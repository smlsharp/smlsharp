functor MLBLrValsFun(structure Token : TOKEN)
 : sig structure ParserData : PARSER_DATA
       structure Tokens : MLB_TOKENS
   end
 = 
struct
structure ParserData=
struct
structure Header = 
struct
(* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

type file = string


end
structure LrTable = Token.LrTable
structure Token = Token
local open LrTable in 
val table=let val actionRows =
"\
\\001\000\001\000\025\000\000\000\
\\001\000\001\000\025\000\006\000\070\000\012\000\069\000\000\000\
\\001\000\004\000\000\000\000\000\
\\001\000\007\000\016\000\010\000\015\000\013\000\014\000\014\000\013\000\
\\015\000\012\000\016\000\011\000\017\000\010\000\018\000\009\000\
\\019\000\008\000\020\000\007\000\000\000\
\\001\000\008\000\071\000\000\000\
\\001\000\008\000\074\000\000\000\
\\001\000\008\000\082\000\000\000\
\\001\000\008\000\084\000\000\000\
\\001\000\009\000\053\000\000\000\
\\001\000\011\000\039\000\000\000\
\\001\000\011\000\049\000\000\000\
\\001\000\011\000\081\000\000\000\
\\001\000\020\000\021\000\000\000\
\\086\000\000\000\
\\087\000\000\000\
\\088\000\003\000\017\000\007\000\016\000\010\000\015\000\013\000\014\000\
\\014\000\013\000\015\000\012\000\016\000\011\000\017\000\010\000\
\\018\000\009\000\019\000\008\000\020\000\007\000\000\000\
\\089\000\000\000\
\\090\000\000\000\
\\091\000\000\000\
\\092\000\000\000\
\\093\000\000\000\
\\094\000\000\000\
\\095\000\000\000\
\\096\000\000\000\
\\097\000\000\000\
\\098\000\000\000\
\\099\000\000\000\
\\100\000\000\000\
\\101\000\000\000\
\\102\000\000\000\
\\103\000\000\000\
\\104\000\000\000\
\\105\000\005\000\052\000\000\000\
\\105\000\005\000\052\000\009\000\051\000\000\000\
\\106\000\000\000\
\\107\000\000\000\
\\108\000\000\000\
\\109\000\000\000\
\\110\000\005\000\047\000\000\000\
\\110\000\005\000\047\000\009\000\046\000\000\000\
\\111\000\000\000\
\\112\000\000\000\
\\113\000\000\000\
\\114\000\000\000\
\\115\000\005\000\044\000\000\000\
\\115\000\005\000\044\000\009\000\043\000\000\000\
\\116\000\000\000\
\\117\000\000\000\
\\118\000\000\000\
\\119\000\005\000\077\000\000\000\
\\120\000\000\000\
\\121\000\000\000\
\\122\000\000\000\
\\123\000\000\000\
\\124\000\000\000\
\\125\000\000\000\
\\126\000\001\000\025\000\000\000\
\\127\000\000\000\
\\128\000\000\000\
\\129\000\000\000\
\\130\000\000\000\
\\131\000\000\000\
\\132\000\000\000\
\\133\000\000\000\
\\134\000\020\000\021\000\000\000\
\\135\000\000\000\
\"
val actionRowNumbers =
"\015\000\014\000\013\000\018\000\
\\015\000\026\000\025\000\027\000\
\\012\000\000\000\000\000\000\000\
\\015\000\000\000\000\000\015\000\
\\017\000\009\000\064\000\062\000\
\\045\000\021\000\060\000\061\000\
\\039\000\020\000\059\000\055\000\
\\024\000\056\000\010\000\058\000\
\\033\000\019\000\008\000\022\000\
\\016\000\015\000\063\000\065\000\
\\042\000\000\000\000\000\036\000\
\\000\000\000\000\057\000\015\000\
\\030\000\000\000\000\000\001\000\
\\004\000\044\000\041\000\046\000\
\\038\000\035\000\040\000\005\000\
\\032\000\029\000\034\000\053\000\
\\051\000\049\000\047\000\003\000\
\\015\000\028\000\043\000\037\000\
\\023\000\031\000\048\000\000\000\
\\011\000\006\000\050\000\001\000\
\\052\000\007\000\054\000\002\000"
val gotoT =
"\
\\007\000\004\000\008\000\003\000\009\000\002\000\010\000\001\000\
\\020\000\083\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\007\000\004\000\008\000\003\000\009\000\016\000\010\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\001\000\018\000\002\000\017\000\000\000\
\\019\000\022\000\025\000\021\000\028\000\020\000\000\000\
\\019\000\026\000\021\000\025\000\024\000\024\000\000\000\
\\013\000\029\000\014\000\028\000\019\000\027\000\000\000\
\\007\000\004\000\008\000\003\000\009\000\030\000\010\000\001\000\000\000\
\\015\000\033\000\018\000\032\000\019\000\031\000\000\000\
\\004\000\035\000\013\000\034\000\019\000\027\000\000\000\
\\007\000\004\000\008\000\003\000\009\000\036\000\010\000\001\000\000\000\
\\000\000\
\\000\000\
\\001\000\018\000\002\000\039\000\003\000\038\000\000\000\
\\000\000\
\\027\000\040\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\023\000\043\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\029\000\014\000\046\000\019\000\027\000\000\000\
\\000\000\
\\000\000\
\\017\000\048\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\007\000\004\000\008\000\003\000\009\000\052\000\010\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\019\000\022\000\026\000\054\000\028\000\053\000\000\000\
\\019\000\022\000\025\000\055\000\028\000\020\000\000\000\
\\000\000\
\\019\000\026\000\022\000\057\000\024\000\056\000\000\000\
\\019\000\026\000\021\000\058\000\024\000\024\000\000\000\
\\000\000\
\\007\000\004\000\008\000\003\000\009\000\059\000\010\000\001\000\000\000\
\\000\000\
\\016\000\061\000\018\000\060\000\019\000\031\000\000\000\
\\015\000\062\000\018\000\032\000\019\000\031\000\000\000\
\\005\000\066\000\011\000\065\000\012\000\064\000\013\000\063\000\
\\019\000\027\000\000\000\
\\000\000\
\\027\000\070\000\000\000\
\\000\000\
\\000\000\
\\023\000\071\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\017\000\073\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\006\000\074\000\000\000\
\\000\000\
\\007\000\076\000\008\000\003\000\000\000\
\\007\000\004\000\008\000\003\000\009\000\077\000\010\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\004\000\078\000\013\000\034\000\019\000\027\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\011\000\081\000\012\000\064\000\013\000\063\000\019\000\027\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\"
val numstates = 84
val numrules = 50
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
local open Header in
type pos = SourcePos.t
type arg = unit
structure MlyValue = 
struct
datatype svalue = VOID | ntVOID of unit ->  unit
 | STRING of unit ->  (string) | FILE of unit ->  (string)
 | ID of unit ->  (string) | strid of unit ->  (unit)
 | strbinds'' of unit ->  (unit) | strbinds' of unit ->  (unit)
 | strbinds of unit ->  (unit) | sigid of unit ->  (unit)
 | sigbinds'' of unit ->  (unit) | sigbinds' of unit ->  (unit)
 | sigbinds of unit ->  (unit) | mlb of unit ->  (file list)
 | id of unit ->  (unit) | fctid of unit ->  (unit)
 | fctbinds'' of unit ->  (unit) | fctbinds' of unit ->  (unit)
 | fctbinds of unit ->  (unit) | basids of unit ->  (unit)
 | basid of unit ->  (unit) | basexpnode of unit ->  (unit)
 | basexp of unit ->  (unit) | basdecsnode of unit ->  (file list)
 | basdecs of unit ->  (file list)
 | basdecnode of unit ->  (file list) | basdec of unit ->  (file list)
 | basbinds'' of unit ->  (unit) | basbinds' of unit ->  (unit)
 | basbinds of unit ->  (unit) | annStar of unit ->  (unit)
 | annPlus of unit ->  (unit) | ann of unit ->  (unit)
end
type svalue = MlyValue.svalue
type result = file list
end
structure EC=
struct
open LrTable
val is_keyword =
fn (T 4) => true | (T 5) => true | (T 6) => true | (T 7) => true | (T 
9) => true | (T 10) => true | (T 11) => true | (T 12) => true | (T 13)
 => true | (T 14) => true | (T 15) => true | (T 16) => true | (T 17)
 => true | _ => false
val preferred_change = 
(nil
,(T 2) :: nil
)::
(nil
,(T 10) :: (T 0) :: (T 7) :: nil
)::
nil
val noShift = 
fn (T 3) => true | _ => false
val showTerminal =
fn (T 0) => "ID"
  | (T 1) => "COMMA"
  | (T 2) => "SEMICOLON"
  | (T 3) => "EOF"
  | (T 4) => "AND"
  | (T 5) => "BAS"
  | (T 6) => "BASIS"
  | (T 7) => "END"
  | (T 8) => "EQUALOP"
  | (T 9) => "FUNCTOR"
  | (T 10) => "IN"
  | (T 11) => "LET"
  | (T 12) => "LOCAL"
  | (T 13) => "OPEN"
  | (T 14) => "SIGNATURE"
  | (T 15) => "STRUCTURE"
  | (T 16) => "ANN"
  | (T 17) => "PRIM"
  | (T 18) => "FILE"
  | (T 19) => "STRING"
  | _ => "bogus-term"
local open Header in
val errtermvalue=
fn (T 0) => MlyValue.ID(fn () => ("bogus")) | 
_ => MlyValue.VOID
end
val terms = (T 1) :: (T 2) :: (T 3) :: (T 4) :: (T 5) :: (T 6) :: (T 7
) :: (T 8) :: (T 9) :: (T 10) :: (T 11) :: (T 12) :: (T 13) :: (T 14)
 :: (T 15) :: (T 16) :: (T 17) :: nil
end
structure Actions =
struct 
exception mlyAction of int
local open Header in
val actions = 
fn (i392,defaultPos,stack,
    (()):arg) =>
case (i392,stack)
of (0,(_,(MlyValue.basdecs basdecs1,basdecs1left,basdecs1right))::
rest671) => let val result=MlyValue.mlb(fn _ => let val basdecs as 
basdecs1=basdecs1 ()
 in (basdecs) end
)
 in (LrTable.NT 19,(result,basdecs1left,basdecs1right),rest671) end
| (1,(_,(MlyValue.basdecsnode basdecsnode1,basdecsnode1left,
basdecsnode1right))::rest671) => let val result=MlyValue.basdecs(fn _
 => let val basdecsnode as basdecsnode1=basdecsnode1 ()
 in (basdecsnode) end
)
 in (LrTable.NT 8,(result,basdecsnode1left,basdecsnode1right),rest671)
 end
| (2,rest671) => let val result=MlyValue.basdecsnode(fn _ => ([]))
 in (LrTable.NT 9,(result,defaultPos,defaultPos),rest671) end
| (3,(_,(MlyValue.basdecs basdecs1,_,basdecs1right))::(_,(_,
SEMICOLON1left,_))::rest671) => let val result=MlyValue.basdecsnode(
fn _ => let val basdecs as basdecs1=basdecs1 ()
 in (basdecs) end
)
 in (LrTable.NT 9,(result,SEMICOLON1left,basdecs1right),rest671) end
| (4,(_,(MlyValue.basdecs basdecs1,_,basdecs1right))::(_,(
MlyValue.basdec basdec1,basdec1left,_))::rest671) => let val result=
MlyValue.basdecsnode(fn _ => let val basdec as basdec1=basdec1 ()
val basdecs as basdecs1=basdecs1 ()
 in (basdec @ basdecs) end
)
 in (LrTable.NT 9,(result,basdec1left,basdecs1right),rest671) end
| (5,(_,(MlyValue.basdecnode basdecnode1,basdecnode1left,
basdecnode1right))::rest671) => let val result=MlyValue.basdec(fn _
 => let val basdecnode as basdecnode1=basdecnode1 ()
 in (basdecnode) end
)
 in (LrTable.NT 6,(result,basdecnode1left,basdecnode1right),rest671)
 end
| (6,(_,(MlyValue.fctbinds fctbinds1,_,fctbinds1right))::(_,(_,
FUNCTOR1left,_))::rest671) => let val result=MlyValue.basdecnode(fn _
 => let val fctbinds1=fctbinds1 ()
 in ([]) end
)
 in (LrTable.NT 7,(result,FUNCTOR1left,fctbinds1right),rest671) end
| (7,(_,(MlyValue.sigbinds sigbinds1,_,sigbinds1right))::(_,(_,
SIGNATURE1left,_))::rest671) => let val result=MlyValue.basdecnode(fn 
_ => let val sigbinds1=sigbinds1 ()
 in ([]) end
)
 in (LrTable.NT 7,(result,SIGNATURE1left,sigbinds1right),rest671) end
| (8,(_,(MlyValue.strbinds strbinds1,_,strbinds1right))::(_,(_,
STRUCTURE1left,_))::rest671) => let val result=MlyValue.basdecnode(fn 
_ => let val strbinds1=strbinds1 ()
 in ([]) end
)
 in (LrTable.NT 7,(result,STRUCTURE1left,strbinds1right),rest671) end
| (9,(_,(MlyValue.basbinds basbinds1,_,basbinds1right))::(_,(_,
BASIS1left,_))::rest671) => let val result=MlyValue.basdecnode(fn _
 => let val basbinds1=basbinds1 ()
 in ([]) end
)
 in (LrTable.NT 7,(result,BASIS1left,basbinds1right),rest671) end
| (10,(_,(_,_,END1right))::(_,(MlyValue.basdecs basdecs2,_,_))::_::(_,
(MlyValue.basdecs basdecs1,_,_))::(_,(_,LOCAL1left,_))::rest671) => 
let val result=MlyValue.basdecnode(fn _ => let val basdecs1=basdecs1 
()
val basdecs2=basdecs2 ()
 in (basdecs1 @ basdecs2) end
)
 in (LrTable.NT 7,(result,LOCAL1left,END1right),rest671) end
| (11,(_,(MlyValue.basids basids1,_,basids1right))::(_,(_,OPEN1left,_)
)::rest671) => let val result=MlyValue.basdecnode(fn _ => let val 
basids1=basids1 ()
 in ([]) end
)
 in (LrTable.NT 7,(result,OPEN1left,basids1right),rest671) end
| (12,(_,(MlyValue.FILE FILE1,FILE1left,FILE1right))::rest671) => let 
val result=MlyValue.basdecnode(fn _ => let val FILE as FILE1=FILE1 ()
 in ([FILE]) end
)
 in (LrTable.NT 7,(result,FILE1left,FILE1right),rest671) end
| (13,(_,(MlyValue.STRING STRING1,STRING1left,STRING1right))::rest671)
 => let val result=MlyValue.basdecnode(fn _ => let val STRING as 
STRING1=STRING1 ()
 in ([STRING]) end
)
 in (LrTable.NT 7,(result,STRING1left,STRING1right),rest671) end
| (14,(_,(_,PRIM1left,PRIM1right))::rest671) => let val result=
MlyValue.basdecnode(fn _ => ([]))
 in (LrTable.NT 7,(result,PRIM1left,PRIM1right),rest671) end
| (15,(_,(_,_,END1right))::(_,(MlyValue.basdecs basdecs1,_,_))::_::(_,
(MlyValue.annPlus annPlus1,_,_))::(_,(_,ANN1left,_))::rest671) => let 
val result=MlyValue.basdecnode(fn _ => let val annPlus1=annPlus1 ()
val basdecs as basdecs1=basdecs1 ()
 in (basdecs) end
)
 in (LrTable.NT 7,(result,ANN1left,END1right),rest671) end
| (16,(_,(MlyValue.fctbinds' fctbinds'1,_,fctbinds'1right))::_::(_,(
MlyValue.fctid fctid1,fctid1left,_))::rest671) => let val result=
MlyValue.fctbinds(fn _ => let val fctid1=fctid1 ()
val fctbinds'1=fctbinds'1 ()
 in () end
)
 in (LrTable.NT 14,(result,fctid1left,fctbinds'1right),rest671) end
| (17,(_,(MlyValue.fctbinds'' fctbinds''1,_,fctbinds''1right))::(_,(
MlyValue.fctid fctid1,fctid1left,_))::rest671) => let val result=
MlyValue.fctbinds(fn _ => let val fctid1=fctid1 ()
val fctbinds''1=fctbinds''1 ()
 in () end
)
 in (LrTable.NT 14,(result,fctid1left,fctbinds''1right),rest671) end
| (18,(_,(MlyValue.fctbinds'' fctbinds''1,_,fctbinds''1right))::(_,(
MlyValue.fctid fctid1,fctid1left,_))::rest671) => let val result=
MlyValue.fctbinds'(fn _ => let val fctid1=fctid1 ()
val fctbinds''1=fctbinds''1 ()
 in () end
)
 in (LrTable.NT 15,(result,fctid1left,fctbinds''1right),rest671) end
| (19,rest671) => let val result=MlyValue.fctbinds''(fn _ => ())
 in (LrTable.NT 16,(result,defaultPos,defaultPos),rest671) end
| (20,(_,(MlyValue.fctbinds fctbinds1,_,fctbinds1right))::(_,(_,
AND1left,_))::rest671) => let val result=MlyValue.fctbinds''(fn _ => 
let val fctbinds1=fctbinds1 ()
 in () end
)
 in (LrTable.NT 16,(result,AND1left,fctbinds1right),rest671) end
| (21,(_,(MlyValue.sigbinds' sigbinds'1,_,sigbinds'1right))::_::(_,(
MlyValue.sigid sigid1,sigid1left,_))::rest671) => let val result=
MlyValue.sigbinds(fn _ => let val sigid1=sigid1 ()
val sigbinds'1=sigbinds'1 ()
 in () end
)
 in (LrTable.NT 20,(result,sigid1left,sigbinds'1right),rest671) end
| (22,(_,(MlyValue.sigbinds'' sigbinds''1,_,sigbinds''1right))::(_,(
MlyValue.sigid sigid1,sigid1left,_))::rest671) => let val result=
MlyValue.sigbinds(fn _ => let val sigid1=sigid1 ()
val sigbinds''1=sigbinds''1 ()
 in () end
)
 in (LrTable.NT 20,(result,sigid1left,sigbinds''1right),rest671) end
| (23,(_,(MlyValue.sigbinds'' sigbinds''1,_,sigbinds''1right))::(_,(
MlyValue.sigid sigid1,sigid1left,_))::rest671) => let val result=
MlyValue.sigbinds'(fn _ => let val sigid1=sigid1 ()
val sigbinds''1=sigbinds''1 ()
 in () end
)
 in (LrTable.NT 21,(result,sigid1left,sigbinds''1right),rest671) end
| (24,rest671) => let val result=MlyValue.sigbinds''(fn _ => ())
 in (LrTable.NT 22,(result,defaultPos,defaultPos),rest671) end
| (25,(_,(MlyValue.sigbinds sigbinds1,_,sigbinds1right))::(_,(_,
AND1left,_))::rest671) => let val result=MlyValue.sigbinds''(fn _ => 
let val sigbinds1=sigbinds1 ()
 in () end
)
 in (LrTable.NT 22,(result,AND1left,sigbinds1right),rest671) end
| (26,(_,(MlyValue.strbinds' strbinds'1,_,strbinds'1right))::_::(_,(
MlyValue.strid strid1,strid1left,_))::rest671) => let val result=
MlyValue.strbinds(fn _ => let val strid1=strid1 ()
val strbinds'1=strbinds'1 ()
 in () end
)
 in (LrTable.NT 24,(result,strid1left,strbinds'1right),rest671) end
| (27,(_,(MlyValue.strbinds'' strbinds''1,_,strbinds''1right))::(_,(
MlyValue.strid strid1,strid1left,_))::rest671) => let val result=
MlyValue.strbinds(fn _ => let val strid1=strid1 ()
val strbinds''1=strbinds''1 ()
 in () end
)
 in (LrTable.NT 24,(result,strid1left,strbinds''1right),rest671) end
| (28,(_,(MlyValue.strbinds'' strbinds''1,_,strbinds''1right))::(_,(
MlyValue.strid strid1,strid1left,_))::rest671) => let val result=
MlyValue.strbinds'(fn _ => let val strid1=strid1 ()
val strbinds''1=strbinds''1 ()
 in () end
)
 in (LrTable.NT 25,(result,strid1left,strbinds''1right),rest671) end
| (29,rest671) => let val result=MlyValue.strbinds''(fn _ => ())
 in (LrTable.NT 26,(result,defaultPos,defaultPos),rest671) end
| (30,(_,(MlyValue.strbinds strbinds1,_,strbinds1right))::(_,(_,
AND1left,_))::rest671) => let val result=MlyValue.strbinds''(fn _ => 
let val strbinds1=strbinds1 ()
 in () end
)
 in (LrTable.NT 26,(result,AND1left,strbinds1right),rest671) end
| (31,(_,(MlyValue.basbinds' basbinds'1,_,basbinds'1right))::_::(_,(
MlyValue.basid basid1,basid1left,_))::rest671) => let val result=
MlyValue.basbinds(fn _ => let val basid1=basid1 ()
val basbinds'1=basbinds'1 ()
 in () end
)
 in (LrTable.NT 3,(result,basid1left,basbinds'1right),rest671) end
| (32,(_,(MlyValue.basbinds'' basbinds''1,_,basbinds''1right))::(_,(
MlyValue.basexp basexp1,basexp1left,_))::rest671) => let val result=
MlyValue.basbinds'(fn _ => let val basexp1=basexp1 ()
val basbinds''1=basbinds''1 ()
 in () end
)
 in (LrTable.NT 4,(result,basexp1left,basbinds''1right),rest671) end
| (33,rest671) => let val result=MlyValue.basbinds''(fn _ => ())
 in (LrTable.NT 5,(result,defaultPos,defaultPos),rest671) end
| (34,(_,(MlyValue.basbinds basbinds1,_,basbinds1right))::(_,(_,
AND1left,_))::rest671) => let val result=MlyValue.basbinds''(fn _ => 
let val basbinds1=basbinds1 ()
 in () end
)
 in (LrTable.NT 5,(result,AND1left,basbinds1right),rest671) end
| (35,(_,(MlyValue.basexpnode basexpnode1,basexpnode1left,
basexpnode1right))::rest671) => let val result=MlyValue.basexp(fn _
 => let val basexpnode1=basexpnode1 ()
 in () end
)
 in (LrTable.NT 10,(result,basexpnode1left,basexpnode1right),rest671)
 end
| (36,(_,(_,_,END1right))::(_,(MlyValue.basdecs basdecs1,_,_))::(_,(_,
BAS1left,_))::rest671) => let val result=MlyValue.basexpnode(fn _ => 
let val basdecs1=basdecs1 ()
 in () end
)
 in (LrTable.NT 11,(result,BAS1left,END1right),rest671) end
| (37,(_,(MlyValue.basid basid1,basid1left,basid1right))::rest671) => 
let val result=MlyValue.basexpnode(fn _ => let val basid1=basid1 ()
 in () end
)
 in (LrTable.NT 11,(result,basid1left,basid1right),rest671) end
| (38,(_,(_,_,END1right))::(_,(MlyValue.basexp basexp1,_,_))::_::(_,(
MlyValue.basdec basdec1,_,_))::(_,(_,LET1left,_))::rest671) => let 
val result=MlyValue.basexpnode(fn _ => let val basdec1=basdec1 ()
val basexp1=basexp1 ()
 in () end
)
 in (LrTable.NT 11,(result,LET1left,END1right),rest671) end
| (39,(_,(MlyValue.id id1,id1left,id1right))::rest671) => let val 
result=MlyValue.basid(fn _ => let val id1=id1 ()
 in () end
)
 in (LrTable.NT 12,(result,id1left,id1right),rest671) end
| (40,(_,(MlyValue.basid basid1,basid1left,basid1right))::rest671) => 
let val result=MlyValue.basids(fn _ => let val basid1=basid1 ()
 in () end
)
 in (LrTable.NT 13,(result,basid1left,basid1right),rest671) end
| (41,(_,(MlyValue.basids basids1,_,basids1right))::(_,(MlyValue.basid
 basid1,basid1left,_))::rest671) => let val result=MlyValue.basids(fn 
_ => let val basid1=basid1 ()
val basids1=basids1 ()
 in () end
)
 in (LrTable.NT 13,(result,basid1left,basids1right),rest671) end
| (42,(_,(MlyValue.id id1,id1left,id1right))::rest671) => let val 
result=MlyValue.fctid(fn _ => let val id1=id1 ()
 in () end
)
 in (LrTable.NT 17,(result,id1left,id1right),rest671) end
| (43,(_,(MlyValue.id id1,id1left,id1right))::rest671) => let val 
result=MlyValue.sigid(fn _ => let val id1=id1 ()
 in () end
)
 in (LrTable.NT 23,(result,id1left,id1right),rest671) end
| (44,(_,(MlyValue.id id1,id1left,id1right))::rest671) => let val 
result=MlyValue.strid(fn _ => let val id1=id1 ()
 in () end
)
 in (LrTable.NT 27,(result,id1left,id1right),rest671) end
| (45,(_,(MlyValue.ID ID1,ID1left,ID1right))::rest671) => let val 
result=MlyValue.id(fn _ => let val ID1=ID1 ()
 in () end
)
 in (LrTable.NT 18,(result,ID1left,ID1right),rest671) end
| (46,(_,(MlyValue.STRING STRING1,STRING1left,STRING1right))::rest671)
 => let val result=MlyValue.ann(fn _ => let val STRING1=STRING1 ()
 in () end
)
 in (LrTable.NT 0,(result,STRING1left,STRING1right),rest671) end
| (47,(_,(MlyValue.annStar annStar1,_,annStar1right))::(_,(
MlyValue.ann ann1,ann1left,_))::rest671) => let val result=
MlyValue.annPlus(fn _ => let val ann1=ann1 ()
val annStar1=annStar1 ()
 in () end
)
 in (LrTable.NT 1,(result,ann1left,annStar1right),rest671) end
| (48,rest671) => let val result=MlyValue.annStar(fn _ => ())
 in (LrTable.NT 2,(result,defaultPos,defaultPos),rest671) end
| (49,(_,(MlyValue.annPlus annPlus1,annPlus1left,annPlus1right))::
rest671) => let val result=MlyValue.annStar(fn _ => let val annPlus1=
annPlus1 ()
 in () end
)
 in (LrTable.NT 2,(result,annPlus1left,annPlus1right),rest671) end
| _ => raise (mlyAction i392)
end
val void = MlyValue.VOID
val extract = fn a => (fn MlyValue.mlb x => x
| _ => let exception ParseInternal
	in raise ParseInternal end) a ()
end
end
structure Tokens : MLB_TOKENS =
struct
type svalue = ParserData.svalue
type ('a,'b) token = ('a,'b) Token.token
fun ID (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 0,(
ParserData.MlyValue.ID (fn () => i),p1,p2))
fun COMMA (p1,p2) = Token.TOKEN (ParserData.LrTable.T 1,(
ParserData.MlyValue.VOID,p1,p2))
fun SEMICOLON (p1,p2) = Token.TOKEN (ParserData.LrTable.T 2,(
ParserData.MlyValue.VOID,p1,p2))
fun EOF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 3,(
ParserData.MlyValue.VOID,p1,p2))
fun AND (p1,p2) = Token.TOKEN (ParserData.LrTable.T 4,(
ParserData.MlyValue.VOID,p1,p2))
fun BAS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 5,(
ParserData.MlyValue.VOID,p1,p2))
fun BASIS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 6,(
ParserData.MlyValue.VOID,p1,p2))
fun END (p1,p2) = Token.TOKEN (ParserData.LrTable.T 7,(
ParserData.MlyValue.VOID,p1,p2))
fun EQUALOP (p1,p2) = Token.TOKEN (ParserData.LrTable.T 8,(
ParserData.MlyValue.VOID,p1,p2))
fun FUNCTOR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 9,(
ParserData.MlyValue.VOID,p1,p2))
fun IN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 10,(
ParserData.MlyValue.VOID,p1,p2))
fun LET (p1,p2) = Token.TOKEN (ParserData.LrTable.T 11,(
ParserData.MlyValue.VOID,p1,p2))
fun LOCAL (p1,p2) = Token.TOKEN (ParserData.LrTable.T 12,(
ParserData.MlyValue.VOID,p1,p2))
fun OPEN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 13,(
ParserData.MlyValue.VOID,p1,p2))
fun SIGNATURE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 14,(
ParserData.MlyValue.VOID,p1,p2))
fun STRUCTURE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 15,(
ParserData.MlyValue.VOID,p1,p2))
fun ANN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 16,(
ParserData.MlyValue.VOID,p1,p2))
fun PRIM (p1,p2) = Token.TOKEN (ParserData.LrTable.T 17,(
ParserData.MlyValue.VOID,p1,p2))
fun FILE (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 18,(
ParserData.MlyValue.FILE (fn () => i),p1,p2))
fun STRING (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 19,(
ParserData.MlyValue.STRING (fn () => i),p1,p2))
end
end
