(* sysinfo.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Get information about the underlying hardware and OS.
 *
 *)

signature SYS_INFO =
  sig

    exception UNKNOWN
	(* this exception is raised when the runtime cannot provide the
	 * requested information.
	 *)

    datatype os_kind
      = UNIX	(* one of the many flavours of UNIX (incl Mach and NeXTStep) *)
      | WIN32	(* Wind32 API (incl. Windows95 and WindowsNT) *)
      | MACOS	(* Macintosh OS (> 7.5) *)
      | OS2	(* IBM's OS/2 *)
      | BEOS	(* BeOS from Be *)

    val getOSKind    : unit -> os_kind
    val getOSName    : unit -> string
    val getOSVersion : unit -> string

    val getHostArch   : unit -> string
	(* returns the HOST_ARCH value from the run-time build *)
    val getTargetArch : unit -> string
	(* returns the TARGET_ARCH value from the run-time build; this is
	 * usually the same as the host architecture, except in the case that
	 * some form of emulation is being run (e.g., ML-to-C, or an
	 * interpreter).
	 *)

    val hasSoftwarePolling : unit -> bool
	(* returns true, if the run-time system was compiled to support software
	 * polling.
	 *)

    val hasMultiprocessing : unit -> bool
	(* returns true, if the run-time system was compiled to support the
	 * multiprocessing hooks.  This does not mean that the underlying
	 * hardware is a multiprocessor.
	 *)

    val getHeapSuffix : unit -> string

  end
