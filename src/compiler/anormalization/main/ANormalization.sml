(**
 * ANormalization
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure ANormalization : ANORMALIZATION = struct

  structure CT = ConstantTerm
  structure AT = AnnotatedTypes 
  structure ATU = AnnotatedTypesUtils
  structure BT = BasicTypes
  structure RBU = RBUCalc
  structure VEnv = ID.Map
  structure ANU = ANormalUtils

  open ANormal

  structure ANExp_ord:ordsig = struct

    type ord_key = anexp

    fun argCompare (x,y) =
        case (x,y) of
          (ANEXCEPTIONTAG {tagValue = i1,...}, ANEXCEPTIONTAG {tagValue = i2,...}) =>
          BT.UInt32.compare(i1,i2)

        | (ANCONSTANT _, ANEXCEPTIONTAG _) => GREATER
        | (ANCONSTANT {value = c1,...}, ANCONSTANT {value = c2,...}) =>
          CT.compare(c1,c2)
        | (ANCONSTANT _, _) => LESS

        | (ANVAR _, ANEXCEPTIONTAG _) => GREATER
        | (ANVAR _, ANCONSTANT _) => GREATER
        | (ANVAR {varInfo = {id = id1,...},...}, ANVAR {varInfo = {id = id2,...},...}) =>
          ID.compare(id1,id2)
        | (ANVAR _, _) => LESS

        | (ANLABEL _, ANEXCEPTIONTAG _) => GREATER
        | (ANLABEL _, ANCONSTANT _) => GREATER
        | (ANLABEL _, ANVAR _) => GREATER
        | (ANLABEL {codeId = codeId1,...}, ANLABEL {codeId=codeId2,...}) => ID.compare(codeId1,codeId2)
        | _ => raise Control.Bug "invalid argument"

    fun argsCompare (argList1,argList2) = ATU.listCompare argCompare (argList1,argList2)

    fun stringsCompare (L1,L2) = ATU.listCompare String.compare (L1,L2)

    fun compare (x,y) =
        case (x,y) of
          (ANENVACC {nestLevel = nestLevel1, offset = offset1,...},
           ANENVACC {nestLevel = nestLevel2, offset = offset2,...}) =>
          ATU.wordPairCompare((nestLevel1,offset1),(nestLevel2,offset2))
        | (ANENVACC _, _) => LESS

        | (ANGETGLOBAL _, ANENVACC _) => GREATER
        | (ANGETGLOBAL {arrayIndex = arrayIndex1, valueOffset = offset1,...},
           ANGETGLOBAL {arrayIndex = arrayIndex2, valueOffset = offset2,...}) =>
          ATU.wordPairCompare((arrayIndex1,offset1),(arrayIndex2,offset2))
        | (ANGETGLOBAL _, _) => LESS

        | (ANSELECT _, ANENVACC _) => GREATER
        | (ANSELECT _, ANGETGLOBAL _) => GREATER
        | (ANSELECT {recordExp = recordExp1, nestLevelExp = nestLevelExp1, offsetExp = offsetExp1,...},
           ANSELECT {recordExp = recordExp2, nestLevelExp = nestLevelExp2, offsetExp = offsetExp2,...}) =>
          argsCompare([recordExp1,nestLevelExp1,offsetExp1],[recordExp2,nestLevelExp2,offsetExp2])
        | (ANSELECT _, _) => LESS

        | (ANRECORD _, ANENVACC _) => GREATER
        | (ANRECORD _, ANGETGLOBAL _) => GREATER
        | (ANRECORD _, ANSELECT _) => GREATER
        | (ANRECORD {fieldList=fieldList1,...},ANRECORD {fieldList=fieldList2,...}) =>
          argsCompare(fieldList1,fieldList2)
        | (ANRECORD _, _) => LESS

        | (ANENVRECORD _, ANENVACC _) => GREATER
        | (ANENVRECORD _, ANGETGLOBAL _) => GREATER
        | (ANENVRECORD _, ANSELECT _) => GREATER
        | (ANENVRECORD _, ANRECORD _) => GREATER
        | (ANENVRECORD {fieldList=fieldList1,...},ANENVRECORD {fieldList=fieldList2,...}) =>
          argsCompare(fieldList1,fieldList2)
        | (ANENVRECORD _, _) => LESS

        | (ANCLOSURE _, ANENVACC _) => GREATER
        | (ANCLOSURE _, ANGETGLOBAL _) => GREATER
        | (ANCLOSURE _, ANSELECT _) => GREATER
        | (ANCLOSURE _, ANRECORD _) => GREATER
        | (ANCLOSURE _, ANENVRECORD _) => GREATER
        | (ANCLOSURE {codeExp=funExp1, envExp=envExp1,...},
           ANCLOSURE {codeExp=funExp2, envExp=envExp2,...}) =>
          argsCompare([funExp1,envExp1],[funExp2,envExp2])
        | (ANCLOSURE _, _) => LESS

        | (ANRECCLOSURE _, ANENVACC _) => GREATER
        | (ANRECCLOSURE _, ANGETGLOBAL _) => GREATER
        | (ANRECCLOSURE _, ANSELECT _) => GREATER
        | (ANRECCLOSURE _, ANRECORD _) => GREATER
        | (ANRECCLOSURE _, ANENVRECORD _) => GREATER
        | (ANRECCLOSURE _, ANCLOSURE _) => GREATER
        | (ANRECCLOSURE {codeExp=funExp1,...},ANRECCLOSURE {codeExp=funExp2,...}) =>
          argCompare(funExp1,funExp2)
        | (ANRECCLOSURE _, _) => LESS

        | (ANMODIFY _, ANENVACC _) => GREATER
        | (ANMODIFY _, ANGETGLOBAL _) => GREATER
        | (ANMODIFY _, ANSELECT _) => GREATER
        | (ANMODIFY _, ANRECORD _) => GREATER
        | (ANMODIFY _, ANENVRECORD _) => GREATER
        | (ANMODIFY _, ANCLOSURE _) => GREATER
        | (ANMODIFY _, ANRECCLOSURE _) => GREATER
        | (ANMODIFY {recordExp=recordExp1,nestLevelExp=nestLevelExp1,offsetExp=offsetExp1,valueExp=valueExp1,...},
           ANMODIFY {recordExp=recordExp2,nestLevelExp=nestLevelExp2,offsetExp=offsetExp2,valueExp=valueExp2,...}) =>
          argsCompare([recordExp1,nestLevelExp1,offsetExp1,valueExp1],[recordExp2,nestLevelExp2,offsetExp2,valueExp2])
        | (ANMODIFY _, _) => LESS
 
        | _ =>  
          let
            val s = (ANormalFormatter.anexpToString x) ^ "," ^ (ANormalFormatter.anexpToString y)
          in
            raise Control.Bug ("invalid atomEnv " ^ s)
          end
  end
  

  structure AtomEnv = BinaryMapFn(ANExp_ord)

  val clusterListRef = ref ([] : andecl list) 

  fun isArgExp exp =
      case exp of
        ANCONSTANT _ => true
      | ANEXCEPTIONTAG _ => true
      | ANVAR _ => true
      | ANLABEL _ => true
      | _ => false

  fun isAtomExp exp =
      case exp of
        ANENVACC _ => true
      | ANGETGLOBAL _ => true
      | ANSELECT _ => true
      | ANRECORD {isMutable,...} => not isMutable
      | ANENVRECORD _ => true
      | ANCLOSURE _ => true
      | ANRECCLOSURE _ => true
      | ANMODIFY _ => true
      | _ => false

  fun makeLetExp (declList,mainExp,loc) =
      case declList of 
        [] => mainExp
      | _ => ANLET {localDeclList = declList, mainExp = mainExp, loc = loc}

  fun transformTy ty =
      case ty of
        AT.ATOMty => ATOM
      | AT.BOXEDty => BOXED
      | AT.DOUBLEty => DOUBLE
      | AT.BOUNDVARty tid => GENERIC tid
      | AT.SINGLEty tid => SINGLE tid
      | AT.UNBOXEDty tid => UNBOXED tid
      | AT.SIZEty _ => ATOM
      | AT.TAGty _ => ATOM
      | AT.INDEXty _ => ATOM
      | AT.BITMAPty _ => ATOM
      | AT.ENVBITMAPty _ => ATOM
      | AT.FRAMEBITMAPty _ => ATOM
      | AT.OFFSETty _ => ATOM
      | AT.PADSIZEty _ => ATOM
      | AT.PADty _ => ATOM (* only occur in fieldTyList*)
      | _ => raise Control.Bug ("invalid compact type " ^ (Control.prettyPrint (AT.format_ty ty)))

  fun transformVar ({id,displayName,ty,varKind},loc) =
      case !varKind of
        RBU.ARG => ANVAR{varInfo = {id = id, displayName = displayName, ty = transformTy ty, varKind = ARG}, loc = loc}
      | RBU.LOCAL => ANVAR{varInfo = {id = id, displayName = displayName, ty = transformTy ty, varKind = LOCAL}, loc = loc}
      | RBU.FREEWORD {nestLevel, offset} => ANENVACC {nestLevel = nestLevel, offset = offset, loc = loc}
      | RBU.ENTRYLABEL _ => raise Control.Bug "invalid varKind ENTRYLABEL"
      | RBU.INNERLABEL _ => raise Control.Bug "invalid varKind ENTRYLABEL"
      | RBU.FREE => raise Control.Bug "invalid varKind FREE"

  fun normalizeAtom aEnv exp =
      if isAtomExp exp
      then
        case AtomEnv.find(aEnv, exp) of
          SOME newExp => newExp
        | _ => exp
      else exp

  fun atomTyList n = List.tabulate(n, (fn _ => ATOM))

  fun singleSize loc = ANCONSTANT {value = CT.WORD 0w1, loc = loc}

  fun singleSizeList (n, loc) = 
      let
        val sizeExp = singleSize loc
      in
        List.tabulate(n, (fn _ => sizeExp))
      end

  fun optimizePRIMAPPLY (exp as ANPRIMAPPLY {primName, argExpList, argSizeExpList, argTyList, loc}) =
      let
        fun intOf (ANCONSTANT {value = CT.INT v,...}) = SOME v
          | intOf _ = NONE
        fun genericIntOf (ANCONSTANT {value = CT.INT v,...}) = SOME (Int32.toInt v)
          | genericIntOf _ = NONE
        fun wordOf (ANCONSTANT {value = CT.WORD v,...}) = SOME v
          | wordOf _ = NONE
        fun genericWordOf (ANCONSTANT {value = CT.WORD v,...}) = SOME (Word.fromLargeWord (Word32.toLargeWord v))
          | genericWordOf _ = NONE
        fun realOf (ANCONSTANT {value = CT.REAL v,...}) = 
            (
             case Real.fromString v of
               SOME real => SOME real
             | NONE => NONE
            )
          | realOf _ = NONE
        fun floatOf (ANCONSTANT {value = CT.FLOAT v,...}) = 
            (
             case Real.fromString v of
               SOME real => SOME real
             | NONE => NONE
            )
          | floatOf _ = NONE
        fun charOf (ANCONSTANT {value = CT.CHAR v,...}) = SOME v
          | charOf _ = NONE
        fun byteOf (ANCONSTANT {value = CT.WORD v,...}) = SOME v
          | byteOf _ = NONE
        fun boolOf (ANCONSTANT {value = CT.INT v,...}) = 
            if v = (Int32.fromInt Constants.TAG_bool_true)
            then SOME true
            else 
              if v = (Int32.fromInt Constants.TAG_bool_false)
              then SOME false
              else raise Control.Bug "invalid bool value"
          | boolOf _ = NONE
        fun stringOf (ANCONSTANT {value = CT.STRING v,...}) = SOME v
          | stringOf _ = NONE


        fun intToExp v = ANCONSTANT {value = CT.INT v, loc = loc}
        fun genericIntToExp v = ANCONSTANT {value = CT.INT (Int32.fromInt v), loc = loc}
        fun wordToExp v = ANCONSTANT {value = CT.WORD v, loc = loc}
        fun genericWordToExp v = ANCONSTANT {value = CT.WORD (Word32.fromLargeWord (Word.toLargeWord v)), loc = loc}
        fun realToExp v = ANCONSTANT {value = CT.REAL (Real.toString v), loc = loc}
        fun floatToExp v = ANCONSTANT {value = CT.FLOAT (Real.toString v), loc = loc}
        fun charToExp v = ANCONSTANT {value = CT.CHAR v, loc = loc}
        fun byteToExp v = ANCONSTANT {value = CT.WORD v, loc = loc}
        fun boolToExp v =
            if v
            then ANCONSTANT {value = CT.INT (Int32.fromInt Constants.TAG_bool_true), loc = loc}
            else ANCONSTANT {value = CT.INT (Int32.fromInt Constants.TAG_bool_false), loc = loc}
        fun stringToExp v = ANCONSTANT {value = CT.STRING v, loc = loc}

        fun optimize1 argConv resConv operator =
            case argExpList of
              [arg] =>
              (
               case argConv arg of
                 SOME v => resConv (operator v)
               | _ => exp
              )
            | _ => exp

        fun optimize2 arg1Conv arg2Conv resConv operator =
            case argExpList of
              [arg1,arg2] =>
              (
               case (arg1Conv arg1,arg2Conv arg2) of
                 (SOME v1,SOME v2) => resConv (operator(v1,v2))
               | _ => exp
              )
            | _ => exp

        fun optimize3 arg1Conv arg2Conv arg3Conv resConv operator =
            case argExpList of
              [arg1,arg2,arg3] =>
              (
               case (arg1Conv arg1,arg2Conv arg2,arg3Conv arg3) of
                 (SOME v1,SOME v2,SOME v3) => resConv (operator(v1,v2,v3))
               | _ => exp
              )
            | _ => exp

      in
        (
         case (primName, argExpList) of
           ("addInt",[ANCONSTANT {value = CT.INT 0,...},arg2]) => arg2
         | ("addInt",[arg1,ANCONSTANT {value = CT.INT 0,...}]) => arg1
         | ("addInt", _) => optimize2 intOf intOf intToExp ( op + ) 
         | ("addWord",[ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
         | ("addWord",[arg1,ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("addWord", _) => optimize2 wordOf wordOf wordToExp ( op + ) 
         | ("addReal", _) => optimize2 realOf realOf realToExp ( op + ) 
         | ("addByte",[ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
         | ("addByte",[arg1,ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("addByte", _) => optimize2 byteOf byteOf byteToExp ( op + ) 

         | ("subInt",[arg1,ANCONSTANT {value = CT.INT 0,...}]) => arg1
         | ("subInt", _) => optimize2 intOf intOf intToExp ( op - ) 
         | ("subWord",[arg1,ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("subWord", _) => optimize2 wordOf wordOf wordToExp ( op - ) 
         | ("subReal", _) => optimize2 realOf realOf realToExp ( op - ) 
         | ("subByte",[arg1,ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("subByte", _) => optimize2 byteOf byteOf byteToExp ( op - ) 

         | ("mulInt",[arg1 as ANCONSTANT {value = CT.INT 0,...},arg2]) => arg1
         | ("mulInt",[arg1,arg2 as ANCONSTANT {value = CT.INT 0,...}]) => arg2
         | ("mulInt", _) => optimize2 intOf intOf intToExp ( op * ) 
         | ("mulWord",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("mulWord",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg2
         | ("mulWord", _) => optimize2 wordOf wordOf wordToExp ( op * ) 
         | ("mulReal", _) => optimize2 realOf realOf realToExp ( op * ) 
         | ("mulByte",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("mulByte",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg2
         | ("mulByte", _) => optimize2 byteOf byteOf byteToExp ( op * ) 

         | ("divInt",[arg1 as ANCONSTANT {value = CT.INT 0,...},arg2]) => arg1
         | ("divInt", _) => optimize2 intOf intOf intToExp ( op div ) 
         | ("divWord",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("divWord", _) => optimize2 wordOf wordOf wordToExp ( op div ) 
         | ("divReal", _) => optimize2 realOf realOf realToExp ( op / ) 
         | ("divByte",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("divByte", _) => optimize2 byteOf byteOf byteToExp ( op div ) 

         | ("modInt",[arg1 as ANCONSTANT {value = CT.INT 0,...},arg2]) => arg1
         | ("modInt", _) => optimize2 intOf intOf intToExp ( op mod ) 
         | ("modWord",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("modWord", _) => optimize2 wordOf wordOf wordToExp ( op mod ) 
         | ("modByte",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
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

         | ("Word_andb",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("Word_andb",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg2
         | ("Word_andb", _) => optimize2 wordOf wordOf wordToExp ( Word32.andb ) 

         | ("Word_orb",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg2
         | ("Word_orb",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("Word_orb", _) => optimize2 wordOf wordOf wordToExp ( Word32.orb ) 

         | ("Word_xorb", _) => optimize2 wordOf wordOf wordToExp ( Word32.xorb ) 
         | ("Word_notb", _) => optimize1 wordOf wordToExp ( Word32.notb ) 

         | ("Word_leftShift",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("Word_leftShift",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("Word_leftShift", _) => optimize2 wordOf genericWordOf wordToExp ( Word32.<< ) 

         | ("Word_logicalRightShift",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("Word_logicalRightShift",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
         | ("Word_logicalRightShift", _) => optimize2 wordOf genericWordOf wordToExp ( Word32.>> ) 

         | ("Word_arithmeticRightShift",[arg1 as ANCONSTANT {value = CT.WORD 0w0,...},arg2]) => arg1
         | ("Word_arithmeticRightShift",[arg1,arg2 as ANCONSTANT {value = CT.WORD 0w0,...}]) => arg1
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
    | optimizePRIMAPPLY _ =
      raise Control.Bug "invalid primapply"

  fun optimizeSWITCH (exp as ANSWITCH {switchExp,expTy, defaultExp, branches, loc}) =
      (
       case switchExp of
         ANCONSTANT {value = switchValue,...} =>
         let
           fun optimizeBranches [] = defaultExp
             | optimizeBranches ({constant,exp}::rest) =
               (
                case CT.compare(switchValue, constant) of
                  EQUAL => exp
                | _ => optimizeBranches rest
               )
         in
           optimizeBranches branches
         end
       | _ => exp
      )
    | optimizeSWITCH _ = raise Control.Bug "invalid switch"


  fun normalizeArg vEnv aEnv (exp, ty, size) =
      let
        val result as (declList, newExp, newVEnv, newAEnv) = normalizeExp vEnv aEnv exp
      in
        if isArgExp newExp
        then result
        else
          case newExp of
            ANMVALUES _ => raise Control.Bug "multiple value should not be in arg position"
          | _ =>
            let
              val newId = ID.generate()
              val varInfo = {id = newId, displayName = "$" ^ (ID.toString newId), ty = ty, varKind = LOCAL} : varInfo
              val expLoc = ANU.getLocOfExp newExp
              val newDecl = ANVAL {boundVarList = [varInfo], sizeExpList = [size], boundExp = newExp, loc = expLoc}
              val var = ANVAR {varInfo = varInfo, loc = expLoc}
              val newAEnv = if isAtomExp newExp then AtomEnv.insert(newAEnv,newExp,var) else newAEnv
            in
              (declList @ [newDecl], var, newVEnv, newAEnv)
            end
      end

  and normalizeArgList vEnv aEnv ([], [], []) = ([],[],vEnv,aEnv)
    | normalizeArgList vEnv aEnv (exp::expList, ty::tyList, size::sizeList) = 
      let
        val (declList1, newExp, newVEnv, newAEnv) = 
            normalizeArg vEnv aEnv (exp,ty,size)
        val (declList2, newExpList, newVEnv, newAEnv) = 
            normalizeArgList newVEnv newAEnv (expList,tyList,sizeList)
      in
        (declList1 @ declList2, newExp::newExpList, newVEnv, newAEnv)
      end
    | normalizeArgList vEnv aEnv (L1,L2,L3) = raise Control.Bug "normalizeArgList"


  and normalizeExp vEnv aEnv exp =
      case exp of
        RBU.RBUFOREIGNAPPLY {funExp, argExpList, argTyList, argSizeExpList, convention, loc} =>
        let
          val n = List.length argExpList
          val newArgTyList = map transformTy argTyList
          val (declList1, newArgSizeExpList, newVEnv, newAEnv) =
              normalizeArgList
                  vEnv aEnv
                  (argSizeExpList, atomTyList n, singleSizeList(n,loc))
          val (declList2, newFunExp::newArgExpList , newVEnv, newAEnv) =
              normalizeArgList 
                  newVEnv newAEnv 
                  (funExp::argExpList, ATOM::newArgTyList, (singleSize loc)::newArgSizeExpList)
          val newExp =
              ANFOREIGNAPPLY
                  {
                   funExp = newFunExp,
                   argExpList = newArgExpList,
                   argTyList = newArgTyList,
                   argSizeExpList = newArgSizeExpList,
                   convention = convention,
                   loc = loc
                  }
        in
          (declList1 @ declList2,newExp,newVEnv, newAEnv)
        end
      | RBU.RBUEXPORTCALLBACK {funExp, argSizeExpList, resultSizeExpList, loc} =>
        let
          val n = List.length argSizeExpList
          val (declList1, newArgSizeExpList, newVEnv, newAEnv) =
              normalizeArgList
                  vEnv aEnv
                  (argSizeExpList, atomTyList n, singleSizeList(n,loc))
          val n = List.length resultSizeExpList
          val (declList2, newFunExp::newResultSizeExpList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (funExp::resultSizeExpList, BOXED::(atomTyList n), singleSizeList(n+1,loc))
          val newExp =
              ANEXPORTCALLBACK
                  {
                   funExp = newFunExp,
                   argSizeExpList = newArgSizeExpList,
                   resultSizeExpList = newResultSizeExpList,
                   loc = loc
                  }   
        in
          (declList1 @ declList2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUCONSTANT arg => ([],ANCONSTANT arg,vEnv,aEnv)
      | RBU.RBUEXCEPTIONTAG arg => ([],ANEXCEPTIONTAG arg,vEnv,aEnv)
      | RBU.RBUVAR {varInfo as {id,...},loc} =>
        (
         case VEnv.find(vEnv, id) of
           SOME newExp => ([],newExp,vEnv,aEnv)
         | _ => ([], normalizeAtom aEnv (transformVar (varInfo, loc)), vEnv, aEnv)
        )
      | RBU.RBULABEL arg => ([],ANLABEL arg,vEnv,aEnv)
      | RBU.RBUGETGLOBAL {arrayIndex, valueOffset, loc} => 
        let
          val newExp =
              ANGETGLOBAL
                  {
                   arrayIndex = arrayIndex,
                   valueOffset = valueOffset,
                   loc = loc
                  }
        in
          ([], normalizeAtom aEnv newExp, vEnv, aEnv)
        end
      | RBU.RBUSETGLOBAL {arrayIndex, valueOffset, valueExp, valueTy, valueSize, loc} =>
        let
          val newValueTy = transformTy valueTy
          val valueSizeExp = ANCONSTANT {value = CT.WORD valueSize, loc = loc}
          val (decls, newValueExp, newVEnv, newAEnv) =
              normalizeArg
                  vEnv aEnv
                  (valueExp, newValueTy, valueSizeExp)
          val newExp =
              ANSETGLOBAL
                  {
                   arrayIndex = arrayIndex,
                   valueOffset = valueOffset,
                   valueExp = newValueExp,
                   valueTy = newValueTy,
                   valueSize = valueSize,
                   loc = loc
                  }
        in
          (decls,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUINITARRAY {arrayIndex, arraySize, elementTy, loc} =>
        let
          val newExp =
              ANINITARRAY
                  {
                   arrayIndex = arrayIndex,
                   arraySize = arraySize,
                   elementTy = transformTy elementTy,
                   loc = loc
                  }
        in
          ([],newExp,vEnv,aEnv)
        end
      | RBU.RBUGETFIELD {arrayExp, offsetExp, loc} =>
        let
          val (decls, [newArrayExp, newOffsetExp], newVEnv, newAEnv) =
              normalizeArgList
                  vEnv aEnv
                  ([arrayExp, offsetExp], [BOXED,ATOM], singleSizeList (2, loc))
          val newExp =
              ANGETFIELD
                  {
                   arrayExp = newArrayExp,
                   offsetExp = newOffsetExp,
                   loc = loc
                  }
        in
          (decls,normalizeAtom aEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUSETFIELD {arrayExp,offsetExp,valueExp,valueTy,valueSizeExp,loc} =>
        let
          val newValueTy = transformTy valueTy
          val (decls1, newValueSizeExp, newVEnv, newAEnv) =
              normalizeArg vEnv aEnv (valueSizeExp, ATOM, singleSize loc)
          val (decls2, [newValueExp, newArrayExp, newOffsetExp], newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  ([valueExp, arrayExp, offsetExp], 
                   [newValueTy,BOXED,ATOM], 
                   newValueSizeExp::(singleSizeList (2, loc)))
          val newExp =
              ANSETFIELD
                  {
                   arrayExp = newArrayExp,
                   offsetExp = newOffsetExp,
                   valueExp = newValueExp,
                   valueTy = newValueTy,
                   valueSizeExp = newValueSizeExp,
                   loc = loc
                  }
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUSETTAIL {consExp, offsetExp, newTailExp, nestLevelExp, loc} =>
        let
          val (decls, [newConsExp, newOffsetExp, newNestLevelExp, newNewTailExp], newVEnv, newAEnv) =
              normalizeArgList
                 vEnv aEnv
                  ([consExp, offsetExp, nestLevelExp, newTailExp], 
                   [BOXED, ATOM, ATOM, BOXED], 
                   (singleSizeList (4, loc)))
          val newExp =
              ANSETTAIL
                  {
                   consExp = newConsExp,
                   offsetExp = newOffsetExp,
                   nestLevelExp = newNestLevelExp,
                   newTailExp = newNewTailExp,
                   loc = loc
                  }
        in
          (decls, normalizeAtom aEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUARRAY {bitmapExp,sizeExp,initialValue,elementTy,elementSizeExp,loc} =>
        let
          val newElementTy = transformTy elementTy
          val (decls1, [newBitmapExp, newSizeExp, newElementSizeExp], newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  ([bitmapExp,sizeExp,elementSizeExp], atomTyList 3, singleSizeList (3, loc))
          val (decls2, newInitialValue, newVEnv, newAEnv) =
              normalizeArg newVEnv newAEnv (initialValue,newElementTy,newElementSizeExp)
          val newExp =
              ANARRAY
                  {
                   bitmapExp = newBitmapExp,
                   sizeExp = newSizeExp,
                   initialValue = newInitialValue,
                   elementTy = newElementTy,
                   elementSizeExp = newElementSizeExp,
                   loc = loc
                  }
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUPRIMAPPLY {primName,argExpList,argSizeExpList,argTyList,loc} =>
        let
          val newArgTyList = map transformTy argTyList
          val n = List.length argTyList
          val (decls1, newArgSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (argSizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newArgExpList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (argExpList,newArgTyList,newArgSizeExpList)
          val newExp =
              ANPRIMAPPLY
                  {
                   primName = primName,
                   argExpList = newArgExpList,
                   argSizeExpList = newArgSizeExpList,
                   argTyList = newArgTyList,
                   loc = loc
                  }
          (*do constant folding*)
          val newExp = optimizePRIMAPPLY newExp
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUAPPM {funExp, argExpList, argTyList, argSizeExpList, loc} =>
        let
          val newArgTyList = map transformTy argTyList
          val n = List.length argTyList
          val (decls1, newArgSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (argSizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newFunExp::newArgExpList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (funExp::argExpList,BOXED::newArgTyList,(singleSize loc)::newArgSizeExpList)
          val newExp =
              ANAPPLY
                  {
                   funExp = newFunExp,
                   argExpList = newArgExpList,
                   argSizeExpList = newArgSizeExpList,
                   argTyList = newArgTyList,
                   loc = loc
                  }
        (*transformation into ANCALL insert here*)
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBURECCALL {codeExp, argExpList, argTyList, argSizeExpList, loc} =>
        let
          val newArgTyList = map transformTy argTyList
          val n = List.length argTyList
          val (decls1, newArgSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (argSizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newCodeExp::newArgExpList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (codeExp::argExpList,ATOM::newArgTyList,(singleSize loc)::newArgSizeExpList)
          val newExp =
              ANRECCALL
                  {
                   codeExp = newCodeExp,
                   argExpList = newArgExpList,
                   argSizeExpList = newArgSizeExpList,
                   argTyList = newArgTyList,
                   loc = loc
                  }
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUINNERCALL {codeExp, argExpList, argTyList, argSizeExpList, loc} =>
        let
          val newArgTyList = map transformTy argTyList
          val n = List.length argTyList
          val (decls1, newArgSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (argSizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newCodeExp::newArgExpList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (codeExp::argExpList,ATOM::newArgTyList,(singleSize loc)::newArgSizeExpList)
          val newExp =
              ANINNERCALL
                  {
                   codeExp = newCodeExp,
                   argExpList = newArgExpList,
                   argSizeExpList = newArgSizeExpList,
                   argTyList = newArgTyList,
                   loc = loc
                  }
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBULET {localDeclList, mainExp, loc} =>
        let
          val (newLocalDeclList, newVEnv,newAEnv) = normalizeDeclList vEnv aEnv localDeclList
          val (mainDecl, newMainExp,newVEnv,newAEnv) = normalizeExp newVEnv newAEnv mainExp
        in
          ([],makeLetExp(newLocalDeclList @ mainDecl,newMainExp,loc),newVEnv,newAEnv)
        end
      | RBU.RBUMVALUES {expList, tyList, sizeExpList, loc} =>
        let
          val newTyList = map transformTy tyList
          val n = List.length tyList
          val (decls1, newSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (sizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newExpList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (expList,newTyList,newSizeExpList)
          val newExp =
              ANMVALUES
                  {
                   expList = newExpList,
                   tyList = newTyList,
                   sizeExpList = newSizeExpList,
                   loc = loc
                  }
        in
          (decls1 @ decls2,newExp,newVEnv,newAEnv)
        end
      | RBU.RBURECORD {bitmapExp,totalSizeExp,fieldList,fieldTyList,fieldSizeExpList, isMutable, loc} =>
        let
          val newFieldTyList = map transformTy fieldTyList
          val n = List.length fieldTyList
          val (decls1, newFieldSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (fieldSizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newBitmapExp::newTotalSizeExp::newFieldList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (bitmapExp::totalSizeExp::fieldList,
                   ATOM::ATOM::newFieldTyList,(singleSize loc)::(singleSize loc)::newFieldSizeExpList)
          val newExp =
              ANRECORD
                  {
                   bitmapExp = newBitmapExp,
                   totalSizeExp = newTotalSizeExp,
                   fieldList = newFieldList,
                   fieldTyList = newFieldTyList,
                   fieldSizeExpList = newFieldSizeExpList,
                   isMutable = isMutable,
                   loc = loc
                  }
        in
          (decls1 @ decls2,normalizeAtom newAEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUENVRECORD {bitmapExp,totalSize,fieldList,fieldTyList,fieldSizeExpList,fixedSizeList,loc} =>
        let
          val newFieldTyList = map transformTy fieldTyList
          val n = List.length fieldTyList
          val (decls1, newFieldSizeExpList, newVEnv, newAEnv) =
              normalizeArgList 
                  vEnv aEnv 
                  (fieldSizeExpList, atomTyList n, singleSizeList (n, loc))
          val (decls2, newBitmapExp::newFieldList, newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  (bitmapExp::fieldList,
                   ATOM::newFieldTyList,(singleSize loc)::newFieldSizeExpList)
          val newExp =
              ANENVRECORD
                  {
                   bitmapExp = newBitmapExp,
                   totalSize = totalSize,
                   fieldList = newFieldList,
                   fieldTyList = newFieldTyList,
                   fieldSizeExpList = newFieldSizeExpList,
                   fixedSizeList = fixedSizeList,
                   loc = loc
                  }
        in
          (decls1 @ decls2,normalizeAtom newAEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUSELECT {recordExp, nestLevelExp, offsetExp, loc} =>
        let
          val (decls, [newRecordExp,newNestLevelExp, newOffsetExp], newVEnv, newAEnv) =
              normalizeArgList
                  vEnv aEnv
                  ([recordExp, nestLevelExp, offsetExp], [BOXED,ATOM,ATOM], singleSizeList (3, loc))
          val newExp =
              ANSELECT
                  {
                   recordExp = newRecordExp,
                   nestLevelExp = newNestLevelExp,
                   offsetExp = newOffsetExp,
                   loc = loc
                  }
        in
          (decls,normalizeAtom aEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUMODIFY {recordExp, nestLevelExp,offsetExp,valueExp,valueTy,valueSizeExp,loc} =>
        let
          val newValueTy = transformTy valueTy
          val (decls1, newValueSizeExp, newVEnv, newAEnv) =
              normalizeArg vEnv aEnv (valueSizeExp,ATOM,singleSize loc)
          val (decls2, [newValueExp,newRecordExp,newNestLevelExp, newOffsetExp], newVEnv, newAEnv) =
              normalizeArgList
                  newVEnv newAEnv
                  ([valueExp,recordExp,nestLevelExp,offsetExp],
                   [newValueTy,BOXED,ATOM,ATOM],newValueSizeExp::(singleSizeList(3,loc)))
          val newExp =
              ANMODIFY
                  {
                   recordExp = newRecordExp,
                   nestLevelExp = newNestLevelExp,
                   offsetExp = newOffsetExp,
                   valueExp = newValueExp,
                   valueTy = newValueTy,
                   valueSizeExp = newValueSizeExp,
                   loc = loc
                  }
        in
          (decls1 @ decls2,normalizeAtom newAEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBURAISE {argExp, loc} =>
        let
          val (decls,newArgExp,newVEnv,newAEnv) = normalizeArg vEnv aEnv (argExp,BOXED,singleSize loc)
          val newExp = ANRAISE {argExp = newArgExp, loc = loc}
        in
          (decls,newExp,newVEnv,newAEnv)
        end
      | RBU.RBUHANDLE{exp,exnVar as {id,displayName,ty,varKind},handler,loc} =>
        let
          val (decls1,newExp, _,_) = normalizeExp vEnv aEnv exp
          val newExnVar = {id=id,displayName=displayName,ty = transformTy ty,varKind=LOCAL}
          val (decls2,newHandler, _,_) = normalizeExp vEnv aEnv handler
          val newExp =
              ANHANDLE
                  {
                   exp = makeLetExp(decls1,newExp,loc),
                   exnVar = newExnVar,
                   handler = makeLetExp(decls2,newHandler,loc),
                   loc = loc
                  }
        (*optimize handle here*)
        in
          ([],newExp,vEnv,aEnv)
        end
      | RBU.RBUSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val newExpTy = transformTy expTy
          val (decls, newSwitchExp, newVEnv,newAEnv) = 
              normalizeArg vEnv aEnv (switchExp,newExpTy,singleSize loc)
          fun transformBranchExp exp =
              let
                val (decls, newExp, _,_) = normalizeExp newVEnv newAEnv exp
              in
                makeLetExp(decls,newExp,loc)
              end
          fun transformBranch {constant,exp} =
              case constant of
                RBU.RBUCONSTANT {value,...} => {constant = value, exp = transformBranchExp exp}
              | _ => raise Control.Bug "invalid constant"
          val newExp =
              ANSWITCH
                  {
                   switchExp = newSwitchExp,
                   expTy = newExpTy,
                   branches = map transformBranch branches,
                   defaultExp = transformBranchExp defaultExp,
                   loc = loc
                  }
          (*optimize switch here*)
          val newExp = optimizeSWITCH newExp
        in
          (decls, newExp, newVEnv, newAEnv)
        end
      | RBU.RBUCLOSURE {codeExp, envExp, loc} =>
        let
          val (decls, [newCodeExp,newEnvExp], newVEnv, newAEnv) =
              normalizeArgList
                  vEnv aEnv
                  ([codeExp,envExp],[ATOM,BOXED],singleSizeList(2,loc))
          val newExp = ANCLOSURE {codeExp = newCodeExp, envExp = newEnvExp, loc = loc}
        in
          (decls,normalizeAtom newAEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUENTRYCLOSURE {codeExp, loc} =>
        let
          val (decls, newCodeExp, newVEnv, newAEnv) =
              normalizeArg vEnv aEnv (codeExp,ATOM,singleSize loc)
          val newExp = ANRECCLOSURE {codeExp = newCodeExp, loc = loc}
        in
          (decls,normalizeAtom newAEnv newExp,newVEnv,newAEnv)
        end
      | RBU.RBUINNERCLOSURE _ => raise Control.Bug "inner closure"

  and normalizeFrameInfo {tyvars, bitmapFree, tagArgList} =
      {
       tyvars = tyvars,
       bitmapFree = 
         case bitmapFree of 
           RBU.RBUCONSTANT arg => ANCONSTANT arg
         | RBU.RBUVAR {varInfo as {varKind = ref (RBU.FREEWORD {nestLevel, offset}),...}, loc} =>
           ANENVACC {nestLevel = nestLevel, offset = offset, loc = loc}
         | _ => raise Control.Bug "invalid bitmapFree",
       tagArgList =
         map
             (fn (RBU.RBUVAR {varInfo as {id, displayName, ty, varKind}, loc}) =>
                 ANVAR
                     {
                      varInfo = {id = id, displayName = displayName, ty = transformTy ty, varKind = ARG},
                      loc = loc
                     }
             )
             tagArgList
      }

  and normalizeFunDecl vEnv {codeId, argVarList, argSizeExpList, bodyExp, resultTyList, resultSizeExpList} =
      let
        val newArgVarList = 
            map
                (fn {id, displayName, ty, varKind} =>
                    {id = id, displayName = displayName, ty = transformTy ty, varKind = ARG}
                )
                argVarList
        val newArgSizeExpList = 
            map 
                (fn (RBU.RBUCONSTANT arg) => ANCONSTANT arg
                  | (RBU.RBUVAR {varInfo as {id,displayName,ty,varKind = ref RBU.ARG}, loc}) =>
                    ANVAR{varInfo = {id = id, displayName = displayName, ty = transformTy ty, varKind = ARG},loc = loc}
                  | (RBU.RBUVAR {varInfo as {id,displayName,ty,varKind = ref (RBU.FREEWORD {nestLevel,offset})}, loc}) =>
                    ANENVACC {nestLevel = nestLevel, offset = offset, loc = loc}
                  | _ => raise Control.Bug "invalid argument size"
                )
                argSizeExpList
        val (decls1,newBodyExp,newVEnv,newAEnv) = normalizeExp vEnv AtomEnv.empty bodyExp
        val newResultTyList = map transformTy  resultTyList
        val n = List.length resultTyList
        val (decls2, newResultSizeExpList, newVEnv, newAEnv) =
            normalizeArgList 
                newVEnv newAEnv
                (resultSizeExpList, atomTyList n, singleSizeList(n, ANU.getLocOfExp newBodyExp))
        val newFunDecl =
            {
             codeId = codeId,
             argVarList = newArgVarList,
             argSizeExpList = newArgSizeExpList,
             bodyExp = makeLetExp (decls1 @ decls2, newBodyExp, ANU.getLocOfExp newBodyExp),
             resultTyList = newResultTyList,
             resultSizeExpList = newResultSizeExpList
            }
      in
        (newFunDecl,newVEnv)
      end

  and normalizeDecl vEnv aEnv decl =
      case decl of
        RBU.RBUVAL {boundVarList, sizeExpList, boundExp, loc} => 
        let
          val (boundDeclList, newBoundExp, newVEnv, newAEnv) =  normalizeExp vEnv aEnv boundExp
          val newBoundVarList = 
              map
                  (fn {id, displayName, ty, varKind} => 
                      {id = id, displayName = displayName, ty = transformTy ty, varKind = LOCAL}
                  )
                  boundVarList
        in
          case newBoundExp of
            ANMVALUES {expList, sizeExpList,...} =>
            let
              val (declList, newVEnv,newAEnv) =
                  ListPair.foldl
                      (fn ((varInfo as {id,...},sizeExp),exp,(declList,vEnv,aEnv)) => 
                          if isArgExp exp
                          then (declList,VEnv.insert(vEnv,id,exp),aEnv)
                          else
                            let
                              val decl = ANVAL {boundVarList = [varInfo], sizeExpList = [sizeExp], boundExp = exp, loc = loc}
                            in
                              if isAtomExp exp
                              then (decl::declList,vEnv,AtomEnv.insert(aEnv,exp,ANVAR{varInfo = varInfo, loc = loc}))
                              else (decl::declList,vEnv,aEnv)
                            end
                      )
                      ([],newVEnv,newAEnv)
                      (ListPair.zip(newBoundVarList,sizeExpList),expList)
            in
              (boundDeclList @ (rev declList), newVEnv, newAEnv)
            end
          | _ =>
            if isArgExp newBoundExp
            then (boundDeclList,VEnv.insert(newVEnv,#id (List.hd newBoundVarList),newBoundExp),newAEnv)
            else
              let
                val n = List.length sizeExpList
                val (sizeDeclList, newSizeExpList, newVEnv, newAEnv) =
                    normalizeArgList newVEnv newAEnv (sizeExpList, atomTyList n, singleSizeList(n,loc))
                val decl = 
                    ANVAL 
                        {
                         boundVarList = newBoundVarList, 
                         sizeExpList = newSizeExpList, 
                         boundExp = newBoundExp, 
                         loc = loc
                        }
                val newAEnv =
                    if isAtomExp newBoundExp
                    then AtomEnv.insert(newAEnv,newBoundExp,ANVAR{varInfo = List.hd newBoundVarList, loc = loc})
                    else newAEnv
              in
                (boundDeclList @ sizeDeclList @ [decl],newVEnv,newAEnv)
              end
        end

      | RBU.RBUCLUSTER {frameInfo, entryFunctions, innerFunctions, isRecursive, loc} =>
        let
          val newFrameInfo = normalizeFrameInfo frameInfo
          val (entryFunctionsRev,funVEnv) =
              foldl
                  (fn (funDecl, (funDeclList,vEnv)) =>
                      let val (newFunDecl,newVEnv) = normalizeFunDecl vEnv funDecl
                      in (newFunDecl::funDeclList,newVEnv) end
                  )
                  ([],VEnv.empty)
                  entryFunctions
          val (innerFunctionsRev,funVEnv) =
              foldl
                  (fn (funDecl, (funDeclList,vEnv)) =>
                      let val (newFunDecl,newVEnv) = normalizeFunDecl vEnv funDecl
                      in (newFunDecl::funDeclList,newVEnv) end
                  )
                  ([],funVEnv)
                  innerFunctions
          val newCluster = 
              ANCLUSTER
                  {
                   frameInfo = newFrameInfo,
                   entryFunctions = rev entryFunctionsRev,
                   innerFunctions = rev innerFunctionsRev,
                   isRecursive = isRecursive,
                   loc = loc
                  }
          val _ = clusterListRef := (newCluster::(!clusterListRef))
        in
          ([],vEnv,aEnv)
        end

  and normalizeDeclList vEnv aEnv [] = ([],vEnv, aEnv)
    | normalizeDeclList vEnv aEnv (decl::rest) =
      let
        val (newDeclList, newVEnv, newAEnv) = normalizeDecl vEnv aEnv decl
        val (newRestDeclList, newVEnv, newAEnv) = normalizeDeclList newVEnv newAEnv rest 
      in
        (newDeclList @ newRestDeclList, newVEnv, newAEnv)
      end

  fun normalize declList =
      let
        val _ = clusterListRef := []  
        val (newDeclList,_ , _) = normalizeDeclList VEnv.empty AtomEnv.empty declList
        val mainFunctionID = ID.generate ()
        val mainFunctionLoc = 
            case newDeclList of
              [] => Loc.noloc
            |_ =>
             let
               val firstLoc = ANU.getLocOfDecl (List.hd newDeclList)
               val lastLoc = ANU.getLocOfDecl (List.hd (rev newDeclList))
             in
               Loc.mergeLocs(firstLoc, lastLoc)
             end
        val mainFrameInfo =
            {
             tyvars = [],
             bitmapFree = ANCONSTANT{value = CT.WORD 0w0, loc = mainFunctionLoc},
             tagArgList = []
            } : frameInfo
        val mainFunDecl =
            {
             codeId = mainFunctionID,
             argVarList = [],
             argSizeExpList = [],
             bodyExp = 
             case newDeclList of 
               [] => ANEXIT mainFunctionLoc
             | _ =>
               ANLET 
                   {
                    localDeclList = newDeclList, 
                    mainExp = ANEXIT mainFunctionLoc, 
                    loc = mainFunctionLoc
                   },
             resultTyList = [],
             resultSizeExpList = []
            } : funDecl
        val mainCluster =
            ANCLUSTER
                {
                 frameInfo = mainFrameInfo,
                 entryFunctions = [mainFunDecl],
                 innerFunctions = [],
                 isRecursive = false,
                 loc = mainFunctionLoc
                }
      in
        rev (mainCluster::(!clusterListRef))
      end

end
