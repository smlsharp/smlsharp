SMLSHARP = smlsharp

all: sample1

sample1: sample1.sml sample1.smi
	$(SMLSHARP) -o $@ sample1.sml
sample2: sample2.sml sample2.smi
	$(SMLSHARP) -o $@ sample2.sml

clean:
	-rm -f sample1
