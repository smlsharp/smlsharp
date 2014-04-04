(**
 * This module runs test cases and makes report of their results.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: TESTRUNNER.sig,v 1.2 2004/10/20 02:09:35 kiyoshiy Exp $
 *)
signature TESTRUNNER =
sig
  
  (***************************************************************************)

  (**
   * implementation specific parameter to runTest function.
   *)
  type parameter

  (**
   *  perform tests
   * @params parameter test
   * @param parameter implementation specific parameter
   * @param test to perform
   *)
  val runTest : parameter -> Test.test -> unit

  (***************************************************************************)

end