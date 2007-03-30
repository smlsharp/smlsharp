(**
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atsushi
 * @author Liu Bochao
 * @author UENO Katsuhiro
 * @version $Id: TypeInferencer.sml,v 1.185 2007/02/07 05:59:37 bochao Exp $
 *)
structure TypeInferencer : TYPE_INFERENCER =
struct
local 
  structure E = TypeInferenceError
  structure TIC = TypeInferenceContext
  structure UE = UserError 
  structure STE = StaticTypeEnv
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
          val currentContext = 
              TIC.makeInitialCurrentContext InitialTypeContext.initialTopTypeContext
          val (typeEnv, tpdeclList) =
              TypeInferModule.typeinfPttopdeclListLinkageUnit
                  currentContext pttopdeclList
      in
          if E.isError()
          then
              raise UE.UserErrors (E.getErrorsAndWarnings ())
          else 
              (typeEnv, tpdeclList, E.getWarnings())
      end

  fun inferInterface importTypeEnv exportTopDecs = 
      let
          val _ = Types.initTid ()
          val _ = TypeInferenceUtils.dummyTyId := 0
          val _ = E.initializeTypeinfError()

          val currentContext = 
              TIC.extendCurrentContextWithTypeEnv
                  (TIC.makeInitialCurrentContext InitialTypeContext.initialTopTypeContext,
                   importTypeEnv)
          val exportSig =
              TypeInferModule.typeinfPttopdeclInterface currentContext exportTopDecs
      in
          if E.isError()
          then
              raise UE.UserErrors (E.getErrorsAndWarnings ())
          else 
              (exportSig, E.getWarnings())
      end

  fun exportSigCheck
          (exportTypeEnv, (exportSigTyConIdSetSig, exportSigTypeEnv), loc)
    =
    let
        val exportEnv = STE.typeEnvToEnv exportTypeEnv
        val exportSigEnv = STE.typeEnvToEnv exportSigTypeEnv
        val newExportSigEnv =
            SigCheck.transparentSigMatch (exportEnv, (exportSigTyConIdSetSig, exportSigEnv))
            handle exn => (SigUtils.handleException (exn, loc); Types.emptyE)
    in
        if E.isError()
        then
            raise UE.UserErrors (E.getErrorsAndWarnings ())
        else 
            (STE.EnvToTypeEnv newExportSigEnv, E.getWarnings())
    end
end
end

