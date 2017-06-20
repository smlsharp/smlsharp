SMLFORMAT = ../../../smlformat/smlformat
SMLSHARP = ../../../compiler/smlsharp
SRCDIR = ../main

.SUFFIXES: .c .h .o .a .sml .ppg .ppg.sml .lex .grm .lex.sml .grm.sml

.sml.o:
	$(SMLSHARP) -B../../../. -c -o $@ $<

.ppg.ppg.sml:
	$(SMLFORMAT) --output=$@ $<

allTest: allTest.o TestJSONTypes.o TestJSON.o TestJSONImpl.o $(SRCDIR)/JSONTypes.ppg.o $(SRCDIR)/JSONTypes.ppg.smi
	$(SMLSHARP) -o allTest -B../../../. allTest.smi

allTest.o: TestJSON.smi TestJSONTypes.smi TestJSONImpl.smi allTest.sml

TestJSONTypes.o: $(SRCDIR)/JSONTypes.ppg $(SRCDIR)/JSONTypes.ppg.smi TestJSONTypes.smi TestJSONTypes.sml 

TestJSONImpl.o: $(SRCDIR)/JSONImpl.smi $(SRCDIR)/JSONImpl.sml $(SRCDIR)/JSON.smi ../../json-to-ml/main/JSONToML.smi

TestJSON.o: $(SRCDIR)/JSON.sml $(SRCDIR)/JSON.smi TestJSON.smi TestJSON.sml

$(SRCDIR)/JSONTypes.ppg.sml: $(SRCDIR)/JSONTypes.ppg $(SRCDIR)/JSONTypes.ppg.smi

$(SRCDIR)/JSONTypes.ppg.o: $(SRCDIR)/JSONTypes.ppg.sml $(SRCDIR)/JSONTypes.ppg.smi

$(SRCDIR)/JSONT.o: $(SRCDIR)/JSON.ppg.sml $(SRCDIR)/JSON.smi

clean:
	rm -f allTest allTest.o TestJSONTypes.o TestJSON.o

