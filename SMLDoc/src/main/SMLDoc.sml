(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: SMLDoc.sml,v 1.6 2007/03/05 03:31:23 kiyoshiy Exp $
 *)
structure SMLDoc : SMLDOC =
struct

  (***************************************************************************)

  structure DGP = DocumentGenerationParameter

  (***************************************************************************)

  val preludeInfixes =
      [
        "::"
      ]

  val preludeTypes =
      [
        ("unit", ["General"]),
        ("int", ["Int"]),
        ("word", ["Word"]),
        ("real", ["Real"]),
        ("char", ["Char"]),
        ("string", ["String"]),
        ("substring", ["Substring"]),
        ("exn", ["General"]),
        ("array", ["Array"]),
        ("vector", ["Vector"]),
        ("ref", []),
        ("bool", []),
        ("option", ["Option"]),
        ("order", ["General"]),
        ("list", ["List"]),
        ("->", [])
      ]

  val preludeStructures =
      [
        ("General", ["General"]),
        ("Int", ["Int"]),
        ("Word", ["Word"]),
        ("Real", ["Real"]),
        ("Char", ["Char"]),
        ("String", ["String"]),
        ("Substring", ["Substring"]),
        ("Array", ["Array"]),
        ("Vector", ["Vector"]),
        ("Option", ["Option"]),
        ("List", ["List"])
      ]

  fun makeDocument
      (parameter
           as DGP.Parameter
           {directory, links, builtinTypes, builtinStructures, ...})
      fileNames
    =
      let
        val parseContext =
            (fn CTX => foldl Parser.addInfix CTX preludeInfixes)
            Parser.emptyContext

        (* ToDo : switch whether to show full path of prelude types *)
        val preludeTypes =
            map (fn (name, _) => (name, [])) preludeTypes
            @ (map (fn name => (name, [])) builtinTypes)
        val preludeStructures =
            preludeStructures
            @ (map (fn name => (name, [name])) builtinStructures)

        val preludeENVSet =
            ((fn ENVSet =>
                 foldl Elaborator.addExternalType ENVSet preludeTypes) o
             (fn ENVSet =>
                 foldl
                     Elaborator.addExternalStructure ENVSet preludeStructures))
            ENVSet.emptyENVSet
        val exteranlLinkedENVSet =
            foldl
            (fn ({URL, linkFile}, ENVSet) =>
                (
                  DGP.onProgress parameter ("reading linkFile:" ^ linkFile);
                  ExternalRefLinker.readLinkFile parameter URL linkFile ENVSet
                ))
            preludeENVSet
            links

        (* start processing *)
        val astUnits =
            map (Parser.parseFile parameter parseContext) fileNames

        val sortedUnits = DependencyAnalyzer.sort parameter astUnits

        val (ENVSet, units) =
            Elaborator.elaborate parameter exteranlLinkedENVSet sortedUnits
        val linkFileName = 
            directory ^ "/" ^ ExternalRefLinker.defaultModuleListFileName
      in
        DGP.onProgress parameter ("writing linkFile:" ^ linkFileName);
        ExternalRefLinker.writeLinkFile parameter linkFileName ENVSet;

        HTMLDocumentGenerator.generateDocument parameter units
      end
(*
        handle e =>
               let val message =
                       case e of
                         Parser.ParseError message => message
                       | ExternalRefLinker.ParseError message => message
                       | e => General.exnMessage e
               in TextIO.output (TextIO.stdErr, message) end
*)

  (***************************************************************************)

end
