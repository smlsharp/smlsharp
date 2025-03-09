@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[51x i8]}><{[4x i8]zeroinitializer,i32 -2147483597,[51x i8]c"src/compiler/libs/util/main/SCCFun.sml:70.32(2002)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[13x i8]}><{[4x i8]zeroinitializer,i32 -2147483635,[13x i8]c"undefined id\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN1__6SCCFunE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN1__6SCCFunE_50 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN1__6SCCFunE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SML_ftab16a01518fb55e518_SCCFun=external global i8
@d=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Graph11getNodeInfoE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Graph3sccE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Graph5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Graph7addEdgeE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Graph7addNodeE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main38a00530c8d1f034_Graph()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_load38a00530c8d1f034_Graph(i8*)local_unnamed_addr
define private void@_SML_tabb16a01518fb55e518_SCCFun()#3{
unreachable
}
define void@_SML_load16a01518fb55e518_SCCFun(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@d,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@d,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_load38a00530c8d1f034_Graph(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb16a01518fb55e518_SCCFun,i8*@_SML_ftab16a01518fb55e518_SCCFun,i8*null)#0
ret void
}
define void@_SML_main16a01518fb55e518_SCCFun()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@d,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@d,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_main38a00530c8d1f034_Graph()#2
br label%d
}
define internal fastcc i8*@_SMLLL7addNode_38(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
br i1%j,label%k,label%m
k:
%l=bitcast i8*%b to i8**
br label%r
m:
call void@sml_check(i32 inreg%i)
%n=bitcast i8**%c to i8***
%o=load i8**,i8***%n,align 8
%p=load i8*,i8**%f,align 8
%q=bitcast i8**%o to i8*
br label%r
r:
%s=phi i8*[%q,%m],[%b,%k]
%t=phi i8*[%p,%m],[%a,%k]
%u=phi i8**[%o,%m],[%l,%k]
%v=getelementptr inbounds i8,i8*%t,i64 12
%w=bitcast i8*%v to i32*
%x=load i32,i32*%w,align 4
%y=add i32%x,7
%z=sub i32 0,%x
%A=and i32%y,%z
%B=add i32%x,3
%C=add i32%B,%A
%D=and i32%C,-4
%E=add i32%D,11
%F=and i32%E,-8
%G=lshr i32%A,3
%H=getelementptr inbounds i8,i8*%t,i64 8
%I=bitcast i8*%H to i32*
%J=load i32,i32*%I,align 4
%K=shl i32%J,%G
%L=or i32%K,1
%M=or i32%F,4
%N=load i8*,i8**%u,align 8
%O=bitcast i8*%N to i8**
%P=load i8*,i8**%O,align 8
store i8*%P,i8**%d,align 8
%Q=getelementptr inbounds i8,i8*%N,i64 8
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%e,align 8
%T=icmp eq i32%J,0
br i1%T,label%Z,label%U
U:
store i8*null,i8**%c,align 8
%V=sext i32%A to i64
%W=getelementptr inbounds i8,i8*%s,i64%V
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
br label%an
Z:
%aa=call i8*@sml_alloc(i32 inreg%x)#0
%ab=getelementptr inbounds i8,i8*%aa,i64 -4
%ac=bitcast i8*%ab to i32*
store i32%x,i32*%ac,align 4
%ad=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ae=sext i32%A to i64
%af=getelementptr inbounds i8,i8*%ad,i64%ae
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aa,i8*%af,i32%x,i1 false)
%ag=load i8*,i8**%f,align 8
%ah=getelementptr inbounds i8,i8*%ag,i64 8
%ai=bitcast i8*%ah to i32*
%aj=load i32,i32*%ai,align 4
%ak=getelementptr inbounds i8,i8*%ag,i64 12
%al=bitcast i8*%ak to i32*
%am=load i32,i32*%al,align 4
br label%an
an:
%ao=phi i64[%ae,%Z],[%V,%U]
%ap=phi i32[%am,%Z],[%x,%U]
%aq=phi i32[%aj,%Z],[%J,%U]
%ar=phi i8*[%aa,%Z],[%Y,%U]
store i8*%ar,i8**%c,align 8
%as=call fastcc i8*@_SMLFN5Graph7addNodeE(i32 inreg%aq,i32 inreg%ap)
%at=getelementptr inbounds i8,i8*%as,i64 16
%au=bitcast i8*%at to i8*(i8*,i8*)**
%av=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%au,align 8
%aw=bitcast i8*%as to i8**
%ax=load i8*,i8**%aw,align 8
%ay=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%az=call fastcc i8*%av(i8*inreg%ax,i8*inreg%ay)
%aA=getelementptr inbounds i8,i8*%az,i64 16
%aB=bitcast i8*%aA to i8*(i8*,i8*)**
%aC=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aB,align 8
%aD=bitcast i8*%az to i8**
%aE=load i8*,i8**%aD,align 8
%aF=load i8*,i8**%c,align 8
%aG=call fastcc i8*%aC(i8*inreg%aE,i8*inreg%aF)
%aH=bitcast i8*%aG to i8**
%aI=load i8*,i8**%aH,align 8
store i8*%aI,i8**%d,align 8
%aJ=getelementptr inbounds i8,i8*%aG,i64 8
%aK=bitcast i8*%aJ to i32*
%aL=load i32,i32*%aK,align 4
%aM=bitcast i8**%f to i8***
%aN=load i8**,i8***%aM,align 8
%aO=load i8*,i8**%aN,align 8
%aP=getelementptr inbounds i8,i8*%aO,i64 16
%aQ=bitcast i8*%aP to i8*(i8*,i8*,i8*)**
%aR=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%aQ,align 8
%aS=bitcast i8*%aO to i8**
%aT=load i8*,i8**%aS,align 8
store i8*%aT,i8**%g,align 8
%aU=call i8*@sml_alloc(i32 inreg 4)#0
%aV=bitcast i8*%aU to i32*
%aW=getelementptr inbounds i8,i8*%aU,i64 -4
%aX=bitcast i8*%aW to i32*
store i32 4,i32*%aX,align 4
store i8*%aU,i8**%h,align 8
store i32 0,i32*%aV,align 4
%aY=call i8*@sml_alloc(i32 inreg 4)#0
%aZ=bitcast i8*%aY to i32*
%a0=getelementptr inbounds i8,i8*%aY,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 4,i32*%a1,align 4
store i32 4,i32*%aZ,align 4
%a2=load i8*,i8**%g,align 8
%a3=load i8*,i8**%h,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
%a4=call fastcc i8*%aR(i8*inreg%a2,i8*inreg%a3,i8*inreg%aY)
%a5=getelementptr inbounds i8,i8*%a4,i64 16
%a6=bitcast i8*%a5 to i8*(i8*,i8*)**
%a7=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a6,align 8
%a8=bitcast i8*%a4 to i8**
%a9=load i8*,i8**%a8,align 8
store i8*%a9,i8**%g,align 8
%ba=load i8*,i8**%f,align 8
%bb=getelementptr inbounds i8,i8*%ba,i64 12
%bc=bitcast i8*%bb to i32*
%bd=load i32,i32*%bc,align 4
store i8*null,i8**%f,align 8
%be=getelementptr inbounds i8,i8*%ba,i64 8
%bf=bitcast i8*%be to i32*
%bg=load i32,i32*%bf,align 4
%bh=call i8*@sml_alloc(i32 inreg%M)#0
%bi=or i32%F,1342177280
%bj=getelementptr inbounds i8,i8*%bh,i64 -4
%bk=bitcast i8*%bj to i32*
store i32%bi,i32*%bk,align 4
call void@llvm.memset.p0i8.i32(i8*%bh,i8 0,i32%M,i1 false)
%bl=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bm=bitcast i8*%bh to i8**
store i8*%bl,i8**%bm,align 8
%bn=icmp eq i32%bg,0
%bo=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bp=getelementptr inbounds i8,i8*%bh,i64%ao
br i1%bn,label%bq,label%br
bq:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bp,i8*%bo,i32%bd,i1 false)
br label%bt
br:
%bs=bitcast i8*%bp to i8**
store i8*%bo,i8**%bs,align 8
br label%bt
bt:
%bu=sext i32%D to i64
%bv=getelementptr inbounds i8,i8*%bh,i64%bu
%bw=bitcast i8*%bv to i32*
store i32%aL,i32*%bw,align 4
%bx=sext i32%F to i64
%by=getelementptr inbounds i8,i8*%bh,i64%bx
%bz=bitcast i8*%by to i32*
store i32%L,i32*%bz,align 4
%bA=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bB=call fastcc i8*%a7(i8*inreg%bA,i8*inreg%bh)
store i8*%bB,i8**%c,align 8
%bC=call i8*@sml_alloc(i32 inreg 20)#0
%bD=getelementptr inbounds i8,i8*%bC,i64 -4
%bE=bitcast i8*%bD to i32*
store i32 1342177296,i32*%bE,align 4
%bF=load i8*,i8**%d,align 8
%bG=bitcast i8*%bC to i8**
store i8*%bF,i8**%bG,align 8
%bH=load i8*,i8**%c,align 8
%bI=getelementptr inbounds i8,i8*%bC,i64 8
%bJ=bitcast i8*%bI to i8**
store i8*%bH,i8**%bJ,align 8
%bK=getelementptr inbounds i8,i8*%bC,i64 16
%bL=bitcast i8*%bK to i32*
store i32 3,i32*%bL,align 4
ret i8*%bC
}
define internal fastcc i8*@_SMLLL7addEdge_39(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
store i8*%a,i8**%g,align 8
store i8*%b,i8**%c,align 8
%j=load atomic i32,i32*@sml_check_flag unordered,align 4
%k=icmp eq i32%j,0
br i1%k,label%l,label%n
l:
%m=bitcast i8*%b to i8**
br label%s
n:
call void@sml_check(i32 inreg%j)
%o=bitcast i8**%c to i8***
%p=load i8**,i8***%o,align 8
%q=load i8*,i8**%g,align 8
%r=bitcast i8**%p to i8*
br label%s
s:
%t=phi i8*[%q,%n],[%a,%l]
%u=phi i8*[%r,%n],[%b,%l]
%v=phi i8**[%p,%n],[%m,%l]
%w=getelementptr inbounds i8,i8*%t,i64 20
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=add i32%y,7
%A=sub i32 0,%y
%B=and i32%z,%A
%C=add i32%B,%y
%D=add i32%y,-1
%E=add i32%D,%C
%F=and i32%E,%A
%G=add i32%C,7
%H=and i32%G,-8
%I=lshr i32%B,3
%J=getelementptr inbounds i8,i8*%t,i64 16
%K=bitcast i8*%J to i32*
%L=load i32,i32*%K,align 4
%M=shl i32%L,%I
%N=or i32%M,1
%O=or i32%H,4
%P=add i32%C,3
%Q=and i32%P,-4
%R=add i32%Q,11
%S=and i32%R,-8
%T=or i32%S,4
%U=load i8*,i8**%v,align 8
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%d,align 8
%X=getelementptr inbounds i8,i8*%U,i64 8
%Y=bitcast i8*%X to i8**
%Z=load i8*,i8**%Y,align 8
store i8*%Z,i8**%e,align 8
%aa=icmp eq i32%L,0
br i1%aa,label%ag,label%ab
ab:
%ac=sext i32%B to i64
%ad=getelementptr inbounds i8,i8*%u,i64%ac
%ae=bitcast i8*%ad to i8**
%af=load i8*,i8**%ae,align 8
store i8*%af,i8**%f,align 8
br label%as
ag:
%ah=call i8*@sml_alloc(i32 inreg%y)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32%y,i32*%aj,align 4
%ak=load i8*,i8**%c,align 8
%al=sext i32%B to i64
%am=getelementptr inbounds i8,i8*%ak,i64%al
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ah,i8*%am,i32%y,i1 false)
%an=load i8*,i8**%g,align 8
%ao=getelementptr inbounds i8,i8*%an,i64 16
%ap=bitcast i8*%ao to i32*
%aq=load i32,i32*%ap,align 4
store i8*%ah,i8**%f,align 8
%ar=icmp eq i32%aq,0
br i1%ar,label%aB,label%as
as:
%at=phi i8*[%u,%ab],[%ak,%ag]
%au=phi i8*[%t,%ab],[%an,%ag]
%av=bitcast i8*%au to i8**
store i8*null,i8**%c,align 8
%aw=sext i32%F to i64
%ax=getelementptr inbounds i8,i8*%at,i64%aw
%ay=bitcast i8*%ax to i8**
%az=load i8*,i8**%ay,align 8
%aA=bitcast i8**%g to i8***
br label%aN
aB:
%aC=getelementptr inbounds i8,i8*%an,i64 20
%aD=bitcast i8*%aC to i32*
%aE=load i32,i32*%aD,align 4
%aF=call i8*@sml_alloc(i32 inreg%aE)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32%aE,i32*%aH,align 4
%aI=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aJ=sext i32%F to i64
%aK=getelementptr inbounds i8,i8*%aI,i64%aJ
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aF,i8*%aK,i32%aE,i1 false)
%aL=bitcast i8**%g to i8***
%aM=load i8**,i8***%aL,align 8
br label%aN
aN:
%aO=phi i8***[%aL,%aB],[%aA,%as]
%aP=phi i8**[%aM,%aB],[%av,%as]
%aQ=phi i8*[%aF,%aB],[%az,%as]
store i8*%aQ,i8**%c,align 8
%aR=load i8*,i8**%aP,align 8
%aS=getelementptr inbounds i8,i8*%aR,i64 16
%aT=bitcast i8*%aS to i8*(i8*,i8*,i8*)**
%aU=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%aT,align 8
%aV=bitcast i8*%aR to i8**
%aW=load i8*,i8**%aV,align 8
store i8*%aW,i8**%h,align 8
%aX=call i8*@sml_alloc(i32 inreg 4)#0
%aY=bitcast i8*%aX to i32*
%aZ=getelementptr inbounds i8,i8*%aX,i64 -4
%a0=bitcast i8*%aZ to i32*
store i32 4,i32*%a0,align 4
store i8*%aX,i8**%i,align 8
store i32 0,i32*%aY,align 4
%a1=call i8*@sml_alloc(i32 inreg 4)#0
%a2=bitcast i8*%a1 to i32*
%a3=getelementptr inbounds i8,i8*%a1,i64 -4
%a4=bitcast i8*%a3 to i32*
store i32 4,i32*%a4,align 4
store i32 4,i32*%a2,align 4
%a5=load i8*,i8**%h,align 8
%a6=load i8*,i8**%i,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%i,align 8
%a7=call fastcc i8*%aU(i8*inreg%a5,i8*inreg%a6,i8*inreg%a1)
%a8=getelementptr inbounds i8,i8*%a7,i64 16
%a9=bitcast i8*%a8 to i8*(i8*,i8*)**
%ba=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a9,align 8
%bb=bitcast i8*%a7 to i8**
%bc=load i8*,i8**%bb,align 8
store i8*%bc,i8**%h,align 8
%bd=load i8*,i8**%g,align 8
%be=getelementptr inbounds i8,i8*%bd,i64 20
%bf=bitcast i8*%be to i32*
%bg=load i32,i32*%bf,align 4
%bh=getelementptr inbounds i8,i8*%bd,i64 16
%bi=bitcast i8*%bh to i32*
%bj=load i32,i32*%bi,align 4
%bk=call i8*@sml_alloc(i32 inreg%O)#0
%bl=or i32%H,1342177280
%bm=getelementptr inbounds i8,i8*%bk,i64 -4
%bn=bitcast i8*%bm to i32*
store i32%bl,i32*%bn,align 4
call void@llvm.memset.p0i8.i32(i8*%bk,i8 0,i32%O,i1 false)
%bo=load i8*,i8**%e,align 8
%bp=bitcast i8*%bk to i8**
store i8*%bo,i8**%bp,align 8
%bq=icmp eq i32%bj,0
%br=load i8*,i8**%f,align 8
%bs=sext i32%B to i64
%bt=getelementptr inbounds i8,i8*%bk,i64%bs
br i1%bq,label%bu,label%bv
bu:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bt,i8*%br,i32%bg,i1 false)
br label%bx
bv:
%bw=bitcast i8*%bt to i8**
store i8*%br,i8**%bw,align 8
br label%bx
bx:
%by=sext i32%H to i64
%bz=getelementptr inbounds i8,i8*%bk,i64%by
%bA=bitcast i8*%bz to i32*
store i32%N,i32*%bA,align 4
%bB=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bC=call fastcc i8*%ba(i8*inreg%bB,i8*inreg%bk)
%bD=icmp eq i8*%bC,null
br i1%bD,label%bE,label%dd
bE:
%bF=load i8*,i8**%g,align 8
%bG=getelementptr inbounds i8,i8*%bF,i64 16
%bH=bitcast i8*%bG to i32*
%bI=load i32,i32*%bH,align 4
%bJ=getelementptr inbounds i8,i8*%bF,i64 20
%bK=bitcast i8*%bJ to i32*
%bL=load i32,i32*%bK,align 4
%bM=call fastcc i8*@_SMLFN5Graph7addNodeE(i32 inreg%bI,i32 inreg%bL)
%bN=getelementptr inbounds i8,i8*%bM,i64 16
%bO=bitcast i8*%bN to i8*(i8*,i8*)**
%bP=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bO,align 8
%bQ=bitcast i8*%bM to i8**
%bR=load i8*,i8**%bQ,align 8
%bS=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bT=call fastcc i8*%bP(i8*inreg%bR,i8*inreg%bS)
%bU=getelementptr inbounds i8,i8*%bT,i64 16
%bV=bitcast i8*%bU to i8*(i8*,i8*)**
%bW=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bV,align 8
%bX=bitcast i8*%bT to i8**
%bY=load i8*,i8**%bX,align 8
%bZ=load i8*,i8**%f,align 8
%b0=call fastcc i8*%bW(i8*inreg%bY,i8*inreg%bZ)
%b1=bitcast i8*%b0 to i8**
%b2=load i8*,i8**%b1,align 8
store i8*%b2,i8**%d,align 8
%b3=getelementptr inbounds i8,i8*%b0,i64 8
%b4=bitcast i8*%b3 to i32*
%b5=load i32,i32*%b4,align 4
%b6=load i8*,i8**%g,align 8
%b7=getelementptr inbounds i8,i8*%b6,i64 8
%b8=bitcast i8*%b7 to i8**
%b9=load i8*,i8**%b8,align 8
%ca=getelementptr inbounds i8,i8*%b9,i64 16
%cb=bitcast i8*%ca to i8*(i8*,i8*,i8*)**
%cc=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%cb,align 8
%cd=bitcast i8*%b9 to i8**
%ce=load i8*,i8**%cd,align 8
store i8*%ce,i8**%h,align 8
%cf=call i8*@sml_alloc(i32 inreg 4)#0
%cg=bitcast i8*%cf to i32*
%ch=getelementptr inbounds i8,i8*%cf,i64 -4
%ci=bitcast i8*%ch to i32*
store i32 4,i32*%ci,align 4
store i8*%cf,i8**%i,align 8
store i32 0,i32*%cg,align 4
%cj=call i8*@sml_alloc(i32 inreg 4)#0
%ck=bitcast i8*%cj to i32*
%cl=getelementptr inbounds i8,i8*%cj,i64 -4
%cm=bitcast i8*%cl to i32*
store i32 4,i32*%cm,align 4
store i32 4,i32*%ck,align 4
%cn=load i8*,i8**%h,align 8
%co=load i8*,i8**%i,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%i,align 8
%cp=call fastcc i8*%cc(i8*inreg%cn,i8*inreg%co,i8*inreg%cj)
%cq=getelementptr inbounds i8,i8*%cp,i64 16
%cr=bitcast i8*%cq to i8*(i8*,i8*)**
%cs=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cr,align 8
%ct=bitcast i8*%cp to i8**
%cu=load i8*,i8**%ct,align 8
store i8*%cu,i8**%h,align 8
%cv=load i8*,i8**%g,align 8
%cw=getelementptr inbounds i8,i8*%cv,i64 20
%cx=bitcast i8*%cw to i32*
%cy=load i32,i32*%cx,align 4
%cz=getelementptr inbounds i8,i8*%cv,i64 16
%cA=bitcast i8*%cz to i32*
%cB=load i32,i32*%cA,align 4
%cC=call i8*@sml_alloc(i32 inreg%T)#0
%cD=or i32%S,1342177280
%cE=getelementptr inbounds i8,i8*%cC,i64 -4
%cF=bitcast i8*%cE to i32*
store i32%cD,i32*%cF,align 4
call void@llvm.memset.p0i8.i32(i8*%cC,i8 0,i32%T,i1 false)
%cG=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cH=bitcast i8*%cC to i8**
store i8*%cG,i8**%cH,align 8
%cI=icmp eq i32%cB,0
%cJ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cK=getelementptr inbounds i8,i8*%cC,i64%bs
br i1%cI,label%cL,label%cM
cL:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cK,i8*%cJ,i32%cy,i1 false)
br label%cO
cM:
%cN=bitcast i8*%cK to i8**
store i8*%cJ,i8**%cN,align 8
br label%cO
cO:
%cP=sext i32%Q to i64
%cQ=getelementptr inbounds i8,i8*%cC,i64%cP
%cR=bitcast i8*%cQ to i32*
store i32%b5,i32*%cR,align 4
%cS=sext i32%S to i64
%cT=getelementptr inbounds i8,i8*%cC,i64%cS
%cU=bitcast i8*%cT to i32*
store i32%N,i32*%cU,align 4
%cV=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cW=call fastcc i8*%cs(i8*inreg%cV,i8*inreg%cC)
store i8*%cW,i8**%e,align 8
%cX=call i8*@sml_alloc(i32 inreg 20)#0
%cY=getelementptr inbounds i8,i8*%cX,i64 -4
%cZ=bitcast i8*%cY to i32*
store i32 1342177296,i32*%cZ,align 4
store i8*%cX,i8**%f,align 8
%c0=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%c1=bitcast i8*%cX to i8**
store i8*%c0,i8**%c1,align 8
%c2=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%c3=getelementptr inbounds i8,i8*%cX,i64 8
%c4=bitcast i8*%c3 to i8**
store i8*%c2,i8**%c4,align 8
%c5=getelementptr inbounds i8,i8*%cX,i64 16
%c6=bitcast i8*%c5 to i32*
store i32 3,i32*%c6,align 4
%c7=call i8*@sml_alloc(i32 inreg 20)#0
%c8=getelementptr inbounds i8,i8*%c7,i64 -4
%c9=bitcast i8*%c8 to i32*
store i32 1342177296,i32*%c9,align 4
%da=getelementptr inbounds i8,i8*%c7,i64 12
%db=bitcast i8*%da to i32*
store i32 0,i32*%db,align 1
%dc=load i8*,i8**%f,align 8
br label%dw
dd:
store i8*null,i8**%f,align 8
%de=bitcast i8*%bC to i32*
%df=load i32,i32*%de,align 4
%dg=call i8*@sml_alloc(i32 inreg 20)#0
%dh=getelementptr inbounds i8,i8*%dg,i64 -4
%di=bitcast i8*%dh to i32*
store i32 1342177296,i32*%di,align 4
store i8*%dg,i8**%f,align 8
%dj=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%dk=bitcast i8*%dg to i8**
store i8*%dj,i8**%dk,align 8
%dl=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dm=getelementptr inbounds i8,i8*%dg,i64 8
%dn=bitcast i8*%dm to i8**
store i8*%dl,i8**%dn,align 8
%do=getelementptr inbounds i8,i8*%dg,i64 16
%dp=bitcast i8*%do to i32*
store i32 3,i32*%dp,align 4
%dq=call i8*@sml_alloc(i32 inreg 20)#0
%dr=getelementptr inbounds i8,i8*%dq,i64 -4
%ds=bitcast i8*%dr to i32*
store i32 1342177296,i32*%ds,align 4
%dt=getelementptr inbounds i8,i8*%dq,i64 12
%du=bitcast i8*%dt to i32*
store i32 0,i32*%du,align 1
%dv=load i8*,i8**%f,align 8
br label%dw
dw:
%dx=phi i8*[%dq,%dd],[%c7,%cO]
%dy=phi i8*[%dv,%dd],[%dc,%cO]
%dz=phi i32[%df,%dd],[%b5,%cO]
%dA=bitcast i8*%dx to i8**
store i8*%dy,i8**%dA,align 8
%dB=getelementptr inbounds i8,i8*%dx,i64 8
%dC=bitcast i8*%dB to i32*
store i32%dz,i32*%dC,align 4
%dD=getelementptr inbounds i8,i8*%dx,i64 16
%dE=bitcast i8*%dD to i32*
store i32 1,i32*%dE,align 4
%dF=bitcast i8*%dy to i8**
%dG=load i8*,i8**%dF,align 8
store i8*%dG,i8**%d,align 8
%dH=getelementptr inbounds i8,i8*%dy,i64 8
%dI=bitcast i8*%dH to i8**
%dJ=load i8*,i8**%dI,align 8
store i8*%dJ,i8**%e,align 8
%dK=load i8**,i8***%aO,align 8
%dL=load i8*,i8**%dK,align 8
%dM=getelementptr inbounds i8,i8*%dL,i64 16
%dN=bitcast i8*%dM to i8*(i8*,i8*,i8*)**
%dO=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%dN,align 8
%dP=bitcast i8*%dL to i8**
%dQ=load i8*,i8**%dP,align 8
store i8*%dQ,i8**%f,align 8
%dR=call i8*@sml_alloc(i32 inreg 4)#0
%dS=bitcast i8*%dR to i32*
%dT=getelementptr inbounds i8,i8*%dR,i64 -4
%dU=bitcast i8*%dT to i32*
store i32 4,i32*%dU,align 4
store i8*%dR,i8**%h,align 8
store i32 0,i32*%dS,align 4
%dV=call i8*@sml_alloc(i32 inreg 4)#0
%dW=bitcast i8*%dV to i32*
%dX=getelementptr inbounds i8,i8*%dV,i64 -4
%dY=bitcast i8*%dX to i32*
store i32 4,i32*%dY,align 4
store i32 4,i32*%dW,align 4
%dZ=load i8*,i8**%f,align 8
%d0=load i8*,i8**%h,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%h,align 8
%d1=call fastcc i8*%dO(i8*inreg%dZ,i8*inreg%d0,i8*inreg%dV)
%d2=getelementptr inbounds i8,i8*%d1,i64 16
%d3=bitcast i8*%d2 to i8*(i8*,i8*)**
%d4=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%d3,align 8
%d5=bitcast i8*%d1 to i8**
%d6=load i8*,i8**%d5,align 8
store i8*%d6,i8**%f,align 8
%d7=load i8*,i8**%g,align 8
%d8=getelementptr inbounds i8,i8*%d7,i64 20
%d9=bitcast i8*%d8 to i32*
%ea=load i32,i32*%d9,align 4
%eb=getelementptr inbounds i8,i8*%d7,i64 16
%ec=bitcast i8*%eb to i32*
%ed=load i32,i32*%ec,align 4
%ee=call i8*@sml_alloc(i32 inreg%O)#0
%ef=getelementptr inbounds i8,i8*%ee,i64 -4
%eg=bitcast i8*%ef to i32*
store i32%bl,i32*%eg,align 4
call void@llvm.memset.p0i8.i32(i8*%ee,i8 0,i32%O,i1 false)
%eh=load i8*,i8**%e,align 8
%ei=bitcast i8*%ee to i8**
store i8*%eh,i8**%ei,align 8
%ej=icmp eq i32%ed,0
%ek=load i8*,i8**%c,align 8
%el=getelementptr inbounds i8,i8*%ee,i64%bs
br i1%ej,label%em,label%en
em:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%el,i8*%ek,i32%ea,i1 false)
br label%ep
en:
%eo=bitcast i8*%el to i8**
store i8*%ek,i8**%eo,align 8
br label%ep
ep:
%eq=getelementptr inbounds i8,i8*%ee,i64%by
%er=bitcast i8*%eq to i32*
store i32%N,i32*%er,align 4
%es=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%et=call fastcc i8*%d4(i8*inreg%es,i8*inreg%ee)
%eu=icmp eq i8*%et,null
br i1%eu,label%ev,label%f4
ev:
%ew=load i8*,i8**%g,align 8
%ex=getelementptr inbounds i8,i8*%ew,i64 16
%ey=bitcast i8*%ex to i32*
%ez=load i32,i32*%ey,align 4
%eA=getelementptr inbounds i8,i8*%ew,i64 20
%eB=bitcast i8*%eA to i32*
%eC=load i32,i32*%eB,align 4
%eD=call fastcc i8*@_SMLFN5Graph7addNodeE(i32 inreg%ez,i32 inreg%eC)
%eE=getelementptr inbounds i8,i8*%eD,i64 16
%eF=bitcast i8*%eE to i8*(i8*,i8*)**
%eG=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%eF,align 8
%eH=bitcast i8*%eD to i8**
%eI=load i8*,i8**%eH,align 8
%eJ=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%eK=call fastcc i8*%eG(i8*inreg%eI,i8*inreg%eJ)
%eL=getelementptr inbounds i8,i8*%eK,i64 16
%eM=bitcast i8*%eL to i8*(i8*,i8*)**
%eN=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%eM,align 8
%eO=bitcast i8*%eK to i8**
%eP=load i8*,i8**%eO,align 8
%eQ=load i8*,i8**%c,align 8
%eR=call fastcc i8*%eN(i8*inreg%eP,i8*inreg%eQ)
%eS=bitcast i8*%eR to i8**
%eT=load i8*,i8**%eS,align 8
store i8*%eT,i8**%d,align 8
%eU=getelementptr inbounds i8,i8*%eR,i64 8
%eV=bitcast i8*%eU to i32*
%eW=load i32,i32*%eV,align 4
%eX=load i8*,i8**%g,align 8
%eY=getelementptr inbounds i8,i8*%eX,i64 8
%eZ=bitcast i8*%eY to i8**
%e0=load i8*,i8**%eZ,align 8
%e1=getelementptr inbounds i8,i8*%e0,i64 16
%e2=bitcast i8*%e1 to i8*(i8*,i8*,i8*)**
%e3=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%e2,align 8
%e4=bitcast i8*%e0 to i8**
%e5=load i8*,i8**%e4,align 8
store i8*%e5,i8**%f,align 8
%e6=call i8*@sml_alloc(i32 inreg 4)#0
%e7=bitcast i8*%e6 to i32*
%e8=getelementptr inbounds i8,i8*%e6,i64 -4
%e9=bitcast i8*%e8 to i32*
store i32 4,i32*%e9,align 4
store i8*%e6,i8**%h,align 8
store i32 0,i32*%e7,align 4
%fa=call i8*@sml_alloc(i32 inreg 4)#0
%fb=bitcast i8*%fa to i32*
%fc=getelementptr inbounds i8,i8*%fa,i64 -4
%fd=bitcast i8*%fc to i32*
store i32 4,i32*%fd,align 4
store i32 4,i32*%fb,align 4
%fe=load i8*,i8**%f,align 8
%ff=load i8*,i8**%h,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%h,align 8
%fg=call fastcc i8*%e3(i8*inreg%fe,i8*inreg%ff,i8*inreg%fa)
%fh=getelementptr inbounds i8,i8*%fg,i64 16
%fi=bitcast i8*%fh to i8*(i8*,i8*)**
%fj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fi,align 8
%fk=bitcast i8*%fg to i8**
%fl=load i8*,i8**%fk,align 8
store i8*%fl,i8**%f,align 8
%fm=load i8*,i8**%g,align 8
%fn=getelementptr inbounds i8,i8*%fm,i64 20
%fo=bitcast i8*%fn to i32*
%fp=load i32,i32*%fo,align 4
%fq=getelementptr inbounds i8,i8*%fm,i64 16
%fr=bitcast i8*%fq to i32*
%fs=load i32,i32*%fr,align 4
%ft=call i8*@sml_alloc(i32 inreg%T)#0
%fu=or i32%S,1342177280
%fv=getelementptr inbounds i8,i8*%ft,i64 -4
%fw=bitcast i8*%fv to i32*
store i32%fu,i32*%fw,align 4
call void@llvm.memset.p0i8.i32(i8*%ft,i8 0,i32%T,i1 false)
%fx=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fy=bitcast i8*%ft to i8**
store i8*%fx,i8**%fy,align 8
%fz=icmp eq i32%fs,0
%fA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fB=getelementptr inbounds i8,i8*%ft,i64%bs
br i1%fz,label%fC,label%fD
fC:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%fB,i8*%fA,i32%fp,i1 false)
br label%fF
fD:
%fE=bitcast i8*%fB to i8**
store i8*%fA,i8**%fE,align 8
br label%fF
fF:
%fG=sext i32%Q to i64
%fH=getelementptr inbounds i8,i8*%ft,i64%fG
%fI=bitcast i8*%fH to i32*
store i32%eW,i32*%fI,align 4
%fJ=sext i32%S to i64
%fK=getelementptr inbounds i8,i8*%ft,i64%fJ
%fL=bitcast i8*%fK to i32*
store i32%N,i32*%fL,align 4
%fM=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%fN=call fastcc i8*%fj(i8*inreg%fM,i8*inreg%ft)
store i8*%fN,i8**%c,align 8
%fO=call i8*@sml_alloc(i32 inreg 20)#0
%fP=getelementptr inbounds i8,i8*%fO,i64 -4
%fQ=bitcast i8*%fP to i32*
store i32 1342177296,i32*%fQ,align 4
store i8*%fO,i8**%e,align 8
%fR=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fS=bitcast i8*%fO to i8**
store i8*%fR,i8**%fS,align 8
%fT=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fU=getelementptr inbounds i8,i8*%fO,i64 8
%fV=bitcast i8*%fU to i8**
store i8*%fT,i8**%fV,align 8
%fW=getelementptr inbounds i8,i8*%fO,i64 16
%fX=bitcast i8*%fW to i32*
store i32 3,i32*%fX,align 4
%fY=call i8*@sml_alloc(i32 inreg 20)#0
%fZ=getelementptr inbounds i8,i8*%fY,i64 -4
%f0=bitcast i8*%fZ to i32*
store i32 1342177296,i32*%f0,align 4
%f1=getelementptr inbounds i8,i8*%fY,i64 12
%f2=bitcast i8*%f1 to i32*
store i32 0,i32*%f2,align 1
%f3=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
br label%gn
f4:
store i8*null,i8**%c,align 8
%f5=bitcast i8*%et to i32*
%f6=load i32,i32*%f5,align 4
%f7=call i8*@sml_alloc(i32 inreg 20)#0
%f8=getelementptr inbounds i8,i8*%f7,i64 -4
%f9=bitcast i8*%f8 to i32*
store i32 1342177296,i32*%f9,align 4
store i8*%f7,i8**%c,align 8
%ga=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%gb=bitcast i8*%f7 to i8**
store i8*%ga,i8**%gb,align 8
%gc=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%gd=getelementptr inbounds i8,i8*%f7,i64 8
%ge=bitcast i8*%gd to i8**
store i8*%gc,i8**%ge,align 8
%gf=getelementptr inbounds i8,i8*%f7,i64 16
%gg=bitcast i8*%gf to i32*
store i32 3,i32*%gg,align 4
%gh=call i8*@sml_alloc(i32 inreg 20)#0
%gi=getelementptr inbounds i8,i8*%gh,i64 -4
%gj=bitcast i8*%gi to i32*
store i32 1342177296,i32*%gj,align 4
%gk=getelementptr inbounds i8,i8*%gh,i64 12
%gl=bitcast i8*%gk to i32*
store i32 0,i32*%gl,align 1
%gm=load i8*,i8**%c,align 8
br label%gn
gn:
%go=phi i8*[%gh,%f4],[%fY,%fF]
%gp=phi i8*[%gm,%f4],[%f3,%fF]
%gq=phi i32[%f6,%f4],[%eW,%fF]
%gr=bitcast i8*%go to i8**
store i8*%gp,i8**%gr,align 8
%gs=getelementptr inbounds i8,i8*%go,i64 8
%gt=bitcast i8*%gs to i32*
store i32%gq,i32*%gt,align 4
%gu=getelementptr inbounds i8,i8*%go,i64 16
%gv=bitcast i8*%gu to i32*
store i32 1,i32*%gv,align 4
%gw=bitcast i8*%gp to i8**
%gx=load i8*,i8**%gw,align 8
store i8*%gx,i8**%c,align 8
%gy=getelementptr inbounds i8,i8*%gp,i64 8
%gz=bitcast i8*%gy to i8**
%gA=load i8*,i8**%gz,align 8
store i8*%gA,i8**%d,align 8
%gB=load i8*,i8**%g,align 8
%gC=getelementptr inbounds i8,i8*%gB,i64 16
%gD=bitcast i8*%gC to i32*
%gE=load i32,i32*%gD,align 4
store i8*null,i8**%g,align 8
%gF=getelementptr inbounds i8,i8*%gB,i64 20
%gG=bitcast i8*%gF to i32*
%gH=load i32,i32*%gG,align 4
%gI=call fastcc i8*@_SMLFN5Graph7addEdgeE(i32 inreg%gE,i32 inreg%gH)
%gJ=getelementptr inbounds i8,i8*%gI,i64 16
%gK=bitcast i8*%gJ to i8*(i8*,i8*)**
%gL=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gK,align 8
%gM=bitcast i8*%gI to i8**
%gN=load i8*,i8**%gM,align 8
%gO=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gP=call fastcc i8*%gL(i8*inreg%gN,i8*inreg%gO)
%gQ=getelementptr inbounds i8,i8*%gP,i64 16
%gR=bitcast i8*%gQ to i8*(i8*,i8*)**
%gS=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gR,align 8
%gT=bitcast i8*%gP to i8**
%gU=load i8*,i8**%gT,align 8
store i8*%gU,i8**%c,align 8
%gV=call i8*@sml_alloc(i32 inreg 12)#0
%gW=bitcast i8*%gV to i32*
%gX=getelementptr inbounds i8,i8*%gV,i64 -4
%gY=bitcast i8*%gX to i32*
store i32 1342177288,i32*%gY,align 4
store i32%dz,i32*%gW,align 4
%gZ=getelementptr inbounds i8,i8*%gV,i64 4
%g0=bitcast i8*%gZ to i32*
store i32%gq,i32*%g0,align 4
%g1=getelementptr inbounds i8,i8*%gV,i64 8
%g2=bitcast i8*%g1 to i32*
store i32 0,i32*%g2,align 4
%g3=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%g4=call fastcc i8*%gS(i8*inreg%g3,i8*inreg%gV)
store i8*%g4,i8**%c,align 8
%g5=call i8*@sml_alloc(i32 inreg 20)#0
%g6=getelementptr inbounds i8,i8*%g5,i64 -4
%g7=bitcast i8*%g6 to i32*
store i32 1342177296,i32*%g7,align 4
%g8=load i8*,i8**%c,align 8
%g9=bitcast i8*%g5 to i8**
store i8*%g8,i8**%g9,align 8
%ha=load i8*,i8**%d,align 8
%hb=getelementptr inbounds i8,i8*%g5,i64 8
%hc=bitcast i8*%hb to i8**
store i8*%ha,i8**%hc,align 8
%hd=getelementptr inbounds i8,i8*%g5,i64 16
%he=bitcast i8*%hd to i32*
store i32 3,i32*%he,align 4
ret i8*%g5
}
define internal fastcc i8*@_SMLLL7getElem_42(i8*inreg%a,i32 inreg%b)#2 gc"smlsharp"{
k:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%a,%k]
%l=getelementptr inbounds i8,i8*%j,i64 12
%m=bitcast i8*%l to i32*
%n=load i32,i32*%m,align 4
%o=add i32%n,-1
%p=sub i32 0,%n
%q=and i32%o,%p
%r=getelementptr inbounds i8,i8*%j,i64 8
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=call fastcc i8*@_SMLFN5Graph11getNodeInfoE(i32 inreg%t,i32 inreg%n)
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
%A=bitcast i8**%d to i8***
%B=load i8**,i8***%A,align 8
%C=load i8*,i8**%B,align 8
%D=call fastcc i8*%x(i8*inreg%z,i8*inreg%C)
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
store i8*%I,i8**%c,align 8
%J=call i8*@sml_alloc(i32 inreg 4)#0
%K=bitcast i8*%J to i32*
%L=getelementptr inbounds i8,i8*%J,i64 -4
%M=bitcast i8*%L to i32*
store i32 4,i32*%M,align 4
store i32%b,i32*%K,align 4
%N=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%O=call fastcc i8*%G(i8*inreg%N,i8*inreg%J)
store i8*%O,i8**%c,align 8
%P=icmp eq i8*%O,null
br i1%P,label%Q,label%ak
Q:
store i8*null,i8**%d,align 8
%R=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%R,i8**%c,align 8
%S=call i8*@sml_alloc(i32 inreg 28)#0
%T=getelementptr inbounds i8,i8*%S,i64 -4
%U=bitcast i8*%T to i32*
store i32 1342177304,i32*%U,align 4
store i8*%S,i8**%d,align 8
%V=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%W=bitcast i8*%S to i8**
store i8*%V,i8**%W,align 8
%X=getelementptr inbounds i8,i8*%S,i64 8
%Y=bitcast i8*%X to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[51x i8]}>,<{[4x i8],i32,[51x i8]}>*@a,i64 0,i32 2,i64 0),i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%S,i64 16
%aa=bitcast i8*%Z to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@b,i64 0,i32 2,i64 0),i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%S,i64 24
%ac=bitcast i8*%ab to i32*
store i32 7,i32*%ac,align 4
%ad=call i8*@sml_alloc(i32 inreg 60)#0
%ae=getelementptr inbounds i8,i8*%ad,i64 -4
%af=bitcast i8*%ae to i32*
store i32 1342177336,i32*%af,align 4
%ag=getelementptr inbounds i8,i8*%ad,i64 56
%ah=bitcast i8*%ag to i32*
store i32 1,i32*%ah,align 4
%ai=load i8*,i8**%d,align 8
%aj=bitcast i8*%ad to i8**
store i8*%ai,i8**%aj,align 8
call void@sml_raise(i8*inreg%ad)#1
unreachable
ak:
%al=load i8*,i8**%d,align 8
%am=getelementptr inbounds i8,i8*%al,i64 8
%an=bitcast i8*%am to i32*
%ao=load i32,i32*%an,align 4
%ap=icmp eq i32%ao,0
br i1%ap,label%av,label%aq
aq:
%ar=sext i32%q to i64
%as=getelementptr inbounds i8,i8*%O,i64%ar
%at=bitcast i8*%as to i8**
%au=load i8*,i8**%at,align 8
ret i8*%au
av:
store i8*null,i8**%d,align 8
%aw=getelementptr inbounds i8,i8*%al,i64 12
%ax=bitcast i8*%aw to i32*
%ay=load i32,i32*%ax,align 4
%az=call i8*@sml_alloc(i32 inreg%ay)#0
%aA=getelementptr inbounds i8,i8*%az,i64 -4
%aB=bitcast i8*%aA to i32*
store i32%ay,i32*%aB,align 4
%aC=load i8*,i8**%c,align 8
%aD=sext i32%q to i64
%aE=getelementptr inbounds i8,i8*%aC,i64%aD
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%az,i8*%aE,i32%ay,i1 false)
ret i8*%az
}
define internal fastcc i8*@_SMLLL3scc_43(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%l=getelementptr inbounds i8,i8*%j,i64 8
%m=bitcast i8*%l to i32*
%n=load i32,i32*%m,align 4
%o=getelementptr inbounds i8,i8*%j,i64 12
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 0,i32 inreg 4,i32 inreg%n,i32 inreg%q)
%s=getelementptr inbounds i8,i8*%r,i64 16
%t=bitcast i8*%s to i8*(i8*,i8*)**
%u=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%t,align 8
%v=bitcast i8*%r to i8**
%w=load i8*,i8**%v,align 8
%x=bitcast i8**%d to i8***
%y=load i8**,i8***%x,align 8
store i8*null,i8**%d,align 8
%z=load i8*,i8**%y,align 8
%A=call fastcc i8*%u(i8*inreg%w,i8*inreg%z)
%B=getelementptr inbounds i8,i8*%A,i64 16
%C=bitcast i8*%B to i8*(i8*,i8*)**
%D=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%C,align 8
%E=bitcast i8*%A to i8**
%F=load i8*,i8**%E,align 8
%G=load i8*,i8**%c,align 8
%H=tail call fastcc i8*%D(i8*inreg%F,i8*inreg%G)
ret i8*%H
}
define internal fastcc i8*@_SMLLL3scc_44(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
br i1%h,label%i,label%k
i:
%j=bitcast i8*%b to i8**
br label%o
k:
call void@sml_check(i32 inreg%g)
%l=bitcast i8**%c to i8***
%m=load i8**,i8***%l,align 8
%n=load i8*,i8**%d,align 8
br label%o
o:
%p=phi i8*[%n,%k],[%a,%i]
%q=phi i8**[%m,%k],[%j,%i]
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%c,align 8
%s=bitcast i8*%p to i32*
%t=load i32,i32*%s,align 4
%u=getelementptr inbounds i8,i8*%p,i64 4
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=call i8*@sml_alloc(i32 inreg 20)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177296,i32*%z,align 4
store i8*%x,i8**%e,align 8
%A=load i8*,i8**%c,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i32*
store i32%t,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%x,i64 12
%F=bitcast i8*%E to i32*
store i32%w,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%x,i64 16
%H=bitcast i8*%G to i32*
store i32 1,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 28)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177304,i32*%K,align 4
store i8*%I,i8**%f,align 8
%L=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLL7getElem_42 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7getElem_49 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 1,i32*%S,align 4
%T=load i8*,i8**%d,align 8
%U=bitcast i8*%T to i32*
%V=load i32,i32*%U,align 4
%W=getelementptr inbounds i8,i8*%T,i64 4
%X=bitcast i8*%W to i32*
%Y=load i32,i32*%X,align 4
%Z=call fastcc i8*@_SMLFN5Graph3sccE(i32 inreg%V,i32 inreg%Y)
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8*(i8*,i8*)**
%ac=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ab,align 8
%ad=bitcast i8*%Z to i8**
%ae=load i8*,i8**%ad,align 8
%af=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ag=call fastcc i8*%ac(i8*inreg%ae,i8*inreg%af)
store i8*%ag,i8**%c,align 8
%ah=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%ai=getelementptr inbounds i8,i8*%ah,i64 16
%aj=bitcast i8*%ai to i8*(i8*,i8*)**
%ak=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aj,align 8
%al=bitcast i8*%ah to i8**
%am=load i8*,i8**%al,align 8
store i8*%am,i8**%e,align 8
%an=load i8*,i8**%d,align 8
%ao=bitcast i8*%an to i32*
%ap=load i32,i32*%ao,align 4
store i8*null,i8**%d,align 8
%aq=getelementptr inbounds i8,i8*%an,i64 4
%ar=bitcast i8*%aq to i32*
%as=load i32,i32*%ar,align 4
%at=call i8*@sml_alloc(i32 inreg 20)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 1342177296,i32*%av,align 4
store i8*%at,i8**%d,align 8
%aw=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ax=bitcast i8*%at to i8**
store i8*%aw,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to i32*
store i32%ap,i32*%az,align 4
%aA=getelementptr inbounds i8,i8*%at,i64 12
%aB=bitcast i8*%aA to i32*
store i32%as,i32*%aB,align 4
%aC=getelementptr inbounds i8,i8*%at,i64 16
%aD=bitcast i8*%aC to i32*
store i32 1,i32*%aD,align 4
%aE=call i8*@sml_alloc(i32 inreg 28)#0
%aF=getelementptr inbounds i8,i8*%aE,i64 -4
%aG=bitcast i8*%aF to i32*
store i32 1342177304,i32*%aG,align 4
%aH=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aI=bitcast i8*%aE to i8**
store i8*%aH,i8**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%aE,i64 8
%aK=bitcast i8*%aJ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3scc_43 to void(...)*),void(...)**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aE,i64 16
%aM=bitcast i8*%aL to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3scc_43 to void(...)*),void(...)**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aE,i64 24
%aO=bitcast i8*%aN to i32*
store i32 -2147483647,i32*%aO,align 4
%aP=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aQ=call fastcc i8*%ak(i8*inreg%aP,i8*inreg%aE)
%aR=getelementptr inbounds i8,i8*%aQ,i64 16
%aS=bitcast i8*%aR to i8*(i8*,i8*)**
%aT=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aS,align 8
%aU=bitcast i8*%aQ to i8**
%aV=load i8*,i8**%aU,align 8
%aW=load i8*,i8**%c,align 8
%aX=tail call fastcc i8*%aT(i8*inreg%aV,i8*inreg%aW)
ret i8*%aX
}
define internal fastcc i8*@_SMLLLN1__6SCCFunE_45(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d)#2 gc"smlsharp"{
r:
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
store i8*%a,i8**%h,align 8
store i8*%b,i8**%e,align 8
store i8*%c,i8**%f,align 8
store i8*%d,i8**%g,align 8
%l=load atomic i32,i32*@sml_check_flag unordered,align 4
%m=icmp eq i32%l,0
br i1%m,label%p,label%n
n:
call void@sml_check(i32 inreg%l)
%o=load i8*,i8**%h,align 8
br label%p
p:
%q=phi i8*[%o,%n],[%a,%r]
%s=bitcast i8*%q to i32*
%t=load i32,i32*%s,align 4
%u=getelementptr inbounds i8,i8*%q,i64 4
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=call i8*@sml_alloc(i32 inreg 20)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177296,i32*%z,align 4
store i8*%x,i8**%i,align 8
%A=load i8*,i8**%g,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i32*
store i32%t,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%x,i64 12
%F=bitcast i8*%E to i32*
store i32%w,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%x,i64 16
%H=bitcast i8*%G to i32*
store i32 1,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 28)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177304,i32*%K,align 4
store i8*%I,i8**%j,align 8
%L=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7addNode_38 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7addNode_38 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
%T=load i8*,i8**%h,align 8
%U=bitcast i8*%T to i32*
%V=load i32,i32*%U,align 4
%W=getelementptr inbounds i8,i8*%T,i64 4
%X=bitcast i8*%W to i32*
%Y=load i32,i32*%X,align 4
%Z=call i8*@sml_alloc(i32 inreg 28)#0
%aa=getelementptr inbounds i8,i8*%Z,i64 -4
%ab=bitcast i8*%aa to i32*
store i32 1342177304,i32*%ab,align 4
store i8*%Z,i8**%i,align 8
%ac=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ad=bitcast i8*%Z to i8**
store i8*%ac,i8**%ad,align 8
%ae=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%af=getelementptr inbounds i8,i8*%Z,i64 8
%ag=bitcast i8*%af to i8**
store i8*%ae,i8**%ag,align 8
%ah=getelementptr inbounds i8,i8*%Z,i64 16
%ai=bitcast i8*%ah to i32*
store i32%V,i32*%ai,align 4
%aj=getelementptr inbounds i8,i8*%Z,i64 20
%ak=bitcast i8*%aj to i32*
store i32%Y,i32*%ak,align 4
%al=getelementptr inbounds i8,i8*%Z,i64 24
%am=bitcast i8*%al to i32*
store i32 3,i32*%am,align 4
%an=call i8*@sml_alloc(i32 inreg 28)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177304,i32*%ap,align 4
store i8*%an,i8**%k,align 8
%aq=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%ar=bitcast i8*%an to i8**
store i8*%aq,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%an,i64 8
%at=bitcast i8*%as to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7addEdge_39 to void(...)*),void(...)**%at,align 8
%au=getelementptr inbounds i8,i8*%an,i64 16
%av=bitcast i8*%au to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7addEdge_39 to void(...)*),void(...)**%av,align 8
%aw=getelementptr inbounds i8,i8*%an,i64 24
%ax=bitcast i8*%aw to i32*
store i32 -2147483647,i32*%ax,align 4
%ay=load i8*,i8**%h,align 8
%az=bitcast i8*%ay to i32*
%aA=load i32,i32*%az,align 4
%aB=getelementptr inbounds i8,i8*%ay,i64 4
%aC=bitcast i8*%aB to i32*
%aD=load i32,i32*%aC,align 4
%aE=call fastcc i8*@_SMLFN5Graph5emptyE(i32 inreg%aA,i32 inreg%aD)
store i8*%aE,i8**%f,align 8
%aF=load i8*,i8**%e,align 8
%aG=getelementptr inbounds i8,i8*%aF,i64 16
%aH=bitcast i8*%aG to i8*(i8*,i8*,i8*)**
%aI=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%aH,align 8
%aJ=bitcast i8*%aF to i8**
%aK=load i8*,i8**%aJ,align 8
store i8*%aK,i8**%e,align 8
%aL=call i8*@sml_alloc(i32 inreg 4)#0
%aM=bitcast i8*%aL to i32*
%aN=getelementptr inbounds i8,i8*%aL,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 4,i32*%aO,align 4
store i8*%aL,i8**%g,align 8
store i32 0,i32*%aM,align 4
%aP=call i8*@sml_alloc(i32 inreg 4)#0
%aQ=bitcast i8*%aP to i32*
%aR=getelementptr inbounds i8,i8*%aP,i64 -4
%aS=bitcast i8*%aR to i32*
store i32 4,i32*%aS,align 4
store i32 4,i32*%aQ,align 4
%aT=load i8*,i8**%e,align 8
%aU=load i8*,i8**%g,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%g,align 8
%aV=call fastcc i8*%aI(i8*inreg%aT,i8*inreg%aU,i8*inreg%aP)
store i8*%aV,i8**%g,align 8
%aW=call i8*@sml_alloc(i32 inreg 20)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177296,i32*%aY,align 4
store i8*%aW,i8**%e,align 8
%aZ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a0=bitcast i8*%aW to i8**
store i8*%aZ,i8**%a0,align 8
%a1=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%a2=getelementptr inbounds i8,i8*%aW,i64 8
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aW,i64 16
%a5=bitcast i8*%a4 to i32*
store i32 3,i32*%a5,align 4
%a6=load i8*,i8**%h,align 8
%a7=bitcast i8*%a6 to i32*
%a8=load i32,i32*%a7,align 4
store i8*null,i8**%h,align 8
%a9=getelementptr inbounds i8,i8*%a6,i64 4
%ba=bitcast i8*%a9 to i32*
%bb=load i32,i32*%ba,align 4
%bc=call i8*@sml_alloc(i32 inreg 12)#0
%bd=bitcast i8*%bc to i32*
%be=getelementptr inbounds i8,i8*%bc,i64 -4
%bf=bitcast i8*%be to i32*
store i32 1342177288,i32*%bf,align 4
store i8*%bc,i8**%f,align 8
store i32%a8,i32*%bd,align 4
%bg=getelementptr inbounds i8,i8*%bc,i64 4
%bh=bitcast i8*%bg to i32*
store i32%bb,i32*%bh,align 4
%bi=getelementptr inbounds i8,i8*%bc,i64 8
%bj=bitcast i8*%bi to i32*
store i32 0,i32*%bj,align 4
%bk=call i8*@sml_alloc(i32 inreg 28)#0
%bl=getelementptr inbounds i8,i8*%bk,i64 -4
%bm=bitcast i8*%bl to i32*
store i32 1342177304,i32*%bm,align 4
store i8*%bk,i8**%g,align 8
%bn=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bo=bitcast i8*%bk to i8**
store i8*%bn,i8**%bo,align 8
%bp=getelementptr inbounds i8,i8*%bk,i64 8
%bq=bitcast i8*%bp to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3scc_44 to void(...)*),void(...)**%bq,align 8
%br=getelementptr inbounds i8,i8*%bk,i64 16
%bs=bitcast i8*%br to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3scc_44 to void(...)*),void(...)**%bs,align 8
%bt=getelementptr inbounds i8,i8*%bk,i64 24
%bu=bitcast i8*%bt to i32*
store i32 -2147483647,i32*%bu,align 4
%bv=call i8*@sml_alloc(i32 inreg 36)#0
%bw=getelementptr inbounds i8,i8*%bv,i64 -4
%bx=bitcast i8*%bw to i32*
store i32 1342177312,i32*%bx,align 4
%by=load i8*,i8**%k,align 8
%bz=bitcast i8*%bv to i8**
store i8*%by,i8**%bz,align 8
%bA=load i8*,i8**%j,align 8
%bB=getelementptr inbounds i8,i8*%bv,i64 8
%bC=bitcast i8*%bB to i8**
store i8*%bA,i8**%bC,align 8
%bD=load i8*,i8**%e,align 8
%bE=getelementptr inbounds i8,i8*%bv,i64 16
%bF=bitcast i8*%bE to i8**
store i8*%bD,i8**%bF,align 8
%bG=load i8*,i8**%g,align 8
%bH=getelementptr inbounds i8,i8*%bv,i64 24
%bI=bitcast i8*%bH to i8**
store i8*%bG,i8**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bv,i64 32
%bK=bitcast i8*%bJ to i32*
store i32 15,i32*%bK,align 4
ret i8*%bv
}
define internal fastcc i8*@_SMLLLN1__6SCCFunE_46(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=bitcast i8*%a to i32*
%e=load i32,i32*%d,align 4
%f=getelementptr inbounds i8,i8*%a,i64 4
%g=bitcast i8*%f to i32*
%h=load i32,i32*%g,align 4
%i=call i8*@sml_alloc(i32 inreg 12)#0
%j=bitcast i8*%i to i32*
%k=getelementptr inbounds i8,i8*%i,i64 -4
%l=bitcast i8*%k to i32*
store i32 1342177288,i32*%l,align 4
store i8*%i,i8**%c,align 8
store i32%e,i32*%j,align 4
%m=getelementptr inbounds i8,i8*%i,i64 4
%n=bitcast i8*%m to i32*
store i32%h,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%i,i64 8
%p=bitcast i8*%o to i32*
store i32 0,i32*%p,align 4
%q=call i8*@sml_alloc(i32 inreg 28)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177304,i32*%s,align 4
%t=load i8*,i8**%c,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLLLN1__6SCCFunE_45 to void(...)*),void(...)**%w,align 8
%x=getelementptr inbounds i8,i8*%q,i64 16
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLLLN1__6SCCFunE_45 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%q,i64 24
%A=bitcast i8*%z to i32*
store i32 -2147483647,i32*%A,align 4
ret i8*%q
}
define fastcc i8*@_SMLFN1__6SCCFunE(i32 inreg%a,i32 inreg%b)#4 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN1__6SCCFunE_46 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN1__6SCCFunE_46 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLL7getElem_49(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLL7getElem_42(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN1__6SCCFunE_50(i8*inreg%a,i8*inreg%b,i8*inreg%c)#4 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN1__6SCCFunE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
