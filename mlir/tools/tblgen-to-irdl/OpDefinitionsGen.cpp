//===- OpDefinitionsGen.cpp - IRDL op definitions generator ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// OpDefinitionsGen uses the description of operations to generate IRDL
// definitions for ops.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/IRDL/IR/IRDL.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/TableGen/AttrOrTypeDef.h"
#include "mlir/TableGen/GenInfo.h"
#include "mlir/TableGen/GenNameParser.h"
#include "mlir/TableGen/Interfaces.h"
#include "mlir/TableGen/Operator.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TableGen/Main.h"
#include "llvm/TableGen/Record.h"
#include "llvm/TableGen/TableGenBackend.h"

using namespace llvm;
using namespace mlir;
using tblgen::NamedTypeConstraint;

static llvm::cl::OptionCategory dialectGenCat("Options for -gen-irdl-dialect");
static llvm::cl::opt<std::string>
    selectedDialect("dialect", llvm::cl::desc("The dialect to gen for"),
                    llvm::cl::cat(dialectGenCat), llvm::cl::Required);

Value createPredicate(OpBuilder &builder, tblgen::Pred pred) {
  MLIRContext *ctx = builder.getContext();

  if (pred.isCombined()) {
    auto combiner = pred.getDef().getValueAsDef("kind")->getName();
    if (combiner == "PredCombinerAnd" || combiner == "PredCombinerOr") {
      std::vector<Value> constraints;
      for (auto *child : pred.getDef().getValueAsListOfDefs("children")) {
        constraints.push_back(createPredicate(builder, tblgen::Pred(child)));
      }
      if (combiner == "PredCombinerAnd") {
        auto op =
            irdl::AllOfOp::create(builder, UnknownLoc::get(ctx), constraints);
        return op.getOutput();
      }
      auto op =
          irdl::AnyOfOp::create(builder, UnknownLoc::get(ctx), constraints);
      return op.getOutput();
    }
  }

  std::string condition = pred.getCondition();
  // Build a CPredOp to match the C constraint built.
  irdl::CPredOp op = irdl::CPredOp::create(builder, UnknownLoc::get(ctx),
                                           StringAttr::get(ctx, condition));
  return op;
}

Value typeToConstraint(OpBuilder &builder, Type type) {
  MLIRContext *ctx = builder.getContext();
  auto op =
      irdl::IsOp::create(builder, UnknownLoc::get(ctx), TypeAttr::get(type));
  return op.getOutput();
}

Value baseToConstraint(OpBuilder &builder, StringRef baseClass) {
  MLIRContext *ctx = builder.getContext();
  auto op = irdl::BaseOp::create(builder, UnknownLoc::get(ctx),
                                 StringAttr::get(ctx, baseClass));
  return op.getOutput();
}

std::optional<Type> recordToType(MLIRContext *ctx, const Record &predRec) {
  if (predRec.isSubClassOf("I")) {
    auto width = predRec.getValueAsInt("bitwidth");
    return IntegerType::get(ctx, width, IntegerType::Signless);
  }

  if (predRec.isSubClassOf("SI")) {
    auto width = predRec.getValueAsInt("bitwidth");
    return IntegerType::get(ctx, width, IntegerType::Signed);
  }

  if (predRec.isSubClassOf("UI")) {
    auto width = predRec.getValueAsInt("bitwidth");
    return IntegerType::get(ctx, width, IntegerType::Unsigned);
  }

  // Index type
  if (predRec.getName() == "Index") {
    return IndexType::get(ctx);
  }

  // Float types
  if (predRec.isSubClassOf("F")) {
    auto width = predRec.getValueAsInt("bitwidth");
    switch (width) {
    case 16:
      return Float16Type::get(ctx);
    case 32:
      return Float32Type::get(ctx);
    case 64:
      return Float64Type::get(ctx);
    case 80:
      return Float80Type::get(ctx);
    case 128:
      return Float128Type::get(ctx);
    }
  }

  if (predRec.getName() == "NoneType") {
    return NoneType::get(ctx);
  }

  if (predRec.getName() == "BF16") {
    return BFloat16Type::get(ctx);
  }

  if (predRec.getName() == "TF32") {
    return FloatTF32Type::get(ctx);
  }

  if (predRec.getName() == "F8E4M3FN") {
    return Float8E4M3FNType::get(ctx);
  }

  if (predRec.getName() == "F8E5M2") {
    return Float8E5M2Type::get(ctx);
  }

  if (predRec.getName() == "F8E4M3") {
    return Float8E4M3Type::get(ctx);
  }

  if (predRec.getName() == "F8E4M3FNUZ") {
    return Float8E4M3FNUZType::get(ctx);
  }

  if (predRec.getName() == "F8E4M3B11FNUZ") {
    return Float8E4M3B11FNUZType::get(ctx);
  }

  if (predRec.getName() == "F8E5M2FNUZ") {
    return Float8E5M2FNUZType::get(ctx);
  }

  if (predRec.getName() == "F8E3M4") {
    return Float8E3M4Type::get(ctx);
  }

  if (predRec.isSubClassOf("Complex")) {
    const Record *elementRec = predRec.getValueAsDef("elementType");
    auto elementType = recordToType(ctx, *elementRec);
    if (elementType.has_value()) {
      return ComplexType::get(elementType.value());
    }
  }

  return std::nullopt;
}

