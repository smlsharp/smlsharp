(* os-filesys.sml
 *
 * COPYRIGHT (c) 1996 Bell Laboratories.
 *
 * Win32 implementation of the OS.FileSys structure
 *
 *)

local
    structure String = StringImp
    structure Time = TimeImp
    structure Word = WordImp
in
structure OS_FileSys : OS_FILE_SYS = 
    struct
	structure OSPath = OS_Path
	structure W32G = Win32_General
	structure W32FS = Win32_FileSys
	structure S = String
	structure C = Char
	val not = Bool.not

	exception SysErr = Assembly.SysErr

	datatype dirstream = DS of {
				 hndlptr : W32G.hndl ref,
				 query : string,
				 isOpen : bool ref,
				 nextFile : string option ref
				 }

	fun rse name msg = raise SysErr(String.concat[name, ": ", msg], NONE)

	fun isDir s = 
	    case W32FS.getFileAttributes s of
		NONE => 
		    rse "isDir" "cannot get file attributes"
	      | SOME a => 
		    W32G.Word.andb(W32FS.FILE_ATTRIBUTE_DIRECTORY,a) <> 0wx0
	    
	fun openDir s = 
	    let fun rse' s = rse "openDir" s
		val _ = not (isDir s) andalso rse' "invalid directory"
		fun mkValidDir s = 
		    if (S.sub(s,S.size s - 1) <> W32G.arcSepChar) then 
			s^(S.str W32G.arcSepChar)
		    else s
		val p = (mkValidDir s)^"*"
		val (h,firstName) = W32FS.findFirstFile p
	    in
		if not (W32G.isValidHandle h) then 
		    rse' "cannot find first file"
		else
		    DS{hndlptr=ref h,query=p,
		       isOpen=ref true,nextFile=ref firstName}
	    end

	fun readDir (DS{isOpen=ref false,...}) = 
	    rse "readDir" "stream not open"
	  | readDir (DS{nextFile=ref NONE,...}) = NONE
	  | readDir (DS{hndlptr,nextFile=nF as ref (SOME name),...}) =
	    (nF := W32FS.findNextFile (!hndlptr);
	     case name of
		 "" => NONE
	       | _ => SOME name)
	val readDir = (* OSPath.mkCanonical o *) readDir

	fun closeDir (DS{isOpen=ref false,...}) = ()
	  | closeDir (DS{hndlptr,isOpen,...}) = 
	      (isOpen := false;
	       if W32FS.findClose (!hndlptr) then ()
	       else 
		   rse "closeDir" "win32: unexpected closeDir failure")

	fun rewindDir (DS{isOpen=ref false,...}) = 
	    rse "rewindDir" "rewinddir on closed directory stream"
	  | rewindDir (d as DS{hndlptr,query,isOpen,nextFile}) = 
	    let val _ = closeDir d
		val (h,firstName) = W32FS.findFirstFile query
	    in
		if not (W32G.isValidHandle h) then 
		    rse "rewindDir" "cannot rewind to first file"
		else
		    (hndlptr := h;
		     nextFile := firstName;
		     isOpen := true)
	    end

	fun chDir s = 
	    if W32FS.setCurrentDirectory s then ()
	    else rse "chDir" "cannot change directory"

	val getDir = OSPath.mkCanonical o W32FS.getCurrentDirectory'
	  
	fun mkDir s = 
	    if W32FS.createDirectory' s then ()
	    else rse "mkDir" "cannot create directory"

	fun rmDir s = 
	    if W32FS.removeDirectory s then ()
	    else rse "rmDir" "cannot remove directory"
	    
	fun isLink _ = false
	fun readLink _ = rse "readLink" "OS does not have links"

	fun exists s = W32FS.getFileAttributes s <> NONE 

	fun fullPath "" = getDir ()
	  | fullPath s = 
	    if exists s then W32FS.getFullPathName' s
	    else raise SysErr("fullPath: cannot generate full path",NONE)
	val fullPath = OSPath.mkCanonical o fullPath

	fun realPath p = 
	    if OSPath.isAbsolute p then fullPath p
	    else OSPath.mkRelative {path=fullPath p, relativeTo=fullPath (getDir())}

	fun fileSize s = 
	    case W32FS.getLowFileSizeByName s of
		SOME w => W32G.Word.toInt w
	      | NONE => rse "fileSize" "cannot get size"
	    
	fun intToMonth 1 = Date.Jan
	  | intToMonth 2 = Date.Feb
	  | intToMonth 3 = Date.Mar
	  | intToMonth 4 = Date.Apr
	  | intToMonth 5 = Date.May
	  | intToMonth 6 = Date.Jun
	  | intToMonth 7 = Date.Jul
	  | intToMonth 8 = Date.Aug
	  | intToMonth 9 = Date.Sep
	  | intToMonth 10 = Date.Oct
	  | intToMonth 11 = Date.Nov
	  | intToMonth 12 = Date.Dec

	fun monthToInt Date.Jan = 1
	  | monthToInt Date.Feb = 2
	  | monthToInt Date.Mar = 3
	  | monthToInt Date.Apr = 4
	  | monthToInt Date.May = 5
	  | monthToInt Date.Jun = 6
	  | monthToInt Date.Jul = 7
	  | monthToInt Date.Aug = 8
	  | monthToInt Date.Sep = 9
	  | monthToInt  Date.Oct = 10
	  | monthToInt  Date.Nov = 11
	  | monthToInt  Date.Dec = 12

	fun intToWeekDay 0 = Date.Sun
	  | intToWeekDay 1 = Date.Mon
	  | intToWeekDay 2 = Date.Tue
	  | intToWeekDay 3 = Date.Wed
	  | intToWeekDay 4 = Date.Thu
	  | intToWeekDay 5 = Date.Fri
	  | intToWeekDay 6 = Date.Sat

	fun weekDayToInt Date.Sun = 0
	  | weekDayToInt Date.Mon = 1
	  | weekDayToInt Date.Tue = 2
	  | weekDayToInt Date.Wed = 3
	  | weekDayToInt Date.Thu = 4
	  | weekDayToInt Date.Fri = 5
	  | weekDayToInt Date.Sat = 6

	fun modTime s = (case W32FS.getFileTime' s
	       of (SOME info) =>
		    Date.toTime(Date.date{
			year = #year info,
			month = intToMonth(#month info),
			day = #day info,
			hour = #hour info,
			minute = #minute info,
			second = #second info,
			offset = NONE
		      })
		| NONE => rse "modTime" "cannot get file time"
	      (* end case *))

	fun setTime (s,t) = let
	      val date = Date.fromTimeLocal(case t of NONE => Time.now() | SOME t' => t')
	      val date' = {
		      year = Date.year date,
		      month = monthToInt(Date.month date),
		      dayOfWeek = weekDayToInt(Date.weekDay date),
		      day = Date.day date,
		      hour = Date.hour date,
		      minute = Date.minute date,
		      second = Date.second date,
		      milliSeconds = 0
		    }
	      in
		if W32FS.setFileTime' (s, date')
		  then ()
		  else rse "setTime" "cannot set time"
	      end

	fun remove s = 
	     if W32FS.deleteFile s then ()
	     else rse "remove" "cannot remove file"

	fun rename {old: string,new: string} = 
	    let fun rse' s = rse "rename" s
		val _ = not (exists old) andalso 
		        rse' ("cannot find old='" ^ old ^ "'")
                val same = (exists new) andalso 
		           (fullPath old = fullPath new)
            in
		if not same then 
		    (if (exists new) then
			 remove new
			   handle _ => rse' "cannot remove 'new'"
		     else ();
		     if W32FS.moveFile(old,new) then ()
		     else rse' "moveFile failed")
		else ()
	    end
		 
	datatype access_mode = A_READ | A_WRITE | A_EXEC

	val strUpper = 
	    S.translate (fn c => S.str (if C.isAlpha c then C.toUpper c else c))

	fun access (s,[]) = exists s
	  | access (s,al) = 
	    case W32FS.getFileAttributes s of
		NONE => 
		    rse "access" "cannot get file attributes"
	      | SOME aw => 
		    let fun aux A_READ = true
			  | aux A_WRITE =
			    W32G.Word.andb(W32FS.FILE_ATTRIBUTE_READONLY,aw) = 0w0
			  | aux A_EXEC = 
			    (case #ext(OS_Path.splitBaseExt s) of
				SOME ext => (case (strUpper ext) of
						 ("EXE" | "COM" | 
						  "CMD" | "BAT" ) => true
						| _ => false)
			      | NONE => false)
		    in List.all aux al
		    end

	fun tmpName () =
	    case W32FS.getTempFileName' () of
		NONE => rse "tmpName" "cannot obtain tmp filename"
	      | SOME s => s

	type file_id = string

	fun fileId s = 
	    fullPath s
	        handle (SysErr _) =>
		    rse "fileId" "cannot create file id"

	fun hash (fid : file_id) = 
	    Word.fromInt
	        (List.foldl (fn (a,b) => (Char.ord a + b) handle _ => 0) 0
		            (String.explode fid))

	val compare = String.compare
    end
end

