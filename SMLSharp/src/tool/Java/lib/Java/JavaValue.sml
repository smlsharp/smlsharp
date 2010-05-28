(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JavaValue.sml,v 1.7 2010/04/25 13:38:47 kiyoshiy Exp $
 *)
structure JavaValue :> JAVA_VALUE =
struct

  (***************************************************************************)

  structure J = JNI
  structure F = SMLSharp.Finalizable
  structure Types = JNITypes
  structure UM = UnmanagedMemory;
  structure US = UnmanagedString;

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
  type Object = JNITypes.jobject SMLSharp.Finalizable.finalizable option
  type String = string option

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

  val null = NONE : Object
  val isNull : Object -> bool = not o Option.isSome

  val JNI_FALSE = 0w0
  val JNI_TRUE = 0w1

  fun boolToJBoolean bool = if bool then JNI_TRUE else JNI_FALSE
  fun jbooleanToBool (jboolean : Types.jboolean) =
      not (jboolean = JNI_FALSE)
  fun jbooleanToJValue (jboolean : Types.jboolean) =
      (jboolean, 0w0)
  fun releaseJBoolean (jboolean : Types.jboolean) = ()

  fun byteToJByte byte = (Word8.toInt byte) : Types.jbyte
  fun jbyteToByte (jbyte : Types.jbyte) = Word8.fromInt jbyte
  fun jbyteToJValue (jbyte : Types.jbyte) = (Word.fromInt jbyte, 0w0)
  fun releaseJByte (jbyte : Types.jbyte) = ()

  fun charToJChar (char : char) = char : Types.jchar
  fun jcharToChar (jchar : Types.jchar) = (jchar : char)
  fun jcharToJValue (jchar : Types.jchar) = (jchar, 0w0)
  fun releaseJChar (jchar : Types.jchar) = ()

  fun shortToJShort (short : short) = (short : Types.jshort)
  fun jshortToShort (jshort : Types.jshort) = (jshort : short)
  fun jshortToJValue (jshort : Types.jshort) = (Word.fromInt jshort, 0w0)
  fun releaseJShort (jshort : Types.jshort) = ()

  fun intToJInt (int : int) = (int : Types.jint)
  fun jintToInt (jint : Types.jint) = (jint : int)
  fun jintToJValue (jint : Types.jint) = (Word.fromInt jint, 0w0)
  fun releaseJInt (jint : Types.jint) = ()

  local
    val mask = Word.toLargeInt 0wxFF
    fun getByte long i = 
        Word8.fromLargeInt(IntInf.andb (IntInf.~>> (long, 0w8 * i), mask))
  in
  fun longToJLong (long : long) =
      let
        val f = (getByte long) o Word.fromInt
        val vec = Word8Vector.tabulate (8, f) (* in little-endian order *)
      in
        PackReal64Little.fromBytes vec
      end
  end
  fun jlongToLong (double : Types.jlong) =
      let
        val vec = PackReal64Little.toBytes double
        val long =
            Word8Vector.foldr
                (fn (b, long) =>
                    IntInf.orb (IntInf.<< (long, 0w8), Word8.toLargeInt b))
                0
                vec
      in
        long
      end
  local
    fun jlongToJValueLittle (double : Types.jlong) =
        let
          val vec = PackReal64Little.toBytes double
          val w1 = PackWord32Little.subVec (vec, 0)
          val w2 = PackWord32Little.subVec (vec, 4)
        in
          (w1, w2)
        end
    fun jlongToJValueBig (double : Types.jlong) =
        let
          val vec = PackReal64Big.toBytes double
          val w1 = PackWord32Big.subVec (vec, 0)
          val w2 = PackWord32Big.subVec (vec, 4)
        in
          (w1, w2)
        end
  in
  val jlongToJValue = 
      case SMLSharp.Platform.byteOrder
       of SMLSharp.Platform.LittleEndian => jlongToJValueLittle
        | SMLSharp.Platform.BigEndian => jlongToJValueBig
  end
  fun releaseJLong (jlong : Types.jlong) = ()

  local
    val (floatToBytes, doubleToBytes, subBytes) =
        case SMLSharp.Platform.byteOrder
         of SMLSharp.Platform.LittleEndian =>
            (
              PackReal32Little.toBytes,
              PackReal64Little.toBytes,
              PackWordLittle.subVec
            )
          | SMLSharp.Platform.BigEndian =>
            (
              PackReal32Big.toBytes,
              PackReal64Big.toBytes,
              PackWordBig.subVec
            )
  in

  fun floatToJFloat (float : float) = float : Types.jfloat
  fun jfloatToFloat (jfloat : Types.jfloat) = jfloat : float
  fun jfloatToJValue (jfloat : Types.jfloat) =
      let
        val bytes = floatToBytes jfloat
        val word1 = subBytes (bytes, 0)
      in
        (word1, 0w0)
      end
  fun releaseJFloat (jfloat : Types.jfloat) = ()

  fun doubleToJDouble (double : real) = double : Types.jdouble
  fun jdoubleToDouble (jdouble : Types.jdouble) = jdouble : real
  fun jdoubleToJValue (jdouble : Types.jdouble) =
      let
        val bytes = doubleToBytes jdouble
        val word1 = subBytes (bytes, 0)
        val word2 = subBytes (bytes, 4)
      in
        (word1, word2)
      end
  fun releaseJDouble (jdouble : Types.jdouble) = ()

  end

  fun stringToJString (SOME string) =
      #NewStringUTF (J.getJNIEnv()) (string) : Types.jstring
    | stringToJString NONE = UM.NULL
  fun jstringToString (jstring : Types.jstring) =
      if UnmanagedMemory.isNULL jstring
      then NONE
      else
        let
          val us =
              #GetStringUTFChars (J.getJNIEnv()) (jstring, ref JNI_FALSE)
          val s = US.import us
          val _ = #ReleaseStringUTFChars (J.getJNIEnv()) (jstring, us)
        in
          SOME s
        end
  fun jstringToJValue (jstring : Types.jstring) =
      (UM.addressToWord jstring, 0w0)
  fun releaseJString (jstring : Types.jstring) =
      if UnmanagedMemory.isNULL jstring
      then ()
      else #DeleteLocalRef (J.getJNIEnv()) jstring

  (* User should call releaseJObject for each jobject to call DeleteLocalRef
   * on it.
   * For object, DeleteLocalRef is called automatically on a jobject which is
   * held in the object.
   *)
  fun objectToJObject (SOME object) =
      #NewLocalRef (J.getJNIEnv()) (F.getValue object) : Types.jobject
    | objectToJObject NONE = UM.NULL
  fun jobjectToObject (jobject : Types.jobject) =
      if UnmanagedMemory.isNULL jobject
      then NONE
      else
        let
          val this =
              F.new
                  (
                    #NewLocalRef (J.getJNIEnv()) jobject,
                    #DeleteLocalRef (J.getJNIEnv())
                  )
        in SOME(this) : Object
        end
  fun jobjectToJValue (jobject : Types.jobject) =
      (UM.addressToWord jobject, 0w0)
  fun releaseJObject (jobject : Types.jobject) =
      if UnmanagedMemory.isNULL jobject
      then ()
      else #DeleteLocalRef (J.getJNIEnv()) jobject

  fun jvaluesToArray jvalues =
      let
        val array = Array.array (length jvalues * 2, 0w0)
        val _ =
            List.foldl
                (fn ((fst, snd), offset) =>
                    (
                      Array.update (array, offset, fst);
                      Array.update (array, offset + 1, snd);
                      offset + 2
                    ))
                0
                jvalues
      in
        array : Types.jvalueArray
      end

  fun isSameObject (obj1, obj2) =
      jbooleanToBool
          (#IsSameObject
               (J.getJNIEnv ())
               (objectToJObject obj1, objectToJObject obj2))

  (***************************************************************************)

end;
