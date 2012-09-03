structure FFISwitchGen = struct
local
  open FFIGenItem PrintFFISwitch
in
fun main maxSize maxRealSize =
let
(*
  val maxSize = 10  (* the maximum number of argyuments *)
  val maxRealSize = 5
*)
  val maxCases = 1024
  val FFISwitchFileName = "./LARGEFFISWITCH.cc"

  datatype elemType = W | D

  type funType = elemType list  * elemType

  fun funTypeToCaseTag elemTypeList =
    let
      fun power 0 = 1
        | power n = 2 * power (n - 1)
      fun elemTypeToBit W = 0 
        | elemTypeToBit D = 1
      fun countBits nil = 0
        | countBits (h::t) = elemTypeToBit h + 2 * (countBits t)
      fun elemTypeListToInt L = power (length L)  - 1  +  countBits (rev L)
    in
      elemTypeListToInt elemTypeList
    end

  fun tagToDigit n =
    let
      fun howMany 0 k allOne = if allOne then k - 1 else k -2
        | howMany n k allOne = howMany (n div 2) (k+1) (allOne andalso (n mod 2 = 1))
    in
      howMany n 0 true
    end
           

  fun enumerate n m = 
    let
      fun allNDigit 0 L = L
        | allNDigit n L = allNDigit (n - 1) ((map (fn x => W::x) L) @ (map (fn x => D::x) L))
      fun intNDigit 0 L = L
        | intNDigit n L = intNDigit (n - 1) (map (fn x => W::x) L)
      fun enumerateFunTypes 0 L =  L
        | enumerateFunTypes n L =  enumerateFunTypes (n - 1) ((if n > m then (intNDigit n [[]])
                                                               else (allNDigit n [[]]))
                                                              @ L)
    in
      enumerateFunTypes n nil
    end
  
  fun makeAnEntry (funType as (resultType:: argTypeList)) =
    let
      val caseTag = CASETAG (funTypeToCaseTag funType)
      val return = (fn D => REAL_RETURN | W => WORD_RETURN) resultType
      val resultTy = (fn D => REAL_RESULT_TY | W => WORD_RESULT_TY) resultType
      fun argTy argDigit = (fn D => REALARG | W => WORDARG) argDigit
      val funbody = (resultTy, map argTy argTypeList)
      fun makeArgs i nil  = nil
        | makeArgs i (D::rest) = (REALLOAD i) ::makeArgs (i+1) rest
        | makeArgs i (W::rest) = (WORDLOAD i) ::makeArgs (i+1) rest
      val funArgs = makeArgs 0 argTypeList
      val returnStatement = (return, funbody, funArgs)
    in
      (caseTag, returnStatement)
    end

  fun takel n l =
    let
      fun take (0, l, r) = (rev l, r)
        | take (n, l, h::t) = take (n - 1, h::l, t)
        | take (n, l, nil) = (rev l, nil)
    in
      take (n, nil, l)
    end

  fun makeSwitchFuncs id entries =
    let
      fun idToName 0 = ""
        | idToName x = Int.toString x
      val (cases, entries) = takel maxCases entries
    in
      case entries of
        nil => [(idToName id, cases, "SWITCHFUNCDEFAULT")]
      | _ =>
        makeSwitchFuncs (id + 1) entries
        @ [(idToName id, cases,
            "SWITCHFUNCNAME("^idToName (id+1)^")\
            \(returnValue, function, SP, tag, argIndexes)")]
    end
  
   fun enumerateEntry n m =
     let
       val outs = TextIO.openOut FFISwitchFileName
       val funtyList = enumerate n m
       val entries = map makeAnEntry funtyList
       val funcs = makeSwitchFuncs 0 entries
       fun printIt x = TextIO.output(outs, ffiSwitchFuncToString x)
       val _ = app printIt funcs
       val _ = TextIO.closeOut outs
     in
       ()
     end
in
  enumerateEntry (maxSize + 1) (maxRealSize + 1)
end
end
end
