(**
 * pickler for data types declared in types module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypesPickler.sml,v 1.22 2007/05/15 06:14:02 kiyoshiy Exp $
 *)
structure TypesPickler 
  : sig
      val eqKind : Types.eqKind Pickle.pu
      val path : Types.path Pickle.pu
      val id : Types.id Pickle.pu
      val tid : Types.tid Pickle.pu
      val recKind : Types.recKind Pickle.pu
      val tvState : Types.tvState Pickle.pu
      val ty : Types.ty Pickle.pu
      val idState : Types.idState Pickle.pu
      val tyBindInfo : Types.tyBindInfo Pickle.pu
      val tvKind : Types.tvKind Pickle.pu
      val varIdInfo : Types.varIdInfo Pickle.pu
      val btvKind : Types.btvKind Pickle.pu
      val varEnv : Types.varEnv Pickle.pu
      val tyConEnv : Types.tyConEnv Pickle.pu
      val tyFun : Types.tyFun Pickle.pu
      val tyCon : Types.tyCon Pickle.pu
      val tySpec : Types.tySpec Pickle.pu
      val conPathInfo : Types.conPathInfo Pickle.pu
      val conPathInfoNameType : Types.conPathInfoNameType Pickle.pu
      val varPathInfo : Types.varPathInfo Pickle.pu
      val primInfo : Types.primInfo Pickle.pu
      val oprimInfo : Types.oprimInfo Pickle.pu
(*
      val strBindInfo : Types.strBindInfo Pickle.pu               
*)
      val strPathInfo : Types.strPathInfo Pickle.pu               

      val tyConIdSet : Types.tyConIdSet Pickle.pu
      val exnTagSet : Types.exnTagSet Pickle.pu
      val strEnv : Types.strEnv Pickle.pu
      val sigBindInfo : Types.sigBindInfo Pickle.pu
      val utvEnv : Types.utvEnv Pickle.pu

      val conInfo : Types.conInfo Pickle.pu
      val subst : Types.subst Pickle.pu
      val Env : Types.Env Pickle.pu
      val funBindInfo : Types.funBindInfo Pickle.pu

      val strInfo : Types.strInfo Pickle.pu
      val funEnv : Types.funEnv Pickle.pu
      val sigEnv : Types.sigEnv Pickle.pu
      val btvEnv : Types.btvEnv Pickle.pu
      val tvarNameSet : Types.tvarNameSet Pickle.pu

      val valId : Types.valId Pickle.pu
      val valIdent : Types.valIdent Pickle.pu

      val fixity : Fixity.fixity Pickle.pu

      val moduleState : Types.moduleState Pickle.pu

    end =
