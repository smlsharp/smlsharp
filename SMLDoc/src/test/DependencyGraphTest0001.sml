(**
 * unit test of <code>structure DependencyGraph</code>
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure DependencyGraphTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = DependencyGraph

  (***************************************************************************)

  val assertEqualIsDependsOn =
      Assert.assertEqual2Tuple 
      (
        Assert.assertEqualOption Assert.assertEqualInt,
        Assert.assertEqualBool
      )

  (****************************************)

  local
    val TESTDEPENDSON0001_SIZE = 10
    val TESTDEPENDSON0001_SRC = 0
    val TESTDEPENDSON0001_DEST = 1
    val TESTDEPENDSON0001_ATTR = 1
  in
  (**
   * test case of dependsOn/isDependsOn (normal case)
   * <ol>
   *   <li>calls dependsOn.</li>
   *   <li>calls isDependsOn and verifies the return value indicates that
   *     there is a dependency with the attribute between the specified
   *     nodes.</li>
   * </ol>
   *)
  fun testDependsOn0001 () =
      let
        val graph = Testee.create TESTDEPENDSON0001_SIZE
      in
        Testee.dependsOn
        graph
        {
          src = TESTDEPENDSON0001_SRC,
          dest = TESTDEPENDSON0001_DEST,
          attr = TESTDEPENDSON0001_ATTR
        };
        assertEqualIsDependsOn
        (SOME TESTDEPENDSON0001_ATTR, true)
        (Testee.isDependsOn
         graph
         {
           src = TESTDEPENDSON0001_SRC,
           dest = TESTDEPENDSON0001_DEST
         });
        ()
      end
  end

  (****************************************)

  local
    val TESTDEPENDSON0002_SIZE = 10
    val TESTDEPENDSON0002_SRC = 0
    val TESTDEPENDSON0002_DEST = 1
  in
  (**
   * test case of dependsOn/isDependsOn (normal case)
   * <ol>
   *   <li>calls isDependsOn and verifies the return value indicates that
   *     there is no dependency with the attribute between the specified
   *     nodes.</li>
   * </ol>
   *)
  fun testDependsOn0002 () =
      let
        val graph = Testee.create TESTDEPENDSON0002_SIZE
      in
        assertEqualIsDependsOn
        (NONE, false)
        (Testee.isDependsOn
         graph
         {
           src = TESTDEPENDSON0002_SRC,
           dest = TESTDEPENDSON0002_DEST
         });
        ()
      end
  end

  (****************************************)

  local
    val TESTDEPENDSON0003_SIZE = 10
    val TESTDEPENDSON0003_SRC = 0
    val TESTDEPENDSON0003_DEST = 1
    val TESTDEPENDSON0003_ATTR = 1
  in
  (**
   * test case of dependsOn/isDependsOn (normal case)
   * <ol>
   *   <li>calls dependsOn.</li>
   *   <li>calls isDependsOn and verifies the return value indicates that
   *     there is a dependency with the attribute between the specified
   *     nodes.</li>
   *   <li>calls isDependsOn with src and destination reversed
   *     and verifies the return value indicates that
   *     there is no dependency of the opposite direction between the
   *     specified nodes.</li>
   * </ol>
   *)
  fun testDependsOn0003 () =
      let
        val graph = Testee.create TESTDEPENDSON0003_SIZE
      in
        Testee.dependsOn
        graph
        {
          src = TESTDEPENDSON0003_SRC,
          dest = TESTDEPENDSON0003_DEST,
          attr = TESTDEPENDSON0003_ATTR
        };
        assertEqualIsDependsOn
        (SOME TESTDEPENDSON0003_ATTR, true)
        (Testee.isDependsOn
         graph
         {
           src = TESTDEPENDSON0003_SRC,
           dest = TESTDEPENDSON0003_DEST
         });
        assertEqualIsDependsOn
        (NONE, false)
        (Testee.isDependsOn
         graph
         {
           src = TESTDEPENDSON0003_DEST,
           dest = TESTDEPENDSON0003_SRC
         });
        ()
      end
  end

  local
    fun testGetClosureBase dir (size, depends, startNode, expectedClosure) =
        let
          val graph = Testee.create size
          val _ =
              app
              (fn (src, dest) =>
                  Testee.dependsOn graph {src = src, dest = dest, attr =()})
              depends
          fun sortInts [] = []
            | sortInts (num :: nums) =
              let
                fun insert [] = [num]
                  | insert (num' :: nums') =
                    if num < num'
                    then num :: num' :: nums'
                    else num' :: (insert nums')
              in insert (sortInts nums) end
          val getClosureFun =
              if dir then Testee.getClosure else Testee.getClosureRev
        in
          Assert.assertEqualList
          Assert.assertEqualInt
          (sortInts expectedClosure)
          (sortInts(getClosureFun graph (fn _ => true, startNode)))
        end

    val testGetClosure =  testGetClosureBase true
    val testGetClosureRev =  testGetClosureBase false
  in

  (**
   *  tests the getClosure function with a node graph.
   * <ul>
   *   <li>the number of nodes: 1</li>
   *   <li>the length of dependency path: 0</li>
   *   <li>the number of dependency path: 0</li>
   * </ul>
   *)
  fun testGetClosure1001 () =
      (
        testGetClosure (1, [], 0, [0]);
        ()
      )
  
  (**
   *  tests the getClosure function with two nodes graph where is no
   * dependency.
   * <ul>
   *   <li>the number of nodes: 2</li>
   *   <li>the length of dependency path: 0</li>
   *   <li>the number of dependency path: 0</li>
   * </ul>
   *)
  fun testGetClosure2001 () =
      (
        testGetClosure (2, [], 0, [0]);
        ()
      )
  
  (**
   *  tests the getClosure function with two nodes graph where is a
   * dependency.
   * <ul>
   *   <li>the number of nodes: 2</li>
   *   <li>the length of dependency path: 1</li>
   *   <li>the number of dependency path: 1</li>
   * </ul>
   *)
  fun testGetClosure2002 () =
      (
        testGetClosure (2, [(0, 1)], 0, [0, 1]);
        testGetClosure (2, [(0, 1)], 1, [1]);
        ()
      )

  (**
   *  tests the getClosure function with two nodes graph which are mutual
   * dependencies between the nodes.
   * <ul>
   *   <li>the number of nodes: 2</li>
   *   <li>the length of dependency path: 1</li>
   *   <li>the number of dependency path: 2</li>
   * </ul>
   *)
  fun testGetClosure2003 () =
      (
        testGetClosure (2, [(0, 1), (1, 0)], 0, [0, 1]);
        testGetClosure (2, [(0, 1), (1, 0)], 1, [0, 1]);
        ()
      )

  (**
   *  tests the getClosure function with three nodes graph.
   * <ul>
   *   <li>the number of nodes: 3</li>
   *   <li>the length of dependency path: 1</li>
   *   <li>the number of dependency path: 1</li>
   * </ul>
   *)
  fun testGetClosure3001 () =
      (
        testGetClosure (3, [(0, 1)], 0, [0, 1]);
        testGetClosure (3, [(0, 1)], 1, [1]);
        testGetClosure (3, [(0, 1)], 2, [2]);
        ()
      )

  (**
   *  tests the getClosure function with three nodes graph.
   * <ul>
   *   <li>the number of nodes: 3</li>
   *   <li>the length of dependency path: 2</li>
   *   <li>the number of dependency path: 1</li>
   * </ul>
   *)
  fun testGetClosure3002 () =
      (
        testGetClosure (3, [(0, 1), (1, 2)], 0, [0, 1, 2]);
        testGetClosure (3, [(0, 1), (1, 2)], 1, [1, 2]);
        testGetClosure (3, [(0, 1), (1, 2)], 2, [2]);
        ()
      )

  (**
   *  tests the getClosure function with four nodes graph.
   * <ul>
   *   <li>the number of nodes: 4</li>
   *   <li>the length of dependency path: 2</li>
   *   <li>the number of dependency path: 2</li>
   * </ul>
   *)
  fun testGetClosure4001 () =
      (
        testGetClosure (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 0, [0, 1, 2, 3]);
        testGetClosure (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 1, [1, 3]);
        testGetClosure (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 2, [2, 3]);
        testGetClosure (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 3, [3]);
        ()
      )

  (********************)

  (**
   *  tests the getClosureRev function with a node graph.
   * <ul>
   *   <li>the number of nodes: 1</li>
   *   <li>the length of dependency path: 0</li>
   *   <li>the number of dependency path: 0</li>
   * </ul>
   *)
  fun testGetClosureRev1001 () =
      (
        testGetClosureRev (1, [], 0, [0]);
        ()
      )
  
  (**
   *  tests the getClosureRev function with two nodes graph where is no
   * dependency.
   * <ul>
   *   <li>the number of nodes: 2</li>
   *   <li>the length of dependency path: 0</li>
   *   <li>the number of dependency path: 0</li>
   * </ul>
   *)
  fun testGetClosureRev2001 () =
      (
        testGetClosureRev (2, [], 0, [0]);
        ()
      )
  
  (**
   *  tests the getClosureRev function with two nodes graph where is a
   * dependency.
   * <ul>
   *   <li>the number of nodes: 2</li>
   *   <li>the length of dependency path: 1</li>
   *   <li>the number of dependency path: 1</li>
   * </ul>
   *)
  fun testGetClosureRev2002 () =
      (
        testGetClosureRev (2, [(0, 1)], 0, [0]);
        testGetClosureRev (2, [(0, 1)], 1, [0, 1]);
        ()
      )

  (**
   *  tests the getClosureRev function with two nodes graph which are mutual
   * dependencies between the nodes.
   * <ul>
   *   <li>the number of nodes: 2</li>
   *   <li>the length of dependency path: 1</li>
   *   <li>the number of dependency path: 2</li>
   * </ul>
   *)
  fun testGetClosureRev2003 () =
      (
        testGetClosureRev (2, [(0, 1), (1, 0)], 0, [0, 1]);
        testGetClosureRev (2, [(0, 1), (1, 0)], 1, [0, 1]);
        ()
      )

  (**
   *  tests the getClosureRev function with three nodes graph.
   * <ul>
   *   <li>the number of nodes: 3</li>
   *   <li>the length of dependency path: 1</li>
   *   <li>the number of dependency path: 1</li>
   * </ul>
   *)
  fun testGetClosureRev3001 () =
      (
        testGetClosureRev (3, [(0, 1)], 0, [0]);
        testGetClosureRev (3, [(0, 1)], 1, [0, 1]);
        testGetClosureRev (3, [(0, 1)], 2, [2]);
        ()
      )

  (**
   *  tests the getClosureRev function with three nodes graph.
   * <ul>
   *   <li>the number of nodes: 3</li>
   *   <li>the length of dependency path: 2</li>
   *   <li>the number of dependency path: 1</li>
   * </ul>
   *)
  fun testGetClosureRev3002 () =
      (
        testGetClosureRev (3, [(0, 1), (1, 2)], 0, [0]);
        testGetClosureRev (3, [(0, 1), (1, 2)], 1, [0, 1]);
        testGetClosureRev (3, [(0, 1), (1, 2)], 2, [0, 1, 2]);
        ()
      )

  (**
   *  tests the getClosureRev function with four nodes graph.
   * <ul>
   *   <li>the number of nodes: 4</li>
   *   <li>the length of dependency path: 2</li>
   *   <li>the number of dependency path: 2</li>
   * </ul>
   *)
  fun testGetClosureRev4001 () =
      (
        testGetClosureRev (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 0, [0]);
        testGetClosureRev (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 1, [0, 1]);
        testGetClosureRev (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 2, [0, 2]);
        testGetClosureRev
            (4, [(0, 1), (0, 2), (1, 3), (2, 3)], 3, [0, 1, 2, 3]);
        ()
      )
  end

  local
    fun testSort (depends, expectedOrder) =
        let
          val graph = Testee.create (List.length expectedOrder)
        in
          app
          (fn (src, dest) =>
              Testee.dependsOn graph {src = src, dest = dest, attr =()})
          depends;
          Assert.assertEqualList
          Assert.assertEqualInt
          expectedOrder
          (Testee.sort graph (fn () => true))
    end
  in

  (**
   *  tests the sort function with a nodes graph without any dependency.
   *)
  fun testSort1001 () =
      (
        testSort ([], [0]);

        ()
      )

  (**
   *  tests the sort function with a nodes graph depending itself.
   *)
  fun testSort1002 () =
      (
        (* 0 -> 0 *)
        testSort ([(0, 0)], [0]);
        ()
      )

  (**
   *  tests the sort function with a two nodes graph where a nodes depends on
   * the other node.
   *)
  fun testSort2001 () =
      (
        (* 0 -> 1 *)
        testSort ([(0, 1)], [1, 0]);

        (* 1 -> 0 *)
        testSort ([(1, 0)], [0, 1]);

        ()
      )

  (**
   *  tests the sort function with a two nodes graph where they depend on
   * each other.
   *  The order of nodes in the result value of the sort function is not
   * defined if they depend each other, but the function must return some
   * value (not stuck).
   *)
  fun testSort2002 () =
      (
        (* 1 -> 0, 0 -> 1 *)
        testSort ([(1, 0), (0, 1)], [0, 1]);

        ()
      )
      handle Assert.Fail(Assert.NotEqualFailure _) => ();

  (**
   *  tests the sort function with a three nodes graph where two nodes depend
   * the other node.
   *)
  fun testSort3001 () =
      (
        (* {0,1} -> 2 *)
        testSort ([(0, 2), (1, 2)], [2, 0, 1]);
        testSort ([(1, 2), (0, 2)], [2, 0, 1]);

        (* {0,2} -> 1 *)
        testSort ([(0, 1), (2, 1)], [1, 0, 2]);
        testSort ([(2, 1), (0, 1)], [1, 0, 2]);

        (* {1,2} -> 0 *)
        testSort ([(1, 0), (2, 0)], [0, 1, 2]);
        testSort ([(2, 0), (1, 0)], [0, 1, 2]);

        ()
      )

  (**
   *  tests the sort function with a three nodes graph where a node depends
   * the other two nodes.
   *)
  fun testSort3002 () =
      (
        (* 0 -> {1,2} *)
        testSort ([(0, 1), (0, 2)], [1, 2, 0]);
        testSort ([(0, 2), (0, 1)], [1, 2, 0]);

        (* 1 -> {0,2} *)
        testSort ([(1, 0), (1, 2)], [0, 2, 1]);
        testSort ([(1, 2), (1, 0)], [0, 2, 1]);

        (* 2 -> {0,1} *)
        testSort ([(2, 0), (2, 1)], [0, 1, 2]);
        testSort ([(2, 1), (2, 0)], [0, 1, 2]);
        ()
      )

  (**
   *  tests the sort function with a three nodes graph where a node depends
   * the other two nodes of which the one node depends the other node.
   *)
  fun testSort3003 () =
      (
        (* 0 -> {1,2}, 1 -> 2 *)
        testSort ([(0, 1), (0, 2), (1, 2)], [2, 1, 0]);
        testSort ([(0, 1), (1, 2), (0, 2)], [2, 1, 0]);
        testSort ([(0, 2), (1, 2), (0, 1)], [2, 1, 0]);
        testSort ([(0, 2), (0, 1), (1, 2)], [2, 1, 0]);
        testSort ([(1, 2), (0, 1), (0, 2)], [2, 1, 0]);
        testSort ([(1, 2), (0, 2), (0, 1)], [2, 1, 0]);
        ()
     )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testDependsOn0001", testDependsOn0001),
        ("testDependsOn0002", testDependsOn0002),
        ("testDependsOn0003", testDependsOn0003),

        ("testGetClosure1001", testGetClosure1001),
        ("testGetClosure2001", testGetClosure2001),
        ("testGetClosure2002", testGetClosure2002),
        ("testGetClosure2003", testGetClosure2003),
        ("testGetClosure3001", testGetClosure3001),
        ("testGetClosure3002", testGetClosure3002),
        ("testGetClosure4001", testGetClosure4001),

        ("testGetClosureRev1001", testGetClosureRev1001),
        ("testGetClosureRev2001", testGetClosureRev2001),
        ("testGetClosureRev2002", testGetClosureRev2002),
        ("testGetClosureRev2003", testGetClosureRev2003),
        ("testGetClosureRev3001", testGetClosureRev3001),
        ("testGetClosureRev3002", testGetClosureRev3002),
        ("testGetClosureRev4001", testGetClosureRev4001),

        ("testSort1001", testSort1001),
        ("testSort1002", testSort1002),
        ("testSort2001", testSort2001),
        ("testSort2002", testSort2002),
        ("testSort3001", testSort3001),
        ("testSort3002", testSort3002),
        ("testSort3003", testSort3003)
      ]

  (***************************************************************************)

end