(**
 * SQL compilation.
 *
 * @copyright (c) 2010, Tohoku University.
 * @author Hiroki Endo
 * @author UENO Katsuhiro
 *)
structure SQLCompilation : sig

  val compile : RecordCalc.rcdecl list -> RecordCalc.rcdecl list

end =
struct

  structure R = RecordCalc
  structure T = Types
  structure A = Absyn
  structure BE = BuiltinEnv

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
        {id = id, path = ["$" ^ VarID.toString id], ty = ty} : R.varInfo
      end

  fun StringConst (const, loc) =
      (R.RCCONSTANT {const = A.STRING (const, loc), ty = BE.STRINGty,
                     loc = loc},
       BE.STRINGty)
  fun IntConst (const, loc) =
      (R.RCCONSTANT {const = A.INT ({radix=StringCvt.DEC,
                                     digits=Int.toString const}, loc),
                     ty = BE.INTty, loc = loc},
       BE.INTty)
  fun WordConst (const, loc) =
      (R.RCCONSTANT {const = A.WORD ({radix=StringCvt.DEC,
                                      digits=Word.toString const}, loc),
                     ty = BE.WORDty, loc = loc},
       BE.WORDty)
  fun CharConst (const, loc) =
      (R.RCCONSTANT {const = A.CHAR (const, loc), ty = BE.CHARty, loc = loc},
       BE.CHARty)
  fun RealConst (const, loc) =
      (R.RCCONSTANT {const = A.REAL (const, loc), ty = BE.REALty, loc = loc},
       BE.REALty)
  fun UnitConst loc =
      (R.RCCONSTANT {const = A.UNITCONST loc, ty = BE.UNITty, loc = loc},
       BE.UNITty)

  fun Var (varInfo as {path, id, ty}:R.varInfo, loc) =
      (R.RCVAR (varInfo, loc), ty)

  fun Seq (exps, loc) =
      let
        val (exps, tys) = ListPair.unzip exps
        val resultTy = List.last tys
                       handle Empty => raise Control.Bug "Seq"
      in
        (R.RCSEQ {expList = exps, expTyList = tys, loc = loc}, resultTy)
      end

  fun MonoLet ((bindExp, bindTy), loc) =
      let
        val var = newVar bindTy
        val bind = (var, bindExp)
      in
        (fn (bodyExp, bodyTy:T.ty) =>
            (case bodyExp of
               R.RCMONOLET {binds, bodyExp, loc=loc2} =>
               R.RCMONOLET {binds=bind::binds, bodyExp=bodyExp,
                            loc = Loc.mergeLocs (loc, loc2)}
             | _ =>
               R.RCMONOLET {binds=[bind], bodyExp=bodyExp, loc=loc},
             bodyTy),
         var)
      end

  fun Record (nil, loc) = UnitConst loc
    | Record (fields, loc) =
      let
        fun fromList list = 
            List.foldl (fn ((key, item), m) => LabelEnv.insert (m, key, item)) LabelEnv.empty list
        val fieldExps = fromList (map (fn (l,(e,t)) => (l,e)) fields)
        val fieldTys = fromList (map (fn (l,(e,t)) => (l,t)) fields)
        val ty = T.RECORDty fieldTys
      in
        (R.RCRECORD {fields = fieldExps, recordTy = ty, loc = loc}, ty)
      end

  fun RecordTy nil = BE.UNITty
    | RecordTy fields =
      let
        fun fromList list = 
            List.foldl (fn ((key, item), m) => LabelEnv.insert (m, key, item)) LabelEnv.empty list
      in
        T.RECORDty (fromList fields)
      end

  fun Tuple (exps, loc) =
      case exps of
        nil => UnitConst loc
      | [x] => x
      | _::_::_ => Record (mapi (fn (i,x) => (Int.toString i, x)) exps, loc)

  fun List (exps, elemTy, loc) =
      let
        val (exps, tys) = ListPair.unzip exps
        val listTyCon = BE.lookupTyCon BuiltinName.listTyName
        val listTy = T.CONSTRUCTty {tyCon = listTyCon, args = [elemTy]}
        val consConInfo = BE.lookupCon BuiltinName.consConName
        val nilConInfo = BE.lookupCon BuiltinName.nilConName
      in
        foldr
          (fn (exp, z) =>
              (R.RCDATACONSTRUCT
                 {con = consConInfo,
                  instTyList = [elemTy],
                  argExpOpt = SOME (#1 (Tuple ([(exp, elemTy), z], loc))),
                  loc = loc},
                 listTy))
          (R.RCDATACONSTRUCT
             {con = nilConInfo,
              instTyList = [elemTy],
              argExpOpt = NONE,
              loc = loc},
             listTy)
          exps
      end

  fun ListTy elemTy =
      let
        val listTyCon = BE.lookupTyCon BuiltinName.listTyName
      in
        T.CONSTRUCTty {tyCon = listTyCon, args = [elemTy]}
      end

  fun MonoPrimApply (prim, retTy, args, loc) =
      let
        val (argExp, argTy) = Tuple (args, loc)
        val primTy = T.FUNMty ([argTy], retTy)
      in
        (R.RCPRIMAPPLY
           {primOp = {primitive = prim, ty = primTy},
            instTyList = nil,
            argExp = argExp,
            loc = loc},
         retTy)
      end

  fun IntAdd (arg1, arg2, loc) =
      MonoPrimApply (BuiltinPrimitive.Int_add BuiltinPrimitive.NoOverflowCheck,
                     BE.INTty, [arg1, arg2], loc)

  fun StringSize ((R.RCCONSTANT {const=A.STRING (s1,_), ...}, _), loc) =
      IntConst (size s1, loc)
    | StringSize (arg, loc) =
      MonoPrimApply (BuiltinPrimitive.String_size, BE.INTty, [arg], loc)

  fun StringAlloc (arg, loc) =
      MonoPrimApply (BuiltinPrimitive.String_allocArray, BE.STRINGty,
                     [arg], loc)

  fun StringCopy {src, si, dst, di, len, loc} =
      MonoPrimApply (BuiltinPrimitive.String_copy_unsafe, BE.UNITty,
                     [src, si, dst, di, len], loc)

  fun StringConcat ((R.RCCONSTANT {const=A.STRING (s1,_), ...}, _),
                    (R.RCCONSTANT {const=A.STRING (s2,_), ...}, _), loc) =
      StringConst (s1 ^ s2, loc)
    | StringConcat (arg1, arg2, loc) =
      let
        (*
         * let n1 = String_size s1
         *     n2 = String_size s2
         *     size = n1 + n2
         *     dst = String_array (size, 0)
         *     String_copy_unsafe (s1, 0, dst, 0, n1)
         *     String_copy_unsafe (s2, 0, dst, n1, n2)
         * in dst
         *)
        val (bind1, var_s1) = MonoLet (arg1, loc)
        val (bind2, var_s2) = MonoLet (arg2, loc)
        val (bind3, var_n1) = MonoLet (StringSize (Var (var_s1, loc), loc), loc)
        val (bind4, var_n2) = MonoLet (StringSize (Var (var_s2, loc), loc), loc)
        val dstSize = IntAdd (Var (var_n1, loc), Var (var_n2, loc), loc)
        val (bind5, var_dst) = MonoLet (StringAlloc (dstSize, loc), loc)
      in
        (bind1 o bind2 o bind3 o bind4 o bind5)
          (Seq ([StringCopy {src = Var (var_s1, loc),
                             si = IntConst (0, loc),
                             dst = Var (var_dst, loc),
                             di = IntConst (0, loc),
                             len = Var (var_n1, loc),
                             loc = loc},
                 StringCopy {src = Var (var_s2, loc),
                             si = IntConst (0, loc),
                             dst = Var (var_dst, loc),
                             di = Var (var_n1, loc),
                             len = Var (var_n2, loc),
                             loc = loc},
                 Var (var_dst, loc)], loc))
      end

  fun BoolConst (b, loc) =
      let
        val name = if b then BuiltinName.trueConName
                   else BuiltinName.falseConName
        val conInfo = BE.lookupCon name
      in
        (R.RCDATACONSTRUCT {con = conInfo,
                            instTyList = nil,
                            argExpOpt = NONE,
                            loc = loc},
         #ty conInfo)
      end

  fun BoolTy () =
      T.CONSTRUCTty
        {tyCon = BE.lookupTyCon BuiltinName.boolTyName,
         args = []}

  fun Some ((argExp, argTy), loc) =
      let
        val conInfo = BE.lookupCon BuiltinName.someConName
        val monoTy = TypesUtils.tpappTy (#ty conInfo, [argTy])
        val retTy = case TypesUtils.derefTy monoTy of
                      T.FUNMty (args, retTy) => retTy
                    | _ => raise Control.Bug "MonoDataCon"
      in
        (R.RCDATACONSTRUCT {con = conInfo,
                            instTyList = [argTy],
                            argExpOpt = SOME argExp,
                            loc = loc},
         retTy)
      end

  fun compileColumn (colname, ty, loc) =
      let
        fun compile ty =
            case TypesUtils.derefTy ty of
              T.CONSTRUCTty {tyCon={id,...}, args=nil} =>
              if TypID.eq (id, #id BE.INTtyCon)
              then ("int", false, IntConst (0, loc))
              else if TypID.eq (id, #id BE.WORDtyCon)
              then ("word", false, WordConst (0w0, loc))
              else if TypID.eq (id, #id BE.CHARtyCon)
              then ("char", false, CharConst (#"\000", loc))
              else if TypID.eq (id, #id BE.STRINGtyCon)
              then ("string", false, StringConst ("", loc))
              else if TypID.eq (id, #id BE.REALtyCon)
              then ("real", false, RealConst ("0.0", loc))
              else if TypID.eq (id, #id (BE.lookupTyCon BuiltinName.boolTyName))
              then ("bool", false, BoolConst (false, loc))
              else raise Control.Bug "compileColumn"
            | T.CONSTRUCTty {tyCon={id,...}, args=[argTy]} =>
              if TypID.eq (id, #id (BE.lookupTyCon BuiltinName.optionTyName))
              then
                let
                  val (tyname, null, witness) = compile argTy
                in
                  (tyname, true, Some (witness, loc))
                end
              else raise Control.Bug "compileColumn: option"
            | _ => raise Control.Bug "compileColumn: _"
        val (tyname, null, witness) = compile ty
      in
        {column = Record ([("colname", StringConst (colname, loc)),
                           ("typename", StringConst (tyname, loc)),
                           ("isnull", BoolConst (null, loc))],
                          loc),
         witness = (colname, witness)}
      end

  fun compileTable (tableName, columnTyMap, loc) =
      let
        val columns =
            map (fn (label, ty) => compileColumn (label, ty, loc))
                (LabelEnv.listItemsi columnTyMap)
        val elemTy = RecordTy [("colname", BE.STRINGty),
                               ("typename", BE.STRINGty),
                               ("isnull", BoolTy ())]
      in
        {table = Record ([("1", StringConst (tableName, loc)),
                          ("2", List (map #column columns, elemTy, loc))],
                         loc),
         witness = (tableName, Record (map #witness columns, loc))}
      end

  fun compileSchema (tableTyMap, loc) =
      let
        val tables =
            map (fn (label, table) => compileTable (label, table, loc))
                (LabelEnv.listItemsi tableTyMap)
        val elemTy =
            RecordTy [("1", BE.STRINGty),
                      ("2", ListTy (RecordTy [("colname", BE.STRINGty),
                                              ("typename", BE.STRINGty),
                                              ("isnull", BoolTy ())]))]
      in
        {schema = List (map #table tables, elemTy, loc),
         witness = Record (map #witness tables, loc)}
      end

  fun compileServerDesc (fields, loc) =
      let
        val fields =
            map (fn ("", exp) => ("", exp)
                  | (label, exp) => (label ^ " = ", exp))
                fields
      in
        case fields of
          nil => StringConst ("", loc)
        | (l,e)::t =>
          foldl
            (fn ((l,e),r) =>
                StringConcat
                  (StringConcat (r, StringConst (" " ^ l, loc), loc),
                   (e, BE.STRINGty), loc))
            (case l of "" => (e, BE.STRINGty)
                     | _ => StringConcat (StringConst (l, loc),
                                          (e, BE.STRINGty), loc))
            t
      end

  fun compileSQLServer (server, schema, resultTy, loc) =
      let
        val server = compileServerDesc (server, loc)
        val {schema, witness} = compileSchema (schema, loc)
        val conInfo = BE.lookupCon BuiltinName.sqlServerConName
        val instTyList = case TypesUtils.derefTy resultTy of
                           T.CONSTRUCTty {tyCon, args} => args
                         | _ => raise Control.Bug "compileSQLServer"
      in
        R.RCDATACONSTRUCT
          {con = conInfo,
           instTyList = instTyList,
           argExpOpt = SOME (#1 (Tuple ([server, schema, witness], loc))),
           loc = loc}
      end

  fun compileSqlexp (rcsqlexp, resultTy, loc) =
      case rcsqlexp of
        R.RCSQLSERVER {server, schema} =>
        let
          val server = map (fn (l, e) => (l, compileExp e)) server
        in
          compileSQLServer (server, schema, resultTy, loc)
        end

  and compileExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY {funExp, foreignFunTy, argExpList, loc} =>
        R.RCFOREIGNAPPLY
          {funExp = compileExp funExp,
           argExpList = map compileExp argExpList,
           foreignFunTy = foreignFunTy,
           loc = loc}
      | R.RCEXPORTCALLBACK {funExp, foreignFunTy, loc} =>
        R.RCEXPORTCALLBACK
          {funExp = compileExp funExp,
           foreignFunTy = foreignFunTy,
           loc = loc}
      | R.RCTAGOF (ty, loc) =>
        R.RCTAGOF (ty, loc)
      | R.RCSIZEOF (ty, loc) =>
        R.RCSIZEOF (ty, loc)
      | R.RCINDEXOF (label, recordTy, loc) =>
        R.RCINDEXOF (label, recordTy, loc)
      | R.RCCONSTANT {const, ty, loc} =>
        R.RCCONSTANT {const=const, ty=ty, loc=loc}
      | R.RCGLOBALSYMBOL symbol =>
        R.RCGLOBALSYMBOL symbol
      | R.RCVAR (varInfo, loc) =>
        R.RCVAR (varInfo, loc)
      | R.RCEXVAR (exVarInfo, loc) =>
        R.RCEXVAR (exVarInfo, loc)
      | R.RCPRIMAPPLY {primOp, instTyList, argExp, loc} =>
        R.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList,
           argExp = compileExp argExp,
           loc = loc}
      | R.RCOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        R.RCOPRIMAPPLY
          {oprimOp = oprimOp,
           instTyList = instTyList,
           argExp = compileExp argExp,
           loc = loc}
      | R.RCDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        R.RCDATACONSTRUCT
          {con = con,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | R.RCEXNCONSTRUCT {exn, instTyList, argExpOpt, loc} =>
        R.RCEXNCONSTRUCT
          {exn = exn,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | R.RCEXN_CONSTRUCTOR {exnInfo, loc} => (* FIXME check this *)
        R.RCEXN_CONSTRUCTOR {exnInfo=exnInfo, loc=loc}
      | R.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} => (* FIXME check this *)
        R.RCEXEXN_CONSTRUCTOR {exExnInfo=exExnInfo, loc=loc}
      | R.RCAPPM {funExp, funTy, argExpList, loc} =>
        R.RCAPPM
          {funExp = compileExp funExp,
           funTy = funTy,
           argExpList = map compileExp argExpList,
           loc = loc}
      | R.RCMONOLET {binds, bodyExp, loc} =>
        R.RCMONOLET
          {binds = map (fn (v,e) => (v, compileExp e)) binds,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | R.RCLET {decls, body, tys, loc} =>
        R.RCLET {decls = map compileDecl decls,
                 body = map compileExp body,
                 tys = tys,
                 loc = loc}
      | R.RCRECORD {fields, recordTy, loc} =>
        R.RCRECORD
          {fields = LabelEnv.map compileExp fields,
           recordTy = recordTy,
           loc = loc}
      | R.RCSELECT {indexExp, label, exp, expTy, resultTy, loc} =>
        R.RCSELECT
          {indexExp = compileExp indexExp,
           label = label,
           exp = compileExp exp,
           expTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | R.RCMODIFY {indexExp, label, recordExp, recordTy, elementExp,
                    elementTy, loc} =>
        R.RCMODIFY
          {indexExp = compileExp indexExp,
           label = label,
           recordExp = compileExp recordExp,
           recordTy = recordTy,
           elementExp = compileExp elementExp,
           elementTy = elementTy,
           loc = loc}
      | R.RCRAISE {exp, ty, loc} =>
        R.RCRAISE {exp = compileExp exp, ty = ty, loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, loc} =>
        R.RCHANDLE
          {exp = compileExp exp,
           exnVar = exnVar,
           handler = compileExp handler,
           loc = loc}
      | R.RCCASE {exp, expTy, ruleList, defaultExp, loc} =>
        R.RCCASE
          {exp = compileExp exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp e)) ruleList,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | R.RCEXNCASE {exp, expTy, ruleList, defaultExp, loc} =>
        R.RCEXNCASE
          {exp = compileExp exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp e)) ruleList,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | R.RCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        R.RCSWITCH
          {switchExp = compileExp switchExp,
           expTy = expTy,
           branches = map (fn (c,e) => (c, compileExp e)) branches,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | R.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        R.RCFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | R.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
        R.RCPOLYFNM
          {btvEnv = btvEnv,
           argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | R.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        R.RCPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp exp,
           loc = loc}
      | R.RCTAPP {exp, expTy, instTyList, loc} =>
        R.RCTAPP
          {exp = compileExp exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | R.RCSEQ {expList, expTyList, loc} =>
        R.RCSEQ
          {expList = map compileExp expList,
           expTyList = expTyList,
           loc = loc}
      | R.RCCAST (rcexp, ty, loc) =>
        R.RCCAST (compileExp rcexp, ty, loc)
      | R.RCSQL exp =>
        compileSqlexp exp
      | R.RCFFI (R.RCFFIIMPORT {ptrExp, ffiTy}, ty, loc) =>
        R.RCFFI (R.RCFFIIMPORT {ptrExp = compileExp ptrExp,
                                ffiTy = ffiTy}, ty, loc)

  and compileDecl rcdecl =
      case rcdecl of
        R.RCVAL (bindList, loc) =>
        R.RCVAL (map (fn (v,e) => (v, compileExp e)) bindList, loc)
      | R.RCVALREC (bindList, loc) =>
        R.RCVALREC (map (fn {var, expTy, exp} =>
                            {var=var, expTy=expTy, exp=compileExp exp})
                        bindList,
                    loc)
      | R.RCVALPOLYREC (btvEnv, bindList, loc) =>
        R.RCVALPOLYREC (btvEnv,
                        map (fn {var, expTy, exp} =>
                                {var=var, expTy=expTy, exp=compileExp exp})
                            bindList,
                        loc)
      | R.RCEXD (binds, loc) =>
        R.RCEXD (binds, loc)
      | R.RCEXNTAGD (bind, loc) => (* FIXME check this *)
        R.RCEXNTAGD (bind, loc)
      | R.RCEXPORTVAR (varInfo, loc) =>
        R.RCEXPORTVAR (varInfo, loc)
      | R.RCEXPORTEXN (exnInfo, loc) =>
        R.RCEXPORTEXN (exnInfo, loc)
      | R.RCEXTERNVAR (exVarInfo, loc) =>
        R.RCEXTERNVAR (exVarInfo, loc)
      | R.RCEXTERNEXN (exExnInfo, loc) =>
        R.RCEXTERNEXN (exExnInfo, loc)

  fun compile decls =
      map compileDecl decls

end
