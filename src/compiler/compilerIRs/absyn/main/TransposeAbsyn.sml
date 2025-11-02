(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure TransposeAbsyn =
struct
  structure T = Token

  type node = {id : int, node : AbsynNode.node}
  type ancestors = node list
  type leaf = Token.token * (Loc.at * Loc.at) * ancestors

  type input = Token.token * (Loc.at * Loc.at)
  type cursor = {result : leaf snoc, count : int, input : input list}

  fun posInt Loc.NOPOS = ~1
    | posInt (Loc.POS {pos = Loc.EOF, ...}) = ~1
    | posInt (Loc.POS {pos = Loc.AT {token, ...}, ...}) = token

  fun enter (cursor as {count, ...} : cursor) node =
      (cursor # {count = count + 1}, {id = count, node = node})

  fun shift path (cursor as {result, ...} : cursor) (token, loc) input =
      let
        val path = case token of T.COMMENT => nil | T.EOF => nil | _ => path
      in
        cursor # {result = result ::> (token, loc, path), input = input}
      end

  fun goto path (cursor as {input = nil, ...}) left = cursor
    | goto path (cursor as {input = h :: t, ...}) left =
      case h of
        (_, (Loc.EOF, _)) => cursor
      | (_, (Loc.AT {token = i, ...}, _)) =>
        if i >= left then cursor else goto path (shift path cursor h t) left

  fun fill path (cursor as {input = nil, ...}) right = cursor
    | fill path (cursor as {input = h :: t, ...}) right =
      case h of
        (_, (Loc.EOF, _)) => cursor
      | (_, (Loc.AT {token = i, ...}, _)) =>
        if i > right then cursor else fill path (shift path cursor h t) right

  fun walk path cursor endPos (node :: nodes) =
      let
        val (left, right) = AbsynNode.getLoc node
        val cursor = goto path cursor (posInt left)
        val (cursor, parent) = enter cursor node
        val children = AbsynNode.getChildren node
        val cursor = walk (parent :: path) cursor (posInt right) children
      in
        walk path cursor endPos nodes
      end
    | walk path cursor endPos nil = fill path cursor endPos

  fun toLeaf (token, loc) : leaf = (token, loc, nil)

  fun generate (input, Absyn.EOF) = Snoc.map toLeaf input
    | generate (input, Absyn.UNIT compileUnit) =
      let
        val cursor = {result = NIL, count = 0, input = Snoc.toList input}
        val node = AbsynNode.COMPILE_UNIT compileUnit
        val {result, input, ...} = walk nil cursor ~1 [node]
      in
        Snoc.toList (Snoc.mapAppend toLeaf (result, input))
      end

end
