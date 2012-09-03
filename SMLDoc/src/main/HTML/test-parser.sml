(* test-parser.sml
 *
 * COPYRIGHT (c) 1996 AT&T REsearch.
 *
 * This is a simple test driver for the HTML parser.
 *)

structure Test :
          sig
            val doit : string -> HTML.html option
            val main : (string * string list) -> OS.Process.status
          end =
struct

  structure Err : HTML_ERROR =
  struct
    type context = {file : string option, line : int}

    fun prf ({file, line}, message) =
        (case file of
           NONE =>
           TextIO.output(TextIO.stdErr, "line " ^ (Int.toString line) ^ ": ")
         | (SOME fname) =>
           TextIO.output
           (TextIO.stdErr, fname ^ "[" ^ (Int.toString line) ^ "]: ");
         TextIO.output(TextIO.stdErr, message);
	 TextIO.output1(TextIO.stdErr, #"\n"))

    fun badStartTag ctx tagName =
        prf (ctx, "unrecognized start tag \"" ^ tagName ^ "\"")

    fun badEndTag ctx tagName =
        prf (ctx, "unrecognized end tag \"" ^ tagName ^ "\"")

    fun badAttrVal ctx (attrName, attrVal) =
        prf
        (
          ctx,
          "bad value \"" ^ attrVal ^ "\" for attribute \"" ^ attrName ^ "\""
        )

    fun lexError ctx msg = prf (ctx, msg)

    fun syntaxError ctx msg = prf (ctx, msg)

    fun missingAttrVal ctx attrName =
        prf (ctx, "missing value for \"" ^ attrName ^ "\" attribute")

    fun missingAttr ctx attrName =
        prf (ctx, "missing \"" ^ attrName ^ "\" attribute")

    fun unknownAttr ctx attrName =
        prf (ctx, "unknown attribute \"" ^ attrName ^ "\"")

    fun unquotedAttrVal ctx attrName =
        prf (ctx, "attribute value for \"" ^ attrName ^ "\" should be quoted")
  end

  structure P = HTMLParserFn(Err);

  fun doit fname = SOME(P.parseFile fname) (* handle _ => NONE *)

  fun main (_, files) = (List.app (ignore o doit) files; OS.Process.success)

end;
