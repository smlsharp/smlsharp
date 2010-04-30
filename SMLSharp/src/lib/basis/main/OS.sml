(*
 * temporary implementation of OS signature.
 *)
structure OS =
struct

  type syserror = int
  fun errorName syserror = "error"
  fun syserror name = NONE
  fun errorMsg syserror = "error"
  exception SysErr of string * syserror option

  val STDIN_DESC = 0
  val STDOUT_DESC = 1
  val STDERR_DESC = 2

  structure IO =
  struct
    type iodesc = int
    structure Kind =
    struct
      val tty = 0w0
      val file = 0w1
    end
    fun kind iodesc =
        if
          iodesc = STDIN_DESC
          orelse iodesc = STDOUT_DESC
          orelse iodesc = STDERR_DESC
        then Kind.tty
        else Kind.file
  end

end;