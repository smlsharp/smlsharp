(**
 * InterfaceHash.sml
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure InterfaceHash : sig

  val generate
      : {filename : Filename.filename,
         requires : InterfaceName.interface_name list,
         topdecs : AbsynInterface.topdec list}
        -> InterfaceName.hash
  val emptyHash : unit -> InterfaceName.hash

end =
struct

  structure A = AbsynInterface

  fun idToString (symbol, loc) = Symbol.toString symbol

  fun valbindName (A.VAL_EXTERN (id, ty, loc)) = id
    | valbindName (A.VAL_ALIAS (id, longid, loc)) = id
    | valbindName (A.VAL_BUILTIN (id, id2, ty, loc)) = id
    | valbindName (A.VAL_OVERLOAD (id, exp, loc)) = id

  fun listNamesValbind prefix valbind =
      [prefix ^ ".V" ^ idToString (valbindName valbind)]

  fun listNamesTypbind prefix (tyvars, id, ty, loc) =
      [prefix ^ ".T" ^ idToString id]

  fun listNamesTypdesc prefix (tyvars, id, impl, loc) =
      [prefix ^ ".T" ^ idToString id]

  fun listNamesTypbindOrTypdesc prefix typbind =
      case typbind of
        A.TYPBIND typbind => listNamesTypbind prefix typbind
      | A.TYPDESC typdesc => listNamesTypdesc prefix typdesc

  fun listNamesConbind prefix ((_, id, _), ty, loc) =
      prefix ^ ".C" ^ idToString id

  fun listNamesDatbind prefix (tyvars, id, conbind, loc) =
      prefix ^ ".T" ^ idToString id :: map (listNamesConbind prefix) conbind

  fun exbindName (A.EXBIND ((_, id, _), ty, loc)) = id
    | exbindName (A.EXBINDREP ((_, id, _), longid, loc)) = id

  fun listNamesExbind prefix exbind =
      [prefix ^ ".E" ^ idToString (exbindName exbind)]

  fun listNamesDec prefix pidec =
      case pidec of
        A.DECVAL (valbind, loc) =>
        listNamesValbind prefix valbind
      | A.DECTYPE (typbinds, loc) =>
        List.concat (map (listNamesTypbindOrTypdesc prefix) typbinds)
      | A.DECEQTYPE (typdescs, loc) =>
        List.concat (map (listNamesTypdesc prefix) typdescs)
      | A.DECDATATYPE (datbinds, NONE, loc) =>
        List.concat (map (listNamesDatbind prefix) datbinds)
      | A.DECDATATYPE (datbinds, SOME (typbinds, _), loc) =>
        List.concat (map (listNamesDatbind prefix) datbinds
                     @ map (listNamesTypbind prefix) typbinds)
      | A.DECDATATYPEREP (id, longtycon, loc) =>
        [prefix ^ ".T" ^ idToString id]
      | A.DECTYPEBUILTIN (id, name, loc) =>
        [prefix ^ ".T" ^ idToString id]
      | A.DECEXCEPTION (exbinds, loc) =>
        List.concat (map (listNamesExbind prefix) exbinds)
      | A.DECSTRUCTURE (strbind, loc) => listNamesStrbind prefix strbind
      | A.DECSEMICOLON loc => nil

  and listNamesStrbind prefix (strid, strexp, loc) =
      listNamesStrexp (prefix ^ ".S" ^ idToString strid) strexp

  and listNamesStrexp prefix strexp =
      case strexp of
        A.STRBASIC (decs, loc) =>
        List.concat (map (listNamesDec prefix) decs)
      | A.STRID id => [prefix] (* CHECK THIS *)
      | A.STRAPP (funid, longstrid, loc) => [prefix] (* CHECK THIS *)

  fun listNamesFunbind (funid, param, strexp, loc) =
      listNamesStrexp (".F" ^ idToString funid) strexp

  fun listNamesTopdec itopdec =
      case itopdec of
        A.TOPDEC dec => listNamesDec "" dec
      | A.TOPFUNCTOR (funbind, loc) => listNamesFunbind funbind
      | A.TOPINFIX (SOME n, ids, loc) =>
        map (fn id => "infix" ^ n ^ " " ^ idToString id) ids
      | A.TOPINFIX (NONE, ids, loc) =>
        map (fn id => "infix " ^ idToString id) ids
      | A.TOPINFIXR (SOME n, ids, loc) =>
        map (fn id => "infixr" ^ n ^ " " ^ idToString id) ids
      | A.TOPINFIXR (NONE, ids, loc) =>
        map (fn id => "infixr " ^ idToString id) ids
      | A.TOPNONFIX (ids, loc) =>
        map (fn id => "nonfix " ^ idToString id) ids

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
