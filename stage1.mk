# GNU make is required.
# This file assumes that srcdir and builddir are same ".".

include stage1_1.dep

./stage1: $(STAGE1_OBJECTS) $(COMPILER_SUPPORT_OBJECTS) stage1_filemap
	$(SMLSHARP_STAGE0) -filemap=stage1_filemap \
	  $(LLVM_SMLSHARP_LDFLAGS) \
	  $(srcdir)/src/compiler/minismlsharp.smi \
	  $(COMPILER_SUPPORT_OBJECTS) \
	  $(LLVM_LIBS) \
	  -o $@

.SUFFIXES: .s0.o .s0.dep

%.s0.dep: %.sml
	$(SMLSHARP_ENV) $(SMLSHARP_STAGE0) -MM $< > $@
	@tmp=`cat $@`; echo "$$tmp" | sed 's/\.o:/.s0.o:/' > $@
%.s0.o: %.sml
	$(SMLSHARP_ENV) $(SMLSHARP_STAGE0) -c -o $@ $<

stage1_filemap: src/compiler/minismlsharp.smi stage1.mk
	set -e; \
	rm -f $@; \
	tmp=`$(SMLSHARP_STAGE0) -MMl src/compiler/minismlsharp.smi`; \
	st=$$?; test "$$st" = "0" || exit $$?; \
	echo "$$tmp" \
	| awk '{sub(" *\\\\$$","");sub("^ *","");gsub("  *","\n");print}' \
	| sed '1d;$$d;s/.o$$//' \
	| awk '{a[NR]=$$0}END{for(i=NR;i>0;i--)print a[i]}' \
	| sed -n -e '/ppg$$/{s/^.*$$/&.smi &.s0.s0.o/;p;d;}' \
	         -e '/grm$$/{s/^.*$$/&.smi &.s0.s0.o/;p;d;}' \
	         -e '/lex$$/{s/^.*$$/&.smi &.s0.s0.o/;p;d;}' \
	         -e 's/^.*$$/&.smi &.s0.o/;p' \
	> $@

stage1_1.dep: stage1_filemap
	rm -f $@
	objs=`sed 's/^.* \(.*\)$$/\1/' stage1_filemap`; \
	echo "STAGE1_OBJECTS = $$objs" | sed '$$q;s/$$/ \\/' >> $@
	gensrcs=`egrep '(ppg|grm|lex).smi ' stage1_filemap | sed 's/^.* \(.*\).s0.o$$/\1.sml/'`; \
	echo "STAGE1_GENSRCS = $$gensrcs" | sed '$$q;s/$$/ \\/' >> $@
	sed -e 's/^\(.*\) \(.*\)\.s0\.o$$/\2.s0.dep: \1 \2.sml stage1_1.dep/' stage1_filemap >> $@
	egrep '(ppg|grm|lex).smi ' stage1_filemap \
	| sed 's/^\(.*\).smi \(.*\).s0.o$$/\1 \2/' \
	| while read src obj; do \
	    echo "$$obj.sml: $$src"; \
	    case "$$src" in \
	      *.ppg) echo '	$$(SMLFORMAT_STAGE0) --output=$$@ '"$$src";; \
	      *.grm) echo '	SMLYACC_OUTPUT=$$@ $$(SMLYACC_STAGE0) '"$$src" >> $@;; \
	      *.lex) echo '	SMLLEX_OUTPUT=$$@ $$(SMLLEX_STAGE0) '"$$src" >> $@;; \
	    esac; \
	    echo '	{ echo 0i; echo _interface \"'`basename $$src.smi`'\"; echo .; echo w; } | ed $$@'; \
	  done >> $@
	echo "include stage1_2.dep" >> $@

stage1_2.dep: stage1_1.dep $(STAGE1_OBJECTS:.o=.dep)
	@echo generating $@ ...
	@cat $(STAGE1_OBJECTS:.o=.dep) > $@
