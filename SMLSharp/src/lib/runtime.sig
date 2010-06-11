signature SMLSHARP_RUNTIME =
sig

(* To keep track of difference from primitives.csv, all primitives appearing
 * in primitives.csv are listed below with commented out.
 * First column character in each commented-out line describes current status
 * of each primitives.
 *   P : provided by compiler as a builtin primitive.
 *   F : provided by compiler as a builtin foreign function call.
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
val Real_dtoa : real * int -> string * int
val Real_strtod : string -> real

(*P Real_toFloat,,"real -> float",1,,IMLPrim_Real_toFloat,effective *)
(*P Real_fromFloat,,"float -> real",1,,IMLPrim_Real_fromFloat,effective *)

(*P Float_fromInt,,"int -> float",1,,IMLPrim_Float_fromInt,effective *)
val Float_toString : Real32.real -> string
val Float_floor : Real32.real -> int
val Float_ceil : Real32.real -> int
(*P Float_trunc,,"float -> int",1,,IMLPrim_Float_trunc,effective *)
val Float_round : Real32.real -> int
val Float_split : Real32.real -> Real32.real * Real32.real
val Float_toManExp : Real32.real -> Real32.real * int
val Float_fromManExp : Real32.real * int -> Real32.real
val Float_copySign : Real32.real * Real32.real -> Real32.real
(*P Float_equal,,"float * float -> bool",2,,IMLPrim_Float_equal,effective *)
val Float_class : Real32.real -> int
val Float_dtoa : Real32.real * int -> string * int
val Float_strtod : string -> Real32.real

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

end
