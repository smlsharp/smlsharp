(**
 * Module compiler flattens structure.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: UniqueIdAllocationCore.sml,v 1.14 2008/03/11 08:53:57 katsu Exp $
 *)
structure UniqueIdAllocationCore  = 
struct
local
  structure CT = ConstantTerm
  structure T  = Types
  structure P = Path
  structure TU = TypesUtils
  structure FAU = FunctorApplyUtils
  structure VIC = VarIDContext
  structure UIAU = UniqueIdAllocationUtils
  structure UIAC = UniqueIdAllocationContext
  structure NM = NameMap
  structure NPEnv = NM.NPEnv

  datatype valIdent = datatype Types.valIdent

  open TypedCalc
  open TypedFlatCalc

  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")
  fun typeToString ty = TypeFormatter.tyToString ty

  val debug = false
  fun printx x = if debug then print x else ()
in

  fun tppatToTfppatList context tppatList =
      let
        val (varIDEnv,tfppatlist) = 
            foldr (
            fn (tppat,(varIDEnv,tfppatlist)) =>
               let
                 val (varIDEnv',tfppat) =
                     tppatToTfppat NPEnv.empty context tppat
                 val newvarIDEnv = 
                     VIC.mergeVarIDEnv {newVarIDEnv = varIDEnv',
                                        oldVarIDEnv = varIDEnv}
               in
                 (newvarIDEnv, tfppat::tfppatlist)
               end)
                  (VIC.emptyVarIDEnv, nil)
                  tppatList
      in
        (
         varIDEnv,
         tfppatlist
        )
      end
 (*
  * orEnv is added to deal with orPattern by Ohori
  * In the or-patter (P1|P2), the set of variables in P1 and P2 is the same
  * and that they msut be given the same id.
  * orEnv is used to remembver the old ids assigned in P1 when translating P2.
  *
  *)
  and tppatToTfppat orEnv context tppat =
      case tppat of
        TPPATWILD args => (VIC.emptyVarIDEnv,TFPPATWILD args)
      | TPPATVAR (varPathInfo as {namePath,ty,...},loc) =>
        let
       (* All pattern variables are also prefixed with the structure path.
        * For the error reporting of Match Compiler, since all variables in
        * pattern only have short names, we just throw away the path part
        * in namePath. 
        *)
          val name =  #1 namePath
          val id = 
              case NPEnv.find(orEnv, namePath) of 
                SOME (VIC.Internal (id, _)) => id
              | SOME (VIC.External _ ) =>
                raise Control.Bug "illegal topItem here"
              | SOME VIC.Dummy => raise Control.Bug "illegal topItem here"
              | NONE => Counters.newLocalID()
          val varIDEnv = 
	      NPEnv.singleton(namePath, VIC.Internal (id, ty))
          val varIdInfo = {displayName = name, ty = ty, varId = T.INTERNAL id}
        in 
          (varIDEnv,TFPPATVAR(varIdInfo, loc))
        end
      | TPPATCONSTANT (constant, ty, loc) =>
        (
         VIC.emptyVarIDEnv,
         TFPPATCONSTANT (CT.fixConst(constant, ty, loc), ty, loc)
        )
      | TPPATDATACONSTRUCT
          {conPat=conPathInfo as {namePath,funtyCon,ty,tag,tyCon},
           instTyList=tys,
           argPatOpt=tppatop,
           patTy=ty1,
           loc=loc}
        =>
        let
          val newconInfo = 
              {
               displayName = NM.usrNamePathToString namePath,
               funtyCon=funtyCon, 
               ty=ty, 
               tag=tag, 
               tyCon = tyCon
              }
          val (varIDEnv,tfppatop) = 
              case tppatop of 
                NONE => (VIC.emptyVarIDEnv,NONE)
              | SOME(tppat) =>
                let
                  val (varIDEnv',tfppat) = tppatToTfppat orEnv context tppat
                in 
                  (varIDEnv',SOME(tfppat))
                end
        in
          (
           varIDEnv,
           TFPPATDATACONSTRUCT
             {conPat=newconInfo,
              instTyList=tys,
              argPatOpt=tfppatop,
              patTy=ty1,
              loc=loc}
          ) 
        end
      | TPPATEXNCONSTRUCT
          {exnPat=conPathInfo as {namePath,funtyCon,ty,tag,tyCon},
           instTyList=tys,
           argPatOpt=tppatop,
           patTy=ty1,
           loc=loc}
        =>
        let
          val newconInfo = 
              {
               displayName = NM.usrNamePathToString namePath,
               funtyCon=funtyCon, 
               ty=ty, 
               tag=tag, 
               tyCon = tyCon
              }
          val (varIDEnv,tfppatop) = 
              case tppatop of 
                NONE => (VIC.emptyVarIDEnv,NONE)
              | SOME(tppat) =>
                let
                  val (varIDEnv',tfppat) = tppatToTfppat orEnv context tppat
                in 
                  (varIDEnv',SOME(tfppat))
                end
        in
          (
           varIDEnv,
           TFPPATEXNCONSTRUCT
             {exnPat=newconInfo,
              instTyList=tys,
              argPatOpt=tfppatop,
              patTy=ty1,
              loc=loc}
          ) 
        end
      | TPPATRECORD {fields=patfields, recordTy=ty,loc=loc} => 
        let
          val (varIDEnv,tfppatfields) = 
              SEnv.foldri
                (fn (label,tppat,(varIDEnv,tppatfields)) =>
                    let
                      val (varIDEnv',tfppat) =
                          tppatToTfppat orEnv context tppat
                      val newvarIDEnv = 
                          VIC.mergeVarIDEnv {newVarIDEnv = varIDEnv',
                                             oldVarIDEnv = varIDEnv}
                      val newtppatfields = 
                          SEnv.insert(tppatfields,label,tfppat)
                    in
                      (newvarIDEnv,newtppatfields)
                    end)
                (VIC.emptyVarIDEnv,SEnv.empty)
                patfields
        in
          (
           varIDEnv,
           TFPPATRECORD{fields=tfppatfields,recordTy=ty,loc=loc}
          )
        end
      | TPPATLAYERED {varPat=tppat1, asPat=tppat2, loc=loc} =>
        let
          val (varIDEnv1,tfppat1) = tppatToTfppat orEnv context tppat1
          val (varIDEnv2,tfppat2) = tppatToTfppat orEnv  context tppat2
        in
          (VIC.mergeVarIDEnv{newVarIDEnv = varIDEnv1,
                             oldVarIDEnv = varIDEnv2},
           TFPPATLAYERED{varPat=tfppat1, asPat=tfppat2, loc=loc})
        end
      | TPPATORPAT (tppat1, tppat2, loc) => 
        let
          val (varIDEnv1,tfppat1) = tppatToTfppat orEnv context tppat1
          val (varIDEnv2,tfppat2) =
              tppatToTfppat (VIC.mergeVarIDEnv {newVarIDEnv = varIDEnv1,
                                                oldVarIDEnv = orEnv})  
                            context tppat2
        in
          (varIDEnv1,
           TFPPATORPAT (tfppat1, tfppat2, loc)
          )
        end

  fun tpexpToTfpexpList (context:UIAC.context) tpexpList =
      map (fn tpexp => tpexpToTfpexp context tpexp) tpexpList

  and tpexpToTfpexp (context:UIAC.context) (tpexp : tpexp) =
      case tpexp of
        TPFOREIGNAPPLY {funExp=tpexp1, 
                        funTy=funTy,
                        instTyList=tyList, 
                        argExpList=tpexpList2, 
                        argTyList=argTys,
                        attributes,
                        loc=loc}
        =>
        let
          val tfpexp1 = tpexpToTfpexp context tpexp1  
          val tfpexpList2 = tpexpToTfpexpList context tpexpList2
        in 
          TFPFOREIGNAPPLY {funExp=tfpexp1, 
                           funTy=funTy,
                           instTyList=tyList, 
                           argExpList=tfpexpList2, 
                           argTyList=argTys,
                           attributes=attributes,
                           loc=loc}
        end
      | TPEXPORTCALLBACK {funExp=tpexp1,
                          argTyList=argTyList,
                          resultTy=resultTy,
                          attributes,
                          loc=loc}
        =>
        let
          val tfpexp1 = tpexpToTfpexp context tpexp1  
        in 
          TFPEXPORTCALLBACK {funExp=tfpexp1,
                             argTyList=argTyList,
                             resultTy=resultTy,
                             attributes=attributes,
                             loc=loc}
        end
      | TPSIZEOF (ty, loc) => TFPSIZEOF (ty, loc)
      | TPCONSTANT (constant, ty, loc) =>
        TFPCONSTANT (CT.fixConst (constant, ty, loc), loc)
      | TPGLOBALSYMBOL (name,kind,ty,loc) =>
        TFPGLOBALSYMBOL (name, kind, ty, loc)
      | TPVAR ({namePath = namePath, ty = ty}, loc) =>
        let
          val displayName = NM.usrNamePathToString namePath
          val tfpexp1 = 
              case VIC.lookupVar (#topVarExternalVarIDBasis context, 
                                  #varIDBasis context, 
                                  namePath) of
                SOME (VIC.External index) => 
                TFPVAR
                  ({
                   displayName = displayName,
                   ty = ty,
                   varId = T.EXTERNAL index
                   },
                   loc)
              | SOME (VIC.Internal (id, _)) =>
                TFPVAR({displayName = displayName, 
                        ty = ty, 
                        varId = T.INTERNAL id}, 
                       loc)
              | SOME VIC.Dummy =>
              (* Dummy may appear in one of the following case,
               * (1) Compilation phases before UniqueIDAllocation
               *     fails to replace all primitive applications to
               *     PRIMAPPLY.
               * (2) Either user writes or compiler generates code
               *     referencing a dummy variable defined in Builtin-
               *     Context. Dummy variable is introduced for
               *     placeholder of bootstrap.
               * Accessing dummy variable is prohibited. It should be
               * a bug.
               *)
                let
                  val e = PredefinedTypes.BootstrapExnPathInfo
                  val exnInfo = 
                      {displayName = NM.usrNamePathToString (#namePath e),
                       funtyCon = #funtyCon e,
                       ty = #ty e,
                       tag = #tag e,
                       tyCon = #tyCon e}
                  val _ = TextIO.output
                            (TextIO.stdErr,
                             "found a reference to DUMMY global name `" ^
                             displayName ^ "'; program won't work\n");
                in
                  TFPRAISE
                    (TFPEXNCONSTRUCT {exn = exnInfo,
                                      instTyList = nil,
                                      argExpOpt = NONE,
                                      loc = loc},
                     ty, loc)
                end
              | NONE =>
                raise
                  Control.BugWithLoc
                    ("undefined variable:"^ (NM.namePathToString namePath),
                     loc)
        in
          tfpexp1
        end
      | TPRECFUNVAR {var = {namePath,...},...} => 
        (print (NM.namePathToString namePath);
         print "\n";
         raise Control.Bug "TPRECFUNVAR in module compiler"
        )
      | TPPRIMAPPLY {primOp=primInfo as {name,ty},
                     instTyList=tys,
                     argExpOpt=tpexpop,
                     loc=loc} =>
        let
          val tfpexpop = 
              case tpexpop of
                NONE => NONE
              | SOME(tpexp) => 
                let 
                  val tfpexpop = tpexpToTfpexp context tpexp
                in
                  SOME(tfpexpop)
                end
        in 
          TFPPRIMAPPLY
            {primOp=primInfo, instTyList=tys, argExpOpt=tfpexpop, loc=loc}
        end
      | TPOPRIMAPPLY {oprimOp=oprimInfo as {name,ty,instances}, 
                      instances=tys, 
                      argExpOpt=tpexpop,
                      loc=loc} =>
        let
          val tfpexpop = 
              case tpexpop of
                NONE => NONE
              | SOME(tpexp) => 
                let
                  val tfpexpop = tpexpToTfpexp context tpexp
                in
                  SOME(tfpexpop)
                end
        in 
          TFPOPRIMAPPLY{oprimOp=oprimInfo,
                        instances=tys,
                        argExpOpt=tfpexpop,
                        loc=loc}
        end
      | TPDATACONSTRUCT{con=conPathInfo as {namePath,funtyCon,ty,tag,tyCon},
                        instTyList=tys,
                        argExpOpt=tpexpop,
                        loc=loc} =>
        let
          val newconInfo = 
              {
               displayName = NM.usrNamePathToString namePath, 
               funtyCon = funtyCon, 
               ty = ty, 
               tag = tag, 
               tyCon = tyCon
              }:conInfo
          val tfpexpop = 
              case tpexpop of
                NONE => NONE
              | SOME(tpexp) => 
                let
                  val tfpexpop = tpexpToTfpexp context tpexp
                in
                  SOME(tfpexpop)
                end
        in
          TFPDATACONSTRUCT
            {con=newconInfo, instTyList=tys, argExpOpt=tfpexpop, loc=loc}
        end
      | TPEXNCONSTRUCT{exn=exnPathInfo as {namePath,funtyCon,ty,tag,tyCon},
                       instTyList=tys,
                       argExpOpt=tpexpop,
                       loc=loc} =>
        let
          val newexnInfo = 
              {
               displayName = NM.usrNamePathToString namePath, 
               funtyCon = funtyCon, 
               ty = ty, 
               tag = tag, 
               tyCon = tyCon
              }
          val tfpexpop = 
              case tpexpop of
                NONE => NONE
              | SOME(tpexp) => 
                let
                  val tfpexpop = tpexpToTfpexp context tpexp
                in
                  SOME(tfpexpop)
                end
        in
          TFPEXNCONSTRUCT
            {exn=newexnInfo, instTyList=tys, argExpOpt=tfpexpop, loc=loc}
        end
      | TPAPPM {funExp=tpexp1,funTy=funty, argExpList=tpexpList2,loc} =>
        let
          val tfpexp1 = tpexpToTfpexp context tpexp1 
          val tfpexpList2 = tpexpToTfpexpList context tpexpList2
        in 
          TFPAPPM
            {funExp=tfpexp1, funTy=funty, argExpList=tfpexpList2, loc=loc}
        end
      | TPMONOLET {binds, bodyExp=tpexp, loc} =>
        let
          fun tpbindsToTfpbinds context nil = 
              (VIC.emptyVarIDEnv, nil)
            | tpbindsToTfpbinds context (tpbind::rem) =
              let
                val (varPathInfo as {namePath,ty},tpexp) = tpbind
                val name = NM.usrNamePathToString namePath
                val id = Counters.newLocalID()
                val varIdInfo = {displayName = name, 
                                 ty = ty,
                                 varId = T.INTERNAL id}
                val tfpexp = tpexpToTfpexp context tpexp
                val varIDEnv1 = 
                    NPEnv.singleton(namePath, VIC.Internal (id, ty))
                val newContext = 
                    UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
                val (varIDEnv2, tfpbinds) = 
                    tpbindsToTfpbinds newContext rem
              in 
                (
                 VIC.mergeVarIDEnv {newVarIDEnv=varIDEnv2,
                                    oldVarIDEnv=varIDEnv1},
                 (varIdInfo,tfpexp)::tfpbinds
                )
              end
          val (varIDEnv1, newbinds) = tpbindsToTfpbinds context binds
          val newContext = UIAC.extendContextWithVarIDEnv(context, varIDEnv1)
          val tfpexp = tpexpToTfpexp newContext tpexp
        in 
          TFPMONOLET {binds=newbinds, bodyExp=tfpexp, loc=loc}
        end
      | TPLET (tpdecs,tpexps,tys,loc) =>
        let
          val (varIDEnv1, tfpdecs) = 
              tpdecsToTfpdecs context tpdecs
          val newContext1 = UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
          val tfpexps = map (tpexpToTfpexp newContext1) tpexps
        in
          TFPLET(tfpdecs,tfpexps,tys,loc)
        end
      | TPRECORD {fields, recordTy=ty,loc} =>
        let
          val tfpfields =
              SEnv.map (fn tpexp => tpexpToTfpexp context tpexp) fields
        in 
          TFPRECORD{fields=tfpfields, recordTy=ty, loc=loc}
        end
      | TPSELECT {label=tag, exp=tpexp, expTy=ty, resultTy, loc=loc} =>
        let
          val tfpexp = tpexpToTfpexp context tpexp 
        in 
          TFPSELECT
            {label=tag, exp=tfpexp, expTy=ty, resultTy= resultTy, loc=loc}
        end
      | TPMODIFY {label, 
                  recordExp=tpexp1, 
                  recordTy=ty1, 
                  elementExp=tpexp2, 
                  elementTy= ty2, 
                  loc=loc} =>
        let
          val tfpexp1 = tpexpToTfpexp context tpexp1
          val tfpexp2 = tpexpToTfpexp context tpexp2
        in
          TFPMODIFY {label=label, 
                     recordExp=tfpexp1, 
                     recordTy=ty1, 
                     elementExp=tfpexp2, 
                     elementTy=ty2, 
                     loc=loc}
        end
      | TPRAISE (tpexp,ty,loc) =>
        TFPRAISE(tpexpToTfpexp context tpexp,ty,loc)
      | TPHANDLE {exp=tpexp1, 
                  exnVar=varPathInfo as {namePath,ty,...}, 
                  handler=tpexp2, 
                  loc} =>
        let
          val id = Counters.newLocalID()
          val name = NM.usrNamePathToString namePath
          val varIdInfo = {displayName = name, ty = ty, varId = T.INTERNAL id}
          val tfpexp1 = tpexpToTfpexp context tpexp1
          val varIDEnv1 = 
              NPEnv.singleton(namePath, (VIC.Internal (id, ty)))
          val newContext =
              UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
          val tfpexp2 = tpexpToTfpexp newContext tpexp2
        in 
          TFPHANDLE {exp=tfpexp1, exnVar=varIdInfo, handler=tfpexp2, loc=loc}
        end
      | TPCASEM {expList=tpexpList, 
                 expTyList=tyList1, 
                 ruleList=rules,
                 ruleBodyTy=ty2,
                 caseKind=caseKind,
                 loc=loc} =>
        let
          val tfpexpList = tpexpToTfpexpList context tpexpList
          val tfprules =
              map
                (fn (tppatList,tpexp) =>
                    let
                      val (varIDEnv, tfppatList) = 
                          tppatToTfppatList context tppatList
                      val newContext =
                          UIAC.extendContextWithVarIDEnv
                            (context, varIDEnv)
                      val tfpexp = tpexpToTfpexp newContext tpexp
                    in 
                      (tfppatList, tfpexp)
                    end
                )
                rules
        in 
          TFPCASEM{expList=tfpexpList, 
                   expTyList=tyList1,
                   ruleList=tfprules,
                   ruleBodyTy=ty2,
                   caseKind=caseKind,
                   loc=loc}
        end
      | TPFNM {argVarList, bodyTy=ty1, bodyExp=tpexp, loc} =>
        let
          val (varIdInfoList, varIDEnv) = 
              foldl
                (fn ({namePath, ty}, (varIdInfoList, varIDEnv)) => 
                    let
                      val id = Counters.newLocalID()
                      val displayName = NM.usrNamePathToString namePath
                    in
                      (varIdInfoList @ [{displayName = displayName, 
                                         ty = ty, 
                                         varId = T.INTERNAL id}],
                       NPEnv.insert(varIDEnv, 
                                    namePath,
                                    (VIC.Internal (id, ty))
                                   )
                      )
                    end)
                (nil, NPEnv.empty)
                argVarList
          val newContext = UIAC.extendContextWithVarIDEnv(context, varIDEnv)
          val tfpexp = tpexpToTfpexp newContext tpexp
        in 
          TFPFNM {argVarList = varIdInfoList,
                  bodyTy=ty1,
                  bodyExp=tfpexp,
                  loc=loc}
        end
      | TPPOLYFNM {btvEnv=btvKind, 
                   argVarList,
                   bodyTy,
                   bodyExp=tpexp,
                   loc=loc} =>
        let
          val (varIdInfoList, varIDEnv) = 
              foldl (fn ({namePath, ty}, (varIdInfoList, varIDEnv)) => 
                        let
                          val id = Counters.newLocalID()
                          val displayName = NM.usrNamePathToString namePath
                        in
                          (varIdInfoList @ [{displayName = displayName, 
                                             ty = ty,
                                             varId = T.INTERNAL id}],
                           NPEnv.insert(varIDEnv, 
                                        namePath,
                                        (VIC.Internal (id, ty))
                                       )
                          )
                        end)
                    (nil, NPEnv.empty)
                    argVarList
          val newContext = UIAC.extendContextWithVarIDEnv(context, varIDEnv)
          val tfpexp = tpexpToTfpexp newContext tpexp
        in 
          TFPPOLYFNM{btvEnv=btvKind, 
                     argVarList = varIdInfoList,
                     bodyTy=bodyTy,
                     bodyExp=tfpexp,
                     loc=loc}
        end
      | TPPOLY {btvEnv=btvKind, expTyWithoutTAbs=ty, exp=tpexp,loc=loc} =>
        let
          val tfpexp = tpexpToTfpexp context tpexp
        in 
          TFPPOLY {btvEnv=btvKind, expTyWithoutTAbs=ty, exp=tfpexp, loc=loc}
        end
      | TPTAPP {exp=tpexp, expTy=ty, instTyList= tys, loc=loc} => 
        let
          val tfpexp = tpexpToTfpexp context tpexp
        in 
          TFPTAPP {exp=tfpexp, expTy=ty, instTyList=tys, loc=loc}
        end
      | TPSEQ {expList=tpexps, expTyList=tys, loc=loc} =>
        let
          val tfpexps = 
              map (fn tpexp => tpexpToTfpexp context tpexp) tpexps
        in 
          TFPSEQ {expList = tfpexps, expTyList= tys, loc=loc}
        end
      | TPLIST {expList=tpexps, listTy, loc} =>
        let
          val tfpexps = 
              map (fn tpexp => tpexpToTfpexp context tpexp) tpexps
        in 
          TFPLIST {expList = tfpexps, listTy=listTy, loc=loc}
        end
      | TPCAST (tpexp, ty, loc)  => TFPCAST(tpexpToTfpexp context tpexp,ty,loc)
      | TPERROR => raise Control.Bug "TPERROR passed to module compiler"
                         
  and tpdecToTfpdecs (context:UIAC.context) tpdec =
      case tpdec of
        TPVAL (decs,loc) => 
        let 
          fun compiledecs context nil = 
              (VIC.emptyVarIDEnv, nil)
            | compiledecs context (dec as (valId,tpexp)::rem) = 
              let
                val (varIDEnv1,newValId) = 
                    case valId of
                      T.VALIDVAR {namePath,ty} => 
                      let
                        val id = Counters.newLocalID()
                        val name = NM.usrNamePathToString namePath
                        val newVar = 
                            VALIDENT
                              {
                               displayName = name,
                               ty = ty,
                               varId = T.INTERNAL id}
                      in
                        (
                         NPEnv.singleton (namePath, 
                                          (VIC.Internal (id, ty))),
                         newVar
                        )
                      end
                    | T.VALIDWILD ty => (VIC.emptyVarIDEnv, VALIDENTWILD ty)
                val newtfpexp = tpexpToTfpexp context tpexp
                val dec1 = (newValId,newtfpexp)
                val (varIDEnv2, decs2) = compiledecs context rem 
              in
                (
                 VIC.mergeVarIDEnv
                   {
                    newVarIDEnv = varIDEnv2, 
                    oldVarIDEnv = varIDEnv1
                   }, 
                 dec1 :: decs2
                )
              end
          val (varIDEnv1, decs) = compiledecs context  decs
        in 
          (varIDEnv1, [TFPVAL(decs,loc)]) 
        end
      | TPVALREC (decs,loc) =>
        let 
          val (recVarIDEnv, exportVarIDEnv, exportReplicationDecs) = 
              foldr
                (fn ({var={namePath,ty},...},
                     (recVarIDEnv, exportVarIDEnv, exportDecs)) => 
                    let
                      val name = NM.usrNamePathToString namePath
                      val internalVarID = Counters.newLocalID()
                      val exportVarID = Counters.newLocalID()
                      val replicationDec = 
                          TFPVAL ([(T.VALIDENT
                                      ({displayName = name,
                                        ty = ty,
                                        varId = T.INTERNAL exportVarID}
                                      ),
                                    TFPVAR
                                      ({displayName = name,
                                        ty = ty,
                                        varId = T.INTERNAL internalVarID}, 
                                       loc)
                                  )],
                                  loc)
                    in
                      (NPEnv.insert(recVarIDEnv,
                                    namePath, 
                                    (VIC.Internal (internalVarID, ty))
                                   ),
                       NPEnv.insert(exportVarIDEnv,
                                    namePath, 
                                    (VIC.Internal (exportVarID, ty))
                                   ),
                       exportDecs @ [replicationDec]
                      )
                    end
                )
                (VIC.emptyVarIDEnv, VIC.emptyVarIDEnv, nil)
                decs
          fun compiledecs context nil = nil
            | compiledecs context (dec::rem) = 
              let
                val {var=var as {namePath,ty}, expTy=ty',exp=tpexp} = dec
                val name = NM.usrNamePathToString namePath
                val curItem = 
                    case VIC.lookupVarInVarIDBasis
                           (#varIDBasis context, namePath) of
                      NONE => raise Control.Bug ("undefined variable:"^ name)
                    | SOME item => item
                val newtfpexp = tpexpToTfpexp context tpexp
                val newdec =
                    (
                     { 
                      displayName = name,
                      ty = ty,
                      varId = T.INTERNAL (VIC.getIdFromInternal curItem)
                     },
                     ty',
                     newtfpexp
                    )
                val newdecs = compiledecs context rem
              in
                newdec::newdecs
              end
          val newContext = UIAC.extendContextWithVarIDEnv(context, recVarIDEnv)
          val decs = compiledecs newContext decs
        in 
          (
           exportVarIDEnv,
           [TFPLOCALDEC ([TFPVALREC (decs,loc)],
                         exportReplicationDecs,
                         loc)]
          )
        end
      | TPVALPOLYREC (btvEnv,decs,loc) =>
        let 
          val (recVarIDEnv, exportVarIDEnv, exportReplicationDecs) = 
              foldr
                (fn ({var={namePath,ty},...},
                     (recVarIDEnv, exportVarIDEnv, exportDecs)) => 
                    let
                      val name = NM.usrNamePathToString namePath
                      val internalVarID = Counters.newLocalID()
                      val exportVarID = Counters.newLocalID()
                      val replicationDec = 
                          TFPVAL ([(T.VALIDENT
                                      ({displayName = name,
                                        ty = ty,
                                        varId = T.INTERNAL exportVarID}
                                      ),
                                    TFPVAR
                                      ({displayName = name,
                                        ty = ty,
                                        varId = T.INTERNAL internalVarID}, 
                                       loc)
                                  )],
                                  loc)
                    in
                      (NPEnv.insert(recVarIDEnv,
                                    namePath, 
                                    (VIC.Internal (internalVarID, ty))
                                   ),
                       NPEnv.insert(exportVarIDEnv,
                                    namePath, 
                                    (VIC.Internal (exportVarID, ty))
                                   ),
                       exportDecs @ [replicationDec]
                      )
                    end
                )
                (VIC.emptyVarIDEnv, VIC.emptyVarIDEnv, nil)
                decs
          fun compiledecs context nil = nil
            | compiledecs context (dec::rem) = 
              let
                val {var=var as {namePath,ty}, expTy = ty', exp = tpexp} = dec
                val name = NM.usrNamePathToString namePath
                val curItem = 
                    case VIC.lookupVarInVarIDBasis
                           (#varIDBasis context, namePath) of
                      NONE => raise Control.Bug ("undefined variable:"^ name)
                    | SOME item => item
                val newtfpexp = tpexpToTfpexp context tpexp
                val newdec =
                    (
                     {
                      displayName = name,
                      ty = ty,
                      varId = T.INTERNAL (VIC.getIdFromInternal curItem)
                     },
                     ty',
                     newtfpexp
                    )
                val newdecs = compiledecs context rem
              in
                newdec::newdecs
              end
          val newContext = UIAC.extendContextWithVarIDEnv(context, recVarIDEnv)
          val localDecs = compiledecs newContext decs
        in 
          (exportVarIDEnv,
           [TFPLOCALDEC ([TFPVALPOLYREC (btvEnv,localDecs,loc)],
                         exportReplicationDecs,
                         loc)]
          )
        end
      | TPVALRECGROUP (_, decs, loc) => tpdecsToTfpdecs context decs
      | TPLOCALDEC (localDecs, decs, loc) => 
        let
          val (varIDEnv1, tfplocalDecs) = tpdecsToTfpdecs context localDecs
          val newContext = UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
          val (varIDEnv2, tfpdecs) = tpdecsToTfpdecs newContext decs
        in 
          (varIDEnv2,
           [TFPLOCALDEC(tfplocalDecs, tfpdecs, loc)]) 
        end
      | TPINTRO ((_, varNamePathEnv), _, strName, loc) =>
        let
          val newVarIDEnv = 
              NM.NPEnv.foldli
                (fn (namePath, idstate, newVarIDEnv) =>
                    case idstate of
                      NM.VARID actualNamePath =>
                      (case VIC.lookupVar (#topVarExternalVarIDBasis context, 
                                           #varIDBasis context, 
                                           actualNamePath) of
                         NONE =>
                         raise
                           Control.BugWithLoc
                             ("unbound variable:"^
                              NM.namePathToString(actualNamePath),
                              loc)
                       | SOME item =>
                         NPEnv.insert(newVarIDEnv, 
                                      namePath,
                                      item)
                      )
                    | NM.CONID _ => newVarIDEnv
                    | NM.EXNID _ => newVarIDEnv)
                NPEnv.empty
                varNamePathEnv
        in
          (newVarIDEnv, nil)
        end
      | TPDATADEC (tyCons,loc) => (VIC.emptyVarIDEnv,nil)
      | TPABSDEC ({decls,...}, loc) => 
        tpdecsToTfpdecs context decls
      | TPTYPE args => (VIC.emptyVarIDEnv,nil)
      | TPDATAREPDEC _ => (VIC.emptyVarIDEnv,nil)
      | TPEXNDEC (exnBinds,loc) => 
        let
          val exnInfos =
              foldr
                (fn (exnBind, newExnInfos) =>
                    case exnBind of
                      TPEXNBINDDEF {namePath, funtyCon, ty, tag, tyCon} => 
                      {displayName = NM.usrNamePathToString namePath, 
                       funtyCon = funtyCon, 
                       ty = ty, 
                       tag = tag, 
                       tyCon = tyCon} :: newExnInfos
                    | TPEXNBINDREP _ => newExnInfos)
                nil
                exnBinds
        in
          (VIC.emptyVarIDEnv, [TFPEXNBINDDEF exnInfos])
        end
      | TPINFIXDEC args =>  (VIC.emptyVarIDEnv,nil)
      | TPINFIXRDEC args => (VIC.emptyVarIDEnv,nil)
      | TPNONFIXDEC args => (VIC.emptyVarIDEnv,nil)
      | TPFUNDECL (fundecl,_) =>
        (map
           (fn {funVar = {namePath,...},...} =>
               (print (NM.namePathToString namePath); print "\n"))
           fundecl;
         raise Control.Bug "TPFUNDECL in module compiler"
        )
      | TPPOLYFUNDECL (_, fundecl ,_) =>
        (map
           (fn {funVar = {namePath,...},...} =>
               (print (NM.namePathToString namePath); print "\n"))
           fundecl;
         raise Control.Bug "TPPOLYFUNDECL in module compiler"
        )
      | TPREPLICATETYPE _ => (NPEnv.empty, nil)
                             
  and tpdecsToTfpdecs context nil = (NPEnv.empty, nil)
    | tpdecsToTfpdecs context (tpdec::tpdecs) 
      = 
      let
        val (varIDEnv1,tfpdecs1) = tpdecToTfpdecs context tpdec
        val newContext = UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
        val (varIDEnv2, tfpdecs2) = tpdecsToTfpdecs newContext tpdecs
      in
        (
         VIC.mergeVarIDEnv {
         newVarIDEnv = varIDEnv2,
         oldVarIDEnv = varIDEnv1
         },
         tfpdecs1 @ tfpdecs2
        )
      end
end
end
