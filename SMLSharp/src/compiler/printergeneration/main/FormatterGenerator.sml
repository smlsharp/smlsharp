(**
 * This structure generates formatter declarations for type/datatype/exception
 * declarations.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FormatterGenerator.sml,v 1.61 2010/04/25 14:19:27 kiyoshiy Exp $
 *)
structure FormatterGenerator =
struct
local
  (***************************************************************************)

  structure A = Absyn
  structure FE = SMLFormat.FormatExpression
  structure NM = NameMap
  structure OC = ObjectCode
  structure P = Path
  structure PE = PatternCalc
  structure PT = PredefinedTypes
  structure TC = TypeContext
  structure TP = TypedCalc
  structure TU = TypesUtils
  structure TY = Types
  structure U = Utility

  (***************************************************************************)
in

  (**
   * return an expression whose value is the formatter for the specified type.
   * @params context currentTyCons BTVFormatters ty
   * @param context
   * @param currentTyConOpt current tycon, if any.
   * @param currentDataTyInfos dataTyInfos defined in the same 'datatype' declaration and whether 
   * @param TVFormatters list of pairs of
   *        <ul>
   *          <li>type variable (tvState ref)</li>
   *          <li>argument name which is bound to the formatter for the type
   *            to which the bound type variable is instantiated.</li>
   *        </ul>
   * @param ty the type of value to be formatted.
   * @return an expression which is evaluated to a formatter for the ty.
   *)
  fun generateFormatterOfTy
          basis path currentTyConOpt (currentDataTyInfos:Types.dataTyInfo list) TVFormatters loc ty =
      let
        (* This function returns
         *   fn argVar => bodyExp
         *)

        val (argVarName, argVarPathInfo, argVarExp) = U.makeVar (ty, loc)

        val bodyExp =
            generateFormatCode
                basis
                path
                currentTyConOpt
                currentDataTyInfos
                TVFormatters
                loc
                (argVarExp, ty)
      in
        TP.TPFNM
            {
              argVarList = [argVarPathInfo],
              bodyTy = OC.formatterResultTy,
              bodyExp = bodyExp,
              loc = loc
            }
      end

  (** make bodyExp.
   * Because recursive call is necessary to handle type variable and
   * POLYty, this is defined as a function. *)
  and generateFormatCode
          (basis:U.basis)
          path
          currentTyConOpt
          currentDataTyInfos
          TVFormatters
          loc
          (argExp, ty) =
      case ty of
        TY.SINGLETONty _ => OC.makeConstantTerm "SINGLETONty"

      |  TY.ERRORty => raise Control.Bug "unexpected ERRORty"

      | TY.DUMMYty _ =>
        TP.TPRAISE
            (OC.failException ("BUG:DUMMYty.", loc), OC.formatterResultTy, loc)

      | TY.TYVARty(ref (TY.SUBSTITUTED actualTy)) =>
        generateFormatCode
            basis
            path
            currentTyConOpt
            currentDataTyInfos
            TVFormatters
            loc
            (argExp, actualTy)

      | TY.TYVARty(ref (TY.TVAR tvKind)) =>
        (case
           List.find
               (fn (ref (TY.TVAR{id, ...}), _) => 
                    (FreeTypeVarID.eq(id, #id tvKind))
                 | _ =>
                   raise
                     Control.Bug
                         "non TVAR in TVFormatters \
                         \(printergeneration/main/FormatterGenerator.sml)")
               TVFormatters
          of
           SOME(_, TVFormatter) =>
           (* formatter of this variable is passed from the caller. *)
           let
             val TVFormatterTy = OC.tyOfFormatterOfTy ty
             val varInfo =
                 {
                   namePath = TVFormatter,
                   ty = TVFormatterTy
                 }
           in
             TP.TPAPPM
                 {
                   funExp = TP.TPVAR (varInfo, loc), 
                   funTy = TVFormatterTy, 
                   argExpList = [argExp], 
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

      | TY.FUNMty _ => OC.makeConstantTerm "fn"

      | TY.RECORDty fieldsMap =>
        if 0 = SEnv.numItems fieldsMap
        then OC.makeConstantTerm "()"
        else
          let
            val (makeExp, argVarExp) =
                case argExp
                 of TP.TPVAR _ =>
                    (* If argExp is variable expression, generates:
                     * generated code:
                     *  "("
                     *  ^ format (#l1 argExp)
                     *  ^ ","
                     *     :
                     *  ^ ","
                     *  ^ format (#ln argExp)
                     *  ^ ")"
                     *)
                    (fn exp => exp, argExp)
                  | _ =>
                    (* If argExp is not variable expression, generates:
                     *  let val v = argExp
                     *  in
                     *    "("
                     *    ^ format (#l1 v)
                     *    ^ ","
                     *       :
                     *    ^ ","
                     *    ^ format (#ln v)
                     *    ^ ")"
                     *  end
                     *)
                    let
                      val (_, varPathInfo, varExp) = U.makeVar (ty, loc)
                      fun makeExp exp =
                          TP.TPLET
                              (
                                [TP.TPVAL
                                  ([(TY.VALIDVAR varPathInfo, argExp)], loc)],
                                [exp],
                                [OC.formatExpressionTy],
                                loc
                              )
                    in
                      (makeExp, varExp)
                    end

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
                                  resultTy = polyFieldTy,
                                  loc = loc
                                },
                                polyFieldTy
                          )
                  val fieldFormatExp =
                      generateFormatCode
                          basis
                          path
                          currentTyConOpt
                          currentDataTyInfos
                          TVFormatters
                          loc
                          (fieldExp, fieldTy)
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
                                OC.translateFormatExpressions loc
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
                (hd fieldExps)
                :: (foldr
                        (fn (exp, joined) =>
                            OC.translateFormatExpressions loc
                                [FE.Term (1, ","), U.s_1_Indicator]
                            @ (exp :: joined))
                        []
                        (tl fieldExps))

            (* header and trailer which enclose the fields list *)
            val (left, right) = if isTuple then ("(", ")") else ("{", "}")
            val leftParenExps = 
                OC.translateFormatExpressions loc
                    [FE.Term (1, left), FE.StartOfIndent 2, U.ns_1_Indicator]
            val rightParenExps =
                OC.translateFormatExpressions loc
                    [FE.EndOfIndent, U.ns_1_Indicator, FE.Term (1, right)]
            val formatExp = 
                OC.makeGuard
                    (
                      SOME{cut = true, strength = 0, direction = FE.Neutral},
                      leftParenExps
                      @ [OC.makeGuard (NONE, joinedExps)]
                      @ rightParenExps
                    )
          in
            makeExp formatExp
          end

      | TY.RAWty{tyCon, args = argTys} =>
        if TyConID.eq(#id tyCon, #id PT.unitTyCon)
        then OC.makeConstantTerm "()"
        else
        if U.isHiddenTyCon basis path tyCon
        then OC.makeConstantTerm "-"
        else
          (case
             (
              (* true if this occurrence of tyCon is self-recursive. *)
              case (currentTyConOpt : TY.tyCon option)
               of NONE => false
                | SOME currentTyCon =>
                  TyConID.eq (#id tyCon, #id currentTyCon),

              (* true if this occurrence of tyCon is recursive. *)
              List.exists
                  (fn dataTyInfo => TyConID.eq (#id tyCon, #id (#tyCon dataTyInfo)))
                  currentDataTyInfos,

              argTys,

              (* true if this occurrence of tyCon is applied with type
               * variables which are exactly same with type variables that
               * appear in the definition of thie tycon.
               * For example, true for d in the former, false for the latter.
               *   datatype ('a, 'b) d = A of ('a, 'b) d | B
               *   datatype ('a, 'b) d = A of ('b, 'a) d | B
               *)
              List.all
                  (fn (
                        ref (TY.TVAR{id = id1, ...}),
                        TY.TYVARty(ref(TY.TVAR{id = id2, ...}))
                      )
                      => FreeTypeVarID.eq(id1, id2)
                    | _ => false)
                  (ListPair.zip (#1 (ListPair.unzip TVFormatters), argTys))
            )
            of
             (true, true, _::_, false) =>
             (* polymorphic self-recursive occurrence, but instantiated with
              * different types.
              * For example, occurrence of d in the argument of A is in this
              * case.
              *   datatype ('a, 'b) d = A of ('b, 'a) d | B
              * Current BUCTransformer cannot handle formatter generated for
              * this recursive datatype, so the formatter produce only "...".
              *)
             OC.makeConstantTerm "..."

           | (false, true, _::_, _) =>
             (* polymorphic mutual recursive occurrence.
              *)
             OC.makeConstantTerm "..."

           | (isSelfRecursive, isRecursive, _, _) =>
             let
              
               (* [f1,...,fn] *)
               val argFormatterExps =
                   map
                       (generateFormatterOfTy
                            basis
                            path
                            currentTyConOpt
                            currentDataTyInfos
                            TVFormatters
                            loc)
                       argTys
               (* [t1->r,...tn->r] *)
               val argFormatterTys = map OC.tyOfFormatterOfTy argTys
(*
val _ = print ("tyCon = " ^ pathToString(appendPath(#strpath tyCon, #name tyCon)) ^ "\n")
*)
               (* If the tyCon is recursive occurrence, the formatter for the
                * tyCon is referrred as local variable.
                * Otherwise, it is referred as global.
                * And these formatters is monotyped within the bodies of them.
                *)
               val formatterNamePath =
                   case U.formatterPathNameOfTyCon path tyCon of
                       (name, path) => 
                       (* Liu: Need to consult Yamatodani san.
                        *  Original: (name, if isRecursive then P.NilPath else path) 
                        *  After flattening in elaboration, variables are referred to
                        *  by global names.
                        * For the following code,
                        * structure A =
                        *   struct
                        *      datatype t = foo of s 
                        *      and s = bar of int
                        *   end
                        * After flattening,
                        *   datatype A.t = A.foo of A.s and A.s = A.bar of int 
                        * The original version generates the formatterNamePath _format_s,
                        * but the expected version should be A._format_s.
                        *)
                       (name, path)

               local
                 (* f : ['a1,...,'an.('a1->r)->...->('an->r)->('a1,...,'an)t->r
                  *)
                 val polyFormatterTy =
                     U.generalize(OC.tyOfFormatterOfDefinedTyCon tyCon)
               in
               (* formatter type which is instantiated with argument types.
                *   (t1->r)->...->(tn->r)->(t1,...,tn)t->r
                *)
               val instantiatedFormatterTy =
                   TU.tpappTy (polyFormatterTy, argTys)
                   
               (* type of formatter which is bound in static environment. *)
               val originalFormatterTy =
                   if isRecursive
                   then
                     (* recursive reference is monotype. *)
                     instantiatedFormatterTy 
                   else polyFormatterTy
               end

               val originalFormatterVarPathInfo = 
                   {namePath = formatterNamePath, ty = originalFormatterTy}

               val originalFormatterExp =
                   TP.TPVAR (originalFormatterVarPathInfo, loc)

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
                       (fn ((argFormatterExp,argFormatterTy),(funExp,funTy)) =>
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
val _ = print "====================\n"
val _ = print "generateFormatterOfTy\n"
val _ = print ("isRecursive = " ^ Bool.toString isRecursive ^ "\n")
val _ = print ("isSelfRecursive = " ^ Bool.toString isSelfRecursive ^ "\n")
val _ = (print "argTys: "; app (fn ty => print (TypeFormatter.tyToString ty ^ ",")) argTys; print "\n")
val _ = print "tyOfFormatterOfTyName: "
val _ = print (TypeFormatter.tyToString (OC.tyOfFormatterOfTyName tyName))
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
                     argExpList = [argExp],
                     loc = loc
                   }
             end)
      | TY.POLYty{body, boundtvars} =>
        let
          val (monoTy, _) = U.instantiateTy ty
          val formatterExp =
              generateFormatCode
                  basis
                  path
                  currentTyConOpt
                  currentDataTyInfos
                  TVFormatters
                  loc
                  (argExp, monoTy)
        in
          formatterExp
        end
          
      | TY.ALIASty(alias, actual) =>
        (* Use the formatter defined for the actual type.
         * No formatter is defined for the alias type.
         *)
        generateFormatCode
            basis
            path
            currentTyConOpt
            currentDataTyInfos
            TVFormatters
            loc
            (argExp, actual)

      | TY.OPAQUEty _ => OC.makeConstantTerm "-"

      (* this type is declared in functor parameter structure. *)
      | TY.SPECty ty => OC.makeConstantTerm "-"
        
  (***************************************************************************)

  fun generateCaseBranchForConPathInfo
          context
          path
          currentTyCon
          currentBoolDataTyInfos
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
              TY.POLYty{body = body as TY.FUNMty(_, TY.RAWty{args, ...}), ...}
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
        val conNamePath = #namePath conInfo
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
                | _ =>
                  raise
                    Control.Bug
                        "illformed funty \
                        \(printergeneration/main/FormatterGenerator.sml)"
            val (_, argVarPathInfo, argVarExp) = U.makeVar (polyArgVarTy, loc)
            val argVarPat = TP.TPPATVAR(argVarPathInfo, loc)
            (* D (v : s) : (s1, ..., sn) t *)
            val pat =
                TP.TPPATDATACONSTRUCT
                    {
                      conPat = conInfo, 
                      instTyList = argTys, 
                      argPatOpt = SOME argVarPat, 
                      patTy = tyConTy, 
                      loc = loc
                    }
            (* if v is a polymorphic, instantiate to a monotype exp. *)
            val (argVarExp, argVarTy) =
                U.instantiateExp(argVarExp, polyArgVarTy)
            (* formatted_v *)
            val argExp =
                generateFormatCode
                    context
                    path
                    currentTyCon
                    currentBoolDataTyInfos
                    formatterOfArgTys
                    loc
                    (argVarExp, argVarTy)
                    
            (* L1{ "D" +1 (formatted_v) } *)
            val conName = NM.usrNamePathToString(conNamePath)
            val exp =
                OC.makeGuard
                    (
                      SOME {cut = false, strength = 1, direction = FE.Left},
                      (OC.translateFormatExpressions loc
                           [FE.Term(size (conName), conName), U.s_1_Indicator])
                      @ [argExp]
                    )
          in ([pat], exp)
          end
        else
          (* D => "D" *)
          let
            val pat =
                TP.TPPATDATACONSTRUCT
                    {
                      conPat = conInfo, 
                      instTyList = argTys, 
                      argPatOpt = NONE, 
                      patTy = conTy, 
                      loc = loc
                    }
            val exp = OC.makeConstantTerm (NM.usrNamePathToString(conNamePath))
          in ([pat], exp)
          end
      end

  fun generateCaseBranchForExnPathInfo
          context
          path
          currentTyCon
          currentTyCons
          loc
          formatterOfArgTys
          (exnInfo : TY.exnPathInfo) =
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
            case #ty exnInfo of
              TY.POLYty{body = body as TY.FUNMty(_, TY.RAWty{args, ...}), ...}
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
        val conNamePath = #namePath exnInfo
        val argTys = map (fn (tyVar, _) => TY.TYVARty tyVar) formatterOfArgTys
      in
        if #funtyCon exnInfo
        then
          (* D (v : s) => "D" (format_s v) *)
          let
            (* argVarTy = s, tyConTy = (s1, ..., sn) t *)
            val (tyConTy, polyArgVarTy) =
                case conTy of
                  TY.FUNMty([argVarTy], tyConTy) => (tyConTy, argVarTy)
                | _ =>
                  raise
                    Control.Bug
                        "illformed funty \
                        \(printergeneration/main/FormatterGenerator.sml)"
            val (_, argVarPathInfo, argVarExp) = U.makeVar (polyArgVarTy, loc)
            val argVarPat = TP.TPPATVAR(argVarPathInfo, loc)
            (* D (v : s) : (s1, ..., sn) t *)
            val pat =
                TP.TPPATEXNCONSTRUCT
                    {
                      exnPat = exnInfo, 
                      instTyList = argTys, 
                      argPatOpt = SOME argVarPat, 
                      patTy = tyConTy, 
                      loc = loc
                    }
            (* if v is a polymorphic, instantiate to a monotype exp. *)
            val (argVarExp, argVarTy) =
                U.instantiateExp(argVarExp, polyArgVarTy)
            (* formatted_v *)
            val argExp =
                generateFormatCode
                    context
                    path
                    currentTyCon
                    currentTyCons
                    formatterOfArgTys
                    loc
                    (argVarExp, argVarTy)
            (* L1{ "D" +1 (formatted_v) } *)
            val conName = NM.usrNamePathToString(conNamePath)
            val exp = OC.makeGuard
                      (
                       SOME {cut = false, strength = 1, direction = FE.Left},
                       (OC.translateFormatExpressions loc
                            [FE.Term(size (conName), conName), U.s_1_Indicator])
                       @ [argExp]
                       )
          in ([pat], exp)
          end
        else
          (* D => "D" *)
          let
            val pat =
                TP.TPPATEXNCONSTRUCT
                    {
                      exnPat = exnInfo, 
                      instTyList = argTys, 
                      argPatOpt = NONE, 
                      patTy = conTy, 
                      loc = loc
                    }
            val exp = OC.makeConstantTerm (NM.usrNamePathToString(conNamePath))
          in ([pat], exp)
          end
      end

  (***************************************************************************)
  (*
   * param : boolCurrentDataTyInfos : bool represents isUserDefined. 
   *)
  fun generateFormatterForDatatype
          context
          currentPath
          currentBoolDataTyInfos
          loc
          ({tyCon as {name, strpath, tyvars, ...}, datacon} : TY.dataTyInfo) =
      let
        (* ('X1->result) ->...-> ('Xn->result) -> ('X1,...,'Xn) t -> result *)
        val formatterTy = OC.tyOfFormatterOfDefinedTyCon tyCon
        (* 'X1 -> result, ..., 'Xn -> result, ('X1,...,'Xn) t *)
        val (formatterTyOfArgTys, argVarTy, _) =
            U.decompFunctionType (List.length tyvars) formatterTy

        (****** name of variable ids *************)
        (* format_ty *)
        val formatterNamePath =
            U.formatterPathNameOfTyCon currentPath tyCon
        (* 'X1, ..., 'Xn *)
        val argTyVars =
            map
                (fn TY.FUNMty([TY.TYVARty(argTyVar)], _) => argTyVar
                  | _ => 
                    raise 
                      Control.Bug 
                          "non TVAR in formatterTyOfArgTys \
                          \(printergeneration/main/FormatterGenerator.sml)")
                formatterTyOfArgTys
        (* format_'X1, ..., format_'Xn *)
        val formatterOfArgTys =
            map
                (fn (ref(TY.TVAR{id, ...})) =>
                    (U.formatterNamePrefix ^ (FreeTypeVarID.toString id), P.NilPath)
                  | _ =>
                    raise
                      Control.Bug
                          "non TVAR in argTyVars \
                          \(printergeneration/main/FormatterGenerator.sml)")
                argTyVars

        val (_, argVarPathInfo, argVarExp) = U.makeVar (argVarTy, loc)
        (* D1 v1 => exp1, ... Dk vk => expk *)
        val branches =
            map
            (fn TY.CONID conPathInfo =>
                generateCaseBranchForConPathInfo
                    context
                    currentPath
                    (SOME tyCon)
                    currentBoolDataTyInfos
                    loc
                    (ListPair.zip(argTyVars, formatterOfArgTys))
                    (conPathInfo)
              | _ =>
                raise 
                  Control.Bug
                  "non CON in datacon \
                  \(printergeneration/main/FormatterGenerator.sml)")
            (SEnv.listItems (datacon))
        (* case (argVar : argVarTy) of pat => (exp : resultTy) *)
        val bodyExp = 
            TP.TPCASEM
            {
              expList = [argVarExp],
              expTyList = [argVarTy],
              ruleList = branches,
              ruleBodyTy = OC.formatterResultTy,
              caseKind = PatternCalc.MATCH,
              loc = loc
            }
        (* fn format_'X1 => ... fn format_'Xn => fn v => body *)
        val (formatterExp, resultTy) =
            foldr
            (fn ((namePath, ty), (fnExp, resultTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], resultTy)
                  val formatterOfArgVarPathInfo =
                      {namePath = namePath, ty = ty}
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
              OC.tyOfFormatterOfTy(argVarTy)
            )
            (ListPair.zip (formatterOfArgTys, formatterTyOfArgTys))
        val formatterVarPathInfo =
            {namePath = formatterNamePath, ty = formatterTy}
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
   * Their implementations are defined recursively as follows.
   * <pre>
   *  fun format_t format_a x =
   *      case x of 
   *        D x => "D" ^ (format_s format_a format_a x)
   *      | E x => "E" ^ (format_a x)
   *  and format_s format_a format_b x = 
   *      case x of
   *        F (x, y) => "F" ^ (format_t format_b x) ^ (format_a y);
   * </pre>
   * (NOTE: Internal generated code, including this one, assumes an extended
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
          context path BTVKindMap loc
          (dataTyInfo : TY.dataTyInfo)
          (formatterVarPathInfo : TY.varPathInfo) =
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
          val arity = List.length (#tyvars (#tyCon dataTyInfo))

        (* This function generates a new polymorphic function from an existing
         * formatter function.
         * Some compilation phase following this printer generation assumes
         * that every bound type variables have globally unique ID.
         * So, we cannot reuse bound type variables which are used in the
         * existing formatter function.
         * Here, we generate fresh-copies of these bound type variables, and
         * use them in the newly generated function.
         *)
        local
            val (subst, BTVKindMap) =
                TU.copyBoundEnv BTVKindMap
            val formatterTy = TU.substBTvar subst (#ty formatterVarPathInfo)
        in
        local
          fun getAppliedTys 0 (TY.FUNMty([TY.RAWty{args, ...}], _)) = args
            | getAppliedTys n (TY.FUNMty(_, resultTy)) =
              getAppliedTys (n - 1) resultTy
            | getAppliedTys _ _ =
              raise
                Control.Bug
                    "non FUNMty in getAppliedTys \
                    \(printergeneration/main/FormatterGenerator.sml)"
        in
          val appliedTys = map U.getRealTy (getAppliedTys arity formatterTy)
        end

        local
          fun isAppliedTy ID =
              List.exists 
              (fn (TY.BOUNDVARty BTVID) => ID = BTVID
                | _ =>
                  raise
                    Control.Bug
                        "non BOUNDVARty in appliedTys \
                        \(printergeneration/main/FormatterGenerator.sml)")
              appliedTys

          fun toBTVs dummyTyIndex [] newTys = List.rev newTys
            | toBTVs dummyTyIndex ((ID, BTVKind) :: tailBTVKinds) newTys =
              let
                val (newTy, dummyTyIndex) = 
                    if isAppliedTy ID
                    then (TY.BOUNDVARty ID, dummyTyIndex)
                    else (TY.DUMMYty dummyTyIndex, dummyTyIndex + 1)
              in toBTVs dummyTyIndex tailBTVKinds (newTy :: newTys)
              end
        in
        val replacedBoundTys =
            toBTVs 0 (BoundTypeVarID.Map.listItemsi BTVKindMap) []
        end

        local
          val newBTVKind =
              {recordKind = TY.UNIV, eqKind = TY.NONEQ}
        in
        val newBTVKindMap = 
            foldl (* left to right *)
                (fn (TY.BOUNDVARty ID, map) =>
                    BoundTypeVarID.Map.insert(map, ID, newBTVKind)
                  | _ =>
                    raise
                      Control.Bug
                          "non BOUNDVARty in appliedTys \
                          \(printergeneration/main/FormatterGenerator.sml)")
                BoundTypeVarID.Map.empty
                appliedTys
        end

        end (* local *)

        (****************************************)
        (* construct a function expression *)

        (* the argument to be formatted *)
        val argTy =
            TY.RAWty {tyCon = #tyCon dataTyInfo, args = appliedTys}
        val argVarPathInfo =
            {namePath = (U.makeVarName (), Path.NilPath), ty = argTy}
        val argExp = TP.TPVAR(argVarPathInfo, loc)
        (* formatter arguments: format_c1, ..., format_cn *)
        val argFormatterVarInfos =
            map
                (fn (ty as TY.BOUNDVARty index) =>
                    {
                      namePath =
                      (U.formatterNamePrefix ^ BoundTypeVarID.toString index,
                       P.NilPath),
                      ty = OC.tyOfFormatterOfTy ty
                    }
                  | _ =>
                    raise
                      Control.Bug
                          "non BOUNDVARty in appliedTys \
                          \(printergeneration/main/FormatterGenerator.sml)")
                appliedTys
        (* type applied formatter: format_t {...,'ci,..,'Xj,...} *)
        val polyFormatterVarPathInfo =
            {
              namePath = #namePath formatterVarPathInfo,
(*
              strpath = #strpath formatterVarPathInfo,
*)
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
                (OC.tyOfFormatterOfTy argTy)
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
            TP.TPVAR(varInfo, loc)
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
                )
              | _ =>
                raise
                  Control.Bug
                      "non FUNMty formatterTy \
                      \(printergeneration/main/FormatterGenerator.sml)")
            (monoFormatterExp, monoFormatterTy)
            argExps

        (* fn format_c1 => ... => fn format_cn => fn arg => bodyExp *)
        val (fnExp, fnTy) =
            foldr (* from right (= cn) to left (= c1) *)
            (fn ({namePath, ty}, (bodyExp, bodyTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], bodyTy)
                  val varPathInfo = {namePath = namePath, ty = ty}
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
              OC.tyOfFormatterOfTy(argTy)
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
              namePath = #namePath formatterVarPathInfo,
              ty = formatterTy
            }
      in
        (varPathInfo, formatterTy, formatterExp)
      end

  fun generateFormatterForDataTyInfos
          generateFormatterForDataTyInfo context path toPrint loc
          (dataTyInfos : Types.dataTyInfo list) =
      let
        val formatterBinds =
            map (generateFormatterForDataTyInfo context path dataTyInfos loc) dataTyInfos

        val TypesOfAllElements =  
            TY.RECORDty
                (foldr
                     (fn (({namePath = funId, ...}, ty, _), tyFields) =>
                         SEnv.insert(tyFields, NM.namePathToString(funId), ty))
                     SEnv.empty
                     formatterBinds)
        val btvEnvOpt =
            case U.generalize TypesOfAllElements of
              TY.POLYty{boundtvars, ...} => SOME boundtvars
            | _ => NONE

        local
          fun transDec (varPathInfo:TY.varPathInfo, ty, exp) =
              {var = varPathInfo, expTy = ty, exp = exp}
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
                        (fn (formatterBind, dataTyInfo) =>
                          generateInstantiatedFormatterForDatatype
                              context
                              path
                              btvEnv
                              loc
                              dataTyInfo
                              (#1 formatterBind))
                        (ListPair.zip (formatterBinds, dataTyInfos))
                fun bindsToValIDExp (varPathInfo, _, exp) =
                    (TY.VALIDVAR varPathInfo, exp) 
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
                       {name = name, strpath = P.NilPath, ty = transTy ty}
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

  fun generateFormatterForDatatypes context path toPrint loc boolDataTyInfos =
      generateFormatterForDataTyInfos
          generateFormatterForDatatype context path toPrint loc boolDataTyInfos

  fun generateFormatterForDatatypeReplication
          context currentPath toPrint loc 
          (leftDataTyInfo:TY.dataTyInfo, 
           relativePath, 
           rightDataTyInfo:TY.dataTyInfo) =
      (* Assume a datatype replication
       *   datatype A = datatype B
       * Because the type inferencer replaces type constructor A with B in
       * type expressions so far, foramtter for A is unnecessary. *)
(*
      (TC.emptyContext, [])
*)
      let
        val rightFormatterNamePath =
            U.formatterPathNameOfTyCon currentPath (#tyCon rightDataTyInfo)
        val rightFormatterVarPathInfo =
            {
             namePath = rightFormatterNamePath,
             ty = U.generalize(OC.tyOfFormatterOfDefinedTyCon (#tyCon rightDataTyInfo))
            }
        val rightFormatterExp = TP.TPVAR (rightFormatterVarPathInfo, loc)
        val leftFormatterNamePath =
            U.formatterPathNameOfTyCon currentPath (#tyCon leftDataTyInfo)
        val leftFormatterVarPathInfo =
            {
             namePath = leftFormatterNamePath,
             ty = U.generalize(OC.tyOfFormatterOfDefinedTyCon (#tyCon leftDataTyInfo))
            }
        val valDeclaration =
            TP.TPVAL
                ([(TY.VALIDVAR leftFormatterVarPathInfo, rightFormatterExp)], loc)

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
          ({tyCon = tyCon as {name, strpath, tyvars, ...}, datacon} : Types.dataTyInfo) =
      let
        (* ('X1->result) ->...-> ('Xn->result) -> ('X1,...,'Xn) t -> result *)
        val formatterTy = OC.tyOfFormatterOfDefinedTyCon tyCon
        (* 'X1 -> result, ..., 'Xn -> result, ('X1,...,'Xn) t *)
        val (formatterTyOfArgTys, argVarTy, _) =
            U.decompFunctionType (List.length tyvars) formatterTy

        (****** name of variable ids *************)
        (* format_ty *)
        val formatterNamePath =
            U.formatterPathNameOfTyCon currentPath tyCon
        (* 'X1, ..., 'Xn *)
        val argTyVars =
            map
                (fn TY.FUNMty([TY.TYVARty(argTyVar)], _) => argTyVar
                  | _ =>
                    raise
                      Control.Bug
                          "illeagal formatterTy \
                          \(printergeneration/main/FormatterGenerator.sml)")
                formatterTyOfArgTys
        (* format_'X1, ..., format_'Xn *)
        val formatterOfArgTys =
            map
                (fn (ref(TY.TVAR{id, ...})) =>
                    (U.formatterNamePrefix ^ FreeTypeVarID.toString id, P.NilPath)
                  | _ => 
                    raise 
                      Control.Bug 
                      "non TVAR in argTyVars \
                      \(printergeneration/main/FormatterGenerator.sml)")
                argTyVars

        val (argVarName, argVarPathInfo, _) = U.makeVar (argVarTy, loc)

        val bodyExp = OC.makeConstantTerm "-"

        (* fn format_'X1 => ... fn format_'Xn => fn v => body *)
        val (formatterExp, resultTy) =
            foldr
            (fn ((namePath, ty), (fnExp, resultTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], resultTy)
                  val formatterOfArgVarPathInfo =
                      {namePath = namePath, ty = ty}
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
              OC.tyOfFormatterOfTy(argVarTy)
            )
            (ListPair.zip (formatterOfArgTys, formatterTyOfArgTys))
        val formatterVarPathInfo =
            {namePath = formatterNamePath, ty = formatterTy}
      in
        (formatterVarPathInfo, formatterTy, formatterExp)
      end

  fun generateFormatterForAbstypes context path toPrint loc dataTyInfos =
      generateFormatterForDataTyInfos
          generateFormatterForAbstype context path toPrint loc dataTyInfos

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
        val monoFormatterTy = OC.tyOfFormatterOfTyFun tyFun
(*
val _ = print
            ("formatterTy: " ^ TypeFormatter.tyToString monoFormatterTy ^ "\n")
*)
        val arity = BoundTypeVarID.Map.numItems (#tyargs tyFun)
        (* 'X1 -> result, ..., 'Xn -> result, ('X1,...,'Xn) t *)
        val (formatterTyOfArgTys, argVarTy, _) =
            U.decompFunctionType arity monoFormatterTy
        (* 'X1, ..., 'Xn *)
        val argTyVars =
            map
                (fn TY.FUNMty([TY.TYVARty(argTyVar)], _) => argTyVar
                  | _ =>
                    raise
                      Control.Bug
                          "illeagal formatterTy \
                          \(printergeneration/main/FormatterGenerator.sml)")
                formatterTyOfArgTys
        (* format_'X1, ..., format_'Xn *)
        val formatterNameOfArgTys =
            map
                (fn (ref(TY.TVAR{id, ...})) =>
                    (U.formatterNamePrefix ^ (FreeTypeVarID.toString id), P.NilPath)
                  | _ => 
                    raise 
                      Control.Bug 
                          "non TVAR in argTyVars \
                          \(printergeneration/main/FormatterGenerator.sml)")
                argTyVars

        (* v *)
        val (_, argVarPathInfo, argVarExp) = U.makeVar (argVarTy, loc)

        (* formatted_v *)
        val bodyExp =
            generateFormatCode
                context
                path
                NONE
                []
                (ListPair.zip (argTyVars, formatterNameOfArgTys))
                loc
                (argVarExp, argVarTy)

        (* fn format_'X1 => ... fn format_'Xn => fn v => body *)
        val (formatterExp, resultTy) =
            foldr
            (fn ((namePath, ty), (fnExp, resultTy)) =>
                let
                  val formatterTy = TY.FUNMty([ty], resultTy)
                  val formatterOfArgVarPathInfo =
                      {namePath = namePath, ty = ty}
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
              OC.tyOfFormatterOfTy(argVarTy)
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
            {namePath = (formatterName, #strpath tyFun), ty = polyFormatterTy}
      in
        TP.TPVAL([(TY.VALIDVAR formatterVarInfo, polyFormatterExp)], loc)
      end
    | generateFormatterForTyFun _ _ _ _ =
      raise
        Control.Bug
            "non TYFUN to generateFormatterForTyFun \
            \(printergeneration/main/FormatterGenerator.sml)"


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
        val formatterTy = OC.tyOfFormatterOfTy PT.exnty
        (* argument of formatter *)
        val (_, argVarPathInfo, argVarExp) = U.makeVar (PT.exnty, loc)

        (* D1 v1 => exp1, ... Dk vk => expk *)
        val branches =
            map
                (generateCaseBranchForExnPathInfo context path NONE [] loc [])
                conInfos

        (* previous formatter *)
        val (_, previousFormatterVarInfo, previousFormatterExp) =
            U.makeVar (formatterTy, loc)

        (* | _ => previous_formatter arg *)
        val defaultBranch =
            (
              [TP.TPPATWILD(PT.exnty, loc)],
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
              expTyList = [#ty argVarPathInfo],
              ruleList = branches @ [defaultBranch],
              ruleBodyTy = OC.formatterResultTy,
              caseKind = PatternCalc.MATCH,
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
        val (_, formatterVarPathInfo, _) = U.makeVar (formatterTy, loc)

        (* (exn -> result) ref *)
        val formatExnRefTy =
            TY.RAWty {tyCon = PT.refTyCon, args = [formatterTy]}
        (* format_exnRef *)
        val formatExnRefVarPathInfo =
            {
              namePath = (OC.nameOfFormatExnRef, P.externPath),
              ty = formatExnRefTy
            }
        val formatExnRefExp = TP.TPVAR (formatExnRefVarPathInfo, loc)

        (* val previous_format =
         *     case formatExnRef of ref formatExn => formatExn *)
        local
          val (tempVarName, tempVarInfo, _) = U.makeVar(formatterTy, loc)
        in
        val derefPreviousFormatterExp =
            TP.TPCASEM
            {
              expList = [formatExnRefExp],
              expTyList = [formatExnRefTy],
              ruleList =
              [(
                 [TP.TPPATDATACONSTRUCT
                      {
                        conPat = PT.refConPathInfo,
                        instTyList = [formatterTy],
                        argPatOpt = SOME(TP.TPPATVAR(tempVarInfo, loc)),
                        patTy = formatExnRefTy,
                        loc = loc
                      }],
                 TP.TPVAR (tempVarInfo, loc)
               )],
              ruleBodyTy = formatterTy,
              caseKind = PatternCalc.MATCH,
              loc = loc
            }
        end
        (* formatExnRef := foramt *)
        val updateFormatExnRefExp =
            TP.TPPRIMAPPLY
            {
              (* {ty = ['a.'a ref * 'a -> unit],...} *)
              primOp = PredefinedTypes.assignPrimInfo,
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
                       var = formatterVarPathInfo,
                       expTy = formatterTy,
                       exp = formatterExp
                     }],
                    loc
                  ),
              TP.TPVAL([(TY.VALIDWILD PT.unitty, updateFormatExnRefExp)], loc)
            ]
      in
        (TC.emptyContext, [TP.TPLOCALDEC(binds, [], loc)])
      end

  (***************************************************************************)
end
end
