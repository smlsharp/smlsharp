(**
 * x86 RTL
 * @copyright (c) 2009, 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLEMIT = sig

  structure Target : sig
    type reg
    type program
    type nextDummy
  end

  type frameLayout
  val format_frameLayout : frameLayout TermFormat.formatter

  val emit : {regAlloc: Target.reg VarID.Map.map,
              layoutMap: frameLayout ClusterID.Map.map}
             -> RTL.program
             -> {code: Target.program, nextDummy: Target.nextDummy}

  val formatOf : RTL.ty -> RTL.format

end
