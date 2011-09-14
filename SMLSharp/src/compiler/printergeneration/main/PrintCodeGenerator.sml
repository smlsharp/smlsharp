(**
 * This structure generates codes which print binding informations.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrintCodeGenerator.sml,v 1.66 2008/08/24 03:54:41 ohori Exp $
 *)
structure PrintCodeGenerator =
struct
local
  (***************************************************************************)

  structure BF = SMLFormat.BasicFormatters
  structure CT = ConstantTerm
  structure FE = SMLFormat.FormatExpression
  structure FG = FormatterGenerator
  structure NM = NameMap
  structure NPEnv = NameMap.NPEnv
  structure OC = ObjectCode
  structure P = Path
  structure PL = PatternCalc
  structure PT = PredefinedTypes
  structure TP = TypedCalc
  structure TY = Types
  structure U = Utility

  (***************************************************************************)
in  
  fun makeSeqExp codes loc = 
      TP.TPSEQ
      {expList = codes, expTyList = map (fn _ => PT.unitty) codes, loc = loc}

  fun reconstructTyEnv (tyConEnv, tyNameMap) =
      SEnv.foldli
          (fn (tyName, tyState, newTyConEnv) =>
              case tyState of
                NameMap.DATATY (namePath, _) =>
                (case NPEnv.find(tyConEnv, namePath) 
                  of NONE =>
                     raise
                       Control.Bug
                           ("unbound type "
                            ^ NameMap.namePathToString(namePath))
                   | SOME tyBindInfo =>
                     NPEnv.insert
                         (newTyConEnv, (tyName, Path.NilPath), tyBindInfo))
              | NameMap.NONDATATY namePath =>
                (case NPEnv.find(tyConEnv, namePath) 
                  of NONE =>
                     raise
                       Control.Bug
                           ("unbound type "
                            ^ NameMap.namePathToString(namePath))
                   | SOME tyBindInfo =>
                     NPEnv.insert
                         (newTyConEnv, (tyName, Path.NilPath), tyBindInfo)))
          NPEnv.empty
          tyNameMap

  fun reconstructVarEnv (varEnv, varNameMap) =
      SEnv.foldli
          (fn (varName, idState, newVarEnv) =>
              case idState of
                NameMap.VARID namePath =>
                (case NPEnv.find(varEnv, namePath)
                  of NONE =>
                     raise
                       Control.Bug
                           ("unbound variable "
                            ^ NameMap.namePathToString(namePath))
                   | SOME idstate => 
                     NPEnv.insert(newVarEnv, (varName, Path.NilPath), idstate))
              | NameMap.CONID namePath =>
                (case NPEnv.find(varEnv, namePath)
                  of NONE =>
                     raise
                       Control.Bug
                           ("unbound data constructor "
                            ^ NameMap.namePathToString(namePath))
                   | SOME idstate => 
                     NPEnv.insert(newVarEnv, (varName, Path.NilPath), idstate))
              | NameMap.EXNID namePath =>
                (case NPEnv.find(varEnv, namePath)
                  of NONE =>
                     raise
                       Control.Bug
                           ("unbound exception constructor "
                            ^ NameMap.namePathToString(namePath))
                   | SOME idstate => 
                     NPEnv.insert
                         (newVarEnv, (varName, Path.NilPath), idstate)))
          NPEnv.empty
          varNameMap
                              
  fun reconstructStrEnv (varEnv, tyConEnv, strNameMap) =
      SEnv.foldli
          (fn
           (
             strName, 
             NameMap.NAMEAUX
                 {
                   name,
                   parentPath,
                   wrapperSysStructure,
                   basicNameMap = (subTyNameMap, subVarNameMap, subStrNameMap)
                 },
             strEnv
           ) =>
           let
             val newSubTyEnv = reconstructTyEnv (tyConEnv, subTyNameMap)
             val newSubVarEnv = reconstructVarEnv (varEnv, subVarNameMap)
             val newSubStrEnv =
                 reconstructStrEnv (varEnv, tyConEnv, subStrNameMap)
           in
             SEnv.insert
                 (
                   strEnv, 
                   strName,
                   TY.STRUCTURE
                       {
                          name = name,
                          strpath = parentPath,
                          wrapperSysStructure = wrapperSysStructure,
                          env = (newSubTyEnv, newSubVarEnv, newSubStrEnv)
                       }
                 )
           end)
          SEnv.empty
          strNameMap

  local
    fun encloseList formatList =
        case formatList of
          [] => []
        | [format] => format
        | _ =>
          FE.Term(1, "(")
          :: (List.concat
                  (U.interleave [FE.Term(1, ","), U.s_d_Indicator] formatList))
          @ [FE.Term(1, ")")]
  in
  fun formatTyVarNames tyVarNames =
      encloseList tyVarNames

  fun formatBTVMap BTVMap =
      let
        val BTVIndexes = map TY.BOUNDVARty (BoundTypeVarID.Map.listKeys BTVMap)
        val formatEnv = TermFormat.extendBtvEnv TermFormat.emptyBtvEnv BTVMap
        val formattedNames = map (TY.format_ty formatEnv) BTVIndexes
      in
        encloseList formattedNames
      end
  end

  fun formatTy path ty =
      let
        (* NOTE: system strpath is stripped everytime when formatTy is called.
         * It seems inefficient.
         *)
        val ty = TypesUtils.stripSysStrpathTy ty
        val path = Path.pathToUsrPath path
        val newTy = U.makePathOfTyRelative path ty
        val newTy = TypesUtils.stripSysStrpathTy newTy
        val expressions = TY.format_ty [] newTy
      in
        expressions
      end

(*
        (* ToDo : this is temporary code until smlpplib can be compiled. *)
        val tyString = TypeFormatter.tyToString newTy
(*
val _ = print ("formatTy: " ^ tyString ^ "\n")
*)
      in
        [FE.Term(size tyString, tyString)]
      end
*)
  fun formatTyUnderBTV path BTVs ty =
      let
        val newTy = U.makePathOfTyRelative path ty
        val formatEnv = TermFormat.extendBtvEnv TermFormat.emptyBtvEnv BTVs
        val expressions = TY.format_ty formatEnv (TypesUtils.stripSysStrpathTy newTy)
      in expressions end
