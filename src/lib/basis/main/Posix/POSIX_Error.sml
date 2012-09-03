(**
 * Structure for POSIX error codes.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: POSIX_Error.sml,v 1.1 2005/08/14 01:55:47 kiyoshiy Exp $
 *)
(* posix-error.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Structure for POSIX error codes.
 *
 *)
structure POSIX_Error =
struct

  type syserror = int (* = PreBasis.syserror *)

  val errors : (int * string) list = POSIX_Error_listErrors 0

  local
    fun find name = List.find (fn (_, errorName) => name = errorName) errors
  in
  fun osVal errorName =
      case find errorName of NONE => raise Fail "not found error name:" ^ s

  fun syserror errorName =
      case find errorName of NONE => NONE | (SOME(errorNo, _)) => SOME errorNo
  end

  fun toWord i = SysWord.fromInt i
  fun fromWord w = SysWord.toInt w
  fun errorMsg i = POSIX_Error_errMsg i
  fun errorName err = POSIX_Error_errorName err

  val toobig      = osVal "toobig"
  val acces       = osVal "acces"
  val again       = osVal "again"
  val badf        = osVal "badf"
  val badmsg      = osVal "badmsg"
  val busy        = osVal "busy"
  val canceled    = osVal "canceled"
  val child       = osVal "child"
  val deadlk      = osVal "deadlk"
  val dom         = osVal "dom"
  val exist       = osVal "exist"
  val fault       = osVal "fault"
  val fbig        = osVal "fbig"
  val inprogress  = osVal "inprogress"
  val intr        = osVal "intr"
  val inval       = osVal "inval"
  val io          = osVal "io"
  val isdir       = osVal "isdir"
  val loop        = osVal "loop"
  val mfile       = osVal "mfile"
  val mlink       = osVal "mlink"
  val msgsize     = osVal "msgsize"
  val nametoolong = osVal "nametoolong"
  val nfile       = osVal "nfile"
  val nodev       = osVal "nodev"
  val noent       = osVal "noent"
  val noexec      = osVal "noexec"
  val nolck       = osVal "nolck"
  val nomem       = osVal "nomem"
  val nospc       = osVal "nospc"
  val nosys       = osVal "nosys"
  val notdir      = osVal "notdir"
  val notempty    = osVal "notempty"
  val notsup      = osVal "notsup"
  val notty       = osVal "notty"
  val nxio        = osVal "nxio"
  val perm        = osVal "perm"
  val pipe        = osVal "pipe"
  val range       = osVal "range"
  val rofs        = osVal "rofs"
  val spipe       = osVal "spipe"
  val srch        = osVal "srch"
  val xdev        = osVal "xdev"

end

