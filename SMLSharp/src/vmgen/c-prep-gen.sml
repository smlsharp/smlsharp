structure CPreprocessGen : sig

  val generate : InsnDef.def_impl list ->
                 {prep32_c: string, prep64_c: string}

end =
struct

  structure I = InsnDef
  structure IMap = Utils.IMap

  (*
   * FIXME: Potentially, instruction matching should be performed by DFA,
   *        not decision tree, but current implementation generates
   *        only tree-formed patterns.
   *)
  type input =
      {size: word, ty: I.ty, value: int}
  datatype patnode =
      NODE of {offset: word,
               edges: (input * patnode) list,
               any: (word * patnode) option,        (* size * next *)
               accept: (word * I.def_impl) option}  (* required rest * impl *)

  fun fmtWordInt x =
      Word.fmt StringCvt.DEC x

  fun fmtInt x =
      String.translate (fn #"~" => "-" | x => str x)
                       (Int.fmt StringCvt.DEC x)

(*
  (* for debug *)
  fun printNode t =
      let
        fun s x = String.implode (List.tabulate (size x, fn _ => #" "))
        fun p prefix (NODE {offset,edges,accept,any}) =
            (print (prefix^
                    "NODE: off="^fmtWordInt offset^
                    ", acc="^(case accept of
                                SOME (r,x) => "("^fmtWordInt r^", "^
                                              #internalName x^")"
                              | NONE => "_")
                    ^"\n");
             app (fn ({size,ty,value},t) =>
                     p (s prefix^"-"^fmtInt value^":"^
                        I.formatTy ty^":"^fmtWordInt size^"-> ") t)
                 edges;
             Option.app
               (fn (size,t) => p (s prefix^"-ANY:"^fmtWordInt size^"-> ") t)
               any)
      in
        p "" t
      end
*)

  fun isCIntTy ty =
      case ty of
        I.W => true
      | I.L => true
      | I.N => true
      | I.NL => true
      | I.F => false
      | I.FS => false
      | I.FL => false
      | I.P => false
      | I.B => true
      | I.H => true
      | I.OA => false
      | I.SC => true
      | I.SZ => true
      | I.LSZ => true
      | I.SSZ => true
      | I.SH => true
      | I.VI => false
      | I.RI => true
      | I.LI => true
      | I.TY => false
      | I.UN _ => false

  fun compareTy (ty1, ty2) =
      let
        (* conscious only byte code format types. *)
        fun f I.W = 1
          | f I.L = 2
          | f I.N = 3
          | f I.NL = 4
          | f I.F = 5
          | f I.FS = 6
          | f I.SC = 7
          | f I.SH = 8
          | f I.SZ = 9
          | f I.LSZ = 10
          | f I.SSZ = 11
          | f I.P = 12
          | f ty = raise Control.Bug ("compareTy "^I.formatTy ty)
      in
        Int.compare (f ty1, f ty2)
      end

  fun compareInput ({size=s1, ty=t1, value=n1}:input,
                    {size=s2, ty=t2, value=n2}:input) =
      case Word.compare (s1, s2) of
        EQUAL => (case compareTy (t1, t2) of
                    EQUAL => Int.compare (n1, n2)
                  | x => x)
      | x => x

  fun unify (node1 as NODE n1, node2 as NODE n2) =
      if #offset n1 = #offset n2
      then NODE {offset = #offset n1,
                 edges = unifyEdges (#edges n1, #edges n2),
                 accept = unifyAccept (#accept n1, #accept n2),
                 any = unifyAny (#any n1, #any n2)}
      else if #offset n1 < #offset n2
      then addAny (node1, #offset n2 - #offset n1, node2)
      else addAny (node2, #offset n1 - #offset n2, node1)

  and addAny (NODE {offset, edges, accept, any}, size, node2) =
      NODE {offset = offset,
            edges = edges,
            accept = accept,
            any = unifyAny (any, SOME (size, node2))}

  and unifyAny (node1, NONE) = node1
    | unifyAny (NONE, node2) = node2
    | unifyAny (SOME (s1, node1), SOME (s2, node2)) =
      if s1 = s2
      then SOME (s1, unify (node1, node2))
      else if s1 < s2
      then SOME (s1, addAny (node1, s2 - s1, node2))
      else SOME (s2, addAny (node2, s1 - s2, node1))

  and unifyEdges (l1, nil) = l1
    | unifyEdges (nil, l2) = l2
    | unifyEdges (l1 as (i1, n1)::t1, l2 as (i2, n2)::t2) =
      case compareInput (i1, i2) of
        EQUAL   => (i1, unify (n1, n2)) :: unifyEdges (t1, t2)
      | LESS    => (i1, n1) :: unifyEdges (t1, l2)
      | GREATER => (i2, n2) :: unifyEdges (l1, t2)

  and unifyAccept (SOME def1, SOME def2) = raise Control.Bug "unifyAccept"
    | unifyAccept (def1, NONE) = def1
    | unifyAccept (NONE, def2) = def2

  val initNode =
      NODE {offset = 0w0, edges = nil, accept = NONE, any = NONE}

  fun makeMatch getPat (def:I.def_impl) =
      let
        fun next pos pats =
            let
              val node as NODE {offset, ...} = make pos pats
            in
              if pos = offset
              then node
              else NODE {offset = pos,
                         edges = nil,
                         accept = NONE,
                         any = SOME (offset - pos, node)}
            end

        and make pos nil =
            NODE {offset = pos, edges = nil,
                  accept = SOME (0w0, def), any = NONE}
          | make pos [I.PATANY {size}] =
            NODE {offset = pos, edges = nil,
                  accept = SOME (size, def), any = NONE}
          | make pos (I.PATANY {size=n1} :: I.PATANY {size=n2} :: t) =
            make pos (I.PATANY {size = n1 + n2} :: t)
          | make pos (I.PATANY {size} :: t) = make (pos+size) t
          | make pos (I.PATINT v :: t) =
            NODE {offset = pos,
                  edges = [(v, next (pos + #size v) t)],
                  accept = NONE,
                  any = NONE}
      in
        make 0w0 (getPat def)
      end

  fun preprocessFun bits prepId =
      "prep"^fmtWordInt bits^"_"^fmtInt prepId

  fun genMatch bits prepMap ind (NODE {offset, edges, any, accept}) =
      let
        val fmtCTy = I.formatCPatTy bits

        val matches =
            Utils.cluster
              (fn (({size=s1,ty=t1,...},_),({size=s2,ty=t2,...},_)) =>
                  s1 = s2 andalso t1 = t2)
              edges

        fun gen ind (nil::t) = raise Control.Bug "genMatch"
          | gen ind ((l as ({size,ty,...},_)::_)::t) =
            ind^"if (rest >= "^fmtWordInt (offset + size)^") {\n"^
            (let
               val ind = ind^" "
               val fetch = "*("^fmtCTy ty^"*)(&p["^fmtWordInt offset^"])"
             in
               (if isCIntTy ty
                then
                  ind^"switch ("^fetch^") {\n"^
                  String.concat
                    (map (fn ({value,...}:input, next) =>
                             ind^"case "^fmtInt value^":\n"^
                             genMatch bits prepMap (ind^" ") next^
                             ind^" break;\n") l) ^
                  ind^"default:\n"^
                  gen (ind^" ") t^
                  ind^" break;\n"^
                  ind^"}\n"
                else
                  Utils.join (ind^"else ")
                    (map (fn ({value,...}:input, next) =>
                             ind^"if ("^fetch^" == "^fmtInt value^") {\n"^
                             genMatch bits prepMap (ind^" ") next^
                             ind^"}\n") l) ^
                  ind^"else {\n"^
                  gen (ind^" ") t^
                  ind^"}\n")
             end) ^
            ind^"}\n"
          | gen ind nil =
            case any of
              NONE => ind^"/* no any */\n"
            | SOME (size, next) =>
              ind^"/* ANY:"^fmtWordInt size^" */\n"^
              genMatch bits prepMap ind next
      in
        (case accept of
           NONE => ""
         | SOME (reqRest, {implId, internalName, pos, alternateId, ...}) =>
           case IMap.find (prepMap, implId) of
             NONE => raise Control.Bug "genMatch"
           | SOME prepId =>
             ind^"/* "^internalName^" : "^Control.loc pos^" */\n"^
             ind^"if (rest >= "^fmtWordInt offset^" + "^fmtWordInt reqRest^")\
                 \ {\n"^
             ind^" PREP_ACCEPT(rt, p, "^internalName^", "^fmtInt implId^");\n"^
             ind^" accept = "^preprocessFun bits prepId^",\
             \ implid = "^fmtInt implId^",\
             \ altid = "^
             (case alternateId of NONE => "-1" | SOME x => fmtInt x)^";\n"^
             ind^"}\n") ^
        gen ind matches
      end

  (* see also genEvalCase of c-eval-gen.sml. *)
  fun genPreprocess bits getFormat
                    (def as {preprocess, argTys, ...}:I.def_impl) =
      let
        val fmtCTy = I.formatCPatTy bits
        val {fields, totalSize, ...}:I.codeFormat = getFormat def
      in
        String.concat
          (map
             (fn {arg, offset, size, ty=patTy} =>
                 let
                   val {semTy, prepTy, ...} =
                       case List.find (fn {arg=x,...} => x = arg) argTys of
                         SOME x => x
                       | NONE => raise Control.Bug "genPreprocess"

                   fun acc ty =
                       "*("^ty^"*)(&p["^fmtWordInt offset^"])"
                 in
                   (* pre-calculating effective addresses.
                    * see also expandVAR in mother.sml. *)
                   case (semTy, prepTy) of
                     (I.RI, SOME I.P) =>
                     acc (I.formatCSemTy I.P)^" = ("^I.formatCSemTy I.P^")\
                     \REGADDR(rt, "^acc (fmtCTy patTy)^");\n"
                   | (I.OA, SOME I.P) =>
                     "if (!CHECK_OFFSET("^acc (fmtCTy patTy)^",\
                     \ ("^fmtCTy patTy^")size,\
                     \ ("^fmtCTy patTy^")rest)) return 0;\n\
                     \"^acc (I.formatCSemTy I.P)^" = ("^I.formatCSemTy I.P^")\
                     \(p + "^fmtWordInt totalSize^"\
                     \ + "^acc (fmtCTy patTy)^");\n"
                   | (_, SOME prepTy) =>
                     raise Control.Bug
                             ("genPreprocess: "^I.formatTy semTy^", "^
                              I.formatTy prepTy)
                   | (_, NONE) => ""
                   end)
               fields) ^
        (case preprocess of
           NONE => ""
         | SOME {name, args, pos} =>
           name^"(rt, p, size, rest, altid"^
           String.concat
             (map
                (fn x =>
                    case List.find (fn {arg,...} => x = arg) fields of
                      SOME {arg, ty, size, offset} =>
                      ", ("^fmtCTy ty^"*"^")(&p["^fmtWordInt offset^"])\
                      \, "^fmtCTy ty^"\
                      \, "^fmtWordInt size
                      | NONE => raise Control.Bug "genPreprocess")
                  args) ^
           ");\n") ^
        "return "^fmtWordInt totalSize^";\n"
      end

  fun genPreprocessFuns bits getFormat defs =
      let
        val preps =
            map (fn def => (def, genPreprocess bits getFormat def)) defs
        val preps =
            Utils.cluster (fn ((_,x),(_,y)) => x = y) preps

        val (_, prepMap) =
            foldl (fn (l as (_, x)::_, (i, prepMap)) =>
                      (i + 1,
                       foldl (fn (({implId, ...}, _), prepMap) =>
                                 IMap.insert (prepMap, implId, i))
                             prepMap l)
                    | (nil, z) => raise Control.Bug "genPreprocessFuns")
                  (0, IMap.empty)
                  preps

        val prepFuns =
            Utils.mapi
              (fn (i, (_, x)::_) =>
                  "static size_t\n\
                  \"^preprocessFun bits i^"(\
                  \runtime_t *rt ATTR_UNUSED, char *p ATTR_UNUSED, \
                  \size_t size ATTR_UNUSED, size_t rest ATTR_UNUSED, \
                  \int altid ATTR_UNUSED)\n\
                  \{\n"^x^"}\n"
                | (i, nil) => raise Control.Bug "genPreprocessFuns")
              preps
      in
        (prepMap, prepFuns)
      end

  fun genProgram bits getPat getFormat defs =
      let
        (* get rid of alternative implementations *)
        val defs = List.filter (fn x => not (null (getPat x))) defs

        val nodes = foldl unify initNode (map (makeMatch getPat) defs)
        val (prepMap, prepFuns) = genPreprocessFuns bits getFormat defs
        val match = genMatch bits prepMap " " nodes
      in
        "#define CHECK_OFFSET(off, size, rest) \\\n\
        \\t(-((size) - (rest)) <= (off) && (off) < (rest))\n\
        \\n\
        \"^String.concat prepFuns^"\
        \\n\
        \static size_t\n\
        \prep"^fmtWordInt bits^"(runtime_t *rt, void *code, size_t size,\
        \ size_t rest)\n\
        \{\n\
        \ char *p = code;\n\
        \ size_t (*accept)(runtime_t *, char *, size_t, size_t, int) = NULL;\n\
        \ int implid = 0, altid = 0;\n\
        \"^match^"\
        \ if (!accept) return 0;  /* error */\n\
        \ *(const void**)p = eval"^fmtWordInt bits^"_optable->entry[implid];\n\
        \ return accept(rt, p, size, rest, altid);\n\
        \}\n"
      end

  fun generate defs =
      {
        prep32_c = genProgram 0w32 #pat32 #format32 defs,
        prep64_c = genProgram 0w64 #pat64 #format64 defs
      }

end
