(**
 * A-Normal optimization
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalOptimization.sml,v 1.21 2008/08/06 17:23:41 ohori Exp $
 *
 * This module performs the following optimizations.
 * - constant foldling (optimizePRIMAPPLY)
 * - constant propagation
 * - replace APPLY with either CALL or RECCALL as many as possible
 * - replace RECTAILCALL to TAILLOCALCALL as many as possible
 *
 * These optimizations are needed to generate much cleaner CFG at the
 * next phase.
 *
 * Constant folding and propagation is effective to inhibit generating
 * explicit loops which are arised from several ANormal terms including
 * implicit loop.
 *
 * Replacing RECTAILCALL with TAILLOCALCALL is much more effective;
 * RECTAILCALL will be translated to costly call instruction, but
 * TAILLOCALCALL will be translated to unconditional jump instruction.
 *
 * Replacing APPLY with RECCALL is a preparation for replacing RECTAILCALL
 * with TAILLOCALCALL.
 *
 * Any other optimizations such as
 * - copy propagation,
 * - dead code elimination,
 * - simplification, and
 * are not needed here since they never affect to CFG generation.
 * Later optimization phase can do them better.
 *
 * Doing efficient copy propagation with keeping semantics of program
 * is not so easy if the program includes MERGEPOINT. For example:
 *
 * switch x
 *   case 0:
 *     let w = call()
 *     let y = w
 *     let z = y      <--- can replace this y with w
 *     MERGE m1 z
 *   default:
 *     raise
 * MERGEPOINT m1 z =>
 * let t = z          <--- cannot replace this z with w
 *                         while z is always equal to w,
 *                         because w is unbound here.
 *
 * Anyway, later optimization phase do the same thing much better.
 *)
structure YAANormalOptimization : YAANORMALOPTIMIZATION =
struct
  structure ID = VarID
  structure CT = ConstantTerm
  structure AN = YAANormal
  structure P = BuiltinPrimitive
  structure Float = Real

  fun optimizePRIMAPPLY (args as {prim, argList, argTyList, ...}) =
      let
        fun intOf (AN.ANINT v) = SOME v
          | intOf _ = NONE
        fun genericIntOf (AN.ANINT v) =
            SOME (BasicTypes.SInt32ToInt v)
          | genericIntOf _ = NONE
        fun wordOf (AN.ANWORD v) = SOME v
          | wordOf _ = NONE
        fun genericWordOf (AN.ANWORD v) =
            SOME (BasicTypes.UInt32ToWord v)
          | genericWordOf _ = NONE
(*
        fun realOf (AN.ANCONST (CT.REAL v)) =
            (
             case Real.fromString v of
               SOME real => SOME real
             | NONE => NONE
            )
          | realOf _ = NONE
        fun floatOf (AN.ANCONST (CT.FLOAT v)) =
            (
             case Real.fromString v of
               SOME real => SOME real
             | NONE => NONE
            )
          | floatOf _ = NONE
*)
        fun charOf (AN.ANCHAR v) = SOME v
          | charOf _ = NONE
        fun byteOf (AN.ANWORD v) = SOME v
          | byteOf _ = NONE
        fun boolOf (AN.ANINT v) =
            if v = 0
            then SOME false
            else SOME true
          | boolOf _ = NONE
(*
        fun stringOf (AN.ANCONST (CT.STRING v)) = SOME v
          | stringOf _ = NONE
*)

        fun intToExp v = AN.ANINT v
        fun genericIntToExp v =
            AN.ANINT (BasicTypes.SInt32.fromInt v)
        fun wordToExp v = AN.ANWORD v
        fun genericWordToExp v =
            AN.ANWORD (BasicTypes.WordToUInt32 v)
(*
        fun realToExp v = AN.ANCONSTANT (CT.REAL (Real.toString v))
        fun floatToExp v = AN.ANCONSTANT (CT.FLOAT (Real.toString v))
*)
        fun charToExp v = AN.ANCHAR v
        fun byteToExp v = AN.ANWORD v
        fun boolToExp v =
            if v
            then AN.ANINT 1
            else AN.ANINT 0
