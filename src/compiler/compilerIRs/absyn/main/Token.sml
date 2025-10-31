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
    | INVALID of string
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
      (* SML# extensions *)
    | U_ATTRIBUTE
    | U_BUILTIN
    | U_FOREACH
    | U_IMPORT
    | U_INTERFACE
    | U_JOIN
    | U_EXTEND
    | U_UPDATE
    | U_DYNAMIC
    | U_DYNAMICCASE
    | U_DYNAMICNULL
    | U_DYNAMICVIEW
    | U_DYNAMICVOID
    | U_POLYREC
    | U_REIFYTY
    | U_REQUIRE
    | U_SIZEOF
    | U_SQL
    | U_SQLEVAL
    | U_SQLEXEC
    | U_SQLSERVER
    | U_USE
      (* identifiers *)
    | ALNUMID of string
    | EQTYVAR of string
    | FREE_TYVAR of string
    | FREE_EQTYVAR of string
    | PREFIXEDLABEL of string
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

  fun tokenName token =
      case token of
      EOF => "EOF"
    | COMMENT => "COMMENT"
    | INVALID _ => "INVALID"
    | ABSTYPE => "ABSTYPE"
    | AND => "AND"
    | ANDALSO => "ANDALSO"
    | AS => "AS"
    | CASE => "CASE"
    | DATATYPE => "DATATYPE"
    | DO => "DO"
    | ELSE => "ELSE"
    | END => "END"
    | EXCEPTION => "EXCEPTION"
    | FN => "FN"
    | FUN => "FUN"
    | HANDLE => "HANDLE"
    | IF => "IF"
    | IN => "IN"
    | INFIX => "INFIX"
    | INFIXR => "INFIXR"
    | LET => "LET"
    | LOCAL => "LOCAL"
    | NONFIX => "NONFIX"
    | OF => "OF"
    | OP => "OP"
    | OPEN => "OPEN"
    | ORELSE => "ORELSE"
    | RAISE => "RAISE"
    | REC => "REC"
    | THEN => "THEN"
    | TYPE => "TYPE"
    | VAL => "VAL"
    | WITH => "WITH"
    | WITHTYPE => "WITHTYPE"
    | WHILE => "WHILE"
    | LPAREN => "LPAREN"
    | RPAREN => "RPAREN"
    | LBRACKET => "LBRACKET"
    | RBRACKET => "RBRACKET"
    | LBRACE => "LBRACE"
    | RBRACE => "RBRACE"
    | COMMA => "COMMA"
    | COLON => "COLON"
    | SEMICOLON => "SEMICOLON"
    | PERIODS => "PERIODS"
    | UNDERBAR => "UNDERBAR"
    | BAR => "BAR"
    | EQ => "EQ"
    | DARROW => "DARROW"
    | ARROW => "ARROW"
    | HASH => "HASH"
    | EQTYPE => "EQTYPE"
    | FUNCTOR => "FUNCTOR"
    | INCLUDE => "INCLUDE"
    | SHARING => "SHARING"
    | SIG => "SIG"
    | SIGNATURE => "SIGNATURE"
    | STRUCT => "STRUCT"
    | STRUCTURE => "STRUCTURE"
    | WHERE => "WHERE"
    | OPAQUE => "OPAQUE"
    | ASTERISK => "ASTERISK"
    | PERIOD => "PERIOD"
    | U_ATTRIBUTE => "U_ATTRIBUTE"
    | U_BUILTIN => "U_BUILTIN"
    | U_FOREACH => "U_FOREACH"
    | U_IMPORT => "U_IMPORT"
    | U_INTERFACE => "U_INTERFACE"
    | U_JOIN => "U_JOIN"
    | U_EXTEND => "U_EXTEND"
    | U_UPDATE => "U_UPDATE"
    | U_DYNAMIC => "U_DYNAMIC"
    | U_DYNAMICCASE => "U_DYNAMICCASE"
    | U_DYNAMICNULL => "U_DYNAMICNULL"
    | U_DYNAMICVIEW => "U_DYNAMICVIEW"
    | U_DYNAMICVOID => "U_DYNAMICVOID"
    | U_POLYREC => "U_POLYREC"
    | U_REIFYTY => "U_REIFYTY"
    | U_REQUIRE => "U_REQUIRE"
    | U_SIZEOF => "U_SIZEOF"
    | U_SQL => "U_SQL"
    | U_SQLEVAL => "U_SQLEVAL"
    | U_SQLEXEC => "U_SQLEXEC"
    | U_SQLSERVER => "U_SQLSERVER"
    | U_USE => "U_USE"
    | ALNUMID _ => "ALNUMID"
    | EQTYVAR _ => "EQTYVAR"
    | FREE_TYVAR _ => "FREE_TYVAR"
    | FREE_EQTYVAR _ => "FREE_EQTYVAR"
    | PREFIXEDLABEL _ => "PREFIXEDLABEL"
    | SYMBOLID _ => "SYMBOLID"
    | TYVAR _ => "TYVAR"
    | CHAR _ => "CHAR"
    | HASH_STRING _ => "HASH_STRING"
    | INT _ => "INT"
    | INTX _ => "INTX"
    | INTLAB _ => "INTLAB"
    | REAL _ => "REAL"
    | STRING _ => "STRING"
    | WORD _ => "WORD"
    | WORDX _ => "WORDX"

end
