@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[51x i8]}><{[4x i8]zeroinitializer,i32 -2147483597,[51x i8]c"src/compiler/libs/util/main/SCCFun.sml:70.32(2002)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[13x i8]}><{[4x i8]zeroinitializer,i32 -2147483635,[13x i8]c"undefined id\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN1__6SCCFunE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN1__6SCCFunE_54 to void(...)*),i32 -2147483647}>,align 8
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
define internal fastcc i8*@_SMLL7addNode_38(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%O=getelementptr inbounds i8,i8*%N,i64 8
%P=bitcast i8*%O to i8**
%Q=load i8*,i8**%P,align 8
store i8*%Q,i8**%d,align 8
%R=icmp eq i32%J,0
br i1%R,label%X,label%S
S:
%T=sext i32%A to i64
%U=getelementptr inbounds i8,i8*%s,i64%T
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
br label%al
X:
%Y=call i8*@sml_alloc(i32 inreg%x)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32%x,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=sext i32%A to i64
%ad=getelementptr inbounds i8,i8*%ab,i64%ac
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Y,i8*%ad,i32%x,i1 false)
%ae=load i8*,i8**%f,align 8
%af=getelementptr inbounds i8,i8*%ae,i64 8
%ag=bitcast i8*%af to i32*
%ah=load i32,i32*%ag,align 4
%ai=getelementptr inbounds i8,i8*%ae,i64 12
%aj=bitcast i8*%ai to i32*
%ak=load i32,i32*%aj,align 4
br label%al
al:
%am=phi i64[%ac,%X],[%T,%S]
%an=phi i32[%ak,%X],[%x,%S]
%ao=phi i32[%ah,%X],[%J,%S]
%ap=phi i8*[%Y,%X],[%W,%S]
store i8*%ap,i8**%e,align 8
%aq=call fastcc i8*@_SMLFN5Graph7addNodeE(i32 inreg%ao,i32 inreg%an)
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8*(i8*,i8*)**
%at=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%as,align 8
%au=bitcast i8*%aq to i8**
%av=load i8*,i8**%au,align 8
%aw=bitcast i8**%c to i8****
%ax=load i8***,i8****%aw,align 8
store i8*null,i8**%c,align 8
%ay=load i8**,i8***%ax,align 8
%az=load i8*,i8**%ay,align 8
%aA=call fastcc i8*%at(i8*inreg%av,i8*inreg%az)
%aB=getelementptr inbounds i8,i8*%aA,i64 16
%aC=bitcast i8*%aB to i8*(i8*,i8*)**
%aD=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aC,align 8
%aE=bitcast i8*%aA to i8**
%aF=load i8*,i8**%aE,align 8
%aG=load i8*,i8**%e,align 8
%aH=call fastcc i8*%aD(i8*inreg%aF,i8*inreg%aG)
%aI=bitcast i8*%aH to i8**
%aJ=load i8*,i8**%aI,align 8
store i8*%aJ,i8**%c,align 8
%aK=getelementptr inbounds i8,i8*%aH,i64 8
%aL=bitcast i8*%aK to i32*
%aM=load i32,i32*%aL,align 4
%aN=bitcast i8**%f to i8***
%aO=load i8**,i8***%aN,align 8
%aP=load i8*,i8**%aO,align 8
%aQ=getelementptr inbounds i8,i8*%aP,i64 16
%aR=bitcast i8*%aQ to i8*(i8*,i8*,i8*)**
%aS=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%aR,align 8
%aT=bitcast i8*%aP to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%g,align 8
%aV=call i8*@sml_alloc(i32 inreg 4)#0
%aW=bitcast i8*%aV to i32*
%aX=getelementptr inbounds i8,i8*%aV,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 4,i32*%aY,align 4
store i8*%aV,i8**%h,align 8
store i32 0,i32*%aW,align 4
%aZ=call i8*@sml_alloc(i32 inreg 4)#0
%a0=bitcast i8*%aZ to i32*
%a1=getelementptr inbounds i8,i8*%aZ,i64 -4
%a2=bitcast i8*%a1 to i32*
store i32 4,i32*%a2,align 4
store i32 4,i32*%a0,align 4
%a3=load i8*,i8**%g,align 8
%a4=load i8*,i8**%h,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
%a5=call fastcc i8*%aS(i8*inreg%a3,i8*inreg%a4,i8*inreg%aZ)
%a6=getelementptr inbounds i8,i8*%a5,i64 16
%a7=bitcast i8*%a6 to i8*(i8*,i8*)**
%a8=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a7,align 8
%a9=bitcast i8*%a5 to i8**
%ba=load i8*,i8**%a9,align 8
store i8*%ba,i8**%g,align 8
%bb=load i8*,i8**%f,align 8
%bc=getelementptr inbounds i8,i8*%bb,i64 12
%bd=bitcast i8*%bc to i32*
%be=load i32,i32*%bd,align 4
store i8*null,i8**%f,align 8
%bf=getelementptr inbounds i8,i8*%bb,i64 8
%bg=bitcast i8*%bf to i32*
%bh=load i32,i32*%bg,align 4
%bi=call i8*@sml_alloc(i32 inreg%M)#0
%bj=or i32%F,1342177280
%bk=getelementptr inbounds i8,i8*%bi,i64 -4
%bl=bitcast i8*%bk to i32*
store i32%bj,i32*%bl,align 4
call void@llvm.memset.p0i8.i32(i8*%bi,i8 0,i32%M,i1 false)
%bm=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bn=bitcast i8*%bi to i8**
store i8*%bm,i8**%bn,align 8
%bo=icmp eq i32%bh,0
%bp=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bq=getelementptr inbounds i8,i8*%bi,i64%am
br i1%bo,label%bt,label%br
br:
%bs=bitcast i8*%bq to i8**
store i8*%bp,i8**%bs,align 8
br label%bu
bt:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bq,i8*%bp,i32%be,i1 false)
br label%bu
bu:
%bv=sext i32%D to i64
%bw=getelementptr inbounds i8,i8*%bi,i64%bv
%bx=bitcast i8*%bw to i32*
store i32%aM,i32*%bx,align 4
%by=sext i32%F to i64
%bz=getelementptr inbounds i8,i8*%bi,i64%by
%bA=bitcast i8*%bz to i32*
store i32%L,i32*%bA,align 4
%bB=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bC=call fastcc i8*%a8(i8*inreg%bB,i8*inreg%bi)
store i8*%bC,i8**%d,align 8
%bD=call i8*@sml_alloc(i32 inreg 20)#0
%bE=getelementptr inbounds i8,i8*%bD,i64 -4
%bF=bitcast i8*%bE to i32*
store i32 1342177296,i32*%bF,align 4
%bG=load i8*,i8**%c,align 8
%bH=bitcast i8*%bD to i8**
store i8*%bG,i8**%bH,align 8
%bI=load i8*,i8**%d,align 8
%bJ=getelementptr inbounds i8,i8*%bD,i64 8
%bK=bitcast i8*%bJ to i8**
store i8*%bI,i8**%bK,align 8
%bL=getelementptr inbounds i8,i8*%bD,i64 16
%bM=bitcast i8*%bL to i32*
store i32 3,i32*%bM,align 4
ret i8*%bD
}
define internal fastcc i8*@_SMLL7addEdge_39(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store i8*%a,i8**%h,align 8
store i8*%b,i8**%c,align 8
%j=load atomic i32,i32*@sml_check_flag unordered,align 4
%k=icmp eq i32%j,0
br i1%k,label%l,label%o
l:
%m=bitcast i8*%b to i8**
%n=bitcast i8*%b to i8***
br label%u
o:
call void@sml_check(i32 inreg%j)
%p=bitcast i8**%c to i8****
%q=load i8***,i8****%p,align 8
%r=load i8*,i8**%h,align 8
%s=bitcast i8***%q to i8**
%t=bitcast i8***%q to i8*
br label%u
u:
%v=phi i8*[%t,%o],[%b,%l]
%w=phi i8**[%s,%o],[%m,%l]
%x=phi i8*[%r,%o],[%a,%l]
%y=phi i8***[%q,%o],[%n,%l]
%z=getelementptr inbounds i8,i8*%x,i64 20
%A=bitcast i8*%z to i32*
%B=load i32,i32*%A,align 4
%C=add i32%B,7
%D=sub i32 0,%B
%E=and i32%C,%D
%F=add i32%E,%B
%G=add i32%B,-1
%H=add i32%G,%F
%I=and i32%H,%D
%J=add i32%F,7
%K=and i32%J,-8
%L=lshr i32%E,3
%M=getelementptr inbounds i8,i8*%x,i64 16
%N=bitcast i8*%M to i32*
%O=load i32,i32*%N,align 4
%P=shl i32%O,%L
%Q=or i32%P,1
%R=or i32%K,4
%S=add i32%F,3
%T=and i32%S,-4
%U=add i32%T,11
%V=and i32%U,-8
%W=or i32%V,4
%X=load i8**,i8***%y,align 8
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%d,align 8
%Z=load i8*,i8**%w,align 8
%aa=getelementptr inbounds i8,i8*%Z,i64 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
store i8*%ac,i8**%e,align 8
%ad=icmp eq i32%O,0
br i1%ad,label%aj,label%ae
ae:
%af=sext i32%E to i64
%ag=getelementptr inbounds i8,i8*%v,i64%af
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
store i8*%ai,i8**%f,align 8
br label%av
aj:
%ak=call i8*@sml_alloc(i32 inreg%B)#0
%al=getelementptr inbounds i8,i8*%ak,i64 -4
%am=bitcast i8*%al to i32*
store i32%B,i32*%am,align 4
%an=load i8*,i8**%c,align 8
%ao=sext i32%E to i64
%ap=getelementptr inbounds i8,i8*%an,i64%ao
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ak,i8*%ap,i32%B,i1 false)
%aq=load i8*,i8**%h,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i32*
%at=load i32,i32*%as,align 4
store i8*%ak,i8**%f,align 8
%au=icmp eq i32%at,0
br i1%au,label%aC,label%av
av:
%aw=phi i8*[%x,%ae],[%aq,%aj]
%ax=phi i8*[%v,%ae],[%an,%aj]
%ay=sext i32%I to i64
%az=getelementptr inbounds i8,i8*%ax,i64%ay
%aA=bitcast i8*%az to i8**
%aB=load i8*,i8**%aA,align 8
br label%aN
aC:
%aD=getelementptr inbounds i8,i8*%aq,i64 20
%aE=bitcast i8*%aD to i32*
%aF=load i32,i32*%aE,align 4
%aG=call i8*@sml_alloc(i32 inreg%aF)#0
%aH=getelementptr inbounds i8,i8*%aG,i64 -4
%aI=bitcast i8*%aH to i32*
store i32%aF,i32*%aI,align 4
%aJ=load i8*,i8**%c,align 8
%aK=sext i32%I to i64
%aL=getelementptr inbounds i8,i8*%aJ,i64%aK
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aG,i8*%aL,i32%aF,i1 false)
%aM=load i8*,i8**%h,align 8
br label%aN
aN:
%aO=phi i8*[%aM,%aC],[%aw,%av]
%aP=phi i8*[%aG,%aC],[%aB,%av]
store i8*%aP,i8**%g,align 8
%aQ=getelementptr inbounds i8,i8*%aO,i64 8
%aR=bitcast i8*%aQ to i8**
%aS=load i8*,i8**%aR,align 8
%aT=getelementptr inbounds i8,i8*%aS,i64 16
%aU=bitcast i8*%aT to i8*(i8*,i8*,i8*)**
%aV=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%aU,align 8
%aW=bitcast i8*%aS to i8**
%aX=load i8*,i8**%aW,align 8
store i8*%aX,i8**%c,align 8
%aY=call i8*@sml_alloc(i32 inreg 4)#0
%aZ=bitcast i8*%aY to i32*
%a0=getelementptr inbounds i8,i8*%aY,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 4,i32*%a1,align 4
store i8*%aY,i8**%i,align 8
store i32 0,i32*%aZ,align 4
%a2=call i8*@sml_alloc(i32 inreg 4)#0
%a3=bitcast i8*%a2 to i32*
%a4=getelementptr inbounds i8,i8*%a2,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 4,i32*%a5,align 4
store i32 4,i32*%a3,align 4
%a6=load i8*,i8**%c,align 8
%a7=load i8*,i8**%i,align 8
store i8*null,i8**%c,align 8
store i8*null,i8**%i,align 8
%a8=call fastcc i8*%aV(i8*inreg%a6,i8*inreg%a7,i8*inreg%a2)
%a9=getelementptr inbounds i8,i8*%a8,i64 16
%ba=bitcast i8*%a9 to i8*(i8*,i8*)**
%bb=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ba,align 8
%bc=bitcast i8*%a8 to i8**
%bd=load i8*,i8**%bc,align 8
store i8*%bd,i8**%c,align 8
%be=load i8*,i8**%h,align 8
%bf=getelementptr inbounds i8,i8*%be,i64 20
%bg=bitcast i8*%bf to i32*
%bh=load i32,i32*%bg,align 4
%bi=getelementptr inbounds i8,i8*%be,i64 16
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
%bl=call i8*@sml_alloc(i32 inreg%R)#0
%bm=or i32%K,1342177280
%bn=getelementptr inbounds i8,i8*%bl,i64 -4
%bo=bitcast i8*%bn to i32*
store i32%bm,i32*%bo,align 4
call void@llvm.memset.p0i8.i32(i8*%bl,i8 0,i32%R,i1 false)
%bp=load i8*,i8**%e,align 8
%bq=bitcast i8*%bl to i8**
store i8*%bp,i8**%bq,align 8
%br=icmp eq i32%bk,0
%bs=load i8*,i8**%f,align 8
%bt=sext i32%E to i64
%bu=getelementptr inbounds i8,i8*%bl,i64%bt
br i1%br,label%bx,label%bv
bv:
%bw=bitcast i8*%bu to i8**
store i8*%bs,i8**%bw,align 8
br label%by
bx:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bu,i8*%bs,i32%bh,i1 false)
br label%by
by:
%bz=sext i32%K to i64
%bA=getelementptr inbounds i8,i8*%bl,i64%bz
%bB=bitcast i8*%bA to i32*
store i32%Q,i32*%bB,align 4
%bC=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bD=call fastcc i8*%bb(i8*inreg%bC,i8*inreg%bl)
%bE=icmp eq i8*%bD,null
br i1%bE,label%bF,label%dc
bF:
%bG=load i8*,i8**%h,align 8
%bH=getelementptr inbounds i8,i8*%bG,i64 16
%bI=bitcast i8*%bH to i32*
%bJ=load i32,i32*%bI,align 4
%bK=getelementptr inbounds i8,i8*%bG,i64 20
%bL=bitcast i8*%bK to i32*
%bM=load i32,i32*%bL,align 4
%bN=call fastcc i8*@_SMLFN5Graph7addNodeE(i32 inreg%bJ,i32 inreg%bM)
%bO=getelementptr inbounds i8,i8*%bN,i64 16
%bP=bitcast i8*%bO to i8*(i8*,i8*)**
%bQ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bP,align 8
%bR=bitcast i8*%bN to i8**
%bS=load i8*,i8**%bR,align 8
%bT=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bU=call fastcc i8*%bQ(i8*inreg%bS,i8*inreg%bT)
%bV=getelementptr inbounds i8,i8*%bU,i64 16
%bW=bitcast i8*%bV to i8*(i8*,i8*)**
%bX=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bW,align 8
%bY=bitcast i8*%bU to i8**
%bZ=load i8*,i8**%bY,align 8
%b0=load i8*,i8**%f,align 8
%b1=call fastcc i8*%bX(i8*inreg%bZ,i8*inreg%b0)
%b2=bitcast i8*%b1 to i8**
%b3=load i8*,i8**%b2,align 8
store i8*%b3,i8**%c,align 8
%b4=getelementptr inbounds i8,i8*%b1,i64 8
%b5=bitcast i8*%b4 to i32*
%b6=load i32,i32*%b5,align 4
%b7=bitcast i8**%h to i8***
%b8=load i8**,i8***%b7,align 8
%b9=load i8*,i8**%b8,align 8
%ca=getelementptr inbounds i8,i8*%b9,i64 16
%cb=bitcast i8*%ca to i8*(i8*,i8*,i8*)**
%cc=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%cb,align 8
%cd=bitcast i8*%b9 to i8**
%ce=load i8*,i8**%cd,align 8
store i8*%ce,i8**%d,align 8
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
%cn=load i8*,i8**%d,align 8
%co=load i8*,i8**%i,align 8
store i8*null,i8**%d,align 8
store i8*null,i8**%i,align 8
%cp=call fastcc i8*%cc(i8*inreg%cn,i8*inreg%co,i8*inreg%cj)
%cq=getelementptr inbounds i8,i8*%cp,i64 16
%cr=bitcast i8*%cq to i8*(i8*,i8*)**
%cs=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cr,align 8
%ct=bitcast i8*%cp to i8**
%cu=load i8*,i8**%ct,align 8
store i8*%cu,i8**%d,align 8
%cv=load i8*,i8**%h,align 8
%cw=getelementptr inbounds i8,i8*%cv,i64 20
%cx=bitcast i8*%cw to i32*
%cy=load i32,i32*%cx,align 4
%cz=getelementptr inbounds i8,i8*%cv,i64 16
%cA=bitcast i8*%cz to i32*
%cB=load i32,i32*%cA,align 4
%cC=call i8*@sml_alloc(i32 inreg%W)#0
%cD=or i32%V,1342177280
%cE=getelementptr inbounds i8,i8*%cC,i64 -4
%cF=bitcast i8*%cE to i32*
store i32%cD,i32*%cF,align 4
call void@llvm.memset.p0i8.i32(i8*%cC,i8 0,i32%W,i1 false)
%cG=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cH=bitcast i8*%cC to i8**
store i8*%cG,i8**%cH,align 8
%cI=icmp eq i32%cB,0
%cJ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cK=getelementptr inbounds i8,i8*%cC,i64%bt
br i1%cI,label%cN,label%cL
cL:
%cM=bitcast i8*%cK to i8**
store i8*%cJ,i8**%cM,align 8
br label%cO
cN:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%cK,i8*%cJ,i32%cy,i1 false)
br label%cO
cO:
%cP=sext i32%T to i64
%cQ=getelementptr inbounds i8,i8*%cC,i64%cP
%cR=bitcast i8*%cQ to i32*
store i32%b6,i32*%cR,align 4
%cS=sext i32%V to i64
%cT=getelementptr inbounds i8,i8*%cC,i64%cS
%cU=bitcast i8*%cT to i32*
store i32%Q,i32*%cU,align 4
%cV=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cW=call fastcc i8*%cs(i8*inreg%cV,i8*inreg%cC)
store i8*%cW,i8**%d,align 8
%cX=call i8*@sml_alloc(i32 inreg 20)#0
%cY=getelementptr inbounds i8,i8*%cX,i64 -4
%cZ=bitcast i8*%cY to i32*
store i32 1342177296,i32*%cZ,align 4
store i8*%cX,i8**%e,align 8
%c0=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%c1=bitcast i8*%cX to i8**
store i8*%c0,i8**%c1,align 8
%c2=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
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
br label%du
dc:
store i8*null,i8**%f,align 8
%dd=bitcast i8*%bD to i32*
%de=load i32,i32*%dd,align 4
%df=call i8*@sml_alloc(i32 inreg 20)#0
%dg=getelementptr inbounds i8,i8*%df,i64 -4
%dh=bitcast i8*%dg to i32*
store i32 1342177296,i32*%dh,align 4
store i8*%df,i8**%c,align 8
%di=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%dj=bitcast i8*%df to i8**
store i8*%di,i8**%dj,align 8
%dk=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dl=getelementptr inbounds i8,i8*%df,i64 8
%dm=bitcast i8*%dl to i8**
store i8*%dk,i8**%dm,align 8
%dn=getelementptr inbounds i8,i8*%df,i64 16
%do=bitcast i8*%dn to i32*
store i32 3,i32*%do,align 4
%dp=call i8*@sml_alloc(i32 inreg 20)#0
%dq=getelementptr inbounds i8,i8*%dp,i64 -4
%dr=bitcast i8*%dq to i32*
store i32 1342177296,i32*%dr,align 4
%ds=getelementptr inbounds i8,i8*%dp,i64 12
%dt=bitcast i8*%ds to i32*
store i32 0,i32*%dt,align 1
br label%du
du:
%dv=phi i8*[%dp,%dc],[%c7,%cO]
%dw=phi i8**[%c,%dc],[%e,%cO]
%dx=phi i32[%de,%dc],[%b6,%cO]
%dy=load i8*,i8**%dw,align 8
%dz=bitcast i8*%dv to i8**
store i8*%dy,i8**%dz,align 8
%dA=getelementptr inbounds i8,i8*%dv,i64 8
%dB=bitcast i8*%dA to i32*
store i32%dx,i32*%dB,align 4
%dC=getelementptr inbounds i8,i8*%dv,i64 16
%dD=bitcast i8*%dC to i32*
store i32 1,i32*%dD,align 4
%dE=bitcast i8*%dv to i8***
%dF=load i8**,i8***%dE,align 8
%dG=load i8*,i8**%dF,align 8
store i8*%dG,i8**%c,align 8
%dH=getelementptr inbounds i8*,i8**%dF,i64 1
%dI=load i8*,i8**%dH,align 8
store i8*%dI,i8**%d,align 8
%dJ=load i8*,i8**%h,align 8
%dK=getelementptr inbounds i8,i8*%dJ,i64 8
%dL=bitcast i8*%dK to i8**
%dM=load i8*,i8**%dL,align 8
%dN=getelementptr inbounds i8,i8*%dM,i64 16
%dO=bitcast i8*%dN to i8*(i8*,i8*,i8*)**
%dP=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%dO,align 8
%dQ=bitcast i8*%dM to i8**
%dR=load i8*,i8**%dQ,align 8
store i8*%dR,i8**%e,align 8
%dS=call i8*@sml_alloc(i32 inreg 4)#0
%dT=bitcast i8*%dS to i32*
%dU=getelementptr inbounds i8,i8*%dS,i64 -4
%dV=bitcast i8*%dU to i32*
store i32 4,i32*%dV,align 4
store i8*%dS,i8**%f,align 8
store i32 0,i32*%dT,align 4
%dW=call i8*@sml_alloc(i32 inreg 4)#0
%dX=bitcast i8*%dW to i32*
%dY=getelementptr inbounds i8,i8*%dW,i64 -4
%dZ=bitcast i8*%dY to i32*
store i32 4,i32*%dZ,align 4
store i32 4,i32*%dX,align 4
%d0=load i8*,i8**%e,align 8
%d1=load i8*,i8**%f,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%d2=call fastcc i8*%dP(i8*inreg%d0,i8*inreg%d1,i8*inreg%dW)
%d3=getelementptr inbounds i8,i8*%d2,i64 16
%d4=bitcast i8*%d3 to i8*(i8*,i8*)**
%d5=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%d4,align 8
%d6=bitcast i8*%d2 to i8**
%d7=load i8*,i8**%d6,align 8
store i8*%d7,i8**%e,align 8
%d8=load i8*,i8**%h,align 8
%d9=getelementptr inbounds i8,i8*%d8,i64 20
%ea=bitcast i8*%d9 to i32*
%eb=load i32,i32*%ea,align 4
%ec=getelementptr inbounds i8,i8*%d8,i64 16
%ed=bitcast i8*%ec to i32*
%ee=load i32,i32*%ed,align 4
%ef=call i8*@sml_alloc(i32 inreg%R)#0
%eg=getelementptr inbounds i8,i8*%ef,i64 -4
%eh=bitcast i8*%eg to i32*
store i32%bm,i32*%eh,align 4
call void@llvm.memset.p0i8.i32(i8*%ef,i8 0,i32%R,i1 false)
%ei=load i8*,i8**%d,align 8
%ej=bitcast i8*%ef to i8**
store i8*%ei,i8**%ej,align 8
%ek=icmp eq i32%ee,0
%el=load i8*,i8**%g,align 8
%em=getelementptr inbounds i8,i8*%ef,i64%bt
br i1%ek,label%ep,label%en
en:
%eo=bitcast i8*%em to i8**
store i8*%el,i8**%eo,align 8
br label%eq
ep:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%em,i8*%el,i32%eb,i1 false)
br label%eq
eq:
%er=getelementptr inbounds i8,i8*%ef,i64%bz
%es=bitcast i8*%er to i32*
store i32%Q,i32*%es,align 4
%et=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%eu=call fastcc i8*%d5(i8*inreg%et,i8*inreg%ef)
%ev=icmp eq i8*%eu,null
br i1%ev,label%ew,label%f3
ew:
%ex=load i8*,i8**%h,align 8
%ey=getelementptr inbounds i8,i8*%ex,i64 16
%ez=bitcast i8*%ey to i32*
%eA=load i32,i32*%ez,align 4
%eB=getelementptr inbounds i8,i8*%ex,i64 20
%eC=bitcast i8*%eB to i32*
%eD=load i32,i32*%eC,align 4
%eE=call fastcc i8*@_SMLFN5Graph7addNodeE(i32 inreg%eA,i32 inreg%eD)
%eF=getelementptr inbounds i8,i8*%eE,i64 16
%eG=bitcast i8*%eF to i8*(i8*,i8*)**
%eH=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%eG,align 8
%eI=bitcast i8*%eE to i8**
%eJ=load i8*,i8**%eI,align 8
%eK=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%eL=call fastcc i8*%eH(i8*inreg%eJ,i8*inreg%eK)
%eM=getelementptr inbounds i8,i8*%eL,i64 16
%eN=bitcast i8*%eM to i8*(i8*,i8*)**
%eO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%eN,align 8
%eP=bitcast i8*%eL to i8**
%eQ=load i8*,i8**%eP,align 8
%eR=load i8*,i8**%g,align 8
%eS=call fastcc i8*%eO(i8*inreg%eQ,i8*inreg%eR)
%eT=bitcast i8*%eS to i8**
%eU=load i8*,i8**%eT,align 8
store i8*%eU,i8**%c,align 8
%eV=getelementptr inbounds i8,i8*%eS,i64 8
%eW=bitcast i8*%eV to i32*
%eX=load i32,i32*%eW,align 4
%eY=bitcast i8**%h to i8***
%eZ=load i8**,i8***%eY,align 8
%e0=load i8*,i8**%eZ,align 8
%e1=getelementptr inbounds i8,i8*%e0,i64 16
%e2=bitcast i8*%e1 to i8*(i8*,i8*,i8*)**
%e3=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%e2,align 8
%e4=bitcast i8*%e0 to i8**
%e5=load i8*,i8**%e4,align 8
store i8*%e5,i8**%e,align 8
%e6=call i8*@sml_alloc(i32 inreg 4)#0
%e7=bitcast i8*%e6 to i32*
%e8=getelementptr inbounds i8,i8*%e6,i64 -4
%e9=bitcast i8*%e8 to i32*
store i32 4,i32*%e9,align 4
store i8*%e6,i8**%f,align 8
store i32 0,i32*%e7,align 4
%fa=call i8*@sml_alloc(i32 inreg 4)#0
%fb=bitcast i8*%fa to i32*
%fc=getelementptr inbounds i8,i8*%fa,i64 -4
%fd=bitcast i8*%fc to i32*
store i32 4,i32*%fd,align 4
store i32 4,i32*%fb,align 4
%fe=load i8*,i8**%e,align 8
%ff=load i8*,i8**%f,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%fg=call fastcc i8*%e3(i8*inreg%fe,i8*inreg%ff,i8*inreg%fa)
%fh=getelementptr inbounds i8,i8*%fg,i64 16
%fi=bitcast i8*%fh to i8*(i8*,i8*)**
%fj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fi,align 8
%fk=bitcast i8*%fg to i8**
%fl=load i8*,i8**%fk,align 8
store i8*%fl,i8**%e,align 8
%fm=load i8*,i8**%h,align 8
%fn=getelementptr inbounds i8,i8*%fm,i64 20
%fo=bitcast i8*%fn to i32*
%fp=load i32,i32*%fo,align 4
%fq=getelementptr inbounds i8,i8*%fm,i64 16
%fr=bitcast i8*%fq to i32*
%fs=load i32,i32*%fr,align 4
%ft=call i8*@sml_alloc(i32 inreg%W)#0
%fu=or i32%V,1342177280
%fv=getelementptr inbounds i8,i8*%ft,i64 -4
%fw=bitcast i8*%fv to i32*
store i32%fu,i32*%fw,align 4
call void@llvm.memset.p0i8.i32(i8*%ft,i8 0,i32%W,i1 false)
%fx=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fy=bitcast i8*%ft to i8**
store i8*%fx,i8**%fy,align 8
%fz=icmp eq i32%fs,0
%fA=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%fB=getelementptr inbounds i8,i8*%ft,i64%bt
br i1%fz,label%fE,label%fC
fC:
%fD=bitcast i8*%fB to i8**
store i8*%fA,i8**%fD,align 8
br label%fF
fE:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%fB,i8*%fA,i32%fp,i1 false)
br label%fF
fF:
%fG=sext i32%T to i64
%fH=getelementptr inbounds i8,i8*%ft,i64%fG
%fI=bitcast i8*%fH to i32*
store i32%eX,i32*%fI,align 4
%fJ=sext i32%V to i64
%fK=getelementptr inbounds i8,i8*%ft,i64%fJ
%fL=bitcast i8*%fK to i32*
store i32%Q,i32*%fL,align 4
%fM=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fN=call fastcc i8*%fj(i8*inreg%fM,i8*inreg%ft)
store i8*%fN,i8**%d,align 8
%fO=call i8*@sml_alloc(i32 inreg 20)#0
%fP=getelementptr inbounds i8,i8*%fO,i64 -4
%fQ=bitcast i8*%fP to i32*
store i32 1342177296,i32*%fQ,align 4
store i8*%fO,i8**%e,align 8
%fR=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fS=bitcast i8*%fO to i8**
store i8*%fR,i8**%fS,align 8
%fT=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
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
br label%gl
f3:
store i8*null,i8**%g,align 8
%f4=bitcast i8*%eu to i32*
%f5=load i32,i32*%f4,align 4
%f6=call i8*@sml_alloc(i32 inreg 20)#0
%f7=getelementptr inbounds i8,i8*%f6,i64 -4
%f8=bitcast i8*%f7 to i32*
store i32 1342177296,i32*%f8,align 4
store i8*%f6,i8**%e,align 8
%f9=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ga=bitcast i8*%f6 to i8**
store i8*%f9,i8**%ga,align 8
%gb=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%gc=getelementptr inbounds i8,i8*%f6,i64 8
%gd=bitcast i8*%gc to i8**
store i8*%gb,i8**%gd,align 8
%ge=getelementptr inbounds i8,i8*%f6,i64 16
%gf=bitcast i8*%ge to i32*
store i32 3,i32*%gf,align 4
%gg=call i8*@sml_alloc(i32 inreg 20)#0
%gh=getelementptr inbounds i8,i8*%gg,i64 -4
%gi=bitcast i8*%gh to i32*
store i32 1342177296,i32*%gi,align 4
%gj=getelementptr inbounds i8,i8*%gg,i64 12
%gk=bitcast i8*%gj to i32*
store i32 0,i32*%gk,align 1
br label%gl
gl:
%gm=phi i8*[%gg,%f3],[%fY,%fF]
%gn=phi i32[%f5,%f3],[%eX,%fF]
%go=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%gp=bitcast i8*%gm to i8**
store i8*%go,i8**%gp,align 8
%gq=getelementptr inbounds i8,i8*%gm,i64 8
%gr=bitcast i8*%gq to i32*
store i32%gn,i32*%gr,align 4
%gs=getelementptr inbounds i8,i8*%gm,i64 16
%gt=bitcast i8*%gs to i32*
store i32 1,i32*%gt,align 4
store i8*%gm,i8**%d,align 8
%gu=getelementptr inbounds i8,i8*%go,i64 8
%gv=bitcast i8*%gu to i8**
%gw=load i8*,i8**%gv,align 8
store i8*%gw,i8**%c,align 8
%gx=load i8*,i8**%h,align 8
%gy=getelementptr inbounds i8,i8*%gx,i64 16
%gz=bitcast i8*%gy to i32*
%gA=load i32,i32*%gz,align 4
store i8*null,i8**%h,align 8
%gB=getelementptr inbounds i8,i8*%gx,i64 20
%gC=bitcast i8*%gB to i32*
%gD=load i32,i32*%gC,align 4
%gE=call fastcc i8*@_SMLFN5Graph7addEdgeE(i32 inreg%gA,i32 inreg%gD)
%gF=getelementptr inbounds i8,i8*%gE,i64 16
%gG=bitcast i8*%gF to i8*(i8*,i8*)**
%gH=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gG,align 8
%gI=bitcast i8*%gE to i8**
%gJ=load i8*,i8**%gI,align 8
%gK=bitcast i8**%d to i8****
%gL=load i8***,i8****%gK,align 8
store i8*null,i8**%d,align 8
%gM=load i8**,i8***%gL,align 8
%gN=load i8*,i8**%gM,align 8
%gO=call fastcc i8*%gH(i8*inreg%gJ,i8*inreg%gN)
%gP=getelementptr inbounds i8,i8*%gO,i64 16
%gQ=bitcast i8*%gP to i8*(i8*,i8*)**
%gR=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gQ,align 8
%gS=bitcast i8*%gO to i8**
%gT=load i8*,i8**%gS,align 8
store i8*%gT,i8**%d,align 8
%gU=call i8*@sml_alloc(i32 inreg 12)#0
%gV=bitcast i8*%gU to i32*
%gW=getelementptr inbounds i8,i8*%gU,i64 -4
%gX=bitcast i8*%gW to i32*
store i32 1342177288,i32*%gX,align 4
store i32%dx,i32*%gV,align 4
%gY=getelementptr inbounds i8,i8*%gU,i64 4
%gZ=bitcast i8*%gY to i32*
store i32%gn,i32*%gZ,align 4
%g0=getelementptr inbounds i8,i8*%gU,i64 8
%g1=bitcast i8*%g0 to i32*
store i32 0,i32*%g1,align 4
%g2=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%g3=call fastcc i8*%gR(i8*inreg%g2,i8*inreg%gU)
store i8*%g3,i8**%d,align 8
%g4=call i8*@sml_alloc(i32 inreg 20)#0
%g5=getelementptr inbounds i8,i8*%g4,i64 -4
%g6=bitcast i8*%g5 to i32*
store i32 1342177296,i32*%g6,align 4
%g7=load i8*,i8**%d,align 8
%g8=bitcast i8*%g4 to i8**
store i8*%g7,i8**%g8,align 8
%g9=load i8*,i8**%c,align 8
%ha=getelementptr inbounds i8,i8*%g4,i64 8
%hb=bitcast i8*%ha to i8**
store i8*%g9,i8**%hb,align 8
%hc=getelementptr inbounds i8,i8*%g4,i64 16
%hd=bitcast i8*%hc to i32*
store i32 3,i32*%hd,align 4
ret i8*%g4
}
define internal fastcc i8*@_SMLL7getElem_42(i8*inreg%a,i32 inreg%b)#2 gc"smlsharp"{
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
%A=bitcast i8**%d to i8****
%B=load i8***,i8****%A,align 8
%C=load i8**,i8***%B,align 8
%D=load i8*,i8**%C,align 8
%E=call fastcc i8*%x(i8*inreg%z,i8*inreg%D)
%F=getelementptr inbounds i8,i8*%E,i64 16
%G=bitcast i8*%F to i8*(i8*,i8*)**
%H=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%G,align 8
%I=bitcast i8*%E to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%c,align 8
%K=call i8*@sml_alloc(i32 inreg 4)#0
%L=bitcast i8*%K to i32*
%M=getelementptr inbounds i8,i8*%K,i64 -4
%N=bitcast i8*%M to i32*
store i32 4,i32*%N,align 4
store i32%b,i32*%L,align 4
%O=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%P=call fastcc i8*%H(i8*inreg%O,i8*inreg%K)
store i8*%P,i8**%c,align 8
%Q=icmp eq i8*%P,null
br i1%Q,label%R,label%al
R:
store i8*null,i8**%d,align 8
%S=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%S,i8**%c,align 8
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
store i8*%T,i8**%d,align 8
%W=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%X=bitcast i8*%T to i8**
store i8*%W,i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%T,i64 8
%Z=bitcast i8*%Y to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[51x i8]}>,<{[4x i8],i32,[51x i8]}>*@a,i64 0,i32 2,i64 0),i8**%Z,align 8
%aa=getelementptr inbounds i8,i8*%T,i64 16
%ab=bitcast i8*%aa to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@b,i64 0,i32 2,i64 0),i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%T,i64 24
%ad=bitcast i8*%ac to i32*
store i32 7,i32*%ad,align 4
%ae=call i8*@sml_alloc(i32 inreg 60)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177336,i32*%ag,align 4
%ah=getelementptr inbounds i8,i8*%ae,i64 56
%ai=bitcast i8*%ah to i32*
store i32 1,i32*%ai,align 4
%aj=load i8*,i8**%d,align 8
%ak=bitcast i8*%ae to i8**
store i8*%aj,i8**%ak,align 8
call void@sml_raise(i8*inreg%ae)#1
unreachable
al:
%am=load i8*,i8**%d,align 8
%an=getelementptr inbounds i8,i8*%am,i64 8
%ao=bitcast i8*%an to i32*
%ap=load i32,i32*%ao,align 4
%aq=icmp eq i32%ap,0
br i1%aq,label%aw,label%ar
ar:
%as=sext i32%q to i64
%at=getelementptr inbounds i8,i8*%P,i64%as
%au=bitcast i8*%at to i8**
%av=load i8*,i8**%au,align 8
br label%aG
aw:
store i8*null,i8**%d,align 8
%ax=getelementptr inbounds i8,i8*%am,i64 12
%ay=bitcast i8*%ax to i32*
%az=load i32,i32*%ay,align 4
%aA=call i8*@sml_alloc(i32 inreg%az)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32%az,i32*%aC,align 4
%aD=load i8*,i8**%c,align 8
%aE=sext i32%q to i64
%aF=getelementptr inbounds i8,i8*%aD,i64%aE
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aA,i8*%aF,i32%az,i1 false)
br label%aG
aG:
%aH=phi i8*[%av,%ar],[%aA,%aw]
ret i8*%aH
}
define internal fastcc i8*@_SMLL3scc_43(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
define internal fastcc i8*@_SMLL3scc_44(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%n=bitcast i8*%l to i32*
%o=load i32,i32*%n,align 4
%p=getelementptr inbounds i8,i8*%l,i64 4
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=call i8*@sml_alloc(i32 inreg 20)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177296,i32*%u,align 4
store i8*%s,i8**%e,align 8
%v=load i8*,i8**%c,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to i32*
store i32%o,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%s,i64 12
%A=bitcast i8*%z to i32*
store i32%r,i32*%A,align 4
%B=getelementptr inbounds i8,i8*%s,i64 16
%C=bitcast i8*%B to i32*
store i32 1,i32*%C,align 4
%D=call i8*@sml_alloc(i32 inreg 28)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177304,i32*%F,align 4
store i8*%D,i8**%f,align 8
%G=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%H=bitcast i8*%D to i8**
store i8*%G,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%D,i64 8
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLL7getElem_42 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%D,i64 16
%L=bitcast i8*%K to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7getElem_52 to void(...)*),void(...)**%L,align 8
%M=getelementptr inbounds i8,i8*%D,i64 24
%N=bitcast i8*%M to i32*
store i32 1,i32*%N,align 4
%O=load i8*,i8**%d,align 8
%P=bitcast i8*%O to i32*
%Q=load i32,i32*%P,align 4
%R=getelementptr inbounds i8,i8*%O,i64 4
%S=bitcast i8*%R to i32*
%T=load i32,i32*%S,align 4
%U=call fastcc i8*@_SMLFN5Graph3sccE(i32 inreg%Q,i32 inreg%T)
%V=getelementptr inbounds i8,i8*%U,i64 16
%W=bitcast i8*%V to i8*(i8*,i8*)**
%X=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%W,align 8
%Y=bitcast i8*%U to i8**
%Z=load i8*,i8**%Y,align 8
%aa=bitcast i8**%c to i8***
%ab=load i8**,i8***%aa,align 8
store i8*null,i8**%c,align 8
%ac=load i8*,i8**%ab,align 8
%ad=call fastcc i8*%X(i8*inreg%Z,i8*inreg%ac)
store i8*%ad,i8**%c,align 8
%ae=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%af=getelementptr inbounds i8,i8*%ae,i64 16
%ag=bitcast i8*%af to i8*(i8*,i8*)**
%ah=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ag,align 8
%ai=bitcast i8*%ae to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%e,align 8
%ak=load i8*,i8**%d,align 8
%al=bitcast i8*%ak to i32*
%am=load i32,i32*%al,align 4
store i8*null,i8**%d,align 8
%an=getelementptr inbounds i8,i8*%ak,i64 4
%ao=bitcast i8*%an to i32*
%ap=load i32,i32*%ao,align 4
%aq=call i8*@sml_alloc(i32 inreg 20)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177296,i32*%as,align 4
store i8*%aq,i8**%d,align 8
%at=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%au=bitcast i8*%aq to i8**
store i8*%at,i8**%au,align 8
%av=getelementptr inbounds i8,i8*%aq,i64 8
%aw=bitcast i8*%av to i32*
store i32%am,i32*%aw,align 4
%ax=getelementptr inbounds i8,i8*%aq,i64 12
%ay=bitcast i8*%ax to i32*
store i32%ap,i32*%ay,align 4
%az=getelementptr inbounds i8,i8*%aq,i64 16
%aA=bitcast i8*%az to i32*
store i32 1,i32*%aA,align 4
%aB=call i8*@sml_alloc(i32 inreg 28)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32 1342177304,i32*%aD,align 4
%aE=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aF=bitcast i8*%aB to i8**
store i8*%aE,i8**%aF,align 8
%aG=getelementptr inbounds i8,i8*%aB,i64 8
%aH=bitcast i8*%aG to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3scc_43 to void(...)*),void(...)**%aH,align 8
%aI=getelementptr inbounds i8,i8*%aB,i64 16
%aJ=bitcast i8*%aI to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3scc_43 to void(...)*),void(...)**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aB,i64 24
%aL=bitcast i8*%aK to i32*
store i32 -2147483647,i32*%aL,align 4
%aM=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aN=call fastcc i8*%ah(i8*inreg%aM,i8*inreg%aB)
%aO=getelementptr inbounds i8,i8*%aN,i64 16
%aP=bitcast i8*%aO to i8*(i8*,i8*)**
%aQ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aP,align 8
%aR=bitcast i8*%aN to i8**
%aS=load i8*,i8**%aR,align 8
%aT=load i8*,i8**%c,align 8
%aU=tail call fastcc i8*%aQ(i8*inreg%aS,i8*inreg%aT)
ret i8*%aU
}
define internal fastcc i8*@_SMLL3scc_47(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
l:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%e,align 8
store i8*%b,i8**%d,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%j,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%e,align 8
br label%j
j:
%k=phi i8*[%i,%h],[%a,%l]
%m=bitcast i8*%k to i32*
%n=load i32,i32*%m,align 4
store i8*null,i8**%e,align 8
%o=getelementptr inbounds i8,i8*%k,i64 4
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%r)
call void@llvm.gcroot(i8**%c,i8*null)#0
%s=call i8*@sml_alloc(i32 inreg 12)#0
%t=bitcast i8*%s to i32*
%u=getelementptr inbounds i8,i8*%s,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177288,i32*%v,align 4
store i8*%s,i8**%c,align 8
store i32%n,i32*%t,align 4
%w=getelementptr inbounds i8,i8*%s,i64 4
%x=bitcast i8*%w to i32*
store i32%q,i32*%x,align 4
%y=getelementptr inbounds i8,i8*%s,i64 8
%z=bitcast i8*%y to i32*
store i32 0,i32*%z,align 4
%A=call i8*@sml_alloc(i32 inreg 28)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177304,i32*%C,align 4
%D=load i8*,i8**%c,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3scc_44 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3scc_44 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%r)
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=call fastcc i8*@_SMLL3scc_44(i8*inreg%D,i8*inreg%L)
ret i8*%M
}
define internal fastcc i8*@_SMLLN1__6SCCFunE_48(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d)#2 gc"smlsharp"{
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
store i8*%b,i8**%g,align 8
store i8*%c,i8**%f,align 8
store i8*%d,i8**%e,align 8
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
%A=load i8*,i8**%e,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7addNode_38 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7addNode_38 to void(...)*),void(...)**%Q,align 8
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
%ac=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ad=bitcast i8*%Z to i8**
store i8*%ac,i8**%ad,align 8
%ae=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7addEdge_39 to void(...)*),void(...)**%at,align 8
%au=getelementptr inbounds i8,i8*%an,i64 16
%av=bitcast i8*%au to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7addEdge_39 to void(...)*),void(...)**%av,align 8
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
%aF=load i8*,i8**%g,align 8
%aG=getelementptr inbounds i8,i8*%aF,i64 16
%aH=bitcast i8*%aG to i8*(i8*,i8*,i8*)**
%aI=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%aH,align 8
store i8*null,i8**%g,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3scc_47 to void(...)*),void(...)**%bq,align 8
%br=getelementptr inbounds i8,i8*%bk,i64 16
%bs=bitcast i8*%br to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3scc_47 to void(...)*),void(...)**%bs,align 8
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
define internal fastcc i8*@_SMLLN1__6SCCFunE_49(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLLN1__6SCCFunE_48 to void(...)*),void(...)**%w,align 8
%x=getelementptr inbounds i8,i8*%q,i64 16
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLLN1__6SCCFunE_48 to void(...)*),void(...)**%y,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN1__6SCCFunE_49 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN1__6SCCFunE_49 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLL7getElem_52(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLL7getElem_42(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLN1__6SCCFunE_54(i8*inreg%a,i8*inreg%b,i8*inreg%c)#4 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN1__6SCCFunE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
