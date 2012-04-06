(*
specs in a signature included by "include" specification.

<ul>
  <li>
    <ul>
      <li>val spec</li>
      <li>type spec</li>
      <li>eqtype spec</li>
      <li>datatype spec</li>
      <li>datatype replication spec</li>
      <li>exception spec</li>
      <li>structure spec</li>
      <li>include spec</li>
    </ul>
  </li>
</ul>
*)
signature Ival = sig val x : int end;
signature Sval = sig include Ival end;

signature Itype = sig type t end;
signature Stype = sig include Itype end;

signature Ieqtype = sig eqtype t end;
signature Seqtype = sig include Ieqtype end;

signature Idatatype = sig datatype dt = D end;
signature Sdatatype = sig include Idatatype end;

datatype dt = D;
signature IdatatypeRep = sig datatype dt = datatype dt end
signature SdatatypeRep = sig include IdatatypeRep end;

signature Iexception = sig exception E end;
signature Sexception = sig include Iexception end;

signature Istructure = 
sig structure S : sig type t datatype dt = D val x : t end end;
signature Sstructure = sig include Istructure end;

signature Tinclude = sig type t datatype dt = D val x : t end;
signature Iinclude = sig include Tinclude end;
signature Sinclude = sig include Iinclude end;
