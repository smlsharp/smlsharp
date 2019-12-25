(**
 * Smart TypedCalc constructors with type reconstruction
 *
 * @copyright (c) 2017, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure TypedCalcCon =
struct

  structure C = TypedCalc
  structure T = Types

  fun printE s =
      TextIO.output (TextIO.stdOut, s)

  type exp = TypedCalc.tpexp * Types.ty
  type pat = TypedCalc.tppat * Types.ty * Types.varInfo VarID.Map.map

  fun instantiateCon (ty, nil) = ty
    | instantiateCon (ty, args) = TypesBasics.tpappTy (ty, args)

  fun arrayTy elemTy =
      T.CONSTRUCTty {tyCon=BuiltinTypes.arrayTyCon, args = [elemTy]}

  fun tupleTy nil = BuiltinTypes.unitTy
    | tupleTy [ty] = ty
    | tupleTy tys = T.RECORDty (RecordLabel.tupleMap tys)

  fun recordTy fields =
      T.RECORDty
        (foldl
           (fn ((k,v),z) =>
               RecordLabel.Map.insert (z, RecordLabel.fromString k, v))
           RecordLabel.Map.empty
           fields)

  fun fail1 msg loc ty =
      (printE ("<<<<<<<<<<<<<<<<<<<\nFAILED: " ^ msg ^ " at ");
       printE (Bug.prettyPrint (Loc.format_loc loc));
       printE "\nty:\n";
       printE (Bug.prettyPrint (Types.format_ty ty));
       printE "\n>>>>>>>>>>>>>>>>>>>\n")

  fun fail2 msg loc (ty1, ty2) =
      (printE ("<<<<<<<<<<<<<<<<<<<\nFAILED: " ^ msg ^ " at ");
       printE (Bug.prettyPrint (Loc.format_loc loc));
       printE "\nty1:\n";
       printE (Bug.prettyPrint (Types.format_ty ty1));
       printE "\nty2:\n";
       printE (Bug.prettyPrint (Types.format_ty ty2));
       printE "\n>>>>>>>>>>>>>>>>>>>\n")

  fun mustBeCONSTRUCTty msg loc ty =
      if
        case TypesBasics.derefTy ty of
          T.CONSTRUCTty _ => true
        | T.POLYty {body, ...} =>
          (case TypesBasics.derefTy body of
             T.CONSTRUCTty _ => true
           | _ => false)
        | _ => false
      then ()
      else fail1 ("mustBeCONSTRUCTty (" ^ msg ^ ")") loc ty

  fun eqTy msg loc tys =
      case
        List.filter
          (fn (i, x) => not (Unify.eqTy BoundTypeVarID.Map.empty x))
          (rev (#2 (foldl (fn (x,(i,z)) => (i+1,(i,x)::z)) (1, nil) tys)))
      of nil => ()
       | errors =>
         app (fn (i, (ty1, ty2)) =>
                 fail2 ("eqTy (" ^ msg ^ " equation " ^ Int.toString i ^ ")")
                       loc
                       (ty1, ty2))
             errors


  fun check (f : unit -> unit) =
      if !Control.checkType then f () else ()



  val TPERROR = (C.TPERROR, T.ERRORty)

  fun TPCONSTANT (x as {const, ty, loc}) =
      (C.TPCONSTANT x, ty)

  fun TPSIZEOF (ty, loc) =
      (C.TPSIZEOF (ty, loc), T.SINGLETONty (T.SIZEty ty))

  fun TPREIFYTY (ty, loc) =
      (C.TPREIFYTY (ty, loc), ReifiedTyData.TyRepTy ())

  fun TPEXN_CONSTRUCTOR (x as {exnInfo, loc}) =
      (C.TPEXN_CONSTRUCTOR x, BuiltinTypes.exntagTy)

  fun TPEXEXN_CONSTRUCTOR (x as {exExnInfo, loc}) =
      (C.TPEXEXN_CONSTRUCTOR x, BuiltinTypes.exntagTy)

  fun TPEXVAR (x as {path, ty}) =
      (C.TPEXVAR x, ty)

  fun TPVAR (x as {id, path, ty, opaque}) =
      (C.TPVAR x, ty)

  fun TPRECFUNVAR (x as {arity, var = {ty, ...}}) =
      (C.TPRECFUNVAR x, ty)

  fun TPCAST (((exp, ty), fromTy), toTy, loc) =
      (check
         (fn () =>
             eqTy "TPCAST" loc [(ty, fromTy)]);
       (C.TPCAST ((exp, ty), toTy, loc), toTy))

  fun TPDATACONSTRUCT {argExpOpt = NONE, con, instTyList, loc} =
      (C.TPDATACONSTRUCT
         {argExpOpt = NONE,
          argTyOpt = NONE,
          con = con,
          instTyList = instTyList,
          loc = loc},
       case instantiateCon (#ty con, instTyList) of
         ty =>
         (check
            (fn () =>
                mustBeCONSTRUCTty "TPDATACONSTRUCT" loc ty);
          ty))
    | TPDATACONSTRUCT {argExpOpt = SOME (argExp, argExpTy), con, instTyList,
                       loc} =
      (C.TPDATACONSTRUCT
         {argExpOpt = SOME argExp,
          argTyOpt = SOME argExpTy,
          con = con,
          instTyList = instTyList,
          loc = loc},
       case instantiateCon (#ty con, instTyList) of
         T.FUNMty ([argTy], retTy) =>
         (check
            (fn () =>
                (* ToDo: check con vs tyCon *)
                (eqTy "TPDATACONSTRUCT" loc [(argTy, argExpTy)];
                 mustBeCONSTRUCTty "TPDATACONSTRUCT" loc retTy));
          retTy)
       | _ => raise Bug.Bug "TPDATACONSTRUCT")

  fun exnConTy (C.EXN exn) = #ty exn
    | exnConTy (C.EXEXN exexn) = #ty exexn

  fun TPEXNCONSTRUCT {argExpOpt = NONE, exn, instTyList, loc} =
      (C.TPEXNCONSTRUCT {argExpOpt = NONE,
                         argTyOpt = NONE,
                         exn = exn,
                         instTyList = instTyList,
                         loc = loc},
       case instantiateCon (exnConTy exn, instTyList) of
         ty =>
         (check
            (fn () =>
                eqTy "TPEXNCONSTRUCT" loc [(ty, BuiltinTypes.exnTy)]);
          ty))
    | TPEXNCONSTRUCT {argExpOpt = SOME (argExp, argExpTy), exn, instTyList,
                      loc} =
      (C.TPEXNCONSTRUCT {argExpOpt = SOME argExp,
                         argTyOpt = SOME argExpTy,
                         exn = exn,
                         instTyList = instTyList,
                         loc = loc},
       case TypesBasics.derefTy (instantiateCon (exnConTy exn, instTyList)) of
         T.FUNMty ([argTy], retTy) =>
         (check
            (fn () =>
                (eqTy "EXNCONSTRUCT" loc
                      [(T.FUNMty ([argTy], retTy),
                        T.FUNMty ([argExpTy], BuiltinTypes.exnTy))]));
          retTy)
       | _ => raise Bug.Bug "TPEXNCONSTRUCT")

  fun ffiStubTy ffity =
      case ffity of
        C.FFIBASETY (ty, loc) => ty
      | C.FFIFUNTY (attributes, argTys, varTys, retTys, loc) =>
        let
          val argTys = map ffiStubTy argTys
          val varTys = case varTys of NONE => nil | SOME l => map ffiStubTy l
          val retTys = map ffiStubTy retTys
        in
          T.FUNMty ([tupleTy (argTys @ varTys)], tupleTy retTys)
        end
      | C.FFIRECORDTY (fields, loc) =>
        T.RECORDty
          (foldl
             (fn ((k, v), m) => RecordLabel.Map.insert (m, k, ffiStubTy v))
             RecordLabel.Map.empty
             fields)

  fun TPFFIIMPORT_FUN {funExp = (funExp, funTy), ffiTy, loc} =
      let
        val stubTy = ffiStubTy ffiTy
      in
        check
          (fn () =>
              eqTy "TPFFIIMPORT_FUN" loc [(funTy, BuiltinTypes.codeptrTy)]);
        (C.TPFFIIMPORT {funExp = C.TPFFIFUN (funExp, funTy),
                        ffiTy = ffiTy,
                        stubTy = stubTy,
                        loc = loc},
         stubTy)
      end

  fun TPFFIIMPORT_EXT {funExp = symbol, ffiTy, loc} =
      let
        val stubTy = ffiStubTy ffiTy
      in
        (C.TPFFIIMPORT {funExp = C.TPFFIEXTERN symbol,
                        ffiTy = ffiTy,
                        stubTy = stubTy,
                        loc = loc},
         stubTy)
      end

  fun TPTAPP {exp, instTyList = nil, loc} = exp
    | TPTAPP {exp = (exp, expTy), instTyList as _::_, loc} =
      (C.TPTAPP
         {exp = exp,
          expTy = expTy,
          instTyList = instTyList,
          loc = loc},
       TypesBasics.tpappTy (expTy, instTyList))

  fun TPPOLY {btvEnv, constraints, exp = (exp, ty), loc} =
      case BoundTypeVarID.Map.isEmpty btvEnv of
        true => (exp, ty)
      | false =>
        (C.TPPOLY
           {btvEnv = btvEnv,
            constraints = constraints,
            exp = exp,
            expTyWithoutTAbs = ty,
            loc = loc},
         T.POLYty
           {boundtvars = btvEnv,
            constraints = constraints,
            body = ty})

  fun TPFNM {argVarList, bodyExp = (bodyExp, bodyTy), loc} =
      (C.TPFNM
         {argVarList = argVarList,
          bodyExp = bodyExp,
          bodyTy = bodyTy,
          loc = loc},
       T.FUNMty (map #ty argVarList, bodyTy))

  fun TPPOLYFNM {btvEnv, constraints, argVarList,
                 bodyExp = (bodyExp, bodyTy), loc} =
      case BoundTypeVarID.Map.isEmpty btvEnv of
        true =>
        TPFNM {argVarList = argVarList,
               bodyExp = (bodyExp, bodyTy),
               loc = loc}
      | false =>
        (C.TPPOLYFNM
           {btvEnv = btvEnv,
            constraints = constraints,
            argVarList = argVarList,
            bodyExp = bodyExp,
            bodyTy = bodyTy,
            loc = loc},
         T.POLYty
           {boundtvars = btvEnv,
            constraints = constraints,
            body = T.FUNMty (map #ty argVarList, bodyTy)})

  fun TPAPPM {funExp = (funExp, funTy), argExpList, loc} =
      let
        val (argExpList, argTyList) = ListPair.unzip argExpList
      in
        (C.TPAPPM
           {funExp = funExp,
            funTy = funTy,
            argExpList = argExpList,
            loc = loc},
         case TypesBasics.derefTy funTy of
           ty as T.FUNMty (_, retTy) =>
           (check
              (fn () =>
                  eqTy "TPAPPM" loc [(ty, T.FUNMty (argTyList, retTy))]);
            retTy)
         | ty =>
           (fail1 "not a function" loc ty;
            raise Bug.Bug "TPAPPM"))
      end

  fun checkMatch loc matchTy {args:pat list, body=(_,ty):exp} =
       let
         exception ERROR
       in
         eqTy "match" loc [(T.FUNMty (map #2 args, ty), matchTy)];
         ignore
           (foldl
              (fn ((_,_,v),z) =>
                  VarID.Map.unionWith (fn _ => raise ERROR) (v, z))
              VarID.Map.empty
              args)
         handle ERROR =>
                (printE "<<<<<<<<<<<<<<<<<<<\nduplicate PTVAR at ";
                 app (fn (pat, _, _) =>
                         (printE (Bug.prettyPrint (C.format_tppat pat));
                          printE "\n"))
                     args;
                 printE "\n>>>>>>>>>>>>>>>>>>>\n")
       end

  fun TPCASEM {caseKind, expList, ruleList = nil, loc} =
      raise Bug.Bug "TPCASEM"
    | TPCASEM {caseKind, expList, ruleList as {body=(_,bodyTy),...}::_, loc} =
      let
        val (expList, expTyList) = ListPair.unzip expList
      in
        check
          (fn () =>
              app (checkMatch loc (T.FUNMty (expTyList, bodyTy))) ruleList);
        (C.TPCASEM
           {caseKind = caseKind,
            expList = expList,
            expTyList = expTyList,
            ruleList =
              map (fn {args, body = (body, _)} =>
                      {args = map #1 args, body = body})
                  ruleList,
            ruleBodyTy = bodyTy,
            loc = loc},
         bodyTy)
      end

  fun TPSEQ {expList = nil, loc} =
      raise Bug.Bug "TPSEQ"
    | TPSEQ {expList = [exp], loc} = exp
    | TPSEQ {expList as _::_, loc} =
      let
        val (expList, expTyList) = ListPair.unzip expList
      in
        (C.TPSEQ
           {expList = expList,
            expTyList = expTyList,
            loc = loc},
         List.last expTyList)
      end

  fun TPLET {decls, body = nil, loc} =
      raise Bug.Bug "TPLET"
    | TPLET {decls=nil, body=[exp], loc} = exp
    | TPLET {decls=nil, body as _::_, loc} =
      TPSEQ {expList = body, loc = loc}
    | TPLET {decls, body as _::_, loc} =
      let
        val (body, tys) = ListPair.unzip body
      in
        (C.TPLET
           {decls = decls,
            body = body,
            tys = tys,
            loc = loc},
         List.last tys)
      end

  fun TPMONOLET {binds=nil, bodyExp, loc} = bodyExp
    | TPMONOLET {binds, bodyExp = (bodyExp, bodyTy), loc} =
      (C.TPMONOLET
         {binds =
            map (fn ({id, ty, path, opaque}, (exp, expTy)) =>
                    ({id = id, ty = expTy, path = path, opaque = opaque}, exp))
                binds,
          bodyExp = bodyExp,
          loc = loc},
       bodyTy)

  fun TPRAISE {exp = (exp, expTy), ty, loc} =
      (check
         (fn () =>
             eqTy "TPRAISE" loc [(expTy, BuiltinTypes.exnTy)]);
       (C.TPRAISE {exp = exp, ty = ty, loc = loc},
        ty))

  fun TPHANDLE {exp = (exp, expTy), exnVar, handler = (handler, handlerTy),
                loc} =
      (check
         (fn () =>
             (eqTy "TPHANDLE" loc
                   [(expTy, handlerTy),
                    (#ty exnVar, BuiltinTypes.exnTy)]));
       (C.TPHANDLE
          {exp = exp,
           exnVar = exnVar,
           handler = handler,
           resultTy = expTy,
           loc = loc},
        expTy))

  fun TPRECORD {fields, loc} =
      let
        val exps = RecordLabel.Map.map (fn (e,_) => e) fields
        val tys = RecordLabel.Map.map (fn (_,t) => t) fields
        val recordTy = T.RECORDty tys
      in
        (C.TPRECORD
           {fields = exps,
            recordTy = recordTy,
            loc = loc},
         recordTy)
      end

  fun selectTy btvEnv (label, ty) =
      let
        val fields =
            case TypesBasics.derefTy ty of
              T.RECORDty fields => SOME fields
            | T.BOUNDVARty tid =>
              (case btvEnv of
                 NONE => NONE
               | SOME btvEnv =>
                 case BoundTypeVarID.Map.find (btvEnv, tid) of
                   SOME (T.KIND {tvarKind = T.REC fields, ...}) => SOME fields
                 | _ => NONE)
            | T.DUMMYty (_, T.KIND {tvarKind = T.REC fields, ...}) =>
              SOME fields
            | _ => NONE
      in
        case fields of
          NONE => raise Bug.Bug "selectTy"
        | SOME fields =>
          case RecordLabel.Map.find (fields, label) of
            NONE => raise Bug.Bug "selectTy"
          | SOME ty => ty
      end

  fun TPSELECT btvEnv {exp = (exp, expTy), label, loc} =
      let
        val resultTy = selectTy btvEnv (label, expTy)
      in
        (C.TPSELECT
           {exp = exp,
            expTy = expTy,
            label = label,
            resultTy = resultTy,
            loc = loc},
         resultTy)
      end

  fun TPMODIFY btvEnv {recordExp = (recordExp, recordTy), label,
                       elementExp = (elementExp, elementTy), loc} =
      (check
         (fn () =>
             eqTy "TPMODIFY" loc
                  [(elementTy, selectTy btvEnv (label, recordTy))]);
       (C.TPMODIFY
          {recordExp = recordExp,
           recordTy = recordTy,
           label = label,
           elementExp = elementExp,
           elementTy = elementTy,
           loc = loc},
        recordTy))

  fun TPPRIMAPPLY {primOp, instTyList, argExp = (argExp, argExpTy), loc} =
      (C.TPPRIMAPPLY
         {primOp = primOp,
          instTyList = instTyList,
          argExp = argExp,
          argTy = argExpTy,
          loc = loc},
       case TypesBasics.derefTy
              (TypesBasics.tpappTy (#ty primOp, instTyList)) of
         T.FUNMty ([argTy], retTy) =>
         (check
            (fn () =>
                eqTy "TPPRIMAPPLY" loc [(argTy, argExpTy)]);
          retTy)
       | _ => raise Bug.Bug "TPPRIMAPPLY")

  fun TPOPRIMAPPLY {oprimOp, instTyList, argExp = (argExp, argExpTy), loc} =
      (C.TPOPRIMAPPLY
         {oprimOp = oprimOp,
          instTyList = instTyList,
          argExp = argExp,
          argTy = argExpTy,
          loc = loc},
       case TypesBasics.derefTy
              (TypesBasics.tpappTy (#ty oprimOp, instTyList)) of
         T.FUNMty ([argTy], retTy) =>
         (check
            (fn () =>
                eqTy "TPOPRIMAPPLY" loc [(argTy, argExpTy)]);
          retTy)
       | _ => raise Bug.Bug "TPOPRIMAPPLY")

  fun TPJOIN {isJoin, args = ((exp1, ty1), (exp2, ty2)), ty, loc} =
      (C.TPJOIN
         {args = (exp1, exp2),
          argtys = (ty1, ty2),
          ty = ty,
          isJoin = isJoin,
          loc = loc},
       (* ToDo: check ty vs ty1, ty2 *)
       ty)

  fun TPDYNAMIC {exp = (exp, expTy), elemTy, coerceTy, loc} =
       (C.TPDYNAMIC
          {exp = exp,
           ty = expTy,
           elemTy = elemTy,
           coerceTy = coerceTy,
           loc = loc},
        coerceTy)

  fun TPDYNAMICIS {exp = (exp, expTy), elemTy, coerceTy, loc} =
       (C.TPDYNAMICIS
          {exp = exp,
           ty = expTy,
           elemTy = elemTy,
           coerceTy = coerceTy,
           loc = loc},
        coerceTy)

  fun TPDYNAMICNULL {ty, coerceTy, loc} =
       (C.TPDYNAMICNULL {ty = ty, coerceTy = coerceTy, loc = loc},
        coerceTy)

  fun TPDYNAMICTOP {ty, coerceTy, loc} =
       (C.TPDYNAMICTOP {ty = ty, coerceTy = coerceTy, loc = loc},
        coerceTy)

  fun TPDYNAMICVIEW {exp = (exp, expTy), elemTy, coerceTy, loc} =
       (C.TPDYNAMICVIEW
          {exp = exp,
           ty = expTy,
           elemTy = elemTy,
           coerceTy = coerceTy,
           loc = loc},
        coerceTy)

  fun TPDYNAMICCASE {groupListTerm = (exp,_), groupListTy, dynamicTerm = (dynamicExp,_), dynamicTy, elemTy, ruleBodyTy, loc} =
       (C.TPDYNAMICCASE
          {groupListTerm = exp,
           groupListTy = groupListTy,
           dynamicTerm = dynamicExp,
           dynamicTy = dynamicTy,
           elemTy = elemTy,
           ruleBodyTy=ruleBodyTy,
           loc = loc},
        ruleBodyTy)

  val TPPATERROR =
      (C.TPPATERROR (T.ERRORty, Loc.noloc), T.ERRORty, VarID.Map.empty)

  fun TPPATCONSTANT (x as (constant, ty, loc)) =
      (C.TPPATCONSTANT x, ty, VarID.Map.empty)

  fun TPPATVAR (x as {id, path, ty, opaque}) =
      (C.TPPATVAR x, ty, VarID.Map.singleton (id, x))

  fun TPPATWILD (x as (ty, loc)) =
      (C.TPPATWILD x, ty, VarID.Map.empty)

  fun TPPATDATACONSTRUCT {conPat, instTyList, argPatOpt = NONE, loc} =
      let
        val patTy = TypesBasics.tpappTy (#ty conPat, instTyList)
      in
        check
          (fn () =>
              mustBeCONSTRUCTty "TPPATDATACONSTRUCT" loc patTy);
        (C.TPPATDATACONSTRUCT
           {conPat = conPat,
            instTyList = instTyList,
            argPatOpt = NONE,
            patTy = patTy,
            loc = loc},
         patTy,
         VarID.Map.empty)
      end
    | TPPATDATACONSTRUCT {conPat, instTyList,
                          argPatOpt = SOME (argPat, argPatTy, argPatVars),
                          loc} =
      let
        val patTy =
            case TypesBasics.tpappTy (#ty conPat, instTyList) of
              T.FUNMty ([argTy], retTy) =>
              (check
                 (fn () =>
                     (eqTy "TPPATDATACONSTRUCT" loc [(argTy, argPatTy)];
                      mustBeCONSTRUCTty "TPPATDATACONSTRUCT" loc retTy));
               retTy)
            | _ => raise Bug.Bug "TPPATDATACONSTRUCT"
      in
        (C.TPPATDATACONSTRUCT
           {conPat = conPat,
            instTyList = instTyList,
            argPatOpt = SOME argPat,
            patTy = patTy,
            loc = loc},
         patTy,
         argPatVars)
      end

  fun TPPATEXNCONSTRUCT {exnPat, instTyList, argPatOpt = NONE, loc} =
      let
        val patTy = TypesBasics.tpappTy (exnConTy exnPat, instTyList)
      in
        check
          (fn () =>
              mustBeCONSTRUCTty "TPPATEXNCONSTRUCT" loc patTy);
        (C.TPPATEXNCONSTRUCT
           {exnPat = exnPat,
            instTyList = instTyList,
            argPatOpt = NONE,
            patTy = patTy,
            loc = loc},
         patTy,
         VarID.Map.empty)
      end
    | TPPATEXNCONSTRUCT {exnPat, instTyList,
                         argPatOpt = SOME (argPat, argPatTy, argPatVars),
                         loc} =
      let
        val patTy =
            case TypesBasics.tpappTy (exnConTy exnPat, instTyList) of
              T.FUNMty ([argTy], retTy) =>
              (check
                 (fn () =>
                     (eqTy "TPPATEXNCONSTRUCT" loc [(argTy, argPatTy)];
                      mustBeCONSTRUCTty "TPPATEXNCONSTRUCT" loc retTy));
               retTy)
            | _ => raise Bug.Bug "TPPATDATACONSTRUCT"
      in
        (C.TPPATEXNCONSTRUCT
           {exnPat = exnPat,
            instTyList = instTyList,
            argPatOpt = SOME argPat,
            patTy = patTy,
            loc = loc},
         patTy,
         argPatVars)
      end

  fun TPPATLAYERED {varPat = (varPat, varTy, varVars),
                    asPat = (asPat, asTy, asVars), loc} =
      (check
         (fn () =>
             eqTy "TPPATLAYERED" loc [(varTy, asTy)]);
       (C.TPPATLAYERED
          {varPat = varPat,
           asPat = asPat,
           loc = loc},
        varTy,
        VarID.Map.unionWith
          (fn _ => raise Bug.Bug "TPPATLAYERED")
          (varVars, asVars)))

  fun TPPATRECORD btvEnv {fields, recordTy, loc} =
      let
        val pats = RecordLabel.Map.map (fn (p,_,_) => p) fields
        val tys = RecordLabel.Map.map (fn (_,t,_) => t) fields
        val recordTy =
            case recordTy of
              NONE => T.RECORDty tys
            | SOME recordTy =>
              (check
                 (fn () =>
                     eqTy "TPPATRECORD" loc
                          (RecordLabel.Map.listItems
                             (RecordLabel.Map.mapi
                                (fn (label, ty) =>
                                    (ty, selectTy btvEnv (label, recordTy)))
                                tys)));
               recordTy)
      in
        (C.TPPATRECORD
           {fields = pats,
            recordTy = recordTy,
            loc = loc},
         recordTy,
         RecordLabel.Map.foldl
           (fn ((_,_,v):pat,z) =>
               VarID.Map.unionWith
                 (fn _ => raise Bug.Bug "TPPATRECORD")
                 (v, z))
           VarID.Map.empty
           fields)
      end

  fun patVars (pats : pat list) =
      foldl (fn ((_,_,v),z) =>
                VarID.Map.unionWith
                  (fn _ => raise Bug.Bug "patVars")
                  (v, z))
            VarID.Map.empty
            pats

  type env =
      {
        exnEnv : Types.exnInfo ExnID.Map.map,
        exExnEnv : Types.exExnInfo LongsymbolEnv.map,
        varEnv : Types.varInfo VarID.Map.map,
        exVarEnv : Types.exVarInfo LongsymbolEnv.map,
        btvEnv : Types.kind BoundTypeVarID.Map.map
      }

  val emptyEnv : env =
      {
        exnEnv = ExnID.Map.empty,
        exExnEnv = LongsymbolEnv.empty,
        varEnv = VarID.Map.empty,
        exVarEnv = LongsymbolEnv.empty,
        btvEnv = BoundTypeVarID.Map.empty
      }

  fun extendEnv (env1:env, env2:env) : env =
      {exnEnv = ExnID.Map.unionWith #2 (#exnEnv env1, #exnEnv env2),
       exExnEnv = LongsymbolEnv.unionWith #2 (#exExnEnv env1, #exExnEnv env2),
       varEnv = VarID.Map.unionWith #2 (#varEnv env1, #varEnv env2),
       exVarEnv = LongsymbolEnv.unionWith #2 (#exVarEnv env1, #exVarEnv env2),
       btvEnv = BoundTypeVarID.Map.unionWith #2 (#btvEnv env1, #btvEnv env2)}

  fun exnEnv x = emptyEnv # {exnEnv = x}
  fun exExnEnv x = emptyEnv # {exExnEnv = x}
  fun varEnv x = emptyEnv # {varEnv = x}
  fun exVarEnv x = emptyEnv # {exVarEnv = x}
  fun btvEnv x = emptyEnv # {btvEnv = x}

  fun makeExnEnv l =
      exnEnv
        (foldl
           (fn (x, z) => ExnID.Map.insert (z, #id x, x))
           ExnID.Map.empty
           l)

  fun makeExExnEnv l =
      exExnEnv
        (foldl
           (fn (x, z) => LongsymbolEnv.insert (z, #path x, x))
           LongsymbolEnv.empty
           l)

  fun makeVarEnv l =
      varEnv
        (foldl
           (fn (x:Types.varInfo, z) => VarID.Map.insert (z, #id x, x))
           VarID.Map.empty
           l)

  fun makeExVarEnv l =
      exVarEnv
        (foldl
           (fn (x:Types.exVarInfo, z) => LongsymbolEnv.insert (z, #path x, x))
           LongsymbolEnv.empty
           l)

  fun clsVar (boundtvars, constraints) (var:Types.varInfo) =
      var # {ty = T.POLYty {boundtvars = boundtvars,
                            constraints = constraints,
                            body = #ty var}}

  fun clsVarEnv abs vars =
      makeVarEnv (map (clsVar abs) vars)

  fun TPEXD (x as (binds, loc)) =
      (C.TPEXD x, makeExnEnv (map #exnInfo binds))

  fun TPEXNTAGD (x as ({exnInfo, varInfo}, loc)) =
      (check
         (fn () =>
             eqTy "TPEXNTAGD" loc [(#ty varInfo, BuiltinTypes.exntagTy)]);
       (C.TPEXNTAGD x, makeExnEnv [exnInfo]))

  fun TPEXPORTEXN x =
      (C.TPEXPORTEXN x, emptyEnv)

  fun TPEXPORTRECFUNVAR x =
      (C.TPEXPORTRECFUNVAR x, emptyEnv)

  fun TPEXPORTVAR x =
      (C.TPEXPORTVAR x, emptyEnv)

  fun TPEXTERNEXN (x, provider) =
      (C.TPEXTERNEXN (x, provider), makeExExnEnv [x])

  fun TPBUILTINEXN x =
      (C.TPBUILTINEXN x, makeExExnEnv [x])

  fun TPEXTERNVAR (x, provider) =
      (C.TPEXTERNVAR (x, provider), makeExVarEnv [x])

  fun funrecbind loc {funVarInfo : Types.varInfo, ruleList = nil} =
      raise Bug.Bug "funrecbind"
    | funrecbind loc {funVarInfo, ruleList as {args, body = (_, bodyTy)}::_} =
      let
        val argTyList = map (fn (_,t,_) => t) args
        val funTy = T.FUNMty (argTyList, bodyTy)
      in
        check
          (fn () =>
              (app (checkMatch loc funTy) ruleList;
               eqTy "funrecbind" loc [(#ty funVarInfo, funTy)]));
        {argTyList = argTyList,
         bodyTy = bodyTy,
         funVarInfo = funVarInfo,
         ruleList = map (fn {args, body = (body, _)} =>
                            {args = map #1 args, body = body})
                        ruleList}
      end

  fun TPFUNDECL (recbinds, loc) =
      let
        val recbinds = map (funrecbind loc) recbinds
      in
        (C.TPFUNDECL (recbinds, loc),
         makeVarEnv (map #funVarInfo recbinds))
      end

  fun TPPOLYFUNDECL {btvEnv, constraints, recbinds, loc} =
      let
        val recbinds = map (funrecbind loc) recbinds
      in
        (C.TPPOLYFUNDECL
           {btvEnv = btvEnv,
            constraints = constraints,
            recbinds = recbinds,
            loc = loc},
         clsVarEnv (btvEnv, constraints) (map #funVarInfo recbinds))
      end

  fun TPVAL (binds, loc) =
      let
        val newBinds =
            map (fn (var, (exp, ty)) => (var # {ty = ty}, exp)) binds
      in
        (C.TPVAL (newBinds, loc),
         makeVarEnv (map #1 newBinds))
      end

  fun TPVALREC (recbinds, loc) =
      let
        val recbinds =
            map (fn {var, exp = (exp, expTy)} =>
                    {var = var, exp = exp, expTy = expTy})
                recbinds
      in
        check
          (fn () =>
              eqTy "TPVALREC" loc
                   (map (fn {var, exp, expTy} => (#ty var, expTy)) recbinds));
        (C.TPVALREC (recbinds, loc),
         makeVarEnv (map #var recbinds))
      end

  fun TPVALPOLYREC {btvEnv, constraints, recbinds, loc} =
      let
        val recbinds =
            map (fn {var, exp = (exp, expTy)} =>
                    {var = var, exp = exp, expTy = expTy})
                recbinds
      in
        check
          (fn () =>
              eqTy "TPVALPOLYREC" loc
                   (map (fn {var, exp, expTy} => (#ty var, expTy)) recbinds));
        (C.TPVALPOLYREC
           {btvEnv = btvEnv,
            constraints = constraints,
            recbinds = recbinds,
            loc = loc},
         clsVarEnv (btvEnv, constraints) (map #var recbinds))
      end

end
