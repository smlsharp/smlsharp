(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: BasicBlock.sml,v 1.11 2007/10/14 19:28:09 katsu Exp $
 *)

structure BasicBlock = struct

open SymbolicInstructions
open List

structure AUX = Aux
structure CFG = AUX.CFG


structure EXC = ExceptionAnalysis


fun fst (f,_) = f 

fun fstlist pairlist = map (fn pair => fst pair) pairlist

fun makeVectorProg prog = Vector.fromList prog


fun labelOfCase l = case l of [] => []
                            | {const=c, destination=d} ::t => d :: (labelOfCase t)

fun makeLabelMapV progV = Vector.foldli (fn (i,Label adr,R) => AUX.ad_map.insert (R,adr,i)
                                        |  (i,_,R) =>R) AUX.ad_map.empty (progV(*,0,NONE*))  


(* current version *)
fun makeCFG prog = 
    let 
        val length = Vector.length prog
        val labelMap = makeLabelMapV prog 
        fun aux (n,ins,R) = case ins of Raise _ => CFG.add (R,(n,length - 1))
                                       | SwitchInt {targetEntry,cases,default} => 
                                         let  val destinations = map (fn ad => valOf (AUX.ad_map.find (labelMap,ad))) 
                                                                     (default :: (labelOfCase cases))  
                                         in 
                                             CFG.addList(R, (map (fn x => (n,x)) (destinations)))
                                         end
                                       | SwitchWord {targetEntry,cases,default} =>
                                         let  val destinations = map (fn ad => valOf (AUX.ad_map.find (labelMap,ad))) 
                                                                     (default :: (labelOfCase cases))
                                         in 
                                             CFG.addList(R, (map (fn x => (n,x)) (destinations)))
                                         end
                                       | SwitchChar {targetEntry,cases,default} =>
                                         let  val destinations = map (fn ad => valOf (AUX.ad_map.find (labelMap,ad))) 
                                                                     (default :: (labelOfCase cases))
                                         in 
                                             CFG.addList(R, (map (fn x => (n,x)) (destinations)))
                                         end
                                       | SwitchString {targetEntry,cases,default} =>
                                         let  val destinations = map (fn ad => valOf (AUX.ad_map.find (labelMap,ad))) 
                                                                     (default :: (labelOfCase cases))
                                         in 
                                             CFG.addList(R, (map (fn x => (n,x)) (destinations)))
                                         end
                                       | Jump {destination} => let val target = valOf (AUX.ad_map.find (labelMap,destination))
                                                               in                 
                                                                   CFG.add(R,(n,target))
                                                               end
                                       | IndirectJump _ => raise Control.Bug "StackReallocator: cannot deal with IndirectJump"
                                       | PopHandler _ => CFG.addList (R,[(n,n+1),(n,length -1)])
                                       | PushHandler {handlerStart,...} => CFG.add(R, (n,n+1))
                                       | Exit => CFG.add(R,(n,length - 1))
                                       | Return_0  => CFG.add(R,(n,length - 1))
                                       | Return_1 _ => CFG.add(R,(n,length - 1))
                                       | Return_MS _ => CFG.add(R,(n,length - 1))
                                       | Return_ML _ => CFG.add(R,(n,length - 1))
                                       | Return_MF _ => CFG.add(R,(n,length - 1))
                                       | Return_MV _ => CFG.add(R,(n,length - 1))
                                       | ConstString _ => R
                                       | TailApply_0 _ => CFG.add(R,(n,length - 1))
                                       | TailApply_1 _ => CFG.add(R,(n,length - 1))
                                       | TailApply_MS _ => CFG.add(R,(n,length - 1))
                                       | TailApply_ML _ => CFG.add(R,(n,length - 1))
                                       | TailApply_MF _ => CFG.add(R,(n,length - 1))
                                       | TailApply_MV _ => CFG.add(R,(n,length - 1))
                                       | TailCallStatic_0 _ => CFG.add(R,(n,length - 1))
                                       | TailCallStatic_1 _ => CFG.add(R,(n,length - 1))
                                       | TailCallStatic_MS _ => CFG.add(R,(n,length - 1))
                                       | TailCallStatic_ML _ => CFG.add(R,(n,length - 1))
                                       | TailCallStatic_MF _ => CFG.add(R,(n,length - 1))
                                       | TailCallStatic_MV _ => CFG.add(R,(n,length - 1))
                                       | RecursiveTailCallStatic_0 _ => CFG.add(R,(n,length - 1))
                                       | RecursiveTailCallStatic_1 _ => CFG.add(R,(n,length - 1))
                                       | RecursiveTailCallStatic_MS _ => CFG.add(R,(n,length - 1))
                                       | RecursiveTailCallStatic_ML _ => CFG.add(R,(n,length - 1))
                                       | RecursiveTailCallStatic_MF _ => CFG.add(R,(n,length - 1))
                                       | RecursiveTailCallStatic_MV _ => CFG.add(R,(n,length - 1))
                                       | _ => CFG.add(R,(n,n+1))
    in  Vector.foldri aux CFG.empty (prog(*,0,NONE*))
    end

