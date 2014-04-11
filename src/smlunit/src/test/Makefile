SMLSHARP_ENV = SMLSHARP_HEAPSIZE=128M:1G
SMLSHARP = smll
SMLFLAGS = -O2
ALLOBJECTS = Main.o TestMain.o TestTextUITestRunner.o TestTest.o TestAssert.o

testExec: $(ALLOBJECTS)
	$(SMLSHARP_ENV) $(SMLSHARP) $(SMLFLAGS) -o testExec Main.smi

Main.o: Main.sml Main.smi TestAssert.smi TestTest.smi TestTextUITestRunner.smi \
 TestMain.smi Main.smi
TestAssert.o: TestAssert.sml TestAssert.smi TestAssert.smi
TestMain.o: TestMain.sml TestMain.smi TestAssert.smi TestTest.smi \
 TestTextUITestRunner.smi TestMain.smi
TestTest.o: TestTest.sml TestTest.smi TestTest.smi
TestTextUITestRunner.o: TestTextUITestRunner.sml TestTextUITestRunner.smi \
 TestTextUITestRunner.smi

.sml.o:
	$(SMLSHARP_ENV) $(SMLSHARP) $(SMLFLAGS) -c -o $@ $<

.SUFFIXES: .sml

clean: PHONY
	rm -f $(ALLOBJECTS) testExec

PHONY: