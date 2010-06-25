(**
 * pickler for data types declared in types module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypesPickler.sml,v 1.50 2008/08/06 17:23:41 ohori Exp $
 *)
structure TypesPickler 
  : sig
      val eqKind : Types.eqKind Pickle.pu
      val tid : FreeTypeVarID.id Pickle.pu
      val recordKind : Types.recordKind Pickle.pu
      val tvState : Types.tvState Pickle.pu
      val ty : Types.ty Pickle.pu
      val idState : Types.idState Pickle.pu
      val tyBindInfo : Types.tyBindInfo Pickle.pu
      val tvKind : Types.tvKind Pickle.pu
      val varIdInfo : Types.varIdInfo Pickle.pu
      val btvKind : Types.btvKind Pickle.pu
(*
      val boxedKind : Types.boxedKind Pickle.pu
*)
      val varEnv : Types.varEnv Pickle.pu
      val topVarEnv : Types.topVarEnv Pickle.pu
      val tyConEnv : Types.tyConEnv Pickle.pu
      val topTyConEnv : Types.topTyConEnv Pickle.pu
      val topEnv : Types.topEnv Pickle.pu
      val interfaceEnv : Types.interfaceEnv Pickle.pu
      val tyFun : Types.tyFun Pickle.pu
      val tyCon : Types.tyCon Pickle.pu
(*
      val tyName : Types.tyName Pickle.pu
      val tySpec : Types.tySpec Pickle.pu
*)
      val conPathInfo : Types.conPathInfo Pickle.pu
      val varPathInfo : Types.varPathInfo Pickle.pu
      val varId : Types.varId Pickle.pu
      val primInfo : Types.primInfo Pickle.pu
      val oprimInfo : Types.oprimInfo Pickle.pu
(*
      val strBindInfo : Types.strBindInfo Pickle.pu               
*)

      val sigBindInfo : Types.sigBindInfo Pickle.pu
      val utvEnv : Types.utvEnv Pickle.pu

      val conInfo : Types.conInfo Pickle.pu
      val Env : Types.Env Pickle.pu
      val funBindInfo : Types.funBindInfo Pickle.pu

(*
      val strInfo : Types.strInfo Pickle.pu
*)
      val funEnv : Types.funEnv Pickle.pu
      val sigEnv : Types.sigEnv Pickle.pu
      val btvEnv : Types.btvEnv Pickle.pu

      val valId : Types.valId Pickle.pu
      val valIdent : Types.valIdent Pickle.pu

      val fixity : Fixity.fixity Pickle.pu
(*
      val moduleState : Types.moduleState Pickle.pu
*)
    end =
struct

  (***************************************************************************)

  structure P = Pickle
  structure T = Types

  (***************************************************************************)

  val path = NamePickler.path

  val tyConID = TyConID.pu_ID

(*
  val tid = P.conv (T.intToTid, T.tidToInt) P.int
*)
  val tid = FreeTypeVarID.pu_ID

  val eqKind = P.enum (fn T.EQ => 0 | T.NONEQ => 1, [T.EQ, T.NONEQ])

  val constructorHasArgFlagList = P.list P.bool

  (****************************************)

  val dummyDataTyInfo =
      {
       tyCon = {name = "",
                strpath = Path.NilPath,
                tyvars = [],
                id = TyConID.generate() (* TyConID.initialID ??? *),
                abstract = false,
                eqKind = ref T.EQ,
                constructorHasArgFlagList = []
               },
       datacon = SEnv.empty
      } : T.dataTyInfo

  val (recordKindFunctions, recordKind) = P.makeNullPu T.UNIV
  val (tvStateFunctions, tvState) = P.makeNullPu (T.SUBSTITUTED T.ERRORty)
  val (tyFunctions, ty) = P.makeNullPu T.ERRORty
  val (idStateFunctions, idState) =
      P.makeNullPu (T.VARID {namePath=("",Path.NilPath), ty=T.ERRORty})
  val (tyBindInfoFunctions, tyBindInfo) =
      P.makeNullPu (T.TYCON dummyDataTyInfo)
