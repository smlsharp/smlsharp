structure DataUtils =
struct
fun listToTuple l = 
 let
   val null = ""
   val T = {1=null, 2=null, 3=null, 4=null, 5=null, 6=null }
   val F =
       [fn (x,T) => T # {1 = x},
        fn (x,T) => T # {2 = x},
        fn (x,T) => T # {3 = x},
        fn (x,T) => T # {4 = x},
        fn (x,T) => T # {5 = x},
        fn (x,T) => T # {6 = x}
       ]
 in
   foldl (fn ((f,x), T) => f (x,T)) T (ListPair.zip (F,l))
 end

fun mkNest (L:{1:string, 2:string, 3:string, 4:string, 5:string, 6:string} list) = 
  let
    val nest = Dynamic.nest
    type nest1 = {1:string, 
                  L: {2:string, 3:string, 4:string, 5:string, 6:string} list} list
    type nest2 = {2:string, L:{3:string, 4:string, 5:string, 6:string} list} list
    type nest3 = {3:string, L:{4:string, 5:string, 6:string} list} list
    type nest4 = {4:string, L:{5:string, 6:string} list} list
    type nest5 = {5:string, L:{6:string} list} list
    val l1 = nest L : nest1
    val l2 = map (fn {1=x,L} => {1 = x, L = nest L : nest2}) l1
    val l3 = 
        map 
          (fn {1=x, L} =>
              {1 = x,
               L = map 
                     (fn {2=x,L} => {2=x, L = nest L : nest3})
                     L})
          l2
    val l4 = 
        map
          (fn {1=x, L} =>
              {1 = x,
               L = map 
                      (fn {2=x, L} => 
                          {2=x, L = map 
                                      (fn {3=x, L} => 
                                          {3=x, L = nest L : nest4})
                                      L}
                      ) L})
            l3
    val l5 = 
        map
        (fn {1=x, L} =>
            {1=x,
             L = 
             map
             (fn {2=x, L} => 
                 {2=x,
                  L =
                  map 
                  (fn {3=x, L} =>
                      {3=x,
                       L =
                       map 
                         (fn {4=x, L} =>
                             {4=x, L = nest L : nest5}) 
                         L})
                  L}
             )
             L}
        )
        l4
  in
    l5
  end


end
