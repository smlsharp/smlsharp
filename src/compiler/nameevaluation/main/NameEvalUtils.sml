(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure NameEvalUtils =
struct
val _ = "initializing NameEvalUtils ..."
local
  structure I = IDCalc
  structure BT = BuiltinTypeNames
  structure PI = PatternCalcInterface
in  
  fun runtimeTyOfConspec conSpec = if SEnv.isEmpty (SEnv.filter (fn SOME _ => true | NONE => false) conSpec)
				   then BuiltinTypeNames.WORDty else BuiltinTypeNames.BOXEDty
  val print = fn s => if !Control.debugPrint then print s else ()
  fun printFixEnv fixEnv =
      if !Control.debugPrint then 
        SEnv.appi
          (fn (name, fixity) => 
              (print name;
               print " : ";
               print (Fixity.fixityToString fixity);
               print "\n")
          )
          fixEnv
      else ()
  fun printPath path =
      if !Control.debugPrint then 
        print (String.concatWith "." path)
      else ()
  fun printTvar tvar =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_tvar tvar))
      else ()
  fun printTvarId tvarId =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_tvarId tvarId))
      else ()
  fun printVarId varId =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_varId varId))
      else ()
  fun printVarInfo var =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_varInfo var))
      else ()
  fun printInterfaceId id = 
      if !Control.debugPrint then 
        print (Control.prettyPrint (InterfaceID.format_id id))
      else ()
  fun printTy ty =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_ty ty))
      else ()
  fun printBuiltinTy ty =
      if !Control.debugPrint then 
        print (Control.prettyPrint (BT.format_bty ty))
      else ()
  fun printPITy ty =
      if !Control.debugPrint then 
        print (Control.prettyPrint (PI.format_ty ty))
      else ()
  fun printTstr tstr =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_tstr tstr))
      else ()
  fun printTyE tyE =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_tyE tyE))
      else ()
  fun printConSpec conSpec =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_conSpec conSpec))
      else ()
  fun printTfun tfun =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_tfun tfun))
      else ()
  fun printTfunkind tfunkind =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_tfunkind tfunkind))
      else ()
  fun printIdstatus idstatus =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_idstatus idstatus) ^ "\n")
      else ()
  fun printTypId typId =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_typId typId))
      else ()
  fun printConId conId =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_conId conId))
      else ()
  fun printExnId exnId =
      if !Control.debugPrint then 
        print (Control.prettyPrint (I.format_exnId exnId))
      else ()
  fun printPrimitive primitive =
      if !Control.debugPrint then 
        print (Control.prettyPrint (BuiltinPrimitive.format_primitive primitive))
      else ()
  fun printLiftedTys liftedTys =
      if !Control.debugPrint then 
        (
         print "{";
         TvarSet.app
           (fn tvar => (printTvar tvar; print ","))
           liftedTys;
         print "}"
        )
      else ()
  fun printTypInfo {id,path} =
      if !Control.debugPrint then 
        (printPath path; print "("; printTypId id; print ")")
      else ()

  fun printTySubst tySubst =
      if !Control.debugPrint then 
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
      else ()
  fun printTypidSet typidSet =
      if !Control.debugPrint then 
        (
         print "{typidSet\n";
         TypID.Set.app
           (fn i => (printTypId i; print "\n,"))
           typidSet;
         print "}\n"
        )
      else ()
  fun printSubst {tvarS, exnIdS, conIdS} =
      if !Control.debugPrint then 
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
      else ()
  fun printTfvSubst tfvSubst =
      if !Control.debugPrint then 
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
      else ()
           
  fun printEnv env =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_env env) ^ "\n")
      else ()
  fun printStrEntry strEntry =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_strEntry strEntry) ^ "\n")
      else ()
  fun printTopEnv env =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_topEnv env) ^ "\n")
      else ()
  fun printFunE funE =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_funE funE) ^ "\n")
      else ()
  fun printFunEEntry funEEntry =
      if !Control.debugPrint then 
        print (Control.prettyPrint (NameEvalEnv.format_funEEntry funEEntry) ^ "\n")
      else ()
  fun printPat icpat =
      if !Control.debugPrint then 
        print (Control.prettyPrint (IDCalc.format_icpat icpat) ^ "\n")
      else ()
  fun printVar var =
      if !Control.debugPrint then 
        print (Control.prettyPrint (IDCalc.format_varInfo var) ^ "\n")
      else ()
  fun printExp exp =
      if !Control.debugPrint then 
        print (Control.prettyPrint (IDCalc.format_icexp exp) ^ "\n")
      else ()
  fun printPat pat =
      if !Control.debugPrint then 
        print (Control.prettyPrint (IDCalc.format_icpat pat) ^ "\n")
      else ()
  fun printDecl dec =
      if !Control.debugPrint then 
        print (Control.prettyPrint (IDCalc.format_icdecl dec) ^ "\n")
      else ()
  fun printPlstrDecl dec =
      if !Control.debugPrint then 
        print (Control.prettyPrint (PatternCalc.format_plstrdec dec) ^ "\n")
      else ()
  fun printPlstrexp strexp =
      if !Control.debugPrint then 
        print (Control.prettyPrint (PatternCalc.format_plstrexp strexp) ^ "\n")
      else ()
  fun printPlsigexp sigexp =
      if !Control.debugPrint then 
        print (Control.prettyPrint (PatternCalc.format_plsigexp sigexp) ^ "\n")
      else ()
  fun printPitopdec dec =
      if !Control.debugPrint then 
        print
          (Control.prettyPrint
             (PatternCalcInterface.format_pitopdec dec) ^ "\n")
      else ()
  fun printCompileUnit compileUnit =
      if !Control.debugPrint then 
        print
          (Control.prettyPrint
             (PatternCalcInterface.format_compileUnit compileUnit) ^ "\n")
      else ()

  fun printPltopdec dec =
      if !Control.debugPrint then 
        print
          (Control.prettyPrint
             (PatternCalc.format_pltopdec dec) ^ "\n")
      else ()
  fun printPidec dec =
      if !Control.debugPrint then 
        print
          (Control.prettyPrint
             (PatternCalcInterface.format_pidec dec) ^ "\n")
      else ()
  fun printCastEnv {tvarEnv, tfunEnv, conIdEnv} =
      if !Control.debugPrint then 
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
      else ()
      
  fun printReverseMap {ToTy, LiftDown} =
      if !Control.debugPrint then 
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
      else ()
  fun printCastMap castMap =
      if !Control.debugPrint then 
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
      else ()
  fun printTfv tfv =
      if !Control.debugPrint then 
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
      else ()
  fun printTfvList tfvList =
      if !Control.debugPrint then 
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
      else ()

  fun printTfvMap tfvMap =
      if !Control.debugPrint then 
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
      else ()

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
