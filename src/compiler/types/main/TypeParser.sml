(**
 * Copyright (c) 2006, Tohoku University.
 *
 * A hand written type parser for setting up the compiler context.
 *
 * <pre>
 * ty ::= funTy | prodOrAtty
 * funTy ::= prodOrAtty -> ty
 * prodOrAtty ::= prodTy | atty
 * prodTy ::= {atty "*"}+ atty
 * atty ::= id
 *        | "'"tyId
 *        | "''"tyId
 *        | [tyvars . ty]
 *        | "(" ty ")"
 *        | (tyargs) tyCon
 * tyId ::= "a"
 *        | "b"
 *        | "c"
 *        | "d"
 *        | "e"
 *        | "f"
 *        | "A"
 *        | "B"
 *        | "C"
 *        | "D"
 *        | "E"
 *        | "F"
 * tyargs ::= "(" tySeq ")"
 * tySeq ::= {ty ","}* ty
 * tyCon ::= ref
 *         | list
 *         | array
 *         | largeInt
 *         | largeWord
 *         | byte
 *         | byteArray
 *         | option
 * </pre>
 * @author OHORI Atsushi
 * @version $Id: TypeParser.sml,v 1.10 2006/02/18 04:59:36 ohori Exp $
 *)
structure TypeParser : TYPE_PARSER =
struct

local
  structure TY = Types
  structure SE = StaticEnv