(*
        fun stringToExp v = AN.ANCONSTANT (CT.STRING v)
*)

        exception NoOptimize

        fun optimize1 argConv resConv operator =
            case argList of
              [arg] =>
              (
               case argConv arg of
                 SOME v => resConv (operator v)
               | _ => raise NoOptimize
              )
            | _ => raise NoOptimize

        fun optimize2 arg1Conv arg2Conv resConv operator =
            case argList of
              [arg1,arg2] =>
              (
               case (arg1Conv arg1,arg2Conv arg2) of
                 (SOME v1,SOME v2) => resConv (operator(v1,v2))
               | _ => raise NoOptimize
              )
            | _ => raise NoOptimize

        fun optimize3 arg1Conv arg2Conv arg3Conv resConv operator =
            case argList of
              [arg1,arg2,arg3] =>
              (
               case (arg1Conv arg1,arg2Conv arg2,arg3Conv arg3) of
                 (SOME v1,SOME v2,SOME v3) => resConv (operator(v1,v2,v3))
               | _ => raise NoOptimize
              )
            | _ => raise NoOptimize

        val anvalue =
          SOME (
            case (prim, argList) of
              (P.Int_add _,[AN.ANINT 0,arg2]) => arg2
            | (P.Int_add _,[arg1,AN.ANINT 0]) => arg1
            | (P.Int_add _, _) => optimize2 intOf intOf intToExp ( op + ) 
            | (P.Word_add,[AN.ANWORD 0w0,arg2]) => arg2
            | (P.Word_add,[arg1,AN.ANWORD 0w0]) => arg1
            | (P.Word_add, _) => optimize2 wordOf wordOf wordToExp ( op + ) 
(*
            | (P.Real_add, _) => optimize2 realOf realOf realToExp ( op + ) 
            | (P.Float_add, _) => optimize2 floatOf floatOf floatToExp ( op + ) 
*)
            | (P.Byte_add,[AN.ANWORD 0w0,arg2]) => arg2
            | (P.Byte_add,[arg1,AN.ANWORD 0w0]) => arg1
            | (P.Byte_add, _) => optimize2 byteOf byteOf byteToExp ( op + ) 
                                 
            | (P.Int_sub _,[arg1,AN.ANINT 0]) => arg1
            | (P.Int_sub _, _) => optimize2 intOf intOf intToExp ( op - ) 
            | (P.Word_sub,[arg1,AN.ANWORD 0w0]) => arg1
            | (P.Word_sub, _) => optimize2 wordOf wordOf wordToExp ( op - ) 
(*
            | (P.Real_sub, _) => optimize2 realOf realOf realToExp ( op - ) 
            | (P.Float_sub, _) => optimize2 floatOf floatOf floatToExp ( op - ) 
*)
            | (P.Byte_sub,[arg1,AN.ANWORD 0w0]) => arg1
            | (P.Byte_sub, _) => optimize2 byteOf byteOf byteToExp ( op - ) 
                                 
            | (P.Int_mul _,[arg1 as AN.ANINT 0,arg2]) => arg1
            | (P.Int_mul _,[arg1 as AN.ANINT 1,arg2]) => arg2
            | (P.Int_mul _,[arg1,arg2 as AN.ANINT 0]) => arg2
            | (P.Int_mul _,[arg1,arg2 as AN.ANINT 1]) => arg1
            | (P.Int_mul _, _) => optimize2 intOf intOf intToExp ( op * ) 
            | (P.Word_mul,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_mul,[arg1 as AN.ANWORD 0w1,arg2]) => arg2
            | (P.Word_mul,[arg1,arg2 as AN.ANWORD 0w0]) => arg2
            | (P.Word_mul,[arg1,arg2 as AN.ANWORD 0w1]) => arg1
            | (P.Word_mul, _) => optimize2 wordOf wordOf wordToExp ( op * ) 
(*
            | (P.Real_mul, _) => optimize2 realOf realOf realToExp ( op * ) 
            | (P.Float_mul, _) => optimize2 floatOf floatOf floatToExp ( op * ) 
*)
            | (P.Byte_mul,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Byte_mul,[arg1 as AN.ANWORD 0w1,arg2]) => arg2
            | (P.Byte_mul,[arg1,arg2 as AN.ANWORD 0w0]) => arg2
            | (P.Byte_mul,[arg1,arg2 as AN.ANWORD 0w1]) => arg1
            | (P.Byte_mul, _) => optimize2 byteOf byteOf byteToExp ( op * ) 
                                 
            | (P.Int_div _,[arg1 as AN.ANINT 0,arg2]) => arg1
            | (P.Int_div _, _) => optimize2 intOf intOf intToExp ( op div ) 
            | (P.Word_div,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_div, _) => optimize2 wordOf wordOf wordToExp ( op div ) 
(*
            | (P.Real_div, _) => optimize2 realOf realOf realToExp ( op / ) 
            | (P.Float_div, _) => optimize2 floatOf floatOf floatToExp ( op / ) 
*)
            | (P.Byte_div,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Byte_div, _) => optimize2 byteOf byteOf byteToExp ( op div ) 
                                 
            | (P.Int_mod _,[arg1 as AN.ANINT 0,arg2]) => arg1
            | (P.Int_mod _, _) => optimize2 intOf intOf intToExp ( op mod ) 
            | (P.Word_mod,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_mod, _) => optimize2 wordOf wordOf wordToExp ( op mod ) 
            | (P.Byte_mod,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Byte_mod, _) => optimize2 byteOf byteOf byteToExp ( op mod ) 
                                 
            | (P.Int_quot _, _) => optimize2 intOf intOf intToExp ( Int32.quot ) 
            | (P.Int_rem _, _) => optimize2 intOf intOf intToExp ( Int32.rem ) 
                                  
            | (P.Int_neg _, _) => optimize1 intOf intToExp ~  
(*
            | (P.Real_neg, _) => optimize1 realOf realToExp ~ 
            | (P.Float_neg, _) => optimize1 floatOf floatToExp ~ 
*)
                                  
            | (P.Int_lt, _) => optimize2 intOf intOf boolToExp ( op < ) 
            | (P.Word_lt, _) => optimize2 wordOf wordOf boolToExp ( op < ) 
(*
            | (P.Real_lt, _) => optimize2 realOf realOf boolToExp ( op < ) 
            | (P.Float_lt, _) => optimize2 floatOf floatOf boolToExp ( op < ) 
*)
            | (P.Byte_lt, _) => optimize2 byteOf byteOf boolToExp ( op < ) 
            | (P.Char_lt, _) => optimize2 charOf charOf boolToExp ( op < ) 
(*
            | (P.RuntimePrim "ltString", _) => optimize2 stringOf stringOf boolToExp ( op < ) 
*)
                                               
            | (P.Int_gt, _) => optimize2 intOf intOf boolToExp ( op > ) 
            | (P.Word_gt, _) => optimize2 wordOf wordOf boolToExp ( op > ) 
(*
            | (P.Real_gt, _) => optimize2 realOf realOf boolToExp ( op > ) 
            | (P.Float_gt, _) => optimize2 floatOf floatOf boolToExp ( op > ) 
*)
            | (P.Byte_gt, _) => optimize2 byteOf byteOf boolToExp ( op > ) 
            | (P.Char_gt, _) => optimize2 charOf charOf boolToExp ( op > ) 
(*
            | (P.String_gt, _) => optimize2 stringOf stringOf boolToExp ( op > ) 
*)
                                               
            | (P.Int_lteq, _) => optimize2 intOf intOf boolToExp ( op <= ) 
            | (P.Word_lteq, _) => optimize2 wordOf wordOf boolToExp ( op <= ) 
(*
            | (P.Real_lteq, _) => optimize2 realOf realOf boolToExp ( op <= ) 
            | (P.Float_lteq, _) => optimize2 floatOf floatOf boolToExp ( op <= ) 
*)
            | (P.Byte_lteq, _) => optimize2 byteOf byteOf boolToExp ( op <= ) 
            | (P.Char_lteq, _) => optimize2 charOf charOf boolToExp ( op <= ) 
(*
            | (P.String_lteq, _) => optimize2 stringOf stringOf boolToExp ( op <= ) 
*)
                                                 
            | (P.Int_gteq, _) => optimize2 intOf intOf boolToExp ( op >= ) 
            | (P.Word_gteq, _) => optimize2 wordOf wordOf boolToExp ( op >= ) 
(*
            | (P.Real_gteq, _) => optimize2 realOf realOf boolToExp ( op >= ) 
            | (P.Float_gteq, _) => optimize2 floatOf floatOf boolToExp ( op >= ) 
*)
            | (P.Byte_gteq, _) => optimize2 byteOf byteOf boolToExp ( op >= ) 
            | (P.Char_gteq, _) => optimize2 charOf charOf boolToExp ( op >= ) 
(*
            | (P.String_gteq, _) => optimize2 stringOf stringOf boolToExp ( op >= )
*)
                                                 
            | (P.Word_toIntX, _) => optimize1 wordOf intToExp (Int32.fromLarge o Word32.toLargeIntX)          
            | (P.Word_fromInt, _) => optimize1 intOf wordToExp (Word32.fromLargeInt o Int32.toLarge)          
                                     
            | (P.Word_andb,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_andb,[arg1,arg2 as AN.ANWORD 0w0]) => arg2
            | (P.Word_andb, _) => optimize2 wordOf wordOf wordToExp ( Word32.andb ) 
                                  
            | (P.Word_orb,[arg1 as AN.ANWORD 0w0,arg2]) => arg2
            | (P.Word_orb,[arg1,arg2 as AN.ANWORD 0w0]) => arg1
            | (P.Word_orb, _) => optimize2 wordOf wordOf wordToExp ( Word32.orb ) 
                                 
            | (P.Word_xorb, _) => optimize2 wordOf wordOf wordToExp ( Word32.xorb ) 
            | (P.Word_notb, _) => optimize1 wordOf wordToExp ( Word32.notb ) 
                                  
            | (P.Word_lshift,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_lshift,[arg1,arg2 as AN.ANWORD 0w0]) => arg1
            | (P.Word_lshift, _) => optimize2 wordOf genericWordOf wordToExp ( Word32.<< ) 
                                    
            | (P.Word_rshift,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_rshift,[arg1,arg2 as AN.ANWORD 0w0]) => arg1
            | (P.Word_rshift, _) => optimize2 wordOf genericWordOf wordToExp ( Word32.>> ) 
                                    
            | (P.Word_arshift,[arg1 as AN.ANWORD 0w0,arg2]) => arg1
            | (P.Word_arshift,[arg1,arg2 as AN.ANWORD 0w0]) => arg1
            | (P.Word_arshift, _) => optimize2 wordOf genericWordOf wordToExp ( Word32.~>> ) 
                                     
(*
            | (P.RuntimePrim "Int_toString", _) => optimize1 intOf stringToExp (Int32.toString)          
            | (P.RuntimePrim "Word_toString", _) => optimize1 wordOf stringToExp (Word32.toString)       
                                                    
            | (P.Real_fromInt, _) => optimize1 intOf realToExp (Real.fromLargeInt o Int32.toLarge)             
            | (P.RuntimePrim "Real_toString", _) => optimize1 realOf stringToExp (Real.toString)       
            | (P.Real_floor _, _) => optimize1 realOf genericIntToExp (Real.floor)
            | (P.Real_ceil _, _) => optimize1 realOf genericIntToExp (Real.ceil)
            | (P.Real_trunc _, _) => optimize1 realOf genericIntToExp (Real.trunc)
            | (P.Real_round _, _) => optimize1 realOf genericIntToExp (Real.round)
                                     
            | (P.Float_fromInt, _) => optimize1 intOf floatToExp (Float.fromLargeInt o Int32.toLarge)             
            | (P.RuntimePrim "Float_toString", _) => optimize1 floatOf stringToExp (Float.toString)       
            | (P.Float_floor _, _) => optimize1 floatOf genericIntToExp (Float.floor)
            | (P.Float_ceil _, _) => optimize1 floatOf genericIntToExp (Float.ceil)
            | (P.Float_trunc _, _) => optimize1 floatOf genericIntToExp (Float.trunc)
            | (P.Float_round _, _) => optimize1 floatOf genericIntToExp (Float.round)
                                      
            | (P.RuntimePrim "Char_toString", _) => optimize1 charOf stringToExp (Char.toString)       
*)
            | (P.Char_ord, _) => optimize1 charOf genericIntToExp (Char.ord)       
            | (P.Char_chr_unsafe, _) => optimize1 genericIntOf charToExp (Char.chr)
                                 
(*
            | (P.RuntimePrim "String_concat2", _) => optimize2 stringOf stringOf stringToExp ( op ^ )        
            | (P.String_sub, _) => optimize2 stringOf genericIntOf charToExp ( String.sub )        
            | (P.String_size, _) => optimize1 stringOf genericIntToExp ( String.size )        
            | (P.RuntimePrim "String_substring", _) => optimize3 stringOf genericIntOf genericIntOf stringToExp ( String.substring )        
                                                       
            | (P.RuntimePrim "Math_sqrt", _) => optimize1 realOf realToExp ( Math.sqrt )
            | (P.RuntimePrim "Math_sin", _) => optimize1 realOf realToExp ( Math.sin )
            | (P.RuntimePrim "Math_cos", _) => optimize1 realOf realToExp ( Math.cos )
            | (P.RuntimePrim "Math_tan", _) => optimize1 realOf realToExp ( Math.tan )
            | (P.RuntimePrim "Math_asin", _) => optimize1 realOf realToExp ( Math.asin )
            | (P.RuntimePrim "Math_acos", _) => optimize1 realOf realToExp ( Math.acos )
            | (P.RuntimePrim "Math_atan", _) => optimize1 realOf realToExp ( Math.atan )
            | (P.RuntimePrim "Math_atan2", _) => optimize2 realOf realOf realToExp ( Math.atan2 )
            | (P.RuntimePrim "Math_exp", _) => optimize1 realOf realToExp ( Math.exp )
            | (P.RuntimePrim "Math_pow", _) => optimize2 realOf realOf realToExp ( Math.pow )
            | (P.RuntimePrim "Math_ln", _) => optimize1 realOf realToExp ( Math.ln )
            | (P.RuntimePrim "Math_log10", _) => optimize1 realOf realToExp ( Math.log10 )
            | (P.RuntimePrim "Math_sinh", _) => optimize1 realOf realToExp ( Math.sinh )
            | (P.RuntimePrim "Math_cosh", _) => optimize1 realOf realToExp ( Math.cosh )
            | (P.RuntimePrim "Math_tanh", _) => optimize1 realOf realToExp ( Math.tanh )
*)

            | _ => raise NoOptimize
        ) handle _ => NONE
      in
        case anvalue of
          SOME value => AN.ANVALUE value
        | NONE => AN.ANPRIMAPPLY args
      end

  fun optimizeSWITCH (exp as AN.ANSWITCH {value, valueTy, default,
                                          branches, loc}) =
      let
        val const =
            case value of
              AN.ANINT x => SOME (CT.INT x)
            | AN.ANWORD x => SOME (CT.WORD x)
            | AN.ANBYTE x => SOME (CT.BYTE x)
            | AN.ANCHAR x => SOME (CT.CHAR x)
            | AN.ANUNIT => SOME (CT.UNIT)
            | _ => NONE
      in
        case const of
          SOME switchValue =>
          let
            fun optimizeBranches [] = default
              | optimizeBranches ({constant=AN.ANCONST const,branch}::rest) =
                (
                  case CT.compare(switchValue, const) of
                    EQUAL => branch
                  | _ => optimizeBranches rest
                )
              | optimizeBranches (h::t) =
                raise Control.Bug "optimizeSWITCH"
          in
            optimizeBranches branches
          end
        | NONE => [exp]
      end
    | optimizeSWITCH _ = raise Control.Bug "invalid switch"

  (*********************************************************************)

  type context =
      {
        entryFunctions: AN.funDecl ID.Map.map
      }

  fun addDef varList anexp env =
      foldl (fn ({id, ...}:AN.varInfo, env) =>
                case ID.Map.find (env, id) of
                  SOME l => ID.Map.insert (env, id, anexp::l)
                | NONE => ID.Map.insert (env, id, [anexp]))
            env
            varList

  fun getDefs env anvalue =
      case anvalue of
        AN.ANVAR varInfo =>
        (case ID.Map.find (env, #id varInfo) of
           NONE => [AN.ANVALUE anvalue]  (* no definition *)
         | SOME l =>
           foldl (fn (AN.ANVALUE value, z) => getDefs env value @ z
                   | (exp, z) => exp :: z)
                 nil l)
      | _ => [AN.ANVALUE anvalue]

  fun valueEq (AN.ANINT c1, AN.ANINT c2) = c1 = c2
    | valueEq (AN.ANWORD c1, AN.ANWORD c2) = c1 = c2
    | valueEq (AN.ANBYTE c1, AN.ANBYTE c2) = c1 = c2
    | valueEq (AN.ANCHAR c1, AN.ANCHAR c2) = c1 = c2
    | valueEq (AN.ANUNIT, AN.ANUNIT) = true
    | valueEq (AN.ANVAR v1, AN.ANVAR v2) = ID.eq (#id v1, #id v2)
    | valueEq (AN.ANLABEL l1, AN.ANLABEL l2) = ID.eq (l1, l2)
    | valueEq (AN.ANTOPSYMBOL {name=name1,...},
               AN.ANTOPSYMBOL {name=name2,...}) = name1 = name2
    | valueEq _ = false

  fun closureEq (AN.ANCLOSURE {funLabel = funLabel1, env = env1},
                 AN.ANCLOSURE {funLabel = funLabel2, env = env2}) =
      valueEq (funLabel1, funLabel2) andalso valueEq (env1, env2)
    | closureEq (AN.ANRECCLOSURE {funLabel = funLabel1},
                 AN.ANRECCLOSURE {funLabel = funLabel2}) =
      valueEq (funLabel1, funLabel2)
    | closureEq _ = false

  fun substVar subst (varInfo as {id, ...}:AN.varInfo) =
      case ID.Map.find (subst, id) of
        SOME v => v
      | NONE => varInfo

  fun propValue env subst anvalue =
      case getDefs env anvalue of
        (AN.ANVALUE v1)::t =>
        if List.all (fn AN.ANVALUE v2 => valueEq (v1, v2) | _ => false) t
        then v1
        else anvalue
      | _ => anvalue

  fun optimizeAPPLY env (args as {closure, argList, argTyList, resultTyList}) =
      case getDefs env closure of
        h::t =>
        if List.all (fn x => closureEq (h, x)) t
        then
          case h of
            AN.ANCLOSURE {funLabel, env} =>
            AN.ANCALL {funLabel = funLabel,
                       env = env,
                       argList = argList,
                       argTyList = argTyList,
                       resultTyList = resultTyList}
          | AN.ANRECCLOSURE {funLabel} =>
            AN.ANRECCALL {funLabel = funLabel,
                          argList = argList,
                          argTyList = argTyList,
                          resultTyList = resultTyList}
          | _ => AN.ANAPPLY args
        else
          AN.ANAPPLY args
      | nil => AN.ANAPPLY args

  fun optimizeTAILRECCALL ({entryFunctions, ...}:context)
                          (args as {funLabel, argList,
                                    argTyList, resultTyList, loc}) =
      case funLabel of
        AN.ANLABEL funLabel =>
        (case ID.Map.find (entryFunctions, funLabel) of
           SOME _ =>
           AN.ANTAILLOCALCALL {codeLabel = AN.ANLOCALCODE funLabel,
                               argList = argList,
                               argTyList = argTyList,
                               resultTyList = resultTyList,
                               loc = loc,
                               knownDestinations = ref nil}
         | NONE => AN.ANTAILRECCALL args)
      | _ => AN.ANTAILRECCALL args

  fun optimizeTAILAPPLY context env
                        (args as {closure, argList, argTyList,
                                  resultTyList, loc}) =
      case getDefs env closure of
        h::t =>
        if List.all (fn x => closureEq (h, x)) t
        then
          case h of
            AN.ANCLOSURE {funLabel, env} =>
            AN.ANTAILCALL {funLabel = funLabel,
                           env = env,
                           argList = argList,
                           argTyList = argTyList,
                           resultTyList = resultTyList,
                           loc = loc}
          | AN.ANRECCLOSURE {funLabel} =>
            optimizeTAILRECCALL context {funLabel = funLabel,
                                         argList = argList,
                                         argTyList = argTyList,
                                         resultTyList = resultTyList,
                                         loc = loc}
          | _ => AN.ANTAILAPPLY args
        else
          AN.ANTAILAPPLY args
      | nil => AN.ANTAILAPPLY args

  fun optimizeExp env subst anexp =
      case anexp of
        AN.ANCONST _ => anexp
      | AN.ANFOREIGNAPPLY {function, argList, argTyList, resultTyList,
                           attributes} =>
        AN.ANFOREIGNAPPLY
            {function = propValue env subst function,
             argList = map (propValue env subst) argList,
             argTyList = argTyList,
             resultTyList = resultTyList,
             attributes = attributes}
      | AN.ANCALLBACKCLOSURE {funLabel, env=closEnv,
                              argTyList, resultTyList, attributes} =>
        AN.ANCALLBACKCLOSURE
            {funLabel = propValue env subst funLabel,
             env = propValue env subst closEnv,
             argTyList = argTyList,
             resultTyList = resultTyList,
             attributes = attributes}
      | AN.ANENVACC {nestLevel, offset, size, ty} =>
        AN.ANENVACC {nestLevel = nestLevel,
                     offset = offset,
                     size = propValue env subst size,
                     ty = ty}
      | AN.ANGETFIELD {array, offset, size, ty, needBoundaryCheck} =>
        AN.ANGETFIELD {array = propValue env subst array,
                       offset = propValue env subst offset,
                       size = propValue env subst size,
                       needBoundaryCheck = needBoundaryCheck,
                       ty = ty}
      | AN.ANARRAY {bitmap, totalSize, initialValue, elementTy, elementSize,
                    isMutable} =>
        AN.ANARRAY {bitmap = propValue env subst bitmap,
                    totalSize = propValue env subst totalSize,
                    initialValue =
                      Option.map (propValue env subst) initialValue,
                    elementTy = elementTy,
                    elementSize = propValue env subst elementSize,
                    isMutable = isMutable}
      | AN.ANPRIMAPPLY {prim, argList, argTyList, resultTyList,
                        instSizeList, instTagList} =>
        optimizePRIMAPPLY
            {prim = prim,
             argList = map (propValue env subst) argList,
             argTyList = argTyList,
             resultTyList = resultTyList,
             instSizeList = map (propValue env subst) instSizeList,
             instTagList = map (propValue env subst) instTagList}
      | AN.ANAPPLY {closure, argList, argTyList, resultTyList} =>
        optimizeAPPLY env
            {closure = propValue env subst closure,
             argList = map (propValue env subst) argList,
             argTyList = argTyList,
             resultTyList = resultTyList}
      | AN.ANCALL {funLabel, env=closEnv, argList, argTyList, resultTyList} =>
        AN.ANCALL {funLabel = propValue env subst funLabel,
                   env = propValue env subst closEnv,
                   argList = map (propValue env subst) argList,
                   argTyList = argTyList,
                   resultTyList = resultTyList}
      | AN.ANRECCALL {funLabel, argList, argTyList, resultTyList} =>
        AN.ANRECCALL {funLabel = propValue env subst funLabel,
                      argList = map (propValue env subst) argList,
                      argTyList = argTyList,
                      resultTyList = resultTyList}
      | AN.ANLOCALCALL {codeLabel, argList, argTyList,
                        resultTyList, returnLabel, knownDestinations} =>
        AN.ANLOCALCALL {codeLabel = codeLabel,
                        argList = map (propValue env subst) argList,
                        argTyList = argTyList,
                        resultTyList = resultTyList,
                        returnLabel = returnLabel,
                        knownDestinations = knownDestinations}
      | AN.ANRECORD {bitmaps, totalSize, fieldList, fieldSizeList,
                     fieldIndexList, fieldTyList, isMutable, clearPad} =>
        AN.ANRECORD {bitmaps = map (propValue env subst) bitmaps,
                     totalSize = propValue env subst totalSize,
                     fieldList = map (propValue env subst) fieldList,
                     fieldSizeList = map (propValue env subst) fieldSizeList,
                     fieldIndexList = map (propValue env subst) fieldIndexList,
                     fieldTyList = fieldTyList,
                     isMutable = isMutable,
                     clearPad = clearPad}
      | AN.ANSELECT {record, nestLevel, offset, size, ty} =>
        AN.ANSELECT {record = propValue env subst record,
                     nestLevel = propValue env subst nestLevel,
                     offset = propValue env subst offset,
                     size = propValue env subst size,
                     ty = ty}
      | AN.ANCLOSURE {funLabel, env = closEnv} =>
        AN.ANCLOSURE {funLabel = propValue env subst funLabel,
                      env = propValue env subst closEnv}
      | AN.ANRECCLOSURE {funLabel} =>
        anexp
      | AN.ANMODIFY {record, nestLevel, offset, value, valueTy,
                     valueTag, valueSize} =>
        AN.ANMODIFY {record = propValue env subst record,
                     nestLevel = propValue env subst nestLevel,
                     offset = propValue env subst offset,
                     value = propValue env subst value,
                     valueTy = valueTy,
                     valueSize = propValue env subst valueSize,
                     valueTag = propValue env subst valueTag}

      (* optimization for these exps should be done at optimizeDecl *)
      | AN.ANVALUE anvalue =>
        raise Control.Bug "optimizeExp: ANVALUE"

  fun optimizeDecl context env subst andecl =
      case andecl of
        AN.ANSETFIELD {array, offset, value, valueTy, valueSize, valueTag,
                       setGlobal, needBoundaryCheck, loc} =>
        ([AN.ANSETFIELD {array = propValue env subst array,
                         offset = propValue env subst offset,
                         value = propValue env subst value,
                         valueTy = valueTy,
                         valueSize = propValue env subst valueSize,
                         valueTag = propValue env subst valueTag,
                         setGlobal = setGlobal,
                         needBoundaryCheck = needBoundaryCheck,
                         loc = loc}],
         env, subst)
      | AN.ANSETTAIL {record, nestLevel, offset, value, valueTy, valueSize,
                      valueTag, loc} =>
        ([AN.ANSETTAIL {record = propValue env subst record,
                        nestLevel = propValue env subst nestLevel,
                        offset = propValue env subst offset,
                        value = propValue env subst value,
                        valueTy = valueTy,
                        valueSize = propValue env subst valueSize,
                        valueTag = propValue env subst valueTag,
                        loc = loc}],
         env, subst)
      | AN.ANCOPYARRAY {src, srcOffset, dst, dstOffset, length, elementTy,
                        elementSize, elementTag, loc} =>
        ([AN.ANCOPYARRAY {src = propValue env subst src,
                          srcOffset = propValue env subst srcOffset,
                          dst = propValue env subst dst,
                          dstOffset = propValue env subst dstOffset,
                          length = propValue env subst length,
                          elementTy = elementTy,
                          elementSize = propValue env subst elementSize,
                          elementTag = propValue env subst elementTag,
                          loc = loc}],
         env, subst)
      | AN.ANTAILAPPLY {closure, argList, argTyList, resultTyList, loc} =>
        ([optimizeTAILAPPLY context env
              {closure = propValue env subst closure,
               argList = map (propValue env subst) argList,
               argTyList = argTyList,
               resultTyList = resultTyList,
               loc = loc}],
         env, subst)
      | AN.ANTAILCALL {funLabel, env = closEnv, argList,
                       argTyList, resultTyList, loc} =>
        ([AN.ANTAILCALL {funLabel = propValue env subst funLabel,
                         env = propValue env subst closEnv,
                         argList = map (propValue env subst) argList,
                         argTyList = argTyList,
                         resultTyList = resultTyList,
                         loc = loc}],
         env, subst)
      | AN.ANTAILRECCALL {funLabel, argList, argTyList, resultTyList, loc} =>
        ([optimizeTAILRECCALL context
              {funLabel = propValue env subst funLabel,
               argList = map (propValue env subst) argList,
               argTyList = argTyList,
               resultTyList = resultTyList,
               loc = loc}],
         env, subst)
      | AN.ANTAILLOCALCALL {codeLabel, argList, argTyList,
                            resultTyList, loc, knownDestinations} =>
        ([AN.ANTAILLOCALCALL
              {codeLabel = codeLabel,
               argList = map (propValue env subst) argList,
               argTyList = argTyList,
               resultTyList = resultTyList,
               knownDestinations = knownDestinations,
               loc = loc}],
         env, subst)
      | AN.ANRETURN {valueList, tyList, loc} =>
        ([AN.ANRETURN {valueList = map (propValue env subst) valueList,
                       tyList = tyList,
                       loc = loc}],
         env, subst)
      | AN.ANLOCALRETURN {valueList, tyList, loc, knownDestinations} =>
        ([AN.ANLOCALRETURN
              {valueList = map (propValue env subst) valueList,
               tyList = tyList,
               loc = loc,
               knownDestinations = knownDestinations}],
         env, subst)
      | AN.ANVAL {varList = [dst], exp = AN.ANVALUE value, loc} =>
        let
          val subst =
              case value of
                AN.ANVAR varInfo =>
                (case ID.Map.find (subst, #id varInfo) of
                   SOME x => ID.Map.insert (subst, #id dst, x)
                 | NONE => subst)
              | _ => subst
          val anexp = AN.ANVALUE (propValue env subst value)
          val dst = substVar subst dst
          val env = addDef [dst] anexp env
        in
          ([AN.ANVAL {varList = [dst],
                      exp = anexp,
                      loc = loc}],
           env, subst)
        end
      | AN.ANVAL {varList, exp, loc} =>
        let
          val varList = map (substVar subst) varList
          val anexp = optimizeExp env subst exp
          val env = addDef varList anexp env
        in
          ([AN.ANVAL {varList = map (substVar subst) varList,
                      exp = anexp,
                      loc = loc}],
           env, subst)
        end
      | AN.ANVALCODE {codeList, loc} =>
        let
          val codeList =
              map (optimizeCodeDecl context env subst) codeList
        in
          ([AN.ANVALCODE {codeList = codeList,
                          loc = loc}],
           env, subst)
        end
      | AN.ANMERGE {label, varList, loc} =>
        ([AN.ANMERGE {label = label,
                      varList = map (substVar subst) varList,
                      loc = loc}],
         env, subst)
      | AN.ANMERGEPOINT {label, varList, leaveHandler, loc} =>
        ([AN.ANMERGEPOINT {label = label,
                           varList = map (substVar subst) varList,
                           leaveHandler = leaveHandler,
                           loc = loc}],
         env, subst)
      | AN.ANRAISE {value, loc} =>
        ([AN.ANRAISE {value = propValue env subst value, loc = loc}],
         env, subst)
      | AN.ANHANDLE {try, exnVar, handler, labels, loc} =>
        let
          val (try, env, subst) = optimizeDeclList context env subst try
          val (handler, env, subst) = optimizeDeclList context env subst handler
        in
          ([AN.ANHANDLE {try = try,
                         exnVar = exnVar,
                         handler = handler,
                         labels = labels,
                         loc = loc}],
           env, subst)
        end
      | AN.ANSWITCH {value, valueTy, branches, default, loc} =>
        let
          val value = propValue env subst value
          val (branches, env, subst) =
              foldr (fn ({branch, constant}, (branches, env, subst)) =>
                        let
                          val (branch, env, subst) =
                              optimizeDeclList context env subst branch
                        in
                          ({constant = constant, branch = branch} :: branches,
                           env, subst)
                        end)
                    (nil, env, subst)
                    branches
          val (default, env, subst) =
              optimizeDeclList context env subst default
        in
          (optimizeSWITCH (AN.ANSWITCH {value = value,
                                        valueTy = valueTy,
                                        branches = branches,
                                        default = default,
                                        loc = loc}),
           env, subst)
        end

  and optimizeDeclList context env subst (andecl::declList) =
      let
        val (decls1, env, subst) = optimizeDecl context env subst andecl
        val (decls2, env, subst) = optimizeDeclList context env subst declList
      in
        (decls1 @ decls2, env, subst)
      end
    | optimizeDeclList context env subst nil = (nil, env, subst)

  and optimizeCodeDecl context env subst
                       ({codeId, argVarList, body, resultTyList,
                         loc}:AN.codeDecl) =
      let
        (* code is in the current sopce *)
        val (body, _, _) = optimizeDeclList context env subst body
      in
        {
          codeId = codeId,
          argVarList = argVarList,
          body = body,
          resultTyList = resultTyList,
          loc =loc
        } : AN.codeDecl
      end

  fun optimizeFunDecl context
                      ({codeId, argVarList, body, resultTyList,
                        ffiAttributes, loc}:AN.funDecl) =
      let
        val (body, _, _) =
            optimizeDeclList context ID.Map.empty ID.Map.empty body
      in
        {
          codeId = codeId,
          argVarList = argVarList,
          body = body,
          resultTyList = resultTyList,
          ffiAttributes = ffiAttributes,
          loc =loc
        } : AN.funDecl
      end

  fun makeFunDeclMap funDeclList =
      foldl (fn (funDecl as {codeId, ...}:AN.funDecl, functions) =>
                ID.Map.insert (functions, codeId, funDecl))
            ID.Map.empty
            funDeclList

  fun optimizeCluster ({clusterId, frameInfo, entryFunctions, hasClosureEnv,
                        loc}:AN.clusterDecl) =
      let
        val context =
            {
              entryFunctions = makeFunDeclMap entryFunctions
            } : context
      in
        {
          clusterId = clusterId,
          frameInfo = frameInfo,
          entryFunctions = map (optimizeFunDecl context) entryFunctions,
          hasClosureEnv = hasClosureEnv,
          loc = loc
        } : AN.clusterDecl
      end

  fun optimize topdecl =
      map (fn (AN.ANCLUSTER cluster) => AN.ANCLUSTER (optimizeCluster cluster)
            | x => x)
          topdecl
end
