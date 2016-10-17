structure JSONImpl =
struct

  open JSON

  structure R = ReifiedTerm

  fun matchTy (realTy, viewTy) = 
      case (realTy, viewTy) of
        (_, DYNty) => true
      | (NULLty, OPTIONty _) => true
      | (OPTIONty realArgTy, OPTIONty argTy) => matchTy (realArgTy, argTy)
      | (_, OPTIONty argTy) => matchTy (realTy, argTy)
      | (ARRAYty realTy1, ARRAYty vewTy1) => matchTy (realTy1, vewTy1)
      | (BOOLty, BOOLty) => true
      | (INTty, INTty) => true
      | (REALty, REALty) => true
      | (STRINGty, STRINGty) => true
      | (RECORDty fl1, RECORDty fl2) => matchTyFields (fl1, fl2)
      | (RECORDty fl1, PARTIALRECORDty fl2) => matchTyFields (fl1, fl2)
      | (PARTIALRECORDty fl1, PARTIALRECORDty fl2) => matchTyFields (fl1, fl2)
      | _ => false

  and matchTyFields (fl1, fl2) =
      let
        exception MatchTyFieldsFail
      in
        (app (fn (l, ty2) =>  
                 case List.find (fn (l', _) => l' = l) fl1 of
                   NONE => raise MatchTyFieldsFail
                 | SOME (_, ty1) =>  
                   if matchTy (ty1, ty2) then ()
                   else raise MatchTyFieldsFail
             ) 
             fl2;
         true)
        handle MatchTyFieldsFail => false
      end

  fun checkLabels (nil,nil) = ()
    | checkLabels ((h,_)::tl, h'::tl') = 
      if h <> h' then raise RuntimeTypeError
      else checkLabels (tl,tl')
    | checkLabels _ = raise RuntimeTypeError


  (* JSON compilation primitives used in TypedElaboration *)
  fun getJson (DYN (_, json)) = json
  fun checkTy json viewTy =
      let
        val jsonTy = typeOf json
      in
        if matchTy (jsonTy, viewTy) then ()
        else 
          (
(*
           print "jsonTy:";
           printJsonTy jsonTy;
           print "\n";
           print "viewTy:";
           printJsonTy viewTy;
           print "\n";
*)
          raise RuntimeTypeError
          )
      end
  fun checkInt (INT int) = int
    | checkInt _ = raise RuntimeTypeError
  fun checkBool (BOOL bool) = bool
    | checkBool _ = raise RuntimeTypeError
  fun checkReal (REAL real) = real
    | checkReal _ = raise RuntimeTypeError
  fun checkString (STRING string) = string
    | checkString _ = raise RuntimeTypeError
  fun checkArray (ARRAY (jsonList, jsonTy)) = jsonList
    | checkArray _ = raise RuntimeTypeError
  fun checkNull NULLObject = NONE
    | checkNull _ = raise RuntimeTypeError
  fun optionCoerce checkFn json = 
      case json of
        NULLObject => NONE
      | x => SOME (checkFn x)
  fun mapCoerce checkFn jsonList = map checkFn jsonList
  fun checkDyn json = DYN (fn _ => raise AttemptToReturnVOIDValue, json)
  fun checkRecord (OBJECT fields) labels = 
      (checkLabels (fields, labels);
       ())
    | checkRecord _ _ = raise RuntimeTypeError

  (* ユーザ指定の型の表現を生成 *)
  fun coerceJson jsonTy = 
   fn json => 
      case (jsonTy, json) of
        (NULLty, NULLObject) => NULLObject
      | (OPTIONty _, NULLObject) => NULLObject
      | (BOOLty, BOOL bool) => BOOL bool
      | (INTty, INT int) => INT int
      | (REALty, REAL real) => REAL real
      | (STRINGty, STRING string) => STRING string
      | (ARRAYty elemTy, ARRAY (jsonList, _)) => ARRAY (map (coerceJson elemTy) jsonList, ARRAYty elemTy)
      | (DYNty, _) => json
      | (RECORDty stringJsontyList, OBJECT stringJsonList) =>
         OBJECT 
         (foldr 
            (fn ((l,ty), fields) =>
                case List.find (fn (l',j) => l = l') stringJsonList of
                  NONE => raise  RuntimeTypeError
                | SOME (l',j) => (l, coerceJson ty j)::fields
            )
            nil
            stringJsontyList
         )
      | (PARTIALRECORDty stringJsontyList, OBJECT stringJsonList) =>
        (
         OBJECT 
           (foldr
              (fn ((l,ty), fields) =>
                  case List.find (fn (l',j) => l = l') stringJsonList of
                    NONE => raise  RuntimeTypeError
                  | SOME (l',j) => (l, coerceJson ty j)::fields
              )
              nil
              stringJsontyList
           )
        )
      | _ => raise RuntimeTypeError
  fun makeCoerce json jsonTy viewFn =
      case jsonTy of
        DYNty => DYN (viewFn, json) 
      | _ => DYN(fn json => viewFn (coerceJson jsonTy json), json)

end
