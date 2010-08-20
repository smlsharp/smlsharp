(**
 * binding information.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Binds.sml,v 1.3 2004/11/06 16:15:02 kiyoshiy Exp $
 *)
structure Binds =
struct

  (***************************************************************************)

  local
    structure EA = ElaboratedAst
  in
  datatype bind =
           SigBind of EA.sigb
         | FsigBind of EA.fsigb
         | StrBind of EA.strb
         | FctBind of EA.fctb
         | TypeBind of EA.tb
         | DataTypeBind of EA.db
         | ConstructorBind of EA.cb
         | ExceptionBind of EA.eb
         | ValBind of EA.vb

  fun getModuleFQN (SigBind(EA.SIGB(FQN, _, _, _, _, _))) = FQN
    | getModuleFQN (FsigBind(EA.FSIGB(FQN, _, _, _, _))) = FQN
    | getModuleFQN (StrBind(EA.STRB(FQN, _, _, _, _, _))) = FQN
    | getModuleFQN (FctBind(EA.FCTB(FQN, _, _, _, _))) = FQN
    | getModuleFQN (TypeBind(EA.TB(FQN, _, _, _, _, _, _))) = FQN
    | getModuleFQN (DataTypeBind(EA.DB(FQN, _, _, _, _, _))) = FQN
    | getModuleFQN (ConstructorBind(EA.CB(FQN, _, _, _, _, _))) = FQN
    | getModuleFQN (ExceptionBind(EA.EBGen(FQN, _, _, _, _))) = FQN
    | getModuleFQN (ExceptionBind(EA.EBDef(FQN, _, _, _, _))) = FQN
    | getModuleFQN (ValBind(EA.VB(FQN, _, _, _, _))) = FQN

  fun getName (SigBind(EA.SIGB(_, name, _, _, _, _))) = name
    | getName (FsigBind(EA.FSIGB(_, name, _, _, _))) = name
    | getName (StrBind(EA.STRB(_, name, _, _, _, _))) = name
    | getName (FctBind(EA.FCTB(_, name, _, _, _))) = name
    | getName (TypeBind(EA.TB(_, name, _, _, _, _, _))) = name
    | getName (DataTypeBind(EA.DB(_, name, _, _, _, _))) = name
    | getName (ConstructorBind(EA.CB(_, name, _, _, _, _))) = name
    | getName (ExceptionBind(EA.EBGen(_, name, _, _, _))) = name
    | getName (ExceptionBind(EA.EBDef(_, name, _, _, _))) = name
    | getName (ValBind(EA.VB(_, name, _, _, _))) = name

  fun getOptDC (SigBind(EA.SIGB(_, _, _, _, _, optDC))) = optDC
    | getOptDC (FsigBind(EA.FSIGB(_, _, _, _, optDC))) = optDC
    | getOptDC (StrBind(EA.STRB(_, _, _, _, _, optDC))) = optDC
    | getOptDC (FctBind(EA.FCTB(_, _, _, _, optDC))) = optDC
    | getOptDC (TypeBind(EA.TB(_, _, _, _, _, _, optDC))) = optDC
    | getOptDC (DataTypeBind(EA.DB(_, _, _, _, _, optDC))) = optDC
    | getOptDC (ConstructorBind(EA.CB(_, _, _, _, _, optDC))) = optDC
    | getOptDC (ExceptionBind(EA.EBGen(_, _, _, _, optDC))) = optDC
    | getOptDC (ExceptionBind(EA.EBDef(_, _, _, _, optDC))) = optDC
    | getOptDC (ValBind(EA.VB(_, _, _, _, optDC))) = optDC

  fun isSigBind (SigBind _) = true | isSigBind _ = false
  fun isFsigBind (FsigBind _) = true | isFsigBind _ = false
  fun isStrBind (StrBind _) = true | isStrBind _ = false
  fun isFctBind (FctBind _) = true | isFctBind _ = false
  fun isTypeBind (TypeBind _) = true | isTypeBind _ = false
  fun isDataTypeBind (DataTypeBind _) = true | isDataTypeBind _ = false
  fun isConstructorBind (ConstructorBind _) = true
    | isConstructorBind _ = false
  fun isExceptionBind (ExceptionBind _) = true | isExceptionBind _ = false
  fun isValBind (ValBind _) = true | isValBind _ = false

  end

  (***************************************************************************)

end