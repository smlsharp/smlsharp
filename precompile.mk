GENASM = genasm () { \
[ -d "precompiled/$$1" ] || mkdir "precompiled/$$1"; \
  echo $(SMLSHARP) -dtarget=$$1 -Bsrc -S -o $$3 $$2; \
  $(SMLSHARP) -dtarget=$$1 -Bsrc -S -o $$3 $$2 \
  && awk 'BEGIN{print"1,$$s/^\\([A-Z0-9_]*:\\)\t\t\043.*$$/\\1/\nw\nq"}' \
     | ed $$3 > /dev/null; \
  return; \
}; genasm
precompile: precompiled/x86-darwin.tar.xz precompiled/x86-linux.tar.xz precompiled/x86-mingw.tar.xz
include Makefile
precompiled/x86-darwin/000.s: src/compiler/minismlsharp.smi $(MINISMLSHARP_OBJECTS)
	@$(GENASM) x86-darwin src/compiler/minismlsharp.smi precompiled/x86-darwin/000.s
precompiled/x86-darwin/001.s: src/compiler/minismlsharp.o src/compiler/minismlsharp.sml
	@$(GENASM) x86-darwin src/compiler/minismlsharp.sml precompiled/x86-darwin/001.s
precompiled/x86-darwin/002.s: src/compiler/main/main/SimpleMain.o src/compiler/main/main/SimpleMain.sml
	@$(GENASM) x86-darwin src/compiler/main/main/SimpleMain.sml precompiled/x86-darwin/002.s
precompiled/x86-darwin/003.s: src/compiler/main/main/ExecutablePath.o src/compiler/main/main/ExecutablePath.sml
	@$(GENASM) x86-darwin src/compiler/main/main/ExecutablePath.sml precompiled/x86-darwin/003.s
precompiled/x86-darwin/004.s: src/compiler/main/main/RunLoop.o src/compiler/main/main/RunLoop.sml
	@$(GENASM) x86-darwin src/compiler/main/main/RunLoop.sml precompiled/x86-darwin/004.s
precompiled/x86-darwin/005.s: src/sql/main/SQLPrim.o src/sql/main/SQLPrim.sml
	@$(GENASM) x86-darwin src/sql/main/SQLPrim.sml precompiled/x86-darwin/005.s
precompiled/x86-darwin/006.s: src/sql/main/Backend.o src/sql/main/Backend.sml
	@$(GENASM) x86-darwin src/sql/main/Backend.sml precompiled/x86-darwin/006.s
precompiled/x86-darwin/007.s: src/sql/main/PGSQLBackend.o src/sql/main/PGSQLBackend.sml
	@$(GENASM) x86-darwin src/sql/main/PGSQLBackend.sml precompiled/x86-darwin/007.s
precompiled/x86-darwin/008.s: src/sql/main/PGSQL.o src/sql/main/PGSQL.sml
	@$(GENASM) x86-darwin src/sql/main/PGSQL.sml precompiled/x86-darwin/008.s
precompiled/x86-darwin/009.s: src/ffi/main/Pointer.o src/ffi/main/Pointer.sml
	@$(GENASM) x86-darwin src/ffi/main/Pointer.sml precompiled/x86-darwin/009.s
precompiled/x86-darwin/010.s: src/ffi/main/DynamicLink.o src/ffi/main/DynamicLink.sml
	@$(GENASM) x86-darwin src/ffi/main/DynamicLink.sml precompiled/x86-darwin/010.s
precompiled/x86-darwin/011.s: src/compiler/main/main/SMLofNJ.o src/compiler/main/main/SMLofNJ.sml
	@$(GENASM) x86-darwin src/compiler/main/main/SMLofNJ.sml precompiled/x86-darwin/011.s
precompiled/x86-darwin/012.s: src/compiler/main/main/GetOpt.o src/compiler/main/main/GetOpt.sml
	@$(GENASM) x86-darwin src/compiler/main/main/GetOpt.sml precompiled/x86-darwin/012.s
precompiled/x86-darwin/013.s: src/compiler/toplevel2/main/Top.o src/compiler/toplevel2/main/Top.sml
	@$(GENASM) x86-darwin src/compiler/toplevel2/main/Top.sml precompiled/x86-darwin/013.s
precompiled/x86-darwin/014.s: src/compiler/toplevel2/main/NameEvalEnvUtils.o src/compiler/toplevel2/main/NameEvalEnvUtils.sml
	@$(GENASM) x86-darwin src/compiler/toplevel2/main/NameEvalEnvUtils.sml precompiled/x86-darwin/014.s
precompiled/x86-darwin/015.s: src/compiler/toplevel2/main/TopData.ppg.o src/compiler/toplevel2/main/TopData.ppg.sml
	@$(GENASM) x86-darwin src/compiler/toplevel2/main/TopData.ppg.sml precompiled/x86-darwin/015.s
precompiled/x86-darwin/016.s: src/compiler/rtl/main/X86AsmGen.o src/compiler/rtl/main/X86AsmGen.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86AsmGen.sml precompiled/x86-darwin/016.s
precompiled/x86-darwin/017.s: src/compiler/rtl/main/X86Frame.o src/compiler/rtl/main/X86Frame.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Frame.sml precompiled/x86-darwin/017.s
precompiled/x86-darwin/018.s: src/compiler/rtl/main/FrameLayout.o src/compiler/rtl/main/FrameLayout.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/FrameLayout.sml precompiled/x86-darwin/018.s
precompiled/x86-darwin/019.s: src/compiler/rtl/main/X86Coloring.o src/compiler/rtl/main/X86Coloring.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Coloring.sml precompiled/x86-darwin/019.s
precompiled/x86-darwin/020.s: src/compiler/rtl/main/X86Constraint.o src/compiler/rtl/main/X86Constraint.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Constraint.sml precompiled/x86-darwin/020.s
precompiled/x86-darwin/021.s: src/compiler/rtl/main/RTLColoring.o src/compiler/rtl/main/RTLColoring.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLColoring.sml precompiled/x86-darwin/021.s
precompiled/x86-darwin/022.s: src/compiler/rtl/main/Coloring.o src/compiler/rtl/main/Coloring.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/Coloring.sml precompiled/x86-darwin/022.s
precompiled/x86-darwin/023.s: src/compiler/rtl/main/RTLRename.o src/compiler/rtl/main/RTLRename.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLRename.sml precompiled/x86-darwin/023.s
precompiled/x86-darwin/024.s: src/compiler/rtl/main/X86Stabilize.o src/compiler/rtl/main/X86Stabilize.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Stabilize.sml precompiled/x86-darwin/024.s
precompiled/x86-darwin/025.s: src/compiler/rtl/main/RTLStabilize.o src/compiler/rtl/main/RTLStabilize.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLStabilize.sml precompiled/x86-darwin/025.s
precompiled/x86-darwin/026.s: src/compiler/rtl/main/X86Select.o src/compiler/rtl/main/X86Select.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Select.sml precompiled/x86-darwin/026.s
precompiled/x86-darwin/027.s: src/compiler/rtl/main/RTLDominate.o src/compiler/rtl/main/RTLDominate.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLDominate.sml precompiled/x86-darwin/027.s
precompiled/x86-darwin/028.s: src/compiler/rtl/main/X86Subst.o src/compiler/rtl/main/X86Subst.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Subst.sml precompiled/x86-darwin/028.s
precompiled/x86-darwin/029.s: src/compiler/rtl/main/X86Emit.o src/compiler/rtl/main/X86Emit.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Emit.sml precompiled/x86-darwin/029.s
precompiled/x86-darwin/030.s: src/compiler/rtl/main/X86Asm.ppg.o src/compiler/rtl/main/X86Asm.ppg.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/X86Asm.ppg.sml precompiled/x86-darwin/030.s
precompiled/x86-darwin/031.s: src/compiler/rtl/main/IEEERealConst.o src/compiler/rtl/main/IEEERealConst.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/IEEERealConst.sml precompiled/x86-darwin/031.s
precompiled/x86-darwin/032.s: src/compiler/rtl/main/RTLBackendContext.o src/compiler/rtl/main/RTLBackendContext.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLBackendContext.sml precompiled/x86-darwin/032.s
precompiled/x86-darwin/033.s: src/compiler/rtl/main/RTLTypeCheck.o src/compiler/rtl/main/RTLTypeCheck.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLTypeCheck.sml precompiled/x86-darwin/033.s
precompiled/x86-darwin/034.s: src/compiler/rtl/main/RTLTypeCheckError.ppg.o src/compiler/rtl/main/RTLTypeCheckError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLTypeCheckError.ppg.sml precompiled/x86-darwin/034.s
precompiled/x86-darwin/035.s: src/compiler/rtl/main/RTLLiveness.o src/compiler/rtl/main/RTLLiveness.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLLiveness.sml precompiled/x86-darwin/035.s
precompiled/x86-darwin/036.s: src/compiler/rtl/main/RTLUtils.o src/compiler/rtl/main/RTLUtils.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLUtils.sml precompiled/x86-darwin/036.s
precompiled/x86-darwin/037.s: src/compiler/rtl/main/RTLEdit.o src/compiler/rtl/main/RTLEdit.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTLEdit.sml precompiled/x86-darwin/037.s
precompiled/x86-darwin/038.s: src/compiler/rtl/main/RTL.ppg.o src/compiler/rtl/main/RTL.ppg.sml
	@$(GENASM) x86-darwin src/compiler/rtl/main/RTL.ppg.sml precompiled/x86-darwin/038.s
precompiled/x86-darwin/039.s: src/compiler/aigenerator2/main/AIGenerator.o src/compiler/aigenerator2/main/AIGenerator.sml
	@$(GENASM) x86-darwin src/compiler/aigenerator2/main/AIGenerator.sml precompiled/x86-darwin/039.s
precompiled/x86-darwin/040.s: src/compiler/aigenerator2/main/Simplify.o src/compiler/aigenerator2/main/Simplify.sml
	@$(GENASM) x86-darwin src/compiler/aigenerator2/main/Simplify.sml precompiled/x86-darwin/040.s
precompiled/x86-darwin/041.s: src/compiler/aigenerator2/main/CallAnalysis.o src/compiler/aigenerator2/main/CallAnalysis.sml
	@$(GENASM) x86-darwin src/compiler/aigenerator2/main/CallAnalysis.sml precompiled/x86-darwin/041.s
precompiled/x86-darwin/042.s: src/compiler/aigenerator2/main/BinarySearchCode.o src/compiler/aigenerator2/main/BinarySearchCode.sml
	@$(GENASM) x86-darwin src/compiler/aigenerator2/main/BinarySearchCode.sml precompiled/x86-darwin/042.s
precompiled/x86-darwin/043.s: src/compiler/aigenerator2/main/AIPrimitive.o src/compiler/aigenerator2/main/AIPrimitive.sml
	@$(GENASM) x86-darwin src/compiler/aigenerator2/main/AIPrimitive.sml precompiled/x86-darwin/043.s
precompiled/x86-darwin/044.s: src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.o src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.sml
	@$(GENASM) x86-darwin src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.sml precompiled/x86-darwin/044.s
precompiled/x86-darwin/045.s: src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.o src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.sml
	@$(GENASM) x86-darwin src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.sml precompiled/x86-darwin/045.s
precompiled/x86-darwin/046.s: src/compiler/targetplatform/main/VMTarget.o src/compiler/targetplatform/main/VMTarget.sml
	@$(GENASM) x86-darwin src/compiler/targetplatform/main/VMTarget.sml precompiled/x86-darwin/046.s
precompiled/x86-darwin/047.s: src/compiler/targetplatform/main/TargetProperty.o src/compiler/targetplatform/main/TargetProperty.sml
	@$(GENASM) x86-darwin src/compiler/targetplatform/main/TargetProperty.sml precompiled/x86-darwin/047.s
precompiled/x86-darwin/048.s: src/compiler/targetplatform/main/TargetPlatformFormatter.o src/compiler/targetplatform/main/TargetPlatformFormatter.sml
	@$(GENASM) x86-darwin src/compiler/targetplatform/main/TargetPlatformFormatter.sml precompiled/x86-darwin/048.s
precompiled/x86-darwin/049.s: src/compiler/yaanormalization/main/StaticAllocation.o src/compiler/yaanormalization/main/StaticAllocation.sml
	@$(GENASM) x86-darwin src/compiler/yaanormalization/main/StaticAllocation.sml precompiled/x86-darwin/049.s
precompiled/x86-darwin/050.s: src/compiler/yaanormalization/main/ANormalOptimization.o src/compiler/yaanormalization/main/ANormalOptimization.sml
	@$(GENASM) x86-darwin src/compiler/yaanormalization/main/ANormalOptimization.sml precompiled/x86-darwin/050.s
precompiled/x86-darwin/051.s: src/compiler/toyaanormal/main/ToYAANormal.o src/compiler/toyaanormal/main/ToYAANormal.sml
	@$(GENASM) x86-darwin src/compiler/toyaanormal/main/ToYAANormal.sml precompiled/x86-darwin/051.s
precompiled/x86-darwin/052.s: src/compiler/toyaanormal/main/NameMangle.o src/compiler/toyaanormal/main/NameMangle.sml
	@$(GENASM) x86-darwin src/compiler/toyaanormal/main/NameMangle.sml precompiled/x86-darwin/052.s
precompiled/x86-darwin/053.s: src/compiler/yaanormal/main/ANormal.ppg.o src/compiler/yaanormal/main/ANormal.ppg.sml
	@$(GENASM) x86-darwin src/compiler/yaanormal/main/ANormal.ppg.sml precompiled/x86-darwin/053.s
precompiled/x86-darwin/054.s: src/compiler/systemdef/main/BasicTypeFormatters.o src/compiler/systemdef/main/BasicTypeFormatters.sml
	@$(GENASM) x86-darwin src/compiler/systemdef/main/BasicTypeFormatters.sml precompiled/x86-darwin/054.s
precompiled/x86-darwin/055.s: src/compiler/systemdef/main/BasicTypes.o src/compiler/systemdef/main/BasicTypes.sml
	@$(GENASM) x86-darwin src/compiler/systemdef/main/BasicTypes.sml precompiled/x86-darwin/055.s
precompiled/x86-darwin/056.s: src/compiler/closureconversion/main/ClosureConversion.o src/compiler/closureconversion/main/ClosureConversion.sml
	@$(GENASM) x86-darwin src/compiler/closureconversion/main/ClosureConversion.sml precompiled/x86-darwin/056.s
precompiled/x86-darwin/057.s: src/compiler/closureanormal/main/ClosureANormal.ppg.o src/compiler/closureanormal/main/ClosureANormal.ppg.sml
	@$(GENASM) x86-darwin src/compiler/closureanormal/main/ClosureANormal.ppg.sml precompiled/x86-darwin/057.s
precompiled/x86-darwin/058.s: src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.o src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.sml
	@$(GENASM) x86-darwin src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.sml precompiled/x86-darwin/058.s
precompiled/x86-darwin/059.s: src/compiler/bitmapanormalization/main/BitmapANormalization.o src/compiler/bitmapanormalization/main/BitmapANormalization.sml
	@$(GENASM) x86-darwin src/compiler/bitmapanormalization/main/BitmapANormalization.sml precompiled/x86-darwin/059.s
precompiled/x86-darwin/060.s: src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.o src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.sml
	@$(GENASM) x86-darwin src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.sml precompiled/x86-darwin/060.s
precompiled/x86-darwin/061.s: src/compiler/bitmapanormal/main/BitmapANormal.ppg.o src/compiler/bitmapanormal/main/BitmapANormal.ppg.sml
	@$(GENASM) x86-darwin src/compiler/bitmapanormal/main/BitmapANormal.ppg.sml precompiled/x86-darwin/061.s
precompiled/x86-darwin/062.s: src/compiler/bitmapcompilation/main/BitmapCompilation.o src/compiler/bitmapcompilation/main/BitmapCompilation.sml
	@$(GENASM) x86-darwin src/compiler/bitmapcompilation/main/BitmapCompilation.sml precompiled/x86-darwin/062.s
precompiled/x86-darwin/063.s: src/compiler/bitmapcompilation/main/SingletonTyEnv.o src/compiler/bitmapcompilation/main/SingletonTyEnv.sml
	@$(GENASM) x86-darwin src/compiler/bitmapcompilation/main/SingletonTyEnv.sml precompiled/x86-darwin/063.s
precompiled/x86-darwin/064.s: src/compiler/bitmapcompilation/main/RecordLayout.o src/compiler/bitmapcompilation/main/RecordLayout.sml
	@$(GENASM) x86-darwin src/compiler/bitmapcompilation/main/RecordLayout.sml precompiled/x86-darwin/064.s
precompiled/x86-darwin/065.s: src/compiler/runtimetypes/main/TypeLayout.o src/compiler/runtimetypes/main/TypeLayout.sml
	@$(GENASM) x86-darwin src/compiler/runtimetypes/main/TypeLayout.sml precompiled/x86-darwin/065.s
precompiled/x86-darwin/066.s: src/compiler/runtimetypes/main/RuntimeTypes.ppg.o src/compiler/runtimetypes/main/RuntimeTypes.ppg.sml
	@$(GENASM) x86-darwin src/compiler/runtimetypes/main/RuntimeTypes.ppg.sml precompiled/x86-darwin/066.s
precompiled/x86-darwin/067.s: src/compiler/bitmapcalc/main/BitmapCalc.ppg.o src/compiler/bitmapcalc/main/BitmapCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/bitmapcalc/main/BitmapCalc.ppg.sml precompiled/x86-darwin/067.s
precompiled/x86-darwin/068.s: src/compiler/recordunboxing/main/RecordUnboxing.o src/compiler/recordunboxing/main/RecordUnboxing.sml
	@$(GENASM) x86-darwin src/compiler/recordunboxing/main/RecordUnboxing.sml precompiled/x86-darwin/068.s
precompiled/x86-darwin/069.s: src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.o src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.sml
	@$(GENASM) x86-darwin src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.sml precompiled/x86-darwin/069.s
precompiled/x86-darwin/070.s: src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.o src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.sml
	@$(GENASM) x86-darwin src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.sml precompiled/x86-darwin/070.s
precompiled/x86-darwin/071.s: src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.o src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.sml precompiled/x86-darwin/071.s
precompiled/x86-darwin/072.s: src/compiler/staticanalysis/main/StaticAnalysis.o src/compiler/staticanalysis/main/StaticAnalysis.sml
	@$(GENASM) x86-darwin src/compiler/staticanalysis/main/StaticAnalysis.sml precompiled/x86-darwin/072.s
precompiled/x86-darwin/073.s: src/compiler/staticanalysis/main/SAContext.o src/compiler/staticanalysis/main/SAContext.sml
	@$(GENASM) x86-darwin src/compiler/staticanalysis/main/SAContext.sml precompiled/x86-darwin/073.s
precompiled/x86-darwin/074.s: src/compiler/staticanalysis/main/SAConstraint.o src/compiler/staticanalysis/main/SAConstraint.sml
	@$(GENASM) x86-darwin src/compiler/staticanalysis/main/SAConstraint.sml precompiled/x86-darwin/074.s
precompiled/x86-darwin/075.s: src/compiler/staticanalysis/main/ReduceTy.o src/compiler/staticanalysis/main/ReduceTy.sml
	@$(GENASM) x86-darwin src/compiler/staticanalysis/main/ReduceTy.sml precompiled/x86-darwin/075.s
precompiled/x86-darwin/076.s: src/compiler/annotatedtypes/main/AnnotatedTypesUtils.o src/compiler/annotatedtypes/main/AnnotatedTypesUtils.sml
	@$(GENASM) x86-darwin src/compiler/annotatedtypes/main/AnnotatedTypesUtils.sml precompiled/x86-darwin/076.s
precompiled/x86-darwin/077.s: src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.o src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.sml
	@$(GENASM) x86-darwin src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.sml precompiled/x86-darwin/077.s
precompiled/x86-darwin/078.s: src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.o src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.sml precompiled/x86-darwin/078.s
precompiled/x86-darwin/079.s: src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.o src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.sml
	@$(GENASM) x86-darwin src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.sml precompiled/x86-darwin/079.s
precompiled/x86-darwin/080.s: src/compiler/datatypecompilation/main/DatatypeCompilation.o src/compiler/datatypecompilation/main/DatatypeCompilation.sml
	@$(GENASM) x86-darwin src/compiler/datatypecompilation/main/DatatypeCompilation.sml precompiled/x86-darwin/080.s
precompiled/x86-darwin/081.s: src/compiler/typedlambda/main/TypedLambdaFormatter.o src/compiler/typedlambda/main/TypedLambdaFormatter.sml
	@$(GENASM) x86-darwin src/compiler/typedlambda/main/TypedLambdaFormatter.sml precompiled/x86-darwin/081.s
precompiled/x86-darwin/082.s: src/compiler/typedlambda/main/TypedLambda.ppg.o src/compiler/typedlambda/main/TypedLambda.ppg.sml
	@$(GENASM) x86-darwin src/compiler/typedlambda/main/TypedLambda.ppg.sml precompiled/x86-darwin/082.s
precompiled/x86-darwin/083.s: src/compiler/recordcompilation/main/RecordCompilation.o src/compiler/recordcompilation/main/RecordCompilation.sml
	@$(GENASM) x86-darwin src/compiler/recordcompilation/main/RecordCompilation.sml precompiled/x86-darwin/083.s
precompiled/x86-darwin/084.s: src/compiler/recordcompilation/main/UnivKind.o src/compiler/recordcompilation/main/UnivKind.sml
	@$(GENASM) x86-darwin src/compiler/recordcompilation/main/UnivKind.sml precompiled/x86-darwin/084.s
precompiled/x86-darwin/085.s: src/compiler/recordcompilation/main/RecordKind.o src/compiler/recordcompilation/main/RecordKind.sml
	@$(GENASM) x86-darwin src/compiler/recordcompilation/main/RecordKind.sml precompiled/x86-darwin/085.s
precompiled/x86-darwin/086.s: src/compiler/recordcompilation/main/OverloadKind.o src/compiler/recordcompilation/main/OverloadKind.sml
	@$(GENASM) x86-darwin src/compiler/recordcompilation/main/OverloadKind.sml precompiled/x86-darwin/086.s
precompiled/x86-darwin/087.s: src/compiler/fficompilation/main/FFICompilation.o src/compiler/fficompilation/main/FFICompilation.sml
	@$(GENASM) x86-darwin src/compiler/fficompilation/main/FFICompilation.sml precompiled/x86-darwin/087.s
precompiled/x86-darwin/088.s: src/compiler/sqlcompilation/main/SQLCompilation.o src/compiler/sqlcompilation/main/SQLCompilation.sml
	@$(GENASM) x86-darwin src/compiler/sqlcompilation/main/SQLCompilation.sml precompiled/x86-darwin/088.s
precompiled/x86-darwin/089.s: src/compiler/matchcompilation/main/MatchCompiler.o src/compiler/matchcompilation/main/MatchCompiler.sml
	@$(GENASM) x86-darwin src/compiler/matchcompilation/main/MatchCompiler.sml precompiled/x86-darwin/089.s
precompiled/x86-darwin/090.s: src/compiler/matchcompilation/main/MatchError.ppg.o src/compiler/matchcompilation/main/MatchError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/matchcompilation/main/MatchError.ppg.sml precompiled/x86-darwin/090.s
precompiled/x86-darwin/091.s: src/compiler/matchcompilation/main/MatchData.o src/compiler/matchcompilation/main/MatchData.sml
	@$(GENASM) x86-darwin src/compiler/matchcompilation/main/MatchData.sml precompiled/x86-darwin/091.s
precompiled/x86-darwin/092.s: src/compiler/recordcalc/main/RecordCalcFormatter.o src/compiler/recordcalc/main/RecordCalcFormatter.sml
	@$(GENASM) x86-darwin src/compiler/recordcalc/main/RecordCalcFormatter.sml precompiled/x86-darwin/092.s
precompiled/x86-darwin/093.s: src/compiler/recordcalc/main/RecordCalc.ppg.o src/compiler/recordcalc/main/RecordCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/recordcalc/main/RecordCalc.ppg.sml precompiled/x86-darwin/093.s
precompiled/x86-darwin/094.s: src/compiler/reflection/main/PrinterGeneration.o src/compiler/reflection/main/PrinterGeneration.sml
	@$(GENASM) x86-darwin src/compiler/reflection/main/PrinterGeneration.sml precompiled/x86-darwin/094.s
precompiled/x86-darwin/095.s: src/compiler/reflection/main/Reify.o src/compiler/reflection/main/Reify.sml
	@$(GENASM) x86-darwin src/compiler/reflection/main/Reify.sml precompiled/x86-darwin/095.s
precompiled/x86-darwin/096.s: src/compiler/reflection/main/ReifiedTermData.o src/compiler/reflection/main/ReifiedTermData.sml
	@$(GENASM) x86-darwin src/compiler/reflection/main/ReifiedTermData.sml precompiled/x86-darwin/096.s
precompiled/x86-darwin/097.s: src/reifiedterm/main/ReifiedTerm.ppg.o src/reifiedterm/main/ReifiedTerm.ppg.sml
	@$(GENASM) x86-darwin src/reifiedterm/main/ReifiedTerm.ppg.sml precompiled/x86-darwin/097.s
precompiled/x86-darwin/098.s: src/reifiedterm/main/TermPrintUtils.ppg.o src/reifiedterm/main/TermPrintUtils.ppg.sml
	@$(GENASM) x86-darwin src/reifiedterm/main/TermPrintUtils.ppg.sml precompiled/x86-darwin/098.s
precompiled/x86-darwin/099.s: src/reifiedterm/main/ReflectionControl.o src/reifiedterm/main/ReflectionControl.sml
	@$(GENASM) x86-darwin src/reifiedterm/main/ReflectionControl.sml precompiled/x86-darwin/099.s
precompiled/x86-darwin/100.s: src/compiler/typeinference2/main/UncurryFundecl_ng.o src/compiler/typeinference2/main/UncurryFundecl_ng.sml
	@$(GENASM) x86-darwin src/compiler/typeinference2/main/UncurryFundecl_ng.sml precompiled/x86-darwin/100.s
precompiled/x86-darwin/101.s: src/compiler/typeinference2/main/InferTypes2.o src/compiler/typeinference2/main/InferTypes2.sml
	@$(GENASM) x86-darwin src/compiler/typeinference2/main/InferTypes2.sml precompiled/x86-darwin/101.s
precompiled/x86-darwin/102.s: src/compiler/typeinference2/main/Printers.o src/compiler/typeinference2/main/Printers.sml
	@$(GENASM) x86-darwin src/compiler/typeinference2/main/Printers.sml precompiled/x86-darwin/102.s
precompiled/x86-darwin/103.s: src/compiler/typeinference2/main/TypeInferenceUtils.o src/compiler/typeinference2/main/TypeInferenceUtils.sml
	@$(GENASM) x86-darwin src/compiler/typeinference2/main/TypeInferenceUtils.sml precompiled/x86-darwin/103.s
precompiled/x86-darwin/104.s: src/compiler/typeinference2/main/TypeInferenceError.ppg.o src/compiler/typeinference2/main/TypeInferenceError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/typeinference2/main/TypeInferenceError.ppg.sml precompiled/x86-darwin/104.s
precompiled/x86-darwin/105.s: src/compiler/typeinference2/main/TypeInferenceContext.ppg.o src/compiler/typeinference2/main/TypeInferenceContext.ppg.sml
	@$(GENASM) x86-darwin src/compiler/typeinference2/main/TypeInferenceContext.ppg.sml precompiled/x86-darwin/105.s
precompiled/x86-darwin/106.s: src/compiler/types/main/Unify.o src/compiler/types/main/Unify.sml
	@$(GENASM) x86-darwin src/compiler/types/main/Unify.sml precompiled/x86-darwin/106.s
precompiled/x86-darwin/107.s: src/compiler/types/main/CheckEq.o src/compiler/types/main/CheckEq.sml
	@$(GENASM) x86-darwin src/compiler/types/main/CheckEq.sml precompiled/x86-darwin/107.s
precompiled/x86-darwin/108.s: src/compiler/typedcalc/main/TypedCalcUtils.o src/compiler/typedcalc/main/TypedCalcUtils.sml
	@$(GENASM) x86-darwin src/compiler/typedcalc/main/TypedCalcUtils.sml precompiled/x86-darwin/108.s
precompiled/x86-darwin/109.s: src/compiler/constantterm/main/ConstantTerm.ppg.o src/compiler/constantterm/main/ConstantTerm.ppg.sml
	@$(GENASM) x86-darwin src/compiler/constantterm/main/ConstantTerm.ppg.sml precompiled/x86-darwin/109.s
precompiled/x86-darwin/110.s: src/compiler/types/main/TypesUtils.o src/compiler/types/main/TypesUtils.sml
	@$(GENASM) x86-darwin src/compiler/types/main/TypesUtils.sml precompiled/x86-darwin/110.s
precompiled/x86-darwin/111.s: src/compiler/types/main/vars.o src/compiler/types/main/vars.sml
	@$(GENASM) x86-darwin src/compiler/types/main/vars.sml precompiled/x86-darwin/111.s
precompiled/x86-darwin/112.s: src/compiler/typedcalc/main/TypedCalc.ppg.o src/compiler/typedcalc/main/TypedCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/typedcalc/main/TypedCalc.ppg.sml precompiled/x86-darwin/112.s
precompiled/x86-darwin/113.s: src/compiler/valrecoptimization/main/TransFundecl.o src/compiler/valrecoptimization/main/TransFundecl.sml
	@$(GENASM) x86-darwin src/compiler/valrecoptimization/main/TransFundecl.sml precompiled/x86-darwin/113.s
precompiled/x86-darwin/114.s: src/compiler/valrecoptimization/main/VALREC_Optimizer.o src/compiler/valrecoptimization/main/VALREC_Optimizer.sml
	@$(GENASM) x86-darwin src/compiler/valrecoptimization/main/VALREC_Optimizer.sml precompiled/x86-darwin/114.s
precompiled/x86-darwin/115.s: src/compiler/valrecoptimization/main/utils.o src/compiler/valrecoptimization/main/utils.sml
	@$(GENASM) x86-darwin src/compiler/valrecoptimization/main/utils.sml precompiled/x86-darwin/115.s
