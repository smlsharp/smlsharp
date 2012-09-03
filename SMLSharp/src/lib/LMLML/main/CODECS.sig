(**
 * This signature spacifies the interface of the <code>Codecs</code> structure.
 * 
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: CODECS.sig,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
signature CODECS =
sig

  type methods

  type char
  type string

  type buffer = Word8VectorSlice.slice

  (**
   * indicates failure of decoding due to malformed byte sequence.
   *)
  exception BadFormat

  (**
   * indicates that two cursors on different byte array or two characters of
   * different encodings are compared.
   *)
  exception Unordered

  (**
   * indicates no codec of the specified name is available.
   *)
  exception UnknownCodec

  exception ConverterNotFound

  (**
   * add a codec to the codec registry.
   * @params (names, cursorMaker)
   * @param names a list of codec name and aliases.
   * @param cursorMaker a function which creates a cursor from at a stream.
   *)
  val registerCodec : (String.string list * methods) -> unit

  (**
   * search for a codec of the specified name.
   * @params name
   * @param name codec name. It should be included in the list obtained by
   *            getCodecNames.
   * @return a function which creates a cursor of the codec from at a stream.
   *)
  val findCodec : String.string -> methods option

  (**
   * returns a list of registered codec names.
   *)
  val getCodecNames : unit -> String.string list

  (**
   * indicates if two names are aliases of the same codec.
   * @params (name1, name2)
   * @param name1 the name of codec
   * @param name2 possible aliase of the codec
   * @return true if name2 is an aliase of the codec of name1.
   * @exception UnknownCodec if name1 is not found in registered codec names.
   *)
  val isAliaseOfCodec : String.string * String.string -> bool

end
