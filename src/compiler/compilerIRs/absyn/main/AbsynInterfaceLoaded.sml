(* -*- sml -*- *)
(**
 * syntax for the interface.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @author Liu Bochao
 *)
structure AbsynInterfaceLoaded =
struct
  type loc = Absyn.loc
  type itopdec = AbsynInterface.topdec
  type sigdec = Absyn.sigdec
  type topdec = Absyn.topdec
  type interface_dec = itopdec InterfaceLoaded.interface_dec
  type 'loc interface = (itopdec, sigdec, 'loc) InterfaceLoaded.interface
  type compile_unit = (itopdec, sigdec, topdec) InterfaceLoaded.compile_unit
  type interface_unit = (itopdec, sigdec) InterfaceLoaded.interface_unit

  val printers =
      {printItopdec = AbsynFormatter.printItopdec,
       printSigdec = AbsynFormatter.printSigdec,
       printTopdec = AbsynFormatter.printTopdec}

  fun format_compile_unit x =
      PrintCalc.format_exp
        (InterfaceLoaded.printCompileUnit printers x)
  fun format_interface_unit x =
      PrintCalc.format_exp
        (InterfaceLoaded.printInterfaceUnit printers x)
end
