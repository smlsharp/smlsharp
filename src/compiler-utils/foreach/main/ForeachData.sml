structure ForeachData =
struct

  open Myth
  structure Ivar = Concurrent.Ivar
  structure A = SMLSharp_Builtin.Array
  val cutOff = ForeachCommon.cutOff

  type index = int

  type 'a context =
      {
        value : index -> 'a,
        newValue : index -> 'a,
        size : int
      }

(*
  local
    val toIndex = SMLSharp_Builtin.Foreach.intToIndex
    val toInt = SMLSharp_Builtin.Foreach.indexToInt
  in
  fun wrap f (i, {value,newValue,size}) =
      f (toIndex i, {value = value o toInt,
                     newValue = newValue o toInt,
                     size = size})
  fun wrapInit f g x =
      f (toIndex o g) x
  fun wrapFini f g x =
      f (g o toInt) x
  end
*)

  fun spawn f =
      let
        val r = A.alloc_unsafe 1
      in
        (Thread.create (fn () => (A.update_unsafe (r, 0, f ()); 0)), r)
      end

  fun join (t, r) =
      (Thread.join t; A.sub_unsafe (r, 0))

  fun newGen (n : int) =
      (ref n, Mutex.create ())

  fun generate (r, m) =
      let
        val _ = Mutex.lock m
        val id = !r
        val _ = r := id + 1
        val _ = Mutex.unlock m
      in
        id
      end

  fun set ary nil = ()
    | set ary ((id,para)::t) = (Array.update (ary, id, para); set ary t)

  fun initLevel {init : ('a -> int) -> 'a -> 'b, gen} (seqs, paras) =
      let
        val items = ref nil
        fun nest seq =
            let val id = generate gen
            in items := (id, seq) :: !items; id
            end
        val paras =
            foldl (fn ((id:int,seq),z) => (id, init nest seq) :: z) paras seqs
      in
        (!items, paras)
      end

  fun initAll env dst depth (items as (seqs, paras)) =
      case seqs of
        nil => Thread.create (fn _ => (set (Ivar.get dst) paras; 0))
      | _::_ =>
        if depth < !cutOff
        then initAll env dst (depth + 1) (initLevel env items)
        else
          let
            val threads = map join (map (initSpawn env dst) seqs)
          in
            Thread.create
              (fn () => (set (Ivar.get dst) paras;
                         app (ignore o Thread.join) threads;
                         0))
          end

  and initSpawn env dst seq =
      spawn (fn _ => initAll env dst 0 ([seq], nil))

  fun initialize init seq =
      let
        val dst = Ivar.create ()
        val gen = newGen 1
        val env = {init = init, gen = gen}
        val t = join (initSpawn env dst (0, seq))
        val a = A.alloc (!(#1 gen)) handle Size => A.alloc_unsafe 0
        val _ = Ivar.set (dst, a)
        val _ = Thread.join t
      in
        a
      end

  fun finalize fini ary =
      let
        fun nest depth id =
            let
              val seq = Array.sub (ary, id)
            in
              if depth <= !cutOff
              then fini (nest (depth + 1)) seq
              else join (spawn (fn () => fini (nest 0) seq))
            end
      in
        nest 0 0
      end

  fun ForeachData {initialize=init, finalize=fini} data iterator pred =
      let
        val from = initialize init data
        val to = ForeachCommon.foreach
                   {from = from,
                    iterator = iterator,
                    pred = pred}
      in
        finalize fini to
      end

end
