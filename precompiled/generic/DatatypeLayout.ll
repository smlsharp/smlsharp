@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN12RuntimeTypes10contagPropE=external local_unnamed_addr global i8*
@_SMLZN12RuntimeTypes10recordPropE=external local_unnamed_addr global i8*
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZN6Symbol14symbolToStringE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLN14DatatypeLayout8classifyE_45 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14DatatypeLayout8classifyE_62 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*null,i8*null,i32 3}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 3,[4x i8]zeroinitializer,i32 0}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 3,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,[4x i8],i32}>*@c,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 1,[4x i8]zeroinitializer,i32 0}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 4,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,[4x i8],i32}>*@e,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 3,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@f,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 0,[4x i8]zeroinitializer,i32 0}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 4,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,[4x i8],i32}>*@h,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 3,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@i,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,[68x i8]}><{[4x i8]zeroinitializer,i32 -2147483580,[68x i8]c"src/compiler/data/runtimetypes/main/DatatypeLayout.sml:145.42(5805)\00"}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,[19x i8]}><{[4x i8]zeroinitializer,i32 -2147483629,[19x i8]c"layout: no variant\00"}>,align 8
@m=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN14DatatypeLayout14datatypeLayoutE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14DatatypeLayout14datatypeLayoutE_64 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN14DatatypeLayout14datatypeLayoutE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@m,i64 0,i32 2)to i8*)
@_SML_ftab3b8fa7741d09e0f0_DatatypeLayout=external global i8
@n=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i32@_SMLFN12RuntimeTypes15canBeRegardedAsE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN4Bool3notE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6IDCalc13propertyOfItyE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6Symbol14symbolToStringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9SymbolEnv6foldriE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maindaa180c1799f3810_Bool()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainc88dec21a8800496_RuntimeTypes_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main44ca35c4c731682b_Symbol()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main1d614b123e80cc95_IDCalc_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loaddaa180c1799f3810_Bool(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*)local_unnamed_addr
declare void@_SML_load44ca35c4c731682b_Symbol(i8*)local_unnamed_addr
declare void@_SML_load1d614b123e80cc95_IDCalc_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb3b8fa7741d09e0f0_DatatypeLayout()#3{
unreachable
}
define void@_SML_load3b8fa7741d09e0f0_DatatypeLayout(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@n,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@n,align 1
tail call void@_SML_loaddaa180c1799f3810_Bool(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*%a)#0
tail call void@_SML_load44ca35c4c731682b_Symbol(i8*%a)#0
tail call void@_SML_load1d614b123e80cc95_IDCalc_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb3b8fa7741d09e0f0_DatatypeLayout,i8*@_SML_ftab3b8fa7741d09e0f0_DatatypeLayout,i8*null)#0
ret void
}
define void@_SML_main3b8fa7741d09e0f0_DatatypeLayout()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@n,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@n,align 1
tail call void@_SML_maindaa180c1799f3810_Bool()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_mainc88dec21a8800496_RuntimeTypes_ppg()#2
tail call void@_SML_main44ca35c4c731682b_Symbol()#2
tail call void@_SML_main1d614b123e80cc95_IDCalc_ppg()#2
br label%d
}
define internal fastcc i8*@_SMLLN14DatatypeLayout8classifyE_45(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
%g=bitcast i8*%a to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%b,align 8
%i=getelementptr inbounds i8,i8*%a,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
%l=icmp eq i8*%k,null
br i1%l,label%m,label%N
m:
%n=getelementptr inbounds i8,i8*%a,i64 16
%o=bitcast i8*%n to i8***
%p=load i8**,i8***%o,align 8
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%c,align 8
%r=getelementptr inbounds i8*,i8**%p,i64 1
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%d,align 8
%t=call i8*@sml_alloc(i32 inreg 20)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177296,i32*%v,align 4
store i8*%t,i8**%e,align 8
%w=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%x=bitcast i8*%t to i8**
store i8*%w,i8**%x,align 8
%y=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%z=getelementptr inbounds i8,i8*%t,i64 8
%A=bitcast i8*%z to i8**
store i8*%y,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%t,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
%D=call i8*@sml_alloc(i32 inreg 20)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177296,i32*%F,align 4
%G=load i8*,i8**%e,align 8
%H=bitcast i8*%D to i8**
store i8*%G,i8**%H,align 8
%I=load i8*,i8**%d,align 8
%J=getelementptr inbounds i8,i8*%D,i64 8
%K=bitcast i8*%J to i8**
store i8*%I,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%D,i64 16
%M=bitcast i8*%L to i32*
store i32 3,i32*%M,align 4
ret i8*%D
N:
%O=bitcast i8*%k to i8**
%P=load i8*,i8**%O,align 8
store i8*%P,i8**%c,align 8
%Q=getelementptr inbounds i8,i8*%a,i64 16
%R=bitcast i8*%Q to i8***
%S=load i8**,i8***%R,align 8
%T=load i8*,i8**%S,align 8
store i8*%T,i8**%d,align 8
%U=getelementptr inbounds i8*,i8**%S,i64 1
%V=load i8*,i8**%U,align 8
store i8*%V,i8**%e,align 8
%W=call i8*@sml_alloc(i32 inreg 20)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177296,i32*%Y,align 4
store i8*%W,i8**%f,align 8
%Z=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aa=bitcast i8*%W to i8**
store i8*%Z,i8**%aa,align 8
%ab=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ac=getelementptr inbounds i8,i8*%W,i64 8
%ad=bitcast i8*%ac to i8**
store i8*%ab,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%W,i64 16
%af=bitcast i8*%ae to i32*
store i32 3,i32*%af,align 4
%ag=call i8*@sml_alloc(i32 inreg 20)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177296,i32*%ai,align 4
store i8*%ag,i8**%b,align 8
%aj=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%am=getelementptr inbounds i8,i8*%ag,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ag,i64 16
%ap=bitcast i8*%ao to i32*
store i32 3,i32*%ap,align 4
%aq=call i8*@sml_alloc(i32 inreg 20)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177296,i32*%as,align 4
%at=load i8*,i8**%d,align 8
%au=bitcast i8*%aq to i8**
store i8*%at,i8**%au,align 8
%av=load i8*,i8**%b,align 8
%aw=getelementptr inbounds i8,i8*%aq,i64 8
%ax=bitcast i8*%aw to i8**
store i8*%av,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%aq,i64 16
%az=bitcast i8*%ay to i32*
store i32 3,i32*%az,align 4
ret i8*%aq
}
define fastcc i8*@_SMLFN14DatatypeLayout14datatypeLayoutE(i8*inreg%a)#2 gc"smlsharp"{
m:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%c,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%a,%m]
%n=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%n)
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%l,i8**%b,align 8
%o=load atomic i32,i32*@sml_check_flag unordered,align 4
%p=icmp eq i32%o,0
br i1%p,label%r,label%q
q:
call void@sml_check(i32 inreg%o)
br label%r
r:
%s=call fastcc i8*@_SMLFN9SymbolEnv6foldriE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=call fastcc i8*%v(i8*inreg%x,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%z=getelementptr inbounds i8,i8*%y,i64 16
%A=bitcast i8*%z to i8*(i8*,i8*)**
%B=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%A,align 8
%C=bitcast i8*%y to i8**
%D=load i8*,i8**%C,align 8
%E=call fastcc i8*%B(i8*inreg%D,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@b,i64 0,i32 2)to i8*))
%F=getelementptr inbounds i8,i8*%E,i64 16
%G=bitcast i8*%F to i8*(i8*,i8*)**
%H=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%G,align 8
%I=bitcast i8*%E to i8**
%J=load i8*,i8**%I,align 8
%K=load i8*,i8**%b,align 8
%L=call fastcc i8*%H(i8*inreg%J,i8*inreg%K)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%n)
%M=bitcast i8*%L to i8**
%N=load i8*,i8**%M,align 8
%O=icmp eq i8*%N,null
br i1%O,label%P,label%bG
P:
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
%T=icmp eq i8*%S,null
br i1%T,label%U,label%ao
U:
%V=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%V,i8**%c,align 8
%W=call i8*@sml_alloc(i32 inreg 28)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177304,i32*%Y,align 4
store i8*%W,i8**%d,align 8
%Z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aa=bitcast i8*%W to i8**
store i8*%Z,i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%W,i64 8
%ac=bitcast i8*%ab to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[68x i8]}>,<{[4x i8],i32,[68x i8]}>*@k,i64 0,i32 2,i64 0),i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%W,i64 16
%ae=bitcast i8*%ad to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[19x i8]}>,<{[4x i8],i32,[19x i8]}>*@l,i64 0,i32 2,i64 0),i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%W,i64 24
%ag=bitcast i8*%af to i32*
store i32 7,i32*%ag,align 4
%ah=call i8*@sml_alloc(i32 inreg 60)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177336,i32*%aj,align 4
%ak=getelementptr inbounds i8,i8*%ah,i64 56
%al=bitcast i8*%ak to i32*
store i32 1,i32*%al,align 4
%am=load i8*,i8**%d,align 8
%an=bitcast i8*%ah to i8**
store i8*%am,i8**%an,align 8
call void@sml_raise(i8*inreg%ah)#1
unreachable
ao:
%ap=getelementptr inbounds i8,i8*%S,i64 8
%aq=bitcast i8*%ap to i8**
%ar=load i8*,i8**%aq,align 8
%as=icmp eq i8*%ar,null
br i1%as,label%at,label%hO
at:
store i8*null,i8**%c,align 8
%au=bitcast i8*%S to i8**
%av=load i8*,i8**%au,align 8
%aw=getelementptr inbounds i8,i8*%av,i64 8
%ax=bitcast i8*%aw to i8**
%ay=load i8*,i8**%ax,align 8
%az=call fastcc i8*@_SMLFN6IDCalc13propertyOfItyE(i8*inreg%ay)
%aA=icmp eq i8*%az,null
br i1%aA,label%bm,label%aB
aB:
%aC=bitcast i8*%az to i8**
%aD=load i8*,i8**%aC,align 8
%aE=bitcast i8*%aD to i32*
%aF=load i32,i32*%aE,align 4
%aG=icmp eq i32%aF,1
br i1%aG,label%aH,label%bm
aH:
%aI=getelementptr inbounds i8,i8*%aD,i64 8
%aJ=bitcast i8*%aI to i8**
%aK=load i8*,i8**%aJ,align 8
store i8*%aK,i8**%c,align 8
%aL=call i8*@sml_alloc(i32 inreg 12)#0
%aM=getelementptr inbounds i8,i8*%aL,i64 -4
%aN=bitcast i8*%aM to i32*
store i32 1342177288,i32*%aN,align 4
%aO=load i8*,i8**%c,align 8
%aP=bitcast i8*%aL to i8**
store i8*%aO,i8**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aL,i64 8
%aR=bitcast i8*%aQ to i32*
store i32 1,i32*%aR,align 4
%aS=icmp eq i8*%aL,null
br i1%aS,label%bm,label%aT
aT:
%aU=getelementptr inbounds i8,i8*%aO,i64 16
%aV=bitcast i8*%aU to i8**
%aW=load i8*,i8**%aV,align 8
%aX=icmp eq i8*%aW,null
br i1%aX,label%bm,label%aY
aY:
%aZ=bitcast i8*%aW to i32*
%a0=load i32,i32*%aZ,align 4
%a1=icmp eq i32%a0,0
br i1%a1,label%a2,label%bm
a2:
%a3=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%a4=getelementptr inbounds i8,i8*%a3,i64 8
%a5=bitcast i8*%a4 to i8**
%a6=load i8*,i8**%a5,align 8
store i8*%a6,i8**%c,align 8
%a7=getelementptr inbounds i8,i8*%a3,i64 16
%a8=bitcast i8*%a7 to i8**
%a9=load i8*,i8**%a8,align 8
store i8*%a9,i8**%d,align 8
%ba=call i8*@sml_alloc(i32 inreg 28)#0
%bb=getelementptr inbounds i8,i8*%ba,i64 -4
%bc=bitcast i8*%bb to i32*
store i32 1342177304,i32*%bc,align 4
%bd=bitcast i8*%ba to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@j,i64 0,i32 2)to i8*),i8**%bd,align 8
%be=load i8*,i8**%c,align 8
%bf=getelementptr inbounds i8,i8*%ba,i64 8
%bg=bitcast i8*%bf to i8**
store i8*%be,i8**%bg,align 8
%bh=load i8*,i8**%d,align 8
%bi=getelementptr inbounds i8,i8*%ba,i64 16
%bj=bitcast i8*%bi to i8**
store i8*%bh,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%ba,i64 24
%bl=bitcast i8*%bk to i32*
store i32 7,i32*%bl,align 4
ret i8*%ba
bm:
%bn=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%bo=getelementptr inbounds i8,i8*%bn,i64 8
%bp=bitcast i8*%bo to i8**
%bq=load i8*,i8**%bp,align 8
store i8*%bq,i8**%c,align 8
%br=getelementptr inbounds i8,i8*%bn,i64 16
%bs=bitcast i8*%br to i8**
%bt=load i8*,i8**%bs,align 8
store i8*%bt,i8**%d,align 8
%bu=call i8*@sml_alloc(i32 inreg 28)#0
%bv=getelementptr inbounds i8,i8*%bu,i64 -4
%bw=bitcast i8*%bv to i32*
store i32 1342177304,i32*%bw,align 4
%bx=bitcast i8*%bu to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@g,i64 0,i32 2)to i8*),i8**%bx,align 8
%by=load i8*,i8**%c,align 8
%bz=getelementptr inbounds i8,i8*%bu,i64 8
%bA=bitcast i8*%bz to i8**
store i8*%by,i8**%bA,align 8
%bB=load i8*,i8**%d,align 8
%bC=getelementptr inbounds i8,i8*%bu,i64 16
%bD=bitcast i8*%bC to i8**
store i8*%bB,i8**%bD,align 8
%bE=getelementptr inbounds i8,i8*%bu,i64 24
%bF=bitcast i8*%bE to i32*
store i32 7,i32*%bF,align 4
ret i8*%bu
bG:
store i8*%N,i8**%e,align 8
%bH=getelementptr inbounds i8,i8*%N,i64 8
%bI=bitcast i8*%bH to i8**
%bJ=load i8*,i8**%bI,align 8
%bK=icmp eq i8*%bJ,null
%bL=bitcast i8*%N to i8**
br i1%bK,label%bM,label%fk
bM:
%bN=getelementptr inbounds i8,i8*%L,i64 8
%bO=bitcast i8*%bN to i8**
%bP=load i8*,i8**%bO,align 8
%bQ=icmp eq i8*%bP,null
br i1%bQ,label%bR,label%cb
bR:
store i8*null,i8**%e,align 8
%bS=load i8*,i8**@_SMLZN12RuntimeTypes10contagPropE,align 8
%bT=getelementptr inbounds i8,i8*%bS,i64 8
%bU=bitcast i8*%bT to i8**
%bV=load i8*,i8**%bU,align 8
store i8*%bV,i8**%c,align 8
%bW=getelementptr inbounds i8,i8*%bS,i64 16
%bX=bitcast i8*%bW to i8**
%bY=load i8*,i8**%bX,align 8
store i8*%bY,i8**%d,align 8
%bZ=call i8*@sml_alloc(i32 inreg 28)#0
%b0=getelementptr inbounds i8,i8*%bZ,i64 -4
%b1=bitcast i8*%b0 to i32*
store i32 1342177304,i32*%b1,align 4
%b2=bitcast i8*%bZ to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@d,i64 0,i32 2)to i8*),i8**%b2,align 8
%b3=load i8*,i8**%c,align 8
%b4=getelementptr inbounds i8,i8*%bZ,i64 8
%b5=bitcast i8*%b4 to i8**
store i8*%b3,i8**%b5,align 8
%b6=load i8*,i8**%d,align 8
%b7=getelementptr inbounds i8,i8*%bZ,i64 16
%b8=bitcast i8*%b7 to i8**
store i8*%b6,i8**%b8,align 8
%b9=getelementptr inbounds i8,i8*%bZ,i64 24
%ca=bitcast i8*%b9 to i32*
store i32 7,i32*%ca,align 4
ret i8*%bZ
cb:
%cc=getelementptr inbounds i8,i8*%bP,i64 8
%cd=bitcast i8*%cc to i8**
%ce=load i8*,i8**%cd,align 8
%cf=icmp eq i8*%ce,null
br i1%cf,label%cg,label%dS
cg:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
%ch=bitcast i8*%bP to i8**
%ci=load i8*,i8**%ch,align 8
%cj=getelementptr inbounds i8,i8*%ci,i64 8
%ck=bitcast i8*%cj to i8**
%cl=load i8*,i8**%ck,align 8
%cm=call fastcc i8*@_SMLFN6IDCalc13propertyOfItyE(i8*inreg%cl)
%cn=icmp eq i8*%cm,null
br i1%cn,label%c3,label%co
co:
%cp=bitcast i8*%cm to i8**
%cq=load i8*,i8**%cp,align 8
%cr=bitcast i8*%cq to i32*
%cs=load i32,i32*%cr,align 4
%ct=icmp eq i32%cs,1
br i1%ct,label%cu,label%c3
cu:
%cv=getelementptr inbounds i8,i8*%cq,i64 8
%cw=bitcast i8*%cv to i8**
%cx=load i8*,i8**%cw,align 8
store i8*%cx,i8**%c,align 8
%cy=call i8*@sml_alloc(i32 inreg 12)#0
%cz=getelementptr inbounds i8,i8*%cy,i64 -4
%cA=bitcast i8*%cz to i32*
store i32 1342177288,i32*%cA,align 4
%cB=load i8*,i8**%c,align 8
%cC=bitcast i8*%cy to i8**
store i8*%cB,i8**%cC,align 8
%cD=getelementptr inbounds i8,i8*%cy,i64 8
%cE=bitcast i8*%cD to i32*
store i32 1,i32*%cE,align 4
%cF=icmp eq i8*%cy,null
br i1%cF,label%c3,label%cG
cG:
%cH=getelementptr inbounds i8,i8*%cB,i64 16
%cI=bitcast i8*%cH to i8**
%cJ=load i8*,i8**%cI,align 8
%cK=icmp eq i8*%cJ,null
br i1%cK,label%c3,label%cL
cL:
%cM=bitcast i8*%cJ to i32*
%cN=load i32,i32*%cM,align 4
%cO=icmp eq i32%cN,0
br i1%cO,label%cP,label%c3
cP:
%cQ=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
store i8*%cQ,i8**%d,align 8
%cR=call i8*@sml_alloc(i32 inreg 20)#0
%cS=getelementptr inbounds i8,i8*%cR,i64 -4
%cT=bitcast i8*%cS to i32*
store i32 1342177296,i32*%cT,align 4
%cU=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cV=bitcast i8*%cR to i8**
store i8*%cU,i8**%cV,align 8
%cW=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cX=getelementptr inbounds i8,i8*%cR,i64 8
%cY=bitcast i8*%cX to i8**
store i8*%cW,i8**%cY,align 8
%cZ=getelementptr inbounds i8,i8*%cR,i64 16
%c0=bitcast i8*%cZ to i32*
store i32 3,i32*%c0,align 4
%c1=call fastcc i32@_SMLFN12RuntimeTypes15canBeRegardedAsE(i8*inreg%cR)
%c2=call fastcc i32@_SMLFN4Bool3notE(i32 inreg%c1)
br label%c3
c3:
%c4=phi i32[1,%cu],[1,%cG],[%c2,%cP],[1,%cL],[1,%co],[1,%cg]
%c5=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
store i8*%c5,i8**%c,align 8
%c6=call i8*@sml_alloc(i32 inreg 12)#0
%c7=getelementptr inbounds i8,i8*%c6,i64 -4
%c8=bitcast i8*%c7 to i32*
store i32 1342177288,i32*%c8,align 4
store i8*%c6,i8**%d,align 8
%c9=getelementptr inbounds i8,i8*%c6,i64 4
%da=bitcast i8*%c9 to i32*
store i32 0,i32*%da,align 1
%db=bitcast i8*%c6 to i32*
store i32%c4,i32*%db,align 4
%dc=getelementptr inbounds i8,i8*%c6,i64 8
%dd=bitcast i8*%dc to i32*
store i32 0,i32*%dd,align 4
%de=call i8*@sml_alloc(i32 inreg 20)#0
%df=getelementptr inbounds i8,i8*%de,i64 -4
%dg=bitcast i8*%df to i32*
store i32 1342177296,i32*%dg,align 4
store i8*%de,i8**%e,align 8
%dh=bitcast i8*%de to i64*
store i64 0,i64*%dh,align 4
%di=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%dj=getelementptr inbounds i8,i8*%de,i64 8
%dk=bitcast i8*%dj to i8**
store i8*%di,i8**%dk,align 8
%dl=getelementptr inbounds i8,i8*%de,i64 16
%dm=bitcast i8*%dl to i32*
store i32 2,i32*%dm,align 4
%dn=call i8*@sml_alloc(i32 inreg 20)#0
%do=getelementptr inbounds i8,i8*%dn,i64 -4
%dp=bitcast i8*%do to i32*
store i32 1342177296,i32*%dp,align 4
store i8*%dn,i8**%f,align 8
%dq=getelementptr inbounds i8,i8*%dn,i64 4
%dr=bitcast i8*%dq to i32*
store i32 0,i32*%dr,align 1
%ds=bitcast i8*%dn to i32*
store i32 3,i32*%ds,align 4
%dt=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%du=getelementptr inbounds i8,i8*%dn,i64 8
%dv=bitcast i8*%du to i8**
store i8*%dt,i8**%dv,align 8
%dw=getelementptr inbounds i8,i8*%dn,i64 16
%dx=bitcast i8*%dw to i32*
store i32 2,i32*%dx,align 4
%dy=load i8*,i8**%c,align 8
%dz=getelementptr inbounds i8,i8*%dy,i64 8
%dA=bitcast i8*%dz to i8**
%dB=load i8*,i8**%dA,align 8
store i8*%dB,i8**%d,align 8
%dC=getelementptr inbounds i8,i8*%dy,i64 16
%dD=bitcast i8*%dC to i8**
%dE=load i8*,i8**%dD,align 8
store i8*%dE,i8**%c,align 8
%dF=call i8*@sml_alloc(i32 inreg 28)#0
%dG=getelementptr inbounds i8,i8*%dF,i64 -4
%dH=bitcast i8*%dG to i32*
store i32 1342177304,i32*%dH,align 4
%dI=load i8*,i8**%f,align 8
%dJ=bitcast i8*%dF to i8**
store i8*%dI,i8**%dJ,align 8
%dK=load i8*,i8**%d,align 8
%dL=getelementptr inbounds i8,i8*%dF,i64 8
%dM=bitcast i8*%dL to i8**
store i8*%dK,i8**%dM,align 8
%dN=load i8*,i8**%c,align 8
%dO=getelementptr inbounds i8,i8*%dF,i64 16
%dP=bitcast i8*%dO to i8**
store i8*%dN,i8**%dP,align 8
%dQ=getelementptr inbounds i8,i8*%dF,i64 24
%dR=bitcast i8*%dQ to i32*
store i32 7,i32*%dR,align 4
ret i8*%dF
dS:
%dT=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%dU=getelementptr inbounds i8,i8*%dT,i64 16
%dV=bitcast i8*%dU to i8*(i8*,i8*)**
%dW=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dV,align 8
%dX=bitcast i8*%dT to i8**
%dY=load i8*,i8**%dX,align 8
%dZ=load i8*,i8**@_SMLZN6Symbol14symbolToStringE,align 8
%d0=call fastcc i8*%dW(i8*inreg%dY,i8*inreg%dZ)
%d1=getelementptr inbounds i8,i8*%d0,i64 16
%d2=bitcast i8*%d1 to i8*(i8*,i8*)**
%d3=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%d2,align 8
%d4=bitcast i8*%d0 to i8**
%d5=load i8*,i8**%d4,align 8
store i8*%d5,i8**%d,align 8
%d6=call fastcc i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg 1,i32 inreg 8)
%d7=getelementptr inbounds i8,i8*%d6,i64 16
%d8=bitcast i8*%d7 to i8*(i8*,i8*)**
%d9=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%d8,align 8
%ea=bitcast i8*%d6 to i8**
%eb=load i8*,i8**%ea,align 8
%ec=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ed=call fastcc i8*%d9(i8*inreg%eb,i8*inreg%ec)
%ee=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ef=call fastcc i8*%d3(i8*inreg%ee,i8*inreg%ed)
store i8*%ef,i8**%c,align 8
%eg=bitcast i8**%e to i8***
%eh=load i8**,i8***%eg,align 8
store i8*null,i8**%e,align 8
%ei=load i8*,i8**%eh,align 8
%ej=call fastcc i8*@_SMLFN6Symbol14symbolToStringE(i8*inreg%ei)
store i8*%ej,i8**%d,align 8
%ek=call i8*@sml_alloc(i32 inreg 20)#0
%el=getelementptr inbounds i8,i8*%ek,i64 -4
%em=bitcast i8*%el to i32*
store i32 1342177296,i32*%em,align 4
store i8*%ek,i8**%e,align 8
%en=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%eo=bitcast i8*%ek to i8**
store i8*%en,i8**%eo,align 8
%ep=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%eq=getelementptr inbounds i8,i8*%ek,i64 8
%er=bitcast i8*%eq to i8**
store i8*%ep,i8**%er,align 8
%es=getelementptr inbounds i8,i8*%ek,i64 16
%et=bitcast i8*%es to i32*
store i32 3,i32*%et,align 4
%eu=call i8*@sml_alloc(i32 inreg 20)#0
%ev=getelementptr inbounds i8,i8*%eu,i64 -4
%ew=bitcast i8*%ev to i32*
store i32 1342177296,i32*%ew,align 4
store i8*%eu,i8**%c,align 8
%ex=bitcast i8*%eu to i64*
store i64 0,i64*%ex,align 4
%ey=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ez=getelementptr inbounds i8,i8*%eu,i64 8
%eA=bitcast i8*%ez to i8**
store i8*%ey,i8**%eA,align 8
%eB=getelementptr inbounds i8,i8*%eu,i64 16
%eC=bitcast i8*%eB to i32*
store i32 2,i32*%eC,align 4
%eD=call i8*@sml_alloc(i32 inreg 20)#0
%eE=getelementptr inbounds i8,i8*%eD,i64 -4
%eF=bitcast i8*%eE to i32*
store i32 1342177296,i32*%eF,align 4
store i8*%eD,i8**%d,align 8
%eG=getelementptr inbounds i8,i8*%eD,i64 4
%eH=bitcast i8*%eG to i32*
store i32 0,i32*%eH,align 1
%eI=bitcast i8*%eD to i32*
store i32 5,i32*%eI,align 4
%eJ=load i8*,i8**%c,align 8
%eK=getelementptr inbounds i8,i8*%eD,i64 8
%eL=bitcast i8*%eK to i8**
store i8*%eJ,i8**%eL,align 8
%eM=getelementptr inbounds i8,i8*%eD,i64 16
%eN=bitcast i8*%eM to i32*
store i32 2,i32*%eN,align 4
%eO=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
store i8*%eO,i8**%c,align 8
%eP=call i8*@sml_alloc(i32 inreg 20)#0
%eQ=getelementptr inbounds i8,i8*%eP,i64 -4
%eR=bitcast i8*%eQ to i32*
store i32 1342177296,i32*%eR,align 4
store i8*%eP,i8**%e,align 8
%eS=getelementptr inbounds i8,i8*%eP,i64 4
%eT=bitcast i8*%eS to i32*
store i32 0,i32*%eT,align 1
%eU=bitcast i8*%eP to i32*
store i32 3,i32*%eU,align 4
%eV=load i8*,i8**%d,align 8
%eW=getelementptr inbounds i8,i8*%eP,i64 8
%eX=bitcast i8*%eW to i8**
store i8*%eV,i8**%eX,align 8
%eY=getelementptr inbounds i8,i8*%eP,i64 16
%eZ=bitcast i8*%eY to i32*
store i32 2,i32*%eZ,align 4
%e0=load i8*,i8**%c,align 8
%e1=getelementptr inbounds i8,i8*%e0,i64 8
%e2=bitcast i8*%e1 to i8**
%e3=load i8*,i8**%e2,align 8
store i8*%e3,i8**%d,align 8
%e4=getelementptr inbounds i8,i8*%e0,i64 16
%e5=bitcast i8*%e4 to i8**
%e6=load i8*,i8**%e5,align 8
store i8*%e6,i8**%c,align 8
%e7=call i8*@sml_alloc(i32 inreg 28)#0
%e8=getelementptr inbounds i8,i8*%e7,i64 -4
%e9=bitcast i8*%e8 to i32*
store i32 1342177304,i32*%e9,align 4
%fa=load i8*,i8**%e,align 8
%fb=bitcast i8*%e7 to i8**
store i8*%fa,i8**%fb,align 8
%fc=load i8*,i8**%d,align 8
%fd=getelementptr inbounds i8,i8*%e7,i64 8
%fe=bitcast i8*%fd to i8**
store i8*%fc,i8**%fe,align 8
%ff=load i8*,i8**%c,align 8
%fg=getelementptr inbounds i8,i8*%e7,i64 16
%fh=bitcast i8*%fg to i8**
store i8*%ff,i8**%fh,align 8
%fi=getelementptr inbounds i8,i8*%e7,i64 24
%fj=bitcast i8*%fi to i32*
store i32 7,i32*%fj,align 4
ret i8*%e7
fk:
%fl=getelementptr inbounds i8,i8*%bJ,i64 8
%fm=bitcast i8*%fl to i8**
%fn=load i8*,i8**%fm,align 8
%fo=icmp eq i8*%fn,null
br i1%fo,label%fp,label%gm
fp:
%fq=getelementptr inbounds i8,i8*%L,i64 8
%fr=bitcast i8*%fq to i8**
%fs=load i8*,i8**%fr,align 8
%ft=icmp eq i8*%fs,null
br i1%ft,label%fu,label%gl
fu:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
%fv=load i8*,i8**%bL,align 8
%fw=call fastcc i8*@_SMLFN6Symbol14symbolToStringE(i8*inreg%fv)
store i8*%fw,i8**%c,align 8
%fx=call i8*@sml_alloc(i32 inreg 12)#0
%fy=getelementptr inbounds i8,i8*%fx,i64 -4
%fz=bitcast i8*%fy to i32*
store i32 1342177288,i32*%fz,align 4
store i8*%fx,i8**%d,align 8
%fA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fB=bitcast i8*%fx to i8**
store i8*%fA,i8**%fB,align 8
%fC=getelementptr inbounds i8,i8*%fx,i64 8
%fD=bitcast i8*%fC to i32*
store i32 1,i32*%fD,align 4
%fE=call i8*@sml_alloc(i32 inreg 20)#0
%fF=getelementptr inbounds i8,i8*%fE,i64 -4
%fG=bitcast i8*%fF to i32*
store i32 1342177296,i32*%fG,align 4
store i8*%fE,i8**%e,align 8
%fH=getelementptr inbounds i8,i8*%fE,i64 4
%fI=bitcast i8*%fH to i32*
store i32 0,i32*%fI,align 1
%fJ=bitcast i8*%fE to i32*
store i32 1,i32*%fJ,align 4
%fK=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fL=getelementptr inbounds i8,i8*%fE,i64 8
%fM=bitcast i8*%fL to i8**
store i8*%fK,i8**%fM,align 8
%fN=getelementptr inbounds i8,i8*%fE,i64 16
%fO=bitcast i8*%fN to i32*
store i32 2,i32*%fO,align 4
%fP=load i8*,i8**@_SMLZN12RuntimeTypes10contagPropE,align 8
store i8*%fP,i8**%c,align 8
%fQ=call i8*@sml_alloc(i32 inreg 20)#0
%fR=getelementptr inbounds i8,i8*%fQ,i64 -4
%fS=bitcast i8*%fR to i32*
store i32 1342177296,i32*%fS,align 4
store i8*%fQ,i8**%f,align 8
%fT=getelementptr inbounds i8,i8*%fQ,i64 4
%fU=bitcast i8*%fT to i32*
store i32 0,i32*%fU,align 1
%fV=bitcast i8*%fQ to i32*
store i32 3,i32*%fV,align 4
%fW=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fX=getelementptr inbounds i8,i8*%fQ,i64 8
%fY=bitcast i8*%fX to i8**
store i8*%fW,i8**%fY,align 8
%fZ=getelementptr inbounds i8,i8*%fQ,i64 16
%f0=bitcast i8*%fZ to i32*
store i32 2,i32*%f0,align 4
%f1=load i8*,i8**%c,align 8
%f2=getelementptr inbounds i8,i8*%f1,i64 8
%f3=bitcast i8*%f2 to i8**
%f4=load i8*,i8**%f3,align 8
store i8*%f4,i8**%d,align 8
%f5=getelementptr inbounds i8,i8*%f1,i64 16
%f6=bitcast i8*%f5 to i8**
%f7=load i8*,i8**%f6,align 8
store i8*%f7,i8**%c,align 8
%f8=call i8*@sml_alloc(i32 inreg 28)#0
%f9=getelementptr inbounds i8,i8*%f8,i64 -4
%ga=bitcast i8*%f9 to i32*
store i32 1342177304,i32*%ga,align 4
%gb=load i8*,i8**%f,align 8
%gc=bitcast i8*%f8 to i8**
store i8*%gb,i8**%gc,align 8
%gd=load i8*,i8**%d,align 8
%ge=getelementptr inbounds i8,i8*%f8,i64 8
%gf=bitcast i8*%ge to i8**
store i8*%gd,i8**%gf,align 8
%gg=load i8*,i8**%c,align 8
%gh=getelementptr inbounds i8,i8*%f8,i64 16
%gi=bitcast i8*%gh to i8**
store i8*%gg,i8**%gi,align 8
%gj=getelementptr inbounds i8,i8*%f8,i64 24
%gk=bitcast i8*%gj to i32*
store i32 7,i32*%gk,align 4
ret i8*%f8
gl:
store i8*null,i8**%e,align 8
br label%hO
gm:
store i8*null,i8**%e,align 8
%gn=getelementptr inbounds i8,i8*%L,i64 8
%go=bitcast i8*%gn to i8**
%gp=load i8*,i8**%go,align 8
%gq=icmp eq i8*%gp,null
br i1%gq,label%gr,label%hO
gr:
%gs=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%gt=getelementptr inbounds i8,i8*%gs,i64 16
%gu=bitcast i8*%gt to i8*(i8*,i8*)**
%gv=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gu,align 8
%gw=bitcast i8*%gs to i8**
%gx=load i8*,i8**%gw,align 8
%gy=load i8*,i8**@_SMLZN6Symbol14symbolToStringE,align 8
%gz=call fastcc i8*%gv(i8*inreg%gx,i8*inreg%gy)
%gA=getelementptr inbounds i8,i8*%gz,i64 16
%gB=bitcast i8*%gA to i8*(i8*,i8*)**
%gC=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gB,align 8
%gD=bitcast i8*%gz to i8**
%gE=load i8*,i8**%gD,align 8
store i8*%gE,i8**%d,align 8
%gF=call fastcc i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg 1,i32 inreg 8)
%gG=getelementptr inbounds i8,i8*%gF,i64 16
%gH=bitcast i8*%gG to i8*(i8*,i8*)**
%gI=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gH,align 8
%gJ=bitcast i8*%gF to i8**
%gK=load i8*,i8**%gJ,align 8
%gL=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gM=call fastcc i8*%gI(i8*inreg%gK,i8*inreg%gL)
%gN=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%gO=call fastcc i8*%gC(i8*inreg%gN,i8*inreg%gM)
store i8*%gO,i8**%c,align 8
%gP=call i8*@sml_alloc(i32 inreg 12)#0
%gQ=getelementptr inbounds i8,i8*%gP,i64 -4
%gR=bitcast i8*%gQ to i32*
store i32 1342177288,i32*%gR,align 4
store i8*%gP,i8**%d,align 8
%gS=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gT=bitcast i8*%gP to i8**
store i8*%gS,i8**%gT,align 8
%gU=getelementptr inbounds i8,i8*%gP,i64 8
%gV=bitcast i8*%gU to i32*
store i32 1,i32*%gV,align 4
%gW=call i8*@sml_alloc(i32 inreg 20)#0
%gX=getelementptr inbounds i8,i8*%gW,i64 -4
%gY=bitcast i8*%gX to i32*
store i32 1342177296,i32*%gY,align 4
store i8*%gW,i8**%c,align 8
%gZ=getelementptr inbounds i8,i8*%gW,i64 4
%g0=bitcast i8*%gZ to i32*
store i32 0,i32*%g0,align 1
%g1=bitcast i8*%gW to i32*
store i32 2,i32*%g1,align 4
%g2=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%g3=getelementptr inbounds i8,i8*%gW,i64 8
%g4=bitcast i8*%g3 to i8**
store i8*%g2,i8**%g4,align 8
%g5=getelementptr inbounds i8,i8*%gW,i64 16
%g6=bitcast i8*%g5 to i32*
store i32 2,i32*%g6,align 4
%g7=call i8*@sml_alloc(i32 inreg 20)#0
%g8=getelementptr inbounds i8,i8*%g7,i64 -4
%g9=bitcast i8*%g8 to i32*
store i32 1342177296,i32*%g9,align 4
store i8*%g7,i8**%d,align 8
%ha=getelementptr inbounds i8,i8*%g7,i64 4
%hb=bitcast i8*%ha to i32*
store i32 0,i32*%hb,align 1
%hc=bitcast i8*%g7 to i32*
store i32 5,i32*%hc,align 4
%hd=load i8*,i8**%c,align 8
%he=getelementptr inbounds i8,i8*%g7,i64 8
%hf=bitcast i8*%he to i8**
store i8*%hd,i8**%hf,align 8
%hg=getelementptr inbounds i8,i8*%g7,i64 16
%hh=bitcast i8*%hg to i32*
store i32 2,i32*%hh,align 4
%hi=load i8*,i8**@_SMLZN12RuntimeTypes10contagPropE,align 8
store i8*%hi,i8**%c,align 8
%hj=call i8*@sml_alloc(i32 inreg 20)#0
%hk=getelementptr inbounds i8,i8*%hj,i64 -4
%hl=bitcast i8*%hk to i32*
store i32 1342177296,i32*%hl,align 4
store i8*%hj,i8**%e,align 8
%hm=getelementptr inbounds i8,i8*%hj,i64 4
%hn=bitcast i8*%hm to i32*
store i32 0,i32*%hn,align 1
%ho=bitcast i8*%hj to i32*
store i32 3,i32*%ho,align 4
%hp=load i8*,i8**%d,align 8
%hq=getelementptr inbounds i8,i8*%hj,i64 8
%hr=bitcast i8*%hq to i8**
store i8*%hp,i8**%hr,align 8
%hs=getelementptr inbounds i8,i8*%hj,i64 16
%ht=bitcast i8*%hs to i32*
store i32 2,i32*%ht,align 4
%hu=load i8*,i8**%c,align 8
%hv=getelementptr inbounds i8,i8*%hu,i64 8
%hw=bitcast i8*%hv to i8**
%hx=load i8*,i8**%hw,align 8
store i8*%hx,i8**%d,align 8
%hy=getelementptr inbounds i8,i8*%hu,i64 16
%hz=bitcast i8*%hy to i8**
%hA=load i8*,i8**%hz,align 8
store i8*%hA,i8**%c,align 8
%hB=call i8*@sml_alloc(i32 inreg 28)#0
%hC=getelementptr inbounds i8,i8*%hB,i64 -4
%hD=bitcast i8*%hC to i32*
store i32 1342177304,i32*%hD,align 4
%hE=load i8*,i8**%e,align 8
%hF=bitcast i8*%hB to i8**
store i8*%hE,i8**%hF,align 8
%hG=load i8*,i8**%d,align 8
%hH=getelementptr inbounds i8,i8*%hB,i64 8
%hI=bitcast i8*%hH to i8**
store i8*%hG,i8**%hI,align 8
%hJ=load i8*,i8**%c,align 8
%hK=getelementptr inbounds i8,i8*%hB,i64 16
%hL=bitcast i8*%hK to i8**
store i8*%hJ,i8**%hL,align 8
%hM=getelementptr inbounds i8,i8*%hB,i64 24
%hN=bitcast i8*%hM to i32*
store i32 7,i32*%hN,align 4
ret i8*%hB
hO:
%hP=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%hQ=getelementptr inbounds i8,i8*%hP,i64 16
%hR=bitcast i8*%hQ to i8*(i8*,i8*)**
%hS=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hR,align 8
%hT=bitcast i8*%hP to i8**
%hU=load i8*,i8**%hT,align 8
%hV=load i8*,i8**@_SMLZN6Symbol14symbolToStringE,align 8
%hW=call fastcc i8*%hS(i8*inreg%hU,i8*inreg%hV)
%hX=getelementptr inbounds i8,i8*%hW,i64 16
%hY=bitcast i8*%hX to i8*(i8*,i8*)**
%hZ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hY,align 8
%h0=bitcast i8*%hW to i8**
%h1=load i8*,i8**%h0,align 8
store i8*%h1,i8**%d,align 8
%h2=call fastcc i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg 1,i32 inreg 8)
%h3=getelementptr inbounds i8,i8*%h2,i64 16
%h4=bitcast i8*%h3 to i8*(i8*,i8*)**
%h5=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%h4,align 8
%h6=bitcast i8*%h2 to i8**
%h7=load i8*,i8**%h6,align 8
%h8=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%h9=call fastcc i8*%h5(i8*inreg%h7,i8*inreg%h8)
%ia=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ib=call fastcc i8*%hZ(i8*inreg%ia,i8*inreg%h9)
store i8*%ib,i8**%c,align 8
%ic=call i8*@sml_alloc(i32 inreg 12)#0
%id=getelementptr inbounds i8,i8*%ic,i64 -4
%ie=bitcast i8*%id to i32*
store i32 1342177288,i32*%ie,align 4
store i8*%ic,i8**%d,align 8
%if=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ig=bitcast i8*%ic to i8**
store i8*%if,i8**%ig,align 8
%ih=getelementptr inbounds i8,i8*%ic,i64 8
%ii=bitcast i8*%ih to i32*
store i32 1,i32*%ii,align 4
%ij=call i8*@sml_alloc(i32 inreg 20)#0
%ik=getelementptr inbounds i8,i8*%ij,i64 -4
%il=bitcast i8*%ik to i32*
store i32 1342177296,i32*%il,align 4
store i8*%ij,i8**%c,align 8
%im=getelementptr inbounds i8,i8*%ij,i64 4
%in=bitcast i8*%im to i32*
store i32 0,i32*%in,align 1
%io=bitcast i8*%ij to i32*
store i32 1,i32*%io,align 4
%ip=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%iq=getelementptr inbounds i8,i8*%ij,i64 8
%ir=bitcast i8*%iq to i8**
store i8*%ip,i8**%ir,align 8
%is=getelementptr inbounds i8,i8*%ij,i64 16
%it=bitcast i8*%is to i32*
store i32 2,i32*%it,align 4
%iu=call i8*@sml_alloc(i32 inreg 20)#0
%iv=getelementptr inbounds i8,i8*%iu,i64 -4
%iw=bitcast i8*%iv to i32*
store i32 1342177296,i32*%iw,align 4
store i8*%iu,i8**%d,align 8
%ix=getelementptr inbounds i8,i8*%iu,i64 4
%iy=bitcast i8*%ix to i32*
store i32 0,i32*%iy,align 1
%iz=bitcast i8*%iu to i32*
store i32 5,i32*%iz,align 4
%iA=load i8*,i8**%c,align 8
%iB=getelementptr inbounds i8,i8*%iu,i64 8
%iC=bitcast i8*%iB to i8**
store i8*%iA,i8**%iC,align 8
%iD=getelementptr inbounds i8,i8*%iu,i64 16
%iE=bitcast i8*%iD to i32*
store i32 2,i32*%iE,align 4
%iF=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
store i8*%iF,i8**%c,align 8
%iG=call i8*@sml_alloc(i32 inreg 20)#0
%iH=getelementptr inbounds i8,i8*%iG,i64 -4
%iI=bitcast i8*%iH to i32*
store i32 1342177296,i32*%iI,align 4
store i8*%iG,i8**%e,align 8
%iJ=getelementptr inbounds i8,i8*%iG,i64 4
%iK=bitcast i8*%iJ to i32*
store i32 0,i32*%iK,align 1
%iL=bitcast i8*%iG to i32*
store i32 3,i32*%iL,align 4
%iM=load i8*,i8**%d,align 8
%iN=getelementptr inbounds i8,i8*%iG,i64 8
%iO=bitcast i8*%iN to i8**
store i8*%iM,i8**%iO,align 8
%iP=getelementptr inbounds i8,i8*%iG,i64 16
%iQ=bitcast i8*%iP to i32*
store i32 2,i32*%iQ,align 4
%iR=load i8*,i8**%c,align 8
%iS=getelementptr inbounds i8,i8*%iR,i64 8
%iT=bitcast i8*%iS to i8**
%iU=load i8*,i8**%iT,align 8
store i8*%iU,i8**%d,align 8
%iV=getelementptr inbounds i8,i8*%iR,i64 16
%iW=bitcast i8*%iV to i8**
%iX=load i8*,i8**%iW,align 8
store i8*%iX,i8**%c,align 8
%iY=call i8*@sml_alloc(i32 inreg 28)#0
%iZ=getelementptr inbounds i8,i8*%iY,i64 -4
%i0=bitcast i8*%iZ to i32*
store i32 1342177304,i32*%i0,align 4
%i1=load i8*,i8**%e,align 8
%i2=bitcast i8*%iY to i8**
store i8*%i1,i8**%i2,align 8
%i3=load i8*,i8**%d,align 8
%i4=getelementptr inbounds i8,i8*%iY,i64 8
%i5=bitcast i8*%i4 to i8**
store i8*%i3,i8**%i5,align 8
%i6=load i8*,i8**%c,align 8
%i7=getelementptr inbounds i8,i8*%iY,i64 16
%i8=bitcast i8*%i7 to i8**
store i8*%i6,i8**%i8,align 8
%i9=getelementptr inbounds i8,i8*%iY,i64 24
%ja=bitcast i8*%i9 to i32*
store i32 7,i32*%ja,align 4
ret i8*%iY
}
define internal fastcc i8*@_SMLLN14DatatypeLayout8classifyE_62(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLN14DatatypeLayout8classifyE_45(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN14DatatypeLayout14datatypeLayoutE_64(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN14DatatypeLayout14datatypeLayoutE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
