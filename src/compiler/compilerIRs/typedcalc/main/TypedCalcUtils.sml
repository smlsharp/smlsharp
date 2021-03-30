(**
 * Utility functions to manipulate the typed pattern calculus.
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori 
 * @version $Id: TypedCalcUtils.sml,v 1.20.6.5 2010/01/29 06:41:34 hiro-en Exp $
 *)
structure TypedCalcUtils = struct
local 
  structure T = Types 
  structure TC = TypedCalc
  structure TB = TypesBasics
  structure BT = BuiltinTypes
  fun bug s = Bug.Bug ("TypedCalcUtil: " ^ s)
in
  fun newTCVarInfo loc (ty:T.ty) =
      let
        val newVarId = VarID.generate()
      in
        {path=[], id=newVarId, ty = ty, opaque=false}
      end
  fun getLocOfExp exp =
      case exp of
        TC.TPERROR => Loc.noloc
      | TC.TPCONSTANT {const, ty, loc} => loc
      | TC.TPVAR {path,...} => Symbol.longsymbolToLoc path
      | TC.TPEXVAR ({path,...}, loc) => loc
      | TC.TPRECFUNVAR {var={path,...},...} => Symbol.longsymbolToLoc path
      | TC.TPFNM  {loc,...} => loc
      | TC.TPAPPM {loc,...} => loc
      | TC.TPDATACONSTRUCT {loc,...} => loc
      | TC.TPEXNCONSTRUCT {loc,...} => loc
      | TC.TPEXNTAG {loc,...} => loc
      | TC.TPEXEXNTAG {loc,...} => loc
      | TC.TPCASEM {loc,...} => loc
      | TC.TPSWITCH {loc,...} => loc
      | TC.TPDYNAMICCASE {loc,...} => loc
      | TC.TPDYNAMICEXISTTAPP {loc,...} => loc
      | TC.TPPRIMAPPLY {loc,...} => loc
      | TC.TPOPRIMAPPLY {loc,...} => loc
      | TC.TPRECORD {loc,...} => loc
      | TC.TPSELECT {loc,...} => loc
      | TC.TPMODIFY {loc,...} => loc
      | TC.TPMONOLET {loc,...} => loc
      | TC.TPLET {decls, body, loc} => loc
      | TC.TPRAISE {exp, ty, loc} => loc
      | TC.TPHANDLE {loc,...} => loc
      | TC.TPTHROW {loc,...} => loc
      | TC.TPCATCH {loc,...} => loc
      | TC.TPPOLY {loc,...} => loc
      | TC.TPTAPP {loc,...} => loc
      | TC.TPCAST (toexo, ty, loc) => loc
      | TC.TPFFIIMPORT {loc,...} => loc
      | TC.TPFOREIGNSYMBOL {loc,...} => loc
      | TC.TPFOREIGNAPPLY {loc,...} => loc
      | TC.TPCALLBACKFN {loc,...} => loc
      | TC.TPSIZEOF (_, loc) => loc
      | TC.TPJOIN {loc, ...} => loc
      | TC.TPDYNAMIC {loc,...} => loc
      | TC.TPDYNAMICIS {loc,...} => loc
      | TC.TPDYNAMICNULL {loc,...} => loc
      | TC.TPDYNAMICTOP {loc,...} => loc
      | TC.TPDYNAMICVIEW {loc,...} => loc
      | TC.TPREIFYTY (ty,loc) => loc

  fun isAtom tpexp =
      case tpexp of
        TC.TPCONSTANT {const, loc, ty} => true
      | TC.TPVAR var => true
      | TC.TPEXVAR (exVarInfo, loc) => true
      | TC.TPRECFUNVAR {arity, var} => true
      | TC.TPFOREIGNSYMBOL _ => true
      | _ => false

  fun expansive tpexp =
      case tpexp of
        TC.TPCONSTANT _ => false
      | TC.TPVAR _ => false
      | TC.TPEXVAR (exVarInfo, loc) => false
      | TC.TPRECFUNVAR _ => false
      | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} => false
      | TC.TPEXNTAG {exnInfo, loc} => false
      | TC.TPEXEXNTAG {exExnInfo, loc} => false
      | TC.TPDATACONSTRUCT {con, instTyList, argExpOpt=NONE, loc} => false
      | TC.TPEXNCONSTRUCT {exn, argExpOpt=NONE, loc} => false
      | TC.TPDATACONSTRUCT {con={path, id, ty}, instTyList, argExpOpt= SOME tpexp, loc} =>
        let
          val tyCon = TB.tyConFromConTy ty
        in
          TypID.eq (#id tyCon, #id BT.refTyCon)  
          orelse expansive tpexp
        end
      | TC.TPEXNCONSTRUCT {exn, argExpOpt= SOME tpexp, loc} =>
        expansive tpexp
      | TC.TPRECORD {fields, recordTy=ty, loc=loc} =>
          RecordLabel.Map.foldli
          (fn (string, tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          fields
      |  (*  (re : bug 141_provide.sml)
             This deep expansive test is necessary to deal with the following
              structure S :> sig
                type 'a t
                val x : 'a t
              end =
              struct
              type 'a t = int * 'a list
              val x = (0, nil)
              end
           Since (0, nil) is compiled to (0, nil:['a. 'a list]) : int * ['a. 'a list],
           the compiler need to construct the following
             val x = (#1 x, #2 x {'x})
           For this to have the type ['a. int * 'a list], the compiler need to abstract 'x
           to form
             val x = ['a. (#1 x, #2 x {'a})]
         *)
        TC.TPSELECT {exp, expTy, label, loc, resultTy} => expansive exp
      | TC.TPMONOLET {binds=varPathInfoTpexpList, bodyExp=tpexp, loc} =>
          foldl
          (fn ((v,tpexp1), isExpansive) => isExpansive orelse expansive tpexp1)
          (expansive tpexp)
          varPathInfoTpexpList
      | TC.TPPOLY {exp=tpexp,...} => expansive tpexp
      | TC.TPTAPP {exp, ...} => expansive exp
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN (ptrExp, _), stubTy} => expansive ptrExp
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIEXTERN _, stubTy} => false
      | TC.TPFOREIGNAPPLY _ => true
      | TC.TPFOREIGNSYMBOL _ => false
      | TC.TPCALLBACKFN _ => false
      | TC.TPCAST ((tpexp, expTy), ty, loc) => expansive tpexp 
      | TC.TPCASEM _ => true
      | TC.TPSWITCH _ => true
      | TC.TPDYNAMICCASE _ => true
      | TC.TPDYNAMICEXISTTAPP _ => true
      | TC.TPPRIMAPPLY _ => true
      | TC.TPOPRIMAPPLY _ => true
      | TC.TPERROR => true
      | TC.TPAPPM _ => true
      | TC.TPMODIFY _ => true
      | TC.TPLET {decls, body, loc} => true
      | TC.TPRAISE _ => true
      | TC.TPHANDLE _ => true
      | TC.TPTHROW _ => true
      | TC.TPCATCH _ => true
      | TC.TPSIZEOF _ => true
      | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys, loc} =>
