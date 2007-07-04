/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: SystemDef.hh,v 1.16.6.1 2007/07/04 06:45:14 katsu Exp $
 */
#ifndef SystemDef_hh_
#define SystemDef_hh_

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdexcept>

#include <stdlib.h>
#include <string.h>

#if defined(__MINGW32__) || defined(__CYGWIN32__)
/* see http://www.cygwin.com/ml/cygwin/2005-09/msg00903.html */
#ifndef NOMINMAX
#define NOMINMAX
#endif
# include <windows.h>
#endif

///////////////////////////////////////////////////////////////////////////////

#ifdef USE_NAMESPACE
namespace jp_ac_jaist_iml {
#endif

typedef char ByteValue;

#if SIZEOF_VOIDP == SIZEOF_INT && SIZEOF_INT == 4
typedef signed int SInt32Value;
typedef unsigned int UInt32Value;
#elif SIZEOF_VOIDP == SIZEOF_LONG && SIZEOF_LONG == 4
typedef signed long SInt32Value;
typedef unsigned long UInt32Value;
#else
#error ---- SML# requires sizeof(void*) == sizeof(int or long) ----
#endif

#if SIZEOF_SHORT == 2
typedef signed short SInt16Value;
typedef unsigned short UInt16Value;
#elif SIZEOF_INT == 2
typedef signed int SInt16Value;
typedef unsigned int UInt16Value;
#else
#error ---- 64bit floating point number type is not found ----
#endif

typedef signed char SInt8Value;
typedef unsigned char UInt8Value;

#if SIZEOF_DOUBLE == 8
typedef double Real64Value;
#elif SIZEOF_FLOAT == 8
typedef float Real64Value;
#else
#error ---- 64bit floating point number type is not found ----
#endif

#if SIZEOF_FLOAT == 4
typedef float Real32Value;
#else
#error ---- 32bit floating point number type is not found ----
#endif

typedef bool BoolValue;

#define BOOLVALUE_TRUE true
#define BOOLVALUE_FALSE false

#ifdef USE_NAMESPACE
}
#endif

///////////////////////////////////////////////////////////////////////////////

#include <math.h>

#define ABS_SINT32(arg)				\
::labs(arg)

#define ABS_REAL64(arg) \
::fabs(arg)

///////////////////////////////////////////////////////////////////////////////

// FIXME: move to "missing"

#ifdef HAVE_IEEEFP_H
#include <ieeefp.h>
#endif

#ifdef HAVE_FPCLASS

inline
int IEEEREAL_CLASS(double realValue)
{
  switch(fpclass(realValue))
    {
      // see Real.sml
      case FP_SNAN: return 0; break;
      case FP_QNAN: return 1; break;
      case FP_NINF: return 2; break;
      case FP_PINF: return 3; break;
      case FP_NDENORM: return 4; break;
      case FP_PDENORM: return 5; break;
      case FP_NZERO: return 6; break;
      case FP_PZERO: return 7; break;
      case FP_NNORM: return 8; break;
      case FP_PNORM: return 9; break;
    }
};

#else /* HAVE_FPCLASS */

inline
int IEEEREAL_CLASS(double realValue)
{
    if(isnan(realValue)){
        return 0;
    }
    else if(isinf(realValue)){
        return (realValue < 0.0) ? 2 : 3;
    }
    else if(0.0 == realValue){
        return 6;
    }
    else{
        return (realValue < 0.0) ? 8 : 9;
    }
}

#endif /* HAVE_FPCLASS */

///////////////////////////////////////////////////////////////////////////////

/*
 * int DLL_CLOSE(handle)
 *     returns 0 if succeeded, non-zero if failed.
 */

#ifdef HAVE_DLOPEN

#include <dlfcn.h>
typedef void* DLL_HANDLE;
#define DLL_INIT() 
#define DLL_EXIT()
#define DLL_OPEN(name) dlopen((name), RTLD_LAZY)
#define DLL_CLOSE(dllHandle) dlclose(dllHandle)
#define DLL_GET_SYM(dllHandle, name) dlsym((dllHandle), (name))
#define DLL_ERROR() dlerror()

#else /* HAVE_DLOPEN */
#if defined(__MINGW32__)

typedef HMODULE DLL_HANDLE;
#define DLL_INIT() 
#define DLL_EXIT()
#define DLL_OPEN(name) LoadLibrary(name)
#define DLL_CLOSE(dllHandle) (!FreeLibrary(dllHandle))
#define DLL_GET_SYM(dllHandle, name) \
            (void*)(GetProcAddress((dllHandle), (name)))

