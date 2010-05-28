(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JNI.sml,v 1.13 2010/04/24 07:50:21 kiyoshiy Exp $
 *)
structure JNI :> JNI =
struct

  structure DL = DynamicLink;
  structure T = JNITypes
  structure UM = UnmanagedMemory;
  structure US = UnmanagedString;

  type JNIEnvPtr = unit ptr
  type JavaVMPtr = unit ptr

  (** JavaVMInitArgs is declared in jni.h as follows.
   * <pre>
   * typedef struct JavaVMInitArgs {
   *     jint version;
   *     jint nOptions;
   *    JavaVMOption *options;
   *     jboolean ignoreUnrecognized;
   * } JavaVMInitArgs;
   * </pre>
   *)
  type JavaVMInitArgs = (T.jint * T.jint * unit ptr * T.jboolean)

  type JNIEnv = 
       {
         FindClass : string -> T.jclass,
         ExceptionOccurred : unit -> T.jthrowable,
         ExceptionDescribe : unit -> unit,
         ExceptionClear : unit -> unit,
         DeleteLocalRef : T.jobject -> unit,
         IsSameObject : T.jobject * T.jobject -> T.jboolean,
         NewLocalRef : T.jobject -> T.jobject,
         NewObjectA : T.jclass * int * T.jvalueArray -> T.jobject,
         IsInstanceOf : T.jobject * T.jclass -> T.jboolean,
         GetMethodID : T.jclass * string * string -> T.jmethodID,
         CallObjectMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jobject,
         CallBooleanMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jboolean,
         CallByteMethodA : T.jclass * T.jmethodID * T.jvalueArray -> T.jbyte,
         CallCharMethodA : T.jclass * T.jmethodID * T.jvalueArray -> T.jchar,
         CallShortMethodA : T.jclass * T.jmethodID * T.jvalueArray -> T.jshort,
         CallIntMethodA : T.jclass * T.jmethodID * T.jvalueArray -> T.jint,
         CallLongMethodA : T.jclass * T.jmethodID * T.jvalueArray -> T.jlong,
(* FIXME: enable this when SML# FFI supports float.
         CallFloatMethodA : T.jclass * T.jmethodID * T.jvalueArray -> T.jfloat,
*)
         CallDoubleMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jdouble,
         CallVoidMethodA : T.jclass * T.jmethodID * T.jvalueArray -> void,
         GetFieldID : T.jclass * string * string -> T.jfieldID,
         GetObjectField : T.jobject * T.jfieldID -> T.jobject,
         GetBooleanField : T.jobject * T.jfieldID -> T.jboolean,
         GetByteField : T.jobject * T.jfieldID -> T.jbyte,
         GetCharField : T.jobject * T.jfieldID -> T.jchar,
         GetShortField : T.jobject * T.jfieldID -> T.jshort,
         GetIntField : T.jobject * T.jfieldID -> T.jint,
         GetLongField : T.jobject * T.jfieldID -> T.jlong,
(* FIXME: enable this when SML# FFI supports float.
         GetFloatField : T.jobject * T.jfieldID -> T.jfloat,
*)
         GetDoubleField : T.jobject * T.jfieldID -> T.jdouble,
         SetObjectField : T.jobject * T.jfieldID * T.jobject -> void,
         SetBooleanField : T.jobject * T.jfieldID * T.jboolean -> void,
         SetByteField : T.jobject * T.jfieldID * T.jbyte -> void,
         SetCharField : T.jobject * T.jfieldID * T.jchar -> void,
         SetShortField : T.jobject * T.jfieldID * T.jshort -> void,
         SetIntField : T.jobject * T.jfieldID * T.jint -> void,
         SetLongField : T.jobject * T.jfieldID * T.jlong -> void,
         SetFloatField : T.jobject * T.jfieldID * T.jfloat -> void,
         SetDoubleField : T.jobject * T.jfieldID * T.jdouble -> void,
         GetStaticMethodID : T.jclass * string * string -> T.jmethodID,
         CallStaticObjectMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jobject,
         CallStaticBooleanMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jboolean,
         CallStaticByteMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jbyte,
         CallStaticCharMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jchar,
         CallStaticShortMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jshort,
         CallStaticIntMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jint,
         CallStaticLongMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jlong,
(*
         CallStaticFloatMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jfloat,
*)
         CallStaticDoubleMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> T.jdouble,
         CallStaticVoidMethodA
         : T.jclass * T.jmethodID * T.jvalueArray -> void,

         GetStaticFieldID : T.jclass * string * string -> T.jfieldID,
         GetStaticObjectField : T.jobject * T.jfieldID -> T.jobject,
         GetStaticBooleanField : T.jobject * T.jfieldID -> T.jboolean,
         GetStaticByteField : T.jobject * T.jfieldID -> T.jbyte,
         GetStaticCharField : T.jobject * T.jfieldID -> T.jchar,
         GetStaticShortField : T.jobject * T.jfieldID -> T.jshort,
         GetStaticIntField : T.jobject * T.jfieldID -> T.jint,
         GetStaticLongField : T.jobject * T.jfieldID -> T.jlong,
(* FIXME: enable this when SML# FFI supports float.
         GetStaticFloatField : T.jobject * T.jfieldID -> T.jfloat,
*)
         GetStaticDoubleField : T.jobject * T.jfieldID -> T.jdouble,
         SetStaticObjectField : T.jobject * T.jfieldID * T.jobject -> void,
         SetStaticBooleanField : T.jobject * T.jfieldID * T.jboolean -> void,
         SetStaticByteField : T.jobject * T.jfieldID * T.jbyte -> void,
         SetStaticCharField : T.jobject * T.jfieldID * T.jchar -> void,
         SetStaticShortField : T.jobject * T.jfieldID * T.jshort -> void,
         SetStaticIntField : T.jobject * T.jfieldID * T.jint -> void,
         SetStaticLongField : T.jobject * T.jfieldID * T.jlong -> void,
         SetStaticFloatField : T.jobject * T.jfieldID * T.jfloat -> void,
         SetStaticDoubleField : T.jobject * T.jfieldID * T.jdouble -> void,

         NewStringUTF : string -> T.jstring,
         GetStringUTFChars : T.jstring * T.jboolean ref -> US.unmanagedString,
         ReleaseStringUTFChars : T.jstring * US.unmanagedString -> unit,

         GetArrayLength : (T.jarray) -> T.jsize,
         NewObjectArray : (T.jsize * T.jclass * T.jobject) -> T.jobjectArray,
         GetObjectArrayElement
         : (T.jobjectArray * T.jsize) -> T.jobject,
         SetObjectArrayElement
         : (T.jobjectArray * T.jsize * T.jobject) -> void,
         NewBooleanArray : (T.jsize) -> T.jbooleanArray,
         NewByteArray : (T.jsize) -> T.jbyteArray,
         NewCharArray : (T.jsize) -> T.jcharArray,
         NewShortArray : (T.jsize) -> T.jshortArray,
         NewIntArray : (T.jsize) -> T.jintArray,
         NewLongArray : (T.jsize) -> T.jlongArray,
         NewFloatArray : (T.jsize) -> T.jfloatArray,
         NewDoubleArray : (T.jsize) -> T.jdoubleArray,
         GetBooleanArrayElements
         : (T.jbooleanArray * T.jboolean ref) -> T.jbooleans,
         GetByteArrayElements
         : (T.jbyteArray * T.jboolean ref) -> T.jbytes,
         GetCharArrayElements
         : (T.jcharArray * T.jboolean ref) -> T.jchars,
         GetShortArrayElements
         : (T.jshortArray * T.jboolean ref) -> T.jshorts,
         GetIntArrayElements
         : (T.jintArray * T.jboolean ref) -> T.jints,
         GetLongArrayElements
         : (T.jlongArray * T.jboolean ref) -> T.jlongs,
         GetFloatArrayElements
         : (T.jfloatArray * T.jboolean ref) -> T.jfloats,
         GetDoubleArrayElements
         : (T.jdoubleArray * T.jboolean ref) -> T.jdoubles,
         ReleaseBooleanArrayElements
         : (T.jbooleanArray * T.jbooleans * T.jint) -> void,
         ReleaseByteArrayElements
         : (T.jbyteArray * T.jbytes * T.jint) -> void,
         ReleaseCharArrayElements
         : (T.jcharArray * T.jchars * T.jint) -> void,
         ReleaseShortArrayElements
         : (T.jshortArray * T.jshorts * T.jint) -> void,
         ReleaseIntArrayElements
         : (T.jintArray * T.jints * T.jint) -> void,
         ReleaseLongArrayElements
         : (T.jlongArray * T.jlongs * T.jint) -> void,
         ReleaseFloatArrayElements
         : (T.jfloatArray * T.jfloats * T.jint) -> void,
         ReleaseDoubleArrayElements
         : (T.jdoubleArray * T.jdoubles * T.jint) -> void,

         GetJavaVM : JavaVMPtr ref -> T.jint,
         this : JNIEnvPtr
       }
  type JavaVM = 
       {
         DestroyJavaVM : unit -> T.jint,
         this : JavaVMPtr
       }

  exception JNIExn of T.jthrowable

  val JNI_VERSION_1_1 = 0x00010001
  val JNI_VERSION_1_2 = 0x00010002
  val JNI_VERSION_1_4 = 0x00010004

  fun getJavaHomeDir _ = 
      case OS.Process.getEnv "JAVA_HOME"
       of SOME dir => dir
        | NONE => raise Fail "JAVA_HOME must be specified."

  val JVMDLL = ref UM.NULL

  fun getJVMDLL () =
      if !JVMDLL = UM.NULL
      then
        let
          val JVMDLLPath =
              case OS.Process.getEnv "JVM_DLL"
               of SOME path => path
                | _ =>
                  case SMLSharp.Platform.OS.host
                   of SMLSharp.Platform.OS.Cygwin 
                      => OS.Path.concat
                             (getJavaHomeDir (), "jre/bin/client/jvm.dll")
                    | SMLSharp.Platform.OS.MinGW
                      => OS.Path.concat
                             (getJavaHomeDir (), "jre/bin/client/jvm.dll")
                    | SMLSharp.Platform.OS.Darwin => 
                      "/System/Library/Frameworks/JavaVM.framework/Libraries/libjvm_compat.dylib"
                    | _ => "libjvm.so" (* ToDo : error ? *)
          val _ = print JVMDLLPath
          val dll = DL.dlopen JVMDLLPath
          val _ =
              if dll = UM.NULL
              then raise Fail ("cannot load " ^ JVMDLLPath)
              else ()
          val _ = JVMDLL := dll
        in
          !JVMDLL
        end
      else !JVMDLL

  fun wrapJavaVM JavaVM = 
      let
        val JavaVMVTBL = UM.wordToAddress(UM.subWord (UM.advance(JavaVM, 0)))
        fun member index =
            UM.wordToAddress(UM.subWord (UM.advance(JavaVMVTBL, index * 4)))
        val DestroyJavaVM =
            (member 3) : _import _stdcall (JavaVMPtr) -> T.jint
      in
        {
          DestroyJavaVM = fn () => DestroyJavaVM JavaVM,
          this = JavaVM
        } : JavaVM
      end

  fun wrapJNIEnv JNIEnv =
      let
        val JNIEnvVTBL = UM.wordToAddress(UM.subWord (UM.advance(JNIEnv, 0)))
        fun member index =
            UM.wordToAddress(UM.subWord (UM.advance(JNIEnvVTBL, index * 4)))

        val FindClass = (member 6) : _import _stdcall (JNIEnvPtr, string) -> T.jclass
        val ExceptionOccurred = (member 15) : _import _stdcall (JNIEnvPtr) -> T.jthrowable
        val ExceptionDescribe = (member 16) : _import _stdcall (JNIEnvPtr) -> void
        val ExceptionClear = (member 17) : _import _stdcall (JNIEnvPtr) -> void
        val DeleteLocalRef = (member 23) : _import _stdcall (JNIEnvPtr, T.jobject) -> void
        val IsSameObject = (member 24) : _import _stdcall (JNIEnvPtr, T.jobject, T.jobject) -> T.jboolean
        val NewLocalRef = (member 25) : _import _stdcall (JNIEnvPtr, T.jobject) -> T.jobject
        val NewObjectA = (member 30) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jobject
        val IsInstanceOf = (member 32) : _import _stdcall (JNIEnvPtr, T.jobject, T.jclass) -> T.jboolean
        val GetMethodID = (member 33) : _import _stdcall (JNIEnvPtr, T.jclass, string, string) -> T.jmethodID
        val CallObjectMethodA = (member 36) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jobject
        val CallBooleanMethodA = (member 39) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jboolean
        val CallByteMethodA = (member 42) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jbyte
        val CallCharMethodA = (member 45) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jchar
        val CallShortMethodA = (member 48) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jshort
        val CallIntMethodA = (member 51) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jint
        val CallLongMethodA = (member 54) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jlong
