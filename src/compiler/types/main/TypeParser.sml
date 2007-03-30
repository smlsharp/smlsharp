(**
 * A hand written type parser for setting up the compiler context.
 *
 * <pre>
 * ty ::= funTy | prodOrAtty
 * funTy ::= prodOrAtty -> ty
 * prodOrAtty ::= recTy | prodTy | atty
 * prodTy ::= {atty "*"}+ atty
 * recTy ::= "{" id ":" ty ("," id ":" ty)* "}"
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
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atsushi
 * @version $Id: TypeParser.sml,v 1.15 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
structure TypeParser :> TYPE_PARSER =
struct

local
  structure TY = Types
in

    structure PC = ParserComb
    type ('a,'b) reader = 'b -> ('a * 'b) option
    type ('a, 'strm) parser = (char,'strm) reader -> ('a,'strm) reader
    type ty = Types.ty

    fun skipSP parser getc strm = 
        PC.seqWith #2 (PC.zeroOrMore (PC.token Char.isSpace), 
                       parser) getc strm

    fun scanId getc strm =
        (PC.wrap
            (
              PC.oneOrMore
                  (PC.eatChar (fn ch => Char.isAlpha ch orelse ch = #"_")),
              String.implode
            ) : (string, 'strm) parser) getc strm

    and scanTid tyConEnv getc strm = 
        skipSP
            (PC.bind
                 (
                   scanId,
                   fn id =>
                      case SEnv.find(tyConEnv, id)
                       of SOME (TY.TYCON(tyCon as {tyvars = [], ...})) =>
                          PC.result (TY.CONty{tyCon = tyCon, args = []})
                        | _ => PC.failure
                 ))
            getc strm

    and scanTyvar getc strm =
        skipSP
        (PC.seqWith #2
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

    and scanAtty tyConEnv getc strm = 
        PC.or(scanPolyTy tyConEnv,
        PC.or(scanTid tyConEnv,
        PC.or(scanTyvar,
        PC.or(scanConty tyConEnv,
              scanParenedTy tyConEnv))))
        getc strm

    and scanProdOrAtty tyConEnv getc strm =
        PC.or'
            [scanRecordTy tyConEnv, scanProdTy tyConEnv, scanAtty tyConEnv]
            getc strm

    and scanTyStar tyConEnv getc strm =
        PC.seqWith
            #1 
            (PC.or(scanAtty tyConEnv, scanParenedTy tyConEnv),
             skipSP(PC.char #"*"))
            getc strm

    and scanField tyConEnv getc strm =
        PC.seqWith
            (fn (id, (_, ty)) => (id, ty))
            (scanId, PC.seq(PC.char #":", scanTy tyConEnv))
            getc strm

    and scanRecordTy tyConEnv getc strm =
        PC.seqWith
            (fn (_, SOME fields) =>
                TY.RECORDty
                    (foldl
                         (fn ((id, ty), env) => SEnv.insert (env, id, ty))
                         SEnv.empty
                         fields)
              | (_, NONE) => TY.RECORDty SEnv.empty)
            (
              PC.char #"{",
              PC.seqWith
                  #1
                  (
                    PC.option
                        (PC.seqWith
                             (fn (first, tail) => first :: tail)
                             (
                               scanField tyConEnv,
                               PC.zeroOrMore
                                   (PC.seqWith
                                        #2 (PC.char #",", scanField tyConEnv))
                             )),
                    PC.char #"}"
                  )
            )
            getc strm

    and scanProdTy tyConEnv getc strm  =
        PC.seqWith (fn (x,y) => 
                    Types.RECORDty (#2 (foldl (fn (x,(n,fl)) =>
                                     (n+1,SEnv.insert(fl,Int.toString n,x)))
                              (1,SEnv.empty)
                              (x@[y]))))
        (PC.oneOrMore (scanTyStar tyConEnv),
         skipSP (scanAtty tyConEnv))
        getc strm

    and scanTyArrow tyConEnv getc strm =
        PC.seqWith #1
        (scanProdOrAtty tyConEnv,
         skipSP (PC.string "->"))
        getc strm

    and scanFunTy tyConEnv getc strm =        
        PC.seqWith (fn (x,y) => Types.FUNMty([x],y))
        (scanTyArrow tyConEnv,scanTy tyConEnv)
        getc strm

    and scanTyComma tyConEnv getc strm =
        PC.seqWith #1 
        (PC.or(scanTy tyConEnv,
               scanParenedTy tyConEnv),
         skipSP (PC.char #","))
        getc strm

    and scanTyParen tyConEnv getc strm =
        PC.seqWith #1
        (scanTy tyConEnv,
         PC.char #")")
        getc strm

    and scanTyCon tyConEnv getc strm = 
        skipSP
          (PC.bind
               (
                 scanId,
                 fn id =>
                    case SEnv.find (tyConEnv, id)
                     of SOME (TY.TYCON tyCon) => PC.result tyCon
                      | NONE => PC.failure
               ))
          getc strm

    and scanTyargs tyConEnv getc strm =
        PC.seqWith #2
        (PC.char #"(",
         PC.seqWith (fn (tyList, ty) => tyList @[ty])
         (PC.zeroOrMore (scanTyComma tyConEnv),
          scanTyParen tyConEnv))
        getc strm

    and scanConty tyConEnv getc strm =
        skipSP
            (PC.seqWith
                 (fn (args, tyCon) => TY.CONty {tyCon=tyCon, args=args})
                 (scanTyargs tyConEnv,
                  scanTyCon tyConEnv))
            getc strm

    and scanParenedTy tyConEnv getc strm = 
        PC.seqWith #2 
        (skipSP(PC.char #"("),
         PC.seqWith #1 (scanTy tyConEnv,
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
    and scanOverloadedKind tyConEnv getc strm =
      PC.or
       (PC.seqWith #2
         (PC.string "#{",
          (PC.seqWith (fn (L,x) => L@[x])
           (PC.zeroOrMore (PC.seqWith #1 (scanTid tyConEnv, PC.char #",")),
            PC.seqWith #1 (scanTid tyConEnv, PC.char #"}")))),
         PC.failure)
         getc strm

    and scanBtvKind tyConEnv getc strm =
      PC.seqWith (fn ((btvid, eqKind), SOME L) => (btvid, {recKind=TY.OVERLOADED L, eqKind = eqKind})
                   | ((btvid, eqKind), NONE) => (btvid, {recKind=TY.UNIV, eqKind = eqKind}))
      (scanBtvKindBtv,
       PC.option (scanOverloadedKind tyConEnv))
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

    and scanBtvEnv tyConEnv getc strm =
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
             (PC.zeroOrMore (PC.seqWith #1 (scanBtvKind tyConEnv, PC.char #",")),
              scanBtvKind tyConEnv),
         PC.char #".")
        getc strm

    and scanPolyTy tyConEnv getc strm = 
        PC.seqWith #2
        (skipSP(PC.char #"["),
         PC.seqWith #1
         (PC.seqWith (fn (btvEnv, body) => TY.POLYty {boundtvars=btvEnv, body=body})
          (scanBtvEnv tyConEnv,
           scanTy tyConEnv),
          skipSP(PC.char #"]")))
        getc strm

    and scanTy tyConEnv getc strm =
        PC.or(scanFunTy tyConEnv,
              scanProdOrAtty tyConEnv)
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
    | TY.BOXEDty => raise Control.Bug "usedBtvarNum in TypeParser"
    | _ =>  raise Control.Bug "usedBtvarNum in TypeParser"

  exception TypeFormat of string
  fun readTy tyConEnv s = 
      let
        val ty = 
          case ((skipSP (scanTy tyConEnv)) Substring.getc (Substring.all s))
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
