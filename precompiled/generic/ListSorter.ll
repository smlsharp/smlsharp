@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ9Subscript=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[61x i8]}><{[4x i8]zeroinitializer,i32 -2147483587,[61x i8]c"src/compiler/libs/list-utils/main/ListSorter.sml:44.24(1293)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[61x i8]}><{[4x i8]zeroinitializer,i32 -2147483587,[61x i8]c"src/compiler/libs/list-utils/main/ListSorter.sml:45.36(1354)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN10ListSorter4sortE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN10ListSorter4sortE_63 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN10ListSorter4sortE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SML_ftab92a9fd50084b022c_ListSorter=external global i8
@d=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN5Array5foldrE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Array8fromListE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainfd227ec42a85e2d0_Array()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loadfd227ec42a85e2d0_Array(i8*)local_unnamed_addr
define private void@_SML_tabb92a9fd50084b022c_ListSorter()#3{
unreachable
}
define void@_SML_load92a9fd50084b022c_ListSorter(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@d,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@d,align 1
tail call void@_SML_loadfd227ec42a85e2d0_Array(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb92a9fd50084b022c_ListSorter,i8*@_SML_ftab92a9fd50084b022c_ListSorter,i8*null)#0
ret void
}
define void@_SML_main92a9fd50084b022c_ListSorter()local_unnamed_addr#2 gc"smlsharp"{
tail call void@_SML_mainfd227ec42a85e2d0_Array()#2
ret void
}
define internal fastcc void@_SMLL4swap_43(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%f,align 8
%g=getelementptr inbounds i8,i8*%a,i64 12
%h=bitcast i8*%g to i32*
%i=load i32,i32*%h,align 4
%j=add i32%i,3
%k=sub i32 0,%i
%l=and i32%j,%k
%m=add i32%i,7
%n=add i32%m,%l
%o=and i32%n,-8
%p=lshr i32%l,3
%q=getelementptr inbounds i8,i8*%a,i64 8
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=shl i32%s,%p
%u=or i32%o,4
%v=bitcast i8*%b to i32*
%w=load i32,i32*%v,align 4
%x=getelementptr inbounds i8,i8*%b,i64 4
%y=bitcast i8*%x to i32*
%z=load i32,i32*%y,align 4
%A=icmp slt i32%w,0
br i1%A,label%ae,label%B
B:
%C=bitcast i8*%a to i32**
%D=load i32*,i32**%C,align 8
%E=getelementptr inbounds i32,i32*%D,i64 -1
%F=load i32,i32*%E,align 4
%G=and i32%F,268435455
%H=udiv i32%G,%i
%I=icmp slt i32%w,%H
%J=bitcast i32*%D to i8*
br i1%I,label%K,label%ae
K:
%L=bitcast i8**%c to i32**
store i32*%D,i32**%L,align 8
%M=icmp eq i32%s,0
br i1%M,label%T,label%N
N:
%O=mul i32%i,%w
%P=sext i32%O to i64
%Q=getelementptr inbounds i8,i8*%J,i64%P
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
br label%ab
T:
%U=call i8*@sml_alloc(i32 inreg%i)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32%i,i32*%W,align 4
%X=load i8*,i8**%c,align 8
%Y=mul i32%i,%w
%Z=sext i32%Y to i64
%aa=getelementptr inbounds i8,i8*%X,i64%Z
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%U,i8*%aa,i32%i,i1 false)
br label%ab
ab:
%ac=phi i8*[%S,%N],[%U,%T]
store i8*%ac,i8**%c,align 8
%ad=icmp slt i32%z,0
br i1%ad,label%bn,label%aw
ae:
store i8*null,i8**%f,align 8
%af=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%af,i8**%c,align 8
%ag=call i8*@sml_alloc(i32 inreg 20)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177296,i32*%ai,align 4
store i8*%ag,i8**%d,align 8
%aj=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=getelementptr inbounds i8,i8*%ag,i64 8
%am=bitcast i8*%al to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%am,align 8
%an=getelementptr inbounds i8,i8*%ag,i64 16
%ao=bitcast i8*%an to i32*
store i32 3,i32*%ao,align 4
%ap=call i8*@sml_alloc(i32 inreg 60)#0
%aq=getelementptr inbounds i8,i8*%ap,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 1342177336,i32*%ar,align 4
%as=getelementptr inbounds i8,i8*%ap,i64 56
%at=bitcast i8*%as to i32*
store i32 1,i32*%at,align 4
%au=load i8*,i8**%d,align 8
%av=bitcast i8*%ap to i8**
store i8*%au,i8**%av,align 8
call void@sml_raise(i8*inreg%ap)#1
unreachable
aw:
%ax=load i8*,i8**%f,align 8
%ay=bitcast i8*%ax to i32**
%az=load i32*,i32**%ay,align 8
%aA=getelementptr inbounds i32,i32*%az,i64 -1
%aB=load i32,i32*%aA,align 4
%aC=and i32%aB,268435455
%aD=getelementptr inbounds i8,i8*%ax,i64 12
%aE=bitcast i8*%aD to i32*
%aF=load i32,i32*%aE,align 4
%aG=udiv i32%aC,%aF
%aH=icmp slt i32%z,%aG
%aI=bitcast i32*%az to i8*
br i1%aH,label%aJ,label%bn
aJ:
%aK=bitcast i8**%d to i32**
store i32*%az,i32**%aK,align 8
%aL=getelementptr inbounds i8,i8*%ax,i64 8
%aM=bitcast i8*%aL to i32*
%aN=load i32,i32*%aM,align 4
%aO=icmp eq i32%aN,0
br i1%aO,label%aV,label%aP
aP:
%aQ=mul i32%aF,%z
%aR=sext i32%aQ to i64
%aS=getelementptr inbounds i8,i8*%aI,i64%aR
%aT=bitcast i8*%aS to i8**
%aU=load i8*,i8**%aT,align 8
br label%a7
aV:
%aW=call i8*@sml_alloc(i32 inreg%aF)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32%aF,i32*%aY,align 4
%aZ=load i8*,i8**%d,align 8
%a0=mul i32%aF,%z
%a1=sext i32%a0 to i64
%a2=getelementptr inbounds i8,i8*%aZ,i64%a1
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aW,i8*%a2,i32%aF,i1 false)
%a3=load i8*,i8**%f,align 8
%a4=getelementptr inbounds i8,i8*%a3,i64 12
%a5=bitcast i8*%a4 to i32*
%a6=load i32,i32*%a5,align 4
br label%a7
a7:
%a8=phi i32[%aF,%aP],[%a6,%aV]
%a9=phi i8*[%ax,%aP],[%a3,%aV]
%ba=phi i8*[%aU,%aP],[%aW,%aV]
store i8*%ba,i8**%d,align 8
%bb=getelementptr inbounds i8,i8*%a9,i64 8
%bc=bitcast i8*%bb to i32*
%bd=load i32,i32*%bc,align 4
%be=call i8*@sml_alloc(i32 inreg%u)#0
%bf=or i32%o,1342177280
%bg=getelementptr inbounds i8,i8*%be,i64 -4
%bh=bitcast i8*%bg to i32*
store i32%bf,i32*%bh,align 4
store i8*%be,i8**%e,align 8
call void@llvm.memset.p0i8.i32(i8*%be,i8 0,i32%u,i1 false)
%bi=bitcast i8*%be to i32*
store i32%w,i32*%bi,align 4
%bj=icmp eq i32%bd,0
%bk=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bl=sext i32%l to i64
%bm=getelementptr inbounds i8,i8*%be,i64%bl
br i1%bj,label%bH,label%bF
bn:
store i8*null,i8**%f,align 8
%bo=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%bo,i8**%c,align 8
%bp=call i8*@sml_alloc(i32 inreg 20)#0
%bq=getelementptr inbounds i8,i8*%bp,i64 -4
%br=bitcast i8*%bq to i32*
store i32 1342177296,i32*%br,align 4
store i8*%bp,i8**%d,align 8
%bs=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bt=bitcast i8*%bp to i8**
store i8*%bs,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bp,i64 8
%bv=bitcast i8*%bu to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%bv,align 8
%bw=getelementptr inbounds i8,i8*%bp,i64 16
%bx=bitcast i8*%bw to i32*
store i32 3,i32*%bx,align 4
%by=call i8*@sml_alloc(i32 inreg 60)#0
%bz=getelementptr inbounds i8,i8*%by,i64 -4
%bA=bitcast i8*%bz to i32*
store i32 1342177336,i32*%bA,align 4
%bB=getelementptr inbounds i8,i8*%by,i64 56
%bC=bitcast i8*%bB to i32*
store i32 1,i32*%bC,align 4
%bD=load i8*,i8**%d,align 8
%bE=bitcast i8*%by to i8**
store i8*%bD,i8**%bE,align 8
call void@sml_raise(i8*inreg%by)#1
unreachable
bF:
%bG=bitcast i8*%bm to i8**
store i8*%bk,i8**%bG,align 8
br label%bI
bH:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bm,i8*%bk,i32%a8,i1 false)
br label%bI
bI:
%bJ=sext i32%o to i64
%bK=getelementptr inbounds i8,i8*%be,i64%bJ
%bL=bitcast i8*%bK to i32*
store i32%t,i32*%bL,align 4
%bM=load i32,i32*%bi,align 4
%bN=load i8*,i8**%f,align 8
%bO=getelementptr inbounds i8,i8*%bN,i64 8
%bP=bitcast i8*%bO to i32*
%bQ=load i32,i32*%bP,align 4
%bR=icmp eq i32%bQ,0
br i1%bR,label%bV,label%bS
bS:
store i8*null,i8**%e,align 8
%bT=bitcast i8*%bm to i8**
%bU=load i8*,i8**%bT,align 8
br label%b4
bV:
%bW=getelementptr inbounds i8,i8*%bN,i64 12
%bX=bitcast i8*%bW to i32*
%bY=load i32,i32*%bX,align 4
%bZ=call i8*@sml_alloc(i32 inreg%bY)#0
%b0=getelementptr inbounds i8,i8*%bZ,i64 -4
%b1=bitcast i8*%b0 to i32*
store i32%bY,i32*%b1,align 4
%b2=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%b3=getelementptr inbounds i8,i8*%b2,i64%bl
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bZ,i8*%b3,i32%bY,i1 false)
br label%b4
b4:
%b5=phi i8*[%bU,%bS],[%bZ,%bV]
%b6=icmp slt i32%bM,0
br i1%b6,label%cv,label%b7
b7:
%b8=load i8*,i8**%f,align 8
%b9=bitcast i8*%b8 to i32**
%ca=load i32*,i32**%b9,align 8
%cb=getelementptr inbounds i32,i32*%ca,i64 -1
%cc=load i32,i32*%cb,align 4
%cd=and i32%cc,268435455
%ce=getelementptr inbounds i8,i8*%b8,i64 12
%cf=bitcast i8*%ce to i32*
%cg=load i32,i32*%cf,align 4
%ch=udiv i32%cd,%cg
%ci=icmp slt i32%bM,%ch
%cj=bitcast i32*%ca to i8*
br i1%ci,label%ck,label%cv
ck:
%cl=getelementptr inbounds i8,i8*%b8,i64 8
%cm=bitcast i8*%cl to i32*
%cn=load i32,i32*%cm,align 4
%co=icmp eq i32%cn,0
%cp=mul i32%cg,%bM
%cq=sext i32%cp to i64
%cr=getelementptr inbounds i8,i8*%cj,i64%cq
br i1%co,label%cu,label%cs
cs:
%ct=bitcast i8*%cr to i8**
call void@sml_write(i8*inreg%cj,i8**inreg%ct,i8*inreg%b5)#0
br label%cN
cu:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cr,i8*%b5,i32%cg,i1 false)
br label%cN
cv:
store i8*null,i8**%f,align 8
%cw=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%cw,i8**%c,align 8
%cx=call i8*@sml_alloc(i32 inreg 20)#0
%cy=getelementptr inbounds i8,i8*%cx,i64 -4
%cz=bitcast i8*%cy to i32*
store i32 1342177296,i32*%cz,align 4
store i8*%cx,i8**%d,align 8
%cA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cB=bitcast i8*%cx to i8**
store i8*%cA,i8**%cB,align 8
%cC=getelementptr inbounds i8,i8*%cx,i64 8
%cD=bitcast i8*%cC to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%cD,align 8
%cE=getelementptr inbounds i8,i8*%cx,i64 16
%cF=bitcast i8*%cE to i32*
store i32 3,i32*%cF,align 4
%cG=call i8*@sml_alloc(i32 inreg 60)#0
%cH=getelementptr inbounds i8,i8*%cG,i64 -4
%cI=bitcast i8*%cH to i32*
store i32 1342177336,i32*%cI,align 4
%cJ=getelementptr inbounds i8,i8*%cG,i64 56
%cK=bitcast i8*%cJ to i32*
store i32 1,i32*%cK,align 4
%cL=load i8*,i8**%d,align 8
%cM=bitcast i8*%cG to i8**
store i8*%cL,i8**%cM,align 8
call void@sml_raise(i8*inreg%cG)#1
unreachable
cN:
%cO=load i8*,i8**%f,align 8
%cP=bitcast i8*%cO to i32**
%cQ=load i32*,i32**%cP,align 8
%cR=getelementptr inbounds i32,i32*%cQ,i64 -1
%cS=load i32,i32*%cR,align 4
%cT=and i32%cS,268435455
%cU=getelementptr inbounds i8,i8*%cO,i64 12
%cV=bitcast i8*%cU to i32*
%cW=load i32,i32*%cV,align 4
%cX=udiv i32%cT,%cW
%cY=icmp slt i32%z,%cX
%cZ=bitcast i32*%cQ to i8*
br i1%cY,label%c0,label%dc
c0:
%c1=getelementptr inbounds i8,i8*%cO,i64 8
%c2=bitcast i8*%c1 to i32*
%c3=load i32,i32*%c2,align 4
%c4=icmp eq i32%c3,0
%c5=load i8*,i8**%c,align 8
%c6=mul i32%cW,%z
%c7=sext i32%c6 to i64
%c8=getelementptr inbounds i8,i8*%cZ,i64%c7
br i1%c4,label%db,label%c9
c9:
%da=bitcast i8*%c8 to i8**
call void@sml_write(i8*inreg%cZ,i8**inreg%da,i8*inreg%c5)#0
ret void
db:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%c8,i8*%c5,i32%cW,i1 false)
ret void
dc:
store i8*null,i8**%f,align 8
%dd=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%dd,i8**%c,align 8
%de=call i8*@sml_alloc(i32 inreg 20)#0
%df=getelementptr inbounds i8,i8*%de,i64 -4
%dg=bitcast i8*%df to i32*
store i32 1342177296,i32*%dg,align 4
store i8*%de,i8**%d,align 8
%dh=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%di=bitcast i8*%de to i8**
store i8*%dh,i8**%di,align 8
%dj=getelementptr inbounds i8,i8*%de,i64 8
%dk=bitcast i8*%dj to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%dk,align 8
%dl=getelementptr inbounds i8,i8*%de,i64 16
%dm=bitcast i8*%dl to i32*
store i32 3,i32*%dm,align 4
%dn=call i8*@sml_alloc(i32 inreg 60)#0
%do=getelementptr inbounds i8,i8*%dn,i64 -4
%dp=bitcast i8*%do to i32*
store i32 1342177336,i32*%dp,align 4
%dq=getelementptr inbounds i8,i8*%dn,i64 56
%dr=bitcast i8*%dq to i32*
store i32 1,i32*%dr,align 4
%ds=load i8*,i8**%d,align 8
%dt=bitcast i8*%dn to i8**
store i8*%ds,i8**%dt,align 8
call void@sml_raise(i8*inreg%dn)#1
unreachable
}
define internal fastcc i32@_SMLL4scan_50(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
j:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%d,align 8
%g=bitcast i8**%c to i32**
br label%h
h:
%i=phi i8*[%cc,%cb],[%b,%j]
store i8*%i,i8**%c,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%c,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%i,%h]
%q=load i8*,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%q,i64 40
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=add i32%t,-1
%v=sub i32 0,%t
%w=and i32%u,%v
%x=shl i32%t,1
%y=add i32%x,-1
%z=add i32%y,%w
%A=and i32%z,%v
%B=add i32%t,7
%C=add i32%B,%A
%D=and i32%C,-8
%E=lshr i32%A,3
%F=lshr i32%w,3
%G=sub nsw i32%E,%F
%H=getelementptr inbounds i8,i8*%q,i64 36
%I=bitcast i8*%H to i32*
%J=load i32,i32*%I,align 4
%K=shl i32%J,%G
%L=or i32%K,%J
%M=or i32%D,4
%N=bitcast i8*%p to i32*
%O=load i32,i32*%N,align 4
%P=getelementptr inbounds i8,i8*%p,i64 4
%Q=bitcast i8*%P to i32*
%R=load i32,i32*%Q,align 4
%S=getelementptr inbounds i8,i8*%q,i64 32
%T=bitcast i8*%S to i32*
%U=load i32,i32*%T,align 4
%V=icmp sgt i32%O,%U
br i1%V,label%co,label%W
W:
%X=getelementptr inbounds i8,i8*%q,i64 16
%Y=bitcast i8*%X to i8**
%Z=load i8*,i8**%Y,align 8
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8*(i8*,i8*)**
%ac=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ab,align 8
%ad=bitcast i8*%Z to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%f,align 8
%af=icmp slt i32%O,0
br i1%af,label%aN,label%ag
ag:
%ah=bitcast i8*%q to i32**
%ai=load i32*,i32**%ah,align 8
%aj=getelementptr inbounds i32,i32*%ai,i64 -1
%ak=load i32,i32*%aj,align 4
%al=and i32%ak,268435455
%am=udiv i32%al,%t
%an=icmp slt i32%O,%am
%ao=bitcast i32*%ai to i8*
br i1%an,label%ap,label%aN
ap:
store i32*%ai,i32**%g,align 8
%aq=icmp eq i32%J,0
br i1%aq,label%ax,label%ar
ar:
%as=mul i32%t,%O
%at=sext i32%as to i64
%au=getelementptr inbounds i8,i8*%ao,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
store i8*%aw,i8**%c,align 8
br label%a5
ax:
%ay=call i8*@sml_alloc(i32 inreg%t)#0
%az=getelementptr inbounds i8,i8*%ay,i64 -4
%aA=bitcast i8*%az to i32*
store i32%t,i32*%aA,align 4
%aB=load i8*,i8**%c,align 8
%aC=mul i32%t,%O
%aD=sext i32%aC to i64
%aE=getelementptr inbounds i8,i8*%aB,i64%aD
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ay,i8*%aE,i32%t,i1 false)
%aF=load i8*,i8**%d,align 8
%aG=getelementptr inbounds i8,i8*%aF,i64 40
%aH=bitcast i8*%aG to i32*
%aI=load i32,i32*%aH,align 4
%aJ=getelementptr inbounds i8,i8*%aF,i64 36
%aK=bitcast i8*%aJ to i32*
%aL=load i32,i32*%aK,align 4
store i8*%ay,i8**%c,align 8
%aM=icmp eq i32%aL,0
br i1%aM,label%bc,label%a5
aN:
store i8*null,i8**%d,align 8
store i8*null,i8**%f,align 8
%aO=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%aO,i8**%c,align 8
%aP=call i8*@sml_alloc(i32 inreg 20)#0
%aQ=getelementptr inbounds i8,i8*%aP,i64 -4
%aR=bitcast i8*%aQ to i32*
store i32 1342177296,i32*%aR,align 4
store i8*%aP,i8**%d,align 8
%aS=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aT=bitcast i8*%aP to i8**
store i8*%aS,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aP,i64 8
%aV=bitcast i8*%aU to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%aV,align 8
%aW=getelementptr inbounds i8,i8*%aP,i64 16
%aX=bitcast i8*%aW to i32*
store i32 3,i32*%aX,align 4
%aY=call i8*@sml_alloc(i32 inreg 60)#0
%aZ=getelementptr inbounds i8,i8*%aY,i64 -4
%a0=bitcast i8*%aZ to i32*
store i32 1342177336,i32*%a0,align 4
%a1=getelementptr inbounds i8,i8*%aY,i64 56
%a2=bitcast i8*%a1 to i32*
store i32 1,i32*%a2,align 4
%a3=load i8*,i8**%d,align 8
%a4=bitcast i8*%aY to i8**
store i8*%a3,i8**%a4,align 8
call void@sml_raise(i8*inreg%aY)#1
unreachable
a5:
%a6=phi i8*[%q,%ar],[%aF,%ax]
%a7=phi i32[%t,%ar],[%aI,%ax]
%a8=phi i32[%J,%ar],[%aL,%ax]
%a9=getelementptr inbounds i8,i8*%a6,i64 8
%ba=bitcast i8*%a9 to i8**
%bb=load i8*,i8**%ba,align 8
br label%bo
bc:
%bd=call i8*@sml_alloc(i32 inreg%aI)#0
%be=getelementptr inbounds i8,i8*%bd,i64 -4
%bf=bitcast i8*%be to i32*
store i32%aI,i32*%bf,align 4
%bg=load i8*,i8**%d,align 8
%bh=getelementptr inbounds i8,i8*%bg,i64 8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bd,i8*%bh,i32%aI,i1 false)
%bi=getelementptr inbounds i8,i8*%bg,i64 40
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
%bl=getelementptr inbounds i8,i8*%bg,i64 36
%bm=bitcast i8*%bl to i32*
%bn=load i32,i32*%bm,align 4
br label%bo
bo:
%bp=phi i1[true,%bc],[false,%a5]
%bq=phi i32[%aI,%bc],[%a7,%a5]
%br=phi i32[%bn,%bc],[%a8,%a5]
%bs=phi i32[%bk,%bc],[%a7,%a5]
%bt=phi i8*[%bd,%bc],[%bb,%a5]
store i8*%bt,i8**%e,align 8
%bu=call i8*@sml_alloc(i32 inreg%M)#0
%bv=or i32%D,1342177280
%bw=getelementptr inbounds i8,i8*%bu,i64 -4
%bx=bitcast i8*%bw to i32*
store i32%bv,i32*%bx,align 4
call void@llvm.memset.p0i8.i32(i8*%bu,i8 0,i32%M,i1 false)
%by=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bz=sext i32%w to i64
%bA=getelementptr inbounds i8,i8*%bu,i64%bz
br i1%bp,label%bD,label%bB
bB:
%bC=bitcast i8*%bA to i8**
store i8*%by,i8**%bC,align 8
br label%bE
bD:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bA,i8*%by,i32%bq,i1 false)
br label%bE
bE:
%bF=icmp eq i32%br,0
%bG=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bH=sext i32%A to i64
%bI=getelementptr inbounds i8,i8*%bu,i64%bH
br i1%bF,label%bL,label%bJ
bJ:
%bK=bitcast i8*%bI to i8**
store i8*%bG,i8**%bK,align 8
br label%bM
bL:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bI,i8*%bG,i32%bs,i1 false)
br label%bM
bM:
%bN=sext i32%D to i64
%bO=getelementptr inbounds i8,i8*%bu,i64%bN
%bP=bitcast i8*%bO to i32*
store i32%L,i32*%bP,align 4
%bQ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bR=call fastcc i8*%ac(i8*inreg%bQ,i8*inreg%bu)
%bS=bitcast i8*%bR to i32*
%bT=load i32,i32*%bS,align 4
%bU=icmp eq i32%bT,2
br i1%bU,label%bV,label%cm
bV:
%bW=load i8*,i8**%d,align 8
%bX=getelementptr inbounds i8,i8*%bW,i64 24
%bY=bitcast i8*%bX to i8**
%bZ=load i8*,i8**%bY,align 8
store i8*%bZ,i8**%c,align 8
%b0=add nsw i32%R,1
%b1=call i8*@sml_alloc(i32 inreg 12)#0
%b2=bitcast i8*%b1 to i32*
%b3=getelementptr inbounds i8,i8*%b1,i64 -4
%b4=bitcast i8*%b3 to i32*
store i32 1342177288,i32*%b4,align 4
store i32%b0,i32*%b2,align 4
%b5=getelementptr inbounds i8,i8*%b1,i64 4
%b6=bitcast i8*%b5 to i32*
store i32%O,i32*%b6,align 4
%b7=getelementptr inbounds i8,i8*%b1,i64 8
%b8=bitcast i8*%b7 to i32*
store i32 0,i32*%b8,align 4
%b9=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call fastcc void@_SMLL4swap_43(i8*inreg%b9,i8*inreg%b1)
%ca=call i8*@sml_alloc(i32 inreg 12)#0
br label%cb
cb:
%cc=phi i8*[%ca,%bV],[%cn,%cm]
%cd=phi i32[%b0,%bV],[%R,%cm]
%ce=add nsw i32%O,1
%cf=bitcast i8*%cc to i32*
%cg=getelementptr inbounds i8,i8*%cc,i64 -4
%ch=bitcast i8*%cg to i32*
store i32 1342177288,i32*%ch,align 4
store i32%ce,i32*%cf,align 4
%ci=getelementptr inbounds i8,i8*%cc,i64 4
%cj=bitcast i8*%ci to i32*
store i32%cd,i32*%cj,align 4
%ck=getelementptr inbounds i8,i8*%cc,i64 8
%cl=bitcast i8*%ck to i32*
store i32 0,i32*%cl,align 4
br label%h
cm:
%cn=call i8*@sml_alloc(i32 inreg 12)#0
br label%cb
co:
ret i32%R
}
define internal fastcc void@_SMLL9quickSort_44(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%i=bitcast i8**%f to i8***
%j=bitcast i8**%c to i32**
%k=bitcast i8**%d to i32**
%l=bitcast i8**%d to i32**
br label%m
m:
%n=phi i8*[%hh,%g5],[%b,%o]
store i8*%n,i8**%c,align 8
%p=load atomic i32,i32*@sml_check_flag unordered,align 4
%q=icmp eq i32%p,0
br i1%q,label%t,label%r
r:
call void@sml_check(i32 inreg%p)
%s=load i8*,i8**%c,align 8
br label%t
t:
%u=phi i8*[%s,%r],[%n,%m]
%v=load i8*,i8**%f,align 8
%w=getelementptr inbounds i8,i8*%v,i64 24
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=shl i32%y,1
%A=or i32%z,13
%B=getelementptr inbounds i8,i8*%v,i64 28
%C=bitcast i8*%B to i32*
%D=load i32,i32*%C,align 4
%E=add i32%D,3
%F=sub i32 0,%D
%G=and i32%E,%F
%H=add i32%D,7
%I=add i32%H,%G
%J=and i32%I,-8
%K=lshr i32%G,3
%L=shl i32%y,%K
%M=or i32%J,4
%N=bitcast i8*%u to i32*
%O=load i32,i32*%N,align 4
%P=getelementptr inbounds i8,i8*%u,i64 4
%Q=bitcast i8*%P to i32*
%R=load i32,i32*%Q,align 4
%S=icmp slt i32%O,%R
br i1%S,label%T,label%hp
T:
%U=add nsw i32%R,%O
%V=sdiv i32%U,2
%W=lshr i32%U,31
%X=and i32%W,%U
%Y=sub nsw i32%V,%X
%Z=icmp slt i32%Y,0
br i1%Z,label%aC,label%aa
aa:
%ab=bitcast i8*%v to i32**
%ac=load i32*,i32**%ab,align 8
%ad=getelementptr inbounds i32,i32*%ac,i64 -1
%ae=load i32,i32*%ad,align 4
%af=and i32%ae,268435455
%ag=udiv i32%af,%D
%ah=icmp slt i32%Y,%ag
%ai=bitcast i32*%ac to i8*
br i1%ah,label%aj,label%aC
aj:
store i32*%ac,i32**%j,align 8
%ak=icmp eq i32%y,0
br i1%ak,label%ar,label%al
al:
%am=mul i32%D,%Y
%an=sext i32%am to i64
%ao=getelementptr inbounds i8,i8*%ai,i64%an
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
br label%az
ar:
%as=call i8*@sml_alloc(i32 inreg%D)#0
%at=getelementptr inbounds i8,i8*%as,i64 -4
%au=bitcast i8*%at to i32*
store i32%D,i32*%au,align 4
%av=load i8*,i8**%c,align 8
%aw=mul i32%D,%Y
%ax=sext i32%aw to i64
%ay=getelementptr inbounds i8,i8*%av,i64%ax
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%as,i8*%ay,i32%D,i1 false)
br label%az
az:
%aA=phi i8*[%aq,%al],[%as,%ar]
store i8*%aA,i8**%c,align 8
%aB=icmp slt i32%O,0
br i1%aB,label%bK,label%aU
aC:
store i8*null,i8**%f,align 8
%aD=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%aD,i8**%c,align 8
%aE=call i8*@sml_alloc(i32 inreg 20)#0
%aF=getelementptr inbounds i8,i8*%aE,i64 -4
%aG=bitcast i8*%aF to i32*
store i32 1342177296,i32*%aG,align 4
store i8*%aE,i8**%d,align 8
%aH=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aI=bitcast i8*%aE to i8**
store i8*%aH,i8**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%aE,i64 8
%aK=bitcast i8*%aJ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aE,i64 16
%aM=bitcast i8*%aL to i32*
store i32 3,i32*%aM,align 4
%aN=call i8*@sml_alloc(i32 inreg 60)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177336,i32*%aP,align 4
%aQ=getelementptr inbounds i8,i8*%aN,i64 56
%aR=bitcast i8*%aQ to i32*
store i32 1,i32*%aR,align 4
%aS=load i8*,i8**%d,align 8
%aT=bitcast i8*%aN to i8**
store i8*%aS,i8**%aT,align 8
call void@sml_raise(i8*inreg%aN)#1
unreachable
aU:
%aV=load i8*,i8**%f,align 8
%aW=bitcast i8*%aV to i32**
%aX=load i32*,i32**%aW,align 8
%aY=getelementptr inbounds i32,i32*%aX,i64 -1
%aZ=load i32,i32*%aY,align 4
%a0=and i32%aZ,268435455
%a1=getelementptr inbounds i8,i8*%aV,i64 28
%a2=bitcast i8*%a1 to i32*
%a3=load i32,i32*%a2,align 4
%a4=udiv i32%a0,%a3
%a5=icmp slt i32%O,%a4
%a6=bitcast i32*%aX to i8*
br i1%a5,label%a7,label%bK
a7:
store i32*%aX,i32**%k,align 8
%a8=getelementptr inbounds i8,i8*%aV,i64 24
%a9=bitcast i8*%a8 to i32*
%ba=load i32,i32*%a9,align 4
%bb=icmp eq i32%ba,0
br i1%bb,label%bi,label%bc
bc:
%bd=mul i32%a3,%O
%be=sext i32%bd to i64
%bf=getelementptr inbounds i8,i8*%a6,i64%be
%bg=bitcast i8*%bf to i8**
%bh=load i8*,i8**%bg,align 8
br label%bu
bi:
%bj=call i8*@sml_alloc(i32 inreg%a3)#0
%bk=getelementptr inbounds i8,i8*%bj,i64 -4
%bl=bitcast i8*%bk to i32*
store i32%a3,i32*%bl,align 4
%bm=load i8*,i8**%d,align 8
%bn=mul i32%a3,%O
%bo=sext i32%bn to i64
%bp=getelementptr inbounds i8,i8*%bm,i64%bo
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bj,i8*%bp,i32%a3,i1 false)
%bq=load i8*,i8**%f,align 8
%br=getelementptr inbounds i8,i8*%bq,i64 28
%bs=bitcast i8*%br to i32*
%bt=load i32,i32*%bs,align 4
br label%bu
bu:
%bv=phi i32[%a3,%bc],[%bt,%bi]
%bw=phi i8*[%aV,%bc],[%bq,%bi]
%bx=phi i8*[%bh,%bc],[%bj,%bi]
store i8*%bx,i8**%d,align 8
%by=getelementptr inbounds i8,i8*%bw,i64 24
%bz=bitcast i8*%by to i32*
%bA=load i32,i32*%bz,align 4
%bB=call i8*@sml_alloc(i32 inreg%M)#0
%bC=or i32%J,1342177280
%bD=getelementptr inbounds i8,i8*%bB,i64 -4
%bE=bitcast i8*%bD to i32*
store i32%bC,i32*%bE,align 4
store i8*%bB,i8**%e,align 8
call void@llvm.memset.p0i8.i32(i8*%bB,i8 0,i32%M,i1 false)
%bF=bitcast i8*%bB to i32*
store i32%Y,i32*%bF,align 4
%bG=icmp eq i32%bA,0
%bH=load i8*,i8**%d,align 8
%bI=sext i32%G to i64
%bJ=getelementptr inbounds i8,i8*%bB,i64%bI
br i1%bG,label%b4,label%b2
bK:
store i8*null,i8**%f,align 8
%bL=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%bL,i8**%c,align 8
%bM=call i8*@sml_alloc(i32 inreg 20)#0
%bN=getelementptr inbounds i8,i8*%bM,i64 -4
%bO=bitcast i8*%bN to i32*
store i32 1342177296,i32*%bO,align 4
store i8*%bM,i8**%d,align 8
%bP=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bQ=bitcast i8*%bM to i8**
store i8*%bP,i8**%bQ,align 8
%bR=getelementptr inbounds i8,i8*%bM,i64 8
%bS=bitcast i8*%bR to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%bS,align 8
%bT=getelementptr inbounds i8,i8*%bM,i64 16
%bU=bitcast i8*%bT to i32*
store i32 3,i32*%bU,align 4
%bV=call i8*@sml_alloc(i32 inreg 60)#0
%bW=getelementptr inbounds i8,i8*%bV,i64 -4
%bX=bitcast i8*%bW to i32*
store i32 1342177336,i32*%bX,align 4
%bY=getelementptr inbounds i8,i8*%bV,i64 56
%bZ=bitcast i8*%bY to i32*
store i32 1,i32*%bZ,align 4
%b0=load i8*,i8**%d,align 8
%b1=bitcast i8*%bV to i8**
store i8*%b0,i8**%b1,align 8
call void@sml_raise(i8*inreg%bV)#1
unreachable
b2:
%b3=bitcast i8*%bJ to i8**
store i8*%bH,i8**%b3,align 8
br label%b5
b4:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bJ,i8*%bH,i32%bv,i1 false)
br label%b5
b5:
%b6=sext i32%J to i64
%b7=getelementptr inbounds i8,i8*%bB,i64%b6
%b8=bitcast i8*%b7 to i32*
store i32%L,i32*%b8,align 4
%b9=load i32,i32*%bF,align 4
%ca=load i8*,i8**%f,align 8
%cb=getelementptr inbounds i8,i8*%ca,i64 24
%cc=bitcast i8*%cb to i32*
%cd=load i32,i32*%cc,align 4
%ce=icmp eq i32%cd,0
br i1%ce,label%ci,label%cf
cf:
%cg=bitcast i8*%bJ to i8**
%ch=load i8*,i8**%cg,align 8
br label%cr
ci:
%cj=getelementptr inbounds i8,i8*%ca,i64 28
%ck=bitcast i8*%cj to i32*
%cl=load i32,i32*%ck,align 4
%cm=call i8*@sml_alloc(i32 inreg%cl)#0
%cn=getelementptr inbounds i8,i8*%cm,i64 -4
%co=bitcast i8*%cn to i32*
store i32%cl,i32*%co,align 4
%cp=load i8*,i8**%e,align 8
%cq=getelementptr inbounds i8,i8*%cp,i64%bI
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cm,i8*%cq,i32%cl,i1 false)
br label%cr
cr:
%cs=phi i8*[%ch,%cf],[%cm,%ci]
%ct=icmp slt i32%b9,0
br i1%ct,label%cS,label%cu
cu:
%cv=load i8*,i8**%f,align 8
%cw=bitcast i8*%cv to i32**
%cx=load i32*,i32**%cw,align 8
%cy=getelementptr inbounds i32,i32*%cx,i64 -1
%cz=load i32,i32*%cy,align 4
%cA=and i32%cz,268435455
%cB=getelementptr inbounds i8,i8*%cv,i64 28
%cC=bitcast i8*%cB to i32*
%cD=load i32,i32*%cC,align 4
%cE=udiv i32%cA,%cD
%cF=icmp slt i32%b9,%cE
%cG=bitcast i32*%cx to i8*
br i1%cF,label%cH,label%cS
cH:
%cI=getelementptr inbounds i8,i8*%cv,i64 24
%cJ=bitcast i8*%cI to i32*
%cK=load i32,i32*%cJ,align 4
%cL=icmp eq i32%cK,0
%cM=mul i32%cD,%b9
%cN=sext i32%cM to i64
%cO=getelementptr inbounds i8,i8*%cG,i64%cN
br i1%cL,label%cR,label%cP
cP:
%cQ=bitcast i8*%cO to i8**
call void@sml_write(i8*inreg%cG,i8**inreg%cQ,i8*inreg%cs)#0
br label%da
cR:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cO,i8*%cs,i32%cD,i1 false)
br label%da
cS:
store i8*null,i8**%f,align 8
%cT=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%cT,i8**%c,align 8
%cU=call i8*@sml_alloc(i32 inreg 20)#0
%cV=getelementptr inbounds i8,i8*%cU,i64 -4
%cW=bitcast i8*%cV to i32*
store i32 1342177296,i32*%cW,align 4
store i8*%cU,i8**%d,align 8
%cX=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cY=bitcast i8*%cU to i8**
store i8*%cX,i8**%cY,align 8
%cZ=getelementptr inbounds i8,i8*%cU,i64 8
%c0=bitcast i8*%cZ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%c0,align 8
%c1=getelementptr inbounds i8,i8*%cU,i64 16
%c2=bitcast i8*%c1 to i32*
store i32 3,i32*%c2,align 4
%c3=call i8*@sml_alloc(i32 inreg 60)#0
%c4=getelementptr inbounds i8,i8*%c3,i64 -4
%c5=bitcast i8*%c4 to i32*
store i32 1342177336,i32*%c5,align 4
%c6=getelementptr inbounds i8,i8*%c3,i64 56
%c7=bitcast i8*%c6 to i32*
store i32 1,i32*%c7,align 4
%c8=load i8*,i8**%d,align 8
%c9=bitcast i8*%c3 to i8**
store i8*%c8,i8**%c9,align 8
call void@sml_raise(i8*inreg%c3)#1
unreachable
da:
%db=load i8**,i8***%i,align 8
%dc=load i8*,i8**%db,align 8
store i8*%dc,i8**%d,align 8
%dd=bitcast i8**%db to i8*
%de=getelementptr inbounds i8,i8*%dd,i64 28
%df=bitcast i8*%de to i32*
%dg=load i32,i32*%df,align 4
%dh=getelementptr inbounds i8*,i8**%db,i64 3
%di=bitcast i8**%dh to i32*
%dj=load i32,i32*%di,align 4
%dk=getelementptr inbounds i8*,i8**%db,i64 1
%dl=load i8*,i8**%dk,align 8
store i8*%dl,i8**%e,align 8
%dm=getelementptr inbounds i8*,i8**%db,i64 2
%dn=load i8*,i8**%dm,align 8
store i8*%dn,i8**%g,align 8
%do=call i8*@sml_alloc(i32 inreg 52)#0
%dp=getelementptr inbounds i8,i8*%do,i64 -4
%dq=bitcast i8*%dp to i32*
store i32 1342177328,i32*%dq,align 4
store i8*%do,i8**%h,align 8
%dr=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ds=bitcast i8*%do to i8**
store i8*%dr,i8**%ds,align 8
%dt=icmp eq i32%dj,0
%du=load i8*,i8**%c,align 8
%dv=getelementptr inbounds i8,i8*%do,i64 8
br i1%dt,label%dy,label%dw
dw:
%dx=bitcast i8*%dv to i8**
store i8*%du,i8**%dx,align 8
br label%dz
dy:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%dv,i8*%du,i32%dg,i1 false)
br label%dz
dz:
%dA=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dB=getelementptr inbounds i8,i8*%do,i64 16
%dC=bitcast i8*%dB to i8**
store i8*%dA,i8**%dC,align 8
%dD=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%dE=getelementptr inbounds i8,i8*%do,i64 24
%dF=bitcast i8*%dE to i8**
store i8*%dD,i8**%dF,align 8
%dG=getelementptr inbounds i8,i8*%do,i64 32
%dH=bitcast i8*%dG to i32*
store i32%R,i32*%dH,align 4
%dI=getelementptr inbounds i8,i8*%do,i64 36
%dJ=bitcast i8*%dI to i32*
store i32%dj,i32*%dJ,align 4
%dK=getelementptr inbounds i8,i8*%do,i64 40
%dL=bitcast i8*%dK to i32*
store i32%dg,i32*%dL,align 4
%dM=getelementptr inbounds i8,i8*%do,i64 48
%dN=bitcast i8*%dM to i32*
store i32%A,i32*%dN,align 4
%dO=call i8*@sml_alloc(i32 inreg 28)#0
%dP=getelementptr inbounds i8,i8*%dO,i64 -4
%dQ=bitcast i8*%dP to i32*
store i32 1342177304,i32*%dQ,align 4
%dR=load i8*,i8**%h,align 8
%dS=bitcast i8*%dO to i8**
store i8*%dR,i8**%dS,align 8
%dT=getelementptr inbounds i8,i8*%dO,i64 8
%dU=bitcast i8*%dT to void(...)**
store void(...)*bitcast(i32(i8*,i8*)*@_SMLL4scan_50 to void(...)*),void(...)**%dU,align 8
%dV=getelementptr inbounds i8,i8*%dO,i64 16
%dW=bitcast i8*%dV to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4scan_61 to void(...)*),void(...)**%dW,align 8
%dX=getelementptr inbounds i8,i8*%dO,i64 24
%dY=bitcast i8*%dX to i32*
store i32 -2147483647,i32*%dY,align 4
%dZ=add nsw i32%O,1
%d0=call i8*@sml_alloc(i32 inreg 12)#0
%d1=bitcast i8*%d0 to i32*
%d2=getelementptr inbounds i8,i8*%d0,i64 -4
%d3=bitcast i8*%d2 to i32*
store i32 1342177288,i32*%d3,align 4
store i32%dZ,i32*%d1,align 4
%d4=getelementptr inbounds i8,i8*%d0,i64 4
%d5=bitcast i8*%d4 to i32*
store i32%O,i32*%d5,align 4
%d6=getelementptr inbounds i8,i8*%d0,i64 8
%d7=bitcast i8*%d6 to i32*
store i32 0,i32*%d7,align 4
%d8=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%d9=call fastcc i32@_SMLL4scan_50(i8*inreg%d8,i8*inreg%d0)
%ea=icmp slt i32%d9,0
br i1%ea,label%eZ,label%eb
eb:
%ec=load i8*,i8**%f,align 8
%ed=bitcast i8*%ec to i32**
%ee=load i32*,i32**%ed,align 8
%ef=getelementptr inbounds i32,i32*%ee,i64 -1
%eg=load i32,i32*%ef,align 4
%eh=and i32%eg,268435455
%ei=getelementptr inbounds i8,i8*%ec,i64 28
%ej=bitcast i8*%ei to i32*
%ek=load i32,i32*%ej,align 4
%el=udiv i32%eh,%ek
%em=icmp slt i32%d9,%el
%en=bitcast i32*%ee to i8*
br i1%em,label%eo,label%eZ
eo:
store i32*%ee,i32**%l,align 8
%ep=getelementptr inbounds i8,i8*%ec,i64 24
%eq=bitcast i8*%ep to i32*
%er=load i32,i32*%eq,align 4
%es=icmp eq i32%er,0
br i1%es,label%ez,label%et
et:
%eu=mul i32%ek,%d9
%ev=sext i32%eu to i64
%ew=getelementptr inbounds i8,i8*%en,i64%ev
%ex=bitcast i8*%ew to i8**
%ey=load i8*,i8**%ex,align 8
br label%eL
ez:
%eA=call i8*@sml_alloc(i32 inreg%ek)#0
%eB=getelementptr inbounds i8,i8*%eA,i64 -4
%eC=bitcast i8*%eB to i32*
store i32%ek,i32*%eC,align 4
%eD=load i8*,i8**%d,align 8
%eE=mul i32%ek,%d9
%eF=sext i32%eE to i64
%eG=getelementptr inbounds i8,i8*%eD,i64%eF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%eA,i8*%eG,i32%ek,i1 false)
%eH=load i8*,i8**%f,align 8
%eI=getelementptr inbounds i8,i8*%eH,i64 28
%eJ=bitcast i8*%eI to i32*
%eK=load i32,i32*%eJ,align 4
br label%eL
eL:
%eM=phi i32[%ek,%et],[%eK,%ez]
%eN=phi i8*[%ec,%et],[%eH,%ez]
%eO=phi i8*[%ey,%et],[%eA,%ez]
store i8*%eO,i8**%d,align 8
%eP=getelementptr inbounds i8,i8*%eN,i64 24
%eQ=bitcast i8*%eP to i32*
%eR=load i32,i32*%eQ,align 4
%eS=call i8*@sml_alloc(i32 inreg%M)#0
%eT=getelementptr inbounds i8,i8*%eS,i64 -4
%eU=bitcast i8*%eT to i32*
store i32%bC,i32*%eU,align 4
store i8*%eS,i8**%e,align 8
call void@llvm.memset.p0i8.i32(i8*%eS,i8 0,i32%M,i1 false)
%eV=bitcast i8*%eS to i32*
store i32%O,i32*%eV,align 4
%eW=icmp eq i32%eR,0
%eX=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%eY=getelementptr inbounds i8,i8*%eS,i64%bI
br i1%eW,label%fj,label%fh
eZ:
store i8*null,i8**%f,align 8
%e0=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%e0,i8**%c,align 8
%e1=call i8*@sml_alloc(i32 inreg 20)#0
%e2=getelementptr inbounds i8,i8*%e1,i64 -4
%e3=bitcast i8*%e2 to i32*
store i32 1342177296,i32*%e3,align 4
store i8*%e1,i8**%d,align 8
%e4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%e5=bitcast i8*%e1 to i8**
store i8*%e4,i8**%e5,align 8
%e6=getelementptr inbounds i8,i8*%e1,i64 8
%e7=bitcast i8*%e6 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%e7,align 8
%e8=getelementptr inbounds i8,i8*%e1,i64 16
%e9=bitcast i8*%e8 to i32*
store i32 3,i32*%e9,align 4
%fa=call i8*@sml_alloc(i32 inreg 60)#0
%fb=getelementptr inbounds i8,i8*%fa,i64 -4
%fc=bitcast i8*%fb to i32*
store i32 1342177336,i32*%fc,align 4
%fd=getelementptr inbounds i8,i8*%fa,i64 56
%fe=bitcast i8*%fd to i32*
store i32 1,i32*%fe,align 4
%ff=load i8*,i8**%d,align 8
%fg=bitcast i8*%fa to i8**
store i8*%ff,i8**%fg,align 8
call void@sml_raise(i8*inreg%fa)#1
unreachable
fh:
%fi=bitcast i8*%eY to i8**
store i8*%eX,i8**%fi,align 8
br label%fk
fj:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%eY,i8*%eX,i32%eM,i1 false)
br label%fk
fk:
%fl=getelementptr inbounds i8,i8*%eS,i64%b6
%fm=bitcast i8*%fl to i32*
store i32%L,i32*%fm,align 4
%fn=load i32,i32*%eV,align 4
%fo=load i8*,i8**%f,align 8
%fp=getelementptr inbounds i8,i8*%fo,i64 24
%fq=bitcast i8*%fp to i32*
%fr=load i32,i32*%fq,align 4
%fs=icmp eq i32%fr,0
br i1%fs,label%fw,label%ft
ft:
store i8*null,i8**%e,align 8
%fu=bitcast i8*%eY to i8**
%fv=load i8*,i8**%fu,align 8
br label%fF
fw:
%fx=getelementptr inbounds i8,i8*%fo,i64 28
%fy=bitcast i8*%fx to i32*
%fz=load i32,i32*%fy,align 4
%fA=call i8*@sml_alloc(i32 inreg%fz)#0
%fB=getelementptr inbounds i8,i8*%fA,i64 -4
%fC=bitcast i8*%fB to i32*
store i32%fz,i32*%fC,align 4
%fD=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fE=getelementptr inbounds i8,i8*%fD,i64%bI
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%fA,i8*%fE,i32%fz,i1 false)
br label%fF
fF:
%fG=phi i8*[%fv,%ft],[%fA,%fw]
%fH=icmp slt i32%fn,0
br i1%fH,label%f6,label%fI
fI:
%fJ=load i8*,i8**%f,align 8
%fK=bitcast i8*%fJ to i32**
%fL=load i32*,i32**%fK,align 8
%fM=getelementptr inbounds i32,i32*%fL,i64 -1
%fN=load i32,i32*%fM,align 4
%fO=and i32%fN,268435455
%fP=getelementptr inbounds i8,i8*%fJ,i64 28
%fQ=bitcast i8*%fP to i32*
%fR=load i32,i32*%fQ,align 4
%fS=udiv i32%fO,%fR
%fT=icmp slt i32%fn,%fS
%fU=bitcast i32*%fL to i8*
br i1%fT,label%fV,label%f6
fV:
%fW=getelementptr inbounds i8,i8*%fJ,i64 24
%fX=bitcast i8*%fW to i32*
%fY=load i32,i32*%fX,align 4
%fZ=icmp eq i32%fY,0
%f0=mul i32%fR,%fn
%f1=sext i32%f0 to i64
%f2=getelementptr inbounds i8,i8*%fU,i64%f1
br i1%fZ,label%f5,label%f3
f3:
%f4=bitcast i8*%f2 to i8**
call void@sml_write(i8*inreg%fU,i8**inreg%f4,i8*inreg%fG)#0
br label%go
f5:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%f2,i8*%fG,i32%fR,i1 false)
br label%go
f6:
store i8*null,i8**%f,align 8
%f7=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%f7,i8**%c,align 8
%f8=call i8*@sml_alloc(i32 inreg 20)#0
%f9=getelementptr inbounds i8,i8*%f8,i64 -4
%ga=bitcast i8*%f9 to i32*
store i32 1342177296,i32*%ga,align 4
store i8*%f8,i8**%d,align 8
%gb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gc=bitcast i8*%f8 to i8**
store i8*%gb,i8**%gc,align 8
%gd=getelementptr inbounds i8,i8*%f8,i64 8
%ge=bitcast i8*%gd to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%ge,align 8
%gf=getelementptr inbounds i8,i8*%f8,i64 16
%gg=bitcast i8*%gf to i32*
store i32 3,i32*%gg,align 4
%gh=call i8*@sml_alloc(i32 inreg 60)#0
%gi=getelementptr inbounds i8,i8*%gh,i64 -4
%gj=bitcast i8*%gi to i32*
store i32 1342177336,i32*%gj,align 4
%gk=getelementptr inbounds i8,i8*%gh,i64 56
%gl=bitcast i8*%gk to i32*
store i32 1,i32*%gl,align 4
%gm=load i8*,i8**%d,align 8
%gn=bitcast i8*%gh to i8**
store i8*%gm,i8**%gn,align 8
call void@sml_raise(i8*inreg%gh)#1
unreachable
go:
%gp=load i8*,i8**%f,align 8
%gq=bitcast i8*%gp to i32**
%gr=load i32*,i32**%gq,align 8
%gs=getelementptr inbounds i32,i32*%gr,i64 -1
%gt=load i32,i32*%gs,align 4
%gu=and i32%gt,268435455
%gv=getelementptr inbounds i8,i8*%gp,i64 28
%gw=bitcast i8*%gv to i32*
%gx=load i32,i32*%gw,align 4
%gy=udiv i32%gu,%gx
%gz=icmp slt i32%d9,%gy
%gA=bitcast i32*%gr to i8*
br i1%gz,label%gB,label%gN
gB:
%gC=getelementptr inbounds i8,i8*%gp,i64 24
%gD=bitcast i8*%gC to i32*
%gE=load i32,i32*%gD,align 4
%gF=icmp eq i32%gE,0
%gG=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gH=mul i32%gx,%d9
%gI=sext i32%gH to i64
%gJ=getelementptr inbounds i8,i8*%gA,i64%gI
br i1%gF,label%gM,label%gK
gK:
%gL=bitcast i8*%gJ to i8**
call void@sml_write(i8*inreg%gA,i8**inreg%gL,i8*inreg%gG)#0
br label%g5
gM:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%gJ,i8*%gG,i32%gx,i1 false)
br label%g5
gN:
store i8*null,i8**%f,align 8
%gO=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%gO,i8**%c,align 8
%gP=call i8*@sml_alloc(i32 inreg 20)#0
%gQ=getelementptr inbounds i8,i8*%gP,i64 -4
%gR=bitcast i8*%gQ to i32*
store i32 1342177296,i32*%gR,align 4
store i8*%gP,i8**%d,align 8
%gS=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gT=bitcast i8*%gP to i8**
store i8*%gS,i8**%gT,align 8
%gU=getelementptr inbounds i8,i8*%gP,i64 8
%gV=bitcast i8*%gU to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%gV,align 8
%gW=getelementptr inbounds i8,i8*%gP,i64 16
%gX=bitcast i8*%gW to i32*
store i32 3,i32*%gX,align 4
%gY=call i8*@sml_alloc(i32 inreg 60)#0
%gZ=getelementptr inbounds i8,i8*%gY,i64 -4
%g0=bitcast i8*%gZ to i32*
store i32 1342177336,i32*%g0,align 4
%g1=getelementptr inbounds i8,i8*%gY,i64 56
%g2=bitcast i8*%g1 to i32*
store i32 1,i32*%g2,align 4
%g3=load i8*,i8**%d,align 8
%g4=bitcast i8*%gY to i8**
store i8*%g3,i8**%g4,align 8
call void@sml_raise(i8*inreg%gY)#1
unreachable
g5:
%g6=add nsw i32%d9,-1
%g7=call i8*@sml_alloc(i32 inreg 12)#0
%g8=bitcast i8*%g7 to i32*
%g9=getelementptr inbounds i8,i8*%g7,i64 -4
%ha=bitcast i8*%g9 to i32*
store i32 1342177288,i32*%ha,align 4
store i32%O,i32*%g8,align 4
%hb=getelementptr inbounds i8,i8*%g7,i64 4
%hc=bitcast i8*%hb to i32*
store i32%g6,i32*%hc,align 4
%hd=getelementptr inbounds i8,i8*%g7,i64 8
%he=bitcast i8*%hd to i32*
store i32 0,i32*%he,align 4
%hf=load i8*,i8**%f,align 8
call fastcc void@_SMLL9quickSort_44(i8*inreg%hf,i8*inreg%g7)
%hg=add nsw i32%d9,1
%hh=call i8*@sml_alloc(i32 inreg 12)#0
%hi=bitcast i8*%hh to i32*
%hj=getelementptr inbounds i8,i8*%hh,i64 -4
%hk=bitcast i8*%hj to i32*
store i32 1342177288,i32*%hk,align 4
store i32%hg,i32*%hi,align 4
%hl=getelementptr inbounds i8,i8*%hh,i64 4
%hm=bitcast i8*%hl to i32*
store i32%R,i32*%hm,align 4
%hn=getelementptr inbounds i8,i8*%hh,i64 8
%ho=bitcast i8*%hn to i32*
store i32 0,i32*%ho,align 4
br label%m
hp:
ret void
}
define internal fastcc i8*@_SMLLN10ListSorter4sortE_55(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%e,align 8
store i8*%b,i8**%c,align 8
%f=getelementptr inbounds i8,i8*%a,i64 4
%g=bitcast i8*%f to i32*
%h=load i32,i32*%g,align 4
%i=add i32%h,-1
%j=sub i32 0,%h
%k=and i32%i,%j
%l=add i32%h,7
%m=add i32%l,%k
%n=and i32%m,-8
%o=add i32%n,15
%p=and i32%o,-8
%q=lshr i32%m,3
%r=lshr i32%k,3
%s=sub nsw i32%q,%r
%t=shl i32 1,%s
%u=bitcast i8*%a to i32*
%v=load i32,i32*%u,align 4
%w=or i32%t,%v
%x=or i32%p,4
%y=icmp eq i32%v,0
br i1%y,label%E,label%z
z:
%A=sext i32%k to i64
%B=getelementptr inbounds i8,i8*%b,i64%A
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
br label%P
E:
%F=call i8*@sml_alloc(i32 inreg%h)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32%h,i32*%H,align 4
%I=load i8*,i8**%c,align 8
%J=sext i32%k to i64
%K=getelementptr inbounds i8,i8*%I,i64%J
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%F,i8*%K,i32%h,i1 false)
%L=load i8*,i8**%e,align 8
%M=getelementptr inbounds i8,i8*%L,i64 4
%N=bitcast i8*%M to i32*
%O=bitcast i8*%L to i32*
br label%P
P:
%Q=phi i64[%J,%E],[%A,%z]
%R=phi i32*[%O,%E],[%u,%z]
%S=phi i32*[%N,%E],[%g,%z]
%T=phi i8*[%I,%E],[%b,%z]
%U=phi i8*[%F,%E],[%D,%z]
store i8*%U,i8**%d,align 8
%V=sext i32%n to i64
%W=getelementptr inbounds i8,i8*%T,i64%V
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%c,align 8
%Z=load i32,i32*%S,align 4
store i8*null,i8**%e,align 8
%aa=load i32,i32*%R,align 4
%ab=call i8*@sml_alloc(i32 inreg%x)#0
%ac=or i32%p,1342177280
%ad=getelementptr inbounds i8,i8*%ab,i64 -4
%ae=bitcast i8*%ad to i32*
store i32%ac,i32*%ae,align 4
call void@llvm.memset.p0i8.i32(i8*%ab,i8 0,i32%x,i1 false)
%af=icmp eq i32%aa,0
%ag=load i8*,i8**%d,align 8
%ah=getelementptr inbounds i8,i8*%ab,i64%Q
br i1%af,label%ak,label%ai
ai:
%aj=bitcast i8*%ah to i8**
store i8*%ag,i8**%aj,align 8
br label%al
ak:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ah,i8*%ag,i32%Z,i1 false)
br label%al
al:
%am=load i8*,i8**%c,align 8
%an=getelementptr inbounds i8,i8*%ab,i64%V
%ao=bitcast i8*%an to i8**
store i8*%am,i8**%ao,align 8
%ap=sext i32%p to i64
%aq=getelementptr inbounds i8,i8*%ab,i64%ap
%ar=bitcast i8*%aq to i32*
store i32%w,i32*%ar,align 4
ret i8*%ab
}
define internal fastcc i8*@_SMLLN10ListSorter4sortE_56(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
n:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%d,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
%o=getelementptr inbounds i8,i8*%m,i64 8
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=getelementptr inbounds i8,i8*%m,i64 12
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=call fastcc i8*@_SMLFN5Array8fromListE(i32 inreg%q,i32 inreg%t)
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
%A=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%B=call fastcc i8*%x(i8*inreg%z,i8*inreg%A)
store i8*%B,i8**%c,align 8
%C=load i8*,i8**%d,align 8
%D=getelementptr inbounds i8,i8*%C,i64 8
%E=bitcast i8*%D to i32*
%F=load i32,i32*%E,align 4
%G=getelementptr inbounds i8,i8*%C,i64 12
%H=bitcast i8*%G to i32*
%I=load i32,i32*%H,align 4
%J=call i8*@sml_alloc(i32 inreg 20)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177296,i32*%L,align 4
store i8*%J,i8**%f,align 8
%M=load i8*,i8**%c,align 8
%N=bitcast i8*%J to i8**
store i8*%M,i8**%N,align 8
%O=getelementptr inbounds i8,i8*%J,i64 8
%P=bitcast i8*%O to i32*
store i32%F,i32*%P,align 4
%Q=getelementptr inbounds i8,i8*%J,i64 12
%R=bitcast i8*%Q to i32*
store i32%I,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%J,i64 16
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=call i8*@sml_alloc(i32 inreg 28)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177304,i32*%W,align 4
%X=load i8*,i8**%f,align 8
%Y=bitcast i8*%U to i8**
store i8*%X,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%U,i64 8
%aa=bitcast i8*%Z to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLL4swap_43 to void(...)*),void(...)**%aa,align 8
%ab=getelementptr inbounds i8,i8*%U,i64 16
%ac=bitcast i8*%ab to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4swap_60 to void(...)*),void(...)**%ac,align 8
%ad=getelementptr inbounds i8,i8*%U,i64 24
%ae=bitcast i8*%ad to i32*
store i32 -2147483647,i32*%ae,align 4
%af=bitcast i8**%d to i8***
%ag=load i8**,i8***%af,align 8
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%e,align 8
%ai=bitcast i8**%ag to i8*
%aj=getelementptr inbounds i8*,i8**%ag,i64 1
%ak=bitcast i8**%aj to i32*
%al=load i32,i32*%ak,align 4
%am=getelementptr inbounds i8,i8*%ai,i64 12
%an=bitcast i8*%am to i32*
%ao=load i32,i32*%an,align 4
%ap=call i8*@sml_alloc(i32 inreg 36)#0
%aq=getelementptr inbounds i8,i8*%ap,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 1342177312,i32*%ar,align 4
store i8*%ap,i8**%g,align 8
%as=load i8*,i8**%c,align 8
%at=bitcast i8*%ap to i8**
store i8*%as,i8**%at,align 8
%au=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%av=getelementptr inbounds i8,i8*%ap,i64 8
%aw=bitcast i8*%av to i8**
store i8*%au,i8**%aw,align 8
%ax=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ay=getelementptr inbounds i8,i8*%ap,i64 16
%az=bitcast i8*%ay to i8**
store i8*%ax,i8**%az,align 8
%aA=getelementptr inbounds i8,i8*%ap,i64 24
%aB=bitcast i8*%aA to i32*
store i32%al,i32*%aB,align 4
%aC=getelementptr inbounds i8,i8*%ap,i64 28
%aD=bitcast i8*%aC to i32*
store i32%ao,i32*%aD,align 4
%aE=getelementptr inbounds i8,i8*%ap,i64 32
%aF=bitcast i8*%aE to i32*
store i32 7,i32*%aF,align 4
%aG=call i8*@sml_alloc(i32 inreg 28)#0
%aH=getelementptr inbounds i8,i8*%aG,i64 -4
%aI=bitcast i8*%aH to i32*
store i32 1342177304,i32*%aI,align 4
%aJ=load i8*,i8**%g,align 8
%aK=bitcast i8*%aG to i8**
store i8*%aJ,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aG,i64 8
%aM=bitcast i8*%aL to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLL9quickSort_44 to void(...)*),void(...)**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aG,i64 16
%aO=bitcast i8*%aN to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL9quickSort_62 to void(...)*),void(...)**%aO,align 8
%aP=getelementptr inbounds i8,i8*%aG,i64 24
%aQ=bitcast i8*%aP to i32*
store i32 -2147483647,i32*%aQ,align 4
%aR=bitcast i8**%c to i32**
%aS=load i32*,i32**%aR,align 8
%aT=getelementptr inbounds i32,i32*%aS,i64 -1
%aU=load i32,i32*%aT,align 4
%aV=and i32%aU,268435455
%aW=load i8*,i8**%d,align 8
%aX=getelementptr inbounds i8,i8*%aW,i64 12
%aY=bitcast i8*%aX to i32*
%aZ=load i32,i32*%aY,align 4
%a0=udiv i32%aV,%aZ
%a1=add nsw i32%a0,-1
%a2=call i8*@sml_alloc(i32 inreg 12)#0
%a3=bitcast i8*%a2 to i32*
%a4=getelementptr inbounds i8,i8*%a2,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177288,i32*%a5,align 4
store i32 0,i32*%a3,align 4
%a6=getelementptr inbounds i8,i8*%a2,i64 4
%a7=bitcast i8*%a6 to i32*
store i32%a1,i32*%a7,align 4
%a8=getelementptr inbounds i8,i8*%a2,i64 8
%a9=bitcast i8*%a8 to i32*
store i32 0,i32*%a9,align 4
%ba=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
call fastcc void@_SMLL9quickSort_44(i8*inreg%ba,i8*inreg%a2)
%bb=load i8*,i8**%d,align 8
%bc=getelementptr inbounds i8,i8*%bb,i64 8
%bd=bitcast i8*%bc to i32*
%be=load i32,i32*%bd,align 4
%bf=getelementptr inbounds i8,i8*%bb,i64 12
%bg=bitcast i8*%bf to i32*
%bh=load i32,i32*%bg,align 4
%bi=call fastcc i8*@_SMLFN5Array5foldrE(i32 inreg%be,i32 inreg%bh,i32 inreg 1,i32 inreg 8)
%bj=getelementptr inbounds i8,i8*%bi,i64 16
%bk=bitcast i8*%bj to i8*(i8*,i8*)**
%bl=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bk,align 8
%bm=bitcast i8*%bi to i8**
%bn=load i8*,i8**%bm,align 8
store i8*%bn,i8**%e,align 8
%bo=load i8*,i8**%d,align 8
%bp=getelementptr inbounds i8,i8*%bo,i64 8
%bq=bitcast i8*%bp to i32*
%br=load i32,i32*%bq,align 4
store i8*null,i8**%d,align 8
%bs=getelementptr inbounds i8,i8*%bo,i64 12
%bt=bitcast i8*%bs to i32*
%bu=load i32,i32*%bt,align 4
%bv=call i8*@sml_alloc(i32 inreg 12)#0
%bw=bitcast i8*%bv to i32*
%bx=getelementptr inbounds i8,i8*%bv,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177288,i32*%by,align 4
store i8*%bv,i8**%d,align 8
store i32%br,i32*%bw,align 4
%bz=getelementptr inbounds i8,i8*%bv,i64 4
%bA=bitcast i8*%bz to i32*
store i32%bu,i32*%bA,align 4
%bB=getelementptr inbounds i8,i8*%bv,i64 8
%bC=bitcast i8*%bB to i32*
store i32 0,i32*%bC,align 4
%bD=call i8*@sml_alloc(i32 inreg 28)#0
%bE=getelementptr inbounds i8,i8*%bD,i64 -4
%bF=bitcast i8*%bE to i32*
store i32 1342177304,i32*%bF,align 4
%bG=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bH=bitcast i8*%bD to i8**
store i8*%bG,i8**%bH,align 8
%bI=getelementptr inbounds i8,i8*%bD,i64 8
%bJ=bitcast i8*%bI to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10ListSorter4sortE_55 to void(...)*),void(...)**%bJ,align 8
%bK=getelementptr inbounds i8,i8*%bD,i64 16
%bL=bitcast i8*%bK to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10ListSorter4sortE_55 to void(...)*),void(...)**%bL,align 8
%bM=getelementptr inbounds i8,i8*%bD,i64 24
%bN=bitcast i8*%bM to i32*
store i32 -2147483647,i32*%bN,align 4
%bO=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bP=call fastcc i8*%bl(i8*inreg%bO,i8*inreg%bD)
%bQ=getelementptr inbounds i8,i8*%bP,i64 16
%bR=bitcast i8*%bQ to i8*(i8*,i8*)**
%bS=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bR,align 8
%bT=bitcast i8*%bP to i8**
%bU=load i8*,i8**%bT,align 8
%bV=call fastcc i8*%bS(i8*inreg%bU,i8*inreg null)
%bW=getelementptr inbounds i8,i8*%bV,i64 16
%bX=bitcast i8*%bW to i8*(i8*,i8*)**
%bY=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bX,align 8
%bZ=bitcast i8*%bV to i8**
%b0=load i8*,i8**%bZ,align 8
%b1=load i8*,i8**%c,align 8
%b2=tail call fastcc i8*%bY(i8*inreg%b0,i8*inreg%b1)
ret i8*%b2
}
define internal fastcc i8*@_SMLLN10ListSorter4sortE_57(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%b,i8**%c,align 8
%e=bitcast i8*%a to i32*
%f=load i32,i32*%e,align 4
%g=getelementptr inbounds i8,i8*%a,i64 4
%h=bitcast i8*%g to i32*
%i=load i32,i32*%h,align 4
%j=call i8*@sml_alloc(i32 inreg 20)#0
%k=getelementptr inbounds i8,i8*%j,i64 -4
%l=bitcast i8*%k to i32*
store i32 1342177296,i32*%l,align 4
store i8*%j,i8**%d,align 8
%m=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%n=bitcast i8*%j to i8**
store i8*%m,i8**%n,align 8
%o=getelementptr inbounds i8,i8*%j,i64 8
%p=bitcast i8*%o to i32*
store i32%f,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%j,i64 12
%r=bitcast i8*%q to i32*
store i32%i,i32*%r,align 4
%s=getelementptr inbounds i8,i8*%j,i64 16
%t=bitcast i8*%s to i32*
store i32 1,i32*%t,align 4
%u=call i8*@sml_alloc(i32 inreg 28)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177304,i32*%w,align 4
%x=load i8*,i8**%d,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10ListSorter4sortE_56 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10ListSorter4sortE_56 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%u,i64 24
%E=bitcast i8*%D to i32*
store i32 -2147483647,i32*%E,align 4
ret i8*%u
}
define fastcc i8*@_SMLFN10ListSorter4sortE(i32 inreg%a,i32 inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 1342177288,i32*%g,align 4
store i8*%d,i8**%c,align 8
store i32%a,i32*%e,align 4
%h=getelementptr inbounds i8,i8*%d,i64 4
%i=bitcast i8*%h to i32*
store i32%b,i32*%i,align 4
%j=getelementptr inbounds i8,i8*%d,i64 8
%k=bitcast i8*%j to i32*
store i32 0,i32*%k,align 4
%l=call i8*@sml_alloc(i32 inreg 28)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177304,i32*%n,align 4
%o=load i8*,i8**%c,align 8
%p=bitcast i8*%l to i8**
store i8*%o,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%l,i64 8
%r=bitcast i8*%q to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10ListSorter4sortE_57 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10ListSorter4sortE_57 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLL4swap_60(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLL4swap_43(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLL4scan_61(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLL4scan_50(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLL9quickSort_62(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLL9quickSort_44(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN10ListSorter4sortE_63(i8*inreg%a,i8*inreg%b,i8*inreg%c)#4 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN10ListSorter4sortE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
