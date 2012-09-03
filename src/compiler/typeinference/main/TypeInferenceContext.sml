(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypeInferenceContext.sml,v 1.24 2007/01/21 13:41:33 kiyoshiy Exp $
 *)
structure TypeInferenceContext =
struct
  local
    open Types Path TypeContext
    structure STE = StaticTypeEnv
    structure T = Types
    structure TU = TypesUtils
  in

  type currentContext = 
       {
         utvarEnv:utvEnv,
         tyConEnv:tyConEnv,
         varEnv:varEnv,
         strEnv:strEnv,
         sigEnv:sigEnv,
         funEnv:funEnv,
         strLevel:path
       }

   val emptyCurrentContext = 
      {
        utvarEnv = SEnv.empty,
        tyConEnv = T.emptyTyConEnv,
        varEnv = T.emptyVarEnv,
        strEnv = T.emptyStrEnv,
        sigEnv = T.emptySigEnv,
        funEnv = T.emptyFunEnv,
        strLevel = NilPath
      } : currentContext

   fun makeInitialCurrentContext {strEnv, sigEnv, funEnv} =
      {
       utvarEnv = SEnv.empty,
       tyConEnv = T.emptyTyConEnv,
       varEnv = T.emptyVarEnv,
       strEnv = strEnv,
       sigEnv = sigEnv,
       funEnv = funEnv,
       strLevel = NilPath
      } : currentContext


   fun bindTyConInCurrentContext 
       ({
         strLevel,
         utvarEnv,
         tyConEnv, 
         varEnv, 
         strEnv, 
         sigEnv,
         funEnv
         } : currentContext,
         string, 
         tyCon) = 
        {
          strLevel = strLevel,
          utvarEnv = utvarEnv,
          tyConEnv = SEnv.insert(tyConEnv, string, tyCon),
          varEnv = varEnv,
          strEnv = strEnv,
          sigEnv = sigEnv,
          funEnv = funEnv
        }

   fun bindVarInCurrentContext 
       (lambdaDepth,
        {
         strLevel,
         utvarEnv,
         tyConEnv, 
         varEnv, 
         strEnv, 
         sigEnv,
         funEnv
         } : currentContext,
         string, 
         idstate)
        = 
       (
        TU.adjustDepthInIdstate lambdaDepth idstate;
        {
          strLevel = strLevel,
          utvarEnv = utvarEnv,
          tyConEnv = tyConEnv,
          varEnv = SEnv.insert(varEnv, string, idstate),
          strEnv = strEnv,
          sigEnv = sigEnv,
          funEnv = funEnv
        }
        )

   fun bindStrInCurrentContext 
       ({
         strLevel,
         utvarEnv,
         tyConEnv, 
         varEnv, 
         strEnv = STRUCTURE strEnvCont, 
         sigEnv,
         funEnv
         } : currentContext,
        string, 
        env) 
        = 
        {
          strLevel = strLevel,
          utvarEnv = utvarEnv,
          tyConEnv = tyConEnv,
          varEnv = varEnv,
          strEnv = STRUCTURE (SEnv.insert(strEnvCont, string, env)),
          sigEnv = sigEnv,
          funEnv = funEnv
        }

   fun bindSigInCurrentContext 
       ({
         strLevel,
         utvarEnv,
         tyConEnv, 
         varEnv, 
         strEnv, 
         sigEnv,
         funEnv
         } : currentContext,
        string, 
        sigexp) 
       = 
        {
          strLevel = strLevel,
          utvarEnv = utvarEnv,
          tyConEnv = tyConEnv,
          varEnv = varEnv,
          strEnv = strEnv,
          sigEnv = SEnv.insert(sigEnv, string, sigexp),
          funEnv = funEnv
        }

   fun extendCurrentContextWithVarEnv
     (
      {
       strLevel,
       utvarEnv,
       tyConEnv, 
       varEnv, 
       strEnv, 
       sigEnv,
       funEnv
       } : currentContext,
      newVarEnv
      ) = 
     {
      strLevel = strLevel,
      utvarEnv = utvarEnv,
      tyConEnv = tyConEnv,
      varEnv = SEnv.unionWith #1 (newVarEnv, varEnv),
      strEnv = strEnv,
      sigEnv = sigEnv,
      funEnv = funEnv
      }

   fun extendCurrentContextWithTyConEnv 
     (
      {
       strLevel,
       utvarEnv,
       tyConEnv, 
       varEnv, 
       strEnv, 
       sigEnv,
       funEnv
       } : currentContext,
      newTyConEnv
      ) = 
     {
      strLevel = strLevel,
      utvarEnv = utvarEnv,
      tyConEnv = SEnv.unionWith #1 (newTyConEnv, tyConEnv),
      varEnv = varEnv,
      strEnv = strEnv,
      sigEnv = sigEnv,
      funEnv = funEnv
      }

   fun extendCurrentContextWithUtvarEnv
     (
      {
       utvarEnv, 
       tyConEnv,
       varEnv,
       strEnv,
       sigEnv,
       funEnv, 
       strLevel
       } : currentContext,
      newUtvarEnv
      )
     =
     {
      strLevel = strLevel,
      utvarEnv = SEnv.unionWith #1 (newUtvarEnv, utvarEnv),
      tyConEnv = tyConEnv,
      varEnv = varEnv,
      strEnv = strEnv,
      sigEnv = sigEnv,
      funEnv = funEnv
      }

   fun extendCurrentContextWithContext 
     (
      {
       utvarEnv, 
       tyConEnv, 
       varEnv, 
       strEnv = STRUCTURE strEnvCont, 
       sigEnv, 
       funEnv, 
       strLevel
       }
      : currentContext,
      {
       tyConEnv = newTyConEnv, 
       varEnv = newVarEnv,
       strEnv = STRUCTURE newStrEnvCont, 
       sigEnv = newSigEnv, 
       funEnv = newFunEnv
       }
      : context
      )
     =
     {
      utvarEnv = utvarEnv, 
      tyConEnv = SEnv.unionWith #1 (newTyConEnv, tyConEnv),
      varEnv =  SEnv.unionWith #1 (newVarEnv, varEnv),
      strEnv = STRUCTURE (SEnv.unionWith #1 (newStrEnvCont, strEnvCont)),
      sigEnv = SEnv.unionWith #1 (newSigEnv, sigEnv),
      funEnv = SEnv.unionWith #1 (newFunEnv, funEnv),
      strLevel = strLevel
      }

   fun injectContextToCurrentContext
     (
      { 
       tyConEnv,
       varEnv, 
       strEnv, 
       sigEnv, 
       funEnv
       } : context
      )
     =
     {
      utvarEnv = SEnv.empty : utvEnv, 
      tyConEnv = tyConEnv : tyConEnv,
      varEnv =  varEnv : varEnv,
      strEnv = strEnv : strEnv,
      sigEnv = sigEnv : sigEnv,
      funEnv = funEnv : funEnv,
      strLevel = NilPath : path
      }

   fun extendCurrentContextWithTypeEnv (cc as {strEnv = STRUCTURE ccStrEnvCont,...} : currentContext, 
                                        typeEnv as {strEnv = STRUCTURE typeEnvStrEnvCont, ...} : STE.typeEnv) = 
       {
        utvarEnv = #utvarEnv cc,
        tyConEnv = SEnv.unionWith #1 (#tyConEnv typeEnv, #tyConEnv cc) : tyConEnv,
        varEnv =  SEnv.unionWith #1 (#varEnv typeEnv, #varEnv cc) : varEnv,
        strEnv = STRUCTURE  (SEnv.unionWith #1 (typeEnvStrEnvCont, ccStrEnvCont)) : strEnv,
        sigEnv = #sigEnv cc : sigEnv,
        funEnv = #funEnv cc : funEnv,
        strLevel = #strLevel cc : path
       }

  fun lookupLongTyCon ({tyConEnv, strEnv = STRUCTURE strEnvCont,...} : currentContext, path) = 
      let
        fun lookUp (tyConEnv, strEnvCont) nil _ =
            raise Control.Bug "lookupLongTyCon:Nil path"
          | lookUp (tyConEnv, strEnvCont) ([tyCon]) absStrPath =
            ((absStrPath,tyCon),SEnv.find(tyConEnv, tyCon))
          | lookUp (tyConEnv, strEnvCont)  (strid :: strids) absStrPath =
            (case SEnv.find(strEnvCont, strid) of 
               NONE => ((absStrPath,""),NONE)
             | SOME {id,name,env = (tyConEnv, _, STRUCTURE strEnvCont ), ...} =>
               lookUp (tyConEnv, strEnvCont) 
                      strids
                      (appendPath(absStrPath,id,name))
            )
      in
        case lookUp (tyConEnv, strEnvCont) path NilPath of
          (_, NONE) => lookUp (tyConEnv, strEnvCont) 
                              (topStrName :: path) 
                              NilPath
        | tyConOpt => tyConOpt
      end

  fun lookupVar ({varEnv, strEnv = STRUCTURE strEnvCont,...} : currentContext, string) =
      case SEnv.find(varEnv, string) of 
        SOME idState => SOME idState
      | _ =>
        (case SEnv.find(strEnvCont, Path.topStrName) of
           SOME {env = (_, varEnv, _), ...} =>
           SEnv.find (varEnv, string)
         | NONE => raise Control.Bug "TOP structure not found")

  fun lookupLongVar ({strEnv = STRUCTURE strEnvCont, varEnv,...} : currentContext, longid) =
      let
        fun lookUp (varEnv, strEnvCont) nil _ = 
            raise Control.Bug "lookupLongVar:Null path"
          | lookUp (varEnv, strEnvCont) ([vName]) absStrPath= 
               ((absStrPath,vName),SEnv.find(varEnv, vName))
          | lookUp (varEnv, strEnvCont) (strName :: path) absStrPath=
               (case SEnv.find(strEnvCont, strName) of 
                  NONE => ((absStrPath,""),NONE)
                | SOME {id,name,env = (_, varEnv, STRUCTURE strEnvCont), ...} =>
                    lookUp (varEnv, strEnvCont) path (appendPath(absStrPath,id,name)))
      in
        case lookUp (varEnv, strEnvCont) longid NilPath of
          (_,NONE) => 
          let
            val newpath = topStrName :: longid
          in
            lookUp (varEnv, strEnvCont) newpath NilPath
          end
        | Varoption => Varoption
      end

  fun lookupLongStructureEnv ({strEnv = STRUCTURE strEnvCont,...}:currentContext, longid) =
      let 
        fun lookUp _ nil _ = 
            raise Control.Bug "lookupLongStructure: NullPath"
          | lookUp strEnvCont ([strName]) absStrPath=
            (
             case (SEnv.find(strEnvCont,strName)) of
               NONE => (absStrPath,NONE)
             | SOME(strPathInfo as {id,name,...}) =>
               (appendPath(absStrPath,id,name), SOME strPathInfo)
            )
          | lookUp strEnvCont (strName :: path) absStrPath = 
            (
             case SEnv.find(strEnvCont, strName) of
               NONE => (absStrPath,NONE)
             | SOME({id,name,env = (_,_,STRUCTURE strEnvCont), ...}) => 
               lookUp strEnvCont path (appendPath(absStrPath,id,name))
            )
      in
        case lookUp strEnvCont longid NilPath of
          (_, NONE) => 
          let 
            val newpath = topStrName :: longid
          in
            lookUp strEnvCont newpath NilPath
          end
        | x => x
      end

  fun lookupUtvar ({utvarEnv,...} : currentContext, string) =
      case SEnv.find(utvarEnv, string) of
        SOME tvStateRef => SOME(TYVARty tvStateRef)
      | NONE => NONE

  fun lookupSigma ({sigEnv,...}:currentContext,sigid) = 
      SEnv.find(sigEnv ,sigid)

  fun lookupFunctor ({funEnv,...}:currentContext, funid) =
      SEnv.find(funEnv, funid) 

  fun updateStrLevel (context : currentContext, path) =
      {
        utvarEnv = #utvarEnv context,
        tyConEnv = #tyConEnv context,
        varEnv = #varEnv context,
        strEnv = #strEnv context,
        sigEnv = #sigEnv context,
        funEnv = #funEnv context,
        strLevel = path
      } : currentContext
    
  (* ToDo : this function and addUtvarIfNotThere should be refactored to share codes. *)
  fun addUtvarOverride (lambdaDepth,
                        {utvarEnv, 
                         tyConEnv, 
                         varEnv, 
                         strEnv, 
                         sigEnv, 
                         funEnv,
                         strLevel}, 
                        tvarNameSet) =
    let
      val (newUtvarEnv, addedUtvars) = 
          SEnv.foldli
              (fn (string, ifeq, (newUtvarEnv, addedUtvars)) =>
                  let 
                    val newTvStateRef =
                        newUtvar(lambdaDepth, 
                                 if ifeq then EQ else NONEQ, 
                                   string)
                  in 
                    (
                      SEnv.insert(newUtvarEnv, string, newTvStateRef),
                      SEnv.insert(addedUtvars, string, (ifeq,newTvStateRef))
                    )
                  end)
              (utvarEnv, SEnv.empty)
              tvarNameSet
    in
      ({
        utvarEnv = newUtvarEnv, 
        tyConEnv=tyConEnv, 
        varEnv=varEnv, 
        strEnv=strEnv,
        sigEnv=sigEnv,
        funEnv = funEnv, 
        strLevel = strLevel
        }:currentContext,
       addedUtvars)
    end

  fun addUtvarIfNotthere (lambdaDepth,
                          {utvarEnv, 
                           tyConEnv, 
                           varEnv, 
                           strEnv, 
                           sigEnv, 
                           funEnv, 
                           strLevel}, 
                          tvarNameSet) =
      let
        val (newUtvarEnv, addedUtvars) = 
            SEnv.foldli
                (fn (string, ifeq, (newUtvarEnv, addedUtvars)) =>
                    if SEnv.inDomain(newUtvarEnv, string)
                    then (newUtvarEnv, addedUtvars)
                    else
                      let
                        val newTvStateRef =
                            newUtvar(lambdaDepth,
                                     if ifeq then EQ else NONEQ, 
                                       string)
                      in 
                        (
                          SEnv.insert(newUtvarEnv, string, newTvStateRef),
                          SEnv.insert(addedUtvars, string, (ifeq,newTvStateRef))
                        )
                      end)
                (utvarEnv, SEnv.empty)
                tvarNameSet
      in
        ({utvarEnv = newUtvarEnv, 
          tyConEnv = tyConEnv,
          varEnv=varEnv, 
          strEnv = strEnv, 
          sigEnv = sigEnv, 
          funEnv = funEnv, 
          strLevel = strLevel
        }:currentContext,
         addedUtvars)
      end

end
end
