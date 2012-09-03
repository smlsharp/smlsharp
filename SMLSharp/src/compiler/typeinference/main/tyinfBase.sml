(**
 * utility functions for type inference modules.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: tyinfBase.sml,v 1.14 2006/02/28 16:11:09 kiyoshiy Exp $
 *)
structure TypeinfBase : TYPEINFBASE =
struct

  local 
    open Types 
    structure TU = TypesUtils
  in

  type utvenv = (tvState ref) SEnv.map


end
end
