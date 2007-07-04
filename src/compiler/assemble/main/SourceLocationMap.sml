(**
 * a map from the offset of an instruction to the location in the source code.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SourceLocationMap.sml,v 1.8 2007/06/20 06:50:41 kiyoshiy Exp $
 *)
structure SourceLocationMap : SOURCE_LOCATION_MAP =
struct

  (***************************************************************************)

  structure A = Absyn
  structure BT = BasicTypes

  (***************************************************************************)

  type offset = BT.UInt32

  type fileName = string

  type fileIndex = int

  type entry = offset * Loc.loc * fileIndex

  (* Internally, entries are maintained in descending order of offset. *)
  type map = entry list * fileIndex SEnv.map

  (***************************************************************************)

  val empty = ([], SEnv.empty) : map

  fun fileNameOfLoc (loc : Loc.loc) = Loc.fileNameOfPos (#1 loc)
  fun isSameLoc (loc1 : Loc.loc, loc2) = loc1 = loc2

  fun append (map, offset, loc) =
      if isSameLoc(loc, Loc.noloc)
      then map (* unchanged *)
      else
        case map of 
          ([], fileNameMap) =>
          if 0 = SEnv.numItems fileNameMap
          then
            let
              val fileIndex = 0
              val entries = [(offset, loc, fileIndex)]
              val newFileNameMap =
                  SEnv.insert (SEnv.empty, fileNameOfLoc loc, fileIndex)
            in
              (entries, newFileNameMap)
            end
          else raise Control.Bug "fileNames is not empty."

        | (entries as (lastOffset, lastLoc, _) :: _, fileNameMap) =>
          if offset < lastOffset
          then
            (* entries must be aligned in descending order of offset. *)
            raise
              Control.Bug
                  ("SourceLocationMap.append: \
                   \offset(" ^ BT.UInt32.toString offset ^
                   " <= lastOffset(" ^ BT.UInt32.toString lastOffset ^ ")")
          else 
            if isSameLoc (lastLoc, loc)
            then map (* unchanged *)
            else
              let
                val fileName = fileNameOfLoc loc
                val (newFileNameMap, fileIndex) =
                    case SEnv.find (fileNameMap, fileName) of
                      SOME(fileIndex) => (fileNameMap, fileIndex)
                    | NONE =>
                      let
                        val fileIndex = SEnv.numItems fileNameMap
                        val newFileNameMap =
                            SEnv.insert(fileNameMap, fileName, fileIndex)
                      in (newFileNameMap, fileIndex)
                      end
              in
                ((offset, loc, fileIndex) :: entries, newFileNameMap)
              end

  fun getAll (map, fileNameMap) =
      let
        fun toLocationTableEntry (offset, loc : Loc.loc, fileIndex) =
            {
              offset = offset,
              fileNameIndex = BT.UInt32.fromInt fileIndex,
              leftLine = BT.UInt32.fromInt (Loc.lineOfPos (#1 loc)),
              leftCol = BT.UInt32.fromInt (Loc.colOfPos (#1 loc)),
              rightLine = BT.UInt32.fromInt (Loc.lineOfPos (#2 loc)),
              rightCol = BT.UInt32.fromInt (Loc.colOfPos (#2 loc))
            } : Executable.locationTableEntry
        val locationTableEntries = List.map toLocationTableEntry (List.rev map)
        val sortedFileNameMap =
            SEnv.foldli
                (fn (fileName, index, orderedMap) =>
                    IEnv.insert (orderedMap, index, fileName))
                IEnv.empty
                fileNameMap
        val fileNames = IEnv.listItems sortedFileNameMap
      in
        (locationTableEntries, fileNames)
      end

  (***************************************************************************)

end
