(**
 * information of links between entities.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Linkage.sml,v 1.2 2004/10/20 03:18:40 kiyoshiy Exp $
 *)
structure Linkage =
struct

  (***************************************************************************)

  structure EA = ElaboratedAst

  (***************************************************************************)

  datatype moduleLinkType =
           (* defined by *)
           ModuleDefLink
         | (* applied functor *)
           AppLink
         | (* argument to functor *)
           ArgLink
         | (* spec of argument of functor *)
           FormalArgLink
         | WhereLink
         | OpenLink
         | IncludeLink
         | ConstraintLink
  type moduleLinkage = moduleLinkType * EA.moduleFQN * EA.moduleFQN

  datatype typeLinkType =
           TypeDefLink
         | ExnArgLink
         | ConstructurArgLink
         | ValTypeLink
  type typeLinkage =
       typeLinkType * (EA.moduleFQN * string) * (EA.moduleFQN * string)

  (***************************************************************************)

end