fun id x = x;
datatype 'a dt = D of 'a;
let val y = id in y 1 end;
let val y = case D 1 of _ => id in y 1 end;
let val y = case D 1 of D _ => id in y 1 end;
