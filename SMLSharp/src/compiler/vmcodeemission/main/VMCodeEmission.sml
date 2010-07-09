(**
 * VM code emission.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMCodeEmission.sml,v 1.7 2008/01/23 08:20:07 katsu Exp $
 *)
structure VMCodeEmission : VMCODEEMISSION =
struct

  structure VM = VMMnemonic
  structure M = MachineLanguage
  structure A = AssemblyCode

  type target = VM.instruction list
  type program = target M.program
  type cluster = target M.cluster
  type basicBlock = target M.basicBlock
  type registerDescMap = M.registerDesc IEnv.map

  (* FIXME: 32bit platform *)
  val wordSize = 0w4
  val maxAlign = 0w8

  infix || <<
  val (op ||) = Word32.orb
  val (op <<) = Word32.<<

  fun toW w = Word32.fromLarge (Word.toLarge w)
  val toOffset = toW
  val toLSZ = toW
  fun toSSZ x = Int32.fromLarge (Word.toLargeInt x)

  type context =
      {
        registerClass: M.registerClassDesc vector,
        frameLayout: M.stackFrameLayout
      }

  fun entityClass entity =
      case entity of
        M.REGISTER (x, _) => x
      | M.STACK (x, _) => x
      | M.HANDLER x => x

  fun emitEntity ({frameLayout={slotAlloc, ...}, ...}:context) entity =
      case entity of
        M.REGISTER (_, id) => VM.REG id
      | M.STACK (_, id) =>
        (case WEnv.find (slotAlloc, id) of
           SOME x => VM.VAR x
         | NONE => raise Control.Bug ("emitEntity: unallocated STACK: "^
                                      Word.fmt StringCvt.DEC id))
      | M.HANDLER x =>
        raise Control.Bug "not implemented: HANDLER"

  fun initFrame (context as {frameLayout, ...}:context)
                (reg1, reg2) =
      let
        fun evalWordComposition l =
            let
              fun eval x nil = x
                | eval x ({shift, value}::t) =
                  eval (x || (toW value << shift)) t
            in
              eval 0w0 l
            end

        fun evalHeaderComposition nil = nil
          | evalHeaderComposition ({offset, value}::t) =
            VM.MVI (VM.W, VM.VAR offset,
                    VM.CONST_W (evalWordComposition value))
            :: evalHeaderComposition t

        fun evalBitmapComposition nil = nil
          | evalBitmapComposition (h::t) =
            (case h of
               M.LSHIFT {dst, arg, shift} =>
               VM.SHLI (VM.W, emitEntity context dst,
                        emitEntity context arg, shift)
             | M.RSHIFT {dst, arg, shift} =>
               VM.SHRI (VM.W, emitEntity context dst,
                        emitEntity context arg, shift)
             | M.ORB {dst, arg1, arg2} =>
               VM.OR   (VM.W, emitEntity context dst,
                        emitEntity context arg1, emitEntity context arg2)
             | M.MASK {dst, arg, numBits} =>
               VM.ANDI (VM.W, emitEntity context dst, emitEntity context arg,
                        VM.CONST_W ((0w1 << numBits) - 0w1))
             | M.LOAD {dst, block, offset} =>
               VM.LDM  (VM.W, emitEntity context dst,
                        emitEntity context block, toSSZ offset)
             | M.SAVE {offset, arg} =>
               VM.MOV  (VM.W, VM.VAR offset,
                        emitEntity context arg)) ::
            evalBitmapComposition t
      in
        evalHeaderComposition (#initHeader frameLayout) @
        evalBitmapComposition (#initBitmap frameLayout (reg1, reg2)) @
        map (fn v => VM.NULL (VM.VAR v)) (#initPointers frameLayout)
      end

  fun emitInsn (context as {registerClass, frameLayout}:context) insn =
      case insn of
        M.Spill {dst, src} =>
        let
          val size = #size (Vector.sub (registerClass, entityClass dst))
              handle Subscript =>
                     raise Control.Bug ("undefined register class: "
                                        ^Int.toString (entityClass dst))
        in
          [ VM.MOVX (size, emitEntity context dst, emitEntity context src) ]
        end
      | M.Code {code = [ VM.ENTER _ ], def, ...} =>
        if #frameSize frameLayout = 0w0 
        then nil
        else
          let
            (* first two def are registers for stack frame initialization *)
            val (reg1, reg2) =
                case def of
                  {ty = M.ALLOCED ent1,...}::{ty = M.ALLOCED ent2,...}::_ =>
                  (ent1, ent2)
                | _ =>
                  raise Control.Bug "emitInsn: ENTER"
          in
            VM.ENTER (toLSZ (#frameSize frameLayout))
            :: initFrame context (reg1, reg2)
          end
      | M.Code {code = [ VM.LEAVE _ ], ...} =>
        if #frameSize frameLayout = 0w0
        then nil
        else [ VM.LEAVE (toLSZ (#frameSize frameLayout)) ]
      | M.Code {code, use, def, loc, ...} =>
        let
          fun makeSubst vars =
              map (fn {ty,...}:M.varInfo =>
                      case ty of
                        M.ALLOCED ent => emitEntity context ent
                      | _ => raise Control.Bug "emitInsn: Code")
                  vars
          val subst = makeSubst use @ makeSubst def
        in
(*
          VM.Loc (Control.prettyPrint (Loc.format_loc loc)) ::
*)
          map (VMMnemonic.substHole subst) code
        end

  fun emitBlock context ({label, instructionList, continue, ...}:basicBlock) =
      let
        val label = VMCodeSelection.labelString label

        val insns =
            case continue of
              NONE => nil
            | SOME l => [ VM.BR (VM.LABELREF (VMCodeSelection.labelString l)) ]

        val insns =
            foldr (fn (insn, insns) => emitInsn context insn @ insns)
                  insns instructionList
      in
        VM.Label label :: insns
      end

  fun emitCluster ({name, entries, registerDesc, frameInfo, body, loc, ...}
                   :cluster) =
      let
        val frameLayout =
            FrameLayout.makeFrame {frameInfo = frameInfo,
                                   frameSizeAlign = maxAlign,
                                   wordSize = wordSize}

(*
        val _ = print ("emitCluster:\n")
        val _ = print "slotAlloc:\n"
        val _ =
            WEnv.appi (fn (k,v) => print (Word.fmt StringCvt.DEC k^" -> "^Word.fmt StringCvt.DEC v^"\n")) (#slotAlloc frameLayout)
        val _ = print ("frameSize: "^Word.fmt StringCvt.DEC (#frameSize frameLayout)^"\n")
*)

        val regClass = Vector.fromList (#classes registerDesc)

        val context =
            {
              frameLayout = frameLayout,
              registerClass = regClass
            }
      in
        foldr (fn (block, body) => emitBlock context block @ body) nil body
      end

  fun emitNobits exportLabels ({slots, size, alignment}:M.globalSegment) =
      let
        val symbols =
            foldl (fn ({label, offset}, map) =>
                      SEnv.insert (map, label, toOffset offset))
                  SEnv.empty
                  slots

        (* currently all global array slots are exported *)
        val exportLabels =
            foldl (fn ({label, offset}, map) =>
                      SEnv.insert (map, label, true))
                  exportLabels
                  slots
      in
        ({
           size = toOffset size,
           symbols = symbols,
           alignment = toOffset alignment
         } : A.nobitsSection,
         exportLabels)
      end

  fun emit (program as {toplevel, clusters, constants,
                        unboxedGlobals, boxedGlobals}:program) =
      let
        (* all entry labels are to be local symbols. *)
        val exports =
            foldl
              (fn ({entries, ...}, map) =>
                  foldl
                    (fn (x, z) =>
                        SEnv.insert (map, VMCodeSelection.labelString x, false))
                    map
                    entries)
              SEnv.empty
              clusters

        val textAlignment =
            case clusters of
              {alignment, ...}::_ => alignment
            | nil => 0w1

        val text = List.concat (map emitCluster clusters)
        val init = List.concat (#code toplevel)
        val data = List.concat (#code constants)

        (* all constant labels are to be local symbols. *)
        val exports =
            foldl
              (fn (VM.Label label, map) => SEnv.insert (map, label, false)
                | (_, map) => map)
              exports
              data

        val (bss, exports) = emitNobits exports unboxedGlobals
        val (bbss, exports) = emitNobits exports boxedGlobals
      in
        {
          exportLabels = exports,
          init = {code = init, alignment = toOffset (#alignment toplevel)},
          text = {code = text, alignment = toOffset textAlignment},
          data = {code = data, alignment = toOffset (#alignment constants)},
          bss  = bss,
          bbss = bbss
        } : VM.instruction list A.program
      end
      handle exn => raise exn

end