precompiled/x86-darwin/116.s: src/compiler/nameevaluation/main/NameEval.o src/compiler/nameevaluation/main/NameEval.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/NameEval.sml precompiled/x86-darwin/116.s
precompiled/x86-darwin/117.s: src/compiler/nameevaluation/main/CheckProvide.o src/compiler/nameevaluation/main/CheckProvide.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/CheckProvide.sml precompiled/x86-darwin/117.s
precompiled/x86-darwin/118.s: src/compiler/nameevaluation/main/NameEvalInterface.o src/compiler/nameevaluation/main/NameEvalInterface.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/NameEvalInterface.sml precompiled/x86-darwin/118.s
precompiled/x86-darwin/119.s: src/compiler/nameevaluation/main/SigCheck.o src/compiler/nameevaluation/main/SigCheck.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/SigCheck.sml precompiled/x86-darwin/119.s
precompiled/x86-darwin/120.s: src/compiler/nameevaluation/main/FunctorUtils.o src/compiler/nameevaluation/main/FunctorUtils.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/FunctorUtils.sml precompiled/x86-darwin/120.s
precompiled/x86-darwin/121.s: src/compiler/nameevaluation/main/EvalSig.o src/compiler/nameevaluation/main/EvalSig.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/EvalSig.sml precompiled/x86-darwin/121.s
precompiled/x86-darwin/122.s: src/compiler/nameevaluation/main/Subst.o src/compiler/nameevaluation/main/Subst.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/Subst.sml precompiled/x86-darwin/122.s
precompiled/x86-darwin/123.s: src/compiler/nameevaluation/main/EvalTy.o src/compiler/nameevaluation/main/EvalTy.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/EvalTy.sml precompiled/x86-darwin/123.s
precompiled/x86-darwin/124.s: src/compiler/nameevaluation/main/SetLiftedTys.o src/compiler/nameevaluation/main/SetLiftedTys.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/SetLiftedTys.sml precompiled/x86-darwin/124.s
precompiled/x86-darwin/125.s: src/compiler/util/main/SCCFun.o src/compiler/util/main/SCCFun.sml
	@$(GENASM) x86-darwin src/compiler/util/main/SCCFun.sml precompiled/x86-darwin/125.s
precompiled/x86-darwin/126.s: src/compiler/util/main/Graph.o src/compiler/util/main/Graph.sml
	@$(GENASM) x86-darwin src/compiler/util/main/Graph.sml precompiled/x86-darwin/126.s
precompiled/x86-darwin/127.s: src/compiler/nameevaluation/main/NormalizeTy.o src/compiler/nameevaluation/main/NormalizeTy.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/NormalizeTy.sml precompiled/x86-darwin/127.s
precompiled/x86-darwin/128.s: src/compiler/nameevaluation/main/NameEvalUtils.o src/compiler/nameevaluation/main/NameEvalUtils.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/NameEvalUtils.sml precompiled/x86-darwin/128.s
precompiled/x86-darwin/129.s: src/compiler/nameevaluation/main/TfunVars.o src/compiler/nameevaluation/main/TfunVars.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/TfunVars.sml precompiled/x86-darwin/129.s
precompiled/x86-darwin/130.s: src/compiler-utils/env/main/PathEnv.o src/compiler-utils/env/main/PathEnv.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/PathEnv.sml precompiled/x86-darwin/130.s
precompiled/x86-darwin/131.s: src/compiler/nameevaluation/main/NameEvalEnv.ppg.o src/compiler/nameevaluation/main/NameEvalEnv.ppg.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/NameEvalEnv.ppg.sml precompiled/x86-darwin/131.s
precompiled/x86-darwin/132.s: src/compiler/nameevaluation/main/NameEvalError.ppg.o src/compiler/nameevaluation/main/NameEvalError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/nameevaluation/main/NameEvalError.ppg.sml precompiled/x86-darwin/132.s
precompiled/x86-darwin/133.s: src/compiler/elaborate/main/Elaborator.o src/compiler/elaborate/main/Elaborator.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/Elaborator.sml precompiled/x86-darwin/133.s
precompiled/x86-darwin/134.s: src/compiler/elaborate/main/ElaborateInterface.o src/compiler/elaborate/main/ElaborateInterface.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaborateInterface.sml precompiled/x86-darwin/134.s
precompiled/x86-darwin/135.s: src/compiler/elaborate/main/UserTvarScope.o src/compiler/elaborate/main/UserTvarScope.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/UserTvarScope.sml precompiled/x86-darwin/135.s
precompiled/x86-darwin/136.s: src/compiler/elaborate/main/ElaborateModule.o src/compiler/elaborate/main/ElaborateModule.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaborateModule.sml precompiled/x86-darwin/136.s
precompiled/x86-darwin/137.s: src/compiler/elaborate/main/ElaborateCore.o src/compiler/elaborate/main/ElaborateCore.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaborateCore.sml precompiled/x86-darwin/137.s
precompiled/x86-darwin/138.s: src/compiler/elaborate/main/ElaborateSQL.o src/compiler/elaborate/main/ElaborateSQL.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaborateSQL.sml precompiled/x86-darwin/138.s
precompiled/x86-darwin/139.s: src/compiler/elaborate/main/ElaborateErrorSQL.ppg.o src/compiler/elaborate/main/ElaborateErrorSQL.ppg.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaborateErrorSQL.ppg.sml precompiled/x86-darwin/139.s
precompiled/x86-darwin/140.s: src/compiler/elaborate/main/ElaboratorUtils.o src/compiler/elaborate/main/ElaboratorUtils.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaboratorUtils.sml precompiled/x86-darwin/140.s
precompiled/x86-darwin/141.s: src/compiler/util/main/utils.o src/compiler/util/main/utils.sml
	@$(GENASM) x86-darwin src/compiler/util/main/utils.sml precompiled/x86-darwin/141.s
precompiled/x86-darwin/142.s: src/compiler/usererror/main/UserErrorUtils.o src/compiler/usererror/main/UserErrorUtils.sml
	@$(GENASM) x86-darwin src/compiler/usererror/main/UserErrorUtils.sml precompiled/x86-darwin/142.s
precompiled/x86-darwin/143.s: src/compiler/elaborate/main/ElaborateError.ppg.o src/compiler/elaborate/main/ElaborateError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/elaborate/main/ElaborateError.ppg.sml precompiled/x86-darwin/143.s
precompiled/x86-darwin/144.s: src/compiler/absyn/main/Fixity.o src/compiler/absyn/main/Fixity.sml
	@$(GENASM) x86-darwin src/compiler/absyn/main/Fixity.sml precompiled/x86-darwin/144.s
precompiled/x86-darwin/145.s: src/compiler/loadfile/main/LoadFile.o src/compiler/loadfile/main/LoadFile.sml
	@$(GENASM) x86-darwin src/compiler/loadfile/main/LoadFile.sml precompiled/x86-darwin/145.s
precompiled/x86-darwin/146.s: src/compiler/loadfile/main/LoadFileError.ppg.o src/compiler/loadfile/main/LoadFileError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/loadfile/main/LoadFileError.ppg.sml precompiled/x86-darwin/146.s
precompiled/x86-darwin/147.s: src/compiler/loadfile/main/InterfaceHash.o src/compiler/loadfile/main/InterfaceHash.sml
	@$(GENASM) x86-darwin src/compiler/loadfile/main/InterfaceHash.sml precompiled/x86-darwin/147.s
precompiled/x86-darwin/148.s: src/compiler/loadfile/main/SHA1.o src/compiler/loadfile/main/SHA1.sml
	@$(GENASM) x86-darwin src/compiler/loadfile/main/SHA1.sml precompiled/x86-darwin/148.s
precompiled/x86-darwin/149.s: src/compiler/parser/main/InterfaceParser.o src/compiler/parser/main/InterfaceParser.sml
	@$(GENASM) x86-darwin src/compiler/parser/main/InterfaceParser.sml precompiled/x86-darwin/149.s
precompiled/x86-darwin/150.s: src/compiler/parser/main/interface.grm.o src/compiler/parser/main/interface.grm.sml
	@$(GENASM) x86-darwin src/compiler/parser/main/interface.grm.sml precompiled/x86-darwin/150.s
precompiled/x86-darwin/151.s: src/compiler/patterncalc/main/PatternCalcInterface.ppg.o src/compiler/patterncalc/main/PatternCalcInterface.ppg.sml
	@$(GENASM) x86-darwin src/compiler/patterncalc/main/PatternCalcInterface.ppg.sml precompiled/x86-darwin/151.s
precompiled/x86-darwin/152.s: src/compiler/absyn/main/AbsynFormatter.o src/compiler/absyn/main/AbsynFormatter.sml
	@$(GENASM) x86-darwin src/compiler/absyn/main/AbsynFormatter.sml precompiled/x86-darwin/152.s
precompiled/x86-darwin/153.s: src/compiler/builtin/main/BuiltinContextSources.o src/compiler/builtin/main/BuiltinContextSources.sml
	@$(GENASM) x86-darwin src/compiler/builtin/main/BuiltinContextSources.sml precompiled/x86-darwin/153.s
precompiled/x86-darwin/154.s: src/compiler/builtin/main/BuiltinContext_smi.o src/compiler/builtin/main/BuiltinContext_smi.sml
	@$(GENASM) x86-darwin src/compiler/builtin/main/BuiltinContext_smi.sml precompiled/x86-darwin/154.s
precompiled/x86-darwin/155.s: src/compiler/types/main/BuiltinEnv.o src/compiler/types/main/BuiltinEnv.sml
	@$(GENASM) x86-darwin src/compiler/types/main/BuiltinEnv.sml precompiled/x86-darwin/155.s
precompiled/x86-darwin/156.s: src/compiler/types/main/EvalIty.o src/compiler/types/main/EvalIty.sml
	@$(GENASM) x86-darwin src/compiler/types/main/EvalIty.sml precompiled/x86-darwin/156.s
precompiled/x86-darwin/157.s: src/compiler/types/main/OPrimMap.o src/compiler/types/main/OPrimMap.sml
	@$(GENASM) x86-darwin src/compiler/types/main/OPrimMap.sml precompiled/x86-darwin/157.s
precompiled/x86-darwin/158.s: src/compiler/types/main/VarMap.o src/compiler/types/main/VarMap.sml
	@$(GENASM) x86-darwin src/compiler/types/main/VarMap.sml precompiled/x86-darwin/158.s
precompiled/x86-darwin/159.s: src/compiler/types/main/IDCalc.ppg.o src/compiler/types/main/IDCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/types/main/IDCalc.ppg.sml precompiled/x86-darwin/159.s
precompiled/x86-darwin/160.s: src/compiler/types/main/Types.ppg.o src/compiler/types/main/Types.ppg.sml
	@$(GENASM) x86-darwin src/compiler/types/main/Types.ppg.sml precompiled/x86-darwin/160.s
precompiled/x86-darwin/161.s: src/compiler/types/main/OPrimInstMap.o src/compiler/types/main/OPrimInstMap.sml
	@$(GENASM) x86-darwin src/compiler/types/main/OPrimInstMap.sml precompiled/x86-darwin/161.s
precompiled/x86-darwin/162.s: src/compiler/types/main/tvarMap.o src/compiler/types/main/tvarMap.sml
	@$(GENASM) x86-darwin src/compiler/types/main/tvarMap.sml precompiled/x86-darwin/162.s
precompiled/x86-darwin/163.s: src/compiler/patterncalc/main/PatternCalc.ppg.o src/compiler/patterncalc/main/PatternCalc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/patterncalc/main/PatternCalc.ppg.sml precompiled/x86-darwin/163.s
precompiled/x86-darwin/164.s: src/compiler/builtin/main/BuiltinPrimitive.ppg.o src/compiler/builtin/main/BuiltinPrimitive.ppg.sml
	@$(GENASM) x86-darwin src/compiler/builtin/main/BuiltinPrimitive.ppg.sml precompiled/x86-darwin/164.s
precompiled/x86-darwin/165.s: src/compiler/util/main/gensym.o src/compiler/util/main/gensym.sml
	@$(GENASM) x86-darwin src/compiler/util/main/gensym.sml precompiled/x86-darwin/165.s
precompiled/x86-darwin/166.s: src/compiler/builtin/main/BuiltinName.o src/compiler/builtin/main/BuiltinName.sml
	@$(GENASM) x86-darwin src/compiler/builtin/main/BuiltinName.sml precompiled/x86-darwin/166.s
precompiled/x86-darwin/167.s: src/compiler/builtin/main/BuiltinType.ppg.o src/compiler/builtin/main/BuiltinType.ppg.sml
	@$(GENASM) x86-darwin src/compiler/builtin/main/BuiltinType.ppg.sml precompiled/x86-darwin/167.s
precompiled/x86-darwin/168.s: src/compiler/generatemain/main/GenerateMain.o src/compiler/generatemain/main/GenerateMain.sml
	@$(GENASM) x86-darwin src/compiler/generatemain/main/GenerateMain.sml precompiled/x86-darwin/168.s
precompiled/x86-darwin/169.s: src/compiler/generatemain/main/GenerateMainError.ppg.o src/compiler/generatemain/main/GenerateMainError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/generatemain/main/GenerateMainError.ppg.sml precompiled/x86-darwin/169.s
precompiled/x86-darwin/170.s: src/compiler/parser/main/Parser.o src/compiler/parser/main/Parser.sml
	@$(GENASM) x86-darwin src/compiler/parser/main/Parser.sml precompiled/x86-darwin/170.s
precompiled/x86-darwin/171.s: src/compiler/parser/main/iml.lex.o src/compiler/parser/main/iml.lex.sml
	@$(GENASM) x86-darwin src/compiler/parser/main/iml.lex.sml precompiled/x86-darwin/171.s
precompiled/x86-darwin/172.s: src/compiler/parser/main/iml.grm.o src/compiler/parser/main/iml.grm.sml
	@$(GENASM) x86-darwin src/compiler/parser/main/iml.grm.sml precompiled/x86-darwin/172.s
precompiled/x86-darwin/173.s: src/compiler/parser/main/ParserError.ppg.o src/compiler/parser/main/ParserError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/parser/main/ParserError.ppg.sml precompiled/x86-darwin/173.s
precompiled/x86-darwin/174.s: src/ml-yacc/lib/parser2.o src/ml-yacc/lib/parser2.sml
	@$(GENASM) x86-darwin src/ml-yacc/lib/parser2.sml precompiled/x86-darwin/174.s
precompiled/x86-darwin/175.s: src/ml-yacc/lib/stream.o src/ml-yacc/lib/stream.sml
	@$(GENASM) x86-darwin src/ml-yacc/lib/stream.sml precompiled/x86-darwin/175.s
precompiled/x86-darwin/176.s: src/ml-yacc/lib/lrtable.o src/ml-yacc/lib/lrtable.sml
	@$(GENASM) x86-darwin src/ml-yacc/lib/lrtable.sml precompiled/x86-darwin/176.s
precompiled/x86-darwin/177.s: src/ml-yacc/lib/join.o src/ml-yacc/lib/join.sml
	@$(GENASM) x86-darwin src/ml-yacc/lib/join.sml precompiled/x86-darwin/177.s
precompiled/x86-darwin/178.s: src/compiler/absyn/main/AbsynInterface.ppg.o src/compiler/absyn/main/AbsynInterface.ppg.sml
	@$(GENASM) x86-darwin src/compiler/absyn/main/AbsynInterface.ppg.sml precompiled/x86-darwin/178.s
precompiled/x86-darwin/179.s: src/compiler/absyn/main/Absyn.ppg.o src/compiler/absyn/main/Absyn.ppg.sml
	@$(GENASM) x86-darwin src/compiler/absyn/main/Absyn.ppg.sml precompiled/x86-darwin/179.s
precompiled/x86-darwin/180.s: src/compiler/absyn/main/AbsynSQL.ppg.o src/compiler/absyn/main/AbsynSQL.ppg.sml
	@$(GENASM) x86-darwin src/compiler/absyn/main/AbsynSQL.ppg.sml precompiled/x86-darwin/180.s
precompiled/x86-darwin/181.s: src/compiler/util/main/SmlppgUtil.ppg.o src/compiler/util/main/SmlppgUtil.ppg.sml
	@$(GENASM) x86-darwin src/compiler/util/main/SmlppgUtil.ppg.sml precompiled/x86-darwin/181.s
precompiled/x86-darwin/182.s: src/compiler-utils/env/main/SSet.o src/compiler-utils/env/main/SSet.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/SSet.sml precompiled/x86-darwin/182.s
precompiled/x86-darwin/183.s: src/compiler-utils/env/main/SOrd.o src/compiler-utils/env/main/SOrd.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/SOrd.sml precompiled/x86-darwin/183.s
precompiled/x86-darwin/184.s: src/compiler/util/main/TermFormat.o src/compiler/util/main/TermFormat.sml
	@$(GENASM) x86-darwin src/compiler/util/main/TermFormat.sml precompiled/x86-darwin/184.s
precompiled/x86-darwin/185.s: src/compiler/util/main/BigInt_IntInf.o src/compiler/util/main/BigInt_IntInf.sml
	@$(GENASM) x86-darwin src/compiler/util/main/BigInt_IntInf.sml precompiled/x86-darwin/185.s
precompiled/x86-darwin/186.s: src/compiler/util/main/ListSorter.o src/compiler/util/main/ListSorter.sml
	@$(GENASM) x86-darwin src/compiler/util/main/ListSorter.sml precompiled/x86-darwin/186.s
precompiled/x86-darwin/187.s: src/compiler-utils/env/main/LabelEnv.o src/compiler-utils/env/main/LabelEnv.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/LabelEnv.sml precompiled/x86-darwin/187.s
precompiled/x86-darwin/188.s: src/compiler-utils/env/main/LabelOrd.o src/compiler-utils/env/main/LabelOrd.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/LabelOrd.sml precompiled/x86-darwin/188.s
precompiled/x86-darwin/189.s: src/smlnj-lib/Util/binary-map-fn.o src/smlnj-lib/Util/binary-map-fn.sml
	@$(GENASM) x86-darwin src/smlnj-lib/Util/binary-map-fn.sml precompiled/x86-darwin/189.s
precompiled/x86-darwin/190.s: src/compiler/name/main/LocalID.o src/compiler/name/main/LocalID.sml
	@$(GENASM) x86-darwin src/compiler/name/main/LocalID.sml precompiled/x86-darwin/190.s
precompiled/x86-darwin/191.s: src/compiler-utils/env/main/ISet.o src/compiler-utils/env/main/ISet.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/ISet.sml precompiled/x86-darwin/191.s
precompiled/x86-darwin/192.s: src/compiler-utils/env/main/IOrd.o src/compiler-utils/env/main/IOrd.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/IOrd.sml precompiled/x86-darwin/192.s
precompiled/x86-darwin/193.s: src/compiler/toolchain/main/BinUtils.o src/compiler/toolchain/main/BinUtils.sml
	@$(GENASM) x86-darwin src/compiler/toolchain/main/BinUtils.sml precompiled/x86-darwin/193.s
precompiled/x86-darwin/194.s: src/compiler/toolchain/main/TempFile.o src/compiler/toolchain/main/TempFile.sml
	@$(GENASM) x86-darwin src/compiler/toolchain/main/TempFile.sml precompiled/x86-darwin/194.s
precompiled/x86-darwin/195.s: src/compiler/toolchain/main/CoreUtils.o src/compiler/toolchain/main/CoreUtils.sml
	@$(GENASM) x86-darwin src/compiler/toolchain/main/CoreUtils.sml precompiled/x86-darwin/195.s
precompiled/x86-darwin/196.s: src/compiler/usererror/main/UserError.ppg.o src/compiler/usererror/main/UserError.ppg.sml
	@$(GENASM) x86-darwin src/compiler/usererror/main/UserError.ppg.sml precompiled/x86-darwin/196.s
precompiled/x86-darwin/197.s: src/compiler/util/main/Counter.o src/compiler/util/main/Counter.sml
	@$(GENASM) x86-darwin src/compiler/util/main/Counter.sml precompiled/x86-darwin/197.s
precompiled/x86-darwin/198.s: src/compiler-utils/env/main/IEnv.o src/compiler-utils/env/main/IEnv.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/IEnv.sml precompiled/x86-darwin/198.s
precompiled/x86-darwin/199.s: src/smlnj-lib/Util/binary-set-fn.o src/smlnj-lib/Util/binary-set-fn.sml
	@$(GENASM) x86-darwin src/smlnj-lib/Util/binary-set-fn.sml precompiled/x86-darwin/199.s
precompiled/x86-darwin/200.s: src/compiler/control/main/Control.ppg.o src/compiler/control/main/Control.ppg.sml
	@$(GENASM) x86-darwin src/compiler/control/main/Control.ppg.sml precompiled/x86-darwin/200.s
precompiled/x86-darwin/201.s: src/compiler/control/main/Loc.ppg.o src/compiler/control/main/Loc.ppg.sml
	@$(GENASM) x86-darwin src/compiler/control/main/Loc.ppg.sml precompiled/x86-darwin/201.s
precompiled/x86-darwin/202.s: src/smlformat/formatlib/main/SMLFormat.o src/smlformat/formatlib/main/SMLFormat.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/SMLFormat.sml precompiled/x86-darwin/202.s
precompiled/x86-darwin/203.s: src/smlformat/formatlib/main/BasicFormatters.o src/smlformat/formatlib/main/BasicFormatters.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/BasicFormatters.sml precompiled/x86-darwin/203.s
precompiled/x86-darwin/204.s: src/smlformat/formatlib/main/PreProcessor.o src/smlformat/formatlib/main/PreProcessor.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/PreProcessor.sml precompiled/x86-darwin/204.s
precompiled/x86-darwin/205.s: src/smlformat/formatlib/main/Truncator.o src/smlformat/formatlib/main/Truncator.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/Truncator.sml precompiled/x86-darwin/205.s
precompiled/x86-darwin/206.s: src/smlformat/formatlib/main/PrettyPrinter.o src/smlformat/formatlib/main/PrettyPrinter.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/PrettyPrinter.sml precompiled/x86-darwin/206.s
precompiled/x86-darwin/207.s: src/smlformat/formatlib/main/PreProcessedExpression.o src/smlformat/formatlib/main/PreProcessedExpression.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/PreProcessedExpression.sml precompiled/x86-darwin/207.s
precompiled/x86-darwin/208.s: src/smlformat/formatlib/main/AssocResolver.o src/smlformat/formatlib/main/AssocResolver.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/AssocResolver.sml precompiled/x86-darwin/208.s
precompiled/x86-darwin/209.s: src/smlformat/formatlib/main/PrinterParameter.o src/smlformat/formatlib/main/PrinterParameter.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/PrinterParameter.sml precompiled/x86-darwin/209.s
precompiled/x86-darwin/210.s: src/smlformat/formatlib/main/FormatExpression.o src/smlformat/formatlib/main/FormatExpression.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/FormatExpression.sml precompiled/x86-darwin/210.s
precompiled/x86-darwin/211.s: src/smlformat/formatlib/main/FormatExpressionTypes.o src/smlformat/formatlib/main/FormatExpressionTypes.sml
	@$(GENASM) x86-darwin src/smlformat/formatlib/main/FormatExpressionTypes.sml precompiled/x86-darwin/211.s
precompiled/x86-darwin/212.s: src/smlnj-lib/Util/parser-comb.o src/smlnj-lib/Util/parser-comb.sml
	@$(GENASM) x86-darwin src/smlnj-lib/Util/parser-comb.sml precompiled/x86-darwin/212.s
precompiled/x86-darwin/213.s: src/config/main/Config.o src/config/main/Config.sml
	@$(GENASM) x86-darwin src/config/main/Config.sml precompiled/x86-darwin/213.s
precompiled/x86-darwin/214.s: src/compiler/toolchain/main/Filename.o src/compiler/toolchain/main/Filename.sml
	@$(GENASM) x86-darwin src/compiler/toolchain/main/Filename.sml precompiled/x86-darwin/214.s
precompiled/x86-darwin/215.s: src/compiler-utils/env/main/SEnv.o src/compiler-utils/env/main/SEnv.sml
	@$(GENASM) x86-darwin src/compiler-utils/env/main/SEnv.sml precompiled/x86-darwin/215.s
precompiled/x86-darwin/216.s: src/smlnj-lib/Util/lib-base.o src/smlnj-lib/Util/lib-base.sml
	@$(GENASM) x86-darwin src/smlnj-lib/Util/lib-base.sml precompiled/x86-darwin/216.s
precompiled/x86-darwin/217.s: src/config/main/Version.o src/config/main/Version.sml
	@$(GENASM) x86-darwin src/config/main/Version.sml precompiled/x86-darwin/217.s
precompiled/x86-darwin/218.s: src/basis/main/binary-op.o src/basis/main/binary-op.sml
	@$(GENASM) x86-darwin src/basis/main/binary-op.sml precompiled/x86-darwin/218.s
precompiled/x86-darwin/219.s: src/basis/main/Date.o src/basis/main/Date.sml
	@$(GENASM) x86-darwin src/basis/main/Date.sml precompiled/x86-darwin/219.s
precompiled/x86-darwin/220.s: src/basis/main/Timer.o src/basis/main/Timer.sml
	@$(GENASM) x86-darwin src/basis/main/Timer.sml precompiled/x86-darwin/220.s
precompiled/x86-darwin/221.s: src/smlnj/Basis/internal-timer.o src/smlnj/Basis/internal-timer.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/internal-timer.sml precompiled/x86-darwin/221.s
precompiled/x86-darwin/222.s: src/basis/main/ArraySlice.o src/basis/main/ArraySlice.sml
	@$(GENASM) x86-darwin src/basis/main/ArraySlice.sml precompiled/x86-darwin/222.s
precompiled/x86-darwin/223.s: src/basis/main/CommandLine.o src/basis/main/CommandLine.sml
	@$(GENASM) x86-darwin src/basis/main/CommandLine.sml precompiled/x86-darwin/223.s
precompiled/x86-darwin/224.s: src/basis/main/Text.o src/basis/main/Text.sml
	@$(GENASM) x86-darwin src/basis/main/Text.sml precompiled/x86-darwin/224.s
precompiled/x86-darwin/225.s: src/basis/main/BinIO.o src/basis/main/BinIO.sml
	@$(GENASM) x86-darwin src/basis/main/BinIO.sml precompiled/x86-darwin/225.s
precompiled/x86-darwin/226.s: src/smlnj/Basis/IO/bin-io.o src/smlnj/Basis/IO/bin-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/IO/bin-io.sml precompiled/x86-darwin/226.s
precompiled/x86-darwin/227.s: src/smlnj/Basis/Unix/posix-bin-prim-io.o src/smlnj/Basis/Unix/posix-bin-prim-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/Unix/posix-bin-prim-io.sml precompiled/x86-darwin/227.s
precompiled/x86-darwin/228.s: src/basis/main/TextIO.o src/basis/main/TextIO.sml
	@$(GENASM) x86-darwin src/basis/main/TextIO.sml precompiled/x86-darwin/228.s
precompiled/x86-darwin/229.s: src/smlnj/Basis/IO/text-io.o src/smlnj/Basis/IO/text-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/IO/text-io.sml precompiled/x86-darwin/229.s
precompiled/x86-darwin/230.s: src/smlnj/Basis/Unix/posix-text-prim-io.o src/smlnj/Basis/Unix/posix-text-prim-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/Unix/posix-text-prim-io.sml precompiled/x86-darwin/230.s
precompiled/x86-darwin/231.s: src/smlnj/Basis/Posix/posix-io.o src/smlnj/Basis/Posix/posix-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/Posix/posix-io.sml precompiled/x86-darwin/231.s
precompiled/x86-darwin/232.s: src/smlnj/Basis/IO/prim-io-bin.o src/smlnj/Basis/IO/prim-io-bin.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/IO/prim-io-bin.sml precompiled/x86-darwin/232.s
precompiled/x86-darwin/233.s: src/basis/main/Word8.o src/basis/main/Word8.sml
	@$(GENASM) x86-darwin src/basis/main/Word8.sml precompiled/x86-darwin/233.s
precompiled/x86-darwin/234.s: src/smlnj/Basis/IO/clean-io.o src/smlnj/Basis/IO/clean-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/IO/clean-io.sml precompiled/x86-darwin/234.s
precompiled/x86-darwin/235.s: src/smlnj/Basis/IO/prim-io-text.o src/smlnj/Basis/IO/prim-io-text.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/IO/prim-io-text.sml precompiled/x86-darwin/235.s
precompiled/x86-darwin/236.s: src/basis/main/CharArray.o src/basis/main/CharArray.sml
	@$(GENASM) x86-darwin src/basis/main/CharArray.sml precompiled/x86-darwin/236.s
precompiled/x86-darwin/237.s: src/basis/main/OS.o src/basis/main/OS.sml
	@$(GENASM) x86-darwin src/basis/main/OS.sml precompiled/x86-darwin/237.s
precompiled/x86-darwin/238.s: src/smlnj/Basis/Unix/os-io.o src/smlnj/Basis/Unix/os-io.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/Unix/os-io.sml precompiled/x86-darwin/238.s
precompiled/x86-darwin/239.s: src/basis/main/ListPair.o src/basis/main/ListPair.sml
	@$(GENASM) x86-darwin src/basis/main/ListPair.sml precompiled/x86-darwin/239.s
precompiled/x86-darwin/240.s: src/smlnj/Basis/Unix/os-filesys.o src/smlnj/Basis/Unix/os-filesys.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/Unix/os-filesys.sml precompiled/x86-darwin/240.s
precompiled/x86-darwin/241.s: src/smlnj/Basis/Unix/os-path.o src/smlnj/Basis/Unix/os-path.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/Unix/os-path.sml precompiled/x86-darwin/241.s
precompiled/x86-darwin/242.s: src/smlnj/Basis/OS/os-path-fn.o src/smlnj/Basis/OS/os-path-fn.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/OS/os-path-fn.sml precompiled/x86-darwin/242.s
precompiled/x86-darwin/243.s: src/basis/main/SMLSharpOSProcess.o src/basis/main/SMLSharpOSProcess.sml
	@$(GENASM) x86-darwin src/basis/main/SMLSharpOSProcess.sml precompiled/x86-darwin/243.s
precompiled/x86-darwin/244.s: src/smlnj/Basis/NJ/cleanup.o src/smlnj/Basis/NJ/cleanup.sml
	@$(GENASM) x86-darwin src/smlnj/Basis/NJ/cleanup.sml precompiled/x86-darwin/244.s
precompiled/x86-darwin/245.s: src/basis/main/SMLSharpOSFileSys.o src/basis/main/SMLSharpOSFileSys.sml
	@$(GENASM) x86-darwin src/basis/main/SMLSharpOSFileSys.sml precompiled/x86-darwin/245.s
precompiled/x86-darwin/246.s: src/basis/main/Byte.o src/basis/main/Byte.sml
	@$(GENASM) x86-darwin src/basis/main/Byte.sml precompiled/x86-darwin/246.s
precompiled/x86-darwin/247.s: src/basis/main/Word8Array.o src/basis/main/Word8Array.sml
	@$(GENASM) x86-darwin src/basis/main/Word8Array.sml precompiled/x86-darwin/247.s
precompiled/x86-darwin/248.s: src/basis/main/Word.o src/basis/main/Word.sml
	@$(GENASM) x86-darwin src/basis/main/Word.sml precompiled/x86-darwin/248.s
precompiled/x86-darwin/249.s: src/basis/main/Time.o src/basis/main/Time.sml
	@$(GENASM) x86-darwin src/basis/main/Time.sml precompiled/x86-darwin/249.s
precompiled/x86-darwin/250.s: src/basis/main/Real32.o src/basis/main/Real32.sml
	@$(GENASM) x86-darwin src/basis/main/Real32.sml precompiled/x86-darwin/250.s
precompiled/x86-darwin/251.s: src/basis/main/Real.o src/basis/main/Real.sml
	@$(GENASM) x86-darwin src/basis/main/Real.sml precompiled/x86-darwin/251.s
