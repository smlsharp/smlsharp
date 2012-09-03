include "StringCvt.smi"

signature BOOL =
sig
  datatype bool = false | true
  val not : bool -> bool
  val toString : bool -> string
  val scan : (char, 'a) StringCvt.reader -> (bool, 'a) StringCvt.reader
  val fromString : string -> bool option
end
