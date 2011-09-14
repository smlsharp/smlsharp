(**
 * x86 RTL
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure RTLBackendContext : sig

  datatype toplevelLabel =
      TOP_NONE                    (* no toplevel label is specified *)
    | TOP_MAIN                    (* toplevel as the unique "main" function *)
    | TOP_SEQ of                  (* middle of sequence of toplevels *)
      {from: string, next: string}

  type context =
      {toplevelLabel: toplevelLabel}

  val empty : context
  val extend : context * context -> context

  val suffixNumber : string -> (string * int) option

end =
struct

  datatype toplevelLabel =
      TOP_NONE
    | TOP_MAIN
    | TOP_SEQ of {from: string, next: string} (* must be global symbols *)
  type context =
      {toplevelLabel: toplevelLabel}

  fun extend ({toplevelLabel=label1}:context, {toplevelLabel=label2}:context) =
      {
        toplevelLabel =
          case (label1, label2) of
            (TOP_NONE, _) => label2
          | (_, TOP_NONE) => label1
          | (TOP_SEQ (s1 as {next,...}), TOP_SEQ (s2 as {from,...})) =>
            if next = from
            then TOP_SEQ {from = #from s1, next = #next s2}
            else raise Control.Bug "RTLSelectContext.extend: cannot extend"
          | _ => raise Control.Bug "RTLSelectContext.extend: TOP_MAIN"
      }
      : context

  val empty =
      {toplevelLabel = TOP_NONE}

  fun suffixNumber label =
      let
        val ss = Substring.full label
        val (prefix, suffix) = Substring.splitl (fn c => c <> #".") ss
        val suffix = Substring.triml 1 suffix
      in
        case Int.scan StringCvt.DEC Substring.getc suffix of
          NONE => NONE
        | SOME (n, s) =>
          if Substring.isEmpty s
          then SOME (Substring.string prefix, n) else NONE
      end

end