(*
  val (sizeTagExpFunctions, sizeTagExp) = P.makeNullPu (T.ST_CONST 0)
*)

  (********************)

  (*
   * CAUTION:
   * 'data', 'tuple2', and other combinator generators take pu as argument.
   * At each time of combinator generation, these generators allocate a new
   * hash tag.
   * For example,
   * <pre>
   *   val IntIntTuple2_a = Pickler.tuple2 (Pickler.int, Pickler.int)
   *   val IntIntTuple2_b = Pickler.tuple2 (Pickler.int, Pickler.int)
   * </pre>
   * Hash tags used by hash functions of IntIntTuple2_a and IntIntTuple2_b are
   * different to each other.
   * This means that the hash functions generate different hash codes for a
   * same value.
   * This violates the assumption of hash function: same hash code should be
   * generated for a same value.
   * To avoid multiple generation of combinators of a same type, every
   * combinators used in picklers are defined here.
   *)

  val boolList = P.list P.bool
  val boolOption = P.option P.bool
  val intList = P.list P.int
  val stringOption = P.option P.string

  val tySEnv = EnvPickler.SEnv ty
  val idStateSEnv = EnvPickler.SEnv idState
  val idStateNPEnv = NameMapPickler.NPEnv idState
  val tyBindInfoSEnv = EnvPickler.SEnv tyBindInfo
  val tyBindInfoNPEnv = NameMapPickler.NPEnv tyBindInfo
  val boolSEnv = EnvPickler.SEnv P.bool

  val tyList = P.list ty

  val tyOption = P.option ty
  val tyBindInfoOption = P.option tyBindInfo
  val tvStateRef = P.refNonCycle tvState
  val eqKindRef = P.refNonCycle eqKind

  (* picklers for tuple types.
   * Tuple elements are sorted in alphabetic order of their type names.
   * But some of them are not sorted...
   *)
  val namePath = P.tuple2(P.string, path)
  val namePath_ty = P.tuple2(namePath, ty)
  val string_ty = P.tuple2(P.string, ty)
  val eqKind_recordKind = P.tuple2(eqKind, recordKind)
  val path_string_ty = P.tuple3(path, P.string, ty)
  val string_path = P.tuple2(P.string, path)
  val ty_ty = P.tuple2 (ty, ty)
  val ty_string = P.tuple2 (ty, P.string)
  val tyList_ty = P.tuple2 (tyList, ty)
  val tyList_int = P.tuple2 (tyList, P.int)
  (********************)

  val operator :
      {
       oprimId : OPrimID.id,
       oprimPolyTy : T.ty,
       name : string,
       keyTyList : T.ty list,
       instTyList : T.ty list
      } P.pu =
      P.conv
        (
         fn (oprimId, oprimPolyTy, name, keyTyList, instTyList) =>
            {oprimId=oprimId,
             oprimPolyTy = oprimPolyTy,
             name = name,
             keyTyList=keyTyList,
             instTyList=instTyList},
         fn {oprimId, oprimPolyTy, name, keyTyList, instTyList} =>
            (oprimId, oprimPolyTy, name, keyTyList, instTyList)
        )
        (P.tuple5(OPrimID.pu_ID, ty, P.string, tyList, tyList))

  val tvKind : T.tvKind P.pu =
      P.conv
        (
            fn (lambdaDepth, id, recordKind, eqKind, tyvarName) =>
               {
                 lambdaDepth = lambdaDepth,
                 id = id,
                 recordKind = recordKind,
                 eqKind = eqKind,
                 tyvarName = tyvarName
               },
            fn {lambdaDepth, id, recordKind, eqKind, tyvarName} =>
               (lambdaDepth, id, recordKind, eqKind, tyvarName)
          )
          (P.tuple5(P.int, tid, recordKind, eqKind, stringOption))

  val varId =
      let
        fun toInt (T.EXTERNAL _) = 0
          | toInt (T.INTERNAL _) = 1


        fun pu_EXTERNAL pu =
            P.con1
                T.EXTERNAL
                (fn (T.EXTERNAL x) => x
                  | _ =>
                    raise
                      Control.Bug
                        "non EXTERNAL to pu_EXTERNAL\
                        \ (types/main/TypesPickler.sml)"
                 )
                (ExternalVarID.pu_ID)

        fun pu_INTERNAL pu =
            P.con1
                T.INTERNAL
                (fn (T.INTERNAL x) => x
                  | _ =>
                    raise
                      Control.Bug
                        "non INTERNAL to pu_INTERNAL\
                        \ (types/main/TypesPickler.sml)"
                 )
                NamePickler.id
      in
        P.data (toInt, [pu_EXTERNAL, pu_INTERNAL])
      end

  val string_ty_varId = 
      P.tuple3(P.string, ty, varId)

  val varIdInfo : T.varIdInfo P.pu =
      P.conv
          (
            fn (displayName, ty, varId) =>
               {displayName = displayName, ty = ty, varId = varId},
            fn {displayName, ty, varId} => (displayName, ty, varId)
          )
          string_ty_varId

  val btvKind : T.btvKind P.pu =
      P.conv
          (
            fn (eqKind, recordKind) =>
               {eqKind = eqKind, recordKind = recordKind},
            fn {eqKind, recordKind} =>
               (eqKind, recordKind)
          )
          eqKind_recordKind
  val btvKindIEnv = EnvPickler.IEnv btvKind
  val btvKindIEnv_ty = P.tuple2(btvKindIEnv, ty)
  val btvKindIEnv_string_path_ty = P.tuple4(btvKindIEnv, P.string, path, ty)

  val varEnv : T.varEnv P.pu = idStateNPEnv
  val varEnvRef = P.refCycle NameMap.NPEnv.empty varEnv
  val topVarEnv : T.topVarEnv P.pu = idStateSEnv
  val datacon : T.topVarEnv P.pu = idStateSEnv
      
  val tyConEnv : T.tyConEnv P.pu = tyBindInfoNPEnv
  val topTyConEnv : T.topTyConEnv P.pu = tyBindInfoSEnv
  val tyFun : T.tyFun P.pu =
      P.conv
          (
           fn (tyargs, name, strpath, body) =>
              {tyargs = tyargs, name = name, strpath = strpath, body = body},
            fn {tyargs, name, strpath, body} => (tyargs, name, strpath, body)
          )
          btvKindIEnv_string_path_ty

  val tyCon : T.tyCon P.pu =
      P.conv
          (
            fn (
                 name,
                 strpath,
                 tyvars,
                 id,
                 abstract,
                 eqKind,
                 constructorHasArgFlagList
               ) =>
               {
                 name = name,
                 tyvars = tyvars,
                 strpath = strpath,
                 id = id,
                 abstract = abstract,
                 eqKind = eqKind,
                 constructorHasArgFlagList = constructorHasArgFlagList
               },
            fn {
                 name,
                 strpath,
                 tyvars,
                 id,
                 abstract,
                 eqKind,
                 constructorHasArgFlagList
               } =>
               (
                 name,
                 strpath,
                 tyvars,
                 id,
                 abstract,
                 eqKind,
                 constructorHasArgFlagList
               )
          )
          (P.tuple7
               (
                 P.string,
                 path,
                 P.list eqKind,
                 TyConID.pu_ID,
                 P.bool,
                 eqKindRef,
                 constructorHasArgFlagList
               ))

  val dataTyInfo = 
      P.conv
          (fn (tyCon, datacon) => {tyCon = tyCon, datacon = datacon},
           fn {tyCon, datacon} => (tyCon, datacon))
          (P.tuple2(tyCon, idStateSEnv))

  val tag = ExnTagID.pu_ID
  val bool_int_string_stringlist_ty_tyCon = 
      P.tuple6(P.bool, P.int, P.string, P.list P.string, ty, tyCon)

  val bool_int_string_ty_tyCon = 
      P.tuple5(P.bool, P.int, P.string, ty, tyCon)
  val bool_tag_string_ty_tyCon = 
      P.tuple5(P.bool, tag, P.string, ty, tyCon)
  val bool_int_namePath_ty_tyCon = 
      P.tuple5(P.bool, P.int, P.tuple2(P.string, path), ty, tyCon)
  val bool_tag_namePath_ty_tyCon = 
      P.tuple5(P.bool, tag, P.tuple2(P.string, path), ty, tyCon)

  val conPathInfo : T.conPathInfo P.pu =
      P.conv
          (
           fn (funtyCon, tag, namePath, ty, tyCon) =>
               {
                 funtyCon = funtyCon,
                 namePath = namePath,
                 tag = tag,
                 ty = ty,
                 tyCon = tyCon
               },
            fn {funtyCon, tag, namePath, ty, tyCon} =>
               (funtyCon, tag, namePath, ty, tyCon)
          )
          bool_int_namePath_ty_tyCon

  val exnPathInfo : T.exnPathInfo P.pu =
      P.conv
          (
           fn (funtyCon, tag, namePath, ty, tyCon) =>
               {
                 funtyCon = funtyCon,
                 namePath = namePath,
                 tag = tag,
                 ty = ty,
                 tyCon = tyCon
               },
            fn {funtyCon, tag, namePath, ty, tyCon} =>
               (funtyCon, tag, namePath, ty, tyCon)
          )
          bool_tag_namePath_ty_tyCon

  val varPathInfo : T.varPathInfo P.pu =
      P.conv
          (
            fn (namePath, ty) =>
               {namePath = namePath, ty = ty},
            fn {namePath, ty} => (namePath, ty)
          )
          namePath_ty

  val varPathInfo_int = P.tuple2 (varPathInfo, P.int)

  val primInfo : T.primInfo P.pu =
      P.conv
        (
         fn (ty, prim_or_special) =>
            {ty = ty, prim_or_special = prim_or_special},
         fn {ty, prim_or_special} => (ty, prim_or_special)
        )
        (P.tuple2 (ty, BuiltinPrimitivePickler.prim_or_special))
  val primInfoTyConIDMap = NamePickler.TyConIDMap primInfo

  val oprimInfo : T.oprimInfo P.pu =
      P.conv
          (
            fn ((oprimPolyTy, name), oprimId) =>
               {oprimPolyTy = oprimPolyTy, oprimId = oprimId, name = name},
            fn {oprimPolyTy, name, oprimId} => ((oprimPolyTy, name), oprimId)
          )
          (P.tuple2(ty_string, OPrimID.pu_ID))
          (* use ty_string for share *)

  val tyCon_tyList = P.tuple2(tyCon, P.list ty)
  (********************)

  local
    val newRecKind : T.recordKind P.pu =
        let
          fun toInt (T.OCONSTkind _) = 0
            | toInt (T.OPRIMkind _) = 1
            | toInt (T.REC _) = 2
            | toInt T.UNIV = 3

          fun pu_OCONSTkind pu =
              P.con1 
              T.OCONSTkind
              (fn T.OCONSTkind x => x
                 | _ => 
                   raise 
                     Control.Bug 
                     "non OCONSTkind to pu_OCONSTkind\
                     \ (types/main/TypesPickler.sml)"
               )
             tyList

          fun pu_OPRIMkind pu =
              P.con1 
              T.OPRIMkind
              (fn T.OPRIMkind x => x
                 | _ => 
                   raise 
                     Control.Bug 
                     "non OPRIMkind to pu_OPRIMkind\
                     \ (types/main/TypesPickler.sml)"
               )
              (P.conv
                 (fn (instances, operators) =>
                     {instances = instances, operators = operators},
                  fn {instances, operators} =>(instances, operators)
                 )
              (P.tuple2(P.list ty, P.list operator)))

          fun pu_REC pu = 
             P.con1 
             T.REC 
             (fn T.REC x => x
               | _ => 
                 raise 
                   Control.Bug 
                   "non REC to pu_REC (types/main/TypesPickler.sml)"
             ) 
             tySEnv
          fun pu_UNIV pu = P.con0 T.UNIV pu
        in
          P.data (toInt,
                  [pu_OCONSTkind,   (* 0 *)
                   pu_OPRIMkind,    (* 1 *)
                   pu_REC,               (* 2 *)
                   pu_UNIV               (* 3 *)
                 ])
        end
    val newTvState : T.tvState P.pu =
        let
          fun toInt (T.SUBSTITUTED _) = 0
            | toInt (T.TVAR _) = 1
          fun pu_SUBSTITUTED pu =
              P.con1 
              T.SUBSTITUTED 
              (fn T.SUBSTITUTED x => x
                | _ => 
                  raise 
                    Control.Bug 
                    "non SUBSTITUTED to pu_SUBSTITUTED\
                    \ (types/main/TypesPickler.sml)"
               ) 
              ty
          fun pu_TVAR pu = 
            P.con1 
            T.TVAR 
            (fn T.TVAR arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non TVAR to pu_TVAR (types/main/TypesPickler.sml)"
            ) 
            tvKind
        in
          P.data (toInt, [pu_SUBSTITUTED, pu_TVAR])
        end
    val newTy : T.ty P.pu =
        let
          fun toInt (T.ALIASty _) = 0
            | toInt (T.BOUNDVARty _) = 1
            | toInt (T.DUMMYty _) = 2
            | toInt (T.ERRORty) = 3
            | toInt (T.FUNMty _) = 4
            | toInt (T.INSTCODEty _) = 5
            | toInt (T.OPAQUEty _) = 6
            | toInt (T.POLYty _) = 7
            | toInt (T.RAWty _) = 8
            | toInt (T.RECORDty _) = 9
            | toInt (T.SPECty _) = 10
            | toInt (T.TYVARty _) = 11
