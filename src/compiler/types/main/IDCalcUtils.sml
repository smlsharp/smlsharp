structure IDCalcUtils =
struct
local
  exception DuplicateVar
  structure IC = IDCalc
  type varMap = VarID.id VarID.Map.map
  val print = fn s => if !Control.debugPrint then print s else ()
  fun printPath path = print (String.concatWith "." path)
  fun bug s = Control.Bug ("IDCalcUtils: " ^ s)
  fun newId varMap id =
      let
        val newId = VarID.generate()
      in
        (VarID.Map.insertWith 
           (fn _ => raise DuplicateVar)
           (varMap, id, newId), newId)
      end
  fun newVar varMap {path,id} =
      let
        val (varMap, newId) = 
            newId varMap id
            handle DuplicateVar => 
                   (printPath path;
                    print "\n";
                    raise bug "duplicate id in IDCalcUtils"
                   )
      in
        (varMap, {path=path, id=newId})
      end
  fun newVars varMap vars =
      let
        val (varMap, varsRev) =
            foldl
            (fn (var, (varMap, varsRev)) =>
                let
                  val (varMap, var) = newVar varMap var
                in
                  (varMap, var::varsRev)
                end
            )
            (varMap, nil)
            vars
      in
        (varMap, List.rev varsRev)
      end
  fun copyPat varMap icpat =
      case icpat of
        IC.ICPATERROR _ => (varMap, icpat)
      | IC.ICPATWILD _ => (varMap, icpat)
      | IC.ICPATVAR (var, loc) =>
        let
          val (varMap, newVar) = newVar varMap var
        in
          (varMap, IC.ICPATVAR (newVar, loc))
        end
      | IC.ICPATCON _ => (varMap, icpat)
      | IC.ICPATEXN _ => (varMap, icpat)
      | IC.ICPATEXEXN _ => (varMap, icpat)
      | IC.ICPATCONSTANT _ => (varMap, icpat)
      | IC.ICPATCONSTRUCT {con:IC.icpat, arg:IC.icpat, loc} =>
        let
          val (varMap, con) = copyPat varMap con
          val (varMap, arg) = copyPat varMap arg
        in
          (varMap, IC.ICPATCONSTRUCT {con=con, arg=arg, loc=loc})
        end
      | IC.ICPATRECORD {flex, fields:(string * IC.icpat) list, loc} =>
        let
          val (varMap, fieldsRev) =
              foldl
              (fn ((label, pat), (varMap, fieldsRev)) =>
                  let
                    val (varMap, pat) = copyPat varMap pat
                  in
                    (varMap, (label, pat)::fieldsRev)
                  end
              )
              (varMap, nil)
              fields
        in
          (varMap, IC.ICPATRECORD {flex=flex, fields=List.rev fieldsRev, loc=loc})
        end
      | IC.ICPATLAYERED {patVar:IC.varInfo, tyOpt, pat, loc} =>
        let
          val (varMap, patVar) = newVar varMap patVar
          val (varMap, pat) = copyPat varMap pat
        in
          (varMap, IC.ICPATLAYERED {patVar=patVar, tyOpt=tyOpt, pat=pat, loc=loc})
        end
      | IC.ICPATTYPED (icpat, ty, loc) =>
        let
          val (varMap, icpat) = copyPat varMap icpat
        in
          (varMap, IC.ICPATTYPED (icpat, ty, loc))
        end
  fun copyPats varMap pats = 
      let
        val (varMap,patsRev) =
            foldl
            (fn (pat, (varMap,patsRev)) =>
                let
                  val (varMap, pat) = copyPat varMap pat
                in
                  (varMap, pat::patsRev)
                end
            )
            (varMap, nil)
            pats
      in
        (varMap, List.rev patsRev)
      end
  fun evalVar varMap {path, id} =
      case VarID.Map.find(varMap, id) of
        SOME id => {path=path, id=id}
      | NONE => {path=path, id=id}
  fun copyExp varMap exp =
      let
        fun copy exp = copyExp varMap exp
      in
        case exp of
          IC.ICERROR _ => exp
        | IC.ICCONSTANT _ => exp
        | IC.ICGLOBALSYMBOL _ => exp
        | IC.ICVAR (var,loc) => IC.ICVAR (evalVar varMap var,loc)
        | IC.ICEXVAR _ => exp
        | IC.ICEXVAR_TOBETYPED (var,loc) =>
          IC.ICEXVAR_TOBETYPED (evalVar varMap var,loc)
        | IC.ICBUILTINVAR _ => exp
        | IC.ICCON _ => exp
        | IC.ICEXN  _ => exp
        | IC.ICEXEXN _ => exp
        | IC.ICEXN_CONSTRUCTOR _ => exp
        | IC.ICEXEXN_CONSTRUCTOR _ => exp
        | IC.ICOPRIM  _ => exp
        | IC.ICTYPED (icexp, ty, loc) => IC.ICTYPED (copy icexp, ty,loc)
        | IC.ICSIGTYPED {icexp,ty,loc,revealKey} =>
          IC.ICSIGTYPED {icexp=copy icexp,
                         ty=ty,
                         loc=loc,
                         revealKey=revealKey}
        | IC.ICAPPM (icexp, icexpList, loc) =>
          IC.ICAPPM (copy icexp, map copy icexpList, loc)
        | IC.ICAPPM_NOUNIFY (icexp, icexpList,loc) =>
          IC.ICAPPM_NOUNIFY (copy icexp, map copy icexpList,loc)
        | IC.ICLET (icdeclList, icexpList, loc) =>
          let
            val (varMap, icdeclListRev) = copyDeclList varMap icdeclList
            val icexpList = map (copyExp varMap) icexpList
          in
            IC.ICLET (List.rev icdeclListRev, icexpList, loc)
          end
        | IC.ICTYCAST (castList, icexp,loc) =>
          IC.ICTYCAST (castList, copy icexp, loc)
        | IC.ICRECORD (stringIcexpList,loc) =>
          IC.ICRECORD (map (fn (l,e) => (l, copy e)) stringIcexpList,loc)
        | IC.ICRAISE (icexp, loc) => IC.ICRAISE (copy icexp, loc)
        | IC.ICHANDLE (icexp, icpatIcexpList, loc) =>
          let
            val icexp = copy icexp
            val icpatIcexpList =
                map
                  (fn (pat,exp) => 
                      let
                        val (varMap, pat) = copyPat varMap pat
                      in
                        (pat, copyExp varMap exp)
                      end
                  )
                icpatIcexpList
          in
            IC.ICHANDLE (icexp, icpatIcexpList, loc)
          end
        | IC.ICFNM (rules, loc) =>
          IC.ICFNM (map (copyRule varMap) rules, loc)
        | IC.ICFNM1 (varTyListList, icexp, loc) =>
          let
            val (varList, tyListList) = ListPair.unzip varTyListList
            val (varMap, varList) = newVars varMap varList
            val icexp = copyExp varMap icexp
            val varTyListList  = ListPair.zip (varList, tyListList)
          in
            IC.ICFNM1 (varTyListList, icexp, loc)
          end
        | IC.ICFNM1_POLY (varTyListList, icexp, loc) =>
          let
            val (vars, tyListList) = ListPair.unzip varTyListList
            val (varMap, vars) = newVars varMap vars
            val varTyListList = ListPair.zip (vars, tyListList)
          in
            IC.ICFNM1_POLY (varTyListList, copyExp varMap icexp, loc)
          end
        | IC.ICCASEM (icexpList, rules, caseKind,loc) =>
          IC.ICCASEM (map copy icexpList,
                      map (copyRule varMap) rules,
                      caseKind,
                      loc)
        | IC.ICRECORD_UPDATE (icexp, stringIcexpList, loc) =>
          IC.ICRECORD_UPDATE (copy icexp,
                              map (fn (l,e) => (l, copy e)) stringIcexpList,
                              loc)
        | IC.ICRECORD_SELECTOR (string, loc) => exp
        | IC.ICSELECT (string, icexp, loc) =>
          IC.ICSELECT (string, copy icexp, loc)
        | IC.ICSEQ (icexpList, loc) =>
          IC.ICSEQ (map copy icexpList, loc)
        | IC.ICCAST (icexp, loc) =>
          IC.ICCAST (copy icexp, loc)
        | IC.ICFFIIMPORT (icexp, ffiTy, loc) =>
          IC.ICFFIIMPORT (copy icexp, ffiTy, loc)
        | IC.ICFFIEXPORT (icexp, ffiTy, loc) =>
          IC.ICFFIEXPORT (copy icexp, ffiTy, loc)
        | IC.ICFFIAPPLY (ffiAttributesOption, icexp, ffiArgList, ffiTy, loc) =>
          IC.ICFFIAPPLY (ffiAttributesOption,
                         copy icexp,
                         map (copyFfiArg varMap) ffiArgList,
                         ffiTy,
                         loc)
        | IC.ICSQLSERVER (string, ty, loc) => exp
        | IC.ICSQLDBI (icpat, icexp, loc) =>
          let
            val (varMap, icpat) = copyPat varMap icpat
          in
            IC.ICSQLDBI (icpat, copyExp varMap icexp, loc)
          end
      end
  and copyFfiArg varMap ffiArg =
      case ffiArg of
        IC.ICFFIARG  (icexp, ffiTy, loc) =>
        IC.ICFFIARG  (copyExp varMap icexp, ffiTy, loc)
      | IC.ICFFIARGSIZEOF (ty, icexpOption, loc) =>
        IC.ICFFIARGSIZEOF (ty, Option.map (copyExp varMap) icexpOption, loc)
  and copyRule varMap {args, body} =
      let
        val (varMap, args) = copyPats varMap args
        val body = copyExp varMap body
      in
        {args=args, body=body}
      end
  and copyBind (newVarMap, varMap) (pat, exp) = 
      let
        val (newVarMap, pat) = copyPat newVarMap pat
        val exp = copyExp varMap exp
      in
        (newVarMap, (pat, exp))
      end
  and copyBinds varMap binds = 
      let
        val (newVarMap, bindsRev) =
            foldl
            (fn (bind, (newVarMap, bindsRev)) =>
                let
                  val (newVarMap, bind) = copyBind (newVarMap, varMap) bind
                in
                  (newVarMap, bind::bindsRev)
                end
            )
            (varMap, nil)
            binds
      in
        (newVarMap, List.rev bindsRev)
      end
  and copyDecl varMap icdecl =
      case icdecl of
      IC.ICVAL (guard, icpatIcexpList, loc) =>
      let
        val (varMap, binds) = copyBinds varMap icpatIcexpList
      in
        (varMap, IC.ICVAL (guard, binds, loc))
      end
    | IC.ICDECFUN
        {
          guard,
          funbinds:
            {
             funVarInfo: IC.varInfo,
             tyList:IDCalc.ty list,
             rules: {args: IC.icpat list, body: IC.icexp} list
            } list,
          loc
         } =>
      let
        val (funvars, rulesList, tyListList) =
            foldr
            (fn ({funVarInfo, tyList, rules}, (funvars, rulesList, tyListList)) =>
                (funVarInfo::funvars, rules::rulesList, tyList::tyListList)
            )
            (nil,nil,nil)
            funbinds
        val (varMap, funvars) = newVars varMap funvars
        val rulesList = map (map (copyRule varMap)) rulesList
        val funbinds =
            map
              (fn (funVar, (rules, tyList)) =>
                  {funVarInfo=funVar, rules = rules, tyList = tyList})
              (ListPair.zip(funvars, ListPair.zip(rulesList, tyListList)))
      in
        (varMap, IC.ICDECFUN {guard=guard, funbinds=funbinds, loc=loc})
      end
    | IC.ICNONRECFUN
         {
          guard,
          funVarInfo: IC.varInfo,
          tyList: IDCalc.ty list,
          rules: {args: IC.icpat list, body: IC.icexp} list,
          loc
         } =>
      let
        val rules = map (copyRule varMap) rules
        val (varMap, funVarInfo) = newVar varMap funVarInfo
      in
        (varMap, 
         IC.ICNONRECFUN {guard=guard, 
                         funVarInfo=funVarInfo,
                         tyList=tyList,
                         rules=rules,
                         loc=loc
                        }
        )
      end
    | IC.ICVALREC
        {guard,
         recbinds: {varInfo: IC.varInfo,
                    tyList:IDCalc.ty list,
                    body: IC.icexp} list,
         loc} =>
      let
        val vars = map #varInfo recbinds
        val (varMap, vars) = newVars varMap vars
        val varRecbindList = ListPair.zip (vars, recbinds)
        val recbinds =
            map
            (fn (var, {varInfo, tyList, body}) =>
                {varInfo=var, tyList=tyList, body=copyExp varMap body}
            )
            varRecbindList
      in
        (varMap,
         IC.ICVALREC {guard=guard, recbinds=recbinds, loc=loc}
        )
      end
    | IC.ICEXND _ => (varMap, icdecl)
    | IC.ICEXNTAGD ({exnInfo, varInfo}, loc) =>
      (varMap, 
       IC.ICEXNTAGD ({exnInfo=exnInfo,
                      varInfo=evalVar varMap varInfo}, 
                     loc)
      )
    | IC.ICEXPORTVAR (varInfo, ty, loc) =>
      (varMap, 
       IC.ICEXPORTVAR (evalVar varMap varInfo, ty, loc)
      )
    | IC.ICEXPORTTYPECHECKEDVAR (varInfo, loc) =>
      (varMap, 
       IC.ICEXPORTTYPECHECKEDVAR (evalVar varMap varInfo, loc)
      )
    | IC.ICEXPORTFUNCTOR (varInfo, ty, loc) =>
      (varMap, 
       IC.ICEXPORTFUNCTOR (evalVar varMap varInfo, ty, loc)
      )
    | IC.ICEXPORTEXN _ => (varMap, icdecl)
    | IC.ICEXTERNVAR  _ => (varMap, icdecl)
    | IC.ICEXTERNEXN  _ => (varMap, icdecl)
    | IC.ICTYCASTDECL (castList, icdeclList, loc) =>
      let
        val (varMap, icdeclList) = copyDeclList varMap icdeclList
      in
        (varMap, IC.ICTYCASTDECL (castList, icdeclList, loc))
      end
    | IC.ICOVERLOADDEF _ => (varMap, icdecl)
  and copyDeclList varMap declList =
      let
        fun copy (decl, (varMap, declListRev)) =
            let
              val (varMap, newDecl) = copyDecl varMap decl
            in
              (varMap, newDecl::declListRev)
            end
        val (varMao, declListRev) = foldl copy (VarID.Map.empty, nil) declList
      in
        (varMap, List.rev declListRev)
      end
in
  val copyExp = fn exp => copyExp VarID.Map.empty exp
  val copyDecl = fn decl => #2 (copyDecl VarID.Map.empty decl)
  val copyDeclList = fn declList => #2 (copyDeclList VarID.Map.empty declList)
  val copyPat = fn pat => #2 (copyPat VarID.Map.empty pat)
end
end
