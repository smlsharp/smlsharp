structure AbsynPickler
  : sig
      val globalSymbolKind : Absyn.globalSymbolKind Pickle.pu
      val ffiAttributes : Absyn.ffiAttributes Pickle.pu
    end =
struct

  val globalSymbolKind =
      Pickle.enum
          (fn Absyn.ForeignCodeSymbol => 0,
           [ Absyn.ForeignCodeSymbol ])

  val callingConvention =
      Pickle.enum
          (
            fn Absyn.FFI_CDECL => 0
             | Absyn.FFI_STDCALL => 1,
            [Absyn.FFI_CDECL,
             Absyn.FFI_STDCALL]
          )

  val ffiAttributes =
      Pickle.conv
          (fn (isPure, noCallback, allocMLValue, callingConvention) =>
              {isPure = isPure,
               noCallback = noCallback,
               allocMLValue = allocMLValue,
               callingConvention = callingConvention},
           fn {isPure, noCallback, allocMLValue, callingConvention} =>
              (isPure, noCallback, allocMLValue, callingConvention))
          (Pickle.tuple4 (Pickle.bool,
                          Pickle.bool,
                          Pickle.bool,
                          Pickle.option callingConvention))

end