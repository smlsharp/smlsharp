(**
 * utilities of A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalUtils.sml,v 1.11 2007/09/01 03:21:15 kiyoshiy Exp $
 *)

structure ANormalUtils : ANORMALUTILS = struct

  open ANormal

  fun getLocOfExp exp =
      case exp of 
           ANFOREIGNAPPLY {loc,...} => loc
         | ANEXPORTCALLBACK {loc,...} => loc
         | ANCONSTANT {loc,...} => loc
         | ANPRIMSYMBOL {loc,...} => loc
         | ANEXCEPTIONTAG {loc,...} => loc
         | ANVAR {loc,...} => loc
         | ANENVACC {loc,...} => loc
         | ANLABEL {loc,...} => loc
         | ANGETFIELD {loc,...} => loc
         | ANSETFIELD {loc,...} => loc
         | ANSETTAIL {loc,...} => loc
         | ANARRAY {loc,...} => loc
         | ANCOPYARRAY {loc,...} => loc
         | ANPRIMAPPLY {loc,...} => loc
         | ANAPPLY {loc,...} => loc
         | ANCALL {loc,...} => loc
         | ANRECCALL {loc,...} => loc
         | ANINNERCALL {loc,...} => loc
         | ANLET {loc,...} => loc
         | ANMVALUES {loc,...} => loc
         | ANRECORD {loc,...} => loc
         | ANENVRECORD {loc,...} => loc
         | ANSELECT {loc,...} => loc
         | ANCLOSURE {loc,...} => loc
         | ANRECCLOSURE {loc,...} => loc
         | ANMODIFY {loc,...} => loc
         | ANRAISE {loc,...} => loc
         | ANHANDLE {loc,...} => loc
         | ANSWITCH {loc,...} => loc
         | ANEXIT loc => loc

  fun getLocOfDecl decl =
      case decl of
        ANVAL {loc,...} => loc
      | ANCLUSTER {loc,...} => loc

end
