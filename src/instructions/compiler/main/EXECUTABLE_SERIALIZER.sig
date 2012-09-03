(**
 *  This signature specifies the interface of modules which provides
 * functionity of translating an executable in ML datatype form to a byte
 * array.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: EXECUTABLE_SERIALIZER.sig,v 1.3 2005/10/22 14:46:33 kiyoshiy Exp $
 *)
signature EXECUTABLE_SERIALIZER =
sig

  (***************************************************************************)

  (**
   *  Translates an executable into the binary form.
   *
   * @params executable
   * @param executable an executable
   * @return a byte array whose contents is the executable in the binary
   *                     form.
   *)
  val serialize : Executable.executable -> Word8Array.array

  (**
   * This function is provided for VM emulator.
   *)
  val deserialize :
      Word8Array.array
      -> {
           instructionsSize: BasicTypes.UInt32,
           instructionsArray : Word8Array.array,
           locationTable : Executable.locationTable,
           nameSlotTable : Executable.nameSlotTable
         }

  (***************************************************************************)

end
