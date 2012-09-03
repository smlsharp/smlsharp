(**
 * optimizer on A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: ANormalOptimizer.sml,v 1.8 2007/02/11 16:39:50 kiyoshiy Exp $
 *)

structure ANormalOptimizer = struct

  open ANormal
  structure AE = AtomEnv
  structure ANU = ANormalUtils
  structure CT = ConstantTerm
  structure PAO = PrimApplyOptimizer
  structure T = Types

  exception Test of string

  fun optimizeArg atomEnv exp =
      case exp of
        ANVAR {varInfo,loc} =>
        (
         case AE.findAlias(atomEnv,varInfo) of
           SOME root => root
         | _ => exp
        )
      | _ => raise Control.Bug ("variable is expected, but found " ^ (ANormalFormatter.anexpToString exp))

  fun optimizeAtom atomEnv exp =
      if AE.isAtom exp
      then
        case AE.findAtom(atomEnv,exp) of
          SOME varInfo => ANVAR{varInfo = varInfo, loc = ANU.getLocOfExp exp}
        | _ => exp
      else raise Control.Bug "atom is expected"

  fun optimizeExp atomEnv exp =
      case exp of 
        ANCONSTANT _ => optimizeAtom atomEnv exp
      | ANVAR _ => optimizeArg atomEnv exp
      | ANENVACC _ => optimizeAtom atomEnv exp
      | ANENVACCINDIRECT _ => optimizeAtom atomEnv exp
      | ANGETGLOBALVALUE _ => optimizeAtom atomEnv exp
      | ANSETGLOBALVALUE {arrayIndex,offset,valueExp,loc} =>
        ANSETGLOBALVALUE
            {
             arrayIndex = arrayIndex,
             offset = offset,
             valueExp = optimizeArg atomEnv valueExp,
             loc = loc
            }
      | ANINITARRAYUNBOXED _ => exp
      | ANINITARRAYBOXED _ => exp
      | ANINITARRAYDOUBLE _ => exp
      | ANPRIMAPPLY {primOp,argExpList,loc} => 
        PAO.optimizePrimApply 
            atomEnv 
            (
             ANPRIMAPPLY
                 {
                  primOp = primOp,
                  argExpList = map (optimizeArg atomEnv) argExpList,
                  loc = loc
                 }
            )
      | ANFOREIGNAPPLY {funExp,argExpList,argTyList,convention,loc} =>
        ANFOREIGNAPPLY
            {
             funExp = optimizeArg atomEnv funExp,
             argExpList = map (optimizeArg atomEnv) argExpList,
             argTyList = argTyList,
             convention = convention,
             loc = loc
            }
      | ANEXPORTCALLBACK {funExp,argTyList,resultTy,loc} =>
        ANEXPORTCALLBACK
            {
             funExp = optimizeArg atomEnv funExp,
             argTyList = argTyList,
             resultTy = resultTy,
             loc = loc
            }
      | ANAPPLY{funExp,argExpList,argSizeList,loc} =>
        ANAPPLY
            {
             funExp = optimizeArg atomEnv funExp,
             argExpList = map (optimizeArg atomEnv) argExpList,
             argSizeList = map (optimizeArg atomEnv) argSizeList,
             loc = loc
            }
      | ANCALL{funLabel,envExp,argExpList,argSizeList,loc} =>
        ANCALL
            {
             funLabel = funLabel,
             envExp = optimizeArg atomEnv envExp,
             argExpList = map (optimizeArg atomEnv) argExpList,
             argSizeList = map (optimizeArg atomEnv) argSizeList,
             loc = loc
            }
      | ANRECORD{bitmapExp,totalSizeExp,fieldList,fieldSizeList,loc} =>
        ANRECORD
            {
             bitmapExp = optimizeArg atomEnv bitmapExp,
             totalSizeExp = optimizeArg atomEnv totalSizeExp,
             fieldList = map (optimizeArg atomEnv) fieldList,
             fieldSizeList = map (optimizeArg atomEnv) fieldSizeList,
             loc = loc
            }
      | ANARRAY{bitmapExp,sizeExp,initialValue,loc} =>
        ANARRAY
            {
             bitmapExp = optimizeArg atomEnv bitmapExp,
             sizeExp = optimizeArg atomEnv sizeExp,
             initialValue = optimizeArg atomEnv initialValue,
             loc = loc
            }
      | ANMODIFY{recordExp,nestLevel,offset,elementExp,loc} =>
        ANMODIFY
            {
             recordExp = optimizeArg atomEnv recordExp,
             nestLevel = optimizeArg atomEnv nestLevel,
             offset = optimizeArg atomEnv offset,
             elementExp = optimizeArg atomEnv elementExp,
             loc = loc
            }
      | ANRAISE {exceptionExp,loc} =>
        ANRAISE 
            {
             exceptionExp = optimizeArg atomEnv exceptionExp,
             loc = loc
            }
      | ANHANDLE{mainExp,exnVar,handler,loc} =>
        let
          val mainExp' = optimizeExp atomEnv mainExp
        in
          case mainExp' of
            ANCONSTANT _ => mainExp'
          | ANVAR _ => mainExp'
          | _ =>
            ANHANDLE
                {
                 mainExp = mainExp',
                 exnVar = exnVar,
                 handler = optimizeExp atomEnv handler,
                 loc = loc
                }
        (*Other cases???*)
        end
      | ANCLOSURE{funLabel,env,loc} =>
        ANCLOSURE
            {
             funLabel = funLabel,
             env = optimizeArg atomEnv env,
             loc = loc
            }
      | ANSWITCH{switchExp,branches,defaultExp,loc} =>
        let
          val switchExp' as (ANVAR{varInfo,...}) = optimizeArg atomEnv switchExp
          fun find ([],_) = defaultExp
            | find ((c,e)::rest,value) =
              (
               case CT.compare(c,value) of
                 EQUAL => e
               | _ => find(rest,value)
              ) 
        in
          case AE.findVar(atomEnv,varInfo) of
            SOME (ANCONSTANT {value,...}) =>
            optimizeExp atomEnv (find(branches,value))
          | _ =>
            ANSWITCH
                {
                 switchExp = switchExp',
                 branches = map (fn (c,e) => (c,optimizeExp atomEnv e)) branches,
                 defaultExp = optimizeExp atomEnv defaultExp,
                 loc = loc
                }
        end
      | ANLET {boundVar,boundExp,mainExp,loc} =>
        let
          val boundExp' = optimizeExp atomEnv boundExp
        in
          case boundExp' of 
            ANRAISE _ => boundExp'
          | ANVAR _ =>
            optimizeExp (AE.addAlias(atomEnv,boundVar,boundExp')) mainExp
          | _ =>
            if AE.isAtom boundExp'
            then
              ANLET
                  {
                   boundVar = boundVar, 
                   boundExp = boundExp',
                   mainExp = optimizeExp (AE.addAtom(atomEnv,boundVar,boundExp')) mainExp,
                   loc = loc
                  }
            else
              ANLET
                  {
                   boundVar = boundVar, 
                   boundExp = boundExp',
                   mainExp = optimizeExp atomEnv mainExp,
                   loc = loc
                  }
        end
      | ANLETLABEL{funLabel,funInfo,funBody,mainExp,loc} =>
        ANLETLABEL
            {
             funLabel = funLabel,
             funInfo = funInfo,
             funBody = optimizeExp AtomEnv.empty funBody,
             mainExp = optimizeExp atomEnv mainExp,
             loc = loc
            }
      | ANVALREC{recbindList,mainExp,loc} =>
        ANVALREC 
            {
             recbindList =
             map 
                 (fn {funLabel,funInfo,body} => 
                     {
                      funLabel = funLabel,
                      funInfo = funInfo,
                      body = optimizeExp AtomEnv.empty body
                     }
                 )
                 recbindList,
             mainExp = optimizeExp atomEnv mainExp,
             loc = loc
            }
      | ANRECCALL{funLabel,argExpList,argSizeList,loc} =>
        ANRECCALL
            {
             funLabel = funLabel,
             argExpList = map (optimizeArg atomEnv) argExpList,
             argSizeList = map (optimizeArg atomEnv) argSizeList,
             loc = loc
            }
      | ANRECCLOSURE _ => exp
      | ANEXIT _ => exp
      | ANGETFIELD{blockExp,nestLevel,offset,loc} =>
        ANGETFIELD
            {
             blockExp = optimizeArg atomEnv blockExp,
             nestLevel = optimizeArg atomEnv nestLevel,
             offset = optimizeArg atomEnv offset,
             loc = loc
            }
      | ANSETFIELD{blockExp,nestLevel,offset,valueExp,loc} =>
        ANSETFIELD
            {
             blockExp = optimizeArg atomEnv blockExp,
             nestLevel = optimizeArg atomEnv nestLevel,
             offset = optimizeArg atomEnv offset,
             valueExp = optimizeArg atomEnv valueExp,
             loc = loc
            }

  (************************************************************************)

  fun optimize anexp = optimizeExp AE.empty anexp

end
