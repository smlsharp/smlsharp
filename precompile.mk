# GNU make is required.
# This file assumes that srcdir and builddir are same ".".

include ./files.mk

SMLSHARP_ENV = SMLSHARP_HEAPSIZE=128M:1G
SMLSHARP = src/compiler/smlsharp
SMLSHARP_DEP =

all: precompiled/x86-darwin.tar.xz \
     precompiled/x86-linux.tar.xz \
     precompiled/x86-mingw.tar.xz

OBJECTS = $(MLYACC_OBJECTS) \
          $(SMLFORMAT_OBJECTS) \
          $(MINISMLSHARP_OBJECTS) \
	  src/compiler/minismlsharp.smi.o
SMIFILES = $(patsubst %.o,%.smi,$(patsubst %.smi.o,%.smi,$(OBJECTS)))
SMLFILES = $(patsubst %.o,%.sml,$(patsubst %.smi.o,%.smi,$(OBJECTS)))

precompiled/ids: $(SMIFILES) precompile.mk
	$(SMLSHARP) -Bsrc -nostdpath -fprint-main-ids \
	  src/ml-yacc/src/ml-yacc.smi \
	  src/smlformat/generator/main/call-main.smi \
	  src/compiler/minismlsharp.smi \
	| sed 's,\.smi$$,.sml,' > $@

precompiled/sums: $(SMLFILES) precompile.mk
	$(SMLSHARP) --sha1 $(SMLFILES) > $@

precompiled/files: precompiled/map precompiled/ids precompiled/sums \
	           precompile.mk
	awk 'BEGIN{while((getline < "precompiled/ids"))id[$$2]=$$1; \
	           while((getline < "precompiled/sums"))sum[$$2]=$$1} \
	     /\.smi\.o$$/{next} \
	     {sub("\\.o$$",".sml",$$2); \
	      printf "compile %s %s:%s %s\n",$$1,id[$$2],sum[$$2],$$2}' \
	  precompiled/map > $@

precompiled/minismlsharp-files: files.mk precompiled/map
	for i in src/compiler/minismlsharp.smi.o $(MINISMLSHARP_OBJECTS); do \
	  fgrep " $$i" precompiled/map; \
	done | cut -d\  -f1 > $@

precompiled/fastbuild1: files.mk precompiled/files
	{ echo 'check src/ml-yacc/src/ml-yacc.smi'; \
	  for i in $(MLYACC_OBJECTS:.o=.sml); do \
	    fgrep " $$i" precompiled/files; \
	  done; } > $@

precompiled/fastbuild2: files.mk precompiled/files
	{ echo 'check src/smlformat/generator/main/call-main.smi'; \
	  for i in $(SMLFORMAT_OBJECTS:.o=.sml); do \
	    fgrep " $$i" precompiled/files; \
	  done; } > $@

precompiled/fastbuild3: files.mk precompiled/files
	{ echo 'check src/compiler/minismlsharp.smi'; \
	  for i in $(MINISMLSHARP_OBJECTS:.o=.sml); do \
	    fgrep " $$i" precompiled/files; \
	  done; } > $@

src/compiler/minismlsharp.smi.x86-darwin.s: $(MINISMLSHARP_OBJECTS:.o=.smi)
	$(SMLSHARP_ENV) $(SMLSHARP) -Bsrc -nostdpath -dtarget=x86-darwin -S -o $@ src/compiler/minismlsharp.smi
src/compiler/minismlsharp.smi.x86-linux.s: $(MINISMLSHARP_OBJECTS:.o=.smi)
	$(SMLSHARP_ENV) $(SMLSHARP) -Bsrc -nostdpath -dtarget=x86-linux -S -o $@ src/compiler/minismlsharp.smi
src/compiler/minismlsharp.smi.x86-mingw.s: $(MINISMLSHARP_OBJECTS:.o=.smi)
	$(SMLSHARP_ENV) $(SMLSHARP) -Bsrc -nostdpath -dtarget=x86-mingw -S -o $@ src/compiler/minismlsharp.smi

%.x86-darwin.s: %.sml
	$(SMLSHARP_ENV) $(SMLSHARP) -Bsrc -nostdpath -dtarget=x86-darwin -S -o $@ $<
%.x86-linux.s: %.sml
	$(SMLSHARP_ENV) $(SMLSHARP) -Bsrc -nostdpath -dtarget=x86-linux -S -o $@ $<
%.x86-mingw.s: %.sml
	$(SMLSHARP_ENV) $(SMLSHARP) -Bsrc -nostdpath -dtarget=x86-mingw -S -o $@ $<

COMPACTASM = \
  compact () { \
    [ -d `dirname "$$2"` ] || mkdir -p `dirname "$$2"`; \
    awk '/^[A-Z0-9_]*:[ \t]/{print $$1;next}{sub("[ \t]*$$","");print}' \
      "$$1" > "$$2"; \
  }; compact

MOD_TAR = \
  perl -e ' \
    binmode(STDIN); \
    while (read(STDIN,$$_,512)) { \
      my $$fmt = 'a100a8a8a8a12a12a8a1a100a6a2a32a32a8a8a155a12'; \
      my @h = unpack($$fmt); \
      unless (~/^\0*$$/) { \
        $$h[2] = $$h[3] = "0" x 7; \
        $$h[11] = $$h[12] = "root"; \
        $$h[5] = "11677621560"; \
        $$h[6] = " " x 8; \
        my $$n = 0; \
        foreach my $$i (unpack("C*",pack($$fmt,@h))) { $$n += $$i; }; \
        $$h[6] = sprintf("0%o\0", $$sum); \
      }; \
      read(STDIN,$$_,(oct($$h[4]) + 511) / 512 * 512); \
      print(pack($$fmt,@h) . $$_); \
    }'

precompiled/map: files.mk precompile.mk
	c=001; \
	inc () { echo 00`expr $$1 + 1` | sed 's,.*\(...\)$$,\1,'; }; \
	echo $(OBJECTS) | awk '{gsub(" ","\n");print}' | sort | uniq \
	| while read i; do \
	    echo "$$c.s $$i"; \
	    c=`inc $$c`; \
	  done > $@

precompile.dep: precompiled/map depend.mk precompile.mk
	for t in x86-darwin x86-linux x86-mingw; do \
	  { \
	    sed "/MLLEX_DEP/d;/MLYACC_DEP/d;/SMLFORMAT_DEP/d;s/\.o:/.$$t.s:/" \
	      depend.mk; \
	    files=; \
	    while read i; do \
	      set -- $$i; \
	      asm=`echo $$2 | sed "s,\\.o\$$,.$$t.s,"`; \
	      echo "precompiled/$$t/$$1: $$asm precompiled/map"; \
	      echo "	\$$(COMPACTASM) $$asm \$$@"; \
	      files="$$files precompiled/$$t/$$1"; \
	    done; \
	    echo "precompiled/$$t.tar.xz: precompiled/minismlsharp-files precompiled/fastbuild1 precompiled/fastbuild2 precompiled/fastbuild3 $$files"; \
	    echo "	(cd precompiled && tar -cf - `echo $$files | sed s,precompiled/,,g` minismlsharp-files fastbuild1 fastbuild2 fastbuild3) | \$$(MOD_TAR) | xz -c > \$$@"; \
	  } < precompiled/map; \
	done > $@

include ./precompile.dep
