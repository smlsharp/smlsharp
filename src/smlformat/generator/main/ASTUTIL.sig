(**
 * Utilities manipulating abstract syntax tree.
 * 
 * @author Copyright 1992 by AT&T Bell Laboratories
 * @author YAMATODANI Kiyoshi
 * @version $Id: ASTUTIL.sig,v 1.2 2004/10/20 02:50:56 kiyoshiy Exp $
 *)
signature ASTUTIL =
  sig

    (* BUILDS VARIOUS CONSTRUCTIONS *)
    val makeSEQdec : Ast.dec * Ast.dec -> Ast.dec

    val layered : Ast.pat * Ast.pat -> Ast.pat

    (* SYMBOLS *)
    val arrowTycon : string
    val bogusID : string
    val exnID : string
    val symArg : string
    val itsym : string list

    val unitExp : Ast.exp
    val unitPat : Ast.pat

    (* QUOTES *)
    val QuoteExp : string -> Ast.exp
    val AntiquoteExp : Ast.exp -> Ast.exp

end  (* signature ASTUTIL *)


