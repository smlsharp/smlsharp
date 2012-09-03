(**
 * abstract instruction generator version 2
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AIGENERATOR.sig,v 1.10 2008/08/05 14:43:59 bochao Exp $
 *)
signature AIGENERATOR2 =
sig

  val generate
      : YAANormal.topdecl list
        -> AbstractInstruction2.program

end
