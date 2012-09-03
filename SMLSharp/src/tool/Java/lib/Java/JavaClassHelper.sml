(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JavaClassHelper.sml,v 1.9 2010/04/25 11:54:55 kiyoshiy Exp $
 *)
structure JavaClassHelper : JAVA_CLASS_HELPER =
struct

  structure J = JNI
  structure JV = JavaValue
  structure T = JNITypes

  exception ClassCastException
  exception JavaException of JV.Object

  type ('jnitype, 'mltype) t =
       {
         callMethod
         : JNI.JNIEnv -> (T.jobject * T.jmethodID * T.jvalueArray -> 'jnitype),
         callStaticMethod
         : JNI.JNIEnv -> (T.jclass * T.jmethodID * T.jvalueArray -> 'jnitype),
         getField : JNI.JNIEnv -> (T.jobject * T.jfieldID -> 'jnitype),
         setField : JNI.JNIEnv -> (T.jobject * T.jfieldID * 'jnitype -> void),
         getStaticField
         : JNI.JNIEnv -> (T.jclass * T.jfieldID -> 'jnitype),
         setStaticField
         : JNI.JNIEnv -> (T.jclass * T.jfieldID * 'jnitype -> void),
         toJNIType : 'mltype -> 'jnitype,
         toJValue : 'jnitype -> JNITypes.jvalue,
         toMLType : 'jnitype -> 'mltype,
         releaseJNIType : 'jnitype -> unit
       }

  type param = JNITypes.jvalue * (unit -> unit)
  type 't method = JV.Object -> param list -> 't
  type 't static_method = JV.Class -> param list -> 't

  type 't get_field = JV.Object -> 't
  type 't set_field = JV.Object -> 't -> void
  type 't get_static_field = JV.Class -> 't
  type 't set_static_field = JV.Class -> 't -> void

  datatype ('members, 'classes) instance = Instance of 'members * JV.Object

  val Z : (T.jboolean, JV.boolean) t =
      {
        toJNIType = JV.boolToJBoolean,
        toJValue = JV.jbooleanToJValue,
        toMLType = JV.jbooleanToBool,
        releaseJNIType = JV.releaseJBoolean,
        callMethod = #CallBooleanMethodA,
        callStaticMethod = #CallStaticBooleanMethodA,
        getField = #GetBooleanField,
        setField = #SetBooleanField,
        getStaticField = #GetStaticBooleanField,
        setStaticField = #SetStaticBooleanField
      }

  val B : (T.jbyte, JV.byte) t =
      {
        toJNIType = JV.byteToJByte,
        toJValue = JV.jbyteToJValue,
        toMLType = JV.jbyteToByte,
        releaseJNIType = JV.releaseJByte,
        callMethod = #CallByteMethodA,
        callStaticMethod = #CallStaticByteMethodA,
        getField = #GetByteField,
        setField = #SetByteField,
        getStaticField = #GetStaticByteField,
        setStaticField = #SetStaticByteField
      }

  val C : (T.jchar, JV.char) t =
      {
        toJNIType = JV.charToJChar,
        toJValue = JV.jcharToJValue,
        toMLType = JV.jcharToChar,
        releaseJNIType = JV.releaseJChar,
        callMethod = #CallCharMethodA,
        callStaticMethod = #CallStaticCharMethodA,
        getField = #GetCharField,
        setField = #SetCharField,
        getStaticField = #GetStaticCharField,
        setStaticField = #SetStaticCharField
      }

  val S : (T.jshort, JV.short) t =
      {
        toJNIType = JV.shortToJShort,
        toJValue = JV.jshortToJValue,
        toMLType = JV.jshortToShort,
        releaseJNIType = JV.releaseJShort,
        callMethod = #CallShortMethodA,
        callStaticMethod = #CallStaticShortMethodA,
        getField = #GetShortField,
        setField = #SetShortField,
        getStaticField = #GetStaticShortField,
        setStaticField = #SetStaticShortField
      }

  val I : (T.jint, JV.int) t =
      {
        toJNIType = JV.intToJInt,
        toJValue = JV.jintToJValue,
        toMLType = JV.jintToInt,
        releaseJNIType = JV.releaseJInt,
        callMethod = #CallIntMethodA,
        callStaticMethod = #CallStaticIntMethodA,
        getField = #GetIntField,
        setField = #SetIntField,
        getStaticField = #GetStaticIntField,
        setStaticField = #SetStaticIntField
      }

  val J : (T.jlong, JV.long) t =
      {
        toJNIType = JV.longToJLong,
        toJValue = JV.jlongToJValue,
        toMLType = JV.jlongToLong,
        releaseJNIType = JV.releaseJLong,
        callMethod = #CallLongMethodA,
        callStaticMethod = #CallStaticLongMethodA,
        getField = #GetLongField,
        setField = #SetLongField,
        getStaticField = #GetStaticLongField,
        setStaticField = #SetStaticLongField
      }

  fun errorFloatUnsupported _ _ = raise Fail "float is not supported."
  val F : (T.jfloat, JV.float) t =
      {
        toJNIType = JV.floatToJFloat,
        toJValue = JV.jfloatToJValue,
        toMLType = JV.jfloatToFloat,
        releaseJNIType = JV.releaseJFloat,
(* FIXME: enable this when SML# FFI supports float.
        callMethod = #CallFloatMethodA,
*)
        callMethod = errorFloatUnsupported,
(* FIXME: enable this when SML# FFI supports float.
        callStaticMethod = #CallStaticFloatMethodA,
*)
        callStaticMethod = errorFloatUnsupported,
(* FIXME: enable this when SML# FFI supports float.
        getField = #GetFloatField,
*)
        getField = errorFloatUnsupported,
        setField = #SetFloatField,
(* FIXME: enable this when SML# FFI supports float.
        getStaticField = #GetStaticFloatField,
*)
        getStaticField = errorFloatUnsupported,
        setStaticField = #SetStaticFloatField
      }

  val D : (T.jdouble, JV.double) t =
      {
        toJNIType = JV.doubleToJDouble,
        toJValue = JV.jdoubleToJValue,
        toMLType = JV.jdoubleToDouble,
        releaseJNIType = JV.releaseJDouble,
        callMethod = #CallDoubleMethodA,
        callStaticMethod = #CallStaticDoubleMethodA,
        getField = #GetDoubleField,
        setField = #SetDoubleField,
        getStaticField = #GetStaticDoubleField,
        setStaticField = #SetStaticDoubleField
      }

  val L : (T.jobject, JV.Object) t =
      {
        toJNIType = JV.objectToJObject,
        toJValue = JV.jobjectToJValue,
        toMLType = JV.jobjectToObject,
        releaseJNIType = JV.releaseJObject,
        callMethod = #CallObjectMethodA,
        callStaticMethod = #CallStaticObjectMethodA,
        getField = #GetObjectField,
        setField = #SetObjectField,
        getStaticField = #GetStaticObjectField,
        setStaticField = #SetStaticObjectField
      }

  val T : (T.jstring, JV.String) t =
      {
        toJNIType = JV.stringToJString,
        toJValue = JV.jstringToJValue,
        toMLType = JV.jstringToString,
        releaseJNIType = JV.releaseJString,
        callMethod = #CallObjectMethodA,
        callStaticMethod = #CallStaticObjectMethodA,
        getField = #GetObjectField,
        setField = #SetObjectField,
        getStaticField = #GetStaticObjectField,
        setStaticField = #SetStaticObjectField
      }

  val V : (void, void) t =
      {
        toJNIType = fn () => (),
        toJValue = fn () => (0w0, 0w0),
        toMLType = fn () => (),
        releaseJNIType = fn () => (),
        callMethod = #CallVoidMethodA,
        callStaticMethod = #CallStaticVoidMethodA,
        getField = fn _ => raise Fail "bug:try to get Void field",
        setField = fn _ => raise Fail "bug:try to set Void field",
        getStaticField = fn _ => raise Fail "bug:try to get Void static field",
        setStaticField = fn _ => raise Fail "bug:try to set Void static field"
      }

  local
    fun arg p v =
        let
          val jarg = #toJNIType p v
          val jvalue = #toJValue p jarg
          fun release () = #releaseJNIType p jarg
        in
          (jvalue, release)
        end
  in
  val argZ = arg Z
  val argB = arg B
  val argC = arg C
  val argS = arg S
  val argI = arg I
  val argJ = arg J
  val argF = arg F
  val argD = arg D
  val argL = arg L
  val argT = arg T
  end

  local
    fun processArgs args =
        let val (jvalues, releases) = ListPair.unzip args
        in
          (JV.jvaluesToArray jvalues, List.foldl (op o) (fn () => ()) releases)
        end

    fun callMethod return methodID (this : JV.Object) args =
        let
          val (argArray, releaseArgs) = processArgs args
          val jthis = JV.objectToJObject this
          val jresult =
              #callMethod return (J.getJNIEnv()) (jthis, methodID, argArray)
          val result = #toMLType return jresult
          val _ = releaseArgs ()
          val _ = JV.releaseJObject jthis
          val _ = #releaseJNIType return jresult
        in
          result
        end

    fun callStaticMethod return methodID class args =
        let
          val jclass = JV.objectToJObject class
          val (argArray, releaseArgs) = processArgs args
          val jresult =
              #callStaticMethod
                  return (J.getJNIEnv()) (jclass, methodID, argArray)
          val result = #toMLType return jresult
          val _ = JV.releaseJObject jclass
          val _ = releaseArgs ()
          val _ = #releaseJNIType return jresult
        in
          result
        end

    fun getField conv fieldID (this : JV.Object) =
        let
          val jthis = JV.objectToJObject this
          val jresult = #getField conv (J.getJNIEnv()) (jthis, fieldID)
          val result = #toMLType conv jresult
          val _ = JV.releaseJObject jthis
          val _ = #releaseJNIType conv jresult
        in
          result
        end

    fun setField conv fieldID (this : JV.Object) arg =
        let
          val jthis = JV.objectToJObject this
          val jnivalue = #toJNIType conv arg
          val _ = #setField conv (J.getJNIEnv()) (jthis, fieldID, jnivalue)
          val _ = JV.releaseJObject jthis
          val _ = #releaseJNIType conv jnivalue
        in
          ()
        end

    fun getStaticField conv fieldID class =
        let
          val jclass = JV.objectToJObject class
          val jresult = #getStaticField conv (J.getJNIEnv()) (jclass, fieldID)
          val result = #toMLType conv jresult
          val _ = JV.releaseJObject jclass
          val _ = #releaseJNIType conv jresult
        in
          result
        end

    fun setStaticField conv fieldID class arg =
        let
          val jclass = JV.objectToJObject class
          val jnivalue = #toJNIType conv arg
          val _ =
              #setStaticField conv (J.getJNIEnv()) (jclass, fieldID, jnivalue)
          val _ = JV.releaseJObject jclass
          val _ = #releaseJNIType conv jnivalue
        in
          ()
        end

  in
  val methodZ = callMethod Z : JNITypes.jmethodID -> JV.boolean method
  val methodB = callMethod B : JNITypes.jmethodID -> JV.byte method
  val methodC = callMethod C : JNITypes.jmethodID -> JV.char method
  val methodS = callMethod S : JNITypes.jmethodID -> JV.short method
  val methodI = callMethod I : JNITypes.jmethodID -> JV.int method
  val methodJ = callMethod J : JNITypes.jmethodID -> JV.long method
  val methodF = callMethod F : JNITypes.jmethodID -> JV.float method
  val methodD = callMethod D : JNITypes.jmethodID -> JV.double method
  val methodL = callMethod L : JNITypes.jmethodID -> JV.Object method
  val methodT = callMethod T : JNITypes.jmethodID -> JV.String method
  val methodV = callMethod V : JNITypes.jmethodID -> void method

  val static_methodZ = callStaticMethod Z
  val static_methodB = callStaticMethod B
  val static_methodC = callStaticMethod C
  val static_methodS = callStaticMethod S
  val static_methodI = callStaticMethod I
  val static_methodJ = callStaticMethod J
  val static_methodF = callStaticMethod F
  val static_methodD = callStaticMethod D
  val static_methodL = callStaticMethod L
  val static_methodT = callStaticMethod T
  val static_methodV = callStaticMethod V

  val getFieldZ = getField Z
  val getFieldB = getField B
  val getFieldC = getField C
  val getFieldS = getField S
  val getFieldI = getField I
  val getFieldJ = getField J
  val getFieldF = getField F
  val getFieldD = getField D
  val getFieldL = getField L
  val getFieldT = getField T

  val setFieldZ = setField Z
  val setFieldB = setField B
  val setFieldC = setField C
  val setFieldS = setField S
  val setFieldI = setField I
  val setFieldJ = setField J
  val setFieldF = setField F
  val setFieldD = setField D
  val setFieldL = setField L
  val setFieldT = setField T

  val getStaticFieldZ = getStaticField Z
  val getStaticFieldB = getStaticField B
  val getStaticFieldC = getStaticField C
  val getStaticFieldS = getStaticField S
  val getStaticFieldI = getStaticField I
  val getStaticFieldJ = getStaticField J
  val getStaticFieldF = getStaticField F
  val getStaticFieldD = getStaticField D
  val getStaticFieldL = getStaticField L
  val getStaticFieldT = getStaticField T

  val setStaticFieldZ = setStaticField Z
  val setStaticFieldB = setStaticField B
  val setStaticFieldC = setStaticField C
  val setStaticFieldS = setStaticField S
  val setStaticFieldI = setStaticField I
  val setStaticFieldJ = setStaticField J
  val setStaticFieldF = setStaticField F
  val setStaticFieldD = setStaticField D
  val setStaticFieldL = setStaticField L
  val setStaticFieldT = setStaticField T

  fun newInstance class VTBL methodID args =
      let
        val jclass = JV.objectToJObject class
        val (argArray, releaseArgs) = processArgs args
        val jobject =
            #NewObjectA (J.getJNIEnv()) (jclass, methodID, argArray)
        val object = JV.jobjectToObject jobject
        val _ = JV.releaseJObject jclass
        val _ = JV.releaseJObject jobject
        val _ = releaseArgs ()
      in
        Instance (VTBL, object)
      end

  end (* local *)

  fun isInstance class object =
      let
        val jclass = JV.objectToJObject class
        val jobject = JV.objectToJObject object
        val jresult = #IsInstanceOf (J.getJNIEnv()) (jobject, jclass)
        val result = JV.jbooleanToBool jresult
        val _ = JV.releaseJObject jclass
        val _ = JV.releaseJObject jobject
        val _ = JV.releaseJBoolean jresult
      in
        result
      end

  fun cast class VTBL object =
      if isInstance class object
      then Instance (VTBL, object)
      else raise ClassCastException

  fun referenceOf (Instance(VTBL, object)) = object

  fun call (Instance(VTBL, object)) selector arg =
      (selector VTBL object arg)
      handle J.JNIExn jthrowable =>
             let
               val throwable = JV.jobjectToObject jthrowable
               val _ = JV.releaseJObject jthrowable
             in
               raise JavaException throwable
             end

  fun initClass
          (className, classRef, methods, staticMethods, fields, staticFields) =
      let
        val jclass = #FindClass (J.getJNIEnv()) className
        val _ = classRef := JV.jobjectToObject jclass

        val _ =
            List.app
                (fn (methodIDref, name, sign) =>
                      methodIDref :=
                      #GetMethodID
                          (J.getJNIEnv())
                          (jclass, name, sign))
                methods
        val _ =
            List.app
                (fn (methodIDref, name, sign) =>
                    methodIDref :=
                    #GetStaticMethodID
                        (J.getJNIEnv())
                        (jclass, name, sign))
                staticMethods
        val _ =
            List.app
                (fn (fieldIDref, name, sign) =>
                      fieldIDref :=
                      #GetFieldID
                          (J.getJNIEnv())
                          (jclass, name, sign))
                fields
        val _ =
            List.app
                (fn (fieldIDref, name, sign) =>
                      fieldIDref :=
                      #GetStaticFieldID
                          (J.getJNIEnv())
                          (jclass, name, sign))
                staticFields
      in
        ()
      end

end;