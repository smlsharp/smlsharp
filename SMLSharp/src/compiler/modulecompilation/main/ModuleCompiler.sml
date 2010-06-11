(**
 * module compiler flattening
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompiler.sml,v 1.148 2008/08/24 03:54:41 ohori Exp $
 *)
structure ModuleCompiler : MODULE_COMPILER = struct
local
  structure PC =  PatternCalc
  structure PCF = PatternCalcFlattened
  structure A = Absyn
  structure C = Control
  structure NM = NameMap
  structure E = ModuleCompilationError
  structure UE = UserError
  structure NPEnv = NM.NPEnv
in
  fun constructDummyPath longStrName =
      foldl (fn (strName, strPath) => Path.appendUsrPath(strPath, strName))
            Path.NilPath
            longStrName

  fun constructDummyNamePath longid =
      let
        fun con nil path =
            raise Control.Bug (Absyn.longidToString(longid)^" is nil")
          | con (h::nil) path = (h, path)
          | con (h::t) path = con t (Path.appendUsrPath(path, h))
      in
        con longid Path.NilPath
      end
    
  fun constructDataCon prefix dataCon = 
      SEnv.mapi
        (fn (varName, idstate) =>
            case idstate of
              NM.VARID _ => raise Control.Bug "VARID appear in datatype"
            | NM.EXNID _ => raise Control.Bug "EXNID appear in datatype"
            | NM.CONID _ =>
              (NM.CONID (varName, prefix)))
        dataCon

