structure ForeachUtils =
struct
  val rootIndex = SMLSharp_Builtin.Foreach.intToIndex 0
  val toIndex = SMLSharp_Builtin.Foreach.intToIndex
  val toInt = SMLSharp_Builtin.Foreach.indexToInt
  type ('para, 'seq) whereParam = 
       {
        default:'para,
        finalize : (index -> 'para) -> index -> 'seq,
        size: 'seq -> int,
        initialize: ('para -> index) -> 'seq -> index
       }

  fun ('para, 'seq) toArray
     ({size, initialize, default, finalize}: ('para, 'seq) whereParam)
      (data : 'seq)
     : 'para array
    =
    let
      val size = size data
      val counter = ref 0
      val array = Array.array(size, default)
      fun elem x = 
          let 
            val count = !counter
            val c = size - count - 1
            val _ = Array.update(array, c, x)
            val _ = counter := count + 1
          in
            toIndex c
          end
      val _ = initialize elem data
    in
      array
    end

  fun ('para, 'seq) toData 
     ({default, finalize, size, initialize} : ('para, 'seq) whereParam)
     (array : 'para array) : 'seq
    = finalize (fn i => Array.sub(array, toInt i)) (toIndex 0)
end
