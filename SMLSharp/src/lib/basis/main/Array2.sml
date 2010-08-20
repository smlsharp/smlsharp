(**
 * Array2 structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Array2 : ARRAY2 =
struct

  (***************************************************************************)

  structure A = Array

  (***************************************************************************)

  (**
   * elements are stored in the row-major order in the base array.
   * The element at (iRow, iCol) in an nRows x nCols array is stored at the
   * offset (iRow * nCols + iCol) in the base array.
   *)
  type 'a array = 'a Array.array * (** nRows *) int * (** nCols *) int

  type 'a region =
       {
	 base : 'a array,
	 row : int, col : int,
	 nrows : int option,
         ncols : int option
      }

  (**
   * canonicalized form of region for internal use.
   * The region includes elements at (row, col) where
   *   startRow <= row < endRow
   *   startCol <= col < endCol.
   *)
  type 'a internal_region =
        {
          array : 'a Array.array,
          nRows : int,
          nCols : int,
          startRow : int,
          startCol : int,
          endRow : int,
          endCol : int
        }

  datatype traversal = RowMajor | ColMajor

  (***************************************************************************)

  fun emptyArray () = A.tabulate (0, fn _ => raise Fail "bug")

  (* check that the region is valid, and translates it into its internal form.
   *)
  fun checkRegion {base = (array, nRows, nCols), row, col, nrows, ncols} =
      if
        row < 0
        orelse col < 0
        orelse nRows < row
        orelse nCols < col
        orelse (isSome nrows
                andalso (valOf nrows < 0 orelse nRows < row + valOf nrows))
        orelse (isSome ncols
                andalso (valOf ncols < 0 orelse nCols < col + valOf ncols))
      then raise General.Subscript
      else
        {
          array = array,
          nRows = nRows,
          nCols = nCols,
          startRow = row,
          startCol = col,
          endRow = case nrows of NONE => nRows | SOME nrows => row + nrows,
          endCol = case ncols of NONE => nCols | SOME ncols => col + ncols
        } : 'a internal_region

  fun array (nRows, nCols, init) =
      let val size = nRows * nCols
      in
        if nRows < 0 orelse nCols < 0 orelse A.maxLen < size
        then raise General.Size
        else (A.array (nRows * nCols, init), nRows, nCols)
      end

  fun fromList elements =
      let
        val nRows = List.length elements
        (* get the length of the first row. *)
        val nCols = case elements of [] => 0 | row :: _ => List.length row
        val size = nRows * nCols
        val array =
            if A.maxLen < size then raise General.Size
            else if size = 0 then emptyArray ()
            else A.array (size, hd (hd elements))
        (* write elements in row-major order.
         * raise Size if any row has more or less elements than the first row.
         *)
        fun writeRows _ [] = ()
          | writeRows offset (row :: rows) =
            let
              fun writeCols iCol [] =
                  if nCols <> iCol then raise General.Size else ()
                | writeCols iCol (col :: cols) =
                  if nCols = iCol
                  then raise General.Size
                  else
                    (
                      A.update (array, offset + iCol, col);
                      writeCols (iCol + 1) cols
                    )
              val () = writeCols 0 row
            in
              writeRows (offset + nCols) rows
            end
      in
        writeRows 0 elements; (array, nRows, nCols)
      end

  fun sub ((array, nRows, nCols), iRow, iCol) =
      if iRow < 0 orelse iCol < 0 orelse nRows <= iRow orelse nCols <= iCol
      then raise General.Subscript
      else A.sub (array, iRow * nCols + iCol)

  fun update ((array, nRows, nCols), iRow, iCol, newElem) =
      if iRow < 0 orelse iCol < 0 orelse nRows <= iRow orelse nCols <= iCol
      then raise General.Subscript
      else A.update (array, iRow * nCols + iCol, newElem)

  fun dimensions (_, nRows, nCols) = (nRows, nCols)

  fun nCols (_, _, n) = n

  fun nRows (_, n, _) = n

  fun row ((array, nRows, nCols), iRow) =
      if iRow < 0 orelse nRows <= iRow
      then raise General.Subscript
      else
        Vector.tabulate (nCols, fn iCol => A.sub (array, iRow * nCols + iCol))

  fun column ((array, nRows, nCols), iCol) =
      if iCol < 0 orelse nCols <= iCol
      then raise General.Subscript
      else
        Vector.tabulate (nRows, fn iRow => A.sub (array, iRow * nCols + iCol))

  fun copy {src, dst, dst_row, dst_col} =
      let
        val src_region = checkRegion src
        val nRowsOfRegion = #endRow src_region - #startRow src_region
        val nColsOfRegion = #endCol src_region - #startCol src_region
        (* src_region and dst_region have the same size. *)
        val dst_region = checkRegion
                             {
                               base = dst,
                               row = dst_row,
                               col = dst_col,
                               nrows = SOME nRowsOfRegion,
                               ncols = SOME nColsOfRegion
                             }

        fun srcOffset (iRow, iCol) = iRow * #nCols src_region + iCol
        fun dstOffset (iRow, iCol) = iRow * #nCols dst_region + iCol

        (* copy elements of columns in a row from left to right. *)
        fun copyColsFromLeft srcRow dstRow =
            let
              fun copyCols srcCol dstCol =
                  if srcCol = #endCol src_region
                  then ()
                  else
                    let
                      val srcOffset = srcOffset (srcRow, srcCol)
                      val dstOffset = dstOffset (dstRow, dstCol)
                      val elem = A.sub (#array src_region, srcOffset)
                      val () = A.update (#array dst_region, dstOffset, elem)
                    in
                      copyCols (srcCol + 1) (dstCol + 1)
                    end
            in copyCols (#startCol src_region) (#startCol dst_region)
            end
        (* copy elements of columns in a row from right to left. *)
        fun copyColsFromRight srcRow dstRow =
            let
              (* NOTE: the region copied includes startCol, but not endCol. *)
              fun copyCols srcCol dstCol =
                  if srcCol = #startCol src_region - 1
                  then ()
                  else
                    let
                      val srcOffset = srcOffset (srcRow, srcCol)
                      val dstOffset = dstOffset (dstRow, dstCol)
                      val elem = A.sub (#array src_region, srcOffset)
                      val () = A.update (#array dst_region, dstOffset, elem)
                    in
                      copyCols (srcCol - 1) (dstCol - 1)
                    end
            in copyCols (#endCol src_region - 1) (#endCol dst_region - 1)
            end
        (* take care about cases where src_region and dst_region overlap
         * in the same array.
         *)
        val copyCols =
            if #startCol src_region < #startCol dst_region
            then copyColsFromRight
            else copyColsFromLeft
        (* copy rows from top to bottom. *)
        fun copyRowsFromTop () =
            let
              fun copyRows srcRow dstRow =
                  if srcRow = #endRow src_region
                  then ()
                  else
                    (
                      copyCols srcRow dstRow;
                      copyRows (srcRow + 1) (dstRow + 1)
                    )
            in copyRows (#startRow src_region) (#startRow dst_region)
            end
        (* copy rows from bottom to top. *)
        fun copyRowsFromBottom () =
            let
              fun copyRows srcRow dstRow =
                  if srcRow = #startRow src_region - 1
                  then ()
                  else
                    (
                      copyCols srcRow dstRow;
                      copyRows (srcRow - 1) (dstRow - 1)
                    )
            in copyRows (#endRow src_region - 1) (#endRow dst_region - 1)
            end
        val copyRows =
            if #startRow src_region < #startRow dst_region
            then copyRowsFromBottom
            else copyRowsFromTop
      in
        copyRows ()
      end

  (* implementation of foldi for RowMajor order *)
  fun foldiRM
        folder init {array, nRows, nCols, startRow, startCol, endRow, endCol} =
      let
        fun f accum iRow iCol =
            if iRow = endRow
            then accum
            else if iCol = endCol
            then f accum (iRow + 1) startCol
            else
              let val elem = A.sub (array, iRow * nCols + iCol)
              in f (folder (iRow, iCol, elem, accum)) iRow (iCol + 1) end
      in f init startRow startCol
      end
      
  (* implementation of foldi for ColMajor order *)
  fun foldiCM
        folder init {array, nRows, nCols, startRow, startCol, endRow, endCol} =
      let
        fun f accum iRow iCol =
            if iCol = endCol
            then accum
            else if iRow = endRow
            then f accum startRow (iCol + 1)
            else
              let val elem = A.sub (array, iRow * nCols + iCol)
              in f (folder (iRow, iCol, elem, accum)) (iRow + 1) iCol end
      in f init startRow startCol
      end

  fun foldi order folder init region =
      let val region = checkRegion region
      in
        case order of
          RowMajor => foldiRM folder init region
        | ColMajor => foldiCM folder init region
      end

  fun fold order folder init array =
      foldi
          order
          (fn (_, _, elem, accum) => folder (elem, accum))
          init 
          {base = array, row = 0, col = 0, nrows = NONE, ncols = NONE}

  fun modifyi order modifier (region as {base = (array, nRows, nCols), ...}) = 
      foldi
          order
          (fn (iRow, iCol, elem, _) =>
              A.update
                  (array, iRow * nCols + iCol, modifier (iRow, iCol, elem)))
          ()
          region

  fun modify order modifier array =
      let
        val region =
            {base = array, row = 0, col = 0, nrows = NONE, ncols = NONE}
      in
        modifyi order (modifier o #3) region
      end

  fun appi order apper region =
      foldi
          order
          (fn (iRow, iCol, elem, _) => apper (iRow, iCol, elem))
          ()
          region

  fun app order apper array =
      let
        val region =
            {base = array, row = 0, col = 0, nrows = NONE, ncols = NONE}
      in
        appi order (apper o #3) region
      end

  fun tabulate order (nRows, 0, _) = (emptyArray(), nRows, 0)
    | tabulate order (0, nCols, _) = (emptyArray(), 0, nCols)
    | tabulate order (nRows, nCols, generator) = 
      let
        val () = if nRows < 0 orelse nCols < 0 then raise General.Size else ()
        val size = nRows * nCols
        val firstElem = generator (0, 0)
        val array =
            if A.maxLen < size
            then raise General.Size
            else A.array (size, firstElem)
        fun modifier (0, 0, _) = firstElem
          | modifier (iRow, iCol, _) = generator (iRow, iCol)
        val region =
            {
              base = (array, nRows, nCols),
              row = 0,
              col = 0,
              nrows = NONE,
              ncols = NONE
            }
        val () = modifyi order modifier region
      in (array, nRows, nCols)
      end

  (***************************************************************************)

end