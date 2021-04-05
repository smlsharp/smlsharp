SML# - a new language in the ML family
======================================

Overview
--------

SML# is a new generation of the Standard ML family of programming
languages being developed at Research Institute of Electrical
Communication, Tohoku University. Its design goal is to provide a
moderate but practically important extensions based on recent advance
in type theory for ML-style languages while maintaining the
compatibility of the Definition of Standard ML.

The main features of SML# include the following.

* record polymorphism

  The type system of SML# fully supports record polymorphism.
  Moreover, its type directed compiler generates efficient code for
  polymorphic record operations.

* integration with SQL

  SQL expressions themselves are integrated as polymorphically-typed
  first-class citizens. This allows the programmer to construct SQL
  queries through ML's higher-order functions and access directly to
  database management systems with enjoying type safety.

* interoperability with C

  SML# program is highly interoperable with C. For example, SML#
  program can directly link with C libraires and call C functions
  without any data conversion.

* Separate compilation and linking

  By writing an interface file, each source file is compiled separately
  into an object file in the standard format. The separately compiled
  object files are then linked together into an executable program.

* Multithread support

  The non-moving GC and direct C interface allow SML# program to
  directly call the Pthread and MassiveThreads library. As far as the
  thread libraries support multicore CPUs, SML# program automatically
  obtains multithread capability on multicore CPUs.

SML# is an extension of the Definition of Standard ML. It supports
the full set of the language and the required set of the Standard ML
Basis Library. The programmer can enjoy the new features with a rich
collection of existing library for Standard ML.

How to build
------------

SML# works on x86_64 (amd64) Linux and macOS.

The following libraries are required:

* GMP
* MassiveThreads 1.00
* LLVM 3.9.1 or above

After setting up the above libraries, you can build and install the
SML# compiler and tools in the following popular three steps:

    ./configure && make && make install

See the SML# document for details.

License
-------

The SML# Compiler and its supporting tools are open source software
being distributed under the MIT license, as described
in the file "LICENSE" included in this distribution package.

Third-party source code used and/or included
--------------------------------------------

SML# contains the following third-party's source code:

* ML-yacc, derived from Standard ML of New Jersey (SML/NJ) 110.73
* ML-lex, derived from SML/NJ 110.73
* Some of the Basis Library structures, derived from SML/NJ 110.73
* The SML/NJ Library, derived from SML/NJ 110.99
* dtoa.c imported from the NetLib
* benchmark progarms, derived from SML/NJ and the Larceny project.

All of them are software distributed under open-source licenses
compatible with the SML# license.  The SML# source code distribution
includes the license of each of them.

Documentation
-------------

The SML# document is available from the [SML# website].
It contains the tutorial on Standard ML, the tour on the SML#'s new
features, and the reference manual of the compiler and its supporing
tools.

[SML# website]: https://smlsharp.github.io/

Contact information
-------------------

There are places for developers and users to have talks about SML#.
* [smlsharp/forum/discussions] (English)
* [smlsharp/forum_ja/discussions] (Japanese)

Issues and Pull requests are always welcome on GitHub.
See the ["Development" page] of the SML# website for details.


[smlsharp/forum/discussions]: https://github.com/smlsharp/forum/discussions
[smlsharp/forum_ja/discussions]: https://github.com/smlsharp/forum_ja/discussions
["Development" page]: https://smlsharp.github.io/en/development/
