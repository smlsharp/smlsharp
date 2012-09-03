FASTBUILD_FUNCS = \
  check () { \
    echo "checking for fast build on $$1 ..." 1>&2; \
    $(SMLSHARP) -Bsrc -nostdpath -fprint-main-ids "$$1" \
    | sed 's/\.smi$$/.sml/' > fastbuild1.tmp; \
    $(SMLSHARP) -Bsrc --sha1 `cut -d\  -f2 fastbuild1.tmp` \
    | awk 'BEGIN{while((getline < "fastbuild1.tmp"))h[$$2]=$$1} \
           {printf "%s:%s %s\n",h[$$2],$$1,$$2}' \
    > fastbuild2.tmp; \
    trap "rm -f fastbuild1.tmp fastbuild2.tmp" EXIT; \
  }; \
  compile () { \
    asm="$$1"; \
    sum="$$2"; \
    sml="$$3"; \
    smi=`echo "$$sml" | sed 's,\.sml$$,.smi,'`; \
    obj=`echo "$$sml" | sed 's,\.sml$$,.o,'`; \
    test -f "$$obj" && return; \
    test "x$$sum" = "x`grep "$$sml" fastbuild2.tmp | cut -d\  -f1`" || return; \
    echo $(CC) -c -o "$$obj" "precompiled/$(NATIVE_TARGET)/$$asm"; \
    $(CC) -c -o "$$obj" "precompiled/$(NATIVE_TARGET)/$$asm"; \
    return; \
  }

# reproduce text to normalize line break characters.
# this is an workaround for mingw.
NORMALIZE_CRLF = \
  normalize () { \
    tmp=fastbuild3.tmp; \
    for i; do sed -n p "$$i" > "$$tmp" && cp "$$tmp" "$$i"; done; \
    rm -f "$$tmp"; \
  }; normalize

fast-all: $(SMLSHARP_DEP)
	$(FASTBUILD_FUNCS); . precompiled/fastbuild1
	$(MAKE) src/smlformat/generator/main/ml.grm.sml \
	        src/smlformat/generator/main/ml.lex.sml
	case '$(host_os)' in *mingw*) \
	  $(NORMALIZE_CRLF) \
	    src/smlformat/generator/main/ml.grm.sml \
	    src/smlformat/generator/main/ml.lex.sml;; esac
	$(FASTBUILD_FUNCS); . precompiled/fastbuild2
	$(MAKE) sources
	case '$(host_os)' in *mingw*) \
	  $(NORMALIZE_CRLF) \
	    `for i in $(GEN_SOURCES); do \
	       case "$$i" in src/smlformat/*) ;; *) echo "$$i";; esac; \
	     done`;; esac
	$(FASTBUILD_FUNCS); . precompiled/fastbuild3
	-awk 'BEGIN{print "/^include.*fastbuild.mk$$/s/^/\043/\nw\nq"}' | ed Makefile > /dev/null
	$(MAKE) all
