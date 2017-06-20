(**
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 *)

structure ReifyTerm =
struct
  local
    structure D = SMLSharp_Builtin.Dynamic
    structure PP = SMLSharp_Builtin.Pointer
    structure P = Pointer
    structure R = ReifiedTerm
    structure RTy = ReifiedTy 
  in
    type tyRep = ReifiedTy.tyRep
    type object = boxed * word
    type dynamic = {tyRep : tyRep, obj : object}

    fun offset ((boxed, word) : object, offset) = (boxed, word + offset)
    fun size ((boxed, offset): object) = D.objectSize boxed

    (* offsets *)
    val word32Size = 0w4
    val word8Size = 0w1
    val word16Size = 0w2
    val word64Size = 0w8
    val tagSize = 0w4
    val realSize = 0w8
    val real32Size = 0w4
    val ptrSize = Word.fromInt (!SMLSharp_PointerSize.pointerSize)      

    fun sizeOf reifiedTy = 
        case reifiedTy of
          RTy.ARRAYty reifiedTy => ptrSize
        | RTy.BOOLty => word32Size
        | RTy.BOUNDVARty BoundTypeVarIDid => 0w0 (* error size *)
        | RTy.CHARty => word8Size
        | RTy.CODEPTRty => ptrSize
        | RTy.CONSTRUCTty {longsymbol, id, args, conSet, layout, size} => Word.fromInt size
        | RTy.DATATYPEty {longsymbol, id, args, layout, size} => Word.fromInt size
        | RTy.EXNTAGty => word32Size
        | RTy.EXNty  => ptrSize
        | RTy.INTty => word32Size
        | RTy.INT8ty => word8Size
        | RTy.INT16ty => word16Size
        | RTy.INT64ty => word64Size
        | RTy.INTERNALty size => Word.fromInt size
        | RTy.INTINFty => ptrSize
        | RTy.LISTty reifiedTy => ptrSize
        | RTy.OPAQUEty {size,...} => Word.fromInt size
        | RTy.OPTIONty reifiedTy => ptrSize
        | RTy.POLYty {boundenv, body} => sizeOf body
        | RTy.PTRty reifiedTy  => ptrSize
        | RTy.ERRORty  => 0w0 (* error size *)
        | RTy.DUMMYty {boxed, size} => size
        | RTy.FUNty  => ptrSize
        | RTy.TYVARty => 0w0 (* error size *)
        | RTy.REAL32ty  => real32Size
        | RTy.REALty => realSize
        | RTy.RECORDty reifiedTyLabelMap => ptrSize
        | RTy.REFty reifiedTy => ptrSize
        | RTy.STRINGty => ptrSize
        | RTy.UNITty => word32Size
        | RTy.VECTORty reifiedTy => ptrSize
        | RTy.WORD8ty => word8Size
        | RTy.WORD16ty => word16Size
        | RTy.WORD64ty => word64Size
        | RTy.WORDty => word32Size

    fun alignOf reifiedTy = sizeOf reifiedTy

    fun typeOf (dyn : dynamic) = #tyRep dyn
    fun objOf (dyn : dynamic) = #obj dyn
    fun objOffset ((boxed, offset):object) = offset
    fun setOffset ((boxed, _):object, offset) = (boxed, offset) : object

    fun boolRep 0 = false 
      | boolRep 1 = true 
      | boolRep _ = raise Bug.Bug "illeagal boolean representation"
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

    fun deref obj = (D.readBoxed (align(obj, RTy.PTRty RTy.INTty)), 0w0)
    fun getInt obj = D.readInt32 (align(obj, RTy.INTty))
    fun getInt8 obj = D.readInt8 (align(obj, RTy.INT8ty))
    fun getInt16 obj = D.readInt16 (align(obj, RTy.INT16ty))
    fun getBool obj = boolRep (getInt obj)
    fun getInt64 obj = D.readInt64 (align(obj, RTy.INT64ty))
    fun getIntInf obj = D.readIntInf (align(obj, RTy.INTINFty))
    fun getReal obj = D.readReal64 (align (obj, RTy.REALty))
    fun getReal32 obj = D.readReal32 (align (obj, RTy.REAL32ty))
    fun getString obj = D.readString (align (obj, RTy.STRINGty))
    fun getChar obj = D.readChar (align (obj, RTy.CHARty))
    fun getWord obj = D.readWord32 (align (obj, RTy.WORDty))
    fun getWord8 obj = D.readWord8 (align (obj, RTy.WORD8ty))
    fun getWord16 obj = D.readWord16 (align (obj, RTy.WORD16ty))
    fun getWord64 obj = D.readWord64 (align (obj, RTy.WORD64ty))
    fun getPtr obj = D.readPtr (align (obj, RTy.PTRty RTy.INTty))

    fun isNull obj = P.isNull (getPtr obj)
    fun car obj = obj
    fun cdr (ty, obj) = align (offset(obj, sizeOf ty), RTy.RECORDty RecordLabel.Map.empty)

    fun writeBoxed ((boxed,word), arg) = D.writeBoxed(boxed, word, arg)
    fun ('a#reify) setCdr (cons : 'a list, arg : 'a list) = 
      let
        val ty = #reifiedTy _reifyTy('a)
        val cdrPart = cdr(ty, (PP.toBoxed cons, 0w0))
        val argBoxed = PP.toBoxed arg
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
              | _ => raise Bug.Bug "tagMapToConName"
          val tyOpt = case SEnv.find(conSet, conName) of
                        NONE => raise Bug.Bug "tagMapToConName"
                      | SOME tyOpt => tyOpt
        in
          (conName, tyOpt)
        end

    val SQLtyConList =
        [
         UserLevelPrimitive.SQL_exp_tyCon,
         UserLevelPrimitive.SQL_whr_tyCon,
         UserLevelPrimitive.SQL_from_tyCon,
         UserLevelPrimitive.SQL_orderby_tyCon,
         UserLevelPrimitive.SQL_offset_tyCon,
         UserLevelPrimitive.SQL_limit_tyCon,
         UserLevelPrimitive.SQL_select_tyCon,
         UserLevelPrimitive.SQL_query_tyCon,
         UserLevelPrimitive.SQL_command_tyCon,
         UserLevelPrimitive.SQL_db_tyCon
        ]
    val JSONtyConList =
        [
         UserLevelPrimitive.JSON_dyn_tyCon,
         UserLevelPrimitive.JSON_json_tyCon,
         UserLevelPrimitive.JSON_jsonTy_tyCon,
         UserLevelPrimitive.JSON_void_tyCon,
         UserLevelPrimitive.JSON_null_tyCon
        ]
    val unprintableDatatypeTyConList = SQLtyConList @ JSONtyConList
    fun dynamicToReifiedTerm (dynamic as {tyRep, obj}) = 
        let
          val {reifiedTy, conSetEnv} = RTy.getConstructTy tyRep
        in
          case reifiedTy of 
            RTy.ARRAYty reifiedTy =>
            let
              val obj = deref obj
              val objSize = size obj
              val elemSize = sizeOf reifiedTy
              val arrayLength = objSize div elemSize
              fun getElementTerm i = 
                  let
                    val obj = offset(obj, Word.fromInt i * elemSize)
                  in
                    dynamicToReifiedTerm
                      {tyRep={reifiedTy=reifiedTy, conSetEnv = conSetEnv}, 
                       obj = obj}
                  end
            in
              R.ARRAY2 (Array.tabulate(Word.toInt arrayLength, getElementTerm))
            end
          | RTy.BOOLty =>  R.BOOL (getBool obj)
          | RTy.BOUNDVARty biv => R.BOUNDVAR
          | RTy.CHARty => R.CHAR (getChar obj)
          | RTy.CODEPTRty => R.CODEPTR (getWord64 obj)
          | RTy.CONSTRUCTty {longsymbol, id, args, layout, conSet, size} =>
            if List.exists (fn x => TypID.eq(#id (x()),id)) unprintableDatatypeTyConList then
              R.UNPRINTABLE
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
                   NONE => R.DATATYPE (conName, NONE)
                 | SOME ty => 
                   let
                     val obj = offset (obj, tagSize)
                     val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
                   in
                     R.DATATYPE (conName, 
                                 SOME (dynamicToReifiedTerm ({tyRep=tyRep, obj = obj})))
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
               if isNull obj then R.DATATYPE(nullName, NONE)
               else
                 let
                   val obj = deref obj
                   val tag = getInt obj
                   val (conName, tyOpt) = tagMapToConNameTy (tagMap, tag, conSet)
                 in
                   case tyOpt of 
                     NONE => R.DATATYPE (conName, NONE)
                   | SOME ty => 
                     let
                       val obj = offset (obj, tagSize)
                       val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
                       val term = dynamicToReifiedTerm {tyRep=tyRep, obj = obj}
                     in
                       R.DATATYPE (conName, SOME term)
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
                 R.DATATYPE (conName, NONE)
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
                     | _ => raise Bug.Bug "RTy.LAYOUT_ARG_OR_NULL {wrap=false}"
                 val tyRep = {reifiedTy = ty, conSetEnv = conSetEnv}
               in
                 if isNull obj then R.DATATYPE(nullName, NONE)
                 else R.DATATYPE
                        (nonNullName, 
                         SOME (dynamicToReifiedTerm 
                                 ({tyRep=tyRep, 
                                   obj = if wrap then deref obj else obj}
                                 )
                              )
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
                      val term = dynamicToReifiedTerm {tyRep=tyRep, obj = obj}
                    in
                      R.DATATYPE (name, SOME term)
                    end
                | _ => raise Bug.Bug "RTy.LAYOUT_SINGLE_ARG {wrap}"
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
                     | _ => raise Bug.Bug "RTy.LAYOUT_CHOICE {falseName}"
               in
                 R.DATATYPE (if tag = 0 then falseName else trueName, NONE)
               end
             | RTy.LAYOUT_SINGLE => 
               (* The layout for datatypes consisting of just one no-argument variant.
                *     datatype foo = Foo                   --> contagty (0)
                *)
               let
                 val conName = 
                     case SEnv.listKeys conSet of
                       [name] => name
                     | _ => raise Bug.Bug "RTy.LAYOUT_CHOICE {falseName}"
               in
                 R.DATATYPE (conName, NONE)
               end
            )
          | RTy.DATATYPEty _ => raise Bug.Bug "RTy.DATATYPEty"
          | RTy.EXNTAGty => R.EXNTAG
          | RTy.EXNty => R.EXN (getExn obj)
          | RTy.INTty => R.INT (getInt obj)
          | RTy.INT8ty => R.INT8 (getInt8 obj)
          | RTy.INT16ty => R.INT16 (getInt16 obj)
          | RTy.INT64ty => R.INT64 (getInt64 obj)
          | RTy.INTERNALty elementTy => R.INTERNAL 
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
                          dynamicToReifiedTerm 
                            {tyRep = tyRep, obj = car obj}
                    in
                      getTail (cdr (reifiedTy, obj), firstJson::listRev)
                    end
            in
              R.LIST (List.rev (getTail (obj, nil)))
            end
          | RTy.OPAQUEty _ => R.UNPRINTABLE
          | RTy.OPTIONty reifiedTy => 
            if isNull obj then R.OPTION NONE
            else R.OPTION 
                 (SOME (dynamicToReifiedTerm 
                          {tyRep = {reifiedTy = reifiedTy, conSetEnv=conSetEnv}, 
                           obj = deref obj}))
          | RTy.POLYty {boundenv, body} => 
            let
              val btvList = BoundTypeVarID.Map.listItems boundenv
              val instTyList = map (fn x => RTy.UNITty) btvList
              val instBodyTy = RTy.instantiate (reifiedTy, instTyList)
              val tyRep = {reifiedTy = instBodyTy, conSetEnv = conSetEnv}
            in
              dynamicToReifiedTerm {tyRep = tyRep, obj = obj}
            end
          | RTy.PTRty _ => R.PTR (getWord64 obj)
          | RTy.FUNty => R.FUN (#1 (deref obj))
          | RTy.TYVARty => R.UNPRINTABLE
          | RTy.ERRORty => R.UNPRINTABLE
          | RTy.DUMMYty _ => R.UNPRINTABLE
          | RTy.REAL32ty  => R.REAL32 (getReal32 obj)
          | RTy.REALty => R.REAL (getReal obj)
          | RTy.RECORDty fieldsTy =>
            let
              val fieldsTyRep = 
                  map (fn (l, ty) => (l, {reifiedTy = ty, conSetEnv = conSetEnv}))
                      (RecordLabel.Map.listItemsi fieldsTy)
              fun getFields (nil, obj, fieldsRev) = List.rev fieldsRev
                | getFields ((l,tyRep as {reifiedTy = ty,...})::rest, obj, fieldsRev) = 
                  let
                    val obj = align(obj, ty)
                    val term = dynamicToReifiedTerm {tyRep = tyRep, obj = obj}
                    val obj = offset(obj, sizeOf ty)
                  in
                    getFields (rest, obj, (l,term)::fieldsRev)
                  end
              val obj = deref obj
              val fields = getFields(fieldsTyRep, obj, nil)
            in
              if RecordLabel.isTupleList fields
              then R.TUPLE (map (fn (_,v) => v) fields)
              else R.RECORD (map (fn (l, v) => (RecordLabel.toString l, v)) fields)
            end
          | RTy.REFty reifiedTy => 
            let
              val obj = deref obj
              val tyRep = {reifiedTy = reifiedTy, conSetEnv = conSetEnv}
            in
              R.REF (dynamicToReifiedTerm {tyRep = tyRep, obj = obj})
            end
          | RTy.STRINGty => R.STRING (getString obj)
          | RTy.UNITty  => R.UNIT
          | RTy.VECTORty reifiedTy => 
            let
              val obj = deref obj
              val objSize = size obj
              val elemSize = sizeOf reifiedTy
              val arrayLength = objSize div elemSize
              fun getElementTerm i = 
                  let
                    val obj = offset(obj, Word.fromInt i * elemSize)
                  in
                    dynamicToReifiedTerm
                      {tyRep={reifiedTy=reifiedTy, conSetEnv = conSetEnv}, 
                       obj = obj}
                  end
            in
              R.VECTOR2 (Vector.tabulate(Word.toInt arrayLength, getElementTerm))
            end
          | RTy.WORD8ty => R.WORD8 (getWord8 obj)
          | RTy.WORD16ty => R.WORD16 (getWord16 obj)
          | RTy.WORD64ty => R.WORD64 (getWord64 obj)
          | RTy.WORDty => R.WORD (getWord obj)
        end

    fun ('a#reify) dynamic (x:'a) : dynamic = 
        {tyRep = _reifyTy('a), 
         obj = (PP.refToBoxed (ref x) : boxed, 0w0)}

    fun ('a#reify) toReifiedTerm (x:'a) = 
        dynamicToReifiedTerm (dynamic x)

end
end
