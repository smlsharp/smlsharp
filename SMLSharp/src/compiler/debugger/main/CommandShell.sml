(**
 * commandline user interface
 * @author YAMATODANI Kiyoshi
 * @version $Id: CommandShell.sml,v 1.7 2005/11/06 14:30:13 kiyoshiy Exp $
 *)
structure CommandShell
  : sig
      (** raised when user inputs "quit" command. *)
      exception Quit
      (** raised when user inputs "run" command. *)
      exception Run

      val start : Context.context -> VM.VM option -> unit
    end =
struct

  (***************************************************************************)

  open BasicTypes
  structure CTX = Context
  structure CVP = CellValuePrinter
  structure FS = FrameStack
  structure I = Instructions
  structure P = CommandShellParser
  structure RT = RuntimeTypes
  structure SS = Substring
  structure U = Utility

  (***************************************************************************)

  (** global context *)
  type context = CTX.context

  (* following types are used locally in this command shell. *)

  datatype commandMap = COMMAND_MAP of commandInfo list

  withtype localContext =
           {
             frames : (FrameStack.frame * RT.codeRef) list,
             currentFrameIndex : int option ref,
             VMOpt : VM.VM option,
             commandMap : commandMap
           }

  and commandHandler = context -> localContext -> P.token list -> unit

  and commandArgSyntax = (P.token, substring) P.regexp

  and commandInfo =
       {
         longName : string,
         shortName : string option,
         description : string,
         syntax : commandArgSyntax,
         handler : commandHandler
       }

  (***************************************************************************)

  (** raised if user input "quit" command. *)
  exception Quit
  (** raised if user input "run" command. *)
  exception Run

  (***************************************************************************)

  structure Errors =
  struct
    (** raised if user input "continue" command. *)
    exception Continue
    (** raised on any error caused by user input. *)
    exception GDBUserError of string
  end

  (***************************************************************************)

  (* utility functions for substring. *)
  fun trimSS substring =
      SS.dropl Char.isSpace (SS.dropr Char.isSpace substring)

  (***************************************************************************)

  fun getCurrentFrame (localContext : localContext) =
      let
        val currentFrameIndex =
            case !(#currentFrameIndex localContext) of
              NONE => raise Errors.GDBUserError "no frame"
            | SOME index => index
      in
        List.nth(#frames localContext, currentFrameIndex)
      end

  fun setCurrentFrame (localContext : localContext) index =
      if (0 <= index) andalso (index < List.length (#frames localContext))
      then #currentFrameIndex localContext := SOME index
      else raise Errors.GDBUserError "frame index"

  (********************)

  fun printFrameInfo (localContext : localContext) frameIndex =
      let
        val (frame, _) =
            List.nth (#frames localContext, frameIndex)
            handle General.Subscript =>
                   raise Errors.GDBUserError "frame index"
        val frameInfo = FS.extractFrame frame
      in
        app
            (fn string => (print string; print "\n"))
            ([
               "frameSize: " ^ UInt32.toString (#frameSize frameInfo),
               "bitmap: " ^ UInt32.toString (#bitmap frameInfo),
               "pointers: " ^ UInt32.toString (#pointersCount frameInfo),
               "atoms: " ^ UInt32.toString (#atomsCount frameInfo),
               "records:"
             ]
             @ (map UInt32.toString (#recordGroups frameInfo)))
      end

  (********************)
  (* command handlers *)

  val descBackTrace = "show all stack frames."
  val regexBackTrace = P.Sequence []
  fun onBackTrace (context : context) (localContext : localContext) args =
      let
        fun toString NONE = "???"
          | toString (SOME loc) = AbsynFormatter.locToString loc
        val frames = #frames localContext
        val locs =
            map
                (fn (_, codeRef) => LocationTable.getLocationOfCodeRef codeRef)
                frames
        val locStrings = map toString locs
      in
        foldl
            (fn (history, index) =>
                (
                  print ("[" ^ Int.toString index ^ "] " ^ history ^ "\n");
                  index + 1
                ))
            0
            locStrings;
        ()
      end

  val descBreak = "set break point."
  val regexBreak = P.Sequence[P.RegexFileName, P.RegexNumber]
  fun onBreak
          (context as {sourceExecutableMap, breakPointTable, ...} : context)
          localContext
          args =
      case args of
        [P.Text fileName, P.Number lineNo] =>
        (case
           CTX.getCodeRefOfSourceLine context (fileName, IntToUInt32 lineNo)
          of
           NONE => raise Errors.GDBUserError "cannot find location\n"
         | SOME (codeRef as {executable, offset}) =>
           if
             isSome(BreakPointTable.findByCodeRef (breakPointTable, codeRef))
           then raise Errors.GDBUserError "breakpoint is already here."
           else
             let
               val opcode = U.getOpcodeAt executable offset
             in
               if I.OPCODE_DebuggerBreak = opcode
               then raise Errors.GDBUserError "break point is already here."
               else
                 let
                   val breakPoint =
                       BreakPointTable.register
                           (breakPointTable, codeRef, opcode)
                 in
                   U.setOpcodeAt executable offset I.OPCODE_DebuggerBreak;
                   print ("break point: " ^ Int.toString breakPoint
                          ^ " at"
                          ^ " offset = " ^ UInt32.toString offset
                          ^ " opcode = " ^ Instructions.opcodeToString opcode
                          ^ "\n")
                 end
             end)
      | _ => raise Errors.GDBUserError "parse error"

  val descCd = "change working directory."
  val regexCd = P.Sequence[P.RegexDirectoryName]
  fun onCd context localContext args =
      case args of
        [P.Text directory] => OS.FileSys.chDir directory
      | _ => raise Errors.GDBUserError "parse error"

  val descContinue = "resume execution."
  val regexContinue = P.Sequence[]
  fun onContinue context _  _ = raise Errors.Continue

  val descDelete = "delete break point."
  val regexDelete = P.RegexNumber
  fun onDelete
          (context as {sourceExecutableMap, breakPointTable, ...} : context)
          localContext
          args =
      case args of
        [P.Number breakPointIndex] =>
        (case BreakPointTable.find (breakPointTable, breakPointIndex) of
           NONE => raise Errors.GDBUserError "cannot find breakpoint"
         | SOME (codeRef as {executable, offset}, originalOpcode) =>
           let
           in
             BreakPointTable.delete (breakPointTable, breakPointIndex);
                
             if
               isSome(BreakPointTable.findByCodeRef (breakPointTable, codeRef))
             then
               (* do nothing, because here is another breakpoint. *)
               (* NOTE: this will not occur. see onBreak *)
               () 
             else
               (* restore original opcode *)
               U.setOpcodeAt executable offset originalOpcode;

             print ("delete break point: " ^ Int.toString breakPointIndex
                    ^ " at"
                    ^ " offset = " ^ UInt32.toString offset
                    ^ " opcode = " ^
                    Instructions.opcodeToString originalOpcode
                    ^ "\n")
           end)
      | _ => raise Errors.GDBUserError "parse error"

  val descFrame = "select current frame."
  val regexFrame = P.Option P.RegexNumber
  fun onFrame
          (context as {sourceExecutableMap, breakPointTable, ...} : context)
          (localContext : localContext)
          args =
      case args of
        [P.Number frameIndex] => setCurrentFrame localContext frameIndex
      | [] =>
        (case !(#currentFrameIndex localContext) of
          SOME frameIndex => printFrameInfo localContext frameIndex
        | NONE => print "no frame") 
      | _ => raise Errors.GDBUserError "parse error"

  local
    fun printCommandHelp (commandInfo : commandInfo) =
        app
            print
            [
              #longName commandInfo,
              "\n",

              "  short name: ",
              getOpt (#shortName commandInfo, ""),
              "\n",

              "  arguments: ",
              " ",
              P.toString (#syntax commandInfo),
              "\n",

              "  ",
              #description commandInfo,
              "\n"
            ]
  in
  val descHelp = "show help"
  val regexHelp = P.Sequence[]
  fun onHelp (context : context) (localContext : localContext) args =
      case #commandMap localContext of
        COMMAND_MAP commandMap => app printCommandHelp commandMap
  end

  val descInfo = "show information."
  val regexInfo : commandArgSyntax =
      P.Or
          [
            P.RegexLiteralText "variables",
            P.Sequence [P.RegexLiteralText "frame", P.Option P.RegexNumber]
          ]
  fun onInfo (context : context) (localContext : localContext) args =
      case args of
        [P.Text "variables"] =>
        let
          val (currentFrame, currentCodeRef) = getCurrentFrame localContext
          val variables = NameSlotTable.getLiveLocalVariables currentCodeRef
          fun printVariable (index, name) =
              print
                  ("[" ^ Int.toString(UInt32ToInt index) ^ "] " ^ name ^ "\n")
        in
          app printVariable variables
        end
      | (P.Text "frame") :: frameArgs =>
        let
          val frameIndex =
              case frameArgs of
                [] =>
                (case !(#currentFrameIndex localContext) of
                   SOME frameIndex => frameIndex
                 | NONE => raise Errors.GDBUserError "no frame")
              | [P.Number frameIndex] => frameIndex
              | _ => raise Errors.GDBUserError "parse error"
        in
          printFrameInfo localContext frameIndex
        end
      | _ => raise Errors.GDBUserError "parse error"

  val descPrint = "print value of an expression."
  val regexPrint = P.RegexText
  fun onPrint (context : context) (localContext : localContext) args =
      case args of
        [P.Text arg] =>
        let
          val (currentFrame, currentCodeRef) = getCurrentFrame localContext
          val value =
              ExpressionInterpreter.eval
                  context currentFrame currentCodeRef (SS.all arg)
              handle ExpressionInterpreter.Error message =>
                     raise Errors.GDBUserError message
          val valueStrings =
              case #VMOpt localContext of
                NONE => raise Errors.GDBUserError "bug"
              | SOME VM => CVP.valueToStrings VM value
        in
          app (fn string => (print string; print "\n")) valueStrings
        end
      | _ => raise Errors.GDBUserError "parse error"

  val descPwd = "print current working directory."
  val regexPwd = P.Sequence[]
  fun onPwd context localContext args =
      case args of
        [] => (print (OS.FileSys.getDir ()); print "\n")
      | _ => raise Errors.GDBUserError "parse error"

  val descQuit = "quit the debugger session."
  val regexQuit = P.Sequence[]
  fun onQuit (context : context) _ _ = raise Quit

  val descRun = "start the program from the beginning."
  val regexRun = P.Sequence[]
  fun onRun (context : context) _ _ = raise Run

  val descSet = "set variable."
  val regexSet : commandArgSyntax =
      P.Or
          [
            P.Sequence [P.RegexLiteralText "args", P.Repeat P.RegexText],
            P.Sequence [P.RegexLiteralText "heapSize", P.RegexNumber],
            P.Sequence [P.RegexLiteralText "frameStackSize", P.RegexNumber],
            P.Sequence [P.RegexLiteralText "handlerStackSize", P.RegexNumber],
            P.Sequence [P.RegexLiteralText "globalCount", P.RegexNumber]
          ]
  fun onSet
          (context : context) (localContext : localContext) args =
      (case args of 
         P.Text "args" :: args =>
         #arguments context := (map (fn P.Text text => text) args)
       | [P.Text "heapSize", P.Number heapSize] =>
         #heapSize context := IntToUInt32 heapSize
       | [P.Text "frameStackSize", P.Number stackSize] =>
         #frameStackSize context := IntToUInt32 stackSize
       | [P.Text "handlerStackSize", P.Number stackSize] =>
         #handlerStackSize context := IntToUInt32 stackSize
       | [P.Text "globalCount", P.Number globalCount] =>
         #globalCount context := IntToUInt32 globalCount
       | _ => raise Errors.GDBUserError "parse error")
      handle Option.Option => raise Errors.GDBUserError "parse error"

  (********************)

  val prompt = "(IMLDB) "

  val commandMap =
      map
          (fn (longName, shortNameOpt, description, syntax, handler) =>
              {
                longName = longName,
                shortName = shortNameOpt,
                description = description,
                syntax = syntax,
                handler = handler
              })
      [
        ("backtrace", SOME "bt", descBackTrace, regexBackTrace, onBackTrace),
        ("break", SOME "b", descBreak, regexBreak, onBreak),
        ("cd", NONE, descCd, regexCd, onCd),
        ("continue", SOME "c", descContinue, regexContinue, onContinue),
        ("delete", SOME "d", descDelete, regexDelete, onDelete),
        ("frame", SOME "f", descFrame, regexFrame, onFrame),
        ("help", SOME "h", descHelp, regexHelp, onHelp),
        ("info", NONE, descInfo, regexInfo, onInfo),
        ("print", SOME "p", descPrint, regexPrint, onPrint),
        ("pwd", NONE, descPwd, regexPwd, onPwd),
        ("quit", SOME "q", descQuit, regexQuit, onQuit),
        ("run", SOME "r", descRun, regexRun, onRun),
        ("set", NONE, descSet, regexSet, onSet)
      ]
  fun findCommand commandName =
      case
        List.find
            (fn {shortName = SOME shortName, ...} => shortName = commandName
              | {shortName = NONE, ...} => false)
            commandMap
       of
        SOME entry => [entry]
      | NONE =>
        List.filter
            (fn {longName, ...} => String.isPrefix commandName longName)
            commandMap

  fun loop (context as {sourceExecutableMap, ...} : context) localContext =
      let
        val _ = print prompt
        val line = TextIO.inputLine TextIO.stdIn
        val (commandSS, argumentSS) =
            SS.splitl (not o Char.isSpace) (trimSS(SS.all line))
        val commandName = SS.string(trimSS commandSS)
      in
        if "" = commandName
        then ()
        else
          case findCommand commandName of
            [] => print "unknown command\n"
          | [{handler, syntax, ...}] =>
            (case P.parse syntax SS.getc argumentSS of
               SOME(args, remains) =>
               (handler context localContext args
                handle Errors.GDBUserError message => print (message ^ "\n")
                     | exn as Quit => raise exn
                     | exn as Run => raise exn
                     | exn as Errors.Continue => raise exn
                     | exn =>
                       (
                         print (exnMessage exn ^ "\n");
                         app
                             (fn history => print (history ^ "\n"))
                             (SMLofNJ.exnHistory exn)
                       ))
             | NONE => raise Errors.GDBUserError "parse error")

          | _ => (print "ambiguous command name\n");
        loop context localContext
      end

  fun start context VMOpt =
      let
        val frames = 
            case VMOpt of
              NONE => []
            | SOME VM =>
              let
                (* make a list of pairs of a frame and an address of
                 * instruction.
                 *  Each frame is paired with an address of a call instruction
                 * which created its upper frame. The address is obtained
                 * from the return address slot of the upper frame.
                 *  The top frame is paired with the address of the current
                 * instruction address.
                 *)
                val frames = FS.getFrames (VM.getFrameStack VM)
                val codeRefs =
                    (VM.getCurrentCodeRef VM)
                    :: (map FS.getReturnAddressOfFrame frames)
              in
                (* the return address in the bottom frame is discarded,
                 * because it is a dummy address. *)
                ListPair.zip (frames, codeRefs)
              end

        val currentFrameIndex = case frames of [] => NONE | _ => SOME 0
        val localContext =
            {
              frames = frames,
              currentFrameIndex = ref currentFrameIndex,
              VMOpt = VMOpt,
              commandMap = COMMAND_MAP commandMap
            }
      in
        (loop context localContext)
        handle Errors.Continue => ()
      end

  (***************************************************************************)

end;