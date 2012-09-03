(**
 * A multibyte string version of ParserComb in SML/NJ library
 * ((c) 1996 AT&T Research).
 * <p>
 * From the original SML/NJ version: 
 * Parser combinators over readers.  These are modeled after the Haskell
 * combinators of Hutton and Meijer.  The main difference is that they
 * return a single result, instead of a list of results.  This means that
 * "or" is a committed choice; once one branch succeeds, the others will not
 * be enabled.  While this is somewhat limiting, for many applications it
 * will not be a problem.  For more substantial parsing problems, one should
 * use ML-Yacc and/or ML-Lex.
 * </p>
 *)
functor CodecParserCombinatorBase
        (P
         : sig
             type string
             type char
             type substring
             val implode : char list -> string
             val getc : substring -> (char * substring) option
             val full : string -> substring
             val compareChar : char * char -> General.order
         end) : MULTI_BYTE_PARSER_COMBINATOR =
struct

  type char = P.char
  type string = P.string

  type ('a, 'strm) parser =
       (char, 'strm) StringCvt.reader -> ('a, 'strm) StringCvt.reader

  fun result v getc strm = SOME(v, strm)

  fun failure getc strm = NONE

  fun wrap (p, f) getc strm =
      case (p getc strm)
       of NONE => NONE
	| (SOME(x, strm)) => SOME(f x, strm)

  fun seqWith f (p1, p2) getc strm =
      case (p1 getc strm)
       of SOME(t1, strm1) =>
          (case (p2 getc strm1)
	    of SOME(t2, strm2) => SOME(f(t1, t2), strm2)
	     | NONE => NONE)
	| NONE => NONE

  fun seq (p1, p2) = seqWith (fn x => x) (p1, p2)

  fun bind (p1, p2') getc strm =
      case (p1 getc strm)
       of SOME(t1, strm1) => p2' t1 getc strm1
	| NONE => NONE

  fun eatChar pred getc strm =
      case getc strm
       of (res as SOME(c, strm')) => if (pred c) then res else NONE
	| _ => NONE

  fun char (c: char) = eatChar (fn c' => (P.compareChar(c, c') = EQUAL))

  fun string s getc strm =
      let
	fun eat (ss, strm) =
            case (P.getc ss, getc strm)
	     of (SOME(c1, ss'), SOME(c2, strm')) =>
		if (P.compareChar(c1, c2) = EQUAL)
                then eat(ss', strm') else NONE
	      | (NONE, _) => SOME(s, strm)
	      | _ => NONE
      in
	eat (P.full s, strm)
      end

  fun skipBefore pred p getc strm =
      let
	fun skip' strm =
            case getc strm
	     of NONE => NONE
	      | SOME(c, strm') => if (pred c) then skip' strm' else p getc strm
      in
	skip' strm
      end

  fun or (p1, p2) getc strm =
      case (p1 getc strm)
       of NONE =>
          (case (p2 getc strm)
	    of NONE => NONE
	     | res => res)
	| res => res

  fun or' l getc strm =
      let
	fun tryNext [] = NONE
	  | tryNext (p::r) =
            case (p getc strm)
	     of NONE => tryNext r
	      | res => res
      in
	tryNext l
      end

  fun zeroOrMore p getc strm =
      let
	val p = p getc
	fun parse (l, strm) =
            case (p strm)
	     of (SOME(item, strm)) => parse (item::l, strm)
	      | NONE => SOME(rev l, strm)
      in
	parse ([], strm)
      end

  fun oneOrMore p getc strm =
      case (zeroOrMore p getc strm)
       of (res as (SOME(_::_, _))) => res
	| _ => NONE

  fun option p getc strm =
      case (p getc strm)
       of SOME(x, strm) => SOME(SOME x, strm)
	| NONE => SOME(NONE, strm)

  (* parse a token consisting of characters satisfying the predicate.
   * If this succeeds, then the resulting string is guaranteed to be
   * non-empty.
   *)
  fun token pred getc strm =
      case (zeroOrMore (eatChar pred) getc strm)
       of (SOME(res as _::_, strm)) => SOME(P.implode res, strm)
	| _ => NONE

end;
