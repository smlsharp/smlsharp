(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: StackReallocation.sml,v 1.15 2007/12/23 17:11:43 matsu Exp $
 *)


structure Reallocater : STACK_REALLOCATION = struct

open SymbolicInstructions
structure AUX = Aux
structure RNAME = Rename
structure LV = LivenessAnalysis
structure UD = UseDefAnalysis
structure BB = BasicBlock
structure CFG = BB.CFG



(* auxirialy function *)

fun argMap varVector = Vector.foldli (fn (i,h,R) => AUX.VarMap.insert (R,h,i)) AUX.VarMap.empty (varVector(*,0,NONE*))

fun vecToList vec = Vector.foldr (fn (i,R) => i :: R) [] vec 
    
fun getNumberOfArgs (args_set,vars) = 
    let fun aux (vs, n,acc) = 
            case vs of [] => acc 
                     | h :: t => if AUX.Lvars.member (args_set,h) 
                                 then aux (t, n + 1, n :: acc)
                                 else aux (t, n + 1, acc)
    in aux (vars,0,[])
    end

fun getVariablesUsedInPushHandler func = 
    case func of [] => AUX.Lvars.empty
               | PushHandler {exceptionEntry,... } :: t => 
                 AUX.Lvars.add (getVariablesUsedInPushHandler t, exceptionEntry)
               | _ :: t => getVariablesUsedInPushHandler t

fun removeArgsFromVarSet (vars,args_set) = List.filter (fn v => not (AUX.Lvars.member (args_set,v))) vars
                                           
      
fun fstList l = map (fn (f,s) => f) l

fun sndListToSet l = List.foldl (fn (udSet,R) => Aux.Lvars.union (R,udSet)) Aux.Lvars.empty (map (fn (f,s)=>s) l) 


fun makeVariableIndices var_set = 
    let fun aux vs n = 
            case vs of [] => AUX.VarMap.empty
                     | h :: t => AUX.VarMap.insert (aux t (n+1), h , n)
    in aux var_set 0
    end


(********************** graph coloring ***********************************)

fun removeArgs (args, defs) =
    let fun aux dfs = List.filter (fn i => not (IntBinarySet.member (args,i))) dfs
    in Vector.map aux defs
    end
                                                                                                 
fun neighberComp ((_,f), (_,s)) = Int.compare (f,s) 

   
fun assignColors (vars,vars2,n,i,ln) = if ln = 0 
                                      then List.nth (vars,i) 
                                      else 
                                          if n = ~1 
                                          then List.nth(vars2,0) 
                                          else List.nth(vars2,n)

fun makeVariableMap (mapArr,vars,vars2,mp,offset) = 
    let val ln2 = length vars2
    in Array.foldli (fn (i,n,R) => AUX.VarMap.insert
                                   (R,List.nth(vars,i),
                                    (assignColors(vars,vars2,n,i,ln2)))) mp (mapArr(*,0,NONE*))
    end

fun neighbersNumber arr = ArrayQSort.sort neighberComp arr    



