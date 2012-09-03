(**
 * IntArraySlice structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IntArraySlice.sml,v 1.2 2005/07/28 04:34:04 kiyoshiy Exp $
 *)
structure IntArraySlice =
          MonoArraySliceBase(structure A = IntArray structure V = IntVector);
