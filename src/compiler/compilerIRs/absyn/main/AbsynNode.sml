(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure AbsynNode =
struct

  structure A = Absyn
  structure I = AbsynInterface
  structure S = AbsynSQL

  datatype node =
      (* AbsynTy *)
      ID of AbsynTy.id
    | VID of AbsynTy.vid
    | LONGVID of AbsynTy.longvid
    | TYCON of AbsynTy.tycon
    | LONGTYCON of AbsynTy.longtycon
    | LAB of AbsynTy.lab
    | TYVAR of AbsynTy.tyvar
    | TYVARSEQ of AbsynTy.tyvarseq
    | OP_LONGVID of Absyn.op_longvid
    | TY of AbsynTy.ty
    | KIND of AbsynTy.kind
    | KINDED_TYVAR of AbsynTy.kinded_tyvar
    | TYROW of AbsynTy.tyrow
    | TYSEQ of AbsynTy.tyseq
    | KINDED_TYVARSEQ of AbsynTy.kinded_tyvarseq
    | FFI_ATTR of AbsynTy.ffi_attr
    | FFI_TY of AbsynTy.ffi_ty
    | FFI_TYROW of AbsynTy.ffi_tyrow
    | FFI_TYSEQ of AbsynTy.ffi_tyseq
    | FFI_ARG of AbsynTy.ffi_arg
    | FFI_RET of AbsynTy.ffi_ret
      (* Absyn *)
    | STRID of Absyn.strid
    | SIGID of Absyn.sigid
    | FUNID of Absyn.funid
    | LONGSTRID of Absyn.longstrid
    | OP_VID of Absyn.op_vid
    | REQUIRE_PATH of Absyn.require_path
    | EXTERN_NAME of Absyn.extern_name
    | EXIST_QUANT of Absyn.exist_quant
    | PAT of Absyn.pat
    | PATROW of Absyn.patrow
    | EXBIND of Absyn.exbind
    | TYPBIND of Absyn.typbind
    | CONBIND of Absyn.conbind
    | DATBIND of Absyn.datbind
    | EXP of Absyn.exp
    | VALBIND of Absyn.valbind
    | DEC of Absyn.dec
    | EXPROW of Absyn.exprow
    | MRULE of Absyn.mrule
    | DYNAMIC_MRULE of Absyn.dynamic_mrule
    | FRULE of Absyn.frule
    | FVALBIND of Absyn.fvalbind
    | PVALBIND of Absyn.pvalbind
    | VALDESC of Absyn.valdesc
    | TYPDESC of Absyn.typdesc
    | CONDESC of Absyn.condesc
    | DATDESC of Absyn.datdesc
    | EXDESC of Absyn.exdesc
    | WHERETYPE of Absyn.wheretype
    | SPEC of Absyn.spec
    | SIGEXP of Absyn.sigexp
    | STRDESC of Absyn.strdesc
    | SIGBIND of Absyn.sigbind
    | SIGCONSTRAINT of Absyn.sigconstraint
    | STREXP of Absyn.strexp
    | STRDEC of Absyn.strdec
    | STRBIND of Absyn.strbind
    | FUNBIND of Absyn.funbind
    | TOPDEC of Absyn.topdec
    | TOP of Absyn.top
    | INTERFACE of Absyn.interface
    | COMPILE_UNIT of Absyn.compile_unit
      (* AbsynSQL *)
    | SQL_TABLE_SELECTOR of AbsynSQL.table_selector
    | SQL_EXP of Absyn.exp AbsynSQL.exp
    | SQL_KWEXP of Absyn.exp AbsynSQL.kwexp
    | SQL_TABLE of Absyn.exp AbsynSQL.table
    | SQL_FROM of Absyn.exp AbsynSQL.from
    | SQL_WHR of Absyn.exp AbsynSQL.whr
    | SQL_GROUPBY of Absyn.exp AbsynSQL.groupby
    | SQL_ORDERBY of Absyn.exp AbsynSQL.orderby
    | SQL_LIMIT of Absyn.exp AbsynSQL.limit
    | SQL_OFFSET of Absyn.exp AbsynSQL.offset
    | SQL_SELECT of Absyn.exp AbsynSQL.select
    | SQL_QUERY of Absyn.exp AbsynSQL.query
    | SQL_ORDER_KEY of Absyn.exp AbsynSQL.order_key
    | SQL_SELECT_ROW of Absyn.exp AbsynSQL.select_row
    | SQL_GROUPBY_CLAUSE of Absyn.exp AbsynSQL.groupby_clause
    | SQL_HAVING_CLAUSE of Absyn.exp AbsynSQL.having_clause
    | SQL_LIMIT_CLAUSE of Absyn.exp AbsynSQL.limit_clause
    | SQL_LIMIT_OFFSET_CLAUSE of Absyn.exp AbsynSQL.limit_offset_clause
    | SQL_OFFSET_CLAUSE of Absyn.exp AbsynSQL.offset_clause
    | SQL_FETCH_CLAUSE of Absyn.exp AbsynSQL.fetch_clause
    | SQL_INSERT_VALUE of Absyn.exp AbsynSQL.insert_value
    | SQL_INSERT_ROW of Absyn.exp AbsynSQL.insert_row
    | SQL_INSERT_VALUES of Absyn.exp AbsynSQL.insert_values
    | SQL_INSERT_LABELS of AbsynSQL.insert_labels
    | SQL_SET_ROW of Absyn.exp AbsynSQL.set_row
    | SQL_SET of Absyn.exp AbsynSQL.set
    | SQL_CON of Absyn.exp AbsynSQL.con
    | SQL_STEP of Absyn.exp AbsynSQL.step
    | SQL_BODY of Absyn.exp AbsynSQL.body
    | SQL_TOP of (Absyn.exp, Absyn.pat, Absyn.ty) AbsynSQL.top
      (*% AbsynInterface *)
    | OPAQUE_IMPL of AbsynInterface.opaque_impl
    | OVERLOAD_INSTANCE of AbsynInterface.overload_instance
    | OVERLOAD_MRULE of AbsynInterface.overload_mrule
    | OVERLOAD_CASE of AbsynInterface.overload_case
    | IVALBIND of AbsynInterface.valbind
    | ITYPDESC of AbsynInterface.typdesc
    | IDEC of AbsynInterface.dec
    | ISTREXP of AbsynInterface.strexp
    | ISTRBIND of AbsynInterface.strbind
    | IFUNBIND of AbsynInterface.funbind
    | ITOPDEC of AbsynInterface.topdec
    | IREQUIRE of AbsynInterface.require
    | IINCLUDE of AbsynInterface.include_dec
    | ISIGDEC of AbsynInterface.sigdec
    | ITOP of AbsynInterface.top

  fun getName node =
      case node of
        ID _ => "ID"
      | VID _ => "VID"
      | LONGVID _ => "LONGVID"
      | TYCON _ => "TYCON"
      | LONGTYCON _ => "LONGTYCON"
      | LAB _ => "LAB"
      | TYVAR _ => "TYVAR"
      | TYVARSEQ _ => "TYVARSEQ"
      | OP_LONGVID _ => "OP_LONGVID"
      | TY (A.TYVAR _) => "TY:TYVAR"
      | TY (A.TYRECORD _) => "TY:TYRECORD"
      | TY (A.TYCON _) => "TY:TYCON"
      | TY (A.TYTUPLE _) => "TY:TYTUPLE"
      | TY (A.TYFUN _) => "TY:TYFUN"
      | TY (A.TYPAREN _) => "TY:TYPAREN"
      | TY (A.TYWILD _) => "TY:TYWILD"
      | TY (A.TYVAR_FREE _) => "TY:TYVAR_FREE"
      | TY (A.TYPOLY _) => "TY:TYPOLY"
      | KIND (A.UNIV _) => "KIND:UNIV"
      | KIND (A.REC _) => "KIND:REC"
      | KINDED_TYVAR _ => "KINDED_TYVAR"
      | TYROW _ => "TYROW"
      | TYSEQ _ => "TYSEQ"
      | KINDED_TYVARSEQ _ => "KINDED_TYVARSEQ"
      | FFI_ATTR _ => "FFI_ATTR"
      | FFI_TY (A.FFITYVAR _) => "FFI_TY:FFITYVAR"
      | FFI_TY (A.FFITYRECORD _) => "FFI_TY:FFITYRECORD"
      | FFI_TY (A.FFITYCON _) => "FFI_TY:FFITYCON"
      | FFI_TY (A.FFITYTUPLE _) => "FFI_TY:FFITYTUPLE"
      | FFI_TY (A.FFITYFUN _) => "FFI_TY:FFITYFUN"
      | FFI_TY (A.FFITYPAREN _) => "FFI_TY:FFITYPAREN"
      | FFI_TYROW _ => "FFI_TYROW"
      | FFI_TYSEQ _ => "FFI_TYSEQ"
      | FFI_ARG _ => "FFI_ARG"
      | FFI_RET _ => "FFI_RET"
      | STRID _ => "STRID"
      | SIGID _ => "SIGID"
      | FUNID _ => "FUNID"
      | LONGSTRID _ => "LONGSTRID"
      | OP_VID _ => "OP_VID"
      | REQUIRE_PATH _ => "REQUIRE_PATH"
      | EXTERN_NAME _ => "EXTERN_NAME"
      | EXIST_QUANT _ => "EXIST_QUANT"
      | PAT (A.PATWILD _) => "PAT:PATWILD"
      | PAT (A.PATCONST _) => "PAT:PATCONST"
      | PAT (A.PATID _) => "PAT:PATID"
      | PAT (A.PATRECORD _) => "PAT:PATRECORD"
      | PAT (A.PATTUPLE _) => "PAT:PATTUPLE"
      | PAT (A.PATLIST _) => "PAT:PATLIST"
      | PAT (A.PATPAREN _) => "PAT:PATPAREN"
      | PAT (A.PATAPP _) => "PAT:PATAPP"
      | PAT (A.PATINFIX _) => "PAT:PATINFIX"
      | PAT (A.PATTYPED _) => "PAT:PATTYPED"
      | PAT (A.PATAS _) => "PAT:PATAS"
      | PATROW (A.PATROW _) => "PATROW:PATROW"
      | PATROW (A.PATROWVAR _) => "PATROW:PATROWVAR"
      | EXBIND (A.EXBIND _) => "EXBIND:EXBIND"
      | EXBIND (A.EXBINDREP _) => "EXBIND:EXBINDREP"
      | TYPBIND _ => "TYPBIND"
      | CONBIND _ => "CONBIND"
      | DATBIND _ => "DATBIND"
      | EXP (A.EXPCONST _) => "EXP:EXPCONST"
      | EXP (A.EXPID _) => "EXP:EXPID"
      | EXP (A.EXPRECORD _) => "EXP:EXPRECORD"
      | EXP (A.EXPSELECT _) => "EXP:EXPSELECT"
      | EXP (A.EXPTUPLE _) => "EXP:EXPTUPLE"
      | EXP (A.EXPLIST _) => "EXP:EXPLIST"
      | EXP (A.EXPSEQ _) => "EXP:EXPSEQ"
      | EXP (A.EXPLET _) => "EXP:EXPLET"
      | EXP (A.EXPPAREN _) => "EXP:EXPPAREN"
      | EXP (A.EXPAPP _) => "EXP:EXPAPP"
      | EXP (A.EXPINFIX _) => "EXP:EXPINFIX"
      | EXP (A.EXPTYPED _) => "EXP:EXPTYPED"
      | EXP (A.EXPANDALSO _) => "EXP:EXPANDALSO"
      | EXP (A.EXPORELSE _) => "EXP:EXPORELSE"
      | EXP (A.EXPHANDLE _) => "EXP:EXPHANDLE"
      | EXP (A.EXPRAISE _) => "EXP:EXPRAISE"
      | EXP (A.EXPIF _) => "EXP:EXPIF"
      | EXP (A.EXPWHILE _) => "EXP:EXPWHILE"
      | EXP (A.EXPCASE _) => "EXP:EXPCASE"
      | EXP (A.EXPFN _) => "EXP:EXPFN"
      | EXP (A.EXPSIZEOF _) => "EXP:EXPSIZEOF"
      | EXP (A.EXPRECORD_UPDATE _) => "EXP:EXPRECORD_UPDATE"
      | EXP (A.EXPTUPLE_UPDATE _) => "EXP:EXPTUPLE_UPDATE"
      | EXP (A.EXPIMPORT_NAME _) => "EXP:EXPIMPORT_NAME"
      | EXP (A.EXPIMPORT_EXP _) => "EXP:EXPIMPORT_EXP"
      | EXP (A.EXPSQL _) => "EXP:EXPSQL"
      | EXP (A.EXPFOREACH_DATA _) => "EXP:EXPFOREACH_DATA"
      | EXP (A.EXPFOREACH_ARRAY _) => "EXP:EXPFOREACH_ARRAY"
      | EXP (A.EXPJOIN _) => "EXP:EXPJOIN"
      | EXP (A.EXPEXTEND _) => "EXP:EXPEXTEND"
      | EXP (A.EXPUPDATE1 _) => "EXP:EXPUPDATE1"
      | EXP (A.EXPUPDATE2 _) => "EXP:EXPUPDATE2"
      | EXP (A.EXPDYNAMIC_AS _) => "EXP:EXPDYNAMIC_AS"
      | EXP (A.EXPDYNAMIC_OF _) => "EXP:EXPDYNAMIC_OF"
      | EXP (A.EXPDYNAMICVIEW _) => "EXP:EXPDYNAMICVIEW"
      | EXP (A.EXPDYNAMICNULL _) => "EXP:EXPDYNAMICNULL"
      | EXP (A.EXPDYNAMICTOP _) => "EXP:EXPDYNAMICTOP"
      | EXP (A.EXPDYNAMICCASE _) => "EXP:EXPDYNAMICCASE"
      | EXP (A.EXPREIFYTY _) => "EXP:EXPREIFYTY"
      | VALBIND (A.VALBIND _) => "VALBIND:VALBIND"
      | VALBIND (A.VALREC _) => "VALBIND:VALREC"
      | DEC (A.DECVAL _) => "DEC:DECVAL"
      | DEC (A.DECFUN _) => "DEC:DECFUN"
      | DEC (A.DECTYPE _) => "DEC:DECTYPE"
      | DEC (A.DECDATATYPE _) => "DEC:DECDATATYPE"
      | DEC (A.DECDATATYPEREP _) => "DEC:DECDATATYPEREP"
      | DEC (A.DECABSTYPE _) => "DEC:DECABSTYPE"
      | DEC (A.DECEXCEPTION _) => "DEC:DECEXCEPTION"
      | DEC (A.DECLOCAL _) => "DEC:DECLOCAL"
      | DEC (A.DECOPEN _) => "DEC:DECOPEN"
      | DEC (A.DECSEMICOLON _) => "DEC:DECSEMICOLON"
      | DEC (A.DECINFIX _) => "DEC:DECINFIX"
      | DEC (A.DECINFIXR _) => "DEC:DECINFIXR"
      | DEC (A.DECNONFIX _) => "DEC:DECNONFIX"
      | DEC (A.DECPOLYREC _) => "DEC:DECPOLYREC"
      | EXPROW _ => "EXPROW"
      | MRULE _ => "MRULE"
      | DYNAMIC_MRULE _ => "DYNAMIC_MRULE"
      | FRULE _ => "FRULE"
      | FVALBIND _ => "FVALBIND"
      | PVALBIND _ => "PVALBIND"
      | VALDESC _ => "VALDESC"
      | TYPDESC _ => "TYPDESC"
      | CONDESC _ => "CONDESC"
      | DATDESC _ => "DATDESC"
      | EXDESC _ => "EXDESC"
      | WHERETYPE _ => "WHERETYPE"
      | SPEC (A.SPECVAL _) => "SPEC:SPECVAL"
      | SPEC (A.SPECTYPE _) => "SPEC:SPECTYPE"
      | SPEC (A.SPECTYPEINC _) => "SPEC:SPECTYPEINC"
      | SPEC (A.SPECEQTYPE _) => "SPEC:SPECEQTYPE"
      | SPEC (A.SPECDATATYPE _) => "SPEC:SPECDATATYPE"
      | SPEC (A.SPECDATATYPEREP _) => "SPEC:SPECDATATYPEREP"
      | SPEC (A.SPECEXCEPTION _) => "SPEC:SPECEXCEPTION"
      | SPEC (A.SPECSTRUCTURE _) => "SPEC:SPECSTRUCTURE"
      | SPEC (A.SPECINCLUDE _) => "SPEC:SPECINCLUDE"
      | SPEC (A.SPECINCLUDE_ID _) => "SPEC:SPECINCLUDE_ID"
      | SPEC (A.SPECSHARINGTYPE _) => "SPEC:SPECSHARINGTYPE"
      | SPEC (A.SPECSHARING _) => "SPEC:SPECSHARING"
      | SPEC (A.SPECSEMICOLON _) => "SPEC:SPECSEMICOLON"
      | SIGEXP (A.SIGBASIC _) => "SIGEXP:SIGBASIC"
      | SIGEXP (A.SIGID _) => "SIGEXP:SIGID"
      | SIGEXP (A.SIGWHERE _) => "SIGEXP:SIGWHERE"
      | STRDESC _ => "STRDESC"
      | SIGBIND _ => "SIGBIND"
      | SIGCONSTRAINT _ => "SIGCONSTRAINT"
      | STREXP (A.STRBASIC _) => "STREXP:STRBASIC"
      | STREXP (A.STRID _) => "STREXP:STRID"
      | STREXP (A.STRCONSTRAINT _) => "STREXP:STRCONSTRAINT"
      | STREXP (A.STRAPP _) => "STREXP:STRAPP"
      | STREXP (A.STRLET _) => "STREXP:STRLET"
      | STRDEC (A.STRDEC _) => "STRDEC:STRDEC"
      | STRDEC (A.STRUCTURE _) => "STRDEC:STRUCTURE"
      | STRDEC (A.STRLOCAL _) => "STRDEC:STRLOCAL"
      | STRDEC (A.STRSEMICOLON _) => "STRDEC:STRSEMICOLON"
      | STRBIND _ => "STRBIND"
      | FUNBIND _ => "FUNBIND"
      | TOPDEC (A.TOPSTRDEC _) => "TOPDEC:TOPSTRDEC"
      | TOPDEC (A.TOPSIGNATURE _) => "TOPDEC:TOPSIGNATURE"
      | TOPDEC (A.TOPFUNCTOR _) => "TOPDEC:TOPFUNCTOR"
      | TOPDEC (A.TOPEXP _) => "TOPDEC:TOPEXP"
      | TOP (A.TOPDEC _) => "TOP:TOPDEC"
      | TOP (A.USE _) => "TOP:USE"
      | TOP (A.USE' _) => "TOP:USE'"
      | TOP (A.TOPSEMICOLON _) => "TOP:TOPSEMICOLON"
      | INTERFACE _ => "INTERFACE"
      | COMPILE_UNIT _ => "COMPILE_UNIT"
      | SQL_TABLE_SELECTOR _ => "SQL_TABLE_SELECTOR"
      | SQL_EXP (S.EXP_EMBED _) => "SQL_EXP:EXP_EMBED"
      | SQL_EXP (S.CONST _) => "SQL_EXP:CONST"
      | SQL_EXP (S.NULL _) => "SQL_EXP:NULL"
      | SQL_EXP (S.TRUE _) => "SQL_EXP:TRUE"
      | SQL_EXP (S.FALSE _) => "SQL_EXP:FALSE"
      | SQL_EXP (S.COLUMN1 _) => "SQL_EXP:COLUMN1"
      | SQL_EXP (S.COLUMN2 _) => "SQL_EXP:COLUMN2"
      | SQL_EXP (S.KWEXP _) => "SQL_EXP:KWEXP"
      | SQL_EXP (S.EXP_SUBQUERY _) => "SQL_EXP:EXP_SUBQUERY"
      | SQL_EXP (S.OP1 _) => "SQL_EXP:OP1"
      | SQL_EXP (S.OP2 _) => "SQL_EXP:OP2"
      | SQL_EXP (S.ID _) => "SQL_EXP:ID"
      | SQL_EXP (S.PAREN _) => "SQL_EXP:PAREN"
      | SQL_EXP (S.APP _) => "SQL_EXP:APP"
      | SQL_EXP (S.INFIX _) => "SQL_EXP:INFIX"
      | SQL_EXP (S.CAST _) => "SQL_EXP:CAST"
      | SQL_EXP (S.TUPLE _) => "SQL_EXP:TUPLE"
      | SQL_KWEXP (S.EXISTS _) => "SQL_KWEXP:EXISTS"
      | SQL_TABLE (S.TABLE _) => "SQL_TABLE:TABLE"
      | SQL_TABLE (S.TABLE_AS _) => "SQL_TABLE:TABLE_AS"
      | SQL_TABLE (S.TABLE_INNER_JOIN _) => "SQL_TABLE:TABLE_INNER_JOIN"
      | SQL_TABLE (S.TABLE_CROSS_JOIN _) => "SQL_TABLE:TABLE_CROSS_JOIN"
      | SQL_TABLE (S.TABLE_NATURAL_JOIN _) => "SQL_TABLE:TABLE_NATURAL_JOIN"
      | SQL_TABLE (S.TABLE_SUBQUERY _) => "SQL_TABLE:TABLE_SUBQUERY"
      | SQL_TABLE (S.TABLE_PAREN _) => "SQL_TABLE:TABLE_PAREN"
      | SQL_FROM (S.FROM _) => "SQL_FROM:FROM"
      | SQL_FROM (S.FROM_EMBED _) => "SQL_FROM:FROM_EMBED"
      | SQL_WHR (S.WHERE _) => "SQL_WHR:WHERE"
      | SQL_WHR (S.WHERE_EMBED _) => "SQL_WHR:WHERE_EMBED"
      | SQL_GROUPBY (S.GROUPBY _) => "SQL_GROUPBY:GROUPBY"
      | SQL_ORDERBY (S.ORDERBY _) => "SQL_ORDERBY:ORDERBY"
      | SQL_ORDERBY (S.ORDERBY_EMBED _) => "SQL_ORDERBY:ORDERBY_EMBED"
      | SQL_LIMIT (S.LIMIT _) => "SQL_LIMIT:LIMIT"
      | SQL_LIMIT (S.LIMIT_EMBED _) => "SQL_LIMIT:LIMIT_EMBED"
      | SQL_OFFSET (S.OFFSET _) => "SQL_OFFSET:OFFSET"
      | SQL_OFFSET (S.OFFSET_EMBED _) => "SQL_OFFSET:OFFSET_EMBED"
      | SQL_SELECT (S.SELECT _) => "SQL_SELECT:SELECT"
      | SQL_SELECT (S.SELECT_EMBED _) => "SQL_SELECT:SELECT_EMBED"
      | SQL_QUERY (S.QUERY _) => "SQL_QUERY:QUERY"
      | SQL_QUERY (S.QUERY_EMBED _) => "SQL_QUERY:QUERY_EMBED"
      | SQL_ORDER_KEY _ => "SQL_ORDER_KEY"
      | SQL_SELECT_ROW _ => "SQL_SELECT_ROW"
      | SQL_GROUPBY_CLAUSE _ => "SQL_GROUPBY_CLAUSE"
      | SQL_HAVING_CLAUSE _ => "SQL_HAVING_CLAUSE"
      | SQL_LIMIT_CLAUSE _ => "SQL_LIMIT_CLAUSE"
      | SQL_LIMIT_OFFSET_CLAUSE _ => "SQL_LIMIT_OFFSET_CLAUSE"
      | SQL_OFFSET_CLAUSE _ => "SQL_OFFSET_CLAUSE"
      | SQL_FETCH_CLAUSE _ => "SQL_FETCH_CLAUSE"
      | SQL_INSERT_VALUE (S.VALUE _) => "SQL_INSERT_VALUE:VALUE"
      | SQL_INSERT_VALUE (S.DEFAULT _) => "SQL_INSERT_VALUE:DEFAULT"
      | SQL_INSERT_ROW _ => "SQL_INSERT_ROW"
      | SQL_INSERT_VALUES (S.INSERT_VALUES _) =>
        "SQL_INSERT_VALUES:INSERT_VALUES"
      | SQL_INSERT_VALUES (S.INSERT_VAR _) => "SQL_INSERT_VALUES:INSERT_VAR"
      | SQL_INSERT_VALUES (S.INSERT_SELECT _) =>
        "SQL_INSERT_VALUES:INSERT_SELECT"
      | SQL_INSERT_LABELS _ => "SQL_INSERT_LABELS"
      | SQL_SET_ROW _ => "SQL_SET_ROW"
      | SQL_SET _ => "SQL_SET"
      | SQL_CON (S.QRY _) => "SQL_CON:QRY"
      | SQL_CON (S.SEL _) => "SQL_CON:SEL"
      | SQL_CON (S.FRM _) => "SQL_CON:FRM"
      | SQL_CON (S.WHR _) => "SQL_CON:WHR"
      | SQL_CON (S.ORD _) => "SQL_CON:ORD"
      | SQL_CON (S.OFF _) => "SQL_CON:OFF"
      | SQL_CON (S.LMT _) => "SQL_CON:LMT"
      | SQL_CON (S.INSERT_LABELED _) => "SQL_CON:INSERT_LABELED"
      | SQL_CON (S.INSERT_NOLABEL _) => "SQL_CON:INSERT_NOLABEL"
      | SQL_CON (S.UPDATE _) => "SQL_CON:UPDATE"
      | SQL_CON (S.DELETE _) => "SQL_CON:DELETE"
      | SQL_CON (S.BEGIN _) => "SQL_CON:BEGIN"
      | SQL_CON (S.COMMIT _) => "SQL_CON:COMMIT"
      | SQL_CON (S.ROLLBACK _) => "SQL_CON:ROLLBACK"
      | SQL_STEP (S.STEP _) => "SQL_STEP:STEP"
      | SQL_STEP (S.STEP_EMBED _) => "SQL_STEP:STEP_EMBED"
      | SQL_BODY (S.CON _) => "SQL_BODY:CON"
      | SQL_BODY (S.EXP _) => "SQL_BODY:EXP"
      | SQL_BODY (S.SEQ _) => "SQL_BODY:SEQ"
      | SQL_BODY (S.BODYPAREN _) => "SQL_BODY:BODYPAREN"
      | SQL_TOP (S.SQLSERVER _) => "SQL_TOP:SQLSERVER"
      | SQL_TOP (S.SQL _) => "SQL_TOP:SQL"
      | SQL_TOP (S.SQLFN _) => "SQL_TOP:SQLFN"
      | OPAQUE_IMPL (I.IMPL_TY _) => "OPAQUE_IMPL:IMPL_TY"
      | OPAQUE_IMPL (I.IMPL_TUPLE _) => "OPAQUE_IMPL:IMPL_TUPLE"
      | OPAQUE_IMPL (I.IMPL_RECORD _) => "OPAQUE_IMPL:IMPL_RECORD"
      | OPAQUE_IMPL (I.IMPL_FUNC _) => "OPAQUE_IMPL:IMPL_FUNC"
      | OVERLOAD_INSTANCE (I.INST_OVERLOAD _) =>
        "OVERLOAD_INSTANCE:INST_OVERLOAD"
      | OVERLOAD_INSTANCE (I.INST_LONGVID _) => "OVERLOAD_INSTANCE:INST_LONGVID"
      | OVERLOAD_INSTANCE (I.INST_PAREN _) => "OVERLOAD_INSTANCE:INST_PAREN"
      | OVERLOAD_MRULE _ => "OVERLOAD_MRULE"
      | OVERLOAD_CASE _ => "OVERLOAD_CASE"
      | IVALBIND (I.VAL_EXTERN _) => "IVALBIND:VAL_EXTERN"
      | IVALBIND (I.VAL_ALIAS _) => "IVALBIND:VAL_ALIAS"
      | IVALBIND (I.VAL_BUILTIN _) => "IVALBIND:VAL_BUILTIN"
      | IVALBIND (I.VAL_OVERLOAD _) => "IVALBIND:VAL_OVERLOAD"
      | ITYPDESC _ => "ITYPDESC"
      | IDEC (I.VAL _) => "IDEC:VAL"
      | IDEC (I.TYPE _) => "IDEC:TYPE"
      | IDEC (I.EQTYPE _) => "IDEC:EQTYPE"
      | IDEC (I.DATATYPE _) => "IDEC:DATATYPE"
      | IDEC (I.DATATYPEREP _) => "IDEC:DATATYPEREP"
      | IDEC (I.TYPEBUILTIN _) => "IDEC:TYPEBUILTIN"
      | IDEC (I.EXCEPTION _) => "IDEC:EXCEPTION"
      | IDEC (I.STRUCTURE _) => "IDEC:STRUCTURE"
      | IDEC (I.SEMICOLON _) => "IDEC:SEMICOLON"
      | ISTREXP (I.STRBASIC _) => "ISTREXP:STRBASIC"
      | ISTREXP (I.STRID _) => "ISTREXP:STRID"
      | ISTREXP (I.STRAPP _) => "ISTREXP:STRAPP"
      | ISTRBIND _ => "ISTRBIND"
      | IFUNBIND _ => "IFUNBIND"
      | ITOPDEC (I.DEC _) => "ITOPDEC:DEC"
      | ITOPDEC (I.FUNCTOR _) => "ITOPDEC:FUNCTOR"
      | ITOPDEC (I.INFIX _) => "ITOPDEC:INFIX"
      | ITOPDEC (I.INFIXR _) => "ITOPDEC:INFIXR"
      | ITOPDEC (I.NONFIX _) => "ITOPDEC:NONFIX"
      | IREQUIRE (I.REQUIRE _) => "IREQUIRE:REQUIRE"
      | IREQUIRE (I.REQUIRE_LOCAL _) => "IREQUIRE:REQUIRE_LOCAL"
      | IREQUIRE (I.USE_LOCAL _) => "IREQUIRE:USE_LOCAL"
      | IREQUIRE (I.REQSEMICOLON _) => "IREQUIRE:REQSEMICOLON"
      | IINCLUDE (I.INCLUDE _) => "IINCLUDE:INCLUDE"
      | IINCLUDE (I.INCSEMICOLON _) => "IINCLUDE:INCSEMICOLON"
      | ISIGDEC (I.SIGNATURE _) => "ISIGDEC:SIGNATURE"
      | ISIGDEC (I.SIGSEMICOLON _) => "ISIGDEC:SIGSEMICOLON"
      | ITOP (I.INTERFACE _) => "ITOP:INTERFACE"
      | ITOP (I.INCLUDES _) => "ITOP:INCLUDES"

  fun getLoc node =
      case node of
        ID (_, loc) => loc
      | VID (_, loc) => loc
      | LONGVID (_, loc) => loc
      | TYCON (_, loc) => loc
      | LONGTYCON (_, loc) => loc
      | LAB (_, loc) => loc
      | TYVAR (_, (_, loc)) => loc
      | TYVARSEQ (_, loc) => loc
      | OP_LONGVID (_, _, loc) => loc
      | TY (A.TYVAR (_, (_, loc))) => loc
      | TY (A.TYRECORD (_, _, loc)) => loc
      | TY (A.TYCON (_, _, loc)) => loc
      | TY (A.TYTUPLE (_, loc)) => loc
      | TY (A.TYFUN (_, _, loc)) => loc
      | TY (A.TYPAREN (_, loc)) => loc
      | TY (A.TYWILD loc) => loc
      | TY (A.TYVAR_FREE (_, _, loc)) => loc
      | TY (A.TYPOLY (_, _, loc)) => loc
      | KIND (A.UNIV (_, loc)) => loc
      | KIND (A.REC (_, _, loc)) => loc
      | KINDED_TYVAR (_, _, loc) => loc
      | TYROW (_, _, loc) => loc
      | TYSEQ (_, loc) => loc
      | KINDED_TYVARSEQ (_, loc) => loc
      | FFI_ATTR (_, loc) => loc
      | FFI_TY (A.FFITYVAR (_, (_, loc))) => loc
      | FFI_TY (A.FFITYRECORD (_, loc)) => loc
      | FFI_TY (A.FFITYCON (_, _, loc)) => loc
      | FFI_TY (A.FFITYTUPLE (_, loc)) => loc
      | FFI_TY (A.FFITYFUN (_, _, _, loc)) => loc
      | FFI_TY (A.FFITYPAREN (_, loc)) => loc
      | FFI_TYROW (_, _, loc) => loc
      | FFI_TYSEQ (_, loc) => loc
      | FFI_ARG (_, _, loc) => loc
      | FFI_RET (_, loc) => loc
      | STRID (_, loc) => loc
      | SIGID (_, loc) => loc
      | FUNID (_, loc) => loc
      | LONGSTRID (_, loc) => loc
      | OP_VID (_, _, loc) => loc
      | REQUIRE_PATH (_, loc) => loc
      | EXTERN_NAME (_, loc) => loc
      | EXIST_QUANT (_, loc) => loc
      | PAT (A.PATWILD loc) => loc
      | PAT (A.PATCONST (_, loc)) => loc
      | PAT (A.PATID (_, _, loc)) => loc
      | PAT (A.PATRECORD (_, _, loc)) => loc
      | PAT (A.PATTUPLE (_, loc)) => loc
      | PAT (A.PATLIST (_, loc)) => loc
      | PAT (A.PATPAREN (_, loc)) => loc
      | PAT (A.PATAPP (_, _, loc)) => loc
      | PAT (A.PATINFIX (_, _, _, loc)) => loc
      | PAT (A.PATTYPED (_, _, loc)) => loc
      | PAT (A.PATAS (_, _, _, loc)) => loc
      | PATROW (A.PATROW (_, _, loc)) => loc
      | PATROW (A.PATROWVAR (_, _, _, loc)) => loc
      | EXBIND (A.EXBIND (_, _, loc)) => loc
      | EXBIND (A.EXBINDREP (_, _, loc)) => loc
      | TYPBIND (_, _, _, loc) => loc
      | CONBIND (_, _, loc) => loc
      | DATBIND (_, _, _, loc) => loc
      | EXP (A.EXPCONST (_, loc)) => loc
      | EXP (A.EXPID (_, _, loc)) => loc
      | EXP (A.EXPRECORD (_, loc)) => loc
      | EXP (A.EXPSELECT (_, loc)) => loc
      | EXP (A.EXPTUPLE (_, loc)) => loc
      | EXP (A.EXPLIST (_, loc)) => loc
      | EXP (A.EXPSEQ (_, loc)) => loc
      | EXP (A.EXPLET (_, _, loc)) => loc
      | EXP (A.EXPPAREN (_, loc)) => loc
      | EXP (A.EXPAPP (_, _, loc)) => loc
      | EXP (A.EXPINFIX (_, _, _, loc)) => loc
      | EXP (A.EXPTYPED (_, _, loc)) => loc
      | EXP (A.EXPANDALSO (_, _, loc)) => loc
      | EXP (A.EXPORELSE (_, _, loc)) => loc
      | EXP (A.EXPHANDLE (_, _, loc)) => loc
      | EXP (A.EXPRAISE (_, loc)) => loc
      | EXP (A.EXPIF (_, _, _, loc)) => loc
      | EXP (A.EXPWHILE (_, _, loc)) => loc
      | EXP (A.EXPCASE (_, _, loc)) => loc
      | EXP (A.EXPFN (_, loc)) => loc
      | EXP (A.EXPSIZEOF (_, loc)) => loc
      | EXP (A.EXPRECORD_UPDATE (_, _, loc)) => loc
      | EXP (A.EXPTUPLE_UPDATE (_, _, loc)) => loc
      | EXP (A.EXPIMPORT_NAME (_, _, loc)) => loc
      | EXP (A.EXPIMPORT_EXP (_, _, loc)) => loc
      | EXP (A.EXPSQL sqlexp) => getLoc (SQL_TOP sqlexp)
      | EXP (A.EXPFOREACH_DATA (_, _, _, _, _, _, loc)) => loc
      | EXP (A.EXPFOREACH_ARRAY (_, _, _, _, _, loc)) => loc
      | EXP (A.EXPJOIN (_, _, loc)) => loc
      | EXP (A.EXPEXTEND (_, _, loc)) => loc
      | EXP (A.EXPUPDATE1 (_, _, loc)) => loc
      | EXP (A.EXPUPDATE2 (_, _, loc)) => loc
      | EXP (A.EXPDYNAMIC_AS (_, _, loc)) => loc
      | EXP (A.EXPDYNAMIC_OF (_, _, loc)) => loc
      | EXP (A.EXPDYNAMICVIEW (_, _, loc)) => loc
      | EXP (A.EXPDYNAMICNULL (_, loc)) => loc
      | EXP (A.EXPDYNAMICTOP (_, loc)) => loc
      | EXP (A.EXPDYNAMICCASE (_, _, loc)) => loc
      | EXP (A.EXPREIFYTY (_, loc)) => loc
      | VALBIND (A.VALBIND (_, _, loc)) => loc
      | VALBIND (A.VALREC (_, loc)) => loc
      | DEC (A.DECVAL (_, _, loc)) => loc
      | DEC (A.DECFUN (_, _, loc)) => loc
      | DEC (A.DECTYPE (_, loc)) => loc
      | DEC (A.DECDATATYPE (_, _, loc)) => loc
      | DEC (A.DECDATATYPEREP (_, _, loc)) => loc
      | DEC (A.DECABSTYPE (_, _, _, loc)) => loc
      | DEC (A.DECEXCEPTION (_, loc)) => loc
      | DEC (A.DECLOCAL (_, _, loc)) => loc
      | DEC (A.DECOPEN (_, loc)) => loc
      | DEC (A.DECSEMICOLON loc) => loc
      | DEC (A.DECINFIX (_, _, loc)) => loc
      | DEC (A.DECINFIXR (_, _, loc)) => loc
      | DEC (A.DECNONFIX (_, loc)) => loc
      | DEC (A.DECPOLYREC (_, loc)) => loc
      | EXPROW (_, _, loc) => loc
      | MRULE (_, _, loc) => loc
      | DYNAMIC_MRULE (_, _, _, loc) => loc
      | FRULE (_, _, _, loc) => loc
      | FVALBIND (_, loc) => loc
      | PVALBIND (_, _, _, loc) => loc
      | VALDESC (_, _, loc) => loc
      | TYPDESC (_, _, loc) => loc
      | CONDESC (_, _, loc) => loc
      | DATDESC (_, _, _, loc) => loc
      | EXDESC (_, _, loc) => loc
      | WHERETYPE (_, _, _, loc) => loc
      | SPEC (A.SPECVAL (_, loc)) => loc
      | SPEC (A.SPECTYPE (_, loc)) => loc
      | SPEC (A.SPECTYPEINC (_, loc)) => loc
      | SPEC (A.SPECEQTYPE (_, loc)) => loc
      | SPEC (A.SPECDATATYPE (_, loc)) => loc
      | SPEC (A.SPECDATATYPEREP (_, _, loc)) => loc
      | SPEC (A.SPECEXCEPTION (_, loc)) => loc
      | SPEC (A.SPECSTRUCTURE (_, loc)) => loc
      | SPEC (A.SPECINCLUDE (_, loc)) => loc
      | SPEC (A.SPECINCLUDE_ID (_, loc)) => loc
      | SPEC (A.SPECSHARINGTYPE (_, _, loc)) => loc
      | SPEC (A.SPECSHARING (_, _, loc)) => loc
      | SPEC (A.SPECSEMICOLON loc) => loc
      | SIGEXP (A.SIGBASIC (_, loc)) => loc
      | SIGEXP (A.SIGID (_, loc)) => loc
      | SIGEXP (A.SIGWHERE (_, _, loc)) => loc
      | STRDESC (_, _, loc) => loc
      | SIGBIND (_, _, loc) => loc
      | SIGCONSTRAINT (_, _, loc) => loc
      | STREXP (A.STRBASIC (_, loc)) => loc
      | STREXP (A.STRID (_, loc)) => loc
      | STREXP (A.STRCONSTRAINT (_, _, _, loc)) => loc
      | STREXP (A.STRAPP (_, _, loc)) => loc
      | STREXP (A.STRLET (_, _, loc)) => loc
      | STRDEC (A.STRDEC dec) => getLoc (DEC dec)
      | STRDEC (A.STRUCTURE (_, loc)) => loc
      | STRDEC (A.STRLOCAL (_, _, loc)) => loc
      | STRDEC (A.STRSEMICOLON loc) => loc
      | STRBIND (_, _, _, loc) => loc
      | FUNBIND (_, _, _, _, loc) => loc
      | TOPDEC (A.TOPSTRDEC strdec) => getLoc (STRDEC strdec)
      | TOPDEC (A.TOPSIGNATURE (_, loc)) => loc
      | TOPDEC (A.TOPFUNCTOR (_, loc)) => loc
      | TOPDEC (A.TOPEXP (_, loc)) => loc
      | TOP (A.TOPDEC (_, loc)) => loc
      | TOP (A.USE (_, loc)) => loc
      | TOP (A.USE' (_, loc)) => loc
      | TOP (A.TOPSEMICOLON loc) => loc
      | INTERFACE (_, loc) => loc
      | COMPILE_UNIT (_, _, loc) => loc
      | SQL_TABLE_SELECTOR (_, _, loc) => loc
      | SQL_EXP (S.EXP_EMBED (_, loc)) => loc
      | SQL_EXP (S.CONST (_, loc)) => loc
      | SQL_EXP (S.NULL loc) => loc
      | SQL_EXP (S.TRUE loc) => loc
      | SQL_EXP (S.FALSE loc) => loc
      | SQL_EXP (S.COLUMN1 (_, loc)) => loc
      | SQL_EXP (S.COLUMN2 (_, _, loc)) => loc
      | SQL_EXP (S.KWEXP (_, _, loc)) => loc
      | SQL_EXP (S.EXP_SUBQUERY (_, _, loc)) => loc
      | SQL_EXP (S.OP1 (_, _, loc)) => loc
      | SQL_EXP (S.OP2 (_, _, _, loc)) => loc
      | SQL_EXP (S.ID (_, _, loc)) => loc
      | SQL_EXP (S.PAREN (_, loc)) => loc
      | SQL_EXP (S.APP (_, _, loc)) => loc
      | SQL_EXP (S.INFIX (_, _, _, loc)) => loc
      | SQL_EXP (S.CAST (_, _, loc)) => loc
      | SQL_EXP (S.TUPLE (_, loc)) => loc
      | SQL_KWEXP (S.EXISTS (_, loc)) => loc
      | SQL_TABLE (S.TABLE (_, _, loc)) => loc
      | SQL_TABLE (S.TABLE_AS (_, _, loc)) => loc
      | SQL_TABLE (S.TABLE_INNER_JOIN (_, _, _, _, loc)) => loc
      | SQL_TABLE (S.TABLE_CROSS_JOIN (_, _, loc)) => loc
      | SQL_TABLE (S.TABLE_NATURAL_JOIN (_, _, loc)) => loc
      | SQL_TABLE (S.TABLE_SUBQUERY (_, _, loc)) => loc
      | SQL_TABLE (S.TABLE_PAREN (_, loc)) => loc
      | SQL_FROM (S.FROM (_, loc)) => loc
      | SQL_FROM (S.FROM_EMBED (_, loc)) => loc
      | SQL_WHR (S.WHERE (_, loc)) => loc
      | SQL_WHR (S.WHERE_EMBED (_, loc)) => loc
      | SQL_GROUPBY (S.GROUPBY (_, _, loc)) => loc
      | SQL_ORDERBY (S.ORDERBY (_, loc)) => loc
      | SQL_ORDERBY (S.ORDERBY_EMBED (_, loc)) => loc
      | SQL_LIMIT (S.LIMIT (_, _, loc)) => loc
      | SQL_LIMIT (S.LIMIT_EMBED (_, loc)) => loc
      | SQL_OFFSET (S.OFFSET (_, _, loc)) => loc
      | SQL_OFFSET (S.OFFSET_EMBED (_, loc)) => loc
      | SQL_SELECT (S.SELECT (_, _, loc)) => loc
      | SQL_SELECT (S.SELECT_EMBED (_, loc)) => loc
      | SQL_QUERY (S.QUERY (_, _, _, _, _, _, loc)) => loc
      | SQL_QUERY (S.QUERY_EMBED (_, loc)) => loc
      | SQL_ORDER_KEY (_, _, loc) => loc
      | SQL_SELECT_ROW (_, _, loc) => loc
      | SQL_GROUPBY_CLAUSE (_, loc) => loc
      | SQL_HAVING_CLAUSE (_, loc) => loc
      | SQL_LIMIT_CLAUSE (_, loc) => loc
      | SQL_LIMIT_OFFSET_CLAUSE (_, loc) => loc
      | SQL_OFFSET_CLAUSE (_, _, loc) => loc
      | SQL_FETCH_CLAUSE (_, _, _, loc) => loc
      | SQL_INSERT_VALUE (S.VALUE exp) => getLoc (SQL_EXP exp)
      | SQL_INSERT_VALUE (S.DEFAULT loc) => loc
      | SQL_INSERT_ROW (_, loc) => loc
      | SQL_INSERT_VALUES (S.INSERT_VALUES (_, loc)) => loc
      | SQL_INSERT_VALUES (S.INSERT_VAR (_, loc)) => loc
      | SQL_INSERT_VALUES (S.INSERT_SELECT query) => getLoc (SQL_QUERY query)
      | SQL_INSERT_LABELS (_, loc) => loc
      | SQL_SET_ROW (_, _, loc) => loc
      | SQL_SET (_, loc) => loc
      | SQL_CON (S.QRY query) => getLoc (SQL_QUERY query)
      | SQL_CON (S.SEL select) => getLoc (SQL_SELECT select)
      | SQL_CON (S.FRM from) => getLoc (SQL_FROM from)
      | SQL_CON (S.WHR whr) => getLoc (SQL_WHR whr)
      | SQL_CON (S.ORD orderby) => getLoc (SQL_ORDERBY orderby)
      | SQL_CON (S.OFF offset) => getLoc (SQL_OFFSET offset)
      | SQL_CON (S.LMT limit) => getLoc (SQL_LIMIT limit)
      | SQL_CON (S.INSERT_LABELED (_, _, _, loc)) => loc
      | SQL_CON (S.INSERT_NOLABEL (_, _, loc)) => loc
      | SQL_CON (S.UPDATE (_, _, _, loc)) => loc
      | SQL_CON (S.DELETE (_, _, loc)) => loc
      | SQL_CON (S.BEGIN loc) => loc
      | SQL_CON (S.COMMIT loc) => loc
      | SQL_CON (S.ROLLBACK loc) => loc
      | SQL_STEP (S.STEP (_, _, loc)) => loc
      | SQL_STEP (S.STEP_EMBED (_, loc)) => loc
      | SQL_BODY (S.CON (_, _, loc)) => loc
      | SQL_BODY (S.EXP exp) => getLoc (SQL_EXP exp)
      | SQL_BODY (S.SEQ (_, loc)) => loc
      | SQL_BODY (S.BODYPAREN (_, loc)) => loc
      | SQL_TOP (S.SQLSERVER (_, _, loc)) => loc
      | SQL_TOP (S.SQL (_, loc)) => loc
      | SQL_TOP (S.SQLFN (_, _, loc)) => loc
      | OPAQUE_IMPL (I.IMPL_TY (_, loc)) => loc
      | OPAQUE_IMPL (I.IMPL_TUPLE loc) => loc
      | OPAQUE_IMPL (I.IMPL_RECORD loc) => loc
      | OPAQUE_IMPL (I.IMPL_FUNC loc) => loc
      | OVERLOAD_INSTANCE (I.INST_OVERLOAD (_, _, _, loc)) => loc
      | OVERLOAD_INSTANCE (I.INST_LONGVID (_, loc)) => loc
      | OVERLOAD_INSTANCE (I.INST_PAREN (_, loc)) => loc
      | OVERLOAD_MRULE (_, _, loc) => loc
      | OVERLOAD_CASE (_, _, _, loc) => loc
      | IVALBIND (I.VAL_EXTERN (_, _, loc)) => loc
      | IVALBIND (I.VAL_ALIAS (_, _, loc)) => loc
      | IVALBIND (I.VAL_BUILTIN (_, _, _, loc)) => loc
      | IVALBIND (I.VAL_OVERLOAD (_, _, loc)) => loc
      | ITYPDESC (_, _, _, loc) => loc
      | IDEC (I.VAL (_, loc)) => loc
      | IDEC (I.TYPE (_, loc)) => loc
      | IDEC (I.EQTYPE (_, loc)) => loc
      | IDEC (I.DATATYPE (_, _, loc)) => loc
      | IDEC (I.DATATYPEREP (_, _, loc)) => loc
      | IDEC (I.TYPEBUILTIN (_, _, loc)) => loc
      | IDEC (I.EXCEPTION (_, loc)) => loc
      | IDEC (I.STRUCTURE (_, loc)) => loc
      | IDEC (I.SEMICOLON loc) => loc
      | ISTREXP (I.STRBASIC (_, loc)) => loc
      | ISTREXP (I.STRID (_, loc)) => loc
      | ISTREXP (I.STRAPP (_, _, loc)) => loc
      | ISTRBIND (_, _, loc) => loc
      | IFUNBIND (_, _, _, loc) => loc
      | ITOPDEC (I.DEC dec) => getLoc (IDEC dec)
      | ITOPDEC (I.FUNCTOR (_, loc)) => loc
      | ITOPDEC (I.INFIX (_, _, loc)) => loc
      | ITOPDEC (I.INFIXR (_, _, loc)) => loc
      | ITOPDEC (I.NONFIX (_, loc)) => loc
      | IREQUIRE (I.REQUIRE (_, _, loc)) => loc
      | IREQUIRE (I.REQUIRE_LOCAL (_, _, loc)) => loc
      | IREQUIRE (I.USE_LOCAL (_, loc)) => loc
      | IREQUIRE (I.REQSEMICOLON loc) => loc
      | IINCLUDE (I.INCLUDE (_, loc)) => loc
      | IINCLUDE (I.INCSEMICOLON loc) => loc
      | ISIGDEC (I.SIGNATURE (_, loc)) => loc
      | ISIGDEC (I.SIGSEMICOLON loc) => loc
      | ITOP (I.INTERFACE (_, _, loc)) => loc
      | ITOP (I.INCLUDES (_, _, loc)) => loc

  fun childrenOfLongid con ids =
      case rev ids of
        nil => nil
      | [x] => [con x]
      | last :: rests => rev (con last :: map STRID rests)

  fun getChildren node =
      case node of
        ID _ => nil
      | VID _ => nil
      | LONGVID (ids, loc) => childrenOfLongid VID ids
      | TYCON _ => nil
      | LONGTYCON (ids, loc) => childrenOfLongid TYCON ids
      | LAB _ => nil
      | TYVAR _ => nil
      | TYVARSEQ (tyvars, loc) => map TYVAR tyvars
      | OP_LONGVID (_, longvid, loc) => [LONGVID longvid]
      | TY (A.TYVAR _) => nil
      | TY (A.TYRECORD (tyrows, _, loc)) => map TYROW tyrows
      | TY (A.TYCON (tyseq, tycon, loc)) => [TYSEQ tyseq, LONGTYCON tycon]
      | TY (A.TYTUPLE (tys, loc)) => map TY tys
      | TY (A.TYFUN (ty1, ty2, loc)) => [TY ty1, TY ty2]
      | TY (A.TYPAREN (ty, loc)) => [TY ty]
      | TY (A.TYWILD loc) => nil
      | TY (A.TYVAR_FREE tyvar) => [KINDED_TYVAR tyvar]
      | TY (A.TYPOLY (tyvars, ty, loc)) => map KINDED_TYVAR tyvars @ [TY ty]
      | KIND (A.UNIV (ids, loc)) => map ID ids
      | KIND (A.REC (ids, tyrows, loc)) => map ID ids @ map TYROW tyrows
      | KINDED_TYVAR (tyvar, kind, loc) => [TYVAR tyvar, KIND kind]
      | TYROW (lab, ty, loc) => [LAB lab, TY ty]
      | TYSEQ (tys, loc) => map TY tys
      | KINDED_TYVARSEQ (tyvars, loc) => map KINDED_TYVAR tyvars
      | FFI_ATTR (ids, loc) => map ID ids
      | FFI_TY (A.FFITYVAR tyvar) => [TYVAR tyvar]
      | FFI_TY (A.FFITYRECORD (tyrows, loc)) => map FFI_TYROW tyrows
      | FFI_TY (A.FFITYCON (tyseq, tycon, loc)) =>
        [FFI_TYSEQ tyseq, LONGTYCON tycon]
      | FFI_TY (A.FFITYTUPLE (tys, loc)) => map FFI_TY tys
      | FFI_TY (A.FFITYFUN (attrs, arg, ret, loc)) =>
        [FFI_ATTR attrs, FFI_ARG arg, FFI_RET ret]
      | FFI_TY (A.FFITYPAREN (ty, loc)) => [FFI_TY ty]
      | FFI_TYROW (lab, ty, loc) => [LAB lab, FFI_TY ty]
      | FFI_TYSEQ (tys, loc) => map FFI_TY tys
      | FFI_ARG (tys, NONE, loc) => map FFI_TY tys
      | FFI_ARG (tys, SOME tys2, loc) => map FFI_TY (tys @ tys2)
      | FFI_RET (tys, loc) => map FFI_TY tys
      | STRID _ => nil
      | SIGID _ => nil
      | FUNID _ => nil
      | LONGSTRID (ids, loc) => map STRID ids
      | OP_VID (_, id, loc) => [VID id]
      | REQUIRE_PATH _ => nil
      | EXTERN_NAME _ => nil
      | EXIST_QUANT (tyvars, loc) => map KINDED_TYVAR tyvars
      | PAT (A.PATWILD _) => nil
      | PAT (A.PATCONST _) => nil
      | PAT (A.PATID id) => [OP_LONGVID id]
      | PAT (A.PATRECORD (patrows, flex, loc)) => map PATROW patrows
      | PAT (A.PATTUPLE (pats, loc)) => map PAT pats
      | PAT (A.PATLIST (pats, loc)) => map PAT pats
      | PAT (A.PATPAREN (pat, loc)) => [PAT pat]
      | PAT (A.PATAPP (pat1, pat2, loc)) => [PAT pat1, PAT pat2]
      | PAT (A.PATINFIX (pat1, vid, pat2, loc)) => [PAT pat1, VID vid, PAT pat2]
      | PAT (A.PATTYPED (pat, ty, loc)) => [PAT pat, TY ty]
      | PAT (A.PATAS (id, NONE, pat, loc)) => [OP_VID id, PAT pat]
      | PAT (A.PATAS (id, SOME ty, pat, loc)) => [OP_VID id, TY ty, PAT pat]
      | PATROW (A.PATROW (lab, pat, loc)) => [LAB lab, PAT pat]
      | PATROW (A.PATROWVAR (vid, NONE, NONE, loc)) => [VID vid]
      | PATROW (A.PATROWVAR (vid, NONE, SOME pat, loc)) => [VID vid, PAT pat]
      | PATROW (A.PATROWVAR (vid, SOME ty, NONE, loc)) => [VID vid, TY ty]
      | PATROW (A.PATROWVAR (vid, SOME ty, SOME pat, loc)) =>
        [VID vid, TY ty, PAT pat]
      | EXBIND (A.EXBIND (id, NONE, loc)) => [OP_VID id]
      | EXBIND (A.EXBIND (id, SOME ty, loc)) => [OP_VID id, TY ty]
      | EXBIND (A.EXBINDREP (id, longid, loc)) => [OP_VID id, OP_LONGVID longid]
      | TYPBIND (tyvarseq, tycon, ty, loc) =>
        [TYVARSEQ tyvarseq, TYCON tycon, TY ty]
      | CONBIND (id, NONE, loc) => [OP_VID id]
      | CONBIND (id, SOME ty, loc) => [OP_VID id, TY ty]
      | DATBIND (tyvarseq, tycon, conbinds, loc) =>
        TYVARSEQ tyvarseq :: TYCON tycon :: map CONBIND conbinds
      | EXP (A.EXPCONST _) => nil
      | EXP (A.EXPID id) => [OP_LONGVID id]
      | EXP (A.EXPRECORD (exprows, loc)) => map EXPROW exprows
      | EXP (A.EXPSELECT (lab, loc)) => [LAB lab]
      | EXP (A.EXPTUPLE (exps, loc)) => map EXP exps
      | EXP (A.EXPLIST (exps, loc)) => map EXP exps
      | EXP (A.EXPSEQ (exps, loc)) => map EXP exps
      | EXP (A.EXPLET (decs, exps, loc)) => map DEC decs @ map EXP exps
      | EXP (A.EXPPAREN (exp, loc)) => [EXP exp]
      | EXP (A.EXPAPP (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPINFIX (exp1, vid, exp2, loc)) => [EXP exp1, VID vid, EXP exp2]
      | EXP (A.EXPTYPED (exp, ty, loc)) => [EXP exp, TY ty]
      | EXP (A.EXPANDALSO (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPORELSE (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPHANDLE (exp, mrules, loc)) => EXP exp :: map MRULE mrules
      | EXP (A.EXPRAISE (exp, loc)) => [EXP exp]
      | EXP (A.EXPIF (exp1, exp2, exp3, loc)) => [EXP exp1, EXP exp2, EXP exp3]
      | EXP (A.EXPWHILE (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPCASE (exp, mrules, loc)) => EXP exp :: map MRULE mrules
      | EXP (A.EXPFN (mrules, loc)) => map MRULE mrules
      | EXP (A.EXPSIZEOF (ty, loc)) => [TY ty]
      | EXP (A.EXPRECORD_UPDATE (exp, exprows, loc)) =>
        EXP exp :: map EXPROW exprows
      | EXP (A.EXPTUPLE_UPDATE (exp, exps, loc)) => map EXP (exp :: exps)
      | EXP (A.EXPIMPORT_NAME (name, ty, loc)) => [EXTERN_NAME name, FFI_TY ty]
      | EXP (A.EXPIMPORT_EXP (exp, ty, loc)) => [EXP exp, FFI_TY ty]
      | EXP (A.EXPSQL sqlexp) => [SQL_TOP sqlexp]
      | EXP (A.EXPFOREACH_DATA (id, exp1, exp2, pat, exp3, exp4, loc)) =>
        [VID id, EXP exp1, EXP exp2, PAT pat, EXP exp3, EXP exp4]
      | EXP (A.EXPFOREACH_ARRAY (id, exp1, pat, exp2, exp3, loc)) =>
        [VID id, EXP exp1, PAT pat, EXP exp2, EXP exp3]
      | EXP (A.EXPJOIN (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPEXTEND (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPUPDATE1 (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPUPDATE2 (exp1, exp2, loc)) => [EXP exp1, EXP exp2]
      | EXP (A.EXPDYNAMIC_AS (exp, ty, loc)) => [EXP exp, TY ty]
      | EXP (A.EXPDYNAMIC_OF (exp, ty, loc)) => [EXP exp, TY ty]
      | EXP (A.EXPDYNAMICVIEW (exp, ty, loc)) => [EXP exp, TY ty]
      | EXP (A.EXPDYNAMICNULL (ty, loc)) => [TY ty]
      | EXP (A.EXPDYNAMICTOP (ty, loc)) => [TY ty]
      | EXP (A.EXPDYNAMICCASE (exp, mrules, loc)) =>
        EXP exp :: map DYNAMIC_MRULE mrules
      | EXP (A.EXPREIFYTY (ty, loc)) => [TY ty]
      | VALBIND (A.VALBIND (pat, exp, loc)) => [PAT pat, EXP exp]
      | VALBIND (A.VALREC (valbinds, loc)) => map VALBIND valbinds
      | DEC (A.DECVAL (tyvarseq, valbinds, loc)) =>
        KINDED_TYVARSEQ tyvarseq :: map VALBIND valbinds
      | DEC (A.DECFUN (tyvarseq, fvalbinds, loc)) =>
        KINDED_TYVARSEQ tyvarseq :: map FVALBIND fvalbinds
      | DEC (A.DECTYPE (typbinds, loc)) => map TYPBIND typbinds
      | DEC (A.DECDATATYPE (datbinds, typbinds, loc)) =>
        map DATBIND datbinds @ map TYPBIND typbinds
      | DEC (A.DECDATATYPEREP (id, longid, loc)) => [TYCON id, LONGTYCON longid]
      | DEC (A.DECABSTYPE (datbinds, typbinds, decs, loc)) =>
        map DATBIND datbinds @ map TYPBIND typbinds @ map DEC decs
      | DEC (A.DECEXCEPTION (exbinds, loc)) => map EXBIND exbinds
      | DEC (A.DECLOCAL (decs1, decs2, loc)) => map DEC (decs1 @ decs2)
      | DEC (A.DECOPEN (ids, loc)) => map LONGSTRID ids
      | DEC (A.DECSEMICOLON loc) => nil
      | DEC (A.DECINFIX (prec, ids, loc)) => map VID ids
      | DEC (A.DECINFIXR (prec, ids, loc)) => map VID ids
      | DEC (A.DECNONFIX (ids, loc)) => map VID ids
      | DEC (A.DECPOLYREC (pvalbinds, loc)) => map PVALBIND pvalbinds
      | EXPROW (lab, exp, loc) => [LAB lab, EXP exp]
      | MRULE (pat, exp, loc) => [PAT pat, EXP exp]
      | DYNAMIC_MRULE (exists, pat, exp, loc) =>
        [EXIST_QUANT exists, PAT pat, EXP exp]
      | FRULE (pat, NONE, exp, loc) => [PAT pat, EXP exp]
      | FRULE (pat, SOME ty, exp, loc) => [PAT pat, TY ty, EXP exp]
      | FVALBIND (frules, loc) => map FRULE frules
      | PVALBIND (vid, ty, exp, loc) => [VID vid, TY ty, EXP exp]
      | VALDESC (vid, ty, loc) => [VID vid, TY ty]
      | TYPDESC (tyvarseq, tycon, loc) => [TYVARSEQ tyvarseq, TYCON tycon]
      | CONDESC (vid, NONE, loc) => [VID vid]
      | CONDESC (vid, SOME ty, loc) => [VID vid, TY ty]
      | DATDESC (tyvarseq, tycon, condescs, loc) =>
        TYVARSEQ tyvarseq :: TYCON tycon :: map CONDESC condescs
      | EXDESC (vid, NONE, loc) => [VID vid]
      | EXDESC (vid, SOME ty, loc) => [VID vid, TY ty]
      | WHERETYPE (tyvarseq, tycon, ty, loc) =>
        [TYVARSEQ tyvarseq, LONGTYCON tycon, TY ty]
      | SPEC (A.SPECVAL (valdescs, loc)) => map VALDESC valdescs
      | SPEC (A.SPECTYPE (typdescs, loc)) => map TYPDESC typdescs
      | SPEC (A.SPECTYPEINC (typbinds, loc)) => map TYPBIND typbinds
      | SPEC (A.SPECEQTYPE (typdescs, loc)) => map TYPDESC typdescs
      | SPEC (A.SPECDATATYPE (datdescs, loc)) => map DATDESC datdescs
      | SPEC (A.SPECDATATYPEREP (tycon, longtycon, loc)) =>
        [TYCON tycon, LONGTYCON longtycon]
      | SPEC (A.SPECEXCEPTION (exdescs, loc)) => map EXDESC exdescs
      | SPEC (A.SPECSTRUCTURE (strdescs, loc)) => map STRDESC strdescs
      | SPEC (A.SPECINCLUDE (sigexp, loc)) => [SIGEXP sigexp]
      | SPEC (A.SPECINCLUDE_ID (sigids, loc)) => map SIGID sigids
      | SPEC (A.SPECSHARINGTYPE (specs, longtycons, loc)) =>
        map SPEC specs @ map LONGTYCON longtycons
      | SPEC (A.SPECSHARING (specs, longstrids, loc)) =>
        map SPEC specs @ map LONGSTRID longstrids
      | SPEC (A.SPECSEMICOLON _) => nil
      | SIGEXP (A.SIGBASIC (specs, loc)) => map SPEC specs
      | SIGEXP (A.SIGID sigid) => [SIGID sigid]
      | SIGEXP (A.SIGWHERE (sigexp, wheretypes, loc)) =>
        SIGEXP sigexp :: map WHERETYPE wheretypes
      | STRDESC (strid, sigexp, loc) => [STRID strid, SIGEXP sigexp]
      | SIGBIND (sigid, sigexp, loc) => [SIGID sigid, SIGEXP sigexp]
      | SIGCONSTRAINT (sigop, sigexp, loc) => [SIGEXP sigexp]
      | STREXP (A.STRBASIC (strdecs, loc)) => map STRDEC strdecs
      | STREXP (A.STRID id) => [LONGSTRID id]
      | STREXP (A.STRCONSTRAINT (strexp, sigop, sigexp, loc)) =>
        [STREXP strexp, SIGEXP sigexp]
      | STREXP (A.STRAPP (funid, A.FUNARG strexp, loc)) =>
        [FUNID funid, STREXP strexp]
      | STREXP (A.STRAPP (funid, A.FUNARG_DEC strdecs, loc)) =>
        FUNID funid :: map STRDEC strdecs
      | STREXP (A.STRLET (strdecs, strexp, loc)) =>
        map STRDEC strdecs @ [STREXP strexp]
      | STRDEC (A.STRDEC dec) => [DEC dec]
      | STRDEC (A.STRUCTURE (strbinds, loc)) => map STRBIND strbinds
      | STRDEC (A.STRLOCAL (strdecs1, strdecs2, loc)) =>
        map STRDEC (strdecs1 @ strdecs2)
      | STRDEC (A.STRSEMICOLON _) => nil
      | STRBIND (strid, NONE, strexp, loc) => [STRID strid, STREXP strexp]
      | STRBIND (strid, SOME sigcon, strexp, loc) =>
        [STRID strid, SIGCONSTRAINT sigcon, STREXP strexp]
      | FUNBIND (funid, A.FUNPARAM (strid, sigexp), NONE, strexp, loc) =>
        [FUNID funid, STRID strid, SIGEXP sigexp, STREXP strexp]
      | FUNBIND (funid, A.FUNPARAM (strid, sigexp), SOME sigcon, strexp, loc) =>
        [FUNID funid, STRID strid, SIGEXP sigexp, SIGCONSTRAINT sigcon,
         STREXP strexp]
      | FUNBIND (funid, A.FUNPARAM_SPEC specs, NONE, strexp, loc) =>
        FUNID funid :: map SPEC specs @ [STREXP strexp]
      | FUNBIND (funid, A.FUNPARAM_SPEC specs, SOME sigcon, strexp, loc) =>
        FUNID funid :: map SPEC specs @ [SIGCONSTRAINT sigcon, STREXP strexp]
      | TOPDEC (A.TOPSTRDEC strdec) => [STRDEC strdec]
      | TOPDEC (A.TOPSIGNATURE (sigbinds, loc)) => map SIGBIND sigbinds
      | TOPDEC (A.TOPFUNCTOR (funbinds, loc)) => map FUNBIND funbinds
      | TOPDEC (A.TOPEXP (exp, loc)) => [EXP exp]
      | TOP (A.TOPDEC (topdecs, loc)) => map TOPDEC topdecs
      | TOP (A.USE (path, loc)) => [REQUIRE_PATH path]
      | TOP (A.USE' (path, loc)) => [REQUIRE_PATH path]
      | TOP (A.TOPSEMICOLON _) => nil
      | INTERFACE (path, loc) => [REQUIRE_PATH path]
      | COMPILE_UNIT (NONE, tops, loc) => map TOP tops
      | COMPILE_UNIT (SOME interface, tops, loc) =>
        INTERFACE interface :: map TOP tops
      | SQL_TABLE_SELECTOR (vid, lab, loc) => [VID vid, LAB lab]
      | SQL_EXP (S.EXP_EMBED (exp, loc)) => [EXP exp]
      | SQL_EXP (S.CONST _) => nil
      | SQL_EXP (S.NULL _) => nil
      | SQL_EXP (S.TRUE _) => nil
      | SQL_EXP (S.FALSE _) => nil
      | SQL_EXP (S.COLUMN1 (lab, loc)) => [LAB lab]
      | SQL_EXP (S.COLUMN2 (lab1, lab2, loc)) => [LAB lab1, LAB lab2]
      | SQL_EXP (S.KWEXP (sql, kwexp, loc)) => [SQL_KWEXP kwexp]
      | SQL_EXP (S.EXP_SUBQUERY (sql, query, loc)) => [SQL_QUERY query]
      | SQL_EXP (S.OP1 (op1, exp, loc)) => [SQL_EXP exp]
      | SQL_EXP (S.OP2 (op2, exp1, exp2, loc)) => [SQL_EXP exp1, SQL_EXP exp2]
      | SQL_EXP (S.ID id) => [OP_LONGVID id]
      | SQL_EXP (S.PAREN (exp, loc)) => [SQL_EXP exp]
      | SQL_EXP (S.APP (exp1, exp2, loc)) => [SQL_EXP exp1, SQL_EXP exp2]
      | SQL_EXP (S.INFIX (exp1, vid, exp2, loc)) =>
        [SQL_EXP exp1, VID vid, SQL_EXP exp2]
      | SQL_EXP (S.CAST (vid, exp, loc)) => [VID vid, SQL_EXP exp]
      | SQL_EXP (S.TUPLE (exps, loc)) => map SQL_EXP exps
      | SQL_KWEXP (S.EXISTS (query, loc)) => [SQL_QUERY query]
      | SQL_TABLE (S.TABLE table) => [SQL_TABLE_SELECTOR table]
      | SQL_TABLE (S.TABLE_AS (table, lab, loc)) => [SQL_TABLE table, LAB lab]
      | SQL_TABLE (S.TABLE_INNER_JOIN (table1, inner, table2, exp, loc)) =>
        [SQL_TABLE table1, SQL_TABLE table2, SQL_EXP exp]
      | SQL_TABLE (S.TABLE_CROSS_JOIN (table1, table2, loc)) =>
        [SQL_TABLE table1, SQL_TABLE table2]
      | SQL_TABLE (S.TABLE_NATURAL_JOIN (table1, table2, loc)) =>
        [SQL_TABLE table1, SQL_TABLE table2]
      | SQL_TABLE (S.TABLE_SUBQUERY (sql, query, loc)) => [SQL_QUERY query]
      | SQL_TABLE (S.TABLE_PAREN (table, loc)) => [SQL_TABLE table]
      | SQL_FROM (S.FROM (tables, loc)) => map SQL_TABLE tables
      | SQL_FROM (S.FROM_EMBED (exp, loc)) => [EXP exp]
      | SQL_WHR (S.WHERE (exp, loc)) => [SQL_EXP exp]
      | SQL_WHR (S.WHERE_EMBED (exp, loc)) => [EXP exp]
      | SQL_GROUPBY (S.GROUPBY (groupby, NONE, loc)) =>
        [SQL_GROUPBY_CLAUSE groupby]
      | SQL_GROUPBY (S.GROUPBY (groupby, SOME having, loc)) =>
        [SQL_GROUPBY_CLAUSE groupby, SQL_HAVING_CLAUSE having]
      | SQL_ORDERBY (S.ORDERBY (keys, loc)) => map SQL_ORDER_KEY keys
      | SQL_ORDERBY (S.ORDERBY_EMBED (exp, loc)) => [EXP exp]
      | SQL_LIMIT (S.LIMIT (limit, NONE, loc)) => [SQL_LIMIT_CLAUSE limit]
      | SQL_LIMIT (S.LIMIT (limit, SOME offset, loc)) =>
        [SQL_LIMIT_CLAUSE limit, SQL_LIMIT_OFFSET_CLAUSE offset]
      | SQL_LIMIT (S.LIMIT_EMBED (exp, loc)) => [EXP exp]
      | SQL_OFFSET (S.OFFSET (offset, NONE, loc)) => [SQL_OFFSET_CLAUSE offset]
      | SQL_OFFSET (S.OFFSET (offset, SOME fetch, loc)) =>
        [SQL_OFFSET_CLAUSE offset, SQL_FETCH_CLAUSE fetch]
      | SQL_OFFSET (S.OFFSET_EMBED (exp, loc)) => [EXP exp]
      | SQL_SELECT (S.SELECT (distinct, (rows, loc1), loc)) =>
        map SQL_SELECT_ROW rows
      | SQL_SELECT (S.SELECT_EMBED (exp, loc)) => [EXP exp]
      | SQL_QUERY (S.QUERY (select, from, whr, group, order, offset, loc)) =>
        [SQL_SELECT select, SQL_FROM from]
        @ (case whr of SOME whr => [SQL_WHR whr] | NONE => nil)
        @ (case group of SOME group => [SQL_GROUPBY group] | NONE => nil)
        @ (case order of SOME order => [SQL_ORDERBY order] | NONE => nil)
        @ (case offset of
             SOME (S.OFFSET_CLAUSE offset) => [SQL_OFFSET offset]
           | SOME (S.LIMIT_CLAUSE limit) => [SQL_LIMIT limit]
           | NONE => nil)
      | SQL_QUERY (S.QUERY_EMBED (exp, loc)) => [EXP exp]
      | SQL_ORDER_KEY (exp, asc, loc) => [SQL_EXP exp]
      | SQL_SELECT_ROW (exp, NONE, loc) => [SQL_EXP exp]
      | SQL_SELECT_ROW (exp, SOME lab, loc) => [SQL_EXP exp, LAB lab]
      | SQL_GROUPBY_CLAUSE (exps, loc) => map SQL_EXP exps
      | SQL_HAVING_CLAUSE (exp, loc) => [SQL_EXP exp]
      | SQL_LIMIT_CLAUSE (NONE, loc) => nil
      | SQL_LIMIT_CLAUSE (SOME exp, loc) => [SQL_EXP exp]
      | SQL_LIMIT_OFFSET_CLAUSE (exp, loc) => [SQL_EXP exp]
      | SQL_OFFSET_CLAUSE (exp, rows, loc) => [SQL_EXP exp]
      | SQL_FETCH_CLAUSE (first, NONE, rows, loc) => nil
      | SQL_FETCH_CLAUSE (first, SOME exp, rows, loc) => [SQL_EXP exp]
      | SQL_INSERT_VALUE (S.VALUE exp) => [SQL_EXP exp]
      | SQL_INSERT_VALUE (S.DEFAULT _) => nil
      | SQL_INSERT_ROW (values, loc) => map SQL_INSERT_VALUE values
      | SQL_INSERT_VALUES (S.INSERT_VALUES (rows, loc)) =>
        map SQL_INSERT_ROW rows
      | SQL_INSERT_VALUES (S.INSERT_VAR (id, loc)) => [OP_LONGVID id]
      | SQL_INSERT_VALUES (S.INSERT_SELECT query) => [SQL_QUERY query]
      | SQL_INSERT_LABELS (labs, loc) => map LAB labs
      | SQL_SET_ROW (lab, exp, loc) => [LAB lab, SQL_EXP exp]
      | SQL_SET (rows, loc) => map SQL_SET_ROW rows
      | SQL_CON (S.QRY query) => [SQL_QUERY query]
      | SQL_CON (S.SEL select) => [SQL_SELECT select]
      | SQL_CON (S.FRM from) => [SQL_FROM from]
      | SQL_CON (S.WHR whr) => [SQL_WHR whr]
      | SQL_CON (S.ORD orderby) => [SQL_ORDERBY orderby]
      | SQL_CON (S.OFF offset) => [SQL_OFFSET offset]
      | SQL_CON (S.LMT limit) => [SQL_LIMIT limit]
      | SQL_CON (S.INSERT_LABELED (table, labels, values, loc)) =>
        [SQL_TABLE_SELECTOR table, SQL_INSERT_LABELS labels,
         SQL_INSERT_VALUES values]
      | SQL_CON (S.INSERT_NOLABEL (table, query, loc)) =>
        [SQL_TABLE_SELECTOR table, SQL_QUERY query]
      | SQL_CON (S.UPDATE (table, set, NONE, loc)) =>
        [SQL_TABLE_SELECTOR table, SQL_SET set]
      | SQL_CON (S.UPDATE (table, set, SOME whr, loc)) =>
        [SQL_TABLE_SELECTOR table, SQL_SET set, SQL_WHR whr]
      | SQL_CON (S.DELETE (table, NONE, loc)) =>
        [SQL_TABLE_SELECTOR table]
      | SQL_CON (S.DELETE (table, SOME whr, loc)) =>
        [SQL_TABLE_SELECTOR table, SQL_WHR whr]
      | SQL_CON (S.BEGIN _) => nil
      | SQL_CON (S.COMMIT _) => nil
      | SQL_CON (S.ROLLBACK _) => nil
      | SQL_STEP (S.STEP (sql, con, loc)) => [SQL_CON con]
      | SQL_STEP (S.STEP_EMBED (exp, loc)) => [EXP exp]
      | SQL_BODY (S.CON (sql, con, loc)) => [SQL_CON con]
      | SQL_BODY (S.EXP exp) => [SQL_EXP exp]
      | SQL_BODY (S.SEQ (steps, loc)) => map SQL_STEP steps
      | SQL_BODY (S.BODYPAREN (body, loc)) => [SQL_BODY body]
      | SQL_TOP (S.SQLSERVER (NONE, ty, loc)) => [TY ty]
      | SQL_TOP (S.SQLSERVER (SOME exp, ty, loc)) => [EXP exp, TY ty]
      | SQL_TOP (S.SQL (body, loc)) => [SQL_BODY body]
      | SQL_TOP (S.SQLFN (pat, body, loc)) => [PAT pat, SQL_BODY body]
      | OPAQUE_IMPL (I.IMPL_TY id) => [LONGTYCON id]
      | OPAQUE_IMPL (I.IMPL_TUPLE _) => nil
      | OPAQUE_IMPL (I.IMPL_RECORD _) => nil
      | OPAQUE_IMPL (I.IMPL_FUNC _) => nil
      | OVERLOAD_INSTANCE (I.INST_OVERLOAD ovcase) => [OVERLOAD_CASE ovcase]
      | OVERLOAD_INSTANCE (I.INST_LONGVID id) => [LONGVID id]
      | OVERLOAD_INSTANCE (I.INST_PAREN (inst, loc)) => [OVERLOAD_INSTANCE inst]
      | OVERLOAD_MRULE (ty, inst, loc) => [TY ty, OVERLOAD_INSTANCE inst]
      | OVERLOAD_CASE (tyvar, ty, mrules, loc) =>
        TYVAR tyvar :: TY ty :: map OVERLOAD_MRULE mrules
      | IVALBIND (I.VAL_EXTERN (id, ty, loc)) => [VID id, TY ty]
      | IVALBIND (I.VAL_ALIAS (id, longid, loc)) => [VID id, LONGVID longid]
      | IVALBIND (I.VAL_BUILTIN (id1, id2, ty, loc)) =>
        [VID id1, VID id2, TY ty]
      | IVALBIND (I.VAL_OVERLOAD (id, ovcase, loc)) =>
        [VID id, OVERLOAD_CASE ovcase]
      | ITYPDESC (tyvarseq, tycon, impl, loc) =>
        [TYVARSEQ tyvarseq, TYCON tycon, OPAQUE_IMPL impl]
      | IDEC (I.VAL (valbind, loc)) => [IVALBIND valbind]
      | IDEC (I.TYPE (typbinds, loc)) =>
        map (fn I.TYPBIND typbind => TYPBIND typbind
              | I.TYPDESC typdesc => ITYPDESC typdesc)
            typbinds
      | IDEC (I.EQTYPE (typdescs, loc)) => map ITYPDESC typdescs
      | IDEC (I.DATATYPE (datbinds, typbinds, loc)) =>
        map DATBIND datbinds @ map TYPBIND typbinds
      | IDEC (I.DATATYPEREP (tycon, longtycon, loc)) =>
        [TYCON tycon, LONGTYCON longtycon]
      | IDEC (I.TYPEBUILTIN (tycon1, tycon2, loc)) =>
        [TYCON tycon1, TYCON tycon2]
      | IDEC (I.EXCEPTION (exbinds, loc)) => map EXBIND exbinds
      | IDEC (I.STRUCTURE (strbind, loc)) => [ISTRBIND strbind]
      | IDEC (I.SEMICOLON _) => nil
      | ISTREXP (I.STRBASIC (decs, loc)) => map IDEC decs
      | ISTREXP (I.STRID id) => [LONGSTRID id]
      | ISTREXP (I.STRAPP (funid, strid, loc)) => [FUNID funid, LONGSTRID strid]
      | ISTRBIND (strid, strexp, loc) => [STRID strid, ISTREXP strexp]
      | IFUNBIND (funid, A.FUNPARAM (strid, sigexp), strexp, loc) =>
        [FUNID funid, STRID strid, SIGEXP sigexp, ISTREXP strexp]
      | IFUNBIND (funid, A.FUNPARAM_SPEC specs, strexp, loc) =>
        FUNID funid :: map SPEC specs @ [ISTREXP strexp]
      | ITOPDEC (I.DEC dec) => [IDEC dec]
      | ITOPDEC (I.FUNCTOR (funbind, loc)) => [IFUNBIND funbind]
      | ITOPDEC (I.INFIX (prec, ids, loc)) => map VID ids
      | ITOPDEC (I.INFIXR (prec, ids, loc)) => map VID ids
      | ITOPDEC (I.NONFIX (ids, loc)) => map VID ids
      | IREQUIRE (I.REQUIRE (path, ids, loc)) => REQUIRE_PATH path :: map ID ids
      | IREQUIRE (I.REQUIRE_LOCAL (path, ids, loc)) =>
        REQUIRE_PATH path :: map ID ids
      | IREQUIRE (I.USE_LOCAL (path, loc)) => [REQUIRE_PATH path]
      | IREQUIRE (I.REQSEMICOLON _) => nil
      | IINCLUDE (I.INCLUDE (path, loc)) => [REQUIRE_PATH path]
      | IINCLUDE (I.INCSEMICOLON _) => nil
      | ISIGDEC (I.SIGNATURE (sigbinds, loc)) => map SIGBIND sigbinds
      | ISIGDEC (I.SIGSEMICOLON _) => nil
      | ITOP (I.INTERFACE (requires, topdecs, loc)) =>
        map IREQUIRE requires @ map ITOPDEC topdecs
      | ITOP (I.INCLUDES (includes, sigdecs, loc)) =>
        map IINCLUDE includes @ map ISIGDEC sigdecs

end
