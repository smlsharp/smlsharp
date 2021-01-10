CC = gcc -pthread
CFLAGS = -Wall -W -O2
CPPFLAGS = -I_thread -Imassivethreads/include
LDFLAGS = -Lmassivethreads/lib
SMLSHARP = ../../src/compiler/smlsharp -B../../src
SMLFLAGS = -O2
GHC = ~/work/ghc-8.10.2/o/bin/ghc
GHCFLAGS = -O2
GO = ~/work/go/bin/go
JAVAC = javac
PMLC = ~/work/manticore/o/bin/pmlc
MPL = ~/work/mpl/build/bin/mpl
OCAMLFIND = ocamlfind

all: \
fib/fib_c_myth \
fib/fib_c_pthread \
fib/fib_c_seq \
fib/fib_smlsharp_myth \
fib/fib_smlsharp_pthread \
fib/fib_smlsharp_seq \
fib/fib_ghc_par \
fib/fib_go_value \
fib/FibJavaForkJoin.class \
fib/FibJavaSeq.class \
fib/fib_manticore_ptuple \
fib/fib_maple_par \
fib/fib_ocaml_domainslib \
nqueen/nqueen_c_myth \
nqueen/nqueen_c_pthread \
nqueen/nqueen_c_seq \
nqueen/nqueen_smlsharp_myth \
nqueen/nqueen_smlsharp_pthread \
nqueen/nqueen_smlsharp_seq \
nqueen/nqueen_ghc_par \
nqueen/nqueen_go_ref \
nqueen/nqueen_go_value \
nqueen/NqueenJavaForkJoin.class \
nqueen/NqueenJavaSeq.class \
nqueen/nqueen_manticore_ptuple \
nqueen/nqueen_maple_par \
nqueen/nqueen_ocaml_domainslib \
mandelbrot/mandelbrot_c_myth \
mandelbrot/mandelbrot_c_pthread \
mandelbrot/mandelbrot_c_seq \
mandelbrot/mandelbrot_smlsharp_myth \
mandelbrot/mandelbrot_smlsharp_pthread \
mandelbrot/mandelbrot_smlsharp_seq \
mandelbrot/mandelbrot_ghc_par \
mandelbrot/mandelbrot_ghc_forkIO \
mandelbrot/mandelbrot_go_value \
mandelbrot/MandelbrotJavaForkJoin.class \
mandelbrot/MandelbrotJavaSeq.class \
mandelbrot/mandelbrot_manticore_ptuple \
mandelbrot/mandelbrot_maple_par \
mandelbrot/mandelbrot_ocaml_domainslib \
cilksort/cilksort_c_myth \
cilksort/cilksort_c_pthread \
cilksort/cilksort_c_seq \
cilksort/cilksort_smlsharp_myth \
cilksort/cilksort_smlsharp_pthread \
cilksort/cilksort_smlsharp_seq \
cilksort/cilksort_manticore_ptuple \
cilksort/cilksort_maple_par \
cilksort/cilksort_ghc_par \
cilksort/cilksort_ghc_forkIO \
cilksort/cilksort_go_value \
cilksort/CilksortJavaForkJoin.class \
cilksort/CilksortJavaSeq.class \
cilksort/cilksort_ocaml_domainslib

