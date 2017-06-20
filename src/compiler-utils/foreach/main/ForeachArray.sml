structure ForeachArray =
struct
  fun ForeachArray data iterator pred =
      ForeachCommon.foreach
        {from = data,
         iterator = iterator,
         pred = pred}
end
