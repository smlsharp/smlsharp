(**
 * stack frame allocation.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
signature FRAMEALLOCATION =
sig

  val allocate
      : {
          preOffset: word,    (* pre-offset of a frame *)
          postOffset: word,   (* post-offset of a frame *)
          maxAlign: word,     (* maximum alignment *)
          wordSize: word,     (* number of bytes in a word *)
          tmpReg1: 'reg,      (* temporally register for bitmap calculuation *)
          tmpReg2: 'reg,
          frameBitmap: ('reg,'addr) FrameLayout.frameBitmap list,
          variables: FrameLayout.format VarID.Map.map   (* varID->format *)
        }
        -> ('reg,'addr) FrameLayout.frameLayout

end
