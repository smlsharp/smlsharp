structure DataAnalysis =
struct
  fun listFiles () =
      let
        val files = BasicData.fileList ()
        val fileNames = map #fileName files
        val fileNameListList = 
            map (String.tokens (fn x => x = #"/")) fileNames
        val nestedFileNames = NestedMap.mkNest fileNameListList
        val string = NestedMap.nestToString nestedFileNames
      in
        (nestedFileNames, string)
      end
end
