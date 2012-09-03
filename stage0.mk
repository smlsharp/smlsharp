GEN_CM = \
    gencm () { \
      echo "$$1" \
      | awk '{gsub(" ","\n");print}' \
      | sed '\,^src/basis/,d;\,^src/smlnj/,d;s,^src/,../src/,' \
      | awk 'BEGIN{print "Group is";\
             print "\043if defined(SMLNJ_VERSION)";\
             print "$$/basis.cm";\
             print "\043endif"}\
             NR==1{s="\043if defined(SMLNJ_VERSION)\n\043else\n"\
                     $$0"\n\043endif\n";next}\
             {s=$$0"\n"s}\
             END{print s}'; \
    }; gencm

MAKESML_SMLNJ = \
    makesml () { \
      heap="$$1_h.$(SMLNJ_HEAP_SUFFIX)"; \
      rm -f "$heap"; \
      { echo "structure SMLofNJ_ = SMLofNJ;"; \
        echo "CM.make \"$$1.cm\";"; \
        echo "SMLofNJ_.exportFn (\"$$1_h\", $$2)"; \
      } | $(SMLNJ) || exit $$?; \
      heap="$$1_h.$(SMLNJ_HEAP_SUFFIX)"; \
      test -f "$$heap" || exit $$?; \
      case '$(SMLNJ_HEAP_SUFFIX)' in \
      *win32*) \
        sml=`echo '$(SMLNJ)' | sed 's,^cmd /c "\(.*\)"$$,\1,'`; \
        awk 'BEGIN{ \
             print"\043!/bin/sh";\
             print"cmd /c '"'$$sml @SMLload=$$heap '"'\"$$*\""}' > "$$1"; \
        ;; \
      *cygwin*) \
        awk 'BEGIN{ \
             print"\043!/bin/sh";\
             print"SMLNJ_CYGWIN_RUNTIME=1";\
             print"export SMLNJ_CYGWIN_RUNTIME";\
             print"$(SMLNJ) @SMLload='"$$heap"' \"$$@\""}' > "$$1"; \
        chmod +x "$$1"; \
        ;; \
      *) \
        awk 'BEGIN{ \
             print"\043!/bin/sh";\
             print"$(SMLNJ) @SMLload='"$$heap"' \"$$@\""}' > "$$1"; \
        chmod +x "$$1"; \
        ;; \
      esac; \
    }; makesml

MAKESML_MLTON = \
    makesml () { '$(MLTON)' -verbose 2 -output "$$1" "$$1.cm"; }; makesml

MAKESML = false

stage0/smllex.cm: stage0.mk files.mk
	$(GEN_CM) '$(MLLEX_SOURCES)' > $@
stage0/smlyacc.cm: stage0.mk files.mk
	$(GEN_CM) '$(MLYACC_SOURCES)' > $@
stage0/smlformat.cm: stage0.mk files.mk
	$(GEN_CM) '$(SMLFORMAT_SOURCES)' > $@
stage0/smlsharp.cm: stage0.mk files.mk
	$(GEN_CM) '$(MINISMLSHARP_SOURCES)' \
	| awk '/src\/sql/{next}\
	       /src\/ffi/{next}\
	       {sub("RunLoop\\.sml$$","RunLoop_dummy.sml");\
	        sub("ExecutablePath\\.sml$$","ExecutablePath_dummy.sml");\
	        print}\
	       /basis.cm$$/{\
	         print"../src/compiler/compat/main/Real32_compat.sml";\
	         print"../src/compiler/compat/main/IEEEReal_compat.sml"}'\
	> $@

stage0/smllex: stage0/smllex.cm $(MLLEX_SOURCES)
	$(MAKESML) stage0/smllex ExportLexGen.lexGen
stage0/smlyacc: stage0/smlyacc.cm $(MLYACC_SOURCES)
	$(MAKESML) stage0/smlyacc ExportParseGen.parseGen
stage0/smlformat: stage0/smlformat.cm $(SMLFORMAT_SOURCES)
	$(MAKESML) stage0/smlformat Main.main
stage0/smlsharp: stage0/smlsharp.cm $(MINISMLSHARP_SOURCES)
	$(MAKESML) stage0/smlsharp Main.main

stage0: PHONY
	-mkdir stage0
	$(MAKE) \
	MAKESML='$$(MAKESML_$(STAGE0_COMPILER))' \
	MLLEX=stage0/smllex \
	MLYACC=stage0/smlyacc \
	SMLFORMAT=stage0/smlformat \
	stage0/smlsharp
	@echo
	@echo "***"
	@echo "*** Building stage 0 compiler is completed. Do \`make'."
	@echo "***"
