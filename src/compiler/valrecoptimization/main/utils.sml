(**
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: utils.sml,v 1.11 2007/02/28 17:57:20 katsu Exp $
 *)
structure VALREC_Utils =
struct
local
  open PatternCalc
in
  structure T = Types
  type globalContext = InitialTypeContext.topTypeContext

  datatype strSSetInfo = STRSSET of (varSet * strMap)
  withtype varSet = SSet.set
  and strMap = strSSetInfo SEnv.map
  and funMap = strSSetInfo SEnv.map

  type Map = (varSet * strMap)

  type context = varSet * strMap * funMap
  val emptyContext = (SSet.empty,SEnv.empty,SEnv.empty) : context


  fun extractMapFromContext (varSet, strMap, funMap) =
      (varSet, strMap)

  fun bindIdInEmptyContext id =
      (SSet.singleton(id),
       SEnv.empty,
       SEnv.empty)

  fun bindFunInEmptyContext (funid, (varSet,strMap)) =
      (
       SSet.empty,
       SEnv.empty,
       SEnv.singleton(funid, STRSSET (varSet,strMap))
       )

  fun bindStrInContext (context:context, strid, (varSet,strMap)) =
      (
       SSet.union (#1 context, varSet),
       SEnv.insert(#2 context, strid, STRSSET (varSet,strMap)),
       #3 context
       )

  fun injectVarSetInEmptyContext varSet =
      (varSet,SEnv.empty,SEnv.empty)

  fun extendContextWithContext (oldContext:context, newContext:context) =
      (SSet.union (#1 oldContext, #1 newContext),
       SEnv.unionWith #1 (#2 newContext, #2 oldContext),
       SEnv.unionWith #1 (#3 newContext, #3 oldContext)
       )

  fun lookupStructureInContext (context:context as (_,strMap,_), longid) =
      let
        fun lookup strMap nil = raise Control.Bug "lookupStructureInContext:NilPath"
          | lookup strMap [strName] = 
            (
             case SEnv.find(strMap, strName) of
               NONE => NONE
             | SOME (STRSSET (varSet, strMap)) =>
               SOME (varSet, strMap)
            )
          | lookup strMap (strName :: path) =
            (
             case SEnv.find(strMap, strName) of
               NONE => NONE
             | SOME (STRSSET (_, strMap)) => 
               lookup strMap path
            )
      in
        lookup strMap longid
      end
        
  fun varEnvToVarSet varEnv = 
      SEnv.foldli (fn (varId,_,varSet) => SSet.add(varSet, varId))
                 SSet.empty
                 varEnv
                 
  fun strEnvToStrMap (T.STRUCTURE strEnvCont) =
    SEnv.map (fn ({env = (subTE,subVE,subSE),...}) =>
                   let
                     val varSet = varEnvToVarSet subVE
                   in
                     STRSSET (varSet, strEnvToStrMap subSE)
                   end
               )
      strEnvCont

  fun lookupStructureInGlobalContext (globalContext as {strEnv = T.STRUCTURE strEnvCont,...} :globalContext, longid) =
      let
        fun lookup strEnvCont nil = raise Control.Bug "lookupStructureInGlobalContext"
          | lookup strEnvCont [strName] =
            (
             case (SEnv.find(strEnvCont,strName)) of
               NONE => NONE
             | SOME {env = (_, varEnv, strEnv),...} =>
               SOME (varEnvToVarSet varEnv, strEnvToStrMap strEnv)
            )
          | lookup strEnvCont (strName :: path) = 
            (
             case SEnv.find(strEnvCont, strName) of
               NONE => NONE
             | SOME {env = (_,_,T.STRUCTURE strEnvCont), ...} => 
               lookup strEnvCont path
            )
      in
        lookup strEnvCont longid
      end

  fun lookupStructure (globalContext,context:context,longid) =
      case lookupStructureInContext (context, longid) of
        SOME (varSet, strMap) => (varSet, strMap)
      | NONE => 
        case lookupStructureInGlobalContext (globalContext, [Path.topStrName] @ longid) of
          SOME (varSet, strMap) => (varSet, strMap)
        | NONE => (SSet.empty, SEnv.empty)

  fun lookupFunctor (globalContext : globalContext , context :context ,string) =
      case SEnv.find(#3 context,string) of
        SOME (STRSSET map) => map
      | NONE => 
        case SEnv.find(#funEnv globalContext,string) of
          SOME { functorSig = 
                 { 
                  func = { 
                          body = {
                                  constrained = (_,(_,subVE,subSE)),
                                  ...
                                  },
                          ...
                          },
                  ...
                  },
                 ...
                 } => (varEnvToVarSet subVE, strEnvToStrMap subSE)
        | NONE => (SSet.empty, SEnv.empty)
      
  fun addIdAsSuffix prefix strName =
      if prefix = "" then
        strName
      else 
        prefix ^ "." ^ strName
        
  (****** for local context ********)
  fun getFreeIdsFromStrMap depthPath strMap =
      SEnv.foldli (fn (strName, STRSSET (subVarSet, subStrMap), sumSet) =>
                      let
                        val crtDepthPath = addIdAsSuffix depthPath strName
                        val subSumSet1 = 
                            SSet.foldl (fn (varId,subSumSet1) => 
                                           SSet.add(subSumSet1, addIdAsSuffix crtDepthPath varId)
                                           )
                                       SSet.empty
                                       subVarSet
                                           
                        val subSumSet2 = getFreeIdsFromStrMap crtDepthPath subStrMap
                      in
                        SSet.union (SSet.union (sumSet,subSumSet1), subSumSet2)
                      end)
                  SSet.empty
                  strMap
                        
  fun getFreeIdsFromContextStrItem (varSet, strMap) =
      SSet.union (varSet, getFreeIdsFromStrMap "" strMap)

  (******* For globalContext ***********)
  fun getFreeIdsFromVarEnv depthPath varEnv =
      SEnv.foldli (fn (varId, _ , varSet) =>
                      SSet.add(varSet,addIdAsSuffix depthPath varId)
                      )
                  SSet.empty
                  varEnv

  fun getFreeIdsFromStrEnv depthPath (T.STRUCTURE strEnvCont) =
      SEnv.foldli (fn (strName, {env= (_ ,subVarEnv, subStrEnv),...}, sumSet) =>
                      let
                        val crtDepthPath = addIdAsSuffix depthPath strName
                        val subSumSet1 = 
                            getFreeIdsFromVarEnv crtDepthPath subVarEnv
                        val subSumSet2 = 
                            getFreeIdsFromStrEnv crtDepthPath subStrEnv
                      in
                        SSet.union (SSet.union (sumSet,subSumSet1), subSumSet2)
                      end)
                  SSet.empty
                  strEnvCont
                  
  fun getFreeIdsFromGlobalContextStrItem (varEnv, strEnv) =
      let
        val varSet1 = getFreeIdsFromVarEnv "" varEnv
        val varSet2 = getFreeIdsFromStrEnv "" strEnv
      in
        SSet.union (varSet1,varSet2)
      end

  fun getVisibleIdsByLongid (globalContext, context, longid) =
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
                      
  fun getFreeIdsInExp globalContext context plexp =
      case plexp of
        PLCONSTANT _ => SSet.empty
      | PLVAR (id,loc) => SSet.singleton(Absyn.longidToString(id))
      | PLTYPED (exp,ty,loc) => getFreeIdsInExp globalContext context exp
      | PLAPPM (funExp,argExpList,loc) =>
        SSet.union(getFreeIdsInExp globalContext context funExp, 
                   getFreeIdsInExpList globalContext context argExpList)
      | PLLET (localDeclList,mainExpList,loc) =>
        SSet.union(getFreeIdsInDeclList globalContext context localDeclList,
                   SSet.difference(getFreeIdsInExpList globalContext context mainExpList,
                                   getBoundIdsInDeclList globalContext context localDeclList))
      | PLRECORD (elementList,loc) =>
        foldl 
            (fn ((label,exp),S) =>
                SSet.union(S,getFreeIdsInExp globalContext context exp))
            SSet.empty
            elementList
      | PLRECORD_UPDATE (exp,elementList,loc) =>
        foldl 
            (fn ((label,exp),S) =>
                SSet.union(S,getFreeIdsInExp globalContext context exp))
            (getFreeIdsInExp globalContext context exp)
            elementList
      | PLTUPLE (elementList, loc) => getFreeIdsInExpList globalContext context elementList
      | PLRAISE (exp,loc) => getFreeIdsInExp globalContext context exp
      | PLHANDLE (handler,matchList, loc) =>
        foldl 
            (fn ((pat,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPat pat)))
            (getFreeIdsInExp globalContext context handler)
            matchList
      | PLFNM (matchList,loc) =>                      
        foldl 
            (fn ((patList,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPatList patList)))
            SSet.empty
            matchList
      | PLCASEM (selectorList, matchList, kind, loc) =>
        foldl 
            (fn ((patList,exp),S) =>
                SSet.union
                    (S,
                     SSet.difference
                         (getFreeIdsInExp globalContext context exp,
                          getFreeIdsInPatList patList)))
            (getFreeIdsInExpList globalContext context selectorList)
            matchList
      | PLRECORD_SELECTOR _ => SSet.empty
      | PLSELECT (label,exp, loc) => getFreeIdsInExp globalContext context exp
      | PLSEQ (expList,loc) => getFreeIdsInExpList globalContext context expList
      | PLCAST (exp,loc) => getFreeIdsInExp globalContext context exp
      | PLFFIIMPORT (exp,ty,loc) => getFreeIdsInExp globalContext context exp
      | PLFFIEXPORT (exp,ty,loc) => getFreeIdsInExp globalContext context exp
      | PLFFIAPPLY (cconv,funExp,args,retTy,loc) =>
        foldl (fn (PLFFIARG (exp, ty), z) =>
                  SSet.union (z, getFreeIdsInExp globalContext context exp)
                | (PLFFIARGSIZEOF (ty, SOME exp), z) =>
                  SSet.union (z, getFreeIdsInExp globalContext context exp)
                | (PLFFIARGSIZEOF (ty, NONE), z) => z)
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
        PLPATWILD _ => SSet.empty
      | PLPATID (id,loc) => SSet.singleton(Absyn.longidToString(id))
      | PLPATCONSTANT _ => SSet.empty
      | PLPATCONSTRUCT (constructor,arg, loc) => getFreeIdsInPat arg
      | PLPATRECORD (_,patList,_) =>
        foldl 
            (fn ((label,pat),S) =>
                SSet.union(S,getFreeIdsInPat pat))
            SSet.empty
            patList
      | PLPATLAYERED (id,_,pat,_) => 
        SSet.union(SSet.singleton(id),getFreeIdsInPat pat)
      | PLPATTYPED (pat,ty,loc) => getFreeIdsInPat pat
      | PLPATORPAT (pat1,pat2,loc) => SSet.union(getFreeIdsInPat pat1,getFreeIdsInPat pat2)

  and getFreeIdsInExBind (PLEXBINDDEF _) = SSet.empty
    | getFreeIdsInExBind (PLEXBINDREP(_,left,_,right,_)) =
      SSet.singleton(Absyn.longidToString(right))

  and getFreeIdsInDecl globalContext context pdecl =
      case pdecl of 
        PDVAL (tvarList, bindList, loc) => getFreeIdsInBindList globalContext context  bindList
      | PDDECFUN  (tvarList, declList, loc) => getFreeIdsInFundeclList globalContext context declList
      | PDVALREC (tvarList, bindList, loc) =>
        SSet.difference(getFreeIdsInBindList globalContext context bindList,
                        getBoundIdsInBindList globalContext context bindList)
      | PDTYPE _ => SSet.empty
      | PDDATATYPE _ => SSet.empty
      | PDABSTYPE _ => SSet.empty
      | PDREPLICATEDAT _ => SSet.empty
      | PDEXD (exBindList, loc) =>
        foldl 
            (fn (exBind,S) => SSet.union(S,getFreeIdsInExBind exBind))
            SSet.empty
            exBindList
      | PDLOCALDEC (localDeclList, mainDeclList, loc) =>
        SSet.union(getFreeIdsInDeclList  globalContext context localDeclList,
                   SSet.difference(getFreeIdsInDeclList globalContext context mainDeclList,
                                   getBoundIdsInDeclList globalContext context localDeclList))
      | PDINFIXDEC _ => SSet.empty
      | PDINFIXRDEC _ => SSet.empty
      | PDNONFIXDEC _ => SSet.empty
      | PDEMPTY => SSet.empty
      | PDOPEN _ => SSet.empty
      | _ => raise Control.Bug "invalid declaration"

  and getFreeIdsInDeclList globalContext context pdeclList =
      #1 (foldl
              (fn (decl,(freeIds,boundIds)) =>
                  (SSet.union(freeIds,
                              SSet.difference(getFreeIdsInDecl globalContext context decl,boundIds)),
                   SSet.union(boundIds,getBoundIdsInDecl globalContext context decl)))
              (SSet.empty,SSet.empty)
              pdeclList)


  and getBoundIdsInExBind (PLEXBINDDEF(_,id,_,_)) =
      SSet.singleton(id)
    | getBoundIdsInExBind (PLEXBINDREP (_,left,_,right,_)) =
      SSet.singleton(left)

  and getBoundIdsInDecl globalContext context pdecl = 
      case pdecl of
        PDVAL (tvarList, bindList , loc ) => getBoundIdsInBindList globalContext context bindList
      | PDDECFUN  (tvarList, declList, loc) => getBoundIdsInFundeclList globalContext context declList
      | PDVALREC (tvarList, bindList, loc) => getBoundIdsInBindList globalContext context bindList
      | PDTYPE _ => SSet.empty
      | PDDATATYPE (datBindList, loc) =>    
        foldl 
            (fn ((_,_,consList),S) =>
                foldl
                    (fn ((_,id,_),S) => SSet.union(S,SSet.singleton(id)))
                    S
                    consList)
            SSet.empty
            datBindList
      | PDABSTYPE(datBindList, declList, loc) => 
            getBoundIdsInDeclList globalContext context declList
      | PDREPLICATEDAT _ => SSet.empty
      | PDEXD (exBindList, loc) =>
        foldl 
            (fn (exBind,S) => SSet.union(S,getBoundIdsInExBind exBind))
            SSet.empty
            exBindList
      | PDLOCALDEC (localDeclList,mainDeclList,loc) => 
        getBoundIdsInDeclList globalContext context mainDeclList
      | PDINFIXDEC _ => SSet.empty
      | PDINFIXRDEC _ => SSet.empty
      | PDNONFIXDEC _ => SSet.empty
      | PDEMPTY => SSet.empty
      | PDOPEN (longvids,loc) => 
        foldl (
               fn (longvid,S) =>
                  SSet.union (S,getVisibleIdsByLongid (globalContext, context, longvid))
              )
              SSet.empty
              longvids
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
