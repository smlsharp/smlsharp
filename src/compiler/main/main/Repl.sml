structure Repl = struct

  val memhist:string list ref = ref []

  fun readHistory(s:string) = (
    if(s<>"") then
      let
        val in1 = TextIO.openIn(s)
        fun read(l) =
          case TextIO.inputLine(in1) of
            NONE => l
          | SOME(s) => read(substring(s,0,(size s) - 1)::l)
        val rc = read([])
      in
        TextIO.closeIn(in1);
        rc
      end handle Io => []
    else !memhist
  )

  fun writeHistory(s:string,l) =
    if(s<>"") then
      let
        val out1 = TextIO.openAppend(s)
      in
        TextIO.output(out1, l ^ "\n");
        TextIO.closeOut(out1)
      end handle Io => ()
    else (
      memhist := l :: !memhist
    )

  fun getchar():char = (
    case TextIO.input1(TextIO.stdIn) of
      SOME(c) => c
    |  NONE => getchar()
  )

  fun tstr(str,n) =
  let
    fun f(n,r) = if(n<=0) then r else f(n-1,r ^ str)
  in
    f(n,"")
  end

  fun inputLine(file) =
  let
    fun update(l,n,item) =
    let
      fun f(h,l,i) =
        if i = n then (rev h) @ item::(tl l)
        else f((hd l)::h,(tl l),i+1)
    in
      f([],l,0)
    end

    fun loop(src,p,hs1,h) =
    let
      val hs = update(hs1, h, src)
      fun hist(h) = (
        let
          val src2 = List.nth(hs, h)
          val dellen = (size src) - (size src2)
        in
          print(tstr("\^[[D", p));
          print(src2);
          print(tstr(" ", dellen));
          print(tstr("\^[[D", dellen));
          loop(src2, size src2,hs,h)
        end
      )
    in
      case getchar() of
          #"\n" => (print("\n"); src)
        | #"\t" => loop(src, p, hs, h)
        | #"\^[" => (
          (* escape *)
          getchar();
          case getchar() of
              #"A" => (* up *)
                if(h < length(hs)-1)
                then hist(h+1)
                else loop(src,p,hs,h)
            | #"B" => (* down *)
                if(h > 0)
                then hist(h-1)
                else loop(src,p,hs,h)
            | #"D" => (* left *)
                if (p > 0)
                then (print("\^[[D"); loop(src,p-1,hs,h))
                else loop(src,p,hs,h)
            | #"C" => (* right *)
                if (p < size src)
                then (print("\^[[C"); loop(src,p+1,hs,h))
                else loop(src,p,hs,h)
            | c => (print ("####"^str(c)^"####"); loop(src,p,hs,h))
        )
        | #"\127" => (* delete *)
          if (src <> "" andalso p > 0) then
            (let
              val src1 = substring(src,0,p - 1) 
              val src2len = (size src) - p
              val src2 = substring(src,p,src2len)
            in
              print("\^[[D");
              print(src2 ^ " ");
              print(tstr("\^[[D", src2len + 1));
              loop(src1 ^ src2, p - 1, hs, h)
            end)
          else loop(src,p,hs,h)
        | c => (* insert *)
          let
            val src1 = substring(src,0,p)
            val src2len = (size src) - p
            val src2 = substring(src,p,src2len)
          in
            print(str(c) ^ src2);
            print(tstr("\^[[D", src2len));
            loop(src1 ^ str(c) ^ src2, p + 1, hs, h)
          end
    end
    val _ = OS.Process.system("stty -echo -icanon min 1 time 0");
    val rc = loop("",0,""::readHistory(file),0)
    val _ = writeHistory(file, rc)
    val _ = OS.Process.system("stty echo -icanon min 1 time 0")
  in
    SOME(rc)
  end

  fun homePath(f) = 
    case OS.Process.getEnv("HOME") of
      SOME(e) => e ^ "/" ^ f
      | NONE => ""
end
