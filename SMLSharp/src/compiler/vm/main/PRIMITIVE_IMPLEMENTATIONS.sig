signature PRIMITIVE_IMPLEMENTATIONS =
sig

  (***************************************************************************)

  val primitives
      : {
          name : string,
          function
          : VM.VM
            -> Heap.heap
            -> RuntimeTypes.cellValue list
            -> RuntimeTypes.cellValue list
        } list

  (***************************************************************************)

end;
