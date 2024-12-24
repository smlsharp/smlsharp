(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcLoc =
struct

  structure R = RecordCalc

  fun locExp exp =
      case exp of
        R.RCVALUE (_, loc) => loc
      | R.RCSTRING (_, loc) => loc
      | R.RCEXVAR (_, loc) => loc
      | R.RCFNM {loc, ...} => loc
      | R.RCAPPM {loc, ...} => loc
      | R.RCSWITCH {loc, ...} => loc
      | R.RCPRIMAPPLY {loc, ...} => loc
      | R.RCRECORD {loc, ...} => loc
      | R.RCSELECT {loc, ...} => loc
      | R.RCMODIFY {loc, ...} => loc
      | R.RCLET {loc, ...} => loc
      | R.RCRAISE {loc, ...} => loc
      | R.RCHANDLE {loc, ...} => loc
      | R.RCTHROW {loc, ...} => loc
      | R.RCCATCH {loc, ...} => loc
      | R.RCFOREIGNAPPLY {loc, ...} => loc
      | R.RCCALLBACKFN {loc, ...} => loc
      | R.RCCAST {loc, ...} => loc
      | R.RCINDEXOF {loc, ...} => loc

end
