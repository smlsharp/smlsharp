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

TARGET= \
	HelloDotNETWorld.dll \
	HelloDotNETWorld.tlb \
	HelloDotNETWorld.sml \
	UseHelloDotNETWorld.exe \


all: $(TARGET)

#  With /codebase option, regasm prints a warning message to specify strong
# name.
# To avoid it, copy the dll to the directory where smlsharp is installed,
# or use 'sn.exe' to generate a strong name for this assembly.
install:
	$(REGASM) HelloDotNETWorld.dll
#	$(REGASM) /codebase HelloDotNETWorld.dll

uninstall:
	- $(REGASM) /unregister HelloDotNETWorld.dll

clean:
	- $(REGASM) /unregister HelloDotNETWorld.dll
	- rm -f $(TARGET)

HelloDotNETWorld.sml: HelloDotNETWorld.tlb
	$(OLE2SML) $<

HelloDotNETWorld.tlb: HelloDotNETWorld.dll
	$(TLBEXP) $< /out:$@ ||  $(REGASM) /tlb $<

HelloDotNETWorld.dll: HelloDotNETWorld.cs
	$(CSC) /t:library $<

UseHelloDotNETWorld.exe: UseHelloDotNETWorld.sml
	$(SMLSHARP2EXE) -o $@ $<
