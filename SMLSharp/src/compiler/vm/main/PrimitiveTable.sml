(**
 * table of implemetation of primitive operators.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveTable.sml,v 1.25 2008/03/11 08:53:57 katsu Exp $
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
        DynamicLinkPrimitives.primitives,
        StringPrimitives.primitives,
        RealPrimitives.primitives,
        IOPrimitives.primitives,
        TimePrimitives.primitives,
        TimerPrimitives.primitives,
        GenericOSPrimitives.primitives,
        CommandLinePrimitives.primitives,
        DatePrimitives.primitives,
        MathPrimitives.primitives,
        PlatformPrimitives.primitives,
        StandardCPrimitives.primitives,
        InternalPrimitives.primitives,
        UnmanagedMemoryPrimitives.primitives,
        UnmanagedStringPrimitives.primitives,
        GCPrimitives.primitives
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
  fun argSizeOfTy (TY.RAWty{tyCon, ...}) =
      if #name tyCon = "real" then 0w2 else 0w1
    | argSizeOfTy _ = 0w1 : BasicTypes.UInt32
  fun argSizesOfTy (TY.POLYty{body, ...}) = argSizesOfTy body
    | argSizesOfTy (TY.FUNMty([argty], _)) = map argSizeOfTy (argTys argty)
    | argSizesOfTy ty = raise Fail "PrimitiveTable.argSizesOfTy"

  fun dummyTyState arity name =
      let
        val tyvars = List.tabulate (arity, fn _ => Types.NONEQ)
      in
      Types.TYCON {tyCon = {name = "",
                            strpath = Path.NilPath,
                            id = TyConID.generate(), (* initialID *)
                            abstract = false,
                            eqKind = ref Types.EQ,
                            tyvars = tyvars,
                            constructorHasArgFlagList = []},
                   datacon = SEnv.empty}
      end
  fun extendTyConEnv env arity tyconNames =
      foldl
          (fn (name,env) => SEnv.insert (env, name, dummyTyState arity name))
          env
          tyconNames

  val arity0Tycons = 
      ["string","unit","int","word","real","byte","byteArray","char","float",
       "bool"]
  val arity1Tycons = ["ptr","option","array","ref"]
  val dummyTopTyConEnv = SEnv.empty
  val dummyTopTyConEnv = extendTyConEnv dummyTopTyConEnv 0 arity0Tycons
  val dummyTopTyConEnv = extendTyConEnv dummyTopTyConEnv 1 arity1Tycons

  fun readTy ty =
      TypeParser.readTy dummyTopTyConEnv ty

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
                         argSizes = argSizesOfTy (readTy ty)
                       }
                 in
                   IEnv.insert (map, index, primitive)
                 end)
            | (_, map) => map)
          IEnv.empty
          P.allPrimitives

  val map = primitiveIndexMap

  (***************************************************************************)

end
