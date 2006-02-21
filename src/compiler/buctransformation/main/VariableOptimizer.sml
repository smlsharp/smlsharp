(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author NGUYEN Huu-Duc
 * @author $Id: VariableOptimizer.sml,v 1.4 2006/02/18 16:04:06 duchuu Exp $
 *)

structure VariableOptimizer = struct

  structure T = Types
  structure BC = BUCCalc
  structure BU = BUCUtils
  structure VMap = ID.Map

  type varSet = 
       {
        tyMap : (T.ty * BC.id) list,
        varMap : BC.varInfo VMap.map
       }

  exception TYPE_FOUND of varSet

  fun bitmapEq ([],L) = 
      (
       case BU.constantBitmap L of
         SOME 0w0 => true
       | _ => false
      )
    | bitmapEq (L,[]) = 
      (
       case BU.constantBitmap L of
         SOME 0w0 => true
       | _ => false
      )
    | bitmapEq (T.ATOMty::L1,T.ATOMty::L2) = bitmapEq(L1,L2)
    | bitmapEq (T.BOXEDty::L1,T.BOXEDty::L2) = bitmapEq(L1,L2)
    | bitmapEq (T.DOUBLEty::L1,T.DOUBLEty::L2) = bitmapEq(L1,L2)
    | bitmapEq (T.ATOMty::L1,T.DOUBLEty::L2) = bitmapEq(L1,T.ATOMty::L2)
    | bitmapEq (T.DOUBLEty::L1,T.ATOMty::L2) = bitmapEq(T.ATOMty::L1,L2)
    | bitmapEq ((T.BOUNDVARty tid1)::L1,(T.BOUNDVARty tid2)::L2) = 
      (tid1=tid2) andalso (bitmapEq(L1,L2))
    | bitmapEq ((T.PADty _)::L1,(T.PADty _)::L2) = bitmapEq(L1,L2)
    | bitmapEq ((T.PADCONDty(_,tid1))::L1,(T.PADCONDty(_,tid2))::L2) =
      (tid1=tid2) andalso (bitmapEq(L1,L2))
    | bitmapEq (_,_) = false

  fun offsetEq ([],[]) = true 
    | offsetEq (T.ATOMty::L1,T.ATOMty::L2) = offsetEq(L1,L2)
    | offsetEq (T.ATOMty::L1,T.BOXEDty::L2) = offsetEq(L1,L2)
    | offsetEq (T.ATOMty::L1,T.DOUBLEty::L2) = offsetEq(L1,T.ATOMty::L2)
    | offsetEq (T.BOXEDty::L1,T.ATOMty::L2) = offsetEq(L1,L2)
    | offsetEq (T.BOXEDty::L1,T.BOXEDty::L2) = offsetEq(L1,L2)
    | offsetEq (T.BOXEDty::L1,T.DOUBLEty::L2) = offsetEq(L1,T.ATOMty::L2)
    | offsetEq (T.DOUBLEty::L1,T.ATOMty::L2) = offsetEq(T.ATOMty::L1,L2)
    | offsetEq (T.DOUBLEty::L1,T.BOXEDty::L2) = offsetEq(T.ATOMty::L1,L2)
    | offsetEq (T.DOUBLEty::L1,T.DOUBLEty::L2) = offsetEq(L1,L2)
    | offsetEq ((T.BOUNDVARty tid1)::L1,(T.BOUNDVARty tid2)::L2) = 
      (tid1=tid2) andalso (offsetEq(L1,L2))
    | offsetEq ((T.PADty _)::L1,(T.PADty _)::L2) = offsetEq(L1,L2)
    | offsetEq ((T.PADCONDty(_,tid1))::L1,(T.PADCONDty(_,tid2))::L2) =
      (tid1=tid2) andalso (offsetEq(L1,L2))
    | offsetEq (_,_) = false

  fun frameBitmapEq ([],[]) = true
    | frameBitmapEq (h1::t1,h2::t2) = (h1=h2) andalso (frameBitmapEq(t1,t2))
    | frameBitmapEq _ = false

  (* only for comparing types of extra variables*)
  fun eq(ty1,ty2) =
      case (ty1,ty2) of
        (T.TAGty tid1,T.TAGty tid2) => tid1 = tid2
      | (T.TAGty tid1,T.BITMAPty [T.BOUNDVARty tid2]) => tid1 = tid2
      | (T.TAGty tid1,T.FRAMEBITMAPty [tid2]) => tid1 = tid2
      | (T.SIZEty tid1,T.SIZEty tid2) => tid1 = tid2
      | (T.SIZEty tid1,T.OFFSETty [T.BOUNDVARty tid2]) => tid1 = tid2
      | (T.BITMAPty [T.BOUNDVARty tid1],T.TAGty tid2) => tid1 = tid2
      | (T.BITMAPty tyList1,T.BITMAPty tyList2) =>
        bitmapEq(tyList1,tyList2)
      | (T.FRAMEBITMAPty [tid1],T.TAGty tid2) => tid1 = tid2
      | (T.FRAMEBITMAPty tidList1,T.FRAMEBITMAPty tidList2) =>
        frameBitmapEq(tidList1,tidList2)
      | (T.OFFSETty [T.BOUNDVARty tid1],T.SIZEty tid2) => tid1 = tid2
      | (T.OFFSETty tyList1,T.OFFSETty tyList2) =>
        offsetEq(tyList1,tyList2)
      | (T.PADty tyList1,T.PADty tyList2) =>
        offsetEq(tyList1,tyList2)
      | (T.PADCONDty (tyList1,tid1),T.PADCONDty (tyList2,tid2)) =>
        offsetEq(tyList1,tyList2) andalso (tid1=tid2)
      | _ => false


  val empty =
      {
       tyMap = [],
       varMap = VMap.empty
      } : varSet

  fun insert ({tyMap,varMap} : varSet, varInfo as {id, ty,...}) =
      (
       List.app
           (fn (ty',id') =>

               if eq(ty,ty') 
               then
                 let
                   val varInfo' = 
                       case VMap.find(varMap,id') of 
                         SOME v => v
                       | _ => raise Control.Bug "variable not found"
                 in
                   raise TYPE_FOUND
                             {
                              tyMap = tyMap,
                              varMap = VMap.insert(varMap,id,varInfo')
                             }
                 end
               else
                 ()
           )
           tyMap;
       {
        tyMap = 
          case ty of
            T.TAGty _ => (ty,id)::tyMap
          | T.SIZEty _ => (ty,id)::tyMap
          | T.BITMAPty _ => (ty,id)::tyMap
          | T.FRAMEBITMAPty _ => (ty,id)::tyMap
          | T.OFFSETty _ => (ty,id)::tyMap
          | T.PADty _ => (ty,id)::tyMap
          | T.PADCONDty _ => (ty,id)::tyMap
          | _ => tyMap,
        varMap = VMap.insert(varMap,id,varInfo)
       }
      ) handle TYPE_FOUND x => x

  fun insertList (varSet,varList) =
      foldr
          (fn (varInfo,S) => insert(S,varInfo))
          varSet
          varList

  fun optimizedVariables ({tyMap,varMap} : varSet) =
      VMap.foldri
          (fn (id,varInfo,L) =>
              if id = (#id varInfo) then varInfo::L else L
          )
          []
          varMap

  fun find ({varMap,...} : varSet, {id,...} : BC.varInfo) =
      VMap.find(varMap,id)

  fun lookup (varSet,varInfo) =
      case find(varSet,varInfo) of
        SOME varInfo' => varInfo'
      | _ => raise Control.Bug "variable not found"
end
