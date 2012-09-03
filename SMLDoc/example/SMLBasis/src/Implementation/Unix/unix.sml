(* unix.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure Unix : UNIX =
  struct

    structure P = Posix.Process
    structure PE = Posix.ProcEnv
    structure PF = Posix.FileSys
    structure PIO = Posix.IO
    structure SS = Substring

    fun protect f x = let
          val _ = Signals.maskSignals Signals.MASKALL
          val y = (f x) handle ex => 
                    (Signals.unmaskSignals Signals.MASKALL; raise ex)
          in
            Signals.unmaskSignals Signals.MASKALL; y
          end

    fun fdReader (name : string, fd : PIO.file_desc) =
	  PosixTextPrimIO.mkReader {
              initBlkMode = true,
              name = name,
              fd = fd
            }

    fun fdWriter (name, fd) =
          PosixTextPrimIO.mkWriter {
	      appendMode = false,
              initBlkMode = true,
              name = name,
              chunkSize=4096,
              fd = fd
            }

    fun openOutFD (name, fd) =
	  TextIO.mkOutstream (
	    TextIO.StreamIO.mkOutstream (
	      fdWriter (name, fd), IO.BLOCK_BUF))

    fun openInFD (name, fd) =
	  TextIO.mkInstream (
	    TextIO.StreamIO.mkInstream (
	      fdReader (name, fd), ""))

    datatype proc = PROC of {
        pid : P.pid,
        ins : TextIO.instream,
        outs : TextIO.outstream
      }

    fun executeInEnv (cmd, argv, env) = let
          val p1 = PIO.pipe ()
          val p2 = PIO.pipe ()
          fun closep () = (
                PIO.close (#outfd p1); 
                PIO.close (#infd p1);
                PIO.close (#outfd p2); 
                PIO.close (#infd p2)
              )
          val base = SS.string(SS.taker (fn c => c <> #"/") (SS.all cmd))
          fun startChild () = (case protect P.fork ()
		 of SOME pid =>  pid           (* parent *)
                  | NONE => let
		      val oldin = #infd p1
		      val newin = Posix.FileSys.wordToFD 0w0
		      val oldout = #outfd p2
		      val newout = Posix.FileSys.wordToFD 0w1
                      in
			PIO.close (#outfd p1);
			PIO.close (#infd p2);
			if (oldin = newin) then ()
			else (
                          PIO.dup2{old = oldin, new = newin};
                          PIO.close oldin);
			if (oldout = newout) then ()
			else (
                          PIO.dup2{old = oldout, new = newout};
                          PIO.close oldout);
			P.exece (cmd, base::argv, env)
		      end
		(* end case *))
          val _ = TextIO.flushOut TextIO.stdOut
          val pid = (startChild ()) handle ex => (closep(); raise ex)
          val ins = openInFD (base^"_exec_in", #infd p2)
          val outs = openOutFD (base^"_exec_out", #outfd p1)
          in
              (* close the child-side fds *)
            PIO.close (#outfd p2);
            PIO.close (#infd p1);
              (* set the fds close on exec *)
            PIO.setfd (#infd p2, PIO.FD.flags [PIO.FD.cloexec]);
            PIO.setfd (#outfd p1, PIO.FD.flags [PIO.FD.cloexec]);
            PROC {
              pid = pid,
              ins = ins,
              outs = outs
            }
          end

    fun execute (cmd, argv) = executeInEnv (cmd, argv, PE.environ())

    fun streamsOf (PROC{ins,outs,...}) = (ins, outs)

    fun kill (PROC{pid,...},signal) = P.kill (P.K_PROC pid, signal)

    fun reap (PROC{pid,ins,outs}) = let
        (* protect is probably too much; typically, one
         * would only mask SIGINT, SIGQUIT and SIGHUP
         *)
          fun waitProc () = #2(protect P.waitpid (P.W_CHILD pid,[]))
          in
            TextIO.closeIn ins;
            TextIO.closeOut outs handle _ => ();
            waitProc ()
          end

  end (* structure Unix *)

