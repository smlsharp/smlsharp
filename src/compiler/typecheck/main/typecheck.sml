(**
 * @copyright (c) 2006, Tohoku University.
 *)

(*********************************************)
(* A Type Checker for Typed Pattern Calculus *)
(*********************************************)

signature TYPECHECK =
sig
    val typecheckTP : {context : CompileContext.compileContext,
                       newContext : CompileContext.compileContext,
                       declarations : TypedCalc.tpdecl list}
                       -> 
                       CompileContext.compileContext * TypedCalc.tpdecl list

    val stopIfAnyTypeError : bool ref
    val errMsgLevel        : int ref
end

structure TypeCheck :> TYPECHECK =
struct

local
 open Types
 open TypedCalc
 open TypeFormatter
in

datatype path = datatype PatternCalc.patpath

val stopIfAnyTypeError = ref false

type tyckEnv = {gEnv:Types.varEnv, 
                btvEnv:Types.btvEnv, 
                tyConEnv:Types.tyConEnv, varEnv:Types.varEnv}

(* Error messages *)
datatype ErrLevel = L_EXPR | L_DECL | L_PAT | L_ELSE | L_PRG

exception Err of (ErrLevel list) * string

val errMsgLevel = ref 2      (* e.g., decl=>expr=>pat *)

infix 6 ^^



