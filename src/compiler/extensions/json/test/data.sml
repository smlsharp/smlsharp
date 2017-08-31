val x1 = "1"
val x2 = "\"joe\""
val x3 = "true"
val x4 = "3.14"
val x5 = "[1,2,3]"
val x6 = "{\"name\":\"SML#\", \"age\":23}"
val x7 = "[{\"name\":\"SML#\", \"age\":23}, {\"name\":\"Joe\", \"office\":517, \"age\":23}]"
val y1 = import x1
val y2 = import x2
val y3 = import x3
val y4 = import x4
val y5 = import x5
val y6 = import x6
val y7 = import x7
val z1 = _json y1 as int
val z2 = _json y2 as string
val z3 = _json y3 as bool
val z4 = _json y4 as real
val z5 = _json y5 as int list
val z6 = _json y6 as {name:string, age:int}
val z7 = _json y7 as {name:string, age:int} dyn list

val J =
   "[{\"name\":\"Joe\", \"age\":21, \"grade\":1.1},\
\    {\"name\":\"Sue\", \"age\":31, \"grade\":2.0},\
\    {\"name\":\"Bob\", \"age\":41, \"grade\":3.9}]"
fun getNames l = map #name l
val j = import J
val vl = _json j as {name:string, age:int, grade:real} list
val nl = getNames vl

val J' =
  "[{\"name\":\"Alice\", \"age\":10, \"nickname\":\"Allie\"},\
\   {\"name\":\"Dinah\", \"age\":3, \"grade\":2.0},\
\   {\"name\":\"Puppy\", \"age\":7}]"
val j' = import J'
val vl' = _json j' as {name:string, age:int} dyn list
val nl' = getNames (map view vl')

fun getFriendlyName vl =
   map (fn x => 
           _jsoncase x of
           {nickname=y:string, ...} => y
         | _ => #name (view x))
       vl
fun avgTemp l = foldl (op +) 0.0 (map (#temp o view o #main o view) l)
fun avgTemp' l =
   foldl (op +) 0.0
         (map (fn x => _jsoncase x of {main={temp:real,...},...} => temp) l)
fun rainyCities t l =
    List.mapPartial
      (fn x => if (_jsoncase x of
                   {rain={"3h"=y:int}, ...} => y > t
        | _ => false)
               then SOME (#name (view x))
               else NONE)
      l

fun getNumAsReal x =
    _jsoncase x of
    (n:int) => Real.fromInt n
  | (r:real) => r
  | _ => 0.0 / 0.0  (* not a number *)
;

let
  val x = [{name = "Joe", score = {math = 76, lang = 89}},
           {name = "Sue", score = {math = 87, lang = 93}},
           {name = "Bob", score = {math = 96, lang = 94}}]
in
  print (#string (dynamicToJson (toDynamic x)))
end
