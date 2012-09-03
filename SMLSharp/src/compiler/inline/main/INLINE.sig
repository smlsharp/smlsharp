signature INLINE = sig
  val doInlining : 
    InlineEnv.globalInlineEnv
    -> MultipleValueCalc.topBlock list
    -> InlineEnv.globalInlineEnv * MultipleValueCalc.topBlock list
end
