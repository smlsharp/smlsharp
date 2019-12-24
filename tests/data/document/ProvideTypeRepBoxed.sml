type r1 = {A : int, B : string}
type ('a, 'b) r2 = {A : 'a, B : 'b}
type ('a, 'b) r3 = {A : 'a, B : 'b}

type a1 = int array
type 'a a2 = 'a array
type 'a a3 = 'a array

type f1 = int -> int
type ('a, 'b) f2 = 'a -> 'b

datatype d1 = D11 of int
            | D12

datatype ('a, 'b) d2 = D21 of 'a
                     | D22 of 'b

datatype ('a, 'b) d3 = D31 of 'a
                     | D32 of 'b

val r1 = {A = 1, B = "A"}
val r2 = {A = 1, B = "A"}
val r31 = {A = 1, B = "A"}
val r32 = {A = 1, B = "B"}

val a1 = Array.fromList [1, 2, 3]; 
val a2 = Array.fromList [1, 2, 3]; 
val a31 = Array.fromList [1, 2, 3]; 
val a32 = Array.fromList [1, 2, 4]; 

val f1 = (fn x => x) (fn x => x) 
fun f2 x = raise Fail "f2"
fun f3 f x = f x

val d11 = D11 1
val d12 = D12

val d21 = D21 1
val d22 = D22 "A"

val d31 = D31 1
val d321 = D32 "A"
val d322 = D32 1

