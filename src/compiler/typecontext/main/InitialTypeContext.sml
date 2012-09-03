(**
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author YAMATODANI Kiyoshi
 * @version $Id: InitialTypeContext.sml,v 1.48 2007/03/05 00:39:40 katsu Exp $
 *)
structure InitialTypeContext =
struct
 
local
  structure TY = Types
  structure TP = TypeParser
  structure P = Path
  structure PT = PredefinedTypes
  structure TU = TypesUtils
  structure TC = TypeContext
in

  type topTypeContext =
       {
        strEnv : TY.strEnv, 
        sigEnv : TY.sigEnv, 
        funEnv : TY.funEnv
        }

  (****************************************)

  val initialVarEnv1 =
      foldl
          (fn (TY.TYCON {datacon = ref datacon, ...}, varEnv) =>
              SEnv.foldl
                  (fn (TY.CONID conPathInfo, varEnv) => 
                      SEnv.insert
                          (varEnv, #name conPathInfo, TY.CONID conPathInfo))
                  varEnv
                  datacon)
          SEnv.empty
          (SEnv.listItems (PT.initialTyConEnv))
            
  val initialVarEnv2 =
      let
        val nameTyPairs = 
            map
              (fn {bindName, ty, ...} => (bindName, ty))
              Primitives.primitives
        val varEnv2 =
            foldr 
              (fn ((name, ty), varEnv) =>
                  SEnv.insert(varEnv, name, TY.PRIM {name = name, ty = ty})
              )
              initialVarEnv1
              nameTyPairs
      in
        varEnv2
      end
 
  (* the first element of the member list is the default type. *)
  val overloadedIdList =
      [
        {
          name = "+",   
          ty = "['a#{int,real,word,byte}.'a * 'a -> 'a]",
          instances = [(PT.intty,"int", "addInt"),
                      (PT.realty,"real", "addReal"),
                      (PT.wordty,"word", "addWord"),
                      (PT.bytety,"byte", "addByte")]
        },
        {
          name = "-",   
          ty = "['a#{int,real,word,byte}.'a * 'a -> 'a]",
          instances = [(PT.intty,"int", "subInt"),
                       (PT.realty,"real", "subReal"),
                       (PT.wordty,"word", "subWord"),
                       (PT.bytety,"byte", "subByte")]
        },
        {
          name = "*",   
          ty = "['a#{int,real,word,byte}.'a * 'a -> 'a]",
          instances = [(PT.intty, "int", "mulInt"),
                       (PT.realty, "real", "mulReal"),
                       (PT.wordty, "word", "mulWord"),
                       (PT.bytety, "byte", "mulByte")]
        },
        {
          name = "div", 
          ty = "['a#{int,word,byte}.'a * 'a -> 'a]",
          instances = [(PT.intty, "int", "divInt"),
                       (PT.wordty, "word", "divWord"),
                       (PT.bytety, "byte", "divByte")]
        },
        {
          name = "mod", 
          ty = "['a#{int,word,byte}.'a * 'a -> 'a]",
          instances = [(PT.intty, "int", "modInt"),
                       (PT.wordty, "word", "modWord"),
                       (PT.bytety, "byte", "modByte")]
        },
        {
          name = "~",   
          ty = "['a#{int,real}.'a -> 'a]",
          instances = [(PT.intty, "int", "negInt"),
                       (PT.realty, "real", "negReal")]
        },
        {
          name = "abs", 
          ty = "['a#{int,real}.'a -> 'a]",
          instances = [(PT.intty, "int", "absInt"),
                       (PT.realty, "real", "absReal")]
        },
        {
          name = "<",   
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(PT.intty, "int", "ltInt"),
                       (PT.realty, "real", "ltReal"),
                       (PT.wordty, "word", "ltWord"),
                       (PT.bytety, "byte", "ltByte"),
                       (PT.charty, "char", "ltChar"),
                       (PT.stringty, "string", "ltString")]
        },
        {
          name = ">",   
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(PT.intty, "int", "gtInt"),
                       (PT.realty, "real", "gtReal"),
                       (PT.wordty, "word", "gtWord"),
                       (PT.bytety, "byte", "gtByte"),
                       (PT.charty, "char", "gtChar"),
                       (PT.stringty, "string", "gtString")]
        },
        {
          name = "<=",  
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(PT.intty, "int",  "lteqInt"),
                       (PT.realty, "real", "lteqReal"),
                       (PT.wordty, "word", "lteqWord"),
                       (PT.bytety, "byte", "lteqByte"),
                       (PT.charty, "char", "lteqChar"),
                       (PT.stringty, "string", "lteqString")]
        },
        {
          name = ">=",  
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(PT.intty, "int",  "gteqInt"),
                       (PT.realty, "real", "gteqReal"),
                       (PT.wordty, "word",  "gteqWord"),
                       (PT.bytety, "byte",  "gteqByte"),
                       (PT.charty, "char",  "gteqChar"),
                       (PT.stringty, "string", "gteqString")]
        },
        {
          name = "!!",  
          ty = "['a#{int,real,word,byte,char}.('a) ptr -> 'a]",
          instances = [(PT.intty, "int",  "UnmanagedMemory_subInt"),
                       (PT.realty, "real", "UnmanagedMemory_subReal"),
                       (PT.wordty, "word",  "UnmanagedMemory_subWord"),
                       (PT.wordty, "byte",  "UnmanagedMemory_sub"),
                       (PT.wordty, "char",  "UnmanagedMemory_sub")]
        }
      ]

  val initialVarEnv =
      let
        fun makePrimitive {name, ty, instances} =
            let
              val oprimTy = TP.readTy PT.initialTyConEnv ty
              val instanceMap = 
                  foldr
                    (fn ((instTy, instTyName, instName), instMap) =>
                        let
                          val newInstTy = TU.tpappTy (oprimTy, [instTy])
                          val varInfo = {name = instName, ty = newInstTy}
                        in
                          SEnv.insert (instMap, instTyName, varInfo)
                        end)
                    SEnv.empty
                    instances
            in
              (name, oprimTy, instanceMap)
            end
        val varEnv =
            foldr 
              (fn ((name, ty, instances), varEnv) =>
                  let
                    val oprimInfo =
                        {name = name, ty = ty, instances = instances}
                  in
                    SEnv.insert (varEnv, name, TY.OPRIM oprimInfo)
                  end
              )
              initialVarEnv2
              (map makePrimitive overloadedIdList)
