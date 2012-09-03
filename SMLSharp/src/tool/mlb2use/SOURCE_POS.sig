(**
 * @version $Id: SOURCE_POS.sig,v 1.1 2007/07/29 00:50:00 kiyoshiy Exp $
 *)
(* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)
signature SOURCE_POS = 
   sig
      type t

      val bogus: t
      val compare: t * t -> General.order
      val equals: t * t -> bool
      val file: t -> File.t
      val line: t -> int
      val make: {column: int,
                 file: File.t,
                 line: int} -> t
      val posToString: t -> string
      val toString: t -> string
   end
