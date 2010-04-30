(**
 * Yet another session implementation for batch mode compile without linking.
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: YAStandAloneSessionNoLink.sml,v 1.1 2008/02/08 07:21:57 katsu Exp $
 *)
structure YAStandAloneSessionNoLink : SESSION =
struct

  type InitialParameter =
      {
        baseName: string,
        objectFileList:
          {fileName: string, objectFile: ObjectFile.objectFile} list ref
      }

  fun openSession ({baseName, objectFileList} : InitialParameter) =
      let
        fun execute (SessionTypes.OBJECTFILE objfile) =
            let
              val count = length (!objectFileList)
              val (basename, suffix) =
                  Substring.splitl (fn x => x <> #".") (Substring.full baseName)
              val filename =
                  Substring.concat [basename,
                                    Substring.full ("-"^Int.toString count),
                                    suffix]
              val outputFileChannel =
                  FileChannel.openOut {fileName = filename}
            in
              objectFileList :=
                  (!objectFileList)
                  @ [{fileName = filename, objectFile = objfile}]
            end
          | execute _ = raise Control.Bug "compilation result mismatch"

        fun close () = ()
      in
        {
          execute = execute,
          close = close
        }
      end

end
