; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: sed 's/iXLen/i32/g' %s | llc -mtriple=riscv32 -mattr=+m,+v -verify-machineinstrs | FileCheck %s --check-prefixes=CHECK,RV32
; RUN: sed 's/iXLen/i32/g' %s | llc -mtriple=riscv64 -mattr=+m,+v -verify-machineinstrs | FileCheck %s --check-prefixes=CHECK,RV64

declare i32 @llvm.experimental.get.vector.length.i16(i16, i32, i1)
declare i32 @llvm.experimental.get.vector.length.i32(i32, i32, i1)
declare i32 @llvm.experimental.get.vector.length.i64(i64, i32, i1)

define i32 @vector_length_i16(i16 zeroext %tc) {
; CHECK-LABEL: vector_length_i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    csrr a1, vlenb
; CHECK-NEXT:    srli a1, a1, 2
; CHECK-NEXT:    bltu a0, a1, .LBB0_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    mv a0, a1
; CHECK-NEXT:  .LBB0_2:
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i16(i16 %tc, i32 2, i1 true)
  ret i32 %a
}

define i32 @vector_length_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf4, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 2, i1 true)
  ret i32 %a
}

define i32 @vector_length_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf4, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 2, i1 true)
  ret i32 %a
}

define i32 @vector_length_i16_fixed(i16 zeroext %tc) {
; CHECK-LABEL: vector_length_i16_fixed:
; CHECK:       # %bb.0:
; CHECK-NEXT:    li a1, 2
; CHECK-NEXT:    bltu a0, a1, .LBB3_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    li a0, 2
; CHECK-NEXT:  .LBB3_2:
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i16(i16 %tc, i32 2, i1 false)
  ret i32 %a
}

define i32 @vector_length_i32_fixed(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_i32_fixed:
; CHECK:       # %bb.0:
; CHECK-NEXT:    li a1, 2
; CHECK-NEXT:    bltu a0, a1, .LBB4_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    li a0, 2
; CHECK-NEXT:  .LBB4_2:
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 2, i1 false)
  ret i32 %a
}

define i32 @vector_length_XLen_fixed(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_XLen_fixed:
; CHECK:       # %bb.0:
; CHECK-NEXT:    li a1, 2
; CHECK-NEXT:    bltu a0, a1, .LBB5_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    li a0, 2
; CHECK-NEXT:  .LBB5_2:
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 2, i1 false)
  ret i32 %a
}

