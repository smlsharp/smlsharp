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

  val checkSymbolDuplication = EU.checkSymbolDuplication
  val checkSymbolDuplication' = EU.checkSymbolDuplication'

  structure A = Absyn
  structure PC = PatternCalc

  fun toSymbol ((sym, loc):A.vid) = {symbol = sym, loc = loc}
  fun toLongsymbol ((ids,_):A.longvid) = map toSymbol ids

  (**
   * name given to an anonymous parameter signature of a functor.
   * Example:
   *   functor F(type x) = struct datatype dt = D of x end
   * is elaborated to:
   *   functor F ('X : sig type x end) =
   *   let open 'X in struct datatype dt = D of x end end
   *)
  val NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER = "_X"

  val emptyTvars = nil : PC.scopedTvars

  datatype sigexpKind = Interface | OrdinarySig

  fun elabSequence elab env nil = (nil, env)
    | elabSequence elab env (elem::elems) =
      let
        val (elems1, env1) = elab env elem
        val env = Symbol.Map.unionWith #2 (env, env1)
        val (elems2, env2) = elabSequence elab env elems
      in
        (elems1 @ elems2, Symbol.Map.unionWith #2 (env1, env2))
      end

  fun elabBinds elaborator elements =
      map (fn (label, element, _) => (toSymbol label, elaborator element)) elements

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
                map (fn (vid, ty, _) => PC.PLSPECVAL (emptyTvars, toSymbol vid, ty, loc))
                    valBinds
          in
            specListToSpecSeq specs
          end
      | A.SPECTYPE(tydescs, loc) => 
          let
            val _ =
                UserErrorUtils.checkSymbolDuplication
                  (toSymbol o #2) tydescs E.DuplicateTypDesc
            val tydescs = map (fn ((tvars, _), symbol, _) => (tvars, toSymbol symbol)) tydescs
          in
            PC.PLSPECTYPE {tydecls=tydescs, eq=false, loc=loc}
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
            fun elabTypeEquation ((tvars, _), symbol, ty, _) =
                PC.PLSPECTYPEEQUATION ((tvars, toSymbol symbol, ty), loc)
          in 
            specListToSpecSeq (map elabTypeEquation maniftypedescs)
          end
      | A.SPECEQTYPE(tydescs, loc) => 
          let
            val _ =
                UserErrorUtils.checkSymbolDuplication
                  (toSymbol o #2)
                  tydescs E.DuplicateTypDesc
            val tydescs = map (fn ((tvars, _), symbol, _) => (tvars, toSymbol symbol)) tydescs
          in
            PC.PLSPECTYPE{tydecls=tydescs, eq=true, loc=loc}
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
              (map (fn ((tyvars, _), symbol, con, loc) =>
                       {tyvars = tyvars, loc = loc, symbol = toSymbol symbol,
                        conbind = map (fn (id,ty, loc) => {symbol=toSymbol id, ty=ty, loc=loc}) con})
                   dataDescs,
               loc)
          end
      | A.SPECDATATYPEREP(tyCon, longTyCon, loc) =>
          PC.PLSPECREPLIC(toSymbol tyCon, toLongsymbol longTyCon, loc)
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
                map (fn (symbol, tyOpt, loc) => (toSymbol symbol, tyOpt, loc)) exnDescs
          in
            PC.PLSPECEXCEPTION(exnDescs, loc)
          end
      | A.SPECSTRUCTURE(strdescs, loc) =>
          let
            val _ = checkSymbolDuplication (toSymbol o #1) strdescs E.DuplicateStrDesc
          in
            PC.PLSPECSTRUCT (elabBinds elabSigExp strdescs, 
                             loc)
          end
      | A.SPECINCLUDE(sigexp, loc)=>
        PC.PLSPECINCLUDE(elabSigExp sigexp, loc)
      | A.SPECINCLUDE_ID(sigids, loc) =>
          let
            fun elabSigID sigid =
                PC.PLSPECINCLUDE(PC.PLSIGID (toSymbol sigid), loc)
          in
            specListToSpecSeq (map elabSigID sigids)
          end
      | A.SPECSHARINGTYPE(spec, longTyCons, loc) =>
          PC.PLSPECSHARE (elabSpecList spec, map toLongsymbol longTyCons, loc)
      | A.SPECSHARING(spec, longstrids, loc) =>
          PC.PLSPECSHARESTR (elabSpecList spec, map toLongsymbol longstrids, loc)
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
          A.SIGBASIC(spec, loc) => PC.PLSIGEXPBASIC(elabSpecList spec, loc)
        | A.SIGID sigid => PC.PLSIGID (toSymbol sigid)
        | A.SIGWHERE (sigexp, whtypes, loc) =>
          foldl
            (fn (((tvars, _), longsymbol, ty, _), plsigexp) =>
                PC.PLSIGWHERE (plsigexp, (tvars, toLongsymbol longsymbol, ty), loc))
            (elabSigExp sigexp)
            whtypes

    and elabStrExp env strexp =
      case strexp of
        A.STRBASIC(strdecs, loc) =>
          let val (plstrdecs, env') = elabStrDecs env strdecs
          in PC.PLSTREXPBASIC(plstrdecs, loc)
          end
      | A.STRID longid => PC.PLSTRID (toLongsymbol longid)
      | A.STRCONSTRAINT(strexp, A.TRANSPARENT, sigexp, loc) =>
          PC.PLSTRTRANCONSTRAINT
          (elabStrExp env strexp, elabSigExp sigexp, loc)
      | A.STRCONSTRAINT(strexp, A.OPAQUE, sigexp, loc) =>
          PC.PLSTROPAQCONSTRAINT
          (elabStrExp env strexp, elabSigExp sigexp, loc)
        | A.STRAPP(funid, A.FUNARG (A.STRID longid), loc) =>
            PC.PLFUNCTORAPP(toSymbol funid, toLongsymbol longid, loc)
        | A.STRAPP(funid, A.FUNARG strexp, loc) =>
            let
              val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
              val newStrLong = SymbolWithLoc.mkLongsymbol [newStrid] loc
              val newStrSymbol = SymbolWithLoc.mkSymbol newStrid loc
              val plstrexp = elabStrExp env strexp
              val plstrbody = PC.PLFUNCTORAPP(toSymbol funid, newStrLong, loc)
              val plstrDecs =[PC.PLSTRUCTBIND([(newStrSymbol,plstrexp, loc)],loc)]
            in
              PC.PLSTRUCTLET(plstrDecs, plstrbody, loc)
            end
        | A.STRAPP (funid, A.FUNARG_DEC strdecs, loc) =>
          elabStrExp env (A.STRAPP (funid, A.FUNARG (A.STRBASIC (strdecs, loc)), loc))
(*
      | A.FUNCTORAPP(funid, strexp, loc) => 
          PC.PLFUNCTORAPP(funid, elabStrExp env strexp, loc)
*)
      | A.STRLET(strdecs, strexp, loc) =>
          let
            val (plstrdecs, env') = elabStrDecs env strdecs
            val newenv = Symbol.Map.unionWith #1 (env', env)
          in
            PC.PLSTRUCTLET(plstrdecs, elabStrExp newenv strexp, loc)
          end

    and elabStrBind env strbind =
      case strbind of
        (strid, SOME (A.TRANSPARENT, sigexp, _), strexp, loc) =>
          (
           toSymbol strid,
           PC.PLSTRTRANCONSTRAINT
           (elabStrExp env strexp, elabSigExp sigexp, loc),
           loc
           )
      | (strid, SOME (A.OPAQUE, sigexp, _), strexp, loc) =>
          (
           toSymbol strid,
           PC.PLSTROPAQCONSTRAINT
           (elabStrExp env strexp, elabSigExp sigexp, loc),
           loc
           )
      | (strid, NONE, strexp, loc) =>
          (toSymbol strid, elabStrExp env strexp, loc)

    and elabStrDec env strdec =
      case strdec of 
        A.STRDEC dec =>
          let val (pldecs, env) = ElaborateCore.elabDec env dec
          in (map (fn pldec => PC.PLCOREDEC(pldec, AbsynUtils.decLoc dec)) pldecs, env)
          end
      | A.STRUCTURE(strbinds,loc) =>
          ([PC.PLSTRUCTBIND(map (elabStrBind env) strbinds, loc)],
           Symbol.Map.empty)
      | A.STRLOCAL(strdecs1, strdecs2, loc) =>
          let
            val (plstrdecs1, env1) = elabStrDecs env strdecs1
            val (plstrdecs2, env2) =
              elabStrDecs (Symbol.Map.unionWith #1 (env1, env)) strdecs2
          in
            ([PC.PLSTRUCTLOCAL(plstrdecs1, plstrdecs2, loc)], env2)
          end
      | A.STRSEMICOLON _ => (nil, Symbol.Map.empty)

    and elabStrDecs env strdecs = elabSequence elabStrDec env strdecs

    and elabFunBind env funbind  =
      case funbind of
        (* functor F(A:sig1) : sig2 = str  =>
                   functor F(A:sig1) = str : sig2 *)
        (funid, A.FUNPARAM (strid, argSigexp),
         SOME (A.TRANSPARENT, resSigexp, _),
         strexp, loc) =>
        let val newStrexp = A.STRCONSTRAINT(strexp, A.TRANSPARENT, resSigexp, loc)
        in
          elabFunBind
            env
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
            env
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
          elabFunBind env newFunBind
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
          elabFunBind env newFunBind
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
          elabFunBind env newFunBind
        end
      (* functor F(A:sig) = str
       *)
      | (funid, A.FUNPARAM (strid, argSigexp), NONE, strexp, loc) =>
        let
          val newArgSigexp = elabSigExp argSigexp
          val newStrexp = elabStrExp env strexp
        in
          {name = toSymbol funid,
           argStrName = toSymbol strid,
           argSig=newArgSigexp,
           body=newStrexp,
           loc=loc}
        end

    and elabTopDec env topdec = 
      case topdec of 
        A.TOPSTRDEC strdec =>
          let val (plstrdecs, env') = elabStrDec env strdec
          in
            (map (fn plstrdec => PC.PLTOPDECSTR(plstrdec, AbsynUtils.strdecLoc strdec)) plstrdecs,
             env')
          end
      | A.TOPSIGNATURE(sigdecs, loc) =>
          let val plsigdecs = elabBinds elabSigExp sigdecs
          in ([PC.PLTOPDECSIG(plsigdecs, loc)], Symbol.Map.empty)
          end
      | A.TOPFUNCTOR(funbinds, loc) =>
          let
            val plfunbinds = map (elabFunBind env) funbinds
          in ([PC.PLTOPDECFUN(plfunbinds, loc)
              ],
              Symbol.Map.empty)
          end
(*
      | A.TOPDECFUN(funbinds, loc) =>
          let val plfunbinds = map (elabFunBind env) funbinds
          in ([PC.PLTOPDECFUN(plfunbinds, loc)], SEnv.empty)
          end
*)
      | A.TOPEXP (exp, loc) =>
        ([PC.PLTOPDECSTR
            (PC.PLCOREDEC
               (PC.PDVAL
                  (nil,
                   [(PC.PLPATID (SymbolWithLoc.mkLongsymbol ["it"] Loc.noloc),
                     ElaborateCore.elabExp env exp,
                     Loc.noloc)],
                   loc),
                loc),
             loc)],
         Symbol.Map.empty)

    and elabTopDecs env topdecs = elabSequence elabTopDec env topdecs
      
end
