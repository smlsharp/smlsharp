(**
 * @author Liu Bochao
 * @version $Id: TypedLambdaPicklerTest001.sml,v 1.3 2006/12/10 08:32:55 kiyoshiy Exp $
 *)
structure TypedLambdaPicklerTest001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = TypesPickler

  structure TL = TypedLambda
  structure T = Types
  (***************************************************************************)

  val sampleTyCon1 = 
      {
        name = "foo",
        strpath = Path.NilPath,
        tyvars = [false],
        id = ID.generate (),
        abstract = true,
        eqKind = ref T.EQ,
        boxedKind = ref T.BOXEDty,
        datacon = ref SEnv.empty
      } : T.tyCon

  val sampleConstantExp = 
      {value = T.STRING "foo" ,loc = Loc.noloc}
      
  val sampleConstantTLExp = TL.TLCONSTANT sampleConstantExp
                            
  val sampleVarIdInfo = 
      {id = ID.generate (), displayName = "foo", ty = T.BOXEDty}
      
  val sampleTldecl = TL.TLEMPTY Loc.noloc

  fun testTlexp tlexp =
      let
        val pickled = Pickle.toString TypedLambdaPickler.tlexp tlexp
        val tlexp2 = Pickle.fromString TypedLambdaPickler.tlexp pickled
      in
        ()
      end

  fun testTLFOREIGNAPPLY0001 () =
      testTlexp
      (TL.TLFOREIGNAPPLY {funExp = sampleConstantTLExp,
                          instTyList = [T.ATOMty,T.ATOMty,T.ATOMty],
                          argExpList = [sampleConstantTLExp],
                          argTyList = [T.ATOMty,T.ATOMty,T.ATOMty],
                          loc = Loc.noloc})

  fun testTLCONSTANT0001 () = testTlexp sampleConstantTLExp 

  fun testTLEXCEPTIONTAG0001 () = 
      testTlexp 
          (TL.TLEXCEPTIONTAG {tagValue = 1, loc = Loc.noloc})

  fun testTLVAR0001 () = 
      testTlexp 
          (TL.TLVAR {varInfo = sampleVarIdInfo, loc = Loc.noloc})
      
  fun testTLGETGLOBAL0001 () =
      testTlexp
          (TL.TLGETGLOBAL ("abcde", T.ATOMty, Loc.noloc))

  fun testTLGETGLOBALVALUE0001 () =
      testTlexp
          (TL.TLGETGLOBALVALUE {arrayIndex = 0w3,
                             offset = 1, 
                             ty = T.ATOMty,
                             loc = Loc.noloc})

  fun testTLSETGLOBALVALUE0001 () =
      testTlexp
      (TL.TLSETGLOBALVALUE  {arrayIndex = 0w3,
                             offset = 100, 
                             valueExp = sampleConstantTLExp,
                             ty = T.ATOMty,
                             loc = Loc.noloc})
      
  fun testTLINITARRAY0001 () =
      testTlexp
      (TL.TLINITARRAY {arrayIndex = 0w4, 
                    size = 1024, 
                    elemTy = T.BOXEDty, 
                    loc = Loc.noloc})

  fun testTLGETFIELD0001 () =
      testTlexp
      (TL.TLGETFIELD {arrayExp = sampleConstantTLExp,
                   indexExp = sampleConstantTLExp, 
                   elementTy = T.ATOMty,
                   loc = Loc.noloc})
      
  fun testTLSETFIELD0001 () =
      testTlexp
      (TL.TLSETFIELD  {valueExp = sampleConstantTLExp, 
                    arrayExp = sampleConstantTLExp,
                    indexExp = sampleConstantTLExp, 
                    elementTy = T.ATOMty,
                    loc = Loc.noloc})

  fun testTLARRAY0001 () =
      testTlexp 
      (TL.TLARRAY {sizeExp = sampleConstantTLExp, 
                initialValue = sampleConstantTLExp, 
                elementTy = T.ATOMty, 
                resultTy  = T.ATOMty, 
                loc = Loc.noloc})

  fun testTLPRIMAPPLY0001 () =
      testTlexp
          (TL.TLPRIMAPPLY {primOp = {name = "bar", ty = T.BOXEDty},
                        instTyList = [T.ATOMty, T.ATOMty],
                        argExpList = [sampleConstantTLExp,sampleConstantTLExp],
                        loc = Loc.noloc})
          
  fun testTLAPPM0001 () =
      testTlexp
          (TL.TLAPPM {funExp = sampleConstantTLExp, 
                   funTy = T.BOXEDty, 
                   argExpList = [sampleConstantTLExp, sampleConstantTLExp,sampleConstantTLExp], 
                   loc = Loc.noloc})
          
  fun testTLMONOLET0001 () =
      testTlexp
          (TL.TLMONOLET {binds = [(sampleVarIdInfo,sampleConstantTLExp)],
                      bodyExp = sampleConstantTLExp,
                      loc = Loc.noloc})

  fun testTLLET0001 () =
      testTlexp 
      (TL.TLLET {localDeclList = [sampleTldecl],
              mainExpList =[sampleConstantTLExp],
              mainExpTyList = [T.ATOMty],
              loc = Loc.noloc})

  fun testTLRECORD0001 () =
      testTlexp
      (TL.TLRECORD {expList = [sampleConstantTLExp], 
                 internalTy = T.ATOMty, 
                 externalTy = SOME T.ATOMty, 
                 loc = Loc.noloc})

  fun testTLSELECT0001 () =
      testTlexp
          (TL.TLSELECT {recordExp = sampleConstantTLExp, 
                     indexExp = sampleConstantTLExp, 
                     recordTy = T.ATOMty, 
                     loc = Loc.noloc})

  fun testTLMODIFY0001 () =
      testTlexp
      (TL.TLMODIFY 
           {
            recordExp  = sampleConstantTLExp, 
            recordTy = T.ATOMty, 
            indexExp = sampleConstantTLExp, 
            elementExp = sampleConstantTLExp, 
            elementTy = T.ATOMty, 
            loc = Loc.noloc})

  fun testTLRAISE0001 () =
      testTlexp
      (TL.TLRAISE 
           {
            argExp = sampleConstantTLExp, 
            resultTy = T.ATOMty, 
            loc = Loc.noloc})

  fun testTLHANDLE0001 () =
      testTlexp
      (TL.TLHANDLE {exp = sampleConstantTLExp,
                 exnVar = sampleVarIdInfo,
                 handler = sampleConstantTLExp,
                 loc = Loc.noloc})

  fun testTLFNM0001 () =
      testTlexp
      (TL.TLFNM {argVarList = [sampleVarIdInfo],
                 bodyTy = T.ATOMty,
                 bodyExp = sampleConstantTLExp, 
                 loc = Loc.noloc})

  fun testTLPOLY0001 () =
      testTlexp
      (TL.TLPOLY {btvEnv = IEnv.singleton (1,{index = 0, recKind = T.UNIV, eqKind = T.EQ}),
               expTyWithoutTAbs = T.ATOMty,
               exp = sampleConstantTLExp,
               loc = Loc.noloc})

  fun testTLTAPP0001 () =
      testTlexp
      (TL.TLTAPP {exp = sampleConstantTLExp, 
               expTy = T.ATOMty, 
               instTyList = [T.ATOMty], 
               loc = Loc.noloc})

  fun testTLSWITCH0001 () =
      testTlexp
      (TL.TLSWITCH
           {
             switchExp = sampleConstantTLExp, 
             expTy = T.BOXEDty, 
             branches =
             [{constant = sampleConstantTLExp, exp = sampleConstantTLExp}],
             defaultExp = sampleConstantTLExp, 
             loc = Loc.noloc
           })

  fun testTLSEQ0001 () =
      testTlexp
      (TL.TLSEQ {expList = [sampleConstantTLExp],
              expTyList = [T.ATOMty],
              loc = Loc.noloc})

  fun testTLCAST0001 () =
       testTlexp
           (TL.TLCAST {exp = sampleConstantTLExp,
                    targetTy = T.ATOMty,
                    loc = Loc.noloc})

  fun testTLOFFSET0001 () =
       testTlexp
           (TL.TLOFFSET {recordTy = T.ATOMty, 
                      label = "foo",
                      loc = Loc.noloc})

  fun testTldecl tldecl =
      let
        val pickled = Pickle.toString TypedLambdaPickler.tldecl tldecl
        val tldecl2 = Pickle.fromString TypedLambdaPickler.tldecl pickled
      in
        ()
      end

  fun testTLVAL0001 tldecl =
      testTldecl 
          (TL.TLVAL 
               {bindList = [{boundValIdent = T.VALIDENTWILD T.ATOMty,
                             boundExp = sampleConstantTLExp}],
                loc = Loc.noloc})

  fun testTLVALREC0001 tldecl =
      testTldecl
          (TL.TLVALREC {recbindList = [{boundVar = sampleVarIdInfo,
                                     boundTy = T.ATOMty,
                                     boundExp = sampleConstantTLExp}],
                     loc = Loc.noloc})

  fun testTLVALPOLYREC0001 tldecl =
      testTldecl
          (TL.TLVALPOLYREC 
               {btvEnv = IEnv.singleton (1,{index = 0, recKind = T.UNIV, eqKind = T.EQ}),
                indexVars = [sampleVarIdInfo],
                recbindList = [{boundVar = sampleVarIdInfo,
                                boundTy = T.ATOMty, 
                                boundExp = sampleConstantTLExp}],
                loc = Loc.noloc})

  fun testTLLOCALDEC0001 tldecl =
      testTldecl
          (TL.TLLOCALDEC {localDeclList = [sampleTldecl],
                       mainDeclList = [sampleTldecl],
                       loc = Loc.noloc})

  fun testTLSETGLOBAL0001 tldecl =
      testTldecl
          (TL.TLSETGLOBAL ("bar", sampleConstantTLExp, Loc.noloc))

  fun testTLEMPTY0001 tldecl =
      testTldecl (TL.TLEMPTY Loc.noloc)

  (*********************************************************************)
  fun suite () =
      Test.labelTests
      [
       ("testTLFOREIGNAPPLY0001", testTLFOREIGNAPPLY0001),
       ("testTLCONSTANT0001",testTLCONSTANT0001),
       ("testTLEXCEPTIONTAG0001",testTLEXCEPTIONTAG0001),
       ("testTLVAR0001",testTLVAR0001),
       ("testTLGETGLOBAL0001",testTLGETGLOBAL0001),
       ("testTLGETGLOBALVALUE0001",testTLGETGLOBALVALUE0001),
       ("testTLSETGLOBALVALUE0001",testTLSETGLOBALVALUE0001),
       ("testTLINITARRAY0001",testTLINITARRAY0001),
       ("testTLGETFIELD0001",testTLGETFIELD0001),
       ("testTLSETFIELD0001",testTLSETFIELD0001),
       ("testTLARRAY0001",testTLARRAY0001),
       ("testTLPRIMAPPLY0001",testTLPRIMAPPLY0001),
       ("testTLAPPM0001",testTLAPPM0001),
       ("testTLMONOLET0001",testTLMONOLET0001),
       ("testTLLET0001",testTLLET0001),
       ("testTLRECORD0001",testTLRECORD0001),
       ("testTLSELECT0001",testTLSELECT0001),
       ("testTLMODIFY0001",testTLMODIFY0001),
       ("testTLRAISE0001",testTLRAISE0001),
       ("testTLHANDLE0001",testTLHANDLE0001),
       ("testTLFNM0001",testTLFNM0001),
       ("testTLPOLY0001",testTLPOLY0001),
       ("testTLTAPP0001",testTLTAPP0001),
       ("testTLSWITCH0001",testTLSWITCH0001),
       ("testTLSEQ0001",testTLSEQ0001),
       ("testTLCAST0001",testTLCAST0001),
       ("testTLOFFSET0001",testTLOFFSET0001),
       ("testTLVAL0001",testTLVAL0001),
       ("testTLVALREC0001",testTLVALREC0001),
       ("testTLVALPOLYREC0001",testTLVALPOLYREC0001),
       ("testTLLOCALDEC0001",testTLLOCALDEC0001),
       ("testTLSETGLOBAL0001",testTLSETGLOBAL0001),
       ("testTLEMPTY0001",testTLEMPTY0001)
      ]

  (***************************************************************************)

end
