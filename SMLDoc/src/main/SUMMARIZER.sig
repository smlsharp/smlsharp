(**
 *  signature of module which analyse the elaborated AST and produce the
 * summarized information useful for the document generator.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: SUMMARIZER.sig,v 1.3 2004/11/06 16:15:03 kiyoshiy Exp $
 *)
signature SUMMARIZER =
sig

  (***************************************************************************)

  (**
   * graph of dependency links between the binds
   *)
  type linkage 

  (**
   * indicates the direction of trace in the <code>getClosureOfLink</code>
   *)
  datatype traceDirection =
           (**
            * trace from the source to the destination of links
            *)
           SRCTODEST
         | (**
            * trace from the destination to the source of links
            *)
           DESTTOSRC

  (***************************************************************************)

  (**
   * generates summary information of the abstract syntax tree.
   * @params compileUnits
   * @param compileUnits the elaborated compile unit list
   * @return a pair of the list of bindings in the given ast and the linkage
   *           graph of those bindings.
   *)
  val summarize : ElaboratedAst.compileUnit list -> (Binds.bind list * linkage)

  (**
   *  traces the linkage graph and gets the closure of links of the specified
   * type.
   * @params direction linkTypes linkage startModule
   * @param direction the direction of trace
   * @param linkTypes a list of the link types to trace
   * @param linkage the linkage graph
   * @param startModule the FQN of the module which is the start point of trace
   * @return bindings reachable from the startModule by tracing the links of
   *                 the specified link types.
   *)
  val getClosureOfLink :
      traceDirection ->
      Linkage.moduleLinkType list ->
      linkage ->
      ElaboratedAst.moduleFQN ->
      Binds.bind list

  (***************************************************************************)

end