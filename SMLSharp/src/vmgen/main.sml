structure Main : sig

  val main : string -> OS.Process.status
  val debug : int ref

end =
struct

  val MLcomment = ("(*", "*)")
  val Ccomment = ("/*", "*/")


  fun output (cbeg, cend) filename content =
      let
        val file = TextIO.openOut filename
      in
        (
          TextIO.output
            (file, cbeg^" This is auto-generated file. Do not edit! "^cend^
                   "\n\n");
          TextIO.output (file, content)
        )
        handle e =>
               (TextIO.closeOut file;
                OS.FileSys.remove filename;
                raise e);
        TextIO.closeOut file
      end

  fun sum f l = foldl (fn (x,z) => f x + z) 0 l

  val debug = ref 0

  fun dump level title format defs =
      if (!debug < 0 andalso level <= ~(!debug)) orelse !debug = level then
      (
        print ("\n" ^ title ^ ":\n");
        app (fn x => print (SMLFormat.prettyPrint [] (format x) ^ "\n")) defs
      )
      else ()

  fun main filename =
      let
        val defs = Parser.parse filename

        val _ = dump 1 "Source" InsnDef.format_def defs

        (* elabolation *)
        val elabDefs = Elaboration.elaborate defs

        val _ = dump 2 "Elaborated" InsnDef.format_def_elaborated elabDefs

        val numElabDefs = length elabDefs

        (* mnemonics -> type-specialized mnemonics *)
        (* I.MOV (I.F, ....)  ==> I.MOVF .... *)
        val typedDefs = TypeCheck.typecheck elabDefs

        val _ = dump 3 "Typechecked" InsnDef.format_def_typechecked typedDefs

        val numTypedDefs = sum (length o #variants) typedDefs

        (* type-specialized mnemonics -> mother instructions *)
        (* I.MOVF (I.REG, I.REG) ==> I.MOVF_rr *)
        val motherDefs = MotherGen.generate typedDefs

        val _ = dump 4 "Mother" InsnDef.format_def_mother motherDefs

        val numMotherDefs = sum (length o #variants) motherDefs

        (* mother instructions -> implementations *)
        (* I.ADDIF_rr (x, y, 0) ==> I.ADDIF_rr_0 (x, y) *)
        (* I.MOVF_rr _ :: X ==> I.MOVF_rr_X *)
        val implDefs = Fusion.fusion motherDefs

        val _ = dump 5 "Implementations" InsnDef.format_def_impl implDefs

        val numInsnDefs = length implDefs

        val _ = print (Int.toString numElabDefs^" definitions\n")
        val _ = print (Int.toString numTypedDefs^" preliminaries\n")
        val _ = print (Int.toString numMotherDefs^" mother instructions\n")
        val _ = print (Int.toString numInsnDefs^" implementations\n")

        (* definition of vm_mnemonic *)
        val mnemonic_sml = MLMnemonicGen.generate elabDefs
        val _ = output MLcomment "VMMnemonic.sml" mnemonic_sml

        (* mnemonic parser : string -> vm_mnemonic *)
        val parser_sml = MLParserGen.generate elabDefs
        val _ = output MLcomment "VMMnemonicParserFn.sml" parser_sml

        (* mnemonic printer : vm_mnemonic -> string *)
        val formatter_sml = MLFormatterGen.generate elabDefs
        val _ = output MLcomment "VMMnemonicFormatterFn.sml" formatter_sml

        (* assemble : vm_mnemonic -> Word8Array *)
        val {asm32_sml, asm64_sml} = MLAssembleGen.generate motherDefs
        val _ = output MLcomment "VMMnemonicAssemblerFn32.sml" asm32_sml
        val _ = output MLcomment "VMMnemonicAssemblerFn64.sml" asm64_sml

        (* preprocess : Word8Array -> ready_form *)
        val {prep32_c, prep64_c} = CPreprocessGen.generate implDefs
        val _ = output Ccomment "prep32.inc" prep32_c
        val _ = output Ccomment "prep64.inc" prep64_c

        (* eval : ready_form -> unit *)
        val {ops32_c, optab32_c, ops64_c, optab64_c} =
            CEvalGen.generate implDefs
        val _ = output Ccomment "ops32.inc" ops32_c
        val _ = output Ccomment "ops64.inc" ops64_c
        val _ = output Ccomment "optab32.inc" optab32_c
        val _ = output Ccomment "optab64.inc" optab64_c

(*
        (* disassemble : Word8Array -> vm_mnemonic *)
        val disasm_sml = MLDisasmbleGen.generate motherDefs
*)
      in
        OS.Process.success
      end
      handle Control.Error msgs =>
             (Control.printError msgs; OS.Process.failure)
           | e as Control.Bug msg =>
             (TextIO.output (TextIO.stdErr, "[BUG] " ^ msg ^ "\n"); raise e)

end
