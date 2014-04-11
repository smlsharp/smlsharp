signature Mlyacc_TOKENS =
sig
type pos
type token
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
structure LrVals
 = 
struct
structure ParserData=
struct
structure Header = 
struct
(* ML-Yacc Parser Generator (c) 1989 Andrew W. Appel, David R. Tarditi *)

(* parser for the ML parser generator *)
(*
  2012-1-13 ohori
  %footer added for defuncteringing ml.grm.sml
*)
open Header

end
local open Header in
type pos = int
type arg = Header.inputSource
type lexarg = Header.inputSource
structure MlyValue = 
struct
datatype svalue = VOID | ntVOID of unit ->  unit
 | UNKNOWN of unit ->  (string) | TYVAR of unit ->  (string)
 | PROG of unit ->  (string) | PREC of unit ->  (Header.prec)
 | INT of unit ->  (string) | IDDOT of unit ->  (string)
 | ID of unit ->  (string*int) | HEADER of unit ->  (string)
 | TY of unit ->  (string)
 | CHANGE_DEC of unit ->  ( ( Header.symbol list * Header.symbol list ) )
 | CHANGE_DECL of unit ->  ( ( Header.symbol list * Header.symbol list )  list)
 | SUBST_DEC of unit ->  ( ( Header.symbol list * Header.symbol list ) )
 | SUBST_DECL of unit ->  ( ( Header.symbol list * Header.symbol list )  list)
 | G_RULE_PREC of unit ->  (Header.symbol option)
 | G_RULE_LIST of unit ->  (Header.rule list)
 | G_RULE of unit ->  (Header.rule list)
 | RHS_LIST of unit ->  ({ rhs:Header.symbol list,code:string,prec:Header.symbol option }  list)
 | RECORD_LIST of unit ->  (string) | QUAL_ID of unit ->  (string)
 | MPC_DECLS of unit ->  (Header.declData)
 | MPC_DECL of unit ->  (Header.declData) | LABEL of unit ->  (string)
 | ID_LIST of unit ->  (Header.symbol list)
 | CONSTR_LIST of unit ->  ( ( Header.symbol * Header.ty option )  list)
 | BEGIN of unit ->  (string*Header.declData* ( Header.rule list ) )
end
type svalue = MlyValue.svalue
type result = string*Header.declData* ( Header.rule list ) 
end
structure ParserArg = struct type pos = pos type svalue = svalue type arg = arg end
structure LrParser = LrParserFun(ParserArg)
structure Token = LrParser.Token
structure LrTable = LrParser.LrTable
local open LrTable in 
val table=let val actionRows =
"\
\\001\000\001\000\082\000\000\000\
\\001\000\005\000\028\000\008\000\027\000\014\000\026\000\015\000\025\000\
\\016\000\024\000\017\000\023\000\019\000\022\000\022\000\021\000\
\\023\000\020\000\024\000\019\000\025\000\018\000\027\000\017\000\
\\028\000\016\000\029\000\015\000\030\000\014\000\031\000\013\000\
\\032\000\012\000\034\000\011\000\038\000\010\000\039\000\009\000\
\\040\000\008\000\042\000\007\000\043\000\006\000\000\000\
\\001\000\006\000\069\000\000\000\
\\001\000\006\000\080\000\000\000\
\\001\000\006\000\092\000\000\000\
\\001\000\006\000\104\000\000\000\
\\001\000\007\000\091\000\036\000\090\000\000\000\
\\001\000\009\000\000\000\000\000\
\\001\000\010\000\067\000\000\000\
\\001\000\011\000\003\000\000\000\
\\001\000\012\000\029\000\000\000\
\\001\000\012\000\031\000\000\000\
\\001\000\012\000\032\000\000\000\
\\001\000\012\000\035\000\000\000\
\\001\000\012\000\047\000\013\000\046\000\000\000\
\\001\000\012\000\047\000\013\000\046\000\020\000\045\000\035\000\044\000\
\\041\000\043\000\000\000\
\\001\000\012\000\051\000\000\000\
\\001\000\012\000\059\000\000\000\
\\001\000\012\000\077\000\018\000\076\000\000\000\
\\001\000\012\000\077\000\018\000\076\000\036\000\075\000\000\000\
\\001\000\012\000\083\000\000\000\
\\001\000\012\000\086\000\000\000\
\\001\000\012\000\107\000\000\000\
\\001\000\035\000\039\000\000\000\
\\001\000\035\000\040\000\000\000\
\\001\000\035\000\053\000\000\000\
\\001\000\035\000\054\000\000\000\
\\001\000\035\000\055\000\000\000\
\\001\000\035\000\056\000\000\000\
\\001\000\035\000\063\000\000\000\
\\001\000\035\000\106\000\000\000\
\\001\000\035\000\110\000\000\000\
\\112\000\012\000\059\000\000\000\
\\113\000\000\000\
\\114\000\000\000\
\\115\000\004\000\064\000\000\000\
\\116\000\004\000\064\000\000\000\
\\117\000\000\000\
\\118\000\000\000\
\\119\000\000\000\
\\120\000\000\000\
\\121\000\000\000\
\\122\000\000\000\
\\123\000\000\000\
\\124\000\000\000\
\\125\000\000\000\
\\126\000\000\000\
\\127\000\000\000\
\\128\000\000\000\
\\129\000\000\000\
\\130\000\000\000\
\\131\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\132\000\000\000\
\\133\000\000\000\
\\134\000\000\000\
\\135\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\136\000\000\000\
\\137\000\000\000\
\\138\000\004\000\081\000\000\000\
\\139\000\000\000\
\\140\000\000\000\
\\141\000\004\000\066\000\000\000\
\\142\000\000\000\
\\143\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\144\000\026\000\097\000\000\000\
\\145\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\146\000\026\000\065\000\000\000\
\\147\000\004\000\100\000\000\000\
\\148\000\000\000\
\\149\000\000\000\
\\150\000\000\000\
\\151\000\012\000\037\000\000\000\
\\152\000\000\000\
\\153\000\000\000\
\\154\000\000\000\
\\155\000\000\000\
\\156\000\000\000\
\\157\000\000\000\
\\158\000\000\000\
\\159\000\000\000\
\\160\000\012\000\047\000\013\000\046\000\000\000\
\\161\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\162\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\163\000\001\000\072\000\002\000\071\000\012\000\047\000\013\000\046\000\000\000\
\\164\000\000\000\
\\165\000\000\000\
\\166\000\000\000\
\\167\000\000\000\
\\168\000\000\000\
\\169\000\033\000\102\000\000\000\
\"
val actionRowNumbers =
"\009\000\034\000\001\000\033\000\
\\010\000\052\000\011\000\012\000\
\\013\000\071\000\071\000\023\000\
\\024\000\015\000\054\000\071\000\
\\071\000\011\000\053\000\016\000\
\\071\000\025\000\026\000\027\000\
\\028\000\017\000\071\000\029\000\
\\035\000\066\000\038\000\061\000\
\\043\000\008\000\041\000\071\000\
\\037\000\049\000\002\000\055\000\
\\079\000\074\000\077\000\019\000\
\\014\000\084\000\039\000\044\000\
\\036\000\050\000\040\000\048\000\
\\047\000\046\000\045\000\032\000\
\\069\000\003\000\058\000\042\000\
\\000\000\056\000\020\000\015\000\
\\013\000\021\000\070\000\015\000\
\\078\000\015\000\015\000\006\000\
\\004\000\076\000\087\000\086\000\
\\085\000\068\000\071\000\071\000\
\\071\000\064\000\065\000\060\000\
\\062\000\051\000\080\000\081\000\
\\075\000\018\000\015\000\067\000\
\\089\000\057\000\059\000\015\000\
\\005\000\083\000\071\000\030\000\
\\022\000\063\000\015\000\089\000\
\\072\000\088\000\082\000\031\000\
\\073\000\007\000"
val gotoT =
"\
\\001\000\109\000\000\000\
\\006\000\002\000\000\000\
\\005\000\003\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\002\000\028\000\000\000\
\\000\000\
\\013\000\032\000\014\000\031\000\000\000\
\\003\000\034\000\000\000\
\\003\000\036\000\000\000\
\\000\000\
\\000\000\
\\007\000\040\000\017\000\039\000\000\000\
\\000\000\
\\003\000\046\000\000\000\
\\003\000\047\000\000\000\
\\002\000\048\000\000\000\
\\000\000\
\\000\000\
\\003\000\050\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\010\000\056\000\011\000\055\000\000\000\
\\003\000\060\000\015\000\059\000\016\000\058\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\003\000\066\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\007\000\068\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\004\000\072\000\008\000\071\000\000\000\
\\007\000\076\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\010\000\077\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\007\000\040\000\017\000\082\000\000\000\
\\013\000\083\000\014\000\031\000\000\000\
\\000\000\
\\000\000\
\\007\000\040\000\017\000\085\000\000\000\
\\000\000\
\\007\000\040\000\017\000\086\000\000\000\
\\007\000\040\000\017\000\087\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\003\000\092\000\009\000\091\000\000\000\
\\003\000\060\000\015\000\093\000\016\000\058\000\000\000\
\\003\000\094\000\000\000\
\\000\000\
\\007\000\068\000\000\000\
\\000\000\
\\000\000\
\\007\000\068\000\000\000\
\\007\000\068\000\000\000\
\\007\000\068\000\000\000\
\\000\000\
\\004\000\096\000\000\000\
\\007\000\040\000\017\000\097\000\000\000\
\\000\000\
\\012\000\099\000\000\000\
\\000\000\
\\000\000\
\\007\000\040\000\017\000\101\000\000\000\
\\000\000\
\\007\000\068\000\000\000\
\\003\000\103\000\000\000\
\\000\000\
\\000\000\
\\007\000\068\000\000\000\
\\007\000\040\000\017\000\106\000\000\000\
\\012\000\107\000\000\000\
\\000\000\
\\000\000\
\\007\000\068\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\"
val numstates = 110
val numrules = 58
val s = ref "" and index = ref 0
val string_to_int = fn () => 
let val i = !index
in index := i+2; Char.ord(String.sub(!s,i)) + Char.ord(String.sub(!s,i+1)) * 256
end
val string_to_list = fn s' =>
    let val len = String.size s'
        fun f () =
           if !index < len then string_to_int() :: f()
           else nil
   in index := 0; s := s'; f ()
   end
