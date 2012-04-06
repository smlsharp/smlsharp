SMLSHARP = smlsharp

callback: callback.smi callback.o callback_c.o
	$(SMLSHARP) -o $@ callback.smi callback_c.o
callback.o: callback.sml
	$(SMLSHARP) -c -o $@ callback.sml
callback_c.o: callback.c
	$(CC) $(CFLAGS) -c -o $@ callback.c

clean:
	-rm -f callback callback.o callback_c.o
