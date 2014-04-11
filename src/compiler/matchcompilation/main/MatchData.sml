(**
 * @copyright (c) 2006, Tohoku University.
 * @author OSAKA Satoshi
 * @version $Id: MatchData.sml,v 1.17 2008/02/21 02:58:41 bochao Exp $
 *)
structure MatchData = 
struct
local
  structure A = Absyn
  structure T = Types
  structure TC = TypedCalc
  structure RC = RecordCalc
  structure BT = BuiltinTypes
in
  datatype kind = Bind | Match | Handle of RC.varInfo
    
  type const = Absyn.constant
  type conInfo = RC.conInfo
  type exnCon = RC.exnCon

  structure ConstOrd : ORD_KEY = 
  struct
    type ord_key = const
    fun orderRadix StringCvt.BIN = 0
      | orderRadix StringCvt.OCT = 1
      | orderRadix StringCvt.DEC = 2
      | orderRadix StringCvt.HEX = 4
    fun compareInt ({radix=r1, digits=d1}, {radix=r2, digits=d2}) =
        case Int.compare (orderRadix r1, orderRadix r2) of
          EQUAL => String.compare (d1, d2)
        | order => order
    fun compare (A.INT (x,_), A.INT (y,_)) = compareInt (x, y)
      | compare (A.WORD (x,_), A.WORD (y,_)) = compareInt (x, y)
      | compare (A.STRING (s1,_), A.STRING (s2,_)) = String.compare (s1, s2)
      | compare (A.REAL (r1,_), A.REAL (r2,_)) = String.compare (r1, r2)
      | compare (A.CHAR (c1,_), A.CHAR (c2,_)) = Char.compare (c1, c2)
      | compare (A.INT _, _) = LESS
      | compare (A.STRING _, A.REAL _) = LESS
      | compare (_, _) = GREATER
  end


  structure DataConOrd : ORD_KEY = 
   (* Ohori: I will double check to make sure that this is should be OK.
        structure TagOrd : ORD_KEY = 
         struct
          type ord_key = tag * bool
       fun compare ((i, _) : ord_key, (k, _) : ord_key) = 
           ID.compare (#id i, #id k)
     end
   *)
  struct
    type ord_key = conInfo * bool
    fun compare (({id=id1,...}, _) : ord_key, ({id=id2,...}, _) : ord_key) = 
        ConID.compare(id1,id2)
  end

(*
  structure ExnConOrd : ORD_KEY = 
   (* Ohori: I will double check to make sure that this is should be OK.
        structure TagOrd : ORD_KEY = 
         struct
          type ord_key = tag * bool
       fun compare ((i, _) : ord_key, (k, _) : ord_key) = 
           ID.compare (#id i, #id k)
     end
   *)
  struct
    type ord_key = exnCon * bool
    fun compare ((exnCon1, _) : ord_key, (exnCon2, _) : ord_key) = 
        case (exnCon1, exnCon2) of
          (RC.EXN {id=id1,...}, RC.EXN{id=id2,...}) =>
          ExnID.compare(id1, id2)
        | (RC.EXEXN{longsymbol=longsymbol1,...},RC.EXEXN{longsymbol=longsymbol2,...}) => 
          Symbol.longsymbolCompare(longsymbol1,longsymbol2)
        | (RC.EXEXN _, RC.EXN _) => LESS
        | (RC.EXN _, RC.EXEXN _) => GREATER
  end
*)
  structure ExnConOrd : ORD_KEY = 
   (* Ohori: I will double check to make sure that this is should be OK.
        structure TagOrd : ORD_KEY = 
         struct
          type ord_key = tag * bool
       fun compare ((i, _) : ord_key, (k, _) : ord_key) = 
           ID.compare (#id i, #id k)
     end
   *)
  struct
    local
      fun compPath (path1, path2) =
          case (path1, path2) of
            (nil,nil) => EQUAL
          | (nil, _ :: _) => LESS
          | (_::_, nil) => GREATER
          | (h1::tl1, h2::tl2) => 
            (case String.compare(h1,h2) of
               EQUAL => compPath(tl1,tl2)
             | ord => ord)
    in
      type ord_key = exnCon * bool
      fun compare ((exnCon1, _) : ord_key, (exnCon2, _) : ord_key) = 
          case (exnCon1, exnCon2) of
            (RC.EXN {id=id1,...}, RC.EXN{id=id2,...}) =>
            ExnID.compare(id1, id2)
          | (RC.EXEXN{path=path1,...},RC.EXEXN{path=path2,...}) => 
            compPath(path1,path2)
          | (RC.EXEXN _, RC.EXN _) => LESS
          | (RC.EXN _, RC.EXEXN _) => GREATER
    end
  end

  structure SSOrd : ORD_KEY = 
  struct
    type ord_key = string * string
    fun compare ((a1, l1), (a2, l2)) = 
        case String.compare (a1, a2)
	of EQUAL => String.compare (l1, l2)
         | ord => ord
  end

  structure ConstMap = BinaryMapFn (ConstOrd)
  structure DataConMap = BinaryMapFn (DataConOrd)
  structure ExnConMap = BinaryMapFn (ExnConOrd)
  structure SSMap = BinaryMapFn (SSOrd)

  type branchId = int

  datatype pat
  = WildPat of T.ty
  | VarPat of RC.varInfo
  | ConstPat of const * T.ty
  | DataConPat of conInfo * bool * pat * T.ty
  | ExnConPat of exnCon * bool * pat * T.ty
  | RecPat of (string * pat) list * T.ty
  | LayerPat of pat * pat
  | OrPat of pat * pat

 type exp = branchId

  datatype rule
  = End of exp
  | ++ of pat * rule
  infixr ++

  type env = RC.varInfo VarInfoEnv.map

  datatype tree
  = EmptyNode
  | LeafNode of exp * env
  | EqNode of RC.varInfo * tree ConstMap.map * tree
  | DataConNode of RC.varInfo * tree DataConMap.map * tree
  | ExnConNode of RC.varInfo * tree ExnConMap.map * tree
  | RecNode of RC.varInfo * string * tree
  | UnivNode of RC.varInfo * tree

  val unitExp =
      RC.RCCONSTANT {const=A.UNITCONST Loc.noloc, ty=BT.unitTy, loc=Loc.noloc}

  val expDummy = unitExp
end
end
