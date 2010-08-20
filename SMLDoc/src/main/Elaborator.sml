(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Elaborator.sml,v 1.7 2006/05/23 05:24:00 kiyoshiy Exp $
 *)
structure Elaborator : ELABORATOR =
struct

  (***************************************************************************)

  structure AA = AnnotatedAst
  structure EA = ElaboratedAst
  structure ES = ENVSet
  structure DC = DocComment
  structure DGP = DocumentGenerationParameter
  structure U = Utility

  (***************************************************************************)

  type path = string list

  type context =
       {
         currentModule : EA.moduleFQN,
         ENVSet : ES.ENVSet,
         parameter : DGP.parameter,
         unknownModuleNames : EA.path list ref,
         unknownElementNames : EA.path list ref,
         warnings : string list ref
       }

  (***************************************************************************)

  local
    (**
     * return the entry in envset for the module the specified path points to.
     * <p>
     *  The module reference which this function returns is assumed to be used
     * to get the information of sub elements (= type,val,structure,...) in
     * this module. It must not be used in the result of elaboration as is.
     * </p>
     * <p>
     *  In SML source code, sub components in signatures/functors/funsigs
     * can not be referred to.
     * So, We can assume that the all modules on the 'path' are structures.
     * </p>
     *)
    fun getENVEntryOfParentModule
        (CTX as {ENVSet, parameter, unknownModuleNames, ...} : context) path =
        let
          fun trace (_, EA.UnknownRef path, ENVSet) =
              (EA.UnknownRef path, ENVSet)
            | trace ([], EA.ModuleRef(ABSFQN, _), ENVSet) =
              (EA.ModuleRef(ABSFQN, path), ENVSet)
            | trace ([], reference as EA.ExternalRef _, ENVSet) =
              (reference, ENVSet)
            | trace (moduleName::childPath, _, ES.ENVSet parentENVSet) =
              (* reference is ModuleRef or ExternalRef *)
              (case
                 List.find
                 (fn (name, _, _) => name = moduleName)
                 (#structureENV parentENVSet)
                of
                NONE =>
                (
                  unknownModuleNames := path :: (!unknownModuleNames);
                  (EA.UnknownRef (path), ES.emptyENVSet)
                )
              | SOME(_, reference, ENVSet) =>
                trace (childPath, reference, ENVSet))
        in trace (path, EA.ModuleRef([], []), ENVSet) end

    fun getREFOfElement
        ENVSelector
        (CTX : context as {parameter, unknownElementNames, ...})
        (path : path) =
        let
          val (modulePath, elementName) = U.splitLast path
          val (moduleRef, ES.ENVSet ENVSet) =
              getENVEntryOfParentModule CTX modulePath
        in
          case moduleRef of
            EA.UnknownRef _ => (EA.UnknownRef modulePath, path)
          | _ =>
            case
              List.find (fn (n, _) => n = elementName) (ENVSelector ENVSet)
             of
              NONE =>
              (
                unknownElementNames := path :: (!unknownElementNames);
                (EA.UnknownRef modulePath, path)
              )
            | SOME (_, EA.ModuleRef(definingModuleABSFQN, _)) =>
              (*
               * NOTE :
               *  The 'definingModuleRef' is not always same as The 'moduleRef'
               * if the target element is imported from a module to other
               * module by 'include' specification and 'open' declaration.
               *  In the generated document, the importing module name should
               * be used as displayed text, but the hyperlink of that text
               * should point to the page for defining module.
               *  So, we return the absolute FQN of defining module and the
               * relative FQN of importing module
               *)
              (EA.ModuleRef(definingModuleABSFQN, modulePath), path)
            | SOME (_, reference) =>
              (reference, path) (* UnknownRef or ExternalRef *)
        end

    fun getENVEntryOfModule moduleType (CTX : context) (path : path) =
        let
          val (parentPath, moduleName) = U.splitLast path
          val envSelector = case moduleType of
                              EA.STRUCTURE => #structureENV
                            | EA.FUNCTOR => #functorENV
                            | EA.SIGNATURE => #signatureENV
                            | EA.FUNCTORSIGNATURE => #functorSignatureENV
        in
          case getENVEntryOfParentModule CTX parentPath of
            (EA.UnknownRef _, _) => (EA.UnknownRef path, ES.emptyENVSet)
          | (_, ES.ENVSet parentENVSet) =>
            case
              List.find
                  (fn (name, _, _) => name = moduleName)
                  (envSelector parentENVSet)
             of
              NONE => (EA.UnknownRef path, ES.emptyENVSet)
            | SOME(_, EA.ModuleRef(ABSFQN, _), childENVSet) =>
              (EA.ModuleRef(ABSFQN, path), childENVSet)
            | SOME(_, reference, childENVSet) =>
              (reference, childENVSet) (* UnknownRef or ExternalRef *)
        end

    val getENVEntryOfStructure = getENVEntryOfModule EA.STRUCTURE
    val getENVEntryOfSignature = getENVEntryOfModule EA.SIGNATURE
    val getENVEntryOfFunctor = getENVEntryOfModule EA.FUNCTOR
    val getENVEntryOfFunctorSignature = getENVEntryOfModule EA.FUNCTORSIGNATURE
  in
  val getREFOfType = getREFOfElement #typeENV
  val getREFOfException = getREFOfElement #exceptionENV

  fun getREFOfStructure CTX path = #1(getENVEntryOfStructure CTX path)
  fun getREFOfSignature CTX path = #1(getENVEntryOfSignature CTX path)
  fun getREFOfFunctor CTX path = #1(getENVEntryOfFunctor CTX path)
  fun getREFOfFunctorSignature CTX path =
      #1(getENVEntryOfFunctorSignature CTX path)

  fun getENVSetOfStructure CTX path = #2(getENVEntryOfStructure CTX path)
  fun getENVSetOfSignature CTX path = #2(getENVEntryOfSignature CTX path)
  fun getENVSetOfFunctor CTX path = #2(getENVEntryOfFunctor CTX path)
  fun getENVSetOfFunctorSignature CTX path =
      #2(getENVEntryOfFunctorSignature CTX path)
  end

  local
    fun isModuleInENV moduleENV moduleName =
        List.exists (fn (name, _, _) => name = moduleName) moduleENV
    fun isElementInENV elementENV elementName =
        List.exists (fn (name, _) => name = elementName) elementENV
  in
  fun isStructureInENV (ES.ENVSet{structureENV, ...}) =
      isModuleInENV structureENV
  fun isSignatureInENV (ES.ENVSet{signatureENV, ...}) =
      isModuleInENV signatureENV
  fun isFunctorInENV (ES.ENVSet{functorENV, ...}) = isModuleInENV functorENV
  fun isFunctorSignatureInENV (ES.ENVSet{functorSignatureENV, ...}) =
      isModuleInENV functorSignatureENV
  fun isTypeInENV (ES.ENVSet{typeENV, ...}) = isElementInENV typeENV
  fun isExceptionInENV (ES.ENVSet{exceptionENV, ...}) =
      isElementInENV exceptionENV
  fun isValInENV (ES.ENVSet{valENV, ...}) = isElementInENV valENV
  end

  fun getTypeOfValInENV (name, ES.ENVSet ENVSet) =
      case List.find (fn (n, _) => n = name) (#valENV ENVSet) of
        NONE => NONE
      | SOME(_, tyOpt) => tyOpt
  fun getStructureInENV (name, ES.ENVSet ENVSet) =
      case List.find (fn (n, _, _) => n = name) (#structureENV ENVSet) of
        NONE => ES.emptyENVSet
      | SOME(_, _, subENVSet) => subENVSet
  fun getFunctorInENV (name, ES.ENVSet ENVSet) =
      case List.find (fn (n, _, _) => n = name) (#functorENV ENVSet) of
        NONE => ES.emptyENVSet
      | SOME(_, _, subENVSet) => subENVSet

  fun bindVal (name, CTX : context, tyOpt) =
      ES.bindVal ES.emptyENVSet (name, tyOpt)

  fun bindType (name, {currentModule, ...} : context) =
      ES.bindType ES.emptyENVSet (name, EA.ModuleRef(currentModule, []))
  fun addExternalType ((name, modulePath), ENVSet) =
      ES.bindType ENVSet (name, EA.UnknownRef modulePath)

  fun bindException (name, {currentModule, ...} : context) =
      ES.bindException ES.emptyENVSet (name, EA.ModuleRef(currentModule, []))
  fun addExternalException ((name, modulePath), ENVSet) =
      ES.bindException ENVSet (name, EA.UnknownRef modulePath)

  fun bindStructure (name, {currentModule, ...} : context, myENVSet) =
      ES.bindStructure
      ES.emptyENVSet
      (name, EA.ModuleRef(currentModule@[(EA.STRUCTURE, name)], []), myENVSet)
  fun bindStructureOfFunctorParameter
          (name, {currentModule, ...} : context, myENVSet) =
      ES.bindStructure
      ES.emptyENVSet
      (
        name,
        EA.ModuleRef
        (currentModule@[(EA.FUNCTORPARAMETER_STRUCTURE, name)], []),
        myENVSet
      )
  fun addExternalStructure ((name, path), ENVSet) =
      ES.bindStructure ENVSet (name, EA.UnknownRef path, ES.emptyENVSet)

  fun bindSignature (name, {currentModule, ...} : context, myENVSet) =
      ES.bindSignature
      ES.emptyENVSet
      (
        name,
        EA.ModuleRef(currentModule@[(EA.SIGNATURE, name)], []),
        myENVSet
      )
  fun addExternalSignature ((name, path), ENVSet) =
      ES.bindSignature ENVSet (name, EA.UnknownRef path, ES.emptyENVSet)

  fun bindFunctor (name, {currentModule, ...} : context, myENVSet) =
      ES.bindFunctor
      ES.emptyENVSet
      (
        name,
        EA.ModuleRef(currentModule@[(EA.FUNCTOR, name)], []),
        myENVSet
      )
  fun addExternalFunctor ((name, path), ENVSet) =
      ES.bindFunctor ENVSet (name, EA.UnknownRef path, ES.emptyENVSet)

  fun bindFunctorSignature (name, {currentModule, ...} : context, myENVSet) =
      ES.bindFunctorSignature
      ES.emptyENVSet
      (
        name,
        EA.ModuleRef(currentModule@[(EA.FUNCTORSIGNATURE, name)], []),
        myENVSet
      )
  fun addExternalFunctorSignature ((name, path), ENVSet) =
      ES.bindFunctorSignature
          ENVSet (name, EA.UnknownRef path, ES.emptyENVSet)

  fun enterModule (CTX : context) moduleType name =
      {
        currentModule = (#currentModule CTX) @ [(moduleType, name)],
        ENVSet = #ENVSet CTX,
        parameter = #parameter CTX,
        unknownModuleNames = #unknownModuleNames CTX,
        unknownElementNames = #unknownElementNames CTX,
        warnings = #warnings CTX
      }

  fun pushENVSetOnCTX (newENVSet, CTX : context) =
      {
        currentModule = #currentModule CTX,
        ENVSet = ES.appendENVSet(newENVSet, #ENVSet CTX),
        parameter = #parameter CTX,
        unknownModuleNames = #unknownModuleNames CTX,
        unknownElementNames = #unknownElementNames CTX,
        warnings = #warnings CTX
      }

  fun toHideBySig
      ({parameter = DGP.Parameter parameter, ...} : context)
      sigENVSetOpt
      isEntityInENV
      name =
      case sigENVSetOpt of
        NONE => false
      | SOME sigENVSet =>
        if #hideBySig parameter
        then not(isEntityInENV sigENVSet name)
        else false

  (****************************************)

  local
    fun elaborateParamPattern (DC.IDParamPat id) = EA.IDParamPat (id, NONE)
      | elaborateParamPattern (DC.TupleParamPat pats) =
        EA.TupleParamPat(map elaborateParamPattern pats)
      | elaborateParamPattern (DC.RecordParamPat patRows) =
        EA.RecordParamPat
        (map (fn (label, pat) => (label, elaborateParamPattern pat)) patRows)

    fun elaborateDocComment
        (CTX : context as {parameter, warnings, ...})
        (summary, description, tags) =
        let
          val initialTagSet =
              EA.TagSet
              {
                authors = [],
                contributors = [],
                copyrights = [],
                exceptions = [],
                params = [],
                paramPattern = NONE,
                return = NONE,
                sees = [],
                version = NONE
              }

          fun append (DC.AuthorTag author, EA.TagSet tagSet) =
              EA.TagSet
              {
                authors = author :: (#authors tagSet),
                contributors = #contributors tagSet,
                copyrights = #copyrights tagSet,
                exceptions = #exceptions tagSet,
                params = #params tagSet,
                paramPattern = #paramPattern tagSet,
                return = #return tagSet,
                sees = #sees tagSet,
                version = #version tagSet
              }
            | append (DC.ContributorTag contributor, EA.TagSet tagSet) =
              EA.TagSet
              {
                authors = #authors tagSet,
                contributors = contributor :: (#contributors tagSet),
                copyrights = #copyrights tagSet,
                exceptions = #exceptions tagSet,
                params = #params tagSet,
                paramPattern = #paramPattern tagSet,
                return = #return tagSet,
                sees = #sees tagSet,
                version = #version tagSet
              }
            | append (DC.CopyrightTag copyright, EA.TagSet tagSet) =
              EA.TagSet
              {
                authors = #authors tagSet,
                contributors = #contributors tagSet,
                copyrights = copyright :: (#copyrights tagSet),
                exceptions = #exceptions tagSet,
                params = #params tagSet,
                paramPattern = #paramPattern tagSet,
                return = #return tagSet,
                sees = #sees tagSet,
                version = #version tagSet
              }
            | append (DC.ExceptionTag (path, description), EA.TagSet tagSet) =
              let val reference = getREFOfException CTX path
              in
                EA.TagSet
                {
                  authors = #authors tagSet,
                  contributors = #contributors tagSet,
                  copyrights = #copyrights tagSet,
                  exceptions = (reference, description) :: #exceptions tagSet,
                  params = #params tagSet,
                  paramPattern = #paramPattern tagSet,
                  return = #return tagSet,
                  sees = #sees tagSet,
                  version = #version tagSet
                }
              end
            | append (DC.ParamTag (name, description), EA.TagSet tagSet) =
              EA.TagSet
              {
                authors = #authors tagSet,
                contributors = #contributors tagSet,
                copyrights = #copyrights tagSet,
                exceptions = #exceptions tagSet,
                params = (name, NONE, description) :: (#params tagSet),
                paramPattern = #paramPattern tagSet,
                return = #return tagSet,
                sees = #sees tagSet,
                version = #version tagSet
              }
            | append (DC.ParamsTag patterns, EA.TagSet tagSet) =
              if #paramPattern tagSet = NONE
              then
                EA.TagSet
                {
                  authors = #authors tagSet,
                  contributors = #contributors tagSet,
                  copyrights = #copyrights tagSet,
                  exceptions = #exceptions tagSet,
                  params = #params tagSet,
                  paramPattern = SOME (map elaborateParamPattern patterns),
                  return = #return tagSet,
                  sees = #sees tagSet,
                  version = #version tagSet
                }
              else
                (
                  warnings := "multiple params tag found." :: (!warnings);
                  EA.TagSet tagSet
                )
            | append (DC.ReturnTag description, EA.TagSet tagSet) =
              if #return tagSet = NONE
              then
                EA.TagSet
                {
                  authors = #authors tagSet,
                  contributors = #contributors tagSet,
                  copyrights = #copyrights tagSet,
                  exceptions = #exceptions tagSet,
                  params = #params tagSet,
                  paramPattern = #paramPattern tagSet,
                  return = SOME description,
                  sees = #sees tagSet,
                  version = #version tagSet
                }
              else
                (
                  warnings := "multiple return tag found." :: (!warnings);
                  EA.TagSet tagSet
                )
            | append (DC.SeeTag description, EA.TagSet tagSet) =
              (* ToDo : parse description. *)
              EA.TagSet
              {
                authors = #authors tagSet,
                contributors = #contributors tagSet,
                copyrights = #copyrights tagSet,
                exceptions = #exceptions tagSet,
                params = #params tagSet,
                paramPattern = #paramPattern tagSet,
                return = #return tagSet,
                sees = description :: (#sees tagSet),
                version = #version tagSet
              }
            | append (DC.VersionTag version, EA.TagSet tagSet) =
              if #version tagSet = NONE
              then
                EA.TagSet
                {
                  authors = #authors tagSet,
                  contributors = #contributors tagSet,
                  copyrights = #copyrights tagSet,
                  exceptions = #exceptions tagSet,
                  params = #params tagSet,
                  paramPattern = #paramPattern tagSet,
                  return = #return tagSet,
                  sees = #sees tagSet,
                  version = SOME version
                }
              else
                (
                  warnings := "multiple version tag found." :: (!warnings);
                  EA.TagSet tagSet
                )

          val elaboratedTags = foldr append initialTagSet tags
        in
          (summary, description, elaboratedTags)
        end

    fun elaborateDocCommentOpt (CTX : context) NONE = NONE
      | elaborateDocCommentOpt CTX (SOME docComment) =
        SOME(elaborateDocComment CTX docComment)

    fun elaborateSigConst elaborate CTX sigConst =
        case sigConst of
          AA.NoSig => (NONE, EA.NoSig)
        | AA.Transparent s =>
          let val (ENVSet, s') = elaborate CTX s
          in (SOME ENVSet, EA.Transparent s') end
        | AA.Opaque s => 
          let val (ENVSet, s') = elaborate CTX s
          in (SOME ENVSet, EA.Opaque s') end

    fun elaborateStrExp CTX _ (AA.VarStr path) =
        (getENVSetOfStructure CTX path, EA.VarStr (getREFOfStructure CTX path))
      | elaborateStrExp CTX sigENVSetOpt (AA.BaseStr decs) =
        let val (ENVSet', decSet) = elaborateDecList CTX sigENVSetOpt decs
        in (ENVSet', EA.BaseStr decSet) end
      | elaborateStrExp
            CTX sigENVSetOpt (AA.ConstrainedStr(strExp, sigConst)) =
        let
          (* we ignore passed sigENVSet, and use sigENVSet' instead because
           * sigENVSet' contains more information than passed sigENVSet *)
          val (sigENVSetOpt', sigConst') =
              elaborateSigConst elaborateSigExp CTX sigConst
          (* ToDo : add type info of sigConst into CTX *)
          val (ENVSet, strExp') = elaborateStrExp CTX sigENVSetOpt' strExp
        in (ENVSet, EA.ConstrainedStr(strExp', sigConst')) end
      | elaborateStrExp CTX _ (AA.AppStr(path, strExpAndIsExps)) =
        let
          fun elaborate (strExp, isExp) =
              let
                val innerCTX =
                    enterModule CTX EA.ANONYMOUS_FUNCTORPARAMETER_STRUCTURE ""
                val (_, strExp') = elaborateStrExp innerCTX NONE strExp
              in (strExp', isExp) end
          val strExpAndIsExps' = map elaborate strExpAndIsExps
          val functorRef = getREFOfFunctor CTX path
          val ENVSet = getENVSetOfFunctor CTX path
        in (ENVSet, EA.AppStr(functorRef, strExpAndIsExps')) end
      | elaborateStrExp CTX sigENVSetOpt (AA.LetStr(decs, strExp)) =
        let
          (* ToDo : mark entries in local envset as 'local' *)
          val (ENVSet, _) = elaborateDecList CTX NONE decs
          val CTX' = pushENVSetOnCTX(ENVSet, CTX)
          val (ENVSet', strExp') = elaborateStrExp CTX' sigENVSetOpt strExp
        in (ENVSet', strExp') end

    and elaborateFctExp CTX _ (AA.VarFct(path, sigConst)) =
        let
          val (_, sigConst') = elaborateSigConst elaborateFsigExp CTX sigConst
        in
          (
            getENVSetOfFunctor CTX path,
            EA.VarFct(getREFOfFunctor CTX path, sigConst')
          )
        end
      | elaborateFctExp
            CTX fsigENVSetOpt (AA.BaseFct{params, body, constraint}) =
        let
          val (ENVSet, params') =
              foldl (elaborateFctParamSpec CTX) (ES.emptyENVSet, []) params
          val params'' = List.rev params'
          (* ToDo : add type info into CTX *)
          val CTX' = pushENVSetOnCTX(ENVSet, CTX)
          (*  The context used in elaboration of constraining signature of
           * functor should contain binding infos of functor parameter
           * (see ML definition p36). *)
          val (sigENVSetOpt, sigConst) =
              elaborateSigConst elaborateSigExp CTX' constraint
          (* we use sigENVSet instead of passed fsigENVSet *)
          val (ENVSet', body') =
              elaborateStrExp CTX' sigENVSetOpt body
        in
          (
            ENVSet',
            EA.BaseFct{params = params'', body = body', constraint = sigConst}
          )
        end
      | elaborateFctExp CTX _ (AA.AppFct(path, strExpAndIsExps, sigConst)) =
        let
          fun elaborate (strExp, isExp) =
              let
                val innerCTX =
                    enterModule CTX EA.ANONYMOUS_FUNCTORPARAMETER_STRUCTURE ""
                val (_, strExp') = elaborateStrExp innerCTX NONE strExp
              in (strExp', isExp) end
          val strExpAndIsExps' = map elaborate strExpAndIsExps
          val functorRef = getREFOfFunctor CTX path
          val ENVSet = getENVSetOfFunctor CTX path
          val (_, sigConst') = elaborateSigConst elaborateFsigExp CTX sigConst
        in (ENVSet, EA.AppFct(functorRef, strExpAndIsExps', sigConst')) end
      | elaborateFctExp CTX fsigENVSetOpt (AA.LetFct(decs, fctExp)) =
        let
          val (ENVSet, _) = elaborateDecList CTX NONE decs
          val CTX' = pushENVSetOnCTX(ENVSet, CTX)
          val (ENVSet', fctExp') = elaborateFctExp CTX' fsigENVSetOpt fctExp
        in (ENVSet', fctExp') end

    and elaborateWhereSpec CTX (AA.WhType(qid, tyvars, ty)) =
        EA.WhType(qid, tyvars, elaborateTy CTX ty)
      | elaborateWhereSpec CTX (AA.WhStruct(qid, structPath)) =
        EA.WhStruct(qid, getREFOfStructure CTX structPath)

    and elaborateSigExp CTX =
        let
          fun elaborate whereSpecsList (AA.VarSig name) =
              (* all signatures are defined in top level.  *)
              let
                val sigExp = EA.VarSig (getREFOfSignature CTX [name])
                val ENVSet = getENVSetOfSignature CTX [name]
              in
                if null whereSpecsList
                then (ENVSet, sigExp)
                else (ENVSet, EA.AugSig(sigExp, whereSpecsList))
              end
            | elaborate whereSpecsList (AA.AugSig(sigExp, whereSpecs)) =
              let val whereSpecs' = map (elaborateWhereSpec CTX) whereSpecs
              in elaborate ((whereSpecs')::whereSpecsList) sigExp end
            | elaborate whereSpecsList (AA.BaseSig specs) =
              let
                val (ENVSet, specSet) = elaborateSpecList CTX specs
                val sigExp = 
                    if null whereSpecsList
                    then EA.BaseSig specSet
                    else EA.AugSig(EA.BaseSig specSet, whereSpecsList)
              in (ENVSet, sigExp) end
        in
          elaborate []
        end

    and elaborateFsigExp CTX (AA.VarFsig name) =
        (* all signatures are defined in top level.  *)
        (
          getENVSetOfFunctorSignature CTX [name],
          EA.VarFsig(getREFOfFunctorSignature CTX [name])
        )
      | elaborateFsigExp CTX (AA.BaseFsig{params, result}) =
        let
          val (ENVSet, params') =
              foldl (elaborateFctParamSpec CTX) (ES.emptyENVSet, []) params
          val params'' = List.rev params'
          val (ENVSet', result') =
              elaborateSigExp (pushENVSetOnCTX(ENVSet, CTX)) result
        in (ENVSet', EA.BaseFsig {params = params'', result = result'}) end

    and elaborateFctParamSpec CTX ((nameOpt, sigExp), (ENVSet, params)) =
        let
          val CTX = pushENVSetOnCTX(ENVSet, CTX)
          val (ENVSet', sigExp') =
              case (nameOpt, sigExp) of
                (NONE, AA.BaseSig specs) =>
                let
                  val innerCTX =
                      enterModule
                      CTX EA.ANONYMOUS_FUNCTORPARAMETER_STRUCTURE "annonymous"
                  val (ENVSet', specSet) = elaborateSpecList innerCTX specs
                in
                  (*
                   * NOTE : Entities specified in the specs are included in
                   * the deltaCTX' as direct elements of the current module,
                   * but the anonymous structure is included in neither
                   * the deltaCTX' nor the deltaCTX.
                   *)
                  (* use openCTXon instead pushCTXon *)
                  (ES.appendENVSet(ENVSet', ENVSet), EA.BaseSig specSet)
                end
              | (SOME name, sigExp) =>
                let
                  val innerCTX =
                      enterModule CTX EA.FUNCTORPARAMETER_STRUCTURE name
                  val (ENVSet', sigExp') = elaborateSigExp innerCTX sigExp

                in
                  (
                    (* extend ENVSet *)
                    ES.appendENVSet
                    (
                      bindStructureOfFunctorParameter (name, CTX, ENVSet'),
                      ENVSet
                    ),
                    sigExp'
                  )
                end
        in (ENVSet', (nameOpt, sigExp')::params) end

    and elaborateSpec CTX (AA.StrSpec(name, loc, sigExp, pathOpt, optDC)) =
        let
          val module = (#currentModule CTX) @ [(EA.STRUCTURE, name)]
          val innerCTX = enterModule CTX EA.STRUCTURE name
          val (ENVSet, sigExp') = elaborateSigExp innerCTX sigExp
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindStructure (name, CTX, ENVSet),
            EA.SpecSet
            {
              strs = [EA.SIGB(module, name, loc, sigExp', pathOpt, optDC)],
              types = [], fcts = [], vals = [], datatypes = [],
              exceptions = [],
              shareStrs = [], shareTycs = [], includes = []
            }
          )
        end
      | elaborateSpec
            CTX (AA.TycSpec(name, loc, tyvars, tyOpt, isEqType, optDC)) =
        let
          val module = #currentModule CTX
          val optDC = elaborateDocCommentOpt CTX optDC
          val tyOpt' = elaborateTyOpt CTX tyOpt
        in
          (
            bindType (name, CTX),
            EA.SpecSet
            {
              types =
              [EA.TB(module, name, loc, tyvars, tyOpt', isEqType, optDC)],
              strs = [], fcts = [], vals = [], datatypes = [],
              exceptions = [],
              shareStrs = [], shareTycs = [], includes = []
            }
          )
        end
      | elaborateSpec CTX (AA.FctSpec(name, loc, fsigExp, optDC)) =
        let
          val module = #currentModule CTX @ [(EA.FUNCTOR, name)]
          val innerCTX = enterModule CTX EA.FUNCTOR name
          val (ENVSet, fsigExp') = elaborateFsigExp innerCTX fsigExp
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindFunctor (name, CTX, ENVSet),
            EA.SpecSet
            {
              fcts = [EA.FSIGB(module, name, loc, fsigExp', optDC)], 
              strs = [], types = [], vals = [], datatypes = [],
              exceptions = [], shareStrs = [], shareTycs = [], includes = []
            }
          )
        end
      | elaborateSpec CTX (AA.ValSpec(name, loc, ty, optDC)) =
        let
          val module = #currentModule CTX
          val ty' = elaborateTy CTX ty
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            (* bind with the type not elaborated *)
            bindVal (name, CTX, SOME ty), 
            EA.SpecSet
            {
              vals = [EA.VB(module, name, loc, SOME ty', optDC)], 
              strs = [], types = [], fcts = [], datatypes = [],
              exceptions = [],
              shareStrs = [], shareTycs = [], includes = []
            }
          )
        end
      | elaborateSpec CTX (AA.DataSpec{datatycs, withtycs}) =
        let
          val module = #currentModule CTX
          val (ENVSet, datatycs', withtycs') =
              elaborateDataTycs CTX (datatycs, withtycs)
        in
          (
            ENVSet,
            EA.SpecSet
            {
              types = withtycs',
              datatypes = datatycs',
              strs = [], fcts = [], vals = [], exceptions = [],
              shareStrs = [], shareTycs = [], includes = []
            }
          )
        end
      | elaborateSpec CTX (AA.ExceSpec(name, loc, tyOpt, optDC)) =
        let
          val module = #currentModule CTX
          val tyOpt' = elaborateTyOpt CTX tyOpt
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindException(name, CTX),
            EA.SpecSet
            {
              exceptions = [EA.EBGen(module, name, loc, tyOpt', optDC)],
              strs = [], types = [], fcts = [], vals = [], datatypes = [], 
              shareStrs = [], shareTycs = [], includes = []
            }
          )
        end
      | elaborateSpec CTX (AA.ShareStrSpec paths) =
        (
          ES.emptyENVSet,
          EA.SpecSet
          {
            shareStrs = [map (getREFOfSignature CTX) paths], 
            strs = [], types = [], fcts = [], vals = [], datatypes = [],
            exceptions = [], shareTycs = [], includes = []
          }
        )
      | elaborateSpec CTX (AA.ShareTycSpec paths) =
        (
          ES.emptyENVSet,
          EA.SpecSet
          {
            shareTycs = [map (getREFOfType CTX) paths], 
            strs = [], types = [], fcts = [], vals = [], datatypes = [],
            exceptions = [], shareStrs = [], includes = []
          }
        )
      | elaborateSpec CTX (AA.IncludeSpec sigExp) =
        let val (ENVSet, sigExp') = elaborateSigExp CTX sigExp
        in
          (
            ENVSet,
            EA.SpecSet
            {
              includes = [sigExp'],
              strs = [], types = [], fcts = [], vals = [], datatypes = [],
              exceptions = [], shareStrs = [], shareTycs = []
            }
          )
        end

    and elaborateSpecList CTX specs =
        let
          fun elaborate (spec, (ENVSet, specSets)) =
              let
                val (ENVSet', specSet') =
                    elaborateSpec (pushENVSetOnCTX(ENVSet, CTX)) spec
              in (ES.appendENVSet(ENVSet', ENVSet), specSet'::specSets) end
          val (ENVSet, specSets) = foldl elaborate (ES.emptyENVSet, []) specs
          val specSet = foldl EA.appendSpecSet EA.emptySpecSet specSets
          (*
           * Items in ENVSet are arranged in the reverse order of declaration.
           * Items in specSet are arranged in the order of declaration
           * (by double foldls).
           *)
        in (ENVSet, specSet) end

    and elaborateDec CTX sigENVSetOpt (AA.ValDec(name, loc, optDC)) =
        let
          val module = #currentModule CTX
          val optDC = elaborateDocCommentOpt CTX optDC
          val tyOpt = case sigENVSetOpt of
                        NONE => NONE
                      | SOME sigENVSet => getTypeOfValInENV (name, sigENVSet)
          val tyOpt' =
              case tyOpt of NONE => NONE | SOME ty => SOME(elaborateTy CTX ty)
        in
          (*  If the user specifies --hidebysig option and this entity declared
           * is not specified in the signature constraining the structure,
           * this entity should not be included in the result decSet so that
           * this entity is not included in the generated documents,
           * but must be added to the result ENVSet to prevent resolving
           * references appeared in declarations following this declaration
           * incorrectly.
           *)
          (
            bindVal (name, CTX, tyOpt),
            if toHideBySig CTX sigENVSetOpt isValInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                vals = [EA.VB(module, name, loc, tyOpt', optDC)],
                types = [], datatypes = [], exceptions = [],
                strs = [], fcts = [], sigs = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.FunDec(name, loc, optDC)) =
        let
          val module = #currentModule CTX
          val optDC = elaborateDocCommentOpt CTX optDC
          val tyOpt = case sigENVSetOpt of
                        NONE => NONE
                      | SOME sigENVSet => getTypeOfValInENV (name, sigENVSet)
          val tyOpt' =
              case tyOpt of NONE => NONE | SOME ty => SOME(elaborateTy CTX ty)
        in              
          (
            bindVal (name, CTX, tyOpt),
            if toHideBySig CTX sigENVSetOpt isValInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                vals = [EA.VB(module, name, loc, tyOpt', optDC)],
                types = [], datatypes = [], exceptions = [],
                strs = [], fcts = [], sigs = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.TypeDec(tb)) =
        let
          val (ENVSet', tb' as EA.TB(_, name, _, _, _, _, _)) =
              elaborateTB CTX tb
        in
          (
            ENVSet',
            if toHideBySig CTX sigENVSetOpt isTypeInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                types = [tb'],
                vals = [], datatypes = [], exceptions = [],
                strs = [], fcts = [], sigs = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.DatatypeDec{datatycs, withtycs}) =
        let
          val (ENVSet', datatycs', withtycs') =
              elaborateDataTycs CTX (datatycs, withtycs)
          val datatycs'' =
              List.filter
              (fn (EA.DB(_, name, _, _, _, _)) =>
                  not(toHideBySig CTX sigENVSetOpt isTypeInENV name))
              datatycs'
          val withtycs'' =
              List.filter
              (fn (EA.TB(_, name, _, _, _, _, _)) =>
                  not(toHideBySig CTX sigENVSetOpt isTypeInENV name))
              withtycs'
        in
          (
            ENVSet',
            EA.DecSet
            {
              types = withtycs'', datatypes = datatycs'',
              vals = [], exceptions = [],
              strs = [], fcts = [], sigs = [], fsigs = [], opens = []
            }
          )
        end
      | elaborateDec
            CTX sigENVSetOpt (AA.AbstypeDec{datatycs, withtycs, body}) =
        let
          val (ENVSet', datatycs', withtycs') =
              elaborateDataTycs CTX (datatycs, withtycs)
          val datatycs'' =
              List.filter
              (fn (EA.DB(_, name, _, _, _, _)) =>
                  not(toHideBySig CTX sigENVSetOpt isTypeInENV name))
              datatycs'
          val withtycs'' =
              List.filter
              (fn (EA.TB(_, name, _, _, _, _, _)) =>
                  not(toHideBySig CTX sigENVSetOpt isTypeInENV name))
              withtycs'
          val (bodyENVSet, bodyDecSet) =
              elaborateDecList
                  (pushENVSetOnCTX(ENVSet', CTX)) sigENVSetOpt body
          (* convert datatype bind into type bind to hide representation. *)
          fun dbToTb (EA.DB(FQN, name, loc, tyvars, _, optDC)) =
              EA.TB(FQN, name, loc, tyvars, NONE, false, optDC)
        in
          (
            ES.appendENVSet(bodyENVSet, ENVSet'),
            EA.appendDecSet
            (
              EA.DecSet
              {
                types = (map dbToTb datatycs'') @ withtycs'', datatypes = [],
                vals = [], exceptions = [],
                strs = [], fcts = [], sigs = [], fsigs = [], opens = []
              },
              bodyDecSet
            )
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.ExceptionDec(eb)) =
        let
          val (ENVSet', eb') = elaborateEB CTX eb
          val name =
              case eb' of
                EA.EBGen(_, name, _, _, _) => name
              | EA.EBDef(_, name, _, _, _) => name
        in
          (
            ENVSet',
            if toHideBySig CTX sigENVSetOpt isExceptionInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                exceptions = [eb'],
                vals = [], types = [], datatypes = [], 
                strs = [], fcts = [], sigs = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec
            CTX sigENVSetOpt (AA.StrDec(name, loc, strExp, sigConst, optDC)) =
        let
          val module = #currentModule CTX @ [(EA.STRUCTURE, name)]
          val (constENVSetOpt, sigConst') =
              elaborateSigConst elaborateSigExp CTX sigConst
          val subENVSetOpt =
              case (sigENVSetOpt, sigConst) of
                (SOME sigENVSet, AA.NoSig) =>
                SOME(getStructureInENV (name, sigENVSet))
              | _ => constENVSetOpt
          val innerCTX = enterModule CTX EA.STRUCTURE name
          val (ENVSet, strExp') = elaborateStrExp innerCTX subENVSetOpt strExp
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindStructure (name, CTX, ENVSet),
            if toHideBySig CTX sigENVSetOpt isStructureInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                strs =
                [EA.STRB(module, name, loc, strExp', sigConst', optDC)], 
                vals = [], types = [], datatypes = [], exceptions = [],
                fcts = [], sigs = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.FctDec(name, loc, fctExp, optDC)) =
        let
          val module = #currentModule CTX @ [(EA.FUNCTOR, name)]
          val innerCTX = enterModule CTX EA.FUNCTOR name
          val innerFSIGENVSet =
              case sigENVSetOpt of
                NONE => NONE
              | SOME sigENVSet => SOME(getFunctorInENV(name, sigENVSet))
          val (ENVSet, fctExp') =
              elaborateFctExp innerCTX innerFSIGENVSet fctExp
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindFunctor (name, CTX, ENVSet),
            if toHideBySig CTX sigENVSetOpt isFunctorInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                fcts = [EA.FCTB(module, name, loc, fctExp', optDC)], 
                vals = [], types = [], datatypes = [], exceptions = [],
                strs = [], sigs = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.SigDec(name, loc, sigExp, optDC)) =
        let
          val module = #currentModule CTX @ [(EA.SIGNATURE, name)]
          val innerCTX = enterModule CTX EA.SIGNATURE name
          val (ENVSet, sigExp') = elaborateSigExp innerCTX sigExp
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindSignature (name, CTX, ENVSet),
            if toHideBySig CTX sigENVSetOpt isSignatureInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                sigs = [EA.SIGB(module, name, loc, sigExp', NONE, optDC)], 
                vals = [], types = [], datatypes = [], exceptions = [],
                strs = [], fcts = [], fsigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.FsigDec(name, loc, fsigExp, optDC)) =
        let
          val module = #currentModule CTX @ [(EA.FUNCTORSIGNATURE, name)]
          val innerCTX = enterModule CTX EA.FUNCTORSIGNATURE name
          val (ENVSet, fsigExp') = elaborateFsigExp innerCTX fsigExp
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindFunctorSignature (name, CTX, ENVSet),
            if toHideBySig CTX sigENVSetOpt isFunctorSignatureInENV name
            then EA.emptyDecSet
            else
              EA.DecSet
              {
                fsigs = [EA.FSIGB(module, name, loc, fsigExp', optDC)], 
                vals = [], types = [], datatypes = [], exceptions = [],
                strs = [], fcts = [], sigs = [], opens = []
              }
          )
        end
      | elaborateDec CTX sigENVSetOpt (AA.LocalDec(localDecs, globalDecs)) =
        let
          val (ENVSet, _) = elaborateDecList CTX sigENVSetOpt localDecs
          val (ENVSet', decSet) =
              elaborateDecList
                  (pushENVSetOnCTX(ENVSet, CTX)) sigENVSetOpt globalDecs
        in
          (ENVSet', decSet)
        end
      | elaborateDec CTX _ (AA.OpenDec path) =
        let
          val structureRef = getREFOfStructure CTX path
          val ENVSet = getENVSetOfStructure CTX path
        in
          (
            ENVSet,
            EA.DecSet
            {
              opens = [structureRef],
              vals = [], types = [], datatypes = [], exceptions = [],
              strs = [], fcts = [], sigs = [], fsigs = []
            }
          )
        end

    and elaborateDecList CTX sigENVSetOpt decs =
        let
          fun elaborate (dec, (ENVSet, decSets)) =
              let
                val CTX' = pushENVSetOnCTX(ENVSet, CTX)
                val (ENVSet', decSet') = elaborateDec CTX' sigENVSetOpt dec
              in (ES.appendENVSet(ENVSet', ENVSet), decSet'::decSets) end
          val (ENVSet, decSets) = foldl elaborate (ES.emptyENVSet, []) decs
          val decSet = foldl EA.appendDecSet EA.emptyDecSet decSets
          (*
           * Items in ENVSet are arranged in the reverse order of declaration.
           * Items in decSet are arranged in the order of declaration
           * (by double foldls).
           *)
        in (ENVSet, decSet) end
              
    and elaborateTB CTX (AA.Tb(name, loc, tyvars, tyOpt, optDC)) =
        let
          val module = #currentModule CTX
          val optDC = elaborateDocCommentOpt CTX optDC
          val tyOpt' = Option.map (elaborateTy CTX) tyOpt
        in
          (
            bindType (name, CTX),
            EA.TB(module, name, loc, tyvars, tyOpt', false, optDC)
          )
        end

    and elaborateDataTycs CTX (dbs, tbs) =
        let
          val module = #currentModule CTX
          val dataNames = map (fn (AA.Db({tyc, ...},_)) => tyc) dbs
          val typeNames = map (fn (AA.Tb(name, _, _, _, _)) => name) tbs
          val ENVSet = 
              foldl
              (fn (name, ENVSet) =>
                  ES.appendENVSet
                      (bindType (name, pushENVSetOnCTX(ENVSet, CTX)), ENVSet))
              ES.emptyENVSet
              (dataNames @ typeNames)
          fun elaborateDB CTX (AA.Db({tyc, loc, tyvars, rhs}, optDC)) =
              let
                val resultTy =
                    EA.ConTy
                    ((EA.ModuleRef(module, []), [tyc]), map EA.VarTy tyvars)
                val optDC = elaborateDocCommentOpt CTX optDC
                val dbrhs = elaborateDBRHS CTX resultTy rhs
              in
                EA.DB(module, tyc, loc, tyvars, dbrhs, optDC)
              end
          fun elaborateTB CTX (AA.Tb(name, loc, tyvars, tyOpt, optDC)) =
              let
                val optDC = elaborateDocCommentOpt CTX optDC
                val tyOpt' = Option.map (elaborateTy CTX) tyOpt
              in
                EA.TB (module, name, loc, tyvars, tyOpt', false, optDC)
              end
          val CTX' = pushENVSetOnCTX(ENVSet, CTX)
        in (ENVSet, map (elaborateDB CTX') dbs, map (elaborateTB CTX') tbs) end
              
    and elaborateDBRHS CTX resultTy (AA.Constrs constrs) =
        let
          val module = #currentModule CTX
          fun elaborate CTX (name, loc, tyOpt, optDC) =
              let
                val optDC = elaborateDocCommentOpt CTX optDC
              in
                EA.CB
                (module, name, loc, elaborateTyOpt CTX tyOpt, resultTy, optDC)
              end
        in EA.Constrs(map (elaborate CTX) constrs) end
      | elaborateDBRHS CTX resultTy (AA.Repl path) =
        EA.Repl(getREFOfType CTX path)

    and elaborateEB CTX (AA.EbGen(name, loc, tyOpt, optDC)) =
        let
          val module = #currentModule CTX
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindException (name, CTX),
            EA.EBGen(module, name, loc, elaborateTyOpt CTX tyOpt, optDC)
          )
        end
      | elaborateEB CTX (AA.EbDef(name, loc, path, optDC)) =
        let
          val module = #currentModule CTX
          val optDC = elaborateDocCommentOpt CTX optDC
        in
          (
            bindException (name, CTX),
            EA.EBDef(module, name, loc, getREFOfException CTX path, optDC)
          )
        end
            
    and elaborateTy CTX (AA.VarTy tyvar) = EA.VarTy tyvar
      | elaborateTy CTX (AA.ConTy(["->"], [ty1, ty2])) =
        EA.FunTy(elaborateTy CTX ty1, elaborateTy CTX ty2)
      | elaborateTy CTX (AA.ConTy(tyc, tys)) =
        EA.ConTy(getREFOfType CTX tyc, map (elaborateTy CTX) tys)
      | elaborateTy CTX (AA.RecordTy(fields)) =
        let
          fun elaborate (label, ty, optDC) =
              let val optDC = elaborateDocCommentOpt CTX optDC
              in (label, elaborateTy CTX ty, optDC) end
        in EA.RecordTy(map elaborate fields) end
      | elaborateTy CTX (AA.TupleTy elements) =
        EA.TupleTy(map (elaborateTy CTX) elements)
      | elaborateTy CTX (AA.CommentedTy(docComment, ty)) =
        EA.CommentedTy(elaborateDocComment CTX docComment, elaborateTy CTX ty)

    and elaborateTyOpt CTX NONE = NONE
      | elaborateTyOpt CTX (SOME ty) = SOME(elaborateTy CTX ty)

  in
  (**
   * elaboration.
   * <p>
   * This function does:
   * <ul>
   *   <li>name resolution. All references are translated to FQNs.</li>
   *   <li>type annotation. Values and functions are annotated with their
   *       types.</li>
   * </ul>
   * </p>
   *)
  fun elaborate parameter initialENVSet unitList =
      let
        fun warnUnknownNames message paths =
            let
              val names = map EA.pathToString paths
              val sorted = U.sort (op <) names
              val uniqued = U.uniq sorted
            in
              app
                  (fn name => DGP.warn parameter (message ^ " " ^ name))
                  uniqued
            end
        val (extendedENVSet, addedENVSet, units) =
            foldl
            (fn (
                  AA.CompileUnit(fileName, decs),
                  (extendedENVSet, addedENVSet, units)
                ) =>
                (
                  DGP.onProgress parameter ("Elaborating: " ^ fileName);
                  let
                    val unknownModuleNames = ref []
                    val unknownElementNames = ref []
                    val warnings = ref []

                    val (newENVSet, newDecSet) =
                        elaborateDecList
                        ({
                           currentModule = [],
                           ENVSet = extendedENVSet,
                           parameter = parameter,
                           unknownModuleNames = unknownModuleNames,
                           unknownElementNames = unknownElementNames,
                           warnings = warnings
                         } : context)
                        NONE
                        decs
                  in
                    warnUnknownNames
                        (fileName ^ ":unknown module")
                        (List.rev(!unknownModuleNames));
                    warnUnknownNames
                        (fileName ^ ":unknown name")
                        (List.rev(!unknownElementNames));
                    app
                        (fn message =>
                            DGP.warn parameter (fileName ^ ":" ^ message))
                        (List.rev(!warnings));
                    (*
                     * ENVSet is arranged in the reverse order of declaration.
                     * DecSet is arranged in the order of declaration.
                     *)
                    (
                      ES.appendENVSet(newENVSet, extendedENVSet),
                      ES.appendENVSet(newENVSet, addedENVSet),
                      EA.CompileUnit(fileName, newDecSet) :: units
                    )
                  end
                ))
            (initialENVSet, ES.emptyENVSet, [])
            unitList
      in
        (addedENVSet, units)
      end
  end

  (***************************************************************************)

end