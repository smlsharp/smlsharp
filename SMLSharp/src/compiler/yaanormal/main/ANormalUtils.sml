(**
 * A-Normal form
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalUtils.sml,v 1.4 2008/01/10 04:43:13 katsu Exp $
 *)
structure YAANormalUtils =
struct

  local
    structure AN = YAANormal
  in

  fun getLoc decl =
      case decl of
        AN.ANSETFIELD {loc, ...} => loc
      | AN.ANSETTAIL {loc, ...} => loc
      | AN.ANCOPYARRAY {loc, ...} => loc
      | AN.ANTAILAPPLY {loc, ...} => loc
      | AN.ANTAILCALL {loc, ...} => loc
      | AN.ANTAILRECCALL {loc, ...} => loc
      | AN.ANTAILLOCALCALL {loc, ...} => loc
      | AN.ANRETURN {loc, ...} => loc
      | AN.ANLOCALRETURN {loc, ...} => loc
      | AN.ANVAL {loc, ...} => loc
      | AN.ANVALCODE {loc, ...} => loc
      | AN.ANMERGE {loc, ...} => loc
      | AN.ANMERGEPOINT {loc, ...} => loc
      | AN.ANRAISE {loc, ...} => loc
      | AN.ANHANDLE {loc, ...} => loc
      | AN.ANSWITCH {loc, ...} => loc

  fun funDeclToCodeDecl ({codeId, argVarList, argSizeList, body, resultTyList,
                          ffiAttributes, loc}:AN.funDecl) =
      {
        codeId = codeId,
        argVarList = argVarList,
        argSizeList = argSizeList,
        body = body,
        resultTyList = resultTyList,
        loc = loc
      } : AN.codeDecl

  end

end
