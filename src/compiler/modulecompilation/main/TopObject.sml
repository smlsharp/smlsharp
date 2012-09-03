(**
 * Top objects
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TopObject.sml,v 1.37 2006/02/28 01:22:50 bochao Exp $
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
        fun getPageSize () =
            !Control.pageSizeOfGlobalArray

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
                
        (* shared by 3 top arrays *)
        val initialFreeGlobalArrayIndex = 0w3 : BT.UInt32 

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

