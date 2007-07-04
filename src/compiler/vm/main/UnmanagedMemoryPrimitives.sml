(**
 * implementation of primitives on unmanaged memory.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnmanagedMemoryPrimitives.sml,v 1.6 2007/04/02 09:42:29 katsu Exp $
 *)
structure UnmanagedMemoryPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun UnmanagedMemory_allocate VM heap [Int bytes] =
      [SLD.stringToValue heap "abc"]
    | UnmanagedMemory_allocate _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_allocate"

  fun UnmanagedMemory_release VM heap [Word rawAddress] =
      [SLD.unitToValue heap ()]
    | UnmanagedMemory_release _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_release"

  fun UnmanagedMemory_sub VM heap [Word rawAddress] =
      [Word 0w0]
    | UnmanagedMemory_sub _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_sub"

  fun UnmanagedMemory_update VM heap [Word rawAddress, Word value] =
      [SLD.unitToValue heap ()]
    | UnmanagedMemory_update _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_update"

  (* updateInt : ptr * int -> unit *)
  fun UnmanagedMemory_updateInt VM heap [Word rawAddress, Int bytes] =
      [SLD.unitToValue heap ()]
    | UnmanagedMemory_updateInt _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_updateInt"

  (* updateInt : ptr -> int *)
  fun UnmanagedMemory_subInt VM heap [Word rawAddress] =
      [Int 0]
    | UnmanagedMemory_subInt _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_subInt"

  fun UnmanagedMemory_subWord VM heap [Word rawAddress] =
      [Word 0w0]
    | UnmanagedMemory_subWord _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_subWord"

  fun UnmanagedMemory_updateWord VM heap [Word rawAddress, Word value] =
      [SLD.unitToValue heap ()]
    | UnmanagedMemory_updateWord _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_updateWord"

  fun UnmanagedMemory_subReal VM heap [Word rawAddress] =
      [Real 0.0]
    | UnmanagedMemory_subReal _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_subReal"

  fun UnmanagedMemory_updateReal
          VM heap [Word rawAddress, Real value, Word 0w0] =
      [SLD.unitToValue heap ()]
    | UnmanagedMemory_updateReal _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_updateReal"

  fun UnmanagedMemory_import VM heap [Word rawAddress, Int bytes] =
      [SLD.stringToValue heap "abc"]
    | UnmanagedMemory_import _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_import"

  fun UnmanagedMemory_export VM heap [address as Pointer _] =
      let val string = SLD.valueToString heap address
      in [Word 0w0]
      end
    | UnmanagedMemory_export _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedMemory_export"

  val primitives =
      [
        {
          name = "UnmanagedMemory_allocate",
          function = UnmanagedMemory_allocate
        },
        {name = "UnmanagedMemory_release", function = UnmanagedMemory_release},
        {name = "UnmanagedMemory_sub", function = UnmanagedMemory_sub},
        {name = "UnmanagedMemory_update", function = UnmanagedMemory_update},
        {name = "UnmanagedMemory_subWord", function = UnmanagedMemory_subWord},
        {
          name = "UnmanagedMemory_updateWord",
          function = UnmanagedMemory_updateWord
        },
        {name = "UnmanagedMemory_subReal", function = UnmanagedMemory_subReal},
        {
          name = "UnmanagedMemory_updateReal",
          function = UnmanagedMemory_updateReal
        },
        {name = "UnmanagedMemory_import", function = UnmanagedMemory_import},
        {name = "UnmanagedMemory_export", function = UnmanagedMemory_export},
        {name = "UnmanagedMemory_updateInt", function = UnmanagedMemory_updateInt},
        {name = "UnmanagedMemory_subInt", function = UnmanagedMemory_subInt}
      ]

  (***************************************************************************)

end;
