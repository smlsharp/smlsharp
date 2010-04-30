structure NameMapPickler 
  : sig
      val namePath : NameMap.namePath Pickle.pu
      val functorInfo : NameMap.functorInfo Pickle.pu
      val basicNameMap : NameMap.basicNameMap Pickle.pu
      val topNameMap : NameMap.topNameMap Pickle.pu
      val NPEnv : 'a Pickle.pu -> 'a NameMap.NPEnv.map Pickle.pu
      val basicNameNPEnv : NameMap.basicNameNPEnv Pickle.pu
    end =
struct

  (***************************************************************************)

  structure P = Pickle
  structure NM = NameMap

  (***************************************************************************)

  val namePath = P.tuple2(P.string, NamePickler.path)
  val (tyStateFunctions, tyState) = P.makeNullPu (NM.NONDATATY (("", Path.NilPath)))
  val (idstateFunctions, idstate) = P.makeNullPu (NM.VARID (("", Path.NilPath)))
  val tyNameMap = EnvPickler.SEnv tyState
  val varNameMap = EnvPickler.SEnv idstate
  val (strNameMapEntryFunctions, strNameMapEntry) = 
      P.makeNullPu (NM.NAMEAUX 
                        {name = "",
                         wrapperSysStructure = NONE,
                         parentPath = Path.NilPath,
                         basicNameMap = (SEnv.empty, SEnv.empty, SEnv.empty)})
  val strNameMap = EnvPickler.SEnv strNameMapEntry
  val basicNameMap = P.tuple3(tyNameMap, varNameMap, strNameMap)
  val funNameMap = 
      EnvPickler.SEnv (P.conv
                           (
                            fn (arg, body) => 
                               {arg = arg, body = body},
                            fn {arg, body} => 
                                  (arg, body)
                           )
                           (P.tuple2(basicNameMap, strNameMapEntry)))
          
  val sigNameMap = EnvPickler.SEnv strNameMapEntry
  val (strKindFunctions, strKind) = P.makeNullPu NM.SYS


  fun NPEnv (value_pu : 'value P.pu) : 'value NameMap.NPEnv.map P.pu =
      NameMap.NPEnv.pu_map (namePath, value_pu)

  val varNameNPEnv = NPEnv idstate
  val tyNameNPEnv = NPEnv tyState
  val basicNameNPEnv = P.tuple2(tyNameNPEnv, varNameNPEnv)
  val funName_argName_argNamePathEnv_bodyNamePathEnv_bodyNameMap = 
      P.tuple5 (P.string, P.string, basicNameNPEnv, basicNameNPEnv, basicNameMap)
  (********************)


  val topNameMap = 
      P.conv
          (
           fn (varNameMap, tyNameMap, funNameMap, sigNameMap, strNameMap) => 
              {varNameMap = varNameMap, 
               tyNameMap = tyNameMap,
               funNameMap = funNameMap, 
               sigNameMap = sigNameMap,
               strNameMap = strNameMap},
           fn {varNameMap, tyNameMap, funNameMap, sigNameMap, strNameMap} => 
              (varNameMap, tyNameMap, funNameMap, sigNameMap, strNameMap)
          )
          (P.tuple5(varNameMap, tyNameMap, funNameMap, sigNameMap, strNameMap))

  val functorInfo : NameMap.functorInfo P.pu =
      P.conv
          (
           fn (funName, argName, argNamePathEnv, bodyNamePathEnv, bodyNameMap) => 
              {funName = funName, 
               argName = argName, 
               argNamePathEnv = argNamePathEnv, 
               bodyNamePathEnv = bodyNamePathEnv,
               bodyNameMap = bodyNameMap},
           fn {funName, argName, argNamePathEnv, bodyNamePathEnv, bodyNameMap} => 
              (funName, argName, argNamePathEnv, bodyNamePathEnv, bodyNameMap)
          )
          funName_argName_argNamePathEnv_bodyNamePathEnv_bodyNameMap

  val newTyState : NameMap.tyState P.pu =
      let
          fun toInt (NameMap.DATATY arg) = 0
            | toInt (NameMap.NONDATATY arg) = 1
          fun pu_DATATY pu = P.con1 NM.DATATY (fn NM.DATATY arg => arg
                                                | _ => raise Control.Bug "non DATATY in pu_DATATY") 
                                    (P.tuple2(namePath, varNameMap))
          fun pu_NONDATATY pu = P.con1 NM.NONDATATY
                                   (fn NM.NONDATATY arg => arg
                                     | _ => raise Control.Bug "non NONDATATY in pu_NONDATATY") 
                                   namePath
        in
          P.data (toInt, [pu_DATATY, pu_NONDATATY])
        end
  val _ = P.updateNullPu tyStateFunctions newTyState

  val newIdstate : NM.idstate P.pu =
      let
          fun toInt (NameMap.VARID arg) = 0
            | toInt (NameMap.CONID arg) = 1
            | toInt (NameMap.EXNID arg) = 2
          fun pu_VARID pu = 
              P.con1 
                  NM.VARID
                  (fn NM.VARID arg => arg
                    | _ => raise Control.Bug "non VARID in pu_VARID")
                  namePath
          fun pu_CONID pu = 
              P.con1 
                  NM.CONID
                  (fn NM.CONID arg => arg
                    | _ => raise Control.Bug "non CONID in pu_CONID")
                  namePath
          fun pu_EXNID pu = 
              P.con1 
                  NM.EXNID
                  (fn NM.EXNID arg => arg
                    | _ => raise Control.Bug "non EXNID in pu_EXNID")
                  namePath
        in
          P.data (toInt, [pu_VARID, pu_CONID, pu_EXNID])
        end
  val _ = P.updateNullPu idstateFunctions newIdstate

  val newStrKind : NM.strKind P.pu =
      let
          fun toInt (NM.SYS) = 0
            | toInt (NM.USR) = 1

          fun pu_SYS pu = P.con0 NM.SYS pu
          fun pu_USR pu = P.con0 NM.USR pu
        in
          P.data (toInt, [pu_SYS, pu_USR])
        end
  val _ = P.updateNullPu strKindFunctions newStrKind

  val newStrNameMapEntry : NM.strNameMapEntry P.pu =
      let
          val name_wrapper_strpath_basicNameMap = 
              P.conv
                  (fn (name, wrapperSysStructure, parentPath, basicNameMap) => 
                      {
                       name = name, 
                       wrapperSysStructure = wrapperSysStructure, 
                       parentPath = parentPath,
                       basicNameMap = basicNameMap},
                   fn {name, wrapperSysStructure, parentPath, basicNameMap} => 
                      (name, wrapperSysStructure, parentPath, basicNameMap))
                  (P.tuple4(P.string, 
                            P.option(P.string), 
                            NamePickler.path, 
                            basicNameMap))
              
          fun toInt (NameMap.NAMEAUX arg) = 0
          fun pu_NAMEAUX pu = P.con1 NM.NAMEAUX
                                     (fn NM.NAMEAUX arg => arg) 
                                     name_wrapper_strpath_basicNameMap
        in
          P.data (toInt, [pu_NAMEAUX])
        end
  val _ = P.updateNullPu strNameMapEntryFunctions newStrNameMapEntry
end