struct

  (***************************************************************************)

  structure P = Pickle
  structure T = Types

  (***************************************************************************)

  val path = NamePickler.path

  val id = NamePickler.id

  val tid = P.conv (T.intToTid, T.tidToInt) P.int

  val eqKind = P.enum (fn T.EQ => 0 | T.NONEQ => 1, [T.EQ, T.NONEQ])

  val callingConvention = AbsynPickler.callingConvention

  (****************************************)

  val dummyTyCon =
      {
        name = "",
        strpath = Path.NilPath,
        tyvars = [],
        id = T.nextTyConId (),
        abstract = false,
        eqKind = ref T.EQ,
        boxedKind = ref T.ERRORty,
        datacon = ref SEnv.empty
      } : T.tyCon

  val (recKindFunctions, recKind) = P.makeNullPu T.UNIV
  val (tvStateFunctions, tvState) = P.makeNullPu (T.SUBSTITUTED T.ATOMty)
  val (tyFunctions, ty) = P.makeNullPu T.ATOMty
  val (idStateFunctions, idState) =
      P.makeNullPu (T.PRIM {name = "foo", ty = T.ATOMty})
  val (tyBindInfoFunctions, tyBindInfo) = P.makeNullPu (T.TYCON dummyTyCon)
  val (sizeTagExpFunctions, sizeTagExp) = P.makeNullPu (T.ST_CONST 0)

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
  val tyBindInfoSEnv = EnvPickler.SEnv tyBindInfo
  val boolSEnv = EnvPickler.SEnv P.bool

  val tyList = P.list ty

  val tyOption = P.option ty
  val tyBindInfoOption = P.option tyBindInfo
  val tvStateRef = P.refNonCycle tvState
  val boxedKindTyRef = P.refNonCycle ty
  val eqKindRef = P.refNonCycle eqKind

  (* picklers for tuple types.
   * Tuple elements are sorted in alphabetic order of their type names.
   * But some of them are not sorted...
   *)
  val id_string = P.tuple2 (id, P.string)
  val id_string_ty = P.tuple3(id, P.string, ty)
  val int_eqKind_recKind = P.tuple3(P.int, eqKind, recKind)
  val path_string_ty = P.tuple3(path, P.string, ty)
  val ty_ty = P.tuple2 (ty, ty)
  val ty_string = P.tuple2 (ty, P.string)
  val tyList_ty = P.tuple2 (tyList, ty)
  val tyList_int = P.tuple2 (tyList, P.int)

  (********************)

  val tvKind : T.tvKind P.pu =
      P.conv
          (
            fn (lambdaDepth, id, recKind, eqKind, tyvarName) =>
               {
                 lambdaDepth = lambdaDepth,
                 id = id,
                 recKind = recKind,
                 eqKind = eqKind,
                 tyvarName = tyvarName
               },
            fn {lambdaDepth, id, recKind, eqKind, tyvarName} =>
               (lambdaDepth, id, recKind, eqKind, tyvarName)
          )
          (P.tuple5(P.int, tid, recKind, eqKind, stringOption))

  val varIdInfo : T.varIdInfo P.pu =
      P.conv
          (
            fn (id, displayName, ty) =>
               {id = id, displayName = displayName, ty = ty},
            fn {id, displayName, ty} => (id, displayName, ty)
          )
          id_string_ty

  val btvKind : T.btvKind P.pu =
      P.conv
          (
            fn (index, eqKind, recKind) =>
               {index = index, eqKind = eqKind, recKind = recKind},
            fn {index, eqKind, recKind} =>
               (index, eqKind, recKind)
          )
          int_eqKind_recKind
  val btvKindIEnv = EnvPickler.IEnv btvKind
  val btvKindIEnv_ty = P.tuple2(btvKindIEnv, ty)
  val btvKindIEnv_string_ty = P.tuple3(btvKindIEnv, P.string, ty)

  val varEnv : T.varEnv P.pu = idStateSEnv
  val varEnvRef = P.refCycle SEnv.empty varEnv

  val tyConEnv : T.tyConEnv P.pu = tyBindInfoSEnv
  val tyFun : T.tyFun P.pu =
      P.conv
          (
            fn (tyargs, name, body) =>
               {tyargs = tyargs, name = name, body = body},
            fn {tyargs, name, body} => (tyargs, name, body)
          )
          btvKindIEnv_string_ty

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
                 boxedKind,
                 datacon
               ) =>
               {
                 name = name,
                 strpath = strpath,
                 tyvars = tyvars,
                 id = id,
                 abstract = abstract,
                 eqKind = eqKind,
                 boxedKind = boxedKind,
                 datacon = datacon
               },
            fn {
                 name,
                 strpath,
                 tyvars,
                 id,
                 abstract,
                 eqKind,
                 boxedKind,
                 datacon
               } =>
               (
                 name,
                 strpath,
                 tyvars,
                 id,
                 abstract,
                 eqKind,
                 boxedKind,
                 datacon
               )
          )
          (P.tuple8
               (
                 P.string,
                 path,
                 boolList,
                 id,
                 P.bool,
                 eqKindRef,
                 boxedKindTyRef,
                 varEnvRef
               ))
  val tyCon_tyList = P.tuple2(tyCon, tyList)
  val bool_int_string_ty_tyCon = P.tuple5(P.bool, P.int, P.string, ty, tyCon)

  val tySpec : T.tySpec P.pu =
      P.conv
          (
            fn (name, id, strpath, eqKind, tyvars, boxedKind) =>
               {
                 name = name,
                 id = id,
                 strpath = strpath,
                 eqKind = eqKind,
                 tyvars = tyvars,
                 boxedKind = boxedKind
               },
            fn {name, id, strpath, eqKind, tyvars, boxedKind} =>
               (name, id, strpath, eqKind, tyvars, boxedKind)
          )
          (P.tuple6 (P.string, id, path, eqKind, boolList, ty))

  val conPathInfo : T.conPathInfo P.pu =
      P.conv
          (
            fn ((funtyCon, tag, name, ty, tyCon), strpath) =>
               {
                 funtyCon = funtyCon,
                 name = name,
                 tag = tag,
                 ty = ty,
                 tyCon = tyCon,
                 strpath = strpath
               },
            fn {funtyCon, tag, name, ty, tyCon, strpath} =>
               ((funtyCon, tag, name, ty, tyCon), strpath)
          )
          (P.tuple2(bool_int_string_ty_tyCon, path))

  val conPathInfoNameType : T.conPathInfoNameType P.pu = conPathInfo

  val varPathInfo : T.varPathInfo P.pu =
      P.conv
          (
            fn (strpath, name, ty) =>
               {strpath = strpath, name = name, ty = ty},
            fn {strpath, name, ty} => (strpath, name, ty)
          )
          path_string_ty

  val primInfo : T.primInfo P.pu =
      P.conv
          (
            fn (ty, name) => {ty = ty, name = name},
            fn {ty, name} => (ty, name)
          )
          ty_string
  val primInfoSEnv = EnvPickler.SEnv primInfo

  val oprimInfo : T.oprimInfo P.pu =
      P.conv
          (
            fn ((ty, name), instances) =>
               {ty = ty, name = name, instances = instances},
            fn {ty, name, instances} => ((ty, name), instances)
          )
          (P.tuple2(ty_string, primInfoSEnv)) (* use ty_string for share *)


  (********************)

  local
    val newRecKind : T.recKind P.pu =
        let
          fun toInt (T.OVERLOADED _) = 0
            | toInt (T.REC _) = 1
            | toInt T.UNIV = 2
          fun pu_OVERLOADED pu =
              P.con1 T.OVERLOADED (fn T.OVERLOADED x => x) tyList
          fun pu_REC pu = P.con1 T.REC (fn T.REC x => x) tySEnv
          fun pu_UNIV pu = P.con0 T.UNIV pu
        in
          P.data (toInt, [pu_OVERLOADED, pu_REC, pu_UNIV])
        end
    val newTvState : T.tvState P.pu =
        let
          fun toInt (T.SUBSTITUTED _) = 0
            | toInt (T.TVAR _) = 1
          fun pu_SUBSTITUTED pu =
              P.con1 T.SUBSTITUTED (fn T.SUBSTITUTED x => x) ty
          fun pu_TVAR pu = P.con1 T.TVAR (fn T.TVAR arg => arg) tvKind
        in
          P.data (toInt, [pu_SUBSTITUTED, pu_TVAR])
        end
    val newTy : T.ty P.pu =
        let
          fun toInt (T.ABSSPECty _) = 0
            | toInt (T.ABSTRACTty) = 1
            | toInt (T.ALIASty _) = 2
            | toInt (T.ATOMty) = 3
            | toInt (T.BITMAPty _) = 4
            | toInt (T.FRAMEBITMAPty _) = 5
            | toInt (T.BITty int) = 6
            | toInt (T.BMABSty _) = 7
            | toInt (T.BOUNDVARty _) = 8
            | toInt (T.BOXEDty) = 9
            | toInt (T.CONty _) = 10
            | toInt (T.DBLUNBOXEDty) = 11
            | toInt (T.DOUBLEty) = 12
            | toInt (T.DUMMYty _) = 13
            | toInt (T.ERRORty) = 14
            | toInt (T.FUNMty _) = 15
            | toInt (T.GENERICty ) = 16
            | toInt (T.INDEXty _) = 17
            | toInt (T.OFFSETty _) = 18
            | toInt (T.PADCONDty _) = 19
            | toInt (T.PADty _) = 20
            | toInt (T.POLYty _) = 21
            | toInt (T.RECORDty _) = 22
            | toInt (T.SIZEty _) = 23
            | toInt (T.SPECty _) = 24
            | toInt (T.TAGty _) = 25
            | toInt (T.TYVARty _) = 26
            | toInt (T.UNBOXEDty) = 27

