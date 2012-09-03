(**
 * @copyright (c) 2010 Tohoku University.
 * @author Atsushi Ohori
 *)
structure OverloadCompilation : 
sig
 val compile : 
     VarIDContext.topExternalVarIDBasis
     -> RecordCalc.topBlock list
     -> RecordCalc.topBlock list
end =
struct
 structure RC = RecordCalc
 structure T = Types
 structure TU = TypesUtils

  fun newLocalId () = VarID.generate ()
  fun newVar ty =
      let
        val id = newLocalId ()
      in
        {
         displayName = "$" ^ VarID.toString id,
         ty = ty,
         varId = Types.INTERNAL id
        }
       end
  fun newVarWithName (ty,name) =
      let
        val id = newLocalId ()
      in
        {
         displayName = name,
         ty = ty,
         varId = Types.INTERNAL id
        }
       end

 structure VarIdOrd =
   struct 
   type ord_key = T.varId
   fun compare (varId1,varId2) = 
       case (varId1,varId2) of
         (T.EXTERNAL eid1, T.EXTERNAL eid2) => 
         ExternalVarID.compare(eid1,eid2)
       | (T.EXTERNAL _, T.INTERNAL _) => LESS
       | (T.INTERNAL _, T.EXTERNAL _) => GREATER
       | (T.INTERNAL iid1, T.INTERNAL iid2) => 
         VarID.compare(iid1,iid2)
   end
 structure VarIdEnv = BinaryMapMaker(VarIdOrd)

 structure BtvListOPrimOrd =
   struct 
   type ord_key = int list * OPrimID.id
   fun compare ((btvIdList1, oprimId1), (btvIdList2, oprimId2)) =
       case (btvIdList1, btvIdList2) of
         (nil,nil) => OPrimID.compare(oprimId1,oprimId2) 
       | (nil, _::_) => LESS
       | (_::_, nil) => GREATER
       | (h1::tail1,h2::tail2) => 
         (case Int.compare (h1, h2) of
            EQUAL => compare ((tail1,oprimId1),(tail2,oprimId2))
          | x => x)
   end
 structure BtvListOPrimEnv = BinaryMapMaker(BtvListOPrimOrd)

 type env = {oprimEnv: T.varIdInfo BtvListOPrimEnv.map,
             varIdEnv : T.varId VarIdEnv.map,
             externalVarIdEnv : VarIDContext.topExternalVarIDBasis}

 fun printRcexp rcexp =
     (
      print (RecordCalcFormatter.rcexpToString nil rcexp);
      print "\n"
     )
 fun printTopBlock topBlock =
     (
      print (RecordCalcFormatter.topGroupToString topBlock);
      print "\n"
     )
 fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

 fun bug s = Control.Bug ("OverloadCompilation:" ^ s)

 exception GetOprimInst
 fun getOprimInst (oprimId, tyconIdList) =
     let
       val instMap = BuiltinContext.getOPrimInstMap oprimId
     in
       case OPrimInstance.Map.find(instMap, tyconIdList) of
         SOME oprimInstInfo => oprimInstInfo
       | NONE => raise GetOprimInst
     end
 
 exception GetOprimInstVar
 fun getOprimInstVar ({oprimEnv, ...}:env) key =
     case BtvListOPrimEnv.find(oprimEnv, key) of
       SOME varIdInfo => varIdInfo
     | NONE => raise GetOprimInstVar

 fun getExternalVar ({externalVarIdEnv, ...}:env) varName ty =
     case VarIDContext.lookupVarInTopVarExternalVarIDBasis
            (externalVarIdEnv, varName) of
       SOME (VarIDContext.External id) =>
       RC.RCVAR ({displayName = varName, ty = ty, varId = T.EXTERNAL id},
                 Loc.noloc)
     | SOME (VarIDContext.Internal (id, _)) =>
       raise bug "getExternalVar: Internal"
     | SOME VarIDContext.Dummy =>
       let
         val _ = TextIO.output
                   (TextIO.stdErr,
                    "OverloadCompile: found a reference to DUMMY global \
                    \name `" ^ varName ^ "'; program won't work\n")
         val e = PredefinedTypes.BootstrapExnPathInfo
         val exnInfo = 
             {displayName = NameMap.usrNamePathToString (#namePath e),
              funtyCon = #funtyCon e, ty = #ty e, tag = #tag e,
              tyCon = #tyCon e}
       in
         RC.RCRAISE (RC.RCEXNCONSTRUCT {exn = exnInfo, instTyList = nil,
                                        argExpOpt = NONE, loc = Loc.noloc},
                     ty, Loc.noloc)
       end
     | NONE =>
       raise bug ("getExternalVar: undefined extenral variable: " ^ varName)

 (*
  * OPRIMkind of {instances : ty list, operators : operator list}
  * type operator =
        {
         oprimId : OPrimID.id,
         name : string,
         oprimPolyTy ; ty,
         keyTyList : ty list,
         instTyList : ty list
        }
  *)
 fun generateOPrimEnv btvEnv =
     let
       val (btvList, operatorList) =
           foldr
             (fn ((btv,{recordKind,...}:T.btvKind),
                  (btvList, operatorList)) =>
                 case recordKind of 
                   T.OPRIMkind {operators,...} =>
                   (btv::btvList, operators @ operatorList)
                 | _ =>(btvList, operatorList)
             )
             (nil,nil)
             (IEnv.listItemsi btvEnv)
       fun extractKeyOperatorList
             (operator as {oprimId, keyTyList, ...} : T.operator)
         =
           let
             fun checkBtv btv =
                 if List.exists (fn btv' => btv = btv') btvList
                 then btv
                 else raise bug "non local btv"
             fun extractBtvSeq nil = nil
               | extractBtvSeq (ty::tyList) = 
                 case TU.derefTy ty of
                   T.RAWty _ => extractBtvSeq tyList
                 | T.BOUNDVARty btv  =>
                   checkBtv btv :: extractBtvSeq tyList
                 | _ => raise bug "illeagal ty in extractBtvSeq"
             val keyBtvList =
                 case extractBtvSeq keyTyList of
                   nil => raise bug "empty key"
                 | L => L
           in
             ((keyBtvList, oprimId),operator)
           end
       val keyOperatorList =
           foldr
           (fn (operator, candidateKeyList) =>
               extractKeyOperatorList operator :: candidateKeyList)
           nil
           operatorList
       fun gt (((L1,id1),_),((L2,id2),_)) =
           let
             val l1 = List.length L1
             val l2 = List.length L2
             fun comp (nil,nil) = EQUAL
               | comp (_,nil) = GREATER
               | comp (nil,_) = LESS
               | comp (h1::t1,h2::t2) =
                 case Int.compare(h1,h2) of
                   EQUAL => comp(t1,t2)
                 | x => x
           in
             l1 > l2 orelse
             l1 = l2 andalso 
             (case comp (L1,L2) of 
                EQUAL => (case OPrimID.compare(id1,id2) of
                           GREATER => true
                         | _ => false)
              | GREATER => true
              | LESS => false)
           end
       val sortedKeyOperatorList = ListMergeSort.sort gt keyOperatorList
       fun unique nil = nil
         | unique (L::LL) = 
           let
             fun superKey ((keyList1,oprimid1),_) ((keyList2,oprimid2),_) = 
                 (* superKey k1 k2 = k2 is a superkey of k1 *)
                 let
                   fun checkEq nil nil = true
                     | checkEq (h1::t1) (h2::t2) =
                       (h1:int) = h2 andalso checkEq t1 t2
                     | checkEq _ _ = raise bug "impossible"
                   val l1 = List.length keyList1
                   val l2 = List.length keyList2
                 in
                   if l1 > l2 orelse not(OPrimID.eq (oprimid1,oprimid2)) then
                     false 
                   else checkEq keyList1 (List.drop(keyList2,l2 - l1))
                 end
           in
             if List.exists (superKey L) LL then unique LL
             else L::unique LL
           end
       val uniqueKeyOperatorList = unique sortedKeyOperatorList
     in
       foldl
       (fn ((key, operator), oprimEnv) =>
           let
             val newInstVar = newVar (T.INSTCODEty operator)
           in
             BtvListOPrimEnv.insert(oprimEnv, key, newInstVar)
           end
       )
       BtvListOPrimEnv.empty
       uniqueKeyOperatorList
     end

 fun generateExtraTyList btvEnv =
     map
       (fn {ty, ...} => ty)
       (BtvListOPrimEnv.listItems (generateOPrimEnv btvEnv))

 fun compileTyList tyList = map compileTy tyList
 and compileTy ty =
     case ty of
      T.INSTCODEty _ => ty
    | T.ERRORty => ty
    | T.DUMMYty _ => ty
    | T.TYVARty _ => ty
    | T.BOUNDVARty _ => ty
    | T.FUNMty (tyList, ty)  => T.FUNMty (tyList, compileTy ty) 
    | T.RECORDty tySEnvmap => T.RECORDty (SEnv.map compileTy tySEnvmap)
    | T.RAWty _ => ty
    | T.POLYty {boundtvars, body}
      =>
      let
        val extraTyList = generateExtraTyList boundtvars
      in
        case extraTyList of
          nil =>
          T.POLYty {boundtvars = boundtvars,body = compileTy body}
        | _ => 
          T.POLYty {boundtvars = boundtvars,
                    body = T.FUNMty (extraTyList, compileTy body)}
      end
    | T.ALIASty (ty1, ty2) => T.ALIASty (compileTy ty1, compileTy ty2) 
    | T.OPAQUEty {spec, implTy = ty}
      => T.OPAQUEty {spec = spec, implTy = compileTy ty}
    | T.SPECty {tyCon, args = tyList}
      =>
      T.SPECty {tyCon = tyCon, args = compileTyList tyList}

 fun compileVarIdInfo ({varIdEnv,...}:env) {displayName, ty, varId} =
     {
      displayName =displayName,
      ty = compileTy ty,
      varId = 
        case VarIdEnv.find(varIdEnv, varId) of
          NONE => varId
        | SOME varId => varId
     }

 datatype instTerm
   = OPRIMINSTINFO of OPrimInstance.oprimInstInfo
   | FUNVAR of T.varIdInfo
 datatype oprimInstance = datatype OPrimInstance.instance
                                 
 fun findInstTerm env (keyTyList,oprimId) = 
     let
       fun findBtvList nil = nil
         | findBtvList (ty::tyList) =
           case TU.derefTy ty of 
             T.BOUNDVARty btvId =>
             btvId :: findBtvList tyList
           | T.RAWty _ => findBtvList tyList
           | _ => raise bug "illeagal instance for oprim"
       val btvKeyList = findBtvList keyTyList
     in
       case btvKeyList of
         nil => 
         let
           val tyConIdList = 
               map 
                 (fn ty => case TU.derefTy ty of
                             T.RAWty{tyCon,...} => #id tyCon
                           | _ => raise bug "illeagal instance for oprim")
                 keyTyList
         in
           OPRIMINSTINFO (getOprimInst (oprimId, tyConIdList))
         end
       | _ =>
           FUNVAR (getOprimInstVar env (btvKeyList, oprimId))
     end

 fun compileValIdent env valIdent =
     case valIdent of
     T.VALIDENT varIdInfo => T.VALIDENT (compileVarIdInfo env varIdInfo)
   | T.VALIDENTWILD ty => T.VALIDENTWILD (compileTy ty)

 fun compileRcexpList env rcexpList = map (compileRcexp env) rcexpList
 and compileRcexpOption env rcexpOption =
     Option.map (compileRcexp env) rcexpOption
 and compileFields env fields = SEnv.map (compileRcexp env) fields
 and compileRcexp (env as {oprimEnv, varIdEnv, externalVarIdEnv}) rcexp =
     case rcexp of 
       RC.RCFOREIGNAPPLY
         {
          funExp = rcexp, 
          funTy = ty,
	  instTyList = tyList1,
	  argExpList = rcexpList, 
	  argTyList = tyList2, 
          attributes = ffiAttributes,
	  loc = loc
         }
       =>
       RC.RCFOREIGNAPPLY
         {
          funExp = compileRcexp env rcexp,
          funTy = compileTy ty,
	  instTyList = tyList1,
	  argExpList = compileRcexpList env rcexpList,
	  argTyList = tyList2,
          attributes = ffiAttributes,
	  loc = loc
         }
     | RC.RCEXPORTCALLBACK 
         {
          funExp = rcexp,
	  argTyList = tyList,
	  resultTy = ty,
          attributes = ffiAttributes,
          loc = loc
         }
       =>
       RC.RCEXPORTCALLBACK 
         {
          funExp = compileRcexp env rcexp,
	  argTyList = tyList,
	  resultTy = compileTy ty,
          attributes = ffiAttributes,
          loc = loc
         }
     | RC.RCSIZEOF (ty,loc)
       =>
       RC.RCSIZEOF (compileTy ty,loc)
     | RC.RCCONSTANT (constant, loc)
       =>
       RC.RCCONSTANT (constant, loc)
     | RC.RCGLOBALSYMBOL (string, globalSymbolKind, ty, loc)
       =>
       RC.RCGLOBALSYMBOL (string, globalSymbolKind, compileTy ty, loc)
     | RC.RCVAR (varIdInfo, loc)
       =>
       RC.RCVAR (compileVarIdInfo env varIdInfo, loc)
     | RC.RCGETFIELD (rcexp, int, ty, loc)
       =>
       RC.RCGETFIELD (compileRcexp env rcexp, int, ty, loc)
     | RC.RCARRAY 
         {
          sizeExp = rcexp1,
          initExp = rcexp2,
          elementTy = ty1,
          resultTy = ty2,
          loc = loc
         }
       =>
       RC.RCARRAY 
         {
          sizeExp = compileRcexp env rcexp1,
          initExp = compileRcexp env rcexp2,
          elementTy = ty1,
          resultTy = ty2,
          loc = loc
         }
     | RC.RCPRIMAPPLY
         {
          primOp = primInfo,
          instTyList = tyList,
          argExpOpt= rcexpOption,
          loc = loc
         }
       =>
       RC.RCPRIMAPPLY
         {
          primOp = primInfo,
          instTyList = tyList,
          argExpOpt= compileRcexpOption env rcexpOption,
          loc = loc
         }
     | RC.RCOPRIMAPPLY
         {
          oprimOp = {name, oprimPolyTy, oprimId},
          instances = instTyList,
          keyTyList = keyTyList,
          argExpOpt = rcexpOption,
          loc = loc
         }
       =>
       let
         val oprimInstTy = TU.tpappTy(oprimPolyTy, instTyList)
         val argRcexp =
             case rcexpOption of
               SOME rcexp => compileRcexp env rcexp
             | NONE =>
               raise bug "no arg to oprim op"
         val instTerm = findInstTerm env (keyTyList,oprimId)
           handle GetOprimInst =>
                  (print "oprim inst not defined for the instance type:\n";
                   map printType keyTyList;
                   print "\n";
                   print "in the expression: ";
                   printRcexp rcexp;
                   print "\n";
                   raise bug "oprim inst not defined"
                  )
                | GetOprimInstVar =>
                  (print "oprim variable not found for:";
                   print ("operator:" ^ name ^ "\n");
                   print "instace type:";
                   map printType keyTyList;
                   print "\n";
                   print "in the expression: ";
                   printRcexp rcexp;
                   print "\n";
                   raise bug "oprint inst var not found"
                  )

       in
         case instTerm of
           FUNVAR varIdInfo =>
           let
             val primCode =
                 RC.RCCAST (RC.RCVAR (varIdInfo,loc), oprimInstTy, loc)
           in
             RC.RCAPPM
               {
                funExp = primCode,
                funTy = oprimInstTy,
                argExpList = [argRcexp],
                loc = loc
               }
           end
         | OPRIMINSTINFO {name, instance = PRIMAPPLY prim_or_special} => 
             RC.RCPRIMAPPLY
               {
                primOp = {prim_or_special = prim_or_special,
                          ty = oprimInstTy},
                instTyList = nil,
                argExpOpt = SOME argRcexp,
                loc = loc
               }
         | OPRIMINSTINFO {name, instance = EXTERNVAR varName} =>
           RC.RCAPPM
             {funExp = getExternalVar env varName oprimInstTy,
              funTy = oprimInstTy,
              argExpList = [argRcexp],
              loc = loc}
       end
     | RC.RCDATACONSTRUCT
         {
          con = conInfo, 
          instTyList = tyList,
          argExpOpt = rcexpOption,
          loc = loc
         }
       =>
       RC.RCDATACONSTRUCT
         {
          con = conInfo, 
          instTyList = tyList,
          argExpOpt = compileRcexpOption env rcexpOption,
          loc = loc
         }
     | RC.RCEXNCONSTRUCT 
         {
          exn = exnInfo,
          instTyList = tyList,
          argExpOpt = rcexpOption,
          loc = loc
         }
       =>
       RC.RCEXNCONSTRUCT 
         {
          exn = exnInfo,
          instTyList = tyList,
          argExpOpt = compileRcexpOption env rcexpOption,
          loc = loc
         }
     | RC.RCAPPM
         {
          funExp = rcexp,
          funTy = ty,
          argExpList = rcexpList,
          loc = loc
         }
       =>
       RC.RCAPPM
         {
          funExp = compileRcexp env rcexp,
          funTy = compileTy ty,
          argExpList = compileRcexpList env rcexpList,
          loc = loc
         }
     | RC.RCMONOLET 
         {
          binds  = varIdInfoRcexpList,
          bodyExp = rcexp, 
          loc = loc
         }
       =>
       RC.RCMONOLET 
         {
          binds  =
            map (fn (varIdInfo, rcexp) =>
                    (compileVarIdInfo env varIdInfo,
                     compileRcexp env rcexp))
                varIdInfoRcexpList,
          bodyExp = compileRcexp env rcexp, 
          loc = loc
         }
     | RC.RCLET (rcdeclList, rcexpList, tyList, loc)
       =>
       RC.RCLET
         (
          compileRcdeclList env rcdeclList,
          compileRcexpList env rcexpList,
          compileTyList tyList,
          loc
         )
     | RC.RCRECORD
         {
          fields = fields,
          recordTy = ty,
          loc = loc
         }
       =>
       RC.RCRECORD
         {
          fields = compileFields env fields,
          recordTy = compileTy ty,
          loc = loc
         }
     | RC.RCSELECT
         {
          label = string,
          exp = rcexp,
          expTy = ty1,
          resultTy = ty2,
          loc = loc
         }
       =>
       RC.RCSELECT
         {
          label = string,
          exp = compileRcexp env rcexp,
          expTy = compileTy ty1,
          resultTy = compileTy ty2,
          loc = loc
         }
     | RC.RCMODIFY 
         {
          label = string, 
          recordExp = rcexp1, 
          recordTy = ty1,
          elementExp = rcexp2, 
          elementTy = ty2,
          loc = loc
         }
       =>
       RC.RCMODIFY 
         {
          label = string, 
          recordExp = compileRcexp env rcexp1, 
          recordTy = compileTy ty1,
          elementExp = compileRcexp env rcexp2, 
          elementTy = compileTy ty2,
          loc = loc
         }
     | RC.RCRAISE (rcexp, ty, loc)
       =>
       RC.RCRAISE (compileRcexp env rcexp, compileTy ty, loc)
     | RC.RCHANDLE
         {
          exp = rcexp1,
          exnVar = varIdInfo,
          handler = rcexp2,
          loc = loc
         }
       =>
       RC.RCHANDLE
         {
          exp = compileRcexp env rcexp1,
          exnVar = varIdInfo,
          handler = compileRcexp env rcexp2,
          loc = loc
         }
     | RC.RCCASE 
         {
          exp = rcexp1,
          expTy = ty,
          ruleList = conInfoVarIdInfoOptionRcexpList,
          defaultExp = rcexp2,
          loc = loc
         }
       =>
       RC.RCCASE 
         {
          exp = compileRcexp env rcexp1,
          expTy = ty,
          ruleList = 
            map
              (fn (conInfo, varIdInfoOption, recexp) =>
                  (conInfo, varIdInfoOption, compileRcexp env recexp))
              conInfoVarIdInfoOptionRcexpList,
          defaultExp = compileRcexp env rcexp2,
          loc = loc
         }
     | RC.RCEXNCASE 
         {
          exp = rcexp1,
          expTy = ty,
          ruleList = exnInfoVarIdInfoOptionRcexpList,
          defaultExp = rcexp2,
          loc = loc
         }
       =>
       RC.RCEXNCASE 
         {
          exp = compileRcexp env rcexp1,
          expTy = ty,
          ruleList =
            map
              (fn (exnInfo, varIdInfoOption, recexp) =>
                  (exnInfo, varIdInfoOption, compileRcexp env recexp))
              exnInfoVarIdInfoOptionRcexpList,
          defaultExp = compileRcexp env rcexp2,
          loc = loc
         }
     | RC.RCSWITCH
         {
          switchExp = rcexp1, 
          expTy = ty, 
          branches = constantRcexpList,
          defaultExp = rcexp2, 
          loc = loc
         }
       =>
       RC.RCSWITCH
         {
          switchExp = compileRcexp env rcexp1, 
          expTy = ty, 
          branches =
            map (fn (c,exp) => (c, compileRcexp env exp)) constantRcexpList,
          defaultExp = compileRcexp env rcexp2, 
          loc = loc
         }
     | RC.RCFNM
         {
          argVarList = varIdInfoList,
          bodyTy = ty,
          bodyExp = rcexp,
          loc = loc
         }
       =>
       RC.RCFNM
         {
          argVarList = varIdInfoList,
          bodyTy = compileTy ty,
          bodyExp = compileRcexp env rcexp,
          loc = loc
         }
     | RC.RCPOLYFNM 
         {
          btvEnv = btvKindIEnvMap,
          argVarList = varIdInfoList,
          bodyTy,
          bodyExp,
          loc = loc
         }
       =>
       let
         val additionalOprimEnv = generateOPrimEnv btvKindIEnvMap
         val newOprimEnv =
             BtvListOPrimEnv.unionWith #1 (additionalOprimEnv, oprimEnv)
         val bodyExp =
             compileRcexp {varIdEnv=varIdEnv, oprimEnv=newOprimEnv,
                           externalVarIdEnv=externalVarIdEnv}
                          bodyExp
         val extraVarIdInfoList = BtvListOPrimEnv.listItems additionalOprimEnv
         val bodyTy = compileTy bodyTy
       in
         case extraVarIdInfoList of
           nil =>
           RC.RCPOLYFNM
             {
              btvEnv = btvKindIEnvMap,
              argVarList = varIdInfoList,
              bodyTy = bodyTy,
              bodyExp = bodyExp,
              loc = loc
             }
         | _ =>
           RC.RCPOLYFNM 
             {
              btvEnv = btvKindIEnvMap,
              argVarList = extraVarIdInfoList,
              bodyTy = T.FUNMty(map #ty varIdInfoList,bodyTy),
              bodyExp = RC.RCFNM
                          {
                           argVarList = varIdInfoList,
                           bodyTy = bodyTy,
                           bodyExp = bodyExp,
                           loc = loc
                          },
              loc = loc
             }
       end
     | RC.RCPOLY
         {
          btvEnv = btvKindIEnvMap,
          expTyWithoutTAbs,
          exp, 
          loc = loc
         }
       =>
       let
         val additionalOprimEnv = generateOPrimEnv btvKindIEnvMap
         val newOprimEnv =
             BtvListOPrimEnv.unionWith #1 (additionalOprimEnv, oprimEnv)
         val newExp =
             compileRcexp {varIdEnv=varIdEnv, oprimEnv=newOprimEnv,
                           externalVarIdEnv=externalVarIdEnv} exp
         val extraVarIdInfoList = BtvListOPrimEnv.listItems additionalOprimEnv
         val expTyWithoutTAbs = compileTy expTyWithoutTAbs
       in
         case extraVarIdInfoList of
           nil =>
           RC.RCPOLY
             {
              btvEnv = btvKindIEnvMap,
              expTyWithoutTAbs = expTyWithoutTAbs,
              exp = newExp,
              loc = loc
             }
         | _ =>
           RC.RCPOLYFNM 
             {
              btvEnv = btvKindIEnvMap,
              argVarList = extraVarIdInfoList,
              bodyTy = expTyWithoutTAbs,
              bodyExp = newExp,
              loc = loc
             }
       end
     | RC.RCTAPP
         {
          exp = rcexp,
          expTy = polyTy,
          instTyList = argTyList,
          loc = loc
         }
       =>
       let
         val rcexp = compileRcexp env rcexp
         val polyTy = compileTy polyTy
         val instTy = TU.tpappTy(polyTy, argTyList)
       in
         case TU.derefTy instTy of
           T.FUNMty(domTyList as T.INSTCODEty _ :: _, bodyTy) =>
           let
             val _ =
                 map (fn ty =>
                         case TU.derefTy ty of
                           T.INSTCODEty _ => ()
                         | _ => raise bug "mixed others with INSTCODEty")
                     domTyList
             fun makeArgRcexp
                 (extraArgTy
                    as
                    (T.INSTCODEty
                       {oprimId,
                        oprimPolyTy,
                        keyTyList,
                        instTyList,
                        name}
                    )
                 )
                 =
                 let
                   val instTerm = findInstTerm env (keyTyList,oprimId)
                       handle GetOprimInst =>
                              (print "oprim inst not defined\
                                     \ for the instance type:\n";
                               map printType keyTyList;
                               print "\n";
                               print "in the expression: ";
                               printRcexp rcexp;
                               print "\n";
                               raise bug "oprim inst not defined"
                              )
                            | GetOprimInstVar =>
                              (print "oprim variable not found for:";
                               print ("operator:" ^ name ^ "\n");
                               print "instace type:";
                               map printType keyTyList;
                               print "\n";
                               print "in the expression: ";
                               printRcexp rcexp;
                               print "\n";
                               raise bug "oprint inst var not found"
                              )

                 in
                   case instTerm of
                     FUNVAR varIdInfo => RC.RCVAR (varIdInfo,loc)
                   | OPRIMINSTINFO {name,
                                    instance = PRIMAPPLY prim_or_special} => 
                     let
                       val oprimInstTy = TU.tpappTy(oprimPolyTy, instTyList)
                       val (domTy,bodyTy) =
                           case TU.derefTy oprimInstTy of
                             T.FUNMty([domTy], bodyTy)=>(domTy, bodyTy)
                           | _ => raise bug "non funty of oprim inst ty"
                       val argVar = newVar domTy
                       val primInfo = {prim_or_special = prim_or_special,
                                       ty = oprimInstTy}
                       val bodyExp =
                           RC.RCPRIMAPPLY
                             {
                              primOp = primInfo,
                              instTyList = nil,
                              argExpOpt= SOME (RC.RCVAR (argVar, loc)),
                              loc = loc
                             }
                     in
                       RC.RCCAST
                         (
                          RC.RCFNM
                            {
                             argVarList = [argVar],
                             bodyTy = bodyTy,
                             bodyExp = bodyExp,
                             loc = loc
                            },
                          extraArgTy,
                          loc
                         )
                     end
                   | OPRIMINSTINFO {name, instance = EXTERNVAR varName} =>
                     let
                       val oprimInstTy = TU.tpappTy(oprimPolyTy, instTyList)
                       val varExp = getExternalVar env varName oprimInstTy
                     in
                       RC.RCCAST (varExp, extraArgTy, loc)
                     end
                 end
               | makeArgRcexp _ = raise bug "non OPRIMkind to makeArgRcexp"
             val argExpList = map makeArgRcexp domTyList 
           in
             RC.RCAPPM
               {
                funExp = RC.RCTAPP
                           {
                            exp = rcexp,
                            expTy = polyTy,
                            instTyList = argTyList,
                            loc = loc
                           },
                funTy = instTy,
                argExpList = argExpList,
                loc = loc
               }
           end
         | _ => (* the instantiated type is a usual function type *)
           RC.RCTAPP
             {
              exp = rcexp,
              expTy = polyTy,
              instTyList = argTyList,
              loc = loc
             }
       end
     | RC.RCSEQ 
         {
          expList = rcexpList,
          expTyList = tyList,
          loc = loc
         }
       =>
       RC.RCSEQ 
         {
          expList = compileRcexpList env rcexpList,
          expTyList = compileTyList tyList,
          loc = loc
         }
     | RC.RCLIST
         {
          expList = rcexpList,
          listTy = ty,
          loc =loc
         }
       =>
       RC.RCLIST
         {
          expList = compileRcexpList env rcexpList,
          listTy = ty,
          loc =loc
         }
     | RC.RCCAST (rcexp, ty, loc)
       =>
       RC.RCCAST (compileRcexp env rcexp, ty, loc)

 and compileRcdeclList env rcdeclList =
     map (compileRcdecl env) rcdeclList
 and compileRcdecl (env as {oprimEnv, varIdEnv, externalVarIdEnv}) rcdecl =
     case rcdecl of
       RC.RCVAL (valIdentRcexpList, loc)
       =>
       RC.RCVAL
         (map
            (fn (varIIdent, rcexp) =>
                (compileValIdent env varIIdent,
                 compileRcexp env rcexp))
            valIdentRcexpList,
          loc)
     | RC.RCVALREC (varExpTyExpRecordList, loc)
       =>
       RC.RCVALREC
         (
          map (fn {var, expTy, exp} =>
                  {var = compileVarIdInfo env var,
                   expTy = compileTy expTy,
                   exp = compileRcexp env exp}
              )
              varExpTyExpRecordList,
          loc)
     | RC.RCVALPOLYREC (originalBtvEnv, varExpTyExpRecordList, loc)
       =>
(*
  [a#K. val rec f1:ty1 = e1
          ...
        and rec fn:ty1 = en ]
 ==>
 local
  F:polyRecordFunTy =
   [a#.
     \A.... (extraVarIdInfoList)
        let
          val rec f1':ty1 = e1'
            ...
          val rec fn':ty1 = en'
        in
          (f1,...,fn) : funRecordTy
        end ]
  in
    f1:polyTy1 = [a#.\A.....(F A ... )[1]]
      ...
    fn:polyTyn = [a#.\A.....(F A ... )[n]]
  end
*)           
       let
         val originalFunVarList = map #var varExpTyExpRecordList
         val additionalOprimEnv = generateOPrimEnv originalBtvEnv
         val extraVarIdInfoList = BtvListOPrimEnv.listItems additionalOprimEnv
         val funRecordTy =
             let
               val originalFunTyList = map #ty originalFunVarList
               val tyField =
                   #2
                    (foldr
                       (fn (ty, (n,fields)) =>
                           (n-1, SEnv.insert(fields, Int.toString n, ty)))
                       (1, SEnv.empty)
                       originalFunTyList)
             in
               T.RECORDty tyField
             end
         val polyRecordFunTy =
             T.POLYty {boundtvars = originalBtvEnv,
                       body = T.FUNMty(map #ty extraVarIdInfoList,
                                       funRecordTy)}
         val polyRecordFunVarIdInfo = newVar polyRecordFunTy
         val funRecordBind =
             let
               val newFunVarList =
                   map
                     newVarWithName
                     (map (fn x => (#ty x,#displayName x)) originalFunVarList)
               val newVarIdEnv =
                   foldl
                     (fn ((varIdInfo1,varIdInfo2), newVarIdEnv) =>
                         VarIdEnv.insert(newVarIdEnv,
                                         #varId varIdInfo1,
                                         #varId varIdInfo2)
                     )
                     varIdEnv
                     (ListPair.zip (originalFunVarList, newFunVarList))
               val newOprimEnv =
                   BtvListOPrimEnv.unionWith
                     #1 (additionalOprimEnv, oprimEnv)
               val newEnv = {varIdEnv = newVarIdEnv,
                             oprimEnv=newOprimEnv,
                             externalVarIdEnv = externalVarIdEnv}
               val newVarExpTyExpRecordList =
                   map
                     (fn {var, expTy, exp} =>
                      {var = compileVarIdInfo newEnv var,
                       expTy = compileTy expTy,
                       exp = compileRcexp newEnv exp}
                     )
                     varExpTyExpRecordList
               val funRecordExp =
                   let
                     val (_, expFields, tyFields) =
                         foldl
                           (fn (var, (n,expFields, tyFields)) =>
                               (n + 1,
                                SEnv.insert(expFields,Int.toString n,
                                            RC.RCVAR (var, loc)),
                                SEnv.insert(tyFields, Int.toString n,
                                            #ty var)
                               )
                           )
                           (1, SEnv.empty, SEnv.empty) 
                           newFunVarList
                   in
                     RC.RCRECORD
                       {fields = expFields,
                        recordTy = T.RECORDty tyFields,
                        loc = loc
                        }
                   end
               val polyRecordFunExp =
                   RC.RCPOLYFNM
                     {
                      btvEnv = originalBtvEnv,
                      argVarList = extraVarIdInfoList,
                      bodyTy = funRecordTy,
                      bodyExp = 
                        RC.RCLET
                          (
                           [RC.RCVALREC (newVarExpTyExpRecordList, loc)],
                           [funRecordExp],
                           [funRecordTy],
                           loc
                          ),
                      loc = loc
                     }
             in
               RC.RCVAL([(T.VALIDENT polyRecordFunVarIdInfo,polyRecordFunExp)],
                        loc)
             end
         val originalFunVarBind =
             let
               val (_, newVarExpTyExpRecordList) =
                   foldr
                     (fn (oldVar,(n,newVarExpTyExpRecordList)) =>
                         let
                           val (boundSubst,newBtvEnv) =
                               TU.copyBoundEnv originalBtvEnv
                           val additionalOprimEnv = generateOPrimEnv newBtvEnv
                           val extraVarIdInfoList =
                               BtvListOPrimEnv.listItems additionalOprimEnv
                           val instTyList = IEnv.listItems boundSubst
                           val extraTyList = map #ty extraVarIdInfoList
                           val funBodyTy = #ty oldVar
                           val instRecordFun = (* F {tau} *)
                               RC.RCTAPP
                                 {exp = RC.RCVAR (polyRecordFunVarIdInfo,loc),
                                  expTy = polyRecordFunTy,
                                  instTyList = instTyList,
                                  loc = loc
                                  }
                           val instRecordFunTy = 
                               T.FUNMty(extraTyList, funBodyTy)
                           val instFunBody = (* F {tau} A [i] *)
                               RC.RCSELECT
                                 {
                                  label = Int.toString n,
                                  exp = 
                                  RC.RCAPPM
                                    {
                                     funExp = instRecordFun,
                                     funTy = instRecordFunTy,
                                     argExpList =
                                       map (fn v => RC.RCVAR(v,loc))
                                           extraVarIdInfoList,
                                     loc = loc
                                    },
                                  expTy = funRecordTy,
                                  resultTy = funBodyTy,
                                  loc = loc
                                 }
                           val newPolyFunTy =
                               T.POLYty
                                 {boundtvars = newBtvEnv,
                                  body = funBodyTy}
                           val newPolyFunBody = (* [a#.\A. F{tau} A [i]] *)
                               RC.RCPOLYFNM
                                 {
                                  btvEnv = newBtvEnv,
                                  argVarList = extraVarIdInfoList,
                                  bodyTy = funBodyTy,
                                  bodyExp = instFunBody,
                                  loc = loc
                                 }
                           val newFunVarWithOldId =
                               {
                                displayName = #displayName oldVar,
                                ty =
                                  T.POLYty
                                    {boundtvars = newBtvEnv,
                                     body=
                                       T.FUNMty
                                       (map #ty extraVarIdInfoList,funBodyTy)
                                    },
                                varId = #varId oldVar
                               }
                         in
                           (n - 1,
                            (T.VALIDENT newFunVarWithOldId, newPolyFunBody)
                            ::newVarExpTyExpRecordList
                           )
                         end
                     )
                     (List.length originalFunVarList,nil)
                     originalFunVarList
             in
               RC.RCVAL
                 (
                  newVarExpTyExpRecordList,
                  loc
                 )
             end
       in
         case extraVarIdInfoList of
           nil =>
           RC.RCVALPOLYREC
             (originalBtvEnv,
              map 
                (fn {var, expTy, exp} =>
                    {var = compileVarIdInfo env var,
                     expTy = compileTy expTy,
                     exp = compileRcexp env exp}
                )
              varExpTyExpRecordList,
              loc)
         | _ =>
           RC.RCLOCALDEC ([funRecordBind],[originalFunVarBind],loc)
       end
     | RC.RCLOCALDEC (rcdeclList1, rcdeclList2, loc)
       =>
       RC.RCLOCALDEC
         (compileRcdeclList env rcdeclList1,
          compileRcdeclList env rcdeclList2,
          loc)
     | RC.RCSETFIELD (rcexp1, rcexp2, int, ty, loc) 
       =>
       RC.RCSETFIELD
         (compileRcexp env rcexp1,
          compileRcexp env rcexp2,
          int,
          compileTy ty,
          loc)
     | RC.RCEMPTY loc
       =>
       RC.RCEMPTY loc
 fun compileBasicblockList env basicblockList =
     map (compileBasicblock env) basicblockList
 and compileBasicblock env basicblock =
     case basicblock of 
       RC.RCVALBLOCK
         {
          code = rcdeclList,
          exnIDSet = set
         }
       =>
       RC.RCVALBLOCK
         {
          code = compileRcdeclList env rcdeclList,
          exnIDSet = set
         }
     | RC.RCLINKFUNCTORBLOCK
         {
          name = string1,
          actualArgName = string2,
          typeResolutionTable = tyConIDmap,
          exnTagResolutionTable = idMap1,
          externalVarIDResolutionTable = idMap2,
          refreshedExceptionTagTable = idMap3,
          refreshedExternalVarIDTable = idMap4,
          loc = loc
         }
       =>
       RC.RCLINKFUNCTORBLOCK
         {
          name = string1, 
          actualArgName = string2,
          typeResolutionTable = tyConIDmap,
          exnTagResolutionTable = idMap1,
          externalVarIDResolutionTable = idMap2,
          refreshedExceptionTagTable = idMap3,
          refreshedExternalVarIDTable = idMap4,
          loc = loc
         }
 and compileTopblockList env nil = nil
   | compileTopblockList env (topBlock::rest) = 
     let
       val topBlock = compileTopblock env topBlock
         handle exn =>
         raise exn
         before (print "OverloadCompile fail for the topblock:\n";
                 printTopBlock topBlock;
                 print "\n"
                )
       val rest = compileTopblockList env rest
     in
       topBlock::rest
     end

 and compileTopblock env topblock =
     case topblock of
       RC.RCFUNCTORBLOCK
         {
          name = string, 
          formalAbstractTypeIDSet = set1,
          formalVarIDSet = set2,
          formalExnIDSet = set3,
          generativeVarIDSet = set4,
          generativeExnIDSet = set5,
          bodyCode = basicBlockList
         }
       =>
       RC.RCFUNCTORBLOCK
         {
          name = string, 
          formalAbstractTypeIDSet = set1,
          formalVarIDSet = set2,
          formalExnIDSet = set3,
          generativeVarIDSet = set4,
          generativeExnIDSet = set5,
          bodyCode = compileBasicblockList env basicBlockList
         }
     | RC.RCBASICBLOCK  basicBlock
       =>
       RC.RCBASICBLOCK (compileBasicblock env basicBlock)

  fun compile externalVarIdEnv topBlockList = 
      let
        val emptyEnv = {oprimEnv = BtvListOPrimEnv.empty,
                        varIdEnv = VarIdEnv.empty,
                        externalVarIdEnv = externalVarIdEnv} : env
        val topBlockList = compileTopblockList emptyEnv topBlockList
      in
        topBlockList
      end
      handle exn => raise exn

end