in

    structure PC = ParserComb
    type ('a,'b) reader = 'b -> ('a * 'b) option
    type ('a, 'strm) parser = (char,'strm) reader -> ('a,'strm) reader
    type ty = Types.ty

    fun skipSP parser = 
        fn getc => fn strm => 
        PC.seqWith #2 (PC.zeroOrMore (PC.token Char.isSpace), 
                       parser) getc strm

    fun scanTid getc strm = 
        PC.seqWith
            #2
            (
              PC.zeroOrMore (PC.token Char.isSpace),
              PC.or'
                  [
                    PC.seqWith #2 (PC.string "bool",PC.result SE.boolty),
                    PC.seqWith #2 (PC.string "int",PC.result SE.intty),
                    PC.seqWith #2 (PC.string "word",PC.result SE.wordty),
                    PC.seqWith #2 (PC.string "char",PC.result SE.charty),
                    PC.seqWith #2 (PC.string "string",PC.result SE.stringty),
                    PC.seqWith #2 (PC.string "real",PC.result SE.realty),
                    PC.seqWith #2 (PC.string "exn",PC.result SE.exnty),
                    PC.seqWith #2 (PC.string "unit",PC.result SE.unitty),
                    PC.seqWith
                        #2 (PC.string "largeInt",PC.result SE.largeIntty),
                    PC.seqWith
                        #2 (PC.string "largeWord",PC.result SE.largeWordty),
                    PC.seqWith
                        #2 (PC.string "byteArray",PC.result SE.byteArrayty),
                    PC.seqWith #2 (PC.string "byte",PC.result SE.bytety),
                    PC.failure
                  ]
            )
            getc strm

    and scanTyvar getc strm =
        PC.seqWith #2 (PC.zeroOrMore (PC.token Char.isSpace),
        PC.seqWith #2
        (PC.or(PC.string "''",
               PC.string "'"
               ),
           PC.or(PC.seqWith #2 (PC.char #"a", PC.result (TY.BOUNDVARty (0 + TY.peekBTid()))),
           PC.or(PC.seqWith #2 (PC.char #"b", PC.result (TY.BOUNDVARty (1 + TY.peekBTid()))),
           PC.or(PC.seqWith #2 (PC.char #"c", PC.result (TY.BOUNDVARty (2 + TY.peekBTid()))),
           PC.or(PC.seqWith #2 (PC.char #"d", PC.result (TY.BOUNDVARty (3 + TY.peekBTid()))),
           PC.or(PC.seqWith #2 (PC.char #"e", PC.result (TY.BOUNDVARty (4 + TY.peekBTid()))),
           PC.or(PC.seqWith #2 (PC.char #"f", PC.result (TY.BOUNDVARty (5 + TY.peekBTid()))),
           PC.failure))))))))
        getc strm

    and scanAtty getc strm = 
        PC.or(scanPolyTy,
        PC.or(scanTid,
        PC.or(scanTyvar,
        PC.or(scanConty,
              scanParenedTy))))
        getc strm

    and scanProdOrAtty getc strm =
        PC.or(scanProdTy,scanAtty)
        getc strm

    and scanTyStar getc strm =
        PC.seqWith #1 
        (PC.or(scanAtty,
               scanParenedTy),
         PC.seq(PC.zeroOrMore (PC.token Char.isSpace), 
                PC.char #"*"))
        getc strm

    and scanProdTy getc strm  =
        PC.seqWith (fn (x,y) => 
                    Types.RECORDty (#2 (foldl (fn (x,(n,fl)) =>
                                     (n+1,SEnv.insert(fl,Int.toString n,x)))
                              (1,SEnv.empty)
                              (x@[y]))))
        (PC.oneOrMore scanTyStar,
         PC.seqWith #2
         (PC.zeroOrMore(PC.token Char.isSpace),
          scanAtty))
        getc strm

    and scanTyArrow getc strm =
        PC.seqWith #1
        (scanProdOrAtty,
         PC.seq(PC.zeroOrMore (PC.token Char.isSpace), 
                PC.string "->"))
        getc strm

    and scanFunTy getc strm =        
        PC.seqWith (fn (x,y) => Types.FUNMty([x],y))
        (scanTyArrow,scanTy)
        getc strm

    and scanTyComma getc strm =
        PC.seqWith #1 
        (PC.or(scanTy,
               scanParenedTy),
         PC.seq(PC.zeroOrMore (PC.token Char.isSpace), 
                PC.char #","))
        getc strm

    and scanTyParen getc strm =
        PC.seqWith #1
        (scanTy,
         PC.char #")")
        getc strm

    and scanTyCon getc strm = 
        PC.seqWith
        #2
        (
          PC.zeroOrMore (PC.token Char.isSpace),
          PC.or'
          [
            PC.seqWith #2 (PC.string "ref",PC.result SE.refTyCon),
            PC.seqWith #2 (PC.string "list",PC.result SE.listTyCon),
            PC.seqWith #2 (PC.string "array",PC.result SE.arrayTyCon),
            PC.seqWith #2 (PC.string "option",PC.result SE.optionTyCon),
            PC.failure
          ]
        )
        getc strm

    and scanTyargs getc strm =
        PC.seqWith #2
        (PC.char #"(",
         PC.seqWith (fn (tyList, ty) => tyList @[ty])
         (PC.zeroOrMore scanTyComma,
          scanTyParen))
        getc strm

    and scanConty getc strm =
        PC.seqWith #2 
        (PC.zeroOrMore (PC.token Char.isSpace),
         PC.seqWith (fn (args, tyCon) => TY.CONty {tyCon=tyCon, args=args})
         (scanTyargs,
          scanTyCon))
        getc strm

    and scanParenedTy getc strm = 
        PC.seqWith #2 
        (skipSP(PC.char #"("),
         PC.seqWith #1 (scanTy,
                        skipSP(PC.char #")")))
        getc strm
(*
    and scanTvarName getc strm =
        PC.seqWith #2 (PC.zeroOrMore (PC.token Char.isSpace),
        PC.or(PC.seqWith #2 (PC.char #"a", PC.result 1),
        PC.or(PC.seqWith #2 (PC.char #"b", PC.result 2),
        PC.or(PC.seqWith #2 (PC.char #"c", PC.result 3),
        PC.or(PC.seqWith #2 (PC.char #"d", PC.result 4),
        PC.or(PC.seqWith #2 (PC.char #"e", PC.result 5),
        PC.or(PC.seqWith #2 (PC.char #"f", PC.result 6),
        PC.failure)))))))
        getc strm
*)
    and scanOverloadedKind getc strm =
      PC.or
       (PC.seqWith #2
         (PC.string "#{",
          (PC.seqWith (fn (L,x) => L@[x])
           (PC.zeroOrMore (PC.seqWith #1 (scanTid, PC.char #",")),
            PC.seqWith #1 (scanTid, PC.char #"}")))),
         PC.failure)
         getc strm

    and scanBtvKind getc strm =
      PC.seqWith (fn ((btvid, eqKind), SOME L) => (btvid, {recKind=TY.OVERLOADED L, eqKind = eqKind})
                   | ((btvid, eqKind), NONE) => (btvid, {recKind=TY.UNIV, eqKind = eqKind}))
      (scanBtvKindBtv,
       PC.option scanOverloadedKind)
      getc strm

    and scanBtvKindBtv getc strm =
        PC.or
         (PC.seqWith #2 
          (PC.char #"'",
           PC.or(PC.seqWith #2 (PC.char #"a", PC.result (0 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"b", PC.result (1 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"c", PC.result (2 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"d", PC.result (3 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"e", PC.result (4 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"f", PC.result (5 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"A", PC.result (0 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"B", PC.result (1 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"C", PC.result (2 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"D", PC.result (3 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"E", PC.result (4 + TY.peekBTid(), TY.NONEQ)),
           PC.or(PC.seqWith #2 (PC.char #"F", PC.result (5 + TY.peekBTid(), TY.NONEQ)),
           PC.failure))))))))))))),
          PC.seqWith #2
          (PC.string "''",
           PC.or(PC.seqWith #2 (PC.char #"a", PC.result (0 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"b", PC.result (1 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"c", PC.result (2 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"d", PC.result (3 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"e", PC.result (4 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"f", PC.result (5 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"A", PC.result (0 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"B", PC.result (1 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"C", PC.result (2 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"D", PC.result (3 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"E", PC.result (4 + TY.peekBTid(), TY.EQ)),
           PC.or(PC.seqWith #2 (PC.char #"F", PC.result (5 + TY.peekBTid(), TY.EQ)),
           PC.failure))))))))))))))
        getc strm

    and scanBtvEnv getc strm =
        PC.seqWith (fn (tvKindinfoList, _) => 
                    #2
                    (foldr (fn ((btvid, {recKind,eqKind}),(n,btvEnv)) =>
                            (n+1,
                             IEnv.insert(btvEnv, btvid, {index = n,
                                                         recKind = recKind,
                                                         eqKind = eqKind})))


                     (0,IEnv.empty)
                     tvKindinfoList))
        (PC.seqWith
             (fn (L,x) => L@[x])
             (PC.zeroOrMore (PC.seqWith #1 (scanBtvKind, PC.char #",")),
              scanBtvKind),
         PC.char #".")
        getc strm

    and scanPolyTy getc strm = 
        PC.seqWith #2
        (skipSP(PC.char #"["),
         PC.seqWith #1
         (PC.seqWith (fn (btvEnv, body) => TY.POLYty {boundtvars=btvEnv, body=body})
          (scanBtvEnv,
           scanTy),
          skipSP(PC.char #"]")))
        getc strm

    and scanTy getc strm =
        PC.or(scanFunTy,
              scanProdOrAtty)
        getc strm

    fun usedBtvarNum ty = 
      case ty of
      TY.TYVARty _ => 0
    | TY.BOUNDVARty _ => 0
    | TY.FUNMty (tyList,ty) => 
        foldl (fn (ty,n) => n + usedBtvarNum ty) (usedBtvarNum ty) tyList
    | TY.RECORDty fields =>
      SEnv.foldr (fn (ty,n) => n + usedBtvarNum ty) 0 fields
    | TY.CONty {tyCon, args} => foldr (fn (ty,n) => n + usedBtvarNum ty) 0 args
    | TY.POLYty {boundtvars, body} =>
      IEnv.numItems boundtvars + usedBtvarNum body
    | TY.BOXEDty => raise Control.Bug "usedBtvarNum in StaticEnv"
    | _ =>  raise Control.Bug "usedBtvarNum in StaticEnv"

  exception TypeFormat of string
  fun readTy s = 
      let
        val ty = 
          case ((skipSP scanTy) Substring.getc (Substring.all s))
            of SOME (x,y) => if (Substring.isEmpty y) then x else raise TypeFormat s
             | NONE => raise TypeFormat s
          val _ = TY.advanceBTid (usedBtvarNum ty)
      in ( 
          (* 
           print (TypeFormatter.tyToString 0 (nil,IEnv.empty) ty ^ "\n");
           *)
          ty)
      end
end;
end;
