(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalTranslator.sml,v 1.19 2007/06/19 22:19:11 ohori Exp $
 *)


structure ANormalTranslator : ANORMAL_TRANSLATOR = struct

  open ANormal

  structure T = Types
  structure TU = TypesUtils
  structure BC = BUCCalc
  structure BU = BUCUtils
  structure CT = ConstantTerm
  structure IDMap = IEnv
  structure ANU = ANormalUtils

  (******************************************************************************)

  fun printBUCExp exp = 
      print ((Control.prettyPrint (BC.format_bucexp [] exp)) ^ "\n")

  structure BUCExp_ord:ordsig = struct 
    type ord_key = BC.bucexp

    fun wordPairCompare ((x1,y1),(x2,y2)) =
        case Word32.compare (x1,x2) of
          GREATER => GREATER
        | EQUAL => Word32.compare(y1,y2)
        | LESS => LESS

    fun compare (x,y) =
        case (x,y) of
          (BC.BUCCONSTANT {value=c1,...}, BC.BUCCONSTANT {value=c2,...}) =>
          CT.compare (c1,c2)
        | (BC.BUCCONSTANT _, _) =>  LESS

        | (BC.BUCVAR _, BC.BUCCONSTANT _) => GREATER
        | (BC.BUCVAR {varInfo = {id=n1,...},...}, BC.BUCVAR {varInfo = {id=n2,...},...}) =>
          ID.compare(n1, n2)
        | (BC.BUCVAR _, _) => LESS

        | (BC.BUCENVACC _,BC.BUCCONSTANT _ ) => GREATER
        | (BC.BUCENVACC _,BC.BUCVAR _ ) => GREATER
        | (BC.BUCENVACC {nestLevel=n1, offset = i1,...},
           BC.BUCENVACC {nestLevel=n2, offset = i2,...}) => 
          wordPairCompare((n1,i1),(n2,i2))
        | (BC.BUCENVACC _,_ ) => LESS

        | (BC.BUCENVACCINDIRECT _,BC.BUCCONSTANT _ ) => GREATER
        | (BC.BUCENVACCINDIRECT _,BC.BUCVAR _ ) => GREATER
        | (BC.BUCENVACCINDIRECT _,BC.BUCENVACC _ ) => GREATER
        | (BC.BUCENVACCINDIRECT {nestLevel=n1,indirectOffset=i1,...},
           BC.BUCENVACCINDIRECT {nestLevel=n2,indirectOffset=i2,...}) => 
          wordPairCompare((n1,i1),(n2,i2))

        | _ =>  raise Control.Bug "invalid atomEnv"
  end

  structure AtomEnv = BinaryMapFn(BUCExp_ord)

  structure Code = struct

    type singleCodeEntry = {funLabel : id, funInfo : funInfo, body : anexp}
    datatype codeEntry = 
           CLS of singleCodeEntry
         | REC of singleCodeEntry list

    val codeList = ref (nil : codeEntry list)
    
    fun addCode x = codeList := x :: !codeList
                    
    fun init () = codeList := nil
  end

  datatype anbinds = 
           SINGLE of varInfo * anexp 
         | MULTI of anbinds * anbinds
         | EMPTY

  (****************************************************************************************)


  fun getLocOfBinds binds =
      case binds of
        SINGLE (varInfo, anexp) => ANU.getLocOfExp anexp
      | MULTI(left, right) =>
        let
          val leftLoc = getLocOfBinds left
          val rightLoc = getLocOfBinds right
        in
          if leftLoc = Loc.noloc
          then rightLoc
          else
            if rightLoc = Loc.noloc
            then leftLoc
            else Loc.mergeLocs (leftLoc, rightLoc)
        end
      | EMPTY => Loc.noloc

  fun newVar (ty,varKind) = 
      let 
        val id = T.newVarId()
      in
        {id=id,displayName="$" ^ (ID.toString id),ty=ty,varKind=varKind}
      end

  fun isAtomExp x =
      case x of
        BC.BUCCONSTANT _ => true
      | BC.BUCVAR _ => true
      | BC.BUCENVACC _ => true
      | BC.BUCENVACCINDIRECT _ => true
      | _ => false

  fun lookupAtom (atomEnv,bucexp) =
      case AtomEnv.find(atomEnv,bucexp) of
        SOME v => v
      | _ => raise Control.Bug "atom not found"

  fun convertTy ty =
      case TU.compactTy ty of
        T.ATOMty => ATOM
      | T.DOUBLEty => DOUBLE
      | T.BOXEDty => BOXED
      | T.BOUNDVARty tid  => TYVAR tid
      | _ => raise Control.Bug "invalid compact type"

  fun convertVarInfo {id,displayName,ty,varKind} =
      let
        val varKind' = 
            case varKind of
              BC.ARG => ARG
            | BC.LOCAL => LOCAL
            | _ => raise Control.Bug "invalid varkind"
      in
        {id=id,displayName=displayName,ty=convertTy ty,varKind=varKind'}
      end 


  fun convertFunInfo 
          atomEnv 
          {tyvars,bitmapFree,tagArgs,sizevals,args,resultTy} 
          loc =
      let
        fun tidOf ty =
            case convertTy ty of
              TYVAR tid => tid
            | _ => raise Control.Bug "tid"

        (* tagArg must be an argument which is already recorded in the atomEnv*)
        fun tagOf v = lookupAtom (atomEnv,BC.BUCVAR {varInfo = v,loc = loc})

        fun sizeOf e =
            case e of
              BC.BUCVAR _ => lookupAtom(atomEnv,e)
            (* envacc size must be converted into local variable*)
            | BC.BUCENVACC _ => lookupAtom(atomEnv,e) 
            | _ => raise Control.Bug "convert funinfo"

      in
        {
         (* stack frame records are sorted by tyvar order: ARG < FREE*)
         tyvars = map tidOf tyvars, 
         bitmapFree = 
             case bitmapFree of
               BC.BUCCONSTANT {value = CT.WORD 0w0,loc} => 
               ANCONSTANT{value=CT.WORD 0w0,loc=loc}
             | BC.BUCENVACC{nestLevel=0w0,offset=i,variableTy,loc} =>
               ANENVACC{nestLevel=0w0,offset=i,loc=loc}
             | BC.BUCENVACC _ => raise Control.Bug "invalid bitmapFree(envacc)"
             | BC.BUCENVACCINDIRECT _ => raise Control.Bug "invalid bitmapFree(envaccind)"
             | _ => raise Control.Bug "invalid bitmapFree",
         tagArgs = map tagOf tagArgs,
         sizevals = map sizeOf sizevals,
         args = map 
                    (fn v => 
                        case lookupAtom(atomEnv,BC.BUCVAR {varInfo = v, loc = loc}) of
                          ANVAR {varInfo,...} => varInfo
                        | _ => raise Control.Bug "invalid argument"
                    ) 
                    args,
         resultTy = convertTy resultTy
        }
      end

  infix 8 @@

  fun op @@ (binds1,binds2) = MULTI(binds1,binds2)

  fun makeExp (EMPTY,exp) = exp
    | makeExp (SINGLE(varInfo,exp),rest) =
      let 
        val loc = Loc.mergeLocs (ANU.getLocOfExp exp, ANU.getLocOfExp rest)
      in 
        ANLET{boundVar = varInfo, boundExp = exp, mainExp = rest, loc = loc} 
      end
    | makeExp (MULTI(binds1,binds2),rest) =
      makeExp(binds1,makeExp(binds2,rest))

  fun compileInlineExp atomEnv (bucexp,ty) =
      let
        val loc = BU.getLocOfExp bucexp
        val (atomEnv',anbinds,anexp) = compileExp atomEnv bucexp
      in
        case anexp of
          ANVAR _ => (atomEnv',anbinds,anexp)
        | _ =>
          let
            val newVar = newVar(ty,LOCAL)
            val atomEnv' =
                if isAtomExp bucexp 
                then AtomEnv.insert(atomEnv',bucexp,ANVAR {varInfo = newVar, loc=loc})
                else atomEnv'
          in
            (atomEnv',anbinds @@ (SINGLE(newVar,anexp)),ANVAR {varInfo = newVar, loc=loc})
          end
      end

  and compileExp atomEnv bucexp =
      case bucexp of
        BC.BUCCONSTANT {value, loc} =>
        (
         case AtomEnv.find(atomEnv,bucexp) of
           SOME anexp => (atomEnv,EMPTY,anexp)
         | _ => (atomEnv,EMPTY,ANCONSTANT {value=value, loc=loc}) 
        )
      | BC.BUCVAR {varInfo, loc} =>
        (
         case AtomEnv.find(atomEnv,bucexp) of
           SOME anexp => (atomEnv,EMPTY,anexp)
         | _ => 
           raise Control.Bug ("variable not found:" ^ (#displayName varInfo))
        )
      | BC.BUCENVACC {nestLevel,offset,variableTy,loc} => 
        (
         case AtomEnv.find(atomEnv,bucexp) of
           SOME anexp => (atomEnv,EMPTY,anexp)
         | _ => 
           (
            atomEnv,
            EMPTY,
            ANENVACC {nestLevel = nestLevel, offset = offset, loc = loc}
           ) 
        )
      | BC.BUCENVACCINDIRECT {nestLevel,indirectOffset,variableTy,loc} =>
        (
         case AtomEnv.find(atomEnv,bucexp) of
           SOME anexp => (atomEnv,EMPTY,anexp)
         | _ => 
           (
            atomEnv,
            EMPTY,
            ANENVACCINDIRECT {nestLevel = nestLevel, indirectOffset = indirectOffset, loc = loc}
           ) 
        )
      | BC.BUCLABEL _ => raise Control.Bug "label"
      | BC.BUCGETGLOBALVALUE {arrayIndex,offset,ty,loc} =>
        (
         atomEnv,
         EMPTY,
         ANGETGLOBALVALUE
             {
              arrayIndex = arrayIndex,
              offset = offset,
              loc = loc
             }
        )
      | BC.BUCSETGLOBALVALUE {arrayIndex,offset,valueExp,ty,loc} =>
        let
          val (atomEnv',valueBinds,valueExp') =
              compileInlineExp atomEnv (valueExp,convertTy ty)
        in
          (
           atomEnv',
           valueBinds,
           ANSETGLOBALVALUE
               {
                arrayIndex = arrayIndex,
                offset = offset,
                valueExp = valueExp',
                loc = loc
               }
          )
        end 
      | BC.BUCINITARRAY {arrayIndex,size,elemTy,loc} =>
        let
          val operand = 
              {
               arrayIndex = arrayIndex,
               size = size,
               loc = loc
              }
        in
          case convertTy elemTy of
            ATOM => (atomEnv,EMPTY,ANINITARRAYUNBOXED operand)
          | BOXED => (atomEnv,EMPTY,ANINITARRAYBOXED operand)
          | DOUBLE => (atomEnv,EMPTY,ANINITARRAYDOUBLE operand)
          | _ => raise Control.Bug "global object must not have arbitrary type"
        end
      | BC.BUCPRIMAPPLY {primOp = {name,ty},argExpList,argTyList,loc} =>
        let
          val (atomEnv',argBinds,argExpList') = 
              compileExpList atomEnv (argExpList,map convertTy argTyList)
        in
          (
            atomEnv',
            argBinds,
            ANPRIMAPPLY
                {
                 primOp = {name=name,ty=convertTy ty},
                 argExpList = argExpList',
                 loc = loc
                }
          )
        end
      | BC.BUCFOREIGNAPPLY {funExp,argExpList,argTyList,convention,loc} =>
        let
          val (atomEnv',funcBinds,funExp') = 
              compileInlineExp atomEnv (funExp,ATOM)
          val argTyList' = map convertTy argTyList
          val (atomEnv',argBinds,argExpList') =
              compileExpList atomEnv' (argExpList, argTyList')
        in
          (
            atomEnv',
            funcBinds @@ argBinds,
            ANFOREIGNAPPLY
                {
                 funExp = funExp',
                 argExpList = argExpList',
                 argTyList = argTyList',
                 convention = convention,
                 loc = loc
                }
          )
        end
      | BC.BUCEXPORTCALLBACK {funExp,argTyList,resultTy,loc} =>
        let
          val (atomEnv',funcBinds,funExp') = 
              compileInlineExp atomEnv (funExp,BOXED)
          val argTyList' = map convertTy argTyList
          val resultTy' = convertTy resultTy
        in
          (
            atomEnv',
            funcBinds,
            ANEXPORTCALLBACK
                {
                 funExp = funExp',
                 argTyList = argTyList',
                 resultTy = resultTy',
                 loc = loc
                }
          )
        end
      | BC.BUCAPPLY {funExp,argExpList,argSizeList,argTyList,loc} =>
        let
          val (atomEnv',funcBinds,funExp') = 
              compileInlineExp atomEnv (funExp,BOXED) 
          val (atomEnv',argBinds,argExpList') =
              compileExpList atomEnv' (argExpList,map convertTy argTyList)
          val (atomEnv',sizeBinds,argSizeList') =
              compileExpList atomEnv' (argSizeList,map (fn _ => ATOM) argSizeList)
        in
          (
           atomEnv',
           funcBinds @@ argBinds @@ sizeBinds,
           ANAPPLY
               {
                funExp = funExp',
                argExpList = argExpList',
                argSizeList = argSizeList',
                loc = loc
               }
          )
        end
      | BC.BUCRECCALL {funExp = BC.BUCLABEL {label,...},argExpList,argSizeList,argTyList,loc} =>
        let
          val (atomEnv',argBinds,argExpList') =
              compileExpList atomEnv (argExpList,map convertTy argTyList)
          val (atomEnv',sizeBinds,argSizeList') =
              compileExpList atomEnv' (argSizeList,map (fn _ => ATOM) argSizeList)
        in
          (
           atomEnv',
           argBinds @@ sizeBinds,
           ANRECCALL
               {
                funLabel = label,
                argExpList = argExpList',
                argSizeList = argSizeList',
                loc = loc
               }
          )
        end
      | BC.BUCRECCALL _ => raise Control.Bug "invalid reccall"
      | BC.BUCRECORD{bitmapExp,totalSizeExp,fieldList,fieldSizeList,fieldTyList,loc} =>
        let
          val (atomEnv',bitmapBinds,bitmapExp') = 
              compileInlineExp atomEnv (bitmapExp,ATOM) 
          val (atomEnv',totalSizeBinds,totalSizeExp') = 
              compileInlineExp atomEnv' (totalSizeExp,ATOM) 
          val (atomEnv',fieldBinds,fieldList') =
              compileExpList atomEnv' (fieldList,map convertTy fieldTyList)
          val (atomEnv',fieldSizeBinds,fieldSizeList') =
              compileExpList
                  atomEnv' (fieldSizeList,map (fn _ => ATOM) fieldSizeList)
        in
          (
           atomEnv',
           bitmapBinds @@ totalSizeBinds @@ fieldBinds @@ fieldSizeBinds,
           ANRECORD
               {
                bitmapExp = bitmapExp',
                totalSizeExp = totalSizeExp',
                fieldList = fieldList',
                fieldSizeList = fieldSizeList',
                loc = loc
               }
          )
        end
      | BC.BUCARRAY {bitmapExp,sizeExp,initialValue,elementTy,loc} =>
        let
          val (atomEnv',binds,[bitmapExp',sizeExp',initialValue']) =
              compileExpList 
                  atomEnv 
                  ([bitmapExp,sizeExp,initialValue],[ATOM,ATOM,convertTy elementTy])
        in
          (
           atomEnv',
           binds,
           ANARRAY
               {
                bitmapExp = bitmapExp',
                sizeExp = sizeExp',
                initialValue = initialValue',
                loc = loc
               }
          )
        end
      | BC.BUCMODIFY {recordExp,nestLevel,offset,elementExp,elementTy,loc} =>
        let
          val (atomEnv',binds,[recordExp',nestLevel',offset',elementExp']) =
              compileExpList 
                  atomEnv 
                  ([recordExp,nestLevel,offset,elementExp],[BOXED,ATOM,ATOM,convertTy elementTy])
        in
          (
           atomEnv',
           binds,
           ANMODIFY
               {
                recordExp = recordExp',
                nestLevel = nestLevel',
                offset = offset',
                elementExp = elementExp',
                loc = loc
               }
          )
        end
      | BC.BUCRAISE {exceptionExp,loc} =>
        let
          val (atomEnv',exnBinds,exceptionExp') = 
              compileInlineExp atomEnv (exceptionExp,BOXED)
        in
          (atomEnv',exnBinds,ANRAISE {exceptionExp = exceptionExp', loc = loc})
        end
      | BC.BUCHANDLE {mainExp,exnVar,handler,loc} =>
        let
          val (_,expBinds,mainExp') = compileExp atomEnv mainExp
          val exnVar' = convertVarInfo exnVar
          val (_,handlerBinds,handler') =
              compileExp 
                  (AtomEnv.insert
                       (
                        atomEnv,
                        BC.BUCVAR {varInfo = exnVar, loc = loc},
                        ANVAR {varInfo = exnVar', loc = loc}
                       )
                  )
                  handler
        in
          (
           atomEnv,
           EMPTY,
           ANHANDLE
               {
                mainExp = makeExp(expBinds,mainExp'),
                exnVar = exnVar',
                handler = makeExp(handlerBinds,handler'),
                loc = loc
               }
          )
        end
      | BC.BUCPOLY {exp,...} => compileExp atomEnv exp
      | BC.BUCTAPP {polyExp,...} =>compileExp atomEnv polyExp
      | BC.BUCCODE _ => raise Control.Bug "invalid code"
      | BC.BUCCLOSURE {code = BC.BUCLABEL {label=label,...},env,loc} =>
        let
          val (atomEnv',binds,env') =
              compileInlineExp atomEnv (env,BOXED)
        in
          (
           atomEnv',
           binds,
           ANCLOSURE{funLabel = label,env = env',loc = loc}
          )
        end
      | BC.BUCCLOSURE {code = BC.BUCCODE {funInfo,body,loc = locOfBody},env,loc} =>
        let
          val (funInfo',body') = compileCode(funInfo,body,locOfBody)
          val label = T.newVarId()
          val _ = Code.addCode(Code.CLS{funLabel = label,funInfo = funInfo', body = body'})
          val (atomEnv',binds,env') =
              compileInlineExp atomEnv (env,BOXED)
        in
          (atomEnv',binds,ANCLOSURE{funLabel = label,env = env',loc = loc})
        end
      | BC.BUCCLOSURE _ => raise Control.Bug "invalid closure"
      | BC.BUCRECCLOSURE {code = BC.BUCLABEL {label,...}, loc} =>
        (atomEnv,EMPTY,ANRECCLOSURE {funLabel = label, loc = loc})
      | BC.BUCRECCLOSURE _ => raise Control.Bug "invalid recclosure"
      | BC.BUCSWITCH {switchExp,expTy,branches,defaultExp,loc} =>
        let
          val (atomEnv',switchExpBinds,switchExp') =
              compileInlineExp atomEnv (switchExp,convertTy expTy)
          val branches' =
              map
                  (fn (c,e) =>
                      let
                        val (_,binds,e') = compileExp atomEnv' e
                      in
                        (c,makeExp(binds,e'))
                      end
                  )
                  branches
          val (_,binds,defaultExp') = compileExp atomEnv' defaultExp
        in
          (
           atomEnv',
           switchExpBinds,
           ANSWITCH
               {
                switchExp = switchExp',
                branches = branches',
                defaultExp = makeExp(binds,defaultExp'),
                loc = loc
               }
          )
        end
      | BC.BUCLET {declList,mainExp,loc} =>
        let
          val (atomEnv',binds) = compileDeclList atomEnv declList
          val (atomEnv',expBinds,mainExp') = compileExp atomEnv' mainExp 
        in
          (atomEnv',binds @@ expBinds,mainExp')
        end
      | BC.BUCSEQ{expList = [exp],expTyList = [ty],loc} => compileExp atomEnv exp
      | BC.BUCSEQ{expList = exp::expList,expTyList = ty::tyList,loc} =>
        let
          val (atomEnv',expBinds,exp') =
              compileInlineExp atomEnv (exp,convertTy ty)
          val (atomEnv',binds,rest) =
              compileExp atomEnv' (BC.BUCSEQ{expList = expList,expTyList = tyList,loc = loc})
        in
          (atomEnv',expBinds @@ binds,rest)
        end
      | BC.BUCSEQ _ => raise Control.Bug "invalid sequence"
      | BC.BUCCAST{exp,expTy,loc} => compileInlineExp atomEnv (exp,convertTy expTy)
      | BC.BUCGETFIELD{blockExp,nestLevel,offset,loc} => 
        let
          val (atomEnv',binds,[blockExp',nestLevel',offset']) = 
              compileExpList atomEnv ([blockExp,nestLevel,offset],[BOXED,ATOM,ATOM])
        in
          (
           atomEnv',
           binds,
           ANGETFIELD
               {
                blockExp = blockExp',
                nestLevel = nestLevel',
                offset = offset',
                loc = loc
               }
          )
        end
      | BC.BUCSETFIELD{blockExp,nestLevel,offset,valueExp,expTy,loc} =>
        let
          val (atomEnv',binds,[blockExp',nestLevel',offset',valueExp']) =
              compileExpList
                  atomEnv
                  ([blockExp,nestLevel,offset,valueExp],[BOXED,ATOM,ATOM,convertTy expTy])
        in
          (
           atomEnv', 
           binds, 
           ANSETFIELD
               {
                blockExp = blockExp',
                nestLevel = nestLevel',
                offset = offset',
                valueExp = valueExp',
                loc = loc
               }
          )
        end
      | BC.BUCSETTAIL {consExp, offsetExp, newTailExp,loc} =>
        let
          val (atomEnv',binds,[newConsExp, newOffsetExp, newNewTailExp]) =
              compileExpList
                  atomEnv
                  ([consExp, offsetExp, newTailExp],[BOXED,ATOM, BOXED])
        in
          (
           atomEnv', 
           binds, 
           ANSETTAIL
               {
                consExp = newConsExp,
                newTailExp = newNewTailExp,
                offsetExp = newOffsetExp,
                loc = loc
               }
          )
        end

  and compileExpList atomEnv ([],[]) = (atomEnv,EMPTY,[])
    | compileExpList atomEnv (exp::expList,ty::tyList) =
      let
        val (atomEnv',expBinds,exp') = 
            compileInlineExp atomEnv (exp,ty)
        val (atomEnv',binds,expList') =
            compileExpList atomEnv' (expList,tyList)
      in
        (atomEnv',expBinds @@ binds,exp'::expList')
      end

  and compileCode (funInfo,body,loc) = 
      let
        val atomEnv = 
            foldr 
                (fn (v,S) => 
                    AtomEnv.insert
                        (
                         S,
                         BC.BUCVAR {varInfo = v, loc = loc}, 
                         ANVAR {varInfo = convertVarInfo v, loc = loc}
                        )
                )
                AtomEnv.empty 
                (#args funInfo)
        val (atomEnv,envaccBinds) = 
            foldr 
                (fn (e,(S,L)) =>
                    case  e of
                      BC.BUCVAR {varInfo,...} => (S,L)
                    (*if size is a free variable, we convert it to a local variable*)
                    | BC.BUCENVACC {nestLevel,offset,variableTy, loc} => 
                      let
                        val varInfo = newVar(ATOM,LOCAL)
                        val bind = SINGLE
                                       (
                                        varInfo,
                                        ANENVACC {nestLevel = nestLevel,offset = offset,loc = loc}
                                       )
                      in
                        (AtomEnv.insert(S,e,ANVAR {varInfo = varInfo, loc = loc}),bind @@ L)
                      end
                    | BC.BUCENVACCINDIRECT _ => raise Control.Bug "size must be a variable (arg/envacc)(2)"
                    | _ => raise Control.Bug "size must be a variable (arg/envacc)"
                )
                (atomEnv,EMPTY)
                (#sizevals funInfo)
        val (_,binds,body') = compileExp atomEnv body
        val funInfo' = convertFunInfo atomEnv funInfo loc
      in
        (funInfo',makeExp(envaccBinds @@ binds,body'))
      end

  and compileRecBinds atomEnv loc recBinds =
      let
        val recBinds' =
            map
                (fn (label,ty,funInfo,body) =>
                    let val (funInfo',body') = compileCode (funInfo,body,loc)
                    in {funLabel = label, funInfo = funInfo', body = body'}
                    end
                )
                recBinds
        val _ = Code.addCode(Code.REC recBinds')
      in
        (atomEnv,EMPTY)
      end

  and compileBinds atomEnv loc [] = (atomEnv,EMPTY)
    | compileBinds atomEnv loc ((BC.VALIDVAR varInfo,exp)::rest) =
      let
        val (atomEnv',expBinds,exp') = compileExp atomEnv exp
        val (atomEnv',bind) =
            case exp' of
              ANVAR {loc,...} => 
              let
                val atomEnv' =
                    AtomEnv.insert(atomEnv',BC.BUCVAR {varInfo = varInfo, loc = loc},exp')
              in 
                (atomEnv',EMPTY)
              end
            | _ => 
              let
                val varInfo' = convertVarInfo varInfo
                val atomEnv' =
                    AtomEnv.insert
                        (
                          atomEnv',
                          BC.BUCVAR {varInfo = varInfo, loc = loc},
                          ANVAR {varInfo = varInfo', loc = loc}
                        )
              in 
                (atomEnv',SINGLE(varInfo',exp'))
              end
        val (atomEnv',restBinds) = compileBinds atomEnv' loc rest
      in
        (atomEnv',expBinds @@ bind @@ restBinds)
      end
    | compileBinds atomEnv loc ((BC.VALIDWILD ty,exp)::rest) =
      let
        val (atomEnv',expBinds,exp') = compileExp atomEnv exp
        val bind =
            case exp' of
              ANVAR _ => EMPTY 
            | _ => SINGLE(newVar(convertTy ty,LOCAL),exp')
        val (atomEnv',restBinds) = compileBinds atomEnv' loc rest
      in
        (atomEnv',expBinds @@ bind @@ restBinds)
      end

  and compileDecl atomEnv bmdecl = 
      case bmdecl of
        BC.BUCVAL {bindList, loc} => compileBinds atomEnv loc bindList
      | BC.BUCVALREC {recbindList, loc} => 
        compileRecBinds atomEnv loc recbindList
      | BC.BUCVALPOLYREC {btvEnv,recbindList,loc} => 
        compileRecBinds atomEnv loc recbindList
      | BC.BUCLOCALDEC {localDeclList,mainDeclList,loc} =>
        let
          val (atomEnv',localBinds) = compileDeclList atomEnv localDeclList
          val (atomEnv',binds) = compileDeclList atomEnv' mainDeclList
        in
          (atomEnv',localBinds @@ binds)
        end
      | BC.BUCEMPTY loc => (atomEnv,EMPTY)

  and compileDeclList atomEnv [] = (atomEnv,EMPTY)
    | compileDeclList atomEnv (decl::rest) =
      let
        val (atomEnv',binds) = compileDecl atomEnv decl
        val (atomEnv',restBinds) = compileDeclList atomEnv' rest
      in
        (atomEnv',binds @@ restBinds)
      end

(*********************************************************************************)

  fun translate decls =
      let
        val _ = Code.init()
        val (atomEnv',binds) = compileDeclList AtomEnv.empty decls
        val bindsLoc = getLocOfBinds binds
      in
        foldl 
            (fn (Code.CLS {funLabel,funInfo,body},rest) =>
                ANLETLABEL 
                    {
                     funLabel = funLabel, 
                     funInfo = funInfo, 
                     funBody = body, 
                     mainExp = rest, 
                     loc = bindsLoc
                    }
              | (Code.REC decls,rest) => 
                ANVALREC {recbindList = decls, mainExp = rest, loc = bindsLoc}
            )
            (makeExp(binds,ANEXIT bindsLoc))
            (!Code.codeList)        
      end

end
