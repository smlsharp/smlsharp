structure StringReplacer =
struct

  local
    structure SS = Substring
  in

  (**
   *  replaces string.
   * <p>
   *  example:
   * <pre>
   * - StringReplacer.replaceString "foo" "bar" "fooboofooboofoo";
   * val it = "barboobarboobar" : string
   * </pre>
   * </p>
   * @params oldString newString string
   * @param oldString the string to be replaced
   * @param newString the string to be inserted
   * @return the string in which occurrences of <code>oldString</code> are
   *      replaced with <code>newString</code>.
   *)
  fun replaceString oldString newString string =
    let
      val oldStringSize = String.size oldString
      val newSubstring = SS.extract (newString, 0, NONE)

      fun replace (substring, substrings) =
          let val (prefix, suffix) = SS.position oldString substring
          in
            if SS.size suffix = 0
            then (prefix :: substrings)
            else
              replace
              (
                SS.triml oldStringSize suffix,
                newSubstring :: prefix :: substrings
              )
          end
    in SS.concat (rev (replace (SS.extract (string, 0, NONE), []))) end

  (**
   * replaces strings in the contents of a file.
   * This function reads the contents of the source file and replaces the
   * occurrences of the first element of a pair in the
   * <code>keyValuePairs</code> with the second element of that pair.
   * The result of replace is output to the destination file.
   *
   * @params keyValuePairs (srcFileName, destFileName)
   * @param keyValuePairs a list of pairs of oldString and newString
   * @param srcFileName the name of source file
   * @param destFileName the name of destination file
   * @return unit
   *)
  fun replaceFile keyValuePairs (srcFileName, destFileName) =
      let val inStream = TextIO.openIn srcFileName
      in
        let val outStream = TextIO.openOut destFileName
        in
          let
            val newText = 
                foldl
                (fn ((key, newString), text) =>
                    replaceString key newString text)
                (TextIO.inputAll inStream)
                keyValuePairs
            val _ = TextIO.output (outStream, newText)
          in TextIO.closeOut outStream; TextIO.closeIn inStream end
            handle e => (TextIO.closeOut outStream; raise e)
        end
          handle e => (TextIO.closeIn inStream; raise e)
      end
  end

end
