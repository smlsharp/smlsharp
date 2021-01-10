(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure NameEvalUtils =
struct
local
  structure A = AbsynTy
  structure I = IDCalc
  (* structure BT = RuntimeTypes *)
  (* structure PI = PatternCalcInterface *)
  structure V = NameEvalEnv
in  
  val print = fn s => if !Bug.debugPrint then print s else ()
  fun printSymbol symbol = print (Bug.prettyPrint (Symbol.format_symbol symbol))
  fun printLongsymbol longsymbol = print (Bug.prettyPrint (Symbol.format_longsymbol longsymbol))
(*
  fun printFixEnv fixEnv =
      if !Bug.debugPrint then 
        SEnv.appi
          (fn (name, fixity) => 
              (print name;
               print " : ";
               print (Fixity.fixityToString fixity);
               print "\n")
          )
          fixEnv
      else ()
*)
  fun printLoc loc = 
      if !Bug.debugPrint then 
        print (Loc.locToString loc)
      else ()
      
  fun printPath path =
      if !Bug.debugPrint then 
        print (String.concatWith "." path)
      else ()
  fun printTvar tvar =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_tvar tvar))
      else ()
  fun printTvarId tvarId =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_tvarId tvarId))
      else ()
  fun printVarId varId =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_varId varId))
      else ()
  fun printVarInfo var =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.formatWithType_varInfo var))
      else ()
  fun printInterfaceId id = 
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (InterfaceID.format_id id))
      else ()
  fun printTy ty =
      if !Bug.debugPrint then 
        if !Control.printWithType then
          print (Bug.prettyPrint (I.formatWithType_ty ty))
        else
          print (Bug.prettyPrint (I.format_ty ty))
      else ()
  fun printProp prop =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_property prop))
      else ()
  fun printPITy ty =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (AbsynTyFormatter.format_ty ty))
      else ()
  fun printTstr tstr =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_tstr tstr))
      else ()
  fun tstrToString tstr =
      if !Control.printWithType then
          Bug.prettyPrint (V.format_tstr tstr)
      else 
          Bug.prettyPrint (V.format_tstr tstr)
  fun printTyE tyE =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_tyE tyE))
      else ()
  fun printConSpec conSpec =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_conSpec conSpec))
      else ()
  fun printTfun tfun =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.formatWithType_tfun tfun))
      else ()
  fun printTfunkind tfunkind =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.formatWithType_tfunkind tfunkind))
      else ()
  fun printIdstatus idstatus =
      if !Bug.debugPrint then 
        if !Control.printWithType then
          print (Bug.prettyPrint (I.formatWithType_idstatus idstatus) ^ "\n")
        else
          print (Bug.prettyPrint (I.format_idstatus idstatus) ^ "\n")
      else ()
  fun idstatusToString idstatus =
      if !Control.printWithType then
        Bug.prettyPrint (I.formatWithType_idstatus idstatus) 
      else 
        Bug.prettyPrint (I.format_idstatus idstatus)
  fun printTypId typId =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_typId typId))
      else ()
  fun printConId conId =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_conId conId))
      else ()
  fun printExnId exnId =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (I.format_exnId exnId))
      else ()
  fun printPrimitive primitive =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (BuiltinPrimitive.format_primitive primitive))
      else ()
  fun printLiftedTys liftedTys =
      if !Bug.debugPrint then 
        (
         print "{";
         TvarSet.app
           (fn tvar => (printTvar tvar; print ","))
           liftedTys;
         print "}"
        )
      else ()
  fun printTypInfo {id,path} =
      if !Bug.debugPrint then 
        (printPath path; print "("; printTypId id; print ")")
      else ()

  fun printTySubst tySubst =
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
        (
         print "{typidSet\n";
         TypID.Set.app
           (fn i => (printTypId i; print "\n,"))
           typidSet;
         print "}\n"
        )
      else ()
  fun printSubst {tvarS, exnIdS, conIdS} =
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_env env) ^ "\n")
      else ()
  fun printStrEntry strEntry =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_strEntry strEntry) ^ "\n")
      else ()
  fun printTopEnv env =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_topEnv env) ^ "\n")
      else ()
  fun printFunE funE =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_funE funE) ^ "\n")
      else ()
  fun printFunEEntry funEEntry =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (V.format_funEEntry funEEntry) ^ "\n")
      else ()

  fun printPat icpat =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (IDCalc.format_icpat icpat) ^ "\n")
      else ()
  fun printVar var =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (IDCalc.formatWithType_varInfo var) ^ "\n")
      else ()
  fun printExp exp =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (IDCalc.formatWithType_icexp exp) ^ "\n")
      else ()
  fun printPat pat =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (IDCalc.format_icpat pat) ^ "\n")
      else ()
  fun printDecl dec =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (IDCalc.format_icdecl dec) ^ "\n")
      else ()
  fun printPlstrDecl dec =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (PatternCalc.format_plstrdec dec) ^ "\n")
      else ()
  fun printPlstrexp strexp =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (PatternCalc.format_plstrexp strexp) ^ "\n")
      else ()
  fun printPlsigexp sigexp =
      if !Bug.debugPrint then 
        print (Bug.prettyPrint (PatternCalc.format_plsigexp sigexp) ^ "\n")
      else ()
  fun printPitopdec dec =
      if !Bug.debugPrint then 
        print
          (Bug.prettyPrint
             (PatternCalcInterface.format_pitopdec dec) ^ "\n")
      else ()
  fun printCompileUnit compileUnit =
      if !Bug.debugPrint then 
        print
          (Bug.prettyPrint
             (PatternCalcInterface.format_compile_unit compileUnit) ^ "\n")
      else ()
  fun printCompileUnitSpliced compileUnitSpliced =
      if !Bug.debugPrint then 
        print
          (Bug.prettyPrint
             (PatternCalcInterface.format_compile_unit_spliced 
                compileUnitSpliced) ^ "\n")
      else ()

  fun printPltopdec dec =
      if !Bug.debugPrint then 
        print
          (Bug.prettyPrint
             (PatternCalc.format_pltopdec dec) ^ "\n")
      else ()
  fun printPidec dec =
      if !Bug.debugPrint then 
        print
          (Bug.prettyPrint
             (PatternCalcInterface.format_pidec dec) ^ "\n")
      else ()
  fun printPiinterfacedec dec =
      if !Bug.debugPrint then 
        print
          (Bug.prettyPrint
             (PatternCalcInterface.format_interfaceDec dec) ^ "\n")
      else ()
  fun printCastEnv {tvarEnv, tfunEnv, conIdEnv} =
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
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
      if !Bug.debugPrint then 
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

  fun SymbolEnvToSymbolSet senv =
      SymbolEnv.foldli
      (fn (name,_,set) => SymbolSet.add(set, name))
      SymbolSet.empty
      senv

  fun staticTyName (typId, envList) =
      let
        exception FoundInEnv of Symbol.symbol list option
        fun sortBySymbol env =
            ListSorter.sort
              (fn ((x, _), (y, _)) =>
                  let
                    val x = Symbol.symbolToString x
                    val y = Symbol.symbolToString y
                  in
                    case Int.compare (size x, size y) of
                      EQUAL => String.compare (x, y)
                    | order => order
                  end)
            (SymbolEnv.listItemsi env)
        fun tstrId (V.TSTR {tfun,...}) = 
            (I.tfunId tfun 
             handle e => (print "staticTyName1\n"; raise e))
          | tstrId (V.TSTR_DTY{tfun,...}) = 
            (I.tfunId tfun 
             handle e => (print "staticTyName2\n"; raise e))
        fun findIdTyE (tyE, typId) =
            List.find
              (fn (symbol, tstr) =>
                  TypID.eq (tstrId tstr, typId) handle Bug.Bug _ => false)
              (sortBySymbol tyE)
        fun findIdEnv (symbolList, V.ENV{tyE, strE=V.STR strentryMap, ...}, typId) =
            case findIdTyE (tyE, typId) of
              SOME (symbol, _) =>
              raise FoundInEnv (SOME (symbolList @ [symbol]))
            | NONE => 
              app
                (fn (symbol, {env, strKind, loc, definedSymbol}) =>
                    findIdEnv (symbolList @ [symbol], env, typId))
                (sortBySymbol strentryMap)
        fun findIdEnvList (envList, typId) =
            List.app (fn env => (findIdEnv (nil, env, typId))) envList
      in
        (findIdEnvList (envList, typId); NONE)
        handle FoundInEnv res => res
      end
            
  fun staticTfunName (envList, tfun) =
      let
        val typId = 
            (I.tfunId tfun 
             handle e => (print "staticTfunName1\n"; raise e))

        val staticLongsymbolOpt = staticTyName (typId, envList)
      in
        case staticLongsymbolOpt of
          SOME longsymbol => Symbol.longsymbolToString longsymbol
        | NONE => "?." ^ Symbol.longsymbolToString (I.tfunLongsymbol tfun)
          handle Bug.Bug _ => "?"
      end
          handle Bug.Bug _ => "??"

  fun staticTyConName (envList, {id, longsymbol,...}) =
      let
        val staticLongsymbolOpt = staticTyName (id, envList)
      in
        case staticLongsymbolOpt of
          SOME longsymbol => Symbol.longsymbolToString longsymbol
        | NONE => "?." ^ Symbol.longsymbolToString longsymbol
          handle Bug.Bug _ => "?"
      end
          handle Bug.Bug _ => "??"


end
end
