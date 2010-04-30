structure SMLSharp = struct
open SMLSharp
structure Runtime :
sig

(* To keep track of difference from primitives.csv, all primitives appearing
 * in primitives.csv are listed below with commented out.
 * First column character in each commented-out line describes status of each
 * primitives.
 *   P : provided by compiler as a true primitive.
 *   F : provided by compiler as a foreign function call.
 *   C : provided by compiler and compiled into couple of instructions
 *       using foreign function.
 *   U : unused.
 *)

(*  # List of primitive operators. *)
(*  # See README.txt. *)
(*  # $Id: primitives.csv,v 1.86 2008/03/11 08:53:57 katsu Exp $ *)
(*   *)
(*P :=,assign,"['a.('a) ref * 'a -> unit]",2,,,effective *)
(*   *)
(*P =,equal,"[''a.''a * ''a -> bool]",2,Equal,,noneffective *)
(*   *)
(*  # Arithmetic primitives may raise exception, except for primitives on 'real'. *)
(*P addInt,,"int * int -> int",2,AddInt,,effective *)
(*F addLargeInt,,"largeInt * largeInt -> largeInt",2,AddLargeInt,,effective *)
(*P addReal,,"real * real -> real",2,AddReal,,noneffective *)
(*P addFloat,,"float * float -> float",2,AddFloat,,noneffective *)
(*P addWord,,"word * word -> word",2,AddWord,,effective *)
(*P addByte,,"byte * byte -> byte",2,AddByte,,effective *)
(*P subInt,,"int * int -> int",2,SubInt,,effective *)
(*F subLargeInt,,"largeInt * largeInt -> largeInt",2,SubLargeInt,,effective *)
(*P subReal,,"real * real -> real",2,SubReal,,noneffective *)
(*P subFloat,,"float * float -> float",2,SubFloat,,noneffective *)
(*P subWord,,"word * word -> word",2,SubWord,,effective *)
(*P subByte,,"byte * byte -> byte",2,SubByte,,effective *)
(*P mulInt,,"int * int -> int",2,MulInt,,effective *)
(*F mulLargeInt,,"largeInt * largeInt -> largeInt",2,MulLargeInt,,effective *)
(*P mulReal,,"real * real -> real",2,MulReal,,noneffective *)
(*P mulFloat,,"float * float -> float",2,MulFloat,,noneffective *)
(*P mulWord,,"word * word -> word",2,MulWord,,effective *)
(*P mulByte,,"byte * byte -> byte",2,MulByte,,effective *)
(*P divInt,,"int * int -> int",2,DivInt,,effective *)
(*F divLargeInt,,"largeInt * largeInt -> largeInt",2,DivLargeInt,,effective *)
(*P divWord,,"word * word -> word",2,DivWord,,effective *)
(*P divByte,,"byte * byte -> byte",2,DivByte,,effective *)
(*P /,divReal,"real * real -> real",2,DivReal,,noneffective *)
(*P divFloat,,"float * float -> float",2,DivFloat,,noneffective *)
(*P modInt,,"int * int -> int",2,ModInt,,effective *)
(*F modLargeInt,,"largeInt * largeInt -> largeInt",2,ModLargeInt,,effective *)
(*P modWord,,"word * word -> word",2,ModWord,,effective *)
(*P modByte,,"byte * byte -> byte",2,ModByte,,effective *)
(*P quotInt,,"int * int -> int",2,QuotInt,,effective *)
val quotLargeInt : IntInf.int * IntInf.int -> IntInf.int (* QuotLargeInt *)
(*P remInt,,"int * int -> int",2,RemInt,,effective *)
val remLargeInt : IntInf.int * IntInf.int -> IntInf.int (* RemLargeInt *)
(*P negInt,,"int -> int",1,NegInt,,effective *)
(*F negLargeInt,,"largeInt -> largeInt",1,NegLargeInt,,effective *)
(*P negReal,,"real -> real",1,NegReal,,noneffective *)
(*P negFloat,,"float -> float",1,NegFloat,,noneffective *)
(*P absInt,,"int -> int",1,AbsInt,,effective *)
(*F absLargeInt,,"largeInt -> largeInt",1,AbsLargeInt,,effective *)
(*P absReal,,"real-> real",1,AbsReal,,noneffective *)
(*P absFloat,,"float-> float",1,AbsFloat,,noneffective *)

(* # Comparison primitives are noneffective because they do not raise exception. *)
(*P ltInt,,"int * int -> bool",2,LtInt,,noneffective *)
(*C ltLargeInt,,"largeInt * largeInt -> bool",2,LtLargeInt,,noneffective *)
(*P ltReal,,"real * real -> bool",2,LtReal,,noneffective *)
(*P ltFloat,,"float * float -> bool",2,LtFloat,,noneffective *)
(*P ltWord,,"word * word -> bool",2,LtWord,,noneffective *)
(*P ltByte,,"byte * byte -> bool",2,LtByte,,noneffective *)
(*P ltChar,,"char * char -> bool",2,LtChar,,noneffective *)
(*C ltString,,"string * string -> bool",2,LtString,,noneffective *)
(*P gtInt,,"int * int -> bool",2,GtInt,,noneffective *)
(*C gtLargeInt,,"largeInt * largeInt -> bool",2,GtLargeInt,,noneffective *)
(*P gtReal,,"real * real -> bool",2,GtReal,,noneffective *)
(*P gtFloat,,"float * float -> bool",2,GtFloat,,noneffective *)
(*P gtWord,,"word * word -> bool",2,GtWord,,noneffective *)
(*P gtByte,,"byte * byte -> bool",2,GtByte,,noneffective *)
(*P gtChar,,"char * char -> bool",2,GtChar,,noneffective *)
(*C gtString,,"string * string -> bool",2,GtString,,noneffective *)
(*P lteqInt,,"int * int -> bool",2,LteqInt,,noneffective *)
(*C lteqLargeInt,,"largeInt * largeInt -> bool",2,LteqLargeInt,,noneffective *)
(*P lteqReal,,"real * real -> bool",2,LteqReal,,noneffective *)
(*P lteqFloat,,"float * float -> bool",2,LteqFloat,,noneffective *)
(*P lteqWord,,"word * word -> bool",2,LteqWord,,noneffective *)
(*P lteqByte,,"byte * byte -> bool",2,LteqByte,,noneffective *)
(*P lteqChar,,"char * char -> bool",2,LteqChar,,noneffective *)
(*C lteqString,,"string * string -> bool",2,LteqString,,noneffective *)
(*P gteqInt,,"int * int -> bool",2,GteqInt,,noneffective *)
(*C gteqLargeInt,,"largeInt * largeInt -> bool",2,GteqLargeInt,,noneffective *)
(*P gteqReal,,"real * real -> bool",2,GteqReal,,noneffective *)
(*P gteqFloat,,"float * float -> bool",2,GteqFloat,,noneffective *)
(*P gteqWord,,"word * word -> bool",2,GteqWord,,noneffective *)
(*P gteqByte,,"byte * byte -> bool",2,GteqByte,,noneffective *)
(*P gteqChar,,"char * char -> bool",2,GteqChar,,noneffective *)
(*C gteqString,,"string * string -> bool",2,GteqString,,noneffective *)

val Int_toString : int -> string

val LargeInt_toString : IntInf.int -> string
val LargeInt_toInt : IntInf.int -> int
val LargeInt_toWord : IntInf.int -> word
val LargeInt_fromInt : int -> IntInf.int
val LargeInt_fromWord : word -> IntInf.int
val LargeInt_pow : IntInf.int * int -> IntInf.int
val LargeInt_log2 : IntInf.int -> int
val LargeInt_orb : IntInf.int * IntInf.int -> IntInf.int
val LargeInt_xorb : IntInf.int * IntInf.int -> IntInf.int
val LargeInt_andb : IntInf.int * IntInf.int -> IntInf.int
val LargeInt_notb : IntInf.int -> IntInf.int

(*P Byte_toIntX,,"byte -> int",1,Byte_toIntX,,effective *)
(*P Byte_fromInt,,"int -> byte",1,Byte_fromInt,,effective *)

(*P Word_toIntX,,"word -> int",1,Word_toIntX,,effective *)
(*P Word_fromInt,,"int -> word",1,Word_fromInt,,effective *)
(*P Word_andb,,"word * word -> word",2,Word_andb,,effective *)
(*P Word_orb,,"word * word -> word",2,Word_orb,,effective *)
(*P Word_xorb,,"word * word -> word",2,Word_xorb,,effective *)
(*P Word_notb,,"word -> word",1,Word_notb,,effective *)
(*P Word_leftShift,,"word * word -> word",2,Word_leftShift,,effective *)
(*P Word_logicalRightShift,,"word * word -> word",2,Word_logicalRightShift,,effective *)
(*P Word_arithmeticRightShift,,"word * word -> word",2,Word_arithmeticRightShift,,effective *)
val Word_toString : word -> string

(*P Real_fromInt,,"int -> real",1,,IMLPrim_Real_fromInt,effective *)
val Real_toString : real -> string
val Real_floor : real -> int
val Real_ceil : real -> int
(*P Real_trunc,,"real -> int",1,,IMLPrim_Real_trunc,effective *)
val Real_round : real -> int
val Real_split : real -> real * real
val Real_toManExp : real -> real * int
val Real_fromManExp : real * int -> real
val Real_copySign : real * real -> real
(*P Real_equal,,"real * real -> bool",2,,IMLPrim_Real_equal,effective *)
val Real_class : real -> int
(*P Real_toFloat,,"real -> float",1,,IMLPrim_Real_toFloat,effective *)
(*P Real_fromFloat,,"float -> real",1,,IMLPrim_Real_fromFloat,effective *)
val Real_dtoa : real * int -> string * int
val Real_strtod : string -> real

(*P Float_fromInt,,"int -> float",1,,IMLPrim_Float_fromInt,effective *)
val Float_toString : Real32.real -> string
(*U Float_floor,,"float -> int",1,,IMLPrim_Float_floor,effective *)
(*U Float_ceil,,"float -> int",1,,IMLPrim_Float_ceil,effective *)
(*U Float_trunc,,"float -> int",1,,IMLPrim_Float_trunc,effective *)
(*U Float_round,,"float -> int",1,,IMLPrim_Float_round,effective *)
(*U Float_split,,"float -> float * float",1,,IMLPrim_Float_split,effective *)
(*U Float_toManExp,,"float -> float * int",1,,IMLPrim_Float_toManExp,effective *)
(*U Float_fromManExp,,"float * int -> float",2,,IMLPrim_Float_fromManExp,effective *)
(*U Float_copySign,,"float * float -> float",2,,IMLPrim_Float_copySign,effective *)
(*P Float_equal,,"float * float -> bool",2,,IMLPrim_Float_equal,effective *)
(*U Float_class,,"float -> int",1,,IMLPrim_Float_class,effective *)

(* # Char_chr may raise Chr exception. *)
val Char_toString : char -> string
val Char_toEscapedString : char -> string
(*P Char_ord,,"char -> int",1,,IMLPrim_Char_ord,effective *)
(*P Char_chr,,"int -> char",1,,IMLPrim_Char_chr,effective *)

val String_concat2 : string * string -> string
(*P String_sub,,"string * int -> char",2,,IMLPrim_String_sub,effective *)
(*P String_size,,"string -> int",1,,IMLPrim_String_size,effective *)
val String_substring : string * int * int -> string
(*P String_update,,"string * int * char -> unit",3,,IMLPrim_String_update,effective *)
(*P String_allocateMutable,,"int * char -> string",2,,IMLPrim_String_allocateMutable,effective *)
(*P String_allocateImmutable,,"int * char -> string",2,,IMLPrim_String_allocateImmutable,effective *)
(*P String_copy,,"string * int * string * int * int -> unit",5,,IMLPrim_String_copy,effective *)

val print : string -> unit

(*P Array_mutableArray,,"['a.int * 'a -> ('a) array]",2,,,effective *)
(*P Array_immutableArray,,"['a.int * 'a -> ('a) array]",2,,,effective *)
(*P Array_sub,,"['a.('a) array * int -> 'a]",2,,,effective *)
(*P Array_update,,"['a.('a) array * int * 'a -> unit]",3,,,effective *)
(*P Array_length,,"['a.('a) array -> int]",1,Array_length,,effective *)
(*P Array_copy,,"['a.('a) array * int * ('a) array * int * int -> unit]",5,,,effective *)

val Internal_getCurrentIP : int -> word * word
val Internal_getStackTrace : int -> (word * word) array
val Internal_IPToString : word * word -> string

val Time_gettimeofday : int -> int * int

val GenericOS_errorName : int -> string
val GenericOS_errorMsg : int -> string
val GenericOS_syserror : string -> int option

val GenericOS_getSTDIN : int -> word
val GenericOS_getSTDOUT : int -> word
val GenericOS_getSTDERR : int -> word
(* # FILE* fileOpen(fileName, mode) *)
val GenericOS_fileOpen : string * string -> word
val GenericOS_fileClose : word -> unit
(* # buffer fileRead(FILE*, nbytes) *)
val GenericOS_fileRead : word * int -> string
(* # readBytes fileReadBuf(FILE*, buffer, start, nbytes) *)
val GenericOS_fileReadBuf : word * string * int * int -> int
(* # writtenBytes fileWrite(FILE*, buffer, start, nbytes) *)
val GenericOS_fileWrite : word * string * int * int -> int
val GenericOS_fileSetPosition : word * int -> int
val GenericOS_fileGetPosition : word -> int
(* # returns the file descriptor. *)
val GenericOS_fileNo : word -> int
(* # returns size of an opened file *)
val GenericOS_fileSize : word -> int

val GenericOS_isRegFD : word -> bool
val GenericOS_isDirFD : word -> bool
val GenericOS_isChrFD : word -> bool
val GenericOS_isBlkFD : word -> bool
val GenericOS_isLinkFD : word -> bool
val GenericOS_isFIFOFD : word -> bool
val GenericOS_isSockFD : word -> bool
val GenericOS_poll : (int * word) array * (int * int) option -> (int * word) array
val GenericOS_getPOLLINFlag : int -> word
val GenericOS_getPOLLOUTFlag : int -> word
val GenericOS_getPOLLPRIFlag : int -> word

(* # int system(char* name) *)
val GenericOS_system : string -> int
(* # void exit(int) *)
val GenericOS_exit : int -> unit
val GenericOS_getEnv : string -> string option
(* # void sleep(unsigned int seconds) *)
val GenericOS_sleep : word -> unit

val GenericOS_openDir : string -> word
val GenericOS_readDir : word -> string option
val GenericOS_rewindDir : word -> unit
val GenericOS_closeDir : word -> unit
val GenericOS_chDir : string -> unit
val GenericOS_getDir : int -> string
val GenericOS_mkDir : string -> unit
val GenericOS_rmDir : string -> unit
val GenericOS_isDir : string -> bool
val GenericOS_isLink : string -> bool
val GenericOS_readLink : string -> string
val GenericOS_getFileModTime : string -> int
val GenericOS_setFileTime : string * int -> unit
val GenericOS_getFileSize : string -> int
val GenericOS_remove : string -> unit
val GenericOS_rename : string * string -> unit
val GenericOS_isFileExists : string -> bool
val GenericOS_isFileReadable : string -> bool
val GenericOS_isFileWritable : string -> bool
val GenericOS_isFileExecutable : string -> bool
val GenericOS_tempFileName : unit -> string
val GenericOS_getFileID : string -> word

val CommandLine_name : int -> string
val CommandLine_arguments : int -> string array

val Date_ascTime : int * int * int * int * int * int * int * int * int -> string
val Date_localTime : int -> int * int * int * int * int * int * int * int * int
val Date_gmTime : int -> int * int * int * int * int * int * int * int * int
val Date_mkTime : int * int * int * int * int * int * int * int * int -> int
val Date_strfTime : string * (int * int * int * int * int * int * int * int * int) -> string

val Timer_getTime : int -> int * int * int * int * int * int

(* # There Math primitives are effective since underlying GMP may raise exception. *)
val Math_sqrt : real -> real
val Math_sin : real -> real
val Math_cos : real -> real
val Math_tan : real -> real
val Math_asin : real -> real
val Math_acos : real -> real
val Math_atan : real -> real
val Math_atan2 : real * real -> real
val Math_exp : real -> real
val Math_pow : real * real -> real
val Math_ln : real -> real
val Math_log10 : real -> real
val Math_sinh : real -> real
val Math_cosh : real -> real
val Math_tanh : real -> real

val StandardC_errno : unit -> int

val UnmanagedMemory_allocate : int -> unit ptr
val UnmanagedMemory_release : unit ptr -> unit
(*F UnmanagedMemory_sub,,"(unit) ptr -> byte",1,,IMLPrim_UnmanagedMemory_sub,effective *)
val UnmanagedMemory_update : unit ptr * Word8.word -> unit
(*F UnmanagedMemory_subWord,,"(unit) ptr -> word",1,,IMLPrim_UnmanagedMemory_subWord,effective *)
val UnmanagedMemory_updateWord : unit ptr * word -> unit
(*F UnmanagedMemory_subInt,,"(unit) ptr -> int",1,,IMLPrim_UnmanagedMemory_subWord,effective *)
val UnmanagedMemory_updateInt : unit ptr * int -> unit
(*F UnmanagedMemory_subReal,,"(unit) ptr -> real",1,,IMLPrim_UnmanagedMemory_subReal,effective *)
val UnmanagedMemory_updateReal : unit ptr * real -> unit
val UnmanagedMemory_import : unit ptr * int -> string
val UnmanagedMemory_export : string * int * int -> unit ptr
val UnmanagedString_size : unit ptr -> int

val DynamicLink_dlopen : string -> unit ptr
val DynamicLink_dlclose : unit ptr -> unit
val DynamicLink_dlsym : unit ptr * string -> unit ptr

(* # actual domain type of addFinalizable is: 'a ref * ('a ref -> unit) ref *)
val GC_addFinalizable : 'a ref -> int
val GC_doGC : int -> unit
val GC_fixedCopy : 'a ref -> unit
val GC_releaseFLOB : 'a ref -> unit
val GC_addressOfFLOB : 'a ref -> unit ptr
val GC_copyBlock : 'a ref -> unit
val GC_isAddressOfBlock : unit ptr -> bool
val GC_isAddressOfFLOB : unit ptr -> bool

val Platform_getPlatform : unit -> string
val Platform_isBigEndian : unit -> bool

val Pack_packWord32Little : Word8.word * Word8.word * Word8.word * Word8.word -> word
val Pack_packWord32Big : Word8.word * Word8.word * Word8.word * Word8.word -> word
val Pack_unpackWord32Little : word -> Word8.word * Word8.word * Word8.word * Word8.word
val Pack_unpackWord32Big : word -> Word8.word * Word8.word * Word8.word * Word8.word
val Pack_packReal64Little : Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word -> real
val Pack_packReal64Big : Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word -> real
val Pack_unpackReal64Little : real -> Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word
val Pack_unpackReal64Big : real -> Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word

val Pack_packReal32Little : Word8.word * Word8.word * Word8.word * Word8.word -> Real32.real
val Pack_packReal32Big : Word8.word * Word8.word * Word8.word * Word8.word -> Real32.real
val Pack_unpackReal32Little : Real32.real -> Word8.word * Word8.word * Word8.word * Word8.word
val Pack_unpackReal32Big : Real32.real -> Word8.word * Word8.word * Word8.word * Word8.word

val SMLSharpCommandLine_executableImageName : unit -> string option

val DynamicBind_importSymbol : string -> unit ptr
val DynamicBind_exportSymbol : string * unit ptr -> unit

end =
struct

  (* implemented in SML# runtime library *)

  val Int_toString = (* used only for basic formatter *)
      _import "prim_Int_toString"
      : __attribute__((pure,no_callback,alloc)) int -> string
  val LargeInt_toString = (* used only for basic formatter *)
      _import "prim_IntInf_toString"
      : __attribute__((pure,no_callback,alloc)) IntInf.int -> string
  val LargeInt_toInt =
      _import "prim_IntInf_toInt"
      : __attribute__((pure,no_callback)) IntInf.int -> int
  val LargeInt_toWord =
      _import "prim_IntInf_toWord"
      : __attribute__((pure,no_callback)) IntInf.int -> word
  val LargeInt_fromInt =
      _import "prim_IntInf_fromInt"
      : __attribute__((pure,no_callback,alloc)) int -> IntInf.int
  val LargeInt_fromWord =
      _import "prim_IntInf_fromWord"
      : __attribute__((pure,no_callback,alloc)) word -> IntInf.int
  val quotLargeInt =
      _import "prim_IntInf_quot"
      : __attribute__((pure,no_callback,alloc))
        (IntInf.int, IntInf.int) -> IntInf.int
  val remLargeInt =
      _import "prim_IntInf_rem"
      : __attribute__((pure,no_callback,alloc))
        (IntInf.int, IntInf.int) -> IntInf.int
  val LargeInt_pow =
      _import "prim_IntInf_pow"
      : __attribute__((pure,no_callback,alloc))
        (IntInf.int, int) -> IntInf.int
  val LargeInt_log2 =
      _import "prim_IntInf_log2"
      : __attribute__((pure,no_callback)) IntInf.int -> int
  val LargeInt_orb =
      _import "prim_IntInf_orb"
      : __attribute__((pure,no_callback,alloc))
        (IntInf.int, IntInf.int) -> IntInf.int
  val LargeInt_xorb =
      _import "prim_IntInf_xorb"
      : __attribute__((pure,no_callback,alloc))
        (IntInf.int, IntInf.int) -> IntInf.int
  val LargeInt_andb =
      _import "prim_IntInf_andb"
      : __attribute__((pure,no_callback,alloc))
        (IntInf.int, IntInf.int) -> IntInf.int
  val LargeInt_notb =
      _import "prim_IntInf_notb"
      : __attribute__((pure,no_callback,alloc)) IntInf.int -> IntInf.int
  val Word_toString = (* used only for basic formatter *)
      _import "prim_Word_toString"
      : __attribute__((pure,no_callback,alloc)) word -> string
  val Real_class =
      _import "prim_Real_class"
      : __attribute__((pure,no_callback)) real -> int
  val ya_String_allocateImmutableNoInit =
      _import "prim_String_allocateImmutableNoInit"
      : __attribute__((pure,no_callback,alloc)) word -> string
  val ya_String_allocateMutableNoInit =
      _import "prim_String_allocateMutableNoInit"
      : __attribute__((pure,no_callback,alloc)) word -> string
  val String_substring =
      _import "prim_String_substring"
      : __attribute__((pure,no_callback,alloc)) (string, int, int) -> string
  val print = (* overrided by TextIO.print *)
      _import "prim_print"
      : __attribute__((no_callback)) string -> unit
  val GenericOS_exit =
      _import "prim_GenericOS_exit"
      : __attribute__((no_callback)) int -> unit
  val ya_GenericOS_open =
      _import "prim_GenericOS_open"
      : __attribute__((no_callback)) (string, string) -> int
  val ya_GenericOS_read =
      _import "prim_GenericOS_read"
      : __attribute__((no_callback)) (int, string, word, word) -> int
  val ya_GenericOS_write =
      _import "prim_GenericOS_write"
      : __attribute__((no_callback)) (int, string, word, word) -> int
  val ya_GenericOS_fstat =
      _import "prim_GenericOS_fstat"
      : __attribute__((no_callback)) (int, word array) -> int
  val ya_GenericOS_stat =
      _import "prim_GenericOS_stat"
      : __attribute__((no_callback)) (string, word array) -> int
  val ya_GenericOS_lseek =
      _import "prim_GenericOS_lseek"
      : __attribute__((no_callback)) (int, int, int) -> int
  val ya_GenericOS_utime =
      _import "prim_GenericOS_utime"
      : __attribute__((no_callback)) (string, word, word) -> int
  val ya_GenericOS_readlink =
      _import "prim_GenericOS_readlink"
      : __attribute__((no_callback,alloc)) string -> string
  val ya_GenericOS_chdir =
      _import "prim_GenericOS_chdir"
      : __attribute__((no_callback)) string -> int
  val ya_GenericOS_mkdir =
      _import "prim_GenericOS_mkdir"
      : __attribute__((no_callback)) (string, int) -> int
  val ya_GenericOS_getcwd =
      _import "prim_GenericOS_getcwd"
      : __attribute__((no_callback,alloc)) () -> char ptr
  val ya_GenericOS_opendir =
      _import "prim_GenericOS_opendir"
      : __attribute__((no_callback)) string -> unit ptr
  val ya_GenericOS_readdir =
      _import "prim_GenericOS_readdir"
      : __attribute__((no_callback,alloc)) unit ptr -> char ptr
  val ya_GenericOS_rewinddir =
      _import "prim_GenericOS_rewinddir"
      : __attribute__((no_callback)) unit ptr -> unit
  val ya_GenericOS_closedir =
      _import "prim_GenericOS_closedir"
      : __attribute__((no_callback)) unit ptr -> int
  val ya_GenericOS_select =
      _import "prim_GenericOS_select"
      : __attribute__((no_callback))
        (int array, int array, int array, int, int) -> int
  val GenericOS_errorName =
      _import "prim_GenericOS_errorName"
      : __attribute__((pure,no_callback,alloc)) int -> string
  val ya_GenericOS_syserror =
      _import "prim_GenericOS_syserror"
      : __attribute__((pure,no_callback)) string -> int
  val ya_Time_gettimeofday =
      _import "prim_Time_gettimeofday"
      : __attribute__((no_callback)) int array -> int
  val ya_Timer_getTimes =
      _import "prim_Timer_getTimes"
      : __attribute__((no_callback)) int array -> int
  val ya_Date_strfTime =
      _import "prim_Date_strfTime"
      : __attribute__((no_callback))
        (string, word, string, int, int, int, int, int, int, int, int, int)
        -> word
  val ya_Date_ascTime =
      _import "prim_Date_ascTime"
      : __attribute__((no_callback))
        (int, int, int, int, int, int, int, int, int) -> char ptr
  val Date_mkTime =
      _import "prim_Date_mkTime"
      : __attribute__((no_callback))
        (int, int, int, int, int, int, int, int, int) -> int
  val ya_Date_localTime =
      _import "prim_Date_localTime"
      : __attribute__((no_callback)) (int, int array) -> unit
  val ya_Date_gmTime =
      _import "prim_Date_gmTime"
      : __attribute__((no_callback)) (int, int array) -> unit
  val Pack_packReal64Little =
      _import "prim_Pack_packReal64Little"
      : __attribute__((pure,no_callback))
        (Word8.word, Word8.word, Word8.word, Word8.word,
         Word8.word, Word8.word, Word8.word, Word8.word) -> real
  val Pack_packReal64Big =
      _import "prim_Pack_packReal64Big"
      : __attribute__((pure,no_callback))
        (Word8.word, Word8.word, Word8.word, Word8.word,
         Word8.word, Word8.word, Word8.word, Word8.word) -> real
  val ya_Pack_unpackReal64Little =
      _import "prim_Pack_unpackReal64Little"
      : __attribute__((no_callback)) (real, string) -> unit
  val ya_Pack_packReal32Little =
      _import "prim_Pack_packReal32Little"
      : __attribute__((no_callback))
      (Word8.word, Word8.word, Word8.word, Word8.word, Real32.real ref) -> unit
  val ya_Pack_packReal32Big =
      _import "prim_Pack_packReal32Big"
      : __attribute__((no_callback))
      (Word8.word, Word8.word, Word8.word, Word8.word, Real32.real ref) -> unit
  val ya_Pack_unpackReal32Little =
      _import "prim_Pack_unpackReal32Little"
      : __attribute__((no_callback)) (Real32.real, string) -> unit
  val ya_UnmanagedMemory_import =
      _import "prim_UnmanagedMemory_import"
      : __attribute__((pure,no_callback,alloc)) (unit ptr, word) -> string
  val ya_UnmanagedMemory_export =
      _import "prim_UnmanagedMemory_export"
      : __attribute__((pure,no_callback)) (string, word, word) -> unit ptr
  val UnmanagedString_size =
      _import "prim_UnmanagedString_size"
      : __attribute__((pure,no_callback)) unit ptr -> int
  val UnmanagedMemory_update =
      _import "prim_UnmanagedMemory_update"
      : __attribute__((no_callback)) (unit ptr, Word8.word) -> unit
  val UnmanagedMemory_updateWord =
      _import "prim_UnmanagedMemory_updateWord"
      : __attribute__((no_callback)) (unit ptr, word) -> unit
  val UnmanagedMemory_updateInt =
      _import "prim_UnmanagedMemory_updateInt"
      : __attribute__((no_callback)) (unit ptr, int) -> unit
  val UnmanagedMemory_updateReal =
      _import "prim_UnmanagedMemory_updateReal"
      : __attribute__((no_callback)) (unit ptr, real) -> unit
  val StandardC_errno =
      _import "prim_StandardC_errno"
      : __attribute__((no_callback)) () -> int
  val Platform_isBigEndian =
      _import "prim_Platform_isBigEndian"
      : __attribute__((pure,no_callback)) () -> int
  val Platform_getPlatform =
      _import "prim_Platform_getPlatform"
      : __attribute__((pure,no_callback,alloc)) () -> string
  val cconstInt =
      _import "prim_cconst_int"
      : __attribute__((pure,no_callback)) string -> int
  val xmalloc =
      _import "prim_xmalloc"
      : __attribute__((no_callback)) int -> unit ptr
  val str_new =
      _import "sml_str_new"
      : __attribute__((no_callback,alloc)) char ptr -> string

  (* Netlib dtoa library *)

  val dtoa =
      _import "sml_dtoa"
      : __attribute__((no_callback))
        (real, int, int, int ref, int ref, char ptr ptr) -> char ptr
  val freedtoa =
      _import "sml_freedtoa"
      : __attribute__((no_callback)) char ptr -> unit
  val strtod =
      _import "sml_strtod"
      : __attribute__((pure,no_callback)) (string, char ptr ptr) -> real

  (* standard C library *)

  (* ANSI *)

  val Real_fromManExp =
      _import "ldexp"
      : __attribute__((pure,no_callback)) (real, int) -> real
  val Math_sqrt =
      _import "sqrt"
      : __attribute__((pure,no_callback)) real -> real
  val Math_sin =
      _import "sin"
      : __attribute__((pure,no_callback)) real -> real
  val Math_cos =
      _import "cos"
      : __attribute__((pure,no_callback)) real -> real
  val Math_tan =
      _import "tan"
      : __attribute__((pure,no_callback)) real -> real
  val Math_asin =
      _import "asin"
      : __attribute__((pure,no_callback)) real -> real
  val Math_acos =
      _import "acos"
      : __attribute__((pure,no_callback)) real -> real
  val Math_atan =
      _import "atan"
      : __attribute__((pure,no_callback)) real -> real
  val Math_atan2 =
      _import "atan2"
      : __attribute__((pure,no_callback)) (real, real) -> real
  val Math_exp =
      _import "exp"
      : __attribute__((pure,no_callback)) real -> real
  val Math_pow =
      _import "pow"
      : __attribute__((pure,no_callback)) (real, real) -> real
  val Math_ln =
      _import "log"
      : __attribute__((pure,no_callback)) real -> real
  val Math_log10 =
      _import "log10"
      : __attribute__((pure,no_callback)) real -> real
  val Math_sinh =
      _import "sinh"
      : __attribute__((pure,no_callback)) real -> real
  val Math_cosh =
      _import "cosh"
      : __attribute__((pure,no_callback)) real -> real
  val Math_tanh =
      _import "tanh"
      : __attribute__((pure,no_callback)) real -> real
  val floor =
      _import "floor"
      : __attribute__((pure,no_callback)) real -> real
  val ceil =
      _import "ceil"
      : __attribute__((pure,no_callback)) real -> real
  val round =
      _import "round"
      : __attribute__((pure,no_callback)) real -> real
  val modf =
      _import "modf"
      : __attribute__((pure,no_callback)) (real, real ref) -> real
  val frexp =
      _import "frexp"
      : __attribute__((pure,no_callback)) (real, int ref) -> real
  val strerror =
      _import "strerror"
      : __attribute__((no_callback)) int -> char ptr
  val getenv =
      _import "getenv"
      : __attribute__((no_callback)) string -> char ptr
  val free =
      _import "free"
      : __attribute__((no_callback)) unit ptr -> unit
  val tmpnam =
      _import "tmpnam"
      : __attribute__((no_callback)) (char ptr) -> char ptr
  val system =
      _import "system"
      : __attribute__((no_callback)) string -> int
  val remove =
      _import "remove"
      : __attribute__((no_callback)) string -> int
  val rename =
      _import "rename"
      : __attribute__((no_callback)) (string, string) -> int

  (* C99 *)

  val Real_copySign =
      _import "copysign"
      : __attribute__((pure,no_callback)) (real, real) -> real

  (* POSIX *)

  val sleep =
      _import "sleep"
      : __attribute__((no_callback)) word -> word
  val close =
      _import "close"
      : __attribute__((no_callback)) int -> int
  val rmdir =
      _import "rmdir"
      : __attribute__((no_callback)) string -> int
  val dlopen =
      _import "dlopen"
      : __attribute__((no_callback)) (string, int) -> unit ptr
  val dlerror =
      _import "dlerror"
      : __attribute__((no_callback)) () -> char ptr
  val dlclose =
      _import "dlclose"
      : __attribute__((no_callback)) unit ptr -> int
  val dlsym =
      _import "dlsym"
      : __attribute__((no_callback)) (unit ptr, string) -> unit ptr

  (* unimplemented primitives *)

  fun CommandLine_name (_:int) : string =
      raise Fail "CommandLine_name is not implemented yet"
  fun CommandLine_arguments (x:int) : string array =
      raise Fail "CommandLine_arguments is not implemented yet"

  fun GC_addFinalizable (_:('a) ref) : int =
      raise Fail "GC_addFinalizable is not implemented yet"
  fun GC_doGC (_:int) : unit =
      raise Fail "GC_doGC is not implemented yet"
  fun SMLSharpCommandLine_executableImageName (_:unit) : string option =
      raise Fail "SMLSharpCommandLine_executableImageName is not implemented yet"

  fun DynamicBind_importSymbol (_:string) : unit ptr =
      raise Fail "DynamicBind is not supported"
  fun DynamicBind_exportSymbol (_:string * unit ptr) : unit =
      raise Fail "DynamicBind is not supported"
  fun GC_isAddressOfBlock (_:unit ptr) : bool =
      raise Fail "FLOB is not supported"
  fun GC_isAddressOfFLOB (_:unit ptr) : bool =
      raise Fail "FLOB is not supported"
  fun Internal_getCurrentIP (_:int) : word * word =
      raise Fail "Internal_getCurrentIP is not supported"
  fun Internal_getStackTrace (_:int) : (word * word) array =
      raise Fail "Internal_getStackTrace is not supported"
  fun Internal_IPToString (_:word * word) : string =
      raise Fail "Internal_IPToString is not supported"
  fun 'a GC_fixedCopy (_:'a ref) : unit =
      raise Fail "FLOB is not supported"
  fun 'a GC_releaseFLOB (_:'a ref) : unit =
      raise Fail "FLOB is not supported"
  fun 'a GC_addressOfFLOB (_:'a ref) : unit ptr =
      raise Fail "FLOB is not supported"
  fun 'a GC_copyBlock (_:'a ref) : unit =
      raise Fail "FLOB is not supported"

  (* minimum prelude *)

  fun ! (ref x) = x

  structure Array =
  struct
    val array = SMLSharp.PrimArray.array
    val sub = SMLSharp.PrimArray.sub_unsafe
    val update = SMLSharp.PrimArray.update_unsafe
    val length = SMLSharp.PrimArray.length
  end

  fun ^ (x:string, y:string) : string =
      let
        val n1 = SMLSharp.PrimString.size x
        val n2 = SMLSharp.PrimString.size y
        val newstr = ya_String_allocateImmutableNoInit (Word.fromInt (n1 + n2))
      in
        SMLSharp.PrimString.copy_unsafe (x, 0, newstr, 0, n1);
        SMLSharp.PrimString.copy_unsafe (y, 0, newstr, n1, n2);
        newstr
      end

  infix 6 ^

  (* implementations of current primitives by new primitives *)

  (*
   * We assume that runtime data representation of 'a ptr is void*
   * in spite for any instance of 'a. Hence we can compare 'a ptr with
   * NULL of void*. Foreign function interface of SML# automatically
   * converts 'a ptr value to pointer value of some type.
   *)
  fun cstrToString (x:char ptr) : string =
      if (_cast(x):unit ptr) = _NULL
      then raise OS.SysErr ("null pointer exception", NONE)
      else str_new x

  fun raiseSysErr () =
      let
        val errno = StandardC_errno ()
      in
        raise OS.SysErr (cstrToString (strerror errno), SOME errno)
      end

  fun checkError (err:int) =
      if err < 0 then raiseSysErr () else ()

  fun checkErrorIfNull (ptr:'a ptr) =
      if (_cast(ptr):unit ptr) = _NULL then raiseSysErr () else ()

  val String_concat2 = op ^

  (* used only for basic formatter *)
  fun Char_toString (ch:char) : string =
      SMLSharp.PrimString.vector (1, ch)

  (* used only for basic formatter *)
  fun Char_toEscapedString (ch:char) : string =
      case ch of
        #"\\" => "\\\\"
      | #"\"" => "\\\""
      | #"\a" => "\\a"
      | #"\b" => "\\b"
      | #"\t" => "\\t"
      | #"\n" => "\\n"
      | #"\v" => "\\v"
      | #"\f" => "\\f"
      | #"\r" => "\\r"
      | _ =>
        let
          val digit = "0123456789"
          val hexdigit = "0123456789abcdef"
          fun d x =
              Char_toString (SMLSharp.PrimString.sub_unsafe (digit, x mod 10))
          fun h x =
              Char_toString (SMLSharp.PrimString.sub_unsafe (digit, x mod 16))
          val n = Char.ord ch
        in
          if n < 32
          then "\\^" ^ Char_toString (Char.chr_unsafe (n + 64))
          else if n > 999
          then "\\u" ^ h (n div 4096) ^ h (n div 256) ^ h (n div 16) ^ h n
          else if n > 126
          then "\\" ^ d (n div 100) ^ d (n div 10) ^ d n
          else Char_toString ch
        end

  fun Real_split (x:real) : real * real =
      let
        val intg = ref 0.0
        val frac = modf (x, intg)
      in
        (frac, !intg)
      end

  fun Real_toManExp (x:real) : real * int =
      let
        val exp = ref 0
        val man = frexp (x, exp)
      in
        (man, !exp)
      end

  fun Real_dtoa (d:real, ndigits:int) : string * int =
      case Real_class d of
        0 => ("nan", 0)     (* CLASS_SNAN *)
      | 1 => ("nan", 0)     (* CLASS_QNAN *)
      | 2 => ("~inf", 0)    (* CLASS_NINF *)
      | 3 => ("inf", 0)     (* CLASS_PINF *)
      | 6 => ("~0", 0)      (* CLASS_NZERO *)
      | 7 => ("0", 0)       (* CLASS_PZERO *)
      | _ =>
        let
          val decpt = ref 0
          val sign = ref 0
          val s = dtoa (d, 0, ndigits, decpt, sign, (_cast(_NULL):char ptr ptr))
          val str = cstrToString s
          val _ = freedtoa s
        in
          if !sign = 0
          then (str, !decpt)
          else ("~" ^ str, !decpt)
        end

  fun Real_strtod (s:string) : real =
      strtod (s, (_cast(_NULL):char ptr ptr))

  (* used only for basic formatter *)
  fun Real_toString (d:real) : string =
      let
        val decpt = ref 0
        val sign = ref 0
        val s = dtoa (d, 2, 8, decpt, sign, (_cast(_NULL):char ptr ptr))
        val str = cstrToString s
        val _ = freedtoa s
        val str = "." ^ str
        val str = if !sign = 0 then str else "~" ^ str
      in
        str ^ "E" ^ Int_toString (!decpt)
      end

  (* used only for basic formatter *)
  fun Float_toString (x:Real32.real) : string =
      Real_toString (Real32.toReal x)

  fun Real_floor (x:real) : int =
      Real.trunc_unsafe (floor x)

  fun Real_ceil (x:real) : int =
      Real.trunc_unsafe (ceil x)

  fun Real_round (x:real) : int =
      Real.trunc_unsafe (round x)

  fun Time_gettimeofday (x:int) : int * int =
      let
        val ret = Array.array (2, 0)
        val err = ya_Time_gettimeofday ret
      in
        checkError err;
        (Array.sub (ret, 0), Array.sub (ret, 1))
      end
      handle OS.SysErr (s,n) =>
             raise OS.SysErr ("gettimeofday:" ^ s, n)

  fun DynamicLink_dlopen (filename:string) : unit ptr =
      let
        val RTLD_LAZY = Word.fromInt (cconstInt "RTLD_LAZY")
        val RTLD_LOCAL = Word.fromInt (cconstInt "RTLD_LOCAL")
        val mode = Word.toIntX (Word.orb (RTLD_LAZY, RTLD_LOCAL))
        val libhandle = dlopen (filename, mode)
      in
        if libhandle = _NULL
        then raise OS.SysErr (cstrToString (dlerror ()), NONE)
        else libhandle
      end

  fun DynamicLink_dlclose (libhandle:unit ptr) : unit =
      if dlclose libhandle < 0
      then raise OS.SysErr (cstrToString (dlerror ()), NONE)
      else ()

  fun DynamicLink_dlsym (libhandle:unit ptr, symname:string) : unit ptr =
      let
        val ptr = dlsym (libhandle, symname)
      in
        if libhandle = _NULL
        then raise OS.SysErr (cstrToString (dlerror ()), NONE)
        else ptr
      end

  fun GenericOS_syserror (errname:string) : int option =
      let
        val errno = ya_GenericOS_syserror errname
      in
        if errno < 0 then NONE else SOME errno
      end

  fun GenericOS_errorMsg (errno:int) : string =
      cstrToString (strerror errno)

  fun GenericOS_sleep (x:word) : unit =
      (sleep x; ())

  fun GenericOS_getSTDIN (_:int) : word = 0w0
  fun GenericOS_getSTDOUT (_:int) : word = 0w1
  fun GenericOS_getSTDERR (_:int) : word = 0w2

  fun GenericOS_fileOpen (filename:string, mode:string) : word =
      let
        val fd = ya_GenericOS_open (filename, mode)
      in
        checkError fd;
        Word.fromInt fd
      end

  fun GenericOS_fileClose (fd:word) : unit =
      checkError (close (Word.toIntX fd))

  fun GenericOS_fileReadBuf (fd:word, buf, offset:int, len:int) : int =
      if offset < 0 orelse len < 0
      then raise OS.SysErr ("invalid argument", NONE)
      else
        let
          val n = ya_GenericOS_read (Word.toIntX fd, buf, 0w0, Word.fromInt len)
        in
          checkError n;
          n
        end

  fun GenericOS_fileRead (fd:word, len:int) : string =
      if len < 0
      then raise OS.SysErr ("invalid argument", NONE)
      else
        let
          val buf = ya_String_allocateMutableNoInit (Word.fromInt len)
          val n = GenericOS_fileReadBuf (fd, buf, 0, len)
        in
          if n = len
          then buf
          else
            let
              val dst = ya_String_allocateMutableNoInit (Word.fromInt n)
            in
              SMLSharp.PrimString.copy_unsafe (buf, 0, dst, 0, n);
              dst
            end
        end

  fun GenericOS_fileWrite (fd:word, buf:string, offset:int, len:int) : int =
      if offset < 0 orelse len < 0
      then raise OS.SysErr ("invalid argument", NONE)
      else
        let
          val n = ya_GenericOS_write (Word.toIntX fd, buf,
                                      Word.fromInt offset, Word.fromInt len)
        in
          checkError n;
          n
        end

  fun GenericOS_fileSetPosition (fd:word, pos:int) : int =
      let
        val whence = cconstInt "SEEK_SET"
        val newpos = ya_GenericOS_lseek (Word.toIntX fd, pos, whence)
      in
        checkError newpos;
        newpos
      end

  fun GenericOS_fileGetPosition (fd:word) : int =
      let
        val whence = cconstInt "SEEK_CUR"
        val pos = ya_GenericOS_lseek (Word.toIntX fd, 0, whence)
      in
        checkError pos;
        pos
      end

  fun GenericOS_fileNo (fd:word) : int = Word.toIntX fd

  local
    val S_IFIFO  = 0wx1000
    val S_IFCHR  = 0wx2000
    val S_IFDIR  = 0wx4000
    val S_IFBLK  = 0wx6000
    val S_IFREG  = 0wx8000
    val S_IFLNK  = 0wxa000
    val S_IFSOCK = 0wxc000
    val S_ISUID  = 0wx0800
    val S_ISGID  = 0wx0400
    val S_ISVTX  = 0wx0200
    val S_IRUSR  = 0wx0100
    val S_IWUSR  = 0wx0080
    val S_IXUSR  = 0wx0040

    fun get_stat (ary:word array) =
        {dev = Array.sub (ary, 0),
         ino = Array.sub (ary, 1),
         mode = Array.sub (ary, 2),
         atime = Array.sub (ary, 3),
         mtime = Array.sub (ary, 4),
         size = Word.toIntX (Array.sub (ary, 5))}

    fun stat filename =
        let
          val st = Array.array (6, 0w0)
          val err = ya_GenericOS_stat (filename, st)
        in
          checkError err;
          get_stat st
        end

    fun fstat fd =
        let
          val st = Array.array (6, 0w0)
          val err = ya_GenericOS_fstat (Word.toIntX fd, st)
        in
          checkError err;
          get_stat st
        end

    fun test stat (fd, mask) =
        if Word.andb (#mode (stat fd), mask) = 0w0 then false else true
  in

  fun GenericOS_fileSize (fd:word) : int =
      #size (fstat fd)

  fun GenericOS_isRegFD  (fd:word) : bool = test fstat (fd, S_IFREG)
  fun GenericOS_isLinkFD (fd:word) : bool = test fstat (fd, S_IFLNK)
  fun GenericOS_isDirFD  (fd:word) : bool = test fstat (fd, S_IFDIR)
  fun GenericOS_isChrFD  (fd:word) : bool = test fstat (fd, S_IFCHR)
  fun GenericOS_isBlkFD  (fd:word) : bool = test fstat (fd, S_IFBLK)
  fun GenericOS_isFIFOFD (fd:word) : bool = test fstat (fd, S_IFIFO)
  fun GenericOS_isSockFD (fd:word) : bool = test fstat (fd, S_IFSOCK)

  fun GenericOS_isFileExists (filename:string) : bool =
      (* assume that fileStat raises an error if the file does not exist. *)
      (stat filename; true)

  fun GenericOS_getFileModTime (filename:string) : int =
      Word.toIntX (#mtime (stat filename))

  fun GenericOS_getFileSize (filename:string) : int =
      #size (stat filename)

  fun GenericOS_isFileReadable (filename:string) : bool =
      test stat (filename, S_IRUSR)

  fun GenericOS_isFileWritable (filename:string) : bool =
      test stat (filename, S_IWUSR)

  fun GenericOS_isFileExecutable (filename:string) : bool =
      test stat (filename, S_IXUSR)

  fun GenericOS_isLink (filename:string) : bool =
      test stat (filename, S_IFLNK)

  fun GenericOS_isDir (filename:string) : bool =
      test stat (filename, S_IFDIR)

  fun GenericOS_getFileID (filename:string) : word =
      (* this is temporary solution.
       * It can be possible that the same id is generated for multiple files. *)
      let
        val {ino, dev, ...} = stat filename
      in
        Word.orb (ino, Word.<< (dev, 0w24))
      end

  fun GenericOS_setFileTime (filename:string, mtime:int) : unit =
      let
        val {atime, ...} = stat filename
        val err = ya_GenericOS_utime (filename, atime, Word.fromInt mtime)
      in
        checkError err
      end

  end (* local *)

  fun GenericOS_remove (filename:string) : unit =
      checkError (remove filename)

  fun GenericOS_rename (filename:string, newfilename:string) : unit =
    checkError (rename (filename, newfilename))

  fun GenericOS_readLink (filename:string) : string =
      let
        val ret = ya_GenericOS_readlink filename
      in
        checkErrorIfNull (_cast(ret) : unit ptr);
        ret
      end

  fun GenericOS_tempFileName () : string =
      let
        val ret = tmpnam (_cast(_NULL) : char ptr)
      in
        checkErrorIfNull (_cast(ret) : unit ptr);
        cstrToString ret
      end

  fun GenericOS_chDir (dirname:string) : unit =
      checkError (ya_GenericOS_chdir (dirname))

  fun GenericOS_mkDir (dirname:string) : unit =
      checkError (ya_GenericOS_mkdir (dirname, 0x1ff (*0777*)))

  fun GenericOS_rmDir (dirname:string) : unit =
      checkError (rmdir (dirname))

  fun GenericOS_getDir (_:int) : string =
      let
        val ret = ya_GenericOS_getcwd ()
        val _ = checkErrorIfNull (_cast(ret):unit ptr)
                handle e => (free (_cast(ret):unit ptr); raise e)
        val s = str_new ret
      in
        free (_cast(ret):unit ptr);
        s
      end

  fun GenericOS_openDir (dirname:string) : word =
      let
        val dirhandle = ya_GenericOS_opendir dirname
      in
        if dirhandle = _NULL
        then raiseSysErr ()
        else _cast(dirhandle) : word
      end

  fun GenericOS_readDir (dirhandle:word) : string option =
      let
        val dirhandle = _cast(dirhandle) : unit ptr
        val ret = ya_GenericOS_readdir dirhandle
      in
        if (_cast(ret):unit ptr) = _NULL then NONE else SOME (str_new ret)
      end

  fun GenericOS_rewindDir (dirhandle:word) : unit =
      ya_GenericOS_rewinddir (_cast(dirhandle) : unit ptr)

  fun GenericOS_closeDir (dirhandle:word) : unit =
      checkError (ya_GenericOS_closedir (_cast(dirhandle) : unit ptr))

  fun GenericOS_system (command:string) : int =
      let
        val status = system command
      in
        checkError status;
        status
      end

  fun GenericOS_getEnv (varname:string) : string option =
      let
        val ret = getenv varname
      in
        if (_cast(ret):unit ptr) = _NULL then NONE else SOME (cstrToString ret)
      end

  local
    val POLLIN = 0w0
    val POLLOUT = 0w1
    val POLLPRI = 0w2

    fun fold (f, z, fds) =
        let
          fun fold' (i : int, f : 'a * int -> int, z : int, l : 'a array) =
              if i >= Array.length fds then z
              else fold' (i+1, f, f (Array.sub (l, i), z), l)
        in
          fold' (0, f, z, fds)
        end

    fun toFDSet (fds : (int * word) array, event : word) =
        let
          val len = fold (fn ((fd, ev), n) => if ev = event then n + 1 else n,
                          0, fds)
          val fdset = Array.array (len, 0)
        in
          fold (fn ((fd, ev), i) => (Array.update (fdset, i, fd); 0), 0, fds);
          fdset
        end

    fun fromFDSet (infds : int array, outfds : int array, prifds : int array) =
        let
          fun count fdset =
              fold (fn (fd, n) => if fd >= 0 then n + 1 else n, 0, fdset)

          fun set (dst, i, ev, fdset) =
              fold (fn (fd, n) =>
                       if fd >= 0
                       then (Array.update (dst, i, (fd, ev)); i + 1) else n,
                    i, fdset)

          val numIn = count infds
          val numOut = count outfds
          val numPri = count prifds
          val fds = Array.array (numIn + numOut + numPri, (0, 0w0))
          val i = 0
          val i = set (fds, i, POLLIN, infds)
          val i = set (fds, i, POLLOUT, outfds)
          val i = set (fds, i, POLLPRI, prifds)
        in
          fds
        end
  in

  fun GenericOS_getPOLLINFlag  (_:int) : word = POLLIN
  fun GenericOS_getPOLLOUTFlag (_:int) : word = POLLOUT
  fun GenericOS_getPOLLPRIFlag (_:int) : word = POLLPRI

  fun GenericOS_poll
        (fds : (int * word) array, timeout : (int * int) option)
        : (int * word) array =
      let
        val (timeoutSec, timeoutMicro) =
            case timeout of
              SOME (sec, micro) => (sec, micro)
            | NONE => (~1, ~1)

        val infds  = toFDSet (fds, POLLIN)
        val outfds = toFDSet (fds, POLLOUT)
        val prifds = toFDSet (fds, POLLPRI)

        val err = ya_GenericOS_select (infds, outfds, prifds,
                                       timeoutSec, timeoutMicro)
        val _ = checkError err
      in
        if err = 0 then Array.array (0, (0,0w0))  (* timeout *)
        else fromFDSet (infds, outfds, prifds)
      end

  end (* local *)

  fun Timer_getTime (x:int) : int * int * int * int * int * int =
      let
        val ret = Array.array (6, 0)
        val err = ya_Timer_getTimes ret
      in
        checkError err;
        (Array.sub (ret, 0),
         Array.sub (ret, 1),
         Array.sub (ret, 2),
         Array.sub (ret, 3),
         Array.sub (ret, 4),
         Array.sub (ret, 5))
      end
        handle OS.SysErr (s,n) => raise OS.SysErr ("times:" ^ s, n)

  fun Date_ascTime (arg:int*int*int*int*int*int*int*int*int) : string =
      str_new (ya_Date_ascTime arg)

  fun Date_strfTime(format:string, (sec:int, min:int, hour:int, mday:int,
                                    mon:int, year:int, wday:int, yday:int,
                                    isdst:int)) : string =
      let
        fun strftime (buf, len) =
            let
              val n = ya_Date_strfTime(buf, len, format, sec, min, hour, mday,
                                       mon, year, wday, yday, isdst)
            in
              if n = 0w0
              then strftime (ya_String_allocateMutableNoInit (len * 0w2),
                             len * 0w2)
              else
                let
                  val dst = ya_String_allocateMutableNoInit n
                in
                  SMLSharp.PrimString.copy_unsafe (buf, 0, dst, 0,
                                                   Word.toIntX n);
                  dst
                end
            end
      in
        strftime (ya_String_allocateMutableNoInit 0w240, 0w240)
      end

  fun Date_localTime (time:int) : int*int*int*int*int*int*int*int*int =
      let
        val buf = Array.array(9, 0)
        val _ = ya_Date_localTime (time, buf)
      in
        (Array.sub (buf, 0),
         Array.sub (buf, 1),
         Array.sub (buf, 2),
         Array.sub (buf, 3),
         Array.sub (buf, 4),
         Array.sub (buf, 5),
         Array.sub (buf, 6),
         Array.sub (buf, 7),
         Array.sub (buf, 8))
      end

  fun Date_gmTime (time:int) : int*int*int*int*int*int*int*int*int =
      let
        val buf = Array.array (9, 0)
        val _ = ya_Date_gmTime (time, buf)
      in
        (Array.sub (buf, 0),
         Array.sub (buf, 1),
         Array.sub (buf, 2),
         Array.sub (buf, 3),
         Array.sub (buf, 4),
         Array.sub (buf, 5),
         Array.sub (buf, 6),
         Array.sub (buf, 7),
         Array.sub (buf, 8))
      end

  fun UnmanagedMemory_allocate (x:int) : unit ptr =
      xmalloc x

  fun UnmanagedMemory_release (x:unit ptr) : unit =
      free x

  fun UnmanagedMemory_import (ptr:unit ptr, len:int) : string =
      if len < 0
      then raise OS.SysErr ("length is negative", NONE)  (* FIXME *)
      else ya_UnmanagedMemory_import (ptr, Word.fromInt len)

  fun UnmanagedMemory_export (str:string, offset:int, size:int) : unit ptr =
      let
        val len = SMLSharp.PrimString.size str
      in
        if offset >= 0 andalso size >= 0
           andalso offset < len andalso size < len - offset
        then ya_UnmanagedMemory_export (str, Word.fromInt offset,
                                        Word.fromInt size)
        else raise OS.SysErr ("boundary check failed", NONE)  (* FIXME *)
      end

  val Platform_isBigEndian =
      fn () => if Platform_isBigEndian () = 0 then false else true

  local
    fun Word8toWord w =
        Word.andb (Word.fromInt (Word8.toIntX w), 0wxFF)
  in

  fun Pack_packWord32Little ((byte0:Word8.word), (byte1:Word8.word),
                             (byte2:Word8.word), (byte3:Word8.word))
      : word =
      Word.orb (Word.<< (Word8toWord byte3, 0w24),
                Word.orb (Word.<< (Word8toWord byte2, 0w16),
                          Word.orb (Word.<< (Word8toWord byte1, 0w8),
                                    Word8toWord byte0)))

  fun Pack_packWord32Big ((byte0:Word8.word), (byte1:Word8.word),
                          (byte2:Word8.word), (byte3:Word8.word))
      : word =
      Word.orb (Word.<< (Word8toWord byte0, 0w24),
                Word.orb (Word.<< (Word8toWord byte1, 0w16),
                          Word.orb (Word.<< (Word8toWord byte2, 0w8),
                                    Word8toWord byte3)))
  end (* local *)

  fun Pack_unpackWord32Little (w:word)
      : Word8.word * Word8.word * Word8.word * Word8.word =
      (Word8.fromInt (Word.toIntX w),
       Word8.fromInt (Word.toIntX (Word.>> (w, 0w8))),
       Word8.fromInt (Word.toIntX (Word.>> (w, 0w16))),
       Word8.fromInt (Word.toIntX (Word.>> (w, 0w24))))

  fun Pack_unpackWord32Big (w:word)
      : Word8.word * Word8.word * Word8.word * Word8.word =
      (Word8.fromInt (Word.toIntX (Word.>> (w, 0w24))),
       Word8.fromInt (Word.toIntX (Word.>> (w, 0w16))),
       Word8.fromInt (Word.toIntX (Word.>> (w, 0w8))),
       Word8.fromInt (Word.toIntX w))

  fun Pack_unpackReal64Little (number:real)
      : (Word8.word*Word8.word*Word8.word*Word8.word
         *Word8.word*Word8.word*Word8.word*Word8.word) =
      let
        val buffer = ya_String_allocateMutableNoInit 0w8
        val _ = ya_Pack_unpackReal64Little (number, buffer)
      in
        (Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 0))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 1))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 2))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 3))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 4))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 5))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 6))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 7))))
      end

  fun Pack_unpackReal64Big (number:real)
      : (Word8.word*Word8.word*Word8.word*Word8.word
         *Word8.word*Word8.word*Word8.word*Word8.word) =
      let
        val buffer = ya_String_allocateMutableNoInit 0w8
        val _ = ya_Pack_unpackReal64Little (number, buffer)
      in
        (Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 7))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 6))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 5))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 4))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 3))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 2))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 1))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 0))))
      end

  fun Pack_packReal32Little (w1:Word8.word, w2:Word8.word,
                             w3:Word8.word, w4:Word8.word) : Real32.real =
      let
        val ret = ref 0.0 : Real32.real ref
        val _ = ya_Pack_packReal32Little (w1, w2, w3, w4, ret)
      in
        !ret
      end

  fun Pack_packReal32Big (w1:Word8.word, w2:Word8.word,
                          w3:Word8.word, w4:Word8.word) : Real32.real =
      let
        val ret = ref 0.0 : Real32.real ref
        val _ = ya_Pack_packReal32Big (w1, w2, w3, w4, ret)
      in
        !ret
      end

  fun Pack_unpackReal32Little (number:Real32.real)
      : (Word8.word * Word8.word * Word8.word * Word8.word) =
      let
        val buffer = ya_String_allocateMutableNoInit 0w4
        val _ = ya_Pack_unpackReal32Little (number, buffer)
      in
        (Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 0))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 1))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 2))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 3))))
      end

  fun Pack_unpackReal32Big (number:Real32.real)
      : (Word8.word * Word8.word * Word8.word * Word8.word) =
      let
        val buffer = ya_String_allocateMutableNoInit 0w4
        val _ = ya_Pack_unpackReal32Little (number, buffer)
      in
        (Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 3))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 2))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 1))),
         Word8.fromInt (Char.ord (SMLSharp.PrimString.sub_unsafe (buffer, 0))))
      end

end
end
