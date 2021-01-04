SMLSHARP = ../../../src/compiler/smlsharp -B ../../../src
SMLFLAGS = -O2
CC = cc
CFLAGS = -O2

all: main_seq main_pth main_myth

clean:
	rm -f main_seq main_pth main_myth
	rm -f stdio.o files.o parse.o main_seq.o main_pth.o main_myth.o incr.o

main_seq: files.o stdio.o parse.o main_seq.o
	$(SMLSHARP) -o $@ main_seq.smi
main_pth: files.o stdio.o parse.o main_pth.o incr.o
	$(SMLSHARP) -o $@ main_pth.smi incr.o
main_myth: files.o stdio.o parse.o main_myth.o
	$(SMLSHARP) -o $@ main_myth.smi
stdio.o: stdio.sml stdio.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ stdio.sml
files.o: files.sml files.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ files.sml
parse.o: parse.sml stdio.smi parse.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ parse.sml
main_seq.o: main_seq.sml files.smi parse.smi main_seq.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ main_seq.sml
main_pth.o: main_pth.sml files.smi parse.smi main_pth.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ main_pth.sml
main_myth.o: main_myth.sml files.smi parse.smi main_myth.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ main_myth.sml
incr.o: incr.c
	$(CC) $(CFLAGS) -c -o $@ incr.c


main_seq35: files.o stdio.o parse.o main_seq.o ../smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) -o $@ -nostdlib ../smlsharp-3.5.0/src/runtime/main.o main_seq.smi ../smlsharp-3.5.0/src/runtime/libsmlsharp.a
main_pth35: files.o stdio.o parse.o main_pth.o incr.o ../smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) -o $@ -nostdlib ../smlsharp-3.5.0/src/runtime/main.o main_pth.smi incr.o ../smlsharp-3.5.0/src/runtime/libsmlsharp.a

