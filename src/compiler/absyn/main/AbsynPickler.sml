structure AbsynPickler
  : sig
      val callingConvention : Absyn.callingConvention Pickle.pu
    end =
struct

  val callingConvention =
      Pickle.enum
          (
            fn Absyn.CC_CDECL => 0
             | Absyn.CC_STDCALL => 1
             | Absyn.CC_DEFAULT => 2,
            [Absyn.CC_CDECL, Absyn.CC_STDCALL, Absyn.CC_DEFAULT]
          )

end