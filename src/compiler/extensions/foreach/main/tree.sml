datatype 'a tree 
  = Empty
  | Node of 'a * 'a tree * 'a tree
datatype 'a paraTree 
  = EMPTY
  | NODE of 'a * index * index
fun size Empty = 1
  | size (Node(a, left, right)) = 1 + size left + size right

fun initialize cell T =
    case T of
      Empty => cell EMPTY
    | Node(a, left, right) => 
      let
        val LEFT =  initialize cell left
        val RIGHT = initialize cell right
      in
        cell (NODE(a, LEFT, RIGHT))
      end

fun finalize value =
    let
      fun conv i = 
          case value i of
            EMPTY => Empty
          | NODE(a, LEFT, RIGHT) =>
            Node(a, conv LEFT, conv RIGHT)
    in
      conv
    end

fun finalize value i =
    case value i of
      EMPTY => Empty
    | NODE(a, LEFT, RIGHT) =>
      Node(a, finalize value LEFT, finalize value RIGHT)


val whereParam = 
    {size = size,
     initialize = initialize,
     default = EMPTY,
     finalize = finalize}

fun mapTree f T = 
    _foreach id in T where whereParam
    with {value, newValue, size} 
    do case value id of
         EMPTY => EMPTY
       | NODE(data, LEFT, RIGHT)  => NODE(f data, LEFT, RIGHT)
    while false
    end  
