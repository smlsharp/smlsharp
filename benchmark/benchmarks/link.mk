barnes_hut2/doit$(DOIT_SUFFIX): barnes_hut2/doit.o barnes_hut2/main.o barnes_hut2/load.o \
  barnes_hut2/data-io.o barnes_hut2/getparam.o barnes_hut2/grav.o \
  barnes_hut2/space.o barnes_hut2/vector.o barnes_hut2/vector3.o \
  barnes_hut2/rand.o 
	$(SMLSHARP) -o $@ barnes_hut2/doit.smi $(LIBS)
barnes_hut/doit$(DOIT_SUFFIX): barnes_hut/doit.o barnes_hut/main2.o \
  barnes_hut/vector3.o barnes_hut/main.o barnes_hut/load.o \
  barnes_hut/data-io.o barnes_hut/getparam.o barnes_hut/grav.o \
  barnes_hut/space.o barnes_hut/rand.o
	$(SMLSHARP) -o $@ barnes_hut/doit.smi $(LIBS)
boyer/doit$(DOIT_SUFFIX): boyer/doit.o boyer/rules.o boyer/boyer.o boyer/terms.o
	$(SMLSHARP) -o $@ boyer/doit.smi $(LIBS)
coresml/doit$(DOIT_SUFFIX): coresml/fibonacci.o
	$(SMLSHARP) -o $@ coresml/fibonacci.smi $(LIBS)
count_graphs/doit$(DOIT_SUFFIX): count_graphs/doit.o count_graphs/count-graphs.o
	$(SMLSHARP) -o $@ count_graphs/doit.smi $(LIBS)
cpstak/doit$(DOIT_SUFFIX): cpstak/doit.o cpstak/cpstak.o
	$(SMLSHARP) -o $@ cpstak/doit.smi $(LIBS)
diviter/doit$(DOIT_SUFFIX): diviter/doit.o diviter/diviter.o
	$(SMLSHARP) -o $@ diviter/doit.smi $(LIBS)
divrec/doit$(DOIT_SUFFIX): divrec/doit.o divrec/divrec.o
	$(SMLSHARP) -o $@ divrec/doit.smi $(LIBS)
fft/doit$(DOIT_SUFFIX): fft/doit.o fft/fft.o
	$(SMLSHARP) -o $@ fft/doit.smi $(LIBS)
gcbench/doit$(DOIT_SUFFIX): gcbench/doit.o gcbench/gcbench.o
	$(SMLSHARP) -o $@ gcbench/doit.smi $(LIBS)
knuth_bendix/doit$(DOIT_SUFFIX): knuth_bendix/doit.o knuth_bendix/knuth-bendix.o
	$(SMLSHARP) -o $@ knuth_bendix/doit.smi $(LIBS)
lexgen/doit$(DOIT_SUFFIX): lexgen/doit.o lexgen/lexgen.o
	$(SMLSHARP) -o $@ lexgen/doit.smi $(LIBS)
life/doit$(DOIT_SUFFIX): life/doit.o life/life.o
	$(SMLSHARP) -o $@ life/doit.smi $(LIBS)
logic/doit$(DOIT_SUFFIX): logic/doit.o logic/main.o logic/data.o logic/unify.o \
  logic/trail.o logic/term.o
	$(SMLSHARP) -o $@ logic/doit.smi $(LIBS)
mandelbrot/doit$(DOIT_SUFFIX): mandelbrot/doit.o mandelbrot/mandelbrot.o
	$(SMLSHARP) -o $@ mandelbrot/doit.smi $(LIBS)
mlyacc/doit$(DOIT_SUFFIX): mlyacc/doit.o mlyacc/main.o mlyacc/link.o \
  mlyacc/yacc.o mlyacc/absyn.o mlyacc/shrink.o mlyacc/verbose.o \
  mlyacc/mkprstruct.o mlyacc/mklrtable.o mlyacc/lalr.o mlyacc/look.o \
  mlyacc/graph.o mlyacc/coreutils.o mlyacc/core.o mlyacc/grammar.o \
  mlyacc/utils.o mlyacc/parse.o mlyacc/yacc.lex.o mlyacc/yacc.grm.o \
  mlyacc/hdr.o mlyacc/parser2.o mlyacc/stream.o mlyacc/join.o mlyacc/lrtable.o
	$(SMLSHARP) -o $@ mlyacc/doit.smi $(LIBS)
nqueen/doit$(DOIT_SUFFIX): nqueen/doit.o nqueen/nqueen.o
	$(SMLSHARP) -o $@ nqueen/doit.smi $(LIBS)
nucleic/doit$(DOIT_SUFFIX): nucleic/doit.o nucleic/main.o nucleic/nucleic.o
	$(SMLSHARP) -o $@ nucleic/doit.smi $(LIBS)
perm9/doit$(DOIT_SUFFIX): perm9/doit.o perm9/perm9.o
	$(SMLSHARP) -o $@ perm9/doit.smi $(LIBS)
puzzle/doit$(DOIT_SUFFIX): puzzle/doit.o puzzle/puzzle.o
	$(SMLSHARP) -o $@ puzzle/doit.smi $(LIBS)
ratio_regions/doit$(DOIT_SUFFIX): ratio_regions/doit.o \
  ratio_regions/ratio-regions.o
	$(SMLSHARP) -o $@ ratio_regions/doit.smi $(LIBS)
ray/doit$(DOIT_SUFFIX): ray/doit.o ray/main.o ray/interface.o ray/interp.o \
  ray/ray.o ray/objects.o
	$(SMLSHARP) -o $@ ray/doit.smi $(LIBS)
simple/doit$(DOIT_SUFFIX): simple/doit.o simple/main.o simple/simple.o \
  simple/control.o simple/array2.o
	$(SMLSHARP) -o $@ simple/doit.smi $(LIBS)
smlyacc/doit$(DOIT_SUFFIX): smlyacc/doit.o smlyacc/main.o
	$(SMLSHARP) -o $@ smlyacc/doit.smi $(LIBS)
tsp/doit$(DOIT_SUFFIX): tsp/doit.o tsp/main.o tsp/tsp.o tsp/build.o tsp/rand.o \
  tsp/lib-base.o tsp/tree.o
	$(SMLSHARP) -o $@ tsp/doit.smi $(LIBS)
vliw/doit$(DOIT_SUFFIX): vliw/doit.o vliw/vliw.o
	$(SMLSHARP) -o $@ vliw/doit.smi $(LIBS)
