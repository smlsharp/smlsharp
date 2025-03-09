@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN12RuntimeTypes10recordPropE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind10format__tagE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicKind10format__tagE_40 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind11format__sizeE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicKind11format__sizeE_41 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11DynamicKind13format__index_GE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicKind13format__index_GE_42 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind13format__recordE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicKind13format__recordE_43 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicKind18format__dynamicKindE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicKind18format__dynamicKindE_44 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11DynamicKind11format__sizeE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN11DynamicKind10format__tagE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SMLZN11DynamicKind13format__index_GE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN11DynamicKind13format__recordE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SMLZN11DynamicKind18format__dynamicKindE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg=private global<{[4x i8],i32,[2x i8*]}><{[4x i8]zeroinitializer,i32 -1342177264,[2x i8*]zeroinitializer}>,align 8
@f=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@f to i64))]
@_SML_ftab0fe904135d8a1a04_DynamicKind_ppg=external global i8
@g=private unnamed_addr global i8 0
@_SMLZN11DynamicKind7topKindE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i32 0,i32 2,i32 0)
@_SMLZN11DynamicKind11pointerKindE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i32 0,i32 2,i32 1)
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
declare void@_SML_maina142c315f12317c0_RecordLabel()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main3a6a3f6785231de5_TermFormat()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_mainc88dec21a8800496_RuntimeTypes_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*)local_unnamed_addr
declare void@_SML_loada142c315f12317c0_RecordLabel(i8*)local_unnamed_addr
declare void@_SML_load3a6a3f6785231de5_TermFormat(i8*)local_unnamed_addr
declare void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb0fe904135d8a1a04_DynamicKind_ppg()#2{
unreachable
}
define void@_SML_load0fe904135d8a1a04_DynamicKind_ppg(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@g,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@g,align 1
tail call void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*%a)#0
tail call void@_SML_loada142c315f12317c0_RecordLabel(i8*%a)#0
tail call void@_SML_load3a6a3f6785231de5_TermFormat(i8*%a)#0
tail call void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb0fe904135d8a1a04_DynamicKind_ppg,i8*@_SML_ftab0fe904135d8a1a04_DynamicKind_ppg,i8*bitcast([2x i64]*@f to i8*))#0
ret void
}
define void@_SML_main0fe904135d8a1a04_DynamicKind_ppg()local_unnamed_addr#1 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=load i8,i8*@g,align 1
%g=and i8%f,2
%h=icmp eq i8%g,0
br i1%h,label%j,label%i
i:
ret void
j:
store i8 3,i8*@g,align 1
tail call void@_SML_main6ad4d8e473c26a9c_BasicFormatters()#1
tail call void@_SML_maina142c315f12317c0_RecordLabel()#1
tail call void@_SML_main3a6a3f6785231de5_TermFormat()#1
tail call void@_SML_mainc88dec21a8800496_RuntimeTypes_ppg()#1
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%k=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%k)#0
%l=load atomic i32,i32*@sml_check_flag unordered,align 4
%m=icmp eq i32%l,0
br i1%m,label%o,label%n
n:
invoke void@sml_check(i32 inreg%l)
to label%o unwind label%U
o:
%p=invoke fastcc i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg 0,i32 inreg 4)
to label%q unwind label%U
q:
store i8*%p,i8**%b,align 8
%r=call i8*@sml_alloc(i32 inreg 28)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177304,i32*%t,align 4
store i8*%r,i8**%c,align 8
%u=load i8*,i8**%b,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=getelementptr inbounds i8,i8*%r,i64 24
%y=bitcast i8*%x to i32*
call void@llvm.memset.p0i8.i64(i8*%w,i8 0,i64 16,i1 false)
store i32 7,i32*%y,align 4
%z=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%A=getelementptr inbounds i8,i8*%z,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%d,align 8
%D=getelementptr inbounds i8,i8*%z,i64 16
%E=bitcast i8*%D to i8**
%F=load i8*,i8**%E,align 8
store i8*%F,i8**%e,align 8
%G=call i8*@sml_alloc(i32 inreg 28)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177304,i32*%I,align 4
%J=load i8*,i8**%b,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=load i8*,i8**%d,align 8
%M=getelementptr inbounds i8,i8*%G,i64 8
%N=bitcast i8*%M to i8**
store i8*%L,i8**%N,align 8
%O=load i8*,i8**%e,align 8
%P=getelementptr inbounds i8,i8*%G,i64 16
%Q=bitcast i8*%P to i8**
store i8*%O,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%G,i64 24
%S=bitcast i8*%R to i32*
store i32 7,i32*%S,align 4
%T=load i8*,i8**%c,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i64 0,i32 2,i64 0),i8*inreg%T)#0
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar0fe904135d8a1a04_DynamicKind_ppg,i64 0,i32 2,i64 1),i8*inreg%G)#0
call void@sml_end()#0
ret void
U:
%V=landingpad{i8*,i8*}
cleanup
%W=extractvalue{i8*,i8*}%V,1
call void@sml_save_exn(i8*inreg%W)#0
call void@sml_end()#0
resume{i8*,i8*}%V
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
define fastcc i8*@_SMLFN11DynamicKind13format__index_GE(i32 inreg%a)#1 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%g,label%f
f:
call void@sml_check(i32 inreg%d)
br label%g
g:
%h=call fastcc i8*@_SMLFN15BasicFormatters11format__wordE(i32 inreg%a)
store i8*%h,i8**%b,align 8
%i=call i8*@sml_alloc(i32 inreg 20)#0
%j=getelementptr inbounds i8,i8*%i,i64 -4
%k=bitcast i8*%j to i32*
store i32 1342177296,i32*%k,align 4
store i8*%i,i8**%c,align 8
%l=bitcast i8*%i to i8**
store i8*null,i8**%l,align 8
%m=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%n=getelementptr inbounds i8,i8*%i,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%i,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 20)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177296,i32*%t,align 4
store i8*%r,i8**%b,align 8
%u=getelementptr inbounds i8,i8*%r,i64 4
%v=bitcast i8*%u to i32*
store i32 0,i32*%v,align 1
%w=bitcast i8*%r to i32*
store i32 1,i32*%w,align 4
%x=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%y=getelementptr inbounds i8,i8*%r,i64 8
%z=bitcast i8*%y to i8**
store i8*%x,i8**%z,align 8
%A=getelementptr inbounds i8,i8*%r,i64 16
%B=bitcast i8*%A to i32*
store i32 2,i32*%B,align 4
%C=call i8*@sml_alloc(i32 inreg 20)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177296,i32*%E,align 4
%F=load i8*,i8**%b,align 8
%G=bitcast i8*%C to i8**
store i8*%F,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%C,i64 8
%I=bitcast i8*%H to i8**
store i8*null,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%C
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
%m=call fastcc i8*%j(i8*inreg%l,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*))
%n=getelementptr inbounds i8,i8*%m,i64 16
%o=bitcast i8*%n to i8*(i8*,i8*)**
%p=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%o,align 8
%q=bitcast i8*%m to i8**
%r=load i8*,i8**%q,align 8
%s=load i8*,i8**%b,align 8
%t=tail call fastcc i8*%p(i8*inreg%r,i8*inreg%s)
ret i8*%t
}
define fastcc i8*@_SMLFN11DynamicKind18format__dynamicKindE(i8*inreg%a)#1 gc"smlsharp"{
l:
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
br i1%g,label%j,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%b,align 8
br label%j
j:
%k=phi i8*[%i,%h],[%a,%l]
%m=bitcast i8*%k to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%b,align 8
%o=getelementptr inbounds i8,i8*%k,i64 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%c,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%d,align 8
%u=call fastcc i8*@_SMLFN10TermFormat14formatRecordTyE(i32 inreg 0,i32 inreg 4)
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*))
%B=getelementptr inbounds i8,i8*%A,i64 16
%C=bitcast i8*%B to i8*(i8*,i8*)**
%D=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%C,align 8
%E=bitcast i8*%A to i8**
%F=load i8*,i8**%E,align 8
%G=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%H=call fastcc i8*%D(i8*inreg%F,i8*inreg%G)
store i8*%H,i8**%b,align 8
%I=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%J=call fastcc i8*@_SMLFN12RuntimeTypes16format__size__propE(i8*inreg%I)
store i8*%J,i8**%c,align 8
%K=call i8*@sml_alloc(i32 inreg 20)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177296,i32*%M,align 4
store i8*%K,i8**%e,align 8
%N=getelementptr inbounds i8,i8*%K,i64 4
%O=bitcast i8*%N to i32*
store i32 0,i32*%O,align 1
%P=bitcast i8*%K to i32*
store i32 4,i32*%P,align 4
%Q=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%R=getelementptr inbounds i8,i8*%K,i64 8
%S=bitcast i8*%R to i8**
store i8*%Q,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%K,i64 16
%U=bitcast i8*%T to i32*
store i32 2,i32*%U,align 4
%V=call i8*@sml_alloc(i32 inreg 20)#0
%W=getelementptr inbounds i8,i8*%V,i64 -4
%X=bitcast i8*%W to i32*
store i32 1342177296,i32*%X,align 4
store i8*%V,i8**%c,align 8
%Y=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%Z=bitcast i8*%V to i8**
store i8*%Y,i8**%Z,align 8
%aa=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ab=getelementptr inbounds i8,i8*%V,i64 8
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%V,i64 16
%ae=bitcast i8*%ad to i32*
store i32 3,i32*%ae,align 4
%af=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ag=call fastcc i8*@_SMLFN12RuntimeTypes15format__tag__propE(i8*inreg%af)
store i8*%ag,i8**%b,align 8
%ah=call i8*@sml_alloc(i32 inreg 20)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177296,i32*%aj,align 4
store i8*%ah,i8**%d,align 8
%ak=getelementptr inbounds i8,i8*%ah,i64 4
%al=bitcast i8*%ak to i32*
store i32 0,i32*%al,align 1
%am=bitcast i8*%ah to i32*
store i32 4,i32*%am,align 4
%an=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ao=getelementptr inbounds i8,i8*%ah,i64 8
%ap=bitcast i8*%ao to i8**
store i8*%an,i8**%ap,align 8
%aq=getelementptr inbounds i8,i8*%ah,i64 16
%ar=bitcast i8*%aq to i32*
store i32 2,i32*%ar,align 4
%as=call i8*@sml_alloc(i32 inreg 20)#0
%at=getelementptr inbounds i8,i8*%as,i64 -4
%au=bitcast i8*%at to i32*
store i32 1342177296,i32*%au,align 4
%av=load i8*,i8**%d,align 8
%aw=bitcast i8*%as to i8**
store i8*%av,i8**%aw,align 8
%ax=load i8*,i8**%c,align 8
%ay=getelementptr inbounds i8,i8*%as,i64 8
%az=bitcast i8*%ay to i8**
store i8*%ax,i8**%az,align 8
%aA=getelementptr inbounds i8,i8*%as,i64 16
%aB=bitcast i8*%aA to i32*
store i32 3,i32*%aB,align 4
ret i8*%as
}
define internal fastcc i8*@_SMLLLN11DynamicKind10format__tagE_40(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind10format__tagE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN11DynamicKind11format__sizeE_41(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind11format__sizeE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN11DynamicKind13format__index_GE_42(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLFN11DynamicKind13format__index_GE(i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN11DynamicKind13format__recordE_43(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind13format__recordE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN11DynamicKind18format__dynamicKindE_44(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicKind18format__dynamicKindE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i64(i8*,i8,i64,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
