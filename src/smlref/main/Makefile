SMLSHARP = ../../../src/compiler/smlsharp -B../../../src
SMLFORMAT = smlformat
SMLFLAGS = -O2
LIBS =

.SUFFIXES: .o .sml .smi .sig .ppg

all: SMLRef TestMain GenReuireDecls

DBSchema.smi: ../../compiler/compilePhases/analyzefiles/main/DBSchema.smi
	cp ../../compiler/compilePhases/analyzefiles/main/DBSchema.smi DBSchema.smi 

DBSchema.sml: ../../compiler/compilePhases/analyzefiles/main/DBSchema.sml
	cp ../../compiler/compilePhases/analyzefiles/main/DBSchema.sml DBSchema.sml

nestedMap.ppg.sml:  nestedMap.ppg  nestedMap.ppg.smi
	$(SMLFORMAT)  --output=$@ --input nestedMap.ppg

SMLRef: DBSchema.smi Config.smi Log.smi RefDBAccess.smi SMLRef.smi DBSchema.o \
 Config.o Log.o RefDBAccess.o SMLRef.o
	$(SMLSHARP) $(LDFLAGS) -o SMLRef SMLRef.smi $(LIBS)
DBSchema.o: DBSchema.sml DBSchema.smi
	$(SMLSHARP) $(SMLFLAGS) -o DBSchema.o -c DBSchema.sml
Config.o: Config.sml DBSchema.smi Config.smi
	$(SMLSHARP) $(SMLFLAGS) -o Config.o -c Config.sml
Log.o: Log.sml DBSchema.smi Config.smi Log.smi
	$(SMLSHARP) $(SMLFLAGS) -o Log.o -c Log.sml
RefDBAccess.o: RefDBAccess.sml DBSchema.smi Config.smi Log.smi RefDBAccess.smi
	$(SMLSHARP) $(SMLFLAGS) -o RefDBAccess.o -c RefDBAccess.sml
SMLRef.o: SMLRef.sml DBSchema.smi Config.smi Log.smi RefDBAccess.smi SMLRef.smi
	$(SMLSHARP) $(SMLFLAGS) -o SMLRef.o -c SMLRef.sml

GenReuireDecls: DBSchema.smi Config.smi ProcessRequireFile.smi \
 GenReuireDecls.smi DBSchema.o Config.o ProcessRequireFile.o GenReuireDecls.o
	$(SMLSHARP) $(LDFLAGS) -o GenReuireDecls GenReuireDecls.smi $(LIBS)
ProcessRequireFile.o: ProcessRequireFile.sml DBSchema.smi Config.smi \
 ProcessRequireFile.smi
	$(SMLSHARP) $(SMLFLAGS) -o ProcessRequireFile.o -c \
 ProcessRequireFile.sml
GenReuireDecls.o: GenReuireDecls.sml DBSchema.smi Config.smi \
 ProcessRequireFile.smi GenReuireDecls.smi
	$(SMLSHARP) $(SMLFLAGS) -o GenReuireDecls.o -c GenReuireDecls.sml

TestMain: DBSchema.smi Config.smi IntStringMap.smi IntIntStringMap.smi \
 BasicData.smi nestedMap.ppg.smi TestMain.smi DBSchema.o Config.o \
 IntStringMap.o IntIntStringMap.o IntIntIntStringMap.o BasicData.o nestedMap.ppg.o TestMain.o
	$(SMLSHARP) $(LDFLAGS) -o TestMain TestMain.smi $(LIBS)
IntStringMap.o: IntStringMap.sml IntStringMap.smi
	$(SMLSHARP) $(SMLFLAGS) -o IntStringMap.o -c IntStringMap.sml
IntIntStringMap.o: IntIntStringMap.sml IntIntStringMap.smi
	$(SMLSHARP) $(SMLFLAGS) -o IntIntStringMap.o -c IntIntStringMap.sml
IntIntIntStringMap.o: IntIntIntStringMap.sml IntIntIntStringMap.smi
	$(SMLSHARP) $(SMLFLAGS) -o IntIntIntStringMap.o -c IntIntIntStringMap.sml
BasicData.o: BasicData.sml DBSchema.smi Config.smi IntStringMap.smi \
 IntIntStringMap.smi IntIntIntStringMap.smi BasicData.smi
	$(SMLSHARP) $(SMLFLAGS) -o BasicData.o -c BasicData.sml
nestedMap.ppg.o: nestedMap.ppg.sml nestedMap.ppg.smi
	$(SMLSHARP) $(SMLFLAGS) -o nestedMap.ppg.o -c nestedMap.ppg.sml
TestMain.o: TestMain.sml DBSchema.smi Config.smi IntStringMap.smi \
 IntIntStringMap.smi BasicData.smi nestedMap.ppg.smi TestMain.smi
	$(SMLSHARP) $(SMLFLAGS) -o TestMain.o -c TestMain.sml

clean: 
	rm -f SMLRef GenReuireDecls BasicData.o \
 Config.o DBSchema.o DataUtils.o \
 GenReuireDecls.o IntStringMap.o Log.o IntIntStringMap.o Log.o ProcessRequireFile.o \
 RefDBAccess.o SMLRef.o TestMain.o nestedMap.ppg.o nestedMap.ppg.sml

