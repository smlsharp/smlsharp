(**
 * @author UENO Katsuhiro
 * @version $Id: ATMARK_TEMPLATE.sig,v 1.1 2005/05/27 03:30:31 kiyoshiy Exp $
 *)
signature ATMARK_TEMPLATE =
sig

  (**
   * replace markers in input.
   * <p>
   * Example.
   * <pre>
   * hoge@fuga@piyo  -> "hoge" ^ (replacement of "fuga") ^ "piyo"
   * hoge@fuga       -> "hoge@fuga" (syntax error but just through)
   * hoge@@fuga      -> "hoge@fuga" (atmark escape)
   * </pre>
   * </p>
   *
   * @params replacer (input, output)
   * @param replacer a function which replace marker with other string.
   * @param input input stream
   * @param output output stream
   * @return unit
   *)
  val format :
      (substring -> string option)
      -> TextIO.instream * TextIO.outstream
      -> unit

end
