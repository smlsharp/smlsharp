(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure RBUContext : RBUCONTEXT = struct

  structure RBUU = RBUUtils
  structure AT = AnnotatedTypes
  structure VEnv = ID.Map
  open RBUCalc

  structure index_ord:ordsig = struct 
    type ord_key = string * int

    fun compare ((label1,tid1),(label2,tid2)) =
        case Int.compare(tid1,tid2) of
          EQUAL => String.compare(label1,label2)
        | LESS => LESS
        | GREATER => GREATER
  end

  structure IndexEnv = BinaryMapFn(index_ord)

  type context =
       {
        staticEnv : 
           {
            repEnv : AT.btvRep IEnv.map, 
            btvSet : ISet.set, 
            tagEnv : (varInfo IEnv.map) ref,
            sizeEnv : (varInfo IEnv.map) ref,
            indexEnv : (varInfo IndexEnv.map) ref,
            extraVarInfoList : (varInfo list) ref,
            frameBitmapIDs : (ID.Set.set) ref
           }, 
        varEnv : varInfo VEnv.map
       }

  (******************************************************)
  (*Type utilities*)

  fun isBoundCompactTy btvSet ty =
      case ty of
        AT.BOUNDVARty tid => ISet.member(btvSet, tid)
      | AT.SINGLEty tid => ISet.member(btvSet, tid)
      | AT.UNBOXEDty tid => ISet.member(btvSet, tid)
      | AT.PADty {condTy, tyList} => isBoundCompactTy btvSet condTy
      | _ => false

  fun isBoundCompactTyList btvSet [] = false
    | isBoundCompactTyList btvSet (ty::tyList) =
      (isBoundCompactTy btvSet ty) orelse (isBoundCompactTyList btvSet tyList)

  fun isBoundTidList btvSet [] = false
    | isBoundTidList btvSet (tid::tidList) = 
      ISet.member(btvSet,tid) orelse (isBoundTidList btvSet tidList)

  fun isBoundType btvSet ty =
      case ty of
        AT.BITMAPty tyList => isBoundCompactTyList btvSet tyList
      | AT.FRAMEBITMAPty tidList => isBoundTidList btvSet tidList
      | AT.ENVBITMAPty {tyList,...} => isBoundCompactTyList btvSet tyList
      | AT.PADSIZEty {condTy, tyList} => isBoundCompactTyList btvSet (condTy::tyList)
      | AT.OFFSETty tyList => isBoundCompactTyList btvSet tyList
      | _ => false   

  fun isBoundTypeVariable ({staticEnv = {btvSet,...},...}:context,tid) = ISet.member(btvSet,tid)

  fun eqOffset ([],[]) = true
    | eqOffset (ty1::tyList1,ty2::tyList2) =
      (
       case (ty1,ty2) of
         (AT.PADty {condTy=condTy1,...}, AT.PADty {condTy=condTy2,...}) => 
         eqOffset(condTy1::tyList1,condTy2::tyList2)
       | (AT.ATOMty, AT.ATOMty) => eqOffset(tyList1,tyList2)
       | (AT.ATOMty, AT.BOXEDty) => eqOffset(tyList1,tyList2)
       | (AT.ATOMty, AT.DOUBLEty) => eqOffset(tyList1,AT.ATOMty::tyList2)
       | (AT.ATOMty, AT.SINGLEty _) => eqOffset(tyList1,tyList2)

       | (AT.BOXEDty, AT.ATOMty ) => eqOffset(tyList1,tyList2)
       | (AT.BOXEDty, AT.BOXEDty) => eqOffset(tyList1,tyList2)
       | (AT.BOXEDty, AT.DOUBLEty) => eqOffset(tyList1,AT.ATOMty::tyList2)
       | (AT.BOXEDty, AT.SINGLEty _) => eqOffset(tyList1,tyList2)

       | (AT.DOUBLEty, AT.ATOMty) => eqOffset(AT.ATOMty::tyList1,tyList2)
       | (AT.DOUBLEty, AT.BOXEDty) => eqOffset(AT.ATOMty::tyList1,tyList2)
       | (AT.DOUBLEty, AT.DOUBLEty) => eqOffset(tyList1,tyList2)
       | (AT.DOUBLEty, AT.SINGLEty _) => eqOffset(AT.ATOMty::tyList1,tyList2)

       | (AT.SINGLEty _, AT.ATOMty) => eqOffset(tyList1,tyList2)
       | (AT.SINGLEty _, AT.BOXEDty) => eqOffset(tyList1,tyList2)
       | (AT.SINGLEty _, AT.DOUBLEty) => eqOffset(tyList1,AT.ATOMty::tyList2)
       | (AT.SINGLEty _, AT.SINGLEty _) => eqOffset(tyList1,tyList2)

       | (AT.UNBOXEDty tid1, AT.UNBOXEDty tid2) => (tid1 = tid2) andalso eqOffset(tyList1,tyList2)
       | (AT.BOUNDVARty tid1, AT.BOUNDVARty tid2) => (tid1 = tid2) andalso eqOffset(tyList1,tyList2)
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
         (AT.PADty {condTy=condTy1,...}, AT.PADty {condTy=condTy2,...}) => 
         eqBitmap(condTy1::tyList1,condTy2::tyList2)
       | (AT.ATOMty, AT.ATOMty) => eqBitmap(tyList1,tyList2)
       | (AT.ATOMty, AT.DOUBLEty) => eqBitmap(tyList1,AT.ATOMty::tyList2)
       | (AT.BOXEDty, AT.BOXEDty) => eqBitmap(tyList1,tyList2)
       | (AT.DOUBLEty, AT.ATOMty) => eqBitmap(AT.ATOMty::tyList1,tyList2)
       | (AT.DOUBLEty, AT.DOUBLEty) => eqBitmap(tyList1,tyList2)
       | (AT.BOUNDVARty tid1, AT.BOUNDVARty tid2) => (tid1 = tid2) andalso eqBitmap(tyList1,tyList2)
       | (AT.SINGLEty tid1, AT.SINGLEty tid2) => (tid1 = tid2) andalso eqBitmap(tyList1,tyList2)
       | (AT.UNBOXEDty tid1, AT.UNBOXEDty tid2) => (tid1 = tid2) andalso eqBitmap(tyList1,tyList2)
       | _ => false
      )

  fun eqTidList ([],[]) = true
    | eqTidList (tid1::tidList1,tid2::tidList2) =
      (tid1=tid2) andalso eqTidList(tidList1,tidList2)
    | eqTidList _ = false

  fun eqTy (ty1,ty2) =
      case (ty1,ty2) of
        (AT.INDEXty {label = label1, recordTy = AT.BOUNDVARty tid1},
         AT.INDEXty {label = label2, recordTy = AT.BOUNDVARty tid2}) =>
        (label1=label2) andalso (tid1=tid2)
      | (AT.SIZEty tid1, AT.SIZEty tid2) => tid1 = tid2
      | (AT.TAGty tid1, AT.TAGty tid2) => tid1 = tid2
      | (AT.OFFSETty tyList1, AT.OFFSETty tyList2) => eqOffset (tyList1,tyList2)
      | (AT.BITMAPty tyList1, AT.BITMAPty tyList2) => eqBitmap (tyList1, tyList2)
      | (AT.FRAMEBITMAPty tidList1, AT.FRAMEBITMAPty tidList2) => eqTidList (tidList1, tidList2)
      | (AT.ENVBITMAPty {tyList = tyList1, fixedSizeList = fixedSizeList1},
         AT.ENVBITMAPty {tyList = tyList2, fixedSizeList = fixedSizeList2}) =>
        eqBitmap(tyList1,tyList2)
      | (AT.PADSIZEty {condTy = condTy1, tyList = tyList1},
         AT.PADSIZEty {condTy = condTy2, tyList = tyList2}) =>
        (
         case (condTy1,condTy2) of
           (AT.DOUBLEty,AT.DOUBLEty) => eqOffset(tyList1,tyList2)
         | (AT.BOUNDVARty tid1, AT.BOUNDVARty tid2) => (tid1=tid2) andalso eqOffset(tyList1,tyList2)
         | (AT.UNBOXEDty tid1, AT.UNBOXEDty tid2) => (tid1=tid2) andalso eqOffset(tyList1,tyList2)
         | _ => false
        )
      | _ => false

  (******************************************************************)
  (*searching, inserting and updating utilities*)

  fun findVariable ({varEnv,...} : context,id) = VEnv.find(varEnv,id)

  fun findByTy ty1 [] = NONE
    | findByTy ty1 ((varInfo as {ty,...} : varInfo)::rest) =
      if eqTy (ty,ty1) then SOME varInfo else findByTy ty1 rest

  fun insertVariable 
          ({staticEnv as {sizeEnv, tagEnv, indexEnv,extraVarInfoList,...}, varEnv} : context)
          (varInfo as {id,ty,...} : varInfo) =
      let
        val _ =
            case ty of 
              AT.SIZEty tid => 
              (
               sizeEnv := IEnv.insert(!sizeEnv, tid, varInfo);
               extraVarInfoList := varInfo::(!extraVarInfoList)
              )
            | AT.TAGty tid => 
              (
               tagEnv := IEnv.insert(!tagEnv, tid, varInfo);
               extraVarInfoList := varInfo::(!extraVarInfoList)
              )
            | AT.INDEXty {label, recordTy as (AT.BOUNDVARty tid)} =>
              (
               indexEnv := IndexEnv.insert(!indexEnv,(label,tid),varInfo);
               extraVarInfoList := varInfo::(!extraVarInfoList)
              )
            | AT.BITMAPty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | AT.FRAMEBITMAPty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | AT.ENVBITMAPty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | AT.OFFSETty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | AT.PADSIZEty _ => extraVarInfoList := varInfo::(!extraVarInfoList)
            | _ => ()
      in
        {
         staticEnv = staticEnv,
         varEnv = VEnv.insert(varEnv,id,varInfo)
        }
      end
   
  fun insertVariables context varInfoList =
      foldl (fn (varInfo,C) => insertVariable C varInfo) context varInfoList


  fun mergeVariable 
          (context as {staticEnv as {btvSet,extraVarInfoList,...}, varEnv} : context)
          (varInfo as {id,displayName,ty,varKind} : varInfo) =
      case VEnv.find(varEnv,id) of
        SOME newVarInfo => (newVarInfo, context)
      | _ =>
        (
         case findByTy ty (!extraVarInfoList) of
           SOME newVarInfo => (newVarInfo, context)
         | _ =>
           let
             val newVarKind = if isBoundType btvSet ty then LOCAL else FREE
             val newVarInfo = {id = id, displayName = displayName, ty = ty, varKind = ref newVarKind}
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
        SOME varInfo => (RBUVAR {varInfo = varInfo, loc = loc}, context)
      | _ =>
        let
          val varInfo = RBUU.newVar FREE (AT.TAGty tid)
        in
          (RBUVAR {varInfo = varInfo, loc = loc}, insertVariable context varInfo)
        end

  fun lookupSize 
          (context as {staticEnv as {sizeEnv,...},varEnv} : context)
          (tid, loc) =
      case IEnv.find(!sizeEnv,tid) of
        SOME varInfo => (RBUVAR {varInfo = varInfo, loc = loc}, context)
      | _ =>
        let
          val varInfo = RBUU.newVar FREE (AT.SIZEty tid)
        in
          (RBUVAR {varInfo = varInfo, loc = loc}, insertVariable context varInfo)
        end

  fun lookupIndex 
          (context as {staticEnv as {indexEnv,...},varEnv} : context)
          (label, tid, loc) =
      case IndexEnv.find(!indexEnv,(label,tid)) of
        SOME varInfo => (RBUVAR {varInfo = varInfo, loc = loc}, context)
      | _ =>
        let
          val varInfo = RBUU.newVar FREE (AT.INDEXty {label = label, recordTy = AT.BOUNDVARty tid})
        in
          (RBUVAR {varInfo = varInfo, loc = loc}, insertVariable context varInfo)
        end

  fun representationOf (context as {staticEnv as {repEnv,...},...} : context, tid) =
      case IEnv.find(repEnv,tid) of
        SOME rep => rep
      | _ => raise Control.Bug ("type variable not found " ^ (Int.toString tid))

  fun listFreeVariables ({varEnv,...} : context) =
      VEnv.foldr
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
                   AT.BITMAPty _ => true
                 | AT.ENVBITMAPty _ => true
                 | AT.FRAMEBITMAPty _ => true
                 | AT.OFFSETty _ => true
                 | AT.PADSIZEty _ => true
                 | _ => false
                ) 
              | _ => false
          )
          (!extraVarInfoList)

  fun getFrameBitmapIDs ({staticEnv as {frameBitmapIDs,...},...} : context) = !frameBitmapIDs

  fun registerFrameBitmapID ({staticEnv as {frameBitmapIDs,...},...} : context) id =
      frameBitmapIDs := ID.Set.add(!frameBitmapIDs,id)

  (**************************************************************)

  fun createEmptyContext () = 
      {
       staticEnv = 
         {
          repEnv = IEnv.empty,
          btvSet = ISet.empty,
          tagEnv = ref (IEnv.empty),
          sizeEnv = ref (IEnv.empty),
          indexEnv = ref (IndexEnv.empty),
          extraVarInfoList = ref [],
          frameBitmapIDs = ref (ID.Set.empty)
         },
       varEnv = VEnv.empty
      } : context

  fun createContext ({staticEnv as {repEnv,...},...} : context) (btvEnv : AT.btvEnv) =
      let
        val (repEnv, btvSet) =
            IEnv.foldl
                (fn ({id,representationRef,...},(repEnv,btvSet)) =>
                    (IEnv.insert(repEnv,id,!representationRef),ISet.add(btvSet,id))
                )
                (repEnv,ISet.empty)
                btvEnv
      in
        {
         staticEnv = 
         {
          repEnv = repEnv,
          btvSet = btvSet,
          tagEnv = ref (IEnv.empty),
          sizeEnv = ref (IEnv.empty),
          indexEnv = ref (IndexEnv.empty),
          extraVarInfoList = ref [],
          frameBitmapIDs = ref (ID.Set.empty)
         },
         varEnv = VEnv.empty
        } : context
      end

  fun extendBtvEnv ({staticEnv as {repEnv,btvSet,tagEnv, sizeEnv, indexEnv, extraVarInfoList, frameBitmapIDs},
                     varEnv} : context) (btvEnv : AT.btvEnv) =
      let
        val repEnv = 
            IEnv.foldl
                (fn ({id,representationRef,...},repEnv) => IEnv.insert(repEnv,id,!representationRef))
                repEnv
                btvEnv
      in
        {
         staticEnv = 
         {
          repEnv = repEnv,
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

end