(*
        val _ = if (systemVarIdent > SE.maxSystemVarId)
                then raise Control.Bug "exceeds maxSystemVarIdent"
                else ()
*)
      in
        varEnv
      end

  val initialStrEnv = TY.emptyStrEnv

  val initialTypeContext =
      {
        tyConEnv = PT.initialTyConEnv,
        varEnv = initialVarEnv,
        strEnv = initialStrEnv,
        sigEnv = TY.emptySigEnv,
        funEnv = TY.emptyFunEnv
      } : TypeContext.context

  val initialTopTypeContext =
      {
       strEnv = 
         TY.STRUCTURE
          (SEnv.singleton
           (
            P.topStrName,
            {
             id = P.topStrID,
             name = P.topStrName,
             strpath = P.NilPath,
             env = (PT.initialTyConEnv, initialVarEnv, TY.emptyStrEnv)
             }
            )
           ),
        sigEnv = TY.emptySigEnv,
        funEnv = TY.emptyFunEnv
      } : topTypeContext

  local
      fun injectPathToTop path =
          case path of
              P.PStructure(topID, topName, tailPath) =>
              if topName = P.topStrName
              then path
              else P.PStructure(P.topStrID, P.topStrName, path)
            | _ => P.PStructure(P.topStrID, P.topStrName, path)

      fun injectBtvKindToTop ({index, recKind, eqKind} : TY.btvKind) =
          {
           index = index,
           recKind = injectRecKindToTop recKind,
           eqKind = eqKind
           }

      and injectRecKindToTop recKind =
          case recKind of
              TY.REC tyMap => TY.REC(SEnv.map injectTyToTop tyMap)
            | TY.OVERLOADED tys => TY.OVERLOADED (map injectTyToTop tys)
            | TY.UNIV => TY.UNIV
      and injectTyConToTop
              ({name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon} : TY.tyCon) =
              (
               datacon := injectVarEnvToTop (!datacon);
               {
                name = name,
                strpath = injectPathToTop strpath,
                abstract = abstract,
                tyvars = tyvars,
                id = id,
                eqKind = eqKind,
                boxedKind = boxedKind,
                datacon = datacon
                }
               )
      and injectTyToTop ty =
          case ty of
              TY.TYVARty(tyRef as ref(TY.SUBSTITUTED destTy)) =>
              (tyRef := TY.SUBSTITUTED(injectTyToTop destTy); ty)
            | TY.FUNMty(domainTyList, rangeTy) =>
              TY.FUNMty(map injectTyToTop domainTyList, injectTyToTop rangeTy)
            | TY.RECORDty tyMap => TY.RECORDty(SEnv.map injectTyToTop tyMap)
            | TY.CONty{tyCon, args} =>
              let
                  (* datacon is not updated here, this must have been updated
                   * already.
                   * This is in order to avoid infinite recursion.
                   *)
                  fun injectTyCon
                          {name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon} =
                          {
                           name = name,
                           strpath = injectPathToTop strpath,
                           abstract = abstract,
                           tyvars = tyvars,
                           id = id,
                           eqKind = eqKind,
                           boxedKind = boxedKind,
                           datacon = datacon
                           }
              in
                  TY.CONty
                      {tyCon = injectTyCon tyCon, args = map injectTyToTop args}
              end
            | TY.POLYty{boundtvars, body} =>
              TY.POLYty
                  {
                   boundtvars = IEnv.map injectBtvKindToTop boundtvars,
                   body = injectTyToTop body
                   }
            | TY.INDEXty(ty, id) => TY.INDEXty(injectTyToTop ty, id)
            | TY.ALIASty(alias, actual) =>
              TY.ALIASty(injectTyToTop alias, injectTyToTop actual)
            | TY.ABSSPECty(specTy,impl) =>
              TY.ABSSPECty(injectTyToTop specTy,impl)
            | _ => ty
                   
      and injectVarPathInfoToTop {name, strpath, ty} =
          {
           name = name,
           strpath = injectPathToTop strpath,
           ty = injectTyToTop ty
           }
      and injectConPathInfoToTop {name, strpath, funtyCon, ty, tag, tyCon} =
          {
           name = name,
           strpath = injectPathToTop strpath,
           funtyCon = funtyCon,
           ty = injectTyToTop ty,
           tag = tag,
           tyCon = tyCon
           }
      and injectVarEnvToTop varEnv =
          SEnv.map 
              (fn (TY.VARID varPathInfo) =>
                  TY.VARID (injectVarPathInfoToTop varPathInfo)
                | (TY.CONID conPathInfo) =>
                  TY.CONID (injectConPathInfoToTop conPathInfo)
                | other => other)
              varEnv
              
      and injectTyBindInfo tyBindInfo =
          case tyBindInfo of
              TY.TYCON tyCon => TY.TYCON(injectTyConToTop tyCon)
            | TY.TYFUN tyFun => TY.TYFUN(injectTyFunToTop tyFun)
            | TY.TYSPEC tySpec => TY.TYSPEC(injectTySpecToTop tySpec)
      and injectTySpecToTop ({spec = {name,id,strpath,tyvars,boxedKind,eqKind},
                              impl}) =
          {spec = {
                   name = name,
                   id = id,
                   strpath = injectPathToTop strpath,
                   tyvars = tyvars,
                   boxedKind = boxedKind,
                   eqKind = eqKind},
           impl = impl
           }
      and injectTyFunToTop ({name, tyargs, body} : TY.tyFun) =
          {
           name = name,
           tyargs = IEnv.map injectBtvKindToTop tyargs,
           body = injectTyToTop body
           }
      and injectTyConEnvToTop tyConEnv = SEnv.map injectTyBindInfo tyConEnv
      fun injectStrEnvToTop (TY.STRUCTURE strEnvCont) = 
        TY.STRUCTURE
         (SEnv.map
          (fn ({id, name, strpath, env = (TE, VE, SE)}) => 
             {
              id = id,
              name = name,
              strpath = P.PStructure(P.topStrID,P.topStrName,strpath),
              env =
              (
               injectTyConEnvToTop TE,
               injectVarEnvToTop VE,
               injectStrEnvToTop SE
               )
              })
          strEnvCont)
      fun extendStrEnvEntry
           (
            {id, name, strpath, env = (TE1, VE1, TY.STRUCTURE SE1)},
            ({env = (TE2, VE2, TY.STRUCTURE SE2), ...}:TY.strPathInfo)
            ) =
           {
            id = id,
            name = name,
            strpath = strpath,
            env =
            (
             SEnv.unionWith #1 (TE1, TE2),
             SEnv.unionWith #1 (VE1, VE2),
             TY.STRUCTURE (SEnv.unionWith #1 (SE1, SE2))
             )
            }
                  
      fun injectIdstateToTop idstate =
          case idstate of
              (TY.VARID varPathInfo) =>
              TY.VARID (injectVarPathInfoToTop varPathInfo)
            | (TY.CONID conPathInfo) =>
              TY.CONID (injectConPathInfoToTop conPathInfo)
            | other => other
  in
      fun extendTopTypeContextWithContext 
              ({strEnv = TY.STRUCTURE topStrEnvCont, 
                sigEnv = topSigEnv, 
                funEnv = topFunEnv} : topTypeContext)
              {strEnv = TY.STRUCTURE newStrEnvCont, 
               varEnv = newVarEnv, 
               tyConEnv  =  newTyConEnv, 
               sigEnv = newSigEnv,  
               funEnv = newFunEnv} =
              let
                  val newTopStrEnvCont =
                      SEnv.singleton
                          (
                           P.topStrName,
                           {
                            id = P.topStrID,
                            name = P.topStrName,
                            strpath = P.NilPath,
                            env = 
                              (injectTyConEnvToTop newTyConEnv,
                               injectVarEnvToTop newVarEnv,
                               injectStrEnvToTop (TY.STRUCTURE newStrEnvCont))
                              }
                           )
              in
                  {
                   strEnv = TY.STRUCTURE  (SEnv.unionWith extendStrEnvEntry (newTopStrEnvCont, topStrEnvCont)),
                   sigEnv = SEnv.unionWith #1 (newSigEnv, topSigEnv),
                   funEnv = SEnv.unionWith #1 (newFunEnv, topFunEnv)
                   }
              end
  end
      
  fun projectTypeContextInTopTypeContext {strEnv = TY.STRUCTURE strEnvCont, 
                                          sigEnv, 
                                          funEnv} =
      let
          val (tyConEnv, varEnv, strEnv) =
              case SEnv.find(strEnvCont, P.topStrName) of
                  SOME {env,...} => env
                | NONE => raise Control.Bug ("top type context contains no"^ P.topStrName)
      in
          {funEnv = funEnv,
           tyConEnv = tyConEnv,
           varEnv = varEnv,
           strEnv = strEnv,
           sigEnv = sigEnv}
      end
end
end
