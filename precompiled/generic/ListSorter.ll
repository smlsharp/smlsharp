@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ9Subscript=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[61x i8]}><{[4x i8]zeroinitializer,i32 -2147483587,[61x i8]c"src/compiler/libs/list-utils/main/ListSorter.sml:44.24(1293)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[61x i8]}><{[4x i8]zeroinitializer,i32 -2147483587,[61x i8]c"src/compiler/libs/list-utils/main/ListSorter.sml:45.36(1354)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN10ListSorter4sortE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN10ListSorter4sortE_59 to void(...)*),i32 -2147483647}>,align 8
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
define internal fastcc void@_SMLLL9quickSort_40(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
O:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%e,align 8
%g=getelementptr inbounds i8,i8*%a,i64 20
%h=bitcast i8*%g to i32*
%i=load i32,i32*%h,align 4
%j=add i32%i,-1
%k=sub i32 0,%i
%l=and i32%j,%k
%m=shl i32%i,1
%n=add i32%m,-1
%o=add i32%n,%l
%p=and i32%o,%k
%q=add i32%i,7
%r=add i32%q,%p
%s=and i32%r,-8
%t=lshr i32%p,3
%u=lshr i32%l,3
%v=sub nsw i32%t,%u
%w=getelementptr inbounds i8,i8*%a,i64 16
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=shl i32%y,%v
%A=or i32%z,%y
%B=or i32%s,4
%C=bitcast i8**%e to i8***
%D=or i32%s,1342177280
%E=sext i32%l to i64
%F=sext i32%p to i64
%G=sext i32%s to i64
%H=bitcast i8**%c to i32**
%I=bitcast i8**%d to i32**
%J=bitcast i8**%d to i32**
%K=bitcast i8**%d to i32**
%L=bitcast i8**%d to i32**
br label%M
M:
%N=phi i8*[%kA,%ko],[%b,%O]
store i8*%N,i8**%c,align 8
%P=load atomic i32,i32*@sml_check_flag unordered,align 4
%Q=icmp eq i32%P,0
br i1%Q,label%T,label%R
R:
call void@sml_check(i32 inreg%P)
%S=load i8*,i8**%c,align 8
br label%T
T:
%U=phi i8*[%S,%R],[%N,%M]
%V=bitcast i8*%U to i32*
%W=load i32,i32*%V,align 4
%X=getelementptr inbounds i8,i8*%U,i64 4
%Y=bitcast i8*%X to i32*
%Z=load i32,i32*%Y,align 4
%aa=icmp slt i32%W,%Z
br i1%aa,label%ab,label%kI
ab:
%ac=add nsw i32%Z,%W
%ad=sdiv i32%ac,2
%ae=lshr i32%ac,31
%af=and i32%ae,%ac
%ag=sub nsw i32%ad,%af
%ah=icmp slt i32%ag,0
br i1%ah,label%aS,label%ai
ai:
%aj=load i8*,i8**%e,align 8
%ak=getelementptr inbounds i8,i8*%aj,i64 8
%al=bitcast i8*%ak to i32**
%am=load i32*,i32**%al,align 8
%an=getelementptr inbounds i32,i32*%am,i64 -1
%ao=load i32,i32*%an,align 4
%ap=and i32%ao,268435455
%aq=getelementptr inbounds i8,i8*%aj,i64 20
%ar=bitcast i8*%aq to i32*
%as=load i32,i32*%ar,align 4
%at=udiv i32%ap,%as
%au=icmp slt i32%ag,%at
%av=bitcast i32*%am to i8*
br i1%au,label%aw,label%aS
aw:
store i32*%am,i32**%H,align 8
%ax=getelementptr inbounds i8,i8*%aj,i64 16
%ay=bitcast i8*%ax to i32*
%az=load i32,i32*%ay,align 4
%aA=icmp eq i32%az,0
br i1%aA,label%aH,label%aB
aB:
store i8*null,i8**%c,align 8
%aC=mul i32%as,%ag
%aD=sext i32%aC to i64
%aE=getelementptr inbounds i8,i8*%av,i64%aD
%aF=bitcast i8*%aE to i8**
%aG=load i8*,i8**%aF,align 8
br label%aP
aH:
%aI=call i8*@sml_alloc(i32 inreg%as)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32%as,i32*%aK,align 4
%aL=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aM=mul i32%as,%ag
%aN=sext i32%aM to i64
%aO=getelementptr inbounds i8,i8*%aL,i64%aN
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aI,i8*%aO,i32%as,i1 false)
br label%aP
aP:
%aQ=phi i8*[%aG,%aB],[%aI,%aH]
store i8*%aQ,i8**%c,align 8
%aR=icmp slt i32%W,0
br i1%aR,label%bP,label%ba
aS:
store i8*null,i8**%e,align 8
%aT=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%aT,i8**%c,align 8
%aU=call i8*@sml_alloc(i32 inreg 20)#0
%aV=getelementptr inbounds i8,i8*%aU,i64 -4
%aW=bitcast i8*%aV to i32*
store i32 1342177296,i32*%aW,align 4
store i8*%aU,i8**%d,align 8
%aX=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aY=bitcast i8*%aU to i8**
store i8*%aX,i8**%aY,align 8
%aZ=getelementptr inbounds i8,i8*%aU,i64 8
%a0=bitcast i8*%aZ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%a0,align 8
%a1=getelementptr inbounds i8,i8*%aU,i64 16
%a2=bitcast i8*%a1 to i32*
store i32 3,i32*%a2,align 4
%a3=call i8*@sml_alloc(i32 inreg 60)#0
%a4=getelementptr inbounds i8,i8*%a3,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177336,i32*%a5,align 4
%a6=getelementptr inbounds i8,i8*%a3,i64 56
%a7=bitcast i8*%a6 to i32*
store i32 1,i32*%a7,align 4
%a8=load i8*,i8**%d,align 8
%a9=bitcast i8*%a3 to i8**
store i8*%a8,i8**%a9,align 8
call void@sml_raise(i8*inreg%a3)#1
unreachable
ba:
%bb=load i8*,i8**%e,align 8
%bc=getelementptr inbounds i8,i8*%bb,i64 8
%bd=bitcast i8*%bc to i32**
%be=load i32*,i32**%bd,align 8
%bf=getelementptr inbounds i32,i32*%be,i64 -1
%bg=load i32,i32*%bf,align 4
%bh=and i32%bg,268435455
%bi=getelementptr inbounds i8,i8*%bb,i64 20
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
%bl=udiv i32%bh,%bk
%bm=icmp slt i32%W,%bl
%bn=bitcast i32*%be to i8*
br i1%bm,label%bo,label%bP
bo:
store i32*%be,i32**%I,align 8
%bp=getelementptr inbounds i8,i8*%bb,i64 16
%bq=bitcast i8*%bp to i32*
%br=load i32,i32*%bq,align 4
%bs=icmp eq i32%br,0
br i1%bs,label%bz,label%bt
bt:
store i8*null,i8**%d,align 8
%bu=mul i32%bk,%W
%bv=sext i32%bu to i64
%bw=getelementptr inbounds i8,i8*%bn,i64%bv
%bx=bitcast i8*%bw to i8**
%by=load i8*,i8**%bx,align 8
br label%b7
bz:
%bA=call i8*@sml_alloc(i32 inreg%bk)#0
%bB=getelementptr inbounds i8,i8*%bA,i64 -4
%bC=bitcast i8*%bB to i32*
store i32%bk,i32*%bC,align 4
%bD=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bE=mul i32%bk,%W
%bF=sext i32%bE to i64
%bG=getelementptr inbounds i8,i8*%bD,i64%bF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bA,i8*%bG,i32%bk,i1 false)
%bH=load i8*,i8**%e,align 8
%bI=getelementptr inbounds i8,i8*%bH,i64 8
%bJ=bitcast i8*%bI to i32**
%bK=load i32*,i32**%bJ,align 8
%bL=getelementptr inbounds i8,i8*%bH,i64 20
%bM=bitcast i8*%bL to i32*
%bN=load i32,i32*%bM,align 4
%bO=getelementptr inbounds i32,i32*%bK,i64 -1
br label%b7
bP:
store i8*null,i8**%e,align 8
%bQ=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%bQ,i8**%c,align 8
%bR=call i8*@sml_alloc(i32 inreg 20)#0
%bS=getelementptr inbounds i8,i8*%bR,i64 -4
%bT=bitcast i8*%bS to i32*
store i32 1342177296,i32*%bT,align 4
store i8*%bR,i8**%d,align 8
%bU=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bV=bitcast i8*%bR to i8**
store i8*%bU,i8**%bV,align 8
%bW=getelementptr inbounds i8,i8*%bR,i64 8
%bX=bitcast i8*%bW to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%bX,align 8
%bY=getelementptr inbounds i8,i8*%bR,i64 16
%bZ=bitcast i8*%bY to i32*
store i32 3,i32*%bZ,align 4
%b0=call i8*@sml_alloc(i32 inreg 60)#0
%b1=getelementptr inbounds i8,i8*%b0,i64 -4
%b2=bitcast i8*%b1 to i32*
store i32 1342177336,i32*%b2,align 4
%b3=getelementptr inbounds i8,i8*%b0,i64 56
%b4=bitcast i8*%b3 to i32*
store i32 1,i32*%b4,align 4
%b5=load i8*,i8**%d,align 8
%b6=bitcast i8*%b0 to i8**
store i8*%b5,i8**%b6,align 8
call void@sml_raise(i8*inreg%b0)#1
unreachable
b7:
%b8=phi i32*[%bf,%bt],[%bO,%bz]
%b9=phi i8*[%bc,%bt],[%bI,%bz]
%ca=phi i32[%bk,%bt],[%bN,%bz]
%cb=phi i8*[%bb,%bt],[%bH,%bz]
%cc=phi i8*[%by,%bt],[%bA,%bz]
%cd=load i32,i32*%b8,align 4
%ce=and i32%cd,268435455
%cf=udiv i32%ce,%ca
%cg=icmp slt i32%ag,%cf
br i1%cg,label%ch,label%cu
ch:
%ci=bitcast i8*%b9 to i8**
%cj=load i8*,i8**%ci,align 8
%ck=getelementptr inbounds i8,i8*%cb,i64 16
%cl=bitcast i8*%ck to i32*
%cm=load i32,i32*%cl,align 4
%cn=icmp eq i32%cm,0
%co=mul i32%ca,%ag
%cp=sext i32%co to i64
%cq=getelementptr inbounds i8,i8*%cj,i64%cp
br i1%cn,label%ct,label%cr
cr:
%cs=bitcast i8*%cq to i8**
call void@sml_write(i8*inreg%cj,i8**inreg%cs,i8*inreg%cc)#0
br label%cM
ct:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cq,i8*%cc,i32%ca,i1 false)
br label%cM
cu:
store i8*null,i8**%e,align 8
%cv=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%cv,i8**%c,align 8
%cw=call i8*@sml_alloc(i32 inreg 20)#0
%cx=getelementptr inbounds i8,i8*%cw,i64 -4
%cy=bitcast i8*%cx to i32*
store i32 1342177296,i32*%cy,align 4
store i8*%cw,i8**%d,align 8
%cz=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cA=bitcast i8*%cw to i8**
store i8*%cz,i8**%cA,align 8
%cB=getelementptr inbounds i8,i8*%cw,i64 8
%cC=bitcast i8*%cB to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%cC,align 8
%cD=getelementptr inbounds i8,i8*%cw,i64 16
%cE=bitcast i8*%cD to i32*
store i32 3,i32*%cE,align 4
%cF=call i8*@sml_alloc(i32 inreg 60)#0
%cG=getelementptr inbounds i8,i8*%cF,i64 -4
%cH=bitcast i8*%cG to i32*
store i32 1342177336,i32*%cH,align 4
%cI=getelementptr inbounds i8,i8*%cF,i64 56
%cJ=bitcast i8*%cI to i32*
store i32 1,i32*%cJ,align 4
%cK=load i8*,i8**%d,align 8
%cL=bitcast i8*%cF to i8**
store i8*%cK,i8**%cL,align 8
call void@sml_raise(i8*inreg%cF)#1
unreachable
cM:
%cN=call i8*@sml_alloc(i32 inreg 12)#0
br label%cO
cO:
%cP=phi i8*[%cN,%cM],[%h3,%h2]
%cQ=phi i32[%W,%cM],[%c7,%h2]
%cR=phi i32[%W,%cM],[%h4,%h2]
%cS=add nsw i32%cQ,1
%cT=bitcast i8*%cP to i32*
%cU=getelementptr inbounds i8,i8*%cP,i64 -4
%cV=bitcast i8*%cU to i32*
store i32 1342177288,i32*%cV,align 4
store i32%cS,i32*%cT,align 4
%cW=getelementptr inbounds i8,i8*%cP,i64 4
%cX=bitcast i8*%cW to i32*
store i32%cR,i32*%cX,align 4
%cY=getelementptr inbounds i8,i8*%cP,i64 8
%cZ=bitcast i8*%cY to i32*
store i32 0,i32*%cZ,align 4
store i8*%cP,i8**%d,align 8
%c0=load atomic i32,i32*@sml_check_flag unordered,align 4
%c1=icmp eq i32%c0,0
br i1%c1,label%c4,label%c2
c2:
call void@sml_check(i32 inreg%c0)
%c3=load i8*,i8**%d,align 8
br label%c4
c4:
%c5=phi i8*[%c3,%c2],[%cP,%cO]
%c6=bitcast i8*%c5 to i32*
%c7=load i32,i32*%c6,align 4
store i8*null,i8**%d,align 8
%c8=getelementptr inbounds i8,i8*%c5,i64 4
%c9=bitcast i8*%c8 to i32*
%da=load i32,i32*%c9,align 4
%db=icmp sgt i32%c7,%Z
br i1%db,label%h7,label%dc
dc:
%dd=load i8**,i8***%C,align 8
%de=load i8*,i8**%dd,align 8
%df=getelementptr inbounds i8,i8*%de,i64 16
%dg=bitcast i8*%df to i8*(i8*,i8*)**
%dh=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dg,align 8
%di=bitcast i8*%de to i8**
%dj=load i8*,i8**%di,align 8
store i8*%dj,i8**%f,align 8
%dk=icmp slt i32%c7,0
br i1%dk,label%d9,label%dl
dl:
%dm=bitcast i8**%dd to i8*
%dn=getelementptr inbounds i8*,i8**%dd,i64 1
%do=bitcast i8**%dn to i32**
%dp=load i32*,i32**%do,align 8
%dq=getelementptr inbounds i32,i32*%dp,i64 -1
%dr=load i32,i32*%dq,align 4
%ds=and i32%dr,268435455
%dt=getelementptr inbounds i8,i8*%dm,i64 20
%du=bitcast i8*%dt to i32*
%dv=load i32,i32*%du,align 4
%dw=udiv i32%ds,%dv
%dx=icmp slt i32%c7,%dw
%dy=bitcast i32*%dp to i8*
br i1%dx,label%dz,label%d9
dz:
store i32*%dp,i32**%J,align 8
%dA=getelementptr inbounds i8*,i8**%dd,i64 2
%dB=bitcast i8**%dA to i32*
%dC=load i32,i32*%dB,align 4
%dD=icmp eq i32%dC,0
br i1%dD,label%dK,label%dE
dE:
store i8*null,i8**%d,align 8
%dF=mul i32%dv,%c7
%dG=sext i32%dF to i64
%dH=getelementptr inbounds i8,i8*%dy,i64%dG
%dI=bitcast i8*%dH to i8**
%dJ=load i8*,i8**%dI,align 8
br label%dZ
dK:
%dL=call i8*@sml_alloc(i32 inreg%dv)#0
%dM=getelementptr inbounds i8,i8*%dL,i64 -4
%dN=bitcast i8*%dM to i32*
store i32%dv,i32*%dN,align 4
%dO=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%dP=mul i32%dv,%c7
%dQ=sext i32%dP to i64
%dR=getelementptr inbounds i8,i8*%dO,i64%dQ
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%dL,i8*%dR,i32%dv,i1 false)
%dS=load i8*,i8**%e,align 8
%dT=getelementptr inbounds i8,i8*%dS,i64 20
%dU=bitcast i8*%dT to i32*
%dV=load i32,i32*%dU,align 4
%dW=getelementptr inbounds i8,i8*%dS,i64 16
%dX=bitcast i8*%dW to i32*
%dY=load i32,i32*%dX,align 4
br label%dZ
dZ:
%d0=phi i32[%dC,%dE],[%dY,%dK]
%d1=phi i32[%dv,%dE],[%dV,%dK]
%d2=phi i8*[%dJ,%dE],[%dL,%dK]
store i8*%d2,i8**%d,align 8
%d3=call i8*@sml_alloc(i32 inreg%B)#0
%d4=getelementptr inbounds i8,i8*%d3,i64 -4
%d5=bitcast i8*%d4 to i32*
store i32%D,i32*%d5,align 4
call void@llvm.memset.p0i8.i32(i8*%d3,i8 0,i32%B,i1 false)
%d6=icmp eq i32%d0,0
%d7=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%d8=getelementptr inbounds i8,i8*%d3,i64%E
br i1%d6,label%er,label%eu
d9:
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%ea=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%ea,i8**%c,align 8
%eb=call i8*@sml_alloc(i32 inreg 20)#0
%ec=getelementptr inbounds i8,i8*%eb,i64 -4
%ed=bitcast i8*%ec to i32*
store i32 1342177296,i32*%ed,align 4
store i8*%eb,i8**%d,align 8
%ee=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ef=bitcast i8*%eb to i8**
store i8*%ee,i8**%ef,align 8
%eg=getelementptr inbounds i8,i8*%eb,i64 8
%eh=bitcast i8*%eg to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%eh,align 8
%ei=getelementptr inbounds i8,i8*%eb,i64 16
%ej=bitcast i8*%ei to i32*
store i32 3,i32*%ej,align 4
%ek=call i8*@sml_alloc(i32 inreg 60)#0
%el=getelementptr inbounds i8,i8*%ek,i64 -4
%em=bitcast i8*%el to i32*
store i32 1342177336,i32*%em,align 4
%en=getelementptr inbounds i8,i8*%ek,i64 56
%eo=bitcast i8*%en to i32*
store i32 1,i32*%eo,align 4
%ep=load i8*,i8**%d,align 8
%eq=bitcast i8*%ek to i8**
store i8*%ep,i8**%eq,align 8
call void@sml_raise(i8*inreg%ek)#1
unreachable
er:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%d8,i8*%d7,i32%d1,i1 false)
%es=load i8*,i8**%c,align 8
%et=getelementptr inbounds i8,i8*%d3,i64%F
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%et,i8*%es,i32%d1,i1 false)
br label%ez
eu:
%ev=bitcast i8*%d8 to i8**
store i8*%d7,i8**%ev,align 8
%ew=load i8*,i8**%c,align 8
%ex=getelementptr inbounds i8,i8*%d3,i64%F
%ey=bitcast i8*%ex to i8**
store i8*%ew,i8**%ey,align 8
br label%ez
ez:
%eA=getelementptr inbounds i8,i8*%d3,i64%G
%eB=bitcast i8*%eA to i32*
store i32%A,i32*%eB,align 4
%eC=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%eD=call fastcc i8*%dh(i8*inreg%eC,i8*inreg%d3)
%eE=bitcast i8*%eD to i32*
%eF=load i32,i32*%eE,align 4
%eG=icmp eq i32%eF,2
br i1%eG,label%eH,label%h5
eH:
%eI=add nsw i32%da,1
%eJ=icmp slt i32%da,-1
br i1%eJ,label%fp,label%eK
eK:
%eL=load i8*,i8**%e,align 8
%eM=getelementptr inbounds i8,i8*%eL,i64 8
%eN=bitcast i8*%eM to i32**
%eO=load i32*,i32**%eN,align 8
%eP=getelementptr inbounds i32,i32*%eO,i64 -1
%eQ=load i32,i32*%eP,align 4
%eR=and i32%eQ,268435455
%eS=getelementptr inbounds i8,i8*%eL,i64 20
%eT=bitcast i8*%eS to i32*
%eU=load i32,i32*%eT,align 4
%eV=udiv i32%eR,%eU
%eW=icmp slt i32%eI,%eV
%eX=bitcast i32*%eO to i8*
br i1%eW,label%eY,label%fp
eY:
store i32*%eO,i32**%K,align 8
%eZ=getelementptr inbounds i8,i8*%eL,i64 16
%e0=bitcast i8*%eZ to i32*
%e1=load i32,i32*%e0,align 4
%e2=icmp eq i32%e1,0
br i1%e2,label%e9,label%e3
e3:
store i8*null,i8**%d,align 8
%e4=mul i32%eU,%eI
%e5=sext i32%e4 to i64
%e6=getelementptr inbounds i8,i8*%eX,i64%e5
%e7=bitcast i8*%e6 to i8**
%e8=load i8*,i8**%e7,align 8
br label%fH
e9:
%fa=call i8*@sml_alloc(i32 inreg%eU)#0
%fb=getelementptr inbounds i8,i8*%fa,i64 -4
%fc=bitcast i8*%fb to i32*
store i32%eU,i32*%fc,align 4
%fd=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fe=mul i32%eU,%eI
%ff=sext i32%fe to i64
%fg=getelementptr inbounds i8,i8*%fd,i64%ff
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%fa,i8*%fg,i32%eU,i1 false)
%fh=load i8*,i8**%e,align 8
%fi=getelementptr inbounds i8,i8*%fh,i64 8
%fj=bitcast i8*%fi to i32**
%fk=load i32*,i32**%fj,align 8
%fl=getelementptr inbounds i8,i8*%fh,i64 20
%fm=bitcast i8*%fl to i32*
%fn=load i32,i32*%fm,align 4
%fo=getelementptr inbounds i32,i32*%fk,i64 -1
br label%fH
fp:
store i8*null,i8**%e,align 8
%fq=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%fq,i8**%c,align 8
%fr=call i8*@sml_alloc(i32 inreg 20)#0
%fs=getelementptr inbounds i8,i8*%fr,i64 -4
%ft=bitcast i8*%fs to i32*
store i32 1342177296,i32*%ft,align 4
store i8*%fr,i8**%d,align 8
%fu=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fv=bitcast i8*%fr to i8**
store i8*%fu,i8**%fv,align 8
%fw=getelementptr inbounds i8,i8*%fr,i64 8
%fx=bitcast i8*%fw to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%fx,align 8
%fy=getelementptr inbounds i8,i8*%fr,i64 16
%fz=bitcast i8*%fy to i32*
store i32 3,i32*%fz,align 4
%fA=call i8*@sml_alloc(i32 inreg 60)#0
%fB=getelementptr inbounds i8,i8*%fA,i64 -4
%fC=bitcast i8*%fB to i32*
store i32 1342177336,i32*%fC,align 4
%fD=getelementptr inbounds i8,i8*%fA,i64 56
%fE=bitcast i8*%fD to i32*
store i32 1,i32*%fE,align 4
%fF=load i8*,i8**%d,align 8
%fG=bitcast i8*%fA to i8**
store i8*%fF,i8**%fG,align 8
call void@sml_raise(i8*inreg%fA)#1
unreachable
fH:
%fI=phi i32*[%fo,%e9],[%eP,%e3]
%fJ=phi i8*[%fi,%e9],[%eM,%e3]
%fK=phi i32[%fn,%e9],[%eU,%e3]
%fL=phi i8*[%fh,%e9],[%eL,%e3]
%fM=phi i8*[%fa,%e9],[%e8,%e3]
store i8*%fM,i8**%d,align 8
%fN=load i32,i32*%fI,align 4
%fO=and i32%fN,268435455
%fP=udiv i32%fO,%fK
%fQ=icmp slt i32%c7,%fP
br i1%fQ,label%fR,label%gk
fR:
%fS=bitcast i8*%fJ to i8**
%fT=load i8*,i8**%fS,align 8
store i8*%fT,i8**%f,align 8
%fU=getelementptr inbounds i8,i8*%fL,i64 16
%fV=bitcast i8*%fU to i32*
%fW=load i32,i32*%fV,align 4
%fX=icmp eq i32%fW,0
br i1%fX,label%f5,label%fY
fY:
%fZ=bitcast i8*%fT to i32*
store i8*null,i8**%f,align 8
%f0=mul i32%fK,%c7
%f1=sext i32%f0 to i64
%f2=getelementptr inbounds i8,i8*%fT,i64%f1
%f3=bitcast i8*%f2 to i8**
%f4=load i8*,i8**%f3,align 8
br label%gC
f5:
%f6=call i8*@sml_alloc(i32 inreg%fK)#0
%f7=getelementptr inbounds i8,i8*%f6,i64 -4
%f8=bitcast i8*%f7 to i32*
store i32%fK,i32*%f8,align 4
%f9=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ga=mul i32%fK,%c7
%gb=sext i32%ga to i64
%gc=getelementptr inbounds i8,i8*%f9,i64%gb
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%f6,i8*%gc,i32%fK,i1 false)
%gd=load i8*,i8**%e,align 8
%ge=getelementptr inbounds i8,i8*%gd,i64 8
%gf=bitcast i8*%ge to i32**
%gg=load i32*,i32**%gf,align 8
%gh=getelementptr inbounds i8,i8*%gd,i64 20
%gi=bitcast i8*%gh to i32*
%gj=load i32,i32*%gi,align 4
br label%gC
gk:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
%gl=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%gl,i8**%c,align 8
%gm=call i8*@sml_alloc(i32 inreg 20)#0
%gn=getelementptr inbounds i8,i8*%gm,i64 -4
%go=bitcast i8*%gn to i32*
store i32 1342177296,i32*%go,align 4
store i8*%gm,i8**%d,align 8
%gp=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gq=bitcast i8*%gm to i8**
store i8*%gp,i8**%gq,align 8
%gr=getelementptr inbounds i8,i8*%gm,i64 8
%gs=bitcast i8*%gr to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%gs,align 8
%gt=getelementptr inbounds i8,i8*%gm,i64 16
%gu=bitcast i8*%gt to i32*
store i32 3,i32*%gu,align 4
%gv=call i8*@sml_alloc(i32 inreg 60)#0
%gw=getelementptr inbounds i8,i8*%gv,i64 -4
%gx=bitcast i8*%gw to i32*
store i32 1342177336,i32*%gx,align 4
%gy=getelementptr inbounds i8,i8*%gv,i64 56
%gz=bitcast i8*%gy to i32*
store i32 1,i32*%gz,align 4
%gA=load i8*,i8**%d,align 8
%gB=bitcast i8*%gv to i8**
store i8*%gA,i8**%gB,align 8
call void@sml_raise(i8*inreg%gv)#1
unreachable
gC:
%gD=phi i8*[%fJ,%fY],[%ge,%f5]
%gE=phi i32[%fK,%fY],[%gj,%f5]
%gF=phi i32*[%fZ,%fY],[%gg,%f5]
%gG=phi i8*[%fL,%fY],[%gd,%f5]
%gH=phi i8*[%f4,%fY],[%f6,%f5]
%gI=getelementptr inbounds i32,i32*%gF,i64 -1
%gJ=load i32,i32*%gI,align 4
%gK=and i32%gJ,268435455
%gL=udiv i32%gK,%gE
%gM=icmp slt i32%eI,%gL
br i1%gM,label%gN,label%g0
gN:
%gO=bitcast i8*%gD to i8**
%gP=load i8*,i8**%gO,align 8
%gQ=getelementptr inbounds i8,i8*%gG,i64 16
%gR=bitcast i8*%gQ to i32*
%gS=load i32,i32*%gR,align 4
%gT=icmp eq i32%gS,0
%gU=mul i32%gE,%eI
%gV=sext i32%gU to i64
%gW=getelementptr inbounds i8,i8*%gP,i64%gV
br i1%gT,label%gZ,label%gX
gX:
%gY=bitcast i8*%gW to i8**
call void@sml_write(i8*inreg%gP,i8**inreg%gY,i8*inreg%gH)#0
br label%hi
gZ:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%gW,i8*%gH,i32%gE,i1 false)
br label%hi
g0:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
%g1=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%g1,i8**%c,align 8
%g2=call i8*@sml_alloc(i32 inreg 20)#0
%g3=getelementptr inbounds i8,i8*%g2,i64 -4
%g4=bitcast i8*%g3 to i32*
store i32 1342177296,i32*%g4,align 4
store i8*%g2,i8**%d,align 8
%g5=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%g6=bitcast i8*%g2 to i8**
store i8*%g5,i8**%g6,align 8
%g7=getelementptr inbounds i8,i8*%g2,i64 8
%g8=bitcast i8*%g7 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%g8,align 8
%g9=getelementptr inbounds i8,i8*%g2,i64 16
%ha=bitcast i8*%g9 to i32*
store i32 3,i32*%ha,align 4
%hb=call i8*@sml_alloc(i32 inreg 60)#0
%hc=getelementptr inbounds i8,i8*%hb,i64 -4
%hd=bitcast i8*%hc to i32*
store i32 1342177336,i32*%hd,align 4
%he=getelementptr inbounds i8,i8*%hb,i64 56
%hf=bitcast i8*%he to i32*
store i32 1,i32*%hf,align 4
%hg=load i8*,i8**%d,align 8
%hh=bitcast i8*%hb to i8**
store i8*%hg,i8**%hh,align 8
call void@sml_raise(i8*inreg%hb)#1
unreachable
hi:
%hj=load i8*,i8**%e,align 8
%hk=getelementptr inbounds i8,i8*%hj,i64 8
%hl=bitcast i8*%hk to i32**
%hm=load i32*,i32**%hl,align 8
%hn=getelementptr inbounds i32,i32*%hm,i64 -1
%ho=load i32,i32*%hn,align 4
%hp=and i32%ho,268435455
%hq=getelementptr inbounds i8,i8*%hj,i64 20
%hr=bitcast i8*%hq to i32*
%hs=load i32,i32*%hr,align 4
%ht=udiv i32%hp,%hs
%hu=icmp slt i32%c7,%ht
%hv=bitcast i32*%hm to i8*
br i1%hu,label%hw,label%hI
hw:
%hx=getelementptr inbounds i8,i8*%hj,i64 16
%hy=bitcast i8*%hx to i32*
%hz=load i32,i32*%hy,align 4
%hA=icmp eq i32%hz,0
%hB=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%hC=mul i32%hs,%c7
%hD=sext i32%hC to i64
%hE=getelementptr inbounds i8,i8*%hv,i64%hD
br i1%hA,label%hH,label%hF
hF:
%hG=bitcast i8*%hE to i8**
call void@sml_write(i8*inreg%hv,i8**inreg%hG,i8*inreg%hB)#0
br label%h0
hH:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%hE,i8*%hB,i32%hs,i1 false)
br label%h0
hI:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
%hJ=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%hJ,i8**%c,align 8
%hK=call i8*@sml_alloc(i32 inreg 20)#0
%hL=getelementptr inbounds i8,i8*%hK,i64 -4
%hM=bitcast i8*%hL to i32*
store i32 1342177296,i32*%hM,align 4
store i8*%hK,i8**%d,align 8
%hN=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%hO=bitcast i8*%hK to i8**
store i8*%hN,i8**%hO,align 8
%hP=getelementptr inbounds i8,i8*%hK,i64 8
%hQ=bitcast i8*%hP to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%hQ,align 8
%hR=getelementptr inbounds i8,i8*%hK,i64 16
%hS=bitcast i8*%hR to i32*
store i32 3,i32*%hS,align 4
%hT=call i8*@sml_alloc(i32 inreg 60)#0
%hU=getelementptr inbounds i8,i8*%hT,i64 -4
%hV=bitcast i8*%hU to i32*
store i32 1342177336,i32*%hV,align 4
%hW=getelementptr inbounds i8,i8*%hT,i64 56
%hX=bitcast i8*%hW to i32*
store i32 1,i32*%hX,align 4
%hY=load i8*,i8**%d,align 8
%hZ=bitcast i8*%hT to i8**
store i8*%hY,i8**%hZ,align 8
call void@sml_raise(i8*inreg%hT)#1
unreachable
h0:
%h1=call i8*@sml_alloc(i32 inreg 12)#0
br label%h2
h2:
%h3=phi i8*[%h1,%h0],[%h6,%h5]
%h4=phi i32[%eI,%h0],[%da,%h5]
br label%cO
h5:
%h6=call i8*@sml_alloc(i32 inreg 12)#0
br label%h2
h7:
%h8=icmp slt i32%da,0
br i1%h8,label%iG,label%h9
h9:
%ia=load i8*,i8**%e,align 8
%ib=getelementptr inbounds i8,i8*%ia,i64 8
%ic=bitcast i8*%ib to i32**
%id=load i32*,i32**%ic,align 8
%ie=getelementptr inbounds i32,i32*%id,i64 -1
%if=load i32,i32*%ie,align 4
%ig=and i32%if,268435455
%ih=getelementptr inbounds i8,i8*%ia,i64 20
%ii=bitcast i8*%ih to i32*
%ij=load i32,i32*%ii,align 4
%ik=udiv i32%ig,%ij
%il=icmp slt i32%da,%ik
%im=bitcast i32*%id to i8*
br i1%il,label%in,label%iG
in:
store i32*%id,i32**%L,align 8
%io=getelementptr inbounds i8,i8*%ia,i64 16
%ip=bitcast i8*%io to i32*
%iq=load i32,i32*%ip,align 4
%ir=icmp eq i32%iq,0
br i1%ir,label%iy,label%is
is:
store i8*null,i8**%d,align 8
%it=mul i32%ij,%da
%iu=sext i32%it to i64
%iv=getelementptr inbounds i8,i8*%im,i64%iu
%iw=bitcast i8*%iv to i8**
%ix=load i8*,i8**%iw,align 8
br label%iY
iy:
%iz=call i8*@sml_alloc(i32 inreg%ij)#0
%iA=getelementptr inbounds i8,i8*%iz,i64 -4
%iB=bitcast i8*%iA to i32*
store i32%ij,i32*%iB,align 4
%iC=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%iD=mul i32%ij,%da
%iE=sext i32%iD to i64
%iF=getelementptr inbounds i8,i8*%iC,i64%iE
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%iz,i8*%iF,i32%ij,i1 false)
br label%iY
iG:
store i8*null,i8**%e,align 8
%iH=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%iH,i8**%c,align 8
%iI=call i8*@sml_alloc(i32 inreg 20)#0
%iJ=getelementptr inbounds i8,i8*%iI,i64 -4
%iK=bitcast i8*%iJ to i32*
store i32 1342177296,i32*%iK,align 4
store i8*%iI,i8**%d,align 8
%iL=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%iM=bitcast i8*%iI to i8**
store i8*%iL,i8**%iM,align 8
%iN=getelementptr inbounds i8,i8*%iI,i64 8
%iO=bitcast i8*%iN to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%iO,align 8
%iP=getelementptr inbounds i8,i8*%iI,i64 16
%iQ=bitcast i8*%iP to i32*
store i32 3,i32*%iQ,align 4
%iR=call i8*@sml_alloc(i32 inreg 60)#0
%iS=getelementptr inbounds i8,i8*%iR,i64 -4
%iT=bitcast i8*%iS to i32*
store i32 1342177336,i32*%iT,align 4
%iU=getelementptr inbounds i8,i8*%iR,i64 56
%iV=bitcast i8*%iU to i32*
store i32 1,i32*%iV,align 4
%iW=load i8*,i8**%d,align 8
%iX=bitcast i8*%iR to i8**
store i8*%iW,i8**%iX,align 8
call void@sml_raise(i8*inreg%iR)#1
unreachable
iY:
%iZ=phi i8*[%ix,%is],[%iz,%iy]
%i0=load i8*,i8**%e,align 8
%i1=getelementptr inbounds i8,i8*%i0,i64 8
%i2=bitcast i8*%i1 to i32**
%i3=load i32*,i32**%i2,align 8
%i4=getelementptr inbounds i32,i32*%i3,i64 -1
%i5=load i32,i32*%i4,align 4
%i6=and i32%i5,268435455
%i7=getelementptr inbounds i8,i8*%i0,i64 20
%i8=bitcast i8*%i7 to i32*
%i9=load i32,i32*%i8,align 4
%ja=udiv i32%i6,%i9
%jb=icmp slt i32%W,%ja
%jc=bitcast i32*%i3 to i8*
br i1%jb,label%jd,label%jo
jd:
%je=getelementptr inbounds i8,i8*%i0,i64 16
%jf=bitcast i8*%je to i32*
%jg=load i32,i32*%jf,align 4
%jh=icmp eq i32%jg,0
%ji=mul i32%i9,%W
%jj=sext i32%ji to i64
%jk=getelementptr inbounds i8,i8*%jc,i64%jj
br i1%jh,label%jn,label%jl
jl:
%jm=bitcast i8*%jk to i8**
call void@sml_write(i8*inreg%jc,i8**inreg%jm,i8*inreg%iZ)#0
br label%jG
jn:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%jk,i8*%iZ,i32%i9,i1 false)
br label%jG
jo:
store i8*null,i8**%e,align 8
%jp=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%jp,i8**%c,align 8
%jq=call i8*@sml_alloc(i32 inreg 20)#0
%jr=getelementptr inbounds i8,i8*%jq,i64 -4
%js=bitcast i8*%jr to i32*
store i32 1342177296,i32*%js,align 4
store i8*%jq,i8**%d,align 8
%jt=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ju=bitcast i8*%jq to i8**
store i8*%jt,i8**%ju,align 8
%jv=getelementptr inbounds i8,i8*%jq,i64 8
%jw=bitcast i8*%jv to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%jw,align 8
%jx=getelementptr inbounds i8,i8*%jq,i64 16
%jy=bitcast i8*%jx to i32*
store i32 3,i32*%jy,align 4
%jz=call i8*@sml_alloc(i32 inreg 60)#0
%jA=getelementptr inbounds i8,i8*%jz,i64 -4
%jB=bitcast i8*%jA to i32*
store i32 1342177336,i32*%jB,align 4
%jC=getelementptr inbounds i8,i8*%jz,i64 56
%jD=bitcast i8*%jC to i32*
store i32 1,i32*%jD,align 4
%jE=load i8*,i8**%d,align 8
%jF=bitcast i8*%jz to i8**
store i8*%jE,i8**%jF,align 8
call void@sml_raise(i8*inreg%jz)#1
unreachable
jG:
%jH=load i8*,i8**%e,align 8
%jI=getelementptr inbounds i8,i8*%jH,i64 8
%jJ=bitcast i8*%jI to i32**
%jK=load i32*,i32**%jJ,align 8
%jL=getelementptr inbounds i32,i32*%jK,i64 -1
%jM=load i32,i32*%jL,align 4
%jN=and i32%jM,268435455
%jO=getelementptr inbounds i8,i8*%jH,i64 20
%jP=bitcast i8*%jO to i32*
%jQ=load i32,i32*%jP,align 4
%jR=udiv i32%jN,%jQ
%jS=icmp slt i32%da,%jR
%jT=bitcast i32*%jK to i8*
br i1%jS,label%jU,label%j6
jU:
%jV=getelementptr inbounds i8,i8*%jH,i64 16
%jW=bitcast i8*%jV to i32*
%jX=load i32,i32*%jW,align 4
%jY=icmp eq i32%jX,0
%jZ=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%j0=mul i32%jQ,%da
%j1=sext i32%j0 to i64
%j2=getelementptr inbounds i8,i8*%jT,i64%j1
br i1%jY,label%j5,label%j3
j3:
%j4=bitcast i8*%j2 to i8**
call void@sml_write(i8*inreg%jT,i8**inreg%j4,i8*inreg%jZ)#0
br label%ko
j5:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%j2,i8*%jZ,i32%jQ,i1 false)
br label%ko
j6:
store i8*null,i8**%e,align 8
%j7=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%j7,i8**%c,align 8
%j8=call i8*@sml_alloc(i32 inreg 20)#0
%j9=getelementptr inbounds i8,i8*%j8,i64 -4
%ka=bitcast i8*%j9 to i32*
store i32 1342177296,i32*%ka,align 4
store i8*%j8,i8**%d,align 8
%kb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%kc=bitcast i8*%j8 to i8**
store i8*%kb,i8**%kc,align 8
%kd=getelementptr inbounds i8,i8*%j8,i64 8
%ke=bitcast i8*%kd to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@b,i64 0,i32 2,i64 0),i8**%ke,align 8
%kf=getelementptr inbounds i8,i8*%j8,i64 16
%kg=bitcast i8*%kf to i32*
store i32 3,i32*%kg,align 4
%kh=call i8*@sml_alloc(i32 inreg 60)#0
%ki=getelementptr inbounds i8,i8*%kh,i64 -4
%kj=bitcast i8*%ki to i32*
store i32 1342177336,i32*%kj,align 4
%kk=getelementptr inbounds i8,i8*%kh,i64 56
%kl=bitcast i8*%kk to i32*
store i32 1,i32*%kl,align 4
%km=load i8*,i8**%d,align 8
%kn=bitcast i8*%kh to i8**
store i8*%km,i8**%kn,align 8
call void@sml_raise(i8*inreg%kh)#1
unreachable
ko:
%kp=add nsw i32%da,-1
%kq=call i8*@sml_alloc(i32 inreg 12)#0
%kr=bitcast i8*%kq to i32*
%ks=getelementptr inbounds i8,i8*%kq,i64 -4
%kt=bitcast i8*%ks to i32*
store i32 1342177288,i32*%kt,align 4
store i32%W,i32*%kr,align 4
%ku=getelementptr inbounds i8,i8*%kq,i64 4
%kv=bitcast i8*%ku to i32*
store i32%kp,i32*%kv,align 4
%kw=getelementptr inbounds i8,i8*%kq,i64 8
%kx=bitcast i8*%kw to i32*
store i32 0,i32*%kx,align 4
%ky=load i8*,i8**%e,align 8
call fastcc void@_SMLLL9quickSort_40(i8*inreg%ky,i8*inreg%kq)
%kz=add nsw i32%da,1
%kA=call i8*@sml_alloc(i32 inreg 12)#0
%kB=bitcast i8*%kA to i32*
%kC=getelementptr inbounds i8,i8*%kA,i64 -4
%kD=bitcast i8*%kC to i32*
store i32 1342177288,i32*%kD,align 4
store i32%kz,i32*%kB,align 4
%kE=getelementptr inbounds i8,i8*%kA,i64 4
%kF=bitcast i8*%kE to i32*
store i32%Z,i32*%kF,align 4
%kG=getelementptr inbounds i8,i8*%kA,i64 8
%kH=bitcast i8*%kG to i32*
store i32 0,i32*%kH,align 4
br label%M
kI:
ret void
}
define internal fastcc i8*@_SMLLLN10ListSorter4sortE_53(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
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
%L=load i8*,i8**%d,align 8
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
store i8*%U,i8**%e,align 8
%V=load i32,i32*%S,align 4
store i8*null,i8**%d,align 8
%W=load i32,i32*%R,align 4
%X=sext i32%n to i64
%Y=getelementptr inbounds i8,i8*%T,i64%X
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
store i8*%aa,i8**%c,align 8
%ab=call i8*@sml_alloc(i32 inreg%x)#0
%ac=or i32%p,1342177280
%ad=getelementptr inbounds i8,i8*%ab,i64 -4
%ae=bitcast i8*%ad to i32*
store i32%ac,i32*%ae,align 4
call void@llvm.memset.p0i8.i32(i8*%ab,i8 0,i32%x,i1 false)
%af=icmp eq i32%W,0
%ag=load i8*,i8**%e,align 8
%ah=getelementptr inbounds i8,i8*%ab,i64%Q
br i1%af,label%ai,label%aj
ai:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ah,i8*%ag,i32%V,i1 false)
br label%al
aj:
%ak=bitcast i8*%ah to i8**
store i8*%ag,i8**%ak,align 8
br label%al
al:
%am=load i8*,i8**%c,align 8
%an=getelementptr inbounds i8,i8*%ab,i64%X
%ao=bitcast i8*%an to i8**
store i8*%am,i8**%ao,align 8
%ap=sext i32%p to i64
%aq=getelementptr inbounds i8,i8*%ab,i64%ap
%ar=bitcast i8*%aq to i32*
store i32%w,i32*%ar,align 4
ret i8*%ab
}
define internal fastcc i8*@_SMLLLN10ListSorter4sortE_54(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
m:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%d,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%a,%m]
%n=getelementptr inbounds i8,i8*%l,i64 8
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
%q=getelementptr inbounds i8,i8*%l,i64 12
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=call fastcc i8*@_SMLFN5Array8fromListE(i32 inreg%p,i32 inreg%s)
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=bitcast i8**%d to i8***
%C=load i8**,i8***%B,align 8
%D=load i8*,i8**%C,align 8
store i8*%D,i8**%e,align 8
%E=bitcast i8**%C to i8*
%F=getelementptr inbounds i8*,i8**%C,i64 1
%G=bitcast i8**%F to i32*
%H=load i32,i32*%G,align 4
%I=getelementptr inbounds i8,i8*%E,i64 12
%J=bitcast i8*%I to i32*
%K=load i32,i32*%J,align 4
%L=call i8*@sml_alloc(i32 inreg 28)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177304,i32*%N,align 4
store i8*%L,i8**%f,align 8
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=load i8*,i8**%c,align 8
%R=getelementptr inbounds i8,i8*%L,i64 8
%S=bitcast i8*%R to i8**
store i8*%Q,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%L,i64 16
%U=bitcast i8*%T to i32*
store i32%H,i32*%U,align 4
%V=getelementptr inbounds i8,i8*%L,i64 20
%W=bitcast i8*%V to i32*
store i32%K,i32*%W,align 4
%X=getelementptr inbounds i8,i8*%L,i64 24
%Y=bitcast i8*%X to i32*
store i32 3,i32*%Y,align 4
%Z=call i8*@sml_alloc(i32 inreg 28)#0
%aa=getelementptr inbounds i8,i8*%Z,i64 -4
%ab=bitcast i8*%aa to i32*
store i32 1342177304,i32*%ab,align 4
%ac=load i8*,i8**%f,align 8
%ad=bitcast i8*%Z to i8**
store i8*%ac,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%Z,i64 8
%af=bitcast i8*%ae to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLL9quickSort_40 to void(...)*),void(...)**%af,align 8
%ag=getelementptr inbounds i8,i8*%Z,i64 16
%ah=bitcast i8*%ag to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL9quickSort_58 to void(...)*),void(...)**%ah,align 8
%ai=getelementptr inbounds i8,i8*%Z,i64 24
%aj=bitcast i8*%ai to i32*
store i32 -2147483647,i32*%aj,align 4
%ak=bitcast i8**%c to i32**
%al=load i32*,i32**%ak,align 8
%am=getelementptr inbounds i32,i32*%al,i64 -1
%an=load i32,i32*%am,align 4
%ao=and i32%an,268435455
%ap=load i8*,i8**%d,align 8
%aq=getelementptr inbounds i8,i8*%ap,i64 12
%ar=bitcast i8*%aq to i32*
%as=load i32,i32*%ar,align 4
%at=udiv i32%ao,%as
%au=add nsw i32%at,-1
%av=call i8*@sml_alloc(i32 inreg 12)#0
%aw=bitcast i8*%av to i32*
%ax=getelementptr inbounds i8,i8*%av,i64 -4
%ay=bitcast i8*%ax to i32*
store i32 1342177288,i32*%ay,align 4
store i32 0,i32*%aw,align 4
%az=getelementptr inbounds i8,i8*%av,i64 4
%aA=bitcast i8*%az to i32*
store i32%au,i32*%aA,align 4
%aB=getelementptr inbounds i8,i8*%av,i64 8
%aC=bitcast i8*%aB to i32*
store i32 0,i32*%aC,align 4
%aD=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
call fastcc void@_SMLLL9quickSort_40(i8*inreg%aD,i8*inreg%av)
%aE=load i8*,i8**%d,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 8
%aG=bitcast i8*%aF to i32*
%aH=load i32,i32*%aG,align 4
%aI=getelementptr inbounds i8,i8*%aE,i64 12
%aJ=bitcast i8*%aI to i32*
%aK=load i32,i32*%aJ,align 4
%aL=call fastcc i8*@_SMLFN5Array5foldrE(i32 inreg%aH,i32 inreg%aK,i32 inreg 1,i32 inreg 8)
%aM=getelementptr inbounds i8,i8*%aL,i64 16
%aN=bitcast i8*%aM to i8*(i8*,i8*)**
%aO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aN,align 8
%aP=bitcast i8*%aL to i8**
%aQ=load i8*,i8**%aP,align 8
store i8*%aQ,i8**%e,align 8
%aR=load i8*,i8**%d,align 8
%aS=getelementptr inbounds i8,i8*%aR,i64 8
%aT=bitcast i8*%aS to i32*
%aU=load i32,i32*%aT,align 4
store i8*null,i8**%d,align 8
%aV=getelementptr inbounds i8,i8*%aR,i64 12
%aW=bitcast i8*%aV to i32*
%aX=load i32,i32*%aW,align 4
%aY=call i8*@sml_alloc(i32 inreg 12)#0
%aZ=bitcast i8*%aY to i32*
%a0=getelementptr inbounds i8,i8*%aY,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 1342177288,i32*%a1,align 4
store i8*%aY,i8**%d,align 8
store i32%aU,i32*%aZ,align 4
%a2=getelementptr inbounds i8,i8*%aY,i64 4
%a3=bitcast i8*%a2 to i32*
store i32%aX,i32*%a3,align 4
%a4=getelementptr inbounds i8,i8*%aY,i64 8
%a5=bitcast i8*%a4 to i32*
store i32 0,i32*%a5,align 4
%a6=call i8*@sml_alloc(i32 inreg 28)#0
%a7=getelementptr inbounds i8,i8*%a6,i64 -4
%a8=bitcast i8*%a7 to i32*
store i32 1342177304,i32*%a8,align 4
%a9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ba=bitcast i8*%a6 to i8**
store i8*%a9,i8**%ba,align 8
%bb=getelementptr inbounds i8,i8*%a6,i64 8
%bc=bitcast i8*%bb to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10ListSorter4sortE_53 to void(...)*),void(...)**%bc,align 8
%bd=getelementptr inbounds i8,i8*%a6,i64 16
%be=bitcast i8*%bd to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10ListSorter4sortE_53 to void(...)*),void(...)**%be,align 8
%bf=getelementptr inbounds i8,i8*%a6,i64 24
%bg=bitcast i8*%bf to i32*
store i32 -2147483647,i32*%bg,align 4
%bh=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bi=call fastcc i8*%aO(i8*inreg%bh,i8*inreg%a6)
%bj=getelementptr inbounds i8,i8*%bi,i64 16
%bk=bitcast i8*%bj to i8*(i8*,i8*)**
%bl=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bk,align 8
%bm=bitcast i8*%bi to i8**
%bn=load i8*,i8**%bm,align 8
%bo=call fastcc i8*%bl(i8*inreg%bn,i8*inreg null)
%bp=getelementptr inbounds i8,i8*%bo,i64 16
%bq=bitcast i8*%bp to i8*(i8*,i8*)**
%br=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bq,align 8
%bs=bitcast i8*%bo to i8**
%bt=load i8*,i8**%bs,align 8
%bu=load i8*,i8**%c,align 8
%bv=tail call fastcc i8*%br(i8*inreg%bt,i8*inreg%bu)
ret i8*%bv
}
define internal fastcc i8*@_SMLLLN10ListSorter4sortE_55(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10ListSorter4sortE_54 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10ListSorter4sortE_54 to void(...)*),void(...)**%C,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10ListSorter4sortE_55 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10ListSorter4sortE_55 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLL9quickSort_58(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLLL9quickSort_40(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN10ListSorter4sortE_59(i8*inreg%a,i8*inreg%b,i8*inreg%c)#4 gc"smlsharp"{
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
