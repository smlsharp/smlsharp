(**
 * @copyright (c) 2007, Tohoku University.
 * @copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * @copyright (C) 1997-2000 NEC Research Institute.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PathMap.sml,v 1.2 2007/08/10 04:59:12 kiyoshiy Exp $
 *)
(* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)
structure PathMap
: sig
    type pathMap
    val empty : pathMap
    val new : string -> pathMap
    val expand : pathMap -> string -> string
  end =
struct

  type pathMap = (string * string) list

  val empty = []

  fun new name =
      let
        val stream = TextIO.openIn name
        fun loop entries =
            case TextIO.inputLine stream of
              NONE => entries
            | SOME line =>
              case String.tokens Char.isSpace line of
                [key, value] => loop ((key, value) :: entries)
              | _ =>
                raise Fail ("syntax error in pathmap:" ^ line)
                      before TextIO.closeIn stream
      in
        loop [] before TextIO.closeIn stream
      end

  local
    fun implodeRev chars = String.implode (List.rev chars)
  in
  fun expand pathMap path =
      let
        fun expandPathVars (path, seen) =
            let
              fun loop (s, acc, accs) =
                  case s of
                    [] => String.concat (List.rev (implodeRev acc :: accs))
                  | #"$" :: #"(" :: s => 
                    let
                      val accs = implodeRev acc :: accs
                      fun loopVar (s, acc) =
                          case s of
                            [] => raise Fail "syntax error"
                          | #")" :: s => (s, implodeRev acc)
                          | c :: s => loopVar (s, c :: acc)
                      val (s, var) = loopVar (s, [])
                    in
                      if List.exists (fn x => x = var) seen
                      then
                        raise Fail ("Cyclic MLB path variables" ^ var)
                      else
                        case List.find (fn (key, _) => key = var) pathMap of
                          NONE =>
                          raise Fail ("Undefined path variable: " ^ var)
                        | SOME (_, path) => 
                          loop
                              (s, [], expandPathVars (path, var :: seen) :: accs)
                    end
                  | c :: s => loop (s, c :: acc, accs)
            in
              loop (String.explode path, [], [])
            end
      in
        expandPathVars (path, [])
      end
  end

end