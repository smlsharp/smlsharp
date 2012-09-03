(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JNITypes.sml,v 1.5 2007/11/04 05:22:16 kiyoshiy Exp $
 *)
structure JNITypes :> JNI_TYPES =
struct
  (* unsigned 8 bits *)
  type jboolean = word
  (* signed 8 bits *)
  type jbyte = int
  (* unsigned 16 bits *)
  type jchar = word
  (* signed 16 bits *)
  type jshort = int
  (* signed 32 bits *)
  type jint = int
  (* signed 64 bits *)
  type jlong = Real64.real (* use Real64 to hold 64 bit value. *)
  (* 32 bits *)
  type jfloat = Real32.real
  (* 64 bits *)
  type jdouble = real

  type jobject = unit ptr
  type jclass = jobject
  type jthrowable = jobject
  type jstring = jobject
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
  type jvalue = Word32.word * Word32.word (* jvalue has sizeof(double) *)
  type jvalueArray = Word32.word array
  type jsize = jint
end;

