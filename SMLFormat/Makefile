# Makefile for SMLFormat
# $Id: Makefile,v 1.5 2006/02/07 12:49:32 kiyoshiy Exp $

# This Makefile instructs make to the following tasks.
# * compile smlformat and generate a heap image file.
# * generate a wrapper script which invokes smlformat.

# Usage:
# $ make
# or, you can specify command name of SML/NJ compiler to be used.
# $ SML=sml make


MAINDIR=generator/main/
BINDIR=$(PWD)/bin
BATFILE=$(BINDIR)/smlformat
HEAPFILE=$(BINDIR)/smlformat-heap

all:
	echo "#!/bin/sh" > $(BATFILE)
	echo "case `uname` in " >> $(BATFILE)
	echo "CYGWIN*) " >> $(BATFILE)
	echo "	HEAPIMAGE_SUFFIX=.x86-win32 " >> $(BATFILE)
	echo "        SML=sml.bat " >> $(BATFILE)
	echo "	;; " >> $(BATFILE)
	echo "*) " >> $(BATFILE)
	echo "	HEAPIMAGE_SUFFIX= " >> $(BATFILE)
	echo "        SML=sml " >> $(BATFILE)
	echo "esac " >> $(BATFILE)
	echo "HEAPIMAGE=$(HEAPFILE)\$${HEAPIMAGE_SUFFIX} " >> $(BATFILE)
	echo "\$${SML} @SMLload=\$${HEAPIMAGE} \$$* " >> $(BATFILE)
	chmod a+x $(BATFILE)
	(cd $(MAINDIR) && \
	if test -z "${SML}"; \
	then \
		case `uname` in \
		CYGWIN*) SML=sml-cm.bat ;;\
		*) SML=sml-cm ;; \
		esac \
	fi; \
	case `uname` in \
	CYGWIN*) MAINFUN="fn (p1, _::ps) => Main.main (p1, ps)" ;; \
	*) MAINFUN=Main.main ;;\
	esac; \
	if echo 'CM.make;' | $$SML | grep 'string ->' > /dev/null; then \
		CM_MAKE_ARG='"sources.cm"'; \
	else \
		CM_MAKE_ARG='()'; \
	fi; \
	echo "CM.make $${CM_MAKE_ARG};" \
	     "SMLofNJ.exportFn(\"$(HEAPFILE)\", $${MAINFUN})" \
	| $${SML})
