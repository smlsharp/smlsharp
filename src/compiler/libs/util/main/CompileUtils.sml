(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure CompileUtils =
struct

  (*
    equivalent to the following but optimized:
      fun compileList env nil = (ret, nil)
        | compileList env (src :: srcs) =
          let
            val (ret1, dst) = compile env src
            val (ret2, dsts) = compile (extend (env, ret1)) srcs
          in
            (accum (ret1, ret2), det :: dsts)
          end
  *)
  fun ('env#boxed, 'src#boxed, 'ret#boxed, 'dst#boxed)
      compileList'
      {extend : 'env * 'ret -> 'env,
       accum : 'ret * 'ret -> 'ret,
       empty : 'ret}
      (compile : 'env -> 'src -> 'ret * 'dst)
      env
      srcs =
      let
        fun loop env (src :: srcs) ret1 dsts =
            let
              val (ret2, dst) = compile env src
            in
              loop (extend (env, ret2)) srcs (accum (ret1, ret2)) (dsts ::> dst)
            end
          | loop env nil ret dsts = (ret, dsts)
      in
        loop env srcs empty NIL
      end

  fun ('env#boxed, 'src#boxed, 'ret#boxed, 'dst#boxed)
      compileList prims (compile : 'env -> 'src -> 'ret * 'dst) env srcs =
      let
        val (ret, dsts) = compileList' prims compile env srcs
      in
        (ret, Snoc.toList dsts)
      end

  (*
    equivalent to the following but optimized:
      fun mapAccum accum acc nil = (acc, nil)
        | mapAccum accum acc (src :: srcs) =
          let
            val (acc, dst) = accum (acc, src)
            val (acc, dsts) = mapAccum accum acc srcs
          in
            (acc, dst :: dsts)
          end
  *)
  fun ('acc#boxed, 'src#boxed, 'dst#boxed)
      mapAccum'
      (accum : 'acc -> 'src -> 'acc * 'dst)
      init
      srcs =
      let
        fun loop (src :: srcs) acc dsts =
            let
              val (acc, dst) = accum acc src
            in
              loop srcs acc (dsts ::> dst)
            end
          | loop nil acc dsts = (acc, dsts)
      in
        loop srcs init NIL
      end

  fun mapAccum accum init srcs =
      let
        val (acc, dsts) = mapAccum' accum init srcs
      in
        (acc, Snoc.toList dsts)
      end

end
