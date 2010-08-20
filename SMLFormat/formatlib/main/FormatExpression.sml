(**
 *  This module defines types which represents format expressions and operators
 * on them.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FormatExpression.sml,v 1.4 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
structure FormatExpression : FORMAT_EXPRESSION =
struct

  (***************************************************************************)

  open FormatExpressionTypes

  (***************************************************************************)

  fun isHigherThan (_, Deferred) = true
    | isHigherThan (Deferred, _) = false
    | isHigherThan (Preferred left, Preferred right) = left < right

  fun assocToString {cut, strength, direction} =
      let
        val directionText = 
            case direction of Left => "L" | Right => "R" | Neutral => "N"
      in
        (if cut then "!" else "") ^ directionText ^ (Int.toString strength)
      end

  fun priorityToString (Preferred priority) = Int.toString priority
    | priorityToString Deferred = "d"

  fun toString (Term (columns, text)) = "\"" ^ text ^ "\""
    | toString Newline = "\\n"
    | toString (Guard(assocOpt, expressions)) =
      (case assocOpt of
         NONE => "{"
       | SOME assoc => (assocToString assoc) ^ "{")
      ^ (concat (map (fn exp => (toString exp) ^ " ") expressions))
      ^ "}"
    | toString (Indicator{space, newline}) =
      (if space then "+" else "")
      ^ (case newline of
           NONE => ""
         | SOME{priority} => priorityToString priority)
    | toString (StartOfIndent indent) =  Int.toString indent ^ "["
    | toString EndOfIndent = "]"

  local
    structure PC = ParserComb

    fun escapedChar getc stream =
        PC.or
            (
              PC.wrap
                  (
                    PC.seq(PC.char #"\\", PC.eatChar (fn _ => true)),
                    fn (_, ch) => implode [#"\\", ch]
                  ),
              PC.wrap(PC.eatChar (fn ch => ch <> #"\""), fn ch => str ch)
            )
            getc stream
  
    fun string getc stream =
        PC.seqWith
            (fn (_, (cs, _)) => let val s = concat cs in Term(size s, s) end)
            (PC.char #"\"", PC.seq(PC.zeroOrMore escapedChar, PC.char #"\""))
            getc stream
  
    (* "\\n" *)
    fun newline getc stream =
        PC.wrap (PC.string "\\n", fn _ => Newline) getc stream
  
    (*
     * "!"?[LRN]("~")?{num}
     *)
    fun assocIndicator getc stream =
        PC.seqWith
            (fn (cutOpt, (direction, strength)) =>
                 {
                   cut = isSome cutOpt,
                   direction = direction,
                   strength = strength
                 })
            (
              PC.option(PC.char #"!"),
              PC.seq
                  (
                    PC.or'
                        [
                          PC.bind(PC.char #"L", fn _ => PC.result Left) ,
                          PC.bind(PC.char #"R", fn _ => PC.result Right) ,
                          PC.bind(PC.char #"N", fn _ => PC.result Neutral)
                        ],
                    Int.scan StringCvt.DEC
                  )
            )
            getc stream
  
    (* {associndicator}?"{"{expressions}"}" *)
    fun guard getc stream =
        PC.seqWith
            (fn (assocOpt, (_, (exps, _))) => Guard (assocOpt, exps))
            (
              PC.option assocIndicator,
              PC.seq (PC.char #"{", PC.seq (expressions, PC.char #"}"))
            )
            getc stream
  
    (* "~"?{num}"[" *)
    and startOfIndent getc stream =
        PC.wrap
            (
              PC.seq (Int.scan StringCvt.DEC, PC.char #"["),
              fn (level, _) => StartOfIndent level
            )
            getc stream
  
    (* "]" *)
    and endOfIndent getc stream =
        PC.wrap (PC.char #"]", fn _ => EndOfIndent) getc stream
  
    (* "d"|{num} *)
    and priority getc stream =
        PC.or
            (
              PC.wrap (PC.char #"d", fn _ => Deferred),
              PC.wrap (Int.scan StringCvt.DEC, fn n => Preferred n)
            )
            getc stream
  
    (* "+"?{priority}|"+" *)
    and indicator getc stream =
        PC.or
            (
              PC.seqWith
                  (fn (spaceOpt, priority) =>
                      Indicator
                          {
                            space = isSome spaceOpt,
                            newline = SOME{priority = priority}
                          })
                  (PC.option (PC.char #"+"), priority),
              PC.wrap
                  (
                    PC.char #"+",
                    fn _ => Indicator {space = true, newline = NONE}
                  )
            )
            getc stream
  
    and expression getc stream =
        PC.or'
            [
              string,
              newline,
              guard,
              startOfIndent,
              endOfIndent,
              indicator
            ]
            getc stream
  
    and expressions getc stream =
        PC.seqWith
            #1
            (
              PC.skipBefore
                  Char.isSpace
                  (PC.oneOrMore (PC.skipBefore Char.isSpace expression)),
              PC.zeroOrMore (PC.eatChar Char.isSpace)
            )
            getc stream
  in

  fun parse getc stream = expressions getc stream

  end
  
  (***************************************************************************)
  
end