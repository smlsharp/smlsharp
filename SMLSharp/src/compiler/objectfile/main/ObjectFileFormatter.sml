(**
 * pretty printer for the object file.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ObjectFileFormatter.sml,v 1.3 2007/11/19 06:00:02 katsu Exp $
 *)
structure ObjectFileFormatter =
struct

  fun objectFileToString (x : ObjectFile.objectFile) =
      Control.prettyPrint (ObjectFile.format_objectFile x)

end
