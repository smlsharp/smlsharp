(**
 * A-Normalization
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalization.sml,v 1.21 2008/08/06 17:23:41 ohori Exp $
 *)
structure YAANormalization : YAANORMALIZATION =
struct

  structure CT = ConstantTerm
  structure RT = RBUTypes
  structure RBU = RBUCalc
  structure AN = YAANormal

  (* for YASIGenerator *)
  fun sisizeof anty =
      if Control.nativeGen() then AN.SIIGNORE
      else
        case anty of
          AN.UINT => AN.SISINGLE
        | AN.SINT => AN.SISINGLE
        | AN.BYTE => AN.SISINGLE
        | AN.CHAR => AN.SISINGLE
        | AN.BOXED => AN.SISINGLE
        | AN.POINTER => AN.SISINGLE
        | AN.FUNENTRY => AN.SISINGLE
        | AN.CODEPOINT => AN.SISINGLE
        | AN.FOREIGNFUN => AN.SISINGLE
        | AN.FLOAT => AN.SISINGLE
        | AN.DOUBLE => AN.SIDOUBLE
        | AN.PAD => raise Control.Bug "sizeof PAD"
        | AN.SIZE => AN.SISINGLE
        | AN.INDEX => AN.SISINGLE
        | AN.BITMAP => AN.SISINGLE
        | AN.OFFSET => AN.SISINGLE
        | AN.TAG => AN.SISINGLE
        | AN.ATOMty => AN.SISINGLE
        | AN.DOUBLEty => AN.SIDOUBLE
        | AN.SINGLEty _ => raise Control.Bug "sizeof SINGLEty"
        | AN.UNBOXEDty _ => raise Control.Bug "sizeof UNBOXEDty"
        | AN.GENERIC x => raise Control.Bug ("sizeof GENERIC "^Int.toString x)

  fun toSISize anvalue =
      if Control.nativeGen() then AN.SIIGNORE
      else
        case anvalue of
          AN.ANWORD 0w1 => AN.SISINGLE
        | AN.ANWORD 0w2 => AN.SIDOUBLE
        | AN.ANVAR varInfo => AN.SIVARIANT varInfo
        | _ => AN.SIIGNORE

  fun toSIExp anexp =
      if Control.nativeGen() then AN.SISIZE AN.SIIGNORE
      else
        case anexp of
          AN.ANVALUE value => AN.SISIZE (toSISize value)
        | AN.ANENVACC {nestLevel, offset, size = AN.ANWORD size, ty} =>
          AN.SIENVACC {nestLevel = nestLevel, offset = offset, size = size,
                       ty = ty}
        | _ => AN.SISIZE AN.SIIGNORE

  (*
   * NOTE:
   *   Previous phases may produce or keep dead code after RAISE.
   *   ANormalization must eliminate such obviously dead code in order
   *   not to leave untypable VAL expressions.
   *
   * Example:
   *   fun f x = (x, raise Fail "")
   *
   * The following code also produce dead code, but it is not problematic
   * because there is no unbound variable reference. Result of "if"
   * expression (i.e. SWITCH) is bound by MERGEPOINT which is never reached.
   *
   *   fun f x = (if x then raise Fail "" else raise Fail "") + 1
   *)
  fun elimDeadCode andeclList =
      let
        fun continue (l, h, t) = elim (h::l, t)
        and break (l, h, t) = skip (h::l, t)
        and skip (l, nil) = rev l
          | skip (l, t as AN.ANMERGEPOINT _::_) = elim (l, t)
          | skip (l, h::t) = skip (l, t)
        and elim (l, nil) = rev l
          | elim (l, h::t) =
            case h of
              AN.ANSETFIELD _ => continue (l, h, t)
            | AN.ANSETTAIL _ => continue (l, h, t)
            | AN.ANCOPYARRAY _ => continue (l, h, t)
            | AN.ANTAILAPPLY _ => break (l, h, t)
            | AN.ANTAILCALL _ => break (l, h, t)
            | AN.ANTAILRECCALL _ => break (l, h, t)
            | AN.ANTAILLOCALCALL _ => break (l, h, t)
            | AN.ANRETURN _ => break (l, h, t)
            | AN.ANLOCALRETURN _ => break (l, h, t)
            | AN.ANVAL _ => continue (l, h, t)
            | AN.ANVALCODE _ => continue (l, h, t)
            | AN.ANMERGE _ => break (l, h, t)
            | AN.ANMERGEPOINT _ => continue (l, h, t)
            | AN.ANRAISE _ => break (l, h, t)
            | AN.ANHANDLE _ => break (l, h, t)
            | AN.ANSWITCH _ => break (l, h, t)
      in
        elim (nil, andeclList)
      end

  fun newVar varKind anty =
      let
        val id = Counters.newLocalId ()
      in
        {id = id, displayName = "$" ^ VarID.toString id,
         varKind = varKind, ty = anty} : AN.varInfo
      end

  datatype returnKind =
      RETURN
    | LOCALRETURN

  fun AnReturn RETURN x = AN.ANRETURN x
    | AnReturn LOCALRETURN {valueList, tyList, sizeList, loc} =
      AN.ANLOCALRETURN {valueList = valueList,
                        tyList = tyList,
                        sizeList = sizeList,
                        loc = loc,
                        knownDestinations = ref nil}

  datatype bounddst =
      LOCAL of AN.varInfo
    | GLOBAL of {id: ExternalVarID.id, ty: AN.ty,
                 size: AN.anvalue, tag: AN.anvalue,
                 displayName: string}

  datatype position =
      Merge of {label: AN.id, dsts: AN.varInfo list, sizes: AN.sisize list}
    | Bound of {dsts: bounddst list, sizes: AN.sisize list}
    | Return of
      {
        returnKind: returnKind,
        decls: AN.andecl list,
        tys: AN.ty list,
        sizes: AN.sisize list
      }

  fun makeSetGlobal dsts loc =
      foldr
        (fn (dst, (vars, decls)) =>
            case dst of
              LOCAL var => (var::vars, decls)
            | GLOBAL {id, ty, size, tag, displayName} =>
              let
                val var = newVar AN.LOCAL ty
              in
                (var::vars,
                 AN.ANSETFIELD {array = AN.ANGLOBALSYMBOL
                                          {name = (displayName, AN.UNDECIDED),
                                           ann = AN.GLOBALVAR id,
                                           ty = AN.BOXED},
                                offset = AN.ANWORD 0w0,
                                value = AN.ANVAR var,
                                valueTy = ty,
                                valueSize = size,
                                valueTag = tag,
                                needBoundaryCheck = false,
                                loc = loc} :: decls)
              end)
        (nil, nil)
        dsts

  fun mergeLabel (Merge {label, ...}) = label
    | mergeLabel _ = raise Control.Bug "mergeLabel"

  fun branchPoint pos leaveHandler loc =
      case pos of
        Bound {dsts, sizes} =>
        let
          val label = Counters.newLocalId ()
          val (vars, decls) = makeSetGlobal dsts loc
        in
          {
            mergePointDecl =
                AN.ANMERGEPOINT {label = label, varList = vars,
                                 leaveHandler = leaveHandler, loc = loc}
                :: decls,
            branchPos =
                Merge {label = label, dsts = vars, sizes = sizes}
          }
        end
      | _ =>
        {mergePointDecl = nil, branchPos = pos}

  fun forceBranch pos leaveHandler loc =
      case pos of
        Bound _ => branchPoint pos leaveHandler loc
      | Merge {label, dsts, sizes} =>
        let
          val newLabel = Counters.newLocalId ()
        in
          {
            mergePointDecl =
                [
                  AN.ANMERGEPOINT {label = newLabel, varList = dsts,
                                   leaveHandler = leaveHandler, loc = loc},
                  AN.ANMERGE {label = label, varList = dsts, loc = loc}
                ],
            branchPos =
                Merge {label = newLabel, dsts = dsts, sizes = sizes}
          }
        end
      | Return {returnKind, decls, sizes, tys, ...} =>
        let
          val label = Counters.newLocalId ()
          val vars = map (newVar AN.LOCAL) tys
        in
          {
            mergePointDecl =
                AN.ANMERGEPOINT {label = label, varList = vars,
                                 leaveHandler = leaveHandler, loc = loc} ::
                decls @
                [
                  AnReturn returnKind {valueList = map AN.ANVAR vars,
                                       tyList = tys,
                                       sizeList = sizes,
                                       loc = loc}
                ],
            branchPos =
                Merge {label = label, dsts = vars, sizes = sizes}
          }
        end

  fun transformTy atty =
      case atty of
        RT.ATOMty => AN.ATOMty
      | RT.BOXEDty => AN.BOXED
      | RT.DOUBLEty => AN.DOUBLEty
      | RT.FLOATty => AN.FLOAT
      | RT.BOUNDVARty tid => AN.GENERIC tid
      | RT.SINGLEty tid => AN.SINGLEty tid
      | RT.UNBOXEDty tid => AN.UNBOXEDty tid
      | RT.SIZEty _ => AN.SIZE
      | RT.TAGty _ => AN.TAG
      | RT.INDEXty _ => AN.INDEX
      | RT.BITMAPty _ => AN.BITMAP
      | RT.ENVBITMAPty _ => AN.BITMAP
      | RT.FRAMEBITMAPty _ => AN.BITMAP
      | RT.OFFSETty _ => AN.OFFSET
      | RT.PADSIZEty _ => AN.SIZE
      | RT.PADty _ => AN.PAD

  fun transformLocalVar ({varId, displayName, ty, varKind}:RBU.varInfo) =
      case (varId, !varKind) of
        (Types.INTERNAL id, RBU.LOCAL) =>
        {id = id, displayName = displayName,
         ty = transformTy ty, varKind = AN.LOCAL} : AN.varInfo
      | _ =>
        raise Control.Bug "transformLocalVar"

  fun transformArgVar ({varId, displayName, ty, varKind}:RBU.varInfo) =
      case (varId, !varKind) of
        (Types.INTERNAL id, RBU.ARG) =>
        {id = id, displayName = displayName,
         ty = transformTy ty, varKind = AN.ARG} : AN.varInfo
      | _ =>
        raise Control.Bug "transformArgVar"

  fun transformLocalArgVar ({varId, displayName, ty, varKind}:RBU.varInfo) =
      case (varId, !varKind) of
        (Types.INTERNAL id, RBU.LOCALARG) =>
        {id = id, displayName = displayName,
         ty = transformTy ty, varKind = AN.LOCALARG} : AN.varInfo
      | _ =>
        raise Control.Bug "transformLocalArgVar"

  fun normalizeVar (varInfo as {varId, displayName, ty, varKind}:RBU.varInfo)
                   valueSizeExp =
      let
        fun var varKind =
            case varId of
              Types.INTERNAL id =>
              {id = id, displayName = displayName,
               ty = transformTy ty, varKind = varKind} : AN.varInfo
            | Types.EXTERNAL _ =>
              raise Control.Bug "normalizeVar: expected INTERNAL varId"
      in
        case !varKind of
          RBU.ARG =>
          (nil, nil, AN.ANVALUE (AN.ANVAR (var AN.ARG)))
        | RBU.LOCAL =>
          (nil, nil, AN.ANVALUE (AN.ANVAR (var AN.LOCAL)))
        | RBU.LOCALARG =>
          (nil, nil, AN.ANVALUE (AN.ANVAR (var AN.LOCALARG)))
        | RBU.FREEWORD {nestLevel, offset} =>
          let
            val (clusters, decls, anSize) = normalizeArg1 AN.SIZE valueSizeExp
          in
            (clusters, decls,
             AN.ANENVACC {nestLevel = nestLevel, offset = offset,
                          size = anSize, ty = transformTy ty})
          end
        | RBU.ENTRYLABEL _ =>
          raise Control.Bug "normalizeVar: ENTRYLABEL"
        | RBU.INNERLABEL _ =>
          raise Control.Bug "normalizeVar: INNERLABEL"
        | RBU.FREE =>
          raise Control.Bug "normalizeVar: FREE"
        | RBU.LOCALCODE _ =>
          raise Control.Bug "normalizeVar: LOCALCODE"
        | RBU.EXTERNAL =>
          case varId of
            Types.EXTERNAL id =>
            let
              val (clusters, decls, anSize) = normalizeArg1 AN.SIZE valueSizeExp
              val ty = transformTy ty
            in
              (clusters, decls,
               AN.ANGETFIELD {array = AN.ANGLOBALSYMBOL
                                        {name = (displayName, AN.UNDECIDED),
                                         ann = AN.GLOBALVAR id,
                                         ty = AN.BOXED},
                              offset = AN.ANWORD 0w0,
                              size = anSize,
                              needBoundaryCheck = false,
                              ty = ty})
            end
          | Types.INTERNAL _ =>
            raise Control.Bug "normalizeVar: EXTERNAL: expected EXTERNAL varId"
      end

  (* size is for YASIGenerator *)
  and normalizeArg anty size rbuexp =
      case rbuexp of
        RBU.RBUCONSTANT {value, loc} =>
        let
          fun makeBind const =
              let
                val var = newVar AN.LOCAL anty
              in
                (nil,
                 [
                   AN.ANVAL {varList = [var],
                             sizeList = [size],
                             exp = AN.ANCONST const,
                             loc = loc}
                 ],
                 AN.ANVAR var)
              end
        in
          case value of
            CT.INT x => (nil, nil, AN.ANINT x)
          | CT.LARGEINT _ => makeBind value
          | CT.WORD x => (nil, nil, AN.ANWORD x)
          | CT.BYTE x => (nil, nil, AN.ANBYTE x)
          | CT.STRING _ => makeBind value
          | CT.REAL _ => makeBind value
          | CT.FLOAT _ => makeBind value
          | CT.CHAR x => (nil, nil, AN.ANCHAR x)
          | CT.UNIT => (nil, nil, AN.ANUNIT)
          | CT.NULL => makeBind value
        end
      | RBU.RBUGLOBALSYMBOL {name, kind=Absyn.ForeignCodeSymbol, ty, loc} =>
        (nil, nil, AN.ANGLOBALSYMBOL {name = (name, AN.EXTERNSYMBOL),
                                      ann = AN.GLOBALOTHER,
                                      ty = AN.FOREIGNFUN})
      | RBU.RBUEXCEPTIONTAG {tagValue, displayName, loc} =>
        (nil, nil, AN.ANGLOBALSYMBOL {name = (displayName, AN.UNDECIDED),
                                      ann = AN.EXCEPTIONTAG tagValue,
                                      ty = AN.BOXED})
      | RBU.RBULABEL {codeId, loc} =>
        (nil, nil,
         case anty of
           AN.FUNENTRY => AN.ANLABEL codeId
         | _ => raise Control.Bug ("normalizeArg: invalid type for LABEL: "
                                   ^ Control.prettyPrint (AN.format_ty anty)))
      | RBU.RBUVAR {varInfo, valueSizeExp, loc} =>
        (case normalizeVar varInfo valueSizeExp of
           (clusters, decls, AN.ANVALUE value) =>
           (clusters, decls, value)
         | (clusters, decls, anexp) =>
           let
             val var = newVar AN.LOCAL anty
           in
             (clusters,
              decls @
              [
                AN.ANVAL {varList = [var],
                          sizeList = [size],
                          exp = anexp,
                          loc = loc}
              ],
              AN.ANVAR var)
           end)
      | _ =>
        let
          val var = newVar AN.LOCAL anty
          val (clusters, decls) =
              normalizeExp (Bound {dsts=[LOCAL var], sizes=[size]}) rbuexp
        in
          (clusters, decls, AN.ANVAR var)
        end

  and normalizeArgList anty size (rbuexp::expList) =
      let
        val (clusters1, decls1, value) = normalizeArg anty size rbuexp
        val (clusters2, decls2, values) = normalizeArgList anty size expList
      in
        (clusters1 @ clusters2, decls1 @ decls2, value :: values)
      end
    | normalizeArgList anty size nil = (nil, nil, nil)

  and normalizeArg1 anty rbuexp =
      normalizeArg anty (sisizeof anty) rbuexp

  and normalizeArg1List anty rbuexpList =
      normalizeArgList anty (sisizeof anty) rbuexpList

  (* for YASIGenerator *)
  and normalizeSISize rbuexp =
      if Control.nativeGen() then (nil, nil, AN.SIIGNORE)
      else
        let
          val (clusters1, decls1, value) = normalizeArg1 AN.SIZE rbuexp
        in
          (clusters1, decls1, toSISize value)
        end

  and normalizeSISizeList (rbuexp::expList) =
      let
        val (clusters1, decls1, size) = normalizeSISize rbuexp
        val (clusters2, decls2, sizes) = normalizeSISizeList expList
      in
        (clusters1 @ clusters2, decls1 @ decls2, size :: sizes)
      end
    | normalizeSISizeList nil = (nil, nil, nil)

  and normalizeArgListWithTy (atty::tyList) (size::sizeList) (rbuexp::expList) =
      let
        val anty = transformTy atty
        val (clusters1, decls1, sisize) = normalizeSISize size
        val (clusters2, decls2, value) = normalizeArg anty sisize rbuexp
        val (clusters3, decls3, tys, sizes, values) =
            normalizeArgListWithTy tyList sizeList expList
      in
        (clusters1 @ clusters2 @ clusters3, decls1 @ decls2 @ decls3,
         anty::tys, sisize::sizes, value::values)
      end
    | normalizeArgListWithTy nil nil nil = (nil, nil, nil, nil, nil)
    | normalizeArgListWithTy _ _ _ = raise Control.Bug "normalizeArgListWithTy"

  and makeUNIT pos loc =
      let
        fun setUnit dsts sizes =
            ListPair.map
              (fn (LOCAL dst, sisize) =>
                  AN.ANVAL {varList = [dst],
                            sizeList = [sisize],
                            exp = AN.ANVALUE AN.ANUNIT,
                            loc = loc}
                | (GLOBAL {id, tag, ty, size, displayName}, sisize) =>
                  AN.ANSETFIELD {array = AN.ANGLOBALSYMBOL
                                           {name = (displayName, AN.UNDECIDED),
                                            ann = AN.GLOBALVAR id,
                                            ty = AN.BOXED},
                                 offset = AN.ANWORD 0w0,
                                 value = AN.ANUNIT,
                                 valueTy = ty,
                                 valueSize = size,
                                 valueTag = tag,
                                 needBoundaryCheck = false,
                                 loc = loc})
              (dsts, sizes)
      in
        case pos of
          Bound {dsts, sizes} =>
          setUnit dsts sizes
        | Merge {label, dsts, sizes} =>
          setUnit (map LOCAL dsts) sizes @
          [
            AN.ANMERGE {label = label,
                        varList = dsts,
                        loc = loc}
          ]
        | Return {returnKind, decls, sizes, tys, ...} =>
          let
            val vars = map (newVar AN.LOCAL) tys
            val valueList = map AN.ANVAR vars
          in
            decls @
            setUnit (map LOCAL vars) sizes @
            [
              AnReturn returnKind {valueList = valueList,
                                   tyList = tys,
                                   sizeList = sizes,
                                   loc = loc}
            ]
          end
      end

  and makeVAL pos loc anexp =
      case pos of
        Bound {dsts, sizes} =>
        let
          val (vars, decls) = makeSetGlobal dsts loc
        in
          AN.ANVAL {varList = vars,
                    sizeList = sizes,
                    exp = anexp,
                    loc = loc}
          :: decls
        end
      | Merge {label, dsts, sizes} =>
        [
          AN.ANVAL {varList = dsts,
                    sizeList = sizes,
                    exp = anexp,
                    loc = loc},
          AN.ANMERGE {label = label,
                      varList = dsts,
                      loc = loc}
        ]
      | Return {returnKind, decls, sizes = nil, tys = nil, ...} =>
        (* return nothing *)
        decls @
        [
          AnReturn returnKind {valueList = [],
                               tyList = [],
                               sizeList = [],
                               loc = loc}
        ]
      | Return {returnKind, decls, sizes, tys, ...} =>
        let
          val vars = map (newVar AN.LOCAL) tys
        in
          decls @
          [
            AN.ANVAL {varList = vars,
                      sizeList = sizes,
                      exp = anexp,
                      loc = loc},
            AnReturn returnKind {valueList = map AN.ANVAR vars,
                                 tyList = tys,
                                 sizeList = sizes,
                                 loc = loc}
          ]
        end

  and normalizeExp pos rbuexp =
      case rbuexp of
        RBU.RBUCONSTANT {value, loc} =>
        (nil, makeVAL pos loc (AN.ANCONST value))
      | RBU.RBUGLOBALSYMBOL {name, kind=Absyn.ForeignCodeSymbol, ty, loc} =>
        (nil, makeVAL pos loc (AN.ANVALUE (AN.ANGLOBALSYMBOL
                                               {name = (name, AN.EXTERNSYMBOL),
                                                ann = AN.GLOBALOTHER,
                                                ty = AN.FOREIGNFUN})))
      | RBU.RBUEXCEPTIONTAG {tagValue, displayName, loc} =>
        (nil, makeVAL pos loc (AN.ANVALUE
                                 (AN.ANGLOBALSYMBOL
                                    {name = (displayName, AN.UNDECIDED),
                                     ann = AN.GLOBALOTHER,
                                     ty = AN.BOXED})))
      | RBU.RBULABEL {codeId, loc} =>
        (nil, makeVAL pos loc (AN.ANVALUE (AN.ANLABEL codeId)))

      | RBU.RBUVAR {varInfo, valueSizeExp, loc} =>
        let
          val (clusters1, decls1, value) = normalizeVar varInfo valueSizeExp
        in
          (clusters1, decls1 @ makeVAL pos loc value)
        end

      | RBU.RBUARRAY {bitmapExp, sizeExp, initialValue,
                      elementTy, elementSizeExp, isMutable, loc} =>
        let
          val (clusters1, decls1, anBitmap) = normalizeArg1 AN.BITMAP bitmapExp
          val (clusters2, decls2, anTotalSize) = normalizeArg1 AN.OFFSET sizeExp
          val anty = transformTy elementTy
          val (clusters3, decls3, anSize) = normalizeArg1 AN.SIZE elementSizeExp
          val (clusters4, decls4, anInitValue) =
              normalizeArg anty (toSISize anSize) initialValue
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4,
           decls1 @ decls2 @ decls3 @ decls4 @
           makeVAL pos loc
               (AN.ANARRAY {bitmap = anBitmap,
                            totalSize = anTotalSize,
                            initialValue = anInitValue,
                            elementTy = anty,
                            elementSize = anSize,
                            isMutable = isMutable}))
        end

      | RBU.RBUGETFIELD {arrayExp, offsetExp, sizeExp, elementTy, loc} =>
        let
          val (clusters1, decls1, anArray) = normalizeArg1 AN.BOXED arrayExp
          val (clusters2, decls2, anOffset) = normalizeArg1 AN.OFFSET offsetExp
          val (clusters3, decls3, anSize) = normalizeArg1 AN.SIZE sizeExp
          val anty = transformTy elementTy
        in
          (clusters1 @ clusters2 @ clusters3,
           decls1 @ decls2 @ decls3 @
           makeVAL pos loc
              (AN.ANGETFIELD {array = anArray,
                              offset = anOffset,
                              size = anSize,
                              needBoundaryCheck = true,
                              ty = anty}))
        end

      | RBU.RBUSETFIELD {arrayExp, offsetExp, valueExp, valueTy,
                         valueSizeExp, valueTagExp, loc} =>
        let
          val (clusters1, decls1, anArray) = normalizeArg1 AN.BOXED arrayExp
          val (clusters2, decls2, anOffset) = normalizeArg1 AN.OFFSET offsetExp
          val anty = transformTy valueTy
          val (clusters3, decls3, anSize) = normalizeArg1 AN.SIZE valueSizeExp
          val (clusters4, decls4, anTag) = normalizeArg1 AN.TAG valueTagExp
          val (clusters5, decls5, anValue) =
              normalizeArg anty (toSISize anSize) valueExp
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4 @ clusters5,
           decls1 @ decls2 @ decls3 @ decls4 @ decls5 @
           [
             AN.ANSETFIELD {array = anArray,
                            offset = anOffset,
                            value = anValue,
                            valueTy = anty,
                            valueSize = anSize,
                            valueTag = anTag,
                            needBoundaryCheck = true,
                            loc = loc}
           ] @
           makeUNIT pos loc)
        end

      | RBU.RBUCLOSURE {codeExp, envExp, loc} =>
        let
          val (clusters1, decls1, anLabel) = normalizeArg1 AN.FUNENTRY codeExp
          val (clusters2, decls2, anEnv) = normalizeArg1 AN.BOXED envExp
        in
          (clusters1 @ clusters2,
           decls1 @ decls2 @
           makeVAL pos loc
               (AN.ANCLOSURE {funLabel = anLabel,
                              env = anEnv}))
        end

      | RBU.RBUENTRYCLOSURE {codeExp, loc} =>
        let
          val (clusters1, decls1, anLabel) = normalizeArg1 AN.FUNENTRY codeExp
        in
          (clusters1,
           decls1 @
           makeVAL pos loc
               (AN.ANRECCLOSURE {funLabel = anLabel}))
        end

      | RBU.RBUINNERCLOSURE {codeExp, loc} =>
        raise Control.Bug "normalizeExp: RBUINNERCLOSURE"

      | RBU.RBUCALLBACKCLOSURE {codeExp, envExp,
                                argSizeExpList, resultSizeExpList,
                                argTyList, resultTyList, attributes, loc} =>
        let
          val (clusters1, decls1, anLabel) = normalizeArg1 AN.FUNENTRY codeExp
          val (clusters2, decls2, anEnv) = normalizeArg1 AN.BOXED envExp
          val anArgTys = map transformTy argTyList
          val anRetTys = map transformTy resultTyList
        in
          (clusters1 @ clusters2,
           decls1 @ decls2 @
           makeVAL pos loc
               (AN.ANCALLBACKCLOSURE {funLabel = anLabel,
                                      env = anEnv,
                                      argTyList = anArgTys,
                                      resultTyList = anRetTys,
                                      attributes = attributes}))
        end

      | RBU.RBUFOREIGNAPPLY {funExp, argExpList, argTyList, argSizeExpList,
                             resultTyList, attributes, loc} =>
        let
          val (clusters1, decls1, anFunc) = normalizeArg1 AN.CODEPOINT funExp
          val (clusters2, decls2, antys, _, anArgs) =
              normalizeArgListWithTy argTyList argSizeExpList argExpList
          val anRetTys = map transformTy resultTyList
        in
          (clusters1 @ clusters2,
           decls1 @ decls2 @
           makeVAL pos loc
               (AN.ANFOREIGNAPPLY {function = anFunc,
                                   argList = anArgs,
                                   argTyList = antys,
                                   resultTyList = anRetTys,
                                   attributes = attributes}))
        end

      | RBU.RBUPRIMAPPLY {prim, argExpList, argSizeExpList, argTyList,
                          resultTyList, instSizeExpList, instTagExpList, loc} =>
        let
          val (clusters1, decls1, antys, _, anArgs) =
              normalizeArgListWithTy argTyList argSizeExpList argExpList
          val (clusters2, decls2, anInstSizes) =
              normalizeArg1List AN.SIZE instSizeExpList
          val (clusters3, decls3, anInstTags) =
              normalizeArg1List AN.TAG instTagExpList
          val anRetTys = map transformTy resultTyList
        in
          (clusters1 @ clusters2 @ clusters3,
           decls1 @ decls2 @ decls3 @
           makeVAL pos loc
               (AN.ANPRIMAPPLY {prim = prim,
                                argList = anArgs,
                                argTyList = antys,
                                resultTyList = anRetTys,
                                instSizeList = anInstSizes,
                                instTagList = anInstTags}))
        end

      | RBU.RBUAPPM {funExp, argExpList, argTyList, argSizeExpList,
                     resultTyList, loc} =>
        let
          val (clusters1, decls1, anFun) = normalizeArg1 AN.BOXED funExp
          val (clusters2, decls2, antys, siSizes, anArgs) =
              normalizeArgListWithTy argTyList argSizeExpList argExpList
          val anRetTys = map transformTy resultTyList
        in
          (clusters1 @ clusters2,
           decls1 @ decls2 @
           (case (!Control.debugCodeGen, pos) of
              (* local code must localReturn or localTailCall;
               * it cannot tail call to a closure *)
              (false, Return {returnKind = RETURN, ...}) =>
              [
                AN.ANTAILAPPLY {closure = anFun,
                                argList = anArgs,
                                argTyList = antys,
                                resultTyList = anRetTys,
                                argSizeList = siSizes,
                                loc = loc}
              ]
            | _ =>
              makeVAL pos loc
                 (AN.ANAPPLY {closure = anFun,
                              argList = anArgs,
                              argTyList = antys,
                              resultTyList = anRetTys,
                              argSizeList = siSizes})))
        end

      | RBU.RBULOCALAPPM {funLabel, argVarList, argExpList, argTyList,
                          argSizeExpList, resultTyList, loc} =>
        let
          val (clusters1, decls1, antys, siSizes, anArgs) =
              normalizeArgListWithTy argTyList argSizeExpList argExpList
          val anRetTys = map transformTy resultTyList
        in
          (clusters1,
           decls1 @
           (case pos of
              (* only local code can localReturn *)
              Return {returnKind = LOCALRETURN, ...} =>
              [
                AN.ANTAILLOCALCALL {codeLabel = AN.ANLOCALCODE funLabel,
                                    argList = anArgs,
                                    argTyList = antys,
                                    resultTyList = anRetTys,
                                    argSizeList = siSizes,
                                    loc = loc,
                                    knownDestinations = ref nil}
              ]
            | _ =>
              makeVAL pos loc
                  (AN.ANLOCALCALL {codeLabel = AN.ANLOCALCODE funLabel,
                                   argList = anArgs,
                                   argTyList = antys,
                                   resultTyList = anRetTys,
                                   argSizeList = siSizes,
                                   returnLabel = Counters.newLocalId (),
                                   knownDestinations = ref nil})))
        end

      | RBU.RBURECCALL {codeExp, argExpList, argTyList, argSizeExpList,
                        resultTyList, loc} =>
        let
          val (clusters1, decls1, anFun) =
              normalizeArg1 AN.FUNENTRY codeExp
          val (clusters2, decls2, antys, siSizes, anArgs) =
              normalizeArgListWithTy argTyList argSizeExpList argExpList
          val anRetTys = map transformTy resultTyList
        in
          (clusters1 @ clusters2,
           decls1 @ decls2 @
           (case pos of
              (* local code cannot tail call to a closure *)
              Return {returnKind = RETURN, ...} =>
              [
                AN.ANTAILRECCALL {funLabel = anFun,
                                  argList = anArgs,
                                  argTyList = antys,
                                  resultTyList = anRetTys,
                                  argSizeList = siSizes,
                                  loc = loc}
              ]
            | _ =>
              makeVAL pos loc
                  (AN.ANRECCALL {funLabel = anFun,
                                 argList = anArgs,
                                 argTyList = antys,
                                 resultTyList = anRetTys,
                                 argSizeList = siSizes})))
        end

      | RBU.RBUINNERCALL {codeExp, argExpList, argTyList, argSizeExpList,
                          resultTyList, loc} =>
        raise Control.Bug "transformExp: RBUINNERCALL"

      | RBU.RBURECORD {bitmapExp, totalSizeExp, fieldList, fieldTyList,
                       fieldSizeExpList, isMutable, loc} =>
        let
          val (clusters1, decls1, anBitmap) =
              normalizeArg1 AN.BITMAP bitmapExp
          val (clusters2, decls2, anTotalSize) =
              normalizeArg1 AN.OFFSET totalSizeExp
          val (clusters3, decls3, antys, _, anValues) =
              normalizeArgListWithTy fieldTyList fieldSizeExpList fieldList
          val (clusters4, decls4, anSizes) =
              normalizeArg1List AN.SIZE fieldSizeExpList
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4,
           decls1 @ decls2 @ decls3 @ decls4 @
           makeVAL pos loc
               (AN.ANRECORD {bitmap = anBitmap,
                             totalSize = anTotalSize,
                             fieldList = anValues,
                             fieldSizeList = anSizes,
                             fieldTyList = antys}))
        end

      | RBU.RBUENVRECORD {bitmapExp, totalSize, fieldList, fieldTyList,
                          fieldSizeExpList, fixedSizeList, loc} =>
        let
          val (clusters1, decls1, anBitmap) =
              normalizeArg1 AN.BITMAP bitmapExp
          val (clusters2, decls2, antys, _, anValues) =
              normalizeArgListWithTy fieldTyList fieldSizeExpList fieldList
          val (clusters3, decls3, anSizes) =
              normalizeArg1List AN.SIZE fieldSizeExpList
        in
          (clusters1 @ clusters2 @ clusters3,
           decls1 @ decls2 @ decls3 @
           makeVAL pos loc
               (AN.ANENVRECORD {bitmap = anBitmap,
                                totalSize = totalSize,
                                fieldList = anValues,
                                fieldSizeList = anSizes,
                                fieldTyList = antys,
                                fixedSizeList = fixedSizeList}))
        end

      | RBU.RBUSELECT {recordExp, nestLevelExp, offsetExp, sizeExp, fieldTy,
                       loc} =>
        let
          val (clusters1, decls1, anRecord) = normalizeArg1 AN.BOXED recordExp
          val (clusters2, decls2, anNestLevel) =
              normalizeArg1 AN.UINT nestLevelExp
          val (clusters3, decls3, anOffset) = normalizeArg1 AN.OFFSET offsetExp
          val (clusters4, decls4, anSize) = normalizeArg1 AN.SIZE sizeExp
          val fieldTy = transformTy fieldTy
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4,
           decls1 @ decls2 @ decls3 @ decls4 @
           makeVAL pos loc
               (AN.ANSELECT {record = anRecord,
                             nestLevel = anNestLevel,
                             offset = anOffset,
                             size = anSize,
                             ty = fieldTy}))
        end

      | RBU.RBUMODIFY {recordExp, nestLevelExp, offsetExp, valueExp, valueTy,
                       valueSizeExp, valueTagExp, loc} =>
        let
          val (clusters1, decls1, anRecord) = normalizeArg1 AN.BOXED recordExp
          val (clusters2, decls2, anNestLevel) =
              normalizeArg1 AN.UINT nestLevelExp
          val (clusters3, decls3, anOffset) = normalizeArg1 AN.OFFSET offsetExp
          val anty = transformTy valueTy
          val (clusters4, decls4, anSize) = normalizeArg1 AN.SIZE valueSizeExp
          val (clusters5, decls5, anTag) = normalizeArg1 AN.TAG valueSizeExp
          val (clusters6, decls6, anValue) =
              normalizeArg anty (toSISize anSize) valueExp
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4 @ clusters5 @
           clusters6,
           decls1 @ decls2 @ decls3 @ decls4 @ decls5 @ decls6 @
           makeVAL pos loc
               (AN.ANMODIFY {record = anRecord,
                             nestLevel = anNestLevel,
                             offset = anOffset,
                             value = anValue,
                             valueTy = anty,
                             valueSize = anSize,
                             valueTag = anTag}))
        end

      | RBU.RBUSETTAIL {consExp, newTailExp, newTailTy, newTailSizeExp,
                        newTailTagExp, offsetExp, nestLevelExp, loc} =>
        let
          val (clusters1, decls1, anRecord) = normalizeArg1 AN.BOXED consExp
          val (clusters2, decls2, anNestLevel) =
              normalizeArg1 AN.UINT nestLevelExp
          val (clusters3, decls3, anOffset) = normalizeArg1 AN.OFFSET offsetExp
          val (clusters4, decls4, anSize) = normalizeArg1 AN.SIZE newTailSizeExp
          val (clusters5, decls5, anTag) = normalizeArg1 AN.SIZE newTailTagExp
          val newTailTy = transformTy newTailTy
          val (clusters6, decls6, anValue) =
              normalizeArg newTailTy (toSISize anSize) newTailExp
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4 @ clusters5,
           decls1 @ decls2 @ decls3 @ decls4 @ decls5 @
           [
             AN.ANSETTAIL {record = anRecord,
                           nestLevel = anNestLevel,
                           offset = anOffset,
                           value = anValue,
                           valueTy = newTailTy,
                           valueSize = anSize,
                           valueTag = anTag,
                           loc = loc}
           ] @
           makeUNIT pos loc)
        end

      | RBU.RBUCOPYARRAY {srcExp, srcOffsetExp, dstExp, dstOffsetExp,
                          lengthExp, elementTy, elementSizeExp, elementTagExp,
                          loc} =>
        let
          val (clusters1, decls1, anSrc) = normalizeArg1 AN.BOXED srcExp
          val (clusters2, decls2, anSrcOffset) =
              normalizeArg1 AN.OFFSET srcOffsetExp
          val (clusters3, decls3, anDst) = normalizeArg1 AN.BOXED dstExp
          val (clusters4, decls4, anDstOffset) =
              normalizeArg1 AN.OFFSET dstOffsetExp
          val (clusters5, decls5, anLength) = normalizeArg1 AN.OFFSET lengthExp
          val anty = transformTy elementTy
          val (clusters6, decls6, anSize) = normalizeArg1 AN.SIZE elementSizeExp
          val (clusters7, decls7, anTag) = normalizeArg1 AN.TAG elementTagExp
        in
          (clusters1 @ clusters2 @ clusters3 @ clusters4 @ clusters5 @
           clusters6 @ clusters7,
           decls1 @ decls2 @ decls3 @ decls4 @ decls5 @ decls6 @ decls7 @
           [
             AN.ANCOPYARRAY {src = anSrc,
                             srcOffset = anSrcOffset,
                             dst = anDst,
                             dstOffset = anDstOffset,
                             length = anLength,
                             elementTy = anty,
                             elementSize = anSize,
                             elementTag = anTag,
                             loc = loc}
           ] @
           makeUNIT pos loc)
        end

      | RBU.RBURAISE {argExp, loc} =>
        let
          val (clusters1, decls1, anValue) = normalizeArg1 AN.BOXED argExp
        in
          (clusters1,
           decls1 @
           [
             AN.ANRAISE {value = anValue,
                         loc = loc}
           ] @
           makeUNIT pos loc)
        end

      | RBU.RBULET {localDeclList, mainExp, loc} =>
        let
          val (clusters1, decls1) = normalizeDeclList localDeclList
          val (clusters2, decls2) = normalizeExp pos mainExp
        in
          (clusters1 @ clusters2, decls1 @ decls2)
        end

      | RBU.RBUMVALUES {expList, tyList, sizeExpList, loc} =>
        let
          fun normalizeMValue
                  (dst::dstVarList) (size::dstSizeList) (rbuexp::expList) =
              let
                val pos = Bound {dsts = [dst], sizes = [size]}
                val (clusters1, decls1) = normalizeExp pos rbuexp
                val (clusters2, decls2) =
                    normalizeMValue dstVarList dstSizeList expList
              in
                (clusters1 @ clusters2, decls1 @ decls2)
              end
            | normalizeMValue nil nil nil = (nil, nil)
            | normalizeMValue _ _ _ = raise Control.Bug "normalizeMValue"
        in
          case pos of
            Bound {dsts, sizes} =>
            normalizeMValue dsts sizes expList
          | Merge {label, dsts, sizes} =>
            let
              val (clusters1, decls1) =
                  normalizeMValue (map LOCAL dsts) sizes expList
            in
              (clusters1,
               decls1 @
               [
                 AN.ANMERGE {label = label,
                             varList = dsts,
                             loc = loc}
               ])
            end
          | Return {returnKind, ...} =>
            let
              val (clusters1, decls1, antys, siSizes, anValues) =
                  normalizeArgListWithTy tyList sizeExpList expList
            in
              (clusters1,
               decls1 @
               [
                 AnReturn returnKind {valueList = anValues,
                                      tyList = antys,
                                      sizeList = siSizes,
                                      loc = loc}
               ])
            end
        end

      | RBU.RBUHANDLE {exp, exnVar, handler, loc} =>
        let
          val tryLabel = Counters.newLocalId ()
          val handlerLabel = Counters.newLocalId ()
          val labels = {tryLabel = tryLabel, handlerLabel = handlerLabel}

          val {mergePointDecl, branchPos} = branchPoint pos NONE loc
          val {mergePointDecl=tryMergePointDecl, branchPos=tryPos} =
              forceBranch branchPos (SOME labels) loc
          val leaveLabel = mergeLabel tryPos

          val (clusters1, tryDecls) = normalizeExp tryPos exp
          val (clusters2, handlerDecls) = normalizeExp branchPos handler
          val anExnVar = transformLocalVar exnVar
        in
          (clusters1 @ clusters2,
           AN.ANHANDLE {try = elimDeadCode tryDecls,
                        exnVar = anExnVar,
                        handler = elimDeadCode handlerDecls,
                        labels = {tryLabel = tryLabel,
                                  leaveLabel = leaveLabel,
                                  handlerLabel = handlerLabel},
                        loc = loc}
           :: tryMergePointDecl @
           mergePointDecl)
        end

      | RBU.RBUSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val {mergePointDecl, branchPos} = branchPoint pos NONE loc

          val anValueTy = transformTy expTy
          val (clusters1, decls1, anValue) = normalizeArg1 anValueTy switchExp

          val (clusters2, anBranches) =
              foldr
                (fn ({constant, exp}, (clusters2, anBranches)) =>
                    let
                      val constant =
                          case constant of
                            RBU.RBUCONSTANT {value, loc} =>
                            AN.ANCONST value
                          | RBU.RBUEXCEPTIONTAG {tagValue, displayName, loc} =>
                            AN.ANVALUE (AN.ANGLOBALSYMBOL
                                          {name = (displayName, AN.UNDECIDED),
                                           ann = AN.EXCEPTIONTAG tagValue,
                                           ty = AN.BOXED})
                          | _ => raise Control.Bug "normalizeExp: RBUSWITCH"

                      val (clusters1, anBranch) = normalizeExp branchPos exp
                      val anBranch = elimDeadCode anBranch
                    in
                      (clusters1 @ clusters2,
                       {constant = constant, branch = anBranch}::anBranches)
                    end)
                (nil, nil)
                branches

          val (clusters3, defaultDecls) = normalizeExp branchPos defaultExp
          val defaultDecls = elimDeadCode defaultDecls
        in
          (clusters1 @ clusters2 @ clusters3,
           decls1 @
           AN.ANSWITCH {value = anValue,
                        valueTy = anValueTy,
                        branches = anBranches,
                        default = defaultDecls,
                        loc = loc}
           :: mergePointDecl)
        end

  and protectUncaughtException pos rbuexp loc =
      let
        val tryLabel = Counters.newLocalId ()
        val handlerLabel = Counters.newLocalId ()
        val labels = {tryLabel = tryLabel, handlerLabel = handlerLabel}
        val {mergePointDecl, branchPos} = branchPoint pos NONE loc
        val {mergePointDecl=tryMergePointDecl, branchPos=tryPos} =
            forceBranch branchPos (SOME labels) loc
        val leaveLabel = mergeLabel tryPos
        val (clusters1, tryDecls) = normalizeExp tryPos rbuexp
        val exnVar = newVar AN.LOCAL AN.BOXED
      in
        (clusters1,
         AN.ANHANDLE {try = elimDeadCode tryDecls,
                      exnVar = exnVar,
                      handler = [AN.ANRAISE {value = AN.ANVAR exnVar,
                                             loc = loc}],
                      labels = {tryLabel = tryLabel,
                                leaveLabel = leaveLabel,
                                handlerLabel = handlerLabel},
                      loc = loc}
         :: tryMergePointDecl @
         mergePointDecl)
      end

  and normalizeDstVarList ((varInfo as {varId,varKind,ty,displayName})::varList)
                          (size::sizeList) (tag::tagList) =
      (
        case (varId, !varKind) of
          (Types.INTERNAL _, RBU.LOCAL) =>
          let
            val (clusters1, decls1, size) = normalizeSISize size
            val var = LOCAL (transformLocalVar varInfo)
            val (clusters2, decls2, sizes, vars) =
                normalizeDstVarList varList sizeList tagList
          in
            (clusters1 @ clusters2, decls1 @ decls2, size::sizes, var::vars)
          end
        | (Types.EXTERNAL id, RBU.EXTERNAL) =>
          let
            val (clusters1, decls1, anSize) = normalizeArg1 AN.SIZE size
            val (clusters2, decls2, anTag) = normalizeArg1 AN.TAG tag
            val siSize = toSISize anSize
            val var = GLOBAL {id = id,
                              ty = transformTy ty,
                              tag = anTag,
                              size = anSize,
                              displayName = displayName}
            val (clusters3, decls3, sizes, vars) =
                normalizeDstVarList varList sizeList tagList
          in
            (clusters1 @ clusters2 @ clusters3,
             decls1 @ decls2 @ decls3, siSize::sizes, var::vars)
          end
        | _ =>
          raise Control.Bug "normalizeDstVarList: varKind"
      )
    | normalizeDstVarList nil nil nil = (nil, nil, nil, nil)
    | normalizeDstVarList _ _ _ = raise Control.Bug "normalizeDstVarList"

  and normalizeDecl rbudecl =
      case rbudecl of
        RBU.RBUVAL {boundVarList, sizeExpList, tagExpList, boundExp, loc} =>
        let
          val (clusters1, decls1, sizes, dstVars) =
              normalizeDstVarList boundVarList sizeExpList tagExpList
          val pos = Bound {dsts = dstVars, sizes = sizes}
          val (clusters2, decls2) = normalizeExp pos boundExp
        in
          (clusters1 @ clusters2, decls1 @ decls2)
        end

      | RBU.RBUVALCODE {codeList, isRecursive, loc} =>
        let
          val (clusters, codeList) = normalizeCodeDeclList codeList
        in
          (clusters,
           [
            AN.ANVALCODE {codeList = codeList,
                          loc = loc}
           ])
        end

      | RBU.RBUCLUSTER {frameInfo, entryFunctions, innerFunctions,
                        isRecursive, hasClosureEnv, loc} =>
        let
          val frameInfo = normalizeFrameInfo frameInfo
          val (clusters1, entryFunctions) =
              normalizeFunDeclList loc entryFunctions
          val clusterDecl =
              {
                clusterId = Counters.newClusterId (),
                frameInfo = frameInfo,
                entryFunctions = entryFunctions,
                hasClosureEnv = hasClosureEnv,
                loc = loc
              } : AN.clusterDecl
        in
          (clusters1 @ [clusterDecl], nil)
        end

  and normalizeDeclList (rbudecl::declList) =
      let
        val (clusters1, decls1) = normalizeDecl rbudecl
        val (clusters2, decls2) = normalizeDeclList declList
      in
        (clusters1 @ clusters2, decls1 @ decls2)
      end
    | normalizeDeclList nil = (nil, nil)

  and normalizeFreeValue rbuexp =
      case rbuexp of
        RBU.RBUCONSTANT {value = CT.WORD x, ...} =>
        AN.ANVALUE (AN.ANWORD x)
      | RBU.RBUVAR {varInfo as {varKind = ref RBU.ARG, ...}, ...} =>
        AN.ANVALUE (AN.ANVAR (transformArgVar varInfo))
      | RBU.RBUVAR {varInfo as {varKind = ref(RBU.FREEWORD{nestLevel,offset}),
                                ...},
                    valueSizeExp = RBU.RBUCONSTANT {value=CT.WORD size,...},
                    ...} =>
        AN.ANENVACC {nestLevel = nestLevel, offset = offset,
                     size = AN.ANWORD size, ty = AN.BITMAP}
      | _ => raise Control.Bug "normalizeFreeValue"

  and normalizeFrameInfo ({tyvars, bitmapFree, tagArgList}:RBU.frameInfo) =
      let
        val anBitmapFree = normalizeFreeValue bitmapFree
        val anTagArgList =
            map (fn RBU.RBUVAR {varInfo, ...} => transformArgVar varInfo
                  | _ => raise Control.Bug "normalizeFrameInfo")
                tagArgList
      in
        {
          tyvars = tyvars,
          bitmapFree = anBitmapFree,
          tagArgList = anTagArgList
        } : AN.frameInfo
      end

  and normalizeFunDecl loc ({codeId, argVarList, argSizeExpList, bodyExp,
                             resultTyList, resultSizeExpList, ffiAttributes}
                            :RBU.funDecl) =
      let
        val anArgVarList = map transformArgVar argVarList
        val siArgSizeList = map (toSIExp o normalizeFreeValue) argSizeExpList
        val anRetTyList = map transformTy resultTyList
        val (clusters1, decls, siSizes) = normalizeSISizeList resultSizeExpList

        val pos = Return {returnKind = RETURN,
                          decls = decls,
                          tys = anRetTyList,
                          sizes = siSizes}
        val (clusters2, bodyDecls) =
            case ffiAttributes of
              NONE => normalizeExp pos bodyExp
            | SOME _ => protectUncaughtException pos bodyExp loc
        val bodyDecls = elimDeadCode bodyDecls
      in
        (clusters1 @ clusters2,
         {
           codeId = codeId,
           argVarList = anArgVarList,
           argSizeList = siArgSizeList,
           body = bodyDecls,
           resultTyList = anRetTyList,
           ffiAttributes = ffiAttributes,
           loc = loc
         } : AN.funDecl)
      end

  and normalizeFunDeclList loc (funDecl::funDeclList) =
      let
        val (clusters1, funDecl) = normalizeFunDecl loc funDecl
        val (clusters2, funDecls) = normalizeFunDeclList loc funDeclList
      in
        (clusters1 @ clusters2, funDecl::funDecls)
      end
    | normalizeFunDeclList loc nil = (nil, nil)

  and normalizeCodeDecl ({codeLabel, argVarList, argSizeExpList, bodyExp,
                          resultTyList, resultSizeExpList, loc}:RBU.codeDecl) =
      let
        val anArgVarList = map transformLocalArgVar argVarList
        val siArgSizeList = map (toSIExp o normalizeFreeValue) argSizeExpList
        val anRetTyList = map transformTy resultTyList
        val (clusters1, decls, siSizes) = normalizeSISizeList resultSizeExpList

        val pos = Return {returnKind = LOCALRETURN,
                          decls = decls,
                          tys = anRetTyList,
                          sizes = siSizes}
        val (clusters2, bodyDecls) = normalizeExp pos bodyExp
        val bodyDecls = elimDeadCode bodyDecls
      in
        (clusters1 @ clusters2,
         {
           codeId = codeLabel,
           argVarList = anArgVarList,
           argSizeList = siArgSizeList,
           body = bodyDecls,
           resultTyList = anRetTyList,
           loc = loc
         } : AN.codeDecl)
      end

  and normalizeCodeDeclList (codeDecl::codeDeclList) =
      let
        val (clusters1, codeDecl) = normalizeCodeDecl codeDecl
        val (clusters2, codeDecls) = normalizeCodeDeclList codeDeclList
      in
        (clusters1 @ clusters2, codeDecl::codeDecls)
      end
    | normalizeCodeDeclList nil = (nil, nil)

  fun normalize rbudecls =
      let
        val pos = Return {returnKind = RETURN,
                          decls = nil,
                          tys = [AN.SINT],
                          sizes = [sisizeof AN.SINT]}
        val toplevelExp =
            RBU.RBULET {localDeclList = rbudecls,
                        mainExp = RBU.RBUCONSTANT {loc = Loc.noloc,
                                                   value = CT.INT 0},
                        loc = Loc.noloc}
        val (clusters, decls) =
            protectUncaughtException pos toplevelExp Loc.noloc
        val decls = elimDeadCode decls

        val topLevelEntryLabel = Counters.newLocalId ()

        val topLevelCluster =
            {
              clusterId = Counters.newClusterId (),
              frameInfo =
                {
                  tyvars = [],
                  bitmapFree = AN.ANVALUE (AN.ANWORD 0w0),
                  tagArgList = []
                },
              entryFunctions =
                [{
                   codeId = topLevelEntryLabel,
                   argVarList = [],
                   argSizeList = [],
                   body = decls,
                   resultTyList = [],
                   ffiAttributes = SOME Absyn.defaultFFIAttributes,
                   loc = Loc.noloc
                 }],
              hasClosureEnv = false,
              loc = Loc.noloc
            } : AN.clusterDecl

        (* first cluster is toplevel cluster. *)
        val clusters = topLevelCluster :: clusters

        val topdecs = map AN.ANCLUSTER clusters
        val topdecs = topdecs @ [ AN.ANENTERTOPLEVEL topLevelEntryLabel ]
      in
        topdecs
      end

end
