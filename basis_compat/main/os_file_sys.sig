signature OS_FILE_SYS =
  sig
    type dirstream
    val openDir : string -> dirstream
    val readDir : dirstream -> string
    val rewindDir : dirstream -> unit
    val closeDir : dirstream -> unit
    val chDir : string -> unit
    val getDir : unit -> string
    val mkDir : string -> unit
    val rmDir : string -> unit
    val isDir : string -> bool
    val isLink : string -> bool
    val readLink : string -> string
    val fullPath : string -> string
    val realPath : string -> string
    val fileSize : string -> Position.int
    val modTime : string -> Time.time
    val setTime : string * Time.time option -> unit
    val remove : string -> unit
    val rename : {new:string, old:string} -> unit
    datatype access_mode = A_EXEC | A_READ | A_WRITE
    val access : string * access_mode list -> bool
    val tmpName : unit -> string
    eqtype file_id
    val fileId : string -> file_id
    val hash : file_id -> word
    val compare : file_id * file_id -> order
  end
