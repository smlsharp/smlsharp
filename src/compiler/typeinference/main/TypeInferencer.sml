(**
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atsushi
 * @author Liu Bochao
 * @author UENO Katsuhiro
 * @version $Id: TypeInferencer.sml,v 1.182 2006/03/02 12:53:26 bochao Exp $
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

  fun inferLinkageUnit pttopdeclList = 
    let
      val _ = Types.initTid ()
      val _ = TypeInferenceUtils.dummyTyId := 0
      val _ = E.initializeTypeinfError()
      val currentContext = TIC.makeInitialCurrentContext InitialTypeContext.initialTopTypeContext
      val (typeEnv, tpdeclList) =
          TypeInferModule.typeinfPttopdeclList' currentContext pttopdeclList
    in
      if E.isError()
      then
        raise UE.UserErrors (E.getErrorsAndWarnings ())
      else 
        (typeEnv, tpdeclList, E.getWarnings())
    end
end
end

