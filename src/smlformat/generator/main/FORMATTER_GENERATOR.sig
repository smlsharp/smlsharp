(**
 * Specfication of modules which generate formatters for type declarations.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FORMATTER_GENERATOR.sig,v 1.5 2004/10/20 02:50:56 kiyoshiy Exp $
 *)
signature FORMATTER_GENERATOR =
sig

  (***************************************************************************)

  (** formatter environment. *)
  type formatterEnv

  (***************************************************************************)

  (** an exception raised in formatter genration
   * @params (cause, region)
   * @param cause the cause of this error
   * @param region the location where this error is found
   *)
  exception GenerationError of string * (int * int)

  (***************************************************************************)

  (** empty formatter environment which fails on any search. *)
  val initialFormatterEnv : formatterEnv

  (**
   *  adds an entry to the formatter environment.
   * <p>
   *  This function registers a name of the formatter by which values of the
   * type built by the type constructor 'tyConName' should be formatted in
   * the namespace indicated by the 'prefixOpt'.
   * </p><p>
   *  If the 'prefixOpt' is <code>NONE</code>, the formatter can be called
   * from any namespace. Otherwise, that is, if the 'prefixOpt' is
   * <code>SOME p</code>, the formatter is registered locally in the namespace
   * indicated by the <code>p</code>.
   * </p>
   * @params F (prefixOpt, tyConName, formatterName)
   * @param F formatter environment
   * @param prefixOpt NONE if the formatter to be added does not belong
   *                 to any namespace.
   * @param tyConName the name of type constructor
   * @param formatterName the name of formatter
   * @return a formatter environment extended with the new entry.
   *)
  val addToFormatterEnv :
      formatterEnv -> string option * string * string -> formatterEnv

  (**
   * generates SML code of the formatter for a datatype declaration.
   *
   * @params formatterEnv (regionOpt, dec)
   * @param formatterEnv the formatter environment
   * @param regionOpt the region of the declaration
   * @param dec the datatype declaration
   * @return a pair of
   * <ul>
   *   <li>a list of pairs of<ul>
   *     <li>destination of generated code</li>
   *     <li>SML code text of the formatters for the type</li>
   *     </ul></li>
   *   <li>the new formatter environment extended with the generated
   *     formatters.</li>
   * </ul>
   *)
  val generateForDataTypeDec :
      formatterEnv ->
      (Ast.region option * Ast.dec) ->
      ((string option * string) list * formatterEnv)

  (**
   * generates SML code of the formatter for a type declaration.
   *
   * @params formatterEnv (regionOpt, dec)
   * @param formatterEnv the formatter environment
   * @param regionOpt the region of the declaration
   * @param dec the type declaration
   * @return a pair of
   * <ul>
   *   <li>a list of pairs of<ul>
   *     <li>destination of generated code</li>
   *     <li>SML code text of the formatters for the type</li>
   *     </ul></li>
   *   <li>the new formatter environment extended with the generated
   *     formatters.</li>
   * </ul>
   *)
  val generateForTypeDec :
      formatterEnv ->
      (Ast.region option * Ast.dec) ->
      ((string option * string) list * formatterEnv)

  (**
   * generates SML code of the formatter for a exception declaration.
   *
   * @params formatterEnv (regionOpt, dec)
   * @param formatterEnv the formatter environment
   * @param regionOpt the region of the declaration
   * @param dec the type declaration
   * @return a pair of
   * <ul>
   *   <li>a list of pairs of<ul>
   *     <li>destination of generated code</li>
   *     <li>SML code text of the formatters for the exception</li>
   *     </ul></li>
   *   <li>the new formatter environment extended with the generated
   *     formatters.</li>
   * </ul>
   *)
  val generateForExceptionDec :
      formatterEnv ->
      (Ast.region option * Ast.dec) ->
      ((string option * string) list * formatterEnv)

  (***************************************************************************)

end
