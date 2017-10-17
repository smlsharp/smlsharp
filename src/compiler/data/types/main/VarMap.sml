structure VarOrd = 
  struct
     type ord_key = {longsymbol:Symbol.longsymbol,id:VarID.id}
     fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
         = VarID.compare (id1,id2)
   end

structure VarMap = BinaryMapFn (VarOrd)

structure VarSet = BinarySetFn (VarOrd)

