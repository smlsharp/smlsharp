(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure EvalIty =
struct
local
  structure I = IDCalc
  structure T = Types
  structure TB = TypesBasics
  fun bug s = Bug.Bug ("EvalITy: " ^ s)
  val debugPrint = fn s => if !Bug.debugPrint then print s else ()
  fun printTy ty = debugPrint (Bug.prettyPrint (I.format_ty ty))
  fun printTfun tfun =
      debugPrint (Bug.prettyPrint (I.format_tfun tfun))
  fun printPath path =
      debugPrint (String.concatWith "." path)

in
  type ityContext = {oprimEnv:I.ty OPrimMap.map,
                     tvarEnv:Types.ty TvarMap.map, 
                     varEnv:I.ty VarMap.map}
  val emptyContext : ityContext = 
      {
       oprimEnv=OPrimMap.empty,
       tvarEnv=TvarMap.empty,
       varEnv=VarMap.empty
      }
  exception EVALTFUN of {iseq:bool, formals:I.formals, realizerTy:I.ty, longsymbol:Symbol.longsymbol}

  fun evalDtyKind context dtyKind = 
      case dtyKind of
        I.DTY => T.DTY
      | I.DTY_INTERFACE => T.DTY
      | I.FUNPARAM => T.DTY
      | I.OPAQUE {tfun, revealKey} =>
        let
          val opaqueRep = 
              T.TYCON (evalTfun context tfun)
              handle
              EVALTFUN{iseq, formals, realizerTy, longsymbol} =>
              let
                val (context, btvEnv) =
                    evalKindedTvarList
                      context 
                      (map (fn tv => (tv, I.UNIV)) formals)
                val rty = evalIty context realizerTy
              in
                T.TFUNDEF {iseq=iseq,
                           arity=length formals,
                           polyTy=T.POLYty{boundtvars=btvEnv,constraints = nil, body=rty}
                           }
              end
        in
          T.OPAQUE {opaqueRep=opaqueRep, revealKey=revealKey}
        end
      | I.BUILTIN builtinTy => T.BUILTIN builtinTy
(*
  and evalTfun context path tfun = 
*)
  and evalTfun context tfun = 
      case tfun of
        I.TFUN_DEF {iseq, formals, realizerTy, longsymbol} =>
        raise EVALTFUN {iseq=iseq, formals=formals, realizerTy=realizerTy, longsymbol=longsymbol}
      | I.TFUN_VAR tfunKindRef =>
        (case tfunKindRef of
           ref(I.TFUN_DTY{id,iseq,formals,runtimeTy, longsymbol, conIDSet,
                           conSpec,liftedTys,dtyKind}) =>
           let
             (* Here we changed LIFTEDty to BOXED.
               I think this is OK since this type only occurrs in the functor body
               and we changes all of them.
               The other possibility is to introduce (LIFTEDty builtinTy) in
               tyCon. 
               *)
             val runtimeTy = 
                 case runtimeTy of
                   I.BUILTINty ty => ty
                 | I.LIFTEDty _ => BuiltinTypeNames.BOXEDty
             val (argTyContext, btvEnv) =
                 evalKindedTvarList
                   context
                   (map (fn ty => (ty, I.UNIV)) formals)
             val argTyFn =
                 if BoundTypeVarID.Map.isEmpty btvEnv
                 then fn ity => fn () => evalIty argTyContext ity
                 else fn ity => fn () =>
                         T.POLYty {boundtvars = btvEnv,
                                   constraints = nil,
                                   body = evalIty argTyContext ity}
           in
              {id = id,
             (* 2012-7-15 ohori: bug 207_printer.sml. 
               path = path,
              *)
               longsymbol = longsymbol,
               iseq = iseq,
	       runtimeTy = runtimeTy,
               arity = List.length formals,
               conIDSet = conIDSet,
               conSet = SymbolEnv.map (Option.map argTyFn) conSpec,
               extraArgs = map (evalIty context) (I.liftedTysToTy liftedTys),
               dtyKind = evalDtyKind context dtyKind
              }
           end
         | ref(I.TFV_SPEC {longsymbol, id, iseq, formals}) =>
           (debugPrint "****** evalTfun ******\n";
            debugPrint "tfun\n";
            printTfun tfun;
            debugPrint "\n";
            raise bug "TFV_SPEC in evalTfun"
           )
         | ref(I.TFV_DTY {longsymbol, id,iseq,formals,conSpec,liftedTys}) =>
           (debugPrint "****** evalTfun ******\n";
            debugPrint "tfun\n";
            printTfun tfun;
            debugPrint "\n";
            raise bug "TFV_DTY in evalTfun"
           )
         | ref(I.REALIZED{tfun,...}) => evalTfun context tfun
         | ref(I.INSTANTIATED{tfun,...}) => evalTfun context tfun
         | ref(I.FUN_DTY{tfun,...}) => evalTfun context tfun
        )
  and evalIty context ity =
       case ity of
         I.TYWILD => T.newty T.univKind
       | I.TYERROR => T.ERRORty
       | I.TYVAR tvar =>
         (case TvarMap.find(#tvarEnv context, tvar) of
            SOME ty => ty
          | NONE => 
            (debugPrint "evalIty tvar not found\n";
             printTy ity;
             raise bug ("free tvar:" ^(Bug.prettyPrint(I.format_ty ity)))
            )
         )
       | I.TYRECORD tyMap => T.RECORDty (RecordLabel.Map.map (evalIty context) tyMap)
       | I.TYCONSTRUCT {tfun, args} => 
(*
  2016-11-02 JSON.null 大堀：に関する以下のad hocな対応は必要ないと思われる．
*)
         (* JSON.nullを'a#json optionに変換; circulr referenceのためbuiltintypesが使えないことに
            ともない，ad-hocな対応;
          *)
         let
           fun isJsonNullTfun tfun = false
           (* 2016-10-24 sasaki: UserLevelPrimitiveとの循環参照を避けるための一時的な変更
               (case tfun of
                  I.TFUN_VAR (ref (I.TFUN_DTY {longsymbol, ...})) =>
                  if map Symbol.symbolToString longsymbol = ["JSON", "null"] andalso
                     TypID.eq(I.tfunId tfun, I.tfunId (UserLevelPrimitive.JSON_null_tfun())) then
                    true 
                  else false
                | _ => false
               )
               handle Bug.Bug _ => false
            *)
         in
(* 2016-10-24 sasaki: isJsonNullTfunは常にfalseを返すようにしたため変更
           if isJsonNullTfun tfun then
             let
(* 
 (*
  NILと同様の扱いで，POLYtyを与える必要があが，ユーザライブラリのapply termであるため
  このad hocな解決は困難
 *)
               val btvid = BoundTypeVarID.generate ()
               val btvEnv = BoundTypeVarID.Map.insert
                            (BoundTypeVarID.Map.empty,
                             btvid,
                             {tvarKind = T.JSON,
                              eqKind = T.NONEQ}
                            )
                   handle e => raise e
               val polybody = T.CONSTRUCTty{tyCon = tyCon, args = [T.BOUNDVARty btvid]}
               val polyty = T.POLYty {boundtvars = btvEnv, constraints = nil, body = polybody}
*)
               val arg = T.newtyRaw
                           {lambdaDepth = T.infiniteDepth,
                            tvarKind = T.JSON,
                            eqKind = T.NONEQ,
                            occurresIn = nil,
                            utvarOpt = NONE}
               val tyCon = evalTfun context (UserLevelPrimitive.JSON_option_tfun())
             in
               T.CONSTRUCTty{tyCon = tyCon, args = [arg]}
             end
           else
*)
             let
               val args = map (evalIty context) args
               val tyCon = evalTfun context tfun
                   handle e => raise e
             in
               T.CONSTRUCTty{tyCon=tyCon, args=args}
             end
             handle 
             EVALTFUN {iseq, formals, realizerTy, longsymbol} =>
             if length formals = length args then
               let
                 val args = map (evalIty context) args
                 val tvarTyPairs = ListPair.zip (formals, args)
                 val tvarEnv = #tvarEnv context
                 val tvarEnv = 
                     foldr
                       (fn ((tvar, ty), tvarEnv) =>
                           TvarMap.insert(tvarEnv, tvar, ty))
                       tvarEnv
                       tvarTyPairs
                 val context = {tvarEnv = tvarEnv,
                                varEnv = #varEnv context,
                                oprimEnv = #oprimEnv context}
               in
                 evalIty context realizerTy
               end
             else
               raise bug "TYCONSTRUCT ARITY"
         end
       | I.TYFUNM (tyList,ty2) =>
         T.FUNMty (map (evalIty context) tyList, evalIty context ty2)
       | I.TYPOLY (kindedTvarList, ty) =>
         let
           val (context, btvEnv) = evalKindedTvarList context kindedTvarList
           val ty = evalIty context ty
           (* the following lines are needed to normalize the order
              of bound type variables in a polytype. See the comment of EFTV.
            *)
           val subst = TB.freshSubst btvEnv
           val ty = TB.substBTvar subst ty
           val (_, otset, freeTvs) = TB.EFTV (ty, nil)
           val boundOtset = 
               BoundTypeVarID.Map.foldl
               (fn (T.TYVARty (r as ref (T.TVAR _)), boundOtset) =>
                   OTSet.add(boundOtset, r)
                 | _ => raise bug "not tyvarty"
               )
               OTSet.empty
               subst
           val tids = 
               IEnv.filter 
                 (fn r => OTSet.member(boundOtset, r))
                 freeTvs
           val btvs =
               IEnv.foldl
                 (fn (r as ref(T.TVAR (k as {id, kind, ...})), btvs) =>
                     let 
                       val btvid = BoundTypeVarID.generate ()
                     in
                       (
                        r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                        (
                         BoundTypeVarID.Map.insert
                           (
                            btvs,
                            btvid,
                            kind
                           )
                        )
                       )
                     end
                   | _ => raise Bug.Bug "generalizeTy")
                 BoundTypeVarID.Map.empty
                 tids
         in
           T.POLYty {boundtvars = btvs, constraints = nil, body = ty}
         end
       | I.INFERREDTY ty => ty
  and evalKindedTvarList (context as {tvarEnv, varEnv, oprimEnv}) kindedTvarList =
      let
        fun genBtv ((tvar as {eq, ...}, kind), (btvKindList, tvarEnv)) = 
            let
              val btvId = BoundTypeVarID.generate()
              val btvTy = T.BOUNDVARty btvId
            in
              ((btvId, eq, kind) :: btvKindList, TvarMap.insert(tvarEnv, tvar, btvTy))
            end
        (* Below, the use of foldl is essential.
            btvId must be generated in the order of kindedTvarList *)
        val (btvKindListRev, tvarEnv) = foldl genBtv (nil, tvarEnv) kindedTvarList
        val newContext = {tvarEnv = tvarEnv, varEnv=varEnv, oprimEnv=oprimEnv}
        fun evalKind context kind : {tvarKind:T.tvarKind, dynKind: bool, reifyKind:bool, subkind:T.subkind}  =
            case kind of
              I.UNIV => {tvarKind = T.UNIV, dynKind = false, reifyKind=false, subkind = T.ANY}
            | I.REC tyFields => 
              {tvarKind = T.REC (RecordLabel.Map.map (evalIty newContext) tyFields), 
               dynKind = false,
               reifyKind = false,
               subkind = T.ANY}
            | I.JSON {dynKind} => {tvarKind = T.UNIV, dynKind = dynKind, reifyKind=false, subkind = T.JSON}
            | I.REIFY => {tvarKind = T.UNIV, dynKind = false, reifyKind=true, subkind = T.ANY}
            | I.BOXED => {tvarKind = T.BOXED, dynKind = false, reifyKind=false, subkind = T.ANY}
            | I.UNBOXED => {tvarKind = T.UNIV, dynKind = false, reifyKind=false, subkind = T.UNBOXED}
        val btvEnv =
            foldl
            (fn ((btvId, eq, kind), btvEnv) =>
                let
                  val {tvarKind, dynKind, reifyKind, subkind} = evalKind newContext kind
                in
                  BoundTypeVarID.Map.insert
                    (btvEnv,
                     btvId,
                     T.KIND {eqKind=eq, dynKind=dynKind, reifyKind=reifyKind, subkind = subkind, tvarKind=tvarKind})
                end
            )
            BoundTypeVarID.Map.empty
            btvKindListRev
      in
        (newContext, btvEnv)
      end
end
end
