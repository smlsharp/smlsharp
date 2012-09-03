(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CellValuePrinter.sml,v 1.4 2006/02/28 16:11:01 kiyoshiy Exp $
 *)
structure CellValuePrinter 
          : sig
              val valueToStrings
                  : VM.VM -> RuntimeTypes.cellValue -> string list
            end =
struct

  (***************************************************************************)

  structure H = Heap
  structure RT = RuntimeTypes

  structure AddressSet =
  BinarySetFn(struct 
                type ord_key = RT.address
                val compare = RawMemory.compare
              end)

  (***************************************************************************)

  datatype stringTree =
           Atom of string
         | Record of string * stringTree list
         | (** reference to an ancestor node *) Cycle of RT.address

  (***************************************************************************)

  fun valueToTree VM parentsSet value =
      case value of
        RT.Pointer address =>
        if AddressSet.member (parentsSet, address)
        then Cycle address
        else
          (let
            val newParentSet = AddressSet.add (parentsSet, address)
            val heap = VM.getHeap VM
            val bitmap = H.getBitmap heap address
            val blockSize = H.getSize heap address
            val blockType = H.getBlockType heap address
            val fields = H.getFields heap (address, 0w0, blockSize)
            val headerString =
                RT.cellValueToString
                (RT.Header
                 {size = blockSize, bitmap = bitmap, blockType = blockType})
            val addressString = RawMemory.toString address
            val fieldTrees = map (valueToTree VM newParentSet) fields
           in
            Record (addressString ^ " " ^ headerString, fieldTrees)
           end
             handle H.Error message => raise Fail message) (* ToDo : *)
      | _ => Atom(RT.cellValueToString value)

  fun treeToStrings prefix (Atom string) = [prefix ^ string]
    | treeToStrings prefix (Cycle address) =
      [prefix ^ "cyclic reference to " ^ RawMemory.toString address]
    | treeToStrings prefix (Record (string, trees)) =
      let
        val fieldIndent =
            implode (List.tabulate (String.size prefix, fn _ => #" "))
        val (_, indexedFieldStringss) =
            foldl
                (fn (tree, (index, fieldStringss)) =>
                    let
                      val fieldPrefix =
                          fieldIndent ^ "[" ^ Int.toString index ^ "]"
                      val fieldStrings = treeToStrings fieldPrefix tree
                    in
                      (index + 1, fieldStrings :: fieldStringss)
                    end)
                (0, [])
                trees
        val indexedFieldStrings = List.concat(List.rev indexedFieldStringss)
      in
        (prefix ^ string) :: indexedFieldStrings
      end

  fun valueToStrings VM value =
      let
        val tree = valueToTree VM (AddressSet.empty) value
        val strings = treeToStrings "" tree
      in
        strings
      end

  (***************************************************************************)

end
