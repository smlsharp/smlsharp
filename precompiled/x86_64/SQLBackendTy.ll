@_SML_ftabe150882a66de11b7_SQLBackendTy=external global i8
@a=internal unnamed_addr global i1 false
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
define private void@_SML_tabbe150882a66de11b7_SQLBackendTy()#1{
unreachable
}
define void@_SML_loade150882a66de11b7_SQLBackendTy(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@a,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@a,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbe150882a66de11b7_SQLBackendTy,i8*@_SML_ftabe150882a66de11b7_SQLBackendTy,i8*null)#0
ret void
}
define void@_SML_maine150882a66de11b7_SQLBackendTy()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
