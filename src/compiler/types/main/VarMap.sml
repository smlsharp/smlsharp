structure VarMap = 
BinaryMapFn
  (struct
   type ord_key = {path:string list,id:VarID.id}
   fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
       = VarID.compare (id1,id2)
   end)

structure VarSet = 
BinarySetFn
  (struct
   type ord_key = {path:string list,id:VarID.id}
   fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
       = VarID.compare (id1,id2)
   end)

