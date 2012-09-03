(**
 *  This signature specifies the interface of modules which provides
 * functionity of translating an executable in ML datatype form to a byte
 * array.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: EXECUTABLE_SERIALIZER.sig,v 1.5 2007/02/19 04:06:09 kiyoshiy Exp $
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
  val serialize : Executable.executable -> Word8Vector.vector

  (**
   * This function is provided for VM emulator.
   *)
  val deserialize :
      Word8Vector.vector
      -> {
           byteOrder : SystemDefTypes.byteOrder,
           instructionsSize: BasicTypes.UInt32,
           instructionsArray : Word8Array.array,
           locationTable : Executable.locationTable,
           nameSlotTable : Executable.nameSlotTable
         }

  (***************************************************************************)

end
