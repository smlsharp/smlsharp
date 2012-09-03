(**
 * A SML port of GNU's getopt library.
 * This port is derived from Sven Panne's
 * <Sven.Panne@informatik.uni-muenchen.de>
 * implementation of the getopt library in Haskell <http://www.haskell.org>
 * 
 * The following comments are lifted from Sven's code:
 * <quote>
 * <p>
 * Two rather obscure features are missing: The Bash 2.0 non-option hack
 * (if you don't already know it, you probably don't want to hear about it...)
 * and the recognition of long options with a single dash (e.g. '-help' is
 * recognised as '--help', as long as there is no short option 'h').
 * </p>
 * <p>
 * Other differences between GNU's getopt and this implementation:
 * <ul>
 * <li>To enforce a coherent description of options and arguments, there are
 *    explanation fields in the option/argument descriptor.</li>
 * <li>Error messages are now more informative, but no longer POSIX
 * compliant... :-(</li>
 * </ul>
 * </p>
 * 
 * @author (c) 1998 Bell Labs, Lucent Technologies.
 * @version $Id: GET_OPT.sig,v 1.1 2007/02/18 03:08:59 kiyoshiy Exp $
 *)
signature GETOPT = 
    sig
        datatype 'a arg_order =    (* What to do with options following non-options *)
            RequireOrder           (*  no option processing after first non-option *)
          | Permute                (*  freely intersperse options and non-options *)
          | ReturnInOrder of string -> 'a  (* wrap non-options into options *)

            
        datatype 'a arg_descr =        (* Description of an argument option: *)
            NoArg of 'a                              (*  no argument required *)
          | ReqArg of (string -> 'a) * string        (*  option requires an argument *)
          | OptArg of (string option -> 'a) * string (*  optional argument *)

            
        type 'a opt_descr = {     (* Description of a single option *)
            short : string,       (*  short options *)
            long : string list,   (*  list of long options strings (without "--") *)
            desc : 'a arg_descr,  (*  argument descriptor *)
            help : string         (*  explanation of option for user *)
          }

            
        val usageInfo : string -> 'a opt_descr list -> string
        (* takes a header string and a list of option descriptions and
         * returns a string explaining the usage information
         *)


        val getOpt : 'a arg_order -> 'a opt_descr list -> string list ->
                        ('a list * string list * string list)
        (* takes as argument an arg_order to specify the non-options
         * handling, a list of option descriptions and a command line
         * containing the options and arguments, and returns a list of 
         * (options, non-options, error messages)
         *)
    end

