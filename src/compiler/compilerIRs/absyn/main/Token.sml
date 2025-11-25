(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @author Katsuhiro Ueno
 *)
structure Token =
struct

  datatype token =
      EOF
    | COMMENT
      (* core keywords *)
    | ABSTYPE
    | AND
    | ANDALSO
    | AS
    | CASE
    | DATATYPE
    | DO
    | ELSE
    | END
    | EXCEPTION
    | FN
    | FUN
    | HANDLE
    | IF
    | IN
    | INFIX
    | INFIXR
    | LET
    | LOCAL
    | NONFIX
    | OF
    | OP
    | OPEN
    | ORELSE
    | RAISE
    | REC
    | THEN
    | TYPE
    | VAL
    | WITH
    | WITHTYPE
    | WHILE
    | LPAREN
    | RPAREN
    | LBRACKET
    | RBRACKET
    | LBRACE
    | RBRACE
    | COMMA
    | COLON
    | SEMICOLON
    | PERIODS
    | UNDERBAR
    | UNDERBAR_
    | BAR
    | EQ
    | DARROW
    | ARROW
    | HASH
      (* module keywords *)
    | EQTYPE
    | FUNCTOR
    | INCLUDE
    | SHARING
    | SIG
    | SIGNATURE
    | STRUCT
    | STRUCTURE
    | WHERE
    | OPAQUE
      (* special symbols *)
    | ASTERISK
    | PERIOD
      (* identifiers *)
    | ALNUMID of string
    | EQTYVAR of string
    | SYMBOLID of string
    | TYVAR of string
      (* scon *)
    | CHAR of string
    | HASH_STRING of string
    | INT of string
    | INTX of string
    | INTLAB of string
    | REAL of string
    | STRING of string
    | WORD of string
    | WORDX of string

end