Value createTypeConstraint(OpBuilder &builder, tblgen::Constraint constraint) {
  MLIRContext *ctx = builder.getContext();
  const Record &predRec = constraint.getDef();

  if (predRec.isSubClassOf("Variadic") || predRec.isSubClassOf("Optional"))
    return createTypeConstraint(builder, predRec.getValueAsDef("baseType"));

  if (predRec.getName() == "AnyType") {
    auto op = irdl::AnyOp::create(builder, UnknownLoc::get(ctx));
    return op.getOutput();
  }

  if (predRec.isSubClassOf("TypeDef")) {
    auto dialect = predRec.getValueAsDef("dialect")->getValueAsString("name");
    if (dialect == selectedDialect) {
      std::string combined = ("!" + predRec.getValueAsString("mnemonic")).str();
      SmallVector<FlatSymbolRefAttr> nested = {
          SymbolRefAttr::get(ctx, combined)};
      auto typeSymbol = SymbolRefAttr::get(ctx, dialect, nested);
      auto op = irdl::BaseOp::create(builder, UnknownLoc::get(ctx), typeSymbol);
      return op.getOutput();
    }
    std::string typeName = ("!" + predRec.getValueAsString("typeName")).str();
    auto op = irdl::BaseOp::create(builder, UnknownLoc::get(ctx),
                                   StringAttr::get(ctx, typeName));
    return op.getOutput();
  }

  if (predRec.isSubClassOf("AnyTypeOf")) {
    std::vector<Value> constraints;
    for (const Record *child : predRec.getValueAsListOfDefs("allowedTypes")) {
      constraints.push_back(
          createTypeConstraint(builder, tblgen::Constraint(child)));
    }
    auto op = irdl::AnyOfOp::create(builder, UnknownLoc::get(ctx), constraints);
    return op.getOutput();
  }

  if (predRec.isSubClassOf("AllOfType")) {
    std::vector<Value> constraints;
    for (const Record *child : predRec.getValueAsListOfDefs("allowedTypes")) {
      constraints.push_back(
          createTypeConstraint(builder, tblgen::Constraint(child)));
    }
    auto op = irdl::AllOfOp::create(builder, UnknownLoc::get(ctx), constraints);
    return op.getOutput();
  }

  // Integer types
  if (predRec.getName() == "AnyInteger") {
    auto op = irdl::BaseOp::create(builder, UnknownLoc::get(ctx),
                                   StringAttr::get(ctx, "!builtin.integer"));
    return op.getOutput();
  }

  if (predRec.isSubClassOf("AnyI")) {
    auto width = predRec.getValueAsInt("bitwidth");
    std::vector<Value> types = {
        typeToConstraint(builder,
                         IntegerType::get(ctx, width, IntegerType::Signless)),
        typeToConstraint(builder,
                         IntegerType::get(ctx, width, IntegerType::Signed)),
        typeToConstraint(builder,
                         IntegerType::get(ctx, width, IntegerType::Unsigned))};
    auto op = irdl::AnyOfOp::create(builder, UnknownLoc::get(ctx), types);
    return op.getOutput();
  }

  auto type = recordToType(ctx, predRec);

  if (type.has_value()) {
    return typeToConstraint(builder, type.value());
  }

  // Confined type
  if (predRec.isSubClassOf("ConfinedType")) {
    std::vector<Value> constraints;
    constraints.push_back(createTypeConstraint(
        builder, tblgen::Constraint(predRec.getValueAsDef("baseType"))));
    for (const Record *child : predRec.getValueAsListOfDefs("predicateList")) {
      constraints.push_back(createPredicate(builder, tblgen::Pred(child)));
    }
    auto op = irdl::AllOfOp::create(builder, UnknownLoc::get(ctx), constraints);
    return op.getOutput();
  }

  return createPredicate(builder, constraint.getPredicate());
}

