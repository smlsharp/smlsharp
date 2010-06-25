structure FunIDMap = struct
local
  structure AT = AnnotatedTypes
  open FunIDMapData 
in
  datatype position = MIDDLE | TAIL

  fun call 
     (
      from, 
      position,
      to as {codeStatus = ref AT.LOCAL,...}
      ) = 
     let
       val map = 
         case position of
           TAIL => gotoMap
         | MIDDLE => callMap
     in
       map := 
        (case FidEnv.find (!map, from) of
          NONE => FidEnv.insert(!map, from, FidSet.singleton to)
        | SOME set =>  FidEnv.insert(!map, from, FidSet.add(set, to)))
     end
    | call _ = ()

  fun initialize () = 
    (
     gotoMap := FidEnv.empty;
     callMap := FidEnv.empty 
     )

  (* the transitive closure of R o E *)
  fun TC R EOption =
    let
      val changed = ref true
      (* R => R o (E u I) o R *)
      fun squre R = 
        let
          val changed = ref false
        in
          (FidEnv.map
           (fn Set =>
            let
              (* R(a) => R(a) u  E(R(a)) *)
              val Set = 
                case EOption of
                  NONE => Set
                | SOME E => 
                    FidSet.foldl 
                    (fn (elem, S) =>
                     (case FidEnv.find (E, elem) of
                        SOME set => 
                          if FidSet.isEmpty(FidSet.difference(set, S)) then 
                            S
                          else (changed:= true;
                                FidSet.union(S, set))
                      | NONE => S)
                        )
                    Set
                    Set
            in
              (* S => S u R(S) where S = R(a) u  E(R(a)) *)
              FidSet.foldl 
              (fn (elem, S) =>
               (case FidEnv.find (R, elem) of
                  SOME set => 
                    if FidSet.isEmpty(FidSet.difference(set, S)) then 
                      S
                    else (changed:= true;
                          FidSet.union(S, set))
                | NONE => S
                )
                )
              Set
              Set
            end)
           R,
           !changed)
        end
      fun loop R =
        let
          val (R, changed) = squre R
        in
          if changed then loop R
          else R
        end
    in
      loop R
    end


  fun coereceEscapeFun fidMap = 
    let
      fun owned nil _ = false
        | owned ({ownerId,ownerCode=ref AT.GLOBAL_FUNSTATUS}::tail) id = false
        | owned ({ownerId,ownerCode = ref AT.CLOSURE}::tail) id = id = ownerId 
        | owned ({ownerId,ownerCode = ref AT.LOCAL}::tail) (id:AT.functionId) =
          id = ownerId orelse owned tail id
      fun coerse () =
        let
          val changed = ref false
        in
          (
            FidEnv.appi
            (
              fn (funStatus as {functionId, codeStatus = ref AT.CLOSURE,...}, S) =>
                 FidSet.app 
                 (
                  fn {codeStatus = r as ref AT.LOCAL, owners, ...} => 
                      if owned owners functionId then ()
                      else (r := AT.CLOSURE; changed := true)
                   | _ => ()
                 )
                 S
              | _ => ()
            )
            fidMap;
            !changed
          )
        end
      fun loop () =
        let
          val changed = coerse ()
        in
          if changed then loop ()
          else ()
        end
    in
      loop()
    end

  fun pruneFidMap fidMap =
    FidEnv.map
    (FidSet.filter 
       (fn {codeStatus = ref AT.CLOSURE,...} => false
         | {codeStatus = ref AT.GLOBAL_FUNSTATUS,...} => false
         | {codeStatus = ref AT.LOCAL,...} => true
        )
    )
    fidMap

  fun solve () =
    let
(*
      val _ = print "gotoMap\n"
      val _ = print) (Control.prettyPrint (FunIDMapData.format_funIdMap (!gotoMap))
      val _ = print "\ncallMap\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap (!callMap)))
      val refMap = FidEnv.unionWith (fn (S1,S2) => FidSet.union (S1,S2)) (!gotoMap, !callMap)
      val _ = print "\nrefMap\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap refMap))
      val refMapStar = TC refMap NONE
      val _ = print "\nrefMapStar\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap refMapStar))
      val _ = coereceEscapeFun refMapStar
      val gotoMap = pruneFidMap (!gotoMap)
      val callMap = pruneFidMap (!callMap)
      val _ = print "Pruned gotoMap\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap (gotoMap)))
      val _ = print "\nPruned callMap\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap (callMap)))
      val gotoMapStar = TC gotoMap NONE
      val callMapStar = TC callMap (SOME gotoMapStar)
      val _ = print "\nPruned gotoMapStar\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap (gotoMapStar)))
      val _ = print "\nPruned callMapStar\n"
      val _ = print (Control.prettyPrint (FunIDMapData.format_funIdMap (callMapStar)))
*)
      val refMap = FidEnv.unionWith (fn (S1,S2) => FidSet.union (S1,S2)) (!gotoMap, !callMap)
      val refMapStar = TC refMap NONE
      val _ = coereceEscapeFun refMapStar
      val gotoMap = pruneFidMap (!gotoMap)
      val callMap = pruneFidMap (!callMap)
      val gotoMapStar = TC gotoMap NONE
      val callMapStar = TC callMap (SOME gotoMapStar)
      val _ =
        FidEnv.appi
        (fn (elem as {codeStatus,...}, set) =>
         if FidSet.member(set, elem) then codeStatus := AT.CLOSURE
         else ())
        callMapStar
      val refMap = FidEnv.unionWith (fn (S1,S2) => FidSet.union (S1,S2)) (gotoMap, callMap)
    in
      coereceEscapeFun refMapStar
    end
end
end
