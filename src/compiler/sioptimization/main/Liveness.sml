(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: Liveness.sml,v 1.8 2007/06/22 09:41:28 matsu Exp $
 *)

structure LivenessAnalysis = struct 
  
open SymbolicInstructions
open List  
     
structure AUX = Aux
structure CFG = AUX.CFG
structure BB = BasicBlock
structure UD = UseDefAnalysis
structure EXC = ExceptionAnalysis

fun curryNth vecs index = Vector.sub (vecs,index)

fun arrayToList (varVector,arr) = Array.foldr (fn (a,R) => (map (curryNth varVector) (MyBitArray.getBits a)) :: R) [] arr
  
  fun UseDefVecToUseDefTypes (use_def_vec, var_map) = 
      Vector.map (fn {def,use} 
                       => {def = map (fn e =>valOf(AUX.VarMap.find(var_map,e))) def, 
                                          use = map (fn e =>valOf(AUX.VarMap.find(var_map,e))) use}) use_def_vec 

  
  fun makeListBBS bbs = 
      let val listKeys = Array.fromList (IntBinaryMap.listKeys bbs)
          val listBBS = Vector.fromList (IntBinaryMap.listItems bbs)
          val ln = Array.length listKeys           
          val indexMap = Array.foldli (fn (i,e,R) => IntBinaryMap.insert (R,e,i)) IntBinaryMap.empty (listKeys,0,NONE)
      in (listKeys,listBBS,indexMap,ln)
      end
      

  fun succPredMaps cfg = 
      let val nodes  = CFG.foldl (fn ((f,s),R) => IntBinaryMap.insert 
                                                      (R,f,IntBinarySet.empty)) IntBinaryMap.empty cfg 
      in CFG.foldl (fn ((f,s),R) => IntBinaryMap.insert 
                                        (R,f,IntBinarySet.add(valOf(IntBinaryMap.find(R,f)),s))) nodes cfg
    end



fun rename (cfg,mp) = CFG.map (fn (f,s) => 
                                  (valOf(IntBinaryMap.find(mp,f)),valOf(IntBinaryMap.find(mp,s)))) cfg 


(* current version *)


