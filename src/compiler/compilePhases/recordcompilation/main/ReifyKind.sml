(**
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 * @author UENO Katsuhiro
 *)
structure ReifyKind =
struct

  structure A = AbsynConst
  structure RC = RecordCalc
  structure T = Types
  structure BT = BuiltinTypes
  structure TB = TypesBasics
  structure BTN = BuiltinTypeNames
  structure U = UserLevelPrimitive

  fun compareTypeTy (ty1, ty2) =
      case (TypesBasics.derefTy ty1, TypesBasics.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        BoundTypeVarID.compare (t1, t2)
      | _ => raise Bug.Bug "UnivKind.compare"

  fun generateSingletonTy btv =
      [T.REIFYty (T.BOUNDVARty btv)]


  exception NotImplemented
  exception TypesTy

  (* ReifyUtilの型構成子 *)
  infixr 4 -->
  infix 5 **

(*
  val print = Bug.printError
  fun printTy ty = print (Types.tyWithTypeToString ty ^ "\n")
  fun printSingletonTy ty = print (Types.singletonTyWithTypeToString ty ^ "\n")
  fun printBtvEnv btvEnv = print (Types.btvEnvToString btvEnv ^ "\n")
  fun printBtvEnvWithType btvEnv = print (Types.btvEnvWithTypeToString btvEnv ^ "\n")
*)

  fun String (str, loc) =
      RC.RCCONSTANT {const = A.STRING (str, loc),
                    loc = loc,
                    ty = BT.stringTy}
  fun LabelAsString (label, loc) =
      String (RecordLabel.toString label, loc)

  fun ConstructTy (tyCon, NONE) =
      T.CONSTRUCTty {tyCon = tyCon, args = nil}
    | ConstructTy (tyCon, SOME arg) =
      T.CONSTRUCTty {tyCon = tyCon, args = [arg]}

  fun jsonTyTy () = ConstructTy (U.JSON_jsonTy_tyCon (), NONE)

  fun Nil (instTy, loc) = 
      RC.RCDATACONSTRUCT 
        {argExpOpt = NONE,
         con = BT.nilTPConInfo,
         argTyOpt = NONE,
         instTyList = [instTy],
         loc = loc}
  fun ListTy ty = ConstructTy (BT.listTyCon, SOME ty)
  fun OptionTy ty = ConstructTy (BT.optionTyCon, SOME ty)
  fun eqTy (id, tyCon) = id = #id tyCon
  fun PairTy (ty1, ty2) = T.RECORDty (RecordLabel.tupleMap [ty1, ty2])
  fun PairExp ((exp1, ty1), (exp2, ty2), loc) =
      RC.RCRECORD
        {fields = RecordLabel.tupleMap [exp1, exp2],
         loc = loc,
         recordTy = PairTy (ty1, ty2)}
  fun FUNMty (argTy, retTy) = T.FUNMty ([argTy], retTy)
  fun Cons ((h, hTy), (t, tTy), loc) =
      RC.RCDATACONSTRUCT
        {argExpOpt = SOME (PairExp ((h, hTy), (t, tTy), loc)),
         con = BT.consTPConInfo,
         argTyOpt = SOME (PairTy (hTy, tTy)),
         instTyList = [hTy],
         loc = loc}
  fun List (exps, instTy, loc) =
      foldr (fn (exp, z) => Cons ((exp, instTy), (z, ListTy instTy), loc))
            (Nil (instTy, loc)) exps

  fun TyExp (conInfo, argExpOpt, argTyOpt, loc) = 
      RC.RCDATACONSTRUCT
        {con = conInfo,
         instTyList = nil,
         argExpOpt = argExpOpt,
         argTyOpt = argTyOpt,
         loc = loc}

  fun TypesTyExn n = (Bug.printError ("TypesTy Exception: " ^ Int.toString n ^ "\n");
                     raise TypesTy)

  fun generateTypeInstance {btvEnv, lookup} ty loc =
      let
        fun evalTy ty = 
            case TB.derefTy ty of
              T.BOUNDVARty tid =>
              (case lookup (T.TYPEty ty) of
                 SOME var => RC.RCVAR var
               | _ => raise Bug.Bug "extra type parameter not found")
            | T.CONSTRUCTty {tyCon = {dtyKind, id, ...}, args} =>
              (case dtyKind of
                 T.BUILTIN BTN.INT32ty =>
                 TyExp (U.JSON_INTty_conInfo (), NONE, NONE, loc)
               | T.BUILTIN BTN.REAL64ty =>
                 TyExp (U.JSON_REALty_conInfo (), NONE, NONE, loc)
               | T.BUILTIN BTN.STRINGty =>
                 TyExp (U.JSON_STRINGty_conInfo (), NONE, NONE, loc)
               | T.BUILTIN BTN.UNITty =>
                 TyExp (U.JSON_RECORDty_conInfo (),
                        SOME (Nil (ListTy (PairTy (BT.stringTy, jsonTyTy ())), loc)),
                        SOME (ListTy (PairTy (BT.stringTy, jsonTyTy ()))), 
                        loc)
               | T.DTY =>
                 if eqTy (id, BT.boolTyCon) then 
                   TyExp (U.JSON_BOOLty_conInfo (), NONE, NONE, loc)
                 else if eqTy (id, BT.listTyCon) then 
                   let
                     val argTy = case args of [argTy] => argTy | _ => raise TypesTyExn 1
                   in
                     TyExp (U.JSON_ARRAYty_conInfo (),
                            SOME (evalTy argTy),
                            SOME (jsonTyTy ()),
                            loc)
                   end
                 else if eqTy (id, BT.optionTyCon) then 
                   let
                     val argTy = case args of [argTy] => argTy | _ => raise TypesTyExn 2
                   in
                     TyExp (U.JSON_OPTIONty_conInfo (),
                            SOME (evalTy argTy),
                            SOME (jsonTyTy ()),
                            loc)
                   end
                 else if eqTy (id, U.JSON_dyn_tyCon ()) then
                   let 
                     val argTy = case args of [argTy] => argTy | _ => raise TypesTyExn 3
                   in
                     case TB.derefTy argTy of
                       T.RECORDty fields =>
                       TyExp
                         (U.JSON_PARTIALRECORDty_conInfo (),
                          SOME (RecordLabel.Map.foldri
                                  (fn (label, exp, listexp) =>
                                      Cons ((PairExp ((LabelAsString (label, loc), BT.stringTy),
                                                      (exp, jsonTyTy()),
                                                      loc),
                                             PairTy (BT.stringTy, jsonTyTy())),
                                            (listexp,
                                             ListTy (PairTy (BT.stringTy, jsonTyTy()))),
                                            loc))
                                  (Nil (PairTy (BT.stringTy, jsonTyTy()), loc))
                                  (RecordLabel.Map.map evalTy fields)),
                          SOME (ListTy (PairTy (BT.stringTy, jsonTyTy()))),
                          loc)
                     | T.CONSTRUCTty {tyCon = {dtyKind, id, ...}, args} =>
                       (case dtyKind of
                          T.BUILTIN BTN.UNITty =>
                          TyExp (U.JSON_PARTIALRECORDty_conInfo (),
                                  SOME (Nil (ListTy (PairTy (BT.stringTy, jsonTyTy())), loc)),
                                  SOME (ListTy (PairTy (BT.stringTy, jsonTyTy()))),
                                  loc)
                        | T.BUILTIN BTN.INT32ty =>
                          TyExp (U.JSON_PARTIALINTty_conInfo (), NONE, NONE, loc)
                        | T.BUILTIN BTN.REAL64ty =>
                          TyExp (U.JSON_PARTIALREALty_conInfo (), NONE, NONE, loc)
                        | T.BUILTIN BTN.STRINGty => 
                          TyExp (U.JSON_PARTIALSTRINGty_conInfo (), NONE, NONE, loc)
                        | T.DTY =>
                          if eqTy (id, BT.boolTyCon) then 
                            TyExp (U.JSON_PARTIALBOOLty_conInfo (), NONE, NONE, loc)
                          else if eqTy (id, U.JSON_void_tyCon ()) then 
                            TyExp (U.JSON_DYNty_conInfo (), NONE, NONE, loc)
                          else raise TypesTyExn 4
                        | _ => raise TypesTyExn 5
                       )
                     | _ => raise TypesTyExn 6
                   end
                 else if eqTy (id, U.JSON_void_tyCon ()) then 
                   TyExp (U.JSON_DYNty_conInfo (), NONE, NONE, loc)
                 else  raise TypesTyExn 7
               | _ => raise TypesTyExn 8
              )
            | T.RECORDty tyFields =>
              TyExp (U.JSON_RECORDty_conInfo (),
                     SOME (List (map (fn (l, ty) => PairExp ((LabelAsString (l, loc), BT.stringTy),
                                                             (evalTy ty, jsonTyTy ()),
                                                             loc))
                                     (RecordLabel.Map.listItemsi tyFields),
                                 PairTy (BT.stringTy, jsonTyTy ()),
                                 loc)),
                     SOME (FUNMty (ListTy (PairTy (BT.stringTy, jsonTyTy ())),
                                   jsonTyTy ())),
                     loc)
            | _ => TyExp (U.JSON_DYNty_conInfo (), NONE, NONE, loc)
      in
        evalTy ty
      end
      handle TypesTy => raise Bug.Bug "Illeagal TYPESOF ty"
           | U.IDNotFound name =>
             raise 
               Bug.Bug ("RecordCompilation: userlevel primitive (compile):" ^ name)

  fun generateReifyInstance btvEnv ty loc =
      let
        fun evalTy ty = 
            case TB.derefTy ty of
              T.BOUNDVARty tid => NONE
            | _ =>
              let
                val tyRep = TyToReifiedTy.toTy ty
              in
                SOME (#exp (ReifyTy.TyRep loc tyRep))
              end

      in
        evalTy ty
      end

end
