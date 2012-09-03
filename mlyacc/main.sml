(* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

structure Main =
struct

fun usage s = 
    print (s ^ "\n" ^ "Usage: smlyacc file.yacc")

fun main (_, []) = (usage "no files"; OS.Process.failure)
  | main (_, [file]) = (ParseGen.parseGen file; OS.Process.success)
  | main _ = (usage "too many files"; OS.Process.failure)

end
