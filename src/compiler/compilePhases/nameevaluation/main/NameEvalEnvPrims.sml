(**
 * @copyright (c) 2018 Tohoku University.
 * @author Atsushi Ohori
 *)
structure NameEvalEnvPrims =
struct
local
  structure I = IDCalc
  structure E = NameEvalError 
  structure V = NameEvalEnv

  structure EU = UserErrorUtils
  fun bug s = Bug.Bug ("NameEvalEnv: " ^ s)

in

  fun preferSecond arg =
      case arg of
        (NONE, SOME (key2, v2)) => (key2, v2)
      | (SOME (key1, v1), NONE) => (key1, v1)
      | (SOME _, SOME (key2, v2)) => (key2, v2)
      | (NONE, NONE) => raise bug "none in unionWith3"

(*
   datatype filePlace = LIB | SRC
   type fileLoc =
        {fileName:string, 
         filePlace:filePlace, 
         from:{line:int, col:int}, 
         to:{line:int, col:int}}
   type fileItem = {loc:fileLoc, itemName:string} 
   datatype defItem = 
       VAR of fileItem
     | CON of fileItem
     | EXN of fileItem
     | TYDEF of fileItem
     | DTY of fileItem
     | STR of fileItem
     | SIG of fileItem
     | FUNCTOR of fileItem
     | OPRIMID of fileItem
     | BUILTINTYDEF of string
     | BUILTINDTY of string
     | BUILTINPRIM of string
   fun defTag defItem =
       case defItem of
       VAR _ => 1
     | CON _ => 2
     | EXN _ => 3
     | TYDEF  _ => 4
     | DTY _ => 5
     | STR _ => 6
     | SIG _ => 7
     | FUNCTOR _ => 8
     | OPRIMID _ => 9
     | BUILTINTYDEF _ => 10
     | BUILTINDTY _ => 11
     | BUILTINPRIM _ => 12

   fun filePlaceCompare (LIB, SRC) = LESS
     | filePlaceCompare (LIB, LIB) = EQUAL
     | filePlaceCompare (SRC, SRC) = EQUAL
     | filePlaceCompare (SRC, LIB) = GREATER
   fun locCompare ({line=l1, col=c1}, {line=l2, col=c2}) =
       case Int.compare (l1, l2) of
         EQUAL => Int.compare(c1, c2)
       | x => x
   fun fileLocCompare (loc1, loc2) =
       case String.compare (#fileName loc1, #fileName loc2) of
         EQUAL => 
         (case filePlaceCompare (#filePlace loc1, #filePlace loc2) of
            EQUAL =>
            (case locCompare (#from loc1, #from loc2) of
               EQUAL =>locCompare (#to loc1, #to loc2)
             | x => x)
          | x => x)
       | x => x
   fun fileItemCompare (fitem1, fitem2) =
       case fileLocCompare (#loc fitem1, #loc fitem2) of
         EQUAL => String.compare  (#itemName fitem1, #itemName fitem2)
       | x => x
   fun primitiveToString primitive =
       Bug.prettyPrint (BuiltinPrimitive.format_primitive primitive)
   fun defItemCompare (d1, d2) =
       case Int.compare (defTag d1, defTag d2) of 
         EQUAL => 
         (case (d1,d2) of
            (VAR fileItem1, VAR fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (CON fileItem1, CON fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (EXN fileItem1, EXN fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (TYDEF fileItem1, TYDEF fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (DTY fileItem1, DTY fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (STR fileItem1, STR fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (SIG fileItem1, SIG fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (FUNCTOR fileItem1, FUNCTOR fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (OPRIMID fileItem1, OPRIMID fileItem2) => fileItemCompare (fileItem1,fileItem2)
          | (BUILTINTYDEF string1, BUILTINTYDEF string2) => String.compare (string1,string2)
          | (BUILTINDTY string1, BUILTINDTY string2) => String.compare (string1,string2)
          | (BUILTINPRIM string1, BUILTINPRIM string2) => String.compare (string1,string2)
          | x => EQUAL) (* this case never happen *)
       | x => x
   fun itemTargetCompare ({fileItem=f1, target=t1}, {fileItem=f2, target=t2}) =
       case fileItemCompare(f1, f2) of
         EQUAL => defItemCompare(t1, t2)
       | x => x

   datatype item = 
       DEF of defItem
     | PROVIDE of {fileItem:fileItem, target:defItem}
     | ALIAS of {fileItem:fileItem, target:defItem}
     | STRMEM of {fileItem:fileItem, target:defItem}
     | SIGMEM of {fileItem:fileItem, target:defItem}
     | REF of {fileItem:fileItem, target:defItem}
   fun itemCompare (DEF def1, DEF def2) = defItemCompare (def1, def2)
     | itemCompare (DEF _, _) =  LESS
     | itemCompare (_, DEF _) =  GREATER
     | itemCompare (PROVIDE x, PROVIDE y) = itemTargetCompare (x,y) 
     | itemCompare (PROVIDE _, _) =  LESS
     | itemCompare (_, PROVIDE _) =  GREATER
     | itemCompare (ALIAS x, ALIAS y) = itemTargetCompare (x,y) 
     | itemCompare (ALIAS x, _) = LESS
     | itemCompare (_, ALIAS _) =  GREATER
     | itemCompare (STRMEM x, STRMEM y) = itemTargetCompare (x,y) 
     | itemCompare (STRMEM x, _) = LESS
     | itemCompare (_, STRMEM _) =  GREATER
     | itemCompare (SIGMEM x, SIGMEM y) = itemTargetCompare (x,y) 
     | itemCompare (SIGMEM x, _) = LESS
     | itemCompare (_, SIGMEM _) =  GREATER
     | itemCompare (REF x, REF y) = itemTargetCompare (x,y) 

  structure ItemOrd =
  struct
    type ord_key = item
    val compare = itemCompare
  end
  structure ItemMap = BinaryMapFn(ItemOrd)
  structure ItemSet = BinarySetFn(ItemOrd)
                                    
   fun isSystemFileitem {loc = {filePlace = LIB, ...}, ...} = true
     | isSystemFileitem {loc = {filePlace = SRC, fileName = "none", from = {line = ~1, col = ~1},...}, ...} = true
     | isSystemFileitem  {loc = {filePlace = SRC, ...}, ...} = false 
   fun isSystemDefitem defItem = 
       case defItem of 
       VAR fileItem => isSystemFileitem fileItem
     | CON fileItem => isSystemFileitem fileItem
     | EXN fileItem => isSystemFileitem fileItem
     | TYDEF fileItem => isSystemFileitem fileItem
     | DTY fileItem => isSystemFileitem fileItem
     | STR fileItem => isSystemFileitem fileItem
     | SIG fileItem => isSystemFileitem fileItem
     | FUNCTOR fileItem => isSystemFileitem fileItem
     | OPRIMID fileItem => isSystemFileitem fileItem
     | BUILTINTYDEF _ => true
     | BUILTINDTY _ => true
     | BUILTINPRIM _ => true

(*
   val libBase = 
       OS.Path.mkCanonical (Filename.toString (MainUtils.defaultSystemBaseDir ()))
   fun symbolToFileitem
      {string, loc = ({fileName, line=l1, col=c1},
                      {fileName=_, line=l2, col=c2})} =
       {itemName = string,
        loc = {fileName = fileName, 
               filePlace = if String.isPrefix libBase fileName then LIB else SRC,
               from = {line = l1, col = c1},
               to = {line = l2, col = c2}}
       }
   fun longsybolToFileitem longsymbol = symbolToFileitem (Symbol.lastSymbol longsymbol)
*)
   fun mkDefitemIdstatus idstatus =
       case idstatus of
         I.IDVAR {id, longsymbol} => 
         SOME (VAR (longsybolToFileitem longsymbol))
       | I.IDVAR_TYPED  {id, ty, longsymbol} =>
         SOME (VAR (longsybolToFileitem longsymbol))
       | I.IDCON {id, ty, longsymbol} =>
         SOME (CON (longsybolToFileitem longsymbol))
       | I.IDEXN {id, ty, longsymbol} =>
         SOME (EXN (longsybolToFileitem longsymbol))
       | I.IDEXNREP {id, ty, longsymbol} =>
         SOME (EXN (longsybolToFileitem longsymbol))
       | I.IDEXVAR {exInfo = {longsymbol, version, used, ty}, internalId} =>
         SOME (VAR (longsybolToFileitem longsymbol))
       | I.IDEXVAR_TOBETYPED {longsymbol, id,  version} =>
         SOME (VAR (longsybolToFileitem longsymbol))
       | I.IDBUILTINVAR {primitive, ty} => 
         SOME (BUILTINPRIM (primitiveToString primitive))
       | I.IDEXEXN {used, longsymbol, version, ty} =>
         SOME (EXN (longsybolToFileitem longsymbol))
       | I.IDEXEXNREP {used, ty, version, longsymbol} =>
         SOME (EXN (longsybolToFileitem longsymbol))
       | I.IDOPRIM {id, overloadDef, used, longsymbol} =>
         SOME (OPRIMID (longsybolToFileitem longsymbol))
       | I.IDSPECVAR {ty, symbol} => NONE
       | I.IDSPECEXN {ty, symbol} => NONE
       | I.IDSPECCON {symbol} => NONE
                               
   fun mkDefitemTfun tfun =
       case tfun of
         I.TFUN_DEF {admitsEq, formals, realizerTy, longsymbol} =>
         SOME (TYDEF (longsybolToFileitem longsymbol))
       | I.TFUN_VAR tfunKindRef =>
         (case tfunKindRef of
            ref(I.TFUN_DTY{id,admitsEq,formals, longsymbol, conIDSet,
                           conSpec,liftedTys,dtyKind}) =>
            SOME (DTY (longsybolToFileitem longsymbol))
          | ref(I.TFV_SPEC {longsymbol, id, admitsEq, formals}) =>
            NONE
          | ref(I.TFV_DTY {longsymbol, id,admitsEq,formals,conSpec,liftedTys}) =>
            NONE
          | ref(I.REALIZED{tfun,...}) => mkDefitemTfun tfun
          | ref(I.INSTANTIATED{tfun,...}) => mkDefitemTfun tfun
          | ref(I.FUN_DTY{tfun,...}) => mkDefitemTfun tfun
         )

   fun mkDefitemTstr tstr =
       case  tstr of
         V.TSTR tfun => mkDefitemTfun tfun
       | V.TSTR_DTY {tfun,...} => mkDefitemTfun tfun
   val refDefSet = ref ItemSet.empty: ItemSet.set ref
   fun resetRefDefList () =  refDefSet := ItemSet.empty
   fun registerItem refDef = 
       if ItemSet.member(!refDefSet, refDef) then ()
       else
         (
          refDefSet := ItemSet.add(!refDefSet, refDef)
         )
   fun regTstr tstr = 
       let
         val defItemOpt =
             case  tstr of
               V.TSTR tfun => mkDefitemTfun tfun
             | V.TSTR_DTY {tfun,...} => mkDefitemTfun tfun
       in
         case defItemOpt of
           NONE => ()
         | SOME defItem => 
           if isSystemDefitem defItem then ()
           else registerItem (DEF defItem)
       end
   fun regId idstatus = 
       let
         val defItemOpt = mkDefitemIdstatus idstatus
       in
         case defItemOpt of
           NONE => ()
         | SOME defItem  => 
           if isSystemDefitem defItem then ()
           else registerItem (DEF defItem)
       end
   fun regStr symbol =
       let
         val fileItem = symbolToFileitem symbol
       in
         if isSystemFileitem fileItem then ()
         else registerItem (DEF (STR fileItem))
       end

   fun regVarE varE =
       SymbolEnv.app regId varE
   fun regTyE tyE =
       SymbolEnv.app regTstr tyE
   fun regStrE envMap =
       SymbolEnv.appi 
         (fn (symbol, env) => regStr symbol)
         envMap
*)

(*
   find function : a function that find a definition from a reference.
                    The argument symbol is a reference occurrence.
   check function: a function looks up an env to check if there is an entry.
                   This symbol is not a refence occurrence.
   bind function: a function that binds a name in an environment.
                  The argument symbol is a definition occurrence.
   insert function: a function that insert an entry into an environment.
                   The argument symbol is not a definition occurrence.
   xxxWithyyy: insert all elements in yyy into  xxx
   bindXxxWithYyy: bind all elenets in yyy into xxx.
   checkProvide: a function that lookup symbol for interface check
*)

  (* find function *)
  fun findTstr (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "*** nil to findTstr *** "
      | symbol :: nil => 
        (case SymbolEnv.findi(tyE, symbol) of
           NONE => NONE
         | SOME (key, tstr) => 
           let
(*
             val defItemOpt = mkDefitemTstr tstr
             val _ = 
                 case defItemOpt of
                   NONE => ()
                 | SOME defItem => 
                   let
                     val fileItem = symbolToFileitem symbol
                   in
                     if isSystemFileitem fileItem 
                        orelse isSystemDefitem defItem
                     then ()
                     else
                       registerItem
                         (REF {fileItem = fileItem, target = defItem})
                   end
*)
           in
             SOME tstr
           end
        )
      | strsymbol :: path =>
        (case SymbolEnv.findi(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME (symbolInEnv, {env,...}) => findTstr (env, path)
        )

  (* find function *)
  exception LookupTstr
  fun lookupTstr env longsymbol : V.tstr =
      case findTstr (env, longsymbol) of 
        NONE => raise LookupTstr
      | SOME tstr => tstr


  (* check function *)
  fun checkTstr (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "*** nil to lookupTy *** "
      | symbol :: nil => SymbolEnv.find(tyE, symbol) 
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkTstr (env, path)
        )

  (* check function *)
  fun checkProvideTstr (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, symbol) =
      let
        val tstrOpt = SymbolEnv.find(tyE, symbol) 
(*
        val _ = 
            case tstrOpt of
              NONE => ()
            | SOME tstr => 
              case mkDefitemTstr tstr of
                NONE => ()
              | SOME defItem => 
                registerItem
                  (PROVIDE {fileItem = symbolToFileitem symbol,
                            target = defItem})
*)
      in
        tstrOpt
      end

  (* bind function *)
  fun rebindTstr (V.ENV{varE,tyE,strE}, symbol, tstr) =
      let
(*
        val _ = regTstr tstr
*)
      in
        V.ENV
          {
           varE = varE,
           tyE = SymbolEnv.insert(tyE, symbol, tstr),
           strE = strE
          }
      end
  (* insert function *)
  fun reinsertTstr (V.ENV{varE,tyE,strE}, symbol, tstr) =
      V.ENV
        {
         varE = varE,
         tyE = SymbolEnv.insert(tyE, symbol, tstr),
         strE = strE
        }

  (* bind function *)
  fun bindTstr (env, symbol, tstr) =
      let
(*
        val _ = regTstr tstr
*)
        val V.ENV{varE, tyE, strE} = env
        val _ = 
            case SymbolEnv.find(tyE, symbol) of
              NONE => ()
            | SOME _ =>
              EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateTypInSpec("055", symbol))
        val tyE = SymbolEnv.insert(tyE, symbol, tstr)
      in
        V.ENV {tyE=tyE, varE=varE, strE=strE}
      end

  (* insert function *)
  fun insertTstr (env, symbol, tstr) =
      let
        val V.ENV{varE, tyE, strE} = env
        val tyE =
            SymbolEnv.insertWithi
            (fn (symbol, _) =>
                (EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateTypInSpec("055", symbol))))
            (tyE, symbol, tstr)
      in
        V.ENV {tyE=tyE, varE=varE, strE=strE}
      end


  (* bind function *)
  fun rebindTstrLongsymbol
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, tstr) =
      let
(*
        val _ = regTstr tstr
*)
      in
        case path of
          nil => raise bug "nil to rebindTypLongid"
        | symbol::nil =>
          V.ENV
            {
             varE = varE,
             tyE = SymbolEnv.insert(tyE, symbol, tstr),
             strE = strE
            }
        | strsymbol::path =>
          let
            val {env, strKind} = 
                case SymbolEnv.find(envMap, strsymbol) of
                  SOME strEntry =>strEntry
                | NONE => raise bug "strenv not found in rebindStrLongsymbol"
            val newEnv = rebindTstrLongsymbol(env, path, tstr)
          in
            V.ENV
              {
               varE = varE,
               tyE = tyE,
               strE = 
               V.STR
                 (SymbolEnv.insert
                    (envMap, strsymbol, {env=newEnv, strKind=strKind}))
              }
          end
      end


  (* insert function *)
  fun reinsertTstrLongsymbol
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, tstr) =
      case path of
        nil => raise bug "nil to rebindTypLongid"
      | symbol::nil =>
        V.ENV
          {
           varE = varE,
           tyE = SymbolEnv.insert(tyE, symbol, tstr),
           strE = strE
          }
      | strsymbol::path =>
        let
          val {env, strKind} = 
              case SymbolEnv.find(envMap, strsymbol) of
                SOME strEntry =>strEntry
              | NONE => raise bug "strenv not found in rebindStrLongsymbol"
          val newEnv = reinsertTstrLongsymbol(env, path, tstr)
        in
          V.ENV
            {
             varE = varE,
             tyE = tyE,
             strE = 
             V.STR
               (SymbolEnv.insert
                  (envMap, strsymbol, {env=newEnv, strKind=strKind}))
            }
        end


  (* find function for those that returns an idstatus *)
  fun findCon (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to findCon"
      | symbol :: nil => 
        let
          val idstatus = SymbolEnv.find(varE, symbol)
        in
          case idstatus of
            (SOME (I.IDCON _)) => idstatus
          | (SOME (I.IDEXN _)) => idstatus
          | (SOME (I.IDEXNREP _)) => idstatus
          | (SOME (I.IDEXEXN _)) => idstatus
          | (SOME (I.IDEXEXNREP _)) => idstatus
          | NONE => NONE
          | (SOME (I.IDVAR _)) => NONE
          | (SOME (I.IDVAR_TYPED _)) => NONE
          | (SOME (I.IDEXVAR _)) => NONE
          | (SOME (I.IDBUILTINVAR _)) => NONE
          | (SOME (I.IDOPRIM _)) => NONE
          | (SOME (I.IDEXVAR_TOBETYPED _)) => raise bug "IDEXVAR_TOBETYPED to findCon"
          | (SOME (I.IDSPECVAR _)) => raise bug "IDSPECVAR to findCon"
          | (SOME (I.IDSPECEXN _)) => raise bug "IDSPECEXN to findCon"
          | (SOME (I.IDSPECCON _)) => raise bug "IDSPECCON to findCon"
        end
      | strsymbol :: path =>
        (case SymbolEnv.findi(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME (smbolInEnv, {env,...}) => findCon (env, path)
        )

  (* find function *)
  fun findId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to findId"
      | symbol :: nil => 
        let
          val idstatusOpt = SymbolEnv.find(varE, symbol)
(*
          val _ =
              case idstatusOpt of
                NONE => ()
              | SOME idstatus => 
                (case mkDefitemIdstatus idstatus of
                   NONE => ()
                 | SOME defItem => 
                   let
                     val fileItem = symbolToFileitem symbol
                   in
                     if isSystemFileitem fileItem 
                        orelse isSystemDefitem defItem
                     then ()
                     else
                       registerItem
                         (REF {fileItem = fileItem, target = defItem})
                   end
                )
*)
        in
          idstatusOpt
        end
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => findId (env, path)
        )

 (* check function *)
  fun checkId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to checkId"
      | symbol :: nil => SymbolEnv.find(varE, symbol)
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkId (env, path)
        )
  (* find function *)
  exception LookupId
  fun lookupId env longsymbol : I.idstatus =
      case findId(env, longsymbol) of
        NONE => raise LookupId
      | SOME idstatus => idstatus

  (* check function *)
  fun searchId env longsymbol : I.idstatus =
      case checkId(env, longsymbol) of
        NONE => raise LookupId
      | SOME idstatus => idstatus

 (* check sig id *)
  fun checkSigId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to checkId"
      | symbol :: nil => SymbolEnv.find(varE, symbol)
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkId (env, path)
        )

 (* check function *)
  fun checkProvideId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, symbol) =
      let
        val idstatusOpt = SymbolEnv.find(varE, symbol)
(*
        val _ = 
            case idstatusOpt of
              NONE => ()
            | SOME idstatus => 
              (case mkDefitemIdstatus idstatus of
                 NONE => ()
               | SOME defItem => 
                 registerItem
                   (PROVIDE {fileItem = symbolToFileitem symbol,
                             target = defItem})
              )
*)
      in
        idstatusOpt
      end


      

 (* check function *)
  fun checkProvideAlias (symbol, V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      let
        val idstatusOpt = 
            case longsymbol of 
              nil => raise bug "nil to checkProvideAlias"
            | symbol :: nil => 
              SymbolEnv.find(varE, symbol)
            | strsymbol :: path =>
              (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
                 NONE => NONE
               | SOME {env,...} => checkId (env, path)
              )
(*
        val _ = 
            case idstatusOpt of
              NONE => ()
            | SOME idstatus => 
              case mkDefitemIdstatus idstatus of
                NONE => ()
              | SOME defItem => 
                registerItem
                  (ALIAS {fileItem = symbolToFileitem symbol,
                          target = defItem})
*)
      in
        idstatusOpt
      end

  (* bind function *)
  fun rebindId (V.ENV{varE, tyE, strE}, symbol, idstatus) =
      let
(*
        val _ = regId idstatus
*)
      in
        V.ENV
          {varE = SymbolEnv.insert(varE, symbol, idstatus),
           tyE = tyE,
           strE = strE
          }
      end
  (* insert function *)
  fun reinsertId (V.ENV{varE, tyE, strE}, symbol, idstatus) =
      V.ENV
        {varE = SymbolEnv.insert(varE, symbol, idstatus),
         tyE = tyE,
         strE = strE
        }
  (* bind function *)
  fun bindId (env, symbol, idstate) =
      let
(*
        val _ = regId idstate
*)
        val V.ENV{varE, tyE, strE} = env
        val varE =
            SymbolEnv.insertWithi
              (fn (symbol,_) =>
                  (EU.enqueueError (Symbol.symbolToLoc symbol,E.DuplicateIdInSpec("054",symbol))))
              (varE, symbol, idstate)
      in
        V.ENV {varE=varE, tyE=tyE, strE=strE}
      end
  (* indsert function *)
  fun insertId (env, symbol, idstate) =
      let
        val V.ENV{varE, tyE, strE} = env
        val varE =
            SymbolEnv.insertWithi
              (fn (symbol,_) =>
                  (EU.enqueueError (Symbol.symbolToLoc symbol,E.DuplicateIdInSpec("054",symbol))))
              (varE, symbol, idstate)
      in
        V.ENV {varE=varE, tyE=tyE, strE=strE}
      end

  (* bind function *)
  fun rebindIdLongsymbol
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, idstatus) : V.env =
      let
(*
        val _ = regId idstatus
*)
      in
        case path of
          nil => raise bug "nil to rebindTypLongid"
        | symbol::nil =>
          V.ENV
            {
             varE = SymbolEnv.insert(varE, symbol, idstatus),
             tyE = tyE,
             strE = strE
            }
        | strsymbol::path =>
          let
            val {env, strKind} = 
                case SymbolEnv.find(envMap, strsymbol) of
                  SOME strEntry => strEntry
                | NONE => raise bug "env not found in rebindIdLongsymbol"
            val newEnv = rebindIdLongsymbol(env, path, idstatus)
          in
            V.ENV
              {
               varE = varE,
               tyE = tyE,
               strE = 
               V.STR (SymbolEnv.insert
                        (envMap, 
                         strsymbol, 
                         {env=newEnv, strKind=strKind}))
              }
          end
      end

  (* insert function *)
  fun reinsertIdLongsymbol
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, idstatus) : V.env =
      case path of
        nil => raise bug "nil to rebindTypLongid"
      | symbol::nil =>
        V.ENV
          {
           varE = SymbolEnv.insert(varE, symbol, idstatus),
           tyE = tyE,
           strE = strE
          }
      | strsymbol::path =>
        let
          val {env, strKind} = 
              case SymbolEnv.find(envMap, strsymbol) of
                SOME strEntry => strEntry
              | NONE => raise bug "env not found in rebindIdLongsymbol"
          val newEnv = reinsertIdLongsymbol(env, path, idstatus)
        in
          V.ENV
            {
             varE = varE,
             tyE = tyE,
             strE = 
             V.STR (SymbolEnv.insert
                    (envMap, 
                     strsymbol, 
                     {env=newEnv, strKind=strKind}))
            }
        end

  (* find function *)
  fun findStr (V.ENV {varE, tyE, strE = V.STR strMap}, longsymbol) = 
      case longsymbol of 
          nil => raise bug "nil to lookupStrId"
        | symbol :: nil =>  SymbolEnv.find(strMap, symbol) 
        | strsymbol :: path =>
          (case SymbolEnv.findi(strMap, strsymbol) of
             NONE => NONE
           | SOME (symbolInEnv, {env,...}) => 
             findStr (env, path)
          )

  (* find function *)
  exception LookupStr
  fun lookupStr env longsymbol = 
      case findStr (env, longsymbol) of
        NONE => raise LookupStr
      | SOME strEntry => strEntry

  (* find function *)
  fun checkStr (V.ENV {varE, tyE, strE = V.STR strMap}, longsymbol) = 
      case longsymbol of 
          nil => raise bug "nil to lookupStrId"
        | symbol :: nil =>  SymbolEnv.find(strMap, symbol) 
        | strsymbol :: path =>
          (case SymbolEnv.find(strMap, strsymbol) of
             NONE => NONE
           | SOME {env,...} => 
             checkStr (env, path)
          )

  (* find function *)
  fun checkProvideStr (V.ENV {varE, tyE, strE = V.STR strMap}, symbol) = 
      let
        val defSymbolstrEntryOpt = SymbolEnv.findi(strMap, symbol) 
        val strEntryOpt =
            case defSymbolstrEntryOpt of
              NONE => NONE
            | SOME (defSymbol, strEntry) => 
              (
(*
               registerItem
                 (PROVIDE {fileItem = symbolToFileitem symbol,
                           target = (STR (symbolToFileitem defSymbol))});
*)
              SOME strEntry)
      in
        strEntryOpt
      end

        

  (* bind function *)
  fun rebindStr (V.ENV{varE,tyE,strE=V.STR envMap}, symbol, {strKind, env=strEnv}) =
      let
(*
        val _ = regStr symbol
*)
      in
        V.ENV {varE = varE,
               tyE = tyE,
               strE = V.STR (SymbolEnv.insert(envMap, symbol, {strKind=strKind, env=strEnv}))
              }
      end

  (* bind function *)
  fun bindStr (V.ENV{varE, tyE, strE = V.STR envMap}, symbol, {strKind, env=strEnv}) =
      let
        val envMap =
            case SymbolEnv.findi(envMap, symbol) of
              NONE => 
              (
(*
               regStr symbol;
*)
               SymbolEnv.insert(envMap, symbol, {strKind=strKind, env=strEnv})
              )
            | SOME (symbol, _) => 
              (EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateIdInSpec("050", symbol));
               envMap
              )
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR envMap}
      end
  (* insert function *)
  fun insertStr (V.ENV{varE, tyE, strE = V.STR envMap}, symbol, {strKind, env=strEnv}) =
      let
        val envMap =
            case SymbolEnv.findi(envMap, symbol) of
              NONE => SymbolEnv.insert(envMap, symbol, {strKind=strKind, env=strEnv})
            | SOME (symbol, _) => 
              (EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateIdInSpec("050", symbol));
               envMap
              )
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR envMap}
      end

  (* insert function *)
  fun reinsertStr (V.ENV{varE,tyE,strE=V.STR envMap}, symbol, {strKind, env=strEnv}) =
      V.ENV {varE = varE,
           tyE = tyE,
           strE = V.STR (SymbolEnv.insert(envMap, symbol, {strKind=strKind, env=strEnv}))
          }

  (* bind function *)
  fun singletonStr (symbol, strEntry) = rebindStr(V.emptyEnv, symbol, strEntry)

  (* insert function *)
  fun varEWithVarE (varE1, varE2) = 
      SymbolEnv.unionWith #2 (varE1, varE2)

  (* bind functions *)
  fun bindVarEWithVarE (varE1, varE2) = 
      (
(*
       regVarE varE2;
*)
       SymbolEnv.unionWithi3
         preferSecond
         (varE1, varE2)
      )

  (* insert functions *)
  fun tyEWithTyE (tyE1, tyE2) = 
      SymbolEnv.unionWith #2 (tyE1, tyE2)

  (* binding functions *)
  fun bindTyEWithTyE (tyE1, tyE2) = 
      (
(*
       regTyE tyE2;
*)
       SymbolEnv.unionWithi3
         preferSecond
         (tyE1, tyE2)
      )

  (* insert functions *)
  fun strEWithStrE (V.STR envMap1, V.STR envMap2) = 
      V.STR (SymbolEnv.unionWith #2 (envMap1, envMap2))

  (* binding functions *)
  fun bindStrEWithStrE (V.STR envMap1, V.STR envMap2) = 
      (
(*
       regStrE envMap2;
*)
       V.STR (SymbolEnv.unionWithi3
                preferSecond
                (envMap1, envMap2)
             )
      )

  (* insert function *)
  fun envWithVarE (V.ENV {varE, strE, tyE}, varE1 : I.varE) =
      V.ENV {varE = varEWithVarE (varE, varE1),
           strE = strE,
           tyE = tyE}

  (* bind functions *)
  fun bindEnvWithVarE (V.ENV {varE, strE, tyE}, varE1 : I.varE) =
      V.ENV {varE = bindVarEWithVarE (varE, varE1),
           strE = strE,
           tyE = tyE}

  (* insert function *)
  fun envWithEnv (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                  V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      V.ENV {varE = varEWithVarE (varE1, varE2),
           strE = strEWithStrE (strE1, strE2),
           tyE = tyEWithTyE (tyE1,tyE2)
          }

  (* bind function *)
  fun bindEnvWithEnv (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                      V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      V.ENV {varE = bindVarEWithVarE (varE1, varE2),
           strE = bindStrEWithStrE (strE1, strE2),
           tyE = bindTyEWithTyE (tyE1,tyE2)
          }

  (* insert function *)
  fun updateStrE (V.STR envMap1, V.STR envMap2) = 
      let
        fun strEWithStrE ({env=env1, strKind}, 
                          {env=env2, strKind=_}) =
            {env=updateEnv(env1,env2), strKind=strKind}
      in
        V.STR (SymbolEnv.unionWith strEWithStrE (envMap1, envMap2))
      end

  (* insert function *)
  and updateEnv (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                  V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      V.ENV {varE = varEWithVarE (varE1, varE2),
           strE = updateStrE (strE1, strE2),
           tyE = tyEWithTyE (tyE1,tyE2)
          }

  (* insert function *)
  fun sigEWithSigE (sigE1, sigE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, sigE1) => SymbolEnv.insert(sigE1, symbol, entry))
      sigE1
      sigE2

  (* bind function *)
  fun bindSigEWithSigE (sigE1, sigE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, sigE1) => 
          SymbolEnv.insert(sigE1, symbol, entry))
      sigE1
      sigE2

  (* find function *)
  fun findFunETopEnv ({Env, FunE, SigE}, symbol) =
      SymbolEnv.find(FunE, symbol) 

  (* check function *)
  fun checkFunETopEnv ({Env, FunE, SigE}, symbol) =
      SymbolEnv.find(FunE, symbol) 

  (* bind function *)
  fun rebindFunE (FunE, symbol, funEEntry) =
      SymbolEnv.insert(FunE, symbol, funEEntry) 

  (* insert function *)
  fun reinsertFunE (FunE, symbol, funEEntry) =
      SymbolEnv.insert(FunE, symbol, funEEntry) 


  (* insert function *)
  fun funEWithFunE (funE1, funE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, funE1) => SymbolEnv.insert(funE1, symbol, entry))
      funE1
      funE2

  (* insert function *)
  fun bindFunEWithFunE (funE1, funE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, funE1) => SymbolEnv.insert(funE1, symbol, entry))
      funE1
      funE2

  (* find function *)
  fun findSigETopEnv ({Env, FunE, SigE}, symbol) =
      SymbolEnv.find(SigE, symbol) 

  (* check function *)
  fun checkSigETopEnv ({Env, FunE, SigE}, symbol) =
      SymbolEnv.find(SigE, symbol) 

  (* bind function *)
  fun rebindSigE (SigE, symbol, env) =
      SymbolEnv.insert(SigE, symbol, env) 

  (* insert function *)
  fun reinsertSigE (SigE, symbol, env) =
      SymbolEnv.insert(SigE, symbol, env) 

  (* insert function *)
  fun topEnvWithSigE ({Env, FunE, SigE}, sige) : V.topEnv =
      {Env = Env,
       FunE = FunE,
       SigE = sigEWithSigE (SigE, sige)
      }

  (* bind function *)
  fun bindTopEnvWithSigE ({Env, FunE, SigE}, sige) : V.topEnv =
      {Env = Env,
       FunE = FunE,
       SigE = bindSigEWithSigE (SigE, sige)
      }

  (* insert function *)
  fun topEnvWithFunE ({Env, FunE, SigE}, funE) : V.topEnv =
      {Env = Env,
       FunE = funEWithFunE (FunE, funE),
       SigE = SigE
      }

  (* bind function *)
  fun bindTopEnvWithFunE ({Env, FunE, SigE}, funE) : V.topEnv =
      {Env = Env,
       FunE = funEWithFunE (FunE, funE),
       SigE = SigE
      }

  (* insert function *)
  fun topEnvWithEnv ({Env, FunE, SigE}, env1) : V.topEnv =
      {Env = envWithEnv (Env, env1), FunE = FunE, SigE = SigE}

  (* bind function *)
  fun bindTopEnvWithEnv ({Env, FunE, SigE}, env1) : V.topEnv =
      {Env = envWithEnv (Env, env1), FunE = FunE, SigE = SigE}

  (* insert function *)
  fun topEnvWithTopEnv
        ({Env=env1,FunE=funE1,SigE=sige1},{Env=env2,FunE=funE2,SigE=sige2})
      : V.topEnv
      =
      {Env = envWithEnv (env1, env2),
       FunE = funEWithFunE (funE1, funE2),
       SigE = sigEWithSigE (sige1, sige2)
      }

  (* bind function *)
  fun bindTopEnvWithTopEnv
        ({Env=env1,FunE=funE1,SigE=sige1},{Env=env2,FunE=funE2,SigE=sige2})
      : V.topEnv
      =
      {Env = bindEnvWithEnv (env1, env2),
       FunE = bindFunEWithFunE (funE1, funE2),
       SigE = bindSigEWithSigE (sige1, sige2)
      }

  fun unionVarE code (varE1, varE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol1, v1), (symbol2,v2)) =>
            (case (v1, v2) of
               (I.IDCON {id=id1, ...}, I.IDCON {id = id2,...}) =>
               if ConID.eq(id1, id2) then ()
               else 
                 EU.enqueueError 
                   (Symbol.symbolToLoc symbol2,
                    E.DuplicateVar(code ^ "v", symbol2))
             | _ => 
               EU.enqueueError 
                 (Symbol.symbolToLoc symbol2, 
                  E.DuplicateVar(code ^ "v", symbol2));
             (symbol2, v2))
        )
        (varE1, varE2)

  fun unionTyE code (tyE1, tyE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol1,v1), (symbol2,v2)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc symbol2, 
                E.DuplicateTypName(code ^ "v", symbol2)); 
             (symbol2, v2))
        )
        (tyE1, tyE2)
            
  fun unionStrE code (V.STR map1, V.STR map2) =
      V.STR
        (
         SymbolEnv.unionWithi2
           (fn ((symbol1,v1), (symbol2,v2)) =>
               (EU.enqueueError
                  (Symbol.symbolToLoc symbol2, 
                   E.DuplicateStrName(code ^ "v", symbol2)); 
                (symbol2, v2))
           )
           (map1, map2)
        )
            
  fun unionFunE code (funE1, funE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol,v1),(symbol2,v2)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc symbol2, 
                E.DuplicateFunctor(code ^ "f", symbol2));
             (symbol2, v2))
        )
      (funE1, funE2)

  fun unionSigE code (sigE1, sigE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol1,v1),(symbol2,v2)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc symbol2, 
                E.DuplicateSigname(code ^ "s", symbol2));
             (symbol2,v2))
        )
        (sigE1, sigE2)

  fun unionEnv code (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                     V.ENV {varE=varE2, strE=strE2, tyE=tyE2})
      =
      let
        val varE = unionVarE code (varE1, varE2)
        val tyE = unionTyE code (tyE1, tyE2)
        val strE = unionStrE code (strE1, strE2)
      in
        V.ENV{varE=varE, strE=strE, tyE=tyE}
      end

  fun unionTopEnv code
        ({Env=env1,FunE=funE1,SigE=sige1},{Env=env2,FunE=funE2,SigE=sige2})
      : V.topEnv
      =
      {Env = unionEnv code (env1, env2),
       FunE = unionFunE code (funE1, funE2),
       SigE = unionSigE code (sige1, sige2)
      }

end
end
