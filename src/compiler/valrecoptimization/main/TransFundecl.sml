(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: TransFundecl.sml,v 1.5 2006/02/28 16:11:11 kiyoshiy Exp $
 *)
structure TransFundecl = struct
local

  structure VU = VALREC_Utils
  open PatternCalc

in

  fun transFunDecl loc (funPat as (PLPATID ([funId], patLoc)), ruleList as (([pat], exp)::_)) =
         (funPat, PLFNM(map (fn (patList,exp) => (patList, transExp exp)) ruleList, loc))
    | transFunDecl loc (funPat as (PLPATID ([funId], patLoc)), [(patList, exp)]) =
        let
          val funBody = 
            foldr (fn (pat, funBody) => PLFNM([([pat], funBody)], loc)) (transExp exp) patList
        in
          (funPat, funBody)
        end
    | transFunDecl loc (funPat as (PLPATID ([funId], patLoc)), ruleList as ((patList, exp)::_)) =
        let
          val funBody = 
            let
              fun listToTuple list =
                #2
                (foldl
                 (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
                 (1, nil)
                 list)
              val newNames = map (fn x => Vars.newPLVarName()) patList 
              val newVars = map (fn x => PLVAR([x], loc)) newNames
              val newVarPats = map (fn x => PLPATID([x], loc)) newNames
              val argRecord = PLRECORD (listToTuple newVars, loc)
              val funRules =
                map
                (fn (args, exp) =>
                 ([PLPATRECORD(false, listToTuple args, loc)], transExp exp)
                 )
                ruleList
            in
              foldr
              (fn (x, y) =>PLFNM([([x], y)], loc))
              (PLAPPM
               (
                PLFNM(funRules, loc),
                [argRecord],
                loc
                ))
              newVarPats
            end
      in
        (funPat, funBody)
      end
    | transFunDecl _ _ = raise Control.Bug "illegal fun decl "
       
  and transExp plexp = 
    case plexp of
      PLCONSTANT (constant, loc) => plexp
    | PLVAR (longid, loc) => plexp
    | PLTYPED (plexp,  ty, loc) => PLTYPED (transExp plexp,  ty, loc)  
    | PLAPPM (plexp, plexpList, loc) => PLAPPM (transExp plexp, map transExp plexpList, loc)
    | PLLET (pdeclList, plexpList, loc) =>
        PLLET(map transDecl pdeclList, map transExp plexpList, loc)
    | PLRECORD (stringPlexpList, loc) =>
        PLRECORD(map (fn (l,plexp) => (l, transExp plexp)) stringPlexpList,
                 loc)
    | PLRECORD_UPDATE (plexp, stringPlexpList, loc) =>
        PLRECORD_UPDATE (transExp plexp, 
                         map (fn (l, exp) => (l, transExp exp)) stringPlexpList, 
                         loc)
    | PLTUPLE (plexpList, loc) =>
        PLTUPLE (map transExp plexpList, loc)
    | PLRAISE (plexp, loc) => PLRAISE (transExp plexp, loc)
    | PLHANDLE (plexp, plpatPlexpList, loc) =>
        PLHANDLE (transExp plexp, map (fn (pat, exp) => (pat, transExp exp)) plpatPlexpList, 
                  loc)
    | PLFNM (plpatListPlexpList, loc) => 
        PLFNM (map (fn (patList, exp) => (patList, transExp exp)) plpatListPlexpList, 
               loc)
    | PLCASEM (plexpList,  plpatListPlexpList, caseKind, loc) =>
        PLCASEM (map transExp plexpList,  
                 map (fn (patList, exp) => (patList, transExp exp)) plpatListPlexpList, 
                 caseKind, 
                 loc)
    | PLRECORD_SELECTOR (string, loc) => plexp
    | PLSELECT (string, plexp, loc) =>
        PLSELECT (string, transExp plexp, loc)
    | PLSEQ (plexpList, loc) => PLSEQ (map transExp plexpList, loc)
    | PLCAST (plexp, loc) => PLCAST(transExp plexp, loc)

  and transDecl pdecl = 
    case pdecl of
      PDVAL (tvarList, plpatPlexpList, loc) =>
        PDVAL (tvarList, map (fn (pat,exp) => (pat, transExp exp)) plpatPlexpList, loc)
    | PDDECFUN (tvarList, plpatPlpatListPlexpListList, loc) =>
        PDVALREC(tvarList, map (transFunDecl loc) plpatPlpatListPlexpListList, loc)
    | PDNONRECFUN (tvarList, plpatPlpatListPlexpList, loc) =>
        PDVAL(tvarList, [transFunDecl loc plpatPlpatListPlexpList], loc)
    | PDVALREC (tvarList, plpatPlexpList, loc) => 
        PDVALREC (tvarList, map (fn (pat, exp) => (pat, transExp exp)) plpatPlexpList, loc)
    | PDVALRECGROUP (stringList, pdeclList, loc) => 
       PDVALRECGROUP (stringList, map transDecl pdeclList, loc)
    | PDTYPE _ => pdecl
    | PDDATATYPE _ => pdecl
    | PDREPLICATEDAT _ => pdecl
    | PDABSTYPE (datbinds, pdeclList, loc) =>  
       PDABSTYPE (datbinds, map transDecl pdeclList, loc)
    | PDEXD _ =>  pdecl
    | PDLOCALDEC (pdeclList1, pdeclList2, loc) => 
        PDLOCALDEC(map transDecl pdeclList1, map transDecl pdeclList2, loc)
    | PDOPEN _ => pdecl
    | PDINFIXDEC _ => pdecl
    | PDINFIXRDEC _ => pdecl
    | PDNONFIXDEC _ => pdecl
    | PDFFIVAL _ => pdecl
    | PDEMPTY => pdecl

 and transStrdec plstrdec =
   case plstrdec of
     PLCOREDEC (pdecl, loc) => PLCOREDEC(transDecl pdecl, loc)
   | PLSTRUCTBIND (stringPlstrexpList, loc) => 
       PLSTRUCTBIND(map (fn (s,strexp) => (s,transStrexp strexp)) stringPlstrexpList, loc)
   | PLSTRUCTLOCAL (plstrdecList1, plstrdecList2, loc) =>
       PLSTRUCTLOCAL(map transStrdec plstrdecList1,
                     map transStrdec plstrdecList2,
                     loc)
 and transStrexp plstrexp =
   case plstrexp of
     PLSTREXPBASIC (plstrdecList, loc) =>PLSTREXPBASIC(map transStrdec plstrdecList, loc)
   | PLSTRID (longid, loc) => plstrexp
   | PLSTRTRANCONSTRAINT (plstrexp, plsigexp, loc) => 
       PLSTRTRANCONSTRAINT(transStrexp plstrexp, plsigexp, loc)
   | PLSTROPAQCONSTRAINT (plstrexp, plsigexp, loc) =>
       PLSTROPAQCONSTRAINT (transStrexp plstrexp, plsigexp, loc)
   | PLFUNCTORAPP (string, plstrexp, loc) =>
       PLFUNCTORAPP (string, transStrexp plstrexp, loc)
   | PLSTRUCTLET  (plstrdecList, plstrexp, loc) =>
       PLSTRUCTLET(map transStrdec plstrdecList, 
                   transStrexp plstrexp,
                   loc)
 and transTopdec pltopdec = 
   case pltopdec of
     PLTOPDECSTR (plstrdec, loc) => PLTOPDECSTR (transStrdec plstrdec, loc)
   | PLTOPDECSIG (stringPlsigexplist, loc) => 
       PLTOPDECSIG (stringPlsigexplist, loc)
   | PLTOPDECFUN (stringStringPlsigexpPlstrexpLocList, loc) =>
       PLTOPDECFUN (map (fn (s1,s2,sigexp,strexp,loc) =>
                         (s1, s2, sigexp, transStrexp strexp, loc))
                    stringStringPlsigexpPlstrexpLocList, 
                    loc)
  fun transTopDeclList topdecList = map transTopdec topdecList
end
end