(* FIXME: enable this when SML# FFI supports float.
        val CallFloatMethodA = (member 57) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jfloat
*)
        val CallDoubleMethodA = (member 60) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> T.jdouble
        val CallVoidMethodA = (member 63) : _import _stdcall (JNIEnvPtr, T.jobject, T.jmethodID, T.jvalueArray) -> void
        val GetFieldID = (member 94) : _import _stdcall (JNIEnvPtr, T.jclass, string, string) -> T.jfieldID
        val GetObjectField = (member 95) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jobject
        val GetBooleanField = (member 96) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jboolean
        val GetByteField = (member 97) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jbyte
        val GetCharField = (member 98) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jchar
        val GetShortField = (member 99) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jshort
        val GetIntField = (member 100) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jint
        val GetLongField = (member 101) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jlong
(* FIXME: enable this when SML# FFI supports float.
        val GetFloatField = (member 102) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jfloat
*)
        val GetDoubleField = (member 103) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID) -> T.jdouble
        val SetObjectField = (member 104) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jobject) -> void
        val SetBooleanField = (member 105) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jboolean) -> void
        val SetByteField = (member 106) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jbyte) -> void
        val SetCharField = (member 107) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jchar) -> void
        val SetShortField = (member 108) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jshort) -> void
        val SetIntField = (member 109) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jint) -> void
        val SetLongField = (member 110) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jlong) -> void
        val SetFloatField = (member 111) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jfloat) -> void
        val SetDoubleField = (member 112) : _import _stdcall (JNIEnvPtr, T.jobject, T.jfieldID, T.jdouble) -> void

        val GetStaticMethodID = (member 113) : _import _stdcall (JNIEnvPtr, T.jclass, string, string) -> T.jmethodID
        val CallStaticObjectMethodA = (member 116) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jobject
        val CallStaticBooleanMethodA = (member 119) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jboolean
        val CallStaticByteMethodA = (member 122) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jbyte
        val CallStaticCharMethodA = (member 125) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jchar
        val CallStaticShortMethodA = (member 128) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jshort
        val CallStaticIntMethodA = (member 131) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jint
        val CallStaticLongMethodA = (member 134) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jlong
