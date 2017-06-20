MLYACC = ../../../ml-yacc/smlyacc
MLLEX = ../../../ml-lex/smllex
SMLFORMAT = ../../../smlformat/smlformat
# SMLSHARP = ../../../compiler/smlsharp
SMLSHARP = smlsharp
SRCDIR = ../main

.SUFFIXES: .c .h .o .a .sml .ppg .ppg.sml .lex .grm .lex.sml .grm.sml

.sml.o:
	$(SMLSHARP) -B../../../. -c -o $@ $<

.ppg.ppg.sml:
	$(SMLFORMAT) --output=$@ $<


allTest: allTest.o  TestValuePrinting.o 
	$(SMLSHARP) -o allTest -B../../../. allTest.smi

TestValuePrinting: TestValuePrinting.o $(SRCDIR)/ReifiedTy.ppg.o $(SRCDIR)/ReifiedTy.ppg.smi $(SRCDIR)/ReifiedTerm.ppg.o $(SRCDIR)/ReifiedTerm.ppg.smi $(SRCDIR)/ReifyTerm.o $(SRCDIR)/ReifyTerm.smi
	$(SMLSHARP) -o TestValuePrinting -B../../../. TestValuePrinting.smi

$(SRCDIR)/ReifiedTy.ppg.sml: $(SRCDIR)/ReifiedTy.ppg $(SRCDIR)/ReifiedTy.ppg.smi

$(SRCDIR)/ReifiedTy.ppg.o: $(SRCDIR)/ReifiedTy.ppg.sml $(SRCDIR)/ReifiedTy.ppg.smi

clean:
	rm -f ./*.o TestReify TestReifyTy allTest TestTyToReifinedTy

