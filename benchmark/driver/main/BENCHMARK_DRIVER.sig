(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BENCHMARK_DRIVER.sig,v 1.2 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
signature BENCHMARK_DRIVER =
sig

  (***************************************************************************)

  (**
   * run benchmarks and emit results to file.
   * @params {prelude, isCompiledPrelude, sourcePaths, resultDirectory}
   * @param prelude path of source file which defines prelude.
   * @param isCompiledPrelude true if prelude is a compiled prelude.
   * @param sourcePaths list of paths of a directory where source files are or
   *              a .sml file. All files in the directory is executed if
   *              directory is specified.
   * @param resultDirectory path of directory where results are output.
   * @return unit
   *)
  val runBenchmarks :
      {
        prelude : string,
        isCompiledPrelude : bool,
        sourcePaths : string list,
        resultDirectory : string
      } -> unit

  (***************************************************************************)

end
