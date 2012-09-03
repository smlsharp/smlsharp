(**
 *  This module analyses dependency relation between the compilation units
 * the parser generated.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: DependencyAnalyzer.sml,v 1.5 2006/05/23 05:23:59 kiyoshiy Exp $
 *)
structure DependencyAnalyzer : DEPENDENCY_ANALYZER =
struct

  (***************************************************************************)

  structure EA = ElaboratedAst
  structure AA = AnnotatedAst
  structure DG = DependencyGraph
  structure DGP = DocumentGenerationParameter
  structure U = Utility

  (***************************************************************************)

  local
    fun addModuleName
            moduleType (name, moduleNames : (EA.moduleType * string) list) =
        (moduleType, name) :: moduleNames
  in
  val addStructure = addModuleName EA.STRUCTURE
  val addSignature = addModuleName EA.SIGNATURE
  val addFunctor = addModuleName EA.FUNCTOR
  val addFunctorSignature = addModuleName EA.FUNCTORSIGNATURE
  end

  fun getDeclaredModules (AA.CompileUnit(fileName, decs)) =
      let
        fun visit (AA.StrDec(name, _, _, _, _)) = [(EA.STRUCTURE, name)]
          | visit (AA.FctDec(name, _, _, _)) = [(EA.FUNCTOR, name)]
          | visit (AA.SigDec(name, _, _, _)) = [(EA.SIGNATURE, name)]
          | visit (AA.FsigDec(name, _, _, _)) = [(EA.FUNCTORSIGNATURE, name)]
          | visit (AA.LocalDec(_, globals)) = List.concat(map visit globals)
          | visit _ = []
      in
        List.concat(map visit decs)
      end

  (****************************************)

  local
    local
      (**
       *
       * if the target module is a nested modules, return null.
       * otherwise, a list consisting of single pair of FQNs of current module
       * and target module.
       *)
      fun getREFofModule
              moduleType currentModule localModules (path as (topName::_)) =
          if List.exists (fn pair => pair = (moduleType, topName)) localModules
          then []
          else
            (*  At this point, it is found that the target is a module
             * declared at top level.
             *  In SML source code, references to nested modules in top level
             * signatures/functors/funsigs from outside of the module are not
             * allowed.
             *  Therefore, we can consider the modules along the path but the
             * innermost module are all structures.
             *)
            let
              val (prefixes, lastModuleName) = U.splitLast path
              val parentFQN = map (fn name => (EA.STRUCTURE, name)) prefixes
            in
              [(currentModule, parentFQN @ [(moduleType, lastModuleName)])]
            end
    in
    val getREFofStructure = getREFofModule EA.STRUCTURE
    val getREFofFunctor = getREFofModule EA.FUNCTOR
    val getREFofSignature = getREFofModule EA.SIGNATURE
    val getREFofFunctorSignature = getREFofModule EA.FUNCTORSIGNATURE
    end

    fun getREFofType currentModule localModules [typeName] = []
      | getREFofType currentModule localModules (path as _::_) =
        getREFofStructure currentModule localModules path
    fun getREFofException currentModule localModules [exnName] = []
      | getREFofException currentModule localModules (path as _::_) =
        getREFofStructure currentModule localModules path

    (****************************************)

    fun visitSigConst currentModule visit localModules sigConst =
        case sigConst of
          AA.NoSig => []
        | AA.Transparent s => visit currentModule localModules s
        | AA.Opaque s => visit currentModule localModules s

    fun visitStrExp currentModule localModules strExp =
        case strExp of
          AA.VarStr path => getREFofStructure currentModule localModules path
        | AA.BaseStr decs =>
          let val (_, deps) = visitDecList currentModule localModules decs
          in deps end
        | AA.ConstrainedStr(strExp, sigConst) =>
          let
            val deps1 =
                visitSigConst currentModule visitSigExp localModules sigConst
            val deps2 = visitStrExp currentModule localModules strExp
          in deps1 @ deps2 end
        | AA.AppStr(path, strExpAndIsExps) =>
          let
            fun visit (strExp, _) =
                visitStrExp currentModule localModules strExp
            val deps1 = List.concat(map visit strExpAndIsExps)
            val deps2 = getREFofFunctor currentModule localModules path
          in deps1 @ deps2 end
        | AA.LetStr(decs, strExp) =>
          let
            val (newLocalModules, deps1) =
                visitDecList currentModule localModules decs
            val deps2 =
                visitStrExp
                    currentModule (newLocalModules @ localModules) strExp
          in deps1 @ deps2 end

    and visitFctExp currentModule localModules fctExp =
        case fctExp of
          AA.VarFct(path, sigConst) =>
          let
            val deps =
                visitSigConst currentModule visitFsigExp localModules sigConst
          in (getREFofFunctor currentModule localModules path) @ deps end
        | AA.BaseFct{params, body, constraint} =>
          let
            val (deltalocalModules, deps1) =
                foldl
                (visitFctParamSpec currentModule localModules) ([], []) params
            val deps2 =
                visitSigConst currentModule visitSigExp localModules constraint
            val deps3 =
                visitStrExp
                    currentModule (deltalocalModules @ localModules) body
          in deps1 @ deps2 @ deps3 end
        | AA.AppFct(path, strExpAndIsExps, sigConst) =>
          let
            fun visit (strExp, _) =
                visitStrExp currentModule localModules strExp
            val deps1 = List.concat(map visit strExpAndIsExps)
            val deps2 = getREFofFunctor currentModule localModules path
            val deps3 =
                visitSigConst currentModule visitFsigExp localModules sigConst
          in deps1 @ deps2 @ deps3 end
        | AA.LetFct(decs, fctExp) =>
          let
            val (deltalocalModules, deps1) =
                visitDecList currentModule localModules decs
            val deps2 =
                visitFctExp
                    currentModule (deltalocalModules @ localModules) fctExp
          in deps1 @ deps2 end

    and visitWhereSpec currentModule localModules whereSpec =
        case whereSpec of
          AA.WhType(qid, tyvars, ty) => visitTy currentModule localModules ty
        | AA.WhStruct(qid, structPath) =>
          getREFofStructure currentModule localModules structPath

    and visitSigExp currentModule localModules sigExp =
        case sigExp of
          AA.VarSig name => (* all signatures are defined in top level.  *)
          getREFofSignature currentModule localModules [name]
        | AA.AugSig(sigExp, whereSpecs) =>
          let
            val deps =
                List.concat
                (map (visitWhereSpec currentModule localModules) whereSpecs)
          in deps @ (visitSigExp currentModule localModules sigExp) end
        | AA.BaseSig specs =>
          let val (_, deps) = visitSpecList currentModule localModules specs
          in deps end

    and visitFsigExp currentModule localModules fsigExp =
        case fsigExp of
          AA.VarFsig name => (* all signatures are defined in top level.  *)
          getREFofFunctorSignature currentModule localModules [name]
        | AA.BaseFsig{params, result} =>
          let
            val (deltalocalModules, deps1) =
                foldl
                (visitFctParamSpec currentModule localModules)
                ([], [])
                params
            val deps2 =
                visitSigExp
                    currentModule (deltalocalModules @ localModules) result
          in deps1 @ deps2 end

    and visitFctParamSpec
        currentModule localModules (nameAndSigExp, (deltalocalModules, deps)) =
        let
          val localModules = deltalocalModules @ localModules
          val (deltalocalModules', newDeps) =
              case nameAndSigExp of
                (NONE, AA.BaseSig specs) =>
                let
                  val (deltaLocalModules', deps) =
                      visitSpecList currentModule localModules specs
                in (deltaLocalModules' @ deltalocalModules, deps) end
              | (SOME name, sigExp) =>
                (
                  addStructure (name, deltalocalModules),
                  visitSigExp currentModule localModules sigExp
                )
        in (deltalocalModules', deps @ newDeps) end

    and visitSpec currentModule localModules spec =
        case spec of
          AA.StrSpec(name, _, sigExp, pathOpt, _) =>
          let val newModule = currentModule @ [(EA.STRUCTURE, name)]
          in
            (
              addStructure (name, []),
              visitSigExp newModule localModules sigExp
            )
          end
        | AA.TycSpec(_, _, _, tyOpt, _, _) =>
          ([], visitTyOpt currentModule localModules tyOpt)
        | AA.FctSpec(name, _, fsigExp, _) =>
          let val newModule = currentModule @ [(EA.FUNCTOR, name)]
          in
            (
              addFunctor (name, []),
              visitFsigExp newModule localModules fsigExp
            )
          end
        | AA.ValSpec(name, _, ty, optDC) =>
          ([], visitTy currentModule localModules ty)
        | AA.DataSpec{datatycs, withtycs} =>
          ([], visitDataTycs currentModule localModules (datatycs, withtycs))
        | AA.ExceSpec(name, _, tyOpt, optDC) =>
          ([], visitTyOpt currentModule localModules tyOpt)
        | AA.ShareStrSpec paths =>
          (* sharing spec includes no reference to toplevel modules. *)
          ([], [])
        | AA.ShareTycSpec paths => ([], [])
        | AA.IncludeSpec sigExp =>
          ([], visitSigExp currentModule localModules sigExp)

    and visitSpecList currentModule localModules specs =
        let
          fun visit (spec, (deltalocalModules, deps)) =
              let
                val (deltalocalModules', deps') =
                    visitSpec
                        currentModule (deltalocalModules @ localModules) spec
              in ((deltalocalModules' @ deltalocalModules), deps' @ deps) end
          val (deltaLocalModules, deps) = foldl visit ([], []) specs
        in (deltaLocalModules, deps) end

    and visitDec currentModule localModules dec =
        case dec of
          AA.ValDec(name, _, optDC) => ([], [])
        | AA.FunDec(name, _, optDC) => ([], [])
        | AA.TypeDec(tb) => ([], visitTB currentModule localModules tb)
        | AA.DatatypeDec{datatycs, withtycs} =>
          ([], visitDataTycs currentModule localModules (datatycs, withtycs))
        | AA.AbstypeDec {datatycs, withtycs, body} =>
          let
            val deps1 =
                visitDataTycs currentModule localModules (datatycs, withtycs)
            val (deltalocalModules, deps2) =
                visitDecList currentModule localModules body
          in
            (deltalocalModules, deps1 @ deps2)
          end
        | AA.ExceptionDec(eb) => visitEB currentModule localModules eb
        | AA.StrDec(name, _, strExp, sigConst, optDC) =>
          let
            val newModule = currentModule @ [(EA.STRUCTURE, name)]
            val deps1 =
                visitSigConst newModule visitSigExp localModules sigConst
          in
            (
              addStructure (name, []),
              visitStrExp newModule localModules strExp @ deps1
            )
          end
        | AA.FctDec(name, _, fctExp, optDC) =>
          let val newModule = currentModule @ [(EA.FUNCTOR, name)]
          in
            (
              addFunctor (name, []),
              visitFctExp newModule localModules fctExp
            )
          end
        | AA.SigDec(name, _, sigExp, optDC) =>
          let val newModule = currentModule @ [(EA.SIGNATURE, name)]
          in
            (
              addSignature (name, []),
              visitSigExp newModule localModules sigExp
            )
          end
        | AA.FsigDec(name, _, fsigExp, optDC) =>
          let val newModule = currentModule @ [(EA.FUNCTORSIGNATURE, name)]
          in
            (
              addFunctorSignature (name, []),
              visitFsigExp newModule localModules fsigExp
            )
          end
        | AA.LocalDec(localDecs, globalDecs) =>
          let
            val (deltalocalModules, deps1) =
                visitDecList currentModule localModules localDecs
            val (deltalocalModules', deps2) =
                visitDecList
                    currentModule (deltalocalModules @ localModules) globalDecs
          in (deltalocalModules', deps1 @ deps2) end
        | AA.OpenDec path =>
          let
            val structureRef =
                getREFofStructure currentModule localModules path
          in ([], structureRef) end

    and visitDecList currentModule localModules decs =
        let
          fun visit (dec, (deltalocalModules, deps)) =
              let
                val (deltalocalModules', deps') =
                    visitDec
                        currentModule (deltalocalModules @ localModules) dec
              in ((deltalocalModules' @ deltalocalModules), deps' @ deps) end
          val (deltalocalModules, deps) = foldl visit ([], []) decs
        in (deltalocalModules, deps) end
              
    and visitTB
            currentModule localModules (AA.Tb(name, _, tyvars, tyOpt, optDC)) =
        visitTyOpt currentModule localModules tyOpt

    and visitDataTycs currentModule localModules (dbs, tbs) =
        let
          fun visitDB (AA.Db({rhs, ...}, optDC)) =
              visitDBRHS currentModule localModules rhs
          fun visitTB (AA.Tb(_, _, _, tyOpt, _)) =
              visitTyOpt currentModule localModules tyOpt
        in List.concat((map visitDB dbs) @ (map visitTB tbs)) end
              
    and visitDBRHS currentModule localModules (AA.Constrs constrs) =
        let
          fun visit localModules (_, _, tyOpt, _) =
              visitTyOpt currentModule localModules tyOpt
        in List.concat(map (visit localModules) constrs) end
      | visitDBRHS currentModule localModules (AA.Repl path) =
        getREFofType currentModule localModules path

    and visitEB currentModule localModules (AA.EbGen(name, _, tyOpt, optDC)) =
        ([], visitTyOpt currentModule localModules tyOpt)
      | visitEB currentModule localModules (AA.EbDef(name, _, path, optDC)) =
        ([], getREFofException currentModule localModules path)
            
    and visitTy currentModule localModules ty =
        case ty of
          AA.VarTy tyvar => []
        | AA.ConTy(tyc, tys) =>
          (getREFofType currentModule localModules tyc) @
          (List.concat(map (visitTy currentModule localModules) tys))
        | AA.RecordTy(fields) =>
          let
            fun visit (label, ty, optDC) =
                visitTy currentModule localModules ty
          in List.concat(map visit fields) end
        | AA.TupleTy elements =>
          let fun visit ty = visitTy currentModule localModules ty
          in List.concat(map visit elements) end
        | AA.CommentedTy (docComment, ty') =>
          visitTy currentModule localModules ty'

    and visitTyOpt currentModule localModules NONE = []
      | visitTyOpt currentModule localModules (SOME ty) =
        visitTy currentModule localModules ty

  in
  fun getDependedModules (AA.CompileUnit(fileName, decs)) =
      let val (_, deps) = visitDecList [] [] decs in deps end
  end

  (****************************************)

  local
    fun findIndex condition list =
        let
          fun find _ [] = NONE
            | find index (hd::tl) =
              if condition hd then SOME(index) else find (index + 1) tl
        in find 0 list end
  in
  fun buildGraph DG declaredModules dependedModules =
      let
        fun findUnitIndexOfModule module =
            findIndex
            (fn declaredModules =>
                List.exists (fn m => m = (List.hd module)) declaredModules)
            declaredModules

        fun setDependency _ [] = ()
          | setDependency srcIndex (dependedModules::others) =
            let
              val destUnitIndexes =
                  List.map
                  valOf
                  (List.filter
                   (fn NONE => false | SOME destIndex => srcIndex <> destIndex)
                   (map findUnitIndexOfModule dependedModules))
            in
              app
              (fn destIndex =>
                  DG.dependsOn
                      DG {src = srcIndex, dest = destIndex, attr = ()})
              destUnitIndexes;
              setDependency (srcIndex + 1) others
            end

      in setDependency 0 dependedModules end
  end

  (****************************************)

  fun sort parameter unitList =
      let
        fun printUnitList header unitList =
            DGP.onProgress parameter
            (String.concat
            ([header, "["] @
             (U.interleave
              ", " 
              (map (fn (AA.CompileUnit(fileName, _)) => fileName) unitList)) @
             ["]"]))

        fun printUnitsWithModules header units modulesList =
            let
              val print =
                  fn (AA.CompileUnit(fileName, _), modules) =>
                     DGP.onProgress
                     parameter
                     (String.concat
                      ([header, fileName, ": "] @
                       (U.interleave
                        ", "
                        (map EA.moduleFQNToString modules))))
            in app print (ListPair.zip (units, modulesList)) end

        fun checkDuplication units declaredModules =
            let
              val fileAndModuleList =
                  List.concat
                  (map
                  ( fn (AA.CompileUnit(fileName, _), modules) =>
                       map (fn module => (fileName, module)) modules)
                   (ListPair.zip (units, declaredModules)))
              val filesOfModuleList =
                  foldl
                  (fn ((fileName, module), list) =>
                      case List.partition (fn pair => module = #1 pair) list of
                        ([], _) => (module, [fileName]) :: list
                      | ([(_, fileNames)], other) =>
                        (module, fileName :: fileNames) :: other)
                  []
                  fileAndModuleList
            in
              app
              (fn (_, [_]) => ()
                | ((moduleType, moduleName), fileNames as _::_) =>
                  DGP.warn
                      parameter
                      (moduleName ^ " is declared in " ^
                       (U.interleaveString ", " fileNames)))
              filesOfModuleList
            end

        (********************)

        val _ = printUnitList "Before sort: " unitList

        val DG = DG.create (List.length unitList)

        val declaredModules = map getDeclaredModules unitList
        val _ =
            printUnitsWithModules "Declared in " unitList
            (map
             (fn modules => map (fn name => [name]) modules)
             declaredModules)
        val _ = checkDuplication unitList declaredModules

        val dependenciesList = map getDependedModules unitList
        val dependedModules =
            map
            (fn dependencies => map (fn (src, dest) => dest) dependencies)
            dependenciesList
        val _ = printUnitsWithModules "Depended by " unitList dependedModules

        val _ = buildGraph DG declaredModules dependedModules
        val sortedUnitIndexes = DG.sort DG (fn () => true)
        val sortedUnitList =
            map (fn index => List.nth (unitList, index)) sortedUnitIndexes

        val _ = printUnitList "After sort: " sortedUnitList
      in
        sortedUnitList
      end

  (***************************************************************************)

end