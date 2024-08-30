(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure CoerceRank1 =
struct
local
  structure T = Types
  structure TC = TypedCalc
  structure TCU = TypedCalcUtils
  structure TB = TypesBasics
  structure P = Printers
  structure E = TypeInferenceError
in

  type ty = Types.ty
  type tpexp = TypedCalc.tpexp
  type varInfo = Types.varInfo

  exception NotSupported
  exception NotFree
  fun bug s = Bug.Bug ("CoereceRank1 " ^ s)

  datatype rank1Term
    = MONO of {exp : tpexp, ty : ty}
    | FN of {var : varInfo, domTy:ty,  body : rank1Term, bodyVar : varInfo, bind:tpexp}
      (* varInfo and bind are added to fix the bug 382_provideEvalOrder *)
    | RECORD of {record:rank1Term RecordLabel.Map.map, var : varInfo, bind:tpexp}
    | DATA of {exp : tpexp, ty: ty}

  fun printTerm term =
      case term of
        MONO {exp, ty} => (P.print "MONO:"; P.printTpexp exp; P.print "\n")
      | FN {var, domTy,  body, bodyVar, bind} => (P.print "FN\n")
      | RECORD _ => (P.print "RECORD\n")
      | DATA _ => (P.print "POLYDATA\n")

  val loc = Loc.noloc
  fun toMonoTerm term =
      case term of
        MONO mono => mono
      | FN {var, domTy,  body, bodyVar, bind} =>
        let
          val {exp, ty = bodyTy} = toMonoTerm body
          val bindExp = 
              TC.TPMONOLET
                {binds = [(bodyVar, bind)],
                 bodyExp = exp,
                 loc = loc}
          val fnExp = TC.TPFNM {argVarList = [var],
                           bodyTy = bodyTy,
                           bodyExp = bindExp,
                           loc = loc}
        in
          {exp = fnExp,
           ty = T.FUNMty ([domTy], bodyTy)}
        end
      | RECORD {record = fields, var, bind} =>
        let
          val (tyFields, expFields) =
              RecordLabel.Map.foldli
                (fn (l, term, (tyFields, expFields)) =>
                    let
                      val {exp, ty} = toMonoTerm term
                    in
                      (RecordLabel.Map.insert(tyFields, l, ty),
                       RecordLabel.Map.insert(expFields, l, exp))
                    end)
                (RecordLabel.Map.empty,RecordLabel.Map.empty)
                fields
          val recordTy = T.RECORDty tyFields
          val tpexp = 
              TC.TPMONOLET
                {binds = [(var, bind)],
                 bodyExp = TC.TPRECORD {fields = expFields, loc = loc, recordTy = tyFields},
                 loc = loc}
        in
          {ty = recordTy, exp = tpexp}
        end          
      | DATA {exp, ty} => {exp = exp, ty = ty}
      
  fun instExp {exp:tpexp, ty:ty} =
      let
        val ty = TB.derefTy ty
      in
        if TB.monoTy ty then MONO {exp = exp, ty = ty}
        else
          case ty of
            T.FUNMty ([domTy], ranTy) =>
            let
              val bodyVar = TCU.newTCVarInfo loc ranTy
              val var = TCU.newTCVarInfo loc domTy
              val body = TC.TPAPPM {funExp = exp,
                                    funTy = ty,
                                    argExpList = [TC.TPVAR var],
                                    loc = loc}
              val rank1Term = instExp {exp = TC.TPVAR bodyVar, ty = ranTy}
            in
              FN {var = var, domTy = domTy, body = rank1Term, bodyVar=bodyVar, bind = body}
            end
          | T.RECORDty tyRecordLabelMapMap =>
            let
              val var = TCU.newTCVarInfo loc ty
              val rank1TermField = 
                  RecordLabel.Map.mapi
                    (fn (l, filedTy) =>
                        let
                          val exp = TC.TPSELECT {label = l, 
                                                 exp = TC.TPVAR var, 
                                                 expTy = ty,
                                                 resultTy = filedTy,
                                                 loc = loc}
                          val rank1Term = instExp {exp = exp, ty = filedTy}
                        in
                          rank1Term
                        end)
                    tyRecordLabelMapMap
            in
              RECORD {record=rank1TermField, var = var, bind = exp}
            end
          | T.POLYty {boundtvars, constraints = nil, body} =>
            let
              val subst = TB.freshSubst boundtvars
              val freeTyvars = BoundTypeVarID.Map.listItems subst
              val newBodyTy = TB.substBTvar subst body
            in
              (case TB.derefTy newBodyTy of
                 T.FUNMty ([domTy], ranTy) =>
                 let
                   val newExp = 
                       TC.TPTAPP {exp = exp, expTy = ty, instTyList = freeTyvars, loc = loc}
                   val bodyVar = TCU.newTCVarInfo loc ranTy
                   val var = TCU.newTCVarInfo loc domTy
                   val body = TC.TPAPPM {funExp = newExp,
                                         funTy = newBodyTy,
                                         argExpList = [TC.TPVAR var],
                                         loc = loc}
                   val rank1Term = instExp {exp = TC.TPVAR bodyVar, ty = ranTy}
                 in
                   FN {domTy = domTy, var = var, body = rank1Term, bodyVar = bodyVar, bind = body}
                 end
               | T.RECORDty tyRecordLabelMapMap =>
                 let
                   val newExp = 
                       TC.TPTAPP {exp = exp, expTy = ty, instTyList = freeTyvars, loc = loc}
                   val var = TCU.newTCVarInfo loc newBodyTy
                   val rank1TermField = 
                       RecordLabel.Map.mapi
                       (fn (l, ty) =>
                           let
                             val exp = TC.TPSELECT {label = l, 
                                                    exp = TC.TPVAR var, 
                                                    expTy = newBodyTy,
                                                    resultTy = ty,
                                                    loc = loc}
                             val rank1Term = instExp {exp = exp, ty = ty}
                           in
                             rank1Term
                           end)
                       tyRecordLabelMapMap
                 in
                   RECORD {record = rank1TermField, var = var, bind = newExp}
                 end
               | T.CONSTRUCTty _ =>
                 let
                   val newExp = 
                       case exp of
                         TC.TPDATACONSTRUCT {con,instTyList=NONE,argExpOpt=NONE,loc}
                         => TC.TPDATACONSTRUCT
                              {con=con,
                               instTyList= SOME freeTyvars,
                               argExpOpt=NONE,
                               loc=loc}
                       | _ => TC.TPTAPP {exp = exp, expTy = ty, instTyList = freeTyvars, loc = loc}
                 in
                   DATA {exp = newExp, ty = newBodyTy}
                 end
               | _ => 
                 (
                  P.print "tpexp\n";
                  P.printTpexp exp;
                  P.print "\nty\n";
                  P.printTy ty;
                  P.print "\n";
                 raise NotSupported
                 )
              )
            end
          | _ => 
            (
             P.print "tpexp\n";
             P.printTpexp exp;
             P.print "\nty\n";
             P.printTy ty;
             P.print "\n";
             raise NotSupported
            )
      end

  fun coerceExp revealTy {depth, term, toTy} =
    let
      fun coerce x = coerceExp revealTy x
      fun isFree ty =
          case TB.derefTy ty of
	  (T.TYVARty (ref (T.TVAR {lambdaDepth,...}))) =>
	  if T.strictlyYoungerDepth {contextDepth = depth, tyvarDepth = lambdaDepth}
	  then ()
	  else  raise NotFree
	| ty => (P.printTy ty; raise (bug "isFree"))
    in
      if TB.monoTy toTy then
        let
          val {exp, ty} = toMonoTerm term
          val tempToTy = revealTy toTy
          val tempTy = ty
          val _ = Unify.unify ([(tempToTy, tempTy)])
        in
          {exp = exp, ty = toTy}
        end
      else
        case (TB.derefTy toTy, term) of
          (T.POLYty {boundtvars, constraints = nil, body}, MONO _) =>
          raise NotFree
        | (T.POLYty {boundtvars, constraints = nil, body = T.FUNMty([argTy], toTyBody)},
           FN {domTy, var, body, bodyVar, bind}) =>
          let
            val depth = depth + 1
            val subst =  TB.freshRigidSubstWithLambdaDepth depth boundtvars
            val freeTyvars = BoundTypeVarID.Map.listItems subst
            val argTy = TB.substBTvar subst argTy
            val toTyBody = TB.substBTvar subst toTyBody
            val tempArgTy = revealTy argTy
            val _ = Unify.unify([(tempArgTy, domTy)])
            val {exp = newExp, ty = newToTyBody} =
                coerce {depth = depth, term = body, toTy = toTyBody}
            val _ = app isFree freeTyvars
            val btvs =
                foldl
                  (fn (ty, btvs) =>
                      case TB.derefTy ty of
                        T.TYVARty (r as ref(T.TVAR (k as {id, kind, ...}))) =>
                        let 
                          val btvid = BoundTypeVarID.generate ()
                        in
                          (r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                           BoundTypeVarID.Map.insert(btvs, btvid, kind))
                        end
                      | _ => raise Bug.Bug "generalizeTy")
                  BoundTypeVarID.Map.empty
                  freeTyvars
            val bindExp = 
                TC.TPMONOLET
                  {binds = [(bodyVar, bind)],
                   bodyExp = newExp,
                   loc = loc}
            val fnExp = TC.TPFNM {argVarList = [var],
                                  bodyTy = newToTyBody,
                                  bodyExp = bindExp,
                                  loc = loc}
          in
            {ty = T.POLYty {boundtvars = btvs, constraints = nil, 
                            body = T.FUNMty([argTy], newToTyBody)},
             exp = TC.TPPOLY
                     {btvEnv=btvs, 
                      constraints=nil, 
                      expTyWithoutTAbs = T.FUNMty([argTy], newToTyBody),
                      exp = fnExp,
                      loc = loc}}
          end
        | (T.POLYty {boundtvars, constraints = nil, body = T.RECORDty tyFields},
           RECORD {record, var, bind}) =>
          let
            val depth = depth + 1
            val subst =  TB.freshRigidSubstWithLambdaDepth depth boundtvars
            val freeTyvars = BoundTypeVarID.Map.listItems subst
            val tyFields = RecordLabel.Map.map (TB.substBTvar subst) tyFields
            val expTyMap = RecordLabel.Map.mergeWith
                             (fn (SOME ty, SOME term) => 
                                 SOME (coerce {depth=depth, term = term, toTy = ty})
                               | _ => raise bug "incorrectField")
                             (tyFields, record)
            val _ = app isFree freeTyvars
            val tyFields = RecordLabel.Map.map (fn {exp, ty} => ty) expTyMap
            val expFields = RecordLabel.Map.map (fn {exp, ty} => exp) expTyMap
            val btvs =
                foldl
                  (fn (ty, btvs) =>
                      case TB.derefTy ty of
                        T.TYVARty (r as ref(T.TVAR (k as {id, kind, ...}))) =>
                        let 
                          val btvid = BoundTypeVarID.generate ()
                        in
                          (r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                           BoundTypeVarID.Map.insert(btvs, btvid, kind))
                        end
                      | _ => raise Bug.Bug "generalizeTy")
                  BoundTypeVarID.Map.empty
                  freeTyvars
            val recordTy = T.RECORDty tyFields
            val bodyTerm = 
                TC.TPMONOLET 
                {binds = [(var, bind)],
                 bodyExp = TC.TPRECORD {fields = expFields,
                                        loc= loc, 
                                        recordTy = tyFields},
                 loc = loc}
          in
            {ty = T.POLYty {boundtvars = btvs, constraints = nil,
                            body = recordTy},
             exp = TC.TPPOLY
                     {btvEnv=btvs, 
                      constraints=nil, 
                      expTyWithoutTAbs = recordTy,
                      exp = bodyTerm,
                      loc = loc}
            }
          end
        | (T.POLYty {boundtvars, constraints = nil, body = bodyTy as T.CONSTRUCTty _},
           term) =>
           let
             val depth = depth + 1
             val subst =  TB.freshRigidSubstWithLambdaDepth depth boundtvars
             val freeTyvars = BoundTypeVarID.Map.listItems subst
             val newBodyTy = TB.substBTvar subst bodyTy
             val tempBodyTy = revealTy newBodyTy
             val {exp, ty} = toMonoTerm term
             val _ = Unify.unify([(tempBodyTy, ty)])
             val _ = app isFree freeTyvars
             val btvs =
                 foldl
                   (fn (ty, btvs) =>
                       case TB.derefTy ty of
                         T.TYVARty (r as ref(T.TVAR (k as {id, kind, ...}))) =>
                         let 
                           val btvid = BoundTypeVarID.generate ()
                         in
                           (r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                            BoundTypeVarID.Map.insert(btvs, btvid, kind))
                         end
                       | _ => raise Bug.Bug "generalizeTy")
                   BoundTypeVarID.Map.empty
                   freeTyvars
           in
             {ty = T.POLYty {boundtvars = btvs, constraints = nil,
                             body = newBodyTy},
              exp = TC.TPPOLY
                      {btvEnv=btvs, 
                       constraints=nil,
                       expTyWithoutTAbs = newBodyTy, 
                       exp = exp,
                       loc = loc}
             }
           end
        | (T.RECORDty tyFields, RECORD {record, var, bind}) =>
          let
            val expTyMap = RecordLabel.Map.mergeWith
                           (fn (SOME ty, SOME term) => 
                               SOME (coerce {depth = depth, term = term, toTy = ty})
                             | _ => raise bug "incorrectField")
                           (tyFields, record)
            val tyFields = RecordLabel.Map.map (fn {exp, ty} => ty) expTyMap
            val expFields = RecordLabel.Map.map (fn {exp, ty} => exp) expTyMap
            val recordTy = T.RECORDty tyFields

          in
            {ty = recordTy,
             exp = TC.TPMONOLET
                     {binds = [(var, bind)],
                      bodyExp =  TC.TPRECORD {fields = expFields,
                                              loc= loc, 
                                              recordTy = tyFields},
                      loc = loc}
            }
          end
        | (T.FUNMty([argTy], bodyTy), FN {var, domTy, body, bodyVar, bind}) =>
          let
            val tempArgTy = revealTy argTy
            val _ = Unify.unify([(tempArgTy, domTy)])
            val {exp = newBodyExp, ty = newBodyTy} = 
                coerce {depth=depth, term = body, toTy = bodyTy}
          val bindExp = 
              TC.TPMONOLET
                {binds = [(bodyVar, bind)],
                 bodyExp = newBodyExp,
                 loc = loc}
            val fnExp = TC.TPFNM {argVarList = [var],
                                   bodyTy = newBodyTy,
                                   bodyExp = bindExp,
                                   loc = loc}
          in
            {exp = fnExp, ty = T.FUNMty([argTy], newBodyTy)}
          end
        | (toTy, MONO {exp, ty}) =>
          let
            val tempToTy = revealTy toTy
            val _ = Unify.unify([(tempToTy, ty)])
          in
            {exp = exp, ty = toTy}
          end
        | (ty, term) =>  
          (
           P.print "term\n";
           printTerm term;
           P.print "\nty\n";
           P.printTy ty;
           P.print "\n";
           raise NotSupported
          )
      end

   fun coerce {revealTyFrom, revealTyTo, loc, path, tpexp, tpexpTy, toTy} = 
       let
         val tpexpTy = revealTyFrom tpexpTy
         val {exp, ty} = 
             coerceExp 
               revealTyTo 
               {depth = 0, term = instExp {exp = tpexp, ty = tpexpTy}, toTy = toTy}
       in
         (ty, exp)
       end
       handle
       Unify.Unify =>
       (E.enqueueError 
          "Typeinf 019-1"
          (loc, E.SignatureMismatch ("019-1",{path=path, ty=tpexpTy, annotatedTy=toTy}));
        (T.ERRORty, TC.TPERROR))
     | NotFree => 
       (E.enqueueError 
          "Typeinf 019-2"
          (loc, E.SignatureMismatch ("019-2",{path=path, ty=tpexpTy, annotatedTy=toTy}));
        (T.ERRORty, TC.TPERROR))
     | NotSuported => 
       (E.enqueueError 
          "Typeinf 019-3"
          (loc, E.SignatureMismatch ("019-3",{path=path, ty=tpexpTy, annotatedTy=toTy}));
        (T.ERRORty, TC.TPERROR))
end
end
