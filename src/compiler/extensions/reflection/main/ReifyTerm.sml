(**
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 *)

structure ReifyTerm =
struct
  local
    structure D = SMLSharp_Builtin.Dynamic
    structure BP = SMLSharp_Builtin.Pointer
    structure P = Pointer
    structure R = ReifiedTerm
    structure RTy = ReifiedTy 
    structure U = UserLevelPrimitive
  in
    fun bug s = raise Bug.Bug ("ReifyTerm: " ^ s)
    val ptrSize = RTy.ptrSize
    val tagSize = 0w4

    datatype reifiedTerm = datatype R.reifiedTerm
    datatype reifiedTy = datatype RTy.reifiedTy
    type tyRep = ReifiedTy.tyRep
    type object = boxed * word
    type dynamic = {tyRep : tyRep, obj : object}

    fun offset ((boxed, word) : object, offset) = (boxed, word + offset)
    fun size ((boxed, offset): object) = D.objectSize boxed

    fun alignOf reifiedTy = RTy.sizeOf reifiedTy

    fun typeOf (dyn : dynamic) = #tyRep dyn
    fun objOf (dyn : dynamic) = #obj dyn
    fun objOffset ((boxed, offset):object) = offset
    fun setOffset ((boxed, _):object, offset) = (boxed, offset) : object

    fun boolRep 0 = false 
      | boolRep 1 = true 
      | boolRep _ = raise bug "illeagal boolean representation"
    fun align (obj, ty) = 
        let
          val align = alignOf ty
          val delta = objOffset obj
        in
          if delta mod align = 0w0 then obj
          else offset (obj, align - (delta mod align))
        end
    fun alignWord (obj, align) =
        let
          val delta = objOffset obj
        in
          if delta mod align = 0w0 then obj
          else offset (obj, align - (delta mod align))
        end

    fun deref obj = (D.readBoxed (align(obj, RTy.PTRty RTy.INT32ty)), 0w0)
    fun getBoxed obj = D.readBoxed (align(obj, RTy.PTRty RTy.INT32ty))
    fun getRef obj = D.readBoxed (align(obj, RTy.PTRty RTy.INT32ty))
    fun getArray obj = D.readBoxed (align(obj, RTy.PTRty RTy.INT32ty))
    fun getVector obj = D.readBoxed (align(obj, RTy.PTRty RTy.INT32ty))
    fun getInt obj = D.readInt32 (align(obj, RTy.INT32ty))
    fun getInt8 obj = D.readInt8 (align(obj, RTy.INT8ty))
    fun getInt16 obj = D.readInt16 (align(obj, RTy.INT16ty))
    fun getBool obj = boolRep (getInt obj)
    fun getInt64 obj = D.readInt64 (align(obj, RTy.INT64ty))
    fun getIntInf obj = D.readIntInf (align(obj, RTy.INTINFty))
    fun getReal64 obj = D.readReal64 (align (obj, RTy.REAL64ty))
    fun getReal32 obj = D.readReal32 (align (obj, RTy.REAL32ty))
    fun getString obj = D.readString (align (obj, RTy.STRINGty))
    fun getLabel obj = RecordLabel.fromString (D.readString (align (obj, RTy.STRINGty)))
    fun getChar obj = D.readChar (align (obj, RTy.CHARty))
    fun getWord32 obj = D.readWord32 (align (obj, RTy.WORD32ty))
    fun getWord8 obj = D.readWord8 (align (obj, RTy.WORD8ty))
    fun getWord16 obj = D.readWord16 (align (obj, RTy.WORD16ty))
    fun getWord64 obj = D.readWord64 (align (obj, RTy.WORD64ty))
    fun getPtr obj = D.readPtr (align (obj, RTy.PTRty RTy.INT32ty))

    fun isNull obj = P.isNull (getPtr obj)
    fun car obj = obj
    fun cdr (ty, obj) = align (offset(obj, RTy.sizeOf ty), RTy.RECORDty RecordLabel.Map.empty)

    fun writeBoxed ((boxed,word), arg) = D.writeBoxed(boxed, word, arg)
    fun ('a#reify) setCdr (cons : 'a list, arg : 'a list) = 
      let
        val ty = #reifiedTy _reifyTy('a)
        val cdrPart = cdr(ty, (BP.castToBoxed cons, 0w0))
        val argBoxed = BP.castToBoxed arg
      in
        writeBoxed(cdrPart, argBoxed)
      end

    fun getExn exnObj =
        let
          val p = D.readBoxed exnObj
        in
          {exnName = getString (D.readBoxed (D.readBoxed (p, 0w0), 0w0), 0w0),
           hasArg = D.objectSize p > ptrSize * 0w2}
        end

    fun tagMapToConNameTy (tagMap, tag, conSet) =
        let
          val conName =         
              case (SEnv.listItemsi (SEnv.filter (fn x => x =  tag) tagMap)) of
                [(name, tag)] => name
              | _ => raise bug "tagMapToConName"
          val tyOpt = case SEnv.find(conSet, conName) of
                        NONE => raise bug "tagMapToConName"
                      | SOME tyOpt => tyOpt
        in
          (conName, tyOpt)
        end

    val SQLtyConList =
        [
         U.SQL_tyCon_exp,
         U.SQL_tyCon_whr,
         U.SQL_tyCon_from,
         U.SQL_tyCon_orderby,
         U.SQL_tyCon_offset,
         U.SQL_tyCon_limit,
         U.SQL_tyCon_select,
         U.SQL_tyCon_query,
         U.SQL_tyCon_command,
         U.SQL_tyCon_db
        ]

    fun ** (ty1, ty2) = RTy.RECORDty (RecordLabel.tupleMap [ty1, ty2])
    infix 5 **

    val SEnvListItemsInt = SEnv.listItemsi : int SEnv.map -> (string * int) list
    val SEnvListItemsReal = SEnv.listItemsi : real SEnv.map -> (string * real) list
    val SEnvListItemsBoxed = SEnv.listItemsi : boxed SEnv.map -> (string * boxed) list
    val senvi = fn x => BP.refToBoxed (ref (SEnvListItemsInt (BP.castFromBoxed x : int SEnv.map)))
    val senvr = fn x => BP.refToBoxed (ref (SEnvListItemsReal (BP.castFromBoxed x : real SEnv.map)))
    val senvb = fn x => BP.refToBoxed (ref (SEnvListItemsBoxed (BP.castFromBoxed x : boxed SEnv.map)))

    val IEnvListItemsInt = IEnv.listItemsi : int IEnv.map -> (int * int) list
    val IEnvListItemsReal = IEnv.listItemsi : real IEnv.map -> (int * real) list
    val IEnvListItemsBoxed = IEnv.listItemsi : boxed IEnv.map -> (int * boxed) list
    val ienvi = 
     fn x => BP.refToBoxed (ref (IEnvListItemsInt (BP.castFromBoxed x : int IEnv.map)))
    val ienvr = 
     fn x => BP.refToBoxed (ref (IEnvListItemsReal (BP.castFromBoxed x : real IEnv.map)))
    val ienvb = 
     fn x => BP.refToBoxed (ref (IEnvListItemsBoxed (BP.castFromBoxed x : boxed IEnv.map)))

    val RecordMapListItemsInt = RecordLabel.Map.listItemsi : int RecordLabel.Map.map -> (RecordLabel.label * int) list
    val RecordMapListItemsReal = RecordLabel.Map.listItemsi : real RecordLabel.Map.map -> (RecordLabel.label * real) list
    val RecordMapListItemsBoxed = RecordLabel.Map.listItemsi : boxed RecordLabel.Map.map -> (RecordLabel.label * boxed) list
    val recordMapi = 
     fn x => BP.refToBoxed (ref (RecordMapListItemsInt (BP.castFromBoxed x : int RecordLabel.Map.map)))
    val recordMapr = 
     fn x => BP.refToBoxed (ref (RecordMapListItemsReal (BP.castFromBoxed x : real RecordLabel.Map.map)))
    val recordMapb = 
     fn x => BP.refToBoxed (ref (RecordMapListItemsBoxed (BP.castFromBoxed x : boxed RecordLabel.Map.map)))

    val unprintableDatatypeTyConList = SQLtyConList
    fun dynamicToReifiedTerm toPrint (dynamic as {tyRep, obj}) = 
        let
          val {reifiedTy, conSetEnv} = RTy.getConstructTy tyRep
        in
          case reifiedTy of 
            RTy.ARRAYty elemTy =>
            if toPrint then
              let
                val obj = deref obj
                val objSize = size obj
                val elemSize = RTy.sizeOf elemTy
                val arrayLength = objSize div elemSize
                fun getElementTerm i = 
                    let
                      val obj = offset(obj, Word.fromInt i * elemSize)
                    in
                      dynamicToReifiedTerm 
                        toPrint
                        {tyRep={reifiedTy=elemTy, conSetEnv = conSetEnv}, 
                         obj = obj}
                    end
              in
                R.ARRAY_PRINT (Array.tabulate(Word.toInt arrayLength, getElementTerm))
              end
            else R.ARRAY (elemTy, getArray obj)
          | RTy.BOOLty =>  R.BOOL (getBool obj)
          | RTy.BOTTOMty =>  R.NULL
          | RTy.BOXEDty => R.BOXED (getBoxed obj)
          | RTy.BOUNDVARty biv => R.BOUNDVAR
          | RTy.CHARty => R.CHAR (getChar obj)
          | RTy.CODEPTRty => R.CODEPTR (getWord64 obj)
          | RTy.CONSTRUCTty {longsymbol, id, args, layout, conSet, size} =>
            if (List.exists (fn x => TypID.eq(#id (x()),id)) unprintableDatatypeTyConList 
                handle UserLevelPrimitive.IDNotFound _ => false)
            then R.UNPRINTABLE
            else
            (case layout of
               RTy.LAYOUT_TAGGED (RTy.TAGGED_RECORD {tagMap}) =>
               (* LAYOUT_TAGGED (TAGGED_RECORD):
                * Each variant is implemented as a tuple consisting of a tag field
                * and arguments of the variant.
                *     datatype 'a foo = Foo of int * int   --> {1: contagty, 2: int * int}
                *                     | Bar of bool        --> {1: contagty, 2: bool}
                *                     | Baz of 'a          --> {1: contagty, 2: 'a}
                *                     | Hoge               --> {1: contagty}
                *                     | Fuga               --> {1: contagty}
                *)
               let
                 val obj = deref obj
                 val tag = getInt obj
                 val (conName, tyOpt) = tagMapToConNameTy (tagMap, tag, conSet)
               in
                 case tyOpt of 
                   NONE => R.DATATYPE (conName, NONE, reifiedTy)
                 | SOME ty => 
                   let
                     val obj = offset (obj, tagSize)
                     val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
                   in
                     R.DATATYPE (conName, 
                                 SOME (dynamicToReifiedTerm toPrint ({tyRep=tyRep, obj = obj})),
                                reifiedTy)
                   end
               end
             | RTy.LAYOUT_TAGGED (RTy.TAGGED_OR_NULL {tagMap, nullName}) =>
               (* LAYOUT_TAGGED (TAGGED_OR_NULL):
                *     datatype 'a foo = Foo of int * int   --> {1: contagty, 2: int * int}
                *                     | Bar of bool        --> {1: contagty, 2: bool}
                *                     | Baz of 'a          --> {1: contagty, 2: 'a}
                *                     | Hoge               --> boxed (NULL)
                *)
               (
               if isNull obj then R.DATATYPE(nullName, NONE, reifiedTy)
               else
                 let
                   val obj = deref obj
                   val tag = getInt obj
                   val (conName, tyOpt) = tagMapToConNameTy (tagMap, tag, conSet)
                 in
                   case tyOpt of 
                     NONE => R.DATATYPE (conName, NONE, reifiedTy)
                   | SOME ty => 
                     let
                       val obj = offset (obj, tagSize)
                       val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
                       val term = dynamicToReifiedTerm toPrint {tyRep=tyRep, obj = obj}
                     in
                       R.DATATYPE (conName, SOME term, reifiedTy)
                     end
                 end
               )
             | RTy.LAYOUT_TAGGED (RTy.TAGGED_TAGONLY {tagMap}) => 
               (*     datatype foo = Foo                  --> contagty
                *                  | Bar                  --> contagty
                *                  | Baz                  --> contagty
                *)
               let
                 val tag = getInt obj
                 val (conName, _) = tagMapToConNameTy (tagMap, tag, conSet)
               in
                 R.DATATYPE (conName, NONE, reifiedTy)
               end
             | RTy.LAYOUT_ARG_OR_NULL {wrap} => 
               (* LAYOUT_ARG_OR_NULL {wrap=false}:
                *     datatype foo = Foo of int * foo      --> int * foo
                *                  | Bar                   --> boxed (NULL)
                * LAYOUT_ARG_OR_NULL {wrap=true}:
                *     datatype foo = Foo of int            --> {1: int}
                *                  | Bar                   --> boxed (NULL)
                *)
               let
                 val conTyOptList = SEnv.listItemsi conSet
                 val (nullName, (nonNullName, ty)) =
                     case conTyOptList of
                       [(s1, NONE), (s2, SOME ty)] => (s1, (s2, ty))
                     | [(s2, SOME ty), (s1, NONE)] => (s1, (s2, ty))
                     | _ => raise bug "RTy.LAYOUT_ARG_OR_NULL {wrap=false}"
                 val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
               in
                 if isNull obj then R.DATATYPE(nullName, NONE, reifiedTy)
                 else R.DATATYPE
                        (nonNullName, 
                         SOME (dynamicToReifiedTerm toPrint 
                                 ({tyRep=tyRep, 
                                   obj = if wrap then deref obj else obj}
                                 )
                              ),
                         reifiedTy
                        )
               end
             | RTy.LAYOUT_SINGLE_ARG {wrap} => 
               (* wrap=false
                *     datatype foo = Foo of int * int     --> int * int
                *     datatype void = Void of void        --> boxed
                * wrap=true
                *     datatype 'a foo = Foo of 'a         --> {1: 'a}
                *     datatype foo = Foo of int           --> {1: int}
                *)
               (
                case SEnv.listItemsi conSet of
                  [(name, SOME ty)] =>
                    let
                      val obj = if wrap then deref obj else obj
                      val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
                      val term = dynamicToReifiedTerm toPrint {tyRep=tyRep, obj = obj}
                    in
                      R.DATATYPE (name, SOME term, reifiedTy)
                    end
                | _ => raise bug "RTy.LAYOUT_SINGLE_ARG {wrap}"
               )
             | RTy.LAYOUT_CHOICE {falseName} =>
               (* If there are just two variant and both of them have no argument,
                * their representation is one unboxed integer.
                * The tag value is either 0 or 1.
                *     datatype foo = Bar                   --> contagty (0)
                *                  | Foo                   --> contagty (1)
                *)
               let
                 val tag = getInt obj
                 val trueName = 
                     case (SEnv.listKeys (SEnv.filteri (fn (l,_) => l <> falseName) conSet)) of
                       [name] => name
                     | _ => raise bug "RTy.LAYOUT_CHOICE {falseName}"
               in
                 R.DATATYPE (if tag = 0 then falseName else trueName, NONE, reifiedTy)
               end
             | RTy.LAYOUT_SINGLE => 
               (* The layout for datatypes consisting of just one no-argument variant.
                *     datatype foo = Foo                   --> contagty (0)
                *)
               let
                 val conName = 
                     case SEnv.listKeys conSet of
                       [name] => name
                     | _ => raise bug "RTy.LAYOUT_CHOICE {falseName}"
               in
                 R.DATATYPE (conName, NONE, reifiedTy)
               end
            )
          | RTy.DATATYPEty _ => raise bug "RTy.DATATYPEty"
          | RTy.DYNAMICty ty => R.DYNAMIC (ty, getBoxed obj)
          | RTy.EXNTAGty => R.EXNTAG
          | RTy.EXNty => R.EXN (getExn obj)
          | RTy.INT32ty => R.INT32 (getInt obj)
          | RTy.INT8ty => R.INT8 (getInt8 obj)
          | RTy.INT16ty => R.INT16 (getInt16 obj)
          | RTy.INT64ty => R.INT64 (getInt64 obj)
          | RTy.INTERNALty => R.INTERNAL 
          | RTy.INTINFty => R.INTINF (getIntInf obj)
          | RTy.LISTty elementTy =>
            let
              val tyRep = {reifiedTy = elementTy, conSetEnv = conSetEnv}
              fun getTail (obj, listRev) = 
                  if isNull obj then listRev
                  else 
                    let
                      val obj = deref obj
                      val firstJson = 
                          dynamicToReifiedTerm toPrint 
                            {tyRep = tyRep, obj = car obj}
                    in
                      getTail (cdr (reifiedTy, obj), firstJson::listRev)
                    end
            in
              R.LIST (List.rev (getTail (obj, nil)))
            end
          | RTy.SENVMAPty elementTy =>
            let
              val tyRep = {reifiedTy = RTy.STRINGty ** elementTy, conSetEnv = conSetEnv}
              val converter = if ReifiedTermToML.isBoxed elementTy then senvb
                              else case RTy.sizeOf elementTy of
                                     0w8 => senvr
                                   | _ => senvi
              val (boxed,word) = deref obj
              val obj = (converter boxed, 0w0)
              fun getTail (obj, listRev) = 
                  if isNull obj then listRev
                  else 
                    let
                      val obj = deref obj
                      val keyValue =
                          dynamicToReifiedTerm 
                            toPrint 
                            {tyRep = tyRep, obj = car obj}
                      val (label, term) =
                          case keyValue of
                            R.RECORD map => 
                            (case RecordLabel.Map.listItemsi map of
                               [(l1,R.STRING key), (l2, value)] =>
                               (key, value)
                             | _ => raise bug "illegal SEnv entry")
                          | _ =>  raise bug "illegal SEnv entry"
                    in
                      getTail (cdr (reifiedTy, obj), 
                               (label, term)::listRev)
                    end
            in
              R.SENVMAP (List.rev (getTail (obj, nil)))
            end
          | RTy.RECORDLABELMAPty elementTy =>
            let
              val tyRep = {reifiedTy = RTy.RECORDLABELty ** elementTy, conSetEnv = conSetEnv}
              val converter = if ReifiedTermToML.isBoxed elementTy then recordMapb
                              else case RTy.sizeOf elementTy of
                                     0w8 => recordMapr
                                   | _ => recordMapi
                val (boxed,word) = deref obj
                val obj = (converter boxed, 0w0)
                fun getTail (obj, listRev) = 
                    if isNull obj then listRev
                    else 
                      let
                        val obj = deref obj
                        val keyValue =
                            dynamicToReifiedTerm 
                              toPrint 
                              {tyRep = tyRep, obj = car obj}
                        val (label, term) =
                            case keyValue of
                              R.RECORD map => 
                              (case RecordLabel.Map.listItemsi map of
                                 [(l1,R.RECORDLABEL key), (l2, value)] =>
                                 (key, value)
                               | _ => raise bug "illegal RecordLabel.Map entry")
                            | _ =>  raise bug "illegal RecordLabel.Map entry"
                      in
                        getTail (cdr (reifiedTy, obj), 
                                 (label, term)::listRev)
                      end
              in
                R.RECORDLABELMAP (List.rev (getTail (obj, nil)))
              end
          | RTy.IENVMAPty elementTy =>
            let
              val tyRep = {reifiedTy = RTy.INT32ty ** elementTy, conSetEnv = conSetEnv}
              val converter = if ReifiedTermToML.isBoxed elementTy then ienvb
                              else case RTy.sizeOf elementTy of
                                     0w8 => ienvr
                                   | _ => ienvi
              val obj = deref obj
              val (boxed,word) = obj
              val obj = (converter boxed, 0w0)
              fun getTail (obj, listRev) = 
                  if isNull obj then listRev
                  else 
                    let
                      val obj = deref obj
                      val keyValue =
                          dynamicToReifiedTerm 
                            toPrint 
                            {tyRep = tyRep, obj = car obj}
                      val (key, term) =
                          case keyValue of
                            R.RECORD map => 
                            (case RecordLabel.Map.listItemsi map of
                               [(l1,R.INT32 key), (l2, value)] =>
                               (key, value)
                             | _ => raise bug "illegal SEnv entry")
                          | _ => raise bug "illegal SEnv entry"
                    in
                      getTail (cdr (reifiedTy, obj), 
                               (key, term)::listRev)
                    end
            in
              R.IENVMAP (List.rev (getTail (obj, nil)))
            end
          | RTy.OPAQUEty _ => R.UNPRINTABLE
          | RTy.OPTIONty elemTy => 
            if isNull obj then R.OPTION (NONE, elemTy)
            else R.OPTION
                   (SOME (dynamicToReifiedTerm toPrint 
                            {tyRep = {reifiedTy = elemTy, conSetEnv=conSetEnv}, 
                             obj = deref obj}),
                    elemTy)
          | RTy.POLYty {boundenv, body} => 
            let
              val btvList = BoundTypeVarID.Map.listItems boundenv
              val instTyList = map (fn x => RTy.UNITty) btvList
              val instBodyTy = RTy.instantiate (reifiedTy, instTyList)
              val tyRep = {reifiedTy = instBodyTy, conSetEnv = conSetEnv}
            in
              dynamicToReifiedTerm toPrint {tyRep = tyRep, obj = obj}
            end
          | RTy.PTRty _ => R.PTR (getWord64 obj)
          | (ty as RTy.FUNMty _) => R.FUN {closure=(#1 (deref obj)), ty=ty}
          | RTy.TYVARty => R.UNPRINTABLE
          | RTy.ERRORty => R.UNPRINTABLE
          | RTy.DUMMYty _ => R.UNPRINTABLE
          | RTy.EXISTty _ => R.UNPRINTABLE
          | RTy.REAL32ty  => R.REAL32 (getReal32 obj)
          | RTy.REAL64ty => R.REAL64 (getReal64 obj)
          | RTy.RECORDLABELty => R.RECORDLABEL (getLabel obj)
          | RTy.RECORDty fieldsTy =>
            let
              val (_, fields) =
                  RecordLabel.Map.foldli
                    (fn (l, ty, (obj, map)) =>
                        let
                          val obj = align(obj, ty)
                          val term = dynamicToReifiedTerm 
                                       toPrint 
                                       {tyRep = {reifiedTy = ty, conSetEnv = conSetEnv},
                                        obj = obj}
                          val obj = offset(obj, RTy.sizeOf ty)
                        in
                          (obj, RecordLabel.Map.insert(map,l,term))
                        end
                    )
                    (deref obj, RecordLabel.Map.empty)
                    fieldsTy
            in
              R.RECORD fields
            end
          | RTy.REFty elemTy => 
            if toPrint then
              let
                val obj = deref obj
                val tyRep = {reifiedTy = elemTy, conSetEnv = conSetEnv}
              in
                R.REF_PRINT (dynamicToReifiedTerm toPrint {tyRep = tyRep, obj = obj})
              end
            else R.REF (elemTy, getRef obj)
          | RTy.STRINGty => R.STRING (getString obj)
          | RTy.VOIDty => R.UNPRINTABLE
          | RTy.UNITty  => R.UNIT
          | RTy.VECTORty elemTy => 
            if toPrint then
              let
                val obj = deref obj
                val objSize = size obj
                val elemSize = RTy.sizeOf elemTy
                val arrayLength = objSize div elemSize
                fun getElementTerm i = 
                    let
                      val obj = offset(obj, Word.fromInt i * elemSize)
                    in
                      dynamicToReifiedTerm 
                        toPrint
                        {tyRep={reifiedTy=elemTy, conSetEnv = conSetEnv}, 
                         obj = obj}
                    end
              in
                R.VECTOR_PRINT (Vector.tabulate(Word.toInt arrayLength, getElementTerm))
              end
            else R.VECTOR (elemTy, getVector obj)
          | RTy.WORD8ty => R.WORD8 (getWord8 obj)
          | RTy.WORD16ty => R.WORD16 (getWord16 obj)
          | RTy.WORD64ty => R.WORD64 (getWord64 obj)
          | RTy.WORD32ty => R.WORD32 (getWord32 obj)
        end

    fun ('a#reify) dynamic (x:'a) : dynamic = 
        {tyRep = _reifyTy('a), 
         obj = (BP.refToBoxed (ref x) : boxed, 0w0)}

    fun ('a#reify) toReifiedTerm (x:'a) = 
        dynamicToReifiedTerm false (dynamic x)

    fun ('a#reify) toReifiedTermPrint (x:'a) = 
        dynamicToReifiedTerm true (dynamic x)

    fun ('a#reify) pp (x:'a) = 
        (TextIO.print (R.reifiedTermToString (toReifiedTerm x));
         TextIO.print  "\n")

    fun ('a#reify) typeOf (x:'a) = _reifyTy('a)

end
end
