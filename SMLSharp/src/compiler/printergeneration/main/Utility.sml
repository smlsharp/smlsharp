(**
 * misc utilities.
 * ToDo : It is better to move members of this strucutre to other more
 * specific modules.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Utility.sml,v 1.38 2008/08/06 12:59:09 ohori Exp $
 *)
structure Utility = 
struct

  (***************************************************************************)

  structure A = Absyn
  structure BF = SMLFormat.BasicFormatters
  structure FE = SMLFormat.FormatExpression
  structure IT = InitialTypeContext
  structure NM = NameMap
  structure NPEnv = NM.NPEnv
  structure P = Path
  structure PE = PatternCalc
  structure PP = SMLFormat
  structure TC = TypeContext
  structure TP = TypedCalc
  structure TPU = TypedCalcUtils
  structure TU = TypesUtils
  structure TY = Types

  (***************************************************************************)

  val s_Indicator = FE.Indicator{space = true, newline = NONE}
  val s_1_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Preferred 1}}
  val ns_1_Indicator =
      FE.Indicator
      {space = false, newline = SOME{priority = FE.Preferred 1}}
  val s_2_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Preferred 2}}
  val s_d_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Deferred}}

  fun makeVarName () = VarName.generate () 

  fun makeVar (ty, loc) =
      let
        val varName = makeVarName ()
        val varPathInfo = {namePath = (varName, Path.NilPath), ty = ty}
        val varExp = TP.TPVAR (varPathInfo, loc)
      in
        (varName, varPathInfo, varExp)
      end

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

  fun listToTupleTy (tyList : TY.ty list) =
      TY.RECORDty(listToTupleSEnv (tyList))

  fun listToTupleExp (valueTyList : (TP.tpexp * TY.ty) list) loc =
      let
        val fields = listToTupleSEnv (map #1 valueTyList)
        val ty = listToTupleTy (map #2 valueTyList)
      in TP.TPRECORD{fields = fields, recordTy = ty, loc = loc}
      end

  fun listToRecordTy labelTyList =
      let
        val tyEnv =
            foldr
                (fn ((label, ty), tyEnv) => SEnv.insert (tyEnv, label, ty))
                SEnv.empty
                labelTyList
      in
        TY.RECORDty tyEnv
      end

  fun listToRecordExp labelValueTyList loc =
      let
        val (valueEnv, tyEnv) =
            foldr
                (fn ((label, value, ty), (valueEnv, tyEnv)) =>
                    (
                      SEnv.insert (valueEnv, label, value),
                      SEnv.insert (tyEnv, label, ty)
                    ))
                (SEnv.empty, SEnv.empty)
                labelValueTyList
      in
        TP.TPRECORD{fields = valueEnv, recordTy = TY.RECORDty tyEnv, loc = loc}
      end

  (**
   * make a string from a path.
   * This function skips the dummy top structure name.
   *)
  fun namePathToPrintString namePath =
      NM.namePathToString(NM.namePathToUsrNamePath namePath)
  
  (**
   * translate absolute path of tyCon to relative path based on the
   * currentPath.
   *)
  fun makePathOfTyConRelative currentPath (tyCon : TY.tyCon) =
      let
(*
          val _ = print "\n ********* \n"
          val _ = print "\n current : "
          val _ = print (Path.pathToString currentPath)
          val _ = print "\n strpath : "
          val _ = print (Path.pathToString (#strpath tyCon))
*)
        val (_, relativePath) = 
            P.removeCommonPrefix (currentPath, #strpath tyCon)
(*
          val _ = print "\n relative Path:"
          val _ = print (Path.pathToString(relativePath))
          val _ = print "\n ************ \n"
*)
        val newTyCon = 
            {
              name = #name tyCon,
              strpath = relativePath,
	      abstract = #abstract tyCon,
              tyvars = #tyvars tyCon,
              id = #id tyCon,
              eqKind = #eqKind tyCon,
              constructorHasArgFlagList = #constructorHasArgFlagList tyCon
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

(*
  fun makePathOfTyNameRelative currentPath (tyName : TY.tyName) =
      let
          val (_, relativePath) = 
            P.removeCommonPrefix (currentPath, #strpath tyName)
          val newTyName = 
              {
                name = #name tyName,
                strpath = relativePath,
	        abstract = #abstract tyName,
                tyvars = #tyvars tyName,
                id = #id tyName,
                eqKind = #eqKind tyName,
                boxedKind = #boxedKind tyName,
                tagNum = #tagNum tyName
              }
      in
        newTyName : TY.tyName 
      end
*)

  (** true if two tyCons are the same. *)
  fun isEqualTyCon(left : TY.tyCon, right : TY.tyCon) =
      TyConID.eq(#id left, #id right) andalso #name left = #name right

(*
  fun tySpecToTyCon 
          ({name, strpath, id, tyvars, eqKind, ...}
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
              constructorHasArgFlagList = nil
            }
      in tyCon end
*)

(*
  fun tySpecToTyName
          ({name, strpath, id, tyvars, eqKind, boxedKind, ...}
           : TY.tySpec) =
      let
        val tyName =
            {
              name = name,
              strpath = strpath,
	      abstract = false,
              tyvars = tyvars,
              id = id,
              eqKind = ref eqKind,
              boxedKind = ref boxedKind,
              tagNum = 0
            }
      in tyName end
*)
  (** perform union operation on a list of contexts. *)
  fun unionContexts [] = TC.emptyContext
    | unionContexts (context :: contexts) =
      foldl TC.mergeContexts context contexts

  (** translate absolute paths of tyCons occurring in a ty into relative. *)
  (* FIXME: do we need to process PREDEFINEDty below? I guess no. *)
  fun makePathOfTyRelative currentPath ty =
      TypeTransducer.mapTyPostOrder
          (fn ty =>
              case ty of
                TY.RAWty {tyCon, args} =>
                let val newTyCon = makePathOfTyConRelative currentPath tyCon
                in TY.RAWty {tyCon = newTyCon, args = args}
                end
              | TY.OPAQUEty{spec = {tyCon, args}, implTy} =>
                let val newTyCon = makePathOfTyConRelative currentPath tyCon
                in
                  TY.OPAQUEty
                      {spec = {tyCon = newTyCon, args = args}, implTy = implTy}
                end
              | TY.SPECty{tyCon, args} =>
                let val newTyCon = makePathOfTyConRelative currentPath tyCon
                in TY.SPECty{tyCon = newTyCon, args = args} end
              | _ => ty) (* tyCon occurs in RAWty, OPAQUEty and SPECty only. *)
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
          | decomp _ _ _ =
            raise
              Control.Bug
                  "non FUNMty in decompFunctionType \
                  \(printergeneration/main/Utility.sml)"
      in
        decomp arity ty []
      end

  fun generalize ty =
      let
        val ({boundEnv, removedTyIds}) =
            TU.generalizer (ty, TY.toplevelDepth)
      in
        if 0 = IEnv.numItems boundEnv
        then ty
        else TY.POLYty{boundtvars = boundEnv, body = ty}
      end

   type basis = {global : TC.topContext, current : TC.context}

   fun lookupVarInBasis (basis:basis, namePath) = 
       if P.isExternPath (#2 namePath)
       then
         SEnv.find
             (
               #varEnv(#global basis),
               NameMap.namePathToString(NM.getTailNamePath namePath)
             )
       else NPEnv.find(#varEnv(#current basis), namePath)
            
   fun lookupTyConInBasis (basis:basis, namePath : NM.namePath) =
       if P.isExternPath (#2 namePath)
       then
         SEnv.find
             (
               #tyConEnv(#global basis),
               NameMap.namePathToString(NM.getTailNamePath namePath)
             )
       else NPEnv.find(#tyConEnv(#current basis), namePath) 

  fun instantiateTy (TY.POLYty{body, boundtvars}) =
      let
        val (monoTy, argTys) =
            TU.instantiate {body = body, boundtvars = boundtvars}
      in
        (monoTy, argTys)
      end
    | instantiateTy ty = (ty, IEnv.empty)

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
        (
          TP.TPTAPP
              {exp=exp, expTy=ty, instTyList=IEnv.listItems argTys, loc=loc},
          monoTy
        )
      end
    | instantiateExp (exp, ty) = (exp, ty)

  fun isTupleFields fieldsMap =
      let
        val fields = SEnv.listItemsi fieldsMap
        fun isNumeric index nil = true
          | isNumeric index ((label, _) :: tail) = 
            (case Int.fromString label  of
               SOME k =>
               if k = index then isNumeric (index + 1) tail else false
             | _ => false)
      in isNumeric 1 fields end

  val formatterNamePrefix = "_format_"

  (** add a tyCon to a context. *)
  fun bindTyCon (dataTyInfo : TY.dataTyInfo, newContext) =
      TC.bindTyConInContext
          (
            TC.extendContextWithVarEnv
                (newContext, TC.injectDataConToVarEnv ((#datacon dataTyInfo))),
            (#name (#tyCon dataTyInfo), #strpath (#tyCon dataTyInfo)),
            TY.TYCON dataTyInfo
          )

  (** returns true if the tyCon is hidden in the context.
   * A tyCon is not "hidden" in either of the following two cases.
   * <ul>
   *   <li>a tyCon of the same ID and the same name is found in the context.
   *     </li>
   *   <li>a tyFun of the same name which is just an identical replication of
   *     the tyCon is found in the context.
   *     </li>
   * </ul>
   * Otherwise, the tyCon is considered hidden.
   * <p>
   * Example.
   * <pre>
   * datatype ('a, 'b) t = D of 'a * 'b;  (* A *)
   * datatype ('a, 'b) t = D of 'a * 'b;  (* B *)
   * type ('a, 'b) t = ('a, 'b) t;        (* C *)
   * type ('a, 'b) t = ('b, 'a) t;        (* D *)
   * type ('a) t = ('a, int) t;           (* E *)
   * </pre>
   * The tyCon <tt>t</tt> defined at A is hidden by
   * the tyCon defined at B, the tyFuns defined at D and E,
   * but not hidden by the tyFun defined at C.
   *)
  fun isHiddenTyCon basis path (tyCon : TY.tyCon) =
      let
        val {name, id, strpath, abstract, ...} =
            makePathOfTyConRelative path tyCon
      in
(*
        abstract
        orelse
*)
        (case lookupTyConInBasis (basis, (name, strpath)) of
           SOME (TY.TYCON dataTyInfo) =>
           not (TyConID.eq(id, (#id (#tyCon dataTyInfo)))) 
         | SOME(TY.TYFUN {body,...}) =>
           let
             fun checkPath (P.NilPath, P.NilPath) = true
               | checkPath (P.PUsrStructure (s1,path1),
                            P.PUsrStructure(s2,path2)) = 
                 s1 = s2 andalso checkPath(path1,path2)
               | checkPath (P.PSysStructure (s1,path1),
                            P.PSysStructure(s2,path2)) = 
                 s1 = s2 andalso checkPath(path1,path2)
               | checkPath _ = false
             fun checkTyList (nil, nil) = true
               | checkTyList (ty1::tyList1, ty2::tyList2) = 
                 (case (getRealTy ty1, getRealTy ty2) of
                    (TY.BOUNDVARty id1, TY.BOUNDVARty id2) =>
                    id1 = id2 andalso checkTyList(tyList1, tyList2)
                  | _ => false)
               | checkTyList _ = false
           in
             case getRealTy body of
               TY.ALIASty
                 (
                  TY.RAWty{tyCon={name=name1,
                                  strpath=path1,...},
                           args=tyList1},
                  TY.RAWty{tyCon={name=name2,
                                  strpath=path2,...},
                           args=tyList2}
                 )
               =>
               not(name1 = name2 andalso
                   checkTyList(tyList1, tyList2) andalso
                   checkPath(path1,path2)
                  )
             | _ => true
           end
(*
         | (_, SOME (TY.TYSPEC tySpec)) => id <> (#id tySpec)
*)
         | _ => true)
      end

(*
  fun isHiddenTyName basis path (tyName : TY.tyName) =
      let
        val {name, id, strpath, abstract, ...} =
            makePathOfTyNameRelative path tyName
      in
(*
        abstract
        orelse
*)
        (case lookupTyConInBasis (basis, (name, strpath)) of
           SOME (TY.TYCON tyCon) => not (TyConID.eq(id, (#id tyCon)))
(*
        | (_, SOME (TY.TYSPEC tySpec)) => id <> (#id tySpec)
*)
         |  _ => true)
      end
*)

  fun formatterNameOfTyName tyName = formatterNamePrefix ^ tyName

  fun formatterNameOfTyNamePath (tyName, strpath) = 
      (formatterNameOfTyName tyName, strpath)

  (**
   * get the name of the formatter for a tyCon.
   *)
  fun formatterPathNameOfTyCon path (tyCon : TY.tyCon) =
      let
        (* val {name, strpath, ...} = makePathOfTyConRelative path tyCon *)
        val namePath = (formatterNameOfTyName (#name tyCon), #strpath tyCon)
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
        namePath
      end

(*
  fun formatterPathNameOfTyName path (tyName : TY.tyName) =
      let
        (* val {name, strpath, ...} = makePathOfTyConRelative path tyCon *)
        val namePath = (formatterNameOfTyName (#name tyName), #strpath tyName)
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
        namePath
      end
*)
end

