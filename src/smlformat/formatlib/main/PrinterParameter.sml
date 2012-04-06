(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
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

  val defaultNewline = "\n"
  val defaultSpace = " "
  val defaultColumns = 80
  val defaultGuardLeft = "("
  val defaultGuardRight = ")"
  val defaultMaxDepthOfGuards = NONE
  val defaultMaxWidthOfGuards = NONE
  val defaultCutOverTail = false

  type parameterRecord =
       {
         newlineString : string,
         spaceString : string,
         columns : int,
         guardLeft : string,
         guardRight : string,
         maxDepthOfGuards : int option,
         maxWidthOfGuards : int option,
         cutOverTail : bool
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

        val (columns, spaceString, newlineString, cutOverTail) =
            List.foldl
                (fn (param, (cols, space, newline, cuttail)) =>
                    case param
                     of Newline s => (cols, space, s, cuttail)
                      | Space s => (cols, s, newline, cuttail)
                      | Columns n => (n, space, newline, cuttail)
                      | CutOverTail b => (cols, space, newline, b)
                      | _ => (cols, space, newline, cuttail))
                (
                  defaultColumns,
                  defaultSpace,
                  defaultNewline,
                  defaultCutOverTail
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
          cutOverTail = cutOverTail
        }
      end

  (***************************************************************************)

end