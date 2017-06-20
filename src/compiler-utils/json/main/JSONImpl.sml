(**
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 *)
structure JSONImpl =
struct

  open JSON

  fun matchTy (realTy, viewTy) = 
      case (realTy, viewTy) of
        (_, DYNty) => true
      | (NULLty, OPTIONty _) => true
      | (OPTIONty realArgTy, OPTIONty argTy) => matchTy (realArgTy, argTy)
      | (_, OPTIONty argTy) => matchTy (realTy, argTy)
      | (ARRAYty DYNty, ARRAYty _) => true
      | (ARRAYty realTy1, ARRAYty vewTy1) => matchTy (realTy1, vewTy1)
      | (BOOLty, BOOLty) => true
      | (BOOLty, PARTIALBOOLty) => true
      | (INTty, INTty) => true
      | (INTty, PARTIALINTty) => true
      | (REALty, REALty) => true
      | (REALty, PARTIALREALty) => true
      | (STRINGty, STRINGty) => true
      | (STRINGty, PARTIALSTRINGty) => true
      | (RECORDty fl1, RECORDty fl2) => matchTyFields (fl1, fl2)
      | (RECORDty fl1, PARTIALRECORDty fl2) => matchTyFields (fl1, fl2)
      | (PARTIALRECORDty fl1, PARTIALRECORDty fl2) => matchTyFields (fl1, fl2)
      | _ =>
        false

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
            val _ = Bug.printError "checkTy ** \n"
            val _ = Bug.printError "jsonTy:"
            val _ = printJsonTy jsonTy
            val _ = Bug.printError "\n"
            val _ = Bug.printError "viewTy:"
            val _ = printJsonTy viewTy
            val _ = Bug.printError "\n"
      in
        if matchTy (jsonTy, viewTy) then ()
        else
          let
            val _ = Bug.printError "checkTy fail \n"
            val _ = Bug.printError "jsonTy:"
            val _ = printJsonTy jsonTy
            val _ = Bug.printError "\n"
            val _ = Bug.printError "viewTy:"
            val _ = printJsonTy viewTy
            val _ = Bug.printError "\n"
          in
            raise RuntimeTypeError
          end
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
  fun makeView jsonTy = 
   fn json => 
      case (jsonTy, json) of
        (NULLty, NULLObject) => NULLObject
      | (OPTIONty _, NULLObject) => NULLObject
      | (OPTIONty INTty, INT _) => json
      | (OPTIONty STRINGty, STRING _) => json
      | (OPTIONty REALty, REAL _) => json
      | (OPTIONty BOOLty, BOOL _) => json
      | (BOOLty, BOOL bool) => BOOL bool
      | (INTty, INT int) => INT int
      | (REALty, REAL real) => REAL real
      | (STRINGty, STRING string) => STRING string
      | (ARRAYty elemTy, ARRAY (jsonList, _)) => ARRAY (map (makeView elemTy) jsonList, ARRAYty elemTy)
      | (DYNty, _) => json
      | (RECORDty stringJsontyList, OBJECT stringJsonList) =>
         OBJECT 
         (foldr 
            (fn ((l,ty), fields) =>
                case List.find (fn (l',j) => l = l') stringJsonList of
                  NONE => raise  RuntimeTypeError
                | SOME (l',j) => (l, makeView ty j)::fields
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
                  | SOME (l',j) => (l, makeView ty j)::fields
              )
              nil
              stringJsontyList
           )
        )
      | _ => raise RuntimeTypeError
  fun makeCoerce json jsonTy viewFn =
      case jsonTy of
        DYNty => DYN (fn _ => raise AttemptToReturnVOIDValue, json) 
      | _ => DYN(fn json => viewFn (makeView jsonTy json), json)

  (* _joinプリミティブテスト用コード *)
  fun naturalJoin (x, y) =
      let
        fun naturalJoin' (ARRAY (jl1, ty1), ARRAY (jl2, ty2)) =
            (* 2016-10-13 sasaki: FIXME: 
             * ARRAY中に重複する要素が存在すると結果に重複する要素が複数出現する *)
            let
              fun joinJsonTy (ARRAYty ty1, ARRAYty ty2) =
                  ARRAYty (joinJsonTy (ty1, ty2))
                | joinJsonTy (OPTIONty ty1, OPTIONty ty2) =
                  OPTIONty (joinJsonTy (ty1, ty2))
                | joinJsonTy (OPTIONty ty1, ty2) =
                  OPTIONty (joinJsonTy (ty1, ty2))
                | joinJsonTy (ty1, OPTIONty ty2) =
                  OPTIONty (joinJsonTy (ty1, ty2))
                | joinJsonTy (RECORDty tyl1, RECORDty tyl2) =
                  RECORDty (processRecordTy (tyl1, tyl2))
                | joinJsonTy (RECORDty tyl1, PARTIALRECORDty tyl2) =
                  PARTIALRECORDty (processRecordTy (tyl1, tyl2))
                | joinJsonTy (PARTIALRECORDty tyl1, RECORDty tyl2) =
                  PARTIALRECORDty (processRecordTy (tyl1, tyl2))
                | joinJsonTy (PARTIALRECORDty tyl1, PARTIALRECORDty tyl2) =
                  PARTIALRECORDty (processRecordTy (tyl1, tyl2))
                | joinJsonTy (NULLty, ty2) = ty2
                | joinJsonTy (ty1, NULLty) = ty1
                | joinJsonTy (ty1, ty2) =
                  if ty1 = ty2 then ty1 
                  else raise NaturalJoin
              and processRecordTy (nil, nil) = nil
                | processRecordTy (tyl1, nil) = tyl1
                | processRecordTy (nil, tyl2) = tyl2
                | processRecordTy (tyl1 as ((l1, ty1) :: rest1), tyl2 as ((l2, ty2) :: rest2)) =
                  (* 2016-10-13 sasaki: 型のリストも名前の昇順ソートされていると仮定 *)
                  if l1 < l2 then (l1, ty1) :: processRecordTy (rest1, tyl2)
                  else if l1 > l2 then (l2, ty2) :: processRecordTy (tyl1, rest2)
                  else (l1, joinJsonTy (ty1, ty2)) :: processRecordTy (rest1, rest2)
            in
              ARRAY (List.foldr (fn (j1, jl) => 
                                    List.foldr (fn (j2, jl')  => 
                                                   naturalJoin' (j1, j2) :: jl'
                                                   handle NaturalJoin => jl')
                                               nil jl2 
                                    @ jl)
                                nil jl1, 
                     joinJsonTy (ty1, ty2))
            end
          | naturalJoin' (b as BOOL b1, BOOL b2) =
            if b1 = b2 then b else raise NaturalJoin
          | naturalJoin' (i as INT i1, INT i2) =
            if i1 = i2 then i else raise NaturalJoin
          | naturalJoin' (n as NULLObject, NULLObject) = n (* Is it OK? *)
          | naturalJoin' (NULLObject, e) = e (* Is it OK? *)
          | naturalJoin' (e, NULLObject) = e (* Is it OK? *)
          | naturalJoin' (OBJECT obj1, OBJECT obj2) =
            (* 2016-10-13 sasaki: それぞれのオブジェクトは名前で昇順ソートされていると仮定 *)
            let
              fun join (nil, nil) = nil
                | join (obj1, nil) = obj1
                | join (nil, obj2) = obj2
                | join (obj1 as ((l1, j1) :: rest1), obj2 as ((l2, j2) :: rest2)) =
                  if l1 < l2 then (l1, j1) :: join (rest1, obj2)
                  else if l1 > l2 then (l2, j2) :: join (obj1, rest2)
                  else (l1, naturalJoin' (j1, j2)) :: join (rest1, rest2)
            in
              OBJECT (join (obj1, obj2))
            end
          | naturalJoin' (REAL r1, REAL r2) =
            (case Real.compare(r1, r2) of
               EQUAL => REAL r1
             | _ => raise NaturalJoin
            )
          | naturalJoin' (s as STRING s1, STRING s2) =
            if s1 = s2 then s else raise NaturalJoin
          | naturalJoin' _ = raise NaturalJoin
      in
        naturalJoin' (x, y)
      end

  fun toJson x = JSON.toJson x
  fun ('a#json) coerceJson (json, jsonTy) : 'a =
       JSONToML.jsonToML (json, jsonTy)
end
