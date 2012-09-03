structure Utils = struct
fun listToTuple list =
    #2
     (foldl
        (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
        (1, nil)
        list)
fun listToFields list =
    #2
     (foldl
        (fn (x, (n, y)) => (n + 1, SEnv.insert(y,Int.toString n, x)))
        (1, SEnv.empty)
        list)
end
