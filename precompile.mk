# GNU make is required.
# This file assumes that srcdir and builddir are same ".".

include ./files.mk

SMLSHARP_ENV = SMLSHARP_HEAPSIZE=512M:2G

MLYACC = src/ml-yacc/smlyacc
MLLEX = src/ml-lex/smllex
SMLFORMAT = src/smlformat/smlformat
SMLSHARP_STAGE2 = src/compiler/smlsharp
MLLEX_DEP = $(MLLEX)
MLYACC_DEP = $(MLYACC)
SMLFORMAT_DEP = $(SMLFORMAT)
SMLSHARP_DEP = $(SMLSHARP_STAGE2)

LLVM_LINK = llvm-link
LLVM_DIS = llvm-dis
OPT = opt
XZ = xz

ifeq ($(ARCH),x86)
TRIPLE = i686-apple-darwin
else ifeq ($(ARCH),x86_64)
TRIPLE = x86_64-apple-darwin
else ifdef ARCH
$(error ARCH must be either x86 or x86_64)
endif

OBJECTS = $(MINISMLSHARP_OBJECTS:.o=.$(ARCH).bc)

top:
	@echo 'type "make all" to build minismlsharp for all targets, or "make all ARCH=..." to build it for a specific target.'
	@exit 1

ifndef ARCH

all:
	$(MAKE) -f precompile.mk all ARCH=x86
	$(MAKE) -f precompile.mk all ARCH=x86_64

else   # ifdef ARCH

all: precompiled/$(ARCH).ll.xz

clean:
	-rm -f $(OBJECTS)
	-rm -f precompile.dep precompiled/$(ARCH)_orig.bc
	-rm -f precompiled/$(ARCH)_opt.bc precompiled/$(ARCH).ll.xz

.SUFFIXES: .sml .$(ARCH).bc .ppg .ppg.sml .lex .lex.sml .grm .grm.sml .grm.sig

%.$(ARCH).bc: %.sml
	$(SMLSHARP_ENV) $(SMLSHARP_STAGE2) -Bsrc --target=$(TRIPLE) -emit-llvm -c -o $@ $<
.ppg.ppg.sml:
	$(SMLSHARP_ENV) $(SMLFORMAT) --output=$@ $<
.lex.lex.sml:
	$(SMLSHARP_ENV) SMLLEX_OUTPUT=$@ $(MLLEX) $<
.grm.grm.sml:
	$(SMLSHARP_ENV) SMLYACC_OUTPUT=$@ $(MLYACC) $<

./precompile.dep: depend.mk precompile.mk
	sed 's/\.o:/.$$(ARCH).bc:/' depend.mk > $@

precompiled/$(ARCH)_orig.bc: $(OBJECTS)
	$(LLVM_LINK) -o $@ $(OBJECTS)

precompiled/$(ARCH)_opt.bc: precompiled/$(ARCH)_orig.bc
	$(OPT) -std-link-opts -internalize -Oz -o $@ precompiled/$(ARCH)_orig.bc

precompiled/$(ARCH).ll.xz: precompiled/$(ARCH)_opt.bc
	$(LLVM_DIS) -o - precompiled/$(ARCH)_opt.bc \
	| (echo "@_SML_ftab = external constant i8"; \
	   sed -e 's,^@_SML_ftab = .*,@_SML_xftab = internal constant i16 0,' \
	   -e '1,/@_SML_ftab/!s,@_SML_ftab,bitcast (i16* @_SML_xftab to i8*),' \
	   -e 's,;[^"]*$$,,;s,^ *,,;s, *$$,,;/^$$/d;/^target triple =/d') \
	| $(XZ) -c > $@

include ./precompile.dep

endif  # ifdef ARCH
