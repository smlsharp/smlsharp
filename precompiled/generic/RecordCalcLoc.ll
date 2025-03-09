@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Loc5nolocE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[69x i8]}><{[4x i8]zeroinitializer,i32 -2147483579,[69x i8]c"src/compiler/compilerIRs/recordcalc/main/RecordCalcLoc.sml:11.6(167)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN13RecordCalcLoc6locExpE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13RecordCalcLoc6locExpE_57 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[69x i8]}><{[4x i8]zeroinitializer,i32 -2147483579,[69x i8]c"src/compiler/compilerIRs/recordcalc/main/RecordCalcLoc.sml:33.6(903)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN13RecordCalcLoc7locDeclE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13RecordCalcLoc7locDeclE_58 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN13RecordCalcLoc6locExpE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN13RecordCalcLoc7locDeclE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SML_ftab32de62036f27cc0f_RecordCalcLoc=external global i8
@e=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@_SML_main67a5b28ff146c353_Loc()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load67a5b28ff146c353_Loc(i8*)local_unnamed_addr
define private void@_SML_tabb32de62036f27cc0f_RecordCalcLoc()#3{
unreachable
}
define void@_SML_load32de62036f27cc0f_RecordCalcLoc(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@e,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@e,align 1
tail call void@_SML_load67a5b28ff146c353_Loc(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb32de62036f27cc0f_RecordCalcLoc,i8*@_SML_ftab32de62036f27cc0f_RecordCalcLoc,i8*null)#0
ret void
}
define void@_SML_main32de62036f27cc0f_RecordCalcLoc()local_unnamed_addr#2 gc"smlsharp"{
tail call void@_SML_main67a5b28ff146c353_Loc()#2
ret void
}
define fastcc i8*@_SMLFN13RecordCalcLoc6locExpE(i8*inreg%a)#2 gc"smlsharp"{
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
%k=bitcast i8*%i to i32*
%l=load i32,i32*%k,align 4
switch i32%l,label%m[
i32 18,label%bO
i32 15,label%bH
i32 4,label%bA
i32 5,label%bt
i32 0,label%bm
i32 16,label%bf
i32 11,label%a8
i32 13,label%a1
i32 14,label%aU
i32 10,label%aN
i32 9,label%aG
i32 12,label%az
i32 7,label%as
i32 17,label%al
i32 3,label%ag
i32 6,label%Z
i32 1,label%S
i32 2,label%L
i32 8,label%E
]
m:
call void@sml_matchcomp_bug()
%n=load i8*,i8**@_SMLZ5Match,align 8
store i8*%n,i8**%b,align 8
%o=call i8*@sml_alloc(i32 inreg 20)#0
%p=getelementptr inbounds i8,i8*%o,i64 -4
%q=bitcast i8*%p to i32*
store i32 1342177296,i32*%q,align 4
store i8*%o,i8**%c,align 8
%r=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%s=bitcast i8*%o to i8**
store i8*%r,i8**%s,align 8
%t=getelementptr inbounds i8,i8*%o,i64 8
%u=bitcast i8*%t to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[69x i8]}>,<{[4x i8],i32,[69x i8]}>*@a,i64 0,i32 2,i64 0),i8**%u,align 8
%v=getelementptr inbounds i8,i8*%o,i64 16
%w=bitcast i8*%v to i32*
store i32 3,i32*%w,align 4
%x=call i8*@sml_alloc(i32 inreg 60)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177336,i32*%z,align 4
%A=getelementptr inbounds i8,i8*%x,i64 56
%B=bitcast i8*%A to i32*
store i32 1,i32*%B,align 4
%C=load i8*,i8**%c,align 8
%D=bitcast i8*%x to i8**
store i8*%C,i8**%D,align 8
call void@sml_raise(i8*inreg%x)#1
unreachable
E:
%F=getelementptr inbounds i8,i8*%i,i64 8
%G=bitcast i8*%F to i8**
%H=load i8*,i8**%G,align 8
%I=getelementptr inbounds i8,i8*%H,i64 16
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
ret i8*%K
L:
%M=getelementptr inbounds i8,i8*%i,i64 8
%N=bitcast i8*%M to i8**
%O=load i8*,i8**%N,align 8
%P=getelementptr inbounds i8,i8*%O,i64 24
%Q=bitcast i8*%P to i8**
%R=load i8*,i8**%Q,align 8
ret i8*%R
S:
%T=getelementptr inbounds i8,i8*%i,i64 8
%U=bitcast i8*%T to i8**
%V=load i8*,i8**%U,align 8
%W=getelementptr inbounds i8,i8*%V,i64 24
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
ret i8*%Y
Z:
%aa=getelementptr inbounds i8,i8*%i,i64 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
%ad=getelementptr inbounds i8,i8*%ac,i64 24
%ae=bitcast i8*%ad to i8**
%af=load i8*,i8**%ae,align 8
ret i8*%af
ag:
%ah=getelementptr inbounds i8,i8*%i,i64 8
%ai=bitcast i8*%ah to i8***
%aj=load i8**,i8***%ai,align 8
%ak=load i8*,i8**%aj,align 8
ret i8*%ak
al:
%am=getelementptr inbounds i8,i8*%i,i64 8
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
%ap=getelementptr inbounds i8,i8*%ao,i64 16
%aq=bitcast i8*%ap to i8**
%ar=load i8*,i8**%aq,align 8
ret i8*%ar
as:
%at=getelementptr inbounds i8,i8*%i,i64 8
%au=bitcast i8*%at to i8**
%av=load i8*,i8**%au,align 8
%aw=getelementptr inbounds i8,i8*%av,i64 24
%ax=bitcast i8*%aw to i8**
%ay=load i8*,i8**%ax,align 8
ret i8*%ay
az:
%aA=getelementptr inbounds i8,i8*%i,i64 8
%aB=bitcast i8*%aA to i8**
%aC=load i8*,i8**%aB,align 8
%aD=getelementptr inbounds i8,i8*%aC,i64 8
%aE=bitcast i8*%aD to i8**
%aF=load i8*,i8**%aE,align 8
ret i8*%aF
aG:
%aH=getelementptr inbounds i8,i8*%i,i64 8
%aI=bitcast i8*%aH to i8**
%aJ=load i8*,i8**%aI,align 8
%aK=getelementptr inbounds i8,i8*%aJ,i64 16
%aL=bitcast i8*%aK to i8**
%aM=load i8*,i8**%aL,align 8
ret i8*%aM
aN:
%aO=getelementptr inbounds i8,i8*%i,i64 8
%aP=bitcast i8*%aO to i8**
%aQ=load i8*,i8**%aP,align 8
%aR=getelementptr inbounds i8,i8*%aQ,i64 48
%aS=bitcast i8*%aR to i8**
%aT=load i8*,i8**%aS,align 8
ret i8*%aT
aU:
%aV=getelementptr inbounds i8,i8*%i,i64 8
%aW=bitcast i8*%aV to i8**
%aX=load i8*,i8**%aW,align 8
%aY=getelementptr inbounds i8,i8*%aX,i64 16
%aZ=bitcast i8*%aY to i8**
%a0=load i8*,i8**%aZ,align 8
ret i8*%a0
a1:
%a2=getelementptr inbounds i8,i8*%i,i64 8
%a3=bitcast i8*%a2 to i8**
%a4=load i8*,i8**%a3,align 8
%a5=getelementptr inbounds i8,i8*%a4,i64 8
%a6=bitcast i8*%a5 to i8**
%a7=load i8*,i8**%a6,align 8
ret i8*%a7
a8:
%a9=getelementptr inbounds i8,i8*%i,i64 8
%ba=bitcast i8*%a9 to i8**
%bb=load i8*,i8**%ba,align 8
%bc=getelementptr inbounds i8,i8*%bb,i64 32
%bd=bitcast i8*%bc to i8**
%be=load i8*,i8**%bd,align 8
ret i8*%be
bf:
%bg=getelementptr inbounds i8,i8*%i,i64 8
%bh=bitcast i8*%bg to i8**
%bi=load i8*,i8**%bh,align 8
%bj=getelementptr inbounds i8,i8*%bi,i64 32
%bk=bitcast i8*%bj to i8**
%bl=load i8*,i8**%bk,align 8
ret i8*%bl
bm:
%bn=getelementptr inbounds i8,i8*%i,i64 8
%bo=bitcast i8*%bn to i8**
%bp=load i8*,i8**%bo,align 8
%bq=getelementptr inbounds i8,i8*%bp,i64 32
%br=bitcast i8*%bq to i8**
%bs=load i8*,i8**%br,align 8
ret i8*%bs
bt:
%bu=getelementptr inbounds i8,i8*%i,i64 8
%bv=bitcast i8*%bu to i8**
%bw=load i8*,i8**%bv,align 8
%bx=getelementptr inbounds i8,i8*%bw,i64 40
%by=bitcast i8*%bx to i8**
%bz=load i8*,i8**%by,align 8
ret i8*%bz
bA:
%bB=getelementptr inbounds i8,i8*%i,i64 8
%bC=bitcast i8*%bB to i8**
%bD=load i8*,i8**%bC,align 8
%bE=getelementptr inbounds i8,i8*%bD,i64 8
%bF=bitcast i8*%bE to i8**
%bG=load i8*,i8**%bF,align 8
ret i8*%bG
bH:
%bI=getelementptr inbounds i8,i8*%i,i64 8
%bJ=bitcast i8*%bI to i8**
%bK=load i8*,i8**%bJ,align 8
%bL=getelementptr inbounds i8,i8*%bK,i64 8
%bM=bitcast i8*%bL to i8**
%bN=load i8*,i8**%bM,align 8
ret i8*%bN
bO:
%bP=getelementptr inbounds i8,i8*%i,i64 8
%bQ=bitcast i8*%bP to i8**
%bR=load i8*,i8**%bQ,align 8
%bS=getelementptr inbounds i8,i8*%bR,i64 8
%bT=bitcast i8*%bS to i8**
%bU=load i8*,i8**%bT,align 8
ret i8*%bU
}
define fastcc i8*@_SMLFN13RecordCalcLoc7locDeclE(i8*inreg%a)#2 gc"smlsharp"{
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
%k=bitcast i8*%i to i32*
%l=load i32,i32*%k,align 4
switch i32%l,label%m[
i32 2,label%Z
i32 3,label%S
i32 0,label%G
i32 1,label%E
]
m:
call void@sml_matchcomp_bug()
%n=load i8*,i8**@_SMLZ5Match,align 8
store i8*%n,i8**%b,align 8
%o=call i8*@sml_alloc(i32 inreg 20)#0
%p=getelementptr inbounds i8,i8*%o,i64 -4
%q=bitcast i8*%p to i32*
store i32 1342177296,i32*%q,align 4
store i8*%o,i8**%c,align 8
%r=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%s=bitcast i8*%o to i8**
store i8*%r,i8**%s,align 8
%t=getelementptr inbounds i8,i8*%o,i64 8
%u=bitcast i8*%t to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[69x i8]}>,<{[4x i8],i32,[69x i8]}>*@c,i64 0,i32 2,i64 0),i8**%u,align 8
%v=getelementptr inbounds i8,i8*%o,i64 16
%w=bitcast i8*%v to i32*
store i32 3,i32*%w,align 4
%x=call i8*@sml_alloc(i32 inreg 60)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177336,i32*%z,align 4
%A=getelementptr inbounds i8,i8*%x,i64 56
%B=bitcast i8*%A to i32*
store i32 1,i32*%B,align 4
%C=load i8*,i8**%c,align 8
%D=bitcast i8*%x to i8**
store i8*%C,i8**%D,align 8
call void@sml_raise(i8*inreg%x)#1
unreachable
E:
%F=load i8*,i8**@_SMLZN3Loc5nolocE,align 8
ret i8*%F
G:
%H=getelementptr inbounds i8,i8*%i,i64 8
%I=bitcast i8*%H to i8***
%J=load i8**,i8***%I,align 8
%K=load i8*,i8**%J,align 8
%L=icmp eq i8*%K,null
br i1%L,label%M,label%O
M:
%N=load i8*,i8**@_SMLZN3Loc5nolocE,align 8
ret i8*%N
O:
%P=bitcast i8*%K to i8**
%Q=load i8*,i8**%P,align 8
%R=tail call fastcc i8*@_SMLFN13RecordCalcLoc6locExpE(i8*inreg%Q)
ret i8*%R
S:
%T=getelementptr inbounds i8,i8*%i,i64 8
%U=bitcast i8*%T to i8**
%V=load i8*,i8**%U,align 8
%W=getelementptr inbounds i8,i8*%V,i64 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
ret i8*%Y
Z:
%aa=getelementptr inbounds i8,i8*%i,i64 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
%ad=getelementptr inbounds i8,i8*%ac,i64 8
%ae=bitcast i8*%ad to i8**
%af=load i8*,i8**%ae,align 8
ret i8*%af
}
define internal fastcc i8*@_SMLLLN13RecordCalcLoc6locExpE_57(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN13RecordCalcLoc6locExpE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN13RecordCalcLoc7locDeclE_58(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN13RecordCalcLoc7locDeclE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
