(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLSELECT = sig

  val select :
      int option   (* compile unit stamp *)
      -> AbstractInstruction2.program
      -> RTL.program

end
