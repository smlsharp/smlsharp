fun f () =
    (00, 01, 02, 03, 04, 05, 06, 07, 08, 09,
     10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
     20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
     30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
     40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
     50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
     60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
     70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
     80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
     90, 91, 92, 93, 94, 95, 96, 97, 98, 99)

(*
2011-12-01 katsu

This causes BUG at RecordUnboxing.

[BUG] record index is too big
    raised at: ../annotatedtypes/main/AnnotatedTypesUtils.sml:162.20-162.57
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)

(*
2011-12-01 ohori
The following change is made in annotatedtypes/main/AnnotatedTypesUtils.sml:
  (*
  val numericalLabelLength = 2
  *)
  val numericalLabelLength = 5

*)
