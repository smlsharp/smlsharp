(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author Liu Bochao
 * utility functions for type inference modules.
 * @version $Id: tyinfBase.sml,v 1.13 2006/02/18 04:59:35 ohori Exp $
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
