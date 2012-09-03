(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLSELECT = sig

  val select :
      {mainSymbol: string} * AbstractInstruction2.program
      -> RTL.program

end
