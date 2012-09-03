fun matrixMult (x,y,z,l,k,n) =
  let
    fun refx (i,j) = i + j 
    fun refy (i,j) = i - j
    fun setz (i,j) v = i + j + j
    fun genIRow i = 
      let
        fun genJthInIRow j =
          let
            fun prodXiYj (h,a) = 
              if h = l then a
              else prodXiYj (h + 1,a + (refx(i,h) * refy(h,j) * refx(h,j)))
          in
            if j = n then ()
            else  (setz (i,j) (prodXiYj (0,0)); genJthInIRow (j+1))
          end
      in
        if i = k then ()
        else (genJthInIRow 0; genIRow (i + 1))
      end
  in
   genIRow 0; z
  end;