define i32 @vector_length_vf1_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf1_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf8, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 1, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf1_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf1_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf8, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 1, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf2_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf2_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf4, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 2, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf2_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf2_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf4, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 2, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf4_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf4_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf2, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 4, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf4_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf4_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, mf2, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 4, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf8_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf8_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m1, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 8, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf8_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf8_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m1, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 8, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf16_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf16_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m2, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 16, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf16_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf16_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m2, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 16, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf32_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf32_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m4, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 32, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf32_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf32_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m4, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 32, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf64_i32(i32 zeroext %tc) {
; CHECK-LABEL: vector_length_vf64_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m8, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 64, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf64_XLen(iXLen zeroext %tc) {
; CHECK-LABEL: vector_length_vf64_XLen:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, a0, e8, m8, ta, ma
; CHECK-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 64, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf128_i32(i32 zeroext %tc) {
; RV32-LABEL: vector_length_vf128_i32:
; RV32:       # %bb.0:
; RV32-NEXT:    csrr a1, vlenb
; RV32-NEXT:    slli a1, a1, 4
; RV32-NEXT:    bltu a0, a1, .LBB20_2
; RV32-NEXT:  # %bb.1:
; RV32-NEXT:    mv a0, a1
; RV32-NEXT:  .LBB20_2:
; RV32-NEXT:    ret
;
; RV64-LABEL: vector_length_vf128_i32:
; RV64:       # %bb.0:
; RV64-NEXT:    sext.w a0, a0
; RV64-NEXT:    csrr a1, vlenb
; RV64-NEXT:    slli a1, a1, 4
; RV64-NEXT:    bltu a0, a1, .LBB20_2
; RV64-NEXT:  # %bb.1:
; RV64-NEXT:    mv a0, a1
; RV64-NEXT:  .LBB20_2:
; RV64-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 128, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf128_XLen(iXLen zeroext %tc) {
; RV32-LABEL: vector_length_vf128_XLen:
; RV32:       # %bb.0:
; RV32-NEXT:    csrr a1, vlenb
; RV32-NEXT:    slli a1, a1, 4
; RV32-NEXT:    bltu a0, a1, .LBB21_2
; RV32-NEXT:  # %bb.1:
; RV32-NEXT:    mv a0, a1
; RV32-NEXT:  .LBB21_2:
; RV32-NEXT:    ret
;
; RV64-LABEL: vector_length_vf128_XLen:
; RV64:       # %bb.0:
; RV64-NEXT:    sext.w a0, a0
; RV64-NEXT:    csrr a1, vlenb
; RV64-NEXT:    slli a1, a1, 4
; RV64-NEXT:    bltu a0, a1, .LBB21_2
; RV64-NEXT:  # %bb.1:
; RV64-NEXT:    mv a0, a1
; RV64-NEXT:  .LBB21_2:
; RV64-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 128, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf3_i32(i32 zeroext %tc) {
; RV32-LABEL: vector_length_vf3_i32:
; RV32:       # %bb.0:
; RV32-NEXT:    csrr a1, vlenb
; RV32-NEXT:    srli a2, a1, 3
; RV32-NEXT:    srli a1, a1, 2
; RV32-NEXT:    add a1, a1, a2
; RV32-NEXT:    bltu a0, a1, .LBB22_2
; RV32-NEXT:  # %bb.1:
; RV32-NEXT:    mv a0, a1
; RV32-NEXT:  .LBB22_2:
; RV32-NEXT:    ret
;
; RV64-LABEL: vector_length_vf3_i32:
; RV64:       # %bb.0:
; RV64-NEXT:    sext.w a0, a0
; RV64-NEXT:    csrr a1, vlenb
; RV64-NEXT:    srli a2, a1, 3
; RV64-NEXT:    srli a1, a1, 2
; RV64-NEXT:    add a1, a1, a2
; RV64-NEXT:    bltu a0, a1, .LBB22_2
; RV64-NEXT:  # %bb.1:
; RV64-NEXT:    mv a0, a1
; RV64-NEXT:  .LBB22_2:
; RV64-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.i32(i32 %tc, i32 3, i1 true)
  ret i32 %a
}

define i32 @vector_length_vf3_XLen(iXLen zeroext %tc) {
; RV32-LABEL: vector_length_vf3_XLen:
; RV32:       # %bb.0:
; RV32-NEXT:    csrr a1, vlenb
; RV32-NEXT:    srli a2, a1, 3
; RV32-NEXT:    srli a1, a1, 2
; RV32-NEXT:    add a1, a1, a2
; RV32-NEXT:    bltu a0, a1, .LBB23_2
; RV32-NEXT:  # %bb.1:
; RV32-NEXT:    mv a0, a1
; RV32-NEXT:  .LBB23_2:
; RV32-NEXT:    ret
;
; RV64-LABEL: vector_length_vf3_XLen:
; RV64:       # %bb.0:
; RV64-NEXT:    sext.w a0, a0
; RV64-NEXT:    csrr a1, vlenb
; RV64-NEXT:    srli a2, a1, 3
; RV64-NEXT:    srli a1, a1, 2
; RV64-NEXT:    add a1, a1, a2
; RV64-NEXT:    bltu a0, a1, .LBB23_2
; RV64-NEXT:  # %bb.1:
; RV64-NEXT:    mv a0, a1
; RV64-NEXT:  .LBB23_2:
; RV64-NEXT:    ret
  %a = call i32 @llvm.experimental.get.vector.length.iXLen(iXLen %tc, i32 3, i1 true)
  ret i32 %a
}
