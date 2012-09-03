(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ErrorQueue.sml,v 1.1 2006/12/31 07:44:52 kiyoshiy Exp $
 *)
structure ErrorQueue =
struct

  datatype errorInfo =
           Error of exn
         | Warning of string

  val errors = ref ([] : errorInfo list)

  fun initialize _ = errors := []

  fun add error = errors := (error :: !errors)

  fun getAll _ = rev (!errors)

end
