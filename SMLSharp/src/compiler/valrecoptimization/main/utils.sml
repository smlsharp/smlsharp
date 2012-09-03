(**
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: utils.sml,v 1.16 2008/03/11 08:53:57 katsu Exp $
 *)
structure VALREC_Utils =
struct
local
  open PatternCalcFlattened
in
  structure T = Types
  structure NM = NameMap
  type globalContext = NameMap.topNameMap

  type varSet = SSet.set
  type funMap = varSet SEnv.map

  type context = varSet * funMap
  val emptyContext = (SSet.empty, SEnv.empty) : context

  fun bindIdInEmptyContext id =
      (SSet.singleton(id), SEnv.empty)

  fun bindFunInEmptyContext (funid, varSet) =
      (SSet.empty, SEnv.singleton(funid, varSet))

  fun injectVarSetInEmptyContext varSet =
      (varSet, SEnv.empty)

  fun extendContextWithContext (oldContext:context, newContext:context) =
      (SSet.union (#1 oldContext, #1 newContext),
       SEnv.unionWith #1 (#2 newContext, #2 oldContext)
       )

  fun varNameMapToVarSet prefixName varEnv = 
      SEnv.foldli (fn (varId,_, varSet) => 
                      let
                          val newName = case prefixName of
                                            "" => varId
                                          | _ => prefixName ^ "." ^ varId
                      in
                          SSet.add(varSet, newName)
                      end)
                  SSet.empty
                  varEnv
                 
  fun strNameMapToVarSet prefixName strEnv =
      SEnv.foldli
          (fn (strName, NM.NAMEAUX{basicNameMap=(subTE, subVE, subSE),...}, varSet) =>
              let
                  val newPrefixName = 
                      case prefixName of
                          "" => strName
                        | _ => prefixName ^ "." ^ strName
                  val varSet1 = varNameMapToVarSet newPrefixName subVE
              in
                  SSet.union (varSet1, varSet)
              end)
          SSet.empty
          strEnv

  fun nameMapToVarSet (nameMap:NameMap.currentNameMap) = 
      SSet.union
          (varNameMapToVarSet "" (#varNameMap nameMap),
           strNameMapToVarSet "" (#strNameMap nameMap))

  fun basicNameMapToVarSet (basicNameMap : NameMap.basicNameMap) =
      SSet.union
          (varNameMapToVarSet "" (#2 basicNameMap),
           strNameMapToVarSet "" (#3 basicNameMap))
      
  fun lookupFunctor (globalContext : NM.topNameMap, context:context, string) =
      case SEnv.find(#2 context, string) of
        SOME (varSet) => varSet
      | NONE => case SEnv.find(#funNameMap globalContext, string) of
                    SOME ({body=NM.NAMEAUX {basicNameMap, ...}, ...}) =>
                    basicNameMapToVarSet basicNameMap
                  | NONE => SSet.empty

  fun adjustVarSet (varSet, prefixName) =
      SSet.map (fn varName => prefixName^"."^varName) varSet
      
  fun addIdAsSuffix prefix strName =
      if prefix = "" then
        strName
      else 
        prefix ^ "." ^ strName
        
  fun getFreeIdsFromVarNameMap depthPath varNameMap =
      SEnv.foldli (fn (varId, _ , varSet) =>
                      SSet.add(varSet,addIdAsSuffix depthPath varId)
                      )
                  SSet.empty
                  varNameMap

  fun getFreeIdsFromStrNameMap depthPath strNameMap =
      SEnv.foldli (fn (strName, NM.NAMEAUX {basicNameMap=(_ ,subVarEnv, subStrEnv),...}, sumSet) =>
                      let
                        val crtDepthPath = addIdAsSuffix depthPath strName
                        val subSumSet1 = 
                            getFreeIdsFromVarNameMap crtDepthPath subVarEnv
                        val subSumSet2 = 
                            getFreeIdsFromStrNameMap crtDepthPath subStrEnv
                      in
                        SSet.union (SSet.union (sumSet,subSumSet1), subSumSet2)
                      end)
                  SSet.empty
                  strNameMap
                  
  fun getFreeIdsFromGlobalContextStrItem (varEnv, strEnv) =
      let
        val varSet1 = getFreeIdsFromVarNameMap "" varEnv
        val varSet2 = getFreeIdsFromStrNameMap "" strEnv
      in
        SSet.union (varSet1,varSet2)
      end

(*  fun getVisibleIdsByLongid (globalContext, context, longid) =
      case lookupStructureInContext (context, longid) of
        SOME (varSet, strMap) => 
        getFreeIdsFromContextStrItem (varSet, strMap)
      | NONE => 
        case lookupStructureInGlobalContext (globalContext, [Path.topStrName] @ longid) of
          SOME (varSet, strMap) =>
          getFreeIdsFromContextStrItem (varSet, strMap)
        | NONE => 
          (* unbound longid error case should be captured by typeinference *)
          SSet.empty
*)
                      
  fun getFreeIdsInExp globalContext context plexp =
      case plexp of
        PLFCONSTANT _ => SSet.empty
      | PLFGLOBALSYMBOL _ => SSet.empty
      | PLFVAR (id,loc) => SSet.singleton(NM.namePathToString(id))
      | PLFTYPED (exp,ty,loc) => getFreeIdsInExp globalContext context exp
      | PLFAPPM (funExp,argExpList,loc) =>
        SSet.union(getFreeIdsInExp globalContext context funExp, 
                   getFreeIdsInExpList globalContext context argExpList)
      | PLFLET (localDeclList,mainExpList,loc) =>
        SSet.union(getFreeIdsInDeclList globalContext context localDeclList,
                   SSet.difference(getFreeIdsInExpList globalContext context mainExpList,
                                   getBoundIdsInDeclList globalContext context localDeclList))
      | PLFRECORD (elementList,loc) =>
        foldl 
            (fn ((label,exp),S) =>
                SSet.union(S,getFreeIdsInExp globalContext context exp))
            SSet.empty
            elementList
      | PLFRECORD_UPDATE (exp,elementList,loc) =>
        foldl 
            (fn ((label,exp),S) =>
                SSet.union(S,getFreeIdsInExp globalContext context exp))
            (getFreeIdsInExp globalContext context exp)
            elementList
      | PLFTUPLE (elementList, loc) => getFreeIdsInExpList globalContext context elementList
      | PLFLIST (elementList, loc) => getFreeIdsInExpList globalContext context elementList
      | PLFRAISE (exp,loc) => getFreeIdsInExp globalContext context exp
      | PLFHANDLE (handler,matchList, loc) =>
        foldl 
            (fn ((pat,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPat pat)))
            (getFreeIdsInExp globalContext context handler)
            matchList
      | PLFFNM (matchList,loc) =>                      
        foldl 
            (fn ((patList,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPatList patList)))
            SSet.empty
            matchList
      | PLFCASEM (selectorList, matchList, kind, loc) =>
        foldl 
            (fn ((patList,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPatList patList)))
            (getFreeIdsInExpList globalContext context selectorList)
            matchList
      | PLFRECORD_SELECTOR _ => SSet.empty
      | PLFSELECT (label,exp, loc) => getFreeIdsInExp globalContext context exp
      | PLFSEQ (expList,loc) => getFreeIdsInExpList globalContext context expList
      | PLFCAST (exp,loc) => getFreeIdsInExp globalContext context exp
      | PLFFFIIMPORT (exp,ty,loc) => getFreeIdsInExp globalContext context exp
      | PLFFFIEXPORT (exp,ty,loc) => getFreeIdsInExp globalContext context exp
      | PLFFFIAPPLY (cconv,funExp,args,retTy,loc) =>
        foldl (fn (PLFFFIARG (exp, ty, loc), z) =>
                  SSet.union (z, getFreeIdsInExp globalContext context exp)
                | (PLFFFIARGSIZEOF (ty, SOME exp, loc), z) =>
                  SSet.union (z, getFreeIdsInExp globalContext context exp)
                | (PLFFFIARGSIZEOF (ty, NONE, loc), z) => z)
              (getFreeIdsInExp globalContext context funExp)
              args

  and getFreeIdsInExpList globalContext context plexpList =
      foldl 
          (fn (exp,S) => SSet.union(S,getFreeIdsInExp globalContext context exp))
          SSet.empty
          plexpList

  and getFreeIdsInFundeclList globalContext context fidRuleListList =
    let
      val boundList =       
        foldl
          (fn ((fidPat,rules),S) => SSet.union(getFreeIdsInPat fidPat,S))
          SSet.empty
          fidRuleListList
      val freeList = 
        foldl
          (fn ((fidPat,rules),S) => SSet.union(getFreeIdsInRule globalContext context rules,S))
          SSet.empty
          fidRuleListList
    in
      SSet.difference(freeList, boundList)
    end

  and getFreeIdsInRule globalContext context patListExpList =
        foldl 
            (fn ((patList,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPatList patList)))
            SSet.empty
            patListExpList


  and getFreeIdsInPatList patList =
      foldl 
          (fn (pat,S) => SSet.union(S,getFreeIdsInPat pat))
          SSet.empty
          patList

  and getFreeIdsInPat plpat = 
      case plpat of 
        PLFPATWILD _ => SSet.empty
      | PLFPATID (id,loc) => SSet.singleton(NM.namePathToString(id))
      | PLFPATCONSTANT _ => SSet.empty
      | PLFPATCONSTRUCT (constructor,arg, loc) => getFreeIdsInPat arg
      | PLFPATRECORD (_,patList,_) =>
        foldl 
            (fn ((label,pat),S) =>
                SSet.union(S,getFreeIdsInPat pat))
            SSet.empty
            patList
      | PLFPATLAYERED (id,_,pat,_) => 
        SSet.union(SSet.singleton(id),getFreeIdsInPat pat)
      | PLFPATTYPED (pat,ty,loc) => getFreeIdsInPat pat
      | PLFPATORPAT (pat1,pat2,loc) => SSet.union(getFreeIdsInPat pat1,getFreeIdsInPat pat2)

  and getFreeIdsInExBind (PLFEXBINDDEF _) = SSet.empty
    | getFreeIdsInExBind (PLFEXBINDREP(_,left,_,right,_)) =
      SSet.singleton(NM.namePathToString(right))

  and getFreeIdsInDecl globalContext context pdecl =
      case pdecl of 
        PDFVAL (tvarList, bindList, loc) => getFreeIdsInBindList globalContext context  bindList
      | PDFDECFUN  (tvarList, declList, loc) => getFreeIdsInFundeclList globalContext context declList
      | PDFVALREC (tvarList, bindList, loc) =>
        SSet.difference(getFreeIdsInBindList globalContext context bindList,
                        getBoundIdsInBindList globalContext context bindList)
      | PDFTYPE _ => SSet.empty
      | PDFDATATYPE _ => SSet.empty
      | PDFABSTYPE _ => SSet.empty
      | PDFREPLICATEDAT _ => SSet.empty
      | PDFEXD (exBindList, loc) =>
        foldl 
            (fn (exBind,S) => SSet.union(S,getFreeIdsInExBind exBind))
            SSet.empty
            exBindList
      | PDFLOCALDEC (localDeclList, mainDeclList, loc) =>
        SSet.union(getFreeIdsInDeclList  globalContext context localDeclList,
                   SSet.difference(getFreeIdsInDeclList globalContext context mainDeclList,
                                   getBoundIdsInDeclList globalContext context localDeclList))
      | PDFINTRO ((_, varNamePathEnv), strNameList, loc) =>
        NameMap.NPEnv.foldl
            (fn (idstate, sset) => 
                SSet.add(sset, 
                         NameMap.namePathToString
                             (NameMap.getNamePathFromIdstate(idstate))))
            SSet.empty
            varNamePathEnv
      | PDFINFIXDEC _ => SSet.empty
      | PDFINFIXRDEC _ => SSet.empty
      | PDFNONFIXDEC _ => SSet.empty
      | PDFEMPTY => SSet.empty
      | _ => raise Control.Bug "invalid declaration"


  and getFreeIdsInDeclList globalContext context pdeclList =
      #1 (foldl
              (fn (decl,(freeIds,boundIds)) =>
                  (SSet.union(freeIds,
                              SSet.difference(getFreeIdsInDecl globalContext context decl,boundIds)),
                   SSet.union(boundIds,getBoundIdsInDecl globalContext context decl)))
              (SSet.empty,SSet.empty)
              pdeclList)


  and getBoundIdsInExBind (PLFEXBINDDEF(_,id,_,_)) =
      SSet.singleton(NM.namePathToString(id))
    | getBoundIdsInExBind (PLFEXBINDREP (_,left,_,right,_)) =
      SSet.singleton(NM.namePathToString(left))

  and getBoundIdsInDecl globalContext context pdecl = 
      case pdecl of
        PDFVAL (tvarList, bindList , loc ) => getBoundIdsInBindList globalContext context bindList
      | PDFDECFUN  (tvarList, declList, loc) => getBoundIdsInFundeclList globalContext context declList
      | PDFVALREC (tvarList, bindList, loc) => getBoundIdsInBindList globalContext context bindList
      | PDFTYPE _ => SSet.empty
      | PDFDATATYPE (prefix, datBindList, loc) =>    
        foldl 
            (fn ((_,_,consList),S) =>
                foldl
                    (fn ((_,id,_),S) => SSet.union(S,SSet.singleton(id)))
                    S
                    consList)
            SSet.empty
            datBindList
      | PDFABSTYPE(prefix, datBindList, declList, loc) => 
            getBoundIdsInDeclList globalContext context declList
      | PDFREPLICATEDAT _ => SSet.empty
      | PDFEXD (exBindList, loc) =>
        foldl 
            (fn (exBind,S) => SSet.union(S,getBoundIdsInExBind exBind))
            SSet.empty
            exBindList
      | PDFLOCALDEC (localDeclList,mainDeclList,loc) => 
        getBoundIdsInDeclList globalContext context mainDeclList
      | PDFINTRO ((_, varNamePathEnv), strNameList, loc) =>
        NameMap.NPEnv.foldli
            (fn (namePath, _, sset) => SSet.add(sset, NameMap.namePathToString(namePath)))
            SSet.empty
            varNamePathEnv
      | PDFINFIXDEC _ => SSet.empty
      | PDFINFIXRDEC _ => SSet.empty
      | PDFNONFIXDEC _ => SSet.empty
      | PDFEMPTY => SSet.empty
      | _ => raise Control.Bug "invalid declaration"

  and getBoundIdsInDeclList globalContext context pdeclList =
      foldl 
          (fn (decl,S) => SSet.union(S,getBoundIdsInDecl globalContext context decl))
          SSet.empty
          pdeclList

  and getFreeIdsInBindList globalContext context bindList =
      #1 (foldl
              (fn ((pat,exp),(freeIds,boundIds)) =>
                  (SSet.union(freeIds,
                              SSet.difference(getFreeIdsInExp globalContext context exp,boundIds)),
                   SSet.union(boundIds,getFreeIdsInPat pat)))
              (SSet.empty,SSet.empty)
              bindList)

  and getBoundIdsInBindList globalContext context bindList =
      foldl
          (fn ((pat,exp),S) => SSet.union(getFreeIdsInPat pat,S))
          SSet.empty
          bindList
        
  and getBoundIdsInFundeclList globalContext context fidRuleListList =
        foldl
          (fn ((fidPat,rules),S) => SSet.union(getFreeIdsInPat fidPat,S))
          SSet.empty
          fidRuleListList
end
end
