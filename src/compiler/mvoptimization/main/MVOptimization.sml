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
  structure VEnv = ID.Map
  structure ATU = AnnotatedTypesUtils
  structure CT = ConstantTerm



  structure MVExp_ord:ordsig = struct

    type ord_key = MV.mvexp

    fun argCompare (x,y) =
        case (x,y) of
          (MV.MVCAST {exp = exp1, ...}, exp2) => argCompare (exp1, exp2)
        | (exp1, MV.MVCAST {exp = exp2,...}) => argCompare (exp1, exp2)
        | (MV.MVEXCEPTIONTAG {tagValue = i1,...}, MV.MVEXCEPTIONTAG {tagValue = i2,...}) =>
          Int.compare(i1,i2)
        | (MV.MVCONSTANT _, MV.MVEXCEPTIONTAG _) => GREATER
        | (MV.MVCONSTANT {value = c1,...}, MV.MVCONSTANT {value = c2,...}) =>
          ConstantTerm.compare(c1,c2)
        | (MV.MVCONSTANT _, _) => LESS
        | (MV.MVVAR _, MV.MVEXCEPTIONTAG _) => GREATER
        | (MV.MVVAR _, MV.MVCONSTANT _) => GREATER
        | (MV.MVVAR {varInfo = {id = id1,...},...}, MV.MVVAR {varInfo = {id = id2,...},...}) =>
          ID.compare(id1,id2)
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
        | (MV.MVSELECT {recordExp = recordExp1, label = label1,...},
           MV.MVSELECT {recordExp = recordExp2, label = label2,...}) =>
          (
           case String.compare(label1,label2) of
             EQUAL => argCompare(recordExp1,recordExp2)
           | d => d 
          )
        | (MV.MVSELECT _, _) => LESS

        | (MV.MVMODIFY _, MV.MVRECORD {isMutable=false,...}) => GREATER
        | (MV.MVMODIFY _, MV.MVSELECT _) => GREATER
        | (MV.MVMODIFY {recordExp = recordExp1, label = label1, valueExp = valueExp1,...},
           MV.MVMODIFY {recordExp = recordExp2, label = label2, valueExp = valueExp2,...}) =>
          (
           case String.compare(label1,label2) of
             EQUAL => argsCompare([recordExp1,valueExp1],[recordExp2,valueExp2])
           | d => d 
          )
 
        | _ =>  raise Control.Bug "invalid atomEnv"
  end

  structure CommonExpEnv = BinaryMapFn(MVExp_ord)

  fun optimizePrimApply varEnv (exp as MV.MVPRIMAPPLY {primInfo, argExpList, loc}) =
      if !Control.doConstantFolding
      then
        let
          exception ConstantNotFound

          fun intOf (MV.MVCONSTANT {value = CT.INT v,...}) = v
            | intOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.INT v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | intOf _ = raise ConstantNotFound
          fun genericIntOf (MV.MVCONSTANT {value = CT.INT v,...}) = Int32.toInt v
            | genericIntOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.INT v,...}) => Int32.toInt v
                 | _ => raise ConstantNotFound
              )
            | genericIntOf _ = raise ConstantNotFound
          fun wordOf (MV.MVCONSTANT {value = CT.WORD v,...}) = v
            | wordOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.WORD v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | wordOf _ = raise ConstantNotFound
          fun genericWordOf (MV.MVCONSTANT {value = CT.WORD v,...}) = Word.fromLargeWord (Word32.toLargeWord v)
            | genericWordOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.WORD v,...}) => Word.fromLargeWord (Word32.toLargeWord v)
                 | _ => raise ConstantNotFound
              )
            | genericWordOf _ = raise ConstantNotFound
          fun realOf (MV.MVCONSTANT {value = CT.REAL v,...}) = valOf(Real.fromString v)
            | realOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.REAL v,...}) => valOf(Real.fromString v)
                 | _ => raise ConstantNotFound
              )
            | realOf _ = raise ConstantNotFound
          fun floatOf (MV.MVCONSTANT {value = CT.FLOAT v,...}) = valOf(Real.fromString v)
            | floatOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.FLOAT v,...}) => valOf(Real.fromString v)
                 | _ => raise ConstantNotFound
              )
            | floatOf _ = raise ConstantNotFound
          fun charOf (MV.MVCONSTANT {value = CT.CHAR v,...}) = v
            | charOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.CHAR v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | charOf _ = raise ConstantNotFound
          fun byteOf (MV.MVCONSTANT {value = CT.WORD v,...}) = v
            | byteOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.WORD v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | byteOf _ = raise ConstantNotFound
          fun stringOf (MV.MVCONSTANT {value = CT.STRING v,...}) = v
            | stringOf (MV.MVVAR {varInfo as {id,...},...}) = 
              (
               case VEnv.find(varEnv,id)
                of SOME (MV.MVCONSTANT {value = CT.STRING v,...}) => v
                 | _ => raise ConstantNotFound
              )
            | stringOf _ = raise ConstantNotFound


          fun intToExp v = MV.MVCONSTANT {value = CT.INT v, loc = loc}
          fun genericIntToExp v = MV.MVCONSTANT {value = CT.INT (Int32.fromInt v), loc = loc}
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
                     exp = MV.MVCONSTANT {value = CT.INT (Int32.fromInt Constants.TAG_bool_true), loc = loc},
                     expTy = AT.intty,
                     targetTy = AT.boolty,
                     loc = loc
                    }
              else 
                MV.MVCAST
                    {
                     exp = MV.MVCONSTANT {value = CT.INT (Int32.fromInt Constants.TAG_bool_false), loc = loc},
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
             ("addInt",[MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg2
           | ("addInt",[arg1,MV.MVCONSTANT {value = CT.INT 0,...}]) => arg1
           | ("addInt", _) => optimize2 intOf intOf intToExp ( op + ) 
           | ("addWord",[MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
           | ("addWord",[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("addWord", _) => optimize2 wordOf wordOf wordToExp ( op + ) 
           | ("addReal", _) => optimize2 realOf realOf realToExp ( op + ) 
           | ("addByte",[MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
           | ("addByte",[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("addByte", _) => optimize2 byteOf byteOf byteToExp ( op + ) 

           | ("subInt",[arg1,MV.MVCONSTANT {value = CT.INT 0,...}]) => arg1
           | ("subInt", _) => optimize2 intOf intOf intToExp ( op - ) 
           | ("subWord",[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("subWord", _) => optimize2 wordOf wordOf wordToExp ( op - ) 
           | ("subReal", _) => optimize2 realOf realOf realToExp ( op - ) 
           | ("subByte",[arg1,MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("subByte", _) => optimize2 byteOf byteOf byteToExp ( op - ) 

           | ("mulInt",[arg1 as MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg1
           | ("mulInt",[arg1 as MV.MVCONSTANT {value = CT.INT 1,...},arg2]) => arg2
           | ("mulInt",[arg1,arg2 as MV.MVCONSTANT {value = CT.INT 0,...}]) => arg2
           | ("mulInt",[arg1,arg2 as MV.MVCONSTANT {value = CT.INT 1,...}]) => arg1
           | ("mulInt", _) => optimize2 intOf intOf intToExp ( op * ) 
           | ("mulWord",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("mulWord",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w1,...},arg2]) => arg2
           | ("mulWord",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg2
           | ("mulWord",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w1,...}]) => arg1
           | ("mulWord", _) => optimize2 wordOf wordOf wordToExp ( op * ) 
           | ("mulReal", _) => optimize2 realOf realOf realToExp ( op * ) 
           | ("mulByte",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("mulByte",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w1,...},arg2]) => arg2
           | ("mulByte",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg2
           | ("mulByte",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w1,...}]) => arg1
           | ("mulByte", _) => optimize2 byteOf byteOf byteToExp ( op * ) 

           | ("divInt",[arg1 as MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg1
           | ("divInt", _) => optimize2 intOf intOf intToExp ( op div ) 
           | ("divWord",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("divWord", _) => optimize2 wordOf wordOf wordToExp ( op div ) 
           | ("divReal", _) => optimize2 realOf realOf realToExp ( op / ) 
           | ("divByte",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("divByte", _) => optimize2 byteOf byteOf byteToExp ( op div ) 

           | ("modInt",[arg1 as MV.MVCONSTANT {value = CT.INT 0,...},arg2]) => arg1
           | ("modInt", _) => optimize2 intOf intOf intToExp ( op mod ) 
           | ("modWord",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("modWord", _) => optimize2 wordOf wordOf wordToExp ( op mod ) 
           | ("modByte",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("modByte", _) => optimize2 byteOf byteOf byteToExp ( op mod ) 

           | ("quotInt", _) => optimize2 intOf intOf intToExp ( Int32.quot ) 
           | ("remInt", _) => optimize2 intOf intOf intToExp ( Int32.rem ) 

           | ("negInt", _) => optimize1 intOf intToExp ~  
           | ("negReal", _) => optimize1 realOf realToExp ~ 

           | ("ltInt", _) => optimize2 intOf intOf boolToExp ( op < ) 
           | ("ltWord", _) => optimize2 wordOf wordOf boolToExp ( op < ) 
           | ("ltReal", _) => optimize2 realOf realOf boolToExp ( op < ) 
           | ("ltByte", _) => optimize2 byteOf byteOf boolToExp ( op < ) 
           | ("ltChar", _) => optimize2 charOf charOf boolToExp ( op < ) 
           | ("ltString", _) => optimize2 stringOf stringOf boolToExp ( op < ) 

           | ("gtInt", _) => optimize2 intOf intOf boolToExp ( op > ) 
           | ("gtWord", _) => optimize2 wordOf wordOf boolToExp ( op > ) 
           | ("gtReal", _) => optimize2 realOf realOf boolToExp ( op > ) 
           | ("gtByte", _) => optimize2 byteOf byteOf boolToExp ( op > ) 
           | ("gtChar", _) => optimize2 charOf charOf boolToExp ( op > ) 
           | ("gtString", _) => optimize2 stringOf stringOf boolToExp ( op > ) 

           | ("lteqInt", _) => optimize2 intOf intOf boolToExp ( op <= ) 
           | ("lteqWord", _) => optimize2 wordOf wordOf boolToExp ( op <= ) 
           | ("lteqReal", _) => optimize2 realOf realOf boolToExp ( op <= ) 
           | ("lteqByte", _) => optimize2 byteOf byteOf boolToExp ( op <= ) 
           | ("lteqChar", _) => optimize2 charOf charOf boolToExp ( op <= ) 
           | ("lteqString", _) => optimize2 stringOf stringOf boolToExp ( op <= ) 

           | ("gteqInt", _) => optimize2 intOf intOf boolToExp ( op >= ) 
           | ("gteqWord", _) => optimize2 wordOf wordOf boolToExp ( op >= ) 
           | ("gteqReal", _) => optimize2 realOf realOf boolToExp ( op >= ) 
           | ("gteqByte", _) => optimize2 byteOf byteOf boolToExp ( op >= ) 
           | ("gteqChar", _) => optimize2 charOf charOf boolToExp ( op >= ) 
           | ("gteqString", _) => optimize2 stringOf stringOf boolToExp ( op >= )

           | ("Word_toIntX", _) => optimize1 wordOf intToExp (Word32.toLargeIntX)          
           | ("Word_fromInt", _) => optimize1 intOf wordToExp (Word32.fromLargeInt)          

           | ("Word_andb",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("Word_andb",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg2
           | ("Word_andb", _) => optimize2 wordOf wordOf wordToExp ( Word32.andb ) 

           | ("Word_orb",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
           | ("Word_orb",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("Word_orb", _) => optimize2 wordOf wordOf wordToExp ( Word32.orb ) 

           | ("Word_xorb", _) => optimize2 wordOf wordOf wordToExp ( Word32.xorb ) 
           | ("Word_notb", _) => optimize1 wordOf wordToExp ( Word32.notb ) 

           | ("Word_leftShift",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("Word_leftShift",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("Word_leftShift", _) => optimize2 wordOf genericWordOf wordToExp ( Word32.<< ) 

           | ("Word_logicalRightShift",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("Word_logicalRightShift",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("Word_logicalRightShift", _) => optimize2 wordOf genericWordOf wordToExp ( Word32.>> ) 

           | ("Word_arithmeticRightShift",[arg1 as MV.MVCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
           | ("Word_arithmeticRightShift",[arg1,arg2 as MV.MVCONSTANT {value = CT.WORD 0w0,...}]) => arg1
           | ("Word_arithmeticRightShift", _) => optimize2 wordOf genericWordOf wordToExp ( Word32.~>> ) 

           | ("Int_toString", _) => optimize1 intOf stringToExp (Int32.toString)          
           | ("Word_toString", _) => optimize1 wordOf stringToExp (Word32.toString)       

           | ("Real_fromInt", _) => optimize1 intOf realToExp (Real.fromLargeInt)             
           | ("Real_toString", _) => optimize1 realOf stringToExp (Real.toString)       
           | ("Real_floor", _) => optimize1 realOf genericIntToExp (Real.floor)
           | ("Real_ceil", _) => optimize1 realOf genericIntToExp (Real.ceil)
           | ("Real_trunc", _) => optimize1 realOf genericIntToExp (Real.trunc)
           | ("Real_round", _) => optimize1 realOf genericIntToExp (Real.round)

           | ("Char_toString", _) => optimize1 charOf stringToExp (Char.toString)       
           | ("Char_ord", _) => optimize1 charOf genericIntToExp (Char.ord)       
           | ("Char_chr", _) => optimize1 genericIntOf charToExp (Char.chr)

           | ("String_concat2", _) => optimize2 stringOf stringOf stringToExp ( op ^ )        
           | ("String_sub", _) => optimize2 stringOf genericIntOf charToExp ( String.sub )        
           | ("String_size", _) => optimize1 stringOf genericIntToExp ( String.size )        
           | ("String_substring", _) => optimize3 stringOf genericIntOf genericIntOf stringToExp ( String.substring )        

           | ("Math_sqrt", _) => optimize1 realOf realToExp ( Math.sqrt )
           | ("Math_sin", _) => optimize1 realOf realToExp ( Math.sin )
           | ("Math_cos", _) => optimize1 realOf realToExp ( Math.cos )
           | ("Math_tan", _) => optimize1 realOf realToExp ( Math.tan )
           | ("Math_asin", _) => optimize1 realOf realToExp ( Math.asin )
           | ("Math_acos", _) => optimize1 realOf realToExp ( Math.acos )
           | ("Math_atan", _) => optimize1 realOf realToExp ( Math.atan )
           | ("Math_atan2", _) => optimize2 realOf realOf realToExp ( Math.atan2 )
           | ("Math_exp", _) => optimize1 realOf realToExp ( Math.exp )
           | ("Math_pow", _) => optimize2 realOf realOf realToExp ( Math.pow )
           | ("Math_ln", _) => optimize1 realOf realToExp ( Math.ln )
           | ("Math_log10", _) => optimize1 realOf realToExp ( Math.log10 )
           | ("Math_sinh", _) => optimize1 realOf realToExp ( Math.sinh )
           | ("Math_cosh", _) => optimize1 realOf realToExp ( Math.cosh )
           | ("Math_tanh", _) => optimize1 realOf realToExp ( Math.tanh )


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
        | MV.MVEXCEPTIONTAG _ => argExp
        | MV.MVVAR {varInfo as {id,...},...} =>
          (case VEnv.find(varEnv, id)
            of SOME rootExp => rootExp
             | NONE => argExp
          )
        | MV.MVCAST {exp = MV.MVCONSTANT _ , ...} => argExp
        | MV.MVCAST {exp = MV.MVEXCEPTIONTAG _ , ...} => argExp
        | MV.MVCAST {exp = MV.MVVAR {varInfo as {id,...},...}, expTy, targetTy, loc} => 
          (case VEnv.find(varEnv, id)
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
       of MV.MVFOREIGNAPPLY{funExp, funTy, argExpList, convention, loc} => 
          MV.MVFOREIGNAPPLY
              {
               funExp = optimizeArg varEnv funExp,
               funTy = funTy,
               argExpList = map (optimizeArg varEnv) argExpList,
               convention = convention,
               loc = loc
              }
        | MV.MVEXPORTCALLBACK {funExp, funTy, loc} =>
          MV.MVEXPORTCALLBACK
              {
               funExp = optimizeArg varEnv funExp,
               funTy = funTy, 
               loc = loc
              }
        | MV.MVSIZEOF _ => mvexp
        | MV.MVCONSTANT _ => mvexp
        | MV.MVEXCEPTIONTAG _ => mvexp
        | MV.MVVAR {varInfo as {id,...},...} =>
          (case VEnv.find(varEnv, id)
            of SOME rootExp => rootExp
             | NONE => mvexp
          )
        | MV.MVGETGLOBAL {arrayIndex, valueIndex, valueTy, loc} => mvexp
        | MV.MVSETGLOBAL {arrayIndex, valueIndex, valueExp, valueTy, loc} =>
          MV.MVSETGLOBAL
              {
               arrayIndex = arrayIndex,
               valueIndex = valueIndex,
               valueExp = optimizeArg varEnv valueExp,
               valueTy = valueTy,
               loc = loc
              }
        | MV.MVINITARRAY {arrayIndex, size, elementTy, loc} => mvexp
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
        | MV.MVARRAY {sizeExp, initialValue, elementTy, loc} =>
          MV.MVARRAY
              {
               sizeExp = optimizeArg varEnv sizeExp,
               initialValue = optimizeArg varEnv initialValue,
               elementTy = elementTy,
               loc = loc
              }
        | MV.MVPRIMAPPLY {primInfo as {ty,...}, argExpList, loc} =>
          let
            val newExp =
                MV.MVPRIMAPPLY
                    {
                     primInfo = primInfo,
                     argExpList = map (optimizeArg varEnv) argExpList,
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
        | MV.MVSELECT {recordExp, label, recordTy, loc} =>
          let 
            val newRecordExp = optimizeArg varEnv recordExp

            fun lookupField id =
                case VEnv.find(recordEnv, id)
                 of SOME fields => valOf(SEnv.find(fields,label))
                  | NONE => 
                    let 
                      val newExp = MV.MVSELECT {recordExp = newRecordExp, 
                                                label = label, 
                                                recordTy = recordTy, 
                                                loc = loc}
                    in 
                      commonSubexpressionEliminate commonExpEnv newExp
                    end
          in 
            case newRecordExp
             of MV.MVVAR {varInfo as {id,...},...} => lookupField id
              | MV.MVCAST {exp = MV.MVVAR {varInfo = {id,...},...},...} => lookupField id
              | _ => raise Control.Bug "invalid record argument"
          end
        | MV.MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
          let
            val newExp = MV.MVMODIFY
                             {
                              recordExp = optimizeArg varEnv recordExp,
                              recordTy = recordTy,
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
            fun firstID ({id,displayName,ty}::L) = id

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
                  | MV.MVVALPOLYREC {btvEnv, recbindList, loc} => [decl]

            fun uncastedExp (exp, expTy, targetTy, expLoc) =
                let 
                  val varInfo = ATU.newVar expTy
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
                  VEnv.insert(recordEnv,id,fields)
                end


            fun filter (decl as MV.MVVAL {boundVars, boundExp, loc}, (declList, varEnv, recordEnv, commonExpEnv)) =
                (case boundExp
                  of MV.MVCONSTANT _ => 
                     (declList, VEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVEXCEPTIONTAG _ => 
                     (declList, VEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVVAR _ => 
                     (declList, VEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVRECORD {isMutable,...} => 
                     if isMutable then
                       (decl::declList, varEnv, recordEnv, commonExpEnv)
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
                     (declList, VEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp = MV.MVEXCEPTIONTAG _, ...} =>
                     (declList, VEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp = MV.MVVAR _, ...} =>
                     (declList, VEnv.insert(varEnv,firstID boundVars,boundExp), recordEnv, commonExpEnv)
                   | MV.MVCAST {exp as (MV.MVRECORD {isMutable,...}), expTy, targetTy, loc = expLoc} => 
                     if isMutable then
                       (decl::declList, varEnv, recordEnv, commonExpEnv)
                     else
                       let 
                         val (varInfo as {id,...}, uncastedDecl, castedExp) = 
                           uncastedExp (exp, expTy, targetTy, expLoc)
                       in 
                         (
                          uncastedDecl::declList,
                          VEnv.insert(varEnv,firstID boundVars, castedExp),
                          addRecordBind(id, exp), 
                          CommonExpEnv.insert(commonExpEnv,exp,varInfo)
                          )
                     end
                   | MV.MVCAST {exp as MV.MVSELECT _, expTy, targetTy, loc = expLoc} => 
                     let 
                       val (varInfo as {id,...}, uncastedDecl, castedExp) = uncastedExp (exp, expTy, targetTy, expLoc)
                     in 
                       (
                        uncastedDecl::declList,
                        VEnv.insert(varEnv,firstID boundVars, castedExp),
                        recordEnv, 
                        CommonExpEnv.insert(commonExpEnv,exp,varInfo)
                       )
                     end
                   | MV.MVCAST {exp as MV.MVMODIFY _, expTy, targetTy, loc = expLoc} => 
                     let 
                       val (varInfo as {id,...}, uncastedDecl, castedExp) = uncastedExp (exp, expTy, targetTy, expLoc)
                     in 
                       (
                        uncastedDecl::declList,
                        VEnv.insert(varEnv,firstID boundVars, castedExp),
                        recordEnv, 
                        CommonExpEnv.insert(commonExpEnv,exp,varInfo)
                       )
                     end
                   | MV.MVCAST {exp, expTy, targetTy, loc = expLoc} => 
                     let 
                       val (varInfo as {id,...}, uncastedDecl, castedExp) = uncastedExp (exp, expTy, targetTy, expLoc)
                     in 
                       (
                        uncastedDecl::declList,
                        VEnv.insert(varEnv,firstID boundVars, castedExp),
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
        | MV.MVVALPOLYREC {btvEnv, recbindList, loc} => 
          let 
            val newRecbindList =
                map 
                    (fn {boundVar, boundExp} =>
                        {boundVar = boundVar, boundExp = optimizeExp varEnv recordEnv commonExpEnv boundExp}
                    )
                    recbindList
            val decl = MV.MVVALPOLYREC {btvEnv = btvEnv, recbindList = newRecbindList, loc = loc}
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


  fun optimize declList = 
      let 
        val (newDeclList,_,_,_) = optimizeDeclList VEnv.empty VEnv.empty CommonExpEnv.empty declList
        val newDeclList =
            if !Control.doUselessCodeElimination
            then UselessCodeElimination.optimize newDeclList
            else newDeclList
      in 
        newDeclList
      end

end
