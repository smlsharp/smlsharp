(**
 * Copyright (c) 2006, Tohoku University.
 *
 * global context
 * @author YAMATODANI Kiyoshi
 * @version $Id: Context.sml,v 1.3 2006/02/18 04:59:21 ohori Exp $
 *)
structure Context =
struct

  (***************************************************************************)

  open BasicTypes
  structure RT = RuntimeTypes

  (***************************************************************************)

  type sourceExecutableMap = (RT.executable list) SEnv.map

  type context =
       {
         sourceExecutableMap : sourceExecutableMap ref,
         breakPointTable : BreakPointTable.table,
         heapSize : BasicTypes.UInt32 ref,
         frameStackSize : BasicTypes.UInt32 ref,
         handlerStackSize : BasicTypes.UInt32 ref,
         globalCount : BasicTypes.UInt32 ref,
         arguments : string list ref
       }

  (***************************************************************************)

  val heapSize = 0w100000 : BasicTypes.UInt32
  val frameStackSize = 0w10000 : BasicTypes.UInt32
  val handlerStackSize = 0w10000 : BasicTypes.UInt32
  val globalCount = 0w10000 : BasicTypes.UInt32

  fun create () =
      {
        sourceExecutableMap = ref SEnv.empty,
        breakPointTable = BreakPointTable.create (),
        heapSize = ref heapSize,
        frameStackSize = ref frameStackSize,
        handlerStackSize = ref handlerStackSize,
        globalCount = ref globalCount,
        arguments = ref []
      } : context

  fun getAllSourceFilesInContext ({sourceExecutableMap, ...} : context) =
      map (fn (name, _) => name) (SEnv.listItemsi (!sourceExecutableMap))

  fun getCodeRefOfSourceLine (context : context) (fileName, lineNo) =
      case SEnv.find (!(#sourceExecutableMap context), fileName) of
        NONE => NONE
      | SOME executables =>
        LocationTable.getCodeRefOfSourceLine executables (fileName, lineNo)

  (***************************************************************************)

end;
