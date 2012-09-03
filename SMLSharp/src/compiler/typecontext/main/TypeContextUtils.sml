(**
 * type context manipulation utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TypeContextUtils.sml,v 1.69 2008/03/25 02:39:44 bochao Exp $
 *)
structure TypeContextUtils =
struct

local 
  structure T = Types
  structure TU = TypesUtils
  structure TC = TypeContext
  structure NPEnv = NameMap.NPEnv
in
  type tyConSubst = T.tyBindInfo TyConID.Map.map
  exception ExTySpecInstantiatedWithNonEqTyBindInfo of string

  fun substTyConInTy switch (tyConSubst : tyConSubst) ty =
      TypeTransducer.mapTyPreOrder
        (fn ty =>
            case ty of
              T.TYVARty (tvar as ref (T.TVAR tvKind)) =>
              let
                val tvKind =
                    substTyConInTvKind switch tyConSubst tvKind
                val _ = tvar := T.TVAR tvKind
              in
                (ty, true)
              end
            | T.RAWty {tyCon as {name, id, ...}, args} => 
              let
                val newArgs = 
                    map (substTyConInTy switch tyConSubst) args
              in
                case TyConID.Map.find(tyConSubst,id) of
                  SOME (T.TYFUN tyFun) => 
                  (TU.betaReduceTy (tyFun, newArgs), false)
                | SOME _ => 
                  (T.RAWty
                     {tyCon = substTyConInTyCon switch tyConSubst tyCon,
                      args = newArgs}, 
                   true)
                | NONE => (ty, true)
              end
            | T.OPAQUEty {spec = {tyCon, args}, implTy} =>
              let
                val newArgs = map (substTyConInTy switch tyConSubst) args
              in
                case TyConID.Map.find(tyConSubst, #id tyCon) of
                  SOME (T.TYOPAQUE {spec, impl}) =>
                  (case (TU.peelTyOPAQUE impl) of
                     T.TYFUN tyFun =>
                     (
                      T.OPAQUEty({spec = {tyCon = spec, args = newArgs},
                                implTy = TU.betaReduceTy (tyFun,newArgs)}), 
                      false
                     )
                   | T.TYCON {tyCon, datacon} =>
                     (
                      T.OPAQUEty {spec = {tyCon = spec, args = newArgs},
                                implTy = T.RAWty {tyCon = tyCon, args = newArgs}
                               }, 
                      false
                     )
                   | T.TYOPAQUE _ =>
                     raise
                       Control.Bug "T.TYOPAQUE should disappear"
                   | T.TYSPEC tyCon => 
                     (
                      T.OPAQUEty {spec = {tyCon = spec, args = newArgs},
                                implTy = T.SPECty
                                           {tyCon = tyCon, args = newArgs}}, 
                      false
                     )
                  )
                | SOME (T.TYFUN tyFun) => 
                  (TU.betaReduceTy (tyFun,newArgs), false)
                | SOME (T.TYCON {tyCon, datacon}) =>
                  (T.RAWty {tyCon = tyCon, args = newArgs}, false)
                | SOME (T.TYSPEC tyCon) =>
                  (T.SPECty {tyCon = tyCon, args = newArgs}, false)
                | NONE => 
                  (T.OPAQUEty {spec = {tyCon = tyCon, args = newArgs}, 
                             implTy = substTyConInTy
                                        switch
                                        tyConSubst
                                        implTy}, 
                   false)
              end
            | T.SPECty {tyCon as {name, id, ...}, args} =>
              let
                val newArgs = map (substTyConInTy switch tyConSubst) args
              in
                case TyConID.Map.find(tyConSubst, id) of
                  SOME (T.TYOPAQUE {spec, impl}) => 
                  (case (TU.peelTyOPAQUE impl) of
                     T.TYFUN tyFun =>
                     (T.OPAQUEty {spec = {tyCon = spec, args = newArgs},
                                implTy = TU.betaReduceTy (tyFun,newArgs)},
                      false)
                   | T.TYCON {tyCon, datacon} =>
                     (T.OPAQUEty{spec = {tyCon = spec, args = newArgs},
                               implTy = T.RAWty {tyCon = tyCon, args = newArgs}},
                      false)
                   | T.TYOPAQUE _ =>
                     raise Control.Bug "T.TYOPAQUE should disappear"
                   | T.TYSPEC tyCon => 
                     (T.OPAQUEty{spec = {tyCon = spec, args = newArgs},
                               implTy = T.SPECty
                                          {tyCon = tyCon, args = newArgs}},
                      false)
                  )
                | SOME (T.TYFUN tyFun) => 
                  (TU.betaReduceTy (tyFun, newArgs), false)
                | SOME (T.TYCON {tyCon, datacon}) =>
                  (T.RAWty {tyCon = tyCon, args = newArgs}, false)
                | SOME (T.TYSPEC tyCon) =>
                  (T.SPECty {tyCon = tyCon, args = newArgs}, false)
                | NONE => 
                  (T.SPECty {tyCon = tyCon, args = newArgs}, false)
              end
            | T.POLYty {boundtvars, body} =>
              let
                val boundtvars = 
                    IEnv.foldli
                      (fn (index, btvKind, boundtvars) =>
                          let
                            val btvKind =
                                substTyConInBtvKind switch tyConSubst btvKind
                          in
                            IEnv.insert(boundtvars, index, btvKind)
                          end)
                      IEnv.empty
                      boundtvars
              in
                (T.POLYty{boundtvars = boundtvars, body = body}, true)
              end
            | _ => (ty, true))
        ty
             
  and substTyConInTvKind
        switch
        (tyConSubst : tyConSubst)
        {lambdaDepth, id, recordKind, eqKind, tyvarName} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    (SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty = substTyConInTy switch tyConSubst ty
                           in
                             SEnv.insert(tySEnvMap, label, ty)
                           end)
                       SEnv.empty
                       tySEnvMap)
              in 
                T.REC tySEnvMap
              end
            | T.OVERLOADED tys => 
              let
                val tys = 
                    (foldr
                       (fn (ty, tys) =>
                           let
                             val ty = substTyConInTy switch tyConSubst ty
                           in
                             ty :: tys
                           end)
                       nil
                       tys)
              in 
                T.OVERLOADED tys
              end
      in
        (
         {
          lambdaDepth = lambdaDepth,
          id=id, 
          recordKind = recordKind,
          eqKind = eqKind,
          tyvarName = tyvarName
         }
        )
      end

  and substTyConInBtvKind
        switch
        (tyConSubst:tyConSubst)
        {index, recordKind, eqKind} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    (SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty = substTyConInTy switch tyConSubst ty
                           in
                             (SEnv.insert(tySEnvMap, label, ty))
                           end)
                       (SEnv.empty)
                       tySEnvMap)
              in
                (T.REC tySEnvMap)
              end
            | T.OVERLOADED tys => 
              let
                val tys = 
                    (foldr
                       (fn (ty, tys) =>
                           let
                             val ty = substTyConInTy switch tyConSubst ty
                           in
                             ty :: tys
                           end)
                       nil
                       tys)
              in
                (T.OVERLOADED tys)
              end
      in
        (
         {
          index=index, 
          recordKind = recordKind,
          eqKind = eqKind
         }
        )
      end

  and substTyConInTyFun
        switch
        (tyConSubst:tyConSubst)
        {name, strpath, tyargs, body} =
      let
        val (tyargs) =
            IEnv.foldri
              (fn (index, btvKind, tyargs) =>
                  let
                    val btvKind = substTyConInBtvKind switch tyConSubst btvKind
                  in
                    IEnv.insert(tyargs, index, btvKind)
                  end)
              IEnv.empty
              tyargs
        val body = substTyConInTy switch tyConSubst body
        val id = case body of 
                   T.ALIASty(T.RAWty {tyCon = {id,...},...}, _) => id
                 | _ =>
                   raise
                     Control.Bug "illegal body of tyFun(substTyConInTyFun)"
        val strpath = case TyConID.Map.find(tyConSubst, id) of
                        NONE => strpath
                      | SOME (T.TYCON {tyCon = {strpath, ...}, ...}) => strpath
                      | SOME (T.TYFUN {strpath, ...}) => strpath
                      | SOME (T.TYSPEC {strpath,...}) => strpath
                      | SOME (T.TYOPAQUE{spec = {strpath,...}, ...}) => strpath
      in
        {
         name = name, 
         strpath = strpath, 
         tyargs = tyargs, 
         body = body
        }
      end

  and substTyConInTyBindInfo switch (tyConSubst:tyConSubst) tyBindInfo =
      case tyBindInfo of
        T.TYCON {tyCon, datacon} => 
        let
          val tyCon = substTyConInTyCon switch tyConSubst tyCon
          val datacon = substTyConInDataCon switch tyConSubst datacon
        in 
          T.TYCON {tyCon = tyCon, datacon = datacon}
        end
      | T.TYFUN tyFun => 
        let
          val tyFun = substTyConInTyFun switch tyConSubst tyFun
        in 
          T.TYFUN tyFun
        end
      | T.TYOPAQUE {spec = spec as {name, strpath, id, eqKind, ...}, impl} => 
        let
          val newImpl = substTyConInTyBindInfo switch tyConSubst impl
        in
          case TyConID.Map.find(tyConSubst, id) of
            NONE =>  T.TYOPAQUE {spec = spec, impl = newImpl}
          | SOME tyBindInfo2 => 
            if (!eqKind = T.EQ) andalso not (TU.admitEqTyBindInfo tyBindInfo2)
            then
              raise ExTySpecInstantiatedWithNonEqTyBindInfo(name)
            else
              case tyBindInfo2 of
                T.TYCON {tyCon, datacon} =>
                if switch = true then tyBindInfo2
                else
                  T.TYCON
                    {tyCon =
                     {
                      name = name , 
                      strpath = strpath,
                      abstract = #abstract tyCon, 
                      tyvars = #tyvars tyCon,
                      id = #id tyCon,
                      eqKind = #eqKind tyCon,
                      constructorHasArgFlagList =
                        #constructorHasArgFlagList tyCon
                     },
                     datacon = datacon}
              | T.TYFUN tyFun =>
                if switch then tyBindInfo2
                else
                  T.TYFUN
                    {name = name,
                     strpath = strpath,
                     tyargs = #tyargs tyFun,
                     body = #body tyFun}
              | T.TYOPAQUE {spec, impl} => 
                if switch then tyBindInfo2
                else
                  T.TYOPAQUE
                    {spec =
                     {
                      name = name,
                      strpath = strpath,
                      id = #id spec,
                      abstract = #abstract spec,
                      eqKind = #eqKind spec,
                      tyvars = #tyvars spec,
                      constructorHasArgFlagList =
                        #constructorHasArgFlagList spec
                     },
                     impl = impl}
              | T.TYSPEC spec => 
                if switch then tyBindInfo2
                else
                  T.TYSPEC
                    {name = name,
                     strpath = strpath,
                     id = #id spec,
                     abstract = #abstract spec,
                     eqKind = #eqKind spec,
                     tyvars = #tyvars spec,
                     constructorHasArgFlagList =
                       #constructorHasArgFlagList spec
                    }
        end
      | T.TYSPEC {id, eqKind, name, strpath, ...} => 
        case TyConID.Map.find(tyConSubst, id) of
          NONE =>  tyBindInfo
        | SOME tyBindInfo2 => 
          if (!eqKind = T.EQ) andalso not (TU.admitEqTyBindInfo tyBindInfo2)
          then
            raise ExTySpecInstantiatedWithNonEqTyBindInfo(name)
          else
            case tyBindInfo2 of
              T.TYCON {tyCon, datacon} =>
              if switch = true then tyBindInfo2
              else
                T.TYCON
                  {tyCon =
                   {
                    name = name , 
                    strpath = strpath,
                    abstract = #abstract tyCon, 
                    tyvars = #tyvars tyCon,
                    id = #id tyCon,
                    eqKind = #eqKind tyCon,
                    constructorHasArgFlagList =
                      #constructorHasArgFlagList tyCon
                   },
                   datacon = datacon}
            | T.TYFUN tyFun =>
              if switch then tyBindInfo2
              else
                T.TYFUN
                  {name = name,
                   strpath = strpath,
                   tyargs = #tyargs tyFun,
                   body = #body tyFun}
            | T.TYOPAQUE {spec, impl} => 
              if switch then tyBindInfo2
              else
                T.TYOPAQUE
                  {spec =
                   {
                    name = name,
                    strpath = strpath,
                    id = #id spec,
                    abstract = #abstract spec,
                    eqKind = #eqKind spec,
                    tyvars = #tyvars spec,
                    constructorHasArgFlagList =
                    #constructorHasArgFlagList spec
                   },
                   impl = impl}
            | T.TYSPEC spec => 
              if switch then tyBindInfo2
              else
                T.TYSPEC
                  {
                   name = name,
                   strpath = strpath,
                   id = #id spec,
                   abstract = #abstract spec,
                   eqKind = #eqKind spec,
                   tyvars = #tyvars spec,
                   constructorHasArgFlagList =
                     #constructorHasArgFlagList spec
                  }
                              
     (*
      and substTyConInTyCon
          switch
          (tyConSubst : tyConSubst) 
          (tyCon
             as
             {name,
              strpath,
              abstract,
              tyvars,
              id=originId,
              eqKind,
              boxedKind,
              datacon} : T.tyCon) 
          =
          let
            val newTyCon =
                case TyConID.Map.find(tyConSubst, originId) of
                  NONE => 
                  let
                    val data =
                        substTyConInDataCon switch tyConSubst datacon
                  in
                    {name = name,
                     strpath = strpath,
                     abstract = abstract,  
                     tyvars = tyvars,
                     id = originId,
                     eqKind = eqKind,
                     boxedKind = boxedKind,
                     datacon = data}
                  end
                | SOME (T.TYFUN (tyFun as {tyargs, body, ...})) =>
                  let
                    val tyName as {name = newName, 
                                   strpath = newStrpath, 
                                   tyvars = newTyvars, 
                                   id = newId, 
                                   eqKind = newEqKind,
                                   tagNum = newTagNum} =
                        TU.tyFunToTyName tyFun
                    val newTyCon : T.tyCon = 
                        if switch then
                          {name = newName ,
                           strpath = newStrpath,
                           abstract = abstract,  
                           tyvars = newTyvars,
                           id = newId,
                           eqKind = newEqKind,
                           boxedKind = ref (TU.boxedKindOfType body), 
                           datacon = SEnv.empty}
                        else 
                          {name = name ,
                           strpath = strpath,
                           abstract = abstract,  
                           tyvars = newTyvars,
                           id = newId,
                           eqKind = newEqKind,
                           boxedKind = ref (TU.boxedKindOfType body), 
                           datacon = SEnv.empty}
                    val tyConSubst =
                        TyConID.Map.insert
                          (tyConSubst, originId, T.TYCON newTyCon)
                    val data = substTyConInDataCon switch tyConSubst datacon
                    val newTyCon = 
                        {
                         name = #name newTyCon,
                         strpath = #strpath newTyCon,
                         abstract = #abstract newTyCon,
                         tyvars = #tyvars newTyCon,
                         id = #id newTyCon,
                         eqKind = #eqKind newTyCon,
                         boxedKind = #boxedKind newTyCon,
                         datacon = data
                        }
                  in
                    newTyCon
                  end 
                | SOME
                    (T.TYCON
                       (tyCon
                          as
                          {name = newName, 
                           strpath = newStrpath,
                           abstract = newAbstract,
                           tyvars = newTyvars, 
                           id = newId,
                           eqKind = newEqKind,
                           boxedKind = newBoxedKind,
                           datacon = newDatacon}))
                  =>
                  if switch then
                    tyCon
                  else
                    {name = name ,
                     strpath = strpath,
                     abstract = newAbstract,
                     tyvars = newTyvars,
                     id = newId,
                     eqKind = newEqKind,
                     boxedKind = newBoxedKind,
                     datacon = newDatacon}
                | SOME
                    (T.TYSPEC
                       {
                        spec = {name = newName, 
                                strpath = newStrpath,
                                id = newId, 
                                eqKind = newEqKind, 
                                tyvars = newTyvars,
                                boxedKind = newBoxedKind},
                        impl = impl
                       }
                    ) 
                  =>
                  let
                    val newTyCon : T.tyCon =
                        if switch then
                          {
                           name = newName ,
                           abstract = abstract,
                           strpath = newStrpath,
                           tyvars = newTyvars,
                           id = newId,
                           eqKind = ref newEqKind,
                           boxedKind = ref newBoxedKind,
                           datacon = SEnv.empty
                          }
                        else
                          {
                           name = name ,
                           abstract = abstract,
                           strpath = strpath,
                           tyvars = newTyvars,
                           id = newId,
                           eqKind = ref newEqKind,
                           boxedKind = ref newBoxedKind,
                           datacon = SEnv.empty
                          }
                    val tyConSubst =
                        TyConID.Map.singleton(originId, T.TYCON newTyCon)
                    val data = substTyConInDataCon switch tyConSubst datacon
                    val newTyCon =
                        {
                         name = #name newTyCon,
                         strpath = #strpath newTyCon,
                         abstract = #abstract newTyCon,
                         tyvars = #tyvars newTyCon,
                         id = #id newTyCon,
                         eqKind = #eqKind newTyCon,
                         boxedKind = #boxedKind newTyCon,
                         datacon = data
                        }
                  in
                    newTyCon
                  end
          in
            newTyCon
          end
      *)                                
  and substTyConInTyCon
        switch
        (tyConSubst : tyConSubst) 
        (tyCon
           as
           {
            name,
            strpath,
            abstract,
            tyvars,
            id = originId,
            eqKind, constructorHasArgFlagList
           } : T.tyCon)
      =
      case TyConID.Map.find(tyConSubst, originId) of
        NONE => tyCon
      | SOME (T.TYFUN (tyFun as {tyargs, body, ...})) =>
        let
          val tyCon = TU.tyFunToTyCon tyFun
          val newTyCon : T.tyCon = 
              if switch then
                {
                 name = #name tyCon ,
                 strpath = #strpath tyCon,
                 abstract = abstract,  
                 tyvars = #tyvars tyCon,
                 id = #id tyCon,
                 eqKind = #eqKind tyCon,
                 constructorHasArgFlagList = #constructorHasArgFlagList tyCon
                }
              else 
                {name = name ,
                 strpath = strpath,
                 abstract = abstract,  
                 tyvars = #tyvars tyCon,
                 id = #id tyCon,
                 eqKind = #eqKind tyCon,
                 constructorHasArgFlagList = constructorHasArgFlagList
                }
        in
          newTyCon
        end 
      | SOME (T.TYCON {tyCon, datacon}) =>
        if switch then
          {name = #name tyCon,
           strpath = #strpath tyCon,
           abstract = #abstract tyCon,
           tyvars = #tyvars tyCon, 
           id = #id tyCon,
           eqKind = #eqKind tyCon,
           constructorHasArgFlagList = #constructorHasArgFlagList tyCon}
        else
          {name = name ,
           strpath = strpath,
           abstract = #abstract tyCon,
           tyvars = #tyvars tyCon,
           id = #id tyCon,
           eqKind = #eqKind tyCon,
           constructorHasArgFlagList = #constructorHasArgFlagList tyCon}
      | SOME (T.TYOPAQUE {spec, impl}) =>
        let
          val newTyCon : T.tyCon =
              if switch then
                {
                 name = #name spec ,
                 abstract = #abstract spec,
                 strpath = #strpath spec,
                 tyvars = #tyvars spec,
                 id = #id spec,
                 eqKind = #eqKind spec,
                 constructorHasArgFlagList = constructorHasArgFlagList
                }
              else
                {
                 name = name ,
                 strpath = strpath,
                 abstract = abstract,
                 tyvars = #tyvars spec,
                 id = #id spec,
                 eqKind = #eqKind spec,
                 constructorHasArgFlagList = constructorHasArgFlagList
                }
        in
          newTyCon
        end
      | SOME (T.TYSPEC tyCon) =>
        let
          val newTyCon : T.tyCon =
              if switch then
                {
                 name = #name tyCon ,
                 abstract = #abstract tyCon,
                 strpath = #strpath tyCon,
                 tyvars = #tyvars tyCon,
                 id = #id tyCon,
                 eqKind = #eqKind tyCon,
                 constructorHasArgFlagList = constructorHasArgFlagList
                }
              else
                {
                 name = name ,
                 strpath = strpath,
                 abstract = abstract,
                 tyvars = #tyvars tyCon,
                 id = #id tyCon,
                 eqKind = #eqKind tyCon,
                 constructorHasArgFlagList = constructorHasArgFlagList
                }
        in
          newTyCon
        end

  and substTyConInTyConEnv switch (tyConSubst:tyConSubst) tyConEnv =
      NPEnv.foldli
        (fn (tyConNamePath, tyBindInfo, newTyConEnv) =>
            let
              val tyBindInfo = 
                  substTyConInTyBindInfo switch tyConSubst tyBindInfo
            in
              NPEnv.insert(newTyConEnv,
                           tyConNamePath,
                           tyBindInfo)
            end
        )
        NPEnv.empty
        tyConEnv

  and substTyConInVarEnv switch (tyConSubst:tyConSubst) varEnv =
      NPEnv.foldli
        (fn (label, idstate, varEnv) =>
            case idstate of
              T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
              let
                val ty = substTyConInTy switch tyConSubst ty
                val newTyCon = 
                    substTyConInTyCon switch tyConSubst tyCon
              in
                NPEnv.insert
                  (
                   varEnv,
                   label,
                   T.CONID{namePath = namePath, 
                         funtyCon = funtyCon, 
                         ty = ty,
                         tag = tag,
                         tyCon = newTyCon}
                  )
              end
            | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
              let
                val ty = substTyConInTy switch tyConSubst ty
                val newTyCon = substTyConInTyCon switch tyConSubst tyCon
              in
                NPEnv.insert
                  (
                   varEnv,
                   label,
                   T.EXNID{namePath = namePath, 
                         funtyCon = funtyCon, 
                         ty = ty,
                         tag = tag,
                         tyCon = newTyCon}
                  )
              end
            | T.VARID {namePath, ty} =>
              let
                val ty = substTyConInTy switch tyConSubst ty
              in
                NPEnv.insert
                  (
                   varEnv,
                   label,
                   T.VARID{namePath = namePath, ty = ty}
                  )
              end
            | T.RECFUNID ({namePath, ty}, int) =>
              let
                val ty = substTyConInTy switch tyConSubst ty
              in
                NPEnv.insert(
                varEnv,
                label,
                T.RECFUNID ({namePath = namePath, ty = ty}, int)
                )
              end
            | T.PRIM x => NPEnv.insert(varEnv,label, T.PRIM x)
            | T.OPRIM x => NPEnv.insert(varEnv,label, T.OPRIM x)
        )
        NPEnv.empty
        varEnv

  and substTyConInDataCon switch (tyConSubst:tyConSubst) datacon =
      SEnv.foldli
        (fn (label, idstate, varEnv) =>
            case idstate of
              T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
              let
                val ty = substTyConInTy switch tyConSubst ty
                val newTyCon = substTyConInTyCon switch tyConSubst tyCon
              in
                SEnv.insert
                  (
                   varEnv,
                   label,
                   T.CONID{namePath = namePath, 
                         funtyCon=funtyCon, 
                         ty = ty,
                         tag = tag,
                         tyCon = newTyCon}
                  )
              end
            | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
              let
                val ty = substTyConInTy switch tyConSubst ty
                val newTyCon = substTyConInTyCon switch tyConSubst tyCon
              in
                SEnv.insert
                  (
                   varEnv,
                   label,
                   T.EXNID{namePath = namePath, 
                         funtyCon=funtyCon, 
                         ty = ty,
                         tag = tag,
                         tyCon = newTyCon}
                  )
              end
            | x =>
              raise Control.Bug "non CONID  in datacon (substTyConInDatacon)"
        )
        SEnv.empty
        datacon

  and substTyConInEnv switch (tyConSubst:tyConSubst) (tyConEnv, varEnv) =
      let
        val tyConEnv = substTyConInTyConEnv switch tyConSubst tyConEnv
        val varEnv = substTyConInVarEnv switch tyConSubst varEnv
      in
        (tyConEnv, varEnv)
      end

  (* this utility function makes sense only when applied to Env *)
  and substTyConInContext 
        switch
        (tyConSubst : tyConSubst)
        ({tyConEnv, varEnv, sigEnv, funEnv} : TC.context) = 
      let
        val tyConEnv = substTyConInTyConEnv switch tyConSubst tyConEnv
        val varEnv = substTyConInVarEnv switch tyConSubst varEnv
      in
        {
         tyConEnv =  tyConEnv,
         varEnv =  varEnv,
         sigEnv =  sigEnv,
         funEnv =  funEnv
        } : TC.context
      end


 (* We maintain two substitution variants here. The reason is that 
  * some substitution should substite all the fields like "strpath, name",etc, 
  * while other subsitutution should keep the original, which is 
  * critical to PrinterCodeGeneration. Printer code generation
  * use these information to generate formatter names.
  * For example, a mapping f: ID -> tyBindInfo
  *        { 1 -> {strpath = A, name = t, ....}
  * when apply it to the following tyCon,
  *        {strpath = B,  name = s, id = 1 ,...}
  * it will result in 
  *        {strpath = A, name = t, ....}
  * Formatter names changes.
  * 
  * Several situtations for substitution:
  * (1) sharing in signature : We should keep the original.
  * (2) type replication : fully substitute the right type into the left type.
  * (3) functor body instantiation : We should keep the original.
  *)
  local
    val nameStrPathSubstSwitch = true
  in
    val substTyConInTyFully = substTyConInTy nameStrPathSubstSwitch
    val substTyConInTvKindFully = substTyConInTvKind nameStrPathSubstSwitch
    val substTyConInBtvKindFully = substTyConInBtvKind nameStrPathSubstSwitch
    val substTyConInTyFunFully = substTyConInTyFun nameStrPathSubstSwitch
    val substTyConInTyBindInfoFully =
        substTyConInTyBindInfo nameStrPathSubstSwitch
    val substTyConInTyConFully = substTyConInTyCon nameStrPathSubstSwitch
    val substTyConInTyConFully = substTyConInTyCon nameStrPathSubstSwitch
    val substTyConInTyConEnvFully = substTyConInTyConEnv nameStrPathSubstSwitch
    val substTyConInVarEnvFully = substTyConInVarEnv nameStrPathSubstSwitch
    val substTyConInDataConFully = substTyConInDataCon nameStrPathSubstSwitch
    val substTyConInEnvFully = substTyConInEnv nameStrPathSubstSwitch
    val substTyConInContextFully = substTyConInContext nameStrPathSubstSwitch 
  end

  local 
    val nameStrPathSubstSwitch = false
  in
    val substTyConInTyPartially = substTyConInTy nameStrPathSubstSwitch
    val substTyConInTvKindPartially = substTyConInTvKind nameStrPathSubstSwitch
    val substTyConInBtvKindPartially =
        substTyConInBtvKind nameStrPathSubstSwitch
    val substTyConInTyFunPartially = substTyConInTyFun nameStrPathSubstSwitch
    val substTyConInTyBindInfoPartially =
        substTyConInTyBindInfo nameStrPathSubstSwitch
    val substTyConInTyConPartially = substTyConInTyCon nameStrPathSubstSwitch
    val substTyConInTyConEnvPartially =
        substTyConInTyConEnv nameStrPathSubstSwitch
    val substTyConInVarEnvPartially = substTyConInVarEnv nameStrPathSubstSwitch
    val substTyConInEnvPartially = substTyConInEnv nameStrPathSubstSwitch
    val substTyConInContextPartially =
        substTyConInContext nameStrPathSubstSwitch 
  end

  fun substTyConInFunBindInfo tyConSubst (funBindInfo : T.funBindInfo) = 
      {
       funName = #funName funBindInfo,
       argName = #argName funBindInfo,
       functorSig =
       {
        generativeExnTagSet = #generativeExnTagSet (#functorSig funBindInfo),
	argTyConIdSet = #argTyConIdSet (#functorSig funBindInfo),
	argSigEnv = substTyConInEnvFully
                      tyConSubst
                      (#argSigEnv (#functorSig funBindInfo)),
        argStrPrefixedEnv = substTyConInEnvFully
                              tyConSubst
                              (#argStrPrefixedEnv (#functorSig funBindInfo)),
	body = (#1 (#body (#functorSig funBindInfo)),
                substTyConInEnvFully
                  tyConSubst
                  (#2 (#body (#functorSig funBindInfo)))
               )
       }
      } : T.funBindInfo
         
  fun substTyConInFunEnv tyConSubst funEnv = 
      SEnv.map (substTyConInFunBindInfo tyConSubst) funEnv
      
  fun substTyConIdInId tyConIdSubst id = 
      case TyConID.Map.find(tyConIdSubst,id) of
        SOME newId => newId
      | NONE => id

  fun substTyConIdOrIdEqKindInTy substFunction ty =
      TypeTransducer.mapTyPreOrder
        (fn ty =>
            case ty of
              T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
              let
                val tvKind =
                    substTyConIdOrIdEqKindInTvKind substFunction tvKind
                val _  = tvar := T.TVAR tvKind
              in
                (ty, true)
              end
            | T.RAWty {tyCon, args} => 
              (T.RAWty
                 {tyCon = substTyConIdOrIdEqKindInTyCon substFunction tyCon, 
                  args = args},
               true)
            | T.OPAQUEty {spec = {tyCon, args}, implTy} =>
              (T.OPAQUEty
                 {spec =
                  {tyCon = substTyConIdOrIdEqKindInTyCon substFunction tyCon, 
                   args = args}, 
                  implTy = implTy},
               true)
            | T.SPECty {tyCon, args} =>
              (T.SPECty
                 {
                  tyCon = substTyConIdOrIdEqKindInTyCon substFunction tyCon, 
                  args = args
                 },
               true)
            | T.POLYty {boundtvars, body} => 
              (T.POLYty
                 {
                  boundtvars =
                    IEnv.map
                      (substTyConIdOrIdEqKindInBtvKind substFunction)
                      boundtvars,
                  body = body},
               true)
            | _ => (ty, true))
        ty

  and substTyConIdOrIdEqKindInTvKind
        substFunction
        {lambdaDepth, id, recordKind, eqKind, tyvarName} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    (SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty =
                                 substTyConIdOrIdEqKindInTy substFunction ty
                           in
                             SEnv.insert(tySEnvMap, label, ty)
                           end)
                       SEnv.empty
                       tySEnvMap)
              in 
                T.REC tySEnvMap
              end
            | T.OVERLOADED tys => 
              let
                val tys = 
                    (foldr
                       (fn (ty, tys) =>
                           let
                             val ty =
                                 substTyConIdOrIdEqKindInTy substFunction ty
                           in
                             ty :: tys
                           end)
                       nil
                       tys)
              in 
                T.OVERLOADED tys
              end
      in
        (
         {
          lambdaDepth = lambdaDepth,
          id=id, 
          recordKind = recordKind,
          eqKind = eqKind,
          tyvarName = tyvarName}
        )
      end

  and substTyConIdOrIdEqKindInBtvKind
        substFunction
        {index, recordKind, eqKind} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    (SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty =
                                 substTyConIdOrIdEqKindInTy substFunction ty
                           in
                             SEnv.insert(tySEnvMap, label, ty)
                           end)
                       SEnv.empty
                       tySEnvMap)
              in
                T.REC tySEnvMap
              end
            | T.OVERLOADED tys => 
              let
                val tys = 
                    (foldr
                       (fn (ty, tys) =>
                           let
                             val ty =
                                 substTyConIdOrIdEqKindInTy substFunction ty
                           in
                             ty :: tys
                           end)
                       nil
                       tys)
              in
                T.OVERLOADED tys
              end
      in
        (
         {
          index=index, 
          recordKind = recordKind,
          eqKind = eqKind
         }
        )
      end

  and substTyConIdOrIdEqKindInTyCon substFunction tyCon = substFunction tyCon

  and substTyConIdOrIdEqKindInTyFun
        substFunction
        {name, strpath, tyargs, body} =
      let
        val tyargs =
            IEnv.foldri
              (fn (index, btvKind, tyargs) =>
                  let
                    val btvKind =
                        substTyConIdOrIdEqKindInBtvKind substFunction btvKind
                  in
                    IEnv.insert(tyargs, index, btvKind)
                  end)
              IEnv.empty
              tyargs
        val body = substTyConIdOrIdEqKindInTy substFunction body
      in
        {
         name = name, 
         strpath = strpath, 
         tyargs = tyargs, 
         body = body
        }
      end

  and substTyConIdOrIdEqKindInTyBindInfo substFunction tyBindInfo =
      case tyBindInfo of
        T.TYCON {tyCon, datacon} => 
        T.TYCON {tyCon = substTyConIdOrIdEqKindInTyCon substFunction tyCon,
               datacon = substTyConIdOrIdEqKindInDatacon substFunction datacon}
      | T.TYFUN tyFun =>
        T.TYFUN (substTyConIdOrIdEqKindInTyFun substFunction tyFun)
      | T.TYOPAQUE {spec, impl}=> 
        T.TYOPAQUE
          {spec = substTyConIdOrIdEqKindInTyCon substFunction spec , 
           impl = substTyConIdOrIdEqKindInTyBindInfo substFunction impl}
      | T.TYSPEC tyCon =>
        T.TYSPEC (substTyConIdOrIdEqKindInTyCon substFunction tyCon)
        
  and substTyConIdOrIdEqKindInTyConEnv substFunction tyConEnv =
      NPEnv.map (substTyConIdOrIdEqKindInTyBindInfo substFunction) tyConEnv
         
  and substTyConIdOrIdEqKindInIdstate substFunction idstate =
      case idstate of
        T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val ty = substTyConIdOrIdEqKindInTy substFunction ty
          val newTyCon = substTyConIdOrIdEqKindInTyCon substFunction tyCon
        in
          T.CONID{namePath = namePath, 
                funtyCon=funtyCon, 
                ty = ty,
                tag = tag,
                tyCon = newTyCon
               }
        end
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val ty = substTyConIdOrIdEqKindInTy substFunction ty
          val newTyCon = substTyConIdOrIdEqKindInTyCon substFunction tyCon
        in
          T.EXNID{namePath = namePath, 
                funtyCon=funtyCon, 
                ty = ty,
                tag = tag,
                tyCon = newTyCon
               }
        end
      | T.VARID {namePath, ty} =>
        let
          val ty = substTyConIdOrIdEqKindInTy substFunction ty
        in
          T.VARID {namePath = namePath, ty = ty}
        end
      | T.RECFUNID ({namePath, ty}, int)  => 
        let
          val ty = substTyConIdOrIdEqKindInTy substFunction ty
        in
          T.RECFUNID ({namePath = namePath, ty = ty} , int) 
        end
      | T.PRIM x => T.PRIM x
      | T.OPRIM x => T.OPRIM x
                        
  and substTyConIdOrIdEqKindInVarEnv substFunction varEnv =
      NPEnv.map (substTyConIdOrIdEqKindInIdstate substFunction) varEnv

  and substTyConIdOrIdEqKindInDatacon substFunction datacon =
      SEnv.map (substTyConIdOrIdEqKindInIdstate substFunction)
               datacon

  and substTyConIdOrIdEqKindInEnv substFunction (tyConEnv, varEnv) =
      let
        val tyConEnv = substTyConIdOrIdEqKindInTyConEnv substFunction tyConEnv
        val varEnv = substTyConIdOrIdEqKindInVarEnv substFunction varEnv
      in
        (tyConEnv, varEnv)
      end

  fun substTyConIdOrIdEqKindInTopVarEnv substFunction topVarEnv =
      SEnv.map (substTyConIdOrIdEqKindInIdstate substFunction) topVarEnv

  fun substTyConIdOrIdEqKindInTopTyConEnv substFunction topTyConEnv =
      SEnv.map (substTyConIdOrIdEqKindInTyBindInfo substFunction) topTyConEnv

  fun substTyConIdOrIdEqKindInTopEnv substFunction (tyConEnv, varEnv) =
      let
        val tyConEnv =
            substTyConIdOrIdEqKindInTopTyConEnv substFunction tyConEnv
        val varEnv = substTyConIdOrIdEqKindInTopVarEnv substFunction varEnv
      in
        (tyConEnv, varEnv)
      end

  fun tyConIDSubstFunction tyConIdSubst (tyCon : T.tyCon) =
      {
       name = #name tyCon, 
       strpath = #strpath tyCon,
       abstract = #abstract tyCon,
       tyvars = #tyvars tyCon,
       id = substTyConIdInId tyConIdSubst (#id tyCon),
       eqKind = #eqKind tyCon,
       constructorHasArgFlagList = #constructorHasArgFlagList tyCon
      }

  fun tyConIDEqSubstFunction tyConIdEqSubst (tyCon : T.tyCon) =
      let
        val (newId, newEqKind:T.eqKind) = 
            case TyConID.Map.find(tyConIdEqSubst,(#id tyCon)) of
              SOME (id, ek) => (id, ek)
            | NONE => ((#id tyCon), !(#eqKind tyCon))
      in
        {
         name = #name tyCon, 
         strpath = #strpath tyCon,
         abstract = #abstract tyCon,
         tyvars = #tyvars tyCon,
         id = newId,
         eqKind = ref newEqKind,
         constructorHasArgFlagList = #constructorHasArgFlagList tyCon
        }
      end

  fun substTyConIdInEnv tyConIdSubst Env =
      substTyConIdOrIdEqKindInEnv (tyConIDSubstFunction tyConIdSubst) Env

  fun substTyConIdInTopEnv tyConIdSubst Env =
      substTyConIdOrIdEqKindInTopEnv (tyConIDSubstFunction tyConIdSubst) Env

  fun substTyConIdInTyBindInfo tyConIdSubst tyBindInfo =
      substTyConIdOrIdEqKindInTyBindInfo
        (tyConIDSubstFunction tyConIdSubst)
        tyBindInfo

  fun substTyConIdInFunBindInfo
        tyConIdSubst
        (funBindInfo : T.funBindInfo) = 
      {
       funName = #funName funBindInfo,
       argName = #argName funBindInfo,
       functorSig =
       {
        generativeExnTagSet = #generativeExnTagSet (#functorSig funBindInfo),
	argTyConIdSet = #argTyConIdSet (#functorSig funBindInfo),
	argSigEnv = 
        substTyConIdInEnv tyConIdSubst (#argSigEnv (#functorSig funBindInfo)),
        argStrPrefixedEnv = 
          substTyConIdInEnv
            tyConIdSubst
            (#argStrPrefixedEnv (#functorSig funBindInfo)),
	body = (#1 (#body (#functorSig funBindInfo)),
                substTyConIdInEnv
                  tyConIdSubst
                  (#2 (#body (#functorSig funBindInfo)))
               )
       }
      } : T.funBindInfo
         
  fun substTyConIdInFunEnv tyConIdSubst funEnv = 
      SEnv.map (substTyConIdInFunBindInfo tyConIdSubst) funEnv
         
(***************************************************************************)
  fun substTyConIdEqInEnv tyConIdEqSubst Env =
      substTyConIdOrIdEqKindInEnv (tyConIDEqSubstFunction tyConIdEqSubst) Env

  fun substTyConIdEqInTyConEnv tyConIdEqSubst tyConEnv =
      substTyConIdOrIdEqKindInTyConEnv
        (tyConIDEqSubstFunction tyConIdEqSubst) tyConEnv

  fun substTyConIdEqInVarEnv tyConIdEqSubst varEnv =
      substTyConIdOrIdEqKindInVarEnv
        (tyConIDEqSubstFunction tyConIdEqSubst) varEnv

(****************************************************************************)
 (*
  fun substTyConIdEqKindInTy tyConIdEqSubst ty =
      TypeTransducer.mapTyPreOrder
        (fn ty =>
            case ty of
              T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
              let
                val tvKind =
                    substTyConIdEqKindInTvKind tyConIdEqSubst tvKind
                val _  = tvar := T.TVAR tvKind
              in
                (ty, true)
              end
            | CONty {tyCon, args} => 
              let
                val tyCon = substTyConIdEqKindInTyCon tyConIdEqSubst tyCon
              in (CONty {tyCon=tyCon, args = args}, true) end
            | T.POLYty {boundtvars, body} => 
              let
                val boundtvars = 
                    IEnv.foldli
                      (fn (index, btvKind, boundtvars) =>
                          let
                            val btvKind =
                                substTyConIdEqKindInBtvKind
                                  tyConIdEqSubst btvKind
                          in
                            IEnv.insert(boundtvars, index, btvKind)
                          end)
                      IEnv.empty
                      boundtvars
              in
                (T.POLYty{boundtvars = boundtvars, body = body}, true)
              end
            | _ => (ty, true))
        ty

  and substTyConIdEqKindInTvKind
        tyConIdEqSubst
        {lambdaDepth, id, recordKind, eqKind, tyvarName} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    (SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
                           in
                             SEnv.insert(tySEnvMap, label, ty)
                           end)
                       SEnv.empty
                       tySEnvMap)
              in 
                T.REC tySEnvMap
              end
            | T.OVERLOADED tys => 
              let
                val tys = 
                    (foldr
                       (fn (ty, tys) =>
                           let
                             val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
                           in
                             ty :: tys
                           end)
                       nil
                       tys)
              in 
                T.OVERLOADED tys
              end
      in
        (
         {
          lambdaDepth = lambdaDepth,
          id=id, 
          recordKind = recordKind,
          eqKind = eqKind,
          tyvarName = tyvarName}
        )
      end

  and substTyConIdEqKindInBtvKind tyConIdEqSubst {index, recordKind, eqKind} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    (SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
                           in
                             SEnv.insert(tySEnvMap, label, ty)
                           end)
                       SEnv.empty
                       tySEnvMap)
              in
                T.REC tySEnvMap
              end
            | T.OVERLOADED tys => 
              let
                val tys = 
                    (foldr
                       (fn (ty, tys) =>
                           let
                             val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
                           in
                             ty :: tys
                           end)
                       nil
                       tys)
              in
                T.OVERLOADED tys
              end
      in
        (
         {
          index=index, 
          recordKind = recordKind,
          eqKind = eqKind
         }
        )
      end

  and substTyConIdEqKindInTyCon 
        tyConIdEqSubst
        ({name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon}
         :T.tyCon) 
    =
    let 
      val newDatacon = substTyConIdEqKindInDataCon tyConIdEqSubst datacon
      val (newId, newEqKind:T.eqKind) = 
          case TyConID.Map.find(tyConIdEqSubst,id) of
            SOME (id, ek) => (id, ek)
          | NONE => (id, !eqKind)
    in
      {
       name = name, 
       strpath = strpath,
       abstract = abstract,
       tyvars = tyvars,
       id = newId,
       eqKind = ref newEqKind,
       boxedKind = boxedKind,
       datacon = newDatacon
      }
    end

  and substTyConIdEqKindInTyCon
        tyConIdEqSubst
        (tyCon
           as
           {name, strpath, abstract, tyvars, id, eqKind, boxedKind, tagNum}) 
    =
    let
      val (newId, newEqKind) = 
          case TyConID.Map.find(tyConIdEqSubst,id) of
            SOME (id, ek) => (id, ek)
          | NONE => (id, !eqKind)
    in
      {
       name = name, 
       strpath = strpath,
       abstract = abstract,
       tyvars = tyvars,
       id = newId,
       eqKind = ref newEqKind,
       boxedKind = boxedKind,
       tagNum = tagNum
      }
    end
    
  and substTyConIdEqKindInTyFun tyConIdEqSubst {name, strpath, tyargs, body} =
      let
        val tyargs =
            IEnv.foldri
              (fn (index, btvKind, tyargs) =>
                  let
                    val btvKind =
                        substTyConIdEqKindInBtvKind tyConIdEqSubst btvKind
                  in
                    IEnv.insert(tyargs, index, btvKind)
                  end)
              IEnv.empty
              tyargs
        val body = substTyConIdEqKindInTy tyConIdEqSubst body
      in
        {
         name = name, 
         strpath = strpath, 
         tyargs = tyargs, 
         body = body
        }
      end

  and substTyConIdEqKindInSpec 
        tyConIdEqSubst
        (tyspec as {name, strpath, id, eqKind, tyvars, boxedKind}) =
      let
        val (newId, newEqKind) = 
            case TyConID.Map.find(tyConIdEqSubst,id) of
              SOME (id, ek : T.eqKind) => (id, ek)
            | NONE => (id, eqKind)
      in
        {name=name, 
         id= newId,
         strpath = strpath, 
         eqKind = newEqKind, 
         tyvars = tyvars,
         boxedKind = boxedKind
        }
      end

  and substTyConIdEqKindInTyBindInfo tyConIdEqSubst tyBindInfo =
      case tyBindInfo of
        USERDEFINEDTYCON {tyCon, args}  => 
        USERDEFINEDTYCON
          {T.TYCON (substTyConIdEqKindInTyCon tyConIdEqSubst tyCon)
      | T.TYFUN tyFun => 
        T.TYFUN (substTyConIdEqKindInTyFun tyConIdEqSubst tyFun)
      | T.TYSPEC {spec = spec , impl = impl}=> 
        case impl of
          NONE =>
          T.TYSPEC
            {spec = substTyConIdEqKindInSpec tyConIdEqSubst spec, impl = NONE}
        | SOME tyBindInfo => 
          let
            val tyBindInfo =
                substTyConIdEqKindInTyBindInfo tyConIdEqSubst tyBindInfo
          in
            T.TYSPEC
              {spec = substTyConIdEqKindInSpec tyConIdEqSubst spec,
               impl = SOME tyBindInfo}
          end
          
  and substTyConIdEqKindInTyConEnv tyConIdEqSubst tyConEnv =
      let
        val tyConEnv =
            NPEnv.foldli
              (fn (label, tyCon, tyConEnv) =>
                  let
                    val tyCon =
                        substTyConIdEqKindInTyBindInfo tyConIdEqSubst tyCon
                  in
                    NPEnv.insert(tyConEnv, label, tyCon)
                  end)
              NPEnv.empty
              tyConEnv
      in
        tyConEnv
      end

  and substTyConIdEqKindInIdstate tyConIdEqSubst idstate =
      case idstate of
        T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
          val newTyCon = substTyConIdEqKindInTyCon tyConIdEqSubst tyCon
        in
          T.CONID{namePath = namePath, 
                funtyCon=funtyCon, 
                ty = ty,
                tag = tag,
                tyCon = newTyCon
               }
        end
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
          val newTyCon = substTyConIdEqKindInTyCon tyConIdEqSubst tyCon
        in
          T.EXNID{namePath = namePath, 
                funtyCon=funtyCon, 
                ty = ty,
                tag = tag,
                tyCon = newTyCon
               }
        end
      | T.VARID {namePath, ty} =>
        let
          val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
        in
          T.VARID {namePath = namePath, ty = ty}
        end
      | T.RECFUNID ({namePath, ty}, int)  => 
        let
          val ty = substTyConIdEqKindInTy tyConIdEqSubst ty
        in
          T.RECFUNID ({namePath = namePath, ty = ty} , int) 
        end
      | T.PRIM x => T.PRIM x
      | T.OPRIM x => T.OPRIM x
                         
  and substTyConIdEqKindInVarEnv tyConIdEqSubst varEnv =
      NPEnv.map (substTyConIdEqKindInIdstate tyConIdEqSubst) varEnv

  and substTyConIdEqKindInDataCon tyConIdEqSubst datacon =
      SEnv.map (substTyConIdEqKindInIdstate tyConIdEqSubst)
               datacon

  and substTyConIdEqKindInEnv tyConIdEqSubst (tyConEnv, varEnv) =
      let
        val tyConEnv = substTyConIdEqKindInTyConEnv tyConIdEqSubst tyConEnv
        val varEnv = substTyConIdEqKindInVarEnv tyConIdEqSubst varEnv
      in
        (tyConEnv, varEnv)
      end
 *)
(*****************************************************************************)
  and getTyFunTyvar (tyFun as {body,...}) =
      TU.EFTV body
         
  and getIdStateTyvars idState = 
      case idState of
        T.VARID({ty,...}) => TU.EFTV ty
      | T.CONID({ty,...}) => TU.EFTV ty
      | T.EXNID({ty,...}) => TU.EFTV ty
      | T.PRIM({ty,...}) => TU.EFTV ty
      | T.OPRIM({ty,...}) => TU.EFTV ty
      | T.RECFUNID({ty,...},_) => TU.EFTV ty

  and tyvarsTyList tys = 
      foldl (fn (ty, set) =>
                OTSet.union (set, TU.EFTV ty))
            tys

  and tyvarsTE tyConEnv =
      let
        fun tyvarsTyBindInfo tyBindInfo =
            case tyBindInfo of 
              T.TYCON {tyCon, datacon} => tyvarsDataCon datacon
            | T.TYFUN(tyFun) =>  getTyFunTyvar tyFun
            | T.TYSPEC _ => OTSet.empty
            | T.TYOPAQUE {spec, impl} => tyvarsTyBindInfo impl
      in
        NPEnv.foldl (fn(tyBindInfo, T) => 
                       OTSet.union(T, tyvarsTyBindInfo tyBindInfo))
                    OTSet.empty 
                    tyConEnv
      end

  and tyvarsVE (varEnv:T.varEnv) =
      NPEnv.foldl  
        (fn(idState, T) =>OTSet.union (T, (getIdStateTyvars idState)))
        OTSet.empty
        varEnv

  and tyvarsDataCon datacon =
      SEnv.foldl  
        (fn (idState, T) =>OTSet.union (T, (getIdStateTyvars idState)))
        OTSet.empty
        datacon

  and tyvarsE (tyConEnv, varEnv) =
      OTSet.union (tyvarsTE tyConEnv,tyvarsVE varEnv)

  and tyvarsG (sigEnv : T.sigEnv) =
      SEnv.foldl
        (fn(T.SIGNATURE(T,{env = E, ...}), V) => OTSet.union(V,tyvarsE E))
        OTSet.empty 
        sigEnv
             
  and tyvarsContext (cc :TC.context) = 
      OTSet.union (tyvarsG (#sigEnv cc),
                   tyvarsE (#tyConEnv cc,
                            #varEnv   cc
                  ))


end (* end local *)
end
