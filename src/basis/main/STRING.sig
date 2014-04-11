signature STRING =
sig
  eqtype string
  eqtype char
  val maxSize : int
  val size : string -> int
  val explode : string -> char list
  val concatWith : string -> string list -> string
  val isPrefix : string -> string -> bool
  val isSuffix : string -> string -> bool
  val isSubstring : string -> string -> bool
  val translate : (char -> string) -> string -> string

  val sub : string * int -> char
  val extract : string * int * int option -> string
  val substring : string * int * int -> string
  val ^ : string * string -> string
  val concat : string list -> string
  val str : char -> string
  val implode : char list -> string
  val map : (char -> char) -> string -> string
  val tokens : (char -> bool) -> string -> string list
  val fields : (char -> bool) -> string -> string list
  val compare : string * string -> order
  val collate : (char * char -> order) -> string * string -> order
  val < : string * string -> bool
  val <= : string * string -> bool
  val > : string * string -> bool
  val >= : string * string -> bool
  val toString : string -> string
  val scan : (char, 'a) StringCvt.reader -> (string, 'a) StringCvt.reader
  val fromString : string -> string option
  val toCString : string -> string
  val fromCString : string -> string option
end
