structure ProcessRequireFile =
struct
  exception SKIP
  fun fileReplace (contents, s) =
      let
        val contentList = String.fields (fn x => x = #"\n") contents
        fun isRequire s =
            let
              val tokens = String.tokens Char.isSpace s
            in
              case tokens of 
                nil => false
              | h::t => h = "_require" 
            end
        fun isUse s =
            let
              val tokens = String.tokens Char.isSpace s
            in
              case tokens of 
                nil => false
              | h::t => h = "_use" 
            end
        fun findLastRequire lines =
            foldl 
              (fn (s,(i,n)) => if isRequire s then (i+1,i+1) 
                               else if isUse s then raise SKIP
                               else (i+1,n))
            (0,~1)
            lines
        val (lines, lastRequire) = findLastRequire contentList
        fun insertCommentEnd (first, t, 0) = 
            first ^ "SML#REF*)\n" ^ (String.concatWith "\n" t)
          | insertCommentEnd (first, h::t, n) = insertCommentEnd (first ^ h ^ "\n", t, n - 1)
          | insertCommentEnd (first, nil, n) = raise Fail "impossible"
        val newContent = 
            if lastRequire = ~1 then String.concatWith "\n" contentList
            else
              s ^ "\n(*SML#REF\n" ^ insertCommentEnd ("", contentList, lastRequire)
      in 
        newContent
      end
  fun mkBackUpName fileName = 
      let
        val {base, ext} = OS.Path.splitBaseExt fileName
      in
        OS.Path.joinBaseExt {base = base ^ "ORG", ext = ext}
      end
  fun backUp fileName =
      let
        val file = TextIO.openIn fileName
        val contents = TextIO.inputAll file
        val _ = TextIO.closeIn file
        val backUpFile = TextIO.openOut (mkBackUpName fileName)
        val _ = TextIO.output (backUpFile, contents)
        val _ = TextIO.closeOut backUpFile
      in
        ()
      end

  fun replaceInteraceFile (fileName, prefix) =
      let
        val filePath = 
            OS.Path.mkAbsolute
              {path = fileName, relativeTo = !Config.baseDir}
        val _ = backUp filePath
        val file = TextIO.openIn filePath
        val contents = TextIO.inputAll file
        val _ = TextIO.closeIn file
        val newContents = fileReplace (contents, prefix)
        val file = TextIO.openOut filePath
        val _ = TextIO.output (file, newContents)
        val _ = TextIO.closeOut file
      in
        ()
      end
      handle SKIP => ()
end
