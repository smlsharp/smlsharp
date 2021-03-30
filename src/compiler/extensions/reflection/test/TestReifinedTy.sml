 (**
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)
structure TestReifiedTy =
struct
  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test
  exception Fail

  open ReifiedTy

  fun labelMap stringTyList =
      foldl
      (fn ((s, ty), map) => 
          RecordLabel.Map.insert(map, RecordLabel.fromString s, ty))
      RecordLabel.Map.empty
      stringTyList
  
  fun listToSenv list = foldr (fn ((s,v),map) =>SEnv.insert(map, s, v)) SEnv.empty list
  val taglayout1 = TAGGED_RECORD {tagMap = listToSenv [("A", 1), ("B", 2)]}
  val taglayout2 = TAGGED_OR_NULL {tagMap = listToSenv [("A", 1), ("B", 2)], nullName = "C"}
  val taglayout3 =  TAGGED_TAGONLY {tagMap = listToSenv [("A", 1), ("B", 2)]}
  val _ = print (taggedLayoutToString taglayout1 ^ "\n")
  val _ = print (taggedLayoutToString taglayout2 ^ "\n")
  val _ = print (taggedLayoutToString taglayout3 ^ "\n")
  val layout1 = LAYOUT_TAGGED taglayout1
  val layout2 = LAYOUT_TAGGED taglayout2
  val layout3 = LAYOUT_TAGGED taglayout3
  val layout4 = LAYOUT_ARG_OR_NULL {wrap = true}
  val layout5 = LAYOUT_SINGLE_ARG {wrap = false} 
  val layout6 = LAYOUT_CHOICE {falseName = "hoge"}
  val layout7 = LAYOUT_SINGLE
  val _ = print (layoutToString layout1 ^ "\n")
  val _ = print (layoutToString layout2 ^ "\n")
  val _ = print (layoutToString layout3 ^ "\n")
  val _ = print (layoutToString layout4 ^ "\n")
  val _ = print (layoutToString layout5 ^ "\n")
  val _ = print (layoutToString layout6 ^ "\n")
  val _ = print (layoutToString layout7 ^ "\n")

  
  val (stringTy1 as (ty1, sty1)) = (INTERNALty, "internalTy")
  val (stringTy2 as (ty2, sty2)) = (INTty, "int")
  val (stringty3 as (ty3, sty3)) = (INT64ty, "int64")
  val (stringty4 as (ty4, sty4)) = (INTINFty, "intInf")
  val (stringty5 as (ty5, sty5)) = (BOOLty, "bool")
  val (stringty6 as (ty6, sty6)) = (WORDty, "word")
  val (stringty7 as (ty7, sty7)) = (WORD8ty, "word8")
  val (stringty8 as (ty8, sty8)) = (WORD64ty, "word64")
  val (stringty9 as (ty9, sty9)) = (CHARty, "char")
  val (stringty10 as (ty10, sty10)) = (STRINGty, "string")
  val (stringty11 as (ty11, sty11)) = (REALty, "real")
  val (stringty12 as (ty12, sty12)) = (REAL32ty, "real32")
  val (stringty13 as (ty13, sty13)) = (UNITty, "unit")
  val (stringty14 as (ty14, sty14)) = (EXNty, "exn")
  val (stringty15 as (ty15, sty15)) = (PTRty, "ptr")
  val (stringty16 as (ty16, sty16)) = (LISTty ty1, sty1 ^ " list")
  val (stringty17 as (ty17, sty17)) = (LISTty ty2, sty2 ^ " list")
  val (stringty18 as (ty18, sty18)) = (ARRAYty ty1, sty1 ^ " array")
  val (stringty19 as (ty19, sty19)) = (ARRAYty ty16, sty16 ^ " array")
  val (stringty20 as (ty20, sty20)) = (VECTORty ty1, sty1 ^ " vector")
  val (stringty21 as (ty21, sty21)) = (VECTORty ty17, sty17 ^ " vector")
  val (stringty22 as (ty22, sty22)) = (OPTIONty ty1, sty1 ^ " option")
  val (stringty23 as (ty23, sty23)) = (OPTIONty ty18, sty18 ^ " option")
  val (stringty24 as (ty24, sty24)) = 
      (RECORDty (labelMap [("a", ty1), ("b", ty2), ("c", ty3)]),
       "{a:" ^ sty1 ^ ", b:" ^ sty2 ^ ", c:" ^ sty3 ^ "}"
      )

  val dataStringTy = 
      [
       (sty1, ty1),
       (sty2, ty2),
       (sty3, ty3),
       (sty4, ty4),
       (sty5, ty5),
       (sty6, ty6),
       (sty7, ty7),
       (sty8, ty8),
       (sty9, ty9),
       (sty10, ty10),
       (sty11, ty11),
       (sty12, ty12),
       (sty13, ty13),
       (sty14, ty14),
       (sty15, ty15),
       (sty16, ty16),
       (sty17, ty17),
       (sty18, ty18),
       (sty19, ty19),
       (sty20, ty20),
       (sty21, ty21),
       (sty22, ty22),
       (sty23, ty23),
       (sty24, ty24)
      ]

  val dataTyTy = 
      foldr
        (fn ((sty, ty), dataTyTy) => (ty, ty)::dataTyTy)
        nil
        dataStringTy

  val dataStringTyOpt = 
      [
       (sty1, SOME ty1),
       ("con1", NONE),
       (sty2, SOME ty2),
       ("con2", NONE),
       (sty3, SOME ty3),
       ("con3", NONE),
       (sty4, SOME ty4),
       ("con4", NONE),
       (sty5, SOME ty5),
       ("con5", NONE),
       (sty6, SOME ty6),
       ("con6", NONE),
       (sty7, SOME ty7),
       ("con7", NONE),
       (sty8, SOME ty8),
       ("con8", NONE),
       (sty9, SOME ty9),
       ("con9", NONE),
       (sty10, SOME ty10),
       ("con10", NONE),
       (sty11, SOME ty11),
       ("con11", NONE),
       (sty12, SOME ty12),
       ("con12", NONE),
       (sty13, SOME ty13),
       ("con13", NONE),
       (sty14, SOME ty14),
       ("con14", NONE),
       (sty15, SOME ty15),
       ("con15", NONE),
       (sty16, SOME ty16),
       ("con16", NONE),
       (sty17, SOME ty17),
       ("con17", NONE),
       (sty18, SOME ty18),
       ("con18", NONE),
       (sty19, SOME ty19),
       ("con19", NONE),
       (sty20, SOME ty20),
       ("con20", NONE),
       (sty21, SOME ty21),
       ("con21", NONE),
       (sty22, SOME ty22),
       ("con22", NONE),
       (sty23, SOME ty23),
       ("con23", NONE),
       (sty24, SOME ty24),
       ("con24", NONE)
      ]

  val dataStringTyOptList =
      let
        val dataStringTyOpt = List.take (dataStringTyOpt, 15)
        fun take1 nil = nil 
          | take1 [a] = [[a]]
          | take1 (h::tail) = [h]::take1 tail
        fun take2 nil = nil
          | take2 [a] = nil
          | take2 [a,b] = [[a,b]]
          | take2 (h1::h2::tail) = [h1,h2] :: take2 (h2::tail)
        fun take3 nil = nil
          | take3 [a] = nil
          | take3 [a,b] = nil
          | take3 [a,b,c] = [[a,b,c]]
          | take3 (h1::h2::h3::tail) = [h1,h2,h3] :: take3 (h2::tail)
        fun take l = foldr (fn (f, list) => f dataStringTyOpt @ list) nil l
      in
        take [take1, take2, take3]
      end

  val dataConSet = map mkConSet dataStringTyOptList
