(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ExecutableSerializer.sml,v 1.9 2005/12/31 12:34:00 kiyoshiy Exp $
 *)
structure ExecutableSerializer : EXECUTABLE_SERIALIZER =
struct

  (***************************************************************************)

  open BasicTypes
  structure BT = BasicTypes
  structure E = Executable
  structure BTS = BasicTypeSerializer
  structure BTSNet = BasicTypeSerializerForNetworkByteOrder

  (***************************************************************************)

  val SIZE_OF_LOCATION_TABLE_ENTRY = 0w6 : UInt32
  val SIZE_OF_NAMESLOT_TABLE_ENTRY = 0w4 : UInt32

  (***************************************************************************)

  fun serializeSequence serializer list writer =
      app (fn element => serializer element writer) list

  fun deserializeSequence deserializer count reader =
      let
        fun scan (elements, 0) = List.rev elements
          | scan (elements, count) = 
            case deserializer reader of
              element => scan (element :: elements, count - 1)
      in scan ([], count)
      end

  fun wordsOfStringLength length = 
      IntToUInt32(BT.StringLengthToPaddedUInt8ListLength (UInt32ToInt length))

  fun serializeString {length, string} writer =
      (
        BTS.serializeUInt32 length writer;
        serializeSequence BTS.serializeUInt8 string writer
      )

  fun deserializeString reader =
      let
        val bytes = BTS.deserializeUInt32 reader
        val bytesOfPadded = UInt32.toInt(wordsOfStringLength bytes) * 4
        val string =
            deserializeSequence BTS.deserializeUInt8 bytesOfPadded reader
      in {length = bytes, string = string} end

  (********************)

  fun sizeOfLocationTable (table : E.locationTable) =
      0w1 (* locationsCount *)
      + (#locationsCount table * SIZE_OF_LOCATION_TABLE_ENTRY)
      + 0w1 (* fileNamesCount *)
      + (#fileNamesCount table) (* fileNameOffsets *)
      +
      (foldl
           (fn ({length, ...}, total) =>
               total + 0w1 + wordsOfStringLength length)
           0w0
           (#fileNames table))

  local
    fun serializeTableEntry (entry : E.locationTableEntry) writer =
        (
          BTS.serializeUInt32 (#offset entry) writer;
          BTS.serializeUInt32 (#fileNameIndex entry) writer;
          BTS.serializeUInt32 (#leftLine entry) writer;
          BTS.serializeUInt32 (#leftCol entry) writer;
          BTS.serializeUInt32 (#rightLine entry) writer;
          BTS.serializeUInt32 (#rightCol entry) writer
        )

    fun deserializeTableEntry reader =
        let
          val offset = BTS.deserializeUInt32 reader
          val fileNameIndex = BTS.deserializeUInt32 reader
          val leftLine = BTS.deserializeUInt32 reader
          val leftCol = BTS.deserializeUInt32 reader
          val rightLine = BTS.deserializeUInt32 reader
          val rightCol = BTS.deserializeUInt32 reader
          val entry =
              {
                offset = offset,
                fileNameIndex = fileNameIndex,
                leftLine = leftLine,
                leftCol = leftCol,
                rightLine = rightLine,
                rightCol = rightCol
              } : E.locationTableEntry
        in entry end
  in

  fun serializeLocationTable (table : E.locationTable) writer =
      (
        BTS.serializeUInt32 (#locationsCount table) writer;
        serializeSequence serializeTableEntry (#locations table) writer;
        BTS.serializeUInt32 (#fileNamesCount table) writer;
        serializeSequence BTS.serializeUInt32 (#fileNameOffsets table) writer;
        serializeSequence serializeString (#fileNames table) writer
      )

  fun deserializeLocationTable reader =
      let
        val locationsCount = BTS.deserializeUInt32 reader
        val locations =
            deserializeSequence
                deserializeTableEntry (UInt32.toInt locationsCount) reader
        val fileNamesCount = BTS.deserializeUInt32 reader

        val fileNameOffsets =
            deserializeSequence
                BTS.deserializeUInt32 (UInt32.toInt fileNamesCount) reader
        val fileNames = 
            deserializeSequence
                deserializeString (UInt32.toInt fileNamesCount) reader
        val locationTable =
            {
              locationsCount = locationsCount,
              locations = locations,
              fileNamesCount = fileNamesCount,
              fileNameOffsets = fileNameOffsets,
              fileNames = fileNames
            } : E.locationTable
      in
        locationTable
      end

  end

  (********************)

  fun sizeOfNameSlotTable (table : E.nameSlotTable) =
      0w1 (* nameSlotsCount *)
      + ((#nameSlotsCount table) * SIZE_OF_NAMESLOT_TABLE_ENTRY)
      + 0w1 (* boundNamesCount *)
      + (#boundNamesCount table) (* boundNameOffsets *)
      +
      (foldl
           (fn ({length, ...}, total) =>
               total + 0w1 + wordsOfStringLength length)
           0w0
           (#boundNames table))

  local
    fun serializeTableEntry (entry : E.nameSlotTableEntry) writer =
        (
          BTS.serializeUInt32 (#lifeTimeBeginOffset entry) writer;
          BTS.serializeUInt32 (#lifeTimeEndOffset entry) writer;
          BTS.serializeUInt32 (#nameIndex entry) writer;
          BTS.serializeUInt32 (#slotIndex entry) writer
        )

    fun deserializeTableEntry reader =
        let
          val lifeTimeBeginOffset = BTS.deserializeUInt32 reader
          val lifeTimeEndOffset = BTS.deserializeUInt32 reader
          val nameIndex = BTS.deserializeUInt32 reader
          val slotIndex = BTS.deserializeUInt32 reader

          val entry =
              {
                lifeTimeBeginOffset = lifeTimeBeginOffset,
                lifeTimeEndOffset = lifeTimeEndOffset,
                nameIndex = nameIndex,
                slotIndex = slotIndex
              } : E.nameSlotTableEntry
        in entry end
  in

  fun serializeNameSlotTable (table : E.nameSlotTable) writer =
      (
        BTS.serializeUInt32 (#nameSlotsCount table) writer;
        serializeSequence serializeTableEntry (#nameSlots table) writer;
        BTS.serializeUInt32 (#boundNamesCount table) writer;
        serializeSequence BTS.serializeUInt32 (#boundNameOffsets table) writer;
        serializeSequence serializeString (#boundNames table) writer
      )

  fun deserializeNameSlotTable reader =
      let
        val nameSlotsCount = BTS.deserializeUInt32 reader
        val nameSlots =
            deserializeSequence
                deserializeTableEntry (UInt32.toInt nameSlotsCount) reader
        val boundNamesCount = BTS.deserializeUInt32 reader

        val boundNameOffsets =
            deserializeSequence
                BTS.deserializeUInt32 (UInt32.toInt boundNamesCount) reader
        val boundNames = 
            deserializeSequence
                deserializeString (UInt32.toInt boundNamesCount) reader
        val nameSlotTable =
            {
              nameSlotsCount = nameSlotsCount,
              nameSlots = nameSlots,
              boundNamesCount = boundNamesCount,
              boundNameOffsets = boundNameOffsets,
              boundNames = boundNames
            } : E.nameSlotTable
      in
        nameSlotTable
      end

  end

  (********************)

  fun deserialize buffer =
      let
        val bufferLength = Word8Array.length buffer
(*
val _ = print ("bufferLength: " ^ UInt32.toString (IntToUInt32 bufferLength) ^ "\n")
*)
        val pos = ref 0
        fun reader () =
            Word8Array.sub (buffer, !pos) before pos := !pos + 1

        val instructionsSize = BTS.deserializeUInt32 reader
(*
val _ = print ("instructionsSize: " ^ UInt32.toString instructionsSize ^ "\n")
*)
        val bytesOfInstructionsSize = UInt32.toInt instructionsSize * 4

        val instructionsArray = Word8Array.array (bytesOfInstructionsSize, 0w0)
        val _ =
            Word8Array.copy
                {
                  src = buffer,
                  si = !pos,
                  len = SOME bytesOfInstructionsSize,
                  dst = instructionsArray,
                  di = 0
                }
        val _ = pos := (!pos) + bytesOfInstructionsSize

        val locationTableWords = BTS.deserializeUInt32 reader
(*
val _ = print ("locationTableWords: " ^ UInt32.toString locationTableWords ^ "\n")
*)
        val locationTable = deserializeLocationTable reader

        val nameSlotTableWords = BTS.deserializeUInt32 reader
(*
val _ = print ("nameSlotTableWords: " ^ UInt32.toString nameSlotTableWords ^ "\n")
*)
        val nameSlotTable = deserializeNameSlotTable reader

        val _ =
            if !pos <> bufferLength
            then
              raise
                Fail
                    ("deserialize: deserialized = " ^ Int.toString (!pos)
                     ^ ", buffer = " ^ Int.toString (Word8Array.length buffer))
            else ()
      in
        {
          instructionsSize = instructionsSize,
          instructionsArray = instructionsArray,
          locationTable = locationTable,
          nameSlotTable = nameSlotTable
        }
      end

  fun serialize
          {instructionsSize, instructions, locationTable, nameSlotTable} =
      let
        val locationTableWords = sizeOfLocationTable locationTable
        val nameSlotTableWords = sizeOfNameSlotTable nameSlotTable

        val totalWords = 
            0w1 (* instructionSize *)
            + instructionsSize (* instructions *)
            + 0w1 (* locationTableWords *)
            + locationTableWords
            + 0w1 (* nameSlotTableWords *)
            + nameSlotTableWords
        val totalBytes = totalWords * 0w4

        val buffer = Word8Array.array (UInt32.toInt totalBytes, 0w0 : UInt8)
        val pos = ref 0
        fun writer byte =
            Word8Array.update (buffer, !pos, byte) before pos := !pos + 1

        (* instructions *)
(*
val _ = print ("totalWords: " ^ UInt32.toString totalWords ^ "\n")
val _ = print ("instructionsSize: " ^ UInt32.toString instructionsSize ^ "\n")
*)
        val _ = BTS.serializeUInt32 instructionsSize writer
        val _ = InstructionSerializer.serialize instructions writer
        val _ =
            if !pos <> (UInt32.toInt instructionsSize * 4) + 4
            then
              raise
                Fail
                    ("serialize: serialized = " ^ Int.toString (!pos)
                     ^ ", instsize = "
                     ^ Int.toString (UInt32.toInt instructionsSize))
            else ()

        (* location table *)
        val _ = BTS.serializeUInt32 locationTableWords writer
(*
val _ = print ("locationTableWords: " ^ UInt32.toString locationTableWords ^ "\n")
*)
        val _ = serializeLocationTable locationTable writer

        (* nameSlot table *)
        val _ = BTS.serializeUInt32 nameSlotTableWords writer
(*
val _ = print ("nameSlotTableWords: " ^ UInt32.toString nameSlotTableWords ^ "\n")
*)
        val _ = serializeNameSlotTable nameSlotTable writer

        val _ =
            if !pos <> UInt32.toInt totalBytes
            then
              raise
                Fail
                    ("serialize: serialized = "
                     ^ Int.toString (!pos) ^
                     ", buffer = " ^ Int.toString (UInt32.toInt totalBytes))
            else ()
      in
        buffer
      end

  (***************************************************************************)

end;
