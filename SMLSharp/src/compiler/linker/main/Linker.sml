(**
 * 
 * @copyright (c) 2008, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: Linker.sml,v 1.31 2008/03/25 02:39:44 bochao Exp $
 *)
structure Linker :
          sig
              val link : string list -> string -> unit
          end =
struct
      structure E = TypeInferenceError
      structure LE = LinkageError
      structure LU = LinkageUnit
      structure LUtil = LinkerUtils
      structure TCU = TypeContextUtils

      (* linkage unit list order is given by the programmer instead of the 
       * automatic dependency analysis.
       *)
      fun linkUnits unitList newObjName = 
          let
              val (linkedImport, linkedRequire, linkedExport, linkedObjOpt) = 
                  foldl (fn ((unit : LU.linkageUnit, 
                              (linkedImport, linkedRequire, linkedExport, linkedObjOpt))) =>
                            (LU.mergeInterfaceSig {new = #import unit, old = linkedImport},
                             LU.mergeInterfaceSig {new = #require unit, old = linkedRequire},
                             LU.mergeInterfaceEnv {new = #export unit, old = linkedExport},
                             case linkedObjOpt of
                                 NONE => SOME (#object unit)
                               | SOME linkedObj =>
                                 SOME (ObjectFileLinker.link (linkedObj, #object unit))
                            )
                        )
                        (LU.emptyInterfaceSig, LU.emptyInterfaceSig, Types.emptyInterfaceEnv, NONE)
                        unitList
              val newLinkedImport = 
                  LUtil.resolveTypeSigCheckEnv {import = linkedImport, export = linkedExport}
          in
              if LE.isError () 
              then NONE
              else SOME ( {fileName = newObjName,
                           import = newLinkedImport,
                           require = linkedRequire,
                           export = linkedExport,
                           object = case linkedObjOpt of
                                        NONE => raise Control.Bug "no linked object"
                                      | SOME obj => obj
                          } : LU.linkageUnit)
          end
      
          
      fun link objNames newObjName =
          let
              val _ = LE.initializeLinkError ()
                      
              (***object files ends with .smo **)
              val _ = LUtil.checkObjectFileNames (newObjName :: objNames)
              val linkageUnits = 
                  foldl (fn (objName, linkageUnits) =>
                            linkageUnits @ [LinkageUnitPickler.linkageUnitReader objName]
                        )
                        nil
                        objNames
              val newLinkageUnitOpt = linkUnits linkageUnits newObjName
          in
              if LE.isError ()
              then LE.handleError ()
              else case newLinkageUnitOpt of
                       NONE => raise Control.Bug "non-generated object"
                     | SOME linkageUnit =>
                       LinkageUnitPickler.linkageUnitWriter linkageUnit newObjName
          end
          
end (* end structure *)
