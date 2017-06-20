(**
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 * @author Daisuke Kikuchi
 *)
structure JSONParser =
struct
  exception ParseError of string
  datatype utJson =
      BOOL of bool
    | INT of int
    | REAL of real
    | STRING of string
    | NULL
    | ARRAY of utJson list
    | OBJECT of (string * utJson) list

  datatype stackItem =
      JSON of utJson
    | OBJ_KEY of string
    | OBJ_BEGIN
    | ARY_BEGIN
  type size_t = YAJL.size_t
  type ctx = stackItem list ref

  fun push (stack, item) = stack := item :: !stack

  fun (parseNull: ctx -> int) stack = (push (stack, JSON NULL); 1)

  fun (parseBool:ctx * int -> int) (stack, i) = 
    let
      val item = JSON (BOOL (i <> 0))
    in
      (push (stack, item); 1)
    end

  fun (parseInt:ctx * int64 -> int) (stack, i) =
      (push (stack, JSON (INT (Int64.toInt i))); 1)

  fun (parseDouble:ctx * real -> int) (stack, r) =
      (push (stack, JSON (REAL r)); 1)

  fun (parseYajlString:ctx * char ptr * size_t -> int) (stack, cp, n) =
    let
      val s = Pointer.importString cp
      val k = String.substring (s, 0, YAJL.size_tToInt n)
    in
      (push (stack, JSON (STRING k)); 1)
    end

  fun (parseObjectStart:ctx -> int) stack =
      (push (stack, OBJ_BEGIN); 1)

  fun (parseObjectKey:ctx * char ptr * size_t -> int) (stack, cp, n) =
    let
      val s = Pointer.importString cp
      val k = String.substring (s, 0, YAJL.size_tToInt n)
    in
      (push (stack, OBJ_KEY k); 1)
    end

  fun insert y kvl =
    case kvl of 
      x::kvs =>
        let
          val kx = #1 x
          val ky = #1 y
        in
          if (ky < kx) then y::(x::kvs)
          else x::(insert y kvs)
        end
    | [] => y::[]

  (* オブジェクトのフィールドをキーでソートする関数 *)
  fun sort kvl =
    case kvl of 
      y::kvs => insert y (sort kvs)
    | [] => []

  fun popObject xl stack =
    let
      fun popObject_aux xl (kl, vl) =
        case xl of
          x::xs => (
            case x of
              JSON j    => popObject_aux xs (kl, (j::vl))
            | OBJ_KEY s => popObject_aux xs ((s::kl), vl)
            | OBJ_BEGIN => (stack := xs; OBJECT (sort (ListPair.zip (kl, vl))))
            | ARY_BEGIN => raise ParseError "ARY_BEGIN before OBJ_BEGIN"
          )
        | [] => raise ParseError "Empty Stack in Object Parsing"
    in
      popObject_aux xl ([], [])
    end

  fun (parseObjectEnd:ctx -> int) stack = 
    let
      (* stackItem の先頭から OBJ_BEGIN までをpop *)
      val obj = popObject (!stack) stack
    in
      (* JSON (OBJECT ...) を push *)
      (stack := (JSON obj)::(!stack); 1)
    end

  fun (parseArrayStart:ctx -> int) stack = 
    (stack := ARY_BEGIN::(!stack); 1)

  fun popArray xl stack =
    let
      fun popArray_aux xl vl =
        case xl of
          x::xs => (
            case x of
              JSON j    => popArray_aux xs (j::vl)
            | OBJ_KEY _ => raise ParseError "OBJ_KEY before ARY_BEGIN"
            | OBJ_BEGIN => raise ParseError "OBJ_BEGIN before ARY_BEGIN"
            | ARY_BEGIN => (stack := xs; ARRAY vl)
          )
        | [] => raise ParseError "Empty Stack in Array Parsing"
    in
      popArray_aux xl []
    end

  fun (parseArrayEnd:ctx -> int) stack =
    let
      (* stackItem の先頭から ARY_BEGIN までをpop *)
      val ary = popArray (!stack) stack
    in
      (* JSON (ARRAY ...) を push *)
      (stack := (JSON ary)::(!stack); 1)
    end

  val yajlCallbacks = 
      {
       1_yajl_null = parseNull,
       2_yajl_boolean = parseBool,
       3_yajl_integer = parseInt,
       4_yajl_double = parseDouble,
       5_yajl_number = Pointer.NULL (),
       6_yajl_string = parseYajlString,
       7_yajl_start_map = parseObjectStart,
       8_yajl_map_key = parseObjectKey,
       9_yajl_end_map = parseObjectEnd,
       10_yajl_start_array =parseArrayStart,
       11_yajl_end_array = parseArrayEnd
      }

  fun printYajlError (hndl, src) =
      let
        val err = YAJL.yajl_get_error(hndl, 0, src, YAJL.intToSize_t (String.size src))
        val errText = Pointer.importString err
        val _ = YAJL.yajl_free_error(hndl, err)
      in
        errText
      end

  (* parse : string -> utJson *)
  fun parse src =
    let
      val stack = ref nil
      val hndl = YAJL.yajl_alloc (yajlCallbacks, Pointer.NULL (), stack)
      val st = YAJL.yajl_parse (hndl, src, YAJL.intToSize_t (String.size src))
      val _ = 
        case st of
          0 => YAJL.yajl_complete_parse hndl
        | 1 => raise ParseError (printYajlError (hndl, src))
        | 2 => raise ParseError (printYajlError (hndl, src))
        | _ => raise ParseError (printYajlError (hndl, src))

      val _ = YAJL.yajl_free hndl

      val jv = List.hd (!stack)

      val res =
        case jv of
          JSON v => v
        | _ => raise ParseError "Final state is not single JSON"
    in
      res
    end
end
