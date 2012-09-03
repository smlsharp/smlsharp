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
 * - globally unique name of every global variable and exception,
 * - set of global variables and exceptions to be exported,
 * - definitions of exceptions (both global and local ones), and
 * - explicit declarations of aliases across compilation units,
 *
 * In the sence of separate compilation, a "globally unique name" is an
 * unique string derived from user-specified name. When we consider separate
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

  type globalSymbolEnv
  val emptyGlobalSymbolEnv : globalSymbolEnv
  val initialGlobalSymbolEnv : globalSymbolEnv
  val extendGlobalSymbolEnv : globalSymbolEnv * globalSymbolEnv
                              -> globalSymbolEnv
  val pu_globalSymbolEnv : globalSymbolEnv Pickle.pu

  val recover :
      {
        newBasis: VarIDContext.topExternalVarIDBasis,
        newContext: TypeContext.context,
        globalSymbolEnv: globalSymbolEnv,
        compileUnitCount: int option  (* NONE = separate compilation mode *)
      }
      -> YAANormal.topdecl list
      -> (globalSymbolEnv * YAANormal.topdecl list)

end =
struct

  structure AN = YAANormal

  type globalSymbolEnv =
      {
        varEnv: string ExternalVarID.Map.map,
        exnEnv: string ExnTagID.Map.map,
        aliasEnv: string SEnv.map
      }

  val emptyGlobalSymbolEnv =
      {
        varEnv = ExternalVarID.Map.empty,
        exnEnv = ExnTagID.Map.empty,
        aliasEnv = SEnv.empty
      } : globalSymbolEnv

  val initialGlobalSymbolEnv =
      {
        varEnv = ExternalVarID.Map.empty,
        exnEnv = #exceptionGlobalNameMap BuiltinContext.builtinContext,
        aliasEnv = SEnv.empty
      } : globalSymbolEnv

  fun disjointUnion (s1, s2) =
      if s1 = s2 then s1
      else raise Control.Bug ("disjointUnion: " ^ s1 ^ " <> " ^ s2)

  fun extendGlobalSymbolEnv (env1:globalSymbolEnv, env2:globalSymbolEnv) =
      {
        varEnv = ExternalVarID.Map.unionWith disjointUnion
                                             (#varEnv env1, #varEnv env2),
        exnEnv = ExnTagID.Map.unionWith disjointUnion
                                        (#exnEnv env1, #exnEnv env2),
        aliasEnv = SEnv.unionWith disjointUnion
                                  (#aliasEnv env1, #aliasEnv env2)
      } : globalSymbolEnv

  local
    structure VarEnvPickler = OrdMapPickler(ExternalVarID.Map)
    structure ExnEnvPickler = OrdMapPickler(ExnTagID.Map)
  in
  val pu_globalSymbolEnv =
      Pickle.conv
        (fn (varEnv, exnEnv, aliasEnv) =>
            {varEnv=varEnv, exnEnv=exnEnv, aliasEnv=aliasEnv},
         fn {varEnv, exnEnv, aliasEnv} =>
            (varEnv, exnEnv, aliasEnv))
        (Pickle.tuple3 (VarEnvPickler.map (ExternalVarID.pu_ID, Pickle.string),
                        ExnEnvPickler.map (ExnTagID.pu_ID, Pickle.string),
                        EnvPickler.SEnv Pickle.string))
  end (* local *)

  (* Make a map from ExternalVarID to global name.
   * Since topVarIDEnv holds a map from string to ExternalVarID,
   * the desired map can be obtained by reversing the topVarIDEnv.
   * Correspondence between ExternalVarID and global name is not
   * one-to-one; same ExternalVarID may be assigned to more than two
   * different global names due to structure A = B, open, and/or
   * val x = y.
   * We regard that one of the global names corresponded to the same
   * ExternalVarID is variable definition, and others are aliases of
   * the definition.
   *)
  fun reverseExternalVarIDBasis
          ((_,topVarIDEnv):VarIDContext.topExternalVarIDBasis) =
      SEnv.foldli
        (fn (k, VarIDContext.Internal _, z) =>
            raise Control.Bug "reverseExternalVarIDBasis"
          | (k, VarIDContext.Dummy, z) => z
          | (k, VarIDContext.External i, z) =>
            case ExternalVarID.Map.find (z, i) of
              SOME v => ExternalVarID.Map.insert (z, i, SSet.add (v, k))
            | NONE => ExternalVarID.Map.insert (z, i, SSet.singleton k))
        ExternalVarID.Map.empty
        topVarIDEnv

  (* Extract definitions of global exceptions defined in the
   * current compile unit from the new type context.
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
                SOME v => ExnTagID.Map.insert (z, tag, SSet.add (v, name))
              | NONE => ExnTagID.Map.insert (z, tag, SSet.singleton name)
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

  datatype symbolDef =
      DEFINED of AN.globalSymbolName
    | REQUIRE of string * string list

  type context =
      {
        varEnv: AN.globalSymbolName ExternalVarID.Map.map,
        exnEnv: AN.globalSymbolName ExnTagID.Map.map,
        exportVars: SSet.set ExternalVarID.Map.map,
        exportExns: SSet.set ExnTagID.Map.map,
        newVarEnv: string ExternalVarID.Map.map,
        newExnEnv: string ExnTagID.Map.map,
        compileUnitCount: int option,
        decls: AN.topdecl list list
      }

  local
    fun fmt n s =
        if size s > n then s else StringCvt.padLeft #"0" n s

    (* In separate compilation mode, every toplevel name must be unique.
     * In sequential compilation mode, toplevel binding may be
     * overriden by following bindings. To make sure that all
     * global name are unique, we insert compilation unit count to
     * the global names. *)
    fun prefix NONE s = s
      | prefix (SOME n) s = fmt 3 (Int.fmt StringCvt.DEC (n + 1)) ^ s

    fun hex n =
        (if n < 16 then "0x0" else "0x")
        ^ String.map Char.toLower (Int.fmt StringCvt.HEX n)

    fun isSymbolChar c =
        Char.isAlphaNum c orelse c = #"." orelse c = #"_"

    fun escape (#"0" :: #"x" :: t) = "0x30" :: escape t
      | escape (h::t) =
        (if isSymbolChar h then str h else hex (ord h)) :: escape t
      | escape nil = nil

    fun mangle prefix name =
        "_SML" ^ prefix ^ "_" ^
        (if CharVector.all isSymbolChar name
            andalso not (String.isSubstring "0x" name)
         then name
         else String.concat (escape (String.explode name)))
  in

  fun varSymbol compileUnitCount name =
      mangle (prefix compileUnitCount "v") name

  fun exnSymbol compileUnitCount name =
      mangle (prefix compileUnitCount "e") name

  end (* local *)

  (* we assume that ID.toString makes an unique string. *)
  fun localVarSymbol count displayName vid =
      varSymbol count ("_" ^ displayName ^ "." ^ ExternalVarID.toString vid)

  fun localExnSymbol count displayName tag =
      exnSymbol count ("_" ^ displayName ^ "." ^ ExnTagID.toString tag)

  fun makeExceptionDecl symbol aliasSymbols =
      let
        val nameStringSymbol = symbol ^ "._name"
      in
        [
          AN.ANTOPCONST  {globalName = nameStringSymbol,
                          export = false,
                          constant = ConstantTerm.STRING symbol},
          AN.ANTOPRECORD {globalName = symbol,
                          export = true,
                          bitmaps = [tagOf AN.BOXED],
                          totalSize = sizeOf AN.BOXED,
                          fieldList = [AN.ANGLOBALSYMBOL
                                         {name = (nameStringSymbol,
                                                  AN.GLOBALSYMBOL),
                                          ann = AN.GLOBALOTHER,
                                          ty = AN.BOXED}],
                          fieldTyList = [AN.BOXED],
                          fieldSizeList = [sizeOf AN.BOXED]}
        ] @
        map (fn sym =>
                AN.ANTOPALIAS {globalName = sym,
                               export = true,
                               originalGlobalName = (symbol, AN.GLOBALSYMBOL)})
            aliasSymbols
      end

  fun makeGlobalVarDecl vid ty symbol aliasSymbols =
      [
        AN.ANTOPARRAY {globalName = symbol,
                       export = true,
                       externalVarID = SOME vid,
                       bitmap = tagOf ty,
                       totalSize = sizeOf ty,
                       initialValues = nil,
                       elementTy = ty,
                       elementSize = sizeOf ty,
                       isMutable = true}
      ] @
      map (fn name =>
              AN.ANTOPALIAS {globalName = name,
                             export = true,
                             originalGlobalName = (symbol, AN.GLOBALSYMBOL)})
          aliasSymbols

  fun recoverExceptionDecl (context:context) displayName tag =
      case ExnTagID.Map.find (#exnEnv context, tag) of
        SOME gname => (context, gname)
      | NONE =>
        let
          val syms =
              case ExnTagID.Map.find (#exportExns context, tag) of
                SOME syms => SSet.listItems syms
              | NONE =>
                (* this exception is defined in current compilation unit
                 * but not exported at top-level. Here we try to recover
                 * its declaration. Note that this exception may refer
                 * from subsequent compile units if there is a functor
                 * declaration using this exception in this compile unit. *)
                [localExnSymbol (#compileUnitCount context) displayName tag]
          val (sym, aliases) = (hd syms, tl syms)
              handle Empty => raise Control.Bug "recoverExceptionDecl"
          val decls = makeExceptionDecl sym aliases
          val gname = (sym, AN.GLOBALSYMBOL)
        in
          ({
             varEnv = #varEnv context,
             exnEnv = ExnTagID.Map.insert (#exnEnv context, tag, gname),
             exportVars = #exportVars context,
             exportExns = #exportExns context,
             newVarEnv = #newVarEnv context,
             newExnEnv = ExnTagID.Map.insert (#newExnEnv context, tag, sym),
             compileUnitCount = #compileUnitCount context,
             decls = decls :: #decls context
           } : context,
           gname)
        end

  fun recoverGlobalVarDecl (context:context) displayName vid ty =
      case ExternalVarID.Map.find (#varEnv context, vid) of
        SOME gname => (context, gname)
      | NONE =>
        let
          val syms =
              case ExternalVarID.Map.find (#exportVars context, vid) of
                SOME syms => SSet.listItems syms
              | NONE =>
                (* this variable is defined in current compilation unit
                 * but not exported at top-level. Note that this variable
                 * may refer from subsequent compile units if there is a
                 * functor declaration using this variable. *)
                [localVarSymbol (#compileUnitCount context) displayName vid]
          val (sym, aliases) = (hd syms, tl syms)
              handle Empty => raise Control.Bug "recoverGlobalVarDecl"
          val decls = makeGlobalVarDecl vid ty sym aliases
          val gname = (sym, AN.GLOBALSYMBOL)
        in
          ({
             varEnv = ExternalVarID.Map.insert (#varEnv context, vid, gname),
             exnEnv = #exnEnv context,
             exportVars = #exportVars context,
             exportExns = #exportExns context,
             newVarEnv = ExternalVarID.Map.insert (#newVarEnv context,vid,sym),
             newExnEnv = #newExnEnv context,
             compileUnitCount = #compileUnitCount context,
             decls = decls :: #decls context
           } : context,
           gname)
        end

  fun extractDecls (context:context) =
      ({
         varEnv = #varEnv context,
         exnEnv = #exnEnv context,
         exportVars = #exportVars context,
         exportExns = #exportExns context,
         newVarEnv = #newVarEnv context,
         newExnEnv = #newExnEnv context,
         compileUnitCount = #compileUnitCount context,
         decls = nil
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
                AN.GLOBALVAR id => recoverGlobalVarDecl context name id ty
              | AN.EXCEPTIONTAG tag => recoverExceptionDecl context name tag
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


  fun recover {newBasis, newContext, compileUnitCount, globalSymbolEnv}
              topdecls =
      let
        val {varEnv, exnEnv, aliasEnv} = globalSymbolEnv
        val exportVarNames = reverseExternalVarIDBasis newBasis
        val exportExnNames = extractExceptionDefinitions newContext

        val varEnv =
            ExternalVarID.Map.map (fn x => (x, AN.EXTERNSYMBOL)) varEnv
        val exnEnv =
            ExnTagID.Map.map (fn x => (x, AN.EXTERNSYMBOL)) exnEnv
        val exportVars =
            ExternalVarID.Map.map (SSet.map (varSymbol compileUnitCount))
                                  exportVarNames
        val exportExns =
            ExnTagID.Map.map (SSet.map (exnSymbol compileUnitCount))
                             exportExnNames

(*
        val _ =
            (print "varEnv:\n";
             ExternalVarID.Map.appi
               (fn (k,(v,_)) =>
                   print (ExternalVarID.toString k ^ " : " ^ v ^ "\n"))
               varEnv)
        val _ =
            (print "exnEnv:\n";
             ExnTagID.Map.appi
               (fn (k,(v,_)) =>
                   print (ExnTagID.toString k ^ " : " ^ v ^ "\n"))
               exnEnv)
        val _ =
            (print "aliasEnv:\n";
             SEnv.appi
               (fn (k,v) => print (k ^ " : " ^ v ^ "\n"))
               aliasEnv)
        val _ =
            (print "exportVars:\n";
             ExternalVarID.Map.appi
               (fn (k,v) => (print (ExternalVarID.toString k ^ " : ");
                             SSet.app (fn x => print (x^", ")) v;
                             print "\n"))
               exportVars)
        val _ =
            (print "exportExns:\n";
             ExnTagID.Map.appi
               (fn (k,v) => (print (ExnTagID.toString k ^ " : ");
                             SSet.app (fn x => print (x^", ")) v;
                             print "\n"))
               exportExns)
*)

        val context =
            {
              varEnv = varEnv,
              exnEnv = exnEnv,
              exportVars = exportVars,
              exportExns = exportExns,
              newVarEnv = ExternalVarID.Map.empty,
              newExnEnv = ExnTagID.Map.empty,
              compileUnitCount = compileUnitCount,
              decls = nil
            } : context

        val (context, topdecls) = recoverTopdeclList context topdecls

        fun addAliases (aliasEnv, origSym, aliasSyms) =
            SSet.foldl (fn (sym, aliasEnv) =>
                           SEnv.insert (aliasEnv, sym, origSym))
                       aliasEnv
                       aliasSyms

        val aliasEnv =
            ExternalVarID.Map.foldli
              (fn (vid, syms, aliasEnv) =>
                  case ExternalVarID.Map.find (#newVarEnv context, vid) of
                    SOME _ => aliasEnv
                  | NONE =>
                    case ExternalVarID.Map.find (#varEnv context, vid) of
                      SOME (sym, _) => addAliases (aliasEnv, sym, syms)
                    | NONE => raise Control.Bug "recover: orphan global var")
              SEnv.empty
              exportVars

        val (context, aliasEnv) =
            ExnTagID.Map.foldli
              (fn (tag, syms, (context, aliasEnv)) =>
                  case ExnTagID.Map.find (#newExnEnv context, tag) of
                    SOME _ => (context, aliasEnv)
                  | NONE =>
                    case ExnTagID.Map.find (#exnEnv context, tag) of
                      SOME (sym, _) =>
                      (* exception replication across compile unit. *)
                      (context, addAliases (aliasEnv, sym, syms))
                    | NONE =>
                      (* exported but unrecovered exception.
                       * This exception is defined for subsequent units. *)
                      (#1 (recoverExceptionDecl context "" tag), aliasEnv))
              (context, aliasEnv)
              exportExns

        val ({newVarEnv, newExnEnv, ...}, decls) = extractDecls context

        val newSymbolEnv =
            {varEnv = newVarEnv, exnEnv = newExnEnv, aliasEnv = aliasEnv}
            : globalSymbolEnv

(*
        val _ =
            (print "newVarEnv:\n";
             ExternalVarID.Map.appi
               (fn (k,v) =>
                   print (ExternalVarID.toString k ^ " : " ^ v ^ "\n"))
               newVarEnv)
        val _ =
            (print "newExnEnv:\n";
             ExnTagID.Map.appi
               (fn (k,v) =>
                   print (ExnTagID.toString k ^ " : " ^ v ^ "\n"))
               newExnEnv)
        val _ =
            (print "newAliasEnv:\n";
             SEnv.appi
               (fn (k,v) => print (k ^ " : " ^ v ^ "\n"))
               aliasEnv)
*)
      in
        (newSymbolEnv, topdecls @ decls)
      end

end
