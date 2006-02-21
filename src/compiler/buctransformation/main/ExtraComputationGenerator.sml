(**
 * Copyright (c) 2006, Tohoku University.
 *
 * ExtraComputationGenerator.
 * @author NGUYEN Huu-Duc
 * @version $Id: ExtraComputationGenerator.sml,v 1.4 2006/02/18 16:04:06 duchuu Exp $
 *)

structure ExtraComputationGenerator = struct

  structure BC = BUCCalc
  structure BCC = BUCCompileContext 
  structure BU = BUCUtils
  structure T = Types
  structure AO = ArithmeticOptimizer
  structure VO = VariableOptimizer
  
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

  and insertFrameBitmap (batch,[]) = raise Control.Bug "frame bitmap must have at least one bit"
    | insertFrameBitmap (batch,[tid]) = insertTag(batch,T.BOUNDVARty tid)
    | insertFrameBitmap (batch,tid::rest) =
      let
        val (batch,v1) = insertTag(batch,T.BOUNDVARty tid)
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
        T.ATOMty => insertConst(batch,0w0)
      | T.BOXEDty => insertConst(batch,0w1)
      | T.DOUBLEty => insertConst(batch,0w0)
      | T.BOUNDVARty tid => AO.insert(batch,AO.TAG tid)
      | T.PADty _ => insertConst(batch,0w0)
      | T.PADCONDty _ => insertConst(batch,0w0)
      | _ => raise Control.Bug ("insertTag: invalid type " ^ (BU.formatType ty))

  and insertSize (batch,ty) =
      case ty of 
        T.ATOMty => insertConst(batch,0w1)
      | T.BOXEDty => insertConst(batch,0w1)
      | T.DOUBLEty => insertConst(batch,0w2)
      | T.BOUNDVARty tid => 
        if !Control.enableUnboxedFloat 
        then AO.insert(batch,AO.SIZE tid)
        else insertConst(batch,0w1)
      | T.PADty tyList => insertPadSize (batch,tyList)
      | T.PADCONDty (tyList,tid) => insertPadCondSize (batch,tyList,tid)
      | _ => raise Control.Bug ("insertSize: invalid type " ^ (BU.formatType ty))

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
        T.BITMAPty tyList => insertBitmap (batch,tyList)
      | T.FRAMEBITMAPty tidList => insertFrameBitmap (batch,tidList)
      | T.OFFSETty tyList => insertOffset (batch,tyList)
      | T.PADty tyList => insertPadSize (batch,tyList)
      | T.PADCONDty (tyList,tid) => insertPadCondSize (batch,tyList,tid)
      | _ => raise Control.Bug "invalid extra local variable"

  fun lookup (varMap,v) =
      case IEnv.find(varMap,v) of
        SOME e => e
      | NONE => raise Control.Bug "lookup: variable not found"

  fun varInfoToExp (varInfo as {id,displayName,ty,varKind}, loc) =
      case varKind of
        BC.FREEWORD {nestLevel, offset} => 
        BC.BUCENVACC {nestLevel = nestLevel, offset = offset, variableTy = ty, loc = loc}
      | BC.FREEVAR {nestLevel, indirectOffset} => 
        BC.BUCENVACCINDIRECT {nestLevel = nestLevel, indirectOffset = indirectOffset, variableTy = ty, loc = loc}
      | BC.ARG => BC.BUCVAR {varInfo = varInfo, loc=loc}
      | BC.LOCAL => BC.BUCVAR {varInfo = varInfo, loc = loc}
      | _ => raise Control.Bug "varinfotoexp"

  fun convertExp (compileContext,varMap,loc) e =
      case e of
        AO.CONST c => BC.BUCCONSTANT{value = T.WORD c, loc = loc}
      | AO.VAR v => varInfoToExp(lookup(varMap,v),loc)
      | AO.SIZE tid => varInfoToExp(BCC.lookupSize(compileContext,tid),loc)
      | AO.TAG tid => varInfoToExp(BCC.lookupTag(compileContext,tid),loc)
      | AO.ADD(e1,e2) => 
        convertPrimApply (compileContext,varMap,loc) ("addWord",[e1,e2])
      | AO.AND(e1,e2) => 
        convertPrimApply (compileContext,varMap,loc) ("Word_andb",[e1,e2])
      | AO.OR(e1,e2) => 
        convertPrimApply (compileContext,varMap,loc) ("Word_orb",[e1,e2])
      | AO.LSHIFT(e1,e2) => 
        convertPrimApply (compileContext,varMap,loc) ("Word_leftShift",[e1,e2])
      | AO.RSHIFT(e1,e2) => 
        convertPrimApply (compileContext,varMap,loc) ("Word_logicalRightShift",[e1,e2])

  and convertPrimApply (compileContext,varMap,loc) (primName,args) =
      let 
        val args = map (convertExp (compileContext,varMap,loc)) args
        val argTys = map (fn _ => T.ATOMty) args
      in
        BC.BUCPRIMAPPLY
            {
             primOp = {name=primName,ty=T.BOXEDty},
             argExpList = args,
             argTyList = argTys,
             loc = loc
            }
      end

  fun convertBind (compileContext,varMap,loc) (v,e) =
      let
        val varInfo = lookup(varMap,v)
        val bmexp = convertExp (compileContext,varMap,loc) e
      in
        (BC.VALIDVAR varInfo,bmexp)
      end

  fun generate compileContext loc =
      let
        val _ = AO.initialize()
        val localVarInfos = BCC.listExtraLocalVariables compileContext
        val varSet = VO.insertList(VO.empty,localVarInfos)
        val optimizedVarInfos = VO.optimizedVariables varSet
        val (batch,vars) =
            foldr
                (fn ({ty,...},(B,L)) =>
                    let
                      val (B,v) = insert(B,ty)
                    in
                      (B,v::L)
                    end
                )
                (AO.empty,[])
                optimizedVarInfos
        val binds = AO.extract(batch,vars)
        val varMap = 
            foldl
                (fn ((v,_),S) => IEnv.insert(S,v,BU.newVar(T.ATOMty,BC.LOCAL)))
                IEnv.empty
                binds
        val bmbinds = map (convertBind (compileContext,varMap,loc)) binds
        val replicateBinds1 = 
            ListPair.map
                (fn (varInfo,v) =>
                    let
                      val varInfo' = lookup(varMap,v)
                    in
                      (BC.VALIDVAR varInfo,BC.BUCVAR {varInfo = varInfo',loc = loc})
                    end                    
                )
                (optimizedVarInfos,vars)
        val replicateBinds2 =
            foldl
                (fn (varInfo,L) =>
                    let
                      val varInfo' = VO.lookup(varSet,varInfo)
                    in
                      if (#id varInfo) = (#id varInfo')
                      then L
                      else (BC.VALIDVAR varInfo,BC.BUCVAR {varInfo = varInfo',loc = loc})::L
                    end
                )
                []
                localVarInfos
      in
        [BC.BUCVAL {bindList = (bmbinds @ replicateBinds1 @ replicateBinds2),loc = loc}]
      end

end
