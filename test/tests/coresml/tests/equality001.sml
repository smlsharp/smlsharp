(*
equality check for argument types to type constructors.

<ul>
  <li>
    <ul>
      <li>equality type
        <ul>
          <li>type variable which admit equality</li>
          <li>record type</li>
          <li>constructed type</li>
          <li>ref type</li>
        </ul>
      </li>
      <li>non equality type
        <ul>
          <li>type variable which does not admit equality</li>
          <li>record type</li>
          <li>constructed type
            <ul>
              <li>some argument type is not equality type.</li>
              <li>the type constructor does not admit equality.</li>
            </ul>
          </li>
          <li>function type</li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
*)
datatype ''a dt = D of ''a;

type ''a tEqTypeVariable = ''a dt * int;
val vEqTypeVariable : bool tEqTypeVariable = (D true, 1);

type tEqRecord = {a : int, b : string} dt;
val vEqRecord : tEqRecord = D {a = 1, b = "abc"};

datatype dtEqConstructed1 = DEqConstructed1;
type tEqConstructed1 = dtEqConstructed1 dt;
val vEqConstructed1 : tEqConstructed1 = D DEqConstructed1;

datatype 'a dtEqConstructed2 = DdtEqConstructed2 of 'a;
type tEqConstructed2 = (int dtEqConstructed2) dt;
val vEqConstructed2 : tEqConstructed2 = D (DdtEqConstructed2 1);

type tEqRef = int ref dt;
val vEqRef = D(ref 1);

(****************************************)
type 'a tNonEqTypeVariable = 'a dt;

type tNonEqRecord = {a : real} dt;

datatype dtNonEqConstructed1 = DNonEqConstructed1 | ENonEqConstructed1 of real;
type tNonEqConstructed1 = dtNonEqConstructed1 dt;

datatype 'a dtNonEqConstructed2 = DNonEqConstructed2 of 'a;
type tNonEqConstructed2 = (real dtNonEqConstructed2) dt;

type tNonEqFunction = (int -> int) dt;
