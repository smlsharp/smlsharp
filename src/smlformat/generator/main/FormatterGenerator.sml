(**
 * This module generates formatter code for types.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori (refactored)
 * @copyright 2010, Tohoku University.
 * @version $Id: FormatterGenerator.sml,v 1.17 2007/06/30 11:04:42 kiyoshiy Exp $
 *)
structure FormatterGenerator : FORMATTER_GENERATOR =
struct

  structure F = FormatTemplate
  structure U = Utility

  datatype listElement
    = LIST of string list
    | ATOM of string
  type expList = listElement list
  fun normalize expList =
      foldr
      (fn (L, nil) => [L]
        | (LIST codeList1, LIST codeList2::rest) => 
          LIST (codeList1@codeList2)::rest
        | (L,rest) => L::rest
      )
      nil
      expList
  fun serialize nil = "nil"
    | serialize [ATOM s] = s
    | serialize (elem::L) = 
      let
        val code = serialize L
      in
        case elem of
          LIST codeList =>
          (U.interleaveString "::" codeList) ^ "::" ^ code
        | ATOM s => s ^ "@" ^ code
      end
  fun expListToCode L = serialize (normalize L)
  fun serializeExpElement E =
      case E of
        LIST codeList =>  (U.interleaveString "::" codeList) ^ ":: nil" 
      | ATOM s => s


  (** cause of error raised by formatter genration *)
  datatype errorCause =
           (** no formatter for the specified type is included in the
            * formatter environment. *)
           FormatterOfTypeNotFound of string * string
         | (** The identifier is not included in the type environment. *)
           TypeOfIDNotFound of string
         | (** type pattern and defining type expression do not match. *)
           UnMatchPatternAndType of string
         | (** conflict in additional parameters, local formatter names,
            * IDs in type pattern *)
           NameConflict of string
         | (** unimplemented feature is required. *)
           Unimplemented of string
         | (** An ID in a custom format tag conflicts with type name or
            * datatype name. *)
           CustomFormatNameConflict of string
         | (** error about @ditto (EXPERIMENTAL EXTENSION by Ueno) *)
           DittoError of string

  (***************************************************************************)

  (** an exception raised in formatter genration *)
  exception GenerationError of string * (int * int)

  exception InternalError of errorCause

  (***************************************************************************)

  (** used as the prefix of name of generated formatters. *)
  val prefixOfLocalFormatterName = "format'_"

  (** used as the header of generated function code. *)
  val DefaultFunctionHeader = "fun"

  (** name of the structure which defined format expression type. *)
  val structureNameOfFormatExpression = "SMLFormat.FormatExpression"

  (** name of the structure which defined formatters for basic types. *)
  val structureNameOfBasicFormatters = "SMLFormat.BasicFormatters"

  (** used as prefix of name of elements of format expression. *)
  val prefixOfFormatExpressionName = structureNameOfFormatExpression ^ "."

  val DefaultFormatterExnRefName =
      structureNameOfBasicFormatters ^ ".format_exn_Ref"

  (** newline literal *)
  val newline = "\n"

  (** with space, no newline *)
  val spaceIndicator = F.Indicator{space = true, newline = NONE}

  (** no space, newline priority 1 *)
  val ns_1_Indicator =
      F.Indicator
      {space = false, newline = SOME{priority = F.Preferred 1}}

  (** with space, newline priority 1 *)
  val s_1_Indicator =
      F.Indicator
      {space = true, newline = SOME{priority = F.Preferred 1}}

  (** with space, deferred newline priority *)
  val s_d_Indicator =
      F.Indicator
      {space = true, newline = SOME{priority = F.Deferred}}

  (** used to group tyCon and its argument type expressions *)
  val assocOfTyConApp = {cut = false, strength = 10, direction = F.Left}

  val unknownRegion = (~1, ~1)

  (***************************************************************************)

  (**
   * get a message describing the cause of exceptions raised by this module.
   * @params errorCause
   * @param errorCause the exception raised by this module.
   * @return a message which describes the detail of the exception.
   *)
  fun getErrorCauseMessage errorCause =
      case errorCause of
        FormatterOfTypeNotFound (prefix, name) =>
        if prefix = Ast.DefaultFormatterPrefix
        then "formatter of type not found: " ^ name
        else "formatter of type for prefix `" ^ prefix ^ "' not found: " ^ name
      | TypeOfIDNotFound name => "type of ID not found:" ^ name
      | UnMatchPatternAndType message =>
        "pattern and type do not match:" ^ message
      | NameConflict name => "name conflicts:" ^ name
      | Unimplemented message => "unimplemented:" ^ message
      | CustomFormatNameConflict name =>
        "custom format tag conflicts with tyCon name:" ^ name
      | DittoError message => message

  (**
   * translates an error into a GenerationError
   *)
  fun translateError (error, region) =
      case error of
        InternalError cause =>
        GenerationError(getErrorCauseMessage cause, region)
      | GenerationError _ => error
      | otherError => GenerationError(General.exnMessage otherError, region)

  (** raised if two lists the zipEq receives are not equal length.
   * This exception is local. It should not be raised out of the SMLFormat lib.
   *)
  exception UnequalLengths

  (**
   *  ListPair.zip plus length check.
   * @params (left, right)
   * @param left the list
   * @param right the another list
   * @return zipped list
   * @throws UnequalLengths if the left and right are not equal length.
   *)
  fun zipEq ([], _::_) = raise UnequalLengths
    | zipEq (_::_, []) = raise UnequalLengths
    | zipEq ([], []) = []
    | zipEq (leftHead::leftTail, rightHead::rightTail) =
      (leftHead, rightHead) :: (zipEq (leftTail, rightTail))

  (**
   *  translate characters to be escaped into escape sequence.
   * @params string
   * @param string a string which may include characters to be escaped.
   * @return escaped string
   *)
  fun escapeString string =
      let
        fun escapeChar char =
            case char of
              #"\a" => [#"a", #"\\"]
            | #"\b" => [#"b", #"\\"]
            | #"\f" => [#"f", #"\\"]
            | #"\n" => [#"n", #"\\"]
            | #"\r" => [#"r", #"\\"]
            | #"\t" => [#"t", #"\\"]
            | #"\v" => [#"v", #"\\"]
            | #"\\" => [#"\\", #"\\"]
            | #"\"" => [#"\"", #"\\"]
            | _ => [char]
        fun escape [] chars = List.rev chars
          | escape (head::tail) chars = escape tail ((escapeChar head) @ chars)
        val escapedString = String.implode (escape (String.explode string) [])
      in
        escapedString
      end

  (****************************************)

  (**
   * get the name of a type variable.
   * @params ty
   * @param ty this must be an Ast.Tyv which might be wrapped in Ast.MarkTyv.
   * @return the name of the type variable
   *)
  fun getTyVarName (Ast.Tyv name) = name
    | getTyVarName (Ast.MarkTyv (tyv, _)) = getTyVarName tyv

  exception GetTyConName

  (**
   * get the name of the type constructor used to build a type expression.
   * @params ty
   * @param ty this must be an Ast.VarTy or Ast.ConTy which might be wrapped
   *          in As.MarkTy
   * @return the name of the type constructor
   *)
  fun getTyConName ty =
      case ty of
        Ast.VarTy tv => getTyVarName tv
      | Ast.ConTy (ids, _) => U.interleaveString "." ids
      | Ast.MarkTy (ty, _) => getTyConName ty
      | _ => raise GetTyConName

  (****************************************)

  (**
   * type of formatter environment.
   * @params (prefixOpt, tyExp)
   * @param prefixOpt namespace indicated by prefix
   * @param tyExp this must be a type variable or a constructor application.
   * @return name of the formatter by which values of the tyExp should be
   *       formatted.
   *)
  type formatterEnv = (string * Ast.ty) -> string

  (**
   * empty formatter environment which fails on any search.
   *)
  val initialFormatterEnv : formatterEnv =
      fn (prefix, ty) =>
         raise InternalError(FormatterOfTypeNotFound(prefix, getTyConName ty))

  (**
   *  adds an entry to the formatter environment.
   * <p>
   *  This function registers a name of the formatter by which values of the
   * type built by the type constructor 'tyConName' should be formatted in
   * the namespace indicated by the 'prefixOpt'.
   * </p><p>
   *  If the 'prefixOpt' is <code>NONE</code>, the formatter can be called
   * from any namespace. Otherwise, that is, if the 'prefixOpt' is
   * <code>SOME p</code>, the formatter is registered locally in the namespace
   * indicated by the <code>p</code>.
   * </p>
   * @params F (prefixOpt, tyConName, formatterName)
   * @param F formatter environment
   * @param prefixOpt NONE if the formatter to be added does not belong
   *                 to any namespace.
   * @param tyConName the name of type constructor
   * @param formatterName the name of formatter
   * @return a formatter environment extended with the new entry.
   *)
  fun addToFormatterEnv (F : formatterEnv) (NONE, tyconName, f) =
      (fn (prefix, ty) =>
          if getTyConName ty = tyconName then f else F (prefix, ty))
    | addToFormatterEnv (F : formatterEnv) (SOME prefix, tyconName, f) =
      (fn (prefix', ty) =>
          if prefix = prefix' andalso getTyConName ty = tyconName
          then f
          else F (prefix', ty))

  (**
   *  append two formatter environments.
   * @params (left, right)
   * @param left the formatter environment to be explored first.
   * @param right the formatter environment to be explored when search in
   *           the <code>left</code> fails.
   * @return a new formatter environment
   *)
  fun appendFormatterEnv ((F1 : formatterEnv), (F2 : formatterEnv)) =
      fn prefixAndTy =>
         ((F1 prefixAndTy)
          handle InternalError(FormatterOfTypeNotFound _) => F2 prefixAndTy)

  (********************)

  (**
   *  type of type environment.
   * @params id
   * @param id an identifier 
   * @return the type expression bound to the <code>id</code>.
   *)
  type typeEnv = string -> Ast.ty

  (** empty type environment *)
  val initialTypeEnv : typeEnv =
      fn id => raise InternalError(TypeOfIDNotFound id)

  (**
   * adds a new entry to the type environment.
   * @params T (id, ty)
   * @param T the type environment to which the new entry is added.
   * @param id identifier
   * @param ty the type expression bound to the <code>id</code>
   * @return a new type environment.
   *)
  fun addToTypeEnv (T : typeEnv) (id, ty) =
      fn name => if name = id then ty else T name

  (********************)

  (**
   * type of additional parameter set
   * @params name
   * @param name the parameter name
   * @return true if the <code>name</code> is contained in the set.
   *)
  type parameterSet = string -> bool

  (** empty parameter set *)
  val initialParameterSet : parameterSet = fn paramName => false

  (**
   * adds a name of parameter to the parameter set.
   * @params P name
   * @param P the parameter set
   * @param name the name of parameter to be added
   * @return a new parameter set
   *)
  fun addToParameterSet (P : parameterSet) paramName =
      fn name => (name = paramName orelse P name)

  (********************)

  (**
   * generates an unique name which does not conflict with any name in params.
   *)
  fun generateUniqueName prefix params =
      let
        fun generate n =
            let val name = prefix ^ Int.toString n
            in if List.exists (fn x => x = name) params
               then generate (n + 1)
               else name
            end
      in
        generate 0
      end

  (****************************************)
  (**
   *  translates a format template into SML code.
   * @params (F, T, P, prefix) isDefault template
   * @param F the formatter environment
   * @param T the type environment
   * @param P the additional parameter set
   * @param prefix the prefix indicating the current namespace
   * @param isDefault true if this template is generated for default formatter
   * @param template a format template to be translated
   * @return a text of SML code which generates format expression
   *         instantiated from the template.
   *)
  fun translateTemplate
      (F : formatterEnv, T : typeEnv, P : parameterSet, prefix : string) 
    : bool -> F.template -> listElement
    =
      let
        fun codeOfIndicator {space, newline} =
            let
              val newlineCode =
                  case newline
                   of NONE => "NONE"
                    | SOME{priority} =>
                      let
                        val priorityCode =
                            case priority
                             of F.Preferred int =>
                                prefixOfFormatExpressionName ^ "Preferred" ^
                                "(" ^ Int.toString int ^ ")"
                              | Deferred =>
                                prefixOfFormatExpressionName ^ "Deferred"
                      in
                        "SOME{" ^
                        "priority = " ^ priorityCode ^
                        "}"
                      end
            in
              "{" ^
              "space = " ^ Bool.toString space ^ ", " ^
              "newline = " ^ newlineCode ^
              "}"
            end

        fun codeOfAssoc NONE = "NONE"
          | codeOfAssoc (SOME{cut, strength, direction}) =
            let
              val directionCode =
                  prefixOfFormatExpressionName ^
                  (case direction
                    of F.Left => "Left"
                     | F.Right => "Right"
                     | F.Neutral => "Neutral")
            in
              "SOME{" ^
              "cut = " ^ Bool.toString cut ^ ", " ^
              "strength = " ^ Int.toString strength ^ ", " ^
              "direction = " ^ directionCode ^
              "}"
            end

        fun translate isDefault template =
            case template of
              F.Term arg =>
              let
                val code = 
                    prefixOfFormatExpressionName ^ "Term" ^
                    "(" ^ (Int.toString (size arg)) ^ ","^
                    "\"" ^ (escapeString arg) ^ "\")"
                val conLongid = prefixOfFormatExpressionName ^ "Term"
              in
                LIST [code]
              end
            | F.Newline =>
              let
                val code =  prefixOfFormatExpressionName ^ "Newline"
              in
                LIST [code]
              end
            | F.Guard (assoc, templates) =>
              let
                val templateCodes = map (translate isDefault) templates
                val templateCode = expListToCode templateCodes
                val assocCode = codeOfAssoc assoc
                val code = 
                  prefixOfFormatExpressionName ^ "Guard (" ^
                    assocCode ^ ", " ^ templateCode ^
                  " )"
              in
                LIST[code]
              end
            | F.Indicator arg =>
              let
                val code = 
                    prefixOfFormatExpressionName ^ "Indicator" ^
                    "(" ^ (codeOfIndicator arg) ^ ")"
              in
                LIST[code]
              end
            | F.StartOfIndent indent =>
              let
                val code = 
                    prefixOfFormatExpressionName ^ "StartOfIndent" ^
                    "(" ^ Int.toString indent ^ ")"
              in
                LIST[code]
              end
            | F.EndOfIndent =>
              let
                val code = 
                    prefixOfFormatExpressionName ^ "EndOfIndent"
              in
                LIST[code]
              end
            | F.Instance instance =>
              let
                val code = 
                    codeOfInstantiation false isDefault instance
              in
                ATOM code
              end
            | F.MarkTemplate(template, region) =>
              (translate isDefault template
               handle error => raise translateError(error, region))

        and codeOfInstantiation isArgPosition isDefault instance =
            (case instance of
               (F.Atom (id, tyid)) =>
               ((* first, try formatting by using bound formatter *)
                let
                  val formatter =
                      case tyid of
                        NONE => F (prefix, T(id))
                      | SOME tyid => F (prefix, Ast.VarTy(Ast.Tyv tyid))
                in
                  if isArgPosition
                  then formatter
                  else formatter ^ "(" ^ id ^ ")"
                end
                  (* When any error occurs, check whether additional parameter
                   * of the same name is declared. *)
                  handle exn as (InternalError _) =>
                         if P(id) then id else raise exn
                       | GetTyConName => 
                         raise InternalError (FormatterOfTypeNotFound (prefix, id))
               )
             | (F.App(id, tyid, instances, templates)) =>
               let
                 val formatter =
                     (case tyid of
                        NONE => F(prefix, T(id))
                      | SOME tyid => F(prefix, Ast.VarTy(Ast.Tyv tyid)))
                     handle exn as (InternalError _) =>
                            if P(id) then id else raise exn
                          | GetTyConName => 
                            raise InternalError (FormatterOfTypeNotFound (prefix, id))
                 val instanceCodes =
                     map (codeOfInstantiation true isDefault) instances
                 val templateCodes =
                     map
                         (fn templates =>
                             let
                               val expList = map (translate isDefault) templates
                             in
                               "(" ^ expListToCode expList ^ ")"
                             end
                         )
                         templates
               in
                 formatter ^
                 "(" ^
                 (U.interleaveString "," (instanceCodes @ templateCodes)) ^
                 ")" ^
                 (if isArgPosition then "" else id)
               end
             | (F.MarkInstance(instance, region)) =>
               (codeOfInstantiation isArgPosition isDefault instance
                handle error => raise (translateError(error, region))))
            handle exn as (InternalError _) =>
                   if isDefault
                   then
                     if isArgPosition
                     then
                       "(fn _ => "
                       ^ "["
                       ^ prefixOfFormatExpressionName ^ "Term(1, \"?\")"
                       ^ "]"
                       ^ ")"
                     else
                       "[" ^ prefixOfFormatExpressionName ^ "Term(1, \"?\")]"
                   else raise exn

        fun generate isDefault template =
            let
              val expElememt = translate isDefault template
              val code = serializeExpElement expElememt
            in
              code
              end
      in
        translate
      end

  (**
   * pattern match of a type expression and a type pattern.
   * @params T (ty, typat)
   * @param T type environment
   * @param ty a type expression
   * @param typat a type pattern
   * @return a new type environment extended by the bindings generated by
   *      pattern match.
   *)
  fun matchTyPat T (ty, (F.VarTyPat id)) = addToTypeEnv T (id, ty)
    | matchTyPat T (ty, F.WildTyPat) = T
    | matchTyPat T (ty, (F.TypedVarTyPat (id, typeID))) = (* ignore ty *)
      addToTypeEnv T (id, Ast.VarTy (Ast.Tyv typeID))
    | matchTyPat T (Ast.RecordTy fieldTypes, F.RecordTyPat(fieldPats, flexible))
      =
      foldl
      (fn ((label, typat), T) =>
          case List.find (fn fieldType => #1 fieldType = label) fieldTypes
           of NONE =>
              raise
                InternalError
                    (UnMatchPatternAndType("label " ^ label ^ " not found"))
            | SOME(_, ty) => matchTyPat T (ty, typat))
      T
      fieldPats
    | matchTyPat T (Ast.TupleTy tys, F.TupleTyPat typats) =
      (foldl (fn (pair, T) => matchTyPat T pair) T (zipEq (tys, typats))
       handle
       UnequalLengths =>
       raise InternalError
                 (UnMatchPatternAndType("the number of elements mismatch.")))
    | matchTyPat T (ty as Ast.ConTy(_, tys), F.TyConTyPat(id, typats)) =
      (foldl
       (fn (pair, T) => matchTyPat T pair)
       (addToTypeEnv T (id, ty))
       (zipEq (tys, typats))
       handle
       UnequalLengths =>
       raise InternalError
                 (UnMatchPatternAndType("the number of arguments mismatch.")))
    | matchTyPat
      T (ty as Ast.ConTy(_, tys), F.TypedTyConTyPat(id, typats, typeID)) =
      (foldl
       (fn (pair, T) => matchTyPat T pair)
       (addToTypeEnv T (id, Ast.VarTy (Ast.Tyv typeID)))
       (zipEq (tys, typats))
       handle
       UnequalLengths =>
       raise InternalError
                 (UnMatchPatternAndType("the number of arguments mismatch.")))
    | matchTyPat T (Ast.MarkTy(ty, _), typat) = matchTyPat T (ty, typat)
    | matchTyPat T (ty, F.MarkTyPat(typat, region)) =
      (matchTyPat T (ty, typat)
       handle error => raise (translateError(error, region)))
    | matchTyPat T _ =
      raise InternalError(UnMatchPatternAndType "type and pattern unmatch")

  (**
   * translates a type pattern to a pattern on expression.
   * @params tyPat
   * @param tyPat a type pattern
   * @return a text of SML code of pattern
   *)
  fun translateTyPatToExpPat (F.VarTyPat id) = id
    | translateTyPatToExpPat F.WildTyPat = "_"
    | translateTyPatToExpPat (F.TypedVarTyPat (id, _)) = id
    | translateTyPatToExpPat (F.RecordTyPat(fieldPats, flexible)) =
      "{" ^
      (U.interleaveString
       ", "
       ((map
         (fn(label, typat) => label ^ " = " ^ (translateTyPatToExpPat typat))
         fieldPats) @
        (if flexible then ["..."] else []))) ^
      "}"
    | translateTyPatToExpPat (F.TupleTyPat typats) =
      "(" ^ (U.interleaveString ", " (map translateTyPatToExpPat typats)) ^ ")"
    | translateTyPatToExpPat (F.TyConTyPat(id, typats)) = id
    | translateTyPatToExpPat (F.TypedTyConTyPat(id, typats, _)) = id
    | translateTyPatToExpPat (F.MarkTyPat(typat, _)) =
      translateTyPatToExpPat typat

  (**
   *  translates a type and a format comment into SML code.
   * @params (F, T, P, prefix) (primaryTag, localTags, isDefault, id, ty)
   * @param F the formatter environment
   * @param T the type environment
   * @param P the additional parameter set
   * @param prefix the prefix indicating the current namespace
   * @param primaryTag the primary format tag
   * @param localTags the local format tags
   * @param isDefault true if formatTags are generated by default
   * @param id the name of the variable to which the value to be formatted
   *           would be bound.
   * @param ty type expression
   * @return a text of SML code which generates a list of format expressions
   *        which encode the value bound to the <code>id</code> according to
   *        the format tags.
   *)
  fun translateType
          (F, P, prefix)
          (
            formatTag : F.formattag,
            localFormatTags : F.formattag list,
            isDefault,
            id,
            ty
          ) =
      let
        fun encloseInList strings =
            "(List.concat[" ^ (U.interleaveString ",\n " strings) ^ "])"

        val T = matchTyPat initialTypeEnv (ty, #typepat formatTag)
        val (T,Ts) =
            let
              val TTS =
                  List.rev
                    (foldl
                       (fn ({id = SOME(id), typepat, ...}, Ts as (T::_)) =>
                           (matchTyPat T (T(id), typepat)) :: Ts
                         | _ => raise Fail "Bug: NONE of id in localFormatTags"
                       )
                       [T]
                       localFormatTags)
            in
              case TTS of T::TS => (T, TS)
                        | _ => raise Fail "Bug: impossible"
            end

        val formatterNames =
            map
            (fn {id = SOME(id), ...} => prefixOfLocalFormatterName ^ id
              | _ => raise Fail "Bug: NONE id in localFomatTags"
            )
            localFormatTags
        val (F0,Fs) =
            let
              val F0Fs =
                  foldr
                    (fn (({id = SOME(id), ...}, formatterName), Fs as (F::_)) =>
                        (addToFormatterEnv F (SOME prefix, id, formatterName)) :: Fs
                      | _ => raise Fail "Bug: NONE id in localFomatTags"
                    )
                    [F]
                    (zipEq (localFormatTags, formatterNames))
            in
              case F0Fs of
                F0::Fs => (F0, Fs)
              | _ => raise Fail "Bug: nil F0Fs"
            end

        val (T',Ts') =
            let
              fun addAllIdsToTypeEnv T ids =
                  foldr
                  (fn(id, T) => addToTypeEnv T (id, Ast.VarTy (Ast.Tyv id)))
                  T
                  ids
              val T'Ts' =
                  (List.rev o #2)
                    (foldl
                       (fn (T, ([], Ts)) => ([], T :: Ts)
                         | (T, (ids, Ts)) =>
                           (tl ids, (addAllIdsToTypeEnv T ids) :: Ts))
                       (map (fn {id=SOME(id),...} => id
                              | _ => raise Fail "Bug: NONE id in localFomatTags"
                            ) 
                            localFormatTags, [])
                       (T::Ts))
            in
              case T'Ts' of T'::Ts' => (T',Ts')
                          | _ => raise Fail "Bug: nil T'sTs'"
            end

        val expList = 
            map
             (translateTemplate (F0, T', P, prefix) isDefault)
             (#templates formatTag)
        val exp = expListToCode expList
(*
        val exp =
            encloseInList
            (map
             (translateTemplate (F0, T', P, prefix) isDefault)
             (#templates formatTag))
*)
        val exps =
            map
            (fn ((F, T), {templates, ...}) =>
                let
                  val expList = 
                      map
                        (translateTemplate (F, T, P, prefix) isDefault)
                        templates
                  val exp = expListToCode expList
                in
                  exp
(*
                encloseInList
                    (map
                         (translateTemplate (F, T, P, prefix) isDefault)
                         templates)
*)
                end
            )
            (zipEq (zipEq (Fs, Ts'), localFormatTags))

        val pat = translateTyPatToExpPat (#typepat formatTag)
        val pats =
            map
            (fn {typepat, ...} => translateTyPatToExpPat typepat)
            localFormatTags

        val funs =
            List.rev  (* formatter for inner most localtag is defined first.*)
            (map
             (fn (formatterName, (pat, exp)) =>
                 "fun " ^ formatterName ^ " " ^ pat ^ " = " ^ exp ^ " ")
             (zipEq (formatterNames, zipEq (pats, exps))))

      in
        case funs of
          nil => "case " ^ id ^ " of " ^ pat ^ " => " ^ newline ^ exp 
        | _ =>
          "case " ^ id ^ " of " ^ pat ^ " => " ^ newline ^
          "let " ^ (U.interleaveString newline funs) ^ newline ^
          "in " ^ exp ^ " end"
      end

  (****************************************)

  (**
   * generates default format tags for a type expression.
   * @params ty
   * @param ty a type expression
   * @return a pair of a primary format tag and a list of local format tags.
   *)
  fun generateDefaultFormatTags ty =
      let
        local val idSeed = ref 0
        in
          fun getNewID () =
              (idSeed := !idSeed + 1; "x" ^ (Int.toString (!idSeed)))
        end

        fun tyconIsList ty =
            case getTyConName ty of
              "list" => true
            | "List.list" => true
            | _ => false

        fun generate ty =
            case ty of
              Ast.VarTy (tv) =>
              let val varName = getNewID ()
              in
                (
                  {
                    id = NONE,
                    typepat = F.VarTyPat varName,
                    templates = [F.Guard(NONE, [F.Instance(F.Atom(varName, NONE))])]
                  },
                  []
                )
              end

            | Ast.ConTy (["->"], [t1, t2]) =>
              let
                val varName = getNewID ()
                val templates = [F.Term "<<fn>>"]
              in
                (
                  {
                    id = NONE,
                    typepat = F.VarTyPat varName,
                    templates = templates
                  },
                  []
                )
              end

            | Ast.ConTy (qid, []) =>
              let
                val varName = getNewID ()
                val template = F.Instance(F.Atom(varName, NONE))
                val templates =
                    case qid of
                      ["string"] => [F.Term "\"", template, F.Term "\""]
                    | ["String", "string"] => [F.Term "\"", template, F.Term "\""]
                    | _ => [template]
              in
                (
                  {
                    id = NONE,
                    typepat = F.VarTyPat varName,
                    templates = [F.Guard(NONE, templates)]
                  },
                  []
                )
              end

            | Ast.ConTy (qid, argTypes) =>
              let
                val tyconVarName = getNewID()
                val idTypePairs = map (fn ty => (getNewID(), ty)) argTypes
                val localTags =
                    List.concat
                    (map
                     (fn (id, argType) =>
                         let
                           val ({typepat, templates, ...}, localTags) =
                               generate argType
                         in
                           {
                             id = SOME id,
                             typepat = typepat,
                             templates = templates
                           } :: localTags
                         end)
                     idTypePairs)
                val typePat =
                    F.TyConTyPat
                    (tyconVarName, map (fn (id, _) => F.VarTyPat id) idTypePairs)
                val inst =
                    F.Instance
                    (F.App
                     (
                       tyconVarName,
                       NONE,
                       map (fn (id, _) => F.Atom (id, NONE)) idTypePairs,
                       if tyconIsList ty
                       then [[F.Term ",", s_1_Indicator]]
                       else []
                     ))
                val templates =
                    [F.Guard
                     (
                       NONE,
                       if tyconIsList ty
                       then
                         [
                           F.Term "[",
                           F.StartOfIndent 2,
                           ns_1_Indicator,
                           inst,
                           F.EndOfIndent,
                           ns_1_Indicator,
                           F.Term "]"
                         ]
                       else [inst]
                     )]
              in
                (
                  {id = NONE, typepat = typePat, templates = templates},
                  localTags
                )
              end

            | Ast.RecordTy fields =>
              let
                val labelVarTyTuples =
                    map (fn (label, ty) => (label, getNewID(), ty)) fields
                val localTags =
                    List.concat
                    (map
                     (fn (label, id, ty) =>
                         let
                           val (typepat, templates, localTags) =
                               case generate ty of
                                 ({id = NONE, typepat, templates}, localTags) =>
                                 (typepat, templates, localTags)
                               | _ => raise Fail "Bug: non NONE id of generate ty"
                         in
                           {
                             id = SOME id,
                             typepat = typepat,
                             templates = templates
                           } ::
                           localTags
                         end)
                     labelVarTyTuples)
                val typePat =
                    F.RecordTyPat
                    (
                      map
                      (fn (label, id, _) => (label, F.VarTyPat id))
                      labelVarTyTuples,
                      false
                    )
                val templateRows =
                    if List.null labelVarTyTuples
                    then []
                    else
                      List.rev
                      (foldl
                       (fn ((label, id, _), fieldTemps) =>
                           (F.Guard
                            (
                              NONE,
                              [
                                (F.Term label),
                                s_d_Indicator,
                                (F.Term "="),
                                s_1_Indicator,
                                F.Guard(NONE, [F.Instance(F.Atom (id, NONE))])
                              ]
                            )::
                            s_1_Indicator::
                            (F.Term ",")::
                            fieldTemps))
                       (case hd labelVarTyTuples of
                          (label, id, _) =>
                          [
                            F.Guard
                            (
                              NONE,
                              [
                                F.Term label,
                                s_d_Indicator,
                                F.Term ("="),
                                s_1_Indicator,
                                (F.Guard(NONE, [F.Instance(F.Atom(id, NONE))]))
                              ]
                            )
                          ])
                       (tl labelVarTyTuples))
              in
                (
                  {
                    id = NONE,
                    typepat = typePat,
                    templates =
                    [F.Guard
                     (
                       NONE,
                       [F.Term "{", F.StartOfIndent 2, ns_1_Indicator] @
                       templateRows @
                       [F.EndOfIndent, ns_1_Indicator, F.Term "}"]
                     )]
                  },
                  localTags
                )
              end

            | Ast.TupleTy types =>
              let
                val varTyTuples = map (fn ty => (getNewID(), ty)) types
                val localTags =
                    List.concat
                    (map
                     (fn (id, ty) =>
                         let
                           val (typepat, templates, localTags) =
                               case generate ty of
                                 ({id = NONE, typepat, templates}, localTags) =>
                                 (typepat, templates, localTags)
                               | _ => raise Fail "Bug: non NONE id of generate ty"
                         in
                           {
                             id = SOME id,
                             typepat = typepat,
                             templates = templates
                           } ::
                           localTags
                         end)
                     varTyTuples)
                val typePat =
                    F.TupleTyPat (map (fn (id, _) => F.VarTyPat id) varTyTuples)
                val templateRows =
                    if List.null varTyTuples
                    then []
                    else
                      List.rev
                      (foldl
                       (fn ((id, _), temps) =>
                           (F.Guard(NONE, [F.Instance(F.Atom (id, NONE))]))::
                           s_1_Indicator::
                           (F.Term ",")::
                           temps)
                       (case hd varTyTuples of
                          (id, _) => [F.Guard(NONE, [F.Instance(F.Atom(id, NONE))])])
                       (tl varTyTuples))
              in
                (
                  {
                    id = NONE,
                    typepat = typePat,
                    templates =
                    [F.Guard
                     (
                       NONE,
                       [F.Term "(", F.StartOfIndent 2, ns_1_Indicator] @
                       templateRows @
                       [F.EndOfIndent, ns_1_Indicator, F.Term ")"]
                     )]
                  },
                  localTags
                )
              end

            | Ast.MarkTy (ty, _) => generate ty
      in
        generate ty
      end

  (****************************************)

  fun findOneOf nil eq l = NONE
    | findOneOf (h::t) eq l =
      case List.find (eq h) l of
        x as SOME _ => x
      | NONE => findOneOf t eq l

  (**
   *  generates a SML code which formats a value built by the specified
   * value constructor.
   * @params
   *     (F, T, P, prefix, ditto)
   *     argVar {formatComments, valConName, argTypeOpt}
   * @param F the formatter environment
   * @param T the type environment
   * @param P the additional parameter set
   * @param prefix the prefix indicating the current namespace
   * @param list of ditto prefixes (EXPERIMENTAL EXTENSION by Ueno)
   * @param argVar the name of variable which is bound to the argument to the
   *             value constructor if the constructor takes an argument.
   * @param formatComments a list of defining format comments
   * @param valConName the name of the value constructor
   * @param argTypeOpt <code>SOME ty</code> if the value constructor requires
   *            an argument of the type <code>ty</code>.
   * @return a text of SML code which generates a list of format expressions
   *        which encode the value constructed by the <code>valConName</code>.
   *)
  fun generateForValConBind
      (F, P, prefix, ditto)
      argVarName {formatComments, valConName, argTypeOpt} =
      let
        fun isSamePrefix prefix (formatComment : Ast.definingFormatComment) =
            #prefix formatComment = prefix
      in
        case findOneOf (prefix::ditto) isSamePrefix formatComments of
          SOME {primaryTag, localTags, ...} =>
          (case argTypeOpt of
             NONE =>
             let
               fun encloseInList strings =
                   "(List.concat[" ^ (U.interleaveString ", " strings) ^ "])"
               val expList = 
                   map
                     (translateTemplate
                        (F, initialTypeEnv, P, prefix)
                        false)
                     (#templates primaryTag)
               val exp = expListToCode expList
             in
               exp
(*
               encloseInList
                   (map
                        (translateTemplate
                             (F, initialTypeEnv, P, prefix)
                             false)
                        (#templates primaryTag))
*)
             end
           | SOME ty =>
             translateType
                 (F, P, prefix)
                 (primaryTag, localTags, false, argVarName, ty))

        | NONE => (* generate default formatter *)
          case argTypeOpt of
            NONE =>
            "[" ^
            prefixOfFormatExpressionName ^ "Term" ^
            "(" ^
            (Int.toString(size valConName)) ^ ", \"" ^ valConName ^ "\"" ^
            ")" ^
            "]"
          | SOME ty =>
            let
              val ({id, typepat, templates}, localFormatTags) =
                  generateDefaultFormatTags ty
              val formatTag =
                  {
                    id = id,
                    typepat = typepat,
                    templates =
                    [F.Guard
                     (
                       SOME assocOfTyConApp,
                       F.Term(valConName) :: s_1_Indicator :: templates
                     )]
                  }
            in
              translateType
                  (F, P, prefix)
                  (formatTag, localFormatTags, true, argVarName, ty)
            end
      end
      
  (**
   *  generates a SML code of body of formatter for the datatype binding.
   * @params (F, P, prefix, ditto) (formatterName, datatypeDef)
   * @param F the formatter environment
   * @param P the additional parameter set
   * @param prefix the prefix indicating the current namespace
   * @param list of ditto prefixes (EXPERIMENTAL EXTENSION by Ueno)
   * @param formatterName the name of formatter to generate
   * @param datatypeDef an AST node of the datatype definition generated by
   *                the parser.
   * @return a text of SML code of formatter
   *)
  fun generateForDataTypeBind
      (F, formatParams, prefix, ditto)
      (
        formatterName,
        {tyConName, tyvars, rhs = Ast.Constrs valconBinds, lazyp,
         innerHeaderFormatComments : Ast.innerHeaderFormatComment list}
      ) =
      let
        val localParams = List.concat (map #params innerHeaderFormatComments)
        val params = case localParams of nil => formatParams
                                       | _ => localParams
        val varNameForValConArg = generateUniqueName "x" params
        val varNameForFormatterArg = generateUniqueName "y" params
        val tyvarNames = map getTyVarName tyvars
        val formatterNames =
            map
            (fn tyvarName => prefixOfLocalFormatterName ^ tyvarName)
            tyvarNames
        val F' =
            foldl
            (fn ((tyvarName, formatterName), F) =>
                addToFormatterEnv F (SOME prefix, tyvarName, formatterName))
            F
            (zipEq (tyvarNames, formatterNames))
        val P =
            foldl
            (fn (param, P) => addToParameterSet P param)
            initialParameterSet
            params
        val exps =
            map
            (generateForValConBind (F', P, prefix, ditto) varNameForValConArg)
            valconBinds
        val rules =
            map
            (fn ({valConName, argTypeOpt, ...}, exp) =>
                valConName ^
                (case argTypeOpt
                  of NONE => ""
                   | SOME ty => " " ^ varNameForValConArg ^ " ") ^
                " => (" ^ exp ^ ")")
            (zipEq (valconBinds, exps))
      in
        formatterName ^
        (if (null formatterNames) andalso (null params)
         then " "
         else
           "(" ^ (U.interleaveString ", " (formatterNames @ params)) ^ ")") ^
        " " ^ varNameForFormatterArg ^ " = " ^
        "case " ^ varNameForFormatterArg ^ " of " ^ newline ^
        (U.interleaveString (newline ^ " | ") rules) ^ newline
      end
    | generateForDataTypeBind
      (F, params, prefix, ditto)
      (
        formatterName,
        {tyConName, tyvars, rhs = Ast.Repl replTyConName, lazyp, ...}
      ) =
      let val formatterOfRepl = F (prefix, Ast.ConTy(replTyConName, []))
      in
        (* tyvars must be null, otherwise SML compiler would complain error. *)
        formatterName ^ " x = " ^ formatterOfRepl ^ " x"
      end

  (**
   *  generates a SML code of body of formatter for a type binding.
   * @params (F, P, prefix, ditto) (formatterName, typeDef)
   * @param F the formatter environment
   * @param P the additional parameter set
   * @param prefix the prefix indicating the current namespace
   * @param list of ditto prefixes (EXPERIMENTAL EXTENSION by Ueno)
   * @param formatterName the name of formatter to generate
   * @param typeDef an AST node of the type definition generated by the parser.
   * @return a text of SML code of formatter
   *)
  fun generateForTypeBind
      (F, formatParams, prefix, ditto)
      (formatterName,
       {tyConName, tyvars, ty, formatComments,
        innerHeaderFormatComments : Ast.innerHeaderFormatComment list}) =
      let
        val localParams = List.concat (map #params innerHeaderFormatComments)
        val formatParams = case localParams of nil => formatParams
                                             | _ => localParams
        fun isSamePrefix prefix (formatComment : Ast.definingFormatComment) =
            #prefix formatComment = prefix
        val ((primaryTag, localTags), isDefault) =
            case findOneOf (prefix::ditto) isSamePrefix formatComments of
              NONE => (generateDefaultFormatTags ty, true)
            | SOME {primaryTag, localTags, ...} =>
              ((primaryTag, localTags), false)

        val varNameForArg = generateUniqueName "x" formatParams
        val tyvarNames = map getTyVarName tyvars
        val formatterNames =
            map
            (fn tyvarName => prefixOfLocalFormatterName ^ tyvarName)
            tyvarNames
        val F' =
            foldl
            (fn ((tyvarName, formatterName), F) =>
                addToFormatterEnv F (SOME prefix, tyvarName, formatterName))
            F
            (zipEq (tyvarNames, formatterNames))
        val P =
            foldl
            (fn (param, P) => addToParameterSet P param)
            initialParameterSet
            formatParams
        val exp =
            translateType
                (F', P, prefix)
                (primaryTag, localTags, isDefault, varNameForArg, ty)
      in
        formatterName ^
        (if (null formatterNames) andalso (null formatParams)
         then " "
         else
           "(" ^
           (U.interleaveString ", " (formatterNames @ formatParams)) ^
           ")") ^
        " " ^ varNameForArg ^ " = " ^ newline ^ exp ^ newline
      end

  (**
   *  generates a SML code of body of formatter for the exception binding.
   * @params (F, P, prefix, ditto) formatterRefName exceptionDef
   * @param F the formatter environment
   * @param P the additional parameter set
   * @param prefix the prefix indicating the current namespace
   * @param ditto list of super-prefixes (EXPERIMENTAL EXTENSION by Ueno)
   * @param formatterRefName the name of formatter to generate
   * @param exceptionDef an AST node of the exception definition generated by
   *                the parser.
   * @return a text of SML code of formatter
   *)
  fun generateForExceptionBind
      (F, formatParams, prefix, ditto)
      formatterRefName
      (Ast.EbGen
         {formatComments, exn, etype,
          innerHeaderFormatComments : Ast.innerHeaderFormatComment list}) =
      let
        val localParams = List.concat (map #params innerHeaderFormatComments)
        val params = case localParams of nil => formatParams
                                       | _ => localParams
        val formatExnName = F(prefix, Ast.ConTy(["exn"], []))
        val varNameForValConArg = generateUniqueName "x" params
        val varNameForFormatterArg = generateUniqueName "y" params
        val P =
            foldl
            (fn (param, P) => addToParameterSet P param)
            initialParameterSet
            params
        val exp =
            generateForValConBind
                (F, P, prefix, ditto)
                varNameForValConArg
                {
                  formatComments = formatComments,
                  valConName = exn,
                  argTypeOpt = etype
                }
        val rule =
            exn ^ 
            (case etype of
               NONE => ""
             | SOME ty => " " ^ varNameForValConArg ^ " ")
            ^ " => (" ^ exp ^ ")"
        val paramsList = 
            if (null params)
            then " "
            else "(" ^ (U.interleaveString ", " params) ^ ")"
      in
        "local val prev_format = !" ^ formatterRefName ^ newline ^
        "fun format " ^ paramsList ^ " " ^ varNameForFormatterArg ^ " = " ^
        "case " ^ varNameForFormatterArg ^ " of " ^ newline ^
        rule ^ newline ^
        " | _ => prev_format " ^ varNameForFormatterArg ^ newline ^
        "val _ = " ^ formatterRefName ^ " := format " ^ newline ^
        "in end" ^ newline
      end
    | generateForExceptionBind
      (F, params, prefix, ditto)
      formatterRefName
      (Ast.EbDef{formatComments, exn, edef, innerHeaderFormatComments}) =
      (* formatter is not generated for EbDef *)
      if null formatComments andalso null innerHeaderFormatComments
      then ""
      else
        raise
          InternalError
          (Unimplemented
           "format comment for exception definition using other exception.")
    | generateForExceptionBind _ _ _ = 
      raise Fail "Bug: illeagal param to generateForExceptionBind"
  (****************************************)

  (**
   * unwrap Ast.Tb.
   * @params tb
   * @param tb Ast.tb
   * @return an Ast.Tb
   *)
  fun getTb (Ast.MarkTb (tb, _)) = getTb tb
    | getTb (Ast.Tb tb) = tb

  (**
   * unwrap Ast.Db.
   * @params db
   * @param db Ast.db
   * @return an Ast.Db
   *)
  fun getDb (Ast.MarkDb (db, _)) = getDb db
    | getDb (Ast.Db db) = db

  (**
   * unwrap Ast.Eb.
   * @params eb
   * @param eb Ast.eb
   * @return an Ast.Eb
   *)
  fun getEb (Ast.MarkEb (eb, _)) = getEb eb
    | getEb eb = eb

  fun wrapInStructureAlias declaration = declaration
(*
  fun wrapInStructureAlias declaration =
      "local structure " ^ aliasOfFormatExpressionStructure ^ " = " ^
      structureNameOfFormatExpression ^ newline ^
      " in " ^ declaration ^ " end " ^ newline
*)

  (**
   * resolve ditto references. (EXPERIMENTAL EXTENSION by Ueno)
   * @params formatComments
   * @param formatComments
   * @return formatComments with complete list of ancestor prefixes and
   *         inherited formatters.
   *)
  fun resolveDitto (formatComments : Ast.headerFormatComment list) =
      let
        fun error msg =
            raise InternalError(DittoError(msg))

        fun find prefix =
            case List.find (fn {prefix=p,...} => p = prefix) formatComments of
              SOME x => x
            | NONE => error ("undefined prefix `"^prefix^"'")

        fun copyFormatters (fmt as {formatters, ditto, ...}
                            : Ast.headerFormatComment) =
            {
              destinationOpt = #destinationOpt fmt,
              funHeaderOpt = #funHeaderOpt fmt,
              params = #params fmt,
              ditto = ditto,
              prefix = #prefix fmt,
              formatters =
                foldl (fn (prefix, z) => #formatters (find prefix) @ z)
                      formatters
                      ditto
            } : Ast.headerFormatComment

        val modified = ref false
        val newFormatComments =
            map (fn fmt as {ditto = nil, ...} => fmt
                  | fmt as {prefix, ditto, ...} =>
                    case #ditto (find (List.last ditto)) of
                      nil => fmt
                    | l =>
                      case List.find (fn p => p = prefix) l of
                        SOME _ => error ("ditto chain is looped: "^prefix)
                      | NONE => 
                        (modified := true;
                         {
                           destinationOpt = #destinationOpt fmt,
                           formatters = #formatters fmt,
                           funHeaderOpt = #funHeaderOpt fmt,
                           params = #params fmt,
                           ditto = ditto @ l,
                           prefix = prefix
                         } : Ast.headerFormatComment))
                formatComments
      in
        if !modified
        then resolveDitto newFormatComments
        else map copyFormatters newFormatComments
      end

  (**
   * generates SML code of the formatter for a datatype declaration.
   *
   * @params formatterEnv (regionOpt, dec)
   * @param formatterEnv the formatter environment
   * @param regionOpt the region of the dec
   * @param dec the datatype declaration
   * @return a pair of
   * <ul>
   *   <li>a list of pairs of<ul>
   *     <li>destination of generated code</li>
   *     <li>SML code text of the formatters for the type</li>
   *     </ul></li>
   *   <li>the new formatter environment extended with the generated
   *     formatters.</li>
   * </ul>
   *)
  fun generateForDataTypeDec
          F (regionOpt, Ast.DatatypeDec (decInfo as {formatComments, ...})) =
      (let
        val datatypeBinds = map getDb (#datatycs decInfo)
        val typeBinds = map getTb (#withtycs decInfo)
        val datatypeNames = map #tyConName datatypeBinds
        val typeNames = map #tyConName typeBinds
        fun isConflictWithTyConName name = 
            List.exists (fn tyConName => name = tyConName) datatypeNames
            orelse List.exists (fn tyConName => name = tyConName) typeNames

        fun generate
            (
              {destinationOpt, funHeaderOpt, formatters, params, prefix, ditto}
              : Ast.headerFormatComment,
              (formatterCodes, F)
            ) =
            let
              val funHeader = case funHeaderOpt of
                                NONE => DefaultFunctionHeader
                              | SOME header => header

              (* F' = local formatters + previously defined formatters *)
              val F' =
                  foldl
                  (fn ((typeName, formatterName), F) =>
                      if isConflictWithTyConName typeName
                      then
                        raise InternalError(CustomFormatNameConflict typeName)
                      else
                        addToFormatterEnv
                            F (SOME prefix, typeName, formatterName))
                  F
                  formatters

              (* build a formatter env which holds current defined formatters.
               *)
              val datatypeFormatterNames =
                  map (fn tyConName => prefix ^ tyConName) datatypeNames
              val typeFormatterNames = 
                  map (fn tyConName => prefix ^ tyConName) typeNames
              (* F'' contains current defined formatters only. *)
              val F'' = 
                  foldl
                      (fn ((tyConName, formatterName), F) =>
                          addToFormatterEnv
                              F (SOME prefix, tyConName, formatterName))
                      initialFormatterEnv
                      ((zipEq (datatypeNames, datatypeFormatterNames)) @
                       (zipEq (typeNames, typeFormatterNames)))

              (*  F''' = current defined formatters
               *       + local formatters
               *       + previously defined formatters. *)
              val F''' = appendFormatterEnv (F'', F')

              (* generate codes of formatters for each datatype bindings. *)
              val tyconFormatters =
                  (map
                       (generateForDataTypeBind (F''', params, prefix, ditto))
                       (zipEq (datatypeFormatterNames, datatypeBinds))) @
                  (map
                       (generateForTypeBind (F''', params, prefix, ditto))
                       (zipEq (typeFormatterNames, typeBinds)))
            in
              (
                formatterCodes @
                [(
                   destinationOpt,
                   wrapInStructureAlias
                   (funHeader ^ " " ^
                    (U.interleaveString " \nand " tyconFormatters))
                 )],
                appendFormatterEnv (F'', F) (* excludes local formatters *)
              )
            end

        val formatComments = resolveDitto formatComments
      in
        (* process left to right *)
        foldl generate ([], F) formatComments
      end
        handle error =>
               raise
               (translateError
                (
                  error,
                  if isSome regionOpt then valOf regionOpt else unknownRegion
                ))
      )
    | generateForDataTypeDec _ _ =
      raise Fail "Bug: illeagal param to generateForDataTypeDec"

  (**
   * generates SML code of the formatter for a type declaration.
   *
   * @params formatterEnv (regionOpt, dec)
   * @param formatterEnv the formatter environment
   * @param regionOpt the region of the dec
   * @param dec the type declaration
   * @return a pair of
   * <ul>
   *   <li>a list of pairs of<ul>
   *     <li>destination of generated code</li>
   *     <li>SML code text of the formatters for the type</li>
   *     </ul></li>
   *   <li>the new formatter environment extended with the generated
   *     formatters.</li>
   * </ul>
   *)
  fun generateForTypeDec F (regionOpt, Ast.TypeDec {formatComments, tbs}) =
     (let
        val typeBinds = map getTb tbs
        val typeNames = map #tyConName typeBinds
        fun isConflictWithTyConName name = 
            List.exists (fn tyConName => name = tyConName) typeNames

        fun generate
            (
              {destinationOpt, funHeaderOpt, formatters, params, prefix, ditto}
              : Ast.headerFormatComment,
              (formatterCodes, F)
            ) =
            let
              val funHeader = case funHeaderOpt of
                                NONE => DefaultFunctionHeader
                              | SOME header => header

              (* F' = local formatters + previously defined formatters *)
              val F' =
                  foldl
                  (fn ((typeName, formatterName), F) =>
                      if isConflictWithTyConName typeName
                      then
                        raise InternalError(CustomFormatNameConflict typeName)
                      else
                        addToFormatterEnv
                            F (SOME prefix, typeName, formatterName))
                  F
                  formatters

              (* build a formatter env consisting of current defined
               * formatters.*)
              val formatterNames = map (fn name => prefix ^ name) typeNames
              val F'' = (* F'' contain only current defined formatters *)
                  foldl
                      (fn ((tyConName, formatterName), F) =>
                          addToFormatterEnv
                              F (SOME prefix, tyConName, formatterName))
                      initialFormatterEnv
                      (zipEq (typeNames, formatterNames))

              (*  F''' = current defined formatters
               *       + local formatters
               *       + previously defined formatters. *)
              val F''' = appendFormatterEnv (F'', F')

              (* generate codes of formatters for each type bindings. *)
              val tyconFormatters =
                  map
                      (generateForTypeBind (F''', params, prefix, ditto))
                      (zipEq (formatterNames, typeBinds))
            in
              (
                formatterCodes @
                [(
                   destinationOpt,
                   wrapInStructureAlias
                   (funHeader ^ " " ^
                    (U.interleaveString " \nand " tyconFormatters))
                 )],
                appendFormatterEnv (F'', F) (* excludes local formatters *)
              )
            end

        val formatComments = resolveDitto formatComments
      in
        foldl generate ([], F) formatComments
      end
        handle error =>
               raise
               (translateError
                (
                  error,
                  if isSome regionOpt then valOf regionOpt else unknownRegion
                ))
     )
    | generateForTypeDec _ _ = raise Fail "Bug: illeagal param to generateForTypeDec"
  (**
   * generates SML code of the formatter for a exception declaration.
   *
   * @params formatterEnv (regionOpt, dec)
   * @param formatterEnv the formatter environment
   * @param regionOpt the region of the dec
   * @param dec the exception declaration
   * @return a pair of
   * <ul>
   *   <li>a list of pairs of<ul>
   *     <li>destination of generated code</li>
   *     <li>SML code text of the formatters for the exception</li>
   *     </ul></li>
   *   <li>the new formatter environment extended with the generated
   *     formatters.</li>
   * </ul>
   *)
  fun generateForExceptionDec
          F (regionOpt, Ast.ExceptionDec {formatComments, ebs}) =
     (let
        val exceptionBinds = map getEb ebs

        fun generate
            (
              {destinationOpt, funHeaderOpt, formatters, params, prefix, ditto}
              : Ast.headerFormatComment,
              (formatterCodes, F)
            ) =
            let
              val prefix =
                  if prefix = Ast.DefaultFormatterPrefix
                  then prefix
                  else
                    raise
                      InternalError
                          (Unimplemented "prefix for exception formatter.")

              val _ = 
                  case funHeaderOpt of
                    NONE => DefaultFunctionHeader
                  | SOME header => 
                    raise
                      InternalError
                          (Unimplemented "funheader for exception formatter.")

              (* F' = local formatters + previously defined formatters *)
              val F' =
                  foldl
                  (fn ((typeName, formatterName), F) =>
                      addToFormatterEnv
                          F (SOME prefix, typeName, formatterName))
                  F
                  formatters

              val formatterExnRefName = DefaultFormatterExnRefName

              (* generate codes of formatters for each type bindings. *)
              val exceptionFormatters =
                  map
                  (generateForExceptionBind
                       (F', params, prefix, ditto)
                       formatterExnRefName)
                  exceptionBinds
            in
              (
                formatterCodes @
                [(
                   destinationOpt,
                   wrapInStructureAlias
                    (U.interleaveString " \n " exceptionFormatters)
                 )],
                F (* exclude local formatters. *)
              )
            end

        val formatComments = resolveDitto formatComments
      in
        foldl generate ([], F) formatComments
      end
        handle error =>
               raise
                 translateError(error, Option.getOpt(regionOpt, unknownRegion))
     )
    | generateForExceptionDec _ _ = 
      raise Fail "Bug: illeagal param to generateForExceptionDec"

  (***************************************************************************)

end
