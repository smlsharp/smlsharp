(**
 * InterfaceHash.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure InterfaceHash : sig

  val generate : string * string list * AbsynInterface.itopdec list
                 -> string
 
end =
struct

  structure A = AbsynInterface

  fun listNamesValbind prefix ({vid, body, loc}:A.valbind) =
      [prefix ^ ".V" ^ vid]

  fun listNamesTypbind prefix ({tyvars, tycon, ty, opacity, loc}:A.typbind) =
      [prefix ^ ".T" ^ tycon]

  fun listNamesDatbind prefix ({tyvars, tycon, conbind, opacity}:A.datbind) =
      prefix ^ ".T" ^ tycon
      :: (case opacity of
            A.TRANSPARENT => map (fn {vid, ty} => prefix ^ ".C" ^ vid) conbind
          | A.OPAQUE_NONEQ => nil
          | A.OPAQUE_EQ => nil)

  fun listNamesExbind prefix exbind =
      case exbind of
        A.EXNDEF {vid, ty, loc} => [prefix ^ ".E" ^ vid]
      | A.EXNREP {vid, longvid, loc} => [prefix ^ ".E" ^ vid]

  fun listNamesDec prefix pidec =
      case pidec of
        A.IVAL valbinds =>
        List.concat (map (listNamesValbind prefix) valbinds)
      | A.ITYPE typbinds =>
        List.concat (map (listNamesTypbind prefix) typbinds)
      | A.IDATATYPE {datbind, loc} =>
        List.concat (map (listNamesDatbind prefix) datbind)
      | A.ITYPEREP {tycon, origTycon, opacity, loc} =>
        [prefix ^ ".T" ^ tycon]
      | A.ITYPEBUILTIN {tycon, builtinName, opacity, loc} =>
        [prefix ^ ".T" ^ tycon]
      | A.IEXCEPTION exbinds =>
        List.concat (map (listNamesExbind prefix) exbinds)
      | A.ISTRUCTURE strbinds =>
        List.concat (map (listNamesStrbind prefix) strbinds)

  and listNamesStrbind prefix ({strid, strexp, loc}:A.strbind) =
      listNamesStrexp (prefix ^ ".S" ^ strid) strexp

  and listNamesStrexp prefix istrexp =
      case istrexp of
        A.ISTRUCT {decs, loc} =>
        List.concat (map (listNamesDec prefix) decs)

  fun listNamesFunbind ({funid, param, strexp, loc}:A.funbind) =
      listNamesStrexp (".F" ^ funid) strexp

  fun fixityToString fixity =
      case fixity of
        A.INFIXL (SOME n) => "infix" ^ BigInt.toString n
      | A.INFIXL NONE => "infix"
      | A.INFIXR (SOME n) => "infixr" ^ BigInt.toString n
      | A.INFIXR NONE => "infixr"
      | A.NONFIX => "nonfix"

  fun listNamesTopdec itopdec =
      case itopdec of
        A.IDEC dec => listNamesDec "" dec
      | A.IFUNDEC funbinds =>
        List.concat (map listNamesFunbind funbinds)
      | A.IINFIX {fixity, vids, loc} =>
        let
          val prefix = fixityToString fixity ^ " "
        in
          map (fn x => prefix ^ x) vids
        end

  fun generate (sourceName, requireHashes, topdecs) =
      let
        val sourceName = Filename.fromString sourceName
        val sourceName = Filename.toString (Filename.basename sourceName)
        val names1 = ["this " ^ sourceName]
        val names2 = map (fn x => "req " ^ x) requireHashes
        val names3 = List.concat (map listNamesTopdec topdecs)
        val names = names1 @ names2 @ names3
        val names = ListSorter.sort String.compare names
        val src = String.concatWith "\n" names
      in
        SHA1.toBase32 (SHA1.digest (Byte.stringToBytes src))
      end

end
