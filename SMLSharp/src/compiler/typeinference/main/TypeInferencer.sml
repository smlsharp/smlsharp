(**
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @author UENO Katsuhiro
 * @version $Id: TypeInferencer.sml,v 1.208 2008/08/04 13:25:37 bochao Exp $
 *)
structure TypeInferencer : TYPE_INFERENCER =
struct
local 
  structure E = TypeInferenceError
  structure TIC = TypeInferenceContext
  structure UE = UserError 
  structure TC = TypeContext
  structure TIU = TypeInferenceUtils
  structure PT = PatternCalcWithTvars
  structure NM = NameMap
  structure SU = SigUtils
in

fun infer 
  globalTypeContext 
  flattenedNamePathEnv 
  pttopdeclList 
  = 
  let
    val _ = TypeInferenceUtils.dummyTyId := 0
    val _ = E.initializeTypeinfError ()
    val basis = TIC.makeInitialBasis globalTypeContext
    val (context : TC.context, tpdecs) =
      TypeInferModule.typeinfPttopdeclList basis pttopdeclList
    val (exportInterfaceEnv, newTpDecs) = 
      let
        val implEnv =
          (* a mapping from namePath without injected unique structure names to types *)
          (TIU.constructEnvFromNameMap ((#tyConEnv context, #varEnv context), flattenedNamePathEnv),
           #funEnv context)
      in
        (implEnv, tpdecs)
      end
    val newContext =
      {
       tyConEnv = #1 (#1 exportInterfaceEnv), 
       varEnv = #2 (#1 exportInterfaceEnv), 
       sigEnv = #sigEnv context, 
       funEnv = #2 exportInterfaceEnv
       }
  in
    if E.isError()
      then
        raise UE.UserErrors (E.getErrorsAndWarnings ())
    else 
      (
       newContext, 
       newTpDecs , 
       E.getWarnings()
       )
  end
  handle exn => raise exn
end
end

