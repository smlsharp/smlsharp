@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11CommandLine4nameE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11CommandLine4nameE_40 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11CommandLine9argumentsE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11CommandLine9argumentsE_41 to void(...)*),i32 -2147483647}>,align 8
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
define fastcc i8*@_SMLFN11CommandLine9argumentsE(i32 inreg%a)#3 gc"smlsharp"personality i32(...)*@sml_personality{
o:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=call i32@prim_CommandLine_argc()
%f=call i8*@prim_CommandLine_argv()
%g=call i8*@sml_alloc(i32 inreg 20)#0
%h=bitcast i8*%g to i32*
%i=getelementptr inbounds i8,i8*%g,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
%k=getelementptr inbounds i8,i8*%g,i64 4
%l=bitcast i8*%k to i32*
store i32 0,i32*%l,align 1
store i32%e,i32*%h,align 4
br label%m
m:
%n=phi i8*[%aa,%P],[%g,%o]
%p=phi i8*[%ag,%P],[null,%o]
%q=getelementptr inbounds i8,i8*%n,i64 8
%r=bitcast i8*%q to i8**
store i8*%p,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%n,i64 16
%t=bitcast i8*%s to i32*
store i32 2,i32*%t,align 4
store i8*%n,i8**%b,align 8
%u=load atomic i32,i32*@sml_check_flag unordered,align 4
%v=icmp eq i32%u,0
br i1%v,label%y,label%w
w:
call void@sml_check(i32 inreg%u)
%x=load i8*,i8**%b,align 8
br label%y
y:
%z=phi i8*[%x,%w],[%n,%m]
%A=bitcast i8*%z to i32*
%B=load i32,i32*%A,align 4
%C=getelementptr inbounds i8,i8*%z,i64 8
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%b,align 8
%F=icmp slt i32%B,2
br i1%F,label%al,label%G
G:
%H=add nsw i32%B,-1
%I=shl i32%H,3
%J=sext i32%I to i64
%K=getelementptr i8,i8*%f,i64%J
%L=bitcast i8*%K to i8**
%M=load i8*,i8**%L,align 8
%N=call i8*@sml_save()#0
%O=invoke i8*@sml_str_new(i8*%M)
to label%P unwind label%ah
P:
call void@sml_unsave()#0
store i8*%O,i8**%c,align 8
%Q=call i8*@sml_alloc(i32 inreg 20)#0
%R=getelementptr inbounds i8,i8*%Q,i64 -4
%S=bitcast i8*%R to i32*
store i32 1342177296,i32*%S,align 4
store i8*%Q,i8**%d,align 8
%T=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%U=bitcast i8*%Q to i8**
store i8*%T,i8**%U,align 8
%V=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%W=getelementptr inbounds i8,i8*%Q,i64 8
%X=bitcast i8*%W to i8**
store i8*%V,i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%Q,i64 16
%Z=bitcast i8*%Y to i32*
store i32 3,i32*%Z,align 4
%aa=call i8*@sml_alloc(i32 inreg 20)#0
%ab=bitcast i8*%aa to i32*
%ac=getelementptr inbounds i8,i8*%aa,i64 -4
%ad=bitcast i8*%ac to i32*
store i32 1342177296,i32*%ad,align 4
%ae=getelementptr inbounds i8,i8*%aa,i64 4
%af=bitcast i8*%ae to i32*
store i32 0,i32*%af,align 1
store i32%H,i32*%ab,align 4
%ag=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
br label%m
ah:
%ai=landingpad{i8*,i8*}
cleanup
%aj=extractvalue{i8*,i8*}%ai,1
call void@sml_unsave()#0
%ak=call i8*@sml_unsave_exn(i8*inreg%aj)#0
resume{i8*,i8*}%ai
al:
ret i8*%E
}
define internal fastcc i8*@_SMLLLN11CommandLine4nameE_40(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11CommandLine4nameE(i32 inreg undef)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN11CommandLine9argumentsE_41(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11CommandLine9argumentsE(i32 inreg undef)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
attributes#3={uwtable}
