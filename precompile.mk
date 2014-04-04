# GNU make is required.
# This file assumes that srcdir and builddir are same ".".

include ./files.mk

SMLSHARP_ENV = SMLSHARP_HEAPSIZE=128M:1G
SMLSHARP_STAGE2 = src/compiler/smlsharp
MLLEX_DEP = src/ml-lex/smllex
MLYACC_DEP = src/ml-yacc/smlyacc
SMLFORMAT_DEP = src/smlformat/smlformat
SMLSHARP_DEP = $(SMLSHARP_STAGE2)

LLVM_LINK = llvm-link
LLVM_DIS = llvm-dis
OPT = opt
XZ = xz

OBJECTS = $(MINISMLSHARP_OBJECTS:.o=.bc) \
	  src/compiler/minismlsharp.smi.bc

all: precompiled/x86.ll.xz

clean:
	-rm -f $(OBJECTS)
	-rm -f precompile.dep precompiled/x86.ll precompiled/x86.ll.xz

src/compiler/minismlsharp.smi.bc: $(MINISMLSHARP_OBJECTS:.o=.smi)
	$(SMLSHARP_ENV) $(SMLSHARP_STAGE2) -Bsrc -emit-llvm -c -o $@ src/compiler/minismlsharp.smi

.SUFFIXES: .sml .bc .ppg .ppg.sml .lex .lex.sml .grm .grm.sml .grm.sig

.sml.bc:
	$(SMLSHARP_ENV) $(SMLSHARP_STAGE2) -Bsrc -emit-llvm -c -o $@ $<
.ppg.ppg.sml:
        $(SMLFORMAT) --output=$@ $<
.lex.lex.sml:
        SMLLEX_OUTPUT=$@ $(MLLEX) $<
.grm.grm.sml:
        SMLYACC_OUTPUT=$@ $(MLYACC) $<

./precompile.dep: depend.mk precompile.mk
	sed 's/\.o:/.bc:/' depend.mk > $@

precompiled/x86_orig.bc: $(OBJECTS)
	$(LLVM_LINK) -o=$@ $(OBJECTS)

precompiled/x86.ll: precompiled/x86_orig.bc
	$(OPT) -disable-internalize -std-link-opts -internalize-public-api-list=_SMLmain -internalize -O2 -S -o $@ precompiled/x86_orig.bc

precompiled/x86.ll.xz: precompiled/x86.ll
	{ echo "; ModuleID = 'precompiled'" && \
	  sed 's,;[^"]*$$,,;s,^ *,,;s, *$$,,;/^$$/d;/^target triple =/d' precompiled/x86.ll && \
	  echo '@_SML_bprecompiled = external global i8' && \
	  echo '@_SML_rprecompiled = external global i8' && \
	  echo '@_SMLstackmap = constant [3 x i8*] [i8* @_SML_rprecompiled, i8* @_SML_bprecompiled, i8* null]'; \
	} | $(XZ) -c > $@

include ./precompile.dep
