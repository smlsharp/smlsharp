structure Dynamic = 
struct
  exception RuntimeTypeError = PartialDynamic.RuntimeTypeError
  type 'a dyn = 'a ReifiedTerm.dyn
  type void = ReifiedTy.void
  type dynamic = void dyn
  datatype term = datatype ReifiedTerm.reifiedTerm
  datatype ty = datatype ReifiedTy.reifiedTy
  fun termToDynamic term = ReifiedTerm.toDynamic term : dynamic 
  fun dynamicToTerm dyn = ReifiedTerm.toReifiedTerm dyn 
  fun termToString term = ReifiedTerm.reifiedTermToString term
  fun termToTy term = PartialDynamic.inferTy term
  fun dynamicToString dyn = termToString (dynamicToTerm dyn)
  fun dynamicToTy dyn = termToTy (dynamicToTerm dyn)
  fun tyToString term = ReifiedTy.reifiedTyToString term
  fun dynamicToTyString dyn = tyToString (termToTy (dynamicToTerm dyn))

  val null = termToDynamic NULL
  val void = termToDynamic VOID
  fun nullWithTy reifiedTy =
      termToDynamic(NULL_WITHTy reifiedTy)
  fun voidWithTy reifiedTy =
      termToDynamic(VOID_WITHTy reifiedTy)
  fun Record stringTermList = 
      RECORD (foldl
                (fn ((string, term), fields) => 
                    RecordLabel.Map.insert(fields, RecordLabel.fromString string, term))
                RecordLabel.Map.empty
              stringTermList)

  fun RecordTermToKeyListValueList term =
      case term of
        RECORD termMap =>
        RecordLabel.Map.foldri 
          (fn (label, term, (LabelStringList,TermStringList)) =>
              (RecordLabel.toString label :: LabelStringList,
               termToString term :: TermStringList))
          (nil,nil)
          termMap
      | _ => (nil, nil)
  fun RecordTy stringTyList = 
      RECORDty (foldl
                  (fn ((string, ty), fields) => 
                      RecordLabel.Map.insert(fields, RecordLabel.fromString string, ty))
                  RecordLabel.Map.empty
                  stringTyList)
  fun ## string dynamic = 
      termToDynamic
        (case dynamicToTerm dynamic of
           RECORD termMap => 
           (case RecordLabel.Map.find(termMap, RecordLabel.fromString string) of
              SOME term => term
            | NONE => NULL)
         | _ => NULL)

  fun #> (string,value) dynamic = 
      termToDynamic
        (case dynamicToTerm dynamic of
           RECORD termMap => 
           RECORD (RecordLabel.Map.insert(termMap, RecordLabel.fromString string, value))
         | _ => VOID)

  fun join (d1, d2) = 
      termToDynamic (NaturalJoin.naturalJoin (dynamicToTerm d1, dynamicToTerm d2))

  fun extend (d1, d2) = 
      termToDynamic (NaturalJoin.extend (dynamicToTerm d1, dynamicToTerm d2))

  fun override (d1, d2) = 
      termToDynamic (NaturalJoin.override (dynamicToTerm d1, dynamicToTerm d2))

  fun Cons (value, dynamic) = 
      termToDynamic
      (case dynamicToTerm dynamic of
         LIST L => LIST (dynamicToTerm value :: L)
       | _ => VOID)

  val Nil = termToDynamic (LIST [])
  fun Hd dynamic = 
      termToDynamic
      (case dynamicToTerm dynamic of
         LIST (h::t) => h
       | _ => VOID)
  fun Tl dynamic = 
      termToDynamic
      (case dynamicToTerm dynamic of
         LIST (h::t) => LIST t
       | _ => VOID)

  fun dynamic x = ReifiedTerm.toDynamic (ReifyTerm.toReifiedTermPrint x)
  fun view x = PartialDynamic.viewDynamic x

  fun toJson dyn = ReifiedTerm.reifiedTermToJSON (ReifiedTerm.toReifiedTerm dyn)

  fun fromJson string = JSON.jsonToDynamic (JSON.parse string)
  fun fromJsonFile string = 
      let
        val jsonStream = TextIO.openIn string
        val json = TextIO.inputAll jsonStream
      in
        fromJson json
      end
      handle exn as IO.Io _ => raise exn

  fun ('a#reify#{},'b#reify) ### (label:string) (record:'a)  =
      let
        val label = RecordLabel.fromString label
        val ty = #reifiedTy (_reifyTy('a))
        val elemTySpec = #reifiedTy (_reifyTy('b))
        val elemTy = 
             case ty of
               ReifiedTy.RECORDty fieldTy =>
               (case RecordLabel.Map.find(fieldTy, label) of
                  SOME ty => ty
                | _ =>  raise RuntimeTypeError)
             | _ => raise RuntimeTypeError 
        val _ = if ReifiedTy.reifiedTyEq(elemTySpec, elemTy) then ()
                else raise RuntimeTypeError 
        val ty = 
            {conSetEnv = TypID.Map.empty,
             reifiedTy = elemTy
            }
        val term = dynamicToTerm (dynamic record)
        val value = case term of 
                      RECORD fields =>
                      (case RecordLabel.Map.find (fields, label) of
                         SOME term => term
                       | _ => raise RuntimeTypeError)
                    |  _ => raise RuntimeTypeError
      in
        ReifiedTermToML.reifiedTermToMLWithTy value ty : 'b
      end
(*
  fun ('a#reify) isTy (x:'a -> unit) y = 
      (_dynamic y as 'a; true)
      handle RuntimeTypeError => false
*)

  fun valueToJson x = toJson (dynamic x)
  fun format x = dynamicToString (dynamic x)
  fun pp x = (TextIO.print (format x); TextIO.print  "\n")
  fun greaterEq (a,b)  = NaturalJoin.greaterEq (dynamicToTerm a, dynamicToTerm b)
end
