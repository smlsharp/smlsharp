structure A = struct datatype s = foo end
structure B = struct open A end;
val x = B.foo;

structure C = struct datatype t = bar end;
structure D = struct open C end;
val y = D.bar;
