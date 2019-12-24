structure MLParser =
struct

  structure A = Absyn
  structure S = Ast
  structure T = FormatCommentLrVals.Tokens

  exception ParseError of string list

  fun getErrorMessage (fileName : string)
                      (posToLocation : int -> int * int)
                      (message : string, (beginPos, endPos) : Ast.region) =
      let
        val (beginLine, beginCol) = posToLocation beginPos
        val (endLine, endCol) = posToLocation endPos
      in
        String.concat
          [fileName, ":",
           Int.toString beginLine, ".", Int.toString beginCol,
           "-",
           Int.toString endLine, ".", Int.toString endCol,
           " ",
           message]
      end

  fun makeLineMap text =
      let
        fun loop s i r =
            if i >= size s then r
            else case String.sub (s, i) of
                   #"\n" => loop s (i + 1) ((i + 1) :: r)
                 | #"\r" =>
                   if String.sub (s, i + 1) = #"\n"
                   then loop s (i + 2) ((i + 2) :: r)
                   else loop s (i + 1) ((i + 1) :: r)
                 | _ => loop s (i + 1) r
      in
        rev (loop text 0 nil)
      end

  fun findLineMap lineMap pos =
      let
        fun loop x nil i k = (i, k - x)
          | loop x (y :: t) i k =
            if y > k then (i, k - x) else loop y t (i + 1) k
      in
        loop 0 lineMap 1 pos
      end

  fun lazyLineMap text =
      let
        val r = ref (fn () => nil)
      in
        r := (fn () => case makeLineMap text of m => (r := (fn () => m); m));
        r
      end

  fun parseFormatComments {filename, content, posToLoc} beg (loc:Loc.loc) =
      let
        val (gap, pos) =
            case loc of
              (Loc.POS {gap, pos, ...}, _) => (gap, pos)
            | (Loc.NOPOS, _) => raise Fail "BUG: parseFormatComments"
        val source = ref (String.substring (content, pos - gap, gap))
        fun input n = !source before source := ""
        val errors = ref nil
        fun error (s, p1, p2) = errors := (s, (p1, p2)) :: !errors
        val lexarg = FormatCommentLex.UserDeclarations.initArg
                       {error = error, offset = pos - gap}
        val lexer = FormatCommentLex.makeLexer input lexarg
        val stream = FormatCommentLrVals.Parser.makeStream {lexer = lexer}
        val stream = FormatCommentLrVals.Parser.consStream
                       (beg ((), ~1, ~1), stream)
        val (result, _) =
            FormatCommentLrVals.Parser.parse
              {lookahead = 15, stream = stream, error = error, arg = ()}
            handle FormatCommentLrVals.Parser.ParseError =>
                   raise ParseError
                         (map (getErrorMessage filename posToLoc) (!errors))
      in
        case !errors of
          nil => result
        | errors =>
          raise ParseError (map (getErrorMessage filename posToLoc) errors)
      end

  fun scanHeaderFormatComments c loc =
      case parseFormatComments c T.CONTEXT_HEADER loc of
        S.Header x => x
      | _ => raise Fail "BUG: scanHeaderFormatComments"

  fun scanInnerHeaderFormatComments c loc =
      case parseFormatComments c T.CONTEXT_INNER loc of
        S.InnerHeader x => x
      | _ => raise Fail "BUG: scanInnerHeaderFormatComments"

  fun scanDefiningFormatComments c loc =
      case parseFormatComments c T.CONTEXT_DEFINING loc of
        S.Defining x => x
      | _ => raise Fail "BUG: scanDefiningFormatComments"

  fun scanDefiningFormatCommentsWithInners c loc =
      case parseFormatComments c T.CONTEXT_DEFINING_WITH_INNER loc of
        S.DefiningWithInner x => x
      | _ => raise Fail "BUG: scanDefiningFormatCommentsWithInners"

  fun locToRegion (Loc.NOPOS, _) = raise Fail "BUG: locToRegion"
    | locToRegion (_, Loc.NOPOS) = raise Fail "BUG: locToRegion"
    | locToRegion (Loc.POS {pos = pos1, ...}, Loc.POS {pos = pos2, ...}) =
      (pos1, pos2)

  fun scanLongid longsymbol =
      map Symbol.symbolToString longsymbol

  fun scanTyvar ({symbol, isEq} : A.tvar) =
      S.Tyv (Symbol.symbolToString symbol)

  fun scanTy ty =
      let
        fun unsupported loc msg =
            raise ParseError
                  [Loc.locToString loc ^ ": unsupported type term: " ^ msg]
      in
        case ty of
          A.TYWILD loc => unsupported loc "TYWILD"
        | A.TYID (tyvar, loc) => S.VarTy (scanTyvar tyvar)
        | A.FREE_TYID {freeTvar, tvarKind, loc} => unsupported loc "FREE_TYID"
        | A.TYRECORD {ifFlex=true, fields, loc} => unsupported loc "TYRECORD"
        | A.TYRECORD {ifFlex=false, fields, loc} =>
          S.RecordTy
            (map (fn (l,t) => (RecordLabel.toString l, scanTy t)) fields)
        | A.TYCONSTRUCT (tyList, longsymbol, loc) =>
          S.ConTy (scanLongid longsymbol, map scanTy tyList)
        | A.TYTUPLE (tyList, loc) =>
          S.TupleTy (map scanTy tyList)
        | A.TYFUN (ty1, ty2, loc) =>
          S.ConTy (["->"], [scanTy ty1, scanTy ty2])
        | A.TYPOLY (tyvars, ty, loc) => unsupported loc "TYPOLY"
      end

  fun scanTb c {tyvars, tyConSymbol, ty = (ty, tyLoc), loc} =
      S.Tb {innerHeaderFormatComments = scanInnerHeaderFormatComments c loc,
            formatComments = scanDefiningFormatComments c tyLoc,
            tyConName = Symbol.symbolToString tyConSymbol,
            ty = scanTy ty,
            tyvars = map scanTyvar tyvars}

  fun scanTypeDec c {tbs, loc} =
      S.TypeDec
        {formatComments = scanHeaderFormatComments c loc,
         tbs = map (scanTb c) tbs,
         region = locToRegion loc}

  fun scanDbrhs c {opFlag, conSymbol, tyOpt, loc} =
      {formatComments = scanDefiningFormatComments c loc,
       valConName = Symbol.symbolToString conSymbol,
       argTypeOpt = Option.map scanTy tyOpt}

  fun scanDb c {tyvars, tyConSymbol, rhs, loc} =
      S.Db {innerHeaderFormatComments = scanInnerHeaderFormatComments c loc,
            tyConName = Symbol.symbolToString tyConSymbol,
            tyvars = map scanTyvar tyvars,
            rhs = S.Constrs (map (scanDbrhs c) rhs)}

  fun scanDatatypeDec c {datatys, withtys, loc} =
      S.DatatypeDec
        {formatComments = scanHeaderFormatComments c loc,
         datatycs = map (scanDb c) datatys,
         withtycs = map (scanTb c) withtys,
         region = locToRegion loc}

  fun scanDatatypeRep c {defSymbol, refLongsymbol, loc} =
      S.DatatypeDec
        {formatComments = scanHeaderFormatComments c loc,
         datatycs =
           [S.Db
              {innerHeaderFormatComments =
                 scanInnerHeaderFormatComments c (Symbol.symbolToLoc defSymbol),
               tyConName = Symbol.symbolToString defSymbol,
               tyvars = nil,
               rhs = S.Repl (scanLongid refLongsymbol)}],
         withtycs = nil,
         region = locToRegion loc}

  fun scanAbstypeDec c {abstys, withtys, body = (_, bodyLoc), loc} =
      S.AbstypeDec
        {formatComments = scanHeaderFormatComments c loc,
         abstycs = map (scanDb c) abstys,
         withtycs = map (scanTb c) withtys,
         bodyBeginPos = #1 (locToRegion bodyLoc),
         region = locToRegion loc}

  fun scanEb c exbind =
      case exbind of
        A.EXBINDDEF {opFlag, conSymbol, tyOpt, loc} =>
        let
          val (innerHeaderFormatComments, definingFormatComments) =
              scanDefiningFormatCommentsWithInners c loc
        in
          S.EbGen {innerHeaderFormatComments = innerHeaderFormatComments,
                   formatComments = definingFormatComments,
                   exn = Symbol.symbolToString conSymbol,
                   etype = Option.map scanTy tyOpt}
        end
      | A.EXBINDREP {opFlag1, conSymbol, refLongsymbol, opFlag2, loc} =>
        let
          val (innerHeaderFormatComments, definingFormatComments) =
              scanDefiningFormatCommentsWithInners c loc
        in
          S.EbDef {innerHeaderFormatComments = innerHeaderFormatComments,
                   formatComments = definingFormatComments,
                   exn = Symbol.symbolToString conSymbol,
                   edef = scanLongid refLongsymbol}
        end

  fun scanExceptionDec c {exbinds, loc} =
      S.ExceptionDec
        {formatComments = scanHeaderFormatComments c loc,
         ebs = map (scanEb c) exbinds,
         region = locToRegion loc}

  and scanDec c dec =
      case dec of
        A.DECVAL (tvars, rules, loc) => S.ValDec
      | A.DECREC (tvars, rules, loc1) => S.ValrecDec
      | A.DECPOLYREC (binds, loc1) => S.ValrecDec
      | A.DECFUN (tvars, frules, loc) => S.FunDec
      | A.DECTYPE x => scanTypeDec c x
      | A.DECDATATYPE x => scanDatatypeDec c x
      | A.DECABSTYPE x => scanAbstypeDec c x
      | A.DECOPEN (strids, loc) => S.OpenDec
      | A.DECREPLICATEDAT x => scanDatatypeRep c x
      | A.DECEXN x => scanExceptionDec c x
      | A.DECLOCAL (decList1, decList2, loc) =>
        S.LocalDec (S.SeqDec (map (scanDec c) decList1),
                    S.SeqDec (map (scanDec c) decList2))
      | A.DECINFIX (prec, ids, loc) => S.FixDec
      | A.DECINFIXR (prec, ids, loc) => S.FixDec
      | A.DECNONFIX (ids, loc) => S.FixDec

  and scanStrexp c strexp =
      case strexp of
        A.STREXPBASIC (strdecList, loc) =>
        S.BaseStr (S.SeqDec (map (scanStrdec c) strdecList))
      | A.STRID (id, loc) => S.VarStr
      | A.STRTRANCONSTRAINT (strexp, sigexp, loc) =>
        S.ConstrainedStr (scanStrexp c strexp)
      | A.STROPAQCONSTRAINT (strexp, sigexp, loc) =>
        S.ConstrainedStr (scanStrexp c strexp)
      | A.FUNCTORAPP (id, strexp, loc) => S.AppStr
      | A.STRUCTLET (strdecList, strexp, loc) =>
        S.LetStr (S.SeqDec (map (scanStrdec c) strdecList), scanStrexp c strexp)

  and scanStrbind c strbind =
      case strbind of
        A.STRBINDTRAN (id, sigexp, strexp, loc) =>
        S.Strb {name = Symbol.symbolToString id, def = scanStrexp c strexp}
      | A.STRBINDOPAQUE (id, sigexp, strexp, loc) =>
        S.Strb {name = Symbol.symbolToString id, def = scanStrexp c strexp}
      | A.STRBINDNONOBSERV (id, strexp, loc) =>
        S.Strb {name = Symbol.symbolToString id, def = scanStrexp c strexp}

  and scanStrdec c strdec =
      case strdec of
        A.COREDEC (dec, loc) => scanDec c dec
      | A.STRUCTBIND (binds, loc) => S.StrDec (map (scanStrbind c) binds)
      | A.STRUCTLOCAL (strdecList1, strdecList2, loc) =>
        S.LocalDec (S.SeqDec (map (scanStrdec c) strdecList1),
                    S.SeqDec (map (scanStrdec c) strdecList2))

  and scanFunbind c funbind =
      case funbind of
        A.FUNBINDTRAN (funid, argid, argsig, funsig, strexp, loc) =>
        S.Fctb {name = Symbol.symbolToString funid,
                def = S.BaseFct {body = scanStrexp c strexp}}
      | A.FUNBINDOPAQUE (funid, argid, argsig, funsig, strexp, loc) =>
        S.Fctb {name = Symbol.symbolToString funid,
                def = S.BaseFct {body = scanStrexp c strexp}}
      | A.FUNBINDNONOBSERV (funid, argid, argsig, strexp, loc) =>
        S.Fctb {name = Symbol.symbolToString funid,
                def = S.BaseFct {body = scanStrexp c strexp}}
      | A.FUNBINDSPECTRAN (funid, spec, funsig, strexp, loc) =>
        S.Fctb {name = Symbol.symbolToString funid,
                def = S.BaseFct {body = scanStrexp c strexp}}
      | A.FUNBINDSPECOPAQUE (funid, spec, funsig, strexp, loc) =>
        S.Fctb {name = Symbol.symbolToString funid,
                def = S.BaseFct {body = scanStrexp c strexp}}
      | A.FUNBINDSPECNONOBSERV (funid, spec, strexp, loc) =>
        S.Fctb {name = Symbol.symbolToString funid,
                def = S.BaseFct {body = scanStrexp c strexp}}

  and scanTopdec c topdec =
      case topdec of
        A.TOPDECSTR (strdec, loc) => scanStrdec c strdec
      | A.TOPDECSIG (sigbind, loc) => S.SigDec
      | A.TOPDECFUN (funbinds, loc) => S.FctDec (map (scanFunbind c) funbinds)

  and scanTop c top =
      case top of
        A.TOPDEC topdecs => map (scanTopdec c) topdecs
      | A.USE (path, loc) => nil

  and scanUnitparseresult c result =
      case result of
        A.UNIT {interface, tops, loc} => List.concat (map (scanTop c) tops)
      | A.EOF => nil

  fun parse (filename, content) =
      let
        val fname = Filename.fromString filename
        val source = ref content
        val input =
            SMLSharpParser.setup
              {source = Loc.FILE (Loc.USERPATH, fname),
               read = fn _ => !source before source := "",
               initialLineno = 1}
        val result =
            SMLSharpParser.parse input
            handle SMLSharpParser.Error errors =>
                   raise ParseError
                         (map (fn (loc, msg) =>
                                  Loc.locToString loc ^ ": " ^ msg)
                              errors)
        val lineMap = lazyLineMap content
        val posToLoc = fn n => findLineMap (!lineMap ()) n
        val c = {filename = filename, content = content, posToLoc = posToLoc}
        val decs = scanUnitparseresult c result
      in
        (decs, posToLoc)
      end

end
