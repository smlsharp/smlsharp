(**
 * implementation of primitives which access garbage collector.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: GCPrimitives.sml,v 1.2 2007/03/03 01:40:27 kiyoshiy Exp $
 *)
structure GCPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun GC_addFinalizable VM heap [Pointer _] = [Int 0]
    | GC_addFinalizable _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "GC_addFinalizable"

  fun GC_doGC VM heap [Int mode] = [SLD.unitToValue heap ()]
    | GC_doGC _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "GC_doGC"

  fun GC_fixedCopy VM heap [Pointer block] = [H.getField heap (block, 0w0)]
    | GC_fixedCopy _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "GC_fixedCopy"

  fun GC_releaseFLOB VM heap [Pointer _] = [SLD.unitToValue heap ()]
    | GC_releaseFLOB _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "GC_releaseFLOB"

  fun GC_addressOfFLOB VM heap [Pointer _] = [SLD.unitToValue heap ()]
    | GC_addressOfFLOB _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "GC_addressOfFLOB"

  val primitives =
      [
        {name = "GC_addFinalizable", function = GC_addFinalizable},
        {name = "GC_doGC", function = GC_doGC},
        {name = "GC_fixedCopy", function = GC_fixedCopy},
        {name = "GC_releaseFLOB", function = GC_releaseFLOB},
        {name = "GC_addressOfFLOB", function = GC_addressOfFLOB}
      ]

  (***************************************************************************)

end;
