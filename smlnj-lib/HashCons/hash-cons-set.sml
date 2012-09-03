(* hash-cons-set.sml
 *
 * COPYRIGHT (c) 2001 Bell Labs, Lucent Technologies
 *
 * This is an implementation of the HASH_CONS_SET signature that is built
 * on top of the WordRedBlackMap structure.  Eventually, it will be replaced
 * by an implmementation that uses Patricia trees.
 *)

structure HashConsSet : HASH_CONS_SET =
  struct

    structure HC = HashCons
    structure Map = WordRedBlackMap

    type 'a obj = 'a HC.obj
    type 'a set = 'a obj Map.map

    val empty = Map.empty
    fun singleton obj = Map.singleton(HC.tag obj, obj)
    fun add  (set, obj) = Map.insert (set, HC.tag obj, obj)
    fun add' (obj, set) = Map.insert (set, HC.tag obj, obj)
    fun addList (set, l) = List.foldl add' set l
    fun delete (set : 'a set, obj) = #1(Map.remove(set, HC.tag obj))
    fun member (set, obj) = Map.inDomain(set, HC.tag obj)
    val isEmpty = Map.isEmpty
    fun equal (set1, set2) = (case Map.collate (fn _ => EQUAL) (set1, set2)
	   of EQUAL => true
	    | _ => false
	  (* end case *))
    fun compare arg = Map.collate (fn _ => EQUAL) arg

    fun isSubset _ = raise Fail "isSubset"

    val numItems = Map.numItems
    val listItems = Map.listItems
    fun union arg = Map.unionWith (fn (a, _) => a) arg
    fun intersection arg = Map.intersectWith (fn (a, _) => a) arg

    fun difference _ = raise Fail "difference"

    val map = Map.map
    val mapPartial = Map.mapPartial
    val app = Map.app
    val foldl = Map.foldl
    val foldr = Map.foldr

    fun partition _ = raise Fail "partition"

    val filter = Map.filter
    fun exists pred set = List.exists pred (listItems set)
    fun find pred set = List.find pred (listItems set)

  end
