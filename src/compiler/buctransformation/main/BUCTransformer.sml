(**
 * BUCTransformer.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCTransformer.sml,v 1.18 2007/02/28 15:31:25 katsu Exp $
 *)

(* 
  The changes are marked with **Ohori
*)

structure BUCTransformer : BUCTRANSFORMER = struct

  open BUCCalc
  structure BT = BasicTypes
  structure CT = ConstantTerm
  structure T =  Types
  structure TU =  TypesUtils
  structure TL =  TypedLambda
  structure BU = BUCUtils
  structure BCC = BUCCompileContext
  structure ECG = ExtraComputationGenerator
  structure IDSet = ID.Set
  structure VO = VariableOptimizer

  type templateInfo =
       {
        extraDecls : bucdecl list,
        recBinds : (id * ty * funInfo * bucexp ) list,
        valrecEnvDecl : bucdecl,
        valrecEnvVar : varInfo,
        wrapperEnvDecl : bucdecl,
        wrapperEnvVar : varInfo,
        funInfo : funInfo
       }
  exception Dummy
  exception LABELFOUND of int

  val OFFSET_SHIFT_BITS = 0w16
  val OFFSET_MASK = 0wxFF

  (*******************************************************************************)
  (* printing utilities for debuging*)

  fun formatVarKind ARG = "arg"
    | formatVarKind LOCAL = "local"
    | formatVarKind FREE = "free"
    | formatVarKind (LABEL l) = "label(" ^ (ID.toString l) ^ ")"
    | formatVarKind (FREEWORD{nestLevel,offset}) = 
      "freeword(" ^ (Word32.toString nestLevel) ^ "," ^ (Word32.toString offset) ^ ")"
    | formatVarKind (FREEVAR{nestLevel,indirectOffset}) = 
      "freevar(" ^ (Word32.toString nestLevel) ^ "," ^ (Word32.toString indirectOffset) ^ ")"

  fun formatEnvBlock [] =  ""
    | formatEnvBlock ({id,displayName,ty,varKind}::rest) = 
      displayName ^ ":" ^ (formatVarKind varKind) ^ "," ^ (formatEnvBlock rest)

  fun formatEnvBlocks [] = "()" 
    | formatEnvBlocks [block] = "(" ^ (formatEnvBlock block) ^ ")"
    | formatEnvBlocks (block::rest) =
      "(" ^ (formatEnvBlock block) ^ (formatEnvBlocks rest) ^ ")"

  fun format_tlexp tlexp = 
      Control.prettyPrint (TL.format_tlexp [] tlexp)


  (*============================compilation======================================*)

  (* sort a list of variables in the following type order
   * FRAMEBITMAPty < fixed-size type < BOUNDVARty  
   *)
  fun arrangeFreeVariables (vars : varInfo list,priorIDs : ID.Set.set) =
      let
        val (frameBitmaps,fixedSizes,polys) =
            foldl 
                (fn (varInfo as {ty,id,...},(L1,L2,L3)) =>
                    if ID.Set.member(priorIDs,id) 
                    then (varInfo::L1,L2,L3)
                    else
                      (
                       case TU.compactTy ty of
                         T.ATOMty => (L1,varInfo::L2,L3)
                       | T.BOXEDty => (L1,varInfo::L2,L3)
                       | T.DOUBLEty => (L1,varInfo::L2,L3)
                       | T.BOUNDVARty _ => (L1,L2,varInfo::L3)
                       | _ => raise Control.Bug "sortVars: invalid compactTy"
                      )
                )
                ([],[],[])
                vars
      in
        (frameBitmaps @ fixedSizes @ polys)
      end


  (* - generate an offset variable for each polytype variable in each block 
   *   (except the first polytype variable which has static offset).
   * - insert offset variables at the beginning of each block
   * - fix the varKind of each variable
   *   FREE -> FREEWORD for variable located at a static offset
   *   FREE -> FREEVAR  for variable located at an arbitrary offset 
   *                    (polytype variable, except the first one)
   *)
  fun fixFreeVarKind blocks =
      let
        fun changeVarKind ({id,displayName,ty,varKind},varKind') =
            {id = id, displayName = displayName, ty = ty, varKind = varKind'}

        (* split a variable list into fixed size list and arbitrary size list*)
        fun split (fixedSizeVars,fixedSizeTys,[],[]) = 
            (rev fixedSizeVars,rev fixedSizeTys,[],[])
          | split (fixedSizeVars,fixedSizeTys,varInfo::restVars,ty::restTys) =
            (
             case ty of
               T.BOUNDVARty _ => 
               (rev fixedSizeVars,rev fixedSizeTys,varInfo::restVars,ty::restTys)
             | _ => split(varInfo::fixedSizeVars,ty::fixedSizeTys,restVars,restTys)
            )
          | split _ = raise Control.Bug "fixFreeVarKind: varList and tyList do not have the same number"

        (* inserting offsets and fixing varKind for one block*)
        fun fixList (nestLevel,isLastBlock,vars) =
            let
              val tys = map (fn {ty,...} => TU.compactTy ty) vars
              (* split variables into 2 parts: fixedSize and polytype*)
              val (fixedSizeVars,fixedSizeTys,polyVars,polyTys) = 
                  split ([],[],vars,tys)
              (* extra offsets are required for polytype variables (except the first one) *)
              val polyVarsNum = List.length polyVars
              val polyOffsetNum = if polyVarsNum = 0 then 0 else polyVarsNum - 1   
              val polyOffsetTys = List.tabulate(polyOffsetNum,fn _ => T.ATOMty)
              (* fixed-size list is extended by the nest pointer 
               * and the list of extra offsets at the beginning*)
              val (fixedSizeTys',startingIndex) =
                  if isLastBlock
                  then (polyOffsetTys @ fixedSizeTys,0)
                  else (T.BOXEDty::(polyOffsetTys @ fixedSizeTys),1)
              (* polytype offset variables are generated by using the list of predecessor types
               * of each polytype variables (except the first one)*)
              val (index,_,polyOffsetVars) = 
                  foldl
                      (fn (v as {ty,...},(index,tyList,vars)) =>
                          let
                            val tyList = tyList @ [TU.compactTy ty]
                            val polyOffsetTy = T.OFFSETty tyList
                            val varKind = FREEWORD
                                              {
                                               nestLevel = Word32.fromInt nestLevel, 
                                               offset = Word32.fromInt index
                                              }
                            val varInfo = BU.newVar(polyOffsetTy,varKind)
                          in
                            (index+1,tyList,vars @ [varInfo])
                          end
                      )
                      (startingIndex,fixedSizeTys',[])
                      (List.take(polyVars,polyOffsetNum))
              (*fix varKind of fixed size variables*)
              val (index,fixedSizeVars) =
                  foldl
                      (fn (v as {ty,...},(index,vars)) =>
                          let
                            val varKind = FREEWORD 
                                              {
                                               nestLevel = Word32.fromInt nestLevel,
                                               offset = Word32.fromInt index
                                              }
                            val varInfo = changeVarKind(v,varKind)
                            val index =
                                case TU.compactTy ty of
                                  T.DOUBLEty => index + 2
                                | _ => index + 1
                          in
                            (index,varInfo::vars)
                          end
                      )
                      (index,[])
                      fixedSizeVars
              (*fix varKind of polytype variables*)
              val firstPolyVarKind = FREEWORD
                                         { 
                                          nestLevel = Word32.fromInt nestLevel,
                                          offset = Word32.fromInt index
                                         }
              val firstPolyVar = List.take(polyVars,polyVarsNum - polyOffsetNum)
              val firstPolyVar =
                  map (fn v => changeVarKind(v,firstPolyVarKind)) firstPolyVar
              val restPolyVars = List.drop(polyVars,polyVarsNum - polyOffsetNum)
              val (_,restPolyVars) =
                  foldl
                      (fn (v,(index,vars)) =>
                          let
                            val varKind = FREEVAR
                                              {
                                               nestLevel = Word32.fromInt nestLevel,
                                               indirectOffset = Word32.fromInt index
                                              }
                            val varInfo = changeVarKind(v,varKind)
                          in
                            (index+1,varInfo::vars)
                          end
                      )
                      (startingIndex,[])
                      restPolyVars
            in
              (polyOffsetVars @ (rev fixedSizeVars) @ firstPolyVar @ (rev restPolyVars))
            end

        (* inserting offsets and fixing varkind for all blocks*)
        fun fixListOfList (nestLevel,[]) = []
          | fixListOfList (nestLevel,[vars]) = [fixList(nestLevel,true,vars)]
          | fixListOfList (nestLevel,vars::rest) =
            (fixList(nestLevel,false,vars))::fixListOfList(nestLevel+1,rest)
      in
        fixListOfList(0,blocks)
      end

  (* Converting every subterm BUCVAR{varKind=FREE,...} into ENVACC or ENVACCINDIRECT
   * This phase should be done after varKind of every free variable in the bodyContext are fixed
   *)
  fun fixEnvironmentAccess (exp,funInfo,bodyContext) =
      let
        fun fix exp =
            case exp of
              BUCCONSTANT _ => exp
            | BUCVAR {varInfo = {id,displayName,ty,varKind = FREE}, loc} => 
              (
               case BCC.findVariable(bodyContext,id) of
                 SOME {varKind = FREEWORD {nestLevel,offset},...} => 
                 BUCENVACC {nestLevel = nestLevel, offset = offset, variableTy = ty, loc = loc }
               | SOME {varKind = FREEVAR {nestLevel,indirectOffset},...} => 
                 BUCENVACCINDIRECT {nestLevel = nestLevel, indirectOffset = indirectOffset, variableTy = ty, loc = loc}
               | SOME _ => raise Control.Bug "env index not found:"
               | _ => raise Control.Bug "env index not found(2)"
              )
            | BUCVAR _ => exp
            | BUCENVACC _ => raise Control.Bug "envacc should haven't been generated"
            | BUCENVACCINDIRECT _ => raise Control.Bug "envacc should haven't been generated"
            | BUCLABEL _ => exp
            | BUCGETGLOBALVALUE {arrayIndex, offset, ty, loc} =>
              BUCGETGLOBALVALUE 
                  {
                   arrayIndex = arrayIndex,
                   offset = offset,
                   ty = ty,
                   loc = loc
                  }
            | BUCSETGLOBALVALUE {arrayIndex, offset, valueExp, ty, loc} =>
              BUCSETGLOBALVALUE 
                  {
                   arrayIndex = arrayIndex,
                   offset = offset,
                   valueExp = fix valueExp,
                   ty = ty,
                   loc = loc
                  }
            | BUCINITARRAY {arrayIndex, size, elemTy, loc} =>
              BUCINITARRAY
                  {
                   arrayIndex = arrayIndex,
                   size = size,
                   elemTy = elemTy,
                   loc = loc
                  }
            | BUCPRIMAPPLY {primOp,argExpList,argTyList,loc} => 
              BUCPRIMAPPLY 
                  {
                   primOp = primOp,
                   argExpList = map fix argExpList,
                   argTyList = argTyList,
                   loc = loc
                  }
            | BUCFOREIGNAPPLY {funExp,argExpList,argTyList,convention,loc} =>
              BUCFOREIGNAPPLY 
                  {
                   funExp = fix funExp,
                   argExpList = map fix argExpList,
                   argTyList = argTyList,
                   convention = convention,
                   loc = loc
                  }
            | BUCEXPORTCALLBACK {funExp,argTyList,resultTy,loc} =>
              BUCEXPORTCALLBACK 
                  {
                   funExp = fix funExp,
                   argTyList = argTyList,
                   resultTy = resultTy,
                   loc = loc
                  }
            | BUCAPPLY {funExp,argExpList,argSizeList,argTyList,loc} =>
              BUCAPPLY
                  { 
                   funExp = fix funExp,
                   argExpList = map fix argExpList,
                   argSizeList = map fix argSizeList,
                   argTyList = argTyList,
                   loc = loc
                  }
            | BUCRECCALL {funExp,argExpList,argSizeList,argTyList,loc} =>
              BUCRECCALL
                  {
                   funExp = fix funExp,
                   argExpList = map fix argExpList,
                   argSizeList = map fix argSizeList,
                   argTyList = argTyList,
                   loc = loc
                  }
            | BUCLET {declList,mainExp,loc} =>
              BUCLET
                  {
                   declList = map fixDecl declList,
                   mainExp = fix mainExp,
                   loc = loc
                  }
            | BUCRECORD {bitmapExp, totalSizeExp, fieldList, fieldSizeList, fieldTyList, loc} =>
              BUCRECORD
                  {
                   bitmapExp = fix bitmapExp,
                   totalSizeExp = fix totalSizeExp,
                   fieldList = map fix fieldList,
                   fieldSizeList = map fix fieldSizeList,
                   fieldTyList = fieldTyList,
                   loc = loc 
                  }
            | BUCARRAY {bitmapExp,sizeExp,initialValue,elementTy,loc} =>
              BUCARRAY 
                  { 
                   bitmapExp = fix bitmapExp,
                   sizeExp = fix sizeExp,
                   initialValue = fix initialValue,
                   elementTy = elementTy,
                   loc = loc
                  }
            | BUCMODIFY {recordExp,nestLevel,offset,elementExp,elementTy,loc} =>
              BUCMODIFY
                  {
                   recordExp = fix recordExp,
                   nestLevel = fix nestLevel,
                   offset = fix offset,
                   elementExp = fix elementExp,
                   elementTy = elementTy,
                   loc = loc
                  }
            | BUCRAISE {exceptionExp,loc} => 
              BUCRAISE {exceptionExp = fix exceptionExp, loc = loc}
            | BUCHANDLE{mainExp,exnVar,handler,loc} =>
              BUCHANDLE
                  {
                   mainExp = fix mainExp,
                   exnVar = exnVar,
                   handler = fix handler,
                   loc = loc
                  }
            | BUCCODE _ => exp
            | BUCPOLY {btvEnv,expTyWithoutTAbs,exp,loc} => 
              BUCPOLY
                  { 
                   btvEnv = btvEnv,
                   expTyWithoutTAbs = expTyWithoutTAbs,
                   exp = fix exp,
                   loc = loc 
                  }
            | BUCTAPP {polyExp,instTyList,loc} => 
              BUCTAPP {polyExp = fix polyExp,instTyList = instTyList, loc = loc}
            | BUCCLOSURE {code,env,loc} => 
              BUCCLOSURE {code = fix code, env = fix env, loc = loc}
            | BUCRECCLOSURE _ => exp
            | BUCSWITCH {switchExp,expTy,branches,defaultExp,loc} =>
              BUCSWITCH 
                  {
                   switchExp = fix switchExp,
                   expTy = expTy,
                   branches = map fixRule branches,
                   defaultExp = fix defaultExp,
                   loc = loc
                  }
            | BUCSEQ {expList,expTyList,loc} => 
              BUCSEQ {expList = map fix expList, expTyList = expTyList, loc = loc}
            | BUCGETFIELD {blockExp,nestLevel,offset,loc} => 
              BUCGETFIELD 
                  {
                   blockExp = fix blockExp,
                   nestLevel = fix nestLevel,
                   offset = fix offset,
                   loc = loc
                  }
            | BUCSETFIELD {blockExp,nestLevel,offset,valueExp,expTy,loc} =>
              BUCSETFIELD
                  { 
                   blockExp = fix blockExp,
                   nestLevel = fix nestLevel,
                   offset = fix offset,
                   valueExp = fix valueExp,
                   expTy = expTy,
                   loc = loc
                  }
            | BUCCAST {exp,expTy,loc} => 
              BUCCAST {exp = fix exp, expTy = expTy, loc = loc}
        and fixDecl decl =
            case decl of
              BUCVAL {bindList, loc} =>
              BUCVAL 
                  {
                   bindList =  map (fn (valId,exp) => (valId,fix exp)) bindList, 
                   loc = loc
                  }
            | BUCVALREC _ => decl
            | BUCVALPOLYREC _ => decl
            | BUCLOCALDEC {localDeclList,mainDeclList,loc} =>
              BUCLOCALDEC 
                  {
                   localDeclList = map fixDecl localDeclList,
                   mainDeclList = map fixDecl mainDeclList, 
                   loc = loc
                  }
            | BUCEMPTY _ => decl
        and fixRule (c,e) = (c,fix e)
        and fixFunInfo {tyvars,bitmapFree,tagArgs,sizevals,args,resultTy} =
            {
             tyvars = tyvars,
             bitmapFree = fix bitmapFree,
             tagArgs = tagArgs,
             sizevals = map fix sizevals,
             args=args,
             resultTy=resultTy
            }
      in
        (fix exp,fixFunInfo funInfo)
      end

  (* generate funInfo by 
   *   - predicting the set of type variables appearing as type of temporary variables
   *   - generating the bitmap of stack frame (bitmapvals)
   *)
  fun generateFunInfo context (argList,body,bodyTy,loc) =
      let
        fun make (context,tyMaker,tyvars) =
            let
              val varInfoList = 
                  map (fn tid => BU.newVar(tyMaker tid,LOCAL)) tyvars
            in 
              BCC.mergeVariables(context,varInfoList)
            end

        val tyvarsForArgs = BU.tvsVarInfoList argList
        val tyvarsForLocalVariables = BU.tvsTypedExp (body,bodyTy)
        val tyvarsForStackFrameSlots = ISet.union(tyvarsForArgs,tyvarsForLocalVariables)

        val (tyvarFrees, tyvarArgs) =
            ISet.foldr
                (fn (tid,(frees,args)) =>
                    if BCC.isBoundTypeVariable (context,tid) 
                    then (frees,tid::args) 
                    else (tid::frees,args)
                )
                ([],[])
                tyvarsForStackFrameSlots
        val (context,bitmapFree) = 
            case tyvarFrees of 
              [] => (context,BU.word_constant(0w0,loc))
            | _ =>
              let
                val var = BU.newVar(T.FRAMEBITMAPty tyvarFrees,LOCAL)
                val (context,var) = BCC.mergeVariable(context,var)
                val _ = BCC.setBookmark(context,BCC.FRAMEBITMAP (#id var),var)
              in
                (context,BUCVAR {varInfo = var, loc = loc})
              end
        val (context,tagArgs) = make(context, T.TAGty, tyvarArgs)

        val bitmapVars = BCC.listLocalBitmapVariables context
        val tyvarForTags = BU.tvsBitmapVarInfoList bitmapVars
        (*insert tag assumptions for generating extra code*)
        val (context,_) = make(context,T.TAGty,ISet.listItems tyvarForTags)

        val tyvarsForSizes = 
            ISet.union(tyvarsForStackFrameSlots,tyvarForTags)
        val (context,sizevals) =
            if !Control.enableUnboxedFloat
            then make(context,T.SIZEty,ISet.listItems tyvarsForSizes)
            else (context,[])

        val tyvars = tyvarArgs @ tyvarFrees

        val funInfo = 
            {
             tyvars = map T.BOUNDVARty tyvars,
             bitmapFree = bitmapFree,
             tagArgs = tagArgs,
             sizevals = map (fn v => BUCVAR {varInfo = v, loc = loc}) sizevals,
             args = argList,
             resultTy = bodyTy
            }
      in
        (context,funInfo)
      end 

  (********************************************************************)
  (* Utilities for compiling VALPOLYREC *)

  fun generateTemplateFunction (recBinds, loc) =
      let
        val (argList,apps,appTys,bodyTy) = 
            foldl
                (fn ({boundVar=v,boundTy=ty,boundExp=e},(L1,L2,L3,bodyTy)) =>
                    let
                      val (args,appTy) = 
                          case e of
                            TL.TLFNM {argVarList = args, bodyTy = bodyTy, bodyExp = body, loc = loc} => 
                            (map (fn arg => BU.newTLVar(#ty arg)) args,bodyTy)
                          | _ => raise Control.Bug "invalid valrec"
                      val appExp = 
                          TL.TLAPPM
                              {
                                funExp = TL.TLVAR {varInfo = v, loc= loc}, 
                                funTy = ty, 
                                argExpList =map (fn v => TL.TLVAR{varInfo = v,loc=loc}) args, 
                                loc = loc
                              }
                    in
                      (L1 @ args,L2 @ [appExp],L3 @ [appTy],appTy)
                    end
                )
                ([],[],[],T.ATOMty)
                recBinds
        val body = TL.TLLET
                       {
                        localDeclList =
                          [TL.TLVALREC {recbindList = recBinds,loc = loc}],
                        mainExpList = apps,
                        mainExpTyList = appTys,
                        loc = loc
                       }
      in
        (argList,body,bodyTy)
      end

  fun extractInformationFromTemplate (templateCode,templateEnv,loc) =
      case templateCode of
        BUCCODE
            {
             funInfo,
             body = 
             BUCLET
                 {
                  declList = extraDecls,
                  mainExp = 
                  BUCLET
                      {
                       declList =
                       [
                        BUCLOCALDEC
                            {
                             localDeclList = 
                             [
                              BUCVALREC {recbindList = recBinds,...},
                              valrecEnvDecl 
                                  as BUCVAL { bindList = [(VALIDVAR valrecEnvVar,_)], ...}
                             ],
                             ...
                            }
                       ],
                       ...
                      },
                  ...
                 },
             ...
            } => 
        let
          val wrapperEnvVar = BU.newVar(T.BOXEDty,LOCAL)
          val wrapperEnvDecl = BUCVAL { bindList = [(VALIDVAR wrapperEnvVar,templateEnv)], loc = loc}
        in
          {
           extraDecls = extraDecls,
           recBinds = recBinds,
           valrecEnvDecl = valrecEnvDecl,
           valrecEnvVar = valrecEnvVar,
           funInfo = funInfo,
           wrapperEnvDecl = wrapperEnvDecl,
           wrapperEnvVar = wrapperEnvVar
          }
        end
      | _ => raise Control.Bug "valpolyrec"

  fun makeWrapperBind 
          (templateInfo:templateInfo,btvEnv,extraArgs,loc)
          (label,originalVar:TL.varIdInfo,args) = 
      let
        val boundTy = 
            BU.convertTy 
                (T.POLYty {boundtvars=btvEnv , body= #ty originalVar})
        val boundVar = 
            {
             id = #id originalVar,
             displayName = #displayName originalVar,
             ty = boundTy,
             varKind = LOCAL
            } 
        val (boundTyBody as (T.FUNMty(argTys,bodyTy))) =
            case boundTy of
              T.POLYty {body,...} => body
            | _ => raise Control.Bug "invalid polyty"
        val templateFunInfo = #funInfo templateInfo
        val funInfo =
            {
             tyvars = #tyvars templateFunInfo,
             bitmapFree = #bitmapFree templateFunInfo,
             tagArgs = #tagArgs templateFunInfo,
             sizevals = #sizevals templateFunInfo,
             args = extraArgs @ args,
             resultTy = bodyTy
            }
        val sizeMap =
            foldl
                (fn (size,S) =>
                    case size of 
                      BUCVAR{varInfo = {ty = T.SIZEty tid,...},...} => IEnv.insert(S,tid,size)
                    | BUCENVACC{variableTy = T.SIZEty tid,...} => IEnv.insert(S,tid,size)
                    | _ => raise Control.Bug "invalid size expression"
                )
                IEnv.empty
                (#sizevals templateFunInfo)
        fun lookupSize ty =
            case TU.compactTy ty of
              T.ATOMty => BUCCONSTANT{value = CT.WORD 0w1,loc=loc}
            | T.BOXEDty => BUCCONSTANT{value = CT.WORD 0w1,loc=loc}
            | T.DOUBLEty => BUCCONSTANT{value = CT.WORD 0w2,loc=loc}
            | T.BOUNDVARty tid => 
              (
               case IEnv.find(sizeMap,tid) of
                 SOME e => e
               | _ => raise Control.Bug ("Size of tyvar " ^ (Int.toString tid) ^ " not found")
              )
        val exp =
            BUCPOLY
                {
                 btvEnv = btvEnv,
                 expTyWithoutTAbs = boundTyBody,
                 exp = 
                 BUCCLOSURE
                     {
                      code = 
                      BUCCODE
                          {
                           funInfo = funInfo,
                           body = 
                           BUCLET
                               {
                                declList = (#extraDecls templateInfo) @ [#valrecEnvDecl templateInfo],
                                mainExp = 
                                BUCAPPLY
                                    {
                                     funExp = 
                                     BUCCLOSURE
                                         {
                                          code = BUCLABEL {label = label, loc = loc},
                                          env = BUCVAR {varInfo = #valrecEnvVar templateInfo, loc = loc},
                                          loc = loc
                                         },
                                     argExpList = map (fn a => BUCVAR {varInfo = a,loc = loc}) args,
                                     argSizeList = map (fn {ty,...} => lookupSize ty) args,
                                     argTyList = map (fn {ty,...} => ty) args,
                                     loc = loc
                                    },
                                loc = loc
                               },
                           loc = loc
                          },
                      env = BUCVAR {varInfo = #wrapperEnvVar templateInfo, loc = loc },
                      loc = loc 
                     },
                 loc = loc
                }
      in
        (VALIDVAR boundVar,exp)
      end

  (******************************************************************************)
  (* Main compilation functions *)


  (* compile a tlexp
   * Input
   *   + context : consists of type variable environment and variable environment
   *   + tlexp : source expression
   * Result
   *   + context' : some bitmap variables and bit variables may have to be added
   *                as assumsion for the compilation
   *   + bmexp : target expression
   *)                                            
  fun compileExp context tlexp =
      case tlexp of 
        TL.TLCONSTANT {value=constant,loc} => 
        (context, BUCCONSTANT {value = constant, loc = loc}) 
      | TL.TLEXCEPTIONTAG {tagValue, loc} =>
        (context, BUCCONSTANT {value = INT(Int32.fromInt(tagValue)), loc = loc})
      | (* variables, which have been recorded in the context, must be free variables.
         * The compiler firstly marks them with FREE varkind, then converts them into
         * ENVACC in FixEnvironmentAccess
         *)
        TL.TLVAR {varInfo as {id,...}, loc} =>
        (
         case BCC.findVariable(context,id) of
           SOME {varKind = LABEL label,...}  => 
           (context,BUCRECCLOSURE {code = BUCLABEL {label = label, loc = loc}, loc = loc})
         | SOME varInfo => (context,BUCVAR {varInfo = varInfo, loc = loc})
         | NONE => 
           let
             val varInfo = BU.convertVarInfo FREE varInfo
             val context = BCC.insertVariable(context,varInfo)
           in
             (context,BUCVAR {varInfo = varInfo, loc = loc})
           end
        )
        
      | TL.TLCAST {exp = exp, targetTy = ty, loc = loc} => 
        let
          val (context,exp') = compileExp context exp
        in
          (context,BUCCAST {exp = exp', expTy = BU.convertTy ty, loc = loc })
        end

      | TL.TLGETGLOBALVALUE {arrayIndex, offset, ty, loc} =>
        let
          val (context,elementSize) = compileSize  context (TU.compactTy ty,loc)
          val offset' =
              case elementSize of
                BUCCONSTANT{value=CT.WORD w,...} => w * (UInt32.fromInt offset)
              | _ => raise Control.Bug "GETGLOBALVALUE: element size must be a constant"
        in
          (
           context,
           BUCGETGLOBALVALUE
               {
                arrayIndex = arrayIndex,
                offset = offset',
                ty = BU.convertTy ty,
                loc = loc
               }
          )
        end

      | TL.TLSETGLOBALVALUE {arrayIndex, offset, valueExp, ty, loc} =>
        let
          val (context,elementSize) = compileSize  context (TU.compactTy ty,loc)
          val offset' =
              case elementSize of
                BUCCONSTANT{value=CT.WORD w,...} => w * (UInt32.fromInt offset)
              | _ => raise Control.Bug "SETGLOBALVALUE: element size must be a constant"
          val (context, valueExp') = compileExp context valueExp
        in
          (
           context,
           BUCSETGLOBALVALUE
               {
                arrayIndex = arrayIndex,
                offset = offset',
                valueExp = valueExp',
                ty = BU.convertTy ty,
                loc = loc
               }
          )
        end

      | TL.TLINITARRAY {arrayIndex, size, elemTy, loc} =>
        let
          val (context,elementSize) = compileSize  context (TU.compactTy elemTy,loc)
          val size' =
              case elementSize of
                BUCCONSTANT{value=CT.WORD w,...} => w * (UInt32.fromInt size)
              | _ => raise Control.Bug "INITARRAY: element size must be a constant"
        in
          (
           context,
           BUCINITARRAY
               {
                arrayIndex = arrayIndex,
                size = size',
                elemTy = BU.convertTy elemTy,
                loc = loc
               }
          )
        end
        
      | TL.TLPRIMAPPLY
        {
          primOp= {name,ty},
          instTyList = tyArgList,
          argExpList = argList,
          loc = loc
        } => 
        (
         let
           val (context,argList') = compileExpList context argList
           val instanciatedTy = TU.tpappTy(ty,tyArgList)
           val argTyList = map BU.convertTy (BU.primArgTys instanciatedTy)
         in 
           (
            context,
            BUCPRIMAPPLY
                {
                 primOp = {name=name,ty=instanciatedTy},
                 argExpList = argList',
                 argTyList = argTyList,
                 loc = loc
                }
           )
         end
         handle Dummy => raise Control.Bug "dummy"
        )
        
      | TL.TLFOREIGNAPPLY
            {
             funExp = funexp as TL.TLVAR{varInfo = {ty, ...}, ...},
             funTy = funTy,
             instTyList = tyArgList,
             argExpList = argList,
             argTyList = argTys,
             convention = convention,
             loc = loc
             }=> 
        (let
           val (context,funexp') = compileExp context funexp
           val (context,argList') = compileExpList context argList
           val argTyList = map BU.convertTy argTys
         in 
           (
            context, 
            BUCFOREIGNAPPLY
                {
                 funExp = funexp', 
                 argExpList = argList', 
                 argTyList = argTyList,
                 convention = convention,
                 loc = loc
                }
           )
         end
           handle Dummy => raise Control.Bug "dummy")

      | TL.TLFOREIGNAPPLY _ => raise Control.Bug "compileExp: funcExp must be a variable"

      | TL.TLEXPORTCALLBACK
            {
             funExp = funexp as TL.TLVAR{varInfo = {ty, ...}, ...},
             instTyList = tyArgList,
             argTyList = argTys,
             resultTy = resultTy,
             loc = loc
             }=> 
        (let
           val (context,funexp') = compileExp context funexp
           val argTyList = map BU.convertTy argTys
           val resultTy' = BU.convertTy resultTy
         in 
           (
            context, 
            BUCEXPORTCALLBACK
                {
                 funExp = funexp', 
                 argTyList = argTyList,
                 resultTy = resultTy',
                 loc = loc
                }
           )
         end
           handle Dummy => raise Control.Bug "dummy")

      | TL.TLEXPORTCALLBACK _ => raise Control.Bug "compileExp: funcExp must be a variable"

      | TL.TLSIZEOF {ty, loc} =>
        let
          val (context,size) = compileSize context (TU.compactTy ty, loc)
          (* FIXME: currently we assume the size of one word is 4 bytes,
           *        but this should be configured with respect to the runtime system. *)
          val sizeOfWord = 4
          val intty = PredefinedTypes.intty
        in
          (context,
           BUCPRIMAPPLY
           {
             primOp = {name = #name (Primitives.mulIntPrimInfo),
                       ty = T.FUNMty ([intty, intty], intty)},
             argExpList = [BUCCONSTANT {value = CT.INT sizeOfWord, loc = loc}, size],
             argTyList = [intty, intty],
             loc = loc
           })
        end

      | (* if the application follows a type instantiation, the compiler first 
         * generates extra bit tag/size arguments, then un-curries these arguments 
         * with the actual argument of the application.
         *)
        TL.TLAPPM
            {
              funExp = TL.TLTAPP {exp = polyExp, expTy = polyTy, instTyList = tyArgList, loc = polyLoc},
              funTy = funcTy,
              argExpList = argList,
              loc = loc
            } =>
        (
         let
           val (context,polyExp') = compileExp context polyExp
           val (context,extraArgList) =
               generateExtraArgs context (tyArgList, loc)
           val extraArgTyList = map (fn _ => T.ATOMty) extraArgList
           val (context,argList') = compileExpList context argList
           val argTyList = map BU.convertTy (BU.argTys funcTy)
           val (context,argSizeList) = 
               compileSizeList context (map TU.compactTy argTyList, loc)
           val extraArgSizeList =
               map (fn _ => BU.word_constant(0w1,loc)) extraArgList
         in
           (
            context,
            BUCAPPLY
                {
                 funExp = BUCTAPP {polyExp = polyExp', instTyList = tyArgList, loc = polyLoc},
                 argExpList = extraArgList @ argList',
                 argSizeList = extraArgSizeList @ argSizeList,
                 argTyList = extraArgTyList @ argTyList,
                 loc = loc
                }
           )
         end
         handle Dummy => raise Control.Bug "dummy"
        )

      | (* if the application is monomorphic (there's no type instantiation)
         * and the function is a recursive function's closure,
         * the compiler translates this term into a recursive call.
         *)
        TL.TLAPPM {funExp = funcExp, funTy = funcTy, argExpList = argList, loc = loc} => 
        ( 
         let 
           val (context,funcExp') = compileExp context funcExp
           val (context,argList') = compileExpList context argList
           val argTyList = map BU.convertTy (BU.argTys funcTy)
           val (context,argSizeList) = 
               compileSizeList context (map TU.compactTy argTyList,loc)
         in 
           case funcExp' of
             BUCRECCLOSURE {code = BUCLABEL {label, loc = labelLoc},...}  => 
             (
              context,
              BUCRECCALL
                  {
                   funExp = BUCLABEL {label = label, loc = labelLoc},
                   argExpList = argList',
                   argSizeList = argSizeList,
                   argTyList = argTyList,
                   loc = loc
                  }
             )
           | _ => 
             (
              context,
              BUCAPPLY
                  {
                   funExp = funcExp',
                   argExpList = argList',
                   argSizeList = argSizeList,
                   argTyList = argTyList,
                   loc = loc
                  }
             )
         end
         handle Dummy => raise Control.Bug "dummy"
        )

      | TL.TLMONOLET {binds=bindList, bodyExp = exp, loc=loc} =>
        (
         let
           val declList =
               map 
                   (fn (x,e) => 
                       TL.TLVAL
                           {
                            bindList = [{boundValIdent = T.VALIDENT x, boundExp = e}], 
                            loc = loc
                           }
                   ) 
                   bindList
           val (context,declList') = compileDeclList context declList
           val (context,exp') = compileExp context exp
         in
           (context,BUCLET {declList = declList', mainExp = exp', loc = loc})
         end
         handle Dummy => raise Control.Bug "dummy"
        )

      | TL.TLLET {localDeclList = declList,mainExpList = expList,mainExpTyList = tyList,loc} =>
        (
         let
           val exp = TL.TLSEQ {expList = expList, expTyList = tyList,loc = loc}
           val (context,declList') = compileDeclList context declList
           val (context,exp') = compileExp context exp
         in
           (context,BUCLET {declList = declList', mainExp = exp', loc = loc})
         end
         handle Dummy => raise Control.Bug "dummy"
        )

      | TL.TLRECORD {expList=elementList, internalTy=recordTy,loc=loc,...} =>
        let
          val flty = 
              case BU.rootTy recordTy of
                T.RECORDty flty => flty
              | _ => raise Control.Bug "invalid record type"
        in
          compileRecord context (elementList,SEnv.listItems flty,loc)
        end

      | TL.TLARRAY 
        {
          sizeExp = sizeExp,
          initialValue = defaultExp,
          elementTy = elementTy,
          resultTy = arrayTy,
          loc = loc
         } =>
        let
          val elementTy = TU.compactTy elementTy
          val (context,defaultExp') = compileExp context defaultExp          
          val (context,sizeExp') =
              compileArrayOffset context (sizeExp,elementTy,loc)
          val (context,bitmapExp) = compileTag context (elementTy, loc)
        in
          (
           context,
           BUCARRAY
               {
                bitmapExp = bitmapExp,
                sizeExp = sizeExp',
                initialValue = defaultExp',
                elementTy = elementTy,
                loc = loc
               }
          )
        end

      | TL.TLSELECT {recordExp = record, indexExp = offset, recordTy = recordTy, loc = loc} =>
        let
          val (context,record') = compileExp context record
          val (context,nestLevel,offset') = compileNestedOffset context offset
        in
          (
           context,
           BUCGETFIELD
               {
                blockExp = record',
                nestLevel = nestLevel,
                offset = offset',
                loc = loc
               }
          )
        end

      | TL.TLMODIFY {
                     recordExp = record, 
                     recordTy = recordTy, 
                     indexExp = offset, 
                     elementExp = exp,
                     elementTy = expTy, 
                     loc = loc
                     } =>
        let
          val (context,record') = compileExp context record
          val (context,exp') = compileExp context exp
          val (context,nestLevel,offset') = compileNestedOffset context offset
        in
          (
           context,
           BUCMODIFY
               {
                recordExp = record',
                nestLevel = nestLevel,
                offset = offset',
                elementExp = exp',
                elementTy = BU.convertTy expTy,
                loc = loc
               }
          )
        end

      | TL.TLRAISE {argExp = exn, resultTy = ty, loc = loc} => 
        let
          val (context,exn') = compileExp context exn
        in
          (context,BUCRAISE {exceptionExp = exn', loc = loc})
        end

      | TL.TLHANDLE {exp, exnVar=varInfo, handler, loc} => 
        let
          val (context,exp') = compileExp context exp
          val varInfo = BU.convertVarInfo LOCAL varInfo
          val context = BCC.insertVariable(context,varInfo)
          val (context,handler') = compileExp context handler
        in
          (
           context,
           BUCHANDLE
               {
                mainExp = exp',
                exnVar = varInfo,
                handler = handler',
                loc = loc
               }
          )
        end

      | TL.TLFNM {argVarList = argList, bodyTy = bodyTy, bodyExp = body,loc = loc} =>
        let
          val (context,code,env,funcTy) =
              compileFunction context (IEnv.empty,argList,bodyTy,body,loc)
          val envVar = BU.newVar(T.BOXEDty,LOCAL)
        in
          (
           context,
           BUCLET
               {
                declList = [BUCVAL {bindList = [(VALIDVAR envVar, env)], loc = loc}],
                mainExp = BUCCLOSURE { code = code, env = BUCVAR {varInfo = envVar, loc = loc}, loc = loc},
                loc = loc
               }
          )
        end

      | TL.TLPOLY {
                   btvEnv = btvEnv,
                   exp = TL.TLFNM {argVarList = argList, bodyTy = bodyTy, bodyExp = body, loc = bodyLoc},
                   loc = loc,
                   ...
                   } =>
        (
         let
           val (context,code,env,funcTy) =
               compileFunction context (btvEnv,argList,bodyTy,body,loc)
           val envVar = BU.newVar(T.BOXEDty,LOCAL)
         in
           (
            context,
            BUCLET
                {
                 declList = [BUCVAL {bindList = [(VALIDVAR envVar,env)], loc = loc }],
                 mainExp =
                 BUCPOLY
                     {
                       btvEnv = btvEnv,
                       expTyWithoutTAbs = funcTy,
                       exp = BUCCLOSURE
                                 {
                                  code = code,
                                  env = BUCVAR {varInfo = envVar, loc = bodyLoc}, 
                                  loc = bodyLoc
                                 },
                       loc = loc
                     },
                 loc = loc
                }
           )
         end
         handle Dummy => raise Control.Bug "dummy"
        )

      | (* - if the source expression is a non-function polymorphic term and has a boxed type,
         *   we still have to insert extra arguments for bit tags and sizes.
         *   In this case, we consider the source exp as a polymorphic function without arguments.
         * - if the source expression has an unboxed type, it must be an integer representing
         *   a construction of a datatype optimized into integers (by record compilation)
         *)
        TL.TLPOLY {btvEnv = btvEnv, expTyWithoutTAbs = bodyTy, exp = exp, loc = loc} => 
        (
         case BU.rootTy bodyTy of 
           T.FUNMty(argTys, domTy) =>
           let
             val args = map BU.newTLVar argTys
             val argExps = map (fn arg => TL.TLVAR {varInfo = arg,loc=loc}) args
             val newExp =
                 TL.TLFNM 
                     {
                      argVarList = args, bodyTy = domTy,
                      bodyExp = TL.TLAPPM {funExp = exp, funTy = bodyTy, argExpList = argExps, loc = loc}, 
                      loc = loc
                     }
           in
             compileExp context (TL.TLPOLY {btvEnv = btvEnv, expTyWithoutTAbs = bodyTy, exp = newExp, loc = loc})
           end
        | _ =>
          if TU.isBoxedType bodyTy
          then
            compileExp
                context
                (TL.TLPOLY 
                     {
                      btvEnv = btvEnv,
                      expTyWithoutTAbs = bodyTy,
                      exp = TL.TLFNM 
                                {
                                 argVarList = [],
                                 bodyTy = bodyTy,
                                 bodyExp = exp,
                                 loc = loc
                                },
                      loc = loc
                     }
                )
          else compileExp context exp
        )

      | (* This is the case where type instantiation appears without lambda application.
         * - If the instantiated term has a function type,
         *   the compiler must first perform eta-expansion (for uncurrying)
         *      e {T1,...,Tn}
         *   ==>
         *      fn (x1,...,xm) => (e {T1,...,Tn} {x1,...xm})
         *   then compiles this result by the standard algorithm.
         * - if the instantiated term is a non-function boxed term, this requires extra  
         *   applications of bit tags and sizes to be inserted.
         * - otherwise, this must be an instantiation of an integer-optimized data construction.
         *)
        TL.TLTAPP {exp = polyExp, expTy = polyTy, instTyList = tyArgList, loc = loc} => 
        (
         let
           val funcTy = BU.rootTy (TU.tpappTy(polyTy,tyArgList))
           val (bodyTy,argTyList) =
               case funcTy of
                 T.FUNMty(argTys,body) => (body,argTys)
               | _ => (funcTy,[])
         in
           case argTyList of
             [] =>
             if TU.isBoxedType polyTy
             then 
               let
                 val (context,polyExp') = compileExp context polyExp
                 val (context,extraArgList) = 
                     generateExtraArgs context (tyArgList, loc)
                 val extraArgTyList = map (fn _ => T.ATOMty) extraArgList
                 val extraArgSizeList = map (fn _ => BU.word_constant(0w1,loc)) extraArgList
               in
                 (
                   context,
                   BUCAPPLY
                       {
                         funExp = BUCTAPP {polyExp = polyExp', instTyList = tyArgList, loc = loc},
                         argExpList = extraArgList,
                         argSizeList = extraArgSizeList,
                         argTyList = extraArgTyList,
                         loc = loc
                       }
                 )
               end
             else compileExp context polyExp

           | _ => 
             let
               val argList = map BU.newTLVar argTyList
               val newExp = 
                   TL.TLFNM 
                       {
                        argVarList = argList,
                        bodyTy = bodyTy,
                        bodyExp = TL.TLAPPM {
                                             funExp = TL.TLTAPP {
                                                                 exp = polyExp,
                                                                 expTy = polyTy,
                                                                 instTyList = tyArgList,
                                                                 loc = loc
                                                                 },
                                             funTy = funcTy,
                                             argExpList = map (fn v => TL.TLVAR{varInfo = v, loc=loc}) argList,
                                             loc = loc
                                             },
                        loc = loc
                       }
             in
               compileExp context newExp
             end
         end 
         handle Dummy => raise Control.Bug "dummy"
        )

      | TL.TLSWITCH {switchExp = selector, expTy = selectorTy, branches = rules, defaultExp = other, loc = loc} => 
        let
          val (context,selector') = compileExp context selector
          val selectorTy' = BU.convertTy selectorTy
          val (context,other') = compileExp context other
          val (context,rules') = 
              foldr 
                  (fn (({constant,exp}),(context,rules)) =>
                      let
                        (* tobe: temporary solution. In the future the intermediate 
                         * language after typeLambda should continue to propogate the 
                         * EXCEPTIONTAG term until the last compilation phase
                         * Liu
                         *)
                        val constant = 
                            case constant of
                                TL.TLCONSTANT{value,...} => value
                              | TL.TLEXCEPTIONTAG{tagValue,...} => INT(Int32.fromInt(tagValue))
                              | _ => raise Control.Bug "illegal constant"
                        val (context,exp') = compileExp context exp
                      in
                        (context,(constant,exp')::rules)
                      end)
                  (context,[]) 
                  rules
        in
          (
           context,
           BUCSWITCH
               {
                switchExp = selector',
                expTy = selectorTy',
                branches = rules',
                defaultExp = other',
                loc = loc 
               }
          )
        end

      | TL.TLSEQ {expList, expTyList,loc} =>
        let
          val (context,expList') = compileExpList context expList
          val expTyList' = map BU.convertTy expTyList
        in
          case expList' of
            [exp] => (context,exp)
          | _ => (context,BUCSEQ{expList = expList', expTyList = expTyList', loc = loc})
        end

      | TL.TLGETFIELD
        {
          arrayExp = array,
          indexExp = indexExp,
          elementTy = expTy,
          loc = loc
         }=>
        let
          val (context,array') = compileExp context array
          val (context,offset) =
              compileArrayOffset context (indexExp,TU.compactTy expTy,loc)
        in
          (
           context,
           BUCGETFIELD
               {
                blockExp = array',
                nestLevel = BU.word_constant(0w0,loc),
                offset = offset,
                loc = loc
               }
          )
        end

      | TL.TLSETFIELD 
          {
            valueExp = exp,
            arrayExp = array,
            indexExp = indexExp,
            elementTy = expTy,
            loc = loc
          } =>
        let
          val (context,exp') = compileExp context exp
          val (context,array') = compileExp context array
          val (context,offset) =
              compileArrayOffset context (indexExp,TU.compactTy expTy,loc)
         in
           (
            context, 
            BUCSETFIELD
                {
                 blockExp = array',
                 nestLevel = BU.word_constant(0w0,loc),
                 offset = offset,
                 valueExp = exp',
                 expTy = BU.convertTy expTy,
                 loc = loc
                }
           )
         end

      | TL.TLOFFSET{loc,...} =>
        let
          val (context,nestLevel,offset) = compileNestedOffset context tlexp
          val mask = 
              case nestLevel of
                BUCCONSTANT { value = CT.WORD w,...} => Word32.<<(w,OFFSET_SHIFT_BITS)
              | _ => raise Control.Bug "nestLevel of layout-fixed record offset must be a constant"
        in
          (*encoding*)
          if mask = 0w0 
          then (context,offset)
          else
            case offset of
              BUCCONSTANT{value = CT.WORD w,...} => 
              (context,BU.word_constant(Word32.orb(mask,w),loc))
            | _ =>
              (context,BU.word_orb(BU.word_constant(mask,loc),offset,loc))
        end

  and compileExpList context expList =
      let
        val (context,expList') =
            foldl 
                (fn (exp,(context,expList)) => 
                    let 
                      val (context,exp') = compileExp context exp
                    in 
                      (context,exp'::expList) 
                    end)
                (context,[]) 
                expList
      in
        (context,rev expList')
      end
      handle  Dummy => raise Control.Bug "dummy"

  and generateExtraArgs context (tyList, loc) = 
      let
        val tyList = map TU.compactTy tyList
        fun compile context compiler =
            foldr
                (fn (ty,(C,L)) =>
                    let
                      val (C',exp) = compiler C (ty, loc)
                    in
                      (C',exp::L)
                    end
                )
                (context,[])
                tyList
        val (context,tags) = compile context compileTag
        val (context,sizes) =
            if !Control.enableUnboxedFloat
            then compile context compileSize

            else (context,[])
      in
        (context,tags @ sizes)
      end

  and compileNestedOffset context exp =
      case exp of 
        TL.TLCONSTANT{value=CT.WORD w,loc} => 
        (*this is the case of accessing to the tag of a flatten datatype block*)
        (context,BU.word_constant(0w0,loc),BU.word_constant(w,loc))
      | TL.TLOFFSET{recordTy,label,loc} =>
        (*this is the case of accessing to a layout-fixed record*)
        let
          fun take (L1,L2,[],[]) = NONE
            | take (L1,L2,ty::tyRest,label'::labelRest) =
              if label = label'
              then SOME (rev L1)
              else take(ty::L1,label'::L2,tyRest,labelRest)
            | take _ = raise Control.Bug "compileNestedOffset: tyList and labelList do not have the same number"

          fun lookup (n,[]) = raise Control.Bug "compileNestedOffset: label not found"
            | lookup (n,[(tyList,labelList)]) = (*the last block - no nested pointer inserted*)
              (
               case take([],[],tyList,labelList) of 
                 SOME tyList' => (n,tyList')
               | _ => raise Control.Bug "compileNestedOffset: label not found"
              )
            | lookup (n,(tyList,labelList)::rest) = (* nested pointer needs to be inserted*)
              (
               case take([],[],tyList,labelList) of
                 SOME tyList' => (n,T.BOXEDty::tyList')
               | _ => lookup(n+0w1,rest)
              )

          val flty = 
              case BU.rootTy recordTy of
                T.RECORDty flty => flty
              | _ => raise Control.Bug "compileNestedLevel: invalid offset exp(2)"
          (*decompose record fields into blocks*)
          val (labelList,tyList) = ListPair.unzip (SEnv.listItemsi flty)
          val tyList = map TU.compactTy tyList
          val alignOpt = !Control.enableUnboxedFloat andalso !Control.alignRecord
          val blocks = BU.decomposeOrdinaryRecord (alignOpt,"",tyList,labelList)
          (*lookup the label*)
          val (nestLevel,tyList') = lookup(0w0,blocks)
          val (context,offset) = compileOffset context (tyList',loc)
        in
          (context,BU.word_constant(nestLevel,loc),offset)
        end
      | TL.TLVAR {loc,...} =>
        (* this is the case of accessing to a polymorphic record (whose layout haven't fixed)*)
        let
          val (context,encodedOffset) = compileExp context exp
          (* decoding*)
          val nestLevel = 
              BU.word_logicalRightShift
                  (encodedOffset,BU.word_constant(BT.WordToUInt32 OFFSET_SHIFT_BITS,loc),loc)
          val offset = 
              BU.word_andb
                  (encodedOffset,BU.word_constant(BT.WordToUInt32 OFFSET_MASK,loc),loc)
        in
          (context,nestLevel,offset)
        end
      | _ => raise Control.Bug "compileNestedLevel: invalid offset exp"

  and generateRecordFromList context (tyList,expList,loc) =
      let
        val (context,bitmap) = compileBitmap context (tyList,loc)
        val (context,totalSize) = compileOffset context (tyList,loc)
        val (context,elementSizeList) =
            foldr
                (fn (ty,(C,L)) =>
                    let
                      val (C',e) = compileSize C (ty, loc)
                    in
                      (C',e::L)
                    end
                )
                (context,[])
                tyList
      in
        (
         context,
         BUCRECORD
             {
              bitmapExp = bitmap,
              totalSizeExp = totalSize,
              fieldList = expList,
              fieldSizeList = elementSizeList,
              fieldTyList = tyList,
              loc = loc
             }
        )
      end

  and generateNestedRecord context ([],loc) = raise Control.Bug "generateNestedRecord"
    | generateNestedRecord context ([(tyList,expList)],loc) = 
      generateRecordFromList context (tyList,expList,loc)
    | generateNestedRecord context ((tyList,expList)::rest,loc) =
      let
        val (context,nested) = generateNestedRecord context (rest,loc)
      in
        generateRecordFromList context (T.BOXEDty::tyList,nested::expList,loc)
      end

  and compileRecord context (elementList, tyList, loc) =
      let
        val (context,elementList) = compileExpList context elementList
        val tyList = map TU.compactTy tyList
        val alignOpt = !Control.alignRecord andalso !Control.enableUnboxedFloat
        val blocks = 
            BU.decomposeOrdinaryRecord(alignOpt,BU.word_constant(0w0,loc),tyList,elementList)
      in
        generateNestedRecord context (blocks,loc)
      end

  and compileEnvRecord (context,bodyContext,loc) =
      let
        (* collect free variables appear in the function body*)
        val freeVars = BCC.listFreeVariables bodyContext
        val varSet = VO.insertList(VO.empty,freeVars)
        val optimizedFreeVars = VO.optimizedVariables varSet
        val priorIDs = 
            ID.Set.map
                (VO.lookupID varSet)
                (BCC.getFrameBitmapIDs bodyContext)
        val optimizedFreeVars = arrangeFreeVariables(optimizedFreeVars,priorIDs)

        val tyList = map (fn {ty,...} => TU.compactTy ty) optimizedFreeVars
        (* decompose free variables into blocks for making nested environment records
         * each polytype free variable consumes at most three words in an environment block:
         * two for its value and one for its offset *)
        val envBlocks =
            map #2 (BU.decomposeEnvRecord(tyList,optimizedFreeVars))
        (* add offset free variables for each polytype one and fix the varKind*)
        val envBlocks = fixFreeVarKind envBlocks
        (* build map from id to new varKind*)
        val varKindMap = 
            foldl
                (fn (vars,M) =>
                    foldl
                        (fn ({id,varKind,...},M) =>
                            ID.Map.insert(M,id,varKind)
                        )
                        M
                        vars
                )
                ID.Map.empty
                envBlocks
        val varKindMap =
            foldl
                (fn (varInfo as {id,...},M) =>
                    let
                      val varInfo' = VO.lookup(varSet,varInfo)
                      val id' = #id varInfo'
                    in
                      if ID.eq(id , id')
                      then M
                      else 
                        case ID.Map.find(M,id') of
                          SOME varKind => ID.Map.insert(M,id,varKind)
                        | _ => raise Control.Bug "varKind not found"
                    end
                )
                varKindMap
                freeVars
        (* update varKind of free variables in the bodyContext*)
        val bodyContext =
            ID.Map.foldli
                (fn (id,varKind,context) => BCC.updateVarKind(context,id,varKind))
                bodyContext
                varKindMap
        (* merge free variables into the context *)
        val (context,envBlocks) =
            foldr
                (fn (vars,(C,L)) =>
                    let
                      val (C',vars') = BCC.mergeVariables(C,vars)
                    in
                      (C',vars'::L)
                    end
                )
                (context,[])
                envBlocks
        (* compile environment blocks*)
        val envBlocks =
            map 
                (fn vars =>
                    ListPair.unzip
                        (
                         map 
                             (fn {id,displayName,ty,...} => 
                                 let
                                   val tlexp = TL.TLVAR{varInfo={id=id,displayName=displayName,ty=ty},loc=loc}
                                   (* context must not be changed*)
                                   val (_,exp) = compileExp context tlexp
                                 in
                                   (TU.compactTy ty,exp)
                                 end
                             )
                             vars
                        )
                )
                envBlocks
        val (context,env) = generateNestedRecord context (envBlocks,loc)
      in
        (context,bodyContext,env)
      end
      handle  Dummy => raise Control.Bug "dummy"

  and compileSize context (ty, loc) =
      case ty of
        T.ATOMty => (context,BU.word_constant(0w1,loc))
      | T.DOUBLEty => (context,BU.word_constant(0w2,loc))
      | T.BOXEDty => (context,BU.word_constant(0w1,loc))
      | T.BOUNDVARty tid =>
        if !Control.enableUnboxedFloat
        then 
          let
            val varInfo = BU.newVar(T.SIZEty tid,LOCAL)
            val (context,varInfo) = BCC.mergeVariable(context,varInfo)
          in
            (context,BUCVAR {varInfo = varInfo, loc = loc } )
          end
        else (context,BU.word_constant(0w1,loc))
      | T.PADty tyList => 
        let
          val varInfo = BU.newVar(T.PADty tyList,LOCAL)
          val (context,varInfo) = BCC.mergeVariable(context,varInfo)
        in
          (context,BUCVAR {varInfo = varInfo, loc = loc } )
        end
      | T.PADCONDty(tyList,tid) => 
        let
          val varInfo = BU.newVar(T.PADCONDty (tyList,tid),LOCAL)
          val (context,varInfo) = BCC.mergeVariable(context,varInfo)
        in
          (context,BUCVAR {varInfo = varInfo, loc = loc } )
        end
      | _ => raise Control.Bug "invalid compacted type"

  and compileSizeList context (tyList,loc) =
      let
        val (context,sizeList') =
            foldl 
                (fn (ty,(context,sizeList)) => 
                    let 
                      val (context,size') = compileSize context (ty,loc)
                    in 
                      (context,size'::sizeList) 
                    end)
                (context,[]) 
                tyList
      in
        (context,rev sizeList')
      end
      handle  Dummy => raise Control.Bug "dummy"

  and compileTag context (ty, loc) =
      case ty of
        T.ATOMty => (context,BU.word_constant(0w0,loc))
      | T.DOUBLEty => (context,BU.word_constant(0w0,loc))
      | T.BOXEDty => (context,BU.word_constant(0w1,loc))
      | T.BOUNDVARty tid =>
        let
          val varInfo = BU.newVar(T.TAGty tid,LOCAL)
          val (context,varInfo) = BCC.mergeVariable(context,varInfo)
        in
          (context,BUCVAR {varInfo = varInfo, loc = loc} )
        end
      | T.PADty tyList => (context,BU.word_constant(0w0,loc)) 
      | T.PADCONDty(tyList,tid) => (context,BU.word_constant(0w0,loc)) 
      | _ => raise Control.Bug "invalid compacted type"

  and compileBitmap context (tyList, loc) =
      (
       case BU.constantBitmap tyList of
         SOME w => (context,BU.word_constant(w,loc))
       | _ =>
         let
           val varInfo = BU.newVar(T.BITMAPty tyList,LOCAL)
           val (context,varInfo') = BCC.mergeVariable(context,varInfo)
         in
           (context,BUCVAR {varInfo = varInfo', loc = loc})
         end
      )
      handle  Dummy => raise Control.Bug "dummy"

  and compileOffset context (tyList, loc) =
      (
       case BU.constantOffset tyList of
         SOME w => (context,BU.word_constant(w,loc))
       | _ =>
         let
           val varInfo = BU.newVar(T.OFFSETty tyList,LOCAL)
           val (context,varInfo') = BCC.mergeVariable(context,varInfo)
         in
           (context,BUCVAR {varInfo = varInfo', loc = loc})
         end
      )
      handle  Dummy => raise Control.Bug "dummy"

  and compileArrayOffset context (indexExp,elementTy,loc) =
      let
        val (context,indexExp) = compileExp context indexExp 
        val indexExp =
            case indexExp of 
              BUCCONSTANT {value = CT.INT n, loc = loc} =>
              BU.word_constant(Word32.fromInt (Int32.toInt n), loc)
            | _ => indexExp 

        val (context,sizeExp) = compileSize context (elementTy,loc)
      in
        case (indexExp,sizeExp) of
          (BUCCONSTANT {value = CT.WORD w1, loc = loc1},BUCCONSTANT {value = CT.WORD w2, loc = loc2}) => 
          (context,BU.word_constant(w1 * w2,loc1))
        | (_,BUCCONSTANT {value = CT.WORD 0w1, loc =  loc2}) =>
          (context,indexExp)
        | (_,BUCCONSTANT {value = CT.WORD 0w2, loc = loc2}) =>
          (context,BU.word_leftShift(indexExp,BU.word_constant(0w1,loc),loc))
        | (_,_) =>
          (
           context,
           BU.word_leftShift(indexExp,BU.word_logicalRightShift(sizeExp,BU.word_constant(0w1,loc),loc),loc)
          )
      end
      handle  Dummy => raise Control.Bug "dummy"

  and compileFunction context (btvEnv,argList,bodyTy,body,loc) = 
      let
        (* Compile the body *)
        val (bodyContext,argList') = BCC.prepareFunctionContext(context,btvEnv,argList) 
        val (bodyContext,body') = compileExp bodyContext body
        val bodyTy' = BU.convertTy bodyTy
        (* generate the funInfo*)
        val (bodyContext,funInfo) =
            generateFunInfo bodyContext (argList',body',bodyTy',loc)
        (* compute the indexes of free variables in the environment record*)
        val (context,bodyContext,env) = compileEnvRecord (context,bodyContext,loc)
        (* convert variables marked with FREE into ENVACC terms*)
        val (body',funInfo') = fixEnvironmentAccess(body',funInfo,bodyContext)
        (* generate extra computation code and put it at the beginning of the function body *)
        val body' = BUCLET{declList = ECG.generate bodyContext loc,mainExp = body',loc = loc}
        (* make code *)
        val code = BUCCODE{funInfo = funInfo', body = body', loc = loc }
        val resultTy = T.FUNMty (map #ty argList',bodyTy')
      in
        (context,code,env,resultTy)
      end
      handle  Dummy => raise Control.Bug "dummy"


  and compileRecBind context (argList,body,bodyTy,loc) =
      let
        val argList' = map (BU.convertVarInfo ARG) argList
        val context = BCC.insertVariables(context,argList')
        val (context,body') = compileExp context body
        val bodyTy' = BU.convertTy bodyTy
        val (context,funInfo) =
            generateFunInfo context (argList',body',bodyTy',loc)
      in
        (context,funInfo,body')
      end 
      handle  Dummy => raise Control.Bug "dummy"

  (* compile a monomorphic valrec decl
   * source decl
   *    val rec f1 = fn x1 => e1
   *            ...
   *        and fn = fn xn => en
   * target decl
   *    local
   *       val rec f1#code = fn x1 => e1'
   *               ....
   *           and fn#code = fn xn => en'
   *       val env = (bitmap;...)
   *    in
   *       val f1 = Closure(f1#code,env)
   *           ....
   *       and fn = Closure(fn#code,env)
   *    end 
   *)   
  and compileVALREC context (recBinds, loc) = 
      let
        (*make an initial common context*)
        val bodyContext = BCC.makeContext(IEnv.empty::(BCC.getTyEnv context))
        val labels = 
            map 
                (fn {boundVar=v,boundTy=ty,boundExp=e} => BU.convertVarInfo (LABEL (T.newVarId())) v)
                recBinds
        val bodyContext = BCC.insertVariables(bodyContext,labels)
        (* compile mutual recursive functions,
         * common context will be incremental changed with new variable assumptions 
         *)
        val (bodyContext,recBinds') =
            ListPair.foldl
                (fn ({varKind as LABEL label,...},{boundVar=v,boundTy=ty,boundExp=e},(context,L)) =>
                    let
                      val (argList,body,bodyTy) =
                          case e of
                            TL.TLFNM {argVarList = args, bodyTy = ty, bodyExp = exp, ...} => (args,exp,ty)
                          | _ => raise Control.Bug "invalid valrec"
                      val (context,funInfo,body') =
                          compileRecBind context (argList,body,bodyTy,loc)
                    in
                      (context,(label,BU.convertTy ty,funInfo,body')::L)
                    end
                  | _ => raise Control.Bug "compileVALREC:varKind must be a LABEL"
                )
                (bodyContext,[])
                (labels,recBinds)
        val recBinds' = rev recBinds'
        (* compile the environment record and update varKind for fixing bodies*)
        val (context,bodyContext,env) = compileEnvRecord (context,bodyContext,loc)
        val envVar = BU.newVar(T.BOXEDty,LOCAL)
        (* fixing the function bodies by converting BUCVAR{varKind=FREE,...} into ENVACC  *)
        val recBinds' =
            map 
                (fn (label,ty,funInfo,body) =>
                    let
                      val (body',funInfo') =
                          fixEnvironmentAccess(body,funInfo,bodyContext)
                    in
                      (label,ty,funInfo',body')
                    end)
                recBinds'
        (* generate the target declaration*)
        val binds =
            ListPair.map 
                (fn ({boundVar=v,...},(l,_,_,_)) =>
                    (
                      VALIDVAR (BU.convertVarInfo LOCAL v),
                      BUCCLOSURE
                          {
                           code = BUCLABEL {label = l, loc = loc},
                           env = BUCVAR {varInfo = envVar, loc = loc }, 
                           loc = loc
                          }
                    ))
                (recBinds,recBinds')
        val result =
            BUCLOCALDEC 
                {
                 localDeclList = 
                 [
                  BUCVALREC {recbindList = recBinds', loc = loc},
                  BUCVAL {bindList = [(VALIDVAR envVar,env)], loc = loc}
                 ],
                 mainDeclList = 
                 [BUCVAL {bindList = binds, loc = loc}],
                 loc = loc
                }
        val context =
            foldl
                (fn ((VALIDVAR v,e),S) => BCC.insertVariable(S,v)
                  | _ => raise Control.Bug "compileVALREC: VALIDVAR expected"
                )
                context
                binds
      in
        (context,result)
      end
      handle  Dummy => raise Control.Bug "dummy"

  (* compile the following polymorphic val rec
   *
   * [ {t1,...,tm}. {i1,...,ik} =>
   *      val rec f1 = fn x1 => e1
   *          ...
   *          and fn = fn xn => en
   * ]
   *
   * into the following target term
   *
   * local
   *   [{t1,...,tm}.
   *     val rec f1#code = fn x1 => e1'
   *         ...
   *         and fn#code = fn xn => en'
   *   ]
   *   val env1 = (...)
   * in
   *   val f1 = 
   *       [{t1,...,tm}.
   *          Closure
   *           (
   *            fn {tag1,...,tagm,size1,...,sizem,i1,...,ik,x1} =>
   *              let
   *                (* extra computation*)
   *                val env2 = (...)
   *              in
   *                Closure(f1#code,env2) x1
   *              end,
   *            env1 
   *           )
   *       ]
   *   ...
   *   val fn = ....
   * end
   * 
   * This is done by first compiling the following function
   *
   * [ {t1,...,tm}.
   *   fn {i1,...,ik,x1',...,xn'} =>
   *     let
   *       val rec f1 = fn x1 => e1
   *           ...
   *           and fn = fn xn => en
   *     in 
   *       (f1 x1';...;fn xn')
   *     end 
   * ]
   * 
   * to the following bitmapcalc term
   *
   * [ {t1,...,tm}.
   *    Closure
   *     (
   *      fn {tag1,...,tagm,size1,...,sizem,i1,...,ik,x1',...,xn'} =>
   *        let
   *          (*extra computation*)
   *          local
   *            val rec f1#code = fn x1 => e1'
   *                 ....
   *                and fn#code = fn xn => en'
   *            val env2 = (...)
   *          in
   *            val f1 = Closure(f1#code,env2)
   *             ....
   *            and fn = Closure(fn#code,env2)
   *          end
   *        in
   *           (f1 x1';....;fn xn')
   *        end,
   *      env1
   *     )
   * ]
   * 
   * then, from this term, we can extract useful information to build the target term
   *)
  and compileVALPOLYREC context (btvEnv,indexArgs,recBinds,loc) = 
      let
        (*generate and compile template function*)
        val indexArgs' = map (BU.convertVarInfo ARG) indexArgs
        val (templateArgList,templateBody,templateBodyTy) =
            generateTemplateFunction (recBinds,loc)
        val (context,templateCode,templateEnv,_) = 
            compileFunction 
                context 
                (btvEnv,indexArgs @ templateArgList,templateBodyTy,templateBody,loc)
        (* extract useful information*) 
        val templateInfo =
            extractInformationFromTemplate (templateCode,templateEnv,loc)
        val extraArgCount = 
            if !Control.enableUnboxedFloat 
            then (IEnv.numItems btvEnv) * 2
            else IEnv.numItems btvEnv
        val extraArgs = 
            (List.take(#args (#funInfo templateInfo),extraArgCount)) @ indexArgs'
        (* build the target decl*)
        val wrapperBindsInfo =
            ListPair.map 
                (fn ((label,_,{args,...},_),{boundVar=originalFuncVar,...}) =>
                    (label,originalFuncVar,map (fn {ty,...} => BU.newVar(ty,ARG)) args)
                )
                (#recBinds templateInfo,recBinds)
        val wrapperBinds = 
            map 
                (makeWrapperBind (templateInfo,btvEnv,extraArgs,loc))
                wrapperBindsInfo
        val result =
            BUCLOCALDEC
                {
                 localDeclList = 
                 [
                  BUCVALPOLYREC 
                      {
                       btvEnv = btvEnv,
                       recbindList = #recBinds templateInfo,
                       loc = loc
                      },
                  #wrapperEnvDecl templateInfo
                 ],
                 mainDeclList = 
                 [BUCVAL {bindList = wrapperBinds, loc = loc}],
                 loc = loc
                }
        val context =
            foldl
                (fn ((VALIDVAR v,e),S) => BCC.insertVariable(S,v)
                  | _ => raise Control.Bug "compileVALPOLYREC: VALIDVAR expected"
                )
                context
                wrapperBinds
      in
        (context,result)
      end
      handle  Dummy => raise Control.Bug "dummy"


  (* compile a tldecl
   * context will be extended with the bitmap variables, bit variables
   * introduced during the compilation of bound expressions.
   * bound variables are also included in the extended context and are 
   * returned as visible variables 
   *)
  and compileDecl context decl =
      (
       case decl of
         TL.TLVAL {bindList = binds, loc} =>
         let 
           val (context,binds') =
               foldl
                   (fn ({boundValIdent=T.VALIDENT v,boundExp = e},(context,L)) =>
                       let
                         val (context,e') = compileExp context e
                         val v' = BU.convertVarInfo LOCAL v
                         val context = BCC.insertVariable(context,v')
                       in
                         (context,(VALIDVAR v',e')::L)
                       end
                     | ({boundValIdent=T.VALIDENTWILD ty,boundExp =e},(context,L)) =>
                       let
                         val (context,e') = compileExp context e
                         val ty' = BU.convertTy ty
                       in
                         (context,(VALIDWILD ty',e')::L)
                       end
                   )
                   (context,[])
                   binds
         in
           (context,BUCVAL {bindList = rev binds', loc = loc})
         end
       | TL.TLVALREC {recbindList, loc} => compileVALREC context (recbindList, loc)
                                 
       | TL.TLVALPOLYREC {btvEnv, indexVars, recbindList, loc} => 
         compileVALPOLYREC context (btvEnv,indexVars,recbindList,loc)
         
       | TL.TLLOCALDEC {localDeclList = localDecls, mainDeclList = decls, loc} =>
         let
           val (context,localDecls') = compileDeclList context localDecls
           val (context,decls') = compileDeclList context decls
         in
           (context,BUCLOCALDEC {localDeclList = localDecls', mainDeclList = decls', loc = loc})
         end
         
       | TL.TLEMPTY loc => (context, BUCEMPTY loc)
                       
      )
      handle  Dummy => raise Control.Bug "dummy"

  and compileDeclList context declList =
      let
        val (context',declList') =
            foldl
                (fn (decl,(C,L)) =>
                    let
                      val (C',decl') = compileDecl C decl
                    in
                      (C',decl'::L)
                    end
                )
                (context,[])
                declList
      in
        (context',rev declList')
      end 
      handle  Dummy => raise Control.Bug "dummy"


(*=====================main compile function===================================== *)

  fun transform tldeclList =
      let
        val context = BCC.makeContext([IEnv.empty])
        val (_,declList) = compileDeclList context tldeclList
      in
        declList
      end
      handle  Dummy => raise Control.Bug "dummy"
                             
end
