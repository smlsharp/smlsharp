(**
 * datatype of linke file which describes linkage information.
 * @author YAMATODANI Kiyoshi
 * @version $Id: LinkFile.sml,v 1.2 2004/10/20 03:18:40 kiyoshiy Exp $
 *)
structure LinkFile =
struct

  (***************************************************************************)

  structure EA = ElaboratedAst

  datatype item =
           ModuleDefine of (EA.moduleType * string) * item list
         | ModuleReplica of (EA.moduleType * string) * EA.moduleFQN
         | TypeDefine of string
         | TypeReplica of string * EA.moduleFQN
         | ValDefine of string
         | ExceptionDefine of string

  (***************************************************************************)

end