(* making CFG of basic blocks *)

fun succ_predArrays (numbers, cfg) = 
    let 
        val succ_ar = Array.array (numbers, 0)
        val pred_ar = Array.array (numbers, 0)
        val _ = CFG.app (fn (f,s) => (Array.update (succ_ar,f,Array.sub(succ_ar,f) + 1);
                                      Array.update (pred_ar,s,Array.sub(pred_ar,s) + 1))) cfg
    in  (succ_ar,pred_ar)
    end  
                       
fun hasOneSuccessor (numbers,cfg) = let fun aux_hos (nums,acc)=
                                      case nums of [] => acc
                                                 | h :: t => let val out_edge = CFG.filter (fn (p,c)=> h = p) cfg
                                                                 val n = CFG.numItems out_edge
                                                             in if (n = 1)
                                                                then aux_hos (t,IntBinarySet.add (acc,h))
                                                                else aux_hos (t,acc)
                                                             end
                              in aux_hos (numbers,IntBinarySet.empty)
                              end
                              
fun hasOnePredecessor (numbers,cfg) = let fun aux_hop (nums,acc)=
                                      case nums of [] => acc
                                                 | h :: t => let val in_edge = CFG.filter (fn (p,c)=> h = c) cfg
                                                                 val n = CFG.numItems in_edge
                                                             in if (n = 1)
                                                                then aux_hop (t,IntBinarySet.add (acc,h))
                                                                else aux_hop (t,acc)
                                                             end
                              in aux_hop (numbers,IntBinarySet.empty)
                              end


fun isNotLabel (Label _) = false | isNotLabel _ = true

fun makeBasicBlockMapV (progV, cfg) = 
    let 
        fun isNotLabel (Label _) = false
          | isNotLabel _ = true
        val ln = Vector.length progV
        val numbers = List.tabulate (ln, fn i => i)
        val (succ_ar, pred_ar)  = succ_predArrays (ln, cfg)
        fun aux (p,current,members,r_cfg) = case p of [] => r_cfg
                                                    | [h1] => IntBinaryMap.insert (IntBinaryMap.insert (r_cfg,current,members),h1,[h1])
                                                    | h1 :: h2 :: t
                                                      => if (CFG.member (cfg,(h1,h2)) 
                                                             andalso (Array.sub (succ_ar,h1) = 1) 
                                                             andalso (Array.sub (pred_ar,h2) = 1)
							     andalso isNotLabel (Vector.sub(progV,h2))) 

                                                         then aux ((h2 :: t),current, h1::members,r_cfg)
                                                         else aux ((h2 :: t),h2,[],
                                                                   IntBinaryMap.insert(r_cfg,current,h1 :: members))
    in aux (numbers,0,[],IntBinaryMap.empty)
    end



(* current version *)
fun makeBBCFG (cfg,bbs) = 
    let         
        val fst = IntBinarySet.addList (IntBinarySet.empty,IntBinaryMap.listKeys bbs)
        val sndfst_map = IntBinaryMap.foldri (fn (f,slist,R) => IntBinaryMap.insert (R,hd slist,f)) IntBinaryMap.empty bbs
        val red_cfg = CFG.filter (fn (f,s)=> IntBinarySet.member (fst,s)) cfg
    in CFG.map (fn (f,s) => (valOf(IntBinaryMap.find(sndfst_map,f)),s)) red_cfg
    end  


end
