(**
 * translation of built-in primitives into VM primitives.
 * @copyright (c) 2009, 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure VMPrimitive : sig

  datatype primImpl =
      Internal1 of Instructions.unaryInstructionCon
    | Internal2 of Instructions.binaryInstructionCon
    | External of string

  val primImpl : SymbolicInstructions.primitive -> primImpl

end =
struct

  structure P = BuiltinPrimitive
  structure S = SymbolicInstructions
  structure I = Instructions

  datatype primImpl =
      Internal1 of Instructions.unaryInstructionCon
    | Internal2 of Instructions.binaryInstructionCon
    | External of string

  fun external name =
      case name of
        "quotLargeInt" => Internal2 I.QuotLargeInt
      | "remLargeInt" => Internal2 I.RemLargeInt
      | "Internal_getCurrentIP" => Internal1 I.CurrentIP
      | "Internal_getStackTrace" => Internal1 I.StackTrace
      | s => External name

  fun primImpl (S.NAME name) = external name
    | primImpl (S.PRIM prim) =
      case prim of
        P.PolyEqual => Internal2 I.Equal
      | P.ObjectEqual => Internal2 I.Equal
      | P.PointerEqual => Internal2 I.Equal
      | P.Array_length => Internal1 I.Array_length
      | P.Byte_add => Internal2 I.AddByte
      | P.Byte_div => Internal2 I.DivByte
      | P.Byte_equal => Internal2 I.Equal
      | P.Byte_fromInt => Internal1 I.Byte_fromInt
      | P.Byte_gt => Internal2 I.GtByte
      | P.Byte_gteq => Internal2 I.GteqByte
      | P.Byte_lt => Internal2 I.LtByte
      | P.Byte_lteq => Internal2 I.LteqByte
      | P.Byte_mod => Internal2 I.ModByte
      | P.Byte_mul => Internal2 I.MulByte
      | P.Byte_sub => Internal2 I.SubByte
      | P.Byte_toIntX => Internal1 I.Byte_toIntX
      | P.Char_chr_unsafe => external "Char_chr"
      | P.Char_equal => Internal2 I.Equal
      | P.Char_gt => Internal2 I.GtChar
      | P.Char_gteq => Internal2 I.GteqChar
      | P.Char_lt => Internal2 I.LtChar
      | P.Char_lteq => Internal2 I.LteqChar
      | P.Char_ord => external "Char_ord"
      | P.Float_abs => Internal1 I.AbsFloat
      | P.Float_add => Internal2 I.AddFloat
      | P.Float_div => Internal2 I.DivFloat
      | P.Float_equal => external "Float_equal"
      | P.Float_fromInt => external "Float_fromInt"
      | P.Float_fromReal => external "Real_toFloat"
      | P.Float_gt => Internal2 I.GtFloat
      | P.Float_gteq => Internal2 I.GteqFloat
      | P.Float_lt => Internal2 I.LtFloat
      | P.Float_lteq => Internal2 I.LteqFloat
      | P.Float_mul => Internal2 I.MulFloat
      | P.Float_neg => Internal1 I.NegFloat
      | P.Float_sub => Internal2 I.SubFloat
      | P.Float_toReal => external "Real_fromFloat"
      | P.Float_trunc_unsafe _ => external "Float_trunc"
      | P.IntInf_abs => Internal1 I.AbsLargeInt
      | P.IntInf_add => Internal2 I.AddLargeInt
      | P.IntInf_div => Internal2 I.DivLargeInt
      | P.IntInf_equal => Internal2 I.Equal
      | P.IntInf_gt => Internal2 I.GtLargeInt
      | P.IntInf_gteq => Internal2 I.GteqLargeInt
      | P.IntInf_lt => Internal2 I.LtLargeInt
      | P.IntInf_lteq => Internal2 I.LteqLargeInt
      | P.IntInf_mod => Internal2 I.ModLargeInt
      | P.IntInf_mul => Internal2 I.MulLargeInt
      | P.IntInf_neg => Internal1 I.NegLargeInt
      | P.IntInf_sub => Internal2 I.SubLargeInt
      | P.Int_abs _ => Internal1 I.AbsInt
      | P.Int_add _ => Internal2 I.AddInt
      | P.Int_div _ => Internal2 I.DivInt
      | P.Int_equal => Internal2 I.Equal
      | P.Int_gt => Internal2 I.GtInt
      | P.Int_gteq => Internal2 I.GteqInt
      | P.Int_lt => Internal2 I.LtInt
      | P.Int_lteq => Internal2 I.LteqInt
      | P.Int_mod _ => Internal2 I.ModInt
      | P.Int_mul _ => Internal2 I.MulInt
      | P.Int_neg _ => Internal1 I.NegInt
      | P.Int_quot _ => Internal2 I.QuotInt
      | P.Int_rem _ => Internal2 I.RemInt
      | P.Int_sub _ => Internal2 I.SubInt
      | P.Ptr_advance => external "Ptr_advance"
      | P.Ptr_deref_int => external "UnmanagedMemory_subWord"
      | P.Ptr_deref_real => external "UnmanagedMemory_subReal"
      | P.Ptr_deref_float => external "UnmanagedMemory_subWord"
      | P.Ptr_deref_word => external "UnmanagedMemory_subWord"
      | P.Ptr_deref_char => external "UnmanagedMemory_sub"
      | P.Ptr_deref_byte => external "UnmanagedMemory_sub"
      | P.Ptr_deref_ptr => external "UnmanagedMemory_subWord"
      | P.Ptr_store_int => external "UnmanagedMemory_updateWord"
      | P.Ptr_store_real => external "UnmanagedMemory_updateReal"
      | P.Ptr_store_float => external "UnmanagedMemory_updateWord"
      | P.Ptr_store_word => external "UnmanagedMemory_updateWord"
      | P.Ptr_store_char => external "UnmanagedMemory_update"
      | P.Ptr_store_byte => external "UnmanagedMemory_update"
      | P.Ptr_store_ptr => external "UnmanagedMemory_updateWord"
      | P.Real_abs => Internal1 I.AbsReal
      | P.Real_add => Internal2 I.AddReal
      | P.Real_div => Internal2 I.DivReal
      | P.Real_equal => external "Real_equal"
      | P.Real_fromInt => external "Real_fromInt"
      | P.Real_gt => Internal2 I.GtReal
      | P.Real_gteq => Internal2 I.GteqReal
      | P.Real_lt => Internal2 I.LtReal
      | P.Real_lteq => Internal2 I.LteqReal
      | P.Real_mul => Internal2 I.MulReal
      | P.Real_neg => Internal1 I.NegReal
      | P.Real_sub => Internal2 I.SubReal
      | P.Real_trunc_unsafe _ => external "Real_trunc"
      | P.String_array => external "String_allocateMutable"
      | P.String_copy_unsafe => external "String_copy"
      | P.String_equal => Internal2 I.Equal
      | P.String_gt => Internal2 I.GtString
      | P.String_gteq => Internal2 I.GteqString
      | P.String_lt => Internal2 I.LtString
      | P.String_lteq => Internal2 I.LteqString
      | P.String_size => external "String_size"
      | P.String_sub_unsafe => external "String_sub"
      | P.String_update_unsafe => external "String_update"
      | P.String_vector => external "String_allocateImmutable"
      | P.Word_add => Internal2 I.AddWord
      | P.Word_andb => Internal2 I.Word_andb
      | P.Word_arshift => Internal2 I.Word_arithmeticRightShift
      | P.Word_div => Internal2 I.DivWord
      | P.Word_equal => Internal2 I.Equal
      | P.Word_fromInt => Internal1 I.Word_fromInt
      | P.Word_gt => Internal2 I.GtWord
      | P.Word_gteq => Internal2 I.GteqWord
      | P.Word_lshift => Internal2 I.Word_leftShift
      | P.Word_lt => Internal2 I.LtWord
      | P.Word_lteq => Internal2 I.LteqWord
      | P.Word_mod => Internal2 I.ModWord
      | P.Word_mul => Internal2 I.MulWord
      | P.Word_notb => Internal1 I.Word_notb
      | P.Word_orb => Internal2 I.Word_orb
      | P.Word_rshift => Internal2 I.Word_logicalRightShift
      | P.Word_sub => Internal2 I.SubWord
      | P.Word_toIntX => Internal1 I.Word_toIntX
      | P.Word_xorb => Internal2 I.Word_xorb

end
