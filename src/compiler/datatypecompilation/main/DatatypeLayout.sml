(**
 * datatype layout
 *
 * @copyright (c) 2016, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure DatatypeLayout =
struct

  (*
   * The "layout" of a datatype describes how its variants are implemented.
   *
   * LAYOUT_TAGGED (TAGGED_RECORD):
   *
   * This is the most generic layout; this is selected if the datatype does
   * not agree with any other layouts below.
   * Each variant is implemented as a pair of a tag and its argument.
   *     datatype 'a foo = Foo of int * int   --> {1: contagty, 2: int * int}
   *                     | Bar of bool        --> {1: contagty, 2: bool}
   *                     | Baz of 'a          --> {1: contagty, 2: 'a}
   *                     | Hoge               --> {1: contagty}
   *                     | Fuga               --> {1: contagty}
   *
   * LAYOUT_TAGGED (TAGGED_OR_NULL):
   *
   * This is a special case of LAYOUT_TAGGED(TAGGED_RECORD);
   * if only one variant has no argument but others have arguments,
   * the no-argument variant is implemented as a null pointer, and others
   * are implemented as pairs.
   *     datatype 'a foo = Foo of int * int   --> {1: contagty, 2: int * int}
   *                     | Bar of bool        --> {1: contagty, 2: bool}
   *                     | Baz of 'a          --> {1: contagty, 2: 'a}
   *                     | Hoge               --> boxed (NULL)
   *
   * LAYOUT_ARG_OR_NULL {wrap=false}:
   *
   * If there are just two variants, one of which has no argument and
   * another of which has non-null boxed argument, the no-argument
   * variant is implemented as a null pointer.
   *     datatype foo = Foo of int * foo      --> int * foo
   *                  | Bar                   --> boxed (NULL)
   *
   * (NOTE: The argument of Foo must be a non-null boxed value.
   *  Otherwise, two variants cannot be distinguished from each other.
   *  See also the "nat" case in LAYOUT_WRAP_OR_NULL {wrap=true}.)
   *
   * LAYOUT_ARG_OR_NULL: {wrap=true}:
   *
   * This is a generic case of LAYOUT_ARG_OR_NULL {wrap=false};
   * if there are just two variants, one of which has no argument and
   * another of which has an argument, and the argument may be either an
   * unboxed value or a null pointer, the argument is wrapped by a
   * one-field record to force the with-argument variant to be a non-null
   * boxed value.
   *     datatype foo = Foo of int            --> {1: int}
   *                  | Bar                   --> boxed (NULL)
   *     datatype 'a foo = Foo of 'a          --> {1: 'a}
   *                     | Bar                --> boxed (NULL)
   *     datatype nat = Succ of nat           --> {1: nat}
   *                  | Zero                  --> boxed (NULL)
   *     datatype f = F1 of b                 --> {1: b}
   *                | F2                      --> boxed (NULL)
   *          and b = B1 of f                 --> {1: f}
   *                | B2                      --> boxed (NULL)
   *
   * (NOTE: In the case of nat, the argument of "Succ" must be wrapped.
   *  Otherwise, any value of nat type would be a null pointer.)
   *
   * LAYOUT_SINGLE_ARG {wrap=false}:
   *
   * If the datatype consists of just one variant with a boxed argument,
   * the implementation of the datatype is equal to that of the argument.
   *     datatype foo = Foo of int * int     --> int * int
   *     datatype void = Void of void        --> boxed
   *
   * LAYOUT_SINGLE_ARG {wrap=true}:
   *
   * If the datatype consists of just one variant that may not be a boxed
   * argument, the argument is wrapped with a one-field record.
   *     datatype 'a foo = Foo of 'a         --> {1: 'a}
   *     datatype foo = Foo of int           --> {1: int}
   *
   * LAYOUT_TAGGED (TAGGED_TAGONLY):
   *
   * If there are more than two variants and all of them have no argument,
   * they are implemented as some distinct integers.
   *     datatype foo = Foo                  --> contagty
   *                  | Bar                  --> contagty
   *                  | Baz                  --> contagty
   *
   * LAYOUT_CHOICE:
   *
   * If there are just two variants and both of them have no argument,
   * they are implemented as integer 0 and 1.
   *     datatype foo = Bar                   --> contagty (0)
   *                  | Foo                   --> contagty (1)
   *
   * (NOTE: this layout is distingished from LAYOUT_TAGGED (TAGGED_TAGONLY)
   * for future optimization; the tag of Foo can be any integer other than 0.
   * Currently, we fix Foo to 1 since polymorphic equality is implemented
   * by runtime bit-by-bit equality check.)
   *
   * LAYOUT_SINGLE:
   *
   * If there is just one variant without argument, it is implemented as 0.
   *     datatype foo = Foo                   --> contagty (0)
   *
   * (NOTE: this layout is for future optimization; the tag of Foo can be
   *  any integer.  Currently, we fix Foo to 0 because of the same reason
   *  as LAYOUT_CHOICE.)
   *
   * LAYOUT_REF:
   *
   * The special case for the ref type.
   *)

  datatype taggedLayout =
      TAGGED_RECORD of {tagMap: int SymbolEnv.map}
    | TAGGED_OR_NULL of {tagMap: int SymbolEnv.map, nullName: Symbol.symbol}
    | TAGGED_TAGONLY of {tagMap: int SymbolEnv.map}

  datatype layout =
      LAYOUT_TAGGED of taggedLayout
    | LAYOUT_ARG_OR_NULL of {wrap: bool}
    | LAYOUT_SINGLE_ARG of {wrap: bool}
    | LAYOUT_CHOICE of {falseName: Symbol.symbol}
    | LAYOUT_SINGLE
    | LAYOUT_REF

  fun runtimeTyOf layout =
      case layout of
        LAYOUT_TAGGED (TAGGED_RECORD _) => BuiltinTypeNames.BOXEDty
      | LAYOUT_TAGGED (TAGGED_OR_NULL _) => BuiltinTypeNames.BOXEDty
      | LAYOUT_TAGGED (TAGGED_TAGONLY _) => BuiltinTypeNames.CONTAGty
      | LAYOUT_ARG_OR_NULL _ => BuiltinTypeNames.BOXEDty
      | LAYOUT_SINGLE_ARG _ => BuiltinTypeNames.BOXEDty
      | LAYOUT_CHOICE _ => BuiltinTypeNames.CONTAGty
      | LAYOUT_SINGLE => BuiltinTypeNames.CONTAGty
      | LAYOUT_REF => BuiltinTypeNames.REFty

  fun classify conSet =
      SymbolEnv.foldri
        (fn (name, SOME ty, {some, none}) =>
            {some = (name, ty) :: some, none = none}
          | (name, NONE, {some, none}) =>
            {some = some, none = name :: none})
        {some = nil, none = nil}
        conSet

  fun makeTagMap conSet =
      #2 (SymbolEnv.foldli
            (fn (key, _, (i, map)) =>
                (i + 1, SymbolEnv.insert (map, key, i)))
            (1, SymbolEnv.empty)
            conSet)

  fun isBoxedTy ty =
      case TypeLayout2.runtimeTy BoundTypeVarID.Map.empty ty of
        SOME RuntimeTypes.BOXEDty => true
      | _ => false

  fun isNotNull circularCheck ty =
      case TypesBasics.derefTy ty of
        Types.POLYty {body, ...} => isNotNull circularCheck body
      | Types.CONSTRUCTty {tyCon as {conSet, ...}, ...} =>
        not (TypID.Set.member (circularCheck, #id tyCon))
        andalso not (SymbolEnv.isEmpty conSet)
        andalso (case layoutOf circularCheck tyCon of
                   LAYOUT_TAGGED (TAGGED_RECORD _) => true
                 | LAYOUT_TAGGED (TAGGED_OR_NULL _) => false
                 | LAYOUT_TAGGED (TAGGED_TAGONLY _) => true
                 | LAYOUT_ARG_OR_NULL _ => false
                 | LAYOUT_CHOICE _ => true
                 | LAYOUT_SINGLE => true
                 | LAYOUT_REF => true
                 | LAYOUT_SINGLE_ARG {wrap=true} => true
                 | LAYOUT_SINGLE_ARG {wrap=false} =>
                   case SymbolEnv.listItems conSet of
                     [SOME ty] => isNotNull circularCheck (ty ())
                   | _ => false)
      | _ => true

  and layoutOf circularCheck (tyCon as {id, conSet, ...}:Types.tyCon) =
      case classify conSet of
        {some = nil, none = nil} => raise Bug.Bug "layout: no variant"
      | {some = nil, none = [_]} => LAYOUT_SINGLE
      | {some = nil, none = [name1, name2]} =>
        (
          TypID.eq (id, #id BuiltinTypes.boolTyCon)
          andalso (Symbol.symbolToString name1 = "false"
                   orelse raise Fail "layout: bool");
          LAYOUT_CHOICE {falseName = name1}
        )
      | {some = nil, none = _::_} =>
        LAYOUT_TAGGED (TAGGED_TAGONLY {tagMap = makeTagMap conSet})
      | {some = [(name, ty)], none = nil} =>
        if TypID.eq (#id BuiltinTypes.refTyCon, id)
        then LAYOUT_REF
        else LAYOUT_SINGLE_ARG {wrap = not (isBoxedTy (ty ()))}
      | {some = [(name1, ty)], none = [name2]} =>
        let
          val ty = ty ()
          val nonNullArg =
              isBoxedTy ty
              andalso isNotNull (TypID.Set.add (circularCheck, id)) ty
        in
          LAYOUT_ARG_OR_NULL {wrap = not nonNullArg}
        end
      | {some, none = [name]} =>
        LAYOUT_TAGGED (TAGGED_OR_NULL {tagMap = makeTagMap conSet,
                                       nullName = name})
      | {some, none} =>
        LAYOUT_TAGGED (TAGGED_RECORD {tagMap = makeTagMap conSet})

  fun datatypeLayout (tyCon as {runtimeTy, ...}) =
      let
        val layout = layoutOf TypID.Set.empty tyCon
      in
        if runtimeTyOf layout = runtimeTy
        then layout
        else raise Bug.Bug "datatypeLayout"
      end

end
