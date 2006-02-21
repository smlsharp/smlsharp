(**
 * Copyright (c) 2006, Tohoku University.
 *)
structure SystemDefTypes =
struct

  datatype byteOrder = LittleEndian | BigEndian

  fun byteOrderToWord LittleEndian = 0w0
    | byteOrderToWord BigEndian = 0w1

  fun byteOrderToString LittleEndian = "LittleEndian"
    | byteOrderToString BigEndian = "BigEndian"

end