(****************************************************************************)

  fun compileOpenVarNameMap nameContext loc varNameMap = 
      SEnv.foldli
        (fn (varName, idstate, (flattenedVarNamePathEnv, newVarNameMap)) =>
            case idstate of
              NM.VARID (namePath as (name, prefix)) =>
              (NPEnv.insert(flattenedVarNamePathEnv,
                            NM.constructNamePath nameContext varName,
                            idstate),
               SEnv.insert(newVarNameMap, 
                           varName, 
                           NM.VARID (varName, #strLevel nameContext)))
            | NM.CONID _ => 
              (NPEnv.insert(flattenedVarNamePathEnv,
                            NM.constructNamePath nameContext varName,
                            idstate),
               SEnv.insert(newVarNameMap, 
                           varName, 
                           NM.CONID (varName, #strLevel nameContext)))
            | NM.EXNID (name, prefix) => 
              (NPEnv.insert(flattenedVarNamePathEnv,
                            NM.constructNamePath nameContext varName,
                            idstate),
               SEnv.insert(newVarNameMap, 
                           varName, 
                           NM.EXNID (varName, #strLevel nameContext))))
        (NPEnv.empty, SEnv.empty)
      varNameMap

  fun compileOpenTyNameMap nameContext loc tyNameMap =
      SEnv.foldli
        (fn (tyName, tyState, (tyNamePathEnv, newTyNameMap)) =>
            case tyState of
              NM.DATATY ((name, prefix), dataCon) =>
              let
                val leftConNameMap =
                    constructDataCon (#strLevel nameContext) dataCon
              in
                (NPEnv.insert
                   (tyNamePathEnv, 
                    NM.constructNamePath nameContext tyName, 
                    tyState),
                 SEnv.insert
                   (newTyNameMap, 
                    tyName,
                    NM.DATATY((tyName, #strLevel nameContext), 
                              leftConNameMap)))
              end
            | NM.NONDATATY (name, prefix) => 
              (NPEnv.insert
                 (tyNamePathEnv,
                  NM.constructNamePath nameContext tyName, 
                  tyState),
               SEnv.insert
                 (newTyNameMap,
                  tyName,
                  NM.NONDATATY (NM.constructNamePath nameContext tyName)))
        )
        (NPEnv.empty, SEnv.empty)
        tyNameMap
                   
  fun compileOpenStrNameMap nameContext loc strNameMap =
      SEnv.foldli
        (fn (strName, 
             NM.NAMEAUX 
               {
                name,
                wrapperSysStructure,
                parentPath, 
                basicNameMap = (tyNameMap, varNameMap, strNameMap)
               },
             ((flattenedTyNamePathEnv, flattenedVarNamePathEnv),
              newStrNameMap))
            =>
            let
              val newParentPath = 
                  NM.joinPathWithWrapper
                    (#strLevel nameContext)
                    wrapperSysStructure
              val newStrLevel = 
                  let
                    val tempStrLevel =
                        NM.appendStrLevel 
                          (#strLevel nameContext, (strName, NM.USR))
                  in
                    case wrapperSysStructure of
                      NONE => tempStrLevel
                    | SOME name => 
                      NM.appendStrLevel
                        (
                         NM.joinPathWithWrapper (#strLevel nameContext) 
                                                wrapperSysStructure,
                         (strName, NM.USR))
                  end
              val newNameContext = 
                  NM.updateStrLevel (nameContext, newStrLevel)
              val (flattenedTyNamePathEnv1, newTyNameMap1) = 
                  compileOpenTyNameMap newNameContext 
                                       loc
                                       tyNameMap
              val (flattenedVarNamePathEnv1, newVarNameMap1) =
                  compileOpenVarNameMap newNameContext 
                                        loc
                                        varNameMap
              val ((flattenedTyNamePathEnv2, flattenedVarNamePathEnv2), 
                   newStrNameMap1) =
                  compileOpenStrNameMap newNameContext
                                        loc
                                        strNameMap
            in
              (
               (NM.mergeNamePathEnvs [flattenedTyNamePathEnv,
                                      flattenedTyNamePathEnv1, 
                                      flattenedTyNamePathEnv2],
                NM.mergeNamePathEnvs [flattenedVarNamePathEnv,
                                      flattenedVarNamePathEnv1, 
                                      flattenedVarNamePathEnv2]),
               SEnv.insert
                 (newStrNameMap,
                  strName,
                  NM.NAMEAUX 
                    {
                     name = name,
                     wrapperSysStructure = wrapperSysStructure,
                     parentPath = newParentPath, 
                     basicNameMap = (newTyNameMap1,
                                     newVarNameMap1,
                                     newStrNameMap1)
                    }
                 )
              )
            end)
        ((NPEnv.empty, NPEnv.empty), SEnv.empty)
        strNameMap

  and compileOpen nameContext loc (tyNameMap, varNameMap, strNameMap) =
      let
        val (flattenedTyNamePathEnv1, newTyNameMap) = 
            compileOpenTyNameMap nameContext loc  tyNameMap
        val (flattenedVarNamePathEnv1, newVarNameMap) =
            compileOpenVarNameMap nameContext loc varNameMap
        val ((flattenedTyNamePathEnv2, flattenedVarNamePathEnv2),
             newStrNameMap) =
            compileOpenStrNameMap nameContext loc strNameMap
      in
        ((NM.mergeNamePathEnvs [flattenedTyNamePathEnv1,
                                flattenedTyNamePathEnv2],
          NM.mergeNamePathEnvs [flattenedVarNamePathEnv1,
                                flattenedVarNamePathEnv2]),
         (newTyNameMap, newVarNameMap, newStrNameMap))
      end

  (*************************************************************************)
  fun adjustPrefixVarNameMap strLevel varNameMap = 
      SEnv.foldli
        (fn (varName, idstate, newVarNameMap) =>
            case idstate of
              NM.VARID (name, prefix) =>
              SEnv.insert(newVarNameMap, 
                          varName, 
                          NM.VARID (varName, strLevel))
            | NM.CONID _ => 
              SEnv.insert(newVarNameMap, 
                          varName, 
                          NM.CONID (varName, strLevel))
            | NM.EXNID (name, prefix) => 
              SEnv.insert(newVarNameMap, 
                          varName, 
                          NM.EXNID (varName, strLevel)))
        SEnv.empty
        varNameMap

  fun adjustPrefixDataCon (strLevel, dataCon) = 
      SEnv.mapi
        (fn (varName, idstate) =>
            case idstate of
              NM.VARID _ => raise Control.Bug "VARID appear in datatype"
            | NM.EXNID _ => raise Control.Bug "EXNID appear in datatype"
            | NM.CONID _ =>
              (NM.CONID (varName, strLevel)))
        dataCon

  fun adjustPrefixTyNameMap strLevel tyNameMap =
      SEnv.foldli
        (fn (tyName, tyState, newTyNameMap) =>
            case tyState of
              NM.DATATY ((name, prefix), dataCon) =>
              let
                val leftConNameMap = adjustPrefixDataCon (strLevel, dataCon)
              in
                SEnv.insert(newTyNameMap, 
                            tyName,
                            NM.DATATY((tyName, strLevel), 
                                      leftConNameMap))
              end
            | NM.NONDATATY (name, prefix) => 
              SEnv.insert(newTyNameMap,
                          tyName,
                          NM.NONDATATY (tyName, strLevel))
        )
        SEnv.empty
        tyNameMap
                   
  fun adjustPrefixStrNameMap strLevel strNameMap =
      SEnv.foldli
        (fn (strName, 
             NM.NAMEAUX
               {name, wrapperSysStructure, parentPath, 
                basicNameMap = (tyNameMap, varNameMap, strNameMap)},
             newStrNameMap) =>
            let
              val newStrLevel = 
                  case wrapperSysStructure of 
                    NONE => NM.appendStrLevel (strLevel, (strName, NM.USR))
                  | SOME (sysName) => 
                    NM.appendStrLevel
                      (NM.appendStrLevel (strLevel, (sysName, NM.SYS)),
                       (name, NM.USR))
              val newTyNameMap1 = 
                  adjustPrefixTyNameMap newStrLevel tyNameMap
              val newVarNameMap1 =
                  adjustPrefixVarNameMap newStrLevel varNameMap
              val newStrNameMap1 =
                  adjustPrefixStrNameMap newStrLevel strNameMap
            in
              SEnv.insert(newStrNameMap, 
                          strName, 
                          NM.NAMEAUX 
                            {
                             name = name,
                             wrapperSysStructure = wrapperSysStructure,
                             parentPath = strLevel,
                             basicNameMap = (newTyNameMap1,
                                             newVarNameMap1,
                                             newStrNameMap1)
                            }
                         )
            end)
        SEnv.empty
        strNameMap

  fun adjustPrefixBasicNameMap strLevel (tyNameMap, varNameMap, strNameMap) =
      let
        val newTyNameMap = 
            adjustPrefixTyNameMap strLevel tyNameMap
        val newVarNameMap =
            adjustPrefixVarNameMap strLevel varNameMap
        val newStrNameMap =
            adjustPrefixStrNameMap strLevel strNameMap
      in
        (newTyNameMap, newVarNameMap, newStrNameMap)
      end

  fun fixPrefixDataCons (prefix, datacon) =
      SEnv.map
        (fn NM.CONID (name, _) => NM.CONID (name, prefix)
          | NM.VARID (namePath) => 
            raise
              Control.Bug
                ((NM.namePathToString namePath)^" is constructor")
          | NM.EXNID (namePath) => 
            raise
              Control.Bug
                ((NM.namePathToString namePath)^" is constructor"))
        datacon

  fun constrainTyNameMap (richTyNameMap, strictTyNameMap) loc =
      SEnv.foldli
        (fn (tyName, strictTyInfo, newTyNameMap) =>
            case strictTyInfo of
              NM.DATATY ((name, prefix), varNameMap) =>
              (case SEnv.find(richTyNameMap, tyName) of
                 NONE => 
                 (E.enqueueError
                    (loc, 
                     E.SigMisMatchNotFoundDataTy({name = tyName}));
                  newTyNameMap)
               | SOME (richTyInfo as (NM.DATATY _)) => 
                 SEnv.insert(newTyNameMap, tyName, richTyInfo)
               | SOME (richTyInfo as (NM.NONDATATY x)) =>
                 SEnv.insert(newTyNameMap, tyName, richTyInfo))
            | NM.NONDATATY _ =>
              (case SEnv.find(richTyNameMap, tyName) of
                 NONE => 
                 (E.enqueueError
                    (loc, 
                     E.SigMisMatchNotFoundDataTy({name = tyName}));
                  newTyNameMap)
               | SOME (NM.DATATY ((name, prefix), _)) => 
                 SEnv.insert(newTyNameMap, 
                             tyName,
                             NM.NONDATATY (name, prefix))
               | SOME (NM.NONDATATY (name, prefix)) =>
                 SEnv.insert
                   (newTyNameMap, tyName, NM.NONDATATY (name, prefix))))
        SEnv.empty
        strictTyNameMap

  fun constrainVarNameMap (richVarNameMap, strictVarNameMap) loc =
      SEnv.foldli
        (fn (varName, strictVarInfo, newVarNameMap) =>
            case SEnv.find(richVarNameMap, varName) of
              NONE => 
              let
                val err = 
                    case strictVarInfo of
                      NM.CONID _ => E.SigMisMatchNotFoundCon({name = varName})
                    | NM.EXNID _ => E.SigMisMatchNotFoundExn({name = varName})
                    | NM.VARID _ => E.SigMisMatchNotFoundVar({name = varName})
              in
                (E.enqueueError (loc, err);
                 newVarNameMap)
              end
            | SOME richVarInfo => 
              SEnv.insert(newVarNameMap, varName, richVarInfo))
        SEnv.empty
        strictVarNameMap

  and constrainStrNameMapEntry 
        ((richEntry
            as
            NM.NAMEAUX
            {
             basicNameMap = (tm, vm, sm),
             name,
             wrapperSysStructure,
             parentPath, ...
            }
         ),
         (strictEntry
            as (NM.NAMEAUX {basicNameMap=(tm', vm', sm'),...}))
        )
        loc
        =
        let
          val newTm = constrainTyNameMap (tm, tm') loc
          val newVm = constrainVarNameMap (vm, vm') loc
          val newSm = constrainStrNameMap (sm, sm') loc
        in
          NM.NAMEAUX {name = name,
                      wrapperSysStructure = wrapperSysStructure,
                      parentPath = parentPath,
                      basicNameMap = (newTm, newVm, newSm)}
        end
       
  and constrainStrNameMap (richStrNameMap, strictStrNameMap) loc =
      SEnv.foldli
        (fn (strName, strictEntry, newStrNameMap) =>
            case SEnv.find(richStrNameMap, strName) of
              NONE => 
              (E.enqueueError 
                 (loc, E.SigMisMatchNotFoundStr({name = strName}));
               newStrNameMap)
            | SOME richEntry =>
              SEnv.insert(newStrNameMap, 
                          strName, 
                          constrainStrNameMapEntry
                            (richEntry, strictEntry)
                            loc
                         )
        )
        SEnv.empty
        strictStrNameMap
                   
  fun constrainBasicNameMap
        {rich = (richTyNameMap, richVarNameMap, richStrNameMap), 
         strict = (strictTyNameMap, strictVarNameMap, strictStrNameMap)}
        loc =
      let
        val tyNameMap = constrainTyNameMap (richTyNameMap, strictTyNameMap) loc
        val varNameMap =
            constrainVarNameMap (richVarNameMap, strictVarNameMap) loc
        val strNameMap =
            constrainStrNameMap (richStrNameMap, strictStrNameMap) loc
      in
        (tyNameMap, varNameMap, strNameMap)
      end

  fun constrainFunNameMap
        {rich : NameMap.funNameMap, strict : NameMap.funNameMap} loc =
      SEnv.foldli
        (fn (funName,
             {arg = strictArg, body = strictBody}, newFunNameMap)
            =>
            case SEnv.find(rich, funName) of
              NONE => 
              (E.enqueueError 
                 (loc, E.InterfaceMisMatchNotFoundFunctor ({name = funName}));
               newFunNameMap)
            | SOME ({arg = richArg, body = richBody}) =>
              let
                (* contravariant in functor domain *)
                val newArg =
                    constrainBasicNameMap
                      {rich = strictArg, strict = richArg} loc
                val newBody =
                    constrainStrNameMapEntry (richBody, strictBody) loc
              in
                SEnv.insert(newFunNameMap,
                            funName,
                            {arg = newArg, body = newBody}
                           )
              end)
        SEnv.empty
        strict
       
  fun constrainBasicInterfaceNameMap
        {rich : NameMap.basicInterfaceNameMap,
         strict : NameMap.basicInterfaceNameMap}
        loc =
      let
        val basicNameMap =
            constrainBasicNameMap {rich = #1 rich, strict = #1 strict} loc
        val funNameMap =
            constrainFunNameMap {rich = #2 rich, strict = #2 strict} loc
      in
        (basicNameMap, funNameMap)
      end

  (*************************************************)
  val NAME_OF_ACTUAL_FUNCTOR_ARG ="X?"

  fun nameAnonymousActualFunctorArg strExp =
      let
        datatype sigExpSeq = 
                 NONSIG 
               | TRANS of (PC.plsigexp * sigExpSeq) 
               | OPAQUE of (PC.plsigexp * sigExpSeq)

        fun patchSig (strexp, loc) sigExpSeq =
            (case sigExpSeq of
               NONSIG => strexp
             | TRANS (plsigexp, rem) =>
               patchSig
                 (PC.PLSTRTRANCONSTRAINT(strexp, plsigexp, loc), loc)
                 rem
             | OPAQUE (plsigexp, rem) =>
               patchSig
                 (PC.PLSTROPAQCONSTRAINT(strexp, plsigexp, loc), loc) rem)

        fun impl strExp sigExpSeq =
            case strExp of
              PC.PLSTREXPBASIC (_, loc) => 
              {
               localPart = [PC.PLSTRUCTBIND
                              ([(NAME_OF_ACTUAL_FUNCTOR_ARG, 
                                 patchSig (strExp, loc) sigExpSeq)], 
                               loc)],
               namePart = [NAME_OF_ACTUAL_FUNCTOR_ARG]
              }
            | PC.PLSTRID(strNames, loc) =>
              (case sigExpSeq of 
                 NONSIG => {localPart = nil, namePart = strNames}
               | any => {localPart = [PC.PLSTRUCTBIND
                                        ([(Absyn.longidToString strNames, 
                                           patchSig (strExp, loc) sigExpSeq)],
                                         loc)
                                     ],
                         namePart = [Absyn.longidToString strNames]})
            | PC.PLSTRTRANCONSTRAINT(strExp', sigExp, loc) => 
              impl strExp' (TRANS (sigExp, sigExpSeq))
            | PC.PLSTROPAQCONSTRAINT(strExp', sigExp, loc) => 
              impl strExp' (OPAQUE (sigExp, sigExpSeq))
            | PC.PLFUNCTORAPP(_, _ , loc) =>
              {localPart = [PC.PLSTRUCTBIND
                              ([(NAME_OF_ACTUAL_FUNCTOR_ARG, 
                                 patchSig (strExp, loc) sigExpSeq)],
                               loc)
                           ],
               namePart = [NAME_OF_ACTUAL_FUNCTOR_ARG]}
            | PC.PLSTRUCTLET(strDecs, strExp', loc) =>
              let
                val {localPart, namePart} = impl strExp' sigExpSeq
              in
                {localPart = strDecs @ localPart,
                 namePart = namePart}
              end
      in
        impl strExp NONSIG
      end


  fun abstractTyNameMapInNameMap (nameMap : NM.currentNameMap) =
      SEnv.map
        (fn NM.DATATY ((name, prefix), _) =>
            NM.DATATY((name, prefix), SEnv.empty)
          | NM.NONDATATY (name, prefix) => NM.NONDATATY (name, prefix))
        (#tyNameMap nameMap)

   (*
    * The difference between Absyn.ty and PCF.ty is that string list of
    * TYCONSTRUCT is compiled into namePath.
    *)
  fun compileTy (nameContext:NM.nameContext) ty =
      case ty of
        A.TYID x => A.TYID x
      | A.TYRECORD (labelTys, loc) => 
        let
          val newLabelTys =
              map (fn (label, rawTy) => (label, compileTy nameContext rawTy))
                  labelTys
        in
          A.TYRECORD (newLabelTys, loc)
        end
      | A.TYCONSTRUCT (argTys, names, loc) =>
        let
          val newArgTys = map (compileTy nameContext) argTys
          val newLongName  =
              case NM.lookupTy (nameContext, names) of
                (_, NONE) => 
                (E.enqueueError 
                   (loc, 
                    E.TyConNotFound({name = Absyn.longidToString(names)}));
                 constructDummyNamePath names)
              | (_, SOME (NM.DATATY(namePath, _))) => namePath
              | (_, SOME (NM.NONDATATY namePath)) => namePath
        in
          A.TYCONSTRUCT_WITH_NAMEPATH (newArgTys, newLongName, loc)
        end
      | A.TYCONSTRUCT_WITH_NAMEPATH (argTys, names, loc) => 
        raise Control.Bug "TYCONSTRUCT_WITH_NAMEPATH in module compile"
      | A.TYTUPLE (tys, loc) =>
        A.TYTUPLE (map (compileTy nameContext) tys, loc)
      | A.TYFUN (ty1, ty2, loc) => A.TYFUN (compileTy nameContext ty1, 
                                            compileTy nameContext ty2, 
                                            loc)
      | A.TYFFI (attributes, attrs, domTys, ranTy, loc) => 
        A.TYFFI (attributes, attrs,
                 map (compileTy nameContext) domTys,
                 compileTy nameContext ranTy, 
                 loc)
      | A.TYPOLY (kindedTvarList, ty, loc) => 
        A.TYPOLY (compileKindedTvarList nameContext kindedTvarList,
                  compileTy nameContext  ty,
                  loc)
           
  and compileTvarKind nameContext tvarKind =
      case tvarKind of
        A.UNIV => A.UNIV
      | A.REC stringTyList => 
        A.REC ((map (fn (l,ty) =>
                        (l, compileTy nameContext ty))) stringTyList)

  and compileKindedTvar nameContext (tvar, tvarKind) =
      (tvar, compileTvarKind nameContext tvarKind)

  and compileKindedTvarList nameContext kindedTvarList =
      map (compileKindedTvar nameContext) kindedTvarList

  fun compileTyOpt nameContext tyOpt =
      case tyOpt of
        NONE => NONE
      | SOME ty => SOME (compileTy nameContext ty)

  fun compileExpList nameContext plexpList =
      foldr 
        (fn (plexp, newPlexpList) =>
            let
              val newPlexp = compileExp nameContext plexp
            in
              (newPlexp :: newPlexpList)
            end)
        nil
        plexpList

  and compileExp nameContext exp = 
      case exp of
        PC.PLCONSTANT (constant , loc) => PCF.PLFCONSTANT(constant, loc)
      | PC.PLGLOBALSYMBOL (name,kind,loc) => PCF.PLFGLOBALSYMBOL(name,kind,loc)
      | PC.PLVAR (names , loc) => 
        (case NM.lookupVar(nameContext, names) of
           (_, SOME (NM.CONID namePath)) => PCF.PLFVAR (namePath, loc)
         | (_, SOME (NM.VARID namePath)) => PCF.PLFVAR (namePath, loc)
         | (_, SOME (NM.EXNID namePath)) => PCF.PLFVAR (namePath, loc)
         | (_, NONE) => 
           (E.enqueueError 
              (loc, 
               E.VarNotFound({name = Absyn.longidToString(names)}));
            PCF.PLFVAR (constructDummyNamePath names, loc)))
      | PC.PLTYPED (plexp ,  ty , loc) =>
        let 
          val ptexp = compileExp nameContext plexp
          val newTy = compileTy nameContext ty
        in
          PCF.PLFTYPED (ptexp, newTy, loc)
        end
      | PC.PLAPPM (plexp , plexpList , loc) => 
        let 
          val ptexp = compileExp nameContext plexp
          val ptexpList = compileExpList nameContext plexpList 
        in
          PCF.PLFAPPM (ptexp , ptexpList , loc)
        end
      | PC.PLLET (pdeclList , plexpList , loc) => 
        let 
(*
          val newNameContext = 
              NM.updateStrLevel (nameContext, Path.NilPath)
*)
          val (newPdeclList, nameMap) = 
              compileDeclList nameContext pdeclList
          val newNameContext = 
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext, 
                 nameMap = nameMap}
          val newPlexps = 
              foldr (fn (plexp, plexps) => 
                        let
                          val newPlexp = compileExp newNameContext plexp
                        in
                          newPlexp :: plexps
                        end)
                    nil
                    plexpList
        in
          PCF.PLFLET (newPdeclList, newPlexps, loc)
        end
      | PC.PLRECORD (stringPlexpList, loc) => 
        let
          val fields = 
              foldr (fn ((l, plexp), binds) =>
                        let
                          val newPlexp = 
                              compileExp nameContext plexp
                        in
                          (l, newPlexp) :: binds
                        end)
                    nil
                    stringPlexpList
        in
          PCF.PLFRECORD (fields, loc)
        end
      | PC.PLRECORD_UPDATE (plexp, stringPlexpList, loc) => 
        let
          val newPlexp = compileExp nameContext plexp
          val fields = 
              foldr (fn ((l, plexp), binds) =>
                        let 
                          val newPlexp = compileExp nameContext plexp
                        in
                          (l, newPlexp) :: binds
                        end)
                    nil
                    stringPlexpList
        in
          PCF.PLFRECORD_UPDATE (newPlexp, fields, loc)
        end
      | PC.PLTUPLE (plexpList , loc) => 
        let
          val newPlexpList = 
              foldr (fn (plexp, newPlexpList) => 
                        let
                          val newPlexp = compileExp nameContext plexp
                        in
                          newPlexp :: newPlexpList
                        end)
                    nil
                    plexpList
        in
          PCF.PLFTUPLE(newPlexpList, loc)
        end
      | PC.PLLIST (plexpList , loc) => 
        let
          val newPlexpList = 
              foldr (fn (plexp, newPlexpList) => 
                        let
                          val newPlexp = compileExp nameContext plexp
                        in
                          newPlexp :: newPlexpList
                        end)
                    nil
                    plexpList
        in
          PCF.PLFLIST(newPlexpList, loc)
        end
      | PC.PLRAISE (plexp, loc) => 
        let 
          val newPlexp = compileExp nameContext plexp
        in
          PCF.PLFRAISE (newPlexp , loc)
        end
      | PC.PLHANDLE (plexp, plpatPlexpList, loc) => 
        let 
          val newPlexp = compileExp nameContext plexp
          val newPlpatPlexpList = 
              foldr
                (fn ((plpat, plexp1), newPlrules) =>
                    let
                      val (newPlpat, varNameMap) = 
                          compilePat nameContext plpat
                      val newNameContext = 
                          NM.extendNameContextWithCurrentNameMap
                            {nameContext = nameContext,
                             nameMap = NM.injectVarNameMapInNameMap varNameMap}
                      val newPlexp1 = compileExp newNameContext plexp1
                    in 
                      (newPlpat, newPlexp1) :: newPlrules
                    end)
                nil
                plpatPlexpList
        in
          PCF.PLFHANDLE (newPlexp, newPlpatPlexpList, loc)
        end
      | PC.PLFNM (plpatListPlexpList , loc) => 
        let 
          val newPlrules = 
              foldr
                (fn ((plpatList, plexp), plrules) =>
                    let
                      val (newPlpatList, varNameMap) = 
                          compilePatList nameContext plpatList
                      val newNameContext =
                          NM.extendNameContextWithCurrentNameMap
                            {nameContext = nameContext,
                             nameMap = NM.injectVarNameMapInNameMap varNameMap}
                      val newPlexp = compileExp newNameContext plexp
                    in
                      (newPlpatList, newPlexp) :: plrules
                    end)
                nil
                plpatListPlexpList
        in
          PCF.PLFFNM  (newPlrules, loc)
        end
      | PC.PLCASEM (plexpList,  plpatListPlexpList, caseKind, loc) => 
        let 
          val newPlexpList = compileExpList nameContext plexpList
          val plrules = 
              foldr
                (fn ((plpatList, plexp1), plrules) =>
                    let
                      val (newPlpatList, varNameMap) = 
                          compilePatList nameContext plpatList
                      val newNameContext =
                          NM.extendNameContextWithCurrentNameMap
                            {nameContext = nameContext,
                             nameMap = NM.injectVarNameMapInNameMap varNameMap}
                      val newPlexp1 = compileExp newNameContext plexp1
                    in
                      (newPlpatList, newPlexp1) :: plrules
                    end)
                nil
                plpatListPlexpList
        in
          PCF.PLFCASEM (newPlexpList, plrules, caseKind, loc)
        end
      | PC.PLRECORD_SELECTOR (string , loc) =>
        PCF.PLFRECORD_SELECTOR (string , loc)
      | PC.PLSELECT (string, plexp, loc) => 
        let 
          val newPlexp = compileExp nameContext plexp
        in
          PCF.PLFSELECT (string , newPlexp , loc)
        end
      | PC.PLSEQ (plexpList, loc) => 
        let
          val newPlexpList = 
              foldr (fn (plexp, plexps) => 
                        let
                          val newPlexp = compileExp nameContext plexp
                        in
                          newPlexp :: plexps
                        end)
                    nil
                    plexpList
        in
          PCF.PLFSEQ(newPlexpList, loc)
        end
      | PC.PLCAST (plexp , loc) => 
        let 
          val newPlexp = compileExp nameContext plexp
        in
          PCF.PLFCAST (newPlexp, loc)
        end
      | PC.PLFFIIMPORT (plexp, ty, loc) =>
        let
          val newPlexp = compileExp nameContext plexp
          val newTy = compileTy nameContext ty
        in
          PCF.PLFFFIIMPORT(newPlexp, newTy, loc)
        end
      | PC.PLFFIEXPORT (plexp, ty, loc) =>
        let
          val newPlexp = compileExp nameContext plexp
          val newTy = compileTy nameContext ty
        in
          PCF.PLFFFIEXPORT(newPlexp, newTy, loc) 
        end
      | PC.PLFFIAPPLY (callingConvention, plexp, ffiArgList, ty, loc) =>
        let
          val newPlexp = compileExp nameContext plexp
          val newFfiArgList = map (compileFfiArg nameContext) ffiArgList
          val newTy = compileTy nameContext ty
        in
          PCF.PLFFFIAPPLY(callingConvention,
                          newPlexp,
                          newFfiArgList,
                          newTy,
                          loc)
        end

  and compileFfiArg nameContext ffiArg = 
      case ffiArg of
        PC.PLFFIARG (plexp, ty, loc) =>
        let
          val newPlexp = compileExp nameContext plexp
          val newTy = compileTy nameContext ty
        in
          PCF.PLFFFIARG (newPlexp, newTy, loc)
        end
      | PC.PLFFIARGSIZEOF (ty, plexpOpt, loc) =>
        let
          val newTy = compileTy nameContext ty
          val newPlexpOpt = Option.map (compileExp nameContext) plexpOpt
        in
          PCF.PLFFFIARGSIZEOF (newTy, newPlexpOpt, loc)
        end
               
  and compileDatatypes nameContext datatypes =
      let
        val newNameContext =
            let
              val tyNameMap =
                  foldl
                    (fn ((_, tyName, _), 
                         tyNameMap) =>
                        SEnv.insert
                          (tyNameMap,
                           tyName, 
                           NM.DATATY((tyName, #strLevel nameContext),
                                     SEnv.empty)))
                    SEnv.empty
                    datatypes
            in
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext,
                 nameMap = NM.injectTyNameMapInNameMap tyNameMap}
            end
      in
        foldl
          (fn ((tvars, tyName:string, constructors), 
               (nameMap, newDatatypes)) =>
              let
                val tyNameMap = SEnv.singleton
                                  (tyName, 
                                   NM.DATATY
                                     ((tyName, #strLevel nameContext),
                                      SEnv.empty))
                val (newConstructors, varNameMap) =
                    foldl
                      (fn ((bool, constructorName, tyOpt), 
                           (newConstructors, varNameMap)) =>
                          let
                            val newTyOpt =
                                compileTyOpt newNameContext tyOpt
                          in
                            (newConstructors @ 
                             [(bool, 
                               constructorName,
                               newTyOpt)],
                             SEnv.insert(varNameMap, 
                                         constructorName,
                             (* if isAbsType then                                                                 NM.CONID (constructorName, Path.NilPath)
                                else
                              *)
                             NM.CONID (constructorName, 
                                       #strLevel nameContext)
                                        )
                            )
                          end)
                      (nil, SEnv.empty)
                      constructors
                val newTyNameMap =
                    SEnv.singleton(tyName, 
                                   NM.DATATY((tyName, #strLevel nameContext),
                                             varNameMap))
              in
                (NM.mergeCurrentNameMap
                   {old = nameMap,
                    new = NM.mergeCurrentNameMap 
                            {old = NM.injectTyNameMapInNameMap newTyNameMap,
                             new = NM.injectVarNameMapInNameMap varNameMap}},
                 newDatatypes @ 
                 [(tvars,
                   (tyName, #strLevel nameContext), 
                   newConstructors)])
              end)
          (NM.emptyCurrentNameMap, nil)
          datatypes
      end

  and compileDec (nameContext:NM.nameContext) pdecl = 
      case pdecl of
        PC.PDVAL (kindedTvarList, plpatPlexpList, loc ) => 
        let 
          val kindedTvarList =
              compileKindedTvarList nameContext kindedTvarList
          val (newPlpatPlexpList, varNameMap) = 
              foldl
                (fn ((plpat, plexp1), (plrules, varNameMap)) =>
                    let
                      val (newPlpat, newVarNameMap) = 
                          compilePat nameContext plpat
                      val newPlexp = compileExp nameContext plexp1
                    in
                      (plrules @ [(newPlpat, newPlexp)],
                       NM.mergeVarNameMap {old = varNameMap,
                                           new = newVarNameMap})
                    end)
                (nil, SEnv.empty)
                plpatPlexpList
        in
          ([PCF.PDFVAL (kindedTvarList, newPlpatPlexpList, loc)], 
           NM.injectVarNameMapInNameMap varNameMap)
        end
      | PC.PDDECFUN (kindedTvarList, plpatPlpatListPlexpListList, loc)  => 
        let
          val kindedTvarList =
              compileKindedTvarList nameContext kindedTvarList
          val varNameMap1 = 
              foldl
                (fn ((funPat, _), varNameMap) =>
                    let
                      val (funpat, varNameMap1) =  
                          compilePat nameContext funPat
                    in
                      NM.mergeVarNameMap {old = varNameMap,
                                          new = varNameMap1}
                    end)
                SEnv.empty
                plpatPlpatListPlexpListList

          val newNameContext = 
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext,
                 nameMap = NM.injectVarNameMapInNameMap varNameMap1}

          val newPlpatPlpatListPlexpListList =
              foldl
                (fn ((funPat, plpatListPlexpList),
                     newPlpatPlpatListPlexpListList)
                    =>
                    let
                      val (plFunPat, varNameMap1) = 
                          compilePat nameContext funPat
                      val plruleMList = 
                          foldr
                            (fn ((plpatList, plexp), plruleMList) =>
                                let
                                  val (newPatList, varNameMap) = 
                                      compilePatList newNameContext plpatList
                                  val newNameContext1 =
                                      NM.extendNameContextWithCurrentNameMap
                                        {nameContext = newNameContext,
                                         nameMap = 
                                         NM.injectVarNameMapInNameMap
                                           varNameMap
                                        }
                                  val newPlexp =
                                      compileExp newNameContext1 plexp
                                in 
                                  (newPatList, newPlexp) :: plruleMList
                                end)
                            nil
                            plpatListPlexpList
                    in
                      newPlpatPlpatListPlexpListList
                      @ [(plFunPat, plruleMList)]
                    end)
                nil
                plpatPlpatListPlexpListList
        in
          ([PCF.PDFDECFUN
              (kindedTvarList, newPlpatPlpatListPlexpListList, loc)],
           NM.injectVarNameMapInNameMap varNameMap1)
        end
      | PC.PDNONRECFUN (kindedTvarList, (funPat,plpatListPlexpList), loc)  => 
        let
          val kindedTvarList =
              compileKindedTvarList nameContext kindedTvarList
          val (newFunPat, varNameMap) = compilePat nameContext funPat
          val newPlruleMList = 
              foldr
                (fn ((plpatList, plexp), plruleMList) =>
                    let
                      val (newPlpatList, varNameMap) = 
                          compilePatList nameContext plpatList
                      val newNameContext = 
                          NM.extendNameContextWithCurrentNameMap
                            {nameContext = nameContext,
                             nameMap =
                             NM.injectVarNameMapInNameMap varNameMap
                            }
                       val newPlexp = compileExp newNameContext plexp
                    in 
                      (newPlpatList, newPlexp) :: plruleMList
                    end)
                nil
                plpatListPlexpList
        in
          ([PCF.PDFNONRECFUN (kindedTvarList, (newFunPat, newPlruleMList),
                              loc)],
           NM.injectVarNameMapInNameMap varNameMap)
        end
      | PC.PDVALREC (kindedTvarList , plpatPlexpList , loc) => 
        let 
          val kindedTvarList =
              compileKindedTvarList nameContext kindedTvarList
          val (newNameContext, incVarNameMap) =
              let
                val varNameMap =
                    foldl
                      (fn ((plpat, _), varNameMap) =>
                          let
                            val (_, varNameMap1) = 
                                compilePat nameContext plpat
                          in
                            NM.mergeVarNameMap {old = varNameMap,
                                                new = varNameMap1}
                          end)
                      SEnv.empty
                      plpatPlexpList
              in
                (NM.extendNameContextWithCurrentNameMap
                   {nameContext = nameContext,
                    nameMap = NM.injectVarNameMapInNameMap varNameMap},
                 varNameMap)
              end
          val plrules = 
              foldr
                (fn ((plpat, plexp1), plrules) =>
                    let
                      val (newPlpat, varNameMap) = 
                          compilePat newNameContext plpat
                      val newPlexp = compileExp newNameContext plexp1
                    in
                      (newPlpat, newPlexp) :: plrules
                    end)
                nil
                plpatPlexpList
        in
          ([PCF.PDFVALREC (kindedTvarList, plrules, loc)], 
           NM.injectVarNameMapInNameMap incVarNameMap)
        end
      | PC.PDVALRECGROUP (idList, pldecls, loc) =>
        let
          val (ptdecls, _, nameMap) = 
              foldl (fn (pldecl, (newPldecls, nameContext, nameMap)) => 
                        let
                          val (decs1, nameMap1) =
                              compileDec nameContext pldecl
                        in
                          (
                           newPldecls @ decs1,
                           NM.extendNameContextWithCurrentNameMap 
                             {nameContext = nameContext,
                              nameMap = nameMap1},
                           NM.mergeCurrentNameMap {old = nameMap,
                                                   new = nameMap1}
                          )
                        end)
                    (nil, nameContext, NM.emptyCurrentNameMap) 
                    pldecls
        in
          ([PCF.PDFVALRECGROUP (idList, ptdecls, loc)], nameMap)
        end
      | PC.PDTYPE (tvarsNameTyList, loc) =>
         let
           val (newTvarsNameTyList, tyNameMap) =
               foldl
                 (fn ((tyvars, tyName, ty), (tyFuns, tyNameMap)) =>
                     let
                       val newTy = compileTy nameContext ty
                     in
                       (tyFuns @ [(tyvars, 
                                   (tyName, (#strLevel nameContext)),
                                   newTy)],
                        SEnv.insert
                          (tyNameMap, 
                           tyName, 
                           NM.NONDATATY(tyName, #strLevel nameContext)))
                     end)
                 (nil, SEnv.empty)
                 tvarsNameTyList
         in
           ([PCF.PDFTYPE (newTvarsNameTyList, loc)], 
            NM.injectTyNameMapInNameMap tyNameMap)
         end
      | PC.PDDATATYPE (datatypes,loc) =>  
        let
          val (nameMap, newDatatypes) = compileDatatypes nameContext datatypes
        in 
          ([PCF.PDFDATATYPE (#strLevel nameContext, newDatatypes, loc)],
           nameMap)
        end
      | PC.PDABSTYPE (datatypes, pdeclList, loc) =>  
        let
          val (nameMap1, newDatatypes) =
              compileDatatypes nameContext datatypes
          val newNameContext =
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext,
                 nameMap = nameMap1}
          val (newPdeclList, nameMap2) = 
              (compileDeclList newNameContext pdeclList)
          val abstractTyNameMap =
              abstractTyNameMapInNameMap nameMap1
          val newNameMap =
              NM.mergeCurrentNameMap
                {old = NM.injectTyNameMapInNameMap abstractTyNameMap,
                 new = nameMap2}
        in
          ([PCF.PDFABSTYPE
              (#strLevel nameContext,
               newDatatypes,
               newPdeclList, loc)],
           newNameMap)
        end
      | PC.PDREPLICATEDAT (leftName, rightNames, loc) => 
        let
          val (newRightLongName, varNameMap) =
              case NM.lookupTy(nameContext, rightNames) of
                (_, NONE) => 
                (E.enqueueError 
                   (loc, 
                    E.TyConNotFound
                      ({name = Absyn.longidToString(rightNames)}));
                 (constructDummyNamePath rightNames, SEnv.empty))
              | (_, SOME (NM.DATATY (namePath, datacon))) => 
                (namePath,
                 adjustPrefixVarNameMap (#strLevel nameContext) datacon)
              | (_, SOME (NM.NONDATATY namePath)) =>                     
                (namePath, SEnv.empty)
          val nameMap =
              NM.mergeCurrentNameMap
                {old = NM.injectVarNameMapInNameMap varNameMap,
                 new = NM.injectTyNameMapInNameMap 
                         (SEnv.singleton
                            (leftName, 
                             NM.DATATY((leftName, #strLevel nameContext),
                                       varNameMap)))}
        in
          ([PCF.PDFREPLICATEDAT((leftName, #strLevel nameContext),
                                newRightLongName,
                                loc)],
           nameMap)
        end
      | PC.PDEXD (exBinds, loc) =>
        let
          val (newExbinds, varNameMap) =
              foldl
                (fn (exbind, (newExnBinds, varNameMap)) =>
                    case exbind of
                      PC.PLEXBINDDEF (bool, name, tyOpt, loc) =>
                      let
                        val newTyOpt = compileTyOpt nameContext tyOpt
                        val newNamePath =
                            NM.constructNamePath nameContext name
                      in
                        (newExnBinds @ [PCF.PLFEXBINDDEF
                                          (bool, 
                                           newNamePath,
                                           newTyOpt, 
                                           loc)],
                         NM.mergeVarNameMap
                           {old = varNameMap,
                            new = SEnv.singleton
                                    (name, 
                                     NM.EXNID (name, #strLevel nameContext))})
                      end
                    | PC.PLEXBINDREP
                        (bool1, leftName, bool2, rightNames, loc)
                      =>
                      let
                        val newLeftNames =
                            NM.constructNamePath nameContext leftName
                        val newRightLongName = 
                            case NM.lookupVar (nameContext, rightNames) of
                              (_, NONE) => 
                              (E.enqueueError 
                                 (loc, 
                                  E.ExnNotFound
                                    ({name =
                                      Absyn.longidToString(rightNames)}));
                               (constructDummyNamePath rightNames))
                            | (_, SOME (NM.VARID namePath)) => 
                              (E.enqueueError 
                                 (loc, 
                                  E.ExnNotFound(
                                  {name = Absyn.longidToString(rightNames)}));
                               (constructDummyNamePath rightNames))
                            | (_, SOME (NM.CONID namePath)) => 
                              (E.enqueueError 
                                 (loc, 
                                  E.ExnNotFound
                                    ({name =
                                      Absyn.longidToString(rightNames)}));
                               (constructDummyNamePath rightNames))
                            | (_, SOME (NM.EXNID namePath)) => namePath
                      in
                        (newExnBinds @ [PCF.PLFEXBINDREP (bool1, 
                                                          newLeftNames, 
                                                          bool2, 
                                                          newRightLongName,
                                                          loc)],
                         NM.mergeVarNameMap
                           {old = varNameMap,
                            new = 
                            SEnv.singleton
                              (leftName, 
                               NM.EXNID (leftName, #strLevel nameContext))})
                      end)
                (nil, SEnv.empty)
                exBinds
        in
          ([PCF.PDFEXD (newExbinds, loc)], 
           NM.injectVarNameMapInNameMap varNameMap)
        end
      | PC.PDLOCALDEC (pdeclList1 , pdeclList2 , loc) => 
        let
          val (newPdeclList1, nameMap1:NM.currentNameMap) = 
              compileDeclList nameContext pdeclList1
          val newNameContext = 
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext,
                 nameMap = nameMap1}
          val (newPdeclList2, nameMap2:NM.currentNameMap) =
              compileDeclList newNameContext pdeclList2
        in
          ([PCF.PDFLOCALDEC (newPdeclList1, newPdeclList2, loc)],
           nameMap2)
        end
      | PC.PDOPEN(strNameList, loc) => 
       (*
        * open is compiled into rebinding term PDFINTRO. For example,
        *     structure S = 
        *          struct
        *                 val x = 1
        *                 type t = int
        *             end
        *     structure P =
        *          struct
        *                open S
        *                val y = x
        *          end
        *   The above is compiled into the following code
        *     val $1.S.x = 1;
        *    type $1.S.t = int;
        *    intro (varNamePathEnv = {$2.P.x -> $1.S.x}
        *           tyNamePathEnv =  {$2.P.t -> $1.S.t},
        *          {original = $1.S, current = $2.P});
        *           val $2.P.y = $2.P.x
        * and the following basicNameMap :
        *           S -> {x -> $1.S.x
        *                 t -> $1.S.t}
        *           P -> {x -> $2.P.x}
        *                {y -> $2.P.y}
        *)
        let
          val (nameMap, newDecs) = 
              foldl
                (fn (strName, (nameMap, newDecs)) =>
                    let
                      val (strpath, basicNameMap) = 
                          case NM.lookupStr(nameContext, strName) of
                            (_, NONE) => 
                            (E.enqueueError 
                               (loc, 
                                E.StructureNotFound
                                  ({name = Absyn.longidToString(strName)}));
                             (constructDummyPath strName,
                              (SEnv.empty, SEnv.empty, SEnv.empty)))
                          | (_, 
                             SOME (NM.NAMEAUX 
                                     {basicNameMap, 
                                      name, 
                                      parentPath,...})) => 
                            (Path.appendUsrPath (parentPath, name), 
                             basicNameMap)
                      val (flattenedNamePathEnv, basicNameMap) = 
                          compileOpen nameContext
                                      loc
                                      basicNameMap
                    in
                      (NM.mergeCurrentNameMap
                         {old = nameMap,
                          new = NM.injectBasicNameMapInNameMap basicNameMap},
                       newDecs @ 
                       [PCF.PDFINTRO (flattenedNamePathEnv, 
                                      {original = strpath, 
                                       current = #strLevel nameContext},
                                      loc)])
                    end)
                (NM.emptyCurrentNameMap, nil)
                strNameList
        in 
          (newDecs, nameMap)
        end
      | PC.PDINFIXDEC(n,idlist,loc) =>
        ([PCF.PDFINFIXDEC(n, idlist, loc)], NM.emptyCurrentNameMap)
      | PC.PDINFIXRDEC(n,idlist,loc) =>
        ([PCF.PDFINFIXRDEC(n,idlist,loc)], NM.emptyCurrentNameMap)
      | PC.PDNONFIXDEC(idlist,loc) =>
        ([PCF.PDFNONFIXDEC(idlist,loc)], NM.emptyCurrentNameMap)
      | PC.PDEMPTY => ([PCF.PDFEMPTY], NM.emptyCurrentNameMap)

  and compileDeclList (nameContext:NameMap.nameContext) pdeclList = 
      let
        val (newPdeclList, _ , nameMap : NM.currentNameMap) =
            foldl
              (fn (pdecl,
                   (newPdeclList, nameContext, nameMap:NM.currentNameMap)
                  ) =>
                  let
                    val (newPdecls, nameMap1) = compileDec nameContext pdecl
                  in
                    (newPdeclList @ newPdecls,
                     NM.extendNameContextWithCurrentNameMap
                       {nameContext = nameContext,
                        nameMap = nameMap1},
                     NM.mergeCurrentNameMap {old = nameMap, new = nameMap1})
                  end)
              (nil, nameContext, NM.emptyCurrentNameMap)
              pdeclList
      in
        (newPdeclList, nameMap)
      end
           
  and compilePatList nameContext plpatList = 
      foldr 
        (fn (plpat, (newPlpatList, varNameMap)) =>
            let 
              val (newPlpat, newVarNameMap) = compilePat nameContext plpat
            in
              (newPlpat :: newPlpatList,
               NM.mergeVarNameMap {old = varNameMap,
                                   new = newVarNameMap})
            end)
        (nil, SEnv.empty)
        plpatList

  and compilePat  nameContext plpat =
      case plpat of
        PC.PLPATWILD x => (PCF.PLFPATWILD x, SEnv.empty)
      | PC.PLPATID (longId, loc) => 
        let
          fun prefixDecLevelName name =
              (name, (#strLevel nameContext))
        in
          case longId of
            [id] => 
            (
             case NM.lookupVar(nameContext, [id]) of
               (_, SOME (NM.CONID namePath)) =>
               (PCF.PLFPATID (namePath, loc), SEnv.empty)
             | (_, SOME (NM.EXNID namePath)) =>
               (PCF.PLFPATID (namePath, loc), SEnv.empty)
             | _ =>
(*
                if inDecNamePosition then
*)

                (PCF.PLFPATID
                   ((id, #strLevel nameContext), loc), 
                 SEnv.singleton(id, NM.VARID(prefixDecLevelName id)))
(*
                 else
                   (PCF.PLFPATID ((id, Path.NilPath), loc), 
                    SEnv.singleton(id, NM.VARID(id, Path.NilPath))
                   )
*)
            )

          | nil => raise Control.Bug "value declaration has no declared name!"
          | longName => 
            case NM.lookupVar(nameContext, longName) of
              (_, NONE) => 
              (E.enqueueError 
                 (loc, 
                  E.VarNotFound({name = Absyn.longidToString(longName)}));
               ((PCF.PLFPATID 
                   (constructDummyNamePath longName, loc), 
                 SEnv.empty)))
            | (_, SOME (NM.VARID namePath)) => 
              (E.enqueueError 
                 (loc, 
                  E.ConNotFound({name = Absyn.longidToString(longName)}));
               ((PCF.PLFPATID (constructDummyNamePath longName, loc), 
                 SEnv.empty)))
            | (_, SOME (NM.EXNID namePath)) => 
              (PCF.PLFPATID (namePath, loc), SEnv.empty)
            | (_, SOME (NM.CONID namePath)) =>
              (PCF.PLFPATID(namePath, loc), SEnv.empty)
        end
      | PC.PLPATCONSTANT (constant, loc) =>
        (PCF.PLFPATCONSTANT(constant,loc), SEnv.empty)
      | PC.PLPATCONSTRUCT (plpat1, plpat2, loc) => 
        let
          val (newPlpat1, varNameMap1) = compilePat nameContext plpat1
          val (newPlpat2, varNameMap2) = compilePat nameContext plpat2
        in
          (PCF.PLFPATCONSTRUCT (newPlpat1, newPlpat2, loc),
           NM.mergeVarNameMap{new = varNameMap2,
                              old = varNameMap1})
        end
      | PC.PLPATRECORD (bool, stringPlpatList, loc) => 
        let
          val (fields, varNameMap) = 
              foldr
                (fn ((l,plpat), (fields, varNameMap)) =>
                    let
                      val (newPlpat, varNameMap') = 
                          compilePat nameContext plpat
                    in 
                      ((l, newPlpat)::fields,
                       NM.mergeVarNameMap
                         {new = varNameMap', old = varNameMap})
                    end)
                (nil, SEnv.empty)
                stringPlpatList
        in
          (PCF.PLFPATRECORD(bool, fields, loc), varNameMap)
        end
      | PC.PLPATLAYERED (string , tyOpt , plpat , loc) => 
        let
          val varNameMap1 =
              SEnv.singleton (string, NM.VARID (string, Path.NilPath))
          val (newPlpat, varNameMap2) = compilePat nameContext plpat
          val newTyOpt =
              Option.map (compileTy nameContext) tyOpt
        in
          (PCF.PLFPATLAYERED (string , newTyOpt , newPlpat , loc), 
           NM.mergeVarNameMap {old = varNameMap1,
                               new = varNameMap2})
        end
      | PC.PLPATTYPED (plpat , ty , loc) => 
        let
          val (newPlpat, varNameMap) = compilePat nameContext plpat
          val newTy = compileTy nameContext ty
        in
          (PCF.PLFPATTYPED (newPlpat, newTy, loc), 
           varNameMap)
        end
      | PC.PLPATORPAT (plpat1 , plpat2 , loc) => 
        let
          val (newPlpat1, varNameMap1) = compilePat nameContext plpat1
          val (newPlpat2, varNameMap2) = compilePat nameContext plpat2
        in
          (PCF.PLFPATORPAT (newPlpat1, newPlpat2, loc), 
           NM.mergeVarNameMap{new = varNameMap2,
                              old = varNameMap1})
        end
               
  (************************ module language *********************)
               
  and compileStrDecs isTop nameContext strDecs = 
      let
        val (decs, _, nameMap) =
            foldl
              (fn (strDec, (decs, nameContext, incNameMap)) =>
                  let
                    val (newDecs, newIncNameMap) = 
                        compileStrDec isTop nameContext strDec
                  in
                    (decs @ newDecs,
                     NM.extendNameContextWithCurrentNameMap
                       {nameContext = nameContext,
                        nameMap = newIncNameMap},
                     NM.mergeCurrentNameMap {old = incNameMap,
                                             new = newIncNameMap})
                  end)
              (nil, nameContext, NM.emptyCurrentNameMap)
              strDecs
      in
        (decs, nameMap)
      end

  and compileStrDec isTop nameContext strDec =
      case strDec of
        PC.PLCOREDEC (dec, loc) => 
        let
          val (newDecs, nameMap) = compileDec nameContext dec
        in
          ([PCF.PDFCOREDEC (newDecs, loc)], nameMap)
        end
      | PC.PLSTRUCTBIND (strBinds, loc) =>
        let
          val (units, incNameMap) = 
              foldl
                (fn (strBind as (strName, strExp), (units, incNameMap)) => 
                    let
                      val sysStructureName = VarNameGen.generate ()
                      val sysStrpath =
                          NM.appendStrLevel(#strLevel nameContext, 
                                            (sysStructureName, 
                                             NM.SYS))
                      val newNameContext = 
                          NM.updateStrLevel 
                            (nameContext, 
                             NM.appendStrLevel (sysStrpath, (strName, NM.USR)))
                      val (newUnit, incNameMap1) =
                          compileStrExp isTop newNameContext strExp
                      val strNameMap =
                          SEnv.singleton
                            (strName, 
                             NM.NAMEAUX 
                               {
                                name = strName,
                                wrapperSysStructure = SOME (sysStructureName),
                                parentPath = sysStrpath,
                                basicNameMap = 
                                (NM.extractBasicNameMapFromNameMap incNameMap1)
                               }
                            )
                    in
                      (units @ 
                       [({strName = strName, 
                          topSigConstraint = extractSigInfoFromTopStrExp
                                               isTop strExp,
                          strNameMap = strNameMap}, 
                         newUnit)], 
                       NM.mergeCurrentNameMap
                         {old = incNameMap,
                          new = NM.injectStrNameMapInNameMap strNameMap})
                    end)
                (nil, NM.emptyCurrentNameMap)
                strBinds
        in
          ([PCF.PDFANDFLATTENED(units, loc)], incNameMap)
        end
      | PC.PLSTRUCTLOCAL(strDecs1, strDecs2, loc) =>
        let
(*
          val newNameContext = NM.updateStrLevel(nameContext, Path.NilPath)
*)
          val (decs1, incNameMap1) = 
              compileStrDecs false nameContext strDecs1
          val newNameContext = 
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext,
                 nameMap = incNameMap1}
          val (decs2, incNameMap2) =
              compileStrDecs true newNameContext strDecs2
        in
          ([PCF.PDFSTRLOCAL(decs1, decs2, loc)], incNameMap2)
        end

  and extractSigInfoFromTopStrExp isTop plStrExp =
      if isTop then
        case plStrExp of
          PC.PLSTRTRANCONSTRAINT(plStrExp, plSigExp, loc) => SOME plSigExp
        | PC.PLSTROPAQCONSTRAINT(plStrExp, plSigExp, loc) => SOME plSigExp
        | PC.PLSTRUCTLET(strDecs, strExp, loc) => 
          extractSigInfoFromTopStrExp isTop strExp
        | _ => NONE 
      else NONE

  and compileStrExp isTop nameContext strExp =
      case strExp of
        PC.PLSTREXPBASIC(strDecs, loc) => 
        let
          val (newDecs, nameMap) = compileStrDecs false nameContext strDecs
        in
          (newDecs, nameMap)
        end
      | PC.PLSTRID(strNames, loc) => 
        (* 
         * structure identifier is transformed into a basic structure
         * expression that contains only a open declaration.
         *)
        let
          val newStrExp =
              PC.PLSTREXPBASIC
                ([PC.PLCOREDEC (PC.PDOPEN([strNames], loc), loc)], loc)
        in
          compileStrExp isTop nameContext newStrExp
        end
      | PC.PLSTRTRANCONSTRAINT(plStrExp, plSigExp, loc) =>
       (* For example, 
        * structure S = 
        *    struct
        *        val x = 1
        *        structure P =
        *           struct
        *              val y = 1
        *             end
        *     end : sig val x : int end
        * is flattened into :
        *   decs : val $1.S.x = 1
        *   sigspec : val $1.S.$2.P.y = 1
        *   richNamePathEnv = {x -> $1.S.x, P.y -> $1.S.$2.P.y}
        *   strictNamePathEnv = { x -> x}
        * 
        * Particularly, richNamePathEnv is used to restore the "clean" type
        * environment in the type inference to do signature matching.
        *)
        let
          val (decs, nameMap1) = 
              compileStrExp isTop nameContext plStrExp
          val newNameContext = NM.updateStrLevel (nameContext, Path.NilPath)
          val (sigSpec, nameMap2) =
              compileSigExp newNameContext plSigExp
          val cutBasicNameMap = 
              constrainBasicNameMap
                {rich = NM.extractBasicNameMapFromNameMap nameMap1, 
                 strict = NM.extractBasicNameMapFromNameMap nameMap2}
                loc
          val strictFlattenedNameMap = 
              NM.basicNameMapToFlattenedNamePathEnv cutBasicNameMap
          val richFlattenedNameMap = 
              NM.basicNameMapToFlattenedNamePathEnv
                (NM.extractBasicNameMapFromNameMap nameMap1)
          val newNameMap = NM.injectBasicNameMapInNameMap cutBasicNameMap
        in 
          ([PCF.PDFTRANCONSTRAINT
              (decs,
               richFlattenedNameMap,
               sigSpec,
               strictFlattenedNameMap,
               loc)], 
           newNameMap)
        end
      | PC.PLSTROPAQCONSTRAINT(plStrExp, plSigExp, loc) =>
        let
          val (decs, nameMap1) = 
              compileStrExp isTop nameContext plStrExp
          val newNameContext = NM.updateStrLevel (nameContext, Path.NilPath)
          val (sigSpec, nameMap2) =
              compileSigExp newNameContext plSigExp
          val cutBasicNameMap = 
              constrainBasicNameMap 
                {rich = NM.extractBasicNameMapFromNameMap nameMap1, 
                 strict = NM.extractBasicNameMapFromNameMap nameMap2} 
                loc
          val strictFlattenedNameMap = 
              NM.basicNameMapToFlattenedNamePathEnv cutBasicNameMap
          val richFlattenedNameMap = 
              NM.basicNameMapToFlattenedNamePathEnv
                (NM.extractBasicNameMapFromNameMap nameMap1)
          val newNameMap = NM.injectBasicNameMapInNameMap cutBasicNameMap
        in 
          ([PCF.PDFOPAQCONSTRAINT
              (decs,
               richFlattenedNameMap,
               sigSpec,
               strictFlattenedNameMap,
               loc)], 
           newNameMap)
        end
      | PC.PLFUNCTORAPP(funName, strExp, loc) =>
        let
          val {localPart, namePart = actualArgName} = 
              nameAnonymousActualFunctorArg strExp
(*
          val newNameContext = NM.updateStrLevel (nameContext, Path.NilPath)
*)
          val (localDecs, localNameMap) = 
              compileStrDecs isTop nameContext localPart
          val (actualArgPath, actualArgNameMap) = 
              let
                val newNameContext = NM.extendNameContextWithCurrentNameMap
                                       {nameContext = nameContext, 
                                        nameMap = localNameMap}
              in
                case NM.lookupStr(newNameContext, actualArgName) of
                  (_, NONE) => 
                  (E.enqueueError 
                     (loc, 
                      E.StructureNotFound
                        ({name = Absyn.longidToString(actualArgName)}));
                   (constructDummyPath actualArgName, 
                    (SEnv.empty, SEnv.empty, SEnv.empty)))
                | (_, SOME (NM.NAMEAUX {name, wrapperSysStructure, 
                                        parentPath, basicNameMap})) => 
                  (Path.appendUsrPath(parentPath, name), basicNameMap)
              end
          val flattenedArgNamePathEnv = 
              NM.basicNameMapToFlattenedNamePathEnv actualArgNameMap
          val bodyBasicNameMap = 
              let
                val bodyBasicNameMap =
                    case NM.lookupFunctor(nameContext, funName) of
                      NONE => 
                      (
                       E.enqueueError 
                         (
                          loc, 
                          E.FunctorNotFound({name = funName})
                         );
                       (SEnv.empty, SEnv.empty, SEnv.empty)
                      )
                    | SOME ({body =
                             NM.NAMEAUX {basicNameMap = bodyBasicNameMap,...},
                             ...}) => 
                      bodyBasicNameMap
              in
                adjustPrefixBasicNameMap
                  (#strLevel nameContext)
                  bodyBasicNameMap
              end
          val newTerm = 
              let
                val term = [PCF.PDFFUNCTORAPP
                              (#strLevel nameContext, 
                               funName, 
                               (actualArgPath, flattenedArgNamePathEnv),
                               loc)]
              in
                case localDecs of 
                  nil => term
                | _ => [PCF.PDFSTRLOCAL(localDecs, term, loc)]
              end
        in
          (newTerm, NM.injectBasicNameMapInNameMap bodyBasicNameMap)
        end
      | PC.PLSTRUCTLET(strDecs, strExp, loc) =>
        let
(*
          val newNameContext = NM.updateStrLevel(nameContext, Path.NilPath)
*)
          val (decs1, incNameMap1) = 
              compileStrDecs false nameContext strDecs
          val newNameContext = 
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext, nameMap = incNameMap1}
          val (decs2, incNameMap2) = 
              compileStrExp isTop newNameContext strExp
        in 
          ([PCF.PDFSTRLOCAL(decs1, decs2, loc)], incNameMap2)
        end

   (*
    * signature is flattened, but not injected into unique structures.
    *)
  and compileSigExp nameContext sigExp =
      case sigExp of
        PC.PLSIGEXPBASIC(spec,loc) => 
        let
          val (newSpec, incNameMap) = 
              compileSpec nameContext spec
        in
          (newSpec, incNameMap)
        end
      | PC.PLSIGID(sigName, loc) => 
        let
          val basicNameMap = 
              case NM.lookupSig(nameContext, sigName) of
                NONE => (E.enqueueError 
                           (loc, 
                            E.SignatureNotFound({name = sigName}));
                         (SEnv.empty, SEnv.empty, SEnv.empty))
              | SOME {basicNameMap,...} => basicNameMap
          val newBasicNameMap =
              adjustPrefixBasicNameMap (#strLevel nameContext) basicNameMap
        in 
          (PCF.PLFSPECPREFIXEDSIGID((sigName, #strLevel nameContext), loc), 
           NM.injectBasicNameMapInNameMap newBasicNameMap)
        end
      | PC.PLSIGWHERE(sigExp, rlstns, loc) =>
        let
          val (spec, incNameMap) = compileSigExp nameContext sigExp
          val newRlstns = 
              foldl
                (fn ((tvars, longid, ty), newRlstns) =>
                    let
                      val (longPath, name) = 
                          case NM.lookupTyInCurrentNameMap
                                 (incNameMap, longid) of
                            (strPath, NONE) => 
                            let
                              val (name, strPath) =
                                  constructDummyNamePath longid
                            in
                              (E.enqueueError 
                                 (loc, 
                                  E.TyConNotFound
                                    ({name = Absyn.longidToString(longid)}));
                               (strPath, name))
                            end
                          | (strPath, SOME (NM.DATATY((name, _),_))) =>
                            (strPath, name)
                          | (strPath, SOME (NM.NONDATATY (name, _))) => 
                            (strPath, name)
                    in
                      (newRlstns
                       @ [(tvars, 
                           (name,
                            Path.joinPath (#strLevel nameContext,
                                           longPath)),
                           compileTy nameContext ty)])
                    end)
                nil
                rlstns
        in
          (PCF.PLFSPECSIGWHERE(spec, newRlstns, loc), incNameMap)
        end

  and compileSpec nameContext spec = 
      case spec of
        PC.PLSPECVAL(nameTys, loc) => 
        let
          val (newNamePathTys, varNameMap) = 
              foldl
                (fn ((name, ty), (newNamePathTys, varNameMap)) =>
                    let
                      val newNamePath = (name, (#strLevel nameContext))
                    in
                      (newNamePathTys
                       @ [(newNamePath, compileTy nameContext ty)],
                       SEnv.insert
                         (varNameMap,
                          name, 
                          NM.VARID(name, #strLevel nameContext)))
                    end)
                (nil, SEnv.empty)
                nameTys
        in
          (PCF.PLFSPECVAL
             (newNamePathTys, loc),
           NM.injectVarNameMapInNameMap(varNameMap))
        end
      | PC.PLSPECTYPE(types, loc) => 
        let
          val (typeNameMap, newTypes) =
              foldl
                (fn ((tyvars, name), (typeNameMap, newTypes)) =>
                    let
                      val newName =  (name, (#strLevel nameContext))
                    in
                      (SEnv.insert
                         (typeNameMap, 
                          name, 
                          NM.NONDATATY (name, #strLevel nameContext)),
                       newTypes @ [(tyvars, newName)])
                    end
                )
                (SEnv.empty, nil)
                types
        in
          (PCF.PLFSPECTYPE(newTypes, loc),
           NM.injectTyNameMapInNameMap(typeNameMap))
        end
      | PC.PLSPECTYPEEQUATION ((tyvars, name, ty), loc) => 
        let
          val namePath = NM.constructNamePath nameContext name
          val newTy = compileTy nameContext ty
          val tyNameMap =
              SEnv.singleton
                (name, NM.NONDATATY(name, #strLevel nameContext))
        in
          (PCF.PLFSPECTYPEEQUATION ((tyvars, namePath, newTy), loc), 
           NM.injectTyNameMapInNameMap(tyNameMap))
        end
      | PC.PLSPECEQTYPE(types, loc) => 
        let
          val (newTypes, typeNameMap) =
              foldl (fn ((tyvars, name), (newTypes, typeNameMap)) =>
                        (newTypes @ [(tyvars, 
                                      NM.constructNamePath nameContext name
                                    )],
                         SEnv.insert
                           (typeNameMap, 
                            name, 
                            NM.NONDATATY(name, #strLevel nameContext)
                           )
                        )
                    )
                    (nil, SEnv.empty)
                    types
        in
          ( PCF.PLFSPECEQTYPE(newTypes, loc), 
            NM.injectTyNameMapInNameMap(typeNameMap))
        end
      | PC.PLSPECDATATYPE(datatypes, loc) => 
        let
          val newDatatypes = 
              map
                (fn (tvars, name, constructorNames) =>
                    let
                      val newConstructorNames =
                          map (fn (con, tyoption) => (false, con, tyoption))
                              constructorNames
                    in
                      (tvars, name, newConstructorNames)
                    end)
                datatypes
          val (nameMap, newDatatypes1) =
              compileDatatypes nameContext newDatatypes
          val newDatatypes2 = 
              map
                (fn (tvars, name, constructorNames) =>
                    let
                      val newConstructorNames =
                          map (fn (_, con, tyoption) => (con, tyoption))
                              constructorNames
                    in
                      (tvars, name, newConstructorNames)
                    end)
                newDatatypes1
        in 
          (PCF.PLFSPECDATATYPE
             (#strLevel nameContext, newDatatypes2, loc),
           nameMap)
        end
      | PC.PLSPECREPLIC(leftName, rightNames, loc) => 
        let
          val newLeftNamePath = NM.constructNamePath nameContext leftName
          val (newRightNamePath, varNameMap) =
              case NM.lookupTy(nameContext, rightNames) of
                (_, NONE) => 
                (E.enqueueError 
                   (loc, 
                    E.TyConNotFound
                      ({name = Absyn.longidToString(rightNames)}));
                 (constructDummyNamePath rightNames, SEnv.empty))
              | (_, SOME (NM.DATATY (namePath, varNameMap)))
                => (namePath, varNameMap)
              | (_, SOME (NM.NONDATATY namePath))
                => (namePath, SEnv.empty)
          val newVarNameMap =
              constructDataCon (#strLevel nameContext) varNameMap
          val nameMap =
              NM.mergeCurrentNameMap
                {old = NM.injectVarNameMapInNameMap newVarNameMap,
                 new = NM.injectTyNameMapInNameMap 
                         (SEnv.singleton
                            (leftName, 
                             NM.DATATY ((leftName, #strLevel nameContext),
                                        newVarNameMap)))}
        in
          (PCF.PLFSPECREPLIC(newLeftNamePath, newRightNamePath, loc), nameMap)
        end
      | PC.PLSPECEXCEPTION(nameTyOpts, loc) => 
        let
          val newNameContext = 
              NM.updateStrLevel(nameContext, #strLevel nameContext)
          val (newNamePathTyOpts, nameMap) = 
              foldl
                (fn ((name, tyOpt), (exns, nameMap)) =>
                    let
                      val newNamePath =
                          NM.constructNamePath newNameContext name
                      val newTyOpt = compileTyOpt newNameContext tyOpt
                    in
                      (exns @ [(newNamePath, newTyOpt)],
                       NM.mergeCurrentNameMap {
                       old = nameMap,
                       new = 
                       NM.injectVarNameMapInNameMap
                         (SEnv.singleton 
                            (name, 
                             NM.EXNID (name, 
                                       #strLevel newNameContext)))
                      })
                    end)
                (nil, NM.emptyCurrentNameMap)
                nameTyOpts
        in
          (PCF.PLFSPECEXCEPTION(newNamePathTyOpts, loc), nameMap)
        end
      | PC.PLSPECSTRUCT (strNameSigExpList, loc) =>
        let
          val (specs, strNameMap) =
              foldl
                (fn ((strName, sigExp), 
                     (newStrNameSigExpList, strNameMap)) =>
                    let
                      val newNameContext =
                          let
                            val newStrLevel = 
                                NM.appendStrLevel(#strLevel nameContext, 
                                                  (strName,
                                                   NM.USR))
                          in
                            NM.updateStrLevel(nameContext, newStrLevel)
                          end
                      val (newSigExp, nameMap) =
                          compileSigExp newNameContext sigExp
                      val basicNameMap =
                          NM.extractBasicNameMapFromNameMap nameMap
                    in
                      (newStrNameSigExpList @ [newSigExp],
                       SEnv.insert(strNameMap, 
                                   strName,
                                   NM.NAMEAUX
                                     {
                                      name = strName,
                                      wrapperSysStructure = NONE,
                                      parentPath = #strLevel nameContext,
                                      basicNameMap = basicNameMap}))
                    end)
                (nil, SEnv.empty)
                strNameSigExpList
          val seqSpec = 
              case specs of
                nil => raise Control.Bug "structure specification is empty"
              | (h :: t) =>
                foldl (fn (spec, seqSpec) =>
                          PCF.PLFSPECSEQ(seqSpec, spec, loc))
                      h
                      t
        in
          (seqSpec, NM.injectStrNameMapInNameMap strNameMap)
        end
(*
      | PC.PLSPECFUNCTOR (functorList, loc) =>
        let
          val (newFunctorList, functorNameMap) = 
              foldl
                (fn ((funName, argSigExp, bodySigExp),
                     (newFunctorList, functorNameMap)) =>
                    let
        (* functor specification is the only one that involves
         * unique structure name. One problematic example imposes
         * this requirement:
         * sig
         *    structure S : sig type t end
         *    structure K : sig type t end
         *    functor F : sig structure S : sig type t val x : S.t end =>
         *                sig structure K : sig type t val x : K.t end
         *)
                      val sysStructureName = VarNameGen.generate ()
                      val newNameContext = 
                          NM.updateStrLevel
                            (nameContext, 
                             Path.PSysStructure
                               (sysStructureName, Path.NilPath))
                      val (newArgSigExp, newArgNameMap) = 
                          compileSigExp newNameContext argSigExp
                      val basicArgSigNameMap =
                          NM.extractBasicNameMapFromNameMap newArgNameMap
                      val newNameContext = 
                          NM.extendNameContextWithCurrentNameMap
                            {nameContext = nameContext, 
                             nameMap = NM.injectBasicNameMapInNameMap
                                         basicArgSigNameMap}
                      val sysStructureName = VarNameGen.generate ()
                      val newNameContext = 
                          NM.updateStrLevel (newNameContext, 
                                             Path.PSysStructure
                                               (sysStructureName,
                                                Path.NilPath))
                      val (newBodySigExp, bodyNameMap) = 
                          compileSigExp newNameContext bodySigExp
                      val basicBodyNameMap = 
                          NM.extractBasicNameMapFromNameMap bodyNameMap
                    in
                      (newFunctorList
                       @ [(funName, 
                           (newArgSigExp, 
                            NM.basicNameMapToFlattenedNamePathEnv
                              basicArgSigNameMap),
                           (newBodySigExp,
                            NM.basicNameMapToFlattenedNamePathEnv
                              basicBodyNameMap)
                          )
                         ],
                       SEnv.insert
                         (functorNameMap,
                          funName,
                          {arg = basicArgSigNameMap,
                           body =
                           NM.NAMEAUX
                             {
                              name = funName,
                              wrapperSysStructure = NONE,
                              parentPath = Path.NilPath,
                              basicNameMap =
                                NM.extractBasicNameMapFromNameMap bodyNameMap
                             }
                          }
                         )
                      )
                    end)
                (nil, SEnv.empty)
                functorList
        in
          (PCF.PLFSPECFUNCTOR (newFunctorList, loc),
           NM.injectFunNameMapInNameMap functorNameMap)
        end
*)
      | PC.PLSPECINCLUDE(sigExp,loc) => 
        let
          val (newSpec, nameMap) = compileSigExp nameContext sigExp
        in
          (newSpec, nameMap)
        end
      | PC.PLSPECSEQ (spec1, spec2, loc) => 
        let
          val (newSpec1, nameMap1) = compileSpec nameContext spec1
          val newNameContext = 
              NM.extendNameContextWithCurrentNameMap
                {nameContext = nameContext,
                 nameMap = nameMap1}
          val (newSpec2, nameMap2) = compileSpec newNameContext spec2
        in
          (PCF.PLFSPECSEQ (newSpec1, newSpec2, loc),
           NM.mergeCurrentNameMap{old = nameMap1, new = nameMap2})
        end
      | PC.PLSPECSHARE(spec, longTyConNames, loc) => 
        let
          val (newSpec, nameMap) = compileSpec nameContext spec
          val longTyConPaths = 
              map
                (fn longTyConName =>
                    case NM.lookupTyInCurrentNameMap
                           (nameMap, longTyConName) of
                      (_, NONE) => 
                      (E.enqueueError 
                         (loc, 
                          E.TyConNotFound
                            ({name = Absyn.longidToString(longTyConName)}));
                       (constructDummyNamePath (longTyConName)))
                    | (_, SOME (NM.DATATY((name, strPath), _)))
                      => (name, strPath)
                    | (_, SOME (NM.NONDATATY(name, strPath)))
                      => (name, strPath))
                longTyConNames
        in
          (PCF.PLFSPECSHARE(newSpec, longTyConPaths, loc),
           nameMap)
        end
      | PC.PLSPECSHARESTR(spec, longStrNames, loc) => 
        let
          val (newSpec, nameMap) = compileSpec nameContext spec
          val mixedEntries = 
              map
                (fn longStrName => 
                    let
                      val (longStrPath, strEntry) = 
                          case NM.lookupStrInCurrentNameMap
                                 (nameMap, longStrName) of
                            (_, NONE) => 
                            (E.enqueueError 
                               (loc, 
                                E.StructureNotFound
                                  ({name =
                                    Absyn.longidToString(longStrName)}));
                             let
                               val strpath = constructDummyPath longStrName
                               val name = Path.getLastElementOfPath strpath
                             in
                               (strpath, NM.NAMEAUX
                                           {name = name, 
                                            wrapperSysStructure = NONE,
                                            parentPath = Path.NilPath,
                                            basicNameMap = 
                                            (SEnv.empty,
                                             SEnv.empty,SEnv.empty)})
                             end)
                          | (strPath,
                             SOME (strEntry as (NM.NAMEAUX {name,  ...})))
                            => 
                            (Path.appendUsrPath(strPath, name), strEntry)
                    in
                      (strEntry,
                       Path.joinPath(#strLevel nameContext,
                                     longStrPath))
                    end)
                longStrNames
                       
          fun share nil sharings = sharings
            | share ((strNameMapEntry, longStrPath)
                     :: mixedEntries) sharings = 
              let
                val sharings1 = 
                    sharePairWise (strNameMapEntry, longStrPath) mixedEntries
              in
                share mixedEntries (sharings @ sharings1)  
              end
                       
          and sharePairWise (strNameMapEntry, longStrPath) mixedEntries = 
              case strNameMapEntry of
                NM.NAMEAUX
                  {
                   name, 
                   basicNameMap = (tyMap, varMap, strMap),
                   ...} =>
                foldl
                  (fn ((NM.NAMEAUX
                          {
                           name=name1, 
                           basicNameMap = (tyMap1, varMap1, strMap1),
                           ...},
                        longStrPath1), sharings) =>
                      let
                        val sharings1 =
                            sharePairTyMap (longStrPath, longStrPath1)
                                           (tyMap, tyMap1)
                        val sharings2 = 
                            sharePairStrMap (longStrPath, longStrPath1)
                                            (strMap, strMap1)
                      in
                        sharings @ sharings1 @ sharings2
                      end)
                  nil
                  mixedEntries

          and sharePairTyMap (longStrPath1, longStrPath2) (tyMap1, tyMap2) =
              SEnv.foldli
                (fn (tyName, _, sharings) =>
                    case SEnv.find(tyMap2, tyName) of
                      NONE => sharings
                    | SOME _ =>  sharings @ [((tyName, longStrPath1),
                                              (tyName, longStrPath2))])
                nil
                tyMap1
                
          and sharePairStrMap (longStrPath1, longStrPath2) (strMap1, strMap2) =
              SEnv.foldli
                (fn (strName, 
                     NM.NAMEAUX
                       {
                        name = name3, 
                        basicNameMap = (tyMap3, varMap3, strMap3),
                        ...},
                     sharings) =>
                    case SEnv.find(strMap2, strName) of
                      NONE => sharings
                    | SOME (NM.NAMEAUX
                              {
                               name = name4, 
                               basicNameMap = (tyMap4, varMap4, strMap4),
                               ...}) =>
                      let
                        val pairPath = 
                            (NM.appendStrLevel
                               (longStrPath1, (strName, NM.USR)),
                             NM.appendStrLevel
                               (longStrPath2, (strName, NM.USR)))
                        val sharings3 = 
                            sharePairTyMap pairPath (tyMap3, tyMap4)
                        val sharings4 =
                            sharePairStrMap pairPath (strMap3, strMap4)
                      in
                        sharings @ sharings3 @ sharings4
                      end)
                nil

                strMap1
                
          val newTerm = 
              let
                val sharings = share mixedEntries nil
              in
                foldl
                  (fn ((leftLongTyConName, rightLongTyConName), term) => 
                      PCF.PLFSPECSHARE
                        (term,
                         [leftLongTyConName, rightLongTyConName], 
                         loc))
                  newSpec
                  sharings
              end
        in
          (newTerm, nameMap)
        end
      | PC.PLSPECEMPTY => (PCF.PLFSPECEMPTY, NM.emptyCurrentNameMap)

  and compileSigDec nameContext (sigName, plSigExp) =
      let
        val (plfSpec, nameMap) = 
            compileSigExp nameContext plSigExp
        val sigNameMap = 
            SEnv.singleton
              (sigName, 
               NM.NAMEAUX
                 {
                  name = sigName,
                  parentPath = Path.NilPath,
                  wrapperSysStructure = NONE,
                  basicNameMap = NM.extractBasicNameMapFromNameMap nameMap
              })
      in
        ((sigName, (plfSpec, plSigExp)), sigNameMap)
      end

  and compileSigDecs nameContext sigDecs = 
      let
        val (newSigDecs, _, sigNameMap) =
            foldl
              (fn (sigDec, (newSigDecs, newNameContext, sigNameMap)) =>
                  let
                    val (sigDec, sigNameMap1) = 
                        compileSigDec newNameContext sigDec
                  in
                    (newSigDecs @ [sigDec],
                     NM.extendNameContextWithSigNameMap 
                       {nameContext = newNameContext,
                        sigNameMap = sigNameMap},
                     NM.mergeSigNameMap {old = sigNameMap,
                                         new = sigNameMap1})
                  end)
              (nil, nameContext, SEnv.empty)
              sigDecs
      in
        (newSigDecs, sigNameMap)
      end

  and compileTopDec nameContext topdec = 
      case topdec of 
        PC.PLTOPDECSTR(strDec, loc) => 
        let
          val isTop = true
          val (coreDecs, nameMap) = compileStrDec isTop nameContext strDec
        in
          (PCF.PLFDECSTR (coreDecs, loc), nameMap)
        end
      | PC.PLTOPDECSIG(sigDecs, loc) => 
        let
          val (newSigDecs, sigNameMap) = 
              compileSigDecs nameContext sigDecs 
        in
          (PCF.PLFDECSIG (newSigDecs, loc), 
           NM.injectSigNameMapInNameMap sigNameMap)
        end
      | PC.PLTOPDECFUN(funBinds, loc) => 
        let
          val (newFunBinds, funNameMap) = 
              foldl
                (fn ((funName, argStrName, argSigExp, bodyStrExp, loc), 
                     (funBinds, incNameMap)) => 
                    let
                      val sysStructureName = VarNameGen.generate ()
                      val argStrPath = 
                          Path.PSysStructure
                            (
                             sysStructureName,
                             Path.PUsrStructure
                               (argStrName, Path.NilPath))
                      val (newArgSpec, argBasicNameMap) =
                          let
                            val newNameContext =
                                NM.updateStrLevel (nameContext, argStrPath)
                            val (spec, incNameMap) =
                                compileSigExp newNameContext argSigExp
                          in
                            (spec, 
                             NM.extractBasicNameMapFromNameMap incNameMap)
                          end
                      val argNameMap = 
                          NM.injectStrNameMapInNameMap
                            (SEnv.singleton
                               (argStrName, 
                                NM.NAMEAUX {name = argStrName,
                                            wrapperSysStructure = NONE,
                                            parentPath = Path.NilPath,
                                            basicNameMap = argBasicNameMap}))
                      val (newBodyDecList, bodyBasicNameMap) =
                          let
                            val (decs, incNameMap) =
                                compileStrExp 
                                  true
                                  (NM.extendNameContextWithCurrentNameMap
                                     {nameContext = nameContext,
                                      nameMap = argNameMap})
                                  bodyStrExp
                          in 
                            (decs, NM.extractBasicNameMapFromNameMap incNameMap)
                          end
                      val newIncNameMap = 
                          NM.injectFunNameMapInNameMap
                            (SEnv.singleton
                               (funName, 
                                {arg = argBasicNameMap,
                                 body = NM.NAMEAUX
                                          {
                                           name = funName,
                                           wrapperSysStructure = NONE,
                                           parentPath = Path.NilPath,
                                           basicNameMap = bodyBasicNameMap}}))
                      val bodySigExpOpt =
                          extractSigInfoFromTopStrExp true bodyStrExp
                    in
                      ((funBinds @ 
                        [(funName, 
                          (newArgSpec, 
                           argStrName,
                           NM.basicNameMapToFlattenedNamePathEnv
                             argBasicNameMap,
                           argSigExp), 
                          (newBodyDecList, bodyBasicNameMap, bodySigExpOpt), 
                          loc)]),
                       NM.mergeCurrentNameMap {old = incNameMap,
                                               new = newIncNameMap})
                    end)
                (nil, NM.emptyCurrentNameMap)
                funBinds
        in
          (PCF.PLFDECFUN(newFunBinds, loc), funNameMap)
        end

  and compileTopDecs nameContext topDecs =
      let
        val (newCoreDecs, nameMap, _) =
            foldl
              (fn (topDec, (topDecs, incNameMap, nameContext)) =>
                  let
                    val (newTopDec, incNameMap') =
                        compileTopDec nameContext topDec
                  in
                    (
                     topDecs @ [newTopDec],
                     NM.mergeCurrentNameMap
                       {new = incNameMap', old = incNameMap},
                     NM.extendNameContextWithCurrentNameMap
                       {nameContext = nameContext,
                        nameMap = incNameMap'}
                    )
                  end)
              (nil, NM.emptyCurrentNameMap, nameContext)
              topDecs
      in
        (newCoreDecs, nameMap)
      end

  (** topNameMap : 1. error detection for structure 
   *               2. structure replication
   *               3. open structure declaration
   * For item 2 and 3, nameMap need to be looked up to generate
   * static rebindings. These kind of rebindings are eleminated 
   * by uniqueIdAllocation phase.
   *)
  fun compile topNameMap (stamp: VarNameID.id) topDecs =
      let
        val _ = VarNameGen.init stamp
        val _ = E.initializeModuleCompilationError()
        val nameContext = {topNameMap = topNameMap,
                           currentNameMap = NM.emptyCurrentNameMap,
                           strLevel = Path.NilPath}
        val (decs, currentNameMap) = compileTopDecs nameContext topDecs
      in
        if E.isError()
        then
          raise UE.UserErrors (E.getErrorsAndWarnings ())
        else 
          (
           currentNameMap, 
           VarNameGen.reset (), 
           decs
          )
      end
end
end