clean:
	rm -f _thread/thread_c_myth.o
	rm -f _thread/thread_c_pthread.o
	rm -f _thread/thread_c_seq.o
	rm -f _thread/thread_smlsharp_myth.o
	rm -f _thread/thread_smlsharp_pthread.o
	rm -f _thread/thread_smlsharp_seq.o
	rm -f fib/fib_c_thread.o
	rm -f fib/fib_c_myth
	rm -f fib/fib_c_pthread
	rm -f fib/fib_c_seq
	rm -f fib/fib_smlsharp_thread.o
	rm -f fib/fib_smlsharp_myth
	rm -f fib/fib_smlsharp_pthread
	rm -f fib/fib_smlsharp_seq
	rm -f fib/fib_ghc_par.hi
	rm -f fib/fib_ghc_par.o
	rm -f fib/fib_ghc_par
	rm -f fib/fib_go_value
	rm -f fib/FibJavaForkJoin.class
	rm -f fib/FibJavaSeq.class
	rm -f fib/fib_manticore_ptuple.s
	rm -f fib/fib_manticore_ptuple
	rm -f fib/fib_maple_par
	rm -f fib/fib_ocaml_domainslib
	rm -f fib/fib_ocaml_domainslib.cmi
	rm -f fib/fib_ocaml_domainslib.cmx
	rm -f fib/fib_ocaml_domainslib.o
	rm -f nqueen/nqueen_c_thread.o
	rm -f nqueen/nqueen_c_myth
	rm -f nqueen/nqueen_c_pthread
	rm -f nqueen/nqueen_c_seq
	rm -f nqueen/nqueen_smlsharp_thread.o
	rm -f nqueen/nqueen_smlsharp_myth
	rm -f nqueen/nqueen_smlsharp_pthread
	rm -f nqueen/nqueen_smlsharp_seq
	rm -f nqueen/nqueen_ghc_par.hi
	rm -f nqueen/nqueen_ghc_par.o
	rm -f nqueen/nqueen_ghc_par
	rm -f nqueen/nqueen_go_ref
	rm -f nqueen/nqueen_go_value
	rm -f nqueen/NqueenJavaForkJoin.class
	rm -f nqueen/NqueenJavaForkJoin\$$Board.class
	rm -f nqueen/NqueenJavaSeq.class
	rm -f nqueen/NqueenJavaSeq\$$Board.class
	rm -f nqueen/nqueen_manticore_ptuple.s
	rm -f nqueen/nqueen_manticore_ptuple
	rm -f nqueen/nqueen_maple_par
	rm -f nqueen/nqueen_ocaml_domainslib
	rm -f nqueen/nqueen_ocaml_domainslib.cmi
	rm -f nqueen/nqueen_ocaml_domainslib.cmx
	rm -f nqueen/nqueen_ocaml_domainslib.o
	rm -f mandelbrot/mandelbrot_c_thread.o
	rm -f mandelbrot/mandelbrot_c_myth
	rm -f mandelbrot/mandelbrot_c_pthread
	rm -f mandelbrot/mandelbrot_c_seq
	rm -f mandelbrot/mandelbrot_smlsharp_thread.o
	rm -f mandelbrot/mandelbrot_smlsharp_myth
	rm -f mandelbrot/mandelbrot_smlsharp_pthread
	rm -f mandelbrot/mandelbrot_smlsharp_seq
	rm -f mandelbrot/mandelbrot_ghc_par.hi
	rm -f mandelbrot/mandelbrot_ghc_par.o
	rm -f mandelbrot/mandelbrot_ghc_par
	rm -f mandelbrot/mandelbrot_ghc_forkIO.hi
	rm -f mandelbrot/mandelbrot_ghc_forkIO.o
	rm -f mandelbrot/mandelbrot_ghc_forkIO
	rm -f mandelbrot/mandelbrot_go_value
	rm -f mandelbrot/mandelbrot_manticore_ptuple.s
	rm -f mandelbrot/mandelbrot_manticore_ptuple
	rm -f mandelbrot/mandelbrot_maple_par
	rm -f mandelbrot/MandelbrotJavaForkJoin.class
	rm -f mandelbrot/MandelbrotJavaSeq.class
	rm -f mandelbrot/mandelbrot_ocaml_domainslib
	rm -f mandelbrot/mandelbrot_ocaml_domainslib.cmi
	rm -f mandelbrot/mandelbrot_ocaml_domainslib.cmx
	rm -f mandelbrot/mandelbrot_ocaml_domainslib.o
	rm -f cilksort/cilksort_c_thread.o
	rm -f cilksort/cilksort_c_myth
	rm -f cilksort/cilksort_c_pthread
	rm -f cilksort/cilksort_c_seq
	rm -f cilksort/cilksort_smlsharp_thread.o
	rm -f cilksort/cilksort_smlsharp_myth
	rm -f cilksort/cilksort_smlsharp_pthread
	rm -f cilksort/cilksort_smlsharp_seq
	rm -f cilksort/cilksort_manticore_ptuple.s
	rm -f cilksort/cilksort_manticore_ptuple
	rm -f cilksort/cilksort_maple_par
	rm -f cilksort/cilksort_ghc_par.hi
	rm -f cilksort/cilksort_ghc_par.o
	rm -f cilksort/cilksort_ghc_par
	rm -f cilksort/cilksort_ghc_forkIO.hi
	rm -f cilksort/cilksort_ghc_forkIO.o
	rm -f cilksort/cilksort_ghc_forkIO
	rm -f cilksort/cilksort_go_value
	rm -f cilksort/CilksortJavaForkJoin.class
	rm -f cilksort/CilksortJavaForkJoin\$$Merge.class
	rm -f cilksort/CilksortJavaForkJoin\$$SortMerge.class
	rm -f cilksort/CilksortJavaSeq.class
	rm -f cilksort/cilksort_ocaml_domainslib
	rm -f cilksort/cilksort_ocaml_domainslib.cmi
	rm -f cilksort/cilksort_ocaml_domainslib.cmx
	rm -f cilksort/cilksort_ocaml_domainslib.o

