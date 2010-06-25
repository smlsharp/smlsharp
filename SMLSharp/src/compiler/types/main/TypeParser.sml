(**
 * A hand written type parser for setting up the compiler context.
 *
 * 2010-5-30: It is extended  to include constructor types in 
 * OVERLOADED kind
 *
 * <pre>
 * id ::= (alphanumeric | _ | .)+
 * tyId ::= id (in TyconEnv with 0 arguments)
 * tyCon ::= id (in TyconEnv with n arguments)
 * tyvarId ::= "a" | "b" | "c" | "d" | "e" | "f"
 * tyvar ::= "'"tyId | "''"tyId
 * btv ::= "'"tyId  | "''"tyId
 *
 * ty ::= funTy | prodOrAtty
 * funTy ::= prodOrAtty -> ty
 * prodOrAtty ::= prodTy | recordTy  | atty
 * prodTy ::= {atty "*"}+ atty
 * recordTy ::= "{" field "}"
 * field ::= 
 *         | id ":" ty ("," id ":" ty)* 
 * atty ::= tyId
 *        | tyvar
 *        | polyTy
 *        | parenedTy 
 *        | (tyargs) tyCon  (with arity check) 
 * polyTy ::= [btvEnv ty]
 * btvEnv ::= (btvWithKind ",")* btvWithKind
 * btvWithKind ::= btv | btv kind
 * kind ::=  "::" "{" tySeq "}" (overloaded constants)
 *         | "#" "{" tySeq "}"  (overloaded primitives)
 *         | "#" "{" recField "}"
 * parenedTy ::= "(" ty ")"
 * btvars ::= {btvar ","}* btvar "."
 * tyargs ::= "(" tySeq ")"
 * tySeq ::= {ty ","}* ty
 * btbar ::= tyvar
 *         | tyvar kind
 *
 * </pre>
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atsushi
 * @version $Id: TypeParser.sml,v 1.25.6.1 2009/09/03 03:35:00 katsu Exp $
 *)
structure TypeParser (* :> TYPE_PARSER *) =
struct

local
  structure TY = Types
  structure P = Path
  structure BTV = BoundTypeVarID
