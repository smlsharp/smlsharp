signature Mlyacc_TOKENS =
sig
type pos
type token
type svalue
val BOGUS_VALUE:  pos * pos -> token
val UNKNOWN: (string) *  pos * pos -> token
val VALUE:  pos * pos -> token
val VERBOSE:  pos * pos -> token
val TYVAR: (string) *  pos * pos -> token
val TERM:  pos * pos -> token
val START:  pos * pos -> token
val SUBST:  pos * pos -> token
val RPAREN:  pos * pos -> token
val RBRACE:  pos * pos -> token
val PROG: (string) *  pos * pos -> token
val PREFER:  pos * pos -> token
val PREC_TAG:  pos * pos -> token
val PREC: (Header.prec) *  pos * pos -> token
val PERCENT_TOKEN_SIG_INFO:  pos * pos -> token
val PERCENT_ARG:  pos * pos -> token
val PERCENT_POS:  pos * pos -> token
val PERCENT_PURE:  pos * pos -> token
val PERCENT_EOP:  pos * pos -> token
val OF:  pos * pos -> token
val NOSHIFT:  pos * pos -> token
val NONTERM:  pos * pos -> token
val NODEFAULT:  pos * pos -> token
val NAME:  pos * pos -> token
val LPAREN:  pos * pos -> token
val LBRACE:  pos * pos -> token
val KEYWORD:  pos * pos -> token
val INT: (string) *  pos * pos -> token
val PERCENT_BLOCKSIZE:  pos * pos -> token
val PERCENT_DECOMPOSE:  pos * pos -> token
val PERCENT_FOOTER:  pos * pos -> token
val PERCENT_HEADER:  pos * pos -> token
val IDDOT: (string) *  pos * pos -> token
val ID: (string*int) *  pos * pos -> token
val HEADER: (string) *  pos * pos -> token
val FOR:  pos * pos -> token
val EOF:  pos * pos -> token
val DELIMITER:  pos * pos -> token
val COMMA:  pos * pos -> token
val COLON:  pos * pos -> token
val CHANGE:  pos * pos -> token
val BAR:  pos * pos -> token
val BLOCK:  pos * pos -> token
val ASTERISK:  pos * pos -> token
val ARROW:  pos * pos -> token
end
signature Mlyacc_LRVALS=
sig
structure Tokens : Mlyacc_TOKENS
structure Parser : PARSER
sharing type Parser.token = Tokens.token
end
