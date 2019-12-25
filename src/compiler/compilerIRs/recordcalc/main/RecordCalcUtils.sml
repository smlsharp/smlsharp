structure RecordCalcUtils =
struct
local
  structure RC = RecordCalc
  structure BT = BuiltinTypes
  structure TB = TypesBasics
  structure T = Types
  val tempVarNamePrefix = "R_"
in
  fun newRCVarName () = Symbol.generateWithPrefix tempVarNamePrefix
  fun newRCVarInfo (ty:Types.ty) =
      let
        val newVarId = VarID.generate()
      in
        {path=[newRCVarName()], id=newVarId, ty = ty}
      end

  fun expansive tpexp =
      case tpexp of
        RC.RCCONSTANT _ => false
      | RC.RCFOREIGNSYMBOL _ => false
      | RC.RCVAR _ => false
      | RC.RCEXVAR exVarInfo => false
      | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} => false
      | RC.RCEXNCONSTRUCT {argExpOpt=NONE, exn, instTyList, loc} => false
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} => false
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} => false
      | RC.RCPOLYFNM _ => false
      | RC.RCINDEXOF _ => false
      | RC.RCTAGOF _ => false
      | RC.RCSIZEOF _ => false
      | RC.RCREIFYTY _ => false
      | RC.RCDATACONSTRUCT {argExpOpt=NONE, argTyOpt, con, instTyList, loc} => false
      | RC.RCDATACONSTRUCT {con={path, id, ty}, instTyList, argTyOpt, argExpOpt= SOME tpexp, loc} =>
        let
          val tyCon = TB.tyConFromConTy ty
        in
          TypID.eq (#id tyCon, #id BT.refTyCon)
          orelse expansive tpexp
        end
      | RC.RCEXNCONSTRUCT {argExpOpt= SOME tpexp, exn, instTyList, loc} =>
        expansive tpexp
      | RC.RCRECORD {fields, recordTy=ty, loc=loc} =>
          RecordLabel.Map.foldli
          (fn (string, tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          fields
      | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} => 
        expansive exp orelse expansive indexExp
      | RC.RCMODIFY  {elementExp:RC.rcexp, elementTy:Types.ty, indexExp:RC.rcexp,
                   label:RecordLabel.label, loc, recordExp:RC.rcexp, recordTy:Types.ty} =>
        expansive recordExp orelse expansive indexExp orelse expansive elementExp
      | RC.RCMONOLET {binds=varPathInfoTpexpList, bodyExp=tpexp, loc} =>
          foldl
          (fn ((v,tpexp1), isExpansive) => isExpansive orelse expansive tpexp1)
          (expansive tpexp)
          varPathInfoTpexpList
      | RC.RCLET {decls, body, tys,loc} => true
      | RC.RCPOLY {exp=tpexp,...} => expansive tpexp
      | RC.RCTAPP {exp, ...} => expansive exp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy, funExp=RC.RCFFIFUN (ptrExp, _)}, ty, loc) =>
        expansive ptrExp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy, funExp=RC.RCFFIEXTERN _}, ty, loc) =>
        false
      | RC.RCCAST ((rcexp, expTy), ty, loc) => expansive rcexp 
      | RC.RCAPPM _ => true
      | RC.RCCASE _ => true
      | RC.RCPRIMAPPLY _ => true
      | RC.RCOPRIMAPPLY _ => true
      | RC.RCSEQ _ => true
      | RC.RCRAISE _ => true
      | RC.RCHANDLE _ => true
      | RC.RCEXNCASE _ => true
      | RC.RCCALLBACKFN _ => true
      | RC.RCFOREIGNAPPLY _ => true
      | RC.RCSWITCH _ => true
      | RC.RCCATCH _ => true
      | RC.RCTHROW _ => true
      | RC.RCJOIN {isJoin, ty,args=(arg1,arg2),argTys,loc} => 
        expansive arg1 orelse expansive arg2
      | RC.RCDYNAMIC {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | RC.RCDYNAMICIS {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | RC.RCDYNAMICNULL {ty, coerceTy,loc} => false
      | RC.RCDYNAMICTOP {ty, coerceTy,loc} => false
      | RC.RCDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | RC.RCDYNAMICCASE _ => true

  fun isAtom tpexp =
      case tpexp of
        RC.RCCONSTANT {const, loc, ty} => true
      | RC.RCFOREIGNSYMBOL {loc, name, ty} => true
      | RC.RCVAR var => true
      | RC.RCEXVAR exVarInfo => true
      | _ => false

 (* 2016-12-04 TypedCalcUtils から．constraintがあればエラー
    FFICompilationで使用
  *)
  fun toplevelInstWithInstTy {ty, exp, instTy} =
      if TB.monoTy ty then {ty=ty, exp=exp}
      else
        case ty of
          T.POLYty{boundtvars,body,constraints = nil} =>
          let 
            val subst =
                BoundTypeVarID.Map.map
                  (fn x => instTy)
                  boundtvars
            val bty = TB.substBTvar subst body
            val newExp = 
                case exp of
                  RC.RCDATACONSTRUCT {con,instTyList=nil,argTyOpt, argExpOpt=NONE,loc}
                  => RC.RCDATACONSTRUCT
                       {con=con,
                        instTyList=map (fn x => instTy) (BoundTypeVarID.Map.listItems subst),
                        argExpOpt=NONE, 
                        argTyOpt = NONE,
                        loc=loc}
                | _ => RC.RCTAPP
                         {exp=exp,
                          expTy=ty,
                          instTyList=map (fn x => instTy) (BoundTypeVarID.Map.listItems subst),
                          loc=RC.getLocExp exp}
          in  
            {ty = bty, exp = newExp}
          end
        | T.POLYty{boundtvars,body,constraints = _::_} => 
          raise Bug.Bug "RecodCalcUtils: toplevelInstWithInstTy with non-nil constraints"
        | ty => {ty = ty, exp = exp}

  exception ToplevelInstWithInstTyList
 (* 2016-12-04 TypedCalcUtils から．constraintがあればエラー
    FFICompilationで使用
  *)
  fun toplevelInstWithInstTyList {ty, exp, instTyList} =
      if TB.monoTy ty then {ty=ty, exp=exp}
      else
        case ty of
          T.POLYty{boundtvars,body,constraints = nil} =>
          let 
            val btvList = BoundTypeVarID.Map.listKeys boundtvars
            val btvTyList = 
                ListPair.zipEq (btvList, instTyList)
                handle ListPair.UnequalLengths =>
                       raise ToplevelInstWithInstTyList
            val subst =
                List.foldl
                  (fn ((btv,ty), subst) =>
                      BoundTypeVarID.Map.insert(subst, btv, ty))
                BoundTypeVarID.Map.empty
                btvTyList
(*
fun printTy ty = print (T.tyToString ty ^ "\n")
val _ = print "ty\n"
val _ = printTy ty
val _ = print "instTyList\n"
val _ = map printTy instTyList
val _ = print "body\n"
val _ = printTy body
val _ = print "btvList\n"
val _ = map printTy (map T.BOUNDVARty btvList)
*)
            val bty = TB.substBTvar subst body
            val newExp = 
                case exp of
                  RC.RCDATACONSTRUCT {con,instTyList=nil,argTyOpt, argExpOpt=NONE,loc}
                  => RC.RCDATACONSTRUCT
                       {con = con,
                        instTyList = instTyList,
                        argExpOpt = NONE, 
                        argTyOpt = NONE,
                        loc = loc}
                | _ => RC.RCTAPP
                         {exp = exp,
                          expTy = ty,
                          instTyList = instTyList,
                          loc = RC.getLocExp exp}
          in  
            {ty = bty, exp = newExp}
          end
        | T.POLYty{boundtvars,body,constraints = _::_} => 
          raise Bug.Bug "RecodCalcUtils: toplevelInstWithInstTy with non-nil constraints"
        | ty => {ty = ty, exp = exp}

 (* 2017-1-03 TypedCalcUtils から ReifyTopEnvで使用 *)
  fun newVarInfo loc (ty:T.ty) =
      let
        val newVarId = VarID.generate()
        val IdString =  VarID.toString newVarId
        val longsymbol = Symbol.mkLongsymbol ["_reify" ^ IdString] loc
      in
        {path=longsymbol, id=newVarId, ty = ty}
      end

  (**
   * Make a kind consistent ground instance.
   *
   * NOTE: If properties contradict with tvarKind, or if constraints are not
   * satisfiable, there is no type-consistent ground instance.
   * Examples include:
   *
   * # fun f x = #a _join({a=true},x) = 123;
   * val f = fn : ['a#[reify]{}, 'b#[reify]{a: int}. ('b = {a: bool} join 'a) =>
   *               'a -> bool]
   * # fun f x = let fun 'a#unboxed g x = x : 'a in (g x, #a x) end;
   * val f = fn : ['a#[unboxed]{a: 'b}, 'b. 'a -> 'a * 'b]
   * # val 'a#[boxed,unboxed] l = nil : 'a list;
   * val l = [] : ['a#[boxed,unboxed]. 'a list]
   *
   * This function generates an instance even for these polytypes.
   * Actually, this function generates an instance for which the record
   * compilation can choose a valid singleton type.
   *
   * This function is used only by ReifyTopEnv for printing polymorphic
   * data (such as nil).  Even if a polytype does not have any type-consistent
   * instance, the printer requires type instantiation in order to reveal the
   * data structure.  The choice of a type instance is not a matter for this
   * purpose because a data structure of a polymorphic type, say ['a. 'a t],
   * does not include any value of type 'a.
   *
   * Therefore, this function does not concern type-consistency, but only
   * concerns that the generated instance can pass subsequent compilation
   * phases, namely record compilation.
   *)
  fun instantiateTv ty =
      case ty of
        T.TYVARty (tv as ref (T.TVAR {kind = T.KIND {tvarKind, properties, dynamicKind}, ...})) =>
        (case tvarKind of
           T.OCONSTkind (h::_) => tv := T.SUBSTITUTED h
         | T.OCONSTkind nil => raise Bug.Bug "instantiateTv: OCONSTkind"
         | T.OPRIMkind {instances = (h::_), ...} => tv := T.SUBSTITUTED h
         | T.OPRIMkind {instances = nil, ...} =>
           raise Bug.Bug "instantiateTv: OPRIMkind"
         | T.REC tyFields => tv := T.SUBSTITUTED (T.RECORDty tyFields)
         | T.UNIV => 
           if T.isProperties T.BOXED properties
           then tv := T.SUBSTITUTED (T.RECORDty RecordLabel.Map.empty)
           else tv := T.SUBSTITUTED BuiltinTypes.unitTy
	)
      | _ => ()

  fun groundInst {ty,exp} =
      if TB.monoTy ty then {ty=ty,exp=exp}
      else
        let
          val expLoc = RC.getLocExp exp
        in
          case ty of
            T.POLYty{boundtvars,body,constraints} =>
            let 
              val subst = TB.freshSubst boundtvars
              val _ = BoundTypeVarID.Map.app instantiateTv subst
              val bty = TB.substBTvar subst body
              val newExp = 
                  case exp of
                    RC.RCDATACONSTRUCT {con,instTyList=nil,argTyOpt, argExpOpt=NONE,loc}
                    => RC.RCDATACONSTRUCT
                         {con=con,
                          instTyList=BoundTypeVarID.Map.listItems subst,
                          argTyOpt =NONE,
                          argExpOpt=NONE, 
                          loc=loc}
                  | _ => RC.RCTAPP
                           {exp=exp,
                            expTy=ty,
                            instTyList=BoundTypeVarID.Map.listItems subst,
                            loc=expLoc}
            in 
              groundInst {ty=bty,exp=newExp}
            end
          | T.FUNMty (tyList, bodyTy) =>
              let
                val newVar = newVarInfo expLoc bodyTy
                val (exp, mkNewExp) = 
                    (RC.RCVAR newVar,
                     fn x => RC.RCMONOLET {binds = [(newVar, exp)],
                                           bodyExp = x,
                                           loc=expLoc}
                    )
                val argVarList = map (newVarInfo expLoc) tyList
                val argExpList = map (fn x => RC.RCVAR x) argVarList
                val {ty = instBodyTy, exp = instBody} = 
                    groundInst
                      {ty = bodyTy,
                       exp = RC.RCAPPM{funExp=exp,
                                       funTy=ty,
                                       argExpList=argExpList,
                                       loc=expLoc}
                      }
                val newExp = 
                  RC.RCFNM
                    {argVarList = argVarList,
                     bodyTy = instBodyTy,
                     bodyExp = instBody,
                     loc = expLoc}
              in 
                {ty = T.FUNMty(tyList, instBodyTy), exp =  mkNewExp newExp}
              end
          | T.RECORDty tyFields => 
            (case exp of
               RC.RCRECORD {fields, recordTy=_, loc=loc} =>
               let
                 val (bindsRev, newTyFields, newFields) =
                     RecordLabel.Map.foldli
                       (fn (l, fieldTy, (bindsRev,newTyFields,newFields)) =>
                           case RecordLabel.Map.find(fields,l) of
                             SOME field =>
                             let
                               val {ty=ty', exp=exp'} = groundInst {ty=fieldTy, exp=field}
                               val newTyFields = RecordLabel.Map.insert(newTyFields, l, ty')
                               val (bindsRev, newFields) =
                                   if isAtom exp' then 
                                     (bindsRev, RecordLabel.Map.insert(newFields, l, exp'))
                                   else
                                     let
                                       val fieldVar = newVarInfo loc ty'
                                       val fieldExp = RC.RCVAR fieldVar
                                       val newFields = RecordLabel.Map.insert(newFields, l, fieldExp)
                                       val bindsRev = (fieldVar, exp') :: bindsRev
                                     in
                                       (bindsRev, newFields)
                                     end
                             in (bindsRev, newTyFields, newFields)
                             end
                           | _ => raise Bug.Bug "groundInst"
                       )
                       (nil, RecordLabel.Map.empty, RecordLabel.Map.empty)
                       tyFields
                 val binds = List.rev bindsRev
                 val recordExp =
                     RC.RCRECORD{fields=newFields,
                                 recordTy=T.RECORDty newTyFields,
                                 loc=loc}
                 val returnExp =
                     case binds of
                       nil => recordExp
                     | _ => 
                       RC.RCMONOLET {binds = binds, bodyExp = recordExp, loc=loc}
               in
                 {ty=T.RECORDty newTyFields, exp=returnExp}
               end
             | _ =>
               if isAtom exp then
                 let 
                   val (bindsRev, flty, flexp) =
                       RecordLabel.Map.foldli 
                         (fn (label, fieldTy, (bindsRev,flty,flexp)) =>
                             let
                               val {ty=fieldTy,exp=instExp} =
                                   groundInst
                                     {ty=fieldTy,
                                      exp=RC.RCSELECT{label=label,
                                                      exp=exp,
                                                      expTy=ty,
                                                      indexExp = RC.RCINDEXOF (label, ty, expLoc),
                                                      resultTy=fieldTy,
                                                      loc=expLoc}
                                     }
                               val fieldVar = newVarInfo expLoc fieldTy
                               val fieldExp = RC.RCVAR fieldVar
                             in
                               ((fieldVar, instExp)::bindsRev,
                                RecordLabel.Map.insert(flty,label,fieldTy),
                                RecordLabel.Map.insert(flexp,label,fieldExp)
                               )
                             end)
                         (nil,RecordLabel.Map.empty,RecordLabel.Map.empty)
                         tyFields
                   val binds = List.rev bindsRev
                   val recordExp =
                       RC.RCRECORD{fields=flexp,
                                   recordTy=T.RECORDty flty,
                                   loc=expLoc}
                   val returnExp =
                       case binds of
                         nil => recordExp
                       | _ => 
                         RC.RCMONOLET
                           {binds = binds,
                            bodyExp = recordExp,
                            loc=expLoc}
                 in 
                   {ty=T.RECORDty flty, exp=returnExp}
                 end
               else
                 let 
                   val var = newVarInfo expLoc ty
                   val varExp = RC.RCVAR var
                   val (bindsRev,flty,flexp) =
                       RecordLabel.Map.foldli
                         (fn (label,fieldTy,(bindsRev,flty,flexp)) =>
                             let val {ty=fieldTy,exp=instExp} =
                                     groundInst
                                       {ty = fieldTy,
                                        exp = RC.RCSELECT
                                                {label=label,
                                                 exp=varExp,
                                                 indexExp = RC.RCINDEXOF (label, ty, expLoc),
                                                 expTy=ty,
                                                 resultTy=fieldTy,
                                                 loc=expLoc}
                                       }
                                 val fieldVar = newVarInfo expLoc fieldTy
                                 val fieldExp = RC.RCVAR fieldVar
                             in
                               ((fieldVar, instExp)::bindsRev,
                                RecordLabel.Map.insert(flty,label,fieldTy),
                                RecordLabel.Map.insert(flexp,label,fieldExp)
                               )
                             end
                         )
                         ([(var, exp)], RecordLabel.Map.empty,RecordLabel.Map.empty)
                         tyFields
                 in 
                   {ty=T.RECORDty flty, 
                    exp =RC.RCMONOLET
                           {binds = List.rev bindsRev,
                            bodyExp =
                            RC.RCRECORD
                              {fields=flexp,
                               recordTy=T.RECORDty flty,
                               loc=expLoc},
                            loc = expLoc
                           }
                   }
                 end
            )
          | ty => {ty=ty,exp=exp}
        end
end
end
