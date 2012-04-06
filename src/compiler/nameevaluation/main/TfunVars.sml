(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
local
  fun bug s = Control.Bug ("tfvkey: " ^ s)
  structure I = IDCalc
  structure IV = NameEvalEnv
  structure tfvkey =
    struct
      type ord_key = I.tfunkind ref
      fun compare (tfv1, tfv2) = 
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
                   | _ =>  raise bug "ord_key (1)"
                  )
                | _ =>  raise bug "ord_key (1)"
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
                   | _ =>  raise bug "ord_key (1)"
                  )
                | _ => raise bug "ord_key (1)"
          in
            TypID.compare(id1, id2)
          end
    end
in
  structure TfvMap = BinaryMapFn(tfvkey)
  structure TfvSet = BinarySetFn(tfvkey)
end

local
  structure I = IDCalc
  fun bug s = Control.Bug ("tfvPathkey: " ^ s)
  structure tfvKey = 
    struct
      type ord_key = I.tfunkind ref * string list
      fun compare ((tfv1,_), (tfv2,_)) = 
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
in
  structure DtyPathMap = BinaryMapFn(tfvKey)
  structure DtyPathSet = BinarySetFn(tfvKey)
end

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
        if tfvKind tfv then TfvMap.insert(set, tfv, path@[name])
        else set
  fun tfvsTstr tfvKind path (name, tstr, set) =
      case tstr of
        IV.TSTR tfun => tfvsTfun tfvKind path (name, tfun, set)
      | IV.TSTR_DTY {tfun,...} => tfvsTfun tfvKind path (name, tfun, set)
  fun tfvsTyE tfvKind path (tyE, set) =
      SEnv.foldri (tfvsTstr tfvKind path) set tyE
  fun tfvsStrE tfvKind path (IV.STR envMap, set) = 
      SEnv.foldri
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
      SEnv.foldri (tfvsTstr tfvKind path) set tyE
  fun tfvsStrE tfvKind path (IV.STR envMap, set) = 
      SEnv.foldri
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
