(**
 *  parameter for ducument generation.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: DocumentGenerationParameter.sml,v 1.8 2007/03/05 03:31:23 kiyoshiy Exp $
 *)
structure DocumentGenerationParameter =
struct

  (***************************************************************************)

  datatype parameter =
           Parameter of
           {
             author : bool,
             contributor : bool,
             copyright : bool,
             bottom : string option,
             builtinTypes : string list,
             builtinStructures : string list,
             charSet : string option,
             directory : string,
             docTitle : string option,
             footer : string option,
             header : string option,
             helpfile : string option,
             help : bool,
             hideBySig : bool,
             index : bool,
             links : {URL : string, linkFile : string} list,
             linkSource : bool,
             listSubModule : bool,
             overview : string option,
             printWarning : bool,
             recursive : bool,
             navbar : bool,
             showSummary : bool,
             splitIndex : bool,
             uses : bool,
             version : bool,
             verbose : bool,
             windowTitle : string option
           }

  (***************************************************************************)

  fun warn (Parameter{printWarning, ...}) message =
      if printWarning
      then app print ["WARNING: ", message, "\n"]
      else ()

  fun error (Parameter{...}) message =
      app print ["ERROR: ", message, "\n"]

  fun onProgress (Parameter{verbose, ...}) message =
      if verbose then print (message ^ "\n") else ()

  (***************************************************************************)

end