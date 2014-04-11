SMLSHARP_ENV = SMLSHARP_HEAPSIZE=128M:1G
SMLSHARP = smlsharp
SMLFLAGS = -O2

all: src/main/SMLUnit.o src/main/TextUITestRunner.o src/main/Test.o \
 src/main/Assert.o

src/main/Assert.o: src/main/Assert.sml src/main/Assert.smi src/main/ASSERT.sig \
 src/main/Assert.smi
src/main/SMLUnit.o: src/main/SMLUnit.sml src/main/SMLUnit.smi \
 src/main/ASSERT.sig src/main/Assert.smi src/main/TEST.sig src/main/Test.smi \
 src/main/TESTRUNNER.sig src/main/TextUITestRunner.smi src/main/SMLUNIT.sig \
 src/main/SMLUnit.smi
src/main/Test.o: src/main/Test.sml src/main/Test.smi src/main/TEST.sig \
 src/main/Test.smi
src/main/TextUITestRunner.o: src/main/TextUITestRunner.sml \
 src/main/TextUITestRunner.smi src/main/ASSERT.sig src/main/Assert.smi \
 src/main/TEST.sig src/main/Test.smi src/main/TESTRUNNER.sig \
 src/main/TextUITestRunner.smi

.sml.o:
	$(SMLSHARP_ENV) $(SMLSHARP) $(SMLFLAGS) -c -o $@ $<

clean: PHONY
	rm -f src/main/SMLUnit.o src/main/TextUITestRunner.o src/main/Test.o \
 src/main/Assert.o

PHONY: # force to rebuild

.SUFFIXES: .sml
