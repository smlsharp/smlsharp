1i\
(* this is auto-generated file. do not edit. *)
/^structure BuiltinPrimitive =/s/BuiltinPrimitive/BuiltinPrimitiveInfo/
/^struct/p
/^end/p

/^  datatype [A-Za-z]* =/,/^ *$/{
  s/datatype \([A-Za-z]*\) =/fun \1_info x = case x of/
  s/^\([| ]*\)\([A-Z]\)/\1BuiltinPrimitive.\2/

  s/\([A-Z].*\)(\* => \(.*\) \*)/\1 => \2/
  s/\([A-Z].*\)(\* \(.*\) \*)/\1 => {ty="\2",exn='',effect=false}/

  s/ *+ effect *",exn='',effect=false}/",exn='',effect=true}/

  s! */ \([^"]*\)",exn='',!",exn='\1',!
  :e
  /exn='[^"']*[A-Z][A-Za-z_]*[, ]*["']/{
    s/\(exn='[^"']*\)\([A-Z][A-Za-z_]*\)\([, ]*["']\)/\1"\2"\3/
    be
  }

  s/exn='\(.*\)'/exn=[\1]/
  s/ *=> */ => /

  s/of string/x/
  s/of builtin/x/

  /of ov_/{
    h
    s/of ov_/BuiltinPrimitive.OverflowCheck/
    p
    g
    s/of ov_/BuiltinPrimitive.NoOverflowCheck/
    s/[, ]*"Overflow"//
  }

  p
}
