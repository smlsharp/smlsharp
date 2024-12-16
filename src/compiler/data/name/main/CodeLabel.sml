(**
 * code labels used in a object file
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

signature CODE_LABEL =
sig
  type id
  val generate : Symbol.longsymbol -> id
  val derive : id -> id
  val eq : id * id -> bool
  val compare : id * id -> order
  val toString : id -> string
  val format_id : id -> SMLFormat.FormatExpression.expression list
  structure Map : ORD_MAP where type Key.ord_key = id
  structure Set : ORD_SET where type item = id
end

local

  structure CodeLabel =
  struct
  
    type id = int * string
                    
    val counter = ref 0
                      
    fun generate longsymbol =
        (!counter before counter := !counter + 1,
         case longsymbol of
           nil => ""
         | _ => NameMangle.mangle (Symbol.longsymbolToLongid longsymbol)) : id

    fun derive ((_, name):id) =
        (!counter before counter := !counter + 1, name) : id
                                                            
    fun eq (id1:id, id2:id) = #1 id1 = #1 id2
                                          
    fun compare (id1:id, id2:id) = Int.compare (#1 id1, #1 id2)
                                               
    (* toString preserves uniqueness *)
    fun toString (n, name) =
        case name of
            "" => "L" ^ Int.toString n
          | s => "L" ^ s ^ "_" ^ Int.toString n
                                        
    fun format_id id =
        let
          val s = toString id
        in
          [SMLFormat.FormatExpression.Term (size s, s)]
        end
          
    structure Key =
    struct
      type ord_key = id
      val compare = compare
    end

    structure Map = BinaryMapFn(Key)
    structure Set = BinarySetFn(Key)
                               
  end

in

(*
structure FunEntryLabel :> CODE_LABEL = CodeLabel
structure CallbackEntryLabel :> CODE_LABEL = CodeLabel
structure FunLocalLabel :> CODE_LABEL = CodeLabel
structure HandlerLabel :> CODE_LABEL = CodeLabel
structure DataLabel :> CODE_LABEL = CodeLabel
structure ExtraDataLabel :> CODE_LABEL = CodeLabel
*)
structure FunEntryLabel = CodeLabel
structure CallbackEntryLabel = CodeLabel
structure FunLocalLabel = CodeLabel
structure HandlerLabel =
struct
  open CodeLabel
  fun asFunLocalLabel (id:id) : id = id
end
structure DataLabel = CodeLabel
structure ExtraDataLabel = CodeLabel

end (* local *)
