(**
 * Word8ArraySlice structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Word8ArraySlice.sml,v 1.1 2005/07/28 04:34:05 kiyoshiy Exp $
 *)
structure Word8ArraySlice =
          MonoArraySliceBase
              (structure A = Word8Array structure V = Word8Vector)
