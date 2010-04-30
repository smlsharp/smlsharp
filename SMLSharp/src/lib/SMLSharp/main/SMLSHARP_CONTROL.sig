(**
 * functions to control SML#.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_CONTROL.sig,v 1.1 2007/06/01 01:26:03 kiyoshiy Exp $
 *)
signature SMLSHARP_CONTROL =
sig

  (**
   * This module define parameters to control the formatter which prints
   * binding information of global declarations.
   *)
  structure Printer
            : sig
                (** specify the maximum number of nests of data structures
                 * which the formatter prints. *)
                val setMaxDepth : int option -> unit
                val getMaxDepth : unit -> int option
                (** specify the maximum number of elements of each nodes in
                 * data structures which the formatter prints. *)
                val setMaxWidth : int option -> unit
                val getMaxWidth : unit -> int option
                (** specify the number of columns. *)
                val setColumns : int -> unit
                val getColumns : unit -> int
                (** specify the maximum number of nests of 'ref' constructors
                 * which the formatter prints. *)
                val setMaxRefDepth : int -> unit
                val getMaxRefDepth : unit -> int
              end

end;
