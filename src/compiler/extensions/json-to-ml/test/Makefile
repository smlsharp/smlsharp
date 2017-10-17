SMLSHARP = ../../../compiler/smlsharp
SMLSHARP_SRCDIR = ../../..

testExec : Main.o TestMain.o JSONToML001.o
	$(SMLSHARP) -B$(SMLSHARP_SRCDIR) -o testExec Main.smi

.SUFFIXES : .sml

.sml.o:
	$(SMLSHARP) -B$(SMLSHARP_SRCDIR) -c -o $@ $<

TestMain.o : TestMain.sml TestMain.smi JSONToML001.smi
Main.o : Main.sml Main.smi TestMain.smi JSONToML001.smi
JSONToML001.o : JSONToML001.sml JSONToML001.smi
