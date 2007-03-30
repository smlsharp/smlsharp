LMLML sample: full text search by SuffixArray.

This sample is an implementation of full text search by using SuffixArray.

The main interface is SuffixArray structure.
Its 'main' function is an entry point for SMLofNJ.exportFn.
For programming use, the 'find' function is available.

      val find
          : string
            -> string
            -> string
            -> (int * MultiByteString.Substring.substring) list

It takes 3 arguments: codec name, file name, search key.
For example, search for occurrences of "Œ•" in ../example/sjis.txt which is encoded in Shift_JIS encoding.

  SuffixArray.find "Shift_JIS" "../example/sjis.txt" "Œ•";

Its result indicates that it found one occurrence which begins at the 6th character in the file.

  val it = [(6,-)] : (int * substring) list

To show the matched substring, 

  print 
   (MultiByteString.String.toString
     (MultiByteString.Substring.string (#2(hd it))));

The output is:

  Œ•“¹def
