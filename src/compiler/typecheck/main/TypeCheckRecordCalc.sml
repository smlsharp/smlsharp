(**
 * @copyright (c) 2006, Tohoku University.
 *)

structure TypeCheckRecordCalc =
struct

open Types RecordCalc

structure CTU = ConstantTypeUtils
structure P  = Path
structure PT = PredefinedTypes
structure TF = TypeFormatter
structure TU = TypesUtils

(* Flags *)
val typeCheck      = ref true
val errMsgLevel    = ref 1      (* e.g., decl=>expr=>pat *)
val MaxSourceLines = ref 5

(* Error messages  *)
datatype ErrLevel = L_EXPR | L_PAT | L_DECL | L_ELSE | L_PRG

exception Err of (ErrLevel list) * string

exception ErrMsg of string

infix 6 ^^

fun op ^^ ((ls,msg), (l,msg')) = 
    let val b  = case ls of
                   []    => true
                 | (h::_) => h<>l andalso (length ls  <= !errMsgLevel)
    in  if b 
        then (l::ls, msg ^ msg')
        else (ls,msg)
    end

fun locToString loc =
    "\n" ^
    SMLFormat.prettyPrint [SMLFormat.Columns 60] (Loc.format_loc loc) ^
    " Typecheck fail (rc): "

fun ERRELS loc msg = Err ([L_ELSE], locToString loc ^ msg ^ "\n")
fun ERREXP loc msg = Err ([L_EXPR], locToString loc ^ msg ^ "\n")
fun ERRPAT loc msg = Err ([L_PAT], locToString loc ^ msg ^ "\n")
fun ERRDEC loc msg = Err ([L_DECL], locToString loc ^ msg ^ "\n")

(* Typecheck environment *)
type tcEnv = {varEnv:varEnv, btvEnv:btvEnv, tyConEnv:Types.tyConEnv}

fun getVarEnv   {varEnv, btvEnv, tyConEnv} = varEnv
fun getBtvEnv   {varEnv, btvEnv, tyConEnv} = btvEnv
fun getTyConEnv {varEnv, btvEnv, tyConEnv} = tyConEnv


(* Environment handling *)
fun mergeTyConEnv tyConEnv tyConEnv' =
    mergeTyConEnvWith (fn (x,y)=>y) tyConEnv  tyConEnv'

and mergeTyConEnvWith f tyConEnv tyConEnv' =
    SEnv.unionWith f (tyConEnv, tyConEnv')

fun mergePatVarEnv patvarEnv patvarEnv' =
    SEnv.unionWith 
     (fn (x,y)=> raise ERRELS Loc.noloc ("duplicated pattern variables"))
      (patvarEnv, patvarEnv')

fun mergeVarEnv varEnv varEnv' =
    SEnv.unionWith (fn (x,y)=>y) (varEnv, varEnv')

fun mergeBtvEnv btvEnv btvEnv' =
    IEnv.unionWith (fn (x,y)=>y) (btvEnv, btvEnv')

fun extendBtvEnv {tyConEnv=tyConEnv, btvEnv=btvEnv, varEnv=varEnv} btvEnv' =
    let 
        val n      = IEnv.numItems btvEnv
        val btvEnv = IEnv.unionWith (fn (x,y) => y) (btvEnv,btvEnv')
    in  {tyConEnv=tyConEnv, btvEnv=btvEnv, varEnv=varEnv}
    end

fun extendVarEnv {tyConEnv=tyConEnv, btvEnv=btvEnv, varEnv=varEnv} varEnv' =
    let val varEnv = mergeVarEnv varEnv varEnv'
    in  {tyConEnv=tyConEnv, btvEnv=btvEnv, varEnv=varEnv}
    end

fun extendTyConEnv 
    {tyConEnv=tyConEnv, btvEnv=btvEnv, varEnv=varEnv} tyConEnv' =
    let val tyConEnv = mergeTyConEnv tyConEnv tyConEnv'
    in  {tyConEnv=tyConEnv, btvEnv=btvEnv, varEnv=varEnv}
    end

(* Utility *)
fun limit_lines s = 
    let val size = String.size s
        fun f i c = if i+1=size
                    then s
                    else 
                      (case String.sub (s,i) of
                          #"\n" 
                           =>
                             (if c = !MaxSourceLines
                              then String.substring (s,0,i) ^ " ...\n"
                              else f (i+1) (c+1))
                       | _ => f (i+1) c)
    in  if !MaxSourceLines = 0 
        then ""
        else f 0 0
    end

fun at_exp env exp =
    limit_lines
    (
    "In expression:\n" ^
    (SMLFormat.prettyPrint
         [SMLFormat.Columns 60] (format_rcexp [(0,getBtvEnv env)] exp)
     handle _ => "") ^
    "\n"
    )

fun at_decl env decl =
    limit_lines
    (
    "In declaration:\n" ^
    SMLFormat.prettyPrint
        [SMLFormat.Columns 60]
        (format_rcdecl [(0,getBtvEnv env)] decl) ^
    "\n"
    )

fun prOpt f (NONE)   = ""
  | prOpt f (SOME v) = f v

fun prList f xs = 
    let
       fun g []  = ""
         | g [x] = f x
         | g (x::xs) = f x ^ ", " ^ g xs 
    in  "[" ^ g xs ^ "]"
    end

fun prMap toList prLabel prElem smap = 
    "{" ^
    foldr (fn ((k,ty),s) => prLabel k ^ " : " ^ prElem ty ^ " " ^ s)
      "" (toList smap) ^
    "}"

fun prSMap prElem smap = prMap SEnv.listItemsi (fn x=>x) prElem smap
fun prIMap prElem imap = prMap IEnv.listItemsi Int.toString prElem imap

(* Printing types as they are *) 

(* This routine *)
(*  - should be used only temporarily. *)
(*  - must be shared by all type checkers. *)
(*  - should be replaced by SMLFormat printer. *)

(* pr is prTy! *)
fun pr (ERRORty) =
       "ERRORty"
  | pr (DUMMYty i) =
       "DUMMYty" ^ Int.toString i
  | pr (TYVARty (ref (TVAR tvkind))) =
       "TYVARty (ref (TVAR (" ^ prTvKind tvkind ^ ")))"
  | pr (TYVARty (ref (SUBSTITUTED ty))) =
       "TYVARty (ref (SUBSTITUTED (" ^ pr ty ^  ")))"
  | pr (BOUNDVARty i) =
       "BOUNDVARty " ^ Int.toString i
  | pr (FUNty (ty1,ty2)) =
       "FUN (" ^ pr ty1 ^ "," ^ pr ty2 ^ ")"
  | pr (RECORDty fieldEnv) =
       "RECORDty (" ^ prSMap pr fieldEnv ^ ")"
  | pr (CONty {tyCon=tycon,args=tys}) =
       "CONty { tyCon=" ^ prTyCon tycon ^ ", args=" ^ prs tys ^ "}"
  | pr (POLYty {boundtvars=btvs,body=ty}) =
       "POLYty { boundtvars=" ^ prIMap prBtvKind btvs ^ ", body=" ^ pr ty ^ "}"
  | pr BOXEDty =
       "BOXEDty"
  | pr ATOMty  =
       "ATOMty"
  | pr (INDEXty (ty,s)) =
       "INDEXty (" ^ pr ty ^ "," ^ s ^ ")"
  | pr (BMABSty (tys,ty)) =
       "BMABSty (" ^ prs tys ^ "," ^ pr ty ^ ")"
  | pr (BITMAPty tys) =
       "BITMAPty " ^ prs tys
  | pr (ALIASty (ty1,ty2)) =
       "ALIASty (" ^ pr ty1 ^ ", " ^ pr ty2 ^ ")"
  | pr (FUNMty (tys,ty)) =
       "FUNMty (" ^ prs tys ^ ", " ^ pr ty ^ ")"
  | pr (BITty i) =
       "BITty " ^ Int.toString i
  | pr (UNBOXEDty) =
       "UNBOXEDty"
  | pr (DBLUNBOXEDty) =
       "DBLUNBOXEDty"
  | pr (OFFSETty tys) =
       "OFFSETty " ^ prs tys
  | pr (TAGty i) =
       "TAGty " ^ Int.toString i
  | pr (SIZEty i) =
       "SIZEty " ^ Int.toString i
  | pr (DOUBLEty) =
       "DOUBLEty "
  | pr (PADty tys) =
       "PADty " ^ prs tys
  | pr (PADCONDty (tys,i)) =
       "PADCONDty (" ^ prs tys ^ ", " ^ Int.toString i ^ ")"
  | pr (FRAMEBITMAPty is) =
       "FRAMEBITMAPty (" ^ prList Int.toString is ^ ")"
  | pr (ABSSPECty (ty1,ty2)) =
       "ABSSPECty (" ^ pr ty1 ^ ", " ^ pr ty2 ^ ")"
  | pr (SPECty ty) =
       "SPECty (" ^ pr ty ^ ")"

and prs tys = prList pr tys

and prTvKind {id=id, recKind=reckind, eqKind=eqkind, tyvarName=stropt} =
    "{ id="        ^ tidToString id         ^
    ", recKind="   ^ prRecKind reckind      ^
    ", eqKind="    ^ prEqKind eqkind        ^
    ", tyvarName=" ^ prOpt (fn x=>x) stropt ^
    "}"

and prTyBindInfo (TYCON tycon) =
    "TYCON " ^ prTyCon tycon
  | prTyBindInfo (TYFUN tyfun) =
    "TYFUN " ^ prTyFun tyfun
  | prTyBindInfo (TYSPEC {spec,impl}) =
    "TYSPEC { spec=" ^ prTySpec spec           ^
           ", impl=" ^ prOpt prTyBindInfo impl ^
           "}"

and prTyCon {name, strpath, tyvars, id, abstract, eqKind, boxedKind, datacon} =
    "{ name="      ^ name                         ^
    ", strpath="   ^ prPath strpath               ^
    ", tyvars="    ^ prList Bool.toString tyvars  ^
    ", id="        ^ ID.toString id               ^
    ", abstract="  ^ Bool.toString abstract       ^
    ", eqKind="    ^ prEqKind (!eqKind)           ^
    ", boxedKind=" ^ prOpt pr (!boxedKind)        ^
(*     ", datacon="   ^ prVarEnv (!datacon)          ^ *)
    ", datacon="   ^ "..."                        ^
    "}"

and prTyFun {name=name,tyargs=btvs,body=ty} =
    "{ name="   ^ name                  ^
    ", tyargs=" ^ prIMap prBtvKind btvs ^
    ", body="   ^ pr ty                 ^
    "}"

and prTySpec {name=name, id=id, strpath=path, eqKind=eqkind,
              tyvars=boolList, boxedKind=tyOption} =
    "{ name="      ^ name                          ^
    ", id="        ^ ID.toString id                ^
    ", strpath="   ^ prPath path                   ^
    ", eqKind="    ^ prEqKind eqkind               ^
    ", tyvars="    ^ prList Bool.toString boolList ^
    ", boxedKind=" ^ prOpt pr tyOption             ^
    "}"

and prTyConEnv smap = prSMap prTyBindInfo smap

and prVarEnv  smap = prSMap prIdState smap
and prVarEnv' smap = prSMap (fn _ => "...;") smap

and prIdState (FFID ffpinfo) = prFFPInfo ffpinfo
  | prIdState (VARID vpinfo) = prVarPathInfo vpinfo
  | prIdState (CONID cpinfo) = prConPathInfo cpinfo
  | prIdState (PRIM  pinfo)  = prPrimInfo pinfo
  | prIdState (OPRIM opinfo) = prOprimInfo opinfo

and prFFPInfo {name=name, strpath=path, ty=ty, argTys=tys} =
    "{ name="    ^ name        ^
    ", strpath=" ^ prPath path ^
    ", ty="      ^ pr ty       ^
    ", argTys="  ^ prs tys     ^
    "}"

and prVarPathInfo {name=name, strpath=path, ty=ty} =
    "{ name="    ^ name        ^
    ", strpath=" ^ prPath path ^
    ", ty="      ^ pr ty       ^
    "}"

and prConPathInfo {name=name, strpath=path, funtyCon=b, ty=ty,
                   tag=i, tyCon=tycon} =
    "{ name="     ^ name            ^
    ", strpath="  ^ prPath path     ^
    ", funtyCon=" ^ Bool.toString b ^
    ", ty="       ^ pr ty           ^
    ", tag="      ^ Int.toString i  ^
    ", tyCon="    ^ prTyCon tycon   ^
    "}"

and prPrimInfo {name=name,ty=ty} =
    "{ name=" ^ name  ^
    ", ty="   ^ pr ty ^
    "}"

and prOprimInfo {name=name, ty=ty, instances=pinfomap} =
    "{ name="      ^ name                       ^
    ", ty="        ^ pr ty                      ^
    ", instances=" ^ prSMap prPrimInfo pinfomap ^
    "}"

and prEqKind EQ    = "EQ"
  | prEqKind NONEQ = "NONEQ"

and prRecKind UNIV             = "UNIV"
  | prRecKind (REC fieldtys)   = "REC " ^ prSMap pr fieldtys
  | prRecKind (OVERLOADED tys) = "OVERLOADED " ^ prs tys

and prBtvKind {index=i, recKind=rek, eqKind=eqk} =
    "{ index="   ^ Int.toString i ^
    ", recKind=" ^ prRecKind rek  ^
    ", eqKind="  ^ prEqKind eqk   ^
    "}"

and prPath (NilPath) = "NilPath"
  | prPath (PStructure (id,name,path)) =
    "PStructure (" ^ ID.toString id ^
    ", "           ^ name           ^
    ", "           ^ prPath path    ^
    ")"

and prConInfo {name,funtyCon,ty,exntag,tyCon} =
    "{" ^
    "name="     ^ name                    ^ ",\n" ^
    "funtyCon=" ^ Bool.toString funtyCon  ^ ",\n" ^
    "ty="       ^ TF.tyToString ty        ^ ",\n" ^
    "exntag="   ^ Int.toString exntag     ^ ",\n" ^
    "tyCon="    ^ prTyCon tyCon           ^
    "}"

fun tysToString tys =
    foldr (fn (ty,s) => TF.tyToString ty ^ ", " ^ s) "" tys

(* Skip 
   - Indirection through TYVARty
   - ALIASty
*)
fun skip (TYVARty (r as (ref (SUBSTITUTED ty)))) =
    (case ty of
       TYVARty (ref (tvState as (SUBSTITUTED _)))
           => (r := tvState; skip ty)
     | ty' => ty)
  | skip (ALIASty (_,ty)) = ty
  | skip (ty as _) = ty

(* Instantiation *)
fun instBtvEnv btvEnv subst = 
    IEnv.map 
     (fn {index=index, recKind=recKind, eqKind=eqKind} => 
      let val recKind = 
              case recKind of
                UNIV => UNIV
              | REC fieldtys => REC (SEnv.map (TU.substBTvar subst) fieldtys)
              (* Overloaded ids are all monomorphic. *)
              | OVERLOADED tys => OVERLOADED tys
      in {index=index, recKind=recKind, eqKind=eqKind}
      end) btvEnv

(* Kind/Type equality  *)

(* 
The first arg is the equality Kind of a bound type var. The second arg
is the  equality Kind of a type  to be instantiated to  the bound type
var.  Note that  the  meaning of  EQ and  NONEQ  in the  first arg  is
different from that in the second arg.
*)
fun leqEqKind eqKindBTVar eqKindTyInst =
    case (eqKindBTVar, eqKindTyInst) of
      (EQ,    EQ   ) => true   
    | (EQ,    NONEQ) => false
    | (NONEQ, EQ   ) => true
    | (NONEQ, NONEQ) => true

fun eqBtvKind iEnv1 iEnv2 {index=_, recKind=rek1, eqKind=eqk1} 
                          {index=_, recKind=rek2, eqKind=eqk2} =
    eqRecKind iEnv1 iEnv2 rek1 rek2 andalso eqk1=eqk2 

and eqRecKind iEnv1 iEnv2 UNIV UNIV = true
  | eqRecKind iEnv1 iEnv2 (REC rek1) (REC rek2) = 
    if SEnv.numItems rek1 <> SEnv.numItems rek2 
    then false
    else foldr (fn ((l,ty1),_) =>
                 case SEnv.find (rek2,l) of
                   SOME ty2 => eqTy iEnv1 iEnv2 ty1 ty2
                 | NONE => false) true 
                  (SEnv.listItemsi rek1)
  | eqRecKind _ _ _ _ = false

and eqBtvKinds iEnv1 iEnv2 [] [] = true
  | eqBtvKinds iEnv1 iEnv2 (k1::ks1) (k2::ks2) = 
    eqBtvKind iEnv1 iEnv2 k1 k2 andalso eqBtvKinds iEnv1 iEnv2 ks1 ks2
  | eqBtvKinds _ _ _ _ = false

(*
leqRecKind  is  used  to  check  if  the type  variables  of  a  given
polymorphic  type can  be  instantiated  with types  given  in a  type
application.
*)

and leqRecKind env UNIV UNIV    = true
  | leqRecKind env UNIV (REC _) = true
  | leqRecKind env (REC rek1) (REC rek2) = 
    if SEnv.numItems rek1 <= SEnv.numItems rek2 
    then foldr (fn ((l,ty1),_) =>
                 case SEnv.find (rek2,l) of
                   SOME ty2 
                        => let val iEnv = getBtvEnv env 
                           in  eqTy iEnv iEnv ty1 ty2
                           end
                 | NONE => false) true (SEnv.listItemsi rek1)
    else false

(* Every overloaded type variable is assumed to have Kind UNIV. *)

  | leqRecKind env (OVERLOADED _) UNIV = true

  | leqRecKind _ _ _ = false

and eqType env ty1 ty2 =
    let val ienv = getBtvEnv env
    in  eqTy ienv ienv ty1 ty2
    end

and eqTy iEnv1 iEnv2 ERRORty ERRORty = true

  | eqTy iEnv1 iEnv2 (DUMMYty _) (DUMMYty _) = true

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
            | NONE => raise ERRELS Loc.noloc
                        ("can't find the bound type variable " ^
                         Int.toString i)
        val btvKind2 =
            case IEnv.find(iEnv2,j) of
              SOME btvKind => btvKind
            | NONE => raise ERRELS Loc.noloc
                        ("can't find the bound type variable " ^
                         Int.toString j)
    in  eqBtvKind iEnv1 iEnv2 btvKind1 btvKind2
    end

  | eqTy iEnv1 iEnv2 (FUNty (tya1,tyr1)) (FUNty (tya2,tyr2)) =
     eqTy iEnv1 iEnv2 tya1 tya2 andalso 
     eqTy iEnv1 iEnv2 tyr1 tyr2

  | eqTy iEnv1 iEnv2 (RECORDty recty1) (RECORDty recty2) = 
     eqFieldTys iEnv1 iEnv2 recty1 recty2

  | eqTy iEnv1 iEnv2 (CONty {tyCon=tyCon1,args=tys1})
                     (CONty {tyCon=tyCon2,args=tys2}) =
     eqTyCon tyCon1 tyCon2 andalso eqTys iEnv1 iEnv2 tys1 tys2

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
     eqTy iEnv1 iEnv2 ty1 ty2 andalso l1=l2

  | eqTy iEnv1 iEnv2 (BMABSty (tys1,ty1)) (BMABSty (tys2,ty2)) =
     eqTys iEnv1 iEnv2 tys1 tys2 andalso eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 (BITMAPty tys1) (BITMAPty tys2) =
     eqTys iEnv1 iEnv2 tys1 tys2

(* Need to check! *)
  | eqTy iEnv1 iEnv2 (ALIASty (aliasty1,expandedty1)) ty2 =
     eqTy iEnv1 iEnv2 expandedty1 ty2

  | eqTy iEnv1 iEnv2 ty1 (ALIASty (aliasty2,expandedty2)) =
     eqTy iEnv1 iEnv2 ty1 expandedty2

  | eqTy iEnv1 iEnv2 (FUNMty (tys1,ty1)) (FUNMty (tys2,ty2)) =
     eqTys iEnv1 iEnv2 tys1 tys2 andalso eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 (BITty i) (BITty j) = i=j

  | eqTy iEnv1 iEnv2 (UNBOXEDty) (UNBOXEDty) = true

  | eqTy iEnv1 iEnv2 (DBLUNBOXEDty) (DBLUNBOXEDty) = true

  | eqTy iEnv1 iEnv2 (OFFSETty tys1) (OFFSETty tys2) =
     eqTys iEnv1 iEnv2 tys1 tys2

  | eqTy iEnv1 iEnv2 (TAGty i) (TAGty j) = i=j

  | eqTy iEnv1 iEnv2 (SIZEty i) (SIZEty j) = i=j

  | eqTy iEnv1 iEnv2 (DOUBLEty) (DOUBLEty) = true

  | eqTy iEnv1 iEnv2 (PADty tys1) (PADty tys2) = 
     eqTys iEnv1 iEnv2 tys1 tys2

  | eqTy iEnv1 iEnv2 (PADCONDty (tys1,i)) (PADCONDty (tys2,j)) = 
     eqTys iEnv1 iEnv2 tys1 tys2 andalso i=j

  | eqTy iEnv1 iEnv2 (FRAMEBITMAPty is) (FRAMEBITMAPty js) = is=js

  | eqTy iEnv1 iEnv2 (ABSSPECty (ty1,_)) ty2 =
     eqTy iEnv1 iEnv2 ty1 ty2 

  | eqTy iEnv1 iEnv2 ty1 (ABSSPECty (ty2,_)) =
     eqTy iEnv1 iEnv2 ty1 ty2 

  | eqTy iEnv1 iEnv2 (SPECty ty1) (SPECty ty2) =
     eqTy iEnv1 iEnv2 ty1 ty2

  | eqTy iEnv1 iEnv2 ty1 ty2 = false

and eqTyOpt iEnv1 iEnv2 (NONE)     (NONE)     = true
  | eqTyOpt iEnv1 iEnv2 (SOME ty1) (SOME ty2) = eqTy iEnv1 iEnv2 ty1 ty2
  | eqTyOpt iEnv1 iEnv2 (_)        (_)        = false

and eqFieldTys iEnv1 iEnv2 recty1 recty2 =
     if SEnv.numItems recty1 <> SEnv.numItems recty2 then false
     else foldr (fn ((k,ty1),b) => 
                  case SEnv.find (recty2,k) of
                    SOME ty2 => b andalso eqTy iEnv1 iEnv2 ty1 ty2
                  | NONE => false) true (SEnv.listItemsi recty1)

and eqTys iEnv1 iEnv2 [] []                   = true
  | eqTys iEnv1 iEnv2 (ty1::tys1) (ty2::tys2) = 
    eqTy iEnv1 iEnv2 ty1 ty2 andalso eqTys iEnv1 iEnv2 tys1 tys2
  | eqTys _ _ _ _                             = false

(* and eqTyCon tyCon tyCon' = PT.isSameTyCon tyCon tyCon' *)

and eqTyCon (tyCon  as {name=name, strpath=path, tyvars=bs, id=id,
                        abstract=abstract, eqKind=eqkind,
                        boxedKind=boxedkind, datacon=datacon})
            (tyCon' as {name=name', strpath=path', tyvars=bs', id=id',
                        abstract=abstract', eqKind=eqkind',
                        boxedKind=boxedkind', datacon=datacon'}) =
    name = name'

(* Something could be wrong here *)

(*     andalso P.comparePathByName (path, path') *)
(*     andalso bs = bs' *)
(*     andalso ID.compare (id, id') = EQUAL *)
(*     andalso abstract = abstract' *)
(*     andalso eqkind = eqkind' *)
(*     andalso eqTyOpt IEnv.empty IEnv.empty (!boxedkind) (!boxedkind') *)
(*     andalso datacon = datacon' *)


fun leqKinds env [] [] = []
  | leqKinds env (btv::btvs) (ty::tys) = 
    let val (eqk,rek) = leqKind env btv ty
    in  (eqk,rek) :: leqKinds env btvs tys
    end

and leqKind env (btv as {index=_,recKind=rek,eqKind=eqk}) ty =
    let val (eqk',rek')    = calcEqRecKind env ty
        val boolLeqEqKind  = leqEqKind eqk eqk'
        val boolLeqRecKind = leqRecKind env rek rek'
    in
        if boolLeqEqKind andalso boolLeqRecKind
        then (eqk,rek)
        else raise ErrMsg
(*               ("can't instantiate type variable " ^ *)
(*                " with " ^ *)
(*                TF.tyToString ty) *)
              ("can't instantiate type variable " ^
               prBtvKind btv ^
               " with " ^
               prEqKind eqk' ^
               " / " ^
               prRecKind rek' ^
               " in " ^
               pr ty ^
               " //// " ^
               TF.tyToString ty)
    end

and calcEqRecKind env TY =
    case TY of
      ERRORty => (NONEQ,UNIV)

    | DUMMYty i => (NONEQ,UNIV)

    | TYVARty (ref (SUBSTITUTED ty)) => calcEqRecKind env ty

    | TYVARty (ref (TVAR tvKind)) => (#eqKind tvKind, #recKind tvKind)

    | BOUNDVARty i =>
         (case IEnv.find (getBtvEnv env, i) of
            SOME {recKind=rek,eqKind=_,...} => (EQ,rek)
          | NONE => raise ErrMsg ( 
                      "ill-formed type: " ^
                      TF.tyToString TY ^ 
                      " is unbound" ))

    | FUNty (ty1,ty2) =>
      let val _ = calcEqRecKind env ty1
          val _ = calcEqRecKind env ty2
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
    | CONty {tyCon=tyCon, args=tys} =>
      let val arity = List.length (#tyvars tyCon)
          val nArgs = length tys
          val _ = if arity=nArgs
                  then ()
                  else raise ErrMsg
                        ("ill-formed type: " ^
                         TF.tyToString TY ^
                         "\n  " ^ 
                         Int.toString arity ^
                         " type argument(s) expected, but " ^
                         Int.toString nArgs ^
                         " type argument(s) available")
          val eqk = foldr (fn ((eqk,_),eqKind) => 
                           if eqk=EQ then eqKind else NONEQ)
                           EQ (map (calcEqRecKind env) tys)
          val eqKind = if #name tyCon = #name PT.refTyCon
                       then EQ
                       else if eqk=EQ 
                       then !(#eqKind tyCon)
                       else NONEQ
      in  (eqKind, UNIV)
      end

    | POLYty {boundtvars=btvEnv, body=ty} =>
      let val env = extendBtvEnv env btvEnv
          val _ = calcEqRecKind env ty
      in  (NONEQ,UNIV)
      end

    | BOXEDty => (NONEQ,UNIV)

    | ATOMty => (NONEQ,UNIV)

    | INDEXty (ty,label)=>
      let val (_,recKind) = calcEqRecKind env ty
          val (eqKind,recKind) =
              case recKind of
                UNIV => raise ErrMsg (
                          "ill-formed type " ^
                          TF.tyToString TY ^
                          ": " ^
                          TF.tyToString ty ^
                          " doesn't have label " ^
                          label)
              | REC fieldtys => 
                let val ty = case SEnv.find(fieldtys,label) of
                               SOME ty => ty
                             | NONE => raise ErrMsg (
                                        "ill-formed type " ^
                                        TF.tyToString TY ^
                                        ": label " ^
                                        label ^ 
                                        " not found")
                in  calcEqRecKind env ty
                end 
              | OVERLOADED _ =>
                        raise ErrMsg (
                          "ill-formed type " ^
                          TF.tyToString TY ^
                          ": " ^ 
                          TF.tyToString ty ^ 
                          "is overloaded")
      in  (eqKind,recKind)
      end

    | BMABSty (tys,ty) =>
      let val _ = map (calcEqRecKind env) tys
          val _ = calcEqRecKind env ty
      in  (NONEQ,UNIV)
      end

    | BITMAPty tys =>
      let val _ = map (calcEqRecKind env) tys
      in  (NONEQ,UNIV)
      end

    | ALIASty (ty1,ty2) =>calcEqRecKind env ty2

    | FUNMty (tys,ty) =>
      let val _ = map (calcEqRecKind env) tys
          val _ = calcEqRecKind env ty
      in  (NONEQ,UNIV)
      end

    | BITty i => (NONEQ,UNIV)

    | UNBOXEDty => (NONEQ,UNIV)

    | DBLUNBOXEDty => (NONEQ,UNIV)

    | OFFSETty tys => (NONEQ,UNIV)

    | TAGty i => (NONEQ,UNIV)

    | SIZEty i => (NONEQ,UNIV)

    | DOUBLEty => (NONEQ,UNIV)

    | PADty tys => (NONEQ,UNIV)

    | PADCONDty (tys,i) => (NONEQ,UNIV)

    | FRAMEBITMAPty is => (NONEQ,UNIV)

(* check SML definition book! *)
    | ABSSPECty (ty1,ty2) => (NONEQ,UNIV)

    | SPECty ty => (NONEQ,UNIV)

(*
fun matchConIdInfoConPathInfo 
    env
    (conIdInfo as {id=id,displayName=name,funtyCon=b,ty=ty,tag=i,tyCon=tycon})
    (conPathInfo as {name=name',strpath=path,funtyCon=b',ty=ty',tag=i,tyCon=tycon'})
    let
    in
       name=name' 
       andalso b=b' 
       andalso ty=ty'
       andalso eqTyCon tycon tycon'
    end
*)

(* The conversion of varIdInfo to varPathInfo in handling bindings *)
(* Need to check the validity of the use of NilPath! *)
fun varIdInfoToVarPathInfo {id=id, displayName=n, ty=ty} =
    {name=n, strpath=P.NilPath, ty=ty}

(* Well-formed types *)

fun checkType (env as {btvEnv=btvEnv,tyConEnv=tyConEnv,varEnv=varEnv}) TY loc =
    case TY of
      ERRORty => ()
    | DUMMYty i => ()
    | TYVARty (ref (SUBSTITUTED ty)) => checkType env ty loc
    | TYVARty (ref (TVAR tvKind)) => checkRecKind env (#recKind tvKind) loc
    | BOUNDVARty i => 
      (case IEnv.find (btvEnv, i) of
        SOME {index=_,recKind=rek,eqKind=_} => checkRecKind env rek loc
      | NONE => raise ERRELS loc
                       (TF.tyToString TY ^ 
                        " is unbound"))
    | FUNty (ty1,ty2) => (checkType env ty1 loc; checkType env ty2 loc)
    | RECORDty fields => foldr (fn ((k,ty),_) => checkType env ty loc) 
                          () (SEnv.listItemsi fields)
(* Should we check if tyCon is well-formed? *)
    | CONty {tyCon=tyCon,args=tys} => checkTypes env tys loc
    | POLYty {boundtvars=btvs, body=ty} =>
      let val env = extendBtvEnv env btvs
      in  checkType env ty loc
      end
    | BOXEDty => ()
    | ATOMty => ()
(* I guess there is one more thing to check something about s. *)
    | INDEXty (ty,s) => checkType env ty loc
    | BMABSty (tys,ty) => (checkTypes env tys loc; checkType env ty loc)
    | BITMAPty tys => checkTypes env tys loc
(* The alias needs not to be checked. *)
    | ALIASty (aliasty, expandedty) => checkType env expandedty loc
    | FUNMty (tys, ty) => (checkTypes env tys loc; checkType env ty loc)
    | BITty i => ()
    | UNBOXEDty => ()
    | DBLUNBOXEDty => ()
    | OFFSETty tys => checkTypes env tys loc
    | TAGty i => ()
    | SIZEty i => ()
    | DOUBLEty => ()
    | PADty tys => checkTypes env tys loc
    | PADCONDty (tys,i) => checkTypes env tys loc
    | FRAMEBITMAPty is => ()
    | ABSSPECty (ty1,_) => (checkType env ty1 loc
                            (* ; checkType env ty2 loc *)
                           )
    | SPECty ty => (checkType env ty loc)

and checkTyOpt env (NONE) loc = ()
  | checkTyOpt env (SOME ty) loc = checkType env ty loc

and checkTypes env [] loc = ()
  | checkTypes env (ty::tys) loc = 
    (checkType env ty loc; checkTypes env tys loc)

and checkRecKind env (UNIV) loc = ()
  | checkRecKind env (REC fields) loc = 
    foldr (fn (ty,_) => checkType env ty loc) () (SEnv.listItems fields)
  | checkRecKind env (OVERLOADED tys) loc = checkTypes env tys loc

(* Typecheck expressions *)

fun checkExp env exp =
    (
    case exp of
      RCFOREIGNAPPLY (expFn, tylistInst, expArg, tylistArgs, loc) =>
      let val polyty = checkExp env expFn
          val _      = checkTypes env ([polyty] @ tylistInst @ tylistArgs) loc
          val ty     = skip polyty
          val (btvEnv,ty) = 
               case ty of
                 POLYty {boundtvars=btvEnv,body=ty} => (btvEnv,ty)
               | _ => (IEnv.empty, ty)
          val _ = if IEnv.numItems btvEnv <> length tylistInst
                  then raise ERREXP loc (
                              "can't instantiate (foreignapply)" ^
                              "\n  type: " ^
                              TF.tyToString polyty ^
                              "\n  instance: " ^ 
                              tysToString tylistInst)
                  else ()
          val subst = ListPair.foldr 
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tylistInst)
          val btvEnv' = instBtvEnv btvEnv subst
          val _ = leqKinds env (IEnv.listItems btvEnv') tylistInst
                  handle ErrMsg errmsg =>
                  raise ERREXP loc (errmsg ^ "(foreignapply)")
          val ty = TU.substBTvar subst ty

          val ty = skip ty
          val tyArg = checkExp env expArg

          val (tys1,ty2) = case ty of
                     (FUNMty (tys1,ty2)) => (tys1,ty2)
                   | _ => raise ERREXP loc (
                           "multi-argument function type is expected: " ^
                           TF.tyToString ty)

          val _ = checkTypes env (tys1 @ [tyArg]) loc

          val tyArg = skip tyArg
          val _ = case tyArg of
                   (RECORDty tysmap) =>
                    let val tylistArgs' = SEnv.listItems tysmap
                        val iEnv = getBtvEnv env
                    in
                        if eqTys iEnv iEnv tylistArgs tylistArgs'
                        then ()
                        else raise ERREXP loc (
                           "operator and operand don't agree (foreignapply)" ^ 
                           "\n  operator domain: " ^ 
                           tysToString tylistArgs ^ 
                           "\n  operand: " ^ 
                           tysToString tylistArgs')
                    end
                  | _ => raise ERREXP loc (
                                 "record type is expected: " ^
                                 TF.tyToString ty)
      in ty2
      end

    | RCCONSTANT (const,loc) => CTU.constTy const
    | RCVAR (varIdInfo,loc) => #ty varIdInfo
    | RCGETGLOBAL (string,ty,loc) => ty

    | RCGETFIELD (exp,int,ty,loc) =>
      let val _ = checkType env ty loc
          val tyexp = checkExp env exp

          val BOXED_ARRAY_TYPE = 
              CONty{tyCon = PT.arrayTyCon, args =  [BOXEDty]}
          val ATOM_ARRAY_TYPE = 
              CONty{tyCon = PT.arrayTyCon, args =  [ATOMty]}
          val DOUBLE_ARRAY_TYPE = 
              CONty{tyCon = PT.arrayTyCon, args =  [DOUBLEty]}

      in  if eqType env tyexp BOXED_ARRAY_TYPE 
          orelse eqType env tyexp ATOM_ARRAY_TYPE
          orelse eqType env tyexp DOUBLE_ARRAY_TYPE
          then ty
          else raise ERREXP loc (
                       "unexpected type in getfield" ^
                       "\n  type: " ^
                       TF.tyToString tyexp)
      end

    | RCARRAY (expSize,expInitVal,tyElem,tyArr,loc) =>
      let val _ = checkType env tyElem loc
          val _ = checkType env tyArr loc
          val tySize = checkExp env expSize
          val tyInitVal = checkExp env expInitVal
          val _ = if eqType env tySize PT.intty = false
                  then raise ERREXP loc (
                               "array size type is not int: " ^
                               TF.tyToString tySize)
                  else ()
          val _ = if eqType env tyInitVal tyElem = false
                  then raise ERREXP loc (
                               "array element type" ^
                               "\n  expected: " ^
                               TF.tyToString tyElem ^
                               "\n  used: " ^
                               TF.tyToString tyInitVal)
                  else ()

          val BOXED_ARRAY_TYPE = 
              CONty{tyCon = PT.arrayTyCon, args =  [BOXEDty]}
          val ATOM_ARRAY_TYPE = 
              CONty{tyCon = PT.arrayTyCon, args =  [ATOMty]}
          val DOUBLE_ARRAY_TYPE = 
              CONty{tyCon = PT.arrayTyCon, args =  [DOUBLEty]}

          val _ = if eqType env tyElem BOXEDty
                  andalso eqType env tyArr BOXED_ARRAY_TYPE
                  then ()
                  else if eqType env tyElem ATOMty
                  andalso eqType env tyArr ATOM_ARRAY_TYPE
                  then ()
                  else if eqType env tyElem DOUBLEty
                  andalso eqType env tyArr DOUBLE_ARRAY_TYPE
                  then ()
                  else raise ERREXP loc (
                        "array and element types don't agree" ^ 
                        "\n  array type: " ^ 
                        TF.tyToString tyArr ^
                        "\n  element type: " ^
                        TF.tyToString tyElem)
      in  tyArr
      end

    | RCPRIMAPPLY (primInfo,tylist,expoption,loc) =>
      let val polyty = #ty primInfo
          val _ = checkTypes env (polyty :: tylist) loc
          val ty = skip polyty
          val (btvEnv,ty) = 
                case ty of
                  POLYty {boundtvars=btvEnv,body=ty} 
                    => (btvEnv,ty)
                | _ => (IEnv.empty, ty)
          val _ = if IEnv.numItems btvEnv <> length tylist
                  then raise ERREXP loc (
                              "can't instantiate " ^
                              #name primInfo ^
                              "\n  type: " ^
                              TF.tyToString polyty ^
                              "\n  instance: " ^ 
                              tysToString tylist)
                  else ()

          val subst = ListPair.foldr 
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tylist)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = leqKinds env (IEnv.listItems btvEnv') tylist
                  handle ErrMsg errmsg =>
                  raise ERREXP loc ("(primitive application)\n" ^ errmsg)

          val ty = TypesUtils.substBTvar subst ty

          val ty = skip ty
          val ty = case (ty, expoption) of 
                     (FUNty (ty1,ty2), SOME exp) => 
                     let val ty1' = checkExp env exp
                         val iEnv = getBtvEnv env
                     in
                         if eqTy iEnv iEnv ty1 ty1' 
                         then ty2
                         else raise ERREXP loc (
                                     "operator and operand don't agree" ^
                                     "\n  operator: " ^ 
                                     #name primInfo ^
                                     "\n  operator domain: " ^ 
                                     TF.tyToString ty1' ^
                                     "\n  operand: " ^ 
                                     TF.tyToString ty1)
                     end
                   | (_, NONE) => ty
                   | (_, _) => raise ERREXP loc (
                                     "function type is expected (primapp)" ^
                                     "\n  type: " ^
                                     TF.tyToString ty)
      in ty
      end

    | RCOPRIMAPPLY (oprimInfo, tyList,expOption,loc) =>
      let val polyty = #ty oprimInfo
          val _ = checkTypes env (polyty :: tyList) loc
          val ty = skip polyty

          val (btvEnv,ty) = 
                case ty of
                  POLYty {boundtvars=btvEnv,body=ty} 
                    => (btvEnv,ty)
                | _ => (IEnv.empty, ty)

          val iEnv = #btvEnv env

          fun isOverloadedTy (btvKind as 
                             {recKind=OVERLOADED tys,
                              eqKind=_,
                              index=_}) ty = 
                (if List.exists (fn ty' => eqTy iEnv iEnv ty ty') tys 
                 then ()
                 else raise ERREXP loc (
                       "overloaded variable not defined at type: " ^
                       "\n  symbol:" ^ #name oprimInfo ^ 
                       "\n  type:" ^ TF.tyToString ty))

            | isOverloadedTy btvKind ty = 
              raise ERREXP loc (
                     "non-overloaded variable: " ^ 
                     #name oprimInfo)

          val _ = if IEnv.numItems btvEnv <> length tyList
                  then raise ERREXP loc (
                         "can't instantiate " ^
                         #name oprimInfo ^
                         "\n  type: " ^
                         TF.tyToString polyty ^
                         "\n  instance: " ^ 
                         tysToString tyList)
                  else map (fn (btvKind, ty) => 
                               isOverloadedTy btvKind ty)
                           (ListPair.zip (IEnv.listItems btvEnv, tyList))

          val subst = ListPair.foldr 
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tyList)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = leqKinds env (IEnv.listItems btvEnv') tyList
                  handle ErrMsg errmsg =>
                  raise ERREXP loc ("(overloaded primitive application)\n" ^
                           errmsg)

          val ty = TypesUtils.substBTvar subst ty

          val ty = skip ty
          val ty = case (ty, expOption) of 
                     (FUNty (ty1,ty2), SOME exp) => 
                     let val ty1' = checkExp env exp
                         val iEnv = #btvEnv env
                     in
                         if eqTy iEnv iEnv ty1 ty1' 
                         then ty2
                         else raise ERREXP loc (
                                     "operator and operand don't agree" ^
                                     "\n  operator: " ^ 
                                     #name oprimInfo ^
                                     "\n  operator domain: " ^ 
                                     TF.tyToString ty1' ^
                                     "\n  operand: " ^ 
                                     TF.tyToString ty1)
                     end
                   | (_, NONE) => ty
                   | (_, _) => raise ERREXP loc (
                                 "function type is expected (oprimapp)" ^
                                 "\n  type: " ^
                                 TF.tyToString ty)
      in ty
      end

    | RCCONSTRUCT (conIdInfo,tyList,expOption,loc) =>
      let val polyty = #ty conIdInfo
          val _ = checkTypes env (polyty :: tyList) loc
          val polyty = skip polyty

          val tyCon = #tyCon conIdInfo
          val isfun = #funtyCon conIdInfo

          val tyname  = #name tyCon
          val arity   = List.length (#tyvars tyCon)
          val datacon = !(#datacon tyCon)

          val (btvEnv,ty) =
                case polyty of
                  POLYty {boundtvars=btvs,body=ty} => (btvs,ty)
                | ty => (IEnv.empty,ty)

          val nbtvEnv = IEnv.numItems btvEnv
          val ntyList = length tyList

          val _ = if nbtvEnv=arity then ()
                  else raise ERREXP loc (
                        "arity annotation mismatch" ^
                        "\n  symbol: " ^ 
                        #displayName conIdInfo ^
                        "\n  type: " ^ 
                        TF.tyToString polyty ^ 
                        "\n  arity: " ^ 
                        Int.toString arity)

          val _ = if nbtvEnv=ntyList orelse ntyList=0
                  then ()
                  else raise ERREXP loc (
                        "can't instantiate data constructor" ^
                        #displayName conIdInfo ^
                        "\n  type: " ^ 
                        TF.tyToString polyty ^ 
                        "\n  instance: " ^
                        tysToString tyList)

          val subst = ListPair.foldr
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tyList)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = if ntyList<>0
                  then leqKinds env (IEnv.listItems btvEnv') tyList
                  else []

          val ty = if ntyList<>0 
                   then TypesUtils.substBTvar subst ty
                   else polyty

          val ty = skip ty

          val ty = case (ty, expOption, isfun) of
                     (FUNty (ty1,ty2), SOME exp, true) =>
                     let val ty1' = checkExp env exp
                         val iEnv = #btvEnv env
                     in
                         if eqTy iEnv iEnv ty1 ty1' 
                         then ty2
                         else raise ERREXP loc (
                                "operator and operand don't agree" ^
                                "\n  operator: " ^ 
                                #displayName conIdInfo ^
                                "\n  operator domain: " ^ 
                                TF.tyToString ty1' ^
                                "\n  operand: " ^ 
                                TF.tyToString ty1)
                     end
                   | (_, NONE, false) => ty
                   | (_, _, _) => raise ERREXP loc (
                          "non-functional constructor applied to operand" ^
                          "\n  operator: " ^ 
                          #displayName conIdInfo ^
                          "\n  type: " ^
                          TF.tyToString ty)
      in ty
      end

    | RCAPP (exp,ty,exp',loc) =>
      let val _ = checkType env ty loc
          val tyf = checkExp env exp
          val tyf = skip tyf
          val ty = 
              case tyf of
                (FUNty (ty1,ty2)) =>
                if eqType env tyf ty 
                then let val tya = checkExp env exp'
                     in  if eqType env tya ty1 
                         then ty2
                         else raise ERREXP loc (
                                "operator and operand don't agree" ^
                                "\n  operator domain: " ^ 
                                TF.tyToString ty1 ^
                                "\n  operand: " ^ 
                                TF.tyToString tya)
                     end
                else raise ERREXP loc
                            ("type annotation mismatch in application" ^
                             "\n  annotated type: " ^ 
                             TF.tyToString ty ^ 
                             "\n  inferred type: " ^
                             TF.tyToString tyf)
              | _ => raise ERREXP loc
                            ("function type is expected (app)" ^
                             "\n  type: " ^
                             TF.tyToString tyf ^
                             "\n  exp: " ^
                             SMLFormat.prettyPrint
                                 [SMLFormat.Columns 60]
                                 (format_rcexp [(0,getBtvEnv env)] exp) ^
                             "\n exp': " ^SMLFormat.prettyPrint
                                 [SMLFormat.Columns 60]
                                 (format_rcexp [(0,getBtvEnv env)] exp') ^
                             "\n  isRCVAR?: " ^
                             (case exp of
                                RCVAR (varIdInfo,loc) => TF.tyToString (#ty varIdInfo)
                              | _ => "***") )
       in ty
      end

    | RCAPPM (exp,tyFun,argExpList,loc) =>
      let val _    = checkType env tyFun loc
          val tyOp = checkExp env exp
          val _    = 
              if eqType env tyFun tyOp
              then ()
              else raise ERREXP loc (
                    "type annotation mismatch (function)" ^
                    "\n  expression: " ^ 
                    TF.tyToString tyOp ^
                    "\n  annotation: " ^ 
                    TF.tyToString tyFun)

          val tyOp = skip tyOp
          val (tys1, ty2) =
              case tyOp of
                (FUNty (ty1,ty2))  => ([ty1], ty2)
              | (FUNMty (tys1,ty2)) => (tys1, ty2)
              | _ => raise ERREXP loc
                            ("function type is expected (appm): " ^
                             TF.tyToString tyOp)

          val tyArgs = map (checkExp env) argExpList
          val _ = if List.length tyArgs <> List.length tys1
                  then raise ERREXP loc (
                       "type annotation mismatch (arity)" ^
                       "\n  # of arguments: " ^ 
                       Int.toString (List.length tyArgs) ^
                       "\n  annotation: " ^
                       Int.toString (List.length tys1))
                  else ()

          val _ =
              foldr (fn ((formalTy,actualTy),()) =>
                if eqType env formalTy actualTy
                then ()
                else raise ERREXP loc (
                       "operator and operand don't agree" ^
                       "\n  operator domain: " ^ 
                       TF.tyToString actualTy ^
                       "\n  operand: " ^ 
                       TF.tyToString formalTy)) ()
                       (ListPair.zip (tyArgs, tys1))

      in ty2
      end

    | RCMONOLET (varIdInfoExpList,exp,loc) =>
      let val varEnv = checkVarIdInfoExpList env varIdInfoExpList loc
          val env = extendVarEnv env varEnv
      in
          checkExp env exp
      end

    | RCLET (declList,expList,tyList,loc) => 
      let val (tyConEnv,varEnv) = checkDecls env declList
          val env = extendTyConEnv env tyConEnv
          val env = extendVarEnv env varEnv
      in
          checkExps env tyList expList loc
      end

    | RCRECORD (fields,ty,loc) => 
      let val _ = checkType env ty loc
          val fieldEnv = checkFields env fields ty loc
          val recordty = RECORDty fieldEnv
          val _ = if eqType env recordty ty = false
                  then raise ERREXP loc
                        ("type annotation mismatch in record" ^
                         "\n  annotated type: " ^ 
                         TF.tyToString ty ^ 
                         "\n  inferred type: " ^
                         TF.tyToString recordty)
                  else ()
      in  ty
      end

    | RCSELECT (exp,label,ty,loc) => 
      let val _ = checkType env ty loc
          val tyexp = checkExp env exp
          val _ = if eqType env ty tyexp = false
                  then raise ERREXP loc
                        ("type annotation mismatch in select" ^
                         "\n  annotated type: " ^ 
                         TF.tyToString ty ^ 
                         "\n  inferred type: " ^
                         TF.tyToString tyexp)
                  else ()

          val tyexp = skip tyexp
          val fieldtyEnv = 
              case tyexp of
                RECORDty fieldtyEnv => fieldtyEnv
              | BOUNDVARty i =>
                (case IEnv.find (getBtvEnv env,i) of
                   SOME btvKind =>
                   (case #recKind btvKind of
                      UNIV => raise ERREXP loc
                       ("expression doesn't have record kind in select" ^
                        "\n  type: " ^ 
                        TF.tyToString (BOUNDVARty i))
                    | REC fieldtyEnv => fieldtyEnv
                    | OVERLOADED _ => raise ERREXP loc
                       ("expression doesn't have record kind in select" ^
                        "\n  type: " ^
                        TF.tyToString (BOUNDVARty i)))
                 | NONE => raise ERREXP loc
                      ("ill-formed type of expression in select" ^
                       "\n  type: " ^
                       TF.tyToString (BOUNDVARty i)))
              | ty => raise ERREXP loc
                      ("expression doesn't have record type in select" ^
                       "\n  type: " ^
                       TF.tyToString ty)
          val fieldty = 
              case SEnv.find (fieldtyEnv,label) of
                SOME ty => ty
              | NONE => raise ERREXP loc
                               ("label not found in select" ^
                                "\n  label: " ^ 
                                label)
      in  fieldty
      end

    | RCMODIFY (label,expRec,tyRec,exp,ty,loc) => 
      let val _ = checkType env tyRec loc
          val _ = checkType env ty loc

          val tyRec' = checkExp env expRec
          val ty'    = checkExp env exp

          val _ = if eqType env tyRec tyRec' = false
                  then raise ERREXP loc
                        ("type annotation mismatch in modify" ^
                         "\n  annotated record type: " ^
                         TF.tyToString tyRec ^
                         "\n  inferred record type: " ^
                         TF.tyToString tyRec')
                  else ()
          val _ = if eqType env ty ty' = false
                  then raise ERREXP loc
                        ("type annotation mismatch in modify" ^
                         "\n  annotated type: " ^
                         TF.tyToString ty ^ 
                         "\n  inferred type: " ^
                         TF.tyToString ty')
                  else ()

          val tyRec' = skip tyRec'
          val tySmap = 
              case tyRec' of
                RECORDty tySmap => tySmap

              | BOUNDVARty i => 
                (case IEnv.find (getBtvEnv env, i) of
                   SOME btvKind =>
                   (case #recKind btvKind of
                      UNIV => 
                        raise ERREXP loc
                          ("expression doesn't have record kind in modify" ^ 
                           "\n  type: " ^
                           TF.tyToString (BOUNDVARty i))
                    | REC tySmap => tySmap
                    | OVERLOADED _ => 
                        raise ERREXP loc
                          ("expression doesn't have record kind in modify" ^ 
                           "\n  type: " ^
                           TF.tyToString (BOUNDVARty i)))
                 | NONE =>
                        raise ERREXP loc
                               ("ill-formed type of expression in modify" ^
                                "\n  type: " ^
                                TF.tyToString (BOUNDVARty i)))
              | _ => raise ERREXP loc
                     (TF.tyToString tyRec' ^ 
                      " is not a record type in modify")

          val lty = case SEnv.find (tySmap, label) of
                      SOME lty => lty
                    | NONE => raise ERREXP loc
                                     ("label not found in modify" ^ 
                                      "\n  label: " ^ label)

          val _ = if eqType env ty lty = false
                  then raise ERREXP loc
                        ("type mismatch in modify" ^
                         "\n  annotated result type: " ^
                         TF.tyToString ty ^
                         "\n  inferred result type: " ^ 
                         TF.tyToString lty)
                  else ()
      in  lty
      end

    | RCRAISE (exp,ty,loc) => 
      let val _ = checkType env ty loc
          val tyExn = checkExp env exp
          val _ = if eqType env tyExn PT.exnty = false 
                  then raise ERREXP loc
                         ("exception type is expected in raise" ^
                          TF.tyToString tyExn)
                  else ()
      in  ty
      end

    | RCHANDLE (exp,varIdInfo,expHandler,loc) => 
      let val ty  = checkExp env exp
          val id  = #displayName varIdInfo
          val ety = #ty varIdInfo
          val envHandler = 
               if eqType env PT.exnty ety
               then extendVarEnv env 
                     (SEnv.singleton (id,
                         VARID (varIdInfoToVarPathInfo varIdInfo)))
               else raise ERREXP loc (
                            "type annotation mismatch in handle" ^
                            "\n  variable: " ^
                            #displayName varIdInfo ^
                            "\n  expected type: " ^
                            TF.tyToString PT.exnty ^
                            "\n  annotated type: " ^
                            TF.tyToString ety)
          val ty' = checkExp envHandler expHandler
          val _ = if eqType env ty ty' = false
                  then raise ERREXP loc (
                         "expression and handler don't agree" ^ 
                         "\n  expression: " ^
                         TF.tyToString ty ^ 
                         "\n  handler: " ^ 
                         TF.tyToString ty')
                  else ()
      in  ty
      end

    | RCCASE (exp,tye,cvebinds,expDefault,loc) => 
      let val _ = checkType env tye loc
          val ty = checkExp env exp
          val _ = if eqType env tye ty = false
                  then raise ERREXP loc (
                         "type annotation mimatch in case expression" ^
                         "\n  expression: " ^
                         TF.tyToString ty ^
                         "\n  annotation: " ^
                         TF.tyToString tye)
                  else ()
          val (ty1,ty2) = checkConVarOptExpList env cvebinds tye loc
          val _ = if eqType env tye ty1 = false
                  then raise ERREXP loc (
                         "type annotation mismatch in case pattern" ^
                         "\n  pattern type: " ^
                         TF.tyToString ty1 ^
                         "\n  annotated type: " ^
                         TF.tyToString tye)
                  else ()
          val tyb = checkExp env expDefault
          val _ = if eqType env tyb ty2 = false
                  then raise ERREXP loc (
                         "types of rules don't agree" ^
                         "\n  default rule: " ^
                         TF.tyToString tyb ^
                         "\n  earlier rule(s): " ^
                         TF.tyToString ty2)
                  else ()
      in  ty2
      end

    | RCSWITCH (exp,ty,constExpList,expBody,loc) =>
      let val tyExp = checkExp env exp
          val (tyArg,tyRes) = checkConstExpList env constExpList loc
          val _ = if eqType env tyExp ty
                  then ()
                  else raise ERREXP loc (
                         "type annotation mismatch in switch" ^
                         "\n  expression: " ^
                         TF.tyToString tyExp ^
                         "\n  annotation: " ^
                         TF.tyToString ty)
          val _ = if eqType env tyExp tyArg
                  then ()
                  else raise ERREXP loc (
                         "type mismatch in switch expression" ^
                         "\n  expression: " ^
                         TF.tyToString tyExp ^
                         "\n  constant pattern(s): " ^
                         TF.tyToString tyArg)
          val tyBody = checkExp env expBody
          val _ = if eqType env tyRes tyBody
                  then ()
                  else raise ERREXP loc (
                         "type mismatch in switch body" ^
                         "\n  expression: " ^
                         TF.tyToString tyBody ^
                         "\n  constant pattern(s): " ^
                         TF.tyToString tyRes)
      in  tyBody
      end

    | RCFN (varIdInfo,ty,exp,loc) => 
      let val _ = checkType env ty loc
          val ty1 = #ty varIdInfo
          val id = #displayName varIdInfo
          val env = extendVarEnv env 
                      (SEnv.singleton (id,
                        VARID (varIdInfoToVarPathInfo varIdInfo)))
          val ty2 = checkExp env exp
          val _ = if eqType env ty ty2 = false
                  then raise ERREXP loc (
                        "type annotation mismatch in anonymous function" ^
                        "\n  expression: " ^
                        TF.tyToString ty2 ^
                        "\n  annotation: " ^
                        TF.tyToString ty)
                  else ()
      in 
          FUNty (ty1,ty2) 
      end

    | RCFNM (varIdInfoList,ty,exp,loc) =>
      let val varIdstateList = 
              map (fn (varIdInfo as {displayName=n, ...})
                   => (n,VARID (varIdInfoToVarPathInfo varIdInfo)))
                   varIdInfoList
          val tys = map (fn (varIdInfo as {ty=ty, ...}) => ty) varIdInfoList
          val varEnv = 
              foldr (fn ((n,idstate),varEnv) =>
                SEnv.insert (varEnv,n,idstate))
                SEnv.empty
                varIdstateList
          val env = extendVarEnv env varEnv
          val ty = checkExp env exp
      in
          FUNMty (tys,ty)
      end

    | RCPOLYFN (btvs,varIdInfo,ty,exp,loc) => 
      let val env = extendBtvEnv env btvs

          val id = #displayName varIdInfo
          val env = extendVarEnv env 
                      (SEnv.singleton (id,
                         VARID (varIdInfoToVarPathInfo varIdInfo)))

          val _ = checkType env ty loc

          val ty1 = #ty varIdInfo
          val _ = checkType env ty1 loc

          val ty2 = checkExp env exp
          val fty = FUNty (ty1,ty2)
       
          val _ = if eqType env ty ty2 = false
                  then raise ERREXP loc (
                         "type annotation mismatch in polymorphic anonymous function" ^
                         "\n  expression: " ^
                         TF.tyToString ty2 ^
                         "\n  annotation: " ^
                         TF.tyToString ty)
                  else ()
      in  POLYty {boundtvars=btvs,body=fty}
      end

    | RCPOLY (btvs,ty,exp,loc) => 
      let val env = extendBtvEnv env btvs
          val _ = checkType env ty loc
          val ty' = checkExp env exp
          val _ = if eqType env ty ty' = false
                  then raise ERREXP loc (
                        "type annotation mismatch in polymorphic expression" ^
                        "\n  expression: " ^
                        TF.tyToString ty' ^
                        "\n  annotation: " ^
                        TF.tyToString ty)
                  else ()
      in  POLYty {boundtvars=btvs,body=ty}
      end

    | RCTAPP (exp,ty,tyList,loc) => 
      let val _ = checkTypes env (ty :: tyList) loc

          val polyty = checkExp env exp
          val _ = if eqType env ty polyty = false
                  then raise ERREXP loc
                         ("type annotation mismatch in type application" ^
                          "\n  expression: " ^
                          TF.tyToString polyty ^
                          "\n  annotation: " ^
                          TF.tyToString ty ^
                          "\n polyfun expr: " ^
                          SMLFormat.prettyPrint
                                 [SMLFormat.Columns 60]
                                 (format_rcexp [(0,getBtvEnv env)] exp))
                  else ()
          val ty = skip ty
          val (btvEnv,ty) = 
                 case ty of
                   POLYty {boundtvars=btvs, body=ty} => (btvs,ty)
                 | ty => (IEnv.empty, ty)
          val _ = if IEnv.numItems btvEnv <> length tyList
                  then raise ERREXP loc
                        ("can't instantiate expression in type application" ^
                         "\n  expression: " ^
                          TF.tyToString polyty ^
                         "\n  instance(s): " ^
                         tysToString tyList)
                  else ()

          val subst = ListPair.foldr
                       (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                        IEnv.empty (IEnv.listItemsi btvEnv,tyList)

          val btvEnv' = instBtvEnv btvEnv subst

          val _ = leqKinds env (IEnv.listItems btvEnv') tyList

          val ty = TypesUtils.substBTvar subst ty
      in  ty
      end

    | RCSEQ (expList,tyList,loc) => checkExps env tyList expList loc

(* Need any condition on ty'? Should it be a constructor type? *)
    | RCCAST (exp, ty, loc) => 
      let val _ = checkType env ty loc
          val ty' = checkExp env exp

(*           val _ = if eqType env ty ATOMty = false  *)
(*                   andalso eqType env ty BOXEDty = false  *)
(*                   andalso eqType env ty DOUBLEty = false  *)
(*                   then raise ERREXP loc *)
(*                         ("unexpected target type for cast: " ^ *)
(*                          TF.tyToString ty) *)
(*                   else () *)

      in  ty
      end
    )
    handle Err msg =>
    raise Err (msg ^^ (L_PAT, at_exp env exp))

and checkExps env [] [] loc = 
    raise ERREXP loc ("empty expression list")
  | checkExps env [ty] [exp] loc = 
    let val ty' = checkExp env exp
    in
        if eqType env ty ty' = false
        then raise ERREXP loc ("type mismatch " ^
                        "\n  expression: " ^
                        TF.tyToString ty' ^ 
                        "\n  annotation: " ^
                        TF.tyToString ty)
        else ty
    end
  | checkExps env (ty::tys) (exp::exps) loc = 
    let val ty' = checkExp env exp
    in
        if eqType env ty ty' = false
        then raise ERREXP loc ("type mismatch: "  ^ 
                        "\n  expression: " ^
                        TF.tyToString ty' ^ 
                        "\n  annotation: " ^
                        TF.tyToString ty)
        else checkExps env tys exps loc
    end
  | checkExps env _ _ loc = 
     raise ERREXP loc ("mismatch in # of exprs and types")

(* case alternatives *)

and checkConstExp env (const,exp) loc = 
    let val tyArg = CTU.constDefaultTy const
        val tyRes = checkExp env exp
    in  (tyArg, tyRes)
    end

and checkConstExpList env [] loc = raise ERRPAT loc ("empty matches")
  | checkConstExpList env [cebind] loc = checkConstExp env cebind loc
  | checkConstExpList env (cebind::cebinds) loc = 
    let val (ty1,ty2) = checkConstExp env cebind loc
        val (ty1',ty2') = checkConstExpList env cebinds loc
    in  if eqType env ty1 ty1' = false
        then raise ERRPAT loc (
               "constant pattern types of rules don't agree" ^
               "\n  this rule: " ^
               TF.tyToString ty1 ^
               "\n  the next rule(s): " ^
               TF.tyToString ty1')
        else if eqType env ty2 ty2' = false
        then raise ERRPAT loc (
               "expression types of rules don't agree" ^
               "\n  this rule: " ^
               TF.tyToString ty2 ^ 
               "\n  the next rule(s): " ^
               TF.tyToString ty2')
        else (ty1, ty2)
    end

and checkConVarOptExp env (conIdInfo,varIdInfoWithTypeOpt, exp) tyexpr loc =
    let val polyty   = #ty conIdInfo
        val tyCon    = #tyCon conIdInfo
        val funtyCon = #funtyCon conIdInfo 

        val tyname = #name tyCon
        val arity  = List.length (#tyvars tyCon)

        val polyty = skip polyty
        val (btvEnv,bodyty) =
             case polyty of
               POLYty {boundtvars=btvEnv,body=ty} => (btvEnv,ty)
             | _ => (IEnv.empty,polyty)

        val nbtvEnv = IEnv.numItems btvEnv

        val ntylist = 0
        val tyList = []

        val _ =
            if nbtvEnv <> arity
            then raise ERRPAT loc (
                        "arity annotation mismatch" ^
                        "\n  symbol: " ^
                        #displayName conIdInfo ^
                        "\n  type: " ^
                        TF.tyToString polyty ^ 
                        "\n  arity: " ^
                        Int.toString arity)
                  else ()

        val _ = if nbtvEnv <> ntylist andalso ntylist <> 0
                  then raise ERRPAT loc
                        ("can't instantiate constructor pattern" ^ 
                         #displayName conIdInfo ^
                         "\n  type: " ^ 
                         TF.tyToString polyty ^ 
                         "\n  instance: " ^
                         tysToString tyList)
                  else ()

        val subst = ListPair.foldr
                     (fn ((i,_),ty,S) => IEnv.insert (S,i,ty))
                       IEnv.empty (IEnv.listItemsi btvEnv,tyList)

        val btvEnv' = instBtvEnv btvEnv subst

        val _ = if ntylist <> 0 
                then leqKinds env (IEnv.listItems btvEnv') tyList
                else []

        val instty = if ntylist <> 0
                     then TypesUtils.substBTvar subst bodyty
                     else polyty

        val instty = skip instty

        val (tyArg,varEnv) =
             case (instty, varIdInfoWithTypeOpt, funtyCon) of
               (FUNty (ty1,ty2), SOME varIdInfoWithType, true) =>
                let val {ty=ty,displayName=id,...} = varIdInfoWithType
                    val varEnv = SEnv.singleton (id,
                           VARID (varIdInfoToVarPathInfo varIdInfoWithType))
                in  if eqType env ty1 ty
                    then (ty2,varEnv)
                    else raise ERRPAT loc
                          ("operator and operand don't agree in constructor pattern" ^
                           "\n  operator domain: " ^
                           TF.tyToString ty1 ^ 
                           "\n  operand: " ^
                           TF.tyToString ty)
                end

(* THREE BUGS!! *)
(*    RCCASE should be equipped with information on how to instantiate *)
(*    the polymorphic type of constructor *)

(* BUG!! *)
(*              | (ty, NONE, false) => (instty, SEnv.empty) *)
             | (_, NONE, false) => (tyexpr, SEnv.empty)

             | (_, SOME varIdInfoWithType, _) => 
                let val {ty=ty,displayName=id,...} = varIdInfoWithType
                    val varEnv = SEnv.singleton (id,
                           VARID (varIdInfoToVarPathInfo varIdInfoWithType))
(* BUG!! *)
(*                 in  (instty,varEnv) *)

                in  (tyexpr,varEnv)
                end
(* BUG!! *)
(*                          raise ERRPAT loc *)
(*                           ("non-functional constructor pattern applied to operand" ^ *)
(*                            "\n  constructor: " ^ *)
(*                            #displayName conIdInfo ^ *)
(*                            "\n  type: " ^ *)
(*                            TF.tyToString instty ^ *)
(*                            "\n  funtyCon: " ^ *)
(*                            Bool.toString funtyCon) *)

        val env = extendVarEnv env varEnv
        val tyRes = checkExp env exp
        
    in  (tyArg, tyRes)
    end

and checkConVarOptExpList env [] tyexpr loc = raise ERRPAT loc ("empty matches")
  | checkConVarOptExpList env [cvebind] tyexpr loc = 
    checkConVarOptExp env cvebind tyexpr loc
  | checkConVarOptExpList env (cvebind::cvebinds) tyexpr loc = 
    let val (ty1,ty2) = checkConVarOptExp env cvebind tyexpr loc
        val (ty1',ty2') = checkConVarOptExpList env cvebinds tyexpr loc
    in  if eqType env ty1 ty1' = false
        then raise ERRPAT loc (
               "constructor pattern types of rules don't agree" ^
               "\n  this rule: " ^
               TF.tyToString ty1 ^ 
               "\n  the next rule(s): " ^
               TF.tyToString ty1')
        else if eqType env ty2 ty2' = false
        then raise ERRPAT loc (
               "expression types of rules don't agree" ^
               "\n  this rule: " ^
               TF.tyToString ty2 ^ 
               "\n  the next rule(s): " ^
               TF.tyToString ty2')
        else (ty1, ty2)
    end
    

(* Fields *)

and checkFields env fields ty loc = 
    let val fieldtys = 
            case ty of
              RECORDty fieldEnv => fieldEnv
            | _ => raise ERREXP loc (
                         "record type is expected: " ^
                         TF.tyToString ty)
    in
        foldr (fn ((id,e),fieldEnv) => 
               let val tyf = case SEnv.find (fieldtys, id) of
                               SOME tyf => tyf
                             | NONE => raise ERREXP loc (
                                        "label not found in record type" ^
                                        "\n  label: " ^
                                        id ^
                                        "\n  type: " ^
                                        TF.tyToString ty)
                   val ty = checkExp env e
               in  SEnv.insert (fieldEnv,id,ty)
               end)
              SEnv.empty (SEnv.listItemsi fields)
    end

(* Binding *)

and checkValIdentExpList env valIdentExpList loc =
    let fun checkLoop env varEnv []                      = varEnv
          | checkLoop env varEnv ((valIdent,exp)::binds) =
            let val (vty,isWild,varIdInfoOpt) = 
                    case valIdent of
                      VALIDENT varIdInfo => (#ty varIdInfo, false,
                                             SOME varIdInfo)
                    | VALIDENTWILD ty    => (ty, true, NONE)
                val ty   = checkExp env exp
                val _ =
                    if eqType env ty vty = false
                    then raise ERRDEC loc
                          ("type annotation mismatch in binding" ^
                           "\n  expression: " ^
                           TF.tyToString ty ^ 
                           "\n  annotation: " ^
                           TF.tyToString vty)
                    else ()
                val varEnv' = 
                    if isWild 
                    then SEnv.empty
                    else let val varIdInfo as {id=id,displayName=n,ty=ty} =
                                 valOf varIdInfoOpt
                         in  SEnv.singleton 
                               (n, VARID (varIdInfoToVarPathInfo varIdInfo))
                         end
                val env = extendVarEnv env varEnv'
                val varEnv = mergeVarEnv varEnv varEnv'
            in  checkLoop env varEnv binds
            end
    in  checkLoop env SEnv.empty valIdentExpList
    end

and checkVarIdInfoExpList env varIdInfoExpList loc =
    let val valIdentExpList = 
            map (fn (varIdInfo,exp) => 
                       (VALIDENT varIdInfo,exp)) varIdInfoExpList
    in  checkValIdentExpList env valIdentExpList loc
    end

and checkVarIdInfoTyExpList env varIdInfoTyExpList loc =
    let val (varEnv,binds) = 
             foldl
              (fn ((varIdInfo,ty,exp),(varEnv,binds)) =>
               let val id   = #displayName varIdInfo
                   val vty  = #ty varIdInfo
                   val _ = 
                       if eqType env ty vty = false
                       then raise ERRDEC loc
                             ("type annotation mismatch in recursive binding" ^
                              "\n  expression: " ^
                              TF.tyToString ty ^
                              "\n  annotation: " ^ 
                              TF.tyToString vty)
                       else ()
               in (mergeVarEnv varEnv
                      (SEnv.singleton
                         (id,VARID (varIdInfoToVarPathInfo varIdInfo))),
                   binds @ [(varIdInfo,exp)])
               end) (SEnv.empty,[]) varIdInfoTyExpList
        val env = extendVarEnv env varEnv
    in  checkVarIdInfoExpList env binds loc
    end

(* Typecheck declarations *)
and checkDecl env decl =
  (
    case decl of

    RCVAL (valIdentExpList, loc) =>
    let val varEnv = checkValIdentExpList env valIdentExpList loc
    in  (SEnv.empty, varEnv)
    end

  | RCVALREC (varIdInfoTyExpList, loc) =>
    let val varEnv = checkVarIdInfoTyExpList env varIdInfoTyExpList loc
    in  (SEnv.empty, varEnv)
    end

  | RCVALPOLYREC (btvs, varIdInfoTyExpList, loc) =>
    let val env = extendBtvEnv env btvs
        val varEnv = checkVarIdInfoTyExpList env varIdInfoTyExpList loc
        val vars = map (fn ({displayName=id,...},_,_) => id) varIdInfoTyExpList
        val ididStates = SEnv.listItemsi varEnv
        val ididStates =
            map (fn (id,idState) => 
                 case (List.find (fn x=>x=id) vars, idState) of
                   (SOME _,VARID {name=id',ty=ty',strpath=path})
                         => (id, VARID {name=id',strpath=path,
                                        ty=POLYty {boundtvars=btvs,body=ty'}})
                 | (_,_) => (id, idState)) ididStates
        val varEnv = foldl (fn ((id,idState),varEnv) =>
                            SEnv.insert(varEnv,id,idState))
                            SEnv.empty ididStates
    in  (SEnv.empty, varEnv)
    end

  | RCLOCALDEC (decls, decls', loc) =>
    let val (tyConEnv,varEnv) = checkDecls env decls
        val env = extendTyConEnv env tyConEnv
        val env = extendVarEnv env varEnv
    in  checkDecls env decls'
    end

  | RCSETFIELD (expVal, expArr, i, ty, loc) =>
    let val _ = checkType env ty loc
        val tyVal = checkExp env expVal
        val tyArr = checkExp env expArr

        val BOXED_ARRAY_TYPE = 
            CONty{tyCon = PT.arrayTyCon, args =  [BOXEDty]}
        val ATOM_ARRAY_TYPE = 
            CONty{tyCon = PT.arrayTyCon, args =  [ATOMty]}
        val DOUBLE_ARRAY_TYPE = 
            CONty{tyCon = PT.arrayTyCon, args =  [DOUBLEty]}

        val _ = if eqType env tyVal ATOMty
                andalso eqType env tyArr ATOM_ARRAY_TYPE
                then ()
                else if eqType env tyVal BOXEDty
                andalso eqType env tyArr BOXED_ARRAY_TYPE
                then ()
                else if eqType env tyVal DOUBLEty
                andalso eqType env tyArr DOUBLE_ARRAY_TYPE
                then ()
                else raise ERREXP loc
                       ("unexpected types in setfield" ^
                        "\n  element: " ^
                        TF.tyToString tyVal ^
                        "\n  array: " ^
                        TF.tyToString tyArr)
    in  (SEnv.empty, SEnv.empty)
    end

  | RCSETGLOBAL (str, expVal, loc) =>
    let val tyVal = checkExp env expVal

        val BOXED_ARRAY_TYPE = 
            CONty{tyCon = PT.arrayTyCon, args =  [BOXEDty]}
        val ATOM_ARRAY_TYPE = 
            CONty{tyCon = PT.arrayTyCon, args =  [ATOMty]}
        val DOUBLE_ARRAY_TYPE = 
            CONty{tyCon = PT.arrayTyCon, args =  [DOUBLEty]}

        val _ = if eqType env tyVal BOXED_ARRAY_TYPE 
                orelse eqType env tyVal ATOM_ARRAY_TYPE
                orelse eqType env tyVal DOUBLE_ARRAY_TYPE
                then ()
                else raise ERREXP loc
                       ("unexpected type in setglobal" ^
                        "\n  operand: " ^
                        TF.tyToString tyVal)
    in  (SEnv.empty, SEnv.empty)
    end

  | RCEMPTY loc => (SEnv.empty, SEnv.empty)
  )

  handle Err msg =>
  raise Err (msg ^^ (L_PRG, at_decl env decl))

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

(* Entry *)
fun typecheck rcdecs = 
    let val env = {varEnv = SEnv.empty,
                   btvEnv = IEnv.empty,
                   tyConEnv = PT.initialTyConEnv}
    in  if !typeCheck 
        then

           checkDecls env rcdecs
           handle Err (_,msg) =>
           (print msg; (SEnv.empty,SEnv.empty))
(*            raise Control.Bug ("Typecheck fail:\n" ^ msg); *)
(*            print "\nSuccessfully typechecked.\n" *)

        else
           (SEnv.empty,SEnv.empty)
    end

end 