(*
            | toInt (T.USERDEFINEDty _) = 11
*)
(*
            | toInt ty =
              raise
                Control.Bug
                    ("TypesPicker.toInt found unknown ty: "
                     ^ TypeFormatter.tyToString ty)
*)

          fun pu_INSTCODEty pu =
            P.con1
            T.INSTCODEty
            (fn T.INSTCODEty arg => arg
              | _ =>
                raise
                  Control.Bug 
                  "non INSTCODEty to pu_INSTCODEty\
                  \ (types/main/TypesPickler.sml)"
             )
            operator
(*
            (P.conv
             (
              fn (instTy, operator) =>
                 {instTy = instTy, operator = operator},
              fn {instTy, operator} => (instTy, operator)
             )
             (P.tuple2(ty, operator)))
*)

          fun pu_OPAQUEty pu =
              P.con1 
              T.OPAQUEty 
              (fn T.OPAQUEty arg => arg
                | _ => 
                  raise 
                    Control.Bug 
                    "non OPAQUEty to pu_OPAQUEty\
                    \ (types/main/TypesPickler.sml)"
               ) 
              (P.conv
                   (fn (tyCon, args, implTy) => 
                       {spec = {tyCon = tyCon, args = args}, 
                        implTy = implTy},
                    fn {spec = {tyCon, args}, implTy} => (tyCon, args, implTy))
                   (P.tuple3(tyCon, P.list ty, ty)))
          fun pu_ALIASty pu = 
            P.con1 
            T.ALIASty 
            (fn T.ALIASty arg => arg
                | _ => 
                  raise 
                    Control.Bug 
                    "non ALIASty to pu_ALIASty\
                    \ (types/main/TypesPickler.sml)"
             ) 
            ty_ty
          fun pu_BOUNDVARty pu =
            P.con1 
            T.BOUNDVARty 
            (fn T.BOUNDVARty arg => arg
              | _ => 
               raise 
                 Control.Bug 
                 "non BOUNDVARty to pu_BOUNDVARty\
                 \ (types/main/TypesPickler.sml)"
            ) 
            P.int