static char DLLErrorMessage[256];
static char* DLL_ERROR()
{
    DWORD errorCode = 
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,
                  0,
                  GetLastError(),
                  LANG_USER_DEFAULT,
                  (LPTSTR)DLLErrorMessage,
                  sizeof(DLLErrorMessage),
                  NULL);
    return DLLErrorMessage;
}

#else /* defined(__MINGW32__) */

typedef void* DLL_HANDLE;
#define DLL_INIT() 
#define DLL_EXIT()
#define DLL_OPEN(name) ((void*)0)
#define DLL_CLOSE(dllHandle) (-1)
#define DLL_GET_SYM(dllHandle, name) ((void*)0)
#define DLL_ERROR() ("not implemented")

#endif /* defined(__MINGW32__) */
#endif /* HAVE_DLOPEN */

///////////////////////////////////////////////////////////////////////////////

/*
 * void* ALLOCATE_MEMORY(size_t size)
 *
 * @param size size of required memory (in bytes)
 * @return the address of allocated memory
 *
 */
#ifndef ALLOCATE_MEMORY
#define ALLOCATE_MEMORY(size) ::malloc((size))
#endif

/*
 * void* REALLOCATE_MEMORY(void* address, size_t size)
 *
 * @param address the address ALLOCATE_MEMORY returned
 * @param size size of required memory (in bytes)
 * @return the address of allocated memory
 *
 */
#ifndef REALLOCATE_MEMORY
#define REALLOCATE_MEMORY(buffer,size) ::realloc((void*)(buffer), (size))
#endif

/*
 * void RELEASE_MEMORY(void* address)
 *
 * @param address the address ALLOCATE_MEMORY returned
 */
#ifndef RELEASE_MEMORY
#define RELEASE_MEMORY(buffer) ::free((void*)buffer)
#endif

/*
 * void COPY_MEMORY(void* dst, void* src, size_t size)
 *
 * @param dst destination address
 * @param src source address
 * @param size size to copy (in bytes)
 */
#ifndef COPY_MEMORY
#define COPY_MEMORY(dst,src,size) ::memcpy((void*)(dst),(void*)(src),(size))
#endif

/*
 * void FILL_MEMORY(void* buffer, int value, size_t size)
 *
 * @param buffer address of memory
 * @param value
 * @param size the number of byte
 */
#ifndef FILL_MEMORY
#define FILL_MEMORY(buffer,value,size) ::memset((void*)(buffer),(value),(size))
#endif

/*
 * void COMPARE_MEMORY(void* left, void* right, size_t size)
 *
 * @param left an address
 * @param right another address
 * @param size size to copy (in bytes)
 */
#ifndef COMPARE_MEMORY
#define COMPARE_MEMORY(left,right,size) ::memcmp((void*)(left),(void*)(right),(size))
#endif

///////////////////////////////////////////////////////////////////////////////

#ifdef WORDS_BIGENDIAN
#define NATIVE_BYTE_ORDER (Executable::BigEndian)
#define BYTE_ORDER_BIG_ENDIAN
#else
#define NATIVE_BYTE_ORDER (Executable::LittleEndian)
#define BYTE_ORDER_LITTLE_ENDIAN
#endif

///////////////////////////////////////////////////////////////////////////////

typedef int FileDescriptor; // ToDo : platform specific ??

///////////////////////////////////////////////////////////////////////////////

#ifdef USE_NAMESPACE

#define BEGIN_NAMESPACE(name) namespace name {
#define END_NAMESPACE }

#else

#define BEGIN_NAMESPACE(name)
#define END_NAMESPACE

#endif

#ifdef USE_NAMESPACE
namespace jp_ac_jaist_iml_runtime { using namespace jp_ac_jaist_iml; }
#endif

///////////////////////////////////////////////////////////////////////////////

// FIXME: compiler specific
#ifdef __GCC__
#define INLINE_MODIFIER inline __attribute__((always_inline))
#else
#define INLINE_MODIFIER inline
#endif

#if defined(NINLINE) || defined(IML_DEBUG)
#define INLINE_FUN
#else
#define INLINE_FUN INLINE_MODIFIER
#endif

#if defined(__MINGW32__) || defined(__CYGWIN32__)
#define CDECL_FUN __attribute__((cdecl))
#define STDCALL_FUN __attribute__((stdcall))
#else
#define CDECL_FUN
#define STDCALL_FUN
#endif

///////////////////////////////////////////////////////////////////////////////

#endif /* SystemDef_hh_ */
