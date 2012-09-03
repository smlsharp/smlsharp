(**
 * A SML port of GNU's getopt library.
 * <p>
 * This port is derived from Sven Panne's 
 * <Sven.Panne@informatik.uni-muenchen.de>
 * implementation of the getopt library in Haskell <http://www.haskell.org>
 * </p>
 * <p>
 * The following comments are lifted from Sven's code:
 * <quote>
 *   <p>
 *   Two rather obscure features are missing: The Bash 2.0 non-option hack (if
 *   you don't already know it, you probably don't want to hear about it...) 
 *   and the recognition of long options with a single dash (e.g. '-help' is
 *   recognised as '--help', as long as there is no short option 'h').
 *   </p>
 *   <p>
 *   Other differences between GNU's getopt and this implementation:
 *   <ul>
 *     <li>
 *       To enforce a coherent description of options and arguments, there are
 *       explanation fields in the option/argument descriptor.
 *     </li>
 *     <li>
 *       Error messages are now more informative, but no longer POSIX
 *       compliant... :-(
 *     </li>
 *   </p>
 * </quote>
 * </p>
 * <p>
 * A difference with Sven's port: errors now invoke an error callback, rather
 * than returning error strings while continuing processing options.
 * The full generality of the latter does not seem justified.
 * </p>
 * 
 * @copyright (c) 1998 Bell Labs, Lucent Technologies.
 * @version $Id: GET_OPT.sig,v 1.1 2005/12/26 14:18:10 kiyoshiy Exp $
 *)
signature GET_OPT = 
sig

  (** What to do with options following non-options. *)
  datatype 'a arg_order =
           (** RequireOrder: no option processing after first non-option *)
           RequireOrder
         | (** Permute: freely intersperse options and non-options *)
           Permute
         | (** ReturnInOrder: wrap non-options into options *)
           ReturnInOrder of string -> 'a
          
  (** Description of an argument option *)
  datatype 'a arg_descr =
           (** NoArg: no argument required *)
           NoArg of 'a
         | (** ReqArg: option requires an argument *)
           ReqArg of (string -> 'a) * string
         | (** OptArg: optional argument *)
           OptArg of (string option -> 'a) * string
          
  (** Description of a single option *)
  type 'a opt_descr =
       {
         short : string,
         long : string list,
         desc : 'a arg_descr,
         help : string
       }

  (** takes a header string and a list of option descriptions and
   * returns a string explaining the usage information
   *)
  val usageInfo
      : {header : string, options : 'a opt_descr list} -> string
 
  (** takes as argument an arg_order to specify the non-options
   * handling, a list of option descriptions, an error callback,
   * and a command line containing the options and arguments,
   * and returns a list of (options, non-options)
   *)      
  val getOpt
      : {
          argOrder : 'a arg_order,
          options : 'a opt_descr list,
          errFn : string -> unit
        }
        -> string list
        -> ('a list * string list)
 
end

