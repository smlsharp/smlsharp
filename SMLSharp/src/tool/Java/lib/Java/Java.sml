(**
 * interface of Java.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Java.sml,v 1.9 2010/04/26 06:53:49 kiyoshiy Exp $
 *)
structure Java : JAVA =
struct

  structure Types = JNITypes
  structure JNI = JNI
  structure Value = JavaValue
  structure ClassHelper = JavaClassHelper
  structure Array = JavaArray

  type Object = Value.Object
  datatype instance = datatype ClassHelper.instance

  exception JavaException = ClassHelper.JavaException
  exception ClassCastException = ClassHelper.ClassCastException

  val initialize = JNI.initialize

  val null = Value.null
  val isNull = Value.isNull
  val isSameObject = Value.isSameObject

  val call = ClassHelper.call
  val referenceOf = ClassHelper.referenceOf

end;
