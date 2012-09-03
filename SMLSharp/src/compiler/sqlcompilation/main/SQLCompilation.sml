(**
 * SQL compilation.
 *
 * @copyright (c) 2010, Tohoku University.
 * @author Hiroki Endo
 * @author UENO Katsuhiro
 *)
structure SQLCompilation : sig

  val compile
      : RecordCalc.topBlock list
        -> RecordCalc.topBlock list

end = 
struct

  structure RC = RecordCalc
  structure CT = ConstantTerm        
  structure T = Types

  fun sqlStrTerm (str, loc) =
      RC.RCCONSTANT (CT.STRING str, loc)

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {displayName = "$" ^ VarID.toString id,
         ty = ty,
         varId = T.INTERNAL id}
        : RC.varIdInfo
      end
        
  fun makeArgExp (args, tys, loc) =
      let
        fun tuple l =
            #2 (foldl (fn (x, (i, z)) =>
                          (i + 1, SEnv.insert (z, Int.toString i, x)))
                      (1, SEnv.empty) l)
      in
        RC.RCRECORD {fields = tuple args,
                     recordTy = Types.RECORDty (tuple tys),
                     loc = loc}
      end
        
  fun stringSizeExp (argExp, loc) =
      RC.RCPRIMAPPLY {primOp = PredefinedTypes.stringSizePrimInfo,
                      instTyList = nil,
                      argExpOpt = SOME argExp,
                      loc = loc}
      
  fun stringCopyUnsafeExp {src, si, dst, di, len, loc} =
      RC.RCPRIMAPPLY {primOp = PredefinedTypes.stringCopyUnsafePrimInfo,
                      instTyList = nil,
                      argExpOpt =
                        SOME (makeArgExp ([src, si, dst, di, len],
                                          [PredefinedTypes.stringty,
                                           PredefinedTypes.intty,
                                           PredefinedTypes.stringty,
                                           PredefinedTypes.intty,
                                           PredefinedTypes.intty],
                                          loc)),
                      loc = loc}
      
  fun stringNewExp (size, loc) =
      RC.RCPRIMAPPLY {primOp = PredefinedTypes.stringArrayPrimInfo,
                      instTyList = nil,
                      argExpOpt =
                        SOME (makeArgExp ([size,
                                           RC.RCCONSTANT
                                             (CT.CHAR #"\000", loc)],
                                          [PredefinedTypes.intty,
                                           PredefinedTypes.charty],
                                          loc)),
                      loc = loc}
      
  fun intAddExp (n1, n2, loc) =
      RC.RCPRIMAPPLY {primOp = PredefinedTypes.intAddPrimInfo,
                      instTyList = nil,
                      argExpOpt =
                        SOME (makeArgExp ([n1, n2],
                                          [PredefinedTypes.intty,
                                           PredefinedTypes.intty],
                                          loc)),
                      loc = loc}
      
  fun const0 loc =
      RC.RCCONSTANT (CT.INT 0, loc)
                   
  fun concat (RC.RCCONSTANT (CT.STRING s1, _), 
              RC.RCCONSTANT (CT.STRING s2, _), loc) =
      RC.RCCONSTANT (CT.STRING (s1 ^ s2), loc)
    | concat (s1, s2, loc) =
      let
        (*
         * let n1 = String_size s1
         *     n2 = String_size s2
         *     size = n1 + n2
         *     dst = String_array (size, 0)
         *     String_copy_unsafe (s1, 0, dst, 0, n1)
         *     String_copy_unsafe (s2, 0, dst, n1, n2)
         * in dst
         *)
        val var_s1 = newVar PredefinedTypes.stringty
        val var_s2 = newVar PredefinedTypes.stringty
        val var_n1 = newVar PredefinedTypes.intty
        val var_n2 = newVar PredefinedTypes.intty
        val var_size = newVar PredefinedTypes.intty
        val var_dst = newVar PredefinedTypes.stringty
      in
        RC.RCMONOLET
          {binds =
             [(var_s1, s1),
              (var_s2, s2),
              (var_n1, stringSizeExp (RC.RCVAR (var_s1, loc), loc)),
              (var_n2, stringSizeExp (RC.RCVAR (var_s2, loc), loc)),
              (var_size, intAddExp (RC.RCVAR (var_n1, loc),
                                    RC.RCVAR (var_n2, loc), loc)),
              (var_dst, stringNewExp (RC.RCVAR (var_size, loc), loc))],
           bodyExp =
             RC.RCSEQ
               {expList =
                  [stringCopyUnsafeExp {src = RC.RCVAR (var_s1, loc),
                                        si = const0 loc,
                                        dst = RC.RCVAR (var_dst, loc),
                                        di = const0 loc,
                                        len = RC.RCVAR (var_n1, loc),
                                        loc = loc},
                   stringCopyUnsafeExp {src = RC.RCVAR (var_s2, loc),
                                        si = const0 loc,
                                        dst = RC.RCVAR (var_dst, loc),
                                        di = RC.RCVAR (var_n1, loc),
                                        len = RC.RCVAR (var_n2, loc),
                                        loc = loc},
                   RC.RCVAR (var_dst, loc)],
                expTyList =
                  [PredefinedTypes.unitty,
                   PredefinedTypes.unitty,
                   PredefinedTypes.stringty],
                loc = loc},
           loc = loc}
      end
        
  fun concatList (s, h::t, loc) = concatList (concat (s, h, loc), t, loc)
    | concatList (s, nil, loc) = s
                                 
  fun sqlConcatTerm loc nil = sqlStrTerm ("", loc)
    | sqlConcatTerm loc (h::t) = concatList (h, t, loc)
                               
  fun sqlCastTerm (exp, loc) =
      RC.RCCAST (exp, PredefinedTypes.stringty, loc)

  val toConInfo = Types.conPathInfoToConInfo

  fun conTyArgs ty =
      case TypesUtils.derefTy ty of
        T.RAWty {tyCon, args} => args
      | _ => raise Control.Bug "conTyArgs"

  fun sqlDataConTerm {conPathInfo, resultTy, argExp, loc} =
      RC.RCDATACONSTRUCT {con = toConInfo conPathInfo,
                          instTyList = conTyArgs resultTy,
                          argExpOpt = SOME argExp,
                          loc = loc}

  fun compileSqlexp (rcsqlexp, resultTy, loc) =
      case rcsqlexp of
        RC.RCSQLSERVER {server, schema} =>
        let
          val strPairTy =
              T.RECORDty
                  (SEnv.insert
                       (SEnv.insert
                            (SEnv.singleton ("colname", T.RAWty {tyCon =
                                                           PredefinedTypes.stringTyCon,
                                                           args = nil}),
                             "typename", T.RAWty {tyCon = PredefinedTypes.stringTyCon,
                                           args = nil}),
                            "isnull", PredefinedTypes.boolty)
                       )
          val strPairListTy = T.RAWty {tyCon = PredefinedTypes.listTyCon, args = [strPairTy]}
          val tablePairTy =
              T.RECORDty
              (SEnv.insert
                   (SEnv.singleton ("1", T.RAWty {tyCon = PredefinedTypes.stringTyCon,
                                                  args = nil}),
                    "2", strPairListTy))
          val tablePairListTy = T.RAWty {tyCon = PredefinedTypes.listTyCon,
                                         args = [tablePairTy]}
          val serverSchemaPairTy =
              T.RECORDty
              (SEnv.insert
                   (SEnv.singleton ("1", PredefinedTypes.stringty),
                    "2", tablePairListTy))
          fun makeStrTuple a (b,c) =
              let
                val fieldEnv =
                    SEnv.insert
                        ((SEnv.insert
                              (SEnv.singleton ("colname", RC.RCCONSTANT (CT.STRING a,
                                                                 (Loc.nopos,Loc.nopos))),
                               "typename",RC.RCCONSTANT (CT.STRING b,(Loc.nopos,Loc.nopos)))),
                         "isnull", RC.RCDATACONSTRUCT {con = toConInfo c,
                                                instTyList = conTyArgs PredefinedTypes.boolty,
                                                argExpOpt = NONE,
                                                loc = (Loc.nopos,Loc.nopos)})
              in
                RC.RCRECORD {fields = fieldEnv, recordTy = strPairTy, loc = (Loc.nopos,Loc.nopos)}
              end
          fun makeStrTupleList al bl =
              if not ((List.length al) = (List.length bl))
              then raise Control.Bug "TPSQLSERVER : colname and colvalue list length not equal"
              else let
                fun tt (T.RAWty {tyCon, args}) =
                    (case args of
                       nil => (#name tyCon, PredefinedTypes.falseConPathInfo)
                     | L =>((case L of
                               [T.RAWty {tyCon,args}] => #name tyCon
                             | _ => raise Control.Bug "TPSQLSERVER : typeCon"),
                            (case #name tyCon of
                               "option" => PredefinedTypes.trueConPathInfo
                             | _ => raise Control.Bug "TPSQLSERVER : typeCon")))
                  | tt _ =  raise Control.Bug "TPSQLSERVER : typename"
                fun tmp nil nil a = a
                  | tmp (h1::t1) (h2::t2) a =
                    tmp t1 t2
                        (a@[makeStrTuple h1 (tt h2)])
                in
                  RC.RCLIST { expList = (tmp al bl []),
                            listTy = strPairListTy,
                            loc = (Loc.nopos,Loc.nopos)}
                end
          fun makeTablenameBodyPair name body =
              (case body of
                 T.RECORDty senv =>
                 let
                   val colnameList = SEnv.listKeys senv
                   val coltypeList = SEnv.listItems senv
                   val evaluatedBody = makeStrTupleList colnameList coltypeList
                   val tablenameConst = RC.RCCONSTANT (CT.STRING name, (Loc.nopos,Loc.nopos))
                   val fieldsEnv = SEnv.insert (SEnv.singleton ("1",tablenameConst),
                                                "2",evaluatedBody)
                 in
                   RC.RCRECORD {fields = fieldsEnv,
                              recordTy = tablePairTy, loc = (Loc.nopos,Loc.nopos)}
                 end
               | _ => raise Control.Bug "TPSQLSERVER : tablebody not pair type")
          fun makeTableList nameList bodyList =
              if not ((List.length nameList) = (List.length bodyList))
              then raise Control.Bug "TPSQLSERVER : tablename and body list length not equal"
              else let
                  fun tmp nil nil a = a
                    | tmp (h1::t1) (h2::t2) a = tmp t1 t2 (a@[makeTablenameBodyPair h1 h2])
                in
                  RC.RCLIST { expList = tmp nameList bodyList [],
                            listTy = tablePairListTy,
                            loc = (Loc.nopos, Loc.nopos) }
                end
          val schmKeys = SEnv.listKeys schema
          val schmItems = map TypesUtils.pruneTy (SEnv.listItems schema)
          val tables = makeTableList schmKeys schmItems
          val server =
              sqlConcatTerm
                  loc
                  (foldr (fn (("",e),S) => compileExp e :: S
                           | ((l,e),S) =>
                             [sqlStrTerm(" " ^ l,loc),
                              sqlStrTerm(" = ",loc),
                              compileExp e]@S)
                         [sqlStrTerm(" ",loc)] server)
          val serverTablePair =
            let
              val fieldsEnv =
                  SEnv.insert
                      (SEnv.singleton ("1",server),
                       "2", tables)
            in
              RC.RCRECORD { fields = fieldsEnv,
                          recordTy = serverSchemaPairTy,
                          loc = loc}
            end

          fun columnWitness ty =
              case TypesUtils.derefTy ty of
                T.RAWty {tyCon, args=nil} =>
                if TyConID.eq (#id tyCon, #id PredefinedTypes.intTyCon)
                then RC.RCCONSTANT (CT.INT 0, loc)
                else if TyConID.eq (#id tyCon, #id PredefinedTypes.wordTyCon)
                then RC.RCCONSTANT (CT.WORD 0w0, loc)
                else if TyConID.eq (#id tyCon, #id PredefinedTypes.boolTyCon)
                then RC.RCDATACONSTRUCT
                       {con = toConInfo PredefinedTypes.falseConPathInfo,
                        instTyList = nil,
                        argExpOpt = NONE,
                        loc = loc}
                else if TyConID.eq (#id tyCon, #id PredefinedTypes.charTyCon)
                then RC.RCCONSTANT (CT.CHAR #"\000", loc)
                else if TyConID.eq (#id tyCon, #id PredefinedTypes.stringTyCon)
                then RC.RCCONSTANT (CT.STRING "", loc)
                else if TyConID.eq (#id tyCon, #id PredefinedTypes.realTyCon)
                then RC.RCCONSTANT (CT.REAL "0.0", loc)
                else raise Control.Bug "columnWitness"
              | ty as T.RAWty {tyCon, args=[arg]} =>
                if TyConID.eq (#id tyCon, #id PredefinedTypes.optionTyCon)
                then sqlDataConTerm
                       {conPathInfo = PredefinedTypes.someConPathInfo,
                        resultTy = ty,
                        argExp = columnWitness arg,
                        loc = loc}
                else raise Control.Bug "columnWitness: option"
              | _ => raise Control.Bug "columnWitness: _"

          fun tableWitness ty =
              case TypesUtils.derefTy ty of
                ty as T.RECORDty fields =>
                RC.RCRECORD
                  {fields = SEnv.map columnWitness fields,
                   recordTy = ty,
                   loc = loc}
              | _ => raise Control.Bug "tableWitness"

          val witnessTy = T.RECORDty schema
          val witness =
              RC.RCRECORD
                {fields = SEnv.map tableWitness schema,
                 recordTy = witnessTy,
                 loc = loc}

          val conarg =
              RC.RCRECORD
                {fields = SEnv.fromList [("1", server),
                                         ("2", tables),
                                         ("3", witness)],
                 recordTy =
                   T.RECORDty
                     (SEnv.fromList [("1", PredefinedTypes.stringty),
                                     ("2", tablePairListTy),
                                     ("3", witnessTy)]),
                 loc = loc}
        in
          sqlDataConTerm {conPathInfo = PredefinedTypes.sqlServerConPathInfo,
                          resultTy = resultTy,
                          argExp = conarg,
                          loc = loc}
        end

  and compileExp rcexp =
      case rcexp of
        RC.RCFOREIGNAPPLY {funExp, funTy, instTyList, argExpList, argTyList,
                           attributes, loc} =>
        RC.RCFOREIGNAPPLY
          {funExp = compileExp funExp,
           funTy = funTy,
           instTyList = instTyList,
           argExpList = map compileExp argExpList,
           argTyList = argTyList,
           attributes = attributes,
           loc = loc}
      | RC.RCEXPORTCALLBACK {funExp, argTyList, resultTy, attributes, loc} =>
        RC.RCEXPORTCALLBACK
          {funExp = compileExp funExp,
           argTyList = argTyList,
           resultTy = resultTy,
           attributes = attributes,
           loc = loc}
      | RC.RCSIZEOF (ty, loc) =>
        RC.RCSIZEOF (ty, loc)
      | RC.RCCONSTANT (constant, loc) =>
        RC.RCCONSTANT (constant, loc)
      | RC.RCGLOBALSYMBOL symbol =>
        RC.RCGLOBALSYMBOL symbol
      | RC.RCVAR (varIdInfo, loc) =>
        RC.RCVAR (varIdInfo, loc)
      | RC.RCGETFIELD (rcexp, index, ty, loc) =>
        RC.RCGETFIELD (compileExp rcexp, index, ty, loc)
      | RC.RCARRAY {sizeExp, initExp, elementTy, resultTy, loc} =>
        RC.RCARRAY
          {sizeExp = compileExp sizeExp,
           initExp = compileExp initExp,
           elementTy = elementTy,
           resultTy = resultTy,
           loc = loc}
      | RC.RCPRIMAPPLY {primOp, instTyList, argExpOpt, loc} =>
        RC.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | RC.RCOPRIMAPPLY {oprimOp, instances, keyTyList, argExpOpt, loc} =>
        RC.RCOPRIMAPPLY
          {oprimOp = oprimOp,
           instances = instances,
           keyTyList = keyTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | RC.RCDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        RC.RCDATACONSTRUCT
          {con = con,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | RC.RCEXNCONSTRUCT {exn, instTyList, argExpOpt, loc} =>
        RC.RCEXNCONSTRUCT
          {exn = exn,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | RC.RCAPPM {funExp, funTy, argExpList, loc} =>
        RC.RCAPPM
          {funExp = compileExp funExp,
           funTy = funTy,
           argExpList = map compileExp argExpList,
           loc = loc}
      | RC.RCMONOLET {binds, bodyExp, loc} =>
        RC.RCMONOLET
          {binds = map (fn (v,e) => (v, compileExp e)) binds,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | RC.RCLET (rcdeclList, rcexpList, tyList, loc) =>
        RC.RCLET (map compileDecl rcdeclList,
                  map compileExp rcexpList,
                  tyList,
                  loc)
      | RC.RCRECORD {fields, recordTy, loc} =>
        RC.RCRECORD
          {fields = SEnv.map compileExp fields,
           recordTy = recordTy,
           loc = loc}
      | RC.RCSELECT {label, exp, expTy, resultTy, loc} =>
        RC.RCSELECT
          {label = label,
           exp = compileExp exp,
           expTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | RC.RCMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        RC.RCMODIFY
          {label = label,
           recordExp = compileExp recordExp,
           recordTy = recordTy,
           elementExp = compileExp elementExp,
           elementTy = elementTy,
           loc = loc}
      | RC.RCRAISE (rcexp, ty, loc) =>
        RC.RCRAISE (compileExp rcexp, ty, loc)
      | RC.RCHANDLE {exp, exnVar, handler, loc} =>
        RC.RCHANDLE
          {exp = compileExp exp,
           exnVar = exnVar,
           handler = compileExp handler,
           loc = loc}
      | RC.RCCASE {exp, expTy, ruleList, defaultExp, loc} =>
        RC.RCCASE
          {exp = compileExp exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp e)) ruleList,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | RC.RCEXNCASE {exp, expTy, ruleList, defaultExp, loc} =>
        RC.RCEXNCASE
          {exp = compileExp exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp e)) ruleList,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | RC.RCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        RC.RCSWITCH
          {switchExp = compileExp switchExp,
           expTy = expTy,
           branches = map (fn (c,e) => (c, compileExp e)) branches,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        RC.RCFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | RC.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
        RC.RCPOLYFNM
          {btvEnv = btvEnv,
           argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | RC.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        RC.RCPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp exp,
           loc = loc}
      | RC.RCTAPP {exp, expTy, instTyList, loc} =>
        RC.RCTAPP
          {exp = compileExp exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | RC.RCSEQ {expList, expTyList, loc} =>
        RC.RCSEQ
          {expList = map compileExp expList,
           expTyList = expTyList,
           loc = loc}
      | RC.RCLIST {expList, listTy, loc} =>
        RC.RCLIST
          {expList = map compileExp expList,
           listTy = listTy,
           loc = loc}
      | RC.RCCAST (rcexp, ty, loc) =>
        RC.RCCAST (compileExp rcexp, ty, loc)
      | RC.RCSQL exp =>
        compileSqlexp exp

  and compileDecl rcdecl =
      case rcdecl of
        RC.RCVAL (bindList, loc) =>
        RC.RCVAL (map (fn (v,e) => (v, compileExp e)) bindList, loc)
      | RC.RCVALREC (bindList, loc) =>
        RC.RCVALREC (map (fn {var, expTy, exp} =>
                             {var=var, expTy=expTy, exp=compileExp exp})
                         bindList, 
                     loc)
      | RC.RCVALPOLYREC (btvEnv, bindList, loc) =>
        RC.RCVALPOLYREC (btvEnv,
                         map (fn {var, expTy, exp} =>
                             {var=var, expTy=expTy, exp=compileExp exp})
                             bindList,
                         loc)
      | RC.RCLOCALDEC (rcdeclList, rcdeclList2, loc) =>
        RC.RCLOCALDEC (map compileDecl rcdeclList,
                       map compileDecl rcdeclList2,
                       loc)
      | RC.RCSETFIELD (exp, arrayExp, index, ty, loc) =>
        RC.RCSETFIELD (compileExp exp, compileExp arrayExp, index, ty, loc)
      | RC.RCEMPTY loc =>
        RC.RCEMPTY loc

  fun compileBasicBlock basicBlock =
      case basicBlock of
        RC.RCVALBLOCK {code, exnIDSet} =>
        RC.RCVALBLOCK {code = map compileDecl code, exnIDSet = exnIDSet}
      | RC.RCLINKFUNCTORBLOCK args =>
        RC.RCLINKFUNCTORBLOCK args

  fun compileTopBlock topBlock =
      case topBlock of
        RC.RCFUNCTORBLOCK {name, formalAbstractTypeIDSet, formalVarIDSet,
                           formalExnIDSet, generativeVarIDSet,
                           generativeExnIDSet, bodyCode} =>
        RC.RCFUNCTORBLOCK
          {name = name,
           formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
           formalVarIDSet = formalVarIDSet,
           formalExnIDSet = formalExnIDSet,
           generativeVarIDSet = generativeVarIDSet,
           generativeExnIDSet = generativeExnIDSet,
           bodyCode = map compileBasicBlock bodyCode}
      | RC.RCBASICBLOCK basicBlock =>
        RC.RCBASICBLOCK (compileBasicBlock basicBlock)

  fun compile topBlockList = 
      map compileTopBlock topBlockList

end
