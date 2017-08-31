structure B = struct end
structure A = F(B)
exception Bar
val x = (raise G.Hoge) : int
val y = (raise G.Hage) : int
