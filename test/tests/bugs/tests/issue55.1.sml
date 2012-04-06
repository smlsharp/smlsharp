structure S1 = struct datatype t = D end;
structure S2 = struct datatype t = datatype S1.t end;
S2.D;
structure S3 = struct datatype t = datatype S1.t val x = D end;
