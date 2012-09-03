(**
 * functions to control SML#.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpControl.sml,v 1.1 2007/06/01 01:26:03 kiyoshiy Exp $
 *)
structure SMLSharpControl : SMLSHARP_CONTROL =
struct
  structure Printer =
  struct
    (* Control_maxDepth, Control_maxWidth and Control_columns are defined in
     * prelude.sml. *)
    fun setMaxDepth intOpt = Control_maxDepth := intOpt
    fun getMaxDepth () = !Control_maxDepth
    fun setMaxWidth intOpt = Control_maxWidth := intOpt
    fun getMaxWidth () = !Control_maxWidth
    fun setColumns int = Control_columns := int
    fun getColumns () = !Control_columns
    fun setMaxRefDepth int = Control_maxRefDepth := int
    fun getMaxRefDepth () = !Control_maxRefDepth
  end
end