(*
          fun pu_USERDEFINEDty pu =
            P.con1
            T.USERDEFINEDty
            (fn T.USERDEFINEDty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non CONty to pu_USERDEFINEDty (types/main/TypesPickler.sml)"
            )
            (P.conv
             (
              fn (tyCon, args) => {tyCon = tyCon, args = args},
              fn {tyCon, args} => (tyCon, args)
              )
             tyCon_tyList)
*)
          fun pu_DUMMYty pu = 
            P.con1 
            T.DUMMYty 
            (fn T.DUMMYty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non DUMMYty to pu_DUMMYty (types/main/TypesPickler.sml)"
            ) 
            P.int
          fun pu_ERRORty pu = P.con0 T.ERRORty pu
          fun pu_FUNMty pu = 
            P.con1 
            T.FUNMty 
            (fn T.FUNMty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non FUNMty to pu_FUNMty (types/main/TypesPickler.sml)"
             ) 
            tyList_ty
          fun pu_POLYty pu =
            P.con1
            T.POLYty
            (fn T.POLYty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non POLYty to pu_POLYty (types/main/TypesPickler.sml)"
             )
            (P.conv
             (
              fn (boundtvars, body) =>
              {boundtvars = boundtvars, body = body},
              fn {boundtvars, body} => (boundtvars, body)
              )
             btvKindIEnv_ty)
          fun pu_RECORDty pu =
            P.con1 
            T.RECORDty 
            (fn T.RECORDty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non RECORDty to pu_RECORDty (types/main/TypesPickler.sml)"
             ) 
            tySEnv
          fun pu_SPECty pu = 
            P.con1 
            T.SPECty 
            (fn T.SPECty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non SPECty to pu_SPECty (types/main/TypesPickler.sml)"
             ) 
            (P.conv
                 (fn (tyCon, args) => {tyCon = tyCon, args = args},
                  fn {tyCon, args} => (tyCon, args))
                 tyCon_tyList)

          fun pu_TYVARty pu =
            P.con1 
            T.TYVARty 
            (fn T.TYVARty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non TYVARty to pu_TYVARty (types/main/TypesPickler.sml)"
             ) 
            tvStateRef

          fun pu_RAWty pu =
            P.con1
            T.RAWty
            (fn T.RAWty arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non RAWty to pu_RAWty (types/main/TypesPickler.sml)"
            )
            (P.conv
             (
              fn (tyCon, args) => {tyCon = tyCon, args = args},
              fn {tyCon, args} => (tyCon, args)
              )
             tyCon_tyList)
        in
          P.data
              (
                toInt,
                [ (* CAUTION: if 'pu_XXXty' is the n-th element of this list,
                   * 'toInt XXXty' must return n. *)
                 pu_ALIASty, (* 0 *)
                 pu_BOUNDVARty, (* 1 *)
                 pu_DUMMYty, (* 2 *)
                 pu_ERRORty, (* 3 *)
                 pu_FUNMty, (* 4 *)
                 pu_INSTCODEty, (* 5 *)
                 pu_OPAQUEty, (* 6 *)
                 pu_POLYty, (* 7 *)
                 pu_RAWty, (* 8 *)
                 pu_RECORDty, (* 9 *)
                 pu_SPECty, (* 10 *)
                 pu_TYVARty (* 11 *)
                ]
              )
        end

    val newIdState : T.idState P.pu =
        let
          fun toInt (T.CONID _) = 0
            | toInt (T.OPRIM _) = 1
            | toInt (T.PRIM _) = 2
            | toInt (T.VARID _) = 3
            | toInt (T.RECFUNID _) = 4
            | toInt (T.EXNID _) = 5
          fun pu_CONID pu = 
            P.con1 
            T.CONID 
            (fn T.CONID arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non CONID to pu_CONID (types/main/TypesPickler.sml)"
             ) 
            conPathInfo
          fun pu_OPRIM pu = 
            P.con1 
            T.OPRIM 
            (fn T.OPRIM arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non OPRIM to pu_OPRIM (types/main/TypesPickler.sml)"
            ) 
            oprimInfo

          fun pu_PRIM pu = 
            P.con1 
            T.PRIM 
            (fn T.PRIM arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non PRIM to pu_PRIM (types/main/TypesPickler.sml)"
             ) 
            primInfo
          fun pu_VARID pu = 
            P.con1 
            T.VARID 
            (fn T.VARID arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non VARID to pu_VARID (types/main/TypesPickler.sml)"
            ) 
            varPathInfo
          (* Ohori: 2007/8/13 Need to check this *)
          fun pu_RECFUNID pu = 
            P.con1 
            T.RECFUNID
            (fn T.RECFUNID arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non RECFUNID to pu_RECFUNID (types/main/TypesPickler.sml)"
            ) 
            varPathInfo_int
          fun pu_EXNID pu = 
            P.con1 
            T.EXNID
            (fn T.EXNID arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non CONID to pu_CONID (types/main/TypesPickler.sml)"
             ) 
            exnPathInfo
        in
          P.data
            (
             toInt,
             [pu_CONID, pu_OPRIM, pu_PRIM, pu_VARID, pu_RECFUNID, pu_EXNID]
            )
        end

    val newTyBindInfo : T.tyBindInfo P.pu =
        let
          fun toInt (T.TYCON arg) = 0
            | toInt (T.TYFUN arg) = 1
            | toInt (T.TYSPEC arg) = 2
            | toInt (T.TYOPAQUE arg) = 3
          fun pu_TYCON pu = 
            P.con1 
            T.TYCON 
            (fn T.TYCON arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non TYCON to pu_TYCON (types/main/TypesPickler.sml)"
            ) 
            dataTyInfo
          fun pu_TYFUN pu = 
            P.con1 
            T.TYFUN 
            (fn T.TYFUN arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non TYFUN to pu_TYFUN (types/main/TypesPickler.sml)"
             ) 
            tyFun
          fun pu_TYSPEC pu =
              P.con1
                  T.TYSPEC
                  (fn T.TYSPEC arg => arg
                    | _ => 
                      raise 
                       Control.Bug 
                       "non TYSPEC to pu_TYSPEC (types/main/TypesPickler.sml)"
                   )
                  tyCon
          fun pu_TYOPAQUE pu =
              P.con1
                  T.TYOPAQUE
                  (fn T.TYOPAQUE arg => arg
                    | _ => 
                      raise 
                        Control.Bug 
                        "non TYSPEC to pu_TYSPEC (types/main/TypesPickler.sml)"
                   )
                  (P.conv
                       (fn (spec, impl) => {spec = spec, impl = impl},
                        fn {spec, impl} => (spec, impl))
                       (P.tuple2(tyCon, tyBindInfo)))
        in
            P.data (toInt, [pu_TYCON, pu_TYFUN, pu_TYSPEC, pu_TYOPAQUE])
        end
  in
  val _ = P.updateNullPu recordKindFunctions newRecKind
  val _ = P.updateNullPu tvStateFunctions newTvState
  val _ = P.updateNullPu tyFunctions newTy
  val _ = P.updateNullPu idStateFunctions newIdState
  val _ = P.updateNullPu tyBindInfoFunctions newTyBindInfo
  end

  (********************)

