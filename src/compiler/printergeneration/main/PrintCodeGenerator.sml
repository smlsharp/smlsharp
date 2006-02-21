(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This structure generates codes which print binding informations.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrintCodeGenerator.sml,v 1.24 2006/02/18 04:59:26 ohori Exp $
 *)
structure PrintCodeGenerator =
struct

  (***************************************************************************)

  structure BF = SMLFormat.BasicFormatters
  structure FE = SMLFormat.FormatExpression
  structure P = Path
  structure SE = StaticEnv
  structure TP = TypedCalc
  structure TPU = TypedCalcUtils
  structure TY = Types

  structure U = Utility
  structure FG = FormatterGenerator
  structure OC = ObjectCode

  (***************************************************************************)

  fun makeSeqExp codes loc = 
      TP.TPSEQ
      {expList = codes, expTyList = map (fn _ => OC.unitTy) codes, loc = loc}

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
      encloseList (map (fn name => [FE.Term(size name, name)]) tyVarNames)

  fun formatBTVMap BTVMap =
      let
        val BTVIndexes = IEnv.listKeys BTVMap
        val formattedNames = 
            map (TY.formatBoundtvar (fn x => x, [(0, BTVMap)])) BTVIndexes
      in
        encloseList formattedNames
      end
  end

  fun formatTy path ty =
      let
        val newTy = U.makePathOfTyRelative path ty
        (* ToDo : this is temporary code until smlpplib can be compiled. *)
        val tyString = TypeFormatter.tyToString newTy
(*
val _ = print ("formatTy: " ^ tyString ^ "\n")
*)
      in
        [FE.Term(size tyString, tyString)]
      end

  fun formatTyUnderBTV path BTVs ty =
      let
        val newTy = U.makePathOfTyRelative path ty
        val expressions = TY.format_ty [(0, BTVs)] newTy
      in expressions end
