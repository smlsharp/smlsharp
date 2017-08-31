structure DataParallelDict =
struct
  datatype 'a LIST 
    = NIL
    | CONS of {head:'a, tail:index}

  val toIndex = Foreach.intToIndex
  val toInt = Foreach.indexToInt

  fun initialize toLIST L =
      case L of
        nil => toLIST NIL
      | (head::tail) => 
        let
          val TAIL = initialize toLIST tail 
        in
          toLIST (CONS {head = head, tail = TAIL})
        end

  fun initialize (K: index -> index) toLIST L =
      case L of
        nil => K (toLIST NIL)
      | h :: tail => 
        let
          val newK = fn i => K (toLIST (CONS {head=h, tail=i}))
        in
          initialize newK toLIST tail
        end
   val initialize = fn X => initialize (fn (x:index) => x) X

  fun initialize toLIST L =
      case L of
        nil => toLIST NIL
      | (head::tail) =>
        let
          val TAIL = Myth.Thread.create (fn () => toInt (initialize toLIST tail))
        in
          toLIST (CONS {head = head, tail = toIndex (Myth.Thread.join TAIL)})
        end


  fun finalize value =
      let
        fun conv i = 
            case value i of
              NIL => nil
            | CONS{head, tail} => head :: conv tail
      in
        conv
      end
  val whereParam = 
      {size = fn L => List.length L + 1,
       initialize = initialize,
       default = NIL,
       finalize = finalize}
  fun pmapWithPred f p L = 
     _foreach id in L where whereParam
     with context
     do case (#value context id) of
          NIL => NIL
        | CONS {head, tail} => CONS {head = f head, tail=tail}
     while p (id, context)
     end 
  fun makeDict (L : (''a * 'b) list) =
    let
      val keyVar = MVar.new () : ''a MVar.mvar
      val foundVar = MVar.new () : 'b option MVar.mvar
      val foundFlag = ref false
      fun find (key:''a) : 'b option = 
          let
            val _ = MVar.put (keyVar, key)
          in
            MVar.take foundVar
          end 
      fun findKey (s,v) =
          let
            val key = MVar.read keyVar 
            val _ = 
                if s = key then 
                  (MVar.put (foundVar, SOME v);
                   foundFlag := true)
                else ()
          in
            (s,v)
          end
      fun pred (id, context) = 
          let
            val _ = 
                if id = Foreach.rootIndex then
                  if !foundFlag then 
                    (MVar.take keyVar;
                     foundFlag := false;
                     ())
                  else (MVar.take keyVar;
                        MVar.put (foundVar, NONE)
                       )
                else ()
          in
            true (* continue forevar *)
          end
      val dict = 
          Myth.Thread.spawn (fn () => (pmapWithPred findKey pred L;()))
  in
    {find=find, dict = dict}
  end
end
fun mkList 0 L =  L | mkList n L = mkList (n - 1) ((n,n)::L);
fun test n = DataParallelDict.makeDict (mkList n nil);

(*
val {find, dict} = test 100000
val x = find 1
val y = find 2
val z = find 3
*)
