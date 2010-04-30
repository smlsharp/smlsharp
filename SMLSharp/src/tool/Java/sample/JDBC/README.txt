JDBC sample code.

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.3 2007/11/29 05:52:12 kiyoshiy Exp $

Program codes in this directory are sample code using JDBC to access RDB.
To run these samples, 

----------
Preparation.

1, get CSVJDBC driver, which is available at
  http://sourceforge.net/projects/csvjdbc/

  Because CSVJDBC is distributed under LGPL, we do not include it in SML#
 package.

2, extract the csvjdbc package, and put csvjdbc.jar into this directory.

  SMLSharp/src/tool/Java/sample/JDBC/csvjdbc.jar

3, run make_sample.sh to generate SML wrapper codes for JDBC classes.
  $ ./make_sample.sh

----------
Run.

1, start SML#.
  $ smlsharp

2, load CSVJDBCTest.sml
  # use "./CSVJDBCTest.sml"

  and call main function.
  # main ();
  NAME = OO   TYPE = C++
  NAME = Functional   TYPE = ML
  NAME = Functional   TYPE = Haskell
  NAME = OO   TYPE = Ruby
  val it = () : unit

  This result shows contents from tables/languages.csv.

----------
