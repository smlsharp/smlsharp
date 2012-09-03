(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: CMFileParser.sml,v 1.4 2007/09/19 05:28:55 matsu Exp $
 *)
structure CMFileParser : CMFILE_PARSER =
struct

  (***************************************************************************)

  local

    structure SP = SourcePath

    structure CMLrVals =
    CMLrValsFun(structure Token = LrParser.Token)
    structure CMLexer =
    CMLexFun(structure Tokens = CMLrVals.Tokens)
    structure CMParser =
    JoinWithArg(structure ParserData = CMLrVals.ParserData
	        structure Lex = CMLexer
	        structure LrParser = LrParser)

    (*************************************************************************)

    exception ParseError

    fun warn message = TextIO.output (TextIO.stdErr, message ^ "\n")

    fun getSpecOfPathName (CMSemantic.NativePathName pathName) = pathName
      | getSpecOfPathName (CMSemantic.StandardPathName pathName) = pathName

    fun parseCMFile fileName =
        let
          type pos = int

          val sourceStream = TextIO.openIn fileName
          val parserOperations = ParserUtil.PositionMap.create fileName

          fun onParseError arg =
              (print(#makeMessage parserOperations arg); raise ParseError)

          (* Build the argument for the lexer; the lexer's local
           * state is encapsulated here to make sure the parser
           * is re-entrant. *)
          val initialArg =
              let
                (* local state *)
                val depth = ref 0
                val curstring = ref []
                val startpos = ref 0
                val instring = ref false
                (* handling comments *)
                fun enterC () = depth := !depth + 1
                fun leaveC () = let val d = !depth - 1 in depth := d; d = 0 end
                (* handling strings *)
                fun newS pos =
                    (
                      instring := true;
                      curstring := [];
                      startpos := pos
                    )
                fun addS c = curstring := c :: !curstring
                fun addSC (s, offs) =
                    addS (chr (ord (String.sub (s, 2)) - offs))
                fun addSN (s, pos) =
                    let
                      val ns = substring (s, 1, 3)
                      val n = Int.fromString ns
                    in
                      addS (chr (valOf n))
                      handle _ =>
                             onParseError 
                                 ("illegal decimal char spec: " ^ ns,
                                  pos, pos + size s)
                    end
                fun getS (pos, tok) =
                    (
                      instring := false;
                      tok (implode (rev (!curstring)), !startpos, pos)
                    )
                (* handling EOF *)
                fun handleEof () =
                    let val pos = 0 (* ToDo : set to the last position *)
                    in
                      if !depth > 0
                      then
                        onParseError
                            ("unexpected end of input in comment", pos, pos)
                      else
                        if !instring
                        then
                          onParseError
                              ("unexpected end of input in string", pos, pos)
                        else ();
                      pos
                    end
              in
                {
                  enterC = enterC,
                  leaveC = leaveC,
                  newS = newS,
                  addS = addS,
                  addSC = addSC,
                  addSN = addSN,
                  getS = getS,
                  handleEof = handleEof,
                  commonOperations = parserOperations,
                  error = onParseError
                }
              end

          fun getLine length = case TextIO.inputLine sourceStream of NONE => ""
								   | SOME s => s
          val lexer = CMParser.makeLexer getLine initialArg

          val (description, _) =
              CMParser.parse (0, lexer, onParseError, ())
              handle e => (TextIO.closeIn sourceStream; raise e)
        in
          TextIO.closeIn sourceStream;
          (description, parserOperations)
        end

    fun isSMLSourceMember (pathName, SOME class) = false
      | isSMLSourceMember (pathName, NONE) =
        let val path = getSpecOfPathName pathName
        in
          if #"$" = String.sub(path, 0)
          then false (* Anchored path *)
          else
            case OS.Path.ext path of
              SOME "sml" => true
            | SOME "sig" => true
            | SOME "fun" => true
            | SOME "cm" => true
            | _ => false
        end

    fun memberToAbsolutePath CMFilePath pathName =
        let
          fun error message = print (message ^ "\n")
          val baseContext =
              SP.dir
              (SP.file
               (SP.native
                    {err = error}
                    {context = SP.cwd(), spec = CMFilePath}))
(*
          val _ = print ("BaseContext = " ^ SP.osstring_dir baseContext ^ "\n")
*)
          val preFile = 
              case pathName of
                (CMSemantic.NativePathName pathName, _) =>
                SP.native
                    {err = error}
                    {context = baseContext, spec = pathName}
              | (CMSemantic.StandardPathName pathName, _) =>
                SP.standard
                    {err = error}
                    {context = baseContext, spec = pathName}
        in
          SP.osstring_prefile preFile
        end
        
  in
  fun readCMFile fileName =
      (case parseCMFile fileName of
         (CMSemantic.Group items, parserOperations) =>
         let
           val (SMLSourceMembers, others) =
               List.partition isSMLSourceMember items
           val SMLPathNames =
               List.map (memberToAbsolutePath fileName) SMLSourceMembers
         in
           app
           (fn (pathName, _) =>
               warn (getSpecOfPathName pathName ^ " is skipped."))
           others;
           SMLPathNames
         end
       | (CMSemantic.Alias destinationFileName, parserOperations) =>
         readCMFile
             (memberToAbsolutePath fileName (destinationFileName, NONE)))
      handle IO.Io _ => (warn (fileName ^ " is skipped."); [])
  end

  fun isCMFileName path =
      case OS.Path.ext path of
        SOME "cm" => true
      | _ => false

  (***************************************************************************)

end
