@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[3x i8]}><{[4x i8]zeroinitializer,i32 -2147483645,[3x i8]c"()\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 2,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[3x i8]}>,<{[4x i8],i32,[3x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 6,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@b,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@c,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[69x i8]}><{[4x i8]zeroinitializer,i32 -2147483579,[69x i8]c"src/compiler/compilerIRs/absyn/main/AbsynConstFormatter.sml:3.26(90)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN19AbsynConstFormatter15format__constantE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN19AbsynConstFormatter15format__constantE_45 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN19AbsynConstFormatter15format__constantE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SML_ftabb8a7401e9be5ceb0_AbsynConstFormatter=external global i8
@g=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN11ConstFormat14format__char__MLE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN11ConstFormat16format__string__MLE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN11ConstFormat20format__intInf__dec__MLE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN11ConstFormat21format__intInf__word__MLE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN15BasicFormatters13format__stringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main6ad4d8e473c26a9c_BasicFormatters()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main0438ba6ee5fb2523_ConstFormat()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*)local_unnamed_addr
declare void@_SML_load0438ba6ee5fb2523_ConstFormat(i8*)local_unnamed_addr
define private void@_SML_tabbb8a7401e9be5ceb0_AbsynConstFormatter()#3{
unreachable
}
define void@_SML_loadb8a7401e9be5ceb0_AbsynConstFormatter(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@g,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@g,align 1
tail call void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*%a)#0
tail call void@_SML_load0438ba6ee5fb2523_ConstFormat(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbb8a7401e9be5ceb0_AbsynConstFormatter,i8*@_SML_ftabb8a7401e9be5ceb0_AbsynConstFormatter,i8*null)#0
ret void
}
define void@_SML_mainb8a7401e9be5ceb0_AbsynConstFormatter()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@g,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@g,align 1
tail call void@_SML_main6ad4d8e473c26a9c_BasicFormatters()#2
tail call void@_SML_main0438ba6ee5fb2523_ConstFormat()#2
br label%d
}
define fastcc i8*@_SMLFN19AbsynConstFormatter15format__constantE(i8*inreg%a)#2 gc"smlsharp"{
j:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%h,label%f
f:
call void@sml_check(i32 inreg%d)
%g=load i8*,i8**%b,align 8
br label%h
h:
%i=phi i8*[%g,%f],[%a,%j]
%k=icmp eq i8*%i,null
br i1%k,label%G,label%l
l:
%m=bitcast i8*%i to i32*
%n=load i32,i32*%m,align 4
switch i32%n,label%o[
i32 1,label%aa
i32 5,label%V
i32 3,label%Q
i32 2,label%L
i32 0,label%H
i32 4,label%G
]
o:
call void@sml_matchcomp_bug()
%p=load i8*,i8**@_SMLZ5Match,align 8
store i8*%p,i8**%b,align 8
%q=call i8*@sml_alloc(i32 inreg 20)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177296,i32*%s,align 4
store i8*%q,i8**%c,align 8
%t=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[69x i8]}>,<{[4x i8],i32,[69x i8]}>*@e,i64 0,i32 2,i64 0),i8**%w,align 8
%x=getelementptr inbounds i8,i8*%q,i64 16
%y=bitcast i8*%x to i32*
store i32 3,i32*%y,align 4
%z=call i8*@sml_alloc(i32 inreg 60)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177336,i32*%B,align 4
%C=getelementptr inbounds i8,i8*%z,i64 56
%D=bitcast i8*%C to i32*
store i32 1,i32*%D,align 4
%E=load i8*,i8**%c,align 8
%F=bitcast i8*%z to i8**
store i8*%E,i8**%F,align 8
call void@sml_raise(i8*inreg%z)#1
unreachable
G:
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@d,i64 0,i32 2)to i8*)
H:
%I=getelementptr inbounds i8,i8*%i,i64 4
%J=load i8,i8*%I,align 1
%K=tail call fastcc i8*@_SMLFN11ConstFormat14format__char__MLE(i8 inreg%J)
ret i8*%K
L:
%M=getelementptr inbounds i8,i8*%i,i64 8
%N=bitcast i8*%M to i8**
%O=load i8*,i8**%N,align 8
%P=tail call fastcc i8*@_SMLFN15BasicFormatters13format__stringE(i8*inreg%O)
ret i8*%P
Q:
%R=getelementptr inbounds i8,i8*%i,i64 8
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
%U=tail call fastcc i8*@_SMLFN11ConstFormat16format__string__MLE(i8*inreg%T)
ret i8*%U
V:
%W=getelementptr inbounds i8,i8*%i,i64 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
%Z=tail call fastcc i8*@_SMLFN11ConstFormat21format__intInf__word__MLE(i8*inreg%Y)
ret i8*%Z
aa:
%ab=getelementptr inbounds i8,i8*%i,i64 8
%ac=bitcast i8*%ab to i8**
%ad=load i8*,i8**%ac,align 8
%ae=tail call fastcc i8*@_SMLFN11ConstFormat20format__intInf__dec__MLE(i8*inreg%ad)
ret i8*%ae
}
define internal fastcc i8*@_SMLLN19AbsynConstFormatter15format__constantE_45(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN19AbsynConstFormatter15format__constantE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
