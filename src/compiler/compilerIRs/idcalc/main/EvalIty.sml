(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure EvalIty =
struct
local
  structure I = IDCalc
  structure T = Types
  structure U = Unify
  (* structure DK = DynamicKind *)

  structure TB = TypesBasics
  fun bug s = Bug.Bug ("EvalITy: " ^ s)
  val debugPrint = fn s => if !Bug.debugPrint then print s else ()
  fun printTy ty = debugPrint (Bug.prettyPrint (I.format_ty ty))
  fun printTfun tfun =
      debugPrint (Bug.prettyPrint (I.format_tfun tfun))
  fun printPath path =
      debugPrint (String.concatWith "." path)

  type freeTvarEnv = T.ty TvarID.Map.map ref
  val freeTvarEnv = ref TvarID.Map.empty : freeTvarEnv
in
  fun resetFreeTvarEnv () = freeTvarEnv := TvarID.Map.empty
  fun setFreeTvarEnv (id, ty1) = 
      let
        val _ = 
            case TvarID.Map.find(!freeTvarEnv, id) of
              SOME ty2  => U.unify [(ty1, ty2)]
            | NONE => ()
      in
        freeTvarEnv := TvarID.Map.insert(!freeTvarEnv, id, ty1)
      end
      
  type ityContext = {oprimEnv:I.ty OPrimMap.map,
                     tvarEnv:Types.ty TvarMap.map, 
                     varEnv:I.ty VarMap.map}
  val emptyContext : ityContext = 
      {
       oprimEnv=OPrimMap.empty,
       tvarEnv=TvarMap.empty,
       varEnv=VarMap.empty
      }
  exception EVALTFUN of {admitsEq:bool, formals:I.formals, realizerTy:I.ty, longsymbol:Symbol.longsymbol}

  fun evalDtyKind context dtyKind = 
      case dtyKind of
        I.DTY ty => T.DTY ty
      | I.DTY_INTERFACE ty => T.DTY ty
      | I.FUNPARAM ty => T.DTY ty
      | I.OPAQUE {tfun, revealKey} =>
        let
          val opaqueRep = 
              T.TYCON (evalTfun context tfun)
              handle
              EVALTFUN{admitsEq, formals, realizerTy, longsymbol} =>
              let
                val (context, btvEnv) =
                    evalKindedTvarList
                      context 
                      (map (fn tv => (tv, I.UNIV I.emptyProperties)) formals)
                val rty = evalIty context realizerTy
              in
                T.TFUNDEF {admitsEq=admitsEq,
                           arity=length formals,
                           polyTy=T.POLYty{boundtvars=btvEnv,constraints = nil, body=rty}
                           }
              end
        in
          T.OPAQUE {opaqueRep=opaqueRep, revealKey=revealKey}
        end
      | I.INTERFACE tfun =>
        let
          val interfaceRep = 
              T.TYCON (evalTfun context tfun)
              handle
              EVALTFUN{admitsEq, formals, realizerTy, longsymbol} =>
              let
                val (context, btvEnv) =
                    evalKindedTvarList
                      context 
                      (map (fn tv => (tv, I.UNIV I.emptyProperties)) formals)
                val rty = evalIty context realizerTy
              in
                T.TFUNDEF {admitsEq=admitsEq,
                           arity=length formals,
                           polyTy=T.POLYty{boundtvars=btvEnv,constraints = nil, body=rty}
                           }
              end
        in
          T.INTERFACE interfaceRep
        end
(*
  and evalTfun context path tfun = 
*)
  and evalTfun context tfun = 
      case tfun of
        I.TFUN_DEF {admitsEq, formals, realizerTy, longsymbol} =>
        raise EVALTFUN {admitsEq=admitsEq, formals=formals, realizerTy=realizerTy, longsymbol=longsymbol}
      | I.TFUN_VAR tfunKindRef =>
        (case tfunKindRef of
           ref(I.TFUN_DTY{id,admitsEq,formals, longsymbol, conIDSet,
                           conSpec,liftedTys,dtyKind}) =>
           let
             val (argTyContext, btvEnv) =
                 evalKindedTvarList
                   context
                   (map (fn ty => (ty, I.UNIV I.emptyProperties)) formals)
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
               admitsEq = admitsEq,
               arity = List.length formals,
               conIDSet = conIDSet,
               conSet = SymbolEnv.map (Option.map argTyFn) conSpec,
               extraArgs = map (evalIty context) (I.liftedTysToTy liftedTys),
               dtyKind = evalDtyKind context dtyKind
              }
           end
         | ref(I.TFV_SPEC {longsymbol, id, admitsEq, formals}) =>
           (debugPrint "****** evalTfun ******\n";
            debugPrint "tfun\n";
            printTfun tfun;
            debugPrint "\n";
            raise bug "TFV_SPEC in evalTfun"
           )
         | ref(I.TFV_DTY {longsymbol, id,admitsEq,formals,conSpec,liftedTys}) =>
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

  and evalFreeTvar context {symbol, id, isEq, tvarKind} =
      let
        val {tvarKind, properties} =
            case tvarKind of
              I.UNIV props => {tvarKind = T.UNIV, properties = props}
            | I.REC {recordKind=tyFields, properties} => 
              {tvarKind = T.REC (RecordLabel.Map.map (evalIty context) tyFields), 
               properties = properties}
        val properties = 
            if isEq
            then T.addProperties I.EQ properties
            else properties
        val kind = {kind = T.KIND {tvarKind = tvarKind, 
                                   properties = properties, 
                                   dynamicKind = NONE},
                    utvarOpt = NONE : T.utvar option}
        val newTy = T.newty kind
        val _ = setFreeTvarEnv (id, newTy)
      in
        newTy
      end

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
             debugPrint "\n";
             raise bug ("free tvar:" ^ (Bug.prettyPrint(I.format_ty ity)))
            )
         )
       | I.TYFREE_TYVAR freeTvar => evalFreeTvar context freeTvar
       | I.TYRECORD {ifFlex, fields=tyMap} => 
         let
           val fields = RecordLabel.Map.map (evalIty context) tyMap
         in
           if ifFlex then T.newtyWithRecordKind fields
           else T.RECORDty fields
         end
       | I.TYCONSTRUCT {tfun, args} => 
         (let
            val args = map (evalIty context) args
            val tyCon = evalTfun context tfun
                handle e => raise e
          in
            T.CONSTRUCTty{tyCon=tyCon, args=args}
          end
          handle 
          EVALTFUN {admitsEq, formals, realizerTy, longsymbol} =>
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
          else raise bug "TYCONSTRUCT ARITY"
         )
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
           if BoundTypeVarID.Map.isEmpty btvs
           then ty
           else T.POLYty {boundtvars = btvs, constraints = nil, body = ty}
         end
       | I.INFERREDTY ty => ty
  and evalKindedTvarList (context as {tvarEnv, varEnv, oprimEnv}) kindedTvarList =
      let
        fun genBtv ((tvar as {isEq, ...}, kind), (btvKindList, tvarEnv)) =
            let
              val btvId = BoundTypeVarID.generate()
              val btvTy = T.BOUNDVARty btvId
            in
              ((btvId, isEq, kind) :: btvKindList, TvarMap.insert(tvarEnv, tvar, btvTy))
            end
        (* Below, the use of foldl is essential.
            btvId must be generated in the order of kindedTvarList *)
        val (btvKindListRev, tvarEnv) = foldl genBtv (nil, tvarEnv) kindedTvarList
        val newContext = {tvarEnv = tvarEnv, varEnv=varEnv, oprimEnv=oprimEnv}
        fun evalKind context kind : {tvarKind:T.tvarKind, properties:T.kindPropertyList}  =
            case kind of
              I.UNIV props => {tvarKind = T.UNIV, properties = props}
            | I.REC {recordKind=tyFields, properties} => 
              {tvarKind = T.REC (RecordLabel.Map.map (evalIty newContext) tyFields), 
               properties = properties}
        val btvEnv =
            foldl
            (fn ((btvId, isEq, kind), btvEnv) =>
                let
                  val {tvarKind, properties} = evalKind newContext kind
                  val properties = 
                      if isEq
                      then T.addProperties I.EQ properties
                      else properties
                in
                  BoundTypeVarID.Map.insert
                    (btvEnv,
                     btvId,
                     T.KIND {properties = properties,
                             tvarKind = tvarKind,
                             dynamicKind = NONE})
                end
            )
            BoundTypeVarID.Map.empty
            btvKindListRev
      in
        (newContext, btvEnv)
      end
end
end
