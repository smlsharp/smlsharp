VERSION=0.20
EXEEXT=.exe
OUTPUTDIR=Output
SETUPFILE=smlsharp-setup.$(VERSION)$(EXEEXT)
ISCC=iscc.exe

TARGETS=$(OUTPUTDIR)/$(SETUPFILE)

all: $(TARGETS)

clean:
	-rm -rf $(TARGETS)

$(OUTPUTDIR)/$(SETUPFILE): smlsharp.iss
	$(ISCC) /Q /O"$(OUTPUTDIR)" /F"$(SETUPFILE:$(EXEEXT)=)" $<
