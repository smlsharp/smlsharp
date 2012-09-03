(**
 * Elaborator.
 * <p>
 * In this pahse, we do the following:
 * <ol>
 *   <li>infix elaboration</li>
 *   <li>expand derived form (incomplete; revise later)</li>
 * </ol>
 * </p>
 *
 * <hr>
 *
 * <h3>Infix resolution</h3>
 *
 * <h4>error check</h4>
 * <p>
 * About infix identifier, the Definition of Standard ML describes:
 * <blockquote>
 * (page 6) The only required use of op is in prefixing a non-infixed
 * occurrence of an identifier vid which has infix status; elsewhere op,
 * where permitted, has no effect.
 * </blockquote>
 * </p>
 * <p>
 * That means, if vid has infix status, occurrences of vid without using op:
 * <pre>
 *   elm vid elm
 * </pre>
 * are accepted (<code>elm</code> is an expression or a pattern either).
 * But non-infixed occurrences without using op:
 * <pre>
 *  vid
 *  ... elm vid
 *  vid elm ...
 * </pre>
 * are rejected.
 * </p>
 *
 * <hr>
 * <h3>expand derived form</h3>
 *
 * <h4><code>fun</code> declaration</h4>
 * <p>
 * A function declaration:
 * <pre>
 *   fun f p11 ... p1n = body1
 *              :       
 *     | f pm1 ... pmn = bodym
 * </pre>
 * is transformed to:
 * <pre>
 *   val rec f = fn x1 => ... fn xn =>
 *               (fn (p11, ..., p1n) => body1
 *                        :
 *                 | (pm1, ..., pmn) => bodym)
 *               (x1, ..., xn)
 * </pre>
 * </p>
 *
 * <h4><code>while</code> expression</h4>
 * <p>
 * A <code>while</code> expression
 * <pre>
 *   while cond do body
 * </pre>
 * is transformed into:
 * <pre>
 *   let
 *     val rec f =
 *             fn () =>
 *                  (fn true => (fn _ => f ()) body
 *                    | false => ())
 *                  cond
 *   in f () end
 * </pre>
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: Elaborator.sml,v 1.105 2008/08/24 03:54:41 ohori Exp $
 *)
structure Elaborator : ELABORATOR =
struct
local
  structure C = Control
  structure A = Absyn
  structure E = ElaborateError
  structure UE = UserError
  structure PC = PatternCalc
