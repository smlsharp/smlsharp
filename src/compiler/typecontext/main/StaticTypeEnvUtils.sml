(**
 * @author Liu Bochao
 * @version $Id: StaticTypeEnvUtils.sml,v 1.3 2006/06/17 07:36:14 bochao Exp $
 * @copyright (c) 2006, Tohoku University.
 *)
structure StaticTypeEnvUtils =
struct
(*
local 
    open TypeContext Types TypeContextUtils
in

  fun substTyConInSizeTagEnv visited tyConSubst (Env as (tyConSizeTagEnv, varEnv, strSizeTagEnv)) = 
      let
        val (visited,tyConSizeTagEnv) = 
            substTyConInTyConSizeTagEnv visited tyConSubst tyConSizeTagEnv
        val (visited,varEnv) = 
            substTyConInVarEnv visited tyConSubst varEnv
        val (visited,strSizeTagEnv) = 
            substTyConInStrSizeTagEnv  visited tyConSubst strSizeTagEnv
      in
        (visited,(tyConSizeTagEnv, varEnv, strSizeTagEnv))
      end

  and substTyConInTyConSizeTagEnv visited tyConSubst tyConSizeTagEnv =
      SEnv.foldli (fn (tyConName,{tyBindInfo, sizeInfo, tagInfo}, (visited, newTyConSizeTagEnv)) =>
                      let
                        val (visited,tyBindInfo) = 
                            substTyConInTyBindInfo  visited tyConSubst tyBindInfo
                      in
                        (visited,
                         SEnv.insert(newTyConSizeTagEnv,
                                     tyConName,
                                     {tyBindInfo = tyBindInfo,
                                      sizeInfo = sizeInfo,
                                      tagInfo = tagInfo})
                         )
                      end
                  )
                  (visited,SEnv.empty)
                  tyConSizeTagEnv

  and substTyConInStrSizeTagEnv visited tyConSubst strSizeTagEnv = 
        SEnv.foldri
          (fn
           (label, STRSIZETAG {id, name, strpath, env = Env, ...}, (visited, strEnv))
           =>
           let
             val (visited, Env) = substTyConInSizeTagEnv visited tyConSubst Env
             val strPathInfo = {id = id, name = name, strpath = strpath, env = Env}
           in
             (visited, SEnv.insert(strEnv, label, STRSIZETAG strPathInfo))
           end)
          (visited, SEnv.empty)
          strSizeTagEnv

  fun substTyConInTypeEnv tyConSubst (typeEnv as {tyConSizeTagEnv, varEnv, strSizeTagEnv}) =
      let
        val (visited,tyConSizeTagEnv) = 
            substTyConInTyConSizeTagEnv ID.Set.empty tyConSubst tyConSizeTagEnv
        val (visited,varEnv) = substTyConInVarEnv visited tyConSubst varEnv
        val (visited,strSizeTagEnv) = 
            substTyConInStrSizeTagEnv visited tyConSubst strSizeTagEnv
      in
        {tyConSizeTagEnv = tyConSizeTagEnv, 
         varEnv = varEnv,
         strSizeTagEnv = strSizeTagEnv}
      end

  fun substTyConIdInSizeTagExp tyConIdSubst sizeTagExp =
      case sizeTagExp of
          ST_CONST _ => sizeTagExp
        | ST_VAR id => ST_VAR (substTyConIdInId tyConIdSubst id)
        | ST_BDVAR _ => sizeTagExp
        | ST_APP {stfun = sizeTagExp, args = sizeTagExps} =>
          ST_APP {stfun = substTyConIdInSizeTagExp tyConIdSubst sizeTagExp, 
                  args = map (substTyConIdInSizeTagExp tyConIdSubst) sizeTagExps}
        | ST_FUN {args, body} => ST_FUN {args = args, body = substTyConIdInSizeTagExp tyConIdSubst body}
          
          
  fun substTyConIdInTyConSizeTagEnv visited tyConIdSubst tyConSizeTagEnv =
      let
          val (visited, tyConSizeTagEnv) =
              SEnv.foldli
                  (fn (label, {tyBindInfo, sizeInfo, tagInfo}, (visited, tyConSizeTagEnv)) =>
                      let
                          val (visited, tyBindInfo) = 
                              substTyConIdInTyBindInfo visited tyConIdSubst tyBindInfo
                          val sizeInfo =
                              substTyConIdInSizeTagExp tyConIdSubst sizeInfo
                          val tagInfo =
                              substTyConIdInSizeTagExp tyConIdSubst tagInfo
                      in
                          (visited, SEnv.insert(tyConSizeTagEnv, 
                                                label,
                                                {tyBindInfo = tyBindInfo,
                                                 sizeInfo = sizeInfo,
                                                 tagInfo = tagInfo}))
                      end)
                  (visited, SEnv.empty)
                  tyConSizeTagEnv
      in
          (visited, tyConSizeTagEnv)
      end

  fun substTyConIdInStrSizeTagEnv visited tyConIdSubst strSizeTagEnv =
      SEnv.foldri
          (fn
           (label, STRSIZETAG {id, name, strpath, env = Env}, (visited, strSizeTagEnv))
           =>
           let
               val (visited, Env) = substTyConIdInSizeTagEnv visited tyConIdSubst Env
               val strPathSizeTagInfo = {id = id, name = name, strpath = strpath, env = Env}
           in
               (visited, SEnv.insert(strSizeTagEnv, label, STRSIZETAG strPathSizeTagInfo))
           end)
          (visited, SEnv.empty)
          strSizeTagEnv

  and substTyConIdInSizeTagEnv visited tyConIdSubst (tyConSizeTagEnv, varEnv, strSizeTagEnv) =
      let
          val (visited, tyConSizeTagEnv) = 
              substTyConIdInTyConSizeTagEnv ID.Set.empty tyConIdSubst tyConSizeTagEnv
          val (visited, varEnv) = 
              substTyConIdInVarEnv visited tyConIdSubst varEnv 
          val (visited, strSizeTagEnv) = 
              substTyConIdInStrSizeTagEnv visited tyConIdSubst strSizeTagEnv
      in
          (visited, (tyConSizeTagEnv, varEnv, strSizeTagEnv))
      end
          
  fun substTyConIdInTypeEnv tyConIdSubst (typeEnv:StaticTypeEnv.typeEnv) =
      let
          val (visited, tyConSizeTagEnv) = 
              substTyConIdInTyConSizeTagEnv ID.Set.empty tyConIdSubst (#tyConSizeTagEnv typeEnv)
          val (visited, varEnv) = 
              substTyConIdInVarEnv visited tyConIdSubst (#varEnv typeEnv)
          val (visited, strSizeTagEnv) = 
              substTyConIdInStrSizeTagEnv visited tyConIdSubst (#strSizeTagEnv typeEnv)
      in
          {tyConSizeTagEnv = tyConSizeTagEnv,
           varEnv = varEnv,
           strSizeTagEnv =  strSizeTagEnv}
      end

  (**********************************************************************)         

  fun sizeTagSubstFromTyConSizeTagEnv (importTyConSizeTagEnv, implTyConSizeTagEnv) =
      SEnv.foldli 
          (fn (tyConName, {tyBindInfo, sizeInfo, tagInfo}, sizeTagSubst) =>
              case tyBindInfo of
                  TYSPEC {spec = {id,...}, impl = NONE} =>
                  (case SEnv.find (implTyConSizeTagEnv, tyConName) of
                       NONE => sizeTagSubst
                     | SOME {tyBindInfo, sizeInfo, tagInfo} =>
                       ID.Map.insert(sizeTagSubst, id, (sizeInfo, tagInfo)))
                | _ => sizeTagSubst)
          ID.Map.empty
          importTyConSizeTagEnv

  fun sizeTagSubstFromStrSizeTagEnv (importStrSizeTagEnv, implStrSizeTagEnv) =
      SEnv.foldli
      (fn (strName, 
           STRSIZETAG {env = (subTyConSizeTagEnv1, subVarEnv1, subStrSizeTagEnv1),...}, 
           sizeTagSubst) =>
          case SEnv.find(implStrSizeTagEnv, strName) of
              SOME (STRSIZETAG {env = (subTyConSizeTagEnv2, subVarEnv2, subStrSizeTagEnv2),...}) =>
                   let
                       val sizeTagSubst1 = 
                           sizeTagSubstFromTyConSizeTagEnv (subTyConSizeTagEnv1, subTyConSizeTagEnv2)
                       val sizeTagSubst2 =
                           sizeTagSubstFromStrSizeTagEnv (subStrSizeTagEnv1, subStrSizeTagEnv2)
                   in
                       ID.Map.unionWithi (fn _ => raise Control.Bug "duplicate tyConId")
                                         (sizeTagSubst,
                                          ID.Map.unionWithi (fn _ => raise Control.Bug "duplicate tyConId")
                                                            (sizeTagSubst1,sizeTagSubst2))
                   end
            | NONE => sizeTagSubst)
      ID.Map.empty
      importStrSizeTagEnv
                  

  fun sizeTagSubstFromEnv (importTypeEnv:StaticTypeEnv.typeEnv, implTypeEnv:StaticTypeEnv.typeEnv) =
      let
          val sizeTagSubst1 = 
              sizeTagSubstFromTyConSizeTagEnv (#tyConSizeTagEnv importTypeEnv,
                                               #tyConSizeTagEnv implTypeEnv)
          val sizeTagSubst2 =
              sizeTagSubstFromStrSizeTagEnv (#strSizeTagEnv importTypeEnv,
                                             #strSizeTagEnv implTypeEnv)
      in
          ID.Map.unionWithi (fn _ => raise Control.Bug "duplicate tyConId") 
                            (sizeTagSubst1, sizeTagSubst2)
      end

  (***********************************************************************************)
  local
      fun substSizeTagExp sizeFlag sizeTagSubst sizeTagExp =
          case sizeTagExp of
              ST_CONST _ => sizeTagExp
            | ST_VAR id => 
              (case ID.Map.find(sizeTagSubst, id) of
                   NONE => sizeTagExp
                 | SOME (sizeInfo, TagInfo) => 
                   if sizeFlag then sizeInfo else TagInfo)
            | ST_BDVAR _ => sizeTagExp
            | ST_APP {stfun, args} => ST_APP {stfun = substSizeTagExp sizeFlag sizeTagSubst stfun,
                                              args = map (substSizeTagExp sizeFlag sizeTagSubst) args}
            | ST_FUN {args, body} => ST_FUN {args = args,
                                             body = substSizeTagExp sizeFlag sizeTagSubst body}
  in
      fun substSizeInfo sizeTagSubst sizeExp =
          substSizeTagExp true sizeTagSubst sizeExp
      fun substTagInfo sizeTagSubst tagExp =
          substSizeTagExp false sizeTagSubst tagExp
  end
          
  fun substSizeTagTyConSizeTagEnv sizeTagSubst tyConSizeTagEnv =
      SEnv.map (fn {tyBindInfo, sizeInfo, tagInfo} =>
                   {tyBindInfo = tyBindInfo,
                    sizeInfo = substSizeInfo sizeTagSubst sizeInfo,
                    tagInfo = substSizeInfo sizeTagSubst tagInfo})
               tyConSizeTagEnv

  fun substSizeTagStrSizeTagEnv sizeTagSubst strSizeTagEnv =
      SEnv.map (fn STRSIZETAG {id, 
                               name, 
                               strpath, 
                               env = (subTyConSizeTagEnv, subVarEnv, subStrSizeTagEnv)} =>
                   let
                       val subTyConSizeTagEnv =
                           substSizeTagTyConSizeTagEnv sizeTagSubst subTyConSizeTagEnv
                       val subStrSizeTagEnv =
                           substSizeTagStrSizeTagEnv sizeTagSubst subStrSizeTagEnv
                   in
                       STRSIZETAG{id = id,
                                  name = name,
                                  strpath = strpath,
                                  env = (subTyConSizeTagEnv, subVarEnv, subStrSizeTagEnv)}
                   end)
               strSizeTagEnv

  fun substSizeTagTypeEnv sizeTagSubst (typeEnv:StaticTypeEnv.typeEnv) =
      {
       tyConSizeTagEnv = 
       substSizeTagTyConSizeTagEnv sizeTagSubst (#tyConSizeTagEnv typeEnv),
       varEnv = #varEnv typeEnv,
       strSizeTagEnv =
       substSizeTagStrSizeTagEnv sizeTagSubst (#strSizeTagEnv typeEnv)
       }

end*)
end