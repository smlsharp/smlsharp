(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: SubFunctions.sml,v 1.3 2007/06/16 14:30:04 matsu Exp $
 *)

structure Aux = struct
  open SymbolicInstructions
  structure EntryOrd =
  struct 
  type ord_key = entry
  fun  compare (e1:entry,e2:entry) = ID.compare (#id e1, #id e2)
  end
  
  (* set of variables *)
  structure Lvars = SplaySetFn (EntryOrd)

  (* variable map *)                              
  structure VarMap = SplayMapFn (EntryOrd)                  

     
structure CfgKey : ORD_KEY =
struct
type ord_key = int * int
fun compare (k1 as (f1,s1), k2 as (f2,s2)) = let val cp = Int.compare (f1,f2)
                                             in if cp = EQUAL 
                                                then Int.compare (s1,s2)
                                                else cp
                                             end
end

structure CFG = SplaySetFn(CfgKey):ORD_SET


structure adrOrd =
struct 
type ord_key = address
fun  compare (e1:address,e2:address) = ID.compare (e1, e2)
end

structure ad_map = SplayMapFn(adrOrd)
structure ad_set = SplaySetFn(adrOrd)


fun flatten twoDlist = 
    case twoDlist of [] => []
                   | h :: t => h @ (flatten t) 
  
  
fun takeVariables (clusterCode : clusterCode) =
    let val vars = #frameInfo clusterCode
        val pointers = #pointers vars
        val atoms = #atoms vars
        val doubles = #doubles vars
        val pt_end = (length pointers) - 1  
        val at_end = pt_end + (length atoms)
        val db_end = at_end + (length doubles)
    in
        ((pt_end,at_end,db_end), (pointers, atoms, doubles),
         (Vector.fromList (pointers @  atoms @ doubles @  (flatten (#records vars)))))
    end

    
fun succPredMaps cfg = 
    let val nodes  = CFG.foldl (fn ((f,s),R) => IntBinaryMap.insert 
                                                    (R,f,IntBinarySet.empty)) IntBinaryMap.empty cfg 
        val nodes2 = CFG.foldl (fn ((f,s),R) => IntBinaryMap.insert 
                                                    (R,f,IntBinarySet.add(valOf(IntBinaryMap.find(R,f)),s))) nodes cfg 
    in nodes2
    end
    

fun makeDepthFirstOrder cfg
  = let val stack = ref [0]
        val table = ref (IntBinarySet.add (IntBinarySet.empty,0))
        val result = ref []
        val childrenMap = succPredMaps cfg 
        fun unvisited_children (n,tb) 
          = let val children = (IntBinaryMap.find (childrenMap, n ))
            in if not (isSome children)
               then NONE
               else IntBinarySet.find (fn n => not (IntBinarySet.member (!tb,n))) (valOf children)
            end     
    in
        (
         while (not (!stack = nil))
         do
             (
              let val node = hd (!stack)
              in 
                  let val child = unvisited_children (node,table)
                  in if not (isSome child)
                     then (result := (hd (!stack)) :: (!result );stack := tl (!stack))
                     else (table := IntBinarySet.add(!table,valOf child);
                           stack := (valOf(child))::(!stack))
                  end
              end
             );
         !result
        )
    end

fun fst (f,s) = f
fun snd (f,s) = s


end
