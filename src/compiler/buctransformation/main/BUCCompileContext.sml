(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCCompileContext.sml,v 1.5 2006/02/28 17:05:50 duchuu Exp $
 *)


structure BUCCompileContext :> BUCCOMPILECONTEXT = struct

  structure BC = BUCCalc
  structure BU = BUCUtils
  structure T = Types
  structure TU = TypesUtils
  structure VEnv = ID.Map

  datatype bookmark = SIZE of int | TAG of int | FRAMEBITMAP of BC.id

  structure bookmark_ord:ordsig = struct 
    type ord_key = bookmark

    fun compare (x,y) =
        case (x,y) of
          (SIZE tid1,SIZE tid2) => Int.compare(tid1,tid2)
        | (SIZE _,_) => LESS
        | (TAG _, SIZE _) => GREATER
        | (TAG tid1, TAG tid2) => Int.compare(tid1,tid2)
        | (TAG _, _) => LESS
        | (FRAMEBITMAP _, SIZE _) => GREATER
        | (FRAMEBITMAP _, TAG _) => GREATER
        | (FRAMEBITMAP id1, FRAMEBITMAP id2) => ID.compare(id1,id2)
  end

  structure Bookmark = BinaryMapFn(bookmark_ord)

  type context =
       {
        tyEnv :  T.btvEnv list,
        varEnv : BC.varInfo VEnv.map,
        (* replicate data for optimization*)
        bookmarks : (BC.id Bookmark.map) ref
       }

  exception VAR_FOUND of BC.varInfo
  exception TID_FOUND

  (******************************************************)
  (* bookmark utilities*)

  fun setBookmark ({bookmarks,...} : context, bookmark, {id,...}: BC.varInfo) =
      bookmarks := Bookmark.insert(!bookmarks,bookmark,id)

  fun getBookmark ({varEnv,bookmarks,...}:context, bookmark) = 
      case Bookmark.find(!bookmarks,bookmark) of 
        SOME id =>
        (
         case VEnv.find(varEnv,id) of
           SOME varInfo => SOME varInfo
         | _ => NONE
        )
      | _ => NONE

  (******************************************************)
  (*Type utilities*)

  fun isBoundTid (btvEnv, tid) = 
      (case IEnv.find(btvEnv,tid) of SOME _ => true | _ => false)

  fun isBoundTidList (btvEnv,[]) = false
    | isBoundTidList (btvEnv,h::t) =
      isBoundTid(btvEnv,h) orelse isBoundTidList(btvEnv,t)

  (* only for compact types and pad types*)
  fun isBoundTy (btvEnv,T.BOUNDVARty tid) = isBoundTid(btvEnv,tid)
    | isBoundTy (btvEnv,T.PADCONDty(_,tid)) = isBoundTid(btvEnv,tid)
    | isBoundTy (btvEnv,_) = false
  
  fun isBoundTyList (btvEnv,[]) = false
    | isBoundTyList (btvEnv,h::t) =
      (isBoundTy(btvEnv,h)) orelse (isBoundTyList(btvEnv,t))

  (* only for type of extra variables (bitmap, offset, tag, size, pad) *)
  fun isBound (btvEnv,T.BITMAPty tyList) =
      isBoundTyList(btvEnv,tyList)
    | isBound (btvEnv,T.FRAMEBITMAPty tidList) =
      isBoundTidList(btvEnv,tidList)
    | isBound (btvEnv,T.OFFSETty tyList) =
      isBoundTyList(btvEnv,tyList)
    | isBound (btvEnv,T.PADty tyList) =
      isBoundTyList(btvEnv,tyList)
    | isBound (btvEnv,T.PADCONDty (tyList,tid)) =
      isBoundTyList(btvEnv,(T.BOUNDVARty tid)::tyList)
    | isBound (btvEnv,T.SIZEty tid) = isBoundTid(btvEnv,tid)
    | isBound (btvEnv,T.TAGty tid) = isBoundTid(btvEnv,tid)
    | isBound (btvEnv,ty) = false

  fun isBoundTypeVariable ({tyEnv,...}:context,tid) =
      isBoundTid(hd tyEnv,tid)

  (*********************************************************)
  (*searching utilities *)

  fun findVariable ({varEnv,...} : context,id) = VEnv.find(varEnv,id)

  fun lookup (varEnv, id) =
      case VEnv.find(varEnv,id) of
        SOME varInfo => varInfo
      | NONE => raise Control.Bug "lookup: id not found"

  fun getFrameBitmapIDs ({bookmarks,...} : context) =
      Bookmark.foldli
          (fn (bookmark,id,S) => 
              case bookmark of
                FRAMEBITMAP _ => ID.Set.add(S,id)
              | _ => S
          )
          (ID.Set.empty)
          (!bookmarks)

  fun listFreeVariables ({varEnv,...}:context) =
      VEnv.foldl
          (fn (varInfo as {varKind,...},L) =>
              case varKind of 
                BC.FREE => varInfo::L
              | _ => L
          )
          []
          varEnv

  fun listLocalBitmapVariables ({varEnv,...}:context) =
      VEnv.foldl
          (fn (v as {ty,varKind,...},L) =>
              case (ty,varKind) of 
                (T.BITMAPty _,BC.LOCAL) => v::L
              | (T.FRAMEBITMAPty _,BC.LOCAL) => v::L
              | _ => L
          )
          []
          varEnv

  fun listExtraLocalVariables ({varEnv,...}:context) =
      VEnv.foldl
          (fn (v as {ty,varKind,...},L) =>
              case (ty,varKind) of 
                (T.BITMAPty _,BC.LOCAL) => v::L
              | (T.FRAMEBITMAPty _,BC.LOCAL) => v::L
              | (T.OFFSETty _,BC.LOCAL) => v::L
              | (T.PADty _,BC.LOCAL) => v::L
              | (T.PADCONDty _,BC.LOCAL) => v::L
              | _ => L
          )
          []
          varEnv

  fun lookupSize (context,tid) = 
      case getBookmark(context,SIZE tid) of
        SOME varInfo => varInfo
      | _ => raise Control.Bug ("size variable not found" ^ (Int.toString tid))

  fun lookupTag (context,tid) = 
      case getBookmark(context,TAG tid) of
        SOME varInfo => varInfo
      | _ => raise Control.Bug "tag variable not found"

  (* only for finding extra variables*)
  fun findByTy (context,ty ) =
      case ty of 
        T.SIZEty tid => getBookmark(context,SIZE tid)
      | T.TAGty tid => getBookmark(context,TAG tid)
      | _ => NONE

  fun varKindOf (btvEnv,ty) =
      if isBound (btvEnv,ty) 
      then
        case ty of
          T.SIZEty _ => BC.ARG
        | T.TAGty _ => BC.ARG
        | _ => BC.LOCAL
      else BC.FREE
           
  (******************************************************************)
  (*inserting and updating utilities*)

  (* insert a varinfo into the context *)
  fun insertVariable 
          (
           {tyEnv,varEnv,bookmarks} : context,
           varInfo as {id,ty,...}
          ) =
      let
        val _ =
            case ty of 
              T.SIZEty tid => bookmarks := (Bookmark.insert(!bookmarks,SIZE tid,id))
            | T.TAGty tid => bookmarks := (Bookmark.insert(!bookmarks,TAG tid,id))
            | _ => ()
      in
        {
         tyEnv = tyEnv,
         varEnv = VEnv.insert(varEnv,id,varInfo),
         bookmarks = bookmarks
        }
      end
   
  (* insert a set of varinfo in to the context *)
  fun insertVariables (context,varInfoList) =
      foldl 
          (fn (varInfo,S) => insertVariable(S,varInfo))
          context
          varInfoList

  (* update varKind only*)
  fun updateVariable 
          (
           context as {tyEnv,varEnv,bookmarks},
           varInfo as {id,...}
          ) =
      case VEnv.find(varEnv,id) of
        SOME _ => 
        {
         tyEnv = tyEnv,
         varEnv = VEnv.insert(varEnv,id,varInfo),
         bookmarks = bookmarks
        }
      | NONE => context : context

  fun updateVariables (context,varInfoList) =
      foldl 
          (fn (varInfo,S) => updateVariable(S,varInfo))
          context
          varInfoList

  fun updateVarKind (context as {tyEnv,varEnv,bookmarks},id,varKind) =
      case VEnv.find(varEnv,id) of
        SOME {ty,displayName,...} =>
        {
         tyEnv = tyEnv,
         varEnv = VEnv.insert(varEnv,id,{id=id,displayName=displayName,ty=ty,varKind=varKind}),
         bookmarks = bookmarks
        }
      | _ => context : context

  (* merge a varinfo to the context *)
  fun mergeVariable 
          (
           context as {tyEnv,varEnv,...},
           varInfo as {id,displayName,ty,varKind}
          ) =
      case VEnv.find(varEnv,id) of
        SOME varInfo' => (context,varInfo')
      | _ =>
        (
         case findByTy(context,ty) of
           SOME varInfo' => (context,varInfo')
         | _ =>
           let
             val varInfo' = 
                 {
                  id = id,
                  displayName = displayName,
                  ty = ty,
                  varKind = varKindOf (List.hd tyEnv,ty)
                 }
           in
             (insertVariable(context,varInfo'),varInfo')
           end
        )

  (* merge a set of varinfo into the context *)
  fun mergeVariables (context,varInfoList) =
      foldr
          (fn (varInfo,(C,L)) =>
              let
                val (C',varInfo') = mergeVariable(C,varInfo)
              in 
                (C',varInfo'::L)
              end
          )
          (context,[])
          varInfoList

  (**************************************************************)

  fun makeContext tyEnv = 
      {
       tyEnv = tyEnv,
       varEnv = (VEnv.empty) : BC.varInfo VEnv.map,
       bookmarks = ref(Bookmark.empty : (BC.id Bookmark.map))
      }

  fun getTyEnv ({tyEnv,...} : context) = tyEnv

  fun prepareFunctionContext ({tyEnv,...} : context, btvEnv, argList) =
      let
        val argList = map (BU.convertVarInfo BC.ARG) argList
        val tidList = IEnv.listKeys btvEnv
        val tagArgList = map (fn tid => BU.newVar(T.TAGty tid,BC.ARG)) tidList
        val sizeArgList =
            if !Control.enableUnboxedFloat
            then map (fn tid => BU.newVar(T.SIZEty tid,BC.ARG)) tidList
            else []
        val argList' = tagArgList @ sizeArgList @ argList
        val context' = makeContext (btvEnv::tyEnv)
        val context' = insertVariables(context',argList')
      in
        (context',argList')
      end

end
