structure MLMnemonicGen : sig

  val generate : InsnDef.def_elaborated list -> string

end =
struct

  structure I = InsnDef

  val sizeType = "word"
  val lsizeType = "Word32.word"
  val ssizeType = "Int32.int"
  val wordType = "Word32.word"
  val longType = "Word64.word"
  val intType = "Int32.int"
  val longIntType = "Int64.int"
  val floatType = "string"  (*"Real.real"*)
  val singleFloatType = "string"  (*"Real.real"*)
  val longFloatType = "string"   (*"Real.real"*)

  fun argToTy arg =
      case arg of
        I.VARX _ => "var"
      | I.LSIZE _ => "lsz"
      | I.SIZE => "sz"
      | I.SCALE => "sc"
      | I.SHIFT => "sh"
      | I.DISPLACEMENT => "ssz"
      | I.IMM => "imm"
      | I.LABEL => "label"
      | I.EXTERN _ => "extern"

  fun genDef ({name, tyList, mnemonicArgs, pos, ...}:I.def_elaborated) =
      let
        val args = map argToTy mnemonicArgs
        val args = case tyList of
                     nil => args | _ => "ty" :: args

        val conname = Utils.conName name
        val datacon =
            case args of
              nil => conname
            | _ => conname ^ " of " ^ Utils.join " * " args
      in
        "(* "^Control.loc pos^" *)\n    "^datacon^"\n"
      end

  fun genSubst ({name, tyList, mnemonicArgs, pos, ...}:I.def_elaborated) =
      let
        val args =
            map (fn arg =>
                    let
                      val v = Utils.argToVar arg
                    in
                      case arg of
                        I.VARX _ => (v, "substVar subst "^v)
                      | _ => (v, v)
                    end)
                mnemonicArgs

        val args = case tyList of
                     nil => args | _ => ("ty", "ty") :: args

        val name = Utils.toUpper name

        fun makepat nil = name
          | makepat l = name ^ " (" ^ Utils.join ", " l ^ ")"
      in
        "(* "^Control.loc pos^" *)\n\
        \    "^makepat (map #1 args)^" =>\n\
        \    "^makepat (map #2 args)^"\n"
      end

  fun generate defs =
      "structure VMMnemonic =\n\
      \struct\n\
      \(*%*)\n\
      \type loc = string\n\
      \ and w = "^wordType^"  (* 32bit unsigned int *)\n\
      \ and l = "^longType^"  (* 64bit unsigned int *)\n\
      \ and n = "^intType^"   (* 32bit signed int *)\n\
      \ and nl = "^longIntType^"  (* 64bit signed int *)\n\
      \ and f = "^floatType^"   (* double-precision floating point *)\n\
      \ and fs = "^singleFloatType^"  (* single-precision floating point *)\n\
      \ and fl = "^longFloatType^"  (* long-precision floating point *)\n\
      \ and sz = "^sizeType^"  (* size of a value *)\n\
      \ and lsz = "^lsizeType^"  (* full-scale unsigned offset address *)\n\
      \ and ssz = "^ssizeType^"  (* full-scale signed offset address *)\n\
      \ and sc = word  (* scale factor for relative address *)\n\
      \ and sh = word  (* shift factor *)\n\
      \(*%*)\n\
      \datatype var =\n\
      \    REG of word\n\
      \  | VAR of word\n\
      \  | HOLE of int\n\
      \(*%*)\n\
      \datatype label =\n\
      \    LABELREF of string\n\
      \  | LOCALLABELREF of int  (* positive=forward, negative=backward *)\n\
      \  | REL of ssz\n\
      \(*%*)\n\
      \datatype extern =\n\
      \    INTERNALREF of string (* reference to internal symbol *)\n\
      \  | GLOBALREF of string   (* reference to global slot symbol *)\n\
      \  | EXTDATAREF of string  (* reference to external data symbol *)\n\
      \  | EXTCODEREF of string  (* reference to external code symbol *)\n\
      \  | FFREF of string       (* reference to foreign function symbol *)\n\
      \  | PRIMREF of string     (* reference to primitive symbol *)\n\
      \(*%*)\n\
      \datatype imm =\n\
      \    CONST_B of Word8.word\n\
      \  | CONST_H of word\n\
      \  | CONST_NB of int\n\
      \  | CONST_NH of int\n\
      \  | CONST_W of "^wordType^"\n\
      \  | CONST_L of "^longType^"\n\
      \  | CONST_N of "^intType^"\n\
      \  | CONST_NL of "^longIntType^"\n\
      \  | CONST_F of "^floatType^"\n\
      \  | CONST_FS of "^singleFloatType^"\n\
      \  | CONST_FL of "^longFloatType^"\n\
      \  | EXTERN of extern\n\
      \(*%*)\n\
      \datatype ty =\n\
      \    W\n\
      \  | L\n\
      \  | N\n\
      \  | NL\n\
      \  | F\n\
      \  | FS\n\
      \  | FL\n\
      \  | P\n\
      \\n\
      \(*%*)\n\
      \datatype instruction =\n\
      \    "^Utils.join "  | " (map genDef defs)^"\
      \  | Label of string\n\
      \  | LocalLabel\n\
      \  | Const of imm list\n\
      \  | ConstString of string\n\
      \  | Loc of loc\n\
      \\n\
      \local\n\
      \fun substVar subst (HOLE n) = List.nth (subst, n)\n\
      \  | substVar subst x = x\n\
      \in\n\
      \fun substHole subst insn =\n\
      \case insn of\n\
      \    "^Utils.join "  | " (map genSubst defs)^"\
      \  | Label _ => insn\n\
      \  | LocalLabel => insn\n\
      \  | Const _ => insn\n\
      \  | ConstString _ => insn\n\
      \  | Loc _ => insn\n\
      \end\n\
      \end\n"

end
