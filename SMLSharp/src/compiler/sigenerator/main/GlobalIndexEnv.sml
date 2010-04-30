structure GlobalIndexEnv :> GLOBALINDEXENV = struct

  structure BT = BasicTypes
  structure IL = IntermediateLanguage
  structure P = Pickle
  structure AN = ANormal

  type arrayIndex = BT.UInt32

  type offset = BT.UInt32

  type implementationIndex = {arrayIndex : arrayIndex, offset : offset}

  type globalIndexEnv = 
       {
        nextArrayIndex : arrayIndex,
        lastBoxedIndex : implementationIndex option,
        lastAtomIndex : implementationIndex option,
        lastDoubleIndex : implementationIndex option,
        indexMap : implementationIndex ExternalVarID.Map.map
       }

  structure AIMapPickler = OrdMapPickler(ExternalVarID.Map)

  val pu_arrayIndex = P.word32
  val pu_offset = P.word32
  val pu_implementationIndex = 
      P.conv
          (
           fn (arrayIndex, offset) =>
              {arrayIndex = arrayIndex, offset = offset},
           fn {arrayIndex, offset} =>
              (arrayIndex, offset)
          )
          (P.tuple2(pu_arrayIndex,pu_offset))
  val pu_implementationIndexOpt = P.option pu_implementationIndex
  val pu_indexMap = AIMapPickler.map(ExternalVarID.pu_ID, pu_implementationIndex)
  val pu_globalIndexEnv =
      P.conv
          (
           fn (nextArrayIndex, lastBoxedIndex, lastAtomIndex, lastDoubleIndex, indexMap) =>
              {
               nextArrayIndex = nextArrayIndex,
               lastBoxedIndex = lastBoxedIndex,
               lastAtomIndex = lastAtomIndex,
               lastDoubleIndex = lastDoubleIndex,
               indexMap = indexMap
              },
           fn {nextArrayIndex, lastBoxedIndex, lastAtomIndex, lastDoubleIndex, indexMap} =>
              (nextArrayIndex, lastBoxedIndex, lastAtomIndex, lastDoubleIndex, indexMap)
          )
          (P.tuple5
               (
                pu_arrayIndex, 
                pu_implementationIndexOpt,
                pu_implementationIndexOpt,
                pu_implementationIndexOpt,
                pu_indexMap
               )
          )


  val globalBoxedArraySize = Word32.fromInt 1024
  val globalAtomArraySize = Word32.fromInt 1024
  val globalDoubleArraySize = Word32.fromInt 2048

  val recordedArrayIndexes = ref ([] : (arrayIndex * IL.ty) list) 

  val emptyGlobalIndexEnv =
      {
       nextArrayIndex = 0w0,
       lastBoxedIndex = NONE,
       lastAtomIndex = NONE,
       lastDoubleIndex = NONE,
       indexMap = ExternalVarID.Map.empty
      } : globalIndexEnv

  val initialGlobalIndexEnv = emptyGlobalIndexEnv : globalIndexEnv
      

  fun findIndex ( {indexMap,...} : globalIndexEnv, abstractIndex) =
      ExternalVarID.Map.find(indexMap, abstractIndex)

  fun allocateIndex 
          ({nextArrayIndex, lastBoxedIndex, lastAtomIndex, lastDoubleIndex, indexMap} : globalIndexEnv,
           abstractIndex, ty
          ) =
      case ty of
        AN.ATOM =>
        let
          val (lastAtomIndex, nextArrayIndex) =
              case lastAtomIndex of
                NONE =>
                (
                 recordedArrayIndexes := (!recordedArrayIndexes @ [(nextArrayIndex, AN.ATOM)]);
                 (SOME {arrayIndex = nextArrayIndex, offset = 0w0}, nextArrayIndex + 0w1)
                )
              | SOME {arrayIndex, offset} =>
                if offset + 0w1 < globalAtomArraySize 
                then (SOME {arrayIndex = arrayIndex, offset = offset + 0w1}, nextArrayIndex)
                else 
                  (
                   recordedArrayIndexes := (!recordedArrayIndexes @ [(nextArrayIndex, AN.ATOM)]);
                   (SOME {arrayIndex = nextArrayIndex, offset = 0w0}, nextArrayIndex + 0w1)
                  )
          val newIndex = valOf(lastAtomIndex)
          val newGlobalIndexEnv =
              {
               nextArrayIndex = nextArrayIndex,
               lastBoxedIndex = lastBoxedIndex,
               lastAtomIndex = lastAtomIndex,
               lastDoubleIndex = lastDoubleIndex,
               indexMap = ExternalVarID.Map.insert(indexMap, abstractIndex, newIndex)
              }
        in
          (newGlobalIndexEnv, newIndex)
        end
      | AN.BOXED =>
        let
          val (lastBoxedIndex, nextArrayIndex) =
              case lastBoxedIndex of
                NONE =>
                (
                 recordedArrayIndexes := (!recordedArrayIndexes @ [(nextArrayIndex, AN.BOXED)]);
                 (SOME {arrayIndex = nextArrayIndex, offset = 0w0}, nextArrayIndex + 0w1)
                )
              | SOME {arrayIndex, offset} =>
                if offset + 0w1 < globalBoxedArraySize 
                then (SOME {arrayIndex = arrayIndex, offset = offset + 0w1}, nextArrayIndex)
                else 
                  (
                   recordedArrayIndexes := (!recordedArrayIndexes @ [(nextArrayIndex, AN.BOXED)]);
                   (SOME {arrayIndex = nextArrayIndex, offset = 0w0}, nextArrayIndex + 0w1)
                  )
          val newIndex = valOf(lastBoxedIndex)
          val newGlobalIndexEnv =
              {
               nextArrayIndex = nextArrayIndex,
               lastBoxedIndex = lastBoxedIndex,
               lastAtomIndex = lastAtomIndex,
               lastDoubleIndex = lastDoubleIndex,
               indexMap = ExternalVarID.Map.insert(indexMap, abstractIndex, newIndex)
              }
        in
          (newGlobalIndexEnv, newIndex)
        end
      | AN.DOUBLE =>
        let
          val (lastDoubleIndex, nextArrayIndex) =
              case lastDoubleIndex of
                NONE =>
                (
                 recordedArrayIndexes := (!recordedArrayIndexes @ [(nextArrayIndex, AN.DOUBLE)]);
                 (SOME {arrayIndex = nextArrayIndex, offset = 0w0}, nextArrayIndex + 0w1)
                )
              | SOME {arrayIndex, offset} =>
                if offset + 0w2 < globalDoubleArraySize 
                then (SOME {arrayIndex = arrayIndex, offset = offset + 0w2}, nextArrayIndex)
                else 
                  (
                   recordedArrayIndexes := (!recordedArrayIndexes @ [(nextArrayIndex, AN.DOUBLE)]);
                   (SOME {arrayIndex = nextArrayIndex, offset = 0w0}, nextArrayIndex + 0w1)
                  )
          val newIndex = valOf(lastDoubleIndex)
          val newGlobalIndexEnv =
              {
               nextArrayIndex = nextArrayIndex,
               lastBoxedIndex = lastBoxedIndex,
               lastAtomIndex = lastAtomIndex,
               lastDoubleIndex = lastDoubleIndex,
               indexMap = ExternalVarID.Map.insert(indexMap, abstractIndex, newIndex)
              }
        in
          (newGlobalIndexEnv, newIndex)
        end
      | _ => raise Control.Bug "global should have a concrete type"

  fun startRecordingNewGlobalArrays () = 
      recordedArrayIndexes := ([] : (arrayIndex * IL.ty) list)

  fun getNewGlobalArrayIndexes () = !recordedArrayIndexes

end
