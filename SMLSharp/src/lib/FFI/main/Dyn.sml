(**
 * serialize library based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author Martin Elsman
 * @version $Id: Dyn.sml,v 1.1 2007/05/20 03:53:25 kiyoshiy Exp $
 *)
structure Dyn :> DYN = 
struct

  (***************************************************************************)

  datatype method = RESET | EQ | SET | HASH
  type dyn = method -> word

  (***************************************************************************)

  fun new eq h =
      let val r = ref NONE
      in
        (
          fn x =>
             fn HASH => h x
              | RESET => (r := NONE; 0w0)
              | SET => (r := SOME x; 0w0)
              | EQ =>
                case !r of NONE => 0w0
                         | SOME y =>
                           if eq(x,y) then 0w1
                           else 0w0,
          fn f => ( r := NONE; f SET; valOf(!r))
        )
      end

  fun eq (f1,f2) = ( f2 RESET ; f1 SET ; f2 EQ = 0w1 )

  fun hash f = f HASH

  (***************************************************************************)

end