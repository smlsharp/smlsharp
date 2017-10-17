(* ohori 2013-4-28 
$ smlc -c 256_segmentation2.sml
$ smlc -c 256_segmentation.sml
$ smlc 256_segmentation.smi
$ ./a.out 
セグメンテーション違反です
sliced later.
*)

(* ohori 2013-08-07 
  再現しない．おそらくこれ以降の変更で修正されたとおもわれる．
  とりあえずfixedに移す．
*)

structure TypedKVS =
struct
  type key = string

  exception Bug
  exception KeyNotFound
  exception InvalidStore
  exception TypeMismatch

  val magic = "SML#KVS"
  fun typeKey k = k ^ "/type"
  fun valKey k = k ^ "/val"
  fun firstKey k = k ^ "/first"
  fun secondKey k = k ^ "/second"

  val intTy = "int"
  val boolTy = "bool"
  val stringTy = "string"
  val realTy = "real"
  val ptrTy = "ptr"
  val pairTy = "pair"

  fun id x = x
  val intMeta = 
      {
       ty = intTy,
       check = fn (_:key) => true,
       decoder = 
       fn x => case Int.fromString  x of
                 SOME v => v
               | NONE => raise Bug,
       encoder = fn x => Int.toString x
      }
  val boolMeta = 
      {
       ty = boolTy,
       check = fn (_:key) => true,
       decoder = 
       fn x => case Bool.fromString  x of
                 SOME v => v
               | NONE => raise Bug,
       encoder = fn x => Bool.toString x
      }
  val realMeta = 
      {
       ty = realTy,
       check = fn (_:key) => true,
       decoder = 
       fn x => case Real.fromString  x of
                 SOME v => v
               | NONE => raise Bug,
       encoder = fn x => Real.toString x
      }
  val stringMeta = 
      {
       ty = stringTy,
       check = fn (_:key) => true,
       decoder = id,
       encoder = id
      }

  fun ptrMeta meta =
      let
        fun init (key, value) =
            (KVS.put (key, magic);
             KVS.put (typeKey key, #ty meta);
             KVS.put (valKey key, #encoder meta value);
             key
            )
        fun find key =
            case KVS.get key of
              NONE => raise KeyNotFound
            | SOME magicVal => 
              if not (magicVal = magic) then
                raise InvalidStore
              else
                (case KVS.get (typeKey key) of
                   NONE => raise InvalidStore
                 | SOME typeval => 
                   if not (typeval = #ty meta) then
                     raise TypeMismatch
                   else key
                )
        fun check key =
            case KVS.get key of
              NONE => false
            | SOME magicVal => 
              (magicVal = magic) andalso
              (case KVS.get (typeKey key) of
                 NONE => false
               | SOME typeval =>  (typeval = #ty meta)
              )
        fun access key =
            {getVal =
             fn () =>
                case KVS.get (valKey key) of 
                  NONE => raise Bug
                | SOME v => #decoder meta v,
             putVal =
             fn v =>
                KVS.put(valKey key, #encoder meta v)
            }
      in
        {
         ty = ptrTy,
         init = init,
         check = check,
         find = find,
         encoder = fn (x:key) => x,
         decoder = fn (x:key) => x,
         access = access
        }
      end

  val intPtrMeta    = ptrMeta intMeta
  val boolPtrMeta   = ptrMeta boolMeta
  val stringPtrMeta = ptrMeta stringMeta
  val realPtrMeta   = ptrMeta realMeta

  fun pairMeta (firstMeta, secondMeta) =
      let
        fun init (key, (v1, v2)) =
            (KVS.put (key, magic);
             KVS.put (typeKey key, pairTy);
             KVS.put (firstKey key, #encoder firstMeta v1);
             KVS.put (secondKey key, #encoder secondMeta v2);
             key
            )
        fun find key =
            case KVS.get key of
              NONE => raise KeyNotFound
            | SOME magicVal => 
              if magicVal = magic then
                case KVS.get (typeKey key) of
                  NONE => raise InvalidStore
                | SOME typeval =>
                  if typeval = pairTy then
                    key
                  else raise TypeMismatch
              else raise InvalidStore
        fun check key =
            case KVS.get key of
              NONE => false
            | SOME magicVal => 
              (magicVal = magic) andalso
              (case KVS.get (typeKey key) of
                 NONE => false
               | SOME typeval =>  (typeval = pairTy)
              )
        fun access key =
            {
             key = key,
             getFirst =
             fn () =>
                case KVS.get (firstKey key) of 
                  NONE => raise Bug
                | SOME v =>
                  if #check firstMeta v then #decoder firstMeta v
                  else raise TypeMismatch,
             getSecond =
             fn () =>
                case KVS.get (secondKey key) of 
                  NONE => raise Bug
                | SOME v =>
                  if #check secondMeta v then #decoder secondMeta v
                  else raise TypeMismatch,
             putFirst = fn v => KVS.put(firstKey key, #encoder firstMeta v),
             putSecond = fn v => KVS.put(secondKey key, #encoder secondMeta v)
            }
      in
        {
         ty = pairTy,
         init = init,
         check = check,
         find = find,
         access = access,
         encoder = fn (x:key) => x,
         decoder = fn (x:key) => x
        }
      end

  fun create meta (key, value) =
      let
        val key = #init meta (key, value)
      in
        #access meta key
      end
end

val a = TypedKVS.create TypedKVS.intPtrMeta ("k1",99)
val b = #getVal a ()
val _ = print (Int.toString b)
val _ = #putVal a 88
val c = #getVal a ()
val _ = print (Int.toString c)
val a = TypedKVS.create 
        (TypedKVS.pairMeta (TypedKVS.intMeta, TypedKVS.boolMeta)) 
        ("k2", (10,true))

