(**
 * Elaborated interface
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *
 * 2012-10-13 ohori:
 * Changed string id and longids to symbols and long symbols
 *)
structure PatternCalcInterface =
struct
  type loc = PatternCalc.loc

  type vid = PatternCalc.vid
  type longvid = PatternCalc.longvid
  type tycon = PatternCalc.tycon
  type longtycon = PatternCalc.longtycon
  type strid = PatternCalc.strid
  type longstrid = PatternCalc.longstrid
  type funid = PatternCalc.funid
  type tyvar = PatternCalc.tyvar
  type kinded_tyvarseq = PatternCalc.kinded_tyvarseq
  datatype ty = datatype PatternCalc.ty
  datatype mono = datatype PatternCalc.mono
  datatype poly = datatype PatternCalc.poly
  datatype sigexp = datatype PatternCalc.sigexp

  datatype opaque_impl = datatype AbsynInterface.opaque_impl

  datatype overload_instance =
      INST_OVERLOAD of overload_case
    | INST_LONGVID of longvid

  withtype overload_case =
      tyvar * mono ty * (mono ty * overload_instance * loc) list * loc

  type overload_mrule = mono ty * overload_instance * loc

  datatype valbind =
      VAL_EXTERN of vid * poly ty * loc
    | VAL_ALIAS of vid * longvid * loc
    | VAL_BUILTIN of vid * vid * poly ty * loc
    | VAL_OVERLOAD of vid * overload_case * loc

  type datbind = PatternCalc.datbind
  type typbind = PatternCalc.typbind
  type typdesc = tyvar list * tycon * opaque_impl * loc
  datatype exbind = datatype PatternCalc.exbind

  datatype dec =
      DECVAL of kinded_tyvarseq * valbind
    | DECTYPBIND of typbind
    | DECTYPDESC of bool * typdesc
    | DECDATATYPE of datbind list * PatternCalc.typbind list * loc
    | DECDATATYPEREP of tycon * longtycon * loc
    | DECTYPEBUILTIN of tycon * tycon * loc
    | DECEXCEPTION of exbind
    | DECSTRUCTURE of strbind

  and strexp =
      STRBASIC of dec list * loc
    | STRID of longstrid
    | STRAPP of funid * longstrid * loc

  withtype strbind = strid * strexp * loc

  type funbind = funid * strid * sigexp * strexp * loc

  datatype topdec =
      TOPDEC of dec
    | TOPFUNCTOR of funbind

  type interface_id = InterfaceID.id

  type interface_dec =
      {interfaceId: interface_id,
       interfaceName: InterfaceName.interface_name,
       requiredIds: {id: interface_id, loc: Loc.pos * Loc.pos} list,
       provideTopdecs: topdec list}

  type 'loc interface =
      {interfaceDecs : interface_dec list,
       requiredIds : {id: interface_id, loc: 'loc} list,
       locallyRequiredIds: {id: interface_id, loc: 'loc} list,
       provideTopdecs : topdec list,
       topdecsInclude : PatternCalc.sigdec list}

  type compile_unit =
      {interface : (Loc.pos * Loc.pos) interface,
       topdecsSource : PatternCalc.topdec list}

  type interface_unit =
      {interfaceDecs : interface_dec list,
       requiredIds : {id : interface_id, loc : unit} list,
       topdecsInclude : PatternCalc.sigdec list}

  fun valbindLoc valbind =
      case valbind of
        VAL_EXTERN (_, _, loc) => loc
      | VAL_ALIAS (_, _, loc) => loc
      | VAL_BUILTIN (_, _, _, loc) => loc
      | VAL_OVERLOAD (_, _, loc) => loc

  fun decLoc dec =
      case dec of
        DECVAL (_, valbind) => valbindLoc valbind
      | DECTYPBIND (_, _, _, loc) => loc
      | DECTYPDESC (_, (_, _, _, loc)) => loc
      | DECDATATYPE (_, _, loc) => loc
      | DECDATATYPEREP (_, _, loc) => loc
      | DECTYPEBUILTIN (_, _, loc) => loc
      | DECEXCEPTION (PatternCalc.EXBIND (_, _, loc)) => loc
      | DECEXCEPTION (PatternCalc.EXBINDREP (_, _, loc)) => loc
      | DECSTRUCTURE (_, _, loc) => loc

  fun topdecLoc topdec =
      case topdec of
        TOPDEC dec => decLoc dec
      | TOPFUNCTOR (_, _, _, _, loc) => loc

  (* revert to absyn for printing *)

  structure A = AbsynInterface

  val dummyPos = {source = Loc.INTERACTIVE, pos = Loc.EOF}
  val loc = (dummyPos, dummyPos)

  fun absynOverloadInst inst =
      case inst of
        INST_OVERLOAD ovcase =>
        A.INST_OVERLOAD (absynOverloadCase ovcase)
      | INST_LONGVID vid =>
        A.INST_LONGVID vid

  and absynOverloadCase (tyvar, ty, mrules, _) =
      ((false, tyvar),
       PatternCalc.absynMonoTy ty,
       map absynOverloadMrule mrules,
       loc)

  and absynOverloadMrule (ty, inst, _) =
      (PatternCalc.absynMonoTy ty, absynOverloadInst inst, loc)

  fun absynValbind valbind =
      case valbind of
        VAL_EXTERN (vid, ty, _) =>
        A.VAL_EXTERN (vid, PatternCalc.absynPolyTy ty, loc)
      | VAL_ALIAS (vid, longvid, _) =>
        A.VAL_ALIAS (vid, longvid, loc)
      | VAL_BUILTIN (vid1, vid2, ty, _) =>
        A.VAL_BUILTIN (vid1, vid2, PatternCalc.absynPolyTy ty, loc)
      | VAL_OVERLOAD (vid, ovcase, _) =>
        A.VAL_OVERLOAD (vid, absynOverloadCase ovcase, loc)

  fun absynTypdesc (tyvars, tycon, impl, _) =
      (PatternCalc.absynTyvarseq tyvars, tycon, impl, loc)

  fun absynDec dec =
      case dec of
        DECVAL (tyvarseq, valbind) =>
        A.DECVAL (PatternCalc.absynKindedTyvarseq tyvarseq,
                  absynValbind valbind,
                  loc)
      | DECTYPBIND typbind =>
        A.DECTYPE ([A.TYPBIND (PatternCalc.absynTypbind typbind)], loc)
      | DECTYPDESC (false, typdesc) =>
        A.DECTYPE ([A.TYPDESC (absynTypdesc typdesc)], loc)
      | DECTYPDESC (true, typdesc) =>
        A.DECEQTYPE ([absynTypdesc typdesc], loc)
      | DECDATATYPE (datbinds, typbinds, _) =>
        A.DECDATATYPE (map PatternCalc.absynDatbind datbinds,
                       PatternCalc.absynWithty typbinds,
                       loc)
      | DECDATATYPEREP (tycon, longtycon, _) =>
        A.DECDATATYPEREP (tycon, longtycon, loc)
      | DECTYPEBUILTIN (tycon1, tycon2, _) =>
        A.DECTYPEBUILTIN (tycon1, tycon2, loc)
      | DECEXCEPTION exbind =>
        A.DECEXCEPTION ([PatternCalc.absynExbind exbind], loc)
      | DECSTRUCTURE strbind =>
        A.DECSTRUCTURE (absynStrbind strbind, loc)

  and absynStrexp strexp =
      case strexp of
        STRBASIC (decs, _) =>
        A.STRBASIC (map absynDec decs, loc)
      | STRID strid =>
        A.STRID strid
      | STRAPP (funid, strid, _) =>
        A.STRAPP (funid, strid, loc)

  and absynStrbind (strid, strexp, _) =
      (strid, absynStrexp strexp, loc)

  fun absynFunbind (funid, strid, sigexp, strexp, _) =
      (funid,
       SOME (A.FUNPARAM (strid, PatternCalc.absynSigexp sigexp, loc)),
       absynStrexp strexp,
       loc)

  fun absynTopdec topdec =
      case topdec of
        TOPDEC dec =>
        A.TOPDEC (absynDec dec)
      | TOPFUNCTOR funbind =>
        A.TOPFUNCTOR (absynFunbind funbind, loc)

  fun absynInterfaceDec {interfaceId, interfaceName, requiredIds,
                         provideTopdecs} =
      {interfaceId = interfaceId,
       interfaceName = interfaceName,
       requiredIds = requiredIds,
       provideTopdecs = map absynTopdec provideTopdecs}

  fun absynInterface {interfaceDecs, requiredIds, locallyRequiredIds,
                      provideTopdecs, topdecsInclude} =
      {interfaceDecs = map absynInterfaceDec interfaceDecs,
       provide =
         {requiredIds = requiredIds,
          locallyRequiredIds = locallyRequiredIds,
          provideTopdecs = map absynTopdec provideTopdecs},
       topdecsInclude = map PatternCalc.absynSigdec topdecsInclude}

  fun absynCompileUnit {interface, topdecsSource} =
      {interface = SOME (absynInterface interface),
       topdecsSource = map PatternCalc.absynTopdec topdecsSource}

  fun absynInterfaceUnit {interfaceDecs, requiredIds, topdecsInclude} =
      {interfaceDecs = map absynInterfaceDec interfaceDecs,
       requiredIds = requiredIds,
       topdecsInclude = map PatternCalc.absynSigdec topdecsInclude}

  fun format_dec dec =
      AbsynInterface.format_dec (absynDec dec)
  fun format_strexp strexp =
      AbsynInterface.format_strexp (absynStrexp strexp)
  fun format_funbind head funbind =
      AbsynInterface.format_funbind head (absynFunbind funbind)
  fun format_topdec topdec =
      AbsynInterface.format_topdec (absynTopdec topdec)
  fun format_interface_dec dec =
      AbsynInterfaceLoaded.format_interface_dec (absynInterfaceDec dec)
  fun format_interface interface =
      AbsynInterfaceLoaded.format_interface {} (absynInterface interface)
  fun format_compile_unit unit =
      AbsynInterfaceLoaded.format_compile_unit (absynCompileUnit unit)
  fun format_interface_unit unit =
      AbsynInterfaceLoaded.format_interface_unit (absynInterfaceUnit unit)

end