bench: all bench.sh
	sh bench.sh

_thread/thread_c_myth.o: _thread/thread_c_myth.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ _thread/thread_c_myth.c
_thread/thread_c_pthread.o: _thread/thread_c_pthread.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ _thread/thread_c_pthread.c
_thread/thread_c_seq.o: _thread/thread_c_seq.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ _thread/thread_c_seq.c
_thread/thread_smlsharp_myth.o: _thread/thread_smlsharp_myth.sml _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ _thread/thread_smlsharp_myth.sml
_thread/thread_smlsharp_pthread.o: _thread/thread_smlsharp_pthread.sml _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ _thread/thread_smlsharp_pthread.sml
_thread/thread_smlsharp_seq.o: _thread/thread_smlsharp_seq.sml _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ _thread/thread_smlsharp_seq.sml

fib/fib_c_thread.o: fib/fib_c_thread.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ fib/fib_c_thread.c
fib/fib_c_myth: _thread/thread_c_myth.o fib/fib_c_thread.o
	$(CC) $(LDFLAGS) -o $@ fib/fib_c_thread.o _thread/thread_c_myth.o -lmyth
fib/fib_c_pthread: _thread/thread_c_pthread.o fib/fib_c_thread.o
	$(CC) $(LDFLAGS) -o $@ fib/fib_c_thread.o _thread/thread_c_pthread.o -pthread
fib/fib_c_seq: _thread/thread_c_seq.o fib/fib_c_thread.o
	$(CC) $(LDFLAGS) -o $@ fib/fib_c_thread.o _thread/thread_c_seq.o
fib/fib_smlsharp_thread.o: fib/fib_smlsharp_thread.sml fib/fib_smlsharp_thread.smi _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ fib/fib_smlsharp_thread.sml
fib/fib_smlsharp_myth: fib/fib_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o fib/fib_smlsharp_thread.o smlsharp_myth.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ fib/fib_smlsharp_thread.smi -lmyth
fib/fib_smlsharp_pthread: fib/fib_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_pthread.o fib/fib_smlsharp_thread.o smlsharp_pthread.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_pthread.filemap -o $@ fib/fib_smlsharp_thread.smi
fib/fib_smlsharp_seq: fib/fib_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o fib/fib_smlsharp_thread.o smlsharp_seq.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ fib/fib_smlsharp_thread.smi
fib/fib_ghc_par: fib/fib_ghc_par.hs
	$(GHC) -threaded $(GHCFLAGS) fib/fib_ghc_par.hs
