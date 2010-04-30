(**
 * global array index allocator for AIGenerator
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: GlobalIndexAllocator.sml,v 1.5 2008/02/21 02:58:40 bochao Exp $
 *)
structure GlobalIndexAllocator : sig

  type allocator =
      {
        allocator: AIGenerator.globalIndexAllocator,
        finish: unit -> GlobalIndexEnv.globalIndexEnv * 
                        (GlobalIndexEnv.arrayIndex * ANormal.ty) list
      }

  val new : GlobalIndexEnv.globalIndexEnv -> allocator

end =
struct

  type allocator =
      {
        allocator: AIGenerator.globalIndexAllocator,
        finish: unit -> GlobalIndexEnv.globalIndexEnv * 
                        (GlobalIndexEnv.arrayIndex * ANormal.ty) list
      }

  fun allocGlobalIndex globalIndexEnvRef (index, ty) =
      let
        val (newGlobalIndexEnv, newIndex) =
            GlobalIndexEnv.allocateIndex (!globalIndexEnvRef, index, ty)
      in
        globalIndexEnvRef := newGlobalIndexEnv
      end

  fun findGlobalIndex globalIndexEnvRef index =
      GlobalIndexEnv.findIndex (!globalIndexEnvRef, index)

  fun new globalIndexEnv =
      let
        val _ = GlobalIndexEnv.startRecordingNewGlobalArrays ()
        val envRef = ref globalIndexEnv

        fun finish () =
            (!envRef, GlobalIndexEnv.getNewGlobalArrayIndexes ())
      in
        {
          allocator =
            {
              alloc = allocGlobalIndex envRef,
              find = findGlobalIndex envRef
            } : AIGenerator.globalIndexAllocator,
          finish = finish
        } : allocator
      end

end
