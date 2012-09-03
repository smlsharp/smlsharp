(**
 * lower-level interface of JNI functions.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JNI.sig,v 1.6 2007/11/29 02:32:21 kiyoshiy Exp $
 *)
signature JNI =
sig

  type JNIEnvPtr
  type JavaVMPtr
  type JNIEnv = 
       {
         FindClass : string -> JNITypes.jclass,
         ExceptionOccurred : unit -> JNITypes.jthrowable,
         ExceptionDescribe : unit -> unit,
         ExceptionClear : unit -> unit,
         DeleteLocalRef : JNITypes.jobject -> unit,
         IsSameObject
         : JNITypes.jobject * JNITypes.jobject -> JNITypes.jboolean,
         NewLocalRef : JNITypes.jobject -> JNITypes.jobject,
         NewObjectA
         : JNITypes.jclass * int * JNITypes.jvalueArray -> JNITypes.jobject,
         IsInstanceOf
         : JNITypes.jobject * JNITypes.jclass -> JNITypes.jboolean,
         GetMethodID : JNITypes.jclass * string * string -> JNITypes.jmethodID,
         CallObjectMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jobject,
         CallBooleanMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jboolean,
         CallByteMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jbyte,
         CallCharMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jchar,
         CallShortMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jshort,
         CallIntMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jint,
         CallLongMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jlong,
         CallFloatMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jfloat,
         CallDoubleMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jdouble,
         CallVoidMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray -> void,
         GetFieldID : JNITypes.jclass * string * string -> JNITypes.jfieldID,
         GetObjectField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jobject,
         GetBooleanField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jboolean,
         GetByteField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jbyte,
         GetCharField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jchar,
         GetShortField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jshort,
         GetIntField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jint,
         GetLongField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jlong,
         GetFloatField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jfloat,
         GetDoubleField
         : JNITypes.jobject * JNITypes.jfieldID -> JNITypes.jdouble,
         SetObjectField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jobject -> void,
         SetBooleanField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jboolean -> void,
         SetByteField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jbyte -> void,
         SetCharField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jchar -> void,
         SetShortField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jshort -> void,
         SetIntField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jint -> void,
         SetLongField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jlong -> void,
         SetFloatField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jfloat -> void,
         SetDoubleField
         : JNITypes.jobject * JNITypes.jfieldID * JNITypes.jdouble -> void,
         GetStaticMethodID
         : JNITypes.jclass * string * string -> JNITypes.jmethodID,
         CallStaticObjectMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jobject,
         CallStaticBooleanMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jboolean,
         CallStaticByteMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jbyte,
         CallStaticCharMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jchar,
         CallStaticShortMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jshort,
         CallStaticIntMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jint,
         CallStaticLongMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jlong,
         CallStaticFloatMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jfloat,
         CallStaticDoubleMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray
           -> JNITypes.jdouble,
         CallStaticVoidMethodA
         : JNITypes.jclass * JNITypes.jmethodID * JNITypes.jvalueArray -> void,

         GetStaticFieldID
         : JNITypes.jclass * string * string -> JNITypes.jfieldID,
         GetStaticObjectField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jobject,
         GetStaticBooleanField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jboolean,
         GetStaticByteField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jbyte,
         GetStaticCharField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jchar,
         GetStaticShortField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jshort,
         GetStaticIntField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jint,
         GetStaticLongField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jlong,
         GetStaticFloatField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jfloat,
         GetStaticDoubleField
         : JNITypes.jclass * JNITypes.jfieldID -> JNITypes.jdouble,
         SetStaticObjectField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jobject -> void,
         SetStaticBooleanField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jboolean -> void,
         SetStaticByteField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jbyte -> void,
         SetStaticCharField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jchar -> void,
         SetStaticShortField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jshort -> void,
         SetStaticIntField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jint -> void,
         SetStaticLongField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jlong -> void,
         SetStaticFloatField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jfloat -> void,
         SetStaticDoubleField
         : JNITypes.jclass * JNITypes.jfieldID * JNITypes.jdouble -> void,

         NewStringUTF : string -> JNITypes.jstring,
         GetStringUTFChars
         : JNITypes.jstring * JNITypes.jboolean ref
           -> UnmanagedString.unmanagedString,
         ReleaseStringUTFChars
         : JNITypes.jstring * UnmanagedString.unmanagedString -> unit,

         GetArrayLength : (JNITypes.jarray) -> JNITypes.jsize,
         NewObjectArray
         : (JNITypes.jsize * JNITypes.jclass * JNITypes.jobject)
           -> JNITypes.jobjectArray,
         GetObjectArrayElement
         : (JNITypes.jobjectArray * JNITypes.jsize) -> JNITypes.jobject,
         SetObjectArrayElement
         : (JNITypes.jobjectArray * JNITypes.jsize * JNITypes.jobject) -> void,
         NewBooleanArray : (JNITypes.jsize) -> JNITypes.jbooleanArray,
         NewByteArray : (JNITypes.jsize) -> JNITypes.jbyteArray,
         NewCharArray : (JNITypes.jsize) -> JNITypes.jcharArray,
         NewShortArray : (JNITypes.jsize) -> JNITypes.jshortArray,
         NewIntArray : (JNITypes.jsize) -> JNITypes.jintArray,
         NewLongArray : (JNITypes.jsize) -> JNITypes.jlongArray,
         NewFloatArray : (JNITypes.jsize) -> JNITypes.jfloatArray,
         NewDoubleArray : (JNITypes.jsize) -> JNITypes.jdoubleArray,
         GetBooleanArrayElements
         : (JNITypes.jbooleanArray * JNITypes.jboolean ref)
           -> JNITypes.jbooleans,
         GetByteArrayElements
         : (JNITypes.jbyteArray * JNITypes.jboolean ref) -> JNITypes.jbytes,
         GetCharArrayElements
         : (JNITypes.jcharArray * JNITypes.jboolean ref) -> JNITypes.jchars,
         GetShortArrayElements
         : (JNITypes.jshortArray * JNITypes.jboolean ref) -> JNITypes.jshorts,
         GetIntArrayElements
         : (JNITypes.jintArray * JNITypes.jboolean ref) -> JNITypes.jints,
         GetLongArrayElements
         : (JNITypes.jlongArray * JNITypes.jboolean ref) -> JNITypes.jlongs,
         GetFloatArrayElements
         : (JNITypes.jfloatArray * JNITypes.jboolean ref) -> JNITypes.jfloats,
         GetDoubleArrayElements
         : (JNITypes.jdoubleArray * JNITypes.jboolean ref) -> JNITypes.jdoubles,
         ReleaseBooleanArrayElements
         : (JNITypes.jbooleanArray * JNITypes.jbooleans * JNITypes.jint)
           -> void,
         ReleaseByteArrayElements
         : (JNITypes.jbyteArray * JNITypes.jbytes * JNITypes.jint) -> void,
         ReleaseCharArrayElements
         : (JNITypes.jcharArray * JNITypes.jchars * JNITypes.jint) -> void,
         ReleaseShortArrayElements
         : (JNITypes.jshortArray * JNITypes.jshorts * JNITypes.jint) -> void,
         ReleaseIntArrayElements
         : (JNITypes.jintArray * JNITypes.jints * JNITypes.jint) -> void,
         ReleaseLongArrayElements
         : (JNITypes.jlongArray * JNITypes.jlongs * JNITypes.jint) -> void,
         ReleaseFloatArrayElements
         : (JNITypes.jfloatArray * JNITypes.jfloats * JNITypes.jint) -> void,
         ReleaseDoubleArrayElements
         : (JNITypes.jdoubleArray * JNITypes.jdoubles * JNITypes.jint) -> void,

         GetJavaVM : JavaVMPtr ref -> JNITypes.jint,
         this : JNIEnvPtr
       }

  type JavaVM = 
       {
         DestroyJavaVM : unit -> JNITypes.jint,
         this : JavaVMPtr
       }

  exception JNIExn of JNITypes.jthrowable

  val initialize : string list -> unit
  val getJNIEnv : unit -> JNIEnv
  val getJavaVM : unit -> JavaVM

end;