@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[59x i8]}><{[4x i8]zeroinitializer,i32 -2147483589,[59x i8]c"src/compiler/compilerIRs/absyn/main/Absyn.sml:952.6(26711)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN5Absyn9getLocExpE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN5Absyn9getLocExpE_75 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[59x i8]}><{[4x i8]zeroinitializer,i32 -2147483589,[59x i8]c"src/compiler/compilerIRs/absyn/main/Absyn.sml:988.6(27988)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN5Absyn9getLocPatE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN5Absyn9getLocPatE_76 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN5Absyn9getLocExpE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN5Absyn9getLocPatE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SML_ftab041042724cd69fea_Absyn=external global i8
@e=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN6Symbol15longsymbolToLocE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main44ca35c4c731682b_Symbol()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load44ca35c4c731682b_Symbol(i8*)local_unnamed_addr
define private void@_SML_tabb041042724cd69fea_Absyn()#3{
unreachable
}
define void@_SML_load041042724cd69fea_Absyn(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@e,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@e,align 1
tail call void@_SML_load44ca35c4c731682b_Symbol(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb041042724cd69fea_Absyn,i8*@_SML_ftab041042724cd69fea_Absyn,i8*null)#0
ret void
}
define void@_SML_main041042724cd69fea_Absyn()local_unnamed_addr#2 gc"smlsharp"{
tail call void@_SML_main44ca35c4c731682b_Symbol()#2
ret void
}
define fastcc i8*@_SMLFN5Absyn9getLocExpE(i8*inreg%a)#2 gc"smlsharp"{
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
i32 3,label%do
i32 28,label%dh
i32 15,label%dc
i32 20,label%c5
i32 22,label%cY
i32 24,label%cR
i32 25,label%cK
i32 23,label%cD
i32 30,label%cw
i32 19,label%cp
i32 27,label%ci
i32 0,label%cb
i32 31,label%b4
i32 2,label%bX
i32 4,label%bQ
i32 14,label%bJ
i32 21,label%bC
i32 16,label%bv
i32 32,label%bo
i32 1,label%bh
i32 12,label%ba
i32 18,label%a3
i32 11,label%aW
i32 29,label%aP
i32 13,label%aI
i32 17,label%aB
i32 5,label%au
i32 7,label%an
i32 8,label%ag
i32 9,label%Z
i32 10,label%S
i32 6,label%L
i32 26,label%E
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
store i8*getelementptr inbounds(<{[4x i8],i32,[59x i8]}>,<{[4x i8],i32,[59x i8]}>*@a,i64 0,i32 2,i64 0),i8**%u,align 8
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
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
ret i8*%K
L:
%M=getelementptr inbounds i8,i8*%i,i64 8
%N=bitcast i8*%M to i8**
%O=load i8*,i8**%N,align 8
%P=getelementptr inbounds i8,i8*%O,i64 16
%Q=bitcast i8*%P to i8**
%R=load i8*,i8**%Q,align 8
ret i8*%R
S:
%T=getelementptr inbounds i8,i8*%i,i64 8
%U=bitcast i8*%T to i8**
%V=load i8*,i8**%U,align 8
%W=getelementptr inbounds i8,i8*%V,i64 16
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
ag:
%ah=getelementptr inbounds i8,i8*%i,i64 8
%ai=bitcast i8*%ah to i8**
%aj=load i8*,i8**%ai,align 8
%ak=getelementptr inbounds i8,i8*%aj,i64 8
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
ret i8*%am
an:
%ao=getelementptr inbounds i8,i8*%i,i64 8
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8**
%at=load i8*,i8**%as,align 8
ret i8*%at
au:
%av=getelementptr inbounds i8,i8*%i,i64 8
%aw=bitcast i8*%av to i8**
%ax=load i8*,i8**%aw,align 8
%ay=getelementptr inbounds i8,i8*%ax,i64 16
%az=bitcast i8*%ay to i8**
%aA=load i8*,i8**%az,align 8
ret i8*%aA
aB:
%aC=getelementptr inbounds i8,i8*%i,i64 8
%aD=bitcast i8*%aC to i8**
%aE=load i8*,i8**%aD,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 24
%aG=bitcast i8*%aF to i8**
%aH=load i8*,i8**%aG,align 8
ret i8*%aH
aI:
%aJ=getelementptr inbounds i8,i8*%i,i64 8
%aK=bitcast i8*%aJ to i8**
%aL=load i8*,i8**%aK,align 8
%aM=getelementptr inbounds i8,i8*%aL,i64 8
%aN=bitcast i8*%aM to i8**
%aO=load i8*,i8**%aN,align 8
ret i8*%aO
aP:
%aQ=getelementptr inbounds i8,i8*%i,i64 8
%aR=bitcast i8*%aQ to i8**
%aS=load i8*,i8**%aR,align 8
%aT=getelementptr inbounds i8,i8*%aS,i64 8
%aU=bitcast i8*%aT to i8**
%aV=load i8*,i8**%aU,align 8
ret i8*%aV
aW:
%aX=getelementptr inbounds i8,i8*%i,i64 8
%aY=bitcast i8*%aX to i8**
%aZ=load i8*,i8**%aY,align 8
%a0=getelementptr inbounds i8,i8*%aZ,i64 16
%a1=bitcast i8*%a0 to i8**
%a2=load i8*,i8**%a1,align 8
ret i8*%a2
a3:
%a4=getelementptr inbounds i8,i8*%i,i64 8
%a5=bitcast i8*%a4 to i8**
%a6=load i8*,i8**%a5,align 8
%a7=getelementptr inbounds i8,i8*%a6,i64 16
%a8=bitcast i8*%a7 to i8**
%a9=load i8*,i8**%a8,align 8
ret i8*%a9
ba:
%bb=getelementptr inbounds i8,i8*%i,i64 8
%bc=bitcast i8*%bb to i8**
%bd=load i8*,i8**%bc,align 8
%be=getelementptr inbounds i8,i8*%bd,i64 8
%bf=bitcast i8*%be to i8**
%bg=load i8*,i8**%bf,align 8
ret i8*%bg
bh:
%bi=getelementptr inbounds i8,i8*%i,i64 8
%bj=bitcast i8*%bi to i8**
%bk=load i8*,i8**%bj,align 8
%bl=getelementptr inbounds i8,i8*%bk,i64 16
%bm=bitcast i8*%bl to i8**
%bn=load i8*,i8**%bm,align 8
ret i8*%bn
bo:
%bp=getelementptr inbounds i8,i8*%i,i64 8
%bq=bitcast i8*%bp to i8**
%br=load i8*,i8**%bq,align 8
%bs=getelementptr inbounds i8,i8*%br,i64 16
%bt=bitcast i8*%bs to i8**
%bu=load i8*,i8**%bt,align 8
ret i8*%bu
bv:
%bw=getelementptr inbounds i8,i8*%i,i64 8
%bx=bitcast i8*%bw to i8**
%by=load i8*,i8**%bx,align 8
%bz=getelementptr inbounds i8,i8*%by,i64 24
%bA=bitcast i8*%bz to i8**
%bB=load i8*,i8**%bA,align 8
ret i8*%bB
bC:
%bD=getelementptr inbounds i8,i8*%i,i64 8
%bE=bitcast i8*%bD to i8**
%bF=load i8*,i8**%bE,align 8
%bG=getelementptr inbounds i8,i8*%bF,i64 8
%bH=bitcast i8*%bG to i8**
%bI=load i8*,i8**%bH,align 8
ret i8*%bI
bJ:
%bK=getelementptr inbounds i8,i8*%i,i64 8
%bL=bitcast i8*%bK to i8**
%bM=load i8*,i8**%bL,align 8
%bN=getelementptr inbounds i8,i8*%bM,i64 16
%bO=bitcast i8*%bN to i8**
%bP=load i8*,i8**%bO,align 8
ret i8*%bP
bQ:
%bR=getelementptr inbounds i8,i8*%i,i64 8
%bS=bitcast i8*%bR to i8**
%bT=load i8*,i8**%bS,align 8
%bU=getelementptr inbounds i8,i8*%bT,i64 16
%bV=bitcast i8*%bU to i8**
%bW=load i8*,i8**%bV,align 8
ret i8*%bW
bX:
%bY=getelementptr inbounds i8,i8*%i,i64 8
%bZ=bitcast i8*%bY to i8**
%b0=load i8*,i8**%bZ,align 8
%b1=getelementptr inbounds i8,i8*%b0,i64 16
%b2=bitcast i8*%b1 to i8**
%b3=load i8*,i8**%b2,align 8
ret i8*%b3
b4:
%b5=getelementptr inbounds i8,i8*%i,i64 8
%b6=bitcast i8*%b5 to i8**
%b7=load i8*,i8**%b6,align 8
%b8=getelementptr inbounds i8,i8*%b7,i64 16
%b9=bitcast i8*%b8 to i8**
%ca=load i8*,i8**%b9,align 8
ret i8*%ca
cb:
%cc=getelementptr inbounds i8,i8*%i,i64 8
%cd=bitcast i8*%cc to i8**
%ce=load i8*,i8**%cd,align 8
%cf=getelementptr inbounds i8,i8*%ce,i64 8
%cg=bitcast i8*%cf to i8**
%ch=load i8*,i8**%cg,align 8
ret i8*%ch
ci:
%cj=getelementptr inbounds i8,i8*%i,i64 8
%ck=bitcast i8*%cj to i8**
%cl=load i8*,i8**%ck,align 8
%cm=getelementptr inbounds i8,i8*%cl,i64 8
%cn=bitcast i8*%cm to i8**
%co=load i8*,i8**%cn,align 8
ret i8*%co
cp:
%cq=getelementptr inbounds i8,i8*%i,i64 8
%cr=bitcast i8*%cq to i8**
%cs=load i8*,i8**%cr,align 8
%ct=getelementptr inbounds i8,i8*%cs,i64 8
%cu=bitcast i8*%ct to i8**
%cv=load i8*,i8**%cu,align 8
ret i8*%cv
cw:
%cx=getelementptr inbounds i8,i8*%i,i64 8
%cy=bitcast i8*%cx to i8**
%cz=load i8*,i8**%cy,align 8
%cA=getelementptr inbounds i8,i8*%cz,i64 8
%cB=bitcast i8*%cA to i8**
%cC=load i8*,i8**%cB,align 8
ret i8*%cC
cD:
%cE=getelementptr inbounds i8,i8*%i,i64 8
%cF=bitcast i8*%cE to i8**
%cG=load i8*,i8**%cF,align 8
%cH=getelementptr inbounds i8,i8*%cG,i64 8
%cI=bitcast i8*%cH to i8**
%cJ=load i8*,i8**%cI,align 8
ret i8*%cJ
cK:
%cL=getelementptr inbounds i8,i8*%i,i64 8
%cM=bitcast i8*%cL to i8**
%cN=load i8*,i8**%cM,align 8
%cO=getelementptr inbounds i8,i8*%cN,i64 16
%cP=bitcast i8*%cO to i8**
%cQ=load i8*,i8**%cP,align 8
ret i8*%cQ
cR:
%cS=getelementptr inbounds i8,i8*%i,i64 8
%cT=bitcast i8*%cS to i8**
%cU=load i8*,i8**%cT,align 8
%cV=getelementptr inbounds i8,i8*%cU,i64 16
%cW=bitcast i8*%cV to i8**
%cX=load i8*,i8**%cW,align 8
ret i8*%cX
cY:
%cZ=getelementptr inbounds i8,i8*%i,i64 8
%c0=bitcast i8*%cZ to i8**
%c1=load i8*,i8**%c0,align 8
%c2=getelementptr inbounds i8,i8*%c1,i64 8
%c3=bitcast i8*%c2 to i8**
%c4=load i8*,i8**%c3,align 8
ret i8*%c4
c5:
%c6=getelementptr inbounds i8,i8*%i,i64 8
%c7=bitcast i8*%c6 to i8**
%c8=load i8*,i8**%c7,align 8
%c9=getelementptr inbounds i8,i8*%c8,i64 8
%da=bitcast i8*%c9 to i8**
%db=load i8*,i8**%da,align 8
ret i8*%db
dc:
%dd=getelementptr inbounds i8,i8*%i,i64 8
%de=bitcast i8*%dd to i8**
%df=load i8*,i8**%de,align 8
%dg=tail call fastcc i8*@_SMLFN6Symbol15longsymbolToLocE(i8*inreg%df)
ret i8*%dg
dh:
%di=getelementptr inbounds i8,i8*%i,i64 8
%dj=bitcast i8*%di to i8**
%dk=load i8*,i8**%dj,align 8
%dl=getelementptr inbounds i8,i8*%dk,i64 8
%dm=bitcast i8*%dl to i8**
%dn=load i8*,i8**%dm,align 8
ret i8*%dn
do:
%dp=getelementptr inbounds i8,i8*%i,i64 8
%dq=bitcast i8*%dp to i8**
%dr=load i8*,i8**%dq,align 8
%ds=getelementptr inbounds i8,i8*%dr,i64 8
%dt=bitcast i8*%ds to i8**
%du=load i8*,i8**%dt,align 8
ret i8*%du
}
define fastcc i8*@_SMLFN5Absyn9getLocPatE(i8*inreg%a)#2 gc"smlsharp"{
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
i32 8,label%aG
i32 1,label%az
i32 2,label%au
i32 5,label%an
i32 6,label%ag
i32 4,label%Z
i32 0,label%S
i32 7,label%L
i32 3,label%E
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
store i8*getelementptr inbounds(<{[4x i8],i32,[59x i8]}>,<{[4x i8],i32,[59x i8]}>*@c,i64 0,i32 2,i64 0),i8**%u,align 8
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
%P=getelementptr inbounds i8,i8*%O,i64 16
%Q=bitcast i8*%P to i8**
%R=load i8*,i8**%Q,align 8
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
ag:
%ah=getelementptr inbounds i8,i8*%i,i64 8
%ai=bitcast i8*%ah to i8**
%aj=load i8*,i8**%ai,align 8
%ak=getelementptr inbounds i8,i8*%aj,i64 8
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
ret i8*%am
an:
%ao=getelementptr inbounds i8,i8*%i,i64 8
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8**
%at=load i8*,i8**%as,align 8
ret i8*%at
au:
%av=getelementptr inbounds i8,i8*%i,i64 8
%aw=bitcast i8*%av to i8***
%ax=load i8**,i8***%aw,align 8
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
ret i8*%aJ
}
define internal fastcc i8*@_SMLLN5Absyn9getLocExpE_75(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN5Absyn9getLocExpE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN5Absyn9getLocPatE_76(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN5Absyn9getLocPatE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
