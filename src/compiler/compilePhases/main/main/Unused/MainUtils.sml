(**
 * utility functions for file manipulation
 * factored out from Main.sml for using AnalyzeFile (Atsushi Ohori)
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *
 *)

structure MainUtils =
struct
  structure I = InterfaceName
  exception ObjFileNotFound of Filename.filename
  exception SmlFileNotFound of Filename.filename
  fun toSmlFile filename =
      Filename.replaceSuffix "sml" filename
  fun toAsmFile filename =
      Filename.replaceSuffix (Config.ASMEXT ()) filename
  fun toObjFile filename =
      Filename.replaceSuffix (Config.OBJEXT ()) filename
  fun toLLFile filename =
      Filename.replaceSuffix LLVMUtils.ASMEXT filename
  fun toBCFile filename =
      Filename.replaceSuffix LLVMUtils.OBJEXT filename
  fun toExeTarget filename =
      Filename.removeSuffix filename
  fun smiSourceToObjSource {fileMap, ...} ((place, filename):I.source) =
      case place of
        I.STDPATH => (place, toObjFile filename)
      | I.LOCALPATH =>
        case fileMap of
          NONE => (place, toObjFile filename)
        | SOME fileMap =>
          case FilenameMap.find (fileMap (), filename) of
            SOME filename => (place, filename)
          | NONE => raise ObjFileNotFound filename
  fun smiSourceToSmlSource {fileMap, ...} ((place, filename):I.source) =
      case place of
        I.STDPATH => NONE
      | I.LOCALPATH =>
        case fileMap of
          NONE => SOME (place, toSmlFile filename)
        | SOME fileMap =>
          case FilenameMap.find (fileMap (), filename) of
            SOME filename => SOME (place, toSmlFile filename)
          | NONE => raise SmlFileNotFound filename
end