(*
  local
    val strPathInfo =
        {
          id = ID.generate (),
          name = "foo",
          strpath = Path.NilPath,
          env = (SEnv.empty, SEnv.empty, SEnv.empty)
        }
  in
  val (strBindInfoFunctions, strBindInfo) =
      P.makeNullPu (T.STRUCTURE strPathInfo)
  end

  val strBindInfoSEnv = EnvPickler.SEnv strBindInfo

  val tyConEnv_VarEnv_StrBindInfoSEnv =
      P.tuple3 (tyConEnv, varEnv, strBindInfoSEnv)
*)
  val tyConEnv_VarEnv =
      P.tuple2 (tyConEnv, varEnv)

  val name_env  =
      P.conv
          (
           fn (name, env) =>
               {name = name,  env = env},
            fn {name, env} => (name, env)
          )
          (P.tuple2(P.string, tyConEnv_VarEnv))

(*
  local
    val newStrBindInfo : T.strBindInfo P.pu =
        let
          fun toInt (T.STRUCTURE _) = 0
          fun pu_STRUCTURE pu =
              P.con1 T.STRUCTURE (fn T.STRUCTURE x => x) strPathInfo
        in
          P.data (toInt, [pu_STRUCTURE])
        end
  in
  val _ = P.updateNullPu strBindInfoFunctions newStrBindInfo
  end
*)

  (****************************************)

  val tyConIdSet = NamePickler.TyConIDSet
  val exnTagSet =  NamePickler.ExnTagIDSet

