(**
 * datatype layout
 *
 * @copyright (c) 2016, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure DatatypeLayout =
struct

  (*
   * "layout" represents how to implement each data constructor of a datatype.
   *
   * LAYOUT_TAGGED_RECORD:
   * Each variant is implemented as a tuple type consisting of a tag field
   * and arguments of the variant.
   *   datatype 'a foo = Foo of int * int   --> contagty * int * int
   *                   | Bar of bool        --> contagty * bool
   *                   | Baz of 'a          --> contagty * 'a
   *   (The format of Baz is decided regardless of any instance of 'a)
   *
   * LAYOUT_TAGGED_TAGONLY:
   * If all variants have no argument, they can be distinguished only by
   * a tag integer.
   *   datatype foo = Foo                  --> contagty
   *                | Bar                  --> contagty
   *                | Baz                  --> contagty
   *
   * LAYOUT_BOOL:
   * If there are just two variant and both of them have no argument,
   * these variants can be implemented like "bool";
   * one variant is 0, and another is any integer other than 0.
   *   datatype bool = false               --> contagty (0)
   *                 | true                --> contagty (other than 0)
   *
   * (FIXME: if true is implemented as "other than 0", it may collapse
   *         dynamic bit-by-bit equality check. Currently we allow only
   *         "1" as the tag of "true".)
   *
   * LAYOUT_UNIT:
   * If there is just one variant with no argument, this can be implemented
   * like "unit"; it can be implemented with an arbitrary integer.
   *   datatype foo = Foo                  --> contagty (any integer is OK)
   *
   * (FIXME: if any tag integer is accepted, it may collapse dynamic
   *         bit-by-bit equality check. Currently we allow only "0" as
   *         the tag of this layout.)
   *
   * LAYOUT_ARGONLY:
   * If there is just one variant with an argument, no tag is needed.
   *   datatype foo = Foo of int           --> {1:int}
   *   datatype foo = Foo of int * int     --> int * int
   *   datatype 'a foo = Foo of 'a         --> {1:'a}
   *
   * LAYOUT_TAGGED_OR_NULL:
   * If there is just one variant with no argument and other variants have
   * arguments, the no-argument variant can be implemented as a null pointer.
   * Any other variants are implemented in the same way as LAYOUT_TAGGED_RECORD.
   *   datatype foo = Foo of int           --> contagty * int
   *                | Bar of int * int     --> contagty * int * int
   *                | Baz                  --> NULL (boxedty)
   *
   * LAYOUT_ARG_OR_NULL:
   * If there is just two variants and one has an argument but another does
   * not, then the no-arguemnt variant can be implemented as a null pointer.
   * The variant with argument is implemented by a record.
   *   datatype foo = Foo of int           --> {1:int}
   *                | Bar                  --> NULL (boxedty)
   *   datatype foo = Foo of int * int     --> {1:int * int}
   *                | Bar                  --> NULL (boxedty)
   *   datatype foo = Foo of foo           --> {1:foo}
   *                | Bar                  --> NULL (boxedty)
   *
   * LAYOUT_REF:
   * Special data representation for ref.
   *)
  datatype taggedLayout =
      TAGGED_RECORD of {tagMap: int SymbolEnv.map}
    | TAGGED_TAGONLY of {tagMap: int SymbolEnv.map}
    | TAGGED_OR_NULL of {tagMap: int SymbolEnv.map, nullName: Symbol.symbol}

  datatype layout =
      LAYOUT_TAGGED of taggedLayout
    | LAYOUT_BOOL of {falseName: Symbol.symbol}
    | LAYOUT_UNIT
    | LAYOUT_ARGONLY
    | LAYOUT_ARG_OR_NULL
    | LAYOUT_REF

  fun checkRepresentation (ty, layout) =
      case layout of
        LAYOUT_TAGGED (TAGGED_RECORD _) => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_TAGGED (TAGGED_TAGONLY _) => ty = BuiltinTypeNames.CONTAGty
      | LAYOUT_TAGGED (TAGGED_OR_NULL _) => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_BOOL _ => ty = BuiltinTypeNames.CONTAGty
      | LAYOUT_UNIT => ty = BuiltinTypeNames.CONTAGty
      | LAYOUT_ARGONLY => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_ARG_OR_NULL => ty = BuiltinTypeNames.BOXEDty
      | LAYOUT_REF => ty = BuiltinTypeNames.REFty

  fun categolizeConSet conSet =
      SymbolEnv.foldri
        (fn (name, SOME _, {hasArg, noArg}) =>
            {hasArg = name::hasArg, noArg = noArg}
          | (name, NONE, {hasArg, noArg}) =>
            {hasArg = hasArg, noArg = name::noArg})
        {hasArg = nil, noArg = nil}
        conSet

  fun makeTagMap conSet =
      #2 (SymbolEnv.foldli
            (fn (key, _, (i, map)) =>
                (i + 1, SymbolEnv.insert (map, key, i)))
            (1, SymbolEnv.empty)
            conSet)

  fun datatypeLayout (tyCon as {id, conSet, runtimeTy, ...}:Types.tyCon) =
      let
        val layout =
            case map isSome (SymbolEnv.listItems conSet) of
              nil => raise Bug.Bug "datatypeLayout: no variant"
            | [true] =>
              if TypID.eq (#id BuiltinTypes.refTyCon, id)
              then LAYOUT_REF
              else LAYOUT_ARGONLY
            | [false] => LAYOUT_UNIT
            | [false, false] =>
              (
                if TypID.eq (id, #id BuiltinTypes.boolTyCon)
                then LAYOUT_BOOL {falseName = Symbol.mkSymbol "false" Loc.noloc}
                else case SymbolEnv.firsti conSet of
                       SOME (name, _) => LAYOUT_BOOL {falseName = name}
                     | NONE => raise Bug.Bug "datatypeLayout: BOOL"
              )
            | _ =>
              case categolizeConSet conSet of
                {hasArg=nil, noArg=_} =>
                LAYOUT_TAGGED (TAGGED_TAGONLY {tagMap = makeTagMap conSet})
              | {hasArg=[_], noArg=[_]} =>
                LAYOUT_ARG_OR_NULL
              | {hasArg=_, noArg=[nullName]} =>
                LAYOUT_TAGGED (TAGGED_OR_NULL {tagMap = makeTagMap conSet,
                                               nullName = nullName})
              | {hasArg=_, noArg=_} =>
                LAYOUT_TAGGED (TAGGED_RECORD {tagMap = makeTagMap conSet})
      in
        if checkRepresentation (runtimeTy, layout)
        then layout
        else raise Bug.Bug "datatypeLayout"
      end

  fun needPack ty =
      case TypesBasics.derefTy ty of
        Types.RECORDty _ => false
      | Types.FUNMty _ => false
      | Types.CONSTRUCTty {tyCon, ...} =>
        (case BuiltinTypeNames.runtimeTy (#runtimeTy tyCon) of
           RuntimeTypes.BOXEDty => false
         | _ => true)
      | _ => true

end
