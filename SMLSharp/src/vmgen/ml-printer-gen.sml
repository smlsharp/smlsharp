structure MLFormatterGen : sig

  val generate : InsnDef.def_elaborated list -> string

end =
struct

  structure I = InsnDef

  fun argToFormatter arg =
      case arg of
        I.VARX _ => "formatVar"
      | I.LSIZE _ => "formatLSize"
      | I.SIZE => "formatSize"
      | I.SCALE => "formatScale"
      | I.SHIFT => "formatShift"
      | I.DISPLACEMENT => "formatSSize"
      | I.LABEL => "formatLabel"
      | I.EXTERN _ => "formatExtern"
      | I.IMM => "formatImm"

  fun genSyntaxCase {format, fixed, pos} =
      let
        val conds =
            map (fn fix =>
                    let
                      val (arg, value) = Utils.fixedArgToBind NONE fix
                    in
                      Utils.argToVar arg^" = "^value
                    end)
                fixed

        val format =
            map (fn I.FMTSTR (",", _) => "\", \""
                  | I.FMTSTR ("+", _) => "\" + \""
                  | I.FMTSTR ("*", _) => "\" * \""
                  | I.FMTSTR (s, _) => "\""^s^"\""
                  | I.FMTARG (v, _) =>
                    argToFormatter v^" "^Utils.argToVar v)
                format
      in
        "(* " ^ Control.loc pos ^ " *)\n" ^
          (case conds of
             nil => Utils.join " ^ " format
           | _ => "if "^Utils.join " andalso " conds^"\n\
                  \then "^Utils.join " ^ " format)
      end

  fun genDef ({name, tyList, mnemonicArgs, syntax, pos, ...}
              :I.def_elaborated) =
      let
        val conName = Utils.conName name

        val insnNameCase =
            case tyList of
              nil => "\""^Utils.insnName (name, NONE)^"\""
            | _::_ =>
              "(case ty of\n"
              ^Utils.join "\n| "
                (map (fn ty =>
                         "I."^Utils.toUpper (Utils.tyToSuffix ty)^" => \
                         \\""^Utils.insnName (name, SOME ty)^"\"")
                     tyList)
              ^(if Utils.isExhaustiveSuffix tyList
                then ")"
                else "\n| _ => raise Format m)")

        val patArgs =
            map (fn arg => Utils.argToVar arg) mnemonicArgs
        val patArgs =
            case tyList of _::_ => "ty" :: patArgs | nil => patArgs

        val pat =
            case patArgs of
              nil => "I."^conName
            | _ => "I."^conName^" ("^Utils.join ", " patArgs^")"
      in
        "| (* " ^ Control.loc pos ^ " *)\n\
        \"^pat^" =>\n\
        \"^insnNameCase^
        (case patArgs of
           nil => "\n"
         | _ => "^ \"\\t\" ^ (\n\
                \"^Utils.join "\nelse " (map genSyntaxCase syntax)^")\n")
      end

  fun generate defs =
      let
        val formatCases =
            map genDef defs
      in
        "functor VMMnemonicFormatterFn\n\
        \(\n\
        \ val formatVar : VMMnemonic.var -> string\n\
        \ val formatSize : VMMnemonic.sz -> string\n\
        \ val formatLSize : VMMnemonic.lsz -> string\n\
        \ val formatSSize : VMMnemonic.ssz -> string\n\
        \ val formatScale : VMMnemonic.sc -> string\n\
        \ val formatShift : VMMnemonic.sh -> string\n\
        \ val formatLabel : VMMnemonic.label -> string\n\
        \ val formatExtern : VMMnemonic.extern -> string\n\
        \ val formatLoc : VMMnemonic.loc -> string\n\
        \ val formatB : Word8.word -> string\n\
        \ val formatH : word -> string\n\
        \ val formatNB : int -> string\n\
        \ val formatNH : int -> string\n\
        \ val formatW : VMMnemonic.w -> string\n\
        \ val formatL : VMMnemonic.l -> string\n\
        \ val formatN : VMMnemonic.n -> string\n\
        \ val formatNL : VMMnemonic.nl -> string\n\
        \ val formatFS : VMMnemonic.fs -> string\n\
        \ val formatF  : VMMnemonic.f -> string\n\
        \ val formatFL : VMMnemonic.fl -> string\n\
        \ val formatString : string -> string\n\
        \) : sig\n\
        \ exception Format of VMMnemonic.instruction\n\
        \ val formatImm : VMMnemonic.imm -> string\n\
        \ val format : VMMnemonic.instruction -> string\n\
        \end =\n\
        \struct\n\
        \local\n\
        \structure I = VMMnemonic\n\
        \in\n\
        \exception Format of VMMnemonic.instruction\n\
        \fun formatImm const =\n\
        \    case const of\n\
        \      I.CONST_B x => formatB x\n\
        \    | I.CONST_H x => formatH x\n\
        \    | I.CONST_NB x => formatNB x\n\
        \    | I.CONST_NH x => formatNH x\n\
        \    | I.CONST_W x => formatW x\n\
        \    | I.CONST_L x => formatL x\n\
        \    | I.CONST_N x => formatN x\n\
        \    | I.CONST_NL x => formatNL x\n\
        \    | I.CONST_F x => formatF x\n\
        \    | I.CONST_FS x => formatFS x\n\
        \    | I.CONST_FL x => formatFL x\n\
        \    | I.EXTERN x => formatExtern x\n\
        \\n\
        \fun format m =\n\
        \case m of\n\
        \  I.Label s => s^\":\"\n\
        \| I.LocalLabel => \"@:\"\n\
        \| I.Const nil => \".const\\t\"\n\
        \| I.Const (h::t) => \".const\\t\"^\
        \  foldl (fn (x,z) => z ^ \", \" ^ formatImm x) (formatImm h) t\n\
        \| I.ConstString s => \".string\\t\"^formatString s\n\
        \| I.Loc loc => \".loc\\t\"^formatLoc loc\n\
        \"^String.concat formatCases^"\
        \end\n\
        \end\n"
      end

end
