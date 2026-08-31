; RUN: split-file %s %t
; RUN: opt -passes=verify -disable-output %t/msvc-cxx-good.ll
; RUN: opt -passes=verify -disable-output %t/msvc-seh-good.ll
; RUN: opt -passes=verify -disable-output %t/coreclr-good.ll
; RUN: not opt -passes=verify -disable-output %t/msvc-cxx.ll 2>&1 | FileCheck %s --check-prefix=MSVC-CXX
; RUN: not opt -passes=verify -disable-output %t/msvc-cxx-bad-arg0.ll 2>&1 | FileCheck %s --check-prefix=MSVC-CXX-BAD-ARG0
; RUN: not opt -passes=verify -disable-output %t/msvc-cxx-bad-arg1.ll 2>&1 | FileCheck %s --check-prefix=MSVC-CXX-BAD-ARG1
; RUN: not opt -passes=verify -disable-output %t/msvc-cxx-bad-arg2.ll 2>&1 | FileCheck %s --check-prefix=MSVC-CXX-BAD-ARG2
; RUN: not opt -passes=verify -disable-output %t/msvc-seh-empty.ll 2>&1 | FileCheck %s --check-prefix=MSVC-SEH-EMPTY
; RUN: not opt -passes=verify -disable-output %t/msvc-seh-nonconst.ll 2>&1 | FileCheck %s --check-prefix=MSVC-SEH-NONCONST
; RUN: not opt -passes=verify -disable-output %t/coreclr-empty.ll 2>&1 | FileCheck %s --check-prefix=CORECLR-EMPTY
; RUN: not opt -passes=verify -disable-output %t/coreclr-nonint.ll 2>&1 | FileCheck %s --check-prefix=CORECLR-NONINT

; Verify personality-specific malformed catchpad payloads are rejected early.

;--- msvc-cxx-good.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)
declare void @f()

define void @good_cxx() personality ptr @__CxxFrameHandler3 {
entry:
  %obj = alloca i8, align 1
  invoke void @f() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr null, i32 0, ptr %obj]
  catchret from %pad to label %cont

cont:
  ret void
}

;--- msvc-seh-good.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__C_specific_handler(...)
declare void @f()

define void @good_seh() personality ptr @__C_specific_handler {
entry:
  invoke void @f() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr null]
  catchret from %pad to label %cont

cont:
  ret void
}

;--- coreclr-good.ll

target triple = "x86_64-pc-windows-coreclr"

declare i32 @ProcessCLRException(...)
declare void @f()

define void @good_coreclr() personality ptr @ProcessCLRException {
entry:
  invoke void @f() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [i32 7]
  catchret from %pad to label %cont

cont:
  ret void
}

;--- msvc-cxx.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)

define void @bad_empty_catchpad() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs []
  catchret from %pad to label %cont

cont:
  ret void
}

; MSVC-CXX: MSVC C++ catchpad must have exactly 3 arguments

;--- msvc-cxx-bad-arg0.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)

define void @bad_cxx_arg0_nonconstant() personality ptr @__CxxFrameHandler3 {
entry:
  %slot = alloca ptr, align 8
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr %slot, i32 0, ptr null]
  catchret from %pad to label %cont

cont:
  ret void
}

; MSVC-CXX-BAD-ARG0: MSVC C++ catchpad first argument must be a constant

;--- msvc-cxx-bad-arg1.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)

define void @bad_cxx_arg1_noni32() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr null, ptr null, ptr null]
  catchret from %pad to label %cont

cont:
  ret void
}

; MSVC-CXX-BAD-ARG1: MSVC C++ catchpad second argument must be an i32 constant

;--- msvc-cxx-bad-arg2.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__CxxFrameHandler3(...)

@GV = global i8 0

define void @bad_cxx_arg2_not_alloca_or_null() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr null, i32 0, ptr @GV]
  catchret from %pad to label %cont

cont:
  ret void
}

; MSVC-CXX-BAD-ARG2: MSVC C++ catchpad third argument must be an alloca or null

;--- msvc-seh-empty.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__C_specific_handler(...)

define void @bad_seh_empty() personality ptr @__C_specific_handler {
entry:
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs []
  catchret from %pad to label %cont

cont:
  ret void
}

; MSVC-SEH-EMPTY: MSVC SEH catchpad must have at least 1 argument

;--- msvc-seh-nonconst.ll

target triple = "x86_64-pc-windows-msvc"

declare i32 @__C_specific_handler(...)

define void @bad_seh_nonconst() personality ptr @__C_specific_handler {
entry:
  %slot = alloca ptr, align 8
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr %slot]
  catchret from %pad to label %cont

cont:
  ret void
}

; MSVC-SEH-NONCONST: MSVC SEH catchpad first argument must be a constant

;--- coreclr-empty.ll

target triple = "x86_64-pc-windows-coreclr"

declare i32 @ProcessCLRException(...)

define void @bad_coreclr_empty() personality ptr @ProcessCLRException {
entry:
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs []
  catchret from %pad to label %cont

cont:
  ret void
}

; CORECLR-EMPTY: CoreCLR catchpad must have at least 1 argument

;--- coreclr-nonint.ll

target triple = "x86_64-pc-windows-coreclr"

declare i32 @ProcessCLRException(...)

define void @bad_coreclr_nonint() personality ptr @ProcessCLRException {
entry:
  invoke void null() to label %cont unwind label %dispatch

dispatch:
  %cs = catchswitch within none [label %catch] unwind to caller

catch:
  %pad = catchpad within %cs [ptr null]
  catchret from %pad to label %cont

cont:
  ret void
}

; CORECLR-NONINT: CoreCLR catchpad first argument must be an i32 constant
