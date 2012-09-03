(*
local structure declaration.
<ul>
  <li>local declared: structure</li>
  <li>global declared: structure</li>
</ul>

<ul>
  <li>local structure and global structure have the same name.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
  <li>how global structure refers to local structure
    <ul>
      <li>refers to element of local structure</li>
      <li>refers to the local structure</li>
    </ul>
  </li>
</ul>
*)
local
  structure S = struct datatype dt = D val x = D end
in
structure S11 = struct val x : S.dt * S.dt = (S.x, S.D) end
end;
val x11 = S11.x;

local
  structure S = struct datatype dt = D val x = D end
in 
structure S12 = S
end;
val x12 : S12.dt * S12.dt = (S12.x, S12.D);

local
  structure S21 = struct datatype dt = D val x = D end
in
structure S21 = struct val x : S21.dt * S21.dt = (S21.x, S21.D) end
end;
val x21 = S21.x;

local
  structure S22 = struct datatype dt = D val x = D end
in 
structure S22 = S22
end;
val x22 : S22.dt * S22.dt = (S22.x, S22.D);

