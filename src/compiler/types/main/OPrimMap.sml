structure OPrimOrd =
  struct
    type ord_key = {longsymbol:Symbol.longsymbol, id:OPrimID.id}
    fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
        = OPrimID.compare (id1,id2)
  end
structure OPrimMap = BinaryMapFn (OPrimOrd)
