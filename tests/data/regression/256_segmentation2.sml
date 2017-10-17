structure KVS =
struct
  type kvs = string SEnv.map ref
  val KVS = ref SEnv.empty : kvs
  fun init () = KVS := SEnv.empty 
  fun get k =SEnv.find (!KVS, k)
  fun put (k,v) = KVS :=  SEnv.insert(!KVS, k, v)
end

