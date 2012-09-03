(**
 * Recover declarations needed for separate compilation.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
(* FIXME:
 * This is a nasty workaround towards native code compilation and separate
 * compilation. We need to perform refactoring drastically for compiler
 * frontend so that we can support separate compilation in natural way.
 *
 * Current intermediate representations and implementations don't hold
 * necessary information for separate compilation. In this phase, we try to
 * recover the lost necessary information from program and compile context.
 * The following information is needed:
 *
 * - globally unique name of each global variable and exception,
 * - set of global variables and exceptions to be exported, and
 * - definitions of exceptions (both global and local ones).
 *
 * In the sence of separate compilation, "globally unique name" is an
 * unique name derived from user-specified name. When we consider separate
 * compilation, we don't allow that the same name variable is defined in
 * two different compile unit which are to be linked.
 *)
(* FIXME:
 * Exceptions are "generative."
 * This means that every exception declaration must be compiled into
 * a sequence of instructions which generates unique tags dynamically.
 * Declaration recovery does not hold this semantics of Standard ML.
 *
 * fun f () =
 *   let exception A
 *   in (A, fn g => g () handle A => ()) end
 * val (e1, h1) = f ()
 * val (e2, h2) = f ()
 * val _ = h1 (fn () => raise e2)   (* unhandled exception *)
 *)

structure DeclarationRecovery : sig

  val recover :
      {
        currentBasis: VarIDContext.topExternalVarIDBasis,
        newBasis: VarIDContext.topExternalVarIDBasis,
        currentContext: InitialTypeContext.topTypeContext,
        newContext: TypeContext.context,
        aliasEnv: string SEnv.map,
        separateCompilation: bool
      }
      -> YAANormal.topdecl list
      -> (string SEnv.map * YAANormal.topdecl list)

end =
struct

  structure AN = YAANormal

  (* Make a map from ExternalVarID to global name.
   * Since topVarIDEnv holds a map from string to ExternalVarID,
   * the desired map can be obtained by reversing the topVarIDEnv.
   * Correspondence between ExternalVarID and global name is not
   * one-to-one; same ExternalVarID may be assigned to more than two
   * different global names due to structure A = B, open, and/or
   * val x = y.
   * One of the global names corresponded to the same ExternalVarID
   * is variable definition, and others are aliases of the definition.
   *)
  fun reverseExternalVarIDBasis
          ((_,topVarIDEnv):VarIDContext.topExternalVarIDBasis) =
      SEnv.foldli
        (fn (k, VarIDContext.Internal _, z) =>
            raise Control.Bug "reverseExternalVarIDBasis"
          | (k, VarIDContext.Dummy, z) => z
          | (k, VarIDContext.External i, z) =>
            case ExternalVarID.Map.find (z, i) of
              SOME l => ExternalVarID.Map.insert (z, i, k::l)
            | NONE => ExternalVarID.Map.insert (z, i, [k]))
        ExternalVarID.Map.empty
        topVarIDEnv

  (* Make a map from ExnTagID to global name.
   * Since top type context holds a map from string to ExnTagID,
   * the desired map can be obtained by reversing the top type context.
   * Correspondence between ExnTagID and global name is not one-to-one;
   * same ExnTagID may be assigned to more than two different global
   * names due to exception replication.
   * One of the global names corresponded to the same ExnTagID is
   * exception definition, and others are aliases of the definition.
   *)
  fun reverseTopTypeContextFromExnTag
          ({varEnv,...}:InitialTypeContext.topTypeContext) =
      SEnv.foldri
        (fn (k, Types.EXNID {tag, ...}, z) =>
            (case ExnTagID.Map.find (z, tag) of
               SOME l => ExnTagID.Map.insert (z, tag, k::l)
             | NONE => ExnTagID.Map.insert (z, tag, [k]))
          | (_, _, z) => z)
        ExnTagID.Map.empty
        varEnv

  (* Extract definitions of global exceptions defined in the
   * current compile unit from type context of local context.
   * The type context contains identifiers which is defined
   * in this compile unit and available in global.
   *)
  fun extractExceptionDefinitions ({varEnv,...}:TypeContext.context) =
      NameMap.NPEnv.foldri
        (fn (namePath, Types.EXNID {tag, ...}, z) =>
            let
              val name = NameMap.usrNamePathToString namePath
            in
              case ExnTagID.Map.find (z, tag) of
                SOME l => ExnTagID.Map.insert (z, tag, name::l)
              | NONE => ExnTagID.Map.insert (z, tag, [name])
            end
          | (_, _, z) => z)
        ExnTagID.Map.empty
        varEnv

  fun toRTTy anty =
      case anty of
        AN.UINT => RBUTypes.ATOMty
      | AN.SINT => RBUTypes.ATOMty
      | AN.BYTE => RBUTypes.ATOMty
      | AN.CHAR => RBUTypes.ATOMty
      | AN.BOXED => RBUTypes.BOXEDty
      | AN.POINTER => RBUTypes.ATOMty
      | AN.FUNENTRY => RBUTypes.ATOMty
      | AN.CODEPOINT => RBUTypes.ATOMty
      | AN.FLOAT => RBUTypes.ATOMty
      | AN.DOUBLE => RBUTypes.DOUBLEty
      | AN.DOUBLEty => RBUTypes.DOUBLEty
      | AN.ATOMty => RBUTypes.ATOMty
      | _ => raise Control.Bug "toRTTy"
  fun tagOf ty =
      BasicTypes.WordToUInt32 (valOf (RBUUtils.constTag (toRTTy ty)))
  fun sizeOf ty =
      BasicTypes.WordToUInt32 (valOf (RBUUtils.constSize (toRTTy ty)))


  local
    fun replace f x =
        if Substring.isEmpty x then ""
        else
          let
            val (s, t) = f (Substring.sub (x, 0), Substring.triml 1 x)
          in
            s ^ replace f t
          end

    fun hex n =
        if n < 16 then "0" ^ Int.fmt StringCvt.HEX n
        else if n < 256 then Int.fmt StringCvt.HEX n
        else "u" ^ Int.fmt StringCvt.HEX n ^ "_"
  in

  fun mangle name =
      "_SML" ^
      replace (fn (#"_", t) =>
                  if Substring.isPrefix "_" t
                  then ("___", Substring.triml 1 t)
                  else ("_", t)
                | (#".", t) => (".", t)
                | (c, t) =>
                  if Char.isAlphaNum c
                  then (str c, t)
                  else ("__" ^ hex (ord c), t))
              (Substring.full name) ^
      "_"

  end


  type context =
      {
        exportVars: string list ExternalVarID.Map.map,
        exportExceptions: string list ExnTagID.Map.map,
        decls: AN.topdecl list list,
        exceptionEnv: AN.globalSymbolName ExnTagID.Map.map,
        globalVarEnv: AN.globalSymbolName ExternalVarID.Map.map
      }

  fun recoverExceptionDecl (context:context) tag =
      case ExnTagID.Map.find (#exceptionEnv context, tag) of
        SOME name => (context, name)
      | NONE =>
        let
          (* Probably this exception is defined in current compilation unit;
           * here we try to recover its declaration. *)
          val (export, names) =
              case ExnTagID.Map.find (#exportExceptions context, tag) of
                NONE => (false, ["Exn._" ^ ExnTagID.toString tag])
              | SOME names => (true, names)

          val (firstName, aliases) = (List.hd names, List.tl names)

          (* firstName is the first name of names in alphabetical order *)
          val nameStringName =
              firstName ^ "." ^ ExnTagID.toString tag ^ "_Name"

          val globalName = (firstName, AN.GLOBALSYMBOL)

          val decls =
              [
                AN.ANTOPCONST  {globalName = nameStringName,
                                export = false,
                                constant = ConstantTerm.STRING firstName},
                AN.ANTOPRECORD {globalName = firstName,
                                export = export,
                                bitmaps = [tagOf AN.BOXED],
                                totalSize = sizeOf AN.BOXED,
                                fieldList = [AN.ANGLOBALSYMBOL
                                                 {name = (nameStringName,
                                                          AN.GLOBALSYMBOL),
                                                  ann = AN.GLOBALOTHER,
                                                  ty = AN.BOXED}],
                                fieldTyList = [AN.BOXED],
                                fieldSizeList = [sizeOf AN.BOXED]}
              ] @
              map (fn name =>
                      AN.ANTOPALIAS
                        {globalName = name,
                         export = export,
                         originalGlobalName = globalName})
                  aliases

          val context =
              {
                exportVars = #exportVars context,
                exportExceptions = #exportExceptions context,
                decls = decls :: #decls context,
                exceptionEnv = ExnTagID.Map.insert (#exceptionEnv context,
                                                    tag, globalName),
                globalVarEnv = #globalVarEnv context
              } : context
        in
          (context, globalName)
        end

  fun recoverGlobalVarDecl (context:context) id ty =
      case ExternalVarID.Map.find (#globalVarEnv context, id) of
        SOME name => (context, name)
      | NONE =>
        let
          val (export, names) =
              case ExternalVarID.Map.find (#exportVars context, id) of
                NONE => (false, ["Var._" ^ ExternalVarID.toString id])
              | SOME names => (true, names)

          (* firstName is the first name of names in alphabetical order *)
          val (firstName, aliases) = (List.hd names, List.tl names)

          val globalName = (firstName, AN.GLOBALSYMBOL)

          val decls =
              [
                AN.ANTOPARRAY {globalName = firstName,
                               export = export,
                               externalVarID = SOME id,
                               bitmap = tagOf ty,
                               totalSize = sizeOf ty,
                               initialValues = nil,
                               elementTy = ty,
                               elementSize = sizeOf ty,
                               isMutable = true}
              ] @
              map (fn name =>
                      AN.ANTOPALIAS
                        {globalName = name,
                         export = export,
                         originalGlobalName = globalName})
                  aliases

          val context =
              {
                exportVars = #exportVars context,
                exportExceptions = #exportExceptions context,
                decls = decls :: #decls context,
                exceptionEnv = #exceptionEnv context,
                globalVarEnv = ExternalVarID.Map.insert (#globalVarEnv context,
                                                         id, globalName)
              } : context
        in
          (context, globalName)
        end

(*
  fun addAlias (context:context) newName origName =
      {
        exportVars = #exportVars context,
        exportExceptions = #exportExceptions context,
        decls =
          [
            AN.ANTOPALIAS {globalName = newName,
                           export = true,
                           originalGlobalName = origName}
          ] :: #decls context,
        exceptionEnv = #exceptionEnv context,
        globalVarEnv = #globalVarEnv context
      } : context

  fun addExceptionAlias (context:context) tag name =
      case ExnTagID.Map.find (#exceptionEnv context, tag) of
        NONE => raise Control.Bug "addExceptionAlias"
      | SOME originalName => addAlias context name originalName

  fun addGlobalVarAlias (context:context) id name =
      case ExternalVarID.Map.find (#globalVarEnv context, id) of
        NONE => raise Control.Bug "addGlobalVarAlias"
      | SOME originalName => addAlias context name originalName
*)

  fun extractDecls (context:context) =
      ({
         exportVars = #exportVars context,
         exportExceptions = #exportExceptions context,
         decls = nil,
         exceptionEnv = #exceptionEnv context,
         globalVarEnv = #globalVarEnv context
       } : context,
       List.concat (rev (#decls context)))


  fun recoverList f z nil = (z, nil)
    | recoverList f z (h::t) =
      let
        val (z, h) = f z h
        val (z, t) = recoverList f z t
      in
        (z, h::t)
      end

  fun recoverValue context anvalue =
      case anvalue of
        AN.ANINT _ => (context, anvalue)
      | AN.ANWORD _ => (context, anvalue)
      | AN.ANBYTE _ => (context, anvalue)
      | AN.ANCHAR _ => (context, anvalue)
      | AN.ANUNIT => (context, anvalue)
      | AN.ANVAR _ => (context, anvalue)
      | AN.ANLABEL _ => (context, anvalue)
      | AN.ANLOCALCODE _ => (context, anvalue)
      | AN.ANGLOBALSYMBOL {name=(name, AN.UNDECIDED), ann, ty} =>
        let
          val (context, globalName) =
              case ann of
                AN.GLOBALVAR id => recoverGlobalVarDecl context id ty
              | AN.EXCEPTIONTAG tag => recoverExceptionDecl context tag
              | AN.GLOBALOTHER =>
                raise Control.Bug "recoverValue: undecided other"
        in
          (context, AN.ANGLOBALSYMBOL {name = globalName, ann = ann, ty = ty})
        end
      | AN.ANGLOBALSYMBOL _ => (context, anvalue)

  fun recoverValueList context anvalueList =
      recoverList recoverValue context anvalueList

  fun recoverExp context anexp =
      case anexp of
        AN.ANCONST _ => (context, anexp)

      | AN.ANVALUE value =>
        let
          val (context, value) = recoverValue context value
        in
          (context, AN.ANVALUE value)
        end

      | AN.ANFOREIGNAPPLY {function, argList, argTyList, resultTyList,
                           attributes} =>
        let
          val (context, function) = recoverValue context function
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANFOREIGNAPPLY {function = function,
                              argList = argList,
                              argTyList = argTyList,
                              resultTyList = resultTyList,
                              attributes = attributes})
        end

      | AN.ANCALLBACKCLOSURE {funLabel, env,
                              argTyList, resultTyList, attributes} =>
        let
          val (context, funLabel) = recoverValue context funLabel
          val (context, env) = recoverValue context env
        in
          (context,
           AN.ANCALLBACKCLOSURE {funLabel = funLabel,
                                 env = env,
                                 argTyList = argTyList,
                                 resultTyList = resultTyList,
                                 attributes = attributes})
        end

      | AN.ANENVACC {nestLevel, offset, size, ty} =>
        let
          val (context, size) = recoverValue context size
        in
          (context,
           AN.ANENVACC {nestLevel = nestLevel,
                        offset = offset,
                        size = size,
                        ty = ty})
        end

      | AN.ANGETFIELD {array, offset, size, ty, needBoundaryCheck} =>
        let
          val (context, array) = recoverValue context array
          val (context, offset) = recoverValue context offset
          val (context, size) = recoverValue context size
        in
          (context,
           AN.ANGETFIELD {array = array,
                          offset = offset,
                          size = size,
                          ty = ty,
                          needBoundaryCheck = needBoundaryCheck})
        end

      | AN.ANARRAY {bitmap, totalSize, initialValue, elementTy, elementSize,
                    isMutable} =>
        let
          val (context, bitmap) = recoverValue context bitmap
          val (context, totalSize) = recoverValue context totalSize
          val (context, initialValue) = recoverValue context initialValue
          val (context, elementSize) = recoverValue context elementSize
        in
          (context,
           AN.ANARRAY {bitmap = bitmap,
                       totalSize = totalSize,
                       initialValue = initialValue,
                       elementTy = elementTy,
                       elementSize = elementSize,
                       isMutable = isMutable})
        end

      | AN.ANRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                     fieldTyList} =>
        let
          val (context, bitmap) = recoverValue context bitmap
          val (context, totalSize) = recoverValue context totalSize
          val (context, fieldList) = recoverValueList context fieldList
          val (context, fieldSizeList) = recoverValueList context fieldSizeList
        in
          (context,
           AN.ANRECORD {bitmap = bitmap,
                        totalSize = totalSize,
                        fieldList = fieldList,
                        fieldSizeList = fieldSizeList,
                        fieldTyList = fieldTyList})
        end

      | AN.ANENVRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                        fieldTyList, fixedSizeList} =>
        let
          val (context, bitmap) = recoverValue context bitmap
          val (context, fieldList) = recoverValueList context fieldList
          val (context, fieldSizeList) = recoverValueList context fieldSizeList
        in
          (context,
           AN.ANENVRECORD {bitmap = bitmap,
                           totalSize = totalSize,
                           fieldList = fieldList,
                           fieldSizeList = fieldSizeList,
                           fieldTyList = fieldTyList,
                           fixedSizeList = fixedSizeList})
        end

      | AN.ANSELECT {record, nestLevel, offset, size, ty} =>
        let
          val (context, record) = recoverValue context record
          val (context, nestLevel) = recoverValue context nestLevel
          val (context, offset) = recoverValue context offset
          val (context, size) = recoverValue context size
        in
          (context,
           AN.ANSELECT {record = record,
                        nestLevel = nestLevel,
                        offset = offset,
                        size = size,
                        ty = ty})
        end

      | AN.ANMODIFY {record, nestLevel, offset, value, valueTy, valueSize,
                     valueTag} =>
        let
          val (context, record) = recoverValue context record
          val (context, nestLevel) = recoverValue context nestLevel
          val (context, offset) = recoverValue context offset
          val (context, value) = recoverValue context value
          val (context, valueSize) = recoverValue context valueSize
          val (context, valueTag) = recoverValue context valueTag
        in
          (context,
           AN.ANMODIFY {record = record,
                        nestLevel = nestLevel,
                        offset = offset,
                        value = value,
                        valueTy = valueTy,
                        valueSize = valueSize,
                        valueTag = valueTag})
        end

      | AN.ANPRIMAPPLY {prim, argList, argTyList, resultTyList,
                        instSizeList, instTagList} =>
        let
          val (context, argList) = recoverValueList context argList
          val (context, instSizeList) = recoverValueList context instSizeList
          val (context, instTagList) = recoverValueList context instTagList
        in
          (context,
           AN.ANPRIMAPPLY {prim = prim,
                           argList = argList,
                           argTyList = argTyList,
                           resultTyList = resultTyList,
                           instSizeList = instSizeList,
                           instTagList = instTagList})
        end

      | AN.ANCLOSURE {funLabel, env} =>
        let
          val (context, funLabel) = recoverValue context funLabel
          val (context, env) = recoverValue context env
        in
          (context,
           AN.ANCLOSURE {funLabel = funLabel,
                         env = env})
        end

      | AN.ANRECCLOSURE {funLabel} =>
        let
          val (context, funLabel) = recoverValue context funLabel
        in
          (context,
           AN.ANRECCLOSURE {funLabel = funLabel})
        end

      | AN.ANAPPLY {closure, argList, argTyList, resultTyList, argSizeList} =>
        let
          val (context, closure) = recoverValue context closure
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANAPPLY {closure = closure,
                       argList = argList,
                       argTyList = argTyList,
                       resultTyList = resultTyList,
                       argSizeList = argSizeList})
        end

      | AN.ANCALL {funLabel, env, argList, argSizeList, argTyList,
                   resultTyList} =>
        let
          val (context, funLabel) = recoverValue context funLabel
          val (context, env) = recoverValue context env
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANCALL {funLabel = funLabel,
                      env = env,
                      argList = argList,
                      argSizeList = argSizeList,
                      argTyList = argTyList,
                      resultTyList = resultTyList})
        end

      | AN.ANRECCALL {funLabel, argList, argSizeList, argTyList,
                      resultTyList} =>
        let
          val (context, funLabel) = recoverValue context funLabel
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANRECCALL {funLabel = funLabel,
                         argList = argList,
                         argSizeList = argSizeList,
                         argTyList = argTyList,
                         resultTyList = resultTyList})
        end

      | AN.ANLOCALCALL {codeLabel, argList, argSizeList, argTyList,
                        resultTyList, returnLabel, knownDestinations} =>
        let
          val (context, codeLabel) = recoverValue context codeLabel
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANLOCALCALL {codeLabel = codeLabel,
                           argList = argList,
                           argSizeList = argSizeList,
                           argTyList = argTyList,
                           resultTyList = resultTyList,
                           returnLabel = returnLabel,
                           knownDestinations = knownDestinations})
        end

  fun recoverDecl context andecl =
      case andecl of
        AN.ANSETFIELD {array, offset, value, valueTy, valueSize, valueTag,
                       needBoundaryCheck, loc} =>
        let
          val (context, array) = recoverValue context array
          val (context, offset) = recoverValue context offset
          val (context, value) = recoverValue context value
          val (context, valueSize) = recoverValue context valueSize
          val (context, valueTag) = recoverValue context valueTag
        in
          (context,
           AN.ANSETFIELD {array = array,
                          offset = offset,
                          value = value,
                          valueTy = valueTy,
                          valueSize = valueSize,
                          valueTag = valueTag,
                          needBoundaryCheck = needBoundaryCheck,
                          loc = loc})
        end

      | AN.ANSETTAIL {record, nestLevel, offset, value, valueTy, valueSize,
                      valueTag, loc} =>
        let
          val (context, record) = recoverValue context record
          val (context, nestLevel) = recoverValue context nestLevel
          val (context, offset) = recoverValue context offset
          val (context, value) = recoverValue context value
          val (context, valueSize) = recoverValue context valueSize
          val (context, valueTag) = recoverValue context valueTag
        in
          (context,
           AN.ANSETTAIL {record = record,
                         nestLevel = nestLevel,
                         offset = offset,
                         value = value,
                         valueTy = valueTy,
                         valueSize = valueSize,
                         valueTag = valueTag,
                         loc = loc})
        end

      | AN.ANCOPYARRAY {src, srcOffset, dst, dstOffset, length, elementTy,
                        elementSize, elementTag, loc} =>
        let
          val (context, src) = recoverValue context src
          val (context, srcOffset) = recoverValue context srcOffset
          val (context, dst) = recoverValue context dst
          val (context, dstOffset) = recoverValue context dstOffset
          val (context, length) = recoverValue context length
          val (context, elementSize) = recoverValue context elementSize
          val (context, elementTag) = recoverValue context elementTag
        in
          (context,
           AN.ANCOPYARRAY {src = src,
                           srcOffset = srcOffset,
                           dst = dst,
                           dstOffset = dstOffset,
                           length = length,
                           elementTy = elementTy,
                           elementSize = elementSize,
                           elementTag = elementTag,
                           loc = loc})
        end

      | AN.ANTAILAPPLY {closure, argList, argTyList, resultTyList, argSizeList,
                        loc} =>
        let
          val (context, closure) = recoverValue context closure
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANTAILAPPLY {closure = closure,
                           argList = argList,
                           argTyList = argTyList,
                           resultTyList = resultTyList,
                           argSizeList = argSizeList,
                           loc = loc})
        end

      | AN.ANTAILCALL {funLabel, env, argList, argSizeList, argTyList,
                       resultTyList, loc} =>
        let
          val (context, funLabel) = recoverValue context funLabel
          val (context, env) = recoverValue context env
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANTAILCALL {funLabel = funLabel,
                          env = env,
                          argList = argList,
                          argSizeList = argSizeList,
                          argTyList = argTyList,
                          resultTyList = resultTyList,
                          loc = loc})
        end

      | AN.ANTAILRECCALL {funLabel, argList, argSizeList, argTyList,
                          resultTyList, loc} =>
        let
          val (context, funLabel) = recoverValue context funLabel
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANTAILRECCALL {funLabel = funLabel,
                             argList = argList,
                             argSizeList = argSizeList,
                             argTyList = argTyList,
                             resultTyList = resultTyList,
                             loc = loc})
        end

      | AN.ANTAILLOCALCALL {codeLabel, argList, argSizeList, argTyList,
                            resultTyList, loc, knownDestinations} =>
        let
          val (context, codeLabel) = recoverValue context codeLabel
          val (context, argList) = recoverValueList context argList
        in
          (context,
           AN.ANTAILLOCALCALL {codeLabel = codeLabel,
                               argList = argList,
                               argSizeList = argSizeList,
                               argTyList = argTyList,
                               resultTyList = resultTyList,
                               loc = loc,
                               knownDestinations = knownDestinations})
        end
      | AN.ANRETURN {valueList, tyList, sizeList, loc} =>
        let
          val (context, valueList) = recoverValueList context valueList
        in
          (context,
           AN.ANRETURN {valueList = valueList,
                        tyList = tyList,
                        sizeList = sizeList,
                        loc = loc})
        end

      | AN.ANLOCALRETURN {valueList, tyList, sizeList, loc,
                          knownDestinations} =>
        let
          val (context, valueList) = recoverValueList context valueList
        in
          (context,
           AN.ANLOCALRETURN {valueList = valueList,
                             tyList = tyList,
                             sizeList = sizeList,
                             loc = loc,
                             knownDestinations = knownDestinations})
        end

      | AN.ANVAL {varList, sizeList, exp, loc} =>
        let
          val (context, exp) = recoverExp context exp
        in
          (context,
           AN.ANVAL {varList = varList,
                     sizeList = sizeList,
                     exp = exp,
                     loc = loc})
        end

      | AN.ANVALCODE {codeList, loc} =>
        let
          val (context, codeList) = recoverCodeDeclList context codeList
        in
          (context,
           AN.ANVALCODE {codeList = codeList,
                         loc = loc})
        end

      | AN.ANMERGE {label, varList, loc} =>
        (context, andecl)

      | AN.ANMERGEPOINT {label, varList, leaveHandler, loc} =>
        (context, andecl)

      | AN.ANRAISE {value, loc} =>
        let
          val (context, value) = recoverValue context value
        in
          (context,
           AN.ANRAISE {value = value,
                       loc = loc})
        end

      | AN.ANHANDLE {try, exnVar, handler, labels, loc} =>
        let
          val (context, try) = recoverDeclList context try
          val (context, handler) = recoverDeclList context handler
        in
          (context,
           AN.ANHANDLE {try = try,
                        exnVar = exnVar,
                        handler = handler,
                        labels = labels,
                        loc = loc})
        end

      | AN.ANSWITCH {value, valueTy, branches, default, loc} =>
        let
          val (context, value) = recoverValue context value
          val (context, branches) = recoverBranches context branches
          val (context, default) = recoverDeclList context default
        in
          (context,
           AN.ANSWITCH {value = value,
                        valueTy = valueTy,
                        branches = branches,
                        default = default,
                        loc = loc})
        end

  and recoverDeclList context andeclList =
      recoverList recoverDecl context andeclList

  and recoverBranch context {constant, branch} =
      let
        val (context, constant) = recoverExp context constant
        val (context, branch) = recoverDeclList context branch
      in
        (context, {constant = constant, branch = branch})
      end

  and recoverBranches context branches =
      recoverList recoverBranch context branches

(*
  and recoverCodeDecl context ({codeId, argVarList, argSizeList, body,
                                resultTyList, loc}:AN.codeDecl) =
      let
        val (context, body) = recoverDeclList context body
      in
        (context,
         {
           codeId = codeId,
           argVarList = argVarList,
           argSizeList = argSizeList,
           body = body,
           resultTyList = resultTyList,
           loc = loc
         } : AN.codeDecl)
      end

  and recoverCodeDeclList context codeDeclList =
      recoverList recoverCodeDecl context codeDeclList
*)

  and recoverFunDecl context ({codeId, argVarList, argSizeList, body,
                               resultTyList, ffiAttributes, loc}:AN.funDecl) =
      let
        val (context, body) = recoverDeclList context body
      in
        (context,
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

  and recoverCodeDecl context ({codeId, argVarList, argSizeList, body,
                                resultTyList, loc}:AN.codeDecl) =
      let
        val (context, body) = recoverDeclList context body
      in
        (context,
         {
           codeId = codeId,
           argVarList = argVarList,
           argSizeList = argSizeList,
           body = body,
           resultTyList = resultTyList,
           loc = loc
         } : AN.codeDecl)
      end

  and recoverFunDeclList context funDeclList =
      recoverList recoverFunDecl context funDeclList

  and recoverCodeDeclList context funDeclList =
      recoverList recoverCodeDecl context funDeclList

  fun recoverCluster context ({clusterId, frameInfo, entryFunctions,
                               hasClosureEnv, loc}:AN.clusterDecl) =
      let
        val (context, entryFunctions) =
            recoverFunDeclList context entryFunctions
      in
        (context,
         {
           clusterId = clusterId,
           frameInfo = frameInfo,
           entryFunctions = entryFunctions,
           hasClosureEnv = hasClosureEnv,
           loc = loc
         } : AN.clusterDecl)
      end

  fun recoverTopdecl context topdecl =
      case topdecl of
        AN.ANCLUSTER cluster =>
        let
          val (context, cluster) = recoverCluster context cluster
          val (context, decls) = extractDecls context
        in
          (context, decls @ [AN.ANCLUSTER cluster])
        end
      | AN.ANTOPCONST _ => (context, [topdecl])
      | AN.ANTOPRECORD _ => (context, [topdecl])
      | AN.ANTOPARRAY _ => (context, [topdecl])
      | AN.ANTOPCLOSURE _ => (context, [topdecl])
      | AN.ANTOPALIAS _ => (context, [topdecl])
      | AN.ANENTERTOPLEVEL id => (context, [topdecl])

  fun recoverTopdeclList context (topdecl::topdecls) =
      let
        val (context, topdecls1) = recoverTopdecl context topdecl
        val (context, topdecls2) = recoverTopdeclList context topdecls
      in
        (context, topdecls1 @ topdecls2)
      end
    | recoverTopdeclList context nil = (context, nil)


  fun makeGlobalName separateCompilationMode id name =
      let
        (* In separate compilation mode, every toplevel name must be unique.
         * In sequential compilation mode, toplevel binding may be
         * overriden by following bindings. To make sure that all
         * global name are unique, we append globally unique ID suffix
         * to global name.
         *)
        fun suffix f x =
            if separateCompilationMode then "" else "." ^ f x
      in
        case id of
          AN.EXCEPTIONTAG tag =>
          (
            case ExnTagID.Map.find (#exceptionGlobalNameMap
                                        BuiltinContext.builtinContext, 
                                    tag) of
              SOME name => name (* predefined exception *)
            | NONE => mangle (name ^ suffix ExnTagID.toString tag)
          )
        | AN.GLOBALVAR id => mangle (name ^ suffix ExternalVarID.toString id)
        | AN.GLOBALOTHER => mangle name
      end

  fun resolveAliases aliasEnv names =
      let
        val set = foldl (fn (x,z) =>
                            case SEnv.find (aliasEnv, x) of
                              SOME x => SEnv.insert (z,x,())
                            | NONE => SEnv.insert (z,x,()))
                        SEnv.empty
                        names
      in
        (* we take the first one in alphabetical order *)
        case SEnv.firsti set of
          SOME (k,v) => k
        | NONE => raise Control.Bug "resolveAliases"
      end

  fun recover {currentBasis, newBasis, currentContext, newContext,
               separateCompilation, aliasEnv} topdecls =
      let
        val importVars = reverseExternalVarIDBasis currentBasis
        val importExceptions = reverseTopTypeContextFromExnTag currentContext
        val exportVars = reverseExternalVarIDBasis newBasis
        val exportExceptions = extractExceptionDefinitions newContext

(*
        val _ =
            (print "importVars:\n";
             ExternalVarID.Map.appi
               (fn (k,v) =>
                   (print (ExternalVarID.toString k ^ " : ");
                    app (fn x => print (x^", ")) v;
                    print "\n"))
               importVars)
        val _ =
            (print "importExceptions:\n";
             ExnTagID.Map.appi
               (fn (k,v) =>
                   (print (ExnTagID.toString k ^ " : ");
                    app (fn x => print (x^", ")) v;
                    print "\n"))
               importExceptions)
        val _ =
            (print "aliasEnv:\n";
             SEnv.appi (fn (x,y) => print (x^" -> "^y^"\n")) aliasEnv)
*)

        fun toGlobalName con =
            fn (id, names) =>
               let
                 val names =
                     map (makeGlobalName separateCompilation (con id)) names
               in
                 (resolveAliases aliasEnv names, AN.EXTERNSYMBOL)
               end

        val globalVarEnv =
            ExternalVarID.Map.mapi (toGlobalName AN.GLOBALVAR) importVars
        val exceptionEnv =
            ExnTagID.Map.mapi (toGlobalName AN.EXCEPTIONTAG) importExceptions
        val exportVars =
            ExternalVarID.Map.mapi
              (fn (k,l) => map (makeGlobalName separateCompilation
                                               (AN.GLOBALVAR k)) l)
              exportVars
        val exportExceptions =
            ExnTagID.Map.mapi
              (fn (k,l) => map (makeGlobalName separateCompilation
                                               (AN.EXCEPTIONTAG k)) l)
              exportExceptions

(*
        val _ =
            (print "exportVars:\n";
             ExternalVarID.Map.appi
               (fn (k,v) =>
                   (print (ExternalVarID.toString k ^ " : ");
                    app (fn x => print (x^", ")) v;
                    print "\n"))
               exportVars)
        val _ =
            (print "exportExceptions:\n";
             ExnTagID.Map.appi
               (fn (k,v) =>
                   (print (ExnTagID.toString k ^ " : ");
                    app (fn x => print (x^", ")) v;
                    print "\n"))
               exportExceptions)
*)

        val context =
            {
              exportVars = exportVars,
              exportExceptions = exportExceptions,
              decls = nil,
              exceptionEnv = exceptionEnv,
              globalVarEnv = globalVarEnv
            } : context

        val (context, topdecls) = recoverTopdeclList context topdecls

        fun insertKeys (map, keys, value) =
            foldl (fn (k,z) => SEnv.insert (z, k, value)) map keys

        (* make sure that all exceptions to be exported are defined. *)
        val (context, aliasEnv) =
            ExnTagID.Map.foldli
              (fn (tag, names, (context, aliasEnv)) =>
                  case ExnTagID.Map.find (#exceptionEnv context, tag) of
                    SOME (name, AN.GLOBALSYMBOL) =>
                    (* exception declaration is already recovered. *)
                    (context, aliasEnv)
                  | SOME (name, AN.EXTERNSYMBOL) =>
                    (* exception replication beyond compile unit. *)
                    (context, insertKeys (aliasEnv, names, name))
                  | SOME (_, AN.UNDECIDED) =>
                    raise Control.Bug "recover: UNDECIDED exception"
                  | NONE =>
                    (* exception declaration has not been recovered.
                     * This means that this exception is not used in
                     * current compile unit but exported. *)
                    (#1 (recoverExceptionDecl context tag), aliasEnv))
              (context, aliasEnv)
              (#exportExceptions context)

        val (context, aliasEnv) =
            ExternalVarID.Map.foldli
              (fn (id, names, (context, aliasEnv)) =>
                  case ExternalVarID.Map.find (#globalVarEnv context, id) of
                    SOME (name, AN.GLOBALSYMBOL) =>
                    (* global variable definition is already recovered. *)
                    (context, aliasEnv)
                  | SOME (name, AN.EXTERNSYMBOL) =>
                    (* aliases beyond compile unit. *)
                    (context, insertKeys (aliasEnv, names, name))
                  | SOME (name, AN.UNDECIDED) =>
                    raise Control.Bug "recover: UNDECIDED variable"
                  | NONE =>
                    (* global variable definition has not been recovered. *)
                    raise Control.Bug "recover: undefined exported variable")
              (context, aliasEnv)
              (#exportVars context)

(*
        val _ =
            (print "newAliasEnv:\n";
             SEnv.appi (fn (x,y) => print (x^" -> "^y^"\n")) aliasEnv)
*)

        val (context, decls) = extractDecls context
      in
        (aliasEnv, topdecls @ decls)
      end

end
