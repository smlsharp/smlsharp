structure DataParallelUtils =
struct
  type stage = int
  val initialStage = 0
  fun next stage = stage + 1
  fun createStage () = ref 0 : stage ref
  fun setNextStage lstage = lstage := next (!lstage)
  fun isNewStage (lstage, gstage) = lstage < gstage

  structure DPBool =
  struct
    fun orTrue (lstage, gstage) = gstage := next (!lstage)
    fun andFalse (lstage, gstage) = gstage := next (!lstage)
    fun isTrue (lstage, gstage) = isNewStage (!lstage, !gstage)
  end

  structure NextValueLock =
  struct
    type id = int
    type nextLock = {mutex: Myth.mutex, cond: Myth.cond}
    fun createNextLock (i:id) : nextLock = 
        {mutex = Myth.Mutex.create(), cond =  Myth.Cond.create()}
    fun destroyNextLocl ({mutex, cond} : nextLock) : unit =
        (Myth.Mutex.destroy mutex; Myth.Cond.destroy cond)
    type 'a context = {getNextLock : id -> nextLock,
                       getStage : id -> stage,
                       setStage : (id * stage) -> unit,
                       setValue : id *'a -> unit,
                       getValue : id -> 'a}
    fun ('a) getMutex (context:'a context) (id:id) = 
        #mutex (#getNextLock context id)
    fun ('a) getCond (context:'a context) (id:id) = 
        #cond (#getNextLock context id)
    fun ('a) getStage (context:'a context) (id:id) = 
        #getStage context id
    fun ('a) getValue (context:'a context) (id:id) = 
        #getValue context id
    fun ('a) lock (context:'a context) (id:id) = 
        Myth.Mutex.lock (getMutex context id)
    fun ('a) unlock (context:'a context) (id:id) = 
        Myth.Mutex.unlock (getMutex context id)
    fun ('a) signal (context:'a context) (id:id) = 
        Myth.Cond.signal (getCond context id)
    fun ('a) broadcast (context:'a context) (id:id) = 
        Myth.Cond.broadcast (getCond context id)
    fun ('a) wait (context:'a context) (id:id) = 
        Myth.Cond.wait (getCond context id, getMutex context id)
    fun ('a) isReady (context:'a context) (lstage:stage ref, id:id) = 
        isNewStage (!lstage, getStage context id)
    fun ('a) putValue (context:'a context) (lstage:stage ref, id:id, v:'a) = 
        (#setValue context (id, v);
         #setStage context (id, next (!lstage)))

    fun ('a) put (context:'a context) (lstage, id, v) =
        let
          val _ = lock context id
          val _ = putValue context (lstage, id, v)
          val _ = broadcast context id
          val _ = unlock context id
        in
          ()
        end

    fun ('a) get (context:'a context) (lstage:stage ref, id:id) =
        let
          fun waitUntilReady () =
              if isReady context (lstage, id) then ()
              else (wait context id; waitUntilReady ())
          val _ = lock context id
          val _ = waitUntilReady ()
          val v = getValue context id
          val _ = unlock context id
        in
          v
        end
  end
end
