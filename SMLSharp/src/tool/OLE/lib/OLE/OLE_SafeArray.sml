(**
 * OLE SAFEARRAY.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_SafeArray : OLE_SAFEARRAY =
struct

  (** flattened representation of OLE SAFEARRAY('a).
   * It corresponds to a variant which tag is (VT_ARRAY | (tag of 'a)).
   * <p>
   * The second component of the tuple is a list of numbers of elements of each
   * dimension.
   * For example, 
   * <code>(ar, [10, 20, 30]) : variant safearray</code>
   * corresponds to <code>VARIANT ar[10][20][30]</code> in C syntax.
   * </p>
   *)
  type 'a safearray = 'a array * int list

  val productOfInts = List.foldl (op * ) 1

  (**
   * For example,
   * <pre>
   * indexesToIndex [10, 20, 30] [1, 2, 3]
   * = (3 * (20 * 10) + 2 * 10 + 1))
   * = 621
   * </pre>
   *)
  fun indexesToIndex [] _ = raise General.Subscript
    | indexesToIndex _ [] = raise General.Subscript
    | indexesToIndex dimensions indexes =
      let
        fun accum value [] [] = value
          | accum value (dim::dims) (idx::idxs) =
            accum ((value * dim) + idx) dims idxs
          | accum _ _ _ = raise General.Subscript
        val rdims = List.rev dimensions
        val ridxs = List.rev indexes
      in
        accum (List.hd ridxs) (List.tl rdims) (List.tl ridxs)
      end

  fun array (dims, initial) = (Array.array(productOfInts dims, initial), dims)
  fun lengths (array, dims) = dims
  fun sub ((array, dims) : 'a safearray, indexes) =
      Array.sub(array, indexesToIndex dims indexes)
  fun update ((array, dims), indexes, value) =
      Array.update(array, indexesToIndex dims indexes, value)

end;