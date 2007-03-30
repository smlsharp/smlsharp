(* win32-process.sml
 *
 * COPYRIGHT (c) 1996 Bell Laboratories.
 *
 * Hooks to Win32 Process functions.
 *
 *)

structure Win32_Process : WIN32_PROCESS = 
    struct
	structure W32G = Win32_General

	fun cf name = W32G.cfun "WIN32-PROCESS" name

	val system' : string -> W32G.word = cf "system"

	fun exitProcess (w: W32G.word) : 'a = cf "exit_process" w

	val getEnvironmentVariable' : string -> string option = 
	    cf "get_environment_variable"
    end

