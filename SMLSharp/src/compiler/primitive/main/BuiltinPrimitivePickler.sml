(* -*- sml -*- *)
(**
 * built-in primitive pickler.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
structure BuiltinPrimitivePickler : sig

  val specialForm : BuiltinPrimitive.specialForm Pickle.pu
  val primitive : BuiltinPrimitive.primitive Pickle.pu
  val prim_or_special : BuiltinPrimitive.prim_or_special Pickle.pu

end =
struct

  structure P = BuiltinPrimitive

  fun ov false = P.NoOverflowCheck
    | ov true = P.OverflowCheck
  fun b P.NoOverflowCheck = false
    | b P.OverflowCheck = true

  datatype prim =
      T of int * string
    | O of int * BuiltinPrimitive.ov_
    | N of int
    | X of BuiltinPrimitive.prim_or_special

  val prim =
      let
        fun toInt (T _) = 0
          | toInt (O _) = 1
          | toInt (N _) = 2
          | toInt (X x) = raise Control.Bug "BuiltinPrimitivePickler: X"
        fun pu_T pu =
            Pickle.con1 T (fn T x => x | _ => (~1,""))
                        (Pickle.tuple2 (Pickle.int, Pickle.string))
        fun pu_O pu =
            Pickle.con1 (fn (n, true) => O (n, P.OverflowCheck)
                          | (n, false) => O (n, P.NoOverflowCheck))
                        (fn O (n, P.OverflowCheck) => (n, true)
                          | O (n, P.NoOverflowCheck) => (n, false)
                          | _ => raise Control.Bug "pu_O")
                        (Pickle.tuple2 (Pickle.int, Pickle.bool))
        fun pu_N pu =
            Pickle.con1 N (fn N x => x | _ => ~1) Pickle.int
      in
        Pickle.data (toInt, [pu_T, pu_O, pu_N])
      end

  open BuiltinPrimitive

  fun conv p =
      case p of
        X(S Assign) => N 0 | N 0 => X(S Assign)
      | X(S Array_array) => N 1 | N 1 => X(S Array_array)
      | X(S Array_vector) => N 2 | N 2 => X(S Array_vector)
      | X(S Array_sub_unsafe) => N 3 | N 3 => X(S Array_sub_unsafe)
      | X(S Array_update_unsafe) => N 4 | N 4 => X(S Array_update_unsafe)
      | X(S Array_copy_unsafe) => N 5 | N 5 => X(S Array_copy_unsafe)
      | X(P (RuntimePrim s)) => T(6,s) | T(6,s) => X(P (RuntimePrim s))
      | X(P PolyEqual) => N 7 | N 7 => X(P PolyEqual)
      | X(P ObjectEqual) => N 8 | N 8 => X(P ObjectEqual)
      | X(P PointerEqual) => N 9 | N 9 => X(P PointerEqual)
      | X(P Array_length) => N 10 | N 10 => X(P Array_length)
      | X(P Byte_add) => N 11 | N 11 => X(P Byte_add)
      | X(P Byte_div) => N 12 | N 12 => X(P Byte_div)
      | X(P Byte_equal) => N 13 | N 13 => X(P Byte_equal)
      | X(P Byte_fromInt) => N 14 | N 14 => X(P Byte_fromInt)
      | X(P Byte_gt) => N 15 | N 15 => X(P Byte_gt)
      | X(P Byte_gteq) => N 16 | N 16 => X(P Byte_gteq)
      | X(P Byte_lt) => N 17 | N 17 => X(P Byte_lt)
      | X(P Byte_lteq) => N 18 | N 18 => X(P Byte_lteq)
      | X(P Byte_mod) => N 19 | N 19 => X(P Byte_mod)
      | X(P Byte_mul) => N 20 | N 20 => X(P Byte_mul)
      | X(P Byte_sub) => N 21 | N 21 => X(P Byte_sub)
      | X(P Byte_toIntX) => N 22 | N 22 => X(P Byte_toIntX)
      | X(P Char_chr_unsafe) => N 23 | N 23 => X(P Char_chr_unsafe)
      | X(P Char_equal) => N 24 | N 24 => X(P Char_equal)
      | X(P Char_gt) => N 25 | N 25 => X(P Char_gt)
      | X(P Char_gteq) => N 26 | N 26 => X(P Char_gteq)
      | X(P Char_lt) => N 27 | N 27 => X(P Char_lt)
      | X(P Char_lteq) => N 28 | N 28 => X(P Char_lteq)
      | X(P Char_ord) => N 29 | N 29 => X(P Char_ord)
      | X(P Float_abs) => N 30 | N 30 => X(P Float_abs)
      | X(P Float_add) => N 31 | N 31 => X(P Float_add)
      | X(P Float_div) => N 33 | N 33 => X(P Float_div)
      | X(P Float_equal) => N 34 | N 34 => X(P Float_equal)
      | X(P Float_fromInt) => N 36 | N 36 => X(P Float_fromInt)
      | X(P Float_fromReal) => N 37 | N 37 => X(P Float_fromReal)
      | X(P Float_gt) => N 38 | N 38 => X(P Float_gt)
      | X(P Float_gteq) => N 39 | N 39 => X(P Float_gteq)
      | X(P Float_lt) => N 40 | N 40 => X(P Float_lt)
      | X(P Float_lteq) => N 41 | N 41 => X(P Float_lteq)
      | X(P Float_mul) => N 42 | N 42 => X(P Float_mul)
      | X(P Float_neg) => N 43 | N 43 => X(P Float_neg)
      | X(P Float_sub) => N 45 | N 45 => X(P Float_sub)
      | X(P Float_toReal) => N 46 | N 46 => X(P Float_toReal)
      | X(P (Float_trunc_unsafe v)) => O(47,v) | O(47,v) => X(P (Float_trunc_unsafe v))
      | X(P IntInf_abs) => N 48 | N 48 => X(P IntInf_abs)
      | X(P IntInf_add) => N 49 | N 49 => X(P IntInf_add)
      | X(P IntInf_div) => N 50 | N 50 => X(P IntInf_div)
      | X(P IntInf_equal) => N 51 | N 51 => X(P IntInf_equal)
      | X(P IntInf_gt) => N 52 | N 52 => X(P IntInf_gt)
      | X(P IntInf_gteq) => N 53 | N 53 => X(P IntInf_gteq)
      | X(P IntInf_lt) => N 54 | N 54 => X(P IntInf_lt)
      | X(P IntInf_lteq) => N 55 | N 55 => X(P IntInf_lteq)
      | X(P IntInf_mod) => N 56 | N 56 => X(P IntInf_mod)
      | X(P IntInf_mul) => N 57 | N 57 => X(P IntInf_mul)
      | X(P IntInf_neg) => N 58 | N 58 => X(P IntInf_neg)
      | X(P IntInf_sub) => N 59 | N 59 => X(P IntInf_sub)
      | X(P (Int_abs v)) => O(60,v) | O(60,v) => X(P (Int_abs v))
      | X(P (Int_add v)) => O(61,v) | O(61,v) => X(P (Int_add v))
      | X(P (Int_div v)) => O(62,v) | O(62,v) => X(P (Int_div v))
      | X(P Int_equal) => N 63 | N 63 => X(P Int_equal)
      | X(P Int_gt) => N 64 | N 64 => X(P Int_gt)
      | X(P Int_gteq) => N 65 | N 65 => X(P Int_gteq)
      | X(P Int_lt) => N 66 | N 66 => X(P Int_lt)
      | X(P Int_lteq) => N 67 | N 67 => X(P Int_lteq)
      | X(P (Int_mod v)) => O(68,v) | O(68,v) => X(P (Int_mod v))
      | X(P (Int_mul v)) => O(69,v) | O(69,v) => X(P (Int_mul v))
      | X(P (Int_neg v)) => O(70,v) | O(70,v) => X(P (Int_neg v))
      | X(P (Int_quot v)) => O(71,v) | O(71,v) => X(P (Int_quot v))
      | X(P (Int_rem v)) => O(72,v) | O(72,v) => X(P (Int_rem v))
      | X(P (Int_sub v)) => O(73,v) | O(73,v) => X(P (Int_sub v))
      | X(P Ptr_advance) => N 74 | N 74 => X(P Ptr_advance)
      | X(P Ptr_deref_int) => N 75 | N 75 => X(P Ptr_deref_int)
      | X(P Ptr_deref_real) => N 76 | N 76 => X(P Ptr_deref_real)
      | X(P Ptr_deref_float) => N 77 | N 77 => X(P Ptr_deref_float)
      | X(P Ptr_deref_word) => N 78 | N 78 => X(P Ptr_deref_word)
      | X(P Ptr_deref_char) => N 79 | N 79 => X(P Ptr_deref_char)
      | X(P Ptr_deref_byte) => N 80 | N 80 => X(P Ptr_deref_byte)
      | X(P Ptr_deref_ptr) => N 81 | N 81 => X(P Ptr_deref_ptr)
      | X(P Ptr_store_int) => N 82 | N 82 => X(P Ptr_store_int)
      | X(P Ptr_store_real) => N 83 | N 83 => X(P Ptr_store_real)
      | X(P Ptr_store_float) => N 84 | N 84 => X(P Ptr_store_float)
      | X(P Ptr_store_word) => N 85 | N 85 => X(P Ptr_store_word)
      | X(P Ptr_store_char) => N 86 | N 86 => X(P Ptr_store_char)
      | X(P Ptr_store_byte) => N 87 | N 87 => X(P Ptr_store_byte)
      | X(P Ptr_store_ptr) => N 88 | N 88 => X(P Ptr_store_ptr)
      | X(P Real_abs) => N 89 | N 89 => X(P Real_abs)
      | X(P Real_add) => N 90 | N 90 => X(P Real_add)
      | X(P Real_div) => N 91 | N 91 => X(P Real_div)
      | X(P Real_equal) => N 92 | N 92 => X(P Real_equal)
      | X(P Real_fromInt) => N 93 | N 93 => X(P Real_fromInt)
      | X(P Real_gt) => N 94 | N 94 => X(P Real_gt)
      | X(P Real_gteq) => N 95 | N 95 => X(P Real_gteq)
      | X(P Real_lt) => N 96 | N 96 => X(P Real_lt)
      | X(P Real_lteq) => N 97 | N 97 => X(P Real_lteq)
      | X(P Real_mul) => N 98 | N 98 => X(P Real_mul)
      | X(P Real_neg) => N 99 | N 99 => X(P Real_neg)
      | X(P Real_sub) => N 100 | N 100 => X(P Real_sub)
      | X(P (Real_trunc_unsafe v)) => O(101,v)
      | O(101,v) => X(P (Real_trunc_unsafe v))
      | X(P String_array) => N 102 | N 102 => X(P String_array)
      | X(P String_copy_unsafe) => N 103 | N 103 => X(P String_array)
      | X(P String_equal) => N 104 | N 104 => X(P String_equal)
      | X(P String_gt) => N 105 | N 105 => X(P String_gt)
      | X(P String_gteq) => N 106 | N 106 => X(P String_gteq)
      | X(P String_lt) => N 107 | N 107 => X(P String_lt)
      | X(P String_lteq) => N 108 | N 108 => X(P String_lteq)
      | X(P String_size) => N 109 | N 109 => X(P String_size)
      | X(P String_sub_unsafe) => N 110 | N 110 => X(P String_sub_unsafe)
      | X(P String_update_unsafe) => N 111 | N 111 => X(P String_update_unsafe)
      | X(P String_vector) => N 112 | N 112 => X(P String_vector)
      | X(P Word_add) => N 113 | N 113 => X(P Word_add)
      | X(P Word_andb) => N 114 | N 114 => X(P Word_andb)
      | X(P Word_arshift) => N 115 | N 115 => X(P Word_arshift)
      | X(P Word_div) => N 116 | N 116 => X(P Word_div)
      | X(P Word_equal) => N 117 | N 117 => X(P Word_equal)
      | X(P Word_fromInt) => N 118 | N 118 => X(P Word_fromInt)
      | X(P Word_gt) => N 119 | N 119 => X(P Word_gt)
      | X(P Word_gteq) => N 120 | N 120 => X(P Word_gteq)
      | X(P Word_lshift) => N 121 | N 121 => X(P Word_lshift)
      | X(P Word_lt) => N 122 | N 122 => X(P Word_lt)
      | X(P Word_lteq) => N 123 | N 123 => X(P Word_lteq)
      | X(P Word_mod) => N 124 | N 124 => X(P Word_mod)
      | X(P Word_mul) => N 125 | N 125 => X(P Word_mul)
      | X(P Word_notb) => N 126 | N 126 => X(P Word_notb)
      | X(P Word_orb) => N 127 | N 127 => X(P Word_orb)
      | X(P Word_rshift) => N 128 | N 128 => X(P Word_rshift)
      | X(P Word_sub) => N 129 | N 129 => X(P Word_sub)
      | X(P Word_toIntX) => N 130 | N 130 => X(P Word_toIntX)
      | X(P Word_xorb) => N 131 | N 131 => X(P Word_xorb)
      | X(S List_first) => N 132 | N 132 => X(S List_first)
      | X(S Array_first) => N 133 | N 133 => X(S Array_first)
      | X(S List_second) => N 134 | N 134 => X(S List_first)
      | X(S Array_second) => N 135 | N 135 => X(S Array_first)
      | X(S Int_first) => N 136 | N 136 => X(S Int_first)
      | X(S Real_second) => N 137 | N 137 => X(S Real_second)
      | T (n,_) => raise Control.Bug ("T "^Int.toString n)
      | O (n,_) => raise Control.Bug ("O "^Int.toString n)
      | N n => raise Control.Bug ("N "^Int.toString n)

  val prim_or_special =
      Pickle.conv
          (fn x => case conv x of X p => p | _ => raise Control.Bug "conv",
           fn x => conv (X x))
          prim

  val primitive =
      Pickle.conv
          (fn P.P x => x | P.S _ => raise Control.Bug "primitive", P.P)
          prim_or_special

  val specialForm =
      Pickle.conv
          (fn P.S x => x | P.P _ => raise Control.Bug "specialForm", P.S)
          prim_or_special

end
