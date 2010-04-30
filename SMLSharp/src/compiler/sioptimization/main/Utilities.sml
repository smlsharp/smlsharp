(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: Utilities.sml,v 1.4 2007/09/10 14:13:30 kiyoshiy Exp $
 *)

structure SI = SymbolicInstructions
               
structure Entry_ord:ORD_KEY = struct 
type ord_key = SI.entry
               
fun compare ({id = id1, displayName = displayName1},{id = id2, displayName = displayName2}) =
    ID.compare(id1,id2)
end
  
structure EntryMap = BinaryMapMaker(Entry_ord)
structure EntrySet = BinarySetFn(Entry_ord)
                     
