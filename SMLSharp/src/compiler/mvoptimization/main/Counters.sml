(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:40 ohori Exp $
 *)
structure Counters : 
          sig
              type stamp
              val init : stamp -> unit
              val getCounterStamp : unit -> stamp
              val newVar : 'a -> {displayName:string, varId:Types.varId, ty:'a}
              val newLocalId : unit -> LocalVarID.id
          end
  =
struct
   type stamp  = LocalVarID.id

   fun init stamp = LocalVarIDGen.init stamp

   fun getCounterStamp () = LocalVarIDGen.reset ()

   fun newLocalId () = LocalVarIDGen.generate ()

   fun newVar ty = 
      let
          val id = newLocalId()
      in
          {displayName = "$" ^ LocalVarID.toString id, ty = ty, varId = Types.INTERNAL id}
      end

end
