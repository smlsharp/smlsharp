(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
structure RBUContext : RBUCONTEXT = struct
 *)
structure RBUContext = struct

  structure RBUU = RBUUtils
  structure AT = AnnotatedTypes
  structure RT = RBUTypes
  open RBUCalc

  structure index_ord:ORD_KEY = struct 
    type ord_key = string * int

    fun compare ((label1,tid1),(label2,tid2)) =
        case Int.compare(tid1,tid2) of
          EQUAL => String.compare(label1,label2)
        | LESS => LESS
        | GREATER => GREATER
  end

  structure IndexEnv = BinaryMapMaker(index_ord)

  type context =
       {
        staticEnv : 
           {
            btvEnv : AT.btvKind IEnv.map, 
            btvSet : ISet.set,
            tagEnv : (varInfo IEnv.map) ref,
            sizeEnv : (varInfo IEnv.map) ref,
            indexEnv : (varInfo IndexEnv.map) ref,
            extraVarInfoList : (varInfo list) ref,
            frameBitmapIDs : (VarIdSet.set) ref
           }, 
        varEnv : varInfo VarIdEnv.map
       }

  (******************************************************)
  (*Type utilities*)

  fun isBoundCompactTy btvSet ty =
      case ty of
        RT.BOUNDVARty tid => ISet.member(btvSet, tid)
      | RT.SINGLEty tid => ISet.member(btvSet, tid)
      | RT.UNBOXEDty tid => ISet.member(btvSet, tid)
      | RT.PADty {condTy, tyList} => isBoundCompactTy btvSet condTy
      | _ => false

  fun isBoundCompactTyList btvSet [] = false
    | isBoundCompactTyList btvSet (ty::tyList) =
      (isBoundCompactTy btvSet ty) orelse (isBoundCompactTyList btvSet tyList)

  fun isBoundTidList btvSet [] = false
    | isBoundTidList btvSet (tid::tidList) = 
      ISet.member(btvSet,tid) orelse (isBoundTidList btvSet tidList)

  fun isBoundType btvSet ty =
      case ty of
        RT.BITMAPty tyList => isBoundCompactTyList btvSet tyList
      | RT.FRAMEBITMAPty tidList => isBoundTidList btvSet tidList
      | RT.ENVBITMAPty {tyList,...} => isBoundCompactTyList btvSet tyList
      | RT.PADSIZEty {condTy, tyList} => isBoundCompactTyList btvSet (condTy::tyList)
      | RT.OFFSETty tyList => isBoundCompactTyList btvSet tyList
      | _ => false   

  fun isBoundTypeVariable ({staticEnv = {btvSet,...},...}:context,tid) = ISet.member(btvSet, tid)

  fun eqOffset ([],[]) = true
    | eqOffset (ty1::tyList1,ty2::tyList2) =
      (
       case (ty1,ty2) of
         (RT.PADty {condTy=condTy1,...}, RT.PADty {condTy=condTy2,...}) => 
         eqOffset(condTy1::tyList1,condTy2::tyList2)
       | (RT.ATOMty, RT.ATOMty) => eqOffset(tyList1,tyList2)
       | (RT.ATOMty, RT.BOXEDty) => eqOffset(tyList1,tyList2)
       | (RT.ATOMty, RT.DOUBLEty) => eqOffset(tyList1,RT.ATOMty::tyList2)
       | (RT.ATOMty, RT.SINGLEty _) => eqOffset(tyList1,tyList2)

       | (RT.BOXEDty, RT.ATOMty ) => eqOffset(tyList1,tyList2)
       | (RT.BOXEDty, RT.BOXEDty) => eqOffset(tyList1,tyList2)
       | (RT.BOXEDty, RT.DOUBLEty) => eqOffset(tyList1,RT.ATOMty::tyList2)
       | (RT.BOXEDty, RT.SINGLEty _) => eqOffset(tyList1,tyList2)

       | (RT.DOUBLEty, RT.ATOMty) => eqOffset(RT.ATOMty::tyList1,tyList2)
       | (RT.DOUBLEty, RT.BOXEDty) => eqOffset(RT.ATOMty::tyList1,tyList2)
       | (RT.DOUBLEty, RT.DOUBLEty) => eqOffset(tyList1,tyList2)
       | (RT.DOUBLEty, RT.SINGLEty _) => eqOffset(RT.ATOMty::tyList1,tyList2)

       | (RT.SINGLEty _, RT.ATOMty) => eqOffset(tyList1,tyList2)
       | (RT.SINGLEty _, RT.BOXEDty) => eqOffset(tyList1,tyList2)
       | (RT.SINGLEty _, RT.DOUBLEty) => eqOffset(tyList1,RT.ATOMty::tyList2)
       | (RT.SINGLEty _, RT.SINGLEty _) => eqOffset(tyList1,tyList2)

       | (RT.UNBOXEDty tid1, RT.UNBOXEDty tid2) => (tid1 = tid2) andalso eqOffset(tyList1,tyList2)
       | (RT.BOUNDVARty tid1, RT.BOUNDVARty tid2) => (tid1 = tid2) andalso eqOffset(tyList1,tyList2)
       | _ => false
      )
    | eqOffset _ = false

  fun eqBitmap([],[]) = true
    | eqBitmap([],tyList) = 
      (case RBUU.constBitmap tyList of SOME 0w0 => true | _ => false)
    | eqBitmap(tyList,[]) = 
      (case RBUU.constBitmap tyList of SOME 0w0 => true | _ => false)
    | eqBitmap(ty1::tyList1,ty2::tyList2) =
      (
       case (ty1,ty2) of
         (RT.PADty {condTy=condTy1,...}, RT.PADty {condTy=condTy2,...}) => 
         eqBitmap(condTy1::tyList1,condTy2::tyList2)
       | (RT.ATOMty, RT.ATOMty) => eqBitmap(tyList1,tyList2)
       | (RT.ATOMty, RT.DOUBLEty) => eqBitmap(tyList1,RT.ATOMty::tyList2)
       | (RT.BOXEDty, RT.BOXEDty) => eqBitmap(tyList1,tyList2)
       | (RT.DOUBLEty, RT.ATOMty) => eqBitmap(RT.ATOMty::tyList1,tyList2)
       | (RT.DOUBLEty, RT.DOUBLEty) => eqBitmap(tyList1,tyList2)
       | (RT.BOUNDVARty tid1, RT.BOUNDVARty tid2) => (tid1 = tid2) andalso eqBitmap(tyList1,tyList2)
       | (RT.SINGLEty tid1, RT.SINGLEty tid2) => (tid1 = tid2) andalso eqBitmap(tyList1,tyList2)
       | (RT.UNBOXEDty tid1, RT.UNBOXEDty tid2) => (tid1 = tid2) andalso eqBitmap(tyList1,tyList2)
       | _ => false
      )

  fun eqTidList ([],[]) = true
    | eqTidList (tid1::tidList1,tid2::tidList2) =
      (tid1=tid2) andalso eqTidList(tidList1,tidList2)
    | eqTidList _ = false

  fun eqTy (ty1,ty2) =
      case (ty1,ty2) of
        (RT.INDEXty {label = label1, recordTy = RT.BOUNDVARty tid1},
         RT.INDEXty {label = label2, recordTy = RT.BOUNDVARty tid2}) =>
        (label1=label2) andalso (tid1=tid2)
      | (RT.SIZEty tid1, RT.SIZEty tid2) => tid1 = tid2
      | (RT.TAGty tid1, RT.TAGty tid2) => tid1 = tid2
      | (RT.OFFSETty tyList1, RT.OFFSETty tyList2) => eqOffset (tyList1,tyList2)
      | (RT.BITMAPty tyList1, RT.BITMAPty tyList2) => eqBitmap (tyList1, tyList2)
      | (RT.FRAMEBITMAPty tidList1, RT.FRAMEBITMAPty tidList2) => eqTidList (tidList1, tidList2)
      | (RT.ENVBITMAPty {tyList = tyList1, fixedSizeList = fixedSizeList1},
         RT.ENVBITMAPty {tyList = tyList2, fixedSizeList = fixedSizeList2}) =>
        eqBitmap(tyList1,tyList2)
      | (RT.PADSIZEty {condTy = condTy1, tyList = tyList1},
         RT.PADSIZEty {condTy = condTy2, tyList = tyList2}) =>
        (
         case (condTy1,condTy2) of
           (RT.DOUBLEty,RT.DOUBLEty) => eqOffset(tyList1,tyList2)
         | (RT.BOUNDVARty tid1, RT.BOUNDVARty tid2) => (tid1=tid2) andalso eqOffset(tyList1,tyList2)
         | (RT.UNBOXEDty tid1, RT.UNBOXEDty tid2) => (tid1=tid2) andalso eqOffset(tyList1,tyList2)
         | _ => false
        )
      | _ => false

  (******************************************************************)
  (*searching, inserting and updating utilities*)

  fun findVariable ({varEnv,...} : context,id) = VarIdEnv.find(varEnv,id)

  fun findByTy ty1 [] = NONE
    | findByTy ty1 ((varInfo as {ty,...} : varInfo)::rest) =
      if eqTy (ty,ty1) then SOME varInfo else findByTy ty1 rest

  fun insertVariableWithId
          ({staticEnv as {sizeEnv, tagEnv, indexEnv,extraVarInfoList,...}, varEnv} : context)
          (varId, varInfo as {ty,displayName,...} : varInfo) =
      let
