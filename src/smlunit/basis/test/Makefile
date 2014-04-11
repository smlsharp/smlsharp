SMLSHARP_ENV = SMLSHARP_HEAPSIZE=128M:1G
SMLSHARP = smlsharp
# SMLFLAGS = -O2

ALLOBJECTS = Main.o TestMain.o TestOptionalModules_SMLSharp.o IntInf101.o IntInf001.o \
 TestRequiredModules.o Word8VectorSlice001.o Word8VectorSlice101.o \
 Word8Vector101.o Word8Vector001.o Word8ArraySlice101.o Word8ArraySlice001.o \
 Word8Array101.o Word8Array001.o Word8001.o Word001.o VectorSlice101.o \
 VectorSlice001.o Vector101.o Vector001.o Time001.o Substring001.o String001.o \
 StringCvt001.o Real001.o Position001.o Option001.o Math001.o ListPair001.o \
 List001.o LargeWord001.o UnsignedInteger001.o LargeInt001.o Int001.o \
 SignedInteger001.o IEEEReal001.o General001.o Date001.o CharVectorSlice101.o \
 CharVectorSlice001.o ImmutableSequenceSlice001.o CharVector101.o \
 CharVector001.o ImmutableSequence001.o CharArraySlice101.o \
 CharArraySlice001.o CharArray101.o CharArray001.o Char001.o Byte001.o \
 Bool001.o ArraySlice101.o SequenceSlice101.o ArraySlice001.o \
 MutableSequenceSlice001.o Array101.o Sequence101.o Array001.o \
 MutableSequence001.o ../../src/main/SMLUnit.o \
 ../../src/main/TextUITestRunner.o ../../src/main/Test.o \
 ../../src/main/Assert.o

testExec : $(ALLOBJECTS)
	$(SMLSHARP_ENV) $(SMLSHARP) $(SMLFLAGS) -o testExec Main.smi

clean: PHONY
	rm -f $(ALLOBJECTS) testExec

PHONY: # force to rebuild

.sml.o:
	$(SMLSHARP_ENV) $(SMLSHARP) $(SMLFLAGS) -c -o $@ $<

.SUFFIXES: .sml

Array001.o: Array001.sml Array001.smi ../../src/main/ASSERT.sig \
 ../../src/main/Assert.smi ../../src/main/TEST.sig ../../src/main/Test.smi \
 ../../src/main/TESTRUNNER.sig ../../src/main/TextUITestRunner.smi \
 ../../src/main/SMLUNIT.sig ../../src/main/SMLUnit.smi SEQUENCE.sig \
 MUTABLE_SEQUENCE.sig MutableSequence001.smi Array001.smi
Array101.o: Array101.sml Array101.smi ../../src/main/ASSERT.sig \
 ../../src/main/Assert.smi ../../src/main/TEST.sig ../../src/main/Test.smi \
 ../../src/main/TESTRUNNER.sig ../../src/main/TextUITestRunner.smi \
 ../../src/main/SMLUNIT.sig ../../src/main/SMLUnit.smi SEQUENCE.sig \
 Sequence101.smi Array101.smi
Array2001.o: Array2001.sml Array2001.smi SEQUENCE.sig Sequence101.smi \
 Array2001.smi
ArraySlice001.o: ArraySlice001.sml ArraySlice001.smi SEQUENCE_SLICE.sig \
 MUTABLE_SEQUENCE_SLICE.sig MutableSequenceSlice001.smi ArraySlice001.smi
ArraySlice101.o: ArraySlice101.sml ArraySlice101.smi SEQUENCE.sig \
 SEQUENCE_SLICE.sig SequenceSlice101.smi ArraySlice101.smi
Bool001.o: Bool001.sml Bool001.smi Bool001.smi
Byte001.o: Byte001.sml Byte001.smi Byte001.smi
Char001.o: Char001.sml Char001.smi Char001.smi
CharArray001.o: CharArray001.sml CharArray001.smi SEQUENCE.sig \
 MUTABLE_SEQUENCE.sig MutableSequence001.smi CharArray001.smi
CharArray101.o: CharArray101.sml CharArray101.smi SEQUENCE.sig Sequence101.smi \
 CharArray101.smi
CharArray2001.o: CharArray2001.sml CharArray2001.smi SEQUENCE.sig \
 Sequence101.smi CharArray2001.smi
CharArraySlice001.o: CharArraySlice001.sml CharArraySlice001.smi \
 SEQUENCE_SLICE.sig MUTABLE_SEQUENCE_SLICE.sig MutableSequenceSlice001.smi \
 CharArraySlice001.smi
CharArraySlice101.o: CharArraySlice101.sml CharArraySlice101.smi SEQUENCE.sig \
 SEQUENCE_SLICE.sig SequenceSlice101.smi CharArraySlice101.smi
