structure JSONImpl =
struct
  open JSON

  structure R = ReifiedTerm

  (* for debugging *)
  fun printJsonTy jsonTy =
      case jsonTy of
     ARRAYty jsonTy =>
     (print "ARRAYty(";
      printJsonTy jsonTy;
      print ")")
    | BOOLty => print "BOOLty"
    | DYNty => print "DYNty"
    | INTty => print "INTty"
    | NULLty => print "NULLtyty"
    | RECORDty stringJsontyList =>
      (print "RECORDty{";
       map (fn (l,jsonTy) =>
               (print l;
                print ":";
                printJsonTy jsonTy;
                print ","
               )
           )
       stringJsontyList;
       ();
       print "}"
      )
    | PARTIALRECORDty stringJsontyList =>
      (print "PARTIALRECORDty{";
       map (fn (l,jsonTy) =>
               (print l;
                print ":";
                printJsonTy jsonTy;
                print ","
               )
           )
       stringJsontyList;
       ();
       print "}"
      )
    | REALty => print "REALty"
    | STRINGty => print "STRINGty"

  fun glbJsonTy (ty1, ty2) = 
      if ty1 = ty2 then ty1
      else
        case (ty1, ty2) of
          (ARRAYty elemTy1, ARRAYty elemTy2) => 
          ARRAYty (glbJsonTy (elemTy1, elemTy2))
        | (RECORDty fl1, RECORDty fl2) =>
          PARTIALRECORDty (glbFieldTys (fl1, fl2))
        | (PARTIALRECORDty fl1, RECORDty fl2) => 
          PARTIALRECORDty (glbFieldTys (fl1, fl2))
        | (RECORDty fl1, PARTIALRECORDty fl2) => 
          PARTIALRECORDty (glbFieldTys (fl1, fl2))
        | (PARTIALRECORDty fl1, PARTIALRECORDty fl2) => 
          PARTIALRECORDty (glbFieldTys (fl1, fl2))
        | _ => DYNty

  and glbFieldTys (fl1, fl2) =
      List.foldr
        (fn ((l, ty1), fl) => 
            case List.find (fn (l',_) => l' = l) fl2 of
              NONE => fl
            | SOME (_, ty2) => (l, glbJsonTy (ty1, ty2)) :: fl
         ) 
      nil
      fl1

  fun typeOf v = 
      case v of
        ARRAY (_,jsonTy) => ARRAYty jsonTy
      | BOOL _ => BOOLty
      | INT _ => INTty
      | NULLObject => NULLty
      | OBJECT fieldList => RECORDty (map (fn (l, json) => (l, typeOf json)) fieldList)
      | REAL _ => REALty
      | STRING  _ => STRINGty

  fun matchTy (realTy, viewTy) = 
      case (realTy, viewTy) of
        (_, DYNty) => true
      | (ARRAYty realTy1, ARRAYty vewTy1) => matchTy (realTy1, vewTy1)
      | (BOOLty, BOOLty) => true
      | (INTty, INTty) => true
      | (NULLty, NULLty) => true
      | (RECORDty fl1, RECORDty fl2) => matchTyFields (fl1, fl2)
      | (RECORDty fl1, PARTIALRECORDty fl2) => 
        matchTyFields (fl1, fl2)
      | (PARTIALRECORDty fl1, PARTIALRECORDty fl2) => 
        matchTyFields (fl1, fl2)
      | (REALty, REALty) => true
      | (STRINGty, STRINGty) => true
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
      if matchTy (typeOf json, viewTy) then ()
      else raise RuntimeTypeError
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
  fun checkNull NULLObject = NULL
    | checkNull _ = raise RuntimeTypeError
  fun mapCoerce checkFn jsonList = map checkFn jsonList
  fun checkDyn json = DYN (fn _ => raise AttemptToReturnVOIDValue, json)
  fun checkRecord (OBJECT fields) labels = 
      (checkLabels (fields, labels);
       ())
    | checkRecord _ _ = raise RuntimeTypeError
  fun coerceJson jsonTy = 
   fn json => 
      case (jsonTy, json) of
        (ARRAYty elemTy, ARRAY (jsonList, _)) => ARRAY (map (coerceJson elemTy) jsonList, ARRAYty elemTy)
      | (BOOLty, BOOL bool) => BOOL bool
      | (DYNty, _) => json
      | (INTty, INT int) => INT int
      | (NULLty, NULLObject) => NULLObject
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
(*
         print "makeCoerce to PARTIALRECOEDty; this should not happen\n";
*)
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
      | (REALty, REAL real) => REAL real
      | (STRINGty, STRING string) => STRING string
      | _ => raise RuntimeTypeError
  fun makeCoerce json jsonTy viewFn =
      case jsonTy of
        DYNty => DYN (viewFn, json) 
      | _ => DYN(fn json => viewFn (coerceJson jsonTy json), json)

end
