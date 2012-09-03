signature RUNTIME_RUNNER =
sig

  (***************************************************************************)

  val execute
      : {
          executableFileName : string,
          outputChannel : ChannelTypes.OutputChannel
        }
        -> OS.Process.status

  (***************************************************************************)

end