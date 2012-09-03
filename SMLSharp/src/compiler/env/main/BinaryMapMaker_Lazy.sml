(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BinaryMapMaker_Lazy.sml,v 1.5 2008/08/06 02:20:19 ohori Exp $
 *)
functor BinaryMapMakerLazy(Key : ORD_KEY)
  : sig
      include ORD_MAP
      val fromList : (Key.ord_key * 'item) list -> 'item map
      val pu_map
          : (Key.ord_key Pickle.pu * 'value Pickle.pu) -> 'value map Pickle.pu
    end =
struct

  structure Key = Key
  structure M = BinaryMapFn(Key)
  structure P = Pickle

  datatype 'a value = V of 'a | Delayed of unit -> 'a
  type 'a map = 'a value ref M.map

  fun fix (ref (V v)) = v
    | fix (r as ref (Delayed f)) = let val v = f () in r := V v; v end
  val empty = M.empty : 'a map
  val isEmpty = M.isEmpty
  fun singleton (k, v) = M.singleton (k, ref (V v))
  fun insert (map, key, value) = M.insert (map, key, ref (V value))
  fun insert' ((key, value), map) = M.insert (map, key, ref (V value))
  fun find (map, key) = Option.map fix (M.find (map, key))
  fun inDomain (m, k) = M.inDomain (m, k)
  fun lookup arg = 
      raise Fail "Sorry, BinaryMapMaker.mergeWith not implemented."
  fun remove (map, key) =
      let val (m, v) = M.remove (map, key) in (m, fix v) end
  fun first m = Option.map fix (M.first m)
  fun firsti m = Option.map (fn (k, v) => (k, fix v)) (M.firsti m)
  fun numItems map = M.numItems map
  fun listItems map = List.map fix (M.listItems map)
  fun listItemsi map = List.map (fn (k, v) => (k, fix v)) (M.listItemsi map)
  fun listKeys m = M.listKeys m
  fun collate compare (m1, m2) =
      M.collate (fn (x, y) => compare (fix x, fix y)) (m1, m2)
  fun unionWith f (m1, m2) =
      M.unionWith (fn (x, y) => ref (V (f (fix x, fix y)))) (m1, m2)
  fun unionWithi f (m1, m2) =
      M.unionWithi (fn (k, x, y) => ref (V (f (k, fix x, fix y)))) (m1, m2)
  fun intersectWith f (m1, m2) =
      M.intersectWith (fn (x, y) => ref (V (f (fix x, fix y)))) (m1, m2)
  fun intersectWithi f (m1, m2) =
      M.intersectWithi (fn (k, x, y) => ref (V (f (k, fix x, fix y)))) (m1, m2)

  fun mergeWith f (m1, m2) =
      raise Fail "Sorry, BinaryMapMaker.mergeWith not implemented."
(*
      M.mergeWith
          (fn (x, y) => f (Option.map fix x, Option.map fix y)) (m1, m2)
*)
  fun mergeWithi f (m1, m2) =
      raise Fail "Sorry, BinaryMapMaker.mergeWithi not implemented."
(*
      M.mergeWithi
          (fn (k, x, y) => f (k, Option.map fix x, Option.map fix y)) (m1, m2)
*)
  fun app f m = M.app (f o fix) m
  fun appi f m = M.appi (fn (k, v) => f (k, fix v)) m
  fun map f m = M.map (ref o V o f o fix) m
  fun mapi f m = M.mapi (fn (k, v) => ref (V (f (k, fix v)))) m
  fun foldl f init m = M.foldl (fn (v, ac) => f (fix v, ac)) init m
  fun foldli f init m = M.foldli (fn (k, v, ac) => f (k, fix v, ac)) init m
  fun foldr f init m = M.foldr (fn (v, ac) => f (fix v, ac)) init m
  fun foldri f init m = M.foldri (fn (k, v, ac) => f (k, fix v, ac)) init m
  fun filter f m = M.filter (f o fix) m
  fun filteri f m = M.filteri (fn (k, v) => f (k, fix v)) m
  fun mapPartial f m = M.mapPartial (Option.map (ref o V) o f o fix) m
  fun mapPartiali f m =
      M.mapPartiali (fn (k, v) => Option.map (ref o V) (f (k, fix v))) m
  fun fromList list =
      List.foldl (fn ((key, item), m) => insert (m, key, item)) empty list

  fun pu_map (key_pu : Key.ord_key P.pu, value_pu : 'value P.pu) =
      let
        fun mapToList map =
            List.map
                (fn (key, ref (V v)) => (key, fn () => v)
                  | (key, ref (Delayed f)) => (key, f))
                (M.listItemsi map)
        fun listToMap list =
            List.foldl
                (fn ((key, f), map) => M.insert (map, key, ref (Delayed f)))
                M.empty
                list
      in
        P.conv
            (listToMap, mapToList)
            (P.list (P.tuple2 (key_pu, P.lazy value_pu)))
      end

end;
