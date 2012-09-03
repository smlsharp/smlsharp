(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.5 2008/08/06 17:23:40 ohori Exp $
 *)
structure NewVar =
struct

   fun newLocalId () = VarID.generate ()
       
   fun newRBUVar varKind ty = 
       let
         val id =  newLocalId ()
       in
         {varId = Types.INTERNAL id,
          displayName = "$" ^ (VarID.toString id),
          ty = ty,
          varKind = ref varKind}
       end

   fun newATVar ty =
       let
         val id = newLocalId ()
       in
         {displayName = "$" ^ VarID.toString id,
          ty = ty,
          varId = Types.INTERNAL id}
       end

end
