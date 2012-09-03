fun f (x,y,z,u,w) = (x,y,z,u,w)
val a = (fn x => x, 1, fn y => y + 1,fn y => y andalso true, 2);
f a;