(*
        val tyString = OC.FEToString expressions
      in [FE.Term(size tyString, tyString)] end
*)

  fun tyvarsToNames tyvars =
      map
          (fn (index, eq) =>
              TY.format_eqKind (BF.format_string (TermFormat.ftvName index)) eq)
          (ListPair.zip (List.tabulate (length tyvars, fn n => n), tyvars))
     

  fun formatAbstype path (tyCon : TY.tyCon) =
      let
        val tyVarNames = tyvarsToNames (#tyvars tyCon)
        val tyVarsExpressions = formatTyVarNames tyVarNames
        val codes = 
            [FE.Term(7, "abstype"), U.s_d_Indicator]
            @ tyVarsExpressions
            @ (if null tyVarNames then [] else [U.s_d_Indicator])
            @ [FE.Term(size (#name tyCon), #name tyCon)]
      in codes end

  fun generatePrintCodeForVals context path loc varInfos =
      let
        (* ToDo : hidden or not cannot decided here ?
         *   Because within a val declaration, each name must be unique. *)
        (* boundVarNames is used to determine whether each binding is hidden
         * by another binding of the same name
         *)
        val (declarationsMap, _) =
            foldr
            (fn (varInfo as {namePath,ty}, (declarationsMap, boundVarNames)) =>
                let
                  val printCode =
                      generatePrintCodeForVal
                          context path boundVarNames loc varInfo
                  val newDeclarationsMap =
                      SEnv.insert
                          (
                            declarationsMap,
                            NM.namePathToString namePath,
                            printCode
                          )
                in
                  (
                    newDeclarationsMap,
                    NM.namePathToString(namePath) :: boundVarNames
                  )
                end)
            (SEnv.empty, [])
            varInfos
      in declarationsMap
      end

  (* this function should be only for global val binding. *)
  and generatePrintCodeForVal
          context path boundVarNames loc ({namePath, ty, ...}) =
      let
        (* ToDo : print "<hidden>" if it is hidden. *)
        val isHiddenBinding =
            List.exists
                (fn boundVarName =>
                    boundVarName = NM.namePathToString(namePath))
                boundVarNames

        (* If ty is polymorphic, instantiate it before passed to formatter.
         * Formatter to be generated is also for the instantiated type.
         *)
        val (varExp, varTy) =
            U.instantiateExp
                (TP.TPVAR({namePath = namePath, ty = ty}, loc), ty)

        (* exp which formats type expresion. *)
        val formatTypeExp =
(*
            OC.concatFormatExpressions
                (OC.translateFormatExpressions (formatTy path ty))
*)
          (* the following procedure is the same as the one performed
             in FG.generateFormatCode to decided whether the type is hidden
             or not.
           *)
          case  U.getRealTy varTy of 
             TY.RAWty{tyCon, ... } =>
             if U.isHiddenTyCon context path tyCon then
               OC.makeConstantTerm
                 ("hidden(" ^ (OC.FEToString (formatTy path ty)) ^ ")")
             else                                                                    
               OC.preformat (formatTy path ty)
           | _ => OC.preformat (formatTy path ty)
(*
            OC.makeConstantTerm "<ty>"
*)

        (* exp which formats value. *)
        val formatValueExp =
            FG.generateFormatCode context path NONE [] [] loc (varExp, varTy)

        val printExp =
            TP.TPSEQ
            {
              expList =
              [
                OC.printFormatOfValBinding
                    (
                      NM.namePathToUsrNamePath namePath,
                      formatValueExp,
                      formatTypeExp,
                      loc
                    ),
                OC.printString ("\n", loc)
              ],
              expTyList = [PT.unitty, PT.unitty],
              loc = loc
            }
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  fun formatConstructor path (TY.CONID{namePath, ty, ...}) = 
      let
          val name = NM.usrNamePathToString namePath
      in
        [
          FE.Guard
              (
                NONE,
                [
                  FE.Term(3, "con"),
                  U.s_d_Indicator,
                  FE.Term(size name, name),
                  U.s_d_Indicator,
                  FE.Term(1, ":"),
                  U.s_1_Indicator
                ]
                @ (formatTy path ty)
              )
        ]
      end
    | formatConstructor _ _ =
      raise
        Control.Bug
            "non CONID to formatConstructor \
             \(printergeneration/main/PrintCodeGenerator.sml)"


  fun formatDataTyInfo path (dataTyInfo : TY.dataTyInfo) =
      let
        val header = if #abstract (#tyCon dataTyInfo) then "type" else "datatype"
        val formattedConstructors =
            if #abstract (#tyCon dataTyInfo)
            then []
            else
              map (formatConstructor path) (SEnv.listItems ((#datacon dataTyInfo)))
        val tyVarNames = tyvarsToNames (#tyvars (#tyCon dataTyInfo))
        val tyVarsExpressions = formatTyVarNames tyVarNames
        val formattedDatatype =
            [
              FE.Guard
                  (
                    NONE,
                    [FE.Term(size header, header), U.s_d_Indicator]
                    @ tyVarsExpressions
                    @ (if null tyVarNames then [] else [U.s_d_Indicator])
                    @ [FE.Term(size (#name (#tyCon dataTyInfo)), #name (#tyCon dataTyInfo))]
                  )
            ]

        (* NOTE: this function a list of lists of format expressions *)
        val codes = (formattedDatatype :: formattedConstructors)
      in
        codes
      end


  fun formatTyCon
          path
          ({name, id, eqKind, tyvars, ...} : TY.tyCon) =
      let
        val tyVarNames = tyvarsToNames tyvars
        val tyVarsExpressions = formatTyVarNames tyVarNames
        val header =
            case !eqKind of Types.EQ => "eqtype" | Types.NONEQ => "type"
        val formatted =
            [
              FE.Guard
                  (
                    NONE,
                    [FE.Term(size header, header), U.s_d_Indicator]
                    @ tyVarsExpressions
                    @ (if null tyVarNames then [] else [U.s_d_Indicator])
                    @ [FE.Term(size name, name)]
                  )
            ]
      in
        formatted
      end

  fun generatePrintCodeForDatatype context path loc (dataTyInfo : TY.dataTyInfo) =
      let
        val formattedTyCon = formatDataTyInfo path dataTyInfo
        val codes =
            List.concat
            (map
                (fn formatted =>
                    [
                      OC.printFormatStatic formatted,
                      OC.printString ("\n", loc)
                    ])
                formattedTyCon)
      in
        makeSeqExp codes loc
      end

  fun generatePrintCodeForDatatypes context path loc tyCons =
      let
        val printCodes =
            map (generatePrintCodeForDatatype context path loc) tyCons
        val printExp = makeSeqExp printCodes loc
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  fun formatDatatypeReplication
          path (leftDataTyInfo, rightName, rightDataTyInfo) =
      let
        val leftName = #name (#tyCon (leftDataTyInfo : TY.dataTyInfo))
        val codes = 
            [
              FE.Term(8, "datatype"),
              U.s_d_Indicator,
              FE.Term(size leftName, leftName),
              U.s_d_Indicator,
              FE.Term(1, "="),
              U.s_d_Indicator,
              FE.Term(8, "datatype"),
              U.s_d_Indicator,
              FE.Term(size rightName, rightName)
            ]
      in codes end

  fun generatePrintCodeForDatatypeReplication
          context
          path
          loc
          (
            leftDataTyInfo,
            (leftPath, tyConName),
            rightDataTyInfo
          ) =
      let
        val rightName = U.namePathToPrintString (tyConName, leftPath)
        val codes = 
            [
              OC.printFormatStatic
                  (formatDatatypeReplication
                       path (leftDataTyInfo, rightName, rightDataTyInfo)),
              OC.printString ("\n", loc)
            ]
        val printExp = makeSeqExp codes loc
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  fun generatePrintCodeForAbstype context path loc (dataTyInfo : TY.dataTyInfo) =
      let
        val codes = 
            [
             OC.printFormatStatic (formatAbstype path (#tyCon dataTyInfo)),
             OC.printString ("\n", loc)
            ]
      in
        makeSeqExp codes loc
      end

  fun generatePrintCodeForAbstypes context path loc tyCons =
      let
        val printCodes =
            map (generatePrintCodeForAbstype context path loc) tyCons
        val printExp = makeSeqExp printCodes loc
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  (***************************************************************************)

(*
  fun generatePrintCodeForOpen context currentPath loc strPathInfos =
      let
        fun generatePrintCodeForOpenOne
                ({(*strpath,*) name, (*id,*) ...} : TY.strPathInfo) =
            let
              (* strpath in strPathInfo is absotlute.
               * But relative path should be printed.
               *)
              val codes = 
                  [
                    OC.printFormatStatic 
                        [
                          FE.Term(4, "open"),
                          U.s_d_Indicator,
                          FE.Term(size name, name)
                        ],
                    OC.printString ("\n", loc)
                  ]
              val printExp = makeSeqExp codes loc
            in
              TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
            end
      in
        TP.TPLOCALDEC(map generatePrintCodeForOpenOne strPathInfos, [], loc)
      end
*)

  fun generatePrintCodeForIntro loc strPath =
      let
        val name = Path.usrPathToString strPath
        val codes = 
            [
              OC.printFormatStatic 
                  [
                    FE.Term(4, "open"),
                    U.s_d_Indicator,
                    FE.Term(size name, name)
                  ],
              OC.printString ("\n", loc)
            ]
        val printExp = makeSeqExp codes loc
      in
        TP.TPLOCALDEC
            ([TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)], [], loc)
      end

  fun generatePrintCodeForExnBind context path loc (TP.TPEXNBINDDEF conInfo) =
      let
        val conName = NM.usrNamePathToString(#namePath conInfo)
        val conTy = #ty conInfo
        val codes =
            [
              OC.printFormatStatic 
                  ([
                     FE.Term(9, "exception"),
                     U.s_d_Indicator,
                     FE.Term(size conName, conName),
                     U.s_d_Indicator,
                     FE.Term(1, ":"),
                     U.s_1_Indicator
                   ] @
                   (formatTy path conTy)),
              OC.printString ("\n", loc)
            ]
      in
        makeSeqExp codes loc
      end

    | generatePrintCodeForExnBind
          context
          path
          loc
          (TP.TPEXNBINDREP(leftNamePath, (rightNamePath))) =
      let
        val leftName = NM.usrNamePathToString leftNamePath
        val rightName = NM.usrNamePathToString rightNamePath
        val codes = 
            [
              OC.printFormatStatic 
                  [
                    FE.Term(9, "exception"),
                    U.s_d_Indicator,
                    FE.Term(size leftName, leftName),
                    U.s_d_Indicator,
                    FE.Term(1, "="),
                    U.s_d_Indicator,
                    FE.Term(size rightName, rightName)
                  ],
              OC.printString ("\n", loc)
            ]
        val printExp = makeSeqExp codes loc
      in
        printExp
      end

  fun generatePrintCodeForExnBinds context path loc exnBinds =
      let
        val printCodes =
            map (generatePrintCodeForExnBind context path loc) exnBinds
        val printExp = makeSeqExp printCodes loc
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  fun formatTyFun path ({tyargs, name, strpath, body} : TY.tyFun) =
      let
(*
        val codes = 
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions
                ([FE.Term(4, "type"), U.s_d_Indicator] @
                 TY.format_tyBindInfo [] tyBind))),
              OC.printString(TP.TPCONSTANT(CT.STRING("\n")))
            ]
*)
        (* If the tyFun is generated from a declaration "type t = ty", the
         * body is ALIASty(t, ty). It is ty which is to be printed.
         * NOTE: Not use TU.derefTy because it strip ALIASty as possible.
         *     For example, if t1 and t2 are declared as follows,
         *        type t1 = ty
         *        type t2 = t1
         *     TU.derefTy(t2) returns ty, which we do not want.
         *)
        val actualTy = case body of TY.ALIASty(_, actual) => actual | _ => body

        val formattedTyVarNames = formatBTVMap tyargs
        
        val tyFunName = name

        val formattedTyFun =
            [
              FE.Guard
              (
                NONE,
                [FE.Term(4, "type"), U.s_d_Indicator]
                @ formattedTyVarNames
                @ (if 0 = BoundTypeVarID.Map.numItems tyargs
                   then [] else [U.s_d_Indicator])
                @ [
                    FE.Term(size tyFunName, tyFunName),
                    U.s_d_Indicator,
                    FE.Term(1, "="),
                    U.s_d_Indicator
                  ]
                @ formatTyUnderBTV path tyargs actualTy
              )
            ]
      in
        formattedTyFun
      end

  fun generatePrintCodeForType context path loc (TY.TYFUN tyFun) =
      let
        val codes = 
            [
              OC.printFormatStatic (formatTyFun path tyFun),
              OC.printString ("\n", loc)
            ]

        val printExp = makeSeqExp codes loc
      in
        printExp
      end
    | generatePrintCodeForType _ _ _ _ =
      raise
        Control.Bug
            "non TYFUN to generatePrintCodeForType \
            \(printergeneration/main/PrintCodeGenerator.sml)"      

  fun generatePrintCodeForTypes context path loc binds = 
      let
        val printCodes = map (generatePrintCodeForType context path loc) binds
        val printExp = makeSeqExp printCodes loc
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  (***************************************************************************)

  fun generatePrintCodeForInfix context path loc (fixity, names) =
      let
        val header =
            case fixity of
              Fixity.INFIX n =>
              let val s = Int.toString n
              in [FE.Term(5, "infix"), U.s_d_Indicator, FE.Term(size s, s)]
              end
            | Fixity.INFIXR n =>
              let val s = Int.toString n
              in [FE.Term(6, "infixr"), U.s_d_Indicator, FE.Term(size s, s)]
              end
            | Fixity.NONFIX => [FE.Term(6, "nonfix")]
        val formattedNames =
            BF.format_list (BF.format_string, [U.s_d_Indicator]) names
        val codes = 
            [
              OC.printFormatStatic 
                (header @ [U.s_d_Indicator] @ formattedNames),
              OC.printString ("\n", loc)
            ]
        val printExp = makeSeqExp codes loc
      in
        TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], loc)
      end

  local
    fun concatFormatsList formats =
        List.concat(U.interleave [U.s_1_Indicator] formats)

    fun formatEnv path ((tyConEnv, varEnv) : TY.Env) =
        let
          val formattedTyConEnv = formatTyConEnv path tyConEnv
          val formattedVarEnv = formatVarEnv path varEnv
          val formattedEnv =
              List.concat
                  (U.interleave
                       [U.s_1_Indicator]
                       (List.filter (not o List.null)
                       [formattedTyConEnv, formattedVarEnv]))
        in
          [
            FE.Guard
            (
              NONE,
              [FE.Term(3, "sig"), FE.StartOfIndent 2]
              @ (if List.null formattedEnv then [] else [U.s_1_Indicator])
              @ formattedEnv
              @ [FE.EndOfIndent, U.s_1_Indicator, FE.Term(3, "end")]
            )
          ]
        end

    and formatInnerStrEnv path (tyConEnv, varEnv, strEnv) =
        let
          val formattedTyConEnv = formatTyConEnv path tyConEnv
          val formattedVarEnv = formatVarEnv path varEnv
          val formattedStrEnv = formatStrEnv path strEnv 
          val formattedEnv =
              List.concat
                  (U.interleave
                       [U.s_1_Indicator]
                       (List.filter
                            (not o List.null)
                            [
                              formattedTyConEnv,
                              formattedVarEnv,
                              formattedStrEnv
                            ]))
        in
          [
            FE.Guard
            (
              NONE,
              [FE.Term(3, "sig"), FE.StartOfIndent 2]
              @ (if List.null formattedEnv then [] else [U.s_1_Indicator])
              @ formattedEnv
              @ [FE.EndOfIndent, U.s_1_Indicator, FE.Term(3, "end")]
            )
          ]
        end

    and formatTyConEnv path tyConEnv =
        concatFormatsList
            (map (formatTyBindInfo path) (NPEnv.listItems tyConEnv))
    and formatVarEnv path varEnv =
        let
          (* exclude constructor bindings, because they are printed with
           * tyCon. *)
          fun isExnCon (conPathInfo : TY.conPathInfo) =
              TyConID.eq(#id (#tyCon conPathInfo), #id PT.exnTyCon)
          val nameIdStates =
              List.filter
                  (fn (name, TY.CONID conPathInfo) => isExnCon conPathInfo
                    | _ => true)
                  (NPEnv.listItemsi varEnv)
        in
            concatFormatsList(map (formatNameIDState path) nameIdStates)
        end
    and formatStrEnv path strEnv =
        (* NOTE: pass keys with items, because strEnvEntry does not contain
         * bound name. *)
        concatFormatsList
            (map (formatStrEnvEntry path) (SEnv.listItemsi strEnv))

    and formatTyBindInfo path (TY.TYCON dataTyInfo) =
        concatFormatsList(formatDataTyInfo path dataTyInfo)
      | formatTyBindInfo path (TY.TYFUN tyFun) = formatTyFun path tyFun
      | formatTyBindInfo path (TY.TYSPEC tyCon) =
        formatTyCon path tyCon
      | formatTyBindInfo path (TY.TYOPAQUE {spec = tyCon, impl}) =
        formatTyCon path tyCon

    and formatNameIDState path (namePath, idState) =
        let
          val name = NM.usrNamePathToString(namePath)
          val ty =
              case idState of
                (TY.VARID varPathInfo) => #ty varPathInfo
              | (TY.PRIM primInfo) => #ty primInfo
              | (TY.OPRIM oprimInfo) => #oprimPolyTy oprimInfo
              | (TY.CONID conPathInfo) => #ty conPathInfo
              | (TY.EXNID conPathInfo) => #ty conPathInfo
              | (TY.RECFUNID (varPathInfo, int)) => #ty varPathInfo
          val header = case idState of (TY.EXNID _) => "exception" 
                                     | _ => "val"
        in
          [
            FE.Guard
                (
                  NONE,
                  [
                    FE.Term(size header, header), U.s_d_Indicator,
                    FE.Term(size name, name), U.s_d_Indicator,
                    FE.Term(1, ":"), U.s_1_Indicator
                  ]
                  @ (formatTy path ty)
                )
          ]
        end
    and formatIDState path idState =
        let
          (* NOTE: CONID is expected to be exception constructor. *)
          val (name, ty) =
              case idState of
                (TY.VARID varPathInfo) =>
                (
                  NM.usrNamePathToString(#namePath varPathInfo),
                  #ty varPathInfo
                )
              | (TY.PRIM primInfo) =>
                (Control.prettyPrint
                   (BuiltinPrimitive.format_prim_or_special
                      (#prim_or_special primInfo)),
                 #ty primInfo)
              | (TY.OPRIM oprimInfo) =>
                (#name oprimInfo, #oprimPolyTy oprimInfo)
              | (TY.CONID conPathInfo) =>
                (
                  NM.usrNamePathToString(#namePath conPathInfo), 
                  #ty conPathInfo
                )
              | (TY.EXNID conPathInfo) =>
                (
                  NM.usrNamePathToString(#namePath conPathInfo),
                  #ty conPathInfo
                )
              | (TY.RECFUNID _) => 
                raise
                  Control.Bug
                      "RECFUNID to formatIDState \
                      \(printergeneration/main/PrintCodeGenerator.sml)" 
          val header = case idState of (TY.CONID _) => "exception" | _ => "val"
        in
          [
            FE.Guard
                (
                  NONE,
                  [
                    FE.Term(size header, header), U.s_d_Indicator,
                    FE.Term(size name, name), U.s_d_Indicator,
                    FE.Term(1, ":"), U.s_1_Indicator
                  ]
                  @ (formatTy path ty)
                )
          ]
        end
    and formatStrEnvEntry
            path
            (strName, TY.STRUCTURE ({name, env, wrapperSysStructure, ...})) =
        let
          val innerPath = 
              case wrapperSysStructure of
                  NONE => Path.appendUsrPath(path, name)
                | SOME sysName => 
                  Path.appendUsrPath (Path.appendSysPath(path, sysName), name)
        in
          [
            FE.Guard
            (
              NONE,
              [
                FE.Term(9, "structure"), U.s_d_Indicator,
                FE.Term(size name, name), U.s_1_Indicator,
                FE.Term(1, ":"), U.s_d_Indicator
              ]
              @ (formatInnerStrEnv innerPath env)
            )
          ]
        end

(*
    fun formatSigExp currentPath (TP.TPMSIGEXPBASIC spec) =
        let
          val formattedSpecs = (formatSpec currentPath) spec
        in
          [
            FE.Guard
            (
              NONE,
              [FE.Term(3, "sig"), FE.StartOfIndent 2]
              @ (case formattedSpecs of
                   [] => [] | _ => (U.s_1_Indicator :: formattedSpecs))
              @ [FE.EndOfIndent, U.s_1_Indicator, FE.Term(3, "end")]
            )
          ]
        end
      | formatSigExp currentPath (TP.TPMSIGID name) =
        [FE.Term(size name, name)]
      | formatSigExp currentPath (TP.TPMSIGWHERE(sigExp, wheres)) =
        let
          val formattedSigExp = formatSigExp currentPath sigExp
          fun formatWhereClause (path, {name, tyargs, body}) =
              let
                val fullName = U.pathNameToString(path, name)
                val tyFun = {name = fullName, tyargs = tyargs, body = body}
              in
                [FE.Term(5, "where"), U.s_d_Indicator]
                @ (formatTyFun currentPath tyFun)
              end
        in
          concatFormatsList(formattedSigExp :: (map formatWhereClause wheres))
        end

    and formatSpec currentPath TP.TPSPECERROR =
        raise Control.Bug "TPSPECERROR to formatSpec  (printergeneration/main/PrintCodeGenerator.sml)" 
      | formatSpec currentPath (TP.TPSPECVAL varInfos) =
        concatFormatsList
            (map (formatIDState currentPath o TY.VARID) varInfos)
      | formatSpec currentPath (TP.TPTYPEEQUATION bindInfo) =
        concatFormatsList([formatTyBindInfo currentPath bindInfo])
      | formatSpec currentPath (TP.TPSPECTYPE tySpecs) =
        concatFormatsList(map (formatTySpec currentPath) tySpecs)
      | formatSpec currentPath (TP.TPSPECEQTYPE tySpecs) =
        concatFormatsList(map (formatTySpec currentPath) tySpecs)
      | formatSpec currentPath (TP.TPSPECDATATYPE tyCons) =
        concatFormatsList
            (map (concatFormatsList o (formatTyCon currentPath)) tyCons)
      | formatSpec
            currentPath
            (TP.TPSPECREPLIC {left, right = {name, tyCon}}) =
        formatDatatypeReplication currentPath (left, name, tyCon)
      | formatSpec currentPath (TP.TPSPECEXCEPTION conPathInfos) =
        concatFormatsList
            (map (formatIDState currentPath o TY.CONID) conPathInfos)
      | formatSpec currentPath (TP.TPSPECSEQ(leftSpec, rightSpec)) =
        (formatSpec currentPath leftSpec)
        @ [U.s_1_Indicator]
        @ (formatSpec currentPath rightSpec)
      | formatSpec currentPath (TP.TPSPECSHARE(spec, paths)) =
        let
          val formattedSpec = formatSpec currentPath spec
          fun formatPath (name, strPath) =
              let val string = U.namePathToPrintString (name, strPath)
              in [FE.Term(size string, string)] end
        in
          formattedSpec
          @ [
              U.s_1_Indicator,
              FE.Term(7, "sharing"),
              U.s_d_Indicator,
              FE.Term(4, "type"),
              U.s_d_Indicator,
              FE.Guard
              (
                NONE, 
                List.concat
                    (U.interleave
                         [U.s_d_Indicator, FE.Term(1, "="), U.s_1_Indicator]
                         (map formatPath paths))
              )
            ]
        end
      | formatSpec currentPath TP.TPSPECEMPTY = [] 
*)

    (** get the constraint signature of a strExp.
     * @return <ul>
     * <li>SOME sigExp) - if a constraint</li>
     * <li>NONE - if no constraint</li>
     *)
(*    fun getConstraintOfStrExp (TP.TPOPAQCONS(_, sigExp, _, _)) = SOME sigExp
      | getConstraintOfStrExp (TP.TPTRANCONS(_, sigExp, _, _)) = SOME sigExp
      | getConstraintOfStrExp (TP.TPFUNCTORAPP _ ) = NONE
      | getConstraintOfStrExp (TP.TPLET(_, strExp,_)) =
        getConstraintOfStrExp strExp
      | getConstraintOfStrExp _ = NONE
*)
  fun formatPlTy plTy = 
      let
          val plTyString = AbsynFormatter.tyToString plTy
      in
          [FE.Term(size plTyString, plTyString)]
      end

  and formatTvars plTvars =
      case plTvars of
        nil => nil
      | [tvar] =>
        let
          val tvarString = AbsynFormatter.tvarToString tvar
        in
          [FE.Term(size tvarString, tvarString)]
        end
      | tvars => 
        let
          fun tyvarsToFormat nil formats = formats
            | tyvarsToFormat (h::nil) formats = 
              let
                val tvarString = AbsynFormatter.tvarToString h
              in
                formats
                @ [FE.Term(1, ","), FE.Term(size tvarString, tvarString)] 
              end
            | tyvarsToFormat (h::t) formats = 
              let
                val tvarString = AbsynFormatter.tvarToString h
              in
                case formats of
                  nil => 
                  tyvarsToFormat t [FE.Term(size tvarString, tvarString)]
                | _ => 
                  tyvarsToFormat
                      t
                      (formats
                       @ [
                           FE.Term(1, ","),
                           FE.Term(size tvarString, tvarString)
                         ])
              end
        in
          [FE.Term(1, "(")] @ tyvarsToFormat tvars nil @ [FE.Term(1, ")")]
        end

  and formatPlSpec plSpec = 
      case plSpec of
        PL.PLSPECVAL (_, stringTyList, _) =>
        let
          fun formatStringTy (string, ty) =
              [
                FE.Guard
                    (
                      NONE,
                      [
                        FE.Term(3, "val"), U.s_d_Indicator,
                        FE.Term(size string, string), U.s_d_Indicator,
                        FE.Term(1, ":"), U.s_1_Indicator
                      ]
                      @ (formatPlTy ty)
                    )
              ]
        in
          concatFormatsList (map formatStringTy stringTyList)
        end
      | PL.PLSPECTYPE {tydecls=tvarsStringList, iseq, loc,...} =>
        let
          fun basic pad name =
              [
                FE.Guard
                    (
                      NONE,
                      (if iseq then [FE.Term(4, "eqtype")]
                       else [FE.Term(4, "type")])
                      @ pad @
                      [U.s_d_Indicator, FE.Term(size name, name)]
                    )
              ]
          fun formatStringTy (tyvars, name) =
              let
                val formattedTyvars = formatTvars tyvars
              in
                case formattedTyvars of
                  nil => basic nil name
                | formatted => basic ([U.s_d_Indicator] @ formatted) name
              end
        in
          concatFormatsList (map formatStringTy tvarsStringList)
        end
      | PL.PLSPECTYPEEQUATION ((tyvars, name, ty), loc) =>
        let
          fun basic pad =
              [
                FE.Guard
                    (
                      NONE,
                      [FE.Term(4, "type")]
                      @ pad
                      @ [
                          U.s_d_Indicator, 
                          FE.Term(size name, name),
                          U.s_d_Indicator,
                          FE.Term(1, "="),
                          U.s_d_Indicator
                        ]
                      @ (formatPlTy ty)
                    )
              ]
          val formattedTyvars = formatTvars tyvars
        in
          case formattedTyvars of
            nil => basic nil
          | formatted => basic ([U.s_d_Indicator] @ formatted)
        end
      | PL.PLSPECDATATYPE (tvarListtyNameConNameTyOptList_List, loc) =>
        let
          fun formatConNameTyOpt (conName, tyOpt) endFlag =
              let
                fun appendSep prefix=
                    prefix
                    @ (if endFlag
                       then nil
                       else
                         [U.s_d_Indicator, FE.Term(1, "|"), U.s_d_Indicator])
              in
                case tyOpt of
                  NONE => appendSep [FE.Term(size conName, conName)]
                | SOME ty => 
                  appendSep
                      (FE.Term(size conName, conName)
                       :: U.s_d_Indicator
                       :: FE.Term(2, "of")
                       :: U.s_d_Indicator
                       :: formatPlTy ty)
              end

          fun formatCons (c :: nil) = formatConNameTyOpt c true
            | formatCons (c :: rem) = 
              (formatConNameTyOpt c false) @ (formatCons rem)
            | formatCons _ = raise Control.Bug "no constructors(formatCons)"
             
          fun formatDataType (tvarList, tyName, conNameTyOptList) =
              let
                val formattedTvars = formatTvars tvarList
                val formattedConNameTyOptList = (formatCons conNameTyOptList)
              in
                case formattedTvars of
                  nil =>
                  [
                    FE.Guard
                        (
                          NONE,
                          FE.Term(8, "datatype")
                          :: U.s_d_Indicator
                          :: FE.Term(size tyName, tyName)
                          :: U.s_d_Indicator
                          :: FE.Term(1, "=")
                          :: U.s_d_Indicator
                          :: formattedConNameTyOptList
                        )
                  ]
                | _ => 
                  [
                    FE.Guard
                        (
                          NONE,
                          [FE.Term(8, "datatype"), U.s_d_Indicator]
                          @ formattedTvars
                          @ [
                              U.s_d_Indicator,
                              FE.Term(size tyName, tyName), 
                              U.s_d_Indicator,
                              FE.Term(1, "="),
                              U.s_d_Indicator
                            ]
                          @ formattedConNameTyOptList
                        )
                  ]
              end
        in
          concatFormatsList
              (map formatDataType tvarListtyNameConNameTyOptList_List)
        end
      | PL.PLSPECREPLIC (string, longid, loc) =>
        let
          val rightString = Absyn.longidToString(longid)
        in
          [
            FE.Guard
                (
                  NONE,
                  [
                    FE.Term(6, "datatype"),
                    U.s_d_Indicator,
                    FE.Term(size string, string),
                    U.s_d_Indicator,
                    FE.Term(1, "="),
                    U.s_d_Indicator,
                    FE.Term(6, "datatype"),
                    U.s_d_Indicator,
                    FE.Term(size rightString, rightString)
                  ]
                )
          ]
        end
      | PL.PLSPECEXCEPTION (exceptionList, loc) =>
        let
          fun formatStringTyOpt (string, tyOpt) =
              case tyOpt of
                NONE =>
                [
                  FE.Guard
                      (
                        NONE,
                        [
                          FE.Term(9, "exception"), 
                          U.s_d_Indicator,
                          FE.Term(size string, string)
                        ]
                      )
                ]
              | SOME plty =>
                [
                  FE.Guard
                      (
                        NONE,
                        FE.Term(9, "exception")
                        :: U.s_d_Indicator
                        :: FE.Term(size string, string)
                        :: U.s_d_Indicator
                        :: FE.Term(2, "of")
                        :: U.s_d_Indicator
                        :: formatPlTy plty
                      )
                ]
        in
          concatFormatsList (map formatStringTyOpt exceptionList)
        end
      | PL.PLSPECSTRUCT (strNameSigExpList, loc) =>
        let
          fun formatStructure (strName, sigExp) =
              [
                FE.Guard
                    (
                      NONE,
                      FE.Term(9, "structure")
                      :: U.s_d_Indicator
                      :: FE.Term(size strName, strName)
                      :: U.s_d_Indicator
                      :: FE.Term(1, ":")
                      :: U.s_1_Indicator
                      :: formatPlSigExp sigExp
                    )
              ]
        in
          concatFormatsList(map formatStructure strNameSigExpList)
        end
      | PL.PLSPECINCLUDE (sigExp, loc) => 
        [
          FE.Guard
              (
                NONE,
                [FE.Term(7, "include"), U.s_1_Indicator]
                @ (formatPlSigExp sigExp)
              )
        ]
      | PL.PLSPECSEQ (plspec1, plspec2, loc) =>
        (formatPlSpec plspec1)
        @ [U.s_1_Indicator]
        @ (formatPlSpec plspec2)
      | PL.PLSPECSHARE (plspec, longIdList, loc) =>
        let
          val formattedSpec = formatPlSpec plspec
          fun formatLongId longId =
              let val string = Absyn.longidToString longId
              in [FE.Term(size string, string)] end
        in
          formattedSpec
          @ [
              U.s_1_Indicator,
              FE.Term(7, "sharing"),
              U.s_d_Indicator,
              FE.Term(4, "type"),
              U.s_d_Indicator,
              FE.Guard
              (
                NONE, 
                List.concat
                    (U.interleave
                         [U.s_d_Indicator, FE.Term(1, "="), U.s_1_Indicator]
                         (map formatLongId longIdList))
              )
            ]
        end
      | PL.PLSPECSHARESTR (plspec, longIdList, loc) =>
        let
          val formattedSpec = formatPlSpec plspec
          fun formatLongId longId =
              let val string = Absyn.longidToString longId
              in [FE.Term(size string, string)] end
        in
          formattedSpec
          @ [
              U.s_1_Indicator,
              FE.Term(7, "sharing"),
              U.s_d_Indicator,
              FE.Guard
                  (
                    NONE, 
                    List.concat
                        (U.interleave
                         [U.s_d_Indicator, FE.Term(1, "="), U.s_1_Indicator]
                         (map formatLongId longIdList))
                  )
            ]
        end
      | PL.PLSPECEMPTY => nil
  and formatPlSigExp plSigExp =
      case plSigExp of
          PL.PLSIGEXPBASIC (plspec, loc) =>
          let
            val formattedSpecs = formatPlSpec plspec
          in
            [
              FE.Guard
                  (
                    NONE,
                    [FE.Term(3, "sig"), FE.StartOfIndent 2]
                    @ (case formattedSpecs of
                           [] => [] | _ => (U.s_1_Indicator :: formattedSpecs))
                    @ [FE.EndOfIndent, U.s_1_Indicator, FE.Term(3, "end")]
                  )
            ]
          end
        | PL.PLSIGID (sigName, loc) => [FE.Term(size sigName, sigName)]
        | PL.PLSIGWHERE (plsigexp, wheres, loc) =>
          let
            val formattedSigExp = formatPlSigExp plsigexp
            fun basic pad name ty =
                [FE.Term(5, "where"), U.s_d_Indicator, FE.Term(4, "type")]
                @ pad
                @ [
                    U.s_d_Indicator,
                    FE.Term(size name, name),
                    U.s_d_Indicator,
                    FE.Term(2, "="),
                    U.s_d_Indicator
                  ]
                @ (formatPlTy ty)
            fun formatWhereClause  (tvars, longid, ty) =
                let
                  val formattedTyvars = formatTvars tvars
                  val name = Absyn.longidToString longid
                in
                  case formattedTyvars of
                    nil => basic nil name ty
                  | formatted => basic (U.s_d_Indicator :: formatted) name ty
                end
          in
            concatFormatsList
                (formattedSigExp :: (map formatWhereClause wheres))
          end
  in
  
  fun generatePrintCodeForStrEnv Env =
      let
        val structureCodes = formatStrEnv Path.NilPath Env
      in
        if structureCodes = nil
        then nil
        else
          let
            val formatted = [FE.Guard(NONE, structureCodes)]
            val printExp =
                TP.TPSEQ
                    {
                      expList =
                      [
                        OC.printFormatStatic formatted,
                        OC.printString ("\n", Loc.noloc)
                      ],
                      expTyList = [PT.unitty, PT.unitty],
                      loc = Loc.noloc
                    }
          in
            [
              TP.TPDECSTR
                  (
                    [
                      TP.TPCOREDEC
                          (
                            [
                              TP.TPVAL
                                  (
                                    [(TY.VALIDWILD PT.unitty, printExp)],
                                    Loc.noloc
                                  )
                            ],
                            Loc.noloc
                          )
                    ],
                    Loc.noloc
                  )
            ]
          end
      end

  fun generatePrintCodeForStrDec
          ({strName, topSigConstraint, strNameMap, basicTypeEnv = (tyConEnv, varEnv)}, loc)
      =
      let
        val formatted  = 
            case topSigConstraint
             of SOME sigExp =>             
                [
                  FE.Term(9, "structure"),
                  U.s_d_Indicator,
                  FE.Term(size strName, strName),
                  U.s_d_Indicator,
                  FE.Term(1, ":"),
                  U.s_1_Indicator
                ]
                @ formatPlSigExp sigExp
              | NONE => 
                formatStrEnv
                    Path.NilPath
                    (reconstructStrEnv (varEnv, tyConEnv, strNameMap))
        val printExp =
            TP.TPSEQ
                {
                  expList =
                  [
                    OC.printFormatStatic (formatted),
                    OC.printString ("\n", loc)
                  ],
                  expTyList = [PT.unitty, PT.unitty],
                  loc = loc
                }
      in
        [
          TP.TPCOREDEC
              (
                [TP.TPVAL([(TY.VALIDWILD PT.unitty, printExp)], Loc.noloc)],
                Loc.noloc
              )
        ]
    end

  fun generatePrintCodeForSigDecl
          context
          path
          loc
          (TY.SIGNATURE(_, {name, env, ...}), sigExpForPrint) =
      let
        val header = 
            [
              FE.Term(9, "signature"),
              U.s_d_Indicator,
              FE.Term(size name, name),
              U.s_d_Indicator,
              FE.Term(1, "="),
              U.s_1_Indicator
            ]

(*        val body = formatEnv innerPath env *)
            
        val body = (*formatSigExp innerPath sigExp*)
            formatPlSigExp sigExpForPrint
      in
        TP.TPSEQ
        {
          expList =
          [
            OC.printFormatStatic (header @ body),
            OC.printString ("\n", loc)
          ],
          expTyList = [PT.unitty, PT.unitty],
          loc = loc
        }
      end

  fun generatePrintCodeForSigDecls context path loc sigDecls =
      let
        val printCodes =
            map (generatePrintCodeForSigDecl context path loc) sigDecls
      in
        makeSeqExp printCodes loc
      end

  fun generatePrintCodeForFunDecl
          context
          path
          loc
          {
            funBindInfo = funBindInfo : TP.funBindInfo, 
            argName = argName, 
            argSpec = (sigExpForPrint, formalArgNamePathEnv), 
            bodyDec = (strExp, bodyNameMap:NameMap.basicNameMap, bodySigExpOpt)
          } =
      let
        val functorName = #funName funBindInfo
        val bodyEnv = #2((#body(#functorSig funBindInfo)))
        val innerPath =
            P.appendUsrPath(path, functorName)

        val parameterPath = P.appendUsrPath(innerPath, #argName funBindInfo)
        val formattedParameter = formatPlSigExp sigExpForPrint
        val formattedBody =
            case bodySigExpOpt of
              NONE =>
              let
                val (bodyTypeTyConEnv, bodyTypeVarEnv) = bodyEnv
                val funBodyNameMap = bodyNameMap
                val bodyTyConEnv =
                    reconstructTyEnv (bodyTypeTyConEnv, #1 funBodyNameMap)
                val bodyVarEnv =
                    reconstructVarEnv (bodyTypeVarEnv, #2 funBodyNameMap)
                val bodyStrEnv =
                    reconstructStrEnv
                        (bodyTypeVarEnv, bodyTypeTyConEnv, #3 funBodyNameMap)
              in 
                formatInnerStrEnv
                    Path.NilPath (bodyTyConEnv, bodyVarEnv, bodyStrEnv)
              end
            | SOME bodySigExp => formatPlSigExp bodySigExp
        val formatted =
            [
              FE.Term(9, "functor"),
              U.s_d_Indicator,
              FE.Term(size functorName, functorName),
              U.s_d_Indicator,
              FE.Term(1, "("),
              FE.Term(size argName, argName),
              U.s_d_Indicator,
              FE.Term(1, ":"),
              U.s_2_Indicator
            ]
            @ formattedParameter
            @ [
                FE.Term(1, ")"),
                U.s_d_Indicator,
                FE.Term(1, ":"),
                U.s_2_Indicator
              ]
            @ formattedBody
      in
        TP.TPSEQ
        {
          expList =
          [
            OC.printFormatStatic formatted,
            OC.printString ("\n", loc)
          ],
          expTyList = [PT.unitty, PT.unitty],
          loc = loc
        }
      end

  fun generatePrintCodeForFunDecls context path loc funDecls =
      let
        val printCodes =
            map (generatePrintCodeForFunDecl context path loc) funDecls
      in
        makeSeqExp printCodes loc
      end

  fun generatePrintCodeForImport context path loc spec =
      raise Control.Bug "to be done"
(* comment out by liu:
      let
        val currentPath = path (* ToDo : ? *)
(*
        val body = formatEnv innerPath env
*)
        val formatted =
            [
              FE.Guard
              (
                NONE,
                [FE.Term(7, "_import"), FE.StartOfIndent 2]
                @ (case (formatSpec currentPath) spec of
                     [] => []
                   | formattedSpecs => (U.s_1_Indicator :: formattedSpecs))
                @ [FE.EndOfIndent, U.s_1_Indicator, FE.Term(3, "end")]
              )
            ]
      in
        TP.TPSEQ
        {
          expList =
          [
            OC.printFormatStatic formatted,
            OC.printString(TP.TPCONSTANT(CT.STRING("\n"), PT.stringty, loc))
          ],
          expTyList = [PT.unitty, PT.unitty],
          loc = loc
        }
      end
*)
  end

  (***************************************************************************)
end
end
