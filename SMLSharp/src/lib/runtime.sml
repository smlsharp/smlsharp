use "./runtime.sig";

structure SMLSharp = struct
open SMLSharp
structure Runtime : SMLSHARP_RUNTIME = struct

(* # List of primitive operators. *)
(* # See README.txt. *)
(* # $Id: primitives.csv,v 1.86 2008/03/11 08:53:57 katsu Exp $ *)
(*  *)
(* :=,assign,"['a.('a) ref * 'a -> unit]",2,,,effective *)
(*  *)
(* =,equal,"[''a.''a * ''a -> bool]",2,Equal,,noneffective *)
(*  *)
(* # Arithmetic primitives may raise exception, except for primitives on 'real'. *)
(* addInt,,"int * int -> int",2,AddInt,,effective *)
(* addLargeInt,,"largeInt * largeInt -> largeInt",2,AddLargeInt,,effective *)
(* addReal,,"real * real -> real",2,AddReal,,noneffective *)
(* addFloat,,"float * float -> float",2,AddFloat,,noneffective *)
(* addWord,,"word * word -> word",2,AddWord,,effective *)
(* addByte,,"byte * byte -> byte",2,AddByte,,effective *)
(* subInt,,"int * int -> int",2,SubInt,,effective *)
(* subLargeInt,,"largeInt * largeInt -> largeInt",2,SubLargeInt,,effective *)
(* subReal,,"real * real -> real",2,SubReal,,noneffective *)
(* subFloat,,"float * float -> float",2,SubFloat,,noneffective *)
(* subWord,,"word * word -> word",2,SubWord,,effective *)
(* subByte,,"byte * byte -> byte",2,SubByte,,effective *)
(* mulInt,,"int * int -> int",2,MulInt,,effective *)
(* mulLargeInt,,"largeInt * largeInt -> largeInt",2,MulLargeInt,,effective *)
(* mulReal,,"real * real -> real",2,MulReal,,noneffective *)
(* mulFloat,,"float * float -> float",2,MulFloat,,noneffective *)
(* mulWord,,"word * word -> word",2,MulWord,,effective *)
(* mulByte,,"byte * byte -> byte",2,MulByte,,effective *)
(* divInt,,"int * int -> int",2,DivInt,,effective *)
(* divLargeInt,,"largeInt * largeInt -> largeInt",2,DivLargeInt,,effective *)
(* divWord,,"word * word -> word",2,DivWord,,effective *)
(* divByte,,"byte * byte -> byte",2,DivByte,,effective *)
(* /,divReal,"real * real -> real",2,DivReal,,noneffective *)
(* divFloat,,"float * float -> float",2,DivFloat,,noneffective *)
(* modInt,,"int * int -> int",2,ModInt,,effective *)
(* modLargeInt,,"largeInt * largeInt -> largeInt",2,ModLargeInt,,effective *)
(* modWord,,"word * word -> word",2,ModWord,,effective *)
(* modByte,,"byte * byte -> byte",2,ModByte,,effective *)
(* quotInt,,"int * int -> int",2,QuotInt,,effective *)
val quotLargeInt = _import "quotLargeInt" : IntInf.int * IntInf.int -> IntInf.int (* QuotLargeInt *)
(* remInt,,"int * int -> int",2,RemInt,,effective *)
val remLargeInt = _import "remLargeInt" : IntInf.int * IntInf.int -> IntInf.int (* RemLargeInt *)
(* negInt,,"int -> int",1,NegInt,,effective *)
(* negLargeInt,,"largeInt -> largeInt",1,NegLargeInt,,effective *)
(* negReal,,"real -> real",1,NegReal,,noneffective *)
(* negFloat,,"float -> float",1,NegFloat,,noneffective *)
(* absInt,,"int -> int",1,AbsInt,,effective *)
(* absLargeInt,,"largeInt -> largeInt",1,AbsLargeInt,,effective *)
(* absReal,,"real-> real",1,AbsReal,,noneffective *)
(* absFloat,,"float-> float",1,AbsFloat,,noneffective *)

(* # Comparison primitives are noneffective because they do not raise exception. *)
(* ltInt,,"int * int -> bool",2,LtInt,,noneffective *)
(* ltLargeInt,,"largeInt * largeInt -> bool",2,LtLargeInt,,noneffective *)
(* ltReal,,"real * real -> bool",2,LtReal,,noneffective *)
(* ltFloat,,"float * float -> bool",2,LtFloat,,noneffective *)
(* ltWord,,"word * word -> bool",2,LtWord,,noneffective *)
(* ltByte,,"byte * byte -> bool",2,LtByte,,noneffective *)
(* ltChar,,"char * char -> bool",2,LtChar,,noneffective *)
(* ltString,,"string * string -> bool",2,LtString,,noneffective *)
(* gtInt,,"int * int -> bool",2,GtInt,,noneffective *)
(* gtLargeInt,,"largeInt * largeInt -> bool",2,GtLargeInt,,noneffective *)
(* gtReal,,"real * real -> bool",2,GtReal,,noneffective *)
(* gtFloat,,"float * float -> bool",2,GtFloat,,noneffective *)
(* gtWord,,"word * word -> bool",2,GtWord,,noneffective *)
(* gtByte,,"byte * byte -> bool",2,GtByte,,noneffective *)
(* gtChar,,"char * char -> bool",2,GtChar,,noneffective *)
(* gtString,,"string * string -> bool",2,GtString,,noneffective *)
(* lteqInt,,"int * int -> bool",2,LteqInt,,noneffective *)
(* lteqLargeInt,,"largeInt * largeInt -> bool",2,LteqLargeInt,,noneffective *)
(* lteqReal,,"real * real -> bool",2,LteqReal,,noneffective *)
(* lteqFloat,,"float * float -> bool",2,LteqFloat,,noneffective *)
(* lteqWord,,"word * word -> bool",2,LteqWord,,noneffective *)
(* lteqByte,,"byte * byte -> bool",2,LteqByte,,noneffective *)
(* lteqChar,,"char * char -> bool",2,LteqChar,,noneffective *)
(* lteqString,,"string * string -> bool",2,LteqString,,noneffective *)
(* gteqInt,,"int * int -> bool",2,GteqInt,,noneffective *)
(* gteqLargeInt,,"largeInt * largeInt -> bool",2,GteqLargeInt,,noneffective *)
(* gteqReal,,"real * real -> bool",2,GteqReal,,noneffective *)
(* gteqFloat,,"float * float -> bool",2,GteqFloat,,noneffective *)
(* gteqWord,,"word * word -> bool",2,GteqWord,,noneffective *)
(* gteqByte,,"byte * byte -> bool",2,GteqByte,,noneffective *)
(* gteqChar,,"char * char -> bool",2,GteqChar,,noneffective *)
(* gteqString,,"string * string -> bool",2,GteqString,,noneffective *)

val Int_toString = _import "Int_toString" : int -> string

val LargeInt_toString = _import "LargeInt_toString" : IntInf.int -> string
val LargeInt_toInt = _import "LargeInt_toInt" : IntInf.int -> int
val LargeInt_toWord = _import "LargeInt_toWord" : IntInf.int -> word
val LargeInt_fromInt = _import "LargeInt_fromInt" : int -> IntInf.int
val LargeInt_fromWord = _import "LargeInt_fromWord" : word -> IntInf.int
val LargeInt_pow = _import "LargeInt_pow" : IntInf.int * int -> IntInf.int
val LargeInt_log2 = _import "LargeInt_log2" : IntInf.int -> int
val LargeInt_orb = _import "LargeInt_orb" : IntInf.int * IntInf.int -> IntInf.int
val LargeInt_xorb = _import "LargeInt_xorb" : IntInf.int * IntInf.int -> IntInf.int
val LargeInt_andb = _import "LargeInt_andb" : IntInf.int * IntInf.int -> IntInf.int
val LargeInt_notb = _import "LargeInt_notb" : IntInf.int -> IntInf.int

(* Byte_toIntX,,"byte -> int",1,Byte_toIntX,,effective *)
(* Byte_fromInt,,"int -> byte",1,Byte_fromInt,,effective *)

(* Word_toIntX,,"word -> int",1,Word_toIntX,,effective *)
(* Word_fromInt,,"int -> word",1,Word_fromInt,,effective *)
(* Word_andb,,"word * word -> word",2,Word_andb,,effective *)
(* Word_orb,,"word * word -> word",2,Word_orb,,effective *)
(* Word_xorb,,"word * word -> word",2,Word_xorb,,effective *)
(* Word_notb,,"word -> word",1,Word_notb,,effective *)
(* Word_leftShift,,"word * word -> word",2,Word_leftShift,,effective *)
(* Word_logicalRightShift,,"word * word -> word",2,Word_logicalRightShift,,effective *)
(* Word_arithmeticRightShift,,"word * word -> word",2,Word_arithmeticRightShift,,effective *)
val Word_toString = _import "Word_toString" : word -> string

(* Real_fromInt,,"int -> real",1,,IMLPrim_Real_fromInt,effective *)
val Real_toString = _import "Real_toString" : real -> string
val Real_floor = _import "Real_floor" : real -> int
val Real_ceil = _import "Real_ceil" : real -> int
(* Real_trunc,,"real -> int",1,,IMLPrim_Real_trunc,effective *)
val Real_round = _import "Real_round" : real -> int
val Real_split = _import "Real_split" : real -> real * real
val Real_toManExp = _import "Real_toManExp" : real -> real * int
val Real_fromManExp = _import "Real_fromManExp" : real * int -> real
val Real_copySign = _import "Real_copySign" : real * real -> real
(* Real_equal,,"real * real -> bool",2,,IMLPrim_Real_equal,effective *)
val Real_class = _import "Real_class" : real -> int
val Real_dtoa = _import "Real_dtoa" : (real * int) -> string * int
val Real_strtod = _import "Real_strtod" : string -> real
val Real_nextAfter = _import "Real_nextAfter" : real * real -> real
val Real_toFloat = _import "Real_toFloat" : real -> Real32.real
val Real_fromFloat = _import "Real_fromFloat" : Real32.real -> real

(* Float_fromInt,,"int -> float",1,,IMLPrim_Float_fromInt,effective *)
val Float_toString = _import "Float_toString" : Real32.real -> string
val Float_floor = _import "Float_floor" : Real32.real -> int
val Float_ceil = _import "Float_ceil" : Real32.real -> int
(* Float_trunc,,"float -> int",1,,IMLPrim_Float_trunc,effective *)
val Float_round = _import "Float_round" : Real32.real -> int
val Float_split = _import "Float_split" : Real32.real -> Real32.real * Real32.real
val Float_toManExp = _import "Float_toManExp" : Real32.real -> Real32.real * int
val Float_fromManExp = _import "Float_fromManExp" : Real32.real * int -> Real32.real
val Float_copySign = _import "Float_copySign" : Real32.real * Real32.real -> Real32.real
(* Float_equal,,"float * float -> bool",2,,IMLPrim_Float_equal,effective *)
val Float_class = _import "Float_class" : Real32.real -> int
val Float_dtoa = _import "Float_dtoa" : (Real32.real * int) -> string * int
val Float_strtod = _import "Float_strtod" : string -> Real32.real
val Float_nextAfter = _import "Float_nextAfter" : Real32.real * Real32.real -> Real32.real

(* # Char_chr may raise Chr exception. *)
val Char_toString = _import "Char_toString" : char -> string
val Char_toEscapedString = _import "Char_toEscapedString" : char -> string
(* Char_ord,,"char -> int",1,,IMLPrim_Char_ord,effective *)
(* Char_chr,,"int -> char",1,,IMLPrim_Char_chr,effective *)

val String_concat2 = _import "String_concat2" : string * string -> string
(* String_sub,,"string * int -> char",2,,IMLPrim_String_sub,effective *)
(* String_size,,"string -> int",1,,IMLPrim_String_size,effective *)
val String_substring = _import "String_substring" : string * int * int -> string
(* String_update,,"string * int * char -> unit",3,,IMLPrim_String_update,effective *)
(* String_allocateMutable,,"int * char -> string",2,,IMLPrim_String_allocateMutable,effective *)
(* String_allocateImmutable,,"int * char -> string",2,,IMLPrim_String_allocateImmutable,effective *)
(* String_copy,,"string * int * string * int * int -> unit",5,,IMLPrim_String_copy,effective *)

val print = _import "print" : string -> unit

(* Array_mutableArray,,"['a.int * 'a -> ('a) array]",2,,,effective *)
(* Array_immutableArray,,"['a.int * 'a -> ('a) array]",2,,,effective *)
(* Array_sub,,"['a.('a) array * int -> 'a]",2,,,effective *)
(* Array_update,,"['a.('a) array * int * 'a -> unit]",3,,,effective *)
(* Array_length,,"['a.('a) array -> int]",1,Array_length,,effective *)
(* Array_copy,,"['a.('a) array * int * ('a) array * int * int -> unit]",5,,,effective *)

val Internal_getCurrentIP = _import "Internal_getCurrentIP" : int -> word * word (* CurrentIP *)
val Internal_getStackTrace = _import "Internal_getStackTrace" : int -> (word * word) array (* StackTrace *)
val Internal_IPToString = _import "Internal_IPToString" : word * word -> string

val Time_gettimeofday = _import "Time_gettimeofday" : int -> int * int

val GenericOS_errorName = _import "GenericOS_errorName" : int -> string
val GenericOS_errorMsg = _import "GenericOS_errorMsg" : int -> string
val GenericOS_syserror = _import "GenericOS_syserror" : string -> (int) option

val GenericOS_getSTDIN = _import "GenericOS_getSTDIN" : int -> word
val GenericOS_getSTDOUT = _import "GenericOS_getSTDOUT" : int -> word
val GenericOS_getSTDERR = _import "GenericOS_getSTDERR" : int -> word
(* # FILE* fileOpen(fileName, mode) *)
val GenericOS_fileOpen = _import "GenericOS_fileOpen" : string * string -> word
val GenericOS_fileClose = _import "GenericOS_fileClose" : word -> unit
(* # buffer fileRead(FILE*, nbytes) *)
val GenericOS_fileRead = _import "GenericOS_fileRead" : word * int -> string
(* # readBytes fileReadBuf(FILE*, buffer, start, nbytes) *)
val GenericOS_fileReadBuf = _import "GenericOS_fileReadBuf" : word * string * int * int -> int
(* # writtenBytes fileWrite(FILE*, buffer, start, nbytes) *)
val GenericOS_fileWrite = _import "GenericOS_fileWrite" : word * string * int * int -> int
val GenericOS_fileSetPosition = _import "GenericOS_fileSetPosition" : word * int -> int
val GenericOS_fileGetPosition = _import "GenericOS_fileGetPosition" : word -> int
(* # returns the file descriptor. *)
val GenericOS_fileNo = _import "GenericOS_fileNo" : word -> int
(* # returns size of an opened file *)
val GenericOS_fileSize = _import "GenericOS_fileSize" : word -> int

val GenericOS_isRegFD = _import "GenericOS_isRegFD" : word -> bool
val GenericOS_isDirFD = _import "GenericOS_isDirFD" : word -> bool
val GenericOS_isChrFD = _import "GenericOS_isChrFD" : word -> bool
val GenericOS_isBlkFD = _import "GenericOS_isBlkFD" : word -> bool
val GenericOS_isLinkFD = _import "GenericOS_isLinkFD" : word -> bool
val GenericOS_isFIFOFD = _import "GenericOS_isFIFOFD" : word -> bool
val GenericOS_isSockFD = _import "GenericOS_isSockFD" : word -> bool
val GenericOS_poll = _import "GenericOS_poll" : ((int * word) array * (int * int) option) -> (int * word) array
val GenericOS_getPOLLINFlag = _import "GenericOS_getPOLLINFlag" : int -> word
val GenericOS_getPOLLOUTFlag = _import "GenericOS_getPOLLOUTFlag" : int -> word
val GenericOS_getPOLLPRIFlag = _import "GenericOS_getPOLLPRIFlag" : int -> word

(* # int system(char* name) *)
val GenericOS_system = _import "GenericOS_system" : string -> int
(* # void exit(int) *)
val GenericOS_exit = _import "GenericOS_exit" : int -> unit
val GenericOS_getEnv = _import "GenericOS_getEnv" : string -> (string) option
(* # void sleep(unsigned int seconds) *)
val GenericOS_sleep = _import "GenericOS_sleep" : word -> unit

val GenericOS_openDir = _import "GenericOS_openDir" : string -> word
val GenericOS_readDir = _import "GenericOS_readDir" : word -> (string) option
val GenericOS_rewindDir = _import "GenericOS_rewindDir" : word -> unit
val GenericOS_closeDir = _import "GenericOS_closeDir" : word -> unit
val GenericOS_chDir = _import "GenericOS_chDir" : string -> unit
val GenericOS_getDir = _import "GenericOS_getDir" : int -> string
val GenericOS_mkDir = _import "GenericOS_mkDir" : string -> unit
val GenericOS_rmDir = _import "GenericOS_rmDir" : string -> unit
val GenericOS_isDir = _import "GenericOS_isDir" : string -> bool
val GenericOS_isLink = _import "GenericOS_isLink" : string -> bool
val GenericOS_readLink = _import "GenericOS_readLink" : string -> string
val GenericOS_getFileModTime = _import "GenericOS_getFileModTime" : string -> int
val GenericOS_setFileTime = _import "GenericOS_setFileTime" : string * int -> unit
val GenericOS_getFileSize = _import "GenericOS_getFileSize" : string -> int
val GenericOS_remove = _import "GenericOS_remove" : string -> unit
val GenericOS_rename = _import "GenericOS_rename" : string * string -> unit
val GenericOS_isFileExists = _import "GenericOS_isFileExists" : string -> bool
val GenericOS_isFileReadable = _import "GenericOS_isFileReadable" : string -> bool
val GenericOS_isFileWritable = _import "GenericOS_isFileWritable" : string -> bool
val GenericOS_isFileExecutable = _import "GenericOS_isFileExecutable" : string -> bool
val GenericOS_tempFileName = _import "GenericOS_tempFileName" : () -> string
val GenericOS_getFileID = _import "GenericOS_getFileID" : string -> word

val CommandLine_name = _import "CommandLine_name" : int -> string
val CommandLine_arguments = _import "CommandLine_arguments" : int -> (string) array

val Date_ascTime = _import "Date_ascTime" : (int * int * int * int * int * int * int * int * int) -> string
val Date_localTime = _import "Date_localTime" : int -> (int * int * int * int * int * int * int * int * int)
val Date_gmTime = _import "Date_gmTime" : int -> (int * int * int * int * int * int * int * int * int)
val Date_mkTime = _import "Date_mkTime" : (int * int * int * int * int * int * int * int * int) -> int
val Date_strfTime = _import "Date_strfTime" : (string * (int * int * int * int * int * int * int * int * int)) -> string

val Timer_getTime = _import "Timer_getTime" : int -> (int * int * int * int * int * int)

(* # There Math primitives are effective since underlying GMP may raise exception. *)
val Math_sqrt = _import "Math_sqrt" : real -> real
val Math_sin = _import "Math_sin" : real -> real
val Math_cos = _import "Math_cos" : real -> real
val Math_tan = _import "Math_tan" : real -> real
val Math_asin = _import "Math_asin" : real -> real
val Math_acos = _import "Math_acos" : real -> real
val Math_atan = _import "Math_atan" : real -> real
val Math_atan2 = _import "Math_atan2" : real * real -> real
val Math_exp = _import "Math_exp" : real -> real
val Math_pow = _import "Math_pow" : real * real -> real
val Math_ln = _import "Math_ln" : real -> real
val Math_log10 = _import "Math_log10" : real -> real
val Math_sinh = _import "Math_sinh" : real -> real
val Math_cosh = _import "Math_cosh" : real -> real
val Math_tanh = _import "Math_tanh" : real -> real

val StandardC_errno = _import "StandardC_errno" : () -> int

val UnmanagedMemory_allocate = _import "UnmanagedMemory_allocate" : int -> (unit) ptr
val UnmanagedMemory_release = _import "UnmanagedMemory_release" : (unit) ptr -> unit
(* UnmanagedMemory_sub,,"(unit) ptr -> byte",1,,IMLPrim_UnmanagedMemory_sub,effective *)
val UnmanagedMemory_update = _import "UnmanagedMemory_update" : (unit) ptr * Word8.word -> unit
(* UnmanagedMemory_subWord,,"(unit) ptr -> word",1,,IMLPrim_UnmanagedMemory_subWord,effective *)
val UnmanagedMemory_updateWord = _import "UnmanagedMemory_updateWord" : (unit) ptr * word -> unit
(* UnmanagedMemory_subInt,,"(unit) ptr -> int",1,,IMLPrim_UnmanagedMemory_subWord,effective *)
val UnmanagedMemory_updateInt = _import "UnmanagedMemory_updateInt" : (unit) ptr * int -> unit
(* UnmanagedMemory_subReal,,"(unit) ptr -> real",1,,IMLPrim_UnmanagedMemory_subReal,effective *)
val UnmanagedMemory_updateReal = _import "UnmanagedMemory_updateReal" : (unit) ptr * real -> unit
val UnmanagedMemory_import = _import "UnmanagedMemory_import" : (unit) ptr * int -> string
val UnmanagedMemory_export = _import "UnmanagedMemory_export" : string * int * int -> (unit) ptr
val UnmanagedString_size = _import "UnmanagedString_size" : (unit) ptr -> int

val DynamicLink_dlopen = _import "DynamicLink_dlopen" : string -> (unit) ptr
val DynamicLink_dlclose = _import "DynamicLink_dlclose" : (unit) ptr -> unit
val DynamicLink_dlsym = _import "DynamicLink_dlsym" : (unit) ptr * string -> (unit) ptr

(* # actual domain type of addFinalizable is: 'a ref * ('a ref -> unit) ref *)
val GC_addFinalizable = _import "GC_addFinalizable" : ('a) ref -> int
val GC_doGC = _import "GC_doGC" : int -> unit
val GC_fixedCopy = _import "GC_fixedCopy" : ('a) ref -> unit
val GC_releaseFLOB = _import "GC_releaseFLOB" : ('a) ref -> unit
val GC_addressOfFLOB = _import "GC_addressOfFLOB" : ('a) ref -> (unit) ptr
val GC_copyBlock = _import "GC_copyBlock" : ('a) ref -> unit
val GC_isAddressOfBlock = _import "GC_isAddressOfBlock" : (unit) ptr -> bool
val GC_isAddressOfFLOB = _import "GC_isAddressOfFLOB" : (unit) ptr -> bool

val Platform_getPlatform = _import "Platform_getPlatform" : () -> string
val Platform_isBigEndian = _import "Platform_isBigEndian" : () -> bool

val Pack_packWord32Little = _import "Pack_packWord32Little" : (Word8.word * Word8.word * Word8.word * Word8.word) -> word
val Pack_packWord32Big = _import "Pack_packWord32Big" : (Word8.word * Word8.word * Word8.word * Word8.word) -> word
val Pack_unpackWord32Little = _import "Pack_unpackWord32Little" : word -> (Word8.word * Word8.word * Word8.word * Word8.word)
val Pack_unpackWord32Big = _import "Pack_unpackWord32Big" : word -> (Word8.word * Word8.word * Word8.word * Word8.word)
val Pack_packReal64Little = _import "Pack_packReal64Little" : (Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word) -> real
val Pack_packReal64Big = _import "Pack_packReal64Big" : (Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word) -> real
val Pack_unpackReal64Little = _import "Pack_unpackReal64Little" : real -> (Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word)
val Pack_unpackReal64Big = _import "Pack_unpackReal64Big" : real -> (Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word * Word8.word)

val Pack_packReal32Little = _import "Pack_packReal32Little" : (Word8.word * Word8.word * Word8.word * Word8.word) -> Real32.real
val Pack_packReal32Big = _import "Pack_packReal32Big" : (Word8.word * Word8.word * Word8.word * Word8.word) -> Real32.real
val Pack_unpackReal32Little = _import "Pack_unpackReal32Little" : Real32.real -> (Word8.word * Word8.word * Word8.word * Word8.word)
val Pack_unpackReal32Big = _import "Pack_unpackReal32Big" : Real32.real -> (Word8.word * Word8.word * Word8.word * Word8.word)

val SMLSharpCommandLine_executableImageName = _import "SMLSharpCommandLine_executableImageName" : () -> (string) option

val DynamicBind_importSymbol = _import "DynamicBind_importSymbol" : string -> (unit) ptr
val DynamicBind_exportSymbol = _import "DynamicBind_exportSymbol" : string * (unit) ptr -> unit

val IEEEReal_setRoundingMode = _import "IEEEReal_setRoundingMode" : int -> unit
val IEEEReal_getRoundingMode = _import "IEEEReal_getRoundingMode" : unit -> int

end
end