(*
  val _ = map (fn conSet => (print (conSetToString conSet);
                             print "\n")
              )
          dataConSet
*)
  val dataConSetConSet = map (fn x => (x,x)) dataConSet

  val dataStringConSet =
      let
        val stringList =
            [
             "(internalTy of internalTy)",
             "(con1)",
             "(int of int)",
             "(con2)",
             "(int64 of int64)",
             "(con3)",
             "(intInf of intInf)",
             "(con4)",
             "(bool of bool)",
             "(con5)",
             "(word of word)",
             "(con6)",
             "(word8 of word8)",
             "(con7)",
             "(word64 of word64)",
             "(con1, internalTy of internalTy)",
             "(con1, int of int)",
             "(con2, int of int)",
             "(con2, int64 of int64)",
             "(con3, int64 of int64)",
             "(con3, intInf of intInf)",
             "(con4, intInf of intInf)",
             "(bool of bool, con4)",
             "(bool of bool, con5)",
             "(con5, word of word)",
             "(con6, word of word)",
             "(con6, word8 of word8)",
             "(con7, word8 of word8)",
             "(con7, word64 of word64)",
             "(con1, int of int, internalTy of internalTy)",
             "(con1, con2, int64 of int64)",
             "(con2, con3, intInf of intInf)",
             "(bool of bool, con3, con4)",
             "(con4, con5, word of word)",
             "(con5, con6, word8 of word8)",
             "(con6, con7, word64 of word64)"
            ]
      in
        ListPair.zip (stringList, dataConSet)
      end
  val dataTypId = 
      let
        fun mkId 0 idList = idList
          | mkId n idList = mkId (n - 1) (TypID.generate() :: idList)
      in
        rev (mkId (length dataConSet) nil)
      end
  val dataTypIdConSet = ListPair.zip (dataTypId, dataConSet)
  val dataConSetEnv = 
      foldl
      (fn ((id,conSet), L) =>
          insertConSet(emptyConSetEnv, id, conSet) 
          :: (map (fn env => insertConSet(env,id, conSet)) L))
      nil
      (rev dataTypIdConSet)
  val dataTypIdConSetPreFixList = ListUtils.prefixList dataTypIdConSet
  val dataTypIdConSetListConSetEnv =
      ListPair.zip (dataTypIdConSetPreFixList, dataConSetEnv)
  fun testReifiedTyToString () =
      let 
        fun assert (string, ty) = 
            Test.TestCase (fn () => Assert.assertEqualString string (reifiedTyToString ty))
      in Test.TestList (map assert dataStringTy)
      end

   fun testReifiedTyEq () =
      let fun assert1 arg = 
              Test.TestCase (fn () => Assert.assertEqualBool true (reifiedTyEq arg))
          fun assert2 (ty1, ty2) =
              Test.TestCase (fn () => assertEqualReifiedTy ty1 ty2)
      in Test.TestList (map assert1 dataTyTy @ map assert2 dataTyTy)
      end

  fun testConSetToString () =
      let fun assert (string, conSet) = 
              Test.TestCase (fn () => Assert.assertEqualString string (conSetToString conSet))
      in  Test.TestList (map assert dataStringConSet)
      end
  fun testConSetEq () =
      let fun assert1 arg = 
              Test.TestCase (fn () => Assert.assertEqualBool true (conSetEq arg))
          fun assert2 (conSet1, conSet2) =
             Test.TestCase (fn () => assertEqualConSet conSet1 conSet2)
      in Test.TestList (map assert1 dataConSetConSet @ map assert2 dataConSetConSet)
      end

  fun testConSetEnv () = 
      let fun assert1 conSetEnv (id, conSet) =
              Test.TestCase (fn () => assertEqualConSet conSet conSet)
          fun assert2 conSetEnv (id, conSet) =
              Test.TestCase (fn () => assertEqualConSetEnv conSetEnv conSetEnv)
          fun assert3 conSetEnv (id, conSet) =
              Test.TestCase 
                (fn () => 
                    assertEqualConSet 
                      conSet 
                      (lookUpConSet(conSetEnv, id)
                       handle ConSetNotFound => 
                              (print "ConSetNotFound\n";
                               print "id:"; print (TypID.toString id);
                               print "\nconSetEnv:"; print (conSetEnvToString conSetEnv);
                               print "\n";
                               raise ConSetNotFound
                              )
                      )
                )
          fun assert (TypIDConSetList, conSetEnv) =
              map (assert1 conSetEnv) TypIDConSetList
              @ map (assert2 conSetEnv) TypIDConSetList
              @ map (assert3 conSetEnv) TypIDConSetList
      in Test.TestList (List.concat (map assert dataTypIdConSetListConSetEnv))
      end

  fun testGlobalConSetEnv () =
      let
        fun assert (TypIDConSetList, conSetEnv) =
            let
              val _ = resetGlobalConSetEnv ()
              val tests =
                  map
                    (fn (id, conSet) =>
                        Test.TestCase 
                          (fn () => 
                              ((findConSet id;()) handle ConSetNotFound =>();
                               setConSet (id, conSet);
                               assertEqualConSet 
                                 conSet
                                 (valOf (findConSet id)
                                  handle x => 
                                         (print "====ConSetNotFound====\n";
                                          print "id:"; print (TypID.toString id);
                                          print "\nconSetEnv:"; print (conSetEnvToString (getGlobalConSetEnv()));
                                          print "\n";
                                          raise ConSetNotFound
                                         )
                                 )
                              )
                          )
                    )
                  TypIDConSetList
              val lastTest = 
                  Test.TestCase 
                  (fn () => assertEqualConSetEnv conSetEnv (getGlobalConSetEnv ()))
            in
              tests @ [lastTest]
            end
      in Test.TestList (List.concat (map assert dataTypIdConSetListConSetEnv))
      end

  val dataTy =
      let
        val _ = resetGlobalConSetEnv ()
        val dataTyConSetList =
            map (fn (id, conSet) =>
                    (mkDatatype (TypID.toString id, id, conSet, nil), conSet))
                dataTypIdConSet
        val conSetEnv = getGlobalConSetEnv()
      in
        map (fn (dty, conSet) => ({conSetEnv = conSetEnv, reifiedTy = dty}, conSet))
            dataTyConSetList
      end

  fun testTy () =
      let
        fun assert (ty, conSet) = 
            Test.TestCase 
            (fn () => 
                assertEqualConSet 
                  conSet
                  (case getConstructTy ty of
                     {reifiedTy = CONSTRUCTty {longsymbol, conSet, ...}, ...} =>
                     conSet
                   | _ => raise Fail
                  )
            )
      in Test.TestList (map assert dataTy)
      end

  val _ = resetGlobalConSetEnv ()
  val listTyId = TypID.generate()

  fun suite () =
      Test.TestList
      [
       Test.TestLabel ("reifiedTyToString", testReifiedTyToString ()),
       Test.TestLabel ("reifiedTyEq", testReifiedTyEq ()),
       Test.TestLabel ("conSetToString", testConSetToString ()),
       Test.TestLabel ("conSetEq", testConSetEq ()),
       Test.TestLabel ("conSetEnv", testConSetEnv ()),
       Test.TestLabel ("globalConSetEnv", testGlobalConSetEnv()),
       Test.TestLabel ("ty", testTy())
      ]
end

