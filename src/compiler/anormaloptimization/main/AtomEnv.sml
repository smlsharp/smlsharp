(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: AtomEnv.sml,v 1.4 2006/02/28 16:10:59 kiyoshiy Exp $
 *)
structure AtomEnv = struct

  open ANormal
  structure T = Types

  fun wordPairCompare ((x1,y1),(x2,y2)) =
      case Word32.compare (x1,x2) of
        GREATER => GREATER
      | EQUAL => Word32.compare(y1,y2)
      | LESS => LESS
                
  fun constantCompare (x,y) = 
      case (x,y) of
        (T.INT i1, T.INT i2) => Int32.compare(i1, i2)
      | (T.INT _, _) => LESS
      | (T.WORD _,T.INT _) => GREATER
      | (T.WORD w1,T.WORD w2) => Word32.compare(w1,w2)
      | (T.WORD w1,_) => LESS
      | (T.STRING _, T.INT _) => GREATER
      | (T.STRING _, T.WORD _) => GREATER
      | (T.STRING s1, T.STRING s2) => String.compare (s1, s2)
      | (T.STRING _, _) => LESS
      | (T.REAL r1, T.INT _) => GREATER
      | (T.REAL r1, T.WORD _) => GREATER
      | (T.REAL r1, T.STRING _) => GREATER
      | (T.REAL r1, T.REAL r2) => String.compare(r1, r2)
      | (T.REAL r1, _) => LESS
      | (T.CHAR _, T.INT _) => GREATER
      | (T.CHAR _, T.WORD _) => GREATER
      | (T.CHAR _, T.STRING _) => GREATER
      | (T.CHAR _, T.REAL _) => GREATER
      | (T.CHAR c1, T.CHAR c2) => Char.compare(c1,c2)
                                  
  structure Atom_ord:ordsig = struct 
    type ord_key = anexp
    fun compare (x,y) =
        case (x,y) of
          (ANCONSTANT {value=c1,...}, ANCONSTANT {value=c2,...}) =>
          constantCompare (c1,c2)
        | (ANCONSTANT _, _) =>  LESS

        | (ANENVACC _,ANCONSTANT _ ) => GREATER
        | (ANENVACC {nestLevel=n1, offset = i1,...},ANENVACC {nestLevel=n2, offset = i2,...}) => 
          wordPairCompare((n1,i1),(n2,i2))
        | (ANENVACC _,_ ) => LESS

        | (ANENVACCINDIRECT _,ANCONSTANT _ ) => GREATER
        | (ANENVACCINDIRECT _,ANENVACC _ ) => GREATER
        | (ANENVACCINDIRECT {nestLevel=n1,indirectOffset=i1,...},
           ANENVACCINDIRECT {nestLevel=n2,indirectOffset=i2,...}) => 
          wordPairCompare((n1,i1),(n2,i2))
        | (ANENVACCINDIRECT _, _) => LESS

        | (ANGETGLOBALVALUE _,ANCONSTANT _) => GREATER
        | (ANGETGLOBALVALUE _,ANENVACC _) => GREATER
        | (ANGETGLOBALVALUE _,ANENVACCINDIRECT _) => GREATER
        | (ANGETGLOBALVALUE{arrayIndex=w11,offset=w12,...},ANGETGLOBALVALUE{arrayIndex=w21,offset=w22,...}) =>
          wordPairCompare((w11,w12),(w21,w22))

        | _ =>  raise Control.Bug "invalid atomEnv"
  end

  structure Var_ord:ordsig = struct 
    type ord_key = varInfo
    fun compare ({id=id1,...}:varInfo,{id=id2,...}:varInfo) = ID.compare(id1,id2)
  end

  structure AtomMap = BinaryMapFn(Atom_ord)
  structure VarMap = BinaryMapFn(Var_ord)


  (*****************************************************************************************)

  type atomEnv = 
       {
        atomMap : varInfo AtomMap.map, 
        varMap : anexp VarMap.map,
        aliases : anexp VarMap.map 
       }

  val empty = {atomMap = AtomMap.empty,varMap = VarMap.empty, aliases = VarMap.empty} : atomEnv

  fun addAlias ({atomMap,varMap,aliases} : atomEnv,varInfo,exp) =
      {
       atomMap = atomMap,
       varMap = varMap,
       aliases = VarMap.insert(aliases,varInfo,exp)
      }

  fun addAtom ({atomMap,varMap,aliases} : atomEnv,varInfo,exp) =
      {
       atomMap = AtomMap.insert(atomMap,exp,varInfo),
       varMap = VarMap.insert(varMap,varInfo,exp),
       aliases = aliases
      }

  fun isAtom exp =
      case exp of
        ANCONSTANT _ => true
      | ANENVACC _ => true
      | ANENVACCINDIRECT _ => true
      | ANGETGLOBALVALUE _ => true
      | _ => false

  fun findAtom ({atomMap,varMap,aliases} : atomEnv,exp) =
      AtomMap.find(atomMap,exp)

  fun findVar ({atomMap,varMap,aliases} : atomEnv,varInfo) =
      VarMap.find(varMap,varInfo)

  fun findAlias ({atomMap,varMap,aliases} : atomEnv,varInfo) =
      VarMap.find(aliases,varInfo)

end
