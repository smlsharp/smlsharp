@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN12RuntimeTypes10recordPropE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11DynamicKind13format__index_GE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11DynamicKind13format__index_GE_40 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind18format__dynamicKindE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11DynamicKind18format__dynamicKindE_41 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind11format__sizeE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11DynamicKind11format__sizeE_42 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11DynamicKind11format__sizeE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind10format__tagE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11DynamicKind10format__tagE_43 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11DynamicKind10format__tagE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SMLZN11DynamicKind13format__index_GE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind13format__recordE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11DynamicKind13format__recordE_44 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11DynamicKind13format__recordE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SMLZN11DynamicKind18format__dynamicKindE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg=private global<{[4x i8],i32,[2x i8*]}><{[4x i8]zeroinitializer,i32 -1342177264,[2x i8*]zeroinitializer}>,align 8
@f=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@f to i64))]
@_SML_ftab78dd31ed3d8f51c2_DynamicKind_ppg=external global i8
@g=private unnamed_addr global i8 0
@_SMLZN11DynamicKind7topKindE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i32 0,i32 2,i32 0)
@_SMLZN11DynamicKind11pointerKindE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i32 0,i32 2,i32 1)
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_save_exn(i8*inreg)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN10TermFormat14formatRecordTyE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN12RuntimeTypes15format__tag__propE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN12RuntimeTypes16format__size__propE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN15BasicFormatters11format__wordE(i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main6ad4d8e473c26a9c_BasicFormatters()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main60e750412e2bb4fe_RecordLabel()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main6f2b90f74b409277_TermFormat()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_mainc88dec21a8800496_RuntimeTypes_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*)local_unnamed_addr
declare void@_SML_load60e750412e2bb4fe_RecordLabel(i8*)local_unnamed_addr
declare void@_SML_load6f2b90f74b409277_TermFormat(i8*)local_unnamed_addr
declare void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb78dd31ed3d8f51c2_DynamicKind_ppg()#2{
unreachable
}
define void@_SML_load78dd31ed3d8f51c2_DynamicKind_ppg(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@g,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@g,align 1
tail call void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*%a)#0
tail call void@_SML_load60e750412e2bb4fe_RecordLabel(i8*%a)#0
tail call void@_SML_load6f2b90f74b409277_TermFormat(i8*%a)#0
tail call void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb78dd31ed3d8f51c2_DynamicKind_ppg,i8*@_SML_ftab78dd31ed3d8f51c2_DynamicKind_ppg,i8*bitcast([2x i64]*@f to i8*))#0
ret void
}
define void@_SML_main78dd31ed3d8f51c2_DynamicKind_ppg()local_unnamed_addr#1 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=load i8,i8*@g,align 1
%f=and i8%e,2
%g=icmp eq i8%f,0
br i1%g,label%i,label%h
h:
ret void
i:
store i8 3,i8*@g,align 1
tail call void@_SML_main6ad4d8e473c26a9c_BasicFormatters()#1
tail call void@_SML_main60e750412e2bb4fe_RecordLabel()#1
tail call void@_SML_main6f2b90f74b409277_TermFormat()#1
tail call void@_SML_mainc88dec21a8800496_RuntimeTypes_ppg()#1
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%j=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%j)#0
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%n,label%m
m:
invoke void@sml_check(i32 inreg%k)
to label%n unwind label%S
n:
%o=invoke fastcc i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg 0,i32 inreg 4)
to label%p unwind label%S
p:
store i8*%o,i8**%b,align 8
%q=call i8*@sml_alloc(i32 inreg 28)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177304,i32*%s,align 4
%t=load i8*,i8**%b,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=getelementptr inbounds i8,i8*%q,i64 24
%x=bitcast i8*%w to i32*
call void@llvm.memset.p0i8.i64(i8*%v,i8 0,i64 16,i1 false)
store i32 7,i32*%x,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i64 0,i32 2,i64 0),i8*inreg%q)#0
%y=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%z=getelementptr inbounds i8,i8*%y,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
store i8*%B,i8**%c,align 8
%C=getelementptr inbounds i8,i8*%y,i64 16
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%d,align 8
%F=call i8*@sml_alloc(i32 inreg 28)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177304,i32*%H,align 4
%I=load i8*,i8**%b,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=load i8*,i8**%c,align 8
%L=getelementptr inbounds i8,i8*%F,i64 8
%M=bitcast i8*%L to i8**
store i8*%K,i8**%M,align 8
%N=load i8*,i8**%d,align 8
%O=getelementptr inbounds i8,i8*%F,i64 16
%P=bitcast i8*%O to i8**
store i8*%N,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%F,i64 24
%R=bitcast i8*%Q to i32*
store i32 7,i32*%R,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar78dd31ed3d8f51c2_DynamicKind_ppg,i64 0,i32 2,i64 1),i8*inreg%F)#0
call void@sml_end()#0
ret void
S:
%T=landingpad{i8*,i8*}
cleanup
%U=extractvalue{i8*,i8*}%T,1
call void@sml_save_exn(i8*inreg%U)#0
call void@sml_end()#0
resume{i8*,i8*}%T
}
define fastcc i8*@_SMLFN11DynamicKind13format__index_GE(i32 inreg%a)#1 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i8*@_SMLFN15BasicFormatters11format__wordE(i32 inreg%a)
store i8*%i,i8**%b,align 8
%j=call i8*@sml_alloc(i32 inreg 20)#0
%k=getelementptr inbounds i8,i8*%j,i64 -4
%l=bitcast i8*%k to i32*
store i32 1342177296,i32*%l,align 4
%m=bitcast i8*%j to i8**
store i8*null,i8**%m,align 8
%n=load i8*,i8**%b,align 8
%o=getelementptr inbounds i8,i8*%j,i64 8
%p=bitcast i8*%o to i8**
store i8*%n,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%j,i64 16
%r=bitcast i8*%q to i32*
store i32 3,i32*%r,align 4
store i8*null,i8**%b,align 8
store i8*%n,i8**%c,align 8
%s=call i8*@sml_alloc(i32 inreg 20)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177296,i32*%u,align 4
store i8*%s,i8**%d,align 8
%v=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%y=getelementptr inbounds i8,i8*%s,i64 8
%z=bitcast i8*%y to i8**
store i8*%x,i8**%z,align 8
%A=getelementptr inbounds i8,i8*%s,i64 16
%B=bitcast i8*%A to i32*
store i32 3,i32*%B,align 4
%C=call i8*@sml_alloc(i32 inreg 20)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177296,i32*%E,align 4
store i8*%C,i8**%b,align 8
%F=getelementptr inbounds i8,i8*%C,i64 4
%G=bitcast i8*%F to i32*
store i32 0,i32*%G,align 1
%H=bitcast i8*%C to i32*
store i32 1,i32*%H,align 4
%I=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%J=getelementptr inbounds i8,i8*%C,i64 8
%K=bitcast i8*%J to i8**
store i8*%I,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%C,i64 16
%M=bitcast i8*%L to i32*
store i32 2,i32*%M,align 4
%N=call i8*@sml_alloc(i32 inreg 20)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177296,i32*%P,align 4
%Q=load i8*,i8**%b,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%N,i64 8
%T=bitcast i8*%S to i8**
store i8*null,i8**%T,align 8
%U=getelementptr inbounds i8,i8*%N,i64 16
%V=bitcast i8*%U to i32*
store i32 3,i32*%V,align 4
store i8*null,i8**%c,align 8
%W=call i8*@sml_alloc(i32 inreg 20)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177296,i32*%Y,align 4
%Z=load i8*,i8**%b,align 8
%aa=bitcast i8*%W to i8**
store i8*%Z,i8**%aa,align 8
%ab=load i8*,i8**%c,align 8
%ac=getelementptr inbounds i8,i8*%W,i64 8
%ad=bitcast i8*%ac to i8**
store i8*%ab,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%W,i64 16
%af=bitcast i8*%ae to i32*
store i32 3,i32*%af,align 4
ret i8*%W
}
define fastcc i8*@_SMLFN11DynamicKind18format__dynamicKindE(i8*inreg%a)#1 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%b,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%i,label%h
h:
call void@sml_check(i32 inreg%f)
br label%i
i:
%j=call fastcc i8*@_SMLFN10TermFormat14formatRecordTyE(i32 inreg 0,i32 inreg 4)
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=call fastcc i8*%m(i8*inreg%o,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
%v=bitcast i8**%b to i8***
%w=load i8**,i8***%v,align 8
%x=load i8*,i8**%w,align 8
%y=call fastcc i8*%s(i8*inreg%u,i8*inreg%x)
store i8*%y,i8**%c,align 8
%z=load i8*,i8**%b,align 8
%A=getelementptr inbounds i8,i8*%z,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
%D=call fastcc i8*@_SMLFN12RuntimeTypes16format__size__propE(i8*inreg%C)
store i8*%D,i8**%d,align 8
%E=call i8*@sml_alloc(i32 inreg 20)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32 1342177296,i32*%G,align 4
store i8*%E,i8**%e,align 8
%H=getelementptr inbounds i8,i8*%E,i64 4
%I=bitcast i8*%H to i32*
store i32 0,i32*%I,align 1
%J=bitcast i8*%E to i32*
store i32 4,i32*%J,align 4
%K=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%L=getelementptr inbounds i8,i8*%E,i64 8
%M=bitcast i8*%L to i8**
store i8*%K,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%E,i64 16
%O=bitcast i8*%N to i32*
store i32 2,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 20)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177296,i32*%R,align 4
store i8*%P,i8**%d,align 8
%S=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%V=getelementptr inbounds i8,i8*%P,i64 8
%W=bitcast i8*%V to i8**
store i8*%U,i8**%W,align 8
%X=getelementptr inbounds i8,i8*%P,i64 16
%Y=bitcast i8*%X to i32*
store i32 3,i32*%Y,align 4
%Z=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
%ad=call fastcc i8*@_SMLFN12RuntimeTypes15format__tag__propE(i8*inreg%ac)
store i8*%ad,i8**%b,align 8
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
store i8*%ae,i8**%c,align 8
%ah=getelementptr inbounds i8,i8*%ae,i64 4
%ai=bitcast i8*%ah to i32*
store i32 0,i32*%ai,align 1
%aj=bitcast i8*%ae to i32*
store i32 4,i32*%aj,align 4
%ak=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%al=getelementptr inbounds i8,i8*%ae,i64 8
%am=bitcast i8*%al to i8**
store i8*%ak,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%ae,i64 16
%ao=bitcast i8*%an to i32*
store i32 2,i32*%ao,align 4
%ap=call i8*@sml_alloc(i32 inreg 20)#0
%aq=getelementptr inbounds i8,i8*%ap,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 1342177296,i32*%ar,align 4
%as=load i8*,i8**%c,align 8
%at=bitcast i8*%ap to i8**
store i8*%as,i8**%at,align 8
%au=load i8*,i8**%d,align 8
%av=getelementptr inbounds i8,i8*%ap,i64 8
%aw=bitcast i8*%av to i8**
store i8*%au,i8**%aw,align 8
%ax=getelementptr inbounds i8,i8*%ap,i64 16
%ay=bitcast i8*%ax to i32*
store i32 3,i32*%ay,align 4
ret i8*%ap
}
define fastcc i8*@_SMLFN11DynamicKind11format__sizeE(i8*inreg%a)#1 gc"smlsharp"{
i:
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%g,label%e
e:
call void@sml_check(i32 inreg%c)
%f=load i8*,i8**%b,align 8
br label%g
g:
%h=phi i8*[%f,%e],[%a,%i]
%j=tail call fastcc i8*@_SMLFN12RuntimeTypes16format__size__propE(i8*inreg%h)
ret i8*%j
}
define fastcc i8*@_SMLFN11DynamicKind10format__tagE(i8*inreg%a)#1 gc"smlsharp"{
i:
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%g,label%e
e:
call void@sml_check(i32 inreg%c)
%f=load i8*,i8**%b,align 8
br label%g
g:
%h=phi i8*[%f,%e],[%a,%i]
%j=tail call fastcc i8*@_SMLFN12RuntimeTypes15format__tag__propE(i8*inreg%h)
ret i8*%j
}
define fastcc i8*@_SMLFN11DynamicKind13format__recordE(i8*inreg%a)#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call fastcc i8*@_SMLFN10TermFormat14formatRecordTyE(i32 inreg 0,i32 inreg 4)
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
%m=call fastcc i8*%j(i8*inreg%l,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%n=getelementptr inbounds i8,i8*%m,i64 16
%o=bitcast i8*%n to i8*(i8*,i8*)**
%p=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%o,align 8
%q=bitcast i8*%m to i8**
%r=load i8*,i8**%q,align 8
%s=load i8*,i8**%b,align 8
%t=tail call fastcc i8*%p(i8*inreg%r,i8*inreg%s)
ret i8*%t
}
define internal fastcc i8*@_SMLLN11DynamicKind13format__index_GE_40(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLFN11DynamicKind13format__index_GE(i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLN11DynamicKind18format__dynamicKindE_41(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind18format__dynamicKindE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN11DynamicKind11format__sizeE_42(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind11format__sizeE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN11DynamicKind10format__tagE_43(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind10format__tagE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN11DynamicKind13format__recordE_44(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind13format__recordE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i64(i8*,i8,i64,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
