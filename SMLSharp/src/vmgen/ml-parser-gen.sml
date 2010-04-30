structure MLParserGen : sig

  val generate : InsnDef.def_elaborated list -> string

end =
struct

  structure I = InsnDef

  fun argToParser arg =
      case arg of
        I.VARX _ => "parseVar"
      | I.LSIZE _ => "parseLSize"
      | I.SIZE => "parseSize"
      | I.SCALE => "parseScale"
      | I.SHIFT => "parseShift"
      | I.DISPLACEMENT => "parseSSize"
      | I.LABEL => "parseLabel"
      | I.EXTERN _ => "parseExtern"
      | I.IMM => "parseConst"

  fun parseTerm (funName, varName) =
      "  case valOf ("^funName^" (ws r)) of ("^varName^", r) =>\n"
  fun parseDelim token =
      "  case read (\""^token^"\", ws r) of r =>\n"
  fun parseOr code1 code2 =
      code1^"handle Option => \n"^code2

  fun genSyntaxCase name insnTy args {format, fixed, pos} =
      let
        val binds = map (Utils.fixedArgToBind insnTy) fixed
        val conArgs =
            map (fn arg =>
                    case List.find (fn (x, v) => x = arg) binds of
                      SOME (x, v) => v
                    | NONE => Utils.argToVar arg)
                args
        val conArgs =
            case insnTy of
              SOME ty => "I." ^ Utils.toUpper (Utils.tyToSuffix ty) :: conArgs
            | NONE => conArgs

        val conName = Utils.conName name

        val combs =
            map (fn I.FMTSTR (s, _) => parseDelim s
                  | I.FMTARG (v, _) =>
                    parseTerm (argToParser v, Utils.argToVar v))
                format

        val return =
            case conArgs of
              nil => "  I."^conName
            | _ => "  I."^conName^" ("^Utils.join ", " conArgs^")"
      in
        "(* " ^ Control.loc pos ^ " *)\n" ^
        (case combs of
           nil => return
         | _ => "(\n" ^ String.concat combs ^ return ^ "\n)\n")
      end

  fun genSyntax name insnTy args pos syntaxCases =
      let
        val insnName = Utils.insnName (name, insnTy)

        val codes = map (genSyntaxCase name insnTy args) syntaxCases

        fun gen nil = raise Control.Bug "genSyntax: no syntax"
          | gen [code] = code
          | gen (code::codes) = parseOr code (gen codes)
      in
        "(* " ^ Control.loc pos ^ " *)\n\
        \\""^insnName^"\" =>\n("^gen codes^")\n"
      end

  fun genDef ({name, tyList, mnemonicArgs, syntax, pos, ...}
              : I.def_elaborated) =
      case tyList of
        nil => [genSyntax name NONE mnemonicArgs pos syntax]
      | _ =>
        map (fn ty => genSyntax name (SOME ty) mnemonicArgs pos syntax) tyList

  fun generate defs =
      "functor VMMnemonicParserFn\n\
      \(\n\
      \ val parseVar :\
      \ (VMMnemonic.var, Substring.substring) StringCvt.reader\n\
      \ val parseSize :\
      \ (VMMnemonic.sz, Substring.substring) StringCvt.reader\n\
      \ val parseLSize :\
      \ (VMMnemonic.lsz, Substring.substring) StringCvt.reader\n\
      \ val parseSSize :\
      \ (VMMnemonic.ssz, Substring.substring) StringCvt.reader\n\
      \ val parseScale :\
      \ (VMMnemonic.sc, Substring.substring) StringCvt.reader\n\
      \ val parseShift :\
      \ (VMMnemonic.sh, Substring.substring) StringCvt.reader\n\
      \ val parseLabel :\
      \ (VMMnemonic.label, Substring.substring) StringCvt.reader\n\
      \ val parseExtern :\
      \ (VMMnemonic.extern, Substring.substring) StringCvt.reader\n\
      \ val parseConst :\
      \ (VMMnemonic.imm, Substring.substring) StringCvt.reader\n\
      \) =\n\
      \struct\n\
      \local\n\
      \structure I = VMMnemonic\n\
      \fun ws s = Substring.dropl Char.isSpace s\n\
      \fun read (t, s) =\n\
      \    if Substring.isPrefix t s\n\
      \    then Substring.triml (size t) s else raise Option\n\
      \in\n\
      \exception OpName\n\
      \exception Operand\n\
      \fun parse s =\n\
      \let\n\
      \  val s = Substring.full s\n\
      \  val (l, r) = Substring.splitl (not o Char.isSpace) s\n\
      \  val l = Substring.string l\n\
      \in\n\
      \case l of\n\
      \"^ Utils.join "| " (List.concat (map genDef defs))^"\
      \| _ => raise OpName\n\
      \end\n\
      \handle Option => raise Operand\n\
      \end\n\
      \end\n"

end
