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

  fun getPos Loc.EOF = raise Fail "Bug: getPos"
    | getPos (Loc.AT {pos, ...}) = pos

  fun posOf Loc.NOPOS = raise Fail "BUG: locToPos"
    | posOf (Loc.POS {pos, ...}) = getPos pos

  fun parseFormatComments {filename, content, posToLoc, commentPos} beg loc =
      let
        val left = posOf (#1 loc)
        val leftmost = case commentPos left of
                         NONE => left
                       | SOME (_, leftmost) => leftmost
        val source = ref (String.substring (content, leftmost, left - leftmost))
        fun input n = !source before source := ""
        val errors = ref nil
        fun error (s, p1, p2) = errors := (s, (p1, p2)) :: !errors
        val lexarg = FormatCommentLex.UserDeclarations.initArg
                       {error = error, offset = leftmost}
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

  fun locToRegion (pos1, pos2) = (posOf pos1, posOf pos2)

  fun scanLongid (longsymbol, _) =
      map (Symbol.toString o #1) longsymbol

  fun scanTyvar ((_, (symbol, _)) : A.tyvar) =
      S.Tyv (Symbol.toString symbol)

  fun scanTy ty =
      let
        fun unsupported loc msg =
            raise ParseError
                  [Loc.locToString loc ^ ": unsupported type term: " ^ msg]
      in
        case ty of
          A.TYWILD loc => unsupported loc "TYWILD"
        | A.TYVAR tyvar => S.VarTy (scanTyvar tyvar)
        | A.TYVAR_FREE (_, _, loc) => unsupported loc "FREE_TYID"
        | A.TYRECORD (_, true, loc) => unsupported loc "TYRECORD"
        | A.TYRECORD (fields, false, loc) =>
          S.RecordTy
            (map (fn ((l, _), t, _) => (RecordLabel.toString l, scanTy t))
                 fields)
        | A.TYCON ((tyList, _), longsymbol, loc) =>
          S.ConTy (scanLongid longsymbol, map scanTy tyList)
        | A.TYTUPLE (tyList, loc) =>
          S.TupleTy (map scanTy tyList)
        | A.TYFUN (ty1, ty2, loc) =>
          S.ConTy (["->"], [scanTy ty1, scanTy ty2])
        | A.TYPOLY (tyvars, ty, loc) => unsupported loc "TYPOLY"
        | A.TYPAREN (ty, loc) => scanTy ty
      end

  fun scanTb c ((tyvars, _), tyConSymbol, ty, loc) =
      S.Tb {innerHeaderFormatComments = scanInnerHeaderFormatComments c loc,
            formatComments = scanDefiningFormatComments c (AbsynUtils.tyLoc ty),
            tyConName = Symbol.toString (#1 tyConSymbol),
            ty = scanTy ty,
            tyvars = map scanTyvar tyvars}

  fun scanTypeDec c (tbs, loc) =
      S.TypeDec
        {formatComments = scanHeaderFormatComments c loc,
         tbs = map (scanTb c) tbs,
         region = locToRegion loc}

  fun scanDbrhs c ((_, (conSymbol, _), _), tyOpt, loc) =
      {formatComments = scanDefiningFormatComments c loc,
       valConName = Symbol.toString conSymbol,
       argTypeOpt = Option.map scanTy tyOpt}

  fun scanDb c ((tyvars, _), (tyConSymbol, _), rhs, loc) =
      S.Db {innerHeaderFormatComments = scanInnerHeaderFormatComments c loc,
            tyConName = Symbol.toString tyConSymbol,
            tyvars = map scanTyvar tyvars,
            rhs = S.Constrs (map (scanDbrhs c) rhs)}

  fun scanDatatypeDec c (datatys, withtys, loc) =
      S.DatatypeDec
        {formatComments = scanHeaderFormatComments c loc,
         datatycs = map (scanDb c) datatys,
         withtycs = map (scanTb c) withtys,
         region = locToRegion loc}

  fun scanDatatypeRep c ((defSymbol, defSymbolLoc), refLongsymbol, loc) =
      S.DatatypeDec
        {formatComments = scanHeaderFormatComments c loc,
         datatycs =
           [S.Db
              {innerHeaderFormatComments =
                 scanInnerHeaderFormatComments c defSymbolLoc,
               tyConName = Symbol.toString defSymbol,
               tyvars = nil,
               rhs = S.Repl (scanLongid refLongsymbol)}],
         withtycs = nil,
         region = locToRegion loc}

  fun scanAbstypeDec c (abstys, withtys, body, loc) =
      S.AbstypeDec
        {formatComments = scanHeaderFormatComments c loc,
         abstycs = map (scanDb c) abstys,
         withtycs = map (scanTb c) withtys,
         bodyBeginPos =
           case body of
             nil => #2 (locToRegion loc) - 3
           | dec :: _ => #1 (locToRegion (AbsynUtils.decLoc dec)) - 1,
         region = locToRegion loc}

  fun scanEb c exbind =
      case exbind of
        A.EXBIND ((_, (conSymbol, _), _), tyOpt, loc) =>
        let
          val (innerHeaderFormatComments, definingFormatComments) =
              scanDefiningFormatCommentsWithInners c loc
        in
          S.EbGen {innerHeaderFormatComments = innerHeaderFormatComments,
                   formatComments = definingFormatComments,
                   exn = Symbol.toString conSymbol,
                   etype = Option.map scanTy tyOpt}
        end
      | A.EXBINDREP ((_, (conSymbol, _), _), (_, refLongsymbol, _), loc) =>
        let
          val (innerHeaderFormatComments, definingFormatComments) =
              scanDefiningFormatCommentsWithInners c loc
        in
          S.EbDef {innerHeaderFormatComments = innerHeaderFormatComments,
                   formatComments = definingFormatComments,
                   exn = Symbol.toString conSymbol,
                   edef = scanLongid refLongsymbol}
        end

  fun scanExceptionDec c (exbinds, loc) =
      S.ExceptionDec
        {formatComments = scanHeaderFormatComments c loc,
         ebs = map (scanEb c) exbinds,
         region = locToRegion loc}

  and scanDec c dec =
      case dec of
        A.DECVAL (tvars, rules, loc) => [S.ValDec]
      | A.DECPOLYREC (binds, loc1) => [S.ValrecDec]
      | A.DECFUN (tvars, frules, loc) => [S.FunDec]
      | A.DECTYPE x => [scanTypeDec c x]
      | A.DECDATATYPE x => [scanDatatypeDec c x]
      | A.DECABSTYPE x => [scanAbstypeDec c x]
      | A.DECOPEN (strids, loc) => [S.OpenDec]
      | A.DECDATATYPEREP x => [scanDatatypeRep c x]
      | A.DECEXCEPTION x => [scanExceptionDec c x]
      | A.DECLOCAL (decList1, decList2, loc) =>
        [S.LocalDec (scanDecList c decList1, scanDecList c decList2)]
      | A.DECINFIX (prec, ids, loc) => [S.FixDec]
      | A.DECINFIXR (prec, ids, loc) => [S.FixDec]
      | A.DECNONFIX (ids, loc) => [S.FixDec]
      | A.DECSEMICOLON _ => []

  and scanDecList c decList =
      S.SeqDec (List.concat (map (scanDec c) decList))

  and scanStrexp c strexp =
      case strexp of
        A.STRBASIC (strdecList, loc) =>
        S.BaseStr (scanStrdecList c strdecList)
      | A.STRID (id, loc) => S.VarStr
      | A.STRCONSTRAINT (strexp, _, sigexp, loc) =>
        S.ConstrainedStr (scanStrexp c strexp)
      | A.STRAPP (id, funarg, loc) => S.AppStr
      | A.STRLET (strdecList, strexp, loc) =>
        S.LetStr (scanStrdecList c strdecList, scanStrexp c strexp)

  and scanStrbind c (id, sigcon, strexp, loc) =
      S.Strb {name = Symbol.toString (#1 id),
              def = scanStrexp c strexp}

  and scanStrdec c strdec =
      case strdec of
        A.STRDEC dec => scanDec c dec
      | A.STRUCTURE (binds, loc) => [S.StrDec (map (scanStrbind c) binds)]
      | A.STRLOCAL (strdecList1, strdecList2, loc) =>
        [S.LocalDec (scanStrdecList c strdecList1,
                     scanStrdecList c strdecList2)]
      | A.STRSEMICOLON _ => []

  and scanStrdecList c strdecList =
      S.SeqDec (List.concat (map (scanStrdec c) strdecList))

  and scanFunbind c (funid, funarg, sigcon, strexp, loc) =
      S.Fctb {name = Symbol.toString (#1 funid),
              def = S.BaseFct {body = scanStrexp c strexp}}

  and scanTopdec c topdec =
      case topdec of
        A.TOPSTRDEC strdec => scanStrdec c strdec
      | A.TOPSIGNATURE (sigbind, loc) => [S.SigDec]
      | A.TOPFUNCTOR (funbinds, loc) =>
        [S.FctDec (map (scanFunbind c) funbinds)]
      | A.TOPEXP exp => nil

  and scanTop c top =
      case top of
        A.TOPDEC (topdecs, loc) => List.concat (map (scanTopdec c) topdecs)
      | A.USE (path, loc) => nil
      | A.USE' (path, loc) => nil
      | A.TOPSEMICOLON _ => nil

  and scanUnitparseresult c result =
      case result of
        A.UNIT (interface, tops, loc) => List.concat (map (scanTop c) tops)
      | A.EOF => nil

  fun makeCommMap map NIL = map
    | makeCommMap map (tokens ::> (Token.EOF, _)) =
      makeCommMap map tokens
    | makeCommMap map (tokens ::> (Token.COMMENT, _)) =
      makeCommMap map tokens
    | makeCommMap map (tokens ::> (_, (pos, _))) =
      let
        val left = getPos pos
        fun loop (tokens ::> (Token.COMMENT, (pos, _))) _ =
            loop tokens (SOME (getPos pos))
          | loop tokens NONE = makeCommMap map tokens
          | loop tokens (SOME pos) = makeCommMap ((left, pos) :: map) tokens
      in
        loop tokens NONE
      end

  fun makeCommentMap tokens =
      Vector.fromList (makeCommMap nil tokens)

  fun binarySearch f vec b e =
      if b >= e then NONE else
      let
        val c = (b + e) div 2
        val item = Vector.sub (vec, c)
      in
        case f item of
          EQUAL => SOME item
        | GREATER => binarySearch f vec (c + 1) e
        | LESS => binarySearch f vec b c
      end

  fun findCommentMap map pos =
      binarySearch (fn (k, _) => Int.compare (pos, k)) map 0 (Vector.length map)

  fun parse (filename, content) =
      let
        val fname = Filename.fromString filename
        val source = ref content
        val input =
            SMLSharpParser.setup
              {source = Loc.FILE (Loc.USERPATH, fname),
               read = fn _ => !source before source := "",
               initialLineno = 1}
        val (tokens, result) =
            SMLSharpParser.parse input
            handle SMLSharpParser.Error errors =>
                   raise ParseError
                         (map (fn (loc, msg) =>
                                  Loc.locToString loc ^ ": " ^ msg)
                              errors)
        val lineMap = lazyLineMap content
        val posToLoc = fn n => findLineMap (!lineMap ()) n
        val commentMap = makeCommentMap tokens
        val commentPos = findCommentMap commentMap
        val c = {filename = filename, content = content, posToLoc = posToLoc,
                 commentPos = commentPos}
        val decs = scanUnitparseresult c result
      in
        (decs, posToLoc)
      end

end
