(**
 * GenerateMain.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure GenerateMain : sig

  val moduleName
      : AbsynInterface.interfaceName option * int option
        -> {source: AbsynInterface.source option,
            mainSymbol: string,
            moduleName: string,
            stackMapSymbol: string,
            codeBeginSymbol: string}

  val generateBuiltin : IDCalc.icdecl list -> RecordCalc.rcdecl list

  val generateEntryCode
      : AbsynInterface.interfaceName option list
        -> {mainFn : LLVMIR.program -> LLVMIR.program,
            moduleName : {moduleName : string}}

end =
struct

  fun interfaceHash (interfaceNameOpt, version) =
      case interfaceNameOpt of
        SOME {hash, ...} => hash
      | NONE =>
        case version of
          NONE => "Z"
        | SOME version => "Z" ^ Int.toString version

  fun moduleName (interfaceNameOpt, version) =
      let
        val hash = interfaceHash (interfaceNameOpt, version)
      in
        {source = Option.map #source interfaceNameOpt,
         moduleName = hash,
         mainSymbol = "_SMLmain" ^ hash,
         stackMapSymbol = "_SML_r" ^ hash,
         codeBeginSymbol = "_SML_b" ^ hash}
      end

  fun checkDuplicateHash moduleNames =
      foldl (fn ({moduleName, source, ...}, map) =>
                case SEnv.find (map, moduleName) of
                  NONE => SEnv.insert (map, moduleName, source)
                | SOME prevName =>
                  raise UserError.UserErrorsWithoutLoc
                        [(UserError.Error,
                          GenerateMainError.HashConflict
                            (prevName, source, moduleName))])
            SEnv.empty
            moduleNames

  structure I = IDCalc
  structure R = RecordCalc
  structure L = LLVMIR

  fun compileSystemICDecl icdecl =
      case icdecl of
        I.ICEXTERNEXN {longsymbol, ty, version=NONE} =>
        let
          val path = Symbol.longsymbolToLongid longsymbol
          val id = ExnID.generate ()
          val ty = EvalIty.evalIty EvalIty.emptyContext ty
          val exnInfo = {path = path, ty = ty, id = id}
        in
          [R.RCEXD ([{exnInfo = exnInfo, loc = Loc.noloc}], Loc.noloc),
           R.RCEXPORTEXN exnInfo]
        end
      | _ => raise Bug.Bug "compileBuiltinDecl"

  fun generateBuiltin icdecls =
      List.concat (map compileSystemICDecl icdecls)

  fun generateEntry moduleNames (program as {topdecs, ...}:L.program) =
      let
        val topdecs =
            List.filter (fn L.DEFINE {linkage = SOME L.EXTERNAL, ...} => false
                          | _ => true)
                        topdecs
        val mainDecls =
            L.DECLARE {linkage = NONE,
                       cconv = NONE,
                       retAttrs = nil,
                       retTy = L.VOID,
                       name = "sml_control_start",
                       arguments = nil,
                       varArg = false,
                       fnAttrs = [L.NOUNWIND],
                       gcname = NONE}
            :: L.DECLARE {linkage = NONE,
                          cconv = NONE,
                          retAttrs = nil,
                          retTy = L.VOID,
                          name = "sml_control_finish",
                          arguments = nil,
                          varArg = false,
                          fnAttrs = [L.NOUNWIND],
                          gcname = NONE}
            :: map (fn {mainSymbol, ...} =>
                       L.DECLARE
                         {linkage = NONE,
                          cconv = SOME L.FASTCC,
                          retAttrs = nil,
                          retTy = L.VOID,
                          name = mainSymbol,
                          arguments = nil,
                          varArg = false,
                          fnAttrs = nil,
                          gcname = NONE})
                   moduleNames
        val mainDef =
            L.DEFINE
              {linkage = SOME L.EXTERNAL,
               cconv = NONE,
               retAttrs = nil,
               retTy = L.VOID,
               name = "_SMLmain",
               parameters = [],
               fnAttrs = nil,
               gcname = NONE,
               body =
                 (L.CALL {result = NONE,
                          tail = true,
                          cconv = NONE,
                          retAttrs = nil,
                          fnPtr = (L.FPTR (L.VOID, nil, false),
                                   L.CONST (L.SYMBOL "sml_control_start")),
                          args = nil,
                          fnAttrs = [L.NOUNWIND]}
                  :: map (fn {mainSymbol, ...} =>
                             L.CALL {result = NONE,
                                     tail = true,
                                     cconv = SOME L.FASTCC,
                                     retAttrs = nil,
                                     fnPtr = (L.FPTR (L.VOID, nil, false),
                                              L.CONST (L.SYMBOL mainSymbol)),
                                     args = nil,
                                     fnAttrs = nil})
                         moduleNames
                  @ [L.CALL {result = NONE,
                             tail = true,
                             cconv = NONE,
                             retAttrs = nil,
                             fnPtr = (L.FPTR (L.VOID, nil, false),
                                      L.CONST (L.SYMBOL "sml_control_finish")),
                             args = nil,
                             fnAttrs = [L.NOUNWIND]}],
                  L.RET_VOID)}
        val stackMapDecls =
            List.concat
              (map (fn {stackMapSymbol, codeBeginSymbol, ...} =>
                       [L.EXTERN {name = stackMapSymbol, ty = L.I8},
                        L.EXTERN {name = codeBeginSymbol, ty = L.I8}])
                   moduleNames)
        val stackMapDef =
            L.GLOBALVAR
              {name = "_SMLstackmap",
               linkage = SOME L.EXTERNAL,
               constant = true,
               ty = L.ARRAY (Word32.fromInt (length moduleNames * 2 + 1),
                             L.PTR L.I8),
               initializer =
                 L.INIT_ARRAY
                   (List.concat
                      (map (fn {stackMapSymbol, codeBeginSymbol, ...} =>
                               [(L.PTR L.I8,
                                 L.INIT_CONST (L.SYMBOL stackMapSymbol)),
                                (L.PTR L.I8,
                                 L.INIT_CONST (L.SYMBOL codeBeginSymbol))])
                           moduleNames
                       @ [[(L.PTR (L.I8), L.INIT_CONST L.NULL)]])),
               align = NONE}
      in
        program # {topdecs = topdecs @ mainDecls @ stackMapDecls
                             @ [mainDef, stackMapDef]}
      end

  fun generateEntryCode interfaceNames =
      let
        val moduleNames = map (fn i => moduleName (i, NONE)) interfaceNames
        val _ = checkDuplicateHash moduleNames
      in
        {mainFn = generateEntry moduleNames,
         moduleName = {moduleName = "SMLmain"}}
      end

end
