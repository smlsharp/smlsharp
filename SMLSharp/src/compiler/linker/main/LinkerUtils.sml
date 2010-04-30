(**
 * Linker Utilities
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: LinkerUtils.sml,v 1.39 2008/03/25 02:39:44 bochao Exp $
 *)
structure LinkerUtils =
struct
  local
      structure LE = LinkageError
      structure TCU = TypeContextUtils
      structure T = Types
      structure LU = LinkageUnit
  in
      fun checkObjectFileNames fileNames =
          app (fn fileName => 
                  if OS.Path.ext fileName = SOME "smo"  
                  then ()
                  else raise LE.IllegalObjectFileSuffix {fileName = fileName})
              fileNames

      fun equivalenceUnifyTyConIDTopTyConEnv {import : Types.topTyConEnv, export : Types.topTyConEnv} =
          SEnv.foldli (fn (externalTyConName, tyBindInfo, tyConIDSubst) =>
                          case SEnv.find(export, externalTyConName) of
                              NONE => tyConIDSubst
                            | SOME (T.TYCON {tyCon = {id = exportID,...}, ...}) =>
                              (case tyBindInfo of
                                   T.TYCON {tyCon = {id = importID, ...}, ...} =>
                                   TyConID.Map.insert(tyConIDSubst, importID, exportID)
                                 | _ => 
                                   (LE.enqueueError
                                        (Loc.noloc, 
                                         LE.InconsistentImportTypeConstructor {name = externalTyConName}
                                        );
                                    tyConIDSubst
                                   )
                              )
                            | SOME (T.TYSPEC {id = exportID, ...}) =>
                              (case tyBindInfo of
                                   T.TYSPEC {id = importID, ...} =>
                                   TyConID.Map.insert(tyConIDSubst, importID, exportID)
                                 |  _ =>
                                    (LE.enqueueError
                                         (Loc.noloc, 
                                          LE.InconsistentImportTypeConstructor {name = externalTyConName}
                                         );
                                     tyConIDSubst
                                    )
                              )
                            | SOME (T.TYOPAQUE _) => 
                              raise Control.Bug "opaque tybindinfo in interface"
                            | SOME (T.TYFUN _) => tyConIDSubst
                      )
                      TyConID.Map.empty
                      import

      fun equivalenceCheckTyBindInfo (name, import, export) = 
          case (import, export) of 
              (T.TYCON (import as {tyCon = importTyCon, datacon = importDatacon}) , 
               T.TYCON {tyCon = exportTyCon, datacon = exportDatacon}) =>
              (if #tyvars importTyCon = #tyvars exportTyCon andalso
                  TyConID.isEqual(#id importTyCon, #id exportTyCon) andalso
                  !(#eqKind importTyCon) = !(#eqKind exportTyCon) andalso
                  SignatureCheck.equivDatacon (importDatacon, exportDatacon) 
               then ()
               else (LE.enqueueError
                         (Loc.noloc, 
                          LE.InconsistentImportTypeConstructor {name = name}
                         );
                     ());
               T.TYCON import)
            | (T.TYFUN import, T.TYFUN export) =>
              (if (SignatureCheck.equivTyFcn (#tyargs import, #body import) (#tyargs export, #body export)) 
               then ()
               else (LE.enqueueError
                         (Loc.noloc, 
                          LE.InconsistentImportTypeConstructor {name = name}
                         );
                     ());
               T.TYFUN import)
            | (T.TYSPEC import, T.TYSPEC export) =>
              (if #tyvars import = #tyvars export andalso
                  TyConID.isEqual(#id import, #id export) andalso
                  (#eqKind import) = (#eqKind export) 
               then ()
               else (LE.enqueueError
                         (Loc.noloc, 
                          LE.InconsistentImportTypeConstructor {name = name}
                         );
                     ());
               T.TYSPEC import)              
            | _ => (LE.enqueueError
                        (Loc.noloc, 
                         LE.InconsistentImportTypeConstructor {name = name}
                        );
                    import)

      fun equivalenceCheckIdstate (name, import, export) = 
          case (import, export) of
              (T.VARID import, T.VARID export) =>
              (if SignatureCheck.equivTy (#ty import, #ty export) then ()
               else (LE.enqueueError
                         (Loc.noloc, 
                          LE.InconsistentImportValueIdentifier {name = name}
                         );
                     ());
               T.VARID import)
            | (T.CONID import, T.CONID export) =>
              (if SignatureCheck.equivTy (#ty import, #ty export) then ()
               else (LE.enqueueError
                         (Loc.noloc, 
                          LE.InconsistentImportValueIdentifier {name = name}
                         );
                     ());
               T.CONID import)
            | (T.EXNID import, T.EXNID export) =>
              (if SignatureCheck.equivTy (#ty import, #ty export) then ()
               else (LE.enqueueError
                         (Loc.noloc, 
                          LE.InconsistentImportDataConstructor {name = name}
                         );
                     ());
               T.EXNID import)
            | (T.PRIM _, _) => raise Control.Bug "PRIM in interface env"
            | ( _, T.PRIM _) => raise Control.Bug "PRIM in interface env"
            | (T.OPRIM _, _) => raise Control.Bug "OPRIM in interface env"
            | ( _, T.OPRIM _) => raise Control.Bug "OPRIM in interface env"
            | (T.RECFUNID _, _) => raise Control.Bug "RECFUNID in interface env"
            | (_, T.RECFUNID _) => raise Control.Bug "RECFUNID in interface env"
            | _ => 
              (
               (LE.enqueueError
                    (Loc.noloc, 
                     LE.InconsistentImportValueIdentifier {name = name}
                    );
                ());
               import)

      fun equivalenceCheckTyConEnv (importTyConEnv, exportTyConEnv) =
          SEnv.foldli (fn (tyConName, importTyBindInfo, importTyConEnv) =>
                          case SEnv.find(exportTyConEnv, tyConName) of
                              NONE => 
                              SEnv.insert(importTyConEnv, tyConName, importTyBindInfo)
                            | SOME exportTyBindInfo =>
                              (equivalenceCheckTyBindInfo (tyConName, importTyBindInfo, exportTyBindInfo);
                               importTyConEnv)
                      )
                      SEnv.empty
                      importTyConEnv

      fun equivalenceCheckVarEnv (importVarEnv, exportVarEnv) =
          SEnv.foldli (fn (varName, importIdstate, importVarEnv) =>
                          case SEnv.find(exportVarEnv, varName) of
                              NONE => SEnv.insert(importVarEnv, varName, importIdstate)
                            | SOME exportIdstate =>
                              (equivalenceCheckIdstate (varName, importIdstate, exportIdstate);
                               importVarEnv))
                      SEnv.empty
                      importVarEnv

      fun equivalenceCheckNPEnv (importEnv : Types.Env, exportEnv : Types.Env) =
          (equivalenceCheckTyConEnv (NameMap.NPEnvToSEnv (#1 importEnv), NameMap.NPEnvToSEnv (#1 exportEnv)),
           equivalenceCheckVarEnv (NameMap.NPEnvToSEnv (#2 importEnv), NameMap.NPEnvToSEnv (#2 exportEnv)))

      fun equivalenceCheckFunBindInfo
              ((importFunBindInfo : Types.funBindInfo), (exportFunBindInfo : Types.funBindInfo)) =
          let
              val importFunArgTyConIDSubst =
                  equivalenceUnifyTyConIDTopTyConEnv 
                      {
                       import = NameMap.NPEnvToSEnv (#1 (#argSigEnv (#functorSig importFunBindInfo))),
                       export = NameMap.NPEnvToSEnv (#1 (#argSigEnv ((#functorSig exportFunBindInfo))))
                      }

              val newImportFunArgEnv = 
                  TCU.substTyConIdInEnv importFunArgTyConIDSubst
                                        (#argSigEnv (#functorSig importFunBindInfo))

              val _ = equivalenceCheckNPEnv (#argSigEnv  (#functorSig importFunBindInfo),
                                             #argSigEnv  (#functorSig exportFunBindInfo))

              val importFunBodyTyConIDSubst = 
                  equivalenceUnifyTyConIDTopTyConEnv 
                      {
                       import = NameMap.NPEnvToSEnv (#1 (#2 (#body (#functorSig importFunBindInfo)))),
                       export = NameMap.NPEnvToSEnv (#1 (#2 (#body (#functorSig exportFunBindInfo))))
                      }

              val newImportFunBodyEnv = 
                  TCU.substTyConIdInEnv importFunArgTyConIDSubst
                                           (#2 (#body  (#functorSig importFunBindInfo)))

              val _ = equivalenceCheckNPEnv ((#2 (#body (#functorSig importFunBindInfo))),
                                             (#2 (#body (#functorSig exportFunBindInfo))))
          in
              ()
          end
          
      fun resolveTypeSigCheckEnv {import : LU.basicInterfaceSig, export : Types.interfaceEnv} =
          let
              val importTyConIDSubst =
                  equivalenceUnifyTyConIDTopTyConEnv 
                      {import = (#1 (#1 (#env import))) , 
                       export = #1 (#1 export)}
     
              val newImportBoundTyConIdSet = 
                  TyConID.Set.map (fn oldID => 
                                      case TyConID.Map.find (importTyConIDSubst, oldID) of
                                          NONE => oldID 
                                        | SOME newID => newID)
                                  (#boundTyConIdSet import)

              val newImportEnv = 
                  (
                   TCU.substTyConIdInTopEnv importTyConIDSubst (#1 (#env import)),
                   TCU.substTyConIdInFunEnv importTyConIDSubst (#2 (#env import))
                  )

              val newImportTyConEnv = 
                  equivalenceCheckTyConEnv (#1 (#1 newImportEnv), #1 (#1 export))

              val newImportVarEnv = 
                  equivalenceCheckVarEnv (#2 (#1 newImportEnv), #2 (#1 export))
                  
              val newImportFunEnv = 
                  SEnv.foldli (fn (funName, importFunBindInfo, importFunEnv) =>
                                  case SEnv.find(#2 export, funName) of
                                      NONE => 
                                      SEnv.insert(importFunEnv, funName, importFunBindInfo)
                                    | SOME exportFunBindInfo =>
                                      (equivalenceCheckFunBindInfo (importFunBindInfo, exportFunBindInfo);
                                       importFunEnv)
                              )
                              SEnv.empty
                              (#2 newImportEnv)
          in
              {boundTyConIdSet = newImportBoundTyConIdSet, 
               env = ((newImportTyConEnv, newImportVarEnv), newImportFunEnv)} : LU.basicInterfaceSig
          end
  end (* end local *)
end (* end structure *)
