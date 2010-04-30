(* win32-filesys.sig
 *
 * COPYRIGHT (c) 1996 Bell Laboratories.
 *
 * Signature for hooks to Win32 file system.
 *
 *)

signature WIN32_FILESYS = 
    sig
	type hndl = Win32_General.hndl

	val hndlToIOD : hndl -> OS.IO.iodesc
	val IODToHndl : OS.IO.iodesc -> hndl
	val rebindIOD : (OS.IO.iodesc * hndl) -> unit

	val findFirstFile : string -> (hndl * string option)
	val findNextFile : hndl -> (string option)
	val findClose : hndl -> bool

	val setCurrentDirectory : string -> bool
	val getCurrentDirectory' : unit -> string
	val createDirectory' : string -> bool
	val removeDirectory : string -> bool

	val FILE_ATTRIBUTE_ARCHIVE : Win32_General.word
	val FILE_ATTRIBUTE_DIRECTORY : Win32_General.word
	val FILE_ATTRIBUTE_HIDDEN : Win32_General.word
	val FILE_ATTRIBUTE_NORMAL : Win32_General.word
	val FILE_ATTRIBUTE_READONLY : Win32_General.word
	val FILE_ATTRIBUTE_SYSTEM : Win32_General.word
	val FILE_ATTRIBUTE_TEMPORARY : Win32_General.word
   (** future win32 use
	val FILE_ATTRIBUTE_ATOMIC_WRITE : Win32_General.word
	val FILE_ATTRIBUTE_XACTION_WRITE : Win32_General.word
   **)

	val getFileAttributes : string -> Win32_General.word option
	val getFileAttributes' : hndl -> Win32_General.word option

	val isRegularFile : hndl -> bool

	val getFullPathName' : string -> string

	val getFileSize : hndl -> (Win32_General.word * Win32_General.word)
	val getLowFileSize : hndl -> Win32_General.word option
	val getLowFileSizeByName : string -> Win32_General.word option 

	val getFileTime' : string -> Win32_General.system_time option
	val setFileTime' : (string * Win32_General.system_time) -> bool

	val deleteFile : string -> bool
	val moveFile : (string * string) -> bool

	val getTempFileName' : unit -> string option
    end

