(**
 * parse command line arguments
 * Copyright (C) 2010 Tohoku University.
 * @author UENO Katsuhiro
 *)
structure GetOpt : sig

  datatype 'a arg =
      OPTION of 'a
    | ARG of string

  datatype 'a argDesc =
      NOARG of 'a
    | REQUIRED of string -> 'a
    | OPTIONAL of string option -> 'a

  datatype 'a optionDesc =
      SHORT of char * 'a argDesc
    | SLONG of string * 'a argDesc
    | DLONG of string * 'a argDesc

  (*
   *             | NOARG   |        REQIURED         |     OPTIONAL
   * ------------+---------+-------------------------+---------------------
   * SHORT "a"   |  -a     |  -a foo                 |  -a      -a foo
   * SLONG "arg" |  -arg   |  -arg=foo    -arg foo   |  -arg    -arg=foo
   * DLONG "arg" |  --arg  |  --arg=foo   --arg foo  |  --arg   --arg=foo
   *)

  exception NoArg of string
  exception HasArg of string
  exception Unknown of string

  val allowPackedOption : bool ref
  val getopt : 'a optionDesc list -> string list -> 'a arg list

end =
struct
  datatype 'a arg =
      OPTION of 'a
    | ARG of string

  datatype 'a argDesc =
      NOARG of 'a
    | REQUIRED of string -> 'a
    | OPTIONAL of string option -> 'a

  datatype 'a optionDesc =
      SHORT of char * 'a argDesc
    | SLONG of string * 'a argDesc
    | DLONG of string * 'a argDesc

  exception NoArg of string
  exception HasArg of string
  exception Unknown of string

  val allowPackedOption = ref false

  fun cons1 (h, (x, y)) = (h::x, y)

  fun parseShort descs (arg, argv) =
      case Substring.getc arg of
        NONE => raise Unknown ""
      | SOME (ch, arg) =>
        case List.find (fn (c,_) => c = ch) descs of
          NONE => raise Unknown (str ch)
        | SOME (_, NOARG v) =>
          if !allowPackedOption
          then cons1 (OPTION v, parseShort descs (arg, argv))
          else if Substring.isEmpty arg
          then ([OPTION v], argv)
          else raise HasArg (str ch)
        | SOME (_, REQUIRED f) =>
          if Substring.isEmpty arg
          then case argv of nil => raise NoArg (str ch)
                          | arg::argv => ([OPTION (f arg)], argv)
          else ([OPTION (f (Substring.string arg))], argv)
        | SOME (_, OPTIONAL f) =>
          if Substring.isEmpty arg
          then ([OPTION (f NONE)], argv)
          else ([OPTION (f (SOME (Substring.string arg)))], argv)

  fun parseLong descs (arg, argv) =
      let
        fun isNotDelim c = c <> #"=" andalso c <> #","
        val (name, arg) = Substring.splitl isNotDelim arg
        val name = Substring.string name
      in
        case List.find (fn (s,_) => s = name) descs of
          NONE => raise Unknown name
        | SOME (_, NOARG v) =>
          if Substring.isEmpty arg then ([OPTION v], argv)
          else raise HasArg name
        | SOME (_, REQUIRED f) =>
          if Substring.isEmpty arg
          then case argv of nil => raise NoArg name
                          | arg::argv => ([OPTION (f arg)], argv)
          else ([OPTION (f (Substring.string (Substring.triml 1 arg)))], argv)
        | SOME (_, OPTIONAL f) =>
          if Substring.isEmpty arg
          then ([OPTION (f NONE)], argv)
          else ([OPTION (f (SOME (Substring.string (Substring.triml 1 arg))))],
                argv)
      end

  fun parseArgv descs nil = nil
    | parseArgv (descs as (shorts, slongs, dlongs)) (arg::argv) =
      let
        val arg = Substring.full arg
        val (args, argv) =
            if Substring.isPrefix "--" arg
            then if Substring.size arg > 2
                 then parseLong dlongs (Substring.triml 2 arg, argv)
                 else (map ARG argv, nil)
            else if Substring.isPrefix "-" arg andalso Substring.size arg > 1
            then parseLong slongs (Substring.triml 1 arg, argv)
                 handle Unknown _ =>
                        parseShort shorts (Substring.triml 1 arg, argv)
            else ([ARG (Substring.string arg)], argv)
      in
        args @ parseArgv descs argv
      end

  fun getopt optionDesc argv =
      let
        val desc =
            foldr
              (fn (SHORT x, (shorts, slongs, dlongs)) =>
                  (x::shorts, slongs, dlongs)
                | (SLONG x, (shorts, slongs, dlongs)) =>
                  (shorts, x::slongs, dlongs)
                | (DLONG x, (shorts, slongs, dlongs)) =>
                  (shorts, slongs, x::dlongs))
              (nil, nil, nil)
              optionDesc
      in
        parseArgv desc argv
      end
end
