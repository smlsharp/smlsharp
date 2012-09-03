fun F r =
    let fun f n = if #a r = n then f n else true
    in f 0
    end;
