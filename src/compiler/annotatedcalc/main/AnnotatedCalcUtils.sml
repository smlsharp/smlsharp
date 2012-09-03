(**
 * AnnotatedCalc utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)

structure AnnotatedCalcUtils : ANNOTATEDCALCUTILS = struct

  structure AT = AnnotatedTypes
  open AnnotatedCalc


  val numericalLabelLength = 2

  fun convertNumericalLabel i =
      let
        fun pad 0 = ""
          | pad n = "0" ^ (pad (n - 1))
        val s = Int.toString i
        val n = String.size s
      in
        if n > numericalLabelLength
        then raise Control.Bug "record index is too big"
        else "$" ^ (pad (numericalLabelLength - n)) ^ s
      end

  fun convertLabel label = 
      case Int.fromString label of
        SOME i => convertNumericalLabel i
      | _ => label 

  fun newVar ty = 
      let
        val id = ID.generate()
      in
        {id = id, displayName = "$" ^ ID.toString id, ty = ty}
      end


end
