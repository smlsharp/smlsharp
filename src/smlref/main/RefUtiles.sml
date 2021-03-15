structure RefUtiles =
struct
  open DBSchema RefTypes 
  type sym = RefTypes.sym
  exception REF_NODE_NOT_FOUND of sym
  exception DEF_NODE_NOT_FOUND of sym

  fun printNode node = 
      print (SMLFormat.prettyPrint nil (RefTypes.format_node node) ^ "\n")
  fun printNodeTree t = 
      print (SMLFormat.prettyPrint nil (RefTypes.format_nodeTree t) ^ "\n")

  fun defTupleToNode 
       (defTuple as {
         category : string,
         defRangeEndPos : int,
         defRangeFileId : int,
         defRangeStartPos : int,
         defSymbol : string,
         defSymbolEndPos : int,
         defSymbolFileId : int,
         defSymbolStartPos : int,
         definedSymbol : string,
         internalId : int,
         kind : string,
         sourceFileId : int,
         tfunKind : string
        } : DBSchema.defTuple)
    =
    let
      val sym = {endPos = defSymbolEndPos,
                 startPos = defSymbolStartPos,
                 fileId = defSymbolFileId,
                 symbol = defSymbol}
      val range = {endPos = defRangeEndPos,
                   startPos = defRangeStartPos}
      val default = {sym = sym, range = range, kind = ID defTuple}
    in
      case (category, kind) of 
        ("PROVIDE", _) => (Dynamic.pp ("defTupleToDefInfo", defTuple);
                           DEF default)
      | ("INTERFACE", "IDEXVAR") =>       INT (default # {kind = VAR defTuple})
      | ("INTERFACE", "IDVAR") =>         INT (default # {kind = VAR defTuple})
      | ("INTERFACE", "IDBUILTINVAR") =>  INT (default # {kind = VAR defTuple})
      | ("INTERFACE", "IDOPRIM") =>       INT (default # {kind = PRIM defTuple})
      | ("INTERFACE", "IDEXEXNREP") =>    INT (default # {kind = EXN defTuple})
      | ("INTERFACE", "IDEXEXN") =>       INT (default # {kind = EXN defTuple})
      | ("INTERFACE", "IDEXNREP") =>      INT (default # {kind = EXN defTuple})
      | ("INTERFACE", "IDCON") =>         INT (default # {kind = CON defTuple})
      | ("INTERFACE", "TSTR") =>          INT (default # {kind = TYCON defTuple})
      | ("INTERFACE", "TSTR_DTY") =>      INT (default # {kind = TYCON defTuple})
      | ("INTERFACE", "STR") =>           INT (default # {kind = STR defTuple})
      | ("INTERFACE", "FUN") =>           INT (default # {kind = FUNCTOR defTuple})
      | ("SIG", "IDSPECVAR") =>           DEF (default # {kind = SIG_VAR defTuple})
      | ("SIG", "IDSPECEXN") =>           DEF (default # {kind = SIG_EXN defTuple})
      | ("BIND_STR", _) =>                DEF (default # {kind = STR defTuple})
      | ("BIND_SIG", _) =>                DEF (default # {kind = SIG defTuple})
      | ("BIND_FUNCTION", _) =>           DEF (default # {kind = FUNCTION defTuple})
      | ("BIND_TSTR", _) =>               DEF (default # {kind = TYCON defTuple})
      | ("BIND_PAT_FN", _) =>             DEF (default # {kind = LOCAL_VAR defTuple})
      | ("BIND_PAT_CASE", _) =>           DEF (default # {kind = LOCAL_VAR defTuple})
      | (_, "IDVAR") =>                   DEF (default # {kind = VAR defTuple})
      | (_, "IDVAR_TYPED") =>             DEF (default # {kind = VAR defTuple})
      | (_, "IDCON") =>                   DEF (default # {kind = CON defTuple})
      | (_, "IDOPRIM") =>                 DEF (default # {kind = PRIM defTuple})
      | (_, "IDEXVAR") =>                 DEF (default # {kind = VAR defTuple})
      | (_, "IDBUILTINVAR") =>            DEF (default # {kind = VAR defTuple})
      | (_, "IDEXN") =>                   DEF (default # {kind = EXN defTuple})
      | (_, "IDEXNREP") =>                DEF (default # {kind = EXN defTuple})
      | (_, "IDEXEXN") =>                 DEF (default # {kind = EXN defTuple})
      | (_, "IDEXEXNREP") =>              DEF (default # {kind = EXN defTuple})
      | (_, "TSTR") =>                    DEF (default # {kind = TYCON defTuple})
      | (_, "STR") =>                     DEF (default # {kind = STR defTuple})
      | (_, "SIG") =>                     DEF (default # {kind = SIG defTuple})
      | (_, "EXN") =>                     DEF (default # {kind = EXN defTuple})
      | (_, "FUN") =>                     DEF (default # {kind = FUNCTOR defTuple})
      | (_, "TSTR_DTY") =>                DEF (default # {kind = TYCON defTuple})
      | _ => (Dynamic.pp ("defTupleToDefInfo", defTuple); DEF default)
    end
      
  fun refTupleToNode 
      (refTuple as {
         category : string,
         defRangeEndPos : int,
         defRangeFileId : int,
         defRangeStartPos : int,
         defSymbol : string,
         defSymbolEndPos : int,
         defSymbolFileId : int,
         defSymbolStartPos : int,
         definedSymbol : string,
         internalId : int,
         kind : string,
         refSymbol : string,
         refSymbolEndPos : int,
         refSymbolFileId : int,
         refSymbolStartPos : int,
         sourceFileId : int,
         tfunKind : string
        } : DBSchema.refTuple)
    =
    let
      val sym = {endPos = refSymbolEndPos,
                 startPos = refSymbolStartPos,
                 fileId = refSymbolFileId,
                 symbol = refSymbol}
      val def = {endPos = defSymbolEndPos,
                 startPos = defSymbolStartPos,
                 fileId = defSymbolFileId,
                 symbol = defSymbol}
      val default = {sym = sym, def = def, kind = REFERENCE_ID refTuple}
    in
      case (category, kind) of 
        ("PROVIDE", "IDVAR") =>         REF (default # {kind = PROVIDE_VAR refTuple})
      | ("PROVIDE", "IDEXVAR") =>       REF (default # {kind = PROVIDE_VAR refTuple})
      | ("PROVIDE", "IDBUILTINVAR") =>  REF (default # {kind = PROVIDE_VAR refTuple})
      | ("PROVIDE", "IDEXEXNREP") =>    REF (default # {kind = PROVIDE_EXN refTuple})
      | ("PROVIDE", "IDEXEXN") =>       REF (default # {kind = PROVIDE_EXN refTuple})
      | ("PROVIDE", "IDCON") =>         REF (default # {kind = PROVIDE_CON refTuple})
      | ("PROVIDE", "TSTR") =>          REF (default # {kind = PROVIDE_TYCON refTuple})
      | ("PROVIDE", "TSTR_DTY") =>      REF (default # {kind = PROVIDE_TYCON refTuple})
      | ("PROVIDE", "STR") =>           REF (default # {kind = PROVIDE_STR refTuple})
      | (_, "IDVAR") =>                 REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "IDEXVAR") =>               REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "IDBUILTINVAR") =>          REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "IDEXEXNREP") =>            REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "IDEXEXN") =>               REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "IDCON") =>                 REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "TSTR") =>                  REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "TSTR_DTY") =>              REF (default # {kind = REFERENCE_VAR refTuple})
      | (_, "STR") =>                   REF (default # {kind = REFERENCE_VAR refTuple})
      | _ =>
        (Dynamic.pp ("refTupleToRefInfo",category, kind);
         REF default)
    end

  fun listDefsInFile fileName =
      let
        val fileId = DBBasics.fileNameToFileId fileName
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.kind as kind,
               #d.sourceFileId as sourceFileId,
               #d.category as category,
               #d.defSymbol as defSymbol,
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.defRangeFileId as defRangeFileId,
               #d.defRangeStartPos as defRangeStartPos,
               #d.defRangeEndPos as defRangeEndPos,
               #d.definedSymbol as definedSymbol,
               #d.internalId as internalId,
               #d.tfunKind as tfunKind
            from 
              #db.defTable as d
            where
              #d.defSymbolFileId = fileId
            order by #.defSymbolStartPos
           )
	     (Config.getConn ())
        val defTuples = SQL.fetchAll r
      in
        map defTupleToNode defTuples
      end

  fun symOfNode node = 
      case node of
        REF {sym,...} => sym
      | DEF {sym,...} => sym
      | INT {sym,...} => sym

  fun nodeOfDefSym (sym as {fileId, startPos, endPos, symbol}) =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.category as category,
               #d.defRangeEndPos as defRangeEndPos,
               #d.defRangeFileId as defRangeFileId,
               #d.defRangeStartPos as defRangeStartPos,
               #d.defSymbol as defSymbol,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.definedSymbol as definedSymbol,
               #d.internalId as internalId,
               #d.kind as kind,
               #d.sourceFileId as sourceFileId,
               #d.tfunKind as tfunKind
            from 
              #db.defTable as d
            where
            ((#d.defSymbolFileId = fileId and
              #d.defSymbol = symbol) and
              #d.defSymbolStartPos = startPos)
            order by #.defSymbolStartPos
           )
	     (Config.getConn ())
        val defTuple = 
            case SQL.fetchAll r of
              nil => raise DEF_NODE_NOT_FOUND sym
            | h::_ => h
      in
        defTupleToNode defTuple
      end

  fun nodeOfRefSym (sym as {fileId, startPos, endPos, symbol}) =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #r.category as category,
              #r.defRangeEndPos as defRangeEndPos,
              #r.defRangeFileId as defRangeFileId,
              #r.defRangeStartPos as defRangeStartPos,
              #r.defSymbol as defSymbol,
              #r.defSymbolEndPos as defSymbolEndPos,
              #r.defSymbolFileId as defSymbolFileId,
              #r.defSymbolStartPos as defSymbolStartPos,
              #r.definedSymbol as definedSymbol,
              #r.internalId as internalId,
              #r.kind as kind,
              #r.sourceFileId as sourceFileId,
              #r.tfunKind as tfunKind,
              #r.refSymbolFileId as refSymbolFileId,
              #r.refSymbol as refSymbol,
              #r.refSymbolStartPos as refSymbolStartPos,
              #r.refSymbolEndPos as refSymbolEndPos
            from 
              #db.refTable as r
            where
            ((#r.refSymbol = symbol and
              #r.refSymbolFileId = fileId) and
              #r.refSymbolStartPos = startPos)
            order by #.refSymbolStartPos
           )
	     (Config.getConn ())
        val refTuple = 
            case SQL.fetchAll r of
              nil => raise REF_NODE_NOT_FOUND sym
            | h::_ => h

      in
        refTupleToNode refTuple
      end

  fun findParents node  =
      let
        val {fileId, startPos, endPos, symbol} = symOfNode node
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.kind as kind,
               #d.sourceFileId as sourceFileId,
               #d.category as category,
               #d.defSymbol as defSymbol,
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.defRangeFileId as defRangeFileId,
               #d.defRangeStartPos as defRangeStartPos,
               #d.defRangeEndPos as defRangeEndPos,
               #d.definedSymbol as definedSymbol,
               #d.internalId as internalId,
               #d.tfunKind as tfunKind
            from 
              #db.defTable as d
            where
            ((((#d.defRangeFileId = fileId and
                #d.defSymbolFileId = fileId) and
                #d.defRangeStartPos <= startPos) and
                #d.defRangeEndPos > endPos) and
                #d.defSymbol <> symbol)
            order by #.defSymbolStartPos desc
           )
	     (Config.getConn ())
        val defTuples = SQL.fetchAll r
      in
        map defTupleToNode defTuples
      end

  fun findRefsInDef (node as REF _) = nil
    | findRefsInDef (node as INT  _) = nil
    | findRefsInDef (node as DEF {range={startPos, endPos}, sym = {fileId,...},...}) =
      let
        val r = 
            (_sql db : (dbSchema,'_) SQL.db =>
             select
               #r.category as category,
               #r.defRangeEndPos as defRangeEndPos,
               #r.defRangeFileId as defRangeFileId,
               #r.defRangeStartPos as defRangeStartPos,
               #r.defSymbol as defSymbol,
               #r.defSymbolEndPos as defSymbolEndPos,
               #r.defSymbolFileId as defSymbolFileId,
               #r.defSymbolStartPos as defSymbolStartPos,
               #r.definedSymbol as definedSymbol,
               #r.internalId as internalId,
               #r.kind as kind,
               #r.sourceFileId as sourceFileId,
               #r.tfunKind as tfunKind,
               #r.refSymbolFileId as refSymbolFileId,
               #r.refSymbol as refSymbol,
               #r.refSymbolStartPos as refSymbolStartPos,
               #r.refSymbolEndPos as refSymbolEndPos
             from 
               #db.refTable as r
             where
              ((#r.defRangeFileId = fileId and
                #r.defRangeStartPos >= startPos) and
                #r.defRangeEndPos < endPos)
              order by #.refSymbolStartPos desc
            )
           (Config.getConn ())
        val refTuples = SQL.fetchAll r
      in
        map refTupleToNode refTuples
      end

  fun defOfRef node =
      let
        val sym as {fileId, startPos, endPos, symbol} = symOfNode node
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #r.defSymbol as symbol,
              #r.defSymbolEndPos as endPos,
              #r.defSymbolFileId as fileId,
              #r.defSymbolStartPos as startPos
            from 
              #db.refTable as r
            where
            ((#r.refSymbol = symbol and
              #r.refSymbolFileId = fileId) and
              #r.refSymbolStartPos = startPos)
            order by #.startPos
           )
	     (Config.getConn ())
        val defSym = 
            case SQL.fetchAll r of
              h::_ => h
            | _ => raise REF_NODE_NOT_FOUND sym
      in
        nodeOfDefSym defSym
      end

  fun refsOfDef (REF _)  = nil
    | refsOfDef node = 
      let
        val {fileId, startPos, endPos, symbol} = symOfNode node
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #r.category as category,
              #r.defRangeEndPos as defRangeEndPos,
              #r.defRangeFileId as defRangeFileId,
              #r.defRangeStartPos as defRangeStartPos,
              #r.defSymbol as defSymbol,
              #r.defSymbolEndPos as defSymbolEndPos,
              #r.defSymbolFileId as defSymbolFileId,
              #r.defSymbolStartPos as defSymbolStartPos,
              #r.definedSymbol as definedSymbol,
              #r.internalId as internalId,
              #r.kind as kind,
              #r.sourceFileId as sourceFileId,
              #r.tfunKind as tfunKind,
              #r.refSymbolFileId as refSymbolFileId,
              #r.refSymbol as refSymbol,
              #r.refSymbolStartPos as refSymbolStartPos,
              #r.refSymbolEndPos as refSymbolEndPos
            from 
              #db.refTable as r
            where
            ((#r.defSymbol = symbol and
              #r.defSymbolFileId = fileId) and
              #r.defSymbolStartPos = startPos)
            order by #.refSymbolStartPos
           )
	     (Config.getConn ())
        val refTuples = SQL.fetchAll r
      in
        map refTupleToNode refTuples
      end

  val symSet = ref SymSet.empty : SymSet.set ref
  fun visited node = 
      SymSet.member(!symSet, symOfNode node)
  fun regSym node =
      symSet := SymSet.add(!symSet, symOfNode node)
  fun makeTree node = 
      if visited node then VISITED (symOfNode node)
      else
        (regSym node;
         case node of
           REF {sym, def,...} => 
           let
             val defNode = nodeOfDefSym def
             val parentNodes = findParents node
             val (p1, p2) =
                 foldl
                   (fn (sym as DEF {kind, ...},(p1, p2)) =>
                       (case kind of 
                          VAR _ => (sym :: p1, p2)
                        | FUNCTION _ => (sym :: p1, p2)
                        | _ => (p1, sym::p2))
                     | ( _, x) => x
                   )
                   (nil,nil)
                   parentNodes
             val parentTrees = map makeTree p1
           in
             REF_NODE {node = node,
                       def = defNode,
                       parentNodes = p2,
                       parentTrees = parentTrees
                      }
           end
         | DEF {sym, kind, range} =>
           let
             val refNodeList = refsOfDef node
             val refTrees = map makeTree refNodeList
             val containRefs = findRefsInDef node
             val containRefTrees = map makeTree containRefs
             val parentNodes = findParents node
           in
             DEF_NODE {node = node,
                       containRefs = containRefTrees,
                       parents = parentNodes,
                       refs = refTrees}
           end
         | INT {sym, kind, range} =>
           let
             val defNode = defOfRef node
             val refNodeList = refsOfDef node
             val refTrees = map makeTree refNodeList
           in
             INT_NODE {node = node, 
                       def = defNode,
                       refs = refTrees}
           end
        )
  val makeTree = fn node => (symSet := SymSet.empty; makeTree node)

(*
  fun makeNodeTreeRef sym = 
      let
        val node = 
  val defSymMap =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.kind as kind,
               #d.sourceFileId as sourceFileId,
               #d.category as category,
               #d.defSymbol as defSymbol,
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.defRangeFileId as defRangeFileId,
               #d.defRangeStartPos as defRangeStartPos,
               #d.defRangeEndPos as defRangeEndPos,
               #d.definedSymbol as definedSymbol,
               #d.internalId as internalId,
               #d.tfunKind as tfunKind
            from 
              #db.defTable as d
           )
	     (Config.getConn ())
        fun insert symMap =
            case SQL.fetch r of 
              NONE => symMap
            | SOME tuple => 
              let
                val sym = {fileId = #defSymbolFileId tuple,
                           startPos = #defSymbolStartPos tuple,
                           endPos = #defSymbolEndPos tuple,
                           symbol = #defSymbol tuple}
                val defInfo = RefTypes.defTupleToDefInfo tuple
                val symMap = 
                    SymMap.insert(symMap, sym, defInfo)
              in
                insert symMap
              end
      in
        insert SymMap.empty
      end
 fun findDefInfo sym  =
     case SymMap.find(defSymMap, sym) of
       SOME x => x
     | _ => 
       (print "defInfo not found:\n";
        Dynamic.pp sym;
        raise DEFINFO_NOT_FOUND sym)
  val refSymMap =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #r.category as category,
              #r.defRangeEndPos as defRangeEndPos,
              #r.defRangeFileId as defRangeFileId,
              #r.defRangeStartPos as defRangeStartPos,
              #r.defSymbol as defSymbol,
              #r.defSymbolEndPos as defSymbolEndPos,
              #r.defSymbolFileId as defSymbolFileId,
              #r.defSymbolStartPos as defSymbolStartPos,
              #r.definedSymbol as definedSymbol,
              #r.internalId as internalId,
              #r.kind as kind,
              #r.refSymbol as refSymbol,
              #r.refSymbolEndPos as refSymbolEndPos,
              #r.refSymbolFileId as refSymbolFileId,
              #r.refSymbolStartPos as refSymbolStartPos,
              #r.sourceFileId as sourceFileId,
              #r.tfunKind as tfunKind
            from 
              #db.refTable as r
           )
	     (Config.getConn ())
        fun insert refSymMap =
            case SQL.fetch r of 
              NONE => refSymMap
            | SOME tuple => 
              let
                val sym = {fileId = #refSymbolFileId tuple,
                           startPos = #refSymbolStartPos tuple,
                           endPos = #refSymbolEndPos tuple,
                           symbol = #refSymbol tuple}
                val refInfo = RefTypes.refTupleToRefInfo tuple
                val refSymMap = 
                    SymMap.insert(refSymMap, sym, refInfo)
              in
                insert refSymMap
              end
      in
        insert SymMap.empty
      end
 fun findRefInfo sym  =
     case SymMap.find(refSymMap, sym) of
       SOME x => x
     | _ => 
       (print "defInfo not found:\n";
        Dynamic.pp sym;
        raise REFINFO_NOT_FOUND sym)
*)
end
