(*
$ smlsharp -c 372_rank1_interface.sml
$ smlsharp -r 372_rank1_interface.smi
# f;
val it = fn : ['a. 'a -> ['b. 'a * 'b -> 'a * 'b]]
# f 1 (1,2);
Segmentation fault
ohori@ubuntu:~/share/HG/smlsharp_ref/doc/tests$ 
*)
fun f x y = y;
