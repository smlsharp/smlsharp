structure GlobalIndexEnv :> GLOBALINDEXENV = struct

  structure BT = BasicTypes
  structure IL = IntermediateLanguage
  structure P = Pickle
  structure AN = ANormal

  (* assignment of a slot of an global array to each external variable ID *)
  type globalIndexEnv = 
       GlobalArrayIndexCounter.implementationIndex ExVarID.Map.map

  (* composed object for global array management. *)
  type globalIndexAllocator =
       {globalIndexEnv: globalIndexEnv,
        newGlobalIndexEnv: globalIndexEnv,
        newArrayIndexes: (GlobalArrayIndexCounter.arrayIndex * IL.ty) list}

  val pu_globalIndexEnv =
      ExVarID.Map.pu_map GlobalArrayIndexCounter.pu_implementationIndex

  val emptyGlobalIndexEnv =
      ExVarID.Map.empty : globalIndexEnv

  fun extendGlobalIndexEnv (env1, env2) =
      ExVarID.Map.unionWith #2 (env1, env2) : globalIndexEnv

  fun initGlobalIndexAllocator globalIndexEnv =
      {
        globalIndexEnv = globalIndexEnv,
        newGlobalIndexEnv = ExVarID.Map.empty,
        newArrayIndexes = nil
      } : globalIndexAllocator

  fun finishGlobalIndexAllocator (allocator:globalIndexAllocator) =
      {
        newGlobalIndexEnv = #newGlobalIndexEnv allocator,
        newGlobalArrayIndexes = #newArrayIndexes allocator
      }

  fun findIndex ({globalIndexEnv, newGlobalIndexEnv, ...}:globalIndexAllocator,
                 abstractIndex) =
      case ExVarID.Map.find (newGlobalIndexEnv, abstractIndex) of
        SOME x => SOME x
      | NONE => ExVarID.Map.find (globalIndexEnv, abstractIndex)

  fun allocateIndex ({globalIndexEnv, newGlobalIndexEnv,
                      newArrayIndexes}:globalIndexAllocator,
                     abstractIndex, ty) =
      let
        val ty =
            case ty of
              AN.ATOM => GlobalArrayIndexCounter.ATOM
            | AN.BOXED => GlobalArrayIndexCounter.BOXED
            | AN.DOUBLE => GlobalArrayIndexCounter.DOUBLE
            | _ => raise Control.Bug "global should have a concrete type"
        val (newArrays, newIndex) = GlobalArrayIndexCounter.allocateIndex ty
        val newArrays =
            map (fn (x, GlobalArrayIndexCounter.ATOM) => (x, AN.ATOM)
                  | (x, GlobalArrayIndexCounter.BOXED) => (x, AN.BOXED)
                  | (x, GlobalArrayIndexCounter.DOUBLE) => (x, AN.DOUBLE))
                newArrays
        val newArrayIndexes = newArrayIndexes @ newArrays
        val newGlobalIndexEnv =
            ExVarID.Map.insert (newGlobalIndexEnv, abstractIndex, newIndex)
      in
        ({globalIndexEnv = globalIndexEnv,
          newGlobalIndexEnv = newGlobalIndexEnv,
          newArrayIndexes = newArrayIndexes} : globalIndexAllocator,
         newIndex)
      end

end
