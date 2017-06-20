structure ForeachCommon =
struct

  open Myth

(*
  val m = Mutex.create ()
  fun print x = (Mutex.lock m; TextIO.print x; Mutex.unlock m)
*)

  val cutOff = ref 16
  val _ =
      case Option.map Int.fromString (OS.Process.getEnv "SMLSHARP_CUTOFF") of
        SOME (SOME x) => if x > 0 then () else cutOff := x
      | _ => ()

  type 'a context =
      {
        value : int -> 'a,
        newValue : int -> 'a,
        size : int
      }
  type 'a iterator = int * 'a context -> 'a
  type 'a pred = int * 'a context -> bool

  fun 'a foreach {from, iterator, pred} =
      let
        val numItems = Array.length from

        (* i-th thread have done done[i]-th iteration *)
        val done = Array.array (numItems, 0)

        (* loop must continue up to !maxCount+1 times *)
        val maxCount = ref 0

        fun step id num from to count =
            let
              val nextCount = count + 1
              fun getValue i = Array.sub (from, i) : 'a
              fun getNewValue cur i : 'a =
                  if Array.sub (done, i) = nextCount
                  then Array.sub (to, i)
                  (* if that is the task to be done by myself, do it. *)
                  else if cur <= i andalso i < id + num
                  then let val v = iterator (i, context i)
                       in Array.update (to, i, v);
                          Array.update (done, i, nextCount);
                          v
                       end
                  (* otherwise, yield control to other threads and try again *)
                  else (Thread.yield (); getNewValue cur i)
              and context cur =
                  {value = getValue,
                   newValue = getNewValue cur,
                   size = numItems}
              fun body i =
                  if i >= id + num then ()
                  else if Array.sub (done, i) = nextCount
                  then body (i + 1)
                  else (Array.update (to, i, iterator (i, context i));
                        Array.update (done, i, nextCount);
                        body (i + 1))
              fun post i =
                  if i >= num then ()
                  else if pred (i, context ~1) then maxCount := nextCount
                  else post (i + 1)
            in
              (* ToDo: what to do if an exception is raised *)
              (body id;
               if !maxCount >= nextCount then () else post id)
              handle _ => ()
            end

        fun start id num from to count =
            if num <= !cutOff
            then (step id num from to count; 0)
            else
              let
                val m = Int.quot (num, 2)
                val n = num - m
                val t1 = Thread.create (fn () => start id m from to count)
                val t2 = Thread.create (fn () => start (id+m) n from to count)
              in
                Thread.join t1;
                Thread.join t2;
                0
              end

        fun mainLoop from to count =
            (start 0 numItems from to count;
             if !maxCount > count
             then mainLoop to from (count + 1)
             else to)

        val to = SMLSharp_Builtin.Array.alloc numItems
      in
        start 0 numItems from to 0;
        if !maxCount > 0
        then mainLoop to (SMLSharp_Builtin.Array.alloc numItems) 1
        else to
      end

end
