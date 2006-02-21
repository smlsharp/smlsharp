(**
 * Copyright (c) 2006, Tohoku University.
 *
 * misc utilities.
 * ToDo : It is better to move members of this strucutre to other more
 * specific modules.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Utility.sml,v 1.13 2006/02/18 04:59:26 ohori Exp $
 *)
structure Utility = 
struct

  (***************************************************************************)

  structure A = Absyn
  structure BF = SMLFormat.BasicFormatters
  structure FE = SMLFormat.FormatExpression
  structure IT = InitialTypeContext
  structure P = Path
  structure PE = PatternCalc
  structure PP = SMLFormat
  structure SE = StaticEnv
  structure TC = TypeContext
  structure TP = TypedCalc
  structure TPU = TypedCalcUtils
  structure TU = TypesUtils
  structure TY = Types

  (***************************************************************************)

  val spaceIndicator = FE.Indicator{space = true, newline = NONE}
  val ns_1_Indicator =
      FE.Indicator
      {space = false, newline = SOME{priority = FE.Preferred 1}}
  val s_1_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Preferred 1}}
  val s_2_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Preferred 2}}
  val s_d_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Deferred}}

  (***************************************************************************)

  (** generate a fresh variable ID *)
  fun makeVarName () = Vars.newTPVarName()

  (**
   * inserts a separator between elements of a list.
   * Each element of the list is itself a list.
   *)
  fun interleave separator [element] = [element]
    | interleave separator [] = []
    | interleave separator (head :: tail) =
      head :: [separator] @ (interleave separator tail)

  (** convert a list of pairs of value into SEnv *)
  fun listToTupleSEnv values =
      let
        val keys =
            List.tabulate
                (List.length values, fn index => Int.toString (index + 1))
      in
        foldr
            (fn ((key, value), map) => SEnv.insert (map, key, value))
            SEnv.empty
            (ListPair.zip (keys, values))
      end

  (**
   * convert a conPathInfo to local.
   *)
  fun makeConPathInfoLocal
          {name, strpath, funtyCon, ty, tag, tyCon} : TY.conPathInfo =
      {
        name = name,
        strpath = P.NilPath,
        funtyCon = funtyCon,
        ty = ty ,
        tag = tag,
        tyCon = tyCon
      } : TY.conPathInfo

  (**
   * converts a conInfo to a conPathInfo.
   * strpath is set to NilPath.
   *)
  fun conInfoToConPathInfo {name, funtyCon, ty, tag, tyCon} : TY.conPathInfo =
      {
        name = name,
        strpath = P.NilPath,
        funtyCon = funtyCon,
        ty = ty ,
        tag = tag,
        tyCon = tyCon
      } : TY.conPathInfo

  (**
   * converts a varPathInfo to a varInfo.
   *)
  fun varPathInfoToVarInfo {name, strpath, ty} = {name = name, ty = ty} 

  (**
   * converts a varInfo to a varPathInfo.
   * strpath is set to NilPath.
   *)
  fun varInfoToVarPathInfo ({name, ty}) =
      {name = name, ty = ty, strpath = P.NilPath} : TY.varPathInfo