(*
            | toInt ty =
              raise
                Control.Bug
                    ("TypesPicker.toInt found unknown ty: "
                     ^ TypeFormatter.tyToString ty)
*)

          fun pu_ABSTRACTty pu = P.con0 T.ABSTRACTty pu
          fun pu_ABSSPECty pu =
              P.con1 T.ABSSPECty (fn T.ABSSPECty arg => arg) ty_ty
          fun pu_ALIASty pu = P.con1 T.ALIASty (fn T.ALIASty arg => arg) ty_ty
          fun pu_ATOMty pu = P.con0 T.ATOMty pu 
          fun pu_BITMAPty pu =
              P.con1 T.BITMAPty (fn T.BITMAPty arg => arg) tyList
          fun pu_FRAMEBITMAPty pu =
              P.con1 T.FRAMEBITMAPty (fn T.FRAMEBITMAPty arg => arg) intList
          fun pu_BITty pu = P.con1 T.BITty (fn T.BITty arg => arg) P.int
          fun pu_BMABSty pu =
              P.con1 T.BMABSty (fn T.BMABSty arg => arg) tyList_ty
          fun pu_BOUNDVARty pu =
              P.con1 T.BOUNDVARty (fn T.BOUNDVARty arg => arg) P.int
          fun pu_BOXEDty pu = P.con0 T.BOXEDty pu 
          fun pu_CONty pu =
              P.con1
                  T.CONty
                  (fn T.CONty arg => arg)
                  (P.conv
                       (
                         fn (tyCon, args) => {tyCon = tyCon, args = args},
                         fn {tyCon, args} => (tyCon, args)
                       )
                       tyCon_tyList)
          fun pu_DBLUNBOXEDty pu = P.con0 T.DBLUNBOXEDty pu
          fun pu_DOUBLEty pu = P.con0 T.DOUBLEty pu
          fun pu_DUMMYty pu = P.con1 T.DUMMYty (fn T.DUMMYty arg => arg) P.int
          fun pu_ERRORty pu = P.con0 T.ERRORty pu
          fun pu_FUNMty pu = P.con1 T.FUNMty (fn T.FUNMty arg => arg) tyList_ty
          fun pu_GENERICty pu = P.con0 T.GENERICty pu 
          fun pu_INDEXty pu =
              P.con1 T.INDEXty (fn T.INDEXty arg => arg) ty_string
          fun pu_OFFSETty pu =
              P.con1 T.OFFSETty (fn T.OFFSETty arg => arg) tyList
          fun pu_PADCONDty pu =
              P.con1 T.PADCONDty (fn T.PADCONDty arg => arg) tyList_int
          fun pu_PADty pu = P.con1 T.PADty (fn T.PADty arg => arg) tyList
          fun pu_POLYty pu =
              P.con1
                  T.POLYty
                  (fn T.POLYty arg => arg)
                  (P.conv
                       (
                         fn (boundtvars, body) =>
                            {boundtvars = boundtvars, body = body},
                         fn {boundtvars, body} => (boundtvars, body)
                       )
                       btvKindIEnv_ty)
          fun pu_RECORDty pu =
              P.con1 T.RECORDty (fn T.RECORDty arg => arg) tySEnv
          fun pu_SIZEty pu = P.con1 T.SIZEty (fn T.SIZEty arg => arg) P.int
          fun pu_SPECty pu = 
              P.con1 T.SPECty (fn T.SPECty arg => arg) ty
          fun pu_TAGty pu = P.con1 T.TAGty (fn T.TAGty arg => arg) P.int
          fun pu_TYVARty pu =
              P.con1 T.TYVARty (fn T.TYVARty arg => arg) tvStateRef
          fun pu_UNBOXEDty pu = P.con0 T.UNBOXEDty pu
        in
          P.data
              (
                toInt,
                [ (* CAUTION: if 'pu_XXXty' is the n-th element of this list,
                   * 'toInt XXXty' must return n. *)
                  pu_ABSSPECty, (* 0 *)
                  pu_ABSTRACTty, (* 1 *)
                  pu_ALIASty, (* 2 *)
                  pu_ATOMty, (* 3 *)
                  pu_BITMAPty, (* 4 *)
                  pu_FRAMEBITMAPty, (* 5 *)
                  pu_BITty, (* 6 *)
                  pu_BMABSty, (* 7 *)
                  pu_BOUNDVARty, (* 8 *)
                  pu_BOXEDty, (* 9 *)
                  pu_CONty, (* 10 *)
                  pu_DBLUNBOXEDty, (* 11 *)
                  pu_DOUBLEty, (* 12 *)
                  pu_DUMMYty, (* 13 *)
                  pu_ERRORty, (* 14 *)
                  pu_FUNMty, (* 15 *)
                  pu_GENERICty, (* 16 *)
                  pu_INDEXty,  (* 17 *)
                  pu_OFFSETty,(* 18 *)
                  pu_PADCONDty, (* 19 *)
                  pu_PADty, (* 20 *)
                  pu_POLYty, (* 21 *)
                  pu_RECORDty, (* 22 *)
                  pu_SIZEty, (* 23 *)
                  pu_SPECty, (* 24 *)
                  pu_TAGty, (* 25 *)
                  pu_TYVARty, (* 26 *)
                  pu_UNBOXEDty (* 27 *)
                ]
              )
        end

    val newIdState : T.idState P.pu =
        let
          fun toInt (T.CONID _) = 0
            | toInt (T.OPRIM _) = 1
            | toInt (T.PRIM _) = 2
            | toInt (T.VARID _) = 3
          fun pu_CONID pu = P.con1 T.CONID (fn T.CONID arg => arg) conPathInfo
          fun pu_OPRIM pu = P.con1 T.OPRIM (fn T.OPRIM arg => arg) oprimInfo
          fun pu_PRIM pu = P.con1 T.PRIM (fn T.PRIM arg => arg) primInfo
          fun pu_VARID pu = P.con1 T.VARID (fn T.VARID arg => arg) varPathInfo
        in
          P.data (toInt, [pu_CONID, pu_OPRIM, pu_PRIM, pu_VARID])
        end

    val newTyBindInfo : T.tyBindInfo P.pu =
        let
          fun toInt (T.TYCON arg) = 0
            | toInt (T.TYFUN arg) = 1
            | toInt (T.TYSPEC arg) = 2
          fun pu_TYCON pu = P.con1 T.TYCON (fn T.TYCON arg => arg) tyCon
          fun pu_TYFUN pu = P.con1 T.TYFUN (fn T.TYFUN arg => arg) tyFun
          fun pu_TYSPEC pu =
              P.con1
                  T.TYSPEC
                  (fn T.TYSPEC arg => arg)
                  (P.conv
                       (
                         fn (impl, spec) => {impl = impl, spec = spec},
                         fn {impl, spec} => (impl, spec)
                       )
                       (P.tuple2(tyBindInfoOption, tySpec)))
        in
          P.data (toInt, [pu_TYCON, pu_TYFUN, pu_TYSPEC])
        end
    val newSizeTagExp : T.sizeTagExp P.pu = 
        let
          fun toInt (T.ST_CONST arg) = 0
            | toInt (T.ST_VAR arg) = 1
            | toInt (T.ST_BDVAR arg) = 2
            | toInt (T.ST_APP arg) = 3
            | toInt (T.ST_FUN arg) = 4
          fun pu_ST_CONST pu = 
              P.con1 
                T.ST_CONST 
                (fn T.ST_CONST arg => arg) 
                P.int
          fun pu_ST_VAR pu = P.con1 T.ST_VAR (fn T.ST_VAR arg => arg) id
          fun pu_ST_BDVAR pu = 
              P.con1 T.ST_BDVAR
                     (fn T.ST_BDVAR arg => arg) P.int
          fun pu_ST_APP pu = 
              P.con1 T.ST_APP (fn T.ST_APP arg => arg) 
                     (P.conv
                        (fn (stfun, args) => {stfun = stfun, args = args},
                         fn {stfun, args} => (stfun, args))
                        (P.tuple2(sizeTagExp, P.list sizeTagExp)))
          fun pu_ST_FUN pu =
              P.con1 T.ST_FUN
                     (fn T.ST_FUN arg => arg)
                     (P.conv
                        (fn (args, body) => {args = args, body = body},
                         fn {args, body} => (args, body))
                        (P.tuple2(P.list P.int, sizeTagExp)))
        in
          P.data (toInt, [pu_ST_CONST, pu_ST_VAR, pu_ST_BDVAR, pu_ST_APP, pu_ST_FUN])
        end
  in
  val _ = P.updateNullPu recKindFunctions newRecKind
  val _ = P.updateNullPu tvStateFunctions newTvState
  val _ = P.updateNullPu tyFunctions newTy
  val _ = P.updateNullPu idStateFunctions newIdState
  val _ = P.updateNullPu tyBindInfoFunctions newTyBindInfo
  val _ = P.updateNullPu sizeTagExpFunctions newSizeTagExp
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
  val (strEnvFunctions, strEnv) = P.makeNullPu (T.STRUCTURE SEnv.empty)
  val tyConEnv_VarEnv_StrEnv =
      P.tuple3 (tyConEnv, varEnv, strEnv)

  val strPathInfo : T.strPathInfo P.pu =
      P.conv
          (
            fn (id, name, strpath, env) =>
               {id = id, name = name, strpath = strpath, env = env},
            fn {id, name, strpath, env} => (id, name, strpath, env)
          )
          (P.tuple4(id, P.string, path, tyConEnv_VarEnv_StrEnv))

  val strPathInfoSEnv = EnvPickler.SEnv strPathInfo

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

  local
    val newStrEnv : T.strEnv P.pu =
        let
          fun toInt (T.STRUCTURE _) = 0
          fun pu_STRUCTURE pu =
              P.con1 T.STRUCTURE (fn T.STRUCTURE x => x) strPathInfoSEnv
        in
          P.data (toInt, [pu_STRUCTURE])
        end
  in
  val _ = P.updateNullPu strEnvFunctions newStrEnv
  end

  (****************************************)

  val tyConIdSet = NamePickler.IDSet
  val exnTagSet = EnvPickler.ISet

