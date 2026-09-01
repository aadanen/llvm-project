; RUN: split-file %s %t
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/wrong-arg-count.ll 2>&1 | FileCheck %t/wrong-arg-count.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/non-constant-typeinfo.ll 2>&1 | FileCheck %t/non-constant-typeinfo.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/bad-typeinfo.ll 2>&1 | FileCheck %t/bad-typeinfo.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/non-constant-adjectives.ll 2>&1 | FileCheck %t/non-constant-adjectives.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/seh-wrong-arg-count.ll 2>&1 | FileCheck %t/seh-wrong-arg-count.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/seh-non-constant-filter.ll 2>&1 | FileCheck %t/seh-non-constant-filter.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/seh-bad-filter.ll 2>&1 | FileCheck %t/seh-bad-filter.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/clr-wrong-arg-count.ll 2>&1 | FileCheck %t/clr-wrong-arg-count.ll
; RUN: not llc -mtriple=x86_64-pc-windows-msvc < %t/clr-non-constant-token.ll 2>&1 | FileCheck %t/clr-non-constant-token.ll

;--- wrong-arg-count.ll
; CHECK: LLVM ERROR: MSVC++ catchpad requires 3 arguments
target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)
declare void @f()

define void @foo() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs []
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- non-constant-typeinfo.ll
; CHECK: LLVM ERROR: MSVC++ catchpad first argument must be a Constant
target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)
declare void @f()

define void @foo() personality ptr @__CxxFrameHandler3 {
entry:
  %obj = alloca ptr
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs [ptr %obj, i32 0, ptr null]
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- bad-typeinfo.ll
; CHECK: LLVM ERROR: MSVC++ catchpad first argument must be null or point to a global variable
target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)
declare void @f()

define void @foo() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs [ptr @f, i32 0, ptr null]
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- non-constant-adjectives.ll
; CHECK: LLVM ERROR: MSVC++ catchpad second argument must be a ConstantInt
target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)
declare void @f()

define void @foo() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs [ptr null, ptr null, ptr null]
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- seh-wrong-arg-count.ll
; CHECK: LLVM ERROR: SEH catchpad requires at least 1 argument
target triple = "x86_64-pc-windows-msvc"

declare i32 @__C_specific_handler(...)
declare void @f()

define void @foo() personality ptr @__C_specific_handler {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs []
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- seh-non-constant-filter.ll
; CHECK: LLVM ERROR: SEH catchpad argument must be a Constant
target triple = "x86_64-pc-windows-msvc"

declare i32 @__C_specific_handler(...)
declare void @f()

define void @foo() personality ptr @__C_specific_handler {
entry:
  %obj = alloca ptr
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs [ptr %obj]
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- seh-bad-filter.ll
; CHECK: LLVM ERROR: SEH catchpad argument must be null or a function
target triple = "x86_64-pc-windows-msvc"

@g = global i32 0
declare i32 @__C_specific_handler(...)
declare void @f()

define void @foo() personality ptr @__C_specific_handler {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs [ptr @g]
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- clr-wrong-arg-count.ll
; CHECK: LLVM ERROR: CLR catchpad requires 1 argument
target triple = "x86_64-pc-windows-msvc"

declare void @ProcessCLRException()
declare void @f()

define void @foo() personality ptr @ProcessCLRException {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs []
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

;--- clr-non-constant-token.ll
; CHECK: LLVM ERROR: CLR catchpad argument must be a ConstantInt
target triple = "x86_64-pc-windows-msvc"

declare void @ProcessCLRException()
declare void @f()

define void @foo() personality ptr @ProcessCLRException {
entry:
  invoke void @f()
          to label %cont unwind label %dispatch

dispatch:                                         ; preds = %entry
  %cs = catchswitch within none [label %catch] unwind to caller

catch:                                            ; preds = %dispatch
  %pad = catchpad within %cs [ptr null]
  catchret from %pad to label %cont

cont:                                             ; preds = %catch, %entry
  ret void
}

