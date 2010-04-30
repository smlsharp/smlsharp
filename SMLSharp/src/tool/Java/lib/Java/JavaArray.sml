local
  structure J = JNI
  structure JV = JavaValue
  structure UM = UnmanagedMemory
in
(**
 * module for Java array.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: JavaArray.sml,v 1.2 2010/04/25 07:44:56 kiyoshiy Exp $
 *)
structure JavaArray : JAVA_ARRAY =
struct

  fun GetArrayLength array =
      JV.jintToInt (#GetArrayLength (J.getJNIEnv()) (JV.objectToJObject array))
  fun NewObjectArray (size, class, object) =
      JV.jobjectToObject
          (#NewObjectArray
               (J.getJNIEnv())
               (
                 JV.intToJInt size,
                 JV.objectToJObject class,
                 JV.objectToJObject object
               ))
  fun subObjectArray (array, index) =
      JV.jobjectToObject
          (#GetObjectArrayElement
               (J.getJNIEnv()) (JV.objectToJObject array, JV.intToJInt index))
  fun updateObjectArray (array, index, object) =
      #SetObjectArrayElement
          (J.getJNIEnv())
          (
            JV.objectToJObject array,
            JV.intToJInt index,
            JV.objectToJObject object
          )
  fun NewBooleanArray size =
      JV.jobjectToObject
          (#NewBooleanArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewByteArray size =
      JV.jobjectToObject
          (#NewByteArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewCharArray size =
      JV.jobjectToObject
          (#NewCharArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewShortArray size =
      JV.jobjectToObject
          (#NewShortArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewIntArray size =
      JV.jobjectToObject
          (#NewIntArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewLongArray size =
      JV.jobjectToObject
          (#NewLongArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewFloatArray size =
      JV.jobjectToObject
          (#NewFloatArray (J.getJNIEnv()) (JV.intToJInt size))
  fun NewDoubleArray size =
      JV.jobjectToObject
          (#NewDoubleArray (J.getJNIEnv()) (JV.intToJInt size))

  local
    val SIZE_OF_JBOOLEAN = 1
    val word8ToWord = Word.fromLargeWord o Word8.toLargeWord
    val wordToWord8 = Word8.fromLargeWord o Word.toLargeWord

    val SIZE_OF_JCHAR = 2
    fun packJCharBE (byte1, byte2) =
        let
          val word1 = word8ToWord byte1
          val word2 = word8ToWord byte2
        in
          Word.orb(Word.<<(word1, 0w8), word2) (* BE endian *)
        end
    fun unpackJCharBE jchar =
        (
          wordToWord8 (Word.andb (Word.>>(jchar, 0w8), 0wxFF)),
          wordToWord8 (Word.andb (jchar, 0wxFF))
        )
    fun packJCharLE (byte1, byte2) =
        let
          val word1 = word8ToWord byte1
          val word2 = word8ToWord byte2
        in
          Word.orb(Word.<<(word2, 0w8), word1)
        end
    fun unpackJCharLE jchar =
        (
          wordToWord8 (Word.andb (jchar, 0wxFF)),
          wordToWord8 (Word.andb (Word.>>(jchar, 0w8), 0wxFF))
        )
    val (packJChar, unpackJChar) =
        case SMLSharp.Platform.byteOrder
         of SMLSharp.Platform.BigEndian => (packJCharBE, unpackJCharBE)
          | SMLSharp.Platform.LittleEndian => (packJCharLE, unpackJCharLE)

    val SIZE_OF_JINT = 4
    val SIZE_OF_JFLOAT = 4 (* 32 bit *)
    val SIZE_OF_JDOUBLE = 8
  in

  fun subJBooleans (jbooleans, index) =
      let
        val address = UM.advance (jbooleans, index * SIZE_OF_JBOOLEAN)
        val byte = UM.sub address
      in
        word8ToWord byte
      end
  fun updateJBooleans (jbooleans, index, jboolean) =
      let
        val address = UM.advance (jbooleans, index * SIZE_OF_JBOOLEAN)
        val _ = UM.update (address, wordToWord8 jboolean)
      in
        ()
      end

  fun subJBytes (jbytes, index) =
      Word.toInt (subJBooleans (jbytes, index))
  fun updateJBytes (jbytes, index, jbyte) =
      updateJBooleans (jbytes, index, Word.fromInt jbyte)

  fun subJChars (jchars, index) =
      let
        val address = UM.advance (jchars, index * SIZE_OF_JCHAR)
        val byte1 = UM.sub address
        val byte2 = UM.sub (UM.advance (address, 1))
      in
        packJChar (byte1, byte2)
      end
  fun updateJChars (jchars, index, jchar) =
      let
        val (byte1, byte2) = unpackJChar jchar
        val address = UM.advance (jchars, index * SIZE_OF_JCHAR)
        val _ = UM.update (address, byte1)
        val _ = UM.update (UM.advance (address, 1), byte2)
      in
        ()
      end

  fun subJShorts (jshorts, index) =
      Word.toInt (subJChars (jshorts, index))
  fun updateJShorts (jshorts, index, jshort) =
      updateJChars (jshorts, index, Word.fromInt jshort)

  fun subJInts (jints, index) =
      let
        val address = UM.advance (jints, index * SIZE_OF_JINT)
        val int = UM.subInt address
      in
        int
      end
  fun updateJInts (jints, index, jint) =
      let
        val address = UM.advance (jints, index * SIZE_OF_JINT)
        val _ = UM.updateInt (address, jint)
      in
        ()
      end

  local
    val (bytesToJFloat, jfloatToBytes) =
        case SMLSharp.Platform.byteOrder
         of SMLSharp.Platform.LittleEndian =>
            (PackReal32Little.fromBytes, PackReal32Little.toBytes)
          | SMLSharp.Platform.BigEndian =>
            (PackReal32Big.fromBytes, PackReal32Big.toBytes)
  in
  fun subJFloats (jfloats, index) =
      let
        val address = UM.advance (jfloats, index * SIZE_OF_JFLOAT)
        val bytes =
            Word8Vector.tabulate
                (SIZE_OF_JFLOAT, fn i => UM.sub (UM.advance (address, i)))
        val jfloat = bytesToJFloat bytes
      in
        jfloat
      end
  fun updateJFloats (jfloats, index, jfloat) =
      let
        val address = UM.advance (jfloats, index * SIZE_OF_JFLOAT)
        val bytes = jfloatToBytes jfloat
        val _ =
            Word8Vector.appi
                (fn (i, byte) => UM.update (UM.advance (address, i), byte))
                bytes
      in
        ()
      end
  end

  fun subJDoubles (jdoubles, index) =
      let
        val address = UM.advance (jdoubles, index * SIZE_OF_JDOUBLE)
        val double = UM.subReal address
      in
        double
      end
  fun updateJDoubles (jdoubles, index, jdouble) =
      let
        val address = UM.advance (jdoubles, index * SIZE_OF_JDOUBLE)
        val _ = UM.updateReal (address, jdouble)
      in
        ()
      end

  val subJLongs = subJDoubles
  val updateJLongs = updateJDoubles

  end (* end of local *)

  fun subArray
          getArrayElements
          releaseArrayElements
          JavaValueToToMLValue
          subElements
          (array, index) =
      let
        val _ =
            if (index < 0) orelse (GetArrayLength array <= index)
            then raise General.Subscript
            else ()
        val isCopy = ref (JV.boolToJBoolean false)
        val elements =
            getArrayElements (J.getJNIEnv()) (JV.objectToJObject array, isCopy)
        val _ = if UM.isNULL elements then raise Fail "NULL returned." else ()
        val v = JavaValueToToMLValue (subElements (elements, index))
        val _ =
            releaseArrayElements
                (J.getJNIEnv()) (JV.objectToJObject array, elements, 0)
      in
        v
      end

  fun updateArray
          getArrayElements
          releaseArrayElements
          MLValueToJavaValue
          updateElements
          (array, index, MLValue) =
      let
        val _ =
            if (index < 0) orelse (GetArrayLength array <= index)
            then raise General.Subscript
            else ()
        val isCopy = ref (JV.boolToJBoolean false)
        val elements =
            getArrayElements (J.getJNIEnv()) (JV.objectToJObject array, isCopy)
        val _ = if UM.isNULL elements then raise Fail "NULL returned." else ()
        val () = updateElements (elements, index, MLValueToJavaValue MLValue)
        val _ =
            releaseArrayElements
                (J.getJNIEnv()) (JV.objectToJObject array, elements, 0)
      in
        ()
      end

  val subBooleanArray =
      subArray
          #GetBooleanArrayElements
          #ReleaseBooleanArrayElements
          JV.jbooleanToBool
          subJBooleans
  val subByteArray =
      subArray
          #GetByteArrayElements
          #ReleaseByteArrayElements
          JV.jbyteToByte
          subJBytes
  val subCharArray =
      subArray
          #GetCharArrayElements
          #ReleaseCharArrayElements
          JV.jcharToChar
          subJChars
  val subShortArray =
      subArray
          #GetShortArrayElements
          #ReleaseShortArrayElements
          JV.jshortToShort
          subJShorts
  val subIntArray =
      subArray
          #GetIntArrayElements
          #ReleaseIntArrayElements
          JV.jintToInt
          subJInts
  val subLongArray =
      subArray
          #GetLongArrayElements
          #ReleaseLongArrayElements
          JV.jlongToLong
          subJLongs
  val subFloatArray =
      subArray
          #GetFloatArrayElements
          #ReleaseFloatArrayElements
          JV.jfloatToFloat
          subJFloats
  val subDoubleArray =
      subArray
          #GetDoubleArrayElements
          #ReleaseDoubleArrayElements
          JV.jdoubleToDouble
          subJDoubles

  val updateBooleanArray =
      updateArray
          #GetBooleanArrayElements
          #ReleaseBooleanArrayElements
          JV.boolToJBoolean
          updateJBooleans
  val updateByteArray =
      updateArray
          #GetByteArrayElements
          #ReleaseByteArrayElements
          JV.byteToJByte
          updateJBytes
  val updateCharArray =
      updateArray
          #GetCharArrayElements
          #ReleaseCharArrayElements
          JV.charToJChar
          updateJChars
  val updateShortArray =
      updateArray
          #GetShortArrayElements
          #ReleaseShortArrayElements
          JV.shortToJShort
          updateJShorts
  val updateIntArray =
      updateArray
          #GetIntArrayElements
          #ReleaseIntArrayElements
          JV.intToJInt
          updateJInts
  val updateLongArray =
      updateArray
          #GetLongArrayElements
          #ReleaseLongArrayElements
          JV.longToJLong
          updateJLongs
  val updateFloatArray =
      updateArray
          #GetFloatArrayElements
          #ReleaseFloatArrayElements
          JV.floatToJFloat
          updateJFloats
  val updateDoubleArray =
      updateArray
          #GetDoubleArrayElements
          #ReleaseDoubleArrayElements
          JV.doubleToJDouble
          updateJDoubles

  end (* end of local *)

end;