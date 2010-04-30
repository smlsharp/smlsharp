signature INLINE = sig
  val doInlining : 
    InlineEnv.globalInlineEnv
    -> Counters.stamps
       -> MultipleValueCalc.topBlock list
          -> InlineEnv.globalInlineEnv * Counters.stamps * MultipleValueCalc.topBlock list
end
