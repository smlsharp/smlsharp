structure FormatByHand : sig

  type exp = SMLFormat.FormatExpression.expression list
  type 'a fmt = 'a -> exp

  val puts : string -> unit
  val putf : 'a fmt -> 'a -> 'a
  val putf' : 'a fmt -> 'a -> unit
  val put : exp -> unit

  val join : 'a fmt * exp -> 'a list fmt
  val rep : 'a fmt -> 'a list fmt
  val tm : string fmt

  (* int *)
  val pi : int fmt
  (* word *)
  val pw : word fmt
  (* string *)
  val ps : string fmt
  (* for tuple *)
  val p2 : 'a fmt * 'b fmt -> ('a * 'b) fmt
  val p3 : 'a fmt * 'b fmt * 'c fmt -> ('a * 'b * 'c) fmt
  val p4 : 'a fmt * 'b fmt * 'c fmt * 'd fmt -> ('a * 'b * 'c * 'd) fmt
  (* for list *)
  val pl : 'a fmt -> 'a list fmt
  (* for record *)
  val pr : (string * 'a fmt) list -> 'a fmt
  (* for map *)
  val pmap : (('k * 'v * exp -> exp) -> exp -> 'a fmt) -> 'k fmt
             -> 'v fmt -> 'a fmt

  type ('context, 'hole, 'result) fmtcomb

  val %` : string -> ('h, 'h, 'r) fmtcomb -> 'r
  val % : ('c, 'a -> 'h, 'a fmt -> string -> ('c, 'h, 'r) fmtcomb -> 'r) fmtcomb
  val ` : ('c, exp, 'c) fmtcomb

  (* %`"hoge "%pi"fuga"` *)

end =
struct

  open SMLFormat.FormatExpression
  open SMLFormat.BasicFormatters

  type exp = expression list
  type 'a fmt = 'a -> exp

  fun puts str = print (str ^ "\n")
  fun put exp = (print (SMLFormat.prettyPrint nil exp); print "\n")
  fun putf fmt x = (put (fmt x); x)
  fun putf' fmt x = put (fmt x)

  fun tm "" = nil | tm x = [Term (size x, x)]
  val nl = [Newline]
  fun gr l = [Guard (NONE, l)]
  fun cut l = [Guard (SOME {cut=true, strength=0, direction=Neutral}, l)]
  fun i n = [Indicator {space=true, newline=SOME {priority=Preferred n}}]
  val sp = [Indicator {space=true, newline=NONE}]
  fun ind n l = StartOfIndent n :: l @ [EndOfIndent]

  val join = format_list
  fun rep f l = format_list (f, nil) l

  fun concatc nil = nil
    | concatc [h] = h
    | concatc (h::t) = h @ tm "," @ i 1 @ concatc t

  val pi = format_int
  val pw = format_word
  fun ps x = tm "\"" @ tm x @ tm "\""

  fun p2 (f1,f2) (x1,x2) =
      tm "(" @ concatc [f1 x1, f2 x2] @ tm ")"
  fun p3 (f1,f2,f3) (x1,x2,x3) =
      tm "(" @ concatc [f1 x1, f2 x2, f3 x3] @ tm ")"
  fun p4 (f1,f2,f3,f4) (x1,x2,x3,x4) =
      tm "(" @ concatc [f1 x1, f2 x2, f3 x3, f4 x4] @ tm ")"

  fun pl f x = tm "[" @ cut (join (f, tm "," @ i 1) x) @ tm "]"

  fun pr l x =
      tm "{" @
      cut (join (fn (nam,f) => gr (tm nam @ sp @ tm "=" @ ind 2 (i 1 @ f x)),
                 tm "," @ i 1) l) @
      tm "}"

  fun pmap foldri fmtKey fmtValue x =
      tm "{" @
      cut (foldri (fn (k,v,z) =>
                      fmtKey k @ sp @ tm "->" @ ind 2 (i 2 @ fmtValue v) @
                      tm "," @ i 1 @ z)
                  nil x) @
      tm "}"

  type ('context, 'hole, 'result) fmtcomb =
       ((exp -> 'hole) -> 'context) -> 'result

  fun %` str comb =
      comb (fn h => h (tm str))

  fun % context (fmt:'a fmt) str comb =
      comb (fn h => context (fn t => fn x => h (t @ fmt x @ tm str)))

  fun ` context =
      context (fn t => t:exp)

end
