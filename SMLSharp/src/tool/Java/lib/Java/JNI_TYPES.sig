(**
 * datatypes which are mapped to native datatypes declared in JNI.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JNI_TYPES.sig,v 1.4 2007/11/04 05:22:16 kiyoshiy Exp $
 *)
signature JNI_TYPES =
sig

  (** unsigned 8 bits *)
  type jboolean = word
  (** signed 8 bits *)
  type jbyte = int
  (** unsigned 16 bits *)
  type jchar = word
  (** signed 16 bits *)
  type jshort = int
  (** signed 32 bits *)
  type jint = int
  (* signed 64 bits *)
  type jlong = Real64.real
  (** 32 bits floating number *)
  type jfloat = Real32.real
  (** 64 bits floating number *)
  type jdouble = real
  (** object reference *)
  type jobject = unit ptr

  type jclass = jobject
  type jstring = jobject
  type jthrowable = jobject
  type jarray = jobject

  type jbooleanArray = jarray
  type jbyteArray = jarray
  type jcharArray = jarray
  type jshortArray = jarray
  type jintArray = jarray
  type jlongArray = jarray
  type jfloatArray = jarray
  type jdoubleArray = jarray
  type jobjectArray = jarray

  type jbooleans = UnmanagedMemory.address
  type jbytes = UnmanagedMemory.address
  type jchars = UnmanagedMemory.address
  type jshorts = UnmanagedMemory.address
  type jints = UnmanagedMemory.address
  type jlongs = UnmanagedMemory.address
  type jfloats = UnmanagedMemory.address
  type jdoubles = UnmanagedMemory.address
  type jobjects = UnmanagedMemory.address

  type jmethodID = int
  type jfieldID = int
  (** serialized form of argument. *)
  type jvalue = Word32.word * Word32.word
  (** array of jvalue. Each element occupies 2 words. *)
  type jvalueArray = Word32.word array
  type jsize = jint

end
