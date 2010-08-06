(**
 *
 * Module compiler expands functor application.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: FunctorLinker.sml,v 1.23 2008/08/06 17:23:39 ohori Exp $
 *)
structure FunctorLinker : FUNCTOR_LINKER = 
struct
local

  structure T  = Types
  structure P = Path
  structure ATU = AnnotatedTypesUtils
  structure AT = AnnotatedTypes
  structure VIC = VarIDContext
  open MultipleValueCalc

  val debug = false
  fun printx x = if debug then (print "\n"; print x; print "\n") else ()
  val newLocalId = VarID.generate

in
  type functorEnv = (MultipleValueCalc.mvdecl list) SEnv.map 
  val initialFunctorEnv = SEnv.empty
  val pu_functorEnv =
      EnvPickler.SEnv (Pickle.list MultipleValueCalcPickler.mvdecl)

  type linkContext =
       {
        typeResolutionTable : AnnotatedTypes.tyBindInfo TyConID.Map.map,
        exnTagResolutionTable : ExnTagID.id ExnTagID.Map.map,
        externalVarIDResolutionTable : ExVarID.id ExVarID.Map.map,
        refreshedExceptionTagTable : ExnTagID.id ExnTagID.Map.map,
        refreshedExternalVarIDTable : ExVarID.id ExVarID.Map.map,
        templateRenamingVarBasis : VIC.templateVarRenamingBasis
       }

  fun extendLinkContextWithTemplateRenamingVarBasis (lc:linkContext, trvb) =
      {
       typeResolutionTable = #typeResolutionTable lc,
       exnTagResolutionTable = #exnTagResolutionTable lc,
       externalVarIDResolutionTable = #externalVarIDResolutionTable lc,
       refreshedExceptionTagTable = #refreshedExceptionTagTable lc,
       refreshedExternalVarIDTable = #refreshedExternalVarIDTable lc,
       templateRenamingVarBasis = 
       VIC.mergeTemplateVarRenamingBasis
         {old = #templateRenamingVarBasis lc,
          new = trvb}
       }

  fun betaReduceAnnotatedTy ({tyargs, body}, tyl) =
      let
        val argsBtyList = IEnv.listItemsi tyargs
      in
        if List.length argsBtyList <> List.length tyl then
          raise Control.Bug "betaReduceAnnotatedTy arity mismatch"
        else
          let
            val subst = 
                ListPair.foldr
                  (fn ((i, _), ty, S) => IEnv.insert(S, i, ty))
                  IEnv.empty
                  (argsBtyList, tyl)
          in 
            ATU.substitute subst body
          end
      end

  fun linkTemplateTy (linkContext:linkContext) ty = 
      case ty of
        AT.INSTCODEty {oprimId, oprimPolyTy, name, keyTyList, instTyList} => 
        AT.INSTCODEty
          {oprimId = oprimId,
           oprimPolyTy = oprimPolyTy,
           name = name,
           keyTyList = map (linkTemplateTy linkContext) instTyList,
           instTyList = map (linkTemplateTy linkContext) instTyList
          }
        | AT.ERRORty => ty
        | AT.DUMMYty _ => ty
        | AT.BOUNDVARty _ => ty

        | AT.FUNMty {argTyList, bodyTy, funStatus, annotation} =>
          AT.FUNMty {argTyList = map (linkTemplateTy linkContext) argTyList, 
                     bodyTy = linkTemplateTy linkContext bodyTy, 
                     annotation = annotation,
                     funStatus = funStatus}
        | AT.MVALty tyList =>
          AT.MVALty (map (linkTemplateTy linkContext) tyList)
        | AT.RECORDty {fieldTypes, annotation} =>
          AT.RECORDty
            {fieldTypes = SEnv.map (linkTemplateTy linkContext) fieldTypes,
             annotation = annotation}
        | AT.POLYty {boundtvars, body} =>
          AT.POLYty
            {boundtvars =
               IEnv.map (linkTemplateBtvKind linkContext) boundtvars, 
             body = linkTemplateTy linkContext body}
        | AT.RAWty {tyCon, args} =>
          AT.RAWty {tyCon = tyCon,
                    args = map (linkTemplateTy linkContext) args
                   }
        | AT.SPECty {tyCon = {id, ...}, args} => 
          let
            val newArgs = map (linkTemplateTy linkContext) args
            val resultTy =
                case TyConID.Map.find (#typeResolutionTable linkContext, id) of
                  NONE => ty
                | SOME (AT.TYCON tyCon) =>
                  AT.RAWty {tyCon = tyCon, args = newArgs}
                | SOME (AT.TYSPEC tyCon) =>
                  AT.SPECty {tyCon = tyCon, args = newArgs}
                | SOME (AT.TYFUN tyFun) =>
                  betaReduceAnnotatedTy (tyFun, newArgs)
          in
            resultTy
          end

  and linkTemplateBtvKind linkContext {id, recordKind, eqKind, instancesRef} =
      let
        val recordKind =
            case recordKind of 
              AT.UNIV => AT.UNIV
            | AT.REC tySEnvMap => 
              AT.REC (SEnv.map (linkTemplateTy linkContext) tySEnvMap)
            | AT.OPRIMkind {instances, operators} =>
              AT.OPRIMkind 
                {instances = map (linkTemplateTy linkContext) instances,
                 operators =
                 map
                   (fn {oprimId, oprimPolyTy, name, keyTyList, instTyList} =>
                       {oprimId = oprimId,
                        oprimPolyTy = oprimPolyTy,
                        name = name,
                        keyTyList =
                        map (linkTemplateTy linkContext) keyTyList,
                        instTyList =
                        map (linkTemplateTy linkContext) instTyList}
                   )
                   operators
                }
        val _ =
            instancesRef := map (linkTemplateTy linkContext) (!instancesRef)
      in
          {
           id = id,
           recordKind = recordKind,
           eqKind = eqKind,
           instancesRef = instancesRef
          } : AT.btvKind
      end

  fun linkTemplateIndex (linkContext:linkContext) index =
      case ExVarID.Map.find(#externalVarIDResolutionTable linkContext,
                                  index) of
          SOME newIndex => newIndex
        | NONE => 
          case ExVarID.Map.find
                 (#refreshedExternalVarIDTable linkContext, index) of
              SOME newIndex => newIndex
            | NONE => index

  fun linkTemplateExceptionTag (linkContext:linkContext) tag loc =
      case ExnTagID.Map.find(#exnTagResolutionTable linkContext, tag) of
          SOME newTag => newTag
        | NONE =>
          case ExnTagID.Map.find(
               #refreshedExceptionTagTable linkContext, tag) of
            SOME newTag => newTag
          | NONE => tag

  fun linkTemplate linkContext templateCode =
      let
        val (templateVarRenamingBasis1, newTemplateCode) =
            linkTemplateDecs linkContext templateCode
      in
        newTemplateCode
      end
          
  and linkTemplateDecs linkContext templateCode =
      let
        val (incTemplateVarRenamingBasis, _, mvdecs) =
            foldl
              (fn
               (mvdec,
                (incTemplateRenamingVarBasis, newLinkContext, mvdecs)
               ) =>
               let
                 val (templateRenamingVarBasis1, mvdec1) = 
                     linkTemplateDec newLinkContext mvdec
               in
                 (
                  VIC.mergeTemplateVarRenamingBasis
                    {old = incTemplateRenamingVarBasis, 
                     new = templateRenamingVarBasis1},
                  extendLinkContextWithTemplateRenamingVarBasis
                    (newLinkContext, templateRenamingVarBasis1),
                  mvdecs @ [mvdec1])
               end)
              (VIC.emptyTemplateRenamingVarBasis, linkContext, nil)
              templateCode
      in
          (incTemplateVarRenamingBasis, mvdecs)
      end
 
  and linkTemplateDec linkContext mvdec = 
      case mvdec of
        MVVAL {boundVars, boundExp, loc} => 
        let
          val (newBoundVars, newTemplateVarRenamingBasis) = 
              foldl
                (fn ({displayName, ty, varId = T.INTERNAL id}, 
                     (newBVs, newTVB)) =>
                    let
                      val newId = newLocalId()
                      val newTy = linkTemplateTy linkContext ty
                    in
                      (newBVs @
                       [{
                         displayName = displayName,
                         ty = newTy,
                         varId = T.INTERNAL newId
                       }],
                       VIC.mergeTemplateVarRenamingBasis
                         {new = VarID.Map.singleton(id, (displayName, newId)),
                          old = newTVB})
                    end
                  | ({displayName, ty, varId = T.EXTERNAL index}, 
                     (newBVs, newTVB)) =>
                    let
                      val newTy = linkTemplateTy linkContext ty
                      val newIndex = linkTemplateIndex linkContext index
                    in
                    (* since id plays no roles for external variables except
                     * that it is different from those of internal variables
                     *)
                      (newBVs @
                       [{
                         displayName = displayName,
                         ty = newTy,
                         varId = T.EXTERNAL newIndex
                       }],
                       newTVB)
                    end)
                (nil, VIC.emptyTemplateRenamingVarBasis)
                boundVars
          val newLinkContext = 
              extendLinkContextWithTemplateRenamingVarBasis
                (linkContext, newTemplateVarRenamingBasis)
          val newMvexp = linkTemplateMvexp newLinkContext boundExp
        in
          (newTemplateVarRenamingBasis,
           MVVAL {boundVars = newBoundVars, boundExp = newMvexp, loc = loc})
        end
      | MVVALREC {recbindList, loc} =>
        let
          val incTemplateVarRenamingBasis = 
              foldr
                (fn ({boundVar = {displayName,
                                  ty,
                                  varId = T.INTERNAL oldId},
                      boundExp}, 
                     templateVarRenamingBasis) => 
                    let
                      val newId = newLocalId()
                    in
                      VIC.mergeTemplateVarRenamingBasis
                        {new = VarID.Map.singleton
                                 (oldId, (displayName, newId)),
                         old = templateVarRenamingBasis}
                    end
                  | ({boundVar = {displayName, ty, varId = T.EXTERNAL index},
                      boundExp}, 
                     templateVarRenamingBasis) =>
                    templateVarRenamingBasis
                )
                VIC.emptyTemplateRenamingVarBasis
                recbindList
          val newLinkContext = 
              extendLinkContextWithTemplateRenamingVarBasis
                (linkContext, incTemplateVarRenamingBasis)
          val newRecbindList =
              foldr
                (fn
                 ({boundVar={displayName, ty = oldTy, varId = T.INTERNAL id},
                   boundExp},
                  newRecbindList) =>
                 let
                   val newId = 
                       case VIC.lookupLocalIdInTemplateVarRenamingBasis
                              (id, incTemplateVarRenamingBasis) 
                        of
                         SOME (displayName, newId) => newId
                       | NONE => raise Control.Bug ("unbound var:"^displayName)
                   val newTy = linkTemplateTy linkContext oldTy
                   val newBoundVar = {displayName = displayName,
                                      ty = newTy,
                                      varId = T.INTERNAL newId}
                   val newMvexp = linkTemplateMvexp newLinkContext boundExp
                 in
                   {boundVar = newBoundVar,
                    boundExp = newMvexp} :: newRecbindList
                 end
               | ({boundVar =
                    {displayName, ty = oldTy, varId = T.EXTERNAL index},
                   boundExp},
                  newRecbindList) =>
                 let
                   val newIndex = linkTemplateIndex linkContext index
                   val newTy = linkTemplateTy newLinkContext oldTy
                   val newBoundVar =
                       {
                        displayName = displayName,
                        ty = newTy,
                        varId = T.EXTERNAL newIndex
                       }
                   val newMvexp = linkTemplateMvexp newLinkContext boundExp
                 in
                   {boundVar = newBoundVar,
                    boundExp = newMvexp} :: newRecbindList
                 end)
                nil
                recbindList
        in
          (incTemplateVarRenamingBasis,
           MVVALREC {recbindList = newRecbindList, loc = loc})
        end
      | MVVALPOLYREC {btvEnv, recbindList, loc} =>
        let
          val incTemplateVarRenamingBasis = 
              foldr
                (fn ({boundVar =
                      {displayName, ty, varId = T.INTERNAL oldId},
                      boundExp}, 
                     templateVarRenamingBasis) => 
                    let
                      val newId = newLocalId()
                    in
                      (
                       VIC.mergeTemplateVarRenamingBasis
                         {new = VarID.Map.singleton
                                  (oldId, (displayName, newId)),
                          old = templateVarRenamingBasis})
                    end
                  | ({boundVar = {displayName, ty, varId = T.EXTERNAL index},
                      boundExp}, 
                     templateVarRenamingBasis) =>
                    templateVarRenamingBasis)
                VIC.emptyTemplateRenamingVarBasis
                recbindList
          val newLinkContext = 
              extendLinkContextWithTemplateRenamingVarBasis
                (linkContext, incTemplateVarRenamingBasis)
          val newRecbindList =
              foldr
                (fn ({boundVar =
                      {displayName, ty = oldTy, varId = T.INTERNAL id},
                      boundExp},
                     newRecbindList) =>
                    let
                      val newId = 
                          case VIC.lookupLocalIdInTemplateVarRenamingBasis
                                 (id, incTemplateVarRenamingBasis) of
                            SOME (displayName, newId) => newId
                          | NONE =>
                            raise Control.Bug ("unbound var:"^displayName)
                      val newTy = linkTemplateTy newLinkContext oldTy
                      val newBoundVar =
                          {
                           displayName = displayName,
                           ty = newTy,
                           varId = T.INTERNAL newId
                          }
                      val newMvexp = linkTemplateMvexp newLinkContext boundExp
                    in
                      {boundVar = newBoundVar, boundExp = newMvexp}
                        :: newRecbindList
                    end
                  | ({boundVar =
                      {displayName, ty = oldTy, varId = T.EXTERNAL index},
                      boundExp},
                     newRecbindList) =>
                    let
                      val newIndex = linkTemplateIndex linkContext index
                      val newTy = linkTemplateTy newLinkContext oldTy
                      val newBoundVar =
                          {
                           displayName = displayName,
                           ty = newTy,
                           varId = T.EXTERNAL newIndex
                          }
                      val newMvexp = 
                          linkTemplateMvexp newLinkContext boundExp
                    in
                      {boundVar = newBoundVar, boundExp = newMvexp}
                      :: newRecbindList
                    end)
                nil
                recbindList
        in
          (
           incTemplateVarRenamingBasis,
           MVVALPOLYREC
             {btvEnv = btvEnv, recbindList = newRecbindList, loc = loc})
        end

  and linkTemplateMvexpList linkContext mvexpList =
      map (linkTemplateMvexp linkContext) mvexpList
      
  and linkTemplateMvexp linkContext mvexpression =
      case mvexpression of
        MVFOREIGNAPPLY {funExp=foreignFunInfo, 
                        funTy, 
                        argExpList=mvexpList, 
                        attributes, 
                        loc} => 
        MVFOREIGNAPPLY
          {funExp = linkTemplateMvexp linkContext foreignFunInfo,
           funTy = linkTemplateTy linkContext funTy,
           argExpList = linkTemplateMvexpList linkContext mvexpList,
           attributes = attributes,
           loc = loc}
      | MVEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        MVEXPORTCALLBACK {funExp = linkTemplateMvexp linkContext funExp,
                          funTy = linkTemplateTy linkContext funTy,
                          attributes = attributes,
                          loc = loc}
      | MVSIZEOF _ => mvexpression
      | MVCONSTANT _ => mvexpression
      | MVGLOBALSYMBOL _ => mvexpression
      | MVEXCEPTIONTAG {tagValue, displayName, loc} =>
        MVEXCEPTIONTAG
          {tagValue = linkTemplateExceptionTag linkContext tagValue loc,
           displayName = displayName,
           loc = loc}
      | MVVAR ({varInfo ={displayName,
                          ty,
                          varId = varId as (T.EXTERNAL index)},
                loc}) => 
        MVVAR ({varInfo =
                {displayName = displayName,
                 ty = linkTemplateTy linkContext ty, 
                 varId = T.EXTERNAL (linkTemplateIndex linkContext index)},
                loc = loc})
      | MVVAR {varInfo = {displayName,ty,varId = T.INTERNAL id}, loc} => 
        (case VIC.lookupLocalIdInTemplateVarRenamingBasis
                (id, #templateRenamingVarBasis linkContext) 
          of  
           (* variable inside body *)
           SOME (_, id) => 
             MVVAR
               ({varInfo = {displayName = displayName,
                            ty = linkTemplateTy linkContext ty,
                            varId = T.INTERNAL id},
                 loc = loc})
         | NONE => 
           raise Control.BugWithLoc
                   ("nonrefreshed variable:" ^ displayName^"(" ^
                    VarID.toString(id)^")",
                    loc))
      | MVGETFIELD ({arrayExp, indexExp, elementTy, loc}) => 
        MVGETFIELD ({arrayExp = linkTemplateMvexp linkContext arrayExp,
                     indexExp = linkTemplateMvexp linkContext indexExp,
                     elementTy = linkTemplateTy linkContext elementTy, 
                     loc = loc})
      | MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        MVSETFIELD {valueExp = linkTemplateMvexp linkContext valueExp,
                    arrayExp = linkTemplateMvexp linkContext arrayExp,
                    indexExp = linkTemplateMvexp linkContext indexExp,
                    elementTy = linkTemplateTy linkContext elementTy, 
                    loc = loc}
      | MVSETTAIL {consExp, newTailExp, tailLabel, listTy, consRecordTy, loc}
        =>
        MVSETTAIL {consExp = linkTemplateMvexp linkContext consExp,
                   newTailExp = linkTemplateMvexp linkContext newTailExp,
                   tailLabel = tailLabel,
                   listTy = linkTemplateTy linkContext listTy,
                   consRecordTy = linkTemplateTy linkContext consRecordTy, 
                   loc = loc}
      | MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} => 
        MVARRAY {sizeExp = linkTemplateMvexp linkContext sizeExp,
                 initialValue = linkTemplateMvexp linkContext initialValue,
                 elementTy = linkTemplateTy linkContext elementTy,
                 isMutable = isMutable,
                 loc = loc}
      | MVCOPYARRAY {srcExp,
                     srcIndexExp,
                     dstExp,
                     dstIndexExp,
                     lengthExp,
                     elementTy,
                     loc} =>
        MVCOPYARRAY
          {srcExp = linkTemplateMvexp linkContext srcExp,
           srcIndexExp = linkTemplateMvexp linkContext srcIndexExp,
           dstExp = linkTemplateMvexp linkContext dstExp,
           dstIndexExp = linkTemplateMvexp linkContext dstIndexExp,
           lengthExp = linkTemplateMvexp linkContext lengthExp,
           elementTy =  linkTemplateTy linkContext elementTy, 
           loc = loc}
      | MVPRIMAPPLY {primInfo = {name, ty}, argExpList, instTyList, loc} =>
        MVPRIMAPPLY{primInfo =
                     {name = name, ty = linkTemplateTy linkContext ty},
                    argExpList = linkTemplateMvexpList  linkContext argExpList,
                    instTyList = map (linkTemplateTy linkContext) instTyList,
                    loc = loc}
      | MVAPPM{funExp, funTy, argExpList, loc} =>
        MVAPPM {funExp = linkTemplateMvexp linkContext funExp,
                funTy = linkTemplateTy linkContext funTy,
                argExpList = linkTemplateMvexpList linkContext argExpList,
                loc=loc}
      | MVLET {localDeclList, mainExp, loc} =>
        let
          val (incTemplateValueRenamingBasis, newLocalDecs) =
              linkTemplateDecs linkContext localDeclList
          val newLinkContext = 
              extendLinkContextWithTemplateRenamingVarBasis
                (linkContext, incTemplateValueRenamingBasis)
        in
          MVLET {localDeclList = newLocalDecs,
                 mainExp = linkTemplateMvexp newLinkContext mainExp,
                 loc = loc}
        end
      | MVMVALUES {expList, tyList, loc} =>
        MVMVALUES {expList = linkTemplateMvexpList linkContext expList,
                   tyList = map (linkTemplateTy linkContext) tyList, 
                   loc = loc}
      | MVRECORD {expList, recordTy, annotation, isMutable, loc} =>
        MVRECORD {expList = linkTemplateMvexpList linkContext expList,
                  recordTy = linkTemplateTy linkContext recordTy, 
                  annotation = annotation, 
                  isMutable = isMutable, 
                  loc = loc}
      | MVSELECT {recordExp, label, recordTy, resultTy, loc} =>
        MVSELECT {recordExp = linkTemplateMvexp linkContext recordExp,
                  label = label, 
                  recordTy = linkTemplateTy linkContext recordTy, 
                  resultTy = linkTemplateTy linkContext resultTy, 
                  loc = loc}
      | MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        MVMODIFY {recordExp = linkTemplateMvexp linkContext recordExp,
                  recordTy = linkTemplateTy linkContext recordTy, 
                  label = label, 
                  valueExp =  linkTemplateMvexp linkContext valueExp,
                  valueTy = linkTemplateTy linkContext valueTy, 
                  loc = loc}
      | MVRAISE {argExp, resultTy, loc} =>
        MVRAISE {argExp = linkTemplateMvexp linkContext argExp,
                 resultTy = linkTemplateTy linkContext resultTy, 
                 loc = loc}
      | MVHANDLE {exp,
                  exnVar=varInfo as {displayName, ty, varId}, 
                  handler,
                  loc=loc} =>
        let
          val id = case varId of 
                     T.INTERNAL id => id
                   | T.EXTERNAL _ =>
                     raise
                       Control.BugWithLoc
                         ("expect local variable in handler",loc)
          val newId =  newLocalId()
          val newVar  = 
              { 
               displayName = displayName,
               ty = linkTemplateTy linkContext ty,
               varId = T.INTERNAL newId
              }
          val newTemplateVarRenamingBasis =
              VarID.Map.singleton(id, (displayName, newId))
          val newLinkContext = 
              extendLinkContextWithTemplateRenamingVarBasis
                (linkContext, newTemplateVarRenamingBasis)
        in
          MVHANDLE {exp = linkTemplateMvexp linkContext exp,
                    exnVar = newVar,
                    handler = linkTemplateMvexp newLinkContext handler,
                    loc=loc}
        end
      | MVFNM {argVarList, funTy, bodyExp, annotation, loc} =>
        let
          val idAndNewArglist = 
              map (fn {displayName, ty, varId = T.INTERNAL id} =>
                      (id,
                       { 
                        displayName = displayName,
                        ty = linkTemplateTy linkContext ty,
                        varId = T.INTERNAL (newLocalId())
                      })
                    | {displayName, ty, varId = T.EXTERNAL _} =>
                      raise
                        Control.BugWithLoc
                          ("expect local variable in function argument",loc)
                  )
                  argVarList
          val newTemplateVarRenamingBasis = 
              foldl 
                (fn ((id, {displayName, ty, varId = T.INTERNAL newId}),
                     templateVarRenamingBasis) =>
                    VIC.mergeTemplateVarRenamingBasis
                      {old = templateVarRenamingBasis,
                       new = VarID.Map.singleton(id, (displayName, newId))}
                  | ((_, {displayName, ty, varId = T.EXTERNAL _}), _) =>
                    raise
                      Control.BugWithLoc
                        ("expect local variable in function argument",loc)
                )
                VIC.emptyTemplateRenamingVarBasis
                idAndNewArglist
          val newLinkContext = 
              extendLinkContextWithTemplateRenamingVarBasis
                (linkContext, newTemplateVarRenamingBasis)
        in
          MVFNM {argVarList = map #2 idAndNewArglist,
                 funTy = linkTemplateTy linkContext funTy,
                 bodyExp = linkTemplateMvexp newLinkContext bodyExp,
                 annotation = annotation,
                 loc = loc}
        end
      | MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        MVPOLY {btvEnv = IEnv.map (linkTemplateBtvKind linkContext) btvEnv,
                expTyWithoutTAbs = linkTemplateTy linkContext expTyWithoutTAbs,
                exp = linkTemplateMvexp linkContext exp,
                loc = loc}
      | MVTAPP {exp, expTy, instTyList, loc=loc} =>
        MVTAPP {exp = linkTemplateMvexp linkContext exp,
                expTy = linkTemplateTy linkContext expTy, 
                instTyList = map (linkTemplateTy linkContext) instTyList,
                loc=loc}
      | MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        MVSWITCH {switchExp = linkTemplateMvexp linkContext switchExp,
                  expTy = linkTemplateTy linkContext expTy, 
                  branches =
                    map
                      (fn {constant,exp} =>
                          {constant = linkTemplateMvexp linkContext constant,
                           exp =linkTemplateMvexp linkContext exp}) branches,
                  defaultExp = linkTemplateMvexp linkContext defaultExp,
                  loc = loc}
      | MVCAST {exp, expTy, targetTy, loc} => 
        MVCAST {exp = linkTemplateMvexp linkContext exp,
                expTy = linkTemplateTy linkContext expTy,
                targetTy = linkTemplateTy linkContext targetTy,
                loc = loc}

  fun linkDec functorEnv dec =
      case dec of
          MVVAL _ => dec
        | MVVALREC _ => dec
        | MVVALPOLYREC _ => dec

  fun linkBasicBlock functorEnv basicBlock =
      case basicBlock of
          MVVALBLOCK {code, exnIDSet} =>
          map (linkDec functorEnv) code
        | MVLINKFUNCTORBLOCK {name, 
                              actualArgName, 
                              typeResolutionTable, 
                              exnTagResolutionTable, 
                              externalVarIDResolutionTable, 
                              refreshedExceptionTagTable, 
                              refreshedExternalVarIDTable, 
                              loc} => 
          let
            val templateCode = 
                case SEnv.find(functorEnv, name) of
                  NONE =>
                  raise Control.BugWithLoc ("unbound functor "^name, loc)
                | SOME code => code
            val linkContext = 
                {
                 typeResolutionTable = typeResolutionTable, 
                 exnTagResolutionTable = exnTagResolutionTable,
                 externalVarIDResolutionTable = externalVarIDResolutionTable,
                 refreshedExceptionTagTable = refreshedExceptionTagTable,
                 refreshedExternalVarIDTable = refreshedExternalVarIDTable,
                 templateRenamingVarBasis =  VIC.emptyTemplateRenamingVarBasis
                }
            val linkedCode = linkTemplate linkContext templateCode
          in
            linkedCode
          end

  fun linkTopBlock functorEnv topBlock =
      case topBlock of
          MVBASICBLOCK basicBlock => 
          (SEnv.empty, linkBasicBlock functorEnv basicBlock)
        | MVFUNCTORBLOCK {name, bodyCode, ...} => 
          let
            val linkedBodyCode = 
                foldl (fn (basicBlock , newCode) =>
                          (newCode @ (linkBasicBlock functorEnv basicBlock)))
                      nil
                      bodyCode
          in
            (SEnv.singleton (name, linkedBodyCode), nil)
          end


  fun link functorEnv topBlocks =
      let
        val (_, incFunctorEnv, newTopBlocks) =
            foldl
              (fn (topBlock, (newFunctorEnv, incFunctorEnv, newTopBlocks)) =>
                  let
                    val (functorEnv1: mvdecl list SEnv.map, newDecs) =
                        linkTopBlock newFunctorEnv topBlock
                  in
                    (SEnv.unionWith #1 (functorEnv1, newFunctorEnv),
                     SEnv.unionWith #1 (functorEnv1, incFunctorEnv),
                     newTopBlocks @ newDecs)
                  end)
              (functorEnv, SEnv.empty, nil)
              topBlocks
      in (incFunctorEnv, newTopBlocks) end
      handle exn => raise exn
end
end
