structure EvalIty =
struct
local
  structure IT = IDTypes 
  structure T = Types
  fun bug s = Control.Bug ("EvalITy: " ^ s)
  val print = fn s => if !Control.debugPrint then print s else ()
  fun printTy ty = print (Control.prettyPrint (IT.format_ty ty))
  fun printTfun tfun =
      print (Control.prettyPrint (IT.format_tfun tfun))
  fun printPath path =
      print (String.concatWith "." path)

in
  exception EVALTFUN of {iseq:bool, formals:IT.formals, realizerTy:IT.ty}
  fun evalKindedTvar
        ((tvar as {eq,...}, IT.UNIV),
         (context as {tvarEnv, varEnv, oprimEnv}, btvEnv)) =
      let 
        val btvId = BoundTypeVarID.generate()
        val btvTy = T.BOUNDVARty btvId
        val tvarEnv = TvarMap.insert(tvarEnv, tvar, btvTy)
        val btvEnv = BoundTypeVarID.Map.insert
                       (btvEnv,btvId,{eqKind=eq,tvarKind=T.UNIV})
      in
        ({tvarEnv=tvarEnv,
          varEnv=varEnv,
          oprimEnv=oprimEnv},
         btvEnv)
      end
    | evalKindedTvar _ = raise bug "non univ kind"
  fun evalKindedTvarList context kindedTvarList =
      foldl evalKindedTvar (context, BoundTypeVarID.Map.empty) kindedTvarList
  fun evalDtyKind context path dtyKind = 
      case dtyKind of
        IT.DTY => T.DTY
      | IT.FUNPARAM => T.DTY
      | IT.OPAQUE {tfun, revealKey} =>
        let
          val opaqueRep = 
              T.TYCON (evalTfun context path tfun)
              handle
              EVALTFUN{iseq, formals, realizerTy} =>
              let
                val (context, btvEnv) =
                    evalKindedTvarList
                      context 
                      (map (fn tv => (tv, IT.UNIV)) formals)
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
      | IT.BUILTIN builtinTy => T.BUILTIN builtinTy
  and evalTfun context path tfun = 
      case tfun of
        IT.TFUN_DEF {iseq, formals, realizerTy} =>
        raise EVALTFUN {iseq=iseq, formals=formals, realizerTy=realizerTy}
      | IT.TFUN_VAR tfunKindRef =>
        (case tfunKindRef of
           ref(IT.TFUN_DTY{id,iseq,formals,conSpec,liftedTys,dtyKind}) =>
           {id = id,
            path = path,
            iseq = iseq,
            arity = List.length formals,
            conSet =SEnv.map
                   (fn NONE => {hasArg=false} | SOME _ => {hasArg=true})
                   conSpec,
            extraArgs = map (evalIty context) (IT.liftedTysToTy liftedTys),
            dtyKind = evalDtyKind context path dtyKind
           }
         | ref(IT.TFV_SPEC {id, iseq, formals}) =>
           (print "****** evalTfun ******\n";
            printPath path;
            print "\n";
            print "tfun\n";
            printTfun tfun;
            print "\n";
            raise bug "TFV_SPEC in evalTfun"
           )
         | ref(IT.TFV_DTY {id,iseq,formals,conSpec,liftedTys}) =>
           (print "****** evalTfun ******\n";
            printPath path;
            print "\n";
            print "tfun\n";
            printTfun tfun;
            print "\n";
            raise bug "TFV_DTY in evalTfun"
           )
         | ref(IT.REALIZED{tfun,...}) => evalTfun context path tfun
         | ref(IT.INSTANTIATED{tfun,...}) => evalTfun context path tfun
         | ref(IT.FUN_TOTVAR {tfunkind, tvar}) =>
           (print "****** evalTfun ******\n";
            printPath path;
            print "\n";
            print "tfun\n";
            printTfun tfun;
            print "\n";
            raise bug "TFV_SPEC in evalTfun"
           )
         | ref(IT.FUN_DTY{tfun,...}) => evalTfun context path tfun
        )
  and evalIty context ity =
       case ity of
         IT.TYWILD => T.ERRORty
       | IT.TYERROR => T.ERRORty
       | IT.TYVAR tvar =>
         (case TvarMap.find(#tvarEnv context, tvar) of
            SOME ty => ty
          | NONE => 
            (print "evalIty tvar not found\n";
             printTy ity;
             raise bug ("free tvar:" ^(Control.prettyPrint(IT.format_ty ity)))
            )
         )
       | IT.TYRECORD tyMap =>
         T.RECORDty (SEnv.map (evalIty context) tyMap)
       | IT.TYCONSTRUCT {typ={path, tfun}, args=nil} =>
         (case tfun of
            IT.TFUN_VAR(ref(IT.FUN_TOTVAR {tfunkind, tvar})) =>
            (case TvarMap.find(#tvarEnv context, tvar) of
               SOME ty => ty
             | NONE => 
               (print "evalIty tvar not found\n";
                printTy ity;
                raise bug ("free tvar: " ^
                           (Control.prettyPrint (IT.format_ty ity)))
               )
            )
          | _ =>
            let
              val tyCon = evalTfun context path tfun
                          handle e => raise e
            in
              T.CONSTRUCTty{tyCon=tyCon, args=nil}
            end
            handle EVALTFUN {iseq, formals, realizerTy} =>
                   case formals of nil => evalIty context realizerTy
                                 | _ => raise bug "TYCONSTRUCT ARITY"
            
         )
       | IT.TYCONSTRUCT {typ={path, tfun}, args} =>
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
       | IT.TYFUNM (tyList,ty2) =>
         T.FUNMty (map (evalIty context) tyList, evalIty context ty2)
       | IT.TYPOLY (kindedTvarList, ty) =>
         let
           val (context, btvEnv) = evalKindedTvarList context kindedTvarList
           val ty = evalIty context ty
         in
           T.POLYty {boundtvars = btvEnv, body = ty}
         end
end
end