CharVector001.o: CharVector001.sml CharVector001.smi SEQUENCE.sig \
 IMMUTABLE_SEQUENCE.sig ImmutableSequence001.smi CharVector001.smi
CharVector101.o: CharVector101.sml CharVector101.smi SEQUENCE.sig \
 Sequence101.smi CharVector101.smi
CharVectorSlice001.o: CharVectorSlice001.sml CharVectorSlice001.smi \
 SEQUENCE_SLICE.sig IMMUTABLE_SEQUENCE_SLICE.sig ImmutableSequenceSlice001.smi \
 CharVectorSlice001.smi
CharVectorSlice101.o: CharVectorSlice101.sml CharVectorSlice101.smi \
 SEQUENCE.sig SEQUENCE_SLICE.sig SequenceSlice101.smi CharVectorSlice101.smi
Date001.o: Date001.sml Date001.smi Date001.smi
General001.o: General001.sml General001.smi General001.smi
IEEEReal001.o: IEEEReal001.sml IEEEReal001.smi IEEEReal001.smi
ImmutableSequence001.o: ImmutableSequence001.sml ImmutableSequence001.smi \
 SEQUENCE.sig IMMUTABLE_SEQUENCE.sig ImmutableSequence001.smi
ImmutableSequenceSlice001.o: ImmutableSequenceSlice001.sml \
 ImmutableSequenceSlice001.smi SEQUENCE_SLICE.sig IMMUTABLE_SEQUENCE_SLICE.sig \
 ImmutableSequenceSlice001.smi
Int001.o: Int001.sml Int001.smi SignedInteger001.smi Int001.smi
IntInf001.o: IntInf001.sml IntInf001.smi SignedInteger001.smi IntInf001.smi
IntInf101.o: IntInf101.sml IntInf101.smi IntInf101.smi
LargeInt001.o: LargeInt001.sml LargeInt001.smi SignedInteger001.smi \
 LargeInt001.smi
LargeWord001.o: LargeWord001.sml LargeWord001.smi UnsignedInteger001.smi \
 LargeWord001.smi
List001.o: List001.sml List001.smi List001.smi
ListPair001.o: ListPair001.sml ListPair001.smi ListPair001.smi
Main.o: Main.sml Main.smi ../../src/main/ASSERT.sig ../../src/main/Assert.smi \
 ../../src/main/TEST.sig ../../src/main/Test.smi ../../src/main/TESTRUNNER.sig \
 ../../src/main/TextUITestRunner.smi ../../src/main/SMLUNIT.sig \
 ../../src/main/SMLUnit.smi SEQUENCE.sig MUTABLE_SEQUENCE.sig \
 MutableSequence001.smi Array001.smi Sequence101.smi Array101.smi \
 SEQUENCE_SLICE.sig MUTABLE_SEQUENCE_SLICE.sig MutableSequenceSlice001.smi \
 ArraySlice001.smi SequenceSlice101.smi ArraySlice101.smi Bool001.smi \
 Byte001.smi Char001.smi CharArray001.smi CharArray101.smi \
 CharArraySlice001.smi CharArraySlice101.smi IMMUTABLE_SEQUENCE.sig \
 ImmutableSequence001.smi CharVector001.smi CharVector101.smi \
 IMMUTABLE_SEQUENCE_SLICE.sig ImmutableSequenceSlice001.smi \
 CharVectorSlice001.smi CharVectorSlice101.smi Date001.smi General001.smi \
 IEEEReal001.smi SignedInteger001.smi Int001.smi LargeInt001.smi \
 UnsignedInteger001.smi LargeWord001.smi List001.smi ListPair001.smi \
 Math001.smi Option001.smi Position001.smi Real001.smi StringCvt001.smi \
 String001.smi Substring001.smi Time001.smi Vector001.smi Vector101.smi \
 VectorSlice001.smi VectorSlice101.smi Word001.smi Word8001.smi \
 Word8Array001.smi Word8Array101.smi Word8ArraySlice001.smi \
 Word8ArraySlice101.smi Word8Vector001.smi Word8Vector101.smi \
 Word8VectorSlice101.smi Word8VectorSlice001.smi TestRequiredModules.smi \
 IntInf001.smi IntInf101.smi TestOptionalModules_SMLSharp.smi TestMain.smi \
 Main.smi
Math001.o: Math001.sml Math001.smi Math001.smi
Mutable2DSequence001.o: Mutable2DSequence001.sml Mutable2DSequence001.smi \
 SEQUENCE.sig MUTABLE_2D_SEQUENCE.sig Mutable2DSequence001.smi
MutableSequence001.o: MutableSequence001.sml MutableSequence001.smi \
 SEQUENCE.sig MUTABLE_SEQUENCE.sig MutableSequence001.smi
