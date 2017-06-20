structure TyToReifiedTy =
struct
  structure T = Types
  structure TB = TypesBasics
  structure BT = BuiltinTypes
  structure R = ReifiedTy
  structure DL = DatatypeLayout

  exception TyToReifiedTy
  exception InstantiateFail
  exception GetConFail

  fun printTy ty = 
     print (T.tyToString ty)
  fun printReifiedTy ty = 
     print (R.reifiedTyToString ty)
  fun eqTyCon ({id=id1,...}, {id=id2,...}) = TypID.eq(id1, id2)

  fun symbolMapToSEnv symbolMap = 
      SymbolEnv.foldli
      (fn (l, v, senv) =>
          SEnv.insert(senv, Symbol.symbolToString l, v))
      SEnv.empty
      symbolMap

  fun convertLayout layout =
      case layout of
      DL.LAYOUT_TAGGED taggedLayout => R.LAYOUT_TAGGED (convertTaggedLayout taggedLayout)
    | DL.LAYOUT_ARG_OR_NULL {wrap = wrap} => R.LAYOUT_ARG_OR_NULL {wrap = wrap}
    | DL.LAYOUT_SINGLE_ARG {wrap = wrap} => R.LAYOUT_SINGLE_ARG  {wrap = wrap}
    | DL.LAYOUT_CHOICE {falseName = name} => R.LAYOUT_CHOICE {falseName= Symbol.symbolToString name}
    | DL.LAYOUT_SINGLE => R.LAYOUT_SINGLE 
    | DL.LAYOUT_REF => raise Bug.Bug "LAYOUT_REF to convertLayout"
  and convertTaggedLayout taggedLayout = 
      case taggedLayout of
      DL.TAGGED_RECORD {tagMap} =>
      R.TAGGED_RECORD {tagMap = symbolMapToSEnv tagMap}
    | DL.TAGGED_OR_NULL {tagMap, nullName} =>
      R.TAGGED_OR_NULL {tagMap = symbolMapToSEnv tagMap, nullName = Symbol.symbolToString  nullName}
    | DL.TAGGED_TAGONLY {tagMap} =>
      R.TAGGED_TAGONLY {tagMap = symbolMapToSEnv tagMap}

  fun oneArg [argTy] = argTy
    | oneArg _ = raise Bug.Bug "Datatype Arity"

  fun sizeOf ty = 
      case TypeLayout2.runtimeTy BoundTypeVarID.Map.empty ty of
        SOME rty => TypeLayout2.sizeOf rty
      | NONE => 0 (* error value *)

  fun traverseTy ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon = {dtyKind = T.DTY, id, conSet,...}, args} =>
        (case R.findConSet id of
           SOME _ => app traverseTy args
         | NONE =>
           let
             val _ = R.setConSet (id, R.emptyConSet)
             val _ = app traverseTy args
             val rigidConSet = 
                 SymbolEnv.foldli
                   (fn (label, NONE, senv) => 
                       SEnv.insert(senv, Symbol.symbolToString label, NONE)
                     | (label, SOME f, senv) => 
                       SEnv.insert(senv, Symbol.symbolToString label, SOME (f ()))
                   )
                   SEnv.empty
                   conSet
             val _ = SEnv.app
                     (fn NONE => ()
                       | SOME ty => traverseTy ty)
                     rigidConSet
             val reifiedConSet =
                 SEnv.map (fn NONE => NONE
                                 | SOME ty => SOME (toReifiedTy ty))
                               rigidConSet
           in
             R.setConSet(id, reifiedConSet)
           end
        )
      | T.CONSTRUCTty {tyCon, args} => app traverseTy args
      | T.SINGLETONty _ => ()
      | T.BACKENDty  _ => ()
      | T.ERRORty => ()
      | T.DUMMYty _ => ()
      | T.TYVARty _ => ()
      | T.BOUNDVARty _ => ()
      | T.FUNMty (tyList, ty) =>(map traverseTy tyList; traverseTy ty)
      | T.RECORDty tyMap => RecordLabel.Map.app traverseTy tyMap
      | T.POLYty {boundtvars, constraints, body} =>
        (map traverseConstraint constraints; traverseTy body)

  and traverseConstraint (T.JOIN {res, args=(ty1,ty2), loc}) =
      (traverseTy res; traverseTy ty1; traverseTy ty2)

  and toReifiedTy ty =
      case TB.derefTy ty of
        T.BOUNDVARty tid => R.BOUNDVARty tid
      | T.CONSTRUCTty {tyCon, args} =>
        if eqTyCon (tyCon, BT.boolTyCon) then R.BOOLty
        else if eqTyCon (tyCon, BT.intTyCon) then R.INTty
        else if eqTyCon (tyCon, BT.int8TyCon) then R.INT8ty
        else if eqTyCon (tyCon, BT.int16TyCon) then R.INT16ty
        else if eqTyCon (tyCon, BT.int64TyCon) then R.INT64ty
        else if eqTyCon (tyCon, BT.intInfTyCon) then R.INTINFty
        else if eqTyCon (tyCon, BT.wordTyCon) then R.WORDty
        else if eqTyCon (tyCon, BT.word8TyCon) then R.WORD8ty
        else if eqTyCon (tyCon, BT.word16TyCon) then R.WORD16ty
        else if eqTyCon (tyCon, BT.word64TyCon) then R.WORD64ty
        else if eqTyCon (tyCon, BT.charTyCon) then R.CHARty
        else if eqTyCon (tyCon, BT.stringTyCon) then R.STRINGty
        else if eqTyCon (tyCon, BT.realTyCon) then R.REALty
        else if eqTyCon (tyCon, BT.real32TyCon) then R.REAL32ty
        else if eqTyCon (tyCon, BT.unitTyCon) then R.UNITty
        else if eqTyCon (tyCon, BT.codeptrTyCon) then R.CODEPTRty
        else if eqTyCon (tyCon, BT.exnTyCon) then R.EXNty
        else if eqTyCon (tyCon, BT.exntagTyCon) then R.EXNTAGty
        else if eqTyCon (tyCon, BT.ptrTyCon) then 
          R.PTRty  (toReifiedTy (oneArg args))
        else if eqTyCon (tyCon, BT.arrayTyCon) then 
          R.ARRAYty (toReifiedTy (oneArg args))
        else if eqTyCon (tyCon, BT.vectorTyCon) then 
          R.VECTORty (toReifiedTy (oneArg args))
        else if eqTyCon (tyCon, BT.refTyCon) then 
          R.REFty (toReifiedTy (oneArg args))
        else if eqTyCon (tyCon, BT.listTyCon) then 
          R.LISTty (toReifiedTy (oneArg args))
        else if eqTyCon (tyCon, BT.optionTyCon) then 
          R.OPTIONty (toReifiedTy (oneArg args))
        else if eqTyCon (tyCon, BT.ptrTyCon) then 
          R.PTRty (toReifiedTy (oneArg args))
        else if not (SymbolEnv.isEmpty (#conSet tyCon)) then
          R.DATATYPEty 
            {longsymbol = #longsymbol tyCon, 
             id = #id tyCon, 
             layout = convertLayout (DatatypeLayout.datatypeLayout tyCon),
             args = map toReifiedTy args,
             size = sizeOf ty
            }
        else
          R.OPAQUEty
              {longsymbol = #longsymbol tyCon, 
               id = #id tyCon, 
               args = map toReifiedTy args,
               size = sizeOf ty}
      | T.RECORDty tyFields =>
        R.RECORDty (RecordLabel.Map.map toReifiedTy tyFields)
      | T.POLYty {boundtvars, constraints, body} =>
        R.POLYty {boundenv = BoundTypeVarID.Map.mapi (fn (i,_) => i) boundtvars,
                  body = toReifiedTy body}
      | T.FUNMty _ => R.FUNty
      | T.TYVARty _ => R.TYVARty
      | T.DUMMYty _ =>
        (case TypeLayout2.runtimeTy BoundTypeVarID.Map.empty ty of
           NONE => raise Bug.Bug "toReifiedTy: DUMMYty"
         | SOME rty =>
           R.DUMMYty {size = Word.fromInt (TypeLayout2.sizeOf rty),
                      boxed = case TypeLayout2.tagOf rty of
                                RuntimeTypes.TAG_BOXED => true
                              | RuntimeTypes.TAG_UNBOXED => false})
      | T.ERRORty => R.ERRORty
      | _ => 
        let
          val size = sizeOf ty
        in
          (print "*** reifiedTyToExp ty ***\n";
           printTy ty;
           R.INTERNALty size)
        end

  fun traverseReifiedTyList reifiedTyList templateConSetEnv =
      foldl
      (fn (ty, templateConSetEnv) =>
          traverseReifiedTy ty templateConSetEnv)
      templateConSetEnv
      reifiedTyList
  and traverseReifiedTy reifiedTy templateConSetEnv =
      case reifiedTy of
        R.DATATYPEty {longsymbol, id, args, layout, size} =>
        if TypID.Map.inDomain(templateConSetEnv, id) then templateConSetEnv
        else
          let
            val templateConSetEnv = 
                TypID.Map.insert(templateConSetEnv, id, R.INTERNALty)
            val conSet = case R.findConSet id of 
                           NONE => 
                             (print "findconset in travserseReifiedTy\n";
                              printReifiedTy reifiedTy;
                              print "\n";
                              print "find conset in travserseReifiedTy \n";
                              raise Bug.Bug "findconset in travserseReifiedTy")
                          | SOME conset => conset
            val reifiedTyList = 
                SEnv.foldl
                (fn (NONE, reifiedTyList) =>reifiedTyList
                  | (SOME ty, reifiedTyList) => ty::reifiedTyList)
                args
                conSet
          in
            traverseReifiedTyList reifiedTyList templateConSetEnv
          end
      | R.LISTty reifiedTy => 
        traverseReifiedTy reifiedTy templateConSetEnv
      | R.ARRAYty reifiedTy =>
        traverseReifiedTy reifiedTy templateConSetEnv
      | R.VECTORty reifiedTy =>
        traverseReifiedTy reifiedTy templateConSetEnv
      | R.OPTIONty reifiedTy =>
        traverseReifiedTy reifiedTy templateConSetEnv
      | R.REFty reifiedTy =>
        traverseReifiedTy reifiedTy templateConSetEnv
      | R.RECORDty reifiedTyMap =>
        RecordLabel.Map.foldr 
        (fn (reifiedTy, templateConSetEnv) =>
            traverseReifiedTy reifiedTy templateConSetEnv)
        templateConSetEnv
        reifiedTyMap
      | R.POLYty {boundenv, body} =>
        traverseReifiedTy body templateConSetEnv
      | _ => templateConSetEnv

  fun getConSetEnv reifiedTy =
      let
        val templateConSetEnv = traverseReifiedTy reifiedTy TypID.Map.empty
        val globalConSetEnv = R.getGlobalConSetEnv ()
      in
        TypID.Map.intersectWith 
          (fn (x,y) => x)
        (globalConSetEnv, templateConSetEnv)
      end

  fun toTy ty = 
      let
        val _ = traverseTy ty
        val reifiedTy = toReifiedTy ty
        val conSetEnv = getConSetEnv reifiedTy
      in
        {conSetEnv = conSetEnv, reifiedTy = reifiedTy}
      end
end
