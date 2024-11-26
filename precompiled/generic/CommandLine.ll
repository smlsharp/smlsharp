@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11CommandLine4nameE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11CommandLine4nameE_40 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11CommandLine9argumentsE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11CommandLine9argumentsE_41 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11CommandLine4nameE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN11CommandLine9argumentsE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SML_ftab3b03551f42df3061_CommandLine=external global i8
@d=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i32@prim_CommandLine_argc()local_unnamed_addr
declare i8*@prim_CommandLine_argv()local_unnamed_addr
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare i8*@sml_save()local_unnamed_addr#0
declare i8*@sml_str_new(i8*)local_unnamed_addr
declare void@sml_unsave()local_unnamed_addr#0
declare i8*@sml_unsave_exn(i8*inreg)local_unnamed_addr#0
define private void@_SML_tabb3b03551f42df3061_CommandLine()#1{
unreachable
}
define void@_SML_load3b03551f42df3061_CommandLine(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@d,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@d,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb3b03551f42df3061_CommandLine,i8*@_SML_ftab3b03551f42df3061_CommandLine,i8*null)#0
ret void
}
define void@_SML_main3b03551f42df3061_CommandLine()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
define fastcc i8*@_SMLFN11CommandLine4nameE(i32 inreg%a)#3 gc"smlsharp"personality i32(...)*@sml_personality{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=tail call i32@prim_CommandLine_argc()
%g=tail call i8*@prim_CommandLine_argv()
%h=icmp slt i32%f,1
br i1%h,label%s,label%i
i:
%j=bitcast i8*%g to i8**
%k=load i8*,i8**%j,align 8
%l=tail call i8*@sml_save()#0
%m=invoke i8*@sml_str_new(i8*%k)
to label%n unwind label%o
n:
tail call void@sml_unsave()#0
ret i8*%m
o:
%p=landingpad{i8*,i8*}
cleanup
%q=extractvalue{i8*,i8*}%p,1
tail call void@sml_unsave()#0
%r=tail call i8*@sml_unsave_exn(i8*inreg%q)#0
resume{i8*,i8*}%p
s:
ret i8*getelementptr inbounds(<{[4x i8],i32,[1x i8]}>,<{[4x i8],i32,[1x i8]}>*@a,i64 0,i32 2,i64 0)
}
define internal fastcc i8*@_SMLL4loop_37(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"personality i32(...)*@sml_personality{
j:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%e,align 8
%g=bitcast i8**%e to i8***
br label%h
h:
%i=phi i8*[%S,%H],[%b,%j]
store i8*%i,i8**%c,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%c,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%i,%h]
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=getelementptr inbounds i8,i8*%p,i64 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=icmp slt i32%r,2
br i1%v,label%ah,label%w
w:
%x=add nsw i32%r,-1
%y=load i8**,i8***%g,align 8
%z=load i8*,i8**%y,align 8
%A=shl i32%x,3
%B=sext i32%A to i64
%C=getelementptr i8,i8*%z,i64%B
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
%F=call i8*@sml_save()#0
%G=invoke i8*@sml_str_new(i8*%E)
to label%H unwind label%ad
H:
call void@sml_unsave()#0
store i8*%G,i8**%d,align 8
%I=call i8*@sml_alloc(i32 inreg 20)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177296,i32*%K,align 4
store i8*%I,i8**%f,align 8
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%O=getelementptr inbounds i8,i8*%I,i64 8
%P=bitcast i8*%O to i8**
store i8*%N,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%I,i64 16
%R=bitcast i8*%Q to i32*
store i32 3,i32*%R,align 4
%S=call i8*@sml_alloc(i32 inreg 20)#0
%T=bitcast i8*%S to i32*
%U=getelementptr inbounds i8,i8*%S,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177296,i32*%V,align 4
%W=getelementptr inbounds i8,i8*%S,i64 4
%X=bitcast i8*%W to i32*
store i32 0,i32*%X,align 1
store i32%x,i32*%T,align 4
%Y=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%Z=getelementptr inbounds i8,i8*%S,i64 8
%aa=bitcast i8*%Z to i8**
store i8*%Y,i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%S,i64 16
%ac=bitcast i8*%ab to i32*
store i32 2,i32*%ac,align 4
br label%h
ad:
%ae=landingpad{i8*,i8*}
cleanup
%af=extractvalue{i8*,i8*}%ae,1
call void@sml_unsave()#0
%ag=call i8*@sml_unsave_exn(i8*inreg%af)#0
resume{i8*,i8*}%ae
ah:
ret i8*%u
}
define fastcc i8*@_SMLFN11CommandLine9argumentsE(i32 inreg%a)#3 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call i32@prim_CommandLine_argc()
%h=call i8*@prim_CommandLine_argv()
%i=call i8*@sml_alloc(i32 inreg 12)#0
%j=getelementptr inbounds i8,i8*%i,i64 -4
%k=bitcast i8*%j to i32*
store i32 1342177288,i32*%k,align 4
store i8*%i,i8**%b,align 8
%l=bitcast i8*%i to i8**
store i8*%h,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%i,i64 8
%n=bitcast i8*%m to i32*
store i32 0,i32*%n,align 4
%o=call i8*@sml_alloc(i32 inreg 28)#0
%p=getelementptr inbounds i8,i8*%o,i64 -4
%q=bitcast i8*%p to i32*
store i32 1342177304,i32*%q,align 4
%r=load i8*,i8**%b,align 8
%s=bitcast i8*%o to i8**
store i8*%r,i8**%s,align 8
%t=getelementptr inbounds i8,i8*%o,i64 8
%u=bitcast i8*%t to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4loop_37 to void(...)*),void(...)**%u,align 8
%v=getelementptr inbounds i8,i8*%o,i64 16
%w=bitcast i8*%v to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4loop_37 to void(...)*),void(...)**%w,align 8
%x=getelementptr inbounds i8,i8*%o,i64 24
%y=bitcast i8*%x to i32*
store i32 -2147483647,i32*%y,align 4
%z=call i8*@sml_alloc(i32 inreg 20)#0
%A=bitcast i8*%z to i32*
%B=getelementptr inbounds i8,i8*%z,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177296,i32*%C,align 4
%D=getelementptr inbounds i8,i8*%z,i64 4
%E=bitcast i8*%D to i32*
store i32 0,i32*%E,align 1
store i32%g,i32*%A,align 4
%F=getelementptr inbounds i8,i8*%z,i64 8
%G=bitcast i8*%F to i8**
store i8*null,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%z,i64 16
%I=bitcast i8*%H to i32*
store i32 2,i32*%I,align 4
%J=load i8*,i8**%b,align 8
%K=tail call fastcc i8*@_SMLL4loop_37(i8*inreg%J,i8*inreg%z)
ret i8*%K
}
define internal fastcc i8*@_SMLLN11CommandLine4nameE_40(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11CommandLine4nameE(i32 inreg undef)
ret i8*%c
}
define internal fastcc i8*@_SMLLN11CommandLine9argumentsE_41(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11CommandLine9argumentsE(i32 inreg undef)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
attributes#3={uwtable}
