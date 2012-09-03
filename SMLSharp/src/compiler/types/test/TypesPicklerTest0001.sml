(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypesPicklerTest0001.sml,v 1.3 2007/10/26 06:03:16 katsu Exp $
 *)
structure TypesPicklerTest001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = TypesPickler

  structure T = Types

  (***************************************************************************)

  val sampleTyCon1 = 
      {
        name = "foo",
        strpath = Path.NilPath,
        tyvars = [false],
        id = ID.generate (),
        abstract = true,
        eqKind = ref T.EQ,
        boxedKind = ref (SOME T.BOXEDty),
        datacon = ref SEnv.empty
      } : T.tyCon

  fun testEqKind eqKind =
      let
        val pickled = Pickle.toString TypesPickler.eqKind eqKind
        val eqKind' = Pickle.fromString TypesPickler.eqKind pickled
      in
        Assert.assertEqual
            (op =)
            (fn T.EQ => "EQ" | T.NONEQ => "NONEQ")
            eqKind
            eqKind';
        ()
      end

  fun testEqKind0001 () = testEqKind T.EQ

  fun testEqKind0002 () = testEqKind T.NONEQ

  (****************************************)

  fun testConstant constant =
      let
        val pickled = Pickle.toString TypesPickler.constant constant
        val constant' = Pickle.fromString TypesPickler.constant pickled
      in
        Assert.assertEqual
            (op =)
            (fn T.CHAR ch => "CHAR" ^ Char.toString ch
              | T.INT int32 => "INT" ^ Int32.toString int32
              | T.REAL string => "REAL" ^ string
              | T.STRING string => "STRING" ^ string
              | T.WORD word32 => "WORD" ^ Word32.toString word32)
            constant
            constant';
        ()
      end

  fun testConstant0001 () = testConstant (T.CHAR #"a")

  fun testConstant0002 () = testConstant (T.INT 123)

  fun testConstant0003 () = testConstant (T.REAL "1.23")

  fun testConstant0004 () = testConstant (T.STRING "abc")

  fun testConstant0005 () = testConstant (T.WORD 0w123)

  (****************************************)

  fun testPath path =
      let
        val pickled = Pickle.toString NamePickler.path path
        val path' = Pickle.fromString NamePickler.path pickled
      in
        Assert.assertEqual
            (op =)
            Path.pathToString
            path
            path';
        ()
      end

  fun testPath0001 () = testPath Path.NilPath

  fun testPath0002 () =
      let val id = ID.generate ()
      in testPath (Path.PStructure(id, "foo", Path.NilPath))
      end

  (****************************************)

  fun testId id =
      let
        val pickled = Pickle.toString NamePickler.id id
        val id' = Pickle.fromString NamePickler.id pickled
      in
        Assert.assertEqual
            ((fn EQUAL => true | _ => false) o ID.compare)
            ID.toString
            id
            id';
        ()
      end

  fun testId0001 () = testId (ID.reserve ())

  fun testId0002 () = testId (ID.generate ())

  (****************************************)

  fun testTid tid =
      let
        val pickled = Pickle.toString TypesPickler.tid tid
        val tid' = Pickle.fromString TypesPickler.tid pickled
      in
        Assert.assertEqual
            ((fn EQUAL => true | _ => false) o T.tidCompare)
            Types.tidToString
            tid
            tid';
        ()
      end

  fun testTid0001 () = testTid (Types.nextTid ())

  (****************************************)

  fun testRecKind recKind =
      let
        val pickled = Pickle.toString TypesPickler.recKind recKind
        val recKind' = Pickle.fromString TypesPickler.recKind pickled
      in
(*
        Assert.assertEqual
            ((fn EQUAL => true | _ => false) o T.recKindCompare)
            Types.recKindToString
            recKind
            recKind';
*)
        ()
      end

  fun testRecKind0001 () = testRecKind (T.OVERLOADED [])

  fun testRecKind0002 () = testRecKind (T.REC SEnv.empty)

  fun testRecKind0003 () = testRecKind T.UNIV

  (****************************************)

  fun testTvState tvState =
      let
        val pickled = Pickle.toString TypesPickler.tvState tvState
        val tvState' = Pickle.fromString TypesPickler.tvState pickled
      in
(*
        Assert.assertEqual
            ((fn EQUAL => true | _ => false) o T.tvStateCompare)
            Types.tvStateToString
            tvState
            tvState';
*)
        ()
      end

  fun testTvState0001 () = testTvState (T.SUBSTITUTED T.BOXEDty)

  fun testTvState0002 () =
      let
        val tvKind =
            {
              id = T.nextTid (),
              recKind = T.UNIV,
              eqKind = T.EQ,
              tyvarName = NONE
            }
      in
        testTvState (T.TVAR tvKind)
      end

  (****************************************)

(*
  val assertEqualTy = 
      Assert.assertEqual
          SigCheck.equivTy
          TypeFormatter.tyToString;
*)
  fun testTy ty =
      let
        val pickled = Pickle.toString TypesPickler.ty ty
        val ty2 = Pickle.fromString TypesPickler.ty pickled
      in
        ()
      end

  fun testABSSPECty0001 () =
      testTy (T.ABSSPECty(T.ATOMty, T.ATOMty))

  fun testALIASty0001 () =
      testTy (T.ALIASty(T.ATOMty, T.ATOMty))

  fun testATOMty0001 () = testTy T.ATOMty

  fun testBOUNDVARty0001 () = testTy (T.BOUNDVARty 10)

  fun testBOXEDty0001 () = testTy T.BOXEDty

  fun testCONty0001 () =
      let
        val tyCon = sampleTyCon1
      in
        testTy (T.CONty {args = [T.BOXEDty], tyCon = tyCon})
      end

  fun testDOUBLEty0001 () = testTy T.DOUBLEty

  fun testDUMMYty0001 () = testTy (T.DUMMYty 1)

  fun testERRORty0001 () = testTy T.ERRORty

  fun testFUNMty0001 () = testTy (T.FUNMty ([T.ATOMty], T.BOXEDty))

  fun testPOLYty0001 () =
      let
        val btvKind = {index = 1, recKind = T.UNIV, eqKind = T.EQ}
        val boundtvars = IEnv.insert (IEnv.empty, 1, btvKind)
      in
        testTy (T.POLYty {body = T.ATOMty, boundtvars = boundtvars})
      end

  fun testRECORDty0001 () =
      let
        val fieldMap = SEnv.insert (SEnv.empty, "a", T.ATOMty)
      in
        testTy (T.RECORDty fieldMap)
      end

  fun testSPECty0001 () = testTy (T.SPECty T.ATOMty)

  fun testTYVARty0001 () =
      let
        val tvKindRef = ref (T.SUBSTITUTED (T.ATOMty))
        val ty = T.TYVARty tvKindRef
        (* self recursive. Although this will not appear in actual code. *)
        val _ = tvKindRef := T.SUBSTITUTED ty
      in
        testTy ty
      end

  (****************************************)

  fun testIdState idState =
      let
        val pickled = Pickle.toString TypesPickler.idState idState
        val idState2 = Pickle.fromString TypesPickler.idState pickled
      in
        ()
      end

  fun testCONID0001 () =
      let
        val conPathInfo = 
            {
              name = "foo",
              strpath = Path.NilPath,
              funtyCon = true,
              ty = T.ATOMty,
              tag = 10,
              tyCon = sampleTyCon1
            }
      in
        testIdState (T.CONID conPathInfo)
      end
              
  fun testOPRIM0001 () =
      let
        val primInfo = {name = "bar", ty = T.BOXEDty}
        val primMap = SEnv.insert(SEnv.empty, "bar", primInfo)
        val oprimInfo = {name = "foo", ty = T.ATOMty, instances = primMap}
      in
        testIdState (T.OPRIM oprimInfo)
      end

  fun testPRIM0001 () =
      let
        val primInfo = {name = "bar", ty = T.BOXEDty}
      in
        testIdState (T.PRIM primInfo)
      end

  fun testFFID0001 () =
      let
        val foreignFunPathInfo =
            {
              name = "foo",
              strpath = Path.NilPath,
              ty = T.ATOMty,
              argTys = [T.BOXEDty]
            }
      in
        testIdState (T.FFID foreignFunPathInfo)
      end

  fun testVARID0001 () =
      let
        val varPathInfo = {name = "foo", strpath = Path.NilPath, ty = T.ATOMty}
      in
        testIdState (T.VARID varPathInfo)
      end

  (****************************************)

  fun testTyBindInfo tyBindInfo =
      let
        val pickled = Pickle.toString TypesPickler.tyBindInfo tyBindInfo
        val tyBindInfo2 = Pickle.fromString TypesPickler.tyBindInfo pickled
      in
        ()
      end

  fun testTYCON0001 () =
      let
        val tyCon = sampleTyCon1
      in
        testTyBindInfo (T.TYCON tyCon)
      end

  fun testTYFUN0001 () =
      let
        val btvKind = {index = 0, recKind = T.UNIV, eqKind = T.EQ}
        val tyargs = IEnv.insert (IEnv.empty, 1, btvKind)
        val tyFun = {name = "foo", tyargs = tyargs, body = T.BOXEDty}
      in
        testTyBindInfo (T.TYFUN tyFun)
      end

  fun testTYSPEC0001 () =
      let
        val tySpec =
            {
              name = "foo",
              id = ID.generate (),
              strpath = Path.NilPath,
              eqKind = T.NONEQ,
              tyvars = [true],
              boxedKind = NONE
            }
      in
        testTyBindInfo
            (T.TYSPEC {impl = SOME(T.TYCON sampleTyCon1), spec = tySpec})
      end

  (****************************************)

  fun testTvKind tvKind =
      let
        val pickled = Pickle.toString TypesPickler.tvKind tvKind
        val tvKind2 = Pickle.fromString TypesPickler.tvKind pickled
      in
        ()
      end

  fun testTvKind0001 () =
      let
        val tvKind =
            {
              id = T.nextTid (),
              recKind = T.UNIV,
              eqKind = T.EQ,
              tyvarName = NONE
            }
      in
        testTvKind tvKind
      end

  (********************)

  fun testVarIdInfo varIdInfo =
      let
        val pickled = Pickle.toString TypesPickler.varIdInfo varIdInfo
        val varIdInfo2 = Pickle.fromString TypesPickler.varIdInfo pickled
      in
        ()
      end

  fun testVarIdInfo0001 () =
      let
        val varIdInfo =
            {id = ID.generate (), displayName = "foo", ty = T.BOXEDty}
      in
        testVarIdInfo varIdInfo
      end

  (********************)

  fun testBtvKind btvKind =
      let
        val pickled = Pickle.toString TypesPickler.btvKind btvKind
        val btvKind2 = Pickle.fromString TypesPickler.btvKind pickled
      in
        ()
      end

  fun testBtvKind0001 () =
      let
        val btvKind = {index = 1, recKind = T.UNIV, eqKind = T.EQ}
      in
        testBtvKind btvKind
      end

  (********************)

  fun testVarEnv varEnv =
      let
        val pickled = Pickle.toString TypesPickler.varEnv varEnv
        val varEnv2 = Pickle.fromString TypesPickler.varEnv pickled
      in
        ()
      end

  fun testVarEnv0001 () =
      let
        val varPathInfo = {name = "foo", strpath = Path.NilPath, ty = T.ATOMty}
        val idState = T.VARID varPathInfo
        val varEnv = SEnv.insert (SEnv.empty, "foo", idState)
      in
        testVarEnv varEnv
      end

  (********************)

  fun testTyConEnv tyConEnv =
      let
        val pickled = Pickle.toString TypesPickler.tyConEnv tyConEnv
        val tyConEnv2 = Pickle.fromString TypesPickler.tyConEnv pickled
      in
        ()
      end

  fun testTyConEnv0001 () =
      let
        val tyBindInfo = T.TYCON sampleTyCon1
        val tyConEnv = SEnv.insert (SEnv.empty, "foo", tyBindInfo)
      in
        testTyConEnv tyConEnv
      end

  (********************)

  fun testTyFun tyFun =
      let
        val pickled = Pickle.toString TypesPickler.tyFun tyFun
        val tyFun2 = Pickle.fromString TypesPickler.tyFun pickled
      in
        ()
      end

  fun testTyFun0001 () =
      let
        val btvKind = {index = 0, recKind = T.UNIV, eqKind = T.EQ}
        val tyargs = IEnv.insert (IEnv.empty, 1, btvKind)
        val tyFun = {name = "foo", tyargs = tyargs, body = T.BOXEDty}
      in
        testTyFun tyFun
      end

  (********************)

  fun testTyCon tyCon =
      let
        val pickled = Pickle.toString TypesPickler.tyCon tyCon
        val tyCon2 = Pickle.fromString TypesPickler.tyCon pickled
      in
        ()
      end

  (*
   * no value constructor
   *)
  fun testTyCon0001 () =
      let
        val tyCon = 
            {
              name = "foo0001",
              strpath = Path.NilPath,
              tyvars = [false],
              id = ID.generate (),
              abstract = true,
              eqKind = ref T.EQ,
              boxedKind = ref (SOME T.BOXEDty),
              datacon = ref SEnv.empty
            } : T.tyCon
      in
        testTyCon tyCon
      end

  (*
   * one value constructor
   *)
  fun testTyCon0002 () =
      let
        val dataconRef = ref SEnv.empty
        val tyCon = 
            {
              name = "foo0002",
              strpath = Path.NilPath,
              tyvars = [false],
              id = ID.generate (),
              abstract = true,
              eqKind = ref T.EQ,
              boxedKind = ref (SOME T.BOXEDty),
              datacon = dataconRef
            } : T.tyCon
        val conPathInfo =
            {
              name = "bar0002",
              strpath = Path.NilPath,
              funtyCon = false,
              ty = T.CONty {args = [], tyCon = tyCon},
              tag = 1,
              tyCon = tyCon
            }
        val _ =
            dataconRef :=
            SEnv.insert (SEnv.empty, "bar0002", T.CONID conPathInfo)
      in
        testTyCon tyCon
      end

  (********************)

  fun testTySpec tySpec =
      let
        val pickled = Pickle.toString TypesPickler.tySpec tySpec
        val tySpec2 = Pickle.fromString TypesPickler.tySpec pickled
      in
        ()
      end

  fun testTySpec0001 () =
      let
        val tySpec =
            {
              name = "foo",
              id = ID.generate (),
              strpath = Path.NilPath,
              eqKind = T.NONEQ,
              tyvars = [true],
              boxedKind = NONE
            }
      in
        testTySpec tySpec
      end

  (********************)

  fun testConPathInfo conPathInfo =
      let
        val pickled = Pickle.toString TypesPickler.conPathInfo conPathInfo
        val conPathInfo2 = Pickle.fromString TypesPickler.conPathInfo pickled
      in
        ()
      end

  fun testConPathInfo0001 () =
      let
        val conPathInfo = 
            {
              name = "foo",
              strpath = Path.NilPath,
              funtyCon = true,
              ty = T.ATOMty,
              tag = 10,
              tyCon = sampleTyCon1
            }
      in
        testConPathInfo conPathInfo
      end
              
  (********************)

  fun testVarPathInfo varPathInfo =
      let
        val pickled = Pickle.toString TypesPickler.varPathInfo varPathInfo
        val varPathInfo2 = Pickle.fromString TypesPickler.varPathInfo pickled
      in
        ()
      end

  fun testVarPathInfo0001 () =
      let
        val varPathInfo = 
            {
              name = "foo",
              strpath = Path.NilPath,
              ty = T.ATOMty
            }
      in
        testVarPathInfo varPathInfo
      end
              
  (********************)

  fun testPrimInfo primInfo =
      let
        val pickled = Pickle.toString TypesPickler.primInfo primInfo
        val primInfo2 = Pickle.fromString TypesPickler.primInfo pickled
      in
        ()
      end

  fun testPrimInfo0001 () =
      let
        val primInfo = {name = "foo", ty = T.ATOMty}
      in
        testPrimInfo primInfo
      end
              
  (********************)

  fun testOprimInfo oprimInfo =
      let
        val pickled = Pickle.toString TypesPickler.oprimInfo oprimInfo
        val oprimInfo2 = Pickle.fromString TypesPickler.oprimInfo pickled
      in
        ()
      end

  fun testOprimInfo0001 () =
      let
        val primInfo = {name = "bar", ty = T.BOXEDty}
        val primMap = SEnv.insert(SEnv.empty, "bar", primInfo)
        val oprimInfo = {name = "foo", ty = T.ATOMty, instances = primMap}
      in
        testOprimInfo oprimInfo
      end
              
  (********************)

  fun testForeignFunPathInfo foreignFunPathInfo =
      let
        val pickled =
            Pickle.toString TypesPickler.foreignFunPathInfo foreignFunPathInfo
        val foreignFunPathInfo2 =
            Pickle.fromString TypesPickler.foreignFunPathInfo pickled
      in
        ()
      end

  fun testForeignFunPathInfo0001 () =
      let
        val foreignFunPathInfo =
            {
              name = "foo",
              strpath = Path.NilPath,
              ty = T.ATOMty,
              argTys = [T.BOXEDty]
            }
      in
        testForeignFunPathInfo foreignFunPathInfo
      end
              
  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testEqKind0001", testEqKind0001),
        ("testEqKind0002", testEqKind0002),

        ("testConstant0001", testConstant0001),
        ("testConstant0002", testConstant0002),
        ("testConstant0003", testConstant0003),
        ("testConstant0004", testConstant0004),
        ("testConstant0005", testConstant0005),

        ("testPath0001", testPath0001),
        ("testPath0002", testPath0002),

        ("testId0001", testId0001),
        ("testId0002", testId0002),

        ("testTid0001", testTid0001),

        ("testRecKind0001", testRecKind0001),
        ("testRecKind0002", testRecKind0002),
        ("testRecKind0003", testRecKind0003),

        ("testTvState0001", testTvState0001),
        ("testTvState0002", testTvState0002),

        ("testABSSPECty0001", testABSSPECty0001),
        ("testALIASty0001", testALIASty0001),
        ("testATOMty0001", testATOMty0001),
        ("testBOUNDVARty0001", testBOUNDVARty0001),
        ("testBOXEDty0001", testBOXEDty0001),
        ("testCONty0001", testCONty0001),
        ("testDOUBLEty0001", testDOUBLEty0001),
        ("testDUMMYty0001", testDUMMYty0001),
        ("testERRORty0001", testERRORty0001),
        ("testFUNMty0001", testFUNMty0001),
        ("testPOLYty0001", testPOLYty0001),
        ("testRECORDty0001", testRECORDty0001),
        ("testSPECty0001", testSPECty0001),
        ("testTYVARty0001", testTYVARty0001),

        ("testCONID0001", testCONID0001),
        ("testOPRIM0001", testOPRIM0001),
        ("testPRIM0001", testPRIM0001),
        ("testFFID0001", testFFID0001),
        ("testVARID0001", testVARID0001),

        ("testTYCON0001", testTYCON0001),
        ("testTYFUN0001", testTYFUN0001),
        ("testTYSPEC0001", testTYSPEC0001),

        ("testTvKind0001", testTvKind0001),

        ("testVarIdInfo0001", testVarIdInfo0001),

        ("testBtvKind0001", testBtvKind0001),

        ("testVarEnv0001", testVarEnv0001),

        ("testTyConEnv0001", testTyConEnv0001),

        ("testTyFun0001", testTyFun0001),

        ("testTyCon0001", testTyCon0001),
        ("testTyCon0002", testTyCon0002),

        ("testTySpec0001", testTySpec0001),

        ("testConPathInfo0001", testConPathInfo0001),

        ("testVarPathInfo0001", testVarPathInfo0001),

        ("testPrimInfo0001", testPrimInfo0001),

        ("testOprimInfo0001", testOprimInfo0001),

        ("testForeignFunPathInfo0001", testForeignFunPathInfo0001)
      ]

  (***************************************************************************)

end
