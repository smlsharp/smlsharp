(**
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 *)
structure JSON =
struct
  structure JP = JSONParser
  structure R = ReifiedTerm

  exception AttemptToReturnVOIDValue
  exception RuntimeTypeError
  exception TypeIsNotJsonKind
  exception AttemptToViewNull

  exception NaturalJoin

  datatype null = datatype JSONTypes.null
  datatype void = datatype JSONTypes.void
  datatype jsonTy = datatype JSONTypes.jsonTy
  datatype json = datatype JSONTypes.json
  datatype dyn = datatype JSONTypes.dyn

  (* for debugging *)
  fun printJsonTy jsonTy =
      let
        val print = Bug.printError
      in
        case jsonTy of
          ARRAYty jsonTy =>
          (print "ARRAYty(";
           printJsonTy jsonTy;
           print ")")
        | BOOLty => print "BOOLty"
        | INTty => print "INTty"
        | REALty => print "REALty"
        | STRINGty => print "STRINGty"
        | PARTIALBOOLty => print "PARTIALBOOLty"
        | PARTIALINTty => print "PARTIALINTty"
        | PARTIALREALty => print "PARTIALREALty"
        | PARTIALSTRINGty => print "PARTIALSTRINGty"
        | DYNty => print "DYNty"
        | NULLty => print "NULLty"
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
        | OPTIONty jsonTy =>
          (print "OPTIONty(";
           printJsonTy jsonTy;
           print ")")
      end

  fun glbJsonTy (ty1, ty2) = 
      if ty1 = ty2 then ty1
      else
        case (ty1, ty2) of
          (NULLty, OPTIONty _) => ty2
        | (NULLty, _) => OPTIONty ty2
        | (OPTIONty _, NULLty) => ty1
        | (_, NULLty) => OPTIONty ty1
        | (OPTIONty argTy1, OPTIONty argTy2) => 
          OPTIONty (glbJsonTy (argTy1, argTy2))
        | (OPTIONty elemTy1, _) =>
          OPTIONty (glbJsonTy (elemTy1, ty2))
        | (_, OPTIONty elemTy2) =>
          OPTIONty (glbJsonTy (ty1, elemTy2)) 
        | (ARRAYty elemTy1, ARRAYty elemTy2) => 
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

  fun infer v = 
    case v of
      JP.OBJECT fields => inferObject fields
    | JP.ARRAY vl   => inferArray vl
    | JP.STRING s   => (STRING s, STRINGty)
    | JP.INT i      => (INT i, INTty)
    | JP.REAL r     => (REAL r, REALty)
    | JP.BOOL b     => (BOOL b, BOOLty)
    | JP.NULL       => (NULLObject, NULLty)
  and inferObject kvl =
    let
      fun inferObject_aux kvl (tjl, tyl) =
        case kvl of
          (k,v)::kvs => 
            let
              val (tj, ty) = infer v
            in
              inferObject_aux kvs ((k, tj)::tjl, (k, ty)::tyl)
            end
        | [] => (List.rev tjl, List.rev tyl)

      val (tjl, tyl) = inferObject_aux kvl ([], [])
    in
      (OBJECT tjl, RECORDty tyl)
    end
  and inferArray nil = (ARRAY (nil, DYNty), ARRAYty DYNty)
    | inferArray (v::vl) = 
      let
        val (tj, ty) = infer v
        val (tjlRev, ty) = 
            foldl
              (fn (v, (tjlRev, ty)) => 
                  let
                    val (tj, ty') = infer v
                  in
                    (tj::tjlRev, glbJsonTy (ty, ty'))
                  end
              )
              ([tj],ty)
            vl
      in
        (ARRAY (List.rev tjlRev, ty), ARRAYty ty)
      end

  fun typeOf v = 
      case v of
        ARRAY (_,jsonTy) => ARRAYty jsonTy
      | BOOL _ => BOOLty
      | INT _ => INTty
      | NULLObject => NULLty
      | OBJECT fieldList => RECORDty (map (fn (l, json) => (l, typeOf json)) fieldList)
      | REAL _ => REALty
      | STRING  _ => STRINGty

  fun view (DYN (viewFn, json)) = viewFn json

  fun importJson uj =
      let
        val (tj, _) = infer uj
      in
        DYN (fn _ => raise AttemptToReturnVOIDValue, tj)
      end

  fun import src =
      importJson (JSONParser.parse src)

  fun importForm src =
      DYN (fn _ => raise AttemptToReturnVOIDValue,
           OBJECT (map (fn (k,v) => (k, STRING v)) src))

  exception ReifiedtermToJson
  fun reifiedtermToJson reifiedterm =
      case reifiedterm of
        R.INT int => INT int
      | R.BOOL bool => BOOL bool
      | R.REAL real => REAL real
      | R.STRING string => STRING string
      | R.RECORD stringReifiedTermList => 
        OBJECT (map (fn (l, r) => (l,  reifiedtermToJson r)) stringReifiedTermList)
      | R.LIST reifiedTermList => 
        let
          val jsonList = map reifiedtermToJson reifiedTermList
          val jsonTyList = map typeOf jsonList
          val jsonTy = 
              case jsonTyList of
                nil => ARRAYty DYNty
              | h::tl => List.foldr glbJsonTy h tl
        in
          ARRAY (jsonList, jsonTy)
        end
      | R.OPTIONNONE => NULLObject
      | R.OPTIONSOME term => reifiedtermToJson term
      | _ => raise TypeIsNotJsonKind

  fun jsonToReifiedterm json =
      case json of
        INT int => R.INT int
      | BOOL bool => R.BOOL bool
      | REAL real => R.REAL real
      | STRING string => R.STRING string
      | OBJECT stringJsonList =>
        R.RECORD (map (fn (l, j) => (l,  jsonToReifiedterm j)) stringJsonList)
      | ARRAY (jsonList, jsonTy) =>
        R.LIST (map jsonToReifiedterm jsonList)
      | NULLObject => R.OPTIONNONE

  fun jsonToString json = 
      SMLFormat.prettyPrint 
        [SMLFormat.Columns 80]
        (ReifiedTerm.toJSON_reifiedTerm (jsonToReifiedterm json))
  fun jsonDynToString (DYN (view, json)) = 
      SMLFormat.prettyPrint 
        [SMLFormat.Columns 80]
        (ReifiedTerm.toJSON_reifiedTerm (jsonToReifiedterm json))
  fun jsonToJsonDyn json = DYN (fn _ => raise AttemptToReturnVOIDValue,json)
  fun jsonDynToJson (DYN (view, json)) = json


  local 
    open PolyDynamic
  in
    fun toList (elementTy, listObj) =
        let
          fun getTail (obj, listRev) = 
              if isNull obj then listRev
              else 
                let
                  val obj = deref obj
                  val firstJson = 
                      dynamicToJson
                        (mkDynamic {ty = elementTy, obj = car obj})
                in
                  getTail (cdr (elementTy, obj), firstJson::listRev)
                end
          in
            List.rev (getTail (listObj, nil))
          end

    and toRecord (filedsTy, obj) = 
        let
          fun getFields (nil, obj, fieldsRev) = List.rev fieldsRev
            | getFields ((l,ty)::rest, obj, fieldsRev) = 
              let
                val obj = align(obj, ty)
                val json = dynamicToJson (mkDynamic {ty = ty, obj = obj})
                val obj = offset(obj, sizeOf ty)
              in
                getFields (rest, obj, (l,json)::fieldsRev)
              end
          in
            getFields (filedsTy, obj, nil)
          end

    and dynamicToJson dyn = 
        let
          val ty = typeOf dyn
          val obj =objOf dyn
        in
          case ty of 
            INTty => INT (getInt obj)
          | REALty => REAL (getReal obj)
          | STRINGty => STRING (getString obj)
          | BOOLty => BOOL (getBool obj)
          | ARRAYty elementTy =>
            let
              val jsonList = toList (elementTy, obj)
            in
              ARRAY (jsonList, elementTy)
            end
          | RECORDty fieldTys =>
            let
              val jsonFields = toRecord(fieldTys, deref obj)
            in
              OBJECT jsonFields
            end
          | OPTIONty ty =>
            if isNull obj then NULLObject
            else dynamicToJson (mkDynamic {ty = ty, obj = deref obj})
          | DYNty => NULLObject (* undefined *)
          | _ => NULLObject (* undefined *)
        end

    fun toJson a = dynamicToJson (dynamic a)

    fun toJsonDyn a = jsonToJsonDyn (toJson a)
  end

end
