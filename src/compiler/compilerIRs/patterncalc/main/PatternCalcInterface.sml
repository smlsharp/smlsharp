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

  type interface_dec = topdec InterfaceLoaded.interface_dec
  type 'loc interface =
      (topdec, PatternCalc.sigdec, 'loc) InterfaceLoaded.interface
  type compile_unit =
      (topdec, PatternCalc.sigdec, PatternCalc.topdec)
        InterfaceLoaded.compile_unit
  type interface_unit =
      (topdec, PatternCalc.sigdec) InterfaceLoaded.interface_unit

  val emptyInterface : InterfaceLoaded.loc interface =
      {interfaceDecs = nil,
       provide = {requiredIds = nil,
                  locallyRequiredIds = nil,
                  provideTopdecs = nil},
       topdecsInclude = nil}

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

  structure P = PrintCalc
  structure A = AbsynFormatter

  fun printOverloadInstance inst =
      case inst of
        INST_OVERLOAD ovcase =>
        printOverloadCase ovcase
      | INST_LONGVID vid =>
        A.printLongvid vid

  and printOverloadMrule (ty, inst, _) =
      P.MRULE (PatternCalc.printMonoTy ty, printOverloadInstance inst)

  and printOverloadCase (tyvar, ty, mrules, _) =
      P.EXPCASE
        (P.OVERLOAD_IN (PatternCalc.printTyvar tyvar,
                        PatternCalc.printMonoTy ty),
         map printOverloadMrule mrules)

  fun printValbind valbind =
      case valbind of
        VAL_EXTERN (vid, ty, _) =>
        P.VALDESC (A.printVid vid, PatternCalc.printPolyTy ty)
      | VAL_ALIAS (vid, longvid, _) =>
        P.VALBIND (A.printVid vid, A.printLongvid longvid)
      | VAL_BUILTIN (vid1, vid2, ty, _) =>
        P.VALBIND (A.printVid vid1,
                   P.BUILTIN_VAL (A.printVid vid2, PatternCalc.printPolyTy ty))
      | VAL_OVERLOAD (vid, ovcase, _) =>
        P.VALBIND (A.printVid vid, printOverloadCase ovcase)

  fun printTypdesc (tyvars, tycon, impl, _) =
      P.ITYPDESC (map PatternCalc.printTyvar tyvars,
                  A.printTycon tycon,
                  A.printOpaqueImpl impl)

  fun printDec dec =
      case dec of
        DECVAL (tyvarseq, valbind) =>
        P.DECVAL (PatternCalc.printKindedTyvarseq tyvarseq,
                  [printValbind valbind])
      | DECTYPBIND typbind =>
        P.DECTYPE [PatternCalc.printTypbind typbind]
      | DECTYPDESC (false, typdesc) =>
        P.DECTYPE [printTypdesc typdesc]
      | DECTYPDESC (true, typdesc) =>
        P.SPECEQTYPE [printTypdesc typdesc]
      | DECDATATYPE (datbinds, typbinds, _) =>
        P.DECDATATYPE (map PatternCalc.printDatbind datbinds,
                       PatternCalc.printWithty typbinds)
      | DECDATATYPEREP (tycon, longtycon, _) =>
        P.DECDATATYPEREP (A.printTycon tycon, A.printLongtycon longtycon)
      | DECTYPEBUILTIN (tycon1, tycon2, _) =>
        P.DECDATATYPEREP (A.printTycon tycon1,
                          P.BUILTIN_DATATYPE (A.printTycon tycon2))
      | DECEXCEPTION exbind =>
        P.DECEXCEPTION [PatternCalc.printExbind exbind]
      | DECSTRUCTURE strbind =>
        P.STRUCTURE [printStrbind strbind]

  and printStrexp strexp =
      case strexp of
        STRBASIC (decs, _) =>
        P.STRBASIC (map printDec decs)
      | STRID strid =>
        A.printLongstrid strid
      | STRAPP (funid, strid, _) =>
        P.STRAPP (A.printFunid funid, [A.printLongstrid strid])

  and printStrbind (strid, strexp, _) =
      P.VALBIND (A.printStrid strid, printStrexp strexp)

  fun printFunbind (funid, strid, sigexp, strexp, _) =
      P.FUNBIND
        ((A.printFunid funid,
          [P.STRCONSTRAINT
             (A.printStrid strid,
              P.TRANSPARENT (PatternCalc.printSigexp sigexp))]),
         NONE,
         printStrexp strexp)

  fun printTopdec topdec =
      case topdec of
        TOPDEC dec =>
        printDec dec
      | TOPFUNCTOR funbind =>
        P.FUNCTOR [printFunbind funbind]

  val printers =
      {printItopdec = printTopdec,
       printSigdec = PatternCalc.printSigdec,
       printTopdec = PatternCalc.printTopdec}

  fun printInterfaceDec x = InterfaceLoaded.printInterfaceDec printers x
  fun printInterface x = InterfaceLoaded.printInterface printers x
  fun printCompileUnit x = InterfaceLoaded.printCompileUnit printers x
  fun printInterfaceUnit x = InterfaceLoaded.printInterfaceUnit printers x

  fun format_dec x = PrintCalc.format_exp (printDec x)
  fun format_funbind x y = PrintCalc.format_bind x (printFunbind y)
  fun format_topdec x = PrintCalc.format_exp (printTopdec x)
  fun format_interface_dec x = PrintCalc.format_exp (printInterfaceDec x)
  fun format_interface x = PrintCalc.format_exp (printInterface x)
  fun format_compile_unit x = PrintCalc.format_exp (printCompileUnit x)
  fun format_interface_unit x = PrintCalc.format_exp (printInterfaceUnit x)

end
