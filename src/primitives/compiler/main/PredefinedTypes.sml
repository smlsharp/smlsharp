(**
 * predefined type constructors and their data constructors.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @version $Id: PredefinedTypes.sml,v 1.9.2.1 2007/03/22 16:30:34 katsu Exp $
 *)
structure PredefinedTypes =
struct

  (***************************************************************************)

  structure C = Constants
  structure P = Path
  structure TP = TypeParser
  structure TU = TypesUtils
  structure TY = Types

  (***************************************************************************)

  local
    val tyConEnvRef = ref SEnv.empty

    fun makeTyCon name tyvars eqKind boxedKind =
        let
          val id = ID.reserve ()
          val tyCon = 
              {
                name = name,
                strpath = P.topStrPath,
                abstract = false,
	        tyvars = tyvars,
                id = id,
	        eqKind = ref eqKind,
                boxedKind = ref boxedKind,
                datacon = ref TY.emptyVarEnv
              } : TY.tyCon
          val tyOpt =
              case tyvars of
                [] => SOME(TY.CONty{tyCon = tyCon, args = []})
              | _ :: _ => NONE
        in
          tyConEnvRef := SEnv.insert (!tyConEnvRef, name, TY.TYCON tyCon);
          (tyCon, id, tyOpt)
        end
  in

  val (boolTyCon, boolTyConid, SOME boolty) =
      makeTyCon "bool" [] TY.EQ TY.ATOMty
  val (intTyCon, intTyConid, SOME intty) =
      makeTyCon "int" [] TY.EQ TY.ATOMty
  val (wordTyCon, wordTyConid, SOME wordty) =
      makeTyCon "word" [] TY.EQ TY.ATOMty
  val (charTyCon, charTyConid, SOME charty) =
      makeTyCon "char" [] TY.EQ TY.ATOMty
  val (stringTyCon, stringTyConid, SOME stringty) =
      makeTyCon "string" [] TY.EQ TY.BOXEDty
  val (realTyCon, realTyConid, SOME realty) =
      makeTyCon "real" [] TY.NONEQ TY.DOUBLEty
  val (floatTyCon, floatTyConid, SOME floatty) =
      makeTyCon "float" [] TY.NONEQ TY.ATOMty
  val (exnTyCon, exnTyConid, SOME exnty) =
      makeTyCon "exn" [] TY.NONEQ TY.BOXEDty
  val (refTyCon, refTyConid, NONE) =
      makeTyCon "ref" [false] TY.EQ TY.BOXEDty
  val (listTyCon, listTyConid, NONE) =
      makeTyCon "list" [false] TY.EQ TY.BOXEDty
  val (arrayTyCon, arrayTyConid, NONE) =
      makeTyCon "array" [false] TY.EQ TY.BOXEDty
  val (largeIntTyCon, largeIntTyConid, SOME largeIntty) =
      makeTyCon "largeInt" [] TY.EQ TY.ATOMty
  val (largeWordTyCon, largeWordTyConid, SOME largeWordty) =
      makeTyCon "largeWord" [] TY.EQ TY.ATOMty
  val (byteTyCon, byteTyConid, SOME bytety) =
      makeTyCon "byte" [] TY.EQ TY.ATOMty
  val (byteArrayTyCon, byteArrayTyConid, SOME byteArrayty) =
      makeTyCon "byteArray" [] TY.EQ TY.BOXEDty
  val (optionTyCon, optionTyConid, NONE) =
      makeTyCon "option" [false] TY.EQ TY.BOXEDty
  val (unitTyCon, unitTyConid, SOME unitty) =
      makeTyCon "unit" [] TY.EQ TY.ATOMty
  val (assocDirectionTyCon, assocDirectionTyConid, SOME assocDirectionty) =
      makeTyCon "assocDirection" [] TY.EQ TY.ATOMty
  val (priorityTyCon, priorityTyConid, SOME priorityty) =
      makeTyCon "priority" [] TY.EQ TY.BOXEDty
  val (expressionTyCon, expressionTyConid, SOME expressionty) =
      makeTyCon "expression" [] TY.EQ TY.BOXEDty

