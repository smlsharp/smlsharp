@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i32)*@_SMLFN4Bool3notE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool3notE_81 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN4Bool3notE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@b=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"false\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"true\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN4Bool8toStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool8toStringE_82 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN4Bool8toStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN4Bool4scanE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN4Bool4scanE_83 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN4Bool4scanE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN4Bool10fromStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool10fromStringE_84 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN4Bool10fromStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SML_ftabdaa180c1799f3810_Bool=external global i8
@g=private unnamed_addr global i8 0
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
%b=load i8,i8*@g,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@g,align 1
tail call void@_SML_load5c37eb24573fc5f9_StringCvt(i8*%a)#0
tail call void@_SML_load4fb8d2c1f12728b2_SMLSharp_ScanChar(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbdaa180c1799f3810_Bool,i8*@_SML_ftabdaa180c1799f3810_Bool,i8*null)#0
ret void
}
define void@_SML_maindaa180c1799f3810_Bool()local_unnamed_addr#1 gc"smlsharp"{
%a=load i8,i8*@g,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@g,align 1
tail call void@_SML_main5c37eb24573fc5f9_StringCvt()#1
tail call void@_SML_main4fb8d2c1f12728b2_SMLSharp_ScanChar()#1
br label%d
}
define internal fastcc i8*@_SMLL5true3_58(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%L,label%bM,label%M
M:
%N=bitcast i8*%K to i8**
%O=load i8*,i8**%N,align 8
store i8*%O,i8**%c,align 8
%P=load i8,i8*%O,align 1
switch i8%P,label%bM[
i8 69,label%aT
i8 101,label%Q
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
br label%ap
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
%al=load i8*,i8**%d,align 8
%am=getelementptr inbounds i8,i8*%al,i64 8
%an=bitcast i8*%am to i32*
%ao=load i32,i32*%an,align 4
br label%ap
ap:
%aq=phi i32[%ao,%ab],[%U,%W]
%ar=phi i8*[%al,%ab],[%R,%W]
%as=phi i8*[%af,%ab],[%aa,%W]
store i8*%as,i8**%c,align 8
%at=getelementptr inbounds i8,i8*%ar,i64 12
%au=bitcast i8*%at to i32*
%av=load i32,i32*%au,align 4
store i8*null,i8**%d,align 8
%aw=call i8*@sml_alloc(i32 inreg%C)#0
%ax=or i32%w,1342177280
%ay=getelementptr inbounds i8,i8*%aw,i64 -4
%az=bitcast i8*%ay to i32*
store i32%ax,i32*%az,align 4
store i8*%aw,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%aw,i8 0,i32%C,i1 false)
%aA=bitcast i8*%aw to i32*
store i32 1,i32*%aA,align 4
%aB=icmp eq i32%aq,0
%aC=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aD=sext i32%t to i64
%aE=getelementptr inbounds i8,i8*%aw,i64%aD
br i1%aB,label%aH,label%aF
aF:
%aG=bitcast i8*%aE to i8**
store i8*%aC,i8**%aG,align 8
br label%aI
aH:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aE,i8*%aC,i32%av,i1 false)
br label%aI
aI:
%aJ=sext i32%w to i64
%aK=getelementptr inbounds i8,i8*%aw,i64%aJ
%aL=bitcast i8*%aK to i32*
store i32%B,i32*%aL,align 4
%aM=call i8*@sml_alloc(i32 inreg 12)#0
%aN=getelementptr inbounds i8,i8*%aM,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 1342177288,i32*%aO,align 4
%aP=load i8*,i8**%d,align 8
%aQ=bitcast i8*%aM to i8**
store i8*%aP,i8**%aQ,align 8
%aR=getelementptr inbounds i8,i8*%aM,i64 8
%aS=bitcast i8*%aR to i32*
store i32 1,i32*%aS,align 4
ret i8*%aM
aT:
%aU=load i8*,i8**%d,align 8
%aV=getelementptr inbounds i8,i8*%aU,i64 8
%aW=bitcast i8*%aV to i32*
%aX=load i32,i32*%aW,align 4
%aY=icmp eq i32%aX,0
br i1%aY,label%a4,label%aZ
aZ:
store i8*null,i8**%c,align 8
%a0=sext i32%r to i64
%a1=getelementptr inbounds i8,i8*%O,i64%a0
%a2=bitcast i8*%a1 to i8**
%a3=load i8*,i8**%a2,align 8
br label%bi
a4:
%a5=getelementptr inbounds i8,i8*%aU,i64 12
%a6=bitcast i8*%a5 to i32*
%a7=load i32,i32*%a6,align 4
%a8=call i8*@sml_alloc(i32 inreg%a7)#0
%a9=getelementptr inbounds i8,i8*%a8,i64 -4
%ba=bitcast i8*%a9 to i32*
store i32%a7,i32*%ba,align 4
%bb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bc=sext i32%r to i64
%bd=getelementptr inbounds i8,i8*%bb,i64%bc
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%a8,i8*%bd,i32%a7,i1 false)
%be=load i8*,i8**%d,align 8
%bf=getelementptr inbounds i8,i8*%be,i64 8
%bg=bitcast i8*%bf to i32*
%bh=load i32,i32*%bg,align 4
br label%bi
bi:
%bj=phi i32[%bh,%a4],[%aX,%aZ]
%bk=phi i8*[%be,%a4],[%aU,%aZ]
%bl=phi i8*[%a8,%a4],[%a3,%aZ]
store i8*%bl,i8**%c,align 8
%bm=getelementptr inbounds i8,i8*%bk,i64 12
%bn=bitcast i8*%bm to i32*
%bo=load i32,i32*%bn,align 4
store i8*null,i8**%d,align 8
%bp=call i8*@sml_alloc(i32 inreg%C)#0
%bq=or i32%w,1342177280
%br=getelementptr inbounds i8,i8*%bp,i64 -4
%bs=bitcast i8*%br to i32*
store i32%bq,i32*%bs,align 4
store i8*%bp,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%bp,i8 0,i32%C,i1 false)
%bt=bitcast i8*%bp to i32*
store i32 1,i32*%bt,align 4
%bu=icmp eq i32%bj,0
%bv=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bw=sext i32%t to i64
%bx=getelementptr inbounds i8,i8*%bp,i64%bw
br i1%bu,label%bA,label%by
by:
%bz=bitcast i8*%bx to i8**
store i8*%bv,i8**%bz,align 8
br label%bB
bA:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bx,i8*%bv,i32%bo,i1 false)
br label%bB
bB:
%bC=sext i32%w to i64
%bD=getelementptr inbounds i8,i8*%bp,i64%bC
%bE=bitcast i8*%bD to i32*
store i32%B,i32*%bE,align 4
%bF=call i8*@sml_alloc(i32 inreg 12)#0
%bG=getelementptr inbounds i8,i8*%bF,i64 -4
%bH=bitcast i8*%bG to i32*
store i32 1342177288,i32*%bH,align 4
%bI=load i8*,i8**%d,align 8
%bJ=bitcast i8*%bF to i8**
store i8*%bI,i8**%bJ,align 8
%bK=getelementptr inbounds i8,i8*%bF,i64 8
%bL=bitcast i8*%bK to i32*
store i32 1,i32*%bL,align 4
ret i8*%bF
bM:
ret i8*null
}
define internal fastcc i8*@_SMLL5true2_59(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
m:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%k,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%d,align 8
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%h],[%b,%m]
%n=phi i8*[%i,%h],[%a,%m]
%o=getelementptr inbounds i8,i8*%n,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=sub i32 0,%q
%s=and i32%q,%r
%t=bitcast i8*%n to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg%l)
%B=icmp eq i8*%A,null
br i1%B,label%aM,label%C
C:
%D=bitcast i8*%A to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%c,align 8
%F=load i8,i8*%E,align 1
switch i8%F,label%aM[
i8 85,label%aj
i8 117,label%G
]
G:
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%e,align 8
%L=getelementptr inbounds i8,i8*%H,i64 16
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
%O=icmp eq i32%N,0
br i1%O,label%U,label%P
P:
%Q=sext i32%s to i64
%R=getelementptr inbounds i8,i8*%E,i64%Q
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
br label%af
U:
store i8*null,i8**%d,align 8
%V=getelementptr inbounds i8,i8*%H,i64 20
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=call i8*@sml_alloc(i32 inreg%X)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32%X,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=sext i32%s to i64
%ad=getelementptr inbounds i8,i8*%ab,i64%ac
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Y,i8*%ad,i32%X,i1 false)
%ae=load i8*,i8**%e,align 8
br label%af
af:
%ag=phi i8*[%K,%P],[%ae,%U]
%ah=phi i8*[%T,%P],[%Y,%U]
%ai=tail call fastcc i8*@_SMLL5true3_58(i8*inreg%ag,i8*inreg%ah)
ret i8*%ai
aj:
%ak=load i8*,i8**%d,align 8
%al=getelementptr inbounds i8,i8*%ak,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=getelementptr inbounds i8,i8*%ak,i64 16
%ap=bitcast i8*%ao to i32*
%aq=load i32,i32*%ap,align 4
%ar=icmp eq i32%aq,0
br i1%ar,label%ax,label%as
as:
%at=sext i32%s to i64
%au=getelementptr inbounds i8,i8*%E,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%aI
ax:
store i8*null,i8**%d,align 8
%ay=getelementptr inbounds i8,i8*%ak,i64 20
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
%aB=call i8*@sml_alloc(i32 inreg%aA)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32%aA,i32*%aD,align 4
%aE=load i8*,i8**%c,align 8
%aF=sext i32%s to i64
%aG=getelementptr inbounds i8,i8*%aE,i64%aF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aB,i8*%aG,i32%aA,i1 false)
%aH=load i8*,i8**%e,align 8
br label%aI
aI:
%aJ=phi i8*[%an,%as],[%aH,%ax]
%aK=phi i8*[%aw,%as],[%aB,%ax]
%aL=tail call fastcc i8*@_SMLL5true3_58(i8*inreg%aJ,i8*inreg%aK)
ret i8*%aL
aM:
ret i8*null
}
define internal fastcc i8*@_SMLL5true1_60(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
m:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%k,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%d,align 8
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%h],[%b,%m]
%n=phi i8*[%i,%h],[%a,%m]
%o=getelementptr inbounds i8,i8*%n,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=sub i32 0,%q
%s=and i32%q,%r
%t=bitcast i8*%n to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg%l)
%B=icmp eq i8*%A,null
br i1%B,label%aM,label%C
C:
%D=bitcast i8*%A to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%c,align 8
%F=load i8,i8*%E,align 1
switch i8%F,label%aM[
i8 82,label%aj
i8 114,label%G
]
G:
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%e,align 8
%L=getelementptr inbounds i8,i8*%H,i64 16
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
%O=icmp eq i32%N,0
br i1%O,label%U,label%P
P:
%Q=sext i32%s to i64
%R=getelementptr inbounds i8,i8*%E,i64%Q
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
br label%af
U:
store i8*null,i8**%d,align 8
%V=getelementptr inbounds i8,i8*%H,i64 20
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=call i8*@sml_alloc(i32 inreg%X)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32%X,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=sext i32%s to i64
%ad=getelementptr inbounds i8,i8*%ab,i64%ac
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Y,i8*%ad,i32%X,i1 false)
%ae=load i8*,i8**%e,align 8
br label%af
af:
%ag=phi i8*[%K,%P],[%ae,%U]
%ah=phi i8*[%T,%P],[%Y,%U]
%ai=tail call fastcc i8*@_SMLL5true2_59(i8*inreg%ag,i8*inreg%ah)
ret i8*%ai
aj:
%ak=load i8*,i8**%d,align 8
%al=getelementptr inbounds i8,i8*%ak,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=getelementptr inbounds i8,i8*%ak,i64 16
%ap=bitcast i8*%ao to i32*
%aq=load i32,i32*%ap,align 4
%ar=icmp eq i32%aq,0
br i1%ar,label%ax,label%as
as:
%at=sext i32%s to i64
%au=getelementptr inbounds i8,i8*%E,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%aI
ax:
store i8*null,i8**%d,align 8
%ay=getelementptr inbounds i8,i8*%ak,i64 20
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
%aB=call i8*@sml_alloc(i32 inreg%aA)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32%aA,i32*%aD,align 4
%aE=load i8*,i8**%c,align 8
%aF=sext i32%s to i64
%aG=getelementptr inbounds i8,i8*%aE,i64%aF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aB,i8*%aG,i32%aA,i1 false)
%aH=load i8*,i8**%e,align 8
br label%aI
aI:
%aJ=phi i8*[%an,%as],[%aH,%ax]
%aK=phi i8*[%aw,%as],[%aB,%ax]
%aL=tail call fastcc i8*@_SMLL5true2_59(i8*inreg%aJ,i8*inreg%aK)
ret i8*%aL
aM:
ret i8*null
}
define internal fastcc i8*@_SMLL6false4_61(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%L,label%bM,label%M
M:
%N=bitcast i8*%K to i8**
%O=load i8*,i8**%N,align 8
store i8*%O,i8**%c,align 8
%P=load i8,i8*%O,align 1
switch i8%P,label%bM[
i8 69,label%aT
i8 101,label%Q
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
br label%ap
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
%al=load i8*,i8**%d,align 8
%am=getelementptr inbounds i8,i8*%al,i64 8
%an=bitcast i8*%am to i32*
%ao=load i32,i32*%an,align 4
br label%ap
ap:
%aq=phi i32[%ao,%ab],[%U,%W]
%ar=phi i8*[%al,%ab],[%R,%W]
%as=phi i8*[%af,%ab],[%aa,%W]
store i8*%as,i8**%c,align 8
%at=getelementptr inbounds i8,i8*%ar,i64 12
%au=bitcast i8*%at to i32*
%av=load i32,i32*%au,align 4
store i8*null,i8**%d,align 8
%aw=call i8*@sml_alloc(i32 inreg%C)#0
%ax=or i32%w,1342177280
%ay=getelementptr inbounds i8,i8*%aw,i64 -4
%az=bitcast i8*%ay to i32*
store i32%ax,i32*%az,align 4
store i8*%aw,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%aw,i8 0,i32%C,i1 false)
%aA=bitcast i8*%aw to i32*
store i32 0,i32*%aA,align 4
%aB=icmp eq i32%aq,0
%aC=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aD=sext i32%t to i64
%aE=getelementptr inbounds i8,i8*%aw,i64%aD
br i1%aB,label%aH,label%aF
aF:
%aG=bitcast i8*%aE to i8**
store i8*%aC,i8**%aG,align 8
br label%aI
aH:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aE,i8*%aC,i32%av,i1 false)
br label%aI
aI:
%aJ=sext i32%w to i64
%aK=getelementptr inbounds i8,i8*%aw,i64%aJ
%aL=bitcast i8*%aK to i32*
store i32%B,i32*%aL,align 4
%aM=call i8*@sml_alloc(i32 inreg 12)#0
%aN=getelementptr inbounds i8,i8*%aM,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 1342177288,i32*%aO,align 4
%aP=load i8*,i8**%d,align 8
%aQ=bitcast i8*%aM to i8**
store i8*%aP,i8**%aQ,align 8
%aR=getelementptr inbounds i8,i8*%aM,i64 8
%aS=bitcast i8*%aR to i32*
store i32 1,i32*%aS,align 4
ret i8*%aM
aT:
%aU=load i8*,i8**%d,align 8
%aV=getelementptr inbounds i8,i8*%aU,i64 8
%aW=bitcast i8*%aV to i32*
%aX=load i32,i32*%aW,align 4
%aY=icmp eq i32%aX,0
br i1%aY,label%a4,label%aZ
aZ:
store i8*null,i8**%c,align 8
%a0=sext i32%r to i64
%a1=getelementptr inbounds i8,i8*%O,i64%a0
%a2=bitcast i8*%a1 to i8**
%a3=load i8*,i8**%a2,align 8
br label%bi
a4:
%a5=getelementptr inbounds i8,i8*%aU,i64 12
%a6=bitcast i8*%a5 to i32*
%a7=load i32,i32*%a6,align 4
%a8=call i8*@sml_alloc(i32 inreg%a7)#0
%a9=getelementptr inbounds i8,i8*%a8,i64 -4
%ba=bitcast i8*%a9 to i32*
store i32%a7,i32*%ba,align 4
%bb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bc=sext i32%r to i64
%bd=getelementptr inbounds i8,i8*%bb,i64%bc
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%a8,i8*%bd,i32%a7,i1 false)
%be=load i8*,i8**%d,align 8
%bf=getelementptr inbounds i8,i8*%be,i64 8
%bg=bitcast i8*%bf to i32*
%bh=load i32,i32*%bg,align 4
br label%bi
bi:
%bj=phi i32[%bh,%a4],[%aX,%aZ]
%bk=phi i8*[%be,%a4],[%aU,%aZ]
%bl=phi i8*[%a8,%a4],[%a3,%aZ]
store i8*%bl,i8**%c,align 8
%bm=getelementptr inbounds i8,i8*%bk,i64 12
%bn=bitcast i8*%bm to i32*
%bo=load i32,i32*%bn,align 4
store i8*null,i8**%d,align 8
%bp=call i8*@sml_alloc(i32 inreg%C)#0
%bq=or i32%w,1342177280
%br=getelementptr inbounds i8,i8*%bp,i64 -4
%bs=bitcast i8*%br to i32*
store i32%bq,i32*%bs,align 4
store i8*%bp,i8**%d,align 8
call void@llvm.memset.p0i8.i32(i8*%bp,i8 0,i32%C,i1 false)
%bt=bitcast i8*%bp to i32*
store i32 0,i32*%bt,align 4
%bu=icmp eq i32%bj,0
%bv=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bw=sext i32%t to i64
%bx=getelementptr inbounds i8,i8*%bp,i64%bw
br i1%bu,label%bA,label%by
by:
%bz=bitcast i8*%bx to i8**
store i8*%bv,i8**%bz,align 8
br label%bB
bA:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bx,i8*%bv,i32%bo,i1 false)
br label%bB
bB:
%bC=sext i32%w to i64
%bD=getelementptr inbounds i8,i8*%bp,i64%bC
%bE=bitcast i8*%bD to i32*
store i32%B,i32*%bE,align 4
%bF=call i8*@sml_alloc(i32 inreg 12)#0
%bG=getelementptr inbounds i8,i8*%bF,i64 -4
%bH=bitcast i8*%bG to i32*
store i32 1342177288,i32*%bH,align 4
%bI=load i8*,i8**%d,align 8
%bJ=bitcast i8*%bF to i8**
store i8*%bI,i8**%bJ,align 8
%bK=getelementptr inbounds i8,i8*%bF,i64 8
%bL=bitcast i8*%bK to i32*
store i32 1,i32*%bL,align 4
ret i8*%bF
bM:
ret i8*null
}
define internal fastcc i8*@_SMLL6false3_62(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
m:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%k,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%d,align 8
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%h],[%b,%m]
%n=phi i8*[%i,%h],[%a,%m]
%o=getelementptr inbounds i8,i8*%n,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=sub i32 0,%q
%s=and i32%q,%r
%t=bitcast i8*%n to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg%l)
%B=icmp eq i8*%A,null
br i1%B,label%aM,label%C
C:
%D=bitcast i8*%A to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%c,align 8
%F=load i8,i8*%E,align 1
switch i8%F,label%aM[
i8 83,label%aj
i8 115,label%G
]
G:
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%e,align 8
%L=getelementptr inbounds i8,i8*%H,i64 16
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
%O=icmp eq i32%N,0
br i1%O,label%U,label%P
P:
%Q=sext i32%s to i64
%R=getelementptr inbounds i8,i8*%E,i64%Q
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
br label%af
U:
store i8*null,i8**%d,align 8
%V=getelementptr inbounds i8,i8*%H,i64 20
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=call i8*@sml_alloc(i32 inreg%X)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32%X,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=sext i32%s to i64
%ad=getelementptr inbounds i8,i8*%ab,i64%ac
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Y,i8*%ad,i32%X,i1 false)
%ae=load i8*,i8**%e,align 8
br label%af
af:
%ag=phi i8*[%K,%P],[%ae,%U]
%ah=phi i8*[%T,%P],[%Y,%U]
%ai=tail call fastcc i8*@_SMLL6false4_61(i8*inreg%ag,i8*inreg%ah)
ret i8*%ai
aj:
%ak=load i8*,i8**%d,align 8
%al=getelementptr inbounds i8,i8*%ak,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=getelementptr inbounds i8,i8*%ak,i64 16
%ap=bitcast i8*%ao to i32*
%aq=load i32,i32*%ap,align 4
%ar=icmp eq i32%aq,0
br i1%ar,label%ax,label%as
as:
%at=sext i32%s to i64
%au=getelementptr inbounds i8,i8*%E,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%aI
ax:
store i8*null,i8**%d,align 8
%ay=getelementptr inbounds i8,i8*%ak,i64 20
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
%aB=call i8*@sml_alloc(i32 inreg%aA)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32%aA,i32*%aD,align 4
%aE=load i8*,i8**%c,align 8
%aF=sext i32%s to i64
%aG=getelementptr inbounds i8,i8*%aE,i64%aF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aB,i8*%aG,i32%aA,i1 false)
%aH=load i8*,i8**%e,align 8
br label%aI
aI:
%aJ=phi i8*[%an,%as],[%aH,%ax]
%aK=phi i8*[%aw,%as],[%aB,%ax]
%aL=tail call fastcc i8*@_SMLL6false4_61(i8*inreg%aJ,i8*inreg%aK)
ret i8*%aL
aM:
ret i8*null
}
define internal fastcc i8*@_SMLL6false2_63(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
m:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%k,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%d,align 8
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%h],[%b,%m]
%n=phi i8*[%i,%h],[%a,%m]
%o=getelementptr inbounds i8,i8*%n,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=sub i32 0,%q
%s=and i32%q,%r
%t=bitcast i8*%n to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg%l)
%B=icmp eq i8*%A,null
br i1%B,label%aM,label%C
C:
%D=bitcast i8*%A to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%c,align 8
%F=load i8,i8*%E,align 1
switch i8%F,label%aM[
i8 76,label%aj
i8 108,label%G
]
G:
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%e,align 8
%L=getelementptr inbounds i8,i8*%H,i64 16
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
%O=icmp eq i32%N,0
br i1%O,label%U,label%P
P:
%Q=sext i32%s to i64
%R=getelementptr inbounds i8,i8*%E,i64%Q
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
br label%af
U:
store i8*null,i8**%d,align 8
%V=getelementptr inbounds i8,i8*%H,i64 20
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=call i8*@sml_alloc(i32 inreg%X)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32%X,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=sext i32%s to i64
%ad=getelementptr inbounds i8,i8*%ab,i64%ac
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Y,i8*%ad,i32%X,i1 false)
%ae=load i8*,i8**%e,align 8
br label%af
af:
%ag=phi i8*[%K,%P],[%ae,%U]
%ah=phi i8*[%T,%P],[%Y,%U]
%ai=tail call fastcc i8*@_SMLL6false3_62(i8*inreg%ag,i8*inreg%ah)
ret i8*%ai
aj:
%ak=load i8*,i8**%d,align 8
%al=getelementptr inbounds i8,i8*%ak,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=getelementptr inbounds i8,i8*%ak,i64 16
%ap=bitcast i8*%ao to i32*
%aq=load i32,i32*%ap,align 4
%ar=icmp eq i32%aq,0
br i1%ar,label%ax,label%as
as:
%at=sext i32%s to i64
%au=getelementptr inbounds i8,i8*%E,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%aI
ax:
store i8*null,i8**%d,align 8
%ay=getelementptr inbounds i8,i8*%ak,i64 20
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
%aB=call i8*@sml_alloc(i32 inreg%aA)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32%aA,i32*%aD,align 4
%aE=load i8*,i8**%c,align 8
%aF=sext i32%s to i64
%aG=getelementptr inbounds i8,i8*%aE,i64%aF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aB,i8*%aG,i32%aA,i1 false)
%aH=load i8*,i8**%e,align 8
br label%aI
aI:
%aJ=phi i8*[%an,%as],[%aH,%ax]
%aK=phi i8*[%aw,%as],[%aB,%ax]
%aL=tail call fastcc i8*@_SMLL6false3_62(i8*inreg%aJ,i8*inreg%aK)
ret i8*%aL
aM:
ret i8*null
}
define internal fastcc i8*@_SMLL6false1_64(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
m:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%k,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%d,align 8
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%h],[%b,%m]
%n=phi i8*[%i,%h],[%a,%m]
%o=getelementptr inbounds i8,i8*%n,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=sub i32 0,%q
%s=and i32%q,%r
%t=bitcast i8*%n to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg%l)
%B=icmp eq i8*%A,null
br i1%B,label%aM,label%C
C:
%D=bitcast i8*%A to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%c,align 8
%F=load i8,i8*%E,align 1
switch i8%F,label%aM[
i8 65,label%aj
i8 97,label%G
]
G:
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%e,align 8
%L=getelementptr inbounds i8,i8*%H,i64 16
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
%O=icmp eq i32%N,0
br i1%O,label%U,label%P
P:
%Q=sext i32%s to i64
%R=getelementptr inbounds i8,i8*%E,i64%Q
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
br label%af
U:
store i8*null,i8**%d,align 8
%V=getelementptr inbounds i8,i8*%H,i64 20
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=call i8*@sml_alloc(i32 inreg%X)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32%X,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=sext i32%s to i64
%ad=getelementptr inbounds i8,i8*%ab,i64%ac
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Y,i8*%ad,i32%X,i1 false)
%ae=load i8*,i8**%e,align 8
br label%af
af:
%ag=phi i8*[%K,%P],[%ae,%U]
%ah=phi i8*[%T,%P],[%Y,%U]
%ai=tail call fastcc i8*@_SMLL6false2_63(i8*inreg%ag,i8*inreg%ah)
ret i8*%ai
aj:
%ak=load i8*,i8**%d,align 8
%al=getelementptr inbounds i8,i8*%ak,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=getelementptr inbounds i8,i8*%ak,i64 16
%ap=bitcast i8*%ao to i32*
%aq=load i32,i32*%ap,align 4
%ar=icmp eq i32%aq,0
br i1%ar,label%ax,label%as
as:
%at=sext i32%s to i64
%au=getelementptr inbounds i8,i8*%E,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%aI
ax:
store i8*null,i8**%d,align 8
%ay=getelementptr inbounds i8,i8*%ak,i64 20
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
%aB=call i8*@sml_alloc(i32 inreg%aA)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32%aA,i32*%aD,align 4
%aE=load i8*,i8**%c,align 8
%aF=sext i32%s to i64
%aG=getelementptr inbounds i8,i8*%aE,i64%aF
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aB,i8*%aG,i32%aA,i1 false)
%aH=load i8*,i8**%e,align 8
br label%aI
aI:
%aJ=phi i8*[%an,%as],[%aH,%ax]
%aK=phi i8*[%aw,%as],[%aB,%ax]
%aL=tail call fastcc i8*@_SMLL6false2_63(i8*inreg%aJ,i8*inreg%aK)
ret i8*%aL
aM:
ret i8*null
}
define internal fastcc i8*@_SMLLN4Bool4scanE_65(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%m,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%d,align 8
br label%m
m:
%n=phi i8*[%l,%k],[%a,%o]
%p=getelementptr inbounds i8,i8*%n,i64 12
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=sub i32 0,%r
%t=and i32%r,%s
%u=bitcast i8*%n to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%e,align 8
%w=getelementptr inbounds i8,i8*%n,i64 8
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=call i8*@sml_alloc(i32 inreg 20)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177296,i32*%B,align 4
store i8*%z,i8**%f,align 8
%C=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i32*
store i32%y,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%z,i64 12
%H=bitcast i8*%G to i32*
store i32%r,i32*%H,align 4
%I=getelementptr inbounds i8,i8*%z,i64 16
%J=bitcast i8*%I to i32*
store i32 1,i32*%J,align 4
%K=call i8*@sml_alloc(i32 inreg 28)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177304,i32*%M,align 4
%N=load i8*,i8**%f,align 8
%O=bitcast i8*%K to i8**
store i8*%N,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%K,i64 8
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5true3_58 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%K,i64 16
%S=bitcast i8*%R to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5true3_58 to void(...)*),void(...)**%S,align 8
%T=getelementptr inbounds i8,i8*%K,i64 24
%U=bitcast i8*%T to i32*
store i32 1,i32*%U,align 4
%V=bitcast i8**%d to i8***
%W=load i8**,i8***%V,align 8
%X=load i8*,i8**%W,align 8
store i8*%X,i8**%e,align 8
%Y=bitcast i8**%W to i8*
%Z=getelementptr inbounds i8*,i8**%W,i64 1
%aa=bitcast i8**%Z to i32*
%ab=load i32,i32*%aa,align 4
%ac=getelementptr inbounds i8,i8*%Y,i64 12
%ad=bitcast i8*%ac to i32*
%ae=load i32,i32*%ad,align 4
%af=call i8*@sml_alloc(i32 inreg 28)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32 1342177304,i32*%ah,align 4
store i8*%af,i8**%g,align 8
%ai=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aj=bitcast i8*%af to i8**
store i8*%ai,i8**%aj,align 8
%ak=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%al=getelementptr inbounds i8,i8*%af,i64 8
%am=bitcast i8*%al to i8**
store i8*%ak,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%af,i64 16
%ao=bitcast i8*%an to i32*
store i32%ab,i32*%ao,align 4
%ap=getelementptr inbounds i8,i8*%af,i64 20
%aq=bitcast i8*%ap to i32*
store i32%ae,i32*%aq,align 4
%ar=getelementptr inbounds i8,i8*%af,i64 24
%as=bitcast i8*%ar to i32*
store i32 3,i32*%as,align 4
%at=call i8*@sml_alloc(i32 inreg 28)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 1342177304,i32*%av,align 4
%aw=load i8*,i8**%g,align 8
%ax=bitcast i8*%at to i8**
store i8*%aw,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5true2_59 to void(...)*),void(...)**%az,align 8
%aA=getelementptr inbounds i8,i8*%at,i64 16
%aB=bitcast i8*%aA to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5true2_59 to void(...)*),void(...)**%aB,align 8
%aC=getelementptr inbounds i8,i8*%at,i64 24
%aD=bitcast i8*%aC to i32*
store i32 1,i32*%aD,align 4
%aE=load i8**,i8***%V,align 8
%aF=load i8*,i8**%aE,align 8
store i8*%aF,i8**%e,align 8
%aG=bitcast i8**%aE to i8*
%aH=getelementptr inbounds i8*,i8**%aE,i64 1
%aI=bitcast i8**%aH to i32*
%aJ=load i32,i32*%aI,align 4
%aK=getelementptr inbounds i8,i8*%aG,i64 12
%aL=bitcast i8*%aK to i32*
%aM=load i32,i32*%aL,align 4
%aN=call i8*@sml_alloc(i32 inreg 28)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177304,i32*%aP,align 4
store i8*%aN,i8**%f,align 8
%aQ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aR=bitcast i8*%aN to i8**
store i8*%aQ,i8**%aR,align 8
%aS=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aT=getelementptr inbounds i8,i8*%aN,i64 8
%aU=bitcast i8*%aT to i8**
store i8*%aS,i8**%aU,align 8
%aV=getelementptr inbounds i8,i8*%aN,i64 16
%aW=bitcast i8*%aV to i32*
store i32%aJ,i32*%aW,align 4
%aX=getelementptr inbounds i8,i8*%aN,i64 20
%aY=bitcast i8*%aX to i32*
store i32%aM,i32*%aY,align 4
%aZ=getelementptr inbounds i8,i8*%aN,i64 24
%a0=bitcast i8*%aZ to i32*
store i32 3,i32*%a0,align 4
%a1=call i8*@sml_alloc(i32 inreg 28)#0
%a2=getelementptr inbounds i8,i8*%a1,i64 -4
%a3=bitcast i8*%a2 to i32*
store i32 1342177304,i32*%a3,align 4
%a4=load i8*,i8**%f,align 8
%a5=bitcast i8*%a1 to i8**
store i8*%a4,i8**%a5,align 8
%a6=getelementptr inbounds i8,i8*%a1,i64 8
%a7=bitcast i8*%a6 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5true1_60 to void(...)*),void(...)**%a7,align 8
%a8=getelementptr inbounds i8,i8*%a1,i64 16
%a9=bitcast i8*%a8 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5true1_60 to void(...)*),void(...)**%a9,align 8
%ba=getelementptr inbounds i8,i8*%a1,i64 24
%bb=bitcast i8*%ba to i32*
store i32 1,i32*%bb,align 4
%bc=load i8**,i8***%V,align 8
%bd=load i8*,i8**%bc,align 8
store i8*%bd,i8**%e,align 8
%be=bitcast i8**%bc to i8*
%bf=getelementptr inbounds i8*,i8**%bc,i64 1
%bg=bitcast i8**%bf to i32*
%bh=load i32,i32*%bg,align 4
%bi=getelementptr inbounds i8,i8*%be,i64 12
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
%bl=call i8*@sml_alloc(i32 inreg 20)#0
%bm=getelementptr inbounds i8,i8*%bl,i64 -4
%bn=bitcast i8*%bm to i32*
store i32 1342177296,i32*%bn,align 4
store i8*%bl,i8**%g,align 8
%bo=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bp=bitcast i8*%bl to i8**
store i8*%bo,i8**%bp,align 8
%bq=getelementptr inbounds i8,i8*%bl,i64 8
%br=bitcast i8*%bq to i32*
store i32%bh,i32*%br,align 4
%bs=getelementptr inbounds i8,i8*%bl,i64 12
%bt=bitcast i8*%bs to i32*
store i32%bk,i32*%bt,align 4
%bu=getelementptr inbounds i8,i8*%bl,i64 16
%bv=bitcast i8*%bu to i32*
store i32 1,i32*%bv,align 4
%bw=call i8*@sml_alloc(i32 inreg 28)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177304,i32*%by,align 4
%bz=load i8*,i8**%g,align 8
%bA=bitcast i8*%bw to i8**
store i8*%bz,i8**%bA,align 8
%bB=getelementptr inbounds i8,i8*%bw,i64 8
%bC=bitcast i8*%bB to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false4_61 to void(...)*),void(...)**%bC,align 8
%bD=getelementptr inbounds i8,i8*%bw,i64 16
%bE=bitcast i8*%bD to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false4_61 to void(...)*),void(...)**%bE,align 8
%bF=getelementptr inbounds i8,i8*%bw,i64 24
%bG=bitcast i8*%bF to i32*
store i32 1,i32*%bG,align 4
%bH=load i8**,i8***%V,align 8
%bI=load i8*,i8**%bH,align 8
store i8*%bI,i8**%e,align 8
%bJ=bitcast i8**%bH to i8*
%bK=getelementptr inbounds i8*,i8**%bH,i64 1
%bL=bitcast i8**%bK to i32*
%bM=load i32,i32*%bL,align 4
%bN=getelementptr inbounds i8,i8*%bJ,i64 12
%bO=bitcast i8*%bN to i32*
%bP=load i32,i32*%bO,align 4
%bQ=call i8*@sml_alloc(i32 inreg 28)#0
%bR=getelementptr inbounds i8,i8*%bQ,i64 -4
%bS=bitcast i8*%bR to i32*
store i32 1342177304,i32*%bS,align 4
store i8*%bQ,i8**%h,align 8
%bT=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bU=bitcast i8*%bQ to i8**
store i8*%bT,i8**%bU,align 8
%bV=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bW=getelementptr inbounds i8,i8*%bQ,i64 8
%bX=bitcast i8*%bW to i8**
store i8*%bV,i8**%bX,align 8
%bY=getelementptr inbounds i8,i8*%bQ,i64 16
%bZ=bitcast i8*%bY to i32*
store i32%bM,i32*%bZ,align 4
%b0=getelementptr inbounds i8,i8*%bQ,i64 20
%b1=bitcast i8*%b0 to i32*
store i32%bP,i32*%b1,align 4
%b2=getelementptr inbounds i8,i8*%bQ,i64 24
%b3=bitcast i8*%b2 to i32*
store i32 3,i32*%b3,align 4
%b4=call i8*@sml_alloc(i32 inreg 28)#0
%b5=getelementptr inbounds i8,i8*%b4,i64 -4
%b6=bitcast i8*%b5 to i32*
store i32 1342177304,i32*%b6,align 4
%b7=load i8*,i8**%h,align 8
%b8=bitcast i8*%b4 to i8**
store i8*%b7,i8**%b8,align 8
%b9=getelementptr inbounds i8,i8*%b4,i64 8
%ca=bitcast i8*%b9 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false3_62 to void(...)*),void(...)**%ca,align 8
%cb=getelementptr inbounds i8,i8*%b4,i64 16
%cc=bitcast i8*%cb to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false3_62 to void(...)*),void(...)**%cc,align 8
%cd=getelementptr inbounds i8,i8*%b4,i64 24
%ce=bitcast i8*%cd to i32*
store i32 1,i32*%ce,align 4
%cf=load i8**,i8***%V,align 8
%cg=load i8*,i8**%cf,align 8
store i8*%cg,i8**%e,align 8
%ch=bitcast i8**%cf to i8*
%ci=getelementptr inbounds i8*,i8**%cf,i64 1
%cj=bitcast i8**%ci to i32*
%ck=load i32,i32*%cj,align 4
%cl=getelementptr inbounds i8,i8*%ch,i64 12
%cm=bitcast i8*%cl to i32*
%cn=load i32,i32*%cm,align 4
%co=call i8*@sml_alloc(i32 inreg 28)#0
%cp=getelementptr inbounds i8,i8*%co,i64 -4
%cq=bitcast i8*%cp to i32*
store i32 1342177304,i32*%cq,align 4
store i8*%co,i8**%g,align 8
%cr=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cs=bitcast i8*%co to i8**
store i8*%cr,i8**%cs,align 8
%ct=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cu=getelementptr inbounds i8,i8*%co,i64 8
%cv=bitcast i8*%cu to i8**
store i8*%ct,i8**%cv,align 8
%cw=getelementptr inbounds i8,i8*%co,i64 16
%cx=bitcast i8*%cw to i32*
store i32%ck,i32*%cx,align 4
%cy=getelementptr inbounds i8,i8*%co,i64 20
%cz=bitcast i8*%cy to i32*
store i32%cn,i32*%cz,align 4
%cA=getelementptr inbounds i8,i8*%co,i64 24
%cB=bitcast i8*%cA to i32*
store i32 3,i32*%cB,align 4
%cC=call i8*@sml_alloc(i32 inreg 28)#0
%cD=getelementptr inbounds i8,i8*%cC,i64 -4
%cE=bitcast i8*%cD to i32*
store i32 1342177304,i32*%cE,align 4
%cF=load i8*,i8**%g,align 8
%cG=bitcast i8*%cC to i8**
store i8*%cF,i8**%cG,align 8
%cH=getelementptr inbounds i8,i8*%cC,i64 8
%cI=bitcast i8*%cH to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false2_63 to void(...)*),void(...)**%cI,align 8
%cJ=getelementptr inbounds i8,i8*%cC,i64 16
%cK=bitcast i8*%cJ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false2_63 to void(...)*),void(...)**%cK,align 8
%cL=getelementptr inbounds i8,i8*%cC,i64 24
%cM=bitcast i8*%cL to i32*
store i32 1,i32*%cM,align 4
%cN=load i8**,i8***%V,align 8
%cO=load i8*,i8**%cN,align 8
store i8*%cO,i8**%e,align 8
%cP=bitcast i8**%cN to i8*
%cQ=getelementptr inbounds i8*,i8**%cN,i64 1
%cR=bitcast i8**%cQ to i32*
%cS=load i32,i32*%cR,align 4
%cT=getelementptr inbounds i8,i8*%cP,i64 12
%cU=bitcast i8*%cT to i32*
%cV=load i32,i32*%cU,align 4
%cW=call i8*@sml_alloc(i32 inreg 28)#0
%cX=getelementptr inbounds i8,i8*%cW,i64 -4
%cY=bitcast i8*%cX to i32*
store i32 1342177304,i32*%cY,align 4
store i8*%cW,i8**%h,align 8
%cZ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%c0=bitcast i8*%cW to i8**
store i8*%cZ,i8**%c0,align 8
%c1=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%c2=getelementptr inbounds i8,i8*%cW,i64 8
%c3=bitcast i8*%c2 to i8**
store i8*%c1,i8**%c3,align 8
%c4=getelementptr inbounds i8,i8*%cW,i64 16
%c5=bitcast i8*%c4 to i32*
store i32%cS,i32*%c5,align 4
%c6=getelementptr inbounds i8,i8*%cW,i64 20
%c7=bitcast i8*%c6 to i32*
store i32%cV,i32*%c7,align 4
%c8=getelementptr inbounds i8,i8*%cW,i64 24
%c9=bitcast i8*%c8 to i32*
store i32 3,i32*%c9,align 4
%da=call i8*@sml_alloc(i32 inreg 28)#0
%db=getelementptr inbounds i8,i8*%da,i64 -4
%dc=bitcast i8*%db to i32*
store i32 1342177304,i32*%dc,align 4
%dd=load i8*,i8**%h,align 8
%de=bitcast i8*%da to i8**
store i8*%dd,i8**%de,align 8
%df=getelementptr inbounds i8,i8*%da,i64 8
%dg=bitcast i8*%df to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false1_64 to void(...)*),void(...)**%dg,align 8
%dh=getelementptr inbounds i8,i8*%da,i64 16
%di=bitcast i8*%dh to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL6false1_64 to void(...)*),void(...)**%di,align 8
%dj=getelementptr inbounds i8,i8*%da,i64 24
%dk=bitcast i8*%dj to i32*
store i32 1,i32*%dk,align 4
%dl=load i8**,i8***%V,align 8
%dm=load i8*,i8**%dl,align 8
%dn=getelementptr inbounds i8,i8*%dm,i64 16
%do=bitcast i8*%dn to i8*(i8*,i8*)**
%dp=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%do,align 8
%dq=bitcast i8*%dm to i8**
%dr=load i8*,i8**%dq,align 8
store i8*%dr,i8**%e,align 8
%ds=bitcast i8**%dl to i8*
%dt=getelementptr inbounds i8*,i8**%dl,i64 1
%du=bitcast i8**%dt to i32*
%dv=load i32,i32*%du,align 4
%dw=getelementptr inbounds i8,i8*%ds,i64 12
%dx=bitcast i8*%dw to i32*
%dy=load i32,i32*%dx,align 4
%dz=call fastcc i8*@_SMLFN17SMLSharp__ScanChar10skipSpacesE(i32 inreg%dv,i32 inreg%dy)
%dA=getelementptr inbounds i8,i8*%dz,i64 16
%dB=bitcast i8*%dA to i8*(i8*,i8*)**
%dC=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dB,align 8
%dD=bitcast i8*%dz to i8**
%dE=load i8*,i8**%dD,align 8
%dF=load i8**,i8***%V,align 8
%dG=load i8*,i8**%dF,align 8
%dH=call fastcc i8*%dC(i8*inreg%dE,i8*inreg%dG)
%dI=getelementptr inbounds i8,i8*%dH,i64 16
%dJ=bitcast i8*%dI to i8*(i8*,i8*)**
%dK=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dJ,align 8
%dL=bitcast i8*%dH to i8**
%dM=load i8*,i8**%dL,align 8
%dN=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dO=call fastcc i8*%dK(i8*inreg%dM,i8*inreg%dN)
%dP=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dQ=call fastcc i8*%dp(i8*inreg%dP,i8*inreg%dO)
%dR=icmp eq i8*%dQ,null
br i1%dR,label%fy,label%dS
dS:
%dT=bitcast i8*%dQ to i8**
%dU=load i8*,i8**%dT,align 8
store i8*%dU,i8**%c,align 8
%dV=load i8,i8*%dU,align 1
switch i8%dV,label%fy[
i8 70,label%e9
i8 84,label%eK
i8 102,label%el
i8 116,label%dW
]
dW:
store i8*null,i8**%h,align 8
%dX=load i8*,i8**%d,align 8
%dY=getelementptr inbounds i8,i8*%dX,i64 8
%dZ=bitcast i8*%dY to i32*
%d0=load i32,i32*%dZ,align 4
%d1=icmp eq i32%d0,0
br i1%d1,label%d7,label%d2
d2:
%d3=sext i32%t to i64
%d4=getelementptr inbounds i8,i8*%dU,i64%d3
%d5=bitcast i8*%d4 to i8**
%d6=load i8*,i8**%d5,align 8
br label%eh
d7:
store i8*null,i8**%d,align 8
%d8=getelementptr inbounds i8,i8*%dX,i64 12
%d9=bitcast i8*%d8 to i32*
%ea=load i32,i32*%d9,align 4
%eb=call i8*@sml_alloc(i32 inreg%ea)#0
%ec=getelementptr inbounds i8,i8*%eb,i64 -4
%ed=bitcast i8*%ec to i32*
store i32%ea,i32*%ed,align 4
%ee=load i8*,i8**%c,align 8
%ef=sext i32%t to i64
%eg=getelementptr inbounds i8,i8*%ee,i64%ef
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%eb,i8*%eg,i32%ea,i1 false)
br label%eh
eh:
%ei=phi i8*[%d6,%d2],[%eb,%d7]
%ej=load i8*,i8**%f,align 8
%ek=tail call fastcc i8*@_SMLL5true1_60(i8*inreg%ej,i8*inreg%ei)
ret i8*%ek
el:
store i8*null,i8**%f,align 8
%em=load i8*,i8**%d,align 8
%en=getelementptr inbounds i8,i8*%em,i64 8
%eo=bitcast i8*%en to i32*
%ep=load i32,i32*%eo,align 4
%eq=icmp eq i32%ep,0
br i1%eq,label%ew,label%er
er:
%es=sext i32%t to i64
%et=getelementptr inbounds i8,i8*%dU,i64%es
%eu=bitcast i8*%et to i8**
%ev=load i8*,i8**%eu,align 8
br label%eG
ew:
store i8*null,i8**%d,align 8
%ex=getelementptr inbounds i8,i8*%em,i64 12
%ey=bitcast i8*%ex to i32*
%ez=load i32,i32*%ey,align 4
%eA=call i8*@sml_alloc(i32 inreg%ez)#0
%eB=getelementptr inbounds i8,i8*%eA,i64 -4
%eC=bitcast i8*%eB to i32*
store i32%ez,i32*%eC,align 4
%eD=load i8*,i8**%c,align 8
%eE=sext i32%t to i64
%eF=getelementptr inbounds i8,i8*%eD,i64%eE
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%eA,i8*%eF,i32%ez,i1 false)
br label%eG
eG:
%eH=phi i8*[%ev,%er],[%eA,%ew]
%eI=load i8*,i8**%h,align 8
%eJ=tail call fastcc i8*@_SMLL6false1_64(i8*inreg%eI,i8*inreg%eH)
ret i8*%eJ
eK:
store i8*null,i8**%h,align 8
%eL=load i8*,i8**%d,align 8
%eM=getelementptr inbounds i8,i8*%eL,i64 8
%eN=bitcast i8*%eM to i32*
%eO=load i32,i32*%eN,align 4
%eP=icmp eq i32%eO,0
br i1%eP,label%eV,label%eQ
eQ:
%eR=sext i32%t to i64
%eS=getelementptr inbounds i8,i8*%dU,i64%eR
%eT=bitcast i8*%eS to i8**
%eU=load i8*,i8**%eT,align 8
br label%e5
eV:
store i8*null,i8**%d,align 8
%eW=getelementptr inbounds i8,i8*%eL,i64 12
%eX=bitcast i8*%eW to i32*
%eY=load i32,i32*%eX,align 4
%eZ=call i8*@sml_alloc(i32 inreg%eY)#0
%e0=getelementptr inbounds i8,i8*%eZ,i64 -4
%e1=bitcast i8*%e0 to i32*
store i32%eY,i32*%e1,align 4
%e2=load i8*,i8**%c,align 8
%e3=sext i32%t to i64
%e4=getelementptr inbounds i8,i8*%e2,i64%e3
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%eZ,i8*%e4,i32%eY,i1 false)
br label%e5
e5:
%e6=phi i8*[%eU,%eQ],[%eZ,%eV]
%e7=load i8*,i8**%f,align 8
%e8=tail call fastcc i8*@_SMLL5true1_60(i8*inreg%e7,i8*inreg%e6)
ret i8*%e8
e9:
store i8*null,i8**%f,align 8
%fa=load i8*,i8**%d,align 8
%fb=getelementptr inbounds i8,i8*%fa,i64 8
%fc=bitcast i8*%fb to i32*
%fd=load i32,i32*%fc,align 4
%fe=icmp eq i32%fd,0
br i1%fe,label%fk,label%ff
ff:
%fg=sext i32%t to i64
%fh=getelementptr inbounds i8,i8*%dU,i64%fg
%fi=bitcast i8*%fh to i8**
%fj=load i8*,i8**%fi,align 8
br label%fu
fk:
store i8*null,i8**%d,align 8
%fl=getelementptr inbounds i8,i8*%fa,i64 12
%fm=bitcast i8*%fl to i32*
%fn=load i32,i32*%fm,align 4
%fo=call i8*@sml_alloc(i32 inreg%fn)#0
%fp=getelementptr inbounds i8,i8*%fo,i64 -4
%fq=bitcast i8*%fp to i32*
store i32%fn,i32*%fq,align 4
%fr=load i8*,i8**%c,align 8
%fs=sext i32%t to i64
%ft=getelementptr inbounds i8,i8*%fr,i64%fs
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%fo,i8*%ft,i32%fn,i1 false)
br label%fu
fu:
%fv=phi i8*[%fj,%ff],[%fo,%fk]
%fw=load i8*,i8**%h,align 8
%fx=tail call fastcc i8*@_SMLL6false1_64(i8*inreg%fw,i8*inreg%fv)
ret i8*%fx
fy:
ret i8*null
}
define internal fastcc i8*@_SMLLN4Bool4scanE_66(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool4scanE_65 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool4scanE_65 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%u,i64 24
%E=bitcast i8*%D to i32*
store i32 1,i32*%E,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLN4Bool4scanE_67(i32 inreg%a,i32 inreg%b)unnamed_addr#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool4scanE_66 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool4scanE_66 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define fastcc i32@_SMLFN4Bool3notE(i32 inreg%a)#3 gc"smlsharp"{
%b=icmp eq i32%a,0
%c=zext i1%b to i32
ret i32%c
}
define fastcc i8*@_SMLFN4Bool8toStringE(i32 inreg%a)#3 gc"smlsharp"{
%b=icmp eq i32%a,0
%c=select i1%b,i8*getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@b,i64 0,i32 2,i64 0),i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@c,i64 0,i32 2,i64 0)
ret i8*%c
}
define internal fastcc i8*@_SMLLN4Bool4scanE_75(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
k:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%a,%k]
%l=bitcast i8*%j to i32*
%m=load i32,i32*%l,align 4
store i8*null,i8**%d,align 8
%n=getelementptr inbounds i8,i8*%j,i64 4
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
%q=call fastcc i8*@_SMLLN4Bool4scanE_67(i32 inreg%m,i32 inreg%p)
%r=getelementptr inbounds i8,i8*%q,i64 16
%s=bitcast i8*%r to i8*(i8*,i8*)**
%t=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%s,align 8
%u=bitcast i8*%q to i8**
%v=load i8*,i8**%u,align 8
%w=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%x=call fastcc i8*%t(i8*inreg%v,i8*inreg%w)
ret i8*%x
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool4scanE_75 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN4Bool4scanE_75 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define fastcc i8*@_SMLFN4Bool10fromStringE(i8*inreg%a)#1 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%g,label%f
f:
call void@sml_check(i32 inreg%d)
br label%g
g:
%h=call fastcc i8*@_SMLFN9StringCvt10scanStringE(i32 inreg 0,i32 inreg 4)
%i=getelementptr inbounds i8,i8*%h,i64 16
%j=bitcast i8*%i to i8*(i8*,i8*)**
%k=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%j,align 8
%l=bitcast i8*%h to i8**
%m=load i8*,i8**%l,align 8
store i8*%m,i8**%c,align 8
%n=call fastcc i8*@_SMLLN4Bool4scanE_67(i32 inreg 0,i32 inreg 4)
%o=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%p=call fastcc i8*%k(i8*inreg%o,i8*inreg%n)
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
%v=load i8*,i8**%b,align 8
%w=tail call fastcc i8*%s(i8*inreg%u,i8*inreg%v)
ret i8*%w
}
define internal fastcc i8*@_SMLLN4Bool3notE_81(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
define internal fastcc i8*@_SMLLN4Bool8toStringE_82(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=icmp eq i32%d,0
%f=select i1%e,i8*getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@b,i64 0,i32 2,i64 0),i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@c,i64 0,i32 2,i64 0)
ret i8*%f
}
define internal fastcc i8*@_SMLLN4Bool4scanE_83(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN4Bool4scanE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN4Bool10fromStringE_84(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN4Bool10fromStringE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