(* FIXME: enable this when SML# FFI supports float.
        val CallStaticFloatMethodA = (member 137) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jfloat
*)
        val CallStaticDoubleMethodA = (member 140) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> T.jdouble 
        val CallStaticVoidMethodA = (member 143) : _import _stdcall (JNIEnvPtr, T.jclass, T.jmethodID, T.jvalueArray) -> void 

        val GetStaticFieldID = (member 144) : _import _stdcall (JNIEnvPtr, T.jclass, string, string) -> T.jfieldID
        val GetStaticObjectField = (member 145) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jobject
        val GetStaticBooleanField = (member 146) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jboolean
        val GetStaticByteField = (member 147) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jbyte
        val GetStaticCharField = (member 148) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jchar
        val GetStaticShortField = (member 149) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jshort
        val GetStaticIntField = (member 150) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jint
        val GetStaticLongField = (member 151) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jlong
(*
        val GetStaticFloatField = (member 152) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jfloat
*)
        val GetStaticDoubleField = (member 153) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID) -> T.jdouble
        val SetStaticObjectField = (member 154) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jobject) -> void
        val SetStaticBooleanField = (member 155) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jboolean) -> void
        val SetStaticByteField = (member 156) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jbyte) -> void
        val SetStaticCharField = (member 157) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jchar) -> void
        val SetStaticShortField = (member 158) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jshort) -> void
        val SetStaticIntField = (member 159) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jint) -> void
        val SetStaticLongField = (member 160) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jlong) -> void
        val SetStaticFloatField = (member 161) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jfloat) -> void
        val SetStaticDoubleField = (member 162) : _import _stdcall (JNIEnvPtr, T.jclass, T.jfieldID, T.jdouble) -> void

        val NewStringUTF = (member 167) : _import _stdcall (JNIEnvPtr, string) -> T.jstring
        val GetStringUTFChars = (member 169) : _import _stdcall (JNIEnvPtr, T.jstring, T.jboolean ref) -> US.unmanagedString
        val ReleaseStringUTFChars = (member 170) : _import _stdcall (JNIEnvPtr, T.jstring, US.unmanagedString) -> void

        val GetArrayLength = (member 171) : _import _stdcall (JNIEnvPtr, T.jarray) -> T.jsize
        val NewObjectArray = (member 172) : _import _stdcall (JNIEnvPtr, T.jsize, T.jclass, T.jobject) -> T.jobjectArray
        val GetObjectArrayElement = (member 173) : _import _stdcall (JNIEnvPtr, T.jobjectArray, T.jsize) -> T.jobject
        val SetObjectArrayElement = (member 174) : _import _stdcall (JNIEnvPtr, T.jobjectArray, T.jsize, T.jobject) -> void
        val NewBooleanArray = (member 175) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jbooleanArray
        val NewByteArray = (member 176) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jbyteArray
        val NewCharArray = (member 177) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jcharArray
        val NewShortArray = (member 178) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jshortArray
        val NewIntArray = (member 179) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jintArray
        val NewLongArray = (member 180) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jlongArray
        val NewFloatArray = (member 181) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jfloatArray
        val NewDoubleArray = (member 182) : _import _stdcall (JNIEnvPtr, T.jsize) -> T.jdoubleArray
        val GetBooleanArrayElements = (member 183) : _import _stdcall (JNIEnvPtr, T.jbooleanArray, T.jboolean ref) -> T.jbooleans
        val GetByteArrayElements = (member 184) : _import _stdcall (JNIEnvPtr, T.jbyteArray, T.jboolean ref) -> T.jbytes
        val GetCharArrayElements = (member 185) : _import _stdcall (JNIEnvPtr, T.jcharArray, T.jboolean ref) -> T.jchars
        val GetShortArrayElements = (member 186) : _import _stdcall (JNIEnvPtr, T.jshortArray, T.jboolean ref) -> T.jshorts
        val GetIntArrayElements = (member 187) : _import _stdcall (JNIEnvPtr, T.jintArray, T.jboolean ref) -> T.jints
        val GetLongArrayElements = (member 188) : _import _stdcall (JNIEnvPtr, T.jlongArray, T.jboolean ref) -> T.jlongs
        val GetFloatArrayElements = (member 189) : _import _stdcall (JNIEnvPtr, T.jfloatArray, T.jboolean ref) -> T.jfloats
        val GetDoubleArrayElements = (member 190) : _import _stdcall (JNIEnvPtr, T.jdoubleArray, T.jboolean ref) -> T.jdoubles
        val ReleaseBooleanArrayElements = (member 191) : _import _stdcall (JNIEnvPtr, T.jbooleanArray, T.jbooleans, T.jint) -> void
        val ReleaseByteArrayElements = (member 192) : _import _stdcall (JNIEnvPtr, T.jbyteArray, T.jbytes, T.jint) -> void
        val ReleaseCharArrayElements = (member 193) : _import _stdcall (JNIEnvPtr, T.jcharArray, T.jchars, T.jint) -> void
        val ReleaseShortArrayElements = (member 194) : _import _stdcall (JNIEnvPtr, T.jshortArray, T.jshorts, T.jint) -> void
        val ReleaseIntArrayElements = (member 195) : _import _stdcall (JNIEnvPtr, T.jintArray, T.jints, T.jint) -> void
        val ReleaseLongArrayElements = (member 196) : _import _stdcall (JNIEnvPtr, T.jlongArray, T.jlongs, T.jint) -> void
        val ReleaseFloatArrayElements = (member 197) : _import _stdcall (JNIEnvPtr, T.jfloatArray, T.jfloats, T.jint) -> void
        val ReleaseDoubleArrayElements = (member 198) : _import _stdcall (JNIEnvPtr, T.jdoubleArray, T.jdoubles, T.jint) -> void

        val GetJavaVM = (member 219) : _import _stdcall (JNIEnvPtr, JavaVMPtr ref) -> T.jint

        (* wrap a JNI function to raise an exception if Java exception is
         * thrown in the JNI function. *)
        fun G result =
            let val exn = ExceptionOccurred JNIEnv
            in
              if UM.isNULL exn
              then result
              else
                (
(*
                  ExceptionDescribe JNIEnv;
*)
                  ExceptionClear JNIEnv;
                  raise JNIExn exn
                )
            end
      in
        {
          FindClass = fn (string) => G(FindClass (JNIEnv, string)),
          ExceptionOccurred = fn () => G(ExceptionOccurred (JNIEnv)),
          ExceptionDescribe = fn () => G(ExceptionDescribe (JNIEnv)),
          ExceptionClear = fn () => G(ExceptionClear (JNIEnv)),
          DeleteLocalRef = fn (jobject) => G(DeleteLocalRef (JNIEnv, jobject)),
          IsSameObject =
          fn (jobject1, jobject2) =>
             G(IsSameObject (JNIEnv, jobject1, jobject2)),
          NewLocalRef = fn (jobject) => G(NewLocalRef (JNIEnv, jobject)),
          NewObjectA =
          fn (class, methodID, values) =>
             G(NewObjectA (JNIEnv, class, methodID, values)),
          IsInstanceOf =
          fn (jobject, class) => G(IsInstanceOf (JNIEnv, jobject, class)),
          GetMethodID =
          fn (class, name, sign) => G(GetMethodID (JNIEnv, class, name, sign)),
          CallObjectMethodA =
          fn (jobject, methodID, values) =>
             G(CallObjectMethodA (JNIEnv, jobject, methodID, values)),
          CallBooleanMethodA =
          fn (jobject, methodID, values) =>
             G(CallBooleanMethodA (JNIEnv, jobject, methodID, values)),
          CallByteMethodA =
          fn (jobject, methodID, values) =>
             G(CallByteMethodA (JNIEnv, jobject, methodID, values)),
          CallCharMethodA =
          fn (jobject, methodID, values) =>
             G(CallCharMethodA (JNIEnv, jobject, methodID, values)),
          CallShortMethodA =
          fn (jobject, methodID, values) =>
             G(CallShortMethodA (JNIEnv, jobject, methodID, values)),
          CallIntMethodA =
          fn (jobject, methodID, values) =>
             G(CallIntMethodA (JNIEnv, jobject, methodID, values)),
          CallLongMethodA =
          fn (jobject, methodID, values) =>
             G(CallLongMethodA (JNIEnv, jobject, methodID, values)),
(* FIXME: enable this when SML# FFI supports float.
          CallFloatMethodA =
          fn (jobject, methodID, values) =>
             G(CallFloatMethodA (JNIEnv, jobject, methodID, values)),
*)
          CallDoubleMethodA =
          fn (jobject, methodID, values) =>
             G(CallDoubleMethodA (JNIEnv, jobject, methodID, values)),
          CallVoidMethodA =
          fn (jobject, methodID, values) =>
             G(CallVoidMethodA (JNIEnv, jobject, methodID, values)),

          GetFieldID =
          fn (jclass, name, sign) =>
             G(GetFieldID (JNIEnv, jclass, name, sign)),
          GetObjectField =
          fn (jobject, fieldID) =>
             G(GetObjectField (JNIEnv, jobject, fieldID)),
          GetBooleanField =
          fn (jobject, fieldID) =>
             G(GetBooleanField (JNIEnv, jobject, fieldID)),
          GetByteField =
          fn (jobject, fieldID) =>
             G(GetByteField (JNIEnv, jobject, fieldID)),
          GetCharField =
          fn (jobject, fieldID) =>
             G(GetCharField (JNIEnv, jobject, fieldID)),
          GetShortField =
          fn (jobject, fieldID) =>
             G(GetShortField (JNIEnv, jobject, fieldID)),
          GetIntField =
          fn (jobject, fieldID) =>
             G(GetIntField (JNIEnv, jobject, fieldID)),
          GetLongField =
          fn (jobject, fieldID) =>
             G(GetLongField (JNIEnv, jobject, fieldID)),
(* FIXME: enable this when SML# FFI supports float.
          GetFloatField =
          fn (jobject, fieldID) =>
             G(GetFloatField (JNIEnv, jobject, fieldID)),
*)
          GetDoubleField =
          fn (jobject, fieldID) =>
             G(GetDoubleField (JNIEnv, jobject, fieldID)),
          SetObjectField =
          fn (jobject, fieldID, value) =>
             G(SetObjectField (JNIEnv, jobject, fieldID, value)),
          SetBooleanField =
          fn (jobject, fieldID, value) =>
             G(SetBooleanField (JNIEnv, jobject, fieldID, value)),
          SetByteField =
          fn (jobject, fieldID, value) =>
             G(SetByteField (JNIEnv, jobject, fieldID, value)),
          SetCharField =
          fn (jobject, fieldID, value) =>
             G(SetCharField (JNIEnv, jobject, fieldID, value)),
          SetShortField =
          fn (jobject, fieldID, value) =>
             G(SetShortField (JNIEnv, jobject, fieldID, value)),
          SetIntField =
          fn (jobject, fieldID, value) =>
             G(SetIntField (JNIEnv, jobject, fieldID, value)),
          SetLongField =
          fn (jobject, fieldID, value) =>
             G(SetLongField (JNIEnv, jobject, fieldID, value)),
          SetFloatField =
          fn (jobject, fieldID, value) =>
             G(SetFloatField (JNIEnv, jobject, fieldID, value)),
          SetDoubleField =
          fn (jobject, fieldID, value) =>
             G(SetDoubleField (JNIEnv, jobject, fieldID, value)),

          GetStaticMethodID =
          fn (class, name, sign) =>
             G(GetStaticMethodID (JNIEnv, class, name, sign)),
          CallStaticObjectMethodA =
          fn (class, methodID, values) =>
             G(CallStaticObjectMethodA (JNIEnv, class, methodID, values)),
          CallStaticBooleanMethodA =
          fn (class, methodID, values) =>
             G(CallStaticBooleanMethodA (JNIEnv, class, methodID, values)),
          CallStaticByteMethodA =
          fn (class, methodID, values) =>
             G(CallStaticByteMethodA (JNIEnv, class, methodID, values)),
          CallStaticCharMethodA =
          fn (class, methodID, values) =>
             G(CallStaticCharMethodA (JNIEnv, class, methodID, values)),
          CallStaticShortMethodA =
          fn (class, methodID, values) =>
             G(CallStaticShortMethodA (JNIEnv, class, methodID, values)),
          CallStaticIntMethodA =
          fn (class, methodID, values) =>
             G(CallStaticIntMethodA (JNIEnv, class, methodID, values)),
          CallStaticLongMethodA =
          fn (class, methodID, values) =>
             G(CallStaticLongMethodA (JNIEnv, class, methodID, values)),
(* FIXME: enable this when SML# FFI supports float.
          CallStaticFloatMethodA =
          fn (class, methodID, values) =>
             G(CallStaticFloatMethodA (JNIEnv, class, methodID, values)),
*)
          CallStaticDoubleMethodA =
          fn (class, methodID, values) =>
             G(CallStaticDoubleMethodA (JNIEnv, class, methodID, values)),
          CallStaticVoidMethodA =
          fn (class, methodID, values) =>
             G(CallStaticVoidMethodA (JNIEnv, class, methodID, values)),

          GetStaticFieldID =
          fn (jclass, name, sign) =>
             G(GetStaticFieldID (JNIEnv, jclass, name, sign)),
          GetStaticObjectField =
          fn (jclass, fieldID) =>
             G(GetStaticObjectField (JNIEnv, jclass, fieldID)),
          GetStaticBooleanField =
          fn (jclass, fieldID) =>
             G(GetStaticBooleanField (JNIEnv, jclass, fieldID)),
          GetStaticByteField =
          fn (jclass, fieldID) =>
             G(GetStaticByteField (JNIEnv, jclass, fieldID)),
          GetStaticCharField =
          fn (jclass, fieldID) =>
             G(GetStaticCharField (JNIEnv, jclass, fieldID)),
          GetStaticShortField =
          fn (jclass, fieldID) =>
             G(GetStaticShortField (JNIEnv, jclass, fieldID)),
          GetStaticIntField =
          fn (jclass, fieldID) =>
             G(GetStaticIntField (JNIEnv, jclass, fieldID)),
          GetStaticLongField =
          fn (jclass, fieldID) =>
             G(GetStaticLongField (JNIEnv, jclass, fieldID)),
(* FIXME: enable this when SML# FFI supports float.
          GetStaticFloatField =
          fn (jclass, fieldID) =>
             G(GetStaticFloatField (JNIEnv, jclass, fieldID)),
*)
          GetStaticDoubleField =
          fn (jclass, fieldID) =>
             G(GetStaticDoubleField (JNIEnv, jclass, fieldID)),
          SetStaticObjectField =
          fn (jclass, fieldID, value) =>
             G(SetStaticObjectField (JNIEnv, jclass, fieldID, value)),
          SetStaticBooleanField =
          fn (jclass, fieldID, value) =>
             G(SetStaticBooleanField (JNIEnv, jclass, fieldID, value)),
          SetStaticByteField =
          fn (jclass, fieldID, value) =>
             G(SetStaticByteField (JNIEnv, jclass, fieldID, value)),
          SetStaticCharField =
          fn (jclass, fieldID, value) =>
             G(SetStaticCharField (JNIEnv, jclass, fieldID, value)),
          SetStaticShortField =
          fn (jclass, fieldID, value) =>
             G(SetStaticShortField (JNIEnv, jclass, fieldID, value)),
          SetStaticIntField =
          fn (jclass, fieldID, value) =>
             G(SetStaticIntField (JNIEnv, jclass, fieldID, value)),
          SetStaticLongField =
          fn (jclass, fieldID, value) =>
             G(SetStaticLongField (JNIEnv, jclass, fieldID, value)),
          SetStaticFloatField =
          fn (jclass, fieldID, value) =>
             G(SetStaticFloatField (JNIEnv, jclass, fieldID, value)),
          SetStaticDoubleField =
          fn (jclass, fieldID, value) =>
             G(SetStaticDoubleField (JNIEnv, jclass, fieldID, value)),

          NewStringUTF = fn (string) => G(NewStringUTF (JNIEnv, string)),
          GetStringUTFChars =
          fn (jstring, isCopy) =>
             G(GetStringUTFChars (JNIEnv, jstring, isCopy)),
          ReleaseStringUTFChars =
          fn (jstring, buffer) =>
             G(ReleaseStringUTFChars (JNIEnv, jstring, buffer)),

          GetArrayLength = fn (jarray) => G(GetArrayLength (JNIEnv, jarray)),
          NewObjectArray =
          fn (jsize, jclass, jobject) =>
             G(NewObjectArray (JNIEnv, jsize, jclass, jobject)),
          GetObjectArrayElement =
          fn (jobjectArray, jsize) =>
             G(GetObjectArrayElement (JNIEnv, jobjectArray, jsize)),
          SetObjectArrayElement =
          fn (jobjectArray, jsize, jobject) =>
             G(SetObjectArrayElement (JNIEnv, jobjectArray, jsize, jobject)),
          NewBooleanArray = fn (jsize) => G(NewBooleanArray (JNIEnv, jsize)),
          NewByteArray = fn (jsize) => G(NewByteArray (JNIEnv, jsize)),
          NewCharArray = fn (jsize) => G(NewCharArray (JNIEnv, jsize)),
          NewShortArray = fn (jsize) => G(NewShortArray (JNIEnv, jsize)),
          NewIntArray = fn (jsize) => G(NewIntArray (JNIEnv, jsize)),
          NewLongArray = fn (jsize) => G(NewLongArray (JNIEnv, jsize)),
          NewFloatArray = fn (jsize) => G(NewFloatArray (JNIEnv, jsize)),
          NewDoubleArray = fn (jsize) => G(NewDoubleArray (JNIEnv, jsize)),
          GetBooleanArrayElements =
          fn (jbooleanArray, jbooleanRef) =>
             G(GetBooleanArrayElements (JNIEnv, jbooleanArray, jbooleanRef)),
          GetByteArrayElements =
          fn (jbyteArray, jbooleanRef) =>
             G(GetByteArrayElements (JNIEnv, jbyteArray, jbooleanRef)),
          GetCharArrayElements =
          fn (jcharArray, jbooleanRef) =>
             G(GetCharArrayElements (JNIEnv, jcharArray, jbooleanRef)),
          GetShortArrayElements =
          fn (jshortArray, jbooleanRef) =>
             G(GetShortArrayElements (JNIEnv, jshortArray, jbooleanRef)),
          GetIntArrayElements =
          fn (jintArray, jbooleanRef) =>
             G(GetIntArrayElements (JNIEnv, jintArray, jbooleanRef)),
          GetLongArrayElements =
          fn (jlongArray, jbooleanRef) =>
             G(GetLongArrayElements (JNIEnv, jlongArray, jbooleanRef)),
          GetFloatArrayElements =
          fn (jfloatArray, jbooleanRef) =>
             G(GetFloatArrayElements (JNIEnv, jfloatArray, jbooleanRef)),
          GetDoubleArrayElements =
          fn (jdoubleArray, jbooleanRef) =>
             G(GetDoubleArrayElements (JNIEnv, jdoubleArray, jbooleanRef)),
          ReleaseBooleanArrayElements =
          fn (jbooleanArray, jbooleanBuffer, jint) =>
             G(ReleaseBooleanArrayElements
                   (JNIEnv, jbooleanArray, jbooleanBuffer, jint)),
          ReleaseByteArrayElements =
          fn (jbyteArray, jbyteBuffer, jint) =>
             G(ReleaseByteArrayElements
                   (JNIEnv, jbyteArray, jbyteBuffer, jint)),
          ReleaseCharArrayElements =
          fn (jcharArray, jcharBuffer, jint) =>
             G(ReleaseCharArrayElements
                   (JNIEnv, jcharArray, jcharBuffer, jint)),
          ReleaseShortArrayElements =
          fn (jshortArray, jshortBuffer, jint) =>
             G(ReleaseShortArrayElements
                   (JNIEnv, jshortArray, jshortBuffer, jint)),
          ReleaseIntArrayElements =
          fn (jintArray, jintBuffer, jint) =>
             G(ReleaseIntArrayElements (JNIEnv, jintArray, jintBuffer, jint)),
          ReleaseLongArrayElements =
          fn (jlongArray, jlongBuffer, jint) =>
             G(ReleaseLongArrayElements
                   (JNIEnv, jlongArray, jlongBuffer, jint)),
          ReleaseFloatArrayElements =
          fn (jfloatArray, jfloatBuffer, jint) =>
             G(ReleaseFloatArrayElements
                   (JNIEnv, jfloatArray, jfloatBuffer, jint)),
          ReleaseDoubleArrayElements =
          fn (jdoubleArray, jdoubleBuffer, jint) =>
             G(ReleaseDoubleArrayElements
                   (JNIEnv, jdoubleArray, jdoubleBuffer, jint)),

          GetJavaVM = fn (VMref) => G(GetJavaVM (JNIEnv, VMref)),
          this = JNIEnv
        } : JNIEnv
      end

  local
    structure N = NativeDataTransporter
    (* native data transporter for JavaVMInitArgs.
     *   typedef struct JavaVMOption {
     *     char *optionString;
     *     void *extraInfo;
     *   } JavaVMOption;
     *   typedef struct JavaVMInitArgs {
     *     jint version;
     *     jint nOptions;
     *     JavaVMOption *options;
     *     jboolean ignoreUnrecognized;
     *   } JavaVMInitArgs;
     *)
