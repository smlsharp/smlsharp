(**
 * This module provides facilities for conversion between OLE DECIMAL data type
 * and SML data type.
 * <p>
 * OLE DECIMAL structure is defined as
 * <pre>
 * typedef struct tagDEC {
 *  WORD wReserved;
 *  BYTE scale;
 *  BYTE sign;
 *  ULONG Hi32;
 *  ULONGLONG Lo64;
 * } DECIMAL;
 * </pre>
 * ( http://msdn.microsoft.com/en-us/library/cc237603(PROT.13).aspx )
 * </p>
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
signature OLE_DECIMAL =
sig

  val SIZE_OF_DECIMAL : int
  
  val MIN_SCALE : Word8.word
  val MAX_SCALE : Word8.word

  (** maximum number stored in the <tt>value</tt> field of decimal. *)
  val MAX_VALUE : IntInf.int
  (** minimum number stored in the <tt>value</tt> field of decimal. *)
  val MIN_VALUE : IntInf.int

  (**
   *)
  type decimal =
       {
         (** scale must be in the range [0, 28] *)
         scale : Word8.word,
         (** between <tt>MinValue</tt> and <tt>MaxValue</tt>, including. *)
         value : IntInf.int
       }

  (** converts a decimal into the binary format which is compatible with
   * OLE DECIMAL.
   * <p>
   * Structures DECIMAL and VARIANT are the same size.
   * When a decimal is serialized as the contents embedded in a variant,
   * its first reserved 2-byte is used to store the tag VT_DECIMAL.
   * </p>
   * @params embedInVariant (stream, decimal)
   * @param embedInVariant if true, VT_DECIMAL is written in the first 2bytes.
   * @param stream an outstream
   * @param decimal a decimal
   * @param new outstream after the decimal is written.
   *)
  val export
      : bool
        -> (OLE_BufferStream.outstream * decimal)
        -> OLE_BufferStream.outstream

  (** obtains a decimal from the binary format which is compatible with
   * OLE DECIMAL. *)
  val import
      : OLE_BufferStream.instream -> (decimal * OLE_BufferStream.instream)

  val toString : decimal -> string

  val compare : decimal * decimal -> order

end;