fib/fib_go_value: fib/fib_go_value.go
	$(GO) build -o $@ fib/fib_go_value.go
fib/FibJavaForkJoin.class: fib/fib_java_forkjoin.java
	$(JAVAC) fib/fib_java_forkjoin.java
fib/FibJavaSeq.class: fib/fib_java_seq.java
	$(JAVAC) fib/fib_java_seq.java
fib/fib_manticore_ptuple: fib/fib_manticore_ptuple.pml
	$(PMLC) -o $@ fib/fib_manticore_ptuple.pml
fib/fib_maple_par: fib/fib_maple_par.sml fib/fib_maple_par.mlb
	$(MPL) fib/fib_maple_par.mlb
fib/fib_ocaml_domainslib: fib/fib_ocaml_domainslib.ml
	$(OCAMLFIND) ocamlopt -linkpkg -package domainslib,unix -o $@ -O2 fib/fib_ocaml_domainslib.ml

nqueen/nqueen_c_thread.o: nqueen/nqueen_c_thread.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ nqueen/nqueen_c_thread.c
nqueen/nqueen_c_myth: _thread/thread_c_myth.o nqueen/nqueen_c_thread.o
	$(CC) $(LDFLAGS) -o $@ nqueen/nqueen_c_thread.o _thread/thread_c_myth.o -lmyth
nqueen/nqueen_c_pthread: _thread/thread_c_pthread.o nqueen/nqueen_c_thread.o
	$(CC) $(LDFLAGS) -o $@ nqueen/nqueen_c_thread.o _thread/thread_c_pthread.o -pthread
nqueen/nqueen_c_seq: _thread/thread_c_seq.o nqueen/nqueen_c_thread.o
	$(CC) $(LDFLAGS) -o $@ nqueen/nqueen_c_thread.o _thread/thread_c_seq.o
nqueen/nqueen_smlsharp_thread.o: nqueen/nqueen_smlsharp_thread.sml nqueen/nqueen_smlsharp_thread.smi _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ nqueen/nqueen_smlsharp_thread.sml
nqueen/nqueen_smlsharp_myth: nqueen/nqueen_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o nqueen/nqueen_smlsharp_thread.o smlsharp_myth.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ nqueen/nqueen_smlsharp_thread.smi -lmyth
nqueen/nqueen_smlsharp_pthread: nqueen/nqueen_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_pthread.o nqueen/nqueen_smlsharp_thread.o smlsharp_pthread.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_pthread.filemap -o $@ nqueen/nqueen_smlsharp_thread.smi
nqueen/nqueen_smlsharp_seq: nqueen/nqueen_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o nqueen/nqueen_smlsharp_thread.o smlsharp_seq.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ nqueen/nqueen_smlsharp_thread.smi
nqueen/nqueen_ghc_par: nqueen/nqueen_ghc_par.hs
	$(GHC) -threaded $(GHCFLAGS) nqueen/nqueen_ghc_par.hs
nqueen/nqueen_go_value: nqueen/nqueen_go_value.go
	$(GO) build -o $@ nqueen/nqueen_go_value.go
nqueen/nqueen_go_ref: nqueen/nqueen_go_ref.go
	$(GO) build -o $@ nqueen/nqueen_go_ref.go
nqueen/NqueenJavaForkJoin.class: nqueen/nqueen_java_forkjoin.java
	$(JAVAC) nqueen/nqueen_java_forkjoin.java
nqueen/NqueenJavaSeq.class: nqueen/nqueen_java_seq.java
	$(JAVAC) nqueen/nqueen_java_seq.java
nqueen/nqueen_manticore_ptuple: nqueen/nqueen_manticore_ptuple.pml
	$(PMLC) -o $@ nqueen/nqueen_manticore_ptuple.pml
