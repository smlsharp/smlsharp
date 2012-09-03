(**
 * Module compiler utilities.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: UniqueIdAllocationUtils.sml,v 1.18 2008/08/06 17:23:41 ohori Exp $
 *)
structure UniqueIdAllocationUtils =
struct
local
  structure T  = Types
  structure P = Path
  structure VIC = VarIDContext
  structure NM = NameMap
  structure NPEnv = NM.NPEnv
  open TypedCalc TypedFlatCalc
in

  fun reconstructVarIDEnvFromNameMapWithoutActualStrName 
          (tyNamePathEnv, varNamePathEnv)
          (context : UniqueIdAllocationContext.context) 
          loc 
    =
    NPEnv.foldli
        (fn (srcNamePath, idstate, newVarIDEnv) => 
            case idstate of
                NameMap.VARID actualVarNamePath =>
                let
                    val newItem =
                        case VIC.lookupVar(#topVarExternalVarIDBasis context,
                                           #varIDBasis context,
                                           actualVarNamePath) of
                            SOME x => x
                          | NONE => 
                            raise Control.BugWithLoc 
                                      ("unbound variable "^
                                       (NM.namePathToString (actualVarNamePath)),
                                       loc)
                in
                    NPEnv.insert(
                                 newVarIDEnv, 
                                 srcNamePath,
                                 newItem
                                 )
                end
              | NameMap.CONID _ => newVarIDEnv
              | NameMap.EXNID _ => newVarIDEnv)
        NPEnv.empty
        varNamePathEnv 
                  
  fun constructFormatterVarIDEnv (instFormatterNameMap, context : UniqueIdAllocationContext.context, loc) =
      SEnv.foldli 
          (fn (formalFormatterLongName, actualFormatterLongName, newVarIDEnv) =>
              case VIC.lookupVar(#topVarExternalVarIDBasis context,
                                 #varIDBasis context,
                                (actualFormatterLongName, P.NilPath)) of
                  NONE => raise Control.BugWithLoc
                                    ("unbound "^ actualFormatterLongName, loc)
                | SOME  item => SEnv.insert(newVarIDEnv, formalFormatterLongName, item))
          SEnv.empty
          instFormatterNameMap
          
  fun adjustPrefixVarEnv (varEnv, prefix) =
      SEnv.foldli (fn (name, item, newVarEnv) =>
                      SEnv.insert(newVarEnv, 
                                  Absyn.longidToString([prefix, name]),
                                  item))
                  SEnv.empty
                  varEnv

  fun constructVarIDEnvFromNamePathEnv (varIDEnv, varNamePathEnv) loc =
      NPEnv.foldli (fn (srcNamePath, idstate, newVarIDEnv) =>
                       case idstate of 
                           NM.VARID _ =>
                           let
                               val namePath = NM.getNamePathFromIdstate idstate
                               val name = NM.namePathToString namePath
                           in
                               case SEnv.find(varIDEnv, name) of
                                   NONE => raise Control.BugWithLoc 
                                                     (("unbound variable :" ^ name), loc)
                                 | SOME item => 
                                   SEnv.insert(newVarIDEnv,
                                               NM.namePathToString srcNamePath,
                                               item)
                           end
                         | NM.EXNID _ => newVarIDEnv
                         | NM.CONID _ => newVarIDEnv)
                   SEnv.empty
                   varNamePathEnv

  fun filterPathVE (varIDEnv, basicNameNPEnv:NM.basicNameNPEnv) =
      let
          val varNamePathSet = 
              NM.NPEnv.foldl (fn (NM.VARID namePath, varNamePathSet) =>
                                 NM.NPSet.add(varNamePathSet, namePath)
                               | (_, varNamePathSet) => varNamePathSet)
                             NM.NPSet.empty
                             (#2 basicNameNPEnv)
          val newVarIDEnv =
              NM.NPEnv.foldli (fn (namePath, pathVarItem, newVarIDEnv) =>
                                  if NM.NPSet.member(varNamePathSet, namePath) 
                                  then NM.NPEnv.insert(newVarIDEnv, namePath, pathVarItem)
                                  else newVarIDEnv)
                              NM.NPEnv.empty
                              varIDEnv
      in
          newVarIDEnv
      end

  (********************************************************************************)
  fun externalizeVarIdInfo IDMap {displayName, ty, varId} =
      let
          val newId = 
              case varId of
                  Types.INTERNAL id =>
                  (case VarID.Map.find(IDMap, id) of
                       SOME (_, index) => T.EXTERNAL index
                     | NONE => Types.INTERNAL id)
                | Types.EXTERNAL _ => varId
      in
          {displayName = displayName,
           ty = ty,
           varId = newId}
      end

  type vidFun = (string * ExVarID.id) VarID.Map.map -> varIdInfo -> varIdInfo

  fun annotateExternalIdValIdent (annotateFunctionVarIdInfo:vidFun) IDMap valIdent =
      case valIdent of
          T.VALIDENT varIdInfo => T.VALIDENT (annotateFunctionVarIdInfo IDMap varIdInfo)
        | T.VALIDENTWILD _ => valIdent

  fun annotateExternalIdTfpexp (annotateFunctionVarIdInfo:vidFun) IDIndexMap tfpexp = 
      case tfpexp of
          TFPFOREIGNAPPLY {funExp, funTy, instTyList, argExpList, argTyList, attributes, loc} =>
          TFPFOREIGNAPPLY
              {
               funExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap funExp,
               funTy = funTy,
               instTyList = instTyList, 
               argExpList = map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) argExpList,
               argTyList = argTyList,
               attributes=attributes,
               loc=loc
               }
        | TFPEXPORTCALLBACK {funExp, argTyList, resultTy, attributes, loc} =>
          TFPEXPORTCALLBACK
              {
               funExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap funExp,
               argTyList = argTyList,
               resultTy = resultTy,
               attributes = attributes,
               loc=loc
               }
       | TFPSIZEOF _ => tfpexp
       | TFPCONSTANT _ => tfpexp
       | TFPGLOBALSYMBOL _ => tfpexp
       | TFPVAR (varIdInfo, loc) => 
         TFPVAR (annotateFunctionVarIdInfo IDIndexMap varIdInfo, loc)
       | TFPGETFIELD _ => tfpexp
       | TFPARRAY {sizeExp, initExp, elementTy, resultTy, loc} =>
         TFPARRAY
             {
              sizeExp = annotateExternalIdTfpexp  annotateFunctionVarIdInfo IDIndexMap sizeExp,
              initExp = annotateExternalIdTfpexp  annotateFunctionVarIdInfo IDIndexMap initExp,
              elementTy = elementTy,
              resultTy = resultTy,
              loc = loc
              }
       | TFPPRIMAPPLY {primOp = prim, instTyList = tys, argExpOpt = tfpexpOpt, loc} =>
         TFPPRIMAPPLY
             {
              primOp=prim, 
              instTyList=tys, 
              argExpOpt = Option.map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) tfpexpOpt,
              loc=loc
              }
       | TFPOPRIMAPPLY
           {
            oprimOp=oprim,
            keyTyList =ktys,
            instances=tys,
            argExpOpt=tfpexpOpt, 
            loc
           } =>
         TFPOPRIMAPPLY
           {
            oprimOp = oprim,
            keyTyList = ktys,
            instances = tys,
            argExpOpt =
              Option.map
                (annotateExternalIdTfpexp
                   annotateFunctionVarIdInfo IDIndexMap)
                tfpexpOpt,
            loc=loc
           }
       | TFPDATACONSTRUCT {con, instTyList = tys, argExpOpt = tfpexpOpt, loc} => 
         TFPDATACONSTRUCT
             {
              con = con, 
              instTyList = tys, 
              argExpOpt = Option.map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) tfpexpOpt,
            loc=loc
            }
       | TFPEXNCONSTRUCT {exn, instTyList = tys, argExpOpt = tfpexpOpt, loc} => 
         TFPEXNCONSTRUCT
             {
              exn = exn, 
              instTyList = tys, 
              argExpOpt = Option.map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) tfpexpOpt,
            loc=loc
            }
       | TFPAPPM {funExp = operator, funTy = ty, argExpList = operandList, loc} =>
	 TFPAPPM
             {
              funExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap operator,
              funTy = ty,
              argExpList = map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) operandList,
              loc=loc
              }
       | TFPMONOLET {binds, bodyExp=exp, loc} => 
	 TFPMONOLET
             {
              binds = map (fn (v, e) =>(v, annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap e)) binds,
	      bodyExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp,
              loc=loc
              }
       | TFPLET (decs, exps, tyl, loc) => 
	 TFPLET
             (
              map (annotateExternalIdTfpdec annotateFunctionVarIdInfo IDIndexMap) decs,
              map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) exps,
              tyl,
              loc
              )
       | TFPRECORD {fields, recordTy=ty, loc} =>
         TFPRECORD
           {
            fields = SEnv.map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) fields, 
            recordTy = ty, 
            loc = loc
            }
       | TFPRAISE (exp, ty, loc) => 
         TFPRAISE (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp, ty, loc)
       | TFPHANDLE {exp=exp1, exnVar=v, handler=exp2, loc} => 
	 TFPHANDLE
             {exp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp1, 
              exnVar = v, 
              handler = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp2, 
              loc=loc}
       | TFPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
         TFPCASEM {expList = map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) expList, 
                   expTyList = expTyList, 
                   ruleList = 
                   map (fn (patList, exp) => (patList, annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp)) ruleList,
                   ruleBodyTy = ruleBodyTy, 
                   caseKind = caseKind, 
                   loc = loc} 
       | TFPFNM {argVarList = varIdInfoList, bodyTy, bodyExp, loc} =>
         TFPFNM
             {
              argVarList = varIdInfoList,
              bodyTy = bodyTy,
              bodyExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap bodyExp,
              loc = loc
              }
       | TFPPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
         TFPPOLYFNM
           {
            btvEnv = btvEnv, 
            argVarList = argVarList, 
            bodyTy = bodyTy, 
            bodyExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap bodyExp,
            loc=loc
            }
       | TFPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
         TFPPOLY
           {
            btvEnv = btvEnv, 
            expTyWithoutTAbs = expTyWithoutTAbs,
            exp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp,
            loc=loc
            }
       | TFPTAPP {exp, expTy, instTyList, loc} =>
         TFPTAPP
             {
              exp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp,
              expTy = expTy,
              instTyList = instTyList,
              loc = loc
              }
       | TFPSELECT {label, exp, expTy, resultTy, loc} => 
	 TFPSELECT
             {
              label = label,
              exp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp,
              expTy = expTy, 
              resultTy = resultTy,
              loc = loc
              }
       | TFPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
         TFPMODIFY {label = label, 
                    recordExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap recordExp, 
                    recordTy = recordTy, 
                    elementExp = annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap elementExp, 
                    elementTy = elementTy, 
                    loc = loc}
       | TFPCAST (exp, ty, loc) => 
         TFPCAST (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp, ty, loc) 
       | TFPLIST {expList, listTy, loc} =>
         TFPLIST {expList = map (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap) expList, 
                  listTy = listTy, 
                  loc = loc}
       | TFPSEQ {expList, expTyList, loc} =>
         TFPSEQ {expList = map (annotateExternalIdTfpexp annotateFunctionVarIdInfo
                                                    IDIndexMap) 
                               expList, 
                 expTyList = expTyList, 
                 loc = loc}

  and annotateExternalIdTfpdec annotateFunctionVarIdInfo IDIndexMap tfpdec =
      case tfpdec of
          TFPVAL (binds, loc) =>
          let
              fun toNewBinds (valIdent, exp) = 
                  (annotateExternalIdValIdent annotateFunctionVarIdInfo IDIndexMap valIdent, 
                   annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp)
          in
	      TFPVAL (map toNewBinds binds, loc)
          end
        | TFPVALREC (binds, loc) =>
          let
              fun toNewBinds (varIdInfo, ty, exp) = 
                  (annotateFunctionVarIdInfo IDIndexMap varIdInfo, 
                   ty, 
                   annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp)
          in
	      TFPVALREC (map toNewBinds binds, loc)
          end
        | TFPVALPOLYREC (localBtvEnv, binds, loc) =>
          let
              fun toNewBinds (var, ty, exp) =
                  (annotateFunctionVarIdInfo IDIndexMap var, 
                   ty, 
                   annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap exp)
          in
	      TFPVALPOLYREC (localBtvEnv, map toNewBinds binds, loc)
          end
        | TFPLOCALDEC (localDecs, decs, loc) => 
	  TFPLOCALDEC
              (map (annotateExternalIdTfpdec annotateFunctionVarIdInfo IDIndexMap) localDecs,
               map (annotateExternalIdTfpdec annotateFunctionVarIdInfo IDIndexMap) decs,
               loc)
        | TFPSETFIELD (e1, e2, int, ty, loc) =>
          TFPSETFIELD
              (annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap e1,
               annotateExternalIdTfpexp annotateFunctionVarIdInfo IDIndexMap e2,
               int,
               ty,
               loc)
        | TFPFUNCTORDEC {name, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet, 
                         generativeExnIDSet, generativeVarIDSet, bodyCode} => 
          TFPFUNCTORDEC {name = name,
                         formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
                         formalVarIDSet = formalVarIDSet,
                         formalExnIDSet = formalExnIDSet,
                         generativeExnIDSet = generativeExnIDSet,
                         generativeVarIDSet = generativeVarIDSet,
                         bodyCode = map (annotateExternalIdTfpdec annotateFunctionVarIdInfo IDIndexMap) bodyCode}
        | TFPLINKFUNCTORDEC x => TFPLINKFUNCTORDEC x
        | TFPEXNBINDDEF x => TFPEXNBINDDEF x


  fun collectVarExternalVarIDVarIdInfo {displayName, ty, varId} =
      case varId of
          T.EXTERNAL index => ExVarID.Set.singleton (index)
        | T.INTERNAL _ => ExVarID.Set.empty

  fun collectVarExternalVarIDValIdent valIdent =
      case valIdent of
          T.VALIDENT varIdInfo => collectVarExternalVarIDVarIdInfo varIdInfo
        | T.VALIDENTWILD _ => ExVarID.Set.empty

  fun collectVarExternalVarIDTfpdec tfpdec =
      case tfpdec of
          TFPVAL (binds, loc) =>
          foldl (fn ((valIdent, _), indexSet) =>
                    ExVarID.Set.union(collectVarExternalVarIDValIdent valIdent, indexSet))
                ExVarID.Set.empty
                binds
        | TFPVALREC (binds, loc) =>
          foldl (fn ((varIdInfo, ty, exp), indexSet) =>
                    ExVarID.Set.union(collectVarExternalVarIDVarIdInfo varIdInfo, indexSet))
                ExVarID.Set.empty
                binds
        | TFPVALPOLYREC (localBtvEnv, binds, loc) =>
          foldl (fn ((varIdInfo, ty, exp), indexSet) =>
                    ExVarID.Set.union(collectVarExternalVarIDVarIdInfo varIdInfo, indexSet))
                ExVarID.Set.empty      
                binds
        | TFPLOCALDEC (localDecs, decs, loc) => 
          collectVarExternalVarIDTfpdecs decs
        | TFPSETFIELD (e1, e2, int, ty, loc) => 
          raise Control.Bug "setfield inside functor body"
        | TFPFUNCTORDEC x => raise Control.Bug "functor declaration inside functor body"
        | TFPLINKFUNCTORDEC {refreshedExternalVarIDTable, ...} => 
          foldl (fn (index, set) => ExVarID.Set.add(set, index))
                ExVarID.Set.empty
                (ExVarID.Map.listItems refreshedExternalVarIDTable)
        | TFPEXNBINDDEF _ => ExVarID.Set.empty      

  and collectVarExternalVarIDTfpdecs tfpdecs =
      foldl (fn (tfpdec, indexSet) =>
                ExVarID.Set.union (collectVarExternalVarIDTfpdec tfpdec, indexSet))
            ExVarID.Set.empty
            tfpdecs

  (**************************************************************************************************************)
  fun collectDefExnIDTfpexps tfpexps =
      foldl (fn (exp, exnIDSet) =>
                ExnTagID.Set.union(collectDefExnIDTfpexp exp, 
                                   exnIDSet))
            ExnTagID.Set.empty
            tfpexps
      
  and collectDefExnIDTfpexp tfpexp = 
      case tfpexp of
          TFPFOREIGNAPPLY {funExp, funTy, instTyList, argExpList, argTyList, attributes, loc} =>
          collectDefExnIDTfpexps (funExp :: argExpList)
        | TFPEXPORTCALLBACK {funExp, argTyList, resultTy, attributes, loc} =>
          collectDefExnIDTfpexp funExp
        | TFPSIZEOF _ => ExnTagID.Set.empty
        | TFPCONSTANT _ => ExnTagID.Set.empty
        | TFPGLOBALSYMBOL _ => ExnTagID.Set.empty
        | TFPVAR _ => ExnTagID.Set.empty
        | TFPGETFIELD _ => ExnTagID.Set.empty
        | TFPARRAY {sizeExp, initExp, elementTy, resultTy, loc} =>
          collectDefExnIDTfpexps [sizeExp, initExp]
        | TFPPRIMAPPLY {primOp = prim, instTyList = tys, argExpOpt = NONE, loc} => ExnTagID.Set.empty
        | TFPPRIMAPPLY {primOp = prim, instTyList = tys, argExpOpt = SOME exp, loc} => 
          collectDefExnIDTfpexp exp
        | TFPOPRIMAPPLY {oprimOp, keyTyList, instances, argExpOpt = NONE, loc}
          => ExnTagID.Set.empty
        | TFPOPRIMAPPLY
            {oprimOp, keyTyList, instances, argExpOpt = SOME exp, loc} => 
          collectDefExnIDTfpexp exp
        | TFPDATACONSTRUCT {con, instTyList = tys, argExpOpt = NONE, loc} => ExnTagID.Set.empty
        | TFPDATACONSTRUCT {con, instTyList = tys, argExpOpt = SOME exp, loc} => 
          collectDefExnIDTfpexp exp
        | TFPEXNCONSTRUCT {exn, instTyList = tys, argExpOpt = NONE, loc} => ExnTagID.Set.empty
        | TFPEXNCONSTRUCT {exn, instTyList = tys, argExpOpt = SOME exp, loc} => 
          collectDefExnIDTfpexp exp
        | TFPAPPM {funExp = operator, funTy = ty, argExpList = operandList, loc} =>
          collectDefExnIDTfpexps (operator :: operandList)
        | TFPMONOLET {binds, bodyExp=exp, loc} => 
          ExnTagID.Set.union
              (foldl (fn ((v, e), exnIDSet) =>
                         ExnTagID.Set.union(exnIDSet, collectDefExnIDTfpexp e))
                     ExnTagID.Set.empty
                     binds,
               collectDefExnIDTfpexp exp)
        | TFPLET (decs, exps, tyl, loc) => 
          ExnTagID.Set.union
              (collectDefExnIDTfpdecs decs, collectDefExnIDTfpexps exps)
        | TFPRECORD {fields, recordTy=ty, loc} =>
          SEnv.foldl (fn (e, exnIDSet) =>
                         ExnTagID.Set.union(exnIDSet, collectDefExnIDTfpexp e))
                     ExnTagID.Set.empty
                     fields
        | TFPRAISE (exp, ty, loc) => collectDefExnIDTfpexp exp
        | TFPHANDLE {exp=exp1, exnVar=v, handler=exp2, loc} => 
          collectDefExnIDTfpexps [exp1, exp2]
        | TFPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
          collectDefExnIDTfpexps (expList @ (map #2 ruleList))
        | TFPFNM {argVarList = varIdInfoList, bodyTy, bodyExp, loc} =>
          collectDefExnIDTfpexp bodyExp
        | TFPPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
          collectDefExnIDTfpexp bodyExp
        | TFPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
          collectDefExnIDTfpexp exp
        | TFPTAPP {exp, expTy, instTyList, loc} =>
          collectDefExnIDTfpexp exp
        | TFPSELECT {label, exp, expTy, resultTy, loc} => 
          collectDefExnIDTfpexp exp
        | TFPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
          collectDefExnIDTfpexps [recordExp, elementExp]
        | TFPCAST (exp, ty, loc) =>  
          collectDefExnIDTfpexp exp
        | TFPLIST {expList, listTy, loc} =>
          collectDefExnIDTfpexps expList
        | TFPSEQ {expList, expTyList, loc} =>
          collectDefExnIDTfpexps expList

  and collectDefExnIDTfpdecs tfpdecs =
      foldl (fn (dec, exnIDSet) =>
                ExnTagID.Set.union(collectDefExnIDTfpdec dec, 
                                   exnIDSet))
            ExnTagID.Set.empty
            tfpdecs

  and collectDefExnIDTfpdec tfpdec =
      case tfpdec of
          TFPVAL (valIDExpList, loc) => 
          foldl (fn ((_, exp), exnIDSet) => ExnTagID.Set.union(collectDefExnIDTfpexp exp, exnIDSet))
                ExnTagID.Set.empty
                valIDExpList
        | TFPVALREC (varIDTyTfpexpList, loc) =>
          foldl (fn ((_ , _ , exp), exnIDSet) => 
                    ExnTagID.Set.union(collectDefExnIDTfpexp exp, exnIDSet))
                ExnTagID.Set.empty
                varIDTyTfpexpList
        | TFPVALPOLYREC (btvEnv, varIDTyTfpexpList, loc) =>
          foldl (fn ((_ , _ , exp), exnIDSet) => 
                    ExnTagID.Set.union(collectDefExnIDTfpexp exp, exnIDSet))
                ExnTagID.Set.empty
                varIDTyTfpexpList
        | TFPLOCALDEC (decs1, decs2, loc) =>
          ExnTagID.Set.union (collectDefExnIDTfpdecs decs1, 
                              collectDefExnIDTfpdecs decs2)
        | TFPSETFIELD _ => ExnTagID.Set.empty
        | TFPEXNBINDDEF exnInfoList => 
          foldl (fn ({tag, ...}, exnIDSet) =>
                    ExnTagID.Set.add (exnIDSet, tag))
                ExnTagID.Set.empty
                exnInfoList
        | TFPFUNCTORDEC _ => raise Control.Bug "TFPFUNCTOR cannot be in VALGROUP!"
        | TFPLINKFUNCTORDEC _ => raise Control.Bug "TFPLINKFUNCTOR cannot be in VALGROUP!"


  fun tfpdecsToTfpBasicBlock tfpdecs =
      let
          fun stripValBlockNilHead (nil, _) tail = tail
            | stripValBlockNilHead (code, exnIDSet) tail = 
              (TFPVALBLOCK {code = code, exnIDSet = exnIDSet}) :: tail
                                         
          val ((valBlockCode, exnIDSet), tailBlocks) =
              foldr (fn (tfpdec, ((valBlockCode, exnIDSet), tailBlocks)) =>
                        case (tfpdec, valBlockCode) of
                            (TFPLINKFUNCTORDEC functorLinkInfo, _) =>
                            ((nil, ExnTagID.Set.empty), 
                             (TFPLINKFUNCTORBLOCK functorLinkInfo) :: 
                             stripValBlockNilHead (valBlockCode,exnIDSet) tailBlocks)
                          | (TFPVAL _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPVALREC _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPVALPOLYREC _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPLOCALDEC _ , code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPSETFIELD _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPEXNBINDDEF _, code) => 
                            ((code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPFUNCTORDEC _, _) => raise Control.Bug "TFPFUNCTORDEC oppear inside functor body!"
                    )
                    ((nil, ExnTagID.Set.empty), nil)
                    tfpdecs
      in stripValBlockNilHead (valBlockCode, exnIDSet) tailBlocks end
      
            
  fun tfpdecsToTfpTopBlock tfpdecs = 
      let
          fun stripValBlockNilHead (nil, _)  tail = tail
            | stripValBlockNilHead (code, exnIDSet) tail = 
              TFPBASICBLOCK(TFPVALBLOCK {code = code, exnIDSet = exnIDSet}) :: tail
                                         
          val ((valBlockCode, exnIDSet), tailBlocks) =
              foldr (fn (tfpdec, ((valBlockCode, exnIDSet), tailBlocks)) =>
                        case (tfpdec, valBlockCode) of
                            (TFPFUNCTORDEC {name, 
                                            formalAbstractTypeIDSet, 
                                            formalVarIDSet, 
                                            formalExnIDSet, 
                                            generativeVarIDSet, 
                                            generativeExnIDSet, 
                                            bodyCode},
                             _) =>
                            let
                                val functorBlock =
                                    TFPFUNCTORBLOCK {name = name, 
                                                     formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
                                                     formalVarIDSet = formalVarIDSet, 
                                                     formalExnIDSet = formalExnIDSet, 
                                                     generativeVarIDSet = generativeVarIDSet, 
                                                     generativeExnIDSet = generativeExnIDSet, 
                                                     bodyCode = tfpdecsToTfpBasicBlock bodyCode}
                            in
                                ((nil, ExnTagID.Set.empty), 
                                 functorBlock  :: stripValBlockNilHead (valBlockCode, exnIDSet) tailBlocks)
                            end
                          | (TFPLINKFUNCTORDEC functorLinkInfo, _) =>
                            ((nil, ExnTagID.Set.empty),
                             (TFPBASICBLOCK (TFPLINKFUNCTORBLOCK functorLinkInfo)) ::
                             stripValBlockNilHead (valBlockCode, exnIDSet) tailBlocks)
                          | (TFPVAL _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPVALREC _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPVALPOLYREC _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPLOCALDEC _ , code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPSETFIELD _, code) => 
                            ((tfpdec ::  code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                          | (TFPEXNBINDDEF _, code) => 
                            ((code, ExnTagID.Set.union (exnIDSet,  collectDefExnIDTfpdec tfpdec)),
                             tailBlocks)
                    )
                    ((nil, ExnTagID.Set.empty), nil)
                    tfpdecs
      in stripValBlockNilHead (valBlockCode, exnIDSet) tailBlocks end

  (**************************************************************************************************************)
  fun setExternalVarIDTopBasis (topBasis : VIC.topExternalVarIDBasis) =
      let
          val (topFunEnv, topVarEnv) = topBasis
          val (newTopVarEnv, newDeltaIDMap) =
              SEnv.foldli (fn (sourceName, varIDItem, (newTopVarEnv, newDeltaIDMap)) =>
                              case varIDItem of
                                  VIC.External externalID =>
                                  let
                                      val newID = 
                                           ExVarID.generate ()
                                  in
                                      (
                                       SEnv.insert(newTopVarEnv, 
                                                   sourceName, 
                                                   VIC.External newID
                                                  ),
                                       ExVarID.Map.insert(newDeltaIDMap, externalID, (sourceName, newID))
                                      )
                                  end
                                | VIC.Dummy =>
                                  (SEnv.insert (newTopVarEnv,sourceName,VIC.Dummy),
                                   newDeltaIDMap)
                                | VIC.Internal _ => raise Control.Bug "illegal Internal item in top Env")
                          (SEnv.empty, ExVarID.Map.empty)
                          topVarEnv
      in
          ((topFunEnv, newTopVarEnv), newDeltaIDMap)
      end
      
  fun IDMapJoinExternalVarIDMap IDMap externalVarIDMap =
      VarID.Map.foldli (fn (srcID, entry as (displayName1, objExternalID), newIDMap) =>
                        case ExVarID.Map.find(externalVarIDMap, objExternalID) of
                            NONE => VarID.Map.insert(newIDMap, srcID, entry)
                          | SOME entry => VarID.Map.insert(newIDMap, srcID, entry))
                    VarID.Map.empty
                    IDMap
end
end
 
