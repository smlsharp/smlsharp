(**
 * module for Java array.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JAVA_ARRAY.sig,v 1.3 2010/04/25 07:44:56 kiyoshiy Exp $
 *)
signature JAVA_ARRAY =
sig

  val GetArrayLength : JavaValue.array -> JavaValue.int

  val NewObjectArray
      : int * JavaValue.Class * JavaValue.Object -> JavaValue.objectArray
  val NewBooleanArray : int -> JavaValue.booleanArray
  val NewByteArray : int -> JavaValue.byteArray
  val NewCharArray : int -> JavaValue.charArray
  val NewShortArray : int -> JavaValue.shortArray
  val NewIntArray : int -> JavaValue.intArray
  val NewLongArray : int -> JavaValue.longArray
  val NewFloatArray : int -> JavaValue.floatArray
  val NewDoubleArray : int -> JavaValue.doubleArray

  val subObjectArray : JavaValue.objectArray * int -> JavaValue.Object
  val updateObjectArray
      : JavaValue.objectArray * int * JavaValue.Object -> unit
  val subBooleanArray : JavaValue.booleanArray * int -> JavaValue.boolean
  val updateBooleanArray
      : JavaValue.booleanArray * int * JavaValue.boolean -> unit
  val subByteArray : JavaValue.byteArray * int -> JavaValue.byte
  val updateByteArray : JavaValue.byteArray * int * JavaValue.byte -> unit
  val subCharArray : JavaValue.charArray * int -> JavaValue.char
  val updateCharArray : JavaValue.charArray * int * JavaValue.char -> unit
  val subShortArray : JavaValue.shortArray * int -> JavaValue.short
  val updateShortArray : JavaValue.shortArray * int * JavaValue.short -> unit
  val subIntArray : JavaValue.intArray * int -> JavaValue.int
  val updateIntArray : JavaValue.intArray * int * JavaValue.int -> unit
  val subLongArray : JavaValue.longArray * int -> JavaValue.long
  val updateLongArray : JavaValue.longArray * int * JavaValue.long -> unit
  val subFloatArray : JavaValue.floatArray * int -> JavaValue.float
  val updateFloatArray : JavaValue.floatArray * int * JavaValue.float -> unit
  val subDoubleArray : JavaValue.doubleArray * int -> JavaValue.double
  val updateDoubleArray
      : JavaValue.doubleArray * int * JavaValue.double -> unit

end
