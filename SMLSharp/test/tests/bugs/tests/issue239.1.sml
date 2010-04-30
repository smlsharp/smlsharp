(* OK *)
val x = 0w0 : byte;

(* OK *)
fun getbyte x = (0w0 : byte);

(* NG *)
fun getbyte (0w0 : byte) = ();
