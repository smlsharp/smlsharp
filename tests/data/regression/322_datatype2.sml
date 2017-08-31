type a = int * int
datatype t = A of a | B of word
fun f x = A (x, x)
fun g ((x,y):a) = x
