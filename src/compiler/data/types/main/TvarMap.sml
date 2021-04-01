(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori 
 *)
structure TvarOrd =
struct
 type ord_key = {symbol:Symbol.symbol,id:TvarID.id,isEq:bool,lifted:bool}
 fun compare ({id=id1,...}:ord_key, {id=id2,...}:ord_key)
     = TvarID.compare (id1,id2)
end

structure TvarMap = BinaryMapFn(TvarOrd)
structure TvarSet = BinarySetFn(TvarOrd)
