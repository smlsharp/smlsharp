(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author OHORI Atsushi
 * @author YAMATODANI Kiyoshi
 * @version $Id: InitialTypeContext.sml,v 1.35 2006/02/18 04:59:31 ohori Exp $
 *)
structure InitialTypeContext =
struct
 
local
  structure TY = Types
  structure TP = TypeParser
  structure P = Path
  structure TU = TypesUtils
  structure SE = StaticEnv
  structure TC = TypeContext
in
  infixr 6 || 
  fun op ||(conPathInfo : TY.conPathInfo, varEnv) =
      SEnv.insert(varEnv, #name conPathInfo, TY.CONID conPathInfo);

  type topTypeContext =
       {
        strEnv : TY.strEnv, 
        sigEnv : TY.sigEnv, 
        funEnv : TY.funEnv
        }

  val trueCon =
      {
        name = "true",
        strpath = P.topStrPath,
        funtyCon = false,
        ty = SE.boolty,
        tyCon = SE.boolTyCon,
        tag = Constants.TAG_bool_true
      }
  val falseCon =
      {
        name = "false",
        strpath = P.topStrPath,
        funtyCon = false,
        ty = SE.boolty,
        tyCon = SE.boolTyCon,
        tag = Constants.TAG_bool_false
      }
  val _ = #datacon SE.boolTyCon := (trueCon || falseCon || SEnv.empty)

  val refCon =
      {
        name = "ref", 
        strpath = Path.topStrPath,
        funtyCon = true,
        ty = TP.readTy "['a.'a -> ('a) ref]",
        tyCon = SE.refTyCon,
        tag = Constants.TAG_ref_ref
      }
  val _ = #datacon SE.refTyCon := (refCon || SEnv.empty)

  val nilCon =
      {
        name = "nil", 
        strpath = P.topStrPath,
        funtyCon = false,
        ty = TP.readTy "['a.('a) list]",
        tyCon = SE.listTyCon,
        tag = Constants.TAG_list_nil
      }
  val consCon =
      {
        name = "::", 
        strpath = P.topStrPath,
        funtyCon = true,
        ty = TP.readTy "['a.'a * ('a) list -> ('a) list]",
        tyCon = SE.listTyCon,
        tag = Constants.TAG_list_cons
      }
  val _ = #datacon SE.listTyCon := (nilCon || consCon || SEnv.empty)

  val NONECon =
      {
        name = "NONE", 
        strpath = P.topStrPath,
        funtyCon = false,
        ty = TP.readTy "['a.('a) option]",
        tyCon = SE.optionTyCon,
        tag = Constants.TAG_option_NONE
      }
  val SOMECon =
      {
        name = "SOME", 
        strpath = P.topStrPath,
        funtyCon = true,
        ty = TP.readTy "['a.'a -> ('a) option]",
        tyCon = SE.optionTyCon,
        tag = Constants.TAG_option_SOME
      }
  val _ = #datacon SE.optionTyCon := (NONECon || SOMECon || SEnv.empty)


  local
    fun make exnTag (name, strpath, SOME argty) = 
        {
          name = name,
          strpath = strpath,
          funtyCon = true,
          ty = TY.FUNMty([argty], SE.exnty),
          tyCon = SE.exnTyCon,
          tag = exnTag
        }
      | make exnTag (name, strpath, NONE) = 
        {
          name = name,
          strpath = strpath,
          funtyCon = false,
          ty = SE.exnty,
          tyCon = SE.exnTyCon,
          tag = exnTag
        }
  in
  fun makeExnConpath (name, strpath, tyOpt) =
      let val exnTag = SE.newExnTag ()
      in make exnTag (name, strpath, tyOpt)
      end
  fun makeSystemExnConpath (name, strpath, tyOpt, exnTag) =
      if SE.maxSystemExnTag < exnTag
      then raise Control.Bug "exceeds maxSystemExnTag"
      else make exnTag (name, strpath, tyOpt)
  end

  fun ExnConpathToExnCon conpath =
      let
        val {name, strpath, funtyCon, ty, tyCon, tag} = conpath
      in
        {
         displayName = name,
         funtyCon = funtyCon,
         ty = ty,
         tyCon = tyCon,
         tag = tag
        }
      end

  val BindExnTag = Constants.TAG_exn_Bind
  val BindExnConpath =
      makeSystemExnConpath ("Bind", P.topStrPath, NONE, BindExnTag)
  val BindExnCon  = ExnConpathToExnCon BindExnConpath 
  val MatchExnTag = Constants.TAG_exn_Match
  val MatchExnConpath =
      makeSystemExnConpath ("Match", P.topStrPath, NONE, MatchExnTag)
  val MatchExnCon = ExnConpathToExnCon MatchExnConpath
  val MatchCompBugExnTag = Constants.TAG_exn_MatchCompBug
  val MatchCompBugExnConpath =
      makeSystemExnConpath
          ("MatchCompBug", P.topStrPath, SOME SE.stringty, MatchCompBugExnTag)
  val MatchCompBugExnCon =
      ExnConpathToExnCon MatchCompBugExnConpath 
  val FormatterExnTag = Constants.TAG_exn_Formatter
  val FormatterExnConpath =
      makeSystemExnConpath
          ("Formatter", P.topStrPath, SOME SE.stringty, FormatterExnTag)
  val FormatterExnCon = ExnConpathToExnCon FormatterExnConpath
  val SysErrExnTag = Constants.TAG_exn_SysErr
  val SysErrExnConpath =
      makeSystemExnConpath
          (
            "SysErr",
            P.topStrPath,
            SOME(TP.readTy("string * (int) option")),
            SysErrExnTag
          )
  val SysErrExnCon = ExnConpathToExnCon SysErrExnConpath

  (****************************************)

  val initialVarEnv1 =
      foldl 
      (fn (conPathInfo, varEnv) => 
          SEnv.insert(varEnv, #name conPathInfo, TY.CONID conPathInfo)
      )
      SEnv.empty
      [
       refCon,
       trueCon,
       falseCon,
       nilCon,
       consCon,
       BindExnConpath,
       MatchExnConpath,
       MatchCompBugExnConpath,
       FormatterExnConpath,
       SysErrExnConpath,
       NONECon,
       SOMECon
       ]
            
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
          instances = [(SE.intty,"int", "addInt"),
                      (SE.realty,"real", "addReal"),
                      (SE.wordty,"word", "addWord"),
                      (SE.wordty,"byte", "addByte")]
        },
        {
          name = "-",   
          ty = "['a#{int,real,word,byte}.'a * 'a -> 'a]",
          instances = [(SE.intty,"int", "subInt"),
                       (SE.realty,"real", "subReal"),
                       (SE.wordty,"word", "subWord"),
                       (SE.realty,"byte", "subByte")]
        },
        {
          name = "*",   
          ty = "['a#{int,real,word,byte}.'a * 'a -> 'a]",
          instances = [(SE.intty, "int", "mulInt"),
                       (SE.realty, "real", "mulReal"),
                       (SE.wordty, "word", "mulWord"),
                       (SE.wordty, "byte", "mulByte")]
        },
        {
          name = "div", 
          ty = "['a#{int,word,byte}.'a * 'a -> 'a]",
          instances = [(SE.intty, "int", "divInt"),
                       (SE.wordty, "word", "divWord"),
                       (SE.wordty, "byte", "divByte")]
        },
        {
          name = "mod", 
          ty = "['a#{int,word,byte}.'a * 'a -> 'a]",
          instances = [(SE.intty, "int", "modInt"),
                       (SE.wordty, "word", "modWord"),
                       (SE.wordty, "byte", "modByte")]
        },
        {
          name = "~",   
          ty = "['a#{int,real}.'a -> 'a]",
          instances = [(SE.intty, "int", "negInt"),
                       (SE.realty, "real", "negReal")]
        },
        {
          name = "abs", 
          ty = "['a#{int,real}.'a -> 'a]",
          instances = [(SE.intty, "int", "absInt"),
                       (SE.realty, "real", "absReal")]
        },
        {
          name = "<",   
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(SE.intty, "int", "ltInt"),
                       (SE.realty, "real", "ltReal"),
                       (SE.wordty, "word", "ltWord"),
                       (SE.wordty, "byte", "ltByte"),
                       (SE.charty, "char", "ltChar"),
                       (SE.stringty, "string", "ltString")]
        },
        {
          name = ">",   
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(SE.intty, "int", "gtInt"),
                       (SE.realty, "real", "gtReal"),
                       (SE.wordty, "word", "gtWord"),
                       (SE.wordty, "byte", "gtByte"),
                       (SE.charty, "char", "gtChar"),
                       (SE.stringty, "string", "gtString")]
        },
        {
          name = "<=",  
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(SE.intty, "int",  "lteqInt"),
                       (SE.realty, "real", "lteqReal"),
                       (SE.wordty, "word", "lteqWord"),
                       (SE.wordty, "byte", "lteqByte"),
                       (SE.charty, "char", "lteqChar"),
                       (SE.stringty, "string", "lteqString")]
        },
        {
          name = ">=",  
          ty = "['a#{int,real,word,byte,char,string}.'a * 'a -> bool]",
          instances = [(SE.intty, "int",  "gteqInt"),
                       (SE.realty, "real", "gteqReal"),
                       (SE.wordty, "word",  "gteqWord"),
                       (SE.wordty, "byte",  "gteqByte"),
                       (SE.charty, "char",  "gteqChar"),
                       (SE.stringty, "string", "gteqString")]
        }
      ]

  val initialVarEnv =
      let
        fun makePrimitive {name, ty, instances} =
            let
              val oprimTy = TP.readTy ty
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

  val initialStrEnv = SEnv.empty

  val initialTypeContext =
      {
        tyConEnv = SE.initialTyConEnv,
        varEnv = initialVarEnv,
        strEnv = initialStrEnv,
        sigEnv = SEnv.empty,
        funEnv = SEnv.empty
      } : TypeContext.context

  val initialTopTypeContext =
      {
       strEnv = SEnv.singleton
                  (
                   P.topStrName,
                   TY.STRUCTURE
                     {
                      id = P.topStrID,
                      name = P.topStrName,
                      strpath = P.NilPath,
                      env = (SE.initialTyConEnv, initialVarEnv, SEnv.empty)
                      }
                     ),
        sigEnv = SEnv.empty,
        funEnv = SEnv.empty
      } : topTypeContext

  local
    structure OCord : ordsig =
      struct
        fun compare (Absyn.INT _, Absyn.INT _)       = EQUAL
          | compare (Absyn.INT _, _)                 = LESS
          | compare (Absyn.WORD _, Absyn.INT _)      = GREATER
          | compare (Absyn.WORD _, Absyn.WORD _)     = EQUAL
          | compare (Absyn.WORD _, _)                = LESS
          | compare (Absyn.STRING _, Absyn.INT _)    = GREATER
          | compare (Absyn.STRING _, Absyn.WORD _)   = GREATER
          | compare (Absyn.STRING _, Absyn.STRING _) = EQUAL
          | compare (Absyn.STRING _,  _)             = LESS
          | compare (Absyn.REAL _, Absyn.CHAR _)     = LESS
          | compare (Absyn.REAL _, Absyn.REAL _)     = EQUAL
          | compare (Absyn.REAL _, _)                = GREATER
          | compare (Absyn.CHAR _, Absyn.CHAR _)     = EQUAL
          | compare (Absyn.CHAR _, _)                = GREATER
        type ord_key = Absyn.constant
      end
    structure OCMap = BinaryMapFn(OCord)
    val constantTypeDefs =
      [
       (Absyn.INT (0,Loc.noloc),  "['a#{int,largeInt}.'a]"),
       (Absyn.WORD (0w0,Loc.noloc), "['a#{word,largeWord,byte}.'a]"),
       (Absyn.STRING ("",Loc.noloc), "string"),
       (Absyn.REAL ("0.0",Loc.noloc), "real"),
       (Absyn.CHAR (#"c",Loc.noloc),  "char")
       ]
    val constantTypeMap =
        foldl
        (fn ((const, tyRep), constTypeMap) =>
         OCMap.insert(constTypeMap, const, TP.readTy tyRep))
        OCMap.empty
        constantTypeDefs
  in
    fun constTy const =
      case OCMap.find(constantTypeMap, const) of
        SOME ty => ty
      | _ => raise (Control.Bug "InitialTypeContext constTy")
  end
       
  fun extendTopTypeContextWithContext 
        ({
         strEnv = topStrEnv, 
         sigEnv = topSigEnv, 
         funEnv = topFunEnv
         } : topTypeContext
        )
        
        {
         strEnv = newStrEnv, 
         varEnv = newVarEnv, 
         tyConEnv  =  newTyConEnv, 
         sigEnv = newSigEnv,  
         funEnv = newFunEnv
         } =
      let
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
        fun injectStrEnvToTop strEnv = 
            SEnv.map
                (fn (TY.STRUCTURE {id, name, strpath, env = (TE, VE, SE)}) => 
                    TY.STRUCTURE
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
                strEnv
        val newTopStrEnv =
            SEnv.singleton
                (
                  P.topStrName,
                  TY.STRUCTURE
                      {
                        id = P.topStrID,
                        name = P.topStrName,
                        strpath = P.NilPath,
                        env = 
                        (
                          injectTyConEnvToTop newTyConEnv,
                          injectVarEnvToTop newVarEnv,
                          injectStrEnvToTop newStrEnv
                        )
                      }
                )
        fun extendStrEnvEntry
                (
                  TY.STRUCTURE {id, name, strpath, env = (TE1, VE1, SE1)},
                  TY.STRUCTURE {env = (TE2, VE2, SE2), ...}
                ) =
            TY.STRUCTURE
                {
                  id = id,
                  name = name,
                  strpath = strpath,
                  env =
                  (
                    SEnv.unionWith #1 (TE1, TE2),
                    SEnv.unionWith #1 (VE1, VE2),
                    SEnv.unionWith #1 (SE1, SE2)
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
        {
          strEnv = SEnv.unionWith extendStrEnvEntry (newTopStrEnv, topStrEnv),
          sigEnv = SEnv.unionWith #1 (newSigEnv, topSigEnv),
          funEnv = SEnv.unionWith #1 (newFunEnv, topFunEnv)
        }
      end

end
end
