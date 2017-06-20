  datatype 'a parList = 
           NIL
         | CONS of 'a * index

  fun listInitialize cell L =
      case L of
        nil => cell NIL
      | h :: tail => 
        let
          val tailIndex = listInitialize cell tail
        in
          cell (CONS(h, tailIndex))
        end

  fun listInitialize (K: index -> index) cell L =
      case L of
        nil => K (cell NIL)
      | h :: tail => 
        let
          val newK = fn i => K (cell (CONS(h, i)))
        in
          listInitialize newK cell tail
        end

  fun listFinalize value =
      let
        fun conv i = 
            case value i of
              NIL => nil
            | CONS(head, tail) => head :: conv tail
      in
        conv
      end

  val whereParam = 
      {size = fn L => List.length L + 1,
       initialize = fn x => listInitialize (fn (x:index) => x) x,
       default = NIL,
       finalize = listFinalize}

 fun mapList f L = 
     _foreach id in L where whereParam
     with {value, newValue, size} 
     do case value id of
          NIL => NIL
        | CONS(head, tail)  => CONS(f head, tail)
     while false
     end  
