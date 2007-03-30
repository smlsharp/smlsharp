(**
 * Module compilation environments.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: PathEnv.sml,v 1.45 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure PathEnv = 
struct
  local
    open Types TypedFlatCalc
    structure P = Path
    structure ITC =  InitialTypeContext
    structure TO = TopObject
  in

    datatype pathVarItem = 
             TopItem of (path * string) * TO.globalIndex * ty
           | CurItem of (path * string) * id * ty * loc

    datatype  pathStrEnvEntry = PATHAUX of pathEnv
    withtype pathVarEnv = pathVarItem SEnv.map
    and pathStrEnv = pathStrEnvEntry SEnv.map
    and pathEnv = pathVarEnv * pathStrEnv 
    and pathFunEnv = 
        (
         pathStrEnv *              (* formal structure argument environment for functor *)
         pathEnv *                 (* functor body environment *)
         tfpdecl list              (* body declarations *)
         ) SEnv.map 

    and pathBasis =  pathFunEnv * pathEnv 

    type topPathBasis = pathFunEnv * pathStrEnv

    val emptyPathVarEnv = SEnv.empty : pathVarEnv
    val emptyPathStrEnv = SEnv.empty : pathStrEnvEntry SEnv.map
    val emptyPathEnv = (SEnv.empty,SEnv.empty) : pathEnv
    val emptyPathFunEnv = SEnv.empty : pathFunEnv
    val emptyPathBasis = (emptyPathFunEnv, emptyPathEnv) : pathBasis
    val emptyTopPathBasis = (emptyPathFunEnv,emptyPathStrEnv) : topPathBasis

    (****  For functor template instantiation *****)
    (* instantiate hole id with actual id *)
    type pathHoleIdEnv = pathVarItem ID.Map.map
    (* refresh bounded id inside functor 
     *   functor F(A : S) =
     *    struct
     *       val x[id = 1] = true  
     *       ....
     *    end
     * Each functor application refresh id of x to reflect
     * the functor generativity.
     **)
    type pathIdEnv = 
         (
          string *  (* displayName for debugging *)
          id        (* unique id *)
          ) ID.Map.map
    val emptyPathHoleIdEnv = ID.Map.empty : pathHoleIdEnv
    val emptyPathIdEnv = ID.Map.empty : pathIdEnv
                               


    (************ prefix manipulation*********)
    val pathbreaker = "."
                           
    fun hideHiddenStructures prefix =
        P.hideLocalizedConstrainedStructure 
          (P.hideTopStructure prefix)
        
    fun pathVarToString (pathVar as (prefix,string)) =
        let
            val prefix = hideHiddenStructures prefix
        in
          case prefix of
            NilPath => string
          | _ => (P.pathToString prefix) ^ pathbreaker ^ string
        end

    fun prefixToFullString prefix =
        let 
          fun pathcvt p s =
              case p of
                NilPath => s
              | PStructure(id,name,NilPath) => (s^name^"("^ ID.toString(id)^")")
              | PStructure(id,name,path) => pathcvt path (s^name^"("^ID.toString(id)^")"^pathbreaker);
        in 
          pathcvt prefix "" 
        end
          
    fun pathVarToFullString (pathVar as (prefix,string)) =
        let
          val prefix = P.hideTopStructure prefix
        in
            case prefix of
              NilPath => string
            | _ => (prefixToFullString prefix) ^ pathbreaker ^ string
        end
          
    fun addPrefix prefix (id, name) = Path.appendPath (prefix, id, name)
    fun joinPrefix prefix1 prefix2 =
        case prefix1 of
          NilPath => prefix2
        | PStructure(id, name, path) => PStructure(id, name, joinPrefix path prefix2)
    fun getTailPrefix prefix =
        case prefix of
          NilPath => NilPath
        | PStructure(_,_,tail) => tail

                                        
    fun getIdFromCurItem item =
        case item of
          TopItem (pathVar, _, _) => 
          raise Control.Bug ("topItem " ^ pathVarToString(pathVar) ^ "contains no ident")
        | CurItem (pathVar, id, ty, loc) => id

    fun getPathVarFromItem item =
        case item of
          TopItem (pathVar, _, _) => pathVar
        | CurItem (pathVar,_,_,_) => pathVar

    fun getIndexFromTopItem item =
        case item of
          TopItem (_, index, _) => index
        | CurItem _ => raise Control.Bug "getIndexFrom Current Item"

    fun lookupPathIdEnv (idEnv, id) = ID.Map.find(idEnv, id)
                                      
    fun lookupPathHoleIdEnv (idEnv, id) = ID.Map.find(idEnv, id)
                                          
    fun mergePathHoleIdEnv (newPathHoleIdEnv, oldPathHoleIdEnv) =
        ID.Map.unionWith #1 (newPathHoleIdEnv, oldPathHoleIdEnv)
        
    fun mergePathIdEnv (newPathIdEnv, oldPathIdEnv) =
        ID.Map.unionWith #1 (newPathIdEnv, oldPathIdEnv)
        
    fun lookupVarInPathBasis (pathBasis, path,varName) =
        let
          val (funEnv, pathEnv) = pathBasis
          fun lookup NilPath (pathVarEnv,pathStrEnv) = 
              (case SEnv.find(pathVarEnv,varName) of
                 NONE => NONE
               | SOME name =>SOME(name))
            | lookup (PStructure(strid,strName,pstructure)) (pathVarEnv,pathStrEnv) =
              (case SEnv.find(pathStrEnv,strName) of 
                 NONE => NONE
               | SOME(PATHAUX E) =>lookup pstructure E)
        in 
          lookup path pathEnv 
        end
          
    fun lookupVarInPathVarEnv (pathVarEnv,var) =
        let
          val pathinfo = 
              case SEnv.find(pathVarEnv,var) of
                NONE => raise Control.Bug (var^" undefined in pathVarEnv")
              | SOME pathinfo => pathinfo
        in
          pathinfo
        end
          
    fun lookupPathStrEnvInPathBasis (pathBasis,path) = 
        let 
          val (funEnv,(pathVarEnv,pathStrEnv)) = pathBasis
          fun lookup NilPath _ = raise Control.Bug "NilPath in lookupPathStrEnvInPathBasis"
            | lookup (PStructure(strid,strName,NilPath)) pathStrEnv = 
              (case (SEnv.find(pathStrEnv,strName)) of
                 NONE => NONE
               | SOME(PATHAUX E) => SOME E)
            | lookup (PStructure(strid,strName,pstructure)) pathStrEnv = 
              (case SEnv.find(pathStrEnv,strName) of 
                 NONE => NONE 
               | SOME(PATHAUX E) =>lookup pstructure (#2 E))
        in 
          lookup path pathStrEnv 
        end

    fun lookupVarInTopPathBasis (topPathBasis,path,varName) =
        let
          val (funEnv,topPathEnv) = topPathBasis
          fun lookup NilPath _ = 
               (print varName;
                print "\n";
                raise Control.Bug "NilPath in lookupVarInTopPathBasis"
               )
            | lookup (PStructure(strid,strName,pstructure)) pathStrEnv =
              (
               case SEnv.find(pathStrEnv,strName) of 
                 NONE => NONE
               | SOME(PATHAUX (pathVarEnv,pathStrEnv)) =>
                 case pstructure of
                   NilPath => SEnv.find(pathVarEnv,varName)
                 | _  => lookup pstructure pathStrEnv
                         )
        in  
          lookup path topPathEnv 
        end 
          
    fun lookupPathStrEnvInTopPathBasis (topPathBasis,path) = 
        let 
          val (funEnv, topPathEnv) = topPathBasis
          fun lookup NilPath _ = raise Control.Bug "NilPath in lookupPathStrEnvInTopPathEnv"
            | lookup (PStructure(strid,strName,NilPath)) pathStrEnv = 
              (case (SEnv.find(pathStrEnv,strName)) of
                 NONE => NONE
               | SOME(PATHAUX E) => SOME E)
            | lookup (PStructure(strid, strName, pstructure)) pathStrEnv = 
              (case SEnv.find(pathStrEnv,strName) of 
                 NONE => NONE 
               | SOME(PATHAUX E) =>lookup pstructure (#2 E))
        in 
          lookup path topPathEnv 
        end
          
    fun lookupFunctorInPathBasis (pathBasis,funid) =
        let
          val (funEnv,pathEnv) = pathBasis
        in
          SEnv.find(funEnv,funid)
        end

    fun lookupFunctorInTopPathBasis (topPathBasis,funid) =
        let
          val (funEnv,topPathEnv) = topPathBasis
        in
          SEnv.find(funEnv,funid)
        end
          
    fun isGlobalPath path =
        case path of
          Path.PStructure(strId, _, _) => strId = Path.topStrID
        | _ => false

    fun lookupVar (topPathBasis,pathBasis,path,varName) =
        case lookupVarInPathBasis (pathBasis,path,varName) of
            SOME (pathinfo) => SOME pathinfo
          | NONE => 
            ( case lookupVarInTopPathBasis (topPathBasis,path,varName) of
                SOME pathinfo => SOME pathinfo
              | NONE => NONE
            )

    fun lookupPathStrEnv (topPathBasis,pathBasis,path) =
        case lookupPathStrEnvInPathBasis (pathBasis,path) of
          SOME strInfo => SOME strInfo
        | NONE => lookupPathStrEnvInTopPathBasis (topPathBasis,path) 

    fun lookupFunctor (topPathBasis,pathBasis,funid) =
        case lookupFunctorInPathBasis (pathBasis,funid) of
          SOME funenv => SOME funenv
        | NONE =>
          (
           case lookupFunctorInTopPathBasis (topPathBasis,funid) of
             SOME funenv => SOME funenv
           | NONE => NONE
          )
          
    fun mergePathEnv {newPathEnv = pathEnv1 : pathEnv, 
                      oldPathEnv = pathEnv2 : pathEnv} =
        (
          SEnv.unionWith #1 (#1 pathEnv1,#1 pathEnv2),
          SEnv.unionWith #1 (#2 pathEnv1,#2 pathEnv2)
        )

    fun mergePathVarEnv {newPathVarEnv = pathVarEnv1, oldPathVarEnv = pathVarEnv2} =
        SEnv.unionWith #1 (pathVarEnv1, pathVarEnv2)

    fun unionPathVarEnv (pathVarEnv1, pathVarEnv2) =
        SEnv.unionWith (fn _ => raise Control.Bug ("duplicate entry in PathVarEnv"))
                       (pathVarEnv1, pathVarEnv2)

    fun mergePathBasis { newPathBasis = pathBasis1 : pathBasis,
                         oldPathBasis = pathBasis2 : pathBasis } =
        ( 
         SEnv.unionWith #1 (#1 pathBasis1, #1 pathBasis2),
         (
          SEnv.unionWith #1 (#1 (#2 pathBasis1), #1 (#2 pathBasis2)),
          SEnv.unionWith #1 (#2 (#2 pathBasis1), #2 (#2 pathBasis2))
          )
         )

    fun injectPathVarEnvToTop pathVarEnv =
        SEnv.map (fn (TopItem ((strPath, name), index, ty)) => 
                     if isGlobalPath strPath then 
                       TopItem ((strPath, name), index, ty)
                     else 
                       TopItem((PStructure(Path.topStrID, Path.topStrName, strPath),name), index, ty)
                   | CurItem _ => raise Control.Bug "extendTopPathBasis with CurrItem"
                 )
                 pathVarEnv

    fun injectPathStrEnvToTop pathStrEnv =
        SEnv.map (
                  fn (PATHAUX(pathVarEnv,pathStrEnv)) =>
                     PATHAUX(
                             injectPathVarEnvToTop pathVarEnv,
                             injectPathStrEnvToTop pathStrEnv
                             )
                     )
                 pathStrEnv

    fun extendPathStrEnvEntry ((PATHAUX(ve1,se1)),(PATHAUX(ve2,se2))) =
        (
         PATHAUX(
                 SEnv.unionWith #1 (ve1,ve2),
                 SEnv.unionWith #1 (se1,se2)
                 )
         )
        
    fun extendPathBasisWithPathEnv {
                                    pathBasis = (funEnv,topPathEnv),
                                    pathEnv = pathEnv
                                    }
        =
        (
         funEnv, mergePathEnv { 
                               newPathEnv = pathEnv,
                               oldPathEnv = topPathEnv
                               }
        )

    fun extendTopPathEnvWithPathEnv { 
                                     topPathEnv = topPathEnv,
                                     pathEnv = (pathVarEnv,pathStrEnv)
                                     } 
        =
        let
          val newTopPathEnv = SEnv.singleton(
                                             Path.topStrName,
                                             PATHAUX(
                                                     injectPathVarEnvToTop pathVarEnv,
                                                     injectPathStrEnvToTop pathStrEnv
                                                     )
                                             )
        in
          SEnv.unionWith extendPathStrEnvEntry (newTopPathEnv,topPathEnv)
        end

    fun extendTopPathBasisWithPathBasis {
                                         topPathBasis = (topFunEnv,topPathEnv),
                                         pathBasis = (funEnv,pathEnv)
                                         } 
        =
        let
        val newTopFunEnv = SEnv.unionWith #1 (funEnv, topFunEnv)
        val newTopPathEnv = extendTopPathEnvWithPathEnv {
                                                         topPathEnv = topPathEnv,
                                                         pathEnv = pathEnv
                                                         }
        in
          (newTopFunEnv,newTopPathEnv)
        end

    fun liftUpPathVarEnvToTop pathVarEnv indexMap =
        SEnv.map (fn (CurItem (pathVar, id, ty, loc)) =>
                     let
                       val index = 
                           case ID.Map.find(indexMap, id) of
                             SOME (displayName, index) => index
                           | NONE => 
                             raise Control.Bug (pathVarToString(pathVar)^" is not allocated")
                     in
                       TopItem (pathVar, index, ty)
                     end
                   | TopItem item => TopItem item
                 )
                 pathVarEnv

    fun liftUpPathStrEnvToTop pathStrEnv indexMap =
        SEnv.map (fn (PATHAUX (subPathVarEnv, subPathStrEnv)) =>
                     let
                       val newSubPathVarEnv = 
                           liftUpPathVarEnvToTop subPathVarEnv indexMap
                       val newSubPathStrEnv = 
                           liftUpPathStrEnvToTop subPathStrEnv indexMap
                     in
                       PATHAUX (newSubPathVarEnv, newSubPathStrEnv)
                     end)
                 pathStrEnv

    fun liftUpPathEnvToTop pathEnv indexMap =
        let
          val (pathVarEnv, pathStrEnv) = pathEnv
        in
          (liftUpPathVarEnvToTop pathVarEnv indexMap,
           liftUpPathStrEnvToTop pathStrEnv indexMap)
        end

    fun liftUpPathBasisToTop pathBasis indexMap =
        let
          val (pathFunEnv, pathEnv) = pathBasis 
        in
          (pathFunEnv, liftUpPathEnvToTop pathEnv indexMap)
        end
  end
end
