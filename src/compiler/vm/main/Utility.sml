(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Utility.sml,v 1.8 2006/02/28 16:11:13 kiyoshiy Exp $
 *)
structure Utility =
struct

  local
    open BasicTypes
    structure E = Executable
    structure RT = RuntimeTypes
  in

  (****************************************)
  (* ToDo : the folloing functions should be moved to another structure
   *      adequate for Executable or instructions manipulation. *)

  fun getOpcodeAt (executable : RT.executable) address =
      let
        val offsetRef = ref(UInt32ToInt (address * BytesOfUInt32))
        fun reader () =
            Word8Array.sub (#instructionsArray executable, !offsetRef)
            before offsetRef := !offsetRef + 1
      in
        Instructions.wordToOpcode(BasicTypeSerializer.deserializeUInt32 reader)
      end

  fun setOpcodeAt (executable : RT.executable) address opcode =
      let
        val offsetRef = ref(UInt32ToInt (address * BytesOfUInt32))
        fun writer byte =
            Word8Array.update (#instructionsArray executable, !offsetRef, byte)
            before offsetRef := !offsetRef + 1
      in
        BasicTypeSerializer.serializeUInt32
            (WordToUInt32 (Instructions.opcodeToWord opcode))
            writer
      end

  fun deserializeString {string, length} = 
      BasicTypes.UInt8ListToString (List.take (string, UInt32.toInt length))

  end

end;