Value createAttrConstraint(OpBuilder &builder, tblgen::Constraint constraint) {
  MLIRContext *ctx = builder.getContext();
  const Record &predRec = constraint.getDef();

  if (predRec.isSubClassOf("DefaultValuedAttr") ||
      predRec.isSubClassOf("DefaultValuedOptionalAttr") ||
      predRec.isSubClassOf("OptionalAttr")) {
    return createAttrConstraint(builder, predRec.getValueAsDef("baseAttr"));
  }

  if (predRec.isSubClassOf("ConfinedAttr")) {
    std::vector<Value> constraints;
    constraints.push_back(createAttrConstraint(
        builder, tblgen::Constraint(predRec.getValueAsDef("baseAttr"))));
    for (const Record *child :
         predRec.getValueAsListOfDefs("attrConstraints")) {
      constraints.push_back(createPredicate(
          builder, tblgen::Pred(child->getValueAsDef("predicate"))));
    }
    auto op = irdl::AllOfOp::create(builder, UnknownLoc::get(ctx), constraints);
    return op.getOutput();
  }

  if (predRec.isSubClassOf("AnyAttrOf")) {
    std::vector<Value> constraints;
    for (const Record *child :
         predRec.getValueAsListOfDefs("allowedAttributes")) {
      constraints.push_back(
          createAttrConstraint(builder, tblgen::Constraint(child)));
    }
    auto op = irdl::AnyOfOp::create(builder, UnknownLoc::get(ctx), constraints);
    return op.getOutput();
  }

  if (predRec.getName() == "AnyAttr") {
    auto op = irdl::AnyOp::create(builder, UnknownLoc::get(ctx));
    return op.getOutput();
  }

  if (predRec.isSubClassOf("AnyIntegerAttrBase") ||
      predRec.isSubClassOf("SignlessIntegerAttrBase") ||
      predRec.isSubClassOf("SignedIntegerAttrBase") ||
      predRec.isSubClassOf("UnsignedIntegerAttrBase") ||
      predRec.isSubClassOf("BoolAttr")) {
    return baseToConstraint(builder, "!builtin.integer");
  }

  if (predRec.isSubClassOf("FloatAttrBase")) {
    return baseToConstraint(builder, "!builtin.float");
  }

  if (predRec.isSubClassOf("StringBasedAttr")) {
    return baseToConstraint(builder, "!builtin.string");
  }

  if (predRec.getName() == "UnitAttr") {
    auto op =
        irdl::IsOp::create(builder, UnknownLoc::get(ctx), UnitAttr::get(ctx));
    return op.getOutput();
  }

  if (predRec.isSubClassOf("AttrDef")) {
    auto dialect = predRec.getValueAsDef("dialect")->getValueAsString("name");
    if (dialect == selectedDialect) {
      std::string combined = ("#" + predRec.getValueAsString("mnemonic")).str();
      SmallVector<FlatSymbolRefAttr> nested = {SymbolRefAttr::get(ctx, combined)

      };
      auto typeSymbol = SymbolRefAttr::get(ctx, dialect, nested);
      auto op = irdl::BaseOp::create(builder, UnknownLoc::get(ctx), typeSymbol);
      return op.getOutput();
    }
    std::string typeName = ("#" + predRec.getValueAsString("attrName")).str();
    auto op = irdl::BaseOp::create(builder, UnknownLoc::get(ctx),
                                   StringAttr::get(ctx, typeName));
    return op.getOutput();
  }

  return createPredicate(builder, constraint.getPredicate());
}

