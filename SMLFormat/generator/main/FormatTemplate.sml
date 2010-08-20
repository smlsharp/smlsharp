(**
 * definition of format template
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FormatTemplate.sml,v 1.6 2007/06/30 11:04:42 kiyoshiy Exp $
 *)
structure FormatTemplate =
struct

  (***************************************************************************)

  (* to mark positions in files *)
  type srcpos = int  (* character position from beginning of stream (base 0) *)
  type region = srcpos * srcpos   (* start and end position of region *)

  (**
   * priority of newline indicators.
   *)
  datatype priority =
           (** preferred priority of the specified priority *)
           Preferred of int
         | (** deferred priority *)
           Deferred

  (**
   * direction of the associativity between elements in guards
   *)
  datatype assocDirection =
                   (** indicates left associativity *)
                   Left
                 | (** indicates right associativity *)
                   Right
                 | (** indicates non-directional associativity *)
                   Neutral

  (**
   * the associativity between elements in guards.
   *)
  type assoc =
       {
         (**
          * true if the inheritance of associativity from the upper guard
          * is cut.
          *) 
         cut : bool,
         (** the strength of the association. *)
         strength : int,
         (** the direction of the association. *)
         direction : assocDirection
       }

  type id = string

  (**
   * format templates
   *)
  datatype template =
           (** literal *) Term of string
         | (** alwasy newline *) Newline
         | (** guard *) Guard of (assoc option) * (template list)
         | (** space/newline indicator *)
           Indicator of
           {
             space : bool,
             newline : {priority : priority} option
           }
         | (** indent push *) StartOfIndent of int
         | (** indent pop *) EndOfIndent
         | (** template instantiation *) Instance of instance
         | (** mark a template *) MarkTemplate of template * region

  (** template instantiation *)
  and instance =
      (** instantiation with no argument *)
      Atom of id * id option
    | (** instantiation with arguments *)
      App of id * id option* (instance list) * (template list list)
    | (** mark a instance *) MarkInstance of instance * region

  (** type patterns *)
  datatype typepat =
           (** id *) VarTyPat of id
         | (** id with custom formatter specified *) TypedVarTyPat of id * id
         | (** dont-care pattern *) WildTyPat
         | (** record *)
           RecordTyPat of
           (string * typepat) list * (** if flexible, true *) bool
         | (** tuple *) TupleTyPat of typepat list
         | (** type constructor application *)
           TyConTyPat of id * (typepat list)
         | (** type constructor application with custom formatter specified *)
           TypedTyConTyPat of id * (typepat list) * id
         | (** mark a typepat *) MarkTyPat of typepat * region

  (**
   * format tag
   *)
  type formattag =
       {id : id option, typepat : typepat, templates : template list}

  (***************************************************************************)

end
