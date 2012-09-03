(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: TransFundecl.sml,v 1.16.6.6 2010/01/29 06:41:34 hiro-en Exp $
 *)
structure TransFundecl : TRANS_FUNDECL = struct
local
  structure VU = VALREC_Utils
  open PatternCalcFlattened
  fun newVarName () = VarName.generate ()
in
  fun transFunDecl loc (funPat, ruleList as (([pat], exp)::_)) =
         (funPat, PLFFNM(map (fn (patList,exp) => (patList, transExp exp)) ruleList, loc))
    | transFunDecl loc (funPat, [(patList, exp)]) =
        let
          val funBody = 
            foldr (fn (pat, funBody) => PLFFNM([([pat], funBody)], loc)) (transExp exp) patList
        in
          (funPat, funBody)
        end
    | transFunDecl loc (funPat, ruleList as ((patList, exp)::_)) =
        let
          val funBody = 
            let
              fun listToTuple list =
                #2
                (foldl
                 (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
                 (1, nil)
                 list)
              val newNames = map (fn x => newVarName()) patList 
              val newVars = map (fn x => PLFVAR((x,Path.NilPath), loc)) newNames
              val newVarPats = map (fn x => PLFPATID((x, Path.NilPath), loc)) newNames
              val argRecord = PLFRECORD (listToTuple newVars, loc)
              val funRules =
                map
                (fn (args, exp) =>
                 ([PLFPATRECORD(false, listToTuple args, loc)], transExp exp)
                 )
                ruleList
            in
              foldr
              (fn (x, y) =>PLFFNM([([x], y)], loc))
              (PLFAPPM
               (
                PLFFNM(funRules, loc),
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
      PLFCONSTANT (constant, loc) => plexp
    | PLFGLOBALSYMBOL _ => plexp
    | PLFVAR (longid, loc) => plexp
    | PLFTYPED (plexp,  ty, loc) => PLFTYPED (transExp plexp,  ty, loc)  
    | PLFAPPM (plexp, plexpList, loc) => PLFAPPM (transExp plexp, map transExp plexpList, loc)
    | PLFLET (pdeclList, plexpList, loc) =>
        PLFLET(map transDecl pdeclList, map transExp plexpList, loc)
    | PLFRECORD (stringPlexpList, loc) =>
        PLFRECORD(map (fn (l,plexp) => (l, transExp plexp)) stringPlexpList,
                 loc)
    | PLFRECORD_UPDATE (plexp, stringPlexpList, loc) =>
        PLFRECORD_UPDATE (transExp plexp, 
                         map (fn (l, exp) => (l, transExp exp)) stringPlexpList, 
                         loc)
    | PLFTUPLE (plexpList, loc) =>
      PLFTUPLE (map transExp plexpList, loc)
    | PLFLIST (plexpList, loc) =>
        PLFLIST (map transExp plexpList, loc)
    | PLFRAISE (plexp, loc) => PLFRAISE (transExp plexp, loc)
    | PLFHANDLE (plexp, plpatPlexpList, loc) =>
        PLFHANDLE (transExp plexp, map (fn (pat, exp) => (pat, transExp exp)) plpatPlexpList, 
                  loc)
    | PLFFNM (plpatListPlexpList, loc) => 
        PLFFNM (map (fn (patList, exp) => (patList, transExp exp)) plpatListPlexpList, 
               loc)
    | PLFCASEM (plexpList,  plpatListPlexpList, caseKind, loc) =>
        PLFCASEM (map transExp plexpList,  
                 map (fn (patList, exp) => (patList, transExp exp)) plpatListPlexpList, 
                 caseKind, 
                 loc)
    | PLFRECORD_SELECTOR (string, loc) => plexp
    | PLFSELECT (string, plexp, loc) =>
        PLFSELECT (string, transExp plexp, loc)
    | PLFSEQ (plexpList, loc) => PLFSEQ (map transExp plexpList, loc)
    | PLFCAST (plexp, loc) => PLFCAST(transExp plexp, loc)
    | PLFFFIIMPORT (plexp, ty, loc) => PLFFFIIMPORT (transExp plexp, ty, loc)  
    | PLFFFIEXPORT (plexp, ty, loc) => PLFFFIEXPORT (transExp plexp, ty, loc)  
    | PLFFFIAPPLY (cconv, funExp, args, retTy, loc) =>
      PLFFFIAPPLY (cconv, transExp funExp,
                  map (fn PLFFFIARG (exp, ty, loc) =>
                          PLFFFIARG (transExp funExp, ty, loc)
                        | PLFFFIARGSIZEOF (ty, SOME exp, loc) =>
                          PLFFFIARGSIZEOF (ty, SOME (transExp exp), loc)
                        | PLFFFIARGSIZEOF (ty, NONE, loc) =>
                          PLFFFIARGSIZEOF (ty, NONE, loc))
                      args,
                  retTy, loc)
    | PLFSQLSERVER (str, schema, loc) =>
      PLFSQLSERVER (map (fn (x,y) => (x,transExp y)) str, schema, loc)
    | PLFSQLDBI (pat, exp, loc) => PLFSQLDBI (pat, transExp exp, loc)
  and transDecl pdecl = 
    case pdecl of
      PDFVAL (tvarList, plpatPlexpList, loc) =>
        PDFVAL (tvarList, map (fn (pat,exp) => (pat, transExp exp)) plpatPlexpList, loc)
    | PDFDECFUN (tvarList, plpatPlpatListPlexpListList, loc) =>
        PDFVALREC(tvarList, map (transFunDecl loc) plpatPlpatListPlexpListList, loc)
    | PDFNONRECFUN (tvarList, plpatPlpatListPlexpList, loc) =>
        PDFVAL(tvarList, [transFunDecl loc plpatPlpatListPlexpList], loc)
    | PDFVALREC (tvarList, plpatPlexpList, loc) => 
        PDFVALREC (tvarList, map (fn (pat, exp) => (pat, transExp exp)) plpatPlexpList, loc)
    | PDFVALRECGROUP (stringList, pdeclList, loc) => 
       PDFVALRECGROUP (stringList, map transDecl pdeclList, loc)
    | PDFTYPE _ => pdecl
    | PDFDATATYPE _ => pdecl
    | PDFREPLICATEDAT _ => pdecl
    | PDFABSTYPE (prefix, datbinds, pdeclList, loc) =>  
       PDFABSTYPE (prefix, datbinds, map transDecl pdeclList, loc)
    | PDFEXD _ =>  pdecl
    | PDFLOCALDEC (pdeclList1, pdeclList2, loc) => 
      PDFLOCALDEC(map transDecl pdeclList1, map transDecl pdeclList2, loc)
    | PDFINTRO _ => pdecl
    | PDFINFIXDEC _ => pdecl
    | PDFINFIXRDEC _ => pdecl
    | PDFNONFIXDEC _ => pdecl
    | PDFEMPTY => pdecl


 and transStrDecl strDec =
     case strDec of 
         PDFCOREDEC (decs,  loc) => 
         PDFCOREDEC (map transDecl decs, loc)         
       | PDFTRANCONSTRAINT (decs, namemap, spec, specnamemap, loc) =>
         PDFTRANCONSTRAINT (map transStrDecl decs, namemap, spec, specnamemap, loc)
       | PDFOPAQCONSTRAINT (decs, namemap, spec, specnamemap, loc) =>
         PDFOPAQCONSTRAINT (map transStrDecl decs, namemap, spec, specnamemap, loc)
       | PDFFUNCTORAPP _ => strDec
       | PDFANDFLATTENED (decUnits, loc) =>
         PDFANDFLATTENED(map (fn (printSig, decs) => (printSig, map transStrDecl decs)) decUnits, loc)
       | PDFSTRLOCAL (localDeclList,mainDeclList,loc) =>
         PDFSTRLOCAL (map transStrDecl localDeclList, 
                      map transStrDecl mainDeclList,
                      loc)
         
 and transTopdec pltopdec = 
   case pltopdec of
     PLFDECSTR (plfDec, loc) => 
     PLFDECSTR (map transStrDecl plfDec, loc)
   | PLFDECSIG (stringPlsigexplist, loc) => 
     PLFDECSIG (stringPlsigexplist, loc)
   | PLFDECFUN (functors, loc) =>
     PLFDECFUN (map (fn (argName, argSpec, (bodyDecs, bodyNameMap, bodySigExp), loc) =>
                        (argName, argSpec, (map transStrDecl bodyDecs, bodyNameMap, bodySigExp), loc))
                    functors,
                    loc)
  fun transTopDeclList topdecList = map transTopdec topdecList
end
end
