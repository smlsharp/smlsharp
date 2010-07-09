signature TEST = sig
    type 'a RList
    val empty : 'a RList
end
structure Test : TEST = struct
    datatype 'a Digit = Zero | One of 'a
    type 'a RList = 'a Digit list

    val empty = nil
end
val list = Test.empty;
