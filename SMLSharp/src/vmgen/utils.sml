structure Utils =
struct

  structure I = InsnDef

  structure IMap =
      BinaryMapFn(type ord_key = int val compare = Int.compare)
  structure SMap =
      BinaryMapFn(type ord_key = string val compare = String.compare)

  fun checkDuplication eq nil = NONE
    | checkDuplication eq (h::t) =
      case List.find (fn x => eq (h, x)) t of
        SOME x => SOME (h, x)
      | NONE => checkDuplication eq t

  fun isSubset eq (l1, l2) =
      List.all (fn x => List.exists (fn y => eq (x, y)) l2) l1
  fun equalSet eq (l1, l2) =
      isSubset eq (l1, l2) andalso isSubset eq (l2, l1)

  fun cluster eq elems =
      let
        fun gather x sames difs nil = (rev sames, rev difs)
          | gather x sames difs (h::t) =
            if eq (h, x)
            then gather x (h::sames) difs t
            else gather x sames (h::difs) t

        fun clustering nil = nil
          | clustering (h::t) =
            let val (sames, difs) = gather h nil nil t
            in (h::sames) :: clustering difs
            end
      in
        clustering elems
      end

  fun sortBy f l =
      let
        fun sort nil = nil
          | sort ((h as (n,_))::t) =
            sort (List.filter (fn (m,_) => m < n) t) @ [h] @
            sort (List.filter (fn (m,_) => m >= n) t)
      in
        map #2 (sort (map (fn x => (f x, x)) l))
      end

  fun uniq eq l =
      map List.hd (cluster eq l)

  fun mapi f l =
      let
        fun map f n (h::t) = f (n, h) :: map f (n + 1) t
          | map f n nil = nil
      in
        map f 0 l
      end

  fun index f l =
      let
        fun ind f n nil = NONE
          | ind f n (h::t) = if f h then SOME n else ind f (n+1) t
      in
        ind f 0 l
      end


  fun toUpper s =
      String.implode (map Char.toUpper (String.explode s))
  fun toLower s =
      String.implode (map Char.toLower (String.explode s))

  fun join sep nil = ""
    | join sep (h::t) =
      let
        fun f sep (h::t) = sep ^ h ^ f sep t
          | f sep nil = ""
      in
        h ^ f sep t
      end


  fun evalMetaif f (meta as I.META _) = meta
    | evalMetaif f (I.METAIF (conds, metaThen, metaElse)) =
      let
        fun eval b l nil = (b, rev l)
          | eval b l (cond::conds) =
            case f cond of
              NONE => eval b (cond::l) conds
            | SOME x => eval (b andalso x) l conds
      in
        case eval true nil conds of
          (false, _) => evalMetaif f metaElse
        | (true, nil) => evalMetaif f metaThen
        | (true, conds) =>
          I.METAIF (conds, evalMetaif f metaThen, evalMetaif f metaElse)
      end

  fun expandMetaif f meta =
      let
        fun expand conds (I.METAIF (conds2, metaThen, metaElse)) =
            expand (conds @ map f conds2) metaThen @ expand conds metaElse
          | expand conds (I.META (x, pos)) =
            [(conds, x, pos)]
      in
        expand nil meta
      end


  fun tyToSuffix ty =
      case ty of
        I.W => "w"
      | I.L => "l"
      | I.N => "n"
      | I.NL => "nl"
      | I.F => "f"
      | I.FS => "fs"
      | I.FL => "fl"
      | I.P => "p"
      | _ => raise Control.Bug ("tyToSuffix: "^I.formatTy ty)

  val allMnemonicTys =
      [I.W, I.L, I.N, I.NL, I.F, I.FS, I.FL, I.P]

  fun isExhaustiveSuffix tyList =
      equalSet (op =) (tyList, allMnemonicTys)

  fun insnName (name, ty) =
      case ty of
        SOME ty => name ^ tyToSuffix ty
      | NONE => name

  fun conName x =
      toUpper x

  fun argToVar arg =
      I.formatArg arg

  fun toMnemonicArgValue (arg, ty, value) =
      let
        fun fmtWord x = Word.fmt StringCvt.DEC (Word.fromInt x)
        fun fmtInt x = Int.toString x
      in
        case (arg, ty, value) of
          (_, I.W, SOME x) => "0w"^fmtWord x^":I.w"
        | (_, I.L, SOME x) => "0w"^fmtWord x^":I.l"
        | (_, I.N, SOME x) => fmtInt x^":I.n"
        | (_, I.NL, SOME x) => fmtInt x^":I.nl"
        | (_, I.F, SOME x) => "\"" ^ fmtInt x ^ ".0\":I.f"
        | (_, I.FS, SOME x) => "\"" ^ fmtInt x ^ ".0\":I.fs"
        | (_, I.FL, SOME x) => "\"" ^ fmtInt x ^ ".0\":I.fl"
        | (_, I.RI, SOME x) => "I.REG 0w"^fmtWord x
        | (_, I.LI, SOME x) => "I.VAR 0w"^fmtWord x
        | (_, I.SC, SOME x) => "0w"^fmtWord x^":I.sc"
        | (_, I.SH, SOME x) => "0w"^fmtWord x^":I.sh"
        | (_, I.SZ, SOME x) => "0w"^fmtWord x^":I.sz"
        | (_, I.LSZ, SOME x) => "0w"^fmtWord x^":I.lsz"
        | (_, I.SSZ, SOME x) => fmtInt x^":I.ssz"
        | (arg, I.RI, NONE) => "I.REG "^argToVar arg
        | (arg, I.LI, NONE) => "I.VAR "^argToVar arg
        | (arg, _, NONE) => argToVar arg
        | _ => raise Control.Bug ("toMnemonicArgValue "^I.formatTy ty)
      end

  (* FIXME: should be integrated into toMnemonicArgValue *)
  fun fixedArgToBind insnTy (arg, value, pos) =
      let
        val const = Int.toString value
      in
        case arg of
          (* varX in meta equation denotes register index. *)
          I.VARX _ => (arg, "I.REG 0w"^const)
        | I.LSIZE _ => (arg, "0w"^const)
        | I.SIZE => (arg, const)
        | I.SCALE => (arg, "0w"^const)
        | I.SHIFT => (arg, "0w"^const)
        | I.DISPLACEMENT => (arg, const)
        | I.LABEL => raise Control.Bug "fixedArgToBind: LABEL"
        | I.EXTERN _ => raise Control.Bug "fixedArgToBind: EXTERN"
        | I.IMM =>
          case insnTy of
            SOME I.W => (arg, "I.CONST_W 0w"^const)
          | SOME I.L => (arg, "I.CONST_L 0w"^const)
          | SOME I.N => (arg, "I.CONST_N "^const)
          | SOME I.NL => (arg, "I.CONST_NL "^const)
          | SOME I.F => (arg, "I.CONST_F \""^const^".0\"")
          | SOME I.FS => (arg, "I.CONST_FS \""^const^".0\"")
          | _ => raise Control.Bug "fixedArgToBind: insnTy"
      end

end