(*
  val strEnv = strBindInfoSEnv
*)

  val sigBindInfo =
      let
        fun toInt (T.SIGNATURE _) = 0
        fun pu_SIGNATURE pu =
            P.con1
              T.SIGNATURE
              (fn (T.SIGNATURE x) => x) (P.tuple2(tyConIdSet, name_env))
      in
        P.data (toInt, [pu_SIGNATURE])
      end

  val utvEnv = EnvPickler.SEnv tvStateRef

  val conInfo =
      P.conv
      (
        fn (funtyCon, tag, displayName, ty, tyCon) =>
           {
             funtyCon = funtyCon,
             tag = tag,
             displayName = displayName,
             ty = ty,
             tyCon = tyCon
           },
        fn {funtyCon, tag, displayName, ty, tyCon} =>
           (funtyCon, tag, displayName, ty, tyCon)
      )
      bool_int_string_ty_tyCon

  val Env = P.tuple2(tyConEnv, varEnv)

  val funBindInfo =
      let
        val functorSig =
            let
                val body = P.tuple2(tyConIdSet, Env)
            in
              P.conv
                  (
                   fn (generativeExnTagSet,
                       argTyConIdSet,
                       argSigEnv,
                       argStrPrefixedEnv,
                       body)
                      =>
                       {
                        generativeExnTagSet = generativeExnTagSet,
                        argTyConIdSet = argTyConIdSet,
                        argSigEnv = argSigEnv, 
                        argStrPrefixedEnv = argStrPrefixedEnv, 
                        body = body
                       },
                   fn {generativeExnTagSet,
                       argTyConIdSet,
                       argSigEnv,
                       argStrPrefixedEnv,
                       body}
                      =>
                      (generativeExnTagSet,
                       argTyConIdSet,
                       argSigEnv,
                       argStrPrefixedEnv,
                       body)
                  )
                  (P.tuple5(exnTagSet, tyConIdSet, Env, Env, body))
            end
      in
        P.conv
            (
              fn (funName, argName, functorSig) =>
                 {
                  funName = funName,
                  argName = argName,
                  functorSig = functorSig},
              fn {funName, argName, functorSig} => 
                 (funName, argName, functorSig)
            )
            (P.tuple3(P.string, P.string, functorSig))
      end

