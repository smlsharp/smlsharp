(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version  $Id: BUCUtils.sml,v 1.13 2007/02/25 03:36:57 ducnh Exp $
 *)

structure BUCUtils :> BUCUTILS  = struct

  structure BT = BasicTypes
  structure BC = BUCCalc
  structure CT = ConstantTerm
  structure PT = PredefinedTypes
  structure TL = TypedLambda
  structure TU = TypesUtils
  structure T = Types

  val BLOCK_HEADER_SIZE = 2
  val MAX_BLOCK_SIZE = 30 
  val MAX_VARIANT_SIZE = 3 (* including offset*)

  datatype pasPosition = PAD_ALWAYS | PAD_NEVER | PAD_MAYBE

  exception VARIANT_LENGTH
  exception ITEM_FOUND of int

  (*************************************************)
  (* print utilities for debugging*)

  fun formatList formatter L =
      let
        fun format [] = ""
          | format [x] = formatter x
          | format (h::t) = (formatter h) ^ "," ^ (format t)
      in
        "(" ^ (format L) ^ ")"
      end

  fun formatType ty =
      Control.prettyPrint (Types.format_ty [] ty)

  fun formatTypeList tyList = formatList formatType tyList

  (*************************************************)
  (* Utilities for generating bitmapcalc exp*)

  fun makePrimApply (primName, args, argTys, loc) =
      BC.BUCPRIMAPPLY
          {
           primOp = {name = primName, ty = T.BOXEDty},
           argExpList = args,
           argTyList = argTys,
           loc = loc
          }

  fun word_constant (w, loc) = 
      BC.BUCCONSTANT {value = CT.WORD w, loc = loc}
      
  fun word_fromInt (intExp, loc) = 
      makePrimApply ("Word_fromInt",[intExp],[T.ATOMty],loc)

  fun word_add (e1,e2,loc) = 
      makePrimApply ("addWord",[e1,e2],[T.ATOMty,T.ATOMty],loc)

  fun word_leftShift (e1,e2,loc) = 
      makePrimApply ("Word_leftShift",[e1,e2],[T.ATOMty,T.ATOMty],loc)

  fun word_logicalRightShift (e1,e2,loc) = 
      makePrimApply ("Word_logicalRightShift",[e1,e2],[T.ATOMty,T.ATOMty],loc)

  fun word_andb (e1,e2,loc) = 
      makePrimApply ("Word_andb",[e1,e2],[T.ATOMty,T.ATOMty],loc)

  fun word_orb (e1,e2,loc) = 
      makePrimApply ("Word_andb",[e1,e2],[T.ATOMty,T.ATOMty],loc)

  fun newVar (ty,varKind) = 
      let
        val id = T.newVarId()
      in
        {id = id,displayName = "$" ^ (ID.toString id),ty=ty,varKind=varKind}
      end

  fun newTLVar ty = 
      let
        val id = T.newVarId()
      in
        {id = id, displayName = "$" ^ (ID.toString id),ty=ty}
      end

  (*********************************************************************)

  fun getLocOfExp exp =
      case exp of
	BC.BUCCONSTANT {loc,...} => loc
      | BC.BUCVAR {loc,...} => loc
      | BC.BUCENVACC {loc,...} => loc
      | BC.BUCENVACCINDIRECT {loc,...} => loc
      | BC.BUCLABEL {loc,...} => loc
      | BC.BUCSETGLOBALVALUE {loc,...} => loc
      | BC.BUCGETGLOBALVALUE {loc,...} => loc
      | BC.BUCINITARRAY {loc,...} => loc
      | BC.BUCCAST {loc,...} => loc
      | BC.BUCPRIMAPPLY {loc,...} =>  loc
      | BC.BUCFOREIGNAPPLY {loc,...} => loc
      | BC.BUCEXPORTCALLBACK {loc,...} => loc
      | BC.BUCAPPLY {loc,...} => loc
      | BC.BUCRECCALL {loc,...} => loc
      | BC.BUCLET {loc,...} => loc
      | BC.BUCRECORD {loc,...} => loc
      | BC.BUCARRAY {loc,...} => loc
      | BC.BUCMODIFY {loc,...} => loc
      | BC.BUCRAISE {loc,...} => loc
      | BC.BUCHANDLE {loc,...} => loc
      | BC.BUCCODE {loc,...} => loc
      | BC.BUCPOLY {loc,...} => loc
      | BC.BUCTAPP {loc,...} => loc
      | BC.BUCCLOSURE {loc,...} => loc
      | BC.BUCRECCLOSURE {loc,...} => loc
      | BC.BUCSWITCH {loc,...} => loc
      | BC.BUCSEQ {loc,...} => loc
      | BC.BUCGETFIELD {loc,...} => loc
      | BC.BUCSETFIELD {loc,...} => loc

  (*************************************************************************)
  (* converting utilities *)


  fun rootTy ty =
      case ty of
        T.TYVARty (ref (T.SUBSTITUTED realTy)) => rootTy realTy
      | T.ABSSPECty (_,realTy) => rootTy realTy
      | T.ALIASty (_,realTy) => rootTy realTy
      | _ => ty

  fun convertTy ty =
      let
        val ty = rootTy ty
      in
        case ty of
          T.TYVARty (ref (T.TVAR tvKind)) =>
          T.TYVARty (ref (T.TVAR (convertTvKind tvKind)))
        | T.RECORDty flty => T.RECORDty(SEnv.map convertTy flty)
        | T.CONty {tyCon,args} => T.CONty{tyCon=tyCon,args=map convertTy args}
        | T.POLYty {boundtvars,body} =>
          let
            val tidList = IEnv.listKeys boundtvars
            val tags = map T.TAGty tidList
            val sizes = 
                if !Control.enableUnboxedFloat 
                then map T.SIZEty tidList
                else []
            val body =
                case convertTy body of
                  T.FUNMty(args,body) => T.FUNMty(tags @ sizes @ args,body)
                | ty => ty 
            val boundtvars = IEnv.map convertBtvKind boundtvars
          in
            T.POLYty {boundtvars = boundtvars,body = body}
          end
        | T.INDEXty(ty,label) => T.INDEXty(convertTy ty,label)
        | T.ALIASty(ty1,ty2) => T.ALIASty(convertTy ty1,convertTy ty2)
        | T.BITMAPty tyList => T.BITMAPty(map convertTy tyList)
        | T.FRAMEBITMAPty tidList => T.FRAMEBITMAPty tidList
        | T.FUNMty(args,body) => T.FUNMty(map convertTy args,convertTy body)
        | T.OFFSETty tyList => T.OFFSETty (map convertTy tyList)
        | T.PADty tyList => T.PADty (map convertTy tyList)
        | T.PADCONDty (tyList,tid) => T.PADCONDty(map convertTy tyList,tid)
        | _ => ty
      end

  and convertTvKind {lambdaDepth, id,recKind,eqKind,tyvarName} =
      {
       lambdaDepth = lambdaDepth,
       id = id,
       recKind = convertRecKind recKind,
       eqKind = eqKind,
       tyvarName = tyvarName
      }

  and convertBtvKind {index,recKind,eqKind} =
      {
       index = index,
       recKind = convertRecKind recKind,
       eqKind = eqKind
      }

  and convertRecKind recKind =
      case recKind of
        T.UNIV => T.UNIV
      | T.REC flty => T.REC (SEnv.map convertTy flty)
      | T.OVERLOADED tyList => T.OVERLOADED (map convertTy tyList)

  fun convertVarInfo varKind {id,displayName,ty} =
      {id=id,displayName=displayName,ty=convertTy ty,varKind=varKind}


  (**************************************************************)

  fun sizeOf ty =
      case ty of
        T.ATOMty => SOME 0w1
      | T.BOXEDty => SOME 0w1
      | T.DOUBLEty => SOME 0w2
      | T.BOUNDVARty _ => NONE
      | T.PADty tyList => 
        (
         case constantOffset tyList of
           SOME w => SOME (Word32.andb(w,0w1))
         | NONE => NONE
        )
      | T.PADCONDty _ => NONE
      | _ => raise Control.Bug "sizeOf: invalid compact type"

  and tagOf ty =
      case ty of
        T.ATOMty => SOME (0w0 : Word32.word)
      | T.BOXEDty => SOME 0w1
      | T.DOUBLEty => SOME 0w0
      | T.BOUNDVARty _ => NONE
      | T.PADty _ =>  SOME 0w0
      | T.PADCONDty _ => SOME 0w0
      | _ => raise Control.Bug "sizeOf: invalid compact type"

  and constantBitmap [] = SOME 0w0
    | constantBitmap (ty::tyList) =
      (
       case (constantBitmap tyList,sizeOf ty,tagOf ty) of
         (SOME w,SOME size,SOME tag) =>
         SOME (Word32.orb(Word32.<< (w,BT.UInt32ToWord size),tag))
       | _ => NONE
      )

  and constantOffset [] = SOME 0w0
    | constantOffset (ty::tyList) =
      (
       case (constantOffset tyList,sizeOf ty) of
         (SOME w1,SOME w2) => SOME (w1 + w2)
       | _ => NONE
      )
      
  (************************************************************)
  (* type utilities*)

  fun arrayElementTy ty =
      case rootTy ty of
        T.CONty {tyCon,args as [ty']} => 
        if T.eqTyCon(tyCon,PT.arrayTyCon)
        then ty'
        else raise Control.Bug "invalid array type"
      | _ => raise Control.Bug "invalid array type"

  fun argTys ty =
      case rootTy ty of
        T.FUNMty (args, body) => args
      | _ => raise Control.Bug "invalid function type 2"

  fun primArgTys ty =
      case rootTy ty of
        T.FUNMty (tys,_) => tys
      | _ => []

  (*************************************************************)
  (* predict tyvars *)

  infix 8 ++
  infix 8 --

  fun op ++ (S1,S2) = ISet.union(S1,S2)
  fun op -- (S1,S2) = ISet.difference(S1,S2)

  fun tvsTy ty =
      case TU.compactTy ty of
        T.BOUNDVARty tid => ISet.singleton(tid)
      | _ => ISet.empty

  fun tvsList collector [] = ISet.empty
    | tvsList collector (h::t) = (tvsList collector t) ++ (collector h)

  fun tvsTyList L = tvsList tvsTy L

  fun tvsTypedExp (exp,ty) = (tvsExp exp) ++ ( tvsTy ty)

  and tvsExp exp = 
      case exp of
	BC.BUCCONSTANT _ => ISet.empty
      | BC.BUCVAR _ => ISet.empty
      | BC.BUCENVACC _ => ISet.empty
      | BC.BUCENVACCINDIRECT _ => ISet.empty
      | BC.BUCLABEL _ => ISet.empty
      | BC.BUCCAST {exp,expTy,...} => tvsTypedExp(exp,expTy)
      | BC.BUCPRIMAPPLY {argExpList,argTyList,...} =>  
        tvsExpList(argExpList,argTyList)
      | BC.BUCFOREIGNAPPLY {argExpList,argTyList,...} =>
        tvsExpList(argExpList,argTyList)
      | BC.BUCEXPORTCALLBACK {argTyList,resultTy,...} =>
        tvsTyList argTyList ++ tvsTy resultTy
      | BC.BUCAPPLY {funExp,argExpList,argTyList,...} =>
        (tvsExp funExp) ++ (tvsExpList (argExpList,argTyList))
      | BC.BUCRECCALL {funExp,argExpList,argTyList,...} => 
        (tvsExp funExp) ++ (tvsExpList (argExpList,argTyList))
      | BC.BUCLET {declList,mainExp,...} =>
        (tvsDeclList declList) ++ (tvsExp mainExp)
      | BC.BUCRECORD {fieldList,fieldTyList,...} =>
        tvsExpList(fieldList,fieldTyList)
      | BC.BUCARRAY {initialValue,elementTy,...} =>
        tvsTypedExp (initialValue,elementTy)
      | BC.BUCMODIFY {recordExp,elementExp,elementTy,...} =>
        (tvsExp recordExp) ++ (tvsTypedExp(elementExp,elementTy))
      | BC.BUCRAISE {exceptionExp,...} => 
        tvsExp exceptionExp
      | BC.BUCHANDLE {mainExp,exnVar,handler,...} => 
        (tvsExp mainExp) ++ (tvsExp handler) ++ (tvsVarInfo exnVar)
      | BC.BUCCODE _ => ISet.empty
      | BC.BUCPOLY {btvEnv,exp,...} =>
        let
          val btvSet =
              IEnv.foldli
                  (fn (tid,_,S) => ISet.add(S,tid))
                  ISet.empty
                  btvEnv
        in
          (tvsExp exp) -- btvSet
        end
      | BC.BUCTAPP {polyExp,...} => 
        tvsExp polyExp
      | BC.BUCCLOSURE {code,env,...} =>
        (tvsExp code) ++ (tvsExp env)
      | BC.BUCRECCLOSURE _ => ISet.empty
      | BC.BUCSWITCH {switchExp,expTy,branches,defaultExp,...} => 
        (tvsTypedExp (switchExp,expTy))
            ++ (tvsExp defaultExp) ++ (tvsRuleList branches)
      | BC.BUCSEQ {expList,expTyList,...} => 
        tvsExpList(expList,expTyList) 
      | BC.BUCGETGLOBALVALUE _ => ISet.empty
      | BC.BUCSETGLOBALVALUE _ => ISet.empty
      | BC.BUCINITARRAY _ => ISet.empty
      | BC.BUCGETFIELD {blockExp,...} =>
        tvsExp blockExp
      | BC.BUCSETFIELD {blockExp,valueExp,expTy,...} =>
        (tvsExp blockExp) ++ (tvsTypedExp(valueExp,expTy))

  and tvsExpList (L1,L2) = tvsList tvsTypedExp (ListPair.zip(L1,L2)) 

  and tvsRule (c,e) = tvsExp e

  and tvsRuleList L = tvsList tvsRule L

  and tvsVarInfo {id,displayName,ty,varKind} = tvsTy ty

  and tvsVarInfoList L = tvsList tvsVarInfo L

  and tvsDecl decl =
      case decl of
        BC.BUCVAL {bindList, loc} => 
        foldl
            (fn ((BC.VALIDVAR {ty,...},e), S) => S ++ (tvsTypedExp(e,ty))
              | ((BC.VALIDWILD ty,e), S) => S ++ (tvsTypedExp(e,ty))
            )
            ISet.empty
            bindList
      | BC.BUCVALREC _ => ISet.empty
      | BC.BUCVALPOLYREC _ => ISet.empty
      | BC.BUCLOCALDEC {localDeclList, mainDeclList,...} =>
        (tvsDeclList localDeclList) ++ (tvsDeclList mainDeclList)
      | BC.BUCEMPTY loc => ISet.empty

  and tvsDeclList declList = tvsList tvsDecl declList

  and tvsBitmapVarInfo {id,displayName,ty=T.BITMAPty tyList,varKind} =
      tvsTyList tyList
    | tvsBitmapVarInfo {id,displayName,ty=T.FRAMEBITMAPty tidList,varKind} =
      foldl (fn (tid,S) => ISet.add(S,tid)) ISet.empty tidList
    | tvsBitmapVarInfo _ = raise Control.Bug "FRAMEBITMAPty, BITMAPty are expected"

  and tvsBitmapVarInfoList L = tvsList tvsBitmapVarInfo L

  and tvsOffsetVarInfo {id,displayName,ty=T.OFFSETty tyList,varKind} =
      tvsTyList tyList
    | tvsOffsetVarInfo _ = raise Control.Bug "OFFSETty expected"

  and tvsOffsetVarInfoList L = tvsList tvsOffsetVarInfo L

  (***************************************************************)
  (* utilities for fixing record layout*)

  fun padPosition tyList =
      let 
        val n = 
            (
             foldl 
                 (fn (ty,S) =>
                     case ty of
                       T.ATOMty => S + 1
                     | T.BOXEDty => S + 1
                     | T.DOUBLEty => S + 2
                     | T.BOUNDVARty _ => raise VARIANT_LENGTH
                     | T.PADty _ => raise VARIANT_LENGTH
                     | T.PADCONDty _ => raise VARIANT_LENGTH
                     | _ => raise Control.Bug "invalid compacted record type"
                 )
                 0
                 tyList
            ) handle VARIANT_LENGTH => ~1
      in
        if n >= 0 
        then (* tyList has a fixed size *)
          if ((n + BLOCK_HEADER_SIZE) mod 2) = 1
          then PAD_ALWAYS (* always insert pad*)
          else PAD_NEVER (* never insert pad*)
        else PAD_MAYBE (* may be insert pad*)
      end

  (* insert pad field before each DOUBLEty field*)
  fun align (pad,(tyList,fieldList)) =
      let
        fun insert (tyList,fieldList,[],[]) = (rev tyList,rev fieldList)
          | insert (tyList,fieldList,ty::tyRest,field::fieldRest) =
            (
             case ty of 
               T.ATOMty => 
               insert(ty::tyList,field::fieldList,tyRest,fieldRest)
             | T.BOXEDty =>
               insert(ty::tyList,field::fieldList,tyRest,fieldRest)
             | T.DOUBLEty =>
               let
                 val padTy = T.PADty (rev tyList)
               in
                 case padPosition tyList of
                   PAD_MAYBE => 
                   insert(ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                 | PAD_ALWAYS => 
                   insert(ty::T.ATOMty::tyList,field::pad::fieldList,tyRest,fieldRest)
                 | PAD_NEVER => 
                   insert(ty::tyList,field::fieldList,tyRest,fieldRest)
               end
             | T.BOUNDVARty tid =>
               let
                 val padTy = T.PADCONDty (rev tyList,tid)
               in
                 case padPosition tyList of
                   PAD_MAYBE => 
                   insert(ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                 | PAD_ALWAYS => 
                   insert(ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                 | PAD_NEVER => 
                   insert(ty::tyList,field::fieldList,tyRest,fieldRest)
               end
             | _ => raise Control.Bug "decompose: invalid compact type"
            )
          | insert _ = raise Control.Bug "tyList and fieldList must have the same length"
      in
        insert([],[],tyList,fieldList)
      end

  fun decomposeOrdinaryRecord (alignOpt,pad,tyList,fieldList) =
      let
        val MAX_BLOCK_FIELDS = !Control.limitOfBlockFields
        fun decompose (blocks,[],[]) = rev blocks
          | decompose (blocks,tyList,fieldList) =
            let
              val totalLength = List.length tyList
              val blockSize = 
                  if totalLength > MAX_BLOCK_FIELDS
                  then MAX_BLOCK_FIELDS
                  else totalLength
              val blockTyList = List.take(tyList, blockSize)
              val blockFieldList = List.take(fieldList, blockSize)
              val tyRest = List.drop(tyList,blockSize)
              val fieldRest = List.drop(fieldList,blockSize)
              val isLastBlock =
                  case tyRest of
                    [] => true
                  | _ => false
              val block = 
                  if isLastBlock
                  then (blockTyList,blockFieldList)
                  else (T.BOXEDty::blockTyList,pad::blockFieldList)
              val (blockTyList',blockFieldList') = 
                  if alignOpt 
                  then align (pad,block)
                  else block
              val block' =
                  if isLastBlock
                  then (blockTyList',blockFieldList')
                  else (List.tl blockTyList',List.tl blockFieldList')
            in
              decompose (block'::blocks,tyRest,fieldRest)
            end
      in
        case decompose ([],tyList,fieldList) of
          [] => [([],[])]
        | L => L
      end

  fun decomposeEnvRecord (tyList,fieldList) =
      let
        fun decompose (totalSize,tyList,fieldList,[],[]) = (rev tyList, rev fieldList,[],[])
          | decompose (totalSize,tyList,fieldList,ty::tyRest,field::fieldRest) =
            let 
              val totalSize =
                  case ty of 
                    T.ATOMty => totalSize + 1
                  | T.BOXEDty => totalSize + 1
                  | T.DOUBLEty => totalSize + 2
                  | T.BOUNDVARty _ => totalSize + MAX_VARIANT_SIZE
                  | _ => raise Control.Bug "invalid compact type"
            in
              if totalSize > MAX_BLOCK_SIZE
              then (rev tyList,rev fieldList,ty::tyRest,field::fieldRest)
              else decompose(totalSize,ty::tyList,field::fieldList,tyRest,fieldRest)
            end
        fun decomposeAll ([],[]) = []
          | decomposeAll (tyList,fieldList) =
            let
              val (blockTyList,blockFieldList,tyRest,fieldRest) =
                  decompose(0,[],[],tyList,fieldList)
            in
              (blockTyList,blockFieldList)::decomposeAll(tyRest,fieldRest)
            end
      in
        case decomposeAll (tyList,fieldList) of
          [] => [([],[])]
        | L => L
      end

end
