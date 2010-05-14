CSC=csc.exe
REGASM=RegAsm.exe
OLE2SML=OLE2SML.exe

TARGET= \
	HelloDotNetWorld.dll \
	HelloDotNetWorld.tlb \
	HelloDotNetWorld.sml \


all: $(TARGET)

clean:
	- $(REGASM) /unregister HelloDotNetWorld.dll
	- rm -f $(TARGET)

HelloDotNetWorld.sml: HelloDotNetWorld.tlb
	$(OLE2SML) $<

#  With /codebase option, regasm prints a warning message to specify strong
# name.
# To avoid it, copy the dll to the directory where smlsharp is installed,
# or use 'sn.exe' to generate a strong name for this assembly.
HelloDotNetWorld.tlb: HelloDotNetWorld.dll
	$(REGASM) /codebase /tlb $<

HelloDotNetWorld.dll: HelloDotNetWorld.cs
	$(CSC) /t:library $<

