@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN13NameEvalUtils14staticTfunNameE=external local_unnamed_addr global i8*
@_SMLZN13NameEvalUtils15staticTyConNameE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN10PrintUtils10tyToStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10PrintUtils10tyToStringE_33 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN10PrintUtils17primitiveToStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10PrintUtils17primitiveToStringE_34 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN10PrintUtils17primitiveToStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN10PrintUtils10tyToStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SML_ftab1dffe44c88ac0c66_PrintUtils=external global i8
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
declare void@_SML_main1d614b123e80cc95_IDCalc_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maind7df276306fcd4f2_NameEvalUtils()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_loade024b0d66695cbd6_BuiltinPrimitive_ppg(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_load1d614b123e80cc95_IDCalc_ppg(i8*)local_unnamed_addr
declare void@_SML_loadd7df276306fcd4f2_NameEvalUtils(i8*)local_unnamed_addr
define private void@_SML_tabb1dffe44c88ac0c66_PrintUtils()#2{
unreachable
}
define void@_SML_load1dffe44c88ac0c66_PrintUtils(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@c,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@c,align 1
tail call void@_SML_loade024b0d66695cbd6_BuiltinPrimitive_ppg(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_load1d614b123e80cc95_IDCalc_ppg(i8*%a)#0
tail call void@_SML_loadd7df276306fcd4f2_NameEvalUtils(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb1dffe44c88ac0c66_PrintUtils,i8*@_SML_ftab1dffe44c88ac0c66_PrintUtils,i8*null)#0
ret void
}
define void@_SML_main1dffe44c88ac0c66_PrintUtils()local_unnamed_addr#1 gc"smlsharp"{
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
tail call void@_SML_main1d614b123e80cc95_IDCalc_ppg()#1
tail call void@_SML_maind7df276306fcd4f2_NameEvalUtils()#1
br label%d
}
define internal fastcc i8*@_SMLLN10PrintUtils10tyToStringE_28(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%l,label%k
k:
call void@sml_check(i32 inreg%i)
br label%l
l:
%m=call fastcc i8*@_SMLFN6IDCalc8print__tyE(i32 inreg 0,i32 inreg 8,i32 inreg 16,i32 inreg 1,i32 inreg 8)
%n=getelementptr inbounds i8,i8*%m,i64 16
%o=bitcast i8*%n to i8*(i8*,i8*)**
%p=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%o,align 8
%q=bitcast i8*%m to i8**
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%h,align 8
%s=bitcast i8**%d to i8***
%t=load i8**,i8***%s,align 8
store i8*null,i8**%d,align 8
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%e,align 8
%v=load i8*,i8**@_SMLZN13NameEvalUtils14staticTfunNameE,align 8
store i8*%v,i8**%f,align 8
%w=load i8*,i8**@_SMLZN13NameEvalUtils15staticTyConNameE,align 8
store i8*%w,i8**%g,align 8
%x=call i8*@sml_alloc(i32 inreg 28)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177304,i32*%z,align 4
store i8*%x,i8**%d,align 8
%A=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%D=getelementptr inbounds i8,i8*%x,i64 8
%E=bitcast i8*%D to i8**
store i8*%C,i8**%E,align 8
%F=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%G=getelementptr inbounds i8,i8*%x,i64 16
%H=bitcast i8*%G to i8**
store i8*%F,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%x,i64 24
%J=bitcast i8*%I to i32*
store i32 7,i32*%J,align 4
%K=call i8*@sml_alloc(i32 inreg 28)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177304,i32*%M,align 4
%N=load i8*,i8**%d,align 8
%O=bitcast i8*%K to i8**
store i8*%N,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%K,i64 8
%Q=getelementptr inbounds i8,i8*%K,i64 24
%R=bitcast i8*%Q to i32*
call void@llvm.memset.p0i8.i64(i8*%P,i8 0,i64 16,i1 false)
store i32 7,i32*%R,align 4
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%S=call i8*@sml_alloc(i32 inreg 28)#0
%T=getelementptr inbounds i8,i8*%S,i64 -4
%U=bitcast i8*%T to i32*
store i32 1342177304,i32*%U,align 4
%V=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%W=bitcast i8*%S to i8**
store i8*%V,i8**%W,align 8
%X=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%Y=getelementptr inbounds i8,i8*%S,i64 8
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ab=getelementptr inbounds i8,i8*%S,i64 16
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%S,i64 24
%ae=bitcast i8*%ad to i32*
store i32 7,i32*%ae,align 4
%af=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ag=call fastcc i8*%p(i8*inreg%af,i8*inreg%S)
%ah=getelementptr inbounds i8,i8*%ag,i64 16
%ai=bitcast i8*%ah to i8*(i8*,i8*)**
%aj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ai,align 8
%ak=bitcast i8*%ag to i8**
%al=load i8*,i8**%ak,align 8
%am=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%an=call fastcc i8*%aj(i8*inreg%al,i8*inreg%am)
%ao=tail call fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%an)
ret i8*%ao
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10PrintUtils10tyToStringE_28 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10PrintUtils10tyToStringE_28 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
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
define internal fastcc i8*@_SMLLN10PrintUtils10tyToStringE_33(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN10PrintUtils10tyToStringE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN10PrintUtils17primitiveToStringE_34(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN10PrintUtils17primitiveToStringE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i64(i8*,i8,i64,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
