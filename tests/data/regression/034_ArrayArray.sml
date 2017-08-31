_interface "034_ArrayArray.smi"
val printf = _import "printf" : (string,...(int)) -> int
val x = SMLSharp_Builtin.Array.alloc_unsafe 2 :int array
val y = SMLSharp_Builtin.Array.length x
val _ = printf ("%d\n", y)
val _ = case y of 2 => () | _ => raise Fail "unexpected"

(*
2011-08-17 ohori

This print 1 but it sould be 2.

This is the case of uncaught exception (segmentation falt):
In count_grapth,

1. In
   fun h (maxSize, folder, state) =
	let
          ....
	  val classesv = Array.array (maxSize+1, [])
masSize+1 is 2 but the array "classesv" created is of size 1

2. This classesv is updated in 

 fun Gfolder (size, _, state, accross) = 
    (
    if size <> 0
    then Array.update (classesv,
		       size,
		       refine (size-1,
			       Array.sub (classesv,  
					  size-1),
			       connected))

results in uncaught exception (segmentation fault).

This is a bug in benchmark source. The correct code should be

structure Array =
struct
  fun array (n,a) = PrimArray.array(n * 4, a)
  fun sub (a,n) = PrimArray.sub(a,n * 4)
  fun update (a,n,b) = PrimArray.update(a,n * 4,b)
  fun tabulate (n, f) =
      if n < 0 then raise Size
      else if n = 0 then array(0, f 0)
      else
        let val e = f 0
            val v = array (n, e)
            fun loop i =
                if i < n
                then (update (v, i, f i); loop (i+1))
                else ()
        in loop 0; v
      end
  fun vector(n,a) = PrimArray.vector(n*4, a)
  val length = PrimArray.length
end

*)

(*
2011-08-19 katsu

Fixed by changeset 9edd4c7b6cdb.

This was a bug of ToYAANormal.
In ClosureANormal array size and array index are represented in the
number of elements, but they are in bytes in YAANormal.

*)
