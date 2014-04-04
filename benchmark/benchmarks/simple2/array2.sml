structure Array2 : sig

    type 'a array2
    exception Subscript
    val array: (int*int) * '1a -> '1a array2
    val sub : 'a array2 * (int*int) -> 'a
    val update : 'a array2 * (int*int) * 'a -> unit
    val length : 'a array2 -> (int*int)

  end = struct

    type 'a array2 = {size : (int*int), value : 'a Array.array}
    exception Subscript = Subscript
    fun index ((i1:int,i2:int),(s1,s2)) =
	if i1>=0 andalso i1<s1 andalso i2>=0 andalso i2<s2 then i1*s2+i2 
	else raise Subscript
    fun array(bnds as (i1,i2), v) = {size=bnds, value=Array.array(i1*i2, v)}
    fun op sub ({size,value}, indx) = Array.sub(value, index(indx,size))
    fun update ({size=size,value=A},i,v) = Array.update(A,index(i,size),v)
    fun length{size=size,value=A} = size

  end; (* Array2 *)
