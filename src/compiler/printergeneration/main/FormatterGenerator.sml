(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This structure generates formatter declarations for type/datatype/exception
 * declarations.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FormatterGenerator.sml,v 1.21 2006/02/18 04:59:25 ohori Exp $
 *)
structure FormatterGenerator =
struct

  (***************************************************************************)

  structure A = Absyn
  structure FE = SMLFormat.FormatExpression
  structure P = Path
  structure PE = PatternCalc
  structure TC = TypeContext
  structure TP = TypedCalc
  structure TU = TypesUtils
  structure TY = Types

  structure U = Utility
  structure OC = ObjectCode

  (***************************************************************************)

  (**
   * return an expression whose value is the formatter for the specified type.
   * @params context currentTyCons BTVFormatters ty
   * @param context
   * @param currentTyCons tyCons 
   * @param TVFormatters list of pairs of
   *        <ul>
   *          <li>type variable (tvState ref)</li>
   *          <li>argument name which is bound to the formatter for the type
   *            to which the bound type variable is instantiated.</li>
   *        </ul>
   * @param ty the type of value to be formatted.
   * @return an expression which is evaluated to a formatter for the ty.
   *)
  fun generateFormatterOfTy context path currentTyCons TVFormatters loc ty =
      let
        (* This function returns
         *   fn argVar => bodyExp
         *)

        val argVarName = U.makeVarName ()
        val argVarPathInfo = {name = argVarName, strpath = P.NilPath, ty = ty}
        val argVarExp = TP.TPVAR (argVarPathInfo, loc)
        (* make bodyExp.
         * Because recursive call is necessary to handle type variable and
         * POLYty, this is defined as a function. *)
        fun generateFormatterBodyOfTy ty =
            case ty of
              TY.ERRORty => raise Control.Bug "unexpected ERRORty"
            | TY.DUMMYty _ =>
              TP.TPRAISE
                  (
                    OC.failException ("BUG? DUMMYty.", loc),
                    OC.formatterResultTy,
                    loc
                  )

            | TY.TYVARty(ref (TY.SUBSTITUTED actualTy)) =>
              generateFormatterBodyOfTy actualTy

            | TY.TYVARty(ref (TY.TVAR tvKind)) =>
              (case
                 List.find
                     (fn (ref (TY.TVAR{id, ...}), _) => id = #id tvKind)
                     TVFormatters
                of
                 SOME(_, TVFormatter) =>
                 (* formatter of this variable is passed from the caller. *)
                 let
                   val TVFormatterTy = OC.formatterOfTyTy ty
                   val varInfo =
                       {
                         name = TVFormatter,
                         strpath = P.NilPath,
                         ty = TVFormatterTy
                       }
                 in
                   TP.TPAPPM
                       {
                         funExp = TP.TPVAR (varInfo, loc), 
                         funTy = TVFormatterTy, 
                         argExpList = [argVarExp], 
                         loc = loc
                       }
                 end
               | NONE =>
                 TP.TPRAISE
                     (
                       OC.failException ("BUG? free tyvar.", loc),
                       OC.formatterResultTy,
                       loc
                     ))

            | TY.BOUNDVARty(ID) =>
              (* This branch is for polymorphic value, such as nil.
               * this expression will be never called in runtime. *)
              TP.TPRAISE
                  (
                    OC.failException ("BUG? bound tyvar.", loc),
                    OC.formatterResultTy,
                    loc
                  )
            | TY.FUNMty _ =>
              OC.translateFormatExpression (FE.Term(2, "fn"))

            | TY.RECORDty fieldsMap =>
              if 0 = SEnv.numItems fieldsMap
              then
                OC.translateFormatExpression(FE.Term(2, "()"))
              else
                let
                  fun generateForField (label, polyFieldTy) =
                      let 
                        val (fieldExp, fieldTy) =
                            U.instantiateExp
                                (
                                  TP.TPSELECT
                                      {
                                        label = label,
                                        exp = argVarExp,
                                        expTy = ty,
                                        loc = loc
                                      },
                                  polyFieldTy
                                )
                        val fieldFormatterExp =
                            generateFormatterOfTy
                                context
                                path
                                currentTyCons
                                TVFormatters
                                loc
                                fieldTy
                        val fieldFormatterTy = OC.formatterOfTyTy fieldTy
                        val fieldFormatExp = 
                            TP.TPAPPM
                                {
                                  funExp = fieldFormatterExp,
                                  funTy = fieldFormatterTy,
                                  argExpList = [fieldExp],
                                  loc = loc
                                }
                      in
                        (label, fieldFormatExp)
                      end
                  (* labelFieldExps = [(l1, #l1 arg), ..., (ln, #ln arg)] *)
                  val labelFieldExps =
                      map generateForField (SEnv.listItemsi fieldsMap)
                  val isTuple = U.isTupleFields fieldsMap
                  val fieldExps =
                      if isTuple
                      then #2(ListPair.unzip labelFieldExps)
                      else
                        (* add label to each field *)
                        map
                        (fn (label, fieldExp) =>
                            OC.makeGuard
                            (
                              NONE,
                              OC.translateFormatExpressions
                              [
                                FE.Term (size label, label),
                                U.s_d_Indicator,
                                FE.Term (1, "="),
                                U.s_1_Indicator
                              ]
                              @ [fieldExp]
                            ))
                        labelFieldExps

                  (* insert commas between fields *)
                  val joinedExps =
                      List.rev
                      (foldl
                       (fn (exp, joined) =>
                           OC.makeGuard(NONE, [exp]) ::
                           OC.translateFormatExpressions
                               [FE.Term (1, ","), U.s_1_Indicator] @
                           joined)
                       ([hd fieldExps])
                       (tl fieldExps))

                  (* header and trailer which enclose the fields list *)
                  val (left, right) =
                      if isTuple then ("(", ")") else ("{", "}")
                  val leftParenExps = 
                      OC.translateFormatExpressions
                      [FE.Term (1, left), FE.StartOfIndent 2, U.s_1_Indicator]
                  val rightParenExps =
                      OC.translateFormatExpressions
                      [FE.EndOfIndent, U.s_1_Indicator, FE.Term (1, right)]
                in
                  OC.makeGuard
                      (NONE, leftParenExps @ joinedExps @ rightParenExps)
                end

            | TY.CONty{tyCon, args = argTys} =>
              if U.isHiddenTyCon context path tyCon
              then OC.translateFormatExpression(FE.Term(1, "-"))
              else
              let

                (* If the tyCon is one of tyCons for which formatters is now
                 * generated, that formatter for the tyCon is referrred as
                 * local variable. Otherwise, it is referred as global.
                 * And these formatters is monotyped within the bodies of them.
                 *)
                val isRecursive = 
                    List.exists (fn tc => tyCon = tc) currentTyCons

                (* [f1,...,fn] *)
                val argFormatterExps =
                    map
                        (generateFormatterOfTy
                             context path currentTyCons TVFormatters loc)
                        argTys
                (* [t1->r,...tn->r] *)
                val argFormatterTys = map OC.formatterOfTyTy argTys
(*
val _ = print ("tyCon = " ^ pathToString(appendPath(#strpath tyCon, #name tyCon)) ^ "\n")
*)
                val (formatterPath, formatterName) =
                    U.formatterPathNameOfTyCon path tyCon

                local
                  val polyFormatterTy =
                      U.generalize(OC.formatterOfTyConTy tyCon)
                in
                (* formatter type which is instantiated with argument types.
                 *   (t1->r)->...->(tn->r)->(t1,...,tn)t->r
                 *)
                val instantiatedFormatterTy =
                    TU.tpappTy (polyFormatterTy, argTys)

                (* type formatter which is bound in static environment.
                 * f : ['a1,...,'an.('a1->r)->...->('an->r)->('a1,...,'an)t->r
                 *)
                val originalFormatterTy =
                    if isRecursive
                    then
                      (* recursive reference is monotype. *)
                      instantiatedFormatterTy 
                    else polyFormatterTy
                end

                (* If the formatter is one which is now defined, it should
                 * be referred by using only single name without module path.
                 *)
                val originalFormatterExp =
                    TP.TPVAR
                        (
                          {
                            name = formatterName,
                            strpath =
                            if isRecursive then P.NilPath else formatterPath,
                            ty = originalFormatterTy
                          },
                          loc
                        )

                (* make monotype version of formatter exp *)
                val instantiatedFormatterExp =
                    if isRecursive orelse List.null argTys
                    then originalFormatterExp
                    else
                      TP.TPTAPP
                          {
                            exp = originalFormatterExp,
                            expTy = originalFormatterTy,
                            instTyList = argTys,
                            loc = loc
                          }

                (* apply argFormatters to the formatter. *)
                val (formatterExp, formatterTy) =
                    (* apply argument formatters to the formatter for the
                     * tyCon,  from 'a1->r to 'an->r. *)
                    foldl
                    (fn ((argFormatterExp, argFormatterTy),(funExp, funTy)) =>
                        let
                          val resultTy = OC.applyTy(funTy, argFormatterTy)
                          val resultExp =
                              TP.TPAPPM
                                  {
                                    funExp = funExp,
                                    funTy = funTy,
                                    argExpList = [argFormatterExp],
                                    loc = loc
                                  }
                        in (resultExp, resultTy)
                        end)
                    (instantiatedFormatterExp, instantiatedFormatterTy)
                    (ListPair.zip (argFormatterExps, argFormatterTys))

(*
val _ = print "generateFormatterOfTy\n"
val _ = (print "argTys: "; app (fn ty => print (TypeFormatter.tyToString ty ^ ",")) argTys; print "\n")
val _ = print "formatterOfTyConTy: "
val _ = print (TypeFormatter.tyToString (OC.formatterOfTyConTy tyCon))
val _ = print "\n"
val _ = print "instantiatedFormatterTy: "
val _ = print (TypeFormatter.tyToString instantiatedFormatterTy)
val _ = print "\n"
val _ = print "originalFormatterTy: "
val _ = print (TypeFormatter.tyToString originalFormatterTy)
val _ = print "\n"
val _ = print "formatterTy: "
val _ = print (TypeFormatter.tyToString formatterTy)
val _ = print "\n"
*)
              in
                (* apply the formatter to the argument *)
                TP.TPAPPM
                    {
                      funExp = formatterExp,
                      funTy = formatterTy,
                      argExpList = [argVarExp],
                      loc = loc
                    }
              end

            | TY.POLYty{body, boundtvars} =>
              let
                val (monoTy, argTys) = 
                    TU.instantiate {body = body, boundtvars = boundtvars}
                val formatterExp = generateFormatterBodyOfTy monoTy
              in
                formatterExp
              end

            | TY.ALIASty(alias, actual) =>
              (* Use the formatter defined for the actual type.
               * No formatter is defined for the alias type.
               *)
              generateFormatterBodyOfTy actual

	    | TY.ABSSPECty _ => OC.translateFormatExpression(FE.Term(1, "-"))

            | TY.SPECty ty =>
              (* this type is declared in functor parameter structure. *)
              OC.translateFormatExpression(FE.Term(1, "-"))

            | _ =>
              raise
                Control.Bug ("unexpected ty: " ^ TypeFormatter.tyToString ty)

        val bodyExp = generateFormatterBodyOfTy ty
      in
        TP.TPFNM
            {
              argVarList = [argVarPathInfo],
              bodyTy = OC.formatterResultTy,
              bodyExp = bodyExp,
              loc = loc
            }
      end

  (***************************************************************************)

  fun generateCaseBranchForConPathInfo
          context
          path
          currentTyCons
          loc
          formatterOfArgTys
          (conInfo : TY.conPathInfo) =
      let
        (*
         * Type of constructors and type of formatter are separately closed in
         * POLYty.
         * For example, assume a datatype declaration:
         *
         *   datatype ('a,'b) t = D1 of 'a | D2 of ('a * 'b)
         *
         * Then, types of formatter and constructors are:
         *
         *   format_t :
         *     ['a,'b.('a->result) -> ('b->result) -> ('a,'b) t -> result]
         *   D1 : ['a, 'b. 'b -> ('b, 'a) t]
         *   D2 : ['b, 'a. ('a * 'b) -> ('a, 'b) t]
         *
         * It is to be noted that bound variables are ordered randomly in
         * binder.
         * We has to translates these types into:
         *
         *   format_t : ('a->result) -> ('b->result) -> ('a,'b) t -> result
         *   D1 : 'a -> ('a, 'b) t
         *   D2 : ('a * 'b) -> ('a, 'b) t
         *
         * under bound variables ['a,'b].
         *
         * Bound type variables in type of each constructor is substituted,
         * so that type variables in types of constructors and the formatter
         * are under the same binder.
         *)
        val conTy =
            case #ty conInfo of
              TY.POLYty{body = body as TY.FUNMty(_, TY.CONty{args, ...}), ...}
              =>
              (* #ty conInfo = ['a1,...,'an. 'a -> ('a1,...,'an) t] *)
              foldl
                  (fn ((TY.BOUNDVARty(srcID), (destTyVar, _)), ty) =>
                      TU.substituteBTV (srcID, TY.TYVARty destTyVar) ty
                    | ((srcTy, _), _) =>
                      raise
                        Fail
                        ("Unexpected(1):" ^ TypeFormatter.tyToString srcTy))
                  body
                  (ListPair.zip (map U.getRealTy args, formatterOfArgTys))
            | ty =>
              (* #ty conInfo = (s1, ..., sn) t *)
              ty
        val conName = #name conInfo
        val argTys = map (fn (tyVar, _) => TY.TYVARty tyVar) formatterOfArgTys
      in
        if #funtyCon conInfo
        then
          (* D (v : s) => "D" (format_s v) *)
          let
            (* argVarTy = s, tyConTy = (s1, ..., sn) t *)
            val (tyConTy, polyArgVarTy) =
                case conTy of
                  TY.FUNMty([argVarTy], tyConTy) => (tyConTy, argVarTy)
            val argVarName = U.makeVarName ()
            val argVarPathInfo =
                {name = argVarName, strpath = P.NilPath, ty = polyArgVarTy}
            val argVarExp = TP.TPVAR(argVarPathInfo, loc)
            val argVarPat = TP.TPPATVAR(argVarPathInfo, loc)
            (* D (v : s) : (s1, ..., sn) t *)
            val pat =
                TP.TPPATCONSTRUCT
                    {
                      conPat=conInfo, 
                      instTyList=argTys, 
                      argPatOpt=SOME argVarPat, 
                      patTy=tyConTy, 
                     loc=loc
                     }
            (* if v is a polymorphic, instantiate to a monotype exp. *)
            val (argVarExp, argVarTy) =
                U.instantiateExp(argVarExp, polyArgVarTy)
            (* format_s *)
            val argFormatterExp =
                generateFormatterOfTy
                    context path currentTyCons formatterOfArgTys loc argVarTy
            (* format_s v *)
            val argExp =
                TP.TPAPPM
                    {
                      funExp = argFormatterExp,
                      funTy = OC.formatterOfTyTy argVarTy,
                      argExpList = [argVarExp],
                      loc = loc
                    }
            (* "D" ^ (format_s v) *)
            val exp =
                OC.concatFormatExpressions
                    ((OC.translateFormatExpressions
                          [FE.Term(size conName, conName), U.s_1_Indicator])
                     @ [argExp])
          in ([pat], exp)
          end
        else
          (* D => "D" *)
          let
            val pat =
                TP.TPPATCONSTRUCT
                    {
                      conPat = conInfo, 
                      instTyList = argTys, 
                      argPatOpt = NONE, 
                      patTy = conTy, 
                      loc = loc
                    }
            val exp =
                OC.translateFormatExpression (FE.Term(size conName, conName))
          in ([pat], exp)
          end
      end

  (***************************************************************************)

  fun generateFormatterForDatatype
          context
          currentPath
          currentTyCons
          loc
          (tyCon as {name, strpath, tyvars, datacon, ...} : TY.tyCon) =
      let
        (* ('X1->result) ->...-> ('Xn->result) -> ('X1,...,'Xn) t -> result *)
        val formatterTy = OC.formatterOfTyConTy tyCon
        (* 'X1 -> result, ..., 'Xn -> result, ('X1,...,'Xn) t *)
        val (formatterTyOfArgTys, argVarTy, _) =
            U.decompFunctionType (List.length tyvars) formatterTy

        (****** name of variable ids *************)
        (* format_ty *)
        val (formatterPath, formatterName) =
            U.formatterPathNameOfTyCon currentPath tyCon
        (* 'X1, ..., 'Xn *)
        val argTyVars =
            map
                (fn TY.FUNMty([TY.TYVARty(argTyVar)], _) => argTyVar)
                formatterTyOfArgTys
        (* format_'X1, ..., format_'Xn *)
        val formatterOfArgTys =
            map
                (fn (ref(TY.TVAR{id, ...})) =>
                    U.formatterNamePrefix ^ (Types.tidToString id))
                argTyVars

        val argVarPathInfo =
            {name = U.makeVarName(), strpath = P.NilPath, ty = argVarTy}
        val argVarExp = TP.TPVAR(argVarPathInfo, loc)
        (* D1 v1 => exp1, ... Dk vk => expk *)
        val branches =
            map
            (fn TY.CONID conPathInfo =>
                generateCaseBranchForConPathInfo
                    context
                    currentPath
                    currentTyCons
                    loc
                    (ListPair.zip(argTyVars, formatterOfArgTys))
                    (U.makeConPathInfoLocal conPathInfo))
            (SEnv.listItems (!datacon))
        (* case (argVar : argVarTy) of pat => (exp : resultTy) *)
        val bodyExp = 
            TP.TPCASEM
            {
              expList = [argVarExp],
              expTyList = [argVarTy],
              ruleList = branches,
              ruleBodyTy = OC.formatterResultTy,
              caseKind = TY.MATCH,
              loc = loc
            }
        (* fn format_'X1 => ... fn format_'Xn => fn v => body *)
        val (formatterExp, resultTy) =
            foldr
            (fn ((name, ty), (fnExp, resultTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], resultTy)
                  val formatterOfArgVarPathInfo =
                      {name = name, ty = ty, strpath = P.NilPath}
                in
                  (
                    TP.TPFNM
                        {
                          argVarList = [formatterOfArgVarPathInfo],
                          bodyTy = resultTy,
                          bodyExp = fnExp,
                          loc = loc
                        },
                    formatterTy
                  )
                end)
            (
              TP.TPFNM
                  {
                    argVarList = [argVarPathInfo],
                    bodyTy = OC.formatterResultTy,
                    bodyExp = bodyExp,
                    loc = loc
                  },
              OC.formatterOfTyTy(argVarTy)
            )
            (ListPair.zip (formatterOfArgTys, formatterTyOfArgTys))
        val formatterVarPathInfo =
            {name = formatterName, strpath = strpath, ty = formatterTy}
      in
        (formatterVarPathInfo, formatterTy, formatterExp)
      end

  (**
   * Generate an instantiated version of formatter.
   * (ToDo : this function name should be changed to other nice name.)
   * <p>
   * Assume a polymorphic recursive datatype declaration.
   * <pre>
   *  datatype 'a t = D of ('a, 'a) s | E of 'a
   *       and ('a, 'b) s = F of 'b t * 'a;
   * </pre>
   * We want to generate formatters of the following bindings.
   * <pre>
   *  format_t : ['a.('a -> string) -> 'a t -> string]
   *  format_s :
   *  [
   *    'a,'b.
   *    ('a -> string) -> ('b -> string) -> ('a, 'b) s -> string
   *  ]
   * </pre>
   * Their implementation is defined recursively as follows.
   * <pre>
   *  fun format_t format_a x =
   *      case x of 
   *        D x => "D" ^ (format_s format_a format_a x)
   *      | E x => "E" ^ (format_a x)
   *  and format_s format_a format_b x = 
   *      case x of
   *        F (x, y) => "F" ^ (format_t format_b x) ^ (format_a y);
   * </pre>
   * (NOTE: Internal generated code, including this one, assume an extended
   * type system which permits polymorphic occurrence of recursive defined
   * identifier (format_s, in this case).
   * </p>
   * <p>
   * But because recursive polymorphic bindings share the union of bound
   * type variables of every bindings in the same declaration, they have
   * the following types different from expected.
   * <pre>
   *  format_t : ['a,'b,'c.('a -> string) -> 'a t -> string]
   *  format_s :
   *  [
   *    'a,'b,'c.
   *    ('b -> string) -> ('c -> string) -> ('b, 'c) s -> string
   *  ]
   * </pre>
   * This causes a problem.
   * Assume a code which applies the constructor defined above.
   * <pre>
   *  val x = E 1 : int t
   * </pre>
   * For this user code, the compiler generates a code which invokes the
   * formatter generated for the applied constructor.
   * <pre>
   *  format_t format_int x
   * </pre>
   * Because format_t has a polymorphic type, it has to be instantiated to
   * a monotype before application.
   * But, by what types should it be instantiated ?
   * The type of format_t has three bound type variables. 
   * On the other hand, we know only int type from this code.
   * </p>
   * <p>
   * One solution is to instantiate with dummy free type variables.
   * <pre>
   *  local
   *    fun format_t ...
   *    and format_s ...
   *  in
   *  val 'a format_t = format_t {'a,'X0,'X1}
   *  val ('a,'b) format_s = format_s {'X0,'a,'b}
   *  end
   * </pre>
   * But this code causes a runtime error (why ?). So, the current
   * implementation generates another eta equivalent code.
   * <pre>
   *  local
   *    fun format_t ...
   *    and format_s ...
   *  in
   *  val 'a format_t = 
   *      fn format_a =>
   *         fn x => format_t {'a,'X0,'X1} format_a x
   *  val ('a, 'b) format_s = 
   *      fn format_a => 
   *         fn format_b =>
   *            fn x =>
   *               format_s {'X0,'a,'b} format_a format_b x
   *  end
   * </pre>
   * </p>
   *
   * @params context BTVKindMap tyCon formatterVarPathInfo
   * @param context context
   * @param BTVKindMap map of bound type variables indexed by ID (= integer).
   * @param tyCon the type constructor for which the formatter is generated.
   * @param formatterVarPathInfo the original formatter for which this
   *        function generates an instantiated version.
   *        The type in it should be generalized but not wrapped in POLYty.
   *        For example, assume the original formatter has the type: 
   *        <code>['a,'b.('a -> string) -> 'a t -> string]</code>.
   *        Then, BTVKindMap contains <code>{'a,'b}</code>,
   *        and the ty field of formatterVarPathInfo should be
   *        <code>('a -> string) -> 'a t -> string</code>.
   * @return (varPathInfo, ty, exp) of the generated formatter
   *)
  fun generateInstantiatedFormatterForDatatype
      context path BTVKindMap loc tyCon (formatterVarPathInfo : TY.varPathInfo) =
      let
        (*
         * 0, assume a set of bound type variables BTV, 
         *  and the original formatter of the type:
         * format_t : ('a1->string)->...->('an->string)->('a1,...,'an)t->string
         * 1, Get applied bound type variables
         *  A = {'a1,...,'an}
         * 2, For each type variable 'bi in BTV,
         *  if 'bi = 'aj  for some 'aj in A
         *  then 'aj
         *  else 'Xi (dummy type)
         * to get a list of type variables
         *  B = {...,'ai,...,'Xj,...}
         * 3, build a function
         *  fn format_c1 => 
         *     ... => 
         *       fn format_cn => 
         *          fn x => format_t {A} format_c1 ... format_cn x
         *  : ['a1,..,'an.
         *     ('a1->string)->...->('an->string)->('a1,...,'an)t->string]
         *)
        val arity = List.length (#tyvars tyCon)

        fun getAppliedTys 0 (TY.FUNMty([TY.CONty{args, ...}], _)) = args
          | getAppliedTys n (TY.FUNMty(_, resultTy)) =
            getAppliedTys (n - 1) resultTy
        val appliedTys =
            map U.getRealTy (getAppliedTys arity (#ty formatterVarPathInfo))
        fun isAppliedTy ID =
            List.exists (fn (TY.BOUNDVARty BTVID) => ID = BTVID) appliedTys

        fun toBTVs dummyTyIndex [] newTys = List.rev newTys
          | toBTVs dummyTyIndex ((ID, BTVKind) :: tailBTVKinds) newTys =
            let
              val BTVIndex = #index (BTVKind : TY.btvKind)
              val (newTy, dummyTyIndex) = 
                  if isAppliedTy ID
                  then (TY.BOUNDVARty ID, dummyTyIndex)
                  else (TY.DUMMYty dummyTyIndex, dummyTyIndex + 1)
            in toBTVs dummyTyIndex tailBTVKinds (newTy :: newTys)
            end
        val replacedBoundTys = toBTVs 0 (IEnv.listItemsi BTVKindMap) []

        fun makeBTVKind index =
            {index = index, recKind = TY.UNIV, eqKind = TY.NONEQ}
        val (_, newBTVKindMap) = 
            foldl (* left to right *)
                (fn (TY.BOUNDVARty ID, (index, map)) =>
                    (index + 1, IEnv.insert(map, ID, makeBTVKind index)))
                (0, IEnv.empty)
                appliedTys

        (****************************************)
        (* construct a function expression *)

        (* the argument to be formatted *)
        val argTy = TY.CONty{tyCon = tyCon, args = appliedTys}
        val argVarPathInfo =
            {name = U.makeVarName (), ty = argTy, strpath = P.NilPath}
        val argExp = TP.TPVAR(argVarPathInfo, loc)
        (* formatter arguments: format_c1, ..., format_cn *)
        val argFormatterVarInfos =
            map
                (fn (ty as TY.BOUNDVARty index) =>
                    {
                      name = U.formatterNamePrefix ^ Int.toString index,
                      ty = OC.formatterOfTyTy ty
                    })
                appliedTys
        (* type applied formatter: format_t {...,'ci,..,'Xj,...} *)
        val polyFormatterVarPathInfo =
            {
              name = #name formatterVarPathInfo,
              strpath = #strpath formatterVarPathInfo,
              ty =
              TY.POLYty
                  {boundtvars = BTVKindMap, body = #ty formatterVarPathInfo}
            }
        val monoFormatterExp = 
            TP.TPTAPP
                {
                  exp = TP.TPVAR (polyFormatterVarPathInfo, loc),
                  expTy = #ty polyFormatterVarPathInfo,
                  instTyList = replacedBoundTys,
                  loc = loc
                }
        val monoFormatterTy =
            foldr
                (fn ({ty, ...}, resultTy) => TY.FUNMty ([ty], resultTy))
                (OC.formatterOfTyTy argTy)
                argFormatterVarInfos
(*
val _ = print "generateInstantiatedFormatterForDatatype\n"
val _ = print "polyFormatterTy: "
val _ = print (TypeFormatter.tyToString (#ty polyFormatterVarPathInfo))
val _ = print "\n"
val _ = print "monoFormatterTy: "
val _ = print (TypeFormatter.tyToString monoFormatterTy)
val _ = print "\n"
*)
        (* [format_c1, ..., format_cn, x] *)
        fun varInfoToExp varInfo =
            TP.TPVAR(U.varInfoToVarPathInfo varInfo, loc)
        val argExps = (map varInfoToExp argFormatterVarInfos) @ [argExp]
        (* format_t {...,'ci,..,'Xj,...} format_c1 ... format_cn x *)
        val (bodyExp, bodyTy) = 
            foldl (* from left (= c1) to right (= cn) *)
            (fn (argExp, (formatterExp, formatterTy as TY.FUNMty(_, resultTy)))
                =>
                (
                  TP.TPAPPM
                      {
                        funExp = formatterExp,
                        funTy = formatterTy,
                        argExpList = [argExp],
                        loc = loc
                      },
                      resultTy
                ))
            (monoFormatterExp, monoFormatterTy)
            argExps

        (* fn format_c1 => ... => fn format_cn => fn arg => bodyExp *)
        val (fnExp, fnTy) =
            foldr (* from right (= cn) to left (= c1) *)
            (fn ({name, ty}, (bodyExp, bodyTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], bodyTy)
                  val varPathInfo = {name = name, ty = ty, strpath = P.NilPath}
                in
                  (
                    TP.TPFNM
                        {
                          argVarList = [varPathInfo],
                          bodyTy = bodyTy,
                          bodyExp = bodyExp,
                          loc = loc
                        },
                    formatterTy
                  )
                end)
            (
              TP.TPFNM
                  {
                    argVarList = [argVarPathInfo],
                    bodyTy = OC.formatterResultTy,
                    bodyExp = bodyExp,
                    loc = loc
                  },
              OC.formatterOfTyTy(argTy)
            )
            argFormatterVarInfos

        val (formatterTy, formatterExp) =
            case appliedTys of
              [] => (fnTy, fnExp)
            | _ =>
              (
                TY.POLYty{boundtvars = newBTVKindMap, body = fnTy},
                TP.TPPOLY
                    {
                      btvEnv = newBTVKindMap,
                      expTyWithoutTAbs = fnTy,
                      exp = fnExp,
                      loc = loc
                    }
              )
        val varPathInfo = 
            {
              name = #name formatterVarPathInfo,
              strpath = P.NilPath,
              ty = formatterTy
            }
      in
        (varPathInfo, formatterTy, formatterExp)
      end

  fun generateFormatterForTyCons
          generateFormatterForTyCon context path toPrint loc tyCons =
      let
        val formatterBinds =
            map (generateFormatterForTyCon context path tyCons loc) tyCons

        val TypesOfAllElements =  
            TY.RECORDty
                (foldr
                     (fn (({name = funId, ...}, ty, _), tyFields) =>
                         SEnv.insert(tyFields, funId, ty))
                     SEnv.empty
                     formatterBinds)
        val btvEnvOpt =
            case U.generalize TypesOfAllElements of
              TY.POLYty{boundtvars, ...} => SOME boundtvars
            | _ => NONE

        local
          fun transDec (varPathInfo, ty, exp) =
              {var = U.varPathInfoToVarInfo varPathInfo, expTy = ty, exp = exp}
        in
        val formatterDecs = map transDec formatterBinds
        val formatterDeclaration =
            case btvEnvOpt of
              SOME btvEnv => TP.TPVALPOLYREC (btvEnv, formatterDecs, loc)
            | _ => TP.TPVALREC (formatterDecs, loc)
        end

        val (declaration, binds) =
            case (btvEnvOpt, formatterBinds) of
              (NONE, _) => (formatterDeclaration, formatterBinds)
            | (_, [_]) => (formatterDeclaration, formatterBinds)
            | (SOME btvEnv, _) =>(* polymorphic multiple recursive datatypes *)
              let
                val helperBinds =
                    map
                      (fn (formatterBind, tyCon) =>
                          generateInstantiatedFormatterForDatatype
                              context path btvEnv loc tyCon (#1 formatterBind))
                      (ListPair.zip (formatterBinds, tyCons))
                fun bindsToValIDExp (varPathInfo, _, exp) =
                    let val varInfo = U.varPathInfoToVarInfo varPathInfo
                    in (TY.VALIDVAR varInfo, exp) end
                val helperDeclaration =
                    TP.TPVAL (map bindsToValIDExp helperBinds, loc)
              in
                (
                  TP.TPLOCALDEC
                      ([formatterDeclaration], [helperDeclaration], loc),
                  helperBinds
                )
              end

(*
        val newContext =
            let
              (* If there are bound type variables found by generalize,
               * wrap the types of each binding into a POLYty.
               * And, strpath which is copied from the strpath of TyCon is
               * ignored, because that strpath is absolute path, but needed
               * in varPathInfo is relative path.
               *)
              val transInfo =
                  let
                    val transTy = 
                        case btvEnvOpt of
                          SOME btvEnv =>
                          (fn ty => TY.POLYty{boundtvars = btvEnv, body = ty})
                        | NONE => (fn ty => ty)
                  in
                    fn {name, strpath, ty} =>
                       {
                         name = name,
                         strpath = P.NilPath, (* *)
                         ty = transTy ty
                       }
                  end
            in
              foldl
                  (fn ((varPathInfo as {name, ...}, _, _), context) =>
                      TC.bindVarInContext
                          (context, name, (TY.VARID(transInfo varPathInfo))))
                  TC.emptyContext
                  formatterBinds
            end
*)
        val newContext = TC.emptyContext
      in
        (newContext, [declaration])
      end

  fun generateFormatterForDatatypes context path toPrint loc tyCons =
      generateFormatterForTyCons
          generateFormatterForDatatype context path toPrint loc tyCons

  fun generateFormatterForDatatypeReplication
      context currentPath toPrint loc (leftTyCon, relativePath, rightTyCon) =
      (* Assume a datatype replication
       *   datatype A = datatype B
       * Because the type inferencer replaces type constructor A with B in
       * type expressions so far, foramtter for A is unnecessary. *)
(*
      (TC.emptyContext, [])
*)
      let
        val (rightFormatterPath, rightFormatterName) =
            U.formatterPathNameOfTyCon currentPath rightTyCon
        val rightFormatterVarPathInfo =
            {
              name = rightFormatterName,
              strpath = rightFormatterPath,
              ty = U.generalize(OC.formatterOfTyConTy rightTyCon)
            }
        val rightFormatterExp = TP.TPVAR (rightFormatterVarPathInfo, loc)
        val (leftFormatterPath, leftFormatterName) =
            U.formatterPathNameOfTyCon currentPath leftTyCon
        val leftFormatterVarPathInfo =
            {
              name = leftFormatterName,
              strpath = leftFormatterPath,
              ty = U.generalize(OC.formatterOfTyConTy leftTyCon)
            }
        val leftFormatterVarInfo =
            U.varPathInfoToVarInfo leftFormatterVarPathInfo

        val valDeclaration =
            TP.TPVAL
                ([(TY.VALIDVAR leftFormatterVarInfo, rightFormatterExp)], loc)

(*
        val newContext =
            if toPrint
            then
              TC.bindVarInContext
                  (
                    context,
                    #name leftFormatterVarPathInfo,
                    TY.VARID leftFormatterVarPathInfo
                  )
            else context
*)
        val newContext = TC.emptyContext
      in
        (newContext, [valDeclaration])
      end

  fun generateFormatterForAbstype
          context
          currentPath
          currentTyCons
          loc
          (tyCon as {name, strpath, tyvars, datacon, ...} : TY.tyCon) =
      let
        (* ('X1->result) ->...-> ('Xn->result) -> ('X1,...,'Xn) t -> result *)
        val formatterTy = OC.formatterOfTyConTy tyCon
        (* 'X1 -> result, ..., 'Xn -> result, ('X1,...,'Xn) t *)
        val (formatterTyOfArgTys, argVarTy, _) =
            U.decompFunctionType (List.length tyvars) formatterTy

        (****** name of variable ids *************)
        (* format_ty *)
        val (formatterPath, formatterName) =
            U.formatterPathNameOfTyCon currentPath tyCon
        (* 'X1, ..., 'Xn *)
        val argTyVars =
            map
                (fn TY.FUNMty([TY.TYVARty(argTyVar)], _) => argTyVar)
                formatterTyOfArgTys
        (* format_'X1, ..., format_'Xn *)
        val formatterOfArgTys =
            map
                (fn (ref(TY.TVAR{id, ...})) =>
                    U.formatterNamePrefix ^ (Types.tidToString id))
                argTyVars

        val argVarName = U.makeVarName()
        val argVarPathInfo =
            {name = argVarName, ty = argVarTy, strpath = P.NilPath}

        val bodyExp = TP.TPCONSTANT (TY.STRING "-", loc)

        (* fn format_'X1 => ... fn format_'Xn => fn v => body *)
        val (formatterExp, resultTy) =
            foldr
            (fn ((name, ty), (fnExp, resultTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], resultTy)
                  val formatterOfArgVarPathInfo =
                      {name = name, ty = ty, strpath = P.NilPath}
                in
                  (
                    TP.TPFNM
                        {
                          argVarList = [formatterOfArgVarPathInfo],
                          bodyTy = resultTy,
                          bodyExp = fnExp,
                          loc = loc
                        },
                    formatterTy
                  )
                end)
            (
              TP.TPFNM
                  {
                    argVarList = [argVarPathInfo],
                    bodyTy = OC.formatterResultTy,
                    bodyExp = bodyExp,
                    loc = loc
                  },
              OC.formatterOfTyTy(argVarTy)
            )
            (ListPair.zip (formatterOfArgTys, formatterTyOfArgTys))
        val formatterVarPathInfo =
            {name = formatterName, strpath = strpath, ty = formatterTy}
      in
        (formatterVarPathInfo, formatterTy, formatterExp)
      end

  fun generateFormatterForAbstypes context path toPrint loc tyCons =
      generateFormatterForTyCons
          generateFormatterForAbstype context path toPrint loc tyCons

  (***************************************************************************)

  (* ToDo : generateFormatterForTyFun, generateFormatterForAbsType and
   * generateFormatterForTyCon can share their codes. *)

  (**
   * generates a formatter for a tyFun.
   * <p>
   * Assume the tyFun is generated from the following "type" declaration.
   *   <pre>type (tv1, ..., tvk) t = ty</pre>
   * A formatter is generated as follows.
   * <pre>
   *   val format_t format_tv1 ... format_tvk v = bodyExp
   * </pre>
   * <code>bodyExp</code> is an expression which formats a value <code>v</code>
   * of the type <code>(tv1, ..., tvk) t</code>. Value of type <code>tvi</code>
   * is formatted by an argument function <code>format_tvi</code>.
   * </p>
   *)
  fun generateFormatterForTyFun context path loc (TY.TYFUN tyFun) =
      let
        (* ('X1->result) ->...-> ('Xn->result) -> ('X1,...,'Xn) t -> result *)
        val monoFormatterTy = OC.formatterOfTyFunTy tyFun
(*
val _ = print
            ("formatterTy: " ^ TypeFormatter.tyToString monoFormatterTy ^ "\n")
*)
        val arity = IEnv.numItems (#tyargs tyFun)
        (* 'X1 -> result, ..., 'Xn -> result, ('X1,...,'Xn) t *)
        val (formatterTyOfArgTys, argVarTy, _) =
            U.decompFunctionType arity monoFormatterTy
        (* 'X1, ..., 'Xn *)
        val argTyVars =
            map
                (fn TY.FUNMty([TY.TYVARty(argTyVar)], _) => argTyVar)
                formatterTyOfArgTys
        (* format_'X1, ..., format_'Xn *)
        val formatterNameOfArgTys =
            map
                (fn (ref(TY.TVAR{id, ...})) =>
                    U.formatterNamePrefix ^ (Types.tidToString id))
                argTyVars

        (* v *)
        val argVarName = U.makeVarName ()
        val argVarPathInfo =
            {name = argVarName, strpath = P.NilPath, ty = argVarTy}
        val argVarExp = TP.TPVAR(argVarPathInfo, loc)

        (* format_s *)
        val argFormatterExp =
            generateFormatterOfTy
                context
                path
                []
                (ListPair.zip (argTyVars, formatterNameOfArgTys))
                loc
                argVarTy
        (* format_s v *)
        val bodyExp =
            TP.TPAPPM
                {funExp=argFormatterExp, 
                 funTy=OC.formatterOfTyTy argVarTy, 
                 argExpList=[argVarExp], 
                 loc=loc}

        (* fn format_'X1 => ... fn format_'Xn => fn v => body *)
        val (formatterExp, resultTy) =
            foldr
            (fn ((name, ty), (fnExp, resultTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], resultTy)
                  val formatterOfArgVarPathInfo =
                      {name = name, ty = ty, strpath = P.NilPath}
                in
                  (
                    TP.TPFNM
                        {
                          argVarList = [formatterOfArgVarPathInfo],
                          bodyTy = resultTy,
                          bodyExp = fnExp,
                          loc = loc
                        },
                    formatterTy
                  )
                end)
            (
              TP.TPFNM
                  {
                    argVarList = [argVarPathInfo],
                    bodyTy = OC.formatterResultTy,
                    bodyExp = bodyExp,
                    loc = loc
                  },
              OC.formatterOfTyTy(argVarTy)
            )
            (ListPair.zip (formatterNameOfArgTys, formatterTyOfArgTys))

        val (polyFormatterTy, polyFormatterExp) =
            case U.generalize monoFormatterTy of
              ty as TY.POLYty{boundtvars, body} =>
              (
                ty,
                TP.TPPOLY
                    {
                      btvEnv = boundtvars, 
                      expTyWithoutTAbs = body, 
                      exp = formatterExp, 
                      loc = loc
                    }
              )
            | _ => (monoFormatterTy, formatterExp)

        (* format_ty *)
        val formatterName = U.formatterNameOfTyName (#name tyFun)
        val formatterVarInfo =
            {name = formatterName, ty = polyFormatterTy}
      in
        TP.TPVAL([(TY.VALIDVAR formatterVarInfo, polyFormatterExp)], loc)
      end

  (**
   *  generates a code which updates format_exn to handle newly declared
   * exceptions.
   * <pre>
   * local
   *   val previous_formatter =
   *       case format_exnRef of ref formatExn => formatExn
   *   fun format exn =
   *       case exn of
   *           name1 arg => "name" ^ (format_ty1 arg)
   *              :
   *         | namen arg => "name" ^ (format_tyn arg)
   *         | exn => previous_formatter exn
   *   val _ = format_exnRef := format
   * in end
   * </pre>
   * NOTE: exception replications are ignored.
   *)
  fun generateFormatterForExnBinds context path toPrint loc exnBinds =
      let
        val conInfos =
            List.concat
                (map
                     (fn (TP.TPEXNBINDDEF conInfo) => [conInfo]
                       | TP.TPEXNBINDREP _ => [])
                     exnBinds)
        (* exn -> result *)
        val formatterTy = OC.formatterOfTyTy OC.exnTy
        (* argument of formatter *)
        val argVarName = U.makeVarName ()
        val argVarInfo = {name = argVarName, ty = OC.exnTy}
        val argVarPathInfo = U.varInfoToVarPathInfo argVarInfo
        val argVarExp = TP.TPVAR (argVarPathInfo, loc)

        (* D1 v1 => exp1, ... Dk vk => expk *)
        val branches =
            map
                (generateCaseBranchForConPathInfo context path [] loc [])
                conInfos

        (* previous formatter *)
        val previousFormatterName = U.makeVarName ()
        val previousFormatterVarInfo =
            {name = previousFormatterName, ty = formatterTy}
        val previousFormatterVarPathInfo =
            U.varInfoToVarPathInfo previousFormatterVarInfo
        val previousFormatterExp = TP.TPVAR (previousFormatterVarPathInfo, loc)
        (* | _ => previous_formatter arg *)
        val defaultBranch =
            (
              [TP.TPPATWILD(OC.exnTy, loc)],
              TP.TPAPPM
                  {
                    funExp = previousFormatterExp,
                    funTy = formatterTy,
                    argExpList = [argVarExp],
                    loc = loc
                  }
            )

        (* case (argVar : argVarTy) of pat => (exp : resultTy) *)
        val bodyExp = 
            TP.TPCASEM
            {
              expList = [argVarExp],
              expTyList = [#ty argVarInfo],
              ruleList = branches @ [defaultBranch],
              ruleBodyTy = OC.formatterResultTy,
              caseKind = TY.MATCH,
              loc = loc
            }
        (* fn v => body *)
        val formatterExp =
            TP.TPFNM
                {
                  argVarList = [argVarPathInfo],
                  bodyTy = OC.formatterResultTy,
                  bodyExp = bodyExp,
                  loc = loc
                }
        val formatterVarName = U.makeVarName ()
        val formatterVarInfo = {name = formatterVarName, ty = formatterTy}
        val formatterVarPathInfo = U.varInfoToVarPathInfo formatterVarInfo

        (* (exn -> result) ref *)
        val formatExnRefTy =
            TY.CONty{tyCon = OC.refTyCon, args = [formatterTy]}
        (* format_exnRef *)
        val formatExnRefVarPathInfo =
            {
              name = OC.nameOfFormatExnRef,
              strpath = OC.pathOfFormatExnRef,
              ty = formatExnRefTy
            }
        val formatExnRefExp = TP.TPVAR (formatExnRefVarPathInfo, loc)

        (* val previous_format =
         *     case formatExnRef of ref formatExn => formatExn *)
        local
          val tempVarName = U.makeVarName()
          val tempVarInfo = {name = tempVarName, ty = formatterTy}
          val tempVarPathInfo = U.varInfoToVarPathInfo tempVarInfo
        in
        val derefPreviousFormatterExp =
            TP.TPCASEM
            {
              expList = [formatExnRefExp],
              expTyList = [formatExnRefTy],
              ruleList =
              [(
                 [TP.TPPATCONSTRUCT
                      {
                        conPat = OC.refCon,
                        instTyList = [formatterTy],
                        argPatOpt = SOME(TP.TPPATVAR(tempVarPathInfo, loc)),
                        patTy = formatExnRefTy,
                        loc = loc
                      }],
                 TP.TPVAR (tempVarPathInfo, loc)
               )],
              ruleBodyTy = formatterTy,
              caseKind = TY.MATCH,
              loc = loc
            }
        end
        (* formatExnRef := foramt *)
        val updateFormatExnRefExp =
            TP.TPPRIMAPPLY
            {
              (* {ty = ['a.'a ref * 'a -> unit],...} *)
              primOp = OC.primInfoOfUpdateRef, 
              instTyList = [formatterTy],
              argExpOpt =
              SOME
                  (TP.TPRECORD
                   {
                     fields =
                     U.listToTupleSEnv
                         [
                           formatExnRefExp,
                           TP.TPVAR (formatterVarPathInfo, loc)
                         ],
                     recordTy =
                     TY.RECORDty
                         (U.listToTupleSEnv [formatExnRefTy, formatterTy]),
                     loc = loc
                   }),
              loc = loc
            }
        val binds =
            [
              TP.TPVAL
              (
                [(
                    TY.VALIDVAR previousFormatterVarInfo,
                    derefPreviousFormatterExp
                  )],
                loc
              ),
              TP.TPVALREC
                  (
                    [{
                       var =formatterVarInfo,
                       expTy = formatterTy,
                       exp = formatterExp
                     }],
                    loc
                  ),
              TP.TPVAL([(TY.VALIDWILD OC.unitTy, updateFormatExnRefExp)], loc)
            ]
      in
        (TC.emptyContext, [TP.TPLOCALDEC(binds, [], loc)])
      end

  (***************************************************************************)

end
