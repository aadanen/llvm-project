; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 4
; RUN: llc -mtriple=amdgcn -mcpu=gfx1250 < %s | FileCheck -check-prefixes=GFX1250 %s

define <2 x bfloat> @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mixhi_bf16 v0, v0, v1, v2 op_sel_hi:[1,1,1]
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  %vec.result = insertelement <2 x bfloat> undef, bfloat %cvt.result, i32 1
  ret <2 x bfloat> %vec.result
}

define <2 x bfloat> @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_constlo(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_constlo:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_mov_b32_e32 v3, 0x3f80
; GFX1250-NEXT:    s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
; GFX1250-NEXT:    v_fma_mixhi_bf16 v3, v0, v1, v2 op_sel_hi:[1,1,1]
; GFX1250-NEXT:    v_mov_b32_e32 v0, v3
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  %vec.result = insertelement <2 x bfloat> <bfloat 1.0, bfloat undef>, bfloat %cvt.result, i32 1
  ret <2 x bfloat> %vec.result
}

define <2 x bfloat> @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_reglo(bfloat %src0, bfloat %src1, bfloat %src2, bfloat %lo) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_reglo:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mixhi_bf16 v3, v0, v1, v2 op_sel_hi:[1,1,1]
; GFX1250-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX1250-NEXT:    v_mov_b32_e32 v0, v3
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  %vec = insertelement <2 x bfloat> undef, bfloat %lo, i32 0
  %vec.result = insertelement <2 x bfloat> %vec, bfloat %cvt.result, i32 1
  ret <2 x bfloat> %vec.result
}

define i32 @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_intpack(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_intpack:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mixlo_bf16 v0, v0, v1, v2 op_sel_hi:[1,1,1]
; GFX1250-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX1250-NEXT:    v_lshlrev_b32_e32 v0, 16, v0
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  %bc = bitcast bfloat %cvt.result to i16
  %ext = zext i16 %bc to i32
  %shr = shl i32 %ext, 16
  ret i32 %shr
}

define i32 @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_intpack_sext(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_intpack_sext:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mixlo_bf16 v0, v0, v1, v2 op_sel_hi:[1,1,1]
; GFX1250-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX1250-NEXT:    v_lshlrev_b32_e32 v0, 16, v0
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  %bc = bitcast bfloat %cvt.result to i16
  %ext = sext i16 %bc to i32
  %shr = shl i32 %ext, 16
  ret i32 %shr
}

define <2 x bfloat> @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo_clamp_precvt(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo_clamp_precvt:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mix_f32_bf16 v0, v0, v1, v2 op_sel_hi:[1,1,1] clamp
; GFX1250-NEXT:    s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
; GFX1250-NEXT:    v_cvt_pk_bf16_f32 v0, v0, s0
; GFX1250-NEXT:    v_lshlrev_b32_e32 v0, 16, v0
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %max = call float @llvm.maxnum.f32(float %result, float 0.0)
  %clamp = call float @llvm.minnum.f32(float %max, float 1.0)
  %cvt.result = fptrunc float %clamp to bfloat
  %vec.result = insertelement <2 x bfloat> undef, bfloat %cvt.result, i32 1
  ret <2 x bfloat> %vec.result
}

define <2 x bfloat> @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo_clamp_postcvt(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo_clamp_postcvt:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mixhi_bf16 v0, v0, v1, v2 op_sel_hi:[1,1,1] clamp
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  %max = call bfloat @llvm.maxnum.bf16(bfloat %cvt.result, bfloat 0.0)
  %clamp = call bfloat @llvm.minnum.bf16(bfloat %max, bfloat 1.0)
  %vec.result = insertelement <2 x bfloat> undef, bfloat %clamp, i32 1
  ret <2 x bfloat> %vec.result
}

define <2 x bfloat> @v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo_clamp_postcvt_multi_use(bfloat %src0, bfloat %src1, bfloat %src2) #0 {
; GFX1250-LABEL: v_mad_mixhi_bf16_bf16lo_bf16lo_bf16lo_undeflo_clamp_postcvt_multi_use:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    s_wait_loadcnt_dscnt 0x0
; GFX1250-NEXT:    s_wait_kmcnt 0x0
; GFX1250-NEXT:    v_fma_mixlo_bf16 v3, v0, v1, v2 op_sel_hi:[1,1,1]
; GFX1250-NEXT:    v_fma_mixhi_bf16 v0, v0, v1, v2 op_sel_hi:[1,1,1] clamp
; GFX1250-NEXT:    global_store_b16 v[0:1], v3, off scope:SCOPE_SYS
; GFX1250-NEXT:    s_wait_storecnt 0x0
; GFX1250-NEXT:    s_set_pc_i64 s[30:31]
  %src0.ext = fpext bfloat %src0 to float
  %src1.ext = fpext bfloat %src1 to float
  %src2.ext = fpext bfloat %src2 to float
  %result = tail call float @llvm.fmuladd.f32(float %src0.ext, float %src1.ext, float %src2.ext)
  %cvt.result = fptrunc float %result to bfloat
  store volatile bfloat %cvt.result, ptr addrspace(1) undef
  %max = call bfloat @llvm.maxnum.bf16(bfloat %cvt.result, bfloat 0.0)
  %clamp = call bfloat @llvm.minnum.bf16(bfloat %max, bfloat 1.0)
  %vec.result = insertelement <2 x bfloat> undef, bfloat %clamp, i32 1
  ret <2 x bfloat> %vec.result
}

declare bfloat @llvm.minnum.bf16(bfloat, bfloat) #1
declare bfloat @llvm.maxnum.bf16(bfloat, bfloat) #1
declare float @llvm.minnum.f32(float, float) #1
declare float @llvm.maxnum.f32(float, float) #1
declare float @llvm.fmuladd.f32(float, float, float) #1
declare <2 x float> @llvm.fmuladd.v2f32(<2 x float>, <2 x float>, <2 x float>) #1

attributes #0 = { nounwind "denormal-fp-math-f32"="preserve-sign,preserve-sign" }
attributes #1 = { nounwind readnone speculatable }
