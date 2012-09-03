(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure NameEvalUtils =
struct
val _ = "initializing NameEvalUtils ..."
local
  structure I = IDCalc
  structure BT = BuiltinType
  structure PI = PatternCalcInterface
in  
  fun runtimeTyOfConspec conSpec = if SEnv.isEmpty (SEnv.filter (fn SOME _ => true | NONE => false) conSpec)
				   then BuiltinType.WORDty else BuiltinType.BOXEDty
  val print = fn s => if !Control.debugPrint then print s else ()
  fun printFixEnv fixEnv =
      SEnv.appi
      (fn (name, fixity) => 
          (print name;
           print " : ";
           print (Fixity.fixityToString fixity);
           print "\n")
      )
      fixEnv
  fun printPath path =
      print (String.concatWith "." path)
  fun printTvar tvar =
      print (Control.prettyPrint (I.format_tvar tvar))
  fun printTvarId tvarId =
      print (Control.prettyPrint (I.format_tvarId tvarId))
  fun printVarId varId =
      print (Control.prettyPrint (I.format_varId varId))
  fun printVarInfo var =
      print (Control.prettyPrint (I.format_varInfo var))
  fun printInterfaceId id = 
      print (Control.prettyPrint (InterfaceID.format_id id))
  fun printTy ty =
      print (Control.prettyPrint (I.format_ty ty))
  fun printBuiltinTy ty =
      print (Control.prettyPrint (BT.format_ty ty))
  fun printPITy ty =
      print (Control.prettyPrint (PI.format_ty ty))
  fun printTstr tstr =
      print (Control.prettyPrint (NameEvalEnv.format_tstr tstr))
  fun printTyE tyE =
      print (Control.prettyPrint (NameEvalEnv.format_tyE tyE))
  fun printConSpec conSpec =
      print (Control.prettyPrint (I.format_conSpec conSpec))
  fun printTfun tfun =
      print (Control.prettyPrint (I.format_tfun tfun))
  fun printTfunkind tfunkind =
      print (Control.prettyPrint (I.format_tfunkind tfunkind))
  fun printIdstatus idstatus =
      print (Control.prettyPrint (I.format_idstatus idstatus) ^ "\n")
  fun printTypId typId =
      print (Control.prettyPrint (I.format_typId typId))
  fun printConId conId =
      print (Control.prettyPrint (I.format_conId conId))
  fun printExnId exnId =
      print (Control.prettyPrint (I.format_exnId exnId))
  fun printPrimitive primitive =
      print (Control.prettyPrint (BuiltinPrimitive.format_primitive primitive))
  fun printLiftedTys liftedTys =
      (
       print "{";
       TvarSet.app
         (fn tvar => (printTvar tvar; print ","))
         liftedTys;
       print "}"
      )
  fun printTypInfo {id,path} =
      (printPath path; print "("; printTypId id; print ")")

  fun printTySubst tySubst =
      (
       print "{";
       TypID.Map.appi
         (fn (i,(typInfo, liftedTys)) =>
             (printTypId i; print "=> (";
              printTypInfo typInfo;
              print ",";
              printLiftedTys liftedTys;
              print ")";
              print "\n"))
         tySubst;
       print "}\n"
      )
  fun printTypidSet typidSet =
      (
       print "{typidSet\n";
       TypID.Set.app
         (fn i => (printTypId i; print "\n,"))
         typidSet;
       print "}\n"
      )
  fun printSubst {tvarS, tfvS, exnIdS, conIdS} =
      let
        val _ = print "tvarS\n"
        val _ =
            (print "[\n";
             TvarMap.appi
               (fn (tvar, ty) =>
                   (printTvar tvar;
                    print "=>";
                    printTy ty;
                    print "\n")
               )
               tvarS;
             print "\n]\n"
            )
        val _ = print "tfvS\n"
        val _ =
            (print "[\n";
             TfvMap.appi
               (fn (ref tfunkind1, ref tfunkind2) =>
                   (printTfunkind tfunkind1;
                    print "=>";
                    printTfunkind tfunkind2;
                    print "\n")
               )
               tfvS;
             print "\n]\n"
            )
        val _ = print "conIdS\n"
        val _ =
            (print "[\n";
             ConID.Map.appi
               (fn (id, idstatus) =>
                   (printConId id;
                    print "=>";
                    printIdstatus idstatus;
                    print "\n")
               )
               conIdS;
             print "\n]\n"
            )
        val _ = print "exnIdS\n"
        val _ =
            (print "[\n";
             ExnID.Map.appi
               (fn (id, id') =>
                   (printExnId id;
                    print "=>";
                    printExnId id';
                    print "\n")
               )
               exnIdS;
             print "\n]\n"
            )
      in
        ()
      end
  fun printTfvSubst tfvSubst =
      (print "[\n";
       TfvMap.appi
         (fn (ref tfunkind1, ref tfunkind2) =>
             (printTfunkind tfunkind1;
              print "=>";
              printTfunkind tfunkind2;
              print "\n")
         )
         tfvSubst;
       print "\n]\n"
      )
      handle exn => raise exn
  fun printEnv env =
      print (Control.prettyPrint (NameEvalEnv.format_env env) ^ "\n")
  fun printStrEntry strEntry =
      print (Control.prettyPrint (NameEvalEnv.format_strEntry strEntry) ^ "\n")
  fun printTopEnv env =
      print (Control.prettyPrint (NameEvalEnv.format_topEnv env) ^ "\n")
  fun printFunE funE =
      print (Control.prettyPrint (NameEvalEnv.format_funE funE) ^ "\n")
  fun printFunEEntry funEEntry =
      print (Control.prettyPrint (NameEvalEnv.format_funEEntry funEEntry) ^ "\n")
  fun printPat icpat =
      print (Control.prettyPrint (IDCalc.format_icpat icpat) ^ "\n")
  fun printVar var =
      print (Control.prettyPrint (IDCalc.format_varInfo var) ^ "\n")
  fun printExp exp =
      print (Control.prettyPrint (IDCalc.format_icexp exp) ^ "\n")
  fun printPat pat =
      print (Control.prettyPrint (IDCalc.format_icpat pat) ^ "\n")
  fun printDecl dec =
      print (Control.prettyPrint (IDCalc.format_icdecl dec) ^ "\n")
  fun printPlstrDecl dec =
      print (Control.prettyPrint (PatternCalc.format_plstrdec dec) ^ "\n")
  fun printPlstrexp strexp =
      print (Control.prettyPrint (PatternCalc.format_plstrexp strexp) ^ "\n")
  fun printPlsigexp sigexp =
      print (Control.prettyPrint (PatternCalc.format_plsigexp sigexp) ^ "\n")
  fun printPitopdec dec =
      print
        (Control.prettyPrint
           (PatternCalcInterface.format_pitopdec dec) ^ "\n")
  fun printCompileUnit compileUnit =
      print
        (Control.prettyPrint
           (PatternCalcInterface.format_compileUnit compileUnit) ^ "\n")
  fun printPltopdec dec =
      print
        (Control.prettyPrint
           (PatternCalc.format_pltopdec dec) ^ "\n")
  fun printPidec dec =
      print
        (Control.prettyPrint
           (PatternCalcInterface.format_pidec dec) ^ "\n")
  fun printCastEnv {tvarEnv, tfunEnv, conIdEnv} =
      (print "tvarEnv :\n";
       TvarMap.appi
         (fn (tvar, ty) =>
             (printTvar tvar;
              print "=>";
              printTy ty;
              print "\n")
         )
         tvarEnv;
       print "tfunEnv :\n";
       TypID.Map.app
         (fn (from, inst, to) =>
             (printTfun from;
              print "with (";
              TvarMap.appi
                (fn (tvar, ty) =>
                    (print " ";
                     printTvar tvar;
                     print ":";
                     printTy ty)
                );
              print ")";
              print "=>";
              printTfun to;
              print "\n")
         )
         tfunEnv;
       print "conIdEnv : \n"
      )
      
  fun printReverseMap {ToTy, LiftDown} =
      (TvarMap.appi
         (fn (tvar, (typInfo, liftedTys)) =>
             (printTvar tvar;
              print "=>";
              printTypInfo typInfo;
              print "with";
              printLiftedTys liftedTys;
              print "\n")
         )
         ToTy;
       TypID.Map.appi
         (fn (id, {arity, path, liftedTys}) =>
             (printPath path;
              print "(";
              printTypId id;
              print ")";
              print "(";
              print (Int.toString arity);
              print ")";
              print " down with ";
              printLiftedTys liftedTys;
              print "\n")
         )
         LiftDown)
  fun printCastMap castMap =
      TypID.Map.appi
        (fn (id, {newId, arity, tyname, liftedTys}) =>
            (print "cast ";
             print tyname;
             print "(";
             printTypId id;
             print ") with ";
             printLiftedTys liftedTys;
             print " down to ";
             printTypId newId;
             print "\n")
        )
        castMap
  fun printTfv tfv =
      case !tfv of
        I.TFV_DTY{id, conSpec,...} =>
        (
         print "TFV_DTY:\n";
         printTypId id;
         print "\n";
         printConSpec conSpec;
         print "\n"
        )
      | I.TFUN_DTY{id, conSpec,...} =>
        (print "TFUN_DTY:\n";
         printTypId id;
         print "\n";
         printConSpec conSpec;
         print "\n"
        )
      | _ => ()
  fun printTfvList tfvList =
      (print "[\n";
       map
         (fn (tfv,path) =>
             (printPath path;
              print ":";
              printTfv tfv;
              print "\n")
         )
         tfvList;
       print "]\n"
      )

  fun printTfvMap tfvMap =
      (TfvMap.appi
         (fn (tfv1,path) =>
             (printTfun (I.TFUN_VAR tfv1);
              print "=>";
              printPath path;
              print "\n"
             )
         )
         tfvMap
      )
      handle exn => raise exn

  fun evalList {eval: 'elm -> 'env * 'newElm,
                emptyEnv:'env,
                unionEnv:'env*'env -> 'env}
               (list:'elm list) : 'env * 'newElm list =
      let
        val (env, listRev) =
            foldl
              (fn (elem, (env,listRev)) =>
                  let
                    val (newEnv, elem) = eval elem
                  in
                    (unionEnv(env, newEnv), elem::listRev)
                  end
              )
              (emptyEnv, nil)
              list
      in
        (env, List.rev listRev)
      end

  fun evalTailList
        {eval:'env -> 'elm -> 'env * 'newElm, env:'env} (list:'elm list)
      : 'env * 'newElm list =
      let
        val (env, listRev) =
            foldl
              (fn (elem, (env, listRev)) =>
                  let
                    val (env, elem) = eval env elem
                  in
                    (env, elem::listRev)
                  end
              )
              (env, nil)
              list
      in
        (env, List.rev listRev)
      end

  fun SEnvToSSet senv =
      SEnv.foldli
      (fn (name,_,set) => SSet.add(set, name))
      SSet.empty
      senv

end
end
