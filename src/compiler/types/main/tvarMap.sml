structure TvarMap =
BinaryMapFn
  (struct
   type ord_key = {name:string,id:TvarID.id,eq:Absyn.eq,lifted:bool}
   fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
       = TvarID.compare (id1,id2)
   end)

structure TvarSet =
BinarySetFn
  (struct
   type ord_key = {name:string,id:TvarID.id,eq:Absyn.eq,lifted:bool}
   fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
       = TvarID.compare (id1,id2)
   end)
