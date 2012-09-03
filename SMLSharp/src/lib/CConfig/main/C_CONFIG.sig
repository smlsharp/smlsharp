(**
 * System configuration inspection by using C compiler.
 *
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: C_CONFIG.sig,v 1.1 2007/03/17 15:09:03 katsu Exp $
 *)
signature C_CONFIG =
sig

  (***************************************************************************)

  (**
   * set verbose flag.
   * If true, CConfig dumps all logs to standard error output.
   * Default is false.
   *)
  val verbose : bool -> unit

  (**
   * set message flag.
   * If true, CConfig displays current inspection status and results
   * of inspections to standard error output.
   * Default is true.
   * string allocated outside of the managed heap.
   *)
  val message : bool -> unit

  (**
   * set logging flag.
   * If true, CConfig writes all logs to "cconfig.log" file in current
   * directory.
   * Default is true.
   *)
  val logging : bool -> unit

  (**
   * set "use cache" flag.
   * If true, CConfig reads and writes "cconfig.cache" file as a cache
   * of check results.
   * Default is true.
   *)
  val useCache : bool -> unit

  (**
   * write check results to "cconfig.cache" file.
   *)
  val saveCache : unit -> unit
                        
  (***************************************************************************)

  (**
   * return a pair of getter and setter of a variable.
   * @params name
   * @param name  a name of variable
   *)
  val config : string ->
               {set: string option -> unit, get: unit -> string option}

  (**
   * replace every variable reference in a string with its content.
   * A variable reference is <code>$</code> followed by one name of
   * variable optionally surrounded by parentheses or braces.
   * <code>$$</code> is replaced with <code>$</code>.
   * The content of variable <var>VAR</var> is
   * <ol>
   * <li>string set by <code>#set config</code> to <var>VAR</var>,</li>
   * <li>the value of environment variable <var>VAR</var> if no string is set
   *     to <var>VAR</var> by <code>#set config</code>,</li>
   * <li>default string provided CConfig if neither no string is set nor
   *     environment variable is not defined, or</li>
   * <li>an empty string.</li>
   * </ol>
   *
   * All variable referecenes are expanded recursivelly; if the content of
   * <var>FOO</var> is <code>"+$BAR+"</code> and the content of <var>BAR</var>
   * is <code>"BAZ"</code>, this function replaces <code>"$FOO"</code>
   * with <code>"+BAZ+"</code>.
   * Note that this function never stop if there is a looped reference.
   *
   * @params string
   * @param string
   *   string containing variable references
   * @return
   *   a string such that every variable reference in given string
   *   is replaced with its content.
   *)
  val expand : string -> string

  (***************************************************************************)

  (**
   * check whether a library is installed on current system.
   * <p>
   * This function inspects whether the library is already installed
   * on the current system like GNU Autoconf.  This function generates
   * minimal C source code and try to compile and link it by C compiler.
   * </p><p>
   * The command line to compile a C source file is given by
   * <var>TRY_COMPILE</var> variable, and one to link is given by
   * <var>TRY_LINK</var> variable.  Default content of <var>TRY_COMPILE</var>
   * is the following:
   * </p>
   * <blockquote><pre>
   * $(CC) -c $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(ccopt) $(src)
   * </pre></blockquote>
   * <p>
   * And default content of <var>TRY_LINK</var> is:
   * </p>
   * <blockquote><pre>
   * $(CC) $(OUTFLAG)$(out) $(INCFLAGS) $(CPPFLAGS)
   * $(CFLAGS) $(ccopt) $(src) $(LIBPATH) $(LDFLAGS) $(ldopt)
   * $(LOCAL_LIBS) $(LIBS)
   * </pre></blockquote>
   *
   * @params (libraryName, functionName, headerFiles)
   * @param libraryName
   *   a name of library to look for.
   * @param functionName
   *   an arbitary function name which is in the library.
   * @param headerFiles
   *   header filenames to be included from generated C source code.
   * @return
   *   true if found the library.
   *)
  val haveLibrary : string * string * string list -> bool

  (**
   * search a library and return its filename if found.
   * <p>
   * This function inspects whether the library exists in the same way
   * as <code>haveLibrary</code> function.
   * If found, this function analyzes the resulting C object file by
   * using <code>ldd</code> command, and extracts a list of library
   * filenames which are linked dynamically from the object code,
   * and then chooses appropriciate one from the list.
   * </p><p>
   * The command line to invoke <code>ldd</code> command is given by
   * <var>TRY_LDD</var> variable. Default content of <var>TRY_LDD</var> is
   * the following:
   * <blockquote><pre>
   * $(LDD) $(out)
   * </pre></blockquote>
   *
   * @params (libraryName, functionName, headerFiles)
   * @param libraryName
   *   a name of library to look for.
   * @param functionName
   *   an arbitary function name which is in the library.
   * @param headerFiles
   *   header filenames to be included from generated C source code.
   * @return
   *   <code>NONE</code> if the library is not found.
   *   <code>SOME <var>filename</var></code> if found, where
   *   <var>filename</var> is an absolute path to the library file.
   *)
  val findLibrary : string * string * string list -> string option

  (**
   * check whether a constant is defined and return its value if found.
   * <p>
   * This function inspects whether the contant (C constant or macro constant)
   * is defined like GNU Autoconf.  This function generates minimal C program
   * to print the constant, and try to compile and link by C compiler
   * and execute the resulting executable file to get the output of
   * the program.
   * </p>
   * 
   * @params (constantName, headerFiles)
   * @param constantName
   *   a name of constant to look for.
   * @param headerFiles
   *   header filenames to be included from generated C source code.
   * @return
   *   <code>NONE</code> if the const is not found.
   *   <code>SOME <var>value</var></code> if found, where
   *   <var>value</var> is the value of the constant.
   *)
  val haveConstInt : string * string list -> int option
  (**
   * see also haveConstInt.
   *)
  val haveConstLong : string * string list -> LargeInt.int option
  (**
   * see also haveConstInt.
   *)
  val haveConstUInt : string * string list -> word option
  (**
   * see also haveConstInt.
   *)
  val haveConstULong : string * string list -> LargeWord.word option
  (**
   * see also haveConstInt.
   *)
  val haveConstFloat : string * string list -> real option
  (**
   * see also haveConstInt.
   *)
  val haveConstDouble : string * string list -> real option
  (**
   * see also haveConstInt.
   *)
  val haveConstString : string * string list -> string option

  (**
   * inspect the size of a C type.
   * 
   * @params (typeName, headerFiles)
   * @param typeName
   *   a name of C type.
   * @param headerFiles
   *   header filenames to be included.
   * @return
   *   an integer value of <code>sizeof(<var>typeName</var>)</code>.
   *)
  val checkSizeOf : string * string list -> int

  (**
   * inspect informations about a member of a structure.
   * 
   * @params (structName, memberName, headerFiles)
   * @param structName
   *   a name of structure.
   * @param memberName
   *   a name of a member of the struction.
   * @param headerFiles
   *   header filenames to be included.
   * @return
   *   a pair of integers. First integer is the size of the member of
   *   the structure, and another is the offset of the member.
   *)
  val checkStructMember : string * string * string list -> (int * int) option

  (**
   * check whether current system is big endian.
   * @return
   *   true if current system is big endian.
   *)
  val checkIsBigEndian : unit -> bool

  (**
   * create a pair of accessor of an integral member of a structure
   * from offset and size.
   * 
   * @params (size, offset)
   * @param size
   *   the size of the member of the structure.
   * @param offset
   *   the offset of the member.
   * @return
   *   a pair of setter and getter.
   *)
  val accessor : int * int -> {set: Word8Array.array * word -> unit,
                               get: Word8Array.array -> word}

  (***************************************************************************)

end
