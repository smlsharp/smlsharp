(**
 * InterfaceHash.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure InterfaceHash : sig

  val generate
      : {filename : Filename.filename,
         requires : InterfaceName.interface_name list,
         topdecs : AbsynInterface.itopdec list}
        -> InterfaceName.hash
  val emptyHash : unit -> InterfaceName.hash

end =
struct

  structure A = AbsynInterface
  val symbolToString = Symbol.symbolToString

  fun listNamesValbind prefix ({symbol, body, loc}:A.valbind) =
      [prefix ^ ".V" ^ symbolToString symbol]

  fun listNamesTypbindTrans prefix {tyvars, symbol, ty, loc} =
      [prefix ^ ".T" ^ symbolToString symbol]

  fun listNamesTypbind prefix typbind =
      case typbind of 
	  A.TRANSPARENT t => listNamesTypbindTrans prefix t
	| A.OPAQUE {eq, tyvars, symbol, runtimeTy, loc} => [prefix ^ ".T" ^ symbolToString symbol]

  fun listNamesDatbind prefix ({tyvars, symbol, conbind}:A.datbind) =
      prefix ^ ".T" ^ symbolToString symbol ::
      map (fn {symbol, ty} => prefix ^ ".C" ^ symbolToString symbol) conbind

  fun listNamesExbind prefix exbind =
      case exbind of
        A.EXNDEF {symbol, ty, loc} => [prefix ^ ".E" ^ symbolToString symbol]
      | A.EXNREP {symbol, longsymbol, loc} => [prefix ^ ".E" ^ symbolToString symbol]

  fun listNamesDec prefix pidec =
      case pidec of
        A.IVAL valbind =>
        listNamesValbind prefix valbind
      | A.ITYPE typbinds =>
        List.concat (map (listNamesTypbind prefix) typbinds)
      | A.IDATATYPE {datbind, withType, loc} =>
        List.concat (map (listNamesDatbind prefix) datbind
                     @ map (listNamesTypbindTrans prefix) withType)
      | A.ITYPEREP {symbol, longsymbol, loc} =>
        [prefix ^ ".T" ^ symbolToString symbol]
      | A.ITYPEBUILTIN {symbol, builtinSymbol, loc} =>
        [prefix ^ ".T" ^ symbolToString symbol]
      | A.IEXCEPTION exbinds =>
        List.concat (map (listNamesExbind prefix) exbinds)
      | A.ISTRUCTURE strbind => listNamesStrbind prefix strbind

  and listNamesStrbind prefix ({symbol, strexp, loc}:A.strbind) =
      listNamesStrexp (prefix ^ ".S" ^ symbolToString symbol) strexp

  and listNamesStrexp prefix istrexp =
      case istrexp of
        A.ISTRUCT {decs, loc} =>
        List.concat (map (listNamesDec prefix) decs)
      | A.ISTRUCTREP {longsymbol, loc} => [prefix] (* CHECK THIS *)
      | A.IFUNCTORAPP {functorSymbol, argument, loc} => [prefix] (* CHECK THIS *)

  fun listNamesFunbind ({functorSymbol, param, strexp, loc}:A.funbind) =
      listNamesStrexp (".F" ^ symbolToString functorSymbol) strexp

  fun fixityToString fixity =
      case fixity of
        A.INFIXL (SOME n) => "infix" ^ n
      | A.INFIXL NONE => "infix"
      | A.INFIXR (SOME n) => "infixr" ^ n
      | A.INFIXR NONE => "infixr"
      | A.NONFIX => "nonfix"

  fun listNamesTopdec itopdec =
      case itopdec of
        A.IDEC dec => listNamesDec "" dec
      | A.IFUNDEC funbind => listNamesFunbind funbind
      | A.IINFIX {fixity, symbols, loc} =>
        let
          val prefix = fixityToString fixity ^ " "
        in
          map (fn x => prefix ^ symbolToString x) symbols
        end

  fun generate {filename, requires, topdecs} =
      let
        val sourceName = Filename.toString (Filename.basename filename)
(*
        val sourceName =
            case source of
              A.GENERATED => ""
            | A.LOADED (_, path) => Filename.toString (Filename.basename path)
*)
        val names1 = ["this " ^ sourceName]
        val names2 = map (fn {hash, ...} : InterfaceName.interface_name =>
                             InterfaceName.hashToString hash)
                         requires
        val names3 = List.concat (map listNamesTopdec topdecs)
        val names = names1 @ names2 @ names3
        val names = ListSorter.sort String.compare names
        val src = String.concatWith "\n" names
      in
        InterfaceName.hash src
      end

  fun emptyHash () =
      InterfaceName.hash ""

end
