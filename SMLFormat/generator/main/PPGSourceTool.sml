(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
(*functor PPGSourceFun (structure CM : COMPILATION_MANAGER) =*)
structure PPGSourceTool =
struct

  local
    structure Tools = CM.Tools

    fun getTargetFile source = source ^ ".sml"

    fun simplerule source = [(getTargetFile source, SOME "sml")]

    val validator = Tools.stdTStampValidator

    fun processor {source, targets} =
        PPGMain.main source (getTargetFile source)

    (* install BetterPPG class *)
    val class = "ppg"
  in
    val _ = Tools.addToolClass
            {
              class = class,
              rule = Tools.dontcare simplerule,
              validator = validator,
              processor = processor
            }
    val _ = Tools.addClassifier
                (Tools.stdSfxClassifier {sfx = "ppg", class = class})
  end

end
