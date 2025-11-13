(*
 * Elaborator.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao

sig

  val elabSigExp : Absyn.sigexp -> PatternCalc.plsigexp
  val elabSpec : Absyn.spec -> PatternCalc.plspec
  val elabTopDecs : Fixity.fixity SEnv.map
                    -> Absyn.topdec list
                    -> PatternCalc.pltopdec list * Fixity.fixity SEnv.map

end
 *)
structure ElaborateModule =
struct
  structure EU = UserErrorUtils
  structure E = ElaborateError
  datatype loc = datatype Loc.loc

  val checkSymbolDuplication = EU.checkSymbolDuplication
  val checkSymbolDuplication' = EU.checkSymbolDuplication'

  structure A = Absyn
  structure PC = PatternCalc

  fun toSymbol ((sym, loc):A.vid) = {symbol = sym, loc = LOC loc}
  fun toLongsymbol ((ids,_):A.longvid) = map toSymbol ids
  fun seq (SOME (items, _)) = items | seq NONE = nil

  (**
   * name given to an anonymous parameter signature of a functor.
   * Example:
   *   functor F(type x) = struct datatype dt = D of x end
   * is elaborated to:
   *   functor F ('X : sig type x end) =
   *   let open 'X in struct datatype dt = D of x end end
   *)
  val NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER = "_X"

  val emptyTvars = (nil, Loc.NOLOC) : PC.scopedTvars

  datatype sigexpKind = Interface | OrdinarySig

  fun elabBinds elaborator elements =
      map (fn (label, element, loc) => (toSymbol label, elaborator element, LOC loc)) elements

  fun specListToSpecSeq specList =
      let
        fun makeSeqSpec [] = raise Bug.Bug "nilspec found in elaborate"
          | makeSeqSpec [spec] = spec
          | makeSeqSpec (spec :: specs) =
            PC.PLSPECSEQ(spec, makeSeqSpec specs)
      in makeSeqSpec specList
      end

    fun elabSpec spec =
        case spec of
          A.SPECVAL(valBinds, loc) =>
          let
            val _ = checkSymbolDuplication
                      (toSymbol o #1)
                      valBinds E.DuplicateValDesc
            val _ =
                app (fn (vid, ty, _) =>
                        ElaborateCore.checkReservedNameForValBind
                          (toSymbol vid))
                    valBinds
            val specs =
                map (fn (vid, ty, _) => PC.PLSPECVAL (emptyTvars, toSymbol vid, ty, LOC loc))
                    valBinds
          in
            specListToSpecSeq specs
          end
        | A.SPECTYPE(tydescs, loc) =>
          let
            val _ =
                UserErrorUtils.checkSymbolDuplication
                  (toSymbol o #2) tydescs E.DuplicateTypDesc
            val tydescs = map (fn (tvars, symbol, _) => (seq tvars, toSymbol symbol)) tydescs
          in
            PC.PLSPECTYPE {tydecls=tydescs, eq=false, loc=LOC loc}
          end
        (*
      | A.SPECTYPE(tydescs, loc) =>
          let
            val _ =
              checkNameDuplication
                  #2 tydescs loc E.DuplicateTypDesc
          in
            PC.PLSPECTYPE(tydescs, loc)
          end
*)
        | A.SPECTYPEINC(maniftypedescs, loc) =>
          let
            val _ =
                checkSymbolDuplication
                  (toSymbol o #2)
                  maniftypedescs E.DuplicateTypDesc
            fun elabTypeEquation (tvars, symbol, ty, _) =
                PC.PLSPECTYPEEQUATION ((seq tvars, toSymbol symbol, ty), LOC loc)
          in
            specListToSpecSeq (map elabTypeEquation maniftypedescs)
          end
        | A.SPECEQTYPE(tydescs, loc) =>
          let
            val _ =
                UserErrorUtils.checkSymbolDuplication
                  (toSymbol o #2)
                  tydescs E.DuplicateTypDesc
            val tydescs = map (fn (tvars, symbol, _) => (seq tvars, toSymbol symbol)) tydescs
          in
            PC.PLSPECTYPE{tydecls=tydescs, eq=true, loc=LOC loc}
          end
(*
      | A.SPECEQTYPE(tydescs, loc) =>
          let
            val _ =
              checkNameDuplication
                  #2 tydescs loc E.DuplicateTypDesc
          in
            PC.PLSPECEQTYPE(tydescs, loc)
          end
*)
        | A.SPECDATATYPE(dataDescs, loc) =>
          let
            val _ =
                checkSymbolDuplication
                  (toSymbol o #2)
                  dataDescs E.DuplicateTypDesc
            fun check (tvar, name, conDescs, loc) =
                (
                  UserErrorUtils.checkSymbolDuplication
                    (fn (con, ty, loc) => toSymbol con)
                    conDescs E.DuplicateConstructorNameInDatatype;
                  app (fn (con, ty, loc) =>
                          ElaborateCore.checkReservedNameForConstructorBind
                            (toSymbol con))
                      conDescs;
                  ()
                )
            val _ = map check dataDescs
          in
            PC.PLSPECDATATYPE
              (map (fn (tyvars, symbol, con, loc) =>
                       {tyvars = seq tyvars, loc = LOC loc, symbol = toSymbol symbol,
                        conbind = map (fn (id,ty, loc) => {symbol=toSymbol id, ty=ty, loc=LOC loc}) con})
                   dataDescs,
               LOC loc)
          end
        | A.SPECDATATYPEREP(tyCon, longTyCon, loc) =>
          PC.PLSPECREPLIC(toSymbol tyCon, toLongsymbol longTyCon, LOC loc)
        | A.SPECEXCEPTION(exnDescs, loc) =>
          let
            val _ =
                checkSymbolDuplication
                  (toSymbol o #1)
                  exnDescs E.DuplicateConstructorNameInException
            val _ =
                app (fn (con, ty, loc) =>
                        ElaborateCore.checkReservedNameForConstructorBind
                          (toSymbol con))
                    exnDescs;
            val exnDescs =
                map (fn (symbol, tyOpt, loc) => (toSymbol symbol, tyOpt, LOC loc)) exnDescs
          in
            PC.PLSPECEXCEPTION(exnDescs, LOC loc)
          end
        | A.SPECSTRUCTURE(strdescs, loc) =>
          let
            val _ = checkSymbolDuplication (toSymbol o #1) strdescs E.DuplicateStrDesc
          in
            PC.PLSPECSTRUCT (elabBinds elabSigExp strdescs,
                             LOC loc)
          end
        | A.SPECINCLUDE(sigexp, loc)=>
          PC.PLSPECINCLUDE(elabSigExp sigexp, LOC loc)
        | A.SPECINCLUDE_ID(sigids, loc) =>
          let
            fun elabSigID sigid =
                PC.PLSPECINCLUDE(PC.PLSIGID (toSymbol sigid), LOC loc)
          in
            specListToSpecSeq (map elabSigID sigids)
          end
        | A.SPECSHARINGTYPE(spec, longTyCons, loc) =>
          PC.PLSPECSHARE (elabSpecList spec, map toLongsymbol longTyCons, LOC loc)
        | A.SPECSHARING(spec, longstrids, loc) =>
          PC.PLSPECSHARESTR (elabSpecList spec, map toLongsymbol longstrids, LOC loc)
        | A.SPECSEMICOLON _ => PC.PLSPECEMPTY

    and elabSpecList specs =
        foldl
          (fn (spec, z) =>
              case (z, elabSpec spec) of
                (z, PC.PLSPECEMPTY) => z
              | (PC.PLSPECEMPTY, spec) => spec
              | (z, spec) => PC.PLSPECSEQ (z, spec))
          PC.PLSPECEMPTY
          specs

    and elabSigExp sigexp =
        case sigexp of
          A.SIGBASIC(spec, loc) =>
          PC.PLSIGEXPBASIC(elabSpecList spec, LOC loc)
        | A.SIGID sigid =>
          PC.PLSIGID (toSymbol sigid)
        | A.SIGWHERE (sigexp, whtypes, loc) =>
          foldl
            (fn ((NONE, longsymbol, ty, _), plsigexp) =>
                PC.PLSIGWHERE (plsigexp, (nil, toLongsymbol longsymbol, ty), LOC loc)
              | ((SOME (tvars, _), longsymbol, ty, _), plsigexp) =>
                PC.PLSIGWHERE (plsigexp, (tvars, toLongsymbol longsymbol, ty), LOC loc))
            (elabSigExp sigexp)
            whtypes

    and elabStrExp strexp =
        case strexp of
          A.STRBASIC(strdecs, loc) =>
          let
            val plstrdecs = elabStrDecs strdecs
          in
            PC.PLSTREXPBASIC(plstrdecs, LOC loc)
          end
        | A.STRID longid => PC.PLSTRID (toLongsymbol longid)
        | A.STRCONSTRAINT(strexp, A.TRANSPARENT, sigexp, loc) =>
          PC.PLSTRTRANCONSTRAINT
            (elabStrExp strexp, elabSigExp sigexp, LOC loc)
        | A.STRCONSTRAINT(strexp, A.OPAQUE, sigexp, loc) =>
          PC.PLSTROPAQCONSTRAINT
            (elabStrExp strexp, elabSigExp sigexp, LOC loc)
        | A.STRAPP(funid, A.FUNARG (A.STRID longid), loc) =>
          PC.PLFUNCTORAPP(toSymbol funid, toLongsymbol longid, LOC loc)
        | A.STRAPP(funid, A.FUNARG strexp, loc) =>
          let
            val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
            val newStrLong = SymbolWithLoc.mkLongsymbol [newStrid] (LOC loc)
            val newStrSymbol = SymbolWithLoc.mkSymbol newStrid (LOC loc)
            val plstrexp = elabStrExp strexp
            val plstrbody = PC.PLFUNCTORAPP(toSymbol funid, newStrLong, LOC loc)
            val plstrDecs =[PC.PLSTRUCTBIND([(newStrSymbol,plstrexp, LOC loc)],LOC loc)]
          in
            PC.PLSTRUCTLET(plstrDecs, plstrbody, LOC loc)
          end
        | A.STRAPP (funid, A.FUNARG_DEC strdecs, loc) =>
          elabStrExp (A.STRAPP (funid, A.FUNARG (A.STRBASIC (strdecs, loc)), loc))
(*
      | A.FUNCTORAPP(funid, strexp, loc) =>
          PC.PLFUNCTORAPP(funid, elabStrExp env strexp, loc)
*)
      | A.STRLET(strdecs, strexp, loc) =>
        let
          val plstrdecs = elabStrDecs strdecs
        in
          PC.PLSTRUCTLET(plstrdecs, elabStrExp strexp, LOC loc)
        end

    and elabStrBind strbind =
      case strbind of
        (strid, SOME (A.TRANSPARENT, sigexp, _), strexp, loc) =>
        (
          toSymbol strid,
          PC.PLSTRTRANCONSTRAINT
            (elabStrExp strexp, elabSigExp sigexp, LOC loc),
          LOC loc
        )
      | (strid, SOME (A.OPAQUE, sigexp, _), strexp, loc) =>
        (
          toSymbol strid,
          PC.PLSTROPAQCONSTRAINT
            (elabStrExp strexp, elabSigExp sigexp, LOC loc),
          LOC loc
        )
      | (strid, NONE, strexp, loc) =>
        (toSymbol strid, elabStrExp strexp, LOC loc)

    and elabStrDec strdec =
      case strdec of
        A.STRDEC dec =>
        let
          val pldecs = ElaborateCore.elabDec dec
        in
          map (fn pldec => PC.PLCOREDEC(pldec, LOC (AbsynUtils.decLoc dec)))
              pldecs
        end
      | A.STRUCTURE(strbinds,loc) =>
        [PC.PLSTRUCTBIND(map elabStrBind strbinds, LOC loc)]
      | A.STRLOCAL(strdecs1, strdecs2, loc) =>
        let
          val plstrdecs1 = elabStrDecs strdecs1
          val plstrdecs2 = elabStrDecs strdecs2
        in
          [PC.PLSTRUCTLOCAL(plstrdecs1, plstrdecs2, LOC loc)]
        end
      | A.STRSEMICOLON _ => nil

    and elabStrDecs strdecs =
        List.concat (map elabStrDec strdecs)

    and elabFunBind funbind  =
      case funbind of
        (* functor F(A:sig1) : sig2 = str  =>
                   functor F(A:sig1) = str : sig2 *)
        (funid, A.FUNPARAM (strid, argSigexp),
         SOME (A.TRANSPARENT, resSigexp, _),
         strexp, loc) =>
        let val newStrexp = A.STRCONSTRAINT(strexp, A.TRANSPARENT, resSigexp, loc)
        in
          elabFunBind
            (funid, A.FUNPARAM (strid, argSigexp), NONE, newStrexp, loc)
        end
          (* functor F(A:sig1) :> sig2 = str  =>
            functor F(A:sig1) = str :> sig2
           *)
      | (funid, A.FUNPARAM (strid, argSigexp),
         SOME (A.OPAQUE, resSigexp, _),
         strexp, loc) =>
        let val newStrexp = A.STRCONSTRAINT(strexp, A.OPAQUE, resSigexp, loc)
        in
          elabFunBind
            (funid, A.FUNPARAM (strid, argSigexp), NONE, newStrexp, loc)
        end
      (* functor F(spec) : sig = str  =>
         functor F('x:sig spec end) = let open 'X in str:sig end
       *)
      | (funid, A.FUNPARAM_SPEC spec,
         SOME (A.TRANSPARENT, resSigexp, _),
         strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRLET
                ([A.STRDEC(A.DECOPEN([([(Symbol.fromString newStrid, loc)], loc)], loc))],
                 A.STRCONSTRAINT(strexp,A.TRANSPARENT,resSigexp,loc),
                 loc)
          val argSigExp = A.SIGBASIC(spec, loc)
          val newFunBind =
              (funid, A.FUNPARAM ((Symbol.fromString newStrid, loc), argSigExp), NONE, newStrexp, loc)
        in
          elabFunBind newFunBind
        end
      (* functor F(spec) :> sig = str  =>
         functor F('x:sig spec end) = let open 'X in str:>sig end
       *)
      | (funid, A.FUNPARAM_SPEC spec,
         SOME (A.OPAQUE, resSigexp, _),
         strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRLET
                ([A.STRDEC(A.DECOPEN([([(Symbol.fromString newStrid, loc)], loc)], loc))],
                 A.STRCONSTRAINT(strexp,A.OPAQUE,resSigexp,loc),
                 loc)
          val argSigExp = A.SIGBASIC(spec, loc)
          val newFunBind =
              (funid, A.FUNPARAM ((Symbol.fromString newStrid, loc), argSigExp), NONE, newStrexp, loc)
        in
          elabFunBind newFunBind
        end
      (* functor F(spec) = str  =>
         functor F('x:sig spec end) = let open 'X in str end
       *)
      | (funid, A.FUNPARAM_SPEC spec, NONE, strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRLET
                ([A.STRDEC(A.DECOPEN([([(Symbol.fromString newStrid, loc)], loc)], loc))], strexp, loc)
          val newFunBind =
              (funid, A.FUNPARAM ((Symbol.fromString newStrid, loc), A.SIGBASIC(spec, loc)), NONE, newStrexp, loc)
        in
          elabFunBind newFunBind
        end
      (* functor F(A:sig) = str
       *)
      | (funid, A.FUNPARAM (strid, argSigexp), NONE, strexp, loc) =>
        let
          val newArgSigexp = elabSigExp argSigexp
          val newStrexp = elabStrExp strexp
        in
          {name = toSymbol funid,
           argStrName = toSymbol strid,
           argSig=newArgSigexp,
           body=newStrexp,
           loc = LOC loc}
        end

    and elabTopDec topdec =
      case topdec of
        A.TOPSTRDEC strdec =>
          let
            val plstrdecs = elabStrDec strdec
          in
            map
              (fn plstrdec =>
                  PC.PLTOPDECSTR(plstrdec, LOC (AbsynUtils.strdecLoc strdec)))
              plstrdecs
          end
      | A.TOPSIGNATURE(sigdecs, loc) =>
          let
            val plsigdecs = elabBinds elabSigExp sigdecs
          in
            [PC.PLTOPDECSIG(plsigdecs, LOC loc)]
          end
      | A.TOPFUNCTOR(funbinds, loc) =>
          let
            val plfunbinds = map elabFunBind funbinds
          in
            [PC.PLTOPDECFUN(plfunbinds, LOC loc)]
          end
(*
      | A.TOPDECFUN(funbinds, loc) =>
          let val plfunbinds = map (elabFunBind env) funbinds
          in ([PC.PLTOPDECFUN(plfunbinds, loc)], SEnv.empty)
          end
*)
      | A.TOPEXP (exp, loc) =>
        [PC.PLTOPDECSTR
           (PC.PLCOREDEC
              (PC.PDVAL
                 (emptyTvars,
                  [(PC.PLPATID (SymbolWithLoc.mkLongsymbol ["it"] (LOC loc)),
                    ElaborateCore.elabExp exp,
                    LOC loc)],
                  LOC loc),
               LOC loc),
            LOC loc)]

    and elabTopDecs topdecs =
        List.concat (map elabTopDec topdecs)

end
