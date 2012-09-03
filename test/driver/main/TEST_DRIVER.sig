(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TEST_DRIVER.sig,v 1.1 2005/03/24 14:58:35 kiyoshiy Exp $
 *)
signature TEST_DRIVER =
sig

  (***************************************************************************)

  (**
   * run test cases and emit results to file.
   * @params {prelude, sourcePaths, resultDirectory, expectedDirectory}
   * @param prelude path of source file which defines preludes.
   * @param sourcePaths list of paths of a directory where source files are or
   *              a .sml file. All files in the directory is executed if
   *              directory is specified.
   * @param expectedDirectory path of directory where files of expected
   *                         outputs are.
   * @param resultDirectory path of directory where results are output.
   * @return unit
   *)
  val runTests :
      {
        prelude : string,
        sourcePaths : string list,
        expectedDirectory : string,
        resultDirectory : string
      } -> unit

  (***************************************************************************)

end
