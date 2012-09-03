structure MotherGen : sig

  val generate : InsnDef.def_typechecked list -> InsnDef.def_mother list

end =
struct

  structure I = InsnDef

  val insnId = ref 0w0

  val opcodeAlign = 0w8   (* must be maximum align *)

  (* size of argument type in byte code (less than 64 bit) *)
  (* See also genDump in ml-asm-gen.sml. *)
  fun sizeof sizeofPointer patTy =
      case patTy of
        I.W => 0w4
      | I.L => 0w8
      | I.N => 0w4
      | I.NL => 0w8
      | I.FS => 0w4
      | I.F => 0w8
      | I.SZ => 0w4
      | I.LSZ => sizeofPointer
      | I.SSZ => sizeofPointer
      | I.RI => sizeofPointer
      | I.LI => sizeofPointer
      | I.OA => sizeofPointer
      | I.P => sizeofPointer
      | _ =>
        raise Control.Bug ("sizeof: invalid pattern type "^I.formatTy patTy)

  fun align alignment pos =
      (pos + alignment - 0w1) - (pos + alignment - 0w1) mod alignment

  fun codeFormat sizeof args =
      let
        fun format sizeof pos nil =
            {fields = nil, totalSize = align opcodeAlign pos}
          | format sizeof pos ({arg, patTy, semTy, prepTy}::args) =
            let
              val size = sizeof patTy
              val offset = align size pos
              val padsize = offset - pos
              val field = {arg = arg, ty = patTy, offset = offset, size = size}
              val {fields, totalSize} = format sizeof (offset + size) args
            in
              {fields = field::fields, totalSize = totalSize}
            end

        val opcodeSize = sizeof I.OA
        val {fields, totalSize} = format sizeof opcodeSize args
      in
        {opcodeSize=opcodeSize, fields=fields, totalSize=totalSize}
        : I.codeFormat
      end

  fun expandVAR nil = [nil]
    | expandVAR (arg::args) =
      let
        fun expand arg args =
            let
              val regTy = {arg=arg, patTy=I.RI, semTy=I.RI, prepTy=SOME I.P}
              val varTy = {arg=arg, patTy=I.LI, semTy=I.LI, prepTy=NONE}
              val expanded = expandVAR args
            in
              map (fn t => regTy :: t) expanded
              @ map (fn t => varTy :: t) expanded
            end
      in
        case arg of
          (arg, I.VI) => expand arg args
        | (arg, semTy) =>
          let
            val ty =
                case semTy of
                  I.SC => {arg=arg, patTy=I.SZ, semTy=semTy, prepTy=NONE}
                | I.SH => {arg=arg, patTy=I.SZ, semTy=semTy, prepTy=NONE}
                | I.OA => {arg=arg, patTy=I.OA, semTy=semTy, prepTy=SOME I.P}
                | _ => {arg=arg, patTy=semTy, semTy=semTy, prepTy=NONE}
          in
            map (fn t => ty :: t) (expandVAR args)
          end
      end

  fun subst (argTys:I.argTy list) (arg, ty, pos) =
      case List.find (fn {arg=x,...} => x = arg) argTys of
        SOME {arg, semTy, patTy, prepTy} => (I.ARG (arg, semTy, pos), semTy)
      | NONE => (I.ARG (arg, ty, pos), ty)

  fun substArgTys argTys metaif =
      case metaif of
        I.METAIF (cond, mthen, melse) =>
        I.METAIF (cond, substArgTys argTys mthen, substArgTys argTys melse)
      | I.META (sem, pos) =>
        I.META (Substitute.substArg (subst argTys) sem, pos)

  fun genVariant ({name, mnemonicArgs, variants, ...}:I.def_typechecked)
                 insnId
                 (typeLow, {ty, codeArgs, preprocess, semantics,
                            alternate, pos}) =
      let
        val numTys = length variants
        val argCases = expandVAR codeArgs
      in
        Utils.mapi
          (fn (typeHi, codeArgs) =>
              let
                val variantId = Word.fromInt (typeHi * numTys + typeLow)
                val opcode = insnId * 0wx10000 + variantId

                (* 32bit format : sizeof(pointer) = 4 *)
                val format32 = codeFormat (sizeof 0w4) codeArgs
                (* 64bit format : sizeof(pointer) = 8 *)
                val format64 = codeFormat (sizeof 0w8) codeArgs
              in
                {
                  variantId = variantId,
                  opcode = opcode,
                  ty = ty,
                  argTys = codeArgs,
                  format32 = format32,
                  format64 = format64,
                  preprocess = preprocess,
                  semantics = substArgTys codeArgs semantics,
                  alternate = 
                    case alternate of
                      SOME sem =>
                      SOME (Substitute.substArg (subst codeArgs) sem)
                    | NONE => NONE
                }
              end)
          argCases
      end

  fun genDef (def as {name, mnemonicArgs, variants, syntax, pos}
                     :I.def_typechecked) =
      let
        val insnId = !insnId before insnId := !insnId + 0w1
      in
        {
          name = name,
          insnId = insnId,
          mnemonicArgs = mnemonicArgs,
          variants = List.concat (Utils.mapi (genVariant def insnId) variants),
          pos = pos
        } : I.def_mother
      end

  fun generate defs =
      (
        insnId := 0w0;
        map genDef defs
      )

end