(*
    val conv = N.boxed (N.tuple4 (N.int, N.int, N.address, N.word))
*)
    val JavaVMOption = N.tuple2 (N.string, N.address)
    val conv =
        N.boxed (N.tuple4 (N.int, N.int, N.flatArray JavaVMOption, N.word))
  in
  fun createJNI (initOptions) =
      let
        val ptrJNI_CreateJavaVM = DL.dlsym (getJVMDLL (), "JNI_CreateJavaVM")
        val JNI_CreateJavaVM =
            ptrJNI_CreateJavaVM
            : _import _stdcall
                      (JavaVMPtr ref, JNIEnvPtr ref, UM.address) -> T.jint
        val JavaVMRef = ref (UM.NULL : JavaVMPtr)
        val JNIEnvRef = ref (UM.NULL : JNIEnvPtr)
        val options =
            Array.fromList
                (List.map (fn option => (option, UM.NULL)) initOptions)
        val initArg =
            N.export
                conv
                (JNI_VERSION_1_2, List.length initOptions, options, (* JNI_FALSE *) 0w0)
        val res = JNI_CreateJavaVM (JavaVMRef, JNIEnvRef, N.addressOf initArg)
        val _ = N.release initArg
        val _ =
            if res = 0
            then ()
            else
              raise
                Fail ("JNI_CreateJavaVM fails:code(" ^ Int.toString res ^ ")")
      in
        (wrapJavaVM (!JavaVMRef), wrapJNIEnv (!JNIEnvRef))
      end
  end (* end of local *)

  local
    val JNIRef = ref (NONE : (JavaVM * JNIEnv) option)
  in
  (*
   * 'initialize' ensures that JNI is initialized only once,
   * because, in current JNI, invocation of JNI_CreateJavaVM more than once
   * seems fail always even after jvm->DestroyJavaVM is called.
   *)
  fun initialize (initOptions) =
      case !JNIRef
       of SOME _ => ()
        | NONE => JNIRef := SOME (createJNI (initOptions))
  fun getJavaVM () =
      case !JNIRef
       of NONE => raise Fail "Java is not initialized."
        | SOME (JavaVM, _) => JavaVM
  fun getJNIEnv () =
      case !JNIRef
       of NONE => raise Fail "Java is not initialized."
        | SOME (_, JNIEnv) => JNIEnv
  end

end;