fun op ^^ ((ls,msg), (l,msg')) = 
    let val b  = case ls of
                   []    => true
                 | (h::_) => h<>l andalso 
                            (length ls  <= !errMsgLevel)
    in  if b 
        then (l::ls, msg ^ msg')
        else (ls,msg)
    end

fun ERRELS msg = Err ([L_ELSE], msg)
fun ERREXP msg = Err ([L_EXPR], msg)
fun ERRDEC msg = Err ([L_DECL], msg)
fun ERRPAT msg = Err ([L_PAT] , msg)


(* Utility  *)
fun pr (ERRORty) = "ERRORty"
  | pr (DUMMYty _) = "DUMMYty"
  | pr (TYVARty (ref (TVAR tvKind))) = 
       "TYVARty (ref (TVar (...)))"
  | pr (TYVARty (ref (SUBSTITUTED ty1))) = 
       "TYVARty (ref (SUBSTITUTED (" ^ pr ty1 ^  ")))"
  | pr (BOUNDVARty i) = "BOUNDVARty " ^ Int.toString i
  | pr (FUNty (ty1,ty2)) = "FUN (" ^ pr ty1 ^ "," ^ pr ty2 ^ ")"
  | pr (IABSty (tys,ty)) = "IABSty ([" ^ prs tys ^ "]," ^ pr ty ^ ")"
  | pr (RECORDty fieldEnv) = "RECORDty (" ^ prSmap fieldEnv ^ ")"
  | pr (CONty {tyCon={name,arity,id,eqKind,datacon},args=tys}) = 
       "CONty ({name=" ^ name ^ 
                ",id=" ^ Int.toString id ^ 
                ",arity=" ^ Int.toString arity ^ 
                ",eqKind=" ^ (if !eqKind=EQ then "EQ" else "NONEQ") ^ 
                ",datacon=" ^ "..." ^
                "}, " ^ prs tys ^ ")"
  | pr (POLYty {boundtvars=btvs,body=ty}) = 
         "POLYty {" ^ 
         "boundtvars=" ^
         prBtvEnv btvs ^
         "," ^ 
         "body=" ^
          pr ty ^
         "}"
  | pr BOXEDty = "BOXEDty"
  | pr ATOMty  = "ATOMty"
  | pr (INDEXty (ty,s)) = "INDEXty (" ^ pr ty ^ "," ^ s ^ ")"
  | pr (BMABSty (tys,ty)) = "BMABSty (" ^ prs tys ^ "," ^ pr ty ^ ")"
  | pr (BITMAPty bitTys) = "BITMAPty [" ^ prbitTys bitTys ^ "]"

and prs [] = ""
  | prs (ty::tys) = pr ty ^ ", " ^ prs tys

and prbitTy DC = "DC"
  | prbitTy (TRACE ty) = "TRACE " ^ pr ty

and prbitTys [] = ""
  | prbitTys (bitTy::bitTys) = prbitTy bitTy ^ ", " ^ prbitTys bitTys

and prSmap smap =
    "{" ^
    foldr (fn ((k,ty),s) => k ^ " : " ^ pr ty ^ s)
      "" (SEnv.listItemsi smap) ^
    "}"

and prImap imap =
    "{" ^
    foldr (fn ((k,ty),s) => Int.toString k ^ " : " ^ pr ty ^ s)
      "" (IEnv.listItemsi imap) ^
    "}"

and prTyConEnv smap =
    foldr (fn ((k,tyBindInfo),s) => 
      case tyBindInfo of
        TYFUN {name,tyargs,body} => 
        "(" ^ name ^ ")" ^ pr (POLYty {boundtvars=tyargs,body=body})
      | TYCON (tyCon as {name,arity,id,eqKind,datacon}) =>
        k ^ "|->\n" ^ prTyCon tyCon ^ "\n\n" ^ s)
        "" (SEnv.listItemsi smap)

and prVarEnv smap =
    "{" ^
    foldr (fn ((k,idState),s) => k ^ 
           " |-> " ^ 
           prIdState idState ^ " " ^ s)
    "" (SEnv.listItemsi smap) ^
    "}"

and prVarEnv' smap =
    "{" ^
    foldr (fn ((k,idState),s) => k ^ 
           " |-> " ^ 
           "...; " ^ s)
    "" (SEnv.listItemsi smap) ^
    "}"

and prIdState (VARID info)  = #name info ^ " : " ^ pr (#ty info)
  | prIdState (CONID info)  = #name info ^ " : " ^ pr (#ty info)
  | prIdState (PRIM  info)  = #name info ^ " : " ^ pr (#ty info)
  | prIdState (OPRIM oinfo) = #name oinfo ^ " : " ^ pr (#ty oinfo)
                              ^ prOInfo (#instances oinfo)

and prOInfo (oinfo : primInfo SEnv.map ) =
    "{" ^
    foldr (fn ((l,{name=name,ty=ty}),s) => l ^ 
           " |-> " ^ 
           "{name=" ^ name ^ ", " ^ "ty=" ^ pr ty ^ "}, "  ^ s)
    "" (SEnv.listItemsi oinfo) ^
    "}"

and prEqKind EQ    = "EQ"
  | prEqKind NONEQ = "NONEQ"

and prRecKind UNIV = "UNIV"
  | prRecKind (REC fieldtys) = 
    "REC { " ^ 
    foldr (fn ((k,ty),s) => k ^ "|->" ^ tyToString ty ^ " " ^ s)
      "" (SEnv.listItemsi fieldtys) ^
    " }"
  | prRecKind (OVERLOADED tys) =
    "OVERLOADED ["  ^ prs tys ^ "]"

and prBtvEnv btvEnv =
    "{" ^
    foldr (fn ((k,btv),s) => Int.toString k ^ " : " ^ prBtv btv ^ " " ^ s)
      "" (IEnv.listItemsi btvEnv) ^
    "}"    

and prBtv {recKind=rek,eqKind=eqk,rank=_,index=_} =
    "{" ^
    "recKind=" ^ prRecKind rek ^ "," ^
    "eqKind="  ^ prEqKind eqk ^ "," ^
    "rank="    ^ "*" ^ "," ^
    "index="   ^ "*" ^
    "}"

and prTyCon {name,arity,id,eqKind,datacon} =
        "{" ^
        "name="    ^ name                ^ ",\n" ^
        "arity="   ^ Int.toString arity  ^ ",\n" ^
        "id="      ^ Int.toString id     ^ ",\n" ^
        "eqKind="  ^ prEqKind (!eqKind)  ^ ",\n" ^
        "datacon=" ^ prVarEnv (!datacon) ^
        "}"

and prConInfo {name,funtyCon,ty,exntag,tyCon} =
        "{" ^
        "name="     ^ name                    ^ ",\n" ^
        "funtyCon=" ^ Bool.toString funtyCon  ^ ",\n" ^
        "ty="       ^ tyToString ty           ^ ",\n" ^
        "exntag="   ^ Int.toString exntag     ^ ",\n" ^
        "tyCon="    ^ prTyCon tyCon ^
        "}"

fun tysToString tys =
    foldr (fn (ty,s) => tyToString ty ^ ", " ^ s) "" tys

fun at_exp (env : tyckEnv) exp =
    "\nIn " ^
    SMLFormat.prettyPrint
        [SMLFormat.Columns 60]
        (format_tpexp [(0,#btvEnv env)] exp)

fun at_pat (env : tyckEnv) pat = 
    "\nIn " ^
    SMLFormat.prettyPrint
        [SMLFormat.Columns 60]
        (format_tppat [(0,#btvEnv env)] pat)

fun at_decl (env : tyckEnv) decl =
    "\nIn " ^
    SMLFormat.prettyPrint
        [SMLFormat.Columns 60]
        (format_tpdecl [(0,#btvEnv env)] decl)

fun skipInd (TYVARty (r as (ref (SUBSTITUTED ty)))) = 
    (case ty of
       TYVARty (ref (tvState as (SUBSTITUTED _)))
           => (r := tvState; skipInd ty)
     | ty' => ty)
  | skipInd (ty as _) = ty

fun instBtvEnv btvEnv subst = 
    IEnv.map 
      (fn {recKind=recKind,eqKind=eqKind, 
           rank=rank,index=index} => 
       let val recKind = 
               case recKind of
                 UNIV => UNIV
               | REC fieldtys =>
                 REC (SEnv.map 
                      (fn ty => 
                         TypesUtils.substBTvar subst ty)
                       fieldtys)
               (* Overloaded ids are all monomorphic. *)
               | OVERLOADED tys => 
                 OVERLOADED tys
       in {recKind=recKind,eqKind=eqKind, 
           rank=rank,index=index}
       end) btvEnv

(* Environment Handling functions *)
fun mergeTyConEnv tyConEnv tyConEnv' =
    mergeTyConEnvWith (fn (x,y)=>y) tyConEnv  tyConEnv'

and mergeExclusiveTyConEnv tyConEnv tyConEnv' =
    mergeTyConEnvWith (fn (x,y)=> raise ERRELS (
        "Duplicate type names")) tyConEnv tyConEnv'

and mergeTyConEnvWith f tyConEnv tyConEnv' =
    SEnv.unionWith f (tyConEnv, tyConEnv')

fun mergePatVarEnv patvarEnv patvarEnv' =
    SEnv.unionWith 
     (fn (x,y)=> raise ERRELS ("Duplicated pattern variables"))
      (patvarEnv, patvarEnv')

fun mergeVarEnv varEnv varEnv' =
    SEnv.unionWith (fn (x,y)=>y) (varEnv, varEnv')

fun mergeBtvEnv btvEnv btvEnv' =
    IEnv.unionWith (fn (x,y)=>y) (btvEnv, btvEnv')

fun extendBtvEnv
    {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv} btvEnv' =
    let 
        val n = IEnv.numItems btvEnv
        val btvEnv = 
            IEnv.unionWith (fn (x,y) => y) (btvEnv,btvEnv')
    in  {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv}
    end

fun extendTyConEnv 
    {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv} tyConEnv' =
    let val tyConEnv = mergeTyConEnv tyConEnv tyConEnv'
    in  {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv}
    end

fun extendVarEnv 
    {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv} varEnv' =
    let val varEnv =  mergeVarEnv varEnv varEnv'
    in  {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv}
    end

fun extendGlobalVarEnv 
    {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv} gEnv' =
    let val gEnv = mergeVarEnv gEnv gEnv'
    in  {tyConEnv=tyConEnv,gEnv=gEnv,btvEnv=btvEnv,varEnv=varEnv}
    end

(* Kind/Type Equality functions *)
fun eqBtvKind iEnv1 iEnv2
    {recKind=rek1, eqKind=eqk1, rank=_, index=_} 
    {recKind=rek2, eqKind=eqk2, rank=_, index=_} = 
    eqRecKind iEnv1 iEnv2 rek1 rek2 andalso 
    eqk1=eqk2 

and eqBtvKinds iEnv1 iEnv2 [] [] = true
  | eqBtvKinds iEnv1 iEnv2 (k1::ks1) (k2::ks2) = 
    eqBtvKind iEnv1 iEnv2 k1 k2 andalso 
    eqBtvKinds iEnv1 iEnv2 ks1 ks2
  | eqBtvKinds _ _ _ _ = false

(* The first arg is the equality Kind of bound type var. The second 
   arg is the equality Kind of type to be instantiated to the bound
   type var. Note that the meaning of EQ and NONEQ in the first arg
   is different from in the second arg. 
*)
and leqEqKind eqKindBTVar eqKindTyInst =
    case (eqKindBTVar, eqKindTyInst) of
      (EQ,    EQ   ) => true   
    | (EQ,    NONEQ) => false
    | (NONEQ, EQ   ) => true
    | (NONEQ, NONEQ) => true

(* leqRecKind is used to check if the type variables of
   a given polymorphic type can be instantiated with types given
    in a type application. 
*)

and leqRecKind (env : tyckEnv) UNIV UNIV    = true
  | leqRecKind env UNIV (REC _) = true
  | leqRecKind env (REC rek1) (REC rek2) = 
    if SEnv.numItems rek1 <= SEnv.numItems rek2 
    then foldr (fn ((l,ty1),_) =>
                 case SEnv.find (rek2,l) of
                   SOME ty2 
                        => let val iEnv = #btvEnv env 
                           in  eqTy iEnv iEnv ty1 ty2
                           end
                 | NONE => false) true (SEnv.listItemsi rek1)
    else false

    (* Every overloaded type variable is assumed 
       to have Kind UNIV.
    *)
  | leqRecKind env (OVERLOADED _) UNIV = true

  | leqRecKind _ _ _ = false

and eqRecKind iEnv1 iEnv2 UNIV UNIV = true
  | eqRecKind iEnv1 iEnv2 (REC rek1) (REC rek2) = 
    if SEnv.numItems rek1 <> SEnv.numItems rek2 
    then false
    else foldr (fn ((l,ty1),_) =>
                 case SEnv.find (rek2,l) of
                   SOME ty2 => eqTy iEnv1 iEnv2 ty1 ty2
                 | NONE => false) true 
                  (SEnv.listItemsi rek1)
  | eqRecKind _ _ (OVERLOADED _) _ =
    raise ERRELS ("Unexpected overloaded record Kind")
  | eqRecKind _ _ _ (OVERLOADED _) =
    raise ERRELS ("Unexpected overloaded record Kind")
  | eqRecKind _ _ _ _ = false

and eqTy iEnv1 iEnv2 ERRORty ERRORty = false

  | eqTy iEnv1 iEnv2 (DUMMYty _) (DUMMYty _) = false

  | eqTy iEnv1 iEnv2 (TYVARty (ref (SUBSTITUTED ty1))) ty2 
    = eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 ty1 (TYVARty (ref (SUBSTITUTED ty2)))
    = eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 (TYVARty (ref (TVAR tvKind1)))
                     (TYVARty (ref (TVAR tvKind2))) = 
    let val {id=_,recKind=rek1,eqKind=eqk1,tyvarName=_} = tvKind1
        val {id=_,recKind=rek2,eqKind=eqk2,tyvarName=_} = tvKind2
    in  eqRecKind iEnv1 iEnv2 rek1 rek2 andalso eqk1=eqk2
    end

  | eqTy iEnv1 iEnv2 (BOUNDVARty i) (BOUNDVARty j) =
    let val btvKind1 = 
            case IEnv.find(iEnv1,i) of
              SOME btvKind => btvKind
            | NONE => raise ERRELS 
                        ("Can't find the bound tyvar " ^
                         Int.toString i)
        val btvKind2 =
            case IEnv.find(iEnv2,j) of
              SOME btvKind => btvKind
            | NONE => raise ERRELS 
                        ("Can't find the bound tyvar " ^
                         Int.toString j)
    in  eqBtvKind iEnv1 iEnv2 btvKind1 btvKind2
    end

  | eqTy iEnv1 iEnv2 (FUNty (tya1,tyr1)) (FUNty (tya2,tyr2)) =
     eqTy iEnv1 iEnv2 tya1 tya2 andalso 
     eqTy iEnv1 iEnv2 tyr1 tyr2

  | eqTy iEnv1 iEnv2 (IABSty (tys1,ty1)) (IABSty (tys2,ty2)) =
     eqTys iEnv1 iEnv2 tys1 tys2 andalso 
     eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 (RECORDty recty1) (RECORDty recty2) = 
     eqFieldTys iEnv1 iEnv2 recty1 recty2

  | eqTy iEnv1 iEnv2 (CONty {tyCon=tyCon1,args=tys1})
                     (CONty {tyCon=tyCon2,args=tys2}) =
     (#name tyCon1 = #name tyCon2) andalso 
     (#arity tyCon1 = #arity tyCon2) andalso 
     (#datacon tyCon1 = #datacon tyCon2) andalso 
     (eqTys iEnv1 iEnv2 tys1 tys2)

  | eqTy iEnv1 iEnv2 (POLYty {boundtvars=btvEnv1,body=ty1}) 
                     (POLYty {boundtvars=btvEnv2,body=ty2}) =
    let val iEnv1 = mergeBtvEnv iEnv1 btvEnv1
        val iEnv2 = mergeBtvEnv iEnv2 btvEnv2
    in  eqBtvKinds iEnv1 iEnv2 (IEnv.listItems btvEnv1) 
                               (IEnv.listItems btvEnv2)
        andalso eqTy iEnv1 iEnv2 ty1 ty2
    end

  | eqTy iEnv1 iEnv2 BOXEDty BOXEDty = true

  | eqTy iEnv1 iEnv2 ATOMty ATOMty = true

  | eqTy iEnv1 iEnv2 (INDEXty (ty1,l1)) (INDEXty (ty2,l2)) = 
     eqTy iEnv1 iEnv2 ty1 ty2 andalso 
     l1=l2

  | eqTy iEnv1 iEnv2 (BMABSty (tys1,ty1)) (BMABSty (tys2,ty2)) =
     eqTys iEnv1 iEnv2 tys1 tys2 andalso 
     eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 (BITMAPty bitTys1) (BITMAPty bitTys2) =
     foldr (fn ((bty1,bty2),_) => eqBitTy iEnv1 iEnv2 bty1 bty2) 
       true
       (ListPair.zip (bitTys1,bitTys2))

  | eqTy iEnv1 iEnv2 ty1 ty2 = false


and eqFieldTys iEnv1 iEnv2 recty1 recty2 =
     if SEnv.numItems recty1 <> SEnv.numItems recty2 then false
     else foldr (fn ((k,ty1),b) => 
                  case SEnv.find (recty2,k) of
                    SOME ty2 => b andalso eqTy iEnv1 iEnv2 ty1 ty2
                  | NONE => false) true (SEnv.listItemsi recty1)

and eqTys iEnv1 iEnv2 [] [] = true
  | eqTys iEnv1 iEnv2 (ty1::tys1) (ty2::tys2) = 
    eqTy iEnv1 iEnv2 ty1 ty2 andalso 
    eqTys iEnv1 iEnv2 tys1 tys2
  | eqTys _ _ _ _ = false

and eqBitTy iEnv1 iEnv2 (DC) (DC) = true
  | eqBitTy iEnv1 iEnv2 (TRACE ty1) (TRACE ty2) = 
    eqTy iEnv1 iEnv2 ty1 ty2
  | eqBitTy _ _ _ _ = false

and eqConInfo (env : tyckEnv)
    (conInfo as {name=name,funtyCon=funtyCon,ty=ty,
                 exntag=exntag,tyCon=tyCon})
    (conInfo' as {name=name',funtyCon=funtyCon',ty=ty',
                 exntag=exntag',tyCon=tyCon'}) =
    let val iEnv = #btvEnv env
    in
        name = name' andalso
        funtyCon = funtyCon' andalso
        eqTy iEnv iEnv ty ty' andalso
        exntag = exntag' andalso
        eqTyCon tyCon tyCon'
    end

and eqTyCon 
    (tyCon as {name=name,arity=arity,id=id,
               eqKind=eqKind,datacon=datacon})
    (tyCon' as {name=name',arity=arity',id=id',
               eqKind=eqKind',datacon=datacon'}) = 
    name = name' andalso
    arity = arity' andalso
    id = id' andalso
    eqKind = eqKind' andalso
    datacon = datacon'

(* environment *)
type tyckEnv = {
                gEnv:varEnv, 
                btvEnv:btvEnv, 
                tyConEnv:tyConEnv, 
                varEnv:varEnv
               }

(* Type *)
fun leqKinds env [] [] = []
  | leqKinds env 
        ((btv as {recKind=rek,eqKind=eqk,rank=_,index=_})::btvs) 
        (ty::tys) =
        let val (eqk',rek') = calcEqRecKind env ty
            val boolLeqEqKind = leqEqKind eqk eqk'
            val boolLeqRecKind = leqRecKind env rek rek'
        in
            if boolLeqEqKind andalso boolLeqRecKind
            then (eqk,rek) :: leqKinds env btvs tys
            else raise ERRELS
                  ("Kind mismatch: " ^ prBtv btv ^ " with " ^ 
                                tyToString ty ^ " : " ^
                    prEqKind eqk ^ "<=" ^ prEqKind eqk' ^ 
                    "(" ^ Bool.toString boolLeqEqKind ^ ")  " ^
                    prRecKind rek ^ "<=" ^ prRecKind rek' ^
                    "(" ^ Bool.toString boolLeqRecKind ^ ")")
        end
  | leqKinds env _ _ =
            raise ERRELS ("Comparing different # of Kinds.")

and calcEqRecKind (env : tyckEnv) TY =
    case TY of
      ERRORty => (NONEQ,UNIV)

    | DUMMYty _ => (NONEQ,UNIV)

    | TYVARty (ref (SUBSTITUTED ty)) => calcEqRecKind env ty

    | TYVARty (ref (TVAR tvKind)) => 
      (#eqKind tvKind, #recKind tvKind)

    | BOUNDVARty i =>
      (case IEnv.find (#btvEnv env,i) of
         SOME {recKind=rek,eqKind=_,...} => (EQ,rek)
       | NONE => raise ERRELS (
                   tyToString TY ^ " is not found in " ^
                   prBtvEnv (#btvEnv env))
      )

    | FUNty (ty1,ty2) =>
      let val _ = calcEqRecKind env ty1
          val _ = calcEqRecKind env ty2
      in  (NONEQ,UNIV)
      end

    | IABSty (tys,ty) => 
      let val _ = map (calcEqRecKind env) tys
          val _ = calcEqRecKind env ty
      in  (NONEQ,UNIV)
      end

    | RECORDty fields =>
      let val eqk = foldr (fn ((_,ty),eqk) =>
                     let val (eqk',_) = calcEqRecKind env ty
                     in  if eqk=EQ andalso eqk'=EQ 
                         then EQ 
                         else NONEQ
                     end) EQ (SEnv.listItemsi fields)
          val rek = REC fields
      in  (eqk,rek)
      end

(* NOTE.
   We can safely assume every bound type variable of a type constructor
   (CONty) has Kind NONEQ and UNIV. We don't have to check whether 
   each bound type vars of CONty has the same Kind as a corresponding 
   type to be instantiated. Moreover, we know
   - CONty is not a record type so that its recKind is UNIV, 
   - CONty has the same arity as # tys, and
   - CONty has the same eqKind as '!(#eqKind tyCon)' if tys 
     all have eqKind EQ. Otherwise, CONty has eqKind NONEQ.

   However, this strategy poses a problem. CONty may have eqKind 
   '!(#eqKind tyCon)' even if some of types has eqKind NONEQ. 
   For example, 

   - datatype ('a,b') D = C of 'a;
   - val x = C 1 : (int, int->int) D;
   - x=x;
     ~~~ type error because of Kind mismatch ~~~

   I don't think this is a serious problem because 
   - datatype declarations with unused type variables do not seem 
     to be common, and
   - SML/NJ also shows the same behavior. 

   c.f. Phantom types.
*)
    | CONty {tyCon=tyCon,args=tys} =>
      let val arity  = #arity tyCon
          val _ = if arity=length tys 
                  then ()
                  else raise ERRELS 
                        ("Different arities in type constructor " ^
                          tyToString TY)
          val eqk = foldr (fn ((eqk,_),eqKind) => 
                           if eqk=EQ then eqKind else NONEQ)
                           EQ (map (calcEqRecKind env) tys)
          val eqKind = if eqk=EQ 
                       then !(#eqKind tyCon)
                       else NONEQ
      in  (eqKind, UNIV)
      end

    | POLYty {boundtvars=btvEnv,body=ty} =>
      let val env = extendBtvEnv env btvEnv
                    handle Err msg =>
                    raise Err (msg ^^ (L_ELSE," : " ^ tyToString TY))
          val _ = calcEqRecKind env ty
      in  (NONEQ,UNIV)
      end

    | BOXEDty => (NONEQ,UNIV)

    | ATOMty => (NONEQ,UNIV)

    | INDEXty (ty,label)=>
      let val (_,recKind) = calcEqRecKind env ty
          val (eqKind,recKind) =
              case recKind of
                REC fieldtys => 
                let val ty = case SEnv.find(fieldtys,label) of
                               SOME ty => ty
                             | NONE => raise ERRELS (label ^ 
                                        " is not found in " ^
                                        tyToString TY)
                in  calcEqRecKind env ty
                end 
              | UNIV => raise ERRELS (tyToString ty ^
                          " has Kind UNIV in " ^
                          tyToString TY)
              | OVERLOADED _ =>
                        raise ERRELS (tyToString ty ^
                          " has Kind OVERLOADED in " ^
                          tyToString TY)
      in  (eqKind,recKind)
      end

    | BMABSty (tys,ty) =>
      let val _ = map (calcEqRecKind env) tys
          val _ = calcEqRecKind env ty
      in  (NONEQ,UNIV)
      end

    | BITMAPty bitTys =>
      let fun checkBitTy DC = ()
            | checkBitTy (TRACE ty) = (calcEqRecKind env ty; ())
          val _ = map checkBitTy bitTys
      in  (NONEQ,UNIV)
      end

and checkType 
    (env as {gEnv=gEnv,btvEnv=btvEnv,tyConEnv=tyConEnv,varEnv=varEnv}) 
    TY =
    case TY of
      ERRORty => ()

    | DUMMYty _ => ()

    | TYVARty (ref (SUBSTITUTED ty)) => checkType env ty

    | TYVARty (ref (TVAR tvKind)) => 
      (case #recKind tvKind of
         UNIV => ()
       | REC fields => 
           foldr (fn (ty,_) => checkType env ty) 
             () (SEnv.listItems fields)
       | OVERLOADED tys =>
           foldr (fn (ty,_) => checkType env ty) () tys)

    | BOUNDVARty i => 
      (case IEnv.find (btvEnv, i) of
        SOME {recKind=rek,eqKind=eqk,rank=rak,index=_} 
             => (case rek of
                  UNIV => ()
                | REC fieldtys =>
                   checkTypes env (SEnv.listItems fieldtys)
                | OVERLOADED tys =>
                   foldr (fn (ty,_) => checkType env ty) () tys)
      | NONE => raise ERRELS 
                       (tyToString TY ^ "(" ^
                        pr TY ^
                        ")" ^
                        " is not found in " ^
                        prBtvEnv btvEnv))

    | FUNty (ty1,ty2) => (checkType env ty1; checkType env ty2)

    | IABSty (tys,ty) => (checkTypes env tys; checkType env ty)

    | RECORDty fields => foldr (fn ((k,ty),_) => checkType env ty) 
                          () (SEnv.listItemsi fields)

(* Should we check something in tyCon? *)
    | CONty {tyCon=tyCon,args=tys} => checkTypes env tys

    | POLYty {boundtvars=btvs,body=ty} =>
      let val env = extendBtvEnv env btvs
                    handle Err msg =>
                    raise Err (msg ^^ (L_ELSE," : " ^ tyToString TY))
      in  checkType env ty
      end

    | BOXEDty => ()

    | ATOMty => ()

    | INDEXty (ty,_) => checkType env ty

    | BMABSty (tys,ty) => (checkTypes env tys; checkType env ty)

    | BITMAPty bitTys => checkBitTypes env bitTys

and checkTypes env ([]) = ()
  | checkTypes env (ty::tys) = 
    (checkType env ty; checkTypes env tys)

and checkBitTypes env [] = ()
  | checkBitTypes env (DC :: bitTys) = checkBitTypes env bitTys
  | checkBitTypes env (TRACE ty :: bitTys) =
      (checkType env ty; checkBitTypes env bitTys)

(* Constant *)
fun checkConst env const =
    case const of
      INT i => intty
    | WORD w => wordty
    | STRING s => stringty
    | REAL f => realty
    | CHAR c => charty

(* Expression *)
fun checkExp (env : tyckEnv) EXP TY =
   (case EXP of
      TPERROR => TY

    | TPCONSTANT const => checkConst env const

    | TPVAR (path, varInfo) => 
       let val id = #name varInfo
           val ty = #ty varInfo
       in
       (case SEnv.find (#varEnv env, id) of
         SOME idState =>
          (case idState of
            VARID varInfo => 
             (let val id' = #name varInfo   (* TODO: id=id'? *)
                  val ty' = #ty varInfo 
                  val iEnv = #btvEnv env
              in
              case eqTy iEnv iEnv ty ty' of
                true => ty
              | false => raise ERREXP
                          (id ^ "'s annotated type (in VAR) " ^ 
                           tyToString ty ^ 
                           " doesn't agree with " ^ 
                           tyToString ty')
              end)
          | _ => raise ERREXP (id ^ "'s idState is not VARID"))
       | NONE => raise ERREXP ("VAR " ^ id ^ " is not found"))
      end

(*
    | TPGLOBAL (path, varInfo) =>
      let val id = #name varInfo
          val ty = #ty varInfo
      in
      (case SEnv.find (#gEnv env, id) of
        SOME (VARID varInfo) => 
          (let val ty' = #ty varInfo 
               val iEnv = #btvEnv env
           in
           if eqTy iEnv iEnv ty ty' then ty
           else raise ERREXP 
                 (id ^ "'s annotated type (in GLOBAL) " ^ 
                  tyToString ty ^ 
                  "(" ^
                  pr ty ^ 
                  ")" ^
                  " doesn't agree with " ^ 
                  tyToString ty' ^
                  "(" ^
                  pr ty' ^ 
                  ")" )
           end )
*)
      | _ => raise ERREXP ("GLOBALVAR " ^ id ^ " is not found"))
      end

    | TPPRIMAPPLY (primInfo,tylist,expoption) =>
      let val polyty = #ty primInfo
          val _ = checkTypes env (polyty :: tylist)
          val ty = skipInd polyty
          val (btvEnv,ty) = 
                case ty of
                  POLYty {boundtvars=btvEnv,body=ty} 
                    => (btvEnv,ty)
                | _ => (IEnv.empty, ty)
          val _ = if IEnv.numItems btvEnv <> length tylist
                  then raise ERREXP (
                              "Poly type " ^
                              tyToString polyty ^
                              " instantiated with " ^ 
                              " the unexpected # of types " ^
                              "[" ^ tysToString tylist ^ "]" ^
                              " (in PRIMAPPLY)")
                  else ()

          val subst = ListPair.foldr 
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tylist)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = leqKinds env (IEnv.listItems btvEnv') tylist

          val ty = TypesUtils.substBTvar subst ty

          val ty = skipInd ty
          val ty = case (ty, expoption) of 
                     (FUNty (ty1,ty2), SOME exp) => 
                     let val ty1' = checkExp env exp ty1
                         val iEnv = #btvEnv env
                     in
                         if eqTy iEnv iEnv ty1 ty1' 
                         then ty2
                         else raise ERREXP (
                                     tyToString ty1 ^ " <> " ^
                                     tyToString ty1' )
                     end
                   | (_, NONE) => ty
                   | (_, _) => raise ERREXP (
                                     tyToString ty ^ 
                                     " should be a function type")
      in ty
      end

    | TPOPRIMAPPLY (oprimInfo,tylist,expoption) =>
      let val polyty = #ty oprimInfo
          val _ = checkTypes env (polyty :: tylist)
          val ty = skipInd polyty

          val (btvEnv,ty) = 
                case ty of
                  POLYty {boundtvars=btvEnv,body=ty} 
                    => (btvEnv,ty)
                | _ => (IEnv.empty, ty)

          val iEnv = #btvEnv env

          fun isOverloadedTy (btvKind as 
                             {recKind=OVERLOADED tys,
                              eqKind=_,
                              rank=_,
                              index=_}) ty = 
                (if List.exists (fn ty' => eqTy iEnv iEnv ty ty') tys 
                 then ()
                 else raise ERREXP (
                       tyToString ty ^ 
                       " never allowed to be substituted for " ^
                       "an OVERLOADED type variable " ^
                       prBtv btvKind ^ "(in OPRIMAPPLY)" ))

            | isOverloadedTy btvKind ty = 
              raise ERREXP (
                     "Illegal attempt to instantiate " ^
                     "a non-OVERLOADED type variable " ^
                     prBtv btvKind ^ " with " ^
                     tyToString ty ^ "(in OPRIMAPPLY)" )

          val _ = if IEnv.numItems btvEnv <> length tylist
                  then raise ERREXP (
                              "Poly type " ^
                              tyToString polyty ^
                              " instantiated with " ^ 
                              " the unexpected # of types " ^
                              "[" ^ tysToString tylist ^ "]" ^
                              " (in OPRIMAPPLY)")
                  else map (fn (btvKind, ty) => 
                               isOverloadedTy btvKind ty)
                           (ListPair.zip (IEnv.listItems btvEnv, tylist))

          val subst = ListPair.foldr 
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tylist)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = leqKinds env (IEnv.listItems btvEnv') tylist

          val ty = TypesUtils.substBTvar subst ty

          val ty = skipInd ty
          val ty = case (ty, expoption) of 
                     (FUNty (ty1,ty2), SOME exp) => 
                     let val ty1' = checkExp env exp ty1
                         val iEnv = #btvEnv env
                     in
                         if eqTy iEnv iEnv ty1 ty1' 
                         then ty2
                         else raise ERREXP (
                                     tyToString ty1 ^ " <> " ^
                                     tyToString ty1' )
                     end
                   | (_, NONE) => ty
                   | (_, _) => raise ERREXP (
                                     tyToString ty ^ 
                                     " should be a function type")
      in ty
      end

    | TPCONSTRUCT (path,conInfo,tylist,expoption) =>
      let val polyty = #ty conInfo
          val _ = checkTypes env (polyty :: tylist)
          val polyty = skipInd polyty

          val id    = #name conInfo
          val tyCon = #tyCon conInfo
          val isfun = #funtyCon conInfo

          val tyname  = #name tyCon
          val arity   = #arity tyCon
          val datacon = !(#datacon tyCon)

          val tyConEnv  = #tyConEnv env

          val _ =
              case SEnv.find (tyConEnv, tyname) of
                SOME (TYCON tyCon') 
                  => if eqTyCon tyCon tyCon' 
                     then () (* i.e., tyCon=tyCon' *)
                     else 
                     raise ERREXP ("TyCons don't agree: " ^
                                prTyCon tyCon ^ " <> " ^
                                prTyCon tyCon' )
              | _ => raise ERREXP ("Datatype " ^ 
                               tyname ^ " is not found" )
          val _ = 
              case SEnv.find (datacon, id) of
                SOME (CONID conInfo') 
                  => if eqConInfo env conInfo conInfo' 
                     then ()
                     else raise ERREXP 
                            ("ConInfos don't agree : " ^
                              prConInfo conInfo ^ "<>" ^
                              prConInfo conInfo' )
              | _ => 
              (case SEnv.find (#gEnv env, id) of
                 SOME (CONID conInfo')
                   => if eqConInfo env conInfo conInfo'
                      then ()
                      else raise ERREXP
                            ("Exception ConInfos don't agree : " ^
                              prConInfo conInfo ^ "<>" ^
                              prConInfo conInfo' )
               | _ => raise ERREXP
                            ("Exception constructor " ^ id ^ 
                             " is not found" ))

          val (btvEnv,ty) =
                case polyty of
                  POLYty {boundtvars=btvs,body=ty} => (btvs,ty)
                | ty => (IEnv.empty,ty)

          val nbtvEnv = IEnv.numItems btvEnv
          val ntylist = length tylist

          val _ = if nbtvEnv=arity then ()
                  else raise ERREXP (
                        "Data constructor has type " ^
                        tyToString polyty ^ 
                        " while ariry is annotated as " ^
                        Int.toString arity )

          val _ = if nbtvEnv=ntylist orelse ntylist=0
                  then ()
                  else raise ERREXP (
                        "Poly type " ^ tyToString polyty ^ 
                        " instantiated with " ^
                        " the unexpected # of types " ^
                        "[" ^ tysToString tylist ^ "] " ^
                        " (in CONSTRUCT)")

          val subst = ListPair.foldr
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tylist)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = if ntylist<>0
                  then leqKinds env (IEnv.listItems btvEnv') tylist
                  else []

          val ty = if ntylist<>0 
                   then TypesUtils.substBTvar subst ty
                   else polyty

          val ty = skipInd ty

          val ty = case (ty, expoption, isfun) of
                     (FUNty (ty1,ty2), SOME exp, true) =>
                     let val ty1' = checkExp env exp ty1
                         val iEnv = #btvEnv env
                     in
                         if eqTy iEnv iEnv ty1 ty1' 
                         then ty2
                         else raise ERREXP (
                               tyToString ty1 ^ " <> " ^
                               tyToString ty1' )
                     end
                   | (_, NONE, false) => ty
                   | (_, _, _) => raise ERREXP (
                          "Constructor argument has type " ^
                          tyToString ty ^ " and " ^
                          "functyCon=" ^ 
                          Bool.toString isfun )
      in ty
      end

    | TPAPP (exp,ty,exp') => 
      let val _ = checkType env ty
          val tyf = checkExp env exp ty
          val tyf = skipInd tyf
          val ty = 
              case tyf of
                (FUNty (ty1,ty2)) =>
                let val iEnv = #btvEnv env
                in
                if eqTy iEnv iEnv tyf ty 
                then let val tya = checkExp env exp' ty1
                     in  if eqTy iEnv iEnv tya ty1 
                         then ty2
                         else raise ERREXP 
                            ("Argument type " ^ 
                             tyToString tya ^ 
                             " doesn't agree with " ^
                             tyToString ty1)
                     end
                else raise ERREXP 
                            ("Type annotation (in APP) " ^
                             tyToString ty ^ 
                             " doesn't agree with " ^
                             tyToString tyf )
                end
              | _ => raise ERREXP
                            (tyToString tyf ^ 
                             " should be a function type" )
       in ty
      end

    | TPMONOLET (binds,exp) => (*  bind = varInfo * exp  *)
      let val varEnv = checkBinds env binds
          val env = extendVarEnv env varEnv
      in
          checkExp env exp TY
      end

    | TPLET (decls, exps, tys) =>
      let val (tyConEnv,varEnv) = checkDecls env decls
          val env = extendTyConEnv env tyConEnv
          val env = extendVarEnv env varEnv
      in
          checkExps env tys exps
      end


    | TPRECORD (fields,ty) =>
      let val _ = checkType env ty
          val fieldEnv = checkFields env fields ty
          val recordty = RECORDty fieldEnv
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv recordty ty 
                  then ()
                  else raise ERREXP
                        (tyToString recordty ^ " <> " ^
                         tyToString ty ) 
      in  ty
      end

    | TPSELECT (label,exp,ty) =>
      let val _ = checkType env ty
          val tyexp = checkExp env exp ty
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty tyexp
                  then ()
                  else raise ERREXP
                        (tyToString ty ^ " <> " ^ 
                         tyToString tyexp )

          val tyexp = skipInd tyexp
          val fieldtyEnv = 
              case tyexp of
                RECORDty fieldtyEnv => fieldtyEnv
              | BOUNDVARty i =>
                (case IEnv.find (#btvEnv env,i) of
                   SOME btvKind =>
                   (case #recKind btvKind of
                      UNIV => raise ERREXP
                       (tyToString (BOUNDVARty i) ^
                        " has Kind UNIV" )
                    | REC fieldtyEnv => fieldtyEnv
                    | OVERLOADED _ => raise ERREXP
                       (tyToString (BOUNDVARty i) ^
                        " has Kind OVERLOADED" ))
                 | NONE => raise ERREXP
                      (tyToString (BOUNDVARty i) ^ 
                       " is not found" ))
              | ty => raise ERREXP
                      (tyToString ty ^ " is not a record type" )
          val fieldty = 
              case SEnv.find (fieldtyEnv,label) of
                SOME ty => ty
              | NONE => raise ERREXP
                               ("Field label " ^ label ^
                                " is not found" )
      in  fieldty
      end

    | TPRAISE (exp,ty) =>
      let val ty' = checkExp env exp exnty
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty' exnty 
                  then ()
                  else raise ERREXP
                         (tyToString ty' ^ " is not an exception type")
      in  ty
      end

    | TPHANDLE (exp,varInfo,exp') =>
      let val ty = checkExp env exp TY
          val id = #name varInfo
          val ety = #ty varInfo
          val iEnv = #btvEnv env
          val env' = 
               if eqTy iEnv iEnv exnty ety
               then extendVarEnv env 
                     (SEnv.singleton (id,VARID varInfo))
               else raise ERREXP (tyToString ety ^ " <> " ^
                                       tyToString exnty )
          val ty' = checkExp env' exp' TY
          val _ = if eqTy iEnv iEnv ty ty' 
                  then ()
                  else raise ERREXP (
                         "Expr and handler " ^ 
                         "don't agree : " ^
                         tyToString ty ^ " <> " ^ 
                         tyToString ty' )
      in  ty
      end

    | TPCASE (exp,tye,patbinds,tyr,caseKind,loc) => 
      let val _ = checkTypes env [tye,tyr]
          val ty = checkExp env exp tye
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv tye ty 
                  then ()
                  else raise ERREXP (
                              "Type annotation (in CASE) " ^
                              tyToString tye ^
                              " doesn't agree with " ^
                              tyToString ty ^
                              " (for case expr)" )
          val (ty1,ty2) = checkPatBinds env patbinds tyr
          val _ = if eqTy iEnv iEnv tye ty1
                  then ()
                  else raise ERREXP (
                           "Type annotation (in CASE) " ^
                           tyToString tye ^ 
                           " doesn't agree with " ^
                           tyToString ty1 ^
                           " (for case patterns)" )
          val _ = if eqTy iEnv iEnv tyr ty2
                  then ()
                  else raise ERREXP (
                           "Type annotation (in CASE) " ^
                           tyToString tyr ^ 
                           " doesn't agree with " ^
                           tyToString ty2 ^
                           " (for case body expr)" )                          
      in  ty2
      end

    | TPFN (varInfo,ty,exp) =>
      let val _ = checkType env ty
          val ty1 = #ty varInfo
          val id = #name varInfo
          val env = extendVarEnv env 
                      (SEnv.singleton (id,VARID varInfo))
          val ty2 = checkExp env exp ty
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty ty2 
                  then ()
                  else raise ERREXP (
                        "Type annotation (in FN) " ^
                         tyToString ty ^ 
                        " doesn't agree with " ^
                         tyToString ty2 )
      in 
          FUNty (ty1,ty2) 
      end

    | TPPOLYFN (btvs,varInfo,ty,exp) => 
      let val env = extendBtvEnv env btvs

          val id = #name varInfo
          val env = extendVarEnv env 
                      (SEnv.singleton (id,VARID varInfo))

          val _ = checkType env ty

          val ty1 = #ty varInfo
          val _ = checkType env ty1

          val ty2 = checkExp env exp ty
          val fty = FUNty (ty1,ty2)
       
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty ty2
                  then ()
                  else raise ERREXP (
                        "Type annotation (in POLYFN) " ^
                        tyToString ty ^ 
                        " doesn't agree with " ^
                        tyToString ty2 )
      in  POLYty {boundtvars=btvs,body=fty}
      end

    | TPPOLY (btvs,ty,exp) =>
      let val env = extendBtvEnv env btvs

          val _ = checkType env ty

          val ty' = checkExp env exp ty

          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty ty'
                  then ()
                  else raise ERREXP (
                        "Type annotation (in POLY) " ^
                        tyToString ty ^
                        " doesn't agree with " ^
                        tyToString ty' )
      in  POLYty {boundtvars=btvs,body=ty}
      end

    | TPTAPP (exp,ty,tys) =>
      let val _ = checkTypes env (ty :: tys)

          val polyty = checkExp env exp ty
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty polyty
                  then ()
                  else raise ERREXP 
                         ("Type annotation (in TAPP) " ^
                          tyToString ty ^ 
                          " doesn't agree with " ^
                          tyToString polyty )
          val ty = skipInd ty
          val (btvEnv,ty) = 
                 case ty of
                   POLYty {boundtvars=btvs, body=ty} => (btvs,ty)
                 | ty => (IEnv.empty, ty)
          val _ = if IEnv.numItems btvEnv <> length tys
                  then raise ERREXP
                        ("Poly type " ^
                          tyToString polyty ^
                         " instantiated with " ^
                         " the unexpected # of types " ^
                         "[" ^ tysToString tys ^ "]" ^
                         " (in TPTAPP)" )
                  else ()

          val subst = ListPair.foldr
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tys)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = leqKinds env (IEnv.listItems btvEnv') tys

          val ty = TypesUtils.substBTvar subst ty
      in  ty
      end

    | TPSEQ (exps,tys) => 
      checkExps env tys exps
    )
    handle Err msg =>
    raise Err (msg ^^ (L_PAT,at_exp env EXP))

and checkExps env [] [] = raise ERREXP ("Expression list is empty")
  | checkExps env [ty] [exp] = 
    let val ty' = checkExp env exp ty
        val iEnv = #btvEnv env
    in
        if eqTy iEnv iEnv ty ty'
        then ty
        else raise ERREXP ("Type mismatch: " ^ 
                        tyToString ty ^ " <> " ^ 
                        tyToString ty' ^
                        at_exp env exp)
    end
  | checkExps env (ty::tys) (exp::exps) = 
    let val ty' = checkExp env exp ty
        val iEnv = #btvEnv env
    in
        if eqTy iEnv iEnv ty ty' 
        then checkExps env tys exps
        else raise ERREXP ("Type mismatch: "  ^ 
                        tyToString ty ^ " <> " ^ 
                        tyToString ty' ^
                        at_exp env exp)
    end
  | checkExps env _ _ = 
     raise ERREXP ("Mismatched # of exprs and types in an expression list")

(* Fields *)
and checkFields env fields ty = 
    let val fieldtys = 
            case ty of
              RECORDty fieldEnv => fieldEnv
            | _ => raise ERREXP (tyToString ty ^
                         " is not a record type")
    in
        foldr (fn ((id,e),fieldEnv) => 
               let val tyf = case SEnv.find (fieldtys, id) of
                               SOME tyf => tyf
                             | NONE => raise ERREXP (id ^ 
                                        " is missing in a record type " ^ 
                                        tyToString ty)
                   val ty = checkExp env e tyf
               in  SEnv.insert (fieldEnv,id,ty)
               end)
              SEnv.empty (SEnv.listItemsi fields)
    end


(* Pattern *)
and checkPat env PAT =
   (case PAT of
      TPPATWILD (ty,loc) => 
      let val _ = checkType env ty
      in  (ty, SEnv.empty)
      end

    | TPPATVAR (varInfo,loc) =>
      let val id = #name varInfo
          val ty = #ty varInfo
          val _ = checkType env ty
      in  (ty, SEnv.singleton (id,VARID varInfo))
      end

    | TPPATCONSTANT (const,ty,loc) =>
      let val _ = checkType env ty

          val cty = checkConst env const
          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty cty
                  then ()
                  else raise ERRPAT
                         ("Type annotation (in PATCONSTANT) " ^
                         tyToString ty ^ 
                          " doesn't agree with " ^
                         tyToString cty )
      in  (ty, SEnv.empty)
      end

    | TPPATCONSTRUCT (path,conInfo,tys,patoption,ty,loc) => 
      let val _ = checkTypes env (tys @ [ty])

          val annty = ty

          val id       = #name conInfo

          val polyty   = #ty conInfo
          val polyty   = skipInd polyty

          val tyCon    = #tyCon conInfo
          val funtyCon = #funtyCon conInfo

          val tyname  = #name tyCon
          val arity   = #arity tyCon
          val datacon = !(#datacon tyCon)

          val tyConEnv  = #tyConEnv env

          val _ =
              case SEnv.find (tyConEnv, tyname) of
                SOME (TYCON tyCon') 
                  => if eqTyCon tyCon tyCon' then ()
                     else
                     raise ERRPAT ("TyCons don't agree: " ^
                                prTyCon tyCon ^ " <> " ^
                                prTyCon tyCon' )
                        
              | _ => raise ERRPAT ("Datatype " ^ tyname ^
                                " is not found" )
          val _ =
              case SEnv.find (datacon, id) of
                SOME (CONID conInfo') =>
                   if eqConInfo env conInfo conInfo' then ()
                   else raise ERRPAT
                           ("ConInfos don't agree : " ^
                             prConInfo conInfo ^
                             prConInfo conInfo' )
              | _ => 
               (* In case the type of data constructor is exn *)
               (case SEnv.find (#gEnv env, id) of
                  SOME (CONID conInfo') 
                    => if eqConInfo env conInfo conInfo' then ()
                       else raise ERRPAT
                           ("Exception ConInfos don't agree : " ^
                             prConInfo conInfo ^
                             prConInfo conInfo' )
                | _ => raise ERRPAT
                               ("Exception constructor pattern " ^ 
                                 id ^ " is not found" ))

          val (btvEnv,bodyty) =
                case polyty of
                  POLYty {boundtvars=btvEnv,body=ty} => (btvEnv,ty)
                | _ => (IEnv.empty,polyty)

          val nbtvEnv = IEnv.numItems btvEnv
          val ntylist = length tys

          val _ = if nbtvEnv=arity 
                  then ()
                  else raise ERRPAT (
                        "Data constructor pattern has type " ^
                        tyToString polyty ^ 
                        " while ariry is annotated as " ^
                        Int.toString arity )

          val _ = if nbtvEnv = ntylist orelse ntylist=0
                  then ()
                  else raise ERRPAT
                        ("Poly type " ^ 
                          tyToString polyty ^
                         " instantiated with " ^
                         "the unexpected # of types " ^
                         "[" ^ tysToString tys ^ "]" ^
                         " (in PATCONSTRUCT) ")

          val subst = ListPair.foldr
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tys)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = if ntylist <> 0 
                  then leqKinds env (IEnv.listItems btvEnv') tys
                  else []

          val instty = if ntylist <> 0
                       then TypesUtils.substBTvar subst bodyty
                       else polyty

          val instty = skipInd instty
          val (ty,patvarEnv) = 
                case (instty, patoption, funtyCon) of
                  (FUNty (ty1,ty2), SOME pat, true) => 
                   let val (ty,patvarEnv) = checkPat env pat
                       val iEnv = #btvEnv env
                   in  if eqTy iEnv iEnv ty1 ty
                       then (ty2,patvarEnv)
                       else raise ERRPAT
                             ("Pattern type " ^
                              tyToString ty1 ^ 
                              " doesn't agree with " ^
                              tyToString ty )
                   end
                | (_, NONE, false) => (ty, SEnv.empty)
                | (_, _, _) => raise ERRPAT
                             ("Data constructor pattern has type " ^
                               tyToString instty ^ " with " ^
                               Bool.toString funtyCon ^
                              " as funtyCon")

          val iEnv = #btvEnv env
          val ty = if eqTy iEnv iEnv annty ty
                   then ty
                   else raise ERRPAT (
                          "Type annotation (in PATCONSTRUCT) " ^ 
                          tyToString annty ^
                          " doesn't agree with " ^
                           tyToString ty )


      in (ty,patvarEnv)
      end

    | TPPATRECORD (patfields,ty,loc) => 
      let val _ = checkType env ty

          val (fieldEnv,patvarEnv) = checkPatFields env patfields
          val ty = skipInd ty
          val recty = RECORDty fieldEnv

          val fieldEnv' = 
          case ty of
            RECORDty fieldEnv'
            => if leqRecKind env (REC fieldEnv) (REC fieldEnv')
               then ()
               else raise ERRPAT
                      (tyToString ty ^ " <> " ^
                       tyToString recty )
          | BOUNDVARty i 
            => (case IEnv.find (#btvEnv env,i) of
                  SOME {recKind=REC fieldEnv',...} 
                  => if leqRecKind env (REC fieldEnv) (REC fieldEnv')
                     then ()
                     else raise ERRPAT
                     (tyToString ty ^ 
                      " don't have the same record Kind as " ^
                      tyToString recty )
                | SOME {recKind=UNIV,...} 
                  => raise ERRPAT
                     (tyToString ty ^ " must have a record Kind" )
                | _ => raise ERRPAT
                       (tyToString ty ^ " is not found " )
               )
          | _ => raise ERRPAT
                      (tyToString ty ^ " <> " ^
                       tyToString recty )
      in  (ty, patvarEnv)
      end

    | TPPATLAYERED (pat,pat',loc) => 
      let val varInfo = 
                case pat of
                  TPPATVAR (varInfo,loc) => varInfo
                | _ => raise ERRPAT ("Illformed layered pattern" )
          val (ty,patvarEnv) = checkPat env pat'
          val vty = #ty varInfo

          val iEnv = #btvEnv env
          val _ = if eqTy iEnv iEnv ty vty 
                  then ()
                  else raise ERRPAT
                        ("Type annotation (in PATLAYERED) " ^
                         tyToString vty ^ 
                         " doesn't agree with " ^
                         tyToString ty )
          val id = #name varInfo
          val patvarEnv = mergePatVarEnv patvarEnv 
                           (SEnv.singleton (id,VARID varInfo))
      in  (ty, patvarEnv)
      end)

    handle Err msg =>
    raise Err (msg ^^ (L_DECL,at_pat env PAT))

and checkPatFields env patfields = 
    foldr (fn ((id,pat),(fieldEnv,patvarEnv)) => 
              let val (ty,patvarEnv') = checkPat env pat
              in  (SEnv.insert (fieldEnv,id,ty),
                   mergePatVarEnv patvarEnv patvarEnv')
              end)
          (SEnv.empty,SEnv.empty)
          (SEnv.listItemsi patfields)

and checkPatBind env (pat,exp) TY =
    let val (ty1,varEnv) = checkPat env pat
        val env = extendVarEnv env varEnv
        val ty2 = checkExp env exp TY
    in  (ty1,ty2)
    end

and checkPatBinds env [] TY = raise ERRPAT ("Empty matches")
  | checkPatBinds env [patbind] TY = checkPatBind env patbind TY
  | checkPatBinds env (patbind::patbinds) TY =
    let val (ty1,ty2) = checkPatBind env patbind TY
        val (ty1',ty2') = checkPatBinds env patbinds TY
        val iEnv = #btvEnv env
    in  if eqTy iEnv iEnv ty1 ty1' andalso 
           eqTy iEnv iEnv ty2 ty2' 
        then (ty1, ty2)
        else raise ERRPAT (
               tyToString ty1 ^ " => " ^ tyToString ty2 ^
               " doesn't agree with " ^
               tyToString ty1' ^ " => " ^ tyToString ty2')

        
    end

(* Binding *)
and checkBindsPossiblyWithWild env binds = 
    let fun checkBinds' env varEnv []            = varEnv
          | checkBinds' env varEnv (bind::binds) =
            let val (valId,exp) = bind
                val (varInfo,tyann,isWild) = 
                    case valId of
                      VALIDVAR varInfo => (varInfo, #ty varInfo, false)
                    | VALIDWILD ty => ({name="_",ty=ty}, ty, true)
                val ty = checkExp env exp tyann
                val vty = #ty varInfo

                val iEnv = #btvEnv env
                val _ = if isWild 
                        then ()
                        else 
                         if eqTy iEnv iEnv ty vty
                         then ()
                         else raise ERRDEC
                          ("Bound expr and var have different types: " ^
                           tyToString ty ^ " <> " ^
                           tyToString vty)
                val id = #name varInfo
                val varEnv' = if isWild 
                              then SEnv.empty
                              else SEnv.singleton (id,VARID varInfo)
                val env = extendVarEnv env varEnv'
                val varEnv = mergeVarEnv varEnv varEnv'
            in
                checkBinds' env varEnv binds
            end
    in checkBinds' env SEnv.empty binds
    end

and checkBinds env binds =
    let val binds = map (fn (varInfo,exp) => 
                          (VALIDVAR varInfo,exp)) binds
    in  checkBindsPossiblyWithWild env binds
    end

and checkRecBinds env recbinds =
    let val (varEnv,binds) = 
             foldr 
              (fn ((varInfo,ty,exp),(varEnv,binds)) =>
               let val id = #name varInfo
                   val vty = #ty varInfo
                   val iEnv = #btvEnv env
                   val _ = if eqTy iEnv iEnv ty vty 
                           then ()
                           else raise ERRDEC
                                  ("Bound expr and var have " ^
                                   "different types: " ^
                                   tyToString ty ^ " <> " ^ 
                                   tyToString vty)
               in (mergeVarEnv varEnv 
                    (SEnv.singleton (id,VARID varInfo)),
                  binds @ [(varInfo,exp)])
               end) (SEnv.empty,[]) recbinds
        val env = extendVarEnv env varEnv

    in  checkBinds env binds
    end

(* Declaration *)
and checkDecl env DECL =
   (case DECL of
      TPVAL binds => 
      let val varEnv = checkBindsPossiblyWithWild env binds
      in  (SEnv.empty, varEnv)
      end

    | TPVALREC recbinds => 
      let val varEnv = checkRecBinds env recbinds
      in  (SEnv.empty, varEnv)
      end

    | TPVALPOLYREC (btvEnv,recbinds) => 
      let val env = extendBtvEnv env btvEnv
          val varEnv = checkRecBinds env recbinds
          val vars = foldr 
                       (fn (({name=id,...},_,_),vars) => (id :: vars))
                       [] recbinds
          val ididStates = SEnv.listItemsi varEnv
          val ididStates =
              map (fn (id,idState) => 
                   case (List.find (fn x=>x=id) vars, idState) of
                     (SOME _,VARID {name=id',ty=ty'})
                           => (id, VARID {
                                name=id',
                                ty=POLYty {boundtvars=btvEnv,body=ty'}})
                   | (_,_) => (id, idState)) ididStates
          val varEnv = foldr (fn ((id,idState),varEnv) =>
                              SEnv.insert(varEnv,id,idState))
                              SEnv.empty ididStates
      in  (SEnv.empty, varEnv)
      end

    | TPLOCALDEC (decls, decls') =>
      let val (tyConEnv,varEnv) = checkDecls env decls
          val env = extendTyConEnv env tyConEnv
          val env = extendVarEnv env varEnv
      in  checkDecls env decls'
      end

    | TPTYPE tyBindInfos =>
      let fun checkTyBindInfos [] = ()

(*
            | checkTySyns ((tvars,id,ty)::tysyns) =
              let val tyConEnv = #tyConEnv env 
                  val _ = 
                      case SEnv.find (tyConEnv,id) of
                        SOME (TYFUN {name,tyargs,body}) 
                          => () (* TODO: What do we have to check? *)
                      | _ => raise ERRDEC (
                                   "Type synonym " ^
                                   id ^ " is not found " )
              in  checkTySyns tysyns
              end
*)

            | checkTyBindInfos (TYCON tyCon :: tyBindInfos) = 
              let val _ = "What am I going to do here?"
              in  ()
              end          

            | checkTyBindInfos (TYFUN {name,tyargs,body} :: tyBindInfos) = 
              let val _ = "What am I going to do here?"
              in  ()
              end          

          val _ = checkTyBindInfos tyBindInfos
      in  (SEnv.empty, SEnv.empty)
      end

    | TPDATADEC tyCons => 
      let fun assumeEQ btvs = 
                IEnv.map (fn {recKind,eqKind,rank,index} =>
                  {recKind=recKind,eqKind=EQ,
                   rank=rank,index=index}) btvs

          val flag = ref false;

          val (tyConEnv,errmsg) = foldr
          (fn (tyCon,(tyConEnv,errmsg)) =>
           let 
              val datacon = !(#datacon tyCon)
              val name    = #name tyCon
              val arity   = #arity tyCon

              val eqk'    =
                   foldr 
                   (fn (idState,eqk) =>
                    case idState of
                      CONID conInfo =>
                       let val polyty   = #ty conInfo
                           val polyty   = skipInd polyty 
                           val funtyCon = #funtyCon conInfo

                           val (env,ty,arity') =
                            case polyty of
                              POLYty {boundtvars=btvs,body=ty} =>
                              let val btvs = assumeEQ btvs
                                  val env = extendBtvEnv env btvs
                                  val nbtvs = IEnv.numItems btvs
                              in  (env,ty,nbtvs)
                              end
                            | ty => (env,ty,0)

                           val _ = 
                            if arity=arity' then ()
                            else raise ERRDEC
                                  ("Arities don't agree : " ^
                                   tyToString polyty ^
                                   "arity=" ^ Int.toString arity )

                           val eqk' =
                            case (ty,funtyCon) of
                              (FUNty (ty1,_),true) => 
                               #1 (calcEqRecKind env ty1)
                            | (_,false) => EQ
                            | _ => raise ERRDEC
                                    ("funtyCon is " ^ 
                                     Bool.toString funtyCon ^
                                     ", but ty is " ^
                                     tyToString ty )

                       in  if eqk=EQ andalso eqk'=EQ 
                           then EQ 
                           else NONEQ
                      end
                    | VARID Info => 
                       raise ERRDEC
                         (#name Info ^ 
                          " should be a data constructor" )
                    | PRIM Info => 
                       raise ERRDEC
                         (#name Info ^ 
                          " should be a data constructor" )
                    | OPRIM oInfo =>
                       raise ERRDEC
                         (#name oInfo ^
                          " should be a data constructor" ))
                   EQ (SEnv.listItems datacon)

              val eqk = !(#eqKind  tyCon)

              val errmsg = 
                  if eqk=eqk' 
                      then errmsg
                      else 
                         (flag:=true; 
                          errmsg ^ 
                          ("Datatype " ^ name ^
                           " has an annotation " ^
                           prEqKind eqk ^ 
                          ", but it should have " ^
                          prEqKind eqk') )

              val id     = #name tyCon
              val tyConEnv' = SEnv.singleton (id,TYCON tyCon)
              val tyConEnv  = mergeExclusiveTyConEnv tyConEnv tyConEnv'

          in  (tyConEnv,errmsg)
          end) (SEnv.empty, "") tyCons
             

          val varEnv = foldr
              (fn (tyCon,varEnv) => 
               let val varEnv' = ! (#datacon tyCon)
               in  mergeVarEnv varEnv varEnv'
               end) SEnv.empty tyCons

          val errmsg = 
              if !flag 
              then ("\n" ^ "Datatype declaration:\n" ^
                       prTyConEnv tyConEnv ^ "\n" ^ errmsg)
              else errmsg

          val _ = if !flag then raise ERRDEC (errmsg ^ "\n" )
                  else ();

      in (tyConEnv, varEnv)
      end  

    | TPDATAREPDEC (s,s') =>
      let val s = ""
      in  (SEnv.empty, SEnv.empty)
      end

    | TPEXNDEC conInfos =>
      let val varEnv = 
              foldr 
               (fn (conInfo as 
                   {name=id,funtyCon=_,ty=ty,exntag=_,tyCon=_},
                    varEnv) =>
               let val exnid = VARID {name=id,ty=ty}
               in     
                   SEnv.insert (varEnv, id, exnid)
               end) SEnv.empty conInfos
      in  (SEnv.empty, varEnv)
      end 

    | TPEXNREPDEC (s,s') =>
      let val s = ""
      in  (SEnv.empty, SEnv.empty)
      end

    | TPINFIXDEC _ => (SEnv.empty, SEnv.empty)

    | TPINFIXRDEC(n, names) => (SEnv.empty, SEnv.empty)

    | TPNONFIXDEC(names) => (SEnv.empty, SEnv.empty))

    handle Err msg =>
    raise Err (msg ^^ (L_PRG,at_decl env DECL))

and checkDecls env decls = 
    let fun checkDecls' env tyConEnv varEnv [] = (tyConEnv,varEnv)
          | checkDecls' env tyConEnv varEnv (decl::decls) =
            let val (tyConEnv',varEnv') = checkDecl env decl
                val env = extendTyConEnv env tyConEnv'
                val env = extendVarEnv env varEnv'
                val tyConEnv = mergeTyConEnv tyConEnv tyConEnv'
                val varEnv = mergeVarEnv varEnv varEnv'
            in
                checkDecls' env tyConEnv varEnv decls
            end
    in
        checkDecls' env SEnv.empty SEnv.empty decls
    end

(*  and checkTopLevelDecls env decls =  *)
(*      let val _ = print (Int.toString (length decls)) *)
(*          fun checkDecls' env tyConEnv varEnv [] = (tyConEnv,varEnv) *)
(*            | checkDecls' env tyConEnv varEnv (decl::decls) = *)
(*              let val (tyConEnv',varEnv') = checkDecl env decl *)
(*                  val env    = extendTyConEnv env tyConEnv' *)
(*                  val env    = extendGlobalVarEnv env varEnv' *)
(*                  val tyConEnv  = mergeTyConEnv tyConEnv tyConEnv' *)
(*                  val varEnv = mergeVarEnv varEnv varEnv' *)
(*              in *)
(*                  checkDecls' env tyConEnv varEnv decls *)
(*              end *)
(*      in *)
(*          checkDecls' env SEnv.empty SEnv.empty decls *)
(*      end *)

fun typecheckTP 
    {context= 
       {utvarEnv=_,
        tyConEnv=tyConEnv,
        varEnv=_,
        globalEnv=gEnv,
        globalBitmapEnv=_
       },
     newContext=
       newContext as
       {utvarEnv=_,
        tyConEnv=newtyConEnv,
        varEnv=newvEnv,
        globalEnv=_,
        globalBitmapEnv=_
       },
     declarations=binds}
    =
    let 
        val env = 
            {tyConEnv=mergeTyConEnv tyConEnv newtyConEnv,
             gEnv=mergeVarEnv gEnv newvEnv,
             btvEnv=IEnv.empty,
             varEnv=SEnv.empty}
        val (tyConEnv',varEnv') =
            (checkDecls env binds) 
            handle Err (_,msg) => 
            if !stopIfAnyTypeError 
            then raise Control.Bug msg
            else (print ("Typecheck fail:\n" ^ msg); 
                        (SEnv.empty, SEnv.empty))

        val _ = print "\nSuccessfully typechecked.\n"

    in (newContext,binds)
    end
end

end

(* Test cases.

val x = 1+2+3+4+5;
val f = fn x => x;
val x = (fn x => x) 1;
val f = fn x => (#name x, #addr x, #id x);
val f = fn x => #name (#addr (#id x));
val f = fn x => x; val p = (f, f); val g = #1 p; (fn a=>fn b=>a) (g 1) (g "1");
val f = ((fn x=>x) 1, fn x => fn y => (x+1, y)); 
val f = ((fn x=>x) 1, fn x => fn y => (x+1, y)); val g = (#2 f) 1;
val xval = fn {X=x,...} => x;
val yval = fn {Y=y,...} => y;
val methods = {getX = xval, getY = yval};
val point1 = {Methods=methods, State={X=1,Y=2}};
let val f = fn x => x; val f = (f,f); val f = (f,f); val f = (f,f) in (#1 (#1 (#1 f))) 1 end;

datatype 'a D = C of 'a ;
datatype 'a D = C of 'a * 'a ;
datatype 'a D = C of 'a->'a ;
datatype 'a D = C; C;
datatype ('a,'b) D = C of 'a;
C 1;
datatype ('a,'b) P = L of 'a * 'b | R of 'b * 'a;

datatype ('a,'b,'c) D = C of 'a * 'b * 'c;

val r= {x=1, y="1", z=fn x=>x};
(fn x=>x) {x=1, y="1"};
#y ((fn x=>x) {x=1, y="1"});
((fn x => x+1) 2) handle x => 2;

datatype X = Cx of Y and  Y = Cy of X;

datatype 'a X = Cx of ('a,'a) Y | Cz and ('a,'b) Y = Cy of 'a X | Cw;

datatype 'a X = Cx of ('a,'a->'a) Y | Cz and ('a,'b) Y = Cy of 'a X | Cw;

datatype 'a X = Cx of 'a * ('a,'a->'a) Y | Cz and ('a,'b) Y = Cy of 'a X | Cw;

datatype 'a X = Cx of 'a->'a * ('a,'a->'a) Y | Cz and ('a,'b) Y = Cy of 'a X | Cw;

val f=fn x=>x=x;

datatype 'a L = Cons of 'a * 'a L | Nil; fn x => case x of Cons (h,t) => t | Nil => Nil;

let val f = fn x => #name x in (f {name="x",age=20}, f {weight=30,name="y"}) end;

val sum =
    let
          datatype 'a List = Nil | Cons of 'a * 'a List
          fun Sum Nil = 0 | Sum (Cons(x,xs)) = x + Sum xs
          fun Interval n = if n=0 then Nil else Cons(n,Interval(n-1))
    in Sum(Interval 10) end;

*)

