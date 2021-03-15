# GNU make is required.
# This file assumes that srcdir and builddir are same ".".
include ./files.mk
include ./src/config.mk

SMLSHARP_ENV = SMLSHARP_HEAPSIZE=32M:2G

MINISMLLEX = echo '$(@F) is older than $(^F)' 1>&2; false
MINISMLYACC = echo '$(@F) is older than $(^F)' 1>&2; false
MINISMLFORMAT = echo '$(@F) is older than $(^F)' 1>&2; false
MINISMLSHARP = src/compiler/smlsharp
SMLLEX_DEP = src/ml-lex/smllex
SMLYACC_DEP = src/ml-yacc/smlyacc
SMLFORMAT_DEP = src/smlformat/smlformat
SMLSHARP_DEP = $(MINISMLSHARP)

LLVM_CONFIG = $(patsubst %/llvm-dis,%/llvm-config,$(LLVM_DIS))
LLVM_LINK = $(patsubst %/llvm-dis,%/llvm-link,$(LLVM_DIS))
XZ = xz

ifeq ($(ARCH),x86)
TRIPLE = i686-apple-darwin
else ifeq ($(ARCH),x86_64)
TRIPLE = x86_64-apple-darwin
else ifdef ARCH
$(error ARCH must be either x86 or x86_64)
endif

MINISOURCES = \
 src/config/main/SQLConfig.sml
OBJECTS = \
 $(patsubst %.o,%.$(ARCH).bc,\
   $(MINISOURCES:.sml=_mini.o) \
   $(filter-out $(MINISOURCES:.sml=.o),$(MINISMLSHARP_OBJECTS)))

top:
	@echo 'type "make all" to build minismlsharp for all targets, or "make all ARCH=..." to build it for a specific target.'
	@exit 1

ifndef ARCH

all:
	$(MAKE) -f precompile.mk all ARCH=x86_64

else   # ifdef ARCH

all: precompiled/$(ARCH).ll.xz

clean:
	-rm -f $(OBJECTS)
	-rm -f precompile.dep precompiled/$(ARCH)_orig.bc
	-rm -f precompiled/$(ARCH)_opt.bc precompiled/$(ARCH).ll.xz

.SUFFIXES: .sml .smi .sig .bc .ppg .lex .grm

%.$(ARCH).bc: %.sml
	$(SMLSHARP_ENV) $(MINISMLSHARP) -Bsrc -target $(TRIPLE) -emit-llvm -c -o $@ $<

$(MINISOURCES:.sml=_mini.sml): %_mini.sml: %.sml.in precompile.mk
	sed '1s!^!_interface "./$(notdir $(<:.sml.in=.smi))" !;s!%[^%]*%!!g' \
	$< > $@

./precompile.dep: depend.mk precompile.mk
	sed $(foreach i,$(MINISOURCES:.sml=),-e 's!$(i).sml!$(i)_mini.sml!') \
	    $(foreach i,$(MINISOURCES:.sml=),-e 's!$(i).o!$(i)_mini.o!') \
	    -e 's/\.o:/.$$(ARCH).bc:/' -e 's/^	/&@/' \
	    depend.mk > $@

src/llvm/main/anonymize: src/llvm/main/anonymize.cpp
	$(CXX) -o $@ src/llvm/main/anonymize.cpp $(shell $(LLVM_CONFIG) --cxxflags --ldflags --libs --system-libs)

rev = $(and $(1),$(call rev,$(wordlist 2,$(words $(1)),$(1))) $(word 1,$(1)))

precompiled/$(ARCH)_orig.bc: $(OBJECTS)
	$(LLVM_LINK) -o $@ $(call rev,$(OBJECTS))

precompiled/$(ARCH)_opt.ll: precompiled/$(ARCH)_opt.bc
	$(LLVM_DIS) $<

precompiled/$(ARCH)_orig.ll: precompiled/$(ARCH)_orig.bc
	$(LLVM_DIS) precompiled/$(ARCH)_orig.bc

precompiled/$(ARCH)_opt.bc: precompiled/$(ARCH)_orig.bc
	$(LLVM_DIS) < precompiled/$(ARCH)_orig.bc \
	| sed -e '/call void @sml_gcroot(/{;/_minismlsharp/!{;s/@_SML_[tf][^,]*/null/g;};}' \
	      -e '/call void @sml_gcroot([^,]*,[^,]*, i8\* null, i8\* null)/d' \
	      -e 's/^define weak/define/' \
	| $(OPT) -std-link-opts -internalize -Oz \
	         -internalize-public-api-list=sml_main,sml_load \
	         -o $@

precompiled/$(ARCH).ll.xz: src/llvm/main/anonymize precompiled/$(ARCH)_opt.bc
	src/llvm/main/anonymize < precompiled/$(ARCH)_opt.bc \
	| sed -E \
	  -e '/^target +triple *=/d' \
	  -e '/^source_filename *=/d' \
	  -e '/^ *(tail )?call void @llvm\.lifetime\.(start|end)/d' \
	  -e '/^declare void @llvm\.lifetime\.(start|end)/d' \
	  -e 's/(^ *(tail )?call void @llvm\.mem(set|cpy|move)[.pi0-9]*)\(([^,]+align ([0-9]+)[^,]*,[^,]+,[^,]+),([^,]+)\)/\1(\4,i32 \5,\6)/' \
	  -e 's/(^ *(tail )?call void @llvm\.mem(set|cpy|move)[.pi0-9]*)\(([^,]+,[^,]+,[^,]+),([^,]+)\)/\1(\4,i32 1,\5)/' \
	  -e 's/(^declare void @llvm\.mem(set|cpy|move)[.pi0-9]*)\(([^,]+,[^,]+,[^,]+),([^,]+)\)/\1(\3,i32,\4)/' \
	| perl \
	  -ne 's/(".*?")|;.*$$| *(["#*=,()<>{}\[\]@%]) *|(\d) +(?=x )/$$+/eg; \
	       s/^ +//;s/ +$$//;print if /\S/' \
	| $(XZ) -e -c > $@
# Workaround for LLVM 6 or prior: from LLVM 7, the signature of memset,
# memcpy, and memmove intrinsics has been changed.  LLVM 7-11 seems
# to accept old signatures and convert it into new ones.  This sed script
# reverts this conversion.

include ./precompile.dep

endif  # ifdef ARCH