precompiled/x86-darwin/252.s: src/basis/main/Substring.o src/basis/main/Substring.sml
	@$(GENASM) x86-darwin src/basis/main/Substring.sml precompiled/x86-darwin/252.s
precompiled/x86-darwin/253.s: src/basis/main/RealClass.o src/basis/main/RealClass.sml
	@$(GENASM) x86-darwin src/basis/main/RealClass.sml precompiled/x86-darwin/253.s
precompiled/x86-darwin/254.s: src/basis/main/IEEEReal.o src/basis/main/IEEEReal.sml
	@$(GENASM) x86-darwin src/basis/main/IEEEReal.sml precompiled/x86-darwin/254.s
precompiled/x86-darwin/255.s: src/basis/main/Int.o src/basis/main/Int.sml
	@$(GENASM) x86-darwin src/basis/main/Int.sml precompiled/x86-darwin/255.s
precompiled/x86-darwin/256.s: src/basis/main/IntInf.o src/basis/main/IntInf.sml
	@$(GENASM) x86-darwin src/basis/main/IntInf.sml precompiled/x86-darwin/256.s
precompiled/x86-darwin/257.s: src/basis/main/String.o src/basis/main/String.sml
	@$(GENASM) x86-darwin src/basis/main/String.sml precompiled/x86-darwin/257.s
precompiled/x86-darwin/258.s: src/basis/main/CharVectorSlice.o src/basis/main/CharVectorSlice.sml
	@$(GENASM) x86-darwin src/basis/main/CharVectorSlice.sml precompiled/x86-darwin/258.s
precompiled/x86-darwin/259.s: src/basis/main/CharVector.o src/basis/main/CharVector.sml
	@$(GENASM) x86-darwin src/basis/main/CharVector.sml precompiled/x86-darwin/259.s
precompiled/x86-darwin/260.s: src/basis/main/StringBase.o src/basis/main/StringBase.sml
	@$(GENASM) x86-darwin src/basis/main/StringBase.sml precompiled/x86-darwin/260.s
precompiled/x86-darwin/261.s: src/basis/main/SMLSharpRuntime.o src/basis/main/SMLSharpRuntime.sml
	@$(GENASM) x86-darwin src/basis/main/SMLSharpRuntime.sml precompiled/x86-darwin/261.s
precompiled/x86-darwin/262.s: src/basis/main/IO.o src/basis/main/IO.sml
	@$(GENASM) x86-darwin src/basis/main/IO.sml precompiled/x86-darwin/262.s
precompiled/x86-darwin/263.s: src/basis/main/Bool.o src/basis/main/Bool.sml
	@$(GENASM) x86-darwin src/basis/main/Bool.sml precompiled/x86-darwin/263.s
precompiled/x86-darwin/264.s: src/basis/main/Word8VectorSlice.o src/basis/main/Word8VectorSlice.sml
	@$(GENASM) x86-darwin src/basis/main/Word8VectorSlice.sml precompiled/x86-darwin/264.s
precompiled/x86-darwin/265.s: src/basis/main/Word8Vector.o src/basis/main/Word8Vector.sml
	@$(GENASM) x86-darwin src/basis/main/Word8Vector.sml precompiled/x86-darwin/265.s
precompiled/x86-darwin/266.s: src/basis/main/Char.o src/basis/main/Char.sml
	@$(GENASM) x86-darwin src/basis/main/Char.sml precompiled/x86-darwin/266.s
precompiled/x86-darwin/267.s: src/basis/main/SMLSharpScanChar.o src/basis/main/SMLSharpScanChar.sml
	@$(GENASM) x86-darwin src/basis/main/SMLSharpScanChar.sml precompiled/x86-darwin/267.s
precompiled/x86-darwin/268.s: src/basis/main/StringCvt.o src/basis/main/StringCvt.sml
	@$(GENASM) x86-darwin src/basis/main/StringCvt.sml precompiled/x86-darwin/268.s
precompiled/x86-darwin/269.s: src/basis/main/VectorSlice.o src/basis/main/VectorSlice.sml
	@$(GENASM) x86-darwin src/basis/main/VectorSlice.sml precompiled/x86-darwin/269.s
precompiled/x86-darwin/270.s: src/basis/main/Vector.o src/basis/main/Vector.sml
	@$(GENASM) x86-darwin src/basis/main/Vector.sml precompiled/x86-darwin/270.s
precompiled/x86-darwin/271.s: src/basis/main/Array.o src/basis/main/Array.sml
	@$(GENASM) x86-darwin src/basis/main/Array.sml precompiled/x86-darwin/271.s
precompiled/x86-darwin/272.s: src/basis/main/List.o src/basis/main/List.sml
	@$(GENASM) x86-darwin src/basis/main/List.sml precompiled/x86-darwin/272.s
precompiled/x86-darwin/273.s: src/basis/main/Option.o src/basis/main/Option.sml
	@$(GENASM) x86-darwin src/basis/main/Option.sml precompiled/x86-darwin/273.s
precompiled/x86-darwin/274.s: src/basis/main/General.o src/basis/main/General.sml
	@$(GENASM) x86-darwin src/basis/main/General.sml precompiled/x86-darwin/274.s
precompiled/x86-darwin.tar.xz:  precompiled/x86-darwin/000.s precompiled/x86-darwin/001.s precompiled/x86-darwin/002.s precompiled/x86-darwin/003.s precompiled/x86-darwin/004.s precompiled/x86-darwin/005.s precompiled/x86-darwin/006.s precompiled/x86-darwin/007.s precompiled/x86-darwin/008.s precompiled/x86-darwin/009.s precompiled/x86-darwin/010.s precompiled/x86-darwin/011.s precompiled/x86-darwin/012.s precompiled/x86-darwin/013.s precompiled/x86-darwin/014.s precompiled/x86-darwin/015.s precompiled/x86-darwin/016.s precompiled/x86-darwin/017.s precompiled/x86-darwin/018.s precompiled/x86-darwin/019.s precompiled/x86-darwin/020.s precompiled/x86-darwin/021.s precompiled/x86-darwin/022.s precompiled/x86-darwin/023.s precompiled/x86-darwin/024.s precompiled/x86-darwin/025.s precompiled/x86-darwin/026.s precompiled/x86-darwin/027.s precompiled/x86-darwin/028.s precompiled/x86-darwin/029.s precompiled/x86-darwin/030.s precompiled/x86-darwin/031.s precompiled/x86-darwin/032.s precompiled/x86-darwin/033.s precompiled/x86-darwin/034.s precompiled/x86-darwin/035.s precompiled/x86-darwin/036.s precompiled/x86-darwin/037.s precompiled/x86-darwin/038.s precompiled/x86-darwin/039.s precompiled/x86-darwin/040.s precompiled/x86-darwin/041.s precompiled/x86-darwin/042.s precompiled/x86-darwin/043.s precompiled/x86-darwin/044.s precompiled/x86-darwin/045.s precompiled/x86-darwin/046.s precompiled/x86-darwin/047.s precompiled/x86-darwin/048.s precompiled/x86-darwin/049.s precompiled/x86-darwin/050.s precompiled/x86-darwin/051.s precompiled/x86-darwin/052.s precompiled/x86-darwin/053.s precompiled/x86-darwin/054.s precompiled/x86-darwin/055.s precompiled/x86-darwin/056.s precompiled/x86-darwin/057.s precompiled/x86-darwin/058.s precompiled/x86-darwin/059.s precompiled/x86-darwin/060.s precompiled/x86-darwin/061.s precompiled/x86-darwin/062.s precompiled/x86-darwin/063.s precompiled/x86-darwin/064.s precompiled/x86-darwin/065.s precompiled/x86-darwin/066.s precompiled/x86-darwin/067.s precompiled/x86-darwin/068.s precompiled/x86-darwin/069.s precompiled/x86-darwin/070.s precompiled/x86-darwin/071.s precompiled/x86-darwin/072.s precompiled/x86-darwin/073.s precompiled/x86-darwin/074.s precompiled/x86-darwin/075.s precompiled/x86-darwin/076.s precompiled/x86-darwin/077.s precompiled/x86-darwin/078.s precompiled/x86-darwin/079.s precompiled/x86-darwin/080.s precompiled/x86-darwin/081.s precompiled/x86-darwin/082.s precompiled/x86-darwin/083.s precompiled/x86-darwin/084.s precompiled/x86-darwin/085.s precompiled/x86-darwin/086.s precompiled/x86-darwin/087.s precompiled/x86-darwin/088.s precompiled/x86-darwin/089.s precompiled/x86-darwin/090.s precompiled/x86-darwin/091.s precompiled/x86-darwin/092.s precompiled/x86-darwin/093.s precompiled/x86-darwin/094.s precompiled/x86-darwin/095.s precompiled/x86-darwin/096.s precompiled/x86-darwin/097.s precompiled/x86-darwin/098.s precompiled/x86-darwin/099.s precompiled/x86-darwin/100.s precompiled/x86-darwin/101.s precompiled/x86-darwin/102.s precompiled/x86-darwin/103.s precompiled/x86-darwin/104.s precompiled/x86-darwin/105.s precompiled/x86-darwin/106.s precompiled/x86-darwin/107.s precompiled/x86-darwin/108.s precompiled/x86-darwin/109.s precompiled/x86-darwin/110.s precompiled/x86-darwin/111.s precompiled/x86-darwin/112.s precompiled/x86-darwin/113.s precompiled/x86-darwin/114.s precompiled/x86-darwin/115.s precompiled/x86-darwin/116.s precompiled/x86-darwin/117.s precompiled/x86-darwin/118.s precompiled/x86-darwin/119.s precompiled/x86-darwin/120.s precompiled/x86-darwin/121.s precompiled/x86-darwin/122.s precompiled/x86-darwin/123.s precompiled/x86-darwin/124.s precompiled/x86-darwin/125.s precompiled/x86-darwin/126.s precompiled/x86-darwin/127.s precompiled/x86-darwin/128.s precompiled/x86-darwin/129.s precompiled/x86-darwin/130.s precompiled/x86-darwin/131.s precompiled/x86-darwin/132.s precompiled/x86-darwin/133.s precompiled/x86-darwin/134.s precompiled/x86-darwin/135.s precompiled/x86-darwin/136.s precompiled/x86-darwin/137.s precompiled/x86-darwin/138.s precompiled/x86-darwin/139.s precompiled/x86-darwin/140.s precompiled/x86-darwin/141.s precompiled/x86-darwin/142.s precompiled/x86-darwin/143.s precompiled/x86-darwin/144.s precompiled/x86-darwin/145.s precompiled/x86-darwin/146.s precompiled/x86-darwin/147.s precompiled/x86-darwin/148.s precompiled/x86-darwin/149.s precompiled/x86-darwin/150.s precompiled/x86-darwin/151.s precompiled/x86-darwin/152.s precompiled/x86-darwin/153.s precompiled/x86-darwin/154.s precompiled/x86-darwin/155.s precompiled/x86-darwin/156.s precompiled/x86-darwin/157.s precompiled/x86-darwin/158.s precompiled/x86-darwin/159.s precompiled/x86-darwin/160.s precompiled/x86-darwin/161.s precompiled/x86-darwin/162.s precompiled/x86-darwin/163.s precompiled/x86-darwin/164.s precompiled/x86-darwin/165.s precompiled/x86-darwin/166.s precompiled/x86-darwin/167.s precompiled/x86-darwin/168.s precompiled/x86-darwin/169.s precompiled/x86-darwin/170.s precompiled/x86-darwin/171.s precompiled/x86-darwin/172.s precompiled/x86-darwin/173.s precompiled/x86-darwin/174.s precompiled/x86-darwin/175.s precompiled/x86-darwin/176.s precompiled/x86-darwin/177.s precompiled/x86-darwin/178.s precompiled/x86-darwin/179.s precompiled/x86-darwin/180.s precompiled/x86-darwin/181.s precompiled/x86-darwin/182.s precompiled/x86-darwin/183.s precompiled/x86-darwin/184.s precompiled/x86-darwin/185.s precompiled/x86-darwin/186.s precompiled/x86-darwin/187.s precompiled/x86-darwin/188.s precompiled/x86-darwin/189.s precompiled/x86-darwin/190.s precompiled/x86-darwin/191.s precompiled/x86-darwin/192.s precompiled/x86-darwin/193.s precompiled/x86-darwin/194.s precompiled/x86-darwin/195.s precompiled/x86-darwin/196.s precompiled/x86-darwin/197.s precompiled/x86-darwin/198.s precompiled/x86-darwin/199.s precompiled/x86-darwin/200.s precompiled/x86-darwin/201.s precompiled/x86-darwin/202.s precompiled/x86-darwin/203.s precompiled/x86-darwin/204.s precompiled/x86-darwin/205.s precompiled/x86-darwin/206.s precompiled/x86-darwin/207.s precompiled/x86-darwin/208.s precompiled/x86-darwin/209.s precompiled/x86-darwin/210.s precompiled/x86-darwin/211.s precompiled/x86-darwin/212.s precompiled/x86-darwin/213.s precompiled/x86-darwin/214.s precompiled/x86-darwin/215.s precompiled/x86-darwin/216.s precompiled/x86-darwin/217.s precompiled/x86-darwin/218.s precompiled/x86-darwin/219.s precompiled/x86-darwin/220.s precompiled/x86-darwin/221.s precompiled/x86-darwin/222.s precompiled/x86-darwin/223.s precompiled/x86-darwin/224.s precompiled/x86-darwin/225.s precompiled/x86-darwin/226.s precompiled/x86-darwin/227.s precompiled/x86-darwin/228.s precompiled/x86-darwin/229.s precompiled/x86-darwin/230.s precompiled/x86-darwin/231.s precompiled/x86-darwin/232.s precompiled/x86-darwin/233.s precompiled/x86-darwin/234.s precompiled/x86-darwin/235.s precompiled/x86-darwin/236.s precompiled/x86-darwin/237.s precompiled/x86-darwin/238.s precompiled/x86-darwin/239.s precompiled/x86-darwin/240.s precompiled/x86-darwin/241.s precompiled/x86-darwin/242.s precompiled/x86-darwin/243.s precompiled/x86-darwin/244.s precompiled/x86-darwin/245.s precompiled/x86-darwin/246.s precompiled/x86-darwin/247.s precompiled/x86-darwin/248.s precompiled/x86-darwin/249.s precompiled/x86-darwin/250.s precompiled/x86-darwin/251.s precompiled/x86-darwin/252.s precompiled/x86-darwin/253.s precompiled/x86-darwin/254.s precompiled/x86-darwin/255.s precompiled/x86-darwin/256.s precompiled/x86-darwin/257.s precompiled/x86-darwin/258.s precompiled/x86-darwin/259.s precompiled/x86-darwin/260.s precompiled/x86-darwin/261.s precompiled/x86-darwin/262.s precompiled/x86-darwin/263.s precompiled/x86-darwin/264.s precompiled/x86-darwin/265.s precompiled/x86-darwin/266.s precompiled/x86-darwin/267.s precompiled/x86-darwin/268.s precompiled/x86-darwin/269.s precompiled/x86-darwin/270.s precompiled/x86-darwin/271.s precompiled/x86-darwin/272.s precompiled/x86-darwin/273.s precompiled/x86-darwin/274.s
	(cd precompiled && tar cf - x86-darwin/000.s x86-darwin/001.s x86-darwin/002.s x86-darwin/003.s x86-darwin/004.s x86-darwin/005.s x86-darwin/006.s x86-darwin/007.s x86-darwin/008.s x86-darwin/009.s x86-darwin/010.s x86-darwin/011.s x86-darwin/012.s x86-darwin/013.s x86-darwin/014.s x86-darwin/015.s x86-darwin/016.s x86-darwin/017.s x86-darwin/018.s x86-darwin/019.s x86-darwin/020.s x86-darwin/021.s x86-darwin/022.s x86-darwin/023.s x86-darwin/024.s x86-darwin/025.s x86-darwin/026.s x86-darwin/027.s x86-darwin/028.s x86-darwin/029.s x86-darwin/030.s x86-darwin/031.s x86-darwin/032.s x86-darwin/033.s x86-darwin/034.s x86-darwin/035.s x86-darwin/036.s x86-darwin/037.s x86-darwin/038.s x86-darwin/039.s x86-darwin/040.s x86-darwin/041.s x86-darwin/042.s x86-darwin/043.s x86-darwin/044.s x86-darwin/045.s x86-darwin/046.s x86-darwin/047.s x86-darwin/048.s x86-darwin/049.s x86-darwin/050.s x86-darwin/051.s x86-darwin/052.s x86-darwin/053.s x86-darwin/054.s x86-darwin/055.s x86-darwin/056.s x86-darwin/057.s x86-darwin/058.s x86-darwin/059.s x86-darwin/060.s x86-darwin/061.s x86-darwin/062.s x86-darwin/063.s x86-darwin/064.s x86-darwin/065.s x86-darwin/066.s x86-darwin/067.s x86-darwin/068.s x86-darwin/069.s x86-darwin/070.s x86-darwin/071.s x86-darwin/072.s x86-darwin/073.s x86-darwin/074.s x86-darwin/075.s x86-darwin/076.s x86-darwin/077.s x86-darwin/078.s x86-darwin/079.s x86-darwin/080.s x86-darwin/081.s x86-darwin/082.s x86-darwin/083.s x86-darwin/084.s x86-darwin/085.s x86-darwin/086.s x86-darwin/087.s x86-darwin/088.s x86-darwin/089.s x86-darwin/090.s x86-darwin/091.s x86-darwin/092.s x86-darwin/093.s x86-darwin/094.s x86-darwin/095.s x86-darwin/096.s x86-darwin/097.s x86-darwin/098.s x86-darwin/099.s x86-darwin/100.s x86-darwin/101.s x86-darwin/102.s x86-darwin/103.s x86-darwin/104.s x86-darwin/105.s x86-darwin/106.s x86-darwin/107.s x86-darwin/108.s x86-darwin/109.s x86-darwin/110.s x86-darwin/111.s x86-darwin/112.s x86-darwin/113.s x86-darwin/114.s x86-darwin/115.s x86-darwin/116.s x86-darwin/117.s x86-darwin/118.s x86-darwin/119.s x86-darwin/120.s x86-darwin/121.s x86-darwin/122.s x86-darwin/123.s x86-darwin/124.s x86-darwin/125.s x86-darwin/126.s x86-darwin/127.s x86-darwin/128.s x86-darwin/129.s x86-darwin/130.s x86-darwin/131.s x86-darwin/132.s x86-darwin/133.s x86-darwin/134.s x86-darwin/135.s x86-darwin/136.s x86-darwin/137.s x86-darwin/138.s x86-darwin/139.s x86-darwin/140.s x86-darwin/141.s x86-darwin/142.s x86-darwin/143.s x86-darwin/144.s x86-darwin/145.s x86-darwin/146.s x86-darwin/147.s x86-darwin/148.s x86-darwin/149.s x86-darwin/150.s x86-darwin/151.s x86-darwin/152.s x86-darwin/153.s x86-darwin/154.s x86-darwin/155.s x86-darwin/156.s x86-darwin/157.s x86-darwin/158.s x86-darwin/159.s x86-darwin/160.s x86-darwin/161.s x86-darwin/162.s x86-darwin/163.s x86-darwin/164.s x86-darwin/165.s x86-darwin/166.s x86-darwin/167.s x86-darwin/168.s x86-darwin/169.s x86-darwin/170.s x86-darwin/171.s x86-darwin/172.s x86-darwin/173.s x86-darwin/174.s x86-darwin/175.s x86-darwin/176.s x86-darwin/177.s x86-darwin/178.s x86-darwin/179.s x86-darwin/180.s x86-darwin/181.s x86-darwin/182.s x86-darwin/183.s x86-darwin/184.s x86-darwin/185.s x86-darwin/186.s x86-darwin/187.s x86-darwin/188.s x86-darwin/189.s x86-darwin/190.s x86-darwin/191.s x86-darwin/192.s x86-darwin/193.s x86-darwin/194.s x86-darwin/195.s x86-darwin/196.s x86-darwin/197.s x86-darwin/198.s x86-darwin/199.s x86-darwin/200.s x86-darwin/201.s x86-darwin/202.s x86-darwin/203.s x86-darwin/204.s x86-darwin/205.s x86-darwin/206.s x86-darwin/207.s x86-darwin/208.s x86-darwin/209.s x86-darwin/210.s x86-darwin/211.s x86-darwin/212.s x86-darwin/213.s x86-darwin/214.s x86-darwin/215.s x86-darwin/216.s x86-darwin/217.s x86-darwin/218.s x86-darwin/219.s x86-darwin/220.s x86-darwin/221.s x86-darwin/222.s x86-darwin/223.s x86-darwin/224.s x86-darwin/225.s x86-darwin/226.s x86-darwin/227.s x86-darwin/228.s x86-darwin/229.s x86-darwin/230.s x86-darwin/231.s x86-darwin/232.s x86-darwin/233.s x86-darwin/234.s x86-darwin/235.s x86-darwin/236.s x86-darwin/237.s x86-darwin/238.s x86-darwin/239.s x86-darwin/240.s x86-darwin/241.s x86-darwin/242.s x86-darwin/243.s x86-darwin/244.s x86-darwin/245.s x86-darwin/246.s x86-darwin/247.s x86-darwin/248.s x86-darwin/249.s x86-darwin/250.s x86-darwin/251.s x86-darwin/252.s x86-darwin/253.s x86-darwin/254.s x86-darwin/255.s x86-darwin/256.s x86-darwin/257.s x86-darwin/258.s x86-darwin/259.s x86-darwin/260.s x86-darwin/261.s x86-darwin/262.s x86-darwin/263.s x86-darwin/264.s x86-darwin/265.s x86-darwin/266.s x86-darwin/267.s x86-darwin/268.s x86-darwin/269.s x86-darwin/270.s x86-darwin/271.s x86-darwin/272.s x86-darwin/273.s x86-darwin/274.s | xz -c6) > $@
precompiled/x86-linux/000.s: src/compiler/minismlsharp.smi $(MINISMLSHARP_OBJECTS)
	@$(GENASM) x86-linux src/compiler/minismlsharp.smi precompiled/x86-linux/000.s
precompiled/x86-linux/001.s: src/compiler/minismlsharp.o src/compiler/minismlsharp.sml
	@$(GENASM) x86-linux src/compiler/minismlsharp.sml precompiled/x86-linux/001.s
precompiled/x86-linux/002.s: src/compiler/main/main/SimpleMain.o src/compiler/main/main/SimpleMain.sml
	@$(GENASM) x86-linux src/compiler/main/main/SimpleMain.sml precompiled/x86-linux/002.s
precompiled/x86-linux/003.s: src/compiler/main/main/ExecutablePath.o src/compiler/main/main/ExecutablePath.sml
	@$(GENASM) x86-linux src/compiler/main/main/ExecutablePath.sml precompiled/x86-linux/003.s
precompiled/x86-linux/004.s: src/compiler/main/main/RunLoop.o src/compiler/main/main/RunLoop.sml
	@$(GENASM) x86-linux src/compiler/main/main/RunLoop.sml precompiled/x86-linux/004.s
precompiled/x86-linux/005.s: src/sql/main/SQLPrim.o src/sql/main/SQLPrim.sml
	@$(GENASM) x86-linux src/sql/main/SQLPrim.sml precompiled/x86-linux/005.s
precompiled/x86-linux/006.s: src/sql/main/Backend.o src/sql/main/Backend.sml
	@$(GENASM) x86-linux src/sql/main/Backend.sml precompiled/x86-linux/006.s
precompiled/x86-linux/007.s: src/sql/main/PGSQLBackend.o src/sql/main/PGSQLBackend.sml
	@$(GENASM) x86-linux src/sql/main/PGSQLBackend.sml precompiled/x86-linux/007.s
precompiled/x86-linux/008.s: src/sql/main/PGSQL.o src/sql/main/PGSQL.sml
	@$(GENASM) x86-linux src/sql/main/PGSQL.sml precompiled/x86-linux/008.s
precompiled/x86-linux/009.s: src/ffi/main/Pointer.o src/ffi/main/Pointer.sml
	@$(GENASM) x86-linux src/ffi/main/Pointer.sml precompiled/x86-linux/009.s
precompiled/x86-linux/010.s: src/ffi/main/DynamicLink.o src/ffi/main/DynamicLink.sml
	@$(GENASM) x86-linux src/ffi/main/DynamicLink.sml precompiled/x86-linux/010.s
precompiled/x86-linux/011.s: src/compiler/main/main/SMLofNJ.o src/compiler/main/main/SMLofNJ.sml
	@$(GENASM) x86-linux src/compiler/main/main/SMLofNJ.sml precompiled/x86-linux/011.s
precompiled/x86-linux/012.s: src/compiler/main/main/GetOpt.o src/compiler/main/main/GetOpt.sml
	@$(GENASM) x86-linux src/compiler/main/main/GetOpt.sml precompiled/x86-linux/012.s
precompiled/x86-linux/013.s: src/compiler/toplevel2/main/Top.o src/compiler/toplevel2/main/Top.sml
	@$(GENASM) x86-linux src/compiler/toplevel2/main/Top.sml precompiled/x86-linux/013.s
precompiled/x86-linux/014.s: src/compiler/toplevel2/main/NameEvalEnvUtils.o src/compiler/toplevel2/main/NameEvalEnvUtils.sml
	@$(GENASM) x86-linux src/compiler/toplevel2/main/NameEvalEnvUtils.sml precompiled/x86-linux/014.s
precompiled/x86-linux/015.s: src/compiler/toplevel2/main/TopData.ppg.o src/compiler/toplevel2/main/TopData.ppg.sml
	@$(GENASM) x86-linux src/compiler/toplevel2/main/TopData.ppg.sml precompiled/x86-linux/015.s
precompiled/x86-linux/016.s: src/compiler/rtl/main/X86AsmGen.o src/compiler/rtl/main/X86AsmGen.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86AsmGen.sml precompiled/x86-linux/016.s
precompiled/x86-linux/017.s: src/compiler/rtl/main/X86Frame.o src/compiler/rtl/main/X86Frame.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Frame.sml precompiled/x86-linux/017.s
precompiled/x86-linux/018.s: src/compiler/rtl/main/FrameLayout.o src/compiler/rtl/main/FrameLayout.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/FrameLayout.sml precompiled/x86-linux/018.s
precompiled/x86-linux/019.s: src/compiler/rtl/main/X86Coloring.o src/compiler/rtl/main/X86Coloring.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Coloring.sml precompiled/x86-linux/019.s
precompiled/x86-linux/020.s: src/compiler/rtl/main/X86Constraint.o src/compiler/rtl/main/X86Constraint.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Constraint.sml precompiled/x86-linux/020.s
precompiled/x86-linux/021.s: src/compiler/rtl/main/RTLColoring.o src/compiler/rtl/main/RTLColoring.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLColoring.sml precompiled/x86-linux/021.s
precompiled/x86-linux/022.s: src/compiler/rtl/main/Coloring.o src/compiler/rtl/main/Coloring.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/Coloring.sml precompiled/x86-linux/022.s
precompiled/x86-linux/023.s: src/compiler/rtl/main/RTLRename.o src/compiler/rtl/main/RTLRename.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLRename.sml precompiled/x86-linux/023.s
precompiled/x86-linux/024.s: src/compiler/rtl/main/X86Stabilize.o src/compiler/rtl/main/X86Stabilize.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Stabilize.sml precompiled/x86-linux/024.s
precompiled/x86-linux/025.s: src/compiler/rtl/main/RTLStabilize.o src/compiler/rtl/main/RTLStabilize.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLStabilize.sml precompiled/x86-linux/025.s
precompiled/x86-linux/026.s: src/compiler/rtl/main/X86Select.o src/compiler/rtl/main/X86Select.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Select.sml precompiled/x86-linux/026.s
precompiled/x86-linux/027.s: src/compiler/rtl/main/RTLDominate.o src/compiler/rtl/main/RTLDominate.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLDominate.sml precompiled/x86-linux/027.s
precompiled/x86-linux/028.s: src/compiler/rtl/main/X86Subst.o src/compiler/rtl/main/X86Subst.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Subst.sml precompiled/x86-linux/028.s
precompiled/x86-linux/029.s: src/compiler/rtl/main/X86Emit.o src/compiler/rtl/main/X86Emit.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Emit.sml precompiled/x86-linux/029.s
precompiled/x86-linux/030.s: src/compiler/rtl/main/X86Asm.ppg.o src/compiler/rtl/main/X86Asm.ppg.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/X86Asm.ppg.sml precompiled/x86-linux/030.s
precompiled/x86-linux/031.s: src/compiler/rtl/main/IEEERealConst.o src/compiler/rtl/main/IEEERealConst.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/IEEERealConst.sml precompiled/x86-linux/031.s
precompiled/x86-linux/032.s: src/compiler/rtl/main/RTLBackendContext.o src/compiler/rtl/main/RTLBackendContext.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLBackendContext.sml precompiled/x86-linux/032.s
precompiled/x86-linux/033.s: src/compiler/rtl/main/RTLTypeCheck.o src/compiler/rtl/main/RTLTypeCheck.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLTypeCheck.sml precompiled/x86-linux/033.s
precompiled/x86-linux/034.s: src/compiler/rtl/main/RTLTypeCheckError.ppg.o src/compiler/rtl/main/RTLTypeCheckError.ppg.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLTypeCheckError.ppg.sml precompiled/x86-linux/034.s
precompiled/x86-linux/035.s: src/compiler/rtl/main/RTLLiveness.o src/compiler/rtl/main/RTLLiveness.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLLiveness.sml precompiled/x86-linux/035.s
precompiled/x86-linux/036.s: src/compiler/rtl/main/RTLUtils.o src/compiler/rtl/main/RTLUtils.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLUtils.sml precompiled/x86-linux/036.s
precompiled/x86-linux/037.s: src/compiler/rtl/main/RTLEdit.o src/compiler/rtl/main/RTLEdit.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTLEdit.sml precompiled/x86-linux/037.s
precompiled/x86-linux/038.s: src/compiler/rtl/main/RTL.ppg.o src/compiler/rtl/main/RTL.ppg.sml
	@$(GENASM) x86-linux src/compiler/rtl/main/RTL.ppg.sml precompiled/x86-linux/038.s
precompiled/x86-linux/039.s: src/compiler/aigenerator2/main/AIGenerator.o src/compiler/aigenerator2/main/AIGenerator.sml
	@$(GENASM) x86-linux src/compiler/aigenerator2/main/AIGenerator.sml precompiled/x86-linux/039.s
precompiled/x86-linux/040.s: src/compiler/aigenerator2/main/Simplify.o src/compiler/aigenerator2/main/Simplify.sml
	@$(GENASM) x86-linux src/compiler/aigenerator2/main/Simplify.sml precompiled/x86-linux/040.s
precompiled/x86-linux/041.s: src/compiler/aigenerator2/main/CallAnalysis.o src/compiler/aigenerator2/main/CallAnalysis.sml
	@$(GENASM) x86-linux src/compiler/aigenerator2/main/CallAnalysis.sml precompiled/x86-linux/041.s
precompiled/x86-linux/042.s: src/compiler/aigenerator2/main/BinarySearchCode.o src/compiler/aigenerator2/main/BinarySearchCode.sml
	@$(GENASM) x86-linux src/compiler/aigenerator2/main/BinarySearchCode.sml precompiled/x86-linux/042.s