(*
  fun pathIDToString path =
      case path of
        P.NilPath => ""
      | P.Pdot(id, name, P.NilPath) => id
      | P.Pdot(id, name, path) => id ^ "." ^ (pathIDToString path)
*)

  (**
   * make a string from a path.
   * This function skips the dummy top structure name.
   *)
  fun pathToString path = P.pathToString (P.hideTopStructure path)

  fun pathNameToString (path, name) =
      case P.hideTopStructure path of
        P.NilPath => name
      | path => (pathToString path) ^ "." ^ name

  (**
   * translate absolute path of tyCon to relative path based on the
   * currentPath.
   *)
  fun makePathOfTyConRelative currentPath (tyCon : TY.tyCon) =
      let
        val (_, relativePath) = 
            P.removeCommonPrefix (currentPath, #strpath tyCon)
        val newTyCon = 
            {
              name = #name tyCon,
              strpath = relativePath,
	      abstract = #abstract tyCon,
              tyvars = #tyvars tyCon,
              id = #id tyCon,
              eqKind = #eqKind tyCon,
              boxedKind = #boxedKind tyCon,
              datacon = #datacon tyCon
            }
      in
(*
print ("makePathOfTyConRelative: \n");
print ("  requested tycon: \n");
print ("      strpath = " ^ (P.pathToString (#strpath tyCon)) ^ "\n");
print ("      name = " ^ (#name tyCon) ^ "\n");
print ("  current path: " ^ (P.pathToString currentPath) ^ "\n");
print ("  relatived tycon: \n");
print ("      strpath = " ^ (P.pathToString relativePath) ^ "\n");
*)
        newTyCon : TY.tyCon 
      end

  (** true if two tyCons are the same. *)
  fun isEqualTyCon(left : TY.tyCon, right : TY.tyCon) =
      #id left = #id right andalso #name left = #name right

  fun tySpecToTyCon 
          ({name, strpath, id, tyvars, eqKind, boxedKind, ...}
           : TY.tySpec) =
      let
        val tyCon =
            {
              name = name,
              strpath = strpath,
	      abstract = false,
              tyvars = tyvars,
              id = id,
              eqKind = ref eqKind,
              boxedKind = ref boxedKind,
              datacon = ref SEnv.empty
            }
      in tyCon end

  (** perform union operation on a list of contexts. *)
  fun unionContexts [] = TC.emptyContext
    | unionContexts (context :: contexts) =
      foldl TC.mergeContexts context contexts

  (** translate absolute paths of tyCons occurring in a ty into relative. *)
  fun makePathOfTyRelative currentPath ty =
      TypeTransducer.mapTyPostOrder
          (fn ty =>
              case ty of
                TY.CONty {tyCon, args} =>
                let val newTyCon = makePathOfTyConRelative currentPath tyCon
                in TY.CONty {tyCon = newTyCon, args = args}
                end
              | _ => ty)
          ty

  fun getRealTy (TY.TYVARty(ref (TY.SUBSTITUTED ty))) = getRealTy ty
    | getRealTy ty = ty

  fun decompFunctionType arity ty =
      let
        fun decomp 0 (TY.FUNMty([argTy], resultTy)) argTys =
            (List.rev argTys, argTy, resultTy)
          | decomp n (TY.FUNMty([argTy], ty)) argTys =
            decomp (n - 1) ty (argTy :: argTys)
          | decomp n (TY.FUNMty(_, ty)) argTys =
            raise Control.Bug "multiple argument function in printer gen"
      in
        decomp arity ty []
      end

  fun generalize ty =
      let
        val {boundEnv, removedTyIds} =
            TU.generalizer (ty, SEnv.empty, SEnv.empty)
      in
        if 0 = IEnv.numItems boundEnv
        then ty
        else TY.POLYty{boundtvars = boundEnv, body = ty}
      end

  (**
   * instantiates an expression into an expression of monomorphic type if it is
   * polymorphic type.
   * <p>
   *  If an exp obtained by decompositon in pattern match has a polymorphic
   * type, it should be instantiated to a monotype exp before a formatter is
   * applied to it.
   * </p>
   * <p>
   * This function should be called to generate an application of formatter to
   * <ul>
   *   <li>element of tuple and record</li>
   *   <li>argument of constructor</li>
   * </ul>
   * </p>
   * @params (exp, ty)
   * @param exp an expression
   * @param ty the type of the exp
   * @return (monotypeExp, monotype)
   *)
  fun instantiateExp (exp, ty as TY.POLYty{body, boundtvars}) =
      let
        val loc = TPU.getLocOfExp exp
        val (monoTy, argTys) =
            TU.instantiate {body = body, boundtvars = boundtvars}
      in
        (TP.TPTAPP{exp=exp, expTy=ty, instTyList=IEnv.listItems argTys, loc=loc}, monoTy)
      end
    | instantiateExp (exp, ty) = (exp, ty)

  fun isTupleFields fieldsMap =
     let
       val fields = SEnv.listItemsi fieldsMap
       fun isNumeric index nil = true
         | isNumeric index ((label, _) :: tail) = 
           (case Int.fromString label  of
              SOME k => if k = index then isNumeric (index + 1) tail else false
            | _ => false)
     in isNumeric 1 fields end

  val formatterNamePrefix = "format_"

  (** add a tyCon to a context. *)
  fun bindTyCon (tyCon : TY.tyCon, newContext) =
      TC.bindTyConInContext
          (
            TC.extendContextWithVarEnv(newContext, !(#datacon tyCon)),
            #name tyCon,
            TY.TYCON tyCon
          )

  (** returns true if the tyCon is hidden.
   * A tyCon is "hidden" in either of the following two cases.
   * <ul>
   *   <li>not found in the context</li>
   *   <li>overridden by another tyCon of the same name.</li>
   * </ul>
   *)
  fun isHiddenTyCon context path (tyCon : TY.tyCon) =
      let
        val {name, id, strpath, abstract, ...} =
            makePathOfTyConRelative path tyCon
      in
(*
        abstract
        orelse
*)
        (case TC.lookupLongTyCon (context, strpath, name) of
           (_, SOME (TY.TYCON tyCon)) => id <> (#id tyCon)
(*
        | (_, SOME (TY.TYSPEC tySpec)) => id <> (#id tySpec)
*)
         | (_, _) => true)
      end

  fun formatterNameOfTyName tyName = formatterNamePrefix ^ tyName

  (**
   * get the name of the formatter for a tyCon.
   *)
  fun formatterPathNameOfTyCon path (tyCon : TY.tyCon) =
      let
        val {name, strpath, ...} = makePathOfTyConRelative path tyCon
        val name = formatterNameOfTyName name
      in
(*
print ("formatterPathNameOfTyCon: \n");
print ("  requested tycon: \n");
print ("      strpath = " ^ (P.pathToString (#strpath tyCon)) ^ "\n");
print ("      name = " ^ (#name tyCon) ^ "\n");
print ("  current path: " ^ (P.pathToString path) ^ "\n");
print ("  relatived tycon: \n");
print ("      strpath = " ^ (P.pathToString strpath) ^ "\n");
*)
        (strpath, name)
      end

end

