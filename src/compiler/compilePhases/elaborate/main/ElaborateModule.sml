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

  structure A = Absyn
  structure PC = PatternCalc

  fun toSymbol ((sym, loc):A.vid) = {symbol = sym, loc = LOC loc}
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

    fun elabSpec spec =
        case spec of
          A.SPECVAL(valBinds, loc) =>
          let
            val specs =
                map (fn (vid, ty, _) => (emptyTvars, toSymbol vid, ty, LOC loc))
                    valBinds
          in
            [PC.PLSPECVAL specs]
          end
        | A.SPECTYPE(tydescs, loc) =>
          let
            val tydescs = map (fn (tvars, symbol, _) => (seq tvars, toSymbol symbol)) tydescs
          in
            [PC.PLSPECTYPE {tydecls=tydescs, eq=false, loc=LOC loc}]
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
            fun elabTypeEquation (tvars, symbol, ty, _) =
                PC.PLSPECTYPEEQUATION ((seq tvars, toSymbol symbol, ty), LOC loc)
          in
            map elabTypeEquation maniftypedescs
          end
        | A.SPECEQTYPE(tydescs, loc) =>
          let
            val tydescs = map (fn (tvars, symbol, _) => (seq tvars, toSymbol symbol)) tydescs
          in
            [PC.PLSPECTYPE{tydecls=tydescs, eq=true, loc=LOC loc}]
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
          [PC.PLSPECDATATYPE
             (map (fn (tyvars, symbol, con, loc) =>
                      {tyvars = seq tyvars, loc = LOC loc, symbol = toSymbol symbol,
                       conbind = map (fn (id,ty, loc) => {symbol=toSymbol id, ty=ty, loc=LOC loc}) con})
                  dataDescs,
              LOC loc)]
        | A.SPECDATATYPEREP(tyCon, longTyCon, loc) =>
          [PC.PLSPECREPLIC(toSymbol tyCon, SymbolWithLoc.fromAbsyn longTyCon, LOC loc)]
        | A.SPECEXCEPTION(exnDescs, loc) =>
          let
            val exnDescs =
                map (fn (symbol, tyOpt, loc) => (toSymbol symbol, tyOpt, LOC loc)) exnDescs
          in
            [PC.PLSPECEXCEPTION(exnDescs, LOC loc)]
          end
        | A.SPECSTRUCTURE(strdescs, loc) =>
          [PC.PLSPECSTRUCT (elabBinds elabSigExp strdescs, LOC loc)]
        | A.SPECINCLUDE(sigexp, loc)=>
          [PC.PLSPECINCLUDE(elabSigExp sigexp, LOC loc)]
        | A.SPECINCLUDE_ID(sigids, loc) =>
          let
            fun elabSigID sigid =
                PC.PLSPECINCLUDE(PC.PLSIGID (toSymbol sigid), LOC loc)
          in
            map elabSigID sigids
          end
        | A.SPECSHARINGTYPE(spec, longTyCons, loc) =>
          [PC.PLSPECSHARE (elabSpecList spec, map SymbolWithLoc.fromAbsyn longTyCons, LOC loc)]
        | A.SPECSHARING(spec, longstrids, loc) =>
          [PC.PLSPECSHARESTR (elabSpecList spec, map SymbolWithLoc.fromAbsyn longstrids, LOC loc)]
        | A.SPECSEMICOLON _ => nil

    and elabSpecList specs =
        List.concat (map elabSpec specs)

    and elabSigExp sigexp =
        case sigexp of
          A.SIGBASIC(spec, loc) =>
          PC.PLSIGEXPBASIC(elabSpecList spec, LOC loc)
        | A.SIGID sigid =>
          PC.PLSIGID (toSymbol sigid)
        | A.SIGWHERE (sigexp, whtypes, loc) =>
          foldl
            (fn ((NONE, longsymbol, ty, _), plsigexp) =>
                PC.PLSIGWHERE (plsigexp, (nil, SymbolWithLoc.fromAbsyn longsymbol, ty), LOC loc)
              | ((SOME (tvars, _), longsymbol, ty, _), plsigexp) =>
                PC.PLSIGWHERE (plsigexp, (tvars, SymbolWithLoc.fromAbsyn longsymbol, ty), LOC loc))
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
        | A.STRID longid => PC.PLSTRID (SymbolWithLoc.fromAbsyn longid)
        | A.STRCONSTRAINT(strexp, (A.TRANSPARENT, sigexp, _), loc) =>
          PC.PLSTRTRANCONSTRAINT
            (elabStrExp strexp, elabSigExp sigexp, LOC loc)
        | A.STRCONSTRAINT(strexp, (A.OPAQUE, sigexp, _), loc) =>
          PC.PLSTROPAQCONSTRAINT
            (elabStrExp strexp, elabSigExp sigexp, LOC loc)
        | A.STRAPP(funid, SOME (A.FUNARG (A.STRID longid)), loc) =>
          PC.PLFUNCTORAPP(toSymbol funid, SymbolWithLoc.fromAbsyn longid, LOC loc)
        | A.STRAPP(funid, SOME (A.FUNARG strexp), loc) =>
          let
            val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
            val newStrLong = SymbolWithLoc.mkLongsymbol (nil, newStrid) (LOC loc)
            val newStrSymbol = SymbolWithLoc.mkSymbol newStrid (LOC loc)
            val plstrexp = elabStrExp strexp
            val plstrbody = PC.PLFUNCTORAPP(toSymbol funid, newStrLong, LOC loc)
            val plstrDecs =[PC.PLSTRUCTBIND([(newStrSymbol,plstrexp, LOC loc)],LOC loc)]
          in
            PC.PLSTRUCTLET(plstrDecs, plstrbody, LOC loc)
          end
        | A.STRAPP (funid, SOME (A.FUNARG_DEC (strdecs, _)), loc) =>
          elabStrExp (A.STRAPP (funid, SOME (A.FUNARG (A.STRBASIC (strdecs, loc))), loc))
        | A.STRAPP (funid, NONE, loc) =>
          elabStrExp (A.STRAPP (funid, SOME (A.FUNARG (A.STRBASIC (nil, loc))), loc))
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
          map PC.PLCOREDEC pldecs
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
        (funid, param as SOME (A.FUNPARAM _),
         SOME (A.TRANSPARENT, resSigexp, _),
         strexp, loc) =>
        let val newStrexp = A.STRCONSTRAINT(strexp, (A.TRANSPARENT, resSigexp, loc), loc)
        in
          elabFunBind (funid, param, NONE, newStrexp, loc)
        end
          (* functor F(A:sig1) :> sig2 = str  =>
            functor F(A:sig1) = str :> sig2
           *)
      | (funid, param as SOME (A.FUNPARAM _),
         SOME (A.OPAQUE, resSigexp, _),
         strexp, loc) =>
        let val newStrexp = A.STRCONSTRAINT(strexp, (A.OPAQUE, resSigexp, loc), loc)
        in
          elabFunBind (funid, param, NONE, newStrexp, loc)
        end
      (* functor F(spec) : sig = str  =>
         functor F('x:sig spec end) = let open 'X in str:sig end
       *)
      | (funid, SOME (A.FUNPARAM_SPEC specLoc),
         SOME (A.TRANSPARENT, resSigexp, _),
         strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRLET
                ([A.STRDEC(A.DECOPEN([(nil, (Symbol.fromString newStrid, loc), loc)], loc))],
                 A.STRCONSTRAINT(strexp,(A.TRANSPARENT,resSigexp,loc),loc),
                 loc)
          val argSigExp = A.SIGBASIC specLoc
          val newFunBind =
              (funid, SOME (A.FUNPARAM ((Symbol.fromString newStrid, loc), argSigExp, #2 specLoc)), NONE, newStrexp, loc)
        in
          elabFunBind newFunBind
        end
      (* functor F(spec) :> sig = str  =>
         functor F('x:sig spec end) = let open 'X in str:>sig end
       *)
      | (funid, SOME (A.FUNPARAM_SPEC specLoc),
         SOME (A.OPAQUE, resSigexp, _),
         strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRLET
                ([A.STRDEC(A.DECOPEN([(nil, (Symbol.fromString newStrid, loc), loc)], loc))],
                 A.STRCONSTRAINT(strexp,(A.OPAQUE,resSigexp,loc),loc),
                 loc)
          val argSigExp = A.SIGBASIC specLoc
          val newFunBind =
              (funid, SOME (A.FUNPARAM ((Symbol.fromString newStrid, loc), argSigExp, #2 specLoc)), NONE, newStrexp, loc)
        in
          elabFunBind newFunBind
        end
      (* functor F(spec) = str  =>
         functor F('x:sig spec end) = let open 'X in str end
       *)
      | (funid, SOME (A.FUNPARAM_SPEC specLoc), NONE, strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRLET
                ([A.STRDEC(A.DECOPEN([(nil, (Symbol.fromString newStrid, loc), loc)], loc))], strexp, loc)
          val newFunBind =
              (funid, SOME (A.FUNPARAM ((Symbol.fromString newStrid, loc), A.SIGBASIC specLoc, #2 specLoc)), NONE, newStrexp, loc)
        in
          elabFunBind newFunBind
        end
      | (funid, NONE, sigcon, strexp, loc) =>
        let
          val newStrid = Symbol.fromString NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newFunBind =
              (funid, SOME (A.FUNPARAM ((newStrid, loc), A.SIGBASIC (nil, loc), loc)), sigcon, strexp, loc)
        in
          elabFunBind newFunBind
        end
      (* functor F(A:sig) = str
       *)
      | (funid, SOME (A.FUNPARAM (strid, argSigexp, _)), NONE, strexp, loc) =>
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
            map PC.PLTOPDECSTR plstrdecs
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
                  [(PC.PLPATID (SymbolWithLoc.mkLongsymbol (nil, "it") (LOC loc)),
                    ElaborateCore.elabExp exp,
                    LOC loc)],
                  nil,
                  LOC loc)))]

    and elabTopDecs topdecs =
        List.concat (map elabTopDec topdecs)

end
