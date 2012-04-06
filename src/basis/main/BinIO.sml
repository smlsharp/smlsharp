(**
 * BinIO structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
(* 2012-01-21 ohori
  I have inlined one-shot functor.
Old:
BinIO 
  <== SMLSharpSMLNJ_BinIO (in ./smlnj/Basis/Unix/posix-bin-io.sml)
       <== SMLSharpSMLNJ_BinIOFn (in ./smlnj/Basis/IO/bin-io-fn.sml)
           SMLSharpSMLNJ_PosixBinPrimIO (in ./smlnj/Basis/Unix/posix-bin-prim-io.sml)
where SMLSharpSMLNJ_BinIOFn is used only onece.
New:
  <== SMLSharpSMLNJ_BinIOFn (in ./smlnj/Basis/IO/bin-io.sml)
      <== SMLSharpSMLNJ_PosixBinPrimIO (in ./smlnj/Basis/Unix/posix-bin-prim-io.sml)
*)
_interface "BinIO.smi"
structure BinIO = SMLSharpSMLNJ_BinIO :> BIN_IO
