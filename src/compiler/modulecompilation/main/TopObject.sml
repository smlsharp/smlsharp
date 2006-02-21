(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Top objects
 * @author Liu Bochao
 * @version $Id: TopObject.sml,v 1.34 2006/02/18 04:59:24 ohori Exp $
 *)
structure TopObject =
struct
   local
        structure TFC = TypedFlatCalc
        structure T = Types 
        structure ITC = InitialTypeContext
        structure SE = StaticEnv
        structure BT = BasicTypes
   in
        type  pageType = int

        val BOXED_PAGE_TYPE = 0
        val ATOM_PAGE_TYPE = 1 
        val DOUBLE_PAGE_TYPE = 2
                               
        type pageArrayIndex = BT.UInt32
        type offset = int
        type globalIndex = pageType * pageArrayIndex * offset
          
        (**** IndexMap ********)
        val  pageSize = 1024
        type indexMap = 
             (* a map from unique id to its index *)
             (
              string *     (* displayName for debugging *)
              globalIndex
             ) ID.Map.map 

        type freeEntryPointer = 
             (* from PAGE_TYPE to freeEntry of that PAGE_TYPE *)
             (pageArrayIndex * offset) IEnv.map

        val emptyIndexMap = ID.Map.empty : indexMap
        val initialIndexMap = emptyIndexMap 

        val TOP_BOXED_PREFIX = "$TOPBOXEDARRAY$"
        val TOP_ATOM_PREFIX = "$TOPATOMARRAY$"
        val TOP_DOUBLE_PREFIX = "$TOPDOUBLEARRAY$"


        val initialFreeEntryPointer = 
            IEnv.insert
              (
               (IEnv.insert
                 (
                  (IEnv.singleton (BOXED_PAGE_TYPE,(0w0:BT.UInt32, 0))),
                  ATOM_PAGE_TYPE,(0w1:BT.UInt32,0)
                 )
               ),
               DOUBLE_PAGE_TYPE,(0w2:BT.UInt32,0)
              )

        val globalPageArrayIndex = ref 0w3 : BT.UInt32 ref

        (******* Top Array  Default Value *******)
(*        fun refConPathInfoToConInfo {funtyCon, name, strpath, tag, ty, tyCon} =
            {
             funtyCon = funtyCon,
             displayName = name,
             tag = tag,
             ty = ty, 
             tyCon = tyCon
             }
        val DEFAULT_ATOM_VALUE = 
            TFC.TFPCAST(TFC.TFPCONSTANT(T.INT(0), Loc.noloc), 
                        T.ATOMty, 
                        Loc.noloc)

        val DEFAULT_DOUBLE_VALUE = 
            TFC.TFPCAST(TFC.TFPCONSTANT(T.REAL("0.0"), Loc.noloc), 
                        T.DOUBLEty, 
                        Loc.noloc)

        val DEFAULT_BOXED_VALUE = 
          TFC.TFPCAST(
                      TFC.TFPCONSTRUCT
                      {
                       con = refConPathInfoToConInfo (ITC.refCon),
                       instTyList = [T.ATOMty],
                       argExpOpt=SOME DEFAULT_ATOM_VALUE,
                       loc=Loc.noloc
                       },
                      T.BOXEDty,
                      Loc.noloc
                      )
                      

        (**** ArrayType **************)
        val BOXED_ARRAY_TYPE = 
            T.CONty{tyCon = SE.arrayTyCon, args =  [T.BOXEDty]}
        val ATOM_ARRAY_TYPE = 
            T.CONty{tyCon = SE.arrayTyCon, args =  [T.ATOMty]}
        val DOUBLE_ARRAY_TYPE = 
            T.CONty{tyCon = SE.arrayTyCon, args =  [T.DOUBLEty]}
*)
        (*******utilities*********)
        fun convertTyToPagetype ty = 
            case TypesUtils.compactTy ty of
              T.BOXEDty => BOXED_PAGE_TYPE
            | T.ATOMty => ATOM_PAGE_TYPE
            | T.DOUBLEty => DOUBLE_PAGE_TYPE
            | _ => raise Control.Bug "invalid Page Type"
                         
        fun getPageNameFromIndex (pageTy, pageArrayIndex, offset) =
            case pageTy of
              0 => TOP_BOXED_PREFIX ^ (UInt32.toString pageArrayIndex)
            | 1 => TOP_ATOM_PREFIX ^ (UInt32.toString pageArrayIndex)
            | 2 => TOP_DOUBLE_PREFIX ^ (UInt32.toString pageArrayIndex)
            | _ => raise Control.Bug "invalid page type"

(*        fun getArrayTypeFromIndex (pageTy,pageArrayIndex,offset) =
            case pageTy of
              0 => BOXED_ARRAY_TYPE
            | 1 => ATOM_ARRAY_TYPE
            | 2 => DOUBLE_ARRAY_TYPE
            | _ => raise Control.Bug "invalid page type"

                         
        fun pageDefaultValue (pageTy,pageArrayIndex,offset) =
            case pageTy of
              0 => DEFAULT_BOXED_VALUE
            | 1 => DEFAULT_ATOM_VALUE
            | 2 => DEFAULT_DOUBLE_VALUE
            | _ => raise Control.Bug "invalid page type"
*)                         
        fun pageElemTy (pageTy,pageArrayIndex,offset) =
            case pageTy of
              0 => T.BOXEDty
            | 1 => T.ATOMty
            | 2 => T.DOUBLEty
            | _ => raise Control.Bug "invalid page type"
                         
        fun getPageTy (pageTy,pageNo,offset) = pageTy
        fun getPageArrayIndex (pageTy, pageArrayIndex, offset) = pageArrayIndex
        fun getOffset (pageTy,pageNo,offset) = offset

        fun mergeIndexMap { 
                           newIndexMap = newIndexMap,                                
                           oldIndexMap = oldIndexMap
                          }
            = ID.Map.unionWith #1 (newIndexMap,oldIndexMap)

   end            
end