fun livenessAnalysis (bcfg,bbs,def,use,vars,var_map,prog) =
    let 
        val (indexArray,listBBs,indexMap,bbsLn) = makeListBBS bbs          
        
        val lnp = Vector.length prog
        val lnv = length vars
        val reversedCFG = CFG.filter (fn (f,s) => not (f=s)) (CFG.map (fn (f,s) => (s,f)) bcfg) 
        val renamedCFG = rename (reversedCFG,indexMap)
        val nodes = IntBinaryMap.listKeys bbs 
        val succMap = succPredMaps renamedCFG
        val succOfnodes = Array.tabulate (bbsLn, fn n  => let val succs = (IntBinaryMap.find (succMap,n))
                                                       in if isSome succs 
                                                          then CFG.listItems (IntBinarySet.foldl 
                                                                                  (fn (h,R)=> CFG.add (R, (n,h))) CFG.empty
                                                                                  (valOf succs))
                                                          else []
                                                       end ) 
        
        val edges = (rev (CFG.listItems renamedCFG))
        
        val W1 = ref edges
        
        val inLives = Array.tabulate (bbsLn,fn _ => MyBitArray.array (lnv, false))
        val outLives = Array.tabulate (bbsLn, fn _ => MyBitArray.array (lnv,false))
        
        
        val ((ex_r,h_n),handlerNumbers) = EXC.makeExceptionRegion prog
        
        
        val headBBs = Vector.map (fn bb => hd bb) listBBs
        val lastBBsMap = Vector.foldli (fn (i,bb,R) => IntBinaryMap.insert (R,List.last bb,i)) IntBinaryMap.empty (listBBs,0,NONE)

        val handlerBlocks = Vector.foldri (fn (i,bb,R) => if IntBinarySet.member (handlerNumbers,List.last bb) 
                                                          then i :: R else R) [] (listBBs,0,NONE)

        fun addExceptionLiveness () = 
            let fun aux  (i,head) = 
                    let val adset_l = valOf(IntBinaryMap.find(ex_r,head))
                        val excEntryNumbers = map (fn ad => valOf(AUX.ad_map.find(h_n,ad))) adset_l
                        val excEntryBlocks = map (fn n => valOf(IntBinaryMap.find(lastBBsMap,n))) excEntryNumbers
                    in List.app (fn n => MyBitArray.union (Array.sub(inLives,i)) (Array.sub (outLives,n))) excEntryBlocks
                    end
            in Vector.appi aux (headBBs,0,NONE)
            end

        fun setBitsList (l,bitArray) = 
            app (fn n => MyBitArray.setBit (bitArray,n)) l
        fun clearBitsList (l,bitArray) =
            app (fn n => MyBitArray.clrBit (bitArray,n)) l
 
        fun makeUseDefInBlock bb =
            let
              val defBits = MyBitArray.array (lnv, false)
              val useBits = MyBitArray.array (lnv, false)
            in
              app (fn n =>
                      let
                        val defs = Vector.sub (def,n)
                        val uses = Vector.sub (use,n)
                      in
                        setBitsList (defs,defBits);
                        clearBitsList (defs,useBits);
			clearBitsList (uses,defBits);
                        setBitsList (uses,useBits)
                      end)
                  bb;
              MyBitArray.complement defBits;
              (useBits, defBits)
            end

        val blockUDs = Vector.map makeUseDefInBlock listBBs
        
        fun clearMyBitArray bar = MyBitArray.appi (fn (i,_) => MyBitArray.clrBit (bar,i)) bar
            
        fun transferBlock ((blockUse,notBlockDef), analysis) = 
            let val tmp = MyBitArray.andb (analysis, notBlockDef, lnv)
            in (MyBitArray.union tmp blockUse; tmp)
            end
 
        fun transferHandlerBlocks () = map (fn i => 
                                               Array.update (outLives,
                                                             i,
                                                             transferBlock (Vector.sub (blockUDs,i),Array.sub (inLives,i)))
                                               ) handlerBlocks
       
        val flag = ref false    
        fun innerLoop Wx = 
            (while (not (!Wx = nil))
             do
                 let val (lp,l) = hd (!Wx)
                     val _ = Wx := tl (!Wx)
                     val lv_l = Array.sub (inLives,l)
                     val flp = transferBlock (Vector.sub (blockUDs,lp),Array.sub (inLives,lp))
                     val lv_lSet = IntBinarySet.addList (IntBinarySet.empty,MyBitArray.getBits lv_l)
                     val flp_Set = IntBinarySet.addList (IntBinarySet.empty,MyBitArray.getBits flp)
                 in 
                     if IntBinarySet.isSubset (flp_Set,lv_lSet)
                     then ()
                     else (flag := true;
                           MyBitArray.union lv_l flp;
                           Wx:= Array.sub(succOfnodes,l) @ (!Wx))
                 end)


        val _ = (innerLoop W1;W1:=edges)
        val _ = flag := false
        
        fun mainLoop () = (
                           transferHandlerBlocks ();
                           addExceptionLiveness ();
                           (*W1:=edges;*)
                           innerLoop W1;
                           if (!flag)
                           then (flag := false;W1:= edges;mainLoop ()) 
                           else (inLives))
    in mainLoop () 
    end




                      (********************    for printing     **********************)

fun livenessProgramPrint (bcfg,bbs,def,use,vars,var_map,prog,varVector) = 
    let val lives = livenessAnalysis (bcfg,bbs,def,use,vars,var_map,prog)
        val livesList = arrayToList (varVector,lives)
    in  Vector.foldri (fn (i,l,R) => (List.nth(livesList,i),l) :: R) nil (prog,0,NONE)
    end


fun livenessPrint (bcfg,bbs,def,use,vars,var_map,prog,varVector) =
    let val lives = livenessAnalysis (bcfg,bbs,def,use,vars,var_map,prog)
        val liveList = arrayToList (varVector,lives)
    in liveList
    end

end
