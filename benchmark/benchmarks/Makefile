SMLSHARP = SMLSHARP_HEAPSIZE=32M:2G ../../src/compiler/smlsharp -B ../../src
DOIT_SUFFIX =
LIBS =

all: \
    barnes_hut2/doit$(DOIT_SUFFIX) \
    barnes_hut/doit$(DOIT_SUFFIX) \
    boyer/doit$(DOIT_SUFFIX) \
    coresml/doit$(DOIT_SUFFIX) \
    count_graphs/doit$(DOIT_SUFFIX) \
    cpstak/doit$(DOIT_SUFFIX) \
    diviter/doit$(DOIT_SUFFIX) \
    divrec/doit$(DOIT_SUFFIX) \
    fibrepeat/doit$(DOIT_SUFFIX) \
    fft/doit$(DOIT_SUFFIX) \
    gcbench/doit$(DOIT_SUFFIX) \
    knuth_bendix/doit$(DOIT_SUFFIX) \
    lexgen/doit$(DOIT_SUFFIX) \
    life/doit$(DOIT_SUFFIX) \
    logic/doit$(DOIT_SUFFIX) \
    mandelbrot/doit$(DOIT_SUFFIX) \
    mlyacc/doit$(DOIT_SUFFIX) \
    smlyacc/doit$(DOIT_SUFFIX) \
    nucleic/doit$(DOIT_SUFFIX) \
    nqueen/doit$(DOIT_SUFFIX) \
    parallel_matrix/doit$(DOIT_SUFFIX) \
    parallel_matrix_tail/doit$(DOIT_SUFFIX) \
    perm9/doit$(DOIT_SUFFIX) \
    puzzle/doit$(DOIT_SUFFIX) \
    ratio_regions/doit$(DOIT_SUFFIX) \
    ray/doit$(DOIT_SUFFIX) \
    simple/doit$(DOIT_SUFFIX) \
    tsp/doit$(DOIT_SUFFIX) \
    vliw/doit$(DOIT_SUFFIX)

.SUFFIXES: .o .smi .sml

.sml.o:
	$(SMLSHARP) -c -o $@ $<

include link.mk
include depend.mk
