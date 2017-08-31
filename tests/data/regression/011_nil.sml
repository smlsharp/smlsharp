val x = nil
(*
2011-08-12 ohori

This causes RecordCompilation loop.

Fixed. 2011-08-12 ohori.

This is due to the loop
  compileExp RCDATACONSTRUCT 
  etaExpandPoly RCDATACONSTRUCT
  complineExp (POLY(TAPP(RCDATACONSTRUCT, tys))
  complineExp RCDATACONSTRUCT
Fixed by changing (TAPP(RCDATACONSTRUCT, tys) to
  RCDATACONSTRUCT with instTyList.
*)
