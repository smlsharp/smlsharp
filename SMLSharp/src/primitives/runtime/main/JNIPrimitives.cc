#include "Primitives.hh"
#include "PrimitiveSupport.hh"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

#ifdef ENABLE_JNI

extern "C" {
#ifdef __CYGWIN__
  // VC recognizes __int64.
  // But gcc does not recognize __int64.
#define  __int64 long long
#endif
#include <jni.h>
}

#ifdef __CYGWIN__
#define PATH_SEPARATOR ';'
#else /* UNIX */
#define PATH_SEPARATOR ':'
#endif

static JNIEnv* g_JNIEnv = NULL;
static JavaVM* g_JVM = NULL;

static const char* FQN_JAVASTRING = "java/lang/String";
static const char* EXN_JNIERROR = "JError";

struct JNIExnWrapper
{
  JNIExnWrapper(jthrowable exn):exn(exn){};
  jthrowable exn;
};

static bool init()
{
    if(g_JVM == NULL)
    {
        JavaVMInitArgs vm_args;
        jint res;
        vm_args.version = JNI_VERSION_1_2;
        vm_args.nOptions = 0;
        res = JNI_CreateJavaVM(&g_JVM, (void**)&g_JNIEnv, &vm_args);
        DBGWRAP(
                fprintf(stderr, "createJVM = %d\n", res);
                fflush(stderr);
                );
        if (res < 0)
        {
        DBGWRAP(
                fprintf(stderr, "JNI_CreateJavaVM error: %d\n", res);
                fflush(stderr);
                );
            return false;
        }
    }
    return true;
}

static void checkJavaException()
{
    jthrowable exn = g_JNIEnv->ExceptionOccurred();
    if(NULL == exn)
    {
        return;
    }
    else
    {
        fprintf(stderr,"java error occurred.\n");
        fflush(stderr);
        g_JNIEnv->ExceptionClear();
        fprintf(stderr,"java error thrown.\n");
        fflush(stderr);
        throw JNIExnWrapper(exn);
    }
}

static jvalue intToJValue(int value)
{
    jvalue jval;
    jval.i = value;
    return jval;
}

static jvalue stringToJValue(const char* value)
{
    jvalue jval;
    jstring jstr = g_JNIEnv->NewStringUTF(value);
    DBGWRAP(
            fprintf(stderr, "stringToJValue = %x\n", jstr);
            fflush(stderr);
            );
    checkJavaException();
    jval.l = jstr;
    return jval;
}

static const char* SYSTEM_CLASSNAME = "java/lang/System";
static const char* TARGET_METHODNAME = "getProperty";
static const char* TARGET_SIGNATURE = "(Ljava/lang/String;)Ljava/lang/String;";

static Cell getProperty(Cell keyCell)
{
    // get class
    jclass clazz = g_JNIEnv->FindClass(SYSTEM_CLASSNAME);
    DBGWRAP(
            fprintf(stderr, "clazz = %x\n", clazz);
            fflush(stderr);
            );
    checkJavaException();
    assert(clazz != NULL);

    // get method
    jmethodID methodID =
    g_JNIEnv->GetStaticMethodID(clazz, TARGET_METHODNAME, TARGET_SIGNATURE);
    DBGWRAP(
            fprintf(stderr, "methodID = %x\n", methodID);
            fflush(stderr);
            );
    checkJavaException();
    assert(methodID != NULL);

    // set up arguments
    char* keyString = PrimitiveSupport::cellToString(keyCell);
    DBGWRAP(
            fprintf(stderr,"keyString = '%s'\n", keyString);
            fflush(stderr);
            );
    jvalue keyJValue = stringToJValue(keyString);
    jvalue jargs[1];
    jargs[0] = keyJValue;

    // call method
    jobject resultJObject =
    g_JNIEnv->CallStaticObjectMethodA(clazz, methodID, jargs);
    jstring resultJString = (jstring)resultJObject;
    DBGWRAP(
            fprintf(stderr, "result = %x\n", resultJString);
            fflush(stderr);
            );
    checkJavaException();
//    assert(resultJString != NULL);

    // extract result string
    jboolean iscopy = JNI_FALSE;
    const char *resultString =
    resultJString
    ? g_JNIEnv->GetStringUTFChars(resultJString, &iscopy)
    : "";
    checkJavaException();
    DBGWRAP(
            fprintf(stderr,"result = '%s'\n", resultString);
            fflush(stderr);
            );
    Cell resultCell = PrimitiveSupport::stringToCell(resultString);

    // clean up
    if(resultJString){
        g_JNIEnv->ReleaseStringUTFChars(resultJString, resultString);
    }
    g_JNIEnv->DeleteLocalRef(keyJValue.l); 
    g_JNIEnv->DeleteLocalRef(resultJString); 

    return resultCell;
}

void
IMLPrim_getJavaPropertyImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    if(init()){
        *resultRef = getProperty((*argumentRefs)[0]);
        return;
    }
    throw IMLRuntimeException();
}

#else

void
IMLPrim_getJavaPropertyImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    char* message = "<not implemented>";
    *resultRef = PrimitiveSupport::stringToCell(message);
    return;
}

#endif

Primitive IMLPrim_getJavaProperty = IMLPrim_getJavaPropertyImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
