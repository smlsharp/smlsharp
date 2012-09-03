(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: PrimApplyOptimizer.sml,v 1.8 2007/02/11 16:39:50 kiyoshiy Exp $
 *)
structure PrimApplyOptimizer = struct

  open ANormal
  structure AE = AtomEnv
  structure BT = BasicTypes
  structure CT = ConstantTerm
  structure T = Types

  datatype primArg = ARGCONST of ConstantTerm.constant | ARGVAR of anexp


  (************************************************************)
  fun makePrimApply (primOp,argExpList,loc) =
      ANPRIMAPPLY
          {
           primOp = primOp,
           argExpList = argExpList,
           loc = loc
          }

  fun makePrimApply1 (primOp,argValue1,argExp2,loc) =
      ANPRIMAPPLY_1
          {
           primOp = primOp,
           argValue1 = argValue1,
           argExp2 = argExp2,
           loc = loc
          }

  fun makePrimApply2 (primOp,argExp1,argValue2,loc) =
      ANPRIMAPPLY_2
          {
           primOp = primOp,
           argExp1 = argExp1,
           argValue2 = argValue2,
           loc = loc
          }

  fun anexpToPrimArg atomEnv (exp as ANVAR {varInfo,...}) =
      case AE.findVar(atomEnv,varInfo) of
        SOME (ANCONSTANT {value,...}) => ARGCONST value
      | _ => ARGVAR exp

  fun realToString r = Real.toString r

  fun stringToReal s =
      case Real.fromString s of
        SOME r => r
      | _ => raise Control.Bug "a real value is expected"

  val trueValue = CT.INT 1
  val falseValue = CT.INT 0


  (************************************************************)

  fun genericOp_1 constOp atomEnv (primOp,[argExp],loc) =
      let
        val arg = anexpToPrimArg atomEnv argExp
      in
        case arg of
          ARGCONST c => ANCONSTANT {value = constOp c,loc = loc}
        | ARGVAR v => makePrimApply(primOp,[v],loc)
      end

  fun genericOp_2 constOp atomEnv (primOp,[argExp1,argExp2],loc) =
      let
        val arg1 = anexpToPrimArg atomEnv argExp1
        val arg2 = anexpToPrimArg atomEnv argExp2
      in
        case (arg1,arg2) of
          (ARGCONST c1,ARGCONST c2) => ANCONSTANT {value = constOp(c1,c2),loc = loc}
        | (ARGCONST c1,ARGVAR v2) => makePrimApply1(primOp,c1,v2,loc)
        | (ARGVAR v1,ARGCONST c2) => makePrimApply2(primOp,v1,c2,loc)
        | (ARGVAR v1,ARGVAR v2) => makePrimApply(primOp,[v1,v2],loc)
      end

  fun genericOp2_2 constOp atomEnv (primOp,[argExp1,argExp2],loc) =
      let
        val arg1 = anexpToPrimArg atomEnv argExp1
        val arg2 = anexpToPrimArg atomEnv argExp2
      in
        case (arg1,arg2) of
          (ARGCONST c1,ARGCONST c2) => ANCONSTANT {value = constOp(c1,c2),loc = loc}
        | _ => makePrimApply(primOp,[argExp1,argExp2],loc)
      end

  fun genericOp_3 constOp atomEnv (primOp,[argExp1,argExp2,argExp3],loc) =
      let
        val arg1 = anexpToPrimArg atomEnv argExp1
        val arg2 = anexpToPrimArg atomEnv argExp2
        val arg3 = anexpToPrimArg atomEnv argExp3
      in
        case (arg1,arg2,arg3) of
          (ARGCONST c1,ARGCONST c2,ARGCONST c3) => ANCONSTANT {value = constOp(c1,c2,c3),loc = loc}
        | _ => makePrimApply(primOp,[argExp1,argExp2,argExp3],loc)
      end

  fun genericOp_ii_i constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.INT v1,CT.INT v2) => CT.INT (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp_ww_w constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.WORD v1,CT.WORD v2) => CT.WORD (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp_rr_r constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.REAL v1,CT.REAL v2) => 
              CT.REAL (realToString(constOp(stringToReal v1,stringToReal v2))))
          atomEnv
          primApplyInfo

  fun genericOp_cc_c constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.CHAR v1,CT.CHAR v2) => CT.CHAR (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp_bb_b constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.WORD v1,CT.WORD v2) => 
              CT.WORD (BT.UInt8ToUInt32(constOp(BT.UInt32ToUInt8 v1,BT.UInt32ToUInt8 v2))))
          atomEnv
          primApplyInfo


  fun genericOp_ii_l constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.INT v1,CT.INT v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp_ww_l constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.WORD v1,CT.WORD v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp_rr_l constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.REAL v1,CT.REAL v2) => 
              if constOp(stringToReal v1,stringToReal v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp_cc_l constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.CHAR v1,CT.CHAR v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp_bb_l constOp atomEnv primApplyInfo =
      genericOp_2
          (fn (CT.WORD v1,CT.WORD v2) => 
              if constOp(BT.UInt32ToUInt8 v1,BT.UInt32ToUInt8 v2) 
              then trueValue 
              else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp2_ii_i constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.INT v1,CT.INT v2) => CT.INT (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp2_ww_w constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.WORD v1,CT.WORD v2) => CT.WORD (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp2_rr_r constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.REAL v1,CT.REAL v2) => 
              CT.REAL (realToString(constOp(stringToReal v1,stringToReal v2))))
          atomEnv
          primApplyInfo

  fun genericOp2_cc_c constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.CHAR v1,CT.CHAR v2) => CT.CHAR (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp2_bb_b constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.WORD v1,CT.WORD v2) => 
              CT.WORD (BT.UInt8ToUInt32(constOp(BT.UInt32ToUInt8 v1, BT.UInt32ToUInt8 v2))))
          atomEnv
          primApplyInfo

  fun genericOp2_ss_s constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.STRING v1,CT.STRING v2) => CT.STRING (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp2_si_c constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.STRING v1,CT.INT v2) => CT.CHAR (constOp(v1,v2)))
          atomEnv
          primApplyInfo

  fun genericOp2_ii_l constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.INT v1,CT.INT v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp2_ww_l constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.WORD v1,CT.WORD v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp2_rr_l constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.REAL v1,CT.REAL v2) => 
              if constOp(stringToReal v1,stringToReal v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp2_cc_l constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.CHAR v1,CT.CHAR v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp2_bb_l constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.WORD v1,CT.WORD v2) => 
              if constOp(BT.UInt32ToUInt8 v1,BT.UInt32ToUInt8 v2) 
              then trueValue 
              else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp2_ss_l constOp atomEnv primApplyInfo =
      genericOp2_2
          (fn (CT.STRING v1,CT.STRING v2) => 
              if constOp(v1,v2) then trueValue else falseValue)
          atomEnv
          primApplyInfo

  fun genericOp_sii_s constOp atomEnv primApplyInfo =
      genericOp_3
          (fn (CT.STRING v1,CT.INT v2,CT.INT v3) => 
              CT.STRING (constOp(v1,v2,v3)))
          atomEnv
          primApplyInfo

  fun genericOp_r_r constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.REAL v) => 
              CT.REAL (realToString (constOp (stringToReal v))))
          atomEnv
          primApplyInfo

  fun genericOp_c_i constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.CHAR v) => CT.INT (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_i_c constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.INT v) => CT.CHAR (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_c_s constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.CHAR v) => CT.STRING (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_r_i constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.REAL v) => 
              CT.INT (constOp (stringToReal v)))
          atomEnv
          primApplyInfo

  fun genericOp_i_r constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.INT v) => 
              CT.REAL (realToString (constOp  v)))
          atomEnv
          primApplyInfo

  fun genericOp_w_s constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.WORD v) => CT.STRING (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_i_s constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.INT v) => CT.STRING (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_s_i constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.STRING v) => CT.INT (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_w_w constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.WORD v) => CT.WORD (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_i_w constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.INT v) => CT.WORD (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_w_i constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.WORD v) => CT.INT (constOp  v))
          atomEnv
          primApplyInfo

  fun genericOp_i_i constOp atomEnv primApplyInfo =
      genericOp_1
          (fn (CT.INT v) => CT.INT (constOp  v))
          atomEnv
          primApplyInfo

  (************************************************************)

  fun divRealOp atomEnv (primOp,[argExp1,argExp2],loc) =
      let
        val arg1 = anexpToPrimArg atomEnv argExp1
        val arg2 = anexpToPrimArg atomEnv argExp2
      in
        case (arg1,arg2) of
          (ARGCONST (CT.REAL r1),ARGCONST (CT.REAL r2)) => 
          (
          case realToString((stringToReal r1)/(stringToReal r2)) of
            "nan" => makePrimApply(primOp,[argExp1,argExp2],loc)
          | "inf" => makePrimApply(primOp,[argExp1,argExp2],loc)
          | "~inf" => makePrimApply(primOp,[argExp1,argExp2],loc)
          | s => ANCONSTANT {value=CT.REAL s,loc=loc}
          ) 
        | (ARGCONST c1,ARGVAR v2) => makePrimApply1(primOp,c1,v2,loc)
        | (ARGVAR v1,ARGCONST c2) => makePrimApply2(primOp,v1,c2,loc)
        | (ARGVAR v1,ARGVAR v2) => makePrimApply(primOp,[v1,v2],loc)
      end


  (************************************************************)

  val optimizers = 
      SEnv.fromList
      [
       ("addInt",genericOp_ii_i (op + )),
       ("addWord",genericOp_ww_w (op + )),
       ("addReal",genericOp_rr_r (op + )),
       ("addByte",genericOp_bb_b (op + )),

       ("subInt",genericOp_ii_i (op - )),
       ("subWord",genericOp_ww_w (op - )),
       ("subReal",genericOp_rr_r (op - )),
       ("subByte",genericOp_bb_b (op - )),

       ("mulInt",genericOp_ii_i (op * )),
       ("mulWord",genericOp_ww_w (op * )),
       ("mulReal",genericOp_rr_r (op * )),
       ("mulByte",genericOp_bb_b (op * )),

       ("divInt",genericOp_ii_i (op div )),
       ("divWord",genericOp_ww_w (op div )),
       ("/",divRealOp),
       ("divByte",genericOp_bb_b (op div )),

       ("modInt",genericOp_ii_i (op mod )),
       ("modWord",genericOp_ww_w (op mod )),
       ("modByte",genericOp_bb_b (op mod)),

       ("quotInt",genericOp_ii_i (Int32.quot)),
       ("remInt",genericOp_ii_i (Int32.rem)),

       ("negInt",genericOp_i_i ~),
       ("negReal",genericOp_r_r ~),

       ("absInt",genericOp_i_i abs),
       ("absReal",genericOp_r_r abs),

       ("ltInt",genericOp2_ii_l (op < )),
       ("ltWord",genericOp2_ww_l (op < )),
       ("ltReal",genericOp2_rr_l (op < )),
       ("ltByte",genericOp2_bb_l (op < )),
       ("ltChar",genericOp2_cc_l (op < )),
       ("ltString",genericOp2_ss_l (op < )),

       ("gtInt",genericOp2_ii_l (op > )),
       ("gtWord",genericOp2_ww_l (op > )),
       ("gtReal",genericOp2_rr_l (op > )),
       ("gtByte",genericOp2_bb_l (op > )),
       ("gtChar",genericOp2_cc_l (op > )),
       ("gtString",genericOp2_ss_l (op > )),

       ("lteqInt",genericOp2_ii_l (op <= )),
       ("lteqWord",genericOp2_ww_l (op <= )),
       ("lteqReal",genericOp2_rr_l (op <= )),
       ("lteqByte",genericOp2_bb_l (op <= )),
       ("lteqChar",genericOp2_cc_l (op <= )),
       ("lteqString",genericOp2_ss_l (op <= )),

       ("gteqInt",genericOp2_ii_l (op >= )),
       ("gteqWord",genericOp2_ww_l (op >= )),
       ("gteqReal",genericOp2_rr_l (op >= )),
       ("gteqByte",genericOp2_bb_l (op >= )),
       ("gteqChar",genericOp2_cc_l (op >= )),
       ("gteqString",genericOp2_ss_l (op >= )),

       ("Word_toIntX",genericOp_w_i (Word32.toLargeIntX)),
       ("Word_fromInt",genericOp_i_w (Word32.fromLargeInt)),
       ("Word_andb",genericOp_ww_w (Word32.andb)),
       ("Word_orb",genericOp_ww_w (Word32.orb)),
       ("Word_xorb",genericOp_ww_w (Word32.xorb)),
       ("Word_notb",genericOp_w_w (Word32.notb)),
       ("Word_leftShift",genericOp_ww_w (fn (w1,w2) => Word32.<<(w1,BT.UInt32ToWord w2))),
       ("Word_logicalRightShift",genericOp_ww_w (fn (w1,w2) => Word32.>>(w1,BT.UInt32ToWord w2))),
       ("Word_arithmeticRightShift",genericOp_ww_w (fn (w1,w2) => Word32.~>>(w1,BT.UInt32ToWord w2))),

       ("Int_toString",genericOp_i_s (Int32.toString)),
       ("Word_toString",genericOp_w_s (Word32.toString)),
       ("Real_fromInt",genericOp_i_r (Real.fromLargeInt)),
       ("Real_floor",genericOp_r_i (fn r => Int32.fromInt (Real.floor r))),
       ("Real_ceil",genericOp_r_i (fn r => Int32.fromInt (Real.ceil r))),
       ("Real_trunc",genericOp_r_i (fn r => Int32.fromInt (Real.trunc r))),
       ("Real_round",genericOp_r_i (fn r => Int32.fromInt (Real.round r))),

       ("Char_toString",genericOp_c_s (Char.toString)),
       ("Char_chr",genericOp_i_c (fn i => Char.chr (Int32.toInt i))),
       ("Char_ord",genericOp_c_i (fn c => Int32.fromInt (Char.ord c))),

       ("String_concat2",genericOp2_ss_s (op ^)),
       ("String_sub",genericOp2_si_c (fn (s,i) => String.sub(s,Int32.toInt i))),
       ("String_size",genericOp_s_i (fn s => Int32.fromInt (String.size s))),
       ("String_substring",genericOp_sii_s (fn (s,i1,i2) => String.substring(s,Int32.toInt i1,Int32.toInt i2))),

       ("Math_sqrt",genericOp_r_r (Math.sqrt)),
       ("Math_sin",genericOp_r_r (Math.sin)),
       ("Math_cos",genericOp_r_r (Math.cos)),
       ("Math_tan",genericOp_r_r (Math.tan)),
       ("Math_asin",genericOp_r_r (Math.asin)),
       ("Math_acos",genericOp_r_r (Math.acos)),
       ("Math_atan",genericOp_r_r (Math.atan)),
       ("Math_atan2",genericOp2_rr_r (Math.atan2)),
       ("Math_exp",genericOp_r_r (Math.exp)),
       ("Math_pow",genericOp2_rr_r (Math.pow)),
       ("Math_ln",genericOp_r_r (Math.ln)),
       ("Math_log10",genericOp_r_r (Math.log10)),
       ("Math_sinh",genericOp_r_r (Math.sinh)),
       ("Math_cosh",genericOp_r_r (Math.cosh)),
       ("Math_tanh",genericOp_r_r (Math.tanh))
      ]

  fun optimizePrimApply atomEnv (exp as ANPRIMAPPLY{primOp as {name,ty},argExpList,loc}) =
      if !Control.doConstantFolding 
      then 
        case SEnv.find(optimizers,name) of
          SOME operator => 
          (
           (operator atomEnv (primOp,argExpList,loc))
           handle _ => exp
          )
        | NOME => exp
      else exp
    | optimizePrimApply atomEnv _ =
      raise Control.Bug "primapply optimization"

end
