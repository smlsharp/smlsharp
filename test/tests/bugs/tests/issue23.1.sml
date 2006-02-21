fun map_int f [] = []
  | map_int f (hd :: tl) = ((f (hd : int)) : int) :: (map_int f tl);
map_int (fn (x : int) => x) [1];

fun map f [] = []
  | map f (hd :: tl) = (f hd) :: (map f tl);
map (fn x => x) [1];
map (fn (x : int) => (x : int)) [1];

fun map_argint f [] = []
  | map_argint f (hd :: tl) = (f (hd : int)) :: (map_argint f tl);
map_argint (fn (x : int) => x) [1];

fun map_resint f [] = ([] : int list)
  | map_resint f (hd :: tl) = (f hd) :: (map_resint f tl);
map_resint (fn (x : int) => x) [1];