nqueen/nqueen_maple_par: nqueen/nqueen_maple_par.sml nqueen/nqueen_maple_par.mlb
	$(MPL) nqueen/nqueen_maple_par.mlb
nqueen/nqueen_ocaml_domainslib: nqueen/nqueen_ocaml_domainslib.ml
	$(OCAMLFIND) ocamlopt -linkpkg -package domainslib,unix -o $@ -O2 nqueen/nqueen_ocaml_domainslib.ml

mandelbrot/mandelbrot_c_thread.o: mandelbrot/mandelbrot_c_thread.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ mandelbrot/mandelbrot_c_thread.c
mandelbrot/mandelbrot_c_myth: _thread/thread_c_myth.o mandelbrot/mandelbrot_c_thread.o
	$(CC) $(LDFLAGS) -o $@ mandelbrot/mandelbrot_c_thread.o _thread/thread_c_myth.o -lmyth
mandelbrot/mandelbrot_c_pthread: _thread/thread_c_pthread.o mandelbrot/mandelbrot_c_thread.o
	$(CC) $(LDFLAGS) -o $@ mandelbrot/mandelbrot_c_thread.o _thread/thread_c_pthread.o -pthread
mandelbrot/mandelbrot_c_seq: _thread/thread_c_seq.o mandelbrot/mandelbrot_c_thread.o
	$(CC) $(LDFLAGS) -o $@ mandelbrot/mandelbrot_c_thread.o _thread/thread_c_seq.o
mandelbrot/mandelbrot_smlsharp_thread.o: mandelbrot/mandelbrot_smlsharp_thread.sml mandelbrot/mandelbrot_smlsharp_thread.smi _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ mandelbrot/mandelbrot_smlsharp_thread.sml
mandelbrot/mandelbrot_smlsharp_myth: mandelbrot/mandelbrot_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o mandelbrot/mandelbrot_smlsharp_thread.o smlsharp_myth.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ mandelbrot/mandelbrot_smlsharp_thread.smi -lmyth
mandelbrot/mandelbrot_smlsharp_pthread: mandelbrot/mandelbrot_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_pthread.o mandelbrot/mandelbrot_smlsharp_thread.o smlsharp_pthread.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_pthread.filemap -o $@ mandelbrot/mandelbrot_smlsharp_thread.smi
mandelbrot/mandelbrot_smlsharp_seq: mandelbrot/mandelbrot_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o mandelbrot/mandelbrot_smlsharp_thread.o smlsharp_seq.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ mandelbrot/mandelbrot_smlsharp_thread.smi
mandelbrot/mandelbrot_ghc_par: mandelbrot/mandelbrot_ghc_par.hs
	$(GHC) -threaded $(GHCFLAGS) mandelbrot/mandelbrot_ghc_par.hs
mandelbrot/mandelbrot_ghc_forkIO: mandelbrot/mandelbrot_ghc_forkIO.hs
	$(GHC) -threaded $(GHCFLAGS) mandelbrot/mandelbrot_ghc_forkIO.hs
mandelbrot/mandelbrot_go_value: mandelbrot/mandelbrot_go_value.go
	$(GO) build -o $@ mandelbrot/mandelbrot_go_value.go
mandelbrot/MandelbrotJavaForkJoin.class: mandelbrot/mandelbrot_java_forkjoin.java
	$(JAVAC) mandelbrot/mandelbrot_java_forkjoin.java
mandelbrot/MandelbrotJavaSeq.class: mandelbrot/mandelbrot_java_seq.java
	$(JAVAC) mandelbrot/mandelbrot_java_seq.java
mandelbrot/mandelbrot_manticore_ptuple: mandelbrot/mandelbrot_manticore_ptuple.pml
	$(PMLC) -o $@ mandelbrot/mandelbrot_manticore_ptuple.pml
