MLYACC = ../../../ml-yacc/smlyacc
MLLEX = ../../../ml-lex/smllex
SMLFORMAT = ../../../smlformat/smlformat
SMLSHARP = ../../../compiler/smlsharp
SRCDIR = ../main

.SUFFIXES: .c .h .o .a .sml .ppg .ppg.sml .lex .grm .lex.sml .grm.sml

.sml.o:
	$(SMLSHARP) -B../../../. -c -o $@ $<

.ppg.ppg.sml:
	$(SMLFORMAT) --output=$@ $<

testAll: TestPolyDynamic.o
	$(SMLSHARP) -B../../../. -o testAll TestPolyDynamic.smi

TestPolyDynamic.o: $(SRCDIR)/PolyDynamic.sml TestPolyDynamic.smi TestPolyDynamic.sml 

$(SRCDIR)/PolyDynamic.sml: $(SRCDIR)/PolyDynamic.smi

$(SRCDIR)/PolyDynamic.o: $(SRCDIR)/PolyDynamic.sml $(SRCDIR)/PolyDynamic.smi

clean:
	rm -f TestPolyDynamic.o testAll
