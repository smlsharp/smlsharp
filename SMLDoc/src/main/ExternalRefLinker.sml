(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ExternalRefLinker.sml,v 1.5 2007/09/19 05:28:55 matsu Exp $
 *)
structure ExternalRefLinker : EXTERNALREF_LINKER =
struct

  (***************************************************************************)

  structure EA = ElaboratedAst
  structure ES = ENVSet
  structure LF = LinkFile
  structure U = Utility
  structure DGP = DocumentGenerationParameter

  val defaultModuleListFileName = "module-list"

  local

    structure LinkFileLrVals =
    LinkFileLrValsFun(structure Token = LrParser.Token)
    structure LinkFileLexer =
    LinkFileLexFun(structure Tokens = LinkFileLrVals.Tokens)
    structure LinkFileParser =
    JoinWithArg(structure ParserData = LinkFileLrVals.ParserData
	        structure Lex = LinkFileLexer
	        structure LrParser = LrParser)

    (*************************************************************************)

    fun parseLinkFile parameter fileName =
        let
          type pos = int

          val sourceStream = TextIO.openIn fileName
          val parserOperations = ParserUtil.PositionMap.create fileName

          fun onParseError arg =
              DGP.error parameter (#makeMessage parserOperations arg)

          val initialArg =
              {
                comLevel = ref 0,
                commonOperations = parserOperations,
                error = onParseError,
                stringStart = ref 0
              }

          fun getLine length = case TextIO.inputLine sourceStream of NONE => ""
								   | SOME s => s
          val lexer = LinkFileParser.makeLexer getLine initialArg

          val (items, _) =
              LinkFileParser.parse (0, lexer, onParseError, ())
              handle e => (TextIO.closeIn sourceStream; raise e)
        in
          TextIO.closeIn sourceStream; (items, parserOperations)
        end

    structure UpdatableENVSet =
    struct
    (* In the list, elements are ordered in reverse of delcared order. *)
    datatype ENVSet =
             UENVSet of
             {
               moduleENV :
               (EA.moduleType * string * EA.moduleReference * ENVSet) list ref,
               typeENV : (string * EA.moduleReference) list ref,
               valENV : string list ref,
               exceptionENV : (string * EA.moduleReference) list ref
             }
    fun toENVSet
        (UENVSet
         {
           moduleENV = ref modules,
           typeENV = ref types,
           valENV = ref vals,
           exceptionENV = ref exceptions
         }) =
        let
          (* early declared elements are bound before. *)
          val moduleAdded =
              foldr
              (fn ((moduleType, name, reference, env), ENVSet) =>
                  ES.bindModule
                      ENVSet moduleType (name, reference, toENVSet env))
              ES.emptyENVSet
              modules
          val typeAdded =
              foldr
              (fn ((name, moduleReference), ENVSet) =>
                  ES.bindType ENVSet (name, moduleReference))
              moduleAdded
              types
          val valAdded =
              foldr
              (fn (name, ENVSet) => ES.bindVal ENVSet (name, NONE))
              typeAdded
              vals
          val exceptionAdded =
              foldr
              (fn ((name, moduleReference), ENVSet) =>
                  ES.bindException ENVSet (name, moduleReference))
              valAdded
              exceptions
        in exceptionAdded end
    fun fromENVSet
        (ES.ENVSet
         {
           valENV,
           exceptionENV,
           typeENV,
           structureENV,
           signatureENV,
           functorENV,
           functorSignatureENV,
           ...
         }) =
        let
          (* CAUTION : order of elements in UES is same with ES. *)
          val modules = ref []
          fun addModule moduleType (name, reference, ENVSet) =
              modules :=
              (moduleType, name, reference, fromENVSet ENVSet) :: (!modules)
          val types = ref []
          fun addType (name, moduleReference) =
              types := (name, moduleReference) :: (!types)
          val vals = ref []
          fun addVal (name, _) = vals := name :: (!vals)
          val exceptions = ref []
          fun addException (name, moduleReference) =
              exceptions := (name, moduleReference) :: (!exceptions)
        in
          app (addModule EA.STRUCTURE) (List.rev structureENV);
          app (addModule EA.SIGNATURE) (List.rev signatureENV);
          app (addModule EA.FUNCTOR) (List.rev functorENV);
          app (addModule EA.FUNCTORSIGNATURE) (List.rev functorSignatureENV);
          app addType (List.rev typeENV);
          app addVal (List.rev valENV);
          app addException (List.rev exceptionENV);
          UENVSet
          {
            moduleENV = modules,
            typeENV = types,
            valENV = vals,
            exceptionENV = exceptions
          }
        end
        
    fun createENVSet () =
        UENVSet
        {
          moduleENV = ref [],
          typeENV = ref [],
          valENV = ref [],
          exceptionENV = ref []
        }
    fun bindModule (UENVSet{moduleENV, ...}) entry =
        moduleENV := entry :: (!moduleENV)
    fun bindType (UENVSet{typeENV, ...}) entry = typeENV := entry :: (!typeENV)
    fun bindVal (UENVSet{valENV, ...}) entry = valENV := entry :: (!valENV)
    fun bindException (UENVSet{exceptionENV, ...}) entry =
        exceptionENV := entry :: (!exceptionENV)
    fun getModuleEntryOfFQN
            (UENVSet{moduleENV, ...}) ((moduleType, name)::FQNTail) =
        (case
           List.find
           (fn entry => moduleType = #1 entry andalso name = #2 entry)
           (!moduleENV)
          of
           NONE => NONE
         | SOME(entry as (_, _, _, subENVSet)) =>
           if List.null FQNTail
           then SOME entry
           else getModuleEntryOfFQN subENVSet FQNTail)
        | getModuleEntryOfFQN _ [] =
          raise
            Fail
            "BUG: ExternalRefLinker.getModuleEntryOfFQN receive empty list."
    end

    structure UES = UpdatableENVSet
    fun buildENVSet baseURL topENVSet parentENVSet parentFQN item =
        case item of
          (LF.ModuleDefine(arc as (moduleType, name), subModules)) =>
          let
            val currentFQN = parentFQN @ [arc]
            (* Items in subModules are sorted in declaration order. *)
            val ENVSet = UES.createENVSet ()
          in
            app
            (buildENVSet baseURL topENVSet ENVSet currentFQN)
            subModules;
            UES.bindModule
            parentENVSet
            (moduleType, name, EA.ExternalRef(currentFQN, baseURL), ENVSet)
          end
        | (LF.ModuleReplica(arc as (moduleType, name), moduleFQN)) =>
          let
            val currentFQN = parentFQN @ [arc]
            val (reference, ENVSet) =
                case UES.getModuleEntryOfFQN topENVSet moduleFQN of
                  NONE =>
                  (
                    EA.UnknownRef(EA.moduleFQNToPath currentFQN),
                    UES.createENVSet ()
                  )
                | SOME(_, _, reference, ENVSet) => (reference, ENVSet)
          in
            UES.bindModule parentENVSet (moduleType, name, reference, ENVSet)
          end
        | (LF.TypeDefine(name)) =>
          UES.bindType parentENVSet (name, EA.ExternalRef(parentFQN, baseURL))
        | (LF.TypeReplica(name, moduleFQN)) =>
          let
            val moduleReference =
                case UES.getModuleEntryOfFQN topENVSet moduleFQN of
                  NONE => EA.UnknownRef(EA.moduleFQNToPath parentFQN)
                | SOME(_, _, reference, _) => reference
          in
            UES.bindType parentENVSet (name, moduleReference)
          end
        | (LF.ValDefine(name)) => UES.bindVal parentENVSet name
        | (LF.ExceptionDefine(name)) =>
          UES.bindException
              parentENVSet (name, EA.ExternalRef(parentFQN, baseURL))
  in
  fun readLinkFile parameter baseURL fileName ENVSet =
      let
        val (items, parserOperations) = parseLinkFile parameter fileName
        val topENVSet = UES.fromENVSet ENVSet
      in
        app (buildENVSet baseURL topENVSet topENVSet []) items;
        (UES.toENVSet topENVSet)
      end
  end

  (************************************************************)

  local
    fun getModuleTypeText moduleType =
        case moduleType of
          EA.STRUCTURE => "structure"
        | EA.SIGNATURE => "signature"
        | EA.FUNCTOR => "functor"
        | EA.FUNCTORSIGNATURE => "funsig"
        | _ =>
          raise
            Fail
            "BUG: ExternalRefLinker.getModuleTypeText receive unknown \
            \moduleType."
    fun arcToString (moduleType, name) =
        (getModuleTypeText moduleType) ^ " " ^ name
    fun FQNToString arcs = U.interleaveString " . " (map arcToString arcs)
    fun makeIndent FQN = String.concat (map (fn _ => " ") FQN)

  in
  fun writeLinkFile parameter fileName ENVSet =
      let
        val stream = TextIO.openOut fileName

        fun writeLine FQN strings =
            let
              val indent = makeIndent FQN
            in
              TextIO.output(stream, indent);
              app (fn s => TextIO.output(stream, s)) strings;
              TextIO.output(stream, "\n")
            end

        fun writeModuleItem parentFQN moduleType (name, reference, ENVSet) =
            let
              val currentFQN = parentFQN @ [(moduleType, name)]
              fun writeReplica FQN =
                  (* ToDo : parameter of functor is skipped. *)
                  if EA.isFQNOfFunctorParameter FQN
                  then ()
                  else
                    writeLine
                    parentFQN
                    [arcToString (moduleType, name), " => ", FQNToString FQN]
              fun writeDefine ENVSet =
                  (
                    writeLine parentFQN [arcToString (moduleType, name), "{"];
                    writeENVSet currentFQN ENVSet;
                    writeLine parentFQN ["}"]
                  )
            in
              case reference of
                EA.UnknownRef path => writeDefine ES.emptyENVSet
              | EA.ExternalRef(FQN, _) => writeReplica FQN
              | EA.ModuleRef(FQN, _) => 
                if FQN = currentFQN
                then writeDefine ENVSet
                else writeReplica FQN
            end
        and writeValItem parentFQN (name, _) =
            writeLine parentFQN ["val ", name]
        and writeExceptionItem parentFQN (name, _) =
            writeLine parentFQN ["exception ", name]
        and writeTypeItem parentFQN (name, moduleReference) =
            let
              fun writeReplica FQN =
                  (* ToDo : parameter of functor is skipped. *)
                  if EA.isFQNOfFunctorParameter FQN
                  then ()
                  else
                    writeLine
                        parentFQN ["type ", name, " => ", FQNToString FQN]
              fun writeDefine () = writeLine parentFQN ["type ", name]
            in
              case moduleReference of
                EA.UnknownRef path => writeDefine ()
              | EA.ExternalRef(FQN, _) => writeReplica FQN
              | EA.ModuleRef(FQN, _) => 
                if FQN = parentFQN then writeDefine () else writeReplica FQN
            end
        and writeENVSet
                currentFQN
                (ES.ENVSet
                 {
                   valENV,
                   exceptionENV,
                   typeENV,
                   structureENV,
                   signatureENV,
                   functorENV,
                   functorSignatureENV,
                   ...
                 }) =
                (
                  app
                  (writeModuleItem currentFQN EA.STRUCTURE)
                  (List.rev structureENV);
                  app
                  (writeModuleItem currentFQN EA.SIGNATURE)
                  (List.rev signatureENV);
                  app
                  (writeModuleItem currentFQN EA.FUNCTOR)
                  (List.rev functorENV);
                  app
                  (writeModuleItem currentFQN EA.FUNCTORSIGNATURE)
                  (List.rev functorSignatureENV);
                  app (writeTypeItem currentFQN) (List.rev typeENV);
                  app (writeValItem currentFQN) (List.rev valENV);
                  app (writeExceptionItem currentFQN) (List.rev exceptionENV)
                )
      in
        writeENVSet [] ENVSet;
        TextIO.closeOut stream
      end
  end

  (***************************************************************************)

end
