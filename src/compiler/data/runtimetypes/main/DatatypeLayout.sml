(**
 * datatype layout
 *
 * @copyright (C) 2021 SML# Development Team.
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
   * another of which has a non-null boxed argument, the no-argument
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
   * If there is just one variant without argument, it is implemented as unit.
   *     datatype foo = Foo                   --> unit
   *
   * (NOTE: this layout is for future optimization; the tag of Foo can be
   *  any integer.  Currently, we fix Foo to 0 because of the same reason
   *  as LAYOUT_CHOICE.)
   *
   * LAYOUT_REF:
   *
   * The special case for the ref type.
   *)

  structure R = RuntimeTypes

  fun tagProp layout =
      RuntimeTypes.contagProp # {rep = R.DATA layout}

  fun recordProp layout =
      RuntimeTypes.recordProp # {rep = R.DATA layout}

  fun classify conSet =
      SymbolEnv.foldri
        (fn (name, SOME ty, {some, none}) =>
            {some = (name, ty) :: some, none = none}
          | (name, NONE, {some, none}) =>
            {some = some, none = name :: none})
        {some = nil, none = nil}
        conSet

  fun makeTagMap conSet =
      map Symbol.symbolToString (SymbolEnv.listKeys conSet)

  fun propertyOf ty =
      case IDCalc.propertyOfIty ty of
        SOME (IDCalc.PROP prop) => SOME prop
      | _ => NONE

  fun datatypeLayout conSet =
      case classify conSet of
        {some = nil, none = nil} => raise Bug.Bug "layout: no variant"
      | {some = nil, none = [_]} =>
        tagProp R.LAYOUT_SINGLE
      | {some = nil, none = [name1, name2]} =>
        tagProp (R.LAYOUT_CHOICE {falseName = Symbol.symbolToString name1})
      | {some = nil, none = _::_} =>
        tagProp (R.LAYOUT_TAGGED
                   (R.TAGGED_TAGONLY {tagMap = makeTagMap conSet}))
      | {some = [(name, ty)], none = nil} =>
        (case propertyOf ty of
           SOME {tag = R.TAG R.BOXED, ...} =>
           recordProp (R.LAYOUT_SINGLE_ARG {wrap = false})
         | _ =>
           recordProp (R.LAYOUT_SINGLE_ARG {wrap = true}))
      | {some = [(name1, ty)], none = [name2]} =>
        let
          val wrap =
              case propertyOf ty of
                NONE => true
              | SOME {tag = R.ANYTAG, ...} => true
              | SOME {tag = R.TAG R.UNBOXED, ...} => true
              | SOME (prop as {tag = R.TAG R.BOXED, rep, ...}) =>
                not (RuntimeTypes.canBeRegardedAs (prop, R.recordProp))
        in
          recordProp (R.LAYOUT_ARG_OR_NULL {wrap = wrap})
        end
      | {some, none = [name]} =>
        recordProp
          (R.LAYOUT_TAGGED
             (R.TAGGED_OR_NULL {tagMap = makeTagMap conSet,
                                nullName = Symbol.symbolToString name}))
      | {some, none} =>
        recordProp (R.LAYOUT_TAGGED
                      (R.TAGGED_RECORD {tagMap = makeTagMap conSet}))

end
