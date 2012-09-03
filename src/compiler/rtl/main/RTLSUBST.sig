(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLSUBST = sig

  (* perform substitution and reconstruct instructions so that
   * each instruction satisfies x86 mnemonic syntax. *)
  val substitute : (RTL.var -> RTL.dst option) -> RTL.graph -> RTL.graph

end
