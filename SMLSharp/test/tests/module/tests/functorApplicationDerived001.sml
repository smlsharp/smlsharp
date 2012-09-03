(*
derived form functor application.
<pre>
funid( strdec )
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>empty</li>
      <li>val spec</li>
      <li>type spec</li>
      <li>eqtype spec</li>
      <li>datatype spec</li>
      <li>datatype replication spec</li>
      <li>exception spec</li>
      <li>structure spec</li>
    </ul>
  </li>
</ul>
*)
functor FEmpty(S : sig end) = struct end;
structure TEmpty = FEmpty();

functor FVal(S : sig val x : int end) = struct val y = S.x end;
structure TVal = FVal(val x = 2);
val xVal = TVal.y;

functor FType(S : sig type t end) = struct datatype dt = D of S.t end;
structure TType = FType(type t = real);
datatype dtType = DType of TType.dt;
val xType = TType.D(1.23);

functor FEqType(S : sig eqtype t end) = struct datatype dt = D of S.t end;
structure TEqType = FEqType(type t = string);
datatype dtEqType = DEqType of TEqType.dt;
val xEqType = TEqType.D "abc";

functor FDatatype(S : sig datatype dt = D end) = 
struct datatype dt = E of S.dt datatype et = datatype S.dt end;
structure TDatatype = FDatatype(datatype dt = D);
datatype dtDatatype = DDatatype of TDatatype.dt;
val xDatatype = TDatatype.E(TDatatype.D);

datatype dtDatatypeRep = DDatatypeRep;
functor FDatatypeRep(S : sig datatype dt = datatype dtDatatypeRep end) =
struct datatype dt = D of S.dt datatype et = datatype S.dt end;
structure TDatatypeRep = FDatatypeRep(datatype dt = datatype dtDatatypeRep);
val xDatatypeRep = TDatatypeRep.D(DDatatypeRep);
val yDatatypeRep = TDatatypeRep.DDatatypeRep;

functor FException(S : sig exception E of real end) =
struct exception F = S.E fun f r = raise S.E r end;
structure TException = FException(exception E of real);
val xException = (TException.f 1.23) handle TException.F r => r;

functor FStructure(S : sig structure T : sig datatype dt = D end end) =
struct structure T = S.T end;
structure TStructure = FStructure(structure T = struct datatype dt = D end);
structure SStructure = TStructure.T;
val xStructure = TStructure.T.D;
