(* -*- sml -*- *)
(**
 * built-in primitive utils.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
structure BuiltinPrimitiveUtils : sig

  val raisesException : BuiltinPrimitive.primitive -> string list
  val hasEffect : BuiltinPrimitive.primitive -> bool

  (* for backward compatibility *)
  val oldPrimitiveName : BuiltinPrimitive.primitive -> string

end =
struct

  structure P = BuiltinPrimitive

  fun raisesException (P.RuntimePrim name) =
      if #hasEffect (Primitives.findPrimitive name)
      then ["Unknown"]  (* dummy *)
      else nil
    | raisesException prim = #exn (BuiltinPrimitiveInfo.primitive_info prim)

  fun hasEffect (P.RuntimePrim name) =
      #hasEffect (Primitives.findPrimitive name)
    | hasEffect prim =
      #effect (BuiltinPrimitiveInfo.primitive_info prim)

  (* for backward compatibility *)
  fun oldPrimitiveName prim =
      case P.P prim of
        P.S P.Assign => ":="
      | P.S P.Array_first => "Array_first"
      | P.S P.List_first => "List_first"
      | P.S P.Int_first => "Int_first"
      | P.S P.Real_second => "Real_second"
      | P.S P.Array_second => "Array_second"
      | P.S P.List_second => "List_second"
      | P.S P.Array_sub_unsafe => "Array_sub"
      | P.S P.Array_update_unsafe => "Array_update"
      | P.S P.Array_vector => "Array_immutableArray"
      | P.S P.Array_array => raise Control.Bug "oldPrimitiveName: Array_array"
      | P.S P.Array_copy_unsafe => "Array_copy"
      | P.P (P.RuntimePrim name) => name
      | P.P P.PolyEqual => "="
      | P.P P.ObjectEqual => "="  (* overloaded *)
      | P.P P.PointerEqual => "="  (* overloaded *)
      | P.P P.Array_length => "Array_length"
      | P.P P.Byte_add => "addByte"
      | P.P P.Byte_div => "divByte"
      | P.P P.Byte_equal => "="     (* overloaded *)
      | P.P P.Byte_fromInt => "Byte_fromInt"
      | P.P P.Byte_gt => "gtByte"
      | P.P P.Byte_gteq => "gteqByte"
      | P.P P.Byte_lt => "ltByte"
      | P.P P.Byte_lteq => "lteqByte"
      | P.P P.Byte_mod => "modByte"
      | P.P P.Byte_mul => "mulByte"
      | P.P P.Byte_sub => "subByte"
      | P.P P.Byte_toIntX => "Byte_toIntX"
      | P.P P.Char_chr_unsafe => "Char_chr"
      | P.P P.Char_equal => "="     (* overloaded *)
      | P.P P.Char_gt => "gtChar"
      | P.P P.Char_gteq => "gteqChar"
      | P.P P.Char_lt => "ltChar"
      | P.P P.Char_lteq => "lteqChar"
      | P.P P.Char_ord => "Char_ord"
      | P.P P.Float_abs => "absFloat"
      | P.P P.Float_add => "addFloat"
      | P.P P.Float_div => "divFloat"
      | P.P P.Float_equal => "Float_equal"
      | P.P P.Float_fromInt => "Float_fromInt"
      | P.P P.Float_fromReal => "Real_toFloat"
      | P.P P.Float_gt => "gtFloat"
      | P.P P.Float_gteq => "gteqFloat"
      | P.P P.Float_lt => "ltFloat"
      | P.P P.Float_lteq => "lteqFloat"
      | P.P P.Float_mul => "mulFloat"
      | P.P P.Float_neg => "negFloat"
      | P.P P.Float_sub => "subFloat"
      | P.P P.Float_toReal => "Real_fromFloat"
      | P.P (P.Float_trunc_unsafe _) => "Float_trunc"
      | P.P P.IntInf_abs => "absLargeInt"
      | P.P P.IntInf_add => "addLargeInt"
      | P.P P.IntInf_div => "divLargeInt"
      | P.P P.IntInf_equal => "="       (* overloaded *)
      | P.P P.IntInf_gt => "gtLargeInt"
      | P.P P.IntInf_gteq => "gteqLargeInt"
      | P.P P.IntInf_lt => "ltLargeInt"
      | P.P P.IntInf_lteq => "lteqLargeInt"
      | P.P P.IntInf_mod => "modLargeInt"
      | P.P P.IntInf_mul => "mulLargeInt"
      | P.P P.IntInf_neg => "negLargeInt"
      | P.P P.IntInf_sub => "subLargeInt"
      | P.P (P.Int_abs _) => "absInt"
      | P.P (P.Int_add _) => "addInt"
      | P.P (P.Int_div _) => "divInt"
      | P.P P.Int_equal => "="       (* overloaded *)
      | P.P P.Int_gt => "gtInt"
      | P.P P.Int_gteq => "gteqInt"
      | P.P P.Int_lt => "ltInt"
      | P.P P.Int_lteq => "lteqInt"
      | P.P (P.Int_mod _) => "modInt"
      | P.P (P.Int_mul _) => "mulInt"
      | P.P (P.Int_neg _) => "negInt"
      | P.P (P.Int_quot _) => "quotInt"
      | P.P (P.Int_rem _) => "remInt"
      | P.P (P.Int_sub _) => "subInt"
      | P.P P.Ptr_advance => raise Control.Bug "oldPrimitiveName: Ptr_advance"
      | P.P P.Ptr_deref_int => "UnmanagedMemory_subInt"
      | P.P P.Ptr_deref_real => "UnmanagedMemory_subReal"
      | P.P P.Ptr_deref_float => "UnmanagedMemory_subFloat"
      | P.P P.Ptr_deref_word => "UnmanagedMemory_subWord"
      | P.P P.Ptr_deref_char => "UnmanagedMemory_sub"
      | P.P P.Ptr_deref_byte => "UnmanagedMemory_sub"  (* overloaded *)
      | P.P P.Ptr_deref_ptr => "UnmanagedMemory_subPtr"
      | P.P P.Ptr_store_int => "UnmanagedMemory_updateInt"
      | P.P P.Ptr_store_real => "UnmanagedMemory_updateReal"
      | P.P P.Ptr_store_float => "UnmanagedMemory_updateFloat"
      | P.P P.Ptr_store_word => "UnmanagedMemory_updateWord"
      | P.P P.Ptr_store_char => "UnmanagedMemory_update"
      | P.P P.Ptr_store_byte => "UnmanagedMemory_update"  (* overloaded *)
      | P.P P.Ptr_store_ptr => "UnmanagedMemory_updatePtr"
      | P.P P.Real_abs => "absReal"
      | P.P P.Real_add => "addReal"
      | P.P P.Real_div => "/"
      | P.P P.Real_equal => "Real_equal"
      | P.P P.Real_fromInt => "Real_fromInt"
      | P.P P.Real_gt => "gtReal"
      | P.P P.Real_gteq => "gteqReal"
      | P.P P.Real_lt => "ltReal"
      | P.P P.Real_lteq => "lteqReal"
      | P.P P.Real_mul => "mulReal"
      | P.P P.Real_neg => "negReal"
      | P.P P.Real_sub => "subReal"
      | P.P (P.Real_trunc_unsafe _) => "Real_trunc"
      | P.P P.String_array => "String_allocateMutable"
      | P.P P.String_copy_unsafe => "String_copy"
      | P.P P.String_equal => "="  (* overloaded *)
      | P.P P.String_gt => "gtString"
      | P.P P.String_gteq => "gteqString"
      | P.P P.String_lt => "ltString"
      | P.P P.String_lteq => "lteqString"
      | P.P P.String_size => "String_size"
      | P.P P.String_sub_unsafe => "String_sub"
      | P.P P.String_update_unsafe => "String_update"
      | P.P P.String_vector => "String_allocateImmutable"
      | P.P P.Word_add => "addWord"
      | P.P P.Word_andb => "Word_andb"
      | P.P P.Word_arshift => "Word_arithmeticRightShift"
      | P.P P.Word_div => "divWord"
      | P.P P.Word_equal => "="          (* overloaded *)
      | P.P P.Word_fromInt => "Word_fromInt"
      | P.P P.Word_gt => "gtWord"
      | P.P P.Word_gteq => "gteqWord"
      | P.P P.Word_lshift => "Word_leftShift"
      | P.P P.Word_lt => "ltWord"
      | P.P P.Word_lteq => "lteqWord"
      | P.P P.Word_mod => "modWord"
      | P.P P.Word_mul => "mulWord"
      | P.P P.Word_notb => "Word_notb"
      | P.P P.Word_orb => "Word_orb"
      | P.P P.Word_rshift => "Word_logicalRightShift"
      | P.P P.Word_sub => "subWord"
      | P.P P.Word_toIntX => "Word_toIntX"
      | P.P P.Word_xorb => "Word_xorb"

end
