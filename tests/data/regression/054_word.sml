val x = 0w0 : word

(*
2011-08-22 katsu

This causes an unexpected type error.

054_word.sml:1.9-1.18 Error:
  (type inference 012) type and type annotation don't agree
  inferred type: 'c::{word(t1),
                      SMLSharp.Word8.word(t1),
                      ('a::{word(t1), word(t1) option(t15)}, 'b)
                       value(t23)}
  type annotation: word(t1)
*)

(*
2011-08-23 ohori


This is due to the fact that 0w0 has an overloaded type having
two same instances, namely "t1" of different names.

  inferred type: 'c::{word(t1),                 <=========
                      SMLSharp.Word8.word(t1),  <=========
                       ....
                      }

If these the same type then the declaration is illegal, 
otherwise something wong with builtin declaration.

2011-08-23 ohori
Fixed a bug in the definition of WORD8tyCon in BuiltinEnv.sml
*)
