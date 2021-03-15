structure RefTrees =
struct
  structure DB = DBSchema

  open RefTypes

  val visited = ref IntIntIntStringSet.empty : IntIntIntStringSet.set ref
  fun isVisited {fileId, startPos, endPos, symbol} =
      IntIntIntStringSet.member(!visited, (fileId, startPos, endPos, symbol))
  fun remove P nil = nil
    | remove P (h::t) = if P h then remove P t else h :: remove P t
  fun unique P nil = nil
    | unique P (h::t) = h :: (remove (P h) t)
  fun eqRefTuple
       ({refSymbolFileId = fileId1, 
         refSymbolStartPos = startPos1, 
         refSymbolEndPos = endPos1, 
         refSymbol = symbol1,...} : refTuple)
       ({refSymbolFileId = fileId2, 
         refSymbolStartPos = startPos2, 
         refSymbolEndPos = endPos2, 
         refSymbol = symbol2,...} : refTuple) =
      fileId1 = fileId2 andalso 
      startPos1 = startPos1 andalso 
      endPos1 = endPos2 andalso 
      symbol1 = symbol2

  fun isStr defInfo =
      case defInfo of
       INTERFACE_STR_DEF _ => true
      | STR_DEF _ => true
      | _ => false

  fun makeUseTree (sym as {fileId, startPos, endPos, symbol}) =
      if isVisited sym then USE_VISITED sym
      else
        let
val _ = Dynamic.pp "makeUseTree"
val _ = Dynamic.pp sym
          val _ = 
              visited := 
              IntIntIntStringSet.add
                (!visited, (fileId, startPos, endPos, symbol))
          val defInfo = defTupleToDefInfo (DBBasics.findDefTuple sym)
          val externalSyms = DBBasics.listDefSymsReferencedInDefSymExternal sym
          val externalTrees = map makeUseTree externalSyms
(*
          val symsLocal = DBBasics.listDefSymsReferencedInDefSymLocal sym
          val localTrees = map makeUseTree symsLocal
*)
        in
          USE_NODE
          { sym = sym,
            defInfo = defInfo,
            localTree = nil,
            externalTree = externalTrees
          }
        end

  fun makeTreeDef (sym as {fileId, startPos, endPos, symbol}) =
      if isVisited sym then VISITED_DEF sym
      else
        let
          val _ = 
              visited := 
              IntIntIntStringSet.add
                (!visited, (fileId, startPos, endPos, symbol))
          val defInfo = defTupleToDefInfo (DBBasics.findDefTuple sym)
          val parentsSyms = DBBasics.findParents sym
          val parentTrees = map makeTreeDef parentsSyms
        in
          if isStr defInfo then 
            DEF_STR {sym = sym, 
                     defInfo = defInfo, 
                     parents = parentTrees}
          else
            let
              val reftuples = DBBasics.findRefTuples sym
              val reftuples = unique eqRefTuple reftuples
              val refTrees = map makeTreeRef reftuples
            in
              DEF_ID {sym = sym, 
                   defInfo = defInfo, 
                   parents = parentTrees, 
                   refs = refTrees}
            end
        end
  and makeTreeRef (refTuple as
                   {refSymbolFileId = fileId, 
                    refSymbolStartPos = startPos, 
                    refSymbolEndPos = endPos, 
                    refSymbol = symbol,...}) =
      let
        val sym = {fileId = fileId, 
                   startPos = startPos, 
                   endPos = endPos,
                   symbol = symbol}
      in
        if isVisited sym then VISITED_REF sym
        else
          let
            val _ = 
                visited := 
                IntIntIntStringSet.add
                  (!visited, (fileId, startPos, endPos, symbol))
            val refInfo = refTupleToRefInfo refTuple
            val parentsSyms = DBBasics.findParents sym
            val parentTrees = map makeTreeDef parentsSyms
          in
            REF {sym = sym, refInfo = refInfo, parents = parentTrees}
          end
      end
  val makeTree =
      fn sym =>
         (visited := IntIntIntStringSet.empty;
          makeTreeDef sym)
  val makeUseTree =
      fn sym =>
         (visited := IntIntIntStringSet.empty;
          makeUseTree sym)
end
