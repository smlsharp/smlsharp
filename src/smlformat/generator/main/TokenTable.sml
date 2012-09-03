(**
 * hash table for token recognition
 * @author COPYRIGHT (c) 1996 Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TokenTable.sml,v 1.4 2006/12/31 07:44:27 kiyoshiy Exp $
 *)
functor TokenTable (Tokens:ML_TOKENS) : sig

    val checkId : (string * int) -> (Tokens.svalue,int) Tokens.token
    val checkSymId : (string * int) -> (Tokens.svalue,int) Tokens.token
    val checkTyvar : (string * int) -> (Tokens.svalue,int) Tokens.token

  end = struct

    exception NotToken

    val symIdTbl =
        [
	  ("*"	, fn yypos => Tokens.ASTERISK(yypos,yypos+1)),
	  ("|"	, fn yypos => Tokens.BAR(yypos,yypos+1)),
	  (":"	, fn yypos => Tokens.COLON(yypos,yypos+1)),
	  (":>"	, fn yypos => Tokens.COLONGT(yypos,yypos+1)),
	  ("="	, fn yypos => Tokens.EQUALOP(yypos,yypos+1)),
	  ("#"	, fn yypos => Tokens.HASH(yypos,yypos+1)),
	  ("->"	, fn yypos => Tokens.ARROW(yypos,yypos+2)),
	  ("=>"	, fn yypos => Tokens.DARROW(yypos,yypos+2))
        ]

    val idTbl =
        [
	  ("and"	, fn yypos => Tokens.AND(yypos,yypos+3)),
	  ("abstype"	, fn yypos => Tokens.ABSTYPE(yypos,yypos+7)),
	  ("as"	, fn yypos => Tokens.AS(yypos,yypos+2)),
	  ("case"	, fn yypos => Tokens.CASE(yypos,yypos+4)),
	  ("datatype"	, fn yypos => Tokens.DATATYPE(yypos,yypos+8)),
	  ("else"	, fn yypos => Tokens.ELSE(yypos,yypos+4)),
	  ("end"	, fn yypos => Tokens.END(yypos,yypos+3)),
	  ("eqtype"	, fn yypos => Tokens.EQTYPE(yypos,yypos+6)),
	  ("exception", fn yypos => Tokens.EXCEPTION(yypos,yypos+9)),
	  ("do"	, fn yypos => Tokens.DO(yypos,yypos+2)),
	  ("fn"	, fn yypos => Tokens.FN(yypos,yypos+2)),
	  ("fun"	, fn yypos => Tokens.FUN(yypos,yypos+3)),
	  ("functor"	, fn yypos => Tokens.FUNCTOR(yypos,yypos+7)),
	  ("funsig"	, fn yypos => Tokens.FUNSIG(yypos,yypos+7)),
	  ("handle"	, fn yypos => Tokens.HANDLE(yypos,yypos+6)),
	  ("if"	, fn yypos => Tokens.IF(yypos,yypos+2)),
	  ("in"	, fn yypos => Tokens.IN(yypos,yypos+2)),
	  ("include"	, fn yypos => Tokens.INCLUDE(yypos,yypos+7)),
	  ("infix"	, fn yypos => Tokens.INFIX(yypos,yypos+5)),
	  ("infixr"	, fn yypos => Tokens.INFIXR(yypos,yypos+6)),
(*	  ("lazy"	, fn yypos => Tokens.LAZY(yypos,yypos+4)), *)
	  ("let"	, fn yypos => Tokens.LET(yypos,yypos+3)),
	  ("local"	, fn yypos => Tokens.LOCAL(yypos,yypos+5)),
	  ("nonfix"	, fn yypos => Tokens.NONFIX(yypos,yypos+6)),
	  ("of"	, fn yypos => Tokens.OF(yypos,yypos+2)),
	  ("op"	, fn yypos => Tokens.OP(yypos,yypos+2)),
	  ("open"	, fn yypos => Tokens.OPEN(yypos,yypos+4)),
(*	  ("overload"	, fn yypos => Tokens.OVERLOAD(yypos,yypos+8)), *)
	  ("raise"	, fn yypos => Tokens.RAISE(yypos,yypos+5)),
	  ("rec"	, fn yypos => Tokens.REC(yypos,yypos+3)),
	  ("sharing"	, fn yypos => Tokens.SHARING(yypos,yypos+7)),
	  ("sig"	, fn yypos => Tokens.SIG(yypos,yypos+3)),
	  ("signature", fn yypos => Tokens.SIGNATURE(yypos,yypos+9)),
	  ("struct"	, fn yypos => Tokens.STRUCT(yypos,yypos+6)),
	  ("structure", fn yypos => Tokens.STRUCTURE(yypos,yypos+9)),
	  ("then"	, fn yypos => Tokens.THEN(yypos,yypos+4)),
	  ("type"	, fn yypos => Tokens.TYPE(yypos,yypos+4)),
	  ("val"	, fn yypos => Tokens.VAL(yypos,yypos+3)),
	  ("where"	, fn yypos => Tokens.WHERE(yypos,yypos+5)),
	  ("while"	, fn yypos => Tokens.WHILE(yypos,yypos+5)),
	  ("with"	, fn yypos => Tokens.WITH(yypos,yypos+4)),
	  ("withtype"	, fn yypos => Tokens.WITHTYPE(yypos,yypos+8)),
	  ("orelse"	, fn yypos => Tokens.ORELSE(yypos,yypos+6)),
	  ("andalso"	, fn yypos => Tokens.ANDALSO(yypos,yypos+7))
        ]

  (* look-up an identifier.  If the symbol is found, the corresponding token is
   * generated with the position of its begining. Otherwise it is a regular
   *)
    fun checkId (str, yypos) = 
      let
	fun mkId () =
	    Tokens.ID(str, yypos, yypos+size(str))
      in
	case List.find (fn (s,_)=> s = str) idTbl of
          NONE => mkId()
	| SOME(_, tokFn) => tokFn yypos
      end

    fun checkSymId (str, yypos) = 
      case List.find (fn(s,_)=>s=str) symIdTbl of
        SOME(_, tokFn) => tokFn yypos
      | NONE => Tokens.ID(str, yypos, yypos+size(str))

    fun checkTyvar (str, yypos) = 
      Tokens.TYVAR (str,yypos,yypos+size (str))

  end

