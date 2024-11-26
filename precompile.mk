# GNU make is required.
# This file assumes that srcdir and builddir are same ".".
include files.mk
include config.mk

SMLSHARP_ENV = SMLSHARP_HEAPSIZE=32M:2G

override MINISMLLEX = echo '$(@F) is older than $(^F)' 1>&2; false
override MINISMLYACC = echo '$(@F) is older than $(^F)' 1>&2; false
override MINISMLFORMAT = echo '$(@F) is older than $(^F)' 1>&2; false
override MINISMLSHARP = src/compiler/smlsharp
override SMLLEX_DEP = src/ml-lex/smllex
override SMLYACC_DEP = src/ml-yacc/smlyacc
override SMLFORMAT_DEP = src/smlformat/smlformat
override SMLSHARP_DEP = $(MINISMLSHARP)

ifeq ($(ARCH),generic32)
override TRIPLE = i686-apple-darwin
else ifeq ($(ARCH),generic)
override TRIPLE = x86_64-apple-darwin
else ifdef ARCH
$(error ARCH must be either x86 or x86_64)
endif

bindir := $(shell $(LLVM7_CONFIG) --bindir)
OPT = $(bindir)/opt

MINISOURCES = \
  src/config/main/SQLConfig.sml

override OBJECTS := \
  $(MINISOURCES:.sml=_mini.o) \
  $(filter-out $(MINISOURCES:.sml=.o),$(MINISMLSHARP_OBJECTS))

override NAMEMAP := \
  $(shell perl -e ' \
    foreach (@ARGV) { \
      $$k = $$_; \
      $$k =~ s/^(.*?\/)?([^\/]+)\.[a-z]+$$/$$2/; \
      $$i = $$h{$$k}++; \
      $$k .= "-$$i" if $$i>0; \
      print "$$k.ll<$$_\n"; \
    }' \
    $(OBJECTS))

override REMOVEWEAKMAP := \
  -D<src/compiler/minismlsharp.o

override lookup = $(patsubst %<$(2),%,$(filter %<$(2),$(1)))
override values = $(foreach i,$(1),$(firstword $(subst <, ,$(i))))

override rev = \
  $(and $(1),$(call rev,$(wordlist 2,$(words $(1)),$(1))) $(word 1,$(1)))

ifndef ARCH

all: precompiled/Makefile
	$(MAKE) -f precompile.mk all ARCH=generic

.PHONY: all

precompiled/Makefile: precompile.mk files.mk
	@echo 'Generating $@' 1>&2; \
	exec > $@; \
	echo '# auto-generated. DO NOT EDIT BY HAND.'; \
	echo 'PRECOMPILED_DIR=precompiled/$$(PRECOMPILED_ARCH)'; \
	for i in $(call values,$(NAMEMAP)); do \
	  s='$$(PRECOMPILED_DIR)/'"$$i"; \
	  d="$${s%.ll}.o"; \
	  printf '%s: $$(LLVM_PLUGIN) %s\n' "$$d" "$$s"; \
	  printf '\t$$(PRECOMPILE_LLC) -o $$@ $$(srcdir)/%s\n' "$$s"; \
	done; \
	printf 'PRECOMPILED_OBJECTS ='; \
	for i in $(call rev,$(call values,$(NAMEMAP))); do \
	  printf ' \\\n$$(PRECOMPILED_DIR)/%s' "$${i%.ll}.o"; \
	done; \
	echo

else # ifdef ARCH

top:
	@echo 'type "make all" to build minismlsharp for all targets, or "make all ARCH=..." to build it for a specific target.'
	@exit 1

override TARGETS := \
  $(foreach i,$(call values,$(NAMEMAP)),precompiled/$(ARCH)/$i)

all: $(TARGETS)

clean:
	-rm -f $(OBJECTS)
	-rm -f precompile.dep precompiled/$(ARCH)_orig.bc
	-rm -f precompiled/$(ARCH)_opt.bc precompiled/$(ARCH).ll.xz

.PHONY: top all clean

.SUFFIXES: .sml .smi .sig .ll .bc .ppg .lex .grm

%.$(ARCH).ll: %.sml
	$(SMLSHARP_ENV) $(MINISMLSHARP) -Bsrc -target $(TRIPLE) \
	-ddumpLLVMEmit=$@ -emit-llvm -c -o /dev/null $<

$(MINISOURCES:.sml=_mini.sml): %_mini.sml: %.sml.in #precompile.mk
	sed '1s!^!_interface "./$(notdir $(<:.sml.in=.smi))" !;s!%[^%]*%!!g' \
	$< > $@

precompile.dep: depend.mk precompile.mk
	sed $(foreach i,$(MINISOURCES:.sml=),-e 's!$(i).sml!$(i)_mini.sml!') \
	    $(foreach i,$(MINISOURCES:.sml=),-e 's!$(i).o!$(i)_mini.o!') \
	    -e 's/\.o:/.$$(ARCH).ll:/' \
	    -e 's/^	/&@/' \
	    depend.mk > $@

src/llvm/main/anonymize: src/llvm/main/anonymize.cpp
	$(CXX) -o $@ src/llvm/main/anonymize.cpp \
	$(shell $(LLVM7_CONFIG) --cxxflags --ldflags --libs --system-libs)

src/llvm/main/removeweak: src/llvm/main/removeweak.cpp
	$(CXX) -o $@ src/llvm/main/removeweak.cpp \
	$(shell $(LLVM7_CONFIG) --cxxflags --ldflags --libs --system-libs)

override define Rule
$(patsubst %.o,%.$(ARCH).opt.ll,$1): \
  $(patsubst %.o,%.$(ARCH).ll,$1) \
  src/llvm/main/removeweak
	src/llvm/main/removeweak $(call lookup,$(REMOVEWEAKMAP),$1) < $$< \
	| $$(OPT) -Oz -S -o $$@
precompiled/$(ARCH)/$(call lookup,$(NAMEMAP),$1): \
  $(patsubst %.o,%.$(ARCH).opt.ll,$1) \
  src/llvm/main/anonymize
	src/llvm/main/anonymize < $$< \
	| perl -ne \
          '$$$$_="" if /^target +triple *=/; \
	   $$$$_="" if /^source_filename *=/; \
	   $$$$_="" if /(call|declare) void @llvm\.lifetime\.(start|end)/; \
	   s/(".*?")|;.*$$$$| *(["#*=,()<>{}\[\]@%]) *|(\d) +(?=x )/$$$$+/eg; \
	   s/^ +//;s/ +$$$$//;print if /\S/' \
	> $$@
endef
$(foreach i,$(OBJECTS),$(eval $(call Rule,$i)))

include precompile.dep

endif  # ifdef ARCH