(* 2016-12-02 多相型は実行文であるため JOIN を expansiveとする；
        expansive arg1 andalso expansive arg2
*)
        true
      | TC.TPDYNAMIC {exp,ty,elemTy, coerceTy,loc} => true
      | TC.TPDYNAMICIS {exp,ty,elemTy, coerceTy,loc} => true
      | TC.TPDYNAMICNULL {ty, coerceTy,loc} => false
      | TC.TPDYNAMICTOP {ty, coerceTy,loc} => false
      | TC.TPDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | TC.TPREIFYTY _ => false

  fun nextDummyTy kind =
      T.DUMMYty (DummyTyID.generate (), kind)

  fun instantiateTv tv =
      case tv of
        ref (T.TVAR {kind as T.KIND {tvarKind, ...}, ...}) =>
        (case tvarKind of
           T.OCONSTkind (h::_) => tv := T.SUBSTITUTED h
         | T.OCONSTkind nil => raise Bug.Bug "instantiateTv OCONSTkind"
         | T.OPRIMkind {instances = (h::_),...} => tv := T.SUBSTITUTED h
         | T.OPRIMkind {instances = nil,...} =>
           raise Bug.Bug "instantiateTv OPRIMkind"
         | T.REC tyFields => tv := T.SUBSTITUTED (nextDummyTy kind)
         | T.UNIV => tv := T.SUBSTITUTED (nextDummyTy kind))
      | ref(T.SUBSTITUTED _) => ()

  (**
   * Make a fresh instance of a polytype and a term of that type.
   *)
  fun freshInst (ty,exp) =
      (* 2016-06-16 sasaki: インスタンス化した制約を返すよう変更 *)
      if TB.monoTy ty then (ty,nil,nil,exp)
      else
        let
          val expLoc = getLocOfExp exp
        in
          case ty of
            T.POLYty{boundtvars,body,constraints} =>
            let 
              val subst = TB.freshSubst boundtvars
              val bty = TB.substBTvar subst body
              val newExp = 
                  case exp of
                    TC.TPDATACONSTRUCT {con,instTyList=NONE,argExpOpt=NONE,loc}
                    => TC.TPDATACONSTRUCT
                         {con=con,
                          instTyList=SOME (BoundTypeVarID.Map.listItems subst),
                          argExpOpt=NONE, 
                          loc=loc}
                  | _ => TC.TPTAPP
                           {exp=exp,
                            expTy=ty,
                            instTyList=BoundTypeVarID.Map.listItems subst,
                            loc=expLoc}
              val bconstraints = 
                  List.map (fn c =>
                               case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                                 T.JOIN
                                     {res = TB.substBTvar subst res,
                                      args = (TB.substBTvar subst arg1,
                                              TB.substBTvar subst arg2), loc=loc})
                           constraints
              val (freshty, freshsubst, freshconstraints, freshexp) =
                  freshInst (bty,newExp)
            in  
              (freshty,
               BoundTypeVarID.Map.listItems subst @ freshsubst,
               bconstraints @ freshconstraints,
               freshexp)
            end
          | T.FUNMty (tyList, bodyTy) =>
            (* 
              2015-10-31 ohori: bug 321; we must preserve evaluation order

              OLD: (fn f:ty => fn x :ty1 => inst(f x)) exp 
              NEW:  fn {x1:ty1,...,xn:tyn} => inst(exp {x1,...,xn})
            *)
              let
                val (exp, mkNewExp) = 
                    if expansive exp then 
                      let
                        val newVar = newTCVarInfo expLoc ty
                      in
                        (TC.TPVAR newVar,
                         fn x => TC.TPMONOLET {binds = [(newVar, exp)],
                                               bodyExp = x,
                                               loc=expLoc}
                        )
                      end
                    else (exp, fn x => x)
                val argVarList = map (newTCVarInfo expLoc) tyList
                val argExpList = map (fn x => TC.TPVAR x) argVarList
                val (instBodyTy, instSubst, instConstraints, instBody) =
                    freshInst
                      (bodyTy,
                       TC.TPAPPM{funExp=exp,
                                 funTy=ty,
                                 argExpList=argExpList,
                                 loc=expLoc})
                val newExp = 
                  TC.TPFNM
                    {argVarList = argVarList,
                     bodyTy = instBodyTy,
                     bodyExp = instBody,
                     loc = expLoc}
              in 
                (T.FUNMty(tyList, instBodyTy), instSubst, instConstraints, mkNewExp newExp)
              end
          | T.RECORDty tyFields => 
            (* 
              OLD: (fn r => {...,l=inst(x.l,ty) ...}) ex 
              NEW: let val xex = ex in {...,l=inst(x.l,ty) ...}
            *)
              (case exp of
                 TC.TPRECORD {fields, recordTy=_, loc=loc} =>
                 let
                   val (bindsRev, bindSubst, bindConstraints, newTyFields, newFields) =
                       RecordLabel.Map.foldli
                         (fn (l, fieldTy, (bindsRev,bindSubst,bindConstraints,newTyFields,newFields)) =>
                             case RecordLabel.Map.find(fields,l) of
                                SOME field =>
                                let
                                  val (ty',subst',constraints',exp') = freshInst (fieldTy, field)
                                  val newTyFields = RecordLabel.Map.insert(newTyFields, l, ty')
                                  val (bindsRev, newFields) =
                                      if isAtom exp' then 
                                        (bindsRev, RecordLabel.Map.insert(newFields, l, exp'))
                                      else
                                        let
                                          val fieldVar = newTCVarInfo loc ty'
                                          val fieldExp = TC.TPVAR fieldVar
                                          val newFields = RecordLabel.Map.insert(newFields, l, fieldExp)
                                          val bindsRev = (fieldVar, exp') :: bindsRev
                                        in
                                          (bindsRev, newFields)
                                        end
                                  val bindConstraints = constraints' @ bindConstraints
                                  val bindSubst = subst' @ bindSubst
                                in (bindsRev, bindSubst, bindConstraints, newTyFields, newFields)
                                end
                              | _ => raise bug "freshInst"
                         )
                         (nil, nil, nil, RecordLabel.Map.empty, RecordLabel.Map.empty)
                         tyFields
                   val binds = List.rev bindsRev
                   val recordExp =
                       TC.TPRECORD{fields=newFields,
                                   recordTy=newTyFields,
                                   loc=loc}
                   val returnExp =
                       case binds of
                         nil => recordExp
                       | _ => 
                         TC.TPMONOLET
                           {binds = binds, bodyExp = recordExp, loc=loc}
                 in
                   (T.RECORDty newTyFields, bindSubst, bindConstraints, returnExp)
                 end
               | _ =>
                 if isAtom exp then
                   let 
                     val (bindsRev, bindSubst, bindConstraints, flty, flexp) =
                         RecordLabel.Map.foldli 
                           (fn (label, fieldTy, (bindsRev,bindSubst,bindConstraints,flty,flexp)) =>
                               let
                                 val (fieldTy,instSubst,instConstraints,instExp) =
                                     freshInst
                                       (fieldTy,
                                        TC.TPSELECT{label=label,
                                                    exp=exp,
                                                    expTy=ty,
                                                    resultTy=fieldTy,
                                                    loc=expLoc})
                                 val fieldVar = newTCVarInfo expLoc fieldTy
                                 val fieldExp = TC.TPVAR fieldVar
                               in
                                 ((fieldVar, instExp)::bindsRev,
                                  instSubst @ bindSubst,
                                  instConstraints @ bindConstraints,
                                  RecordLabel.Map.insert(flty,label,fieldTy),
                                  RecordLabel.Map.insert(flexp,label,fieldExp)
                                 )
                               end)
                           (nil,nil,nil,RecordLabel.Map.empty,RecordLabel.Map.empty)
                           tyFields
                     val binds = List.rev bindsRev
                     val recordExp =
                         TC.TPRECORD{fields=flexp,
                                     recordTy=flty,
                                     loc=expLoc}
                     val returnExp =
                         case binds of
                           nil => recordExp
                         | _ => 
                           TC.TPMONOLET
                             {binds = binds,
                              bodyExp = recordExp,
                              loc=expLoc}
                   in 
                     (T.RECORDty flty, bindSubst, bindConstraints, returnExp)
                   end
                 else
                   let 
                     val var = newTCVarInfo expLoc ty
                     val varExp = TC.TPVAR var
                     val (bindsRev,bindSubst,bindConstraints,flty,flexp) =
                         RecordLabel.Map.foldli
                           (fn (label,fieldTy,(bindsRev,bindSubst,bindConstraints,flty,flexp)) =>
                               let val (fieldTy,instSubst,instConstraints,instExp) =
                                       freshInst
                                         (fieldTy,
                                          TC.TPSELECT
                                            {label=label,
                                             exp=varExp,
                                             expTy=ty,
                                             resultTy=fieldTy,
                                             loc=expLoc})
                                 val fieldVar = newTCVarInfo expLoc fieldTy
                                 val fieldExp = TC.TPVAR fieldVar
                               in
                                 ((fieldVar, instExp)::bindsRev,
                                  instSubst @ bindSubst,
                                  instConstraints @ bindConstraints,
                                  RecordLabel.Map.insert(flty,label,fieldTy),
                                  RecordLabel.Map.insert(flexp,label,fieldExp)
                                 )
                               end
                           )
                           ([(var, exp)], nil, nil, RecordLabel.Map.empty,RecordLabel.Map.empty)
                           tyFields
                   in 
                     (
                      T.RECORDty flty, 
                      bindSubst,
                      bindConstraints,
                      TC.TPMONOLET
                        {binds = List.rev bindsRev,
                         bodyExp =
                         TC.TPRECORD
                           {fields=flexp,
                            recordTy=flty,
                            loc=expLoc},
                         loc = expLoc
                        }
                     )
                   end
              )
          | ty => (ty,nil,nil,exp)
        end

  fun groundInst {exp, ty} =
      let
        val (ty, tyvars, _, exp) = freshInst (ty, exp)
      in
        app (fn T.TYVARty tv => instantiateTv tv | _ => ()) tyvars;
        {exp = exp, ty = ty}
      end

  (**
   * Make a fresh instance of a polytype and a term of that type.
   *)
  fun freshToplevelInst (ty,exp) =
      (* 2016-06-16 sasaki: インスタンス化した制約を返すよう変更 *)
      if TB.monoTy ty then (ty,nil,nil,exp)
      else
        case ty of
          T.POLYty{boundtvars,body,constraints} =>
          let 
            val subst = TB.freshSubst boundtvars
            val bty = TB.substBTvar subst body
            val newExp = 
                case exp of
                  TC.TPDATACONSTRUCT {con,instTyList=NONE,argExpOpt=NONE,loc}
                  => TC.TPDATACONSTRUCT
                       {con=con,
                        instTyList=SOME (BoundTypeVarID.Map.listItems subst),
                        argExpOpt=NONE, 
                        loc=loc}
                | _ => TC.TPTAPP
                         {exp=exp,
                          expTy=ty,
                          instTyList=BoundTypeVarID.Map.listItems subst,
                          loc=getLocOfExp exp}
            val constraints = 
                List.map (fn c =>
                             case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                               T.JOIN
                                   {res = TB.substBTvar subst res,
                                    args = (TB.substBTvar subst arg1,
                                            TB.substBTvar subst arg2), loc=loc})
                         constraints
          in  
            (bty,BoundTypeVarID.Map.listItems subst,constraints,newExp)
          end
        | ty => (ty,nil,nil,exp)

  fun toplevelInstWithInstTy {exp, ty, instTy} =
      let
        val (ty, tyvars, constraints, exp) = freshToplevelInst (ty, exp)
        val _ =
            case constraints of
              nil => ()
            | _::_ =>
              raise Bug.Bug "toplevelInstWithInstTy with non-nil constraints"
        val _ =
            app (fn T.TYVARty (r as ref (T.TVAR _)) =>
                    r := T.SUBSTITUTED instTy
                  | _ => raise Bug.Bug "toplevelInstWithInstTy")
                tyvars
      in
        {exp = exp, ty = ty}
      end

  exception ToplevelInstWithInstTyList

  fun toplevelInstWithInstTyList {exp, ty, instTyList} =
      let
        val (ty, tyvars, constraints, exp) = freshToplevelInst (ty, exp)
        val _ =
            case constraints of
              nil => ()
            | _::_ =>
              raise Bug.Bug "toplevelInstWithInstTy with non-nil constraints"
        val _ =
            ListPair.appEq
              (fn (T.TYVARty (r as ref (T.TVAR _)), instTy) =>
                  r := T.SUBSTITUTED instTy
                | _ => raise Bug.Bug "toplevelInstWithInstTyList")
              (tyvars, instTyList)
            handle ListPair.UnequalLengths =>
                   raise ToplevelInstWithInstTyList
      in
        {exp = exp, ty = ty}
      end

end
end
