(**
 * Copyright (c) 2006, Tohoku University.
 *
 * type constants (needs re-writing).
 * 
 * @author Atsushi Ohori 
 * @version $Id: staticenv.sml,v 1.61 2006/02/18 04:59:37 ohori Exp $
 *)
structure StaticEnv = struct
local
    open Types
in

  (***************************************************************************)

    datatype fixity = INFIX of int | INFIXR of int | NONFIX

  (***************************************************************************)

    val emptyVarEnv = SEnv.empty : varEnv
    val emptyTyfield = SEnv.empty : ty SEnv.map
    val emptyTyConEnv = SEnv.empty : tyConEnv 
    val emptyStrEnv = SEnv.empty :strEnv
    val emptySigEnv = SEnv.empty :sigEnv
    val emptyE = (SEnv.empty,SEnv.empty,SEnv.empty) :Env

    val emptySubst = IEnv.empty : subst

    (****************************************)
    val boolTyConid = ID.reserve ()
    val intTyConid = ID.reserve ()
    val wordTyConid = ID.reserve ()
    val charTyConid = ID.reserve ()
    val stringTyConid = ID.reserve ()
    val realTyConid = ID.reserve ()
    val exnTyConid = ID.reserve ()
    val refTyConid = ID.reserve ()
    val listTyConid = ID.reserve ()
    val arrayTyConid = ID.reserve ()
    val largeIntTyConid = ID.reserve ()
    val largeWordTyConid = ID.reserve ()
    val byteTyConid = ID.reserve ()
    val byteArrayTyConid = ID.reserve ()
    val optionTyConid = ID.reserve ()

    val boolTyCon = {name = "bool", strpath=Path.topStrPath, abstract = false,
		     tyvars = [], id=boolTyConid, 
		     eqKind=ref EQ, boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val intTyCon = {name = "int", strpath=Path.topStrPath, abstract =false,
		    tyvars = [], id=intTyConid, 
		    eqKind=ref EQ, boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val wordTyCon = {name = "word", strpath=Path.topStrPath, abstract =false,
		     tyvars = [], id=wordTyConid, 
		     eqKind=ref EQ, boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val charTyCon = {name = "char", strpath=Path.topStrPath, abstract =false,
		     tyvars = [], id=charTyConid, 
		     eqKind=ref EQ, boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val stringTyCon = {name = "string", strpath=Path.topStrPath, abstract =false,
		       tyvars = [], id=stringTyConid, 
		       eqKind=ref EQ, boxedKind = ref (SOME BOXEDty), datacon=ref emptyVarEnv}:tyCon
    val realTyCon = {name = "real", strpath=Path.topStrPath, abstract =false,
		     tyvars = [], id=realTyConid, 
		     eqKind=ref NONEQ, boxedKind = ref (SOME DOUBLEty), datacon=ref emptyVarEnv}:tyCon
    val exnTyCon = {name = "exn",strpath=Path.topStrPath, abstract =false,
		    tyvars = [], id=exnTyConid, 
		    eqKind=ref NONEQ, boxedKind = ref (SOME BOXEDty), datacon=ref emptyVarEnv}:tyCon
    val refTyCon = {name = "ref", strpath=Path.topStrPath, abstract =false,
		    tyvars = [false], id=refTyConid, 
		    eqKind=ref EQ, boxedKind = ref (SOME BOXEDty), 
		    datacon=ref emptyVarEnv}:tyCon
    val listTyCon = {name = "list", strpath=Path.topStrPath, abstract =false,
		     tyvars = [false], id=listTyConid,
                     eqKind = ref EQ, boxedKind = ref (SOME BOXEDty), 
		     datacon=ref emptyVarEnv}:tyCon
    val arrayTyCon = {name = "array", strpath=Path.topStrPath, abstract =false,
		      tyvars = [false], id=arrayTyConid, 
		      eqKind=ref EQ, boxedKind = ref (SOME BOXEDty), 
		      datacon=ref emptyVarEnv}:tyCon
    val largeIntTyCon = {name = "largeInt", strpath=Path.topStrPath, abstract =false,
			 tyvars = [], id=largeIntTyConid, eqKind=ref EQ, 
			 boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val largeWordTyCon = {name = "largeWord", strpath=Path.topStrPath, abstract = false,
			  tyvars = [], id=largeWordTyConid, eqKind=ref EQ, 
			  boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val byteTyCon = {name = "byte", strpath=Path.topStrPath, abstract = false,
                     tyvars = [], id=byteTyConid, eqKind=ref EQ, 
			  boxedKind = ref (SOME ATOMty), datacon=ref emptyVarEnv}:tyCon
    val byteArrayTyCon = {name = "byteArray", strpath=Path.topStrPath, abstract =false,
                          tyvars = [], id=byteArrayTyConid, 
                          eqKind=ref EQ, boxedKind = ref (SOME BOXEDty), 
                          datacon=ref emptyVarEnv}:tyCon
    val optionTyCon = {name = "option", strpath=Path.topStrPath, abstract =false,
		     tyvars = [false], id=optionTyConid,
                     eqKind = ref EQ, boxedKind = ref (SOME BOXEDty), 
		     datacon=ref emptyVarEnv}:tyCon

    val systemTyCon = 
        [
          boolTyCon, 
          intTyCon, 
          wordTyCon, 
          charTyCon,
          stringTyCon,
          realTyCon,
          exnTyCon, 
          refTyCon,
          listTyCon,
	  arrayTyCon,
          largeIntTyCon,
          largeWordTyCon,
          byteTyCon,
	  byteArrayTyCon,
          optionTyCon
        ]

    (** true if two tyCons are the same. *)
    fun isSameTyCon (left : tyCon, right : tyCon) =
        (#name left = #name right) andalso (#id left = #id right)

    (****************************************)

    val boolty = CONty{tyCon = boolTyCon, args = nil}
    val intty = CONty{tyCon = intTyCon, args = nil}
    val wordty = CONty{tyCon = wordTyCon, args = nil}
    val charty = CONty{tyCon = charTyCon, args = nil}
    val stringty = CONty{tyCon = stringTyCon, args = nil}
    val realty = CONty{tyCon = realTyCon, args = nil}
    val exnty = CONty{tyCon = exnTyCon, args = nil}
    val tagty = intty (* constructor tag is integer *)

    val largeIntty = CONty{tyCon = largeIntTyCon, args = nil}
    val largeWordty = CONty{tyCon = largeWordTyCon, args = nil}
    val bytety = CONty{tyCon = byteTyCon, args = nil}
    val byteArrayty = CONty{tyCon = byteArrayTyCon, args = nil}

    val unitty = RECORDty SEnv.empty

    (****************************************)

    infixr 6 || 
    fun op ||((x, y), z) = SEnv.insert(z, x, y);

    val initialTyConEnv =
	("int", TYCON intTyCon)
      || ("word", TYCON wordTyCon) 
      || ("char", TYCON charTyCon) 
      || ("string", TYCON stringTyCon) 
      || ("bool", TYCON boolTyCon) 
      || ("real", TYCON realTyCon) 
      || ("exn", TYCON exnTyCon) 
      || ("ref", TYCON refTyCon)
      || ("unit", TYFUN {name = "unit", tyargs = IEnv.empty, body = unitty})
      || ("list", TYCON listTyCon)
      || ("array", TYCON arrayTyCon)
      || ("largeInt", TYCON largeIntTyCon)
      || ("largeWord", TYCON largeWordTyCon)
      || ("byte", TYCON byteTyCon)
      || ("byteArray", TYCON byteArrayTyCon)
      || ("option", TYCON optionTyCon)
      || SEnv.empty

    (*
     * see
     *  "Appendix C: The Initial Static Basis" and "Appendix E: Overloading"
     *)
    val initialFixEnv =
        foldr
            (fn ((x, fix), fEnv) =>SEnv.insert(fEnv, x, fix))
            SEnv.empty
            [
              ("div", INFIX 7),
              ("mod", INFIX 7),
              ("*", INFIX 7),
              ("/", INFIX 7),
              ("+", INFIX 6),
              ("-", INFIX 6),
              ("::", INFIXR 5),
              ("=", INFIX 4),
              ("<", INFIX 4),
              (">", INFIX 4),
              ("<=", INFIX 4),
              (">=", INFIX 4),
              (":=", INFIX 3)
            ]

    (****************************************)

    fun nextTyConId () = ID.peek ()
    fun newTyConId () = ID.generate ()

    fun nextVarId () = ID.peek ()
    fun newVarId () = ID.generate ()

    val dummyStructureId = ID.reserve ()
    fun nextStructureId () = ID.peek ()
    fun newStructureId () = ID.generate ()

    (* NOTE: exception tag is not global ID. 
     *)
    val maxSystemExnTag = 10
    val exnConIdSequenceRef =
        ref(SequentialNumber.generateSequence maxSystemExnTag)
    fun nextExnTag () = SequentialNumber.peek (!exnConIdSequenceRef)
    fun newExnTag() = SequentialNumber.generate (!exnConIdSequenceRef)

    (****************************************)

    fun init () =
        (
          ID.init ();
          SequentialNumber.init (!exnConIdSequenceRef)
        )

  (***************************************************************************)
 
end
end
