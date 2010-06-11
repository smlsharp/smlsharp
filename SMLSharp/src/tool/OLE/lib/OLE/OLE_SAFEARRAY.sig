(**
 * OLE SAFEARRAY.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
signature OLE_SAFEARRAY =
sig

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

  (**
   * creates a safearray.
   * @params (dimensions, initial)
   * @param dimensions a list of dimensions.
   * @param initial a value stored in each slot in the created array.
   * @return a safearray.
   *)
  val array : (int list * 'a) -> 'a safearray

  (**
   * returns dimensions of the safearray.
   *)
  val lengths : 'a safearray -> int list
                                 
  (**
   * returns the array element specified by a list of indexes.
   * @params (array, indexes)
   * @param array an safearray
   * @param indexes a list of indexes.
   * @return array[hd indexes][hd (tl indexes)]...[hd (tl ... (tl indexes))]
   *)
  val sub : 'a safearray * int list -> 'a

  (**
   * sets the array element specified by a list of indexes.
   * @params (array, indexes, value)
   * @param array an safearray
   * @param indexes a list of indexes.
   * @param value stored in the array slot specified by indexes.
   *)
  val update : 'a safearray * int list * 'a -> unit

end;