@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN13NameEvalUtils14staticTfunNameE=external local_unnamed_addr global i8*
@_SMLZN13NameEvalUtils15staticTyConNameE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN10PrintUtils17primitiveToStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10PrintUtils17primitiveToStringE_32 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN10PrintUtils10tyToStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10PrintUtils10tyToStringE_33 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN10PrintUtils17primitiveToStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SMLZN10PrintUtils10tyToStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SML_ftabbc4c971ada825b24_PrintUtils=external global i8
@c=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@_SMLFN16BuiltinPrimitive16format__primitiveE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN3Bug11prettyPrintE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN6IDCalc8print__tyE(i32 inreg,i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maine024b0d66695cbd6_BuiltinPrimitive_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maindd7ac0235f3a2d21_IDCalc_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main988b411893ed23b3_NameEvalUtils()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_loade024b0d66695cbd6_BuiltinPrimitive_ppg(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loaddd7ac0235f3a2d21_IDCalc_ppg(i8*)local_unnamed_addr
declare void@_SML_load988b411893ed23b3_NameEvalUtils(i8*)local_unnamed_addr
define private void@_SML_tabbbc4c971ada825b24_PrintUtils()#2{
unreachable
}
define void@_SML_loadbc4c971ada825b24_PrintUtils(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@c,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@c,align 1
tail call void@_SML_loade024b0d66695cbd6_BuiltinPrimitive_ppg(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_loaddd7ac0235f3a2d21_IDCalc_ppg(i8*%a)#0
tail call void@_SML_load988b411893ed23b3_NameEvalUtils(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbbc4c971ada825b24_PrintUtils,i8*@_SML_ftabbc4c971ada825b24_PrintUtils,i8*null)#0
ret void
}
define void@_SML_mainbc4c971ada825b24_PrintUtils()local_unnamed_addr#1 gc"smlsharp"{
%a=load i8,i8*@c,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@c,align 1
tail call void@_SML_maine024b0d66695cbd6_BuiltinPrimitive_ppg()#1
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#1
tail call void@_SML_maindd7ac0235f3a2d21_IDCalc_ppg()#1
tail call void@_SML_main988b411893ed23b3_NameEvalUtils()#1
br label%d
}
define fastcc i8*@_SMLFN10PrintUtils17primitiveToStringE(i8*inreg%a)#1 gc"smlsharp"{
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
store i8*null,i8**%b,align 8
%j=call fastcc i8*@_SMLFN16BuiltinPrimitive16format__primitiveE(i8*inreg%h)
%k=tail call fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%j)
ret i8*%k
}
define internal fastcc i8*@_SMLLLN10PrintUtils10tyToStringE_29(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%a,i8**%e,align 8
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%l,label%k
k:
call void@sml_check(i32 inreg%i)
br label%l
l:
%m=call fastcc i8*@_SMLFN6IDCalc8print__tyE(i32 inreg 0,i32 inreg 8,i32 inreg 16,i32 inreg 1,i32 inreg 8)
store i8*%m,i8**%d,align 8
%n=bitcast i8**%e to i8***
%o=load i8**,i8***%n,align 8
store i8*null,i8**%e,align 8
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%f,align 8
%q=load i8*,i8**@_SMLZN13NameEvalUtils14staticTfunNameE,align 8
store i8*%q,i8**%g,align 8
%r=load i8*,i8**@_SMLZN13NameEvalUtils15staticTyConNameE,align 8
store i8*%r,i8**%h,align 8
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
store i8*%s,i8**%e,align 8
%v=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%y=getelementptr inbounds i8,i8*%s,i64 8
%z=bitcast i8*%y to i8**
store i8*%x,i8**%z,align 8
%A=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%B=getelementptr inbounds i8,i8*%s,i64 16
%C=bitcast i8*%B to i8**
store i8*%A,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%s,i64 24
%E=bitcast i8*%D to i32*
store i32 7,i32*%E,align 4
%F=load i8*,i8**%d,align 8
%G=getelementptr inbounds i8,i8*%F,i64 16
%H=bitcast i8*%G to i8*(i8*,i8*)**
%I=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%H,align 8
%J=bitcast i8*%F to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%d,align 8
%L=call i8*@sml_alloc(i32 inreg 28)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177304,i32*%N,align 4
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=getelementptr inbounds i8,i8*%L,i64 24
%S=bitcast i8*%R to i32*
call void@llvm.memset.p0i8.i64(i8*%Q,i8 0,i64 16,i1 false)
store i32 7,i32*%S,align 4
%T=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%U=call fastcc i8*%I(i8*inreg%T,i8*inreg%L)
%V=getelementptr inbounds i8,i8*%U,i64 16
%W=bitcast i8*%V to i8*(i8*,i8*)**
%X=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%W,align 8
%Y=bitcast i8*%U to i8**
%Z=load i8*,i8**%Y,align 8
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=call fastcc i8*%X(i8*inreg%Z,i8*inreg%aa)
%ac=tail call fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%ab)
ret i8*%ac
}
define fastcc i8*@_SMLFN10PrintUtils10tyToStringE(i8*inreg%a)#3 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10PrintUtils10tyToStringE_29 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10PrintUtils10tyToStringE_29 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLLN10PrintUtils17primitiveToStringE_32(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN10PrintUtils17primitiveToStringE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN10PrintUtils10tyToStringE_33(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN10PrintUtils10tyToStringE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i64(i8*,i8,i64,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
