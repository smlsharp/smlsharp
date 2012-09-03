(**
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: UniqueIdAllocation.sml,v 1.21 2008/08/04 13:25:37 bochao Exp $
 *)
structure UniqueIDAllocation : UNIQUEIDALLOCATION  = 
struct
local

  structure T = Types
  structure P = Path
  structure VIC = VarIDContext
  structure UIAM = UniqueIdAllocationMod
  structure TFCU = TypedFlatCalcUtils
  structure UIAU = UniqueIdAllocationUtils

  open TypedCalc TypedFlatCalc 
in
  fun allocateID 
        topVarExternalVarIDBasis varNamePathEnv tptopdecs
    =
    let
      val tptopGroups = UIAM.tptopdecsToTpTopGroups tptopdecs
      val (deltaCurrentVarIDBasis, deltaIDMap, tfpdecs) = 
          UIAM.tptopGroupsToTfpdecs topVarExternalVarIDBasis tptopGroups
      val liftedBasis = 
          (* internal id to external id *)
            VIC.liftUpVarIDBasis deltaCurrentVarIDBasis deltaIDMap
      val topBasis = 
          (* reconstruct topBasis according to flattened namePathEnv *)
            VarIDContext.varIDBasisToTopVarIDBasis varNamePathEnv liftedBasis
      val externalIDAnnotatedTfpdecs = 
          map (UIAU.annotateExternalIdTfpdec UIAU.externalizeVarIdInfo deltaIDMap)
              tfpdecs
      val externalIDAnnotatedTfpGroups =
          UIAU.tfpdecsToTfpTopBlock externalIDAnnotatedTfpdecs
      in
      (
       topBasis,
       externalIDAnnotatedTfpGroups
      )
    end
      handle exn => raise exn
end
end
