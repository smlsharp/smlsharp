(**
 * an optimization that allocates static objects statically.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure StaticAllocation : sig

  val optimize : YAANormal.topdecl list -> YAANormal.topdecl list

end =
struct

  structure AN = YAANormal
  structure CT = ConstantTerm

  type env =
      {
        topEnv: AN.topdecl SEnv.map,
        varEnv: AN.anvalue option VarID.Map.map,
        isToplevel: bool,
        clusterId: AN.clusterId,
        count: int ref
      }

  fun extendVarEnv ({topEnv, varEnv, isToplevel, clusterId, count}:env)
                   newVarEnv =
      {topEnv = topEnv,
       varEnv = VarID.Map.unionWith #2 (varEnv, newVarEnv),
       isToplevel = isToplevel,
       clusterId = clusterId,
       count = count} : env

  fun unionTopEnv (env1, env2) =
      SEnv.unionWith
        (fn (x,y) =>
            raise Control.Bug ("unionTopEnv:\n"
                               ^ Control.prettyPrint (AN.format_topdecl x)
                               ^ "\n" 
                               ^ Control.prettyPrint (AN.format_topdecl y)))
        (env1, env2)

  fun fmt3 n =
      StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.DEC n)

  (* assume that "ClusterID.toString clusterId" is locally unique *)
  fun newTopName ({clusterId, count, ...}:env) =
      "SA_C" ^ ClusterID.toString clusterId ^ "." ^ (fmt3 (!count))
      before count := !count + 1

  fun bindVars vars =
      foldl (fn ({id,...}:AN.varInfo, varEnv) =>
                VarID.Map.insert (varEnv, id, NONE))
            VarID.Map.empty
            vars

  fun optimizeValue varEnv anvalue =
      case anvalue of
        AN.ANINT _ => anvalue
      | AN.ANWORD _ => anvalue
      | AN.ANBYTE _ => anvalue
      | AN.ANCHAR _ => anvalue
      | AN.ANUNIT => anvalue
      | AN.ANVAR {id,...} =>
        (
          case VarID.Map.find (varEnv, id) of
            SOME (SOME value) => value
          | _ => anvalue
        )
      | AN.ANLABEL _ => anvalue
      | AN.ANLOCALCODE _ => anvalue
      | AN.ANGLOBALSYMBOL _ => anvalue

  fun isStatic value =
      case value of
        AN.ANINT _ => true
      | AN.ANWORD _ => true
      | AN.ANBYTE _ => true
      | AN.ANCHAR _ => true
      | AN.ANUNIT => true
      | AN.ANVAR _ => false
      | AN.ANLABEL _ => true
      | AN.ANLOCALCODE _ => false
      | AN.ANGLOBALSYMBOL _ => true

  fun toUInt32 (AN.ANWORD n) = n
    | toUInt32 (AN.ANINT n) =
      if n < 0 then raise Overflow else BasicTypes.SInt32ToUInt32 n
    | toUInt32 _ = raise Control.Bug "toUInt32"
  fun toFunLabel (AN.ANLABEL id) = id
    | toFunLabel _ = raise Control.Bug "toFunLabel: ANLABEL expected"

  local
    fun allocTop env topdeclFn =
        let
          val name = newTopName env
          val topdecl = topdeclFn name
        in
          SOME (SEnv.singleton (name, topdecl),
                AN.ANGLOBALSYMBOL {name = (name, AN.GLOBALSYMBOL),
                                   ann = AN.GLOBALOTHER,
                                   ty = AN.BOXED})
        end
  in

  fun allocateConst env const =
      case const of
        CT.INT n => SOME (SEnv.empty, AN.ANINT n)
      | CT.LARGEINT n => NONE
      | CT.WORD n => SOME (SEnv.empty, AN.ANWORD n)
      | CT.BYTE n => SOME (SEnv.empty, AN.ANBYTE n)
      | CT.STRING s =>
        allocTop env
          (fn name => AN.ANTOPCONST {globalName = name,
                                     export = false,
                                     constant = const})
      | CT.REAL _ => NONE
      | CT.FLOAT _ => NONE
      | CT.CHAR c => SOME (SEnv.empty, AN.ANCHAR c)
      | CT.UNIT => SOME (SEnv.empty, AN.ANUNIT)
      | CT.NULL => NONE

  fun allocateStatic env exp =
      case exp of
        AN.ANCONST const => allocateConst env const
      | AN.ANVALUE value =>
        if isStatic value then SOME (SEnv.empty, value) else NONE
      | AN.ANFOREIGNAPPLY _ => NONE
      | AN.ANCALLBACKCLOSURE _ => NONE
      | AN.ANENVACC _ => NONE
      | AN.ANGETFIELD _ => NONE
      | AN.ANARRAY {bitmap, totalSize, initialValue, elementTy, elementSize,
                    isMutable} =>
        (* assume that the toplevel is executed only once and has no loop. *)
        if (not isMutable orelse #isToplevel env)
           andalso List.all isStatic [bitmap, totalSize,
                                      initialValue, elementSize]
        then
          let
            val totalSize = toUInt32 totalSize
            val elementSize = toUInt32 elementSize
          in
            if totalSize mod elementSize = 0w0 then
              let
                val numElems = totalSize div elementSize
                val values = List.tabulate (BasicTypes.UInt32ToInt numElems,
                                            fn _ => initialValue)
              in
                allocTop env
                  (fn name =>
                      AN.ANTOPARRAY {globalName = name,
                                     export = false,
                                     bitmap = toUInt32 bitmap,
                                     totalSize = totalSize,
                                     initialValues = values,
                                     elementTy = elementTy,
                                     elementSize = elementSize,
                                     isMutable = isMutable})
              end
            else NONE
          end
          handle Overflow => NONE
        else NONE
      | AN.ANRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                     fieldTyList, isMutable} =>
        if List.all isStatic ([bitmap, totalSize] @ fieldList @ fieldSizeList)
        then
          allocTop env
            (fn name => 
                AN.ANTOPRECORD {globalName = name,
                                export = false,
                                bitmaps = [toUInt32 bitmap],
                                totalSize = toUInt32 totalSize,
                                fieldList = fieldList,
                                fieldTyList = fieldTyList,
                                fieldSizeList = map toUInt32 fieldSizeList,
                                isMutable = isMutable})
        else NONE
      | AN.ANENVRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                        fieldTyList, fixedSizeList} =>
        if List.all isStatic (bitmap :: fieldList @ fieldSizeList)
        then
          allocTop env
            (fn name =>
                AN.ANTOPRECORD {globalName = name,
                                export = false,
                                bitmaps = [toUInt32 bitmap],
                                totalSize = totalSize,
                                fieldList = fieldList,
                                fieldTyList = fieldTyList,
                                fieldSizeList = fixedSizeList,
                                isMutable = false})
        else NONE
      | AN.ANSELECT _ => NONE
      | AN.ANMODIFY _ => NONE
      | AN.ANPRIMAPPLY _ => NONE
      | AN.ANCLOSURE {funLabel, env=closEnv} =>
        if isStatic funLabel andalso isStatic closEnv
        then
          allocTop env
            (fn name =>
                AN.ANTOPCLOSURE {globalName = name,
                                 export = false,
                                 funLabel = toFunLabel funLabel,
                                 closureEnv = closEnv})
        else NONE
      | AN.ANRECCLOSURE _ => NONE
      | AN.ANAPPLY _ => NONE
      | AN.ANCALL _ => NONE
      | AN.ANRECCALL _ => NONE
      | AN.ANLOCALCALL _ => NONE

  end (* local *)

  fun optimizeExp varEnv exp =
      case exp of
        AN.ANCONST _ => exp
      | AN.ANVALUE value => AN.ANVALUE (optimizeValue varEnv value)

      | AN.ANFOREIGNAPPLY {function, argList, argTyList, resultTyList,
                           attributes} =>
        AN.ANFOREIGNAPPLY {function = optimizeValue varEnv function,
                           argList = map (optimizeValue varEnv) argList,
                           argTyList = argTyList,
                           resultTyList = resultTyList,
                           attributes = attributes}

      | AN.ANCALLBACKCLOSURE {funLabel, env,
                              argTyList, resultTyList, attributes} =>
        AN.ANCALLBACKCLOSURE {funLabel = optimizeValue varEnv funLabel,
                              env = optimizeValue varEnv env,
                              argTyList = argTyList,
                              resultTyList = resultTyList,
                              attributes = attributes}

      | AN.ANENVACC {nestLevel, offset, size, ty} =>
        AN.ANENVACC {nestLevel = nestLevel,
                     offset = offset,
                     size = optimizeValue varEnv size,
                     ty = ty}

      | AN.ANGETFIELD {array, offset, size, ty, needBoundaryCheck} =>
        AN.ANGETFIELD {array = optimizeValue varEnv array,
                       offset = optimizeValue varEnv offset,
                       size = optimizeValue varEnv size,
                       ty = ty,
                       needBoundaryCheck = needBoundaryCheck}

      | AN.ANARRAY {bitmap, totalSize, initialValue, elementTy, elementSize,
                    isMutable} =>
        AN.ANARRAY {bitmap = optimizeValue varEnv bitmap,
                    totalSize = optimizeValue varEnv totalSize,
                    initialValue = optimizeValue varEnv initialValue,
                    elementTy = elementTy,
                    elementSize = optimizeValue varEnv elementSize,
                    isMutable = isMutable}

      | AN.ANRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                     fieldTyList, isMutable} =>
        AN.ANRECORD {bitmap = optimizeValue varEnv bitmap,
                     totalSize = optimizeValue varEnv totalSize,
                     fieldList = map (optimizeValue varEnv) fieldList,
                     fieldSizeList = map (optimizeValue varEnv) fieldSizeList,
                     fieldTyList = fieldTyList,
                     isMutable = isMutable}

      | AN.ANENVRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                        fieldTyList, fixedSizeList} =>
        AN.ANENVRECORD
          {bitmap = optimizeValue varEnv bitmap,
           totalSize = totalSize,
           fieldList = map (optimizeValue varEnv) fieldList,
           fieldSizeList = map (optimizeValue varEnv) fieldSizeList,
           fieldTyList = fieldTyList,
           fixedSizeList = fixedSizeList}

      | AN.ANSELECT {record, nestLevel, offset, size, ty} =>
        AN.ANSELECT {record = optimizeValue varEnv record,
                     nestLevel = optimizeValue varEnv nestLevel,
                     offset = optimizeValue varEnv offset,
                     size = optimizeValue varEnv size,
                     ty = ty}

      | AN.ANMODIFY {record, nestLevel, offset, value, valueTy, valueSize,
                     valueTag} =>
        AN.ANMODIFY {record = optimizeValue varEnv record,
                     nestLevel = optimizeValue varEnv nestLevel,
                     offset = optimizeValue varEnv offset,
                     value = optimizeValue varEnv value,
                     valueTy = valueTy,
                     valueSize = optimizeValue varEnv valueSize,
                     valueTag = optimizeValue varEnv valueTag}

      | AN.ANPRIMAPPLY {prim, argList, argTyList, resultTyList,
                        instSizeList, instTagList} =>
        AN.ANPRIMAPPLY {prim = prim,
                        argList = map (optimizeValue varEnv) argList,
                        argTyList = argTyList,
                        resultTyList = resultTyList,
                        instSizeList = map (optimizeValue varEnv) instSizeList,
                        instTagList = map (optimizeValue varEnv) instTagList}

      | AN.ANCLOSURE {funLabel, env} =>
        AN.ANCLOSURE {funLabel = optimizeValue varEnv funLabel,
                      env = optimizeValue varEnv env}
 
      | AN.ANRECCLOSURE {funLabel} =>
        AN.ANRECCLOSURE {funLabel = optimizeValue varEnv funLabel}

      | AN.ANAPPLY {closure, argList, argTyList, resultTyList, argSizeList} =>
        AN.ANAPPLY {closure = optimizeValue varEnv closure,
                    argList = map (optimizeValue varEnv) argList,
                    argTyList = argTyList,
                    resultTyList = resultTyList,
                    argSizeList = argSizeList}

      | AN.ANCALL {funLabel, env, argList, argSizeList, argTyList,
                   resultTyList} =>
        AN.ANCALL {funLabel = optimizeValue varEnv funLabel,
                   env = optimizeValue varEnv env,
                   argList = map (optimizeValue varEnv) argList,
                   argSizeList = argSizeList,
                   argTyList = argTyList,
                   resultTyList = resultTyList}

      | AN.ANRECCALL {funLabel, argList, argSizeList, argTyList,
                      resultTyList} =>
        AN.ANRECCALL {funLabel = optimizeValue varEnv funLabel,
                      argList = map (optimizeValue varEnv) argList,
                      argSizeList = argSizeList,
                      argTyList = argTyList,
                      resultTyList = resultTyList}

      | AN.ANLOCALCALL {codeLabel, argList, argSizeList, argTyList,
                        resultTyList, returnLabel, knownDestinations} =>
        AN.ANLOCALCALL {codeLabel = optimizeValue varEnv codeLabel,
                        argList = map (optimizeValue varEnv) argList,
                        argSizeList = argSizeList,
                        argTyList = argTyList,
                        resultTyList = resultTyList,
                        returnLabel = returnLabel,
                        knownDestinations = knownDestinations}

  fun optimizeDecl (env as {topEnv, varEnv, ...}:env) decl =
      case decl of
        AN.ANSETFIELD {array, offset, value, valueTy, valueSize,
                       valueTag, needBoundaryCheck, loc} =>
        let
          val decl =
              AN.ANSETFIELD {array = optimizeValue varEnv array,
                             offset = optimizeValue varEnv offset,
                             value = optimizeValue varEnv value,
                             valueTy = valueTy,
                             valueSize = optimizeValue varEnv valueSize,
                             valueTag = optimizeValue varEnv valueTag,
                             needBoundaryCheck = needBoundaryCheck,
                             loc = loc}
        in
          case decl of
            AN.ANSETFIELD {array = AN.ANGLOBALSYMBOL {name=(name,_),...},
                           offset = AN.ANWORD 0w0,
                           value,
                           needBoundaryCheck = false, ...} =>
            if isStatic value
            then
              case SEnv.find (topEnv, name) of
                SOME (AN.ANTOPVAR {globalName, externalVarID, initialValue,
                                   elementTy, elementSize}) =>
                (
                  case initialValue of
                    SOME _ => raise Control.Bug "optimizeDecl: ANSETFIELD"
                  | NONE =>
                    (SEnv.singleton (globalName,
                                     AN.ANTOPVAR {globalName = globalName,
                                                  externalVarID = externalVarID,
                                                  initialValue = SOME value,
                                                  elementTy = elementTy,
                                                  elementSize = elementSize}),
                     VarID.Map.empty,
                     nil)
                )
              | _ => (SEnv.empty, VarID.Map.empty, [decl])
            else (SEnv.empty, VarID.Map.empty, [decl])
          | _ => (SEnv.empty, VarID.Map.empty, [decl])
        end

      | AN.ANSETTAIL {record, nestLevel, offset, value, valueTy, valueSize,
                      valueTag, loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANSETTAIL {record = optimizeValue varEnv record,
                        nestLevel = optimizeValue varEnv nestLevel,
                        offset = optimizeValue varEnv offset,
                        value = optimizeValue varEnv value,
                        valueTy = valueTy,
                        valueSize = optimizeValue varEnv valueSize,
                        valueTag = optimizeValue varEnv valueTag,
                        loc = loc}])

      | AN.ANCOPYARRAY {src, srcOffset, dst, dstOffset, length, elementTy,
                        elementSize, elementTag, loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANCOPYARRAY {src = optimizeValue varEnv src,
                          srcOffset = optimizeValue varEnv srcOffset,
                          dst = optimizeValue varEnv dst,
                          dstOffset = optimizeValue varEnv dstOffset,
                          length = optimizeValue varEnv length,
                          elementTy = elementTy,
                          elementSize = optimizeValue varEnv elementSize,
                          elementTag = optimizeValue varEnv elementTag,
                          loc = loc}])

      | AN.ANTAILAPPLY {closure, argList, argTyList, resultTyList, argSizeList,
                        loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANTAILAPPLY {closure = optimizeValue varEnv closure,
                          argList = map (optimizeValue varEnv) argList,
                          argTyList = argTyList,
                          resultTyList = resultTyList,
                          argSizeList = argSizeList,
                          loc = loc}])

      | AN.ANTAILCALL {funLabel, env, argList, argSizeList, argTyList,
                       resultTyList, loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANTAILCALL {funLabel = optimizeValue varEnv funLabel,
                         env = optimizeValue varEnv env,
                         argList = map (optimizeValue varEnv) argList,
                         argSizeList = argSizeList,
                         argTyList = argTyList,
                         resultTyList = resultTyList,
                         loc = loc}])

      | AN.ANTAILRECCALL {funLabel, argList, argSizeList, argTyList,
                          resultTyList, loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANTAILRECCALL {funLabel = optimizeValue varEnv funLabel,
                            argList = map (optimizeValue varEnv) argList,
                            argSizeList = argSizeList,
                            argTyList = argTyList,
                            resultTyList = resultTyList,
                            loc = loc}])

      | AN.ANTAILLOCALCALL {codeLabel, argList, argSizeList, argTyList,
                            resultTyList, loc, knownDestinations} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANTAILLOCALCALL {codeLabel = optimizeValue varEnv codeLabel,
                              argList = map (optimizeValue varEnv) argList,
                              argSizeList = argSizeList,
                              argTyList = argTyList,
                              resultTyList = resultTyList,
                              loc = loc,
                              knownDestinations = knownDestinations}])

      | AN.ANRETURN {valueList, tyList, sizeList, loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANRETURN {valueList = map (optimizeValue varEnv) valueList,
                       tyList = tyList,
                       sizeList = sizeList,
                       loc = loc}])

      | AN.ANLOCALRETURN {valueList, tyList, sizeList, loc,
                          knownDestinations} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANLOCALRETURN {valueList = map (optimizeValue varEnv) valueList,
                            tyList = tyList,
                            sizeList = sizeList,
                            loc = loc,
                            knownDestinations = knownDestinations}])

      | AN.ANVAL {varList, sizeList, exp, loc} =>
        let
          val exp = optimizeExp varEnv exp
        in
          case (varList, allocateStatic env exp) of
            ([var], SOME (newTopEnv, value)) =>
            (newTopEnv, VarID.Map.singleton (#id var, SOME value), nil)
          | _ =>
            (SEnv.empty, bindVars varList,
             [AN.ANVAL {varList = varList,
                        sizeList = sizeList,
                        exp = exp,
                        loc = loc}])
        end

      | AN.ANVALCODE {codeList, loc} =>
        let
          val (topEnv, codeList) = optimizeCodeDeclList env codeList
        in
          (topEnv, VarID.Map.empty,
           [AN.ANVALCODE {codeList = codeList, loc = loc}])
        end

      | AN.ANMERGE {label, varList, loc} =>
        let
          val decls =
              List.mapPartial
                (fn var =>
                    case optimizeValue varEnv (AN.ANVAR var) of
                      AN.ANVAR _ => NONE
                    | value =>
                      SOME (AN.ANVAL {varList = [var],
                                      sizeList = [AN.SIIGNORE],
                                      exp = AN.ANVALUE value,
                                      loc = loc}))
                varList
        in
          (SEnv.empty, VarID.Map.empty, decls @ [decl])
        end

      | AN.ANMERGEPOINT {label, varList, leaveHandler, loc} =>
        (SEnv.empty, bindVars varList,
         [AN.ANMERGEPOINT {label = label,
                           varList = varList,
                           leaveHandler = leaveHandler,
                           loc = loc}])

      | AN.ANRAISE {value, loc} =>
        (SEnv.empty, VarID.Map.empty,
         [AN.ANRAISE {value = optimizeValue varEnv value,
                      loc = loc}])

      | AN.ANHANDLE {try, exnVar, handler, labels, loc} =>
        let
          val (topEnv1, try) = optimizeDeclList env try
          val newVarEnv = VarID.Map.singleton (#id exnVar, NONE)
          val handlerEnv = extendVarEnv env newVarEnv
          val (topEnv2, handler) = optimizeDeclList handlerEnv handler
        in
          (unionTopEnv (topEnv1, topEnv2), VarID.Map.empty,
           [AN.ANHANDLE {try = try,
                         exnVar = exnVar,
                         handler = handler,
                         labels = labels,
                         loc = loc}])
        end

      | AN.ANSWITCH {value, valueTy, branches, default, loc} =>
        let
          val value = optimizeValue varEnv value
          val (topEnv1, branches) = optimizeBranches env branches
          val (topEnv2, default) = optimizeDeclList env default
        in
          (unionTopEnv (topEnv1, topEnv2), VarID.Map.empty,
           [AN.ANSWITCH {value = value,
                         valueTy = valueTy,
                         branches = branches,
                         default = default,
                         loc = loc}])
        end

  and optimizeBranches env nil = (SEnv.empty, nil)
    | optimizeBranches env ({constant, branch}::branches) =
      let
        val constant = optimizeExp (#varEnv env) constant
        val (topEnv1, branch) = optimizeDeclList env branch
        val branch = {constant = constant, branch = branch}
        val (topEnv2, branches) = optimizeBranches env branches
      in
        (unionTopEnv (topEnv1, topEnv2), branch::branches)
      end
              
  and optimizeDeclList env nil = (SEnv.empty, nil)
    | optimizeDeclList env (decl::decls) =
      let
        val (topEnv1, varEnv1, decls1) = optimizeDecl env decl
        val env = extendVarEnv env varEnv1
        val (topEnv2, decls2) = optimizeDeclList env decls
      in
        (unionTopEnv (topEnv1, topEnv2), decls1 @ decls2)
      end

  and optimizeCodeDecl env ({codeId, argVarList, argSizeList, body,
                             resultTyList, loc}:AN.codeDecl) =
      let
        val env = extendVarEnv env (bindVars argVarList)
        val (newTopEnv, body) = optimizeDeclList env body
      in
        (newTopEnv,
         {
           codeId = codeId,
           argVarList = argVarList,
           argSizeList = argSizeList,
           body = body,
           resultTyList = resultTyList,
           loc = loc
         } : AN.codeDecl)
      end

  and optimizeCodeDeclList env nil = (SEnv.empty, nil)
    | optimizeCodeDeclList env (codedecl::codedecls) =
      let
        val (topEnv1, fundecl) = optimizeCodeDecl env codedecl
        val (topEnv2, fundecls) = optimizeCodeDeclList env codedecls
      in
        (unionTopEnv (topEnv1, topEnv2), codedecl :: codedecls)
      end

  and optimizeFunDecl env ({codeId, argVarList, argSizeList, body,
                            resultTyList, ffiAttributes, loc}:AN.funDecl) =
      let
        val {topEnv, toplevelFunIds, clusterId, count} = env
        val env = {topEnv = topEnv,
                   varEnv = bindVars argVarList,
                   isToplevel = VarID.Set.member (toplevelFunIds, codeId),
                   clusterId = clusterId,
                   count = count} : env

        val (newTopEnv, body) = optimizeDeclList env body
      in
        (newTopEnv,
         {
           codeId = codeId,
           argVarList = argVarList,
           argSizeList = argSizeList,
           body = body,
           resultTyList = resultTyList,
           ffiAttributes = ffiAttributes,
           loc = loc
         } : AN.funDecl)
      end

  fun optimizeFunDeclList env nil = (SEnv.empty, nil)
    | optimizeFunDeclList env (fundecl::fundecls) =
      let
        val (topEnv1, fundecl) = optimizeFunDecl env fundecl
        val (topEnv2, fundecls) = optimizeFunDeclList env fundecls
      in
        (unionTopEnv (topEnv1, topEnv2), fundecl :: fundecls)
      end

  fun optimizeCluster {topEnv, toplevelFunIds}
                      ({clusterId, frameInfo, entryFunctions,
                        hasClosureEnv, loc}:AN.clusterDecl) =
      let
        val env = {topEnv = topEnv,
                   toplevelFunIds = toplevelFunIds,
                   clusterId = clusterId,
                   count = ref 0}

        val (newTopEnv, entryFunctions) =
            optimizeFunDeclList env entryFunctions
      in
        (newTopEnv,
         {
           clusterId = clusterId,
           frameInfo = frameInfo,
           entryFunctions = entryFunctions,
           hasClosureEnv = hasClosureEnv,
           loc = loc
         } : AN.clusterDecl)
      end

  fun optimizeTopdecl env topdecl =
      case topdecl of
        AN.ANCLUSTER cluster =>
        let
          val (newTopEnv, newCluster) = optimizeCluster env cluster
        in
          (newTopEnv, AN.ANCLUSTER newCluster)
        end
      | AN.ANTOPCONST _ => (SEnv.empty, topdecl)
      | AN.ANTOPRECORD _ => (SEnv.empty, topdecl)
      | AN.ANTOPARRAY _ => (SEnv.empty, topdecl)
      | AN.ANTOPVAR _ => (SEnv.empty, topdecl)
      | AN.ANTOPCLOSURE _ => (SEnv.empty, topdecl)
      | AN.ANTOPALIAS _ => (SEnv.empty, topdecl)
      | AN.ANENTERTOPLEVEL id => (SEnv.empty, topdecl)

  fun optimizeTopdeclList env nil = (SEnv.empty, nil)
    | optimizeTopdeclList env (topdecl::topdecls) =
      let
        val (topEnv1, topdecl) = optimizeTopdecl env topdecl

        val {topEnv, toplevelFunIds} = env
        val topEnv = SEnv.unionWith #2 (topEnv, topEnv1)
        val env2 = {topEnv = topEnv, toplevelFunIds = toplevelFunIds}

        val (topEnv2, topdecls) = optimizeTopdeclList env2 topdecls
      in
        (unionTopEnv (topEnv1, topEnv2), topdecl :: topdecls)
      end

  fun globalName topdecl =
      case topdecl of
        AN.ANCLUSTER cluster => NONE
      | AN.ANTOPCONST {globalName, ...} => SOME globalName
      | AN.ANTOPRECORD {globalName, ...} => SOME globalName
      | AN.ANTOPARRAY {globalName, ...} => SOME globalName
      | AN.ANTOPVAR {globalName, ...} => SOME globalName
      | AN.ANTOPCLOSURE {globalName, ...} => SOME globalName
      | AN.ANTOPALIAS {globalName, ...} => SOME globalName
      | AN.ANENTERTOPLEVEL id => NONE

  fun makeTopEnv topdecls =
      foldl (fn (topdecl, env) =>
                case globalName topdecl of
                  NONE => env
                | SOME name => SEnv.insert (env, name, topdecl))
            SEnv.empty
            topdecls

  fun replaceTopdecl topEnv topdecls =
      map (fn topdecl =>
              case globalName topdecl of
                NONE => topdecl
              | SOME name =>
                case SEnv.find (topEnv, name) of
                  NONE => topdecl
                | SOME topdecl => topdecl)
          topdecls

  fun optimize topdecls =
      let
        val topEnv = makeTopEnv topdecls
        val toplevelFunIds =
            VarID.Set.fromList
              (List.mapPartial
                 (fn AN.ANENTERTOPLEVEL id => SOME id | _ => NONE)
                 topdecls)
        val env = {topEnv = topEnv, toplevelFunIds = toplevelFunIds}

        val (newTopEnv, topdecls) = optimizeTopdeclList env topdecls
        val topdecls = replaceTopdecl newTopEnv topdecls

        val newTopdecls =
            SEnv.foldri
              (fn (name, topdecl, newTopdecls) =>
                  case SEnv.find (topEnv, name) of
                    SOME _ => newTopdecls
                  | NONE => topdecl :: newTopdecls)
              nil
              newTopEnv

(*
        val _ =
            case
              List.mapPartial (fn AN.ANENTERTOPLEVEL id => SOME id | _ => NONE)
                              topdecls
             of
              [id] =>
              (case
                 List.mapPartial
                   (fn AN.ANCLUSTER {entryFunctions, ...} =>
                       List.find (fn {codeId,...} => codeId = id) entryFunctions
                     | _ => NONE)
                   topdecls
                of
                 [fundecl] =>
                 print (Control.prettyPrint (AN.format_funDecl fundecl) ^ "\n")
               | _ => ())
            | _ => ()
*)
      in
        newTopdecls @ topdecls
      end

end
