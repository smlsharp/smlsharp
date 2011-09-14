signature GLOBALINDEXENV = sig

  type globalIndexEnv
  type globalIndexAllocator

  val emptyGlobalIndexEnv : globalIndexEnv
  val extendGlobalIndexEnv : globalIndexEnv * globalIndexEnv -> globalIndexEnv

  (* takes current counter and environment and returns an allocator. *)
  val initGlobalIndexAllocator
      : globalIndexEnv -> globalIndexAllocator

  (* save the current counter and deconstruct an allocator to
   * newly-introduced environment and new global array indexes. *)
  val finishGlobalIndexAllocator
      : globalIndexAllocator
        -> {newGlobalIndexEnv: globalIndexEnv,
            newGlobalArrayIndexes:
            (GlobalArrayIndexCounter.arrayIndex * IntermediateLanguage.ty) list}

  val findIndex : globalIndexAllocator * ExVarID.id
                  -> GlobalArrayIndexCounter.implementationIndex option

  val allocateIndex
      : globalIndexAllocator * ExVarID.id * IntermediateLanguage.ty -> 
        globalIndexAllocator * GlobalArrayIndexCounter.implementationIndex

  val pu_globalIndexEnv : globalIndexEnv Pickle.pu

end
