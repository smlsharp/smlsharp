(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: TransFundecl.sml,v 1.16.6.6 2010/01/29 06:41:34 hiro-en Exp $
 *)
structure TransFundecl : TRANS_FUNDECL = struct
local
  open IDCalc
  fun newVarId () = VarID.generate ()
in
  fun transFunDeclVarInfo loc funbind =
      let
        val (varInfo, body) = transFunDeclInner loc funbind
      in
        {varInfo = varInfo, body = body}
      end
  and transFunDeclPat loc funbind =
      let
        val (varInfo, body) = transFunDeclInner loc funbind
      in
        (ICPATVAR (varInfo, loc), body)
      end
  and transFunDeclInner loc {funVarInfo, rules as ({args=[pat], body}::_)} =
      (funVarInfo,
       ICFNM
         (map
            (fn {args,body} => {args = args, body = transExp body}) rules,
          loc))
    | transFunDeclInner loc {funVarInfo, rules as [{args, body}]} =
      let
        val funBody = 
            foldr
              (fn (pat, funBody) =>
                  ICFNM([{args = [pat], body = funBody}], loc))
              (transExp body) args
      in
        (funVarInfo, funBody)
      end
    | transFunDeclInner loc {funVarInfo, rules as ({args, body}::_)} =
      let
        val funBody =
            let
              fun listToTuple list =
                  #2
                    (foldl
                       (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
                       (1, nil)
                       list)
              val newIds = map (fn x => newVarId()) args
              val newVars =
                  map (fn id=>ICVAR({path=nil,id=id},loc)) newIds
              val newVarPats =
                  map (fn id => ICPATVAR({path=nil,id=id},
                                         loc)) newIds
              val argRecord = ICRECORD (listToTuple newVars, loc)
              val funRules =
                  map
                  (fn {args, body} =>
                      {args = [ICPATRECORD {flex = false,
                                            fields = listToTuple args,
                                            loc = loc}],
                       body = transExp body}
                  )
                  rules
            in
              foldr
                (fn (x, y) =>
                    ICFNM([{args = [x], body = y}],
                          loc))
                (ICAPPM
                   (
                    ICFNM(funRules, loc),
                    [argRecord],
                    loc
                ))
                newVarPats
            end
      in
        (funVarInfo, funBody)
      end
    | transFunDeclInner _ _ = raise Control.Bug "illegal fun decl "
       
  and transExp icexp =
      case icexp of
        ICERROR (vaInfo, loc) => icexp
      | ICCONSTANT (constant, loc) => icexp
      | ICGLOBALSYMBOL _ => icexp
      | ICVAR (_, loc) => icexp
      | ICEXVAR ({path, ty}, loc) => icexp
      | ICEXVAR_TOBETYPED ({path, id}, loc) => icexp
      | ICBUILTINVAR {primitive, ty, loc} => icexp
      | ICCON (conInfo, loc) => icexp
      | ICEXN (exnInfo, loc) => icexp
      | ICEXEXN ({path, ty}, loc) => icexp
      | ICEXN_CONSTRUCTOR (exnInfo, loc) => icexp
      | ICEXEXN_CONSTRUCTOR (exnInfo, loc) => icexp
      | ICOPRIM (oprimInfo, loc) => icexp
      | ICTYPED (icexp, ty, loc) => ICTYPED (transExp icexp, ty, loc)
      | ICSIGTYPED {path,icexp,ty,loc, revealKey} =>
        ICSIGTYPED {path=path,
                    icexp=transExp icexp,
                    ty=ty,
                    revealKey=revealKey,
                    loc=loc}
      | ICAPPM (icexp, icexplist, loc) =>
        ICAPPM (transExp icexp, map transExp icexplist, loc)
      | ICAPPM_NOUNIFY (icexp, icexplist, loc) =>
        ICAPPM_NOUNIFY (transExp icexp, map transExp icexplist, loc)
      | ICLET (icdecList, icexpList, loc) =>
        ICLET (map transDecl icdecList, map transExp icexpList, loc)
      | ICTYCAST (tycastList, icexp, loc) =>
        ICTYCAST (tycastList, transExp icexp, loc)
      | ICRECORD (stringIcexpList, loc) =>
        ICRECORD (map (fn (l, icexp) => (l, transExp icexp)) stringIcexpList,
                  loc)
      | ICRAISE (icexp, loc) =>
        ICRAISE (transExp icexp, loc)
      | ICHANDLE (icexp, icpatIcexpList, loc) =>
        ICHANDLE (transExp icexp,
                  map (fn (pat, exp) => (pat, transExp exp)) icpatIcexpList,
                  loc)
      | ICFNM (icpatListIcexpList, loc) =>
        ICFNM (map (fn ({args:icpat list, body:icexp}) =>
                       {args = args, body = transExp body})
                   icpatListIcexpList,
               loc)
      | ICFNM1 (varTyListList, icexp, loc) =>
        ICFNM1 (varTyListList, transExp icexp, loc)
      | ICFNM1_POLY (varTyList, icexp, loc) =>
        ICFNM1_POLY (varTyList, transExp icexp, loc)
      | ICCASEM (icexpList, icpatListIcexpList, caseKind, loc) =>
        ICCASEM (map transExp icexpList,
                 map (fn {args, body} => {args = args, body = transExp body})
                     icpatListIcexpList,
                 caseKind,
                 loc)
      | ICRECORD_UPDATE (icexp, stringIcexpList, loc) =>
        ICRECORD_UPDATE (transExp icexp,
                         map (fn (l, exp) => (l, transExp exp)) stringIcexpList,
                         loc)
      | ICRECORD_SELECTOR (string, loc) => icexp
      | ICSELECT (string, icexp, loc) =>
        ICSELECT (string, transExp icexp, loc)
      | ICSEQ (icexpList, loc) => ICSEQ (map transExp icexpList, loc)
      | ICCAST (icexp, loc) => ICCAST (transExp icexp, loc)
      | ICFFIIMPORT (icexp, ty, loc) => ICFFIIMPORT (transExp icexp, ty, loc)
      | ICFFIEXPORT (icexp, ty, loc) => ICFFIEXPORT (transExp icexp, ty, loc)
      | ICFFIAPPLY (cconv, funExp, args, retTy, loc) =>
        ICFFIAPPLY (cconv, transExp funExp,
                    map (fn ICFFIARG (exp, ty, loc) =>
                            ICFFIARG (transExp funExp, ty, loc)
                          | ICFFIARGSIZEOF (ty, SOME exp, loc) =>
                            ICFFIARGSIZEOF (ty, SOME (transExp exp), loc)
                          | ICFFIARGSIZEOF (ty, NONE, loc) =>
                            ICFFIARGSIZEOF (ty, NONE, loc))
                        args,
                    retTy, loc)
      | ICSQLSERVER (str, schema, loc) =>
        ICSQLSERVER (map (fn (x,y) => (x,transExp y)) str, schema, loc)
      | ICSQLDBI (icpat, icexp, loc) => ICSQLDBI (icpat, transExp icexp, loc)
  and transDecl icdecl =
      case icdecl of
        ICVAL (tvarList, icpatIcexpList, loc) =>
        ICVAL (tvarList,
               map (fn (pat,exp) => (pat, transExp exp)) icpatIcexpList, loc)
      | ICDECFUN {guard, funbinds, loc} =>
        ICVALREC {guard = guard,
                  recbinds = map (transFunDeclVarInfo loc) funbinds,
                  loc = loc}
      | ICNONRECFUN {guard, funVarInfo, rules, loc} =>
        ICVAL(guard,
              [transFunDeclPat loc {funVarInfo = funVarInfo, rules = rules}],
              loc)
        (*raise Fail "FIX ICNONRECFUN!!"*)
      | ICVALREC {guard, recbinds, loc} =>
        ICVALREC {guard = guard,
                  recbinds = map (fn ({varInfo, body}) =>
                                     {varInfo = varInfo,
                                      body = transExp body})
                                 recbinds,
                  loc = loc}
      | ICABSTYPE {tybinds, body, loc} =>
        ICABSTYPE {tybinds = tybinds, body = map transDecl body, loc = loc}
      | ICEXND ( exdList, loc) => icdecl
      | ICEXNTAGD (_, loc) => icdecl
      | ICEXPORTVAR (varInfo, ty, loc) => icdecl
      | ICEXPORTTYPECHECKEDVAR (varInfo, loc) => icdecl 
      | ICEXPORTFUNCTOR _ => icdecl
      | ICEXPORTEXN (exnInfo, loc) => icdecl
      | ICEXTERNVAR ({path, ty}, loc) => icdecl
      | ICEXTERNEXN ({path, ty}, loc) => icdecl
      | ICOVERLOADDEF {boundtvars, id, path, overloadCase, loc} => icdecl
                                                    
  fun transIcdeclList icdeclList = map transDecl icdeclList      
end
end
