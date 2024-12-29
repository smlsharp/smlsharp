(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure UnionFind =
struct

  datatype 'a node_state = ROOT of word * 'a | NODE of 'a node
  withtype 'a node = 'a node_state ref

  fun new x = ref (ROOT (0w1, x))

  fun equal (x : 'a node, y : 'a node) = x = y

  (* path halving *)
  fun walk (c as ref (ROOT x)) = (c, x)
    | walk (c as ref (NODE (p as ref (ROOT x)))) = (p, x)
    | walk (c as ref (NODE (p as ref (s as NODE g)))) = (c := s; walk g)

  fun find node = case walk node of (_, (_, value)) => value

  fun size node = case walk node of (_, (count, _)) => Word.toIntX count

  fun same (node1, node2) = #1 (walk node1) = #1 (walk node2)

  fun union merge (node1, node2) =
      let
        val (root1, (size1, value1)) = walk node1
        val (root2, (size2, value2)) = walk node2
      in
        (* union by size *)
        if root1 = root2 then true
        else if size1 <= size2
        then (root1 := ROOT (size1 + size2, merge (value1, value2));
              root2 := NODE root1;
              false)
        else (root2 := ROOT (size1 + size2, merge (value2, value1));
              root1 := NODE root2;
              false)
      end

  fun update merge (node, newValue) =
      let
        val (root, (size, value)) = walk node
      in
        root := ROOT (size, merge (value, newValue))
      end

end
