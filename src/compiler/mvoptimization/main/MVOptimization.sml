(**
 * MultipleValueCalc optimization
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure MVOptimization : MVOPTIMIZATION = struct

  structure AT = AnnotatedTypes
  structure MV = MultipleValueCalc
  structure MVU = MultipleValueCalcUtils
  structure ATU = AnnotatedTypesUtils
  structure CT = ConstantTerm
  structure Float = Real
  structure P = BuiltinPrimitive

  fun newVar ty = 
      let
        val id = VarID.generate ()
      in
        {displayName = "$" ^ VarID.toString id,
         ty = ty,
         varId = Types.INTERNAL id}
      end

  structure MVExp_ord:ORD_KEY = struct

    type ord_key = MV.mvexp

    fun argCompare (x,y) =
        case (x,y) of
          (MV.MVCAST {exp = exp1, ...}, exp2) => argCompare (exp1, exp2)
        | (exp1, MV.MVCAST {exp = exp2,...}) => argCompare (exp1, exp2)
        | (MV.MVEXCEPTIONTAG {tagValue = i1,...}, MV.MVEXCEPTIONTAG {tagValue = i2,...}) =>
          ExnTagID.compare(i1,i2)
        | (MV.MVEXCEPTIONTAG _, _) => LESS
        | (MV.MVCONSTANT _, MV.MVEXCEPTIONTAG _) => GREATER
        | (MV.MVCONSTANT {value = c1,...}, MV.MVCONSTANT {value = c2,...}) =>
          ConstantTerm.compare(c1,c2)
        | (MV.MVCONSTANT _, _) => LESS
        | (MV.MVVAR _, MV.MVEXCEPTIONTAG _) => GREATER
        | (MV.MVVAR _, MV.MVCONSTANT _) => GREATER
        | (MV.MVVAR {varInfo = {varId = varId1,...},...}, MV.MVVAR {varInfo = {varId = varId2,...},...}) =>
          VarIdEnv.Key.compare (varId1, varId2)
        | (MV.MVGLOBALSYMBOL _, MV.MVEXCEPTIONTAG _) => GREATER
        | (MV.MVGLOBALSYMBOL _, MV.MVCONSTANT _) => GREATER
        | (MV.MVGLOBALSYMBOL _, MV.MVVAR _) => GREATER
        | (MV.MVGLOBALSYMBOL {name=name1,...}, MV.MVGLOBALSYMBOL {name=name2,...}) =>
          String.compare (name1, name2)
        | _ => raise Control.Bug "invalid argument"

    fun argsCompare (argList1,argList2) = ATU.listCompare argCompare (argList1,argList2)

    fun stringsCompare (L1,L2) = ATU.listCompare String.compare (L1,L2)

    fun compare (x,y) =
        case (x,y) of
          (MV.MVRECORD {isMutable=false, 
                        expList = expList1, 
                        recordTy = AT.RECORDty {fieldTypes = flty1,...},...
                        },
           MV.MVRECORD {isMutable=false, 
                        expList = expList2, 
                        recordTy = AT.RECORDty {fieldTypes = flty2,...},...}) =>
          (
           case stringsCompare(SEnv.listKeys flty1,SEnv.listKeys flty2) of
             EQUAL => argsCompare(expList1,expList2)
           | d => d 
          )
        | (MV.MVRECORD {isMutable=false,...}, _) => LESS

        | (MV.MVSELECT _, MV.MVRECORD {isMutable=false,...}) => GREATER
        | (MV.MVSELECT {recordExp = recordExp1, indexExp = indexExp1,...},
           MV.MVSELECT {recordExp = recordExp2, indexExp = indexExp2,...}) =>
          (
           case argCompare(indexExp1,indexExp2) of
             EQUAL => argCompare(recordExp1,recordExp2)
           | d => d 
          )
        | (MV.MVSELECT _, _) => LESS

        | (MV.MVMODIFY _, MV.MVRECORD {isMutable=false,...}) => GREATER
        | (MV.MVMODIFY _, MV.MVSELECT _) => GREATER
        | (MV.MVMODIFY {recordExp = recordExp1, indexExp = indexExp1, valueExp = valueExp1,...},
           MV.MVMODIFY {recordExp = recordExp2, indexExp = indexExp2, valueExp = valueExp2,...}) =>
          (
           case argCompare(indexExp1,indexExp2) of
             EQUAL => argsCompare([recordExp1,valueExp1],[recordExp2,valueExp2])
           | d => d 
          )
 
        | _ =>  raise Control.Bug "invalid atomEnv"
  end

  structure CommonExpEnv = BinaryMapMaker(MVExp_ord)

  fun optimizePrimApply varEnv (exp as MV.MVPRIMAPPLY {primInfo, argExpList, instTyList, loc}) =
      if !Control.doConstantFolding
      then
        let
          exception ConstantNotFound

          fun intOf (MV.MVCONSTANT {value = CT.INT v,...}) = v
            | intOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv,varId)
                of SOME (MV.MVCONSTANT {value = CT.INT v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | intOf _ = raise ConstantNotFound
          fun genericIntOf (MV.MVCONSTANT {value = CT.INT v,...}) = Int32.toInt v
            | genericIntOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv,varId)
                of SOME (MV.MVCONSTANT {value = CT.INT v,...}) => Int32.toInt v
                 | _ => raise ConstantNotFound
              )
            | genericIntOf _ = raise ConstantNotFound
          fun largeIntOf (MV.MVCONSTANT {value = CT.LARGEINT v,...}) = v
            | largeIntOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.LARGEINT v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | largeIntOf _ = raise ConstantNotFound
          fun wordOf (MV.MVCONSTANT {value = CT.WORD v,...}) = v
            | wordOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.WORD v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | wordOf _ = raise ConstantNotFound
          fun genericWordOf (MV.MVCONSTANT {value = CT.WORD v,...}) = Word.fromLargeWord (Word32.toLargeWord v)
            | genericWordOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.WORD v,...}) => Word.fromLargeWord (Word32.toLargeWord v)
                 | _ => raise ConstantNotFound
              )
            | genericWordOf _ = raise ConstantNotFound
          fun realOf (MV.MVCONSTANT {value = CT.REAL v,...}) = valOf(Real.fromString v)
            | realOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.REAL v,...}) => valOf(Real.fromString v)
                 | _ => raise ConstantNotFound
              )
            | realOf _ = raise ConstantNotFound
          fun floatOf (MV.MVCONSTANT {value = CT.FLOAT v,...}) = valOf(Real.fromString v)
            | floatOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv,varId)
                of SOME (MV.MVCONSTANT {value = CT.FLOAT v,...}) => valOf(Real.fromString v)
                 | _ => raise ConstantNotFound
              )
            | floatOf _ = raise ConstantNotFound
          fun charOf (MV.MVCONSTANT {value = CT.CHAR v,...}) = v
            | charOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.CHAR v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | charOf _ = raise ConstantNotFound
          fun byteOf (MV.MVCONSTANT {value = CT.WORD v,...}) = v
            | byteOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.WORD v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | byteOf _ = raise ConstantNotFound
          fun stringOf (MV.MVCONSTANT {value = CT.STRING v,...}) = v
            | stringOf (MV.MVVAR {varInfo as {varId,...},...}) = 
              (
               case VarIdEnv.find(varEnv, varId)
                of SOME (MV.MVCONSTANT {value = CT.STRING v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | stringOf _ = raise ConstantNotFound


          fun intToExp v = MV.MVCONSTANT {value = CT.INT v, loc = loc}
          fun genericIntToExp v = MV.MVCONSTANT {value = CT.INT (Int32.fromInt v), loc = loc}
          fun largeIntToExp v = MV.MVCONSTANT {value = CT.LARGEINT v, loc = loc}
          fun wordToExp v = MV.MVCONSTANT {value = CT.WORD v, loc = loc}
          fun genericWordToExp v = 
              MV.MVCONSTANT {value = CT.WORD (Word32.fromLargeWord (Word.toLargeWord v)), loc = loc}
          fun realToExp v = MV.MVCONSTANT {value = CT.REAL (Real.toString v), loc = loc}
          fun floatToExp v = MV.MVCONSTANT {value = CT.FLOAT (Real.toString v), loc = loc}
          fun charToExp v = MV.MVCONSTANT {value = CT.CHAR v, loc = loc}
          fun byteToExp v = MV.MVCONSTANT {value = CT.WORD v, loc = loc}
          fun boolToExp v =
              if v
              then 
                MV.MVCAST
                    {
                     exp = MV.MVCONSTANT {value = CT.INT (Int32.fromInt (Constants.TAG_bool_true)), loc = loc},
                     expTy = AT.intty,
                     targetTy = AT.boolty,
                     loc = loc
                    }
              else 
                MV.MVCAST
                    {
                     exp = MV.MVCONSTANT {value = CT.INT (Int32.fromInt (Constants.TAG_bool_false)), loc = loc},
                     expTy = AT.intty,
                     targetTy = AT.boolty,
                     loc = loc
                    }
          fun stringToExp v = MV.MVCONSTANT {value = CT.STRING v, loc = loc}

          fun optimize1 argConv resConv operator =
              case argExpList of
                [arg] => resConv (operator (argConv arg))
              | _ => exp

          fun optimize2 arg1Conv arg2Conv resConv operator =
              case argExpList of
                [arg1,arg2] => resConv (operator(arg1Conv arg1, arg2Conv arg2))
              | _ => exp

          fun optimize3 arg1Conv arg2Conv arg3Conv resConv operator =
              case argExpList of
                [arg1,arg2,arg3] => resConv (operator(arg1Conv arg1,arg2Conv arg2, arg3Conv arg3))
              | _ => exp

        in
          (
           case (#name primInfo, argExpList) of
             (P.Int_add _,[MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg2
           | (P.Int_add _,[arg1,MV.MVCONSTANT {value = CT.INT 0,...}]) => arg1
           | (P.Int_add _, _) => optimize2 intOf intOf intToExp ( op + ) 
           | (P.Word_add,[MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
           | (P.Word_add,[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Word_add, _) => optimize2 wordOf wordOf wordToExp ( op + ) 
           | (P.Real_add, _) => optimize2 realOf realOf realToExp ( op + ) 
           | (P.Float_add, _) => optimize2 floatOf floatOf floatToExp ( op + ) 
           | (P.Byte_add,[MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
           | (P.Byte_add,[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Byte_add, _) => optimize2 byteOf byteOf byteToExp ( op + ) 

           | (P.Int_sub _,[arg1,MV.MVCONSTANT {value = CT.INT 0,...}]) => arg1
           | (P.Int_sub _, _) => optimize2 intOf intOf intToExp ( op - ) 
           | (P.Word_sub,[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Word_sub, _) => optimize2 wordOf wordOf wordToExp ( op - ) 
           | (P.Real_sub, _) => optimize2 realOf realOf realToExp ( op - ) 
           | (P.Float_sub, _) => optimize2 floatOf floatOf floatToExp ( op - ) 
           | (P.Byte_sub,[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Byte_sub, _) => optimize2 byteOf byteOf byteToExp ( op - ) 

           | (P.Int_mul _,[arg1 as MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg1
           | (P.Int_mul _,[arg1 as MV.MVCONSTANT {value = CT.INT 1,...},arg2]) => arg2
           | (P.Int_mul _,[arg1,arg2 as MV.MVCONSTANT {value = CT.INT 0,...}]) => arg2
           | (P.Int_mul _,[arg1,arg2 as MV.MVCONSTANT {value = CT.INT 1,...}]) => arg1
           | (P.Int_mul _, _) => optimize2 intOf intOf intToExp ( op * ) 
           | (P.Word_mul,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_mul,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w1,...},arg2]) => arg2
           | (P.Word_mul,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg2
           | (P.Word_mul,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w1,...}]) => arg1
           | (P.Word_mul, _) => optimize2 wordOf wordOf wordToExp ( op * ) 
           | (P.Real_mul, _) => optimize2 realOf realOf realToExp ( op * ) 
           | (P.Float_mul, _) => optimize2 floatOf floatOf floatToExp ( op * ) 
           | (P.Byte_mul,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Byte_mul,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w1,...},arg2]) => arg2
           | (P.Byte_mul,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg2
           | (P.Byte_mul,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w1,...}]) => arg1
           | (P.Byte_mul, _) => optimize2 byteOf byteOf byteToExp ( op * ) 

           | (P.Int_div _,[arg1 as MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg1
           | (P.Int_div _, _) => optimize2 intOf intOf intToExp ( op div ) 
           | (P.Word_div,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_div, _) => optimize2 wordOf wordOf wordToExp ( op div ) 
           (*| (P.Real_div, _) => optimize2 realOf realOf realToExp ( op / ) *)
           (*| (P.Float_div, _) => optimize2 floatOf floatOf floatToExp ( op / ) *)
           | (P.Byte_div,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Byte_div, _) => optimize2 byteOf byteOf byteToExp ( op div ) 

           | (P.Int_mod _,[arg1 as MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg1
           | (P.Int_mod _, _) => optimize2 intOf intOf intToExp ( op mod ) 
           | (P.Word_mod,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_mod, _) => optimize2 wordOf wordOf wordToExp ( op mod ) 
           | (P.Byte_mod,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Byte_mod, _) => optimize2 byteOf byteOf byteToExp ( op mod ) 

           | (P.Int_quot _, _) => optimize2 intOf intOf intToExp ( Int32.quot ) 
           | (P.Int_rem _, _) => optimize2 intOf intOf intToExp ( Int32.rem ) 

           | (P.Int_neg _, _) => optimize1 intOf intToExp ~  
           | (P.Real_neg, _) => optimize1 realOf realToExp ~ 
           | (P.Float_neg, _) => optimize1 floatOf floatToExp ~ 

           | (P.Int_lt, _) => optimize2 intOf intOf boolToExp ( op < ) 
           | (P.Word_lt, _) => optimize2 wordOf wordOf boolToExp ( op < ) 
           | (P.Real_lt, _) => optimize2 realOf realOf boolToExp ( op < ) 
           | (P.Float_lt, _) => optimize2 floatOf floatOf boolToExp ( op < ) 
           | (P.Byte_lt, _) => optimize2 byteOf byteOf boolToExp ( op < ) 
           | (P.Char_lt, _) => optimize2 charOf charOf boolToExp ( op < ) 
           | (P.String_lt, _) => optimize2 stringOf stringOf boolToExp ( op < ) 

           | (P.Int_gt, _) => optimize2 intOf intOf boolToExp ( op > ) 
           | (P.Word_gt, _) => optimize2 wordOf wordOf boolToExp ( op > ) 
           | (P.Real_gt, _) => optimize2 realOf realOf boolToExp ( op > ) 
           | (P.Float_gt, _) => optimize2 floatOf floatOf boolToExp ( op > ) 
           | (P.Byte_gt, _) => optimize2 byteOf byteOf boolToExp ( op > ) 
           | (P.Char_gt, _) => optimize2 charOf charOf boolToExp ( op > ) 
           | (P.String_gt, _) => optimize2 stringOf stringOf boolToExp ( op > ) 

           | (P.Int_lteq, _) => optimize2 intOf intOf boolToExp ( op <= ) 
           | (P.Word_lteq, _) => optimize2 wordOf wordOf boolToExp ( op <= ) 
           | (P.Real_lteq, _) => optimize2 realOf realOf boolToExp ( op <= ) 
           | (P.Float_lteq, _) => optimize2 floatOf floatOf boolToExp ( op <= ) 
           | (P.Byte_lteq, _) => optimize2 byteOf byteOf boolToExp ( op <= ) 
           | (P.Char_lteq, _) => optimize2 charOf charOf boolToExp ( op <= ) 
           | (P.String_lteq, _) => optimize2 stringOf stringOf boolToExp ( op <= ) 

           | (P.Int_gteq, _) => optimize2 intOf intOf boolToExp ( op >= ) 
           | (P.Word_gteq, _) => optimize2 wordOf wordOf boolToExp ( op >= ) 
           | (P.Real_gteq, _) => optimize2 realOf realOf boolToExp ( op >= ) 
           | (P.Float_gteq, _) => optimize2 floatOf floatOf boolToExp ( op >= ) 
           | (P.Byte_gteq, _) => optimize2 byteOf byteOf boolToExp ( op >= ) 
           | (P.Char_gteq, _) => optimize2 charOf charOf boolToExp ( op >= ) 
           | (P.String_gteq, _) => optimize2 stringOf stringOf boolToExp ( op >= )

           | (P.Word_toIntX, _) => optimize1 wordOf intToExp (Int32.fromLarge o Word32.toLargeIntX)          
           | (P.Word_fromInt, _) => optimize1 intOf wordToExp (Word32.fromLargeInt o Int32.toLarge)          

           | (P.Word_andb,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_andb,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg2
           | (P.Word_andb, _) => optimize2 wordOf wordOf wordToExp ( Word32.andb ) 

           | (P.Word_orb,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
           | (P.Word_orb,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Word_orb, _) => optimize2 wordOf wordOf wordToExp ( Word32.orb ) 

           | (P.Word_xorb, _) => optimize2 wordOf wordOf wordToExp ( Word32.xorb ) 
           | (P.Word_notb, _) => optimize1 wordOf wordToExp ( Word32.notb ) 

           | (P.Word_lshift,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_lshift,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Word_lshift, _) => optimize2 wordOf genericWordOf wordToExp ( Word32.<< ) 

           | (P.Word_rshift,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_rshift,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Word_rshift, _) => optimize2 wordOf genericWordOf wordToExp ( Word32.>> ) 

           | (P.Word_arshift,[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | (P.Word_arshift,[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | (P.Word_arshift, _) => optimize2 wordOf genericWordOf wordToExp ( Word32.~>> ) 

(*
           | (P.RuntimePrim "Int_toString", _) => optimize1 intOf stringToExp (Int32.toString)          
           | (P.RuntimePrim "Word_toString", _) => optimize1 wordOf stringToExp (Word32.toString)       
*)

           | (P.Real_fromInt, _) => optimize1 intOf realToExp (Real.fromLargeInt o Int32.toLarge)             
(*
           | (P.RuntimePrim "Real_toString", _) => optimize1 realOf stringToExp (Real.toString)       
           | (P.RuntimePrim "Real_floor", _) => optimize1 realOf genericIntToExp (Real.floor)
           | (P.RuntimePrim "Real_ceil", _) => optimize1 realOf genericIntToExp (Real.ceil)
*)
           | (P.Real_trunc_unsafe _, _) => optimize1 realOf genericIntToExp (Real.trunc)
(*
           | (P.RuntimePrim "Real_round", _) => optimize1 realOf genericIntToExp (Real.round)
*)

           | (P.Float_fromInt, _) => optimize1 intOf floatToExp (Float.fromLargeInt o Int32.toLarge)             
(*
           | (P.RuntimePrim "Float_toString", _) => optimize1 floatOf stringToExp (Float.toString)       
           | (P.RuntimePrim "Float_floor", _) => optimize1 floatOf genericIntToExp (Float.floor)
           | (P.RuntimePrim "Float_ceil", _) => optimize1 floatOf genericIntToExp (Float.ceil)
*)
           | (P.Float_trunc_unsafe _, _) => optimize1 floatOf genericIntToExp (Float.trunc)
(*
           | (P.RuntimePrim "Float_round", _) => optimize1 floatOf genericIntToExp (Float.round)

           | (P.RuntimePrim "Char_toString", _) => optimize1 charOf stringToExp (Char.toString)       
*)
           | (P.Char_ord, _) => optimize1 charOf genericIntToExp (Char.ord)       
           | (P.Char_chr_unsafe, _) => optimize1 genericIntOf charToExp (Char.chr)

(*
           | (P.RuntimePrim "String_concat2", _) => optimize2 stringOf stringOf stringToExp ( op ^ )        
*)
           | (P.String_sub_unsafe, _) => optimize2 stringOf genericIntOf charToExp ( String.sub )        
           | (P.String_size, _) => optimize1 stringOf genericIntToExp ( String.size )        
(*
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

           | _ => exp          
          ) handle _ => exp
        end
      else exp
    | optimizePrimApply _ _ = raise Control.Bug "invalid primapply"

  fun commonSubexpressionEliminate commonExpEnv exp =
      if !Control.doCommonSubexpressionElimination
      then
        case CommonExpEnv.find(commonExpEnv, exp)
         of SOME varInfo => MV.MVVAR {varInfo = varInfo, loc = MVU.getLocOfExp exp}
          | _ => exp
      else exp


  fun optimizeArg varEnv argExp =
      case argExp
       of MV.MVCONSTANT _ => argExp
        | MV.MVGLOBALSYMBOL _ => argExp
        | MV.MVEXCEPTIONTAG _ => argExp
        | MV.MVVAR {varInfo as {varId,...},...} =>
          (case VarIdEnv.find(varEnv, varId)
            of SOME rootExp => rootExp
             | NONE => argExp
          )
        | MV.MVCAST {exp = MV.MVCONSTANT _ , ...} => argExp
        | MV.MVCAST {exp = MV.MVGLOBALSYMBOL _, ...} => argExp
        | MV.MVCAST {exp = MV.MVEXCEPTIONTAG _ , ...} => argExp
        | MV.MVCAST {exp = MV.MVVAR {varInfo as {varId,...},...}, expTy, targetTy, loc} => 
          (case VarIdEnv.find(varEnv, varId)
            of SOME (MV.MVCAST {exp, expTy,...}) => 
               MV.MVCAST {exp = exp, expTy = expTy, targetTy = targetTy, loc = loc}
             | SOME rootExp =>
               MV.MVCAST {exp = rootExp, expTy = expTy, targetTy = targetTy, loc = loc}
             | NONE => argExp
          )
        | _ => 
          let 
            val s = Control.prettyPrint (MV.format_mvexp argExp)
          in 
            raise Control.Bug ("invalid argument" ^ s)
          end

  fun optimizeExp varEnv recordEnv commonExpEnv mvexp =
      case mvexp
       of MV.MVFOREIGNAPPLY{funExp, funTy, argExpList, attributes, loc} => 
          MV.MVFOREIGNAPPLY
              {
               funExp = optimizeArg varEnv funExp,
               funTy = funTy,
               argExpList = map (optimizeArg varEnv) argExpList,
               attributes = attributes,
               loc = loc
              }
        | MV.MVEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
          MV.MVEXPORTCALLBACK
              {
               funExp = optimizeExp varEnv recordEnv commonExpEnv funExp,
               funTy = funTy, 
               attributes = attributes,
               loc = loc
              }
        | MV.MVTAGOF _ => mvexp
        | MV.MVSIZEOF _ => mvexp
        | MV.MVINDEXOF _ => mvexp
        | MV.MVCONSTANT _ => mvexp
        | MV.MVGLOBALSYMBOL _ => mvexp
        | MV.MVEXCEPTIONTAG _ => mvexp
        | MV.MVVAR {varInfo as {varId,...},...} =>
          (case VarIdEnv.find(varEnv, varId)
            of SOME rootExp => rootExp
             | NONE => mvexp
          )
        | MV.MVGETFIELD {arrayExp, indexExp, elementTy, loc} =>
          MV.MVGETFIELD
              {
               arrayExp = optimizeArg varEnv arrayExp,
               indexExp = optimizeArg varEnv indexExp,
               elementTy = elementTy,
               loc = loc
              }
        | MV.MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
          MV.MVSETFIELD
              {
               valueExp = optimizeArg varEnv valueExp,
               arrayExp = optimizeArg varEnv arrayExp,
               indexExp = optimizeArg varEnv indexExp,
               elementTy = elementTy,
               loc = loc
              }
        | MV.MVSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
          MV.MVSETTAIL
              {
               consExp = optimizeArg varEnv consExp,
               newTailExp = optimizeArg varEnv newTailExp,
               listTy = listTy,
               consRecordTy = consRecordTy,
               tailLabel = tailLabel,
               loc = loc
              }
        | MV.MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
          MV.MVARRAY
              {
               sizeExp = optimizeArg varEnv sizeExp,
               initialValue = optimizeArg varEnv initialValue,
               elementTy = elementTy,
               isMutable = isMutable,
               loc = loc
              }
        | MV.MVCOPYARRAY
              {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
          MV.MVCOPYARRAY
              {
               srcExp = optimizeArg varEnv srcExp,
               srcIndexExp = optimizeArg varEnv srcIndexExp,
               dstExp = optimizeArg varEnv dstExp,
               dstIndexExp = optimizeArg varEnv dstIndexExp,
               lengthExp = optimizeArg varEnv lengthExp,
               elementTy = elementTy,
               loc = loc
              }
        | MV.MVPRIMAPPLY {primInfo as {ty,...}, argExpList, instTyList, loc} =>
          let
            val newExp =
                MV.MVPRIMAPPLY
                    {
                     primInfo = primInfo,
                     argExpList = map (optimizeArg varEnv) argExpList,
                     instTyList = instTyList,
                     loc = loc
                    }
          in
          (* constant folding can be applied here *)
            optimizePrimApply varEnv newExp
          end
        | MV.MVAPPM {funExp as MV.MVTAPP{exp, expTy, instTyList, loc = tappLoc}, funTy, argExpList, loc = appLoc} =>
          MV.MVAPPM
              {
               funExp = MV.MVTAPP
                            {
                             exp = optimizeArg varEnv exp,
                             expTy = expTy,
                             instTyList = instTyList,
                             loc = tappLoc
                            },
               funTy = funTy,
               argExpList = map (optimizeArg varEnv) argExpList,
               loc = appLoc
              }
        | MV.MVAPPM {funExp, funTy, argExpList, loc} =>
          MV.MVAPPM
              {
               funExp = optimizeArg varEnv funExp,
               funTy = funTy,
               argExpList = map (optimizeArg varEnv) argExpList,
               loc = loc
              }
        | MV.MVLET {localDeclList, mainExp, loc} =>
          let
            val (newLocalDeclList, newVarEnv, newRecordEnv, newCommonExpEnv) = 
                optimizeDeclList varEnv recordEnv commonExpEnv localDeclList
            val newMainExp = optimizeExp newVarEnv newRecordEnv newCommonExpEnv mainExp
          in 
            case newMainExp 
             of MV.MVLET {localDeclList, mainExp,...} =>
                MV.MVLET {localDeclList = newLocalDeclList @ localDeclList, mainExp = mainExp, loc = loc}
              | _ =>
                MV.MVLET {localDeclList = newLocalDeclList, mainExp = newMainExp, loc = loc}
          end
        | MV.MVMVALUES {expList, tyList, loc} =>
          MV.MVMVALUES
              {
               expList = map (optimizeArg varEnv) expList,
               tyList = tyList,
               loc = loc
              }
        | MV.MVRECORD {expList, recordTy, annotation, isMutable, loc} =>
          let
            val newExp = MV.MVRECORD
                             {
                              expList = map (optimizeArg varEnv) expList,
                              recordTy = recordTy,
                              annotation = annotation,
                              isMutable = isMutable,
                              loc = loc
                             }                         
          in
            if isMutable then newExp
            else commonSubexpressionEliminate commonExpEnv newExp
          end
        | MV.MVSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
          let 
            val newRecordExp = optimizeArg varEnv recordExp
            val indexExp = optimizeArg varEnv indexExp

            fun lookupField kind =
                case VarIdEnv.find(recordEnv, kind)
                 of SOME fields => 
                    (
                     case SEnv.find(fields,label)
                      of SOME exp => exp
                       | NONE =>
                         (* this code should either be eliminated by switch optimization
                          * or never be reached at runtime. Then use a dummy field instead.
                          *) 
                         MV.MVCONSTANT {value = CT.INT 0, loc = loc}
                    )
                  | NONE => 
                    let 
                      val newExp = MV.MVSELECT {recordExp = newRecordExp, 
                                                indexExp = indexExp,
                                                label = label,
                                                recordTy = recordTy, 
                                                resultTy = resultTy,
                                                loc = loc}
                    in 
                      commonSubexpressionEliminate commonExpEnv newExp
                    end
          in 
            case newRecordExp
             of MV.MVVAR {varInfo as {varId,...},...} => lookupField varId
              | MV.MVCAST {exp = MV.MVVAR {varInfo = {varId,...},...},...} => lookupField varId
              | _ => 
                (* this code should either be eliminated by switch optimization
                          * or never be reached at runtime. Then use a dummy field instead.
                          *) 
                MV.MVCONSTANT {value = CT.INT 0, loc = loc}
          end
        | MV.MVMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy, loc} =>
          let
            val newExp = MV.MVMODIFY
                             {
                              recordExp = optimizeArg varEnv recordExp,
                              recordTy = recordTy,
                              indexExp = optimizeArg varEnv indexExp,
                              label = label,
                              valueExp = optimizeArg varEnv valueExp,
                              valueTy = valueTy,
                              loc = loc
                             }                         
          in 
            commonSubexpressionEliminate commonExpEnv newExp
          end
        | MV.MVRAISE {argExp, resultTy, loc} =>
          MV.MVRAISE
              {
               argExp = optimizeArg varEnv argExp,
               resultTy = resultTy,
               loc = loc
              }
        | MV.MVHANDLE {exp, exnVar, handler, loc} =>
          MV.MVHANDLE
              {
               exp = optimizeExp varEnv recordEnv commonExpEnv exp,
               exnVar = exnVar,
               handler = optimizeExp varEnv recordEnv commonExpEnv handler,
               loc = loc
              }
        | MV.MVFNM {argVarList, funTy, bodyExp, annotation, loc} =>
          MV.MVFNM
              {
               argVarList = argVarList,
               funTy = funTy,
               bodyExp = optimizeExp varEnv recordEnv commonExpEnv bodyExp,
               annotation = annotation,
               loc = loc
              }
        | MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
          MV.MVPOLY
              {
               btvEnv = btvEnv,
               expTyWithoutTAbs = expTyWithoutTAbs,
               exp = optimizeExp varEnv recordEnv commonExpEnv exp,
               loc = loc
              }
        | MV.MVTAPP {exp, expTy, instTyList, loc} =>
          MV.MVTAPP
              {
               exp = optimizeArg varEnv exp,
               expTy = expTy,
               instTyList = instTyList,
               loc = loc
              }
        | MV.MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
          let 
            fun optimizeBranch {constant, exp} =
                {
                 constant = constant,
                 exp = optimizeExp varEnv recordEnv commonExpEnv exp
                }
            val newSwitchExp = optimizeArg varEnv switchExp
            val newBranches = map optimizeBranch branches
            val newDefaultExp = optimizeExp varEnv recordEnv commonExpEnv defaultExp

            fun lookupBranch v [] = newDefaultExp
              | lookupBranch v ({constant as MV.MVCONSTANT {value,...}, exp}::rest) = 
                (
                 case ConstantTerm.compare(value,v)
                  of EQUAL => exp
                   | _ => lookupBranch v rest 
                )
              | lookupBranch v _ = raise Control.Bug "non MVCONSTANT in lookupBranch : (mvoptimization/main/MVOptimization.sml)"
          in 
            case newSwitchExp of
              MV.MVCONSTANT {value, loc} => lookupBranch value newBranches
            | MV.MVCAST {exp = MV.MVCONSTANT {value, loc},...} => lookupBranch value newBranches
            | _ =>
              MV.MVSWITCH 
                  {
                   switchExp = newSwitchExp,
                   expTy = expTy,
                   branches = newBranches,
                   defaultExp = newDefaultExp, 
                   loc = loc
                  }
          end
        | MV.MVCAST {exp, expTy, targetTy, loc} =>
          (
           case optimizeExp varEnv recordEnv commonExpEnv exp
            of MV.MVLET {localDeclList, mainExp as MV.MVCAST{exp, expTy,loc=loc1,...},...} =>
               MV.MVLET 
                   {
                    localDeclList = localDeclList,
                    mainExp = MV.MVCAST {exp = exp, expTy = expTy, targetTy = targetTy, loc = loc1},
                    loc = loc
                   }
             | MV.MVLET {localDeclList, mainExp,...} => 
               MV.MVLET 
                   {
                    localDeclList = localDeclList,
                    mainExp = MV.MVCAST {exp = mainExp, expTy = expTy, targetTy = targetTy, loc = loc},
                    loc = loc
                   }
             | MV.MVCAST {exp, expTy,...} => MV.MVCAST {exp = exp, expTy = expTy, targetTy = targetTy, loc = loc}
             | exp => MV.MVCAST {exp = exp, expTy = expTy, targetTy = targetTy, loc = loc}
          )

  and optimizeDecl varEnv recordEnv commonExpEnv mvdecl =
      case mvdecl
       of MV.MVVAL {boundVars, boundExp, loc} => 
          let 
            fun firstID ({displayName,ty, varId}::L) = varId
              | firstID nil = raise Control.Bug "nil to fistID : (mvoptimization/main/MVOptimization.sml)"

            fun simplifyDecl decl =
                case decl
                 of MV.MVVAL {boundVars, boundExp, loc} => 
                    (case boundExp
                      of MV.MVLET {localDeclList, mainExp, ...} => 
                         localDeclList @ (simplifyDecl (MV.MVVAL {boundVars = boundVars, boundExp = mainExp, loc = loc}))
                       | MV.MVMVALUES {expList, tyList, ...} => 
                         ListPair.map 
                             (fn (varInfo,exp) => MV.MVVAL {boundVars = [varInfo], boundExp = exp, loc = loc})
                             (boundVars, expList)
                       | _ => [decl]
                    )
                  | MV.MVVALREC {recbindList, loc} => [decl]

            fun uncastedExp (exp, expTy, targetTy, expLoc) =
                let 
                  val varInfo = newVar expTy
                  val newDecl = MV.MVVAL{boundVars = [varInfo], boundExp = exp, loc = loc}
                  val castedExp = 
                      MV.MVCAST
                          {
                           exp = MV.MVVAR {varInfo = varInfo, loc = expLoc}, 
                           expTy = expTy, 
                           targetTy = targetTy, 
                           loc = expLoc
                          }
                in 
                  (varInfo, newDecl, castedExp)
                end

            fun addRecordBind(id,MV.MVRECORD {expList, recordTy as AT.RECORDty {fieldTypes,...},...}) =
                let 
                  val fields =
                      ListPair.foldl
                          (fn (label,exp,S) => SEnv.insert(S,label,exp))
                          SEnv.empty
                          (SEnv.listKeys fieldTypes, expList)
                in 
                  VarIdEnv.insert(recordEnv,id,fields)
                end
              | addRecordBind _ = 
                raise Control.Bug "non MVRECORD to addRecordBind : (mvoptimization/main/MVOptimization.sml)"


            fun filter (decl as MV.MVVAL {boundVars, boundExp, loc}, (declList, varEnv, recordEnv, commonExpEnv)) =
                (case boundExp
                  of MV.MVCONSTANT _ =>
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVGLOBALSYMBOL _ =>
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVEXCEPTIONTAG _ => 
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVVAR _ => 
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVRECORD {isMutable,...} => 
                     if isMutable 
                     then (decl::declList, varEnv, recordEnv, commonExpEnv)
                     else
                       (
                        decl::declList,
                        varEnv, 
                        addRecordBind(firstID boundVars, boundExp), 
                        CommonExpEnv.insert(commonExpEnv,boundExp,List.hd boundVars)
                        )
                   | MV.MVSELECT _ =>
                     (
                      decl::declList,
                      varEnv, 
                      recordEnv, 
                      CommonExpEnv.insert(commonExpEnv,boundExp,List.hd boundVars)
                     )
                   | MV.MVMODIFY _ =>
                     (
                      decl::declList,
                      varEnv, 
                      recordEnv, 
                      CommonExpEnv.insert(commonExpEnv,boundExp,List.hd boundVars)
                     )
                   | MV.MVCAST {exp = MV.MVCONSTANT _, ...} => 
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp = MV.MVGLOBALSYMBOL _, ...} => 
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp = MV.MVEXCEPTIONTAG _, ...} =>
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp = MV.MVVAR _, ...} =>
                     if ATU.isGlobal (hd boundVars)
                     then (decl::declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                     else (declList, VarIdEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp as (MV.MVRECORD {isMutable,...}), expTy, targetTy, loc = expLoc} => 
                     if isMutable
                     then (decl::declList, varEnv, recordEnv, commonExpEnv)
                     else
                       let 
                         val (varInfo as {varId,...}, uncastedDecl, castedExp) = 
                           uncastedExp (exp, expTy, targetTy, expLoc)
                         val decls = 
                             if ATU.isGlobal (hd boundVars)
                             then (MV.MVVAL {boundVars = boundVars, boundExp = castedExp, loc = loc})::uncastedDecl::declList
                             else uncastedDecl::declList
                       in 
                         (
                          decls,
                          VarIdEnv.insert(varEnv,firstID boundVars, castedExp),
                          addRecordBind(varId, exp), 
                          CommonExpEnv.insert(commonExpEnv,exp,varInfo)
                          )
                     end
                   | MV.MVCAST {exp as MV.MVSELECT _, expTy, targetTy, loc = expLoc} => 
                     let 
                       val (varInfo, uncastedDecl, castedExp) = uncastedExp (exp, expTy, targetTy, expLoc)
                       val decls = 
                           if ATU.isGlobal (hd boundVars)
                           then (MV.MVVAL {boundVars = boundVars, boundExp = castedExp, loc = loc})::uncastedDecl::declList
                           else uncastedDecl::declList
                     in 
                       (
                        decls,
                        VarIdEnv.insert(varEnv,firstID boundVars, castedExp),
                        recordEnv, 
                        CommonExpEnv.insert(commonExpEnv,exp,varInfo)
                       )
                     end
                   | MV.MVCAST {exp as MV.MVMODIFY _, expTy, targetTy, loc = expLoc} => 
                     let 
                       val (varInfo, uncastedDecl, castedExp) = uncastedExp (exp, expTy, targetTy, expLoc)
                       val decls = 
                           if ATU.isGlobal (hd boundVars)
                           then (MV.MVVAL {boundVars = boundVars, boundExp = castedExp, loc = loc})::uncastedDecl::declList
                           else uncastedDecl::declList
                     in 
                       (
                        decls,
                        VarIdEnv.insert(varEnv,firstID boundVars, castedExp),
                        recordEnv, 
                        CommonExpEnv.insert(commonExpEnv,exp,varInfo)
                       )
                     end
                   | MV.MVCAST {exp, expTy, targetTy, loc = expLoc} => 
                     let 
                       val (varInfo, uncastedDecl, castedExp) = uncastedExp (exp, expTy, targetTy, expLoc)
                       val decls = 
                           if ATU.isGlobal (hd boundVars)
                           then (MV.MVVAL {boundVars = boundVars, boundExp = castedExp, loc = loc})::uncastedDecl::declList
                           else uncastedDecl::declList
                     in 
                       (
                        decls,
                        VarIdEnv.insert(varEnv,firstID boundVars, castedExp),
                        recordEnv, 
                        commonExpEnv
                       )
                     end
                   | _ => (decl::declList, varEnv, recordEnv, commonExpEnv)
                )
              | filter (decl, (declList, varEnv, recordEnv, commonExpEnv)) = 
                (decl::declList, varEnv, recordEnv, commonExpEnv)

            val declList = 
                simplifyDecl 
                    (MV.MVVAL 
                         {
                          boundVars = boundVars, 
                          boundExp = optimizeExp varEnv recordEnv commonExpEnv boundExp, 
                          loc = loc
                         }
                    )

            val (declListRev, newVarEnv, newRecordEnv, newCommonExpEnv) =     
                foldl filter ([],varEnv,recordEnv,commonExpEnv) declList
          in
            (rev declListRev, newVarEnv, newRecordEnv, newCommonExpEnv)
          end
        | MV.MVVALREC {recbindList, loc} => 
          let 
            val newRecbindList =
                map 
                    (fn {boundVar, boundExp} =>
                        {boundVar = boundVar, boundExp = optimizeExp varEnv recordEnv commonExpEnv boundExp}
                    )
                    recbindList
            val decl = MV.MVVALREC {recbindList = newRecbindList, loc = loc}
          in 
            ([decl], varEnv, recordEnv, commonExpEnv)
          end

  and optimizeDeclList varEnv recordEnv commonExpEnv [] = ([],varEnv,recordEnv,commonExpEnv)
    | optimizeDeclList varEnv recordEnv commonExpEnv (decl::declList) =
      let 
        val (decls1,newVarEnv,newRecordEnv,newCommonExpEnv) = 
            optimizeDecl varEnv recordEnv commonExpEnv decl
        val (decls2,newVarEnv,newRecordEnv,newCommonExpEnv) =
            optimizeDeclList newVarEnv newRecordEnv newCommonExpEnv declList
      in 
        (decls1 @ decls2, newVarEnv, newRecordEnv, newCommonExpEnv)
      end

end
