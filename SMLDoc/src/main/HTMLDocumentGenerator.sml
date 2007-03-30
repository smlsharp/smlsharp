(**
 * This module generates HTML documents describing the given program.
 * @author YAMATODANI Kiyoshi
 * @version $Id: HTMLDocumentGenerator.sml,v 1.11 2007/02/17 07:01:58 kiyoshiy Exp $
 *)
structure HTMLDocumentGenerator : DOCUMENT_GENERATOR =
struct

  (***************************************************************************)

  structure EA = ElaboratedAst
  structure S = Summarizer
  structure B = Binds
  structure L = Linkage
  structure FE = SMLFormat.FormatExpression
  structure BF = SMLFormat.BasicFormatters
  structure U = Utility
  structure DGP = DocumentGenerationParameter
  structure HTML =
  struct
    open HTML
    open MakeHTML
  end

  (***************************************************************************)

  val ANCHOR_PREFIX_TYPE = "Type"
  val ANCHOR_PREFIX_EXCEPTION = "Exception"
  val ANCHOR_PREFIX_VAL = "Val"
  val ANCHOR_PREFIX_VALUECONSTRUCTOR = "Constr"

  (***************************************************************************)

  fun escapeHTML string =
      let
        (* $ is escaped to avoid that a string "$Id ... $" is interpreted
         * by CVS.
         * 36 is character code of '$'.
         *)
        val table =
            [("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("$", "&#36;")]
      in U.replaceStringByTable table string
      end

  (****************************************)

  fun makeFileNameForModule FQN =
      let
        fun prefix EA.STRUCTURE = "Str"
          | prefix EA.SIGNATURE = "Sig"
          | prefix EA.FUNCTOR = "Fct"
          | prefix EA.FUNCTORSIGNATURE = "Fsig"
          | prefix EA.FUNCTORPARAMETER_STRUCTURE = "FnStr"
          | prefix EA.ANONYMOUS_FUNCTORPARAMETER_STRUCTURE = "AnFnStr"
      in
        (U.interleaveString
         "-"
         (map (fn (moduleType, name) => (prefix moduleType) ^ name) FQN)) ^
        ".html"
      end

  fun getModuleTypeText moduleType =
      case moduleType of
        EA.STRUCTURE => "structure"
      | EA.SIGNATURE => "signature"
      | EA.FUNCTOR => "functor"
      | EA.FUNCTORSIGNATURE => "funsig"

  (** make a file name for a document in which the source code in
   * the sourcePath is formatted in HTML format. *)
  fun makeFileNameForSource sourcePath =
      let val table = [("/", "_"), ("\\", "_"), (".", "_"), (":", "_")]
      in "Src" ^ U.replaceStringByTable table sourcePath ^ ".html"
      end

  val LINE_NUMBER_WIDTH = 4
  fun makeLineAnchor lineNumber = 
      ((StringCvt.padLeft #"0" LINE_NUMBER_WIDTH) o Int.toString) lineNumber

  fun makeLocAnchor {fileName, line, column} =
      (makeFileNameForSource fileName) ^ "#" ^ (makeLineAnchor line)

  (****************************************)

  val ind_s = FE.Indicator({space = true, newline = NONE})
  val ind_sd =
      FE.Indicator({space = true, newline = SOME{priority = FE.Deferred}})
  val ind_nsd =
      FE.Indicator({space = false, newline = SOME{priority = FE.Deferred}})
  val ind_s1 =
      FE.Indicator({space = true, newline = SOME{priority = FE.Preferred 1}})
  val ind_ns1 =
      FE.Indicator({space = false, newline = SOME{priority = FE.Preferred 1}})
  val ind_s2 =
      FE.Indicator({space = true, newline = SOME{priority = FE.Preferred 2}})
  val ind_s3 =
      FE.Indicator({space = true, newline = SOME{priority = FE.Preferred 3}})

  local
    structure PP = SMLFormat.PrinterParameter
  in
  fun printFormats format =
      SMLFormat.prettyPrint
          [PP.Space "&nbsp;", PP.Newline "<br>\n", PP.Columns 80]
          format
      handle SMLFormat.Fail message => raise Fail message
  end

  fun formatModuleReference moduleRef =
      case moduleRef of
        (EA.UnknownRef path) =>
        let val text = EA.pathToString path in FE.Term(size text, text) end
      | (EA.ExternalRef(FQN, baseURL)) =>
        let
          val pathText = EA.moduleFQNToString FQN
          val fileName = makeFileNameForModule FQN
        in
          FE.Term
          (
            size pathText,
            "<A HREF=\"" ^ baseURL ^ "/" ^ fileName ^ "\">" ^ pathText ^ "</A>"
          )
        end
      | (EA.ModuleRef(FQN, displayPath)) =>
        let val pathText = EA.pathToString displayPath
        in
          if EA.isFQNOfFunctorParameter FQN
          then FE.Term(size pathText, pathText)
          else
            let val fileName = makeFileNameForModule FQN
            in
              FE.Term
              (
                size pathText,
                "<A HREF=\"" ^ fileName ^ "\">" ^ pathText ^ "</A>"
              )
            end
        end

  local
    fun formatElementReference anchorPrefix (EA.UnknownRef _, path) =
        let val text = EA.pathToString path
        in FE.Term(size text, text) end
      | formatElementReference
            anchorPrefix (EA.ExternalRef(FQN, baseURL), path) =
        let
          val pathText = EA.pathToString path
          val fileName = makeFileNameForModule FQN
          val URL =
              baseURL ^ "/" ^ fileName ^ "#" ^ anchorPrefix ^ (List.last path)
        in
          FE.Term
          (size pathText, "<A HREF=\"" ^ URL ^ "\">" ^ pathText ^ "</A>")
        end
      | formatElementReference
            anchorPrefix (EA.ModuleRef(ABSFQN, RELPath), path) =
        if EA.isFQNOfFunctorParameter ABSFQN
        then
          (* HTML file is not generated for functor parameters.
           * So, references to functor parameters are not hyper-linked. *)
          let val text = EA.pathToString path
          in FE.Term(size text, text) end
        else
          let
            val fileName =
                if null ABSFQN then "" else makeFileNameForModule ABSFQN
            val FQNString = EA.pathToString path
          in
            FE.Term
            (
              size FQNString,
              "<A HREF=\"" ^
              fileName ^ "#" ^ anchorPrefix ^ (List.last path) ^
              "\">" ^
              FQNString ^
              "</A>"
            )
          end
  in
  val formatTypeReference = formatElementReference ANCHOR_PREFIX_TYPE
  val formatExceptionReference = formatElementReference ANCHOR_PREFIX_EXCEPTION
  val formatValReference = formatElementReference ANCHOR_PREFIX_VAL
  val formatValueConstructorReference =
      formatElementReference ANCHOR_PREFIX_VALUECONSTRUCTOR
  end

  fun formatTy isDetail ty =
      let
        fun formatDocComment (summary, _, _) = 
            if isDetail
            then
              let
                val html =
                    "<FONT COLOR=\"red\"><I>(* " ^ summary ^ "*)</I></FONT>"
              in [FE.Term(size summary, html)] end
            else []

        fun format (EA.VarTy(tyvar)) = [FE.Term(size tyvar, tyvar)]
          | format (EA.ConTy(tyConReference, argTys)) =
            let
              val tyConFormat = formatTypeReference tyConReference
              val argTysFormats =
                  case argTys of
                    [] => []
                  | [argTy] => (format argTy) @ [ind_s]
                  | _ =>
                    [FE.Guard
                     (
                       NONE,
                       FE.Term(1,"(") :: FE.StartOfIndent 2 :: ind_ns1 ::
                       (BF.format_list (format,[FE.Term(1,","),ind_s1]) argTys)
                       @ [FE.EndOfIndent, ind_ns1, FE.Term(1,")")]
                     ), ind_s]
            in
              [FE.Guard
               (
                 SOME{cut = false, strength = 2, direction = FE.Neutral},
                 argTysFormats @ [tyConFormat]
               )]
            end
          | format (EA.FunTy(ty1, ty2)) =
            [FE.Guard
             (
               SOME{cut = false, strength = 1, direction = FE.Right},
               (format(ty1)) @
               [
                 ind_sd,
                 FE.Term(2, "-&gt;"),
                 FE.StartOfIndent(2),
                 ind_s1,
                 FE.Guard (NONE, format(ty2)),
                 FE.EndOfIndent
               ]
             )]
          | format (EA.RecordTy tyRows) =
            let
              fun formatTyRow (label, ty, optDC) =
                  let
                    val optDocCommentHTML =
                        case optDC of
                          NONE => []
                        | SOME docComment =>
                          formatDocComment docComment @ [ind_s1]
                  in
                    [FE.Guard
                     (
                       NONE,
                       optDocCommentHTML @
                       [
                         FE.Term(size label, label),
                         ind_s,
                         FE.Term(1, ":"),
                         ind_s2,
                         FE.Guard
                         (
                           SOME
                           {cut = true, strength = 0, direction = FE.Neutral},
                           format(ty)
                         )
                       ]
                     )]
                  end
            in
              [FE.Guard
               (
                 SOME{cut = true, strength = 0, direction = FE.Neutral},
                 [FE.Term(1, "{"), FE.StartOfIndent(2), ind_ns1] @
                 (BF.format_list(formatTyRow,[FE.Term(1,","), ind_s1])tyRows) @
                 [FE.EndOfIndent, ind_ns1, FE.Term(1, "}")]
               )]
            end
          | format (EA.TupleTy elems) =
            let
              fun formatElement ty =
                  [FE.Guard
                   (
                     SOME {cut = false, strength = 2, direction = FE.Neutral},
                     format ty
                   )]
            in
              [FE.Guard
               (
                 SOME{cut = false, strength = 1, direction = FE.Neutral},
                 BF.format_list
                 (formatElement, [ind_s, FE.Term(1, "*"), ind_s1]) elems
               )]
            end
          | format (EA.CommentedTy(docComment, ty)) =
            [
              FE.Guard
                  (NONE, formatDocComment docComment @ [ind_s1] @ format ty)
            ]
              
      in
        format ty
      end

  fun formatParamPat (EA.IDParamPat (id, tyOpt)) = [FE.Term(size id, id)]
    | formatParamPat (EA.TupleParamPat pats) =
      [FE.Guard
       (
         NONE,
         [FE.Term(1,"("), FE.StartOfIndent(2), ind_ns1] @
         (BF.format_list(formatParamPat,[FE.Term(1,","), ind_s1]) pats) @
         [FE.EndOfIndent, ind_ns1, FE.Term(1, ")")]
       )]
    | formatParamPat (EA.RecordParamPat patRows) =
      let
        fun formatPatRow (label, pat) =
            [FE.Guard
             (
               NONE,
               [
                 FE.Term(size label, label),
                 ind_sd,
                 FE.Term(1, "="),
                 ind_s2,
                 FE.Guard (NONE, formatParamPat(pat))
               ]
             )]
      in
        [FE.Guard
         (
           NONE,
           [FE.Term(1, "{"), FE.StartOfIndent(2), ind_ns1] @
           (BF.format_list(formatPatRow, [FE.Term(1, ","), ind_s1]) patRows) @
           [FE.EndOfIndent, ind_ns1, FE.Term(1, "}")]
         )]
      end
  fun formatParamPats pats =
      [FE.Guard(NONE, BF.format_list(formatParamPat, [ind_s1]) pats)]

  fun formatTyVars [] = []
    | formatTyVars [tyvar] = [FE.Term(size tyvar, tyvar), ind_s]
    | formatTyVars tyvars =
      FE.Term(1, "(") ::
      (BF.format_list(BF.format_string, [FE.Term(1, ","), ind_s]) tyvars) @
      [FE.Term(1, ")"), ind_s]

  fun formatSigConst formatter EA.NoSig = []
    | formatSigConst formatter (EA.Transparent constraint) =
      [ind_s, FE.Term(1, ":"), FE.StartOfIndent 2, ind_sd] @
      formatter constraint @
      [FE.EndOfIndent]
    | formatSigConst formatter (EA.Opaque constraint) =
      [ind_s, FE.Term(2, ":>"), FE.StartOfIndent 2, ind_sd] @
      formatter constraint @
      [FE.EndOfIndent]

  fun formatFunctorParamSig(SOME id, sigExp) =
      FE.Term(1, "(") ::
      FE.Guard
      (
        NONE,
        [FE.Term(size id, id), ind_s, FE.Term(1, ":"), ind_s1] @
        formatSigExp sigExp
      ) ::
      [FE.Term(1, ")")]
    | formatFunctorParamSig(NONE, EA.BaseSig specSet) =
      FE.Term(1, "(") ::
      FE.Guard
      (
        NONE,
        FE.StartOfIndent 2 :: formatSpecSet specSet @ [FE.EndOfIndent] 
      ) ::
      [FE.Term(1, ")")]

  and formatFunctorArg (strExp, true) =
      FE.Guard
      (
        NONE,
        FE.Term(1, "(") ::
        FE.Guard
        (
          NONE,
          [FE.StartOfIndent 2, ind_ns1] @
          formatStrExp strExp @
          [FE.EndOfIndent, ind_ns1]
        ) ::
        [FE.Term(1, ")")]
      )
    | formatFunctorArg (EA.BaseStr decSet, false) =
      FE.Guard
      (NONE, [FE.Term(1, "(")] @ formatDecSet decSet @ [FE.Term(1, ")")])

  and formatStrExp (EA.VarStr reference) = [formatModuleReference reference]
    | formatStrExp (EA.BaseStr decSet) =
      [FE.Guard
       (
         NONE,
         [FE.Term(6, "struct"), FE.StartOfIndent 2, ind_s1] @
         formatDecSet decSet @
         [FE.EndOfIndent, ind_s1, FE.Term(3, "end")]
       )]
    | formatStrExp (EA.ConstrainedStr (strExp, sigConst)) =
      [
        FE.Guard
        (NONE, formatStrExp strExp @ formatSigConst formatSigExp sigConst)
      ]
    | formatStrExp (EA.AppStr(functorReference, args)) =
      formatModuleReference functorReference :: (map formatFunctorArg args)

  and formatFctExp fctExp =
      let
        (* argument fsigexp to the sigConst is always VarFsig *)
        fun formatConstraint sigConst =
            formatSigConst
            (fn(EA.VarFsig reference) => [formatModuleReference reference])
            sigConst
      in
        case fctExp of
          EA.VarFct(reference, sigConst) =>
          formatConstraint sigConst @
          [ind_s, FE.Term(1, "="), ind_s1, formatModuleReference reference]
        | EA.BaseFct {params, body, constraint} =>
          List.concat
              (U.interleave [ind_s2] (map formatFunctorParamSig params)) @
          formatSigConst formatSigExp constraint @
          [ind_s, FE.Term(1, "="), ind_s1] @
          formatStrExp body
        | EA.AppFct(functorReference, args, sigConst) =>
          formatConstraint sigConst @
          (ind_s :: FE.Term(1, "=") :: ind_s1 ::
           formatModuleReference functorReference ::
           (map formatFunctorArg args))
      end

  and formatWhereSpec (EA.WhType(path, tyvars, ty)) =
      let val pathText = EA.pathToString path
      in
        [FE.Guard
         (
           NONE,
           FE.Term(4, "type") ::
           (case tyvars of [] => [] | _ => ind_s :: (formatTyVars tyvars)) @
           [
             ind_s,
             FE.Term(size pathText, pathText),
             ind_s,
             FE.Term(1, "="),
             ind_s1
           ]
           @ (formatTy false ty)
         )]
      end
    | formatWhereSpec (EA.WhStruct(path, reference)) =
      let val pathString = EA.pathToString path
      in
        [FE.Guard
         (
           NONE,
           [
             FE.Term(size pathString, pathString),
             ind_s,
             FE.Term(1, "="),
             ind_s1,
             formatModuleReference reference
           ]
         )]
      end

  and formatSigExp (EA.VarSig reference) = [formatModuleReference reference]
    | formatSigExp (EA.BaseSig specSet) =
      [FE.Guard
       (
         NONE,
         [FE.Term(3, "sig"), FE.StartOfIndent 2, ind_s1] @
         formatSpecSet specSet @
         [FE.EndOfIndent, ind_s1, FE.Term(3, "end")]
       )]
    | formatSigExp (EA.AugSig (sigExp, whereSpecsList)) =
      [FE.Guard
       (
         NONE,
         formatSigExp sigExp @ 
         (if null whereSpecsList
          then []
          else
            [FE.StartOfIndent 2, ind_s1] @
            BF.format_list
            (
              (fn whereSpecs =>
                  [FE.Term(5,"where"), ind_s] @
                  BF.format_list
                  (
                    formatWhereSpec,
                    [
                      FE.StartOfIndent 2,
                      ind_s3,
                      FE.EndOfIndent,
                      FE.Term(3, "and"),
                      ind_s
                    ]
                  )
                  whereSpecs),
              [ind_s2]
            )
            whereSpecsList)
       )]
      
  and formatFsigExp (EA.VarFsig reference) =
      [ind_s, FE.Term(1, "="), ind_s1, formatModuleReference reference]
    | formatFsigExp (EA.BaseFsig {params, result}) =
      List.concat
      (U.interleave [ind_s2] (map formatFunctorParamSig params)) @
      [ind_s, FE.Term(1, "="), ind_s1] @
      formatSigExp result

  and formatSpecSet (EA.SpecSet specSet) =
      let
        val strs = map formatSigBind (#strs specSet)
        val fcts = map formatFsigBind (#fcts specSet)

        val shareStrs = map formatShareStrs (#shareStrs specSet)

        val shareTycs = map formatShareTycs (#shareTycs specSet)

        val includes = map formatInclude (#includes specSet)

        val types = map (formatTypeBind false) (#types specSet)
        val datatypes = map (formatDataTypeBind false) (#datatypes specSet)
        val exceptions = map (formatExceptionBind false) (#exceptions specSet)
        val vals = map (formatValBind false) (#vals specSet)
      in
        [
          FE.Guard
          (
            NONE,
            List.concat
            (U.interleave
             [ind_s1]
             (List.concat
             [
               includes, strs, fcts, shareStrs,
               types, datatypes, shareTycs,
               exceptions, vals
             ]
            ))
          )
        ]
      end

  and formatDecSet (EA.DecSet decSet) =
      let
        val strs = map formatStrBind (#strs decSet)
        val fcts = map formatFctBind (#fcts decSet)
        val sigs = map formatSigBind (#sigs decSet)
        val fsigs = map formatFsigBind (#fsigs decSet)

        val opens = map formatOpen (#opens decSet)

        val types = map (formatTypeBind false) (#types decSet)
        val datatypes = map (formatDataTypeBind false) (#datatypes decSet)
        val exceptions = map (formatExceptionBind false) (#exceptions decSet)
        val vals = map (formatValBind false) (#vals decSet)
      in
        [
          FE.Guard
          (
            NONE,
            List.concat
            (U.interleave
             [ind_s1]
             (List.concat
             [
               opens, strs, fcts, sigs, fsigs, 
               types, datatypes, exceptions, vals
             ]
            ))
          )
        ]
      end

  and formatSigBind (EA.SIGB(module, name, loc, sigExp, _, _)) =
      let
        (*
         * signature bindings appear in one of the following 4 forms.
         * 
         * 1) toplevel bound signature
         *
         *   signature S = sigExp
         *
         * 2) inner signature in other signature
         *
         *   signature P =
         *   sig
         *     structure S : sigExp
         *   end
         *
         * 3) named parameter of functor
         *
         *   functor F(S : sigExp) = ...
         *
         * 4) inner signature in anonymous parameter of functor
         *
         *   functor F(... structure S : sigExp ...) = ...
         *)
        val (header, separator) =
            case U.splitLast module of
              (parentFQN, _) =>
              let
                fun scan [] = (FE.Term(10, "signature"), FE.Term(1, "="))
                  | scan ((EA.SIGNATURE, _)::_) = 
                    (FE.Term(9, "structure"), FE.Term(1, ":"))
                  | scan ((EA.FUNCTORPARAMETER_STRUCTURE, _)::_) =
                    (FE.Term(0, ""), FE.Term(1, ":"))
                  | scan ((EA.ANONYMOUS_FUNCTORPARAMETER_STRUCTURE, _)::_) = 
                    (FE.Term(9, "structure"), FE.Term(1, ":"))
                  | scan (_::tailFQN) = scan tailFQN
              in scan parentFQN end
      in
        [FE.Guard
         (
           NONE,
           [
             header,
             ind_s,
             formatModuleReference(EA.ModuleRef(module, [name])),
             ind_s,
             separator,
             ind_s1
           ] @
           formatSigExp sigExp
         )]
      end

  and formatStrBind (EA.STRB(module, name, loc, strExp, sigConst, _)) =
      [FE.Guard
       (
         NONE,
         [
           FE.Term(9, "structure"),
           ind_s,
           formatModuleReference(EA.ModuleRef(module, [name]))
         ] @
         formatSigConst formatSigExp sigConst @
         [ind_s, FE.Term(1, "="), ind_s1] @
         formatStrExp strExp
       )]

  and formatFctBind (EA.FCTB(module, name, loc, fctExp, _)) =
      [FE.Guard
       (
         NONE,
         [
           FE.Term(7, "functor"),
           ind_s,
           formatModuleReference(EA.ModuleRef(module, [name]))
         ] @
         formatFctExp fctExp
       )]

  and formatFsigBind (EA.FSIGB(module, name, loc, fsigExp, _)) =
      [FE.Guard
       (
         NONE,
         [
           FE.Term(6, "funsig"),
           ind_s,
           formatModuleReference(EA.ModuleRef(module, [name]))
         ] @
         formatFsigExp fsigExp
       )]

  and formatShareStrs referenceList =
      [FE.Guard
       (
         NONE,
         FE.Term(7, "sharing") :: ind_s1 ::
         BF.format_list
         (fn r => [formatModuleReference r], [ind_s, FE.Term(1, "="), ind_s2])
         referenceList
       )]

  and formatShareTycs referenceList =
      [FE.Guard
       (
         NONE,
         FE.Term(7, "sharing") :: ind_s :: FE.Term(4, "type") :: ind_s1 ::
         BF.format_list
         (fn r => [formatTypeReference r], [ind_s, FE.Term(1, "="), ind_s2])
         referenceList
       )]

  and formatInclude sigExp =
      [FE.Guard(NONE, FE.Term(7, "include") :: ind_s1 :: formatSigExp sigExp)]

  and formatOpen moduleReference =
      [FE.Guard
       (
         NONE,
         [FE.Term(4, "open"), ind_s1, formatModuleReference moduleReference]
       )]

  and formatTypeBind
          isDetail (EA.TB(module, name, loc, tyvars, tyOpt, isEqType, _)) =
      let
        val typeHeadText = if isEqType then "eqtype" else "type"
        val formattedTyVars = formatTyVars tyvars
        val formattedName =
            if isDetail
            then [FE.Term(size name, name)]
            else [formatTypeReference(EA.ModuleRef(module, []), [name])]
        val formattedRHS = 
            case tyOpt of
              NONE => []
            | SOME(ty) =>
              [ind_s, FE.Term(1, "="), ind_s1] @ (formatTy isDetail ty)
      in
        [FE.Guard
         (
           NONE,
           [
             FE.Term(size typeHeadText, typeHeadText),
             ind_s,
             FE.Guard(NONE, formattedTyVars @ formattedName @ formattedRHS)
           ]
         )]
      end

  and formatDataTypeBind
          isDetail (EA.DB(module, name, loc, tyvars, dbrhs, _)) =
      let
        fun formatConstr (EA.CB(module, name, loc, tyOpt, resultTy, optDC)) =
            [FE.Guard
             (
               NONE,
               (formatValueConstructorReference
                (EA.ModuleRef(module, []), [name]) ::
                (case tyOpt of
                   NONE => []
                 | SOME ty => 
                   [ind_s, FE.Term(2, "of"), ind_s1] @ (formatTy isDetail ty)))
             )]

        val formattedTyVars = formatTyVars tyvars
        val formattedName =
            if isDetail
            then [FE.Term(size name, name)]
            else [formatTypeReference(EA.ModuleRef(module, []), [name])]
        val formattedDbrhs =
            case dbrhs of
              EA.Repl reference =>
              [FE.Term(8, "datatype"), ind_s1, formatTypeReference reference]
            | EA.Constrs constrs =>
              BF.format_list
              (formatConstr,
               [
                 FE.StartOfIndent ~2,
                 ind_s1,
                 FE.Term(1, "|"),
                 ind_s ,
                 FE.EndOfIndent
               ])
              constrs
      in
        [FE.Guard
         (
           NONE,
           [
             FE.Term(8, "datatype"),
             ind_s,
             FE.Guard
             (
               NONE,
               formattedTyVars @
               formattedName @
               [ind_s, FE.Term(1, "="), ind_s1, FE.Guard(NONE, formattedDbrhs)]
             )
           ]
         )]
      end

  and formatValueConsturctorBind
          isDetail (EA.CB(module, name, loc, tyOpt, resultTy, optDC)) =
      let
        val ty =
            case tyOpt of
              NONE => resultTy | SOME argTy => EA.FunTy(argTy, resultTy)
        val formattedParamPats =
            if isDetail
            then
              case optDC of
                SOME(_, _, EA.TagSet{paramPattern = SOME pats, ...}) =>
                [ind_s2, FE.Guard(NONE, formatParamPats pats)]
              | _ => []
            else []
        val formattedName =
            if isDetail
            then FE.Term(size name, name)
            else
              formatValueConstructorReference(EA.ModuleRef(module, []), [name])
        val formattedTy = formatTy isDetail ty
      in
        [FE.Guard
         (
           NONE,
           [
             FE.Term(11, "constructor"),
             ind_s,
             FE.Guard
             (
               NONE,
               formattedName :: 
               formattedParamPats @
               [ind_s1, FE.Term(1, ":"), ind_s] @
               formattedTy
             )
           ]
         )]
      end

  and formatValBind isDetail (EA.VB(module, name, loc, tyOpt, optDC)) =
      let
        val formattedName =
            if isDetail
            then FE.Term(size name, name)
            else formatValReference(EA.ModuleRef(module, []), [name])
        val (isFun, formattedParamPats) =
            if isDetail
            then
              case optDC of
                SOME(_, _, EA.TagSet{paramPattern = SOME pats, ...}) =>
                (true, ind_s :: (formatParamPats pats))
              | _ => (false, [])
            else (false, [])
        val header = FE.Term(3, if isFun then "fun" else "val")
        val formattedTypeSection = 
            case tyOpt of
              NONE => []
            | SOME(ty) =>
              [ind_s1, FE.Term(1, ":"), ind_s] @ (formatTy isDetail ty)
      in
        [FE.Guard
         (
           NONE,
           [
             header,
             ind_s,
             FE.Guard
             (NONE, formattedName :: formattedParamPats @ formattedTypeSection)
           ]
         )]
      end

  and formatExceptionBind isDetail eb =
      let
        val (module, name) =
            case eb of
              EA.EBGen(module, name, _, _, _) => (module, name)
            | EA.EBDef(module, name, _, _, _) => (module, name)
        val formattedName =
            if isDetail
            then FE.Term(size name, name)
            else formatExceptionReference(EA.ModuleRef(module, []), [name])
      in
        [FE.Guard
         (
           NONE,
           case eb of
             EA.EBGen(_, name, loc, tyOpt, _) =>
             [FE.Term(9, "exception"), ind_s, formattedName] @
             (case tyOpt of
                NONE => []
              | SOME(ty) =>
                [ind_s, FE.Term(2, "of"), ind_s] @ formatTy isDetail ty)
           | EA.EBDef(_, name, loc, reference, _) =>
             [
               FE.Term(9, "exception"), ind_s,
               formattedName, ind_s1, FE.Term(1, "="), ind_s,
               formatExceptionReference reference
             ]
         )]
      end

  (****************************************)

  val BRBlock = HTML.TextBlock(HTML.BR)

  local
    fun stringListToHTML header strings =
        case strings of
          [] => []
        | _ =>
          [{
             dt = [HTML.B(HTML.PCDATA (header ^ ":"))],
             dd =
             HTML.TextBlock(HTML.PCDATA(U.interleaveString ", " strings))
           }]

    fun listItemsOfTags
        (DGP.Parameter{author, contributor, copyright, version, ...})
        (EA.TagSet tagSet) =
        let
          val authorsHTML =
              if author
              then stringListToHTML "Author" (#authors tagSet)
              else []
          val contributorsHTML =
              if contributor
              then stringListToHTML "Contributor" (#contributors tagSet)
              else []
          val copyrightsHTML =
              if copyright
              then stringListToHTML "Copyright" (#copyrights tagSet)
              else []
          val parametersHTML =
              let
                fun makeItem (name, tyOpt, description) =
                    let
                      val tyHTML =
                          case tyOpt of
                            NONE => ""
                          | SOME ty => (" : " ^ printFormats(formatTy true ty))
                    in
                      {
                        dt = [HTML.CODE(HTML.PCDATA(name ^ tyHTML))],
                        dd = HTML.TextBlock(HTML.PCDATA description)
                      }
                    end
              in
                case #params tagSet of
                  [] => []
                | parameters =>
                  [{
                     dt = [HTML.B(HTML.PCDATA "Parameters:")],
                     dd = HTML.mkDL (map makeItem parameters)
                   }]
              end
          val exceptionsHTML = 
              let
                fun makeItem (reference, description) =
                    let
                      val link =
                          HTML.CODE
                          (HTML.PCDATA
                           (printFormats
                            ([formatExceptionReference reference])))
                    in
                      {
                        dt = [link],
                        dd = HTML.TextBlock(HTML.PCDATA description)
                      }
                    end
              in
                case #exceptions tagSet of
                  [] => []
                | exceptions =>
                  [{
                     dt = [HTML.B(HTML.PCDATA "Exception:")],
                     dd = HTML.mkDL (map makeItem exceptions)
                   }]
              end
          val returnHTML =
              case #return tagSet of
                NONE => []
              | SOME description =>
                [{
                   dt = [HTML.B(HTML.PCDATA ("Returns:"))],
                   dd = HTML.TextBlock (HTML.PCDATA description)
                 }]
          val seesHTML =
              case #sees tagSet of
                [] => []
              | sees =>
                [{
                   dt = [HTML.B(HTML.PCDATA ("See Also:"))],
                   dd =
                   HTML.TextBlock(HTML.PCDATA(U.interleaveString ", " sees))
                 }]
          val versionHTML =
              if version
              then
                case #version tagSet of
                  NONE => []
                | SOME version =>
                  [{
                     dt = [HTML.B(HTML.PCDATA ("Version:"))],
                     dd = HTML.TextBlock (HTML.PCDATA version)
                   }]
              else []
        in
          List.concat
          [
            authorsHTML,
            contributorsHTML,
            copyrightsHTML,
            parametersHTML,
            returnHTML,
            exceptionsHTML,
            seesHTML,
            versionHTML
          ]
        end

    fun blockOfDocComment description tagItems =
        let
        in
          HTML.blockList
          [
            HTML.mkDL
            [
              {
                dt = [],
                dd =
                HTML.blockList
                [
                  HTML.TextBlock(HTML.PCDATA description),
                  HTML.mkP(HTML.PCDATA "")
                ]
              },
              {dt = [], dd = HTML.mkDL tagItems}
            ]
          ]
        end

    fun locToString {fileName = sourcePath, line, column} =
        let val {file = fileName, ...} = OS.Path.splitDirFile sourcePath
        in fileName ^ ":" ^ Int.toString line ^ "." ^ Int.toString column end
  in

  fun blockOfOptDocComment (DGP as DGP.Parameter parameters) loc optDC =
      case (#linkSource parameters, optDC) of
        (false, NONE) => HTML.TextBlock(HTML.PCDATA "")
      | _ =>
        let
          val tagItems =
              case optDC of
                NONE => [] | SOME(_, _, tagSet) => listItemsOfTags DGP tagSet
          val locItem =
              if #linkSource parameters
              then 
                [{
                   dt = [HTML.B(HTML.PCDATA ("Source:"))],
                   dd =
                   HTML.TextBlock
                   (HTML.mkA_HREF
                    {
                      href = makeLocAnchor loc,
                      content = HTML.PCDATA(locToString loc)
                    })
                 }]
              else []
          val description =
              case optDC of NONE => "" | SOME(_, description, _) => description
        in
          blockOfDocComment description (tagItems @ locItem)
        end
  end

  fun blockOfOptDocCommentSummary optDC =
      HTML.TextBlock
      (case optDC of
         NONE => HTML.PCDATA ""
       | SOME(summary, _, _) =>
         HTML.PCDATA
         ("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" ^
          summary))

  fun textOfAnchor prefix name = 
      HTML.TextBlock
      (HTML.mkA_NAME{name = prefix ^ name, content = HTML.PCDATA "<!-- -->"})

  fun blockOfFormat format =
      HTML.mkP(HTML.CODE(HTML.PCDATA(printFormats format)))

  (********************)

  fun blocksOfTypeSummary 
      (bind as EA.TB(module, name, loc, tyvars, tyOpt, isEqType, optDC)) =
      let
        val typeBlock = blockOfFormat (formatTypeBind false bind)
        val summaryBlock = blockOfOptDocCommentSummary optDC
      in
        [HTML.blockList [typeBlock, BRBlock, summaryBlock]]
      end

  fun blockOfTypeDetail
      DGP
      (bind as EA.TB(module, name, loc, tyvars, tyOpt, isEqType, optDC)) =
      let
        val anchorHTML = textOfAnchor ANCHOR_PREFIX_TYPE name
        val nameHTML = HTML.mkH(3, name)
        val typeHTML = blockOfFormat (formatTypeBind true bind)
      in
        HTML.blockList
        [anchorHTML, nameHTML, typeHTML, blockOfOptDocComment DGP loc optDC]
      end

  (********************)

  fun blocksOfDataTypeSummary
          (bind as EA.DB(module, name, loc, tyvars, dbrhs, optDC)) =
      let
        val typeBlock = blockOfFormat (formatDataTypeBind false bind)
        val summaryBlock = blockOfOptDocCommentSummary optDC
      in
        [HTML.blockList [typeBlock, BRBlock, summaryBlock]]
      end

  fun blockOfDataTypeDetail
          DGP
          (bind as EA.DB(module, name, loc, tyvars, dbrhs, optDC)) =
      let
        val anchorHTML = textOfAnchor ANCHOR_PREFIX_TYPE name
        val nameHTML = HTML.mkH(3, name)
        val typeHTML = blockOfFormat (formatDataTypeBind true bind)
      in
        HTML.blockList
        [anchorHTML, nameHTML, typeHTML, blockOfOptDocComment DGP loc optDC]
      end

  (********************)

  fun blocksOfValueConstructorSummary
          (bind as EA.CB(module, name, loc, tyOpt, resultTy, optDC)) = 
      let
        val typeBlock = blockOfFormat (formatValueConsturctorBind false bind)
        val summaryBlock = blockOfOptDocCommentSummary optDC
      in
        [HTML.blockList [typeBlock, BRBlock, summaryBlock]]
      end

  fun blockOfValueConstructorDetail
          DGP
          (bind as EA.CB(module, name, loc, tyOpt, resultTy, optDC)) = 
      let
        val anchorHTML = textOfAnchor ANCHOR_PREFIX_VALUECONSTRUCTOR name
        val nameHTML = HTML.mkH(3, name)
        val typeHTML = blockOfFormat (formatValueConsturctorBind true bind)
      in
        HTML.blockList
        [anchorHTML, nameHTML, typeHTML, blockOfOptDocComment DGP loc optDC]
      end

  (********************)

  fun blocksOfValSummary (bind as EA.VB(module, name, loc, tyOpt, optDC)) =
      let
        val valBlock = blockOfFormat (formatValBind false bind)
        val summaryBlock = blockOfOptDocCommentSummary optDC
      in
        [HTML.blockList [valBlock, BRBlock, summaryBlock]]
      end

  fun blockOfValDetail DGP (bind as EA.VB(module, name, loc, tyOpt, optDC)) =
      let
        val anchorHTML = textOfAnchor ANCHOR_PREFIX_VAL name
        val nameHTML = HTML.mkH(3, name)
        val valHTML = blockOfFormat(formatValBind true bind)
      in
        HTML.blockList
            [anchorHTML, nameHTML, valHTML, blockOfOptDocComment DGP loc optDC]
      end

  (********************)

  fun blocksOfExceptionSummary(bind) = 
      let
        val optDC =
            case bind of
              EA.EBGen(_, _, _, _, optDC) => optDC
            | EA.EBDef(_, _, _, _, optDC) => optDC
        val exceptionBlock = blockOfFormat(formatExceptionBind false bind)
        val summaryBlock = blockOfOptDocCommentSummary optDC
      in [HTML.blockList [exceptionBlock, BRBlock, summaryBlock]] end

  fun blockOfExceptionDetail DGP (bind) =
      let
        val (name, loc, optDC) =
            case bind of
              EA.EBGen(_, name, loc, _, optDC) => (name, loc, optDC)
            | EA.EBDef(_, name, loc, _, optDC) => (name, loc, optDC)
        val anchorHTML = textOfAnchor ANCHOR_PREFIX_EXCEPTION name
        val nameHTML = HTML.mkH(3, name)
        val exceptionHTML = blockOfFormat(formatExceptionBind true bind)
      in
        HTML.blockList
        [
          anchorHTML,
          nameHTML,
          exceptionHTML,
          blockOfOptDocComment DGP loc optDC
        ]
      end

  (********************)

  local
    fun blocksOfModuleSummary moduleType (*showFQN*) (FQN, name, optDC) =
      let
        val moduleTypeText = getModuleTypeText moduleType
        val structureBlock = 
            blockOfFormat
            [
              FE.Term(size moduleTypeText, moduleTypeText),
              ind_s,
              formatModuleReference(EA.ModuleRef (FQN, [name]))
            ]
        val summaryBlock = blockOfOptDocCommentSummary optDC
      in [HTML.blockList [structureBlock, BRBlock, summaryBlock]] end
  in
  fun blocksOfStructureSummary
          (EA.STRB(FQN, name, loc, strExp, sigConst, optDC)) =
      blocksOfModuleSummary EA.STRUCTURE (FQN, name, optDC)
  fun blocksOfSignatureSummary (EA.SIGB(FQN, name, loc, sigExp, _, optDC)) =
      blocksOfModuleSummary EA.SIGNATURE (FQN, name, optDC)
  fun blocksOfFunctorSummary (EA.FCTB(FQN, name, loc, fctExp, optDC)) =
      blocksOfModuleSummary EA.FUNCTOR (FQN, name, optDC)
  fun blocksOfFunctorSignatureSummary
          (EA.FSIGB(FQN, name, loc, fsigExp, optDC)) =
      blocksOfModuleSummary EA.FUNCTORSIGNATURE (FQN, name, optDC)
  end

  fun blocksOfOpenSummary moduleReference =
      [blockOfFormat [formatModuleReference moduleReference]]

  fun blocksOfIncludeSummary sigExp =
      [blockOfFormat (formatSigExp sigExp)]

  (****************************************)

  local
    fun makeListHeaderTR (title, colspan) =
        HTML.TR
        {
          align = NONE,
          valign = NONE,
          bgcolor = SOME "#CCCCFF",
          content = 
          [HTML.mkTH_COLSPAN
           {
             content =
             HTML.TextBlock
             (HTML.FONT
              {size = SOME "+2", color = NONE, content = HTML.PCDATA title}),
             colspan = colspan
           }]
        }
  in
  fun blockOfSummaryList title summaryMaker [] = HTML.BlockList[]
    | blockOfSummaryList title summaryMaker elements =
      let
        val elementSummaryBlocksList = map summaryMaker elements
        val elementTRs =
            map
            (fn blocks => HTML.mkTR (map HTML.mkTD blocks))
            elementSummaryBlocksList
        val numberOfTD =
            if null elementSummaryBlocksList
            then 1
            else List.length (hd elementSummaryBlocksList)
        val titleTR = makeListHeaderTR (title, numberOfTD)
      in
        HTML.TABLE
        {
          align = NONE, width = SOME "100%", border = SOME "1",
          cellspacing = SOME "0", cellpadding = SOME "3", caption = NONE,
          content = titleTR :: elementTRs
        }
      end

  fun blockOfDetailList title detailMaker [] = HTML.BlockList []
    | blockOfDetailList title detailMaker elements =
      let
        val elementDetailHTMLs =
            U.interleave HTML.HR (map detailMaker elements)
        val titleTR = makeListHeaderTR (title, 1)
        val titleBlock =
            HTML.TABLE
            {
              align = NONE, width = SOME "100%", border = SOME "1",
              cellspacing = SOME "1", cellpadding = SOME "3", caption = NONE,
              content = [titleTR]
            }
      in
        HTML.blockList
            (titleBlock :: elementDetailHTMLs @ [HTML.mkP(HTML.PCDATA "")])
      end
  end

  (****************************************)

  fun HTMLOfFrame
      (
        titleOpt,
        (leftFrameName, leftFrameFileName),
        (rightFrameName, rightFrameFileName)
      ) =
      let
        val title =
            case titleOpt of SOME title => title | NONE => "SML documentation"
        val leftFrame =
            HTML.Frame{src = SOME leftFrameFileName, name = SOME leftFrameName}
        val rightFrame =
            HTML.Frame
            {src = SOME rightFrameFileName, name= SOME rightFrameName}
        val frameSet =
            HTML.FrameSet
            {
              cols = SOME "20%,80%",
              rows = NONE,
              frames = [leftFrame, rightFrame]
            }
        val noframes =
            HTML.blockList
            [
              HTML.mkH(2, "Frame Alert"),
              HTML.mkP
              (HTML.PCDATA
               "This document is designed to be viewed using the frames \
               \feature. If you see this message, you are using a \
               \non-frame-capable web client.")
            ]
      in
        HTML.HTML
        {
          version = NONE,
          head = [HTML.Head_TITLE title],
          body = HTML.FRAMEBODY{frame = frameSet, noframes = noframes}
        }
      end

  fun HTMLOfModuleList targetFrame overviewFileName listSubModule moduleHTMLs =
      let
        val moduleHTMLs' =
            (* get rid of submodules from moduleHTMLs, if specified *)
            if listSubModule
            then moduleHTMLs
            else List.filter (fn ([_], _) => true | _ => false) moduleHTMLs

        fun collect ((FQN, _), (signatures, structures, funsigs, functors)) =
            case List.last FQN of
              (EA.SIGNATURE, _) =>
              (FQN::signatures, structures, funsigs, functors)
            | (EA.STRUCTURE, _) =>
              (signatures, FQN::structures, funsigs, functors)
            | (EA.FUNCTORSIGNATURE, _) =>
              (signatures, structures, FQN::funsigs, functors)
            | (EA.FUNCTOR, _) =>
              (signatures, structures, funsigs, FQN::functors)
        val (signatures, structures, funsigs, functors) =
            foldr collect ([], [], [], []) moduleHTMLs'

        fun makeItem FQN = 
            HTML.textList
            [
              HTML.A
              {
                name = NONE,
                href = SOME(makeFileNameForModule FQN),
                rel = NONE,
                rev = NONE,
                title = NONE,
                target = SOME targetFrame,
                content = HTML.PCDATA(EA.moduleFQNToString FQN)
              },
              HTML.BR
            ]

        fun sortFQNs FQNs =
            U.sort
            (fn (left, right) =>
                (EA.moduleFQNToString left) < (EA.moduleFQNToString right))
            FQNs

        fun makeList title [] = HTML.blockList[]
          | makeList title FQNs =
            HTML.TextBlock
            (HTML.textList
             ([
               HTML.B
               (HTML.FONT
                {size = SOME "+1", color = NONE, content = HTML.PCDATA title}),
               HTML.BR
              ] @
              (map makeItem (sortFQNs FQNs)) @
              [HTML.BR]))

        val toplevel =
            HTML.TextBlock
            (HTML.textList
             [
               HTML.B
               (HTML.FONT
                {
                  size = SOME "+1",
                  color = NONE,
                  content =
                  HTML.A
                  {
                    name = NONE,
                    href = SOME(overviewFileName),
                    rel = NONE,
                    rev = NONE,
                    title = NONE,
                    target = SOME targetFrame,
                    content = HTML.PCDATA("Overview")
                  }
                }
               ),
               HTML.BR,
               HTML.BR
             ])

        val signatureList = makeList "Signatures" signatures
        val structureList = makeList "Structures" structures
        val funsigList = makeList "FunctorSignatures" funsigs
        val functorList = makeList "Functors" functors

        val listBlock =
            HTML.blockList
            [toplevel, signatureList, structureList, funsigList, functorList]

        val body =
            HTML.TABLE
            {
              align = NONE, width = SOME "100%", border = SOME "0",
              cellspacing = NONE, cellpadding = NONE, caption = NONE,
              content = [HTML.mkTR[HTML.mkTD(listBlock)]]
            }
      in
        HTML.HTML
        {
          version = NONE,
          head = [],
          body =
          HTML.BODY
          {
            background = NONE,
            bgcolor = NONE,
            text = NONE,
            link = NONE,
            vlink = NONE,
            alink = NONE,
            content = body
          }
        }
      end

  local
    fun splitBindsByInitial sortedBinds =
        let
          fun isSameInitial (left, right) =
              if (not (Char.isAlpha left)) andalso (not (Char.isAlpha right))
              then true
              else Char.toUpper left = Char.toUpper right
          fun nameOfGroup initial = 
              if Char.isAlpha initial
              then Char.toString(Char.toUpper initial)
              else "Other"
          fun scan currentInitial sameInitialBinds bindsList (bind::binds) =
              let val initial = String.sub(B.getName bind, 0)
              in
                if isSameInitial (currentInitial, initial)
                then
                  scan currentInitial (bind::sameInitialBinds) bindsList binds
                else
                  scan
                  initial
                  [bind]
                  ((nameOfGroup currentInitial, List.rev sameInitialBinds) ::
                   bindsList)
                  binds
              end
            | scan currentInitial sameInitialBinds bindsList [] =
              List.rev
                  ((nameOfGroup currentInitial, List.rev sameInitialBinds) ::
                   bindsList)
        in
          List.filter
              (fn (_, binds) => not(List.null binds))
              (scan #"a" [] [] sortedBinds)
        end

    fun bodyBlockOfIndex (name, binds) =
        let
          local
            fun format (shortLinkText, entityTypeDesc, module, optDC) =
                {
                  dt = 
                  [HTML.textList
                   [
                     HTML.B(HTML.PCDATA shortLinkText),
                     HTML.PCDATA(" - " ^ entityTypeDesc),
                     HTML.PCDATA
                     (printFormats
                      [formatModuleReference
                           (EA.ModuleRef(module, EA.moduleFQNToPath module))])
                   ]],
                  dd = blockOfOptDocCommentSummary optDC
                }

            fun formatModuleBind bind =
                let
                  val moduleFQN = B.getModuleFQN bind
                  val moduleName = B.getName bind
                  val shortLinkText =
                      printFormats
                      [formatModuleReference
                       (EA.ModuleRef(moduleFQN, [moduleName]))]
                  val entityTypeDesc =
                      case List.last moduleFQN of
                        (moduleType, _) => (getModuleTypeText moduleType) ^ " "
                in
                  format
                    (shortLinkText, entityTypeDesc, moduleFQN, B.getOptDC bind)
                end
            fun formatElementBind (bind, referenceFormatter, entityTypeDesc) =
                let
                  val moduleFQN = B.getModuleFQN bind
                  val shortLinkText =
                      printFormats
                      [referenceFormatter
                       (EA.ModuleRef(moduleFQN, []), [B.getName bind])]
                in
                  format
                    (shortLinkText, entityTypeDesc, moduleFQN, B.getOptDC bind)
                end
          in
          fun formatBind (bind as B.SigBind _) = formatModuleBind bind
            | formatBind (bind as B.FsigBind _) = formatModuleBind bind
            | formatBind (bind as B.StrBind _) = formatModuleBind bind
            | formatBind (bind as B.FctBind _) = formatModuleBind bind
            | formatBind (bind as B.TypeBind _) =
              formatElementBind (bind, formatTypeReference, "Type in ")
            | formatBind (bind as B.DataTypeBind _) = 
              formatElementBind (bind, formatTypeReference, "Datatype in ")
            | formatBind (bind as B.ConstructorBind _) =
              formatElementBind
                  (bind, formatValueConstructorReference, "Constructor in ")
            | formatBind (bind as B.ExceptionBind _) = 
              formatElementBind
                  (bind, formatExceptionReference, "Exception in ")
            | formatBind (bind as B.ValBind _) = 
              formatElementBind (bind, formatValReference, "Value in ")
          end

          val titleBlock =
              HTML.Hn
              {
                n = 1,
                align = SOME(HTML.HAlign.center),
                content = HTML.PCDATA(name)
              }
        in
          HTML.blockList [titleBlock, HTML.mkDL(map formatBind binds)]
        end
    fun compareBindName (left, right) =
        let
          val leftName = B.getName left
          val rightName = B.getName right
          val leftBeginAlpha = Char.isAlpha(String.sub(leftName, 0))
          val rightBeginAlpha = Char.isAlpha(String.sub(rightName, 0))
        in
          if leftBeginAlpha = rightBeginAlpha
          then
            (* both are alphabet or both are non-alphabet. *)
            GREATER <> U.compareStringNoCase (leftName, rightName)
          else leftBeginAlpha (* alphabets preceds non-alphabets *)
        end
  in
  fun bodyBlocksOfIndexes binds =
      let
        val splitedBinds = splitBindsByInitial (U.sort compareBindName binds)
      in
          map
          (fn (name, binds) => (name, bodyBlockOfIndex (name, binds)))
          splitedBinds
      end
  end

  fun bodyBlockOfDefaultHelp {overviewFileName, indexFileNameOpt, hasUses} =
      let
        fun makePageDesc title string =
            [
              HTML.Hn{n = 3, align = NONE, content = HTML.PCDATA(title)},
              HTML.BLOCKQUOTE(HTML.mkP(HTML.PCDATA string))
            ]

        val titleText = HTML.PCDATA("How This API Document Is Organized")
        val titleBlocks =
            [
              HTML.Hn
              {n = 1, align = SOME(HTML.HAlign.center), content = titleText},
              HTML.TextBlock
              (HTML.PCDATA
               "This API (Application Programming Interface) document has\
               \ pages corresponding to the items in the navigation bar, \
               \described as follows.")
            ]

        val overviewBlocks =
            makePageDesc
            "Overview"
            ("The <A HREF=\"" ^ overviewFileName ^ "\">Overview</A> page \
             \is the front page of this API document and provides a list \
             \of all modules with a summary for each.  This page can also \
             \contain an overall description of the set of modules.")

        val moduleBlocks =
            makePageDesc
            "Module"
            "Each module, nested module has its own separate page. \
            \Each of these pages has three sections consisting of a module \
            \description, summary tables, and detailed member descriptions:\
            \<UL>\
            \<LI>Module declaration\
            \<LI>All Known Implementing Modules\
            \<LI>Module description\
            \<P>\
            \<LI>Nested Module Summary\
            \<LI>Type Summary\
            \<LI>Datatype Summary\
            \<LI>DataConstructor Summary\
            \<LI>Value Summary\
            \<LI>Exception Summary\
            \<P>\
            \<LI>Type Detail\
            \<LI>Datatype Detail\
            \<LI>DataConstructor Detail\
            \<LI>Value Detail\
            \<LI>Exception Detail\
            \</UL>\
            \Each summary entry contains the first sentence from the \
            \detailed description for that item. The summary entries are \
            \alphabetical, while the detailed descriptions are in the \
            \order they appear in the source code. This preserves the \
            \logical groupings established by the programmer."

        val usesBlocks =
            if hasUses
            then
              makePageDesc
              "Use"
              "Each documented module has its own Use page.  This page \
              \describes what modules use the given module. \
              \ You can access this page by first going to the module, \
              \then clicking on the \"Use\" link in the navigation bar."
            else []

        val indexBlocks =
            case indexFileNameOpt of
              NONE => []
            | SOME indexFileName =>
              makePageDesc
              "Index"
              ("The <A HREF=\"" ^ indexFileName ^ "\">Index</A> contains an \
               \alphabetic list of all modules, types, datatypes, data \
               \constructors, values and exceptions.")
      in
        HTML.blockList
        (titleBlocks @ overviewBlocks @ moduleBlocks @ usesBlocks @
         indexBlocks)
      end

  fun bodyBlockOfUsesOfModule linkage moduleFQN = 
      let
        val titleText =
            HTML.PCDATA("Uses of " ^ EA.moduleFQNToString moduleFQN)
        val titleBlock = 
            HTML.Hn
            {n = 1, align = SOME(HTML.HAlign.center), content = titleText}
        val bodyBlock = HTML.TextBlock(HTML.PCDATA "sorry, not implemented.")
      in
        HTML.blockList[titleBlock, bodyBlock]
      end

  fun bodyBlockOfOverviewPage (title, detailBlock, customOverviewText) =
      let
        val titleText =
            HTML.PCDATA(case title of SOME title => title | NONE => "Overview")
        val titleBlock =
            HTML.Hn
            {n = 1, align = SOME(HTML.HAlign.center), content = titleText}
        val customOverviewBlock =
            HTML.TextBlock(HTML.PCDATA customOverviewText)
      in
        HTML.blockList
            [titleBlock, customOverviewBlock, detailBlock]
      end

  (****************************************)

  type navigatedPages =
       {
         overview : string option option,
         uses : string option option,
         index : string option option,
         help : string option option
       }

  (**
   * generate a HTML block for navigation bar.
   *
   * @params sideStringOpt {overview, uses, index, help}
   * @param sideString SOME string (may be HTML code) to be displayed at the
   *        right side of the navigation bar. NONE if no string should be
   *        displayed.
   * @param overview NONE if overview page is not generated. SOME NONE if
   *         a hyperlink to the overview page shoud not be generated.
   *         SOME SOME url if a hyperlink to the url should be generated.
   * @param uses for 'uses of this module' page
   * @param index for 'index-all' page
   * @param help for 'help' page
   *)
  fun blockOfNavigationBar
          sideStringOpt ({overview, uses, index, help} : navigatedPages) =
      let
        fun makeCell (string, NONE) = []
          | makeCell (string, SOME urlOpt) =
            let
              val urlText =
                  case urlOpt of
                    NONE => string ^ "&nbsp;"
                  | SOME url =>
                    "<B><A HREF=\"" ^ url ^ "\">" ^ string ^ "</A></B>&nbsp;"
            in
              [HTML.TD
               {
                 nowrap = false,
                 rowspan = NONE,
                 colspan = NONE,
                 align = NONE,
                 valign = NONE,
                 width = NONE,
                 height = NONE,
                 bgcolor = SOME "#EEEEFF",
	         content = HTML.TextBlock(HTML.PCDATA(urlText))
               }]
            end
        val cells =
            List.concat
            (map
             makeCell
             [
               ("Overview", overview),
               ("Uses", uses),
               ("Index", index),
               ("Help", help)
             ])
        val tr =
            HTML.TR
            {
              align = SOME HTML.HAlign.center,
              valign = SOME HTML.CellVAlign.top,
              bgcolor = NONE,
              content = cells
            }

        val innerTableCell =
            if List.null cells
            then []
            else
            [HTML.mkTD
             (HTML.TABLE
              {
                align = NONE, width = SOME "100%", border = SOME "0",
                cellspacing = SOME "3", cellpadding = SOME "0", caption = NONE,
                content = [tr]
              })]
        val headerCell =
            case sideStringOpt of
              NONE => []
            | SOME sideString =>
              [HTML.TD
              {
                nowrap = false,
                rowspan = NONE,
                colspan = NONE,
                align = SOME HTML.HAlign.right,
                valign = SOME HTML.CellVAlign.top,
                width = NONE,
                height = NONE,
                bgcolor = NONE,
	        content = HTML.TextBlock(HTML.PCDATA sideString)
              }]
      in
        HTML.TABLE
        {
          align = NONE, width = SOME "100%", border = SOME "0",
          cellspacing = SOME "0", cellpadding = SOME "1", caption = NONE,
          content = [HTML.mkTR(innerTableCell @ headerCell)]
        }
      end

  fun blockOfModuleHeader
          DGP linkage (moduleFQN, loc, signatureFormat, optDC) =
      let
        val implementingModuleBinds =
            case List.last moduleFQN of
              (EA.SIGNATURE, _) => 
              List.filter
              (U.satisfyAny [B.isStrBind, B.isFctBind])
               (S.getClosureOfLink
                S.DESTTOSRC
                [L.IncludeLink, L.ConstraintLink, L.ModuleDefLink, L.OpenLink]
                linkage
                moduleFQN)
            | _ => []
        val implementingModuleFQNs = map B.getModuleFQN implementingModuleBinds

        val enclosingModuleFQNs =
            let
              fun scan [_] FQNs = map rev FQNs
                | scan (pair :: pairs) FQNs =
                  scan pairs ([pair] :: (map (fn FQN => pair :: FQN) FQNs))
            in scan moduleFQN [] end

        fun makeFQNListDL title FQNs =
            if null FQNs
            then []
            else
              [HTML.mkDL
               [{
                  dt = [HTML.B(HTML.PCDATA title)],
                  dd =
                  blockOfFormat
                  (BF.format_list
                   (
                     fn r => [formatModuleReference r],
                     [FE.Term(1, ","), ind_sd]
                   )
                   (map
                    (fn FQN => EA.ModuleRef(FQN, EA.moduleFQNToPath FQN))
                    FQNs))
                }]]

        val dependInfoDL =
            makeFQNListDL
                "All Known Implementing Modules:" implementingModuleFQNs
        val enclosingModuleDL =
            makeFQNListDL "Enclosing Modules:" enclosingModuleFQNs

      in
        HTML.blockList
        (HTML.mkH(2, EA.moduleFQNToString moduleFQN) ::
        dependInfoDL @
        enclosingModuleDL @
        [
          HTML.HR,
          blockOfFormat(signatureFormat),
          HTML.mkP(HTML.PCDATA ""),
          blockOfOptDocComment DGP loc optDC,
          HTML.mkP(HTML.PCDATA "")
        ])
      end

  fun bodyBlockOfModulePage (moduleFQN, moduleHeaderHTML, moduleDetailHTML) =
      HTML.blockList[moduleHeaderHTML, moduleDetailHTML]

  (****************************************)

  local
    fun getValueConstructors dataTypes =
        let
          fun collect (EA.DB(_, _, _, _, EA.Repl _, _)) = []
            | collect (EA.DB(_, _, _, _, EA.Constrs constrs, _)) = constrs
        in
          List.concat(map collect dataTypes)
        end

    fun concatSummaryDetailList (summaryList, detailList) =
        HTML.blockList
        ((U.interleave (HTML.TextBlock(HTML.PCDATA "&nbsp;")) summaryList) @
         [HTML.mkP(HTML.PCDATA "&nbsp;")] @
         (U.interleave (HTML.TextBlock(HTML.PCDATA "&nbsp;")) detailList))

    fun sort getKey list =
        U.sort
        (fn (left, right) =>
            GREATER <> U.compareStringNoCase (getKey left, getKey right))
        list

    fun sortSpecSet (EA.SpecSet specSet) =
        EA.SpecSet
        {
          strs =
          sort (fn EA.SIGB(_, name, _, _, _, _) => name) (#strs specSet),
          fcts = sort (fn EA.FSIGB(_, name, _, _, _) => name) (#fcts specSet),
          shareStrs = #shareStrs specSet,
          shareTycs = #shareTycs specSet,
          includes = #includes specSet,
          types =
          sort (fn EA.TB(_, name, _, _, _, _, _) => name) (#types specSet),
          datatypes =
          sort (fn EA.DB(_, name, _, _, _, _) => name) (#datatypes specSet),
          exceptions =
          sort (fn EA.EBGen(_, name, _, _, _) => name) (#exceptions specSet),
          vals = sort (fn EA.VB(_, name, _, _, _) => name) (#vals specSet)
        }

    fun sortDecSet (EA.DecSet decSet) =
        EA.DecSet
        {
          strs = sort (fn EA.STRB(_, name, _, _, _, _) => name) (#strs decSet),
          fcts = sort (fn EA.FCTB(_, name, _, _, _) => name) (#fcts decSet),
          sigs = sort (fn EA.SIGB(_, name, _, _, _, _) => name) (#sigs decSet),
          fsigs = sort (fn EA.FSIGB(_, name, _, _, _) => name) (#fsigs decSet),
          opens = #opens decSet,
          types =
          sort (fn EA.TB(_, name, _, _, _, _, _) => name) (#types decSet),
          datatypes =
          sort (fn EA.DB(_, name, _, _, _, _) => name) (#datatypes decSet),
          exceptions =
          sort
          (fn EA.EBGen(_, name, _, _, _) => name
            | EA.EBDef(_, name, _, _, _) => name)
          (#exceptions decSet),
          vals = sort (fn EA.VB(_, name, _, _, _) => name) (#vals decSet)
        }

  in
  fun generateSummaryListOfDecSet 
          (DGP as DGP.Parameter parameters) linkage (EA.DecSet decSet) =
      let
        val openSummaryList =
            blockOfSummaryList
            "Opened structures"
            blocksOfOpenSummary
            (#opens decSet)

        val signatureSummaryList =
            blockOfSummaryList
            "Inner Signature summary"
            blocksOfSignatureSummary
            (#sigs decSet)

        val structureSummaryList =
            blockOfSummaryList
            "Inner Structure summary"
            blocksOfStructureSummary
            (#strs decSet)

        val functorSignatureSummaryList = 
            blockOfSummaryList
            "Inner FunctorSignature summary"
            blocksOfFunctorSignatureSummary
            (#fsigs decSet)

        val functorSummaryList = 
            blockOfSummaryList
            "Inner Functor summary"
            blocksOfFunctorSummary
            (#fcts decSet)

        val typeSummaryList =
            blockOfSummaryList
            "Type summary"
            blocksOfTypeSummary
            (#types decSet)
        val datatypeSummaryList =
            blockOfSummaryList
            "Datatype summary"
            blocksOfDataTypeSummary
            (#datatypes decSet)
        val constructorSummaryList =
            blockOfSummaryList
            "DataConstructor summary"
            blocksOfValueConstructorSummary
            (sort
             (fn EA.CB(_, name, _, _, _, _) => name) 
             (getValueConstructors (#datatypes decSet)))
        val exceptionSummaryList =
            blockOfSummaryList
            "Exception summary"
            blocksOfExceptionSummary
            (#exceptions decSet)
        val valSummaryList =
            blockOfSummaryList
            "Value summary"
            blocksOfValSummary
            (#vals decSet)
      in
        [
          openSummaryList,
          signatureSummaryList,
          structureSummaryList,
          functorSignatureSummaryList,
          functorSummaryList,
          typeSummaryList,
          datatypeSummaryList,
          constructorSummaryList,
          valSummaryList,
          exceptionSummaryList
        ]
      end
  and generateDetailListOfDecSet 
          (DGP as DGP.Parameter parameters) linkage (EA.DecSet decSet) =
      let
        val typeDetailList =
            blockOfDetailList
            "Type detail"
            (blockOfTypeDetail DGP)
            (#types decSet)

        val datatypeDetailList = 
            blockOfDetailList
            "Datatype detail"
            (blockOfDataTypeDetail DGP)
            (#datatypes decSet)

        val constructorDetailList = 
            blockOfDetailList
            "DataConstructor detail"
            (blockOfValueConstructorDetail DGP)
            (getValueConstructors (#datatypes decSet))

        val exceptionDetailList = 
            blockOfDetailList
            "Exception detail"
            (blockOfExceptionDetail DGP)
            (#exceptions decSet)

        val valDetailList = 
            blockOfDetailList
            "Value detail"
            (blockOfValDetail DGP)
            (#vals decSet)

      in
        [
          typeDetailList,
          datatypeDetailList,
          constructorDetailList,
          valDetailList,
          exceptionDetailList
        ]
      end

  and generateForDecSet
          (DGP as DGP.Parameter parameters) linkage (EA.DecSet decSet) =
      let
        val structureDocs =
            List.concat(map (generateForStructure DGP linkage) (#strs decSet))
        val functorDocs =
            List.concat(map (generateForFunctor DGP linkage) (#fcts decSet))
        val signatureDocs =
            List.concat(map (generateForSignature DGP linkage) (#sigs decSet))
        val functorSignatureDocs =
            List.concat
            (map (generateForFunctorSignature DGP linkage) (#fsigs decSet))

        (********************)

        val bodyBlock =
            concatSummaryDetailList
            (
              if #showSummary parameters
              then
                generateSummaryListOfDecSet
                    DGP linkage (sortDecSet (EA.DecSet decSet))
              else [],
              generateDetailListOfDecSet DGP linkage (EA.DecSet decSet)
            )
      in
        (
          bodyBlock,
          (structureDocs @ functorDocs @ signatureDocs @ functorSignatureDocs)
        )
      end

  and generateForSpecSet
          (DGP as DGP.Parameter parameters) linkage (EA.SpecSet specSet) =
      let
        val EA.SpecSet sortedSpecSet = sortSpecSet (EA.SpecSet specSet)

        val structureDocs =
            List.concat(map (generateForSignature DGP linkage) (#strs specSet))

        val functorDocs = 
            List.concat
            (map (generateForFunctorSignature DGP linkage) (#fcts specSet))

        (********************)

        val includeSummaryList =
            blockOfSummaryList
            "Included signatures"
            blocksOfIncludeSummary
            (#includes sortedSpecSet)

        val structureSummaryList =
            blockOfSummaryList
            "Inner Structure summary"
            blocksOfSignatureSummary
            (#strs sortedSpecSet)

        val functorSummaryList = 
            blockOfSummaryList
            "Inner Functor summary"
            blocksOfFunctorSignatureSummary
            (#fcts sortedSpecSet)

        val typeSummaryList =
            blockOfSummaryList
            "Type summary"
            blocksOfTypeSummary
            (#types sortedSpecSet)
        val typeDetailList =
            blockOfDetailList
            "Type detail"
            (blockOfTypeDetail DGP)
            (#types specSet)

        val datatypeSummaryList =
            blockOfSummaryList
            "Datatype summary"
            blocksOfDataTypeSummary
            (#datatypes sortedSpecSet)
        val datatypeDetailList = 
            blockOfDetailList
            "Datatype detail"
            (blockOfDataTypeDetail DGP)
            (#datatypes specSet)

        val constructorSummaryList =
            blockOfSummaryList
            "DataConstructor summary"
            blocksOfValueConstructorSummary
            (sort
             (fn (EA.CB(_, name, _, _, _, _)) => name) 
             (getValueConstructors (#datatypes sortedSpecSet)))
        val constructorDetailList = 
            blockOfDetailList
            "DataConstructor detail"
            (blockOfValueConstructorDetail DGP)
            (getValueConstructors (#datatypes specSet))

        val exceptionSummaryList =
            blockOfSummaryList
            "Exception summary"
            blocksOfExceptionSummary
            (#exceptions sortedSpecSet)
        val exceptionDetailList = 
            blockOfDetailList
            "Exception detail"
            (blockOfExceptionDetail DGP)
            (#exceptions specSet)

        val valSummaryList =
            blockOfSummaryList
            "Value summary"
            blocksOfValSummary
            (#vals sortedSpecSet)
        val valDetailList = 
            blockOfDetailList
            "Value detail"
            (blockOfValDetail DGP)
            (#vals specSet)

        (********************)

        val bodyBlock =
            concatSummaryDetailList
            (if #showSummary parameters
             then
               [
                 includeSummaryList,
                 structureSummaryList,
                 functorSummaryList,
                 typeSummaryList,
                 datatypeSummaryList,
                 constructorSummaryList,
                 valSummaryList,
                 exceptionSummaryList
               ]
             else [],
             [
               typeDetailList,
               datatypeDetailList,
               constructorDetailList,
               valDetailList,
               exceptionDetailList
             ])
      in (bodyBlock, (structureDocs @ functorDocs)) end

  and generateForStructure
      (DGP as DGP.Parameter parameters)
      linkage
      (bind as EA.STRB(currentFQN, name, loc, strExp, sigConst, optDC)) =
      let
        val declarationFormat =
            if #showSummary parameters then [] else formatStrBind bind
        val moduleHeader =
            blockOfModuleHeader
                DGP linkage (currentFQN, loc, declarationFormat, optDC)

        fun getDetailAndSubDocs (EA.BaseStr(decSet)) =
            generateForDecSet DGP linkage decSet
          | getDetailAndSubDocs (EA.ConstrainedStr(strExp, _)) =
            getDetailAndSubDocs strExp
          | getDetailAndSubDocs _ = (HTML.mkP (HTML.PCDATA ""), [])
        val (moduleDetail, subDocs) = getDetailAndSubDocs strExp

        val docForThis =
            bodyBlockOfModulePage (currentFQN, moduleHeader, moduleDetail)
      in
        (currentFQN, docForThis) :: subDocs
      end

  and generateForSignature
      (DGP as DGP.Parameter parameters)
      linkage
      (bind as EA.SIGB(currentFQN, name, loc, sigExp, _, optDC)) =
      let
        val declarationFormat =
            if #showSummary parameters then [] else formatSigBind bind
        val moduleHeader =
            blockOfModuleHeader
                DGP linkage (currentFQN, loc, declarationFormat, optDC)

        fun getDetailAndSubDocs (EA.BaseSig(specSet)) =
            generateForSpecSet DGP linkage specSet
          | getDetailAndSubDocs (EA.AugSig(sigExp, _)) =
            getDetailAndSubDocs sigExp
          | getDetailAndSubDocs _ = (HTML.mkP (HTML.PCDATA ""), [])
        val (moduleDetail, subDocs) = getDetailAndSubDocs sigExp

        val docForThis =
            bodyBlockOfModulePage (currentFQN, moduleHeader, moduleDetail)
      in
        (currentFQN, docForThis) :: subDocs
      end

  and generateForFunctor
      (DGP as DGP.Parameter parameters)
      linkage
      (bind as EA.FCTB(currentFQN, name, loc, fctExp, optDC)) =
      let
        val declarationFormat =
            if #showSummary parameters then [] else formatFctBind bind
        val moduleHeader =
            blockOfModuleHeader
                DGP linkage (currentFQN, loc, declarationFormat, optDC)

        fun getDetailAndSubDocs (EA.BaseStr(decSet)) =
            generateForDecSet DGP linkage decSet
          | getDetailAndSubDocs (EA.ConstrainedStr(strExp, _)) =
            getDetailAndSubDocs strExp
          | getDetailAndSubDocs _ = (HTML.mkP (HTML.PCDATA ""), [])
        val (moduleDetail, subDocs) = 
            case fctExp of
              EA.BaseFct{body, ...} => getDetailAndSubDocs body
            | _ => (HTML.mkP (HTML.PCDATA ""), [])

        val docForThis =
            bodyBlockOfModulePage (currentFQN, moduleHeader, moduleDetail)
      in
        (currentFQN, docForThis) :: subDocs
      end

  and generateForFunctorSignature
      (DGP as DGP.Parameter parameters)
      linkage
      (bind as EA.FSIGB(currentFQN, name, loc, fsigExp, optDC)) =
      let
        val declarationFormat =
            if #showSummary parameters then [] else formatFsigBind bind
        val moduleHeader =
            blockOfModuleHeader
                DGP linkage (currentFQN, loc, declarationFormat, optDC)

        fun getDetailAndSubDocs (EA.BaseSig(specSet)) =
            generateForSpecSet DGP linkage specSet
          | getDetailAndSubDocs (EA.AugSig(sigExp, _)) =
            getDetailAndSubDocs sigExp
          | getDetailAndSubDocs _ = (HTML.mkP (HTML.PCDATA ""), [])
        val (moduleDetail, subDocs) = 
            case fsigExp of
              EA.BaseFsig{result, ...} => getDetailAndSubDocs result
            | _ => (HTML.mkP (HTML.PCDATA ""), [])

        val docForThis =
            bodyBlockOfModulePage (currentFQN, moduleHeader, moduleDetail)
      in
        (currentFQN, docForThis) :: subDocs
      end

  fun generateForTopLevelDecSet
          (DGP as DGP.Parameter parameters) linkage units =
      let
        val EA.DecSet decSet =
            foldl
                EA.appendDecSet
                EA.emptyDecSet
                (map (fn EA.CompileUnit(_, decSet) => decSet) units)

        val structureDocs =
            List.concat(map (generateForStructure DGP linkage) (#strs decSet))
        val functorDocs =
            List.concat(map (generateForFunctor DGP linkage) (#fcts decSet))
        val signatureDocs =
            List.concat(map (generateForSignature DGP linkage) (#sigs decSet))
        val functorSignatureDocs =
            List.concat
            (map (generateForFunctorSignature DGP linkage) (#fsigs decSet))

        (********************)

        val bodyBlock =
            concatSummaryDetailList
            (
              generateSummaryListOfDecSet
                  DGP linkage (sortDecSet (EA.DecSet decSet)),
              generateDetailListOfDecSet DGP linkage(EA.DecSet decSet)
            )
      in
        (
          bodyBlock,
          (structureDocs @ functorDocs @ signatureDocs @ functorSignatureDocs)
        )
      end

  end (* end of local *)

  fun blockOfSourceCode fileName =
      let
        val sourceStream = TextIO.openIn fileName
        fun scan lineNumber lineHTMLs =
            case TextIO.inputLine sourceStream of
              "" => lineHTMLs
            | line =>
              let
                val lineNumberString = makeLineAnchor lineNumber
                val lineHTML =
                    HTML.textList
                    [
                      HTML.mkA_NAME
                      {name = lineNumberString, content = HTML.PCDATA("")},
                      HTML.FONT
                          {
                            size = NONE,
                            color = SOME "green",
                            content = HTML.PCDATA lineNumberString
                          },
                      HTML.PCDATA "  ",
                      HTML.PCDATA (escapeHTML line)
                    ]
              in
                scan (lineNumber + 1) (lineHTML :: lineHTMLs)
              end
        val lineHTMLs = List.rev(scan 1 [])
        val block = HTML.PRE{width = NONE, content = HTML.textList lineHTMLs}
      in
        TextIO.closeIn sourceStream;
        block
      end


  (************************************************************)
      
  fun generateDocument (DGP as DGP.Parameter parameters) units =
      let
        val moduleFrameName = "moduleFrame"
        val moduleListFrameName = "moduleListFrame"
        val topFileName = "index.html"
        val overviewFileName = "overview-summary.html"
        val indexAllFileName = "index-all.html"
        fun makeIndexFileName name = "index-" ^ name ^ ".html"
        val moduleListFileName = "modules.html"
        val helpFileName =
            case #helpfile parameters of
              SOME file => file
            | NONE => "help-doc.html"

        fun emitHTML (fileName, documentHTML) =
            let
              val filePath = OS.Path.concat(#directory parameters, fileName)
              val _ = DGP.onProgress DGP ("generating :" ^ filePath)
              val outStream = TextIO.openOut filePath
            in
              PrHTML.prHTML
              {
                putc = fn c => TextIO.output1 (outStream, c),
                puts = fn s => TextIO.output (outStream, s)
              }
              documentHTML
              handle e => (TextIO.closeOut outStream; raise e);
              TextIO.closeOut outStream
            end

        fun HTMLFromBodyBlock
                (navigatedPages : navigatedPages)
                additionalNavBarBlockOpt
                (title, documentBodyBlock) =
            let
              val navigatedPages' =
                  {
                    overview = #overview navigatedPages,
                    index =
                    if #index parameters then #index navigatedPages else NONE,
                    uses =
                    if #uses parameters then #uses navigatedPages else NONE,
                    help =
                    if #help parameters then #help navigatedPages else NONE
                  }

              fun makeNavBar sideStringOpt =
                  HTML.blockList
                  ((if #navbar parameters
                    then blockOfNavigationBar sideStringOpt navigatedPages'
                    else
                      case sideStringOpt of
                        NONE => HTML.mkP(HTML.PCDATA "")
                      | SOME sideString => HTML.mkP(HTML.PCDATA sideString)) ::
                   (case additionalNavBarBlockOpt of
                      NONE => []
                    | SOME block => [block]))
              val headerNavigationBar = makeNavBar (#header parameters)
              val footerNavigationBar = makeNavBar (#footer parameters)

              val HTMLheaders =
                  HTML.Head_TITLE (title) ::
                  (case #charSet parameters of
                     NONE => []
                   | SOME charSet =>
                     [HTML.Head_META
                      {
                        httpEquiv = SOME "content-type",
                        name = NONE,
                        content = "text/html; charset=" ^ charSet
                      }])

              val bodyBlock =
                  HTML.blockList
                  (headerNavigationBar ::
                   [HTML.HR, documentBodyBlock, HTML.HR] @
                   [footerNavigationBar] @
                   (case #bottom parameters of
                      NONE => []
                    | SOME bottom =>
                      [HTML.HR, HTML.TextBlock(HTML.PCDATA bottom)]))
                     
              val body = 
                  HTML.BODY
                  {
                    background = NONE,
                    bgcolor = NONE,
                    text = NONE,
                    link = NONE,
                    vlink = NONE,
                    alink = NONE,
                    content = bodyBlock
                  }
            in
              HTML.HTML{version = NONE, head = HTMLheaders, body = body}
            end

        (****************************************)

        val _ = DGP.onProgress DGP "Summarizing"
        val (binds, linkage) = S.summarize units
        val (overviewDetail, moduleDocuments) =
            generateForTopLevelDecSet DGP linkage units

        (****************************************)

        val HTMLsOfIndexes =
            if #index parameters
            then
              let
                val nameAndBlocks =
                    map
                    (fn (name, block) =>
                        (
                          name,
                          HTML.blockList
                          [
                            HTML.TextBlock
                            (HTML.mkA_NAME
                             {name = name, content = HTML.PCDATA""}),
                            block
                          ]
                        ))
                    (bodyBlocksOfIndexes binds)
                val fileNameAndBlocks =
                    if #splitIndex parameters
                    then 
                      map
                      (fn (name, block) => (makeIndexFileName name, block))
                      nameAndBlocks
                    else 
                      (* insert HR and anchors *)
                      [(
                         indexAllFileName,
                         HTML.blockList
                             (U.interleave HTML.HR (map #2 nameAndBlocks))
                      )]
                val fileNameOfName = 
                    if #splitIndex parameters
                    then makeIndexFileName
                    else (fn name => indexAllFileName)
                val indexOfIndexesBlock =
                    HTML.TextBlock
                    (HTML.textList
                     (U.interleave
                      (HTML.PCDATA "&nbsp;")
                      (map
                       (fn (name, _) =>
                           HTML.mkA_HREF
                           {
                             href = fileNameOfName name ^ "#" ^ name,
                             content = HTML.PCDATA name
                           })
                       nameAndBlocks)))
              in
                map
                (fn (fileName, block) =>
                    (
                      fileName,
                      HTMLFromBodyBlock
                      {
                        overview = SOME(SOME overviewFileName),
                        uses = SOME NONE,
                        index = SOME NONE,
                        help = SOME(SOME helpFileName)
                      }
                      (SOME indexOfIndexesBlock)
                      ("Index", block))
                    )
                fileNameAndBlocks
              end 
            else []
        val firstIndexFileNameOpt =
            case HTMLsOfIndexes of
              [] => NONE
            | (fileName, _) :: _ => SOME fileName

        (****************************************)

        val HTMLsOfSources =
            if #linkSource parameters
            then
              map
                  (fn EA.CompileUnit(sourceFileName, _) =>
                      let val bodyBlock = blockOfSourceCode sourceFileName
                      in
                        (
                          makeFileNameForSource sourceFileName,
                          HTMLFromBodyBlock
                              {
                                overview = SOME(SOME overviewFileName),
                                uses = SOME NONE,
                                index = SOME(firstIndexFileNameOpt),
                                help = SOME(SOME helpFileName)
                              }
                              NONE
                              ("Source", bodyBlock)
                        )
                      end)
                  units
            else []

        (****************************************)

        local
          val customOverviewText =
              case #overview parameters of
                NONE => ""
              | SOME fileName =>
                let
                  val stream = TextIO.openIn fileName
                  val content = TextIO.inputAll stream
                  val body =
                      EasyHTMLParser.getBodyOfHTML
                      (fn message => DGP.warn DGP (fileName ^ ": " ^ message))
                      content
                in TextIO.closeIn stream; body end
        in
        val HTMLOfOverview =
            HTMLFromBodyBlock
            {
              overview = SOME NONE,
              uses = SOME NONE,
              index = SOME(firstIndexFileNameOpt),
              help = SOME(SOME helpFileName)
            }
            NONE
            ("Overview",
             bodyBlockOfOverviewPage
                 (#docTitle parameters, overviewDetail, customOverviewText))
        end

        (****************************************)

        val HTMLOfHelpOpt =
            case #helpfile parameters of
              NONE =>
              SOME
              (HTMLFromBodyBlock
               {
                 overview = SOME(SOME overviewFileName),
                 uses = SOME NONE,
                 index = SOME(firstIndexFileNameOpt),
                 help = SOME NONE
               }
               NONE
               (
                 "Help",
                 bodyBlockOfDefaultHelp
                 {
                   overviewFileName = overviewFileName,
                   indexFileNameOpt = firstIndexFileNameOpt,
                   hasUses = #uses parameters
                 }
               )
              )
            | SOME _ => NONE
             (* ToDo : we should copy the user specified help file ??? *)

        fun HTMLOfModule (moduleFQN, documentBodyBlock) =
            let
              val HTML =
                  HTMLFromBodyBlock
                  {
                    overview = SOME(SOME overviewFileName),
                    uses = SOME NONE,
                    index = SOME(firstIndexFileNameOpt),
                    help = SOME(SOME helpFileName)
                  }
                  NONE
                  (EA.moduleFQNToString moduleFQN, documentBodyBlock)
              val fileName = makeFileNameForModule moduleFQN
            in
              (fileName, HTML)
            end

        (****************************************)

        val HTMLOfModuleList =
            HTMLOfModuleList
            moduleFrameName
            overviewFileName
            (#listSubModule parameters)
            moduleDocuments

        val HTMLOfFrame =
            HTMLOfFrame
            (
              #windowTitle parameters,
              (moduleListFrameName, moduleListFileName),
              (moduleFrameName, overviewFileName)
            )

        (****************************************)

      in
        emitHTML (topFileName, HTMLOfFrame);
        emitHTML (moduleListFileName, HTMLOfModuleList);
        emitHTML (overviewFileName, HTMLOfOverview);
        app emitHTML HTMLsOfIndexes;
        app emitHTML HTMLsOfSources;
        case HTMLOfHelpOpt of
          NONE => ()
        | SOME HTMLOfHelp => emitHTML (helpFileName, HTMLOfHelp);
        app (emitHTML o HTMLOfModule) moduleDocuments
      end

  (***************************************************************************)

end