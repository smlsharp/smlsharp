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

  type topEnv =
       {locals: AN.topdecl VarID.Map.map, globals: AN.topdecl SEnv.map}

  val emptyTopEnv =
      {locals = VarID.Map.empty, globals = SEnv.empty} : topEnv

  fun singleton (AN.TOP_LOCAL id, decl) =
      {locals = VarID.Map.singleton (id, decl), globals = SEnv.empty} : topEnv
    | singleton (AN.TOP_GLOBAL sym, decl) =
      {locals = VarID.Map.empty, globals = SEnv.singleton (sym, decl)} : topEnv

  fun find ({locals, globals}:topEnv, topSymbol) =
      case topSymbol of
        AN.TOP_LOCAL id => VarID.Map.find (locals, id)
      | AN.TOP_GLOBAL sym => SEnv.find (globals, sym)

  fun extendTopEnv (env1:topEnv, env2:topEnv) =
      {locals = VarID.Map.unionWith #1 (#locals env1, #locals env2),
       globals = SEnv.unionWith #2 (#globals env1, #globals env2)}
      : topEnv

  fun listItems ({locals, globals}:topEnv) =
      VarID.Map.listItems locals @ SEnv.listItems globals

  type env =
      {
        topEnv: topEnv,
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

  fun fmt3 n =
      StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.DEC n)

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
      | AN.ANTOPSYMBOL _ => anvalue
      | AN.ANNULLPOINTER => anvalue
      | AN.ANNULLBOXED => anvalue

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
      | AN.ANTOPSYMBOL _ => true
      | AN.ANNULLPOINTER => true
      | AN.ANNULLBOXED => true

  fun toUInt32 (AN.ANWORD n) = n
    | toUInt32 (AN.ANINT n) =
      if n < 0 then raise Overflow else BasicTypes.SInt32ToUInt32 n
    | toUInt32 _ = raise Control.Bug "toUInt32"
  fun toFunLabel (AN.ANLABEL id) = id
    | toFunLabel _ = raise Control.Bug "toFunLabel: ANLABEL expected"

  local
    fun allocTop topdeclFn =
        let
          val name = AN.TOP_LOCAL (VarID.generate ())
          val topdecl = topdeclFn name
        in
          SOME (singleton (name, topdecl),
                AN.ANTOPSYMBOL {name = AN.TOP_EXPORT name, ty = AN.BOXED})
        end
  in

  fun allocateConst const =
      case const of
        CT.INT n => SOME (emptyTopEnv, AN.ANINT n)
      | CT.LARGEINT n => NONE
      | CT.WORD n => SOME (emptyTopEnv, AN.ANWORD n)
      | CT.BYTE n => SOME (emptyTopEnv, AN.ANBYTE n)
      | CT.STRING s =>
        allocTop
          (fn name => AN.ANTOPCONST {globalName = name,
                                     constant = const})
      | CT.REAL _ => NONE
      | CT.FLOAT _ => NONE
      | CT.CHAR c => SOME (emptyTopEnv, AN.ANCHAR c)
      | CT.UNIT => SOME (emptyTopEnv, AN.ANUNIT)
      | CT.NULLPOINTER => SOME (emptyTopEnv, AN.ANNULLPOINTER)
      | CT.NULLBOXED => SOME (emptyTopEnv, AN.ANNULLBOXED)

  fun allocateStatic (env:env) exp =
      case exp of
        AN.ANCONST const => allocateConst const
      | AN.ANVALUE value =>
        if isStatic value then SOME (emptyTopEnv, value) else NONE
      | AN.ANFOREIGNAPPLY _ => NONE
      | AN.ANCALLBACKCLOSURE _ => NONE
      | AN.ANENVACC _ => NONE
      | AN.ANGETFIELD _ => NONE
      | AN.ANARRAY {bitmap, totalSize, initialValue = NONE, elementTy,
                    elementSize, isMutable} => NONE
      | AN.ANARRAY {bitmap, totalSize, initialValue = SOME initialValue,
                    elementTy, elementSize, isMutable} =>
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
                allocTop
                  (fn name =>
                      AN.ANTOPARRAY {globalName = name,
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
      | AN.ANRECORD {bitmaps, totalSize, fieldList, fieldSizeList,
                     fieldIndexList, fieldTyList, isMutable, clearPad} =>
        if List.all isStatic (totalSize :: bitmaps @ fieldList @ fieldSizeList
                              @ fieldIndexList)
        then
            let
              val totalSize = toUInt32 totalSize
              val fieldIndexList = map toUInt32 fieldIndexList
              fun difList (nil, z) = [z : BasicTypes.UInt32]
                | difList ([x], z) = [z - x]
                | difList (h1::h2::t, z) = (h2 - h1) :: difList (h2::t, z)
              val fieldSizeList = difList (fieldIndexList, totalSize)
            in
              allocTop
                (fn name =>
                    AN.ANTOPRECORD {globalName = name,
                                    bitmaps = map toUInt32 bitmaps,
                                    totalSize = totalSize,
                                    fieldList = fieldList,
                                    fieldTyList = fieldTyList,
                                    fieldSizeList = fieldSizeList,
                                    isMutable = isMutable})
            end
        else NONE
      | AN.ANSELECT _ => NONE
      | AN.ANMODIFY _ => NONE
      | AN.ANPRIMAPPLY _ => NONE
      | AN.ANCLOSURE {funLabel, env=closEnv} =>
        if isStatic funLabel andalso isStatic closEnv
        then
          allocTop
            (fn name =>
                AN.ANTOPCLOSURE {globalName = name,
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
                    initialValue =
                      Option.map (optimizeValue varEnv) initialValue,
                    elementTy = elementTy,
                    elementSize = optimizeValue varEnv elementSize,
                    isMutable = isMutable}

      | AN.ANRECORD {bitmaps, totalSize, fieldList, fieldSizeList,
                     fieldIndexList, fieldTyList, isMutable, clearPad} =>
        AN.ANRECORD {bitmaps = map (optimizeValue varEnv) bitmaps,
                     totalSize = optimizeValue varEnv totalSize,
                     fieldList = map (optimizeValue varEnv) fieldList,
                     fieldSizeList = map (optimizeValue varEnv) fieldSizeList,
                     fieldIndexList = map (optimizeValue varEnv) fieldIndexList,
                     fieldTyList = fieldTyList,
                     isMutable = isMutable,
                     clearPad = clearPad}

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

      | AN.ANAPPLY {closure, argList, argTyList, resultTyList} =>
        AN.ANAPPLY {closure = optimizeValue varEnv closure,
                    argList = map (optimizeValue varEnv) argList,
                    argTyList = argTyList,
                    resultTyList = resultTyList}

      | AN.ANCALL {funLabel, env, argList, argTyList, resultTyList} =>
        AN.ANCALL {funLabel = optimizeValue varEnv funLabel,
                   env = optimizeValue varEnv env,
                   argList = map (optimizeValue varEnv) argList,
                   argTyList = argTyList,
                   resultTyList = resultTyList}

      | AN.ANRECCALL {funLabel, argList, argTyList, resultTyList} =>
        AN.ANRECCALL {funLabel = optimizeValue varEnv funLabel,
                      argList = map (optimizeValue varEnv) argList,
                      argTyList = argTyList,
                      resultTyList = resultTyList}

      | AN.ANLOCALCALL {codeLabel, argList, argTyList,
                        resultTyList, returnLabel, knownDestinations} =>
        AN.ANLOCALCALL {codeLabel = optimizeValue varEnv codeLabel,
                        argList = map (optimizeValue varEnv) argList,
                        argTyList = argTyList,
                        resultTyList = resultTyList,
                        returnLabel = returnLabel,
                        knownDestinations = knownDestinations}

  fun optimizeDecl (env as {topEnv, varEnv, ...}:env) decl =
      case decl of
        AN.ANSETFIELD {array, offset, value, valueTy, valueSize,
                       valueTag, setGlobal, needBoundaryCheck, loc} =>
        let
          val array = optimizeValue varEnv array
          val offset = optimizeValue varEnv offset
          val value = optimizeValue varEnv value
          val valueSize = optimizeValue varEnv valueSize
          val valueTag = optimizeValue varEnv valueTag
          val decl =
              AN.ANSETFIELD {array = array,
                             offset = offset,
                             value = value,
                             valueTy = valueTy,
                             valueSize = valueSize,
                             valueTag = valueTag,
                             setGlobal = setGlobal,
                             needBoundaryCheck = needBoundaryCheck,
                             loc = loc}
        in
          case (array, offset, isStatic value, needBoundaryCheck) of
            (AN.ANTOPSYMBOL {name=AN.TOP_EXPORT name,...},
             AN.ANWORD 0w0, true, false) =>
            (
              case find (topEnv, name) of
                SOME (AN.ANTOPVAR {globalName, initialValue,
                                   elementTy, elementSize}) =>
                (
                  case initialValue of
                    SOME _ => raise Control.Bug "optimizeDecl: ANSETFIELD"
                  | NONE =>
                    (singleton
                       (name, AN.ANTOPVAR {globalName = globalName,
                                           initialValue = SOME value,
                                           elementTy = elementTy,
                                           elementSize = elementSize}),
                     VarID.Map.empty,
                     nil)
                )
              | _ => (emptyTopEnv, VarID.Map.empty, [decl])
            )
          | _ => (emptyTopEnv, VarID.Map.empty, [decl])
        end

      | AN.ANSETTAIL {record, nestLevel, offset, value, valueTy, valueSize,
                      valueTag, loc} =>
        (emptyTopEnv, VarID.Map.empty,
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
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANCOPYARRAY {src = optimizeValue varEnv src,
                          srcOffset = optimizeValue varEnv srcOffset,
                          dst = optimizeValue varEnv dst,
                          dstOffset = optimizeValue varEnv dstOffset,
                          length = optimizeValue varEnv length,
                          elementTy = elementTy,
                          elementSize = optimizeValue varEnv elementSize,
                          elementTag = optimizeValue varEnv elementTag,
                          loc = loc}])

      | AN.ANTAILAPPLY {closure, argList, argTyList, resultTyList, loc} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANTAILAPPLY {closure = optimizeValue varEnv closure,
                          argList = map (optimizeValue varEnv) argList,
                          argTyList = argTyList,
                          resultTyList = resultTyList,
                          loc = loc}])

      | AN.ANTAILCALL {funLabel, env, argList, argTyList, resultTyList, loc} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANTAILCALL {funLabel = optimizeValue varEnv funLabel,
                         env = optimizeValue varEnv env,
                         argList = map (optimizeValue varEnv) argList,
                         argTyList = argTyList,
                         resultTyList = resultTyList,
                         loc = loc}])

      | AN.ANTAILRECCALL {funLabel, argList, argTyList, resultTyList, loc} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANTAILRECCALL {funLabel = optimizeValue varEnv funLabel,
                            argList = map (optimizeValue varEnv) argList,
                            argTyList = argTyList,
                            resultTyList = resultTyList,
                            loc = loc}])

      | AN.ANTAILLOCALCALL {codeLabel, argList, argTyList,
                            resultTyList, loc, knownDestinations} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANTAILLOCALCALL {codeLabel = optimizeValue varEnv codeLabel,
                              argList = map (optimizeValue varEnv) argList,
                              argTyList = argTyList,
                              resultTyList = resultTyList,
                              loc = loc,
                              knownDestinations = knownDestinations}])

      | AN.ANRETURN {valueList, tyList, loc} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANRETURN {valueList = map (optimizeValue varEnv) valueList,
                       tyList = tyList,
                       loc = loc}])

      | AN.ANLOCALRETURN {valueList, tyList, loc, knownDestinations} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANLOCALRETURN {valueList = map (optimizeValue varEnv) valueList,
                            tyList = tyList,
                            loc = loc,
                            knownDestinations = knownDestinations}])

      | AN.ANVAL {varList, exp, loc} =>
        let
          val exp = optimizeExp varEnv exp
        in
          case (varList, allocateStatic env exp) of
            ([var], SOME (newTopEnv, value)) =>
            (newTopEnv, VarID.Map.singleton (#id var, SOME value), nil)
          | _ =>
            (emptyTopEnv, bindVars varList,
             [AN.ANVAL {varList = varList,
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
                                      exp = AN.ANVALUE value,
                                      loc = loc}))
                varList
        in
          (emptyTopEnv, VarID.Map.empty, decls @ [decl])
        end

      | AN.ANMERGEPOINT {label, varList, leaveHandler, loc} =>
        (emptyTopEnv, bindVars varList,
         [AN.ANMERGEPOINT {label = label,
                           varList = varList,
                           leaveHandler = leaveHandler,
                           loc = loc}])

      | AN.ANRAISE {value, loc} =>
        (emptyTopEnv, VarID.Map.empty,
         [AN.ANRAISE {value = optimizeValue varEnv value,
                      loc = loc}])

      | AN.ANHANDLE {try, exnVar, handler, labels, loc} =>
        let
          val (topEnv1, try) = optimizeDeclList env try
          val newVarEnv = VarID.Map.singleton (#id exnVar, NONE)
          val handlerEnv = extendVarEnv env newVarEnv
          val (topEnv2, handler) = optimizeDeclList handlerEnv handler
        in
          (extendTopEnv (topEnv1, topEnv2), VarID.Map.empty,
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
          (extendTopEnv (topEnv1, topEnv2), VarID.Map.empty,
           [AN.ANSWITCH {value = value,
                         valueTy = valueTy,
                         branches = branches,
                         default = default,
                         loc = loc}])
        end

  and optimizeBranches env nil = (emptyTopEnv, nil)
    | optimizeBranches env ({constant, branch}::branches) =
      let
        val constant = optimizeExp (#varEnv env) constant
        val (topEnv1, branch) = optimizeDeclList env branch
        val branch = {constant = constant, branch = branch}
        val (topEnv2, branches) = optimizeBranches env branches
      in
        (extendTopEnv (topEnv1, topEnv2), branch::branches)
      end
              
  and optimizeDeclList env nil = (emptyTopEnv, nil)
    | optimizeDeclList env (decl::decls) =
      let
        val (topEnv1, varEnv1, decls1) = optimizeDecl env decl
        val env = extendVarEnv env varEnv1
        val (topEnv2, decls2) = optimizeDeclList env decls
      in
        (extendTopEnv (topEnv1, topEnv2), decls1 @ decls2)
      end

  and optimizeCodeDecl env ({codeId, argVarList, body, resultTyList,
                             loc}:AN.codeDecl) =
      let
        val env = extendVarEnv env (bindVars argVarList)
        val (newTopEnv, body) = optimizeDeclList env body
      in
        (newTopEnv,
         {
           codeId = codeId,
           argVarList = argVarList,
           body = body,
           resultTyList = resultTyList,
           loc = loc
         } : AN.codeDecl)
      end

  and optimizeCodeDeclList env nil = (emptyTopEnv, nil)
    | optimizeCodeDeclList env (codedecl::codedecls) =
      let
        val (topEnv1, fundecl) = optimizeCodeDecl env codedecl
        val (topEnv2, fundecls) = optimizeCodeDeclList env codedecls
      in
        (extendTopEnv (topEnv1, topEnv2), codedecl :: codedecls)
      end

  and optimizeFunDecl env ({codeId, argVarList, body,
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
           body = body,
           resultTyList = resultTyList,
           ffiAttributes = ffiAttributes,
           loc = loc
         } : AN.funDecl)
      end

  fun optimizeFunDeclList env nil = (emptyTopEnv, nil)
    | optimizeFunDeclList env (fundecl::fundecls) =
      let
        val (topEnv1, fundecl) = optimizeFunDecl env fundecl
        val (topEnv2, fundecls) = optimizeFunDeclList env fundecls
      in
        (extendTopEnv (topEnv1, topEnv2), fundecl :: fundecls)
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
      | AN.ANTOPCONST _ => (emptyTopEnv, topdecl)
      | AN.ANTOPRECORD _ => (emptyTopEnv, topdecl)
      | AN.ANTOPARRAY _ => (emptyTopEnv, topdecl)
      | AN.ANTOPVAR _ => (emptyTopEnv, topdecl)
      | AN.ANTOPCLOSURE _ => (emptyTopEnv, topdecl)
      | AN.ANTOPALIAS _ => (emptyTopEnv, topdecl)
      | AN.ANENTERTOPLEVEL id => (emptyTopEnv, topdecl)

  fun optimizeTopdeclList env nil = (emptyTopEnv, nil)
    | optimizeTopdeclList env (topdecl::topdecls) =
      let
        val (topEnv1, topdecl) = optimizeTopdecl env topdecl

        val {topEnv, toplevelFunIds} = env
        val topEnv = extendTopEnv (topEnv, topEnv1)
        val env2 = {topEnv = topEnv, toplevelFunIds = toplevelFunIds}

        val (topEnv2, topdecls) = optimizeTopdeclList env2 topdecls
      in
        (extendTopEnv (topEnv1, topEnv2), topdecl :: topdecls)
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
                | SOME name => extendTopEnv (env, singleton (name, topdecl)))
            emptyTopEnv
            topdecls

  fun replaceTopdecl topEnv topdecls =
      map (fn topdecl =>
              case globalName topdecl of
                NONE => topdecl
              | SOME name =>
                case find (topEnv, name) of
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

        val newTopdecls = listItems newTopEnv
        val newTopdecls =
            List.filter (fn topdecl =>
                            case globalName topdecl of
                              NONE => true
                            | SOME name => case find (topEnv, name) of
                                             NONE => true
                                           | SOME _ => false)
                        newTopdecls

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
