val (x, y) = f ()
val _ = (_import "printf" : (string,...(int,int)) -> int) ("%d %d\n", x, y)