val string_to_pairlist = fn (conv_key,conv_entry) =>
     let fun f () =
         case string_to_int()
         of 0 => EMPTY
          | n => PAIR(conv_key (n-1),conv_entry (string_to_int()),f())
     in f
     end
val string_to_pairlist_default = fn (conv_key,conv_entry) =>
    let val conv_row = string_to_pairlist(conv_key,conv_entry)
    in fn () =>
       let val default = conv_entry(string_to_int())
           val row = conv_row()
       in (row,default)
       end
   end
val string_to_table = fn (convert_row,s') =>
    let val len = String.size s'
        fun f ()=
           if !index < len then convert_row() :: f()
           else nil
     in (s := s'; index := 0; f ())
     end
local
  val memo = Array.array(numstates+numrules,ERROR)
  val _ =let fun g i=(Array.update(memo,i,REDUCE(i-numstates)); g(i+1))
       fun f i =
            if i=numstates then g i
            else (Array.update(memo,i,SHIFT (STATE i)); f (i+1))
          in f 0 handle Subscript => ()
          end
in
val entry_to_action = fn 0 => ACCEPT | 1 => ERROR | j => Array.sub(memo,(j-2))
end
val gotoT=Array.fromList(string_to_table(string_to_pairlist(NT,STATE),gotoT))
val actionRows=string_to_table(string_to_pairlist_default(T,entry_to_action),actionRows)
val actionRowNumbers = string_to_list actionRowNumbers
val actionT = let val actionRowLookUp=
let val a=Array.fromList(actionRows) in fn i=>Array.sub(a,i) end
in Array.fromList(map actionRowLookUp actionRowNumbers)
end
in LrTable.mkLrTable {actions=actionT,gotos=gotoT,numRules=numrules,
numStates=numstates,initialState=STATE 0}
end
end
structure EC=
struct
open LrTable
infix 5 $$
fun x $$ y = y::x
val is_keyword =
fn _ => false
val preferred_change : (term list * term list) list = 
nil
val noShift = 
fn (T 8) => true | _ => false
val showTerminal =
fn (T 0) => "ARROW"
  | (T 1) => "ASTERISK"
  | (T 2) => "BLOCK"
  | (T 3) => "BAR"
  | (T 4) => "CHANGE"
  | (T 5) => "COLON"
  | (T 6) => "COMMA"
  | (T 7) => "DELIMITER"
  | (T 8) => "EOF"
  | (T 9) => "FOR"
  | (T 10) => "HEADER"
  | (T 11) => "ID"
  | (T 12) => "IDDOT"
  | (T 13) => "PERCENT_HEADER"
  | (T 14) => "PERCENT_FOOTER"
  | (T 15) => "PERCENT_DECOMPOSE"
  | (T 16) => "PERCENT_BLOCKSIZE"
  | (T 17) => "INT"
  | (T 18) => "KEYWORD"
  | (T 19) => "LBRACE"
  | (T 20) => "LPAREN"
  | (T 21) => "NAME"
  | (T 22) => "NODEFAULT"
  | (T 23) => "NONTERM"
  | (T 24) => "NOSHIFT"
  | (T 25) => "OF"
  | (T 26) => "PERCENT_EOP"
  | (T 27) => "PERCENT_PURE"
  | (T 28) => "PERCENT_POS"
  | (T 29) => "PERCENT_ARG"
  | (T 30) => "PERCENT_TOKEN_SIG_INFO"
  | (T 31) => "PREC"
  | (T 32) => "PREC_TAG"
  | (T 33) => "PREFER"
  | (T 34) => "PROG"
  | (T 35) => "RBRACE"
  | (T 36) => "RPAREN"
  | (T 37) => "SUBST"
  | (T 38) => "START"
  | (T 39) => "TERM"
  | (T 40) => "TYVAR"
  | (T 41) => "VERBOSE"
  | (T 42) => "VALUE"
  | (T 43) => "UNKNOWN"
  | (T 44) => "BOGUS_VALUE"
  | _ => "bogus-term"
local open Header in
val errtermvalue=
fn _ => MlyValue.VOID
end
val terms : term list = nil
 $$ (T 44) $$ (T 42) $$ (T 41) $$ (T 39) $$ (T 38) $$ (T 37) $$ (T 36)
 $$ (T 35) $$ (T 33) $$ (T 32) $$ (T 30) $$ (T 29) $$ (T 28) $$ (T 27)
 $$ (T 26) $$ (T 25) $$ (T 24) $$ (T 23) $$ (T 22) $$ (T 21) $$ (T 20)
 $$ (T 19) $$ (T 18) $$ (T 16) $$ (T 15) $$ (T 14) $$ (T 13) $$ (T 9)
 $$ (T 8) $$ (T 7) $$ (T 6) $$ (T 5) $$ (T 4) $$ (T 3) $$ (T 2) $$ (T 
1) $$ (T 0)end
structure Actions =
struct 
exception mlyAction of int
local open Header in
fun actionFun1
     (i392:int,defaultPos:pos,stack:(LrTable.state * (svalue * pos * pos)) list,
     (inputSource):arg) =
  case (i392, stack) of 
 ( 0, ( ( _, ( MlyValue.G_RULE_LIST G_RULE_LIST1, _, G_RULE_LIST1right
)) :: _ :: ( _, ( MlyValue.MPC_DECLS MPC_DECLS1, _, _)) :: ( _, ( 
MlyValue.HEADER HEADER1, HEADER1left, _)) :: rest671)) => let val  
result = MlyValue.BEGIN (fn _ => let val  (HEADER as HEADER1) = 
HEADER1 ()
 val  (MPC_DECLS as MPC_DECLS1) = MPC_DECLS1 ()
 val  (G_RULE_LIST as G_RULE_LIST1) = G_RULE_LIST1 ()
 in (HEADER,MPC_DECLS,rev G_RULE_LIST)
end)
 in ( LrTable.NT 0, ( result, HEADER1left, G_RULE_LIST1right), rest671
)
end
|  ( 1, ( ( _, ( MlyValue.MPC_DECL MPC_DECL1, MPC_DECLleft, 
MPC_DECL1right)) :: ( _, ( MlyValue.MPC_DECLS MPC_DECLS1, 
MPC_DECLS1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECLS (fn _ => let val  (MPC_DECLS as MPC_DECLS1) = 
MPC_DECLS1 ()
 val  (MPC_DECL as MPC_DECL1) = MPC_DECL1 ()
 in (join_decls(MPC_DECLS,MPC_DECL,inputSource,MPC_DECLleft))
end)
 in ( LrTable.NT 5, ( result, MPC_DECLS1left, MPC_DECL1right), rest671
)
end
|  ( 2, ( rest671)) => let val  result = MlyValue.MPC_DECLS (fn _ => (
DECL {prec=nil,nonterm=NONE,term=NONE,eop=nil,control=nil,
		   keyword=nil,change=nil,
		   value=nil}
))
 in ( LrTable.NT 5, ( result, defaultPos, defaultPos), rest671)
end
|  ( 3, ( ( _, ( MlyValue.CONSTR_LIST CONSTR_LIST1, _, 
CONSTR_LIST1right)) :: ( _, ( _, TERM1left, _)) :: rest671)) => let
 val  result = MlyValue.MPC_DECL (fn _ => let val  (CONSTR_LIST as 
CONSTR_LIST1) = CONSTR_LIST1 ()
 in (
DECL { prec=nil,nonterm=NONE,
	       term = SOME CONSTR_LIST, eop =nil,control=nil,
		change=nil,keyword=nil,
		value=nil}
)
end)
 in ( LrTable.NT 4, ( result, TERM1left, CONSTR_LIST1right), rest671)

end
|  ( 4, ( ( _, ( MlyValue.CONSTR_LIST CONSTR_LIST1, _, 
CONSTR_LIST1right)) :: ( _, ( _, NONTERM1left, _)) :: rest671)) => let
 val  result = MlyValue.MPC_DECL (fn _ => let val  (CONSTR_LIST as 
CONSTR_LIST1) = CONSTR_LIST1 ()
 in (
DECL { prec=nil,control=nil,nonterm= SOME CONSTR_LIST,
	       term = NONE, eop=nil,change=nil,keyword=nil,
	       value=nil}
)
end)
 in ( LrTable.NT 4, ( result, NONTERM1left, CONSTR_LIST1right), 
rest671)
end
|  ( 5, ( ( _, ( MlyValue.ID_LIST ID_LIST1, _, ID_LIST1right)) :: ( _,
 ( MlyValue.PREC PREC1, PREC1left, _)) :: rest671)) => let val  result
 = MlyValue.MPC_DECL (fn _ => let val  (PREC as PREC1) = PREC1 ()
 val  (ID_LIST as ID_LIST1) = ID_LIST1 ()
 in (
DECL {prec= [(PREC,ID_LIST)],control=nil,
	      nonterm=NONE,term=NONE,eop=nil,change=nil,
	      keyword=nil,value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PREC1left, ID_LIST1right), rest671)
end
|  ( 6, ( ( _, ( MlyValue.ID ID1, _, ID1right)) :: ( _, ( _, 
START1left, _)) :: rest671)) => let val  result = MlyValue.MPC_DECL
 (fn _ => let val  (ID as ID1) = ID1 ()
 in (
DECL {prec=nil,control=[START_SYM (symbolMake ID)],nonterm=NONE,
	       term = NONE, eop = nil,change=nil,keyword=nil,
	       value=nil}
)
end)
 in ( LrTable.NT 4, ( result, START1left, ID1right), rest671)
end
|  ( 7, ( ( _, ( MlyValue.ID_LIST ID_LIST1, _, ID_LIST1right)) :: ( _,
 ( _, PERCENT_EOP1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (ID_LIST as ID_LIST1) = ID_LIST1
 ()
 in (
DECL {prec=nil,control=nil,nonterm=NONE,term=NONE,
		eop=ID_LIST, change=nil,keyword=nil,
	 	value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_EOP1left, ID_LIST1right), 
rest671)
end
|  ( 8, ( ( _, ( MlyValue.ID_LIST ID_LIST1, _, ID_LIST1right)) :: ( _,
 ( _, KEYWORD1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (ID_LIST as ID_LIST1) = ID_LIST1
 ()
 in (
DECL {prec=nil,control=nil,nonterm=NONE,term=NONE,eop=nil,
		change=nil,keyword=ID_LIST,
	 	value=nil}
)
end)
 in ( LrTable.NT 4, ( result, KEYWORD1left, ID_LIST1right), rest671)

end
|  ( 9, ( ( _, ( MlyValue.ID_LIST ID_LIST1, _, ID_LIST1right)) :: ( _,
 ( _, PREFER1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (ID_LIST as ID_LIST1) = ID_LIST1
 ()
 in (
DECL {prec=nil,control=nil,nonterm=NONE,term=NONE,eop=nil,
		    change=map (fn i=>([],[i])) ID_LIST,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PREFER1left, ID_LIST1right), rest671)

end
|  ( 10, ( ( _, ( MlyValue.CHANGE_DECL CHANGE_DECL1, _, 
CHANGE_DECL1right)) :: ( _, ( _, CHANGE1left, _)) :: rest671)) => let
 val  result = MlyValue.MPC_DECL (fn _ => let val  (CHANGE_DECL as 
CHANGE_DECL1) = CHANGE_DECL1 ()
 in (
DECL {prec=nil,control=nil,nonterm=NONE,term=NONE,eop=nil,
		change=CHANGE_DECL,keyword=nil,
		value=nil}
)
end)
 in ( LrTable.NT 4, ( result, CHANGE1left, CHANGE_DECL1right), rest671
)
end
|  ( 11, ( ( _, ( MlyValue.SUBST_DECL SUBST_DECL1, _, SUBST_DECL1right
)) :: ( _, ( _, SUBST1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (SUBST_DECL as SUBST_DECL1) = 
SUBST_DECL1 ()
 in (
DECL {prec=nil,control=nil,nonterm=NONE,term=NONE,eop=nil,
		change=SUBST_DECL,keyword=nil,
		value=nil}
)
end)
 in ( LrTable.NT 4, ( result, SUBST1left, SUBST_DECL1right), rest671)

end
|  ( 12, ( ( _, ( MlyValue.ID_LIST ID_LIST1, _, ID_LIST1right)) :: ( _
, ( _, NOSHIFT1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (ID_LIST as ID_LIST1) = ID_LIST1
 ()
 in (
DECL {prec=nil,control=[NSHIFT ID_LIST],nonterm=NONE,term=NONE,
	            eop=nil,change=nil,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, NOSHIFT1left, ID_LIST1right), rest671)

end
|  ( 13, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( _, 
PERCENT_HEADER1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (PROG as PROG1) = PROG1 ()
 in (
DECL {prec=nil,control=[FUNCTOR PROG],nonterm=NONE,term=NONE,
	            eop=nil,change=nil,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_HEADER1left, PROG1right), 
rest671)
end
|  ( 14, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( _, 
PERCENT_FOOTER1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (PROG as PROG1) = PROG1 ()
 in (
DECL {prec=nil,control=[FOOTER PROG],nonterm=NONE,term=NONE,
	            eop=nil,change=nil,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_FOOTER1left, PROG1right), 
rest671)
end
|  ( 15, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( _, 
PERCENT_DECOMPOSE1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (PROG as PROG1) = PROG1 ()
 in (
DECL {prec=nil,control=[DECOMPOSE PROG],nonterm=NONE,term=NONE,
	            eop=nil,change=nil,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_DECOMPOSE1left, PROG1right), 
rest671)
end
|  ( 16, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( _, 
PERCENT_BLOCKSIZE1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (PROG as PROG1) = PROG1 ()
 in (
DECL {prec=nil,control=[BLOCKSIZE PROG],nonterm=NONE,term=NONE,
	            eop=nil,change=nil,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_BLOCKSIZE1left, PROG1right), 
rest671)
end
|  ( 17, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( _, 
PERCENT_TOKEN_SIG_INFO1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (PROG as PROG1) = PROG1 ()
 in (
DECL {prec=nil,control=[TOKEN_SIG_INFO PROG],
                    nonterm=NONE,term=NONE,
	            eop=nil,change=nil,keyword=nil,
		    value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_TOKEN_SIG_INFO1left, PROG1right)
, rest671)
end
|  ( 18, ( ( _, ( MlyValue.ID ID1, _, ID1right)) :: ( _, ( _, 
NAME1left, _)) :: rest671)) => let val  result = MlyValue.MPC_DECL (fn
 _ => let val  (ID as ID1) = ID1 ()
 in (
DECL {prec=nil,control=[PARSER_NAME (symbolMake ID)],
	            nonterm=NONE,term=NONE,
		    eop=nil,change=nil,keyword=nil, value=nil}
)
end)
 in ( LrTable.NT 4, ( result, NAME1left, ID1right), rest671)
end
|  ( 19, ( ( _, ( MlyValue.TY TY1, _, TY1right)) :: _ :: ( _, ( 
MlyValue.PROG PROG1, _, _)) :: ( _, ( _, PERCENT_ARG1left, _)) :: 
rest671)) => let val  result = MlyValue.MPC_DECL (fn _ => let val  (
PROG as PROG1) = PROG1 ()
 val  (TY as TY1) = TY1 ()
 in (
DECL {prec=nil,control=[PARSE_ARG(PROG,TY)],nonterm=NONE,
	            term=NONE,eop=nil,change=nil,keyword=nil,
		     value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_ARG1left, TY1right), rest671)

end
|  ( 20, ( ( _, ( _, VERBOSE1left, VERBOSE1right)) :: rest671)) => let
 val  result = MlyValue.MPC_DECL (fn _ => (
DECL {prec=nil,control=[Header.VERBOSE],
	        nonterm=NONE,term=NONE,eop=nil,
	        change=nil,keyword=nil,
		value=nil}
))
 in ( LrTable.NT 4, ( result, VERBOSE1left, VERBOSE1right), rest671)

end
|  ( 21, ( ( _, ( _, NODEFAULT1left, NODEFAULT1right)) :: rest671)) =>
 let val  result = MlyValue.MPC_DECL (fn _ => (
DECL {prec=nil,control=[Header.NODEFAULT],
	        nonterm=NONE,term=NONE,eop=nil,
	        change=nil,keyword=nil,
		value=nil}
))
 in ( LrTable.NT 4, ( result, NODEFAULT1left, NODEFAULT1right), 
rest671)
end
|  ( 22, ( ( _, ( _, PERCENT_PURE1left, PERCENT_PURE1right)) :: 
rest671)) => let val  result = MlyValue.MPC_DECL (fn _ => (
DECL {prec=nil,control=[Header.PURE],
	        nonterm=NONE,term=NONE,eop=nil,
	        change=nil,keyword=nil,
		value=nil}
))
 in ( LrTable.NT 4, ( result, PERCENT_PURE1left, PERCENT_PURE1right), 
rest671)
end
|  ( 23, ( ( _, ( MlyValue.TY TY1, _, TY1right)) :: ( _, ( _, 
PERCENT_POS1left, _)) :: rest671)) => let val  result = 
MlyValue.MPC_DECL (fn _ => let val  (TY as TY1) = TY1 ()
 in (
DECL {prec=nil,control=[Header.POS TY],
	        nonterm=NONE,term=NONE,eop=nil,
	        change=nil,keyword=nil,
		value=nil}
)
end)
 in ( LrTable.NT 4, ( result, PERCENT_POS1left, TY1right), rest671)

end
|  ( 24, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( 
MlyValue.ID ID1, _, _)) :: ( _, ( _, VALUE1left, _)) :: rest671)) =>
 let val  result = MlyValue.MPC_DECL (fn _ => let val  (ID as ID1) = 
ID1 ()
 val  (PROG as PROG1) = PROG1 ()
 in (
DECL {prec=nil,control=nil,
	        nonterm=NONE,term=NONE,eop=nil,
	        change=nil,keyword=nil,
		value=[(symbolMake ID,PROG)]}
)
end)
 in ( LrTable.NT 4, ( result, VALUE1left, PROG1right), rest671)
end
|  ( 25, ( ( _, ( MlyValue.CHANGE_DECL CHANGE_DECL1, _, 
CHANGE_DECL1right)) :: _ :: ( _, ( MlyValue.CHANGE_DEC CHANGE_DEC1, 
CHANGE_DEC1left, _)) :: rest671)) => let val  result = 
MlyValue.CHANGE_DECL (fn _ => let val  (CHANGE_DEC as CHANGE_DEC1) = 
CHANGE_DEC1 ()
 val  (CHANGE_DECL as CHANGE_DECL1) = CHANGE_DECL1 ()
 in (CHANGE_DEC :: CHANGE_DECL)
end)
 in ( LrTable.NT 14, ( result, CHANGE_DEC1left, CHANGE_DECL1right), 
rest671)
end
|  ( 26, ( ( _, ( MlyValue.CHANGE_DEC CHANGE_DEC1, CHANGE_DEC1left, 
CHANGE_DEC1right)) :: rest671)) => let val  result = 
MlyValue.CHANGE_DECL (fn _ => let val  (CHANGE_DEC as CHANGE_DEC1) = 
CHANGE_DEC1 ()
 in ([CHANGE_DEC])
end)
 in ( LrTable.NT 14, ( result, CHANGE_DEC1left, CHANGE_DEC1right), 
rest671)
end
|  ( 27, ( ( _, ( MlyValue.ID_LIST ID_LIST2, _, ID_LIST2right)) :: _
 :: ( _, ( MlyValue.ID_LIST ID_LIST1, ID_LIST1left, _)) :: rest671))
 => let val  result = MlyValue.CHANGE_DEC (fn _ => let val  ID_LIST1 =
 ID_LIST1 ()
 val  ID_LIST2 = ID_LIST2 ()
 in (ID_LIST1, ID_LIST2)
end)
 in ( LrTable.NT 15, ( result, ID_LIST1left, ID_LIST2right), rest671)

end
|  ( 28, ( ( _, ( MlyValue.SUBST_DECL SUBST_DECL1, _, SUBST_DECL1right
)) :: _ :: ( _, ( MlyValue.SUBST_DEC SUBST_DEC1, SUBST_DEC1left, _))
 :: rest671)) => let val  result = MlyValue.SUBST_DECL (fn _ => let
 val  (SUBST_DEC as SUBST_DEC1) = SUBST_DEC1 ()
 val  (SUBST_DECL as SUBST_DECL1) = SUBST_DECL1 ()
 in (SUBST_DEC :: SUBST_DECL)
end)
 in ( LrTable.NT 12, ( result, SUBST_DEC1left, SUBST_DECL1right), 
rest671)
end
|  ( 29, ( ( _, ( MlyValue.SUBST_DEC SUBST_DEC1, SUBST_DEC1left, 
SUBST_DEC1right)) :: rest671)) => let val  result = 
MlyValue.SUBST_DECL (fn _ => let val  (SUBST_DEC as SUBST_DEC1) = 
SUBST_DEC1 ()
 in ([SUBST_DEC])
end)
 in ( LrTable.NT 12, ( result, SUBST_DEC1left, SUBST_DEC1right), 
rest671)
end
|  ( 30, ( ( _, ( MlyValue.ID ID2, _, ID2right)) :: _ :: ( _, ( 
MlyValue.ID ID1, ID1left, _)) :: rest671)) => let val  result = 
MlyValue.SUBST_DEC (fn _ => let val  ID1 = ID1 ()
 val  ID2 = ID2 ()
 in ([symbolMake ID2],[symbolMake ID1])
end)
 in ( LrTable.NT 13, ( result, ID1left, ID2right), rest671)
end
|  ( 31, ( ( _, ( MlyValue.TY TY1, _, TY1right)) :: _ :: ( _, ( 
MlyValue.ID ID1, _, _)) :: _ :: ( _, ( MlyValue.CONSTR_LIST 
CONSTR_LIST1, CONSTR_LIST1left, _)) :: rest671)) => let val  result = 
MlyValue.CONSTR_LIST (fn _ => let val  (CONSTR_LIST as CONSTR_LIST1) =
 CONSTR_LIST1 ()
 val  (ID as ID1) = ID1 ()
 val  (TY as TY1) = TY1 ()
 in ((symbolMake ID,SOME (tyMake TY))::CONSTR_LIST)
end)
 in ( LrTable.NT 1, ( result, CONSTR_LIST1left, TY1right), rest671)

end
|  ( 32, ( ( _, ( MlyValue.ID ID1, _, ID1right)) :: _ :: ( _, ( 
MlyValue.CONSTR_LIST CONSTR_LIST1, CONSTR_LIST1left, _)) :: rest671))
 => let val  result = MlyValue.CONSTR_LIST (fn _ => let val  (
CONSTR_LIST as CONSTR_LIST1) = CONSTR_LIST1 ()
 val  (ID as ID1) = ID1 ()
 in ((symbolMake ID,NONE)::CONSTR_LIST)
end)
 in ( LrTable.NT 1, ( result, CONSTR_LIST1left, ID1right), rest671)

end
|  ( 33, ( ( _, ( MlyValue.TY TY1, _, TY1right)) :: _ :: ( _, ( 
MlyValue.ID ID1, ID1left, _)) :: rest671)) => let val  result = 
MlyValue.CONSTR_LIST (fn _ => let val  (ID as ID1) = ID1 ()
 val  (TY as TY1) = TY1 ()
 in ([(symbolMake ID,SOME (tyMake TY))])
end)
 in ( LrTable.NT 1, ( result, ID1left, TY1right), rest671)
end
|  ( 34, ( ( _, ( MlyValue.ID ID1, ID1left, ID1right)) :: rest671)) =>
 let val  result = MlyValue.CONSTR_LIST (fn _ => let val  (ID as ID1)
 = ID1 ()
 in ([(symbolMake ID,NONE)])
end)
 in ( LrTable.NT 1, ( result, ID1left, ID1right), rest671)
end
|  ( 35, ( ( _, ( MlyValue.RHS_LIST RHS_LIST1, _, RHS_LIST1right)) ::
 _ :: ( _, ( MlyValue.ID ID1, ID1left, _)) :: rest671)) => let val  
result = MlyValue.G_RULE (fn _ => let val  (ID as ID1) = ID1 ()
 val  (RHS_LIST as RHS_LIST1) = RHS_LIST1 ()
 in (
map (fn {rhs,code,prec} =>
    	          Header.RULE {lhs=symbolMake ID,rhs=rhs,
			       code=code,prec=prec})
	 RHS_LIST
)
end)
 in ( LrTable.NT 9, ( result, ID1left, RHS_LIST1right), rest671)
end
|  ( 36, ( ( _, ( MlyValue.G_RULE G_RULE1, _, G_RULE1right)) :: ( _, (
 MlyValue.G_RULE_LIST G_RULE_LIST1, G_RULE_LIST1left, _)) :: rest671))
 => let val  result = MlyValue.G_RULE_LIST (fn _ => let val  (
G_RULE_LIST as G_RULE_LIST1) = G_RULE_LIST1 ()
 val  (G_RULE as G_RULE1) = G_RULE1 ()
 in (G_RULE@G_RULE_LIST)
end)
 in ( LrTable.NT 10, ( result, G_RULE_LIST1left, G_RULE1right), 
rest671)
end
|  ( 37, ( ( _, ( MlyValue.G_RULE G_RULE1, G_RULE1left, G_RULE1right))
 :: rest671)) => let val  result = MlyValue.G_RULE_LIST (fn _ => let
 val  (G_RULE as G_RULE1) = G_RULE1 ()
 in (G_RULE)
end)
 in ( LrTable.NT 10, ( result, G_RULE1left, G_RULE1right), rest671)

end
|  ( 38, ( ( _, ( MlyValue.ID_LIST ID_LIST1, _, ID_LIST1right)) :: ( _
, ( MlyValue.ID ID1, ID1left, _)) :: rest671)) => let val  result = 
MlyValue.ID_LIST (fn _ => let val  (ID as ID1) = ID1 ()
 val  (ID_LIST as ID_LIST1) = ID_LIST1 ()
 in (symbolMake ID :: ID_LIST)
end)
 in ( LrTable.NT 2, ( result, ID1left, ID_LIST1right), rest671)
end
|  ( 39, ( rest671)) => let val  result = MlyValue.ID_LIST (fn _ => (
nil))
 in ( LrTable.NT 2, ( result, defaultPos, defaultPos), rest671)
end
|  ( 40, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( 
MlyValue.G_RULE_PREC G_RULE_PREC1, _, _)) :: ( _, ( MlyValue.ID_LIST 
ID_LIST1, ID_LIST1left, _)) :: rest671)) => let val  result = 
MlyValue.RHS_LIST (fn _ => let val  (ID_LIST as ID_LIST1) = ID_LIST1
 ()
 val  (G_RULE_PREC as G_RULE_PREC1) = G_RULE_PREC1 ()
 val  (PROG as PROG1) = PROG1 ()
 in ([{rhs=ID_LIST,code=PROG,prec=G_RULE_PREC}])
end)
 in ( LrTable.NT 8, ( result, ID_LIST1left, PROG1right), rest671)
end
|  ( 41, ( ( _, ( MlyValue.PROG PROG1, _, PROG1right)) :: ( _, ( 
MlyValue.G_RULE_PREC G_RULE_PREC1, _, _)) :: ( _, ( MlyValue.ID_LIST 
ID_LIST1, _, _)) :: _ :: ( _, ( MlyValue.RHS_LIST RHS_LIST1, 
RHS_LIST1left, _)) :: rest671)) => let val  result = MlyValue.RHS_LIST
 (fn _ => let val  (RHS_LIST as RHS_LIST1) = RHS_LIST1 ()
 val  (ID_LIST as ID_LIST1) = ID_LIST1 ()
 val  (G_RULE_PREC as G_RULE_PREC1) = G_RULE_PREC1 ()
 val  (PROG as PROG1) = PROG1 ()
 in ({rhs=ID_LIST,code=PROG,prec=G_RULE_PREC}::RHS_LIST)
end)
 in ( LrTable.NT 8, ( result, RHS_LIST1left, PROG1right), rest671)
end
|  ( 42, ( ( _, ( MlyValue.TYVAR TYVAR1, TYVAR1left, TYVAR1right)) :: 
rest671)) => let val  result = MlyValue.TY (fn _ => let val  (TYVAR
 as TYVAR1) = TYVAR1 ()
 in (TYVAR)
end)
 in ( LrTable.NT 16, ( result, TYVAR1left, TYVAR1right), rest671)
end
|  ( 43, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.RECORD_LIST 
RECORD_LIST1, _, _)) :: ( _, ( _, LBRACE1left, _)) :: rest671)) => let
 val  result = MlyValue.TY (fn _ => let val  (RECORD_LIST as 
RECORD_LIST1) = RECORD_LIST1 ()
 in ("{ "^RECORD_LIST^" } ")
end)
 in ( LrTable.NT 16, ( result, LBRACE1left, RBRACE1right), rest671)

end
|  ( 44, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( _, LBRACE1left, _))
 :: rest671)) => let val  result = MlyValue.TY (fn _ => ("{}"))
 in ( LrTable.NT 16, ( result, LBRACE1left, RBRACE1right), rest671)

end
|  ( 45, ( ( _, ( MlyValue.PROG PROG1, PROG1left, PROG1right)) :: 
rest671)) => let val  result = MlyValue.TY (fn _ => let val  (PROG as 
PROG1) = PROG1 ()
 in (" ( "^PROG^" ) ")
end)
 in ( LrTable.NT 16, ( result, PROG1left, PROG1right), rest671)
end
|  ( 46, ( ( _, ( MlyValue.QUAL_ID QUAL_ID1, _, QUAL_ID1right)) :: ( _
, ( MlyValue.TY TY1, TY1left, _)) :: rest671)) => let val  result = 
MlyValue.TY (fn _ => let val  (TY as TY1) = TY1 ()
 val  (QUAL_ID as QUAL_ID1) = QUAL_ID1 ()
 in (TY^" "^QUAL_ID)
end)
 in ( LrTable.NT 16, ( result, TY1left, QUAL_ID1right), rest671)
end
|  ( 47, ( ( _, ( MlyValue.QUAL_ID QUAL_ID1, QUAL_ID1left, 
QUAL_ID1right)) :: rest671)) => let val  result = MlyValue.TY (fn _ =>
 let val  (QUAL_ID as QUAL_ID1) = QUAL_ID1 ()
 in (QUAL_ID)
end)
 in ( LrTable.NT 16, ( result, QUAL_ID1left, QUAL_ID1right), rest671)

end
|  ( 48, ( ( _, ( MlyValue.TY TY2, _, TY2right)) :: _ :: ( _, ( 
MlyValue.TY TY1, TY1left, _)) :: rest671)) => let val  result = 
MlyValue.TY (fn _ => let val  TY1 = TY1 ()
 val  TY2 = TY2 ()
 in (TY1^"*"^TY2)
end)
 in ( LrTable.NT 16, ( result, TY1left, TY2right), rest671)
end
|  ( 49, ( ( _, ( MlyValue.TY TY2, _, TY2right)) :: _ :: ( _, ( 
MlyValue.TY TY1, TY1left, _)) :: rest671)) => let val  result = 
MlyValue.TY (fn _ => let val  TY1 = TY1 ()
 val  TY2 = TY2 ()
 in (TY1 ^ " -> " ^ TY2)
end)
 in ( LrTable.NT 16, ( result, TY1left, TY2right), rest671)
end
|  ( 50, ( ( _, ( MlyValue.TY TY1, _, TY1right)) :: _ :: ( _, ( 
MlyValue.LABEL LABEL1, _, _)) :: _ :: ( _, ( MlyValue.RECORD_LIST 
RECORD_LIST1, RECORD_LIST1left, _)) :: rest671)) => let val  result = 
MlyValue.RECORD_LIST (fn _ => let val  (RECORD_LIST as RECORD_LIST1) =
 RECORD_LIST1 ()
 val  (LABEL as LABEL1) = LABEL1 ()
 val  (TY as TY1) = TY1 ()
 in (RECORD_LIST^","^LABEL^":"^TY)
end)
 in ( LrTable.NT 7, ( result, RECORD_LIST1left, TY1right), rest671)

end
|  ( 51, ( ( _, ( MlyValue.TY TY1, _, TY1right)) :: _ :: ( _, ( 
MlyValue.LABEL LABEL1, LABEL1left, _)) :: rest671)) => let val  result
 = MlyValue.RECORD_LIST (fn _ => let val  (LABEL as LABEL1) = LABEL1
 ()
 val  (TY as TY1) = TY1 ()
 in (LABEL^":"^TY)
end)
 in ( LrTable.NT 7, ( result, LABEL1left, TY1right), rest671)
end
|  ( 52, ( ( _, ( MlyValue.ID ID1, ID1left, ID1right)) :: rest671)) =>
 let val  result = MlyValue.QUAL_ID (fn _ => let val  (ID as ID1) = 
ID1 ()
 in ((fn (a,_) => a) ID)
end)
 in ( LrTable.NT 6, ( result, ID1left, ID1right), rest671)
end
|  ( 53, ( ( _, ( MlyValue.QUAL_ID QUAL_ID1, _, QUAL_ID1right)) :: ( _
, ( MlyValue.IDDOT IDDOT1, IDDOT1left, _)) :: rest671)) => let val  
result = MlyValue.QUAL_ID (fn _ => let val  (IDDOT as IDDOT1) = IDDOT1
 ()
 val  (QUAL_ID as QUAL_ID1) = QUAL_ID1 ()
 in (IDDOT^QUAL_ID)
end)
 in ( LrTable.NT 6, ( result, IDDOT1left, QUAL_ID1right), rest671)
end
|  ( 54, ( ( _, ( MlyValue.ID ID1, ID1left, ID1right)) :: rest671)) =>
 let val  result = MlyValue.LABEL (fn _ => let val  (ID as ID1) = ID1
 ()
 in ((fn (a,_) => a) ID)
end)
 in ( LrTable.NT 3, ( result, ID1left, ID1right), rest671)
end
|  ( 55, ( ( _, ( MlyValue.INT INT1, INT1left, INT1right)) :: rest671)
) => let val  result = MlyValue.LABEL (fn _ => let val  (INT as INT1)
 = INT1 ()
 in (INT)
end)
 in ( LrTable.NT 3, ( result, INT1left, INT1right), rest671)
end
|  ( 56, ( ( _, ( MlyValue.ID ID1, _, ID1right)) :: ( _, ( _, 
PREC_TAG1left, _)) :: rest671)) => let val  result = 
MlyValue.G_RULE_PREC (fn _ => let val  (ID as ID1) = ID1 ()
 in (SOME (symbolMake ID))
end)
 in ( LrTable.NT 11, ( result, PREC_TAG1left, ID1right), rest671)
end
|  ( 57, ( rest671)) => let val  result = MlyValue.G_RULE_PREC (fn _
 => (NONE))
 in ( LrTable.NT 11, ( result, defaultPos, defaultPos), rest671)
end
| _ => raise (mlyAction i392)
val actions = actionFun1
end
val void = MlyValue.VOID
val extract = fn a => (fn MlyValue.BEGIN x => x
| _ => let exception ParseInternal
	in raise ParseInternal end) a ()
end
end
structure Parser =
 struct
   type token = ParserData.LrParser.Token.token
   type stream = ParserData.LrParser.Stream.stream
   type result = ParserData.result
   type pos = ParserData.pos
   type arg = ParserData.arg
   exception ParseError= ParserData.LrParser.ParseError
   fun makeStream {lexer: unit -> token} : stream
     = ParserData.LrParser.Stream.streamify lexer
   val consStream = ParserData.LrParser.Stream.cons
   val getStream = ParserData.LrParser.Stream.get
   val sameToken = ParserData.Token.sameToken
   fun parse {lookahead:int, stream:stream, error: (string * pos * pos -> unit),arg:arg} =
      (fn (a,b) => (ParserData.Actions.extract a,b))
      (ParserData.LrParser.parse
         {table = ParserData.table,
          lexer=stream,
          lookahead=lookahead,
          saction = ParserData.Actions.actions,
          arg=arg,
          void= ParserData.Actions.void,
          ec = {is_keyword = ParserData.EC.is_keyword,
                noShift = ParserData.EC.noShift,
                preferred_change = ParserData.EC.preferred_change,
                errtermvalue = ParserData.EC.errtermvalue,
                error=error,
                showTerminal = ParserData.EC.showTerminal,
                terms = ParserData.EC.terms}}
      )
 end
structure Token = ParserData.LrParser.Token
structure Tokens : Mlyacc_TOKENS =
struct
type pos = ParserData.pos
type token = ParserData.Token.token
fun ARROW (p1,p2) = Token.TOKEN (ParserData.LrTable.T 0,(
ParserData.MlyValue.VOID,p1,p2))
fun ASTERISK (p1,p2) = Token.TOKEN (ParserData.LrTable.T 1,(
ParserData.MlyValue.VOID,p1,p2))
fun BLOCK (p1,p2) = Token.TOKEN (ParserData.LrTable.T 2,(
ParserData.MlyValue.VOID,p1,p2))
fun BAR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 3,(
ParserData.MlyValue.VOID,p1,p2))
fun CHANGE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 4,(
ParserData.MlyValue.VOID,p1,p2))
fun COLON (p1,p2) = Token.TOKEN (ParserData.LrTable.T 5,(
ParserData.MlyValue.VOID,p1,p2))
fun COMMA (p1,p2) = Token.TOKEN (ParserData.LrTable.T 6,(
ParserData.MlyValue.VOID,p1,p2))
fun DELIMITER (p1,p2) = Token.TOKEN (ParserData.LrTable.T 7,(
ParserData.MlyValue.VOID,p1,p2))
fun EOF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 8,(
ParserData.MlyValue.VOID,p1,p2))
fun FOR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 9,(
ParserData.MlyValue.VOID,p1,p2))
fun HEADER (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 10,(
ParserData.MlyValue.HEADER (fn () => i),p1,p2))
fun ID (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 11,(
ParserData.MlyValue.ID (fn () => i),p1,p2))
fun IDDOT (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 12,(
ParserData.MlyValue.IDDOT (fn () => i),p1,p2))
fun PERCENT_HEADER (p1,p2) = Token.TOKEN (ParserData.LrTable.T 13,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_FOOTER (p1,p2) = Token.TOKEN (ParserData.LrTable.T 14,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_DECOMPOSE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 15,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_BLOCKSIZE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 16,(
ParserData.MlyValue.VOID,p1,p2))
fun INT (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 17,(
ParserData.MlyValue.INT (fn () => i),p1,p2))
fun KEYWORD (p1,p2) = Token.TOKEN (ParserData.LrTable.T 18,(
ParserData.MlyValue.VOID,p1,p2))
fun LBRACE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 19,(
ParserData.MlyValue.VOID,p1,p2))
fun LPAREN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 20,(
ParserData.MlyValue.VOID,p1,p2))
fun NAME (p1,p2) = Token.TOKEN (ParserData.LrTable.T 21,(
ParserData.MlyValue.VOID,p1,p2))
fun NODEFAULT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 22,(
ParserData.MlyValue.VOID,p1,p2))
fun NONTERM (p1,p2) = Token.TOKEN (ParserData.LrTable.T 23,(
ParserData.MlyValue.VOID,p1,p2))
fun NOSHIFT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 24,(
ParserData.MlyValue.VOID,p1,p2))
fun OF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 25,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_EOP (p1,p2) = Token.TOKEN (ParserData.LrTable.T 26,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_PURE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 27,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_POS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 28,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_ARG (p1,p2) = Token.TOKEN (ParserData.LrTable.T 29,(
ParserData.MlyValue.VOID,p1,p2))
fun PERCENT_TOKEN_SIG_INFO (p1,p2) = Token.TOKEN (
ParserData.LrTable.T 30,(ParserData.MlyValue.VOID,p1,p2))
fun PREC (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 31,(
ParserData.MlyValue.PREC (fn () => i),p1,p2))
fun PREC_TAG (p1,p2) = Token.TOKEN (ParserData.LrTable.T 32,(
ParserData.MlyValue.VOID,p1,p2))
fun PREFER (p1,p2) = Token.TOKEN (ParserData.LrTable.T 33,(
ParserData.MlyValue.VOID,p1,p2))
fun PROG (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 34,(
ParserData.MlyValue.PROG (fn () => i),p1,p2))
fun RBRACE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 35,(
ParserData.MlyValue.VOID,p1,p2))
fun RPAREN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 36,(
ParserData.MlyValue.VOID,p1,p2))
fun SUBST (p1,p2) = Token.TOKEN (ParserData.LrTable.T 37,(
ParserData.MlyValue.VOID,p1,p2))
fun START (p1,p2) = Token.TOKEN (ParserData.LrTable.T 38,(
ParserData.MlyValue.VOID,p1,p2))
fun TERM (p1,p2) = Token.TOKEN (ParserData.LrTable.T 39,(
ParserData.MlyValue.VOID,p1,p2))
fun TYVAR (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 40,(
ParserData.MlyValue.TYVAR (fn () => i),p1,p2))
fun VERBOSE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 41,(
ParserData.MlyValue.VOID,p1,p2))
fun VALUE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 42,(
ParserData.MlyValue.VOID,p1,p2))
fun UNKNOWN (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 43,(
ParserData.MlyValue.UNKNOWN (fn () => i),p1,p2))
fun BOGUS_VALUE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 44,(
ParserData.MlyValue.VOID,p1,p2))
end
end

