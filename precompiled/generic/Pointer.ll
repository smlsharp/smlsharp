@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ4Size=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[36x i8]}><{[4x i8]zeroinitializer,i32 -2147483612,[36x i8]c"src/ffi/main/Pointer.sml:28.28(702)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN7Pointer11importBytesE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7Pointer11importBytesE_45 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i64)*@_SMLFN7Pointer12importStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7Pointer12importStringE_46 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[37x i8]}><{[4x i8]zeroinitializer,i32 -2147483611,[37x i8]c"src/ffi/main/Pointer.sml:42.28(1077)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN7Pointer13importString_GE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7Pointer13importString_GE_47 to void(...)*),i32 -2147483647}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i64)*@_SMLLLN7Pointer6isNullE_41 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7Pointer6isNullE_48 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN7Pointer6isNullE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN7Pointer6isNullE_49 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN7Pointer6isNullE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SMLZN7Pointer11importBytesE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN7Pointer12importStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN7Pointer13importString_GE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SML_ftab15b022b21c7f9f6b_Pointer=external global i8
@h=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@prim_UnmanagedMemory_import(i8*,i32)local_unnamed_addr
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@sml_save()local_unnamed_addr#0
declare i8*@sml_str_new(i8*)local_unnamed_addr
declare i8*@sml_str_new2(i8*,i32)local_unnamed_addr
declare void@sml_unsave()local_unnamed_addr#0
declare i8*@sml_unsave_exn(i8*inreg)local_unnamed_addr#0
define private void@_SML_tabb15b022b21c7f9f6b_Pointer()#2{
unreachable
}
define void@_SML_load15b022b21c7f9f6b_Pointer(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@h,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@h,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb15b022b21c7f9f6b_Pointer,i8*@_SML_ftab15b022b21c7f9f6b_Pointer,i8*null)#0
ret void
}
define void@_SML_main15b022b21c7f9f6b_Pointer()local_unnamed_addr#3 gc"smlsharp"{
ret void
}
define fastcc i8*@_SMLFN7Pointer11importBytesE(i8*inreg%a)#4 gc"smlsharp"personality i32(...)*@sml_personality{
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
store i8*null,i8**%b,align 8
%k=getelementptr inbounds i8,i8*%i,i64 8
%l=bitcast i8*%k to i32*
%m=load i32,i32*%l,align 4
%n=icmp sgt i32%m,-1
br i1%n,label%G,label%o
o:
%p=load i8*,i8**@_SMLZ4Size,align 8
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
store i8*getelementptr inbounds(<{[4x i8],i32,[36x i8]}>,<{[4x i8],i32,[36x i8]}>*@a,i64 0,i32 2,i64 0),i8**%w,align 8
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
%H=bitcast i8*%i to i8**
%I=load i8*,i8**%H,align 8
%J=call i8*@sml_save()#0
%K=invoke i8*@prim_UnmanagedMemory_import(i8*%I,i32%m)
to label%L unwind label%M
L:
call void@sml_unsave()#0
ret i8*%K
M:
%N=landingpad{i8*,i8*}
cleanup
%O=extractvalue{i8*,i8*}%N,1
call void@sml_unsave()#0
%P=call i8*@sml_unsave_exn(i8*inreg%O)#0
resume{i8*,i8*}%N
}
define fastcc i8*@_SMLFN7Pointer12importStringE(i64 inreg%a)#4 gc"smlsharp"personality i32(...)*@sml_personality{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=inttoptr i64%a to i8*
%g=tail call i8*@sml_save()#0
%h=invoke i8*@sml_str_new(i8*%f)
to label%i unwind label%j
i:
tail call void@sml_unsave()#0
ret i8*%h
j:
%k=landingpad{i8*,i8*}
cleanup
%l=extractvalue{i8*,i8*}%k,1
tail call void@sml_unsave()#0
%m=tail call i8*@sml_unsave_exn(i8*inreg%l)#0
resume{i8*,i8*}%k
}
define fastcc i8*@_SMLFN7Pointer13importString_GE(i8*inreg%a)#4 gc"smlsharp"personality i32(...)*@sml_personality{
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
store i8*null,i8**%b,align 8
%k=getelementptr inbounds i8,i8*%i,i64 8
%l=bitcast i8*%k to i32*
%m=load i32,i32*%l,align 4
%n=icmp sgt i32%m,-1
br i1%n,label%G,label%o
o:
%p=load i8*,i8**@_SMLZ4Size,align 8
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
store i8*getelementptr inbounds(<{[4x i8],i32,[37x i8]}>,<{[4x i8],i32,[37x i8]}>*@d,i64 0,i32 2,i64 0),i8**%w,align 8
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
%H=bitcast i8*%i to i8**
%I=load i8*,i8**%H,align 8
%J=call i8*@sml_save()#0
%K=invoke i8*@sml_str_new2(i8*%I,i32%m)
to label%L unwind label%M
L:
call void@sml_unsave()#0
ret i8*%K
M:
%N=landingpad{i8*,i8*}
cleanup
%O=extractvalue{i8*,i8*}%N,1
call void@sml_unsave()#0
%P=call i8*@sml_unsave_exn(i8*inreg%O)#0
resume{i8*,i8*}%N
}
define internal fastcc i32@_SMLLLN7Pointer6isNullE_41(i64 inreg%a)#3 gc"smlsharp"{
%b=icmp eq i64%a,0
%c=zext i1%b to i32
ret i32%c
}
define fastcc i8*@_SMLFN7Pointer6isNullE(i32 inreg%a,i32 inreg%b)#3 gc"smlsharp"{
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
}
define internal fastcc i8*@_SMLLLN7Pointer11importBytesE_45(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN7Pointer11importBytesE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN7Pointer12importStringE_46(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%b to i64*
%d=load i64,i64*%c,align 4
%e=tail call fastcc i8*@_SMLFN7Pointer12importStringE(i64 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN7Pointer13importString_GE_47(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN7Pointer13importString_GE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN7Pointer6isNullE_48(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i64*
%d=load i64,i64*%c,align 4
%e=icmp eq i64%d,0
%f=zext i1%e to i32
%g=tail call i8*@sml_alloc(i32 inreg 4)#0
%h=bitcast i8*%g to i32*
%i=getelementptr inbounds i8,i8*%g,i64 -4
%j=bitcast i8*%i to i32*
store i32 4,i32*%j,align 4
store i32%f,i32*%h,align 4
ret i8*%g
}
define internal fastcc i8*@_SMLLLN7Pointer6isNullE_49(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
attributes#4={uwtable}
