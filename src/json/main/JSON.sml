structure JSON =
struct
  structure JP = JSONParser
  structure R = ReifiedTerm

  (* void type has no value. *)
  exception AttemptToReturnVOIDValue
  exception RuntimeTypeError
  exception TypeIsNotJsonKind

  datatype null = NULL
  datatype void = VOID

 (* JSON Types *)
  datatype jsonTy 
    = ARRAYty of jsonTy
    | BOOLty
    | DYNty
    | INTty
    | NULLty
    | RECORDty of (string * jsonTy) list
    | PARTIALRECORDty of (string * jsonTy) list
    | REALty
    | STRINGty

 (* Typed JSON Objects *)
  datatype json 
    = ARRAY of json list * jsonTy
    | BOOL of bool
    | INT of int
    | NULLObject
    | OBJECT of (string * json) list
    | REAL of real
    | STRING of string

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

  datatype 'a dyn 
    = DYN of (json -> 'a) * json

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
            foldr
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

  fun view (DYN (viewFn, json)) = viewFn json

  fun import src =
    let
      val uj = JSONParser.parse src
      val (tj, _) = infer uj
    in
      DYN (fn _ => raise AttemptToReturnVOIDValue, tj)
    end

  fun importForm src =
      DYN (fn _ => raise AttemptToReturnVOIDValue,
           OBJECT (map (fn (k,v) => (k, STRING v)) src))

  exception ReifiedtermToJson
  fun reifiedtermToJson reifiedterm =
      case reifiedterm of
        R.INTtyRep int => INT int
      | R.BOOLtyRep bool => BOOL bool
      | R.REALtyRep real => REAL real
      | R.STRINGtyRep string => STRING string
      | R.RECORDtyRep stringReifiedTermList => 
        OBJECT (map (fn (l, r) => (l,  reifiedtermToJson r)) stringReifiedTermList)
      | R.LISTtyRep reifiedTermList => 
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
      | R.INT64tyRep int64 => raise TypeIsNotJsonKind
      | R.INTINFtyRep int => raise TypeIsNotJsonKind
      | R.REAL32tyRep real => raise TypeIsNotJsonKind
      | R.CHARtyRep char => raise TypeIsNotJsonKind
      | R.WORDtyRep word => raise TypeIsNotJsonKind
      | R.WORD8tyRep word => raise TypeIsNotJsonKind
      | R.WORD64tyRep word => raise TypeIsNotJsonKind
      | R.EXNtyRep => raise TypeIsNotJsonKind
      | R.FUNtyRep => raise TypeIsNotJsonKind
      | R.PTRtyRep => raise TypeIsNotJsonKind
      | R.TUPLEtyRep reifiedTermList => raise TypeIsNotJsonKind
      | R.DATATYPEtyRep stringReifiedTermOption => raise TypeIsNotJsonKind
      | R.ARRAYtyRep {dummyPrinter, contentsFn} => raise TypeIsNotJsonKind
      | R.VECTORtyRep {dummyPrinter, contentsFn} => raise TypeIsNotJsonKind
      | R.UNITtyRep => raise TypeIsNotJsonKind
      | R.UNPRINTABLERep => raise TypeIsNotJsonKind
      | R.ELIPSISRep => raise TypeIsNotJsonKind
      | R.BUILTINRep => raise TypeIsNotJsonKind

  type dynamic = Dynamic.dynamic

  fun dynamicToJson dyn =
      let
        val reifiedTerm = DynamicPrinter.dynamicToReifiedTerm dyn
        val json = reifiedtermToJson reifiedTerm
        val string = 
            SMLFormat.prettyPrint 
              [SMLFormat.Columns 80]
              (ReifiedTerm.toJSON_reifiedTerm reifiedTerm)
      in
        {json = DYN (fn _ => raise AttemptToReturnVOIDValue,json), string=string}
      end


end
