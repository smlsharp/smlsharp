(*
 * A wrapper structure to bridge incompatibilities between the Basis
 * implementation of SML/NJ and the Basis which SMLUnit assumes.
 * 
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLUnit =
struct
  open SMLUnit

  structure Assert =
  struct
    open Assert

    structure AssertIEEEReal =
    struct
      open AssertIEEEReal

      val assertEqualFloatClass =
          convertAssertEqual IEEEReal.fromNewClass assertEqualFloatClass
      val assertEqualDecimalApprox =
          convertAssertEqual
              IEEEReal.fromNewDecimalApprox assertEqualDecimalApprox
    end
  end
end