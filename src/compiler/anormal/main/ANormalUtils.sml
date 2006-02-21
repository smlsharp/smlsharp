(**
 * Copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalUtils.sml,v 1.4 2006/02/18 16:04:03 duchuu Exp $
 *)

structure ANormalUtils : ANORMAL_UTILS = struct

  open ANormal

  fun getLocOfExp exp =
      case exp of 
        ANCONSTANT{loc,...} => loc
      | ANVAR{loc,...} => loc
      | ANENVACC{loc,...} => loc
      | ANENVACCINDIRECT{loc,...} => loc
      | ANGETGLOBALVALUE{loc,...} => loc
      | ANSETGLOBALVALUE{loc,...} => loc
      | ANINITARRAYUNBOXED{loc,...} => loc
      | ANINITARRAYBOXED{loc,...} => loc
      | ANINITARRAYDOUBLE{loc,...} => loc
      | ANPRIMAPPLY{loc,...} => loc
      | ANPRIMAPPLY_1{loc,...} => loc
      | ANPRIMAPPLY_2{loc,...} => loc
      | ANFOREIGNAPPLY{loc,...} => loc
      | ANAPPLY{loc,...} => loc
      | ANCALL{loc,...} => loc
      | ANRECORD{loc,...} => loc
      | ANARRAY{loc,...} => loc
      | ANMODIFY{loc,...} => loc
      | ANRAISE{loc,...} => loc
      | ANHANDLE{loc,...} => loc
      | ANCLOSURE{loc,...} => loc
      | ANSWITCH{loc,...} => loc
      | ANLET{loc,...} => loc
      | ANLETLABEL{loc,...} => loc
      | ANVALREC{loc,...} => loc
      | ANRECCALL{loc,...} => loc
      | ANRECCLOSURE{loc,...} => loc
      | ANGETFIELD{loc,...} => loc
      | ANSETFIELD{loc,...} => loc
      | ANFFIVAL{loc,...} => loc
      | ANEXIT loc => loc

end
