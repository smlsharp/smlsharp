structure FileSymbolOrd =
struct
  type ord_key = FileID.id * Symbol.symbol
  fun compare ((fid1, s1),(fid2, s2))  = 
      case FileID.Map.Key.compare (fid1,fid2) of
        EQUAL => Symbol.compare(s1, s2)
      | x => x
end

structure FileSymbolMap = BinaryMapFn(FileSymbolOrd)
