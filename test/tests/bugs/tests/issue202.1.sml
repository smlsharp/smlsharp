functor TextIOFn ()  = 
struct
  fun input1 () =
      case SOME(#"a", ())
       of NONE => NONE
        | SOME(elem, _) => SOME elem
end;
structure TextIO = TextIOFn ();
TextIO.input1 ();
