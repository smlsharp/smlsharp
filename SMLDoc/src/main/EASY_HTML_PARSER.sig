(**
 *  This module provides functions parsing HTML documents.
 *  The supposed usage of them are parse of files which users of SMLDoc
 * specifies in the command line options, such as --overview, --helpfile.
 *  Full spec parser like those in the HTML library of SMLNJ is not
 * required to parse Overview file or Help file the user specifies.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: EASY_HTML_PARSER.sig,v 1.2 2004/10/20 03:18:39 kiyoshiy Exp $
 *)
signature EASY_HTML_PARSER =
sig

  (***************************************************************************)

  (**
   * retrieves the content of BODY tag.
   * @params warn HTML
   * @param warn a function which should be called to display warning message.
   * @param HTML the text in HTML format to be parsed.
   * @return the content of BODY tag in the <code>HTML</code>
   *)
  val getBodyOfHTML : (string -> unit) -> string -> string

  (***************************************************************************)

end