(* the following are for opaque types intended to be used as types of foriegn functions *)
  val (pointerTyCon, pointerTyConid, NONE) =
      makeTyCon "ptr" [false] TY.EQ TY.ATOMty
  val ptrty = TY.CONty{tyCon = pointerTyCon, args = [unitty]}

  val initialTyConEnv = !tyConEnvRef

  end

  (****************************************)

  local
    fun getTyConOfTy (TY.CONty{tyCon, ...}) = tyCon
      | getTyConOfTy ty =
        raise Control.Bug "PredefinedTypes.getTyConOfTy expects CONty"
    fun decompTy (TY.POLYty{body, ...}) = decompTy body
      | decompTy (TY.FUNMty(_, result)) = (true, getTyConOfTy result)
      | decompTy ty = (false, getTyConOfTy ty)

    fun makeValCon name tyString tag =
        let
          val ty = TP.readTy initialTyConEnv tyString
          val (isFunCon, tyCon) = decompTy ty
          val conPathInfo =
              {
                name = name,
                strpath = P.topStrPath,
                funtyCon = isFunCon,
                ty = ty,
                tyCon = tyCon,
                tag = tag
              }
        in
          #datacon tyCon
          := SEnv.insert(!(#datacon tyCon), name, TY.CONID conPathInfo);
          conPathInfo
        end
  in

  val trueCon = makeValCon "true" "bool" C.TAG_bool_true
  val falseCon = makeValCon "false" "bool" C.TAG_bool_false
  val nullCon = makeValCon "_NULL" "['a.('a) ptr]" C.TAG_pointer_null

  val refCon = makeValCon "ref" "['a.'a -> ('a) ref]" C.TAG_ref_ref

  val nilCon = makeValCon "nil" "['a.('a) list]" C.TAG_list_nil
  val consCon =
      makeValCon "::" "['a.'a * ('a) list -> ('a) list]" C.TAG_list_cons

  val NONECon = makeValCon "NONE" "['a.('a) option]" C.TAG_option_NONE
  val SOMECon = makeValCon "SOME" "['a.'a -> ('a) option]" C.TAG_option_SOME

  val BindCon = makeValCon "Bind" "exn" C.TAG_exn_Bind
  val MatchCon = makeValCon "Match" "exn" C.TAG_exn_Match
  val MatchCompBugCon =
      makeValCon "MatchCompBug" "string -> exn" C.TAG_exn_MatchCompBug
  val FormatterCon = makeValCon "Formatter" "string -> exn" C.TAG_exn_Formatter
  val SysErrCon =
      makeValCon "SysErr" "string * (int) option -> exn" C.TAG_exn_SysErr
  val FailCon = makeValCon "Fail" "string -> exn" C.TAG_exn_Fail

  val LeftCon = makeValCon "Left" "assocDirection" 0
  val RightCon = makeValCon "Right" "assocDirection" 1
  val NeutralCon = makeValCon "Neutral" "assocDirection" 2
  val PreferredCon = makeValCon "Preferred" "int -> priority" 0
  val DeferredCon = makeValCon "Deferred" "priority" 1
  val TermCon = makeValCon "Term" "(int * string) -> expression" 0
  val GuardCon =
      makeValCon
          "Guard"
          "({cut:bool,strength:int,direction:assocDirection}) option * (expression) list -> expression"
          1
  val IndicatorCon =
      makeValCon
          "Indicator"
          "{space:bool,newline:({priority:priority}) option} -> expression"
          2
  val StartOfIndentCon = makeValCon "StartOfIndent" "int -> expression" 3
  val EndOfIndentCon = makeValCon "EndOfIndent" "expression" 4

  end

  fun makeExnConPath name strpath tyOpt =
      let
        val exnTag = TY.newExnTag ()
        val (ty, funtyCon) =
            case tyOpt
             of SOME argty => (TY.FUNMty([argty], exnty), true)
              | _ => (exnty, false)
      in
        {
         name = name,
         strpath = strpath,
         funtyCon = funtyCon,
         ty = ty,
         tyCon = exnTyCon,
         tag = exnTag
       }
      end

  (***************************************************************************)
 
end
