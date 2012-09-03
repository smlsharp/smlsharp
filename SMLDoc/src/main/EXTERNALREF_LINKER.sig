(**
 * This modules reads/writes link files.
 * <p>
 *  Link files list the names of ML program elements (modules and types)
 * for which documents are generated in the specified location.
 * </p>
 * <p>
 *  This module saves the structure of the ENVSet the elaborator generates
 * into a link file and restores them from the linkfile.
 * </p>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: EXTERNALREF_LINKER.sig,v 1.3 2004/11/07 13:16:19 kiyoshiy Exp $
 *)
signature EXTERNALREF_LINKER =
sig

  (***************************************************************************)

  (**
   * the default name of link files
   *)
  val defaultModuleListFileName : string

  (**
   * reads the link file.
   * <p>
   *   The link file lists elements for which HTML documents are generated
   *  in the specified URL.
   *  This function reads the file and builds an ENVSet which contains
   * external references to the elements listed in the file.
   * </p>
   * @params parameter baseURL fileName baseENVSet
   * @param parameter common parameter
   * @param baseURL the URL of the directory where HTML files for the elements
   *              listed in the link file are contained.
   * @param fileName the name of link file
   * @param baseENVSet the ENVSet which contains prelude elements and
   *                elements loaded from other linkfiles prior.
   * @return extended environment set
   * @author YAMATODANI Kiyoshi
   * @version 1.0
   *)
  val readLinkFile :
      DocumentGenerationParameter.parameter ->
      string ->
      string ->
      ENVSet.ENVSet ->
      ENVSet.ENVSet

  (**
   * writes the ENVSet into a link file.
   * @params parameter fileName ENVSet
   * @param parameter common parameter
   * @param fileName the name of file to be generated.
   * @param ENVSet the ENVSet to be output
   * @return unit
   * @author YAMATODANI Kiyoshi
   * @version 1.0
   *)
  val writeLinkFile : 
      DocumentGenerationParameter.parameter ->
      string ->
      ENVSet.ENVSet ->
      unit

  (***************************************************************************)

end
