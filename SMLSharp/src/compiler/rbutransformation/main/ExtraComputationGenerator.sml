(**
 * ExtraComputationGenerator.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ExtraComputationGenerator.sml,v 1.9 2008/01/23 08:20:07 katsu Exp $
 *)

structure ExtraComputationGenerator : EXTRACOMPUTATIONGENERATOR = struct

  structure CTX = RBUContext 
  structure RBUU = RBUUtils
  structure CT = ConstantTerm
  structure AT = AnnotatedTypes
  structure RT = RBUTypes
  structure AO = ArithmeticOptimizer
  structure P = BuiltinPrimitive
  open RBUCalc
  
  fun insertConst (batch,w) = AO.insert(batch,AO.CONST w)

  (*
   *  bitmap([ty1,...,tyn]) = tag(ty1) AND (bitmap([ty2,...,tyn]) << size(ty1))
   *)
  fun insertBitmap (batch,[]) = insertConst(batch,0w0)
    | insertBitmap (batch,[ty]) = insertTag(batch,ty)
    | insertBitmap (batch,ty::rest) =
      let
        val (batch,v1) = insertTag(batch,ty)
        val (batch,v2) = insertSize(batch,ty)
        val (batch,v3) = insertBitmap(batch,rest)
      in
        AO.insert(batch,AO.OR(AO.VAR v1,AO.LSHIFT(AO.VAR v3,AO.VAR v2)))
      end

  and insertEnvBitmap (batch,[],[]) = insertConst(batch,0w0)
    | insertEnvBitmap (batch,[ty],[size]) = insertTag(batch,ty)
    | insertEnvBitmap (batch,ty::tyRest,size::sizeRest) =
      let
        val (batch,v1) = insertTag(batch,ty)
        val (batch,v2) = insertConst(batch,size)
        val (batch,v3) = insertEnvBitmap(batch,tyRest,sizeRest)
      in
        AO.insert(batch,AO.OR(AO.VAR v1,AO.LSHIFT(AO.VAR v3,AO.VAR v2)))
      end
    | insertEnvBitmap _ = 
       raise 
         Control.Bug
         "ty and size lists don's agree : (rbutransformation/main/ExtraComputationGenerator.sml)"

  and insertFrameBitmap (batch,[]) = raise Control.Bug "frame bitmap must have at least one bit"
    | insertFrameBitmap (batch,[tid]) = insertTag(batch,RT.BOUNDVARty tid)
    | insertFrameBitmap (batch,tid::rest) =
      let
        val (batch,v1) = insertTag(batch,RT.BOUNDVARty tid)
        val (batch,v2) = insertFrameBitmap(batch,rest)
      in
        AO.insert(batch,AO.OR(AO.VAR v1,AO.LSHIFT(AO.VAR v2,AO.CONST 0w1)))
      end

  (*
   *  offset([ty1,...,tyn]) = size(ty1) + offset([ty2,...,tyn])
   *)
  and insertOffset (batch,[]) = insertConst(batch,0w0)
    | insertOffset (batch,[ty]) = insertSize(batch,ty)
    | insertOffset (batch,ty::rest) =
      let 
        val (batch,v1) = insertSize(batch,ty)
        val (batch,v2) = insertOffset(batch,rest)
      in
        AO.insert(batch,AO.ADD(AO.VAR v1,AO.VAR v2))
      end

  and insertTag (batch,ty) =
      case ty of 
        RT.ATOMty => insertConst(batch,0w0)
      | RT.BOXEDty => insertConst(batch,0w1)
      | RT.DOUBLEty => insertConst(batch,0w0)
      | RT.BOUNDVARty tid => AO.insert(batch,AO.TAG tid)
      | RT.SINGLEty tid => AO.insert(batch,AO.TAG tid)
      | RT.UNBOXEDty tid => insertConst(batch,0w0)
      | RT.PADty _ => insertConst(batch,0w0)
      | _ => raise Control.Bug "insertTag: invalid type "

  and insertSize (batch,ty) =
      if !Control.enableUnboxedFloat 
      then
        (
         case ty of 
           RT.ATOMty => insertConst(batch,0w1)
         | RT.BOXEDty => insertConst(batch,0w1)
         | RT.DOUBLEty => insertConst(batch,0w2)
         | RT.BOUNDVARty tid => AO.insert(batch,AO.SIZE tid)
         | RT.SINGLEty tid => insertConst(batch,0w1)
         | RT.UNBOXEDty tid => AO.insert(batch,AO.SIZE tid)
         | RT.PADty {condTy = RT.DOUBLEty, tyList} => insertPadSize (batch,tyList)
         | RT.PADty {condTy = RT.BOUNDVARty tid, tyList} => insertPadCondSize (batch,tyList,tid)
         | RT.PADty {condTy = RT.UNBOXEDty tid, tyList} => insertPadCondSize (batch,tyList,tid)
         | _ => raise Control.Bug "insertSize: invalid type "
        )
      else insertConst(batch,0w1)

  (*
   * size(PADty tyList) = offset(tyList) AND 1
   *)
  and insertPadSize (batch,tyList) =
      let 
        val (batch,v) = insertOffset(batch,tyList)
      in
        AO.insert(batch,AO.AND(AO.CONST 0w1,AO.VAR v))
      end

  (*
   * size(PADCONDty (tyList,tid) = 
   *        offset(tyList) AND (size(BOUNDVARty tid) >> 1)
   *)
  and insertPadCondSize (batch,tyList,tid) =
      let 
        val (batch,v) = insertOffset(batch,tyList)
      in
        AO.insert(batch,AO.AND(AO.RSHIFT(AO.SIZE tid,AO.CONST 0w1),AO.VAR v))
      end

  fun insert (batch,ty) =
      case ty of 
        RT.BITMAPty tyList => insertBitmap (batch,tyList)
      | RT.FRAMEBITMAPty tidList => insertFrameBitmap (batch,tidList)
      | RT.ENVBITMAPty {tyList, fixedSizeList} => insertEnvBitmap (batch,tyList,fixedSizeList)
      | RT.OFFSETty tyList => insertOffset (batch,tyList)
      | RT.PADSIZEty {condTy, tyList} => insertSize (batch,RT.PADty {condTy = condTy, tyList = tyList})
      | _ => raise Control.Bug "invalid extra local variable"

  (*
   * FIXME: yet another version of computation generator.
   *        yet another version computes size in bytes, not in words.
   *        if !Control.nativeGen() is true, yet another version is enabled,
   *        otherwise previous version is enabled.
   *)
  fun YAinsertBitOffset (batch, offset) =
      let
        val scale = BasicTypes.WordToUInt32 (RBUU.pointerSizeScale())
      in
        AO.insert (batch, AO.RSHIFT (AO.VAR offset, AO.CONST scale))
      end

  fun YAinsertBitmap (batch, tyList) =
      let
        fun insert batch (SOME (bitmap, offset)) (ty::tys) =
            let
              val (batch, v1) = insertTag (batch, ty)
              val (batch, v2) = YAinsertBitOffset (batch, offset)
              val (batch, v3) =
                  AO.insert (batch, AO.LSHIFT (AO.VAR v1, AO.VAR v2))
              val (batch, v4) =
                  AO.insert (batch, AO.OR (AO.VAR bitmap, AO.VAR v3))
              val (batch, v5) =
                  YAinsertNextOffset batch (SOME offset) ty
            in
              insert batch (SOME (v4, v5)) tys
            end
          | insert batch NONE (ty::tys) =
            let
              val (batch, v1) = insertTag (batch, ty)
              val (batch, v2) = YAinsertNextOffset batch NONE ty
            in
              insert batch (SOME (v1, v2)) tys
            end
          | insert batch (SOME (bitmap,_)) nil = (batch, bitmap)
          | insert batch NONE nil = insertConst (batch, 0w0)
      in
        insert batch NONE tyList
      end

  and YAinsertEnvBitmap (batch, tyList, sizeList) =
      let
        fun insert batch (SOME (bitmap, offset)) (ty::tys, size::sizes) =
            let
              val (batch, v1) = insertTag (batch, ty)
              val (batch, v2) = YAinsertBitOffset (batch, offset)
              val (batch, v3) =
                  AO.insert (batch, AO.LSHIFT (AO.VAR v1, AO.VAR v2))
              val (batch, v4) =
                  AO.insert (batch, AO.OR (AO.VAR bitmap, AO.VAR v3))
              val (batch, v5) = 
                  AO.insert (batch, AO.ADD (AO.VAR offset, AO.CONST size))
            in
              insert batch (SOME (v4, v5)) (tys, sizes)
            end
          | insert batch NONE (ty::tys, size::sizes) =
            let
              val (batch, v1) = insertTag (batch, ty)
              val (batch, v2) = insertConst (batch, size)
            in
              insert batch (SOME (v1, v2)) (tys, sizes)
            end
          | insert batch (SOME (bitmap,_)) (nil, nil) = (batch, bitmap)
          | insert batch NONE (nil, nil) = insertConst (batch, 0w0)
          | insert batch _ _ = raise Control.Bug "YAinsertEnvBitmap"
      in
        insert batch NONE (tyList, sizeList)
      end

  and YAinsertFrameBitmap (batch, tidList) =
      let
        fun insert batch (SOME (bitmap, offset)) (tid::tids) =
            let
              val (batch, v1) = insertTag (batch, RT.BOUNDVARty tid)
              val (batch, v2) =
                  AO.insert (batch, AO.LSHIFT (AO.VAR v1, AO.VAR offset))
              val (batch, v3) =
                  AO.insert (batch, AO.OR (AO.VAR bitmap, AO.VAR v2))
              val (batch, v4) =
                  AO.insert (batch, AO.ADD (AO.VAR offset, AO.CONST 0w1))
            in
              insert batch (SOME (v3, v4)) tids
            end
          | insert batch NONE (tid::tids) =
            let
              val (batch, v1) = insertTag (batch, RT.BOUNDVARty tid)
              val (batch, v2) = insertConst (batch, 0w1)
            in
              insert batch (SOME (v1, v2)) tids
            end
          | insert batch (SOME (bitmap,_)) nil = (batch, bitmap)
          | insert batch NONE nil =
            raise Control.Bug "frame bitmap must have at least one bit"
      in
        insert batch NONE tidList
      end

  (* Assume that size is equal to alignment, and every size is power of 2.
   * We can calculate the nearest offset z of x aligned in y as follows;
   *
   * z = (x + y - 1) AND (NOT (y - 1))
   *
   * and pad size w from x to be aligned in y (difference between x and z)
   * is;
   *
   * w = (NOT (x + y - 1)) AND (y - 1)
   *
   * Here we call (y - 1) in the above expression as "pad mask."
   *)
  and YAinsertNextOffset batch NONE ty = YAinsertSize (batch, ty)
(*
    | YAinsertNextOffset batch (SOME x) (RT.PADty {condTy, tyList}) =
      let
        val (batch, mask) = YAinsertPadMask (batch, condTy)
      in
        AO.insert (batch, AO.AND (AO.ADD (AO.VAR x,AO.VAR mask),
                                  AO.NOT (AO.VAR mask)))
      end
*)
    | YAinsertNextOffset batch (SOME x) ty =
      let
        val (batch, v1) = YAinsertSize (batch, ty)
      in
        AO.insert (batch, AO.ADD (AO.VAR x,AO.VAR v1))
      end

  and YAinsertOffset (batch, tyList) =
      let
        fun offset batch NONE nil = insertConst (batch, 0w0)
          | offset batch (SOME x) nil = (batch, x)
          | offset batch x (ty::tys) =
            let
              val (batch, v) = YAinsertNextOffset batch x ty
            in
              offset batch (SOME v) tys
            end
      in
        offset batch NONE tyList
      end

  and YAinsertPadMask (batch,ty) =
      let
        val (batch,v) = YAinsertSize(batch,ty)
      in
        AO.insert(batch, AO.SUB(AO.VAR v,AO.CONST 0w1))
      end

  and YAinsertSize (batch,ty) =
      case RBUUtils.constSize ty of
        SOME x => insertConst (batch, BasicTypes.WordToUInt32 x)
      | NONE =>
        case ty of
          RT.BOUNDVARty tid => AO.insert (batch, AO.SIZE tid)
        | RT.UNBOXEDty tid => AO.insert (batch, AO.SIZE tid)
        | RT.PADty {condTy, tyList} =>
          let
            val (batch,x) = YAinsertOffset (batch, tyList)
            val (batch,mask) = YAinsertPadMask(batch, condTy)
          in
            AO.insert (batch, AO.AND (AO.NOT (AO.ADD (AO.VAR x, AO.VAR mask)),
                                      AO.VAR mask))
          end
        | _ => raise Control.Bug "insertSize: invalid type "

  fun YAinsert (batch,ty) =
      case ty of
        RT.BITMAPty tyList => YAinsertBitmap (batch,tyList)
      | RT.FRAMEBITMAPty tidList => YAinsertFrameBitmap (batch,tidList)
      | RT.ENVBITMAPty {tyList, fixedSizeList} => YAinsertEnvBitmap (batch,tyList,fixedSizeList)
      | RT.OFFSETty tyList => YAinsertOffset (batch,tyList)
      | RT.PADSIZEty {condTy, tyList} => YAinsertSize (batch,RT.PADty {condTy=condTy, tyList=tyList})
      | _ => raise Control.Bug "invalid extra local variable"

  fun generateForLocalVarInfoList context localVarInfoList loc =
      let
        val insert = if Control.nativeGen() then YAinsert else insert
        val _ = AO.initialize()
        val (batch,varList) =
            foldr
                (fn ({ty,...},(B,L)) =>
                    let
                      val (B,v) = insert(B,ty)
                    in
                      (B,v::L)
                    end
                )
                (AO.empty,[])
                localVarInfoList
        val bindList = AO.extract(batch,varList)
        val varMap = 
            foldl
                (fn ((v,_),S) => IEnv.insert(S,v, Counters.newRBUVar LOCAL RT.ATOMty))
                IEnv.empty
                bindList

        fun lookup v = valOf(IEnv.find(varMap,v))

        fun convertExp context exp =
            case exp of
              AO.CONST c => (RBUCONSTANT{value = CT.WORD c, loc = loc}, context)
            | AO.VAR v =>
              let
                val newVarInfo = lookup v
                val sizeExp = RBUU.constSizeExp (#ty newVarInfo, loc)
              in
                (RBUVAR {varInfo = newVarInfo,valueSizeExp = sizeExp,loc = loc}, context)
              end
            | AO.SIZE tid => CTX.lookupSize context (tid,loc)
            | AO.TAG tid => CTX.lookupTag context (tid,loc)
            | AO.ADD(e1,e2) => convertPrimApply context (P.Word_add,[e1,e2])
            | AO.AND(e1,e2) => convertPrimApply context (P.Word_andb,[e1,e2])
            | AO.OR(e1,e2) => convertPrimApply context (P.Word_orb,[e1,e2])
            | AO.LSHIFT(e1,e2) => convertPrimApply context (P.Word_lshift,[e1,e2])
            | AO.RSHIFT(e1,e2) => convertPrimApply context (P.Word_rshift,[e1,e2])
            | AO.SUB(e1,e2) => convertPrimApply context (P.Word_sub,[e1,e2])
            | AO.NOT e => convertPrimApply context (P.Word_notb,[e])

        and convertExpList context [] = ([],context)
          | convertExpList context (exp::expList) =
            let
              val (newExp, newContext) = convertExp context exp
              val (newExpList, newContext) = convertExpList newContext expList
            in
              (newExp::newExpList,newContext)
            end
            
        and convertPrimApply context (prim,argExpList) =
            let 
              val (newArgExpList, newContext) = convertExpList context argExpList
              val argTyList = map (fn _ => RT.ATOMty) argExpList
              val argSizeExpList = map (fn ty => RBUU.constSizeExp (ty,loc)) argTyList
            in
              (
               RBUPRIMAPPLY
                   {
                    prim = prim,
                    argExpList = newArgExpList,
                    argTyList = argTyList,
                    resultTyList = [RT.ATOMty],
                    argSizeExpList = argSizeExpList,
                    instSizeExpList = nil,
                    instTagExpList = nil,
                    loc = loc
                   },
               newContext
              )
            end

        fun convertBind context (v,e) =
            let
              val varInfo = lookup v
              val (exp, newContext) = convertExp context e
            in
              (RBUVAL {boundVarList = [varInfo], sizeExpList = [RBUU.constSizeExp (#ty varInfo,loc)], tagExpList = [RBUU.constTagExp (#ty varInfo,loc)], boundExp = exp, loc = loc}, newContext)
            end

        and convertBindList context [] = ([], context)
          | convertBindList context (bind::bindList) =
            let
              val (decl, newContext) = convertBind context bind
              val (declList, newContext) = convertBindList newContext bindList
            in
              (decl::declList,newContext)
            end


        val (declList, newContext) = convertBindList context bindList

        val referenceDeclList = 
            ListPair.map
                (fn (varInfo,v) =>
                    let
                      val newVarInfo = lookup v
                      val sizeExp = RBUU.constSizeExp (#ty newVarInfo, loc)
                    in
                      RBUVAL 
                          {
                           boundVarList = [varInfo], 
                           sizeExpList = [RBUU.constSizeExp (#ty varInfo,loc)],
                           tagExpList = [RBUU.constTagExp (#ty varInfo, loc)],
                           boundExp = RBUVAR {varInfo = newVarInfo,valueSizeExp = sizeExp,loc = loc}, 
                           loc = loc
                          }
                    end                    
                )
                (localVarInfoList,varList)
      in
        (declList @ referenceDeclList, newContext)
      end

  fun generate context loc =
      let
        val localVarInfoList = CTX.listExtraLocalVariables context
      in
        generateForLocalVarInfoList context localVarInfoList loc
      end

  fun generateWithBtvEnv context (btvEnv:AT.btvEnv) loc =
      let
        val localVarInfoList = CTX.listExtraLocalVariables context
        val btvSet =
            IEnv.foldl
                (fn ({id,...},btvSet) =>ISet.add(btvSet,id))
                ISet.empty
                btvEnv

        fun tvInBtvSet ty =
            case ty of 
              RT.SIZEty tid => ISet.member(btvSet, tid)
            | RT.TAGty tid => ISet.member(btvSet, tid)
            | RT.INDEXty {label, recordTy as (RT.BOUNDVARty tid)} =>
                ISet.member(btvSet, tid)
            | _ => false

        val effectiveVarInfoList =
          foldr
          (fn (varInfo as {ty,...},effectiveVarInfoList) =>
           if tvInBtvSet ty then 
             varInfo :: effectiveVarInfoList
           else effectiveVarInfoList)
          nil
          localVarInfoList
      in
        generateForLocalVarInfoList context effectiveVarInfoList loc
      end

end
