(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypeInferenceContext.sml,v 1.20 2006/02/28 16:11:08 kiyoshiy Exp $
 *)
structure TypeInferenceContext =
struct
  local
    open Types Path TypeContext
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
        tyConEnv = SEnv.empty,
        varEnv = SEnv.empty,
        strEnv = SEnv.empty,
        sigEnv = SEnv.empty,
        funEnv = SEnv.empty,
        strLevel = NilPath
      } : currentContext

   fun makeInitialCurrentContext {strEnv, sigEnv, funEnv} =
      {
       utvarEnv = SEnv.empty,
       tyConEnv = SEnv.empty,
       varEnv = SEnv.empty,
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
         idstate)
        = 
        {
          strLevel = strLevel,
          utvarEnv = utvarEnv,
          tyConEnv = tyConEnv,
          varEnv = SEnv.insert(varEnv,string, idstate),
          strEnv = strEnv,
          sigEnv = sigEnv,
          funEnv = funEnv
        }

   fun bindStrInCurrentContext 
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
        env) 
        = 
        {
          strLevel = strLevel,
          utvarEnv = utvarEnv,
          tyConEnv = tyConEnv,
          varEnv = varEnv,
          strEnv = SEnv.insert(strEnv, string, env),
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
       strEnv, 
       sigEnv, 
       funEnv, 
       strLevel
       }
      : currentContext,
      {
       tyConEnv = newTyConEnv, 
       varEnv = newVarEnv,
       strEnv = newStrEnv, 
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
      strEnv = SEnv.unionWith #1 (newStrEnv, strEnv),
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

  fun lookupLongTyCon ({tyConEnv, strEnv,...} : currentContext, path) = 
      let
        fun lookUp (tyConEnv, strEnv) nil _ =
            raise Control.Bug "lookupLongTyCon:Nil path"
          | lookUp (tyConEnv, strEnv) ([tyCon]) absStrPath =
            ((absStrPath,tyCon),SEnv.find(tyConEnv, tyCon))
          | lookUp (tyConEnv, strEnv)  (strid :: strids) absStrPath =
            (case SEnv.find(strEnv, strid) of 
               NONE => ((absStrPath,""),NONE)
             | SOME (STRUCTURE {id,name,env = (tyConEnv, _, strEnv), ...}) =>
               lookUp (tyConEnv, strEnv) 
                      strids
                      (appendPath(absStrPath,id,name))
            )
      in
        case lookUp (tyConEnv, strEnv) path NilPath of
          (_, NONE) => lookUp (tyConEnv, strEnv) 
                              (topStrName :: path) 
                              NilPath
        | tyConOpt => tyConOpt
      end

  fun lookupVar ({varEnv, strEnv,...} : currentContext, string) =
      case SEnv.find(varEnv, string) of 
        SOME idState => SOME idState
      | _ =>
        (case SEnv.find(strEnv, Path.topStrName) of
           SOME (STRUCTURE {env = (_, varEnv, _), ...}) =>
           SEnv.find (varEnv, string)
         | NONE => raise Control.Bug "TOP structure not found")

  fun lookupLongVar ({strEnv, varEnv,...} : currentContext, longid) =
      let
        fun lookUp (varEnv, strEnv) nil _ = 
            raise Control.Bug "lookupLongVar:Null path"
          | lookUp (varEnv, strEnv) ([vName]) absStrPath= 
               ((absStrPath,vName),SEnv.find(varEnv, vName))
          | lookUp (varEnv, strEnv) (strName :: path) absStrPath=
               (case SEnv.find(strEnv, strName) of 
                  NONE => ((absStrPath,""),NONE)
                | SOME(STRUCTURE {id,name,env = (_, varEnv, strEnv), ...}) =>
                    lookUp (varEnv, strEnv) path (appendPath(absStrPath,id,name)))
      in
        case lookUp (varEnv, strEnv) longid NilPath of
          (_,NONE) => 
          let
            val newpath = topStrName :: longid
          in
            lookUp (varEnv, strEnv) newpath NilPath
          end
        | Varoption => Varoption
      end

  fun lookupLongStructureEnv ({strEnv,...}:currentContext, longid) =
      let 
        fun lookUp _ nil _ = 
            raise Control.Bug "lookupLongStructure: NullPath"
          | lookUp strEnv ([strName]) absStrPath=
            (
             case (SEnv.find(strEnv,strName)) of
               NONE => (absStrPath,NONE)
             | SOME(STRUCTURE (strPathInfo as {id,name,...})) =>
               (appendPath(absStrPath,id,name), SOME strPathInfo)
            )
          | lookUp strEnv (strName :: path) absStrPath = 
            (
             case SEnv.find(strEnv, strName) of
               NONE => (absStrPath,NONE)
             | SOME(STRUCTURE {id,name,env = (_,_,strEnv), ...}) => 
               lookUp strEnv path (appendPath(absStrPath,id,name))
            )
      in
        case lookUp strEnv longid NilPath of
          (_, NONE) => 
          let 
            val newpath = topStrName :: longid
          in
            lookUp strEnv newpath NilPath
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
  fun addUtvarOverride ({utvarEnv, 
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
                        newUtvar(if ifeq then EQ else NONEQ, string)
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

  fun addUtvarIfNotthere ({utvarEnv, 
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
                            newUtvar(if ifeq then EQ else NONEQ, string)
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
