(**
 * tests we created so far.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

(*
 * This file is dedicated to old tests we have created before the test
 * system was established.  It is not recommended to add a new test in
 * this file; create a new test file instead.
 *
 * Search for "ToDo" to find out tests that is not carried out automatically.
 *)

structure RegressionTests =
struct
structure P = ParserError
structure E = ElaborateError
structure N = NameEvalError
structure T = TypeInferenceError
structure M = MatchError
structure D = PartialDynamic
open SMLUnit.Test SMLUnit.Assert Compiler

val tests = TestList [

  Test
    ("001_equal",
     fn () => ignore (compile ["regression/001_equal.sml"])),
  Test
    ("002_sig",
     fn () => ignore (compile ["regression/002_sig.sml"])),
  Test
    ("003_datatype",
     fn () => ignore (compile ["regression/003_datatype.sml"])),
  Test
    ("004_datatype",
     fn () => (compile ["regression/004_datatype.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.NonFunction _),
                            (_,_,T.NonFunction _)])
                     => ()),
  Test
    ("005_datatype",
     fn () => ignore (compile ["regression/005_datatype.sml"])),
  Test
    ("006_int",
     fn () => ignore (compile ["regression/006_int.sml"])),
  Test
    ("007_polly",
     fn () => ignore (compile ["regression/007_polly.sml"])),
  Test
    ("008_length",
     fn () => ignore (compile ["regression/008_length.sml"])),
  Test
    ("009_append",
     fn () => ignore (compile ["regression/009_append.sml"])),
  Test
    ("010_cons",
     fn () => ignore (compile ["regression/010_cons.sml"])),
  Test
    ("011_nil",
     fn () => ignore (compile ["regression/011_nil.sml"])),
  Test
    ("012_case",
     fn () => ignore (compile ["regression/012_case.sml"])),
  Test
    ("013_sig",
     fn () => ignore (compile ["regression/013_sig.sml"])),
  Test
    ("014_foldl",
     fn () => ignore (compile ["regression/014_foldl.sml"])),
  Test
    ("015_app",
     fn () => ignore (compile ["regression/015_app.sml"])),
  Test
    ("016_select",
     fn () => ignore (compile ["regression/016_select.sml"])),
  Test
    ("017_app",
     fn () => ignore (compile ["regression/017_app.sml"])),
  Test
    ("018_handle",
     fn () => ignore (compile ["regression/018_handle.sml"])),
  Test
    ("019_polyfun",
     fn () => ignore (compile ["regression/019_polyfun.sml"])),
  Test
    ("020_nestedrecord",
     fn () => ignore (compile ["regression/020_nestedrecord.sml"])),
  Test
    ("021_export",
     fn () => ignore (compile ["regression/021_export.sml"])),
  Test
    ("022_exception",
     fn () => execute (link "" (compile ["regression/022_exception.sml"]))),
  Test
    ("023_exn",
     fn () => ignore (compile ["regression/023_exn.sml"])),
  Test
    ("024_polyraise",
     fn () => (compile ["regression/024_polyraise.sml"];
               fail "must cause a warning")
              handle CompileError
                       (_, [(_,_,M.MatchError ("match nonexhaustive", [_]))])
                     => ()),
  Test
    ("025_equal",
     fn () => ignore (compile ["regression/025_equal.sml"])),
  Test
    ("026_equal",
     fn () => execute (link "" (compile ["regression/026_equal.sml"]))),
  Test
    ("027_raise",
     fn () =>
        let
          val {errors, objfiles, ...} = compile' ["regression/027_raise.sml"]
        in
          case errors of
            [(_,_,T.ValueRestriction _)] => ()
          | errors => raiseCompileError errors;
          (execute (link "" objfiles);
           fail "must be aborted")
          handle Signaled (6, _) => ()
        end),
  Test
    ("028_utvar",
     fn () => ignore (compile ["regression/028_utvar.sml"])),
  Test
    ("029_utvar",
     fn () => ignore (compile ["regression/029_utvar.sml"])),
  Test
    ("030_uncaught",
     fn () => (execute (link "" (compile ["regression/030_uncaught.sml"]));
               fail "must be aborted")
              handle Signaled (6, _) => ()),
  Test
    ("032_sig",
     fn () => ignore (compile ["regression/032_sig.sml"])),
  Test
    ("034_ArrayArray",
     fn () =>
        execute
          (link "regression/034_ArrayArray.smi"
                (compile ["regression/034_ArrayArray.sml"]))),
  Test
    ("035_sig",
     fn () => ignore (compile ["regression/035_sig.sml"])),
  Test
    ("036_castToString",
     fn () => ignore (compile ["regression/036_castToString.sml"])),
  Test
    ("037_functor",
     fn () => ignore (compile ["regression/037_functor.sml"])),
  Test
    ("038_functor2",
     fn () => ignore (compile ["regression/038_functor2.sml"])),
  Test
    ("039_type",
     fn () => ignore (compile ["regression/039_type.sml"])),
  Test
    ("040_exception",
     fn () => ignore (compile ["regression/040_exception.sml"])),
  Test
    ("041_type",
     fn () => ignore (compile ["regression/041_type.sml"])),
  Test
    ("042_typerep",
     fn () => ignore (compile ["regression/042_typerep.sml"])),
  Test
    ("043_type",
     fn () => ignore (compile ["regression/043_type.sml"])),
  Test
    ("044_datatype",
     fn () => ignore (compile ["regression/044_datatype.sml"])),
  Test
    ("045_evality",
     fn () => ignore (compile ["regression/045_evality.sml"])),
  Test
    ("046_exnrep",
     fn () => ignore (compile ["regression/046_exnrep.sml"])),
  Test
    ("047_exnrep",
     fn () => (compile ["regression/047_exnrep.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideExceptionType _)])
                     => ()),
  Test
    ("048_opaquesig",
     fn () => ignore (compile ["regression/048_opaquesig.sml"])),
  Test
    ("050_sig",
     fn () => ignore (compile ["regression/050_sig.sml"])),
  Test
    ("051_typealias",
     fn () => ignore (compile ["regression/051_typealias.sml"])),
  Test
    ("052_undeftype",
     fn () => (compile ["regression/052_undeftype.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.TypNotFound _)])
                     => ()),
  Test
    ("053_typerep",
     fn () => ignore (compile ["regression/053_typerep.sml"])),
  Test
    ("054_word",
     fn () => ignore (compile ["regression/054_word.sml"])),
  Test
    ("055_exception",
     fn () => (compile ["regression/055_exception.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideExceptionType _)])
                     => ()),
  Test
    ("056_doubledval",
     fn () => (compile ["regression/056_doubledval.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.DuplicateVar _)])
                     => ()),
  Test
    ("057_wheretype",
     fn () => ignore (compile ["regression/057_wheretype.sml"])),
  Test
    ("058_functorTycast",
     fn () => ignore (compile ["regression/058_functorTycast.sml"])),
  Test
    ("059_opaqueint",
     fn () => (compile ["regression/059_opaqueint.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TypeAnnotationNotAgree _)])
                     => ()),
  Test
    ("060_functor",
     fn () => (compile ["regression/060_functor.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGTypUndefined _)])
                     => ()),
  Test
    ("061_functor",
     fn () => ignore (compile ["regression/061_functor.sml"])),
  Test
    ("062_functorPoly",
     fn () => ignore (compile ["regression/062_functorPoly.sml"])),
  Test
    ("063_functorexn",
     fn () => ignore (compile ["regression/063_functorexn.sml"])),
  Test
    ("064_functorDty",
     fn () => ignore (compile ["regression/064_functorDty.sml"])),
  Test
    ("065_functorPhantom",
     (* test for SML# specific feature *)
     fn () => (compile ["regression/065_functorPhantom.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.FunctorParamRestriction _)])
                     => ()),
  Test
    ("067_provide",
     fn () => ignore (compile ["regression/067_provide.sml"])),
  Test
    ("068_sig",
     fn () => ignore (compile ["regression/068_sig.sml"])),
  Test
    ("069_open",
     fn () => ignore (compile ["regression/069_open.sml"])),
  Test
    ("070_sig",
     fn () => ignore (compile ["regression/070_sig.sml"])),
  Test
    ("071_tyconarg",
     fn () => (compile ["regression/071_tyconarg.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.TypArity _)])
                     => ()),
  Test
    ("072_tyconarg",
     fn () => (compile ["regression/072_tyconarg.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.TypArity _)])
                     => ()),
  Test
    ("073_sigopen",
     fn () => ignore (compile ["regression/073_sigopen.sml"])),
  Test
    ("074_wheretype",
     fn () => ignore (compile ["regression/074_wheretype.sml"])),
  Test
    ("075_builtin",
     fn () => ignore (compile ["regression/075_builtin.sml"])),
  Test
    ("075_idNil",
     fn () => ignore (compile ["regression/075_idNil.sml"])),
  Test
    ("076_typeerror",
     fn () => (compile ["regression/076_typeerror.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.PatternExpMismatch _)])
                     => ()),
  Test
    ("077_sig",
     fn () => ignore (compile ["regression/077_sig.sml"])),
  Test
    ("077_sigopaque",
     fn () => ignore (compile ["regression/077_sigopaque.sml"])),
  Test
    ("078_sharing",
     fn () => (compile ["regression/078_sharing.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.TypUndefinedInSigshare _)])
                     => ()),
  Test
    ("079_functorsig",
     fn () => (compile ["regression/079_functorsig.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGDtyMismatch _)])
                     => ()),
  Test
    ("080_functorsig",
     fn () => ignore (compile ["regression/080_functorsig.sml"])),
  Test
    ("082_functor",
     fn () => (compile ["regression/082_functor.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGEqtype _)])
                     => ()),
  Test
    ("083_provide",
     fn () => ignore (compile ["regression/083_provide.sml"])),
  Test
    ("084_provide",
     fn () => ignore (compile ["regression/084_provide.sml"])),
  Test
    ("085_provide",
     fn () => ignore (compile ["regression/085_provide.sml"])),
  Test
    ("085_provide2",
     fn () => ignore (compile ["regression/085_provide2.sml"])),
  Test
    ("086_sig",
     fn () => (compile ["regression/086_sig.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGDtyRequired _),
                            (_,_,N.SIGVarUndefined _)])
                     => ()),
  Test
    ("087_functorexn",
     fn () => ignore (compile ["regression/087_functorexn.sml"])),
  Test
    ("088_functorarg",
     fn () => (compile ["regression/088_functorarg.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.TypNotFound _)])
                     => ()),
  Test
    ("089_functorarg",
     fn () => ignore (compile ["regression/089_functorarg.sml"])),
  Test
    ("090_functorexn",
     fn () => ignore (compile ["regression/090_functorexn.sml"])),
  Test
    ("091_functorarg",
     fn () => ignore (compile ["regression/091_functorarg.sml"])),
  Test
    ("092_requirefunctor",
     fn () => ignore (compile ["regression/092_requirefunctor.sml"])),
  Test
    ("093_datatype",
     fn () => ignore (compile ["regression/093_datatype.sml"])),
  Test
    ("094_provideopen",
     fn () => ignore (compile ["regression/094_provideopen.sml"])),
  Test
    ("095_valrec",
     fn () => ignore (compile ["regression/095_valrec.sml"])),
  Test
    ("096_providefun",
     fn () => ignore (compile ["regression/096_providefun.sml"])),
  Test
    ("097_providefun",
     fn () => ignore (compile ["regression/097_providefun.sml"])),
  Test
    ("098_rtlframe",
     fn () => ignore (compile ["regression/098_rtlframe.sml"])),
  Test
    ("099_provide",
     fn () => ignore (compile ["regression/099_provide.sml"])),
  Test
    ("100_evaltfun",
     fn () => ignore (compile ["regression/100_evaltfun.sml"])),
  Test
    ("101_functorapp",
     fn () =>
        ignore
          (link "regression/101_functorapp.smi"
                (compile ["regression/101_functorapp.sml",
                          "regression/101_functorapp2.sml"]))),
  Test
    ("102_functorprovide",
     fn () => ignore (compile ["regression/102_functorprovide.sml"])),
  Test
    ("103_unit",
     (* test for SML# specific feature *)
     fn () => (compile ["regression/103_unit.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TypeAnnotationNotAgree _)])
                     => ()),
  Test
    ("104_functorlink",
     fn () =>
        execute
          (link "regression/104_functorlink.sml"
                (compile ["regression/104_functorlink.sml",
                          "regression/104_functorlink2.sml",
                          "regression/104_functorlink3.sml"]))),
  Test
    ("105_functorexn",
     fn () => ignore (compile ["regression/105_functorexn.sml"])),
  Test
    ("106_functorexn",
     fn () => ignore (compile ["regression/106_functorexn.sml"])),
  Test
    ("107_functorexn",
     fn () => ignore (compile ["regression/107_functorexn.sml"])),
  Test
    ("108_functordty",
     fn () => ignore (compile ["regression/108_functordty.sml"])),
  Test
    ("109_functortype",
     fn () => ignore (compile ["regression/109_functortype.sml"])),
  Test
    ("110_exntype",
     fn () => ignore (compile ["regression/110_exntype.sml"])),
  Test
    ("111_functortype",
     fn () => ignore (compile ["regression/111_functortype.sml"])),
  Test
    ("112_errmsg",
     fn () => (compile ["regression/112_errmsg.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideEquality _)])
                     => ()),
  Test
    ("113_errmsg",
     fn () => (compile ["regression/113_errmsg.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideConType _)])
                     => ()),
  Test
    ("114_exnrep",
     fn () => ignore (compile ["regression/114_exnrep.sml"])),
  Test
    ("115_datatype",
     fn () => ignore (compile ["regression/115_datatype.sml"])),
  Test
    ("116_functorexn",
     fn () => ignore (compile ["regression/116_functorexn.sml"])),
  Test
    ("118_functorlift",
     fn () => ignore (compile ["regression/118_functorlift.sml"])),
  Test
    ("119_functor",
     fn () => ignore (compile ["regression/119_functor.sml"])),
  Test
    ("121_functor",
     fn () =>
        ignore
          (link "regression/121_functor.smi"
                (compile ["regression/121_functor.sml",
                          "regression/121_functor2.sml"]))),
  Test
    ("122_wheretype",
     fn () => ignore (compile ["regression/122_wheretype.sml"])),
  Test
    ("123_functor",
     fn () =>
        ignore
          (link "regression/123_functor0.smi"
                (compile ["regression/123_functor0.sml",
                          "regression/123_functor.sml"]))),
  Test
    ("124_open",
     fn () =>
        ignore
          (link "regression/124_open0.smi"
                (compile ["regression/124_open0.sml",
                          "regression/124_open.sml",
                          "regression/124_open2.sml"]))),
  Test
    ("125_functor",
     fn () => ignore (compile ["regression/125_functor.sml"])),
  Test
    ("126_functor",
     fn () => ignore (compile ["regression/126_functor.sml"])),
  Test
    ("127_functor",
     fn () => ignore (compile ["regression/127_functor.sml"])),
  Test
    ("128_functor",
     fn () => ignore (compile ["regression/128_functor.sml"])),
  Test
    ("129_functor",
     fn () => ignore (compile ["regression/129_functor.sml"])),
  Test
    ("130_recordunboxing",
     fn () =>
        execute
          (link "regression/130_recordunboxing0.smi"
                (compile ["regression/130_recordunboxing0.sml",
                          "regression/130_recordunboxing.sml"]))),
  Test
    ("131_functorty",
     fn () =>
        execute
          (link "regression/131_functorty.smi"
                (compile ["regression/131_functorty.sml",
                          "regression/131_functorty2.sml"]))),
  Test
    ("132_overload",
     fn () => (compile ["regression/132_overload.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TypeAnnotationNotAgree _)])
                     => ()),
  Test
    ("134_functor",
     fn () =>
        execute
          (link "regression/134_functor.smi"
                (compile ["regression/134_functor.sml",
                          "regression/134_functor2.sml"]))),
  Test
    ("135_uncurry",
     fn () => ignore (compile ["regression/135_uncurry.sml"])),
  Test
    ("136_sig",
     fn () => ignore (compile ["regression/136_sig.sml"])),
  Test
    ("137_functor",
     fn () =>
        ignore
          (link "regression/137_functor.smi"
                (compile ["regression/137_functor.sml",
                          "regression/137_functor2.sml",
                          "regression/137_functor3.sml"]))),
  Test
    ("138_sig",
     fn () => ignore (compile ["regression/138_sig.sml"])),
  Test
    ("139_sig",
     fn () => ignore (compile ["regression/139_sig.sml"])),
  Test
    ("140_sig",
     fn () => ignore (compile ["regression/140_sig.sml"])),
  Test
    ("141_provide",
     fn () => ignore (compile ["regression/141_provide.sml"])),
  Test
    ("142_bug",
     fn () => ignore (compile ["regression/142_bug.sml"])),
  Test
    ("143_functor",
     fn () => ignore (compile ["regression/143_functor.sml"])),
  Test
    ("144_functor",
     fn () => ignore (compile ["regression/144_functor.sml"])),
  Test
    ("145_sharing",
     fn () => ignore (compile ["regression/145_sharing.sml"])),
  Test
    ("146_sharing",
     fn () => ignore (compile ["regression/146_sharing.sml"])),
  Test
    ("147_functor",
     fn () => ignore (compile ["regression/147_functor.sml"])),
  Test
    ("148_sharing",
     fn () => ignore (compile ["regression/148_sharing.sml"])),
  Test
    ("149_functor",
     fn () => ignore (compile ["regression/149_functor.sml"])),
  Test
    ("150_functor",
     fn () => ignore (compile ["regression/150_functor.sml"])),
  Test
    ("151_functor",
     fn () => ignore (compile ["regression/151_functor.sml"])),
  Test
    ("152_sharing",
     fn () => ignore (compile ["regression/152_sharing.sml"])),
  Test
    ("153_poly",
     fn () => (compile ["regression/153_poly.sml"];
               fail "must cause a warning")
              handle CompileError
                       (_, [(_,_,T.ValueRestriction _),
                            (_,_,M.MatchError ("match nonexhaustive", [_]))])
                     => ()),
  Test
    ("154_staticanalysis",
     fn () => (compile ["regression/154_staticanalysis.sml"];
               fail "must cause a warning")
              handle CompileError
                       (_, [(_,_,M.MatchError ("match nonexhaustive", [_]))])
                     => ()),
  Test
    ("155_match",
     fn () => (compile ["regression/155_match.sml"];
               fail "must cause a warning")
              handle CompileError
                       (_, [(_,_,M.MatchError ("match nonexhaustive", [_]))])
                     => ()),
  Test
    ("156_sig",
     fn () => (compile ["regression/156_sig.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SigIdUndefined _),
                            (_,_,N.TypUndefinedInSigshare _)])
                     => ()),
  Test
    ("157_polyValBind",
     fn () => (compile ["regression/157_polyValBind.sml"];
               fail "must cause a warning")
              handle CompileError
                       (_, [(_,_,T.ValueRestriction _),
                            (_,_,M.MatchError ("match nonexhaustive",_))])
                     => ()),
  Test
    ("158_functor",
     fn () => (compile ["regression/158_functor.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideFunparamMismatch _)])
                     => ()),
  Test
    ("160_functor",
     fn () => (compile ["regression/160_functor.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideFunctorMismatch _)])
                     => ()),
  Test
    ("161_functorarg",
     fn () => ignore (compile ["regression/161_functorarg.sml"])),
  Test
    ("162_exn",
     fn () => ignore (compile ["regression/162_exn.sml"])),
  Test
    ("163_functor",
     fn () => ignore (compile ["regression/163_functor.sml"])),
  Test
    ("164_functor",
     fn () => ignore (compile ["regression/164_functor.sml"])),
  Test
    ("165_functor",
     fn () => ignore (compile ["regression/165_functor.sml"])),
  Test
    ("166_functor",
     fn () => ignore (compile ["regression/166_functor.sml"])),
  Test
    ("167_functor",
     fn () => ignore (compile ["regression/167_functor.sml"])),
  Test
    ("168_sharing",
     fn () => ignore (compile ["regression/168_sharing.sml"])),
  Test
    ("169_exnrep",
     fn () => ignore (compile ["regression/169_exnrep.sml"])),
  Test
    ("170_functorexn",
     fn () => ignore (compile ["regression/170_functorexn.sml"])),
  Test
    ("171_open",
     fn () => ignore (compile ["regression/171_open.sml"])),
  Test
    ("172_sharing",
     fn () => ignore (compile ["regression/172_sharing.sml"])),
  Test
    ("173_sharing",
     fn () => ignore (compile ["regression/173_sharing.sml"])),
  Test
    ("174_functorexn",
     fn () => ignore (compile ["regression/174_functorexn.sml"])),
  Test
    ("175_bigrecord",
     fn () => ignore (compile ["regression/175_bigrecord.sml"])),
  Test
    ("176_select",
     fn () => ignore (compile ["regression/176_select.sml"])),
  Test
    ("177_sig",
     fn () => ignore (compile ["regression/177_sig.sml"])),
  Test
    ("178_functorarg",
     fn () => ignore (compile ["regression/178_functorarg.sml"])),
  Test
    ("179_boundTvarName",
     (* ToDo: check the output of type printer *)
     fn () => ignore (interactiveFile "regression/179_boundTvarName.sml")),
  Test
    ("180_datatype",
     fn () => ignore (compile ["regression/180_datatype.sml"])),
  Test
    ("181_functor",
     fn () => ignore (compile ["regression/181_functor.sml"])),
  Test
    ("182_datatype",
     fn () => ignore (compile ["regression/182_datatype.sml"])),
  Test
    ("183_sharing",
     fn () => ignore (compile ["regression/183_sharing.sml"])),
  Test
    ("184_exn",
     fn () =>
        ignore
          (link "regression/184_exn.smi"
                (compile ["regression/184_exn.sml",
                          "regression/184_exn2.sml",
                          "regression/184_exn3.sml"]))),
  Test
    ("185_exnrep",
     fn () =>
        ignore
          (link "regression/185_exnrep.smi"
                (compile ["regression/185_exnrep.sml",
                          "regression/185_exnrep2.sml"]))),
  Test
    ("186_arraySubscript",
     fn () =>
        execute
          (link "regression/186_arraySubscript.smi"
                (compile ["regression/186_arraySubscript.sml"]))),
  Test
    ("187_segv",
     fn () =>
        case compile' ["regression/187_segv.sml"] of
          {errors = [(_,_,M.MatchError ("match nonexhaustive",_))],
           objfiles, ...} =>
          execute (link "" objfiles)
        | {errors, ...} => raiseCompileError errors),
  Test
    ("188_exn",
     fn () => ignore (compile ["regression/188_exn.sml"])),
  Test
    ("189_case",
     fn () => execute (link "" (compile ["regression/189_case.sml"]))),
  Test
    ("190_eqtypeRef",
     fn () => ignore (compile ["regression/190_eqtypeRef.sml"])),
  Test
    ("191_equal",
     fn () => execute (link "" (compile ["regression/191_equal.sml"]))),
  Test
    ("192_0w90",
     fn () => ignore (compile ["regression/192_0w90.sml"])),
  Test
    ("192_realTostring",
     fn () =>
        execute
          (link "regression/192_realTostring.smi"
                (compile ["regression/192_realTostring.sml"]))),
  Test
    ("193_dupname",
     fn () => (compile ["regression/193_dupname.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.DuplicateStrName _)])
                     => ()),
  Test
    ("193_primitiveArg",
     fn () => ignore (compile ["regression/193_primitiveArg.sml"])),
  Test
    ("194_opaqueSig",
     fn () => (compile ["regression/194_opaqueSig.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TyConListMismatch _)])
                     => ()),
  Test
    ("194_opaqueSig_good",
     fn () => ignore (compile ["regression/194_opaqueSig_good.sml"])),
  Test
    ("195_dummyType",
     fn () =>
        case interactiveFile' "regression/195_dummyType.sml" of
          {errors = [(_, _, T.ValueRestriction _)], ...} => ()
        | {errors, ...} => raiseCompileError errors),
  Test
    ("196_abstype",
     fn () => ignore (compile ["regression/196_abstype.sml"])),
  Test
    ("197_select",
     fn () => execute (link "" (compile ["regression/197_select.sml"]))),
  Test
    ("198_handle",
     fn () => execute (link "" (compile ["regression/198_handle.sml"]))),
  Test
    ("199_exn",
     fn () =>
        assertEqualStringList
          ["exception R3 of string\n\
           \exception E31 of int\n\
           \exception E32 = E31\n"]
          (#prints (interactiveFile "regression/199_exn.sml"))),
  Test
    ("200_record",
     fn () => (compile ["regression/200_record.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,E.DuplicateRecordLabel _),
                            (_,_,E.DuplicateRecordLabel _)])
                     => ()),
  Test
    ("202_bigrecord",
     fn () => ignore (compile ["regression/202_bigrecord.sml"])),
  Test
    ("203_anormalOptimize",
     fn () => evalFile "regression/203_anormalOptimize.sml"),
  Test
    ("204_functor",
     fn () => ignore (interactiveFile "regression/204_functor.sml")),
  Test
    ("205_exnExport",
     fn () => ignore (interactiveFile "regression/205_exnExport.sml")),
  Test
    ("206_eqtype",
     fn () => (compile ["regression/206_eqtype.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGEqtype _)])
                     => ()),
  Test
    ("207_printer",
     (* ToDo: test the error message *)
     fn () => (compile ["regression/207_printer.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.NonFunction _)])
                     => ()),
  Test
    ("208_constraint",
     fn () => ignore (compile ["regression/208_constraint.sml"])),
  Test
    ("209_functor",
     fn () => ignore (compile ["regression/209_functor.sml"])),
  Test
    ("210_functor",
     fn () => ignore (compile ["regression/210_functor.sml"])),
  Test
    ("211_printSignatureAnd",
     fn () =>
        assertEqualStringList
          ["signature S21 =\n\
           \  sig\n\
           \    type t\n\
           \    datatype dt = D\n\
           \    val x : t * dt\n\
           \  end\n\
           \signature S22 =\n\
           \  sig\n\
           \    type t\n\
           \    datatype dt = D\n\
           \    val x : t * dt\n\
           \  end\n"]
          (#prints (interactiveFile "regression/211_printSignatureAnd.sml"))),
  Test
    ("212_wheretype",
     (* test for SML# specific feature *)
     fn () => (compile ["regression/212_wheretype.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.TypeErrorInSigwhere _),
                            (_,_,N.TypeErrorInSigwhere _)])
                     => ()),
  Test
    ("213_printSDatatypeOpaque",
     fn () =>
        assertEqualStringList
          ["signature SDatatype =\n\
           \  sig\n\
           \    structure S : sig\n\
           \      datatype dt = D\n\
           \    end\n\
           \  end\n",
           "structure SDatatypeOpaque =\n\
           \  struct\n\
           \    structure S =\n\
           \      struct\n\
           \        datatype dt = <hidden>\n\
           \      end\n\
           \  end\n"]
          (#prints
             (interactiveFile "regression/213_printSDatatypeOpaque.sml"))),
  Test
    ("214_typeSpecMatching",
     fn () => (compile ["regression/214_typeSpecMatching.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_02",
     fn () => (compile ["regression/214_typeSpecMatching_02.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_03",
     fn () => (compile ["regression/214_typeSpecMatching_03.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_04",
     fn () => (compile ["regression/214_typeSpecMatching_04.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_05",
     fn () => (compile ["regression/214_typeSpecMatching_05.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_06",
     fn () => (compile ["regression/214_typeSpecMatching_06.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_07",
     fn () => (compile ["regression/214_typeSpecMatching_07.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_08",
     fn () => (compile ["regression/214_typeSpecMatching_08.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_09",
     fn () => (compile ["regression/214_typeSpecMatching_09.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_10",
     fn () => (compile ["regression/214_typeSpecMatching_10.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_11",
     fn () => (compile ["regression/214_typeSpecMatching_11.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("214_typeSpecMatching_12",
     fn () => (compile ["regression/214_typeSpecMatching_12.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGArity _)])
                     => ()),
  Test
    ("215_functor",
     fn () => ignore (compile ["regression/215_functor.sml"])),
  Test
    ("216_opaque",
     fn () => ignore (compile ["regression/216_opaque.sml"])),
  Test
    ("217_opaque",
     fn () =>
        assertEqualStringList
          ["signature S =\n\
           \  sig\n\
           \    structure T1 : sig\n\
           \      datatype dt = D\n\
           \    end\n\
           \  and T2 : sig\n\
           \      datatype dt = D\n\
           \    end\n\
           \  end\n",
           "structure S =\n\
           \  struct\n\
           \    structure T1 =\n\
           \      struct\n\
           \        datatype dt = D\n\
           \      end\n\
           \    structure T2 =\n\
           \      struct\n\
           \        datatype dt = D\n\
           \      end\n\
           \  end\n",
           "structure SOpaque =\n\
           \  struct\n\
           \    structure T1 =\n\
           \      struct\n\
           \        datatype dt = <hidden>\n\
           \      end\n\
           \    structure T2 =\n\
           \      struct\n\
           \        datatype dt = <hidden>\n\
           \      end\n\
           \  end\n"]
          (#prints (interactiveFile "regression/217_opaque.sml"))),
  Test
    ("218_printer",
     fn () =>
        assertEqualStringList
          ["signature S1 =\n\
           \  sig\n\
           \  end\n\
           \signature S2 =\n\
           \  sig\n\
           \  end\n"]
          (#prints (interactiveFile "regression/218_printer.sml"))),
  Test
    ("219_structure",
     fn () =>
        assertEqualStringList
          ["structure S1 =\n\
           \  struct\n\
           \    datatype dt = D\n\
           \    val x = D : dt\n\
           \  end\n"]
          (#prints (interactiveFile "regression/219_structure.sml"))),
  Test
    ("220_sharingType",
     fn () => (compile ["regression/220_sharingType.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.SIGDtyMismatch _)])
                     => ()),
  Test
    ("220_sharingType_good",
     fn () => ignore (compile ["regression/220_sharingType_good.sml"])),
  Test
    ("221_functorInstantiate",
     fn () => ignore (compile ["regression/221_functorInstantiate.sml"])),
  Test
    ("222_functorArgumentTyconName",
     fn () =>
        assertEqualStringList
          ["functor FFF\n\
           \  (sig\n\
           \    datatype foo = A of int\n\
           \  end) :\n\
           \    sig\n\
           \      datatype hoge = B of foo\n\
           \      val B : foo -> hoge\n\
           \    end\n\
           \structure P =\n\
           \  struct\n\
           \    datatype foo = A of int\n\
           \  end\n",
           "structure A =\n\
           \  struct\n\
           \    datatype hoge = B of P.foo\n\
           \  end\n",
           "val it = fn : P.foo -> A.hoge\n"]
          (#prints
             (interactiveFile "regression/222_functorArgumentTyconName.sml"))),
  Test
    ("223_wildPat",
     fn () => ignore (compile ["regression/223_wildPat.sml"])),
  Test
    ("224_eqTyvars",
     fn () => (compile ["regression/224_eqTyvars.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TyConListMismatch _)])
                     => ()),
  Test
    ("225_typeinfOrder",
     (* ToDo: check the error message *)
     fn () => (compile ["regression/225_typeinfOrder.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _)])
                     => ()),
  Test
    ("226_rank1Decompose",
     fn () => ignore (compile ["regression/226_rank1Decompose.sml"])),
  Test
    ("227_provideFunctorSharing",
     fn () => (compile ["regression/227_provideFunctorSharing.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.ProvideFunparamMismatch _)])
                     => ()),
  Test
    ("228_abstypeInFunctor",
     fn () => ignore (compile ["regression/228_abstypeInFunctor.sml"])),
  Test
    ("229_functorPrinter",
     fn () =>
        assertEqualStringList
          ["functor F\n\
           \  (sig\n\
           \    type foo\n\
           \  end) :\n\
           \    sig\n\
           \      type bar = foo\n\
           \      val f : foo -> foo\n\
           \    end\n",
           "structure A =\n\
           \  struct\n\
           \    type 'a foo = int\n\
           \    val f = fn : int -> int\n\
           \  end\n"]
          (#prints (interactiveFile "regression/229_functorPrinter.sml"))),
  Test
    ("230_signaturePrint",
     fn () =>
        assertEqualStringList
          ["signature A =\n\
           \  sig\n\
           \    type f\n\
           \    type g\n\
           \  end\n"]
          (#prints (interactiveFile "regression/230_signaturePrint.sml"))),
  Test
    ("231_recFunOrder",
     (* ToDo: cannot understand what this test case is for *)
     fn () => (compile ["regression/231_recFunOrder.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _),
                            (_,_,T.TyConListMismatch _)])
                     => ()),
  Test
    ("232_tlNil",
     fn () => (interactiveFile "regression/232_tlNil.sml";
               fail "must raise Empty")
              handle CompileError
                       (_, [(_,_,T.ValueRestriction _),
                            (_,_,UncaughtException (_,Empty))])
                     => ()),
  Test
    ("233_functorSigNewLine",
     fn () =>
        assertEqualStringList
          ["functor F\n\
           \  (sig\n\
           \    datatype foo = A | B\n\
           \    datatype ZZZ = C\n\
           \  end) :\n\
           \    sig\n\
           \      val x\n\
           \    end\n\
           \signature A =\n\
           \  sig\n\
           \    datatype foo = A | B\n\
           \    datatype ZZZ = C\n\
           \  end\n"]
          (#prints (interactiveFile "regression/233_functorSigNewLine.sml"))),
  Test
    ("234_recordPat",
     fn () => ignore (compile ["regression/234_recordPat.sml"])),
  Test
    ("235_functor",
     fn () => ignore (interactiveFile "regression/235_functor.sml")),
  Test
    ("236_link",
     fn () =>
        ignore
          (link "regression/236_link.smi"
                (compile ["regression/236_link.sml",
                          "regression/236_link2.sml"]))),
  Test
    ("237_sharing",
     fn () => ignore (compile ["regression/237_sharing.sml"])),
  Test
    ("238_sharing",
     fn () => ignore (compile ["regression/238_sharing.sml"])),
  Test
    ("239_functorExn",
     (* no description of what this test case is for *)
     fn () => ignore (compile ["regression/239_functorExn.sml"])),
  Test
    ("240_structureExn",
     (* no description of what this test case is for *)
     fn () => ignore (compile ["regression/240_structureExn.sml"])),
  Test
    ("241_structureExn",
     fn () => ignore (compile ["regression/241_structureExn.sml"])),
  Test
    ("242_functorExn",
     fn () => ignore (compile ["regression/242_functorExn.sml"])),
  Test
    ("243_functorAppInterface",
     (* no description of what this test case is for *)
     fn () => ignore (compile ["regression/243_functorAppInterface.sml"])),
  Test
    ("244_eqtypeArray",
     fn () => ignore (compile ["regression/244_eqtypeArray.sml"])),
  Test
    ("245_functorExn",
     fn () => ignore (compile ["regression/245_functorExn.sml",
                               "regression/245_functorExn2.sml",
                               "regression/245_functorExn3.sml"])),
  Test
    ("246_builtin",
     fn () => ignore (compile ["regression/246_builtin.sml",
                               "regression/246_builtin2.sml"])),
  Test
    ("247_builtin",
     fn () => ignore (compile ["regression/247_builtin.sml"])),
  Test
    ("248_recordUnboxing",
     fn () => ignore (compile ["regression/248_recordUnboxing.sml"])),
  Test
    ("249_pairBind",
     fn () => (compile ["regression/249_pairBind.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.PatternExpMismatch _)])
                     => ()),
  Test
    ("250_applyBug",
     fn () => (compile ["regression/250_applyBug.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.PatternExpMismatch _)])
                     => ()),
  Test
    ("251_sigPath",
     fn () =>
        assertEqualStringList
          ["signature S =\n\
           \  sig\n\
           \    type foo\n\
           \    val x1 : int\n\
           \    val x2 : int * int\n\
           \    val x3 : int * int * int * int\n\
           \    val x : foo -> A.foo\n\
           \    val y : foo -> A.bar\n\
           \    structure A :\n\
           \    sig\n\
           \      datatype bar = A\n\
           \      type foo\n\
           \    end\n\
           \  end\n"]
          (#prints (interactiveFile "regression/251_sigPath.sml"))),
  Test
    ("252_sigPath",
     fn () =>
        assertEqualStringList
          ["signature S1 =\n\
           \  sig\n\
           \    datatype bar = A\n\
           \    type foo\n\
           \  end\n\
           \signature S2 =\n\
           \  sig\n\
           \    type foo\n\
           \    val x1 : int\n\
           \    val x2 : int * int\n\
           \    val x3 : int * int * int * int\n\
           \    val x : foo -> A.foo\n\
           \    val y : foo -> A.bar\n\
           \    structure A :\n\
           \    sig\n\
           \      datatype bar = A\n\
           \      type foo\n\
           \    end\n\
           \  end\n"]
          (#prints (interactiveFile "regression/252_sigPath.sml"))),
  Test
    ("253_functorDatatypeRep",
     fn () => ignore (compile ["regression/253_functorDatatypeRep.sml"])),
  Test
    ("254_functorArg",
     fn () => ignore (compile ["regression/254_functorArg.sml"])),
  Test
    ("255_sigPoly",
     fn () => ignore (interactiveFile "regression/255_sigPoly.sml")),
  Test
    ("256_segmentation",
     fn () =>
        execute
          (link "regression/256_segmentation.smi"
                (compile ["regression/256_segmentation.sml",
                          "regression/256_segmentation2.sml"]))),
  Test
    ("257_recordPolyAnnotation",
     fn () => ignore (compile ["regression/257_recordPolyAnnotation.sml"])),
  Test
    ("258_tcoptimization",
     fn () => ignore (compile ["regression/258_tcoptimization.sml"])),
  Test
    ("259_typeinf",
     fn () => (compile ["regression/259_typeinf.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.NonFunction _)])
                     => ()),
  Test
    ("260_provide",
     fn () => (compile ["regression/260_provide.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.SignatureMismatch _)])
                     => ()),
(*
  Test
    ("260_turnIntoVector",
     fn () =>
        case compile' ["regression/260_turnIntoVector.sml"] of
          {errors = [(_,_,T.ValueRestriction _)], objfiles, ...} =>
          execute (link "" objfiles)
        | {errors, ...} => raiseCompileError errors),
*)
  Test
    ("261_typeinf",
     fn () =>
        let
          val orig = !Control.doUncurryOptimization
          val _ = compile ["regression/261_typeinf.sml"]
                  handle e => (Control.doUncurryOptimization := orig; raise e)
        in
          Control.doUncurryOptimization := orig
        end),
  Test
    ("262_extern",
     fn () => ignore (compile ["regression/262_extern.sml"])),
  Test
    ("263_uncurry",
     fn () =>
        execute
          (link "regression/263_uncurry0.smi"
                (compile ["regression/263_uncurry.sml",
                          "regression/263_uncurry0.sml"]))),
  Test
    ("264_invalidDbi",
     fn () => ignore (compile ["regression/264_invalidDbi.sml"])),
  Test
    ("265_functor",
     fn () => ignore (compile ["regression/265_functor.sml"])),
  Test
    ("266_SQLInsertOption",
     fn () => ignore (compile ["regression/266_SQLInsertOption.sml"])),
  Test
    ("267_realRecord",
     fn () =>
        execute
          (link "regression/267_realRecord.smi"
                (compile ["regression/267_realRecord.sml"]))),
  Test
    ("267_recordUnboxing",
     fn () => ignore (compile ["regression/267_recordUnboxing.sml"])),
  Test
    ("268_staticAnalysis",
     (* no description of what this test case is for *)
     fn () => ignore (compile ["regression/268_staticAnalysis.sml"])),
  Test
    ("269_staticAnalysis",
     (* no description of what this test case is for *)
     fn () => ignore (compile ["regression/269_staticAnalysis.sml"])),
  Test
    ("270_providecheck",
     fn () => (compile ["regression/270_providecheck.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.TypeAnnotationNotAgree _)])
                     => ()),
  Test
    ("271_opaqueSig",
     fn () => ignore (compile ["regression/271_opaqueSig.sml"])),
  Test
    ("272_sql",
     (* ToDo: this requires SQLServer *)
     fn () => execute (link "" (compile ["regression/272_sql.sml"]))
              handle _ => ()),
  Test
    ("273_realToDecimal",
     fn () =>
        execute
          (link "regression/273_realToDecimal.smi"
                (compile ["regression/273_realToDecimal.sml"]))),
  Test
    ("274_O2StringSub",
     (* ToDo: set -O2 flag *)
     fn () =>
        execute
          (link "regression/274_O2StringSub.sml"
                (compile ["regression/274_O2StringSub.sml"]))),
  Test
    ("275_arrayCopy",
     fn () =>
        execute
          (link "regression/275_arrayCopy.smi"
                (compile ["regression/275_arrayCopy.sml"]))),
  Test
    ("276_OS.FileSysInInteractiveMode",
     fn () =>
        ignore
          (interactiveFile "regression/276_OS.FileSysInInteractiveMode.sml")),
  Test
    ("277_termEq",
     fn () =>
        execute
          (link "regression/277_termEq.smi"
                (compile ["regression/277_termEq.sml"]))),
  Test
    ("278_listPairAppEq",
     fn () => ignore (compile ["regression/278_listPairAppEq.sml"])),
  Test
    ("279_arraySliceCopy",
     fn () => evalFile "regression/279_arraySliceCopy.sml"),
  Test
    ("281_arraySliceCopyEmpty",
     fn () => evalFile "regression/281_arraySliceCopyEmpty.sml"),
  Test
    ("282_polyEqList",
     fn () => evalFile "regression/282_polyEqList.sml"),
  Test
    ("283_stringEq",
     fn () => evalFile "regression/283_stringEq.sml"),
  Test
    ("285_realPath",
     fn () =>
        let
          val m = compile ["regression/285_realPath.sml"]
          val e = link "regression/285_realPath.smi" m
          val f = TempFile.create "README"
          val testlink = Filename.concatPath
                           (Filename.dirname f, Filename.fromString "testlink")
        in
          CoreUtils.chdir
            (Filename.dirname f)
            (fn _ => (OS.Process.system "ln -s README testlink"; execute e))
          handle e => (CoreUtils.rm_f testlink; raise e);
          CoreUtils.rm_f testlink;
          ()
        end),
  Test
    ("287_remove",
     fn () =>
        let
          val m = compile ["regression/287_remove.sml"]
          val e = link "regression/287_remove.smi" m
          val f = TempFile.create "temp"
          val testdir = Filename.concatPath
                          (Filename.dirname f, Filename.fromString "testdir")
        in
          CoreUtils.chdir (Filename.dirname f) (fn _ => execute e)
          handle e => (CoreUtils.rmdir_f testdir; raise e);
          CoreUtils.rmdir_f testdir;
          ()
        end),
  Test
    ("290_vectorSliceSub",
     fn () => (evalFile "regression/290_vectorSliceSub.sml";
               fail "must cause Subscript")
              handle CompileError
                       (_, [(_,_, UncaughtException (_, Subscript))])
                     => ()),
  Test
    ("291_div",
     fn () => evalFile "regression/291_div.sml"),
  Test
    ("292_arrayCopy",
     fn () => 
        execute
          (link "regression/292_arrayCopy.smi"
                (compile ["regression/292_arrayCopy.sml"]))),
  Test
    ("293_bigarray",
     fn () =>
        execute
          (link "regression/293_bigarray.smi"
                (compile ["regression/293_bigarray.sml"]))),
  Test
    ("294_ArraySliceFindi",
     fn () => evalFile "regression/294_ArraySliceFindi.sml"),
  Test
    ("295_CharVectorSlice",
     fn () => evalFile "regression/295_CharVectorSlice.sml"),
  Test
    ("296_VectorSlice",
     fn () => evalFile "regression/296_VectorSlice.sml"),
  Test
    ("299_RealNextAfter",
     fn () => evalFile "regression/299_RealNextAfter.sml"),
  Test
    ("301_MathPow",
     fn () => evalFile "regression/301_MathPow.sml"),
  Test
    ("302_DateFromTimeLocal",
     fn () => evalFile "regression/302_DateFromTimeLocal.sml"),
  Test
    ("303_Real32NotEqual",
     fn () => evalFile "regression/303_Real32NotEqual.sml"),
  Test
    ("305_Real32Min",
     fn () => evalFile "regression/305_Real32Min.sml"),
  Test
    ("306_Real32Max",
     fn () => evalFile "regression/306_Real32Max.sml"),
  Test
    ("307_Real32NextAfter",
     fn () => evalFile "regression/307_Real32NextAfter.sml"),
  Test
    ("308_Real32RealRound",
     fn () => evalFile "regression/308_Real32RealRound.sml"),
  Test
    ("309_Real32Round",
     fn () => evalFile "regression/309_Real32Round.sml"),
  Test
    ("310_Real32MathPow",
     fn () => evalFile "regression/310_Real32MathPow.sml"),
  Test
    ("311_DateFmt",
     fn () => evalFile "regression/311_DateFmt.sml"),
(* Date.fromStringは、仕様の問題
  Test
    ("312_DateFromString",
     fn () => evalFile "regression/312_DateFromString.sml"),
*)
  Test
    ("313_DateFromString",
     fn () => evalFile "regression/313_DateFromString.sml"),
  Test
    ("314_DateFromString",
     fn () => evalFile "regression/314_DateFromString.sml"),
  Test
    ("315_IntInfPatternMatch",
     fn () => evalFile "regression/315_IntInfPatternMatch.sml"),
(* Date.fromStringは、仕様の問題
  Test
    ("316_DateFromString",
     fn () => evalFile "regression/316_DateFromString.sml"),
*)
  Test
    ("317_functor",
     fn () => ignore (interactiveFile "regression/317_functor.sml")),
  Test
    ("318_ffiImport",
     fn () => ignore (compile ["regression/318_ffiImport.sml"])),
  Test
    ("319_ref",
     fn () => execute (link "" (compile ["regression/319_ref.sml"]))),
  Test
    ("322_datatype",
     fn () =>
        execute
          (link "regression/322_datatype.smi"
                (compile ["regression/322_datatype.sml",
                          "regression/322_datatype2.sml"]))),
  Test
    ("323_interactiveSignatures",
     fn () => evalFile "regression/323_interactiveSignatures.sml"),
  Test
    ("324_jsonKindSig",
     fn () => ignore (compile ["regression/324_jsonKindSig.sml"])),
  Test
    ("324_syntax",
     fn () => (compile ["regression/324_syntax.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,P.ParseError _)])
                     => ()),
(*
  (* this is a test for old JSON functions and therefore do not work *)
  Test
    ("326_jsonCase",
     fn () => evalFile "regression/326_jsonCase.sml"),
*)
  Test
    ("327_searchLpadBug",
     fn () => evalFile "regression/327_searchLpadBug.sml"
              handle CompileError
                       (_, [(_,_,UncaughtException (_, IEEEReal.Unordered))])
                     => ()),
  Test
    ("328_topsymbol",
     fn () => evalFile "regression/328_topsymbol.sml"),
  Test
    ("329_segv",
     (* ToDo: set SMLSHARP_HEAPSIZE to 1M and repeat several times *)
     fn () =>
        let
          val e = link "" (compile ["regression/329_segv.sml"])
          fun repeat f 0 = () | repeat f n = (f (); repeat f (n-1))
        in
          repeat (fn () => execute e) 10
        end),
(*
  (* these are tests for old JSON functions and therefore do not work *)
  Test
    ("333_jsonAs",
     fn () => ignore (interactiveFile "regression/333_jsonAs.sml")),
  Test
    ("333_jsonAs.sml compile",
     fn () =>
        execute
          (link "regression/333_jsonAs.sml"
                (compile ["regression/333_jsonAs.sml"]))),
  Test
    ("334_JSONView",
     fn () => evalFile "regression/334_JSONView.sml"),
  Test
    ("334_JSONView.sml compile",
     fn () =>
        execute
          (link "regression/334_JSONView.sml"
                (compile ["regression/334_JSONView.sml"]))),
  Test
    ("335_dynamic",
     (* ToDo: this uses old JSON functions and so does not work *)
     fn () => ignore (interactiveFile' "regression/335_dynamic.sml")),
*)
  Test
    ("337_overload",
     fn () => ignore (compile ["regression/337_overload.sml",
                               "regression/337_overload2.sml"])),
  Test
    ("157_polyValBind",
     fn () => (compile ["regression/338_dummytype.sml"];
               fail "must cause a warning")
              handle CompileError
                       (_, [(_,_,T.ValueRestriction _)]) => ()),
  Test
    ("339_rebindId",
     fn () => ignore (interactiveFile "regression/339_rebindId.sml")),
  Test
    ("341_phantom",
     fn () =>
        execute
          (link "regression/341_phantom.smi"
                (compile ["regression/341_phantom.sml",
                          "regression/341_phantom2.sml"]))),
  Test
    ("342_findConset",
     fn () => ignore (interactiveFile "regression/342_findConset.sml")),
  Test
    ("343_phantom",
     fn () =>
        execute
          (link "regression/343_phantom.smi"
                (compile ["regression/343_phantom.sml",
                          "regression/343_phantom2.sml"]))),
  Test
    ("344_functor",
     fn () => ignore (compile ["regression/344_functor.sml",
                               "regression/344_functor2.sml"])),
  Test
    ("345_exnrep",
     fn () => ignore
                (link "regression/345_exnrep.smi"
                      (compile ["regression/345_exnrep.sml",
                                "regression/345_exnrep2.sml"]))),
  Test
    ("347_reifyKind",
     fn () => (compile ["regression/347_reifyKind2.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,T.SignatureMismatch _)]) => ()),
  Test
    ("348_functor",
     fn () => ignore (compile ["regression/348_functor.sml"])),
  Test
    ("349_functor",
     fn () => ignore (compile ["regression/349_functor.sml"])),
  Test
    ("350_functor",
     fn () => ignore (compile ["regression/350_functor.sml"])),
  Test
    ("351_open",
     fn () =>
        assertEqualStringList
          ["structure A =\n\
           \  struct\n\
           \    type foo = int32\n\
           \    exception A\n\
           \    exception B\n\
           \    val x = 1 : foo\n\
           \    val y = 2 : foo\n\
           \  end\n",
           "type foo = int32\n\
           \exception A = A.A\n\
           \exception B = A.B\n\
           \val x = 1 : foo\n\
           \val y = 2 : foo\n"]
          (#prints (interactiveFile "regression/351_open.sml"))),
  Test
    ("352_SQLCloseConn",
     fn () =>
        (interactiveFile "regression/352_SQLCloseConn.sml";
         fail "must raise a SQL.Connect")
        handle CompileError
                 (_, [(_,_,UncaughtException (_, SQL.Connect _))]) => ()),
  Test
    ("353_join",
     fn () =>
        ignore (evalFile "regression/353_join.sml")),
  Test
    ("355_opaqueSig",
     fn () =>
        ignore (interactiveFile "regression/355_opaqueSig.sml")),
  Test
    ("356_eqkind",
     fn () => ignore (compile ["regression/356_eqkind.sml"])),
  Test
    ("359_dynamic",
     fn () =>
        ignore (evalFile "regression/359_dynamic.sml")),
  Test
    ("360_dynamic",
     fn () =>
        (evalFile "regression/360_dynamic.sml";
         fail "must raise RuntimeTypeError")
        handle CompileError
                 (_, [(_,_,UncaughtException (_, D.RuntimeTypeError))]) => ()),
  Test
    ("362_functor",
     fn () => ignore (compile ["regression/362_functor.sml"])),
  Test
    ("363_functor",
     fn () => (compile ["regression/363_functor.sml"];
               fail "must cause a compile error")
              handle CompileError
                       (_, [(_,_,N.LIFTEDPropNotAllowedInOpaqueInterface _),
                            (_,_,N.ProvideUndefinedTypeName _)]) => ()),
  Test
    ("364_signature",
     fn () =>
        (compile ["regression/364_signature.sml"];
         fail "must cause a compile error")
        handle CompileError
                 (_, [(_,_,T.SignatureMismatch _)]) => ()),
  Test
    ("365_nameeval",
     fn () =>
        (compile ["regression/365_nameeval.sml"];
         fail "must cause a compile error")
        handle CompileError
                 (_, [(_,_,N.DuplicateStrName _)]) => ()),
  Test
    ("367_interface",
     fn () =>
        (compile ["regression/367_interface.sml"];
         fail "must cause a compile error")
        handle CompileError (_, [(_,_,T.UserTvarNotGeneralized _)]) => ()),
  Test
    ("368_interface",
     fn () =>
        (compile ["regression/368_interface.sml"];
         fail "must cause a compile error")
        handle CompileError (_, [(_,_,T.UserTvarNotGeneralized _)]) => ()),
  Test
    ("369_duplicateInterface",
     fn () =>
        (compile ["regression/369_duplicateInterface.sml"];
         fail "must cause a compile error")
        handle CompileError
                 (_, [(_,_,N.DuplicateVar _),
                      (_,_,N.DuplicateStrName _)]) => ()),
  Test
    ("370_datatype",
     fn () =>
        (compile ["regression/370_datatype.sml"];
         fail "must cause a compile error")
        handle CompileError
                 (_, [(_,_,N.DuplicateTypName _)]) => ()),
  Test
    ("371_opaquetype",
     fn () => ignore (compile ["regression/371_opaquetype.sml"])),
  Test
    ("372_rank1_sig",
     fn () => ignore (compile ["regression/372_rank1_sig.sml"])),
  Test
    ("373_rank1_interface",
     fn () =>
        execute
          (link "regression/373_rank1_interface.smi"
                (compile ["regression/373_rank1_interface.sml",
                          "regression/373_rank1_interface2.sml"]))),
  Test
    ("374_rank1tests",
     fn () =>
        execute
          (link "regression/374_rank1tests.smi"
                (compile ["regression/374_rank1tests.sml",
                          "regression/374_rank1tests2.sml"]))),
  Test
    ("375_valrec",
     fn () => ignore (compile ["regression/375_valrec.sml"])),
  Test
    ("376_provide",
     fn () =>
        (compile ["regression/376_provide.sml"];
         fail "must cause a compile error")
        handle CompileError
                 (_, [(_,_,N.DuplicateVar _)]) => ()),
  Test
    ("377_ospath",
     fn () => ignore (interactiveFile "regression/377_ospath.sml")),
  Test
    ("378_join",
     fn () => ignore (compile ["regression/378_join.sml"])),

  TestList nil (* placeholder *)
]
end
