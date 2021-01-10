val fopen = _import "fopen" : (string, string) -> unit ptr
val fread = _import "fread" : (char array, word64, word64, unit ptr) -> word64
val fclose = _import "fclose" : unit ptr -> int
type instream = unit ptr * CharArray.array

fun openIn filename =
    let
      val fp = fopen (filename, "rb")
      val buf = CharArray.array (4096, #"\000")
    in
      (fp, buf)
    end

fun input (fp, buf) =
    let
      val n = fread (buf, 0w1, 0w4096, fp)
      val s = CharArraySlice.slice (buf, 0, SOME (Word64.toIntX n))
    in
      CharArraySlice.vector s
    end

fun closeIn (fp, buf) =
    ignore (fclose fp)