precompiled/x86-linux/043.s: src/compiler/aigenerator2/main/AIPrimitive.o src/compiler/aigenerator2/main/AIPrimitive.sml
	@$(GENASM) x86-linux src/compiler/aigenerator2/main/AIPrimitive.sml precompiled/x86-linux/043.s
precompiled/x86-linux/044.s: src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.o src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.sml
	@$(GENASM) x86-linux src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.sml precompiled/x86-linux/044.s
precompiled/x86-linux/045.s: src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.o src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.sml
	@$(GENASM) x86-linux src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.sml precompiled/x86-linux/045.s
precompiled/x86-linux/046.s: src/compiler/targetplatform/main/VMTarget.o src/compiler/targetplatform/main/VMTarget.sml
	@$(GENASM) x86-linux src/compiler/targetplatform/main/VMTarget.sml precompiled/x86-linux/046.s
precompiled/x86-linux/047.s: src/compiler/targetplatform/main/TargetProperty.o src/compiler/targetplatform/main/TargetProperty.sml
	@$(GENASM) x86-linux src/compiler/targetplatform/main/TargetProperty.sml precompiled/x86-linux/047.s
precompiled/x86-linux/048.s: src/compiler/targetplatform/main/TargetPlatformFormatter.o src/compiler/targetplatform/main/TargetPlatformFormatter.sml
	@$(GENASM) x86-linux src/compiler/targetplatform/main/TargetPlatformFormatter.sml precompiled/x86-linux/048.s
precompiled/x86-linux/049.s: src/compiler/yaanormalization/main/StaticAllocation.o src/compiler/yaanormalization/main/StaticAllocation.sml
	@$(GENASM) x86-linux src/compiler/yaanormalization/main/StaticAllocation.sml precompiled/x86-linux/049.s
precompiled/x86-linux/050.s: src/compiler/yaanormalization/main/ANormalOptimization.o src/compiler/yaanormalization/main/ANormalOptimization.sml
	@$(GENASM) x86-linux src/compiler/yaanormalization/main/ANormalOptimization.sml precompiled/x86-linux/050.s
precompiled/x86-linux/051.s: src/compiler/toyaanormal/main/ToYAANormal.o src/compiler/toyaanormal/main/ToYAANormal.sml
	@$(GENASM) x86-linux src/compiler/toyaanormal/main/ToYAANormal.sml precompiled/x86-linux/051.s
precompiled/x86-linux/052.s: src/compiler/toyaanormal/main/NameMangle.o src/compiler/toyaanormal/main/NameMangle.sml
	@$(GENASM) x86-linux src/compiler/toyaanormal/main/NameMangle.sml precompiled/x86-linux/052.s
precompiled/x86-linux/053.s: src/compiler/yaanormal/main/ANormal.ppg.o src/compiler/yaanormal/main/ANormal.ppg.sml
	@$(GENASM) x86-linux src/compiler/yaanormal/main/ANormal.ppg.sml precompiled/x86-linux/053.s
precompiled/x86-linux/054.s: src/compiler/systemdef/main/BasicTypeFormatters.o src/compiler/systemdef/main/BasicTypeFormatters.sml
	@$(GENASM) x86-linux src/compiler/systemdef/main/BasicTypeFormatters.sml precompiled/x86-linux/054.s
precompiled/x86-linux/055.s: src/compiler/systemdef/main/BasicTypes.o src/compiler/systemdef/main/BasicTypes.sml
	@$(GENASM) x86-linux src/compiler/systemdef/main/BasicTypes.sml precompiled/x86-linux/055.s
precompiled/x86-linux/056.s: src/compiler/closureconversion/main/ClosureConversion.o src/compiler/closureconversion/main/ClosureConversion.sml
	@$(GENASM) x86-linux src/compiler/closureconversion/main/ClosureConversion.sml precompiled/x86-linux/056.s
precompiled/x86-linux/057.s: src/compiler/closureanormal/main/ClosureANormal.ppg.o src/compiler/closureanormal/main/ClosureANormal.ppg.sml
	@$(GENASM) x86-linux src/compiler/closureanormal/main/ClosureANormal.ppg.sml precompiled/x86-linux/057.s
precompiled/x86-linux/058.s: src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.o src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.sml
	@$(GENASM) x86-linux src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.sml precompiled/x86-linux/058.s
precompiled/x86-linux/059.s: src/compiler/bitmapanormalization/main/BitmapANormalization.o src/compiler/bitmapanormalization/main/BitmapANormalization.sml
	@$(GENASM) x86-linux src/compiler/bitmapanormalization/main/BitmapANormalization.sml precompiled/x86-linux/059.s
precompiled/x86-linux/060.s: src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.o src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.sml
	@$(GENASM) x86-linux src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.sml precompiled/x86-linux/060.s
precompiled/x86-linux/061.s: src/compiler/bitmapanormal/main/BitmapANormal.ppg.o src/compiler/bitmapanormal/main/BitmapANormal.ppg.sml
	@$(GENASM) x86-linux src/compiler/bitmapanormal/main/BitmapANormal.ppg.sml precompiled/x86-linux/061.s
precompiled/x86-linux/062.s: src/compiler/bitmapcompilation/main/BitmapCompilation.o src/compiler/bitmapcompilation/main/BitmapCompilation.sml
	@$(GENASM) x86-linux src/compiler/bitmapcompilation/main/BitmapCompilation.sml precompiled/x86-linux/062.s
precompiled/x86-linux/063.s: src/compiler/bitmapcompilation/main/SingletonTyEnv.o src/compiler/bitmapcompilation/main/SingletonTyEnv.sml
	@$(GENASM) x86-linux src/compiler/bitmapcompilation/main/SingletonTyEnv.sml precompiled/x86-linux/063.s
precompiled/x86-linux/064.s: src/compiler/bitmapcompilation/main/RecordLayout.o src/compiler/bitmapcompilation/main/RecordLayout.sml
	@$(GENASM) x86-linux src/compiler/bitmapcompilation/main/RecordLayout.sml precompiled/x86-linux/064.s
precompiled/x86-linux/065.s: src/compiler/runtimetypes/main/TypeLayout.o src/compiler/runtimetypes/main/TypeLayout.sml
	@$(GENASM) x86-linux src/compiler/runtimetypes/main/TypeLayout.sml precompiled/x86-linux/065.s
precompiled/x86-linux/066.s: src/compiler/runtimetypes/main/RuntimeTypes.ppg.o src/compiler/runtimetypes/main/RuntimeTypes.ppg.sml
	@$(GENASM) x86-linux src/compiler/runtimetypes/main/RuntimeTypes.ppg.sml precompiled/x86-linux/066.s
precompiled/x86-linux/067.s: src/compiler/bitmapcalc/main/BitmapCalc.ppg.o src/compiler/bitmapcalc/main/BitmapCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/bitmapcalc/main/BitmapCalc.ppg.sml precompiled/x86-linux/067.s
precompiled/x86-linux/068.s: src/compiler/recordunboxing/main/RecordUnboxing.o src/compiler/recordunboxing/main/RecordUnboxing.sml
	@$(GENASM) x86-linux src/compiler/recordunboxing/main/RecordUnboxing.sml precompiled/x86-linux/068.s
precompiled/x86-linux/069.s: src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.o src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.sml
	@$(GENASM) x86-linux src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.sml precompiled/x86-linux/069.s
precompiled/x86-linux/070.s: src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.o src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.sml
	@$(GENASM) x86-linux src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.sml precompiled/x86-linux/070.s
precompiled/x86-linux/071.s: src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.o src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.sml precompiled/x86-linux/071.s
precompiled/x86-linux/072.s: src/compiler/staticanalysis/main/StaticAnalysis.o src/compiler/staticanalysis/main/StaticAnalysis.sml
	@$(GENASM) x86-linux src/compiler/staticanalysis/main/StaticAnalysis.sml precompiled/x86-linux/072.s
precompiled/x86-linux/073.s: src/compiler/staticanalysis/main/SAContext.o src/compiler/staticanalysis/main/SAContext.sml
	@$(GENASM) x86-linux src/compiler/staticanalysis/main/SAContext.sml precompiled/x86-linux/073.s
precompiled/x86-linux/074.s: src/compiler/staticanalysis/main/SAConstraint.o src/compiler/staticanalysis/main/SAConstraint.sml
	@$(GENASM) x86-linux src/compiler/staticanalysis/main/SAConstraint.sml precompiled/x86-linux/074.s
precompiled/x86-linux/075.s: src/compiler/staticanalysis/main/ReduceTy.o src/compiler/staticanalysis/main/ReduceTy.sml
	@$(GENASM) x86-linux src/compiler/staticanalysis/main/ReduceTy.sml precompiled/x86-linux/075.s
precompiled/x86-linux/076.s: src/compiler/annotatedtypes/main/AnnotatedTypesUtils.o src/compiler/annotatedtypes/main/AnnotatedTypesUtils.sml
	@$(GENASM) x86-linux src/compiler/annotatedtypes/main/AnnotatedTypesUtils.sml precompiled/x86-linux/076.s
precompiled/x86-linux/077.s: src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.o src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.sml
	@$(GENASM) x86-linux src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.sml precompiled/x86-linux/077.s
precompiled/x86-linux/078.s: src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.o src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.sml precompiled/x86-linux/078.s
precompiled/x86-linux/079.s: src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.o src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.sml
	@$(GENASM) x86-linux src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.sml precompiled/x86-linux/079.s
precompiled/x86-linux/080.s: src/compiler/datatypecompilation/main/DatatypeCompilation.o src/compiler/datatypecompilation/main/DatatypeCompilation.sml
	@$(GENASM) x86-linux src/compiler/datatypecompilation/main/DatatypeCompilation.sml precompiled/x86-linux/080.s
precompiled/x86-linux/081.s: src/compiler/typedlambda/main/TypedLambdaFormatter.o src/compiler/typedlambda/main/TypedLambdaFormatter.sml
	@$(GENASM) x86-linux src/compiler/typedlambda/main/TypedLambdaFormatter.sml precompiled/x86-linux/081.s
precompiled/x86-linux/082.s: src/compiler/typedlambda/main/TypedLambda.ppg.o src/compiler/typedlambda/main/TypedLambda.ppg.sml
	@$(GENASM) x86-linux src/compiler/typedlambda/main/TypedLambda.ppg.sml precompiled/x86-linux/082.s
precompiled/x86-linux/083.s: src/compiler/recordcompilation/main/RecordCompilation.o src/compiler/recordcompilation/main/RecordCompilation.sml
	@$(GENASM) x86-linux src/compiler/recordcompilation/main/RecordCompilation.sml precompiled/x86-linux/083.s
precompiled/x86-linux/084.s: src/compiler/recordcompilation/main/UnivKind.o src/compiler/recordcompilation/main/UnivKind.sml
	@$(GENASM) x86-linux src/compiler/recordcompilation/main/UnivKind.sml precompiled/x86-linux/084.s
precompiled/x86-linux/085.s: src/compiler/recordcompilation/main/RecordKind.o src/compiler/recordcompilation/main/RecordKind.sml
	@$(GENASM) x86-linux src/compiler/recordcompilation/main/RecordKind.sml precompiled/x86-linux/085.s
precompiled/x86-linux/086.s: src/compiler/recordcompilation/main/OverloadKind.o src/compiler/recordcompilation/main/OverloadKind.sml
	@$(GENASM) x86-linux src/compiler/recordcompilation/main/OverloadKind.sml precompiled/x86-linux/086.s
precompiled/x86-linux/087.s: src/compiler/fficompilation/main/FFICompilation.o src/compiler/fficompilation/main/FFICompilation.sml
	@$(GENASM) x86-linux src/compiler/fficompilation/main/FFICompilation.sml precompiled/x86-linux/087.s
precompiled/x86-linux/088.s: src/compiler/sqlcompilation/main/SQLCompilation.o src/compiler/sqlcompilation/main/SQLCompilation.sml
	@$(GENASM) x86-linux src/compiler/sqlcompilation/main/SQLCompilation.sml precompiled/x86-linux/088.s
precompiled/x86-linux/089.s: src/compiler/matchcompilation/main/MatchCompiler.o src/compiler/matchcompilation/main/MatchCompiler.sml
	@$(GENASM) x86-linux src/compiler/matchcompilation/main/MatchCompiler.sml precompiled/x86-linux/089.s
precompiled/x86-linux/090.s: src/compiler/matchcompilation/main/MatchError.ppg.o src/compiler/matchcompilation/main/MatchError.ppg.sml
	@$(GENASM) x86-linux src/compiler/matchcompilation/main/MatchError.ppg.sml precompiled/x86-linux/090.s
precompiled/x86-linux/091.s: src/compiler/matchcompilation/main/MatchData.o src/compiler/matchcompilation/main/MatchData.sml
	@$(GENASM) x86-linux src/compiler/matchcompilation/main/MatchData.sml precompiled/x86-linux/091.s
precompiled/x86-linux/092.s: src/compiler/recordcalc/main/RecordCalcFormatter.o src/compiler/recordcalc/main/RecordCalcFormatter.sml
	@$(GENASM) x86-linux src/compiler/recordcalc/main/RecordCalcFormatter.sml precompiled/x86-linux/092.s
precompiled/x86-linux/093.s: src/compiler/recordcalc/main/RecordCalc.ppg.o src/compiler/recordcalc/main/RecordCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/recordcalc/main/RecordCalc.ppg.sml precompiled/x86-linux/093.s
precompiled/x86-linux/094.s: src/compiler/reflection/main/PrinterGeneration.o src/compiler/reflection/main/PrinterGeneration.sml
	@$(GENASM) x86-linux src/compiler/reflection/main/PrinterGeneration.sml precompiled/x86-linux/094.s
precompiled/x86-linux/095.s: src/compiler/reflection/main/Reify.o src/compiler/reflection/main/Reify.sml
	@$(GENASM) x86-linux src/compiler/reflection/main/Reify.sml precompiled/x86-linux/095.s
precompiled/x86-linux/096.s: src/compiler/reflection/main/ReifiedTermData.o src/compiler/reflection/main/ReifiedTermData.sml
	@$(GENASM) x86-linux src/compiler/reflection/main/ReifiedTermData.sml precompiled/x86-linux/096.s
precompiled/x86-linux/097.s: src/reifiedterm/main/ReifiedTerm.ppg.o src/reifiedterm/main/ReifiedTerm.ppg.sml
	@$(GENASM) x86-linux src/reifiedterm/main/ReifiedTerm.ppg.sml precompiled/x86-linux/097.s
precompiled/x86-linux/098.s: src/reifiedterm/main/TermPrintUtils.ppg.o src/reifiedterm/main/TermPrintUtils.ppg.sml
	@$(GENASM) x86-linux src/reifiedterm/main/TermPrintUtils.ppg.sml precompiled/x86-linux/098.s
precompiled/x86-linux/099.s: src/reifiedterm/main/ReflectionControl.o src/reifiedterm/main/ReflectionControl.sml
	@$(GENASM) x86-linux src/reifiedterm/main/ReflectionControl.sml precompiled/x86-linux/099.s
precompiled/x86-linux/100.s: src/compiler/typeinference2/main/UncurryFundecl_ng.o src/compiler/typeinference2/main/UncurryFundecl_ng.sml
	@$(GENASM) x86-linux src/compiler/typeinference2/main/UncurryFundecl_ng.sml precompiled/x86-linux/100.s
precompiled/x86-linux/101.s: src/compiler/typeinference2/main/InferTypes2.o src/compiler/typeinference2/main/InferTypes2.sml
	@$(GENASM) x86-linux src/compiler/typeinference2/main/InferTypes2.sml precompiled/x86-linux/101.s
precompiled/x86-linux/102.s: src/compiler/typeinference2/main/Printers.o src/compiler/typeinference2/main/Printers.sml
	@$(GENASM) x86-linux src/compiler/typeinference2/main/Printers.sml precompiled/x86-linux/102.s
precompiled/x86-linux/103.s: src/compiler/typeinference2/main/TypeInferenceUtils.o src/compiler/typeinference2/main/TypeInferenceUtils.sml
	@$(GENASM) x86-linux src/compiler/typeinference2/main/TypeInferenceUtils.sml precompiled/x86-linux/103.s
precompiled/x86-linux/104.s: src/compiler/typeinference2/main/TypeInferenceError.ppg.o src/compiler/typeinference2/main/TypeInferenceError.ppg.sml
	@$(GENASM) x86-linux src/compiler/typeinference2/main/TypeInferenceError.ppg.sml precompiled/x86-linux/104.s
precompiled/x86-linux/105.s: src/compiler/typeinference2/main/TypeInferenceContext.ppg.o src/compiler/typeinference2/main/TypeInferenceContext.ppg.sml
	@$(GENASM) x86-linux src/compiler/typeinference2/main/TypeInferenceContext.ppg.sml precompiled/x86-linux/105.s
precompiled/x86-linux/106.s: src/compiler/types/main/Unify.o src/compiler/types/main/Unify.sml
	@$(GENASM) x86-linux src/compiler/types/main/Unify.sml precompiled/x86-linux/106.s
precompiled/x86-linux/107.s: src/compiler/types/main/CheckEq.o src/compiler/types/main/CheckEq.sml
	@$(GENASM) x86-linux src/compiler/types/main/CheckEq.sml precompiled/x86-linux/107.s
precompiled/x86-linux/108.s: src/compiler/typedcalc/main/TypedCalcUtils.o src/compiler/typedcalc/main/TypedCalcUtils.sml
	@$(GENASM) x86-linux src/compiler/typedcalc/main/TypedCalcUtils.sml precompiled/x86-linux/108.s
precompiled/x86-linux/109.s: src/compiler/constantterm/main/ConstantTerm.ppg.o src/compiler/constantterm/main/ConstantTerm.ppg.sml
	@$(GENASM) x86-linux src/compiler/constantterm/main/ConstantTerm.ppg.sml precompiled/x86-linux/109.s
precompiled/x86-linux/110.s: src/compiler/types/main/TypesUtils.o src/compiler/types/main/TypesUtils.sml
	@$(GENASM) x86-linux src/compiler/types/main/TypesUtils.sml precompiled/x86-linux/110.s
precompiled/x86-linux/111.s: src/compiler/types/main/vars.o src/compiler/types/main/vars.sml
	@$(GENASM) x86-linux src/compiler/types/main/vars.sml precompiled/x86-linux/111.s
precompiled/x86-linux/112.s: src/compiler/typedcalc/main/TypedCalc.ppg.o src/compiler/typedcalc/main/TypedCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/typedcalc/main/TypedCalc.ppg.sml precompiled/x86-linux/112.s
precompiled/x86-linux/113.s: src/compiler/valrecoptimization/main/TransFundecl.o src/compiler/valrecoptimization/main/TransFundecl.sml
	@$(GENASM) x86-linux src/compiler/valrecoptimization/main/TransFundecl.sml precompiled/x86-linux/113.s
precompiled/x86-linux/114.s: src/compiler/valrecoptimization/main/VALREC_Optimizer.o src/compiler/valrecoptimization/main/VALREC_Optimizer.sml
	@$(GENASM) x86-linux src/compiler/valrecoptimization/main/VALREC_Optimizer.sml precompiled/x86-linux/114.s
precompiled/x86-linux/115.s: src/compiler/valrecoptimization/main/utils.o src/compiler/valrecoptimization/main/utils.sml
	@$(GENASM) x86-linux src/compiler/valrecoptimization/main/utils.sml precompiled/x86-linux/115.s
precompiled/x86-linux/116.s: src/compiler/nameevaluation/main/NameEval.o src/compiler/nameevaluation/main/NameEval.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/NameEval.sml precompiled/x86-linux/116.s
precompiled/x86-linux/117.s: src/compiler/nameevaluation/main/CheckProvide.o src/compiler/nameevaluation/main/CheckProvide.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/CheckProvide.sml precompiled/x86-linux/117.s
precompiled/x86-linux/118.s: src/compiler/nameevaluation/main/NameEvalInterface.o src/compiler/nameevaluation/main/NameEvalInterface.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/NameEvalInterface.sml precompiled/x86-linux/118.s
precompiled/x86-linux/119.s: src/compiler/nameevaluation/main/SigCheck.o src/compiler/nameevaluation/main/SigCheck.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/SigCheck.sml precompiled/x86-linux/119.s
precompiled/x86-linux/120.s: src/compiler/nameevaluation/main/FunctorUtils.o src/compiler/nameevaluation/main/FunctorUtils.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/FunctorUtils.sml precompiled/x86-linux/120.s
precompiled/x86-linux/121.s: src/compiler/nameevaluation/main/EvalSig.o src/compiler/nameevaluation/main/EvalSig.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/EvalSig.sml precompiled/x86-linux/121.s
precompiled/x86-linux/122.s: src/compiler/nameevaluation/main/Subst.o src/compiler/nameevaluation/main/Subst.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/Subst.sml precompiled/x86-linux/122.s
precompiled/x86-linux/123.s: src/compiler/nameevaluation/main/EvalTy.o src/compiler/nameevaluation/main/EvalTy.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/EvalTy.sml precompiled/x86-linux/123.s
precompiled/x86-linux/124.s: src/compiler/nameevaluation/main/SetLiftedTys.o src/compiler/nameevaluation/main/SetLiftedTys.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/SetLiftedTys.sml precompiled/x86-linux/124.s
precompiled/x86-linux/125.s: src/compiler/util/main/SCCFun.o src/compiler/util/main/SCCFun.sml
	@$(GENASM) x86-linux src/compiler/util/main/SCCFun.sml precompiled/x86-linux/125.s
precompiled/x86-linux/126.s: src/compiler/util/main/Graph.o src/compiler/util/main/Graph.sml
	@$(GENASM) x86-linux src/compiler/util/main/Graph.sml precompiled/x86-linux/126.s
precompiled/x86-linux/127.s: src/compiler/nameevaluation/main/NormalizeTy.o src/compiler/nameevaluation/main/NormalizeTy.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/NormalizeTy.sml precompiled/x86-linux/127.s
precompiled/x86-linux/128.s: src/compiler/nameevaluation/main/NameEvalUtils.o src/compiler/nameevaluation/main/NameEvalUtils.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/NameEvalUtils.sml precompiled/x86-linux/128.s
precompiled/x86-linux/129.s: src/compiler/nameevaluation/main/TfunVars.o src/compiler/nameevaluation/main/TfunVars.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/TfunVars.sml precompiled/x86-linux/129.s
precompiled/x86-linux/130.s: src/compiler-utils/env/main/PathEnv.o src/compiler-utils/env/main/PathEnv.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/PathEnv.sml precompiled/x86-linux/130.s
precompiled/x86-linux/131.s: src/compiler/nameevaluation/main/NameEvalEnv.ppg.o src/compiler/nameevaluation/main/NameEvalEnv.ppg.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/NameEvalEnv.ppg.sml precompiled/x86-linux/131.s
precompiled/x86-linux/132.s: src/compiler/nameevaluation/main/NameEvalError.ppg.o src/compiler/nameevaluation/main/NameEvalError.ppg.sml
	@$(GENASM) x86-linux src/compiler/nameevaluation/main/NameEvalError.ppg.sml precompiled/x86-linux/132.s
precompiled/x86-linux/133.s: src/compiler/elaborate/main/Elaborator.o src/compiler/elaborate/main/Elaborator.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/Elaborator.sml precompiled/x86-linux/133.s
precompiled/x86-linux/134.s: src/compiler/elaborate/main/ElaborateInterface.o src/compiler/elaborate/main/ElaborateInterface.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaborateInterface.sml precompiled/x86-linux/134.s
precompiled/x86-linux/135.s: src/compiler/elaborate/main/UserTvarScope.o src/compiler/elaborate/main/UserTvarScope.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/UserTvarScope.sml precompiled/x86-linux/135.s
precompiled/x86-linux/136.s: src/compiler/elaborate/main/ElaborateModule.o src/compiler/elaborate/main/ElaborateModule.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaborateModule.sml precompiled/x86-linux/136.s
precompiled/x86-linux/137.s: src/compiler/elaborate/main/ElaborateCore.o src/compiler/elaborate/main/ElaborateCore.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaborateCore.sml precompiled/x86-linux/137.s
precompiled/x86-linux/138.s: src/compiler/elaborate/main/ElaborateSQL.o src/compiler/elaborate/main/ElaborateSQL.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaborateSQL.sml precompiled/x86-linux/138.s
precompiled/x86-linux/139.s: src/compiler/elaborate/main/ElaborateErrorSQL.ppg.o src/compiler/elaborate/main/ElaborateErrorSQL.ppg.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaborateErrorSQL.ppg.sml precompiled/x86-linux/139.s
precompiled/x86-linux/140.s: src/compiler/elaborate/main/ElaboratorUtils.o src/compiler/elaborate/main/ElaboratorUtils.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaboratorUtils.sml precompiled/x86-linux/140.s
precompiled/x86-linux/141.s: src/compiler/util/main/utils.o src/compiler/util/main/utils.sml
	@$(GENASM) x86-linux src/compiler/util/main/utils.sml precompiled/x86-linux/141.s
precompiled/x86-linux/142.s: src/compiler/usererror/main/UserErrorUtils.o src/compiler/usererror/main/UserErrorUtils.sml
	@$(GENASM) x86-linux src/compiler/usererror/main/UserErrorUtils.sml precompiled/x86-linux/142.s
precompiled/x86-linux/143.s: src/compiler/elaborate/main/ElaborateError.ppg.o src/compiler/elaborate/main/ElaborateError.ppg.sml
	@$(GENASM) x86-linux src/compiler/elaborate/main/ElaborateError.ppg.sml precompiled/x86-linux/143.s
precompiled/x86-linux/144.s: src/compiler/absyn/main/Fixity.o src/compiler/absyn/main/Fixity.sml
	@$(GENASM) x86-linux src/compiler/absyn/main/Fixity.sml precompiled/x86-linux/144.s
precompiled/x86-linux/145.s: src/compiler/loadfile/main/LoadFile.o src/compiler/loadfile/main/LoadFile.sml
	@$(GENASM) x86-linux src/compiler/loadfile/main/LoadFile.sml precompiled/x86-linux/145.s
precompiled/x86-linux/146.s: src/compiler/loadfile/main/LoadFileError.ppg.o src/compiler/loadfile/main/LoadFileError.ppg.sml
	@$(GENASM) x86-linux src/compiler/loadfile/main/LoadFileError.ppg.sml precompiled/x86-linux/146.s
precompiled/x86-linux/147.s: src/compiler/loadfile/main/InterfaceHash.o src/compiler/loadfile/main/InterfaceHash.sml
	@$(GENASM) x86-linux src/compiler/loadfile/main/InterfaceHash.sml precompiled/x86-linux/147.s
precompiled/x86-linux/148.s: src/compiler/loadfile/main/SHA1.o src/compiler/loadfile/main/SHA1.sml
	@$(GENASM) x86-linux src/compiler/loadfile/main/SHA1.sml precompiled/x86-linux/148.s
precompiled/x86-linux/149.s: src/compiler/parser/main/InterfaceParser.o src/compiler/parser/main/InterfaceParser.sml
	@$(GENASM) x86-linux src/compiler/parser/main/InterfaceParser.sml precompiled/x86-linux/149.s
precompiled/x86-linux/150.s: src/compiler/parser/main/interface.grm.o src/compiler/parser/main/interface.grm.sml
	@$(GENASM) x86-linux src/compiler/parser/main/interface.grm.sml precompiled/x86-linux/150.s
precompiled/x86-linux/151.s: src/compiler/patterncalc/main/PatternCalcInterface.ppg.o src/compiler/patterncalc/main/PatternCalcInterface.ppg.sml
	@$(GENASM) x86-linux src/compiler/patterncalc/main/PatternCalcInterface.ppg.sml precompiled/x86-linux/151.s
precompiled/x86-linux/152.s: src/compiler/absyn/main/AbsynFormatter.o src/compiler/absyn/main/AbsynFormatter.sml
	@$(GENASM) x86-linux src/compiler/absyn/main/AbsynFormatter.sml precompiled/x86-linux/152.s
precompiled/x86-linux/153.s: src/compiler/builtin/main/BuiltinContextSources.o src/compiler/builtin/main/BuiltinContextSources.sml
	@$(GENASM) x86-linux src/compiler/builtin/main/BuiltinContextSources.sml precompiled/x86-linux/153.s
precompiled/x86-linux/154.s: src/compiler/builtin/main/BuiltinContext_smi.o src/compiler/builtin/main/BuiltinContext_smi.sml
	@$(GENASM) x86-linux src/compiler/builtin/main/BuiltinContext_smi.sml precompiled/x86-linux/154.s
precompiled/x86-linux/155.s: src/compiler/types/main/BuiltinEnv.o src/compiler/types/main/BuiltinEnv.sml
	@$(GENASM) x86-linux src/compiler/types/main/BuiltinEnv.sml precompiled/x86-linux/155.s
precompiled/x86-linux/156.s: src/compiler/types/main/EvalIty.o src/compiler/types/main/EvalIty.sml
	@$(GENASM) x86-linux src/compiler/types/main/EvalIty.sml precompiled/x86-linux/156.s
precompiled/x86-linux/157.s: src/compiler/types/main/OPrimMap.o src/compiler/types/main/OPrimMap.sml
	@$(GENASM) x86-linux src/compiler/types/main/OPrimMap.sml precompiled/x86-linux/157.s
precompiled/x86-linux/158.s: src/compiler/types/main/VarMap.o src/compiler/types/main/VarMap.sml
	@$(GENASM) x86-linux src/compiler/types/main/VarMap.sml precompiled/x86-linux/158.s
precompiled/x86-linux/159.s: src/compiler/types/main/IDCalc.ppg.o src/compiler/types/main/IDCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/types/main/IDCalc.ppg.sml precompiled/x86-linux/159.s
precompiled/x86-linux/160.s: src/compiler/types/main/Types.ppg.o src/compiler/types/main/Types.ppg.sml
	@$(GENASM) x86-linux src/compiler/types/main/Types.ppg.sml precompiled/x86-linux/160.s
precompiled/x86-linux/161.s: src/compiler/types/main/OPrimInstMap.o src/compiler/types/main/OPrimInstMap.sml
	@$(GENASM) x86-linux src/compiler/types/main/OPrimInstMap.sml precompiled/x86-linux/161.s
precompiled/x86-linux/162.s: src/compiler/types/main/tvarMap.o src/compiler/types/main/tvarMap.sml
	@$(GENASM) x86-linux src/compiler/types/main/tvarMap.sml precompiled/x86-linux/162.s
precompiled/x86-linux/163.s: src/compiler/patterncalc/main/PatternCalc.ppg.o src/compiler/patterncalc/main/PatternCalc.ppg.sml
	@$(GENASM) x86-linux src/compiler/patterncalc/main/PatternCalc.ppg.sml precompiled/x86-linux/163.s
precompiled/x86-linux/164.s: src/compiler/builtin/main/BuiltinPrimitive.ppg.o src/compiler/builtin/main/BuiltinPrimitive.ppg.sml
	@$(GENASM) x86-linux src/compiler/builtin/main/BuiltinPrimitive.ppg.sml precompiled/x86-linux/164.s
