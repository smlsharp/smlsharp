(*
"handle" expression which occurs at various locations.

<ul>
  <li>location of "handle" expression 
    <ul>
      <li>record expression</li>
      <li>let expression</li>
      <li>argument of tyCon application expression</li>
      <li>tyCon of tyCon application expression</li>
      <li>typed expression</li>
      <li>handle expression</li>
      <li>raise expression</li>
      <li>fn expression</li>
    </ul>
  </li>
</ul>
*)
exception E;
fun raiseE () = raise E;
fun id x = x;
datatype 'a dt = D of 'a;

val vRecord = {a = raiseE () handle E => 1};

val vLet = let in raiseE () handle E => 1 end;

val vArgTyConApp = D(raiseE () handle E => 1);

val vTyConTyConApp = (raiseE () handle E => D) 1;

val vArgFunApp = id (raiseE () handle E => 1);

val vFunFunApp = (raiseE () handle E => id) 1;

val vTyped = (raiseE () handle E => id) : int -> int;

val vHandle = (raiseE () handle E => 1) handle E => 2;

val vRaise = (raise (raiseE () handle E => raise E)) handle E => 1;

val vFn = fn x => (raiseE () handle E => x);
