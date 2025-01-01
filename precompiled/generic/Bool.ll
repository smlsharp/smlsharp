@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i32)*@_SMLFN4Bool3notE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool3notE_80 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN4Bool10fromStringE_69 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool10fromStringE_82 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN4Bool10fromStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool10fromStringE_83 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"false\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"true\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN4Bool8toStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool8toStringE_84 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN4Bool4scanE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN4Bool4scanE_85 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN4Bool3notE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SMLZN4Bool8toStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SMLZN4Bool4scanE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SMLZN4Bool10fromStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SML_ftabdaa180c1799f3810_Bool=external global i8
@h=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@_SMLFN17SMLSharp__ScanChar10skipSpacesE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9StringCvt10scanStringE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main5c37eb24573fc5f9_StringCvt()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main4fb8d2c1f12728b2_SMLSharp_ScanChar()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load5c37eb24573fc5f9_StringCvt(i8*)local_unnamed_addr
declare void@_SML_load4fb8d2c1f12728b2_SMLSharp_ScanChar(i8*)local_unnamed_addr
define private void@_SML_tabbdaa180c1799f3810_Bool()#2{
unreachable
}
define void@_SML_loaddaa180c1799f3810_Bool(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@h,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@h,align 1
tail call void@_SML_load5c37eb24573fc5f9_StringCvt(i8*%a)#0
tail call void@_SML_load4fb8d2c1f12728b2_SMLSharp_ScanChar(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbdaa180c1799f3810_Bool,i8*@_SML_ftabdaa180c1799f3810_Bool,i8*null)#0
ret void
}
define void@_SML_maindaa180c1799f3810_Bool()local_unnamed_addr#1 gc"smlsharp"{
%a=load i8,i8*@h,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@h,align 1
tail call void@_SML_main5c37eb24573fc5f9_StringCvt()#1
tail call void@_SML_main4fb8d2c1f12728b2_SMLSharp_ScanChar()#1
br label%d
}
define fastcc i32@_SMLFN4Bool3notE(i32 inreg%a)#3 gc"smlsharp"{
%b=icmp eq i32%a,0
%c=zext i1%b to i32
ret i32%c
}
define internal fastcc i8*@_SMLLL5true1_64(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
l:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%j,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
%i=load i8*,i8**%c,align 8
br label%j
j:
%k=phi i8*[%i,%g],[%b,%l]
%m=phi i8*[%h,%g],[%a,%l]
%n=getelementptr inbounds i8,i8*%m,i64 12
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
%q=sub i32 0,%p
%r=and i32%p,%q
%s=add i32%p,3
%t=and i32%s,%q
%u=add i32%p,7
%v=add i32%u,%t
%w=and i32%v,-8
%x=lshr i32%t,3
%y=getelementptr inbounds i8,i8*%m,i64 8
%z=bitcast i8*%y to i32*
%A=load i32,i32*%z,align 4
%B=shl i32%A,%x
%C=or i32%w,4
%D=bitcast i8*%m to i8**
%E=load i8*,i8**%D,align 8
%F=getelementptr inbounds i8,i8*%E,i64 16
%G=bitcast i8*%F to i8*(i8*,i8*)**
%H=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%G,align 8
%I=bitcast i8*%E to i8**
%J=load i8*,i8**%I,align 8
store i8*null,i8**%c,align 8
%K=call fastcc i8*%H(i8*inreg%J,i8*inreg%k)
%L=icmp eq i8*%K,null
br i1%L,label%aG,label%M
M:
%N=bitcast i8*%K to i8**
%O=load i8*,i8**%N,align 8
store i8*%O,i8**%c,align 8
%P=load i8,i8*%O,align 1
switch i8%P,label%aG[
i8 82,label%al
i8 114,label%Q
]
Q:
%R=load i8*,i8**%d,align 8
%S=getelementptr inbounds i8,i8*%R,i64 8
%T=bitcast i8*%S to i32*
%U=load i32,i32*%T,align 4
%V=icmp eq i32%U,0
br i1%V,label%ab,label%W
W:
store i8*null,i8**%c,align 8
%X=sext i32%r to i64
%Y=getelementptr inbounds i8,i8*%O,i64%X
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
br label%cI
ab:
%ac=getelementptr inbounds i8,i8*%R,i64 12
%ad=bitcast i8*%ac to i32*
%ae=load i32,i32*%ad,align 4
%af=call i8*@sml_alloc(i32 inreg%ae)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32%ae,i32*%ah,align 4
%ai=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aj=sext i32%r to i64
%ak=getelementptr inbounds i8,i8*%ai,i64%aj
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%af,i8*%ak,i32%ae,i1 false)
br label%cI
al:
%am=load i8*,i8**%d,align 8
%an=getelementptr inbounds i8,i8*%am,i64 8
%ao=bitcast i8*%an to i32*
%ap=load i32,i32*%ao,align 4
%aq=icmp eq i32%ap,0
br i1%aq,label%aw,label%ar
ar:
store i8*null,i8**%c,align 8
%as=sext i32%r to i64
%at=getelementptr inbounds i8,i8*%O,i64%as
%au=bitcast i8*%at to i8**
%av=load i8*,i8**%au,align 8
br label%cI
aw:
%ax=getelementptr inbounds i8,i8*%am,i64 12
%ay=bitcast i8*%ax to i32*
%az=load i32,i32*%ay,align 4
%aA=call i8*@sml_alloc(i32 inreg%az)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32%az,i32*%aC,align 4
%aD=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aE=sext i32%r to i64
%aF=getelementptr inbounds i8,i8*%aD,i64%aE
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aA,i8*%aF,i32%az,i1 false)
br label%cI
aG:
ret i8*null
aH:
%aI=phi i8*[%c8,%c4],[%dd,%c9],[%dt,%dp],[%dy,%du]
%aJ=load i8**,i8***%cK,align 8
%aK=load i8*,i8**%aJ,align 8
%aL=getelementptr inbounds i8,i8*%aK,i64 16
%aM=bitcast i8*%aL to i8*(i8*,i8*)**
%aN=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aM,align 8
%aO=bitcast i8*%aK to i8**
%aP=load i8*,i8**%aO,align 8
%aQ=call fastcc i8*%aN(i8*inreg%aP,i8*inreg%aI)
%aR=icmp eq i8*%aQ,null
br i1%aR,label%aG,label%aS
aS:
%aT=bitcast i8*%aQ to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%c,align 8
%aV=load i8,i8*%aU,align 1
switch i8%aV,label%aG[
i8 69,label%bP
i8 101,label%aW
]
aW:
%aX=load i8*,i8**%d,align 8
%aY=getelementptr inbounds i8,i8*%aX,i64 8
%aZ=bitcast i8*%aY to i32*
%a0=load i32,i32*%aZ,align 4
%a1=icmp eq i32%a0,0
br i1%a1,label%a7,label%a2
a2:
store i8*null,i8**%c,align 8
%a3=sext i32%r to i64
%a4=getelementptr inbounds i8,i8*%aU,i64%a3
%a5=bitcast i8*%a4 to i8**
%a6=load i8*,i8**%a5,align 8
br label%bl
a7:
%a8=getelementptr inbounds i8,i8*%aX,i64 12
%a9=bitcast i8*%a8 to i32*
%ba=load i32,i32*%a9,align 4
%bb=call i8*@sml_alloc(i32 inreg%ba)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32%ba,i32*%bd,align 4
%be=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bf=sext i32%r to i64
%bg=getelementptr inbounds i8,i8*%be,i64%bf
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bb,i8*%bg,i32%ba,i1 false)
%bh=load i8*,i8**%d,align 8
%bi=getelementptr inbounds i8,i8*%bh,i64 8
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
br label%bl
bl:
%bm=phi i32[%bk,%a7],[%a0,%a2]
%bn=phi i8*[%bh,%a7],[%aX,%a2]
%bo=phi i8*[%bb,%a7],[%a6,%a2]
store i8*%bo,i8**%c,align 8
%bp=getelementptr inbounds i8,i8*%bn,i64 12
%bq=bitcast i8*%bp to i32*
%br=load i32,i32*%bq,align 4
store i8*null,i8**%d,align 8
%bs=call i8*@sml_alloc(i32 inreg%C)#0
%bt=or i32%w,1342177280
%bu=getelementptr inbounds i8,i8*%bs,i64 -4
%bv=bitcast i8*%bu to i32*
store i32%bt,i32*%bv,align 4
store i8*%bs,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%bs,i8 0,i32%C,i1 false)
%bw=bitcast i8*%bs to i32*
store i32 1,i32*%bw,align 4
%bx=icmp eq i32%bm,0
%by=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bz=sext i32%t to i64
%bA=getelementptr inbounds i8,i8*%bs,i64%bz
br i1%bx,label%bB,label%bC
bB:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bA,i8*%by,i32%br,i1 false)
br label%bE
bC:
%bD=bitcast i8*%bA to i8**
store i8*%by,i8**%bD,align 8
br label%bE
bE:
%bF=sext i32%w to i64
%bG=getelementptr inbounds i8,i8*%bs,i64%bF
%bH=bitcast i8*%bG to i32*
store i32%B,i32*%bH,align 4
%bI=call i8*@sml_alloc(i32 inreg 12)#0
%bJ=getelementptr inbounds i8,i8*%bI,i64 -4
%bK=bitcast i8*%bJ to i32*
store i32 1342177288,i32*%bK,align 4
%bL=load i8*,i8**%d,align 8
%bM=bitcast i8*%bI to i8**
store i8*%bL,i8**%bM,align 8
%bN=getelementptr inbounds i8,i8*%bI,i64 8
%bO=bitcast i8*%bN to i32*
store i32 1,i32*%bO,align 4
ret i8*%bI
bP:
%bQ=load i8*,i8**%d,align 8
%bR=getelementptr inbounds i8,i8*%bQ,i64 8
%bS=bitcast i8*%bR to i32*
%bT=load i32,i32*%bS,align 4
%bU=icmp eq i32%bT,0
br i1%bU,label%b0,label%bV
bV:
store i8*null,i8**%c,align 8
%bW=sext i32%r to i64
%bX=getelementptr inbounds i8,i8*%aU,i64%bW
%bY=bitcast i8*%bX to i8**
%bZ=load i8*,i8**%bY,align 8
br label%ce
b0:
%b1=getelementptr inbounds i8,i8*%bQ,i64 12
%b2=bitcast i8*%b1 to i32*
%b3=load i32,i32*%b2,align 4
%b4=call i8*@sml_alloc(i32 inreg%b3)#0
%b5=getelementptr inbounds i8,i8*%b4,i64 -4
%b6=bitcast i8*%b5 to i32*
store i32%b3,i32*%b6,align 4
%b7=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%b8=sext i32%r to i64
%b9=getelementptr inbounds i8,i8*%b7,i64%b8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%b4,i8*%b9,i32%b3,i1 false)
%ca=load i8*,i8**%d,align 8
%cb=getelementptr inbounds i8,i8*%ca,i64 8
%cc=bitcast i8*%cb to i32*
%cd=load i32,i32*%cc,align 4
br label%ce
ce:
%cf=phi i32[%cd,%b0],[%bT,%bV]
%cg=phi i8*[%ca,%b0],[%bQ,%bV]
%ch=phi i8*[%b4,%b0],[%bZ,%bV]
store i8*%ch,i8**%c,align 8
%ci=getelementptr inbounds i8,i8*%cg,i64 12
%cj=bitcast i8*%ci to i32*
%ck=load i32,i32*%cj,align 4
store i8*null,i8**%d,align 8
%cl=call i8*@sml_alloc(i32 inreg%C)#0
%cm=or i32%w,1342177280
%cn=getelementptr inbounds i8,i8*%cl,i64 -4
%co=bitcast i8*%cn to i32*
store i32%cm,i32*%co,align 4
store i8*%cl,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%cl,i8 0,i32%C,i1 false)
%cp=bitcast i8*%cl to i32*
store i32 1,i32*%cp,align 4
%cq=icmp eq i32%cf,0
%cr=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cs=sext i32%t to i64
%ct=getelementptr inbounds i8,i8*%cl,i64%cs
br i1%cq,label%cu,label%cv
cu:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ct,i8*%cr,i32%ck,i1 false)
br label%cx
cv:
%cw=bitcast i8*%ct to i8**
store i8*%cr,i8**%cw,align 8
br label%cx
cx:
%cy=sext i32%w to i64
%cz=getelementptr inbounds i8,i8*%cl,i64%cy
%cA=bitcast i8*%cz to i32*
store i32%B,i32*%cA,align 4
%cB=call i8*@sml_alloc(i32 inreg 12)#0
%cC=getelementptr inbounds i8,i8*%cB,i64 -4
%cD=bitcast i8*%cC to i32*
store i32 1342177288,i32*%cD,align 4
%cE=load i8*,i8**%d,align 8
%cF=bitcast i8*%cB to i8**
store i8*%cE,i8**%cF,align 8
%cG=getelementptr inbounds i8,i8*%cB,i64 8
%cH=bitcast i8*%cG to i32*
store i32 1,i32*%cH,align 4
ret i8*%cB
cI:
%cJ=phi i8*[%aa,%W],[%af,%ab],[%av,%ar],[%aA,%aw]
%cK=bitcast i8**%d to i8***
%cL=load i8**,i8***%cK,align 8
%cM=load i8*,i8**%cL,align 8
%cN=getelementptr inbounds i8,i8*%cM,i64 16
%cO=bitcast i8*%cN to i8*(i8*,i8*)**
%cP=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cO,align 8
%cQ=bitcast i8*%cM to i8**
%cR=load i8*,i8**%cQ,align 8
%cS=call fastcc i8*%cP(i8*inreg%cR,i8*inreg%cJ)
%cT=icmp eq i8*%cS,null
br i1%cT,label%aG,label%cU
cU:
%cV=bitcast i8*%cS to i8**
%cW=load i8*,i8**%cV,align 8
store i8*%cW,i8**%c,align 8
%cX=load i8,i8*%cW,align 1
switch i8%cX,label%aG[
i8 85,label%dj
i8 117,label%cY
]
cY:
%cZ=load i8*,i8**%d,align 8
%c0=getelementptr inbounds i8,i8*%cZ,i64 8
%c1=bitcast i8*%c0 to i32*
%c2=load i32,i32*%c1,align 4
%c3=icmp eq i32%c2,0
br i1%c3,label%c9,label%c4
c4:
store i8*null,i8**%c,align 8
%c5=sext i32%r to i64
%c6=getelementptr inbounds i8,i8*%cW,i64%c5
%c7=bitcast i8*%c6 to i8**
%c8=load i8*,i8**%c7,align 8
br label%aH
c9:
%da=getelementptr inbounds i8,i8*%cZ,i64 12
%db=bitcast i8*%da to i32*
%dc=load i32,i32*%db,align 4
%dd=call i8*@sml_alloc(i32 inreg%dc)#0
%de=getelementptr inbounds i8,i8*%dd,i64 -4
%df=bitcast i8*%de to i32*
store i32%dc,i32*%df,align 4
%dg=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dh=sext i32%r to i64
%di=getelementptr inbounds i8,i8*%dg,i64%dh
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%dd,i8*%di,i32%dc,i1 false)
br label%aH
dj:
%dk=load i8*,i8**%d,align 8
%dl=getelementptr inbounds i8,i8*%dk,i64 8
%dm=bitcast i8*%dl to i32*
%dn=load i32,i32*%dm,align 4
%do=icmp eq i32%dn,0
br i1%do,label%du,label%dp
dp:
store i8*null,i8**%c,align 8
%dq=sext i32%r to i64
%dr=getelementptr inbounds i8,i8*%cW,i64%dq
%ds=bitcast i8*%dr to i8**
%dt=load i8*,i8**%ds,align 8
br label%aH
du:
%dv=getelementptr inbounds i8,i8*%dk,i64 12
%dw=bitcast i8*%dv to i32*
%dx=load i32,i32*%dw,align 4
%dy=call i8*@sml_alloc(i32 inreg%dx)#0
%dz=getelementptr inbounds i8,i8*%dy,i64 -4
%dA=bitcast i8*%dz to i32*
store i32%dx,i32*%dA,align 4
%dB=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dC=sext i32%r to i64
%dD=getelementptr inbounds i8,i8*%dB,i64%dC
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%dy,i8*%dD,i32%dx,i1 false)
br label%aH
}
define internal fastcc i8*@_SMLLL6false1_65(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
l:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%j,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
%i=load i8*,i8**%c,align 8
br label%j
j:
%k=phi i8*[%i,%g],[%b,%l]
%m=phi i8*[%h,%g],[%a,%l]
%n=getelementptr inbounds i8,i8*%m,i64 12
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
%q=sub i32 0,%p
%r=and i32%p,%q
%s=add i32%p,3
%t=and i32%s,%q
%u=add i32%p,7
%v=add i32%u,%t
%w=and i32%v,-8
%x=lshr i32%t,3
%y=getelementptr inbounds i8,i8*%m,i64 8
%z=bitcast i8*%y to i32*
%A=load i32,i32*%z,align 4
%B=shl i32%A,%x
%C=or i32%w,4
%D=bitcast i8*%m to i8**
%E=load i8*,i8**%D,align 8
%F=getelementptr inbounds i8,i8*%E,i64 16
%G=bitcast i8*%F to i8*(i8*,i8*)**
%H=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%G,align 8
%I=bitcast i8*%E to i8**
%J=load i8*,i8**%I,align 8
store i8*null,i8**%c,align 8
%K=call fastcc i8*%H(i8*inreg%J,i8*inreg%k)
%L=icmp eq i8*%K,null
br i1%L,label%aG,label%M
M:
%N=bitcast i8*%K to i8**
%O=load i8*,i8**%N,align 8
store i8*%O,i8**%c,align 8
%P=load i8,i8*%O,align 1
switch i8%P,label%aG[
i8 65,label%al
i8 97,label%Q
]
Q:
%R=load i8*,i8**%d,align 8
%S=getelementptr inbounds i8,i8*%R,i64 8
%T=bitcast i8*%S to i32*
%U=load i32,i32*%T,align 4
%V=icmp eq i32%U,0
br i1%V,label%ab,label%W
W:
store i8*null,i8**%c,align 8
%X=sext i32%r to i64
%Y=getelementptr inbounds i8,i8*%O,i64%X
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
br label%dD
ab:
%ac=getelementptr inbounds i8,i8*%R,i64 12
%ad=bitcast i8*%ac to i32*
%ae=load i32,i32*%ad,align 4
%af=call i8*@sml_alloc(i32 inreg%ae)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32%ae,i32*%ah,align 4
%ai=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aj=sext i32%r to i64
%ak=getelementptr inbounds i8,i8*%ai,i64%aj
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%af,i8*%ak,i32%ae,i1 false)
br label%dD
al:
%am=load i8*,i8**%d,align 8
%an=getelementptr inbounds i8,i8*%am,i64 8
%ao=bitcast i8*%an to i32*
%ap=load i32,i32*%ao,align 4
%aq=icmp eq i32%ap,0
br i1%aq,label%aw,label%ar
ar:
store i8*null,i8**%c,align 8
%as=sext i32%r to i64
%at=getelementptr inbounds i8,i8*%O,i64%as
%au=bitcast i8*%at to i8**
%av=load i8*,i8**%au,align 8
br label%dD
aw:
%ax=getelementptr inbounds i8,i8*%am,i64 12
%ay=bitcast i8*%ax to i32*
%az=load i32,i32*%ay,align 4
%aA=call i8*@sml_alloc(i32 inreg%az)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32%az,i32*%aC,align 4
%aD=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aE=sext i32%r to i64
%aF=getelementptr inbounds i8,i8*%aD,i64%aE
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aA,i8*%aF,i32%az,i1 false)
br label%dD
aG:
ret i8*null
aH:
%aI=phi i8*[%c7,%c3],[%dc,%c8],[%ds,%do],[%dx,%dt]
%aJ=load i8**,i8***%dF,align 8
%aK=load i8*,i8**%aJ,align 8
%aL=getelementptr inbounds i8,i8*%aK,i64 16
%aM=bitcast i8*%aL to i8*(i8*,i8*)**
%aN=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aM,align 8
%aO=bitcast i8*%aK to i8**
%aP=load i8*,i8**%aO,align 8
%aQ=call fastcc i8*%aN(i8*inreg%aP,i8*inreg%aI)
%aR=icmp eq i8*%aQ,null
br i1%aR,label%aG,label%aS
aS:
%aT=bitcast i8*%aQ to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%c,align 8
%aV=load i8,i8*%aU,align 1
switch i8%aV,label%aG[
i8 69,label%bP
i8 101,label%aW
]
aW:
%aX=load i8*,i8**%d,align 8
%aY=getelementptr inbounds i8,i8*%aX,i64 8
%aZ=bitcast i8*%aY to i32*
%a0=load i32,i32*%aZ,align 4
%a1=icmp eq i32%a0,0
br i1%a1,label%a7,label%a2
a2:
store i8*null,i8**%c,align 8
%a3=sext i32%r to i64
%a4=getelementptr inbounds i8,i8*%aU,i64%a3
%a5=bitcast i8*%a4 to i8**
%a6=load i8*,i8**%a5,align 8
br label%bl
a7:
%a8=getelementptr inbounds i8,i8*%aX,i64 12
%a9=bitcast i8*%a8 to i32*
%ba=load i32,i32*%a9,align 4
%bb=call i8*@sml_alloc(i32 inreg%ba)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32%ba,i32*%bd,align 4
%be=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bf=sext i32%r to i64
%bg=getelementptr inbounds i8,i8*%be,i64%bf
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bb,i8*%bg,i32%ba,i1 false)
%bh=load i8*,i8**%d,align 8
%bi=getelementptr inbounds i8,i8*%bh,i64 8
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
br label%bl
bl:
%bm=phi i32[%bk,%a7],[%a0,%a2]
%bn=phi i8*[%bh,%a7],[%aX,%a2]
%bo=phi i8*[%bb,%a7],[%a6,%a2]
store i8*%bo,i8**%c,align 8
%bp=getelementptr inbounds i8,i8*%bn,i64 12
%bq=bitcast i8*%bp to i32*
%br=load i32,i32*%bq,align 4
store i8*null,i8**%d,align 8
%bs=call i8*@sml_alloc(i32 inreg%C)#0
%bt=or i32%w,1342177280
%bu=getelementptr inbounds i8,i8*%bs,i64 -4
%bv=bitcast i8*%bu to i32*
store i32%bt,i32*%bv,align 4
store i8*%bs,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%bs,i8 0,i32%C,i1 false)
%bw=bitcast i8*%bs to i32*
store i32 0,i32*%bw,align 4
%bx=icmp eq i32%bm,0
%by=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bz=sext i32%t to i64
%bA=getelementptr inbounds i8,i8*%bs,i64%bz
br i1%bx,label%bB,label%bC
bB:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bA,i8*%by,i32%br,i1 false)
br label%bE
bC:
%bD=bitcast i8*%bA to i8**
store i8*%by,i8**%bD,align 8
br label%bE
bE:
%bF=sext i32%w to i64
%bG=getelementptr inbounds i8,i8*%bs,i64%bF
%bH=bitcast i8*%bG to i32*
store i32%B,i32*%bH,align 4
%bI=call i8*@sml_alloc(i32 inreg 12)#0
%bJ=getelementptr inbounds i8,i8*%bI,i64 -4
%bK=bitcast i8*%bJ to i32*
store i32 1342177288,i32*%bK,align 4
%bL=load i8*,i8**%d,align 8
%bM=bitcast i8*%bI to i8**
store i8*%bL,i8**%bM,align 8
%bN=getelementptr inbounds i8,i8*%bI,i64 8
%bO=bitcast i8*%bN to i32*
store i32 1,i32*%bO,align 4
ret i8*%bI
bP:
%bQ=load i8*,i8**%d,align 8
%bR=getelementptr inbounds i8,i8*%bQ,i64 8
%bS=bitcast i8*%bR to i32*
%bT=load i32,i32*%bS,align 4
%bU=icmp eq i32%bT,0
br i1%bU,label%b0,label%bV
bV:
store i8*null,i8**%c,align 8
%bW=sext i32%r to i64
%bX=getelementptr inbounds i8,i8*%aU,i64%bW
%bY=bitcast i8*%bX to i8**
%bZ=load i8*,i8**%bY,align 8
br label%ce
b0:
%b1=getelementptr inbounds i8,i8*%bQ,i64 12
%b2=bitcast i8*%b1 to i32*
%b3=load i32,i32*%b2,align 4
%b4=call i8*@sml_alloc(i32 inreg%b3)#0
%b5=getelementptr inbounds i8,i8*%b4,i64 -4
%b6=bitcast i8*%b5 to i32*
store i32%b3,i32*%b6,align 4
%b7=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%b8=sext i32%r to i64
%b9=getelementptr inbounds i8,i8*%b7,i64%b8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%b4,i8*%b9,i32%b3,i1 false)
%ca=load i8*,i8**%d,align 8
%cb=getelementptr inbounds i8,i8*%ca,i64 8
%cc=bitcast i8*%cb to i32*
%cd=load i32,i32*%cc,align 4
br label%ce
ce:
%cf=phi i32[%cd,%b0],[%bT,%bV]
%cg=phi i8*[%ca,%b0],[%bQ,%bV]
%ch=phi i8*[%b4,%b0],[%bZ,%bV]
store i8*%ch,i8**%c,align 8
%ci=getelementptr inbounds i8,i8*%cg,i64 12
%cj=bitcast i8*%ci to i32*
%ck=load i32,i32*%cj,align 4
store i8*null,i8**%d,align 8
%cl=call i8*@sml_alloc(i32 inreg%C)#0
%cm=or i32%w,1342177280
%cn=getelementptr inbounds i8,i8*%cl,i64 -4
%co=bitcast i8*%cn to i32*
store i32%cm,i32*%co,align 4
store i8*%cl,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%cl,i8 0,i32%C,i1 false)
%cp=bitcast i8*%cl to i32*
store i32 0,i32*%cp,align 4
%cq=icmp eq i32%cf,0
%cr=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cs=sext i32%t to i64
%ct=getelementptr inbounds i8,i8*%cl,i64%cs
br i1%cq,label%cu,label%cv
cu:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ct,i8*%cr,i32%ck,i1 false)
br label%cx
cv:
%cw=bitcast i8*%ct to i8**
store i8*%cr,i8**%cw,align 8
br label%cx
cx:
%cy=sext i32%w to i64
%cz=getelementptr inbounds i8,i8*%cl,i64%cy
%cA=bitcast i8*%cz to i32*
store i32%B,i32*%cA,align 4
%cB=call i8*@sml_alloc(i32 inreg 12)#0
%cC=getelementptr inbounds i8,i8*%cB,i64 -4
%cD=bitcast i8*%cC to i32*
store i32 1342177288,i32*%cD,align 4
%cE=load i8*,i8**%d,align 8
%cF=bitcast i8*%cB to i8**
store i8*%cE,i8**%cF,align 8
%cG=getelementptr inbounds i8,i8*%cB,i64 8
%cH=bitcast i8*%cG to i32*
store i32 1,i32*%cH,align 4
ret i8*%cB
cI:
%cJ=phi i8*[%d3,%dZ],[%d8,%d4],[%eo,%ek],[%et,%ep]
%cK=load i8**,i8***%dF,align 8
%cL=load i8*,i8**%cK,align 8
%cM=getelementptr inbounds i8,i8*%cL,i64 16
%cN=bitcast i8*%cM to i8*(i8*,i8*)**
%cO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cN,align 8
%cP=bitcast i8*%cL to i8**
%cQ=load i8*,i8**%cP,align 8
%cR=call fastcc i8*%cO(i8*inreg%cQ,i8*inreg%cJ)
%cS=icmp eq i8*%cR,null
br i1%cS,label%aG,label%cT
cT:
%cU=bitcast i8*%cR to i8**
%cV=load i8*,i8**%cU,align 8
store i8*%cV,i8**%c,align 8
%cW=load i8,i8*%cV,align 1
switch i8%cW,label%aG[
i8 83,label%di
i8 115,label%cX
]
cX:
%cY=load i8*,i8**%d,align 8
%cZ=getelementptr inbounds i8,i8*%cY,i64 8
%c0=bitcast i8*%cZ to i32*
%c1=load i32,i32*%c0,align 4
%c2=icmp eq i32%c1,0
br i1%c2,label%c8,label%c3
c3:
store i8*null,i8**%c,align 8
%c4=sext i32%r to i64
%c5=getelementptr inbounds i8,i8*%cV,i64%c4
%c6=bitcast i8*%c5 to i8**
%c7=load i8*,i8**%c6,align 8
br label%aH
c8:
%c9=getelementptr inbounds i8,i8*%cY,i64 12
%da=bitcast i8*%c9 to i32*
%db=load i32,i32*%da,align 4
%dc=call i8*@sml_alloc(i32 inreg%db)#0
%dd=getelementptr inbounds i8,i8*%dc,i64 -4
%de=bitcast i8*%dd to i32*
store i32%db,i32*%de,align 4
%df=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dg=sext i32%r to i64
%dh=getelementptr inbounds i8,i8*%df,i64%dg
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%dc,i8*%dh,i32%db,i1 false)
br label%aH
di:
%dj=load i8*,i8**%d,align 8
%dk=getelementptr inbounds i8,i8*%dj,i64 8
%dl=bitcast i8*%dk to i32*
%dm=load i32,i32*%dl,align 4
%dn=icmp eq i32%dm,0
br i1%dn,label%dt,label%do
do:
store i8*null,i8**%c,align 8
%dp=sext i32%r to i64
%dq=getelementptr inbounds i8,i8*%cV,i64%dp
%dr=bitcast i8*%dq to i8**
%ds=load i8*,i8**%dr,align 8
br label%aH
dt:
%du=getelementptr inbounds i8,i8*%dj,i64 12
%dv=bitcast i8*%du to i32*
%dw=load i32,i32*%dv,align 4
%dx=call i8*@sml_alloc(i32 inreg%dw)#0
%dy=getelementptr inbounds i8,i8*%dx,i64 -4
%dz=bitcast i8*%dy to i32*
store i32%dw,i32*%dz,align 4
%dA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dB=sext i32%r to i64
%dC=getelementptr inbounds i8,i8*%dA,i64%dB
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%dx,i8*%dC,i32%dw,i1 false)
br label%aH
dD:
%dE=phi i8*[%aa,%W],[%af,%ab],[%av,%ar],[%aA,%aw]
%dF=bitcast i8**%d to i8***
%dG=load i8**,i8***%dF,align 8
%dH=load i8*,i8**%dG,align 8
%dI=getelementptr inbounds i8,i8*%dH,i64 16
%dJ=bitcast i8*%dI to i8*(i8*,i8*)**
%dK=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dJ,align 8
%dL=bitcast i8*%dH to i8**
%dM=load i8*,i8**%dL,align 8
%dN=call fastcc i8*%dK(i8*inreg%dM,i8*inreg%dE)
%dO=icmp eq i8*%dN,null
br i1%dO,label%aG,label%dP
dP:
%dQ=bitcast i8*%dN to i8**
%dR=load i8*,i8**%dQ,align 8
store i8*%dR,i8**%c,align 8
%dS=load i8,i8*%dR,align 1
switch i8%dS,label%aG[
i8 76,label%ee
i8 108,label%dT
]
dT:
%dU=load i8*,i8**%d,align 8
%dV=getelementptr inbounds i8,i8*%dU,i64 8
%dW=bitcast i8*%dV to i32*
%dX=load i32,i32*%dW,align 4
%dY=icmp eq i32%dX,0
br i1%dY,label%d4,label%dZ
dZ:
store i8*null,i8**%c,align 8
%d0=sext i32%r to i64
%d1=getelementptr inbounds i8,i8*%dR,i64%d0
%d2=bitcast i8*%d1 to i8**
%d3=load i8*,i8**%d2,align 8
br label%cI
d4:
%d5=getelementptr inbounds i8,i8*%dU,i64 12
%d6=bitcast i8*%d5 to i32*
%d7=load i32,i32*%d6,align 4
%d8=call i8*@sml_alloc(i32 inreg%d7)#0
%d9=getelementptr inbounds i8,i8*%d8,i64 -4
%ea=bitcast i8*%d9 to i32*
store i32%d7,i32*%ea,align 4
%eb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ec=sext i32%r to i64
%ed=getelementptr inbounds i8,i8*%eb,i64%ec
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%d8,i8*%ed,i32%d7,i1 false)
br label%cI
ee:
%ef=load i8*,i8**%d,align 8
%eg=getelementptr inbounds i8,i8*%ef,i64 8
%eh=bitcast i8*%eg to i32*
%ei=load i32,i32*%eh,align 4
%ej=icmp eq i32%ei,0
br i1%ej,label%ep,label%ek
ek:
store i8*null,i8**%c,align 8
%el=sext i32%r to i64
%em=getelementptr inbounds i8,i8*%dR,i64%el
%en=bitcast i8*%em to i8**
%eo=load i8*,i8**%en,align 8
br label%cI
ep:
%eq=getelementptr inbounds i8,i8*%ef,i64 12
%er=bitcast i8*%eq to i32*
%es=load i32,i32*%er,align 4
%et=call i8*@sml_alloc(i32 inreg%es)#0
%eu=getelementptr inbounds i8,i8*%et,i64 -4
%ev=bitcast i8*%eu to i32*
store i32%es,i32*%ev,align 4
%ew=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ex=sext i32%r to i64
%ey=getelementptr inbounds i8,i8*%ew,i64%ex
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%et,i8*%ey,i32%es,i1 false)
br label%cI
}
define internal fastcc i8*@_SMLLLN4Bool4scanE_66(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%o=getelementptr inbounds i8,i8*%m,i64 12
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=sub i32 0,%q
%s=and i32%q,%r
%t=bitcast i8*%m to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%e,align 8
%v=getelementptr inbounds i8,i8*%m,i64 8
%w=bitcast i8*%v to i32*
%x=load i32,i32*%w,align 4
%y=call i8*@sml_alloc(i32 inreg 20)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177296,i32*%A,align 4
store i8*%y,i8**%f,align 8
%B=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to i32*
store i32%x,i32*%E,align 4
%F=getelementptr inbounds i8,i8*%y,i64 12
%G=bitcast i8*%F to i32*
store i32%q,i32*%G,align 4
%H=getelementptr inbounds i8,i8*%y,i64 16
%I=bitcast i8*%H to i32*
store i32 1,i32*%I,align 4
%J=call i8*@sml_alloc(i32 inreg 28)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177304,i32*%L,align 4
%M=load i8*,i8**%f,align 8
%N=bitcast i8*%J to i8**
store i8*%M,i8**%N,align 8
%O=getelementptr inbounds i8,i8*%J,i64 8
%P=bitcast i8*%O to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5true1_64 to void(...)*),void(...)**%P,align 8
%Q=getelementptr inbounds i8,i8*%J,i64 16
%R=bitcast i8*%Q to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5true1_64 to void(...)*),void(...)**%R,align 8
%S=getelementptr inbounds i8,i8*%J,i64 24
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=bitcast i8**%d to i8***
%V=load i8**,i8***%U,align 8
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%e,align 8
%X=bitcast i8**%V to i8*
%Y=getelementptr inbounds i8*,i8**%V,i64 1
%Z=bitcast i8**%Y to i32*
%aa=load i32,i32*%Z,align 4
%ab=getelementptr inbounds i8,i8*%X,i64 12
%ac=bitcast i8*%ab to i32*
%ad=load i32,i32*%ac,align 4
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
store i8*%ae,i8**%g,align 8
%ah=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ai=bitcast i8*%ae to i8**
store i8*%ah,i8**%ai,align 8
%aj=getelementptr inbounds i8,i8*%ae,i64 8
%ak=bitcast i8*%aj to i32*
store i32%aa,i32*%ak,align 4
%al=getelementptr inbounds i8,i8*%ae,i64 12
%am=bitcast i8*%al to i32*
store i32%ad,i32*%am,align 4
%an=getelementptr inbounds i8,i8*%ae,i64 16
%ao=bitcast i8*%an to i32*
store i32 1,i32*%ao,align 4
%ap=call i8*@sml_alloc(i32 inreg 28)#0
%aq=getelementptr inbounds i8,i8*%ap,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 1342177304,i32*%ar,align 4
%as=load i8*,i8**%g,align 8
%at=bitcast i8*%ap to i8**
store i8*%as,i8**%at,align 8
%au=getelementptr inbounds i8,i8*%ap,i64 8
%av=bitcast i8*%au to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL6false1_65 to void(...)*),void(...)**%av,align 8
%aw=getelementptr inbounds i8,i8*%ap,i64 16
%ax=bitcast i8*%aw to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL6false1_65 to void(...)*),void(...)**%ax,align 8
%ay=getelementptr inbounds i8,i8*%ap,i64 24
%az=bitcast i8*%ay to i32*
store i32 1,i32*%az,align 4
%aA=load i8**,i8***%U,align 8
%aB=load i8*,i8**%aA,align 8
%aC=getelementptr inbounds i8,i8*%aB,i64 16
%aD=bitcast i8*%aC to i8*(i8*,i8*)**
%aE=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aD,align 8
%aF=bitcast i8*%aB to i8**
%aG=load i8*,i8**%aF,align 8
store i8*%aG,i8**%e,align 8
%aH=bitcast i8**%aA to i8*
%aI=getelementptr inbounds i8*,i8**%aA,i64 1
%aJ=bitcast i8**%aI to i32*
%aK=load i32,i32*%aJ,align 4
%aL=getelementptr inbounds i8,i8*%aH,i64 12
%aM=bitcast i8*%aL to i32*
%aN=load i32,i32*%aM,align 4
%aO=call fastcc i8*@_SMLFN17SMLSharp__ScanChar10skipSpacesE(i32 inreg%aK,i32 inreg%aN)
%aP=getelementptr inbounds i8,i8*%aO,i64 16
%aQ=bitcast i8*%aP to i8*(i8*,i8*)**
%aR=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aQ,align 8
%aS=bitcast i8*%aO to i8**
%aT=load i8*,i8**%aS,align 8
%aU=load i8**,i8***%U,align 8
%aV=load i8*,i8**%aU,align 8
%aW=call fastcc i8*%aR(i8*inreg%aT,i8*inreg%aV)
%aX=getelementptr inbounds i8,i8*%aW,i64 16
%aY=bitcast i8*%aX to i8*(i8*,i8*)**
%aZ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aY,align 8
%a0=bitcast i8*%aW to i8**
%a1=load i8*,i8**%a0,align 8
%a2=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a3=call fastcc i8*%aZ(i8*inreg%a1,i8*inreg%a2)
%a4=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%a5=call fastcc i8*%aE(i8*inreg%a4,i8*inreg%a3)
%a6=icmp eq i8*%a5,null
br i1%a6,label%cN,label%a7
a7:
%a8=bitcast i8*%a5 to i8**
%a9=load i8*,i8**%a8,align 8
store i8*%a9,i8**%c,align 8
%ba=load i8,i8*%a9,align 1
switch i8%ba,label%cN[
i8 70,label%co
i8 84,label%bZ
i8 102,label%bA
i8 116,label%bb
]
bb:
store i8*null,i8**%g,align 8
%bc=load i8*,i8**%d,align 8
%bd=getelementptr inbounds i8,i8*%bc,i64 8
%be=bitcast i8*%bd to i32*
%bf=load i32,i32*%be,align 4
%bg=icmp eq i32%bf,0
br i1%bg,label%bm,label%bh
bh:
%bi=sext i32%s to i64
%bj=getelementptr inbounds i8,i8*%a9,i64%bi
%bk=bitcast i8*%bj to i8**
%bl=load i8*,i8**%bk,align 8
br label%bw
bm:
store i8*null,i8**%d,align 8
%bn=getelementptr inbounds i8,i8*%bc,i64 12
%bo=bitcast i8*%bn to i32*
%bp=load i32,i32*%bo,align 4
%bq=call i8*@sml_alloc(i32 inreg%bp)#0
%br=getelementptr inbounds i8,i8*%bq,i64 -4
%bs=bitcast i8*%br to i32*
store i32%bp,i32*%bs,align 4
%bt=load i8*,i8**%c,align 8
%bu=sext i32%s to i64
%bv=getelementptr inbounds i8,i8*%bt,i64%bu
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bq,i8*%bv,i32%bp,i1 false)
br label%bw
bw:
%bx=phi i8*[%bl,%bh],[%bq,%bm]
%by=load i8*,i8**%f,align 8
%bz=tail call fastcc i8*@_SMLLL5true1_64(i8*inreg%by,i8*inreg%bx)
ret i8*%bz
bA:
store i8*null,i8**%f,align 8
%bB=load i8*,i8**%d,align 8
%bC=getelementptr inbounds i8,i8*%bB,i64 8
%bD=bitcast i8*%bC to i32*
%bE=load i32,i32*%bD,align 4
%bF=icmp eq i32%bE,0
br i1%bF,label%bL,label%bG
bG:
%bH=sext i32%s to i64
%bI=getelementptr inbounds i8,i8*%a9,i64%bH
%bJ=bitcast i8*%bI to i8**
%bK=load i8*,i8**%bJ,align 8
br label%bV
bL:
store i8*null,i8**%d,align 8
%bM=getelementptr inbounds i8,i8*%bB,i64 12
%bN=bitcast i8*%bM to i32*
%bO=load i32,i32*%bN,align 4
%bP=call i8*@sml_alloc(i32 inreg%bO)#0
%bQ=getelementptr inbounds i8,i8*%bP,i64 -4
%bR=bitcast i8*%bQ to i32*
store i32%bO,i32*%bR,align 4
%bS=load i8*,i8**%c,align 8
%bT=sext i32%s to i64
%bU=getelementptr inbounds i8,i8*%bS,i64%bT
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bP,i8*%bU,i32%bO,i1 false)
br label%bV
bV:
%bW=phi i8*[%bK,%bG],[%bP,%bL]
%bX=load i8*,i8**%g,align 8
%bY=tail call fastcc i8*@_SMLLL6false1_65(i8*inreg%bX,i8*inreg%bW)
ret i8*%bY
bZ:
store i8*null,i8**%g,align 8
%b0=load i8*,i8**%d,align 8
%b1=getelementptr inbounds i8,i8*%b0,i64 8
%b2=bitcast i8*%b1 to i32*
%b3=load i32,i32*%b2,align 4
%b4=icmp eq i32%b3,0
br i1%b4,label%ca,label%b5
b5:
%b6=sext i32%s to i64
%b7=getelementptr inbounds i8,i8*%a9,i64%b6
%b8=bitcast i8*%b7 to i8**
%b9=load i8*,i8**%b8,align 8
br label%ck
ca:
store i8*null,i8**%d,align 8
%cb=getelementptr inbounds i8,i8*%b0,i64 12
%cc=bitcast i8*%cb to i32*
%cd=load i32,i32*%cc,align 4
%ce=call i8*@sml_alloc(i32 inreg%cd)#0
%cf=getelementptr inbounds i8,i8*%ce,i64 -4
%cg=bitcast i8*%cf to i32*
store i32%cd,i32*%cg,align 4
%ch=load i8*,i8**%c,align 8
%ci=sext i32%s to i64
%cj=getelementptr inbounds i8,i8*%ch,i64%ci
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ce,i8*%cj,i32%cd,i1 false)
br label%ck
ck:
%cl=phi i8*[%b9,%b5],[%ce,%ca]
%cm=load i8*,i8**%f,align 8
%cn=tail call fastcc i8*@_SMLLL5true1_64(i8*inreg%cm,i8*inreg%cl)
ret i8*%cn
co:
store i8*null,i8**%f,align 8
%cp=load i8*,i8**%d,align 8
%cq=getelementptr inbounds i8,i8*%cp,i64 8
%cr=bitcast i8*%cq to i32*
%cs=load i32,i32*%cr,align 4
%ct=icmp eq i32%cs,0
br i1%ct,label%cz,label%cu
cu:
%cv=sext i32%s to i64
%cw=getelementptr inbounds i8,i8*%a9,i64%cv
%cx=bitcast i8*%cw to i8**
%cy=load i8*,i8**%cx,align 8
br label%cJ
cz:
store i8*null,i8**%d,align 8
%cA=getelementptr inbounds i8,i8*%cp,i64 12
%cB=bitcast i8*%cA to i32*
%cC=load i32,i32*%cB,align 4
%cD=call i8*@sml_alloc(i32 inreg%cC)#0
%cE=getelementptr inbounds i8,i8*%cD,i64 -4
%cF=bitcast i8*%cE to i32*
store i32%cC,i32*%cF,align 4
%cG=load i8*,i8**%c,align 8
%cH=sext i32%s to i64
%cI=getelementptr inbounds i8,i8*%cG,i64%cH
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cD,i8*%cI,i32%cC,i1 false)
br label%cJ
cJ:
%cK=phi i8*[%cy,%cu],[%cD,%cz]
%cL=load i8*,i8**%g,align 8
%cM=tail call fastcc i8*@_SMLLL6false1_65(i8*inreg%cL,i8*inreg%cK)
ret i8*%cM
cN:
ret i8*null
}
define internal fastcc i8*@_SMLLLN4Bool4scanE_67(i32 inreg%a,i32 inreg%b,i8*inreg%c)unnamed_addr#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%c,i8**%d,align 8
%f=call i8*@sml_alloc(i32 inreg 20)#0
%g=getelementptr inbounds i8,i8*%f,i64 -4
%h=bitcast i8*%g to i32*
store i32 1342177296,i32*%h,align 4
store i8*%f,i8**%e,align 8
%i=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%j=bitcast i8*%f to i8**
store i8*%i,i8**%j,align 8
%k=getelementptr inbounds i8,i8*%f,i64 8
%l=bitcast i8*%k to i32*
store i32%a,i32*%l,align 4
%m=getelementptr inbounds i8,i8*%f,i64 12
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%f,i64 16
%p=bitcast i8*%o to i32*
store i32 1,i32*%p,align 4
%q=call i8*@sml_alloc(i32 inreg 28)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177304,i32*%s,align 4
%t=load i8*,i8**%e,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool4scanE_66 to void(...)*),void(...)**%w,align 8
%x=getelementptr inbounds i8,i8*%q,i64 16
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool4scanE_66 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%q,i64 24
%A=bitcast i8*%z to i32*
store i32 1,i32*%A,align 4
ret i8*%q
}
define internal fastcc i8*@_SMLLLN4Bool10fromStringE_69(i8*inreg%a)#1 gc"smlsharp"{
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
%j=tail call fastcc i8*@_SMLLLN4Bool4scanE_67(i32 inreg 0,i32 inreg 4,i8*inreg%h)
ret i8*%j
}
define fastcc i8*@_SMLFN4Bool10fromStringE(i8*inreg%a)#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call fastcc i8*@_SMLFN9StringCvt10scanStringE(i32 inreg 0,i32 inreg 4)
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
%m=call fastcc i8*%j(i8*inreg%l,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*))
%n=getelementptr inbounds i8,i8*%m,i64 16
%o=bitcast i8*%n to i8*(i8*,i8*)**
%p=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%o,align 8
%q=bitcast i8*%m to i8**
%r=load i8*,i8**%q,align 8
%s=load i8*,i8**%b,align 8
%t=tail call fastcc i8*%p(i8*inreg%r,i8*inreg%s)
ret i8*%t
}
define fastcc i8*@_SMLFN4Bool8toStringE(i32 inreg%a)#3 gc"smlsharp"{
%b=icmp eq i32%a,0
%c=select i1%b,i8*getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@d,i64 0,i32 2,i64 0),i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@e,i64 0,i32 2,i64 0)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Bool4scanE_77(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
l:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%j,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
%i=load i8*,i8**%c,align 8
br label%j
j:
%k=phi i8*[%i,%g],[%a,%l]
%m=phi i8*[%h,%g],[%b,%l]
%n=bitcast i8*%k to i32*
%o=load i32,i32*%n,align 4
%p=getelementptr inbounds i8,i8*%k,i64 4
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=tail call fastcc i8*@_SMLLLN4Bool4scanE_67(i32 inreg%o,i32 inreg%r,i8*inreg%m)
ret i8*%s
}
define fastcc i8*@_SMLFN4Bool4scanE(i32 inreg%a,i32 inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool4scanE_77 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Bool4scanE_77 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLLN4Bool3notE_80(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=icmp eq i32%d,0
%f=zext i1%e to i32
%g=tail call i8*@sml_alloc(i32 inreg 4)#0
%h=bitcast i8*%g to i32*
%i=getelementptr inbounds i8,i8*%g,i64 -4
%j=bitcast i8*%i to i32*
store i32 4,i32*%j,align 4
store i32%f,i32*%h,align 4
ret i8*%g
}
define internal fastcc i8*@_SMLLLN4Bool10fromStringE_82(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLLN4Bool10fromStringE_69(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Bool10fromStringE_83(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN4Bool10fromStringE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Bool8toStringE_84(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=icmp eq i32%d,0
%f=select i1%e,i8*getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@d,i64 0,i32 2,i64 0),i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@e,i64 0,i32 2,i64 0)
ret i8*%f
}
define internal fastcc i8*@_SMLLLN4Bool4scanE_85(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN4Bool4scanE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
