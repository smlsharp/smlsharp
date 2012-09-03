(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>exception spec</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>none</li>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SException = sig exception F of real val f : real -> real end;
structure PException = struct exception E of real end;

functor FException(exception E of real) =
struct exception F = E fun f r = raise E r end;
structure TException = FException(PException);
val xException = (TException.f 1.23) handle TException.F r => r;

functor FExceptionTrans(exception E of real) : SException =
struct exception F = E fun f r = raise E r end;
structure TExceptionTrans = FExceptionTrans(PException);
val xExceptionTrans = (TExceptionTrans.f 1.23) handle TExceptionTrans.F r => r;

functor FExceptionOpaq(exception E of real) : SException =
struct exception F = E fun f r = raise E r end;
structure TExceptionOpaq = FExceptionOpaq(PException);
val xExceptionOpaq = (TExceptionOpaq.f 1.23) handle TExceptionOpaq.F r => r;