(*
  val strEnv = strBindInfoSEnv
*)
  val tyConIdSet_strPathInfo = P.tuple2(tyConIdSet, strPathInfo)

  val sigBindInfo =
      let
        fun toInt (T.SIGNATURE _) = 0
        fun pu_SIGNATURE pu =
            P.con1 T.SIGNATURE (fn (T.SIGNATURE x) => x) tyConIdSet_strPathInfo
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

  val subst = EnvPickler.IEnv ty

  val Env = P.tuple3(tyConEnv, varEnv, strEnv)

  val funBindInfo =
      let
        val name_id =
            P.conv
                (
                  fn (id, name) => {id = id, name = name},
                  fn {id, name} => (id, name)
                )
                id_string
        val func = name_id
        val argument = name_id
        val functorSig =
            let
              val body =
                  P.conv
                      (
                        fn (constrained, unConstrained) =>
                           {constrained = constrained,
                            unConstrained = unConstrained},
                        fn {constrained, unConstrained} =>
                           (constrained, unConstrained)
                      )
                      (P.tuple2(P.tuple2(tyConIdSet, Env), Env))
              val func =
                  P.conv
                      (
                        fn (arg, body) => {arg = arg, body = body},
                        fn {arg, body} => (arg, body)
                      )
                      (P.tuple2(Env, body))
            in
              P.conv
                  (
                    fn (exnTagSet, tyConIdSet, func) =>
                       {
                         exnTagSet = exnTagSet,
                         tyConIdSet = tyConIdSet,
                         func = func
                       },
                   fn {exnTagSet, tyConIdSet, func} =>
                      (exnTagSet, tyConIdSet, func))
                  (P.tuple3(exnTagSet, tyConIdSet, func))
            end
      in
        P.conv
            (
              fn (func, argument, functorSig) =>
                 {func = func, argument = argument, functorSig = functorSig},
              fn {func, argument, functorSig} => (func, argument, functorSig)
            )
            (P.tuple3(func, argument, functorSig))
      end

  val strInfo =
      P.conv
          (
            fn ((id, name), env) => {id = id, name = name, env = env},
            fn {id, name, env} => ((id, name), env)
          )
          (P.tuple2(id_string, Env))
  val funEnv = EnvPickler.SEnv funBindInfo
  val sigEnv = EnvPickler.SEnv sigBindInfo
  val btvEnv = btvKindIEnv
  val tvarNameSet = boolSEnv

  val valId =
      let
        fun toInt (T.VALIDVAR _) = 0
          | toInt (T.VALIDWILD _) = 1
        fun pu_VALIDVAR pu =
            P.con1
                T.VALIDVAR
                (fn (T.VALIDVAR x) => x)
                (P.conv
                     (
                       fn (ty, name) => {ty = ty, name = name},
                       fn {ty, name} => (ty, name)
                     )
                     ty_string)
        fun pu_VALIDWILD pu =
            P.con1
                T.VALIDWILD
                (fn (T.VALIDWILD x) => x)
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
                (fn (T.VALIDENT x) => x)
                (P.conv
                     (
                       fn (id, displayName, ty) =>
                          {id = id, displayName = displayName, ty = ty},
                       fn {id, displayName, ty} => (id, displayName, ty)
                     )
                     id_string_ty)
        fun pu_VALIDENTWILD pu =
            P.con1
                T.VALIDENTWILD
                (fn (T.VALIDENTWILD x) => x)
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
            P.con1 Fixity.INFIX (fn (Fixity.INFIX x) => x) P.int
        fun pu_INFIXR pu =
            P.con1 Fixity.INFIXR (fn (Fixity.INFIXR x) => x) P.int
        fun pu_NONFIX pu = P.con0 Fixity.NONFIX pu
      in
        P.data (toInt, [pu_INFIX, pu_INFIXR, pu_NONFIX])
      end

  val moduleState =
      P.tuple3
          (
            NamePickler.sequence,
            NamePickler.sequence,
            NamePickler.sequence
          )

  (***************************************************************************)

end
