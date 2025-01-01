@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN12RuntimeTypes10contagPropE=external local_unnamed_addr global i8*
@_SMLZN12RuntimeTypes10recordPropE=external local_unnamed_addr global i8*
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZN6Symbol14symbolToStringE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN14DatatypeLayout14datatypeLayoutE_45 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14DatatypeLayout14datatypeLayoutE_60 to void(...)*),i32 -2147483647}>,align 8
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
@m=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN14DatatypeLayout14datatypeLayoutE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14DatatypeLayout14datatypeLayoutE_61 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN14DatatypeLayout14datatypeLayoutE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@m,i64 0,i32 2)to i8*)
@_SML_ftab90c0803643f1cb28_DatatypeLayout=external global i8
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
declare void@_SML_main89b8631430c545af_Symbol()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maindd7ac0235f3a2d21_IDCalc_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loaddaa180c1799f3810_Bool(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loadc88dec21a8800496_RuntimeTypes_ppg(i8*)local_unnamed_addr
declare void@_SML_load89b8631430c545af_Symbol(i8*)local_unnamed_addr
declare void@_SML_loaddd7ac0235f3a2d21_IDCalc_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb90c0803643f1cb28_DatatypeLayout()#3{
unreachable
}
define void@_SML_load90c0803643f1cb28_DatatypeLayout(i8*%a)local_unnamed_addr#0{
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
tail call void@_SML_load89b8631430c545af_Symbol(i8*%a)#0
tail call void@_SML_loaddd7ac0235f3a2d21_IDCalc_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb90c0803643f1cb28_DatatypeLayout,i8*@_SML_ftab90c0803643f1cb28_DatatypeLayout,i8*null)#0
ret void
}
define void@_SML_main90c0803643f1cb28_DatatypeLayout()local_unnamed_addr#2 gc"smlsharp"{
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
tail call void@_SML_main89b8631430c545af_Symbol()#2
tail call void@_SML_maindd7ac0235f3a2d21_IDCalc_ppg()#2
br label%d
}
define internal fastcc i8*@_SMLLLN14DatatypeLayout14datatypeLayoutE_45(i8*inreg%a)#4 gc"smlsharp"{
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
br i1%l,label%m,label%P
m:
%n=getelementptr inbounds i8,i8*%a,i64 16
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
%q=bitcast i8*%p to i8**
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%c,align 8
%s=getelementptr inbounds i8,i8*%p,i64 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%d,align 8
%v=call i8*@sml_alloc(i32 inreg 20)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177296,i32*%x,align 4
store i8*%v,i8**%e,align 8
%y=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%B=getelementptr inbounds i8,i8*%v,i64 8
%C=bitcast i8*%B to i8**
store i8*%A,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%v,i64 16
%E=bitcast i8*%D to i32*
store i32 3,i32*%E,align 4
%F=call i8*@sml_alloc(i32 inreg 20)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177296,i32*%H,align 4
%I=load i8*,i8**%e,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=load i8*,i8**%d,align 8
%L=getelementptr inbounds i8,i8*%F,i64 8
%M=bitcast i8*%L to i8**
store i8*%K,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%F,i64 16
%O=bitcast i8*%N to i32*
store i32 3,i32*%O,align 4
ret i8*%F
P:
%Q=bitcast i8*%k to i8**
%R=load i8*,i8**%Q,align 8
store i8*%R,i8**%c,align 8
%S=getelementptr inbounds i8,i8*%a,i64 16
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%d,align 8
%X=getelementptr inbounds i8,i8*%U,i64 8
%Y=bitcast i8*%X to i8**
%Z=load i8*,i8**%Y,align 8
store i8*%Z,i8**%e,align 8
%aa=call i8*@sml_alloc(i32 inreg 20)#0
%ab=getelementptr inbounds i8,i8*%aa,i64 -4
%ac=bitcast i8*%ab to i32*
store i32 1342177296,i32*%ac,align 4
store i8*%aa,i8**%f,align 8
%ad=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ae=bitcast i8*%aa to i8**
store i8*%ad,i8**%ae,align 8
%af=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ag=getelementptr inbounds i8,i8*%aa,i64 8
%ah=bitcast i8*%ag to i8**
store i8*%af,i8**%ah,align 8
%ai=getelementptr inbounds i8,i8*%aa,i64 16
%aj=bitcast i8*%ai to i32*
store i32 3,i32*%aj,align 4
%ak=call i8*@sml_alloc(i32 inreg 20)#0
%al=getelementptr inbounds i8,i8*%ak,i64 -4
%am=bitcast i8*%al to i32*
store i32 1342177296,i32*%am,align 4
store i8*%ak,i8**%b,align 8
%an=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ao=bitcast i8*%ak to i8**
store i8*%an,i8**%ao,align 8
%ap=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aq=getelementptr inbounds i8,i8*%ak,i64 8
%ar=bitcast i8*%aq to i8**
store i8*%ap,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%ak,i64 16
%at=bitcast i8*%as to i32*
store i32 3,i32*%at,align 4
%au=call i8*@sml_alloc(i32 inreg 20)#0
%av=getelementptr inbounds i8,i8*%au,i64 -4
%aw=bitcast i8*%av to i32*
store i32 1342177296,i32*%aw,align 4
%ax=load i8*,i8**%d,align 8
%ay=bitcast i8*%au to i8**
store i8*%ax,i8**%ay,align 8
%az=load i8*,i8**%b,align 8
%aA=getelementptr inbounds i8,i8*%au,i64 8
%aB=bitcast i8*%aA to i8**
store i8*%az,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%au,i64 16
%aD=bitcast i8*%aC to i32*
store i32 3,i32*%aD,align 4
ret i8*%au
}
define fastcc i8*@_SMLFN14DatatypeLayout14datatypeLayoutE(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i8*@_SMLFN9SymbolEnv6foldriE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*)**
%l=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
%o=call fastcc i8*%l(i8*inreg%n,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%p=getelementptr inbounds i8,i8*%o,i64 16
%q=bitcast i8*%p to i8*(i8*,i8*)**
%r=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%q,align 8
%s=bitcast i8*%o to i8**
%t=load i8*,i8**%s,align 8
%u=call fastcc i8*%r(i8*inreg%t,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@b,i64 0,i32 2)to i8*))
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
%A=load i8*,i8**%c,align 8
%B=call fastcc i8*%x(i8*inreg%z,i8*inreg%A)
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
%E=icmp eq i8*%D,null
br i1%E,label%F,label%bw
F:
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to i8**
%I=load i8*,i8**%H,align 8
%J=icmp eq i8*%I,null
br i1%J,label%K,label%ae
K:
store i8*null,i8**%c,align 8
%L=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%L,i8**%b,align 8
%M=call i8*@sml_alloc(i32 inreg 28)#0
%N=getelementptr inbounds i8,i8*%M,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177304,i32*%O,align 4
store i8*%M,i8**%c,align 8
%P=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%Q=bitcast i8*%M to i8**
store i8*%P,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%M,i64 8
%S=bitcast i8*%R to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[68x i8]}>,<{[4x i8],i32,[68x i8]}>*@k,i64 0,i32 2,i64 0),i8**%S,align 8
%T=getelementptr inbounds i8,i8*%M,i64 16
%U=bitcast i8*%T to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[19x i8]}>,<{[4x i8],i32,[19x i8]}>*@l,i64 0,i32 2,i64 0),i8**%U,align 8
%V=getelementptr inbounds i8,i8*%M,i64 24
%W=bitcast i8*%V to i32*
store i32 7,i32*%W,align 4
%X=call i8*@sml_alloc(i32 inreg 60)#0
%Y=getelementptr inbounds i8,i8*%X,i64 -4
%Z=bitcast i8*%Y to i32*
store i32 1342177336,i32*%Z,align 4
%aa=getelementptr inbounds i8,i8*%X,i64 56
%ab=bitcast i8*%aa to i32*
store i32 1,i32*%ab,align 4
%ac=load i8*,i8**%c,align 8
%ad=bitcast i8*%X to i8**
store i8*%ac,i8**%ad,align 8
call void@sml_raise(i8*inreg%X)#1
unreachable
ae:
%af=getelementptr inbounds i8,i8*%I,i64 8
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
%ai=icmp eq i8*%ah,null
br i1%ai,label%aj,label%hA
aj:
%ak=bitcast i8*%I to i8**
%al=load i8*,i8**%ak,align 8
%am=getelementptr inbounds i8,i8*%al,i64 8
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
store i8*null,i8**%c,align 8
%ap=call fastcc i8*@_SMLFN6IDCalc13propertyOfItyE(i8*inreg%ao)
%aq=icmp eq i8*%ap,null
br i1%aq,label%bc,label%ar
ar:
%as=bitcast i8*%ap to i8**
%at=load i8*,i8**%as,align 8
%au=bitcast i8*%at to i32*
%av=load i32,i32*%au,align 4
%aw=icmp eq i32%av,1
br i1%aw,label%ax,label%bc
ax:
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to i8**
%aA=load i8*,i8**%az,align 8
store i8*%aA,i8**%b,align 8
%aB=call i8*@sml_alloc(i32 inreg 12)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32 1342177288,i32*%aD,align 4
%aE=load i8*,i8**%b,align 8
%aF=bitcast i8*%aB to i8**
store i8*%aE,i8**%aF,align 8
%aG=getelementptr inbounds i8,i8*%aB,i64 8
%aH=bitcast i8*%aG to i32*
store i32 1,i32*%aH,align 4
%aI=icmp eq i8*%aB,null
br i1%aI,label%bc,label%aJ
aJ:
%aK=getelementptr inbounds i8,i8*%aE,i64 16
%aL=bitcast i8*%aK to i8**
%aM=load i8*,i8**%aL,align 8
%aN=icmp eq i8*%aM,null
br i1%aN,label%bc,label%aO
aO:
%aP=bitcast i8*%aM to i32*
%aQ=load i32,i32*%aP,align 4
%aR=icmp eq i32%aQ,0
br i1%aR,label%aS,label%bc
aS:
%aT=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%aU=getelementptr inbounds i8,i8*%aT,i64 8
%aV=bitcast i8*%aU to i8**
%aW=load i8*,i8**%aV,align 8
store i8*%aW,i8**%b,align 8
%aX=getelementptr inbounds i8,i8*%aT,i64 16
%aY=bitcast i8*%aX to i8**
%aZ=load i8*,i8**%aY,align 8
store i8*%aZ,i8**%c,align 8
%a0=call i8*@sml_alloc(i32 inreg 28)#0
%a1=getelementptr inbounds i8,i8*%a0,i64 -4
%a2=bitcast i8*%a1 to i32*
store i32 1342177304,i32*%a2,align 4
%a3=bitcast i8*%a0 to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@j,i64 0,i32 2)to i8*),i8**%a3,align 8
%a4=load i8*,i8**%b,align 8
%a5=getelementptr inbounds i8,i8*%a0,i64 8
%a6=bitcast i8*%a5 to i8**
store i8*%a4,i8**%a6,align 8
%a7=load i8*,i8**%c,align 8
%a8=getelementptr inbounds i8,i8*%a0,i64 16
%a9=bitcast i8*%a8 to i8**
store i8*%a7,i8**%a9,align 8
%ba=getelementptr inbounds i8,i8*%a0,i64 24
%bb=bitcast i8*%ba to i32*
store i32 7,i32*%bb,align 4
ret i8*%a0
bc:
%bd=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%be=getelementptr inbounds i8,i8*%bd,i64 8
%bf=bitcast i8*%be to i8**
%bg=load i8*,i8**%bf,align 8
store i8*%bg,i8**%b,align 8
%bh=getelementptr inbounds i8,i8*%bd,i64 16
%bi=bitcast i8*%bh to i8**
%bj=load i8*,i8**%bi,align 8
store i8*%bj,i8**%c,align 8
%bk=call i8*@sml_alloc(i32 inreg 28)#0
%bl=getelementptr inbounds i8,i8*%bk,i64 -4
%bm=bitcast i8*%bl to i32*
store i32 1342177304,i32*%bm,align 4
%bn=bitcast i8*%bk to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@g,i64 0,i32 2)to i8*),i8**%bn,align 8
%bo=load i8*,i8**%b,align 8
%bp=getelementptr inbounds i8,i8*%bk,i64 8
%bq=bitcast i8*%bp to i8**
store i8*%bo,i8**%bq,align 8
%br=load i8*,i8**%c,align 8
%bs=getelementptr inbounds i8,i8*%bk,i64 16
%bt=bitcast i8*%bs to i8**
store i8*%br,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bk,i64 24
%bv=bitcast i8*%bu to i32*
store i32 7,i32*%bv,align 4
ret i8*%bk
bw:
%bx=bitcast i8*%D to i8**
%by=load i8*,i8**%bx,align 8
store i8*%by,i8**%b,align 8
%bz=getelementptr inbounds i8,i8*%D,i64 8
%bA=bitcast i8*%bz to i8**
%bB=load i8*,i8**%bA,align 8
%bC=icmp eq i8*%bB,null
br i1%bC,label%bD,label%e9
bD:
%bE=getelementptr inbounds i8,i8*%B,i64 8
%bF=bitcast i8*%bE to i8**
%bG=load i8*,i8**%bF,align 8
%bH=icmp eq i8*%bG,null
br i1%bH,label%bI,label%b2
bI:
%bJ=load i8*,i8**@_SMLZN12RuntimeTypes10contagPropE,align 8
%bK=getelementptr inbounds i8,i8*%bJ,i64 8
%bL=bitcast i8*%bK to i8**
%bM=load i8*,i8**%bL,align 8
store i8*%bM,i8**%b,align 8
%bN=getelementptr inbounds i8,i8*%bJ,i64 16
%bO=bitcast i8*%bN to i8**
%bP=load i8*,i8**%bO,align 8
store i8*%bP,i8**%c,align 8
%bQ=call i8*@sml_alloc(i32 inreg 28)#0
%bR=getelementptr inbounds i8,i8*%bQ,i64 -4
%bS=bitcast i8*%bR to i32*
store i32 1342177304,i32*%bS,align 4
%bT=bitcast i8*%bQ to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@d,i64 0,i32 2)to i8*),i8**%bT,align 8
%bU=load i8*,i8**%b,align 8
%bV=getelementptr inbounds i8,i8*%bQ,i64 8
%bW=bitcast i8*%bV to i8**
store i8*%bU,i8**%bW,align 8
%bX=load i8*,i8**%c,align 8
%bY=getelementptr inbounds i8,i8*%bQ,i64 16
%bZ=bitcast i8*%bY to i8**
store i8*%bX,i8**%bZ,align 8
%b0=getelementptr inbounds i8,i8*%bQ,i64 24
%b1=bitcast i8*%b0 to i32*
store i32 7,i32*%b1,align 4
ret i8*%bQ
b2:
%b3=getelementptr inbounds i8,i8*%bG,i64 8
%b4=bitcast i8*%b3 to i8**
%b5=load i8*,i8**%b4,align 8
%b6=icmp eq i8*%b5,null
br i1%b6,label%b7,label%dK
b7:
%b8=bitcast i8*%bG to i8**
%b9=load i8*,i8**%b8,align 8
%ca=getelementptr inbounds i8,i8*%b9,i64 8
%cb=bitcast i8*%ca to i8**
%cc=load i8*,i8**%cb,align 8
store i8*null,i8**%b,align 8
store i8*null,i8**%c,align 8
%cd=call fastcc i8*@_SMLFN6IDCalc13propertyOfItyE(i8*inreg%cc)
%ce=icmp eq i8*%cd,null
br i1%ce,label%cW,label%cf
cf:
%cg=bitcast i8*%cd to i8**
%ch=load i8*,i8**%cg,align 8
%ci=bitcast i8*%ch to i32*
%cj=load i32,i32*%ci,align 4
%ck=icmp eq i32%cj,1
br i1%ck,label%cl,label%cW
cl:
%cm=getelementptr inbounds i8,i8*%ch,i64 8
%cn=bitcast i8*%cm to i8**
%co=load i8*,i8**%cn,align 8
store i8*%co,i8**%b,align 8
%cp=call i8*@sml_alloc(i32 inreg 12)#0
%cq=getelementptr inbounds i8,i8*%cp,i64 -4
%cr=bitcast i8*%cq to i32*
store i32 1342177288,i32*%cr,align 4
%cs=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ct=bitcast i8*%cp to i8**
store i8*%cs,i8**%ct,align 8
%cu=getelementptr inbounds i8,i8*%cp,i64 8
%cv=bitcast i8*%cu to i32*
store i32 1,i32*%cv,align 4
%cw=icmp eq i8*%cp,null
br i1%cw,label%cW,label%cx
cx:
store i8*%cs,i8**%b,align 8
%cy=getelementptr inbounds i8,i8*%cs,i64 16
%cz=bitcast i8*%cy to i8**
%cA=load i8*,i8**%cz,align 8
%cB=icmp eq i8*%cA,null
br i1%cB,label%cC,label%cD
cC:
store i8*null,i8**%b,align 8
br label%cW
cD:
%cE=bitcast i8*%cA to i32*
%cF=load i32,i32*%cE,align 4
%cG=icmp eq i32%cF,0
br i1%cG,label%cI,label%cH
cH:
store i8*null,i8**%b,align 8
br label%cW
cI:
%cJ=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
store i8*%cJ,i8**%c,align 8
%cK=call i8*@sml_alloc(i32 inreg 20)#0
%cL=getelementptr inbounds i8,i8*%cK,i64 -4
%cM=bitcast i8*%cL to i32*
store i32 1342177296,i32*%cM,align 4
%cN=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cO=bitcast i8*%cK to i8**
store i8*%cN,i8**%cO,align 8
%cP=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cQ=getelementptr inbounds i8,i8*%cK,i64 8
%cR=bitcast i8*%cQ to i8**
store i8*%cP,i8**%cR,align 8
%cS=getelementptr inbounds i8,i8*%cK,i64 16
%cT=bitcast i8*%cS to i32*
store i32 3,i32*%cT,align 4
%cU=call fastcc i32@_SMLFN12RuntimeTypes15canBeRegardedAsE(i8*inreg%cK)
%cV=call fastcc i32@_SMLFN4Bool3notE(i32 inreg%cU)
br label%cW
cW:
%cX=phi i32[1,%cl],[1,%cC],[1,%cH],[%cV,%cI],[1,%cf],[1,%b7]
%cY=call i8*@sml_alloc(i32 inreg 12)#0
%cZ=getelementptr inbounds i8,i8*%cY,i64 -4
%c0=bitcast i8*%cZ to i32*
store i32 1342177288,i32*%c0,align 4
store i8*%cY,i8**%b,align 8
%c1=getelementptr inbounds i8,i8*%cY,i64 4
%c2=bitcast i8*%c1 to i32*
store i32 0,i32*%c2,align 1
%c3=bitcast i8*%cY to i32*
store i32%cX,i32*%c3,align 4
%c4=getelementptr inbounds i8,i8*%cY,i64 8
%c5=bitcast i8*%c4 to i32*
store i32 0,i32*%c5,align 4
%c6=call i8*@sml_alloc(i32 inreg 20)#0
%c7=getelementptr inbounds i8,i8*%c6,i64 -4
%c8=bitcast i8*%c7 to i32*
store i32 1342177296,i32*%c8,align 4
store i8*%c6,i8**%c,align 8
%c9=bitcast i8*%c6 to i64*
store i64 0,i64*%c9,align 4
%da=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%db=getelementptr inbounds i8,i8*%c6,i64 8
%dc=bitcast i8*%db to i8**
store i8*%da,i8**%dc,align 8
%dd=getelementptr inbounds i8,i8*%c6,i64 16
%de=bitcast i8*%dd to i32*
store i32 2,i32*%de,align 4
%df=call i8*@sml_alloc(i32 inreg 20)#0
%dg=getelementptr inbounds i8,i8*%df,i64 -4
%dh=bitcast i8*%dg to i32*
store i32 1342177296,i32*%dh,align 4
store i8*%df,i8**%d,align 8
%di=getelementptr inbounds i8,i8*%df,i64 4
%dj=bitcast i8*%di to i32*
store i32 0,i32*%dj,align 1
%dk=bitcast i8*%df to i32*
store i32 3,i32*%dk,align 4
%dl=load i8*,i8**%c,align 8
%dm=getelementptr inbounds i8,i8*%df,i64 8
%dn=bitcast i8*%dm to i8**
store i8*%dl,i8**%dn,align 8
%do=getelementptr inbounds i8,i8*%df,i64 16
%dp=bitcast i8*%do to i32*
store i32 2,i32*%dp,align 4
%dq=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%dr=getelementptr inbounds i8,i8*%dq,i64 8
%ds=bitcast i8*%dr to i8**
%dt=load i8*,i8**%ds,align 8
store i8*%dt,i8**%b,align 8
%du=getelementptr inbounds i8,i8*%dq,i64 16
%dv=bitcast i8*%du to i8**
%dw=load i8*,i8**%dv,align 8
store i8*%dw,i8**%c,align 8
%dx=call i8*@sml_alloc(i32 inreg 28)#0
%dy=getelementptr inbounds i8,i8*%dx,i64 -4
%dz=bitcast i8*%dy to i32*
store i32 1342177304,i32*%dz,align 4
%dA=load i8*,i8**%d,align 8
%dB=bitcast i8*%dx to i8**
store i8*%dA,i8**%dB,align 8
%dC=load i8*,i8**%b,align 8
%dD=getelementptr inbounds i8,i8*%dx,i64 8
%dE=bitcast i8*%dD to i8**
store i8*%dC,i8**%dE,align 8
%dF=load i8*,i8**%c,align 8
%dG=getelementptr inbounds i8,i8*%dx,i64 16
%dH=bitcast i8*%dG to i8**
store i8*%dF,i8**%dH,align 8
%dI=getelementptr inbounds i8,i8*%dx,i64 24
%dJ=bitcast i8*%dI to i32*
store i32 7,i32*%dJ,align 4
ret i8*%dx
dK:
%dL=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%dM=getelementptr inbounds i8,i8*%dL,i64 16
%dN=bitcast i8*%dM to i8*(i8*,i8*)**
%dO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dN,align 8
%dP=bitcast i8*%dL to i8**
%dQ=load i8*,i8**%dP,align 8
%dR=load i8*,i8**@_SMLZN6Symbol14symbolToStringE,align 8
%dS=call fastcc i8*%dO(i8*inreg%dQ,i8*inreg%dR)
%dT=getelementptr inbounds i8,i8*%dS,i64 16
%dU=bitcast i8*%dT to i8*(i8*,i8*)**
%dV=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dU,align 8
%dW=bitcast i8*%dS to i8**
%dX=load i8*,i8**%dW,align 8
store i8*%dX,i8**%d,align 8
%dY=call fastcc i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg 1,i32 inreg 8)
%dZ=getelementptr inbounds i8,i8*%dY,i64 16
%d0=bitcast i8*%dZ to i8*(i8*,i8*)**
%d1=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%d0,align 8
%d2=bitcast i8*%dY to i8**
%d3=load i8*,i8**%d2,align 8
%d4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%d5=call fastcc i8*%d1(i8*inreg%d3,i8*inreg%d4)
%d6=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%d7=call fastcc i8*%dV(i8*inreg%d6,i8*inreg%d5)
store i8*%d7,i8**%c,align 8
%d8=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%d9=call fastcc i8*@_SMLFN6Symbol14symbolToStringE(i8*inreg%d8)
store i8*%d9,i8**%b,align 8
%ea=call i8*@sml_alloc(i32 inreg 20)#0
%eb=getelementptr inbounds i8,i8*%ea,i64 -4
%ec=bitcast i8*%eb to i32*
store i32 1342177296,i32*%ec,align 4
store i8*%ea,i8**%d,align 8
%ed=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ee=bitcast i8*%ea to i8**
store i8*%ed,i8**%ee,align 8
%ef=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%eg=getelementptr inbounds i8,i8*%ea,i64 8
%eh=bitcast i8*%eg to i8**
store i8*%ef,i8**%eh,align 8
%ei=getelementptr inbounds i8,i8*%ea,i64 16
%ej=bitcast i8*%ei to i32*
store i32 3,i32*%ej,align 4
%ek=call i8*@sml_alloc(i32 inreg 20)#0
%el=getelementptr inbounds i8,i8*%ek,i64 -4
%em=bitcast i8*%el to i32*
store i32 1342177296,i32*%em,align 4
store i8*%ek,i8**%b,align 8
%en=bitcast i8*%ek to i64*
store i64 0,i64*%en,align 4
%eo=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ep=getelementptr inbounds i8,i8*%ek,i64 8
%eq=bitcast i8*%ep to i8**
store i8*%eo,i8**%eq,align 8
%er=getelementptr inbounds i8,i8*%ek,i64 16
%es=bitcast i8*%er to i32*
store i32 2,i32*%es,align 4
%et=call i8*@sml_alloc(i32 inreg 20)#0
%eu=getelementptr inbounds i8,i8*%et,i64 -4
%ev=bitcast i8*%eu to i32*
store i32 1342177296,i32*%ev,align 4
store i8*%et,i8**%c,align 8
%ew=getelementptr inbounds i8,i8*%et,i64 4
%ex=bitcast i8*%ew to i32*
store i32 0,i32*%ex,align 1
%ey=bitcast i8*%et to i32*
store i32 5,i32*%ey,align 4
%ez=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%eA=getelementptr inbounds i8,i8*%et,i64 8
%eB=bitcast i8*%eA to i8**
store i8*%ez,i8**%eB,align 8
%eC=getelementptr inbounds i8,i8*%et,i64 16
%eD=bitcast i8*%eC to i32*
store i32 2,i32*%eD,align 4
%eE=call i8*@sml_alloc(i32 inreg 20)#0
%eF=getelementptr inbounds i8,i8*%eE,i64 -4
%eG=bitcast i8*%eF to i32*
store i32 1342177296,i32*%eG,align 4
store i8*%eE,i8**%d,align 8
%eH=getelementptr inbounds i8,i8*%eE,i64 4
%eI=bitcast i8*%eH to i32*
store i32 0,i32*%eI,align 1
%eJ=bitcast i8*%eE to i32*
store i32 3,i32*%eJ,align 4
%eK=load i8*,i8**%c,align 8
%eL=getelementptr inbounds i8,i8*%eE,i64 8
%eM=bitcast i8*%eL to i8**
store i8*%eK,i8**%eM,align 8
%eN=getelementptr inbounds i8,i8*%eE,i64 16
%eO=bitcast i8*%eN to i32*
store i32 2,i32*%eO,align 4
%eP=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%eQ=getelementptr inbounds i8,i8*%eP,i64 8
%eR=bitcast i8*%eQ to i8**
%eS=load i8*,i8**%eR,align 8
store i8*%eS,i8**%b,align 8
%eT=getelementptr inbounds i8,i8*%eP,i64 16
%eU=bitcast i8*%eT to i8**
%eV=load i8*,i8**%eU,align 8
store i8*%eV,i8**%c,align 8
%eW=call i8*@sml_alloc(i32 inreg 28)#0
%eX=getelementptr inbounds i8,i8*%eW,i64 -4
%eY=bitcast i8*%eX to i32*
store i32 1342177304,i32*%eY,align 4
%eZ=load i8*,i8**%d,align 8
%e0=bitcast i8*%eW to i8**
store i8*%eZ,i8**%e0,align 8
%e1=load i8*,i8**%b,align 8
%e2=getelementptr inbounds i8,i8*%eW,i64 8
%e3=bitcast i8*%e2 to i8**
store i8*%e1,i8**%e3,align 8
%e4=load i8*,i8**%c,align 8
%e5=getelementptr inbounds i8,i8*%eW,i64 16
%e6=bitcast i8*%e5 to i8**
store i8*%e4,i8**%e6,align 8
%e7=getelementptr inbounds i8,i8*%eW,i64 24
%e8=bitcast i8*%e7 to i32*
store i32 7,i32*%e8,align 4
ret i8*%eW
e9:
%fa=getelementptr inbounds i8,i8*%bB,i64 8
%fb=bitcast i8*%fa to i8**
%fc=load i8*,i8**%fb,align 8
%fd=icmp eq i8*%fc,null
br i1%fd,label%fe,label%f9
fe:
%ff=getelementptr inbounds i8,i8*%B,i64 8
%fg=bitcast i8*%ff to i8**
%fh=load i8*,i8**%fg,align 8
%fi=icmp eq i8*%fh,null
br i1%fi,label%fj,label%f8
fj:
store i8*null,i8**%c,align 8
store i8*null,i8**%b,align 8
%fk=call fastcc i8*@_SMLFN6Symbol14symbolToStringE(i8*inreg%by)
store i8*%fk,i8**%b,align 8
%fl=call i8*@sml_alloc(i32 inreg 12)#0
%fm=getelementptr inbounds i8,i8*%fl,i64 -4
%fn=bitcast i8*%fm to i32*
store i32 1342177288,i32*%fn,align 4
store i8*%fl,i8**%c,align 8
%fo=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%fp=bitcast i8*%fl to i8**
store i8*%fo,i8**%fp,align 8
%fq=getelementptr inbounds i8,i8*%fl,i64 8
%fr=bitcast i8*%fq to i32*
store i32 1,i32*%fr,align 4
%fs=call i8*@sml_alloc(i32 inreg 20)#0
%ft=getelementptr inbounds i8,i8*%fs,i64 -4
%fu=bitcast i8*%ft to i32*
store i32 1342177296,i32*%fu,align 4
store i8*%fs,i8**%b,align 8
%fv=getelementptr inbounds i8,i8*%fs,i64 4
%fw=bitcast i8*%fv to i32*
store i32 0,i32*%fw,align 1
%fx=bitcast i8*%fs to i32*
store i32 1,i32*%fx,align 4
%fy=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fz=getelementptr inbounds i8,i8*%fs,i64 8
%fA=bitcast i8*%fz to i8**
store i8*%fy,i8**%fA,align 8
%fB=getelementptr inbounds i8,i8*%fs,i64 16
%fC=bitcast i8*%fB to i32*
store i32 2,i32*%fC,align 4
%fD=call i8*@sml_alloc(i32 inreg 20)#0
%fE=getelementptr inbounds i8,i8*%fD,i64 -4
%fF=bitcast i8*%fE to i32*
store i32 1342177296,i32*%fF,align 4
store i8*%fD,i8**%d,align 8
%fG=getelementptr inbounds i8,i8*%fD,i64 4
%fH=bitcast i8*%fG to i32*
store i32 0,i32*%fH,align 1
%fI=bitcast i8*%fD to i32*
store i32 3,i32*%fI,align 4
%fJ=load i8*,i8**%b,align 8
%fK=getelementptr inbounds i8,i8*%fD,i64 8
%fL=bitcast i8*%fK to i8**
store i8*%fJ,i8**%fL,align 8
%fM=getelementptr inbounds i8,i8*%fD,i64 16
%fN=bitcast i8*%fM to i32*
store i32 2,i32*%fN,align 4
%fO=load i8*,i8**@_SMLZN12RuntimeTypes10contagPropE,align 8
%fP=getelementptr inbounds i8,i8*%fO,i64 8
%fQ=bitcast i8*%fP to i8**
%fR=load i8*,i8**%fQ,align 8
store i8*%fR,i8**%b,align 8
%fS=getelementptr inbounds i8,i8*%fO,i64 16
%fT=bitcast i8*%fS to i8**
%fU=load i8*,i8**%fT,align 8
store i8*%fU,i8**%c,align 8
%fV=call i8*@sml_alloc(i32 inreg 28)#0
%fW=getelementptr inbounds i8,i8*%fV,i64 -4
%fX=bitcast i8*%fW to i32*
store i32 1342177304,i32*%fX,align 4
%fY=load i8*,i8**%d,align 8
%fZ=bitcast i8*%fV to i8**
store i8*%fY,i8**%fZ,align 8
%f0=load i8*,i8**%b,align 8
%f1=getelementptr inbounds i8,i8*%fV,i64 8
%f2=bitcast i8*%f1 to i8**
store i8*%f0,i8**%f2,align 8
%f3=load i8*,i8**%c,align 8
%f4=getelementptr inbounds i8,i8*%fV,i64 16
%f5=bitcast i8*%f4 to i8**
store i8*%f3,i8**%f5,align 8
%f6=getelementptr inbounds i8,i8*%fV,i64 24
%f7=bitcast i8*%f6 to i32*
store i32 7,i32*%f7,align 4
ret i8*%fV
f8:
store i8*null,i8**%b,align 8
br label%hA
f9:
store i8*null,i8**%b,align 8
%ga=getelementptr inbounds i8,i8*%B,i64 8
%gb=bitcast i8*%ga to i8**
%gc=load i8*,i8**%gb,align 8
%gd=icmp eq i8*%gc,null
br i1%gd,label%ge,label%hA
ge:
%gf=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%gg=getelementptr inbounds i8,i8*%gf,i64 16
%gh=bitcast i8*%gg to i8*(i8*,i8*)**
%gi=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gh,align 8
%gj=bitcast i8*%gf to i8**
%gk=load i8*,i8**%gj,align 8
%gl=load i8*,i8**@_SMLZN6Symbol14symbolToStringE,align 8
%gm=call fastcc i8*%gi(i8*inreg%gk,i8*inreg%gl)
%gn=getelementptr inbounds i8,i8*%gm,i64 16
%go=bitcast i8*%gn to i8*(i8*,i8*)**
%gp=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%go,align 8
%gq=bitcast i8*%gm to i8**
%gr=load i8*,i8**%gq,align 8
store i8*%gr,i8**%b,align 8
%gs=call fastcc i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg 1,i32 inreg 8)
%gt=getelementptr inbounds i8,i8*%gs,i64 16
%gu=bitcast i8*%gt to i8*(i8*,i8*)**
%gv=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gu,align 8
%gw=bitcast i8*%gs to i8**
%gx=load i8*,i8**%gw,align 8
%gy=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gz=call fastcc i8*%gv(i8*inreg%gx,i8*inreg%gy)
%gA=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%gB=call fastcc i8*%gp(i8*inreg%gA,i8*inreg%gz)
store i8*%gB,i8**%b,align 8
%gC=call i8*@sml_alloc(i32 inreg 12)#0
%gD=getelementptr inbounds i8,i8*%gC,i64 -4
%gE=bitcast i8*%gD to i32*
store i32 1342177288,i32*%gE,align 4
store i8*%gC,i8**%c,align 8
%gF=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%gG=bitcast i8*%gC to i8**
store i8*%gF,i8**%gG,align 8
%gH=getelementptr inbounds i8,i8*%gC,i64 8
%gI=bitcast i8*%gH to i32*
store i32 1,i32*%gI,align 4
%gJ=call i8*@sml_alloc(i32 inreg 20)#0
%gK=getelementptr inbounds i8,i8*%gJ,i64 -4
%gL=bitcast i8*%gK to i32*
store i32 1342177296,i32*%gL,align 4
store i8*%gJ,i8**%b,align 8
%gM=getelementptr inbounds i8,i8*%gJ,i64 4
%gN=bitcast i8*%gM to i32*
store i32 0,i32*%gN,align 1
%gO=bitcast i8*%gJ to i32*
store i32 2,i32*%gO,align 4
%gP=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gQ=getelementptr inbounds i8,i8*%gJ,i64 8
%gR=bitcast i8*%gQ to i8**
store i8*%gP,i8**%gR,align 8
%gS=getelementptr inbounds i8,i8*%gJ,i64 16
%gT=bitcast i8*%gS to i32*
store i32 2,i32*%gT,align 4
%gU=call i8*@sml_alloc(i32 inreg 20)#0
%gV=getelementptr inbounds i8,i8*%gU,i64 -4
%gW=bitcast i8*%gV to i32*
store i32 1342177296,i32*%gW,align 4
store i8*%gU,i8**%c,align 8
%gX=getelementptr inbounds i8,i8*%gU,i64 4
%gY=bitcast i8*%gX to i32*
store i32 0,i32*%gY,align 1
%gZ=bitcast i8*%gU to i32*
store i32 5,i32*%gZ,align 4
%g0=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%g1=getelementptr inbounds i8,i8*%gU,i64 8
%g2=bitcast i8*%g1 to i8**
store i8*%g0,i8**%g2,align 8
%g3=getelementptr inbounds i8,i8*%gU,i64 16
%g4=bitcast i8*%g3 to i32*
store i32 2,i32*%g4,align 4
%g5=call i8*@sml_alloc(i32 inreg 20)#0
%g6=getelementptr inbounds i8,i8*%g5,i64 -4
%g7=bitcast i8*%g6 to i32*
store i32 1342177296,i32*%g7,align 4
store i8*%g5,i8**%d,align 8
%g8=getelementptr inbounds i8,i8*%g5,i64 4
%g9=bitcast i8*%g8 to i32*
store i32 0,i32*%g9,align 1
%ha=bitcast i8*%g5 to i32*
store i32 3,i32*%ha,align 4
%hb=load i8*,i8**%c,align 8
%hc=getelementptr inbounds i8,i8*%g5,i64 8
%hd=bitcast i8*%hc to i8**
store i8*%hb,i8**%hd,align 8
%he=getelementptr inbounds i8,i8*%g5,i64 16
%hf=bitcast i8*%he to i32*
store i32 2,i32*%hf,align 4
%hg=load i8*,i8**@_SMLZN12RuntimeTypes10contagPropE,align 8
%hh=getelementptr inbounds i8,i8*%hg,i64 8
%hi=bitcast i8*%hh to i8**
%hj=load i8*,i8**%hi,align 8
store i8*%hj,i8**%b,align 8
%hk=getelementptr inbounds i8,i8*%hg,i64 16
%hl=bitcast i8*%hk to i8**
%hm=load i8*,i8**%hl,align 8
store i8*%hm,i8**%c,align 8
%hn=call i8*@sml_alloc(i32 inreg 28)#0
%ho=getelementptr inbounds i8,i8*%hn,i64 -4
%hp=bitcast i8*%ho to i32*
store i32 1342177304,i32*%hp,align 4
%hq=load i8*,i8**%d,align 8
%hr=bitcast i8*%hn to i8**
store i8*%hq,i8**%hr,align 8
%hs=load i8*,i8**%b,align 8
%ht=getelementptr inbounds i8,i8*%hn,i64 8
%hu=bitcast i8*%ht to i8**
store i8*%hs,i8**%hu,align 8
%hv=load i8*,i8**%c,align 8
%hw=getelementptr inbounds i8,i8*%hn,i64 16
%hx=bitcast i8*%hw to i8**
store i8*%hv,i8**%hx,align 8
%hy=getelementptr inbounds i8,i8*%hn,i64 24
%hz=bitcast i8*%hy to i32*
store i32 7,i32*%hz,align 4
ret i8*%hn
hA:
%hB=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%hC=getelementptr inbounds i8,i8*%hB,i64 16
%hD=bitcast i8*%hC to i8*(i8*,i8*)**
%hE=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hD,align 8
%hF=bitcast i8*%hB to i8**
%hG=load i8*,i8**%hF,align 8
%hH=load i8*,i8**@_SMLZN6Symbol14symbolToStringE,align 8
%hI=call fastcc i8*%hE(i8*inreg%hG,i8*inreg%hH)
%hJ=getelementptr inbounds i8,i8*%hI,i64 16
%hK=bitcast i8*%hJ to i8*(i8*,i8*)**
%hL=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hK,align 8
%hM=bitcast i8*%hI to i8**
%hN=load i8*,i8**%hM,align 8
store i8*%hN,i8**%b,align 8
%hO=call fastcc i8*@_SMLFN9SymbolEnv8listKeysE(i32 inreg 1,i32 inreg 8)
%hP=getelementptr inbounds i8,i8*%hO,i64 16
%hQ=bitcast i8*%hP to i8*(i8*,i8*)**
%hR=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hQ,align 8
%hS=bitcast i8*%hO to i8**
%hT=load i8*,i8**%hS,align 8
%hU=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%hV=call fastcc i8*%hR(i8*inreg%hT,i8*inreg%hU)
%hW=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%hX=call fastcc i8*%hL(i8*inreg%hW,i8*inreg%hV)
store i8*%hX,i8**%b,align 8
%hY=call i8*@sml_alloc(i32 inreg 12)#0
%hZ=getelementptr inbounds i8,i8*%hY,i64 -4
%h0=bitcast i8*%hZ to i32*
store i32 1342177288,i32*%h0,align 4
store i8*%hY,i8**%c,align 8
%h1=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h2=bitcast i8*%hY to i8**
store i8*%h1,i8**%h2,align 8
%h3=getelementptr inbounds i8,i8*%hY,i64 8
%h4=bitcast i8*%h3 to i32*
store i32 1,i32*%h4,align 4
%h5=call i8*@sml_alloc(i32 inreg 20)#0
%h6=getelementptr inbounds i8,i8*%h5,i64 -4
%h7=bitcast i8*%h6 to i32*
store i32 1342177296,i32*%h7,align 4
store i8*%h5,i8**%b,align 8
%h8=getelementptr inbounds i8,i8*%h5,i64 4
%h9=bitcast i8*%h8 to i32*
store i32 0,i32*%h9,align 1
%ia=bitcast i8*%h5 to i32*
store i32 1,i32*%ia,align 4
%ib=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ic=getelementptr inbounds i8,i8*%h5,i64 8
%id=bitcast i8*%ic to i8**
store i8*%ib,i8**%id,align 8
%ie=getelementptr inbounds i8,i8*%h5,i64 16
%if=bitcast i8*%ie to i32*
store i32 2,i32*%if,align 4
%ig=call i8*@sml_alloc(i32 inreg 20)#0
%ih=getelementptr inbounds i8,i8*%ig,i64 -4
%ii=bitcast i8*%ih to i32*
store i32 1342177296,i32*%ii,align 4
store i8*%ig,i8**%c,align 8
%ij=getelementptr inbounds i8,i8*%ig,i64 4
%ik=bitcast i8*%ij to i32*
store i32 0,i32*%ik,align 1
%il=bitcast i8*%ig to i32*
store i32 5,i32*%il,align 4
%im=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%in=getelementptr inbounds i8,i8*%ig,i64 8
%io=bitcast i8*%in to i8**
store i8*%im,i8**%io,align 8
%ip=getelementptr inbounds i8,i8*%ig,i64 16
%iq=bitcast i8*%ip to i32*
store i32 2,i32*%iq,align 4
%ir=call i8*@sml_alloc(i32 inreg 20)#0
%is=getelementptr inbounds i8,i8*%ir,i64 -4
%it=bitcast i8*%is to i32*
store i32 1342177296,i32*%it,align 4
store i8*%ir,i8**%d,align 8
%iu=getelementptr inbounds i8,i8*%ir,i64 4
%iv=bitcast i8*%iu to i32*
store i32 0,i32*%iv,align 1
%iw=bitcast i8*%ir to i32*
store i32 3,i32*%iw,align 4
%ix=load i8*,i8**%c,align 8
%iy=getelementptr inbounds i8,i8*%ir,i64 8
%iz=bitcast i8*%iy to i8**
store i8*%ix,i8**%iz,align 8
%iA=getelementptr inbounds i8,i8*%ir,i64 16
%iB=bitcast i8*%iA to i32*
store i32 2,i32*%iB,align 4
%iC=load i8*,i8**@_SMLZN12RuntimeTypes10recordPropE,align 8
%iD=getelementptr inbounds i8,i8*%iC,i64 8
%iE=bitcast i8*%iD to i8**
%iF=load i8*,i8**%iE,align 8
store i8*%iF,i8**%b,align 8
%iG=getelementptr inbounds i8,i8*%iC,i64 16
%iH=bitcast i8*%iG to i8**
%iI=load i8*,i8**%iH,align 8
store i8*%iI,i8**%c,align 8
%iJ=call i8*@sml_alloc(i32 inreg 28)#0
%iK=getelementptr inbounds i8,i8*%iJ,i64 -4
%iL=bitcast i8*%iK to i32*
store i32 1342177304,i32*%iL,align 4
%iM=load i8*,i8**%d,align 8
%iN=bitcast i8*%iJ to i8**
store i8*%iM,i8**%iN,align 8
%iO=load i8*,i8**%b,align 8
%iP=getelementptr inbounds i8,i8*%iJ,i64 8
%iQ=bitcast i8*%iP to i8**
store i8*%iO,i8**%iQ,align 8
%iR=load i8*,i8**%c,align 8
%iS=getelementptr inbounds i8,i8*%iJ,i64 16
%iT=bitcast i8*%iS to i8**
store i8*%iR,i8**%iT,align 8
%iU=getelementptr inbounds i8,i8*%iJ,i64 24
%iV=bitcast i8*%iU to i32*
store i32 7,i32*%iV,align 4
ret i8*%iJ
}
define internal fastcc i8*@_SMLLLN14DatatypeLayout14datatypeLayoutE_60(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLLN14DatatypeLayout14datatypeLayoutE_45(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN14DatatypeLayout14datatypeLayoutE_61(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN14DatatypeLayout14datatypeLayoutE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