MutableSequenceSlice001.o: MutableSequenceSlice001.sml \
 MutableSequenceSlice001.smi SEQUENCE_SLICE.sig MUTABLE_SEQUENCE_SLICE.sig \
 MutableSequenceSlice001.smi
Option001.o: Option001.sml Option001.smi Option001.smi
Position001.o: Position001.sml Position001.smi SignedInteger001.smi \
 Position001.smi
Real001.o: Real001.sml Real001.smi Real001.smi
RealArray001.o: RealArray001.sml RealArray001.smi SEQUENCE.sig \
 MUTABLE_SEQUENCE.sig MutableSequence001.smi RealArray001.smi
RealArray101.o: RealArray101.sml RealArray101.smi SEQUENCE.sig Sequence101.smi \
 RealArray101.smi
RealVector001.o: RealVector001.sml RealVector001.smi SEQUENCE.sig \
 MUTABLE_SEQUENCE.sig MutableSequence001.smi RealVector001.smi
RealVector101.o: RealVector101.sml RealVector101.smi SEQUENCE.sig \
 Sequence101.smi RealVector101.smi
Sequence101.o: Sequence101.sml Sequence101.smi SEQUENCE.sig Sequence101.smi
SequenceSlice101.o: SequenceSlice101.sml SequenceSlice101.smi SEQUENCE.sig \
 SEQUENCE_SLICE.sig SequenceSlice101.smi
SignedInteger001.o: SignedInteger001.sml SignedInteger001.smi \
 SignedInteger001.smi
String001.o: String001.sml String001.smi String001.smi
StringCvt001.o: StringCvt001.sml StringCvt001.smi StringCvt001.smi
Substring001.o: Substring001.sml Substring001.smi Substring001.smi
TestMain.o: TestMain.sml TestMain.smi ../../src/main/ASSERT.sig \
 ../../src/main/Assert.smi ../../src/main/TEST.sig ../../src/main/Test.smi \
 ../../src/main/TESTRUNNER.sig ../../src/main/TextUITestRunner.smi \
 ../../src/main/SMLUNIT.sig ../../src/main/SMLUnit.smi SEQUENCE.sig \
 MUTABLE_SEQUENCE.sig MutableSequence001.smi Array001.smi Sequence101.smi \
 Array101.smi SEQUENCE_SLICE.sig MUTABLE_SEQUENCE_SLICE.sig \
 MutableSequenceSlice001.smi ArraySlice001.smi SequenceSlice101.smi \
 ArraySlice101.smi Bool001.smi Byte001.smi Char001.smi CharArray001.smi \
 CharArray101.smi CharArraySlice001.smi CharArraySlice101.smi \
 IMMUTABLE_SEQUENCE.sig ImmutableSequence001.smi CharVector001.smi \
 CharVector101.smi IMMUTABLE_SEQUENCE_SLICE.sig ImmutableSequenceSlice001.smi \
 CharVectorSlice001.smi CharVectorSlice101.smi Date001.smi General001.smi \
 IEEEReal001.smi SignedInteger001.smi Int001.smi LargeInt001.smi \
 UnsignedInteger001.smi LargeWord001.smi List001.smi ListPair001.smi \
 Math001.smi Option001.smi Position001.smi Real001.smi StringCvt001.smi \
 String001.smi Substring001.smi Time001.smi Vector001.smi Vector101.smi \
 VectorSlice001.smi VectorSlice101.smi Word001.smi Word8001.smi \
 Word8Array001.smi Word8Array101.smi Word8ArraySlice001.smi \
 Word8ArraySlice101.smi Word8Vector001.smi Word8Vector101.smi \
 Word8VectorSlice101.smi Word8VectorSlice001.smi TestRequiredModules.smi \
 IntInf001.smi IntInf101.smi TestOptionalModules_SMLSharp.smi TestMain.smi
TestOptionalModules_MLton.o: TestOptionalModules_MLton.sml
TestOptionalModules_SMLNJ.o: TestOptionalModules_SMLNJ.sml
TestOptionalModules_SMLSharp.o: TestOptionalModules_SMLSharp.sml \
 TestOptionalModules_SMLSharp.smi SignedInteger001.smi IntInf001.smi \
 IntInf101.smi TestOptionalModules_SMLSharp.smi
