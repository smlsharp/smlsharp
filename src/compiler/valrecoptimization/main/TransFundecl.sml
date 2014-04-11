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
        val (varInfo, tyList, body) = transFunDeclInner loc funbind
      in
        {varInfo = varInfo, tyList = tyList, body = body}
      end
  and transFunDeclPat loc funbind =
      let
        val (varInfo, tyList, body) = transFunDeclInner loc funbind
        val pat =
            foldr
            (fn (ty, pat) => ICPATTYPED(pat, ty, loc))
            (ICPATVAR_TRANS varInfo)
            tyList
      in
        (pat, body)
      end
  and transFunDeclInner loc {funVarInfo, tyList, rules as ({args=[pat], body}::_)} =
      (funVarInfo,
       tyList,
       ICFNM
         (map
            (fn {args,body} => {args = args, body = transExp body}) rules,
          loc))
    | transFunDeclInner loc {funVarInfo, tyList, rules as [{args, body}]} =
      let
        val funBody = 
            foldr
              (fn (pat, funBody) =>
                  ICFNM([{args = [pat], body = funBody}], loc))
              (transExp body) args
      in
        (funVarInfo, tyList, funBody)
      end
    | transFunDeclInner loc {funVarInfo, tyList, rules as ({args, body}::_)} =
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
                  map (fn id=>ICVAR {longsymbol=Symbol.mkLongsymbol nil loc,id=id}) newIds
              val newVarPats =
                  map (fn id => ICPATVAR_TRANS {longsymbol=Symbol.mkLongsymbol nil loc,id=id}) newIds
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
        (funVarInfo, tyList, funBody)
      end
    | transFunDeclInner _ _ = raise Bug.Bug "illegal fun decl "
       
  and transExp icexp =
      case icexp of
        ICERROR  => icexp
      | ICCONSTANT constant => icexp
      | ICVAR _ => icexp
      | ICEXVAR _ => icexp
      | ICEXVAR_TOBETYPED _ => icexp
      | ICBUILTINVAR _ => icexp
      | ICCON _ => icexp
      | ICEXN _ => icexp
      | ICEXEXN _ => icexp
      | ICEXN_CONSTRUCTOR exnInfo => icexp
      | ICEXEXN_CONSTRUCTOR exnInfo => icexp
      | ICOPRIM oprimInfo => icexp
      | ICTYPED (icexp, ty, loc) => ICTYPED (transExp icexp, ty, loc)
      | ICSIGTYPED {icexp,ty,loc, revealKey} =>
        ICSIGTYPED {icexp=transExp icexp,
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
      | ICFFIIMPORT (icexp, ty, loc) => ICFFIIMPORT (transFFIFun icexp, ty, loc)
      | ICFFIAPPLY (cconv, funExp, args, retTy, loc) =>
        ICFFIAPPLY (cconv, transFFIFun funExp,
                    map (fn ICFFIARG (exp, ty, loc) =>
                            ICFFIARG (transExp exp, ty, loc)
                          | ICFFIARGSIZEOF (ty, SOME exp, loc) =>
                            ICFFIARGSIZEOF (ty, SOME (transExp exp), loc)
                          | ICFFIARGSIZEOF (ty, NONE, loc) =>
                            ICFFIARGSIZEOF (ty, NONE, loc))
                        args,
                    retTy, loc)
      | ICSQLSCHEMA {columnInfoFnExp, ty, loc} =>
        ICSQLSCHEMA {columnInfoFnExp = transExp columnInfoFnExp,
                     ty = ty,
                     loc = loc}
      | ICSQLDBI (icpat, icexp, loc) => ICSQLDBI (icpat, transExp icexp, loc)
      | ICJOIN (icexp1, icexp2, loc) => ICJOIN (transExp icexp1, transExp icexp2, loc)
  and transFFIFun ffiFun =
      case ffiFun of
        ICFFIFUN exp => ICFFIFUN (transExp exp)
      | ICFFIEXTERN _ => ffiFun
  and transDecl icdecl =
      case icdecl of
        ICVAL (tvarList, icpatIcexpList, loc) =>
        ICVAL (tvarList,
               map (fn (pat,exp) => (pat, transExp exp)) icpatIcexpList, loc)
      | ICDECFUN {guard, funbinds, loc} =>
        ICVALREC {guard = guard,
                  recbinds = map (transFunDeclVarInfo loc) funbinds,
                  loc = loc}
      | ICNONRECFUN {guard, funVarInfo, tyList, rules, loc} =>
        ICVAL(guard,
              [transFunDeclPat loc {funVarInfo = funVarInfo, tyList = tyList, rules = rules}],
              loc)
        (*raise Fail "FIX ICNONRECFUN!!"*)
      | ICVALREC {guard, recbinds, loc} =>
        ICVALREC {guard = guard,
                  recbinds = map (fn ({varInfo, tyList, body}) =>
                                     {varInfo = varInfo,
                                      tyList = tyList,
                                      body = transExp body})
                                 recbinds,
                  loc = loc}
      | ICVALPOLYREC (polyrecbinds, loc) =>
        ICVALPOLYREC 
          (map (fn {varInfo, ty, body} => {varInfo=varInfo, ty=ty, body=transExp body})
               polyrecbinds,
           loc)
      | ICEXND ( exdList, loc) => icdecl
      | ICEXNTAGD (_, loc) => icdecl
      | ICEXPORTVAR _ => icdecl
      | ICEXPORTTYPECHECKEDVAR _ => icdecl 
      | ICEXPORTFUNCTOR _ => icdecl
      | ICEXPORTEXN _ => icdecl
      | ICEXTERNVAR _ => icdecl
      | ICEXTERNEXN _ => icdecl
      | ICTYCASTDECL (tycastList, icdeclList, loc) => 
        ICTYCASTDECL (tycastList, map transDecl icdeclList, loc) 
      | ICOVERLOADDEF _ => icdecl
                                                    
  fun transIcdeclList (decls:IDCalc.topdecl) = 
      map transDecl decls
end
end
