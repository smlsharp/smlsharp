(**
 * compilation of linkage unit
 * a linkage unit form is as follows:
 * ***************************************************
 * namespace myorg.sometool
 * import org.smlsharp.compiler.tool
 * require myorg.myrequire
 *
 * (* some ordinary toplevel declarations here *)
 * ***************************************************
 * @author Liu Bochao
 * @version $Id: CompileObject.sml,v 1.11 2008/03/25 02:39:44 bochao Exp $
 *)
structure CompileObject : sig val compile : string -> unit end =
struct
local
    structure C = Control
    structure UE = UserError
    structure PU = PathUtility
    structure P = Pickle
    structure NM = NameMap
    structure N = Namespace
    structure NPEnv = NameMap.NPEnv
    structure UIAC = UniqueIdAllocationContext
    structure TB = TopBasis
    structure TE = TopLevelError

   fun print message = 
       (TextIO.output (TextIO.stdErr, message); TextIO.flushOut TextIO.stdErr)

    val interfaceExt = ".smi" (* i for interface *)
    val objectExt = ".smo" (* o for object *)

    (* to be refactored *)
    fun initializeDummySession () = 
        let
            val session : SessionTypes.Session =
                {execute = fn _ => (), close = fn () => ()} 
        in
            session
        end
    
    val dummySession = initializeDummySession ()

    fun initializeSysParam session = 
        {
         session = session,
         standardOutput = TextIOChannel.openOut {outStream = TextIO.stdOut},
         standardError = TextIOChannel.openOut {outStream = TextIO.stdErr},
         loadPathList =  ["."],
         getVariable = OS.Process.getEnv
        } : TB.sysParam
        
    fun removeFileNameExt fileName = 
        let
            val suffixLength = 
                case (OS.Path.ext fileName) of
                    SOME suffix => size(suffix) + 1
                  | NONE => 0
        in
            substring(fileName, 0, size(fileName) - suffixLength)
        end

    fun getShortFileNameWithoutExt filePath = 
        let
            val {dir, file} = OS.Path.splitDirFile filePath
        in 
            removeFileNameExt file
        end

    fun getLongFileNameWithoutExt filePath = 
        let
            val {dir, file} = OS.Path.splitDirFile filePath
        in 
            OS.Path.joinDirFile {dir = dir, file =removeFileNameExt file}
        end

    fun absynNamespaceToNamespace absynNamespace =
        case absynNamespace of
            Absyn.NAMESPACE (longid, loc) => 
            Namespace.fromStringList longid
          | Absyn.ABSNAMESPACE (longid, loc) => 
            Namespace.fromStringList longid
          | EMPTYNAMESPACE => 
            Namespace.defaultNamespace
            
    fun resolveAbsolutePath (sysParam : TB.sysParam) currentBaseDirectory fileName =
        PathResolver.resolve (#getVariable sysParam)
                             (#loadPathList sysParam)
                             currentBaseDirectory
                             fileName
                             handle exn => raise UE.UserErrorsWithoutLoc [(UE.Error, exn)]

in
    type parseSource =
         {getBaseDirectory : unit -> string,
          fileName : string,
          stream : ChannelTypes.InputChannel}

    structure Parser = 
    struct
          fun makeInterfaceParseSourceAndParseContext
                  sysParam (parseSource: parseSource) errorToString createContext = 
              let
                  val parseContext = 
                      createContext {isPrelude = false,
                                     sourceName = #fileName parseSource,
                                     onError = (Top.printError sysParam) o errorToString,
                                     getLine = fn n => (#getLine (#stream parseSource)) ()}
              in
                  (parseSource, parseContext)
              end

          structure InterfaceParser =
          struct
          fun parseInterface sysParam (source : parseSource) =
              let 
                  val (initialSource, initialParseContext) =
                      makeInterfaceParseSourceAndParseContext
                          sysParam
                          source
                          InterfaceParser.errorToString
                          InterfaceParser.createContext
                          
                  fun processInterface source parseContext =
                      let
                          fun parseInterface parseContext =
                              (SOME(InterfaceParser.parse parseContext))
                              handle InterfaceParser.EndOfParse => NONE
                                   | exn => raise exn
                      in
                          case (parseInterface parseContext) of
                              NONE => raise Control.Bug "non interface"
                            | SOME(parseResult, newParseContext) =>
                              case (parseInterface newParseContext) of 
                                  NONE => parseResult
                                | SOME _ => raise Control.Bug "interface parsing is not complete" 
                      end

                  val interface = 
                      processInterface initialSource initialParseContext
                      handle exn => (Top.errorHandler sysParam exn;
                                     (Absyn.EMPTYNAMESPACE, Absyn.SPECEMPTY, Loc.noloc))
              in
                  interface
              end
          end

          structure CodeParser =
          struct
          fun parseCode sysParam (parseSource : parseSource) =
              let 
                  val parseContext =
                      Parser.createContext {isPrelude = false,
                                            sourceName = #fileName parseSource,
                                            onError = (Top.printError sysParam) o Parser.errorToString,
                                            getLine = fn n => (#getLine (#stream parseSource)) (),
                                            withPrompt = false,
                                            print = print}

                  fun generateParseSourceAndContext (parseSource : parseSource) fileName loc = 
                      let
                          val currentBaseDirectory = #getBaseDirectory parseSource ()
                          val absoluteFilePath =
                              PathResolver.resolve (#getVariable sysParam)
                                                   (#loadPathList sysParam)
                                                   currentBaseDirectory
                                                   fileName
                                                   handle exn => raise UE.UserErrors [(loc, UE.Error, exn)]
                          val baseDirectory = #dir(PU.splitDirFile absoluteFilePath)
                          val newParseSource = {getBaseDirectory = fn () => baseDirectory,
                                                fileName = fileName,
                                                stream = FileChannel.openIn {fileName = absoluteFilePath}}
                      in
                          (newParseSource,
                           Parser.createContext
                               {
                                sourceName = fileName,
                                onError = (Top.printError sysParam) o Parser.errorToString,
                                getLine = fn n => (#getLine (#stream newParseSource)) (),
                                isPrelude = false,
                                withPrompt = false,
                                print = print
                          }) handle exn => ((#close (#stream newParseSource)) ();
                                            raise exn)
                      end

                  fun processFile parseSource parseContext =
                      let
                          val parseResultAndContextOpt = 
                              SOME(Parser.parse parseContext)
                              handle Parser.EndOfParse => NONE
                                   | exn => raise exn
                      in
                          case parseResultAndContextOpt of
                              NONE => 
                              [(Absyn.EMPTYNAMESPACE, nil, nil, Loc.noloc)]
                            | SOME(parseResult, continueParseContext) =>
                              case parseResult of
                                  Absyn.UNIT unit => 
                                  let
                                      val continueUnitList = processFile parseSource continueParseContext
                                  in
                                      [unit] @ continueUnitList
                                  end
                                | Absyn.USE (fileName, loc) => 
                                  let
                                      val (innerSource, innerParseContext) = 
                                          generateParseSourceAndContext parseSource fileName loc
                                      val useUnitList = processFile innerSource innerParseContext
                                      val continueUnitList = processFile parseSource continueParseContext
                                  in
                                      useUnitList @ continueUnitList
                                  end
                                | Absyn.USEOBJ (_, loc) => 
                                  raise UE.UserErrors [(loc, 
                                                        UE.Error, 
                                                        TopLevelError.UseObjOccurInLinkageUnit)]
                      end

                  fun mergeUnitList unitList = 
                      foldl (fn ((namespaceDec, importRequireDecs, topDecs, loc), 
                                 (isFirstUnit, (newNamespaceDec, newImportRequireDecs, newTopDecs))) =>
                                if isFirstUnit then
                                    (false, (namespaceDec, importRequireDecs, topDecs))
                                else
                                    case (namespaceDec, importRequireDecs) of
                                        (Absyn.EMPTYNAMESPACE, nil) =>
                                        (false, (newNamespaceDec, newImportRequireDecs, newTopDecs @ topDecs))
                                      | (Absyn.NAMESPACE (namespace, loc), _) => 
                                        raise UE.UserErrors 
                                                  [(loc, 
                                                    UE.Error, 
                                                    TopLevelError.NamespaceDecNotAtBeginning
                                                        (Absyn.longidToString namespace))]
                                      | (Absyn.ABSNAMESPACE (namespace, loc), _) =>
                                        raise UE.UserErrors
                                                  [(loc, 
                                                    UE.Error, 
                                                    TopLevelError.ABSNamespaceDecNotAtBeginning
                                                        (Absyn.longidToString namespace))]
                                      | (_, importRequireDecs) =>
                                        raise UE.UserErrors 
                                                  [(loc, 
                                                    UE.Error, 
                                                    TopLevelError.ImportOrRequireDecNotAtBeginning
                                                        importRequireDecs)]
                            )
                            (true, (Absyn.EMPTYNAMESPACE, nil, nil))
                            unitList
                            
                  val (_, unit as (_, _, topdecs)) = mergeUnitList (processFile parseSource parseContext)
              in
                  unit
              end
          end (* end structure CodeParser *)
    end (* end structure parser *)

    structure PhaseCompiler =
    struct
    (*********** interface compiler *****************************************)
    fun doInterfaceElaboration (basis : TB.basis) interface =
        let
            val (plInterface, varNameStamp, warnings) =
                Elaborator.elaborateInterface (#varNameStamp (#localStamps basis)) interface
            val newBasis = TB.setBasisLocalStamps 
                               basis 
                               (TB.setLocalStampsVarNameStamp (#localStamps basis)
                                                              varNameStamp)
            val _ = Top.printWarnings (#sysParam basis) warnings
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    Top.printIntermediateCodes
                        (#sysParam basis)
                        "Elaborated"
                        PatternCalcFormatter.plinterfaceToString
                        [plInterface]
                else ()
        in
            (plInterface, newBasis)
        end

    fun doInterfaceModuleCompilation (basis : TB.basis) plinterface =
        let
            val (plfinterface, externNameMap, varNameStamp) = 
                ModuleCompiler.compileInterface (#nameMap (#context basis))
                                                (#varNameStamp (#localStamps basis)) 
                                                plinterface
            val newBasis = 
                TB.extendBasisWithNameMapOfStaticInterface
                    (TB.setBasisLocalStamps 
                         basis 
                         (TB.setLocalStampsVarNameStamp (#localStamps basis)
                                                        varNameStamp))
                    externNameMap
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    Top.printIntermediateCodes (#sysParam basis)
                                               "Module Compilation"
                                               PatternCalcFlattenedFormatter.plfinterfaceToString
                                               [plfinterface]
                else ()
        in
            (plfinterface, externNameMap, newBasis)
        end

    fun doInterfaceSetTvars (basis : TB.basis) plfInterface =
        let
            val ptInterface = SetTVars.setInterface plfInterface
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    Top.printIntermediateCodes
                        (#sysParam basis)
                        "User Tyvar Processed"
                        PatternCalcWithTvarsFormatter.ptinterfaceToString
                        [ptInterface]
                else ()
        in
            ptInterface
        end

    fun doInterfaceTypeInference (basis : TB.basis) ptInterface =
        let
            val stamps = 
                {boundTypeVarIDStamp = #boundTypeVarIDStamp (#stamps basis),
                 freeTypeVarIDStamp = #freeTypeVarIDStamp (#localStamps basis),
                 exnTagIDKeyStamp = #exnTagIDKeyStamp (#stamps basis),
                 tyConIDKeyStamp = #tyConIDKeyStamp (#stamps basis),
                 varNameStamp = #varNameStamp (#localStamps basis)}
            val ((tyConIdSet, interfaceEnv), tpInterface, newStamps, warnings) =
                TypeInferencer.inferInterface (#topTypeContext (#context basis)) stamps ptInterface 
            val newGlobalStamps = 
                TB.setStampsTypeConstructorGlobalIDStamp
                    (TB.setStampsExceptionGlobalTagStamp
                         (TB.setStampsBoundTypeVarIDStamp (#stamps basis) (#boundTypeVarIDStamp newStamps))
                         (#exnTagIDKeyStamp newStamps))
                    (#tyConIDKeyStamp newStamps)
            val newLocalStamps =
                TB.setLocalStampsVarNameStamp (#localStamps basis) (#varNameStamp newStamps)
            val newBasis = 
                TB.extendBasisWithTypeEnvOfStaticInterface
                    (TB.setBasisLocalStamps (TB.setBasisStamps basis newGlobalStamps)  
                                            newLocalStamps)
                    interfaceEnv

            val _ = Top.printWarnings (#sysParam basis) warnings
            val _ =
                if !C.printTP andalso !C.switchTrace
                then
                    (
                     Top.printIntermediateCodes (#sysParam basis)
                                                "Statically evaluated"
                                                (TypedCalcFormatter.tpinterfaceToString [])
                                                [tpInterface];
                     Top.printError (#sysParam basis) "\nGenerated static bindings:\n";
                     Top.printError (#sysParam basis) (TypeFormatter.interfaceEnvToString interfaceEnv)
                    )
                else ()
        in
            (tpInterface, (tyConIdSet, interfaceEnv), newBasis)
        end

    fun doInterfaceUniqueIDAllocation (basis : TB.basis) interface =
        let
            val stamps = 
                {
                 localVarIDStamp = (#localVarIDStamp (#localStamps basis)),
                 externalVarIDKeyStamp = #externalVarIDKeyStamp (#stamps basis)
                }
            val (externalVarIDBasis, stamps) =
                UniqueIDAllocation.allocateExternalVarIDForInterface stamps interface
            val newBasis = 
                TB.extendBasisWithExternalVarIDBasisOfStaticInterface
                    (
                     TB.setBasisStamps
                         (TB.setBasisLocalStamps 
                              basis 
                              (TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis)
                                                                           (#localVarIDStamp stamps)))
                         (TB.setStampsExternalVarIDStamp (#stamps basis)
                                                         (#externalVarIDKeyStamp stamps))
                    )
                    externalVarIDBasis
                    
        in
            (externalVarIDBasis, newBasis)
        end

    fun compileInterface (absynInterface as (absynNamespace, spec, loc)) =  
        let
            val basis = 
                let
                    val (context, stamps) = 
                        Top.initializeContextAndStampsWithNamespace (absynNamespaceToNamespace absynNamespace)
                in
                    {
                     context = context,
                     stamps = stamps,
                     localContext = TB.initializeLocalContext(),
                     localStamps = TB.initializeLocalStamps(),
                     sysParam = initializeSysParam dummySession,
                     exportConstraint = NONE
                    }
                end
            val (plinterface, newBasis) = 
                doInterfaceElaboration basis absynInterface
            val (plfinterface, nameMap, newBasis) = 
                doInterfaceModuleCompilation newBasis plinterface 
            val ptInterface = doInterfaceSetTvars newBasis plfinterface
            val (tpInterface, (tyConIdSet, externalTypeEnv as (tyTypeEnv, varTypeEnv)), newBasis) = 
                doInterfaceTypeInference newBasis ptInterface
            val (externalVarIDBasis, newBasis) = 
                doInterfaceUniqueIDAllocation newBasis tpInterface
        in
            ({basicInterfaceNameMap = nameMap, 
              basicInterfaceSig = {boundTyConIdSet = tyConIdSet,
                                   env = externalTypeEnv}, 
              externalVarIDBasis = externalVarIDBasis} : LinkageUnit.staticInterface,
             newBasis)
        end

    (*************** code body compiler ******************************************)
    fun compileCode (basis : TB.basis) decs =
        let
            val (codeOpt, newBasis, contextUpdater) = Top.phasesCompile basis decs
            val exportContext = contextUpdater TB.emptyContext
        in
            (exportContext, newBasis, codeOpt)
        end

    end (* PhaseCompiler structure end *)

    structure UnitCompiler =
    struct
          fun compileImportRequires baseDir initialBasis impReqDecs =
              let
                  fun compileImportRequire (impreq, passingValues as (importStaticInterface, 
                                                                      requireStaticInterface, 
                                                                      newBasis)) =
                      case impreq of
                          Absyn.IMPORT (fileName, loc) =>
                          let
                              val absoluteFilePath = 
                                  resolveAbsolutePath (#sysParam initialBasis) baseDir fileName
                              val {dir, file} = OS.Path.splitDirFile absoluteFilePath
                              val stream = FileChannel.openIn {fileName = absoluteFilePath}
                              val abstractInterface as (namespaceList, spec, loc) =
                                  Parser.InterfaceParser.parseInterface
                                      (#sysParam initialBasis)
                                      {
                                       stream = stream,
                                       fileName = file,
                                       getBaseDirectory = fn () => dir
                                      }
                              val _ = #close stream ()
                              val (nonNamespacePrefixedStaticInterface, _) = 
                                  PhaseCompiler.compileInterface abstractInterface
                              val namespace = absynNamespaceToNamespace namespaceList
                              val namespacePrefixedStaticInterface = 
                                  LinkageUnit.injectStaticInterfaceInNamespace 
                                      nonNamespacePrefixedStaticInterface namespace
                              val newBasis =
                                  TopBasis.extendBasisWithStaticInterface
                                      (TopBasis.extendBasisWithStaticInterface
                                           newBasis nonNamespacePrefixedStaticInterface)
                                      namespacePrefixedStaticInterface
                          in
                              (LinkageUnit.extendStaticInterface {new = namespacePrefixedStaticInterface,
                                                                  old = importStaticInterface}, 
                               requireStaticInterface,
                               newBasis)
                          end
                        | Absyn.REQUIRE (fileName, loc) =>
                          let
                              val absoluteFilePath = 
                                  resolveAbsolutePath (#sysParam initialBasis) baseDir fileName
                              val {dir, file} = OS.Path.splitDirFile absoluteFilePath
                              val stream = FileChannel.openIn {fileName = absoluteFilePath}
                              val abstractInterface as (namespaceList, spec, loc) =
                                  Parser.InterfaceParser.parseInterface
                                      (#sysParam initialBasis)
                                      {
                                       stream = stream,
                                       fileName = file,
                                       getBaseDirectory = fn () => dir
                                      }
                              val _ = #close stream ()
                              val (nonNamespacePrefixedStaticInterface, _) = 
                                  PhaseCompiler.compileInterface abstractInterface
                              val namespace = absynNamespaceToNamespace namespaceList
                              val namespacePrefixedStaticInterface = 
                                  LinkageUnit.injectStaticInterfaceInNamespace 
                                      nonNamespacePrefixedStaticInterface namespace
                              val newBasis =
                                  TopBasis.extendBasisWithStaticInterface
                                      (TopBasis.extendBasisWithStaticInterface
                                           newBasis nonNamespacePrefixedStaticInterface)
                                      namespacePrefixedStaticInterface
                          in
                              (
                               importStaticInterface,
                               LinkageUnit.extendStaticInterface {new = namespacePrefixedStaticInterface,
                                                                  old = requireStaticInterface}, 
                               newBasis
                              )
                          end
                        | Absyn.EMPTYIMPREQ => passingValues
              in
                  foldl compileImportRequire 
                        (LinkageUnit.emptyStaticInterface, LinkageUnit.emptyStaticInterface, initialBasis) 
                        impReqDecs
              end

          fun compileUnit baseDir
                          (unitNamespace, impReqDecs, topdecs)
                          exportNamespaceStaticInterfaceOpt
                          unitFileName
            =
            let 
                val (context, stamps) = Top.initializeContextAndStampsWithNamespace unitNamespace
                val initialBasis = 
                    {
                     context = context : TB.context,
                     stamps = stamps,
                     localContext = TB.initializeLocalContext (),
                     localStamps = TB.initializeLocalStamps (),
                     sysParam = initializeSysParam dummySession,
                     exportConstraint = 
                     case exportNamespaceStaticInterfaceOpt of
                         NONE => NONE
                       | SOME (namespace, exportStaticInterface) => SOME exportStaticInterface
                    }: TB.basis
                val (importStaticInterface, requireStaticInterface, newBasis) =
                    compileImportRequires baseDir initialBasis impReqDecs
                val (exportContext, newBasis, objectOpt) = 
                    PhaseCompiler.compileCode newBasis topdecs
                val object = 
                    case objectOpt of
                        NONE => raise Control.Bug "object code is not generated!"
                      | SOME object => object
                val exportEnv =
                    ((#tyConEnv (#topTypeContext exportContext), 
                      #varEnv (#topTypeContext exportContext)),
                     #funEnv (#topTypeContext exportContext))
                val namespacePrefixedExportEnv = 
                    LinkageUnit.injectInterfaceEnvInNamespace exportEnv unitNamespace
            in 
                (
                 {
                  fileName = unitFileName,
                  import = #basicInterfaceSig importStaticInterface,
                  require = #basicInterfaceSig requireStaticInterface,
                  export = namespacePrefixedExportEnv,
                  object = object
                 } : LinkageUnit.linkageUnit,
                 newBasis
                )
            end 
    end (* end UnitCompiler structure *)

(*  A utility function collects and compiles all the .smi interface files under one specified path in sysParam.
    fun loadInterfaceBasis sysParam =
        let
            fun scanDirectory dir =
                let
                    val dirStream = (OS.FileSys.openDir dir)
                        handle OS.SysErr (msg, _) => 
                               raise TopLevelError.InvalidPath msg
                    fun readFileList fileList =
                        case OS.FileSys.readDir dirStream of
                            NONE => fileList
                          | SOME file => 
                            let
                                val fullFile = OS.Path.joinDirFile {dir = dir, file = file}
                                val newFileList = 
                                    if OS.FileSys.isLink fullFile
                                    then fileList
                                    else if OS.FileSys.isDir fullFile
                                    then fileList @ (scanDirectory fullFile) 
                                    else case (OS.Path.ext fullFile) of
                                             SOME "smi" => fileList @ [fullFile]
                                           | SOME x => fileList
                                           | NONE => fileList
                            in
                                readFileList newFileList
                            end
                    val dirFileList = readFileList nil
                    val _ = OS.FileSys.closeDir dirStream
                in
                    dirFileList
                end

            val interfaceFileList = 
                foldl (fn (loadPath, interfaceFileList) =>
                          interfaceFileList @ (scanDirectory loadPath))
                      nil
                      (#loadPathList sysParam)
                
            val ImportRequireBasisPair = 
                foldl (fn (interfaceFile, (importInterfaceBasis, requireInterfaceBasis)) =>
                          let
                              val {dir, file} = OS.Path.splitDirFile interfaceFile
                              val _ = print ("[loading interface:" ^ interfaceFile)
                              val stream = FileChannel.openIn {fileName = interfaceFile}
                              val abstractInterface as (namespace, spec, loc) =
                                  Parser.InterfaceParser.parseInterface
                                      sysParam
                                      {
                                       stream = stream,
                                       fileName = file,
                                       getBaseDirectory = fn () => dir
                                      }
                              val _ = #close stream ()
                              val (context, _) = 
                                  PhaseCompiler.compileInterface abstractInterface
                              val _ = print "...]\n"
                              val (newImportInterfaceBasis, newRequireInterfaceBasis) =
                                  case namespace of
                                      Absyn.NAMESPACE (namespaceList, loc) => 
                                      (Namespace.Map.insert(importInterfaceBasis,
                                                            Namespace.fromStringList namespaceList,
                                                            context),
                                       requireInterfaceBasis)
                                    | Absyn.ABSNAMESPACE (namespaceList, loc) =>
                                      (importInterfaceBasis,
                                       Namespace.Map.insert(requireInterfaceBasis,
                                                            Namespace.fromStringList namespaceList,
                                                            context)
                                      )
                                    | Absyn.EMPTYNAMESPACE =>
                                      let
                                          val loc = Loc.makePos {fileName = interfaceFile, 
                                                                 line = 0, 
                                                                 col = 0}
                                      in
                                          (
                                           TE.enqueueError ((loc, loc), TE.NamespaceIsNotDeclared);
                                           (importInterfaceBasis,requireInterfaceBasis)
                                          )
                                      end
                          in
                              (newImportInterfaceBasis,
                               newRequireInterfaceBasis)
                          end)
                      (Namespace.Map.empty, Namespace.Map.empty)
                      interfaceFileList
        in
            ImportRequireBasisPair
        end
*)
    fun compile fileName =
        let
            val _ = C.doCompileObj := true
            (**************** use Ueno san's new object code ***************) 
            val _ = C.targetPlatform := "newvm"
(*
            val _ = C.useAI := true
            val _ = C.newvm := true
*)
            (********** temparay switch off Control options  *******************)
            val _ = C.skipPrinter := true
            val _ = C.doInlining := false

            val _ = TE.initializeCompilationError ()
            
            val sysParam = initializeSysParam dummySession                          

            val currentBaseDirectory = OS.FileSys.fullPath(#dir(PathUtility.splitDirFile "./"))        
            val absoluteFilePath = resolveAbsolutePath sysParam currentBaseDirectory fileName
            val baseDirectory = #dir(PU.splitDirFile absoluteFilePath)

(*
            (* load namespace basis environment from the loadPath given by sysParam *)
            val (importInterfaceBasis, requireInterfaceBasis) = 
                loadInterfaceBasis (initializeSysParam dummySession)
*)
        in
            let
                (***** export interface file ********)
                local 
                    val absynExportInterfaceOpt = 
                        let
                            val expFileName = (removeFileNameExt fileName) ^ interfaceExt
                            val expFileChannelOpt = 
                                SOME (FileChannel.openIn {fileName = expFileName})
                                handle exn => NONE
                            val absynExportInterfaceOpt = 
                                Option.map (fn  expFileChannel =>
                                                (Parser.InterfaceParser.parseInterface
                                                     sysParam
                                                     {stream = expFileChannel, 
                                                      fileName = expFileName, 
                                                      getBaseDirectory = fn () => baseDirectory})
                                           )
                                           expFileChannelOpt
                            val _ = Option.map (fn x => (#close x) ())  expFileChannelOpt
                        in
                            absynExportInterfaceOpt
                        end
                in
                    val exportNamespaceStaticInterfaceOpt = 
                        Option.map (fn (absynExportInterface as (absynNamespace, spec, loc)) =>
                                       (
                                        absynNamespaceToNamespace absynNamespace, 
                                        (#1 (PhaseCompiler.compileInterface  absynExportInterface))
                                       )
                                   )
                                   absynExportInterfaceOpt
                end
                
                (****************** implemenation file  *******************************)
                val absynUnit as (namespaceDec, impReqDecs, code) = 
                    let
                        val impFile = FileChannel.openIn {fileName = fileName}
                            handle exn => raise UE.UserErrorsWithoutLoc [(UE.Error, exn)]
                        val absynUnit = Parser.CodeParser.parseCode 
                                            sysParam
                                            {stream = impFile, 
                                             fileName = fileName, 
                                             getBaseDirectory = fn () => baseDirectory}
                        val _ = #close impFile ()
                    in
                        absynUnit
                    end

                val shortFileName = getShortFileNameWithoutExt fileName
                val unitNamespace = 
                    case namespaceDec of
                        Absyn.NAMESPACE (namespaceList, loc) => 
                        let
                            val namespace = Namespace.fromStringList namespaceList
                        in
                            (*
                             * namespace of a linkage unit must be the same as that of export interface
                             *)
                            case exportNamespaceStaticInterfaceOpt of 
                                SOME (exportInterfaceNamespace , _) => 
                                if not (Namespace.isEqual(namespace, exportInterfaceNamespace))
                                then 
                                    (TE.enqueueError 
                                         (loc, 
                                          TE.NamesapceIsDifferentInInterfaceAndImplementationFile
                                              (namespace, exportInterfaceNamespace));
                                     namespace)
                                else namespace
                              | NONE => namespace
                        end
                      | Absyn.ABSNAMESPACE (namespaceList, loc) => 
                        (TE.enqueueError (loc, TE.NamespaceIsNotDeclared);
                         Namespace.fromStringList namespaceList)
                      | Absyn.EMPTYNAMESPACE => 
                        Namespace.defaultNamespace

                val (unit : LinkageUnit.linkageUnit, newBasis) = 
                    UnitCompiler.compileUnit baseDirectory
                                             (unitNamespace, impReqDecs, code)
                                             exportNamespaceStaticInterfaceOpt
                                             fileName
                                             
                val objectFileName = (getLongFileNameWithoutExt fileName) ^ objectExt
                val _ = if !TE.isAnyError then
                            raise UE.UserErrors (TE.getErrorsAndWarnings ())
                        else
                            LinkageUnitPickler.linkageUnitWriter unit objectFileName
            in
                ()
            end handle e => (Top.errorHandler sysParam e)
        end 
end
end