precompiled/x86-linux/165.s: src/compiler/util/main/gensym.o src/compiler/util/main/gensym.sml
	@$(GENASM) x86-linux src/compiler/util/main/gensym.sml precompiled/x86-linux/165.s
precompiled/x86-linux/166.s: src/compiler/builtin/main/BuiltinName.o src/compiler/builtin/main/BuiltinName.sml
	@$(GENASM) x86-linux src/compiler/builtin/main/BuiltinName.sml precompiled/x86-linux/166.s
precompiled/x86-linux/167.s: src/compiler/builtin/main/BuiltinType.ppg.o src/compiler/builtin/main/BuiltinType.ppg.sml
	@$(GENASM) x86-linux src/compiler/builtin/main/BuiltinType.ppg.sml precompiled/x86-linux/167.s
precompiled/x86-linux/168.s: src/compiler/generatemain/main/GenerateMain.o src/compiler/generatemain/main/GenerateMain.sml
	@$(GENASM) x86-linux src/compiler/generatemain/main/GenerateMain.sml precompiled/x86-linux/168.s
precompiled/x86-linux/169.s: src/compiler/generatemain/main/GenerateMainError.ppg.o src/compiler/generatemain/main/GenerateMainError.ppg.sml
	@$(GENASM) x86-linux src/compiler/generatemain/main/GenerateMainError.ppg.sml precompiled/x86-linux/169.s
precompiled/x86-linux/170.s: src/compiler/parser/main/Parser.o src/compiler/parser/main/Parser.sml
	@$(GENASM) x86-linux src/compiler/parser/main/Parser.sml precompiled/x86-linux/170.s
precompiled/x86-linux/171.s: src/compiler/parser/main/iml.lex.o src/compiler/parser/main/iml.lex.sml
	@$(GENASM) x86-linux src/compiler/parser/main/iml.lex.sml precompiled/x86-linux/171.s
precompiled/x86-linux/172.s: src/compiler/parser/main/iml.grm.o src/compiler/parser/main/iml.grm.sml
	@$(GENASM) x86-linux src/compiler/parser/main/iml.grm.sml precompiled/x86-linux/172.s
precompiled/x86-linux/173.s: src/compiler/parser/main/ParserError.ppg.o src/compiler/parser/main/ParserError.ppg.sml
	@$(GENASM) x86-linux src/compiler/parser/main/ParserError.ppg.sml precompiled/x86-linux/173.s
precompiled/x86-linux/174.s: src/ml-yacc/lib/parser2.o src/ml-yacc/lib/parser2.sml
	@$(GENASM) x86-linux src/ml-yacc/lib/parser2.sml precompiled/x86-linux/174.s
precompiled/x86-linux/175.s: src/ml-yacc/lib/stream.o src/ml-yacc/lib/stream.sml
	@$(GENASM) x86-linux src/ml-yacc/lib/stream.sml precompiled/x86-linux/175.s
precompiled/x86-linux/176.s: src/ml-yacc/lib/lrtable.o src/ml-yacc/lib/lrtable.sml
	@$(GENASM) x86-linux src/ml-yacc/lib/lrtable.sml precompiled/x86-linux/176.s
precompiled/x86-linux/177.s: src/ml-yacc/lib/join.o src/ml-yacc/lib/join.sml
	@$(GENASM) x86-linux src/ml-yacc/lib/join.sml precompiled/x86-linux/177.s
precompiled/x86-linux/178.s: src/compiler/absyn/main/AbsynInterface.ppg.o src/compiler/absyn/main/AbsynInterface.ppg.sml
	@$(GENASM) x86-linux src/compiler/absyn/main/AbsynInterface.ppg.sml precompiled/x86-linux/178.s
precompiled/x86-linux/179.s: src/compiler/absyn/main/Absyn.ppg.o src/compiler/absyn/main/Absyn.ppg.sml
	@$(GENASM) x86-linux src/compiler/absyn/main/Absyn.ppg.sml precompiled/x86-linux/179.s
precompiled/x86-linux/180.s: src/compiler/absyn/main/AbsynSQL.ppg.o src/compiler/absyn/main/AbsynSQL.ppg.sml
	@$(GENASM) x86-linux src/compiler/absyn/main/AbsynSQL.ppg.sml precompiled/x86-linux/180.s
precompiled/x86-linux/181.s: src/compiler/util/main/SmlppgUtil.ppg.o src/compiler/util/main/SmlppgUtil.ppg.sml
	@$(GENASM) x86-linux src/compiler/util/main/SmlppgUtil.ppg.sml precompiled/x86-linux/181.s
precompiled/x86-linux/182.s: src/compiler-utils/env/main/SSet.o src/compiler-utils/env/main/SSet.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/SSet.sml precompiled/x86-linux/182.s
precompiled/x86-linux/183.s: src/compiler-utils/env/main/SOrd.o src/compiler-utils/env/main/SOrd.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/SOrd.sml precompiled/x86-linux/183.s
precompiled/x86-linux/184.s: src/compiler/util/main/TermFormat.o src/compiler/util/main/TermFormat.sml
	@$(GENASM) x86-linux src/compiler/util/main/TermFormat.sml precompiled/x86-linux/184.s
precompiled/x86-linux/185.s: src/compiler/util/main/BigInt_IntInf.o src/compiler/util/main/BigInt_IntInf.sml
	@$(GENASM) x86-linux src/compiler/util/main/BigInt_IntInf.sml precompiled/x86-linux/185.s
precompiled/x86-linux/186.s: src/compiler/util/main/ListSorter.o src/compiler/util/main/ListSorter.sml
	@$(GENASM) x86-linux src/compiler/util/main/ListSorter.sml precompiled/x86-linux/186.s
precompiled/x86-linux/187.s: src/compiler-utils/env/main/LabelEnv.o src/compiler-utils/env/main/LabelEnv.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/LabelEnv.sml precompiled/x86-linux/187.s
precompiled/x86-linux/188.s: src/compiler-utils/env/main/LabelOrd.o src/compiler-utils/env/main/LabelOrd.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/LabelOrd.sml precompiled/x86-linux/188.s
precompiled/x86-linux/189.s: src/smlnj-lib/Util/binary-map-fn.o src/smlnj-lib/Util/binary-map-fn.sml
	@$(GENASM) x86-linux src/smlnj-lib/Util/binary-map-fn.sml precompiled/x86-linux/189.s
precompiled/x86-linux/190.s: src/compiler/name/main/LocalID.o src/compiler/name/main/LocalID.sml
	@$(GENASM) x86-linux src/compiler/name/main/LocalID.sml precompiled/x86-linux/190.s
precompiled/x86-linux/191.s: src/compiler-utils/env/main/ISet.o src/compiler-utils/env/main/ISet.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/ISet.sml precompiled/x86-linux/191.s
precompiled/x86-linux/192.s: src/compiler-utils/env/main/IOrd.o src/compiler-utils/env/main/IOrd.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/IOrd.sml precompiled/x86-linux/192.s
precompiled/x86-linux/193.s: src/compiler/toolchain/main/BinUtils.o src/compiler/toolchain/main/BinUtils.sml
	@$(GENASM) x86-linux src/compiler/toolchain/main/BinUtils.sml precompiled/x86-linux/193.s
precompiled/x86-linux/194.s: src/compiler/toolchain/main/TempFile.o src/compiler/toolchain/main/TempFile.sml
	@$(GENASM) x86-linux src/compiler/toolchain/main/TempFile.sml precompiled/x86-linux/194.s
precompiled/x86-linux/195.s: src/compiler/toolchain/main/CoreUtils.o src/compiler/toolchain/main/CoreUtils.sml
	@$(GENASM) x86-linux src/compiler/toolchain/main/CoreUtils.sml precompiled/x86-linux/195.s
precompiled/x86-linux/196.s: src/compiler/usererror/main/UserError.ppg.o src/compiler/usererror/main/UserError.ppg.sml
	@$(GENASM) x86-linux src/compiler/usererror/main/UserError.ppg.sml precompiled/x86-linux/196.s
precompiled/x86-linux/197.s: src/compiler/util/main/Counter.o src/compiler/util/main/Counter.sml
	@$(GENASM) x86-linux src/compiler/util/main/Counter.sml precompiled/x86-linux/197.s
precompiled/x86-linux/198.s: src/compiler-utils/env/main/IEnv.o src/compiler-utils/env/main/IEnv.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/IEnv.sml precompiled/x86-linux/198.s
precompiled/x86-linux/199.s: src/smlnj-lib/Util/binary-set-fn.o src/smlnj-lib/Util/binary-set-fn.sml
	@$(GENASM) x86-linux src/smlnj-lib/Util/binary-set-fn.sml precompiled/x86-linux/199.s
precompiled/x86-linux/200.s: src/compiler/control/main/Control.ppg.o src/compiler/control/main/Control.ppg.sml
	@$(GENASM) x86-linux src/compiler/control/main/Control.ppg.sml precompiled/x86-linux/200.s
precompiled/x86-linux/201.s: src/compiler/control/main/Loc.ppg.o src/compiler/control/main/Loc.ppg.sml
	@$(GENASM) x86-linux src/compiler/control/main/Loc.ppg.sml precompiled/x86-linux/201.s
precompiled/x86-linux/202.s: src/smlformat/formatlib/main/SMLFormat.o src/smlformat/formatlib/main/SMLFormat.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/SMLFormat.sml precompiled/x86-linux/202.s
precompiled/x86-linux/203.s: src/smlformat/formatlib/main/BasicFormatters.o src/smlformat/formatlib/main/BasicFormatters.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/BasicFormatters.sml precompiled/x86-linux/203.s
precompiled/x86-linux/204.s: src/smlformat/formatlib/main/PreProcessor.o src/smlformat/formatlib/main/PreProcessor.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/PreProcessor.sml precompiled/x86-linux/204.s
precompiled/x86-linux/205.s: src/smlformat/formatlib/main/Truncator.o src/smlformat/formatlib/main/Truncator.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/Truncator.sml precompiled/x86-linux/205.s
precompiled/x86-linux/206.s: src/smlformat/formatlib/main/PrettyPrinter.o src/smlformat/formatlib/main/PrettyPrinter.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/PrettyPrinter.sml precompiled/x86-linux/206.s
precompiled/x86-linux/207.s: src/smlformat/formatlib/main/PreProcessedExpression.o src/smlformat/formatlib/main/PreProcessedExpression.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/PreProcessedExpression.sml precompiled/x86-linux/207.s
precompiled/x86-linux/208.s: src/smlformat/formatlib/main/AssocResolver.o src/smlformat/formatlib/main/AssocResolver.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/AssocResolver.sml precompiled/x86-linux/208.s
precompiled/x86-linux/209.s: src/smlformat/formatlib/main/PrinterParameter.o src/smlformat/formatlib/main/PrinterParameter.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/PrinterParameter.sml precompiled/x86-linux/209.s
precompiled/x86-linux/210.s: src/smlformat/formatlib/main/FormatExpression.o src/smlformat/formatlib/main/FormatExpression.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/FormatExpression.sml precompiled/x86-linux/210.s
precompiled/x86-linux/211.s: src/smlformat/formatlib/main/FormatExpressionTypes.o src/smlformat/formatlib/main/FormatExpressionTypes.sml
	@$(GENASM) x86-linux src/smlformat/formatlib/main/FormatExpressionTypes.sml precompiled/x86-linux/211.s
precompiled/x86-linux/212.s: src/smlnj-lib/Util/parser-comb.o src/smlnj-lib/Util/parser-comb.sml
	@$(GENASM) x86-linux src/smlnj-lib/Util/parser-comb.sml precompiled/x86-linux/212.s
precompiled/x86-linux/213.s: src/config/main/Config.o src/config/main/Config.sml
	@$(GENASM) x86-linux src/config/main/Config.sml precompiled/x86-linux/213.s
precompiled/x86-linux/214.s: src/compiler/toolchain/main/Filename.o src/compiler/toolchain/main/Filename.sml
	@$(GENASM) x86-linux src/compiler/toolchain/main/Filename.sml precompiled/x86-linux/214.s
precompiled/x86-linux/215.s: src/compiler-utils/env/main/SEnv.o src/compiler-utils/env/main/SEnv.sml
	@$(GENASM) x86-linux src/compiler-utils/env/main/SEnv.sml precompiled/x86-linux/215.s
precompiled/x86-linux/216.s: src/smlnj-lib/Util/lib-base.o src/smlnj-lib/Util/lib-base.sml
	@$(GENASM) x86-linux src/smlnj-lib/Util/lib-base.sml precompiled/x86-linux/216.s
precompiled/x86-linux/217.s: src/config/main/Version.o src/config/main/Version.sml
	@$(GENASM) x86-linux src/config/main/Version.sml precompiled/x86-linux/217.s
precompiled/x86-linux/218.s: src/basis/main/binary-op.o src/basis/main/binary-op.sml
	@$(GENASM) x86-linux src/basis/main/binary-op.sml precompiled/x86-linux/218.s
precompiled/x86-linux/219.s: src/basis/main/Date.o src/basis/main/Date.sml
	@$(GENASM) x86-linux src/basis/main/Date.sml precompiled/x86-linux/219.s
precompiled/x86-linux/220.s: src/basis/main/Timer.o src/basis/main/Timer.sml
	@$(GENASM) x86-linux src/basis/main/Timer.sml precompiled/x86-linux/220.s
precompiled/x86-linux/221.s: src/smlnj/Basis/internal-timer.o src/smlnj/Basis/internal-timer.sml
	@$(GENASM) x86-linux src/smlnj/Basis/internal-timer.sml precompiled/x86-linux/221.s
precompiled/x86-linux/222.s: src/basis/main/ArraySlice.o src/basis/main/ArraySlice.sml
	@$(GENASM) x86-linux src/basis/main/ArraySlice.sml precompiled/x86-linux/222.s
precompiled/x86-linux/223.s: src/basis/main/CommandLine.o src/basis/main/CommandLine.sml
	@$(GENASM) x86-linux src/basis/main/CommandLine.sml precompiled/x86-linux/223.s
precompiled/x86-linux/224.s: src/basis/main/Text.o src/basis/main/Text.sml
	@$(GENASM) x86-linux src/basis/main/Text.sml precompiled/x86-linux/224.s
precompiled/x86-linux/225.s: src/basis/main/BinIO.o src/basis/main/BinIO.sml
	@$(GENASM) x86-linux src/basis/main/BinIO.sml precompiled/x86-linux/225.s
precompiled/x86-linux/226.s: src/smlnj/Basis/IO/bin-io.o src/smlnj/Basis/IO/bin-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/IO/bin-io.sml precompiled/x86-linux/226.s
precompiled/x86-linux/227.s: src/smlnj/Basis/Unix/posix-bin-prim-io.o src/smlnj/Basis/Unix/posix-bin-prim-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/Unix/posix-bin-prim-io.sml precompiled/x86-linux/227.s
precompiled/x86-linux/228.s: src/basis/main/TextIO.o src/basis/main/TextIO.sml
	@$(GENASM) x86-linux src/basis/main/TextIO.sml precompiled/x86-linux/228.s
precompiled/x86-linux/229.s: src/smlnj/Basis/IO/text-io.o src/smlnj/Basis/IO/text-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/IO/text-io.sml precompiled/x86-linux/229.s
precompiled/x86-linux/230.s: src/smlnj/Basis/Unix/posix-text-prim-io.o src/smlnj/Basis/Unix/posix-text-prim-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/Unix/posix-text-prim-io.sml precompiled/x86-linux/230.s
precompiled/x86-linux/231.s: src/smlnj/Basis/Posix/posix-io.o src/smlnj/Basis/Posix/posix-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/Posix/posix-io.sml precompiled/x86-linux/231.s
precompiled/x86-linux/232.s: src/smlnj/Basis/IO/prim-io-bin.o src/smlnj/Basis/IO/prim-io-bin.sml
	@$(GENASM) x86-linux src/smlnj/Basis/IO/prim-io-bin.sml precompiled/x86-linux/232.s
precompiled/x86-linux/233.s: src/basis/main/Word8.o src/basis/main/Word8.sml
	@$(GENASM) x86-linux src/basis/main/Word8.sml precompiled/x86-linux/233.s
precompiled/x86-linux/234.s: src/smlnj/Basis/IO/clean-io.o src/smlnj/Basis/IO/clean-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/IO/clean-io.sml precompiled/x86-linux/234.s
precompiled/x86-linux/235.s: src/smlnj/Basis/IO/prim-io-text.o src/smlnj/Basis/IO/prim-io-text.sml
	@$(GENASM) x86-linux src/smlnj/Basis/IO/prim-io-text.sml precompiled/x86-linux/235.s
precompiled/x86-linux/236.s: src/basis/main/CharArray.o src/basis/main/CharArray.sml
	@$(GENASM) x86-linux src/basis/main/CharArray.sml precompiled/x86-linux/236.s
precompiled/x86-linux/237.s: src/basis/main/OS.o src/basis/main/OS.sml
	@$(GENASM) x86-linux src/basis/main/OS.sml precompiled/x86-linux/237.s
precompiled/x86-linux/238.s: src/smlnj/Basis/Unix/os-io.o src/smlnj/Basis/Unix/os-io.sml
	@$(GENASM) x86-linux src/smlnj/Basis/Unix/os-io.sml precompiled/x86-linux/238.s
precompiled/x86-linux/239.s: src/basis/main/ListPair.o src/basis/main/ListPair.sml
	@$(GENASM) x86-linux src/basis/main/ListPair.sml precompiled/x86-linux/239.s
precompiled/x86-linux/240.s: src/smlnj/Basis/Unix/os-filesys.o src/smlnj/Basis/Unix/os-filesys.sml
	@$(GENASM) x86-linux src/smlnj/Basis/Unix/os-filesys.sml precompiled/x86-linux/240.s
precompiled/x86-linux/241.s: src/smlnj/Basis/Unix/os-path.o src/smlnj/Basis/Unix/os-path.sml
	@$(GENASM) x86-linux src/smlnj/Basis/Unix/os-path.sml precompiled/x86-linux/241.s
precompiled/x86-linux/242.s: src/smlnj/Basis/OS/os-path-fn.o src/smlnj/Basis/OS/os-path-fn.sml
	@$(GENASM) x86-linux src/smlnj/Basis/OS/os-path-fn.sml precompiled/x86-linux/242.s
precompiled/x86-linux/243.s: src/basis/main/SMLSharpOSProcess.o src/basis/main/SMLSharpOSProcess.sml
	@$(GENASM) x86-linux src/basis/main/SMLSharpOSProcess.sml precompiled/x86-linux/243.s
precompiled/x86-linux/244.s: src/smlnj/Basis/NJ/cleanup.o src/smlnj/Basis/NJ/cleanup.sml
	@$(GENASM) x86-linux src/smlnj/Basis/NJ/cleanup.sml precompiled/x86-linux/244.s
precompiled/x86-linux/245.s: src/basis/main/SMLSharpOSFileSys.o src/basis/main/SMLSharpOSFileSys.sml
	@$(GENASM) x86-linux src/basis/main/SMLSharpOSFileSys.sml precompiled/x86-linux/245.s
precompiled/x86-linux/246.s: src/basis/main/Byte.o src/basis/main/Byte.sml
	@$(GENASM) x86-linux src/basis/main/Byte.sml precompiled/x86-linux/246.s
precompiled/x86-linux/247.s: src/basis/main/Word8Array.o src/basis/main/Word8Array.sml
	@$(GENASM) x86-linux src/basis/main/Word8Array.sml precompiled/x86-linux/247.s
precompiled/x86-linux/248.s: src/basis/main/Word.o src/basis/main/Word.sml
	@$(GENASM) x86-linux src/basis/main/Word.sml precompiled/x86-linux/248.s
precompiled/x86-linux/249.s: src/basis/main/Time.o src/basis/main/Time.sml
	@$(GENASM) x86-linux src/basis/main/Time.sml precompiled/x86-linux/249.s
precompiled/x86-linux/250.s: src/basis/main/Real32.o src/basis/main/Real32.sml
	@$(GENASM) x86-linux src/basis/main/Real32.sml precompiled/x86-linux/250.s
precompiled/x86-linux/251.s: src/basis/main/Real.o src/basis/main/Real.sml
	@$(GENASM) x86-linux src/basis/main/Real.sml precompiled/x86-linux/251.s
precompiled/x86-linux/252.s: src/basis/main/Substring.o src/basis/main/Substring.sml
	@$(GENASM) x86-linux src/basis/main/Substring.sml precompiled/x86-linux/252.s
precompiled/x86-linux/253.s: src/basis/main/RealClass.o src/basis/main/RealClass.sml
	@$(GENASM) x86-linux src/basis/main/RealClass.sml precompiled/x86-linux/253.s
precompiled/x86-linux/254.s: src/basis/main/IEEEReal.o src/basis/main/IEEEReal.sml
	@$(GENASM) x86-linux src/basis/main/IEEEReal.sml precompiled/x86-linux/254.s
precompiled/x86-linux/255.s: src/basis/main/Int.o src/basis/main/Int.sml
	@$(GENASM) x86-linux src/basis/main/Int.sml precompiled/x86-linux/255.s
precompiled/x86-linux/256.s: src/basis/main/IntInf.o src/basis/main/IntInf.sml
	@$(GENASM) x86-linux src/basis/main/IntInf.sml precompiled/x86-linux/256.s
precompiled/x86-linux/257.s: src/basis/main/String.o src/basis/main/String.sml
	@$(GENASM) x86-linux src/basis/main/String.sml precompiled/x86-linux/257.s
precompiled/x86-linux/258.s: src/basis/main/CharVectorSlice.o src/basis/main/CharVectorSlice.sml
	@$(GENASM) x86-linux src/basis/main/CharVectorSlice.sml precompiled/x86-linux/258.s
precompiled/x86-linux/259.s: src/basis/main/CharVector.o src/basis/main/CharVector.sml
	@$(GENASM) x86-linux src/basis/main/CharVector.sml precompiled/x86-linux/259.s
precompiled/x86-linux/260.s: src/basis/main/StringBase.o src/basis/main/StringBase.sml
	@$(GENASM) x86-linux src/basis/main/StringBase.sml precompiled/x86-linux/260.s
precompiled/x86-linux/261.s: src/basis/main/SMLSharpRuntime.o src/basis/main/SMLSharpRuntime.sml
	@$(GENASM) x86-linux src/basis/main/SMLSharpRuntime.sml precompiled/x86-linux/261.s
precompiled/x86-linux/262.s: src/basis/main/IO.o src/basis/main/IO.sml
	@$(GENASM) x86-linux src/basis/main/IO.sml precompiled/x86-linux/262.s
precompiled/x86-linux/263.s: src/basis/main/Bool.o src/basis/main/Bool.sml
	@$(GENASM) x86-linux src/basis/main/Bool.sml precompiled/x86-linux/263.s
precompiled/x86-linux/264.s: src/basis/main/Word8VectorSlice.o src/basis/main/Word8VectorSlice.sml
	@$(GENASM) x86-linux src/basis/main/Word8VectorSlice.sml precompiled/x86-linux/264.s
precompiled/x86-linux/265.s: src/basis/main/Word8Vector.o src/basis/main/Word8Vector.sml
	@$(GENASM) x86-linux src/basis/main/Word8Vector.sml precompiled/x86-linux/265.s
precompiled/x86-linux/266.s: src/basis/main/Char.o src/basis/main/Char.sml
	@$(GENASM) x86-linux src/basis/main/Char.sml precompiled/x86-linux/266.s
precompiled/x86-linux/267.s: src/basis/main/SMLSharpScanChar.o src/basis/main/SMLSharpScanChar.sml
	@$(GENASM) x86-linux src/basis/main/SMLSharpScanChar.sml precompiled/x86-linux/267.s
precompiled/x86-linux/268.s: src/basis/main/StringCvt.o src/basis/main/StringCvt.sml
	@$(GENASM) x86-linux src/basis/main/StringCvt.sml precompiled/x86-linux/268.s
precompiled/x86-linux/269.s: src/basis/main/VectorSlice.o src/basis/main/VectorSlice.sml
	@$(GENASM) x86-linux src/basis/main/VectorSlice.sml precompiled/x86-linux/269.s
precompiled/x86-linux/270.s: src/basis/main/Vector.o src/basis/main/Vector.sml
	@$(GENASM) x86-linux src/basis/main/Vector.sml precompiled/x86-linux/270.s
precompiled/x86-linux/271.s: src/basis/main/Array.o src/basis/main/Array.sml
	@$(GENASM) x86-linux src/basis/main/Array.sml precompiled/x86-linux/271.s
precompiled/x86-linux/272.s: src/basis/main/List.o src/basis/main/List.sml
	@$(GENASM) x86-linux src/basis/main/List.sml precompiled/x86-linux/272.s
precompiled/x86-linux/273.s: src/basis/main/Option.o src/basis/main/Option.sml
	@$(GENASM) x86-linux src/basis/main/Option.sml precompiled/x86-linux/273.s
precompiled/x86-linux/274.s: src/basis/main/General.o src/basis/main/General.sml
	@$(GENASM) x86-linux src/basis/main/General.sml precompiled/x86-linux/274.s
