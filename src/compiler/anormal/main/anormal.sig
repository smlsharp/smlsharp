(**
 * Copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: anormal.sig,v 1.15 2006/02/18 16:04:03 duchuu Exp $
 *)

signature ANormal = sig

  type loc
  type id 
  type tyvarId
  datatype ty =
           BOXED
         | ATOM
         | DOUBLE
         | TYVAR of tyvarId 
  datatype varKind =
	   ARG 
         | LOCAL

  type varInfo
  type varInfoWithType
  type varInfoWithoutKind
  type primInfo 
  datatype constant = datatype Types.constant

  datatype anexp =
	   ANCONSTANT of {value :constant, loc : loc}
         | ANVAR of {varInfo : varInfo, loc : loc}
         | ANENVACC of 
             {
              nestLevel : Word32.word, 
              offset : Word32.word, 
              loc : loc
             }
         | ANENVACCINDIRECT of 
             {
              nestLevel : Word32.word, 
              indirectOffset : Word32.word, 
              loc : loc
             }
         | ANGETGLOBALVALUE of 
              {
               arrayIndex : BasicTypes.UInt32, 
               offsetExp : anexp, 
               loc: loc
              }
         | ANSETGLOBALVALUE of 
             {
              arrayIndex : BasicTypes.UInt32, 
              offsetExp : anexp, 
              valueExp: anexp, 
              loc :loc
             }
         | ANINITARRAYUNBOXED of 
             {
              arrayIndex : BasicTypes.UInt32, 
              sizeExp : anexp, 
              loc:loc
             }
         | ANINITARRAYBOXED of 
             {
              arrayIndex : BasicTypes.UInt32, 
              sizeExp : anexp, 
              loc:loc
             }
         | ANINITARRAYDOUBLE of 
             {
              arrayIndex : BasicTypes.UInt32, 
              sizeExp : anexp, 
              loc:loc
             }
         | ANPRIMAPPLY of 
             {
              primOp : primInfo, 
              argExpList : anexp list, 
              loc : loc
             }
         | ANPRIMAPPLY_1 of 
             {
              primOp : primInfo, 
              argValue1 : constant,
              argExp2 : anexp, 
              loc : loc
             }
         | ANPRIMAPPLY_2 of 
             {
              primOp : primInfo, 
              argExp1 : anexp, 
              argValue2 : constant,
              loc : loc
             }
         | ANFOREIGNAPPLY of 
             {
              funExp : anexp,
              argExpList : anexp list,
              argTyList : ty list,
              loc : loc
             }
         | ANAPPLY of 
             {
              funExp : anexp, 
              argExpList : anexp list, 
              loc : loc
             }
         | ANCALL of 
             {
              funLabel : id, 
              argExpList : anexp list, 
              loc : loc
             }
         | ANRECORD of 
             {
              bitmapExp : anexp,
              totalSizeExp : anexp,
              fieldList : anexp list,
              fieldSizeList : anexp list,
              loc : loc
             }
         | ANARRAY of 
             {
              bitmapExp : anexp,
              sizeExp : anexp,
              initialValue : anexp,
              loc : loc
             }
         | ANMODIFY of 
             {
              recordExp : anexp,
              nestLevel : anexp,
              offset : anexp,
              elementExp : anexp,
              loc : loc
             }
         | ANRAISE of {exceptionExp : anexp, loc : loc}
         | ANHANDLE of 
             {
              mainExp : anexp,
              exnVar : varInfo,
              handler :  anexp,
              loc : loc
             }
         | ANCLOSURE of {funLabel : id, env : anexp, loc : loc}
         | ANSWITCH of 
             {
              switchExp : anexp,
              branches : (constant * anexp) list,
              defaultExp : anexp,
              loc : loc
             }
         | ANLET of 
             {
              boundVar : varInfo, 
              boundExp : anexp, 
              mainExp : anexp, 
              loc : loc
             }
         | ANLETLABEL of 
             {
              funLabel : id, 
              funInfo : funInfo, 
              funBody : anexp,
              mainExp : anexp,
              loc : loc
             }
         | ANVALREC of 
             {
              recbindList : {funLabel : id, funInfo : funInfo, body : anexp} list,
              mainExp : anexp,
              loc : loc
             }
         | ANRECCALL of 
             {
              funLabel : id, 
              argExpList : anexp list, 
              loc : loc
             }
         | ANRECCLOSURE of {funLabel :id, loc : loc}
         | ANEXIT of loc
         | ANGETFIELD of 
             {
              blockExp : anexp,
              nestLevel : anexp,
              offset : anexp,
              loc : loc
             }
         | ANSETFIELD of 
             {
              blockExp : anexp,
              nestLevel : anexp,
              offset : anexp,
              valueExp : anexp,
              loc : loc
             }
         | ANFFIVAL of 
             {
              funExp : anexp,
              libExp : anexp,
              argTyList : ty list,
              resultTy : ty,
              funTy : ty,
              loc : loc
             }

  withtype funInfo =
           {
            tyvars:tyvarId list,
            bitmapFree: anexp,
	    tagArgs: anexp list,
            sizevals: anexp list,
	    args:varInfo list,
	    resultTy: ty
	   } 

end
