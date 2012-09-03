structure S1 = struct datatype t = D end
structure S2 = struct datatype t = datatype S1.t end
val x = S2.D