precompiled/x86-linux.tar.xz:  precompiled/x86-linux/000.s precompiled/x86-linux/001.s precompiled/x86-linux/002.s precompiled/x86-linux/003.s precompiled/x86-linux/004.s precompiled/x86-linux/005.s precompiled/x86-linux/006.s precompiled/x86-linux/007.s precompiled/x86-linux/008.s precompiled/x86-linux/009.s precompiled/x86-linux/010.s precompiled/x86-linux/011.s precompiled/x86-linux/012.s precompiled/x86-linux/013.s precompiled/x86-linux/014.s precompiled/x86-linux/015.s precompiled/x86-linux/016.s precompiled/x86-linux/017.s precompiled/x86-linux/018.s precompiled/x86-linux/019.s precompiled/x86-linux/020.s precompiled/x86-linux/021.s precompiled/x86-linux/022.s precompiled/x86-linux/023.s precompiled/x86-linux/024.s precompiled/x86-linux/025.s precompiled/x86-linux/026.s precompiled/x86-linux/027.s precompiled/x86-linux/028.s precompiled/x86-linux/029.s precompiled/x86-linux/030.s precompiled/x86-linux/031.s precompiled/x86-linux/032.s precompiled/x86-linux/033.s precompiled/x86-linux/034.s precompiled/x86-linux/035.s precompiled/x86-linux/036.s precompiled/x86-linux/037.s precompiled/x86-linux/038.s precompiled/x86-linux/039.s precompiled/x86-linux/040.s precompiled/x86-linux/041.s precompiled/x86-linux/042.s precompiled/x86-linux/043.s precompiled/x86-linux/044.s precompiled/x86-linux/045.s precompiled/x86-linux/046.s precompiled/x86-linux/047.s precompiled/x86-linux/048.s precompiled/x86-linux/049.s precompiled/x86-linux/050.s precompiled/x86-linux/051.s precompiled/x86-linux/052.s precompiled/x86-linux/053.s precompiled/x86-linux/054.s precompiled/x86-linux/055.s precompiled/x86-linux/056.s precompiled/x86-linux/057.s precompiled/x86-linux/058.s precompiled/x86-linux/059.s precompiled/x86-linux/060.s precompiled/x86-linux/061.s precompiled/x86-linux/062.s precompiled/x86-linux/063.s precompiled/x86-linux/064.s precompiled/x86-linux/065.s precompiled/x86-linux/066.s precompiled/x86-linux/067.s precompiled/x86-linux/068.s precompiled/x86-linux/069.s precompiled/x86-linux/070.s precompiled/x86-linux/071.s precompiled/x86-linux/072.s precompiled/x86-linux/073.s precompiled/x86-linux/074.s precompiled/x86-linux/075.s precompiled/x86-linux/076.s precompiled/x86-linux/077.s precompiled/x86-linux/078.s precompiled/x86-linux/079.s precompiled/x86-linux/080.s precompiled/x86-linux/081.s precompiled/x86-linux/082.s precompiled/x86-linux/083.s precompiled/x86-linux/084.s precompiled/x86-linux/085.s precompiled/x86-linux/086.s precompiled/x86-linux/087.s precompiled/x86-linux/088.s precompiled/x86-linux/089.s precompiled/x86-linux/090.s precompiled/x86-linux/091.s precompiled/x86-linux/092.s precompiled/x86-linux/093.s precompiled/x86-linux/094.s precompiled/x86-linux/095.s precompiled/x86-linux/096.s precompiled/x86-linux/097.s precompiled/x86-linux/098.s precompiled/x86-linux/099.s precompiled/x86-linux/100.s precompiled/x86-linux/101.s precompiled/x86-linux/102.s precompiled/x86-linux/103.s precompiled/x86-linux/104.s precompiled/x86-linux/105.s precompiled/x86-linux/106.s precompiled/x86-linux/107.s precompiled/x86-linux/108.s precompiled/x86-linux/109.s precompiled/x86-linux/110.s precompiled/x86-linux/111.s precompiled/x86-linux/112.s precompiled/x86-linux/113.s precompiled/x86-linux/114.s precompiled/x86-linux/115.s precompiled/x86-linux/116.s precompiled/x86-linux/117.s precompiled/x86-linux/118.s precompiled/x86-linux/119.s precompiled/x86-linux/120.s precompiled/x86-linux/121.s precompiled/x86-linux/122.s precompiled/x86-linux/123.s precompiled/x86-linux/124.s precompiled/x86-linux/125.s precompiled/x86-linux/126.s precompiled/x86-linux/127.s precompiled/x86-linux/128.s precompiled/x86-linux/129.s precompiled/x86-linux/130.s precompiled/x86-linux/131.s precompiled/x86-linux/132.s precompiled/x86-linux/133.s precompiled/x86-linux/134.s precompiled/x86-linux/135.s precompiled/x86-linux/136.s precompiled/x86-linux/137.s precompiled/x86-linux/138.s precompiled/x86-linux/139.s precompiled/x86-linux/140.s precompiled/x86-linux/141.s precompiled/x86-linux/142.s precompiled/x86-linux/143.s precompiled/x86-linux/144.s precompiled/x86-linux/145.s precompiled/x86-linux/146.s precompiled/x86-linux/147.s precompiled/x86-linux/148.s precompiled/x86-linux/149.s precompiled/x86-linux/150.s precompiled/x86-linux/151.s precompiled/x86-linux/152.s precompiled/x86-linux/153.s precompiled/x86-linux/154.s precompiled/x86-linux/155.s precompiled/x86-linux/156.s precompiled/x86-linux/157.s precompiled/x86-linux/158.s precompiled/x86-linux/159.s precompiled/x86-linux/160.s precompiled/x86-linux/161.s precompiled/x86-linux/162.s precompiled/x86-linux/163.s precompiled/x86-linux/164.s precompiled/x86-linux/165.s precompiled/x86-linux/166.s precompiled/x86-linux/167.s precompiled/x86-linux/168.s precompiled/x86-linux/169.s precompiled/x86-linux/170.s precompiled/x86-linux/171.s precompiled/x86-linux/172.s precompiled/x86-linux/173.s precompiled/x86-linux/174.s precompiled/x86-linux/175.s precompiled/x86-linux/176.s precompiled/x86-linux/177.s precompiled/x86-linux/178.s precompiled/x86-linux/179.s precompiled/x86-linux/180.s precompiled/x86-linux/181.s precompiled/x86-linux/182.s precompiled/x86-linux/183.s precompiled/x86-linux/184.s precompiled/x86-linux/185.s precompiled/x86-linux/186.s precompiled/x86-linux/187.s precompiled/x86-linux/188.s precompiled/x86-linux/189.s precompiled/x86-linux/190.s precompiled/x86-linux/191.s precompiled/x86-linux/192.s precompiled/x86-linux/193.s precompiled/x86-linux/194.s precompiled/x86-linux/195.s precompiled/x86-linux/196.s precompiled/x86-linux/197.s precompiled/x86-linux/198.s precompiled/x86-linux/199.s precompiled/x86-linux/200.s precompiled/x86-linux/201.s precompiled/x86-linux/202.s precompiled/x86-linux/203.s precompiled/x86-linux/204.s precompiled/x86-linux/205.s precompiled/x86-linux/206.s precompiled/x86-linux/207.s precompiled/x86-linux/208.s precompiled/x86-linux/209.s precompiled/x86-linux/210.s precompiled/x86-linux/211.s precompiled/x86-linux/212.s precompiled/x86-linux/213.s precompiled/x86-linux/214.s precompiled/x86-linux/215.s precompiled/x86-linux/216.s precompiled/x86-linux/217.s precompiled/x86-linux/218.s precompiled/x86-linux/219.s precompiled/x86-linux/220.s precompiled/x86-linux/221.s precompiled/x86-linux/222.s precompiled/x86-linux/223.s precompiled/x86-linux/224.s precompiled/x86-linux/225.s precompiled/x86-linux/226.s precompiled/x86-linux/227.s precompiled/x86-linux/228.s precompiled/x86-linux/229.s precompiled/x86-linux/230.s precompiled/x86-linux/231.s precompiled/x86-linux/232.s precompiled/x86-linux/233.s precompiled/x86-linux/234.s precompiled/x86-linux/235.s precompiled/x86-linux/236.s precompiled/x86-linux/237.s precompiled/x86-linux/238.s precompiled/x86-linux/239.s precompiled/x86-linux/240.s precompiled/x86-linux/241.s precompiled/x86-linux/242.s precompiled/x86-linux/243.s precompiled/x86-linux/244.s precompiled/x86-linux/245.s precompiled/x86-linux/246.s precompiled/x86-linux/247.s precompiled/x86-linux/248.s precompiled/x86-linux/249.s precompiled/x86-linux/250.s precompiled/x86-linux/251.s precompiled/x86-linux/252.s precompiled/x86-linux/253.s precompiled/x86-linux/254.s precompiled/x86-linux/255.s precompiled/x86-linux/256.s precompiled/x86-linux/257.s precompiled/x86-linux/258.s precompiled/x86-linux/259.s precompiled/x86-linux/260.s precompiled/x86-linux/261.s precompiled/x86-linux/262.s precompiled/x86-linux/263.s precompiled/x86-linux/264.s precompiled/x86-linux/265.s precompiled/x86-linux/266.s precompiled/x86-linux/267.s precompiled/x86-linux/268.s precompiled/x86-linux/269.s precompiled/x86-linux/270.s precompiled/x86-linux/271.s precompiled/x86-linux/272.s precompiled/x86-linux/273.s precompiled/x86-linux/274.s
	(cd precompiled && tar cf - x86-linux/000.s x86-linux/001.s x86-linux/002.s x86-linux/003.s x86-linux/004.s x86-linux/005.s x86-linux/006.s x86-linux/007.s x86-linux/008.s x86-linux/009.s x86-linux/010.s x86-linux/011.s x86-linux/012.s x86-linux/013.s x86-linux/014.s x86-linux/015.s x86-linux/016.s x86-linux/017.s x86-linux/018.s x86-linux/019.s x86-linux/020.s x86-linux/021.s x86-linux/022.s x86-linux/023.s x86-linux/024.s x86-linux/025.s x86-linux/026.s x86-linux/027.s x86-linux/028.s x86-linux/029.s x86-linux/030.s x86-linux/031.s x86-linux/032.s x86-linux/033.s x86-linux/034.s x86-linux/035.s x86-linux/036.s x86-linux/037.s x86-linux/038.s x86-linux/039.s x86-linux/040.s x86-linux/041.s x86-linux/042.s x86-linux/043.s x86-linux/044.s x86-linux/045.s x86-linux/046.s x86-linux/047.s x86-linux/048.s x86-linux/049.s x86-linux/050.s x86-linux/051.s x86-linux/052.s x86-linux/053.s x86-linux/054.s x86-linux/055.s x86-linux/056.s x86-linux/057.s x86-linux/058.s x86-linux/059.s x86-linux/060.s x86-linux/061.s x86-linux/062.s x86-linux/063.s x86-linux/064.s x86-linux/065.s x86-linux/066.s x86-linux/067.s x86-linux/068.s x86-linux/069.s x86-linux/070.s x86-linux/071.s x86-linux/072.s x86-linux/073.s x86-linux/074.s x86-linux/075.s x86-linux/076.s x86-linux/077.s x86-linux/078.s x86-linux/079.s x86-linux/080.s x86-linux/081.s x86-linux/082.s x86-linux/083.s x86-linux/084.s x86-linux/085.s x86-linux/086.s x86-linux/087.s x86-linux/088.s x86-linux/089.s x86-linux/090.s x86-linux/091.s x86-linux/092.s x86-linux/093.s x86-linux/094.s x86-linux/095.s x86-linux/096.s x86-linux/097.s x86-linux/098.s x86-linux/099.s x86-linux/100.s x86-linux/101.s x86-linux/102.s x86-linux/103.s x86-linux/104.s x86-linux/105.s x86-linux/106.s x86-linux/107.s x86-linux/108.s x86-linux/109.s x86-linux/110.s x86-linux/111.s x86-linux/112.s x86-linux/113.s x86-linux/114.s x86-linux/115.s x86-linux/116.s x86-linux/117.s x86-linux/118.s x86-linux/119.s x86-linux/120.s x86-linux/121.s x86-linux/122.s x86-linux/123.s x86-linux/124.s x86-linux/125.s x86-linux/126.s x86-linux/127.s x86-linux/128.s x86-linux/129.s x86-linux/130.s x86-linux/131.s x86-linux/132.s x86-linux/133.s x86-linux/134.s x86-linux/135.s x86-linux/136.s x86-linux/137.s x86-linux/138.s x86-linux/139.s x86-linux/140.s x86-linux/141.s x86-linux/142.s x86-linux/143.s x86-linux/144.s x86-linux/145.s x86-linux/146.s x86-linux/147.s x86-linux/148.s x86-linux/149.s x86-linux/150.s x86-linux/151.s x86-linux/152.s x86-linux/153.s x86-linux/154.s x86-linux/155.s x86-linux/156.s x86-linux/157.s x86-linux/158.s x86-linux/159.s x86-linux/160.s x86-linux/161.s x86-linux/162.s x86-linux/163.s x86-linux/164.s x86-linux/165.s x86-linux/166.s x86-linux/167.s x86-linux/168.s x86-linux/169.s x86-linux/170.s x86-linux/171.s x86-linux/172.s x86-linux/173.s x86-linux/174.s x86-linux/175.s x86-linux/176.s x86-linux/177.s x86-linux/178.s x86-linux/179.s x86-linux/180.s x86-linux/181.s x86-linux/182.s x86-linux/183.s x86-linux/184.s x86-linux/185.s x86-linux/186.s x86-linux/187.s x86-linux/188.s x86-linux/189.s x86-linux/190.s x86-linux/191.s x86-linux/192.s x86-linux/193.s x86-linux/194.s x86-linux/195.s x86-linux/196.s x86-linux/197.s x86-linux/198.s x86-linux/199.s x86-linux/200.s x86-linux/201.s x86-linux/202.s x86-linux/203.s x86-linux/204.s x86-linux/205.s x86-linux/206.s x86-linux/207.s x86-linux/208.s x86-linux/209.s x86-linux/210.s x86-linux/211.s x86-linux/212.s x86-linux/213.s x86-linux/214.s x86-linux/215.s x86-linux/216.s x86-linux/217.s x86-linux/218.s x86-linux/219.s x86-linux/220.s x86-linux/221.s x86-linux/222.s x86-linux/223.s x86-linux/224.s x86-linux/225.s x86-linux/226.s x86-linux/227.s x86-linux/228.s x86-linux/229.s x86-linux/230.s x86-linux/231.s x86-linux/232.s x86-linux/233.s x86-linux/234.s x86-linux/235.s x86-linux/236.s x86-linux/237.s x86-linux/238.s x86-linux/239.s x86-linux/240.s x86-linux/241.s x86-linux/242.s x86-linux/243.s x86-linux/244.s x86-linux/245.s x86-linux/246.s x86-linux/247.s x86-linux/248.s x86-linux/249.s x86-linux/250.s x86-linux/251.s x86-linux/252.s x86-linux/253.s x86-linux/254.s x86-linux/255.s x86-linux/256.s x86-linux/257.s x86-linux/258.s x86-linux/259.s x86-linux/260.s x86-linux/261.s x86-linux/262.s x86-linux/263.s x86-linux/264.s x86-linux/265.s x86-linux/266.s x86-linux/267.s x86-linux/268.s x86-linux/269.s x86-linux/270.s x86-linux/271.s x86-linux/272.s x86-linux/273.s x86-linux/274.s | xz -c6) > $@
precompiled/x86-mingw/000.s: src/compiler/minismlsharp.smi $(MINISMLSHARP_OBJECTS)
	@$(GENASM) x86-mingw src/compiler/minismlsharp.smi precompiled/x86-mingw/000.s
precompiled/x86-mingw/001.s: src/compiler/minismlsharp.o src/compiler/minismlsharp.sml
	@$(GENASM) x86-mingw src/compiler/minismlsharp.sml precompiled/x86-mingw/001.s
precompiled/x86-mingw/002.s: src/compiler/main/main/SimpleMain.o src/compiler/main/main/SimpleMain.sml
	@$(GENASM) x86-mingw src/compiler/main/main/SimpleMain.sml precompiled/x86-mingw/002.s
precompiled/x86-mingw/003.s: src/compiler/main/main/ExecutablePath.o src/compiler/main/main/ExecutablePath.sml
	@$(GENASM) x86-mingw src/compiler/main/main/ExecutablePath.sml precompiled/x86-mingw/003.s
precompiled/x86-mingw/004.s: src/compiler/main/main/RunLoop.o src/compiler/main/main/RunLoop.sml
	@$(GENASM) x86-mingw src/compiler/main/main/RunLoop.sml precompiled/x86-mingw/004.s
precompiled/x86-mingw/005.s: src/sql/main/SQLPrim.o src/sql/main/SQLPrim.sml
	@$(GENASM) x86-mingw src/sql/main/SQLPrim.sml precompiled/x86-mingw/005.s
precompiled/x86-mingw/006.s: src/sql/main/Backend.o src/sql/main/Backend.sml
	@$(GENASM) x86-mingw src/sql/main/Backend.sml precompiled/x86-mingw/006.s
precompiled/x86-mingw/007.s: src/sql/main/PGSQLBackend.o src/sql/main/PGSQLBackend.sml
	@$(GENASM) x86-mingw src/sql/main/PGSQLBackend.sml precompiled/x86-mingw/007.s
precompiled/x86-mingw/008.s: src/sql/main/PGSQL.o src/sql/main/PGSQL.sml
	@$(GENASM) x86-mingw src/sql/main/PGSQL.sml precompiled/x86-mingw/008.s
precompiled/x86-mingw/009.s: src/ffi/main/Pointer.o src/ffi/main/Pointer.sml
	@$(GENASM) x86-mingw src/ffi/main/Pointer.sml precompiled/x86-mingw/009.s
precompiled/x86-mingw/010.s: src/ffi/main/DynamicLink.o src/ffi/main/DynamicLink.sml
	@$(GENASM) x86-mingw src/ffi/main/DynamicLink.sml precompiled/x86-mingw/010.s
precompiled/x86-mingw/011.s: src/compiler/main/main/SMLofNJ.o src/compiler/main/main/SMLofNJ.sml
	@$(GENASM) x86-mingw src/compiler/main/main/SMLofNJ.sml precompiled/x86-mingw/011.s
precompiled/x86-mingw/012.s: src/compiler/main/main/GetOpt.o src/compiler/main/main/GetOpt.sml
	@$(GENASM) x86-mingw src/compiler/main/main/GetOpt.sml precompiled/x86-mingw/012.s
precompiled/x86-mingw/013.s: src/compiler/toplevel2/main/Top.o src/compiler/toplevel2/main/Top.sml
	@$(GENASM) x86-mingw src/compiler/toplevel2/main/Top.sml precompiled/x86-mingw/013.s
precompiled/x86-mingw/014.s: src/compiler/toplevel2/main/NameEvalEnvUtils.o src/compiler/toplevel2/main/NameEvalEnvUtils.sml
	@$(GENASM) x86-mingw src/compiler/toplevel2/main/NameEvalEnvUtils.sml precompiled/x86-mingw/014.s
precompiled/x86-mingw/015.s: src/compiler/toplevel2/main/TopData.ppg.o src/compiler/toplevel2/main/TopData.ppg.sml
	@$(GENASM) x86-mingw src/compiler/toplevel2/main/TopData.ppg.sml precompiled/x86-mingw/015.s
precompiled/x86-mingw/016.s: src/compiler/rtl/main/X86AsmGen.o src/compiler/rtl/main/X86AsmGen.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86AsmGen.sml precompiled/x86-mingw/016.s
precompiled/x86-mingw/017.s: src/compiler/rtl/main/X86Frame.o src/compiler/rtl/main/X86Frame.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Frame.sml precompiled/x86-mingw/017.s
precompiled/x86-mingw/018.s: src/compiler/rtl/main/FrameLayout.o src/compiler/rtl/main/FrameLayout.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/FrameLayout.sml precompiled/x86-mingw/018.s
precompiled/x86-mingw/019.s: src/compiler/rtl/main/X86Coloring.o src/compiler/rtl/main/X86Coloring.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Coloring.sml precompiled/x86-mingw/019.s
precompiled/x86-mingw/020.s: src/compiler/rtl/main/X86Constraint.o src/compiler/rtl/main/X86Constraint.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Constraint.sml precompiled/x86-mingw/020.s
precompiled/x86-mingw/021.s: src/compiler/rtl/main/RTLColoring.o src/compiler/rtl/main/RTLColoring.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLColoring.sml precompiled/x86-mingw/021.s
precompiled/x86-mingw/022.s: src/compiler/rtl/main/Coloring.o src/compiler/rtl/main/Coloring.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/Coloring.sml precompiled/x86-mingw/022.s
precompiled/x86-mingw/023.s: src/compiler/rtl/main/RTLRename.o src/compiler/rtl/main/RTLRename.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLRename.sml precompiled/x86-mingw/023.s
precompiled/x86-mingw/024.s: src/compiler/rtl/main/X86Stabilize.o src/compiler/rtl/main/X86Stabilize.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Stabilize.sml precompiled/x86-mingw/024.s
precompiled/x86-mingw/025.s: src/compiler/rtl/main/RTLStabilize.o src/compiler/rtl/main/RTLStabilize.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLStabilize.sml precompiled/x86-mingw/025.s
precompiled/x86-mingw/026.s: src/compiler/rtl/main/X86Select.o src/compiler/rtl/main/X86Select.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Select.sml precompiled/x86-mingw/026.s
precompiled/x86-mingw/027.s: src/compiler/rtl/main/RTLDominate.o src/compiler/rtl/main/RTLDominate.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLDominate.sml precompiled/x86-mingw/027.s
precompiled/x86-mingw/028.s: src/compiler/rtl/main/X86Subst.o src/compiler/rtl/main/X86Subst.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Subst.sml precompiled/x86-mingw/028.s
precompiled/x86-mingw/029.s: src/compiler/rtl/main/X86Emit.o src/compiler/rtl/main/X86Emit.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Emit.sml precompiled/x86-mingw/029.s
precompiled/x86-mingw/030.s: src/compiler/rtl/main/X86Asm.ppg.o src/compiler/rtl/main/X86Asm.ppg.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/X86Asm.ppg.sml precompiled/x86-mingw/030.s
precompiled/x86-mingw/031.s: src/compiler/rtl/main/IEEERealConst.o src/compiler/rtl/main/IEEERealConst.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/IEEERealConst.sml precompiled/x86-mingw/031.s
precompiled/x86-mingw/032.s: src/compiler/rtl/main/RTLBackendContext.o src/compiler/rtl/main/RTLBackendContext.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLBackendContext.sml precompiled/x86-mingw/032.s
precompiled/x86-mingw/033.s: src/compiler/rtl/main/RTLTypeCheck.o src/compiler/rtl/main/RTLTypeCheck.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLTypeCheck.sml precompiled/x86-mingw/033.s
precompiled/x86-mingw/034.s: src/compiler/rtl/main/RTLTypeCheckError.ppg.o src/compiler/rtl/main/RTLTypeCheckError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLTypeCheckError.ppg.sml precompiled/x86-mingw/034.s
precompiled/x86-mingw/035.s: src/compiler/rtl/main/RTLLiveness.o src/compiler/rtl/main/RTLLiveness.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLLiveness.sml precompiled/x86-mingw/035.s
precompiled/x86-mingw/036.s: src/compiler/rtl/main/RTLUtils.o src/compiler/rtl/main/RTLUtils.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLUtils.sml precompiled/x86-mingw/036.s
precompiled/x86-mingw/037.s: src/compiler/rtl/main/RTLEdit.o src/compiler/rtl/main/RTLEdit.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTLEdit.sml precompiled/x86-mingw/037.s
precompiled/x86-mingw/038.s: src/compiler/rtl/main/RTL.ppg.o src/compiler/rtl/main/RTL.ppg.sml
	@$(GENASM) x86-mingw src/compiler/rtl/main/RTL.ppg.sml precompiled/x86-mingw/038.s
precompiled/x86-mingw/039.s: src/compiler/aigenerator2/main/AIGenerator.o src/compiler/aigenerator2/main/AIGenerator.sml
	@$(GENASM) x86-mingw src/compiler/aigenerator2/main/AIGenerator.sml precompiled/x86-mingw/039.s
precompiled/x86-mingw/040.s: src/compiler/aigenerator2/main/Simplify.o src/compiler/aigenerator2/main/Simplify.sml
	@$(GENASM) x86-mingw src/compiler/aigenerator2/main/Simplify.sml precompiled/x86-mingw/040.s
precompiled/x86-mingw/041.s: src/compiler/aigenerator2/main/CallAnalysis.o src/compiler/aigenerator2/main/CallAnalysis.sml
	@$(GENASM) x86-mingw src/compiler/aigenerator2/main/CallAnalysis.sml precompiled/x86-mingw/041.s
precompiled/x86-mingw/042.s: src/compiler/aigenerator2/main/BinarySearchCode.o src/compiler/aigenerator2/main/BinarySearchCode.sml
	@$(GENASM) x86-mingw src/compiler/aigenerator2/main/BinarySearchCode.sml precompiled/x86-mingw/042.s
precompiled/x86-mingw/043.s: src/compiler/aigenerator2/main/AIPrimitive.o src/compiler/aigenerator2/main/AIPrimitive.sml
	@$(GENASM) x86-mingw src/compiler/aigenerator2/main/AIPrimitive.sml precompiled/x86-mingw/043.s
precompiled/x86-mingw/044.s: src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.o src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.sml
	@$(GENASM) x86-mingw src/compiler/abstractinstruction2/main/AbstractInstructionFormatter.sml precompiled/x86-mingw/044.s
precompiled/x86-mingw/045.s: src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.o src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.sml
	@$(GENASM) x86-mingw src/compiler/abstractinstruction2/main/AbstractInstruction.ppg.sml precompiled/x86-mingw/045.s
precompiled/x86-mingw/046.s: src/compiler/targetplatform/main/VMTarget.o src/compiler/targetplatform/main/VMTarget.sml
	@$(GENASM) x86-mingw src/compiler/targetplatform/main/VMTarget.sml precompiled/x86-mingw/046.s
precompiled/x86-mingw/047.s: src/compiler/targetplatform/main/TargetProperty.o src/compiler/targetplatform/main/TargetProperty.sml
	@$(GENASM) x86-mingw src/compiler/targetplatform/main/TargetProperty.sml precompiled/x86-mingw/047.s
precompiled/x86-mingw/048.s: src/compiler/targetplatform/main/TargetPlatformFormatter.o src/compiler/targetplatform/main/TargetPlatformFormatter.sml
	@$(GENASM) x86-mingw src/compiler/targetplatform/main/TargetPlatformFormatter.sml precompiled/x86-mingw/048.s
precompiled/x86-mingw/049.s: src/compiler/yaanormalization/main/StaticAllocation.o src/compiler/yaanormalization/main/StaticAllocation.sml
	@$(GENASM) x86-mingw src/compiler/yaanormalization/main/StaticAllocation.sml precompiled/x86-mingw/049.s
precompiled/x86-mingw/050.s: src/compiler/yaanormalization/main/ANormalOptimization.o src/compiler/yaanormalization/main/ANormalOptimization.sml
	@$(GENASM) x86-mingw src/compiler/yaanormalization/main/ANormalOptimization.sml precompiled/x86-mingw/050.s
precompiled/x86-mingw/051.s: src/compiler/toyaanormal/main/ToYAANormal.o src/compiler/toyaanormal/main/ToYAANormal.sml
	@$(GENASM) x86-mingw src/compiler/toyaanormal/main/ToYAANormal.sml precompiled/x86-mingw/051.s
precompiled/x86-mingw/052.s: src/compiler/toyaanormal/main/NameMangle.o src/compiler/toyaanormal/main/NameMangle.sml
	@$(GENASM) x86-mingw src/compiler/toyaanormal/main/NameMangle.sml precompiled/x86-mingw/052.s
precompiled/x86-mingw/053.s: src/compiler/yaanormal/main/ANormal.ppg.o src/compiler/yaanormal/main/ANormal.ppg.sml
	@$(GENASM) x86-mingw src/compiler/yaanormal/main/ANormal.ppg.sml precompiled/x86-mingw/053.s
precompiled/x86-mingw/054.s: src/compiler/systemdef/main/BasicTypeFormatters.o src/compiler/systemdef/main/BasicTypeFormatters.sml
	@$(GENASM) x86-mingw src/compiler/systemdef/main/BasicTypeFormatters.sml precompiled/x86-mingw/054.s
precompiled/x86-mingw/055.s: src/compiler/systemdef/main/BasicTypes.o src/compiler/systemdef/main/BasicTypes.sml
	@$(GENASM) x86-mingw src/compiler/systemdef/main/BasicTypes.sml precompiled/x86-mingw/055.s
precompiled/x86-mingw/056.s: src/compiler/closureconversion/main/ClosureConversion.o src/compiler/closureconversion/main/ClosureConversion.sml
	@$(GENASM) x86-mingw src/compiler/closureconversion/main/ClosureConversion.sml precompiled/x86-mingw/056.s
precompiled/x86-mingw/057.s: src/compiler/closureanormal/main/ClosureANormal.ppg.o src/compiler/closureanormal/main/ClosureANormal.ppg.sml
	@$(GENASM) x86-mingw src/compiler/closureanormal/main/ClosureANormal.ppg.sml precompiled/x86-mingw/057.s
precompiled/x86-mingw/058.s: src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.o src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.sml
	@$(GENASM) x86-mingw src/compiler/bitmapanormaloptimize/main/BitmapANormalReorder.sml precompiled/x86-mingw/058.s
precompiled/x86-mingw/059.s: src/compiler/bitmapanormalization/main/BitmapANormalization.o src/compiler/bitmapanormalization/main/BitmapANormalization.sml
	@$(GENASM) x86-mingw src/compiler/bitmapanormalization/main/BitmapANormalization.sml precompiled/x86-mingw/059.s
precompiled/x86-mingw/060.s: src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.o src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.sml
	@$(GENASM) x86-mingw src/compiler/bitmapanormal/main/TypeCheckBitmapANormal.sml precompiled/x86-mingw/060.s
precompiled/x86-mingw/061.s: src/compiler/bitmapanormal/main/BitmapANormal.ppg.o src/compiler/bitmapanormal/main/BitmapANormal.ppg.sml
	@$(GENASM) x86-mingw src/compiler/bitmapanormal/main/BitmapANormal.ppg.sml precompiled/x86-mingw/061.s
precompiled/x86-mingw/062.s: src/compiler/bitmapcompilation/main/BitmapCompilation.o src/compiler/bitmapcompilation/main/BitmapCompilation.sml
	@$(GENASM) x86-mingw src/compiler/bitmapcompilation/main/BitmapCompilation.sml precompiled/x86-mingw/062.s
precompiled/x86-mingw/063.s: src/compiler/bitmapcompilation/main/SingletonTyEnv.o src/compiler/bitmapcompilation/main/SingletonTyEnv.sml
	@$(GENASM) x86-mingw src/compiler/bitmapcompilation/main/SingletonTyEnv.sml precompiled/x86-mingw/063.s
precompiled/x86-mingw/064.s: src/compiler/bitmapcompilation/main/RecordLayout.o src/compiler/bitmapcompilation/main/RecordLayout.sml
	@$(GENASM) x86-mingw src/compiler/bitmapcompilation/main/RecordLayout.sml precompiled/x86-mingw/064.s
precompiled/x86-mingw/065.s: src/compiler/runtimetypes/main/TypeLayout.o src/compiler/runtimetypes/main/TypeLayout.sml
	@$(GENASM) x86-mingw src/compiler/runtimetypes/main/TypeLayout.sml precompiled/x86-mingw/065.s
precompiled/x86-mingw/066.s: src/compiler/runtimetypes/main/RuntimeTypes.ppg.o src/compiler/runtimetypes/main/RuntimeTypes.ppg.sml
	@$(GENASM) x86-mingw src/compiler/runtimetypes/main/RuntimeTypes.ppg.sml precompiled/x86-mingw/066.s
precompiled/x86-mingw/067.s: src/compiler/bitmapcalc/main/BitmapCalc.ppg.o src/compiler/bitmapcalc/main/BitmapCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/bitmapcalc/main/BitmapCalc.ppg.sml precompiled/x86-mingw/067.s
precompiled/x86-mingw/068.s: src/compiler/recordunboxing/main/RecordUnboxing.o src/compiler/recordunboxing/main/RecordUnboxing.sml
	@$(GENASM) x86-mingw src/compiler/recordunboxing/main/RecordUnboxing.sml precompiled/x86-mingw/068.s
precompiled/x86-mingw/069.s: src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.o src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.sml
	@$(GENASM) x86-mingw src/compiler/multiplevaluecalc/main/MultipleValueCalcUtils.sml precompiled/x86-mingw/069.s
precompiled/x86-mingw/070.s: src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.o src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.sml
	@$(GENASM) x86-mingw src/compiler/multiplevaluecalc/main/MultipleValueCalcFormatter.sml precompiled/x86-mingw/070.s
precompiled/x86-mingw/071.s: src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.o src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/multiplevaluecalc/main/MultipleValueCalc.ppg.sml precompiled/x86-mingw/071.s
precompiled/x86-mingw/072.s: src/compiler/staticanalysis/main/StaticAnalysis.o src/compiler/staticanalysis/main/StaticAnalysis.sml
	@$(GENASM) x86-mingw src/compiler/staticanalysis/main/StaticAnalysis.sml precompiled/x86-mingw/072.s
precompiled/x86-mingw/073.s: src/compiler/staticanalysis/main/SAContext.o src/compiler/staticanalysis/main/SAContext.sml
	@$(GENASM) x86-mingw src/compiler/staticanalysis/main/SAContext.sml precompiled/x86-mingw/073.s
precompiled/x86-mingw/074.s: src/compiler/staticanalysis/main/SAConstraint.o src/compiler/staticanalysis/main/SAConstraint.sml
	@$(GENASM) x86-mingw src/compiler/staticanalysis/main/SAConstraint.sml precompiled/x86-mingw/074.s
precompiled/x86-mingw/075.s: src/compiler/staticanalysis/main/ReduceTy.o src/compiler/staticanalysis/main/ReduceTy.sml
	@$(GENASM) x86-mingw src/compiler/staticanalysis/main/ReduceTy.sml precompiled/x86-mingw/075.s
precompiled/x86-mingw/076.s: src/compiler/annotatedtypes/main/AnnotatedTypesUtils.o src/compiler/annotatedtypes/main/AnnotatedTypesUtils.sml
	@$(GENASM) x86-mingw src/compiler/annotatedtypes/main/AnnotatedTypesUtils.sml precompiled/x86-mingw/076.s
precompiled/x86-mingw/077.s: src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.o src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.sml
	@$(GENASM) x86-mingw src/compiler/annotatedcalc/main/AnnotatedCalcFormatter.sml precompiled/x86-mingw/077.s
precompiled/x86-mingw/078.s: src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.o src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/annotatedcalc/main/AnnotatedCalc.ppg.sml precompiled/x86-mingw/078.s
precompiled/x86-mingw/079.s: src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.o src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.sml
	@$(GENASM) x86-mingw src/compiler/annotatedtypes/main/AnnotatedTypes.ppg.sml precompiled/x86-mingw/079.s
precompiled/x86-mingw/080.s: src/compiler/datatypecompilation/main/DatatypeCompilation.o src/compiler/datatypecompilation/main/DatatypeCompilation.sml
	@$(GENASM) x86-mingw src/compiler/datatypecompilation/main/DatatypeCompilation.sml precompiled/x86-mingw/080.s
precompiled/x86-mingw/081.s: src/compiler/typedlambda/main/TypedLambdaFormatter.o src/compiler/typedlambda/main/TypedLambdaFormatter.sml
	@$(GENASM) x86-mingw src/compiler/typedlambda/main/TypedLambdaFormatter.sml precompiled/x86-mingw/081.s
precompiled/x86-mingw/082.s: src/compiler/typedlambda/main/TypedLambda.ppg.o src/compiler/typedlambda/main/TypedLambda.ppg.sml
	@$(GENASM) x86-mingw src/compiler/typedlambda/main/TypedLambda.ppg.sml precompiled/x86-mingw/082.s
precompiled/x86-mingw/083.s: src/compiler/recordcompilation/main/RecordCompilation.o src/compiler/recordcompilation/main/RecordCompilation.sml
	@$(GENASM) x86-mingw src/compiler/recordcompilation/main/RecordCompilation.sml precompiled/x86-mingw/083.s
precompiled/x86-mingw/084.s: src/compiler/recordcompilation/main/UnivKind.o src/compiler/recordcompilation/main/UnivKind.sml
	@$(GENASM) x86-mingw src/compiler/recordcompilation/main/UnivKind.sml precompiled/x86-mingw/084.s
precompiled/x86-mingw/085.s: src/compiler/recordcompilation/main/RecordKind.o src/compiler/recordcompilation/main/RecordKind.sml
	@$(GENASM) x86-mingw src/compiler/recordcompilation/main/RecordKind.sml precompiled/x86-mingw/085.s
