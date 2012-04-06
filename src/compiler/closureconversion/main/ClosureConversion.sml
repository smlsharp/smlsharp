(**
 * bitmap calc A-normalization.
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ClosureConversion : sig
  
  val convert : BitmapANormal.baexp -> ClosureANormal.catopdec list

end =
struct

  structure A = BitmapANormal
  structure C = ClosureANormal
  structure T = AnnotatedTypes

  val emptyBtvEnv = BoundTypeVarID.Map.empty : A.btvEnv

  type varSet = A.varInfo VarID.Map.map
  val emptyVarSet = VarID.Map.empty : varSet
  fun union (x,y) = VarID.Map.unionWith #2 (x,y) : varSet
  fun unionList sets = foldl union emptyVarSet sets
  fun addVar (set, var as {id,...}) = VarID.Map.insert (set, id, var) : varSet
  fun addVars (set, vars) = foldl (fn (var,set) => addVar (set, var)) set vars
  fun varSetFromList vars = addVars (emptyVarSet, vars)
  fun setminus (set1, set2) =
      VarID.Map.filteri
        (fn (vid,_) => not (VarID.Map.inDomain (set2, vid)))
        set1

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, path = ["$" ^ VarID.toString id], ty = ty} : C.varInfo
      end

  fun mapi f l =
      let
        fun loop f i nil = nil
          | loop f i (h::t) = f (i,h) :: loop f (i+1) t
      in
        loop f 0 l
      end

  fun isNone NONE = true
    | isNone (SOME _) = false

  fun makeRecordTy fields =
      T.RECORDty {fieldTypes = 
                  List.foldl 
                    (fn ((key, item), m) => LabelEnv.insert (m, key, item)) 
                    LabelEnv.empty
                    fields,
                  annotation = ref {labels = T.LE_GENERIC, boxed = true,
                                    align = false}}

  fun valueToWord value =
      case value of
        C.BACONST (C.BACONSTANT (ConstantTerm.WORD w)) => Word32.toLarge w
      | C.BACONST _ => raise Control.Bug "valueToWord: BACONST"
      | C.BAVAR _ => raise Control.Bug "valueToWord: BAVAR"
      | C.BACAST {exp, expTy, targetTy} => valueToWord exp
      | C.BATAPP {exp, expTy, instTyList} => valueToWord exp

  fun Val (var, exp, loc) =
      fn K => C.CAVAL {boundVar = var, boundExp = exp, nextExp = K, loc = loc}

  fun freeVarsValue bv bavalue =
      case bavalue of
        A.BACONST const => emptyVarSet
      | A.BACAST {exp, expTy, targetTy} => freeVarsValue bv exp
      | A.BATAPP {exp, expTy, instTyList} => freeVarsValue bv exp
      | A.BAVAR (varInfo as {id,...}) =>
        if VarID.Map.inDomain (bv, id)
        then emptyVarSet else VarID.Map.singleton (id, varInfo)

  fun freeVarsValueOption bv NONE = emptyVarSet
    | freeVarsValueOption bv (SOME bavalue) = freeVarsValue bv bavalue

  fun freeVarsValueList bv values =
      unionList (map (freeVarsValue bv) values)

  fun freeVarsPrim bv baprim =
      case baprim of
        A.BAVALUE value =>
        freeVarsValue bv value
      | A.BAEXVAR {exVarInfo, varSize} =>
        freeVarsValue bv varSize
      | A.BAPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                       instSizeList} =>
        unionList [freeVarsValueList bv argExpList,
                   freeVarsValueList bv instTagList,
                   freeVarsValueList bv instSizeList]
      | A.BARECORD {fieldList, recordTy, annotation, isMutable, clearPad,
                    totalSizeExp, bitmapExpList} =>
        unionList
          [unionList
             (map (fn {fieldExp, fieldLabel, fieldIndex, fieldTy, fieldSize} =>
                      unionList [freeVarsValue bv fieldExp,
                                 freeVarsValue bv fieldIndex,
                                 freeVarsValue bv fieldSize])
                  fieldList),
           freeVarsValue bv totalSizeExp,
           freeVarsValueList bv bitmapExpList]
      | A.BASELECT {recordExp, indexExp, label, recordTy, resultTy,
                    resultSize} =>
        unionList [freeVarsValue bv recordExp,
                   freeVarsValue bv indexExp,
                   freeVarsValue bv resultSize]
      | A.BAMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    valueTag, valueSize} =>
        unionList [freeVarsValue bv recordExp,
                   freeVarsValue bv indexExp,
                   freeVarsValue bv valueExp,
                   freeVarsValue bv valueTag,
                   freeVarsValue bv valueSize]
        
  fun freeVarsCall bv bacall =
      case bacall of
        A.BAFOREIGNAPPLY {funExp, foreignFunTy, argExpList} =>
        unionList (freeVarsValue bv funExp
                   :: map (freeVarsValue bv) argExpList)
      | A.BAAPPM {funExp, funTy, argExpList} =>
        unionList (freeVarsValue bv funExp
                   :: map (freeVarsValue bv) argExpList)

  local

    fun fvLocalFunction bv fv ({argVarList, funTy, bodyExp,
                                annotation, loc}:C.localFunction) =
        let
          val bv = addVars (bv, argVarList)
        in
          fvExp bv fv bodyExp
        end

    and fvSwitch bv fv ({switchExp, expTy, branches, defaultExp, loc}
                        :C.switch) =
        let
          val fv = union (fv, freeVarsValue bv switchExp)
          val fv = foldl (fn ({constant, branchExp}, fv) =>
                             fvExp bv fv branchExp)
                         fv
                         branches
        in
          fvExp bv fv defaultExp
        end

    and fvExp bv fv caexp =
        case caexp of
          C.CAVAL {boundVar, boundExp, nextExp, loc} =>
          let
            val fv = union (fv, freeVarsPrim bv boundExp)
            val bv = addVar (bv, boundVar)
          in
            fvExp bv fv nextExp
          end
        | C.CACALL {resultVars, callExp, nextExp, loc} =>
          let
            val fv = union (fv, freeVarsCall bv callExp)
            val bv = addVars (bv, resultVars)
          in
            fvExp bv fv nextExp
          end
        | C.CAEXPORTVAR {varInfo, varSize, varTag, nextExp, loc} =>
          let
            val fv = if VarID.Map.inDomain (bv, #id varInfo)
                     then fv else addVar (fv, varInfo)
            val fv = union (fv, freeVarsValueList bv [varSize, varTag])
          in
            fvExp bv fv nextExp
          end
        | C.CACLOSURE {boundVar, codeId, closureEnv, closureLayout, funTy,
                       nextExp, loc} =>
          let
            val fv = union (fv, freeVarsValueOption bv closureEnv)
            val bv = addVar (bv, boundVar)
          in
            fvExp bv fv nextExp
          end
        | C.CACALLBACKCLOSURE {boundVar, codeId, closureEnv, foreignFunTy,
                               nextExp, loc} =>
          let
            val fv = union (fv, freeVarsValueOption bv closureEnv)
            val bv = addVar (bv, boundVar)
          in
            fvExp bv fv nextExp
          end
        | C.CALOCALFNM {recbindList, nextExp, loc} =>
          let
            val bv = addVars (bv, map #boundVar recbindList)
            val fv = foldl (fn ({boundVar, function}, fv) =>
                               fvLocalFunction bv fv function)
                           fv
                           recbindList
          in
            fvExp bv fv nextExp
          end
        | C.CAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
          let
            val fv = fvExp bv fv tryExp
            val fv = fvExp (addVar (bv, exnVar)) fv handlerExp
            val bv = addVars (bv, resultVars)
          in
            fvExp bv fv nextExp
          end
(*
        | C.CANEST {resultVars, nestExp, nextExp, loc} =>
          let
            val fv = fvExp bv fv nestExp
            val bv = addVars (bv, resultVars)
          in
            fvExp bv fv nextExp
          end
*)
        | C.CAMERGE resultVars =>
          union (fv, setminus (varSetFromList resultVars, bv))
        | C.CARETURN {resultVars, funTy, loc} =>
          union (fv, setminus (varSetFromList resultVars, bv))
        | C.CATAILAPPM {funExp, funTy, argExpList, loc} =>
          union (fv, unionList (map (freeVarsValue bv) (funExp::argExpList)))
        | C.CARAISE {argExp, loc} =>
          union (fv, freeVarsValue bv argExp)
        | C.CASWITCH {resultVars, switch, nextExp} =>
          let
            val fv = fvSwitch bv fv switch
            val bv = addVars (bv, resultVars)
          in
            fvExp bv fv nextExp
          end
        | C.CATAILSWITCH switch =>
          fvSwitch bv fv switch
        | C.CAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
          let
            val fv = fvExp bv fv exp
            val bv = addVars (bv, resultVars)
          in
            fvExp bv fv nextExp
          end

  in

  fun freeVarsExp bv caexp =
      fvExp bv emptyVarSet caexp

  end (* local *)

  local

    val emptySet = BoundTypeVarID.Set.empty

    fun extendBtvEnv x =
        BoundTypeVarID.Map.unionWith #2 x : A.btvEnv

    fun ftv btvEnv set ({ty,...}:A.varInfo) =
        case ty of
          T.BOUNDVARty tid =>
          if BoundTypeVarID.Map.inDomain (btvEnv, tid)
          then set else BoundTypeVarID.Set.add (set, tid)
        | _ => set

    fun ftvList btvEnv set vars =
        foldl (fn (var, set) => ftv btvEnv set var) set vars

    fun ftvVarSet btvEnv set vars =
        VarID.Map.foldl (fn (var, set) => ftv btvEnv set var) set vars

    fun ftvValue btvEnv set value =
        ftvVarSet btvEnv set (freeVarsValue emptyVarSet value)

    fun ftvValueList btvEnv set values =
        ftvVarSet btvEnv set (freeVarsValueList emptyVarSet values)

    fun ftvPrim btvEnv set baprim =
        ftvVarSet btvEnv set (freeVarsPrim emptyVarSet baprim)

    fun ftvCall btvEnv set bacall =
        ftvVarSet btvEnv set (freeVarsCall emptyVarSet bacall)

    fun ftvFunction btvEnv set ({argVarList, funTy, bodyExp, annotation,
                                 closureLayout, loc}:A.function) =
        let
          val set = ftvList btvEnv set argVarList
        in
          ftvExp btvEnv set bodyExp
        end

    and ftvSwitch btvEnv set ({switchExp, expTy, branches, defaultExp, loc}
                              :A.switch) =
        let
          val set = ftvValue btvEnv set switchExp
          val set = foldl (fn ({constant, branchExp}, set) =>
                              ftvExp btvEnv set branchExp)
                          set
                          branches
          val set = ftvExp btvEnv set defaultExp
        in
          set
        end

    and ftvExp btvEnv set baexp =
        case baexp of
          A.BAVAL {boundVar, boundExp, nextExp, loc} =>
          let
            val set = ftv btvEnv set boundVar
            val set = ftvPrim btvEnv set boundExp
          in
            ftvExp btvEnv set nextExp
          end
        | A.BACALL {resultVars, callExp, nextExp, loc} =>
          let
            val set = ftvList btvEnv set resultVars
            val set = ftvCall btvEnv set callExp
          in
            ftvExp btvEnv set nextExp
          end
        | A.BAEXPORTVAR {varInfo, varSize, varTag, nextExp, loc} =>
          let
            val set = ftv btvEnv set varInfo
            val set = ftvValueList btvEnv set [varSize, varTag]
          in
            ftvExp btvEnv set nextExp
          end
        | A.BAEXTERNVAR {exVarInfo, nextExp, loc} =>
          ftvExp btvEnv set nextExp
        | A.BAFNM {boundVar, btvEnv=btvEnv2, function, nextExp} =>
          let
            val set = ftv btvEnv set boundVar
            val btvEnv2 = extendBtvEnv (btvEnv, btvEnv2)
            val set = ftvFunction btvEnv2 set function
          in
            ftvExp btvEnv set nextExp
          end
        | A.BACALLBACKFNM {boundVar, function, foreignFunTy, nextExp} =>
          let
            val set = ftv btvEnv set boundVar
            val set = ftvFunction btvEnv set function
          in
            ftvExp btvEnv set nextExp
          end
        | A.BAVALREC {recbindList, nextExp, loc} =>
          let
            val set = foldl (fn ({boundVar, function}, set) =>
                                let
                                  val set = ftv btvEnv set boundVar
                                  val set = ftvFunction btvEnv set function
                                in
                                  set
                                end)
                            set
                            recbindList
          in
            ftvExp btvEnv set nextExp
          end
        | A.BAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
          let
            val set = ftvList btvEnv set resultVars
            val set = ftvExp btvEnv set tryExp
            val set = ftv btvEnv set exnVar
            val set = ftvExp btvEnv set handlerExp
          in
            ftvExp btvEnv set nextExp
          end
(*
        | A.BANEST {resultVars, nestExp, nextExp, loc} =>
          let
            val set = ftvList btvEnv set resultVars
            val set = ftvExp btvEnv set nestExp
          in
            ftvExp btvEnv set nextExp
          end
*)
        | A.BAMERGE resultVars =>
          ftvList btvEnv set resultVars
        | A.BARETURN {resultVars, funTy, loc} =>
          ftvList btvEnv set resultVars
        | A.BATAILAPPM {funExp, funTy, argExpList, loc} =>
          ftvValueList btvEnv set (funExp::argExpList)
        | A.BARAISE {argExp, loc} =>
          ftvValue btvEnv set argExp
        | A.BASWITCH {resultVars, switch, nextExp} =>
          let
            val set = ftvList btvEnv set resultVars
            val set = ftvSwitch btvEnv set switch
          in
            ftvExp btvEnv set nextExp
          end
        | A.BATAILSWITCH switch =>
          ftvSwitch btvEnv set switch
        | A.BAPOLY {resultVars, btvEnv=btvEnv2, expTyWithoutTAbs, exp,
                    nextExp, loc} =>
          let
            val set = ftvList btvEnv set resultVars
            val btvEnv = extendBtvEnv (btvEnv, btvEnv2)
            val set = ftvExp btvEnv set exp
          in
            ftvExp btvEnv set nextExp
          end

  in

  (* free type variables occurring in type annotations of variables. *)
  fun freeTyvarsFunction exp =
      ftvFunction emptyBtvEnv emptySet exp

  fun freeTyvarsFunctionList funcs =
      foldl (fn (func, set) => ftvFunction emptyBtvEnv set func)
            emptySet
            funcs

  end (* local *)


      






  type frameBitmap =
       {bitmap : RecordLayout.bitmap, tids: BoundTypeVarID.id list}

  type env =
      {
        boundVars : varSet,
        styEnv : SingletonTyEnv.env,
        frameBitmap : frameBitmap
      }

  val emptyEnv =
      {boundVars = emptyVarSet,
       styEnv = SingletonTyEnv.emptyEnv,
       frameBitmap = {bitmap = RecordLayout.emptyBitmap, tids = nil}} : env

  fun bindTyvars ({boundVars, styEnv, frameBitmap}:env, btvEnv) =
      {boundVars = boundVars,
       styEnv = SingletonTyEnv.bindTyvars (styEnv, btvEnv),
       frameBitmap = frameBitmap} : env

  fun bindVars ({boundVars, styEnv, frameBitmap}:env, vars) =
      {boundVars = boundVars,
       styEnv = SingletonTyEnv.bindVars (styEnv, vars),
       frameBitmap = frameBitmap} : env

  fun setFrameBitmap ({boundVars, styEnv, frameBitmap}:env, newFrameBitmap) =
      {boundVars = boundVars,
       styEnv = styEnv,
       frameBitmap = newFrameBitmap} : env

  fun constTag ({styEnv,...}:env) tid =
      SingletonTyEnv.constTag styEnv (T.BOUNDVARty tid)

  fun unalignedSize ({styEnv,...}:env) ty =
      SingletonTyEnv.unalignedSize styEnv ty

  fun findTag ({styEnv,...}:env) ty =
      SingletonTyEnv.findTag styEnv ty

  fun findSize ({styEnv,...}:env) ty =
      SingletonTyEnv.findSize styEnv ty

  fun ftvToBtvEnv ({styEnv,...}:env) ftv =
      BoundTypeVarID.Map.filteri
        (fn (tid, _) => BoundTypeVarID.Set.member (ftv, tid))
        (SingletonTyEnv.btvEnv styEnv)

  fun tagVars argVarList =
      List.mapPartial
        (fn var as {ty,...}:A.varInfo =>
            case ty of
              T.SINGLETONty (T.TAGty (T.BOUNDVARty tid)) =>
              SOME (tid, var)
            | _ => NONE)
        argVarList

  fun convertList f nil = (nil, nil)
    | convertList f (elem::elems) =
      let
        val (result1, elem) = f elem
        val (result2, elems) = convertList f elems
      in
        (result1 @ result2 : C.catopdec list, elem::elems)
      end

  fun toCavalue (value, sty) =
      let
        fun constWord n = ConstantTerm.WORD (Word32.fromLarge n)
        val value =
            case value of
              RecordLayout.CONST n => C.BACONST (C.BACONSTANT (constWord n))
            | RecordLayout.VAR (v, NONE) => C.BAVAR v
            | RecordLayout.VAR (v, SOME ty) =>
              C.BACAST {exp = C.BAVAR v, expTy = #ty v, targetTy = ty}
      in
        case sty of
          NONE => value
        | SOME sty =>
          C.BACAST {exp = value, expTy = T.wordty, targetTy = T.SINGLETONty sty}
      end

  fun toCaexp (nil, loc) = (fn K => K)
    | toCaexp (decl::decls, loc) =
      case decl of
        RecordLayout.MOVE (var, value) =>
        Val (var, C.BAVALUE (toCavalue (value, NONE)), loc)
        o toCaexp (decls, loc)
      | RecordLayout.PRIMAPPLY {boundVar, primInfo, argList} =>
        let
          val argExpList = map (fn v => toCavalue (v, NONE)) argList
        in
          Val (boundVar,
               C.BAPRIMAPPLY {primInfo = primInfo,
                              argExpList = argExpList,
                              instTyList = nil,
                              instTagList = nil,
                              instSizeList = nil},
               loc)
          o toCaexp (decls, loc)
        end

  fun frameBitmapVars ({bitmap, tids}:frameBitmap) =
      map (fn RecordLayout.VAR (v, _) => v
            | _ => raise Control.Bug "frameBitmapVars")
          (RecordLayout.bitmapWords bitmap)

  fun extendFrameBitmap ({bitmap, tids}:frameBitmap, bits, loc) =
      let
        val (newTids, tagVars) = ListPair.unzip bits
        val tags = map (fn tag => {tag = RecordLayout.VAR (tag, NONE)}) tagVars
        val (decls, bitmap) = RecordLayout.addBitsToBitmap (tags, bitmap)
        val frameBitmap = {bitmap = bitmap, tids = newTids @ tids}
        val vars = frameBitmapVars frameBitmap
        val merge = C.CAMERGE vars
      in
        ((toCaexp (decls, loc)) merge, frameBitmap)
      end

  fun computeFrameBitmap env (btvEnv, argVarList, freeTyvars, loc) =
      if BoundTypeVarID.Set.isEmpty freeTyvars then
        (* no free type variable in the frame; no frame bitmap *)
        (C.CAMERGE nil, nil, nil, #frameBitmap env)
      else if BoundTypeVarID.Map.isEmpty btvEnv then
        (* free type variables are found but they are not bound here;
         * all the ftv whose tags are not constant must be already in
         * the current frameBitmap. *)
        let
          val frameBitmap = #frameBitmap env
          val freeTyvars = BoundTypeVarID.Set.filter
                             (fn t => isNone (constTag env t))
                             freeTyvars
          val tids = foldl (fn (t,z) => BoundTypeVarID.Set.add (z,t))
                           BoundTypeVarID.Set.empty
                           (#tids frameBitmap)
          val _ = if BoundTypeVarID.Set.isSubset (freeTyvars, tids)
                  then () else raise Control.Bug "computeFrameBitmap"
          val vars = frameBitmapVars frameBitmap
        in
          (C.CAMERGE vars, vars, #tids frameBitmap, frameBitmap)
        end
      else
        (* some type variables bound by btvEnv occurs in bodyExp.
         * extend frameBitmap with the type variables. *)
        let
          val boundTagBits = tagVars argVarList
          val env = bindTyvars (env, btvEnv)
          val bits = List.filter
                       (fn (tid, var) =>
                           BoundTypeVarID.Set.member (freeTyvars, tid)
                           andalso isNone (constTag env tid))
                       boundTagBits
          val (frameBitmapExp, frameBitmap) =
              extendFrameBitmap (#frameBitmap env, bits, loc)
        in
          (frameBitmapExp, frameBitmapVars frameBitmap,
           #tids frameBitmap, frameBitmap)
        end

  fun makeRecord (fields, loc) =
      let
        val (decls, {totalSize, fieldIndexes, bitmap}) =
            RecordLayout.computeRecord
              (map (fn {tag,size,fieldSize,label,var:C.varInfo} =>
                       {tag=tag, size=fieldSize}) fields)
        val recordTy =
            makeRecordTy
              (map (fn {label, var={ty,...}, ...} => (label, ty)) fields)
        val totalSize =
            toCavalue (totalSize, SOME (T.RECORDSIZEty recordTy))
        val fieldList =
            ListPair.mapEq
              (fn (index, {tag, size, fieldSize, label, var as {ty,...}}) =>
                  {fieldExp = C.BAVAR var,
                   fieldLabel = label,
                   fieldIndex =
                     toCavalue (index, SOME (T.INDEXty (label, recordTy))),
                   fieldSize = toCavalue (size, SOME (T.SIZEty ty)),
                   fieldTy = ty})
              (fieldIndexes, fields)
        val bitmap =
            mapi (fn (i,v) =>
                     toCavalue (v, SOME (T.RECORDBITMAPty (i, recordTy))))
                 bitmap
      in
        (toCaexp (decls, loc),
         {fieldList = fieldList,
          recordTy = recordTy,
          annotation = AnnotationLabelID.generate (),
          isMutable = false,
          clearPad = false,
          totalSizeExp = totalSize,
          bitmapExpList = bitmap})
      end

  fun listFreeVars env vars =
      let
        val fields = map (fn (var as {ty,...}:C.varInfo) =>
                             (var, findTag env ty, findSize env ty,
                              unalignedSize env ty))
                         (VarID.Map.listItems vars)
        fun addValue (set, RecordLayout.CONST _) = set
          | addValue (set, RecordLayout.VAR (var, _)) = addVar (set, var)
        (* size is needed to read a value from closure environment. *)
        val fv = foldl (fn ((var,tag,size,usize),set) => addValue (set, size))
                       emptyVarSet
                       fields
        val fv = setminus (fv, vars)
      in
        if VarID.Map.isEmpty fv
        then fields
        else listFreeVars env fv @ fields
      end

  fun closureEnvRecordFields env freeVars =
      let
        val fields = listFreeVars env freeVars
        (* larger field first *)
        val fields =
            ListSorter.sort
              (fn ((var1,tag1,size1,usize1), (var2,tag2,size2,usize2)) =>
                  case Int.compare (usize1, usize2) of
                    EQUAL => VarID.compare (#id var1, #id var2)
                  | LESS => GREATER
                  | GREATER => LESS)
              fields
      in
        mapi (fn (i,(var,tag,size,usize)) =>
                 {label = Int.toString i,
                  var = var,
                  tag = tag,
                  size = size,
                  fieldSize = RecordLayout.const usize})
             fields
      end

  fun explodeRecord (recordVar, nil) = nil
    | explodeRecord (recordVar, {fieldExp:C.cavalue,
                                 fieldTy, fieldLabel, fieldIndex,
                                 fieldSize}::fields) =
      C.BASELECT {recordExp = C.BAVAR recordVar,
                  indexExp = fieldIndex,
                  label = fieldLabel,
                  recordTy = #ty recordVar,
                  resultTy = fieldTy,
                  resultSize = fieldSize}
      :: explodeRecord (recordVar, fields)

  fun computeClosureEnv env (freeVars, loc) =
      if VarID.Map.isEmpty freeVars
      then {makeClosureEnvExpFn = fn K => K,
            closureEnvExp = NONE,
            closureEnvArg = NONE,
            freeVarsMap = VarID.Map.empty}
      else
        let
          val fields = closureEnvRecordFields env freeVars
          val (expFn, recordExpArg) = makeRecord (fields, loc)
          val closureEnvVar = newVar (#recordTy recordExpArg)
          val closureEnvArgVar = newVar (#recordTy recordExpArg)
          val makeClosureEnvExpFn =
              expFn o Val (closureEnvVar, C.BARECORD recordExpArg, loc)
          val selectExps =
              explodeRecord (closureEnvArgVar, #fieldList recordExpArg)
          val freeVars =
              ListPair.mapEq
                (fn ({var,...}, selectExp) => 
                    (var, fn K => C.CAVAL {boundVar = var,
                                           boundExp = selectExp,
                                           nextExp = K,
                                           loc = loc}))
                (fields, selectExps)
          val freeVarsMap =
              foldl (fn (({id,...}, e), z) => VarID.Map.insert (z, id, e))
                    VarID.Map.empty
                    freeVars
        in
          {makeClosureEnvExpFn = makeClosureEnvExpFn,
           closureEnvExp = SOME (C.BAVAR closureEnvVar),
           closureEnvArg = SOME {argVar = closureEnvArgVar,
                                 freeVars = map #1 freeVars},
           freeVarsMap = freeVarsMap}
        end

  fun closureEnvArgVarSet NONE = emptyVarSet
    | closureEnvArgVarSet (SOME {argVar, freeVars:C.varInfo list}) =
      VarID.Map.singleton (#id argVar, argVar)

  fun bindFreeVars bv freeVarsMap freeVars =
      let
        val vars = VarID.Map.listItems freeVars
        val selects =
            List.mapPartial
              (fn var as {id,...}:C.varInfo =>
                  case VarID.Map.find (freeVarsMap, id) of
                    SOME e => SOME (var, e)
                  | NONE => NONE)
                vars
        val (sizes, others) =
            foldr (fn (({ty,...}, e), (sizes, others)) =>
                      case ty of
                        T.SINGLETONty (T.SIZEty _) => (e o sizes, others)
                      | _ => (sizes, e o others))
                  (fn K => K, fn K => K)
                  selects
        val expFn = sizes o others
        val tmpExp = expFn (C.CAMERGE vars)
        val fv = freeVarsExp bv tmpExp
(*
val _ = print "tmpExp:\n"
val _ = print (Control.prettyPrint (C.format_caexp tmpExp) ^ "\n")
val _ =
    app (fn v => print (Control.prettyPrint (C.format_varInfo v) ^ ","))
        (VarID.Map.listItems fv)
val _ = print "\n"
*)
      in
        if VarID.Map.isEmpty fv
        then expFn
        else bindFreeVars bv freeVarsMap fv o expFn
      end

  fun convertFn env (btvEnv, ffiAttributes, path,
                     func as {argVarList, funTy, bodyExp,
                              annotation, closureLayout, loc}:A.function) =
      let
(*
val _ = print "--- convertFn begin ---\n"
val _ = print (Control.prettyPrint (A.format_baexp bodyExp) ^ "\n")
*)
        val ftv = freeTyvarsFunction func
(*
val _ = print "ftv: "
val _ = app (fn v => print (Control.prettyPrint (C.format_tid v) ^ ",")) (BoundTypeVarID.Set.listItems ftv)
val _ = print "\n"
*)
        val (frameBitmapExp, frameBitmapVars, frameBitmapBits, frameBitmap) =
            computeFrameBitmap env (btvEnv, argVarList, ftv, loc)
        val nestEnv = bindTyvars (env, btvEnv)
        val freeTyvars = ftvToBtvEnv nestEnv ftv
        val nestEnv = bindVars (nestEnv, argVarList)
        val nestEnv = setFrameBitmap (nestEnv, frameBitmap)
        val (topdecs, bodyExp) = convertExp nestEnv bodyExp
        val bv = varSetFromList argVarList
        val freeVarsBitmap = freeVarsExp bv frameBitmapExp
        val freeVarsBody = freeVarsExp (addVars (bv, frameBitmapVars)) bodyExp
(*
val _ = print "freeVarsBody: "
val _ = app (fn v => print (Control.prettyPrint (C.format_varInfo v) ^ ",")) (VarID.Map.listItems freeVarsBody)
val _ = print "\n"
*)
        val freeVars = union (freeVarsBitmap, freeVarsBody)
(*
val _ = print "freeVars: "
val _ = app (fn v => print (Control.prettyPrint (C.format_varInfo v) ^ ",")) (VarID.Map.listItems freeVars)
val _ = print "\n"
*)

        val {makeClosureEnvExpFn, closureEnvExp, closureEnvArg, freeVarsMap} =
            computeClosureEnv env (freeVars, loc)
        val bv = union (bv, closureEnvArgVarSet closureEnvArg)
        val frameBitmapExp =
            (bindFreeVars bv freeVarsMap freeVarsBitmap) frameBitmapExp
        val bodyExp =
            (bindFreeVars bv freeVarsMap freeVarsBody) bodyExp
        val {bodyTy, ...} = AnnotatedTypesUtils.expandFunTy funTy
        val codeId = VarID.generate ()
        val clusterDecl =
            C.CAFUNCTION {codeId = codeId,
                          path = path,
                          btvEnv = btvEnv,
                          freeTyvars = freeTyvars,
                          bodyTy = bodyTy,
                          attributes = ffiAttributes,
                          closureEnvArg = closureEnvArg,
                          argVarList = argVarList,
                          frameBitmapExp = frameBitmapExp,
                          frameBitmaps = frameBitmapVars,
                          frameBitmapBits = frameBitmapBits,
                          outerFrameBitmap =
                            (#tids (#frameBitmap env),
                             map (fn v => toCavalue (v, NONE))
                                 (RecordLayout.bitmapWords
                                    (#bitmap (#frameBitmap env)))),
                          bodyExp = bodyExp,
                          annotation = annotation,
                          loc = loc}
(*
val _ = print ("codeId: " ^ Control.prettyPrint (C.format_functionCodeId codeId) ^ "\n")
val _ = print "--- convertFn end ---\n"
*)
      in
        (topdecs @ [clusterDecl], makeClosureEnvExpFn, codeId, closureEnvExp)
      end

  and convertRecBind env recBinds =
      let
        val boundVars = map #boundVar recBinds
        val env = bindVars (env, boundVars)
      in
        convertList
          (fn {boundVar,
               function as {argVarList, bodyExp, funTy,
                            annotation, closureLayout, loc}:A.function} =>
              let
                val env = bindVars (env, argVarList)
                val (topdecs, bodyExp) = convertExp env bodyExp
                (* NOTE: fv includes recursive variables *)
                val fv = freeVarsExp (varSetFromList argVarList) bodyExp
              in
                (topdecs, {boundVar = boundVar,
                           function = function,
                           bodyExp = bodyExp,
                           freeVars = fv,
                           codeId = VarID.generate ()})
              end)
          recBinds
      end

  and convertRecFn env (recBinds, loc) =
      let
        val ftv = freeTyvarsFunctionList (map #function recBinds)
        val freeTyvars = ftvToBtvEnv env ftv
        val (frameBitmapVars, frameBitmapBits) =
            if BoundTypeVarID.Set.isEmpty ftv
            then (nil, nil)
            else (frameBitmapVars (#frameBitmap env), #tids (#frameBitmap env))
        val (topdecs, recBinds) = convertRecBind env recBinds
        val freeVars = setminus (unionList (map #freeVars recBinds),
                                 varSetFromList (map #boundVar recBinds))
        val freeVars = addVars (freeVars, frameBitmapVars)
        val {makeClosureEnvExpFn, closureEnvExp, closureEnvArg, freeVarsMap} =
            computeClosureEnv env (freeVars, loc)
        val bv = closureEnvArgVarSet closureEnvArg
        val frameBitmapExp =
            (bindFreeVars bv freeVarsMap (varSetFromList frameBitmapVars))
              (C.CAMERGE frameBitmapVars)
        val closureEnvArgExp =
            Option.map (fn {argVar,...} => C.BAVAR argVar) closureEnvArg
        val freeVarsMap =
            foldl
              (fn ({boundVar, codeId, function={closureLayout,funTy,...}, ...},
                   freeVarsMap) =>
                  VarID.Map.insert
                    (freeVarsMap, #id boundVar,
                     fn K => C.CACLOSURE {boundVar = boundVar,
                                          codeId = codeId,
                                          funTy = funTy,
                                          closureEnv = closureEnvArgExp,
                                          closureLayout = closureLayout,
                                          nextExp = K,
                                          loc = loc}))
              freeVarsMap
              recBinds
        val functions =
            map (fn {codeId, function={argVarList, funTy,
                                       annotation, ...},
                     boundVar={path,...}, bodyExp, freeVars, ...} =>
                    let
                      val bv = union (bv, varSetFromList argVarList)
                    in
                      {codeId = codeId,
                       path = path,
                       argVarList = argVarList,
                       funTy = funTy,
                       bodyExp = (bindFreeVars bv freeVarsMap freeVars) bodyExp,
                       annotation = annotation,
                       loc = loc}
                    end)
                recBinds
        val clusterDecl =
            C.CARECFUNCTION {closureEnvArg = closureEnvArg,
                             freeTyvars = freeTyvars,
                             frameBitmapExp = frameBitmapExp,
                             frameBitmaps = frameBitmapVars,
                             frameBitmapBits = frameBitmapBits,
                             functions = functions,
                             loc = loc}
        val closureInfo =
            map (fn {boundVar, function, codeId, ...} =>
                    {boundVar = boundVar,
                     codeId = codeId,
                     funTy = #funTy function,
                     closureEnv = closureEnvExp,
                     closureLayout = #closureLayout function})
                recBinds
      in
        (topdecs @ [clusterDecl], makeClosureEnvExpFn, closureInfo)
      end

  and convertLocalFn env recbindList =
      let
        val env = bindVars (env, map #boundVar recbindList)
      in
        convertList
          (fn {boundVar,
               function={argVarList, funTy, bodyExp,
                         annotation, closureLayout, loc}:A.function} =>
              let
                val env = bindVars (env, argVarList)
                val (topdecs1, bodyExp) = convertExp env bodyExp
              in
                (topdecs1,
                 {boundVar = boundVar,
                  function = {argVarList = argVarList,
                              bodyExp = bodyExp,
                              funTy = funTy,
                              annotation = annotation,
                              loc = loc} : C.localFunction})
              end)
          recbindList
      end

  and convertSwitch env ({switchExp, expTy, branches, defaultExp, loc}
                         :A.switch) =
      let
        val (topdecs1, branches) =
            convertList
              (fn {constant, branchExp} =>
                  let
                    val (topdecs1, branchExp) = convertExp env branchExp
                  in
                    (topdecs1, {constant = constant, branchExp = branchExp})
                  end)
              branches
        val (topdecs2, defaultExp) = convertExp env defaultExp
      in
        (topdecs1 @ topdecs2,
         {switchExp = switchExp,
          expTy = expTy,
          branches = branches,
          defaultExp = defaultExp,
	  loc = loc} : C.switch)
      end

  and convertExp env baexp =
      case baexp of
        A.BAVAL {boundVar, boundExp, nextExp, loc} =>
        let
          val env = bindVars (env, [boundVar])
          val (topdecs1, nextExp) = convertExp env nextExp
        in
          (topdecs1,
           C.CAVAL {boundVar = boundVar,
                    boundExp = boundExp,
                    nextExp = nextExp,
                    loc = loc})
        end
      | A.BACALL {resultVars, callExp, nextExp, loc} =>
        let
          val env = bindVars (env, resultVars)
          val (topdecs1, nextExp) = convertExp env nextExp
        in
          (topdecs1,
           C.CACALL {resultVars = resultVars,
                     callExp = callExp,
                     nextExp = nextExp,
                     loc = loc})
        end
      | A.BAEXPORTVAR {varInfo, varSize, varTag, nextExp, loc} =>
        let
          val (topdecs1, nextExp) = convertExp env nextExp
        in
          (C.CATOPVAR {path = #path varInfo,
                       initialValue = NONE,
                       elementTy = #ty varInfo,
                       elementSize = valueToWord varSize}
           :: topdecs1,
           C.CAEXPORTVAR {varInfo = varInfo,
                          varSize = varSize,
                          varTag = varTag,
                          nextExp = nextExp,
                          loc = loc})
        end
      | A.BAEXTERNVAR {exVarInfo, nextExp, loc} =>
        let
          val (topdecs1, nextExp) = convertExp env nextExp
        in
          (C.CAEXTERNVAR {exVarInfo = exVarInfo, loc = loc} :: topdecs1,
           nextExp)
        end
      | A.BAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
        let
          val (topdecs1, tryExp) = convertExp env tryExp
          val handlerEnv = bindVars (env, [exnVar])
          val (topdecs2, handlerExp) = convertExp handlerEnv handlerExp
          val env = bindVars (env, resultVars)
          val (topdecs3, nextExp) = convertExp env nextExp
        in
          (topdecs1 @ topdecs2 @ topdecs3,
           C.CAHANDLE {resultVars = resultVars,
                       tryExp = tryExp,
                       exnVar = exnVar,
                       handlerExp = handlerExp,
                       nextExp = nextExp,
                       loc = loc})
        end
      | A.BASWITCH {resultVars, switch, nextExp} =>
        let
          val (topdecs1, switch) = convertSwitch env switch
          val env = bindVars (env, resultVars)
          val (topdecs2, nextExp) = convertExp env nextExp
        in
          (topdecs1 @ topdecs2,
           C.CASWITCH {resultVars = resultVars,
                       switch = switch,
                       nextExp = nextExp})
        end
      | A.BATAILSWITCH switch =>
        let
          val (topdecs1, switch) = convertSwitch env switch
        in
          (topdecs1, C.CATAILSWITCH switch)
        end
      | A.BAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
        let
          val nestEnv = bindTyvars (env, btvEnv)
          val (topdecs1, exp) = convertExp nestEnv exp
          val env = bindVars (env, resultVars)
          val (topdecs2, nextExp) = convertExp env nextExp
        in
          (topdecs1 @ topdecs2,
           C.CAPOLY {resultVars = resultVars,
                     btvEnv = btvEnv,
                     expTyWithoutTAbs = expTyWithoutTAbs,
                     exp = exp,
                     nextExp = nextExp,
                     loc = loc})
        end
(*
      | A.BANEST {resultVars, nestExp, nextExp, loc} =>
        let
          val (topdecs1, nestExp) = convertExp env nestExp
          val env = bindVars (env, resultVars)
          val (topdecs2, nextExp) = convertExp env nextExp
        in
          (topdecs1 @ topdecs2,
           C.CANEST {resultVars = resultVars,
                     nestExp = nestExp,
                     nextExp = nextExp,
                     loc = loc})
        end
*)
      | A.BAMERGE resultVars =>
        (nil, C.CAMERGE resultVars)
      | A.BARETURN {resultVars, funTy, loc} =>
        (nil,
         C.CARETURN {resultVars = resultVars,
                     funTy = funTy,
                     loc = loc})
      | A.BATAILAPPM {funExp, funTy, argExpList, loc} =>
        (nil,
         C.CATAILAPPM {funExp = funExp,
                       funTy = funTy,
                       argExpList = argExpList,
                       loc = loc})
      | A.BARAISE {argExp, loc} =>
        (nil,
         C.CARAISE {argExp = argExp,
                    loc = loc})
      | A.BAFNM {boundVar, btvEnv, function as {funTy,...}, nextExp} =>
        if AnnotatedTypesUtils.isLocalFunTy funTy then
          let
            val _ = if BoundTypeVarID.Map.isEmpty btvEnv
                    then () else raise Control.Bug "convertExp: BAFNM"
            val (topdecs1, recbindList) =
                convertLocalFn env [{boundVar=boundVar, function=function}]
            val env = bindVars (env, [boundVar])
            val (topdecs2, nextExp) = convertExp env nextExp
          in
            (topdecs1 @ topdecs2,
             C.CALOCALFNM {recbindList = recbindList,
                           nextExp = nextExp,
                           loc = #loc function})
          end
        else
          let
            val (topdecs1, makeClosureEnvExpFn, codeId, closureEnv) =
                convertFn env (btvEnv, NONE, #path boundVar, function)
            val (topdecs2, nextExp) = convertExp env nextExp
          in
            (topdecs1 @ topdecs2,
             makeClosureEnvExpFn
               (C.CACLOSURE {boundVar = boundVar,
                             codeId = codeId,
                             funTy = funTy,
                             closureEnv = closureEnv,
                             closureLayout = #closureLayout function,
                             nextExp = nextExp,
                             loc = #loc function}))
          end
      | A.BACALLBACKFNM {boundVar, function, foreignFunTy as {attributes,...},
                         nextExp} =>
        let
          val (topdecs1, makeClosureEnvExpFn, codeId, closureEnv) =
              convertFn env (emptyBtvEnv, SOME attributes, #path boundVar,
                             function)
          val (topdecs2, nextExp) = convertExp env nextExp
        in
          (topdecs1 @ topdecs2,
           makeClosureEnvExpFn
             (C.CACALLBACKCLOSURE {boundVar = boundVar,
                                   codeId = codeId,
                                   closureEnv = closureEnv,
                                   foreignFunTy = foreignFunTy,
                                   nextExp = nextExp,
                                   loc = #loc function}))
        end
      | A.BAVALREC {recbindList, nextExp, loc} =>
        if List.all (fn {function={funTy,...},...} =>
                        AnnotatedTypesUtils.isLocalFunTy funTy)
                    recbindList
        then
          let
            val (topdecs1, recbindList) = convertLocalFn env recbindList
            val (topdecs2, nextExp) = convertExp env nextExp
          in
            (topdecs1 @ topdecs2,
             C.CALOCALFNM {recbindList = recbindList,
                           nextExp = nextExp,
                           loc = loc})
          end
        else
          let
            val (topdecs1, makeClosureEnvExpFn, closureInfo) =
                convertRecFn env (recbindList, loc)
            val (topdecs2, nextExp) = convertExp env nextExp
            val closureExp =
                foldr
                  (fn ({boundVar, codeId, funTy, closureEnv,
                        closureLayout}, z) =>
                      C.CACLOSURE {boundVar = boundVar,
                                   codeId = codeId,
                                   funTy = funTy,
                                   closureEnv = closureEnv,
                                   closureLayout = closureLayout,
                                   nextExp = z,
                                   loc = loc})
                  nextExp
                  closureInfo
          in
            (topdecs1 @ topdecs2, makeClosureEnvExpFn closureExp)
          end

  fun convert bcexp =
      let
        val (topdecs, caexp) = convertExp emptyEnv bcexp
      in
        topdecs @ [C.CATOPLEVEL caexp]
      end

end
