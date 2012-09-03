structure Fusion : sig

  val fusion : InsnDef.def_mother list -> InsnDef.def_impl list

end =
struct

  structure I = InsnDef

  val implId = ref 0

  fun tyToInsnSuffix semTy =
      case semTy of
        I.W => "w"
      | I.L => "l"
      | I.N => "n"
      | I.NL => "N"
      | I.FS => "f"
      | I.F => "F"
      | I.SC => "c"
      | I.SH => "h"
      | I.SZ => "z"
      | I.SSZ => "s"
      | I.LSZ => "S"
      | I.RI => "r"
      | I.LI => "v"
      | I.P => "p"
      | I.OA => "o"
      | _ => raise Control.Bug ("tyToInsnSuffix: "^I.formatTy semTy)

  fun codePattern ({opcodeSize, fields, totalSize}:I.codeFormat)
                  opcode assignment =
      let
        val fixedPat =
            map (fn (a, n) =>
                    case List.find (fn {arg,...} => a = arg) fields of
                      SOME {offset, size, ty, ...} =>
                      (offset, {size = size, ty = ty, value = n})
                    | NONE => raise Control.Bug "codePattern")
                assignment

        val opcodePat =
            (0w0, {size=opcodeSize, ty=I.W, value=Word.toInt opcode})

        val fixedPat =
            Utils.sortBy (Word.toInt o #1) (opcodePat :: fixedPat)

        fun pad pos nextPos =
            if pos < nextPos then [I.PATANY {size = nextPos - pos}] else nil

        fun gen pos nil = pad pos totalSize
          | gen pos ((offset, pat as {size, ...})::t) =
            pad pos offset @ I.PATINT pat :: gen (offset + size) t
      in
        gen 0w0 fixedPat
      end

  fun expandMetaif (argTys:I.argTy list) semantics =
      let
        (*
         * NOTE: meta equation "varX == n" is true if varX is register and
         *       the register index is equal to n. If varX is not register,
         *       then this equation is always false.
         *)
        val semantics =
            Utils.evalMetaif
              (fn I.METAEQ (arg as I.VARX _, _, _) =>
                  (case List.find (fn {arg=x,...} => x = arg) argTys of
                     SOME {semTy=I.LI,...} => SOME false
                   | _ => NONE)
                | _ => NONE)
              semantics
      in
        Utils.expandMetaif
          (fn I.METAEQ (arg, n, pos) =>
              (case List.find (fn {arg=x,...} => x = arg) argTys of
                 SOME _ => (arg, n)
               | NONE =>
                 raise Control.Error
                         [(pos, "unbound operand `"^I.formatArg arg^"'")])
            | I.METAEQTY (_, pos) =>
              raise Control.Error [(pos, "meta type equation in syntax")]
            | I.METAEQSUFFIX _ =>
              raise Control.Bug "expandMetaif: METAEQSUFFIX")
          semantics
      end

  fun subst assignment (arg, ty, pos) =
      case List.find (fn (x,_) => x = arg) assignment of
        SOME (_,n) => (I.NUM (n, ty, pos), ty)
      | NONE => (I.ARG (arg, ty, pos), ty)

  (*
   * FIXME: Currently only operand fusion is implemented.
   *        Is instruction fusion needed?
   *)
  fun fusionDef ({name, mnemonicArgs, pos, insnId, ...}:I.def_mother)
                (variant as {variantId, opcode, ty, argTys,
                             format32, format64, preprocess, semantics,
                             alternate}) =
      let
        val suffix =
            map (fn arg =>
                    case List.find (fn {arg=x,...} => x = arg) argTys of
                      SOME {semTy,...} => tyToInsnSuffix semTy
                    | NONE => raise Control.Bug "fusionDef: mnemonicArgs")
                mnemonicArgs

        val insnName = Utils.insnName (name, ty)

        val internalName =
            case suffix of
              nil => insnName
            | _ => insnName ^ "_" ^ String.concat suffix

        val semanticCases = expandMetaif argTys semantics

        val specialized =
            Utils.mapi
              (fn (fusionId, (assignment, semantics:I.semantics, pos)) =>
                  {
                    fusionId = fusionId,
                    assignment = assignment,
                    semantics = Substitute.substArg (subst assignment)
                                                    semantics,
                    pos = pos
                  })
              semanticCases

        val specialized =
            case specialized of
              [x] => [(internalName, x)]
            | _ =>
              map (fn x as {fusionId,...} =>
                      (internalName ^ "_" ^ Int.toString fusionId, x))
                  specialized

        val (alternate, alternateId) =
            case alternate of
              NONE => (nil, NONE)
            | SOME sem =>
              let
                val implId = !implId before implId := !implId + 1
              in
                ([{
                    internalName = internalName^"_alt",
                    insnName = insnName,
                    implId = implId,
                    insnId = insnId,
                    variantId = variantId,
                    alternateId = NONE,
                    argTys = argTys,
                    assignment = nil,
                    format32 = format32,
                    format64 = format64,
                    pat32 = nil,
                    pat64 = nil,
                    preprocess = NONE,
                    semantics = sem,
                    pos = pos
                  } : I.def_impl],
                 SOME implId)
              end
      in
        alternate @
        map
          (fn (internalName, {assignment, semantics, pos, ...}) =>
              {
                internalName = internalName,
                insnName = insnName,
                implId = !implId before implId := !implId + 1,
                insnId = insnId,
                variantId = variantId,
                alternateId = alternateId,
                argTys = argTys,
                assignment = assignment,
                format32 = format32,
                format64 = format64,
                pat32 = codePattern format32 opcode assignment,
                pat64 = codePattern format64 opcode assignment,
                preprocess = preprocess,
                semantics = semantics,
                pos = pos
              } : I.def_impl)
          specialized
      end

  fun fusion defs =
      (
        implId := 0;
        List.concat
          (map (fn def as {variants, ...} =>
                   List.concat (map (fusionDef def) variants))
               defs)
      )

end