precompiled/x86-mingw/086.s: src/compiler/recordcompilation/main/OverloadKind.o src/compiler/recordcompilation/main/OverloadKind.sml
	@$(GENASM) x86-mingw src/compiler/recordcompilation/main/OverloadKind.sml precompiled/x86-mingw/086.s
precompiled/x86-mingw/087.s: src/compiler/fficompilation/main/FFICompilation.o src/compiler/fficompilation/main/FFICompilation.sml
	@$(GENASM) x86-mingw src/compiler/fficompilation/main/FFICompilation.sml precompiled/x86-mingw/087.s
precompiled/x86-mingw/088.s: src/compiler/sqlcompilation/main/SQLCompilation.o src/compiler/sqlcompilation/main/SQLCompilation.sml
	@$(GENASM) x86-mingw src/compiler/sqlcompilation/main/SQLCompilation.sml precompiled/x86-mingw/088.s
precompiled/x86-mingw/089.s: src/compiler/matchcompilation/main/MatchCompiler.o src/compiler/matchcompilation/main/MatchCompiler.sml
	@$(GENASM) x86-mingw src/compiler/matchcompilation/main/MatchCompiler.sml precompiled/x86-mingw/089.s
precompiled/x86-mingw/090.s: src/compiler/matchcompilation/main/MatchError.ppg.o src/compiler/matchcompilation/main/MatchError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/matchcompilation/main/MatchError.ppg.sml precompiled/x86-mingw/090.s
precompiled/x86-mingw/091.s: src/compiler/matchcompilation/main/MatchData.o src/compiler/matchcompilation/main/MatchData.sml
	@$(GENASM) x86-mingw src/compiler/matchcompilation/main/MatchData.sml precompiled/x86-mingw/091.s
precompiled/x86-mingw/092.s: src/compiler/recordcalc/main/RecordCalcFormatter.o src/compiler/recordcalc/main/RecordCalcFormatter.sml
	@$(GENASM) x86-mingw src/compiler/recordcalc/main/RecordCalcFormatter.sml precompiled/x86-mingw/092.s
precompiled/x86-mingw/093.s: src/compiler/recordcalc/main/RecordCalc.ppg.o src/compiler/recordcalc/main/RecordCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/recordcalc/main/RecordCalc.ppg.sml precompiled/x86-mingw/093.s
precompiled/x86-mingw/094.s: src/compiler/reflection/main/PrinterGeneration.o src/compiler/reflection/main/PrinterGeneration.sml
	@$(GENASM) x86-mingw src/compiler/reflection/main/PrinterGeneration.sml precompiled/x86-mingw/094.s
precompiled/x86-mingw/095.s: src/compiler/reflection/main/Reify.o src/compiler/reflection/main/Reify.sml
	@$(GENASM) x86-mingw src/compiler/reflection/main/Reify.sml precompiled/x86-mingw/095.s
precompiled/x86-mingw/096.s: src/compiler/reflection/main/ReifiedTermData.o src/compiler/reflection/main/ReifiedTermData.sml
	@$(GENASM) x86-mingw src/compiler/reflection/main/ReifiedTermData.sml precompiled/x86-mingw/096.s
precompiled/x86-mingw/097.s: src/reifiedterm/main/ReifiedTerm.ppg.o src/reifiedterm/main/ReifiedTerm.ppg.sml
	@$(GENASM) x86-mingw src/reifiedterm/main/ReifiedTerm.ppg.sml precompiled/x86-mingw/097.s
precompiled/x86-mingw/098.s: src/reifiedterm/main/TermPrintUtils.ppg.o src/reifiedterm/main/TermPrintUtils.ppg.sml
	@$(GENASM) x86-mingw src/reifiedterm/main/TermPrintUtils.ppg.sml precompiled/x86-mingw/098.s
precompiled/x86-mingw/099.s: src/reifiedterm/main/ReflectionControl.o src/reifiedterm/main/ReflectionControl.sml
	@$(GENASM) x86-mingw src/reifiedterm/main/ReflectionControl.sml precompiled/x86-mingw/099.s
precompiled/x86-mingw/100.s: src/compiler/typeinference2/main/UncurryFundecl_ng.o src/compiler/typeinference2/main/UncurryFundecl_ng.sml
	@$(GENASM) x86-mingw src/compiler/typeinference2/main/UncurryFundecl_ng.sml precompiled/x86-mingw/100.s
precompiled/x86-mingw/101.s: src/compiler/typeinference2/main/InferTypes2.o src/compiler/typeinference2/main/InferTypes2.sml
	@$(GENASM) x86-mingw src/compiler/typeinference2/main/InferTypes2.sml precompiled/x86-mingw/101.s
precompiled/x86-mingw/102.s: src/compiler/typeinference2/main/Printers.o src/compiler/typeinference2/main/Printers.sml
	@$(GENASM) x86-mingw src/compiler/typeinference2/main/Printers.sml precompiled/x86-mingw/102.s
precompiled/x86-mingw/103.s: src/compiler/typeinference2/main/TypeInferenceUtils.o src/compiler/typeinference2/main/TypeInferenceUtils.sml
	@$(GENASM) x86-mingw src/compiler/typeinference2/main/TypeInferenceUtils.sml precompiled/x86-mingw/103.s
precompiled/x86-mingw/104.s: src/compiler/typeinference2/main/TypeInferenceError.ppg.o src/compiler/typeinference2/main/TypeInferenceError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/typeinference2/main/TypeInferenceError.ppg.sml precompiled/x86-mingw/104.s
precompiled/x86-mingw/105.s: src/compiler/typeinference2/main/TypeInferenceContext.ppg.o src/compiler/typeinference2/main/TypeInferenceContext.ppg.sml
	@$(GENASM) x86-mingw src/compiler/typeinference2/main/TypeInferenceContext.ppg.sml precompiled/x86-mingw/105.s
precompiled/x86-mingw/106.s: src/compiler/types/main/Unify.o src/compiler/types/main/Unify.sml
	@$(GENASM) x86-mingw src/compiler/types/main/Unify.sml precompiled/x86-mingw/106.s
precompiled/x86-mingw/107.s: src/compiler/types/main/CheckEq.o src/compiler/types/main/CheckEq.sml
	@$(GENASM) x86-mingw src/compiler/types/main/CheckEq.sml precompiled/x86-mingw/107.s
precompiled/x86-mingw/108.s: src/compiler/typedcalc/main/TypedCalcUtils.o src/compiler/typedcalc/main/TypedCalcUtils.sml
	@$(GENASM) x86-mingw src/compiler/typedcalc/main/TypedCalcUtils.sml precompiled/x86-mingw/108.s
precompiled/x86-mingw/109.s: src/compiler/constantterm/main/ConstantTerm.ppg.o src/compiler/constantterm/main/ConstantTerm.ppg.sml
	@$(GENASM) x86-mingw src/compiler/constantterm/main/ConstantTerm.ppg.sml precompiled/x86-mingw/109.s
precompiled/x86-mingw/110.s: src/compiler/types/main/TypesUtils.o src/compiler/types/main/TypesUtils.sml
	@$(GENASM) x86-mingw src/compiler/types/main/TypesUtils.sml precompiled/x86-mingw/110.s
precompiled/x86-mingw/111.s: src/compiler/types/main/vars.o src/compiler/types/main/vars.sml
	@$(GENASM) x86-mingw src/compiler/types/main/vars.sml precompiled/x86-mingw/111.s
precompiled/x86-mingw/112.s: src/compiler/typedcalc/main/TypedCalc.ppg.o src/compiler/typedcalc/main/TypedCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/typedcalc/main/TypedCalc.ppg.sml precompiled/x86-mingw/112.s
precompiled/x86-mingw/113.s: src/compiler/valrecoptimization/main/TransFundecl.o src/compiler/valrecoptimization/main/TransFundecl.sml
	@$(GENASM) x86-mingw src/compiler/valrecoptimization/main/TransFundecl.sml precompiled/x86-mingw/113.s
precompiled/x86-mingw/114.s: src/compiler/valrecoptimization/main/VALREC_Optimizer.o src/compiler/valrecoptimization/main/VALREC_Optimizer.sml
	@$(GENASM) x86-mingw src/compiler/valrecoptimization/main/VALREC_Optimizer.sml precompiled/x86-mingw/114.s
precompiled/x86-mingw/115.s: src/compiler/valrecoptimization/main/utils.o src/compiler/valrecoptimization/main/utils.sml
	@$(GENASM) x86-mingw src/compiler/valrecoptimization/main/utils.sml precompiled/x86-mingw/115.s
precompiled/x86-mingw/116.s: src/compiler/nameevaluation/main/NameEval.o src/compiler/nameevaluation/main/NameEval.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/NameEval.sml precompiled/x86-mingw/116.s
precompiled/x86-mingw/117.s: src/compiler/nameevaluation/main/CheckProvide.o src/compiler/nameevaluation/main/CheckProvide.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/CheckProvide.sml precompiled/x86-mingw/117.s
precompiled/x86-mingw/118.s: src/compiler/nameevaluation/main/NameEvalInterface.o src/compiler/nameevaluation/main/NameEvalInterface.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/NameEvalInterface.sml precompiled/x86-mingw/118.s
precompiled/x86-mingw/119.s: src/compiler/nameevaluation/main/SigCheck.o src/compiler/nameevaluation/main/SigCheck.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/SigCheck.sml precompiled/x86-mingw/119.s
precompiled/x86-mingw/120.s: src/compiler/nameevaluation/main/FunctorUtils.o src/compiler/nameevaluation/main/FunctorUtils.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/FunctorUtils.sml precompiled/x86-mingw/120.s
precompiled/x86-mingw/121.s: src/compiler/nameevaluation/main/EvalSig.o src/compiler/nameevaluation/main/EvalSig.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/EvalSig.sml precompiled/x86-mingw/121.s
precompiled/x86-mingw/122.s: src/compiler/nameevaluation/main/Subst.o src/compiler/nameevaluation/main/Subst.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/Subst.sml precompiled/x86-mingw/122.s
precompiled/x86-mingw/123.s: src/compiler/nameevaluation/main/EvalTy.o src/compiler/nameevaluation/main/EvalTy.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/EvalTy.sml precompiled/x86-mingw/123.s
precompiled/x86-mingw/124.s: src/compiler/nameevaluation/main/SetLiftedTys.o src/compiler/nameevaluation/main/SetLiftedTys.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/SetLiftedTys.sml precompiled/x86-mingw/124.s
precompiled/x86-mingw/125.s: src/compiler/util/main/SCCFun.o src/compiler/util/main/SCCFun.sml
	@$(GENASM) x86-mingw src/compiler/util/main/SCCFun.sml precompiled/x86-mingw/125.s
precompiled/x86-mingw/126.s: src/compiler/util/main/Graph.o src/compiler/util/main/Graph.sml
	@$(GENASM) x86-mingw src/compiler/util/main/Graph.sml precompiled/x86-mingw/126.s
precompiled/x86-mingw/127.s: src/compiler/nameevaluation/main/NormalizeTy.o src/compiler/nameevaluation/main/NormalizeTy.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/NormalizeTy.sml precompiled/x86-mingw/127.s
precompiled/x86-mingw/128.s: src/compiler/nameevaluation/main/NameEvalUtils.o src/compiler/nameevaluation/main/NameEvalUtils.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/NameEvalUtils.sml precompiled/x86-mingw/128.s
precompiled/x86-mingw/129.s: src/compiler/nameevaluation/main/TfunVars.o src/compiler/nameevaluation/main/TfunVars.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/TfunVars.sml precompiled/x86-mingw/129.s
precompiled/x86-mingw/130.s: src/compiler-utils/env/main/PathEnv.o src/compiler-utils/env/main/PathEnv.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/PathEnv.sml precompiled/x86-mingw/130.s
precompiled/x86-mingw/131.s: src/compiler/nameevaluation/main/NameEvalEnv.ppg.o src/compiler/nameevaluation/main/NameEvalEnv.ppg.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/NameEvalEnv.ppg.sml precompiled/x86-mingw/131.s
precompiled/x86-mingw/132.s: src/compiler/nameevaluation/main/NameEvalError.ppg.o src/compiler/nameevaluation/main/NameEvalError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/nameevaluation/main/NameEvalError.ppg.sml precompiled/x86-mingw/132.s
precompiled/x86-mingw/133.s: src/compiler/elaborate/main/Elaborator.o src/compiler/elaborate/main/Elaborator.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/Elaborator.sml precompiled/x86-mingw/133.s
precompiled/x86-mingw/134.s: src/compiler/elaborate/main/ElaborateInterface.o src/compiler/elaborate/main/ElaborateInterface.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaborateInterface.sml precompiled/x86-mingw/134.s
precompiled/x86-mingw/135.s: src/compiler/elaborate/main/UserTvarScope.o src/compiler/elaborate/main/UserTvarScope.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/UserTvarScope.sml precompiled/x86-mingw/135.s
precompiled/x86-mingw/136.s: src/compiler/elaborate/main/ElaborateModule.o src/compiler/elaborate/main/ElaborateModule.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaborateModule.sml precompiled/x86-mingw/136.s
precompiled/x86-mingw/137.s: src/compiler/elaborate/main/ElaborateCore.o src/compiler/elaborate/main/ElaborateCore.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaborateCore.sml precompiled/x86-mingw/137.s
precompiled/x86-mingw/138.s: src/compiler/elaborate/main/ElaborateSQL.o src/compiler/elaborate/main/ElaborateSQL.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaborateSQL.sml precompiled/x86-mingw/138.s
precompiled/x86-mingw/139.s: src/compiler/elaborate/main/ElaborateErrorSQL.ppg.o src/compiler/elaborate/main/ElaborateErrorSQL.ppg.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaborateErrorSQL.ppg.sml precompiled/x86-mingw/139.s
precompiled/x86-mingw/140.s: src/compiler/elaborate/main/ElaboratorUtils.o src/compiler/elaborate/main/ElaboratorUtils.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaboratorUtils.sml precompiled/x86-mingw/140.s
precompiled/x86-mingw/141.s: src/compiler/util/main/utils.o src/compiler/util/main/utils.sml
	@$(GENASM) x86-mingw src/compiler/util/main/utils.sml precompiled/x86-mingw/141.s
precompiled/x86-mingw/142.s: src/compiler/usererror/main/UserErrorUtils.o src/compiler/usererror/main/UserErrorUtils.sml
	@$(GENASM) x86-mingw src/compiler/usererror/main/UserErrorUtils.sml precompiled/x86-mingw/142.s
precompiled/x86-mingw/143.s: src/compiler/elaborate/main/ElaborateError.ppg.o src/compiler/elaborate/main/ElaborateError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/elaborate/main/ElaborateError.ppg.sml precompiled/x86-mingw/143.s
precompiled/x86-mingw/144.s: src/compiler/absyn/main/Fixity.o src/compiler/absyn/main/Fixity.sml
	@$(GENASM) x86-mingw src/compiler/absyn/main/Fixity.sml precompiled/x86-mingw/144.s
precompiled/x86-mingw/145.s: src/compiler/loadfile/main/LoadFile.o src/compiler/loadfile/main/LoadFile.sml
	@$(GENASM) x86-mingw src/compiler/loadfile/main/LoadFile.sml precompiled/x86-mingw/145.s
precompiled/x86-mingw/146.s: src/compiler/loadfile/main/LoadFileError.ppg.o src/compiler/loadfile/main/LoadFileError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/loadfile/main/LoadFileError.ppg.sml precompiled/x86-mingw/146.s
precompiled/x86-mingw/147.s: src/compiler/loadfile/main/InterfaceHash.o src/compiler/loadfile/main/InterfaceHash.sml
	@$(GENASM) x86-mingw src/compiler/loadfile/main/InterfaceHash.sml precompiled/x86-mingw/147.s
precompiled/x86-mingw/148.s: src/compiler/loadfile/main/SHA1.o src/compiler/loadfile/main/SHA1.sml
	@$(GENASM) x86-mingw src/compiler/loadfile/main/SHA1.sml precompiled/x86-mingw/148.s
precompiled/x86-mingw/149.s: src/compiler/parser/main/InterfaceParser.o src/compiler/parser/main/InterfaceParser.sml
	@$(GENASM) x86-mingw src/compiler/parser/main/InterfaceParser.sml precompiled/x86-mingw/149.s
precompiled/x86-mingw/150.s: src/compiler/parser/main/interface.grm.o src/compiler/parser/main/interface.grm.sml
	@$(GENASM) x86-mingw src/compiler/parser/main/interface.grm.sml precompiled/x86-mingw/150.s
precompiled/x86-mingw/151.s: src/compiler/patterncalc/main/PatternCalcInterface.ppg.o src/compiler/patterncalc/main/PatternCalcInterface.ppg.sml
	@$(GENASM) x86-mingw src/compiler/patterncalc/main/PatternCalcInterface.ppg.sml precompiled/x86-mingw/151.s
precompiled/x86-mingw/152.s: src/compiler/absyn/main/AbsynFormatter.o src/compiler/absyn/main/AbsynFormatter.sml
	@$(GENASM) x86-mingw src/compiler/absyn/main/AbsynFormatter.sml precompiled/x86-mingw/152.s
precompiled/x86-mingw/153.s: src/compiler/builtin/main/BuiltinContextSources.o src/compiler/builtin/main/BuiltinContextSources.sml
	@$(GENASM) x86-mingw src/compiler/builtin/main/BuiltinContextSources.sml precompiled/x86-mingw/153.s
precompiled/x86-mingw/154.s: src/compiler/builtin/main/BuiltinContext_smi.o src/compiler/builtin/main/BuiltinContext_smi.sml
	@$(GENASM) x86-mingw src/compiler/builtin/main/BuiltinContext_smi.sml precompiled/x86-mingw/154.s
precompiled/x86-mingw/155.s: src/compiler/types/main/BuiltinEnv.o src/compiler/types/main/BuiltinEnv.sml
	@$(GENASM) x86-mingw src/compiler/types/main/BuiltinEnv.sml precompiled/x86-mingw/155.s
precompiled/x86-mingw/156.s: src/compiler/types/main/EvalIty.o src/compiler/types/main/EvalIty.sml
	@$(GENASM) x86-mingw src/compiler/types/main/EvalIty.sml precompiled/x86-mingw/156.s
precompiled/x86-mingw/157.s: src/compiler/types/main/OPrimMap.o src/compiler/types/main/OPrimMap.sml
	@$(GENASM) x86-mingw src/compiler/types/main/OPrimMap.sml precompiled/x86-mingw/157.s
precompiled/x86-mingw/158.s: src/compiler/types/main/VarMap.o src/compiler/types/main/VarMap.sml
	@$(GENASM) x86-mingw src/compiler/types/main/VarMap.sml precompiled/x86-mingw/158.s
precompiled/x86-mingw/159.s: src/compiler/types/main/IDCalc.ppg.o src/compiler/types/main/IDCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/types/main/IDCalc.ppg.sml precompiled/x86-mingw/159.s
precompiled/x86-mingw/160.s: src/compiler/types/main/Types.ppg.o src/compiler/types/main/Types.ppg.sml
	@$(GENASM) x86-mingw src/compiler/types/main/Types.ppg.sml precompiled/x86-mingw/160.s
precompiled/x86-mingw/161.s: src/compiler/types/main/OPrimInstMap.o src/compiler/types/main/OPrimInstMap.sml
	@$(GENASM) x86-mingw src/compiler/types/main/OPrimInstMap.sml precompiled/x86-mingw/161.s
precompiled/x86-mingw/162.s: src/compiler/types/main/tvarMap.o src/compiler/types/main/tvarMap.sml
	@$(GENASM) x86-mingw src/compiler/types/main/tvarMap.sml precompiled/x86-mingw/162.s
precompiled/x86-mingw/163.s: src/compiler/patterncalc/main/PatternCalc.ppg.o src/compiler/patterncalc/main/PatternCalc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/patterncalc/main/PatternCalc.ppg.sml precompiled/x86-mingw/163.s
precompiled/x86-mingw/164.s: src/compiler/builtin/main/BuiltinPrimitive.ppg.o src/compiler/builtin/main/BuiltinPrimitive.ppg.sml
	@$(GENASM) x86-mingw src/compiler/builtin/main/BuiltinPrimitive.ppg.sml precompiled/x86-mingw/164.s
precompiled/x86-mingw/165.s: src/compiler/util/main/gensym.o src/compiler/util/main/gensym.sml
	@$(GENASM) x86-mingw src/compiler/util/main/gensym.sml precompiled/x86-mingw/165.s
precompiled/x86-mingw/166.s: src/compiler/builtin/main/BuiltinName.o src/compiler/builtin/main/BuiltinName.sml
	@$(GENASM) x86-mingw src/compiler/builtin/main/BuiltinName.sml precompiled/x86-mingw/166.s
precompiled/x86-mingw/167.s: src/compiler/builtin/main/BuiltinType.ppg.o src/compiler/builtin/main/BuiltinType.ppg.sml
	@$(GENASM) x86-mingw src/compiler/builtin/main/BuiltinType.ppg.sml precompiled/x86-mingw/167.s
precompiled/x86-mingw/168.s: src/compiler/generatemain/main/GenerateMain.o src/compiler/generatemain/main/GenerateMain.sml
	@$(GENASM) x86-mingw src/compiler/generatemain/main/GenerateMain.sml precompiled/x86-mingw/168.s
precompiled/x86-mingw/169.s: src/compiler/generatemain/main/GenerateMainError.ppg.o src/compiler/generatemain/main/GenerateMainError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/generatemain/main/GenerateMainError.ppg.sml precompiled/x86-mingw/169.s
precompiled/x86-mingw/170.s: src/compiler/parser/main/Parser.o src/compiler/parser/main/Parser.sml
	@$(GENASM) x86-mingw src/compiler/parser/main/Parser.sml precompiled/x86-mingw/170.s
precompiled/x86-mingw/171.s: src/compiler/parser/main/iml.lex.o src/compiler/parser/main/iml.lex.sml
	@$(GENASM) x86-mingw src/compiler/parser/main/iml.lex.sml precompiled/x86-mingw/171.s
precompiled/x86-mingw/172.s: src/compiler/parser/main/iml.grm.o src/compiler/parser/main/iml.grm.sml
	@$(GENASM) x86-mingw src/compiler/parser/main/iml.grm.sml precompiled/x86-mingw/172.s
precompiled/x86-mingw/173.s: src/compiler/parser/main/ParserError.ppg.o src/compiler/parser/main/ParserError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/parser/main/ParserError.ppg.sml precompiled/x86-mingw/173.s
precompiled/x86-mingw/174.s: src/ml-yacc/lib/parser2.o src/ml-yacc/lib/parser2.sml
	@$(GENASM) x86-mingw src/ml-yacc/lib/parser2.sml precompiled/x86-mingw/174.s
precompiled/x86-mingw/175.s: src/ml-yacc/lib/stream.o src/ml-yacc/lib/stream.sml
	@$(GENASM) x86-mingw src/ml-yacc/lib/stream.sml precompiled/x86-mingw/175.s
precompiled/x86-mingw/176.s: src/ml-yacc/lib/lrtable.o src/ml-yacc/lib/lrtable.sml
	@$(GENASM) x86-mingw src/ml-yacc/lib/lrtable.sml precompiled/x86-mingw/176.s
precompiled/x86-mingw/177.s: src/ml-yacc/lib/join.o src/ml-yacc/lib/join.sml
	@$(GENASM) x86-mingw src/ml-yacc/lib/join.sml precompiled/x86-mingw/177.s
precompiled/x86-mingw/178.s: src/compiler/absyn/main/AbsynInterface.ppg.o src/compiler/absyn/main/AbsynInterface.ppg.sml
	@$(GENASM) x86-mingw src/compiler/absyn/main/AbsynInterface.ppg.sml precompiled/x86-mingw/178.s
precompiled/x86-mingw/179.s: src/compiler/absyn/main/Absyn.ppg.o src/compiler/absyn/main/Absyn.ppg.sml
	@$(GENASM) x86-mingw src/compiler/absyn/main/Absyn.ppg.sml precompiled/x86-mingw/179.s
precompiled/x86-mingw/180.s: src/compiler/absyn/main/AbsynSQL.ppg.o src/compiler/absyn/main/AbsynSQL.ppg.sml
	@$(GENASM) x86-mingw src/compiler/absyn/main/AbsynSQL.ppg.sml precompiled/x86-mingw/180.s
precompiled/x86-mingw/181.s: src/compiler/util/main/SmlppgUtil.ppg.o src/compiler/util/main/SmlppgUtil.ppg.sml
	@$(GENASM) x86-mingw src/compiler/util/main/SmlppgUtil.ppg.sml precompiled/x86-mingw/181.s
precompiled/x86-mingw/182.s: src/compiler-utils/env/main/SSet.o src/compiler-utils/env/main/SSet.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/SSet.sml precompiled/x86-mingw/182.s
precompiled/x86-mingw/183.s: src/compiler-utils/env/main/SOrd.o src/compiler-utils/env/main/SOrd.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/SOrd.sml precompiled/x86-mingw/183.s
precompiled/x86-mingw/184.s: src/compiler/util/main/TermFormat.o src/compiler/util/main/TermFormat.sml
	@$(GENASM) x86-mingw src/compiler/util/main/TermFormat.sml precompiled/x86-mingw/184.s
precompiled/x86-mingw/185.s: src/compiler/util/main/BigInt_IntInf.o src/compiler/util/main/BigInt_IntInf.sml
	@$(GENASM) x86-mingw src/compiler/util/main/BigInt_IntInf.sml precompiled/x86-mingw/185.s
precompiled/x86-mingw/186.s: src/compiler/util/main/ListSorter.o src/compiler/util/main/ListSorter.sml
	@$(GENASM) x86-mingw src/compiler/util/main/ListSorter.sml precompiled/x86-mingw/186.s
precompiled/x86-mingw/187.s: src/compiler-utils/env/main/LabelEnv.o src/compiler-utils/env/main/LabelEnv.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/LabelEnv.sml precompiled/x86-mingw/187.s
precompiled/x86-mingw/188.s: src/compiler-utils/env/main/LabelOrd.o src/compiler-utils/env/main/LabelOrd.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/LabelOrd.sml precompiled/x86-mingw/188.s
precompiled/x86-mingw/189.s: src/smlnj-lib/Util/binary-map-fn.o src/smlnj-lib/Util/binary-map-fn.sml
	@$(GENASM) x86-mingw src/smlnj-lib/Util/binary-map-fn.sml precompiled/x86-mingw/189.s
precompiled/x86-mingw/190.s: src/compiler/name/main/LocalID.o src/compiler/name/main/LocalID.sml
	@$(GENASM) x86-mingw src/compiler/name/main/LocalID.sml precompiled/x86-mingw/190.s
precompiled/x86-mingw/191.s: src/compiler-utils/env/main/ISet.o src/compiler-utils/env/main/ISet.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/ISet.sml precompiled/x86-mingw/191.s
precompiled/x86-mingw/192.s: src/compiler-utils/env/main/IOrd.o src/compiler-utils/env/main/IOrd.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/IOrd.sml precompiled/x86-mingw/192.s
precompiled/x86-mingw/193.s: src/compiler/toolchain/main/BinUtils.o src/compiler/toolchain/main/BinUtils.sml
	@$(GENASM) x86-mingw src/compiler/toolchain/main/BinUtils.sml precompiled/x86-mingw/193.s
precompiled/x86-mingw/194.s: src/compiler/toolchain/main/TempFile.o src/compiler/toolchain/main/TempFile.sml
	@$(GENASM) x86-mingw src/compiler/toolchain/main/TempFile.sml precompiled/x86-mingw/194.s
precompiled/x86-mingw/195.s: src/compiler/toolchain/main/CoreUtils.o src/compiler/toolchain/main/CoreUtils.sml
	@$(GENASM) x86-mingw src/compiler/toolchain/main/CoreUtils.sml precompiled/x86-mingw/195.s
precompiled/x86-mingw/196.s: src/compiler/usererror/main/UserError.ppg.o src/compiler/usererror/main/UserError.ppg.sml
	@$(GENASM) x86-mingw src/compiler/usererror/main/UserError.ppg.sml precompiled/x86-mingw/196.s
precompiled/x86-mingw/197.s: src/compiler/util/main/Counter.o src/compiler/util/main/Counter.sml
	@$(GENASM) x86-mingw src/compiler/util/main/Counter.sml precompiled/x86-mingw/197.s
precompiled/x86-mingw/198.s: src/compiler-utils/env/main/IEnv.o src/compiler-utils/env/main/IEnv.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/IEnv.sml precompiled/x86-mingw/198.s
precompiled/x86-mingw/199.s: src/smlnj-lib/Util/binary-set-fn.o src/smlnj-lib/Util/binary-set-fn.sml
	@$(GENASM) x86-mingw src/smlnj-lib/Util/binary-set-fn.sml precompiled/x86-mingw/199.s
precompiled/x86-mingw/200.s: src/compiler/control/main/Control.ppg.o src/compiler/control/main/Control.ppg.sml
	@$(GENASM) x86-mingw src/compiler/control/main/Control.ppg.sml precompiled/x86-mingw/200.s
precompiled/x86-mingw/201.s: src/compiler/control/main/Loc.ppg.o src/compiler/control/main/Loc.ppg.sml
	@$(GENASM) x86-mingw src/compiler/control/main/Loc.ppg.sml precompiled/x86-mingw/201.s
precompiled/x86-mingw/202.s: src/smlformat/formatlib/main/SMLFormat.o src/smlformat/formatlib/main/SMLFormat.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/SMLFormat.sml precompiled/x86-mingw/202.s
precompiled/x86-mingw/203.s: src/smlformat/formatlib/main/BasicFormatters.o src/smlformat/formatlib/main/BasicFormatters.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/BasicFormatters.sml precompiled/x86-mingw/203.s
precompiled/x86-mingw/204.s: src/smlformat/formatlib/main/PreProcessor.o src/smlformat/formatlib/main/PreProcessor.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/PreProcessor.sml precompiled/x86-mingw/204.s
precompiled/x86-mingw/205.s: src/smlformat/formatlib/main/Truncator.o src/smlformat/formatlib/main/Truncator.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/Truncator.sml precompiled/x86-mingw/205.s
precompiled/x86-mingw/206.s: src/smlformat/formatlib/main/PrettyPrinter.o src/smlformat/formatlib/main/PrettyPrinter.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/PrettyPrinter.sml precompiled/x86-mingw/206.s
precompiled/x86-mingw/207.s: src/smlformat/formatlib/main/PreProcessedExpression.o src/smlformat/formatlib/main/PreProcessedExpression.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/PreProcessedExpression.sml precompiled/x86-mingw/207.s
precompiled/x86-mingw/208.s: src/smlformat/formatlib/main/AssocResolver.o src/smlformat/formatlib/main/AssocResolver.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/AssocResolver.sml precompiled/x86-mingw/208.s
precompiled/x86-mingw/209.s: src/smlformat/formatlib/main/PrinterParameter.o src/smlformat/formatlib/main/PrinterParameter.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/PrinterParameter.sml precompiled/x86-mingw/209.s
precompiled/x86-mingw/210.s: src/smlformat/formatlib/main/FormatExpression.o src/smlformat/formatlib/main/FormatExpression.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/FormatExpression.sml precompiled/x86-mingw/210.s
precompiled/x86-mingw/211.s: src/smlformat/formatlib/main/FormatExpressionTypes.o src/smlformat/formatlib/main/FormatExpressionTypes.sml
	@$(GENASM) x86-mingw src/smlformat/formatlib/main/FormatExpressionTypes.sml precompiled/x86-mingw/211.s
