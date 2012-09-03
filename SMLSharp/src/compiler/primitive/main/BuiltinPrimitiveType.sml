(* -*- sml -*- *)
(**
 * built-in primitive utils.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
structure BuiltinPrimitiveType : sig

  val primInfo : Types.topTyConEnv
                 -> BuiltinPrimitive.prim_or_special
                 -> {name: BuiltinPrimitive.prim_or_special, ty: Types.ty}

end =
struct

  structure P = BuiltinPrimitive

  fun primInfo topTyConEnv builtin =
      let
        val {ty,...} =
            case builtin of
              P.P prim => BuiltinPrimitiveInfo.primitive_info prim
            | P.S prim => BuiltinPrimitiveInfo.specialForm_info prim
      in
        {name = builtin, ty = TypeParser.readTy topTyConEnv ty}
      end

end
