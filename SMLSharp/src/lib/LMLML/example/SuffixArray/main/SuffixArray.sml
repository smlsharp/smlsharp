(**
 * an implementation of full text search by using suffix array.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SuffixArray.sml,v 1.1 2006/12/11 11:01:53 kiyoshiy Exp $
 *)
structure SuffixArray
  : sig

      (**
       * Search in a text file for suffixes of which prefixes match with the
       * specified key.
       * An index file is created if it does not exist or is obsolete.
       * @params codec textFile key
       * @param code codec name
       * @param textFile name of text file
       * @param key search key
       * @return a list of pairs of index and suffix matching with the key
       *)
      val find
          : string
            -> string
            -> string
            -> (int * MBSubstring.substring) list

      val main : string * string list -> OS.Process.status

    end =
struct

  structure MBS = MultiByteString.String
  structure MBSS = MBSubstring
  structure MBC = MultiByteString.Char

  structure SuffixSetKey =
  struct
    type ord_key = int * MBSS.substring
    fun compare ((_, mbs1), (_, mbs2)) = MBSS.compare (mbs1, mbs2)
  end
  structure SuffixSet = BinarySetFn(SuffixSetKey)

  (**
   * An alternative implementation of BinIO.inputAll.
   * We implement by ourselves, because BinIO.inputAll aborts on Windows.
   *)
  fun inputAll instream =
      let
        fun untilEOF vectors =
            let val vector = BinIO.input instream
            in
              if 0 < Word8Vector.length vector
              then untilEOF (vector :: vectors)
              else Word8Vector.concat (List.rev vectors)
            end
      in
        untilEOF []
      end

  fun readMBSFile fileName =
      let
        val instream = BinIO.openIn fileName
        val bytes = inputAll instream
        val _ = BinIO.closeIn instream
        val mbs = MBS.fromBytes bytes
      in
        mbs
      end

  (**
   * returns a list of suffixes which begin from each characters in a MBS.
   *)
  fun getSuffixes mbs =
      let
        val mbss = MBSS.full mbs
        fun collect remain arrays =
            case MBSS.getc remain
             of NONE =>
                (* not include 'remain' in the result because it's empty. *)
                List.rev arrays
              | SOME(_, remain') => collect remain' (remain :: arrays)
      in
        collect mbss [mbss]
      end

  (**
   * sort a suffixes list.
   *)
  fun sortSuffixList suffixes =
      let
        fun offsetOfMBSS mbss = case MBSS.base mbss of (_, offset, _) => offset
        val suffixAndOffsets = 
            map (fn mbss => (offsetOfMBSS mbss, mbss)) suffixes
        val set = SuffixSet.addList(SuffixSet.empty, suffixAndOffsets)
      in
        SuffixSet.listItems set
      end

  (**
   * rebuild a suffix list from a base text and indexes of characters in the
   * text from which suffixes begin.
   *)
  fun restoreSuffixList (mbs, indexes) =
      List.map
          (fn index => (index, MBSS.extract (mbs, index, NONE)))
          indexes

  (**
   * search in a suffix array for suffixes whose prefixes match with the key.
   *)
  fun search suffixArray key =
      let
        val keyMbss = MBSS.full key
        val keySize = MBS.size key

        (**
         * returns EQUAL if prefix of the text matches with the key.
         * It returns EQUAL, even if the text is longer than the key.
         *)
        fun comparePrefix text =
            let
              val text' =
                  MBSS.slice
                      (text, 0, SOME(Int.min(keySize, MBSS.size text)))
            in
              MBSS.compare (keyMbss, text')
            end

        fun collectSiblings index =
            let
              (** returns SOME if an element at i matches with the key *)
              fun isEqualSibling i =
                  let val element as (_, suffix) = Vector.sub(suffixArray, i)
                  in
                    if General.EQUAL = comparePrefix suffix
                    then SOME element
                    else NONE
                  end
              fun collectLeft i siblings =
                  if 0 <= i
                  then
                    case isEqualSibling i
                     of SOME sibling =>
                        collectLeft (i - 1) (sibling :: siblings)
                    | _ => List.rev siblings
                  else List.rev siblings
              fun collectRight i siblings =
                  if i < Vector.length suffixArray
                  then 
                    case isEqualSibling i
                     of SOME sibling =>
                        collectRight (i + 1) (sibling :: siblings)
                      | _ => List.rev siblings
                  else List.rev siblings
            in
              (collectLeft (index - 1) [], collectRight (index + 1) [])
            end

        (**
         * search matching suffixes in a range of the suffix array between
         * left and right, excluding right.
         *)
        fun binSearch (left, right) =
            if left = right
            then []
            else
              let
                val center = (left + right) div 2
                val element as (_, suffix) = Vector.sub(suffixArray, center)
              in
                case comparePrefix suffix
                 of General.LESS => binSearch (left, center)
                  | General.EQUAL =>
                    let val (lefts, rights) = collectSiblings center
                    in lefts @ [element] @ rights end
                  | General.GREATER => binSearch (center, right)
            end
      in
        binSearch (0, Vector.length suffixArray)
      end

  local
    open Word32
    val W32 = Word8.toLargeWord
    val W8 = Word8.fromLargeWord
    infix << >> andb orb

    fun writeWord32 outstream word32 =
        (
          BinIO.output1 (outstream, W8(word32));
          BinIO.output1 (outstream, W8(word32 >> 0w8));
          BinIO.output1 (outstream, W8(word32 >> 0w16));
          BinIO.output1 (outstream, W8(word32 >> 0w24));
          ()
        )
    fun readWord32 instream =
        let val bytes = BinIO.inputN (instream, 4)
        in
          if Word8Vector.length bytes = 4
          then
            SOME
                (W32(Word8Vector.sub(bytes, 0))
                 orb (W32(Word8Vector.sub(bytes, 1)) << 0w8)
                 orb (W32(Word8Vector.sub(bytes, 2)) << 0w16)
                 orb (W32(Word8Vector.sub(bytes, 2)) << 0w24))
          else NONE
        end          
  in

  fun writeIntList outFileName ints = 
      let
        fun write outstream int = writeWord32 outstream (Word32.fromInt int)
        val outstream = BinIO.openOut outFileName
        val _ = List.app (write outstream) ints
        val _ = BinIO.closeOut outstream
      in
        ()
      end

  fun readIntList arrayFileName =
      let
        val instream = BinIO.openIn arrayFileName
        fun reads ints =
            case readWord32 instream
              of NONE => List.rev ints
               | SOME int => reads (Word32.toInt int :: ints)
        val indexes = reads []
        val _ = BinIO.closeIn instream
      in
        indexes
      end

  end

  (** make a name of index file for a text file. *)
  fun arrayFileNameOf textFileName codec = textFileName ^ ".suf" ^ "." ^ codec

  (**
   * create a new suffix array for a text file, and write it to a new index
   * file.
   *)
  fun generate codec textFileName outFileName =
      let
        val contents = readMBSFile textFileName
        val suffixes = getSuffixes contents
        val suffixList = sortSuffixList suffixes
        val indexList = List.map #1 suffixList
        val _ = writeIntList outFileName indexList
      in
        suffixList
      end

  (**
   * restore a suffix array from an existing index file.
   *)
  fun restore codec textFileName arrayFileName =
      let
        val contents = readMBSFile textFileName
        val indexes = readIntList arrayFileName
        val suffixList = restoreSuffixList (contents, indexes)
      in
        suffixList
      end

  (**
   * main interface.
   *)
  fun find codec textFileName key =
      let
        val _ = MultiByteString.setDefaultCodecName codec
        val textFileModTime = OS.FileSys.modTime textFileName

        val keyMBS = MBS.fromString key

        val indexFileName = arrayFileNameOf textFileName codec
        val indexFileExists =
            (case OS.FileSys.modTime indexFileName
              of indexFileModTime => Time.<(textFileModTime, indexFileModTime))
            handle OS.SysErr _ => false
        val suffixList =
            if indexFileExists
            then restore codec textFileName indexFileName
            else generate codec textFileName indexFileName

        val suffixArray = Vector.fromList suffixList
      in
        search suffixArray keyMBS
      end

  (**
   * an export entry for SMLofNJ.exportFn.
   *)
  fun main (commandName, [codec, textFileName, key]) =
      let
        fun showResult (index, suffix) =
            let
              val suffixSize = MBSS.size suffix
            in
              print
                  (Int.toString index
                   ^ ": "
                   ^ (MBS.toString o MBSS.string o MBSS.slice)
                         (suffix, 0, SOME(Int.min(suffixSize, 40)))
                   ^ "\n")
            end
        val results = find codec textFileName key
      in
        app showResult results;
        OS.Process.success
      end

end;
