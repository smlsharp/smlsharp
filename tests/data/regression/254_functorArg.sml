(* 2013-4-7 ohori:
This causes unexpected name error:

ccc.smi:32.11-32.44 Error:
  (name evaluation CP-260) Provide check fails (type definition):
  mkCore.IntGrammar.SymbolAssoc.key

*)

(* ohori 2013-08-07 
  再現しない．おそらくこれ以降の変更で修正されたとおもわれる．
  とりあえずfixedに移す．
*)


signature TABLE =
   sig
    type key
   end
signature GRAMMAR =
    sig
     datatype symbol = TERM of int | NONTERM of int
   end
signature INTGRAMMAR =
    sig
      structure Grammar  : GRAMMAR
      structure SymbolAssoc : TABLE
      sharing type SymbolAssoc.key = Grammar.symbol
    end

functor mkCore(structure IntGrammar : INTGRAMMAR)
 : 
    sig
	structure Grammar : GRAMMAR
	structure IntGrammar : INTGRAMMAR
	sharing Grammar = IntGrammar.Grammar
    end
 =
  struct
    structure IntGrammar = IntGrammar
    structure Grammar = IntGrammar.Grammar
  end
