#ifndef PRIMITIVES_HH_
#define PRIMITIVES_HH_

#include "SystemDef.hh"
#include "RuntimeTypes.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

typedef
void (*Primitive)(UInt32Value argsCount, Cell* argumentRefs[], Cell* resultRef);

// ToDo : these are to be enclosed in a class (ex. PrimitivesTable. ) ?

typedef struct {
    const char *name;
    Primitive prim;
} PrimitiveEntry;

extern PrimitiveEntry primitives[];

extern const int NUMBER_OF_PRIMITIVES;

UInt32Value find_primitive_index(const char *name);

// ToDo : every primitive implementing function is to be global ?

extern Primitive IMLPrim_Int_toString;
extern Primitive IMLPrim_LargeInt_toString;
extern Primitive IMLPrim_LargeInt_toInt;
extern Primitive IMLPrim_LargeInt_toWord;
extern Primitive IMLPrim_LargeInt_fromInt;
extern Primitive IMLPrim_LargeInt_fromWord;
extern Primitive IMLPrim_LargeInt_pow;
extern Primitive IMLPrim_LargeInt_log2;
extern Primitive IMLPrim_LargeInt_orb;
extern Primitive IMLPrim_LargeInt_xorb;
extern Primitive IMLPrim_LargeInt_andb;
extern Primitive IMLPrim_LargeInt_notb;
extern Primitive IMLPrim_Word_toString;
extern Primitive IMLPrim_Real_fromInt;
extern Primitive IMLPrim_Real_toString;
extern Primitive IMLPrim_Real_floor;
extern Primitive IMLPrim_Real_ceil;
extern Primitive IMLPrim_Real_trunc;
extern Primitive IMLPrim_Real_round;
extern Primitive IMLPrim_Real_split;
extern Primitive IMLPrim_Real_toManExp;
extern Primitive IMLPrim_Real_fromManExp;
extern Primitive IMLPrim_Real_copySign;
extern Primitive IMLPrim_Real_equal;
extern Primitive IMLPrim_Real_class;
extern Primitive IMLPrim_Real_dtoa;
extern Primitive IMLPrim_Real_strtod;
extern Primitive IMLPrim_Real_nextAfter;
extern Primitive IMLPrim_Real_toFloat;
extern Primitive IMLPrim_Real_fromFloat;
extern Primitive IMLPrim_Float_fromInt;
extern Primitive IMLPrim_Float_toString;
extern Primitive IMLPrim_Float_floor;
extern Primitive IMLPrim_Float_ceil;
extern Primitive IMLPrim_Float_trunc;
extern Primitive IMLPrim_Float_round;
extern Primitive IMLPrim_Float_split;
extern Primitive IMLPrim_Float_toManExp;
extern Primitive IMLPrim_Float_fromManExp;
extern Primitive IMLPrim_Float_copySign;
extern Primitive IMLPrim_Float_equal;
extern Primitive IMLPrim_Float_class;
extern Primitive IMLPrim_Float_dtoa;
extern Primitive IMLPrim_Float_strtod;
extern Primitive IMLPrim_Float_nextAfter;
extern Primitive IMLPrim_Char_toString;
extern Primitive IMLPrim_Char_toEscapedString;
extern Primitive IMLPrim_Char_ord;
extern Primitive IMLPrim_Char_chr;
extern Primitive IMLPrim_String_concat2;
extern Primitive IMLPrim_String_sub;
extern Primitive IMLPrim_String_size;
extern Primitive IMLPrim_String_substring;
extern Primitive IMLPrim_String_update;
extern Primitive IMLPrim_String_allocateMutable;
extern Primitive IMLPrim_String_allocateImmutable;
extern Primitive IMLPrim_String_copy;
extern Primitive IMLPrim_print;
extern Primitive IMLPrim_Internal_IPToString;
extern Primitive IMLPrim_Time_gettimeofday;
extern Primitive IMLPrim_GenericOS_errorName;
extern Primitive IMLPrim_GenericOS_errorMsg;
extern Primitive IMLPrim_GenericOS_syserror;
extern Primitive IMLPrim_GenericOS_getSTDIN;
extern Primitive IMLPrim_GenericOS_getSTDOUT;
extern Primitive IMLPrim_GenericOS_getSTDERR;
extern Primitive IMLPrim_GenericOS_fileOpen;
extern Primitive IMLPrim_GenericOS_fileClose;
extern Primitive IMLPrim_GenericOS_fileRead;
extern Primitive IMLPrim_GenericOS_fileReadBuf;
extern Primitive IMLPrim_GenericOS_fileWrite;
extern Primitive IMLPrim_GenericOS_fileSetPosition;
extern Primitive IMLPrim_GenericOS_fileGetPosition;
extern Primitive IMLPrim_GenericOS_fileNo;
extern Primitive IMLPrim_GenericOS_fileSize;
extern Primitive IMLPrim_GenericOS_isRegFD;
extern Primitive IMLPrim_GenericOS_isDirFD;
extern Primitive IMLPrim_GenericOS_isChrFD;
extern Primitive IMLPrim_GenericOS_isBlkFD;
extern Primitive IMLPrim_GenericOS_isLinkFD;
extern Primitive IMLPrim_GenericOS_isFIFOFD;
extern Primitive IMLPrim_GenericOS_isSockFD;
extern Primitive IMLPrim_GenericOS_poll;
extern Primitive IMLPrim_GenericOS_getPOLLINFlag;
extern Primitive IMLPrim_GenericOS_getPOLLOUTFlag;
extern Primitive IMLPrim_GenericOS_getPOLLPRIFlag;
extern Primitive IMLPrim_GenericOS_system;
extern Primitive IMLPrim_GenericOS_exit;
extern Primitive IMLPrim_GenericOS_getEnv;
extern Primitive IMLPrim_GenericOS_sleep;
extern Primitive IMLPrim_GenericOS_openDir;
extern Primitive IMLPrim_GenericOS_readDir;
extern Primitive IMLPrim_GenericOS_rewindDir;
extern Primitive IMLPrim_GenericOS_closeDir;
extern Primitive IMLPrim_GenericOS_chDir;
extern Primitive IMLPrim_GenericOS_getDir;
extern Primitive IMLPrim_GenericOS_mkDir;
extern Primitive IMLPrim_GenericOS_rmDir;
extern Primitive IMLPrim_GenericOS_isDir;
extern Primitive IMLPrim_GenericOS_isLink;
extern Primitive IMLPrim_GenericOS_readLink;
extern Primitive IMLPrim_GenericOS_getFileModTime;
extern Primitive IMLPrim_GenericOS_setFileTime;
extern Primitive IMLPrim_GenericOS_getFileSize;
extern Primitive IMLPrim_GenericOS_remove;
extern Primitive IMLPrim_GenericOS_rename;
extern Primitive IMLPrim_GenericOS_isFileExists;
extern Primitive IMLPrim_GenericOS_isFileReadable;
extern Primitive IMLPrim_GenericOS_isFileWritable;
extern Primitive IMLPrim_GenericOS_isFileExecutable;
extern Primitive IMLPrim_GenericOS_tempFileName;
extern Primitive IMLPrim_GenericOS_getFileID;
extern Primitive IMLPrim_CommandLine_name;
extern Primitive IMLPrim_CommandLine_arguments;
extern Primitive IMLPrim_Date_ascTime;
extern Primitive IMLPrim_Date_localTime;
extern Primitive IMLPrim_Date_gmTime;
extern Primitive IMLPrim_Date_mkTime;
extern Primitive IMLPrim_Date_strfTime;
extern Primitive IMLPrim_Timer_getTime;
extern Primitive IMLPrim_Math_sqrt;
extern Primitive IMLPrim_Math_sin;
extern Primitive IMLPrim_Math_cos;
extern Primitive IMLPrim_Math_tan;
extern Primitive IMLPrim_Math_asin;
extern Primitive IMLPrim_Math_acos;
extern Primitive IMLPrim_Math_atan;
extern Primitive IMLPrim_Math_atan2;
extern Primitive IMLPrim_Math_exp;
extern Primitive IMLPrim_Math_pow;
extern Primitive IMLPrim_Math_ln;
extern Primitive IMLPrim_Math_log10;
extern Primitive IMLPrim_Math_sinh;
extern Primitive IMLPrim_Math_cosh;
extern Primitive IMLPrim_Math_tanh;
extern Primitive IMLPrim_StandardC_errno;
extern Primitive IMLPrim_UnmanagedMemory_allocate;
extern Primitive IMLPrim_UnmanagedMemory_release;
extern Primitive IMLPrim_UnmanagedMemory_sub;
extern Primitive IMLPrim_UnmanagedMemory_update;
extern Primitive IMLPrim_UnmanagedMemory_subWord;
extern Primitive IMLPrim_UnmanagedMemory_updateWord;
extern Primitive IMLPrim_UnmanagedMemory_subReal;
extern Primitive IMLPrim_UnmanagedMemory_updateReal;
extern Primitive IMLPrim_UnmanagedMemory_import;
extern Primitive IMLPrim_UnmanagedMemory_export;
extern Primitive IMLPrim_UnmanagedString_size;
extern Primitive IMLPrim_DynamicLink_dlopen;
extern Primitive IMLPrim_DynamicLink_dlclose;
extern Primitive IMLPrim_DynamicLink_dlsym;
extern Primitive IMLPrim_GC_addFinalizable;
extern Primitive IMLPrim_GC_doGC;
extern Primitive IMLPrim_GC_fixedCopy;
extern Primitive IMLPrim_GC_releaseFLOB;
extern Primitive IMLPrim_GC_addressOfFLOB;
extern Primitive IMLPrim_GC_copyBlock;
extern Primitive IMLPrim_GC_isAddressOfBlock;
extern Primitive IMLPrim_GC_isAddressOfFLOB;
extern Primitive IMLPrim_Platform_getPlatform;
extern Primitive IMLPrim_Platform_isBigEndian;
extern Primitive IMLPrim_Pack_packWord32Little;
extern Primitive IMLPrim_Pack_packWord32Big;
extern Primitive IMLPrim_Pack_unpackWord32Little;
extern Primitive IMLPrim_Pack_unpackWord32Big;
extern Primitive IMLPrim_Pack_packReal64Little;
extern Primitive IMLPrim_Pack_packReal64Big;
extern Primitive IMLPrim_Pack_unpackReal64Little;
extern Primitive IMLPrim_Pack_unpackReal64Big;
extern Primitive IMLPrim_Pack_packReal32Little;
extern Primitive IMLPrim_Pack_packReal32Big;
extern Primitive IMLPrim_Pack_unpackReal32Little;
extern Primitive IMLPrim_Pack_unpackReal32Big;
extern Primitive IMLPrim_SMLSharpCommandLine_executableImageName;
extern Primitive IMLPrim_DynamicBind_importSymbol;
extern Primitive IMLPrim_DynamicBind_exportSymbol;
extern Primitive IMLPrim_IEEEReal_setRoundingMode;
extern Primitive IMLPrim_IEEEReal_getRoundingMode;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // PRIMITIVES_HH_