TestRequiredModules.o: TestRequiredModules.sml TestRequiredModules.smi \
 ../../src/main/ASSERT.sig ../../src/main/Assert.smi ../../src/main/TEST.sig \
 ../../src/main/Test.smi ../../src/main/TESTRUNNER.sig \
 ../../src/main/TextUITestRunner.smi ../../src/main/SMLUNIT.sig \
 ../../src/main/SMLUnit.smi SEQUENCE.sig MUTABLE_SEQUENCE.sig \
 MutableSequence001.smi Array001.smi Sequence101.smi Array101.smi \
 SEQUENCE_SLICE.sig MUTABLE_SEQUENCE_SLICE.sig MutableSequenceSlice001.smi \
 ArraySlice001.smi SequenceSlice101.smi ArraySlice101.smi Bool001.smi \
 Byte001.smi Char001.smi CharArray001.smi CharArray101.smi \
 CharArraySlice001.smi CharArraySlice101.smi IMMUTABLE_SEQUENCE.sig \
 ImmutableSequence001.smi CharVector001.smi CharVector101.smi \
 IMMUTABLE_SEQUENCE_SLICE.sig ImmutableSequenceSlice001.smi \
 CharVectorSlice001.smi CharVectorSlice101.smi Date001.smi General001.smi \
 IEEEReal001.smi SignedInteger001.smi Int001.smi LargeInt001.smi \
 UnsignedInteger001.smi LargeWord001.smi List001.smi ListPair001.smi \
 Math001.smi Option001.smi Position001.smi Real001.smi StringCvt001.smi \
 String001.smi Substring001.smi Time001.smi Vector001.smi Vector101.smi \
 VectorSlice001.smi VectorSlice101.smi Word001.smi Word8001.smi \
 Word8Array001.smi Word8Array101.smi Word8ArraySlice001.smi \
 Word8ArraySlice101.smi Word8Vector001.smi Word8Vector101.smi \
 Word8VectorSlice101.smi Word8VectorSlice001.smi TestRequiredModules.smi
TestTest.o: TestTest.sml TestTest.smi Bool001.smi TestTest.smi
Time001.o: Time001.sml Time001.smi Time001.smi
UnsignedInteger001.o: UnsignedInteger001.sml UnsignedInteger001.smi \
 UnsignedInteger001.smi
Vector001.o: Vector001.sml Vector001.smi SEQUENCE.sig IMMUTABLE_SEQUENCE.sig \
 ImmutableSequence001.smi Vector001.smi
Vector101.o: Vector101.sml Vector101.smi SEQUENCE.sig Sequence101.smi \
 Vector101.smi
VectorSlice001.o: VectorSlice001.sml VectorSlice001.smi SEQUENCE_SLICE.sig \
 IMMUTABLE_SEQUENCE_SLICE.sig ImmutableSequenceSlice001.smi VectorSlice001.smi
VectorSlice101.o: VectorSlice101.sml VectorSlice101.smi SEQUENCE.sig \
 SEQUENCE_SLICE.sig SequenceSlice101.smi VectorSlice101.smi
Word001.o: Word001.sml Word001.smi UnsignedInteger001.smi Word001.smi
Word8001.o: Word8001.sml Word8001.smi UnsignedInteger001.smi Word8001.smi
Word8Array001.o: Word8Array001.sml Word8Array001.smi SEQUENCE.sig \
 MUTABLE_SEQUENCE.sig MutableSequence001.smi Word8Array001.smi
Word8Array101.o: Word8Array101.sml Word8Array101.smi SEQUENCE.sig \
 Sequence101.smi Word8Array101.smi
Word8Array2001.o: Word8Array2001.sml Word8Array2001.smi SEQUENCE.sig \
 MUTABLE_2D_SEQUENCE.sig Mutable2DSequence001.smi Word8Array2001.smi
Word8ArraySlice001.o: Word8ArraySlice001.sml Word8ArraySlice001.smi \
 SEQUENCE_SLICE.sig MUTABLE_SEQUENCE_SLICE.sig MutableSequenceSlice001.smi \
 Word8ArraySlice001.smi
Word8ArraySlice101.o: Word8ArraySlice101.sml Word8ArraySlice101.smi \
 SEQUENCE.sig SEQUENCE_SLICE.sig SequenceSlice101.smi Word8ArraySlice101.smi
Word8Vector001.o: Word8Vector001.sml Word8Vector001.smi SEQUENCE.sig \
 IMMUTABLE_SEQUENCE.sig ImmutableSequence001.smi Word8Vector001.smi
Word8Vector101.o: Word8Vector101.sml Word8Vector101.smi SEQUENCE.sig \
 SEQUENCE_SLICE.sig SequenceSlice101.smi Sequence101.smi Word8Vector101.smi
Word8VectorSlice001.o: Word8VectorSlice001.sml Word8VectorSlice001.smi \
 SEQUENCE_SLICE.sig IMMUTABLE_SEQUENCE_SLICE.sig ImmutableSequenceSlice001.smi \
 Word8VectorSlice001.smi
Word8VectorSlice101.o: Word8VectorSlice101.sml Word8VectorSlice101.smi \
 SEQUENCE.sig SEQUENCE_SLICE.sig SequenceSlice101.smi Word8VectorSlice101.smi
