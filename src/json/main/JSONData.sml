(**
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 *)
structure JSONData =
struct
local
  structure V = NameEvalEnv
  structure ITy = EvalIty
  structure I = IDCalc
  structure T = Types
  structure TC = TypedCalc
  fun printLongsymbol longsymbol = 
      (print (Symbol.longsymbolToString longsymbol);
       print "\n")
  fun bug s = Bug.Bug ("RefiedTermData:" ^ s)
  val pos = Loc.makePos {fileName="ReifiedTermData.sml", line=0, col=0}
  val loc = (pos,pos)
  fun mkLongsymbol longid = Symbol.mkLongsymbol longid loc

  val stack = ref LongsymbolEnv.empty : IDCalc.exInfo LongsymbolEnv.map ref
  fun insert exInfo = stack := LongsymbolEnv.insert (!stack, #longsymbol exInfo, exInfo)

  fun get name x = 
      case !x of
        NONE => raise Bug.Bug ("JSONData " ^ name ^ " not set")
      | SOME v => v

  fun getVar name x = 
      let
        val exInfo = 
            case !x of
              NONE => raise Bug.Bug ("JSONData " ^ name ^ " not set")
            | SOME v => v
      in
        insert exInfo;
        I.ICEXVAR {exInfo = exInfo, longsymbol = #longsymbol exInfo}
      end

  fun getCon name x = 
      let
        val conInfo = 
            case !x of
              NONE => raise Bug.Bug ("JSONData " ^ name ^ " not set")
            | SOME v => v
      in
        I.ICCON conInfo
      end

in
  fun initExternalDecls () = stack := LongsymbolEnv.empty
  fun getExternDecls () = map (fn exInfo => IDCalc.ICEXTERNVAR exInfo) (LongsymbolEnv.listItems (!stack))

  (* types *)
   val dynTfun = ref NONE : I.tfun option ref
   val jsonTfun = ref NONE : I.tfun option ref
   val jsonTyTfun = ref NONE : I.tfun option ref
   val voidTfun = ref NONE : I.tfun option ref
   val nullTfun = ref NONE : I.tfun option ref

  (* exception *)
   val RuntimeTypeErrorExp = ref NONE : I.icexp option ref

  (* constructor *)
   val DYNConInfo = ref NONE : I.conInfo option ref

   val ARRAYtyConInfo = ref NONE : I.conInfo option ref
   val BOOLtyConInfo = ref NONE : I.conInfo option ref
   val INTtyConInfo = ref NONE : I.conInfo option ref
   val NULLtyConInfo = ref NONE : I.conInfo option ref
   val DYNtyConInfo = ref NONE : I.conInfo option ref
   val RECORDtyConInfo = ref NONE : I.conInfo option ref
   val PARTIALRECORDtyConInfo = ref NONE : I.conInfo option ref
   val REALtyConInfo = ref NONE : I.conInfo option ref
   val STRINGtyConInfo = ref NONE : I.conInfo option ref

   val ARRAYConInfo = ref NONE : I.conInfo option ref
   val BOOLConInfo = ref NONE : I.conInfo option ref
   val INTConInfo = ref NONE : I.conInfo option ref
   val NULLObjectConInfo = ref NONE : I.conInfo option ref
   val OBJECTConInfo = ref NONE : I.conInfo option ref
   val REALConInfo = ref NONE : I.conInfo option ref
   val STRINGConInfo = ref NONE : I.conInfo option ref
 
   val NULLConInfo = ref NONE : I.conInfo option ref
   val VOIDConInfo = ref NONE : I.conInfo option ref

  (* variables *)
   val getJson = ref NONE : I.exInfo option ref
   val checkTy = ref NONE : I.exInfo option ref
   val checkInt = ref NONE : I.exInfo option ref
   val checkReal = ref NONE : I.exInfo option ref
   val checkBool = ref NONE : I.exInfo option ref
   val checkString = ref NONE : I.exInfo option ref
   val checkArray = ref NONE : I.exInfo option ref
   val checkNull = ref NONE : I.exInfo option ref
   val checkDyn = ref NONE : I.exInfo option ref
   val checkRecord = ref NONE : I.exInfo option ref
   val mapCoerce = ref NONE : I.exInfo option ref
   val makeCoerce = ref NONE : I.exInfo option ref

  fun init ({Env, ...}:V.topEnv) =
      let
        fun findCon longid =
            case V.findId(Env, mkLongsymbol longid) of
              SOME (I.IDCON {id, longsymbol, ty}) =>
              SOME {longsymbol=longsymbol, id=id, ty=ty}
            | _ => NONE

        fun findExn longid =
            case V.findId(Env, mkLongsymbol longid) of
              SOME (I.IDEXEXN (exInfo as {longsymbol,...},_)) => 
              SOME (I.ICEXEXN {exInfo=exInfo, longsymbol=longsymbol})
            | SOME (I.IDEXEXNREP (exInfo as {longsymbol,...},_)) => 
              SOME (I.ICEXEXN {exInfo=exInfo, longsymbol=longsymbol})
            | _ => NONE

        fun findVar longid =
            let
              val longsymbol = mkLongsymbol longid
            in
              case V.findId (Env, longsymbol) of
                NONE => NONE
              | SOME (I.IDEXVAR {exInfo,...}) => SOME exInfo
              | SOME _ => NONE
            end

        fun findTfun longid =
            case V.findTstr (Env, mkLongsymbol longid) of
              NONE => NONE
            | SOME (V.TSTR tfun) => SOME tfun
            | SOME (V.TSTR_DTY {tfun, ...}) => SOME tfun

      in
        (* types *)
         dynTfun :=    findTfun ["JSON","dyn"];
         jsonTfun :=   findTfun ["JSON","json"];
         jsonTyTfun := findTfun ["JSON","jsonTy"];
         voidTfun :=   findTfun ["JSON","void"];
         nullTfun :=   findTfun ["JSON","null"];

        (* exception *)
         RuntimeTypeErrorExp :=  findExn ["JSON","RuntimeTypeError"];

        (* constructor *)
         DYNConInfo :=      findCon ["JSON","DYN"];

         ARRAYtyConInfo :=  findCon ["JSON","ARRAYty"];
         BOOLtyConInfo :=   findCon ["JSON","BOOLty"];
         INTtyConInfo :=    findCon ["JSON","INTty"];
         NULLtyConInfo :=   findCon ["JSON","NULLty"];
         DYNtyConInfo :=   findCon ["JSON","DYNty"];
         RECORDtyConInfo := findCon ["JSON","RECORDty"];
         PARTIALRECORDtyConInfo := findCon ["JSON","PARTIALRECORDty"];
         REALtyConInfo :=   findCon ["JSON","REALty"];
         STRINGtyConInfo := findCon ["JSON","STRINGty"];

         ARRAYConInfo :=  findCon ["JSON","ARRAY"];
         BOOLConInfo :=   findCon ["JSON","BOOL"];
         INTConInfo :=    findCon ["JSON","INT"];
         NULLObjectConInfo :=   findCon ["JSON","NULLObject"];
         OBJECTConInfo := findCon ["JSON","OBJECT"];
         REALConInfo :=   findCon ["JSON","REAL"];
         STRINGConInfo := findCon ["JSON","STRING"];

         NULLConInfo := findCon ["JSON","NULL"];
         VOIDConInfo := findCon ["JSON","VOID"];

        (* variables *)
         getJson := findVar ["JSONImpl", "getJson"];
         checkTy := findVar ["JSONImpl", "checkTy"];
         checkInt := findVar ["JSONImpl", "checkInt"];
         checkReal := findVar ["JSONImpl", "checkReal"];
         checkBool := findVar ["JSONImpl", "checkBool"];
         checkString := findVar ["JSONImpl", "checkString"];
         checkArray := findVar ["JSONImpl", "checkArray"];
         checkNull := findVar ["JSONImpl", "checkNull"];
         checkDyn := findVar ["JSONImpl", "checkDyn"]; 
         checkRecord := findVar ["JSONImpl", "checkRecord"]; 
         mapCoerce := findVar ["JSONImpl", "mapCoerce"]; 
         makeCoerce := findVar ["JSONImpl", "makeCoerce"]; 
         ()
      end

   val dynTfun = fn () => get "dynTfun" dynTfun
   val jsonTfun = fn () => get "jsonTfun" jsonTfun
   val jsonTyTfun = fn () => get "jsonTyTfun" jsonTyTfun
   val voidTfun = fn () => get "voidTfun" voidTfun
   val nullTfun = fn () => get "nullTfun" nullTfun

  (* exception *)
   val RuntimeTypeErrorExp = fn () => get "RuntimeErrorExp" RuntimeTypeErrorExp


  (* constructor expression *)
   val DYN = fn () => getCon "DYNConInfo" DYNConInfo

   val ARRAYty = fn () => getCon "ARRAYtyConInfo" ARRAYtyConInfo
   val BOOLty = fn () => getCon "BOOLtyConInfo" BOOLtyConInfo
   val INTty = fn () => getCon "INTtyConInfo" INTtyConInfo
   val NULLty = fn () => getCon "NULLtyConInfo" NULLtyConInfo
   val DYNty = fn () => getCon "DYNtyConInfo" DYNtyConInfo
   val RECORDty = fn () => getCon "RECORDtyConInfo" RECORDtyConInfo
   val PARTIALRECORDty = fn () => getCon "PARTIALRECORDtyConInfo" PARTIALRECORDtyConInfo
   val REALty = fn () => getCon "REALtyConInfo" REALtyConInfo
   val STRINGty = fn () => getCon "STRINGtyConInfo" STRINGtyConInfo

   val ARRAY = fn () => getCon "ARRAYConInfo" ARRAYConInfo
   val BOOL = fn () => getCon "BOOLConInfo" BOOLConInfo
   val INT = fn () => getCon "INTConInfo" INTConInfo
   val NULLObject = fn () => getCon "NULLObjectConInfo" NULLObjectConInfo
   val OBJECT = fn () => getCon "OBJECTConInfo" OBJECTConInfo
   val REAL = fn () => getCon "REALConInfo" REALConInfo
   val STRING = fn () => getCon "STRINGConInfo" STRINGConInfo
 
   val NULL = fn () => getCon "NULLConInfo" NULLConInfo
   val VOID = fn () => getCon "VOIDConInfo" VOIDConInfo

  (* constructor *)
   val DYNConInfo = fn () => get "DYNConInfo" DYNConInfo
   val ARRAYtyConInfo = fn () => get "ARRAYtyConInfo" ARRAYtyConInfo
   val BOOLtyConInfo = fn () => get "BOOLtyConInfo" BOOLtyConInfo
   val INTtyConInfo = fn () => get "INTtyConInfo" INTtyConInfo
   val NULLtyConInfo = fn () => get "NULLtyConInfo" NULLtyConInfo
   val DYNtyConInfo = fn () => get "DYNtyConInfo" DYNtyConInfo
   val RECORDtyConInfo = fn () => get "RECORDtyConInfo" RECORDtyConInfo
   val PARTIALRECORDtyConInfo = fn () => get "PARTIALRECORDtyConInfo" PARTIALRECORDtyConInfo
   val REALtyConInfo = fn () => get "REALtyConInfo" REALtyConInfo
   val STRINGtyConInfo = fn () => get "STRINGtyConInfo" STRINGtyConInfo
   val ARRAYConInfo = fn () => get "ARRAYConInfo" ARRAYConInfo
   val BOOLConInfo = fn () => get "BOOLConInfo" BOOLConInfo
   val INTConInfo = fn () => get "INTConInfo" INTConInfo
   val NULLObjectConInfo = fn () => get "NULLObjectConInfo" NULLObjectConInfo
   val OBJECTConInfo = fn () => get "OBJECTConInfo" OBJECTConInfo
   val REALConInfo = fn () => get "REALConInfo" REALConInfo
   val STRINGConInfo = fn () => get "STRINGConInfo" STRINGConInfo
   val NULLConInfo = fn () => get "NULLConInfo" NULLConInfo
   val VOIDConInfo = fn () => get "VOIDConInfo" VOIDConInfo

  (* variables *)
   val getJson = fn () => getVar "getJson" getJson
   val checkTy = fn () => getVar "checkTy" checkTy
   val checkInt = fn () => getVar "checkInt" checkInt
   val checkReal = fn () => getVar "checkReal" checkReal
   val checkBool = fn () => getVar "checkBool" checkBool
   val checkString = fn () => getVar "checkString" checkString
   val checkArray = fn () => getVar "checkArray" checkArray
   val checkNull = fn () => getVar "checkNull" checkNull
   val checkDyn = fn () => getVar "checkDyn" checkDyn
   val checkRecord = fn () => getVar "checkRecord" checkRecord
   val mapCoerce = fn () => getVar "mapCoerce" mapCoerce
   val makeCoerce = fn () => getVar "makeCoerce" makeCoerce


end
end
