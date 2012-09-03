(**
 * Properties of Target Platform.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: TargetProperty.sml,v 1.2 2008/01/23 08:20:07 katsu Exp $
 *)

functor TargetProperty(Target : TARGET_PLATFORM) : TARGET_PROPERTY =
struct

  open Target

  fun ceilTo (x, y) =
      (x + y - 0w1) - (x + y - 0w1) mod y

  fun gcd (m, 0w0) = m
    | gcd (m, n) = gcd (n, m mod n)

  fun lcm (m, n) = (m * n) div gcd (m, n)

  fun log2 n =
      Word.fromInt (ceil (Math.ln (real (Word.toInt n)) / Math.ln 2.0))

  fun min [h] = h : word
    | min (h::t) = let val x = min t in if h < x then h else x end
    | min nil = raise Control.Bug "min"

  fun max (h::t) = let val x = max t in if h > x then h else x end
    | max nil = 0w0

  fun uniq nil = nil : word list
    | uniq (h::t) = case List.find (fn x => x = h) t of
                       SOME _ => t | NONE => h::t


  val basicSize = min [C_sizeOfInt, C_sizeOfPtr, C_sizeOfReal]

  fun size_align (c_size, c_align) =
      let
        val _ = if c_size < c_align
                then raise Control.Bug "size < align"
                else ()
        val size = ceilTo (c_size, basicSize) div basicSize
        val align = lcm (c_align, basicSize) div basicSize
      in
        (max [size, align], align)
      end

  val (sizeOfInt,   alignOfInt)   = size_align (C_sizeOfInt,   C_alignOfInt)
  val (sizeOfPtr,   alignOfPtr)   = size_align (C_sizeOfPtr,   C_alignOfPtr)
  val (sizeOfReal,  alignOfReal)  = size_align (C_sizeOfReal,  C_alignOfReal)
  val (sizeOfFloat, alignOfFloat) = size_align (C_sizeOfFloat, C_alignOfFloat)



  val sizeVariation =
      ListSorter.sort Word.compare (uniq [sizeOfInt, sizeOfPtr, sizeOfReal])

  local
    val types = [(sizeOfInt, alignOfInt),
                 (sizeOfPtr, alignOfPtr),
                 (sizeOfReal, alignOfReal)]
    fun alignOfSize size =
        foldl lcm 0w1 (map #2 (List.filter (fn (s,_) => s = size) types))
  in

  val alignVariation =
      map alignOfSize sizeVariation

  end


  val maxSize = max [sizeOfInt, sizeOfPtr, sizeOfReal, sizeOfFloat]
  val maxAlign = foldl lcm alignOfInt [alignOfPtr, alignOfReal, alignOfFloat]



(*
  val maxBlockFields = C_integerBits - 0w1
  val nestedBlockIndex = intToUInt 0





  val bitmapSize = C_integerBits






  (*
   * -- Structure of Block Header
   *
   *   int: |3----+----2----+----1----+----|
   *        <-A-><------------B------------>
   *
   *        A (5bit)  : size of block
   *        B (27bit) : bitmap of block
   *
   *


   * bitmap for 1 word slots
   *
   *   int: |3----+----2----+----1----+----|
   *        <-A>1<------------B------------>
   *
   *        A (4bit)  : number of 1 word slots (1,3,5,...,25,27)
   *        B (27bit) : bitmap of block
   *


   * bitmap for max word slots
   *
   *   int: |3----+----2----+----1----+----|
   *        <-A>0x<-----------B------------>
   *
   *        Ax (5bit)  : number of max word slots (1-26)
   *        B (26bit) : bitmap of block


   












   *   int: |3----+----2----+----1----+----|
   *        <-A>0<B-><---C----><----D------>

A: number of D
B: number of C



(32 - log2(32)) / 2 = 13
32 - (32 - log2(32)) - (32 - log2(32)) / 2 = 32 - 5 - 13 = 14
14 - log2(14) / 2 = 5


   *
   * bitmap for max word slots and boxed 1 word slots
   * bitmap for max word slots and 1 word slots
   *
   *
                         |
   *
   *
   * -- Layout of Stack Frame
   *
   * alignOfHeader       maxAlign                 maxAlign alignOfInt
   *     |                  |                        |        |
   *     |[header] |[ ] ... |[ ] ...    |[ ] ... [ ] |[ ] ... |[header] [ ] ...
   *     |         |        |           |            |        |
   *     |<-head-->|<--N1-->|<-maxSize->|            |<--N2-->|
   *     |<--headerOffset-->|                        |        |
   *     |         |        |<-----spaceForArgs----->|        |
   *     |         |                                          |
   *     |         |<---------------blockSize---------------->|
   *     |                                                    |
   *     |<--------------------- a block -------------------->|<-- a block --
   *     |
   *     |<--------------------------- a frame -----------------------
   *     ^
   *   FramePointer
   *
   * assumption: maxAlign mod alignOfHeader = 0
   * N1 should be as small as possible for efficient bitmap computation.
   *
   * N1 = min(alignOfHeader, maxAlign) - sizeOfHeader
   * blockHeaderOffset = sizeOfHeader + N1
   * N2 = ceilTo(blockHeaderOffset, maxAlign) - blockHeaderOffset
   *
   * maxSpaceForArgs = N - N mod maxAlign
   *         where N = frameBitmapSize - N1 - N2
   * maxNumArgsPerBlock = maxSpaceForArgs / maxSize
   * constraint: maxNumArgsPerBlock > 0
   *
   * blockPadding = N1 + N2
   * maxBlockSize = N1 + maxSpaceForArgs + N2
   * blockSize(x) = blockPadding + x * maxAlign
   *)

  val frameBitmapSize = C_integerBits - log2 (C_integerBits - 0w1)
  val sizeOfHeader = sizeOfInt
  val alignOfHeader = alignOfInt

  val padHead = min [alignOfHeader, maxAlign] - sizeOfHeader
  val blockHeaderOffset = sizeOfHeader + padHead
  val padTail = ceilTo (blockHeaderOffset, maxAlign) - blockHeaderOffset

  val maxSlots = frameBitmapSize - padHead - padTail
  val maxSpaceForArgs = maxSlots - maxSlots mod maxAlign
  val maxNumArgsPerBlock = maxSpaceForArgs div maxSize
  val _ = if maxNumArgsPerBlock > 0w0 then ()
          else raise Control.Bug "ASSERT: maxNumArgsPerBlock > 0"

  val blockPadding = padHead + padTail
  val maxBlockSize = blockPadding + maxSpaceForArgs
*)


end