Value createRegionConstraint(OpBuilder &builder, tblgen::Region constraint) {
  MLIRContext *ctx = builder.getContext();
  const Record &predRec = constraint.getDef();

  if (predRec.getName() == "AnyRegion") {
    ValueRange entryBlockArgs = {};
    auto op =
        irdl::RegionOp::create(builder, UnknownLoc::get(ctx), entryBlockArgs);
    return op.getResult();
  }

  if (predRec.isSubClassOf("SizedRegion")) {
    ValueRange entryBlockArgs = {};
    auto ty = IntegerType::get(ctx, 32);
    auto op = irdl::RegionOp::create(
        builder, UnknownLoc::get(ctx), entryBlockArgs,
        IntegerAttr::get(ty, predRec.getValueAsInt("blocks")));
    return op.getResult();
  }

  return createPredicate(builder, constraint.getPredicate());
}

/// Returns the name of the operation without the dialect prefix.
static StringRef getOperatorName(tblgen::Operator &tblgenOp) {
  StringRef opName = tblgenOp.getDef().getValueAsString("opName");
  return opName;
}

/// Returns the name of the type without the dialect prefix.
static StringRef getTypeName(tblgen::TypeDef &tblgenType) {
  StringRef opName = tblgenType.getDef()->getValueAsString("mnemonic");
  return opName;
}

/// Returns the name of the attr without the dialect prefix.
static StringRef getAttrName(tblgen::AttrDef &tblgenType) {
  StringRef opName = tblgenType.getDef()->getValueAsString("mnemonic");
  return opName;
}

/// Extract an operation to IRDL.
irdl::OperationOp createIRDLOperation(OpBuilder &builder,
                                      tblgen::Operator &tblgenOp) {
  MLIRContext *ctx = builder.getContext();
  StringRef opName = getOperatorName(tblgenOp);

  irdl::OperationOp op = irdl::OperationOp::create(
      builder, UnknownLoc::get(ctx), StringAttr::get(ctx, opName));

  // Add the block in the region.
  Block &opBlock = op.getBody().emplaceBlock();
  OpBuilder consBuilder = OpBuilder::atBlockBegin(&opBlock);

  SmallDenseSet<StringRef> usedNames;
  for (auto &namedCons : tblgenOp.getOperands())
    usedNames.insert(namedCons.name);
  for (auto &namedCons : tblgenOp.getResults())
    usedNames.insert(namedCons.name);
  for (auto &namedReg : tblgenOp.getRegions())
    usedNames.insert(namedReg.name);

  size_t generateCounter = 0;
  auto generateName = [&](StringRef prefix) -> StringAttr {
    SmallString<16> candidate;
    do {
      candidate.clear();
      raw_svector_ostream candidateStream(candidate);
      candidateStream << prefix << generateCounter;
      generateCounter++;
    } while (usedNames.contains(candidate));
    return StringAttr::get(ctx, candidate);
  };
  auto normalizeName = [&](StringRef name) -> StringAttr {
    if (name == "")
      return generateName("unnamed");
    return StringAttr::get(ctx, name);
  };

  auto getValues = [&](tblgen::Operator::const_value_range namedCons) {
    SmallVector<Value> operands;
    SmallVector<Attribute> names;
    SmallVector<irdl::VariadicityAttr> variadicity;

    for (const NamedTypeConstraint &namedCons : namedCons) {
      auto operand = createTypeConstraint(consBuilder, namedCons.constraint);
      operands.push_back(operand);

      names.push_back(normalizeName(namedCons.name));

      irdl::VariadicityAttr var;
      if (namedCons.isOptional())
        var = consBuilder.getAttr<irdl::VariadicityAttr>(
            irdl::Variadicity::optional);
      else if (namedCons.isVariadic())
        var = consBuilder.getAttr<irdl::VariadicityAttr>(
            irdl::Variadicity::variadic);
      else
        var = consBuilder.getAttr<irdl::VariadicityAttr>(
            irdl::Variadicity::single);

      variadicity.push_back(var);
    }
    return std::make_tuple(operands, names, variadicity);
  };

  auto [operands, operandNames, operandVariadicity] =
      getValues(tblgenOp.getOperands());
  auto [results, resultNames, resultVariadicity] =
      getValues(tblgenOp.getResults());

  SmallVector<Value> attributes;
  SmallVector<Attribute> attrNames;
  for (auto namedAttr : tblgenOp.getAttributes()) {
    if (namedAttr.attr.isOptional())
      continue;
    attributes.push_back(createAttrConstraint(consBuilder, namedAttr.attr));
    attrNames.push_back(StringAttr::get(ctx, namedAttr.name));
  }

  SmallVector<Value> regions;
  SmallVector<Attribute> regionNames;
  for (auto namedRegion : tblgenOp.getRegions()) {
    regions.push_back(
        createRegionConstraint(consBuilder, namedRegion.constraint));
    regionNames.push_back(normalizeName(namedRegion.name));
  }

  // Create the operands and results operations.
  if (!operands.empty())
    irdl::OperandsOp::create(consBuilder, UnknownLoc::get(ctx), operands,
                             ArrayAttr::get(ctx, operandNames),
                             operandVariadicity);
  if (!results.empty())
    irdl::ResultsOp::create(consBuilder, UnknownLoc::get(ctx), results,
                            ArrayAttr::get(ctx, resultNames),
                            resultVariadicity);
  if (!attributes.empty())
    irdl::AttributesOp::create(consBuilder, UnknownLoc::get(ctx), attributes,
                               ArrayAttr::get(ctx, attrNames));
  if (!regions.empty())
    irdl::RegionsOp::create(consBuilder, UnknownLoc::get(ctx), regions,
                            ArrayAttr::get(ctx, regionNames));

  return op;
}

