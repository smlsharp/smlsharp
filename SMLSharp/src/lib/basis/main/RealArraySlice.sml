(**
 * RealArraySlice structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: RealArraySlice.sml,v 1.1 2005/12/18 12:58:09 kiyoshiy Exp $
 *)
structure RealArraySlice =
          MonoArraySliceBase(structure A = RealArray structure V = RealVector)
