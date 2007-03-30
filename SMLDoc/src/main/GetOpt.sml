(**
 * @author (c) 1998 Bell Labs, Lucent Technologies.
 * @version $Id: GetOpt.sml,v 1.1 2007/02/18 03:08:59 kiyoshiy Exp $
 *)
structure GetOpt :> GETOPT = 
    struct

        datatype 'a arg_order = RequireOrder
                              | Permute
                              | ReturnInOrder of string -> 'a

        datatype 'a arg_descr = NoArg of 'a
                              | ReqArg of (string -> 'a) * string
                              | OptArg of (string option -> 'a) * string

        type 'a opt_descr = {short : string,
                             long : string list,
                             desc : 'a arg_descr,
                             help : string}
            
        datatype 'a opt_kind = Opt of 'a
                             | NonOpt of string
                             | EndOfOpts
                             | OptErr of string


        (* Some helper functions to help the transition from the Haskell code
         *)

        fun unlines [] = ""
          | unlines (x::xs) = concat [x,"\n",(unlines xs)]

        fun unzip3 [] = ([],[],[])
          | unzip3 ((a,b,c)::xs) = let val (as',bs,cs) = unzip3 xs
                                   in
                                       (a::as',b::bs,c::cs)
                                   end
        fun zipWith3 (_,[],[],[]) = []
          | zipWith3 (f,a::as',b::bs,c::cs) = 
                          (f(a,b,c))::(zipWith3 (f,as',bs,cs))
                          
        fun sepBy (_,[]) = ""
          | sepBy (_,[x]) = x
          | sepBy (sep,x::xs) = concat [x,sep,sepBy (sep,xs)]

        fun breakeq str = let val (x::xs) = String.tokens (fn x => x = #"=") str
                            in
                                case xs 
                                  of [] => (x,"")
                                   | _ => (x,concat ("="::xs))
                            end


        (* formatting of options
         *)
            
        fun fmtShort (NoArg _) so = concat ["-",Char.toString so]
          | fmtShort (ReqArg (_,ad)) so = concat ["-",Char.toString so," ",ad]
          | fmtShort (OptArg (_,ad)) so = concat ["-",Char.toString so,"[",ad,"]"]

        fun fmtLong (NoArg _) lo = concat ["--",lo]
          | fmtLong (ReqArg (_,ad)) lo = concat ["--",lo,"=",ad]
          | fmtLong (OptArg (_,ad)) lo = concat ["--",lo,"[=",ad,"]"]

        fun fmtOpt {short=sos, long=los, desc=ad, help=descr} = 
               (sepBy (", ",map (fmtShort ad) (String.explode sos)),
                sepBy (", ",map (fmtLong ad) los),
                descr)


        (* Usage information
         *)

        fun paste (x,y,z) = concat ["  ",x,"  ",y,"  ",z]

        fun repeat (0,str) = ""
          | repeat (n,str) = str^(repeat(n-1,str))

        fun flushLeft (n,[]) = []
          | flushLeft (n,x::xs) = (String.extract (x^(repeat (n," ")),0,
                                                   SOME n))::
                                       (flushLeft (n,xs))

        fun maximum l = let fun max ([],l) = l
                              | max (x::xs,l) = if (l > x)
                                                    then max(xs,l)
                                                else max (xs,x)
                        in
                            max (l,0)
                        end

        fun sameLen xs = flushLeft ((maximum o (map size)) xs,xs)

        fun usageInfo header optDescr = 
            let val (ss,ls,ds) = (unzip3 o (map fmtOpt)) optDescr
(*
                val table = zipWith3 (paste,sameLen ss,sameLen ls,sameLen ds)
*)
                val table = zipWith3 (paste,sameLen ss,sameLen ls, ds)
            in
                unlines (header::table)
            end


        (* Some error handling functions
         *)

        fun errAmbig ods optStr =
            let val header = concat ["option `",optStr,"' is ambiguous; could be one of:"]
            in
                OptErr (usageInfo header ods)
            end

        fun errReq d optStr = OptErr (concat ["option `",optStr,"' requires an argument ",d,"\n"])

        fun errUnrec optStr = OptErr (concat ["unrecognized option `",optStr,"'\n"])

        fun errNoArg optStr = OptErr (concat ["option `",optStr,"' doesn't allow an argument\n"])


        (* handle long option
         *)

        fun longOpt xs rest optDescr = 
            let val (opt,arg) = breakeq xs
(*
                val options = List.filter (fn {long,...} =>
                                                List.exists (fn x => String.isPrefix opt x) long)
                                          optDescr
*)
                val options = List.filter (fn {long,...} =>
                                                List.exists (fn x => opt = x) long)
                                          optDescr
                val ads = map (fn {desc,...} => desc) options
                val optStr = "--"^opt
                fun long (_::(_::_)) _ rest1 = (errAmbig options optStr, rest1)
                  | long [NoArg a] "" rest1 = (Opt a,rest1)
                  | long [NoArg _] x rest1 = if (String.isPrefix "=" x)
                                                 then (errNoArg optStr,rest1)
                                             else raise Fail "long: impossible"
                  | long [ReqArg (_,d)] "" [] = (errReq d optStr,[])
                  | long [ReqArg (f,_)] "" (r::rest1) = (Opt (f r),rest1)
                  | long [ReqArg (f,_)] x rest1 = if (String.isPrefix "=" x)
                                                      then (Opt (f (String.extract (x,1,NONE))),
                                                            rest1)
                                                  else raise Fail "long: impossible"
                  | long [OptArg (f,_)] "" rest1 = (Opt (f NONE),rest1)
                  | long [OptArg (f,_)] x rest1 = if (String.isPrefix "=" x)
                                                      then (Opt (f (SOME (String.extract (x,1,NONE)))),
                                                            rest1)
                                                  else raise Fail "long: impossible"
(*                   | long [_] _ _ = raise Fail "long: impossible"*)
                  | long [] _ rest1 = (errUnrec optStr,rest1)
            in
                long ads arg rest
            end



        (* handle short option
         *)

        fun shortOpt x xs rest optDescr = 
            let val options = List.filter (fn {short,...} => 
                                                 List.exists (fn s => s = x) (String.explode short)) 
                                          optDescr
                val ads = map (fn {desc,...} => desc) options
                val optStr = "-"^(Char.toString x)
                fun short (_::_::_) _ rest1 = (errAmbig options optStr,rest1)
                  | short ((NoArg a)::_) "" rest1 = (Opt a,rest1)
                  | short ((NoArg a)::_) ys rest1 = (Opt a,("-"^ys)::rest1)
                  | short ((ReqArg (_,d))::_) "" [] = (errReq d optStr,[])
                  | short ((ReqArg (f,_))::_) "" (r::rest1) = (Opt (f r), rest1)
                  | short ((ReqArg (f,_))::_) ys rest1 = (Opt (f ys), rest1)
                  | short ((OptArg (f,_))::_) "" rest1 = (Opt (f NONE),rest1)
                  | short ((OptArg (f,_))::_) ys rest1 = (Opt (f (SOME ys)),rest1)
                  | short [] "" rest1 = (errUnrec optStr,rest1)
                  | short [] ys rest1 = (errUnrec optStr,("-"^ys)::rest1)
            in
                short ads xs rest
            end


        (* take a look at the next command line argument and decide what to
         * do with it
         *)

        fun getNext [] _ = raise Fail "getNext: impossible"
          | getNext (x::rest) optDescr = 
            if (x="--")
                then (EndOfOpts,rest)
            else if (String.isPrefix "--" x)
                     then longOpt (String.extract (x,2,NONE)) rest optDescr
                 else if (String.isPrefix "-" x)
                          then shortOpt (String.sub (x,1)) (String.extract (x,2,NONE)) rest optDescr
                      else (NonOpt x,rest)


        (* entry point of the library
         *)

        fun getOpt _ _ [] = ([],[],[])
          | getOpt ordering optDescr args = 
            let val (opt,rest) = getNext args optDescr
                val (os,xs,es) = getOpt ordering optDescr rest
                fun procNextOpt (Opt o') _ = (o'::os,xs,es)
                  | procNextOpt (NonOpt x) RequireOrder = ([],x::rest,[])
                  | procNextOpt (NonOpt x) Permute = (os,x::xs,es)
                  | procNextOpt (NonOpt x) (ReturnInOrder f) = ((f x)::os,xs,es)
                  | procNextOpt EndOfOpts RequireOrder = ([],rest,[])
                  | procNextOpt EndOfOpts Permute = ([],rest,[])
                  | procNextOpt EndOfOpts (ReturnInOrder f) = (map f rest,[],[])
                  | procNextOpt (OptErr e) _ = (os,xs,e::es)
            in
                procNextOpt opt ordering
            end

    end
