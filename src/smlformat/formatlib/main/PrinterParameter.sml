(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 * @version $Id: PrinterParameter.sml,v 1.4 2007/06/18 13:30:43 kiyoshiy Exp $
 *)
structure PrinterParameter =
struct

  (***************************************************************************)

  datatype parameter =
           Newline of string
         | Space of string
         | Columns of int
         | GuardLeft of string
         | GuardRight of string
         | MaxDepthOfGuards of int option
         | MaxWidthOfGuards of int option
         | CutOverTail of bool
         | OutputFunction of string -> unit

  val defaultNewline = "\n"
  val defaultSpace = " "

  val defaultColumns = 80
  val defaultGuardLeft = "("
  val defaultGuardRight = ")"
  val defaultMaxDepthOfGuards = NONE
  val defaultMaxWidthOfGuards = NONE
  val defaultCutOverTail = false
  val defaultOutputFunction = NONE

  type parameterRecord =
       {
         newlineString : string,
         spaceString : string,
         columns : int,
         guardLeft : string,
         guardRight : string,
         maxDepthOfGuards : int option,
         maxWidthOfGuards : int option,
         cutOverTail : bool,
         outputFunction : (string -> unit) option
       }

  (***************************************************************************)

  fun convert parameterList =
      let
        val (
              spaceString,
              guardLeft,
              guardRight,
              maxDepthOfGuards,
              maxWidthOfGuards
            ) =
            List.foldl
                (fn (param, (space, left, right, depth, width)) =>
                  case param
                   of Space s => (s, left, right, depth, width)
                    | GuardLeft s => (space, s, right, depth, width)
                    | GuardRight s => (space, left, s, depth, width)
                    | MaxDepthOfGuards no =>
                      (space, left, right, no, width)
                    | MaxWidthOfGuards no =>
                      (space, left, right, depth, no)
                    | _ => (space, left, right, depth, width))
                (
                  defaultSpace,
                  defaultGuardLeft,
                  defaultGuardRight,
                  defaultMaxDepthOfGuards,
                  defaultMaxWidthOfGuards
                )
                parameterList

        val (columns, spaceString, newlineString, cutOverTail, outputFunction) =
            List.foldl
                (fn (param, (cols, space, newline, cuttail, outputFn)) =>
                    case param
                     of Newline s => (cols, space, s, cuttail, outputFn)
                      | Space s => (cols, s, newline, cuttail, outputFn)
                      | Columns n => (n, space, newline, cuttail, outputFn)
                      | CutOverTail b => (cols, space, newline, b, outputFn)
                      | OutputFunction f =>
                        (cols, space, newline, cuttail, SOME f)
                      | _ => (cols, space, newline, cuttail, outputFn))
                (
                  defaultColumns,
                  defaultSpace,
                  defaultNewline,
                  defaultCutOverTail,
                  defaultOutputFunction
                )
                parameterList
      in
        {
          newlineString = newlineString,
          spaceString = spaceString,
          columns = columns,
          guardLeft = guardLeft,
          guardRight = guardRight,
          maxDepthOfGuards = maxDepthOfGuards,
          maxWidthOfGuards = maxWidthOfGuards,
          cutOverTail = cutOverTail,
          outputFunction = outputFunction
        }
      end

  (***************************************************************************)

end