mandelbrot/mandelbrot_maple_par: mandelbrot/mandelbrot_maple_par.sml mandelbrot/mandelbrot_maple_par.mlb
	$(MPL) mandelbrot/mandelbrot_maple_par.mlb
mandelbrot/mandelbrot_ocaml_domainslib: mandelbrot/mandelbrot_ocaml_domainslib.ml
	$(OCAMLFIND) ocamlopt -linkpkg -package domainslib,unix -o $@ -O2 mandelbrot/mandelbrot_ocaml_domainslib.ml

cilksort/cilksort_c_thread.o: cilksort/cilksort_c_thread.c _thread/thread_c.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ cilksort/cilksort_c_thread.c
cilksort/cilksort_c_myth: _thread/thread_c_myth.o cilksort/cilksort_c_thread.o
	$(CC) $(LDFLAGS) -o $@ cilksort/cilksort_c_thread.o _thread/thread_c_myth.o -lmyth
cilksort/cilksort_c_pthread: _thread/thread_c_pthread.o cilksort/cilksort_c_thread.o
	$(CC) $(LDFLAGS) -o $@ cilksort/cilksort_c_thread.o _thread/thread_c_pthread.o -pthread
cilksort/cilksort_c_seq: _thread/thread_c_seq.o cilksort/cilksort_c_thread.o
	$(CC) $(LDFLAGS) -o $@ cilksort/cilksort_c_thread.o _thread/thread_c_seq.o
cilksort/cilksort_smlsharp_thread.o: cilksort/cilksort_smlsharp_thread.sml cilksort/cilksort_smlsharp_thread.smi _thread/thread_smlsharp.smi
	$(SMLSHARP) $(SMLFLAGS) -c -o $@ cilksort/cilksort_smlsharp_thread.sml
cilksort/cilksort_smlsharp_myth: cilksort/cilksort_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o cilksort/cilksort_smlsharp_thread.o smlsharp_myth.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ cilksort/cilksort_smlsharp_thread.smi -lmyth
cilksort/cilksort_smlsharp_pthread: cilksort/cilksort_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_pthread.o cilksort/cilksort_smlsharp_thread.o smlsharp_pthread.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_pthread.filemap -o $@ cilksort/cilksort_smlsharp_thread.smi
cilksort/cilksort_smlsharp_seq: cilksort/cilksort_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o cilksort/cilksort_smlsharp_thread.o smlsharp_seq.filemap
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ cilksort/cilksort_smlsharp_thread.smi
cilksort/cilksort_ghc_par: cilksort/cilksort_ghc_par.hs
	$(GHC) -threaded $(GHCFLAGS) cilksort/cilksort_ghc_par.hs
cilksort/cilksort_ghc_forkIO: cilksort/cilksort_ghc_forkIO.hs
	$(GHC) -threaded $(GHCFLAGS) cilksort/cilksort_ghc_forkIO.hs
cilksort/cilksort_go_value: cilksort/cilksort_go_value.go
	$(GO) build -o $@ cilksort/cilksort_go_value.go
cilksort/CilksortJavaForkJoin.class: cilksort/cilksort_java_forkjoin.java
	$(JAVAC) cilksort/cilksort_java_forkjoin.java
cilksort/CilksortJavaSeq.class: cilksort/cilksort_java_seq.java
	$(JAVAC) cilksort/cilksort_java_seq.java
cilksort/cilksort_manticore_ptuple: cilksort/cilksort_manticore_ptuple.pml
	$(PMLC) -o $@ cilksort/cilksort_manticore_ptuple.pml
cilksort/cilksort_maple_par: cilksort/cilksort_maple_par.sml cilksort/cilksort_maple_par.mlb
	$(MPL) cilksort/cilksort_maple_par.mlb
cilksort/cilksort_ocaml_domainslib: cilksort/cilksort_ocaml_domainslib.ml
	$(OCAMLFIND) ocamlopt -linkpkg -package domainslib,unix -o $@ -O2 cilksort/cilksort_ocaml_domainslib.ml







