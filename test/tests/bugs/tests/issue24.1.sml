fun until f [] = [] 
    | until f (hd :: tl) = if f hd then [] else until f tl;
until (fn x => true) [1];
