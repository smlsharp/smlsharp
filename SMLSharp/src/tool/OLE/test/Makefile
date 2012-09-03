# These .NET tools are found at Microsoft Visual Studio install directory or
# .NET Framework
# For example:
#   C:/Program Files/Microsoft Visual Studio 8/SDK/v2.0/Bin/
#   C:/WINDOWS/Microsoft.NET/Framework/v1.0.3705/
CSC=csc.exe
REGASM=RegAsm.exe
TLBEXP=TlbExp.exe
TLBIMP=TlbImp.exe
SN=Sn.exe

OLE2SML=OLE2SML.exe
SMLSHARP2EXE=smlsharp2exe.sh

####################
# source files.

TESTER_SMLS= \
	DataTypes1Tester.sml \
	DataTypes2Tester.sml \
	DataTypes3Tester.sml \
	DataTypes4Tester.sml \


TESTEE_CSHARPS= \
	$(TESTER_SMLS:Tester.sml=Testee.cs) \


SOURCES= \
	$(TESTER_SMLS) \
	$(TESTEE_CSHARPS) \
	AssertOLEValue.sml \
	TestMain.sml \
	sources.sml \


####################
# derived files.

TESTEE_SMLS= \
	$(TESTEE_CSHARPS:.cs=.sml) \


DLLS= \
	$(TESTEE_CSHARPS:.cs=.dll) \


TLBS= \
	$(DLLS:.dll=.tlb) \


TARGET= \
	TestMain.exe \


########################################

all: $(TARGET)

#  With /codebase option, regasm prints a warning message to specify strong
# name.
# To avoid it, copy the dll to the directory where smlsharp is installed,
# or use 'sn.exe' to generate a strong name for this assembly.
install:
	- for f in $(DLLS); do $(REGASM) $$f; done;
#	- for f in $(DLLS); do $(REGASM) /codebase $$f; done;

uninstall:
	- for f in $(DLLS); do $(REGASM) /unregister $$f; done;

clean:
	- for f in $(DLLS); do $(REGASM) /unregister $$f; done;
	- rm -f $(TARGET) $(TLBS) $(DLLS) $(TESTEE_SMLS)

%.dll: %.cs
	$(CSC) /t:library $<

%.tlb: %.dll
	$(TLBEXP) $< /out:$@ ||  $(REGASM) /tlb $<

%.sml: %.tlb
	$(OLE2SML) $<

TestMain.exe: $(TLBS) $(DLLS) $(TESTEE_SMLS) $(SOURCES)
	$(SMLSHARP2EXE) -o $@ sources.sml
