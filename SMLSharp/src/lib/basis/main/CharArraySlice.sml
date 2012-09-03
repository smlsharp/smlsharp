(**
 * CharArraySlice structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharArraySlice.sml,v 1.1 2005/07/28 04:34:04 kiyoshiy Exp $
 *)
structure CharArraySlice =
          MonoArraySliceBase(structure A = CharArray structure V = CharVector);
