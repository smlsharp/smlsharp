(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: StructureLocalization.sml,v 1.6 2006/02/28 16:11:08 kiyoshiy Exp $
 *)

(* type instantiation for structure.
 * The following is the reason for introducing 'LOCALSTR                                          
 * structure A =
 *    struct
 *        structure A = struct fun g x = x end
 *        structure B = struct fun f x = x end
 *    end : sig structure B : sig val f : int -> int end end
 * Localized into: 
 * local
 *    structure A ('LOCALSTR) =
 *       struct
 *        structure A = struct fun g x = x end
 *        structure B = struct fun f x = x end
 *       end
 * in
 *    structure A =
 *       struct
 *           open A ('LOCALSTR)
     *           structure B = 
 *               struct
 *                  val f = A.B.f ('LOCAL-A.B.f) {int}  <-- A.B conflict with opened A
 *           end
 *       end
 * end
 * note: The bracket version is the current strategy.
 *)
 structure StructureLocalization =
  struct
  
  structure PT = PatternCalcWithTvars

  fun isConstrainedStrExp ptstrexp =
      case ptstrexp of
        PT.PTSTREXPBASIC _ => false
      | PT.PTSTRID _ => false
      | PT.PTSTRTRANCONSTRAINT (ptstrexp,_,_) => true
      | PT.PTSTROPAQCONSTRAINT (ptstrexp,_,_) => true
      | PT.PTFUNCTORAPP _ => false
      | PT.PTSTRUCTLET _ => false
      
  fun fetchLongStrId ptstrexp =
      case ptstrexp of
        PT.PTSTREXPBASIC _ => NONE
      | PT.PTSTRID (longid,_) => SOME longid
      | PT.PTSTRTRANCONSTRAINT (ptstrexp,_,_) => fetchLongStrId ptstrexp
      | PT.PTSTROPAQCONSTRAINT (ptstrexp,_,_) => fetchLongStrId ptstrexp
      | PT.PTFUNCTORAPP _ => NONE
      | PT.PTSTRUCTLET (_, ptstrexp, _) => fetchLongStrId ptstrexp

    val LOCALSTRID = Path.localizedConstrainedStrName
        
    fun id x = x
    fun localizePtstrdec ptstrdec =
         case ptstrdec of
           PT.PTCOREDEC _ => ptstrdec
         | PT.PTSTRUCTBIND (strbinds,loc) => 
           let
             val (localParts,inParts) = 
                 foldl (fn ((strName, ptstrexp), (localParts,inParts)) =>
                           let
                             val (localPartStrexp,holeFcn) = localizePtstrexp ptstrexp
                             val (localPart, inPart) =
                                 if isConstrainedStrExp ptstrexp then
                                   ([(strName, localPartStrexp)],
                                    [(strName,
                                      holeFcn (
                                               PT.PTSTREXPBASIC 
                                                 ([PT.PTCOREDEC (PT.PTOPEN ([[LOCALSTRID,strName]],loc),loc)],loc)
                                              )
                                      )
                                     ]
                                    )
                                 else
                                   (nil,[(strName,localPartStrexp)])
                           in
                             (localParts @ localPart,
                              inParts @ inPart)
                           end
                             )
                       (nil,nil)
                       strbinds
           in
             case localParts of
               nil => PT.PTSTRUCTBIND (inParts,loc)
             | _   => PT.PTSTRUCTLOCAL 
                        ([PT.PTSTRUCTBIND([(LOCALSTRID, 
                                            PT.PTSTREXPBASIC([PT.PTSTRUCTBIND(localParts,loc)],loc)
                                            )
                                           ],
                                          loc
                                          )
                          ],
                         [PT.PTSTRUCTBIND(inParts,loc)],
                                        loc)
           end
         | PT.PTSTRUCTLOCAL (ptstrdecs1, ptstrdecs2,loc) =>
           PT.PTSTRUCTLOCAL (map (fn x => localizePtstrdec x) ptstrdecs1,
                             map (fn x => localizePtstrdec x) ptstrdecs2,
                             loc) 

     and localizePtstrexp ptstrexp =
            case ptstrexp of
              PT.PTSTRTRANCONSTRAINT _ => localizeImpl ptstrexp id
            | PT.PTSTROPAQCONSTRAINT _ => localizeImpl ptstrexp id
            | PT.PTFUNCTORAPP (string, ptstrexp, loc) => 
              let
                val newPtstrexp = localizeToLetStrexp ptstrexp loc
              in
                (PT.PTFUNCTORAPP (string,  newPtstrexp, loc),
                 id)
              end
            | PT.PTSTRUCTLET  (ptstrdecs,ptstrexp,loc) =>
              let
                val newPtstrexp = localizeToLetStrexp ptstrexp loc
              in
                (PT.PTSTRUCTLET (map localizePtstrdec ptstrdecs ,
                                 newPtstrexp,
                                 loc),
                 id)
              end
            | PT.PTSTREXPBASIC (ptstrdecs,loc) =>
              (PT.PTSTREXPBASIC (map localizePtstrdec ptstrdecs ,
                                 loc),
               id)
            | PT.PTSTRID _ => (ptstrexp,id)

     and localizeImpl ptstrexp holeFcn =
            case ptstrexp of
              PT.PTSTREXPBASIC (ptstrdecs,loc) => 
              let
                val newPtstrdecs = map localizePtstrdec ptstrdecs 
              in
                (PT.PTSTREXPBASIC (newPtstrdecs,loc),holeFcn)
              end
            | PT.PTSTRID (longid,loc) => (ptstrexp, holeFcn)
            | PT.PTSTRTRANCONSTRAINT (ptstrexp,ptsigexp,loc) => 
              localizeImpl ptstrexp
                        (fn x => holeFcn (PT.PTSTRTRANCONSTRAINT (x,ptsigexp,loc)))
            | PT.PTSTROPAQCONSTRAINT (ptstrexp,ptsigexp,loc) => 
              localizeImpl ptstrexp
                        (fn x => holeFcn (PT.PTSTROPAQCONSTRAINT (x,ptsigexp,loc)))
            | PT.PTFUNCTORAPP (string, ptstrexp, loc) => 
              let
                val newPtstrexp = localizeToLetStrexp ptstrexp loc
              in
                (PT.PTFUNCTORAPP (string, newPtstrexp, loc),
                 holeFcn)
              end
            | PT.PTSTRUCTLET (ptstrdecs, ptstrexp, loc) => 
              let
                val ptstrdecs1 = map localizePtstrdec ptstrdecs
                val (newPtstrexp,holeFcn) = localizePtstrexp ptstrexp
              in
                (PT.PTSTRUCTLET(ptstrdecs1, newPtstrexp, loc),
                 holeFcn)
              end

     and localizeToLetStrexp ptstrexp loc =
            let
              val (newPtstrexp,holeFcn) = localizePtstrexp ptstrexp
              val longStrIdOpt = fetchLongStrId ptstrexp
              fun constructStrexp longid coreStrexp = 
                  foldr (fn (strid, strexp) =>
                            PT.PTSTREXPBASIC
                              ([PT.PTSTRUCTBIND ([(strid,strexp)],loc)],loc)
                              )
                        coreStrexp
                        longid
              val strLetExp = 
                  if not (isConstrainedStrExp ptstrexp) then
                    newPtstrexp
                  else
                    case longStrIdOpt of
                      NONE =>
                      PT.PTSTRUCTLET
                        (
                         [PT.PTSTRUCTBIND ([(LOCALSTRID,
                                             newPtstrexp)],
                                           loc)],
                         holeFcn (
                                PT.PTSTREXPBASIC
                                  ([
                                    PT.PTCOREDEC
                                      (PT.PTOPEN
                                         ([[LOCALSTRID]],
                                          loc),
                                         loc
                                         )
                                      ],
                                   loc)
                                  ),
                       loc
                       )
                  | SOME (longStrId : string list)=> 
                    let
                      val coreStrexp =
                          holeFcn (PT.PTSTREXPBASIC
                                     ([PT.PTCOREDEC (PT.PTOPEN ([longStrId],loc),loc)],
                                      loc)
                                  )
                    in
                      PT.PTSTRUCTLET
                        (
                         [PT.PTSTRUCTBIND ([(hd(longStrId),
                                             constructStrexp (tl(longStrId)) coreStrexp)],
                                           loc)],
                         PT.PTSTRID(longStrId,loc),
                         loc
                         )
                    end
            in
              strLetExp
            end

  end
