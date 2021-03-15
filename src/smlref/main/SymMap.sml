structure SymOrg =
struct
  type ord_key = {fileId:int, startPos:int, endPos:int, symbol:string}

  fun compare ({fileId=id1, startPos=spos1, endPos=epos1, symbol=s1},
               {fileId=id2, startPos=spos2, endPos=epos2, symbol=s2}) =
      case Int.compare(id1, id2) of
        EQUAL => (case Int.compare(spos1, spos2) of
                    EQUAL => 
                     (case Int.compare (epos1, epos2) of
                        EQUAL => String.compare(s1,s2)
                      | x => x)
                  | x => x)
      | x => x
end

structure SymMap = BinaryMapFn(SymOrg)
structure SymSet = BinarySetFn(SymOrg)

