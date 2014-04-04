(*
 * Elaborator.
 *
 * @copyright (c) 2006, Tohoku University.
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

  val checkNameDuplication = EU.checkNameDuplication
  val checkNameDuplication' = EU.checkNameDuplication'
  val checkSymbolDuplication = EU.checkSymbolDuplication
  val checkSymbolDuplication' = EU.checkSymbolDuplication'

  structure A = Absyn
  structure PC = PatternCalc

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
        val env = SEnv.unionWith #2 (env, env1)
        val (elems2, env2) = elabSequence elab env elems
      in
        (elems1 @ elems2, SEnv.unionWith #2 (env1, env2))
      end

  fun elabBinds elaborator elements =
      map (fn (label, element) => (label, elaborator element)) elements

  fun specListToSpecSeq loc specList =
      let
        fun makeSeqSpec [] = raise Bug.Bug "nilspec found in elaborate"
          | makeSeqSpec [spec] = spec
          | makeSeqSpec (spec :: specs) =
            PC.PLSPECSEQ(spec, makeSeqSpec specs, loc)
      in makeSeqSpec specList
      end

    fun elabSpec spec =
      case spec of
        A.SPECSEQ(A.SPECEMPTY, spec, loc) => elabSpec spec
      | A.SPECSEQ(spec, A.SPECEMPTY, loc) => elabSpec spec
      | A.SPECSEQ(spec1, spec2, loc) =>
          PC.PLSPECSEQ(elabSpec spec1, elabSpec spec2, loc)
      | A.SPECVAL(valBinds, loc) =>
          let
            val _ = checkSymbolDuplication
                        #1
                        valBinds E.DuplicateValDesc
            val _ =
                app (fn (vid, ty) =>
                        ElaborateCore.checkReservedNameForValBind
                          vid)
                    valBinds
            val specs =
                map (fn (vid, ty) => PC.PLSPECVAL (emptyTvars, vid, ty, loc))
                    valBinds
          in
            specListToSpecSeq loc specs
          end
      | A.SPECTYPE(tydescs, loc) => 
          let
            val _ =
                UserErrorUtils.checkSymbolDuplication
                  #2 tydescs E.DuplicateTypDesc
          in
            PC.PLSPECTYPE {tydecls=tydescs, iseq=false, loc=loc}
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
      | A.SPECDERIVEDTYPE(maniftypedescs, loc) =>
          let 
            val _ =
              checkSymbolDuplication
                  #2
                  maniftypedescs E.DuplicateTypDesc
            fun elabTypeEquation (tvars, symbol, ty) = 
                PC.PLSPECTYPEEQUATION ((tvars, symbol, ty), loc)
          in 
            specListToSpecSeq loc (map elabTypeEquation maniftypedescs)
          end
      | A.SPECEQTYPE(tydescs, loc) => 
          let
            val _ =
                UserErrorUtils.checkSymbolDuplication
                  #2
                  tydescs E.DuplicateTypDesc
          in
            PC.PLSPECTYPE{tydecls=tydescs, iseq=true, loc=loc}
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
                  #2
                  dataDescs E.DuplicateTypDesc
            fun check (tvar, name, conDescs) = 
                (
                 UserErrorUtils.checkSymbolDuplication
                   (fn (con, ty) => con)
                   conDescs E.DuplicateConstructorNameInDatatype;
                 app (fn (con, ty) =>
                         ElaborateCore.checkReservedNameForConstructorBind
                           con)
                   conDescs;
                 ()
                )
            val _ = map check dataDescs
          in
            PC.PLSPECDATATYPE(dataDescs, loc)
          end
      | A.SPECREPLIC(tyCon, longTyCon, loc) =>
          PC.PLSPECREPLIC(tyCon, longTyCon, loc)
      | A.SPECEXCEPTION(exnDescs, loc) =>
          let
            val _ = 
              checkSymbolDuplication
                  #1
                  exnDescs E.DuplicateConstructorNameInException
            val _ =
              app (fn (con, ty) =>
                      ElaborateCore.checkReservedNameForConstructorBind
                        con)
                  exnDescs;
            val exnDescs =
                map (fn (symbol, tyOpt) => (symbol, tyOpt)) exnDescs
          in
            PC.PLSPECEXCEPTION(exnDescs, loc)
          end
      | A.SPECSTRUCT(strdescs, loc) => 
          let
            val _ = 
              checkNameDuplication
                  (fn x => Symbol.symbolToString (#1 x)) strdescs loc E.DuplicateStrDesc
          in
            PC.PLSPECSTRUCT (elabBinds elabSigExp strdescs, 
                             loc)
          end
      | A.SPECINCLUDE(sigexp, loc)=>
        PC.PLSPECINCLUDE(elabSigExp sigexp, loc)
      | A.SPECDERIVEDINCLUDE(sigids, loc) => 
          let
            fun elabSigID sigid =
                PC.PLSPECINCLUDE(PC.PLSIGID sigid, loc)
          in
            specListToSpecSeq loc (map elabSigID sigids)
          end
      | A.SPECSHARE(spec, longTyCons, loc) => 
          PC.PLSPECSHARE (elabSpec spec, longTyCons, loc)
      | A.SPECSHARESTR(spec, longstrids, loc) => 
          PC.PLSPECSHARESTR (elabSpec spec, longstrids, loc)
      | A.SPECEMPTY => PC.PLSPECEMPTY


    and elabSigExp sigexp =
      case sigexp of 
        A.SIGEXPBASIC(spec, loc) => PC.PLSIGEXPBASIC(elabSpec spec, loc)
      | A.SIGID(sigid,loc) => PC.PLSIGID sigid
      | A.SIGWHERE(sigexp, whtype, loc) =>
        PC.PLSIGWHERE(elabSigExp sigexp, whtype, loc)

    and elabStrExp env strexp =
      case strexp of
        A.STREXPBASIC(strdecs, loc) => 
          let val (plstrdecs, env') = elabStrDecs env strdecs
          in PC.PLSTREXPBASIC(plstrdecs, loc)
          end
      | A.STRID(longid, loc) => PC.PLSTRID longid
      | A.STRTRANCONSTRAINT(strexp, sigexp, loc) =>
          PC.PLSTRTRANCONSTRAINT
          (elabStrExp env strexp, elabSigExp sigexp, loc)
      | A.STROPAQCONSTRAINT(strexp, sigexp, loc) =>
          PC.PLSTROPAQCONSTRAINT
          (elabStrExp env strexp, elabSigExp sigexp, loc)
        | A.FUNCTORAPP(funid, A.STRID(longid, loc1), loc2) => 
            PC.PLFUNCTORAPP(funid, longid, loc2)
        | A.FUNCTORAPP(funid, strexp, loc) => 
            let
              val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
              val newStrLong = Symbol.mkLongsymbol [newStrid] loc
              val newStrSymbol = Symbol.mkSymbol newStrid loc
              val plstrexp = elabStrExp env strexp
              val plstrbody = PC.PLFUNCTORAPP(funid, newStrLong, loc)
              val plstrDecs =[PC.PLSTRUCTBIND([(newStrSymbol,plstrexp)],loc)]
            in
              PC.PLSTRUCTLET(plstrDecs, plstrbody, loc)
            end
(*
      | A.FUNCTORAPP(funid, strexp, loc) => 
          PC.PLFUNCTORAPP(funid, elabStrExp env strexp, loc)
*)
      | A.STRUCTLET(strdecs, strexp, loc) =>
          let
            val (plstrdecs, env') = elabStrDecs env strdecs
            val newenv = SEnv.unionWith #1 (env', env)
          in
            PC.PLSTRUCTLET(plstrdecs, elabStrExp newenv strexp, loc)
          end

    and elabStrBind env strbind =
      case strbind of
        A.STRBINDTRAN(strid, sigexp, strexp, loc) =>
          (
           strid,
           PC.PLSTRTRANCONSTRAINT
           (elabStrExp env strexp, elabSigExp sigexp, loc)
           )
      | A.STRBINDOPAQUE(strid, sigexp, strexp, loc) =>
          (
           strid,
           PC.PLSTROPAQCONSTRAINT
           (elabStrExp env strexp, elabSigExp sigexp, loc)
           )
      | A.STRBINDNONOBSERV(strid, strexp, loc) =>
          (strid, elabStrExp env strexp)

    and elabStrDec env strdec =
      case strdec of 
        A.COREDEC(dec, loc) => 
          let val (pldecs, env) = ElaborateCore.elabDec env dec
          in (map (fn pldec => PC.PLCOREDEC(pldec, loc)) pldecs, env)
          end
      | A.STRUCTBIND(strbinds,loc) => 
          ([PC.PLSTRUCTBIND(map (elabStrBind env) strbinds, loc)],
           SEnv.empty)
      | A.STRUCTLOCAL(strdecs1, strdecs2, loc) =>
          let
            val (plstrdecs1, env1) = elabStrDecs env strdecs1
            val (plstrdecs2, env2) =
              elabStrDecs (SEnv.unionWith #1 (env1, env)) strdecs2
          in
            ([PC.PLSTRUCTLOCAL(plstrdecs1, plstrdecs2, loc)], env2)
          end

    and elabStrDecs env strdecs = elabSequence elabStrDec env strdecs

    and elabFunBind env funbind  =
      case funbind of
        (* functor F(A:sig1) : sig2 = str  =>
                   functor F(A:sig1) = str : sig2 *)
          A.FUNBINDTRAN (funid, strid, argSigexp, resSigexp, strexp, loc) =>
        let val newStrexp = A.STRTRANCONSTRAINT(strexp, resSigexp, loc)
        in
          elabFunBind
            env
            (A.FUNBINDNONOBSERV(funid, strid, argSigexp, newStrexp, loc))
        end
          (* functor F(A:sig1) :> sig2 = str  =>
            functor F(A:sig1) = str :> sig2
           *)
      | A.FUNBINDOPAQUE (funid, strid, argSigexp, resSigexp, strexp, loc) =>
        let val newStrexp = A.STROPAQCONSTRAINT(strexp, resSigexp, loc)
        in
          elabFunBind
            env
            (A.FUNBINDNONOBSERV(funid, strid, argSigexp, newStrexp, loc))
        end
      (* functor F(spec) : sig = str  =>
         functor F('x:sig spec end) = let open 'X in str:sig end 
       *)
      | A.FUNBINDSPECTRAN(funid, spec, resSigexp, strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRUCTLET
                ([A.COREDEC(A.DECOPEN([ Symbol.mkLongsymbol [newStrid] loc], loc), loc)], 
                 A.STRTRANCONSTRAINT(strexp,resSigexp,loc),
                 loc)
          val argSigExp = A.SIGEXPBASIC(spec, loc)
          val newFunBind =
              A.FUNBINDNONOBSERV
                (funid, Symbol.mkSymbol newStrid loc, argSigExp, newStrexp, loc)
        in
          elabFunBind env newFunBind
        end
      (* functor F(spec) :> sig = str  =>
         functor F('x:sig spec end) = let open 'X in str:>sig end 
       *)
      | A.FUNBINDSPECOPAQUE(funid, spec, resSigexp, strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRUCTLET
                ([A.COREDEC(A.DECOPEN([Symbol.mkLongsymbol [newStrid] loc], loc), loc)], 
                 A.STROPAQCONSTRAINT(strexp,resSigexp,loc),
                 loc)
          val argSigExp = A.SIGEXPBASIC(spec, loc)
          val newFunBind =
              A.FUNBINDNONOBSERV
                (funid, Symbol.mkSymbol newStrid loc, argSigExp, newStrexp, loc)
        in
          elabFunBind env newFunBind
        end
      (* functor F(spec) = str  =>
         functor F('x:sig spec end) = let open 'X in str end 
       *)
      | A.FUNBINDSPECNONOBSERV (funid, spec, strexp, loc) =>
        let
          val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
          val newStrexp =
              A.STRUCTLET
                ([A.COREDEC(A.DECOPEN([Symbol.mkLongsymbol [newStrid] loc], loc), loc)], strexp, loc)
          val newFunBind =
              A.FUNBINDNONOBSERV
                (funid, Symbol.mkSymbol newStrid loc, A.SIGEXPBASIC(spec, loc), newStrexp, loc)
        in
          elabFunBind env newFunBind
        end
      (* functor F(A:sig) = str
       *)
      | A.FUNBINDNONOBSERV(funid, strid, argSigexp, strexp, loc) =>
        let
          val newArgSigexp = elabSigExp argSigexp
          val newStrexp = elabStrExp env strexp
        in
          {name = funid,
           argStrName = strid,
           argSig=newArgSigexp,
           body=newStrexp,
           loc=loc}
        end

    and elabTopDec env topdec = 
      case topdec of 
        A.TOPDECSTR(strdec, loc) => 
          let val (plstrdecs, env') = elabStrDec env strdec
          in
            (map (fn plstrdec => PC.PLTOPDECSTR(plstrdec, loc)) plstrdecs,
             env')
          end
      | A.TOPDECSIG(sigdecs, loc) => 
          let val plsigdecs = elabBinds elabSigExp sigdecs
          in ([PC.PLTOPDECSIG(plsigdecs, loc)], SEnv.empty)
          end
      | A.TOPDECFUN(funbinds, loc) =>
          let
            val plfunbinds = map (elabFunBind env) funbinds
          in ([PC.PLTOPDECFUN(plfunbinds, loc)
              ],
              SEnv.empty)
          end
(*
      | A.TOPDECFUN(funbinds, loc) =>
          let val plfunbinds = map (elabFunBind env) funbinds
          in ([PC.PLTOPDECFUN(plfunbinds, loc)], SEnv.empty)
          end
*)
    and elabTopDecs env topdecs = elabSequence elabTopDec env topdecs
      
end
