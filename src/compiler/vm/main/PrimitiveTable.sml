(**
 * Copyright (c) 2006, Tohoku University.
 *
 * table of implemetation of primitive operators.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveTable.sml,v 1.13 2006/02/18 04:59:40 ohori Exp $
 *)
structure PrimitiveTable
          : sig
              val map : VM.primitive IEnv.map
            end = 
struct

  (***************************************************************************)

  structure P = Primitives
  structure RE = RuntimeErrors
  structure TY = Types

  (***************************************************************************)

  val primitivesList = 
      [
        IntPrimitives.primitives,
        WordPrimitives.primitives,
        CharPrimitives.primitives,
        StringPrimitives.primitives,
        RealPrimitives.primitives,
        IOPrimitives.primitives,
        TimePrimitives.primitives,
        TimerPrimitives.primitives,
        GenericOSPrimitives.primitives,
        CommandLinePrimitives.primitives,
        DatePrimitives.primitives,
        MathPrimitives.primitives,
        InternalPrimitives.primitives,
        UnmanagedMemoryPrimitives.primitives,
        UnmanagedStringPrimitives.primitives
      ]

  (********************)

  fun addPrimitives map primitives =
      foldr
          (fn (primitive as {name, function}, map) =>
              SEnv.insert (map, #name primitive, primitive))
          map
          primitives

  val primitiveNameMap =
      foldr
          (fn (primitives, map) => addPrimitives map primitives)
          SEnv.empty
          primitivesList

  fun argTys (TY.RECORDty tyMap) =
      let
        fun getTyOfIndex index =
            case SEnv.find (tyMap, Int.toString (index + 1)) of
              SOME ty => ty
            | NONE =>
              raise
                Fail
                ("PrimitiveTable.argTys: not found tuple element of index = "
                 ^ Int.toString index)
      in
        List.tabulate (SEnv.numItems tyMap, getTyOfIndex)
      end
    | argTys ty = [ty]
  fun argSizeOfTy (TY.CONty{tyCon, ...}) =
      if #id tyCon = StaticEnv.realTyConid then 0w2 else 0w1
    | argSizeOfTy _ = 0w1 : BasicTypes.UInt32
  fun argSizesOfTy (TY.POLYty{body, ...}) = argSizesOfTy body
    | argSizesOfTy (TY.FUNMty([argty], _)) = map argSizeOfTy (argTys argty)
    | argSizesOfTy ty = raise Fail "PrimitiveTable.argSizesOfTy"

  val primitiveIndexMap =
      List.foldr
          (fn ({instruction = P.External index, bindName, ty, ...}, map) =>
              (case SEnv.find (primitiveNameMap, bindName) of
                 NONE =>
                 (print ("Warning: " ^ bindName ^ " is not implemented.\n");
(*
                 raise
                   Fail
                       ("Sorry! primitive " ^ bindName ^ " is not defined. ")
*)
                  map
                       )
               | SOME {name, function} =>
                 let
                   val primitive = 
                       {
                         name = name,
                         function = function,
                         argSizes = argSizesOfTy ty
                       }
                 in
                   IEnv.insert (map, index, primitive)
                 end)
            | (_, map) => map)
          IEnv.empty
          P.primitives

  val map = primitiveIndexMap

  (***************************************************************************)

end
