(**
 * ElaboratorSQL.sml
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author ENDO Hiroki
 *)

structure ElaborateSQL =
struct

  structure A = Absyn
  structure S = AbsynSQL
  structure P = PatternCalc
  structure F = ElaborateErrorSQL
  structure E = ElaborateError
  datatype loc = datatype Loc.loc

  val SQLPrim = "SMLSharp_SQL_Prim"
  structure Name =
  struct
    val structure_Op = [SQLPrim, "Op"]
    val con_cons = (nil, "::")
    val con_nil = (nil, "nil")
    val con_SOME = ([SQLPrim, "Option"], "SOME")
    val con_NONE = ([SQLPrim, "Option"], "NONE")
    val con_true = ([SQLPrim, "Bool"], "true")
    val con_false = ([SQLPrim, "Bool"], "false")
    val con_True = ([SQLPrim, "Bool3"], "True")
    val con_False = ([SQLPrim, "Bool3"], "False")
    val con_Unknown = ([SQLPrim, "Bool3"], "Unknown")
    val ty_db = ([SQLPrim], "db")
    val ty_command = ([SQLPrim], "command")
    val fun_isSome = ([SQLPrim, "Option"], "isSome")
    val fun_not3 = ([SQLPrim, "Bool3"], "not3")
    val fun_and3 = ([SQLPrim, "Bool3"], "and3")
    val fun_or3 = ([SQLPrim, "Bool3"], "or3")
    val fun_fromBool = ([SQLPrim, "Bool3"], "fromBool")
    val fun_isTrue = ([SQLPrim, "Bool3"], "isTrue")
    val fun_is = ([SQLPrim, "Bool3"], "is")
    val fun_map = ([SQLPrim, "List"], "map")
    val fun_filter = ([SQLPrim, "List"], "filter")
    val fun_append = ([SQLPrim, "List"], "@")
    val fun_hd = ([SQLPrim, "List"], "hd")
    val fun_take = ([SQLPrim, "List"], "take")
    val fun_drop = ([SQLPrim, "List"], "drop")
    val fun_onlyOne = ([SQLPrim, "List2"], "onlyOne")
    val fun_isNotEmpty = ([SQLPrim, "List2"], "isNotEmpty")
    val fun_prod = ([SQLPrim, "List2"], "prod")
    val fun_join = ([SQLPrim, "List2"], "join")
    val fun_nub = ([SQLPrim, "List2"], "nub")
    val fun_sortBy = ([SQLPrim, "List2"], "sortBy")
    val fun_groupBy = ([SQLPrim, "List2"], "groupBy")
    val fun_compare = ([SQLPrim], "compare")
    val fun_comparePair = ([SQLPrim, "General2"], "comparePair")
    val fun_reverseOrder = ([SQLPrim, "General2"], "reverseOrder")
    val fun_fromSQL = ([SQLPrim], "fromSQL")
    val fun_toSQL = ([SQLPrim], "toSQL")
    val fun_dummyCursor = ([SQLPrim], "dummyCursor")
    val fun_newCursor = ([SQLPrim], "newCursor")
    val fun_sqlserver = ([SQLPrim], "sqlserver")
    val fun_sqleval = ([SQLPrim], "sqleval")
    val fun_closeCommand = ([SQLPrim], "closeCommand")
    val fun_ty = ([SQLPrim], "ty")
    val con_CONST = ([SQLPrim, "Ast"], "CONST")
    val con_INT = ([SQLPrim, "Ast"], "INT")
    val con_WORD = ([SQLPrim, "Ast"], "WORD")
    val con_REAL = ([SQLPrim, "Ast"], "REAL")
    val con_STRING = ([SQLPrim, "Ast"], "STRING")
    val con_CHAR = ([SQLPrim, "Ast"], "CHAR")
    val con_BOOL = ([SQLPrim, "Ast"], "BOOL")
    val con_NULL = ([SQLPrim, "Ast"], "NULL")
    val con_COLUMN1 = ([SQLPrim, "Ast"], "COLUMN1")
    val con_COLUMN2 = ([SQLPrim, "Ast"], "COLUMN2")
    val con_EXISTS = ([SQLPrim, "Ast"], "EXISTS")
    val con_IS = ([SQLPrim, "Ast"], "IS")
    val con_IS_NOT = ([SQLPrim, "Ast"], "IS_NOT")
    val con_NOT = ([SQLPrim, "Ast"], "NOT")
    val con_AND = ([SQLPrim, "Ast"], "AND")
    val con_OR = ([SQLPrim, "Ast"], "OR")
    val con_EXP_SUBQUERY = ([SQLPrim, "Ast"], "EXP_SUBQUERY")
    val con_FUNCALL = ([SQLPrim, "Ast"], "FUNCALL")
    val con_OP2 = ([SQLPrim, "Ast"], "OP2")
    val con_UNARYOP = ([SQLPrim, "Ast"], "UNARYOP")
    val con_WHERE = ([SQLPrim, "Ast"], "WHERE")
    val con_TABLEID = ([SQLPrim, "Ast"], "TABLEID")
    val con_TABLE = ([SQLPrim, "Ast"], "TABLE")
    val con_TABLE_SUBQUERY = ([SQLPrim, "Ast"], "TABLE_SUBQUERY")
    val con_TABLE_AS = ([SQLPrim, "Ast"], "TABLE_AS")
    val con_JOIN = ([SQLPrim, "Ast"], "JOIN")
    val con_INNERJOIN = ([SQLPrim, "Ast"], "INNERJOIN")
    val con_CROSSJOIN = ([SQLPrim, "Ast"], "CROSSJOIN")
    val con_NATURALJOIN = ([SQLPrim, "Ast"], "NATURALJOIN")
    val con_FROM = ([SQLPrim, "Ast"], "FROM")
    val con_ASC = ([SQLPrim, "Ast"], "ASC")
    val con_DESC = ([SQLPrim, "Ast"], "DESC")
    val con_ORDERBY = ([SQLPrim, "Ast"], "ORDERBY")
    val con_OFFSET = ([SQLPrim, "Ast"], "OFFSET")
    val con_LIMIT = ([SQLPrim, "Ast"], "LIMIT")
    val con_GROUPBY = ([SQLPrim, "Ast"], "GROUPBY")
    val con_HAVING = ([SQLPrim, "Ast"], "HAVING")
    val con_ALL = ([SQLPrim, "Ast"], "ALL")
    val con_DISTINCT = ([SQLPrim, "Ast"], "DISTINCT")
    val con_SELECT = ([SQLPrim, "Ast"], "SELECT")
    val con_QUERY = ([SQLPrim, "Ast"], "QUERY")
    val con_QUERY_COMMAND = ([SQLPrim, "Ast"], "QUERY_COMMAND")
    val con_DEFAULT = ([SQLPrim, "Ast"], "DEFAULT")
    val con_VALUE = ([SQLPrim, "Ast"], "VALUE")
    val con_INSERT = ([SQLPrim, "Ast"], "INSERT")
    val con_INSERT_VALUES = ([SQLPrim, "Ast"], "INSERT_VALUES")
    val con_INSERT_SELECT = ([SQLPrim, "Ast"], "INSERT_SELECT")
    val con_UPDATE = ([SQLPrim, "Ast"], "UPDATE")
    val con_DELETE = ([SQLPrim, "Ast"], "DELETE")
    val con_BEGIN = ([SQLPrim, "Ast"], "BEGIN")
    val con_COMMIT = ([SQLPrim, "Ast"], "COMMIT")
    val con_ROLLBACK = ([SQLPrim, "Ast"], "ROLLBACK")
    val con_SEQ = ([SQLPrim, "Ast"], "SEQ")
    val con_EXPty = ([SQLPrim], "EXPty")
    val con_WHRty = ([SQLPrim], "WHRty")
    val con_FROMty = ([SQLPrim], "FROMty")
    val con_ORDERBYty = ([SQLPrim], "ORDERBYty")
    val con_OFFSETty = ([SQLPrim], "OFFSETty")
    val con_LIMITty = ([SQLPrim], "LIMITty")
    val con_SELECTty = ([SQLPrim], "SELECTty")
    val con_QUERYty = ([SQLPrim], "QUERYty")
    val con_COMMANDty = ([SQLPrim], "COMMANDty")
    val con_DBty = ([SQLPrim], "DBty")
  end

  fun mapi f l =
      let fun map f i nil = nil
            | map f i (h::t) = f (i,h) :: map f (i+1) t
      in map f 0 l
      end

  fun prepend names vid : A.longvid =
      (map (fn s => (Symbol.intern s, #2 vid)) names, vid, #2 vid)

  fun intern (names, name) loc : A.longvid =
      prepend names (Symbol.intern name, loc)

  fun univKind loc =
      (PatternCalc.emptyKindProp, P.UNIV, LOC loc)

  fun Vid symbol loc : A.vid =
      (symbol, loc)

  fun Lab lab (_ : A.loc) : A.lab =
      lab

  fun Label name (loc : A.loc) =
      (RecordLabel.fromString name, loc)

  fun tupleList items loc =
      map (fn (label, item) => (Lab (label, loc), item))
          (RecordLabel.tupleList items)

  fun Ty ty (_ : A.loc) : P.annot_ty =
      ty

  fun Tyvar symbol loc : P.tyvar =
      (symbol, loc)

  fun TyWild loc =
      P.TY (P.TYWILD (LOC loc))

  fun TyID tv loc =
      P.TYVAR (tv loc)

  fun TyCon args name loc =
      P.TYCON (map (fn arg => arg loc) args, intern name loc, LOC loc)

  fun TyFun (ty1, ty2) loc =
      P.TYFUN (ty1 loc, ty2 loc, loc)

  fun Pat pat (_ : A.loc) : P.pat =
      pat

  fun PatWild loc =
      P.PATWILD (LOC loc)

  fun PatUnit loc =
      P.PATCONST (A.UNITCONST, LOC loc)

  fun PatVar symbol loc =
      P.PATID (nil, (symbol, loc), loc)

  fun PatVarLab (label, loc) (_:A.loc) =
      P.PATID (nil, (Symbol.intern (RecordLabel.toString label), loc), loc)

  fun PatRecordWithFlex flex fields loc =
      P.PATRECORD
        (map (fn (lab, pat) => (lab loc, pat loc, LOC loc)) fields,
         flex,
         LOC loc)

  fun PatFlexRecord fields =
      PatRecordWithFlex true fields

  fun PatRecord fields =
      PatRecordWithFlex false fields

  fun PatTuple pats loc =
      PatRecord (tupleList pats loc) loc

  fun PatPair (pat1, pat2) =
      PatTuple [pat1, pat2]

  fun PatAs (vid, pat) loc =
      P.PATAS (vid, NONE, pat loc, LOC loc)

  fun PatAsLab ((label, loc1), pat) loc =
      P.PATAS ((Symbol.intern (RecordLabel.toString label), loc1),
               NONE,
               pat loc,
               LOC loc)

  fun PatCon name vid loc =
      P.PATCON (intern name loc, P.PATID (nil, vid, #2 vid), LOC loc)

  fun PatTyped (pat, ty) loc =
      P.PATTYPED (pat loc, ty loc, LOC loc)

  fun Exp exp (_ : A.loc) : P.exp =
      exp

  fun Loc (loc : A.loc) x =
      fn (_ : A.loc) => x loc

  fun Var symbol loc =
      P.EXPID (nil, (symbol, loc), loc)

  fun LongVar longvid (_ : A.loc) =
      P.EXPID longvid

  fun VarLab (label, loc) (_ : A.loc) =
      P.EXPID (nil, (Symbol.intern (RecordLabel.toString label), loc), loc)

  fun ExVar name loc =
      P.EXPID (intern name loc)

  fun Case1 exp1 (pat, exp2) loc =
      P.EXPCASE (exp1 loc, [(pat loc, exp2 loc, LOC loc)], LOC loc)

  fun Fn (pat, exp) loc =
      P.EXPFN ([(pat loc, exp loc, LOC loc)], LOC loc)

  fun Fn1 f loc =
      let
        val x = Symbol.generate NONE
      in
        Fn (PatVar x, f (Var x)) loc
      end

  fun Let tyvars (pat, exp) exp2 loc =
      P.EXPLET
        ([P.DECVAL ((map (fn x => (x loc, univKind loc, LOC loc)) tyvars, LOC loc),
                    [(pat loc, exp loc, LOC loc)],
                    nil,
                    LOC loc)],
         exp2 loc,
         LOC loc)

  fun Const const loc =
      P.EXPCONST (const, LOC loc)

  fun Unit loc =
      Const A.UNITCONST loc

  fun Int n =
      Const (A.INT (Int.toLarge n))

  fun String s =
      Const (A.STRING s)

  fun LabString (label, loc) (_ : A.loc) =
      String (RecordLabel.toString label) loc

  fun VidString ((symbol, _) : A.vid) =
      String (Symbol.toString symbol)

  fun StringFirst S.FIRST = String "first"
    | StringFirst S.NEXT = String "next"

  fun StringRows S.ROW = String "row"
    | StringRows S.ROWS = String "rows"

  fun App exp1 exp2 loc =
      P.EXPAPP (exp1 loc, exp2 loc, LOC loc)

  fun Record fields loc =
      P.EXPRECORD
        (map (fn (lab, exp) => (lab loc, exp loc, LOC loc)) fields, LOC loc)

  fun Tuple exps loc =
      Record (tupleList exps loc) loc

  fun UnitTuple loc =
      Tuple nil loc

  fun Pair (x, y) =
      Tuple [x, y]

  fun Select lab exp loc =
      P.EXPAPP (P.EXPSELECT (lab loc, LOC loc), exp loc, LOC loc)

  fun Fst exp =
      Select (Label "1") exp

  fun Snd exp =
      Select (Label "2") exp

  fun Modify exp fields loc =
      P.EXPRECORD_UPDATE
        (exp loc,
         map (fn (lab, e) => (lab loc, e loc, LOC loc)) fields,
         LOC loc)

  fun Typed (exp, ty) loc =
      P.EXPTYPED (exp loc, ty loc, LOC loc)

  fun Ignore exp =
      Case1 exp (PatWild, Unit)

  fun Seq (exp1, exp2) =
      Case1 exp1 (PatWild, exp2)

  fun Join (exp1, exp2) loc =
      P.EXPJOIN (P.JOIN, exp1 loc, exp2 loc, LOC loc)

  fun Con name nil = ExVar name
    | Con name [arg] = App (ExVar name) arg
    | Con name args = App (ExVar name) (Tuple args)
        fun toTuple e = Tuple

  fun Cons (e1, e2) =
      Con Name.con_cons [e1, e2]

  fun Nil loc =
      Con Name.con_nil [] loc

  fun List exps =
      foldr Cons Nil exps

  fun Some x =
      Con Name.con_SOME [x]

  fun None loc =
      Con Name.con_NONE [] loc

  fun True loc =
      Con Name.con_true [] loc

  fun False loc =
      Con Name.con_false [] loc

  fun True3 loc =
      Con Name.con_True [] loc

  fun False3 loc =
      Con Name.con_False [] loc

  fun Unknown3 loc =
      Con Name.con_Unknown [] loc

  fun Option NONE = None
    | Option (SOME x) = Some x

  fun Ty_db (toyTy, connTy) loc =
      TyCon [toyTy, connTy] Name.ty_db loc

  fun Ty_command (toyTy, connTy) loc =
      TyCon [toyTy, connTy] Name.ty_command loc

  fun Fun_not3 e =
      App (ExVar Name.fun_not3) e

  fun Fun_and3 (e1, e2) =
      App (ExVar Name.fun_and3) (Tuple [e1, e2])

  fun Fun_or3 (e1, e2) =
      App (ExVar Name.fun_or3) (Tuple [e1, e2])

  fun Fun_fromBool e =
      App (ExVar Name.fun_fromBool) e

  fun Fun_isTrue e =
      App (ExVar Name.fun_isTrue) e

  fun Fun_is e1 e2 =
      App (App (ExVar Name.fun_is) e1) e2

  fun Fun_isSome e =
      Fun_fromBool (App (ExVar Name.fun_isSome) e)

  fun Fun_map f l =
      App (App (ExVar Name.fun_map) (Fn1 f)) l

  fun Fun_filter f l =
      App (App (ExVar Name.fun_filter) (Fn1 (fn x => Fun_isTrue (f x)))) l

  fun Fun_append (e1, e2) =
      App (ExVar Name.fun_append) (Tuple [e1, e2])

  fun Fun_hd e =
      App (ExVar Name.fun_hd) e

  fun Fun_take (e, n) =
      App (ExVar Name.fun_take) (Pair (e, n))

  fun Fun_drop (e, n) =
      App (ExVar Name.fun_drop) (Pair (e, n))

  fun Fun_onlyOne e =
      App (ExVar Name.fun_onlyOne) e

  fun Fun_isNotEmpty e =
      App (ExVar Name.fun_isNotEmpty) e

  fun Fun_prod (e1, e2) =
      App (ExVar Name.fun_prod) (Tuple [e1, e2])

  fun Fun_join f (e1, e2) =
      App (App (ExVar Name.fun_join) (Fn1 f)) (Tuple [e1, e2])

  fun Fun_nub f e =
      App (App (ExVar Name.fun_nub) (Fn1 f)) e

  fun Fun_sortBy f cmp l =
      App (App (App (ExVar Name.fun_sortBy) (Fn1 f)) cmp) l

  fun Fun_groupBy f cmp l =
      App (App (App (ExVar Name.fun_groupBy) (Fn1 f)) cmp) l

  val Var_compare =
      ExVar Name.fun_compare

  fun Fun_compare x =
      App (ExVar Name.fun_compare) x

  fun Fun_comparePair (f1, f2) =
      App (ExVar Name.fun_comparePair) (Pair (f1, f2))

  fun Fun_reverseOrder x =
      App (ExVar Name.fun_reverseOrder) x

  fun Fun_fromSQL (h, i) =
      App (ExVar Name.fun_fromSQL) (Tuple [h, Int i])

  fun Fun_toSQL x =
      App (ExVar Name.fun_toSQL) x

  fun Fun_dummyCursor x =
      App (ExVar Name.fun_dummyCursor) x

  fun Fun_newCursor readFn res =
      App (App (ExVar Name.fun_newCursor) readFn) res

  fun Fun_sqlserver (serv, schema) =
      App (ExVar Name.fun_sqlserver) (Tuple [serv, schema])

  fun Fun_sqleval query x =
      App (App (ExVar Name.fun_sqleval) query) x

  fun Var_closeCommand loc =
      ExVar Name.fun_closeCommand loc

  fun Con_CONST x =
      Con Name.con_CONST [x]

  fun Con_INT const =
      Con Name.con_INT [Const const]

  fun Con_WORD const =
      Con Name.con_WORD [Const const]

  fun Con_REAL const =
      Con Name.con_REAL [Const const]

  fun Con_STRING const =
      Con Name.con_STRING [Const const]

  fun Con_CHAR const =
      Con Name.con_CHAR [Const const]

  fun Con_BOOL x =
      Con Name.con_BOOL [x]

  fun Con_NULL loc =
      Con Name.con_NULL [] loc

  fun Con_COLUMN1 lab =
      Con Name.con_COLUMN1 [LabString lab]

  fun Con_COLUMN2 (lab1, lab2) =
      Con Name.con_COLUMN2 [LabString lab1, LabString lab2]

  fun Con_EXISTS query =
      Con Name.con_EXISTS [query]

  fun Con_IS (q, s) =
      Con Name.con_IS [q, String s]

  fun Con_IS_NOT (q, s) =
      Con Name.con_IS_NOT [q, String s]

  fun Con_NOT q =
      Con Name.con_NOT [q]

  fun Con_AND (q1, q2) =
      Con Name.con_AND [q1, q2]

  fun Con_OR (q1, q2) =
      Con Name.con_OR [q1, q2]

  fun Con_EXP_SUBQUERY query =
      Con Name.con_EXP_SUBQUERY [query]

  fun Con_FUNCALL string args =
      Con Name.con_FUNCALL [String string, List args]

  fun Con_OP2 (arg1, symbol, arg2) =
      Con Name.con_OP2 [arg1, VidString symbol, arg2]

  fun Con_UNARYOP s arg =
      Con Name.con_UNARYOP [String s, arg]

  fun Con_WHERE exp =
      Con Name.con_WHERE [exp]

  fun Con_TABLEID (db, lab) =
      Con Name.con_TABLEID [db, LabString lab]

  fun Con_TABLE table =
      Con Name.con_TABLE [table]

  fun Con_TABLE_SUBQUERY query =
      Con Name.con_TABLE_SUBQUERY [query]

  fun Con_TABLE_AS (table, label) =
      Con Name.con_TABLE_AS [table, LabString label]

  fun Con_JOIN (tab1, tab2, exp) =
      Con Name.con_JOIN [tab1, tab2, exp]

  fun Con_INNERJOIN (tab1, tab2, exp) =
      Con Name.con_INNERJOIN [tab1, tab2, exp]

  fun Con_CROSSJOIN (tab1, tab2) =
      Con Name.con_CROSSJOIN [tab1, tab2]

  fun Con_NATURALJOIN (tab1, tab2) =
      Con Name.con_NATURALJOIN [tab1, tab2]

  fun Con_FROM tables =
      Con Name.con_FROM [List tables]

  fun Con_ASC loc =
      Con Name.con_ASC [] loc

  fun Con_DESC loc =
      Con Name.con_DESC [] loc

  fun Con_ORDERBY keys =
      Con Name.con_ORDERBY [List (map Pair keys)]

  fun Con_OFFSET {offset = (offset, rows), fetch} =
      Con Name.con_OFFSET
          [Record
             [(Label "offset", Pair (offset, StringRows rows)),
              (Label "fetch",
               case fetch of
                 NONE => None
               | SOME (first, count, rows) =>
                 Tuple [StringFirst first, Option count, StringRows rows])]]

  fun Con_LIMIT {limit, offset} =
      Con Name.con_LIMIT
          [Record
             [(Label "limit", Option limit),
              (Label "offset", Option offset)]]

  fun Con_GROUPBY (keys, having) =
      Con Name.con_GROUPBY [List keys, having]

  fun Con_HAVING exp =
      Con Name.con_HAVING [exp]

  fun Con_ALL loc =
      Con Name.con_ALL [] loc

  fun Con_DISTINCT loc =
      Con Name.con_DISTINCT [] loc

  fun Con_SELECT (distinct, selectList) =
      Con Name.con_SELECT
          [distinct,
           List (map (fn (l, e) => Pair (LabString l, e)) selectList)]

  fun Con_QUERY (select, from, whr, groupby, orderby, limit) =
      Con Name.con_QUERY [select, from,
                          Option whr, Option groupby,
                          Option orderby, Option limit]

  fun Con_QUERY_COMMAND query =
      Con Name.con_QUERY_COMMAND [query]

  fun Con_DEFAULT loc =
      Con Name.con_DEFAULT [] loc

  fun Con_VALUE exp =
      Con Name.con_VALUE [exp]

  fun Con_INSERT (tableId, labels, values) =
      Con Name.con_INSERT
          [tableId,
           Option (Option.map (List o map LabString) labels),
           values]

  fun Con_INSERT_VALUES arg =
      Con Name.con_INSERT_VALUES [arg]

  fun Con_INSERT_SELECT select =
      Con Name.con_INSERT_SELECT [select]

  fun Con_UPDATE (tableId, setList, whr) =
      Con Name.con_UPDATE
          [tableId,
           List (map (fn (l, e) => Pair (LabString l, e)) setList),
           whr]

  fun Con_DELETE (tableId, whr) =
      Con Name.con_DELETE [tableId, whr]

  fun Con_BEGIN loc =
      Con Name.con_BEGIN [] loc

  fun Con_COMMIT loc =
      Con Name.con_COMMIT [] loc

  fun Con_ROLLBACK loc =
      Con Name.con_ROLLBACK [] loc

  fun Con_SEQ (c1, c2) =
      Con Name.con_SEQ [c1, c2]

  fun Con_EXPty (term, toy) =
      Con Name.con_EXPty [term, toy]

  fun Con_WHRty (term, toy) =
      Con Name.con_WHRty [term, toy]

  fun Con_FROMty (term, toy) =
      Con Name.con_FROMty [term, toy]

  fun Con_ORDERBYty (term, toy) =
      Con Name.con_ORDERBYty [term, toy]

  fun Con_OFFSETty (term, toy) =
      Con Name.con_OFFSETty [term, toy]

  fun Con_LIMITty (term, toy) =
      Con Name.con_LIMITty [term, toy]

  fun Con_SELECTty (term, toy, read) =
      Con Name.con_SELECTty [term, toy, read]

  fun Con_QUERYty (term, toy, read) =
      Con Name.con_QUERYty [term, toy, read]

  fun Con_COMMANDty (term, toy, ret) =
      Con Name.con_COMMANDty [term, toy, ret]

  fun sqlFunName ((symbol, _) : A.vid) =
        String.translate (fn #"'" => "" | c => str (Char.toUpper c))
                         (Symbol.toString symbol)

  fun sappSpine (S.APP (x, y, _)) r = sappSpine x (y :: r)
    | sappSpine x r = x :: r

  (* syntactic category of each query construct *)
  datatype ty =
      EXPty
    | WHRty
    | FROMty
    | ORDERBYty
    | OFFSETty
    | LIMITty
    | SELECTty
    | QUERYty
    | COMMANDty
    | DBty

  fun tyToConName ty =
      case ty of
        EXPty => Name.con_EXPty
      | WHRty => Name.con_WHRty
      | FROMty => Name.con_FROMty
      | ORDERBYty => Name.con_ORDERBYty
      | OFFSETty => Name.con_OFFSETty
      | LIMITty => Name.con_LIMITty
      | SELECTty => Name.con_SELECTty
      | QUERYty => Name.con_QUERYty
      | COMMANDty => Name.con_COMMANDty
      | DBty => Name.con_DBty

  type labset = A.loc RecordLabel.Map.map

  fun singletonLabset lab : labset =
      RecordLabel.Map.singleton lab

  fun listToLabset labs : labset =
      foldl (fn ((lab, loc), z) => RecordLabel.Map.insert (z, lab, loc))
            RecordLabel.Map.empty
            labs

  fun memberLabset (labset, (lab, _) : A.lab) =
      RecordLabel.Map.inDomain (labset, lab)

  fun unionLabset (labset1, labset2) : labset =
      RecordLabel.Map.unionWith #1 (labset1, labset2)

  fun differenceLabset (labset1, labset2) : labset =
      RecordLabel.Map.mergeWith
        (fn (SOME x, NONE) => SOME x | _ => NONE)
        (labset1, labset2)

  type column2set = (A.loc * labset) RecordLabel.Map.map

  val emptySet = RecordLabel.Map.empty : column2set

  fun singleton ((lab1, loc1), lab2) : column2set =
      RecordLabel.Map.singleton (lab1, (loc1, singletonLabset lab2))

  fun union (set1, set2) : column2set =
      RecordLabel.Map.unionWith
        (fn ((loc1, labset1), (_, labset2)) =>
            (loc1, unionLabset (labset1, labset2)))
        (set1, set2)

  fun listToSet pairs =
      foldl union emptySet (map singleton pairs)

  fun member (set, ((lab1, _), lab2)) =
      case RecordLabel.Map.find (set, lab1) of
        NONE => false
      | SOME (_, labset) => memberLabset (labset, lab2)

  fun listItems set =
      map (fn (lab1, (loc1, labset)) =>
              ((lab1, loc1), RecordLabel.Map.listItemsi labset))
          (RecordLabel.Map.listItemsi set)

  fun intersect (set, NONE) = emptySet
    | intersect (set, SOME labset) =
      RecordLabel.Map.filteri
        (fn (lab, _) => RecordLabel.Map.inDomain (labset, lab))
        set

  fun difference (set, labset) =
      RecordLabel.Map.filteri
        (fn (lab, _) => not (RecordLabel.Map.inDomain (labset, lab)))
        set

  datatype query_const =
      INT of IntInf.int
    | WORD of IntInf.int
    | STRING of string
    | REAL of string
    | CHAR of char
    | BOOL of bool

  (* SQL query constructs.
   * For simplicity, we define a single all-in-one datatype rather than
   * a datatype for each syntactic category. *)
  datatype query =
      MLEXP of P.longvid
    | EMBED of Symbol.symbol * ty * S.loc
    | CONST of query_const * S.loc
    | NULL of S.loc
    | COLUMN1 of P.lab
    | COLUMN2 of (P.lab * P.lab) * S.loc
    | OP1 of S.op1 * query * S.loc
    | OP2 of S.op2 * query * query * S.loc
    | APP of query * query * S.loc
    | SQLAPP of bool * P.vid * query * S.loc
    | APPOP2 of P.vid * query * query * S.loc
    | TUPLE of query list * S.loc
    | EXISTS of query * S.loc
    | EXP_SUBQUERY of query * S.loc
    | WHERE of query * S.loc
    | FROM of table list * S.loc
    | ORDERBY of (query * S.asc_desc option) list * S.loc
    | OFFSET of
      {offset : query * S.row_rows * S.loc,
       fetch : (S.first_next * query option * S.row_rows * S.loc) option,
       loc : S.loc}
    | LIMIT of
      {limit : query option * S.loc,
       offset : (query * S.loc) option,
       loc : S.loc}
    | SELECT of S.distinct_all option * ((P.lab * query) list * S.loc) * S.loc
    | QUERY of
      {select : query,
       from : query,
       correlate : {outer : P.lab list, inner : P.lab list} option,
       whr : query option,
       groupBy : group_by option,
       orderBy : query option,
       limit : query option,
       loc : S.loc}
    | QUERY_COMMAND of query
    | INSERT_VALUES of
      {table : table_selector,
       labels : P.lab list,
       values : ((query option * S.loc) list * S.loc) list,
       loc : S.loc}
    | INSERT_SELECT of
      {table : table_selector,
       labels : P.lab list option,
       query : query,
       loc : S.loc}
    | INSERT_VAR of
      {table : table_selector,
       labels : P.lab list,
       values : P.longvid,
       loc : S.loc}
    | UPDATE of
      {table : table_selector,
       setList : (P.lab * query) list,
       whr : query option,
       loc : S.loc}
    | DELETE of {table : table_selector, whr : query option, loc : S.loc}
    | BEGIN of S.loc
    | COMMIT of S.loc
    | ROLLBACK of S.loc
    | SEQ of query * query * S.loc

  (* table expressions *)
  and table =
      TABLE of table_selector * P.lab option
    | TABLE_AS of table * P.lab * S.loc
    | TABLE_SUBQUERY of query * S.loc
    | TABLE_JOIN of table * join * table * S.loc

  (* table join operators *)
  and join =
      INNER_JOIN of {inner : bool} * query
    | CROSS_JOIN
    | NATURAL_JOIN

  (* table selector in the given database *)
  withtype table_selector =
      {db : query, lab : P.lab, loc : S.loc}

  and group_by =
      {columns : column2set,
       representatives : column2set,
       groupBy : query list * S.loc,
       having : (query * S.loc) option}

  datatype sql_or_ml = SQL of query | ML of query

  fun getLoc (MLEXP (_, _, loc)) = loc
    | getLoc (EMBED (_, _, loc)) = loc
    | getLoc (CONST (_, loc)) = loc
    | getLoc (NULL loc) = loc
    | getLoc (COLUMN1 (_, loc)) = loc
    | getLoc (COLUMN2 (_, loc)) = loc
    | getLoc (OP1 (_, _, loc)) = loc
    | getLoc (OP2 (_, _, _, loc)) = loc
    | getLoc (APP (_, _, loc)) = loc
    | getLoc (SQLAPP (_, _, _, loc)) = loc
    | getLoc (APPOP2 (_, _, _, loc)) = loc
    | getLoc (TUPLE (_, loc)) = loc
    | getLoc (EXISTS (_, loc)) = loc
    | getLoc (EXP_SUBQUERY (_, loc)) = loc
    | getLoc (WHERE (_, loc)) = loc
    | getLoc (FROM (_, loc)) = loc
    | getLoc (ORDERBY (_, loc)) = loc
    | getLoc (OFFSET {loc, ...}) = loc
    | getLoc (LIMIT {loc, ...}) = loc
    | getLoc (SELECT (_, _, loc)) = loc
    | getLoc (QUERY {loc, ...}) = loc
    | getLoc (QUERY_COMMAND q) = getLoc q
    | getLoc (INSERT_VALUES {loc, ...}) = loc
    | getLoc (INSERT_SELECT {loc, ...}) = loc
    | getLoc (INSERT_VAR {loc, ...}) = loc
    | getLoc (UPDATE {loc, ...}) = loc
    | getLoc (DELETE {loc, ...}) = loc
    | getLoc (BEGIN loc) = loc
    | getLoc (COMMIT loc) = loc
    | getLoc (ROLLBACK loc) = loc
    | getLoc (SEQ (_, _, loc)) = loc

  fun tableNames table =
      case table of
        TABLE (_, SOME k) => [k]
      | TABLE (_, NONE) => nil
      | TABLE_SUBQUERY _ => nil
      | TABLE_AS (tab, k, _) => tableNames tab @ [k]
      | TABLE_JOIN (tab1, _, tab2, _) => tableNames tab1 @ tableNames tab2

  fun tableListNames tables =
      List.concat (map tableNames tables)

  local
    fun pair (NONE, NONE) = NONE
      | pair (pat1, pat2) =
        SOME (PatPair (getOpt (pat1, PatWild), getOpt (pat2, PatWild)))
    fun name (lab, NONE) = SOME (PatVarLab lab)
      | name (lab, SOME pat) = SOME (PatAsLab (lab, pat))
    fun join (pair1, pair2) =
        (pair (pair pair1, pair pair2), NONE)
  in

  fun tableToPatPair table =
      case table of
        TABLE (_, NONE) => (NONE, NONE)
      | TABLE (_, SOME label) => (NONE, SOME (PatVarLab label))
      | TABLE_SUBQUERY _ => (NONE, NONE)
      | TABLE_JOIN (tab1, _, tab2, _) =>
        join (tableToPatPair tab1, tableToPatPair tab2)
      | TABLE_AS (tab, lab, _) =>
        let
          val (pat1, pat2) = tableToPatPair tab
        in
          (pat1, name (lab, pat2))
        end

  fun tableToPat table =
      getOpt (pair (tableToPatPair table), PatWild)

  fun tableListToPat nil = PatWild
    | tableListToPat (table :: tables) =
      getOpt (pair (foldl (fn (tab, z) => join (z, tableToPatPair tab))
                          (tableToPatPair table)
                          tables),
              PatWild)

  end (* local *)

  fun flattenTable table x =
      Case1 x (tableToPat table,
               Record (map (fn l => (Lab l, VarLab l)) (tableNames table)))

  fun flattenTableList tables x =
      Case1 x (tableListToPat tables,
               Record (map (fn l => (Lab l, VarLab l)) (tableListNames tables)))

  fun correlateJoin NONE outerRecord = (fn x => x)
    | correlateJoin (SOME {outer, inner}) outerRecord =
      Fun_map
        (fn innerRecord =>
            Case1
              (Pair (outerRecord, innerRecord))
              (PatPair
                 (PatFlexRecord (map (fn l => (Lab l, PatVarLab l)) outer),
                  PatRecord (map (fn l => (Lab l, PatVarLab l)) inner)),
               Record (map (fn l => (Lab l, VarLab l)) (outer @ inner))))

  fun column2setToRecord f set =
      let
        fun inner lab1 labset =
            RecordLabel.Map.foldri
              (fn (lab2, loc2, z) =>
                  (Lab (lab2, loc2), f (lab1, (lab2, loc2))) :: z)
              nil
              labset
        fun outer set =
            RecordLabel.Map.foldri
              (fn (lab1, (loc1, labset), z) =>
                  (Lab (lab1, loc1), Record (inner (lab1, loc1) labset)) :: z)
              nil
              set
      in
        Record (outer set)
      end

  fun transpose (columns, representatives) =
      Fun_map
        (fn equiv =>
            column2setToRecord
              (fn (k, l) =>
                  if member (representatives, (k, l))
                  then Select (Lab l) (Select (Lab k) (Fun_hd equiv))
                  else Fun_map (fn x => Select (Lab l) (Select (Lab k) x))
                               equiv)
              (union (columns, representatives)))

  fun nestedPair nil = Int 0
    | nestedPair (h::t) = foldl (fn (x,z) => Pair (z,x)) h t

  fun nestedCompare nil = Var_compare
    | nestedCompare (h::t) = foldl (fn (x,z) => Fun_comparePair (z,x)) h t

  fun ascdescToToy NONE = Var_compare
    | ascdescToToy (SOME S.ASC) = Var_compare
    | ascdescToToy (SOME S.DESC) = Fn1 (Fun_reverseOrder o Fun_compare)

  fun distinctToToy selectList NONE = (fn c => c)
    | distinctToToy selectList (SOME S.ALL) = (fn c => c)
    | distinctToToy selectList (SOME S.DISTINCT) =
      let
        val l = Symbol.generate NONE
        val r = Symbol.generate NONE
        fun toTuple e =
            nestedPair (map (fn (l,_) => Select (Lab l) e) selectList)
        fun compare x =
            Case1 x (PatTuple [PatVar l, PatVar r],
                     App (nestedCompare
                            (map (fn _ => Var_compare) selectList))
                         (Pair (toTuple (Var l), toTuple (Var r))))
      in
        fn c => Fun_nub compare c
      end

  fun tableIdToToy {db, lab, loc} =
      Loc loc (Select (Lab lab) (queryToToy db Unit))

  and tableToToy table =
      case table of
        TABLE_AS (tab, _, loc) =>
        tableToToy tab
      | TABLE (t as {loc,...}, _) =>
        Loc loc (Fun_map (fn x => Pair (x, x)) (tableIdToToy t))
      | TABLE_SUBQUERY (query, loc) =>
        Loc loc (Fun_map (fn x => Pair (x, x)) (queryToToy query UnitTuple))
      | TABLE_JOIN (tab1, INNER_JOIN (_, exp), tab2, loc) =>
        (Loc loc)
          (Fun_filter
             (fn x => (queryToToy exp) (flattenTable table x))
             (Fun_prod (tableToToy tab1, tableToToy tab2)))
      | TABLE_JOIN (tab1, CROSS_JOIN, tab2, loc) =>
        Loc loc (Fun_prod (tableToToy tab1, tableToToy tab2))
      | TABLE_JOIN (tab1, NATURAL_JOIN, tab2, loc) =>
        (Loc loc)
          (Fun_join (fn x => Join (Fst x, Snd x))
                    (tableToToy tab1, tableToToy tab2))

  and tableListToToy nil = Nil
    | tableListToToy (table :: tables) =
      foldl (fn (tab, z) => Fun_prod (z, tableToToy tab))
            (tableToToy table)
            tables

  and queryToToyOpt NONE = (fn c => c)
    | queryToToyOpt (SOME q) = queryToToy q

  and recordToToy fields =
      (fn c => map (fn (l, e) => (Lab l, queryToToy e c)) fields)

  and insertValueToToy default (lab, (NONE, loc)) =
      (Lab lab, Loc loc (Select (Lab lab) default))
    | insertValueToToy default (lab, (SOME e, loc)) =
      (Lab lab, Loc loc (queryToToy e UnitTuple))

  and insertRowToToy default labels (row, loc) =
      Record (ListPair.map (insertValueToToy default) (labels, row))

  and insertValuesToToy default labels values =
      List (map (insertRowToToy default labels) values)

  and groupByToToy NONE = (fn c => c)
    | groupByToToy (SOME {columns, representatives, groupBy=(groupBy, loc),
                          having}) =
      (fn c =>
          (Loc loc)
            ((havingToToy having)
               ((transpose (columns, representatives))
                  (Fun_groupBy
                     (fn x => nestedPair
                                (map (fn q => queryToToy q x) groupBy))
                     (nestedCompare (map (fn _ => Var_compare) groupBy))
                     c))))

  and havingToToy NONE = (fn c => c)
    | havingToToy (SOME (exp, loc)) =
      (fn c => Loc loc (Fun_filter (queryToToy exp) c))

  (* The toy program of each query construct is made under some context
   * denoted by "fn c".  For uniformity, even if it does not depend on
   * any context, it is with "fn c", where "c" is {}. *)
  and queryToToy query =
      case query of
        MLEXP id => (fn _ => LongVar id)
      | EMBED (id, QUERYty, loc) =>
        (fn c => Loc loc (App (Snd (Var id)) UnitTuple))
      | EMBED (id, _, loc) => (fn c => Loc loc (App (Snd (Var id)) c))
      | CONST (INT n, loc) => (fn _ => Loc loc (Const (A.INT n)))
      | CONST (WORD n, loc) => (fn _ => Loc loc (Const (A.WORD n)))
      | CONST (STRING s, loc) => (fn _ => Loc loc (Const (A.STRING s)))
      | CONST (REAL r, loc) => (fn _ => Loc loc (Const (A.REAL r)))
      | CONST (CHAR c, loc) => (fn _ => Loc loc (Const (A.CHAR c)))
      | CONST (BOOL true, loc) => (fn _ => Loc loc True)
      | CONST (BOOL false, loc) => (fn _ => Loc loc False) 
      | NULL loc => (fn _ => Loc loc None)
      | COLUMN1 (lab as (_, loc)) =>
        (fn c => Loc loc (Select (Lab lab) c))
      | COLUMN2 ((lab1, lab2), loc) =>
        (fn c => Loc loc (Select (Lab lab2) (Select (Lab lab1) c)))
      | OP1 (S.IS_NULL, exp, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_isSome (queryToToy exp c))))
      | OP1 (S.IS_NOT_NULL, exp, loc) =>
        (fn c => Loc loc (Fun_isSome (queryToToy exp c)))
      | OP1 (S.IS_TRUE, exp, loc) =>
        (fn c => Loc loc (Fun_is True3 (queryToToy exp c)))
      | OP1 (S.IS_NOT_TRUE, exp, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_is True3 (queryToToy exp c))))
      | OP1 (S.IS_FALSE, exp, loc) =>
        (fn c => Loc loc (Fun_is False3 (queryToToy exp c)))
      | OP1 (S.IS_NOT_FALSE, exp, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_is False3 (queryToToy exp c))))
      | OP1 (S.IS_UNKNOWN, exp, loc) =>
        (fn c => Loc loc (Some (Fun_is Unknown3 (queryToToy exp c))))
      | OP1 (S.IS_NOT_UNKNOWN, exp, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_is Unknown3 (queryToToy exp c))))
      | OP1 (S.NOT, exp, loc) =>
        (fn c => Loc loc (Fun_not3 (queryToToy exp c)))
      | OP2 (S.AND, e1, e2, loc) =>
        (fn c => Loc loc (Fun_and3 (queryToToy e1 c, queryToToy e2 c)))
      | OP2 (S.OR, e1, e2, loc) =>
        (fn c => Loc loc (Fun_or3 (queryToToy e1 c, queryToToy e2 c)))
      | EXISTS (query, loc) =>
        (fn c => Loc loc (Fun_fromBool (Fun_isNotEmpty (queryToToy query c))))
      | EXP_SUBQUERY (query, loc) =>
        (fn c => Loc loc (Fun_onlyOne (queryToToy query c)))
      | APP (f, x, loc) =>
        (fn c => Loc loc (App (queryToToy f c) (queryToToy x c)))
      | SQLAPP (_, f, arg, loc) =>
        (fn c => Loc loc (App (LongVar (prepend Name.structure_Op f))
                              (queryToToy arg c)))
      | APPOP2 (f, x, y, loc) =>
        (fn c => Loc loc (App (LongVar (prepend Name.structure_Op f))
                              (Pair (queryToToy x c, queryToToy y c))))
      | TUPLE (exps, loc) =>
        (fn c => Loc loc (Tuple (map (fn x => queryToToy x c) exps)))
      | WHERE (exp, loc) =>
        (fn c => Loc loc (Fun_filter (queryToToy exp) c))
      | FROM (tables, loc) =>
        (fn c =>
            (Loc loc)
              ((Fun_map (flattenTableList tables) (tableListToToy tables))))
      | ORDERBY (keys, loc) =>
        (fn c =>
            (Loc loc)
              (Fun_sortBy
                 (fn x => nestedPair (map (fn (q,_) => queryToToy q x) keys))
                 (nestedCompare (map (ascdescToToy o #2) keys))
                 c))
      | LIMIT {limit=(limit, loc), offset, loc = _} =>
        (case limit of
           NONE => (fn c => c)
         | SOME count =>
           (fn c => (Loc loc) (Fun_take (c, queryToToy count UnitTuple))))
        o (case offset of
             NONE => (fn c => c)
           | SOME (count, loc) =>
             (fn c => (Loc loc) (Fun_drop (c, queryToToy count UnitTuple))))
      | OFFSET {offset=(offset, _, loc), fetch, loc = _} =>
        (case fetch of
           NONE => (fn c => c)
         | SOME (_, NONE, _, loc) => (fn c => (Loc loc) (Fun_take (c, Int 1)))
         | SOME (_, SOME count, _, loc) =>
           (fn c => (Loc loc) (Fun_take (c, queryToToy count UnitTuple))))
        o (fn c => (Loc loc) (Fun_drop (c, queryToToy offset UnitTuple)))
      | SELECT (distinct, (selectList, loc1), loc2) =>
        (fn c =>
            (Loc loc2)
              ((distinctToToy selectList distinct)
                 (Fun_map
                    (fn x => Loc loc1 (Record (recordToToy selectList x)))
                    c)))
      | QUERY {select, from, whr, correlate, groupBy, orderBy, limit, loc} =>
        (fn c =>
            (Loc loc
             o queryToToyOpt limit
             o queryToToyOpt orderBy
             o queryToToy select
             o groupByToToy groupBy
             o queryToToyOpt whr
             o correlateJoin correlate c
             o queryToToy from)
              UnitTuple)
      | QUERY_COMMAND q => queryToToy q
      | INSERT_VAR {table, labels, values=id, loc} =>
        let
          val table = tableIdToToy table
          val default = Fun_hd table
          val pat = PatFlexRecord (map (fn l => (Lab l, PatVarLab l)) labels)
          val exp = Modify default (map (fn l => (Lab l, VarLab l)) labels)
          val values = Fun_map (fn x => Case1 x (pat, exp)) (LongVar id)
        in
          fn c => Loc loc (Ignore (Fun_append (table, values)))
        end
      | INSERT_VALUES {table, labels, values, loc} =>
        let
          val table = tableIdToToy table
          val default = Fun_hd table
          val rows = insertValuesToToy default labels values
        in
          fn c => Loc loc (Ignore (Fun_append (table, rows)))
        end
      | INSERT_SELECT {table, labels = NONE, query, loc} =>
        (fn c => Ignore (Fun_append (tableIdToToy table,
                                     queryToToy query UnitTuple)))
      | INSERT_SELECT {table, labels = SOME labs, query, loc} =>
        let
          val table = tableIdToToy table
          val default = Fun_hd table
          val pat = PatFlexRecord (map (fn l => (Lab l, PatVarLab l)) labs)
          val exp = Modify default (map (fn l => (Lab l, VarLab l)) labs)
        in
          fn c =>
             (Loc loc)
               (Ignore
                  ((Fun_map (fn x => Case1 x (pat, exp)))
                     (queryToToy query UnitTuple)))
        end
      | UPDATE {table as {lab, ...}, setList, whr, loc} =>
        (fn c =>
            (Loc loc)
              (Ignore
                 (Fun_map
                    (fn x =>
                        Modify
                          (Select (Lab lab) x)
                          (map (fn (l,e) => (Lab l, queryToToy e x)) setList))
                    ((queryToToyOpt whr)
                       (Fun_map
                          (fn x => Record [(Lab lab, x)])
                          (tableIdToToy table))))))
      | DELETE {table as {lab, ...}, whr, loc} =>
        (fn c =>
            (Loc loc)
              (Ignore
                 ((queryToToyOpt whr)
                    (Fun_map
                       (fn x => Record [(Lab lab, x)])
                       (tableIdToToy table)))))
      | BEGIN loc =>
        (fn c => Loc loc Unit)
      | COMMIT loc =>
        (fn c => Loc loc Unit)
      | ROLLBACK loc =>
        (fn c => Loc loc Unit)
      | SEQ (c1, c2, loc) =>
        (fn c => (Loc loc) (Seq (queryToToy c1 c, queryToToy c2 c)))

  fun ascdescToTerm NONE = None
    | ascdescToTerm (SOME S.ASC) = Some Con_ASC
    | ascdescToTerm (SOME S.DESC) = Some Con_DESC

  fun distinctToTerm NONE = None
    | distinctToTerm (SOME S.ALL) = Some Con_ALL
    | distinctToTerm (SOME S.DISTINCT) = Some Con_DISTINCT

  fun tableIdToTerm {db, lab, loc} =
      Loc loc (Con_TABLEID (queryToTerm db, lab))

  and tableToTerm table =
      case table of
        TABLE_AS (tab, label, loc) =>
        Loc loc (Con_TABLE_AS (tableToTerm tab, label))
      | TABLE (t as {loc,...}, _) =>
        Loc loc (Con_TABLE (tableIdToTerm t))
      | TABLE_SUBQUERY (query, loc) =>
        Loc loc (Con_TABLE_SUBQUERY (queryToTerm query))
      | TABLE_JOIN (tab1, INNER_JOIN ({inner}, exp), tab2, loc) =>
        (Loc loc)
          ((if inner then Con_INNERJOIN else Con_JOIN)
             (tableToTerm tab1, tableToTerm tab2, queryToTerm exp))
      | TABLE_JOIN (tab1, CROSS_JOIN, tab2, loc) =>
        Loc loc (Con_CROSSJOIN (tableToTerm tab1, tableToTerm tab2))
      | TABLE_JOIN (tab1, NATURAL_JOIN, tab2, loc) =>
        Loc loc (Con_NATURALJOIN (tableToTerm tab1, tableToTerm tab2))

  and whereToTerm NONE = None
    | whereToTerm (SOME whr) = Some (queryToTerm whr)

  and recordToTerm fields =
      map (fn (l, e) => (l, queryToTerm e)) fields

  and insertValueToTerm (NONE, loc) = Loc loc Con_DEFAULT
    | insertValueToTerm (SOME e, loc) = Loc loc (Con_VALUE (queryToTerm e))

  and groupByToTerm {columns, representatives, groupBy=(groupBy,loc), having} =
      Loc loc (Con_GROUPBY (map queryToTerm groupBy,
                            Option (Option.map havingToTerm having)))

  and havingToTerm (having, loc) =
      Loc loc (Con_HAVING (queryToTerm having))

  and queryToTerm query =
      case query of
        MLEXP (id as (_, _, loc)) =>
        Loc loc (Con_CONST (Fun_toSQL (LongVar id)))
      | EMBED (x, ty, loc) =>
        Loc loc (Fst (Var x))
      | CONST (INT n, loc) =>
        Loc loc (Con_CONST (Con_INT (A.INT n)))
      | CONST (WORD n, loc) =>
        Loc loc (Con_CONST (Con_WORD (A.WORD n)))
      | CONST (REAL s, loc) =>
        Loc loc (Con_CONST (Con_REAL (A.REAL s)))
      | CONST (STRING s, loc) =>
        Loc loc (Con_CONST (Con_STRING (A.STRING s)))
      | CONST (CHAR c, loc) =>
        Loc loc (Con_CONST (Con_CHAR (A.CHAR c)))
      | CONST (BOOL true, loc) =>
        Loc loc (Con_CONST (Con_BOOL True))
      | CONST (BOOL false, loc) =>
        Loc loc (Con_CONST (Con_BOOL False))
      | NULL loc =>
        Loc loc (Con_CONST Con_NULL)
      | COLUMN1 (lab as (_, loc)) =>
        Loc loc (Con_COLUMN1 lab)
      | COLUMN2 ((label1, label2), loc) =>
        Loc loc (Con_COLUMN2 (label1, label2))
      | OP1 (S.IS_NULL, query, loc) =>
        Loc loc (Con_IS (queryToTerm query, "NULL"))
      | OP1 (S.IS_NOT_NULL, query, loc) =>
        Loc loc (Con_IS_NOT (queryToTerm query, "NULL"))
      | OP1 (S.IS_TRUE, query, loc) =>
        Loc loc (Con_IS (queryToTerm query, "TRUE"))
      | OP1 (S.IS_NOT_TRUE, query, loc) =>
        Loc loc (Con_IS_NOT (queryToTerm query, "TRUE"))
      | OP1 (S.IS_FALSE, query, loc) =>
        Loc loc (Con_IS (queryToTerm query, "FALSE"))
      | OP1 (S.IS_NOT_FALSE, query, loc) =>
        Loc loc (Con_IS_NOT (queryToTerm query, "FALSE"))
      | OP1 (S.IS_UNKNOWN, query, loc) =>
        Loc loc (Con_IS (queryToTerm query, "UNKNOWN"))
      | OP1 (S.IS_NOT_UNKNOWN, query, loc) =>
        Loc loc (Con_IS_NOT (queryToTerm query, "UNKNOWN"))
      | OP1 (S.NOT, query, loc) =>
        Loc loc (Con_NOT (queryToTerm query))
      | OP2 (S.AND, q1, q2, loc) =>
        Loc loc (Con_AND (queryToTerm q1, queryToTerm q2))
      | OP2 (S.OR, q1, q2, loc) =>
        Loc loc (Con_OR (queryToTerm q1, queryToTerm q2))
      | EXISTS (query, loc) =>
        Loc loc (Con_EXISTS (queryToTerm query))
      | EXP_SUBQUERY (query, loc) =>
        Loc loc (Con_EXP_SUBQUERY (queryToTerm query))
      | APP (f, x, loc) =>
        (UserErrorUtils.enqueueError (LOC loc, F.AppInSQLQuery); Unit)
      | SQLAPP (true, _, arg, _) => queryToTerm arg
      | SQLAPP (false, funid, TUPLE (args, loc1), loc) =>
        (case Symbol.toString (#1 funid) of
           "~" => (UserErrorUtils.enqueueError (LOC loc, F.NegNotUnary); Unit)
         | _ => Loc loc (Con_FUNCALL (sqlFunName funid) (map queryToTerm args)))
      | SQLAPP (false, funid, arg, loc) =>
        (case Symbol.toString (#1 funid) of
           "~" => Loc loc (Con_UNARYOP "-" (queryToTerm arg))
         | _ => Loc loc (Con_FUNCALL (sqlFunName funid) [queryToTerm arg]))
      | APPOP2 (f, x, y, loc) =>
        Loc loc (Con_OP2 (queryToTerm x, f, queryToTerm y))
      | TUPLE (exps, loc) =>
        (UserErrorUtils.enqueueError (LOC loc, F.TupleInSQLQuery); Unit)
      | WHERE (exp, loc) =>
        Loc loc (Con_WHERE (queryToTerm exp))
      | FROM (tables, loc) =>
        Loc loc (Con_FROM (map tableToTerm tables))
      | ORDERBY (keys, loc) =>
        (Loc loc)
          (Con_ORDERBY
             (map (fn (exp, ascdesc) =>
                      (queryToTerm exp, ascdescToTerm ascdesc))
                  keys))
      | OFFSET {offset = (offset, rows, loc1), fetch, loc} =>
        (Loc loc)
          (Con_OFFSET
             {offset = (Loc loc1 (queryToTerm offset), rows),
              fetch =
                case fetch of
                  NONE => NONE
                | SOME (first, count, rows, loc) =>
                  SOME (first, Option.map (Loc loc o queryToTerm) count, rows)})
      | LIMIT {limit = (limit, loc1), offset, loc} =>
        (Loc loc)
          (Con_LIMIT
             {limit = Option.map (Loc loc1 o queryToTerm) limit,
              offset =
                case offset of
                  NONE => NONE
                | SOME (count, loc) => SOME (Loc loc (queryToTerm count))})
      | SELECT (distinct, (selectList, _), loc) =>
        Loc loc (Con_SELECT (distinctToTerm distinct, recordToTerm selectList))
      | QUERY {select, from, whr, correlate, groupBy, orderBy, limit, loc} =>
        (Loc loc)
          (Con_QUERY
             (queryToTerm select,
              queryToTerm from,
              Option.map queryToTerm whr,
              Option.map groupByToTerm groupBy,
              Option.map queryToTerm orderBy,
              Option.map queryToTerm limit))
      | QUERY_COMMAND q =>
        Con_QUERY_COMMAND (queryToTerm q)
      | INSERT_VAR {table, labels, values=id, loc} =>
        let
          val pat = PatRecord (map (fn l => (Lab l, PatVarLab l)) labels)
          fun fieldToTerm l = Con_VALUE (Con_CONST (Fun_toSQL (VarLab l)))
          val exp = List (map fieldToTerm labels)
        in
          (Loc loc)
            (Con_INSERT
               (tableIdToTerm table,
                SOME labels,
                Con_INSERT_VALUES
                  (Fun_map (fn x => Case1 x (pat, exp)) (LongVar id))))
        end
      | INSERT_VALUES {table, labels, values, loc} =>
        (Loc loc)
          (Con_INSERT
             (tableIdToTerm table,
              SOME labels,
              Con_INSERT_VALUES
                (List
                   (map (fn (l,loc) => List (map insertValueToTerm l))
                        values))))
      | INSERT_SELECT {table, labels, query, loc} =>
        (Loc loc)
          (Con_INSERT
             (tableIdToTerm table,
              labels,
              Con_INSERT_SELECT (queryToTerm query)))
      | UPDATE {table, setList, whr, loc} =>
        (Loc loc)
          (Con_UPDATE
             (tableIdToTerm table,
              recordToTerm setList,
              whereToTerm whr))
      | DELETE {table, whr, loc} =>
        (Loc loc)
          (Con_DELETE (tableIdToTerm table, whereToTerm whr))
      | BEGIN loc =>
        Loc loc Con_BEGIN
      | COMMIT loc =>
        Loc loc Con_COMMIT
      | ROLLBACK loc =>
        Loc loc Con_ROLLBACK
      | SEQ (c1, c2, loc) =>
        (Loc loc) (Con_SEQ (queryToTerm c1, queryToTerm c2))

  fun readResult select =
      case select of
        EMBED (x, ty, loc) =>
        Loc loc (Select (Label "3") (Var x))
      | QUERY {select, ...} => readResult select
      | QUERY_COMMAND query => readResult query
      | SEQ (x, y, _) => readResult y
      | SELECT (_, (l, loc), _) =>
        let
          fun fields c = mapi (fn (i, (l, _)) => (Lab l, Fun_fromSQL (c, i))) l
        in
          Loc loc (Fn1 (fn c => List [Record (fields c)]))
        end
      | _ => raise Bug.Bug "readResult"

  fun lastCommand (SEQ (x, y, _)) = lastCommand y
    | lastCommand x = x

  fun queryToExp query =
      let
        val term = queryToTerm query
        val toy = queryToToy query
      in
        case query of
          EMBED (x, ty, _) => Con (tyToConName ty) [Var x]
        | MLEXP _ => Con_EXPty (term, Fn1 toy)
        | CONST _ => Con_EXPty (term, Fn1 toy)
        | NULL _ => Con_EXPty (term, Fn1 toy)
        | COLUMN1 _ => Con_EXPty (term, Fn1 toy)
        | COLUMN2 _ => Con_EXPty (term, Fn1 toy)
        | OP1 _ => Con_EXPty (term, Fn1 toy)
        | OP2 _ => Con_EXPty (term, Fn1 toy)
        | APP _ => Con_EXPty (term, Fn1 toy)
        | SQLAPP _ => Con_EXPty (term, Fn1 toy)
        | APPOP2 _ => Con_EXPty (term, Fn1 toy)
        | TUPLE _ => Con_EXPty (term, Fn1 toy)
        | EXISTS _ => Con_EXPty (term, Fn1 toy)
        | EXP_SUBQUERY _ => Con_EXPty (term, Fn1 toy)
        | WHERE _ => Con_WHRty (term, Fn1 toy)
        | FROM _ => Con_FROMty (term, Fn1 toy)
        | ORDERBY _ => Con_ORDERBYty (term, Fn1 toy)
        | OFFSET _ => Con_OFFSETty (term, Fn1 toy)
        | LIMIT _ => Con_LIMITty (term, Fn1 toy)
        | SELECT _ => Con_SELECTty (term, Fn1 toy, readResult query)
        | QUERY _ => Con_QUERYty (term, Fn1 toy, readResult query)
        | QUERY_COMMAND _ =>
          Con_COMMANDty (term,
                         Fn1 (Fun_dummyCursor o toy),
                         Fn1 (Fun_newCursor (readResult query)))
        | INSERT_VALUES _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | INSERT_SELECT _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | INSERT_VAR _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | UPDATE _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | DELETE _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | BEGIN _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | COMMIT _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | ROLLBACK _ => Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
        | SEQ _ =>
          case lastCommand query of
            EMBED (x, COMMANDty, loc) =>
            Con_COMMANDty
              (term,
               Fn1 toy,
               Loc loc (Select (Label "3") (Var x)))
          | q as QUERY_COMMAND _ =>
            Con_COMMANDty
              (term,
               Fn1 (Fun_dummyCursor o toy),
               Fn1 (Fun_newCursor (readResult q)))
          | _ =>
            Con_COMMANDty (term, Fn1 toy, Var_closeCommand)
      end

  type elab_ret =
      {binds : {pat : P.pat, exp : P.exp, loc : A.loc} list,
       column2set: column2set}

  val emptyRet = {binds = nil, column2set = emptySet} : elab_ret

  fun merge (rets : elab_ret list) : elab_ret =
      {binds = List.concat (map #binds rets),
       column2set = foldl (fn (x,z) => union (#column2set x, z)) emptySet rets}

  fun removeLabels (ret:elab_ret, NONE) = ret
    | removeLabels ({binds, column2set}, SOME labset) : elab_ret =
      {binds = binds, column2set = difference (column2set, labset)}

  fun makeBind ({binds,...}:elab_ret) body =
      foldr (fn ({pat, exp, loc}, z) => Loc loc (Case1 (Exp exp) (Pat pat, z)))
            body
            binds

  type env =
      {
        elabAbsynExp : A.exp -> P.exp,
        (* if SOME, we are in a query with concrete FROMs in the context *)
        fromLabels : labset option
      }

  fun elabOpt f NONE = (emptyRet, NONE)
    | elabOpt f (SOME x) =
      let
        val (ret, y) = f x
      in
        (ret : elab_ret, SOME y)
      end

  fun elabList f l =
      let
        val (rets, queries) = ListPair.unzip (map f l)
      in
        (merge rets, queries)
      end

  fun toSQL (SQL q) = (emptyRet, q)
    | toSQL (ML (q as CONST _)) = (emptyRet, q)
    | toSQL (ML q) =
      let
        val x = Symbol.generate NONE
        val loc = getLoc q
      in
        ({binds = [{pat = PatVar x loc,
                    exp = (queryToToy q UnitTuple) loc,
                    loc = loc}],
          column2set = emptySet},
         MLEXP (nil, (x, loc), loc))
      end

  fun embed (ty, plexp, loc) =
      let
        val x = Symbol.generate NONE
        val plpat = PatCon (tyToConName ty) (x, loc) loc
      in
        ({binds = [{pat = plpat, exp = plexp, loc = loc}],
          column2set = emptySet},
         EMBED (x, ty, loc))
      end

  fun elabEmbed (env as {elabAbsynExp, ...}:env) ty (exp, loc) =
      case exp of
        A.EXPPAREN (exp, loc) => elabEmbed env ty (exp, loc)
      | A.EXPSQL (S.SQL (sql, loc)) =>
        let
          val (ty2, (ret1, query)) = elabSQL env sql
          val (ret2, query) =
              if ty = ty2
              then (emptyRet, query)
              else embed (ty, queryToExp query loc, loc)
        in
          (merge [ret1, ret2], query)
        end
      | _ =>
        embed (ty, elabAbsynExp exp, loc)

  and elabExp env exp =
      case exp of
        S.EXP_EMBED e =>
        let
          val (ret, q) = elabEmbed env EXPty e
        in
          (ret, SQL q)
        end
      | S.COLUMN1 (x, loc) =>
        (emptyRet, SQL (COLUMN1 x))
      | S.COLUMN2 (x, y, loc) =>
        ({binds = nil, column2set = singleton (x, y)},
         SQL (COLUMN2 ((x, y), loc)))
      | S.CONST (A.INT n, loc) => (emptyRet, ML (CONST (INT n, loc)))
      | S.CONST (A.WORD n, loc) => (emptyRet, ML (CONST (WORD n, loc)))
      | S.CONST (A.STRING s, loc) => (emptyRet, ML (CONST (STRING s, loc)))
      | S.CONST (A.REAL r, loc) => (emptyRet, ML (CONST (REAL r, loc)))
      | S.CONST (A.CHAR c, loc) => (emptyRet, ML (CONST (CHAR c, loc)))
      | S.CONST (A.UNITCONST, loc) =>
        let
          val x = Symbol.generate NONE
        in
          ({binds = [{pat = PatVar x loc, exp = Unit loc, loc = loc}],
            column2set = emptySet},
           ML (MLEXP (nil, (x, loc), loc)))
        end
      | S.NULL loc => (emptyRet, SQL (NULL loc))
      | S.TRUE loc => (emptyRet, ML (CONST (BOOL true, loc)))
      | S.FALSE loc => (emptyRet, ML (CONST (BOOL false, loc)))
      | S.ID (_, id, loc) =>
        (emptyRet, ML (MLEXP id))
      | S.OP1 (op1, e, loc) =>
        let
          val (ret, q) = elabExp env e
        in
          case q of
            ML q => (ret, ML (OP1 (op1, q, loc)))
          | SQL q => (ret, SQL (OP1 (op1, q, loc)))
        end
      | S.OP2 (op2, e1, e2, loc) =>
        let
          val (ret1, q1) = elabExp env e1
          val (ret2, q2) = elabExp env e2
        in
          case (q1, q2) of
            (ML q1, ML q2) => (merge [ret1, ret2], ML (OP2 (op2, q1, q2, loc)))
          | _ =>
            let
              val (ret3, q1) = toSQL q1
              val (ret4, q2) = toSQL q2
            in
              (merge [ret1, ret3, ret2, ret4], SQL (OP2 (op2, q1, q2, loc)))
            end
        end
      | S.APP (S.ID (false, longid as (nil, id, _), loc1), exp2, loc) =>
        let
          val (ret2, q2) = elabExp env exp2
        in
          case q2 of
            ML q2 =>
            (ret2, ML (APP (MLEXP longid, q2, loc)))
          | SQL q2 =>
            (ret2, SQL (SQLAPP (false, id, q2, loc)))
        end
      | S.APP (exp1, exp2, loc) =>
        let
          val (ret1, q1) = elabExp env exp1
          val (ret2, q2) = elabExp env exp2
        in
          case (q1, q2) of
            (ML q1, ML q2) =>
            (merge [ret1, ret2], ML (APP (q1, q2, loc)))
          | _ =>
            let
              val (ret3, q1) = toSQL q1
              val (ret4, q2) = toSQL q2
            in
              (merge [ret1, ret3, ret2, ret4], SQL (APP (q1, q2, loc)))
            end
        end
      | S.INFIX (exp1, vid, exp2, loc) =>
        let
          val (ret1, q1) = elabExp env exp1
          val (ret2, q2) = elabExp env exp2
        in
          case (q1, q2) of
            (ML q1, ML q2) =>
            (merge [ret1, ret2],
             ML (APP (MLEXP (nil, vid, #2 vid),
                      TUPLE ([q1, q2], loc),
                      loc)))
          | _ =>
            let
              val (ret3, q1) = toSQL q1
              val (ret4, q2) = toSQL q2
            in
              (merge [ret1, ret3, ret2, ret4],
               SQL (APPOP2 (vid, q1, q2, loc)))
            end
        end
      | S.CAST (vid, exp, loc) =>
        let
          val (ret1, q1) = elabExp env exp
          val (ret2, q1) = toSQL q1
        in
          (merge [ret1, ret2], SQL (SQLAPP (true, vid, q1, loc)))
        end
      | S.TUPLE (exps, loc) =>
        let
          val exps = map (elabExp env) exps
        in
          if List.all (fn (_, ML _) => true | (_, SQL _) => false) exps
          then
            (merge (map #1 exps),
             ML (TUPLE (map (fn (_, ML x) => x
                              | (_, SQL _) => raise Bug.Bug "elabExp: TUPLE")
                            exps,
                        loc)))
          else
            let
              val exps = map (fn (r, q) => (r, toSQL q)) exps
              val exps = map (fn (r1, (r2, q)) => (merge [r1, r2], q)) exps
              val (rets, exps) = ListPair.unzip exps
            in
              (merge rets, SQL (TUPLE (exps, loc)))
            end
        end
      | S.KWEXP (_, S.EXISTS (query, loc), _) =>
        let
          val (ret, q) = elabQuery env query
        in
          (ret, SQL (EXISTS (q, loc)))
        end
      | S.EXP_SUBQUERY (_, query, loc) =>
        let
          val (ret, q) = elabQuery env query
        in
          (ret, SQL (EXP_SUBQUERY (q, loc)))
        end
      | S.PAREN (exp, _) => elabExp env exp

  and elabExpToQuery env exp =
      let
        val (ret1, q) = elabExp env exp
        val (ret2, q) = toSQL q
      in
        (merge [ret1, ret2], q)
      end

  and elabWhere env (S.WHERE (exp, loc)) =
      let
        val (ret, q) = elabExpToQuery env exp
      in
        (ret, WHERE (q, loc))
      end
    | elabWhere env (S.WHERE_EMBED exploc) =
      elabEmbed env WHRty exploc

  and elabTableId env ((db as (_, loc1), lab, loc) : S.table_selector) =
      let
        val exploc = (A.EXPID (false, (nil, db, loc1), loc1), loc1)
        val (ret, db) = elabEmbed env DBty exploc
      in
        (ret, {db = db, lab = lab, loc = loc})
      end

  and elabTable env table =
      case table of
        S.TABLE_AS (S.TABLE t, lab, loc) =>
        let
          val (ret, q) = elabTableId env t
        in
          (false, (ret, TABLE_AS (TABLE (q, NONE), lab, loc)))
        end
      | S.TABLE (t as (_, lab, _)) =>
        let
          val (ret, q) = elabTableId env t
        in
          (false, (ret, TABLE (q, SOME lab)))
        end
      | S.TABLE_SUBQUERY (_, query, loc) =>
        let
          val (ret, q) = elabQuery env query
        in
          (false, (ret, TABLE_SUBQUERY (q, loc)))
        end
      | S.TABLE_AS (tab, lab, loc) =>
        let
          val (hasCrossJoin, (ret, tab)) = elabTable env tab
        in
          if hasCrossJoin
          then UserErrorUtils.enqueueError (LOC loc, F.CrossJoinName (#1 lab))
          else ();
          (hasCrossJoin, (ret, TABLE_AS (tab, lab, loc)))
        end
      | S.TABLE_INNER_JOIN (tab1, inner, tab2, onExp, loc) =>
        let
          val (hasCrossJoin1, (ret1, tab1)) = elabTable env tab1
          val (hasCrossJoin2, (ret2, tab2)) = elabTable env tab2
          val (ret3, q) = elabExpToQuery env onExp
        in
          (true,
           (merge [ret1, ret2, ret3],
            TABLE_JOIN (tab1, INNER_JOIN ({inner = inner}, q), tab2, loc)))
        end
      | S.TABLE_CROSS_JOIN (tab1, tab2, loc) =>
        let
          val (hasCrossJoin1, (ret1, tab1)) = elabTable env tab1
          val (hasCrossJoin2, (ret2, tab2)) = elabTable env tab2
        in
          (true,
           (merge [ret1, ret2],
            TABLE_JOIN (tab1, CROSS_JOIN, tab2, loc)))
        end
      | S.TABLE_NATURAL_JOIN (tab1, tab2, loc) =>
        let
          val (hasCrossJoin1, (ret1, tab1)) = elabTable env tab1
          val (hasCrossJoin2, (ret2, tab2)) = elabTable env tab2
        in
          if hasCrossJoin1 orelse hasCrossJoin2
          then UserErrorUtils.enqueueError (LOC loc, F.UnnaturalNaturalJoin)
          else ();
          (false,
           (merge [ret1, ret2],
            TABLE_JOIN (tab1, NATURAL_JOIN, tab2, loc)))
        end
      | S.TABLE_PAREN (tab, _) => elabTable env tab

  and elabTableList env tables =
      elabList (#2 o elabTable env) tables

  and elabFrom env (S.FROM (tables, loc)) =
      let
        val (ret, tables) = elabTableList env tables
        val labels = tableListNames tables
        val _ = UserErrorUtils.checkRecordLabelDuplication
                  (fn (label, _) => label)
                  labels
                  (LOC loc)
                  F.DuplicateSQLFromLabel
      in
        (SOME (listToLabset labels), (ret, FROM (tables, loc)))
      end
    | elabFrom env (S.FROM_EMBED exploc) =
      (NONE, elabEmbed env FROMty exploc)

  and elabOrderBy env (S.ORDERBY (keys, loc)) =
      let
        val (ret, keys) =
            elabList
              (fn ((b,e),a) => (b,(e,a)))
              (map (fn (exp, ascdesc, _) => (elabExpToQuery env exp, ascdesc))
                   keys)
      in
        (ret, ORDERBY (keys, loc))
      end
    | elabOrderBy env (S.ORDERBY_EMBED exploc) =
      elabEmbed env ORDERBYty exploc

  and elabOffset env (S.OFFSET ((offset, rows, loc1), fetch, loc)) =
      let
        val (ret1, offset) = elabExpToQuery env offset
        val (ret2, fetch) =
            elabOpt
              (fn (first, count, rows, loc) =>
                  let
                    val (ret, count) = elabOpt (elabExpToQuery env) count
                  in
                    (ret, (first, count, rows, loc))
                  end)
              fetch
      in
        (merge [ret1, ret2],
         OFFSET {offset = (offset, rows, loc1), fetch = fetch, loc = loc})
      end
    | elabOffset env (S.OFFSET_EMBED exploc) =
      elabEmbed env OFFSETty exploc

  and elabLimit env (S.LIMIT ((limit, loc1), offset, loc)) =
      let
        val (ret1, limit) = elabOpt (elabExpToQuery env) limit
        val (ret2, offset) =
            elabOpt
              (fn (offset, loc) =>
                  let
                    val (ret, offset) = elabExpToQuery env offset
                  in
                    (ret, (offset, loc))
                  end)
              offset
      in
        (merge [ret1, ret2],
         LIMIT {limit = (limit, loc1), offset = offset, loc = loc})
      end
    | elabLimit env (S.LIMIT_EMBED exploc) =
      elabEmbed env LIMITty exploc

  and elabLimitOrOffset env (S.LIMIT_CLAUSE limit) = elabLimit env limit
    | elabLimitOrOffset env (S.OFFSET_CLAUSE offset) = elabOffset env offset

  and elabSelect env (S.SELECT (distinct, (selectList, loc1), loc2)) =
      let
        val (ret, selectList) =
            elabList
              (fn (l,(r,e)) => (r,(l,e)))
              (map (fn (i, (e, NONE, _)) =>
                       ((i, AbsynUtils.sqlExpLoc e), elabExpToQuery env e)
                     | (i, (e, SOME l, _)) => (l, elabExpToQuery env e))
                   (RecordLabel.tupleList selectList))
        val _ = UserErrorUtils.checkRecordLabelDuplication
                  (fn ((label, _), _) => label)
                  selectList
                  (LOC loc1)
                  F.DuplicateSQLSelectLabel
      in
        (ret, SELECT (distinct, (selectList, loc1), loc2))
      end
    | elabSelect env (S.SELECT_EMBED exploc) =
      elabEmbed env SELECTty exploc

  and elabGroupBy env (S.GROUPBY ((groupBy, loc), having, _)) =
      let
        val (ret1, keys) =
            case groupBy of
              [S.CONST (A.UNITCONST, _)] => (emptyRet, nil)
            | _ => elabList (elabExpToQuery env) groupBy
        val (ret2, having) = elabOpt (elabHaving env) having
      in
        (merge [ret1, ret2], {groupBy = (keys, loc), having = having})
      end

  and elabHaving env ((exp, loc) : A.exp S.having_clause) =
      let
        val (ret, q) = elabExpToQuery env exp
      in
        (ret, (q, loc))
      end

  and setupGroupBy {outerLabels, columns} {groupBy as (keys, _), having} =
      let
        (* columns specified in GROUP BY refer to representatives *)
        val representatives =
            listToSet
              (List.mapPartial (fn COLUMN2 (x,_) => SOME x | _ => NONE) keys)
        (* columns provided by outer FROMs also refer to representatives *)
        val representatives =
            union (representatives, intersect (columns, outerLabels))
      in
        {representatives = representatives,
         columns = columns,
         groupBy = groupBy,
         having = having} : group_by
      end

  and elabQuery env (S.QUERY (select, from, whr, groupBy, orderBy, limit,
                              loc)) =
      let
        val (fromLabels, (ret2, from)) = elabFrom env from
        val (innerLabels, outerLabels) =
            case (fromLabels, #fromLabels env) of
              (SOME inner, SOME outer) =>
              (SOME (unionLabset (inner, outer)),
               SOME (differenceLabset (outer, inner)))
            | x => x
        val correlate =
            case (fromLabels, outerLabels) of
              (SOME inner, SOME outer) =>
              SOME {inner = RecordLabel.Map.listItemsi inner,
                    outer = RecordLabel.Map.listItemsi outer}
            | _ => NONE

        val env = env # {fromLabels = innerLabels}
        val (ret1, select) = elabSelect env select
        val (ret3, whr) = elabOpt (elabWhere env) whr
        val (ret4, groupBy) = elabOpt (elabGroupBy env) groupBy
        val (ret5, orderBy) = elabOpt (elabOrderBy env) orderBy
        val (ret6, limit) = elabOpt (elabLimitOrOffset env) limit

        val groupBy =
            Option.map
              (setupGroupBy
                 {columns = union (#column2set ret1, #column2set ret2),
                  outerLabels = outerLabels})
              groupBy
      in
        (removeLabels (merge [ret1, ret2, ret3, ret4, ret5, ret6], fromLabels),
         QUERY {select = select,
                from = from,
                correlate = correlate,
                whr = whr,
                groupBy = groupBy,
                orderBy = orderBy,
                limit = limit,
                loc = loc})
      end
    | elabQuery env (S.QUERY_EMBED exploc) =
      elabEmbed env QUERYty exploc

  and elabInsertValue env (S.VALUE exp) =
      let
        val (ret, q) = elabExpToQuery env exp
      in
        (ret, (SOME q, AbsynUtils.sqlExpLoc exp))
      end
    | elabInsertValue env (S.DEFAULT loc) = (emptyRet, (NONE, loc))

  and elabInsertRow env numLabels (row, loc:S.loc) =
      (if length row = numLabels
       then ()
       else UserErrorUtils.enqueueError (LOC loc, F.NumberOfSQLInsertLabel);
       (elabList (elabInsertValue env) row, loc))

  and elabInsertValues env numLabels values =
      elabList
        (fn ((b,r),l) => (b,(r,l)))
        (map (elabInsertRow env numLabels) values)

  and elabSQLcon env sqlcon =
      case sqlcon of
        S.SEL select => (SELECTty, elabSelect env select)
      | S.FRM from => (FROMty, #2 (elabFrom env from))
      | S.WHR whr => (WHRty, elabWhere env whr)
      | S.ORD orderBy => (ORDERBYty, elabOrderBy env orderBy)
      | S.OFF offset => (OFFSETty, elabOffset env offset)
      | S.LMT limit => (LIMITty, elabLimit env limit)
      | S.QRY query => (QUERYty, elabQuery env query)
      | S.INSERT_LABELED (tid, (labels, loc), values, loc2) =>
        let
          val (ret1, table) = elabTableId env tid
          val _ = UserErrorUtils.checkRecordLabelDuplication
                    (fn (x, _) => x)
                    labels
                    (LOC loc)
                    F.DuplicateSQLInsertLabel
        in
          case values of
            S.INSERT_SELECT query =>
            let
              val (ret2, q) = elabQuery env query
            in
              (COMMANDty,
               (merge [ret1, ret2],
                INSERT_SELECT {table = table,
                               labels = SOME labels,
                               query = q,
                               loc = loc2}))
            end
          | S.INSERT_VALUES (values, _) =>
            let
              val (ret2, q) = elabInsertValues env (length labels) values
            in
              (COMMANDty,
               (merge [ret1, ret2],
                INSERT_VALUES {table = table,
                               labels = labels,
                               values = q,
                               loc = loc2}))
            end
          | S.INSERT_VAR ((_, id, _), loc) =>
            (COMMANDty,
             (ret1,
              INSERT_VAR {table = table,
                          labels = labels,
                          values = id,
                          loc = loc}))
        end
      | S.INSERT_NOLABEL (tid, query, loc) =>
        let
          val (ret1, table) = elabTableId env tid
          val (ret2, q) = elabQuery env query
        in
          (COMMANDty,
           (merge [ret1, ret2],
            INSERT_SELECT {table = table, labels = NONE, query = q, loc = loc}))
        end
      | S.UPDATE (tid, (sets, loc), whr, loc2) =>
        let
          val (ret1, table) = elabTableId env tid
          val _ = UserErrorUtils.checkRecordLabelDuplication
                    (fn ((label, _), _, _) => label)
                    sets
                    (LOC loc)
                    F.DuplicateSQLSetLabel
          val (ret2, sets) =
              elabList
                (fn (l,(b,e)) => (b,(l,e)))
                (map (fn (l,e,_) => (l, elabExpToQuery env e)) sets)
          val (ret3, whr) =
              elabOpt (elabWhere env) whr
        in
          (COMMANDty,
           (merge [ret1, ret2, ret3],
            UPDATE {table = table, setList = sets, whr = whr, loc = loc2}))
        end
      | S.DELETE (tid, whr, loc) =>
        let
          val (ret1, table) = elabTableId env tid
          val (ret2, whr) = elabOpt (elabWhere env) whr
        in
          (COMMANDty,
           (merge [ret1, ret2],
            DELETE {table = table, whr = whr, loc = loc}))
        end
      | S.BEGIN loc => (COMMANDty, (emptyRet, BEGIN loc))
      | S.COMMIT loc => (COMMANDty, (emptyRet, COMMIT loc))
      | S.ROLLBACK loc => (COMMANDty, (emptyRet, ROLLBACK loc))

  and elabSQL env sql =
      case sql of
        S.CON (_, sqlcon, _) => elabSQLcon env sqlcon
      | S.EXP exp => (EXPty, elabExpToQuery env exp)
      | S.SEQ (seq, _) => (COMMANDty, elabSeq env seq)
      | S.BODYPAREN (sql, _) => elabSQL env sql

  and elabSeq env nil = raise Bug.Bug "elabSeq: nil"
    | elabSeq env [S.STEP (_, sql, _)] =
      (case elabSQLcon env sql of
         (QUERYty, (ret, query)) => (ret, QUERY_COMMAND query)
       | (_, (ret, query)) => (ret, query))
    | elabSeq env [S.STEP_EMBED exploc] = elabEmbed env COMMANDty exploc
    | elabSeq env (S.STEP (_, sql, loc) :: seq) =
      let
        val (ty, (ret1, query1)) = elabSQLcon env sql
        val query1 =
            case ty of
              QUERYty => QUERY_COMMAND query1
            | _ => query1
        val (ret2, query2) = elabSeq env seq
      in
        (merge [ret1, ret2], SEQ (query1, query2, loc))
      end
    | elabSeq env (S.STEP_EMBED exploc :: seq) =
      let
        val (ret1, query1) = elabEmbed env COMMANDty exploc
        val (ret2, query2) = elabSeq env seq
      in
        (merge [ret1, ret2], SEQ (query1, query2, #2 exploc))
      end

  fun sqlFn (pat, exp) =
      let
        val t = Tyvar (Symbol.generate (SOME (Symbol.intern "'sql")))
        val x = Symbol.generate NONE
        val patTy = Ty_db (TyWild, TyID t)
        val expTy = Ty_command (TyWild, TyID t)
      in
        Fn1 (fn y =>
                Let [t]
                    (PatVar x,
                     Fn (PatTyped (Pat pat, patTy), Typed (exp, expTy)))
                    (Fun_sqleval (Var x) y))
      end

  fun elabSqlexp (context as {elabPat, env}) sqlexp =
      case sqlexp of
        S.SQL (sql, loc) : (A.exp,A.pat,A.ty) S.top  =>
        let
          val (ty, (ret, query)) = elabSQL env sql
        in
          makeBind ret (queryToExp query) loc
        end
      | S.SQLFN (pat, sql, loc) : (A.exp,A.pat,A.ty) S.top  =>
        let
          val pat = elabPat pat
          val (ty, (ret, query)) = elabSQL env sql
          val query =
              case ty of
                QUERYty => QUERY_COMMAND query
              | _ => query
          val bodyExp = queryToExp query
        in
          sqlFn (pat, makeBind ret bodyExp) loc
        end
      | S.SQLSERVER (exp, schema, loc) =>
        Fun_sqlserver
          (case exp of
             NONE => String ""
           | SOME exp => Exp (#elabAbsynExp env exp),
           Exp (P.EXPSQLSCHEMA (ExVar Name.fun_ty loc,
                                ElaborateTy.elabMonoTy schema,
                                LOC loc)))
          loc

  fun elaborateExp {elabExp, elabPat} sqlexp =
      let
        val env = {elabAbsynExp = elabExp, fromLabels = NONE}
      in
        elabSqlexp {elabPat = elabPat, env = env} sqlexp
      end

end
