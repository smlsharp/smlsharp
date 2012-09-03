datatype 'a list = nil | cons of 'a * 'a list
fun length nil = 0
  | length (cons(h,t)) = 1 + length t


