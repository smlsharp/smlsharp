(**
 * ElaboratorSQL.sml
 * @copyright (c) 2009-2016, Tohoku University.
 * @author UENO Katsuhiro
 * @author ENDO Hiroki
 *)

structure ElaborateSQL =
struct

  structure A = Absyn
  structure S = AbsynSQL
  structure P = PatternCalc
  structure E = ElaborateErrorSQL

  val SQLPrim = "SMLSharp_SQL_Prim"
  structure Name =
  struct
    val structure_Op = [SQLPrim, "Op"]
    val con_cons = ["::"]
    val con_nil = ["nil"]
    val con_SOME = [SQLPrim, "Option", "SOME"]
    val con_NONE = [SQLPrim, "Option", "NONE"]
    val con_true = [SQLPrim, "Bool", "true"]
    val con_false = [SQLPrim, "Bool", "false"]
    val con_True = [SQLPrim, "Bool3", "True"]
    val con_False = [SQLPrim, "Bool3", "False"]
    val con_Unknown = [SQLPrim, "Bool3", "Unknown"]
    val ty_db = [SQLPrim, "db"]
    val ty_command = [SQLPrim, "command"]
    val fun_isSome = [SQLPrim, "Option", "isSome"]
    val fun_not3 = [SQLPrim, "Bool3", "not3"]
    val fun_and3 = [SQLPrim, "Bool3", "and3"]
    val fun_or3 = [SQLPrim, "Bool3", "or3"]
    val fun_fromBool = [SQLPrim, "Bool3", "fromBool"]
    val fun_isTrue = [SQLPrim, "Bool3", "isTrue"]
    val fun_is = [SQLPrim, "Bool3", "is"]
    val fun_map = [SQLPrim, "List", "map"]
    val fun_filter = [SQLPrim, "List", "filter"]
    val fun_append = [SQLPrim, "List", "@"]
    val fun_hd = [SQLPrim, "List", "hd"]
    val fun_take = [SQLPrim, "List", "take"]
    val fun_drop = [SQLPrim, "List", "drop"]
    val fun_onlyOne = [SQLPrim, "List2", "onlyOne"]
    val fun_isNotEmpty = [SQLPrim, "List2", "isNotEmpty"]
    val fun_prod = [SQLPrim, "List2", "prod"]
    val fun_join = [SQLPrim, "List2", "join"]
    val fun_nub = [SQLPrim, "List2", "nub"]
    val fun_sortBy = [SQLPrim, "List2", "sortBy"]
    val fun_groupBy = [SQLPrim, "List2", "groupBy"]
    val fun_compare = [SQLPrim, "compare"]
    val fun_comparePair = [SQLPrim, "General2", "comparePair"]
    val fun_reverseOrder = [SQLPrim, "General2", "reverseOrder"]
    val fun_fromSQL = [SQLPrim, "fromSQL"]
    val fun_wrap = [SQLPrim, "wrap"]
    val fun_unwrapInt = [SQLPrim, "unwrapInt"]
    val fun_unwrapReal = [SQLPrim, "unwrapReal"]
    val fun_unwrapWord = [SQLPrim, "unwrapWord"]
    val fun_unwrapString = [SQLPrim, "unwrapString"]
    val fun_unwrapChar = [SQLPrim, "unwrapChar"]
    val fun_unwrapBool = [SQLPrim, "unwrapBool"]
    val fun_queryCommand = [SQLPrim, "queryCommand"]
    val fun_sqlserver = [SQLPrim, "sqlserver"]
    val fun_sqleval = [SQLPrim, "sqleval"]
    val fun_closeRes = [SQLPrim, "closeRes"]
    val fun_ty = [SQLPrim, "ty"]
    val con_CONST = [SQLPrim, "Ast", "CONST"]
    val con_INT = [SQLPrim, "Ast", "INT"]
    val con_WORD = [SQLPrim, "Ast", "WORD"]
    val con_REAL = [SQLPrim, "Ast", "REAL"]
    val con_STRING = [SQLPrim, "Ast", "STRING"]
    val con_CHAR = [SQLPrim, "Ast", "CHAR"]
    val con_BOOL = [SQLPrim, "Ast", "BOOL"]
    val con_LITERAL = [SQLPrim, "Ast", "LITERAL"]
    val con_COLUMN1 = [SQLPrim, "Ast", "COLUMN1"]
    val con_COLUMN2 = [SQLPrim, "Ast", "COLUMN2"]
    val con_EXISTS = [SQLPrim, "Ast", "EXISTS"]
    val con_IS = [SQLPrim, "Ast", "IS"]
    val con_IS_NOT = [SQLPrim, "Ast", "IS_NOT"]
    val con_NOT = [SQLPrim, "Ast", "NOT"]
    val con_AND = [SQLPrim, "Ast", "AND"]
    val con_OR = [SQLPrim, "Ast", "OR"]
    val con_EXP_SUBQUERY = [SQLPrim, "Ast", "EXP_SUBQUERY"]
    val con_WHERE = [SQLPrim, "Ast", "WHERE"]
    val con_TABLEID = [SQLPrim, "Ast", "TABLEID"]
    val con_TABLE = [SQLPrim, "Ast", "TABLE"]
    val con_TABLE_SUBQUERY = [SQLPrim, "Ast", "TABLE_SUBQUERY"]
    val con_TABLE_AS = [SQLPrim, "Ast", "TABLE_AS"]
    val con_JOIN = [SQLPrim, "Ast", "JOIN"]
    val con_INNERJOIN = [SQLPrim, "Ast", "INNERJOIN"]
    val con_CROSSJOIN = [SQLPrim, "Ast", "CROSSJOIN"]
    val con_NATURALJOIN = [SQLPrim, "Ast", "NATURALJOIN"]
    val con_FROM = [SQLPrim, "Ast", "FROM"]
    val con_ASC = [SQLPrim, "Ast", "ASC"]
    val con_DESC = [SQLPrim, "Ast", "DESC"]
    val con_ORDERBY = [SQLPrim, "Ast", "ORDERBY"]
    val con_OFFSET = [SQLPrim, "Ast", "OFFSET"]
    val con_LIMIT = [SQLPrim, "Ast", "LIMIT"]
    val con_GROUPBY = [SQLPrim, "Ast", "GROUPBY"]
    val con_HAVING = [SQLPrim, "Ast", "HAVING"]
    val con_ALL = [SQLPrim, "Ast", "ALL"]
    val con_DISTINCT = [SQLPrim, "Ast", "DISTINCT"]
    val con_SELECT = [SQLPrim, "Ast", "SELECT"]
    val con_QUERY = [SQLPrim, "Ast", "QUERY"]
    val con_DEFAULT = [SQLPrim, "Ast", "DEFAULT"]
    val con_VALUE = [SQLPrim, "Ast", "VALUE"]
    val con_INSERT = [SQLPrim, "Ast", "INSERT"]
    val con_INSERT_VALUES = [SQLPrim, "Ast", "INSERT_VALUES"]
    val con_INSERT_SELECT = [SQLPrim, "Ast", "INSERT_SELECT"]
    val con_UPDATE = [SQLPrim, "Ast", "UPDATE"]
    val con_DELETE = [SQLPrim, "Ast", "DELETE"]
    val con_BEGIN = [SQLPrim, "Ast", "BEGIN"]
    val con_COMMIT = [SQLPrim, "Ast", "COMMIT"]
    val con_ROLLBACK = [SQLPrim, "Ast", "ROLLBACK"]
    val con_EXPty = [SQLPrim, "EXPty"]
    val con_WHRty = [SQLPrim, "WHRty"]
    val con_FROMty = [SQLPrim, "FROMty"]
    val con_ORDERBYty = [SQLPrim, "ORDERBYty"]
    val con_OFFSETty = [SQLPrim, "OFFSETty"]
    val con_LIMITty = [SQLPrim, "LIMITty"]
    val con_SELECTty = [SQLPrim, "SELECTty"]
    val con_QUERYty = [SQLPrim, "QUERYty"]
    val con_COMMANDty = [SQLPrim, "COMMANDty"]
    val con_DBty = [SQLPrim, "DBty"]
  end

  fun mapi f l =
      let fun map f i nil = nil
            | map f i (h::t) = f (i,h) :: map f (i+1) t
      in map f 0 l
      end

  fun recordLabelToSymbol label loc =
      Symbol.mkSymbol (RecordLabel.toString label) loc

  fun Ty ty (_:S.loc) = ty : A.ty

  fun Tyvar x : A.tvar =
      {symbol = x, isEq = false}

  fun TyWild loc =
      A.TYWILD loc

  fun TyID tv loc =
      A.TYID (tv, loc)

  fun TyCon args name loc =
      A.TYCONSTRUCT
        (map (fn arg => arg loc) args, Symbol.mkLongsymbol name loc, loc)

  fun TyFun (ty1, ty2) loc =
      A.TYFUN (ty1 loc, ty2 loc, loc)

  fun Pat x (_:P.loc) = x : P.plpat

  fun PatWild loc =
      P.PLPATWILD loc

  fun PatUnit loc =
      P.PLPATCONSTANT (A.UNITCONST, loc)

  fun PatVar symbol (_:P.loc) =
      P.PLPATID [symbol]

  fun PatVarLabel label loc =
      P.PLPATID [recordLabelToSymbol label loc]

  fun PatFlexRecord fields loc =
      P.PLPATRECORD (true, map (fn (l, pat) => (l, pat loc)) fields, loc)

  fun PatRecord fields loc =
      P.PLPATRECORD (false, map (fn (l, pat) => (l, pat loc)) fields, loc)

  fun PatTuple pats = PatRecord (RecordLabel.tupleList pats)

  fun PatAs (var, pat) loc =
      P.PLPATLAYERED (var, NONE, pat loc, loc)

  fun PatAsLabel (label, pat) loc =
      P.PLPATLAYERED (recordLabelToSymbol label loc, NONE, pat loc, loc)

  fun PatCon name symbol loc =
      P.PLPATCONSTRUCT (P.PLPATID (Symbol.mkLongsymbol name loc),
                        P.PLPATID [symbol], loc)

  fun PatTyped (pat, ty) loc =
      P.PLPATTYPED (pat loc, ty loc, loc)

  fun Exp x (_:P.loc) = x : P.plexp

  fun Loc (loc:P.loc) x = fn (_:P.loc) => x loc

  fun Var symbol (_:P.loc) =
      P.PLVAR [symbol]

  fun VarLabel label loc =
      P.PLVAR [recordLabelToSymbol label loc]

  fun ExVar name loc =
      P.PLVAR (Symbol.mkLongsymbol name loc)

  fun Case1 exp1 (pat, exp2) loc =
      P.PLCASEM ([exp1 loc], [([pat loc], exp2 loc)], P.MATCH, loc)

  fun Fn (pat, exp) loc =
      P.PLFNM ([([pat loc], exp loc)], loc)

  fun Fn1 f =
      let
        val x = Symbol.generate ()
      in
        Fn (PatVar x, f (Var x))
      end

  fun Let tyvars (pat, exp) exp2 loc =
      P.PLLET ([P.PDVAL (map (fn x => (x, A.UNIV(nil,loc))) tyvars,
                         [(pat loc, exp loc)], loc)],
               [exp2 loc], loc)

  fun Unit loc =
      P.PLCONSTANT (A.UNITCONST, loc)

  fun Int n loc =
      P.PLCONSTANT
        (A.INT (Int.toLarge n), loc)

  fun String s loc =
      P.PLCONSTANT (A.STRING s, loc)

  fun LabelString label =
      String (RecordLabel.toString label)

  fun App exp1 exp2 loc =
      P.PLAPPM (exp1 loc, [exp2 loc], loc)

  fun Record fields =
      fn loc => P.PLRECORD (map (fn (l, e) => (l, e loc)) fields, loc)

  fun Tuple exps = Record (RecordLabel.tupleList exps)

  fun UnitTuple loc =
      Tuple [] loc

  fun Pair (x, y) =
      Tuple [x, y]

  fun Select label exp loc =
      P.PLSELECT (label, exp loc, loc)

  fun Fst exp =
      Select (RecordLabel.fromString "1") exp

  fun Snd exp =
      Select (RecordLabel.fromString "2") exp

  fun Modify exp fields loc =
      P.PLRECORD_UPDATE (exp loc, map (fn (l, e) => (l, e loc)) fields, loc)

  fun Typed (exp, ty) loc =
      P.PLTYPED (exp loc, ty loc, loc)

  fun Ignore exp loc =
      P.PLSEQ ([exp loc, Unit loc], loc)

  fun Join (exp1, exp2) loc =
      P.PLJOIN (true, exp1 loc, exp2 loc, loc)

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

  fun Ty_db (toyTy, connTy) =
      TyCon [toyTy, connTy] Name.ty_db

  fun Ty_command (toyTy, connTy) =
      TyCon [toyTy, connTy] Name.ty_command

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

  fun Fun_wrap x =
      App (ExVar Name.fun_wrap) x

  fun Fun_unwrapInt exp =
      App (ExVar Name.fun_unwrapInt) exp

  fun Fun_unwrapReal exp =
      App (ExVar Name.fun_unwrapReal) exp

  fun Fun_unwrapWord exp =
      App (ExVar Name.fun_unwrapWord) exp

  fun Fun_unwrapString exp =
      App (ExVar Name.fun_unwrapString) exp

  fun Fun_unwrapChar exp =
      App (ExVar Name.fun_unwrapChar) exp

  fun Fun_unwrapBool exp =
      App (ExVar Name.fun_unwrapBool) exp

  fun Fun_queryCommand select =
      App (ExVar Name.fun_queryCommand) select

  fun Fun_sqlserver (serv, schema) =
      App (ExVar Name.fun_sqlserver) (Tuple [serv, schema])

  fun Fun_sqleval query x =
      App (App (ExVar Name.fun_sqleval) query) x

  fun Var_closeRes loc =
      ExVar Name.fun_closeRes loc

  fun Con_CONST x =
      Con Name.con_CONST [x]

  fun Con_INT const =
      Con Name.con_INT [fn loc => P.PLCONSTANT (const, loc)]

  fun Con_WORD const =
      Con Name.con_WORD [fn loc => P.PLCONSTANT (const, loc)]

  fun Con_REAL const =
      Con Name.con_REAL [fn loc => P.PLCONSTANT (const, loc)]

  fun Con_STRING const =
      Con Name.con_STRING [fn loc => P.PLCONSTANT (const, loc)]

  fun Con_CHAR const =
      Con Name.con_CHAR [fn loc => P.PLCONSTANT (const, loc)]

  fun Con_BOOL x =
      Con Name.con_BOOL [x]

  fun Con_LITERAL x =
      Con Name.con_LITERAL [String x]

  fun Con_COLUMN1 label =
      Con Name.con_COLUMN1 [LabelString label]

  fun Con_COLUMN2 (label1, label2) =
      Con Name.con_COLUMN2 [LabelString label1, LabelString label2]

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

  fun Con_WHERE exp =
      Con Name.con_WHERE [exp]

  fun Con_TABLEID (db, label) =
      Con Name.con_TABLEID [db, LabelString label]

  fun Con_TABLE table =
      Con Name.con_TABLE [table]

  fun Con_TABLE_SUBQUERY query =
      Con Name.con_TABLE_SUBQUERY [query]

  fun Con_TABLE_AS (table, label) =
      Con Name.con_TABLE_AS [table, LabelString label]

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
             [(RecordLabel.fromString "offset", Pair (offset, String rows)),
              (RecordLabel.fromString "fetch",
               case fetch of
                 NONE => None
               | SOME (first, count, rows) =>
                 Tuple [String first, Option count, String rows])]]

  fun Con_LIMIT {limit, offset} =
      Con Name.con_LIMIT
          [Record
             [(RecordLabel.fromString "limit", Option limit),
              (RecordLabel.fromString "offset", Option offset)]]

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
           List (map (fn (l, e) => Pair (LabelString l, e)) selectList)]

  fun Con_QUERY (select, from, whr, groupby, orderby, limit) =
      Con Name.con_QUERY [select, from,
                          Option whr, Option groupby,
                          Option orderby, Option limit]

  fun Con_DEFAULT loc =
      Con Name.con_DEFAULT [] loc

  fun Con_VALUE exp =
      Con Name.con_VALUE [exp]

  fun Con_INSERT (tableId, labels, values) =
      Con Name.con_INSERT
          [tableId,
           Option (Option.map (List o map LabelString) labels),
           values]

  fun Con_INSERT_VALUES values =
      Con Name.con_INSERT_VALUES [List (map List values)]

  fun Con_INSERT_SELECT select =
      Con Name.con_INSERT_SELECT [select]

  fun Con_UPDATE (tableId, setList, whr) =
      Con Name.con_UPDATE
          [tableId,
           List (map (fn (l, e) => Pair (LabelString l, e)) setList),
           whr]

  fun Con_DELETE (tableId, whr) =
      Con Name.con_DELETE [tableId, whr]

  fun Con_BEGIN loc =
      Con Name.con_BEGIN [] loc

  fun Con_COMMIT loc =
      Con Name.con_COMMIT [] loc

  fun Con_ROLLBACK loc =
      Con Name.con_ROLLBACK [] loc

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

  type column2set = RecordLabel.Set.set RecordLabel.Map.map

  val emptySet = RecordLabel.Map.empty : column2set

  fun singleton (k, l) =
      RecordLabel.Map.singleton (k, RecordLabel.Set.singleton l)

  fun union (set1, set2) =
      RecordLabel.Map.mergeWith
        (fn (SOME x, SOME y) => SOME (RecordLabel.Set.union (x, y))
          | (SOME x, NONE) => SOME x
          | (NONE, SOME y) => SOME y
          | (NONE, NONE) => NONE)
        (set1, set2)

  fun listToSet l =
      foldl union emptySet (map singleton l)

  fun member (set, (k, l)) =
      case RecordLabel.Map.find (set, k) of
        NONE => false
      | SOME set => RecordLabel.Set.member (set, l)

  fun listItems set =
      map (fn (k, s) => (k, RecordLabel.Set.listItems s))
          (RecordLabel.Map.listItemsi set)

  fun filterLabels (set, NONE) = emptySet
    | filterLabels (set, SOME labels) =
      RecordLabel.Map.filteri
        (fn (k, s) => RecordLabel.Set.member (labels, k))
        set

  (* SQL query constructs.
   * For simplicity, we define a single all-in-one datatype rather than
   * a datatype for each syntactic category. *)
  datatype query =
      EMBED of S.symbol * ty * S.loc
    | CONST of {ast : S.loc -> P.plexp, toy : S.loc -> P.plexp, loc : S.loc}
    | COLUMN1 of S.label * S.loc
    | COLUMN2 of (S.label * S.label) * S.loc
    | EXISTS of query * S.loc
    | OP1 of S.op1 * query * S.loc
    | OP2 of S.op2 * query * query * S.loc
    | EXP_SUBQUERY of query * S.loc
    | WHERE of query * S.loc
    | FROM of table list * S.loc
    | ORDERBY of (query * S.asc_desc option) list * S.loc
    | OFFSET of {offset : query * string * S.loc,
                 fetch : (string * query option * string * S.loc) option}
    | LIMIT of {limit : query option * S.loc,
                offset : (query * S.loc) option}
    | SELECT of S.distinct option * ((S.label * query) list * S.loc) * S.loc
    | QUERY of {select : query,
                from : query,
                correlate : {outer : S.label list, inner : S.label list} option,
                whr : query option,
                groupBy : groupBy option,
                orderBy : query option,
                limit : query option,
                loc : S.loc}
    | INSERT_VALUES of {table : table_selector,
                        labels : S.label list,
                        values : ((query option * S.loc) list * S.loc) list,
                        loc : S.loc}
    | INSERT_SELECT of {table : table_selector,
                        labels : S.label list option,
                        query : query,
                        loc : S.loc}
    | UPDATE of {table : table_selector,
                 setList : (S.label * query) list,
                 whr : query option,
                 loc : S.loc}
    | DELETE of {table : table_selector, whr : query option, loc : S.loc}
    | BEGIN of S.loc
    | COMMIT of S.loc
    | ROLLBACK of S.loc

  (* table expressions *)
  and table =
      TABLE of table_selector * S.label option
    | TABLE_AS of table * S.label * S.loc
    | TABLE_SUBQUERY of query * S.loc
    | TABLE_JOIN of table * join * table * S.loc

  (* table join operators *)
  and join =
      INNER_JOIN of {inner : bool} * query
    | CROSS_JOIN
    | NATURAL_JOIN

  (* table selector in the given database *)
  withtype table_selector =
      {db : query, label : S.label, loc : S.loc}

  and groupBy =
      {columns : column2set,
       representatives : column2set,
       groupBy : query list * S.loc,
       having : (query * S.loc) option}

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
        SOME (PatTuple [getOpt (pat1, PatWild), getOpt (pat2, PatWild)])
    fun name (label, NONE) = SOME (PatVarLabel label)
      | name (label, SOME pat) = SOME (PatAsLabel (label, pat))
    fun join (pair1, pair2) =
        (pair (pair pair1, pair pair2), NONE)
  in

  fun tableToPatPair table =
      case table of
        TABLE (_, NONE) => (NONE, NONE)
      | TABLE (_, SOME label) => (NONE, SOME (PatVarLabel label))
      | TABLE_SUBQUERY _ => (NONE, NONE)
      | TABLE_JOIN (tab1, _, tab2, _) =>
        join (tableToPatPair tab1, tableToPatPair tab2)
      | TABLE_AS (tab, label, _) =>
        let
          val (pat1, pat2) = tableToPatPair tab
        in
          (pat1, name (label, pat2))
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
               Record (map (fn l => (l, VarLabel l)) (tableNames table)))

  fun flattenTableList tables x =
      Case1 x (tableListToPat tables,
               Record (map (fn l => (l, VarLabel l)) (tableListNames tables)))

  fun correlateJoin NONE outerRecord = (fn x => x)
    | correlateJoin (SOME {outer, inner}) outerRecord =
      Fun_map
        (fn innerRecord =>
            Case1
              (Pair (outerRecord, innerRecord))
              (PatTuple
                 [PatFlexRecord (map (fn l => (l, PatVarLabel l)) outer),
                  PatRecord (map (fn l => (l, PatVarLabel l)) inner)],
               Record (map (fn l => (l, VarLabel l)) (outer @ inner))))

  fun column2setToRecord f set =
      let
        fun inner k set =
            RecordLabel.Set.foldr (fn (l,z) => (l, f (k, l)) :: z) nil set
        fun outer map =
            RecordLabel.Map.foldri
              (fn (k,s,z) => (k, Record (inner k s)) :: z) nil map
      in
        Record (outer set)
      end

  fun transpose (columns, representatives) =
      Fun_map
        (fn equiv =>
            column2setToRecord
              (fn (k,l) =>
                  if member (representatives, (k, l))
                  then Select l (Select k (Fun_hd equiv))
                  else Fun_map (fn x => Select l (Select k x)) equiv)
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
        val l = Symbol.generate ()
        val r = Symbol.generate ()
        fun toTuple e = nestedPair (map (fn (l,_) => Select l e) selectList)
        fun compare x =
            Case1 x (PatTuple [PatVar l, PatVar r],
                     App (nestedCompare
                            (map (fn _ => Var_compare) selectList))
                         (Pair (toTuple (Var l), toTuple (Var r))))
      in
        fn c => Fun_nub compare c
      end

  fun tableIdToToy {db, label, loc} =
      Loc loc (Select label (queryToToy db Unit))

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
      (fn c => map (fn (l, e) => (l, queryToToy e c)) fields)

  and insertValueToToy default (l, (NONE, loc)) =
      (l, Loc loc (Select l default))
    | insertValueToToy default (l, (SOME e, loc)) =
      (l, Loc loc (queryToToy e UnitTuple))

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
                     (fn x => nestedPair (map (fn q => queryToToy q x) groupBy))
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
        EMBED (x, ty, loc) =>
        (fn c => Loc loc (App (Snd (Var x)) c))
      | CONST {ast, toy, loc} =>
        (fn c => Loc loc toy)
      | COLUMN1 (label, loc) =>
        (fn c => Loc loc (Select label c))
      | COLUMN2 ((label1, label2), loc) =>
        (fn c => Loc loc (Select label2 (Select label1 c)))
      | EXISTS (query, loc) =>
        (fn c => Loc loc (Fun_fromBool (Fun_isNotEmpty (queryToToy query c))))
      | OP1 (S.IS_NULL, query, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_isSome (queryToToy query c))))
      | OP1 (S.IS_NOT_NULL, query, loc) =>
        (fn c => Loc loc (Fun_isSome (queryToToy query c)))
      | OP1 (S.IS_TRUE, query, loc) =>
        (fn c => Loc loc (Fun_is True3 (queryToToy query c)))
      | OP1 (S.IS_NOT_TRUE, query, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_is True3 (queryToToy query c))))
      | OP1 (S.IS_FALSE, query, loc) =>
        (fn c => Loc loc (Fun_is False3 (queryToToy query c)))
      | OP1 (S.IS_NOT_FALSE, query, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_is False3 (queryToToy query c))))
      | OP1 (S.IS_UNKNOWN, query, loc) =>
        (fn c => Loc loc (Some (Fun_is Unknown3 (queryToToy query c))))
      | OP1 (S.IS_NOT_UNKNOWN, query, loc) =>
        (fn c => Loc loc (Fun_not3 (Fun_is Unknown3 (queryToToy query c))))
      | OP1 (S.NOT, query, loc) =>
        (fn c => Loc loc (Fun_not3 (queryToToy query c)))
      | OP2 (S.AND, q1, q2, loc) =>
        (fn c => Loc loc (Fun_and3 (queryToToy q1 c, queryToToy q2 c)))
      | OP2 (S.OR, q1, q2, loc) =>
        (fn c => Loc loc (Fun_or3 (queryToToy q1 c, queryToToy q2 c)))
      | EXP_SUBQUERY (query as EMBED _, loc) =>
        (fn c => Loc loc (Fun_onlyOne (queryToToy query UnitTuple)))
      | EXP_SUBQUERY (query, loc) =>
        (fn c => Loc loc (Fun_onlyOne (queryToToy query c)))
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
      | LIMIT {limit=(limit,loc), offset} =>
        (case limit of
           NONE => (fn c => c)
         | SOME count =>
           (fn c => (Loc loc) (Fun_take (c, queryToToy count UnitTuple))))
        o (case offset of
             NONE => (fn c => c)
           | SOME (count, loc) =>
             (fn c => (Loc loc) (Fun_drop (c, queryToToy count UnitTuple))))
      | OFFSET {offset=(offset, _, loc), fetch} =>
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
          val pat = PatFlexRecord (map (fn l => (l, PatVarLabel l)) labs)
          val exp = Modify default (map (fn l => (l, VarLabel l)) labs)
        in
          fn c =>
             (Loc loc)
               (Ignore
                  ((Fun_map (fn x => Case1 x (pat, exp)))
                     (queryToToy query UnitTuple)))
        end
      | UPDATE {table as {label, ...}, setList, whr, loc} =>
        (fn c =>
            (Loc loc)
              (Ignore
                 (Fun_map
                    (fn x => Modify
                               (Select label x)
                               (map (fn (l,e) => (l, queryToToy e x)) setList))
                    ((queryToToyOpt whr)
                       (Fun_map
                          (fn x => Record [(label, x)])
                          (tableIdToToy table))))))
      | DELETE {table as {label, ...}, whr, loc} =>
        (fn c =>
            (Loc loc)
              (Ignore
                 ((queryToToyOpt whr)
                    (Fun_map
                       (fn x => Record [(label, x)])
                       (tableIdToToy table)))))
      | BEGIN loc =>
        (fn c => Loc loc Unit)
      | COMMIT loc =>
        (fn c => Loc loc Unit)
      | ROLLBACK loc =>
        (fn c => Loc loc Unit)

  fun ascdescToTerm NONE = None
    | ascdescToTerm (SOME S.ASC) = Some Con_ASC
    | ascdescToTerm (SOME S.DESC) = Some Con_DESC

  fun distinctToTerm NONE = None
    | distinctToTerm (SOME S.ALL) = Some Con_ALL
    | distinctToTerm (SOME S.DISTINCT) = Some Con_DISTINCT

  fun tableIdToTerm {db, label, loc} =
      Loc loc (Con_TABLEID (queryToTerm db, label))

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
        EMBED (x, ty, loc) =>
        Loc loc (Fst (Var x))
      | CONST {ast, toy, loc} =>
        Loc loc ast
      | COLUMN1 (label, loc) =>
        Loc loc (Con_COLUMN1 label)
      | COLUMN2 ((label1, label2), loc) =>
        Loc loc (Con_COLUMN2 (label1, label2))
      | EXISTS (query, loc) =>
        Loc loc (Con_EXISTS (queryToTerm query))
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
      | EXP_SUBQUERY (query, loc) =>
        Loc loc (Con_EXP_SUBQUERY (queryToTerm query))
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
      | OFFSET {offset = (offset, rows, loc), fetch} =>
        (Loc loc)
          (Con_OFFSET
             {offset = (Loc loc (queryToTerm offset), rows),
              fetch =
                case fetch of
                  NONE => NONE
                | SOME (first, count, rows, loc) =>
                  SOME (first, Option.map (Loc loc o queryToTerm) count, rows)})
      | LIMIT {limit = (limit, loc), offset} =>
        (Loc loc)
          (Con_LIMIT
             {limit = Option.map (Loc loc o queryToTerm) limit,
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
      | INSERT_VALUES {table, labels, values, loc} =>
        (Loc loc)
          (Con_INSERT
             (tableIdToTerm table,
              SOME labels,
              Con_INSERT_VALUES
                (map (fn (l,loc) => map insertValueToTerm l) values)))
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

  fun readResult select =
      case select of
        EMBED (x, ty, loc) =>
        Loc loc (Select (RecordLabel.fromString "3") (Var x))
      | QUERY {select, ...} => readResult select
      | SELECT (_, (l, loc), _) =>
        let
          fun fields c = mapi (fn (i, (l, _)) => (l, Fun_fromSQL (c, i))) l
        in
          Loc loc (Fn1 (fn c => List [Record (fields c)]))
        end
      | _ => raise Bug.Bug "readResult"

  fun queryToExp query =
      let
        val term = queryToTerm query
        val toy = Fn1 (queryToToy query)
      in
        case query of
          EMBED (x, ty, _) => Con (tyToConName ty) [Var x]
        | CONST _ => Con_EXPty (term, toy)
        | COLUMN1 _ => Con_EXPty (term, toy)
        | COLUMN2 _ => Con_EXPty (term, toy)
        | EXISTS _ => Con_EXPty (term, toy)
        | OP1 _ => Con_EXPty (term, toy)
        | OP2 _ => Con_EXPty (term, toy)
        | EXP_SUBQUERY _ => Con_EXPty (term, toy)
        | WHERE _ => Con_WHRty (term, toy)
        | FROM _ => Con_FROMty (term, toy)
        | ORDERBY _ => Con_ORDERBYty (term, toy)
        | OFFSET _ => Con_OFFSETty (term, toy)
        | LIMIT _ => Con_LIMITty (term, toy)
        | SELECT _ => Con_SELECTty (term, toy, readResult query)
        | QUERY _ => Con_QUERYty (term, toy, readResult query)
        | INSERT_VALUES _ => Con_COMMANDty (term, toy, Var_closeRes)
        | INSERT_SELECT _ => Con_COMMANDty (term, toy, Var_closeRes)
        | UPDATE _ => Con_COMMANDty (term, toy, Var_closeRes)
        | DELETE _ => Con_COMMANDty (term, toy, Var_closeRes)
        | BEGIN _ => Con_COMMANDty (term, toy, Var_closeRes)
        | COMMIT _ => Con_COMMANDty (term, toy, Var_closeRes)
        | ROLLBACK _ => Con_COMMANDty (term, toy, Var_closeRes)
      end

  type elab_ret =
      {binds : {pat : P.plpat, exp : P.plexp, loc : P.loc} list,
       column2set: column2set}

  val emptyRet = {binds = nil, column2set = emptySet} : elab_ret

  fun merge (rets : elab_ret list) : elab_ret =
      {binds = List.concat (map #binds rets),
       column2set = foldl (fn (x,z) => union (#column2set x, z)) emptySet rets}

  fun removeLabels (ret:elab_ret, NONE) = ret
    | removeLabels ({binds, column2set}, SOME labels) : elab_ret =
      {binds = binds,
       column2set = RecordLabel.Map.filteri
                      (fn (k, s) => not (RecordLabel.Set.member (labels, k)))
                      column2set}

  fun makeBind ({binds,...}:elab_ret) body =
      foldr (fn ({pat, exp, loc}, z) => Loc loc (Case1 (Exp exp) (Pat pat, z)))
            body
            binds

  type context =
      {
        (* if SOME, we are in a query with concrete FROMs in the context *)
        fromLabels : RecordLabel.Set.set option,
        (* Which context we are currently in *)
        ty : ty,
        (* the set of free COLUMN2 in the given (or siblings) expression *)
        column2setRet : RecordLabel.Set.set RecordLabel.Map.map ref
      }

  type env =
      {elabAbsynExp : context option -> A.exp -> P.plexp,
       fromLabels : RecordLabel.Set.set option}

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

  fun embed (ty, plexp, loc) =
      let
        val x = Symbol.generate ()
        val plpat = PatCon (tyToConName ty) x loc
      in
        ({binds = [{pat = plpat, exp = plexp, loc = loc}],
          column2set = emptySet},
         EMBED (x, ty, loc))
      end

  fun elabEmbed (env as {elabAbsynExp, ...}:env) ty (exp, loc) =
      case exp of
        A.EXPAPP ([atexp], loc) => elabEmbed env ty (atexp, loc)
      | A.EXPSQL (S.SQL sql, loc) =>
        let
          val (ty2, (ret1, query)) = elabSQL env (SOME ty) (sql, loc)
          val (ret2, query) =
              if ty = ty2
              then (emptyRet, query)
              else embed (ty, queryToExp query loc, loc)
        in
          (merge [ret1, ret2], query)
        end
      | _ =>
        let
          val r = ref emptySet
          val c = {fromLabels = #fromLabels env, ty = ty, column2setRet = r}
          val abexp =
              A.EXPLET
                ([A.DECOPEN ([Symbol.mkLongsymbol Name.structure_Op loc], loc),
                  A.DECINFIX ("5", [Symbol.mkSymbol "like" loc,
                                    Symbol.mkSymbol "||" loc], loc), 
                  A.DECINFIX ("7", [Symbol.mkSymbol "%" loc], loc),
                  A.DECNONFIX ([Symbol.mkSymbol "mod" loc], loc)],
                 [A.EXPAPP ([exp], loc)],
                 loc)
          val plexp = elabAbsynExp (SOME c) abexp
          val ret1 = {binds = nil, column2set = !r}
          val (ret2, query) = embed (ty, plexp, loc)
        in
          (merge [ret1, ret2], query)
        end

  and elabExp env exp =
      case exp of
        S.EXP e => elabEmbed env EXPty e
      | S.COLUMN1 (x, loc) =>
        (emptyRet, COLUMN1 (x, loc))
      | S.COLUMN2 (x, loc) =>
        ({binds = nil, column2set = singleton x}, COLUMN2 (x, loc))
      | S.OP1 (op1, e, loc) =>
        let
          val (ret, q) = elabExp env e
        in
          (ret, OP1 (op1, q, loc))
        end
      | S.OP2 (op2, e1, e2, loc) =>
        let
          val (ret1, q1) = elabExp env e1
          val (ret2, q2) = elabExp env e2
        in
          (merge [ret1, ret2], OP2 (op2, q1, q2, loc))
        end
      | S.EXISTS (query, loc) =>
        let
          val (ret, q) = elabQuery env query
        in
          (ret, EXISTS (q, loc))
        end
      | S.CONST (c, loc) =>
        let
          fun const (con, unwrap, loc) =
              CONST {ast = Con_CONST (con c),
                     toy = unwrap (Fun_wrap (Exp (P.PLCONSTANT (c, loc)))),
                     loc = loc}
        in
          case c of
            A.INT _ =>
            (emptyRet, const (Con_INT, Fun_unwrapInt, loc))
          | A.WORD _ =>
            (emptyRet, const (Con_WORD, Fun_unwrapWord, loc))
          | A.STRING _ =>
            (emptyRet, const (Con_STRING, Fun_unwrapString, loc))
          | A.REAL _ =>
            (emptyRet, const (Con_REAL, Fun_unwrapReal, loc))
          | A.CHAR _ =>
            (emptyRet, const (Con_CHAR, Fun_unwrapChar, loc))
          | A.UNITCONST =>
            elabEmbed env EXPty (A.EXPCONSTANT (c, loc), loc)
        end
      | S.NULL loc =>
        (emptyRet, CONST {ast = Con_LITERAL "NULL", toy = None, loc = loc})
      | S.TRUE loc =>
        (emptyRet, CONST {ast = Con_CONST (Con_BOOL True),
                          toy = Fun_unwrapBool (Fun_wrap True),
                          loc = loc})
      | S.FALSE loc =>
        (emptyRet, CONST {ast = Con_CONST (Con_BOOL False),
                          toy = Fun_unwrapBool (Fun_wrap False),
                          loc = loc})

  and elabWhere env (S.WHERE (exp, loc)) =
      let
        val (ret, q) = elabExp env exp
      in
        (ret, WHERE (q, loc))
      end

  and elabWhereClause env (S.EMBED exploc) = elabEmbed env WHRty exploc
    | elabWhereClause env (S.CLAUSE clause) = elabWhere env clause

  and elabJoin env join =
      case join of
        S.CROSS_JOIN => (emptyRet, CROSS_JOIN)
      | S.NATURAL_JOIN => (emptyRet, NATURAL_JOIN)
      | S.INNER_JOIN (b, exp) =>
        let
          val (ret, q) = elabExp env exp
        in
          (ret, INNER_JOIN (b, q))
        end

  and elabTableId env ({db, label, loc}:S.table_selector) =
      let
        val exploc = (A.EXPID [db], Symbol.symbolToLoc db)
        val (ret, db) = elabEmbed env DBty exploc
      in
        (ret, {db = db, label = label, loc = loc})
      end

  and elabTable env table =
      case table of
        S.TABLE_AS (S.TABLE t, label, loc) =>
        let
          val (ret, q) = elabTableId env t
        in
          (false, (ret, TABLE_AS (TABLE (q, NONE), label, loc)))
        end
      | S.TABLE t =>
        let
          val (ret, q) = elabTableId env t
        in
          (false, (ret, TABLE (q, SOME (#label t))))
        end
      | S.TABLE_SUBQUERY (query, loc) =>
        let
          val (ret, q) = elabQuery env query
        in
          (false, (ret, TABLE_SUBQUERY (q, loc)))
        end
      | S.TABLE_AS (tab, label, loc) =>
        let
          val (hasCrossJoin, (ret, tab)) = elabTable env tab
        in
          if hasCrossJoin
          then UserErrorUtils.enqueueError (loc, E.CrossJoinName label)
          else ();
          (hasCrossJoin, (ret, TABLE_AS (tab, label, loc)))
        end
      | S.TABLE_JOIN (tab1, join, tab2, loc) =>
        let
          val (hasCrossJoin1, (ret1, tab1)) = elabTable env tab1
          val (hasCrossJoin2, (ret2, tab2)) = elabTable env tab2
          val (ret3, join) = elabJoin env join
          val isNatural = case join of NATURAL_JOIN => true | _ => false
        in
          if isNatural andalso (hasCrossJoin1 orelse hasCrossJoin2)
          then UserErrorUtils.enqueueError (loc, E.UnnaturalNaturalJoin)
          else ();
          (not isNatural,
           (merge [ret1, ret2, ret3],
            TABLE_JOIN (tab1, join, tab2, loc)))
        end

  and elabTableList env tables =
      elabList (#2 o elabTable env) tables

  and elabFrom env (S.FROM (tables, loc)) =
      let
        val (ret, tables) = elabTableList env tables
        val labels = tableListNames tables
        val _ = UserErrorUtils.checkRecordLabelDuplication
                  (fn x => x)
                  labels
                  loc
                  E.DuplicateSQLFromLabel
      in
        (SOME (RecordLabel.Set.fromList labels), (ret, FROM (tables, loc)))
      end

  and elabFromClause env (S.EMBED exploc) = (NONE, elabEmbed env FROMty exploc)
    | elabFromClause env (S.CLAUSE clause) = elabFrom env clause

  and elabOrderBy env (S.ORDER_BY (keys, loc)) =
      let
        val (ret, keys) =
            elabList
              (fn ((b,e),a) => (b,(e,a)))
              (map (fn (exp, ascdesc) => (elabExp env exp, ascdesc)) keys)
      in
        (ret, ORDERBY (keys, loc))
      end

  and elabOrderByClause env (S.EMBED exploc) = elabEmbed env ORDERBYty exploc
    | elabOrderByClause env (S.CLAUSE clause) = elabOrderBy env clause

  and elabOffset env (S.OFFSET {offset = (offset, rows, loc), fetch}) =
      let
        val (ret1, offset) = elabExp env offset
        val (ret2, fetch) =
            elabOpt
              (fn (first, count, rows, loc) =>
                  let
                    val (ret, count) = elabOpt (elabExp env) count
                  in
                    (ret, (first, count, rows, loc))
                  end)
              fetch
      in
        (merge [ret1, ret2],
         OFFSET {offset = (offset, rows, loc), fetch = fetch})
      end

  and elabLimit env (S.LIMIT {limit = (limit, loc), offset}) =
      let
        val (ret1, limit) = elabOpt (elabExp env) limit
        val (ret2, offset) =
            elabOpt
              (fn (offset, loc) =>
                  let
                    val (ret, offset) = elabExp env offset
                  in
                    (ret, (offset, loc))
                  end)
              offset
      in
        (merge [ret1, ret2],
         LIMIT {limit = (limit, loc), offset = offset})
      end

  and elabLimitOrOffsetClause env (S.LIMIT_CLAUSE (S.EMBED exploc)) =
      elabEmbed env LIMITty exploc
    | elabLimitOrOffsetClause env (S.OFFSET_CLAUSE (S.EMBED exploc)) =
      elabEmbed env OFFSETty exploc
    | elabLimitOrOffsetClause env (S.LIMIT_CLAUSE (S.CLAUSE limit)) =
      elabLimit env limit
    | elabLimitOrOffsetClause env (S.OFFSET_CLAUSE (S.CLAUSE offset)) =
      elabOffset env offset

  and elabSelect env (S.SELECT (distinct, (selectList, loc1), loc2)) =
      let
        val (ret, selectList) =
            elabList
              (fn (l,(r,e)) => (r,(l,e)))
              (map (fn (i,(k,e)) => (getOpt (k, i), elabExp env e))
                   (RecordLabel.tupleList selectList))
        val _ = UserErrorUtils.checkRecordLabelDuplication
                  #1
                  selectList
                  loc1
                  E.DuplicateSQLSelectLabel
      in
        (ret, SELECT (distinct, (selectList, loc1), loc2))
      end

  and elabSelectClause env (S.EMBED exp) = elabEmbed env SELECTty exp
    | elabSelectClause env (S.CLAUSE clause) = elabSelect env clause

  and elabGroupByClause env (S.GROUP_BY ((groupBy, loc), having)) =
      let
        val (ret1, keys) =
            case groupBy of
              [S.CONST (A.UNITCONST, _)] => (emptyRet, nil)
            | _ => elabList (elabExp env) groupBy
        val (ret2, having) = elabOpt (elabHavingClause env) having
      in
        (merge [ret1, ret2], {groupBy = (keys, loc), having = having})
      end

  and elabHavingClause env (S.HAVING (exp, loc)) =
      let
        val (ret, q) = elabExp env exp
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
            union (representatives, filterLabels (columns, outerLabels))
      in
        {representatives = representatives,
         columns = columns,
         groupBy = groupBy,
         having = having} : groupBy
      end

  and elabQuery env (S.QUERY (select, from, whr, groupBy, orderBy, limit,
                              loc)) =
      let
        val (fromLabels, (ret2, from)) = elabFromClause env from
        val (innerLabels, outerLabels) =
            case (fromLabels, #fromLabels env) of
              (SOME inner, SOME outer) =>
              (SOME (RecordLabel.Set.union (inner, outer)),
               SOME (RecordLabel.Set.difference (outer, inner)))
            | x => x
        val correlate =
            case (fromLabels, outerLabels) of
              (SOME inner, SOME outer) =>
              SOME {inner = RecordLabel.Set.listItems inner,
                    outer = RecordLabel.Set.listItems outer}
            | _ => NONE

        val env = env # {fromLabels = innerLabels}
        val (ret1, select) = elabSelectClause env select
        val (ret3, whr) = elabOpt (elabWhereClause env) whr
        val (ret4, groupBy) = elabOpt (elabGroupByClause env) groupBy
        val (ret5, orderBy) = elabOpt (elabOrderByClause env) orderBy
        val (ret6, limit) = elabOpt (elabLimitOrOffsetClause env) limit

        val groupBy =
            Option.map
              (setupGroupBy
                 {columns = union (#column2set ret1, #column2set ret2),
                  outerLabels = outerLabels})
              groupBy
      in
        (removeLabels (merge [ret1, ret2, ret3, ret4, ret5, ret6],
                       fromLabels),
         QUERY {select = select,
                from = from,
                correlate = correlate,
                whr = whr,
                groupBy = groupBy,
                orderBy = orderBy,
                limit = limit,
                loc = loc})
      end
    | elabQuery env (S.QUERY_EMBED exp) =
      elabEmbed env QUERYty exp

  and elabInsertValue env (value, loc) =
      let
        val (ret, q) = elabOpt (elabExp env) value
      in
        (ret, (q, loc))
      end

  and elabInsertRow env numLabels (row, loc:S.loc) =
      (if length row = numLabels
       then ()
       else UserErrorUtils.enqueueError (loc, E.NumberOfSQLInsertLabel);
       (elabList (elabInsertValue env) row, loc))

  and elabInsertValues env numLabels values =
      elabList
        (fn ((b,r),l) => (b,(r,l)))
        (map (elabInsertRow env numLabels) values)

  and elabSQL env ty (sql, loc) =
      case sql of
        S.SEL select => (SELECTty, elabSelect env select)
      | S.FRM from => (FROMty, #2 (elabFrom env from))
      | S.WHR whr => (WHRty, elabWhere env whr)
      | S.ORD orderBy => (ORDERBYty, elabOrderBy env orderBy)
      | S.OFF offset => (OFFSETty, elabOffset env offset)
      | S.LMT limit => (LIMITty, elabLimit env limit)
      | S.QRY query =>
        let
          val (ret, q) = elabQuery env query
        in
          case ty of
            SOME EXPty => (EXPty, (ret, EXP_SUBQUERY (q, loc)))
          | _ => (QUERYty, (ret, q))
        end
      | S.INSERT_LABELED (tid, (labels, loc), values) =>
        let
          val (ret1, table) = elabTableId env tid
          val _ = UserErrorUtils.checkRecordLabelDuplication
                    (fn x => x)
                    labels
                    loc
                    E.DuplicateSQLInsertLabel
        in
          case values of
            S.INSERT_SELECT query =>
            let
              val (ret2, q) = elabQuery env query
            in
              (COMMANDty,
               (merge [ret1, ret2],
                INSERT_SELECT {table = table, labels = SOME labels, query = q,
                              loc = loc}))
            end
          | S.INSERT_VALUES values =>
            let
              val (ret2, q) = elabInsertValues env (length labels) values
            in
              (COMMANDty,
               (merge [ret1, ret2],
                INSERT_VALUES {table = table, labels = labels, values = q,
                               loc = loc}))
            end
        end
      | S.INSERT_NOLABEL (tid, query) =>
        let
          val (ret1, table) = elabTableId env tid
          val (ret2, q) = elabQuery env query
        in
          (COMMANDty,
           (merge [ret1, ret2],
            INSERT_SELECT {table = table, labels = NONE, query = q, loc = loc}))
        end
      | S.UPDATE (tid, (sets, loc), whr) =>
        let
          val (ret1, table) = elabTableId env tid
          val _ = UserErrorUtils.checkRecordLabelDuplication
                    #1
                    sets
                    loc
                    E.DuplicateSQLSetLabel
          val (ret2, sets) =
              elabList (fn (l,(b,e)) => (b,(l,e)))
                       (map (fn (l,e) => (l, elabExp env e)) sets)
          val (ret3, whr) =
              elabOpt (elabWhereClause env) whr
        in
          (COMMANDty,
           (merge [ret1, ret2, ret3],
            UPDATE {table = table, setList = sets, whr = whr, loc = loc}))
        end
      | S.DELETE (tid, whr) =>
        let
          val (ret1, table) = elabTableId env tid
          val (ret2, whr) = elabOpt (elabWhereClause env) whr
        in
          (COMMANDty,
           (merge [ret1, ret2],
            DELETE {table = table, whr = whr, loc = loc}))
        end
      | S.BEGIN => (COMMANDty, (emptyRet, BEGIN loc))
      | S.COMMIT => (COMMANDty, (emptyRet, COMMIT loc))
      | S.ROLLBACK => (COMMANDty, (emptyRet, ROLLBACK loc))
      | S.E exp => (EXPty, elabExp env exp)

  fun sqlFn (pat, exp) =
      let
        val t = Tyvar (Symbol.generate ())
        val x = Symbol.generate ()
        val patTy = Ty_db (TyWild, TyID t)
        val expTy = Ty_command (TyWild, TyID t)
      in
        Fn1 (fn y =>
                Let [t]
                    (PatVar x,
                     Fn (PatTyped (Pat pat, patTy), Typed (exp, expTy)))
                    (Fun_sqleval (Var x) y))
      end

  fun elabSqlexp (context as {elabPat, env, ty}) (sqlexp, loc) =
      case sqlexp of
        S.SQL sql =>
        let
          val (ty, (ret, query)) = elabSQL env ty (sql, loc)
        in
          (#column2set ret, makeBind ret (queryToExp query) loc)
        end
      | S.SQLFN (pat, sql) =>
        let
          val pat = elabPat NONE pat
          val (ty, (ret, query)) = elabSQL env ty (sql, loc)
          val bodyExp = queryToExp query
          val bodyExp =
              case ty of
                QUERYty => Fun_queryCommand bodyExp
              | _ => bodyExp
        in
          (#column2set ret, sqlFn (pat, makeBind ret bodyExp) loc)
        end
      | S.SQLFNEXP (pat, exp) =>
        let
          val pat = elabPat NONE pat
          val (ret, query) =
              case exp of
                S.EXP (exp, loc) => elabEmbed env COMMANDty (exp, loc)
              | _ => elabExp env exp
          val bodyExp = queryToExp query
        in
          (#column2set ret, sqlFn (pat, makeBind ret bodyExp) loc)
        end
      | S.SQLSERVER (exp, schema) =>
        (emptySet,
         Fun_sqlserver
           (case exp of
              NONE => String ""
            | SOME exp => Exp (#elabAbsynExp env NONE exp),
            Exp (P.PLSQLSCHEMA {tyFnExp = ExVar Name.fun_ty loc,
                                ty = schema,
                                loc = loc}))
           loc)

  fun elaborateExp {elabExp, elabPat} context (sqlexp, loc) =
      let
        val (fromLabels, ty) =
            case context of
              SOME {fromLabels, ty, ...} => (fromLabels, SOME ty)
            | NONE => (NONE, NONE)
        val env = {elabAbsynExp = elabExp, fromLabels = fromLabels}
        val (set, exp) =
            elabSqlexp {elabPat = elabPat, env = env, ty = ty} (sqlexp, loc)
      in
        case context of
          SOME {column2setRet, ...} =>
          column2setRet := union (!column2setRet, set)
        | NONE => ();
        exp
      end

end