smlsharp-3.5.0.tar.gz:
	curl -O https://www.pllab.riec.tohoku.ac.jp/smlsharp/download/$@

smlsharp-3.5.0/src/runtime/libsmlsharp.a: smlsharp-3.5.0.tar.gz
	-rm -rf smlsharp-3.5.0
	tar -xzf smlsharp-3.5.0.tar.gz
	cp ../../config.status smlsharp-3.5.0/
	(cd smlsharp-3.5.0 && ./config.status --recheck && ./config.status)
	sed -i.orig -e '/^DEFS =/s/$$/ -DGCTIME/' smlsharp-3.5.0/config.mk
	(cd smlsharp-3.5.0 && make runtime)

smlsharp35: \
 fib/fib_smlsharp35_seq \
 fib/fib_smlsharp35_myth \
 nqueen/nqueen_smlsharp35_seq \
 nqueen/nqueen_smlsharp35_myth \
 mandelbrot/mandelbrot_smlsharp35_seq \
 mandelbrot/mandelbrot_smlsharp35_myth \
 cilksort/cilksort_smlsharp35_seq \
 cilksort/cilksort_smlsharp35_myth

fib/fib_smlsharp35_seq: fib/fib_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o fib/fib_smlsharp_thread.o smlsharp_seq.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o fib/fib_smlsharp_thread.smi smlsharp-3.5.0/src/runtime/libsmlsharp.a
fib/fib_smlsharp35_myth: fib/fib_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o fib/fib_smlsharp_thread.o smlsharp_myth.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o fib/fib_smlsharp_thread.smi smlsharp-3.5.0/src/runtime/libsmlsharp.a -lmyth
nqueen/nqueen_smlsharp35_seq: nqueen/nqueen_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o nqueen/nqueen_smlsharp_thread.o smlsharp_seq.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o nqueen/nqueen_smlsharp_thread.smi smlsharp-3.5.0/src/runtime/libsmlsharp.a
nqueen/nqueen_smlsharp35_myth: nqueen/nqueen_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o nqueen/nqueen_smlsharp_thread.o smlsharp_myth.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o nqueen/nqueen_smlsharp_thread.smi -lmyth smlsharp-3.5.0/src/runtime/libsmlsharp.a
mandelbrot/mandelbrot_smlsharp35_seq: mandelbrot/mandelbrot_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o mandelbrot/mandelbrot_smlsharp_thread.o smlsharp_seq.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o mandelbrot/mandelbrot_smlsharp_thread.smi smlsharp-3.5.0/src/runtime/libsmlsharp.a
mandelbrot/mandelbrot_smlsharp35_myth: mandelbrot/mandelbrot_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o mandelbrot/mandelbrot_smlsharp_thread.o smlsharp_myth.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o mandelbrot/mandelbrot_smlsharp_thread.smi smlsharp-3.5.0/src/runtime/libsmlsharp.a -lmyth
cilksort/cilksort_smlsharp35_seq: cilksort/cilksort_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_seq.o cilksort/cilksort_smlsharp_thread.o smlsharp_seq.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_seq.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o cilksort/cilksort_smlsharp_thread.smi smlsharp-3.5.0/src/runtime/libsmlsharp.a
cilksort/cilksort_smlsharp35_myth: cilksort/cilksort_smlsharp_thread.smi _thread/thread_smlsharp.smi _thread/thread_smlsharp_myth.o cilksort/cilksort_smlsharp_thread.o smlsharp_myth.filemap smlsharp-3.5.0/src/runtime/libsmlsharp.a
	$(SMLSHARP) $(LDFLAGS) -filemap=smlsharp_myth.filemap -o $@ -nostdlib smlsharp-3.5.0/src/runtime/main.o cilksort/cilksort_smlsharp_thread.smi -lmyth smlsharp-3.5.0/src/runtime/libsmlsharp.a
