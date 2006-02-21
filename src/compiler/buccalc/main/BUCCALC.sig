(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author NGUYEN Huu-Duc 
 * @version $Id: BUCCALC.sig,v 1.3 2006/02/18 16:04:05 duchuu Exp $
 *)


signature BUCCALC = sig

  type loc 
  type ty 
  type id
  datatype varKind =
	   ARG 
         | LOCAL
         | FREE
         | FREEWORD of {nestLevel: Word32.word, offset : Word32.word}
         | FREEVAR of {nestLevel : Word32.word, indirectOffset : Word32.word}
         | LABEL of id 
  type varInfo
  type varInfoWithType
  datatype valId =
           VALIDVAR of varInfoWithType
         | VALIDWILD of ty

  type primInfo 
  type btvKind  

  datatype constant =  datatype Types.constant

  datatype bucexp =
           BUCCONSTANT of {value : constant, loc : loc}
         | BUCVAR of {varInfo : varInfo, loc: loc}
         | BUCENVACC of 
             {
              nestLevel : Word32.word, 
              offset : Word32.word, 
              variableTy : ty, 
              loc : loc
             }
         | BUCENVACCINDIRECT of 
             {
              nestLevel : Word32.word,
              indirectOffset : Word32.word,
              variableTy : ty,
              loc : loc
             }

         | BUCLABEL of {label : id, loc : loc}

         | BUCGETGLOBALVALUE of 
             {
              arrayIndex : BasicTypes.UInt32, 
              offsetExp : bucexp, 
              ty : ty, 
              loc: loc
             }
             
         | BUCSETGLOBALVALUE of 
             {
              arrayIndex : BasicTypes.UInt32, 
              offsetExp : bucexp, 
              valueExp: bucexp, 
              ty:ty,
              loc :loc
             }

         | BUCINITARRAY of 
             {
              arrayIndex : BasicTypes.UInt32, 
              sizeExp : bucexp, 
              elemTy:ty, 
              loc:loc
             }

         | BUCPRIMAPPLY of 
             {
              primOp : primInfo,
              argExpList : bucexp list,
              argTyList : ty list,
              loc : loc
             }

         | BUCFOREIGNAPPLY of 
             {
               funExp : bucexp,
               argExpList : bucexp list,
               argTyList : ty list,
               loc : loc
             }

         | BUCAPPLY of 
             {
              funExp : bucexp,
              argExpList : bucexp list,
              argTyList : ty list,
              loc : loc
             }

         | BUCRECCALL of 
             {
              funExp : bucexp,
              argExpList : bucexp list,
              argTyList : ty list,
              loc : loc
             }

         | BUCLET of 
             {
              declList : bucdecl list,
              mainExp : bucexp,
              loc : loc
             }

         | BUCRECORD of 
             {
              bitmapExp : bucexp,
              totalSizeExp : bucexp,
              fieldList : bucexp list,
              fieldSizeList : bucexp list,
              fieldTyList : ty list,
              loc : loc
             }

         | BUCARRAY of 
             {
              bitmapExp : bucexp,
              sizeExp : bucexp,
              initialValue : bucexp,
              elementTy : ty,
              loc : loc
             }

         | BUCMODIFY of 
             {
              recordExp : bucexp,
              nestLevel : bucexp,
              offset :  bucexp,
              elementExp :bucexp,
              elementTy : ty,
              loc : loc
             }

         | BUCRAISE of 
             {
              exceptionExp : bucexp,
              loc : loc
             }

         | BUCHANDLE of 
           { 
            mainExp : bucexp,
            exnVar : varInfo,
            handler : bucexp,
            loc : loc
           }

         | BUCCODE of 
             {
              funInfo : funInfo,
              body : bucexp,
              loc : loc
             }

         | BUCPOLY of 
             { 
              btvEnv : btvKind IEnv.map,
              expTyWithoutTAbs : ty,
              exp : bucexp,
              loc : loc
             }


         | BUCTAPP of 
             {
              polyExp : bucexp,
              instTyList : ty list,
              loc : loc
             }

         | BUCCLOSURE of 
             {
              code : bucexp,
              env : bucexp,
              loc : loc
             }

         | BUCRECCLOSURE of {code : bucexp, loc : loc}

         | BUCSWITCH of 
             {
              switchExp : bucexp,
              expTy : ty,
              branches : (constant * bucexp) list,
              defaultExp :  bucexp,
              loc : loc
             }

         | BUCSEQ of 
             {
              expList : bucexp list,
              expTyList : ty list,
              loc : loc
             }

         | BUCGETFIELD of 
            {
             blockExp : bucexp,
             nestLevel : bucexp,
             offset : bucexp,
             loc : loc
            }

         | BUCSETFIELD of 
             {
              blockExp : bucexp,
              nestLevel : bucexp,
              offset : bucexp,
              valueExp : bucexp,
              expTy : ty,
              loc : loc
             }

         | BUCCAST of {exp : bucexp, expTy : ty, loc : loc}

         | BUCFFIVAL of 
             {
              funExp : bucexp,
              libExp : bucexp,
              argTyList : ty list,
              resultTy : ty,
              funTy : ty,
              loc : loc
             }

       and bucdecl =
           BUCVAL of 
            {
             bindList : (valId * bucexp) list,
             loc : loc
            }

         | BUCVALREC of 
             {
              recbindList : (id * ty * funInfo * bucexp ) list,
              loc : loc
             }

         | BUCVALPOLYREC of
             {
              btvEnv : btvKind IEnv.map,
              recbindList : (id * ty * funInfo * bucexp ) list,
              loc : loc
             }

         | BUCLOCALDEC of 
             {
              localDeclList : bucdecl list,
              mainDeclList : bucdecl list,
              loc : loc
             }

         | BUCEMPTY of loc

                   
  withtype funInfo =
           {
            tyvars:ty list,
            bitmapFree : bucexp,
            tagArgs : varInfo list,
            sizevals : bucexp list,
            args:varInfo list,
            resultTy:ty
           }
end

