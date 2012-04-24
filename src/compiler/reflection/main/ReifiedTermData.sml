(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReifiedTermData =
struct
local
  structure BE = BuiltinEnv
  structure V = NameEvalEnv
  structure ITy = EvalIty
  structure I = IDCalc
  structure T = Types
  structure TC = TypedCalc
  fun printPath path = 
      (print (String.concatWith "." path);
       print "\n")
  fun bug s = Control.Bug ("RefiedTermData:" ^ s)
in

  (* types *)
  val reifiedTerm = ref NONE : T.ty option ref
  val idstatus = ref NONE : T.ty option ref
  val tstr = ref NONE : T.ty option ref
  val varE = ref NONE : T.ty option ref
  val tyE =  ref NONE : T.ty option ref
  val env = ref  NONE : T.ty option ref
  val strentry = ref  NONE : T.ty option ref
  val funE = ref  NONE : T.ty option ref
  val sigentry = ref  NONE : T.ty option ref
  val sigE = ref  NONE : T.ty option ref
  val topEnv = ref  NONE : T.ty option ref

  (* variables *)
  val makeArrayTerm = ref NONE : (TC.tpexp * T.ty) option ref
  val makeListTerm = ref NONE : (TC.tpexp * T.ty) option ref
  val makeConsTerm = ref NONE : (TC.tpexp * T.ty) option ref
  val makeFieldTerm = ref NONE : (TC.tpexp * T.ty) option ref
  val makeConsField = ref NONE : (TC.tpexp * T.ty) option ref
  val fieldNil = ref NONE : (TC.tpexp * T.ty) option ref
  val reifiedTermNil = ref NONE : (TC.tpexp * T.ty) option ref
  val makeEXVAR  = ref NONE : (TC.tpexp * T.ty) option ref
  val makeEXEXN = ref NONE : (TC.tpexp * T.ty) option ref
  val makeEXEXNREP = ref NONE : (TC.tpexp * T.ty) option ref
  val makeTstr = ref NONE : (TC.tpexp * T.ty) option ref
  val idstatusNil = ref NONE : (TC.tpexp * T.ty) option ref
  val idstatusCons = ref NONE : (TC.tpexp * T.ty) option ref
  val tstrNil = ref NONE : (TC.tpexp * T.ty) option ref
  val tstrCons = ref NONE : (TC.tpexp * T.ty) option ref
  val makeENV = ref NONE : (TC.tpexp * T.ty) option ref
  val makeStrentry = ref NONE : (TC.tpexp * T.ty) option ref
  val strentryNil = ref NONE : (TC.tpexp * T.ty) option ref
  val strentryCons = ref NONE : (TC.tpexp * T.ty) option ref
  val stringNil = ref NONE : (TC.tpexp * T.ty) option ref
  val stringCons = ref NONE : (TC.tpexp * T.ty) option ref
  val makeSigentry = ref NONE : (TC.tpexp * T.ty) option ref
  val sigentryNil = ref NONE : (TC.tpexp * T.ty) option ref
  val sigentryCons = ref NONE : (TC.tpexp * T.ty) option ref
  val makeReifiedTopenv = ref NONE : (TC.tpexp * T.ty) option ref
  val format_topEnv = ref NONE : (TC.tpexp * T.ty) option ref
  val printTopEnv = ref NONE : (TC.tpexp * T.ty) option ref

  (* constructor *)
  val INTtyRep = ref NONE : T.conInfo option ref
  val BOOLtyRep = ref NONE : T.conInfo option ref
  val INTINFtyRep = ref NONE : T.conInfo option ref
  val WORDtyRep = ref NONE : T.conInfo option ref
  val WORD8tyRep = ref NONE : T.conInfo option ref
  val CHARtyRep = ref NONE : T.conInfo option ref
  val STRINGtyRep = ref NONE : T.conInfo option ref
  val REALtyRep = ref NONE : T.conInfo option ref
  val REAL32tyRep = ref NONE : T.conInfo option ref
  val UNITtyRep = ref NONE : T.conInfo option ref
  val FUNtyRep = ref NONE : T.conInfo option ref
  val RECORDtyRep = ref NONE : T.conInfo option ref
  val TUPLEtyRep = ref NONE : T.conInfo option ref
  val LISTtyRep = ref NONE : T.conInfo option ref
  val ARRAYtyRep = ref NONE : T.conInfo option ref
  val CONSTRUCTtyRep = ref NONE : T.conInfo option ref
  val EXNtyRep = ref NONE : T.conInfo option ref
  val PTRtyRep = ref NONE : T.conInfo option ref
  val UNPRINTABLERep = ref NONE : T.conInfo option ref
  val BUILTINRep = ref NONE : T.conInfo option ref
  val EXVAR  = ref NONE : T.conInfo option ref
  val EXEXN = ref NONE : T.conInfo option ref
  val EXEXNREP = ref NONE : T.conInfo option ref
  val ENV = ref NONE : T.conInfo option ref

  fun init ({Env, ...}:V.topEnv) =
      let
        fun findCon path =
            case V.findId(Env, path) of
              SOME (I.IDCON {id, ty}) =>
              let
                val ty = ITy.evalIty ITy.emptyContext ty 
              in
                SOME {path=path, id=id, ty=ty}
              end
            | _ => 
              (printPath path;
               raise bug "con not found"
              )
        fun findVar path =
            case V.findId (Env, path) of
              NONE => (printPath path;
                       raise bug "map not found (1)"
                      )
            | SOME (I.IDEXVAR {path, ty, version, loc,...}) => 
              let
                val path = I.setVersion(path, version)
                val ty = ITy.evalIty ITy.emptyContext ty
                    handle e => 
                      (printPath path;
                       raise bug "map not found (2)"
                      )
              in
                SOME (TC.TPEXVAR ({path=path, ty=ty},loc), ty)
              end
            | SOME _ => 
              (printPath path;
               raise bug "map not found (3)"
              )
        fun findTy path =
            let
              val tfun = 
                  case V.findTstr (Env,path) of
                    NONE => 
                    (printPath path;
                     raise bug "reifiedTerm tyCon not found"
                    )
                  | SOME (V.TSTR tfun) => tfun
                  | SOME (V.TSTR_DTY {tfun, ...}) => tfun
              val ity = I.TYCONSTRUCT {typ={path=path, tfun=tfun}, args=nil}
              val ty = ITy.evalIty ITy.emptyContext ity
            in
              SOME ty
            end
      in
        (* types *)
         reifiedTerm := findTy ["ReifiedTerm","reifiedTerm"];
         idstatus := findTy ["ReifiedTerm","idstatus"];
         tstr := findTy ["ReifiedTerm","tstr"];
         varE := findTy ["ReifiedTerm","varE"];
         tyE := findTy ["ReifiedTerm","tyE"];
         env := findTy ["ReifiedTerm","env"];
         strentry := findTy ["ReifiedTerm","strentry"];
         funE := findTy ["ReifiedTerm","funE"];
         sigentry := findTy ["ReifiedTerm","sigentry"];
         sigE := findTy ["ReifiedTerm","sigE"];
         topEnv := findTy ["ReifiedTerm","topEnv"];

        (* variables *)
         makeArrayTerm := findVar ["ReifiedTerm","makeArrayTerm"];
         makeListTerm := findVar ["ReifiedTerm","makeListTerm"];
         makeConsTerm := findVar ["ReifiedTerm","makeConsTerm"];
         makeFieldTerm := findVar ["ReifiedTerm","makeFieldTerm"];
         makeConsField := findVar ["ReifiedTerm","makeConsField"];
         fieldNil := findVar ["ReifiedTerm","fieldNil"];
         reifiedTermNil := findVar ["ReifiedTerm","reifiedTermNil"];
         makeEXVAR := findVar ["ReifiedTerm","makeEXVAR"];
         makeEXEXN := findVar ["ReifiedTerm","makeEXEXN"];
         makeEXEXNREP := findVar ["ReifiedTerm","makeEXEXNREP"];
         makeTstr := findVar ["ReifiedTerm","makeTstr"];
         idstatusNil := findVar ["ReifiedTerm","idstatusNil"];
         idstatusCons := findVar ["ReifiedTerm","idstatusCons"];
         tstrNil := findVar ["ReifiedTerm","tstrNil"];
         tstrCons := findVar ["ReifiedTerm","tstrCons"];
         makeENV := findVar ["ReifiedTerm","makeENV"];
         makeStrentry := findVar ["ReifiedTerm","makeStrentry"];
         strentryNil := findVar ["ReifiedTerm","strentryNil"];
         strentryCons := findVar ["ReifiedTerm","strentryCons"];
         stringNil := findVar ["ReifiedTerm","stringNil"];
         stringCons := findVar ["ReifiedTerm","stringCons"];
         makeSigentry := findVar ["ReifiedTerm","makeSigentry"];
         sigentryNil := findVar ["ReifiedTerm","sigentryNil"];
         sigentryCons := findVar ["ReifiedTerm","sigentryCons"];
         makeReifiedTopenv := findVar ["ReifiedTerm","makeReifiedTopenv"];
         format_topEnv := findVar ["ReifiedTerm","format_topEnv"];
         printTopEnv := findVar ["ReifiedTerm","printTopEnv"];

        (* constructor *)
         INTtyRep := findCon ["ReifiedTerm","INTtyRep"];
         BOOLtyRep := findCon ["ReifiedTerm","BOOLtyRep"];
         INTINFtyRep := findCon ["ReifiedTerm","INTINFtyRep"];
         WORDtyRep := findCon ["ReifiedTerm","WORDtyRep"];
         WORD8tyRep := findCon ["ReifiedTerm","WORD8tyRep"];
         CHARtyRep := findCon ["ReifiedTerm","CHARtyRep"];
         STRINGtyRep := findCon ["ReifiedTerm","STRINGtyRep"];
         REALtyRep := findCon ["ReifiedTerm","REALtyRep"];
         REAL32tyRep := findCon ["ReifiedTerm","REAL32tyRep"];
         UNITtyRep := findCon ["ReifiedTerm","UNITtyRep"];
         FUNtyRep := findCon ["ReifiedTerm","FUNtyRep"];
         RECORDtyRep := findCon ["ReifiedTerm","RECORDtyRep"];
         TUPLEtyRep := findCon ["ReifiedTerm","TUPLEtyRep"];
         LISTtyRep := findCon ["ReifiedTerm","LISTtyRep"];
         ARRAYtyRep := findCon ["ReifiedTerm","ARRAYtyRep"];
         CONSTRUCTtyRep := findCon ["ReifiedTerm","CONSTRUCTtyRep"];
         EXNtyRep := findCon ["ReifiedTerm","EXNtyRep"];
         PTRtyRep := findCon ["ReifiedTerm","PTRtyRep"];
         UNPRINTABLERep := findCon ["ReifiedTerm","UNPRINTABLERep"];
         BUILTINRep := findCon ["ReifiedTerm","BUILTINRep"];
         EXVAR := findCon ["ReifiedTerm","EXVAR"];
         EXEXN := findCon ["ReifiedTerm","EXEXN"];
         EXEXNREP := findCon ["ReifiedTerm","EXEXNREP"];
         ENV := findCon ["ReifiedTerm","ENV"]
      end

  fun mkConTerm (con, exp) =
      TC.TPDATACONSTRUCT 
        {con=con, instTyList=nil, argExpOpt=exp, loc= Loc.noloc}

  fun unprintable () = 
      case !UNPRINTABLERep of
        NONE => raise bug "unprintable unavailable"
      | SOME con => mkConTerm(con, NONE)

  fun builtin () = 
      case !BUILTINRep of
        NONE => raise bug "unprintable unavailable"
      | SOME con => mkConTerm(con, NONE)

  fun mkINTtyRepTerm exp = 
      case !INTtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkBOOLtyRepTerm exp = 
      case !BOOLtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkINTINFtyRepTerm exp = 
      case !INTINFtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkWORDtyRepTerm exp =
      case !WORDtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,SOME exp)

  fun mkWORD8tyRepTerm exp =
      case !WORD8tyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkCHARtyRepTerm exp =
      case !CHARtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,SOME exp)

  fun mkSTRINGtyRepTerm exp =
      case !STRINGtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkREALtyRepTerm exp =
      case !REALtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,SOME exp)

  fun mkREAL32tyRepTerm exp =
      case !REAL32tyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkUNITtyRepTerm () =
      case !UNITtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,NONE)

  fun mkFUNtyRepTerm () =
      case !FUNtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,NONE)

  fun mkRECORDtyRepTerm exp =
      case !RECORDtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkTUPLEtyRepTerm exp =
      case !TUPLEtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkLISTtyRepTerm exp =
      case !LISTtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,SOME exp)

  fun mkARRAYtyRepTerm exp =
      case !ARRAYtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,SOME exp)

  fun mkCONSTRUCTtyRepTerm exp =
      case !CONSTRUCTtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, SOME exp)

  fun mkEXNtyRepTerm () =
      case !EXNtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con,NONE)

  fun mkPTRtyRepTerm () =
      case !PTRtyRep of
        NONE => unprintable()
      | SOME con => mkConTerm(con, NONE)

end
end
