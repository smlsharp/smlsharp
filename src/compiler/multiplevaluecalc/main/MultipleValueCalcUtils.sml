(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MultipleValueCalcUtils.sml,v 1.4 2007/06/19 22:19:12 ohori Exp $
 *)
structure MultipleValueCalcUtils : MULTIPLEVALUECALCUTILS = struct
  open MultipleValueCalc

  fun getLocOfExp exp =
      case exp of
        MVFOREIGNAPPLY {loc,...} => loc
      | MVEXPORTCALLBACK {loc,...} => loc
      | MVSIZEOF {loc,...} => loc
      | MVCONSTANT {loc,...} => loc
      | MVEXCEPTIONTAG {loc,...} => loc
      | MVVAR {loc,...} => loc
      | MVGETGLOBAL {loc,...} => loc
      | MVSETGLOBAL {loc,...} => loc
      | MVINITARRAY {loc,...} => loc
      | MVGETFIELD {loc,...} => loc
      | MVSETFIELD {loc,...} => loc
      | MVSETTAIL {loc,...} => loc
      | MVARRAY {loc,...} => loc
      | MVPRIMAPPLY {loc,...} => loc
      | MVAPPM {loc,...} => loc
      | MVLET {loc,...} => loc
      | MVMVALUES {loc,...} => loc
      | MVRECORD {loc,...} => loc
      | MVSELECT {loc,...} => loc
      | MVMODIFY {loc,...} => loc
      | MVRAISE {loc,...} => loc
      | MVHANDLE {loc,...} => loc
      | MVFNM {loc,...} => loc
      | MVPOLY {loc,...} => loc
      | MVTAPP {loc,...} => loc
      | MVSWITCH {loc,...} => loc
      | MVCAST {loc,...} => loc

  fun getLocOfDecl decl =
      case decl of
        MVVAL {loc,...} => loc
      | MVVALREC {loc,...} => loc
      | MVVALPOLYREC {loc,...} => loc

end
