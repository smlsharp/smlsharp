SMLSHARP = smlsharp

database-cgi: load.smi cgi.o cgimain.o load.o pages.o try.o
	$(SMLSHARP) -o $@ load.smi
cgi.o: cgi.sml cgi.smi
	$(SMLSHARP) -c -o $@ cgi.sml
cgimain.o: cgimain.sml cgi.smi pages.smi cgimain.smi
	$(SMLSHARP) -c -o $@ cgimain.sml
load.o: load.sml load.smi cgimain.smi cgi.smi pages.smi try.smi
	$(SMLSHARP) -c -o $@ load.sml
pages.o: pages.sml cgi.smi try.smi pages.smi
	$(SMLSHARP) -c -o $@ pages.sml
try.o: try.sml try.smi
	$(SMLSHARP) -c -o $@ try.sml

clean:
	-rm -f database-cgi cgi.o cgimain.o load.o pages.o try.o
