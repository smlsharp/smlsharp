(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: AtomEnv.sml,v 1.8 2007/09/10 14:13:30 kiyoshiy Exp $
 *)
structure AtomEnv = struct

  open ANormal
  structure CT = ConstantTerm
  structure T = Types

  fun wordPairCompare ((x1,y1),(x2,y2)) =
      case Word32.compare (x1,x2) of
        GREATER => GREATER
      | EQUAL => Word32.compare(y1,y2)
      | LESS => LESS
                
  structure Atom_ord:ORD_KEY = struct 
    type ord_key = anexp
    fun compare (x,y) =
        case (x,y) of
          (ANCONSTANT {value=c1,...}, ANCONSTANT {value=c2,...}) =>
          CT.compare (c1,c2)
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

  structure Var_ord:ORD_KEY = struct 
    type ord_key = varInfo
    fun compare ({id=id1,...}:varInfo,{id=id2,...}:varInfo) = ID.compare(id1,id2)
  end

  structure AtomMap = BinaryMapMaker(Atom_ord)
  structure VarMap = BinaryMapMaker(Var_ord)


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
