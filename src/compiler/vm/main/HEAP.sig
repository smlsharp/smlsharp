(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This module provides heap management.
 * @author YAMATODANI Kiyoshi
 * @version $Id: HEAP.sig,v 1.16 2006/02/18 04:59:39 ohori Exp $
 *)
signature HEAP =
sig

  (***************************************************************************)

  (** function which receives a value and updates it if it is a pointer. *)
  type rootTracer = RuntimeTypes.cellValue -> RuntimeTypes.cellValue

  (** call back function which the heap will call this at GC.
   * Users of the heap should provide this rootSet.
   * In this function, user should pass his holding root pointers to the
   * rootTracer. *)
  type rootSet = rootTracer -> unit

  (** the heap. *)
  type heap

  (** bitmap indicating which slot holds pointer value. *)
  type bitmap = BasicTypes.UInt32

  (** contents of cells *)
  type cellValue = RuntimeTypes.cellValue

  (** address to a cell in the heap. *)
  type address = cellValue RawMemory.pointer

  (***************************************************************************)

  exception Error of string

  (***************************************************************************)

  (** set to true if message should be printed on invocations of GC *)
  val traceGC : bool ref

  (** initialize heap *)
  val initialize :
      {
        memory : cellValue RawMemory.pointer,
        memorySize : BasicTypes.UInt32,
        rootSets : rootSet list
      } -> heap

  (* add a rootset. *)
  val addRootSet : heap -> rootSet -> int

  (* remove a rootset. *)
  val removeRootSet : heap -> int -> unit

  (** get the bitmap of a block *)
  val getBitmap : heap -> address -> bitmap

  (** set the bitmap of a block *)
  val setBitmap : heap -> (address * bitmap) -> unit

  (** get the number of fields of a block *)
  val getSize : heap -> address -> BasicTypes.UInt32

  (** get the block type of a block *)
  val getBlockType : heap -> address -> RuntimeTypes.blockType

  (** get the content of a field of a block *)
  val getField : heap -> (address * BasicTypes.UInt32) -> cellValue
  val getFields
      : heap
        -> (address
            * (** start index *) BasicTypes.UInt32
            * (** fields count *) BasicTypes.UInt32)
        -> cellValue list

  (** update the content of a field of a block *)
  val setField : heap -> (address * BasicTypes.UInt32 * cellValue) -> unit
  val setFields
      : heap -> (address * BasicTypes.UInt32 * cellValue list) -> unit

  (** allocates a block *)
  val allocateBlock :
      heap
      -> {
           size : BasicTypes.UInt32,
           bitmap : bitmap,
           blockType : RuntimeTypes.blockType
         }
      -> address

  (** allocates a blank block *)
  val allocateBlankBlock :
      heap
      -> {
           size : BasicTypes.UInt32,
           blockType : RuntimeTypes.blockType
         }
      -> address

  val copyBlock : heap -> (address * address) -> unit

  val getEmptyBlockAddress : heap -> address
(*
  (** initialize fields of a just allocated block *)
  val putFields : heap -> (address * cellValue list) -> unit
*)

  (***************************************************************************)

end 
