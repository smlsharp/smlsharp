(**
 * @copyright (c) 2007, Tohoku University.
 * @author Isao Sasano
 * @version $Id: InlineEnv.sml,v 1.9 2008/08/05 14:43:59 bochao Exp $
 *)

structure InlineEnv =
struct
local
structure MV = MultipleValueCalc
structure AT = AnnotatedTypes
in

(* string is only used for debugging. *)
datatype inlineInfo = FN of MV.mvexp * string
		    | PFN of MV.btvEnv * MV.mvexp * int * string 
		    (* int is for the size of this pfn.
		     * This size information is used when expanding type application.
		     *)
		    | SIMPLE of MV.mvexp
  		      (* 
		       * for constant, variable, exception,
		       * and cast of them 
		       *)

datatype globalInlineInfo = GFN of MV.mvexp * string (* for MVFNM in global env. *)
			  | GPFN of AT.btvEnv * MV.mvexp * int * string 
			  (* int is for the size of this gpfn
			   * This size information is used when expanding type application.
			   *)
			  | GSIMPLE of MV.mvexp * string

datatype globalInlineEnv = GIE of globalInlineInfo ExVarID.Map.map
val initialInlineEnv = GIE ExVarID.Map.empty

fun printInlineInfo inlineInfo =
    case inlineInfo of
	FN (mvexp, name)
	=> 
	print 
	    (
	     "FN: " ^
	     MultipleValueCalcFormatter.mvexpToString mvexp
	     ^ "\n"
	    )
      | PFN (btvEnv, mvexp, size, name)
	=>
	print 
	    (
	     "PFN: " ^
	     Control.prettyPrint (MultipleValueCalc.format_btvEnv btvEnv) ^
	     MultipleValueCalcFormatter.mvexpToString mvexp ^
	     "\n"
	    )
      | SIMPLE mvexp
	=>
	print 
	    (
	     "SIMPLE: " ^
	     MultipleValueCalcFormatter.mvexpToString mvexp
	     ^ "\n"
	    )

fun printGlobalInlineInfo globalInlineInfo =
    case globalInlineInfo of
	GFN (mvexp,name)
	=> 
	(print (name ^ " GFN ")
(*
 ;
	 print (MultipleValueCalcFormatter.mvexpToString mvexp)
*)
)
      | GPFN (btvEnv,mvexp,size,name) 
	=> 
	(print (name ^ " GPFN ") 
(*
;
	 print (MultipleValueCalcFormatter.mvexpToString mvexp)
*)
)
      | GSIMPLE (mvexp,name) 
	=> 
	(print (name ^ " GSIMPLE ")
(*
;
	 print (MultipleValueCalcFormatter.mvexpToString mvexp)
*)
)

fun printGlobalInlineEnv (GIE aimap) =
    ExVarID.Map.appi (fn (key,globalInlineInfo) => 
		    (print (Control.prettyPrint (ExVarID.format_id key));
		     print " ";
		     printGlobalInlineInfo globalInlineInfo;
		     print "\n")
		)
		aimap
    
end
end
