structure UNIXODBC = struct

type SQLHANDLE = unit ptr
type SQLHENV = SQLHANDLE
type SQLHDBC = SQLHANDLE
type SQLHSTMT = SQLHANDLE
type SQLSMALLINT = int (* TODO: should be singed short int *)
type SQLUSMALLINT = word (* TODO: typedef unsigned short SQLUSMALLINT *)
type SQLINTEGER = int (* maybe 32 bit integer on any platform *)
type SQLRETURN = SQLSMALLINT
type SQLCHAR_PTR = string (* typedef unsigned char SQLCHAR *)
type SQLPOINTER = Word8Array.array (* typedef void * SQLPOINTER *)
type SQLPOINTER_AS_INT = int (* typedef void * SQLPOINTER *)
type SQLLEN = int (* maybe integer of same size as pointer *)
type SQLSETPOSIROW = SQLUSMALLINT
type SQLCHAR_array = Word8Array.array

(* handle type *)
val SQL_HANDLE_DBC = 2
val SQL_HANDLE_DESC = 4
val SQL_HANDLE_ENV = 1
val SQL_HANDLE_STMT = 3

val NULL_HANDLE = Pointer.NULL () : SQLHANDLE
val ATTR_ODBC_VERSION = 200
val OV_ODBC3 = 3
val NTS = ~3
val NULL_DATA = ~1
val C_CHAR = 1
val POSITION = 0w0
val REFRESH = 0w1
val LOCK_NO_CHANGE = 0w0
val ATTR_ROW_ARRAY_SIZE = 27
val COLUMN_NAME = 0w4
val DATA_TYPE = 0w5
val NULLABLE = 0w11

val SQL_SUCCESS = 0
val SQL_SUCCESS_WITH_INFO = 1
val SQL_INALID_HANDLE = ~2
val SQL_ERROR = ~1
val SQL_STILL_EXECUTING = 2
val SQL_NEED_DATA = 99
val SQL_NO_DATA = 100
(* val SQL_PARAM_DATA_AVAILABLE *)

fun lazy f =
    let
        val r = ref NONE
    in
     fn () =>
        case !r of
            SOME x => x
          | NONE =>
            let val x = f ()
            in r := SOME x; x
            end
    end

val lib =
    lazy (fn _ =>
             DynamicLink.dlopen
                 (case OS.Process.getEnv "SMLSHARP_LIBODBC" of
                    SOME x => x
                  | NONE =>
                    case SMLSharp_Config.DLLEXT () of
                      "so" => "libodbc.so.2"
                    | dll => "libodbc.2." ^ dll))

(* Connecting to data source *)
val AllocHandle =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLAllocHandle")
		  : _import (SQLSMALLINT, SQLHANDLE, SQLHANDLE ref)
		            -> SQLRETURN)
val Connect =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLConnect")
		  : _import (SQLHDBC, SQLCHAR_PTR, SQLSMALLINT,
			              SQLCHAR_PTR, SQLSMALLINT,
			              SQLCHAR_PTR, SQLSMALLINT) -> SQLRETURN)
(* Setting and retrieving driver attributes *)
val SetEnvAttr =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLSetEnvAttr")
		  : _import (SQLHENV, SQLINTEGER, SQLPOINTER_AS_INT,
			     SQLINTEGER)
		            -> SQLRETURN)
val SetStmtAttr =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLSetStmtAttr")
		  : _import (SQLHSTMT, SQLINTEGER, SQLPOINTER_AS_INT,
			     SQLINTEGER)
		            -> SQLRETURN)
(* Submitting requests *)
val ExecDirect =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLExecDirect")
		  : _import (SQLHSTMT, SQLCHAR_PTR, SQLINTEGER) -> SQLRETURN)
(* Retrieving results and information about results *)
val RowCount =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLRowCount")
		  : _import (SQLHSTMT, SQLLEN ref) -> SQLRETURN)
val NumResultCols =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLNumResultCols")
		  : _import (SQLHSTMT, SQLSMALLINT ref) -> SQLRETURN)
val Fetch =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLFetch")
		  : _import SQLHSTMT -> SQLRETURN)
(*
'a array was not accepted
UNIXODBC.sml:
(type inference 059) User type variable cannot be generalized: 'a
UNIXODBC.smi:
  (type inference 074) type and type annotation don't agree
    inferred type: unit
                     -> unit ptr * int * int * 'FH('a) array * int * int ref
                          -> int
  type annotation: unit
                     -> unit ptr * int * int * 'GN('RIGID) array * int * int ref
                          -> int
*)
val GetData =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLGetData")
		  : _import (SQLHSTMT, SQLUSMALLINT, SQLSMALLINT,
			     SQLPOINTER, SQLLEN, SQLLEN ref) -> SQLRETURN)
val SetPos =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLSetPos")
		  : _import (SQLHSTMT, SQLSETPOSIROW,
			     SQLUSMALLINT, SQLUSMALLINT)
		            -> SQLRETURN)
val Columns =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLColumns")
		  : _import (SQLHSTMT, SQLCHAR_PTR, SQLSMALLINT,
			               SQLCHAR_PTR, SQLSMALLINT,
			               SQLCHAR_PTR, SQLSMALLINT,
			               SQLCHAR_PTR, SQLSMALLINT) -> SQLRETURN)
val Tables =
    lazy (fn _ => DynamicLink.dlsym (lib (), "SQLTables")
		  : _import (SQLHSTMT, SQLCHAR_PTR, SQLSMALLINT,
			               SQLCHAR_PTR, SQLSMALLINT,
			               SQLCHAR_PTR, SQLSMALLINT,
			               SQLCHAR_PTR, SQLSMALLINT) -> SQLRETURN)
(* Terminationg a connection *)
val Disconnect =
lazy (fn _ => DynamicLink.dlsym (lib (), "SQLDisconnect")
	      : _import SQLHDBC -> SQLRETURN)
val FreeHandle =
lazy (fn _ => DynamicLink.dlsym (lib (),"SQLFreeHandle")
	      : _import (SQLSMALLINT, SQLHANDLE) -> SQLRETURN)
val GetDiagRec =
lazy (fn _ => DynamicLink.dlsym (lib (), "SQLGetDiagRec")
              : _import (SQLSMALLINT, SQLHANDLE, SQLSMALLINT, SQLCHAR_array,
                         SQLINTEGER ref, SQLCHAR_array, SQLSMALLINT,
                         SQLSMALLINT ref)
                        -> SQLRETURN)

end
