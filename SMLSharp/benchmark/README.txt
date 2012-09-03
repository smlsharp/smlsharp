IML Benchmark suite.

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.3 2008/01/16 07:31:25 kiyoshiy Exp $

--------------------
1, Overview

 This benchmark suite consists of two components.
  * driver
  * benchmark programs

The driver invokes the IML to execute benchmark programs and records elapsed time.

Constituent files of the benchmark suite are organized in the following directories.

  develop
    +-- benchmark
          +-- bin
          +-- driver
          +-- benchmarks
                +-- barnes-hut
                +-- boyer
                +-- ...

Shell scripts in the 'bin' directory invoke the driver.
The 'driver' directory contains source files of the driver.
Some benchmark programs are provided in the 'benchmarks' directory.

--------------------
2, Running benchmark.

 With shell scripts found in the 'bin' directory, you can invoke the benchmark driver to run benchmark programs.

  $ cd bin
  $ ./runbenchmark.sh \
         -html \
         -remote \
         -d benchresult/coresml \
         ../benchmarks/coresml/load.sml

The benchmark driver processes a program as follows.

  compiler
    (1) compile preludes
    (2) compile benchmark program
    (3) emit bytecodes to an imo file

  runtime
    (4) executes bytecodes in an imo file

The benchmark driver records amount times of (2) and (4).

If you configured SML# at a directory other than iml3/SMLSharp/, you have to specify TOP_BUILDDIR environment.
  $ env TOP_BUILDDIR=/home/yamato/iml3/SMLSharp/release ./runbenchmark.sh ...

--------------------
3, Benchmark result.

 Results of benchmarks are emitted into a report document in some format.

Currently, HTML format printer is implemented.

And, with "-d" option, you can specify the directory into which documents are generated.

--------------------
4, Benchmark programs.

 You can specify any source program to invoke the benchmark driver.

Some benchmark programs are provided in the 'benchmarks' directory.
You can also add new benchmark programs under the 'benchmarks' directory.

--------------------
