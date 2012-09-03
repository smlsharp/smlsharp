(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:39 ohori Exp $
 *)
structure Counters :
          sig
              val newLocalID : unit -> VarID.id
          end
  =
struct
   fun newLocalID () = VarID.generate ()
end
