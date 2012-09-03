(* string.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure StringImp : STRING =
  struct
    val op + = InlineT.DfltInt.+
    val op - = InlineT.DfltInt.-
    val op < = InlineT.DfltInt.<
    val op <= = InlineT.DfltInt.<=
    val op > = InlineT.DfltInt.>
    val op >= = InlineT.DfltInt.>=
(*    val op = = InlineT.= *)
    val unsafeSub = InlineT.CharVector.sub
    val unsafeUpdate = InlineT.CharVector.update

  (* list reverse *)
    fun rev ([], l) = l
      | rev (x::r, l) = rev (r, x::l)

    type char = char
    type string = string

    val maxSize = Core.max_length

  (* the length of a string *)
    val size = InlineT.CharVector.length

    val unsafeCreate = Assembly.A.create_s

  (* allocate an uninitialized string of given length *)
    fun create n = if (InlineT.DfltInt.ltu(maxSize, n))
	  then raise General.Size
	  else Assembly.A.create_s n

  (* convert a character into a single character string *)
    fun str (c : Char.char) : string =
	  InlineT.PolyVector.sub(PreString.chars, InlineT.cast c)

  (* get a character from a string *)
    val sub : (string * int) -> char = InlineT.CharVector.chkSub

  (* Return the n-character substring of s starting at position i.
   * NOTE: we use words to check the right bound so as to avoid
   * raising overflow.
   *)
    local
      structure W = InlineT.DfltWord
    in
    fun substring (s, i, n) =
	  if ((i < 0) orelse (n < 0)
	  orelse W.<(W.fromInt(size s), W.+(W.fromInt i, W.fromInt n)))
	    then raise General.Subscript
	    else PreString.unsafeSubstring (s, i, n)
    end (* local *)

    fun extract (v, base, optLen) = let
	  val len = size v
	  fun newVec n = let
		val newV = Assembly.A.create_s n
		fun fill i = if (i < n)
		      then (unsafeUpdate(newV, i, unsafeSub(v, base+i)); fill(i+1))
		      else ()
		in
		  fill 0; newV
		end
	  in
	    case (base, optLen)
	     of (0, NONE) => v
	      | (_, SOME 0) => if ((base < 0) orelse (len < base))
		    then raise General.Subscript
		    else ""
	      | (_, NONE) => if ((base < 0) orelse (len < base))
		      then raise General.Subscript
		    else if (base = len)
		      then ""
		      else newVec (len - base)
	      | (_, SOME 1) =>
		  if ((base < 0) orelse (len < base+1))
		    then raise General.Subscript
		    else str(unsafeSub(v, base))
	      | (_, SOME n) =>
		  if ((base < 0) orelse (n < 0) orelse (len < (base+n)))
		    then raise General.Subscript
		    else newVec n
	    (* end case *)
	  end

    fun op ^ ("", s) = s
      | op ^ (s, "") = s
      | op ^ (x, y) = PreString.concat2 (x, y)

  (* concatenate a list of strings together *)
    fun concat [s] = s
      | concat (sl : string list) = let
	fun length (i, []) = i
	  | length (i, s::rest) = length(i+size s, rest)
	in
	  case length(0, sl)
	   of 0 => ""
	    | 1 => let
		fun find ("" :: r) = find r
		  | find (s :: _) = s
		  | find _ = "" (** impossible **)
		in
		  find sl
		end
	    | totLen => let
		val ss = create totLen
		fun copy ([], _) = ()
		  | copy (s::r, i) = let
		      val len = size s
		      fun copy' j = if (j = len)
			    then ()
			    else (
			      unsafeUpdate(ss, i+j, unsafeSub(s, j));
			      copy'(j+1))
		      in
			copy' 0;
			copy (r, i+len)
		      end
		in
		  copy (sl, 0);  ss
		end
	  (* end case *)
	end (* concat *)

  (* concatenate a list of strings, using the given separator string *)
    fun concatWith _ [] = ""
      | concatWith _ [x] = x
      | concatWith sep (h :: t) =
	concat (rev (foldl (fn (x, l) => x :: sep :: l) [h] t, []))

  (* implode a list of characters into a string *)
    fun implode [] = ""
      | implode cl =  let
	  fun length ([], n) = n
	    | length (_::r, n) = length (r, n+1)
	  in
	    PreString.implode (length (cl, 0), cl)
	  end

  (* explode a string into a list of characters *)
    fun explode s = let
	  fun f(l, ~1) = l
	    | f(l,  i) = f(unsafeSub(s, i) :: l, i-1)
	  in
	    f(nil, size s - 1)
	  end

    fun map f vec = (case (size vec)
	   of 0 => ""
	    | len => let
		val newVec = Assembly.A.create_s len
		fun mapf i = if (i < len)
		      then (unsafeUpdate(newVec, i, f(unsafeSub(vec, i))); mapf(i+1))
		      else ()
		in
		  mapf 0; newVec
		end
	  (* end case *))

  (* map a translation function across the characters of a string *)
    fun translate tr s = PreString.translate (tr, s, 0, size s)

  (* tokenize a string using the given predicate to define the delimiter
   * characters.
   *)
    fun tokens isDelim s = let
	  val n = size s
	  fun substr (i, j, l) = if (i = j)
		then l
		else PreString.unsafeSubstring(s, i, j-i)::l
	  fun scanTok (i, j, toks) = if (j < n)
		  then if (isDelim (unsafeSub (s, j)))
		    then skipSep(j+1, substr(i, j, toks))
		    else scanTok (i, j+1, toks)
		  else substr(i, j, toks)
	  and skipSep (j, toks) = if (j < n)
		  then if (isDelim (unsafeSub (s, j)))
		    then skipSep(j+1, toks)
		    else scanTok(j, j+1, toks)
		  else toks
	  in
	    rev (scanTok (0, 0, []), [])
	  end
    fun fields isDelim s = let
	  val n = size s
	  fun substr (i, j, l) = PreString.unsafeSubstring(s, i, j-i)::l
	  fun scanTok (i, j, toks) = if (j < n)
		  then if (isDelim (unsafeSub (s, j)))
		    then scanTok (j+1, j+1, substr(i, j, toks))
		    else scanTok (i, j+1, toks)
		  else substr(i, j, toks)
	  in
	    rev (scanTok (0, 0, []), [])
	  end

  (* String comparisons *)
    fun isPrefix s1 s2 = PreString.isPrefix (s1, s2, 0, size s2)
    fun isSuffix s1 s2 =
	let val sz2 = size s2
	in
	    PreString.isPrefix (s1, s2, sz2 - size s1, sz2)
	end
    fun isSubstring s = let
	val stringsearch = PreString.kmp s
	fun search s' = let
	    val epos = size s'
	in
	    stringsearch (s', 0, epos) < epos
	end
    in
	search
    end

    fun compare (a, b) =
	PreString.cmp (a, 0, size a, b, 0, size b)
    fun collate cmpFn (a, b) =
	PreString.collate cmpFn (a, 0, size a, b, 0, size b)

  (* String greater or equal *)
    fun sgtr (a, b) = let
	  val al = size a and bl = size b
	  val n = if (al < bl) then al else bl
	  fun cmp i = if (i = n)
		then (al > bl)
		else let
		  val ai = unsafeSub(a,i)
		  val bi = unsafeSub(b,i)
		  in
		    Char.>(ai, bi) orelse ((ai = bi) andalso cmp(i+1))
		  end
	  in
	    cmp 0
	  end

    fun op <= (a,b) = if sgtr(a,b) then false else true
    fun op < (a,b) = sgtr(b,a)
    fun op >= (a,b) = b <= a
    val op > = sgtr

    fun fromString' scanChar s = let
	  val len = size s
	  fun getc i = if InlineT.DfltInt.<(i, len)
		then SOME(unsafeSub(s, i), i+1)
		else NONE
	  val scanChar = scanChar getc
	  fun accum (i, chars) = (case (scanChar i)
		 of NONE => if InlineT.DfltInt.<(i, len)
		      then NONE (* bad format *)
		      else SOME(implode(List.rev chars))
		  | (SOME(c, i')) => accum(i', c::chars)
		(* end case *))
	  in
	    accum (0, [])
	  end

    val fromString = fromString' Char.scan
    val toString = translate Char.toString

    val fromCString = fromString' Char.scanC
    val toCString = translate Char.toCString

  end (* structure String *)	   