(*
        val tyString = OC.FEToString expressions
      in [FE.Term(size tyString, tyString)] end
*)

  fun tyvarsToNames tyvars =
      map
          (fn (index, isEq) =>
              (if isEq then "''" else "'") ^ Types.tyIdName index)
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
            (fn (varInfo as {name,ty}, (declarationsMap, boundVarNames)) =>
                let
                  val printCode =
                      generatePrintCodeForVal
                          context path boundVarNames loc varInfo
                  val newDeclarationsMap =
                      SEnv.insert(declarationsMap, name, printCode)
                in
                  (newDeclarationsMap, name :: boundVarNames)
                end)
            (SEnv.empty, [])
            varInfos
      in declarationsMap
      end

  (* this function should be only for global val binding. *)
  and generatePrintCodeForVal
          context path boundVarNames loc ({name, ty, ...}) =
      let
        (* ToDo : print "<hidden>" if it is hidden. *)
        val isHiddenBinding =
            List.exists (fn boundVarName => boundVarName = name) boundVarNames

        (* If ty is polymorphic, instantiate it before passed to formatter.
         * Formatter to be generated is also for the instantiated type.
         *)
        val (varTy, varExp) =
            TPU.freshInst
            (ty, TP.TPVAR({name = name, strpath = P.NilPath, ty = ty}, loc))

        (* exp which formats type expresion. *)
        val formatTypeExp =
            OC.concatFormatExpressions
                (OC.translateFormatExpressions (formatTy path ty))
        (* exp which is formatter for the type. *)
        val formatterExp =
            FG.generateFormatterOfTy context path [] [] loc varTy
        (* exp which formats value. *)
        val formatValueExp =
            TP.TPAPPM
                {
                  funExp = formatterExp, 
                  funTy = OC.formatterOfTyTy varTy, 
                  argExpList = [varExp], 
                  loc = loc
                }

        val stringOfName = "val " ^ name ^ " ="
        val printExp =
            TP.TPSEQ
            {
              expList =
              [
                OC.printFormat
                    (OC.concatFormatExpressions
                         ((OC.translateFormatExpressions
                               [
                                 FE.Term(size stringOfName, stringOfName),
                                 U.s_1_Indicator
                               ])
                          @ [formatValueExp]
                          @ (OC.translateFormatExpressions
                                 [U.s_1_Indicator, FE.Term(2, ": ")])
                          @ [formatTypeExp])),
                OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
              ],
              expTyList = [OC.unitTy, OC.unitTy],
              loc = loc
            }
      in
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  fun formatConstructor path (TY.CONID{name, ty, ...}) = 
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

  fun formatTyCon path (tyCon : TY.tyCon) =
      let
        val header = if #abstract tyCon then "type" else "datatype"
        val formattedConstructors =
            if #abstract tyCon
            then []
            else
              map (formatConstructor path) (SEnv.listItems (!(#datacon tyCon)))
        val tyVarNames = tyvarsToNames (#tyvars tyCon)
        val tyVarsExpressions = formatTyVarNames tyVarNames
        val formattedDatatype =
            [
              FE.Guard
                  (
                    NONE,
                    [FE.Term(size header, header), U.s_d_Indicator]
                    @ tyVarsExpressions
                    @ (if null tyVarNames then [] else [U.s_d_Indicator])
                    @ [FE.Term(size (#name tyCon), #name tyCon)]
                  )
            ]

        (* NOTE: this function a list of lists of format expressions *)
        val codes = (formattedDatatype :: formattedConstructors)
      in
        codes
      end

  fun formatTySpec
          path
          ({name, id, strpath, eqKind, tyvars, ...} : TY.tySpec) =
      let
        val tyVarNames = tyvarsToNames tyvars
        val tyVarsExpressions = formatTyVarNames tyVarNames
        val header =
            case eqKind of Types.EQ => "eqtype" | Types.NONEQ => "type"
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

  fun generatePrintCodeForDatatype context path loc (tyCon : TY.tyCon) =
      let
        val formattedTyCon = formatTyCon path tyCon
        val codes =
            List.concat
            (map
                (fn formatted =>
                    [
                      OC.printFormat
                          (OC.concatFormatExpressions
                               (OC.translateFormatExpressions formatted)),
                      OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
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
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  fun formatDatatypeReplication
          path (leftTyCon, (relativeStrPath,name), rightTyCon) =
      let
        val leftName = #name (leftTyCon : TY.tyCon)
        val rightName = U.pathNameToString (relativeStrPath, name)
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
            leftTyCon,
            relativePath as (relativeStrPath, tyConName),
            rightTyCon
          ) =
      let
        val rightName = U.pathNameToString (relativeStrPath, tyConName)
        val codes = 
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions
                (formatDatatypeReplication
                     path (leftTyCon, relativePath, rightTyCon)))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
            ]
        val printExp = makeSeqExp codes loc
      in
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  fun generatePrintCodeForAbstype context path loc (tyCon : TY.tyCon) =
      let
        val codes = 
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions(formatAbstype path tyCon))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
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
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  (***************************************************************************)

  fun generatePrintCodeForOpen context currentPath loc strPathInfos =
      let
        fun generatePrintCodeForOpenOne
                ({strpath, name, id, ...} : TY.strPathInfo) =
            let
              (* strpath in strPathInfo is absotlute.
               * But relative path should be printed.
               *)
              val (_, relativePath) =
                  P.removeCommonPrefix (currentPath, strpath)
              val name =
                  U.pathToString (Path.appendPath(relativePath, id, name))
              val codes = 
                  [
                    OC.printFormat
                    (OC.concatFormatExpressions
                     (OC.translateFormatExpressions
                          ([
                             FE.Term(4, "open"),
                             U.s_d_Indicator,
                             FE.Term(size name, name)
                           ]))),
                    OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
                  ]
              val printExp = makeSeqExp codes loc
            in
              TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
            end
      in
        TP.TPLOCALDEC(map generatePrintCodeForOpenOne strPathInfos, [], loc)
      end

  fun generatePrintCodeForExnBind context path loc (TP.TPEXNBINDDEF conInfo) =
      let
        val conName = #name conInfo
        val conTy = #ty conInfo
        val codes =
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions
                ([
                   FE.Term(9, "exception"),
                   U.s_d_Indicator,
                   FE.Term(size conName, conName),
                   U.s_d_Indicator,
                   FE.Term(1, ":"),
                   U.s_1_Indicator
                 ] @
                 (formatTy path conTy)))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
            ]
      in
        makeSeqExp codes loc
      end

    | generatePrintCodeForExnBind
          context
          path
          loc
          (TP.TPEXNBINDREP(leftName, (rightStrPath,rightName))) =
      let
        val rightName = U.pathNameToString (rightStrPath, rightName)
        val codes = 
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions
                ([
                   FE.Term(9, "exception"),
                   U.s_d_Indicator,
                   FE.Term(size leftName, leftName),
                   U.s_d_Indicator,
                   FE.Term(1, "="),
                   U.s_d_Indicator,
                   FE.Term(size rightName, rightName)
                 ]))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
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
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  fun formatTyFun path ({tyargs, name, body} : TY.tyFun) =
      let
(*
        val codes = 
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions
                ([FE.Term(4, "type"), U.s_d_Indicator] @
                 TY.format_tyBindInfo [] tyBind))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n")))
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

        val formattedTyFun =
            [
              FE.Guard
              (
                NONE,
                [FE.Term(4, "type"), U.s_d_Indicator]
                @ formattedTyVarNames
                @ (if 0 = IEnv.numItems tyargs then [] else [U.s_d_Indicator])
                @ [
                    FE.Term(size name, name),
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
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions (formatTyFun path tyFun))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
            ]

        val printExp = makeSeqExp codes loc
      in
        printExp
      end

  fun generatePrintCodeForTypes context path loc binds = 
      let
        val printCodes = map (generatePrintCodeForType context path loc) binds
        val printExp = makeSeqExp printCodes loc
      in
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  (***************************************************************************)

  fun generatePrintCodeForInfix context path loc (fixity, names) =
      let
        val header =
            case fixity of
              SE.INFIX n =>
              let val s = Int.toString n
              in [FE.Term(5, "infix"), U.s_d_Indicator, FE.Term(size s, s)]
              end
            | SE.INFIXR n =>
              let val s = Int.toString n
              in [FE.Term(6, "infixr"), U.s_d_Indicator, FE.Term(size s, s)]
              end
            | SE.NONFIX => [FE.Term(6, "nonfix")]
        val formattedNames =
            BF.format_list (BF.format_string, [U.s_d_Indicator]) names
        val codes = 
            [
              OC.printFormat
              (OC.concatFormatExpressions
               (OC.translateFormatExpressions
                (header @ [U.s_d_Indicator] @ formattedNames))),
              OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
            ]
        val printExp = makeSeqExp codes loc
      in
        TP.TPVAL([(TY.VALIDWILD OC.unitTy, printExp)], loc)
      end

  local
    fun concatFormatsList formats =
        List.concat(U.interleave [U.s_1_Indicator] formats)

    fun formatEnv path ((tyConEnv, varEnv, strEnv) : TY.Env) =
        let
          val formattedTyConEnv = formatTyConEnv path tyConEnv
          val formattedVarEnv = formatVarEnv path varEnv
          val formattedStrEnv = formatStrEnv path strEnv
          val formattedEnv =
              List.concat
                  (U.interleave
                       [U.s_1_Indicator]
                       (List.filter (not o List.null)
                       [formattedTyConEnv, formattedVarEnv, formattedStrEnv]))
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
            (map (formatTyBindInfo path) (SEnv.listItems tyConEnv))
    and formatVarEnv path varEnv =
        let
          (* exclude constructor bindings, because they are printed with
           * tyCon. *)
          fun isExnCon (conPathInfo : TY.conPathInfo) =
              #tyCon conPathInfo = SE.exnTyCon
          val idStates =
              List.filter
                  (fn TY.CONID conPathInfo => isExnCon conPathInfo
                    | _ => true)
                  (SEnv.listItems varEnv)
        in
          concatFormatsList(map (formatIDState path) idStates)
        end
    and formatStrEnv path strEnv =
        (* NOTE: pass keys with items, because strEnvEntry does not contain
         * bound name. *)
        concatFormatsList
            (map (formatStrEnvEntry path) (SEnv.listItemsi strEnv))
    and formatTyBindInfo path (TY.TYCON tyCon) =
        concatFormatsList(formatTyCon path tyCon)
      | formatTyBindInfo path (TY.TYFUN tyFun) = formatTyFun path tyFun
      | formatTyBindInfo path (TY.TYSPEC {spec = tySpec, impl}) =
        formatTySpec path tySpec
    and formatIDState path idState =
        let
          (* NOTE: CONID is expected to be exception constructor. *)
          val (name, ty) =
              case idState of
                (TY.VARID varPathInfo) => (#name varPathInfo, #ty varPathInfo)
              | (TY.PRIM primInfo) => (#name primInfo, #ty primInfo)
              | (TY.OPRIM oprimInfo) => (#name oprimInfo, #ty oprimInfo)
              | (TY.CONID conPathInfo) => (#name conPathInfo, #ty conPathInfo)
              | (TY.FFID foreignFunPathInfo) =>
                (#name foreignFunPathInfo, #ty foreignFunPathInfo)
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
    and formatStrEnvEntry path (name, TY.STRUCTURE{id, env, ...}) =
        let
          val innerPath = Path.appendPath(path, id, name)
        in
          [
            FE.Guard
            (
              NONE,
              [
                FE.Term(9, "structure"), U.s_d_Indicator,
                FE.Term(size name, name), U.s_d_Indicator,
                FE.Term(1, ":"), U.s_1_Indicator
              ]
              @ (formatEnv innerPath env)
            )
          ]
        end

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
    and formatSpec currentPath (TP.TPMSPECVAL varInfos) =
        let val varPathInfos = map U.varInfoToVarPathInfo varInfos
        in
          concatFormatsList
              (map (formatIDState currentPath o TY.VARID) varPathInfos)
        end
      | formatSpec currentPath (TP.TPMTYPEEQUATION bindInfo) =
        concatFormatsList([formatTyBindInfo currentPath bindInfo])
      | formatSpec currentPath (TP.TPMSPECTYPE tySpecs) =
        concatFormatsList(map (formatTySpec currentPath) tySpecs)
      | formatSpec currentPath (TP.TPMSPECEQTYPE tySpecs) =
        concatFormatsList(map (formatTySpec currentPath) tySpecs)
      | formatSpec currentPath (TP.TPMSPECDATATYPE tyCons) =
        concatFormatsList
            (map (concatFormatsList o (formatTyCon currentPath)) tyCons)
      | formatSpec
            currentPath
            (TP.TPMSPECREPLIC {left, right = {relativePath, tyCon}}) =
        formatDatatypeReplication currentPath (left, relativePath, tyCon)
      | formatSpec currentPath (TP.TPMSPECEXCEPTION conPathInfos) =
        concatFormatsList
            (map (formatIDState currentPath o TY.CONID) conPathInfos)
      | formatSpec currentPath (TP.TPMSPECSTRUCT structures) =
        let
          fun formatStructure ({id, name, ...} : TY.strPathInfo, sigExp) =
              let val innerPath = P.appendPath(currentPath, id, name)
              in
                [
                  FE.Guard
                  (
                    NONE,
                    [
                      FE.Term(9, "structure"), U.s_d_Indicator,
                      FE.Term(size name, name), U.s_d_Indicator,
                      FE.Term(1, ":"), U.s_1_Indicator
                    ]
                    @ (formatSigExp innerPath sigExp)
                  )
                ]
              end
        in
          concatFormatsList(map formatStructure structures)
        end
      | formatSpec currentPath (TP.TPMSPECINCLUDE sigExp) =
        [
          FE.Guard
              (
                NONE,
                [FE.Term(7, "include"), U.s_1_Indicator]
                @ (formatSigExp currentPath sigExp)
              )
        ]
      | formatSpec currentPath (TP.TPMSPECSEQ(leftSpec, rightSpec)) =
        (formatSpec currentPath leftSpec)
        @ [U.s_1_Indicator]
        @ (formatSpec currentPath rightSpec)
      | formatSpec currentPath (TP.TPMSPECSHARE(spec, paths)) =
        let
          val formattedSpec = formatSpec currentPath spec
          fun formatPath (strPath, name) =
              let val string = U.pathNameToString (strPath, name)
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
      | formatSpec currentPath (TP.TPMSPECSHARESTR(spec, paths)) =
        let
          val formattedSpec = formatSpec currentPath spec
          fun formatPath path =
              let val string = U.pathToString path
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
                         (map formatPath paths))
              )
            ]
        end
      | formatSpec currentPath TP.TPMSPECEMPTY = []

    (** get the constraint signature of a strExp.
     * @return <ul>
     * <li>SOME sigExp) - if a constraint</li>
     * <li>NONE - if no constraint</li>
     *)
    fun getConstraintOfStrExp (TP.TPMOPAQCONS(_, sigExp, _, _)) = SOME sigExp
      | getConstraintOfStrExp (TP.TPMTRANCONS(_, sigExp, _, _)) = SOME sigExp
      | getConstraintOfStrExp (TP.TPMFUNCTORAPP _ ) = NONE
      | getConstraintOfStrExp (TP.TPMLET(_, strExp,_)) =
        getConstraintOfStrExp strExp
      | getConstraintOfStrExp _ = NONE
  in
  fun generatePrintCodeForStrBind
          context path loc ({id, name, env} : TP.strInfo, strExp) =
      let
        val innerPath = Path.appendPath(path, id, name)
        val header = 
            [
              FE.Term(9, "structure"),
              U.s_d_Indicator,
              FE.Term(size name, name),
              U.s_1_Indicator,
              FE.Term(1, ":"),
              U.s_d_Indicator
            ]
        val body =
            case getConstraintOfStrExp strExp of
              NONE => formatEnv innerPath env
            | SOME sigExp => formatSigExp path sigExp
        val formatted = [FE.Guard(NONE, header @ body)]
      in
        TP.TPSEQ
        {
          expList = [
                     OC.printFormat
                     (OC.concatFormatExpressions
                      (OC.translateFormatExpressions formatted)),
                     OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
                     ],
          expTyList = [OC.unitTy, OC.unitTy],
          loc = loc
        }
      end

  fun generatePrintCodeForSigDecl
          context
          path
          loc
          (TY.SIGNATURE(_, {id, name, strpath, env, ...}), sigExp) =
      let
        val innerPath = P.appendPath(path, id, name)
        val header = 
            [
              FE.Term(9, "signature"),
              U.s_d_Indicator,
              FE.Term(size name, name),
              U.s_d_Indicator,
              FE.Term(1, "="),
              U.s_1_Indicator
            ]
(*
        val body = formatEnv innerPath env
*)
        val body = formatSigExp innerPath sigExp
      in
        TP.TPSEQ
        {
          expList =
          [
            OC.printFormat
                (OC.concatFormatExpressions
                     (OC.translateFormatExpressions (header @ body))),
            OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
          ],
          expTyList = [OC.unitTy, OC.unitTy],
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
          (funBindInfo : TP.funBindInfo, argName, sigExp, strExp) =
      let
        val functorName = #name (#func funBindInfo)
        val bodyEnv = #2(#constrained(#body(#func(#functorSig funBindInfo))))
        val innerPath =
            P.appendPath(path, #id (#func funBindInfo), functorName)

        val parameterInfo = #argument funBindInfo
        val parameterPath =
            P.appendPath(innerPath, #id parameterInfo, #name parameterInfo)
        val formattedParameter = formatSigExp parameterPath sigExp
        val formattedBody =
            case getConstraintOfStrExp strExp of
              NONE => formatEnv innerPath bodyEnv
            | SOME bodySigExp => formatSigExp innerPath bodySigExp
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
                U.s_1_Indicator
              ]
            @ formattedBody
      in
        TP.TPSEQ
        {
          expList =
          [
            OC.printFormat
                (OC.concatFormatExpressions
                     (OC.translateFormatExpressions formatted)),
            OC.printString(TP.TPCONSTANT(TY.STRING("\n"), loc))
          ],
          expTyList = [OC.unitTy, OC.unitTy],
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

  end

  (***************************************************************************)

end