irdl::TypeOp createIRDLType(OpBuilder &builder, tblgen::TypeDef &tblgenType) {
  MLIRContext *ctx = builder.getContext();
  StringRef typeName = getTypeName(tblgenType);
  std::string combined = ("!" + typeName).str();

  irdl::TypeOp op = irdl::TypeOp::create(builder, UnknownLoc::get(ctx),
                                         StringAttr::get(ctx, combined));

  op.getBody().emplaceBlock();

  return op;
}

irdl::AttributeOp createIRDLAttr(OpBuilder &builder,
                                 tblgen::AttrDef &tblgenAttr) {
  MLIRContext *ctx = builder.getContext();
  StringRef attrName = getAttrName(tblgenAttr);
  std::string combined = ("#" + attrName).str();

  irdl::AttributeOp op = irdl::AttributeOp::create(
      builder, UnknownLoc::get(ctx), StringAttr::get(ctx, combined));

  op.getBody().emplaceBlock();

  return op;
}

static irdl::DialectOp createIRDLDialect(OpBuilder &builder) {
  MLIRContext *ctx = builder.getContext();
  return irdl::DialectOp::create(builder, UnknownLoc::get(ctx),
                                 StringAttr::get(ctx, selectedDialect));
}

static bool emitDialectIRDLDefs(const RecordKeeper &records, raw_ostream &os) {
  // Initialize.
  MLIRContext ctx;
  ctx.getOrLoadDialect<irdl::IRDLDialect>();
  OpBuilder builder(&ctx);

  // Create a module op and set it as the insertion point.
  OwningOpRef<ModuleOp> module =
      ModuleOp::create(builder, UnknownLoc::get(&ctx));
  builder = builder.atBlockBegin(module->getBody());
  // Create the dialect and insert it.
  irdl::DialectOp dialect = createIRDLDialect(builder);
  // Set insertion point to start of DialectOp.
  builder = builder.atBlockBegin(&dialect.getBody().emplaceBlock());

  for (const Record *type :
       records.getAllDerivedDefinitionsIfDefined("TypeDef")) {
    tblgen::TypeDef tblgenType(type);
    if (tblgenType.getDialect().getName() != selectedDialect)
      continue;
    createIRDLType(builder, tblgenType);
  }

  for (const Record *attr :
       records.getAllDerivedDefinitionsIfDefined("AttrDef")) {
    tblgen::AttrDef tblgenAttr(attr);
    if (tblgenAttr.getDialect().getName() != selectedDialect)
      continue;
    createIRDLAttr(builder, tblgenAttr);
  }

  for (const Record *def : records.getAllDerivedDefinitionsIfDefined("Op")) {
    tblgen::Operator tblgenOp(def);
    if (tblgenOp.getDialectName() != selectedDialect)
      continue;

    createIRDLOperation(builder, tblgenOp);
  }

  // Print the module.
  module->print(os);

  return false;
}

static mlir::GenRegistration
    genOpDefs("gen-dialect-irdl-defs", "Generate IRDL dialect definitions",
              [](const RecordKeeper &records, raw_ostream &os) {
                return emitDialectIRDLDefs(records, os);
              });
