@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN14ExecutablePath7getPathE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14ExecutablePath7getPathE_33 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN14ExecutablePath7getPathE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SML_ftab79d121494e8ef456_ExecutablePath=external global i8
@b=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@prim_executable_path()local_unnamed_addr
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare i8*@sml_save()local_unnamed_addr#0
declare void@sml_unsave()local_unnamed_addr#0
declare i8*@sml_unsave_exn(i8*inreg)local_unnamed_addr#0
define private void@_SML_tabb79d121494e8ef456_ExecutablePath()#1{
unreachable
}
define void@_SML_load79d121494e8ef456_ExecutablePath(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@b,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@b,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb79d121494e8ef456_ExecutablePath,i8*@_SML_ftab79d121494e8ef456_ExecutablePath,i8*null)#0
ret void
}
define void@_SML_main79d121494e8ef456_ExecutablePath()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
define fastcc i8*@_SMLFN14ExecutablePath7getPathE(i32 inreg%a)#3 gc"smlsharp"personality i32(...)*@sml_personality{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call i8*@sml_save()#0
%h=invoke i8*@prim_executable_path()
to label%i unwind label%x
i:
call void@sml_unsave()#0
store i8*%h,i8**%b,align 8
%j=getelementptr inbounds i8,i8*%h,i64 -4
%k=bitcast i8*%j to i32*
%l=load i32,i32*%k,align 4
%m=and i32%l,268435455
%n=icmp eq i32%m,1
br i1%n,label%o,label%p
o:
ret i8*null
p:
%q=call i8*@sml_alloc(i32 inreg 12)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177288,i32*%s,align 4
%t=load i8*,i8**%b,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to i32*
store i32 1,i32*%w,align 4
ret i8*%q
x:
%y=landingpad{i8*,i8*}
cleanup
%z=extractvalue{i8*,i8*}%y,1
call void@sml_unsave()#0
%A=call i8*@sml_unsave_exn(i8*inreg%z)#0
resume{i8*,i8*}%y
}
define internal fastcc i8*@_SMLLN14ExecutablePath7getPathE_33(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN14ExecutablePath7getPathE(i32 inreg undef)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
attributes#3={uwtable}
