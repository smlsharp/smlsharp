(**
 * conversion functions between JNI values and ML values.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JAVA_VALUE.sig,v 1.6 2010/04/25 13:38:47 kiyoshiy Exp $
 *)
signature JAVA_VALUE = 
sig

  (***************************************************************************)

  type boolean = bool
  type byte = Word8.word
  type char = word
  type short = int
  type int = int
  (** 64 bit integer. *)
  type long = IntInf.int
  type double = real
  type float = Real32.real
  (** reference to a Java object. *)
  type Object
  type String = string option

  (**
   * A function with no argument takes 'void' value.
   * A function with no return value returns 'void' value.
   *)
  type void = unit

  (** reference to an instance of java.lang.Class class. *)
  type Class = Object

  type array = Object

  type booleanArray = array
  type byteArray = array
  type charArray = array
  type shortArray = array
  type intArray = array
  type longArray = array
  type floatArray = array
  type doubleArray = array
  type objectArray = array

  (***************************************************************************)

  (** null Object reference. *)
  val null : Object

  (** returns true if the object reference is null. *)
  val isNull : Object -> bool
  (** returns true if two object references point to the same object. *)
  val isSameObject : Object * Object -> bool

  val boolToJBoolean : boolean -> JNITypes.jboolean
  val jbooleanToBool : JNITypes.jboolean -> boolean
  val jbooleanToJValue : JNITypes.jboolean -> JNITypes.jvalue
  val releaseJBoolean : JNITypes.jboolean -> unit

  val byteToJByte : byte -> JNITypes.jbyte
  val jbyteToByte : JNITypes.jbyte -> byte
  val jbyteToJValue : JNITypes.jbyte -> JNITypes.jvalue
  val releaseJByte : JNITypes.jbyte -> unit

  (* jchar is unsigned 16 bits. *)
  val charToJChar : char -> JNITypes.jchar
  val jcharToChar : JNITypes.jchar -> char
  val jcharToJValue : word -> JNITypes.jvalue
  val releaseJChar : JNITypes.jchar -> unit

  val shortToJShort : short -> JNITypes.jshort
  val jshortToShort : JNITypes.jshort -> short
  val jshortToJValue : JNITypes.jshort -> JNITypes.jvalue
  val releaseJShort : JNITypes.jshort -> unit

  val intToJInt : int -> JNITypes.jint
  val jintToInt : JNITypes.jint -> int
  val jintToJValue : JNITypes.jint -> JNITypes.jvalue
  val releaseJInt : JNITypes.jint -> unit

  val longToJLong : long -> JNITypes.jlong
  val jlongToLong : JNITypes.jlong -> long
  val jlongToJValue : JNITypes.jlong -> JNITypes.jvalue
  val releaseJLong : JNITypes.jlong -> unit

  val floatToJFloat : float -> JNITypes.jfloat
  val jfloatToFloat : JNITypes.jfloat -> float
  val jfloatToJValue : JNITypes.jfloat -> JNITypes.jvalue
  val releaseJFloat : JNITypes.jfloat -> unit

  val doubleToJDouble : double -> JNITypes.jdouble
  val jdoubleToDouble : JNITypes.jdouble -> double
  val jdoubleToJValue : JNITypes.jdouble -> JNITypes.jvalue
  val releaseJDouble : JNITypes.jdouble -> unit

  val objectToJObject : Object -> JNITypes.jobject
  val jobjectToObject : JNITypes.jobject -> Object
  val jobjectToJValue : JNITypes.jobject -> JNITypes.jvalue
  val releaseJObject : JNITypes.jobject -> unit

  val stringToJString : String -> JNITypes.jstring
  val jstringToJValue : JNITypes.jstring -> JNITypes.jvalue
  val jstringToString : JNITypes.jstring -> String
  val releaseJString : JNITypes.jstring -> unit

  val jvaluesToArray : JNITypes.jvalue list -> JNITypes.jvalueArray

  (***************************************************************************)

end
