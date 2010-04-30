(**
 * interface of Java.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JAVA.sig,v 1.11 2010/04/26 06:53:49 kiyoshiy Exp $
 *)
signature JAVA =
sig

  structure Types : JNI_TYPES
  structure JNI : JNI
  structure Value : JAVA_VALUE
  structure Array : JAVA_ARRAY
  structure ClassHelper : JAVA_CLASS_HELPER

  type Object
  type ('members, 'classes) instance

  exception JavaException of Object
  exception ClassCastException

  (** initialize Java interface.
   * User should call this function once before using functions of the Java
   * interface.
   *)
  val initialize : string list -> unit

  val null : Object
  val isNull : Object -> bool
  val isSameObject : Object * Object -> bool

  val call
      : ('members, 'classes) instance
        -> ('members -> Object -> ('arg -> 'result))
        -> ('arg -> 'result)

  val referenceOf : ('members, 'classes) instance -> Object

end;