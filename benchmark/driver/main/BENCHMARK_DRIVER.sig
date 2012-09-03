(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BENCHMARK_DRIVER.sig,v 1.1 2005/09/05 05:28:12 kiyoshiy Exp $
 *)
signature BENCHMARK_DRIVER =
sig

  (***************************************************************************)

  (**
   * run benchmarks and emit results to file.
   * @params {prelude, sourcePaths, resultDirectory}
   * @param prelude path of source file which defines preludes.
   * @param sourcePaths list of paths of a directory where source files are or
   *              a .sml file. All files in the directory is executed if
   *              directory is specified.
   * @param resultDirectory path of directory where results are output.
   * @return unit
   *)
  val runBenchmarks :
      {
        prelude : string,
        sourcePaths : string list,
        resultDirectory : string
      } -> unit

  (***************************************************************************)

end
