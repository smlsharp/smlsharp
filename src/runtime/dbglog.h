#pragma once

#define DBG__MAXARGS 8
#define DBG__NARGS_(x1,x2,x3,x4,x5,x6,x7,x8,X,...) X
#define DBG__NARGS(...) DBG__NARGS_(__VA_ARGS__,8,7,6,5,4,3,2,1)
#define DBG__STR(c) #c
#define DBG__CHR_(c) DBG__STR(\00##c)
#define DBG__CHR(c) DBG__CHR_(c)
#define DBG__APP1(f,x)     f(x)
#define DBG__APP2(f,x,...) f(x) DBG__APP1(f##_,__VA_ARGS__)
#define DBG__APP3(f,x,...) f(x) DBG__APP2(f##_,__VA_ARGS__)
#define DBG__APP4(f,x,...) f(x) DBG__APP3(f##_,__VA_ARGS__)
#define DBG__APP5(f,x,...) f(x) DBG__APP4(f##_,__VA_ARGS__)
#define DBG__APP6(f,x,...) f(x) DBG__APP5(f##_,__VA_ARGS__)
#define DBG__APP7(f,x,...) f(x) DBG__APP6(f##_,__VA_ARGS__)
#define DBG__APP8(f,x,...) f(x) DBG__APP7(f##_,__VA_ARGS__)
#define DBG__APP__(x) DBG__APP##x
#define DBG__APP_(x) DBG__APP__(x)
#define DBG__APP(f,...) DBG__APP_(DBG__NARGS(__VA_ARGS__))(f,__VA_ARGS__)
#define DBG__UNUSED __attribute__((unused))
#define DBG__ARG(x) uintptr_t *DBG__p DBG__UNUSED = DBG__alloc(x"\n");
#define DBG__ARG_(x) DBG__p[0] = (uintptr_t)(x);
#define DBG__ARG__(x) DBG__p[1] = (uintptr_t)(x);
#define DBG__ARG___(x) DBG__p[2] = (uintptr_t)(x);
#define DBG__ARG____(x) DBG__p[3] = (uintptr_t)(x);
#define DBG__ARG_____(x) DBG__p[4] = (uintptr_t)(x);
#define DBG__ARG______(x) DBG__p[5] = (uintptr_t)(x);
#define DBG__ARG_______(x) DBG__p[6] = (uintptr_t)(x);
#define DBG__FILELINE_(x) DBG__STR(x)
#define DBG__FILELINE() __FILE__":"DBG__FILELINE_(__LINE__)": "

/* the argument must consist of 1 format followed by at most 7 arguments */
#define DBG(...) \
  do{ DBG__APP(DBG__ARG, DBG__CHR(DBG__NARGS(__VA_ARGS__))__VA_ARGS__) }while(0)
#define DBGFL(...) DBG(DBG__FILELINE()__VA_ARGS__)

uintptr_t *DBG__alloc(const char *fmt);
void DBGdump(const char *filename);
