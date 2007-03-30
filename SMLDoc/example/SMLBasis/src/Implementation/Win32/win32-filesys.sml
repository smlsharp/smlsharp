(* win32-filesys.sml
 *
 * COPYRIGHT (c) 1996 Bell Laboratories.
 *
 * Hooks to Win32 file system.
 *
 *)

structure Win32_FileSys : WIN32_FILESYS = 
    struct
	structure W32G = Win32_General
	type hndl = W32G.hndl

	type word = W32G.word

	fun hndlToIOD h = OS.IO.IODesc (ref h)
	fun IODToHndl (OS.IO.IODesc (ref h)) = h

	fun rebindIOD (OS.IO.IODesc hr,h) = hr := h

	fun cf name = W32G.cfun "WIN32-FILESYS" name

	val findFirstFile : string -> (hndl * string option) = 
	    cf "find_first_file"
	val findNextFile : hndl -> string option = cf "find_next_file"
	val findClose : hndl -> bool = cf "find_close"

	val setCurrentDirectory : string -> bool = cf "set_current_directory"
	val getCurrentDirectory' : unit -> string = cf "get_current_directory"
	val createDirectory' : string -> bool = cf "create_directory"
	val removeDirectory : string -> bool = cf "remove_directory"

	val cc = W32G.getConst "FILE_ATTRIBUTE"

	val FILE_ATTRIBUTE_ARCHIVE : word = cc "ARCHIVE"
	val FILE_ATTRIBUTE_DIRECTORY : word = cc "DIRECTORY"
	val FILE_ATTRIBUTE_HIDDEN : word = cc "HIDDEN"
	val FILE_ATTRIBUTE_NORMAL : word = cc "NORMAL"
	val FILE_ATTRIBUTE_READONLY : word = cc "READONLY"
	val FILE_ATTRIBUTE_SYSTEM : word = cc "SYSTEM"
	val FILE_ATTRIBUTE_TEMPORARY : word = cc "TEMPORARY"
    (** future win32 use
	val FILE_ATTRIBUTE_ATOMIC_WRITE : word = cc "ATOMIC_WRITE"
	val FILE_ATTRIBUTE_XACTION_WRITE : word = cc "XACTION_WRITE"
    **)

	val getFileAttributes : string -> word option = 
	    cf "get_file_attributes"
	val getFileAttributes' : hndl -> word option =
	    cf "get_file_attributes_by_handle"

	fun isRegularFile h =  (* assumes attributes accessible *)
	    let val SOME a = getFileAttributes' h
	    in  W32G.Word.andb(FILE_ATTRIBUTE_DIRECTORY,a) = 0wx0
	    end

	val getFullPathName' : string -> string = cf "get_full_path_name"

	val getFileSize : hndl -> (word * word) = cf "get_file_size"
	val getLowFileSize : hndl -> word option = cf "get_low_file_size"
	val getLowFileSizeByName : string -> word option = 
	    cf "get_low_file_size_by_name"

	(* year, month, day-o-week, day, hour, minute, second, millisecs *)
	type time_rec = (int * int * int * int * int * int * int * int)

	fun trToSt (y,mon,dow,d,h,min,s,ms) : W32G.system_time = 
	    {year=y,month=mon,dayOfWeek=dow,day=d,hour=h,
	     minute=min,second=s,milliSeconds=ms}

	fun stToTr {year,month,dayOfWeek,day,
		    hour,minute,second,milliSeconds} : time_rec = 
	    (year,month,dayOfWeek,day,hour,minute,second,milliSeconds)

	val getFileTime : string -> time_rec option = cf "get_file_time"
	val getFileTime' = Option.map trToSt o getFileTime

	val setFileTime : (string * time_rec) -> bool =  cf "set_file_time"
	fun setFileTime' (name,sysTime) = setFileTime(name,stToTr sysTime)

	val deleteFile : string -> bool = cf "delete_file"
	val moveFile : (string * string) -> bool = cf "move_file"

	val getTempFileName' : unit -> string option = cf "get_temp_file_name"
    end

