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
 *         | byte
 *         | byteArray
 *         | option
 * </pre>
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atsushi
 * @version $Id: TypeParser.sml,v 1.25 2008/08/06 17:23:41 ohori Exp $
 *)
structure TypeParser :> TYPE_PARSER =
struct

local
  structure TY = Types
  structure P = Path
  structure RBTVS = ReservedBoundTypeVarIDGen
in

    structure PC = ParserComb
    type ('a,'b) reader = 'b -> ('a * 'b) option
    type ('a, 'strm) parser = (char,'strm) reader -> ('a,'strm) reader
    type ty = Types.ty

    fun skipSP parser getc strm = 
        PC.seqWith #2 (PC.zeroOrMore (PC.token Char.isSpace), 
                       parser) getc strm

    exception TypeFormat of string
    fun readTy tyConEnv s = 
        let
            fun scanId getc strm =
                (PC.wrap
                     (
                      PC.oneOrMore
                          (PC.eatChar (fn ch => Char.isAlphaNum ch orelse ch = #"_" orelse ch = #".")),
                          String.implode
                          ) : (string, 'strm) parser) getc strm

            and scanTid tyConEnv getc strm = 
                skipSP
                    (PC.bind
                         (
                          scanId,
                          fn id =>
                             case SEnv.find(tyConEnv, id) of
                                 SOME (TY.TYCON {tyCon as {tyvars=[],...},...}) =>
                                 PC.result (TY.RAWty{tyCon=tyCon, args = []})
                             | _ => PC.failure before print("fail:"^id^"\n")
                                      ))
                    getc strm

            and scanTyvar getc strm =
               skipSP
                  (PC.seqWith #2
                  (PC.or(PC.string "''",
                         PC.string "'"),
                   PC.or(PC.seqWith 
                         #2 (PC.char #"a", 
                             PC.result (TY.BOUNDVARty (RBTVS.peekNth 0))),
                   PC.or(PC.seqWith 
                         #2 (PC.char #"b", 
                             PC.result (TY.BOUNDVARty (RBTVS.peekNth 1))),
                   PC.or(PC.seqWith 
                         #2 (PC.char #"c", 
                             PC.result (TY.BOUNDVARty (RBTVS.peekNth 2))),
                   PC.or(PC.seqWith 
                         #2 (PC.char #"d", 
                             PC.result (TY.BOUNDVARty (RBTVS.peekNth 3))),
                   PC.or(PC.seqWith 
                         #2 (PC.char #"e", 
                             PC.result (TY.BOUNDVARty (RBTVS.peekNth 4))),
                   PC.or(PC.seqWith 
                         #2 (PC.char #"f", 
                             PC.result (TY.BOUNDVARty (RBTVS.peekNth 5))),
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

            and scanTyName tyConEnv getc strm = 
                skipSP
                    (PC.bind
                         (
                          scanId,
                          fn id =>
                             case SEnv.find (tyConEnv, id) of
                                 SOME (TY.TYCON {tyCon,...}) =>
                                 PC.result (TY.RAWty, tyCon)
                               | _ => PC.failure
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
                         (fn (args, (con, tyCon)) => con {tyCon=tyCon, args=args})
                         (scanTyargs tyConEnv,
                          scanTyName tyConEnv))
                    getc strm

            and scanParenedTy tyConEnv getc strm = 
                PC.seqWith #2 
                           (skipSP(PC.char #"("),
                            PC.seqWith #1 (scanTy tyConEnv,
                                           skipSP(PC.char #")")))
                           getc strm

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
                PC.seqWith (fn ((btvid, eqKind), SOME L) => (btvid, {recordKind=TY.OVERLOADED L, eqKind = eqKind})
                             | ((btvid, eqKind), NONE) => (btvid, {recordKind=TY.UNIV, eqKind = eqKind}))
                           (scanBtvKindBtv,
                            PC.option (scanOverloadedKind tyConEnv))
                           getc strm

            and scanBtvKindBtv getc strm =
                PC.or
                    (PC.seqWith #2 
                    (PC.char #"'",
                     PC.or(PC.seqWith
                           #2 (PC.char #"a", 
                               PC.result (RBTVS.peekNth 0, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"b", 
                               PC.result (RBTVS.peekNth 1, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"c",
                               PC.result (RBTVS.peekNth 2, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"d", 
                               PC.result (RBTVS.peekNth 3, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"e",
                               PC.result (RBTVS.peekNth 4, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"f",
                               PC.result (RBTVS.peekNth 5, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"A",
                               PC.result (RBTVS.peekNth 0, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"B",
                               PC.result (RBTVS.peekNth 1, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"C",
                               PC.result (RBTVS.peekNth 2, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"D",
                               PC.result (RBTVS.peekNth 3, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"E",
                               PC.result (RBTVS.peekNth 4, TY.NONEQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"F",
                               PC.result (RBTVS.peekNth 5, TY.NONEQ)),
                           PC.failure))))))))))))),
                    PC.seqWith #2
                    (PC.string "''",
                     PC.or(PC.seqWith
                           #2 (PC.char #"a",
                               PC.result (RBTVS.peekNth 0, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"b",
                               PC.result (RBTVS.peekNth 1, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"c",
                               PC.result (RBTVS.peekNth 2, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"d",
                               PC.result (RBTVS.peekNth 3, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"e", 
                               PC.result (RBTVS.peekNth 4, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"f",
                               PC.result (RBTVS.peekNth 5, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"A",
                               PC.result (RBTVS.peekNth 0, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"B",
                               PC.result (RBTVS.peekNth 1, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"C",
                               PC.result (RBTVS.peekNth 2, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"D",
                               PC.result (RBTVS.peekNth 3, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"E",
                               PC.result (RBTVS.peekNth 4, TY.EQ)),
                     PC.or(PC.seqWith
                           #2 (PC.char #"F",
                               PC.result (RBTVS.peekNth 5, TY.EQ)),
                     PC.failure))))))))))))))
                getc strm

            and scanBtvEnv tyConEnv getc strm =
                PC.seqWith (fn (tvKindinfoList, _) => 
                               #2
                                   (foldr (fn ((btvid, {recordKind,eqKind}),(n,btvEnv)) =>
                                              (n+1,
                                               IEnv.insert(btvEnv, btvid, {index = n,
                                                                           recordKind = recordKind,
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
                  | TY.RAWty {tyCon, args} => foldr (fn (ty,n) => n + usedBtvarNum ty) 0 args
                  | TY.POLYty {boundtvars, body} =>
                    IEnv.numItems boundtvars + usedBtvarNum body
                  | t => raise Control.Bug "usedBtvarNum in TypeParser"

            val ty = 
                case ((skipSP (scanTy tyConEnv)) Substring.getc (Substring.full s))
                 of SOME (x,y) => if (Substring.isEmpty y) then x else 
(print s;print"\n";raise TypeFormat s)
                  | NONE =>
(print s;print"\n";raise TypeFormat s)

            
            val _ = RBTVS.advance (usedBtvarNum ty)
        in 
            (* 
             print (TypeFormatter.tyToString 0 (nil,IEnv.empty) ty ^ "\n");
             *)
            ty
        end
end;
end;
