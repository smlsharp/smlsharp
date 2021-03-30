(**
 * @copyright (C) 2021 SML# Development Team.
 * @author OSAKA Satoshi
 * @version $Id: MatchData.sml,v 1.17 2008/02/21 02:58:41 bochao Exp $
 *)
structure MatchData = 
struct
local
  structure A = AbsynConst
  structure T = Types
  structure TC = TypedCalc
  structure BT = BuiltinTypes
in
  datatype kind = Bind | Match | Handle of T.varInfo
    
  type const = A.constant
  type conInfo = T.conInfo
  type exnCon = TC.exnCon

  structure ConstOrd : ORD_KEY = 
  struct
    type ord_key = const
    fun orderRadix StringCvt.BIN = 0
      | orderRadix StringCvt.OCT = 1
      | orderRadix StringCvt.DEC = 2
      | orderRadix StringCvt.HEX = 4
    fun compare (A.INT x, A.INT y) = IntInf.compare (x, y)
      | compare (A.WORD x, A.WORD y) = IntInf.compare (x, y)
      | compare (A.STRING s1, A.STRING s2) = String.compare (s1, s2)
      | compare (A.REAL r1, A.REAL r2) = String.compare (r1, r2)
      | compare (A.CHAR c1, A.CHAR c2) = Char.compare (c1, c2)
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
    type ord_key = conInfo * Types.ty list option * bool
    fun compare (({id=id1,...}, _, _) : ord_key, ({id=id2,...}, _, _) : ord_key) =
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
    type ord_key = exnCon * bool
    fun compare ((exnCon1, _) : ord_key, (exnCon2, _) : ord_key) =
        case (exnCon1, exnCon2) of
          (TC.EXN {id=id1,...}, TC.EXN{id=id2,...}) =>
          ExnID.compare(id1, id2)
        | (TC.EXEXN{path=path1,...},TC.EXEXN{path=path2,...}) =>
          Symbol.longsymbolCompare (path1,path2)
        | (TC.EXEXN _, TC.EXN _) => LESS
        | (TC.EXN _, TC.EXEXN _) => GREATER
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
  | VarPat of T.varInfo
  | ConstPat of const * T.ty
  | DataConPat of conInfo * T.ty list option * bool * pat * T.ty
  | ExnConPat of exnCon * bool * pat * T.ty
  | RecPat of (RecordLabel.label * pat) list * T.ty
  | LayerPat of pat * pat
  | OrPat of pat * pat

 type exp = branchId

  datatype rule
  = End of exp
  | ++ of pat * rule
  infixr ++

  type env = T.varInfo VarInfoEnv.map

  datatype tree
  = EmptyNode
  | LeafNode of exp * env
  | EqNode of T.varInfo * tree ConstMap.map * tree
  | DataConNode of T.varInfo * tree DataConMap.map * tree
  | ExnConNode of T.varInfo * tree ExnConMap.map * tree
  | RecNode of T.varInfo * RecordLabel.label * tree
  | UnivNode of T.varInfo * tree

  val unitExp =
      TC.TPCONSTANT {const=A.UNITCONST, ty=BT.unitTy, loc=Loc.noloc}

  val expDummy = unitExp
end
end
