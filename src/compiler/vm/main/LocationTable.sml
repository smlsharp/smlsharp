(**
 * @copyright (c) 2006, Tohoku University.
 *)
local

  open RuntimeTypes
  open BasicTypes
  structure C = Counter
  structure E = Executable
  structure ES = ExecutableSerializer
  structure H = Heap
  structure I = Instructions
  structure P = Primitives
  structure RC = RuntimeCounters
  structure RE = RuntimeErrors
  structure RM = RawMemory
  structure SU = SignalUtility
  structure U = Utility
in
(**
 * This module manipulates the runtime table of source code locations.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: LocationTable.sml,v 1.11 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure LocationTable
          : sig

             val getCodeRefOfSourceLine
                 : executable list
                   -> ((** fileName *) string * (** line number *) UInt32)
                   -> (** code reference *) codeRef option

             val getLocationOfCodeRef
                 : codeRef -> Loc.loc option
          end =
struct

  (***************************************************************************)

  local
    (**
     * entries are sorted in the ascending order of location.
     *)
    structure EntrySet =
    BinarySetFn
        (struct
           type ord_key = executable * E.locationTableEntry
           fun compare ((_, left) : ord_key, (_, right) : ord_key) =
               case UInt32.compare (#leftLine left, #leftLine right) of
                 EQUAL =>
                 (case UInt32.compare (#leftCol left, #leftCol right) of
                    EQUAL =>
                    (case UInt32.compare (#rightLine left, #rightLine right) of
                       EQUAL =>
                       UInt32.compare (#rightCol left, #rightCol right)
                     | order => order)
                  | order => order)
               | order => order
         end)

    fun sortLocationsInLineNo locations =
        EntrySet.listItems (EntrySet.addList (EntrySet.empty, locations))

    fun getIndexOfFileName fileName (executable : executable) =
        let
          val fileNames =
              E.getFileNamesOfLocationTable (#locationTable executable)
          fun scan index [] = NONE
            | scan index (name :: names) =
              if name = fileName then SOME index else scan (index + 0w1) names
        in
          scan (0w0 : UInt32) fileNames
        end

    fun getLocationsOfFile fileName (executable : executable) =
        case getIndexOfFileName fileName executable of
          NONE => []
        | SOME fileNameIndex =>
          let
            val {locationTable = {locations, ...}, ...} = executable
            (* Only entries of the specified fileNameIndex are necessary. *)
            val filteredLocations =
                List.filter
                    (fn entry => fileNameIndex = #fileNameIndex entry)
                    locations
          in map (fn location => (executable, location)) filteredLocations end
  in

  fun getCodeRefOfSourceLine executables (fileName, lineNo) =
      let
        val locations =
            List.concat(map (getLocationsOfFile fileName) executables)
        (* sort in the ascending order in line number *)
        val sortedLocations = sortLocationsInLineNo locations
(*
val _ = print ("lineNo = " ^ UInt32.toString lineNo ^ "\n")
val _ = print ("original = " ^ Int.toString (length locations) ^ "\n")
val _ = app (fn (_, entry) => print ("leftLineNo = " ^ UInt32.toString (#leftLine entry) ^ "\n")) locations
val _ = print ("sorted = " ^ Int.toString (length sortedLocations) ^ "\n")
val _ = app (fn (_, entry) => print ("leftLineNo = " ^ UInt32.toString (#leftLine entry) ^ "\n")) sortedLocations
*)
        val entryOpt =
            List.find
                (fn (_, entry) => lineNo <= #leftLine entry)
                sortedLocations
      in
        case entryOpt of
          NONE => NONE
        | SOME(executable, {offset, ...} : E.locationTableEntry) =>
          SOME ({executable = executable, offset = offset} : codeRef)
      end
  end

  fun getLocationOfCodeRef
          {executable = {locationTable, ...} : executable, offset}=
      let
        val {locations, fileNames, ...} : E.locationTable = locationTable
        fun  find prev [] = prev : E.locationTableEntry option
           | find prev (next :: remains) =
             if offset < #offset next then prev else find (SOME next) remains
        val entry = find NONE locations
      in
        case entry of
          NONE => NONE
        | SOME{fileNameIndex, leftLine, leftCol, rightLine, rightCol, ...} =>
          let
(*
              val _ = TextIO.print ("fileNameIndex = " ^ UInt32.toString fileNameIndex ^ ", # of fileNames = " ^ Int.toString (List.length fileNames) ^ "\n")
              val _ = TextIO.print ("leftLine = " ^ UInt32.toString leftLine ^ ", leftCol = " ^ UInt32.toString leftCol ^ "\n")
*)
            val fileName =
                U.deserializeString
                    (List.nth (fileNames, UInt32.toInt fileNameIndex))
            fun makePos (line, col) =
                Loc.makePos
                    {
                      fileName = fileName,
                      line = UInt32.toInt line,
                      col = UInt32.toInt col
                    }
          in
            SOME (makePos (leftLine, leftCol), makePos(rightLine, rightCol))
          end
      end

  (***************************************************************************)

end (* structure *)

end (* local *)
