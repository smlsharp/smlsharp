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

  fun listNamesTypbind prefix typbind =
      case typbind of 
	  A.TRANSPARENT {tyvars, tycon, ty,  loc} => [prefix ^ ".T" ^ tycon]
	| A.OPAQUE_NONEQ {tyvars, tycon, runtimeTy, loc} => [prefix ^ ".T" ^ tycon]
	| A.OPAQUE_EQ {tyvars, tycon, runtimeTy, loc} => [prefix ^ ".T" ^ tycon] 

  fun listNamesDatbind prefix ({tyvars, tycon, conbind}:A.datbind) =
      prefix ^ ".T" ^ tycon ::  map (fn {vid, ty} => prefix ^ ".C" ^ vid) conbind

  fun listNamesExbind prefix exbind =
      case exbind of
        A.EXNDEF {vid, ty, loc} => [prefix ^ ".E" ^ vid]
      | A.EXNDEF_WITHNAME {vid, ty, externPath, loc} => [prefix ^ ".E" ^ vid] (* CHECK THIS *)
      | A.EXNREP {vid, longvid, loc} => [prefix ^ ".E" ^ vid]

  fun listNamesDec prefix pidec =
      case pidec of
        A.IVAL valbinds =>
        List.concat (map (listNamesValbind prefix) valbinds)
      | A.ITYPE typbinds =>
        List.concat (map (listNamesTypbind prefix) typbinds)
      | A.IDATATYPE {datbind, loc} =>
        List.concat (map (listNamesDatbind prefix) datbind)
      | A.ITYPEREP {tycon, origTycon, loc} =>
        [prefix ^ ".T" ^ tycon]
      | A.ITYPEBUILTIN {tycon, builtinName, loc} =>
        [prefix ^ ".T" ^ tycon]
      | A.IEXCEPTION exbinds =>
        List.concat (map (listNamesExbind prefix) exbinds)
      | A.ISTRUCTURE strbind => listNamesStrbind prefix strbind

  and listNamesStrbind prefix ({strid, strexp, loc}:A.strbind) =
      listNamesStrexp (prefix ^ ".S" ^ strid) strexp

  and listNamesStrexp prefix istrexp =
      case istrexp of
        A.ISTRUCT {decs, loc} =>
        List.concat (map (listNamesDec prefix) decs)
      | A.ISTRUCTREP {strPath, loc} => [prefix] (* CHECK THIS *)
      | A.IFUNCTORAPP {functorName, argumentPath, loc} => [prefix] (* CHECK THIS *)

  fun listNamesFunbind ({funid, param, strexp, loc}:A.funbind) =
      listNamesStrexp (".F" ^ funid) strexp

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
