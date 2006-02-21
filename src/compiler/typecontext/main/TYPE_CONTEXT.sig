(**
 * Copyright (c) 2006, Tohoku University.
 *
 * type structures.
 *
 * @author OHORI Atushi
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: TYPE_CONTEXT.sig,v 1.3 2006/02/18 04:59:31 ohori Exp $
 *)
signature TYPE_CONTEXT =
sig

  type context
  type currentContext
  exception DuplicateEntryInUnionContexts
  val addUtvarIfNotthere :
      currentContext * Types.tvarNameSet -> currentContext * Types.utvEnv
  val addUtvarOverride :
      currentContext * Types.tvarNameSet -> currentContext * Types.utvEnv
  val bindSigInContext : string * Types.sigma
                         -> context
                            -> context
  val bindSigInEmptyContext : string * Types.sigma
                              -> context
  val bindStrInContext : string * Types.strE
                         -> context
                            -> context
  val bindStrInEmptyContext : string * Types.strE
                              -> context
  val bindTyConInContext : string * Types.tyBindInfo
                           -> context
                              -> context
  val bindTyConInEmptyContext : string * Types.tyBindInfo
                                -> context
  val injectSigEnvToContext : Types.sigEnv -> context
  val injectStrEnvToContext : Types.strEnv -> context
  val injectTyConEnvToContext : Types.tyConEnv -> context
  val injectVarEnvToContext : Types.varEnv -> context
  val bindVarInContext : string * Types.idState -> context -> context
  val bindVarInEmptyContext : string * Types.idState -> context
  val contextToString : context -> string
  val currentContextToString : currentContext -> string
  val emptyContext : context
  val extendContextWithContext : context
                                 -> context
                                    -> context
  val extendCurrentContextWithContext : context
                                        -> currentContext
                                           -> currentContext
  val extendSigInContext : Types.sigEnv
                           -> context
                              -> context
  val extendStrEnvInContext : Types.strEnv
                              -> context
                                 -> context
  val extendTyConEnvInContext : Types.tyConEnv
                                -> context
                                   -> context
  val extendVarEnvInContext : Types.varEnv
                              -> context
                                 -> context
  val format_compileContextVarEnv : (int * Types.btvEnv) list
                                    -> Types.varEnv
                                      -> SMLFormat.FormatExpression.expression list

  val format_context : 
      (int * Types.btvEnv) list
      -> context
      -> SMLFormat.FormatExpression.expression list
  val format_currentContext : 
      (int * Types.btvEnv) list
      -> currentContext
      -> SMLFormat.FormatExpression.expression list
  val format_globalContext : 
      (int * Types.btvEnv) list
      -> context
      -> SMLFormat.FormatExpression.expression list
  val getCurrentContextEnv : currentContext -> Types.Env
  val getGbSigEnvinCrtCxt : currentContext -> Types.sigEnv
  val getGbStrEnvinCrtCxt : currentContext -> Types.strEnv
  val getGbTyConEnvinCrtCxt : currentContext -> Types.tyConEnv
  val getGbVarEnvinCrtCxt : currentContext -> Types.varEnv
  val getGlobalContextEnv : context -> Types.Env
  val getStructureEnvFromContext : context -> Types.Env
  val lookupLongStructure : currentContext -> Types.path -> Types.Env option
  val lookupLongStructureInStrEnv
      : Types.strEnv -> Types.path -> Types.Env option
  val lookupLongTyCon : currentContext * Types.path -> Types.tyBindInfo option
  val lookupLongVar : currentContext * Types.path ->bool * Types.idState option
  val lookupSigma : currentContext * string -> Types.sigma option
  val lookupTyCon : currentContext * string -> Types.tyBindInfo option
  val lookupUtvar : currentContext * string -> Types.ty option
  val lookupVar : currentContext * string -> bool * Types.idState option
  val makeEmptyCurrentContext : context -> currentContext
  val emptyCurrentContext : currentContext
  val mergeTyConEnv : Types.tyConEnv * Types.tyConEnv -> Types.tyConEnv
  val mergeVarEnv : Types.varEnv * Types.varEnv -> Types.varEnv
  val mergeBtvEnv : Types.btvEnv * Types.btvEnv -> Types.btvEnv
  val mergeSigEnv : Types.sigEnv * Types.sigEnv -> Types.sigEnv
  val mergeStrEnv : Types.strEnv * Types.strEnv -> Types.strEnv
  val mergeTyNameSet : Types.tyNameSet * Types.tyNameSet -> Types.tyNameSet

  val unionhContexts : context -> context -> context
  val updateStrLevel : currentContext * Types.path -> currentContext

(*
  val emptyContext : context
  val getEmptyCurrentContext : context -> currentContext

  val addTyConEnv : currentContext * Types.tyConEnv -> currentContext
  val addVarEnv : currentContext * Types.varEnv -> currentContext
  val addStrEnv : currentContext * Types.strEnv -> currentContext
  val addEnv : currentContext * Types.Env -> currentContext
  val addTyNameSet : currentContext * Types.tyNameSet -> currentContext
  val addUtvarEnv : currentContext * Types.utvEnv -> currentContext
  val replaceUtvarEnv :currentContext * Types.utvEnv -> currentContext


  val bindTyCon : currentContext * string * Types.tyBindInfo -> currentContext
  val bindVar : currentContext * string * Types.idState -> currentContext
  val bindStructure :currentContext * string * Types.strE -> currentContext
  val bindSignature : currentContext * string * Types.sigma -> currentContext

  val getCurrentContextEnv : currentContext -> Types.Env
  val getGlobalContextEnv : context -> Types.Env
  val lookupTyCon : currentContext * string -> Types.tyBindInfo option
  val lookupVar : currentContext * string -> bool * Types.idState option
  val lookupUtvar : currentContext * string -> Types.ty option

  val updateContext : context * context -> context
  val updateCompileContextByCurrentContext
      : context * currentContext -> context
  val mergeCurrentContext : currentContext * currentContext -> currentContext
  val generateNewCurrentContext
      : (
          context *
          Types.utvEnv *
          Types.tyConEnv * 
	  Types.varEnv *
          Types.strEnv *
          Types.sigEnv *
          Types.tyNameSet *
          Types.path
        )
        -> currentContext

  (* move these to the SemanticObjects *)
  val mergeTyConEnv : Types.tyConEnv * Types.tyConEnv -> Types.tyConEnv
  val mergeVarEnv : Types.varEnv * Types.varEnv -> Types.varEnv
  val mergeBtvEnv : Types.btvEnv * Types.btvEnv -> Types.btvEnv
  val mergeSigEnv : Types.sigEnv * Types.sigEnv -> Types.sigEnv
  val mergeStrEnv : Types.strEnv * Types.strEnv -> Types.strEnv
  val mergeTyNameSet : Types.tyNameSet * Types.tyNameSet -> Types.tyNameSet
  val mergeEnv : Types.Env * Types.Env -> Types.Env
  (* ToDo : move this to SemanticObjects *)

  val format_context :
      (int * Types.btvEnv) list
      -> context
      -> SMLFormat.FormatExpression.expression list
  val format_currentContext :
      (int * Types.btvEnv) list
      -> currentContext
      -> SMLFormat.FormatExpression.expression list

  (* ToDo : these functions are necessary ??? *)
  val contextToString : context -> string
  val currentContextToString : currentContext -> string
  *)
end
