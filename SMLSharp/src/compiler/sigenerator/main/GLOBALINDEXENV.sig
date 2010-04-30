signature GLOBALINDEXENV = sig

  type arrayIndex = BasicTypes.UInt32
  type offset = BasicTypes.UInt32

  type implementationIndex = {arrayIndex : arrayIndex, offset : offset}

  type globalIndexEnv

  val initialGlobalIndexEnv : globalIndexEnv

  val emptyGlobalIndexEnv : globalIndexEnv

  val findIndex : globalIndexEnv * ExternalVarID.id -> implementationIndex option

  val allocateIndex : globalIndexEnv * ExternalVarID.id * IntermediateLanguage.ty -> 
                      globalIndexEnv * implementationIndex

  val globalBoxedArraySize : BasicTypes.UInt32
  val globalAtomArraySize : BasicTypes.UInt32
  val globalDoubleArraySize : BasicTypes.UInt32

  val startRecordingNewGlobalArrays : unit -> unit
  val getNewGlobalArrayIndexes : unit -> (arrayIndex * IntermediateLanguage.ty) list

  val pu_globalIndexEnv : globalIndexEnv Pickle.pu

end
