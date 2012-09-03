(**
 * ExtraComputationGenerator.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ExtraComputationGenerator.sml,v 1.2 2007/04/18 09:07:04 ducnh Exp $
 *)

structure ExtraComputationGenerator : EXTRACOMPUTATIONGENERATOR = struct

  structure CTX = RBUContext 
  structure RBUU = RBUUtils
  structure CT = ConstantTerm
  structure AT = AnnotatedTypes
  structure AO = ArithmeticOptimizer
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

  and insertFrameBitmap (batch,[]) = raise Control.Bug "frame bitmap must have at least one bit"
    | insertFrameBitmap (batch,[tid]) = insertTag(batch,AT.BOUNDVARty tid)
    | insertFrameBitmap (batch,tid::rest) =
      let
        val (batch,v1) = insertTag(batch,AT.BOUNDVARty tid)
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
        AT.ATOMty => insertConst(batch,0w0)
      | AT.BOXEDty => insertConst(batch,0w1)
      | AT.DOUBLEty => insertConst(batch,0w0)
      | AT.BOUNDVARty tid => AO.insert(batch,AO.TAG tid)
      | AT.SINGLEty tid => AO.insert(batch,AO.TAG tid)
      | AT.UNBOXEDty tid => insertConst(batch,0w0)
      | AT.PADty _ => insertConst(batch,0w0)
      | _ => raise Control.Bug "insertTag: invalid type "

  and insertSize (batch,ty) =
      if !Control.enableUnboxedFloat 
      then
        (
         case ty of 
           AT.ATOMty => insertConst(batch,0w1)
         | AT.BOXEDty => insertConst(batch,0w1)
         | AT.DOUBLEty => insertConst(batch,0w2)
         | AT.BOUNDVARty tid => AO.insert(batch,AO.SIZE tid)
         | AT.SINGLEty tid => insertConst(batch,0w1)
         | AT.UNBOXEDty tid => AO.insert(batch,AO.SIZE tid)
         | AT.PADty {condTy = AT.DOUBLEty, tyList} => insertPadSize (batch,tyList)
         | AT.PADty {condTy = AT.BOUNDVARty tid, tyList} => insertPadCondSize (batch,tyList,tid)
         | AT.PADty {condTy = AT.UNBOXEDty tid, tyList} => insertPadCondSize (batch,tyList,tid)
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
        AT.BITMAPty tyList => insertBitmap (batch,tyList)
      | AT.FRAMEBITMAPty tidList => insertFrameBitmap (batch,tidList)
      | AT.ENVBITMAPty {tyList, fixedSizeList} => insertEnvBitmap (batch,tyList,fixedSizeList)
      | AT.OFFSETty tyList => insertOffset (batch,tyList)
      | AT.PADSIZEty {condTy, tyList} => insertSize (batch,AT.PADty {condTy = condTy, tyList = tyList})
      | _ => raise Control.Bug "invalid extra local variable"

  fun generate context loc =
      let
        val _ = AO.initialize()
        val localVarInfoList = CTX.listExtraLocalVariables context
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
                (fn ((v,_),S) => IEnv.insert(S,v,RBUU.newVar LOCAL AT.ATOMty))
                IEnv.empty
                bindList

        fun lookup v = valOf(IEnv.find(varMap,v))

        fun convertExp context exp =
            case exp of
              AO.CONST c => (RBUCONSTANT{value = CT.WORD c, loc = loc}, context)
            | AO.VAR v => (RBUVAR {varInfo = lookup v,loc = loc}, context)
            | AO.SIZE tid => CTX.lookupSize context (tid,loc)
            | AO.TAG tid => CTX.lookupTag context (tid,loc)
            | AO.ADD(e1,e2) => convertPrimApply context ("addWord",[e1,e2])
            | AO.AND(e1,e2) => convertPrimApply context ("Word_andb",[e1,e2])
            | AO.OR(e1,e2) => convertPrimApply context ("Word_orb",[e1,e2])
            | AO.LSHIFT(e1,e2) => convertPrimApply context ("Word_leftShift",[e1,e2])
            | AO.RSHIFT(e1,e2) => convertPrimApply context ("Word_logicalRightShift",[e1,e2])

        and convertExpList context [] = ([],context)
          | convertExpList context (exp::expList) =
            let
              val (newExp, newContext) = convertExp context exp
              val (newExpList, newContext) = convertExpList newContext expList
            in
              (newExp::newExpList,newContext)
            end
            
        and convertPrimApply context (primName,argExpList) =
            let 
              val (newArgExpList, newContext) = convertExpList context argExpList
              val argTyList = map (fn _ => AT.ATOMty) argExpList
              val argSizeExpList = map (fn _ => RBUU.singleSizeExp loc) argExpList
            in
              (
               RBUPRIMAPPLY
                   {
                    primName = primName,
                    argExpList = newArgExpList,
                    argTyList = argTyList,
                    argSizeExpList = argSizeExpList,
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
              (RBUVAL {boundVarList = [varInfo], sizeExpList = [RBUU.singleSizeExp loc], boundExp = exp, loc = loc}, newContext)
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
                    in
                      RBUVAL 
                          {
                           boundVarList = [varInfo], 
                           sizeExpList = [RBUU.singleSizeExp loc],
                           boundExp = RBUVAR {varInfo = newVarInfo,loc = loc}, 
                           loc = loc
                          }
                    end                    
                )
                (localVarInfoList,varList)
      in
        (declList @ referenceDeclList, newContext)
      end

end
