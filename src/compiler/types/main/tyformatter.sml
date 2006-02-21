(**
 * Copyright (c) 2006, Tohoku University.
 *
 * formatter of types.
 *
 * @author Atsushi Ohori 
 * @version $Id: tyformatter.sml,v 1.8 2006/02/18 04:59:37 ohori Exp $
 *)
structure TyFormatter =
struct

    structure FE = SMLFormat.FormatExpression;
    structure BF = SMLFormat.BasicFormatters;
	
   (**
    * a canonical name of a bound type variables
    *)
   fun tyIdName tid = 
       let
         fun numeral n = 
	     if n < 26
             then [ord #"a" + n]
	     else 
	       let val (msb, rest) = (n mod 26, (n div 26) - 1)
	       in (ord #"a" + msb)::(numeral  rest)
	       end
       in (implode(map chr (rev (numeral tid))))
       end

   (**
    * a canonical name of a free type variables
    *)
   fun freeTyIdName tid = 
       let
         fun numeral n = 
	     if n < 26
             then [ord #"A" + n]
	     else 
	       let val (msb, rest) = (n mod 26, (n div 26) - 1)
	       in (ord #"A" + msb) :: (numeral  rest)
	       end
       in (implode(map chr (rev (numeral tid))))
       end

   (**
    * a canonical name of a dummy type variables
    *)
   fun dummyTyIdName tid = "X" ^ Int.toString tid

   fun tyId2Doc (index, eqKind) = 
       let val prefix = case eqKind of EQ => "''" | NONEQ => "'"
       in (prefix ^ tyIdName index)
       end

   fun freeTyIdToDoc ({id, recKind, eqKind, ...} : Types.tvKind) = 
       let val prefix = case eqKind of EQ => "''" | NONEQ => "'"
       in (prefix ^ (freeTyIdName id))
       end

   fun format_freeTyId values =	BF.format_string(freeTyIdName values)

   fun formatBoundtvar (formatter, btvenvs) =
       let 
	 fun findInfo nil = raise Control.Bug "TyIdToDoc, find index"
	   | findInfo ((n, benv) :: rest) =
	     (case IEnv.find(benv,id) of
		SOME (tvKind as {index, eqKind, recKind, rank}) =>
                (n + index, tvKind)
	      | NONE => findInfo rest)
	 val (index, btvKind) = findInfo btvenvs 
	 val tidDoc = BF.format_string (index, #eqKind btvKind)
       in
	 case #recKind btvKind of UNIV => tidDoc | REC fl => tidDoc
(*
		      tidDoc @@
		      formatList(SEnv.listItemsi fl,tyfToDoc ES.TOP btvenvs,"#{",",","}")
*)
       end

   fun format_boundvar (_, nil) _ = raise Empty
      | format_boundvar (formatter, (n, benv) :: rest) id = 
	(case IEnv.find(benv, id) of
	   SOME(btvKind) => formatter((n, benv) :: rest) btvKind
	 | NONE => format_boundvar(formatter, rest) id)
		
   (* formatter of 'a IEnv.map *)
   fun format_bmap_int elementFormatter values =
       let val separator = List.concat[[SMLFormat.FormatExpression.Term(1, ",")]]
       in BF.format_list(elementFormatter, separator) (IEnv.listItems values)
       end

   fun createBtvKindMap nil vars = [(0, vars)]
     | createBtvKindMap ((n, benv) :: rest) vars =
       (n + IEnv.numItems benv, vars) :: (n, benv) :: rest

   local
     (* translate bound type variable into alphabet. *)
     fun format_tyId values =
	 let
	   fun tyIdName tid = 
	       let
		 fun numeral n = 
		     if n < 26
                     then [ord #"a" + n]
		     else 
		       let val (msb, rest) = (n mod 26, (n div 26) - 1)
		       in (ord #"a" + msb) :: (numeral  rest)
		       end
	       in
		 (implode(map chr (rev (numeral tid))))
	       end
	 in
	   BF.format_string(tyIdName values)
	 end
   in
   fun format_btvKind_index nil  index = format_tyId index
     | format_btvKind_index ((n, benv) :: t) index = format_tyId (n + index)
   end

end
