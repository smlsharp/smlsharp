val _ =
    let
      fun l8 s = String.extract (s, size s - 8, NONE)
      fun fmt (h, l) =
          CharVector.map Char.toLower
            (l8 ("0000000" ^ Word32.fmt StringCvt.HEX h)
             ^ l8 ("0000000" ^ Word32.fmt StringCvt.HEX l))
      fun test (input, expect) =
          let
            val float = valOf (IEEERealConst64.fromString input)
            val actual = fmt (IEEERealConst64.pack float)
          in
            if actual = expect then ()
            else raise Fail (input ^ " " ^ expect ^ " " ^ actual)
          end
    in
      (* normalized number *)
      test ("0.0",                      "0000000000000000");
      test ("~2.5",                     "c004000000000000");
      test ("1.79769313486231571e+308", "7fefffffffffffff");
      test ("0.841470984807896505",     "3feaed548f090cee");
      test ("2.22507385850720188e~308", "0010000000000001");
      test ("2.22507385850720138e~308", "0010000000000000");
      (* denormalized number *)
      test ("2.22507385850720102e~308", "000fffffffffffff");
      test ("2.22507385850720089e~308", "000fffffffffffff");
      test ("7.41691286169066963e~309", "0005555555555555");
      test ("4.94065645841246517e~324", "0000000000000001");
      (* too small *)
      test ("1e~340",                   "0000000000000001");
      ()
    end
