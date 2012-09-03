(**
 * parser of CSV format.
 *
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @version $Id: CSVPARSER.sig,v 1.6 2005/12/10 08:27:08 kiyoshiy Exp $
 *)
signature CSVPARSER =
sig

  (***************************************************************************)

  (**
   * indicates whether a field value is quoted string or not.
   * <p>
   * A quoted field can have sequence white spaces in its header or trailer.
   * A unquoted field does not include heading or trailing white spaces.
   * For example, the following line in a CSV format
   * <pre>
   *   a, b , " x y z " , c d
   * </pre>
   * contains 5 fields.
   * <pre>
   * [("a", UNQUOTED),("b", UNQUOTED),(" x y z ",QUOTED),("c d",UNQUOTED)]
   * </pre>
   * <p>
   *)
  datatype fieldQuote =
           (** non quoted string. *)
           UNQUOTED
         | (** a string quoted. *)
           QUOTED

  (**
   * fields in a CSV table.
   * <p>
   * <ul>
   *   <li>Fields are separated by either commas or linebreaks.</li>
   *   <li>Commas and linebreaks within a quoted literal are regarded
   *   as parts of a field, not field separators.</li>
   *   <li>If stripField is true, preceding and following whitespaces
   *   are trimmed.</li>
   *   <li>Meta characters such as quotation marks or backslashs in quoted
   *   literals are not appeared within the result of the parsing.</li>
   *   <li>If a field is empty, the field is NONE.</li>
   * </ul>
   * </p>
   *)
  (*
   * NOTE: A field in a CSV table is string option, not substring option,
   *       in order to be able to handle escaped characters.
   *       (???)
   *)
  type field = (string * fieldQuote) option

  (**
   * each rows consists of one more fields.
   * <p>
   * <ul>
   *   <li>Rows in a CSV table are separated by linebreaks (CRLF, CR, or LF).
   *       </li>
   *   <li>A empty line in the input is regarded as a row including one
   *       empty field.</li>
   * </ul>
   * </p>
   *)
  type row = field list

  (**
   * a table consists of one more rows.
   * <p>
   * Empty input is regarded as a table including one row including one
   * empty field.
   * </p>
   *)
  type table = row list

  (**
   * parse a CSV table from a stream.
   *)
  type 'stream parser = 'stream -> table

  (***************************************************************************)

  (**
   * create a parser.
   *
   * @params {delimiter, quote, escape, stripField, reader}
   * @param delimiter separator between two fields.
   * @param quote mark the start or end of quoted literal.
   * @param escape mark for escaped character.
   * @param stripField do or do not trim whitespaces surrounding a field.
   * @param reader a reader function 
   * @return a CSV parser
   *)
  val createParser :
      {
        delimiter: char,
	quote: char,
	escape: char,
	stripField: bool,
        reader : (char, 'stream) StringCvt.reader
      } -> 'stream parser

  (**
   * create a default parser.
   * <p>
   * <code>parse reader</code> is equivalent to:
   * <pre>
   * createParser
   *   {
   *     delimiter = #",",
   *     quote = #"\"",
   *     escape = #"\\",
   *     stripField = true,
   *     reader = reader
   *   }
   * </pre>
   * </p>
   *)
  val parse : (char, 'stream) StringCvt.reader -> 'stream parser

  (**
   * create a default parser of a string.
   * <p>
   * <code>parseString</code> is equivalent to:
   * <pre>
   * fn string => parse Substring.getc (Substring.all)
   * </pre>
   * </p>
   *)
  val parseString : string parser

  (***************************************************************************)

end