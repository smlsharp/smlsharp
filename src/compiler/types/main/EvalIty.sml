(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure EvalIty =
struct
local
  structure I = IDCalc
  structure T = Types
  fun bug s = Control.Bug ("EvalITy: " ^ s)
  val debugPrint = fn s => if !Control.debugPrint then print s else ()
  fun printTy ty = debugPrint (Control.prettyPrint (I.format_ty ty))
  fun printTfun tfun =
      debugPrint (Control.prettyPrint (I.format_tfun tfun))
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
  exception EVALTFUN of {iseq:bool, formals:I.formals, realizerTy:I.ty}
  fun evalKindedTvar
        ((tvar as {eq,...}, I.UNIV),
         (context as {tvarEnv, varEnv, oprimEnv}, btvEnv)) =
      let 
        val btvId = BoundTypeVarID.generate()
        val btvTy = T.BOUNDVARty btvId
        val tvarEnv = TvarMap.insert(tvarEnv, tvar, btvTy)
        val btvEnv = BoundTypeVarID.Map.insert
                       (btvEnv,btvId,{eqKind=eq,tvarKind=T.UNIV})
      in
        ({tvarEnv=tvarEnv, varEnv=varEnv, oprimEnv=oprimEnv},
         btvEnv)
      end
    | evalKindedTvar _ = raise bug "non univ kind"
  fun evalKindedTvarList context kindedTvarList =
      foldl evalKindedTvar (context, BoundTypeVarID.Map.empty) kindedTvarList
  fun evalDtyKind context path dtyKind = 
      case dtyKind of
        I.DTY => T.DTY
      | I.DTY_INTERFACE => T.DTY
      | I.FUNPARAM => T.DTY
      | I.OPAQUE {tfun, revealKey} =>
        let
          val opaqueRep = 
              T.TYCON (evalTfun context path tfun)
              handle
              EVALTFUN{iseq, formals, realizerTy} =>
              let
                val (context, btvEnv) =
                    evalKindedTvarList
                      context 
                      (map (fn tv => (tv, I.UNIV)) formals)
                val rty = evalIty context realizerTy
              in
                T.TFUNDEF {iseq=iseq,
                           arity=length formals,
                           polyTy=T.POLYty{boundtvars=btvEnv,body=rty}
                          }
              end
        in
          T.OPAQUE {opaqueRep=opaqueRep, revealKey=revealKey}
        end
      | I.BUILTIN builtinTy => T.BUILTIN builtinTy
  and evalTfun context path tfun = 
      case tfun of
        I.TFUN_DEF {iseq, formals, realizerTy} =>
        raise EVALTFUN {iseq=iseq, formals=formals, realizerTy=realizerTy}
      | I.TFUN_VAR tfunKindRef =>
        (case tfunKindRef of
           ref(I.TFUN_DTY{id,iseq,formals,runtimeTy,originalPath,
                           conSpec,liftedTys,dtyKind}) =>
           {id = id,
            path = path,
            iseq = iseq,
	    runtimeTy = runtimeTy,
            arity = List.length formals,
            conSet =SEnv.map
                      (fn NONE => {hasArg=false} | SOME ity => {hasArg=true})
                      conSpec,
            extraArgs = map (evalIty context) (I.liftedTysToTy liftedTys),
            dtyKind = evalDtyKind context path dtyKind
           }
         | ref(I.TFV_SPEC {id, iseq, formals}) =>
           (debugPrint "****** evalTfun ******\n";
            printPath path;
            debugPrint "\n";
            debugPrint "tfun\n";
            printTfun tfun;
            debugPrint "\n";
            raise bug "TFV_SPEC in evalTfun"
           )
         | ref(I.TFV_DTY {id,iseq,formals,conSpec,liftedTys}) =>
           (debugPrint "****** evalTfun ******\n";
            printPath path;
            debugPrint "\n";
            debugPrint "tfun\n";
            printTfun tfun;
            debugPrint "\n";
            raise bug "TFV_DTY in evalTfun"
           )
         | ref(I.REALIZED{tfun,...}) => evalTfun context path tfun
         | ref(I.INSTANTIATED{tfun,...}) => evalTfun context path tfun
         | ref(I.FUN_DTY{tfun,...}) => evalTfun context path tfun
        )
  and evalIty context ity =
       case ity of
         I.TYWILD => T.ERRORty
       | I.TYERROR => T.ERRORty
       | I.TYVAR tvar =>
         (case TvarMap.find(#tvarEnv context, tvar) of
            SOME ty => ty
          | NONE => 
            (debugPrint "evalIty tvar not found\n";
             printTy ity;
             raise bug ("free tvar:" ^(Control.prettyPrint(I.format_ty ity)))
            )
         )
       | I.TYRECORD tyMap => T.RECORDty (LabelEnv.map (evalIty context) tyMap)
       | I.TYCONSTRUCT {typ={path, tfun}, args} =>
         (let
            val args = map (evalIty context) args
            val tyCon = evalTfun context path tfun
                handle e => raise e
          in
            T.CONSTRUCTty{tyCon=tyCon, args=args}
          end
          handle EVALTFUN {iseq, formals, realizerTy} =>
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
         )
       | I.TYFUNM (tyList,ty2) =>
         T.FUNMty (map (evalIty context) tyList, evalIty context ty2)
       | I.TYPOLY (kindedTvarList, ty) =>
         let
           val (context, btvEnv) = evalKindedTvarList context kindedTvarList
           val ty = evalIty context ty
         in
           T.POLYty {boundtvars = btvEnv, body = ty}
         end
       | I.INFERREDTY ty => ty
end
end
