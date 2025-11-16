(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure Dynamic = 
struct
  exception RuntimeTypeError = PartialDynamic.RuntimeTypeError
  exception Format
  exception JSONError of string
  type 'a dyn = 'a ReifiedTerm.dyn
  type void = ReifiedTy.void
  type dynamic = void dyn
  datatype term = datatype ReifiedTerm.reifiedTerm
  datatype ty = datatype ReifiedTy.reifiedTy
  open PrintControl
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
      RECORD stringTermList

  fun RecordTermToKeyListValueList term =
      case term of
        RECORD termMap =>
        foldr
          (fn ((label, term), (LabelStringList,TermStringList)) =>
              (label :: LabelStringList,
               termToString term :: TermStringList))
          (nil,nil)
          termMap
      | _ => (nil, nil)

  fun RecordTermToSQLValueList term =
      let
        fun quoteToSqlQuote s =
            String.translate (fn #"'" => "''" | c => String.str c) s
        fun toSqlMinus s =
            String.translate (fn #"~" => "-" | c => String.str c) s
        fun termToSqlValue term = 
            case term of 
              STRING string => "'" ^ (quoteToSqlQuote string) ^ "'"
            | INT32 int => toSqlMinus (Int32.toString int) 
            | INT16 int => toSqlMinus (Int16.toString int) 
            | INT64 int => toSqlMinus (Int64.toString int) 
            | INT8 int => toSqlMinus (Int8.toString int) 
            | _ => termToString term
      in            
        case term of
          RECORD termMap =>
          foldr
            (fn ((label, term), TermStringList) =>
                termToSqlValue term :: TermStringList)
            nil
            termMap
        | _ => nil
      end

  fun RecordTy stringTyList = 
      RECORDty stringTyList
  fun ## string dynamic = 
      termToDynamic
        (case dynamicToTerm dynamic of
           RECORD termMap => 
           (case List.find (fn (l, _) => l = string) termMap of
              SOME (_, term) => term
            | NONE => NULL)
         | _ => NULL)

  fun #> (string, elem) dynamic = 
      termToDynamic
        (case dynamicToTerm dynamic of
           RECORD termMap => 
           RECORD (SEnv.listItemsi (SEnv.insert
                     (ReifiedTy.toSEnv termMap, string, dynamicToTerm elem)))
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

  fun dynamic x = ReifiedTerm.toDynamic (ReifyTerm.toReifiedTerm x)
  fun view x = PartialDynamic.viewDynamic x

  fun toJson dyn = ReifiedTerm.reifiedTermToJSON (ReifiedTerm.toReifiedTerm dyn)

  fun jsonToReifiedTerm json =
      case json of
        JSON.BOOL bool => ReifiedTerm.BOOL bool
      | JSON.INT int => ReifiedTerm.INT32 (IntInf.toInt int)
      | JSON.FLOAT real => ReifiedTerm.REAL64 real
      | JSON.STRING string => ReifiedTerm.STRING string
      | JSON.NULL => ReifiedTerm.NULL  
      | JSON.ARRAY jsonList => ReifiedTerm.LIST (map jsonToReifiedTerm jsonList)
      | JSON.OBJECT stringJsonList =>
        ReifiedTerm.RECORD
          (map (fn (l, json) => (l, jsonToReifiedTerm json)) stringJsonList)

  fun jsonToDynamic json =
      ReifiedTerm.toDynamic (jsonToReifiedTerm json)

  fun fromJson string =
      jsonToDynamic (JSONParser.parse (JSONParser.openString string)
                     handle Fail s => raise JSONError s)

  fun fromJsonFile string =
      jsonToDynamic (JSONParser.parseFile string
                     handle Fail s => raise JSONError s)

  fun ('a#reify#{},'b#reify) ### (label:string) (record:'a)  =
      let
        val ty = #reifiedTy (_reifyTy('a))
        val elemTySpec = #reifiedTy (_reifyTy('b))
        val elemTy = 
             case ty of
               ReifiedTy.RECORDty fieldTy =>
               (case List.find (fn (l,_) => l = label) fieldTy of
                  SOME (_, ty) => ty
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
                      (case List.find (fn (l,_) => l = label) fields of
                         SOME (_, term) => term
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
  fun tagOf x = 
      case String.tokens (fn x => x = #" ") (format x) 
       of h::_ => h | _ => raise Format
  fun tagAndValue x = 
      case String.tokens (fn x => x = #" ") (format x) 
       of h1::h2::_ => (h1,h2) | _ => raise Format
  fun pp x =
      (SMLFormat.prettyPrint
         [SMLFormat.OutputFunction TextIO.print,
          SMLFormat.Columns (!printWidth)]
         (ReifiedTerm.format_reifiedTerm
            (dynamicToTerm
               (ReifiedTerm.toDynamic
                  (ReifyTerm.toReifiedTermPrint (!printMaxDepth) x))));
       TextIO.print "\n")
  fun debugPrint x = if !Bug.debugPrint then pp x else ()
  fun greaterEq (a,b)  = NaturalJoin.greaterEq (dynamicToTerm a, dynamicToTerm b)
  val project = RecordUtils.project
  val nest = RecordUtils.nest
end