precompiled/x86-mingw/212.s: src/smlnj-lib/Util/parser-comb.o src/smlnj-lib/Util/parser-comb.sml
	@$(GENASM) x86-mingw src/smlnj-lib/Util/parser-comb.sml precompiled/x86-mingw/212.s
precompiled/x86-mingw/213.s: src/config/main/Config.o src/config/main/Config.sml
	@$(GENASM) x86-mingw src/config/main/Config.sml precompiled/x86-mingw/213.s
precompiled/x86-mingw/214.s: src/compiler/toolchain/main/Filename.o src/compiler/toolchain/main/Filename.sml
	@$(GENASM) x86-mingw src/compiler/toolchain/main/Filename.sml precompiled/x86-mingw/214.s
precompiled/x86-mingw/215.s: src/compiler-utils/env/main/SEnv.o src/compiler-utils/env/main/SEnv.sml
	@$(GENASM) x86-mingw src/compiler-utils/env/main/SEnv.sml precompiled/x86-mingw/215.s
precompiled/x86-mingw/216.s: src/smlnj-lib/Util/lib-base.o src/smlnj-lib/Util/lib-base.sml
	@$(GENASM) x86-mingw src/smlnj-lib/Util/lib-base.sml precompiled/x86-mingw/216.s
precompiled/x86-mingw/217.s: src/config/main/Version.o src/config/main/Version.sml
	@$(GENASM) x86-mingw src/config/main/Version.sml precompiled/x86-mingw/217.s
precompiled/x86-mingw/218.s: src/basis/main/binary-op.o src/basis/main/binary-op.sml
	@$(GENASM) x86-mingw src/basis/main/binary-op.sml precompiled/x86-mingw/218.s
precompiled/x86-mingw/219.s: src/basis/main/Date.o src/basis/main/Date.sml
	@$(GENASM) x86-mingw src/basis/main/Date.sml precompiled/x86-mingw/219.s
precompiled/x86-mingw/220.s: src/basis/main/Timer.o src/basis/main/Timer.sml
	@$(GENASM) x86-mingw src/basis/main/Timer.sml precompiled/x86-mingw/220.s
precompiled/x86-mingw/221.s: src/smlnj/Basis/internal-timer.o src/smlnj/Basis/internal-timer.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/internal-timer.sml precompiled/x86-mingw/221.s
precompiled/x86-mingw/222.s: src/basis/main/ArraySlice.o src/basis/main/ArraySlice.sml
	@$(GENASM) x86-mingw src/basis/main/ArraySlice.sml precompiled/x86-mingw/222.s
precompiled/x86-mingw/223.s: src/basis/main/CommandLine.o src/basis/main/CommandLine.sml
	@$(GENASM) x86-mingw src/basis/main/CommandLine.sml precompiled/x86-mingw/223.s
precompiled/x86-mingw/224.s: src/basis/main/Text.o src/basis/main/Text.sml
	@$(GENASM) x86-mingw src/basis/main/Text.sml precompiled/x86-mingw/224.s
precompiled/x86-mingw/225.s: src/basis/main/BinIO.o src/basis/main/BinIO.sml
	@$(GENASM) x86-mingw src/basis/main/BinIO.sml precompiled/x86-mingw/225.s
precompiled/x86-mingw/226.s: src/smlnj/Basis/IO/bin-io.o src/smlnj/Basis/IO/bin-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/IO/bin-io.sml precompiled/x86-mingw/226.s
precompiled/x86-mingw/227.s: src/smlnj/Basis/Unix/posix-bin-prim-io.o src/smlnj/Basis/Unix/posix-bin-prim-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/Unix/posix-bin-prim-io.sml precompiled/x86-mingw/227.s
precompiled/x86-mingw/228.s: src/basis/main/TextIO.o src/basis/main/TextIO.sml
	@$(GENASM) x86-mingw src/basis/main/TextIO.sml precompiled/x86-mingw/228.s
precompiled/x86-mingw/229.s: src/smlnj/Basis/IO/text-io.o src/smlnj/Basis/IO/text-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/IO/text-io.sml precompiled/x86-mingw/229.s
precompiled/x86-mingw/230.s: src/smlnj/Basis/Unix/posix-text-prim-io.o src/smlnj/Basis/Unix/posix-text-prim-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/Unix/posix-text-prim-io.sml precompiled/x86-mingw/230.s
precompiled/x86-mingw/231.s: src/smlnj/Basis/Posix/posix-io.o src/smlnj/Basis/Posix/posix-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/Posix/posix-io.sml precompiled/x86-mingw/231.s
precompiled/x86-mingw/232.s: src/smlnj/Basis/IO/prim-io-bin.o src/smlnj/Basis/IO/prim-io-bin.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/IO/prim-io-bin.sml precompiled/x86-mingw/232.s
precompiled/x86-mingw/233.s: src/basis/main/Word8.o src/basis/main/Word8.sml
	@$(GENASM) x86-mingw src/basis/main/Word8.sml precompiled/x86-mingw/233.s
precompiled/x86-mingw/234.s: src/smlnj/Basis/IO/clean-io.o src/smlnj/Basis/IO/clean-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/IO/clean-io.sml precompiled/x86-mingw/234.s
precompiled/x86-mingw/235.s: src/smlnj/Basis/IO/prim-io-text.o src/smlnj/Basis/IO/prim-io-text.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/IO/prim-io-text.sml precompiled/x86-mingw/235.s
precompiled/x86-mingw/236.s: src/basis/main/CharArray.o src/basis/main/CharArray.sml
	@$(GENASM) x86-mingw src/basis/main/CharArray.sml precompiled/x86-mingw/236.s
precompiled/x86-mingw/237.s: src/basis/main/OS.o src/basis/main/OS.sml
	@$(GENASM) x86-mingw src/basis/main/OS.sml precompiled/x86-mingw/237.s
precompiled/x86-mingw/238.s: src/smlnj/Basis/Unix/os-io.o src/smlnj/Basis/Unix/os-io.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/Unix/os-io.sml precompiled/x86-mingw/238.s
precompiled/x86-mingw/239.s: src/basis/main/ListPair.o src/basis/main/ListPair.sml
	@$(GENASM) x86-mingw src/basis/main/ListPair.sml precompiled/x86-mingw/239.s
precompiled/x86-mingw/240.s: src/smlnj/Basis/Unix/os-filesys.o src/smlnj/Basis/Unix/os-filesys.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/Unix/os-filesys.sml precompiled/x86-mingw/240.s
precompiled/x86-mingw/241.s: src/smlnj/Basis/Unix/os-path.o src/smlnj/Basis/Unix/os-path.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/Unix/os-path.sml precompiled/x86-mingw/241.s
precompiled/x86-mingw/242.s: src/smlnj/Basis/OS/os-path-fn.o src/smlnj/Basis/OS/os-path-fn.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/OS/os-path-fn.sml precompiled/x86-mingw/242.s
precompiled/x86-mingw/243.s: src/basis/main/SMLSharpOSProcess.o src/basis/main/SMLSharpOSProcess.sml
	@$(GENASM) x86-mingw src/basis/main/SMLSharpOSProcess.sml precompiled/x86-mingw/243.s
precompiled/x86-mingw/244.s: src/smlnj/Basis/NJ/cleanup.o src/smlnj/Basis/NJ/cleanup.sml
	@$(GENASM) x86-mingw src/smlnj/Basis/NJ/cleanup.sml precompiled/x86-mingw/244.s
precompiled/x86-mingw/245.s: src/basis/main/SMLSharpOSFileSys.o src/basis/main/SMLSharpOSFileSys.sml
	@$(GENASM) x86-mingw src/basis/main/SMLSharpOSFileSys.sml precompiled/x86-mingw/245.s
precompiled/x86-mingw/246.s: src/basis/main/Byte.o src/basis/main/Byte.sml
	@$(GENASM) x86-mingw src/basis/main/Byte.sml precompiled/x86-mingw/246.s
precompiled/x86-mingw/247.s: src/basis/main/Word8Array.o src/basis/main/Word8Array.sml
	@$(GENASM) x86-mingw src/basis/main/Word8Array.sml precompiled/x86-mingw/247.s
precompiled/x86-mingw/248.s: src/basis/main/Word.o src/basis/main/Word.sml
	@$(GENASM) x86-mingw src/basis/main/Word.sml precompiled/x86-mingw/248.s
precompiled/x86-mingw/249.s: src/basis/main/Time.o src/basis/main/Time.sml
	@$(GENASM) x86-mingw src/basis/main/Time.sml precompiled/x86-mingw/249.s
precompiled/x86-mingw/250.s: src/basis/main/Real32.o src/basis/main/Real32.sml
	@$(GENASM) x86-mingw src/basis/main/Real32.sml precompiled/x86-mingw/250.s
precompiled/x86-mingw/251.s: src/basis/main/Real.o src/basis/main/Real.sml
	@$(GENASM) x86-mingw src/basis/main/Real.sml precompiled/x86-mingw/251.s
precompiled/x86-mingw/252.s: src/basis/main/Substring.o src/basis/main/Substring.sml
	@$(GENASM) x86-mingw src/basis/main/Substring.sml precompiled/x86-mingw/252.s
precompiled/x86-mingw/253.s: src/basis/main/RealClass.o src/basis/main/RealClass.sml
	@$(GENASM) x86-mingw src/basis/main/RealClass.sml precompiled/x86-mingw/253.s
precompiled/x86-mingw/254.s: src/basis/main/IEEEReal.o src/basis/main/IEEEReal.sml
	@$(GENASM) x86-mingw src/basis/main/IEEEReal.sml precompiled/x86-mingw/254.s
precompiled/x86-mingw/255.s: src/basis/main/Int.o src/basis/main/Int.sml
	@$(GENASM) x86-mingw src/basis/main/Int.sml precompiled/x86-mingw/255.s
precompiled/x86-mingw/256.s: src/basis/main/IntInf.o src/basis/main/IntInf.sml
	@$(GENASM) x86-mingw src/basis/main/IntInf.sml precompiled/x86-mingw/256.s
precompiled/x86-mingw/257.s: src/basis/main/String.o src/basis/main/String.sml
	@$(GENASM) x86-mingw src/basis/main/String.sml precompiled/x86-mingw/257.s
precompiled/x86-mingw/258.s: src/basis/main/CharVectorSlice.o src/basis/main/CharVectorSlice.sml
	@$(GENASM) x86-mingw src/basis/main/CharVectorSlice.sml precompiled/x86-mingw/258.s
precompiled/x86-mingw/259.s: src/basis/main/CharVector.o src/basis/main/CharVector.sml
	@$(GENASM) x86-mingw src/basis/main/CharVector.sml precompiled/x86-mingw/259.s
precompiled/x86-mingw/260.s: src/basis/main/StringBase.o src/basis/main/StringBase.sml
	@$(GENASM) x86-mingw src/basis/main/StringBase.sml precompiled/x86-mingw/260.s
precompiled/x86-mingw/261.s: src/basis/main/SMLSharpRuntime.o src/basis/main/SMLSharpRuntime.sml
	@$(GENASM) x86-mingw src/basis/main/SMLSharpRuntime.sml precompiled/x86-mingw/261.s
precompiled/x86-mingw/262.s: src/basis/main/IO.o src/basis/main/IO.sml
	@$(GENASM) x86-mingw src/basis/main/IO.sml precompiled/x86-mingw/262.s
precompiled/x86-mingw/263.s: src/basis/main/Bool.o src/basis/main/Bool.sml
	@$(GENASM) x86-mingw src/basis/main/Bool.sml precompiled/x86-mingw/263.s
precompiled/x86-mingw/264.s: src/basis/main/Word8VectorSlice.o src/basis/main/Word8VectorSlice.sml
	@$(GENASM) x86-mingw src/basis/main/Word8VectorSlice.sml precompiled/x86-mingw/264.s
precompiled/x86-mingw/265.s: src/basis/main/Word8Vector.o src/basis/main/Word8Vector.sml
	@$(GENASM) x86-mingw src/basis/main/Word8Vector.sml precompiled/x86-mingw/265.s
precompiled/x86-mingw/266.s: src/basis/main/Char.o src/basis/main/Char.sml
	@$(GENASM) x86-mingw src/basis/main/Char.sml precompiled/x86-mingw/266.s
precompiled/x86-mingw/267.s: src/basis/main/SMLSharpScanChar.o src/basis/main/SMLSharpScanChar.sml
	@$(GENASM) x86-mingw src/basis/main/SMLSharpScanChar.sml precompiled/x86-mingw/267.s
precompiled/x86-mingw/268.s: src/basis/main/StringCvt.o src/basis/main/StringCvt.sml
	@$(GENASM) x86-mingw src/basis/main/StringCvt.sml precompiled/x86-mingw/268.s
precompiled/x86-mingw/269.s: src/basis/main/VectorSlice.o src/basis/main/VectorSlice.sml
	@$(GENASM) x86-mingw src/basis/main/VectorSlice.sml precompiled/x86-mingw/269.s
precompiled/x86-mingw/270.s: src/basis/main/Vector.o src/basis/main/Vector.sml
	@$(GENASM) x86-mingw src/basis/main/Vector.sml precompiled/x86-mingw/270.s
precompiled/x86-mingw/271.s: src/basis/main/Array.o src/basis/main/Array.sml
	@$(GENASM) x86-mingw src/basis/main/Array.sml precompiled/x86-mingw/271.s
precompiled/x86-mingw/272.s: src/basis/main/List.o src/basis/main/List.sml
	@$(GENASM) x86-mingw src/basis/main/List.sml precompiled/x86-mingw/272.s
precompiled/x86-mingw/273.s: src/basis/main/Option.o src/basis/main/Option.sml
	@$(GENASM) x86-mingw src/basis/main/Option.sml precompiled/x86-mingw/273.s
precompiled/x86-mingw/274.s: src/basis/main/General.o src/basis/main/General.sml
	@$(GENASM) x86-mingw src/basis/main/General.sml precompiled/x86-mingw/274.s
precompiled/x86-mingw.tar.xz:  precompiled/x86-mingw/000.s precompiled/x86-mingw/001.s precompiled/x86-mingw/002.s precompiled/x86-mingw/003.s precompiled/x86-mingw/004.s precompiled/x86-mingw/005.s precompiled/x86-mingw/006.s precompiled/x86-mingw/007.s precompiled/x86-mingw/008.s precompiled/x86-mingw/009.s precompiled/x86-mingw/010.s precompiled/x86-mingw/011.s precompiled/x86-mingw/012.s precompiled/x86-mingw/013.s precompiled/x86-mingw/014.s precompiled/x86-mingw/015.s precompiled/x86-mingw/016.s precompiled/x86-mingw/017.s precompiled/x86-mingw/018.s precompiled/x86-mingw/019.s precompiled/x86-mingw/020.s precompiled/x86-mingw/021.s precompiled/x86-mingw/022.s precompiled/x86-mingw/023.s precompiled/x86-mingw/024.s precompiled/x86-mingw/025.s precompiled/x86-mingw/026.s precompiled/x86-mingw/027.s precompiled/x86-mingw/028.s precompiled/x86-mingw/029.s precompiled/x86-mingw/030.s precompiled/x86-mingw/031.s precompiled/x86-mingw/032.s precompiled/x86-mingw/033.s precompiled/x86-mingw/034.s precompiled/x86-mingw/035.s precompiled/x86-mingw/036.s precompiled/x86-mingw/037.s precompiled/x86-mingw/038.s precompiled/x86-mingw/039.s precompiled/x86-mingw/040.s precompiled/x86-mingw/041.s precompiled/x86-mingw/042.s precompiled/x86-mingw/043.s precompiled/x86-mingw/044.s precompiled/x86-mingw/045.s precompiled/x86-mingw/046.s precompiled/x86-mingw/047.s precompiled/x86-mingw/048.s precompiled/x86-mingw/049.s precompiled/x86-mingw/050.s precompiled/x86-mingw/051.s precompiled/x86-mingw/052.s precompiled/x86-mingw/053.s precompiled/x86-mingw/054.s precompiled/x86-mingw/055.s precompiled/x86-mingw/056.s precompiled/x86-mingw/057.s precompiled/x86-mingw/058.s precompiled/x86-mingw/059.s precompiled/x86-mingw/060.s precompiled/x86-mingw/061.s precompiled/x86-mingw/062.s precompiled/x86-mingw/063.s precompiled/x86-mingw/064.s precompiled/x86-mingw/065.s precompiled/x86-mingw/066.s precompiled/x86-mingw/067.s precompiled/x86-mingw/068.s precompiled/x86-mingw/069.s precompiled/x86-mingw/070.s precompiled/x86-mingw/071.s precompiled/x86-mingw/072.s precompiled/x86-mingw/073.s precompiled/x86-mingw/074.s precompiled/x86-mingw/075.s precompiled/x86-mingw/076.s precompiled/x86-mingw/077.s precompiled/x86-mingw/078.s precompiled/x86-mingw/079.s precompiled/x86-mingw/080.s precompiled/x86-mingw/081.s precompiled/x86-mingw/082.s precompiled/x86-mingw/083.s precompiled/x86-mingw/084.s precompiled/x86-mingw/085.s precompiled/x86-mingw/086.s precompiled/x86-mingw/087.s precompiled/x86-mingw/088.s precompiled/x86-mingw/089.s precompiled/x86-mingw/090.s precompiled/x86-mingw/091.s precompiled/x86-mingw/092.s precompiled/x86-mingw/093.s precompiled/x86-mingw/094.s precompiled/x86-mingw/095.s precompiled/x86-mingw/096.s precompiled/x86-mingw/097.s precompiled/x86-mingw/098.s precompiled/x86-mingw/099.s precompiled/x86-mingw/100.s precompiled/x86-mingw/101.s precompiled/x86-mingw/102.s precompiled/x86-mingw/103.s precompiled/x86-mingw/104.s precompiled/x86-mingw/105.s precompiled/x86-mingw/106.s precompiled/x86-mingw/107.s precompiled/x86-mingw/108.s precompiled/x86-mingw/109.s precompiled/x86-mingw/110.s precompiled/x86-mingw/111.s precompiled/x86-mingw/112.s precompiled/x86-mingw/113.s precompiled/x86-mingw/114.s precompiled/x86-mingw/115.s precompiled/x86-mingw/116.s precompiled/x86-mingw/117.s precompiled/x86-mingw/118.s precompiled/x86-mingw/119.s precompiled/x86-mingw/120.s precompiled/x86-mingw/121.s precompiled/x86-mingw/122.s precompiled/x86-mingw/123.s precompiled/x86-mingw/124.s precompiled/x86-mingw/125.s precompiled/x86-mingw/126.s precompiled/x86-mingw/127.s precompiled/x86-mingw/128.s precompiled/x86-mingw/129.s precompiled/x86-mingw/130.s precompiled/x86-mingw/131.s precompiled/x86-mingw/132.s precompiled/x86-mingw/133.s precompiled/x86-mingw/134.s precompiled/x86-mingw/135.s precompiled/x86-mingw/136.s precompiled/x86-mingw/137.s precompiled/x86-mingw/138.s precompiled/x86-mingw/139.s precompiled/x86-mingw/140.s precompiled/x86-mingw/141.s precompiled/x86-mingw/142.s precompiled/x86-mingw/143.s precompiled/x86-mingw/144.s precompiled/x86-mingw/145.s precompiled/x86-mingw/146.s precompiled/x86-mingw/147.s precompiled/x86-mingw/148.s precompiled/x86-mingw/149.s precompiled/x86-mingw/150.s precompiled/x86-mingw/151.s precompiled/x86-mingw/152.s precompiled/x86-mingw/153.s precompiled/x86-mingw/154.s precompiled/x86-mingw/155.s precompiled/x86-mingw/156.s precompiled/x86-mingw/157.s precompiled/x86-mingw/158.s precompiled/x86-mingw/159.s precompiled/x86-mingw/160.s precompiled/x86-mingw/161.s precompiled/x86-mingw/162.s precompiled/x86-mingw/163.s precompiled/x86-mingw/164.s precompiled/x86-mingw/165.s precompiled/x86-mingw/166.s precompiled/x86-mingw/167.s precompiled/x86-mingw/168.s precompiled/x86-mingw/169.s precompiled/x86-mingw/170.s precompiled/x86-mingw/171.s precompiled/x86-mingw/172.s precompiled/x86-mingw/173.s precompiled/x86-mingw/174.s precompiled/x86-mingw/175.s precompiled/x86-mingw/176.s precompiled/x86-mingw/177.s precompiled/x86-mingw/178.s precompiled/x86-mingw/179.s precompiled/x86-mingw/180.s precompiled/x86-mingw/181.s precompiled/x86-mingw/182.s precompiled/x86-mingw/183.s precompiled/x86-mingw/184.s precompiled/x86-mingw/185.s precompiled/x86-mingw/186.s precompiled/x86-mingw/187.s precompiled/x86-mingw/188.s precompiled/x86-mingw/189.s precompiled/x86-mingw/190.s precompiled/x86-mingw/191.s precompiled/x86-mingw/192.s precompiled/x86-mingw/193.s precompiled/x86-mingw/194.s precompiled/x86-mingw/195.s precompiled/x86-mingw/196.s precompiled/x86-mingw/197.s precompiled/x86-mingw/198.s precompiled/x86-mingw/199.s precompiled/x86-mingw/200.s precompiled/x86-mingw/201.s precompiled/x86-mingw/202.s precompiled/x86-mingw/203.s precompiled/x86-mingw/204.s precompiled/x86-mingw/205.s precompiled/x86-mingw/206.s precompiled/x86-mingw/207.s precompiled/x86-mingw/208.s precompiled/x86-mingw/209.s precompiled/x86-mingw/210.s precompiled/x86-mingw/211.s precompiled/x86-mingw/212.s precompiled/x86-mingw/213.s precompiled/x86-mingw/214.s precompiled/x86-mingw/215.s precompiled/x86-mingw/216.s precompiled/x86-mingw/217.s precompiled/x86-mingw/218.s precompiled/x86-mingw/219.s precompiled/x86-mingw/220.s precompiled/x86-mingw/221.s precompiled/x86-mingw/222.s precompiled/x86-mingw/223.s precompiled/x86-mingw/224.s precompiled/x86-mingw/225.s precompiled/x86-mingw/226.s precompiled/x86-mingw/227.s precompiled/x86-mingw/228.s precompiled/x86-mingw/229.s precompiled/x86-mingw/230.s precompiled/x86-mingw/231.s precompiled/x86-mingw/232.s precompiled/x86-mingw/233.s precompiled/x86-mingw/234.s precompiled/x86-mingw/235.s precompiled/x86-mingw/236.s precompiled/x86-mingw/237.s precompiled/x86-mingw/238.s precompiled/x86-mingw/239.s precompiled/x86-mingw/240.s precompiled/x86-mingw/241.s precompiled/x86-mingw/242.s precompiled/x86-mingw/243.s precompiled/x86-mingw/244.s precompiled/x86-mingw/245.s precompiled/x86-mingw/246.s precompiled/x86-mingw/247.s precompiled/x86-mingw/248.s precompiled/x86-mingw/249.s precompiled/x86-mingw/250.s precompiled/x86-mingw/251.s precompiled/x86-mingw/252.s precompiled/x86-mingw/253.s precompiled/x86-mingw/254.s precompiled/x86-mingw/255.s precompiled/x86-mingw/256.s precompiled/x86-mingw/257.s precompiled/x86-mingw/258.s precompiled/x86-mingw/259.s precompiled/x86-mingw/260.s precompiled/x86-mingw/261.s precompiled/x86-mingw/262.s precompiled/x86-mingw/263.s precompiled/x86-mingw/264.s precompiled/x86-mingw/265.s precompiled/x86-mingw/266.s precompiled/x86-mingw/267.s precompiled/x86-mingw/268.s precompiled/x86-mingw/269.s precompiled/x86-mingw/270.s precompiled/x86-mingw/271.s precompiled/x86-mingw/272.s precompiled/x86-mingw/273.s precompiled/x86-mingw/274.s
	(cd precompiled && tar cf - x86-mingw/000.s x86-mingw/001.s x86-mingw/002.s x86-mingw/003.s x86-mingw/004.s x86-mingw/005.s x86-mingw/006.s x86-mingw/007.s x86-mingw/008.s x86-mingw/009.s x86-mingw/010.s x86-mingw/011.s x86-mingw/012.s x86-mingw/013.s x86-mingw/014.s x86-mingw/015.s x86-mingw/016.s x86-mingw/017.s x86-mingw/018.s x86-mingw/019.s x86-mingw/020.s x86-mingw/021.s x86-mingw/022.s x86-mingw/023.s x86-mingw/024.s x86-mingw/025.s x86-mingw/026.s x86-mingw/027.s x86-mingw/028.s x86-mingw/029.s x86-mingw/030.s x86-mingw/031.s x86-mingw/032.s x86-mingw/033.s x86-mingw/034.s x86-mingw/035.s x86-mingw/036.s x86-mingw/037.s x86-mingw/038.s x86-mingw/039.s x86-mingw/040.s x86-mingw/041.s x86-mingw/042.s x86-mingw/043.s x86-mingw/044.s x86-mingw/045.s x86-mingw/046.s x86-mingw/047.s x86-mingw/048.s x86-mingw/049.s x86-mingw/050.s x86-mingw/051.s x86-mingw/052.s x86-mingw/053.s x86-mingw/054.s x86-mingw/055.s x86-mingw/056.s x86-mingw/057.s x86-mingw/058.s x86-mingw/059.s x86-mingw/060.s x86-mingw/061.s x86-mingw/062.s x86-mingw/063.s x86-mingw/064.s x86-mingw/065.s x86-mingw/066.s x86-mingw/067.s x86-mingw/068.s x86-mingw/069.s x86-mingw/070.s x86-mingw/071.s x86-mingw/072.s x86-mingw/073.s x86-mingw/074.s x86-mingw/075.s x86-mingw/076.s x86-mingw/077.s x86-mingw/078.s x86-mingw/079.s x86-mingw/080.s x86-mingw/081.s x86-mingw/082.s x86-mingw/083.s x86-mingw/084.s x86-mingw/085.s x86-mingw/086.s x86-mingw/087.s x86-mingw/088.s x86-mingw/089.s x86-mingw/090.s x86-mingw/091.s x86-mingw/092.s x86-mingw/093.s x86-mingw/094.s x86-mingw/095.s x86-mingw/096.s x86-mingw/097.s x86-mingw/098.s x86-mingw/099.s x86-mingw/100.s x86-mingw/101.s x86-mingw/102.s x86-mingw/103.s x86-mingw/104.s x86-mingw/105.s x86-mingw/106.s x86-mingw/107.s x86-mingw/108.s x86-mingw/109.s x86-mingw/110.s x86-mingw/111.s x86-mingw/112.s x86-mingw/113.s x86-mingw/114.s x86-mingw/115.s x86-mingw/116.s x86-mingw/117.s x86-mingw/118.s x86-mingw/119.s x86-mingw/120.s x86-mingw/121.s x86-mingw/122.s x86-mingw/123.s x86-mingw/124.s x86-mingw/125.s x86-mingw/126.s x86-mingw/127.s x86-mingw/128.s x86-mingw/129.s x86-mingw/130.s x86-mingw/131.s x86-mingw/132.s x86-mingw/133.s x86-mingw/134.s x86-mingw/135.s x86-mingw/136.s x86-mingw/137.s x86-mingw/138.s x86-mingw/139.s x86-mingw/140.s x86-mingw/141.s x86-mingw/142.s x86-mingw/143.s x86-mingw/144.s x86-mingw/145.s x86-mingw/146.s x86-mingw/147.s x86-mingw/148.s x86-mingw/149.s x86-mingw/150.s x86-mingw/151.s x86-mingw/152.s x86-mingw/153.s x86-mingw/154.s x86-mingw/155.s x86-mingw/156.s x86-mingw/157.s x86-mingw/158.s x86-mingw/159.s x86-mingw/160.s x86-mingw/161.s x86-mingw/162.s x86-mingw/163.s x86-mingw/164.s x86-mingw/165.s x86-mingw/166.s x86-mingw/167.s x86-mingw/168.s x86-mingw/169.s x86-mingw/170.s x86-mingw/171.s x86-mingw/172.s x86-mingw/173.s x86-mingw/174.s x86-mingw/175.s x86-mingw/176.s x86-mingw/177.s x86-mingw/178.s x86-mingw/179.s x86-mingw/180.s x86-mingw/181.s x86-mingw/182.s x86-mingw/183.s x86-mingw/184.s x86-mingw/185.s x86-mingw/186.s x86-mingw/187.s x86-mingw/188.s x86-mingw/189.s x86-mingw/190.s x86-mingw/191.s x86-mingw/192.s x86-mingw/193.s x86-mingw/194.s x86-mingw/195.s x86-mingw/196.s x86-mingw/197.s x86-mingw/198.s x86-mingw/199.s x86-mingw/200.s x86-mingw/201.s x86-mingw/202.s x86-mingw/203.s x86-mingw/204.s x86-mingw/205.s x86-mingw/206.s x86-mingw/207.s x86-mingw/208.s x86-mingw/209.s x86-mingw/210.s x86-mingw/211.s x86-mingw/212.s x86-mingw/213.s x86-mingw/214.s x86-mingw/215.s x86-mingw/216.s x86-mingw/217.s x86-mingw/218.s x86-mingw/219.s x86-mingw/220.s x86-mingw/221.s x86-mingw/222.s x86-mingw/223.s x86-mingw/224.s x86-mingw/225.s x86-mingw/226.s x86-mingw/227.s x86-mingw/228.s x86-mingw/229.s x86-mingw/230.s x86-mingw/231.s x86-mingw/232.s x86-mingw/233.s x86-mingw/234.s x86-mingw/235.s x86-mingw/236.s x86-mingw/237.s x86-mingw/238.s x86-mingw/239.s x86-mingw/240.s x86-mingw/241.s x86-mingw/242.s x86-mingw/243.s x86-mingw/244.s x86-mingw/245.s x86-mingw/246.s x86-mingw/247.s x86-mingw/248.s x86-mingw/249.s x86-mingw/250.s x86-mingw/251.s x86-mingw/252.s x86-mingw/253.s x86-mingw/254.s x86-mingw/255.s x86-mingw/256.s x86-mingw/257.s x86-mingw/258.s x86-mingw/259.s x86-mingw/260.s x86-mingw/261.s x86-mingw/262.s x86-mingw/263.s x86-mingw/264.s x86-mingw/265.s x86-mingw/266.s x86-mingw/267.s x86-mingw/268.s x86-mingw/269.s x86-mingw/270.s x86-mingw/271.s x86-mingw/272.s x86-mingw/273.s x86-mingw/274.s | xz -c6) > $@
