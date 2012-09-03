(**
 * implementation of primitives on time values.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TimerPrimitives.sml,v 1.5 2006/02/28 16:11:13 kiyoshiy Exp $
 *)
structure TimerPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  val timer = Timer.startCPUTimer ()
  fun decomposeTime time =
      let
        val seconds = Time.toSeconds time
        val microSeconds = LargeInt.rem(Time.toMicroseconds time, 1000000)
      in
        (seconds, microSeconds)
      end
        handle General.Overflow => (0, 0)

  fun Timer_getTime VM heap [dummy] =
      let
        val {usr, sys, gc} = Timer.checkCPUTimer timer
        val block =
            H.allocateBlock
                heap {size = 0w6, bitmap = 0w0, blockType = RecordBlock}
        val (usrSec, usrMicroSec) = decomposeTime usr
        val (sysSec, sysMicroSec) = decomposeTime sys
        val (GCSec, GCMicroSec) = decomposeTime gc
        val values =
            [
              Int usrSec, Int usrMicroSec,
              Int sysSec, Int sysMicroSec,
              Int GCSec, Int GCMicroSec
            ]
      in
        H.setFields heap (block, 0w0, values);
        [Pointer block]
      end
    | Timer_getTime _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Timer_getTime"

  val primitives =
      [
        {name = "Timer_getTime", function = Timer_getTime}
      ]

  (***************************************************************************)

end;