in

  datatype fixity = datatype Fixity.fixity

  (**
   * name given to an anonymous parameter signature of a functor.
   * Example:
   * <pre>
   *   functor F(type x) = struct datatype dt = D of x end
   * </pre>
   * is elaborated to:
   * <pre>
   *   functor F ('X : sig type x end) =
   *   let open 'X in struct datatype dt = D of x end end
   * </pre>
   *)
  val NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER = "'X"

  (***************************************************************************)

  local
    val errorQueue = UE.createQueue ()
  in
    fun initializeErrorQueue () = UE.clearQueue errorQueue
    fun getErrorsAndWarnings () = UE.getErrorsAndWarnings errorQueue
    fun getErrors () = UE.getErrors errorQueue
    fun getWarnings () = UE.getWarnings errorQueue
    val enqueueError = UE.enqueueError errorQueue
    val enqueueWarning = UE.enqueueWarning errorQueue
  end

(*
  fun isValue exp = 
    case exp of
      A.EXPCONSTANT _ => true
    | A.EXPID _ => true
    | A.EXPOPID _ => true
    | A.EXPFN _ => true
    | A.EXPTYPED (e, _, _) => isValue e
    | A.EXPAPP ([e], _) => isValue e
    | _ => false
*)

  (**************************************************************)

  local
    fun isReservedConstructorName name =
        case name of
          "true" => true
        | "false" => true
        | "nil" => true
        | "::" => true
        | "ref" => true
        | _ => false
  in
    fun checkReservedNameForConstructorBind (name, loc) =
      if isReservedConstructorName name orelse name = "it"
        then enqueueError(loc, E.BindReservedName name)
      else ()
    fun checkReservedNameForValBind (name, loc) =
      if isReservedConstructorName name
        then enqueueError(loc, E.BindReservedName name)
      else ()
  end

  fun getLabelOfPatRow (A.PATROWPAT(label, _, _)) = label
    | getLabelOfPatRow (A.PATROWVAR(label, _, _, _)) = label

  fun listToTuple list =
    #2
    (foldl
     (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
     (1, nil)
     list)

  fun elabFFIAttributes loc attr : A.ffiAttributes =
      foldl
        (fn (attr, attrs as {isPure,noCallback,allocMLValue,
                             callingConvention}) =>
            case attr of
              "cdecl" => {isPure = isPure,
                          noCallback = noCallback,
                          allocMLValue = allocMLValue,
                          callingConvention = SOME A.FFI_CDECL}
            | "stdcall" => {isPure = isPure,
                            noCallback = noCallback,
                            allocMLValue = allocMLValue,
                            callingConvention = SOME A.FFI_STDCALL}
            | "pure" => {isPure = true,
                         noCallback = noCallback,
                         allocMLValue = allocMLValue,
                         callingConvention = callingConvention}
            | "no_callback" => {isPure = isPure,
                                noCallback = true,
                                allocMLValue = allocMLValue,
                                callingConvention = callingConvention}
            | "callback" => {isPure = isPure,
                             noCallback = false,
                             allocMLValue = allocMLValue,
                             callingConvention = callingConvention}
            | "alloc" => {isPure = isPure,
                          noCallback = noCallback,
                          allocMLValue = true,
                          callingConvention = callingConvention}
            | "no_alloc" => {isPure = isPure,
                             noCallback = noCallback,
                             allocMLValue = false,
                             callingConvention = callingConvention}
            | _ =>
              (enqueueError (loc, E.UndefinedFFIAttribute {attr=attr});
               attrs))
        Absyn.defaultFFIAttributes
        attr

  (**
   * checks duplication in a set of names.
   * @params getName elements loc makeExn
   * @param getName a function to retriev name from an element. It should
   *               return NONE if no name is bound.
   * @param elements a list of element which contain a name in it.
   * @param loc location to be used in error message, if duplication found.
   * @param makeExn a function to construct an exception to be reported,
   *            if duplication found.
   * @return unit
   *)
  fun checkNameDuplication' getName elements loc makeExn =
    let
      fun collectDuplication names duplicates [] = SEnv.listItems duplicates
        | collectDuplication names duplicates (element :: elements) =
          case getName element of
            SOME name =>
              let
                val newDuplicates =
                  case SEnv.find(names, name) of
                    SOME _ => SEnv.insert(duplicates, name, name)
                  | NONE => duplicates
                val newNames = SEnv.insert(names, name, name)
              in collectDuplication newNames newDuplicates elements
              end
          | NONE => collectDuplication names duplicates elements
      val duplicateNames = collectDuplication SEnv.empty SEnv.empty elements
    in
      app (fn name => enqueueError(loc, makeExn name)) duplicateNames
    end
  (**
   * a variant of name duplicate checker.
   * getName parameter should return a string, instead of a string option.
   *)      
  fun checkNameDuplication getName elements loc makeExn =
      checkNameDuplication' (SOME o getName) elements loc makeExn

  fun substTyVarInTy substFun ty =
    let
      fun subst ty =
        case ty of
          A.TYID (tyVar, loc) => substFun (tyVar, loc)
        | A.TYRECORD (labelTys, loc) =>
            let
              val newLabelTys =
                map (fn (label, ty) => (label, subst ty)) labelTys
            in
              A.TYRECORD (newLabelTys, loc)
            end
        | A.TYCONSTRUCT_WITH_NAMEPATH (argTys, tyConPath, loc) =>
            raise Control.Bug "TYCONSTRUCT_WITH_NAMEPATH in Elaborator"
        | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
            let val newArgTys = map subst argTys
            in A.TYCONSTRUCT(newArgTys, tyConPath, loc)
            end
        | A.TYTUPLE(tys, loc) => A.TYTUPLE(map subst tys, loc)
        | A.TYFUN(rangeTy, domainTy, loc) =>
            A.TYFUN(subst rangeTy, subst domainTy, loc)
        | A.TYFFI(attrs, s, domTys, ranTy, loc) =>
            A.TYFFI(attrs, s, map subst domTys, subst ranTy, loc)
        | A.TYPOLY(tvarList, ty, loc) => 
            let
              val shadowNameList = map (fn ({name,...},_) => name) tvarList
              fun newSubstFun  (tyID as ({name, ...}, loc)) =
                if List.exists (fn x => x = name) shadowNameList then A.TYID tyID
                else substFun tyID
            in
              A.TYPOLY(tvarList, substTyVarInTy newSubstFun ty, loc)
            end
    in
      subst ty
    end

  fun replaceTyVarInTyWithTy (tyVars, argTys) ty =
      let
        val tyVarMap = 
            foldr
            (fn ((tyVar, destTy), map) => SEnv.insert(map, tyVar, destTy))
            SEnv.empty
            (ListPair.zip(tyVars, argTys))
        fun subst (tyID as ({name, eq}, loc)) =
            case SEnv.find(tyVarMap, name) of
              NONE =>
              (enqueueError(loc, E.NotBoundTyvar {tyvar = name}); A.TYID tyID)
            | SOME destTy => destTy
      in substTyVarInTy subst ty
      end

  fun expandWithTypesInDataBind (withTypeBinds : A.typbind list) =
      let
        val typeMap =
            foldr
            (fn (bind as (_, name, _), map) =>
                SEnv.insert(map, name, bind))
            SEnv.empty
            withTypeBinds
        fun expandInTy ty =
            case ty of
              A.TYID _ => ty
            | A.TYRECORD (labelTys, loc) =>
              let
                val newLabelTys =
                    map (fn (label, ty) => (label, expandInTy ty)) labelTys
              in
                A.TYRECORD (newLabelTys, loc)
              end
            | A.TYCONSTRUCT_WITH_NAMEPATH (argTys, tyConPath, loc) =>
              raise Control.Bug "TYCONSTRUCT_WITH_NAMEPATH in Elaborator"
            | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
              let val expandedArgTys = map expandInTy argTys
              in
                case tyConPath of
                  [tyConName] =>
                  (case SEnv.find (typeMap, tyConName) of
                     SOME (withTyVars, withName, withTy) =>
                     let
                       val withTyVarNames = map #name withTyVars
                       val withTyVarsLen = List.length withTyVars
                       val givenTyLen = List.length expandedArgTys
                     in
                        if withTyVarsLen = givenTyLen
                        then
                          replaceTyVarInTyWithTy
                              (withTyVarNames, expandedArgTys) withTy
                        else
                          let
                            val exn = 
                                E.ArityMismatchInTypeDeclaration
                                    {
                                      tyCon = withName,
                                      wants = withTyVarsLen,
                                      given = givenTyLen
                                    }
                          in
                            enqueueError(loc, exn); ty
                          end
                      end
                   | NONE => A.TYCONSTRUCT(expandedArgTys, tyConPath, loc))
                | _ => A.TYCONSTRUCT(map expandInTy argTys, tyConPath, loc)
              end
            | A.TYTUPLE(tys, loc) => A.TYTUPLE(map expandInTy tys, loc)
            | A.TYFUN(rangeTy, domainTy, loc) =>
              A.TYFUN(expandInTy rangeTy, expandInTy domainTy, loc)
            | A.TYFFI(attrs, s, domTys, ranTy, loc) =>
              A.TYFFI(attrs, s, map expandInTy domTys, expandInTy ranTy, loc)
            | A.TYPOLY(tvarList, ty, loc) => 
              A.TYPOLY(tvarList, expandInTy ty, loc)
        fun expandInDataCon (isOp, name, tyOpt) =
            let
              val newTyOpt =
                  case tyOpt of NONE => NONE | SOME ty => SOME(expandInTy ty)
            in (isOp, name, newTyOpt) end
      in
        fn (tvars, name, dataCons) =>
           (tvars, name, map expandInDataCon dataCons)
      end

  (**************************************************************)
  (* utility functions for infix resolution. *)

  (* Here, we assume the left-right scan so that the first param is the 
   * right of the second. 
   * In the case of conflict, we give a preference to the left.
   *)
  fun stronger (INFIX n, INFIX m) = n > m
    | stronger (INFIX n, INFIXR m) = n > m  
    | stronger (INFIXR n, INFIX m) = n > m  
    | stronger (INFIXR n, INFIXR m) = n >= m  
    | stronger (NONFIX, _) = raise Control.Bug "NONFIX in Elab.stronger"
    | stronger (_, NONFIX) = raise Control.Bug "NONFIX in Elab.stronger"
  fun findFixity (env : fixity SEnv.map) id =
      case SEnv.find (env, id) of SOME v => v | _ => NONFIX
  fun isNonfix env id =
      (case SEnv.find (env, id) of
         SOME NONFIX => true | NONE => true | _ => false)

  (**
   * operator information
   *)
  type 'a operator =
       {
         combiner : 'a * 'a -> 'a,
         left : Loc.pos,
         right : Loc.pos,
         status : fixity
       }

  (**
   *  translates a list of expressions or patterns into a nested application.
   * <p>
   * Occurrences of infix identifiers in it are associated with arguments of
   * its both sides, according to operator's strength of associativity.
   * To share the code between translation of expressions and of patterns,
   * this function takes some operators in parameter.
   * </p>
   * <p>
   * And this function also asserts that every infix identifier occurs only
   * at infix position. 
   * <p>
   *)
  fun 'a resolveInfix
         {makeApp, makeUserOp, elab, findFixity, getIDInfo}
         env
         elist =
      let
        (*  assert infix id does not occur at the first position or at the
         * last position in the list. *)
        (* ToDo : getIDInfo and findFixity should be merged ?
         * Both operates on ID term (EXPID/PATID). *)
        val (first, last) = (hd elist, List.last elist)
        val validFirst = 
            case findFixity env first of
              NONFIX => true
            | _ => let val (id, loc) = getIDInfo first
                   in enqueueError (loc, E.BeginWithInfixID id); false
                   end
        val validLast =
            case elist of
              [_] => true (* first and last is the same element. *)
            | _ =>
              case findFixity env last of
                NONFIX => true
              | _ => let val (id, loc) = getIDInfo last
                     in enqueueError (loc, E.EndWithInfixID id); false
                     end

        (* An infix ID used may not be a data constructor.
         * We do not reject at this point, since it will be rejected by 
         * the type checker later. 
         *)
        fun resolve [x] nil nil = x
          | resolve (h1 :: h2 :: args) ((op1 : 'a operator) :: ops) nil = 
            resolve (#combiner op1 (h2, h1) :: args) ops nil
          | resolve (h1 :: h2 :: args) (op1 :: ops) (lexp :: tail) = 
            (case findFixity env lexp of
               NONFIX =>
               resolve
               (makeApp (h1, elab env lexp) :: h2 :: args) (op1 :: ops) tail
             | x =>
               if stronger(x, #status op1)
               then
                 resolve
                     (elab env (hd tail) :: h1 :: h2 :: args)
                     (makeUserOp (elab env lexp) x :: op1 :: ops)
                     (tl tail)
               else
                 resolve (#combiner op1 (h2, h1) :: args) ops (lexp :: tail))
          | resolve (h1 :: args) nil (lexp :: tail) = 
            (case findFixity env lexp of
               NONFIX =>
               resolve (makeApp (h1, elab env lexp) :: args) nil tail
             | x =>
               resolve
                   (elab env (hd tail) :: h1 :: args)
                   [makeUserOp (elab env lexp) x]
                   (tl tail))
          | resolve _ _ _ = raise Control.Bug "Elab.resolveInfix"
      in
        if validFirst andalso validLast
        then
          resolve [elab env (hd elist)] nil (tl elist)
        else
          (* elist contains invalid infix occurrence, which aborts resolve.
           * So, after checking each element, it returns temporary result.
           *)
          hd (map (elab env) elist)
      end

    fun elabSequence elabolator env elements =
      let
        val (elaborateds, env) =
          foldl
          (fn (element, (elaborateds, env')) =>
           let
             val (elaborated, env'') =
               elabolator (SEnv.unionWith #1 (env', env)) element
           in
             (
              elaborated :: elaborateds,
              SEnv.unionWith #1 (env'', env')
              )
           end)
          (nil, SEnv.empty)
          elements
      in
        (List.concat(rev elaborateds), env)
      end

  fun truePat loc = PC.PLPATID(["true"], loc)
  fun falsePat loc = PC.PLPATID(["false"], loc)
  fun trueExp loc = PC.PLVAR(["true"], loc)
  fun falseExp loc = PC.PLVAR(["false"], loc)
  fun unitPat loc = PC.PLPATCONSTANT(A.UNITCONST loc, loc)
  fun unitExp loc = PC.PLCONSTANT(A.UNITCONST loc, loc)

  fun elabLabeledSequence elaborator env elements =
      map (fn (label, element) => (label, elaborator env element)) elements

  fun elabTy env ty =
      case ty of
        A.TYID _ => ty
      | A.TYRECORD (labelTys, loc) =>
        let val newLabelTys = elabLabeledSequence elabTy env labelTys
        in
          checkNameDuplication
              #1 labelTys loc E.DuplicateRecordLabelInRawType;
          A.TYRECORD (newLabelTys, loc)
        end
      | A.TYCONSTRUCT_WITH_NAMEPATH (argTys, tyConPath, loc) =>
        raise Control.Bug "TYCONSTRUCT_WITH_NAMEPATH in Elaborator"
      | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
        A.TYCONSTRUCT(map (elabTy env) argTys, tyConPath, loc)
      | A.TYTUPLE(tys, loc) => A.TYTUPLE(map (elabTy env) tys, loc)
      | A.TYFUN(rangeTy, domainTy, loc) =>
        A.TYFUN(elabTy env rangeTy, elabTy env domainTy, loc)
      | A.TYFFI(_, attrs, domTys, ranTy, loc) =>
        A.TYFFI(elabFFIAttributes loc attrs, nil,
                map (elabTy env) domTys, elabTy env ranTy, loc)
      | A.TYPOLY(tvarList, ty, loc) =>
        A.TYPOLY(tvarList, elabTy env ty, loc)

  fun elabConDesc env (name, NONE) = (name, NONE)
    | elabConDesc env (name, SOME ty) = (name, SOME(elabTy env ty))
  fun elabDataDesc loc env (tvars, name, conDescs) =
      let
        val _ = 
            checkNameDuplication
              #1 conDescs loc E.DuplicateConstructorNameInDatatype
      in
        (tvars, name, map (elabConDesc env) conDescs)
      end

  (**
   *  transforms infix application expression into non-infix application
   * expression.
   * This function also perform elaboration.
   *)
  fun resolveInfixExp env elist =
      let
        fun makeApp (x, y) =
            PC.PLAPPM(x, [y], (PC.getLeftPosExp x, PC.getRightPosExp y))
        fun makeUserOp lexp fixity =
            {
              status = fixity, 
              left = PC.getLeftPosExp lexp,
              right = PC.getRightPosExp lexp,
              combiner =
              fn (x, y) => 
                 let val loc = (PC.getLeftPosExp x, PC.getRightPosExp y)
                 in PC.PLAPPM(lexp, [PC.PLTUPLE([x, y], loc)], loc)
                 end
            }
        fun findFixity (env : fixity SEnv.map) lexp = 
            case lexp of
              A.EXPID (id, _) =>
              (case SEnv.find (env, A.longidToString(id)) of
                 SOME v => v | _ => NONFIX)
            | _ => NONFIX
        fun getIDInfo (A.EXPID (id, loc)) = (A.longidToString(id), loc)
          | getIDInfo exp = raise Control.Bug "getIDInfo expects EXPID."

      in
        resolveInfix
        {
          makeApp = makeApp,
          makeUserOp = makeUserOp,
          elab = elabExp,
          findFixity = findFixity,
          getIDInfo = getIDInfo
         }
        env
        elist
       end

  (**
   *  transforms infix constructor application pattern into non-infix
   * constructor application pattern.
   * This function also perform elaboration.
   *)
  and resolveInfixPat env elist =
      let
        fun makeApp (x, y) =
            PC.PLPATCONSTRUCT(x, y, (PC.getLeftPosPat x, PC.getRightPosPat y))
        fun makeUserOp lexp fixity =
            {
              status = fixity, 
              left = PC.getLeftPosPat lexp,
              right = PC.getRightPosPat lexp,
              combiner =
              fn (x, y) => 
                 let val loc = (PC.getLeftPosPat x, PC.getRightPosPat y)
                 in
                   PC.PLPATCONSTRUCT
                   (lexp, PC.PLPATRECORD(false, listToTuple [x, y], loc), loc)
                 end
            }
        fun findFixity (env : fixity SEnv.map) lexp = 
            case lexp of
              A.PATID {opPrefix=false, id, loc} => 
              (case (SEnv.find (env, A.longidToString(id))) of
                 SOME v => v | _ => NONFIX)
            | _ => NONFIX
        fun getIDInfo (A.PATID {opPrefix, id=id, loc=loc}) = (A.longidToString(id), loc)
          | getIDInfo pat = raise Control.Bug "getIDInfo expects PATID"

      in
        resolveInfix
        {
          makeApp = makeApp,
          makeUserOp = makeUserOp,
          elab = elabPat,
          findFixity = findFixity,
          getIDInfo = getIDInfo
         }
        env
        elist
      end

  (**
   *  translate header of infix function declarations to nonfix declaration
   * using "op" modifier.
   * <p>
   * To be translated is declaration which takes two arguments and whose
   * first argument is ID declared infix. If they are enclosed by parenthesis,
   * they are translated also.</p>
   * <p>
   * Assume <code>id</code> has infix status. Then, translates from:
   * <pre>
   * (Case 1)  fun p1 id p2 p3 ... pn = exp
   * </pre>
   * <pre>
   * (Case 2)  fun (p1 id p2) p3 ... pn = exp
   * </pre>
   * to:
   * <pre>
   *   fun (op id) (p1, p2) p3 ... pn = exp
   * </pre>
   * If both Case 1 and Case 2 apply, Case 1 has priority over Case 2.
   * For example:
   * <pre>
   *   fun (x %% y) ## z = x + y + z;
   * </pre>
   * This is interpreted as a definition of <code>##</code>.
   * </p>
   * <p>
   * For other cases, do nothing.
   * </p>
   *)
  and resolveFunDecls env fdecls =
      let
        fun make2TuplePat (leftPat, rightPat) =
            let
              val leftLoc = A.getLocPat leftPat
              val rightLoc = A.getLocPat rightPat
            in
              A.PATRECORD
                  {
                   ifFlex= false,
                    fields=
                    [
                      A.PATROWPAT("1", leftPat, leftLoc),
                      A.PATROWPAT("2", rightPat, rightLoc)
                    ],
                    loc = Loc.mergeLocs (leftLoc, rightLoc)
                  }
            end

        (**
         *  picks up the function ID.
         * And asserts that it is nonfix id or infix id with "op" modifier.
         *  For other arguments, the resolveInfixPat will check that no infix
         * ID is used without "op".
         *)
        fun transNonfixForm (pats, tyOpt, exp) =
            case pats of
              A.PATID {opPrefix=opf, id=fid, loc=loc} :: argPats =>
              if
                (case findFixity env (A.longidToString(fid)) of
                   NONFIX => true | _ => opf)
              then (opf, fid, argPats, tyOpt, exp)
              else
                (
                  enqueueError
                      (loc, E.InfixUsedWithoutOP (A.longidToString(fid)));
                  (opf, fid, argPats, tyOpt, exp)
                )
            | _ =>
              (
                enqueueError (A.getLocPat (hd pats), E.IllegalFunctionSymbol);
                (false, ["<dummy>"], tl pats, tyOpt, exp)
              )

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase2 (args, tyOpt, exp) =
             case args of
               A.PATAPPLY([leftArg, A.PATID {opPrefix=false, id, loc}, rightArg], _)
               :: otherArgs =>
               (case findFixity env (A.longidToString(id)) of
                  NONFIX => transNonfixForm (args, tyOpt, exp)
                | _ =>
                  let val newArg = make2TuplePat(leftArg, rightArg)
                  in (true, id, newArg :: otherArgs, tyOpt, exp)
                  end)
             | _ => transNonfixForm (args, tyOpt, exp)

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase1 (args, tyOpt, exp) =
             case args of
               leftArg :: (A.PATID {opPrefix=false, id, loc}) :: rightArg :: otherArgs =>
               (case findFixity env (A.longidToString(id)) of
                  NONFIX => resolveCase2 (args, tyOpt, exp)
                | _ =>
                  let val newArg = make2TuplePat(leftArg, rightArg)
                  in (true, id, newArg :: otherArgs, tyOpt, exp)
                  end)
             | _ => resolveCase2 (args, tyOpt, exp)
      in
        map resolveCase1 fdecls
      end

  and elabFunDecls loc env fdecls =
      let
        val (opfs, fids, args, exps) = 
            foldr
                (fn ((opf, fid, arg, optTy, exp), (opfs, fids, args, exps)) =>
                    let
                      (*   fun id pat .. pat : ty = exp
                       * is a derived form equivalent to
                       *   fun id pat .. pat = exp : ty
                       *)
                      val typedExp =
                          case optTy of
                            NONE => exp
                          | SOME ty => A.EXPTYPED(exp, ty, loc)
                      val newExp = elabExp env typedExp
                      val newArg = map (elabPat env) arg
                    in
                      (opf :: opfs, fid :: fids, newArg :: args, newExp :: exps)
                    end)
                (nil, nil, nil, nil)
                fdecls

        val fid = hd fids
        val _ =
            if List.all (fn x => x = fid) fids
            then ()
            else
              (* ToDo : more specific location should be passed. *)
              enqueueError (loc, E.NotAllHaveFunctionName)

        val argNum = length (hd args)
        val _ =
            if List.all (fn x => length x = argNum) args
            then ()
            else enqueueError (loc, E.NotAllHaveSameNumberPatterns)
        val _ =
            if 0 = argNum
            then enqueueError (loc, E.FunctionParameterNotFound)
            else ()

        val fdecl = (PC.PLPATID (fid, loc), ListPair.zip (args,exps))
(*
        val funBody = 
            if length (hd args) = 1
            then
              (* fun f pat = exp
               *     :  :     :
               *   | f pat = exp
               *)
              PC.PLFNM(ListPair.zip (args, exps), loc)
            else
              if length args = 1
              then
                (* fun f pat ... pat = exp *)
                foldr (fn (x, y) => PC.PLFNM([([x], y)], loc)) (hd exps) (hd args)
              else
                (* fun f pat ... pat = exp
                 *     :  :       :     :
                 *   | f pat ... pat = exp
                 *)
                let
                  val newNames = map (fn x => Vars.newPLVarName()) (hd args) 
                  val newVars = map (fn x => PC.PLVAR([x], loc)) newNames
                  val newVarPats = map (fn x => PC.PLPATID([x], loc)) newNames
                  val argRecord = PC.PLRECORD (listToTuple newVars, loc)
                  val argpats =
                      map
                          (fn args =>
                              PC.PLPATRECORD(false, listToTuple args, loc))
                          args
                in
                  foldr
                      (fn (x, y) =>PC.PLFNM([([x], y)], loc))
                      (PC.PLAPPM
                           (
                             PC.PLFNM(ListPair.zip (argpats, exps), loc),
                             [argRecord],
                            loc
                          ))
                      newVarPats
                end
*)
      in
        fdecl
      end

  and elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc) =
      let
        fun elabDataCon (isOp, name, NONE) = (isOp, name, NONE)
          | elabDataCon (isOp, name, SOME ty) =
            (isOp, name, SOME(elabTy env ty))
        fun elabDataBind (tvars, name, dataCons) =
            (tvars, name, map elabDataCon dataCons)
        fun elabTypeBind (tvars, name, ty) = (tvars, name, elabTy env ty)

        val dataCons =
            List.concat (map (fn (_, _, dataCons) => dataCons) dataBinds)
        val boundTypeNames = (map #2 dataBinds) @ (map #2 withTypeBinds)
        fun id x = x
        val _ =
            checkNameDuplication
                id boundTypeNames loc E.DuplicateTypeNameInDatatype
        val _ =
            checkNameDuplication
                #2 dataCons loc E.DuplicateConstructorNameInDatatype
        val _ =
            app
                (fn dataCon =>
                    checkReservedNameForConstructorBind(#2 dataCon, loc))
                dataCons

        val newDataBinds = map elabDataBind dataBinds
        val newWithTypeBinds = map elabTypeBind withTypeBinds
        val expandedDataBinds =
            map (expandWithTypesInDataBind newWithTypeBinds) newDataBinds
      in
        (expandedDataBinds, newWithTypeBinds)
      end

  and elabExp env ast = 
      case ast of 
        A.EXPCONSTANT x => PC.PLCONSTANT x
      | A.EXPGLOBALSYMBOL x => PC.PLGLOBALSYMBOL x
      | A.EXPID (x,loc) => PC.PLVAR (x,loc)
      | A.EXPOPID (x,loc) => PC.PLVAR (x,loc)
      | A.EXPRECORD (stringExpList, loc) =>
        (
          checkNameDuplication #1 stringExpList loc E.DuplicateRecordLabel;
          PC.PLRECORD (elabLabeledSequence elabExp env stringExpList, loc)
        )
      | A.EXPRECORD_UPDATE (exp, stringExpList, loc) =>
        (
          checkNameDuplication #1 stringExpList loc E.DuplicateRecordLabel;
          PC.PLRECORD_UPDATE
          (
            elabExp env exp,
            elabLabeledSequence elabExp env stringExpList,
            loc
          )
        )
      | A.EXPRECORD_SELECTOR (x, loc) =>  PC.PLRECORD_SELECTOR(x, loc)
      | A.EXPTUPLE (elist, loc) => PC.PLTUPLE(map (elabExp env) elist, loc)
      | A.EXPLIST (elist, loc) => 
        if !C.doListExpressionOptimization then
          PC.PLLIST(map (elabExp env) elist, loc)
        else
          let
            fun folder (x, y) =
              PC.PLAPPM
              (PC.PLVAR(["::"], loc), [PC.PLTUPLE([elabExp env x, y], loc)], loc)
            val plexp = foldr folder (PC.PLVAR(["nil"], loc)) elist
          in
            plexp
          end
      | A.EXPAPP (elist, loc) => resolveInfixExp env elist
      | A.EXPSEQ (elist, loc) => PC.PLSEQ(map (elabExp env) elist, loc)
      | A.EXPTYPED (exp, ty, loc) =>
        PC.PLTYPED (elabExp env exp, elabTy env ty, loc)
      | A.EXPCONJUNCTION (e1, e2, loc) =>
        let
          val ple1 = elabExp env e1
          val ple2 = elabExp env e2
        in
          PC.PLAPPM
          (
            PC.PLFNM([([truePat loc], ple2), ([falsePat loc], falseExp loc)], loc),
            [ple1],
            loc
          )
        end
      | A.EXPDISJUNCTION (e1, e2, loc) =>
        let
          val ple1 = elabExp env e1
          val ple2 = elabExp env e2
        in
          PC.PLAPPM
          (
            PC.PLFNM ([([truePat loc], trueExp loc), ([falsePat loc], ple2)], loc),
            [ple1],
            loc
          )
        end
      | A.EXPHANDLE (e1, match, loc) =>
        PC.PLHANDLE
            (
              elabExp env e1,
              map (fn (x, y) => (elabPat env x, elabExp env y)) match,
              loc
            )
      | A.EXPRAISE (e, loc) =>PC.PLRAISE(elabExp env e, loc)
      | A.EXPIF (e1, e2, e3, loc) =>
        let
          val ple1 = elabExp env e1
          val ple2 = elabExp env e2
          val ple3 = elabExp env e3
        in
          PC.PLCASEM
          ([ple1], [([truePat loc], ple2), ([falsePat loc], ple3)], PC.MATCH, loc)
        end
      | A.EXPWHILE (condExp, bodyExp, loc) =>
        let
          val newid = VarNameGen.generate ()
          val condPl = elabExp env condExp
          val bodyPl = elabExp env bodyExp
          (* (fn _ => newid ()) body *)
          val whbody =
              PC.PLAPPM
              (
                PC.PLFNM
                (
                  [
                    (
                      [PC.PLPATWILD loc],
                      PC.PLAPPM(PC.PLVAR([newid], loc), [unitExp loc], loc)
                    )
                  ],
                  loc
                ),
                [bodyPl],
                loc
              )
          (* fn () => (fn true => whbody | false => ()) cond *)
          val body =
              PC.PLFNM
              (
                [
                  (
                    [unitPat loc],
                    PC.PLAPPM
                    (
                      PC.PLFNM
                      (
                        [([truePat loc], whbody), ([falsePat loc], unitExp loc)],
                        loc
                      ),
                      [condPl],
                      loc
                    )
                  )
                ],
                loc
              )
        in
          PC.PLLET
          (
            [PC.PDVALREC(nil, [(PC.PLPATID([newid], loc), body)], loc)],
            [PC.PLAPPM(PC.PLVAR([newid], loc), [unitExp loc], loc)],
            loc
          )
        end
      | A.EXPCASE (objectExp, match, loc) =>
        PC.PLCASEM
        (
          [elabExp env objectExp],
          map (fn (x, y) => ([elabPat env x], elabExp env y)) match,
          PC.MATCH,
          loc
        )
      | A.EXPFN (match, loc) =>
        PC.PLFNM(map (fn (x, y) => ([elabPat env x], elabExp env y)) match, loc)
      | A.EXPLET (decs, elist, loc) => 
        let
          val (pdecs, env') = elabDecs env decs
          val newEnv = SEnv.unionWith #1 (env',env)
        in
          PC.PLLET (pdecs, map (elabExp newEnv) elist, loc)
        end
      | A.EXPCAST (exp,loc) => PC.PLCAST(elabExp env exp, loc)
      | A.EXPFFIIMPORT (exp, ty, loc) =>
        (case ty of A.TYFFI _ => ()
                  | _ => enqueueError (loc, E.NotForeignFunctionType {ty=ty});
         PC.PLFFIIMPORT (elabExp env exp, elabTy env ty, loc))
      | A.EXPFFIEXPORT (exp, ty, loc) =>
        (case ty of A.TYFFI _ => ()
                  | _ => enqueueError (loc, E.NotForeignFunctionType {ty=ty});
         PC.PLFFIEXPORT (elabExp env exp, elabTy env ty, loc))
      | A.EXPFFIAPPLY (attrs, funExp, args, retTy, loc) =>
        PC.PLFFIAPPLY (elabFFIAttributes loc attrs,
                       elabExp env funExp,
                       map (fn A.FFIARG (exp, ty, loc) =>
                               PC.PLFFIARG (elabExp env exp, elabTy env ty, loc)
                             | A.FFIARGSIZEOF (ty, SOME exp, loc) =>
                               PC.PLFFIARGSIZEOF (elabTy env ty,
                                                  SOME (elabExp env exp),
                                                  loc
                                                  )
                             | A.FFIARGSIZEOF (ty, NONE, loc) =>
                               PC.PLFFIARGSIZEOF (elabTy env ty, NONE, loc))
                           args,
                       elabTy env retTy, loc)

  and elabPat env pat = 
      case pat of
        A.PATWILD loc => PC.PLPATWILD loc
      | A.PATCONSTANT (x as (constant, loc)) =>
        (case constant of
           A.REAL (_, loc) =>
           (* According to syntactic restriction of ML Definition, real
            * constant pattern is not allowed. *)
           (enqueueError (loc, E.RealConstantInPattern); PC.PLPATCONSTANT x)
         | _ => PC.PLPATCONSTANT x)
      | A.PATID {opPrefix=b, id, loc} => PC.PLPATID (id, loc)
      | A.PATAPPLY (plist, loc) => resolveInfixPat env plist
      | A.PATRECORD {ifFlex=flex, fields=pfields, loc=loc} =>
        (
          checkNameDuplication
              getLabelOfPatRow pfields loc E.DuplicateRecordLabelInPat;
          PC.PLPATRECORD (flex, map (elabPatRow env) pfields, loc)
        )
      | A.PATTUPLE (plist, loc) =>
        PC.PLPATRECORD (false, listToTuple (map (elabPat env) plist), loc)
      | A.PATLIST (elist, loc) =>
        let
          val plexp =
              foldr
              (fn (x, y) =>
                  PC.PLPATCONSTRUCT
                  (
                    PC.PLPATID(["::"], loc),
                    PC.PLPATRECORD(false, listToTuple [elabPat env x, y], loc),
                    loc
                  ))
              (PC.PLPATID(["nil"], loc))
              elist
        in
          case plexp of
            PC.PLPATID(x, l) => PC.PLPATID(x, loc)
          | PC.PLPATCONSTRUCT(x, y, l) => PC.PLPATCONSTRUCT(x, y, loc)
          | _ => raise Control.Bug "elab EXPLIST"
        end
      | A.PATTYPED (pat, ty, loc) =>
        PC.PLPATTYPED(elabPat env pat, elabTy env ty, loc)
      | A.PATLAYERED (A.PATID {opPrefix=b, id=path, loc=loc1}, pat, loc) =>
        let
          val _ =
              if A.isShortId path
              then ()
              else enqueueError (loc, E.LeftOfASMustBeVariable)
          val id = A.longidToString(path)
        in
          checkReservedNameForValBind (id, loc1);
          PC.PLPATLAYERED(id, NONE, elabPat env pat, loc)
        end
      | A.PATLAYERED
            (A.PATTYPED
                 (A.PATID{opPrefix, id=path, loc=loc1}, ty, loc2), pat, loc) =>
        let
          val _ =
              if A.isShortId path
              then ()
              else enqueueError (loc, E.LeftOfASMustBeVariable)
          val id = A.longidToString(path)
          val elabedTy = elabTy env ty
          val elabedPat = elabPat env pat
        in
          checkReservedNameForValBind (id, loc1);
          PC.PLPATLAYERED(id, SOME elabedTy, elabedPat, loc)
        end
      | A.PATLAYERED
            (A.PATTYPED(A.PATAPPLY([pat], _), ty, loc1), pat2, loc2) =>
        (* The first argument of PATLAYERED and PATTYPED is always be PATAPPLY 
         * (see iml.grm). This is because sequence of at least one pat should
         * be checked for infix occurrence.
         *)
        elabPat env (A.PATLAYERED(A.PATTYPED(pat, ty, loc1), pat2, loc2))
      | A.PATLAYERED (A.PATAPPLY([pat], _), pat2, loc2) =>
        elabPat env (A.PATLAYERED(pat, pat2, loc2))
      | A.PATLAYERED (pat1, pat2, loc2) =>
        (
          enqueueError (loc2, E.LeftOfASMustBeVariable);
          elabPat env pat1;
          elabPat env pat2
        )
      | A.PATORPAT (pat1, pat2, loc2) =>
        PC.PLPATORPAT(
                      elabPat env pat1,
                      elabPat env pat2,
                      loc2
                      )

    and elabPatRow env patrow =
        case patrow of
          (* label = pat *)
          A.PATROWPAT (id, pat, loc) => (id, elabPat env pat)
        (* label < : ty > < as pat > *)
        | A.PATROWVAR (id, optTy, optPat, loc) => 
          let
            val _ = checkReservedNameForValBind (id, loc)
            val newOptTy =
                case optTy of NONE => NONE | SOME ty => SOME(elabTy env ty)
            val pat =
                case optPat of
                  SOME pat => PC.PLPATLAYERED(id, newOptTy, elabPat env pat,loc)
                | _ =>
                  case newOptTy of
                    SOME ty => PC.PLPATTYPED (PC.PLPATID([id], loc), ty, loc)
                  | _ => PC.PLPATID([id], loc)
          in (id, pat)
          end

    and elabDec env dec = 
        case dec of
          A.DECVAL (tyvs, decls, loc) =>
          let
            val newDecls =
                map (fn (pat, e) => (elabPat env pat, elabExp env e)) decls
          in
            ([PC.PDVAL (tyvs, newDecls, loc)], SEnv.empty)
          end
        | A.DECREC (tyvs, decls, loc) =>
          let
            (* right hand side of val rec must be "fn". *)
            fun assertExp (A.EXPFN _) = ()
              | assertExp exp = enqueueError (loc, E.NotFnBoundInValRec)
            (* check pattern AFTER elaboration, because even single var pattern
             * is parsed as application pattern. *)
            fun assertPattern pat =
                case pat of
                  PC.PLPATWILD _ => 
                  enqueueError(loc, E.NonVariablePatternInValRec)
                | PC.PLPATID _ => ()
                | PC.PLPATLAYERED(name, _, rightPat, _) => 
                  enqueueError(loc, E.NonVariablePatternInValRec)
                | PC.PLPATTYPED(innerPat, _, _) => assertPattern innerPat
                | _ => enqueueError(loc, E.NonVariablePatternInValRec)
            fun elabBind (pat, exp) =
                let
                  val elabedPat = elabPat env pat
                  val elabedExp = elabExp env exp
                in
                  assertPattern elabedPat; (* after elab *)
                  assertExp exp; (* before elab *)
                  (elabedPat, elabedExp)
                end
            fun getNameOfBound (PC.PLPATID(name, _), _) =
                SOME(A.longidToString name)
              | getNameOfBound (PC.PLPATTYPED (pat, _, _), exp) =
                getNameOfBound (pat, exp)
              | getNameOfBound (pat, _) =
                (* this case will be rejected by the above assertPat. *)
                NONE
            val elabedBinds = map elabBind decls
            val _ =
                checkNameDuplication' (* NOTE: use primed version. a trick. *)
                    getNameOfBound
                    elabedBinds
                    loc
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDVALREC(tyvs, elabedBinds, loc)], SEnv.empty)
          end
        | A.DECFUN (tyvs, fbinds, loc) =>
          let
            val elabFBind = elabFunDecls loc env o resolveFunDecls env
            val elabedFunBinds = map elabFBind fbinds
            fun getNameOfBind (PC.PLPATID (name, _), _) = A.longidToString name
              | getNameOfBind _ =
                raise Control.Bug "not PATID nor PATTYPED getNameOfBound"
            val _ =
                checkNameDuplication
                    getNameOfBind
                    elabedFunBinds
                    loc
                    E.DuplicateVarNameInValRec
          in ([PC.PDDECFUN (tyvs, elabedFunBinds, loc)], SEnv.empty)
          end
        | A.DECTYPE (tyBinds, loc) =>
          let
            fun elabTyBind (tvars, name, ty) =
                let
                  val newTVars =
                      map (fn {name=tvarName, eq} => {name=tvarName, eq=A.NONEQ}) tvars
                  val newTy =
                      substTyVarInTy
                          (fn ({name=tvarName, eq}, loc) =>
                              A.TYID({name=tvarName, eq=A.NONEQ}, loc))
                          ty
                in
                  (newTVars, name, elabTy env newTy)
                end
            val newTyBinds = map elabTyBind tyBinds
          in
            checkNameDuplication #2 newTyBinds loc E.DuplicateTypeNameInType;
            ([PC.PDTYPE (newTyBinds, loc)], SEnv.empty)
          end
        | A.DECDATATYPE (dataBinds, withTypeBinds, loc) =>
          let
            val (newDataBinds, newWithTypeBinds) =
                elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc)
          in
            (
              (PC.PDDATATYPE (newDataBinds, loc)) 
              :: (case newWithTypeBinds of
                    [] => [] | _ => [PC.PDTYPE(newWithTypeBinds, loc)]),
              SEnv.empty
            )
          end
        | A.DECREPLICATEDAT (tyCon, longTyCon, loc) =>
          ([PC.PDREPLICATEDAT (tyCon, longTyCon, loc)], SEnv.empty) 
        | A.DECABSTYPE (dataBinds, withTypeBinds, decs, loc) =>
          let
            val (newDataBinds, newWithTypeBinds) =
                elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc)
            val (newDecs, _) = elabDecs env decs
            val newVisibleDecs =
                case newWithTypeBinds of
                  [] => newDecs
                | _ => PC.PDTYPE(newWithTypeBinds, loc) :: newDecs
          in
            ([PC.PDABSTYPE(newDataBinds, newVisibleDecs, loc)], SEnv.empty)
          end
        | A.DECEXN (exnBinds, loc) =>
          let
            fun elabExnBind (A.EXBINDDEF(isOp, name, NONE, loc)) =
                PC.PLEXBINDDEF(isOp, name, NONE, loc)
              | elabExnBind (A.EXBINDDEF(isOp, name, SOME ty, loc)) =
                PC.PLEXBINDDEF(isOp, name, SOME(elabTy env ty), loc)
              | elabExnBind
                (A.EXBINDREP(bool1, name, bool2, exnlongid, loc)) =
                PC.PLEXBINDREP(bool1, name, bool2, exnlongid, loc)
            fun getExnName (A.EXBINDDEF(_, name, _, _)) = name
              | getExnName (A.EXBINDREP(_, name, _, _, _)) = name
            fun getExnLoc (A.EXBINDDEF(_, _, _, loc)) = loc
              | getExnLoc (A.EXBINDREP(_, _, _, _, loc)) = loc
            val _ =
                checkNameDuplication
                getExnName exnBinds loc E.DuplicateConstructorNameInException
            val _ =
                app
                    checkReservedNameForConstructorBind 
                    (ListPair.zip
                         (map getExnName exnBinds, map getExnLoc exnBinds))
          in
            ([PC.PDEXD (map elabExnBind exnBinds, loc)], SEnv.empty)
          end
        | A.DECLOCAL (dec1, dec2, loc) => 
          let
            val (pdecs1, env1) = elabDecs env dec1
            val (pdecs2, env2) = elabDecs (SEnv.unionWith #1 (env1, env)) dec2
          in
            ([PC.PDLOCALDEC(pdecs1, pdecs2, loc)], env2)
          end
        | A.DECOPEN(longids,loc) => ([PC.PDOPEN(longids, loc)], SEnv.empty)
        | A.DECINFIX (n, idlist, loc) =>
          (
            [PC.PDINFIXDEC(n, idlist, loc)],
            foldr
                (fn (x, env) => SEnv.insert (env, x, INFIX n))
                SEnv.empty
                idlist
          )
        | A.DECINFIXR (n, idlist, loc) =>
          (
            [PC.PDINFIXRDEC(n, idlist, loc)],
            foldr
                (fn (x, env) => SEnv.insert (env, x, INFIXR n))
                SEnv.empty
                idlist
          )
        | A.DECNONFIX (idlist, loc) =>
          (
            [PC.PDNONFIXDEC(idlist, loc)],
            foldr
                (fn (x, env) => SEnv.insert (env, x, NONFIX))
                SEnv.empty
                idlist
          )

    and elabDecs env decs = elabSequence elabDec env decs

(*******************below dealing with module*********************************)
    local
      datatype sigexpKind = Interface | OrdinarySig
    in
      fun specListToSpecSeq loc specList =
        let
          fun makeSeqSpec [] = raise Control.Bug "nilspec found in elaborate"
            | makeSeqSpec [spec] = spec
            | makeSeqSpec (spec :: specs) =
            PC.PLSPECSEQ(spec, makeSeqSpec specs, loc)
        in makeSeqSpec specList
        end

      fun elabSpec env spec =
        case spec of
          A.SPECSEQ(A.SPECEMPTY, spec, loc) => elabSpec env spec
        | A.SPECSEQ(spec, A.SPECEMPTY, loc) => elabSpec env spec
        | A.SPECSEQ(spec1, spec2, loc) =>
            PC.PLSPECSEQ(elabSpec env spec1, elabSpec env spec2, loc)
        | A.SPECVAL(valBinds, loc) =>
            let
              val _ = checkNameDuplication #1 valBinds loc E.DuplicateValDesc
            in
              PC.PLSPECVAL(elabLabeledSequence elabTy env valBinds, loc)
            end
        | A.SPECTYPE(tydescs, loc) => 
            let
              val _ =
                checkNameDuplication
                #2 tydescs loc E.DuplicateTypDesc
            in
              PC.PLSPECTYPE(tydescs, loc)
            end
        | A.SPECDERIVEDTYPE(maniftypedescs, loc) =>
            let 
              val _ =
                checkNameDuplication
                #2 maniftypedescs loc E.DuplicateTypDesc
              fun elabDesc (tvars, name, ty) = (tvars, name, elabTy env ty)
              fun elabTypeEquation m = PC.PLSPECTYPEEQUATION (elabDesc m, loc)
            in 
              specListToSpecSeq loc (map elabTypeEquation maniftypedescs)
            end
        | A.SPECEQTYPE(tydescs, loc) => 
            let
              val _ =
                checkNameDuplication
                #2 tydescs loc E.DuplicateTypDesc
            in
              PC.PLSPECEQTYPE(tydescs, loc)
            end
        | A.SPECDATATYPE(dataDescs, loc) =>
            let
              val _ =
                checkNameDuplication
                #2 dataDescs loc E.DuplicateTypDesc
            in
              PC.PLSPECDATATYPE(map (elabDataDesc loc env) dataDescs, loc)
            end
        | A.SPECREPLIC(tyCon, longTyCon, loc) =>
            PC.PLSPECREPLIC(tyCon, longTyCon, loc)
        | A.SPECEXCEPTION(exnDescs, loc) =>
            let
              val _ = 
                checkNameDuplication
                #1 exnDescs loc E.DuplicateConstructorNameInException
              fun elabExn env exnDescOpt = Option.map (elabTy env) exnDescOpt
            in
              PC.PLSPECEXCEPTION(elabLabeledSequence elabExn env exnDescs, loc)
            end
        | A.SPECSTRUCT(strdescs, loc) => 
            let
              val _ = 
                checkNameDuplication
                #1 strdescs loc E.DuplicateStrDesc
            in
              PC.PLSPECSTRUCT (elabLabeledSequence elabSigExp env strdescs, 
                               loc)
            end
(*
        | A.SPECFUNCTOR(fundescs, loc) =>
          let
              fun elabFunSigExp env (funName, argSigExp, bodySigExp) =
                  (funName, 
                   elabSigExp env argSigExp,
                   elabSigExp env bodySigExp)
              val _ = 
                  checkNameDuplication
                      #1 fundescs loc E.DuplicateFunctorDesc
          in
              PC.PLSPECFUNCTOR (map (elabFunSigExp env) fundescs, loc)
          end
*)
        | A.SPECINCLUDE(sigexp, loc)=>
          PC.PLSPECINCLUDE(elabSigExp env sigexp, loc)
        | A.SPECDERIVEDINCLUDE(sigids, loc) => 
            let
              fun elabSigID sigid = PC.PLSPECINCLUDE(PC.PLSIGID(sigid, loc), loc)
            in
              specListToSpecSeq loc (map elabSigID sigids)
            end
        | A.SPECSHARE(spec, longTyCons, loc) => 
            PC.PLSPECSHARE (elabSpec env spec, longTyCons, loc)
        | A.SPECSHARESTR(spec, longstrids, loc) => 
            PC.PLSPECSHARESTR (elabSpec env spec, longstrids, loc)
        | A.SPECEMPTY => PC.PLSPECEMPTY


      and elabSigExp env sigexp =
        case sigexp of 
          A.SIGEXPBASIC(spec, loc) => PC.PLSIGEXPBASIC(elabSpec env spec, loc)
        | A.SIGID(sigid,loc) => PC.PLSIGID(sigid, loc)
        | A.SIGWHERE(sigexp, whtypes, loc) =>
            let
              fun elabClause (tyvars, tyCon, ty) = (tyvars, tyCon, elabTy env ty)
            in
              PC.PLSIGWHERE(elabSigExp env sigexp, map elabClause whtypes, loc)
            end

      and elabStrExp env strexp =
        case strexp of
          A.STREXPBASIC(strdecs, loc) => 
            let val (plstrdecs, env') = elabStrDecs env strdecs
            in PC.PLSTREXPBASIC(plstrdecs, loc)
            end
        | A.STRID(longid, loc) => PC.PLSTRID(longid, loc)
        | A.STRTRANCONSTRAINT(strexp, sigexp, loc) =>
            PC.PLSTRTRANCONSTRAINT
            (elabStrExp env strexp, elabSigExp env sigexp, loc)
        | A.STROPAQCONSTRAINT(strexp, sigexp, loc) =>
            PC.PLSTROPAQCONSTRAINT
            (elabStrExp env strexp, elabSigExp env sigexp, loc)
        | A.FUNCTORAPP(funid, strexp, loc) => 
            PC.PLFUNCTORAPP(funid, elabStrExp env strexp, loc)
        | A.STRUCTLET(strdecs, strexp, loc) =>
            let
              val (plstrdecs, env') = elabStrDecs env strdecs
              val newenv = SEnv.unionWith #1 (env', env)
            in
              PC.PLSTRUCTLET(plstrdecs, elabStrExp env strexp, loc)
            end

      and elabStrBind env strbind =
        case strbind of
          A.STRBINDTRAN(strid, sigexp, strexp, loc) =>
            (
             strid,
             PC.PLSTRTRANCONSTRAINT
             (elabStrExp env strexp, elabSigExp env sigexp, loc)
             )
        | A.STRBINDOPAQUE(strid, sigexp, strexp, loc) =>
            (
             strid,
             PC.PLSTROPAQCONSTRAINT
             (elabStrExp env strexp, elabSigExp env sigexp, loc)
             )
        | A.STRBINDNONOBSERV(strid, strexp, loc) =>
            (strid, elabStrExp env strexp)

      and elabStrDec env strdec =
        case strdec of 
          A.COREDEC(dec, loc) => 
            let val (pldecs, env) = elabDec env dec
            in (map (fn pldec => PC.PLCOREDEC(pldec, loc)) pldecs, env)
            end
        | A.STRUCTBIND(strbinds,loc) => 
            ([PC.PLSTRUCTBIND(map (elabStrBind env) strbinds, loc)], SEnv.empty)
        | A.STRUCTLOCAL(strdecs1, strdecs2, loc) =>
            let
              val (plstrdecs1, env1) = elabStrDecs env strdecs1
              val (plstrdecs2, env2) =
                elabStrDecs (SEnv.unionWith #1 (env1, env)) strdecs2
            in
              ([PC.PLSTRUCTLOCAL(plstrdecs1, plstrdecs2, loc)], env2)
            end

      and elabStrDecs env strdecs = elabSequence elabStrDec env strdecs

      and elabFunBind env funbind  =
        case funbind of
          A.FUNBINDTRAN (funid, strid, argSigexp, resSigexp, strexp, loc) =>
            let val newStrexp = A.STRTRANCONSTRAINT(strexp, resSigexp, loc)
            in
              elabFunBind
              env
              (A.FUNBINDNONOBSERV(funid, strid, argSigexp, newStrexp, loc))
            end
        | A.FUNBINDOPAQUE (funid, strid, argSigexp, resSigexp, strexp, loc) =>
            let val newStrexp = A.STROPAQCONSTRAINT(strexp, resSigexp, loc)
            in
              elabFunBind
              env
              (A.FUNBINDNONOBSERV(funid, strid, argSigexp, newStrexp, loc))
            end
        | A.FUNBINDNONOBSERV(funid, strid, argSigexp, strexp, loc) =>
            let
              val newArgSigexp = elabSigExp env argSigexp
              val newStrexp = elabStrExp env strexp
            in
              (funid, strid, newArgSigexp, newStrexp, loc)
            end
        | A.FUNBINDSPECTRAN(funid, spec, resSigexp, strexp, loc) =>
            let
              val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
              val newStrexp =
                A.STRUCTLET
                ([A.COREDEC(A.DECOPEN([[newStrid]], loc), loc)], 
                 A.STRTRANCONSTRAINT(strexp,resSigexp,loc),
                 loc)
              val argSigExp = A.SIGEXPBASIC(spec, loc)
              val newFunBind =
                A.FUNBINDNONOBSERV
                (funid, newStrid, argSigExp, newStrexp, loc)
            in
              elabFunBind env newFunBind
            end
        | A.FUNBINDSPECOPAQUE(funid, spec, resSigexp, strexp, loc) =>
            let
              val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
              val newStrexp =
                A.STRUCTLET
                ([A.COREDEC(A.DECOPEN([[newStrid]], loc), loc)], 
                 A.STROPAQCONSTRAINT(strexp,resSigexp,loc),
                 loc)
              val argSigExp = A.SIGEXPBASIC(spec, loc)
              val newFunBind =
                A.FUNBINDNONOBSERV
                (funid, newStrid, argSigExp, newStrexp, loc)
            in
              elabFunBind env newFunBind
            end
        | A.FUNBINDSPECNONOBSERV (funid, spec, strexp, loc) =>
            let
              val newStrid = NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
              val newStrexp =
                A.STRUCTLET
                ([A.COREDEC(A.DECOPEN([[newStrid]], loc), loc)], strexp, loc)
              val newFunBind =
                A.FUNBINDNONOBSERV
                (funid, newStrid, A.SIGEXPBASIC(spec, loc), newStrexp, loc)
            in
              elabFunBind env newFunBind
            end

      and elabTopDec env topdec = 
        case topdec of 
          A.TOPDECSTR(strdec, loc) => 
            let val (plstrdecs, env') = elabStrDec env strdec
            in
              (map (fn plstrdec => PC.PLTOPDECSTR(plstrdec, loc)) plstrdecs, env')
            end
        | A.TOPDECSIG(sigdecs, loc) => 
            let val plsigdecs = elabLabeledSequence elabSigExp env sigdecs
            in ([PC.PLTOPDECSIG(plsigdecs, loc)], SEnv.empty)
            end
        | A.TOPDECFUN(funbinds, loc) =>
            let val plfunbinds = map (elabFunBind env) funbinds
            in ([PC.PLTOPDECFUN(plfunbinds, loc)], SEnv.empty)
            end

      and elabTopDecs env topdecs = elabSequence elabTopDec env topdecs

      (* the top level function *)
      fun elaborate fixEnv varNameState decs =
        let        
          (* initiallize *)
          val _ = initializeErrorQueue ()
          val _ = VarNameGen.init varNameState 

          val (ptopdecls, env) = elabTopDecs fixEnv decs

          (* finalizne *)
          val newVarNameState = VarNameGen.reset ()
        in        
          case getErrors () of
            [] => (
                   ptopdecls, 
                   env, 
                   newVarNameState,
                   getWarnings()
                   )
          | errors => raise UE.UserErrors (getErrorsAndWarnings ())
        end
        
    end (* end local *)
end
end
