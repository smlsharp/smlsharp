(**
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * <p>
 * Copyright 2004
 * Atsushi Ohori 
 * JAIST, Ishikawa Japan.
 * </p>
 * @author OHORI Atsushi
 * @author Liu Bochao
 * @author UENO Katsuhiro
 * @version $Id: TypeInferencer.sml,v 1.180 2006/02/09 10:24:32 ohori Exp $
 *)
structure TypeInferencer : TYPE_INFERENCER =
struct
local 
  structure E = TypeInferenceError
  structure TIC = TypeInferenceContext
  structure UE = UserError 
in
  fun infer (globalContext as {strEnv,...})  pttopdeclList = 
    let
      val _ = Types.initTid ()
      val _ = TypeInferenceUtils.dummyTyId := 0
      val _ = E.initializeTypeinfError()
      val currentContext = TIC.makeInitialCurrentContext globalContext
      val (newContext, tpdeclList) =
          TypeInferModule.typeinfPttopdeclList currentContext pttopdeclList
    in
      if E.isError()
      then
        raise UE.UserErrors (E.getErrorsAndWarnings ())
      else 
        (newContext, tpdeclList, E.getWarnings())
    end

end
end

