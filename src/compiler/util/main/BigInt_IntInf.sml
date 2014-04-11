structure BigInt :
          sig
            include INTEGER
            (**
             * converts an integer to its string representation which is
             * valid as an integer literal in C language.
             *)
            val toCString : int -> string
          end =
struct
  open IntInf
  fun toCString n =
      let val str = toString (abs n)
      in if n < 0 then "-" ^ str else str end
end
