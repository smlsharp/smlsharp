(**
 * compiler toolchain support - shell utils
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ShellUtils =
struct

  type output = {stdout : Filename.filename, stderr : Filename.filename}
  exception Fail of {command : string,
                     status : OS.Process.status,
                     output : output}

  datatype arg =
      ARG of string
    | EXPAND of string

  fun isPlainChar c =
      Char.isAlphaNum c orelse c = #"/" orelse c = #"." orelse c = #"-"
      orelse c = #"_" orelse c = #"="

  fun escapeSh "" = "\"\""
    | escapeSh s =
      "'" ^ String.translate (fn #"'" => "'\\''" | c => str c) s ^ "'"

  fun isCmdSpecial c =
      c = #"&" orelse c = #"|" orelse c = #"<" orelse c = #">"
      orelse c = #"(" orelse c = #")" orelse c = #"^" orelse c = #"%"

  fun escapeCmd s =
      let
        fun span x = Substring.string (Substring.span x)
        fun escapeBackslash ss =
            case Substring.getc ss of
              SOME (#"\"", ss) => ("\\^\"", ss)
            | SOME (#"\\", ss) =>
              (case escapeBackslash ss of
                 r as ("", ss) => r
               | (escaped, ss) => ("\\\\" ^ escaped, ss))
            | _ => ("", ss)
        fun escapeStep ss =
            case Substring.getc ss of
              NONE => NONE
            | SOME (#"\"", ss) => SOME ("\\^\"", ss)
            | SOME (#"\\", _) =>
              (case escapeBackslash ss of
                 ("", ss2) => SOME (span (ss, ss2), ss2)
               | r => SOME r)
            | SOME (c, ss) =>
              if isCmdSpecial c
              then SOME ("^" ^ str c, ss)
              else SOME (str c, ss)
        fun escapeAll z ss =
            case escapeStep ss of
              NONE => String.concat (rev z)
            | SOME (escaped, ss) => escapeAll (escaped :: z) ss
      in
        "^\"" ^ escapeAll nil (Substring.full s) ^ "^\""
      end

  fun escape (EXPAND s) = s
    | escape (ARG s) =
      if size s > 0 andalso CharVector.all isPlainChar s
      then s
      else case Config.HOST_OS_TYPE () of
             Config.Unix => escapeSh s
           | Config.Cygwin => escapeSh s
           | Config.Mingw => escapeCmd s

  fun join args =
      String.concatWith " " (map escape args)

  fun splitArgs max args =
      let
        fun loop pos r nil = (rev r, nil)
          | loop pos r (h :: t) =
            let
              val len = pos + 1 + size (escape h)
            in
              if len > max then (rev r, h::t) else loop len (h::r) t
            end
      in
        loop 0 nil args
      end

  fun split {pre, args, post} =
      case Config.CMDLINE_MAXLEN () of
        NONE => (args, nil)
      | SOME max =>
        splitArgs (max - (size (join pre) + size (join post) + 1)) args

  fun puts s =
      TextIO.output (TextIO.stdErr, s ^ "\n")

  fun system args =
      let
        val command = join args
        val stdout = TempFile.create ".txt"
        val stderr = TempFile.create ".txt"
        val cmd = command ^ " > " ^ escape (ARG (Filename.toString stdout))
        val cmd = cmd ^ " 2> " ^ escape (ARG (Filename.toString stderr))
        val _ = if !Control.printCommand then puts command else ()
        val status = OS.Process.system cmd
        val ret = {stdout = stdout, stderr = stderr}
      in
        if !Control.printCommand
        then CoreUtils.cat [stdout, stderr] TextIO.stdErr
        else ();
        if OS.Process.isSuccess status
        then ret
        else raise Fail {command = command, status = status, output = ret}
      end

end
