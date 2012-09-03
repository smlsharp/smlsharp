(**
 * abstract instruction generator
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AIGENERATOR.sig,v 1.10 2008/08/05 14:43:59 bochao Exp $
 *)
signature AIGENERATOR =
sig

  (* for YASIGenerator *)
  type globalIndexAllocator =
      {
        find: ExternalVarID.id -> AbstractInstruction.globalIndex option,
        alloc: ExternalVarID.id * ANormal.ty -> unit
      }

  val generate
      : Counters.stamp
        -> globalIndexAllocator option
        -> YAANormal.topdecl list
        -> Counters.stamp * AbstractInstruction.program

end
