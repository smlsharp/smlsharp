(**
 * Translation of datatypes to record types.
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure DatatypeCompilation : sig

  val compile : RecordCalc.rcdecl list -> TypedLambda.tldecl list

end =
struct

  structure RC = RecordCalc
  structure TL = TypedLambda
  structure CT = ConstantTerm
  structure BE = BuiltinEnv
  structure T = Types

  fun mapi f l =
      let
        fun loop (i, nil) = nil
          | loop (i, h::t) = f (i, h) :: loop (i + 1, t)
      in
        loop (1, l)
      end

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {path = ["$" ^ VarID.toString id], ty = ty, id = id} : TL.varInfo
      end

  fun exnConTy exnCon =
      case exnCon of
        RC.EXN {ty,...} => ty
      | RC.EXEXN {ty,...} => ty

  fun PolyTy f =
      let
        val tid = BoundTypeVarID.generate ()
        val tvarKind = {eqKind=Absyn.NONEQ, tvarKind=T.UNIV}
      in
        T.POLYty {boundtvars = BoundTypeVarID.Map.singleton (tid, tvarKind),
                  body = f (T.BOUNDVARty tid)}
      end

  fun RefTy elemTy =
      T.CONSTRUCTty {tyCon = BE.lookupTyCon BuiltinName.refTyName,
                     args = [elemTy]}

  fun BoolTy () =
      T.CONSTRUCTty {tyCon = BE.lookupTyCon BuiltinName.boolTyName, args = []}

  val contagTy = BE.WORDty 

  fun ConstTermTag const =
      CT.WORD (Word32.fromInt const)

  fun If {condExp, thenExp, elseExp, loc} =
      TL.TLSWITCH
        {switchExp = TL.TLCAST {exp = condExp,
                                targetTy = contagTy, (* bool *)
                                loc = loc},
         expTy = contagTy,
         branches = [{constant = ConstTermTag 0, exp = elseExp}],
         defaultExp = thenExp,
         loc = loc}

  (* expression term constructors with type computation *)
  local
    datatype binds =
        BIND of (TL.varInfo * (TL.loc -> TL.tlexp)) list
    datatype expTerm =
        EXP of (TL.loc -> TL.tlexp) * T.ty
      | VALUE of binds * (TL.loc -> TL.tlexp) * T.ty

    fun makeLet (BIND nil, exp) = exp
      | makeLet (BIND binds, exp) =
        fn loc =>
           let
             val binds =
                 map (fn (v, e) => TL.TLVAL {boundVar = v,
                                             boundExp = e loc,
                                             loc = loc})
                     binds
           in
             case exp loc of
               TL.TLLET {localDeclList=binds2, mainExp, loc} =>
               TL.TLLET {localDeclList = binds @ binds2,
                         mainExp = mainExp,
                         loc = loc}
             | mainExp =>
               TL.TLLET {localDeclList = binds,
                         mainExp = mainExp,
                         loc = loc}
           end

    fun asEXP (EXP x) = x
      | asEXP (VALUE (binds, exp, ty)) = (makeLet (binds, exp), ty)

    fun asVALUE (VALUE x) = x
      | asVALUE (EXP (exp, ty)) =
        let
          val var = newVar ty
        in
          (BIND [(var, exp)], fn loc => TL.TLVAR {varInfo=var, loc=loc}, ty)
        end

    fun isValueExp tlexp =
        case tlexp of
          TL.TLFOREIGNAPPLY _ => false
        | TL.TLEXPORTCALLBACK _ => false
        | TL.TLCONSTANT _ => true
        | TL.TLGLOBALSYMBOL _ => true
        | TL.TLTAGOF _ => true
        | TL.TLSIZEOF _ => true
        | TL.TLINDEXOF _ => true
        | TL.TLVAR _ => true
        | TL.TLEXVAR _ => true
        | TL.TLPRIMAPPLY _ => false
        | TL.TLAPPM _ => false
        | TL.TLLET _ => false
        | TL.TLRECORD _ => false
        | TL.TLSELECT _ => false
        | TL.TLMODIFY _ => false
        | TL.TLRAISE _ => false
        | TL.TLHANDLE _ => false
        | TL.TLFNM _ => false
        | TL.TLPOLY _ => false
        | TL.TLTAPP _ => false
        | TL.TLSWITCH _ => false
        | TL.TLCAST {exp,...} => isValueExp exp

  in

  val bindNothing = BIND nil

  fun pack (tlexp, ty) =
      if isValueExp tlexp
      then VALUE (BIND nil, fn _ => tlexp, ty)
      else EXP (fn _ => tlexp, ty)

  fun unpack (term, loc) =
      #1 (asEXP term) loc

  fun valueForm term =
      let
        val (binds, exp, ty) = asVALUE term
      in
        (binds, VALUE (BIND nil, exp, ty))
      end

  fun termTy (EXP (exp, ty)) = ty
    | termTy (VALUE (binds, exp, ty)) = ty

  fun bind (var, EXP (exp, ty)) =
      BIND [(var, exp)]
    | bind (var, VALUE (BIND binds, exp, ty)) =
      BIND (binds @ [(var, exp)])

  fun Let (binds, tlexp, loc) =
      makeLet (binds, fn _ => tlexp) loc

  fun LET (binds, EXP (exp, ty)) =
      EXP (makeLet (binds, exp), ty)
    | LET (BIND binds2, VALUE (BIND binds1, exp, ty)) =
      VALUE (BIND (binds1 @ binds2), exp, ty)

  fun CAST (ty, EXP (exp, _)) =
      EXP (fn loc => TL.TLCAST {exp = exp loc, targetTy = ty, loc = loc}, ty)
    | CAST (ty, VALUE (binds, exp, _)) =
      VALUE (binds,
             fn loc => TL.TLCAST {exp = exp loc, targetTy = ty, loc = loc},
             ty)

  fun CONST (const, ty) =
      VALUE (BIND nil, fn loc => TL.TLCONSTANT {value=const, loc=loc}, ty)

  fun VAR varInfo =
      VALUE (BIND nil, fn loc => TL.TLVAR {varInfo=varInfo, loc=loc},
             #ty varInfo)

  fun EXVAR exVarInfo =
      VALUE (BIND nil, fn loc => TL.TLEXVAR {exVarInfo=exVarInfo, loc=loc},
             #ty exVarInfo)

  fun PRIMAPPLY (primInfo, instTyList, argTermList) =
      let
        val args = map (fn x => #1 (asEXP x)) argTermList
        val retTy = TypesUtils.tpappTy (#ty primInfo, instTyList)
      in
        EXP (fn loc =>
                TL.TLPRIMAPPLY {primInfo = primInfo,
                                instTyList = instTyList,
                                argExpList = map (fn e => e loc) args,
                                loc = loc},
             retTy)
      end

  fun IF {condExp, thenExp, elseExp} =
      let
        val (condExp, _) = asEXP condExp
        val (thenExp, retTy) = asEXP thenExp
        val (elseExp, _) = asEXP elseExp
      in
        EXP (fn loc => If {condExp = condExp loc,
                           thenExp = thenExp loc,
                           elseExp = elseExp loc,
                           loc = loc},
             retTy)
      end

  fun RECORD (labels, terms) =
      let
        val (binds, fields, tys) =
            ListPair.foldrEq
              (fn (label, term, (binds, fields, tys)) =>
                  let
                    val (BIND binds2, exp, ty) = asVALUE term
                  in
                    (binds2 @ binds,
                     LabelEnv.insert (fields, label, exp),
                     LabelEnv.insert (tys, label, ty))
                  end)
              (nil, LabelEnv.empty, LabelEnv.empty)
              (labels, terms)
        val recordTy = T.RECORDty tys
      in
        LET (BIND binds,
             EXP (fn loc => TL.TLRECORD
                              {isMutable = false,
                               fields = LabelEnv.map (fn f => f loc) fields,
                               recordTy = recordTy,
                               loc = loc},
                  recordTy))
      end

  fun TUPLE terms =
      RECORD (mapi (fn (i,_) => Int.toString i) terms, terms)

  fun SELECT (label, term) =
      let
        val (exp, ty) = asEXP term
        val fields =
            case TypesUtils.derefTy ty of
              T.RECORDty fields => fields
            | _ => raise Control.Bug "SELECT: type error"
        val fieldTy =
            case LabelEnv.find (fields, label) of
              SOME ty => ty
            | NONE => raise Control.Bug "SELECT: label not found"
      in
        EXP (fn loc =>
                case exp loc of
                  TL.TLRECORD {isMutable=false, fields, ...} =>
                  (
                    case LabelEnv.find (fields, label) of
                      NONE => raise Control.Bug "SELECT: field not found"
                    | SOME exp => exp
                  )
                | exp =>
                  TL.TLSELECT
                    {recordExp = exp,
                     indexExp = TL.TLINDEXOF {label = label,
                                              recordTy = ty,
                                              loc = loc},
                     label = label,
                     recordTy = ty,
                     resultTy = fieldTy,
                     loc = loc},
             fieldTy)
      end

  end (* local *)

  fun explodeRecordExp term =
      let
        val (binds, recordTerm) =
            case unpack (term, Loc.noloc) of
              TL.TLRECORD {isMutable=false,...} => (bindNothing, term)
            | _ => valueForm term
        val fields =
            case TypesUtils.derefTy (termTy recordTerm) of
              T.RECORDty tys =>
              map (fn label => SELECT (label, recordTerm))
                  (LabelEnv.listKeys tys)
            | _ => [recordTerm]
      in
        (binds, fields)
      end

  fun explodeRecordTy ty =
      case TypesUtils.derefTy ty of
        T.RECORDty fields => ListPair.unzip (LabelEnv.listItemsi fields)
      | _ => raise Control.Bug "explodeRecordTy"

  fun tupleTy tys =
      T.RECORDty 
        (
         List.foldl 
           (fn ((key, item), m) => LabelEnv.insert (m, key, item)) LabelEnv.empty 
           (mapi (fn (i,ty) => (Int.toString i, ty)) tys)
        )

  fun splitLet tlexp =
      case tlexp of
        TL.TLLET {localDeclList, mainExp, loc} =>
        (fn mainExp => TL.TLLET {localDeclList = localDeclList,
                                 mainExp = mainExp,
                                 loc = loc},
         mainExp)
      | _ => (fn exp => exp, tlexp)

  fun splitLetOpt NONE = (fn exp => exp, NONE)
    | splitLetOpt (SOME exp) =
      let
        val (letFn, exp) = splitLet exp
      in
        (letFn, SOME exp)
      end

  fun TagConst const =
      CONST (ConstTermTag const, BE.WORDty)

  fun NullConst () =
      CONST (CT.NULLBOXED, BE.BOXEDty)

  fun IsNull term =
      PRIMAPPLY ({primitive = BuiltinPrimitive.IdentityEqual,
                  ty = T.FUNMty ([BE.BOXEDty, BE.BOXEDty], BoolTy ())},
                 nil,
                 [CAST (BE.BOXEDty, term), NullConst ()])

  fun ExnTagEqual (exp1, exp2) =
      PRIMAPPLY ({primitive = BuiltinPrimitive.IdentityEqual,
                  ty = T.FUNMty ([BE.EXNTAGty, BE.EXNTAGty], BoolTy ())},
                 nil,
                 [exp1, exp2])

  fun RefAlloc elemTerm =
      let
        val primTy = PolyTy (fn tv => T.FUNMty ([tv], RefTy tv))
      in
        PRIMAPPLY ({primitive = BuiltinPrimitive.Ref_alloc, ty = primTy},
                   [termTy elemTerm],
                   [elemTerm])
      end

  fun RefDeref refTerm =
      let
        val primTy = PolyTy (fn tv => T.FUNMty ([RefTy tv], tv))
        val elemTy = case TypesUtils.derefTy (termTy refTerm) of
                       T.CONSTRUCTty {args=[ty],...} => ty
                     | _ => raise Control.Bug "RefDeref"
      in
        PRIMAPPLY ({primitive = BuiltinPrimitive.Ref_deref, ty = primTy},
                   [elemTy],
                   [refTerm])
      end

  (*
   * "layout" represents how to implement each data constructor of a datatype.
   *
   * LAYOUT_TAGGED_RECORD:
   * Each variant is implemented as a tuple type consisting of a tag field
   * and arguments of the variant.
   *   datatype 'a foo = Foo of int * int   --> contagty * int * int
   *                   | Bar of bool        --> contagty * bool
   *                   | Baz of 'a          --> contagty * 'a
   *   (The format of Baz is decided regardless of any instance of 'a)
   *
   * LAYOUT_TAGGED_TAGONLY:
   * If all variants have no argument, they can be distinguished only by
   * a tag integer.
   *   datatype foo = Foo                  --> int
   *                | Bar                  --> int
   *                | Baz                  --> int
   *
   * LAYOUT_BOOL:
   * If there are just two variant and both of them have no argument,
   * these variants can be implemented like "bool";
   * one variant is 0, and another is any integer other than 0.
   *   datatype bool = false               --> int (0)
   *                 | true                --> int (other than 0)
   *
   * LAYOUT_UNIT:
   * If there is just one variant with no argument, this can be implemented
   * like "unit"; it can be implemented with an arbitrary integer.
   *   datatype foo = Foo                  --> int (any integer is OK)
   *
   * (FIXME: LAYOUT_BOOL and LAYOUT_UNIT may make equality check difficult.)
   *
   * LAYOUT_ARGONLY:
   * If there is just one variant with an argument, no tag is needed.
   *   datatype foo = Foo of int           --> {1:int}
   *   datatype foo = Foo of int * int     --> int * int
   *   datatype 'a foo = Foo of 'a         --> {1:'a}
   *
   * LAYOUT_TAGGED_OR_NULL:
   * If there is just one variant with no argument and other variants have
   * arguments, the no-argument variant can be implemented as a null pointer.
   * Any other variants are implemented in the same way as LAYOUT_TAGGED_RECORD.
   *   datatype foo = Foo of int           --> contagty * int
   *                | Bar of int * int     --> contagty * int * int
   *                | Baz                  --> NULL (boxedty)
   *
   * LAYOUT_ARG_OR_NULL:
   * If there is just two variants and one has an argument but another does
   * not, then the no-arguemnt variant can be implemented as a null pointer.
   * The variant with argument is implemented by a record.
   *   datatype foo = Foo of int           --> {1:int}
   *                | Bar                  --> NULL (boxedty)
   *   datatype foo = Foo of int * int     --> int * int
   *                | Bar                  --> NULL (boxedty)
   *
   * LAYOUT_REF:
   * Special data representation for ref.
   *)
  datatype taggedLayout =
      TAGGED_RECORD of {tagMap: int SEnv.map}
    | TAGGED_TAGONLY of {tagMap: int SEnv.map}
    | TAGGED_OR_NULL of {tagMap: int SEnv.map}

  datatype layout =
      LAYOUT_TAGGED of taggedLayout
    | LAYOUT_BOOL of {falseName: string}
    | LAYOUT_UNIT
    | LAYOUT_ARGONLY
    | LAYOUT_ARG_OR_NULL
    | LAYOUT_REF

  fun checkRepresentation (runtimeTy, layout) =
      case layout of
        LAYOUT_TAGGED (TAGGED_RECORD _) => runtimeTy = BuiltinType.BOXEDty
      | LAYOUT_TAGGED (TAGGED_TAGONLY _) => runtimeTy = BuiltinType.WORDty
      | LAYOUT_TAGGED (TAGGED_OR_NULL _) => runtimeTy = BuiltinType.BOXEDty
      | LAYOUT_BOOL _ => runtimeTy = BuiltinType.WORDty
      | LAYOUT_UNIT => runtimeTy = BuiltinType.WORDty
      | LAYOUT_ARGONLY => runtimeTy = BuiltinType.BOXEDty
      | LAYOUT_ARG_OR_NULL => runtimeTy = BuiltinType.BOXEDty
      | LAYOUT_REF => runtimeTy = BuiltinType.BOXEDty

  fun countBool l =
      let
        fun count (t, f, nil) = {t=t, f=f}
          | count (t, f, true::l) = count (t + 1, f, l)
          | count (t, f, false::l) = count (t, f + 1, l)
      in
        count (0, 0, l)
      end

  fun decomposeDataconTy ty =
      case TypesUtils.derefTy ty of
        T.POLYty {boundtvars, body} => decomposeDataconTy body
      | T.FUNMty ([argTy], retTy) => (SOME argTy, retTy)
      | T.FUNMty _ => raise Control.Bug "dataconTy"
      | T.CONSTRUCTty _ => (NONE, ty)
      | _ => raise Control.Bug "decomposeDataconTy"

  fun dataconArgTy ty =
      case decomposeDataconTy ty of
        (SOME argTy, retTy) => argTy
      | _ => raise Control.Bug "dataconArgTy"

  fun extractDatatypeTyCon ty =
      (* ty must be the type of either data or data constructor. *)
      case TypesUtils.derefTy ty of
        T.POLYty {boundtvars, body} => extractDatatypeTyCon body
      | T.FUNMty (_, retTy) => extractDatatypeTyCon ty  (* constructor type *)
      | T.CONSTRUCTty {tyCon, args} =>
        (
          case #dtyKind tyCon of
            T.DTY => tyCon
          | _ => raise Control.Bug "extractDatatypeTyCon: not a datatype"
        )
      | _ => raise Control.Bug "extractTyCon"

  fun makeTagMap conSet =
      #2 (SEnv.foldli (fn (key, _, (i, map)) =>
                          (i + 1, SEnv.insert (map, key, i)))
                      (1, SEnv.empty)
                      conSet)

  fun datatypeLayout ({id, conSet, runtimeTy, ...}:T.tyCon) =
      let
        val layout =
            case map #hasArg (SEnv.listItems conSet) of
              nil => raise Control.Bug "datatypeLayout: no variant"
            | [true] =>
              if TypID.eq (id, #id (BE.lookupTyCon BuiltinName.refTyName))
              then LAYOUT_REF
              else LAYOUT_ARGONLY
            | [false] => LAYOUT_UNIT
            | [false, false] =>
              (
                if TypID.eq (id, #id (BE.lookupTyCon BuiltinName.boolTyName))
                then LAYOUT_BOOL {falseName = "false"}
                else case SEnv.firsti conSet of
                       SOME (name, _) => LAYOUT_BOOL {falseName = name}
                     | NONE => raise Control.Bug "datatypeLayout: BOOL"
              )
            | hasArgList =>
              case countBool hasArgList of
                {t=0, f=_} =>
                LAYOUT_TAGGED (TAGGED_TAGONLY {tagMap = makeTagMap conSet})
              | {t=1, f=1} => LAYOUT_ARG_OR_NULL
              | {t=_, f=1} =>
                LAYOUT_TAGGED (TAGGED_OR_NULL {tagMap = makeTagMap conSet})
              | {t=_, f=_} =>
                LAYOUT_TAGGED (TAGGED_RECORD {tagMap = makeTagMap conSet})
      in
        if checkRepresentation (runtimeTy, layout)
        then layout
        else raise Control.Bug "datatypeLayout"
      end

  fun lookupConTag (taggedLayout, {path, ty, ...}:T.conInfo) =
      let
        fun lookup tagMap =
            case SEnv.find (tagMap, List.last path) of
              NONE => raise Control.Bug "dataconTag"
            | SOME tag => tag : int
      in
        case taggedLayout of
          TAGGED_TAGONLY {tagMap} => lookup tagMap
        | TAGGED_RECORD {tagMap} => lookup tagMap
        | TAGGED_OR_NULL {tagMap} =>
          case decomposeDataconTy ty of
            (SOME _, _) => lookup tagMap
          | (NONE, _) => 0
      end

  fun extractConTag (layout, term) =
      case layout of
        TAGGED_TAGONLY _ => CAST (contagTy, term)
      | TAGGED_RECORD _ => SELECT ("1", CAST (tupleTy [contagTy], term))
      | TAGGED_OR_NULL _ =>
        let
          val (binds, term) = valueForm term
        in
          LET (binds, 
               IF {condExp = IsNull term,
                   thenExp = TagConst 0,
                   elseExp =
                     SELECT ("1", CAST (tupleTy [contagTy], term))})
        end

  fun composeTaggedCon (taggedLayout, conInfo, argTerm) =
      let
        val tag = TagConst (lookupConTag (taggedLayout, conInfo))
      in
        case argTerm of
          NONE => TUPLE [tag]
        | SOME term =>
          let
            val (binds, terms) = explodeRecordExp term
          in
            LET (binds, TUPLE (tag::terms))
          end
      end

  fun decomposeTaggedCon (conInfo:T.conInfo, dataTerm) expectTy =
      let
        val (fieldLabels, fieldTys) =
            case TypesUtils.derefTy (dataconArgTy (#ty conInfo)) of
              T.RECORDty _ => explodeRecordTy expectTy
            | _ => (nil, [expectTy])
        val fieldTys = contagTy :: fieldTys
        val dataTerm = CAST (tupleTy fieldTys, dataTerm)
        val (binds, exps) = explodeRecordExp dataTerm
      in
        case (fieldLabels, exps) of
          (nil, [_, term]) => LET (binds, term)
        | (nil, _) => raise Control.Bug "decomposeTaggedCon"
        | (_, _::t) => LET (binds, RECORD (fieldLabels, t))
        | (_, nil) => raise Control.Bug "decomposeTaggedCon"
      end

  fun composeArgOnlyCon (argTerm, conArgTy) =
      case TypesUtils.derefTy conArgTy of
        T.RECORDty _ => argTerm
      | _ => TUPLE [argTerm]

  fun decomposeArgOnlyCon (conInfo:T.conInfo, dataTerm) expectTy =
      case TypesUtils.derefTy (dataconArgTy (#ty conInfo)) of
        T.RECORDty _ => CAST (expectTy, dataTerm)
      | _ => SELECT ("1", CAST (tupleTy [expectTy], dataTerm))

  fun composeCon (conInfo:T.conInfo, instTyList, argExpOpt) =
      let
        val conInstTy = TypesUtils.tpappTy (#ty conInfo, instTyList)
        val (argTy, retTy) = decomposeDataconTy conInstTy
        val argTerm =
            case (argTy, argExpOpt) of
              (NONE, NONE) => NONE
            | (SOME argTy, SOME argExp) => SOME (pack (argExp, argTy))
            | _ => raise Control.Bug "composeCon"
        val (conArgTy, conRetTy) = decomposeDataconTy (#ty conInfo)
        val tyCon = extractDatatypeTyCon conRetTy
        val layout = datatypeLayout tyCon
        val term =
            case layout of
              LAYOUT_TAGGED (layout as TAGGED_RECORD _) =>
              composeTaggedCon (layout, conInfo, argTerm)
            | LAYOUT_TAGGED (layout as TAGGED_TAGONLY _) =>
              (
                case argTerm of
                  SOME _ => raise Control.Bug "composeCon: TAGGED_TAGONLY"
                | NONE => TagConst (lookupConTag (layout, conInfo))
              )
            | LAYOUT_TAGGED (layout as TAGGED_OR_NULL _) =>
              (
                case argTerm of
                  NONE => NullConst ()
                | SOME _ => composeTaggedCon (layout, conInfo, argTerm)
              )
            | LAYOUT_BOOL {falseName} =>
              (
                case argTerm of
                  SOME _ => raise Control.Bug "composeCon: LAYOUT_BOOL"
                | NONE =>
                  if List.last (#path conInfo) = falseName
                  then TagConst 0 else TagConst 1
              )
            | LAYOUT_UNIT =>
              (
                case argTerm of
                  SOME _ => raise Control.Bug "composeCon: LAYOUT_UNIT"
                | NONE => TagConst 0
              )
            | LAYOUT_ARGONLY =>
              (
                case (argTerm, conArgTy) of
                  (SOME term, SOME argTy) => composeArgOnlyCon (term, argTy)
                | _ => raise Control.Bug "composeCon: LAYOUT_ARGONLY"
              )
            | LAYOUT_ARG_OR_NULL =>
              (
                case (argTerm, conArgTy) of
                  (NONE, NONE) => NullConst ()
                | (SOME term, SOME argTy) => composeArgOnlyCon (term, argTy)
                | _ => raise Control.Bug "composeCon: LAYOUT_ARG_OR_NULL"
              )
            | LAYOUT_REF =>
              (
                case argTerm of
                  NONE => raise Control.Bug "composeCon: LAYOUT_REF"
                | SOME term => RefAlloc term
              )
      in
        CAST (retTy, term)
      end

  fun makeBranchExp (argTermFn, NONE, branchExp, loc) = branchExp
    | makeBranchExp (argTermFn, SOME argVar, branchExp, loc) =
      Let (bind (argVar, argTermFn (#ty argVar)), branchExp, loc)

  fun switchCon (dataTerm, ruleList, defaultExp, loc) =
      let
        val tyCon = extractDatatypeTyCon (termTy dataTerm)
        val layout = datatypeLayout tyCon
      in
        case layout of
          LAYOUT_TAGGED layout =>
          let
            val (binds, dataTerm) = valueForm dataTerm
            val tagTerm = extractConTag (layout, dataTerm)
            val branches =
                map
                  (fn (conInfo, argVar, exp) =>
                      {constant = ConstTermTag (lookupConTag (layout, conInfo)),
                       exp = makeBranchExp
                               (decomposeTaggedCon (conInfo, dataTerm),
                                argVar, exp, loc)})
                  ruleList
          in
            Let (binds,
                 TL.TLSWITCH {switchExp = unpack (tagTerm, loc),
                              expTy = termTy tagTerm,
                              branches = branches,
                              defaultExp = defaultExp,
                              loc = loc},
                 loc)
          end
        | LAYOUT_BOOL {falseName} =>
          let
            val (conInfo, ifTrueExp, ifFalseExp) =
                case ruleList of
                  [(con1, NONE, exp1), (con2, NONE, exp2)] =>
                  if List.last (#path con1) = falseName
                  then (con1, exp2, exp1)
                  else (con1, exp1, exp2)
                | [(con1, NONE, exp1)] =>
                  if List.last (#path con1) = falseName
                  then (con1, defaultExp, exp1)
                  else (con1, exp1, defaultExp)
                | _ => raise Control.Bug "switchCon: LAYOUT_BOOL"
          in
            If {condExp = unpack (dataTerm, loc),
                thenExp = ifTrueExp,
                elseExp = ifFalseExp,
                loc = loc}
          end
        | LAYOUT_UNIT =>
          (
            case ruleList of
              [(_, _, branchExp)] => branchExp
            | _ => raise Control.Bug "compileExp: RCCASE: LAYOUT_UNIT"
          )
        | LAYOUT_ARGONLY =>
          (
            case ruleList of
              [(conInfo, SOME argVar, branchExp)] =>
              Let (bind (argVar, decomposeArgOnlyCon (conInfo, dataTerm)
                                                     (#ty argVar)),
                   branchExp, loc)
            | _ => raise Control.Bug "compileExp: RCCASE: LAYOUT_ARGONLY"
          )
        | LAYOUT_ARG_OR_NULL =>
          let
            val (conInfo, argVar, ifDataExp, ifNullExp) =
                case ruleList of
                  [(_, NONE, exp1), (con, SOME v, exp2)] =>
                  (con, SOME v, exp2, exp1)
                | [(con, SOME v, exp1), (_, NONE, exp2)] =>
                  (con, SOME v, exp1, exp2)
                | [(con, SOME v, exp1)] =>
                  (con, SOME v, exp1, defaultExp)
                | [(con, NONE, exp1)] =>
                  (con, NONE, defaultExp, exp1)
                | _ => raise Control.Bug "switchArgOrNull"
            val (binds, dataTerm) = valueForm dataTerm
          in
            Let (binds,
                 If {condExp = unpack (IsNull dataTerm, loc),
                     thenExp = ifNullExp,
                     elseExp =
                       makeBranchExp
                         (decomposeArgOnlyCon (conInfo, dataTerm),
                          argVar, ifDataExp, loc),
                     loc = loc},
                 loc)
          end
        | LAYOUT_REF =>
          (
            case ruleList of
              [(_, SOME argVar, branchExp)] =>
              Let (bind (argVar, RefDeref dataTerm), branchExp, loc)
            | _ => raise Control.Bug "compileExp: RCCASE: LAYOUT_ARGONLY"
          )
      end

  type env =
      {
        exnMap: TL.varInfo ExnID.Map.map,
        exExnMap: TL.exVarInfo PathEnv.map
      }

  val emptyEnv =
      {exnMap = ExnID.Map.empty, exExnMap = PathEnv.empty} : env

  fun newLocalExn (env:env, {path, ty, id}:RC.exnInfo) =
      let
        val vid = VarID.generate ()
        val varInfo = {path = path, ty = BE.EXNTAGty, id = vid} : TL.varInfo
      in
        ({exnMap = ExnID.Map.insert (#exnMap env, id, varInfo),
          exExnMap = #exExnMap env} : env,
         varInfo)
      end

  fun addExternExn (env:env, {path, ty}:RC.exExnInfo) =
      let
        val exVarInfo = {path = path, ty = BE.EXNTAGty} : TL.exVarInfo
      in
        ({exnMap = #exnMap env,
          exExnMap = PathEnv.insert (#exExnMap env, path, exVarInfo)} : env,
         exVarInfo)
      end

  fun findLocalExnTag ({exnMap, ...}:env, {id, ...}:RC.exnInfo) =
      ExnID.Map.find (exnMap, id)

  fun findExternExnTag ({exExnMap, ...}:env, {path,...}:RC.exExnInfo) =
      PathEnv.find (exExnMap, path)

  fun findExnTag (env, exnCon) =
      case exnCon of
        RC.EXN e =>
        (case findLocalExnTag (env, e) of
           SOME var => SOME (VAR var)
         | NONE => NONE)
      | RC.EXEXN e =>
        (case findExternExnTag (env, e) of
           SOME var => SOME (EXVAR var)
         | NONE => NONE)

  fun allocExnTag path =
      let
        val name = String.concatWith "." path
        val nameExp = CONST (CT.STRING name, BE.STRINGty)
      in
        CAST (BE.EXNTAGty, RefAlloc nameExp)
      end

  fun extractExnTagName tagTerm =
      RefDeref (CAST (RefTy BE.STRINGty, tagTerm))

  fun composeExn env (exnCon, argExpOpt) =
      let
        val (argTy, _) = decomposeDataconTy (exnConTy exnCon)
        val argTerm =
            case (argTy, argExpOpt) of
              (NONE, NONE) => NONE
            | (SOME argTy, SOME argExp) => SOME (pack (argExp, argTy))
            | _ => raise Control.Bug "composeExn"
        val tagTerm =
            case findExnTag (env, exnCon) of
              SOME tag => tag
            | NONE => raise Control.Bug "composeExn: tag not found"
      in
        case argTerm of
          NONE => CAST (BE.EXNty, TUPLE [tagTerm])
        | SOME term => CAST (BE.EXNty, TUPLE [tagTerm, term])
      end

  fun extractExnTag exnTerm =
      SELECT ("1", CAST (tupleTy [BE.EXNTAGty], exnTerm))

  fun decomposeExn exnTerm expectTy =
      SELECT ("2", CAST (tupleTy [BE.EXNTAGty, expectTy], exnTerm))

  fun switchExn env (exnTerm, ruleList, defaultExp, loc) =
      let
        (* exception match must be performed by linear search. *)
        val (binds, exnTerm) = valueForm exnTerm
        val tagTerm = extractExnTag exnTerm
      in
        Let (binds,
             foldr
               (fn ((exnCon, argVar, branchExp), z) =>
                   let
                     val tag = case findExnTag (env, exnCon) of
                                 SOME tagTerm => tagTerm
                               | NONE => raise Control.Bug "switchExn"
                   in
                     If {condExp = unpack (ExnTagEqual (tagTerm, tag), loc),
                         thenExp = makeBranchExp
                                     (decomposeExn exnTerm,
                                      argVar, branchExp, loc),
                         elseExp = z,
                         loc = loc}
                   end)
               defaultExp
               ruleList,
             loc)
      end

  fun fixConst (const, ty, loc) =
      ConstantTerm.fixConst
        {constTerm = fn c => TL.TLCONSTANT {value=c, loc=loc},
         recordTerm = fn (fields, recordTy) =>
                         TL.TLRECORD {isMutable = false,
                                      fields = fields,
                                      recordTy = recordTy,
                                      loc = loc},
         conTerm = fn {con, instTyList, arg} =>
                      unpack (composeCon (con, instTyList, arg), loc)}
        (const, ty)

  fun compileExp (env:env) rcexp =
      case rcexp of
        RC.RCFOREIGNAPPLY {funExp, foreignFunTy, argExpList, loc} =>
        TL.TLFOREIGNAPPLY
          {funExp = compileExp env funExp,
           foreignFunTy = foreignFunTy,
           argExpList = map (compileExp env) argExpList,
           loc = loc}
      | RC.RCEXPORTCALLBACK {funExp, foreignFunTy, loc} =>
        TL.TLEXPORTCALLBACK
          {funExp = compileExp env funExp,
           foreignFunTy = foreignFunTy,
           loc = loc}
      | RC.RCSIZEOF (ty, loc) =>
        TL.TLSIZEOF {ty=ty, loc=loc}
      | RC.RCTAGOF (ty, loc) =>
        TL.TLTAGOF {ty=ty, loc=loc}
      | RC.RCINDEXOF (label, recordTy, loc) =>
        TL.TLINDEXOF {label=label, recordTy=recordTy, loc=loc}
      | RC.RCCONSTANT {const, loc, ty} =>
        fixConst (const, ty, loc)
      | RC.RCGLOBALSYMBOL {name, kind, ty, loc} =>
        TL.TLGLOBALSYMBOL {name=name, kind=kind, ty=ty, loc=loc}
      | RC.RCVAR (varInfo, loc) =>
        TL.TLVAR {varInfo = varInfo, loc = loc}
      | RC.RCEXVAR (exVarInfo, loc) =>
        TL.TLEXVAR {exVarInfo = exVarInfo, loc = loc}
      | RC.RCPRIMAPPLY {primOp={primitive, ty}, instTyList, argExp, loc} =>
        let
          val argExp = compileExp env argExp
          val (letFn, argExp) = splitLet argExp
          val (argTy, retTy) =
              case TypesUtils.tpappTy (ty, instTyList) of
                T.FUNMty ([argTy], retTy) => (argTy, retTy)
              | _ => raise Control.Bug "RCPRIMAPPLY: not a function"
          val argTerm = pack (argExp, argTy)
          fun explodeArgTy ty =
              case TypesUtils.derefTy ty of
                T.POLYty {boundtvars, body} =>
                T.POLYty {boundtvars=boundtvars, body=explodeArgTy body}
              | T.FUNMty ([argTy], retTy) =>
                (case TypesUtils.derefTy argTy of
                   T.RECORDty fields => T.FUNMty (LabelEnv.listItems fields, retTy)
                 | ty => T.FUNMty ([ty], retTy))
              | _ => raise Control.Bug "RCPRIMAPPLY: explodeArgTy"
          val term =
              case primitive of
                BuiltinPrimitive.Cast => CAST (retTy, argTerm)
              | BuiltinPrimitive.Exn_Name =>
                extractExnTagName (extractExnTag argTerm)
              | _ =>
                let
                  val (binds, argTerms) = explodeRecordExp argTerm
                  val primTy = explodeArgTy ty
                in
                  LET (binds,
                       PRIMAPPLY ({primitive = primitive, ty = primTy},
                                  instTyList, argTerms))
                end
        in
          letFn (unpack (term, loc))
        end
      | RC.RCDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
          val (letFn, argExpOpt) = splitLetOpt argExpOpt
        in
          letFn (unpack (composeCon (con, instTyList, argExpOpt), loc))
        end
      | RC.RCEXNCONSTRUCT {exn, instTyList=nil, argExpOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
          val (letFn, argExpOpt) = splitLetOpt argExpOpt
        in
          letFn (unpack (composeExn env (exn, argExpOpt), loc))
        end
      | RC.RCEXNCONSTRUCT {exn, instTyList=_::_, argExpOpt, loc} =>
        raise Control.Bug "compileExp: RCEXNCONSTRUCT"
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Control.Bug "compileExp: RCEXN_CONSTRUCTOR"
          | SOME var => TL.TLVAR {varInfo = var, loc = loc}
        )
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
        (
          case findExternExnTag (env, exExnInfo) of
            NONE => raise Control.Bug "compileExp: RCEXEXN_CONSTRUCTOR"
          | SOME var => TL.TLEXVAR {exVarInfo = var, loc = loc}
        )
      | RC.RCAPPM {funExp, funTy, argExpList, loc} =>
        let
          val argExpList = map (compileExp env) argExpList
        in
          TL.TLAPPM {funExp = compileExp env funExp,
                     funTy = funTy,
                     argExpList = argExpList,
                     loc = loc}
        end
      | RC.RCMONOLET {binds, bodyExp, loc} =>
        TL.TLLET
          {localDeclList =
             map (fn (v,e) => TL.TLVAL {boundVar = v,
                                        boundExp = compileExp env e,
                                        loc = loc})
                 binds,
           mainExp = compileExp env bodyExp,
           loc = loc}
      | RC.RCLET {decls, body=[rcexp], tys, loc} =>
        let
          val (env, decls) = compileDeclList env decls
          val mainExp = compileExp env rcexp
        in
          TL.TLLET {localDeclList = decls,
                    mainExp = mainExp,
                    loc = loc}
        end
      | RC.RCLET {decls, body, tys, loc} =>
        compileExp env (RC.RCLET {decls = decls,
                                  body = [RC.RCSEQ {expList = body,
                                                    expTyList = tys,
                                                    loc = loc}],
                                  tys = [List.last tys],
                                  loc = loc})
      | RC.RCRECORD {fields, recordTy, loc} =>
        TL.TLRECORD
          {isMutable = false,
           fields = LabelEnv.map (compileExp env) fields,
           recordTy = recordTy,
           loc = loc}
      | RC.RCSELECT {indexExp, label, exp, expTy, resultTy, loc} =>
        TL.TLSELECT
          {recordExp = compileExp env exp,
           indexExp = compileExp env indexExp,
           label = label,
           recordTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | RC.RCMODIFY {indexExp, label, recordExp, recordTy, elementExp,
                     elementTy, loc} =>
        TL.TLMODIFY
          {indexExp = compileExp env indexExp,
           label = label,
           recordExp = compileExp env recordExp,
           recordTy = recordTy,
           valueExp = compileExp env elementExp,
           loc = loc}
      | RC.RCRAISE {exp, ty, loc} =>
        TL.TLRAISE
          {argExp = compileExp env exp,
           resultTy = ty,
           loc = loc}
      | RC.RCHANDLE {exp, exnVar, handler, loc} =>
        TL.TLHANDLE
          {exp = compileExp env exp,
           exnVar = exnVar,
           handler = compileExp env handler,
           loc = loc}
      | RC.RCCASE {exp, expTy, ruleList, defaultExp, loc} =>
        let
          val exp = compileExp env exp
          val ruleList = map (fn (conInfo, argVar, exp) =>
                                 (conInfo, argVar, compileExp env exp))
                             ruleList
          val defaultExp = compileExp env defaultExp
        in
          switchCon (pack (exp, expTy), ruleList, defaultExp, loc)
        end
      | RC.RCEXNCASE {exp, expTy, ruleList, defaultExp, loc} =>
        let
          val exp = compileExp env exp
          val ruleList = map (fn (exnCon, argVar, exp) =>
                                 (exnCon, argVar, compileExp env exp))
                             ruleList
          val defaultExp = compileExp env defaultExp
        in
          switchExn env (pack (exp, expTy), ruleList, defaultExp, loc)
        end
      | RC.RCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val switchExp = compileExp env switchExp
          val branches =
              map (fn (c, e) =>
                      case fixConst (c, expTy, loc) of
                        TL.TLCONSTANT {value, ...} =>
                        {constant = value, exp = compileExp env e}
                      | _ => raise Control.Bug "compileExp: RCSWITCH")
                  branches
          val defaultExp = compileExp env defaultExp
        in
          TL.TLSWITCH
            {switchExp = switchExp,
             expTy = expTy,
             branches = branches,
             defaultExp = defaultExp,
             loc = loc}
        end
      | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        TL.TLFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | RC.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
        TL.TLPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = T.FUNMty (map #ty argVarList, bodyTy),
           exp = TL.TLFNM {argVarList = argVarList,
                           bodyTy = bodyTy,
                           bodyExp = compileExp env bodyExp,
                           loc = loc},
           loc = loc}
      | RC.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        TL.TLPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp env exp,
           loc = loc}
      | RC.RCTAPP {exp, expTy, instTyList, loc} =>
        TL.TLTAPP
          {exp = compileExp env exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | RC.RCSEQ {expList, expTyList, loc} =>
        let
          val exps = ListPair.zipEq (map (compileExp env) expList, expTyList)
        in
          case rev exps of
            nil => raise Control.Bug "compileExp: RCLET"
          | [exp] => #1 exp
          | lastExp::exps =>
            TL.TLLET
              {localDeclList =
                 map (fn (exp, ty) =>
                         TL.TLVAL {boundVar = newVar ty,
                                   boundExp = exp, loc =loc})
                     (rev exps),
               mainExp = #1 lastExp,
               loc = loc}
        end
      | RC.RCCAST (rcexp, ty, loc) =>
        TL.TLCAST {exp = compileExp env rcexp, targetTy = ty, loc = loc}
      | RC.RCOPRIMAPPLY _ =>
        raise Control.Bug "compileExp: RCOPRIMAPPLY"
      | RC.RCSQL exp =>
        raise Control.Bug "RCSQL"
      | RC.RCFFI exp =>
        raise Control.Bug "RCFFI"

  and compileDecl env rcdecl =
      case rcdecl of
        RC.RCVAL (bindList, loc) =>
        (env,
         map (fn (v, e) =>
                 TL.TLVAL {boundVar = v,
                           boundExp = compileExp env e,
                           loc = loc})
             bindList)
      | RC.RCVALREC (bindList, loc) =>
        (env,
         [TL.TLVALREC
            {recbindList = map (fn {var, expTy, exp} =>
                                   {boundVar = var,
                                    boundExp = compileExp env exp})
                               bindList,
             loc = loc}])
      | RC.RCVALPOLYREC (btvEnv, bindList, loc) =>
        raise Control.Bug "compileExp: RCVALPOLYREC"
      | RC.RCEXPORTVAR (varInfo, loc) =>
        (env, [TL.TLEXPORTVAR (varInfo, loc)])
      | RC.RCEXTERNVAR (exVarInfo, loc) =>
        (env, [TL.TLEXTERNVAR (exVarInfo, loc)])
      | RC.RCEXD (exnBinds, loc) =>
        let
          fun compileExBind env nil = (env, nil)
            | compileExBind env ({exnInfo, loc}::binds) =
              let
                val (env, tagVar) = newLocalExn (env, exnInfo)
                val (env, decls) = compileExBind env binds
              in
                (env,
                 TL.TLVAL {boundVar = tagVar,
                           boundExp = unpack (allocExnTag (#path exnInfo), loc),
                           loc = loc}
                 :: decls)
              end
        in
          compileExBind env exnBinds
        end
      | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val (env, tagVar) = newLocalExn (env, exnInfo)
        in
          (env,
           [TL.TLVAL {boundVar = tagVar,
                      boundExp = TL.TLVAR {varInfo = varInfo, loc = loc},
                      loc = loc}])
        end
      | RC.RCEXPORTEXN (exnInfo as {path, ...}, loc) =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Control.Bug "compileDecl: RCEXPORTEXN"
          | SOME (var as {id, ty,...}) => 
            (* ohori: bug 184. the external name is "path" in exnInfo, 
               which must be kept. *)
            (env, [TL.TLEXPORTVAR ({path=path, id=id, ty=ty}, loc)])
        )
      | RC.RCEXTERNEXN (exExnInfo, loc) =>
        let
          val (env, tagVar) = addExternExn (env, exExnInfo)
        in
          (env, [TL.TLEXTERNVAR (tagVar, loc)])
        end

  and compileDeclList env nil = (env, nil)
    | compileDeclList env (decl::decls) =
      let
        val (env, decls1) = compileDecl env decl
        val (env, decls2) = compileDeclList env decls
      in
        (env, decls1 @ decls2)
      end

  fun compile decls =
      let
        val (env, decls) = compileDeclList emptyEnv decls
      in
        decls
      end

end
