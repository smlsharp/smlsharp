/**
 * prim.h
 * @copyright (c) 2007-2010, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__PRIM_H__
#define SMLSHARP__PRIM_H__

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <unistd.h>
#if !defined(HAVE_CONFIG_H) || defined(HAVE_DLFCN_H)
#include <dlfcn.h>
#endif /* HAVE_DLFCN_H */
#if !defined(HAVE_CONFIG_H) || defined(HAVE_FENV_H)
#include <fenv.h>
#endif /* HAVE_FENV_H */

/*
 * Correspondence between ML types and C types:
 *    ML type       C type
 *     int           int
 *     char          char
 *     Word8.word    unsigned char
 *     real          double
 *     Real32.real   float
 *     unit ptr      void *
 *     char ptr      char *
 *     IntInf.int    sml_intinf_t *
 *     string        STRING
 */
typedef char *STRING;
#ifndef SMLSHARP__SMLSHARP_H__
struct sml_intinf;
typedef struct sml_intinf sml_intinf_t;
#endif /* SMLSHARP__SMLSHARP_H__ */

int sml_memcmp(const char *s1, int i1, const char *s2, int i2, int len);

/* compiler builtin primitives */
int prim_fesetround(int x);
int prim_fegetround(void);
int prim_String_cmp(const char *, const char *);
int prim_IntInf_cmp(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t * prim_IntInf_load(const char *);
void prim_CopyMemory(void *, unsigned int, const void *, unsigned int,
		     unsigned int, unsigned int);

STRING prim_String_allocateMutable(int, char);
STRING prim_String_allocateImmutable(int, char);
void prim_String_copy(const char *, int, char *, int, int);
int prim_String_size(const char *);
char prim_String_sub(const char *, int);
void prim_String_update(char *, int, char);
sml_intinf_t * prim_IntInf_abs(sml_intinf_t *);
sml_intinf_t * prim_IntInf_add(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t * prim_IntInf_div(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t * prim_IntInf_mod(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t * prim_IntInf_mul(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t * prim_IntInf_neg(sml_intinf_t *);
sml_intinf_t * prim_IntInf_sub(sml_intinf_t *, sml_intinf_t *);
int prim_UnmanagedMemory_subInt(void *ptr);
double prim_UnmanagedMemory_subReal(void *ptr);
unsigned int prim_UnmanagedMemory_subWord(void *ptr);
unsigned char prim_UnmanagedMemory_subByte(void *ptr);
void *prim_UnmanagedMemory_subPtr(void *p);

/* for basis library implementation */
STRING prim_Int_toString(int);
STRING prim_IntInf_toString(sml_intinf_t *);
int prim_IntInf_toInt(sml_intinf_t *);
unsigned int prim_IntInf_toWord(sml_intinf_t *);
double prim_IntInf_toReal(sml_intinf_t *);
sml_intinf_t *prim_IntInf_fromInt(int);
sml_intinf_t *prim_IntInf_fromWord(unsigned int);
sml_intinf_t *prim_IntInf_fromReal(double);
sml_intinf_t *prim_IntInf_quot(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t *prim_IntInf_rem(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t *prim_IntInf_pow(sml_intinf_t *, int);
int prim_IntInf_log2(sml_intinf_t *);
sml_intinf_t *prim_IntInf_orb(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t *prim_IntInf_xorb(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t *prim_IntInf_andb(sml_intinf_t *, sml_intinf_t *);
sml_intinf_t *prim_IntInf_notb(sml_intinf_t *);
STRING prim_Word_toString(unsigned int);
int prim_Real_class(double);
int prim_Float_class(float);
void *prim_ya_String_allocateImmutableNoInit(unsigned int);
void *prim_ya_String_allocateMutableNoInit(unsigned int);
STRING prim_String_substring(const char *, int, int);
void prim_print(const char *);

void prim_GenericOS_exit(int);
int prim_GenericOS_open(const char *, const char *);
int prim_GenericOS_read(int, char *, unsigned int, unsigned int);
int prim_GenericOS_write(int, const char *, unsigned int, unsigned int);
int prim_GenericOS_fstat(int, unsigned int[]);
int prim_GenericOS_stat(const char *, unsigned int[]);
int prim_GenericOS_lseek(int, int, int);
int prim_GenericOS_utime(const char *, unsigned int, unsigned int);
STRING prim_GenericOS_readlink(const char *);
int prim_GenericOS_chdir(const char *);
int prim_GenericOS_mkdir(const char *, int);
STRING prim_GenericOS_getcwd(void);
void *prim_GenericOS_opendir(const char *);
STRING prim_GenericOS_readdir(void *);
void prim_GenericOS_rewinddir(void *);
int prim_GenericOS_closedir(void *);
int prim_GEnericOS_poll(int[], unsigned int[], int, int);
STRING prim_GenericOS_errorName(int);
int prim_GenericOS_syserror(const char *);
int prim_Time_gettimeofday(int[]);
int prim_Timer_getTimes(int[]);
int prim_Date_localOffset(int[]);
unsigned int prim_Date_strfTime(char *, unsigned int, const char *,
				int, int, int, int, int, int, int, int, int);
char *prim_Date_ascTime(int, int, int, int, int, int, int, int, int);
int prim_Date_mkTime(int, int, int, int, int, int, int, int, int);
int prim_Date_localTime(int, int[]);
int prim_Date_gmTime(int, int[]);
double Pack_packReal64Little(unsigned char, unsigned char, unsigned char,
			     unsigned char, unsigned char, unsigned char,
			     unsigned char, unsigned char);
double prim_Pack_packReal64Big(unsigned char, unsigned char, unsigned char,
			       unsigned char, unsigned char, unsigned char,
			       unsigned char, unsigned char);
void prim_Pack_unpackReal64Little(double, unsigned char *);
void prim_Pack_packReal32Little(unsigned char, unsigned char,
				unsigned char, unsigned char, float *);
void prim_Pack_packReal32Big(unsigned char, unsigned char,
			     unsigned char, unsigned char, float *);
void prim_Pack_unpackReal32Little(float, unsigned char *);
STRING prim_UnmanagedMemory_import(void *, unsigned int);
void *prim_UnmanagedMemory_export(const char *, unsigned int, unsigned int);
int prim_UnmanagedString_size(void *);
void prim_UnmanagedMemory_updateByte(void *, unsigned char);
void prim_UnmanagedMemory_updateWord(void *, unsigned int);
void prim_UnmanagedMemory_updateInt(void *, int);
void prim_UnmanagedMemory_updateReal(void *, double);
void prim_UnmanagedMemory_updatePtr(void *, void *);
int prim_StandardC_errno(void);
int prim_CommandLine_argc(void);
char **prim_CommandLine_argv(int);
void *prim_xmalloc(int size);
STRING prim_executable_path(void);
STRING prim_tmpName(void);
int prim_cconst_int(const char *);
STRING sml_str_new(const char *);

/* netlib dtoa */
double sml_strtod(const char *, char **);
char *sml_dtoa(double, int, int, int *, int *, char **);
void sml_freedtoa(char *);

/* standard C library functions for basis library implementation */
/* we redeclare them here in order to check whether each type we assume
 * actually matches to C library function type. */

/* ANSI */
/* math.h */
double ldexp(double, int);
double sqrt(double);
double sin(double);
double cos(double);
double tan(double);
double asin(double);
double acos(double);
double atan(double);
double atan2(double, double);
double exp(double);
double pow(double, double);
double log(double);
double log10(double);
double sinh(double);
double cosh(double);
double tanh(double);
double floor(double x);
double ceil(double x);
double round(double x);
double modf(double, double *);
double frexp(double, int *);

/* string.h */
char *strerror(int);

/* stdlib.h */
char *getenv(const char *);
void free(void *);
int system(const char *);

/* stdio.h */
int remove(const char *);
int rename(const char *, const char *);

/* C99 */
/* math.h */
double copysign(double, double);
float copysignf(float, float);
float ceilf(float);
float floorf(float);
float roundf(float);
float ldexpf(float, int);
float frexpf(float, int *);
float modff(float, float *);
double nextafter(double, double);
float nextafterf(float, float);

/* POSIX */
/* unistd.h */
unsigned int sleep(unsigned int); /* effect */
int close(int); /* effect */
int rmdir(const char *); /* effect */

/* dlfcn.h */
void *dlopen(const char *, int); /* effect */
char *dlerror(void); /* effect */
int dlclose(void *); /* effect */
void *dlsym(void *, const char *); /* effect */

#endif /* SMLSHARP__PRIM_H__ */
