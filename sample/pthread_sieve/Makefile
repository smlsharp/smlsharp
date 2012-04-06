SMLSHARP = smlsharp

pthread_sieve: load.smi pthread.o mvar.o sieve.o load.o
	$(SMLSHARP) -o $@ load.smi $(LIBS)

pthread.o: pthread.sml pthread.smi
	$(SMLSHARP) -c -o $@ pthread.sml
mvar.o: mvar.sml mvar.smi pthread.smi
	$(SMLSHARP) -c -o $@ mvar.sml
sieve.o: sieve.sml sieve.smi mvar.smi pthread.smi
	$(SMLSHARP) -c -o $@ sieve.sml
load.o: load.sml load.smi sieve.smi mvar.smi pthread.smi
	$(SMLSHARP) -c -o $@ load.sml

clean:
	-rm -f pthread_sieve pthread.o mvar.o sieve.o load.o