(*
  val strInfo =
      P.conv
          (
            fn ((id, name), env) => {id = id, name = name, env = env},
            fn {id, name, env} => ((id, name), env)
          )
          (P.tuple2(id_string, Env))
*)
  val funEnv = EnvPickler.SEnv funBindInfo
  val sigEnv = EnvPickler.SEnv sigBindInfo
  val btvEnv = btvKindIEnv

  val valId =
      let
        fun toInt (T.VALIDVAR _) = 0
          | toInt (T.VALIDWILD _) = 1
        fun pu_VALIDVAR pu =
            P.con1
                T.VALIDVAR
                (fn (T.VALIDVAR x) => x
                  | _ =>
                    raise
                      Control.Bug
                        "non VALIDVAR  to pu_VALIDVAR\
                        \ (types/main/TypesPickler.sml)"
                 )
                (P.conv
                     (
                       fn (ty,  namePath) => {ty = ty, namePath = namePath},
                       fn {ty,  namePath} => (ty, namePath)
                     )
                     (P.tuple2(ty, P.tuple2(P.string, path))))
        fun pu_VALIDWILD pu =
            P.con1
                T.VALIDWILD
                (fn (T.VALIDWILD x) => x
                  | _ =>
                    raise
                      Control.Bug
                        "non VALIDWILD to pu_VALIDWILD\
                        \ (types/main/TypesPickler.sml)"
                 )
                ty
      in
        P.data (toInt, [pu_VALIDVAR, pu_VALIDWILD])
      end

  val valIdent =
      let
        fun toInt (T.VALIDENT _) = 0
          | toInt (T.VALIDENTWILD _) = 1
        fun pu_VALIDENT pu =
            P.con1
                T.VALIDENT
                (fn (T.VALIDENT x) => x
                  | _ =>
                    raise
                      Control.Bug
                        "non VALIDENT to pu_VALIDENT\
                        \ (types/main/TypesPickler.sml)"
                 )
                (P.conv
                     (
                       fn (displayName, ty, varId) =>
                          {displayName = displayName, ty = ty, varId = varId},
                       fn {displayName, ty, varId} => (displayName, ty, varId)
                     )
                     string_ty_varId)
        fun pu_VALIDENTWILD pu =
            P.con1
                T.VALIDENTWILD
                (fn (T.VALIDENTWILD x) => x
                  | _ =>
                    raise
                      Control.Bug
                        "non VALIDENTWILD to pu_VALIDENTWILD\
                        \ (types/main/TypesPickler.sml)"
                 )
                ty
      in
        P.data (toInt, [pu_VALIDENT, pu_VALIDENTWILD])
      end

  val fixity =
      let
        fun toInt (Fixity.INFIX _) = 0
          | toInt (Fixity.INFIXR _) = 1
          | toInt Fixity.NONFIX = 2
        fun pu_INFIX pu =
          P.con1 
          Fixity.INFIX 
          (fn (Fixity.INFIX x) => x
            | _ => 
              raise 
                Control.Bug 
                "non INFIX to pu_INFIX (types/main/TypesPickler.sml)"
           ) 
          P.int
        fun pu_INFIXR pu =
          P.con1 
          Fixity.INFIXR 
          (fn (Fixity.INFIXR x) => x
            | _ => 
              raise 
                Control.Bug 
                "non INFIXR to pu_INFIXR (types/main/TypesPickler.sml)"
           ) 
          P.int
        fun pu_NONFIX pu = P.con0 Fixity.NONFIX pu
      in
        P.data (toInt, [pu_INFIX, pu_INFIXR, pu_NONFIX])
      end

  val topEnv = P.tuple2(topTyConEnv, topVarEnv)

  val interfaceEnv = P.tuple2(P.tuple2(topTyConEnv, topVarEnv), funEnv)

end
