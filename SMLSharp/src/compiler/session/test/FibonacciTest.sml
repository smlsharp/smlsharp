

val count = 10;
val Primitive_PrintInt = 0;
val Primitive_InputInt = 1;

local
open SymbolicInstructions
in
val fibCode = 
[
(*  LoadConst {value = count}, *)
  CallPrim1 {primitive = IntToUInt24 Primitive_InputInt},
  CallStatic {bitmapEntry = AnyEntry(0w0), entryPoint = LabelRef "fib"},
  CallPrim1 {primitive = IntToUInt24 Primitive_PrintInt},
  Exit,
  Label "fib",
  FunEntry
  {
    arity = 0w1,
    atomCount = 0w2,
    pointerCount = 0w1,
    recordCount = 0w0,
    staticEntryPoint = LabelRef "fib.static"
  },
  Label "fib.static",
  Store {variableEntry = AtomEntry(0w0)},
  LoadConst {value = 0},
  JumpConditionalRelative
  {
    condition = Eq,
    variableEntry = AtomEntry 0w0,
    destination = LabelRef "fib.exit"
  },
  LoadConst {value = 1},
  JumpConditionalRelative
  {
    condition = Eq,
    variableEntry = AtomEntry 0w0,
    destination = LabelRef "fib.exit"
  },
  SubInt {variableEntry = AtomEntry(0w0)},
  CallStatic {bitmapEntry = AnyEntry(0w0), entryPoint = LabelRef "fib"},
  Store {variableEntry = AtomEntry(0w1)},
  LoadConst {value = 2},
  SubInt {variableEntry = AtomEntry(0w0)},
  CallStatic {bitmapEntry = AnyEntry(0w0), entryPoint = LabelRef "fib"},
  AddInt {variableEntry = AtomEntry(0w1)},
  Label "fib.exit",
  Return
];
end;

val fibBin = (InstructionSerializer.serialize o Assembler.assemble) fibCode;

fun testStandAlone fileName =
    let
        val channel = FileChannel.openOut {fileName = fileName};
        val session = StandAloneSession.openSession {outputChannel = channel};
        fun cleanUp () = (#close session (); #close channel ())
    in
        #execute session fibBin
        handle e => (cleanUp(); raise e);
        cleanUp()
    end

fun testInteractive hostName port =
    let
        val stdInChannel = TextIOChannel.openIn {inStream = TextIO.stdIn}
        val stdOutChannel = TextIOChannel.openOut {outStream = TextIO.stdOut}
        val stdErrorChannel = TextIOChannel.openOut {outStream = TextIO.stdErr}
        val (socketInputChannel, socketOutputChannel) =
            ClientSocketChannel.openInOut {hostName = hostName, port = port}
        val session =
            InteractiveSession.openSession
            {
              terminalInputChannel = stdInChannel,
              terminalOutputChannel = stdOutChannel,
              terminalErrorChannel = stdErrorChannel,
              messageInputChannel = socketInputChannel,
              messageOutputChannel = socketOutputChannel
            }
        fun cleanUp () =
            (
              #close session ();
              #close stdInChannel ();
              #close stdOutChannel ();
              #close stdErrorChannel ();
              #close socketInputChannel ();
              #close socketOutputChannel ()
            )

    in
        #execute session fibBin
        handle e => (cleanUp (); raise e);
        cleanUp ()
    end;