(*
        val _ =
          (
           print "inserted var name\n";
           print displayName;
           print "\nvarid\n";
           print (Control.prettyPrint (ID.format_id varId));
           print "\n"
           )
*)
        val _ =
            case ty of 
              RT.SIZEty tid => 
              (
               sizeEnv := IEnv.insert(!sizeEnv, tid, varInfo);
               extraVarInfoList := varInfo::(!extraVarInfoList)
              )
            | RT.TAGty tid => 
              (
               tagEnv := IEnv.insert(!tagEnv, tid, varInfo);
               extraVarInfoList := varInfo::(!extraVarInfoList)
              )
            | RT.INDEXty {label, recordTy as (RT.BOUNDVARty tid)} =>
              (
               indexEnv := IndexEnv.insert(!indexEnv,(label,tid),varInfo);
               extraVarInfoList := varInfo::(!extraVarInfoList)
              )
            | RT.BITMAPty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | RT.FRAMEBITMAPty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | RT.ENVBITMAPty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | RT.OFFSETty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | RT.PADSIZEty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | _ => ()
      in
        {
         staticEnv = staticEnv,
         varEnv = VarIdEnv.insert(varEnv,varId,varInfo)
        } : context
      end
   
  fun insertVariable context (varInfo as {varId,ty,...} : varInfo)  =
    insertVariableWithId context (varId, varInfo)

  fun insertVariablesWithId context IdVarInfoList =
      foldl (fn (idVarInfo,C) => insertVariableWithId C idVarInfo) context IdVarInfoList

  fun insertVariables context varInfoList =
      foldl (fn (varInfo,C) => insertVariable C varInfo) context varInfoList

  fun mergeVariable 
          (context as {staticEnv as {btvSet,extraVarInfoList,...}, varEnv} : context)
          (varInfo as {varId,displayName,ty,varKind} : varInfo) =
      case VarIdEnv.find(varEnv,varId) of
        SOME newVarInfo => (newVarInfo, context)
      | _ =>
        (
         case findByTy ty (!extraVarInfoList) of
           SOME newVarInfo => (newVarInfo, context)
         | _ =>
           let
             val newVarKind = if isBoundType btvSet ty then LOCAL else FREE
             val newVarInfo = {varId = varId, displayName = displayName, ty = ty, varKind = ref newVarKind}
           in
             (newVarInfo, insertVariable context newVarInfo)
           end
        )

  fun mergeVariables context varInfoList =
      foldr
          (fn (varInfo,(L,C)) =>
              let
                val (newVarInfo, newC) = mergeVariable C varInfo
              in 
                (newVarInfo::L, newC)
              end
          )
          ([],context)
          varInfoList

  fun lookupTag 
          (context as {staticEnv as {tagEnv,...},varEnv} : context)
          (tid, loc) =
      case IEnv.find(!tagEnv,tid) of
        SOME varInfo =>
        (RBUVAR {varInfo = varInfo, valueSizeExp = RBUU.constSizeExp (#ty varInfo,loc), loc = loc}, context)
      | _ =>
        let
          val varInfo = Counters.newRBUVar FREE (RT.TAGty tid)
        in
          (RBUVAR {varInfo = varInfo, valueSizeExp = RBUU.constSizeExp (#ty varInfo,loc), loc = loc},
           insertVariable context varInfo)
        end

  fun lookupSize 
          (context as {staticEnv as {sizeEnv,...},varEnv} : context)
          (tid, loc) =
      case IEnv.find(!sizeEnv,tid) of
        SOME varInfo =>
        (RBUVAR {varInfo = varInfo, valueSizeExp = RBUU.constSizeExp (#ty varInfo,loc), loc = loc}, context)
      | _ =>
        let
          val varInfo = Counters.newRBUVar FREE (RT.SIZEty tid)
        in
          (RBUVAR {varInfo = varInfo, valueSizeExp = RBUU.constSizeExp (#ty varInfo,loc), loc = loc},
           insertVariable context varInfo)
        end

  fun lookupIndex 
          (context as {staticEnv as {indexEnv,...},varEnv} : context)
          (label, tid, loc) =
      case IndexEnv.find(!indexEnv,(label,tid)) of
        SOME varInfo =>
        (RBUVAR {varInfo = varInfo, valueSizeExp = RBUU.constSizeExp (#ty varInfo,loc), loc = loc}, context)
      | _ =>
        let
          val varInfo = Counters.newRBUVar FREE (RT.INDEXty {label = label, recordTy = RT.BOUNDVARty tid})
        in
          (RBUVAR {varInfo = varInfo, valueSizeExp = RBUU.constSizeExp (#ty varInfo,loc), loc = loc},
           insertVariable context varInfo)
        end

(*
  fun representationOf (context as {staticEnv as {repEnv,...},...} : context, tid) =
      case IEnv.find(repEnv,tid) of
        SOME rep => rep
      | _ => raise Control.Bug ("type variable not found " ^ (Int.toString tid))
*)

  fun listFreeVariables ({varEnv,...} : context) =
      VarIdEnv.foldr
          (fn (varInfo as {varKind,...},L) =>
              case !varKind of
                FREE => varInfo::L
              | FREEWORD _ => raise Control.Bug "should not be computed"
              | _ => L
          )
          []
          varEnv

  fun listExtraLocalVariables (context as {staticEnv as {extraVarInfoList,...},...} : context) =
      List.filter
          (fn {ty,varKind,...} => 
              case !varKind of 
                LOCAL => 
                (
                 case ty of
                   RT.BITMAPty _ => true
                 | RT.ENVBITMAPty _ => true
                 | RT.FRAMEBITMAPty _ => true
                 | RT.OFFSETty _ => true
                 | RT.PADSIZEty _ => true
                 | _ => false
                ) 
              | _ => false
          )
          (!extraVarInfoList)

  fun getFrameBitmapIDs ({staticEnv as {frameBitmapIDs,...},...} : context) = !frameBitmapIDs

  fun registerFrameBitmapID ({staticEnv as {frameBitmapIDs,...},...} : context) id =
      frameBitmapIDs := VarIdSet.add(!frameBitmapIDs,id)

  (**************************************************************)

  fun createEmptyContext () = 
      {
       staticEnv = 
         {
          btvEnv = IEnv.empty,
          btvSet = ISet.empty,
          tagEnv = ref (IEnv.empty),
          sizeEnv = ref (IEnv.empty),
          indexEnv = ref (IndexEnv.empty),
          extraVarInfoList = ref [],
          frameBitmapIDs = ref (VarIdSet.empty)
         },
       varEnv = VarIdEnv.empty
      } : context

  fun addKeys (set, map) =
      IEnv.foldli (fn (k,_,set) => ISet.add (set, k)) set map

  fun createContext ({staticEnv as {btvEnv,...},...} : context) (newBtvEnv : AT.btvEnv) =
      let
        val btvEnv = IEnv.unionWith #1 (newBtvEnv, btvEnv)
        val btvSet = addKeys (ISet.empty, newBtvEnv)
(*
        val (repEnv, btvSet) =
            IEnv.foldl
                (fn ({id,representationRef,...},(repEnv,btvSet)) =>
                    (IEnv.insert(repEnv,id,!representationRef),ISet.add(btvSet,id))
                )
                (repEnv,ISet.empty)
                btvEnv
*)
      in
        {
         staticEnv = 
         {
          btvEnv = btvEnv,
          btvSet = btvSet,
          tagEnv = ref (IEnv.empty),
          sizeEnv = ref (IEnv.empty),
          indexEnv = ref (IndexEnv.empty),
          extraVarInfoList = ref [],
          frameBitmapIDs = ref (VarIdSet.empty)
         },
         varEnv = VarIdEnv.empty
        } : context
      end

  fun extendBtvEnv ({staticEnv as {btvEnv,btvSet,tagEnv, sizeEnv, indexEnv, extraVarInfoList, frameBitmapIDs},
                     varEnv} : context) (newBtvEnv : AT.btvEnv) =
      let
        val btvEnv = IEnv.unionWith #1 (newBtvEnv, btvEnv)
(*
        val repEnv = 
            IEnv.foldl
                (fn ({id,representationRef,...},repEnv) => IEnv.insert(repEnv,id,!representationRef))
                repEnv
                btvEnv
*)
      in
        {
         staticEnv = 
         {
          btvEnv = btvEnv,
          btvSet = btvSet,
          tagEnv = tagEnv,
          sizeEnv = sizeEnv,
          indexEnv = indexEnv,
          extraVarInfoList = extraVarInfoList,
          frameBitmapIDs = frameBitmapIDs
         },
         varEnv = varEnv
        } : context
      end

  fun fullyExtendBtvEnv ({staticEnv as {btvEnv,btvSet,tagEnv, sizeEnv, indexEnv, extraVarInfoList, frameBitmapIDs},
                     varEnv} : context) (newBtvEnv : AT.btvEnv) =
      let
        val btvEnv = IEnv.unionWith #1 (newBtvEnv, btvEnv)
        val btvSet = addKeys (btvSet, newBtvEnv)
(*
        val (repEnv, btvSet) =
            IEnv.foldl
                (fn ({id,representationRef,...},(repEnv,btvSet)) =>
                    (IEnv.insert(repEnv,id,!representationRef),ISet.add(btvSet,id))
                )
                (repEnv,btvSet)
                btvEnv
*)
      in
        {
         staticEnv = 
         {
          btvEnv = btvEnv,
          btvSet = btvSet,
          tagEnv = tagEnv,
          sizeEnv = sizeEnv,
          indexEnv = indexEnv,
          extraVarInfoList = extraVarInfoList,
          frameBitmapIDs = frameBitmapIDs
         },
         varEnv = varEnv
        } : context
      end

  fun removeTidsAndVarIds 
    (context as 
     {staticEnv as 
      {
       btvEnv = btvEnvIEnv,
       btvSet = btvSetISet,
       tagEnv = tagEnvIEnvRef, 
       sizeEnv = sizeEnvIEnvRef, 
       indexEnv = indexEnvIndexEnvRef, 
       extraVarInfoList = extraVarInfoListRef, 
       frameBitmapIDs = frameBitmapIDsSetRef
       },
      varEnv = varEnvVarIdEnv} : context) 
    (extaBtvEnvIEnv : AT.btvEnv) 
    =
      let
        val localVarInfoList = listExtraLocalVariables context

        val btvSet =
            IEnv.foldli
                (fn (id, _, btvSet) => ISet.add(btvSet,id))
                ISet.empty
                extaBtvEnvIEnv

        fun tvInBtvSet ty =
            case ty of 
              RT.SIZEty tid => ISet.member(btvSet, tid)
            | RT.TAGty tid => ISet.member(btvSet, tid)
            | RT.INDEXty {label, recordTy as (RT.BOUNDVARty tid)} =>
                ISet.member(btvSet, tid)
            | _ => false

        val effectiveVarIdSet =
          foldr
          (fn (varInfo as {varId, ty,...},effectiveVarIdSet) =>
           if tvInBtvSet ty then 
             VarIdSet.add(effectiveVarIdSet,varId)
           else effectiveVarIdSet)
          VarIdSet.empty
          localVarInfoList

(*
        val btvSetISet =
          ISet.foldl
          (fn (tid, btvSetISet)  => 
             ISet.delete(btvSetISet, tid) handle LibBase.NotFound => btvSetISet
          )
          btvSetISet
          btvSet

        val repEnvIEnv = 
          ISet.foldl
          (fn (id, repEnvIEnv)  => 
             (#1 (IEnv.remove(repEnvIEnv, id))) handle LibBase.NotFound => repEnvIEnv
          )
          repEnvIEnv
          btvSet
*)
        val _ =
          tagEnvIEnvRef :=
          ISet.foldl
          (fn (tid, tagEnv) => 
             (#1 (IEnv.remove(tagEnv, tid))) handle LibBase.NotFound => tagEnv
           )
          (!tagEnvIEnvRef)
          btvSet

        val _ =
          sizeEnvIEnvRef :=
          ISet.foldl
          (fn (tid, sizeEnv) => 
             (#1 (IEnv.remove(sizeEnv, tid))) handle LibBase.NotFound => sizeEnv
           )
          (!sizeEnvIEnvRef)
          btvSet

        val _ =
          indexEnvIndexEnvRef :=
          IndexEnv.foldri
          (fn ((label,tid), varInfo, indexEnv) => 
           if ISet.member(btvSet, tid) then
             indexEnv
           else IndexEnv.insert(indexEnv,(label,tid),varInfo)
           )
          IndexEnv.empty
          (!indexEnvIndexEnvRef)

        val _  =
          extraVarInfoListRef :=
          foldr 
          (fn (varInfo as {varId,...},extraVarInfoList) =>
               if VarIdSet.member(effectiveVarIdSet, varId) then
                 extraVarInfoList
               else varInfo :: extraVarInfoList
          )
          nil
          (!extraVarInfoListRef)

        val varEnvVarIdEnv = 
          VarIdSet.foldl
          (fn (id, varEnv) => 
             (#1 (VarIdEnv.remove(varEnvVarIdEnv, id))) handle LibBase.NotFound => varEnvVarIdEnv
           )
          varEnvVarIdEnv
          effectiveVarIdSet
      in
        {
         staticEnv =
          {
           btvEnv = btvEnvIEnv,
           btvSet = btvSetISet,
           tagEnv = tagEnvIEnvRef, 
           sizeEnv = sizeEnvIEnvRef, 
           indexEnv = indexEnvIndexEnvRef, 
           extraVarInfoList = extraVarInfoListRef, 
           frameBitmapIDs = frameBitmapIDsSetRef
           },
         varEnv = varEnvVarIdEnv
         } 
      end

end
