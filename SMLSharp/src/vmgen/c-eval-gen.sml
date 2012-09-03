structure CEvalGen : sig

  val generate : InsnDef.def_impl list ->
                 {ops32_c: string, optab32_c: string,
                  ops64_c: string, optab64_c: string}

end =
struct

  structure I = InsnDef

  fun fmtWordInt x =
      Word.fmt StringCvt.DEC x

  fun fmtInt x =
      String.translate (fn #"~" => "-" | x => str x)
                       (Int.fmt StringCvt.DEC x)

  datatype fetch =
      VALUE of int
    | FETCH of string

  fun setupArgs bits (argTys:I.argTy list) assignment fields =
      map
        (fn {arg, offset, ty=patTy, ...}:I.codeField =>
            let
              val {semTy, prepTy, ...} =
                  case List.find (fn {arg=x,...} => x = arg) argTys of
                    SOME x => x
                  | NONE => raise Control.Bug "genEvalCase"

              val value =
                  case List.find (fn (x,_) => x = arg) assignment of
                    SOME (_,x) => VALUE x
                  | NONE =>
                    case prepTy of
                      SOME prepTy =>
                      FETCH ("(FETCH_PREP(\
                             \"^I.formatCPatTy bits patTy^", \
                             \"^I.formatCSemTy semTy^", \
                             \"^I.formatCSemTy prepTy^", \
                             \(&ip["^fmtWordInt offset^"])))")
                    | NONE =>
                      FETCH ("(("^I.formatCSemTy semTy^")\
                              \*("^I.formatCPatTy bits patTy^"*)\
                              \(&ip["^fmtWordInt offset^"]))")
            in
              {arg = Utils.argToVar arg,
               semTy = semTy,
               patTy = patTy,
               offset = offset,
               value = value}
            end)
        fields

  fun genDebugPrint internalName args =
      "DBG_OP_PRINT_BEG("^internalName^");" ::
      map
        (fn {value = VALUE x, arg, semTy, patTy, offset} =>
            "DBG_OP_PRINT("^I.formatTy semTy^", \
            \\" "^arg^"=\", "^I.formatSemNum semTy x^");"
          | {value = FETCH x, arg, semTy, patTy, offset} =>
            "DBG_OP_PRINT("^I.formatTy semTy^", \
            \\" "^arg^"=\", "^x^");")
        args @
      ["DBG_OP_PRINT_END();"]

  fun genOpEntry bits getFormat
                 (def as {internalName, insnName, implId, argTys, assignment,
                          semantics, pos, ...}:I.def_impl) =
      let
        val {totalSize, fields, ...}:I.codeFormat = getFormat def
        val args = setupArgs bits argTys assignment fields

        val defs =
            List.mapPartial
              (fn {value = FETCH x, arg, ...} =>
                  SOME {def="#define "^arg^" "^x^"\n",
                        undef="#undef "^arg^"\n"}
                | {value = VALUE x, arg, ...} => NONE)
              args
      in
        "\nOPENTRY("^fmtWordInt bits^", "^fmtInt implId^", "^internalName^")\n\
        \{\n\
        \"^String.concat (map #def defs)^"\
        \#define OPSIZE "^fmtWordInt totalSize^"\n\
        \"^Utils.join "\n" (genDebugPrint internalName args)^"\n\
        \"^I.formatCSemantics semantics^"\n\
        \DISPATCH("^fmtWordInt totalSize^");\n\
        \#undef OPSIZE\n\
        \"^String.concat (map #undef defs)^"\
        \}\n"
      end

  fun genOpTable bits defs =
      let
        val cases =
            map
              (fn {internalName, implId, ...}:I.def_impl =>
                  "OPENTRY_ADDR("^fmtWordInt bits^", "^fmtInt implId^", \
                  \"^internalName^")")
              defs
      in
        "#define NUM_IMPL"^fmtWordInt bits^" "^fmtInt (length defs)^"\n\
        \static \
        \const void * const \
        \optable"^fmtWordInt bits^"["^fmtInt (length defs)^"] = \
        \{\n\
        \"^Utils.join ",\n" cases^"\n\
        \};\n"
      end

  fun genProgram bits getFormat defs =
      let
        val entries = map (genOpEntry bits getFormat) defs
        val optable = genOpTable bits defs
      in
        (String.concat entries, optable)
      end

  fun generate defs =
      let
        val (ops32, optab32) = genProgram 0w32 #format32 defs
        val (ops64, optab64) = genProgram 0w64 #format64 defs
      in
        {
          ops32_c = ops32,
          optab32_c = optab32,
          ops64_c = ops64,
          optab64_c = optab64
        }
      end

end
