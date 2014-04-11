(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
structure PathOrd = 
struct
  type ord_key = string list
  fun compare (path1,path2) =
      case (path1, path2) of
        (nil,nil) => EQUAL
      | (nil, _) => LESS
      | (_,nil) =>  GREATER
      | (h1::t1, h2::t2) => 
        (case String.compare(h1,h2) of
           EQUAL => compare(t1,t2)
         | x => x)
end

