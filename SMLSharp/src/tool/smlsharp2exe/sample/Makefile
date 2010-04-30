
SMLSHARP2EXE=/usr/local/bin/smlsharp2exe.sh
SMLSHARP_LIB_DIR=/usr/local/lib
CXX=g++
CC=gcc

TARGETS=app.exe interpreter.o interpreter.h

all: app.exe

interpreter.o: interpreter.sml
	$(SMLSHARP2EXE) -c $<

app.exe: app.c interpreter.o
	$(CXX) -o $@ -L ${SMLSHARP_LIB_DIR} $^ -lsmlsharp -lgmp
#	$(CC) -o $@ -L  ${SMLSHARP_LIB_DIR} $^ -lsmlsharp -lgmp -lstdc++

clean:
	-rm -f $(TARGETS)