structure MLAssembleGen : sig

  val generate : InsnDef.def_mother list ->
                 {asm32_sml: string, asm64_sml: string}

end =
struct

  structure I = InsnDef
  structure IMap = Utils.IMap

  infix << ||
  val (op <<) = Word.<<
  val (op ||) = Word.orb

  fun fmtWordInt x = Word.fmt (StringCvt.DEC) x
  fun fmtWordHex x = "x" ^ Word.fmt (StringCvt.HEX) x

  (* See also "sizeof" and "expandVAR" in mother.sml. *)
  fun dump offset size ty arg =
      let
        val offset = fmtWordInt offset
      in
        case (size, ty) of
          (0w4, I.W) => "dumpW (a, i+"^offset^", "^arg^")"
        | (0w8, I.L) => "dumpL (a, i+"^offset^", "^arg^")"
        | (0w4, I.N) => "dumpN (a, i+"^offset^", "^arg^")"
        | (0w8, I.NL) => "dumpNL (a, i+"^offset^", "^arg^")"
        | (0w4, I.FS) => "dumpFS (a, i+"^offset^", "^arg^")"
        | (0w8, I.F) => "dumpF (a, i+"^offset^", "^arg^")"
        | (0w4, I.SZ) => "dumpWord (a, i+"^offset^", "^arg^")"
        | (0w4, I.LSZ) => "dumpW (a, i+"^offset^", "^arg^")"
        | (0w8, I.LSZ) => "dumpW64 (a, i+"^offset^", "^arg^")"
        | (0w4, I.SSZ) => "dumpN (a, i+"^offset^", "^arg^")"
        | (0w8, I.SSZ) => "dumpN64 (a, i+"^offset^", "^arg^")"
        | (0w4, I.OA) => "dumpN (a, i+"^offset^", "^arg^")"
        | (0w8, I.OA) => "dumpN64 (a, i+"^offset^", "^arg^")"
        | (0w4, I.RI) => "dumpWord (a, i+"^offset^", "^arg^")"
        | (0w8, I.RI) => "dumpWord64 (a, i+"^offset^", "^arg^")"
        | (0w4, I.LI) => "dumpWord (a, i+"^offset^", "^arg^")"
        | (0w8, I.LI) => "dumpWord64 (a, i+"^offset^", "^arg^")"
        (* I.P is already translated into I.OA *)
        | _ => raise Control.Bug ("dump: undumpable format "^
                                  I.formatTy ty^":"^fmtWordInt size)
      end

  fun dumpOpcode offset size arg =
      case size of
        0w4 => "dumpWord (a, i+"^fmtWordInt offset^", "^arg^")"
      | 0w8 => "dumpWord64 (a, i+"^fmtWordInt offset^", "^arg^")"
      | _ => raise Control.Bug "dumpWord"

  fun dumpField totalSize field =
      case field of
        [{arg as I.LABEL, offset, size, ty}] =>
        dump offset size ty
             ("resolve labelEnv (i+"^fmtWordInt totalSize^") "
              ^ Utils.argToVar arg) ^
        ";\n"
      | [{arg as I.EXTERN _, offset, size, ty}] =>
        dump offset size I.OA "0" ^ ";\n"
      | {arg as I.IMM, ...}::_ =>
        "(case (ty, "^Utils.argToVar arg^") of\n"^
        Utils.join "\n| "
          (map
             (fn {ty=I.P, offset, size, arg} =>
                 "(I.P,I.EXTERN _) => "^dump offset size I.OA "0"
               | {ty, offset, size, arg} =>
                 let
                   val arg = Utils.argToVar arg
                   val sty = Utils.toUpper (Utils.tyToSuffix ty)
                 in
                   "(I."^sty^",I.CONST_"^sty^" "^arg^") =>\
                   \ "^dump offset size ty arg^"\n\
                   \| (I."^sty^",I.EXTERN _) =>\
                   \ "^dump offset size I.OA "0"
                 end)
             field) ^
        "\n| _ => raise Assemble m);\n"
      | [{arg, offset, size, ty}] =>
        dump offset size ty (Utils.argToVar arg) ^ ";\n"
      | _ =>
        raise Control.Bug "dumpField"

  fun dumpFunArgs opcode ({fields, ...}:I.codeFormat) =
      "("^
      Utils.join ", "
        (opcode ::
         (map (fn {arg as I.IMM, ...} => "ty, "^Utils.argToVar arg
                | {arg, ...} => Utils.argToVar arg)
              fields)) ^
      ")"

  fun genDumpFun funname formats =
      let
        val format as {opcodeSize, totalSize, fields}:I.codeFormat =
            List.hd formats
            handle Empty => raise Control.Bug "genAsmDumpFun: Empty"

        val args =
            Utils.mapi
              (fn (i, _) =>
                  Utils.uniq
                    (op =)
                    (map (fn x => (List.nth (#fields x, i))) formats))
              fields
            handle Subscript => raise Control.Bug "genAsmDumpFun: Subscript"

        val exts =
            List.mapPartial
              (fn {arg as I.EXTERN _, offset, size, ...}::_ =>
                  SOME ("[{offset = i+"^fmtWordInt offset^",\
                        \ size = 0w"^fmtWordInt size^",\
                        \ extern = "^Utils.argToVar arg^"}]")
                | {arg as I.IMM, offset, size,...}::_ =>
                  SOME ("(case "^Utils.argToVar arg^" of\n\
                        \ I.EXTERN x =>\
                        \ [{offset = i+"^fmtWordInt offset^",\
                        \ size = 0w"^fmtWordInt size^",\
                        \ extern = x}]\n\
                        \ | _ => nil)")
                | _ => NONE)
              args

        val exts =
            case exts of nil => "nil" | _::_ => Utils.join " @ " exts
      in
        "fun "^funname^" "^dumpFunArgs "opcode" format^" mode =\n\
        \case mode of\n\
        \ASM (labelEnv,a,i,m) =>\n\
        \("^dumpOpcode 0w0 opcodeSize "opcode" ^ ";\n"^
        String.concat (map (dumpField totalSize) args) ^
        "{next=i+"^fmtWordInt totalSize^", externs=nil})\n\
        \| PROP (i,m) =>\n\
        \{next=i+"^fmtWordInt totalSize^", externs="^exts^"}\n"
      end

  fun genDumpFuns clusters =
      let
        val (_, rfuncs, funMap) =
            foldl
              (fn (variants, (i, funcs, funMap)) =>
                  let
                    val formats =  map #format variants
                    val funname = "dump_" ^ Int.toString i
                    val code = genDumpFun funname formats
                    val funMap =
                        foldl
                          (fn ({opcode, def, variant, format}, funMap) =>
                              IMap.insert (funMap, Word.toIntX opcode, funname))
                          funMap
                          variants
                  in
                    (i + 1, code::funcs, funMap)
                  end)
              (0, nil, IMap.empty)
              clusters
      in
        (rev rfuncs, funMap)
      end


  fun argPattern ({name, mnemonicArgs, ...}:I.def_mother) ty
                 (argTys:I.argTy list) =
      let
        val pat =
            map (fn arg =>
                    case List.find (fn {arg=x,...} => x = arg) argTys of
                      SOME {semTy,...} =>
                      Utils.toMnemonicArgValue (arg, semTy, NONE)
                    | NONE => raise Control.Bug "argPattern")
                mnemonicArgs
        val pat =
            case ty of
              NONE => pat
            | SOME ty => "ty as I."^Utils.toUpper (Utils.tyToSuffix ty) :: pat
      in
        case pat of nil => "" | _::_ => "("^Utils.join ", " pat^")"
      end

  fun anyPattern ({name, mnemonicArgs, variants, ...}:I.def_mother) =
      let
        val con = "I."^Utils.toUpper name
      in
        case (mnemonicArgs, variants) of
          (_::_, {ty=SOME _,...}::_) => (con^" args", "args")
        | (nil, {ty=SOME _,...}::_) => (con^" args", "args")
        | (_::_, _) => (con^" args", "args")
        | _ => (con, "")
      end


  fun genInsnDumpFun getFormat dumpFunMap funname
                     (def as {variants, pos, ...}:I.def_mother) =
      let
        val (_, args) = anyPattern def

        val pats =
            map
              (fn variant as {opcode, ty, argTys, ...} =>
                  let
                    val format = getFormat variant
                    val dumpFunName =
                        case IMap.find (dumpFunMap, Word.toIntX opcode) of
                          SOME x => x
                        | NONE => raise Control.Bug "genAsm"
                  in
                    (argPattern def ty argTys,
                     dumpFunName,
                     dumpFunArgs ("0w"^fmtWordHex opcode) format)
                  end)
              variants

        val cluster =
            Utils.cluster (fn ((_,x1,_),(_,x2,_)) => x1 = x2) pats

        fun genCase f =
            "case "^args^" of\n"^
            Utils.join "\n| "
              (map (fn x as (pat,func,params) => pat^" => "^f x) pats) ^
            (* FIXME: ad-hoc workaround to prevent non-exhaustive match *)
              (case pats of
               [_] => ""
             | _ => "\n| _ => raise Assemble (getInsn mode)")

        val body =
            case cluster of
              [[("",func,params)]] => func^" "^params^" mode"
            | [(pat,func,params)::_] =>
              func^" (\n"^genCase (fn (_,_,y) => y)^") mode"
            | _ => genCase (fn (_,x,y) => x^" "^y^" mode")
      in
        "(* "^Control.loc pos^" *)\n\
        \fun "^funname^" "^args^" mode =\n"^
        body^"\n"
      end


  fun eqField (x as {arg=a1,ty=t1:I.ty,size=s1:word,offset=o1:word},
               y as {arg=a2,ty=t2,size=s2,offset=o2}) =
      case (a1, a2) of (I.IMM, I.IMM) => o1 = o2 | _ => x = y

  fun eqFields (h1::t1, h2::t2) = eqField (h1, h2) andalso eqFields (t1, t2)
    | eqFields (nil, nil) = true
    | eqFields _ = false

  fun eqFormat ({opcodeSize=o1,fields=f1,totalSize=t1}:I.codeFormat,
                {opcodeSize=o2,fields=f2,totalSize=t2}:I.codeFormat) =
      o1 = o2 andalso t1 = t2 andalso eqFields (f1, f2)

  fun setup getFormat defs =
      let
        val variants =
            List.concat
              (map (fn def as {variants, ...}:I.def_mother =>
                       map (fn variant as {opcode, ...} =>
                               {
                                 opcode = opcode,
                                 def = def,
                                 variant = variant,
                                 format = getFormat variant : I.codeFormat
                               })
                           variants)
                   defs)
      in
        Utils.cluster (fn (x,y) => eqFormat (#format x, #format y)) variants
      end

  fun genAsm getFormat defs =
      let
        val variants =
            setup getFormat defs

        val (dumpFuns, dumpFunMap) =
            genDumpFuns variants

        val insnFuns =
            map (fn def as {name, ...} =>
                    genInsnDumpFun getFormat dumpFunMap ("dump_"^name) def)
                defs

        val cases =
            map
              (fn def as {name, ...} =>
                  let
                    val (pat, arg) = anyPattern def
                    val pat = "I."^Utils.conName name^" "^arg
                  in
                    "| "^pat^" => dump_"^name^" "^arg^" mode\n"
                  end)
              defs
      in
        (dumpFuns @ insnFuns, cases)
      end


  fun genFunctor ptrsize suffix getFormat defs =
      let
        val (funcs, asmCases) = genAsm getFormat defs
      in
        "functor VMMnemonicAssemblerFn"^suffix^"\n\
        \(\n\
        \  structure LabelEnv : sig\n\
        \   type map\n\
        \   val find : map * string -> int option\n\
        \   val findLocal : map * int -> int option\n\
        \  end\n\
        \  structure Dump : sig\n\
        \   type buf\n\
        \   val dumpWord : buf * int * word -> unit  (* 32bit *)\n\
        \   val dumpWord64 : buf * int * word -> unit  (* 64bit *)\n\
        \   val dumpB : buf * int * Word8.word -> unit\n\
        \   val dumpH : buf * int * word -> unit\n\
        \   val dumpNB : buf * int * int -> unit\n\
        \   val dumpNH : buf * int * int -> unit\n\
        \   val dumpW : buf * int * Word32.word -> unit\n\
        \   val dumpW64 : buf * int * Word32.word -> unit\n\
        \   val dumpL : buf * int * Word64.word -> unit\n\
        \   val dumpN : buf * int * Int32.int -> unit\n\
        \   val dumpN64 : buf * int * Int32.int -> unit\n\
        \   val dumpNL : buf * int * Int64.int -> unit\n\
        \   val dumpF : buf * int * string -> unit\n\
        \   val dumpFS : buf * int * string -> unit\n\
        \   val dumpFL : buf * int * string -> unit\n\
        \  end\n\
        \  structure Error : sig\n\
        \   exception LabelNotFound of VMMnemonic.label\n\
        \   exception Assemble of VMMnemonic.instruction\n\
        \  end\n\
        \) : VM_MNEMONIC_ASSEMBLER_FN =\n\
        \struct\n\
        \ open Dump\n\
        \ open Error\n\
        \ type buf = buf\n\
        \ type labelEnv = LabelEnv.map\n\
        \ structure I = VMMnemonic\n\
        \\n\
        \ datatype mode =\n\
        \     PROP of int * VMMnemonic.instruction\n\
        \   | ASM of labelEnv * buf * int * VMMnemonic.instruction\n\
        \ fun getInsn (PROP (_,m)) = m\n\
        \   | getInsn (ASM (_,_,_,m)) = m\n\
        \\n\
        \ fun toSSZ n = Int32.fromInt n\n\
        \\n\
        \ fun resolve labelEnv base label =\n\
        \     case label of\n\
        \       I.LABELREF l =>\n\
        \       (case LabelEnv.find (labelEnv, l) of\n\
        \          SOME x => toSSZ (x - base)\n\
        \        | NONE => raise LabelNotFound label)\n\
        \     | I.LOCALLABELREF x =>\n\
        \       (case LabelEnv.findLocal (labelEnv, x) of\n\
        \          SOME x => toSSZ (x - base)\n\
        \        | NONE => raise LabelNotFound label)\n\
        \     | I.REL x => x\n\
        \\n\
        \ fun immSize imm =\n\
        \     case imm of\n\
        \       I.CONST_B _ => 1\n\
        \     | I.CONST_H _ => 2\n\
        \     | I.CONST_NB _ => 1\n\
        \     | I.CONST_NH _ => 2\n\
        \     | I.CONST_W _ => 4\n\
        \     | I.CONST_L _ => 4\n\
        \     | I.CONST_N _ => 4\n\
        \     | I.CONST_NL _ => 8\n\
        \     | I.CONST_F _ => 8\n\
        \     | I.CONST_FS _ => 4\n\
        \     | I.CONST_FL _ => 16\n\
        \     | I.EXTERN _ => "^fmtWordInt ptrsize^"\n\
        \\n\
        \ fun dumpImm (a, i, imm) =\n\
        \     case imm of\n\
        \       I.CONST_B x => dumpB (a, i, x)\n\
        \     | I.CONST_H x => dumpH (a, i, x)\n\
        \     | I.CONST_NB x => dumpNB (a, i, x)\n\
        \     | I.CONST_NH x => dumpNH (a, i, x)\n\
        \     | I.CONST_W x => dumpW (a, i, x)\n\
        \     | I.CONST_L x => dumpL (a, i, x)\n\
        \     | I.CONST_N x => dumpN (a, i, x)\n\
        \     | I.CONST_NL x => dumpNL (a, i, x)\n\
        \     | I.CONST_F x => dumpF (a, i, x)\n\
        \     | I.CONST_FS x => dumpFS (a, i, x)\n\
        \     | I.CONST_FL x => dumpFL (a, i, x)\n\
        \     | I.EXTERN _ => "^dump 0w0 ptrsize I.OA "0"^"\n\
        \\n\
        \fun nobits (ASM (l,a,i,m)) = {next=i, externs=nil}\n\
        \  | nobits (PROP (i,m)) = {next=i, externs=nil}\n\
        \\n\
        \fun dumpConst consts (ASM (l,a,i,m)) =\n\
        \    {next = foldl (fn (x,i) => (dumpImm (a, i, x); i + immSize x))\
        \ i consts,\n\
        \     externs = nil}\n\
        \  | dumpConst consts (PROP (i,m)) =\n\
        \    let\n\
        \      val (r, i) =\n\
        \          foldl\n\
        \            (fn (imm as I.EXTERN x, (r, i)) =>\n\
        \                let val s = immSize imm\n\
        \                in ({offset = i, size = 0w"^fmtWordInt ptrsize^",\n\
        \                     extern = x} :: r, i + s)\n\
        \                end\n\
        \              | (imm,(r,i)) => (r, i + immSize imm))\n\
        \            (nil, i) consts\n\
        \    in {next=i, externs=rev r} end\n\
        \\n\
        \fun dumpString str (ASM (l,a,i,m)) =\n\
        \    {next =\n\
        \       CharVector.foldl\n\
        \         (fn (c,i) => (dumpB (a, i, Word8.fromInt (ord c)); i + 1))\n\
        \         i str,\n\
        \     externs = nil}\n\
        \  | dumpString str (PROP (i,m)) =\n\
        \    {next = i + size str, externs = nil}\n\
        \\n\
        \"^String.concat funcs^"\
        \\n\
        \ fun asm m mode =\n\
        \   case m of\n\
        \     I.Label _ => nobits mode\n\
        \   | I.LocalLabel => nobits mode\n\
        \   | I.Const l => dumpConst l mode\n\
        \   | I.ConstString s => dumpString s mode\n\
        \   | I.Loc _ => nobits mode\n\
        \"^String.concat asmCases^"\
        \\n\
        \ fun property (x as (_,m)) = asm m (PROP x)\n\
        \ fun assemble (x as (_,_,_,m)) = #next (asm m (ASM x))\n\
        \end\n"
      end

  fun generate defs =
      {
        asm32_sml = genFunctor 0w4 "32" #format32 defs,
        asm64_sml = genFunctor 0w8 "64" #format64 defs
      }

end
