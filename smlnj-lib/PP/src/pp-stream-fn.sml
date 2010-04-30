(* pp-stream-fn.sml
 *
 * COPYRIGHT (c) 2005 John Reppy (http://www.cs.uchicago.edu/~jhr)
 * All rights reserved.
 *
 * The implementation of PP streams, where all the action is.
 *)

functor PPStreamFn (
    structure Token : PP_TOKEN
    structure Device : PP_DEVICE
      sharing type Token.style = Device.style
(**
  ) : PP_STREAM =
**)
  ) : sig include PP_STREAM val dump : (TextIO.outstream * stream) -> unit end =
  struct

    structure D = Device
    structure T = Token
    structure Q = Queue

    type device = D.device
    type token = T.token
    type style = T.style

    datatype indent
      = Abs of int		(* indent relative to outer indentation *)
      | Rel of int		(* indent relative to start of box *)

  (**** DATA STRUCTURES ****)
    datatype pp_token
      = TEXT of string			(* raw text.  This includes tokens.  The *)
					(* width and style information is taken *)
					(* care of when they are inserted in *)
					(* queue. *)
      | NBSP of int			(* some number of non-breakable spaces *)
      | BREAK of {nsp : int, offset : int}
      | BEGIN of (indent * box_type)
      | END
      | PUSH_STYLE of style
      | POP_STYLE
      | NL
      | IF_NL
      | CTL of (device -> unit)		(* device control operation *)

   and box_type = HBOX | VBOX | HVBOX | HOVBOX | BOX | FITS

    type pp_queue_elem = {	(* elements of the PP queue *)
	tok : pp_token,
	sz : int ref,			(* size of blok (set when known) *)
	len : int			(* length of token *)
      }

    datatype stream = PP of {
	dev : device,			(* the underlying device *)
	closed : bool ref,		(* set to true, when the stream is *)
					(* closed *)
	width : int,			(* the width of the device *)
	spaceLeft : int ref,		(* space left on current line *)
	curIndent : int ref,		(* current indentation *)
	curDepth : int ref,		(* current nesting level of boxes. *)
	leftTot : int ref,		(* total width of tokens already printed *)
	rightTot : int ref,		(* total width of tokens ever inserted *)
					(* into the queue. *)
	queue : pp_queue_elem Q.queue,	(* the queue of pending tokens *)
	fmtStk				(* stack of information about currently *)
	  : (box_type * int) list ref,	(* active blocks *)
	scanStk
	  : (int * pp_queue_elem) list ref,
	styleStk : style list ref
      }

  (**** DEBUGGING FUNCTIONS ****)
    structure F = Format
    fun boxTypeToString HBOX = "HBOX"
      | boxTypeToString VBOX = "VBOX"
      | boxTypeToString HVBOX = "HVBOX"
      | boxTypeToString HOVBOX = "HOVBOX"
      | boxTypeToString BOX = "BOX"
      | boxTypeToString FITS = "FITS"
    fun indentToString (Abs n) = concat["Abs ", Int.toString n]
      | indentToString (Rel n) = concat["Rel ", Int.toString n]
    fun tokToString (TEXT s) = concat["TEXT \"", String.toString s, "\""]
      | tokToString (NBSP n) = concat["NBSP ", Int.toString n]
      | tokToString (BREAK{nsp, offset}) =
	  F.format "BREAK{nsp=%d, offset=%d}" [F.INT nsp, F.INT offset]
      | tokToString (BEGIN(indent, ty)) = F.format "BEGIN(%s, %s)" [
	    F.STR(indentToString indent), F.STR(boxTypeToString ty)
	  ]
      | tokToString END = "END"
      | tokToString (PUSH_STYLE _) = "PUSH_STYLE _"
      | tokToString POP_STYLE = "POP_STYLE"
      | tokToString NL = "NL"
      | tokToString IF_NL = "IF_NL"
      | tokToString (CTL f) = "CTL _"
    fun qelemToString {tok, sz, len} = F.format "{tok=%s, sz=%d, len=%d}" [
	    F.STR(tokToString tok), F.INT(!sz), F.INT len
	  ]
    fun scanElemToString (n, elem) =
	  F.format "(%d, %s)" [F.INT n, F.STR(qelemToString elem)]
    fun dump (outStrm, PP pp) = let
	  fun pr s = TextIO.output(outStrm, s)
	  fun prf (fmt, items) = pr(F.format fmt items)
	  fun fmtElemToString (ty, n) =
		F.format "(%s, %d)" [F.STR(boxTypeToString ty), F.INT n]
	  fun prl fmtElem [] = pr "[]"
	    | prl fmtElem l = pr(ListFormat.fmt {
		  init = "[\n    ", final = "]", sep = "\n    ", fmt = fmtElem
		} l)
	  in
	    pr  ("BEGIN\n");
	    prf ("  width     = %3d\n", [F.INT(#width pp)]);
	    prf ("  curIndent = %3d, curDepth = %3d\n", [
		F.INT(!(#curIndent pp)), F.INT(!(#curDepth pp))
	      ]);
	    prf ("  leftTot   = %3d, rightTot = %3d\n", [
		F.INT(!(#leftTot pp)), F.INT(!(#rightTot pp))
	      ]);
	    prf ("  spaceLeft = %3d\n", [F.INT(!(#spaceLeft pp))]);
	    pr   "  queue = "; prl qelemToString (Q.contents(#queue pp)); pr "\n";
	    pr   "  fmtStk = "; prl fmtElemToString (!(#fmtStk pp)); pr "\n";
	    pr   "  scanStk = "; prl scanElemToString (!(#scanStk pp)); pr "\n";
	    pr  ("END\n")
	  end

  (**** UTILITY FUNCTIONS ****)

    val infinity = Option.getOpt(Int.maxInt, 1000000000)

  (* output functions *)
    fun output (PP{dev, ...}, s) = D.string(dev, s)
    fun outputNL (PP{dev, ...}) = D.newline dev
    fun blanks (_, 0) = ()
      | blanks (PP{dev, ...}, n) = D.space (dev, n)

  (* add a token to the pretty-printer queue *)
    fun enqueueTok (PP{rightTot, queue, ...}, tok) = (
	  rightTot := !rightTot + #len tok;
	  Q.enqueue(queue, tok))

  (* format a break as a newline; indenting the new line.
   *   strm	-- PP stream
   *   offset	-- the extra indent amount supplied by the break
   *   wid	-- the remaining line width at the opening of the
   *		   innermost enclosing box.
   *)
    fun breakNewLine (strm, offset, wid) = let
	  val PP{width, curIndent, spaceLeft, ...} = strm
	  val indent = (width - wid) + offset
(***** CAML version does the following: *****
	  val indent = min(maxIndent, indent)
*****)
	  in
	    curIndent := indent;
	    spaceLeft := width - indent;
	    outputNL strm;
	    blanks (strm, indent)
	  end

  (* format a break as spaces.
   *   strm	-- PP stream
   *   nsp	-- number of spaces to output.
   *)
    fun breakSameLine (strm as PP{spaceLeft, ...}, nsp) = (
	  spaceLeft := !spaceLeft - nsp;
	  blanks (strm, nsp))

(***** this function is in the CAML version, but is currently not used.
    fun forceLineBreak (strm as PP{fmtStk, spaceLeft, ...}) = (case !fmtStk
	   of ((ty, wid)::r) => if (wid > !spaceLeft)
		then (case ty
		   of (FITS | HBOX) => ()
		    | _ => breakNewLine (strm, 0, wid)
		  (* end case *))
		else ()
	    | _ => outputNL strm
	  (* end case *))
*****)

  (* return the current style of the PP stream *)
    fun currentStyle (PP{styleStk = ref [], dev, ...}) = D.defaultStyle dev
      | currentStyle (PP{styleStk = ref(sty::_), ...}) = sty

  (**** FORMATTING ****)

    fun format (strm, sz, tok) = (case tok
	   of (TEXT s) => let
		val PP{spaceLeft, ...} = strm
		in
		  spaceLeft := !spaceLeft - sz;
		  output(strm, s)
		end
	    | (NBSP n) => let
		val PP{spaceLeft, ...} = strm
		in
		  spaceLeft := !spaceLeft - sz;
		  blanks (strm, n)
		end
	    | (BREAK{nsp, offset}) => let
		val PP{fmtStk, spaceLeft, width, curIndent, ...} = strm
		in
		  case !fmtStk
		   of ((HBOX, wid)::_) => breakSameLine (strm, nsp)
		    | ((VBOX, wid)::_) => breakNewLine (strm, offset, wid)
		    | ((HVBOX, wid)::_) => breakNewLine (strm, offset, wid)
		    | ((HOVBOX, wid)::_) => if (sz > !spaceLeft)
			then breakNewLine (strm, offset, wid)
			else breakSameLine (strm, nsp)
		    | ((BOX, wid)::_) =>
			if ((sz > !spaceLeft)
			orelse (!curIndent > (width - wid)+offset))
			  then breakNewLine (strm, offset, wid)
			  else breakSameLine (strm, nsp)
		    | ((FITS, wid)::_) => breakSameLine (strm, nsp)
		    | _ => () (* no open box *)
		end
	    | (BEGIN(indent, ty)) => let
		val PP{curIndent, spaceLeft, width, fmtStk, ...} = strm
		val spaceLeft' = !spaceLeft
		val insPt = width - spaceLeft'
	      (* compute offset from right margin of this block's indent *)
		val offset = (case indent
		       of (Rel off) => spaceLeft' - off
			| (Abs off) => (case !fmtStk
			     of ((_, wid)::_) => wid - off
			      | _ => width - (!curIndent + off)
(* maybe this can be
			      | _ => width - off
??? *)
			    (* end case *))
		      (* end case *))
(***** CAML version does the following: ****
		val _ = if (insPt > maxIndent)
			then forceLineBreak strm
			else ()
*****)
		val ty' = (case ty
		       of VBOX => VBOX
			| _ => if (sz > spaceLeft') then ty else FITS
		      (* end case *))
		in
		  fmtStk := (ty', offset) :: !fmtStk
		end
	    | END => let
		val PP{fmtStk, ...} = strm
		in
		  case !fmtStk
		   of (_ :: (l as _::_)) => fmtStk := l
		    | _ => () (* error: no open blocks *)
		end
	    | (PUSH_STYLE sty) => let
		val PP{dev, ...} = strm
		in
		  D.pushStyle (dev, sty)
		end
	    | POP_STYLE => let
		val PP{dev, ...} = strm
		in
		  D.popStyle dev
		end
	    | NL => let
		val PP{fmtStk, ...} = strm
		in
		  case !fmtStk
		   of ((_, wid)::r) => breakNewLine (strm, 0, wid)
		    | _ => outputNL strm
		  (* end case *)
		end
	    | IF_NL => raise Fail "IF_NL"
	    | (CTL ctlFn) => let
		val PP{dev, ...} = strm
		in
		  ctlFn dev
		end
	  (* end case *))

    fun advanceLeft strm = let
	  val PP{spaceLeft, leftTot, rightTot, queue, ...} = strm
	  fun advance () = (case Q.peek queue
		 of (SOME{tok, sz=ref sz, len}) =>
		      if ((sz >= 0) orelse (!rightTot - !leftTot >= !spaceLeft))
			then (
			  ignore(Q.dequeue queue);
			  format (strm, if sz < 0 then infinity else sz, tok);
			  leftTot := len + !leftTot;
			  advance())
			else ()
		  | NONE => ()
		(* end case *))
	  in
	    advance ()
	  end

    fun enqueueAndAdvance (strm, tok) = (
	  enqueueTok (strm, tok);
	  advanceLeft strm)

    fun enqueueTokenWithLen (strm, tok, len) =
	  enqueueAndAdvance (strm, {sz = ref len, len = len, tok = tok})

    fun enqueueStringWithLen (strm, s, len) =
	  enqueueTokenWithLen (strm, TEXT s, len)

    fun enqueueToken (strm, tok) = enqueueTokenWithLen (strm, tok, 0)

  (* the scan stack always has this element on its bottom *)
    val scanStkBot = (~1, {sz = ref ~1, tok = TEXT "", len = 0})

  (* clear the scan stack *)
    fun clearScanStk (PP{scanStk, ...}) = scanStk := [scanStkBot]

  (* Set the size of the element on the top of the scan stack.  The isBreak
   * flag is set to true for breaks and false for boxes.
   *)
    fun setSize (strm, isBreak) = (
	(* NOTE: scanStk should never be empty *)
	  case strm
	   of PP { scanStk as ref [], ... } =>
		raise Fail "PPStreamFn:setSize: impossible: scanStk is empty"
	    | PP{leftTot, rightTot, scanStk as ref((leftTot', elem)::r), ...} =>
	      (* check for obsolete elements *)
		if (leftTot' < !leftTot)
		  then clearScanStk strm
		  else (case (elem, isBreak)
		     of ({sz, tok=BREAK _, ...}, true) => (
			  sz := !sz + !rightTot;
			  scanStk := r)
		      | ({sz, tok=BEGIN _, ...}, false) => (
			  sz := !sz + !rightTot;
			  scanStk := r)
		      | _ => ()
		    (* end case *))
	  (* end case *))

    fun pushScanElem (strm as PP{scanStk, rightTot, ...}, setSz, tok) = (
	  enqueueTok (strm, tok);
	  if setSz then setSize (strm, true) else ();
	  scanStk := (!rightTot, tok) :: !scanStk)

  (* Open a new box *)
    fun ppOpenBox (strm, indent, brType) = let
	  val PP{rightTot, curDepth, ...} = strm
	  in
	    curDepth := !curDepth + 1;
(**** CAML code
	    (* check that !curDepth < maxDepth *)
****)
	    pushScanElem (strm, false, {
		sz = ref(~(!rightTot)),
		tok = BEGIN(indent, brType),
		len = 0
	      })
	  end

  (* the root box, which is always open *)
    fun openSysBox (strm as PP{rightTot, curDepth, ...}) = (
	  curDepth := !curDepth + 1;
	  pushScanElem (strm, false, {
	      sz = ref(~(!rightTot)), tok = BEGIN(Rel 0, HOVBOX), len = 0
	    }))

  (* close a box *)
    fun ppCloseBox (strm as PP{curDepth as ref depth, ...}) =
	  if (depth > 1)
	    then (
(**** CAML code
	    (* check that depth < maxDepth *)
****)
	      enqueueTok (strm, {sz = ref 0, tok = END, len = 0});
	      setSize (strm, true);
	      setSize (strm, false);
	      curDepth := depth-1)
	    else raise Fail "unmatched close box"

    fun ppBreak (strm as PP{rightTot, ...}, arg) = (
	  pushScanElem (strm, true, {
	      sz = ref(~(!rightTot)), tok = BREAK arg, len = #nsp arg
	    }))

    fun ppInit (strm as PP pp) = (
	  #leftTot pp := 1;
	  #rightTot pp := 1;
	  Q.clear(#queue pp);
	  clearScanStk strm;
	  #curIndent pp := 0;
	  #curDepth pp := 0;
	  #spaceLeft pp := #width pp;
	  #fmtStk pp := [];
	  #styleStk pp := [];
	  openSysBox strm)

    fun ppNewline strm =
	  enqueueAndAdvance (strm, {sz = ref 0, tok = NL, len = 0})

    fun ppFlush (strm as PP{dev, curDepth, rightTot, ...}, withNL) = let
	  fun closeBoxes () = if (!curDepth > 1)
		then (ppCloseBox strm; closeBoxes())
		else ()
	  in
	    closeBoxes ();
	    rightTot := infinity;
	    advanceLeft strm;
	    if withNL then outputNL strm else ();
	    D.flush dev;
	    ppInit strm
	  end

  (**** USER FUNCTIONS ****)
    fun openStream d = let
	  val strm = PP{
		  dev = d,
		  closed = ref false,
		  width = Option.getOpt(D.lineWidth d, infinity),
		  spaceLeft = ref 0,
		  curIndent = ref 0,
		  curDepth = ref 0,
		  leftTot = ref 1,	(* why 1 ? *)
		  rightTot = ref 1,	(* why 1 ? *)
		  queue = Q.mkQueue(),
		  fmtStk = ref [],
		  scanStk = ref [],
		  styleStk = ref []
		}
	  in
	    ppInit strm;
	    strm
	  end

    fun flushStream strm = ppFlush(strm, false)
    fun closeStream (strm as PP{closed, ...}) = (flushStream strm; closed := true)
    fun getDevice (PP{dev, ...}) = dev

    fun openHBox strm = ppOpenBox (strm, Abs 0, HBOX)
    fun openVBox strm indent = ppOpenBox (strm, indent, VBOX)
    fun openHVBox strm indent = ppOpenBox (strm, indent, HVBOX)
    fun openHOVBox strm indent = ppOpenBox (strm, indent, HOVBOX)
    fun openBox strm indent = ppOpenBox (strm, indent, BOX)
    fun closeBox strm = ppCloseBox strm

    fun token (strm as PP{dev, ...}) t = let
	  val tokStyle = T.style t
	  in
	    if (D.sameStyle(currentStyle strm, tokStyle))
	      then enqueueStringWithLen (strm, T.string t, T.size t)
	      else (
		enqueueToken (strm, PUSH_STYLE tokStyle);
		enqueueStringWithLen (strm, T.string t, T.size t);
		enqueueToken (strm, POP_STYLE))
	  end
    fun string strm s = enqueueStringWithLen(strm, s, size s)

    fun pushStyle (strm as PP{styleStk, ...}, sty) = (
	  if (D.sameStyle(currentStyle strm, sty))
	    then ()
	    else enqueueToken (strm, PUSH_STYLE sty);
	  styleStk := sty :: !styleStk)
    fun popStyle (strm as PP{styleStk, ...}) = (case !styleStk
	   of [] => raise Fail "PP: unmatched popStyle"
	    | (sty::r) => (
		styleStk := r;
		if (D.sameStyle(currentStyle strm, sty))
		  then ()
		  else enqueueToken (strm, POP_STYLE))
	  (* end case *))

    fun break strm arg = ppBreak (strm, arg)
    fun space strm n = break strm {nsp=n, offset=0}
    fun cut strm = break strm {nsp=0, offset=0}
    fun newline strm = ppNewline strm
    fun nbSpace strm n = enqueueTokenWithLen (strm, NBSP n, n)

    fun control strm ctlFn = enqueueToken (strm, CTL ctlFn)

  end

