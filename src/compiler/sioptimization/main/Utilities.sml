(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: Utilities.sml,v 1.2 2006/02/28 16:11:06 kiyoshiy Exp $
 *)

structure SI = SymbolicInstructions
               
structure Entry_ord:ordsig = struct 
type ord_key = SI.entry
               
fun compare ({id = id1, displayName = displayName1},{id = id2, displayName = displayName2}) =
    ID.compare(id1,id2)
end
  
structure EntryMap = BinaryMapFn(Entry_ord)
structure EntrySet = BinarySetFn(Entry_ord)
                     
