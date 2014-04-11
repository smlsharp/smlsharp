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
  structure TC = TypedCalc
  structure TL = TypedLambda
  structure CT = ConstantTerm
  structure BT = BuiltinTypes
  structure BP = BuiltinPrimitive
  structure T = Types

  structure E = EmitTypedLambda

  val errors = UserError.createQueue ()

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

  fun ConTag const =
      CT.CONTAG (Word32.fromInt const)

  fun exnConTy exnCon =
      case exnCon of
        RC.EXN {ty,...} => ty
      | RC.EXEXN {ty,...} => ty

  fun extractTyCon ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, args} => tyCon
      | _ => raise Bug.Bug "extractTyCon"

  fun unwrapLet (TL.TLLET {localDecl, mainExp, loc}) =
      let
        val (decls, mainExp) = unwrapLet mainExp
      in
        (E.Decl (localDecl, loc) :: decls, mainExp)
      end
    | unwrapLet mainExp = (nil, mainExp)

  fun explodeRecordExp exp =
      let
        val expTy =
            case exp of
              E.Exp (_, ty) => ty
            | E.Cast (_, ty) => ty
            | _ => raise Bug.Bug "explodeRecordExp"
        val fieldTys =
            case TypesBasics.derefTy expTy of
              T.RECORDty fieldTys => fieldTys
            | _ => raise Bug.Bug "explodeRecordExp: not a record"
      in
        case exp of
          E.Exp (TL.TLRECORD {isMutable = false, fields, recordTy, ...}, _) =>
          (nil,
           map (fn (label, exp) =>
                   E.Exp (exp, case LabelEnv.find (fieldTys, label) of
                                 SOME ty => ty
                               | NONE => raise Bug.Bug "explodeRecordExp"))
               (LabelEnv.listItemsi fields))
        | _ =>
          let
            val vid = EmitTypedLambda.newId ()
          in
            ([(vid, exp)],
             map (fn (label, ty) => E.Select (label, E.Var vid))
                 (LabelEnv.listItemsi fieldTys))
          end
      end

  fun explodeRecordTy recordTy =
      case TypesBasics.derefTy recordTy of
        T.RECORDty fields => ListPair.unzip (LabelEnv.listItemsi fields)
      | ty => raise Bug.Bug "explodeRecordTy"

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
   *   datatype foo = Foo                  --> contagty
   *                | Bar                  --> contagty
   *                | Baz                  --> contagty
   *
   * LAYOUT_BOOL:
   * If there are just two variant and both of them have no argument,
   * these variants can be implemented like "bool";
   * one variant is 0, and another is any integer other than 0.
   *   datatype bool = false               --> contagty (0)
   *                 | true                --> contagty (other than 0)
   *
   * (FIXME: if true is implemented as "other than 0", it may collapse
   *         dynamic bit-by-bit equality check. Currently we allow only
   *         "1" as the tag of "true".)
   *
   * LAYOUT_UNIT:
   * If there is just one variant with no argument, this can be implemented
   * like "unit"; it can be implemented with an arbitrary integer.
   *   datatype foo = Foo                  --> contagty (any integer is OK)
   *
   * (FIXME: if any tag integer is accepted, it may collapse dynamic
   *         bit-by-bit equality check. Currently we allow only "0" as
   *         the tag of this layout.)
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
    | TAGGED_OR_NULL of {tagMap: int SEnv.map, nullName: string}

  datatype layout =
      LAYOUT_TAGGED of taggedLayout
    | LAYOUT_BOOL of {falseName: string}
    | LAYOUT_UNIT
    | LAYOUT_ARGONLY
    | LAYOUT_ARG_OR_NULL
    | LAYOUT_REF

  fun checkRepresentation (ty, layout) =
      case layout of
        LAYOUT_TAGGED (TAGGED_RECORD _) => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_TAGGED (TAGGED_TAGONLY _) => ty = BuiltinTypeNames.CONTAGty
      | LAYOUT_TAGGED (TAGGED_OR_NULL _) => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_BOOL _ => ty = BuiltinTypeNames.CONTAGty
      | LAYOUT_UNIT => ty = BuiltinTypeNames.CONTAGty
      | LAYOUT_ARGONLY => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_ARG_OR_NULL => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_REF => ty = BuiltinTypeNames.REFty

  fun categolizeConSet conSet =
      SEnv.foldri
        (fn (name, {hasArg=true}, {hasArg, noArg}) =>
            {hasArg = name::hasArg, noArg = noArg}
          | (name, {hasArg=false}, {hasArg, noArg}) =>
            {hasArg = hasArg, noArg = name::noArg})
        {hasArg = nil, noArg = nil}
        conSet

  fun decomposeDataconTy ty =
      case TypesBasics.derefTy ty of
        T.FUNMty ([argTy], retTy) => (SOME argTy, retTy)
      | T.CONSTRUCTty _ => (NONE, ty)
      | _ => raise Bug.Bug "decomposeDataconTy"

  fun dataconArgTy ({ty, ...}:RecordCalc.conInfo) =
      case TypesBasics.derefTy ty of
        T.POLYty {boundtvars, body} =>
        (case TypesBasics.derefTy body of
           T.FUNMty ([argTy], retTy) => argTy
         | _ => raise Bug.Bug "dataconArgTy")
      | T.FUNMty ([argTy], retTy) => argTy
      | _ => raise Bug.Bug "dataconArgTy"

  fun makeTagMap conSet =
      #2 (SEnv.foldli (fn (key, _, (i, map)) =>
                          (i + 1, SEnv.insert (map, key, i)))
                      (1, SEnv.empty)
                      conSet)

  fun datatypeLayout (tyCon as {id, conSet, runtimeTy, ...}:T.tyCon) =
      let
        val layout =
            case map #hasArg (SEnv.listItems conSet) of
              nil => raise Bug.Bug "datatypeLayout: no variant"
            | [true] =>
              if TypID.eq (#id BT.refTyCon, id)
              then LAYOUT_REF
              else LAYOUT_ARGONLY
            | [false] => LAYOUT_UNIT
            | [false, false] =>
              (
                if TypID.eq (id, #id BT.boolTyCon)
                then LAYOUT_BOOL {falseName = "false"}
                else case SEnv.firsti conSet of
                       SOME (name, _) => LAYOUT_BOOL {falseName = name}
                     | NONE => raise Bug.Bug "datatypeLayout: BOOL"
              )
            | _ =>
              case categolizeConSet conSet of
                {hasArg=nil, noArg=_} =>
                LAYOUT_TAGGED (TAGGED_TAGONLY {tagMap = makeTagMap conSet})
              | {hasArg=[_], noArg=[_]} =>
                LAYOUT_ARG_OR_NULL
              | {hasArg=_, noArg=[nullName]} =>
                LAYOUT_TAGGED (TAGGED_OR_NULL {tagMap = makeTagMap conSet,
                                               nullName = nullName})
              | {hasArg=_, noArg=_} =>
                LAYOUT_TAGGED (TAGGED_RECORD {tagMap = makeTagMap conSet})
      in
        if checkRepresentation (runtimeTy, layout)
        then layout
        else raise Bug.Bug "datatypeLayout"
      end

  fun lookupConTag (taggedLayout, path) =
      let
        val tagMap =
            case taggedLayout of
              TAGGED_TAGONLY {tagMap} => tagMap
            | TAGGED_RECORD {tagMap} => tagMap
            | TAGGED_OR_NULL {tagMap, nullName} => tagMap
      in
        case SEnv.find (tagMap, List.last path) of
          NONE => raise Bug.Bug ("dataconTag " ^ String.concatWith "." path)
        | SOME tag => tag : int
      end

  fun extractConTag (taggedLayout, exp) =
      case taggedLayout of
        TAGGED_TAGONLY _ => E.Cast (exp, BT.contagTy)
      | TAGGED_RECORD _ => E.Select ("1", E.Cast (exp, E.tupleTy [BT.contagTy]))
      | TAGGED_OR_NULL {tagMap, nullName} =>
        let
          val vid = EmitTypedLambda.newId ()
        in
          E.Let ([(vid, exp)],
                 E.If (E.IsNull (E.Cast (exp, BT.boxedTy)),
                       E.ConTag (lookupConTag (taggedLayout, [nullName])),
                       E.Select ("1", E.Cast (exp, E.tupleTy [BT.contagTy]))))
        end

  fun composeTaggedCon (taggedLayout, conInfo, argExpOpt, retTy) =
      let
        val tagExp = E.ConTag (lookupConTag (taggedLayout, #path conInfo))
      in
        case argExpOpt of
          NONE => E.Cast (E.Tuple [tagExp], retTy)
        | SOME argExp =>
          let
            val (binds, exps) =
                case TypesBasics.derefTy (dataconArgTy conInfo) of
                  T.RECORDty _ => explodeRecordExp argExp
                | _ => (nil, [argExp])
          in
            E.Let (binds, E.Cast (E.Tuple (tagExp :: exps), retTy))
          end
      end

  fun extractTaggedConArg (conInfo:RecordCalc.conInfo, dataExp) argTy =
      let
        val (labels, fieldTys) =
            case TypesBasics.derefTy (dataconArgTy conInfo) of
              T.RECORDty _ => explodeRecordTy argTy
            | _ => (nil, [argTy])
        val dataExp = E.Cast (dataExp, E.tupleTy (BT.contagTy :: fieldTys))
        val (binds, exps) = explodeRecordExp dataExp
      in
        case (labels, exps) of
          (nil, [_, exp]) => E.Let (binds, exp)
        | (nil, _) => raise Bug.Bug "extractTaggedConArg"
        | (_::_, _::t) => E.Let (binds, E.Record (labels, t))
        | (_::_, nil) => raise Bug.Bug "extractTaggedConArg"
      end

  fun needPack conInfo =
      case TypesBasics.derefTy (dataconArgTy conInfo) of
        T.RECORDty _ => false
      | T.FUNMty _ => false
      | T.CONSTRUCTty {tyCon, ...} =>
        (case BuiltinTypeNames.runtimeTy (#runtimeTy tyCon) of
           RuntimeTypes.BOXEDty => false
         | _ => true)
      | _ => true

  fun composeArgOnlyCon (conInfo, argExp, retTy) =
      if needPack conInfo
      then E.Cast (E.Tuple [argExp], retTy)
      else E.Cast (argExp, retTy)

  fun extractArgOnlyConArg (conInfo, dataExp) argTy =
      if needPack conInfo
      then E.Select ("1", E.Cast (dataExp, E.tupleTy [argTy]))
      else E.Cast (dataExp, argTy)

  fun composeCon (conInfo:RC.conInfo, instTyList, argExpOpt) =
      let
        val conInstTy = TypesBasics.tpappTy (#ty conInfo, instTyList)
        val (argTy, retTy) = decomposeDataconTy conInstTy
        val argExpOpt =
            case (argExpOpt, argTy) of
              (NONE, NONE) => NONE
            | (SOME argExp, SOME argTy) => SOME (E.Exp (argExp, argTy))
            | _ => raise Bug.Bug "composeCon"
        val layout = datatypeLayout (extractTyCon retTy)
      in
        case layout of
          LAYOUT_TAGGED (layout as TAGGED_RECORD _) =>
          composeTaggedCon (layout, conInfo, argExpOpt, retTy)
        | LAYOUT_TAGGED (layout as TAGGED_TAGONLY _) =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: TAGGED_TAGONLY"
            | NONE =>
              E.Cast (E.ConTag (lookupConTag (layout, #path conInfo)), retTy)
          )
        | LAYOUT_TAGGED (layout as TAGGED_OR_NULL _) =>
          (
            case argExpOpt of
              NONE => E.Cast (E.Null, retTy)
            | SOME _ => composeTaggedCon (layout, conInfo, argExpOpt, retTy)
          )
        | LAYOUT_BOOL {falseName} =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: LAYOUT_BOOL"
            | NONE =>
              E.Cast (if List.last (#path conInfo) = falseName
                      then E.ConTag 0 else E.ConTag 1,
                      retTy)
          )
        | LAYOUT_UNIT =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: LAYOUT_UNIT"
            | NONE => E.Cast (E.ConTag 0, retTy)
          )
        | LAYOUT_ARGONLY =>
          (
            case argExpOpt of
              SOME exp => composeArgOnlyCon (conInfo, exp, retTy)
            | _ => raise Bug.Bug "composeCon: LAYOUT_ARGONLY"
          )
        | LAYOUT_ARG_OR_NULL =>
          (
            case argExpOpt of
              NONE => E.Cast (E.Null, retTy)
            | SOME exp => composeArgOnlyCon (conInfo, exp, retTy)
          )
        | LAYOUT_REF =>
          (
            case (argExpOpt, argTy) of
              (SOME argExp, SOME argTy) => E.Ref_alloc (argTy, argExp)
            | _ => raise Bug.Bug "composeCon: LAYOUT_REF"
          )
      end

  fun makeBranch argFn (NONE, branchExp, resultTy) =
      E.Exp (branchExp, resultTy)
    | makeBranch argFn (SOME argVar, branchExp, resultTy) =
      E.TLLet ([E.Bind (argVar, argFn (#ty argVar))],
               E.Exp (branchExp, resultTy))

  fun switchCon (dataExp, dataTy, ruleList, defaultExp, resultTy) =
      let
        val tyCon = extractTyCon dataTy
        val layout = datatypeLayout tyCon
      in
        case layout of
          LAYOUT_TAGGED layout =>
          let
            val dataVid = EmitTypedLambda.newId ()
            val dataVarExp = E.Var dataVid
          in
            E.Let ([(dataVid, E.Exp (dataExp, dataTy))],
                   E.Switch
                     (extractConTag (layout, dataVarExp),
                      map
                        (fn (conInfo as {path, ...}, argVarOpt, exp) =>
                            (ConTag (lookupConTag (layout, path)),
                             makeBranch
                               (extractTaggedConArg (conInfo, dataVarExp))
                               (argVarOpt, exp, resultTy)))
                        ruleList,
                      E.Exp (defaultExp, resultTy)))
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
                | _ => raise Bug.Bug "switchCon: LAYOUT_BOOL"
          in
            E.If (E.Exp (dataExp, dataTy),
                  E.Exp (ifTrueExp, resultTy),
                  E.Exp (ifFalseExp, resultTy))
          end
        | LAYOUT_UNIT =>
          (
            case ruleList of
              [(_, _, branchExp)] => E.Exp (branchExp, resultTy)
            | _ => raise Bug.Bug "compileExp: RCCASE: LAYOUT_UNIT"
          )
        | LAYOUT_ARGONLY =>
          (
            case ruleList of
              [(conInfo, argVar as SOME _, branchExp)] =>
              makeBranch
                (extractArgOnlyConArg (conInfo, E.Exp (dataExp, dataTy)))
                (argVar, branchExp, resultTy)
            | _ => raise Bug.Bug "compileExp: RCCASE: LAYOUT_ARGONLY"
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
                | _ => raise Bug.Bug "switchArgOrNull"
            val dataVid = EmitTypedLambda.newId ()
          in
            E.Let ([(dataVid, E.Exp (dataExp, dataTy))],
                   E.If (E.IsNull (E.Cast (E.Var dataVid, BT.boxedTy)),
                         E.Exp (ifNullExp, resultTy),
                         makeBranch
                           (extractArgOnlyConArg (conInfo, E.Var dataVid))
                           (argVar, ifDataExp, resultTy)))
          end
        | LAYOUT_REF =>
          (
            case ruleList of
              [(_, SOME argVar, branchExp)] =>
              E.TLLet
                ([E.Bind (argVar,
                          E.Ref_deref (#ty argVar, E.Exp (dataExp, dataTy)))],
                 E.Exp (branchExp, resultTy))
            | _ => raise Bug.Bug "compileExp: RCCASE: LAYOUT_ARGONLY"
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
        val varInfo = {path = path, ty = BT.exntagTy, id = vid} : TL.varInfo
      in
        ({exnMap = ExnID.Map.insert (#exnMap env, id, varInfo),
          exExnMap = #exExnMap env} : env,
         varInfo)
      end

  fun addExternExn (env:env, {path, ty}:RC.exExnInfo) =
      let
        val exVarInfo = {path = path, ty = BT.exntagTy} : TL.exVarInfo
      in
        ({exnMap = #exnMap env,
          exExnMap = PathEnv.insert (#exExnMap env, path, exVarInfo)} : env,
         exVarInfo)
      end

  fun findLocalExnTag ({exnMap, ...}:env, {id, ...}:RC.exnInfo) =
      ExnID.Map.find (exnMap, id)

  fun findExternExnTag ({exExnMap, ...}:env, {path,...}:RC.exExnInfo) =
      PathEnv.find (exExnMap, path)

  val puts = _import "puts" : string -> int
  fun findExnTag (env, exnCon) =
      case exnCon of
        RC.EXN e =>
        (case findLocalExnTag (env, e) of
           SOME v => SOME (E.TLVar v)
         | NONE => 
           (puts "findExnTag fail\n";
            puts (String.concatWith "." (#path e));
           NONE
           )
        )
      | RC.EXEXN e =>
        (case findExternExnTag (env, e) of
           SOME v => SOME (E.ExVar v)
         | NONE => 
           (puts "findExnTag fail\n";
            puts (String.concatWith "." (#path e));
            NONE
           )
        )

  fun composeExn env (exnCon, argExpOpt, loc) =
      let
        val (argTy, _) = decomposeDataconTy (exnConTy exnCon)
        val argOpt =
            case (argExpOpt, argTy) of
              (NONE, NONE) => NONE
            | (SOME argExp, SOME argTy) => SOME (E.Exp (argExp, argTy))
            | _ => raise Bug.Bug "composeExn"
        val tagExp =
            case findExnTag (env, exnCon) of
              SOME tagExp => tagExp
            | NONE => raise Bug.Bug "composeExn: tag not found"
      in
        EmitTypedLambda.composeExn (tagExp, loc, argOpt)
      end

  fun switchExn env (exnExp, expTy, ruleList, defaultExp, resultTy) =
      let
        (* exception match must be performed by linear search. *)
        val exnVid = EmitTypedLambda.newId ()
        val tagVid = EmitTypedLambda.newId ()
      in
        E.Let
          ([(exnVid, E.Exp (exnExp, expTy)),
            (tagVid, EmitTypedLambda.extractExnTag (E.Var exnVid))],
           foldr
             (fn ((exnCon, argVarOpt, branchExp), elseExp) =>
                 let
                   val tagExp = case findExnTag (env, exnCon) of
                                  SOME tagExp => tagExp
                                | NONE => raise Bug.Bug "switchExn"
                 in
                   E.If (E.IdentityEqual (BT.exntagTy, E.Var tagVid, tagExp),
                         case argVarOpt of
                           NONE => E.Exp (branchExp, resultTy)
                         | SOME argVar =>
                           E.TLLet
                             ([E.Bind
                                 (argVar,
                                  E.extractExnArg (E.Var exnVid, #ty argVar))],
                              E.Exp (branchExp, resultTy)),
                         elseExp)
                 end)
             (E.Exp (defaultExp, resultTy))
             ruleList)
      end

  fun fixConst (const, ty, loc) =
      ConstantTerm.fixConst
        {constTerm = fn c =>
                        TL.TLCONSTANT {const = c,
                                       ty = ConstantTerm.typeOf c,
                                       loc = loc},
         recordTerm = fn (fields, recordTy) =>
                         TL.TLRECORD {isMutable = false,
                                      fields = fields,
                                      recordTy = recordTy,
                                      loc = loc},
         conTerm =
           fn {con, instTyList, arg} =>
              EmitTypedLambda.emit loc (composeCon (con, instTyList, arg))}
        (const, ty)
      handle e as ConstantTerm.TooLargeConstant =>
             (UserError.enqueueError errors (loc, e);
              TL.TLCONSTANT {const=ConstantTerm.UNIT, ty=ty, loc=loc}) (*dummy*)

  fun compileExp (env:env) rcexp =
      case rcexp of
        RC.RCFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        TL.TLFOREIGNAPPLY
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | RC.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp, loc} =>
        TL.TLCALLBACKFN
          {attributes = attributes,
           resultTy = resultTy,
           argVarList = argVarList,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | RC.RCSIZEOF (ty, loc) =>
        TL.TLSIZEOF {ty=ty, loc=loc}
      | RC.RCTAGOF (ty, loc) =>
        TL.TLTAGOF {ty=ty, loc=loc}
      | RC.RCINDEXOF (label, recordTy, loc) =>
        TL.TLINDEXOF {label=label, recordTy=recordTy, loc=loc}
      | RC.RCCONSTANT {const, loc, ty} =>
        fixConst (const, ty, loc)
      | RC.RCFOREIGNSYMBOL {name, ty, loc} =>
        TL.TLFOREIGNSYMBOL {name=name, ty=ty, loc=loc}
      | RC.RCVAR varInfo =>
        TL.TLVAR {varInfo = varInfo, loc = Loc.noloc}
      | RC.RCEXVAR exVarInfo =>
        TL.TLEXVAR {exVarInfo = exVarInfo, loc = Loc.noloc}
      | RC.RCPRIMAPPLY {primOp={primitive, ty}, instTyList, argExp, loc} =>
        let
          val argExp = compileExp env argExp
          val (argTy, retTy) =
              case TypesBasics.tpappTy (ty, instTyList) of
                T.FUNMty ([argTy], retTy) => (argTy, retTy)
              | _ => raise Bug.Bug "RCPRIMAPPLY: not a function"
          val (decls, argExp) = unwrapLet argExp
          val argExp = E.Exp (argExp, argTy)
          val primTy = PrimitiveTypedLambda.toPrimTy ty
          val (binds, argExps) =
              case #argTyList primTy of
                nil => (nil, nil)
              | _::nil => (nil, [argExp])
              | _::_::_ => explodeRecordExp argExp
          val exp =
              E.Let (binds,
                     PrimitiveTypedLambda.compile
                       {primitive = primitive,
                        primTy = primTy,
                        instTyList = instTyList,
                        resultTy = retTy,
                        argExpList = argExps,
                        loc = loc})
        in
          EmitTypedLambda.emit loc (E.TLLet (decls, exp))
        end
      | RC.RCDATACONSTRUCT {con, instTyList, argExpOpt, argTyOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
        in
          EmitTypedLambda.emit loc (composeCon (con, instTyList, argExpOpt))
        end
      | RC.RCEXNCONSTRUCT {exn, instTyList=nil, argExpOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
        in
          EmitTypedLambda.emit loc (composeExn env (exn, argExpOpt, loc))
        end
      | RC.RCEXNCONSTRUCT {exn, instTyList=_::_, argExpOpt, loc} =>
        raise Bug.Bug "compileExp: RCEXNCONSTRUCT"
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Bug.Bug "compileExp: RCEXN_CONSTRUCTOR"
          | SOME var => TL.TLVAR {varInfo = var, loc = loc}
        )
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
        (
          case findExternExnTag (env, exExnInfo) of
            NONE => raise Bug.Bug "compileExp: RCEXEXN_CONSTRUCTOR"
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
        foldr
          (fn ((var, exp), mainExp) =>
              TL.TLLET
                {localDecl = TL.TLVAL {boundVar = var,
                                       boundExp = compileExp env exp,
                                       loc = loc},
                 mainExp = mainExp,
                 loc = loc})
          (compileExp env bodyExp)
          binds
      | RC.RCLET {decls, body=[rcexp], tys, loc} =>
        let
          val (env, decls) = compileDeclList env decls
          val mainExp = compileExp env rcexp
        in
          foldr
            (fn (dec, mainExp) =>
                TL.TLLET {localDecl = dec, mainExp = mainExp, loc = loc})
            mainExp
            decls
        end
      | RC.RCLET {decls, body, tys, loc} =>
        compileExp env (RC.RCLET {decls = decls,
                                  body = [RC.RCSEQ {expList = body,
                                                    expTyList = tys,
                                                    loc = loc}],
                                  tys = [List.last tys],
                                  loc = loc})
      | RC.RCRECORD {fields, recordTy, loc} =>
        if LabelEnv.isEmpty fields
        then EmitTypedLambda.emit loc (E.Cast (E.Null, recordTy))
        else TL.TLRECORD
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
           valueTy = elementTy,
           loc = loc}
      | RC.RCRAISE {exp, ty, loc} =>
        TL.TLRAISE
          {argExp = compileExp env exp,
           resultTy = ty,
           loc = loc}
      | RC.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        TL.TLHANDLE
          {exp = compileExp env exp,
           exnVar = exnVar,
           handler = compileExp env handler,
           resultTy = resultTy,
           loc = loc}
      | RC.RCCASE {exp, expTy, ruleList, defaultExp, resultTy, loc} =>
        let
          val exp = compileExp env exp
          val ruleList = map (fn (conInfo, argVar, exp) =>
                                 (conInfo, argVar, compileExp env exp))
                             ruleList
          val defaultExp = compileExp env defaultExp
        in
          EmitTypedLambda.emit
            loc
            (switchCon (exp, expTy, ruleList, defaultExp, resultTy))
        end
      | RC.RCEXNCASE {exp, expTy, ruleList, defaultExp, resultTy, loc} =>
        let
          val exp = compileExp env exp
          val ruleList = map (fn (exnCon, argVar, exp) =>
                                 (exnCon, argVar, compileExp env exp))
                             ruleList
          val defaultExp = compileExp env defaultExp
        in
          EmitTypedLambda.emit
            loc
            (switchExn env (exp, expTy, ruleList, defaultExp, resultTy))
        end
      | RC.RCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val switchExp = compileExp env switchExp
          val branches =
              map (fn (c, e) =>
                      case fixConst (c, expTy, loc) of
                        TL.TLCONSTANT {const, ...} =>
                        {constant = const, exp = compileExp env e}
                      | _ => raise Bug.Bug "compileExp: RCSWITCH")
                  branches
          val defaultExp = compileExp env defaultExp
        in
          case branches of
            {constant = CT.LARGEINT _, exp = _}::_ =>
            SwitchCompile.compileIntInfSwitch
              {switchExp = switchExp,
               expTy = expTy,
               branches = branches,
               defaultExp = defaultExp,
               resultTy = resultTy,
               loc = loc}
          | {constant = CT.STRING _, exp = _}::_ =>
            SwitchCompile.compileStringSwitch
              {switchExp = switchExp,
               expTy = expTy,
               branches = branches,
               defaultExp = defaultExp,
               resultTy = resultTy,
               loc = loc}
          | _ =>
            TL.TLSWITCH
              {switchExp = switchExp,
               expTy = expTy,
               branches = branches,
               defaultExp = defaultExp,
               resultTy = resultTy,
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
            nil => raise Bug.Bug "compileExp: RCLET"
          | [exp] => #1 exp
          | lastExp::exps =>
            foldl
              (fn ((exp, ty), mainExp) =>
                   TL.TLLET {localDecl = TL.TLVAL {boundVar = newVar ty,
                                                   boundExp = exp,
                                                   loc = loc},
                             mainExp = mainExp,
                             loc = loc})
              (#1 lastExp)
              exps
        end
      | RC.RCCAST ((rcexp, expTy), ty, loc) =>
        TL.TLCAST {exp = compileExp env rcexp, expTy = expTy, targetTy = ty,
                   runtimeTyCast = false, bitCast = false,
                   loc = loc}
      | RC.RCOPRIMAPPLY _ =>
        raise Bug.Bug "compileExp: RCOPRIMAPPLY"
      | RC.RCFFI exp =>
        raise Bug.Bug "RCFFI"

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
        raise Bug.Bug "compileExp: RCVALPOLYREC"
      | RC.RCEXPORTVAR {path, id, ty} =>
        (env, [TL.TLEXPORTVAR ({path=path, ty=ty},
                               TL.TLVAR {varInfo = {path=path, ty=ty, id=id}, loc = Loc.noloc},
                               Loc.noloc)])
      | RC.RCEXTERNVAR exVarInfo =>
        (env, [TL.TLEXTERNVAR (exVarInfo, Loc.noloc)])
      | RC.RCEXD (exnBinds, loc) =>
        let
          fun compileExBind env nil = (env, nil)
            | compileExBind env ({exnInfo, loc}::binds) =
              let
                val (env, tagVar) = newLocalExn (env, exnInfo)
                val (env, decls) = compileExBind env binds
                val tagExp = EmitTypedLambda.allocExnTag exnInfo
              in
                (env,
                 TL.TLVAL
                   {boundVar = tagVar,
                    boundExp = EmitTypedLambda.emit loc tagExp,
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
      | RC.RCEXPORTEXN (exnInfo as {path, ...}) =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Bug.Bug "compileDecl: RCEXPORTEXN"
          | SOME (var as {id, ty,...}) =>
            (* ohori: bug 184. the external name is "path" in exnInfo,
               which must be kept. *)
            (env, [TL.TLEXPORTVAR ({path=path, ty=ty},
                                   TL.TLVAR {varInfo = var, loc = Loc.noloc},
                                   Loc.noloc)])
        )
      | RC.RCEXTERNEXN exExnInfo =>
        let
          val (env, tagVar) = addExternExn (env, exExnInfo)
        in
          (env, [TL.TLEXTERNVAR (tagVar, Loc.noloc)])
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
        val _ = UserError.clearQueue errors
        val (env, decls) = compileDeclList emptyEnv decls
      in
        case UserError.getErrors errors of
          [] => decls
        | errors => raise UserError.UserErrors errors
      end

end