fun oneStepTransfer (def,use',barray) = 
    (app (fn n => BitArray.clrBit (barray,n)) def;
     app (fn n => BitArray.setBit (barray,n)) use')



fun makeInterferenceMatrix (lives,bbs,lnp,lnv,defs,uses) = 
    let val matrix = Array.tabulate (lnv,fn _ => BitArray.array(lnv,false))
        fun aux1 (def,lvs) = app (fn i => BitArray.union (Array.sub (matrix,i)) lvs) def   
        fun aux2 (bb,lvs) = 
            case bb of [] => ()
                     | h :: t => 
                       let val def = Vector.sub (defs,h)
                           val use' = Vector.sub (uses,h)
                           val _ = aux1 (def,lvs)
                           val _ = oneStepTransfer (def,use',lvs)
                       in aux2 (t,lvs)
                       end
    in  (Vector.mapi (fn (i,bb) => aux2 (bb,Array.sub (lives,i))) (bbs(*,0,NONE*));matrix)
    end 


fun makeNeighber (matrix,(f,l),ln) = 
    let fun innerLoop (i,n,bar) = 
            if n > l
            then ()
            else 
                if BitArray.sub (bar,n) 
                then (BitArray.setBit (Array.sub (matrix,n),i);
                     innerLoop(i,n+1,bar))
                else innerLoop (i,n+1,bar)
        fun mainLoop i = if i > l 
                         then ()
                         else (innerLoop (i,f,Array.sub(matrix,i));mainLoop (i+1))
    in if ln = 0 
       then () 
       else mainLoop f
    end

fun countNeighber (matrix,(f,l),nArray,ln) = 
    let fun aux (i,n,bar) ns = 
            if n > l
            then  Array.update (nArray,i-f,(i-f,ns))
            else 
                if BitArray.sub (bar,n)
                then aux (i,n+1,bar) (ns + 1)
                else aux (i,n+1,bar) ns
        fun mainLoop i = if i > l
                         then ()
                         else (aux (i,f,Array.sub(matrix,i)) 0;mainLoop (i+1))
    in if ln = 0
       then () 
       else mainLoop f
    end



fun getNeighberColor (current,vM,(f,l),matrix) = 
    let fun aux (i,bar) ns = 
            if i > l 
            then ns
            else 
                let val bit = BitArray.sub (bar,i)
                in
                    if bit
                    then aux (i+1,bar) (IntBinarySet.add (ns, (Array.sub(vM,i-f)))) 
                    else aux (i+1,bar) ns 
                end
    in aux (f,Array.sub(matrix,current + f)) IntBinarySet.empty
    end

                        
fun selectOne (regPool, usedColors) = 
    valOf(IntBinarySet.find (fn i => not (IntBinarySet.member (usedColors,i))) regPool)


fun selectColor (vM,regPool,v,(f,l),matrix) = 
    let val neighbers = getNeighberColor (v,vM,(f,l),matrix)
    in selectOne (regPool,neighbers)
    end

fun body (vM,regPool,stk,(f,l),matrix) = 
    let fun aux st = case st of [] => ()
                              | h :: t => 
                                let val selectedColor = selectColor (vM,regPool,h,(f,l),matrix)
                                in
                                (Array.update(vM,h,selectedColor);
                                 aux t)
                                end
    in aux stk
    end 
    

fun graphColoringBody (vars,neighberNumbers,(f,l),matrix) = 
    let val maxColor = length vars
        val registerPool = IntBinarySet.addList (IntBinarySet.empty,
                                                 List.tabulate(maxColor,fn i => i))
        val stack = Array.foldr (fn ((i,_),R) => i :: R) [] neighberNumbers
        val varMap = Array.array (maxColor,~1)
    in if maxColor = 0 
       then varMap
       else (body (varMap,registerPool,stack,(f,l),matrix);
             varMap)
    end


fun clearAxis matrix = Array.appi (fn (i,bar) => BitArray.clrBit (bar,i)) (matrix(*,0,NONE*))

(*
fun clearOtherBits (matrix,(lnp,lna,lnd),ln) = 
    let val bits1 = BitArray.bits (ln - lnp,[])
        val bits2 = BitArray.bits (lnp,[])
        val bits3 = BitArray.bits (ln - (lnp + lna),[])
        val bits4 = BitArray.bits (lnp + lna,[])
        val bits5 = BitArray.bits (ln - (lnp + lna + lnd),[])
        val bits6 = BitArray.bits (ln,[])
        fun copyFalseAt bar = BitArray.copy {di = lnp, dst = bar, src = bits1}
        fun copyFalsePt bar = (BitArray.copy {di = 0, dst = bar, src = bits2};
                               BitArray.copy {di = lnp + lna, dst = bar, src = bits3})
        fun copyFalseDb bar = (BitArray.copy {di = 0, dst=bar, src = bits4};
                               BitArray.copy {di = lnp + lna + lnd, dst = bar, src = bits5})
        fun copyFalseAll bar = BitArray.copy {di = 0, dst = bar, src = bits6}
        fun aux (i,bar) = if i < lnp 
                          then copyFalseAt bar
                          else 
                              if i < lnp + lna
                              then copyFalsePt bar
                              else 
                                  if i < lnp + lna + lnd 
                                  then copyFalseDb bar
                                  else copyFalseAll bar
    in Array.appi aux  (matrix,0,NONE)
    end 
*)

fun removeLoc prog = 
    let fun aux p = case p of [] => []
			     | h :: t => (case h of Location _ => aux t
						  | _ => h :: (aux t))
    in aux prog
    end

(* current version *)
fun graphColoringFunction (pt_end,at_end,db_end) arg_Map (vp,va,vd) varVector (functionCode:functionCode) = 
    let 
        (* variables *)
        val var_set = vecToList varVector
        val ln = List.length var_set

        (* program representation *)     
        val ins1 = (#instructions functionCode) @ [Exit]
	val ins = removeLoc ins1
        val prog = BB.makeVectorProg ins 
        val lnp = List.length ins
        (* Arguments and variables used in pushhandler. They can not be reallocated.  *)
        val args = AUX.Lvars.union (AUX.Lvars.addList(AUX.Lvars.empty,#args functionCode),getVariablesUsedInPushHandler ins)

        val args_indexList = getNumberOfArgs (args,var_set)
        val args_index = IntBinarySet.addList (IntBinarySet.empty,args_indexList)
           
        (* use def analysis *)
        val defs = removeArgs (args_index, UD.def arg_Map ins)
        val uses = UD.use' arg_Map ins


        (* control flow graph *)
        val cfg = BB.makeCFG prog
        val bbs = BB.makeBasicBlockMapV (prog,cfg)
        
        (* liveness information *)
        val lives =  (LV.livenessAnalysis
                              (BB.makeBBCFG (cfg,bbs),bbs,defs,uses,var_set,makeVariableIndices var_set,prog))
        
        val listBBs =  Vector.fromList (IntBinaryMap.listItems bbs)
        val matrix = makeInterferenceMatrix (lives,listBBs,lnp,ln,defs,uses)
        
        val _ = Array.app (fn bitAr => ((app (fn args => BitArray.clrBit (bitAr,args)) args_indexList);())) matrix
        
        val (lnp,lna,lnd) = (List.length vp,List.length va,List.length vd)


        (*val _ = clearOtherBits (matrix,(lnp,lna,lnd),ln)*)
        val _ = clearAxis matrix
        
        val nArrayP = Array.array (lnp, (0,0))
        val nArrayA = Array.array (lna, (0,0))
        val nArrayD = Array.array (lnd, (0,0))

        val _ = makeNeighber (matrix,(0,at_end),lnp)
        val _ = makeNeighber (matrix,(at_end + 1,pt_end),lna)
        val _ = makeNeighber (matrix,(pt_end + 1,db_end),lnd)
        
        val _ = countNeighber (matrix,(0,pt_end),nArrayP,lnp)
        val _ = countNeighber (matrix,(pt_end + 1,at_end),nArrayA,lna)
        val _ = countNeighber (matrix,(at_end + 1,db_end),nArrayD,lnd)
                 
        val _ = neighbersNumber nArrayP
        val _ = neighbersNumber nArrayA
        val _ = neighbersNumber nArrayD
        
        val PMapAr = graphColoringBody (vp,nArrayP,(0,pt_end),matrix)
        val AMapAr = graphColoringBody (va,nArrayA,(pt_end + 1,at_end),matrix)
        val DMapAr = graphColoringBody (vd,nArrayD,(at_end + 1,db_end),matrix)


        (**********  renaming  variables *************)
                     
        val useVar = Vector.foldl (fn (use',R) => AUX.Lvars.addList (R,map (fn u => Vector.sub (varVector,u)) use')) AUX.Lvars.empty uses
        val udVar = Vector.foldl (fn (def,R) => AUX.Lvars.addList (R,map (fn d => Vector.sub (varVector,d)) def)) useVar defs

        val removeFilter  = ((List.filter (fn var => AUX.Lvars.member (udVar,var))) o removeArgsFromVarSet) 
        val (newVp,newVa,newVd) = (removeFilter (vp,args), removeFilter (va,args), removeFilter (vd,args))
        val varMap1 = makeVariableMap (PMapAr,vp,newVp,AUX.VarMap.empty,~1)
                      
        val varMap2 = makeVariableMap (AMapAr,va,newVa,varMap1,pt_end)
                      
        val varMap3 = makeVariableMap (DMapAr,vd,newVd,varMap2,at_end)
        val varMap = AUX.Lvars.foldl (fn (arg,R) => AUX.VarMap.insert (R,arg,arg)) varMap3 args
                     
        val newCode = RNAME.reallocate (varMap,#instructions functionCode)
                      
        val uses2 = UD.use' arg_Map newCode
        val defs2 = UD.def arg_Map newCode
                    
        val useVar2 = Vector.foldl (fn (use',R) => AUX.Lvars.addList 
                                                      (R,map (fn u => Vector.sub (varVector,u)) use')) AUX.Lvars.empty uses2
        val udVar2 = Vector.foldl (fn (def,R) => AUX.Lvars.addList 
                                                     (R,map (fn d => Vector.sub (varVector,d)) def)) useVar2 defs2
    in 
        ({name = #name functionCode, loc = #loc functionCode, args= #args functionCode, instructions = newCode} : functionCode
       ,AUX.Lvars.union (udVar2,args))
    end 


(********************************************************************************)

(* newer version *)

fun graphColoringFunction2 (pt_end,at_end,db_end) arg_Map_All (vp,va,vd) varVector_All records (functionCode:functionCode) =
    let 
        (* variables *)
(*
        val var_set = vecToList varVector
        val ln = List.length var_set
*)
        (* program representation *)     
        val ins1 = (#instructions functionCode) @ [Exit]
	val ins = removeLoc ins1
        val prog = BB.makeVectorProg ins 
        val lnp = List.length ins
        
	(* Arguments and variables used in pushhandler. They can not be reallocated.  *)
        val args = AUX.Lvars.union (AUX.Lvars.addList(AUX.Lvars.empty,#args functionCode),getVariablesUsedInPushHandler ins)
(*
        val args_indexList = getNumberOfArgs (args,var_set)
        val args_index = IntBinarySet.addList (IntBinarySet.empty,args_indexList)
*)   
     

        (**************************  making new variable sets *********************************)      
        val d2 = UD.def arg_Map_All ins
        val u2 = UD.use' arg_Map_All ins
                            
        val useVar2 = Vector.foldl (fn (use',R) => AUX.Lvars.addList 
                                                      (R,map (fn u => Vector.sub (varVector_All,u)) use')) AUX.Lvars.empty d2
        val udVar2 = Vector.foldl (fn (def,R) => AUX.Lvars.addList 
                                                     (R,map (fn d => Vector.sub (varVector_All,d)) def)) useVar2 u2

	val useDefWithArgs = (AUX.Lvars.union (udVar2,args))

        val vp = List.filter (fn v => AUX.Lvars.member(useDefWithArgs,v)) vp
	val va = List.filter (fn v => AUX.Lvars.member(useDefWithArgs,v)) va
	val vd = List.filter (fn v => AUX.Lvars.member(useDefWithArgs,v)) vd
        val varVector = Vector.fromList (vp @ va @ vd @ records)
        
        val arg_Map = argMap varVector
             
        val pt_end = (length vp) - 1
        val at_end = pt_end + (length va)
	val db_end = at_end + (length vd) 	
        
        val var_set = vecToList varVector
        val ln = List.length var_set
        
        val args_indexList = getNumberOfArgs (args,var_set)
        val args_index = IntBinarySet.addList (IntBinarySet.empty,args_indexList)

        (*****************************************************************************************)
                       
        (* use def analysis *)
        val defs = removeArgs (args_index, UD.def arg_Map ins)
        val uses = UD.use' arg_Map ins

        (* control flow graph *)
        val cfg = BB.makeCFG prog
        val bbs = BB.makeBasicBlockMapV (prog,cfg)
        
        (* liveness information *)
        val lives =  (LV.livenessAnalysis
                              (BB.makeBBCFG (cfg,bbs),bbs,defs,uses,var_set,makeVariableIndices var_set,prog))
        
        val listBBs =  Vector.fromList (IntBinaryMap.listItems bbs)
        val matrix = makeInterferenceMatrix (lives,listBBs,lnp,ln,defs,uses)
        
        val _ = Array.app (fn bitAr => ((app (fn args => BitArray.clrBit (bitAr,args)) args_indexList);())) matrix
        
        val (lnp,lna,lnd) = (List.length vp,List.length va,List.length vd)

        val _ = clearAxis matrix
        
        val nArrayP = Array.array (lnp, (0,0))
        val nArrayA = Array.array (lna, (0,0))
        val nArrayD = Array.array (lnd, (0,0))

        val _ = makeNeighber (matrix,(0,at_end),lnp)
        val _ = makeNeighber (matrix,(at_end + 1,pt_end),lna)
        val _ = makeNeighber (matrix,(pt_end + 1,db_end),lnd)
        
        val _ = countNeighber (matrix,(0,pt_end),nArrayP,lnp)
        val _ = countNeighber (matrix,(pt_end + 1,at_end),nArrayA,lna)
        val _ = countNeighber (matrix,(at_end + 1,db_end),nArrayD,lnd)
                 
        val _ = neighbersNumber nArrayP
        val _ = neighbersNumber nArrayA
        val _ = neighbersNumber nArrayD
        
        val PMapAr = graphColoringBody (vp,nArrayP,(0,pt_end),matrix)
        val AMapAr = graphColoringBody (va,nArrayA,(pt_end + 1,at_end),matrix)
        val DMapAr = graphColoringBody (vd,nArrayD,(at_end + 1,db_end),matrix)


        (**********************************  renaming  variables **************************)
                     
        val useVar = Vector.foldl (fn (use',R) => AUX.Lvars.addList (R,map (fn u => Vector.sub (varVector,u)) use')) AUX.Lvars.empty uses
        val udVar = Vector.foldl (fn (def,R) => AUX.Lvars.addList (R,map (fn d => Vector.sub (varVector,d)) def)) useVar defs

        val removeFilter  = ((List.filter (fn var => AUX.Lvars.member (udVar,var))) o removeArgsFromVarSet) 
        val (newVp,newVa,newVd) = (removeFilter (vp,args), removeFilter (va,args), removeFilter (vd,args))
        val varMap1 = makeVariableMap (PMapAr,vp,newVp,AUX.VarMap.empty,~1)
                      
        val varMap2 = makeVariableMap (AMapAr,va,newVa,varMap1,pt_end)
                      
        val varMap3 = makeVariableMap (DMapAr,vd,newVd,varMap2,at_end)
        val varMap = AUX.Lvars.foldl (fn (arg,R) => AUX.VarMap.insert (R,arg,arg)) varMap3 args
                     
        val newCode = RNAME.reallocate (varMap,#instructions functionCode)
                      
        val uses2 = UD.use' arg_Map_All newCode
        val defs2 = UD.def arg_Map_All newCode
                    
        val useVar2 = Vector.foldl (fn (use',R) => AUX.Lvars.addList 
                                                      (R,map (fn u => Vector.sub (varVector_All,u)) use')) AUX.Lvars.empty uses2
        val udVar2 = Vector.foldl (fn (def,R) => AUX.Lvars.addList 
                                                     (R,map (fn d => Vector.sub (varVector_All,d)) def)) useVar2 defs2
    in 
        ({name = #name functionCode, loc = #loc functionCode, args= #args functionCode, instructions = newCode} : functionCode
       ,AUX.Lvars.union (udVar2,args))
    end 


       (**************************************************************************************)


(* current version of stack reallocater *)
fun clusterGraphColoring2 (clusterCode : clusterCode) =
    let val ((pt_end,at_end,db_end),(vp,va,vd),varVector) = AUX.takeVariables clusterCode
        val frameInfo = #frameInfo clusterCode
        val arg_Map = argMap varVector
                      
        val functionCodes = #functionCodes clusterCode 
        
        val newFunctions = map 
                               (graphColoringFunction  (pt_end,at_end,db_end) arg_Map (vp,va,vd) varVector) 
                               functionCodes
        val newFunctionCodes = fstList newFunctions
        val udargs = sndListToSet newFunctions
        
        val (vp2,va2,vd2) = (List.filter (fn v => Aux.Lvars.member (udargs,v)) vp,
                             List.filter (fn v => Aux.Lvars.member (udargs,v)) va,
                             List.filter (fn v => Aux.Lvars.member (udargs,v)) vd)
        val newFrameInfo = {bitmapvals = #bitmapvals frameInfo, 
                            pointers = vp2, atoms = va2, doubles = vd2, 
                            records = #records frameInfo} : frameInfo
    in {frameInfo = newFrameInfo, functionCodes = newFunctionCodes, loc = #loc clusterCode} : clusterCode
    end


(* current version of stack reallocater, refined *)
fun clusterGraphColoring (clusterCode : clusterCode) =
    let val ((pt_end,at_end,db_end),(vp,va,vd),varVector,records) = AUX.takeVariables2 clusterCode
        val frameInfo = #frameInfo clusterCode
        val arg_Map = argMap varVector
                      
        val functionCodes = #functionCodes clusterCode 
        
        val newFunctions = map 
                               (graphColoringFunction2  (pt_end,at_end,db_end) arg_Map (vp,va,vd) varVector records) 
                               functionCodes
        val newFunctionCodes = fstList newFunctions
        val udargs = sndListToSet newFunctions
        
        val (vp2,va2,vd2) = (List.filter (fn v => Aux.Lvars.member (udargs,v)) vp,
                             List.filter (fn v => Aux.Lvars.member (udargs,v)) va,
                             List.filter (fn v => Aux.Lvars.member (udargs,v)) vd)
        val newFrameInfo = {bitmapvals = #bitmapvals frameInfo, 
                            pointers = vp2, atoms = va2, doubles = vd2, 
                            records = #records frameInfo} : frameInfo
    in {frameInfo = newFrameInfo, functionCodes = newFunctionCodes, loc = #loc clusterCode} : clusterCode
    end



(**************   for printing *******************)

(*** auxirially function for printing control flow information ***)

fun printCFG arg_Map varVector (functionCode:functionCode) = 
let val ins = (#instructions functionCode) @ [Exit]
        val prog = BB.makeVectorProg ins 
        val defs = UD.def arg_Map ins
        val uses = UD.use' arg_Map ins
        val varN = Vector.length varVector
        val cfg = (BB.makeCFG prog)
        val bbs = BB.makeBasicBlockMapV (prog,cfg)
in BB.CFG.listItems (BB.CFG.filter (fn (f,s) => not (f=s)) (BB.makeBBCFG (cfg,bbs)))
end


(**** Auxirially functions for printing liveness ****)


fun printLivenessFunctions arg_Map varVector (functionCode : functionCode) = 
    let val ins = (#instructions functionCode) @ [Exit]
        val prog = BB.makeVectorProg ins
        val cfg =  (BB.makeCFG prog)
        val bbs = BB.makeBasicBlockMapV (prog,cfg)
        val cfg2 = BB.makeBBCFG (cfg,bbs)

        val var_set = vecToList varVector
        val var_map = makeVariableIndices var_set
        val defs = UD.def arg_Map ins
        val uses = UD.use' arg_Map ins
    in LV.livenessPrint (cfg2,bbs,defs,uses,var_set,var_map,prog,varVector)
    end


fun printLivenessFunctions2 arg_Map varVector (functionCode : functionCode) = 
    let val ins = (#instructions functionCode) @ [Exit]
        val prog = BB.makeVectorProg ins
        val cfg =  (BB.makeCFG prog)
        val bbs = BB.makeBasicBlockMapV (prog,cfg)
        val cfg2 = BB.makeBBCFG (cfg,bbs)

        val var_set = vecToList varVector
        val var_map = makeVariableIndices var_set
        val defs = UD.def arg_Map ins
        val uses = UD.use' arg_Map ins
    in LV.livenessProgramPrint (cfg2,bbs,defs,uses,var_set,var_map,prog,varVector)
    end



(*************************************************************)


(** printing CFGs of function inside clusters **)
fun printCFGClusters clusterCode =
    let val (_,_,varVector) = AUX.takeVariables clusterCode 
        val arg_Map = argMap varVector
        val functionCodes = #functionCodes clusterCode
    in map (printCFG arg_Map varVector) functionCodes
    end


(** printing liveness information inside clusters **)
fun printLivenessClusters clusterCode = 
    let val (_,_,varVector) = AUX.takeVariables clusterCode
        val arg_Map = argMap varVector
        val functionCodes = #functionCodes clusterCode
    in map (printLivenessFunctions arg_Map varVector) functionCodes
    end

fun printLivenessClusters2 clusterCode = 
    let val (_,_,varVector) = AUX.takeVariables clusterCode
        val arg_Map = argMap varVector
        val functionCodes = #functionCodes clusterCode
    in map (printLivenessFunctions2 arg_Map varVector) functionCodes
    end
    
end


