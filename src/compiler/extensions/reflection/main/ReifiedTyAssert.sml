(**
 * Type representation for types
 *
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReifiedTyAssert =
struct
  open ReifiedTy

  fun assertEqualTaggedLayout x y = 
      SMLUnit.Assert.assertEqual taggedLayoutEq taggedLayoutToString x y
  fun assertEqualLayout x y = 
      SMLUnit.Assert.assertEqual layoutEq layoutToString x y
  fun assertEqualReifiedTy (x:reifiedTy) (y:reifiedTy) =
      SMLUnit.Assert.assertEqual reifiedTyEq reifiedTyToString x y

  fun assertEqualConSet (x:conSet) (y:conSet) =
      SMLUnit.Assert.assertEqual conSetEq conSetToString x y
  fun assertEqualConSetEnv env1 env2 =
      SMLUnit.Assert.assertEqual conSetEnvEq conSetEnvToString env1 env2
  fun assertEqualTy (tyRep1:tyRep) (tyRep2:tyRep) =
      SMLUnit.Assert.assertEqual tyRepEq tyRepToString tyRep1 tyRep2

end
