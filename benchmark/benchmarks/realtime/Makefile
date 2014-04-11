#SMLSHARP = ../../../src/compiler/smlsharp -B../../../../../smlsharp_concurrentgc/smlsharp/src -dinsertCheckGC=yes
SMLSHARP = ../../../src/compiler/smlsharp -B../../../src -dinsertCheckGC=yes
CC = gcc -m32

realtime: top.smi top.o main.o gettime.o clock_gettime.o pthread.o fft.o count_graphs.o gcbench.o
	$(SMLSHARP) -o $@ top.smi $(LIBS) clock_gettime.o -lrt

top.o : top.sml top.smi main.smi
	$(SMLSHARP) -c -o $@ top.sml
main.o : main.sml main.smi gettime.smi pthread.smi fft.smi count_graphs.smi
	$(SMLSHARP) -c -o $@ main.sml
gettime.o : gettime.sml gettime.smi clock_gettime.c
	$(SMLSHARP) -c -o $@ gettime.sml
clock_gettime.o : clock_gettime.c
	$(CC) -c -o $@ clock_gettime.c
pthread.o : pthread.sml pthread.smi 
	$(SMLSHARP) -c -o $@ pthread.sml
fft.o : fft.sml fft.smi
	$(SMLSHARP) -c -o $@ fft.sml
gcbench.o : gcbench.sml gcbench.smi
	$(SMLSHARP) -c -o $@ gcbench.sml
count_graphs.o : count_graphs.sml count_graphs.smi
	$(SMLSHARP) -c -o $@ count_graphs.sml


clean:
	-rm -f realtime top.o main.o gettime.o clock_gettime.o pthread.o fft.o count_graph.o
