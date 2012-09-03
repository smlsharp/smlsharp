(**
 * implementation of primitives on time values.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TimerPrimitives.sml,v 1.7 2007/09/20 09:02:54 matsu Exp $
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
	  fun checkCPUTimer2 tr =  (*fn tr =>*)
	      let val {gc, nongc={sys, usr}} = Timer.checkCPUTimes tr
		  val {sys=gcsys, usr=gcusr} = gc
		  val gc = Time.+ (gcsys, gcusr)
	      in {sys = sys, usr = usr, gc = gc}
	      end
          val {usr, sys, gc} = checkCPUTimer2 timer
          val block =
              H.allocateBlock
                  heap {size = 0w6, bitmap = 0w0, blockType = RecordBlock}
          val (usrSec, usrMicroSec) = decomposeTime usr
          val (sysSec, sysMicroSec) = decomposeTime sys
          val (GCSec, GCMicroSec) = decomposeTime gc
          val values =
            [
              Int (SInt32.fromLarge usrSec), Int (SInt32.fromLarge usrMicroSec),
              Int (SInt32.fromLarge sysSec), Int (SInt32.fromLarge sysMicroSec),
              Int (SInt32.fromLarge GCSec), Int (SInt32.fromLarge GCMicroSec)
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
