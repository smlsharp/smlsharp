(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
local
  fun bug s = Bug.Bug ("TfvKey: " ^ s)
  structure I = IDCalc
  structure IV = NameEvalEnv
in
  structure TfvKey =
    struct
      type ord_key = I.tfunkind ref
      fun compare (tfv1:ord_key, tfv2:ord_key) = 
          let
            val id1 = 
                case !tfv1 of
                  I.TFV_SPEC {id,...} => id
                | I.TFV_DTY {id,...} => id
                | I.TFUN_DTY{id,...} => id
                | I.INSTANTIATED{tfunkind, tfun} => 
                  (case tfunkind of
                     I.TFV_SPEC {id,...} => id
                   | I.TFV_DTY {id,...} => id
                   | I.TFUN_DTY {id,...} => id
                   | I.INSTANTIATED _ => raise bug "ord_key (1)"
                   | I.REALIZED _ =>  raise bug "ord_key (2)"
                   | I.FUN_DTY _ =>  raise bug "ord_key (3)"
                  )
                | I.REALIZED _ =>  raise bug "ord_key (4)"
                | I.FUN_DTY _ =>  raise bug "ord_key (5)"
            val id2 = 
                case !tfv2 of
                  I.TFV_SPEC {id,...} => id
                | I.TFV_DTY {id,...} => id
                | I.TFUN_DTY{id,...} => id
                | I.INSTANTIATED{tfunkind, tfun} => 
                  (case tfunkind of
                     I.TFV_SPEC {id,...} => id
                   | I.TFV_DTY {id,...} => id
                   | I.TFUN_DTY {id,...} => id
                   | I.INSTANTIATED _ => raise bug "ord_key (6)"
                   | I.REALIZED _ =>  raise bug "ord_key (7)"
                   | I.FUN_DTY _ =>  raise bug "ord_key (8)"
                  )
                | I.REALIZED _ =>  raise bug "ord_key (9)"
                | I.FUN_DTY _ =>  raise bug "ord_key (10)"
          in
            TypID.compare(id1, id2)
          end
    end
  structure TfvMap = BinaryMapFn(TfvKey)
  structure TfvSet = BinarySetFn(TfvKey)
end

(*
local
  structure I = IDCalc
  fun bug s = Bug.Bug ("DtyKey: " ^ s)
in
  structure DtyKey = 
    struct
      type ord_key = I.tfunkind ref * string list
      fun compare ((tfv1,_):ord_key, (tfv2,_):ord_key) = 
          let
            val id1 = case !tfv1 of
                        I.TFV_DTY {id,...} => id
                      | I.TFUN_DTY{id,...} => id
                      | _ => raise bug "tfvkey"
            val id2 = case !tfv2 of
                        I.TFV_DTY {id,...} => id
                      | I.TFUN_DTY{id,...} => id
                      | _ => raise bug "tfvkey"
          in
            TypID.compare(id1, id2)
          end
    end
  structure DtyPathMap = BinaryMapFn(DtyKey)
  structure DtyPathSet = BinarySetFn(DtyKey)
end
*)

structure TfunVars =
struct
local
  structure I = IDCalc
  structure IV = NameEvalEnv
in
  fun tfvsTfun tfvKind path (name, tfun, set) =
      case I.derefTfun tfun of
        I.TFUN_DEF _ => set
      | I.TFUN_VAR tfv =>
(* 2012-7-19 ohori: bug 210_functor.sml:
    dtyKind must be processed
*)
        let
          val set =
              case !tfv of
                I.TFUN_DTY{dtyKind = I.OPAQUE{tfun, ...},...} =>
                tfvsTfun tfvKind path (name, tfun, set)
              | _ => set
        in
          if tfvKind tfv then TfvMap.insert(set, tfv, path@[name])
          else set
        end

  fun tfvsTstr tfvKind path (name, tstr, set) =
      case tstr of
        IV.TSTR tfun => tfvsTfun tfvKind path (name, tfun, set)
      | IV.TSTR_DTY {tfun,...} => tfvsTfun tfvKind path (name, tfun, set)

  fun tfvsTyE tfvKind path (tyE, set) =
      SymbolEnv.foldri (tfvsTstr tfvKind path) set tyE
  fun tfvsStrE tfvKind path (IV.STR envMap, set) = 
      SymbolEnv.foldri
        (fn (name, {env, strKind}, set) => 
            tfvsEnv tfvKind (path@[name]) (env, set))
        set
        envMap 

 and tfvsEnv tfvKind path (IV.ENV {tyE, strE, varE}, set) =
      let
        val set = tfvsTyE tfvKind path (tyE, set)
      in
        tfvsStrE tfvKind path (strE, set)
      end
  fun allTfvKind (ref tfunkind) =
      case tfunkind of
        I.TFV_SPEC _ => true
      | I.TFV_DTY _ => true
      | I.TFUN_DTY _ => true
      | _ => false
  fun instantiatedKind (ref tfunkind) =
      case tfunkind of
        I.INSTANTIATED _ => true
      | _ => false
  fun sigTfvKind (ref tfunkind) =
      case tfunkind of
        I.TFV_SPEC _ => true
      | I.TFV_DTY _ => true
      | _ => false
  fun specKind (ref tfunkind) =
      case tfunkind of
        I.TFV_SPEC _ => true
      | _ => false
  fun dtyKind (ref tfunkind) =
      case tfunkind of
        I.TFV_DTY _ => true
      | I.TFUN_DTY _ => true
      | _ => false
  fun sigDtyKind (ref tfunkind) =
      case tfunkind of
        I.TFV_DTY _ => true
      | _ => false
  fun strDtyKind (ref tfunkind) =
      case tfunkind of
        I.TFUN_DTY _ => true
      | _ => false
end
end


structure TfunVarsRefresh =
struct
local
  structure I = IDCalc
  structure IV = NameEvalEnv
in
  fun tfvsTfun tfvKind path (name, tfun, set) =
      case tfun of
        I.TFUN_DEF _ => set
      | I.TFUN_VAR tfv =>
        if tfvKind tfv then TfvMap.insert(set, tfv, path@[name])
        else set
  fun tfvsTstr tfvKind path (name, tstr, set) =
      case tstr of
        IV.TSTR tfun => tfvsTfun tfvKind path (name, tfun, set)
      | IV.TSTR_DTY {tfun,...} => tfvsTfun tfvKind path (name, tfun, set)
  fun tfvsTyE tfvKind path (tyE, set) =
      SymbolEnv.foldri (tfvsTstr tfvKind path) set tyE
  fun tfvsStrE tfvKind path (IV.STR envMap, set) = 
      SymbolEnv.foldri
        (fn (name, {env, strKind}, set) => tfvsEnv tfvKind (path@[name]) (env, set))
        set
        envMap
  and tfvsEnv tfvKind path (IV.ENV {tyE, strE, varE}, set) =
      let
        val set = tfvsTyE tfvKind path (tyE, set)
      in
        tfvsStrE tfvKind path (strE, set)
      end
  fun allTfvKind (ref tfunkind) =
      case tfunkind of
        I.TFV_SPEC _ => true
      | I.TFV_DTY _ => true
      | I.TFUN_DTY _ => true
      | _ => false
  fun sigTfvKind (ref tfunkind) =
      case tfunkind of
        I.TFV_SPEC _ => true
      | I.TFV_DTY _ => true
      | _ => false
  fun specKind (ref tfunkind) =
      case tfunkind of
        I.TFV_SPEC _ => true
      | _ => false
  fun dtyKind (ref tfunkind) =
      case tfunkind of
        I.TFV_DTY _ => true
      | I.TFUN_DTY _ => true
      | _ => false
  fun sigDtyKind (ref tfunkind) =
      case tfunkind of
        I.TFV_DTY _ => true
      | _ => false
  fun strDtyKind (ref tfunkind) =
      case tfunkind of
        I.TFUN_DTY _ => true
      | _ => false
end
end