in
  structure PC = ParserComb
  type ('a,'b) reader = 'b -> ('a * 'b) option
  type ('a, 'strm) parser = (char,'strm) reader -> ('a,'strm) reader
  type ty = Types.ty
  exception TypeFormat of string

  fun skipSP parser getc strm = 
      PC.seqWith #2 (PC.zeroOrMore (PC.token Char.isSpace), 
                     parser) getc strm

  fun scanId getc strm =
      (PC.wrap
         (
          PC.oneOrMore
            (PC.eatChar
               (fn ch => Char.isAlphaNum ch
                         orelse
                         ch = #"_" orelse ch = #".")),
          String.implode
         ) : (string, 'strm) parser) getc strm
            
  fun scanTyId tyConEnv getc strm = 
      skipSP
        (PC.bind
           (
            scanId,
            fn id =>
               case SEnv.find(tyConEnv, id) of
                 SOME (TY.TYCON {tyCon as {tyvars=[],...},...}) =>
                 PC.result (TY.RAWty{tyCon=tyCon, args = []})
               | _ => 
                 (print id;
                  print " not found.";
                  print "\n";
                  PC.failure)
           )
        )
        getc strm

  fun scanTyCon tyConEnv getc strm = 
      skipSP
        (PC.bind
           (
            scanId,
            fn id =>
               case SEnv.find (tyConEnv, id) of
                 SOME (TY.TYCON {tyCon as {tyvars,...},...}) =>
                 PC.result (TY.RAWty, tyCon, List.length tyvars)
               | _ =>
                 (print id;
                  print " not found.";
                  print "\n";
                  PC.failure)
        ))
        getc strm

  fun scanTyvarId getc strm =
      PC.or(PC.seqWith
              #2 (PC.char #"a", 
                  PC.result (BTV.peekNth 0)),
      PC.or(PC.seqWith
              #2 (PC.char #"b", 
                  PC.result (BTV.peekNth 1)),
      PC.or(PC.seqWith
              #2 (PC.char #"c", 
                  PC.result (BTV.peekNth 2)),
      PC.or(PC.seqWith
              #2 (PC.char #"d", 
                  PC.result (BTV.peekNth 3)),
      PC.or(PC.seqWith
              #2 (PC.char #"e", 
                  PC.result (BTV.peekNth 4)),
      PC.or(PC.seqWith
              #2 (PC.char #"f",
                  PC.result (BTV.peekNth 5)),
      PC.failure
      ))))))
      getc strm

  fun scanBtv getc strm =
      PC.wrap
        (PC.or(
         PC.seq(PC.seqWith #2 (PC.char #"'", PC.result TY.NONEQ),
                scanTyvarId),
         PC.seq(PC.seqWith #2 (PC.string "''", PC.result TY.EQ),
                scanTyvarId)),
         (fn (eqkind, btvid) => (btvid, eqkind))
        )
        getc strm

  fun scanTyvar getc strm =
      skipSP
        (PC.seqWith
           (fn (_,btvid) => TY.BOUNDVARty btvid)
           (PC.or(PC.string "''", PC.string "'"),
            scanTyvarId)
        )
        getc strm

  fun readTy tyConEnv s = 
      let
        fun scanTy tyConEnv getc strm =
            PC.or(scanFunTy tyConEnv,scanProdOrAtty tyConEnv)
                 getc strm

        and scanFunTy tyConEnv getc strm =        
            PC.seqWith
              (fn (x,y) => Types.FUNMty([x],y))
              (
               PC.seqWith
                 #1
                 (scanProdOrAtty tyConEnv,
                  skipSP (PC.string "->")),
               scanTy tyConEnv
              )
              getc strm

        and scanProdOrAtty tyConEnv getc strm =
            PC.or'
              [scanRecordTy tyConEnv, scanProdTy tyConEnv, scanAtty tyConEnv]
              getc strm

        and scanProdTy tyConEnv getc strm  =
            PC.seqWith
              (fn (x,y) => 
                  Types.RECORDty
                    (#2
                      (foldl (fn (x,(n,fl)) =>
                                 (n+1,SEnv.insert(fl,Int.toString n,x)))
                             (1,SEnv.empty)
                             (x@[y]))))
              (PC.oneOrMore (scanTyStar tyConEnv),
               skipSP (scanAtty tyConEnv))
              getc strm

        and scanTyStar tyConEnv getc strm =
            PC.seqWith
              #1 
              (PC.or(scanAtty tyConEnv, scanParenedTy tyConEnv),
               skipSP(PC.char #"*"))
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

        and scanField tyConEnv getc strm =
            PC.seqWith
              (fn (id, (_, ty)) => (id, ty))
              (scanId, PC.seq(PC.char #":", scanTy tyConEnv))
              getc strm

        and scanAtty tyConEnv getc strm = 
            PC.or(scanPolyTy tyConEnv,
            PC.or(scanTyId tyConEnv,
            PC.or(scanTyvar,
            PC.or(scanConty tyConEnv,
                  scanParenedTy tyConEnv))))
                 getc strm

        and scanPolyTy tyConEnv getc strm = 
            PC.seqWith
              #2
              (skipSP(PC.char #"["),
               PC.seqWith
                 #1
                 (PC.seqWith
                    (fn (btvEnv, body) =>
                        TY.POLYty {boundtvars=btvEnv, body=body})
                    (scanBtvEnv tyConEnv, scanTy tyConEnv),
                  skipSP(PC.char #"]")))
              getc strm

        and scanBtvEnv tyConEnv getc strm =
            PC.seqWith
              (fn (tvKindinfoList, _) => 
                  foldr
                    (fn ((btvid, {recordKind,eqKind}),btvEnv) =>
                        IEnv.insert(btvEnv,
                                    btvid,
                                    {recordKind = recordKind,
                                     eqKind = eqKind}))
                    IEnv.empty
                    tvKindinfoList)
              (PC.seqWith
                 (fn (L,x) => L@[x])
                 (PC.zeroOrMore
                    (PC.seqWith #1 (scanBtvWithKind tyConEnv, PC.char #",")),
                  scanBtvWithKind tyConEnv),
               PC.char #".")
              getc strm

        and scanBtvWithKind tyConEnv getc strm =
            PC.seqWith
              (fn ((btvid, eqKind), SOME k) =>
                  (btvid, {recordKind=k, eqKind = eqKind})
                | ((btvid, eqKind), NONE) =>
                  (btvid, {recordKind=TY.UNIV, eqKind = eqKind}))
              (scanBtv, PC.option (scanKind tyConEnv))
              getc strm


        and scanKind tyconEnv getc strm = 
            PC.or (scanOverloadedConstKind tyConEnv,
            PC.or (scanOverloadedPrimKind tyConEnv,
                   scanRecordKind tyConEnv))
            getc strm

        and scanOverloadedConstKind tyConEnv getc strm =
            PC.or
              (PC.seqWith 
                 #2
                 (PC.string "::{",
                  (PC.seqWith 
                     (fn (L,x) => TY.OCONSTkind (L@[x]))
                     (PC.zeroOrMore
                        (PC.seqWith 
                           #1
                           (PC.or (scanTyId tyConEnv,
                                   scanConty tyConEnv),
                            PC.char #",")),
                      PC.seqWith 
                        #1 
                        (PC.or (scanConty tyConEnv,
                                scanTyId tyConEnv),
                         PC.char #"}")))),
               PC.failure)
              getc strm

        and scanOverloadedPrimKind tyConEnv getc strm =
            PC.or
              (PC.seqWith 
                 #2
                 (PC.string "#{",
                  (PC.seqWith 
                     (fn (L,x) => TY.OPRIMkind
                                    {
                                     instances = L@[x],
                                     operators = nil
                                    }
                     )
                     (PC.zeroOrMore
                        (PC.seqWith 
                           #1
                           (PC.or (scanTyId tyConEnv,
                                   scanConty tyConEnv),
                            PC.char #",")),
                      PC.seqWith
                        #1 
                        (PC.or (scanConty tyConEnv,
                                scanTyId tyConEnv),
                         PC.char #"}")))),
               PC.failure)
              getc strm

        and scanRecordKind tyConEnv getc strm =
            PC.seqWith (fn (_,TY.RECORDty x) => TY.REC x
                         | _ => raise Control.Bug "scanRecordKind")
                       (PC.char #"#", scanRecordTy tyConEnv)
                       getc strm

        and scanParenedTy tyConEnv getc strm = 
            PC.seqWith #2 
                       (skipSP(PC.char #"("),
                        PC.seqWith #1 (scanTy tyConEnv,
                                       skipSP(PC.char #")")))
                       getc strm

        and scanConty tyConEnv getc strm =
            skipSP
              (PC.bind
               (PC.seq (scanTyargs tyConEnv, scanTyCon tyConEnv),
                fn (args, (con, tyCon, arity)) =>
                   if List.length args = arity then
                     PC.result (con {tyCon=tyCon, args=args})
                   else (print "argNumber\n";PC.failure)))
              getc strm

        and scanTyargs tyConEnv getc strm =
            PC.seqWith #2
                       (PC.char #"(",
                        PC.seqWith (fn (tyList, ty) => tyList @[ty])
                                   (PC.zeroOrMore (scanTyComma tyConEnv),
                                    scanTyParen tyConEnv))
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

        fun usedBtvarNum ty = 
            case ty of
              TY.TYVARty _ => 0
            | TY.BOUNDVARty _ => 0
            | TY.FUNMty (tyList,ty) => 
              foldl
                (fn (ty,n) => n + usedBtvarNum ty)
                (usedBtvarNum ty)
                tyList
            | TY.RECORDty fields =>
              SEnv.foldr (fn (ty,n) => n + usedBtvarNum ty) 0 fields
            | TY.RAWty {tyCon, args} =>
              foldr (fn (ty,n) => n + usedBtvarNum ty) 0 args
            | TY.POLYty {boundtvars, body} =>
              IEnv.numItems boundtvars + usedBtvarNum body
            | t => raise Control.Bug "usedBtvarNum in TypeParser"

        val ty = 
            case ((skipSP (scanTy tyConEnv)) Substring.getc (Substring.full s))
             of SOME (x,y) => if (Substring.isEmpty y) then x else 
                              (print s;print"\n";raise TypeFormat s)
              | NONE =>
                (print "readTy\n";
                 print s;print"\n";
                 raise TypeFormat s)
        val _ = BTV.advance (usedBtvarNum ty)
      in 
        (* 
         print (TypeFormatter.tyToString 0 (nil,IEnv.empty) ty ^ "\n");
        *)
        ty
      end
end
end
