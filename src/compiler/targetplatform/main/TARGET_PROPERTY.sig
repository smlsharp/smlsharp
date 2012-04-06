(**
 * Properties of Target Platform.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: TARGET_PROPERTY.sig,v 1.2 2008/01/23 08:20:07 katsu Exp $
 *)

signature TARGET_PROPERTY =
sig

  include TARGET_PLATFORM

  (* min [C_sizeOfX, ...] *)
  val basicSize : word          (* bytes of 1 word *)

  (* C_sizeOfX / basicSize *)
  val sizeOfInt : word          (* words of 1 int *)
  val sizeOfReal : word         (* words of 1 double *)
  val sizeOfFloat : word        (* words of 1 float *)
  val sizeOfPtr : word          (* words of 1 pointer *)

  (* lcm (C_alignOfX, basicSize) / basicSize *)
  val alignOfInt : word            
  val alignOfReal : word
  val alignOfFloat : word
  val alignOfPtr : word

  (* uniq [sizeOfX, ...] *)
  val sizeVariation : word list
  val alignVariation : word list  (* corresponds to sizeVariation *)

  val maxSize : word    (* max [sizeOfX, ..., alignOfX, ...] *)
  val maxAlign : word   (* lcm [alignOfX, ...] *)


(*
  val maxBlockFields : word    (* maxinum number of fields in 1 block *)
  val nestedBlockIndex : uint  (* index of pointer to nested block *)




  val bitmapSize : word

  val blockHeaderOffset : word
  val maxNumArgsPerBlock : word
  val blockPadding : word
  val maxBlockSize : word
*)



end
