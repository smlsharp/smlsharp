structure Word =
  struct

    (* No error occurs if the next line is removed. *)
    structure W = struct end

    type word = word
    fun toLargeWord word = word
  end;
  structure LargeWord = Word;

  signature WORD =
  sig
    eqtype  word
    val toLargeWord : word -> LargeWord.word
  end;
  structure LargeWord = Word :> WORD;
  structure Word = Word :> WORD where type word = word;

  val toLargeWord_0 = Word.toLargeWord 0w0;
