@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[81x i8]}><{[4x i8]zeroinitializer,i32 -2147483567,[81x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:21.6(482)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[82x i8]}><{[4x i8]zeroinitializer,i32 -2147483566,[82x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:84.6(3143)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLLLN18ConcurrencySupport7hasCallE_118 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN18ConcurrencySupport7hasCallE_133 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:109.6(3923)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:63.25(2301)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[16x i8]}><{[4x i8]zeroinitializer,i32 -2147483632,[16x i8]c"reachableToLoop\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[82x i8]}><{[4x i8]zeroinitializer,i32 -2147483566,[82x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:57.6(2047)\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:136.6(4806)\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN18ConcurrencySupport13compileTopdecE_128 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN18ConcurrencySupport13compileTopdecE_136 to void(...)*),i32 -2147483647}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN18ConcurrencySupport13insertCheckGCE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN18ConcurrencySupport13insertCheckGCE_137 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN18ConcurrencySupport13insertCheckGCE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@j,i64 0,i32 2)to i8*)
@_SML_ftab840c81e7629d5e9b_ConcurrencySupport=external global i8
@k=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN13FunLocalLabel3Map4findE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map6insertE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List5foldlE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maine7eca9e7f5c591d9_CodeLabel()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_loade7eca9e7f5c591d9_CodeLabel(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
define private void@_SML_tabb840c81e7629d5e9b_ConcurrencySupport()#3{
unreachable
}
define void@_SML_load840c81e7629d5e9b_ConcurrencySupport(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@k,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@k,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_loade7eca9e7f5c591d9_CodeLabel(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb840c81e7629d5e9b_ConcurrencySupport,i8*@_SML_ftab840c81e7629d5e9b_ConcurrencySupport,i8*null)#0
ret void
}
define void@_SML_main840c81e7629d5e9b_ConcurrencySupport()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@k,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@k,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_maine7eca9e7f5c591d9_CodeLabel()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
br label%d
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_110(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store i8*%a,i8**%g,align 8
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%k,label%m
k:
%l=bitcast i8*%a to i8**
br label%q
m:
call void@sml_check(i32 inreg%i)
%n=load i8*,i8**%c,align 8
%o=bitcast i8**%g to i8***
%p=load i8**,i8***%o,align 8
br label%q
q:
%r=phi i8**[%p,%m],[%l,%k]
%s=phi i8*[%n,%m],[%b,%k]
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=getelementptr inbounds i8,i8*%s,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
%y=getelementptr inbounds i8,i8*%s,i64 16
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
store i8*%A,i8**%d,align 8
%B=load i8*,i8**%r,align 8
%C=call fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_106(i8*inreg%B,i8*inreg%x)
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%e,align 8
%F=getelementptr inbounds i8,i8*%C,i64 8
%G=bitcast i8*%F to i8**
%H=load i8*,i8**%G,align 8
store i8*%H,i8**%f,align 8
%I=load i8*,i8**%g,align 8
%J=getelementptr inbounds i8,i8*%I,i64 8
%K=bitcast i8*%J to i32*
%L=load i32,i32*%K,align 4
%M=icmp eq i32%L,0
br i1%M,label%ax,label%N
N:
%O=bitcast i8*%I to i8**
%P=load i8*,i8**%O,align 8
store i8*%P,i8**%g,align 8
%Q=call i8*@sml_alloc(i32 inreg 12)#0
%R=getelementptr inbounds i8,i8*%Q,i64 -4
%S=bitcast i8*%R to i32*
store i32 1342177288,i32*%S,align 4
store i8*%Q,i8**%h,align 8
%T=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%U=bitcast i8*%Q to i8**
store i8*%T,i8**%U,align 8
%V=getelementptr inbounds i8,i8*%Q,i64 8
%W=bitcast i8*%V to i32*
store i32 1,i32*%W,align 4
%X=call i8*@sml_alloc(i32 inreg 20)#0
%Y=getelementptr inbounds i8,i8*%X,i64 -4
%Z=bitcast i8*%Y to i32*
store i32 1342177296,i32*%Z,align 4
store i8*%X,i8**%g,align 8
%aa=getelementptr inbounds i8,i8*%X,i64 4
%ab=bitcast i8*%aa to i32*
store i32 0,i32*%ab,align 1
%ac=bitcast i8*%X to i32*
store i32 5,i32*%ac,align 4
%ad=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ae=getelementptr inbounds i8,i8*%X,i64 8
%af=bitcast i8*%ae to i8**
store i8*%ad,i8**%af,align 8
%ag=getelementptr inbounds i8,i8*%X,i64 16
%ah=bitcast i8*%ag to i32*
store i32 2,i32*%ah,align 4
%ai=call i8*@sml_alloc(i32 inreg 20)#0
%aj=getelementptr inbounds i8,i8*%ai,i64 -4
%ak=bitcast i8*%aj to i32*
store i32 1342177296,i32*%ak,align 4
store i8*%ai,i8**%h,align 8
%al=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%am=bitcast i8*%ai to i8**
store i8*%al,i8**%am,align 8
%an=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ao=getelementptr inbounds i8,i8*%ai,i64 8
%ap=bitcast i8*%ao to i8**
store i8*%an,i8**%ap,align 8
%aq=getelementptr inbounds i8,i8*%ai,i64 16
%ar=bitcast i8*%aq to i32*
store i32 3,i32*%ar,align 4
%as=call i8*@sml_alloc(i32 inreg 20)#0
%at=getelementptr inbounds i8,i8*%as,i64 -4
%au=bitcast i8*%at to i32*
store i32 1342177296,i32*%au,align 4
%av=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aw=bitcast i8*%as to i8**
store i8*%av,i8**%aw,align 8
br label%aD
ax:
store i8*null,i8**%g,align 8
%ay=call i8*@sml_alloc(i32 inreg 20)#0
%az=getelementptr inbounds i8,i8*%ay,i64 -4
%aA=bitcast i8*%az to i32*
store i32 1342177296,i32*%aA,align 4
%aB=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aC=bitcast i8*%ay to i8**
store i8*%aB,i8**%aC,align 8
br label%aD
aD:
%aE=phi i8*[%ay,%ax],[%as,%N]
%aF=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aG=getelementptr inbounds i8,i8*%aE,i64 8
%aH=bitcast i8*%aG to i8**
store i8*%aF,i8**%aH,align 8
%aI=getelementptr inbounds i8,i8*%aE,i64 16
%aJ=bitcast i8*%aI to i32*
store i32 3,i32*%aJ,align 4
store i8*%aE,i8**%e,align 8
%aK=call i8*@sml_alloc(i32 inreg 28)#0
%aL=getelementptr inbounds i8,i8*%aK,i64 -4
%aM=bitcast i8*%aL to i32*
store i32 1342177304,i32*%aM,align 4
%aN=load i8*,i8**%c,align 8
%aO=bitcast i8*%aK to i8**
store i8*%aN,i8**%aO,align 8
%aP=load i8*,i8**%e,align 8
%aQ=getelementptr inbounds i8,i8*%aK,i64 8
%aR=bitcast i8*%aQ to i8**
store i8*%aP,i8**%aR,align 8
%aS=load i8*,i8**%d,align 8
%aT=getelementptr inbounds i8,i8*%aK,i64 16
%aU=bitcast i8*%aT to i8**
store i8*%aS,i8**%aU,align 8
%aV=getelementptr inbounds i8,i8*%aK,i64 24
%aW=bitcast i8*%aV to i32*
store i32 7,i32*%aW,align 4
ret i8*%aK
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_106(i8*inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"{
q:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%d,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%b,%q]
%r=bitcast i8*%p to i8**
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%d,align 8
%t=getelementptr inbounds i8,i8*%p,i64 8
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
%w=icmp eq i8*%v,null
br i1%w,label%S,label%x
x:
%y=bitcast i8*%v to i32*
%z=load i32,i32*%y,align 4
switch i32%z,label%A[
i32 4,label%S
i32 3,label%S
i32 1,label%bw
i32 5,label%S
i32 2,label%T
i32 0,label%S
i32 6,label%S
]
A:
store i8*null,i8**%d,align 8
call void@sml_matchcomp_bug()
%B=load i8*,i8**@_SMLZ5Match,align 8
store i8*%B,i8**%c,align 8
%C=call i8*@sml_alloc(i32 inreg 20)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177296,i32*%E,align 4
store i8*%C,i8**%d,align 8
%F=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%G=bitcast i8*%C to i8**
store i8*%F,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%C,i64 8
%I=bitcast i8*%H to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[81x i8]}>,<{[4x i8],i32,[81x i8]}>*@a,i64 0,i32 2,i64 0),i8**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
%L=call i8*@sml_alloc(i32 inreg 60)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177336,i32*%N,align 4
%O=getelementptr inbounds i8,i8*%L,i64 56
%P=bitcast i8*%O to i32*
store i32 1,i32*%P,align 4
%Q=load i8*,i8**%d,align 8
%R=bitcast i8*%L to i8**
store i8*%Q,i8**%R,align 8
call void@sml_raise(i8*inreg%L)#1
unreachable
S:
ret i8*%p
T:
%U=getelementptr inbounds i8,i8*%v,i64 8
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%W,i64 8
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
store i8*%ab,i8**%f,align 8
%ac=getelementptr inbounds i8,i8*%W,i64 16
%ad=bitcast i8*%ac to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%g,align 8
%af=getelementptr inbounds i8,i8*%W,i64 24
%ag=bitcast i8*%af to i32*
%ah=load i32,i32*%ag,align 4
%ai=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%aj=getelementptr inbounds i8,i8*%ai,i64 16
%ak=bitcast i8*%aj to i8*(i8*,i8*)**
%al=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ak,align 8
%am=bitcast i8*%ai to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%h,align 8
%ao=call i8*@sml_alloc(i32 inreg 20)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177296,i32*%aq,align 4
store i8*%ao,i8**%i,align 8
%ar=load i8*,i8**%c,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ao,i64 8
%au=bitcast i8*%at to i32*
store i32%ah,i32*%au,align 4
%av=getelementptr inbounds i8,i8*%ao,i64 16
%aw=bitcast i8*%av to i32*
store i32 1,i32*%aw,align 4
%ax=call i8*@sml_alloc(i32 inreg 28)#0
%ay=getelementptr inbounds i8,i8*%ax,i64 -4
%az=bitcast i8*%ay to i32*
store i32 1342177304,i32*%az,align 4
%aA=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aB=bitcast i8*%ax to i8**
store i8*%aA,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%ax,i64 8
%aD=bitcast i8*%aC to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_110 to void(...)*),void(...)**%aD,align 8
%aE=getelementptr inbounds i8,i8*%ax,i64 16
%aF=bitcast i8*%aE to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_110 to void(...)*),void(...)**%aF,align 8
%aG=getelementptr inbounds i8,i8*%ax,i64 24
%aH=bitcast i8*%aG to i32*
store i32 -2147483647,i32*%aH,align 4
%aI=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aJ=call fastcc i8*%al(i8*inreg%aI,i8*inreg%ax)
%aK=getelementptr inbounds i8,i8*%aJ,i64 16
%aL=bitcast i8*%aK to i8*(i8*,i8*)**
%aM=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aL,align 8
%aN=bitcast i8*%aJ to i8**
%aO=load i8*,i8**%aN,align 8
%aP=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aQ=call fastcc i8*%aM(i8*inreg%aO,i8*inreg%aP)
store i8*%aQ,i8**%e,align 8
%aR=load i8*,i8**%c,align 8
%aS=load i8*,i8**%g,align 8
store i8*null,i8**%c,align 8
store i8*null,i8**%g,align 8
%aT=call fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_106(i8*inreg%aR,i8*inreg%aS)
store i8*%aT,i8**%c,align 8
%aU=call i8*@sml_alloc(i32 inreg 36)#0
%aV=getelementptr inbounds i8,i8*%aU,i64 -4
%aW=bitcast i8*%aV to i32*
store i32 1342177312,i32*%aW,align 4
store i8*%aU,i8**%g,align 8
%aX=getelementptr inbounds i8,i8*%aU,i64 28
%aY=bitcast i8*%aX to i32*
store i32 0,i32*%aY,align 1
%aZ=load i8*,i8**%e,align 8
%a0=bitcast i8*%aU to i8**
store i8*null,i8**%e,align 8
store i8*%aZ,i8**%a0,align 8
%a1=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a2=getelementptr inbounds i8,i8*%aU,i64 8
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a5=getelementptr inbounds i8,i8*%aU,i64 16
%a6=bitcast i8*%a5 to i8**
store i8*%a4,i8**%a6,align 8
%a7=getelementptr inbounds i8,i8*%aU,i64 24
%a8=bitcast i8*%a7 to i32*
store i32%ah,i32*%a8,align 4
%a9=getelementptr inbounds i8,i8*%aU,i64 32
%ba=bitcast i8*%a9 to i32*
store i32 7,i32*%ba,align 4
%bb=call i8*@sml_alloc(i32 inreg 20)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177296,i32*%bd,align 4
store i8*%bb,i8**%c,align 8
%be=getelementptr inbounds i8,i8*%bb,i64 4
%bf=bitcast i8*%be to i32*
store i32 0,i32*%bf,align 1
%bg=bitcast i8*%bb to i32*
store i32 2,i32*%bg,align 4
%bh=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bi=getelementptr inbounds i8,i8*%bb,i64 8
%bj=bitcast i8*%bi to i8**
store i8*%bh,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bb,i64 16
%bl=bitcast i8*%bk to i32*
store i32 2,i32*%bl,align 4
%bm=call i8*@sml_alloc(i32 inreg 20)#0
%bn=getelementptr inbounds i8,i8*%bm,i64 -4
%bo=bitcast i8*%bn to i32*
store i32 1342177296,i32*%bo,align 4
%bp=load i8*,i8**%d,align 8
%bq=bitcast i8*%bm to i8**
store i8*%bp,i8**%bq,align 8
%br=load i8*,i8**%c,align 8
%bs=getelementptr inbounds i8,i8*%bm,i64 8
%bt=bitcast i8*%bs to i8**
store i8*%br,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bm,i64 16
%bv=bitcast i8*%bu to i32*
store i32 3,i32*%bv,align 4
ret i8*%bm
bw:
%bx=getelementptr inbounds i8,i8*%v,i64 8
%by=bitcast i8*%bx to i8**
%bz=load i8*,i8**%by,align 8
%bA=bitcast i8*%bz to i8**
%bB=load i8*,i8**%bA,align 8
store i8*%bB,i8**%e,align 8
%bC=getelementptr inbounds i8,i8*%bz,i64 8
%bD=bitcast i8*%bC to i8**
%bE=load i8*,i8**%bD,align 8
store i8*%bE,i8**%f,align 8
%bF=getelementptr inbounds i8,i8*%bz,i64 16
%bG=bitcast i8*%bF to i8**
%bH=load i8*,i8**%bG,align 8
store i8*%bH,i8**%g,align 8
%bI=getelementptr inbounds i8,i8*%bz,i64 24
%bJ=bitcast i8*%bI to i8**
%bK=load i8*,i8**%bJ,align 8
store i8*%bK,i8**%h,align 8
%bL=getelementptr inbounds i8,i8*%bz,i64 32
%bM=bitcast i8*%bL to i8**
%bN=load i8*,i8**%bM,align 8
store i8*%bN,i8**%i,align 8
%bO=getelementptr inbounds i8,i8*%bz,i64 40
%bP=bitcast i8*%bO to i8**
%bQ=load i8*,i8**%bP,align 8
%bR=load i8*,i8**%c,align 8
%bS=call fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_106(i8*inreg%bR,i8*inreg%bQ)
store i8*%bS,i8**%j,align 8
%bT=load i8*,i8**%c,align 8
%bU=load i8*,i8**%g,align 8
store i8*null,i8**%c,align 8
store i8*null,i8**%g,align 8
%bV=call fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_106(i8*inreg%bT,i8*inreg%bU)
store i8*%bV,i8**%c,align 8
%bW=call i8*@sml_alloc(i32 inreg 52)#0
%bX=getelementptr inbounds i8,i8*%bW,i64 -4
%bY=bitcast i8*%bX to i32*
store i32 1342177328,i32*%bY,align 4
store i8*%bW,i8**%g,align 8
%bZ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%b0=bitcast i8*%bW to i8**
store i8*%bZ,i8**%b0,align 8
%b1=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%b2=getelementptr inbounds i8,i8*%bW,i64 8
%b3=bitcast i8*%b2 to i8**
store i8*%b1,i8**%b3,align 8
%b4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%b5=getelementptr inbounds i8,i8*%bW,i64 16
%b6=bitcast i8*%b5 to i8**
store i8*%b4,i8**%b6,align 8
%b7=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b8=getelementptr inbounds i8,i8*%bW,i64 24
%b9=bitcast i8*%b8 to i8**
store i8*%b7,i8**%b9,align 8
%ca=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cb=getelementptr inbounds i8,i8*%bW,i64 32
%cc=bitcast i8*%cb to i8**
store i8*%ca,i8**%cc,align 8
%cd=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%ce=getelementptr inbounds i8,i8*%bW,i64 40
%cf=bitcast i8*%ce to i8**
store i8*%cd,i8**%cf,align 8
%cg=getelementptr inbounds i8,i8*%bW,i64 48
%ch=bitcast i8*%cg to i32*
store i32 63,i32*%ch,align 4
%ci=call i8*@sml_alloc(i32 inreg 20)#0
%cj=getelementptr inbounds i8,i8*%ci,i64 -4
%ck=bitcast i8*%cj to i32*
store i32 1342177296,i32*%ck,align 4
store i8*%ci,i8**%c,align 8
%cl=getelementptr inbounds i8,i8*%ci,i64 4
%cm=bitcast i8*%cl to i32*
store i32 0,i32*%cm,align 1
%cn=bitcast i8*%ci to i32*
store i32 1,i32*%cn,align 4
%co=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cp=getelementptr inbounds i8,i8*%ci,i64 8
%cq=bitcast i8*%cp to i8**
store i8*%co,i8**%cq,align 8
%cr=getelementptr inbounds i8,i8*%ci,i64 16
%cs=bitcast i8*%cr to i32*
store i32 2,i32*%cs,align 4
%ct=call i8*@sml_alloc(i32 inreg 20)#0
%cu=getelementptr inbounds i8,i8*%ct,i64 -4
%cv=bitcast i8*%cu to i32*
store i32 1342177296,i32*%cv,align 4
%cw=load i8*,i8**%d,align 8
%cx=bitcast i8*%ct to i8**
store i8*%cw,i8**%cx,align 8
%cy=load i8*,i8**%c,align 8
%cz=getelementptr inbounds i8,i8*%ct,i64 8
%cA=bitcast i8*%cz to i8**
store i8*%cy,i8**%cA,align 8
%cB=getelementptr inbounds i8,i8*%ct,i64 16
%cC=bitcast i8*%cB to i32*
store i32 3,i32*%cC,align 4
ret i8*%ct
}
define internal fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_118(i8*inreg%a)#2 gc"smlsharp"{
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
%j=getelementptr inbounds i8,i8*%h,i64 8
%k=bitcast i8*%j to i32*
%l=load i32,i32*%k,align 4
%m=icmp eq i32%l,0
br i1%m,label%o,label%n
n:
ret i32 1
o:
%p=bitcast i8*%h to i8**
%q=load i8*,i8**%p,align 8
%r=getelementptr inbounds i8,i8*%q,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=tail call fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_112(i8*inreg%t)
ret i32%u
}
define internal fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_112(i8*inreg%a)unnamed_addr#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
br label%d
d:
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=load i8*,i8**%b,align 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
%l=icmp eq i8*%k,null
br i1%l,label%m,label%aN
m:
%n=getelementptr inbounds i8,i8*%i,i64 8
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
%q=icmp eq i8*%p,null
br i1%q,label%M,label%r
r:
%s=bitcast i8*%p to i32*
%t=load i32,i32*%s,align 4
switch i32%t,label%u[
i32 4,label%M
i32 3,label%M
i32 1,label%aB
i32 5,label%M
i32 2,label%O
i32 0,label%M
i32 6,label%M
]
u:
call void@sml_matchcomp_bug()
%v=load i8*,i8**@_SMLZ5Match,align 8
store i8*%v,i8**%b,align 8
%w=call i8*@sml_alloc(i32 inreg 20)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177296,i32*%y,align 4
store i8*%w,i8**%c,align 8
%z=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%A=bitcast i8*%w to i8**
store i8*%z,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%w,i64 8
%C=bitcast i8*%B to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@d,i64 0,i32 2,i64 0),i8**%C,align 8
%D=getelementptr inbounds i8,i8*%w,i64 16
%E=bitcast i8*%D to i32*
store i32 3,i32*%E,align 4
%F=call i8*@sml_alloc(i32 inreg 60)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177336,i32*%H,align 4
%I=getelementptr inbounds i8,i8*%F,i64 56
%J=bitcast i8*%I to i32*
store i32 1,i32*%J,align 4
%K=load i8*,i8**%c,align 8
%L=bitcast i8*%F to i8**
store i8*%K,i8**%L,align 8
call void@sml_raise(i8*inreg%F)#1
unreachable
M:
%N=phi i32[1,%O],[0,%m],[1,%aX],[1,%aX],[0,%r],[0,%r],[1,%aB],[0,%r],[0,%r],[0,%r]
ret i32%N
O:
%P=getelementptr inbounds i8,i8*%p,i64 8
%Q=bitcast i8*%P to i8**
%R=load i8*,i8**%Q,align 8
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
store i8*%T,i8**%b,align 8
%U=getelementptr inbounds i8,i8*%R,i64 16
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
%X=call fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_112(i8*inreg%W)
%Y=icmp eq i32%X,0
br i1%Y,label%Z,label%M
Z:
%aa=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg 1,i32 inreg 8,i32 inreg 0,i32 inreg 4)
%ab=getelementptr inbounds i8,i8*%aa,i64 16
%ac=bitcast i8*%ab to i8*(i8*,i8*)**
%ad=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ac,align 8
%ae=bitcast i8*%aa to i8**
%af=load i8*,i8**%ae,align 8
%ag=call fastcc i8*%ad(i8*inreg%af,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*))
%ah=getelementptr inbounds i8,i8*%ag,i64 16
%ai=bitcast i8*%ah to i8*(i8*,i8*)**
%aj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ai,align 8
%ak=bitcast i8*%ag to i8**
%al=load i8*,i8**%ak,align 8
store i8*%al,i8**%c,align 8
%am=call i8*@sml_alloc(i32 inreg 4)#0
%an=bitcast i8*%am to i32*
%ao=getelementptr inbounds i8,i8*%am,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 4,i32*%ap,align 4
store i32 0,i32*%an,align 4
%aq=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ar=call fastcc i8*%aj(i8*inreg%aq,i8*inreg%am)
%as=getelementptr inbounds i8,i8*%ar,i64 16
%at=bitcast i8*%as to i8*(i8*,i8*)**
%au=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%at,align 8
%av=bitcast i8*%ar to i8**
%aw=load i8*,i8**%av,align 8
%ax=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ay=call fastcc i8*%au(i8*inreg%aw,i8*inreg%ax)
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
ret i32%aA
aB:
%aC=getelementptr inbounds i8,i8*%p,i64 8
%aD=bitcast i8*%aC to i8**
%aE=load i8*,i8**%aD,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 16
%aG=bitcast i8*%aF to i8**
%aH=load i8*,i8**%aG,align 8
store i8*%aH,i8**%b,align 8
%aI=getelementptr inbounds i8,i8*%aE,i64 40
%aJ=bitcast i8*%aI to i8**
%aK=load i8*,i8**%aJ,align 8
%aL=call fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_112(i8*inreg%aK)
%aM=icmp eq i32%aL,0
br i1%aM,label%bt,label%M
aN:
%aO=bitcast i8*%k to i8**
%aP=load i8*,i8**%aO,align 8
%aQ=getelementptr inbounds i8,i8*%k,i64 8
%aR=bitcast i8*%aQ to i8**
%aS=load i8*,i8**%aR,align 8
store i8*%aS,i8**%c,align 8
%aT=getelementptr inbounds i8,i8*%i,i64 8
%aU=bitcast i8*%aT to i8**
%aV=load i8*,i8**%aU,align 8
store i8*%aV,i8**%b,align 8
%aW=icmp eq i8*%aP,null
br i1%aW,label%bi,label%aX
aX:
%aY=bitcast i8*%aP to i32*
%aZ=load i32,i32*%aY,align 4
switch i32%aZ,label%a0[
i32 10,label%bi
i32 9,label%M
i32 6,label%bi
i32 8,label%bi
i32 14,label%bi
i32 16,label%bi
i32 15,label%bi
i32 0,label%bi
i32 1,label%bi
i32 5,label%bi
i32 18,label%bi
i32 19,label%bi
i32 3,label%bi
i32 20,label%bi
i32 13,label%bi
i32 12,label%bi
i32 17,label%bi
i32 2,label%bi
i32 4,label%M
i32 21,label%bi
i32 7,label%bi
i32 11,label%bi
]
a0:
store i8*null,i8**%c,align 8
call void@sml_matchcomp_bug()
%a1=load i8*,i8**@_SMLZ5Match,align 8
store i8*%a1,i8**%b,align 8
%a2=call i8*@sml_alloc(i32 inreg 20)#0
%a3=getelementptr inbounds i8,i8*%a2,i64 -4
%a4=bitcast i8*%a3 to i32*
store i32 1342177296,i32*%a4,align 4
store i8*%a2,i8**%c,align 8
%a5=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%a6=bitcast i8*%a2 to i8**
store i8*%a5,i8**%a6,align 8
%a7=getelementptr inbounds i8,i8*%a2,i64 8
%a8=bitcast i8*%a7 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[82x i8]}>,<{[4x i8],i32,[82x i8]}>*@b,i64 0,i32 2,i64 0),i8**%a8,align 8
%a9=getelementptr inbounds i8,i8*%a2,i64 16
%ba=bitcast i8*%a9 to i32*
store i32 3,i32*%ba,align 4
%bb=call i8*@sml_alloc(i32 inreg 60)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177336,i32*%bd,align 4
%be=getelementptr inbounds i8,i8*%bb,i64 56
%bf=bitcast i8*%be to i32*
store i32 1,i32*%bf,align 4
%bg=load i8*,i8**%c,align 8
%bh=bitcast i8*%bb to i8**
store i8*%bg,i8**%bh,align 8
call void@sml_raise(i8*inreg%bb)#1
unreachable
bi:
%bj=call i8*@sml_alloc(i32 inreg 20)#0
%bk=getelementptr inbounds i8,i8*%bj,i64 -4
%bl=bitcast i8*%bk to i32*
store i32 1342177296,i32*%bl,align 4
%bm=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bn=bitcast i8*%bj to i8**
store i8*%bm,i8**%bn,align 8
%bo=load i8*,i8**%b,align 8
%bp=getelementptr inbounds i8,i8*%bj,i64 8
%bq=bitcast i8*%bp to i8**
store i8*%bo,i8**%bq,align 8
%br=getelementptr inbounds i8,i8*%bj,i64 16
%bs=bitcast i8*%br to i32*
store i32 3,i32*%bs,align 4
store i8*%bj,i8**%b,align 8
br label%bt
bt:
br label%d
}
define internal fastcc i8*@_SMLLL7blocks2_121(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
o:
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
br i1%j,label%m,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%c,align 8
br label%m
m:
%n=phi i8*[%l,%k],[%b,%o]
%p=bitcast i8*%n to i8**
%q=load i8*,i8**%p,align 8
%r=getelementptr inbounds i8,i8*%q,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%c,align 8
%u=getelementptr inbounds i8,i8*%q,i64 16
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%d,align 8
%x=getelementptr inbounds i8,i8*%n,i64 8
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
store i8*%z,i8**%e,align 8
%A=call fastcc i8*@_SMLFN13FunLocalLabel3Map6insertE(i32 inreg 1,i32 inreg 8)
%B=getelementptr inbounds i8,i8*%A,i64 16
%C=bitcast i8*%B to i8*(i8*,i8*)**
%D=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%C,align 8
%E=bitcast i8*%A to i8**
%F=load i8*,i8**%E,align 8
store i8*%F,i8**%h,align 8
%G=bitcast i8**%f to i8***
%H=load i8**,i8***%G,align 8
%I=load i8*,i8**%H,align 8
store i8*%I,i8**%f,align 8
%J=call i8*@sml_alloc(i32 inreg 20)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177296,i32*%L,align 4
store i8*%J,i8**%g,align 8
%M=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%N=bitcast i8*%J to i8**
store i8*%M,i8**%N,align 8
%O=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%P=getelementptr inbounds i8,i8*%J,i64 8
%Q=bitcast i8*%P to i8**
store i8*%O,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%J,i64 16
%S=bitcast i8*%R to i32*
store i32 3,i32*%S,align 4
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
%W=load i8*,i8**%e,align 8
%X=bitcast i8*%T to i8**
store i8*%W,i8**%X,align 8
%Y=load i8*,i8**%d,align 8
%Z=getelementptr inbounds i8,i8*%T,i64 8
%aa=bitcast i8*%Z to i8**
store i8*%Y,i8**%aa,align 8
%ab=load i8*,i8**%g,align 8
%ac=getelementptr inbounds i8,i8*%T,i64 16
%ad=bitcast i8*%ac to i8**
store i8*%ab,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%T,i64 24
%af=bitcast i8*%ae to i32*
store i32 7,i32*%af,align 4
%ag=load i8*,i8**%h,align 8
%ah=tail call fastcc i8*%D(i8*inreg%ag,i8*inreg%T)
ret i8*%ah
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport11compileBodyE_125(i8*inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"{
w:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
store i8*%a,i8**%c,align 8
%m=bitcast i8*%b to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%d,align 8
%o=getelementptr inbounds i8,i8*%b,i64 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%e,align 8
%r=call fastcc i8*@_SMLLLN18ConcurrencySupport17insertCheckAtLoopE_106(i8*inreg%a,i8*inreg%b)
store i8*%r,i8**%f,align 8
%s=call fastcc i8*@_SMLFN13FunLocalLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
%t=load i8*,i8**%f,align 8
store i8*%s,i8**%g,align 8
store i8*%t,i8**%h,align 8
br label%u
u:
%v=phi i8*[%t,%w],[%ba,%a9]
%x=load atomic i32,i32*@sml_check_flag unordered,align 4
%y=icmp eq i32%x,0
br i1%y,label%B,label%z
z:
call void@sml_check(i32 inreg%x)
%A=load i8*,i8**%h,align 8
br label%B
B:
%C=phi i8*[%A,%z],[%v,%u]
store i8*null,i8**%h,align 8
%D=getelementptr inbounds i8,i8*%C,i64 8
%E=bitcast i8*%D to i8**
%F=load i8*,i8**%E,align 8
%G=icmp eq i8*%F,null
br i1%G,label%ac,label%H
H:
%I=bitcast i8*%F to i32*
%J=load i32,i32*%I,align 4
switch i32%J,label%K[
i32 4,label%cm
i32 3,label%cl
i32 1,label%ce
i32 5,label%cd
i32 2,label%bb
i32 0,label%ad
i32 6,label%ac
]
K:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
call void@sml_matchcomp_bug()
%L=load i8*,i8**@_SMLZ5Match,align 8
store i8*%L,i8**%c,align 8
%M=call i8*@sml_alloc(i32 inreg 20)#0
%N=getelementptr inbounds i8,i8*%M,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177296,i32*%O,align 4
store i8*%M,i8**%d,align 8
%P=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%Q=bitcast i8*%M to i8**
store i8*%P,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%M,i64 8
%S=bitcast i8*%R to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[82x i8]}>,<{[4x i8],i32,[82x i8]}>*@g,i64 0,i32 2,i64 0),i8**%S,align 8
%T=getelementptr inbounds i8,i8*%M,i64 16
%U=bitcast i8*%T to i32*
store i32 3,i32*%U,align 4
%V=call i8*@sml_alloc(i32 inreg 60)#0
%W=getelementptr inbounds i8,i8*%V,i64 -4
%X=bitcast i8*%W to i32*
store i32 1342177336,i32*%X,align 4
%Y=getelementptr inbounds i8,i8*%V,i64 56
%Z=bitcast i8*%Y to i32*
store i32 1,i32*%Z,align 4
%aa=load i8*,i8**%d,align 8
%ab=bitcast i8*%V to i8**
store i8*%aa,i8**%ab,align 8
call void@sml_raise(i8*inreg%V)#1
unreachable
ac:
store i8*null,i8**%g,align 8
br label%cp
ad:
%ae=getelementptr inbounds i8,i8*%F,i64 8
%af=bitcast i8*%ae to i8**
%ag=load i8*,i8**%af,align 8
%ah=getelementptr inbounds i8,i8*%ag,i64 8
%ai=bitcast i8*%ah to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%h,align 8
%ak=call fastcc i8*@_SMLFN13FunLocalLabel3Map4findE(i32 inreg 1,i32 inreg 8)
%al=getelementptr inbounds i8,i8*%ak,i64 16
%am=bitcast i8*%al to i8*(i8*,i8*)**
%an=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%am,align 8
%ao=bitcast i8*%ak to i8**
%ap=load i8*,i8**%ao,align 8
store i8*%ap,i8**%i,align 8
%aq=call i8*@sml_alloc(i32 inreg 20)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177296,i32*%as,align 4
%at=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%au=bitcast i8*%aq to i8**
store i8*%at,i8**%au,align 8
%av=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aw=getelementptr inbounds i8,i8*%aq,i64 8
%ax=bitcast i8*%aw to i8**
store i8*%av,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%aq,i64 16
%az=bitcast i8*%ay to i32*
store i32 3,i32*%az,align 4
%aA=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aB=call fastcc i8*%an(i8*inreg%aA,i8*inreg%aq)
%aC=icmp eq i8*%aB,null
br i1%aC,label%aD,label%aX
aD:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%aE=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%aE,i8**%c,align 8
%aF=call i8*@sml_alloc(i32 inreg 28)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177304,i32*%aH,align 4
store i8*%aF,i8**%d,align 8
%aI=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aJ=bitcast i8*%aF to i8**
store i8*%aI,i8**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aF,i64 8
%aL=bitcast i8*%aK to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@e,i64 0,i32 2,i64 0),i8**%aL,align 8
%aM=getelementptr inbounds i8,i8*%aF,i64 16
%aN=bitcast i8*%aM to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[16x i8]}>,<{[4x i8],i32,[16x i8]}>*@f,i64 0,i32 2,i64 0),i8**%aN,align 8
%aO=getelementptr inbounds i8,i8*%aF,i64 24
%aP=bitcast i8*%aO to i32*
store i32 7,i32*%aP,align 4
%aQ=call i8*@sml_alloc(i32 inreg 60)#0
%aR=getelementptr inbounds i8,i8*%aQ,i64 -4
%aS=bitcast i8*%aR to i32*
store i32 1342177336,i32*%aS,align 4
%aT=getelementptr inbounds i8,i8*%aQ,i64 56
%aU=bitcast i8*%aT to i32*
store i32 1,i32*%aU,align 4
%aV=load i8*,i8**%d,align 8
%aW=bitcast i8*%aQ to i8**
store i8*%aV,i8**%aW,align 8
call void@sml_raise(i8*inreg%aQ)#1
unreachable
aX:
%aY=bitcast i8*%aB to i8**
%aZ=load i8*,i8**%aY,align 8
%a0=bitcast i8*%aZ to i8**
%a1=load i8*,i8**%a0,align 8
%a2=icmp eq i8*%a1,null
br i1%a2,label%cn,label%a3
a3:
%a4=bitcast i8*%a1 to i8**
%a5=load i8*,i8**%a4,align 8
%a6=getelementptr inbounds i8,i8*%aZ,i64 8
%a7=bitcast i8*%a6 to i8**
%a8=load i8*,i8**%a7,align 8
store i8*%a5,i8**%g,align 8
store i8*%a8,i8**%h,align 8
br label%a9
a9:
%ba=phi i8*[%a8,%a3],[%cc,%bw],[%ck,%ce]
br label%u
bb:
%bc=getelementptr inbounds i8,i8*%F,i64 8
%bd=bitcast i8*%bc to i8**
%be=load i8*,i8**%bd,align 8
%bf=bitcast i8*%be to i8**
%bg=load i8*,i8**%bf,align 8
store i8*%bg,i8**%h,align 8
%bh=getelementptr inbounds i8,i8*%be,i64 16
%bi=bitcast i8*%bh to i8**
%bj=load i8*,i8**%bi,align 8
store i8*%bj,i8**%i,align 8
%bk=getelementptr inbounds i8,i8*%be,i64 24
%bl=bitcast i8*%bk to i32*
%bm=load i32,i32*%bl,align 4
%bn=icmp eq i32%bm,0
br i1%bn,label%bo,label%bw
bo:
%bp=call i8*@sml_alloc(i32 inreg 12)#0
%bq=getelementptr inbounds i8,i8*%bp,i64 -4
%br=bitcast i8*%bq to i32*
store i32 1342177288,i32*%br,align 4
%bs=load i8*,i8**%g,align 8
%bt=bitcast i8*%bp to i8**
store i8*%bs,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bp,i64 8
%bv=bitcast i8*%bu to i32*
store i32 1,i32*%bv,align 4
br label%bw
bw:
%bx=phi i8*[%bp,%bo],[null,%bb]
store i8*%bx,i8**%j,align 8
%by=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%bz=getelementptr inbounds i8,i8*%by,i64 16
%bA=bitcast i8*%bz to i8*(i8*,i8*)**
%bB=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bA,align 8
%bC=bitcast i8*%by to i8**
%bD=load i8*,i8**%bC,align 8
store i8*%bD,i8**%k,align 8
%bE=call i8*@sml_alloc(i32 inreg 12)#0
%bF=getelementptr inbounds i8,i8*%bE,i64 -4
%bG=bitcast i8*%bF to i32*
store i32 1342177288,i32*%bG,align 4
store i8*%bE,i8**%l,align 8
%bH=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bI=bitcast i8*%bE to i8**
store i8*%bH,i8**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bE,i64 8
%bK=bitcast i8*%bJ to i32*
store i32 1,i32*%bK,align 4
%bL=call i8*@sml_alloc(i32 inreg 28)#0
%bM=getelementptr inbounds i8,i8*%bL,i64 -4
%bN=bitcast i8*%bM to i32*
store i32 1342177304,i32*%bN,align 4
%bO=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%bP=bitcast i8*%bL to i8**
store i8*%bO,i8**%bP,align 8
%bQ=getelementptr inbounds i8,i8*%bL,i64 8
%bR=bitcast i8*%bQ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7blocks2_121 to void(...)*),void(...)**%bR,align 8
%bS=getelementptr inbounds i8,i8*%bL,i64 16
%bT=bitcast i8*%bS to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7blocks2_121 to void(...)*),void(...)**%bT,align 8
%bU=getelementptr inbounds i8,i8*%bL,i64 24
%bV=bitcast i8*%bU to i32*
store i32 -2147483647,i32*%bV,align 4
%bW=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%bX=call fastcc i8*%bB(i8*inreg%bW,i8*inreg%bL)
%bY=getelementptr inbounds i8,i8*%bX,i64 16
%bZ=bitcast i8*%bY to i8*(i8*,i8*)**
%b0=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bZ,align 8
%b1=bitcast i8*%bX to i8**
%b2=load i8*,i8**%b1,align 8
%b3=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%b4=call fastcc i8*%b0(i8*inreg%b2,i8*inreg%b3)
%b5=getelementptr inbounds i8,i8*%b4,i64 16
%b6=bitcast i8*%b5 to i8*(i8*,i8*)**
%b7=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%b6,align 8
%b8=bitcast i8*%b4 to i8**
%b9=load i8*,i8**%b8,align 8
%ca=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cb=call fastcc i8*%b7(i8*inreg%b9,i8*inreg%ca)
%cc=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*%cb,i8**%g,align 8
store i8*%cc,i8**%h,align 8
br label%a9
cd:
store i8*null,i8**%g,align 8
br label%cp
ce:
%cf=getelementptr inbounds i8,i8*%F,i64 8
%cg=bitcast i8*%cf to i8**
%ch=load i8*,i8**%cg,align 8
%ci=getelementptr inbounds i8,i8*%ch,i64 40
%cj=bitcast i8*%ci to i8**
%ck=load i8*,i8**%cj,align 8
store i8*%ck,i8**%h,align 8
br label%a9
cl:
store i8*null,i8**%g,align 8
br label%cp
cm:
store i8*null,i8**%g,align 8
br label%cp
cn:
%co=load i8*,i8**%f,align 8
ret i8*%co
cp:
%cq=load i8*,i8**%f,align 8
%cr=call fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_112(i8*inreg%cq)
%cs=icmp eq i32%cr,0
br i1%cs,label%c6,label%ct
ct:
store i8*null,i8**%f,align 8
%cu=call i8*@sml_alloc(i32 inreg 12)#0
%cv=getelementptr inbounds i8,i8*%cu,i64 -4
%cw=bitcast i8*%cv to i32*
store i32 1342177288,i32*%cw,align 4
store i8*%cu,i8**%f,align 8
%cx=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cy=bitcast i8*%cu to i8**
store i8*%cx,i8**%cy,align 8
%cz=getelementptr inbounds i8,i8*%cu,i64 8
%cA=bitcast i8*%cz to i32*
store i32 1,i32*%cA,align 4
%cB=call i8*@sml_alloc(i32 inreg 20)#0
%cC=getelementptr inbounds i8,i8*%cB,i64 -4
%cD=bitcast i8*%cC to i32*
store i32 1342177296,i32*%cD,align 4
store i8*%cB,i8**%c,align 8
%cE=getelementptr inbounds i8,i8*%cB,i64 4
%cF=bitcast i8*%cE to i32*
store i32 0,i32*%cF,align 1
%cG=bitcast i8*%cB to i32*
store i32 5,i32*%cG,align 4
%cH=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cI=getelementptr inbounds i8,i8*%cB,i64 8
%cJ=bitcast i8*%cI to i8**
store i8*%cH,i8**%cJ,align 8
%cK=getelementptr inbounds i8,i8*%cB,i64 16
%cL=bitcast i8*%cK to i32*
store i32 2,i32*%cL,align 4
%cM=call i8*@sml_alloc(i32 inreg 20)#0
%cN=getelementptr inbounds i8,i8*%cM,i64 -4
%cO=bitcast i8*%cN to i32*
store i32 1342177296,i32*%cO,align 4
store i8*%cM,i8**%f,align 8
%cP=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cQ=bitcast i8*%cM to i8**
store i8*%cP,i8**%cQ,align 8
%cR=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cS=getelementptr inbounds i8,i8*%cM,i64 8
%cT=bitcast i8*%cS to i8**
store i8*%cR,i8**%cT,align 8
%cU=getelementptr inbounds i8,i8*%cM,i64 16
%cV=bitcast i8*%cU to i32*
store i32 3,i32*%cV,align 4
%cW=call i8*@sml_alloc(i32 inreg 20)#0
%cX=getelementptr inbounds i8,i8*%cW,i64 -4
%cY=bitcast i8*%cX to i32*
store i32 1342177296,i32*%cY,align 4
%cZ=load i8*,i8**%f,align 8
%c0=bitcast i8*%cW to i8**
store i8*%cZ,i8**%c0,align 8
%c1=load i8*,i8**%e,align 8
%c2=getelementptr inbounds i8,i8*%cW,i64 8
%c3=bitcast i8*%c2 to i8**
store i8*%c1,i8**%c3,align 8
%c4=getelementptr inbounds i8,i8*%cW,i64 16
%c5=bitcast i8*%c4 to i32*
store i32 3,i32*%c5,align 4
ret i8*%cW
c6:
%c7=load i8*,i8**%f,align 8
ret i8*%c7
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport13compileTopdecE_128(i8*inreg%a)#2 gc"smlsharp"{
s:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
store i8*%a,i8**%b,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%q,label%o
o:
call void@sml_check(i32 inreg%m)
%p=load i8*,i8**%b,align 8
br label%q
q:
%r=phi i8*[%p,%o],[%a,%s]
%t=bitcast i8*%r to i32*
%u=load i32,i32*%t,align 4
switch i32%u,label%v[
i32 1,label%bc
i32 0,label%N
]
v:
call void@sml_matchcomp_bug()
%w=load i8*,i8**@_SMLZ5Match,align 8
store i8*%w,i8**%b,align 8
%x=call i8*@sml_alloc(i32 inreg 20)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177296,i32*%z,align 4
store i8*%x,i8**%c,align 8
%A=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@h,i64 0,i32 2,i64 0),i8**%D,align 8
%E=getelementptr inbounds i8,i8*%x,i64 16
%F=bitcast i8*%E to i32*
store i32 3,i32*%F,align 4
%G=call i8*@sml_alloc(i32 inreg 60)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177336,i32*%I,align 4
%J=getelementptr inbounds i8,i8*%G,i64 56
%K=bitcast i8*%J to i32*
store i32 1,i32*%K,align 4
%L=load i8*,i8**%c,align 8
%M=bitcast i8*%G to i8**
store i8*%L,i8**%M,align 8
call void@sml_raise(i8*inreg%G)#1
unreachable
N:
%O=getelementptr inbounds i8,i8*%r,i64 8
%P=bitcast i8*%O to i8**
%Q=load i8*,i8**%P,align 8
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%b,align 8
%T=getelementptr inbounds i8,i8*%Q,i64 8
%U=bitcast i8*%T to i8**
%V=load i8*,i8**%U,align 8
store i8*%V,i8**%c,align 8
%W=getelementptr inbounds i8,i8*%Q,i64 16
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
%Z=getelementptr inbounds i8,i8*%Q,i64 24
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
store i8*%ab,i8**%d,align 8
%ac=getelementptr inbounds i8,i8*%Q,i64 32
%ad=bitcast i8*%ac to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%e,align 8
%af=getelementptr inbounds i8,i8*%Q,i64 40
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%f,align 8
%ai=getelementptr inbounds i8,i8*%Q,i64 48
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
store i8*%ak,i8**%g,align 8
%al=getelementptr inbounds i8,i8*%Q,i64 56
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%h,align 8
%ao=getelementptr inbounds i8,i8*%Q,i64 64
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
store i8*%aq,i8**%i,align 8
%ar=getelementptr inbounds i8,i8*%Q,i64 72
%as=bitcast i8*%ar to i8**
%at=load i8*,i8**%as,align 8
store i8*%at,i8**%j,align 8
%au=call fastcc i8*@_SMLLLN18ConcurrencySupport11compileBodyE_125(i8*inreg%ab,i8*inreg%Y)
store i8*%au,i8**%k,align 8
%av=call i8*@sml_alloc(i32 inreg 84)#0
%aw=getelementptr inbounds i8,i8*%av,i64 -4
%ax=bitcast i8*%aw to i32*
store i32 1342177360,i32*%ax,align 4
store i8*%av,i8**%l,align 8
%ay=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%az=bitcast i8*%av to i8**
store i8*%ay,i8**%az,align 8
%aA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aB=getelementptr inbounds i8,i8*%av,i64 8
%aC=bitcast i8*%aB to i8**
store i8*%aA,i8**%aC,align 8
%aD=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%aE=getelementptr inbounds i8,i8*%av,i64 16
%aF=bitcast i8*%aE to i8**
store i8*%aD,i8**%aF,align 8
%aG=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aH=getelementptr inbounds i8,i8*%av,i64 24
%aI=bitcast i8*%aH to i8**
store i8*%aG,i8**%aI,align 8
%aJ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aK=getelementptr inbounds i8,i8*%av,i64 32
%aL=bitcast i8*%aK to i8**
store i8*%aJ,i8**%aL,align 8
%aM=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aN=getelementptr inbounds i8,i8*%av,i64 40
%aO=bitcast i8*%aN to i8**
store i8*%aM,i8**%aO,align 8
%aP=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aQ=getelementptr inbounds i8,i8*%av,i64 48
%aR=bitcast i8*%aQ to i8**
store i8*%aP,i8**%aR,align 8
%aS=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aT=getelementptr inbounds i8,i8*%av,i64 56
%aU=bitcast i8*%aT to i8**
store i8*%aS,i8**%aU,align 8
%aV=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aW=getelementptr inbounds i8,i8*%av,i64 64
%aX=bitcast i8*%aW to i8**
store i8*%aV,i8**%aX,align 8
%aY=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%aZ=getelementptr inbounds i8,i8*%av,i64 72
%a0=bitcast i8*%aZ to i8**
store i8*%aY,i8**%a0,align 8
%a1=getelementptr inbounds i8,i8*%av,i64 80
%a2=bitcast i8*%a1 to i32*
store i32 1023,i32*%a2,align 4
%a3=call i8*@sml_alloc(i32 inreg 20)#0
%a4=getelementptr inbounds i8,i8*%a3,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177296,i32*%a5,align 4
%a6=bitcast i8*%a3 to i64*
store i64 0,i64*%a6,align 4
%a7=load i8*,i8**%l,align 8
%a8=getelementptr inbounds i8,i8*%a3,i64 8
%a9=bitcast i8*%a8 to i8**
store i8*%a7,i8**%a9,align 8
%ba=getelementptr inbounds i8,i8*%a3,i64 16
%bb=bitcast i8*%ba to i32*
store i32 2,i32*%bb,align 4
ret i8*%a3
bc:
%bd=getelementptr inbounds i8,i8*%r,i64 8
%be=bitcast i8*%bd to i8**
%bf=load i8*,i8**%be,align 8
%bg=bitcast i8*%bf to i8**
%bh=load i8*,i8**%bg,align 8
store i8*%bh,i8**%b,align 8
%bi=getelementptr inbounds i8,i8*%bf,i64 8
%bj=bitcast i8*%bi to i8**
%bk=load i8*,i8**%bj,align 8
%bl=getelementptr inbounds i8,i8*%bf,i64 16
%bm=bitcast i8*%bl to i8**
%bn=load i8*,i8**%bm,align 8
store i8*%bn,i8**%c,align 8
%bo=getelementptr inbounds i8,i8*%bf,i64 24
%bp=bitcast i8*%bo to i8**
%bq=load i8*,i8**%bp,align 8
store i8*%bq,i8**%d,align 8
%br=getelementptr inbounds i8,i8*%bf,i64 32
%bs=bitcast i8*%br to i32*
%bt=load i32,i32*%bs,align 4
%bu=getelementptr inbounds i8,i8*%bf,i64 40
%bv=bitcast i8*%bu to i8**
%bw=load i8*,i8**%bv,align 8
store i8*%bw,i8**%e,align 8
%bx=getelementptr inbounds i8,i8*%bf,i64 48
%by=bitcast i8*%bx to i8**
%bz=load i8*,i8**%by,align 8
store i8*%bz,i8**%f,align 8
%bA=getelementptr inbounds i8,i8*%bf,i64 56
%bB=bitcast i8*%bA to i8**
%bC=load i8*,i8**%bB,align 8
store i8*%bC,i8**%g,align 8
%bD=getelementptr inbounds i8,i8*%bf,i64 64
%bE=bitcast i8*%bD to i8**
%bF=load i8*,i8**%bE,align 8
store i8*%bF,i8**%h,align 8
%bG=getelementptr inbounds i8,i8*%bf,i64 72
%bH=bitcast i8*%bG to i8**
%bI=load i8*,i8**%bH,align 8
store i8*%bI,i8**%i,align 8
%bJ=icmp eq i32%bt,0
br i1%bJ,label%bM,label%bK
bK:
%bL=call fastcc i8*@_SMLLLN18ConcurrencySupport11compileBodyE_125(i8*inreg null,i8*inreg%bk)
br label%bM
bM:
%bN=phi i8*[%bL,%bK],[%bk,%bc]
store i8*%bN,i8**%j,align 8
%bO=call i8*@sml_alloc(i32 inreg 84)#0
%bP=getelementptr inbounds i8,i8*%bO,i64 -4
%bQ=bitcast i8*%bP to i32*
store i32 1342177360,i32*%bQ,align 4
store i8*%bO,i8**%k,align 8
%bR=getelementptr inbounds i8,i8*%bO,i64 36
%bS=bitcast i8*%bR to i32*
store i32 0,i32*%bS,align 1
%bT=load i8*,i8**%b,align 8
%bU=bitcast i8*%bO to i8**
store i8*null,i8**%b,align 8
store i8*%bT,i8**%bU,align 8
%bV=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bW=getelementptr inbounds i8,i8*%bO,i64 8
%bX=bitcast i8*%bW to i8**
store i8*%bV,i8**%bX,align 8
%bY=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bZ=getelementptr inbounds i8,i8*%bO,i64 16
%b0=bitcast i8*%bZ to i8**
store i8*%bY,i8**%b0,align 8
%b1=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%b2=getelementptr inbounds i8,i8*%bO,i64 24
%b3=bitcast i8*%b2 to i8**
store i8*%b1,i8**%b3,align 8
%b4=getelementptr inbounds i8,i8*%bO,i64 32
%b5=bitcast i8*%b4 to i32*
store i32 0,i32*%b5,align 4
%b6=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%b7=getelementptr inbounds i8,i8*%bO,i64 40
%b8=bitcast i8*%b7 to i8**
store i8*%b6,i8**%b8,align 8
%b9=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ca=getelementptr inbounds i8,i8*%bO,i64 48
%cb=bitcast i8*%ca to i8**
store i8*%b9,i8**%cb,align 8
%cc=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cd=getelementptr inbounds i8,i8*%bO,i64 56
%ce=bitcast i8*%cd to i8**
store i8*%cc,i8**%ce,align 8
%cf=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cg=getelementptr inbounds i8,i8*%bO,i64 64
%ch=bitcast i8*%cg to i8**
store i8*%cf,i8**%ch,align 8
%ci=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cj=getelementptr inbounds i8,i8*%bO,i64 72
%ck=bitcast i8*%cj to i8**
store i8*%ci,i8**%ck,align 8
%cl=getelementptr inbounds i8,i8*%bO,i64 80
%cm=bitcast i8*%cl to i32*
store i32 1007,i32*%cm,align 4
%cn=call i8*@sml_alloc(i32 inreg 20)#0
%co=bitcast i8*%cn to i32*
%cp=getelementptr inbounds i8,i8*%cn,i64 -4
%cq=bitcast i8*%cp to i32*
store i32 1342177296,i32*%cq,align 4
%cr=getelementptr inbounds i8,i8*%cn,i64 4
%cs=bitcast i8*%cr to i32*
store i32 0,i32*%cs,align 1
store i32 1,i32*%co,align 4
%ct=load i8*,i8**%k,align 8
%cu=getelementptr inbounds i8,i8*%cn,i64 8
%cv=bitcast i8*%cu to i8**
store i8*%ct,i8**%cv,align 8
%cw=getelementptr inbounds i8,i8*%cn,i64 16
%cx=bitcast i8*%cw to i32*
store i32 2,i32*%cx,align 4
ret i8*%cn
}
define fastcc i8*@_SMLFN18ConcurrencySupport13insertCheckGCE(i8*inreg%a)#2 gc"smlsharp"{
n:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%b,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%b,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
%o=bitcast i8*%m to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%b,align 8
%q=getelementptr inbounds i8,i8*%m,i64 8
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%c,align 8
%t=getelementptr inbounds i8,i8*%m,i64 16
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%d,align 8
%w=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%x=getelementptr inbounds i8,i8*%w,i64 16
%y=bitcast i8*%x to i8*(i8*,i8*)**
%z=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%y,align 8
%A=bitcast i8*%w to i8**
%B=load i8*,i8**%A,align 8
%C=call fastcc i8*%z(i8*inreg%B,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@i,i64 0,i32 2)to i8*))
%D=getelementptr inbounds i8,i8*%C,i64 16
%E=bitcast i8*%D to i8*(i8*,i8*)**
%F=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%E,align 8
%G=bitcast i8*%C to i8**
%H=load i8*,i8**%G,align 8
%I=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%J=call fastcc i8*%F(i8*inreg%H,i8*inreg%I)
store i8*%J,i8**%c,align 8
%K=load i8*,i8**%d,align 8
%L=bitcast i8*%K to i8**
%M=load i8*,i8**%L,align 8
%N=getelementptr inbounds i8,i8*%K,i64 8
%O=bitcast i8*%N to i8**
%P=load i8*,i8**%O,align 8
store i8*%P,i8**%e,align 8
%Q=getelementptr inbounds i8,i8*%K,i64 16
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%d,align 8
%T=call fastcc i8*@_SMLLLN18ConcurrencySupport11compileBodyE_125(i8*inreg%P,i8*inreg%M)
store i8*%T,i8**%f,align 8
%U=call i8*@sml_alloc(i32 inreg 28)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177304,i32*%W,align 4
store i8*%U,i8**%g,align 8
%X=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%Y=bitcast i8*%U to i8**
store i8*%X,i8**%Y,align 8
%Z=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aa=getelementptr inbounds i8,i8*%U,i64 8
%ab=bitcast i8*%aa to i8**
store i8*%Z,i8**%ab,align 8
%ac=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ad=getelementptr inbounds i8,i8*%U,i64 16
%ae=bitcast i8*%ad to i8**
store i8*%ac,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%U,i64 24
%ag=bitcast i8*%af to i32*
store i32 7,i32*%ag,align 4
%ah=call i8*@sml_alloc(i32 inreg 28)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177304,i32*%aj,align 4
%ak=load i8*,i8**%b,align 8
%al=bitcast i8*%ah to i8**
store i8*%ak,i8**%al,align 8
%am=load i8*,i8**%c,align 8
%an=getelementptr inbounds i8,i8*%ah,i64 8
%ao=bitcast i8*%an to i8**
store i8*%am,i8**%ao,align 8
%ap=load i8*,i8**%g,align 8
%aq=getelementptr inbounds i8,i8*%ah,i64 16
%ar=bitcast i8*%aq to i8**
store i8*%ap,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%ah,i64 24
%at=bitcast i8*%as to i32*
store i32 7,i32*%at,align 4
ret i8*%ah
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport7hasCallE_133(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLLLN18ConcurrencySupport7hasCallE_118(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport13compileTopdecE_136(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLLN18ConcurrencySupport13compileTopdecE_128(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN18ConcurrencySupport13insertCheckGCE_137(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN18ConcurrencySupport13insertCheckGCE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
