(**
 * emit llvm module
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure LLVMEmit =
struct

  structure L = LLVMIR

  type phi_map =
      (L.value * L.phi_label) list list FunLocalLabel.Map.map
  val empty = FunLocalLabel.Map.empty : phi_map
  fun singleton srcLabel (dstLabel, args) : phi_map =
      FunLocalLabel.Map.singleton
        (dstLabel, map (fn (ty, v) => [(v, srcLabel)]) args)
  fun singleton' srcLabel (dstLabel, args) : phi_map =
      FunLocalLabel.Map.singleton
        (dstLabel, map (fn v => [(v, srcLabel)]) args)
  fun merge (map1, map2) : phi_map =
      FunLocalLabel.Map.unionWith
        (ListPair.mapEq (op @))
        (map1, map2)

  fun makePhiMap label ((_, last):L.body) =
      case last of
        L.BLOCK {label = blockLabel, phis, body, next} =>
        merge (makePhiMap label next, makePhiMap (L.BLOCKLABEL blockLabel) body)
      | L.LANDINGPAD {label = blockLabel, body, next, ...} =>
        merge (makePhiMap label next, makePhiMap (L.LPADLABEL blockLabel) body)
      | L.RET _ => empty
      | L.RET_VOID => empty
      | L.BR dest => singleton label dest
      | L.BR_C (cond, dest1, dest2) =>
        merge (singleton label dest1, singleton label dest2)
      | L.INVOKE {result, to, ...} =>
        singleton' label (to, case result of SOME v => [L.VAR v] | NONE => nil)
      | L.RESUME _ => empty
      | L.SWITCH {value, default, branches} =>
        foldl merge
              (singleton label default)
              (map (singleton label o #2) branches)
      | L.UNREACHABLE => empty

  fun completePhiPhi (p as L.PHI_COMPLETE _, _) = p
    | completePhiPhi (L.PHI (ty, var), args) = L.PHI_COMPLETE (var, ty, args)

  fun completePhiLast phiMap last =
      case last of
        L.BLOCK {label, phis, body, next} =>
        let
          val phiArgs =
              case FunLocalLabel.Map.find (phiMap, label) of
                NONE => map (fn _ => nil) phis  (* dead code *)
              | SOME phiArgs => phiArgs
          val phis =
              ListPair.mapEq
                (fn (L.PHI (ty, var), args) => L.PHI_COMPLETE (var, ty, args)
                    | (p, _) => p)
                (phis, phiArgs)
              handle ListPair.UnequalLengths => raise Bug.Bug "completePhiBody"
        in
          L.BLOCK {label = label,
                   phis = phis,
                   body = completePhiBody phiMap body,
                   next = completePhiBody phiMap next}
        end
      | L.LANDINGPAD {label, argVar, catch, cleanup, body, next} =>
        L.LANDINGPAD {label = label,
                      argVar = argVar,
                      catch = catch,
                      cleanup = cleanup,
                      body = completePhiBody phiMap body,
                      next = completePhiBody phiMap next}
      | L.RET _ => last
      | L.RET_VOID => last
      | L.BR _ => last
      | L.BR_C _ => last
      | L.INVOKE _ => last
      | L.RESUME _ => last
      | L.SWITCH _ => last
      | L.UNREACHABLE => last

  and completePhiBody phiMap ((mid, last):L.body) =
      (mid, completePhiLast phiMap last)

  fun completePhiTopdec topdec =
      case topdec of
        L.DEFINE (args as {body, ...}) =>
        let
          val phiMap = makePhiMap L.BEGINFUNC body
        in
          L.DEFINE (args # {body = completePhiBody phiMap body})
        end
      | L.DECLARE _ => topdec
      | L.GLOBALVAR _ => topdec
      | L.ALIAS _ => topdec
      | L.EXTERN _ => topdec

  fun completePhi ({moduleName, datalayout, triple, topdecs}:L.program) =
      {moduleName = moduleName,
       datalayout = datalayout,
       triple = triple,
       topdecs = map completePhiTopdec topdecs}
      : L.program

  (* ToDo: SMLFormat and TextIO are too slow to print possibly huge LLVM IR *)
  type file = unit ptr
  val fopen_c = _import "fopen" : (string, string) -> file
  val fputs_c = _import "fputs" : (string, file) -> int
  val fclose = _import "fclose" : file -> int

  fun fopen x =
      let
        val r = fopen_c x
      in
        if Pointer.isNull r
        then raise SMLSharp_Runtime.OS_SysErr ()
        else r
      end

  fun fputs x =
      if fputs_c x < 0
      then raise SMLSharp_Runtime.OS_SysErr ()
      else ()

  fun output file indents nil nil = ()
    | output file indents nil (h :: t) =
      output file indents h t
    | output file indents (h :: t) k =
      case h of
        SMLFormat.FormatExpression.Term (_, s) =>
        (fputs (s, file); output file indents t k)
      | SMLFormat.FormatExpression.Guard (_, expressions) =>
        output file indents expressions (t :: k)
      | SMLFormat.FormatExpression.Indicator {space = true, ...} =>
        (fputs (" ", file); output file indents t k)
      | SMLFormat.FormatExpression.Indicator {space = false, ...} =>
        output file indents t k
      | SMLFormat.FormatExpression.Sequence expressions =>
        output file indents expressions (t :: k)
      | SMLFormat.FormatExpression.Newline =>
        let
          val indent = case indents of i::_ => i | nil => 0
          val spaces = CharVector.tabulate (indent, fn _ => #" ")
        in
          fputs ("\n" ^ spaces, file);
          output file indents t k
        end
      | SMLFormat.FormatExpression.StartOfIndent i =>
        let
          val indent = case indents of j::_ => i + j | nil => i
        in
          output file (indent :: indents) t k
        end
      | SMLFormat.FormatExpression.EndOfIndent =>
        output file (case indents of nil => nil | _::l => l) t k
  val output = fn file => fn l => output file nil l nil

  fun emit program =
      let
        val program = completePhi program
        val fe = LLVMIR.format_program program
        val llfile = TempFile.create ("." ^ LLVMUtils.ASMEXT)
(*
        val ir = SMLFormat.prettyPrint nil fe
        val _ = CoreUtils.makeTextFile (llfile, ir)
*)
        val out = fopen (Filename.toString llfile, "w")
        val r = (output out fe; NONE) handle e => SOME e
        val _ = fclose out
        val _ = case r of NONE => () | SOME e => raise e
      in
        llfile
      end

end
