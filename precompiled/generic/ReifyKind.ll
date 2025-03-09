@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN19DatatypeCompilation8emptyEnvE=external local_unnamed_addr global i8*
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN9ReifyKind11singletonTyE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind11singletonTyE_52 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[75x i8]}><{[4x i8]zeroinitializer,i32 -2147483573,[75x i8]c"src/compiler/compilePhases/recordcompilation/main/ReifyKind.sml:22.19(561)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[18x i8]}><{[4x i8]zeroinitializer,i32 -2147483630,[18x i8]c"ReifyKind.compare\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLFN9ReifyKind7compareE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind7compareE_53 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN9ReifyKind12generateArgsE_43 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind12generateArgsE_54 to void(...)*),i32 -2147483647}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN9ReifyKind12generateArgsE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind12generateArgsE_55 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN9ReifyKind16generateInstanceE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind16generateInstanceE_57 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9ReifyKind11singletonTyE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SMLZN9ReifyKind12generateArgsE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SMLZN9ReifyKind7compareE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SMLZN9ReifyKind16generateInstanceE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SML_ftabff64188d21513a09_ReifyKind=external global i8
@h=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN11TypesBasics7derefTyE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13TyToReifiedTy4toTyE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN14BoundTypeVarID7compareE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN19DatatypeCompilation10compileExpE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN7ReifyTy15TyRepWithLookUpE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main22c101bff228a4a9_LocalID()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main7833b15b41d4b824_TypesBasics()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maina005ce1f4fb2368a_TyToReifiedTy()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main972a18c2d8c2c40c_ReifyTy()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainba6f91a4b5bbe1e6_DatatypeCompilation()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_load22c101bff228a4a9_LocalID(i8*)local_unnamed_addr
declare void@_SML_load7833b15b41d4b824_TypesBasics(i8*)local_unnamed_addr
declare void@_SML_loada005ce1f4fb2368a_TyToReifiedTy(i8*)local_unnamed_addr
declare void@_SML_load972a18c2d8c2c40c_ReifyTy(i8*)local_unnamed_addr
declare void@_SML_loadba6f91a4b5bbe1e6_DatatypeCompilation(i8*)local_unnamed_addr
define private void@_SML_tabbff64188d21513a09_ReifyKind()#3{
unreachable
}
define void@_SML_loadff64188d21513a09_ReifyKind(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@h,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@h,align 1
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_load22c101bff228a4a9_LocalID(i8*%a)#0
tail call void@_SML_load7833b15b41d4b824_TypesBasics(i8*%a)#0
tail call void@_SML_loada005ce1f4fb2368a_TyToReifiedTy(i8*%a)#0
tail call void@_SML_load972a18c2d8c2c40c_ReifyTy(i8*%a)#0
tail call void@_SML_loadba6f91a4b5bbe1e6_DatatypeCompilation(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbff64188d21513a09_ReifyKind,i8*@_SML_ftabff64188d21513a09_ReifyKind,i8*null)#0
ret void
}
define void@_SML_mainff64188d21513a09_ReifyKind()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@h,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@h,align 1
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_main22c101bff228a4a9_LocalID()#2
tail call void@_SML_main7833b15b41d4b824_TypesBasics()#2
tail call void@_SML_maina005ce1f4fb2368a_TyToReifiedTy()#2
tail call void@_SML_main972a18c2d8c2c40c_ReifyTy()#2
tail call void@_SML_mainba6f91a4b5bbe1e6_DatatypeCompilation()#2
br label%d
}
define fastcc i8*@_SMLFN9ReifyKind11singletonTyE(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=call i8*@sml_alloc(i32 inreg 20)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177296,i32*%f,align 4
%g=getelementptr inbounds i8,i8*%c,i64 4
%h=bitcast i8*%g to i32*
store i32 0,i32*%h,align 1
store i32 2,i32*%d,align 4
%i=load i8*,i8**%b,align 8
%j=getelementptr inbounds i8,i8*%c,i64 8
%k=bitcast i8*%j to i8**
store i8*%i,i8**%k,align 8
%l=getelementptr inbounds i8,i8*%c,i64 16
%m=bitcast i8*%l to i32*
store i32 2,i32*%m,align 4
ret i8*%c
}
define fastcc i32@_SMLFN9ReifyKind7compareE(i8*inreg%a)#2 gc"smlsharp"{
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
%k=bitcast i8*%i to i8**
%l=load i8*,i8**%k,align 8
%m=getelementptr inbounds i8,i8*%i,i64 8
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=call fastcc i8*@_SMLFN11TypesBasics7derefTyE(i8*inreg%l)
store i8*%p,i8**%c,align 8
%q=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%r=call fastcc i8*@_SMLFN11TypesBasics7derefTyE(i8*inreg%q)
%s=load i8*,i8**%c,align 8
%t=icmp eq i8*%s,null
br i1%t,label%y,label%u
u:
%v=bitcast i8*%s to i32*
%w=load i32,i32*%v,align 4
%x=icmp eq i32%w,1
br i1%x,label%z,label%y
y:
store i8*null,i8**%c,align 8
br label%V
z:
store i8*null,i8**%c,align 8
%A=getelementptr inbounds i8,i8*%s,i64 4
%B=bitcast i8*%A to i32*
%C=load i32,i32*%B,align 4
%D=icmp eq i8*%r,null
br i1%D,label%V,label%E
E:
%F=bitcast i8*%r to i32*
%G=load i32,i32*%F,align 4
%H=icmp eq i32%G,1
br i1%H,label%I,label%V
I:
%J=getelementptr inbounds i8,i8*%r,i64 4
%K=bitcast i8*%J to i32*
%L=load i32,i32*%K,align 4
%M=call i8*@sml_alloc(i32 inreg 12)#0
%N=bitcast i8*%M to i32*
%O=getelementptr inbounds i8,i8*%M,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177288,i32*%P,align 4
store i32%C,i32*%N,align 4
%Q=getelementptr inbounds i8,i8*%M,i64 4
%R=bitcast i8*%Q to i32*
store i32%L,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%M,i64 8
%T=bitcast i8*%S to i32*
store i32 0,i32*%T,align 4
%U=tail call fastcc i32@_SMLFN14BoundTypeVarID7compareE(i8*inreg%M)
ret i32%U
V:
%W=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%W,i8**%b,align 8
%X=call i8*@sml_alloc(i32 inreg 28)#0
%Y=getelementptr inbounds i8,i8*%X,i64 -4
%Z=bitcast i8*%Y to i32*
store i32 1342177304,i32*%Z,align 4
store i8*%X,i8**%c,align 8
%aa=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ab=bitcast i8*%X to i8**
store i8*%aa,i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%X,i64 8
%ad=bitcast i8*%ac to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[75x i8]}>,<{[4x i8],i32,[75x i8]}>*@b,i64 0,i32 2,i64 0),i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%X,i64 16
%af=bitcast i8*%ae to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[18x i8]}>,<{[4x i8],i32,[18x i8]}>*@c,i64 0,i32 2,i64 0),i8**%af,align 8
%ag=getelementptr inbounds i8,i8*%X,i64 24
%ah=bitcast i8*%ag to i32*
store i32 7,i32*%ah,align 4
%ai=call i8*@sml_alloc(i32 inreg 60)#0
%aj=getelementptr inbounds i8,i8*%ai,i64 -4
%ak=bitcast i8*%aj to i32*
store i32 1342177336,i32*%ak,align 4
%al=getelementptr inbounds i8,i8*%ai,i64 56
%am=bitcast i8*%al to i32*
store i32 1,i32*%am,align 4
%an=load i8*,i8**%c,align 8
%ao=bitcast i8*%ai to i8**
store i8*%an,i8**%ao,align 8
call void@sml_raise(i8*inreg%ai)#1
unreachable
}
define internal fastcc i8*@_SMLLLN9ReifyKind12generateArgsE_43(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=getelementptr inbounds i8,i8*%a,i64 4
%e=bitcast i8*%d to i32*
%f=load i32,i32*%e,align 4
%g=icmp eq i32%f,0
br i1%g,label%M,label%h
h:
%i=bitcast i8*%a to i32*
%j=load i32,i32*%i,align 4
%k=call i8*@sml_alloc(i32 inreg 12)#0
%l=bitcast i8*%k to i32*
%m=getelementptr inbounds i8,i8*%k,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177288,i32*%n,align 4
store i8*%k,i8**%b,align 8
store i32 1,i32*%l,align 4
%o=getelementptr inbounds i8,i8*%k,i64 4
%p=bitcast i8*%o to i32*
store i32%j,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i32*
store i32 0,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 20)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177296,i32*%u,align 4
store i8*%s,i8**%c,align 8
%v=getelementptr inbounds i8,i8*%s,i64 4
%w=bitcast i8*%v to i32*
store i32 0,i32*%w,align 1
%x=bitcast i8*%s to i32*
store i32 2,i32*%x,align 4
%y=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%z=getelementptr inbounds i8,i8*%s,i64 8
%A=bitcast i8*%z to i8**
store i8*%y,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 16
%C=bitcast i8*%B to i32*
store i32 2,i32*%C,align 4
%D=call i8*@sml_alloc(i32 inreg 20)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177296,i32*%F,align 4
%G=load i8*,i8**%c,align 8
%H=bitcast i8*%D to i8**
store i8*%G,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%D,i64 8
%J=bitcast i8*%I to i8**
store i8*null,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%D,i64 16
%L=bitcast i8*%K to i32*
store i32 3,i32*%L,align 4
ret i8*%D
M:
ret i8*null
}
define fastcc i8*@_SMLFN9ReifyKind12generateArgsE(i8*inreg%a)#4 gc"smlsharp"{
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
}
define internal fastcc i8*@_SMLLL6lookUp_47(i8*inreg%a,i32 inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%i
g:
%h=bitcast i8*%a to i8**
br label%l
i:
call void@sml_check(i32 inreg%e)
%j=bitcast i8**%c to i8***
%k=load i8**,i8***%j,align 8
br label%l
l:
%m=phi i8**[%k,%i],[%h,%g]
%n=load i8*,i8**%m,align 8
%o=getelementptr inbounds i8,i8*%n,i64 16
%p=bitcast i8*%o to i8*(i8*,i8*)**
%q=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%p,align 8
%r=bitcast i8*%n to i8**
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%c,align 8
%t=call i8*@sml_alloc(i32 inreg 12)#0
%u=bitcast i8*%t to i32*
%v=getelementptr inbounds i8,i8*%t,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177288,i32*%w,align 4
store i8*%t,i8**%d,align 8
store i32 1,i32*%u,align 4
%x=getelementptr inbounds i8,i8*%t,i64 4
%y=bitcast i8*%x to i32*
store i32%b,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%t,i64 8
%A=bitcast i8*%z to i32*
store i32 0,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=bitcast i8*%B to i32*
%D=getelementptr inbounds i8,i8*%B,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177296,i32*%E,align 4
%F=getelementptr inbounds i8,i8*%B,i64 4
%G=bitcast i8*%F to i32*
store i32 0,i32*%G,align 1
store i32 2,i32*%C,align 4
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%B,i64 8
%J=bitcast i8*%I to i8**
store i8*%H,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 16
%L=bitcast i8*%K to i32*
store i32 2,i32*%L,align 4
%M=load i8*,i8**%c,align 8
%N=tail call fastcc i8*%q(i8*inreg%M,i8*inreg%B)
ret i8*%N
}
define internal fastcc i8*@_SMLLLN9ReifyKind16generateInstanceE_48(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
store i8*%a,i8**%f,align 8
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%k,label%m
k:
%l=bitcast i8*%a to i8**
br label%p
m:
call void@sml_check(i32 inreg%i)
%n=bitcast i8**%f to i8***
%o=load i8**,i8***%n,align 8
br label%p
p:
%q=phi i8**[%o,%m],[%l,%k]
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%d,align 8
%s=call i8*@sml_alloc(i32 inreg 12)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177288,i32*%u,align 4
store i8*%s,i8**%e,align 8
%v=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to i32*
store i32 1,i32*%y,align 4
%z=call i8*@sml_alloc(i32 inreg 28)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177304,i32*%B,align 4
store i8*%z,i8**%g,align 8
%C=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLL6lookUp_47 to void(...)*),void(...)**%F,align 8
%G=getelementptr inbounds i8,i8*%z,i64 16
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL6lookUp_56 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%z,i64 24
%J=bitcast i8*%I to i32*
store i32 -2147483647,i32*%J,align 4
%K=load i8*,i8**%c,align 8
%L=call fastcc i8*@_SMLFN13TyToReifiedTy4toTyE(i8*inreg%K)
%M=getelementptr inbounds i8,i8*%L,i64 16
%N=bitcast i8*%M to i8*(i8*,i8*)**
%O=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%N,align 8
%P=bitcast i8*%L to i8**
%Q=load i8*,i8**%P,align 8
%R=load i8*,i8**%f,align 8
%S=getelementptr inbounds i8,i8*%R,i64 8
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
%V=call fastcc i8*%O(i8*inreg%Q,i8*inreg%U)
store i8*%V,i8**%d,align 8
%W=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%X=call fastcc i8*@_SMLFN7ReifyTy15TyRepWithLookUpE(i8*inreg%W)
%Y=getelementptr inbounds i8,i8*%X,i64 16
%Z=bitcast i8*%Y to i8*(i8*,i8*)**
%aa=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Z,align 8
%ab=bitcast i8*%X to i8**
%ac=load i8*,i8**%ab,align 8
%ad=load i8*,i8**%c,align 8
%ae=call fastcc i8*%aa(i8*inreg%ac,i8*inreg%ad)
%af=getelementptr inbounds i8,i8*%ae,i64 16
%ag=bitcast i8*%af to i8*(i8*,i8*)**
%ah=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ag,align 8
%ai=bitcast i8*%ae to i8**
%aj=load i8*,i8**%ai,align 8
%ak=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%al=call fastcc i8*%ah(i8*inreg%aj,i8*inreg%ak)
store i8*%al,i8**%d,align 8
%am=load i8*,i8**@_SMLZN19DatatypeCompilation8emptyEnvE,align 8
%an=call fastcc i8*@_SMLFN19DatatypeCompilation10compileExpE(i8*inreg%am)
%ao=getelementptr inbounds i8,i8*%an,i64 16
%ap=bitcast i8*%ao to i8*(i8*,i8*)**
%aq=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ap,align 8
%ar=bitcast i8*%an to i8**
%as=load i8*,i8**%ar,align 8
%at=bitcast i8**%d to i8***
%au=load i8**,i8***%at,align 8
%av=load i8*,i8**%au,align 8
%aw=call fastcc i8*%aq(i8*inreg%as,i8*inreg%av)
store i8*%aw,i8**%e,align 8
%ax=load i8*,i8**%d,align 8
%ay=getelementptr inbounds i8,i8*%ax,i64 8
%az=bitcast i8*%ay to i8**
%aA=load i8*,i8**%az,align 8
store i8*%aA,i8**%d,align 8
%aB=load i8*,i8**%f,align 8
%aC=getelementptr inbounds i8,i8*%aB,i64 8
%aD=bitcast i8*%aC to i8**
%aE=load i8*,i8**%aD,align 8
store i8*%aE,i8**%f,align 8
%aF=call i8*@sml_alloc(i32 inreg 20)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177296,i32*%aH,align 4
store i8*%aF,i8**%g,align 8
%aI=getelementptr inbounds i8,i8*%aF,i64 4
%aJ=bitcast i8*%aI to i32*
store i32 0,i32*%aJ,align 1
%aK=bitcast i8*%aF to i32*
store i32 2,i32*%aK,align 4
%aL=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aM=getelementptr inbounds i8,i8*%aF,i64 8
%aN=bitcast i8*%aM to i8**
store i8*%aL,i8**%aN,align 8
%aO=getelementptr inbounds i8,i8*%aF,i64 16
%aP=bitcast i8*%aO to i32*
store i32 2,i32*%aP,align 4
%aQ=call i8*@sml_alloc(i32 inreg 20)#0
%aR=getelementptr inbounds i8,i8*%aQ,i64 -4
%aS=bitcast i8*%aR to i32*
store i32 1342177296,i32*%aS,align 4
store i8*%aQ,i8**%h,align 8
%aT=getelementptr inbounds i8,i8*%aQ,i64 4
%aU=bitcast i8*%aT to i32*
store i32 0,i32*%aU,align 1
%aV=bitcast i8*%aQ to i32*
store i32 9,i32*%aV,align 4
%aW=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aX=getelementptr inbounds i8,i8*%aQ,i64 8
%aY=bitcast i8*%aX to i8**
store i8*%aW,i8**%aY,align 8
%aZ=getelementptr inbounds i8,i8*%aQ,i64 16
%a0=bitcast i8*%aZ to i32*
store i32 2,i32*%a0,align 4
%a1=call i8*@sml_alloc(i32 inreg 44)#0
%a2=getelementptr inbounds i8,i8*%a1,i64 -4
%a3=bitcast i8*%a2 to i32*
store i32 1342177320,i32*%a3,align 4
store i8*%a1,i8**%f,align 8
%a4=getelementptr inbounds i8,i8*%a1,i64 4
%a5=bitcast i8*%a4 to i32*
store i32 0,i32*%a5,align 1
%a6=bitcast i8*%a1 to i32*
store i32 1,i32*%a6,align 4
%a7=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%a8=getelementptr inbounds i8,i8*%a1,i64 8
%a9=bitcast i8*%a8 to i8**
store i8*%a7,i8**%a9,align 8
%ba=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bb=getelementptr inbounds i8,i8*%a1,i64 16
%bc=bitcast i8*%bb to i8**
store i8*%ba,i8**%bc,align 8
%bd=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%be=getelementptr inbounds i8,i8*%a1,i64 24
%bf=bitcast i8*%be to i8**
store i8*%bd,i8**%bf,align 8
%bg=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bh=getelementptr inbounds i8,i8*%a1,i64 32
%bi=bitcast i8*%bh to i8**
store i8*%bg,i8**%bi,align 8
%bj=getelementptr inbounds i8,i8*%a1,i64 40
%bk=bitcast i8*%bj to i32*
store i32 30,i32*%bk,align 4
%bl=call i8*@sml_alloc(i32 inreg 20)#0
%bm=getelementptr inbounds i8,i8*%bl,i64 -4
%bn=bitcast i8*%bm to i32*
store i32 1342177296,i32*%bn,align 4
store i8*%bl,i8**%c,align 8
%bo=getelementptr inbounds i8,i8*%bl,i64 4
%bp=bitcast i8*%bo to i32*
store i32 0,i32*%bp,align 1
%bq=bitcast i8*%bl to i32*
store i32 2,i32*%bq,align 4
%br=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bs=getelementptr inbounds i8,i8*%bl,i64 8
%bt=bitcast i8*%bs to i8**
store i8*%br,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bl,i64 16
%bv=bitcast i8*%bu to i32*
store i32 2,i32*%bv,align 4
%bw=call i8*@sml_alloc(i32 inreg 12)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177288,i32*%by,align 4
%bz=load i8*,i8**%c,align 8
%bA=bitcast i8*%bw to i8**
store i8*%bz,i8**%bA,align 8
%bB=getelementptr inbounds i8,i8*%bw,i64 8
%bC=bitcast i8*%bB to i32*
store i32 1,i32*%bC,align 4
ret i8*%bw
}
define internal fastcc i8*@_SMLLLN9ReifyKind16generateInstanceE_49(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%b,i8**%c,align 8
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%n=getelementptr inbounds i8,i8*%h,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%h,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 28)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177304,i32*%t,align 4
%u=load i8*,i8**%e,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind16generateInstanceE_48 to void(...)*),void(...)**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind16generateInstanceE_48 to void(...)*),void(...)**%z,align 8
%A=getelementptr inbounds i8,i8*%r,i64 24
%B=bitcast i8*%A to i32*
store i32 -2147483647,i32*%B,align 4
ret i8*%r
}
define fastcc i8*@_SMLFN9ReifyKind16generateInstanceE(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=getelementptr inbounds i8,i8*%a,i64 8
%e=bitcast i8*%d to i8**
%f=load i8*,i8**%e,align 8
store i8*%f,i8**%b,align 8
%g=call i8*@sml_alloc(i32 inreg 12)#0
%h=getelementptr inbounds i8,i8*%g,i64 -4
%i=bitcast i8*%h to i32*
store i32 1342177288,i32*%i,align 4
store i8*%g,i8**%c,align 8
%j=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%k=bitcast i8*%g to i8**
store i8*%j,i8**%k,align 8
%l=getelementptr inbounds i8,i8*%g,i64 8
%m=bitcast i8*%l to i32*
store i32 1,i32*%m,align 4
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
%q=load i8*,i8**%c,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%n,i64 8
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind16generateInstanceE_49 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%n,i64 16
%v=bitcast i8*%u to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ReifyKind16generateInstanceE_49 to void(...)*),void(...)**%v,align 8
%w=getelementptr inbounds i8,i8*%n,i64 24
%x=bitcast i8*%w to i32*
store i32 -2147483647,i32*%x,align 4
ret i8*%n
}
define internal fastcc i8*@_SMLLLN9ReifyKind11singletonTyE_52(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN9ReifyKind11singletonTyE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN9ReifyKind7compareE_53(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLFN9ReifyKind7compareE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLLN9ReifyKind12generateArgsE_54(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLLN9ReifyKind12generateArgsE_43(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN9ReifyKind12generateArgsE_55(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
}
define internal fastcc i8*@_SMLLL6lookUp_56(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLL6lookUp_47(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN9ReifyKind16generateInstanceE_57(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN9ReifyKind16generateInstanceE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
