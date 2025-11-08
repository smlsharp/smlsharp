(**
 * syntax for the IML.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
 *)
structure Absyn =
struct
  open AbsynTy

  (*% @formatter(AbsynConst.constant) AbsynConstFormatter.format_constant *)
  datatype constant = datatype AbsynConst.constant

  (*% @formatter(id) AbsynTyFormatter.format_id *)
  datatype strid = datatype id

  (*% @formatter(id) AbsynTyFormatter.format_id *)
  datatype sigid = datatype id

  (*% @formatter(id) AbsynTyFormatter.format_id *)
  datatype funid = datatype id

  (*% @formatter(longid) AbsynTyFormatter.format_longid *)
  datatype longstrid = datatype longid

  (*% @formatter(AbsynTy.vid) AbsynTyFormatter.format_vid *)
  datatype vid = datatype AbsynTy.vid

  (*% @formatter(AbsynTy.op_longvid) AbsynTyFormatter.format_op_longvid *)
  datatype op_longvid = datatype AbsynTy.op_longvid

  (*% @formatter(AbsynTy.tycon) AbsynTyFormatter.format_tycon *)
  datatype tycon = datatype AbsynTy.tycon

  (*% @formatter(AbsynTy.longtycon) AbsynTyFormatter.format_longtycon *)
  datatype longtycon = datatype AbsynTy.longtycon

  (*% @formatter(AbsynTy.lab) AbsynTyFormatter.format_lab *)
  datatype lab = datatype AbsynTy.lab

  (*% @formatter(AbsynTy.tyvarseq) AbsynTyFormatter.format_tyvarseq *)
  datatype tyvarseq = datatype AbsynTy.tyvarseq

  (*% @formatter(AbsynTy.ty) AbsynTyFormatter.format_ty *)
  datatype ty = datatype AbsynTy.ty

  (*% @formatter(AbsynTy.kinded_tyvar) AbsynTyFormatter.format_kinded_tyvar *)
  datatype kinded_tyvar = datatype AbsynTy.kinded_tyvar

  (*%
   * @formatter(AbsynTy.kinded_tyvarseq)
   * AbsynTyFormatter.format_kinded_tyvarseq
   *)
  datatype kinded_tyvarseq = datatype AbsynTy.kinded_tyvarseq

  (*% @formatter(AbsynTy.ffi_ty) AbsynTyFormatter.format_ffi_ty *)
  datatype ffi_ty = datatype AbsynTy.ffi_ty

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   *)
  type op_vid =
      (*%
       * @format(op1 * vid * loc)
       * op1:iftrue()("op" +d,)
       * vid
       *)
      bool * vid * loc

  (*%
   * @formatter(RequirePath.path) RequirePath.format_path
   *)
  type require_path =
      (*%
       * @format(path * loc)
       * "\"" path "\""
       *)
      RequirePath.path * loc

  (*% *)
  type extern_name =
      (*%
       * @format(name * loc)
       * "\"" name "\""
       *)
      string * loc

  (*% *)
  type exist_quant =
      (*%
       * @format(tyvar tyvars * loc)
       * "{" !N0{ tyvars(tyvar)("," +1) } "}"
       *)
      kinded_tyvar list * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(N0ifsome) AbsynFormatterUtils.N0ifsome
   *)
  datatype pat =
      (*%
       * @format(loc) "_"
       *)
      PATWILD of loc
    | (*%
       * @format(const * loc) const
       *)
      PATCONST of constant * loc
    | (*%
       * @format(longvid)
       * longvid
       *)
      PATID of op_longvid
    | (*%
       * @format(row rows * flex * loc)
       * "{" !N0{ rows(row)("," +1) flex:iftrue()("," +1 "...",) } "}"
       *)
      PATRECORD of patrow list * bool * loc
    | (*%
       * @format(pat pats * loc)
       * "(" !N0{ pats(pat)("," +1) } ")"
       *)
      PATTUPLE of pat list * loc
    | (*%
       * @format(pat pats * loc)
       * "[" !N0{ pats(pat)("," +1) } "]"
       *)
      PATLIST of pat list * loc
    | (*%
       * @format(pat * loc)
       * "(" !N0{ pat } ")"
       *)
      PATPAREN of pat * loc
    | (*%
       * @format(pat pats * loc)
       * !N0{ pats(pat)(+1) }
       *)
      PATAPP of pat list * loc
    | (*%
       * @format(pat * ty * loc)
       * !N0{ pat +1 ":" +d ty }
       *)
      PATTYPED of pat * ty * loc
    | (*%
       * @format(vid * ty tyOpt * pat * loc)
       * !N0{
       *   tyOpt:N0ifsome()(
       *     vid
       *     tyOpt:ifsome()(+1 ":" +d tyOpt(ty),)
       *   )
       *   +1 "as" +d pat
       * }
       *)
      PATAS of op_vid * ty option * pat * loc

  and patrow =
      (*%
       * @format(lab * pat * loc)
       * !N0{ lab +1 "=" +d pat }
       *)
      PATROW of lab * pat * loc
    | (*%
       * @format(vid * ty tyOpt * pat patOpt * loc)
       * patOpt:N0ifsome()(
       *   tyOpt:N0ifsome()(
       *     vid
       *     tyOpt:ifsome()(+1 ":" +d tyOpt(ty),)
       *   )
       *   patOpt:ifsome()(+1 "as" +d patOpt(pat),)
       * )
       *)
      PATROWVAR of vid * ty option * pat option * loc

  (*%
   * @params(head)
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  datatype exbind =
      (*%
       * @format(vid * ty tyOpt * loc)
       * !N0{
       *   head
       *   vid
       *   tyOpt:ifsome()(+1 "of" +d tyOpt(ty),)
       * }
       *)
      EXBIND of op_vid * ty option * loc
    | (*%
       * @format(vid * longvid * loc)
       * !N0{
       *   head
       *   vid
       *   +1 "=" +d
       *   longvid
       *  }
       *)
      EXBINDREP of op_vid * op_longvid * loc

  (*%
   * @params(head)
   * @formatter(ifemptyseq) AbsynFormatterUtils.ifemptyseq
   *)
  type typbind =
      (*%
       * @format(tyvarseq * tycon * ty * loc)
       * !N0{
       *   !N0{
       *     head
       *     tyvarseq
       *     tyvarseq:ifemptyseq()(,+1)
       *     tycon
       *   }
       *   +d "=" +1
       *   ty
       * }
       *)
      tyvarseq * tycon * ty * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  type conbind =
      (*%
       * @format(vid * ty tyOpt * loc)
       * !N0{
       *   vid
       *   tyOpt:ifsome()(+d "of" +1 tyOpt(ty),)
       * }
       *)
      op_vid * ty option * loc

  (*%
   * @params(head)
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(ifemptyseq) AbsynFormatterUtils.ifemptyseq
   * @formatter(decs) AbsynFormatterUtils.decs
   *)
  type datbind =
      (*%
       * @format(tyvarseq * tycon * conbind conbinds * loc)
       * !N0{
       *   head
       *   tyvarseq
       *   tyvarseq:ifemptyseq()(,+d)
       *   tycon
       *   +d "="
       *   conbinds:ifcons()(2[+1],)
       *   conbinds(conbind)(+1 "|" +d)
       * }
       *)
      tyvarseq * tycon * conbind list * loc

  (*%
   * @formatter(AbsynSQL.top) AbsynSQLFormatter.format_top
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(ifemptyseq) AbsynFormatterUtils.ifemptyseq
   * @formatter(decs) AbsynFormatterUtils.decs
   * @formatter(decs2) AbsynFormatterUtils.decs2
   *)
  datatype exp =
      (*%
       * @format(const * loc) const
       *)
      EXPCONST of constant * loc
    | (*%
       * @format(longvid)
       * longvid
       *)
      EXPID of op_longvid
    | (*%
       * @format(row rows * loc)
       * "{" !N0{ rows(row)("," +1) } "}"
       *)
      EXPRECORD of exprow list * loc
    | (*%
       * @format(lab * loc)
       * "#" lab
       *)
      EXPSELECT of lab * loc
    | (*%
       * @format(exp exps * loc)
       * "(" !N0{ exps(exp)("," +1) } ")"
       *)
      EXPTUPLE of exp list * loc
    | (*%
       * @format(exp exps * loc)
       * "[" !N0{ exps(exp)("," +1) } "]"
       *)
      EXPLIST of exp list * loc
    | (*%
       * @format(exp exps * loc)
       * "(" !N0{ exps(exp)(";" +1) } ")"
       *)
      EXPSEQ of exp list * loc
    | (*%
       * @format(dec decs * exp exps * loc)
       * !N0{
       *   "let"
       *   decs:ifcons()(2[+1],)
       *   decs(dec)(2[+1])
       *   +1 "in"
       *   exps:ifcons()(2[+1],)
       *   exps(exp)(";" 2[+1])
       *   +1 "end"
       * }
       *)
      EXPLET of dec list * exp list * loc
    | (*%
       * @format(exp * loc)
       * "(" !N0{ exp } ")"
       *)
      EXPPAREN of exp * loc
    | (*%
       * @format(exp exps * loc)
       * !N0{ exps(exp)(2[+1]) }
       *)
      EXPAPP of exp list * loc
    | (*%
       * @format(exp * ty * loc)
       * !N0{ exp +1 ":" +d ty }
       *)
      EXPTYPED of exp * ty * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * !N0{ exp1 +1 "andalso" +d exp2 }
       *)
      EXPANDALSO of exp * exp * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * !N0{ exp1 +1 "orelse" +d exp2 }
       *)
      EXPORELSE of exp * exp * loc
    | (*%
       * @format(exp * mrule mrules * loc)
       * !N0{ exp +1 !N0{ "handle" 2[+1] mrules(mrule)(+1 "|" +d) } }
       *)
      EXPHANDLE of exp * mrule list * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "raise" 2[+1] exp }
       *)
      EXPRAISE of exp * loc
    | (*%
       * @format(exp1 * exp2 * exp3 * loc)
       * !N0{
       *   !N0{ "if" 2[+1] exp1 }
       *   +1
       *   !N0{ "then" 2[+1] exp2 }
       *   +1
       *   !N0{ "else" 2[+1] exp3 }
       * }
       *)
      EXPIF of exp * exp * exp * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * !N0{ "while" +d exp1 +1 "do" +d exp2 }
       *)
      EXPWHILE of exp * exp * loc
    | (*%
       * @format(exp * mrule mrules * loc)
       * !N0{ !N0{ "case" 2[+1] exp +1 "of" } 2[+1] mrules(mrule)(+1 "|" +d) }
       *)
      EXPCASE of exp * mrule list * loc
    | (*%
       * @format(mrule mrules * loc)
       * !N0{ "f" !N0{ "n" +d mrules(mrule)(+1 "|" +d) } }
       *)
      EXPFN of mrule list * loc
    | (*%
       * @format(ty * loc)
       * "_sizeof(" !N0{ ty } ")"
       *)
      EXPSIZEOF of ty * loc
    | (*%
       * @format(exp * row rows * loc)
       * !N0{ exp +1 "#" +d "{" !N0{ rows(row)("," +1) } "}" }
       *)
      EXPRECORD_UPDATE of exp * exprow list * loc
    | (*%
       * @format(exp * row rows * loc)
       * !N0{ exp +1 "#" +d "(" !N0{ rows(row)("," +1) } ")" }
       *)
      EXPTUPLE_UPDATE of exp * exp list * loc
    | (*%
       * @format(name * ty * loc)
       * !N0{ "_import" +d name +1 ":" +d ty }
       *)
      EXPIMPORT_NAME of extern_name * ffi_ty * loc
    | (*%
       * @format(exp * ty * loc)
       * !N0{ exp +1 ":" +d "_import" +d ty }
       *)
      EXPIMPORT_EXP of exp * ffi_ty * loc
    | (*%
       * @format(sqlexp)
       * sqlexp
       *)
      EXPSQL of sqlexp
    | (*%
       * @format(vid * exp1 * exp2 * pat * exp3 * exp4 * loc)
       * !N0{
       *   "_foreach" vid
       *   +1 "in" +d exp1
       *   +1 "where" +d exp2
       *   +1 "with" +d pat
       *   +1 "do" +d exp3
       *   +1 "while" +d exp4
       *   +1 "end"
       * }
       *)
      EXPFOREACH_DATA of vid * exp * exp * pat * exp * exp * loc
    | (*%
       * @format(vid * exp1 * pat * exp2 * exp3 * loc)
       * !N0{
       *   "_foreach" vid
       *   +1 "in" +d exp1
       *   +1 "with" +d pat
       *   +1 "do" +d exp2
       *   +1 "while" +d exp3
       *   +1 "end"
       * }
       *)
      EXPFOREACH_ARRAY of vid * exp * pat * exp * exp * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * "_join(" !N0{ exp1 "," +1 exp2 } ")"
       *)
      EXPJOIN of exp * exp * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * "_extend(" !N0{ exp1 "," +1 exp2 } ")"
       *)
      EXPEXTEND of exp * exp * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * "_update(" !N0{ exp1 "," +1 exp2 } ")"
       *)
      EXPUPDATE1 of exp * exp * loc
    | (*%
       * @format(exp1 * exp2 * loc)
       * !N0{ exp1 +1 "#" +d "{" !N0{ exp2 } "}" }
       *)
      EXPUPDATE2 of exp * exp * loc
    | (*%
       * @format(exp * ty * loc)
       * !N0{ "_dynamic" +d exp +1 "as" +d ty }
       *)
      EXPDYNAMIC_AS of exp * ty * loc
    | (*%
       * @format(exp * ty * loc)
       * !N0{ "_dynamic" +d exp +1 "of" +d ty }
       *)
      EXPDYNAMIC_OF of exp * ty * loc
    | (*%
       * @format(exp * ty * loc)
       * !N0{ "_dynamicview" +d exp +1 "of" +d ty }
       *)
      EXPDYNAMICVIEW of exp * ty * loc
    | (*%
       * @format(ty * loc)
       * !N0{ "_dynamicnull" +d "as" +d ty }
       *)
      EXPDYNAMICNULL of ty * loc
    | (*%
       * @format(ty * loc)
       * !N0{ "_dynamictop" +d "as" +d ty }
       *)
      EXPDYNAMICTOP of ty * loc
    | (*%
       * @format(exp * mrule mrules * loc)
       * !N0{
       *   !N0{ "_dynamiccase" 2[+1] exp +1 "of" }
       *   2[+1]
       *   mrules(mrule)(+1 "|" +d)
       * }
       *)
      EXPDYNAMICCASE of exp * dynamic_mrule list * loc
    | (*%
       * @format(ty * loc)
       * "_reifyTy(" 2[1] !N0{ ty } 1 ")"
       *)
      EXPREIFYTY of ty * loc

  and (*% @params(head) *) valbind =
      (*%
       * @format(pat * exp * loc)
       * !N0{ head pat +d "=" +1 exp }
       *)
      VALBIND of pat * exp * loc
    | (*%
       * @format(valbind valbinds * loc)
       * valbinds:decs(valbind)(head "rec" +d, +1 "and" +d,)
       *)
      VALREC of valbind list * loc

  and dec =
      (*%
       * @format(tyvarseq * valbind valbinds * loc)
       * !N0{
       *   "val" +d
       *   valbinds:decs(valbind)(
       *     tyvarseq
       *     tyvarseq:ifemptyseq()(,+d),
       *     +1 "and" +d,
       *   )
       * }
       *)
      DECVAL of kinded_tyvarseq * valbind list * loc
    | (*%
       * @format(tyvarseq * fvalbind fvalbinds * loc)
       * !N0{
       *   "fu"
       *   fvalbinds:decs2(fvalbind)(
       *     "n" +d,
       *     tyvarseq
       *     tyvarseq:ifemptyseq()(,+1),
       *     +1 "an",
       *     "d" +d,
       *   )
       * }
       *)
      DECFUN of kinded_tyvarseq * fvalbind list * loc
    | (*%
       * @format(typbind typbinds * loc)
       * !N0{ "ty" typbinds:decs(typbind)("pe" +d, +1 "an", "d" +d) }
       *)
      DECTYPE of typbind list * loc
    | (*%
       * @format(datbind datbinds * typbind typbinds * loc)
       * !N0{
       *   datbinds:decs(datbind)("datatype" +d, +1, "and" +d)
       *   typbinds:ifcons()(+1,)
       *   typbinds:decs(typbind)("withtype" +d, +1, "and" +d)
       * }
       *)
      DECDATATYPE of datbind list * typbind list * loc
    | (*%
       * @format(tycon * longtycon * loc)
       * !N0{ "datatype" +d tycon +d "=" +1 "datatype" +d longtycon }
       *)
      DECDATATYPEREP of tycon * longtycon * loc
    | (*%
       * @format(datbind datbinds * typbind typbinds * dec decs * loc)
       * !N0{
       *   datbinds:decs(datbind)("abstype" +d, +1, "and" +d)
       *   typbinds:decs(typbind)(+1 "withtype" +d, +1, "and" +d)
       *   +1 "with"
       *   decs:ifcons()(2[+1],)
       *   decs(dec)(2[+1])
       *   +1 "end"
       * }
       *)
      DECABSTYPE of datbind list * typbind list * dec list * loc
    | (*%
       * @format(exbind exbinds * loc)
       * !N0{ "ex" exbinds:decs(exbind)("ception" +d, +1 "an", "d" +d) }
       *)
      DECEXCEPTION of exbind list * loc
    | (*%
       * @format(dec1 decs1 * dec2 decs2 * loc)
       * !N0{
       *   "local"
       *   decs1:ifcons()(2[+1],)
       *   decs1(dec1)(2[+1])
       *   +1 "in"
       *   decs2:ifcons()(2[+1],)
       *   decs2(dec2)(2[+1])
       *   +1 "end"
       * }
       *)
      DECLOCAL of dec list * dec list * loc
    | (*%
       * @format(longstrid longstrids * loc)
       * !N0{
       *   "open"
       *   longstrids:ifcons()(2[+1],)
       *   !N0{ longstrids(longstrid)(+1) }
       * }
       *)
      DECOPEN of longstrid list * loc
    | (*%
       * @format
       * ";"
       *)
      DECSEMICOLON of loc
    | (*%
       * @format(prec precOpt * vid vids * loc)
       * !N0{
       *   "infix"
       *   precOpt:ifsome()(+d precOpt(prec),)
       *   vids:ifcons()(2[+1],)
       *   !N0{ vids(vid)(+1) }
       * }
       *)
      DECINFIX of string option * vid list * loc
    | (*%
       * @format(prec precOpt * vid vids * loc)
       * !N0{
       *   "infixr"
       *   precOpt:ifsome()(+d precOpt(prec),)
       *   vids:ifcons()(2[+1],)
       *   !N0{ vids(vid)(+1) }
       * }
       *)
      DECINFIXR of string option * vid list * loc
    | (*%
       * @format(vid vids * loc)
       * !N0{
       *   "nonfix"
       *   vids:ifcons()(2[+1],)
       *   !N0{ vids(vid)(+1) }
       * }
       *)
      DECNONFIX of vid list * loc
    | (*%
       * @format(pvalbind pvalbinds * loc)
       * !N0{
       *   "val" +d
       *   pvalbinds:decs(pvalbind)(
       *     "_polyrec" +d,
       *     +1,
       *     "and" +d
       *   )
       * }
       *)
      DECPOLYREC of pvalbind list * loc

  withtype sqlexp =
      (*%
       * @format((exp, pat, ty) sqltop)
       * sqltop(exp, pat, ty)
       *)
      (exp, pat, ty) AbsynSQL.top

  and exprow =
      (*%
       * @format(lab * exp * loc)
       * !N0{ lab +d "=" 2[+1] exp }
       *)
      lab * exp * loc

  and mrule =
      (*%
       * @format(pat * exp * loc)
       * !N0{ pat +d "=>" +1 exp }
       *)
      pat * exp * loc

  and dynamic_mrule =
      (*%
       * @format(exists * pat * exp * loc)
       * !N0{ exists exists:ifemptyseq()(,+1) pat +d "=>" +1 exp }
       *)
      exist_quant * pat * exp * loc

  and (*% @params(head) *) frule =
      (*%
       * @format(pat pats * ty tyOpt * exp * loc)
       * !N0{
       *   !N0{
       *     head
       *     pats(pat)(+1)
       *     tyOpt:ifsome()(+1 ":" +d tyOpt(ty),)
       *     +1
       *   }
       *   "=" +1
       *   exp
       * }
       *)
      pat list * ty option * exp * loc

  and (*% @params(head1, head2) *) fvalbind =
      (*%
       * @format(frule frules * loc)
       * !N0{ head1 frules:decs(frule:frule)(head2, +1 "|" +d,) }
       *)
      (pat list * ty option * exp * loc) list * loc

  and (*% @params(head) *) pvalbind =
      (*%
       * @format(vid * ty * exp * loc)
       * !N0{ !N0{ head vid +1 ":" +d ty } +d "=" +1 exp }
       *)
      vid * ty * exp * loc

  (*% @params(head) *)
  type valdesc =
      (*%
       * @format(vid * ty * loc)
       * !N0{ head vid +1 ":" +d ty }
       *)
      vid * ty * loc

  (*%
   * @params(head)
   * @formatter(ifemptyseq) AbsynFormatterUtils.ifemptyseq
   *)
  type typdesc =
      (*%
       * @format(tyvarseq * tycon * loc)
       * !N0{ head tyvarseq tyvarseq:ifemptyseq()(,+1) tycon }
       *)
      tyvarseq * tycon * loc

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
  *)
  type condesc =
      (*%
       * @format(vid * ty tyOpt * loc)
       * !N0{ vid tyOpt:ifsome()(+d "of" +1 tyOpt(ty),) }
       *)
      vid * ty option * loc

  (*%
   * @params(head)
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(ifemptyseq) AbsynFormatterUtils.ifemptyseq
   *)
  type datdesc =
      (*%
       * @format(tyvarseq * tycon * condesc condescs * loc)
       * !N0{
       *   head
       *   tyvarseq
       *   tyvarseq:ifemptyseq()(,+1)
       *   tycon
       *   +d "="
       *   condescs:ifcons()(2[+1],)
       *   condescs(condesc)(+1 "|" +d)
       * }
       *)
      tyvarseq * tycon * condesc list * loc

  (*%
   * @params(head)
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  type exdesc =
      (*%
       * @format(vid * ty tyOpt * loc)
       * !N0{ head vid tyOpt:ifsome()(+d "of" +1 tyOpt(ty),) }
       *)
      vid * ty option * loc

  (*%
   * @params(head)
   * @formatter(ifemptyseq) AbsynFormatterUtils.ifemptyseq
   *)
  type wheretype =
      (*%
       * @format(tyvarseq * longtycon * ty * loc)
       * !N0{
       *   head
       *   tyvarseq
       *   tyvarseq:ifemptyseq()(,+1)
       *   longtycon
       *   +d "=" +1
       *   ty
       * }
       *)
      tyvarseq * longtycon * ty * loc

  (*%
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(decs) AbsynFormatterUtils.decs
   *)
  datatype spec =
      (*%
       * @format(valdesc valdescs * loc)
       * !N0{ valdescs:decs(valdesc)("val" +d, +1, "and" +d) }
       *)
      SPECVAL of valdesc list * loc
    | (*%
       * @format(typdesc typdescs * loc)
       * !N0{ "ty" typdescs:decs(typdesc)("pe" +d, +1 "an", "d" +d) }
       *)
      SPECTYPE of typdesc list * loc
    | (*%
       * @format(typbind typbinds * loc)
       * !N0{ "ty" typbinds:decs(typbind)("pe" +d, +1 "an", "d" +d) }
       *)
      SPECTYPEINC of typbind list * loc
    | (*%
       * @format(typdesc typdescs * loc)
       * !N0{ "eq" typdescs:decs(typdesc)("type" +d, +1 "an", "d" +d) }
       *)
      SPECEQTYPE of typdesc list * loc
    | (*%
       * @format(datdesc datdescs * loc)
       * !N0{ datdescs:decs(datdesc)("datatype" +d, +1, "and" +d) }
       *)
      SPECDATATYPE of datdesc list * loc
    | (*%
       * @format(tycon * longtycon * loc)
       * !N0{ "datatype" +d tycon +d "=" +1 "datatype" +d longtycon }
       *)
      SPECDATATYPEREP of tycon * longtycon * loc
    | (*%
       * @format(exdesc exdescs * loc)
       * !N0{ "ex" exdescs:decs(exdesc)("ception" +d, +1 "an", "d" +d) }
       *)
      SPECEXCEPTION of exdesc list * loc
    | (*%
       * @format(strdesc strdescs * loc)
       * !N0{ strdescs:decs(strdesc)("structure" +d, +1, "and" +d) }
       *)
      SPECSTRUCTURE of strdesc list * loc
    | (*%
       * @format(sigexp * loc)
       * !N0{ "include" 2[+1] sigexp }
       *)
      SPECINCLUDE of sigexp * loc
    | (*%
       * @format(sigid sigids * loc)
       * !N0{ "include" 2[+1] !N0{ sigids(sigid)(+1) } }
       *)
      SPECINCLUDE_ID of sigid list * loc
    | (*%
       * @format(spec specs * longtycon longtycons * loc)
       * !N0{
       *   specs(spec)(+1)
       *   specs:ifcons()(+1,)
       *   !N0{
       *     "sharing" +d "type" 2[+1]
       *     !N0{ longtycons(longtycon)(+1 "=" +d) }
       *   }
       * }
       *)
      SPECSHARINGTYPE of spec list * longtycon list * loc
    | (*%
       * @format(spec specs * longstrid longstrids * loc)
       * !N0{
       *   specs(spec)(+1)
       *   specs:ifcons()(+1,)
       *   !N0{
       *     "sharing" 2[+1]
       *     !N0{ longstrids(longstrid)(+1 "=" +d) }
       *   }
       * }
       *)
      SPECSHARING of spec list * longstrid list * loc
    | (*%
       * @format(loc)
       * ";"
       *)
      SPECSEMICOLON of loc

  and sigexp =
      (*%
       * @format(spec specs * loc)
       * !N0{
       *    "sig"
       *    specs:ifcons()(2[+1],)
       *    specs(spec)(2[+1])
       *    +1 "end"
       * }
       *)
      SIGBASIC of spec list * loc
    | (*%
       * @format(sigid)
       * sigid
       *)
      SIGID of sigid
    | (*%
       * @format(sigexp * typbind typbinds * loc)
       * !N0{
       *   sigexp
       *   +1
       *   "wh"
       *   typbinds:decs(typbind)(
       *     "ere" +d "type" +d,
       *     +1 "an",
       *     "d" +d "type" +d
       *   )
       * }
       *)
      SIGWHERE of sigexp * wheretype list * loc

  withtype (*% @params(head) *) strdesc =
      (*%
       * @format(strid * sigexp * loc)
       * !N0{ head strid +1 ":" +d sigexp }
       *)
      strid * sigexp * loc

  (*% *)
  type (*% @params(head) *) sigbind =
      (*%
       * @format(sigid * sigexp * loc)
       * !N0{ head sigid +d "=" +1 sigexp }
       *)
      strid * sigexp * loc

  (*% *)
  datatype sigop =
      (*% @format ":" *)
      TRANSPARENT
    | (*% @format ":>" *)
      OPAQUE

  (*% @params(head) *)
  type sigconstraint =
      (*%
       * @format(sigop * sigexp * loc)
       * !N0{ head sigop +d sigexp }
       *)
      sigop * sigexp * loc

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(decs) AbsynFormatterUtils.decs
   *)
  datatype strexp =
      (*%
       * @format(strdec strdecs * loc)
       * !N0{
       *   "struct"
       *   strdecs:ifcons()(2[+1],)
       *   strdecs(strdec)(2[+1])
       *   +1 "end"
       * }
       *)
      STRBASIC of strdec list * loc
    | (*%
       * @format(longstrid)
       * longstrid
       *)
      STRID of longstrid
    | (*%
       * @format(strexp * sigop * sigexp * loc)
       * !N0{ strexp +1 sigop +d sigexp }
       *)
      STRCONSTRAINT of strexp * sigop * sigexp * loc
    | (*%
       * @format(funid * arg * loc)
       * !N0{ funid "(" 2[1] !N0{ arg } 1 ")" }
       *)
      STRAPP of funid * fun_arg * loc
    | (*%
       * @format(strdec strdecs * strexp * loc)
       * !N0{
       *   "let"
       *   strdecs:ifcons()(2[+1],)
       *   strdecs(strdec)(2[+1])
       *   +1 "in"
       *   2[+1] strexp
       *   +1 "end"
       * }
       *)
      STRLET of strdec list * strexp * loc

  and strdec =
      (*%
       * @format(dec)
       * dec
       *)
      STRDEC of dec
    | (*%
       * @format(strbind strbinds * loc)
       * !N0{ strbinds:decs(strbind)("structure" +d, +1, "and" +d) }
       *)
      STRUCTURE of strbind list * loc
    | (*%
       * @format(strdec1 strdecs1 * strdec2 strdecs2 * loc)
       * !N0{
       *   "local"
       *   strdecs1:ifcons()(2[+1],)
       *   strdecs1(strdec1)(2[+1])
       *   +1 "in"
       *   strdecs2:ifcons()(2[+1],)
       *   strdecs2(strdec2)(2[+1])
       *   +1 "end"
       * }
       *)
      STRLOCAL of strdec list * strdec list * loc
    | (*%
       * @format(loc)
       * ";"
       *)
      STRSEMICOLON of loc

  and fun_arg =
      (*%
       * @format(strexp)
       * strexp
       *)
      FUNARG of strexp
    | (*%
       * @format(strdec strdecs)
       * !N0{ strdecs(strdec)(+1) }
       *)
      FUNARG_DEC of strdec list

  withtype (*% @params(head) *) strbind =
      (*%
       * @format(strid * sigcon sigconOpt * strexp * loc)
       * !N0{
       *   !N0{
       *     sigconOpt:ifsome()(
       *       sigconOpt(sigcon()(head strid +1)),
       *       head strid
       *     )
       *     +1
       *   }
       *   "=" +1
       *   strexp
       * }
       *)
      strid * sigconstraint option * strexp * loc

  (*% *)
  datatype fun_param =
      (*%
       * @format(strid * sigexp)
       * !N0{ strid +1 ":" +d sigexp }
       *)
      FUNPARAM of strid * sigexp
    | (*%
       * @format(spec specs)
       * !N0{ specs(spec)(+1) }
       *)
      FUNPARAM_SPEC of spec list

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  type (*% @params(head) *) funbind =
      (*%
       * @format(funid * param * sigcon sigconOpt * strexp * loc)
       * !N0{
       *   sigconOpt:ifsome()(
       *     sigconOpt(sigcon()(head funid "(" 2[1] !N0{ param } 1 ")" +1)),
       *     head funid "(" 2[1] !N0{ param } 1 ")"
       *   )
       *   +d "=" +1
       *   strexp
       * }
       *)
      funid * fun_param * sigconstraint option * strexp * loc

  (*%
   * @formatter(decs) AbsynFormatterUtils.decs
   *)
  datatype topdec =
      (*%
       * @format(strdec)
       * strdec
       *)
      TOPSTRDEC of strdec
    | (*%
       * @format(sigbind sigbinds * loc)
       * !N0{ sigbinds:decs(sigbind)("signature" +d, +1, "and" +d) }
       *)
      TOPSIGNATURE of sigbind list * loc
    | (*%
       * @format(funbind funbinds * loc)
       * !N0{ funbinds:decs(funbind)("functor" +d, +1, "and" +d) }
       *)
      TOPFUNCTOR of funbind list * loc
    | (*%
       * @format(exp * loc)
       * exp
       *)
      TOPEXP of exp * loc

  (*% *)
  datatype top =
      (*%
       * @format(topdec topdecs * loc)
       * topdecs(topdec)(+1)
       *)
      TOPDEC of topdec list * loc
    | (*%
       * @format(path * loc)
       * "use" +d path
       *)
      USE of require_path * loc
    | (*%
       * @format(path * loc)
       * "_use" +d path
       *)
      USE' of require_path * loc
    | (*%
       * @format
       * ";"
       *)
      TOPSEMICOLON of loc

  (*%
   * @formatter(RequirePath.path) RequirePath.format_path
   *)
  type interface =
      (*%
       * @format(path * loc)
       * "_interface" +d path
       *)
      require_path * loc

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   *)
  type compile_unit =
      (*%
       * @format(interface interfaceOpt * top tops * loc)
       * interfaceOpt(interface)
       * interfaceOpt:ifsome()(tops:ifcons()(\n,),)
       * tops(top)(\n)
       *)
      interface option * top list * loc

  (*% *)
  datatype absyn =
      (*%
       * @format(unit)
       * unit
       *)
      UNIT of compile_unit
    | (*%
       *)
      EOF

end
