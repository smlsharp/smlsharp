structure SourceOrd =
struct
  type ord_key = InterfaceName.source
  fun compare ((p1,f1), (p2, f2))
      = case String.compare 
               (Dynamic.tagOf p1, Dynamic.tagOf p2) of
          EQUAL => String.compare
                     (Filename.toString f1, Filename.toString f2)
        | x => x
end

structure SourceMap = BinaryMapFn(SourceOrd)
