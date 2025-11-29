(* -*- sml -*- *)
(**
 * syntax for the interface.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @author Liu Bochao
 *)
structure InterfaceLoaded =
struct

  type loc = Absyn.loc

  type 'itopdec interface_dec =
      {interfaceId: InterfaceID.id,
       interfaceName: InterfaceName.interface_name,
       requiredIds: {id: InterfaceID.id, loc: loc} list,
       provideTopdecs: 'itopdec list}

  type ('itopdec, 'sigdec, 'loc) interface =
      {interfaceDecs : 'itopdec interface_dec list,
       provide :
         {requiredIds : {id : InterfaceID.id, loc : 'loc} list,
          locallyRequiredIds : {id : InterfaceID.id, loc : 'loc} list,
          provideTopdecs : 'itopdec list},
       topdecsInclude: 'sigdec list}

  type ('itopdec, 'sigdec, 'topdec) compile_unit =
      {interface : ('itopdec, 'sigdec, loc) interface option,
       topdecsSource : 'topdec list}

  type ('itopdec, 'sigdec) interface_unit =
      {interfaceDecs : 'itopdec interface_dec list,
       requiredIds : {id : InterfaceID.id, loc : unit} list,
       topdecsInclude : 'sigdec list}

  structure P = PrintCalc

  fun printInterfaceId id =
      P.N0 (P.FORMAT (InterfaceID.format_id id))

  fun printInterfaceName name =
      P.N0 (P.FORMAT (InterfaceName.format_interface_name name))

  fun printRequiredId {id, loc} =
      P.REQUIRE (printInterfaceId id, nil)

  fun printLocallyRequiredId {id, loc} =
      P.REQUIRE_LOCAL (printInterfaceId id, nil)

  fun printDecs nil = P.EXPLIST nil
    | printDecs decs = P.TOPDECS decs

  fun printInterfaceDec {printItopdec, ...}
                        {interfaceId, interfaceName, requiredIds,
                         provideTopdecs} =
      P.EXPROW
        (P.EXPTYPED
           (printInterfaceId interfaceId,
            printInterfaceName interfaceName),
         printDecs
           (map printRequiredId requiredIds
            @ map printItopdec provideTopdecs))

  fun printProvide {printItopdec, ...}
                   {requiredIds, locallyRequiredIds, provideTopdecs} =
      P.EXPROW
        (P.KEYWORD ["provide"],
         printDecs
           (map printRequiredId requiredIds
            @ map printLocallyRequiredId locallyRequiredIds
            @ map printItopdec provideTopdecs))

  fun printInterface (printers as {printSigdec, ...})
                     {interfaceDecs, provide, topdecsInclude} =
      P.EXPRECORD
        (map (printInterfaceDec printers) interfaceDecs
         @ [printProvide printers provide,
            P.EXPROW
              (P.KEYWORD ["topdecsInclude"],
               printDecs (map printSigdec topdecsInclude))],
         false)

  fun printCompileUnit (printers as {printTopdec, ...})
                       {interface, topdecsSource} =
      P.TOPDECS
        ((case interface of
            NONE => nil
          | SOME interface => [P.INTERFACE (printInterface printers interface)])
         @ map printTopdec topdecsSource)

  fun printInterfaceUnit (printers as {printSigdec, ...})
                         {interfaceDecs, requiredIds, topdecsInclude} =
      P.TOPDECS
        (map (printInterfaceDec printers) interfaceDecs
         @ map printRequiredId requiredIds
         @ map printSigdec topdecsInclude)

end
