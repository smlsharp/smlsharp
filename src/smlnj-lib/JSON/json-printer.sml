(* json-printer.sml
 *
 * COPYRIGHT (c) 2008 The Fellowship of SML/NJ (http://www.smlnj.org)
 * All rights reserved.
 *
 * A printer for JSON values.
 *)

structure JSONPrinter : sig

    val print : TextIO.outstream * JSON.value -> unit
    val print' : {strm : TextIO.outstream, pretty : bool} -> JSON.value -> unit

  end = struct

    structure J = JSON
    structure JSP = JSONStreamPrinter

    fun printWith printer = let
	  fun pr (J.OBJECT fields) = let
		fun prField (key, v) = (JSP.objectKey(printer, key); pr v)
		in
		  JSP.beginObject printer;
		  List.app prField fields;
		  JSP.endObject printer
		end
	    | pr (J.ARRAY vs) = (
		JSP.beginArray printer;
		List.app pr vs;
		JSP.endArray printer)
	    | pr J.NULL = JSP.null printer
	    | pr (J.BOOL b) = JSP.boolean (printer, b)
	    | pr (J.INT n) = JSP.integer (printer, n)
	    | pr (J.FLOAT f) = JSP.float (printer, f)
	    | pr (J.STRING s) = JSP.string (printer, s)
	  in
	    fn v => (pr v; JSP.close printer)
	  end

    fun print (strm, v) = printWith (JSP.new strm) v

    fun print' {strm, pretty} = printWith (JSP.new' {strm=strm, pretty=pretty})

  end
