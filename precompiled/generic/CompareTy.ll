@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLFN9CompareTy9compareTyE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9CompareTy9compareTyE_100 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[72x i8]}><{[4x i8]zeroinitializer,i32 -2147483576,[72x i8]c"src/compiler/compilePhases/typeinference/main/CompareTy.sml:77.21(2987)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[11x i8]}><{[4x i8]zeroinitializer,i32 -2147483637,[11x i8]c"impossible\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/typeinference/main/CompareTy.sml:63.8(2080)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[70x i8]}><{[4x i8]zeroinitializer,i32 -2147483578,[70x i8]c"src/compiler/compilePhases/typeinference/main/CompareTy.sml:20.6(547)\00"}>,align 8
@_SMLZN9CompareTy9compareTyE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SML_ftab7a8439dd5a792011_CompareTy=external global i8
@f=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN11RecordLabel3Map7collateE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN13FreeTypeVarID7compareE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN14BoundTypeVarID3Map3Key7compareE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN5Int327compareE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN5TypID3Map3Key7compareE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN9ExistTyID7compareE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main5148a836b3728be9_Int32()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maina142c315f12317c0_RecordLabel()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main22c101bff228a4a9_LocalID()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maincf2656e90c9ab770_ExistTyID()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load5148a836b3728be9_Int32(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loada142c315f12317c0_RecordLabel(i8*)local_unnamed_addr
declare void@_SML_load22c101bff228a4a9_LocalID(i8*)local_unnamed_addr
declare void@_SML_loadcf2656e90c9ab770_ExistTyID(i8*)local_unnamed_addr
define private void@_SML_tabb7a8439dd5a792011_CompareTy()#3{
unreachable
}
define void@_SML_load7a8439dd5a792011_CompareTy(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@f,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@f,align 1
tail call void@_SML_load5148a836b3728be9_Int32(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_loada142c315f12317c0_RecordLabel(i8*%a)#0
tail call void@_SML_load22c101bff228a4a9_LocalID(i8*%a)#0
tail call void@_SML_loadcf2656e90c9ab770_ExistTyID(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb7a8439dd5a792011_CompareTy,i8*@_SML_ftab7a8439dd5a792011_CompareTy,i8*null)#0
ret void
}
define void@_SML_main7a8439dd5a792011_CompareTy()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@f,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@f,align 1
tail call void@_SML_main5148a836b3728be9_Int32()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_maina142c315f12317c0_RecordLabel()#2
tail call void@_SML_main22c101bff228a4a9_LocalID()#2
tail call void@_SML_maincf2656e90c9ab770_ExistTyID()#2
br label%d
}
define fastcc i32@_SMLFN9CompareTy9compareTyE(i8*inreg%a)#2 gc"smlsharp"{
j:
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
%g=bitcast i8**%b to i8***
br label%h
h:
%i=phi i8*[%lt,%ls],[%a,%j]
store i8*%i,i8**%b,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
%m=bitcast i8*%i to i8**
br i1%l,label%p,label%n
n:
call void@sml_check(i32 inreg%k)
%o=load i8**,i8***%g,align 8
br label%p
p:
%q=phi i8**[%o,%n],[%m,%h]
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%c,align 8
%s=getelementptr inbounds i8*,i8**%q,i64 1
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%b,align 8
br label%u
u:
%v=phi i8*[%ao,%al],[%r,%p]
store i8*%v,i8**%d,align 8
%w=load atomic i32,i32*@sml_check_flag unordered,align 4
%x=icmp eq i32%w,0
br i1%x,label%A,label%y
y:
call void@sml_check(i32 inreg%w)
%z=load i8*,i8**%d,align 8
br label%A
A:
%B=phi i8*[%z,%y],[%v,%u]
%C=icmp eq i8*%B,null
br i1%C,label%ar,label%D
D:
%E=bitcast i8*%B to i32*
%F=load i32,i32*%E,align 4
switch i32%F,label%G[
i32 9,label%at
i32 0,label%as
i32 4,label%ar
i32 3,label%aq
i32 5,label%ap
i32 10,label%ad
i32 1,label%ac
i32 6,label%ab
i32 8,label%aa
i32 2,label%Z
i32 7,label%Y
]
G:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
call void@sml_matchcomp_bug()
%H=load i8*,i8**@_SMLZ5Match,align 8
store i8*%H,i8**%b,align 8
%I=call i8*@sml_alloc(i32 inreg 20)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177296,i32*%K,align 4
store i8*%I,i8**%c,align 8
%L=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[70x i8]}>,<{[4x i8],i32,[70x i8]}>*@e,i64 0,i32 2,i64 0),i8**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to i32*
store i32 3,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 60)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177336,i32*%T,align 4
%U=getelementptr inbounds i8,i8*%R,i64 56
%V=bitcast i8*%U to i32*
store i32 1,i32*%V,align 4
%W=load i8*,i8**%c,align 8
%X=bitcast i8*%R to i8**
store i8*%W,i8**%X,align 8
call void@sml_raise(i8*inreg%R)#1
unreachable
Y:
store i8*null,i8**%d,align 8
br label%au
Z:
store i8*null,i8**%d,align 8
br label%au
aa:
store i8*null,i8**%d,align 8
br label%au
ab:
store i8*null,i8**%d,align 8
br label%au
ac:
store i8*null,i8**%d,align 8
br label%au
ad:
store i8*null,i8**%d,align 8
%ae=getelementptr inbounds i8,i8*%B,i64 8
%af=bitcast i8*%ae to i8***
%ag=load i8**,i8***%af,align 8
%ah=load i8*,i8**%ag,align 8
%ai=bitcast i8*%ah to i32*
%aj=load i32,i32*%ai,align 4
%ak=icmp eq i32%aj,0
br i1%ak,label%al,label%au
al:
%am=getelementptr inbounds i8,i8*%ah,i64 8
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
br label%u
ap:
store i8*null,i8**%d,align 8
br label%au
aq:
store i8*null,i8**%d,align 8
br label%au
ar:
store i8*null,i8**%d,align 8
br label%au
as:
store i8*null,i8**%d,align 8
br label%au
at:
store i8*null,i8**%d,align 8
br label%au
au:
%av=phi i32[10,%Y],[9,%Z],[8,%aa],[7,%ab],[6,%ac],[4,%ap],[3,%aq],[2,%ar],[1,%as],[0,%at],[5,%ad]
br label%aw
aw:
%ax=phi i8**[%bg,%be],[%b,%au]
%ay=load i8*,i8**%ax,align 8
store i8*%ay,i8**%d,align 8
%az=load atomic i32,i32*@sml_check_flag unordered,align 4
%aA=icmp eq i32%az,0
br i1%aA,label%aD,label%aB
aB:
call void@sml_check(i32 inreg%az)
%aC=load i8*,i8**%d,align 8
br label%aD
aD:
%aE=phi i8*[%aC,%aB],[%ay,%aw]
%aF=icmp eq i8*%aE,null
br i1%aF,label%bj,label%aG
aG:
%aH=bitcast i8*%aE to i32*
%aI=load i32,i32*%aH,align 4
switch i32%aI,label%aJ[
i32 9,label%bl
i32 0,label%bk
i32 4,label%bj
i32 3,label%bi
i32 5,label%bh
i32 10,label%a6
i32 1,label%a5
i32 6,label%a4
i32 8,label%a3
i32 2,label%a2
i32 7,label%a1
]
aJ:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
call void@sml_matchcomp_bug()
%aK=load i8*,i8**@_SMLZ5Match,align 8
store i8*%aK,i8**%b,align 8
%aL=call i8*@sml_alloc(i32 inreg 20)#0
%aM=getelementptr inbounds i8,i8*%aL,i64 -4
%aN=bitcast i8*%aM to i32*
store i32 1342177296,i32*%aN,align 4
store i8*%aL,i8**%c,align 8
%aO=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aP=bitcast i8*%aL to i8**
store i8*%aO,i8**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aL,i64 8
%aR=bitcast i8*%aQ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[70x i8]}>,<{[4x i8],i32,[70x i8]}>*@e,i64 0,i32 2,i64 0),i8**%aR,align 8
%aS=getelementptr inbounds i8,i8*%aL,i64 16
%aT=bitcast i8*%aS to i32*
store i32 3,i32*%aT,align 4
%aU=call i8*@sml_alloc(i32 inreg 60)#0
%aV=getelementptr inbounds i8,i8*%aU,i64 -4
%aW=bitcast i8*%aV to i32*
store i32 1342177336,i32*%aW,align 4
%aX=getelementptr inbounds i8,i8*%aU,i64 56
%aY=bitcast i8*%aX to i32*
store i32 1,i32*%aY,align 4
%aZ=load i8*,i8**%c,align 8
%a0=bitcast i8*%aU to i8**
store i8*%aZ,i8**%a0,align 8
call void@sml_raise(i8*inreg%aU)#1
unreachable
a1:
store i8*null,i8**%d,align 8
br label%bm
a2:
store i8*null,i8**%d,align 8
br label%bm
a3:
store i8*null,i8**%d,align 8
br label%bm
a4:
store i8*null,i8**%d,align 8
br label%bm
a5:
store i8*null,i8**%d,align 8
br label%bm
a6:
store i8*null,i8**%d,align 8
%a7=getelementptr inbounds i8,i8*%aE,i64 8
%a8=bitcast i8*%a7 to i8***
%a9=load i8**,i8***%a8,align 8
%ba=load i8*,i8**%a9,align 8
%bb=bitcast i8*%ba to i32*
%bc=load i32,i32*%bb,align 4
%bd=icmp eq i32%bc,0
br i1%bd,label%be,label%bm
be:
%bf=getelementptr inbounds i8,i8*%ba,i64 8
%bg=bitcast i8*%bf to i8**
br label%aw
bh:
store i8*null,i8**%d,align 8
br label%bm
bi:
store i8*null,i8**%d,align 8
br label%bm
bj:
store i8*null,i8**%d,align 8
br label%bm
bk:
store i8*null,i8**%d,align 8
br label%bm
bl:
store i8*null,i8**%d,align 8
br label%bm
bm:
%bn=phi i32[10,%a1],[9,%a2],[8,%a3],[7,%a4],[6,%a5],[4,%bh],[3,%bi],[2,%bj],[1,%bk],[0,%bl],[5,%a6]
%bo=icmp eq i32%av,%bn
%bp=load i8*,i8**%c,align 8
br i1%bo,label%dh,label%bq
bq:
%br=phi i8*[%ca,%b7],[%bp,%bm]
store i8*%br,i8**%c,align 8
%bs=load atomic i32,i32*@sml_check_flag unordered,align 4
%bt=icmp eq i32%bs,0
br i1%bt,label%bw,label%bu
bu:
call void@sml_check(i32 inreg%bs)
%bv=load i8*,i8**%c,align 8
br label%bw
bw:
%bx=phi i8*[%bv,%bu],[%br,%bq]
%by=icmp eq i8*%bx,null
br i1%by,label%cd,label%bz
bz:
%bA=bitcast i8*%bx to i32*
%bB=load i32,i32*%bA,align 4
switch i32%bB,label%bC[
i32 9,label%cf
i32 0,label%ce
i32 4,label%cd
i32 3,label%cc
i32 5,label%cb
i32 10,label%bZ
i32 1,label%bY
i32 6,label%bX
i32 8,label%bW
i32 2,label%bV
i32 7,label%bU
]
bC:
store i8*null,i8**%c,align 8
call void@sml_matchcomp_bug()
%bD=load i8*,i8**@_SMLZ5Match,align 8
store i8*%bD,i8**%b,align 8
%bE=call i8*@sml_alloc(i32 inreg 20)#0
%bF=getelementptr inbounds i8,i8*%bE,i64 -4
%bG=bitcast i8*%bF to i32*
store i32 1342177296,i32*%bG,align 4
store i8*%bE,i8**%c,align 8
%bH=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bI=bitcast i8*%bE to i8**
store i8*%bH,i8**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bE,i64 8
%bK=bitcast i8*%bJ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[70x i8]}>,<{[4x i8],i32,[70x i8]}>*@e,i64 0,i32 2,i64 0),i8**%bK,align 8
%bL=getelementptr inbounds i8,i8*%bE,i64 16
%bM=bitcast i8*%bL to i32*
store i32 3,i32*%bM,align 4
%bN=call i8*@sml_alloc(i32 inreg 60)#0
%bO=getelementptr inbounds i8,i8*%bN,i64 -4
%bP=bitcast i8*%bO to i32*
store i32 1342177336,i32*%bP,align 4
%bQ=getelementptr inbounds i8,i8*%bN,i64 56
%bR=bitcast i8*%bQ to i32*
store i32 1,i32*%bR,align 4
%bS=load i8*,i8**%c,align 8
%bT=bitcast i8*%bN to i8**
store i8*%bS,i8**%bT,align 8
call void@sml_raise(i8*inreg%bN)#1
unreachable
bU:
store i8*null,i8**%c,align 8
br label%cg
bV:
store i8*null,i8**%c,align 8
br label%cg
bW:
store i8*null,i8**%c,align 8
br label%cg
bX:
store i8*null,i8**%c,align 8
br label%cg
bY:
store i8*null,i8**%c,align 8
br label%cg
bZ:
store i8*null,i8**%c,align 8
%b0=getelementptr inbounds i8,i8*%bx,i64 8
%b1=bitcast i8*%b0 to i8***
%b2=load i8**,i8***%b1,align 8
%b3=load i8*,i8**%b2,align 8
%b4=bitcast i8*%b3 to i32*
%b5=load i32,i32*%b4,align 4
%b6=icmp eq i32%b5,0
br i1%b6,label%b7,label%cg
b7:
%b8=getelementptr inbounds i8,i8*%b3,i64 8
%b9=bitcast i8*%b8 to i8**
%ca=load i8*,i8**%b9,align 8
br label%bq
cb:
store i8*null,i8**%c,align 8
br label%cg
cc:
store i8*null,i8**%c,align 8
br label%cg
cd:
store i8*null,i8**%c,align 8
br label%cg
ce:
store i8*null,i8**%c,align 8
br label%cg
cf:
store i8*null,i8**%c,align 8
br label%cg
cg:
%ch=phi i32[10,%bU],[9,%bV],[8,%bW],[7,%bX],[6,%bY],[4,%cb],[3,%cc],[2,%cd],[1,%ce],[0,%cf],[5,%bZ]
br label%ci
ci:
%cj=load atomic i32,i32*@sml_check_flag unordered,align 4
%ck=icmp eq i32%cj,0
br i1%ck,label%cm,label%cl
cl:
call void@sml_check(i32 inreg%cj)
br label%cm
cm:
%cn=load i8*,i8**%b,align 8
%co=icmp eq i8*%cn,null
br i1%co,label%c3,label%cp
cp:
%cq=bitcast i8*%cn to i32*
%cr=load i32,i32*%cq,align 4
switch i32%cr,label%cs[
i32 9,label%c5
i32 0,label%c4
i32 4,label%c3
i32 3,label%c2
i32 5,label%c1
i32 10,label%cP
i32 1,label%cO
i32 6,label%cN
i32 8,label%cM
i32 2,label%cL
i32 7,label%cK
]
cs:
call void@sml_matchcomp_bug()
%ct=load i8*,i8**@_SMLZ5Match,align 8
store i8*%ct,i8**%b,align 8
%cu=call i8*@sml_alloc(i32 inreg 20)#0
%cv=getelementptr inbounds i8,i8*%cu,i64 -4
%cw=bitcast i8*%cv to i32*
store i32 1342177296,i32*%cw,align 4
store i8*%cu,i8**%c,align 8
%cx=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cy=bitcast i8*%cu to i8**
store i8*%cx,i8**%cy,align 8
%cz=getelementptr inbounds i8,i8*%cu,i64 8
%cA=bitcast i8*%cz to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[70x i8]}>,<{[4x i8],i32,[70x i8]}>*@e,i64 0,i32 2,i64 0),i8**%cA,align 8
%cB=getelementptr inbounds i8,i8*%cu,i64 16
%cC=bitcast i8*%cB to i32*
store i32 3,i32*%cC,align 4
%cD=call i8*@sml_alloc(i32 inreg 60)#0
%cE=getelementptr inbounds i8,i8*%cD,i64 -4
%cF=bitcast i8*%cE to i32*
store i32 1342177336,i32*%cF,align 4
%cG=getelementptr inbounds i8,i8*%cD,i64 56
%cH=bitcast i8*%cG to i32*
store i32 1,i32*%cH,align 4
%cI=load i8*,i8**%c,align 8
%cJ=bitcast i8*%cD to i8**
store i8*%cI,i8**%cJ,align 8
call void@sml_raise(i8*inreg%cD)#1
unreachable
cK:
store i8*null,i8**%b,align 8
br label%c6
cL:
store i8*null,i8**%b,align 8
br label%c6
cM:
store i8*null,i8**%b,align 8
br label%c6
cN:
store i8*null,i8**%b,align 8
br label%c6
cO:
store i8*null,i8**%b,align 8
br label%c6
cP:
store i8*null,i8**%b,align 8
%cQ=getelementptr inbounds i8,i8*%cn,i64 8
%cR=bitcast i8*%cQ to i8***
%cS=load i8**,i8***%cR,align 8
%cT=load i8*,i8**%cS,align 8
%cU=bitcast i8*%cT to i32*
%cV=load i32,i32*%cU,align 4
%cW=icmp eq i32%cV,0
br i1%cW,label%cX,label%c6
cX:
%cY=getelementptr inbounds i8,i8*%cT,i64 8
%cZ=bitcast i8*%cY to i8**
%c0=load i8*,i8**%cZ,align 8
store i8*%c0,i8**%b,align 8
br label%ci
c1:
store i8*null,i8**%b,align 8
br label%c6
c2:
store i8*null,i8**%b,align 8
br label%c6
c3:
store i8*null,i8**%b,align 8
br label%c6
c4:
store i8*null,i8**%b,align 8
br label%c6
c5:
store i8*null,i8**%b,align 8
br label%c6
c6:
%c7=phi i32[10,%cK],[9,%cL],[8,%cM],[7,%cN],[6,%cO],[4,%c1],[3,%c2],[2,%c3],[1,%c4],[0,%c5],[5,%cP]
%c8=call i8*@sml_alloc(i32 inreg 12)#0
%c9=bitcast i8*%c8 to i32*
%da=getelementptr inbounds i8,i8*%c8,i64 -4
%db=bitcast i8*%da to i32*
store i32 1342177288,i32*%db,align 4
store i32%ch,i32*%c9,align 4
%dc=getelementptr inbounds i8,i8*%c8,i64 4
%dd=bitcast i8*%dc to i32*
store i32%c7,i32*%dd,align 4
%de=getelementptr inbounds i8,i8*%c8,i64 8
%df=bitcast i8*%de to i32*
store i32 0,i32*%df,align 4
%dg=tail call fastcc i32@_SMLFN5Int327compareE(i8*inreg%c8)
ret i32%dg
dh:
%di=icmp eq i8*%bp,null
br i1%di,label%dm,label%dj
dj:
%dk=bitcast i8*%bp to i32*
%dl=load i32,i32*%dk,align 4
switch i32%dl,label%dm[
i32 5,label%kq
i32 10,label%iZ
i32 1,label%ip
i32 6,label%gt
i32 8,label%fC
i32 2,label%dH
]
dm:
%dn=load i8*,i8**%b,align 8
%do=icmp eq i8*%dn,null
br i1%do,label%dt,label%dp
dp:
%dq=bitcast i8*%dn to i32*
%dr=load i32,i32*%dq,align 4
%ds=icmp eq i32%dr,10
br i1%ds,label%du,label%dt
dt:
store i8*null,i8**%c,align 8
br label%k2
du:
store i8*null,i8**%b,align 8
%dv=getelementptr inbounds i8,i8*%dn,i64 8
%dw=bitcast i8*%dv to i8***
%dx=load i8**,i8***%dw,align 8
%dy=load i8*,i8**%dx,align 8
%dz=bitcast i8*%dy to i32*
%dA=load i32,i32*%dz,align 4
%dB=icmp eq i32%dA,0
br i1%dB,label%dD,label%dC
dC:
store i8*null,i8**%c,align 8
br label%k2
dD:
%dE=getelementptr inbounds i8,i8*%dy,i64 8
%dF=bitcast i8*%dE to i8**
%dG=load i8*,i8**%dF,align 8
store i8*%dG,i8**%b,align 8
br label%lm
dH:
%dI=getelementptr inbounds i8,i8*%bp,i64 8
%dJ=bitcast i8*%dI to i8**
%dK=load i8*,i8**%dJ,align 8
%dL=bitcast i8*%dK to i8**
%dM=load i8*,i8**%dL,align 8
store i8*%dM,i8**%d,align 8
%dN=load i8*,i8**%b,align 8
%dO=icmp eq i8*%dN,null
br i1%dO,label%dS,label%dP
dP:
%dQ=bitcast i8*%dN to i32*
%dR=load i32,i32*%dQ,align 4
switch i32%dR,label%dS[
i32 10,label%fp
i32 2,label%dT
]
dS:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
br label%k2
dT:
%dU=getelementptr inbounds i8,i8*%dK,i64 8
%dV=bitcast i8*%dU to i8**
%dW=load i8*,i8**%dV,align 8
%dX=getelementptr inbounds i8,i8*%dW,i64 40
%dY=bitcast i8*%dX to i32*
%dZ=load i32,i32*%dY,align 4
store i8*null,i8**%c,align 8
%d0=getelementptr inbounds i8,i8*%dN,i64 8
%d1=bitcast i8*%d0 to i8**
%d2=load i8*,i8**%d1,align 8
%d3=bitcast i8*%d2 to i8**
%d4=load i8*,i8**%d3,align 8
store i8*%d4,i8**%b,align 8
%d5=getelementptr inbounds i8,i8*%d2,i64 8
%d6=bitcast i8*%d5 to i8**
%d7=load i8*,i8**%d6,align 8
%d8=getelementptr inbounds i8,i8*%d7,i64 40
%d9=bitcast i8*%d8 to i32*
%ea=load i32,i32*%d9,align 4
%eb=call i8*@sml_alloc(i32 inreg 12)#0
%ec=bitcast i8*%eb to i32*
%ed=getelementptr inbounds i8,i8*%eb,i64 -4
%ee=bitcast i8*%ed to i32*
store i32 1342177288,i32*%ee,align 4
store i32%dZ,i32*%ec,align 4
%ef=getelementptr inbounds i8,i8*%eb,i64 4
%eg=bitcast i8*%ef to i32*
store i32%ea,i32*%eg,align 4
%eh=getelementptr inbounds i8,i8*%eb,i64 8
%ei=bitcast i8*%eh to i32*
store i32 0,i32*%ei,align 4
%ej=call fastcc i32@_SMLFN5TypID3Map3Key7compareE(i8*inreg%eb)
%ek=icmp eq i32%ej,0
br i1%ek,label%en,label%el
el:
%em=phi i32[%ej,%dT],[%eP,%eK],[%hC,%hx],[%h3,%hN],[1,%hD],[%fg,%e0],[1,%eQ]
ret i32%em
en:
%eo=call i8*@sml_alloc(i32 inreg 20)#0
%ep=getelementptr inbounds i8,i8*%eo,i64 -4
%eq=bitcast i8*%ep to i32*
store i32 1342177296,i32*%eq,align 4
%er=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%es=bitcast i8*%eo to i8**
store i8*%er,i8**%es,align 8
%et=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
br label%eu
eu:
%ev=phi i8*[%fj,%fi],[%eo,%en]
%ew=phi i8*[%fo,%fi],[%et,%en]
%ex=getelementptr inbounds i8,i8*%ev,i64 8
%ey=bitcast i8*%ex to i8**
store i8*%ew,i8**%ey,align 8
%ez=getelementptr inbounds i8,i8*%ev,i64 16
%eA=bitcast i8*%ez to i32*
store i32 3,i32*%eA,align 4
store i8*%ev,i8**%b,align 8
%eB=load atomic i32,i32*@sml_check_flag unordered,align 4
%eC=icmp eq i32%eB,0
br i1%eC,label%eF,label%eD
eD:
call void@sml_check(i32 inreg%eB)
%eE=load i8*,i8**%b,align 8
br label%eF
eF:
%eG=phi i8*[%eE,%eD],[%ev,%eu]
%eH=bitcast i8*%eG to i8**
%eI=load i8*,i8**%eH,align 8
%eJ=icmp eq i8*%eI,null
br i1%eJ,label%eK,label%eQ
eK:
%eL=getelementptr inbounds i8,i8*%eG,i64 8
%eM=bitcast i8*%eL to i8**
%eN=load i8*,i8**%eM,align 8
%eO=icmp eq i8*%eN,null
%eP=select i1%eO,i32 0,i32 2
br label%el
eQ:
%eR=bitcast i8*%eI to i8**
%eS=load i8*,i8**%eR,align 8
store i8*%eS,i8**%c,align 8
%eT=getelementptr inbounds i8,i8*%eI,i64 8
%eU=bitcast i8*%eT to i8**
%eV=load i8*,i8**%eU,align 8
store i8*%eV,i8**%d,align 8
%eW=getelementptr inbounds i8,i8*%eG,i64 8
%eX=bitcast i8*%eW to i8**
%eY=load i8*,i8**%eX,align 8
%eZ=icmp eq i8*%eY,null
br i1%eZ,label%el,label%e0
e0:
%e1=bitcast i8*%eY to i8**
%e2=load i8*,i8**%e1,align 8
store i8*%e2,i8**%b,align 8
%e3=getelementptr inbounds i8,i8*%eY,i64 8
%e4=bitcast i8*%e3 to i8**
%e5=load i8*,i8**%e4,align 8
store i8*%e5,i8**%e,align 8
%e6=call i8*@sml_alloc(i32 inreg 20)#0
%e7=getelementptr inbounds i8,i8*%e6,i64 -4
%e8=bitcast i8*%e7 to i32*
store i32 1342177296,i32*%e8,align 4
%e9=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fa=bitcast i8*%e6 to i8**
store i8*%e9,i8**%fa,align 8
%fb=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%fc=getelementptr inbounds i8,i8*%e6,i64 8
%fd=bitcast i8*%fc to i8**
store i8*%fb,i8**%fd,align 8
%fe=getelementptr inbounds i8,i8*%e6,i64 16
%ff=bitcast i8*%fe to i32*
store i32 3,i32*%ff,align 4
%fg=call fastcc i32@_SMLFN9CompareTy9compareTyE(i8*inreg%e6)
%fh=icmp eq i32%fg,0
br i1%fh,label%fi,label%el
fi:
%fj=call i8*@sml_alloc(i32 inreg 20)#0
%fk=getelementptr inbounds i8,i8*%fj,i64 -4
%fl=bitcast i8*%fk to i32*
store i32 1342177296,i32*%fl,align 4
%fm=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fn=bitcast i8*%fj to i8**
store i8*%fm,i8**%fn,align 8
%fo=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
br label%eu
fp:
store i8*null,i8**%d,align 8
store i8*null,i8**%b,align 8
%fq=getelementptr inbounds i8,i8*%dN,i64 8
%fr=bitcast i8*%fq to i8***
%fs=load i8**,i8***%fr,align 8
%ft=load i8*,i8**%fs,align 8
%fu=bitcast i8*%ft to i32*
%fv=load i32,i32*%fu,align 4
%fw=icmp eq i32%fv,0
br i1%fw,label%fy,label%fx
fx:
store i8*null,i8**%c,align 8
br label%k2
fy:
%fz=getelementptr inbounds i8,i8*%ft,i64 8
%fA=bitcast i8*%fz to i8**
%fB=load i8*,i8**%fA,align 8
store i8*%fB,i8**%b,align 8
br label%lm
fC:
%fD=getelementptr inbounds i8,i8*%bp,i64 8
%fE=bitcast i8*%fD to i8**
%fF=load i8*,i8**%fE,align 8
store i8*%fF,i8**%d,align 8
%fG=load i8*,i8**%b,align 8
%fH=icmp eq i8*%fG,null
br i1%fH,label%fL,label%fI
fI:
%fJ=bitcast i8*%fG to i32*
%fK=load i32,i32*%fJ,align 4
switch i32%fK,label%fL[
i32 10,label%gg
i32 8,label%fM
]
fL:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
br label%k2
fM:
store i8*null,i8**%c,align 8
%fN=getelementptr inbounds i8,i8*%fG,i64 8
%fO=bitcast i8*%fN to i8**
%fP=load i8*,i8**%fO,align 8
store i8*%fP,i8**%b,align 8
%fQ=call fastcc i8*@_SMLFN11RecordLabel3Map7collateE(i32 inreg 1,i32 inreg 8)
%fR=getelementptr inbounds i8,i8*%fQ,i64 16
%fS=bitcast i8*%fR to i8*(i8*,i8*)**
%fT=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fS,align 8
%fU=bitcast i8*%fQ to i8**
%fV=load i8*,i8**%fU,align 8
%fW=call fastcc i8*%fT(i8*inreg%fV,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%fX=getelementptr inbounds i8,i8*%fW,i64 16
%fY=bitcast i8*%fX to i8*(i8*,i8*)**
%fZ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fY,align 8
%f0=bitcast i8*%fW to i8**
%f1=load i8*,i8**%f0,align 8
store i8*%f1,i8**%c,align 8
%f2=call i8*@sml_alloc(i32 inreg 20)#0
%f3=getelementptr inbounds i8,i8*%f2,i64 -4
%f4=bitcast i8*%f3 to i32*
store i32 1342177296,i32*%f4,align 4
%f5=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%f6=bitcast i8*%f2 to i8**
store i8*%f5,i8**%f6,align 8
%f7=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%f8=getelementptr inbounds i8,i8*%f2,i64 8
%f9=bitcast i8*%f8 to i8**
store i8*%f7,i8**%f9,align 8
%ga=getelementptr inbounds i8,i8*%f2,i64 16
%gb=bitcast i8*%ga to i32*
store i32 3,i32*%gb,align 4
%gc=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%gd=call fastcc i8*%fZ(i8*inreg%gc,i8*inreg%f2)
%ge=bitcast i8*%gd to i32*
%gf=load i32,i32*%ge,align 4
ret i32%gf
gg:
store i8*null,i8**%d,align 8
store i8*null,i8**%b,align 8
%gh=getelementptr inbounds i8,i8*%fG,i64 8
%gi=bitcast i8*%gh to i8***
%gj=load i8**,i8***%gi,align 8
%gk=load i8*,i8**%gj,align 8
%gl=bitcast i8*%gk to i32*
%gm=load i32,i32*%gl,align 4
%gn=icmp eq i32%gm,0
br i1%gn,label%gp,label%go
go:
store i8*null,i8**%c,align 8
br label%k2
gp:
%gq=getelementptr inbounds i8,i8*%gk,i64 8
%gr=bitcast i8*%gq to i8**
%gs=load i8*,i8**%gr,align 8
store i8*%gs,i8**%b,align 8
br label%lm
gt:
%gu=getelementptr inbounds i8,i8*%bp,i64 8
%gv=bitcast i8*%gu to i8**
%gw=load i8*,i8**%gv,align 8
%gx=bitcast i8*%gw to i8**
%gy=load i8*,i8**%gx,align 8
store i8*%gy,i8**%d,align 8
%gz=getelementptr inbounds i8,i8*%gw,i64 8
%gA=bitcast i8*%gz to i8**
%gB=load i8*,i8**%gA,align 8
store i8*%gB,i8**%e,align 8
%gC=load i8*,i8**%b,align 8
%gD=icmp eq i8*%gC,null
br i1%gD,label%gH,label%gE
gE:
%gF=bitcast i8*%gC to i32*
%gG=load i32,i32*%gF,align 4
switch i32%gG,label%gH[
i32 10,label%ic
i32 6,label%gI
]
gH:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
br label%k2
gI:
%gJ=getelementptr inbounds i8,i8*%gC,i64 8
%gK=bitcast i8*%gJ to i8**
%gL=load i8*,i8**%gK,align 8
%gM=bitcast i8*%gL to i8**
%gN=load i8*,i8**%gM,align 8
store i8*%gN,i8**%b,align 8
%gO=getelementptr inbounds i8,i8*%gL,i64 8
%gP=bitcast i8*%gO to i8**
%gQ=load i8*,i8**%gP,align 8
store i8*%gQ,i8**%c,align 8
%gR=call i8*@sml_alloc(i32 inreg 20)#0
%gS=getelementptr inbounds i8,i8*%gR,i64 -4
%gT=bitcast i8*%gS to i32*
store i32 1342177296,i32*%gT,align 4
store i8*%gR,i8**%f,align 8
%gU=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%gV=bitcast i8*%gR to i8**
store i8*%gU,i8**%gV,align 8
%gW=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%gX=getelementptr inbounds i8,i8*%gR,i64 8
%gY=bitcast i8*%gX to i8**
store i8*%gW,i8**%gY,align 8
%gZ=getelementptr inbounds i8,i8*%gR,i64 16
%g0=bitcast i8*%gZ to i32*
store i32 3,i32*%g0,align 4
%g1=call i8*@sml_alloc(i32 inreg 20)#0
%g2=getelementptr inbounds i8,i8*%g1,i64 -4
%g3=bitcast i8*%g2 to i32*
store i32 1342177296,i32*%g3,align 4
store i8*%g1,i8**%d,align 8
%g4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%g5=bitcast i8*%g1 to i8**
store i8*%g4,i8**%g5,align 8
%g6=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%g7=getelementptr inbounds i8,i8*%g1,i64 8
%g8=bitcast i8*%g7 to i8**
store i8*%g6,i8**%g8,align 8
%g9=getelementptr inbounds i8,i8*%g1,i64 16
%ha=bitcast i8*%g9 to i32*
store i32 3,i32*%ha,align 4
%hb=call i8*@sml_alloc(i32 inreg 20)#0
%hc=getelementptr inbounds i8,i8*%hb,i64 -4
%hd=bitcast i8*%hc to i32*
store i32 1342177296,i32*%hd,align 4
%he=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%hf=bitcast i8*%hb to i8**
store i8*%he,i8**%hf,align 8
%hg=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
br label%hh
hh:
%hi=phi i8*[%h6,%h5],[%hb,%gI]
%hj=phi i8*[%ib,%h5],[%hg,%gI]
%hk=getelementptr inbounds i8,i8*%hi,i64 8
%hl=bitcast i8*%hk to i8**
store i8*%hj,i8**%hl,align 8
%hm=getelementptr inbounds i8,i8*%hi,i64 16
%hn=bitcast i8*%hm to i32*
store i32 3,i32*%hn,align 4
store i8*%hi,i8**%b,align 8
%ho=load atomic i32,i32*@sml_check_flag unordered,align 4
%hp=icmp eq i32%ho,0
br i1%hp,label%hs,label%hq
hq:
call void@sml_check(i32 inreg%ho)
%hr=load i8*,i8**%b,align 8
br label%hs
hs:
%ht=phi i8*[%hr,%hq],[%hi,%hh]
%hu=bitcast i8*%ht to i8**
%hv=load i8*,i8**%hu,align 8
%hw=icmp eq i8*%hv,null
br i1%hw,label%hx,label%hD
hx:
%hy=getelementptr inbounds i8,i8*%ht,i64 8
%hz=bitcast i8*%hy to i8**
%hA=load i8*,i8**%hz,align 8
%hB=icmp eq i8*%hA,null
%hC=select i1%hB,i32 0,i32 2
br label%el
hD:
%hE=bitcast i8*%hv to i8**
%hF=load i8*,i8**%hE,align 8
store i8*%hF,i8**%c,align 8
%hG=getelementptr inbounds i8,i8*%hv,i64 8
%hH=bitcast i8*%hG to i8**
%hI=load i8*,i8**%hH,align 8
store i8*%hI,i8**%d,align 8
%hJ=getelementptr inbounds i8,i8*%ht,i64 8
%hK=bitcast i8*%hJ to i8**
%hL=load i8*,i8**%hK,align 8
%hM=icmp eq i8*%hL,null
br i1%hM,label%el,label%hN
hN:
%hO=bitcast i8*%hL to i8**
%hP=load i8*,i8**%hO,align 8
store i8*%hP,i8**%b,align 8
%hQ=getelementptr inbounds i8,i8*%hL,i64 8
%hR=bitcast i8*%hQ to i8**
%hS=load i8*,i8**%hR,align 8
store i8*%hS,i8**%e,align 8
%hT=call i8*@sml_alloc(i32 inreg 20)#0
%hU=getelementptr inbounds i8,i8*%hT,i64 -4
%hV=bitcast i8*%hU to i32*
store i32 1342177296,i32*%hV,align 4
%hW=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%hX=bitcast i8*%hT to i8**
store i8*%hW,i8**%hX,align 8
%hY=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%hZ=getelementptr inbounds i8,i8*%hT,i64 8
%h0=bitcast i8*%hZ to i8**
store i8*%hY,i8**%h0,align 8
%h1=getelementptr inbounds i8,i8*%hT,i64 16
%h2=bitcast i8*%h1 to i32*
store i32 3,i32*%h2,align 4
%h3=call fastcc i32@_SMLFN9CompareTy9compareTyE(i8*inreg%hT)
%h4=icmp eq i32%h3,0
br i1%h4,label%h5,label%el
h5:
%h6=call i8*@sml_alloc(i32 inreg 20)#0
%h7=getelementptr inbounds i8,i8*%h6,i64 -4
%h8=bitcast i8*%h7 to i32*
store i32 1342177296,i32*%h8,align 4
%h9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ia=bitcast i8*%h6 to i8**
store i8*%h9,i8**%ia,align 8
%ib=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
br label%hh
ic:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%b,align 8
%id=getelementptr inbounds i8,i8*%gC,i64 8
%ie=bitcast i8*%id to i8***
%if=load i8**,i8***%ie,align 8
%ig=load i8*,i8**%if,align 8
%ih=bitcast i8*%ig to i32*
%ii=load i32,i32*%ih,align 4
%ij=icmp eq i32%ii,0
br i1%ij,label%il,label%ik
ik:
store i8*null,i8**%c,align 8
br label%k2
il:
%im=getelementptr inbounds i8,i8*%ig,i64 8
%in=bitcast i8*%im to i8**
%io=load i8*,i8**%in,align 8
store i8*%io,i8**%b,align 8
br label%lm
ip:
%iq=load i8*,i8**%b,align 8
%ir=icmp eq i8*%iq,null
br i1%ir,label%iv,label%is
is:
%it=bitcast i8*%iq to i32*
%iu=load i32,i32*%it,align 4
switch i32%iu,label%iv[
i32 10,label%iM
i32 1,label%iw
]
iv:
store i8*null,i8**%c,align 8
br label%k2
iw:
%ix=getelementptr inbounds i8,i8*%bp,i64 4
%iy=bitcast i8*%ix to i32*
%iz=load i32,i32*%iy,align 4
store i8*null,i8**%c,align 8
store i8*null,i8**%b,align 8
%iA=getelementptr inbounds i8,i8*%iq,i64 4
%iB=bitcast i8*%iA to i32*
%iC=load i32,i32*%iB,align 4
%iD=call i8*@sml_alloc(i32 inreg 12)#0
%iE=bitcast i8*%iD to i32*
%iF=getelementptr inbounds i8,i8*%iD,i64 -4
%iG=bitcast i8*%iF to i32*
store i32 1342177288,i32*%iG,align 4
store i32%iz,i32*%iE,align 4
%iH=getelementptr inbounds i8,i8*%iD,i64 4
%iI=bitcast i8*%iH to i32*
store i32%iC,i32*%iI,align 4
%iJ=getelementptr inbounds i8,i8*%iD,i64 8
%iK=bitcast i8*%iJ to i32*
store i32 0,i32*%iK,align 4
%iL=tail call fastcc i32@_SMLFN14BoundTypeVarID3Map3Key7compareE(i8*inreg%iD)
ret i32%iL
iM:
store i8*null,i8**%b,align 8
%iN=getelementptr inbounds i8,i8*%iq,i64 8
%iO=bitcast i8*%iN to i8***
%iP=load i8**,i8***%iO,align 8
%iQ=load i8*,i8**%iP,align 8
%iR=bitcast i8*%iQ to i32*
%iS=load i32,i32*%iR,align 4
%iT=icmp eq i32%iS,0
br i1%iT,label%iV,label%iU
iU:
store i8*null,i8**%c,align 8
br label%k2
iV:
%iW=getelementptr inbounds i8,i8*%iQ,i64 8
%iX=bitcast i8*%iW to i8**
%iY=load i8*,i8**%iX,align 8
store i8*%iY,i8**%b,align 8
br label%lm
iZ:
%i0=getelementptr inbounds i8,i8*%bp,i64 8
%i1=bitcast i8*%i0 to i8***
%i2=load i8**,i8***%i1,align 8
%i3=load i8*,i8**%i2,align 8
%i4=bitcast i8*%i3 to i32*
%i5=load i32,i32*%i4,align 4
switch i32%i5,label%i6[
i32 1,label%jx
i32 0,label%jo
]
i6:
store i8*null,i8**%c,align 8
call void@sml_matchcomp_bug()
%i7=load i8*,i8**@_SMLZ5Match,align 8
store i8*%i7,i8**%b,align 8
%i8=call i8*@sml_alloc(i32 inreg 20)#0
%i9=getelementptr inbounds i8,i8*%i8,i64 -4
%ja=bitcast i8*%i9 to i32*
store i32 1342177296,i32*%ja,align 4
store i8*%i8,i8**%c,align 8
%jb=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%jc=bitcast i8*%i8 to i8**
store i8*%jb,i8**%jc,align 8
%jd=getelementptr inbounds i8,i8*%i8,i64 8
%je=bitcast i8*%jd to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@d,i64 0,i32 2,i64 0),i8**%je,align 8
%jf=getelementptr inbounds i8,i8*%i8,i64 16
%jg=bitcast i8*%jf to i32*
store i32 3,i32*%jg,align 4
%jh=call i8*@sml_alloc(i32 inreg 60)#0
%ji=getelementptr inbounds i8,i8*%jh,i64 -4
%jj=bitcast i8*%ji to i32*
store i32 1342177336,i32*%jj,align 4
%jk=getelementptr inbounds i8,i8*%jh,i64 56
%jl=bitcast i8*%jk to i32*
store i32 1,i32*%jl,align 4
%jm=load i8*,i8**%c,align 8
%jn=bitcast i8*%jh to i8**
store i8*%jm,i8**%jn,align 8
call void@sml_raise(i8*inreg%jh)#1
unreachable
jo:
%jp=getelementptr inbounds i8,i8*%i3,i64 8
%jq=bitcast i8*%jp to i8**
%jr=load i8*,i8**%jq,align 8
store i8*%jr,i8**%c,align 8
%js=call i8*@sml_alloc(i32 inreg 20)#0
%jt=getelementptr inbounds i8,i8*%js,i64 -4
%ju=bitcast i8*%jt to i32*
store i32 1342177296,i32*%ju,align 4
%jv=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%jw=bitcast i8*%js to i8**
store i8*%jv,i8**%jw,align 8
br label%ls
jx:
%jy=getelementptr inbounds i8,i8*%i3,i64 8
%jz=bitcast i8*%jy to i32**
%jA=load i32*,i32**%jz,align 8
%jB=load i32,i32*%jA,align 4
%jC=load i8*,i8**%b,align 8
%jD=icmp eq i8*%jC,null
br i1%jD,label%jI,label%jE
jE:
%jF=bitcast i8*%jC to i32*
%jG=load i32,i32*%jF,align 4
%jH=icmp eq i32%jG,10
br i1%jH,label%jJ,label%jI
jI:
store i8*null,i8**%c,align 8
br label%k2
jJ:
store i8*null,i8**%b,align 8
%jK=getelementptr inbounds i8,i8*%jC,i64 8
%jL=bitcast i8*%jK to i8***
%jM=load i8**,i8***%jL,align 8
%jN=load i8*,i8**%jM,align 8
%jO=bitcast i8*%jN to i32*
%jP=load i32,i32*%jO,align 4
switch i32%jP,label%jQ[
i32 1,label%kc
i32 0,label%j8
]
jQ:
store i8*null,i8**%c,align 8
call void@sml_matchcomp_bug()
%jR=load i8*,i8**@_SMLZ5Match,align 8
store i8*%jR,i8**%b,align 8
%jS=call i8*@sml_alloc(i32 inreg 20)#0
%jT=getelementptr inbounds i8,i8*%jS,i64 -4
%jU=bitcast i8*%jT to i32*
store i32 1342177296,i32*%jU,align 4
store i8*%jS,i8**%c,align 8
%jV=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%jW=bitcast i8*%jS to i8**
store i8*%jV,i8**%jW,align 8
%jX=getelementptr inbounds i8,i8*%jS,i64 8
%jY=bitcast i8*%jX to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@d,i64 0,i32 2,i64 0),i8**%jY,align 8
%jZ=getelementptr inbounds i8,i8*%jS,i64 16
%j0=bitcast i8*%jZ to i32*
store i32 3,i32*%j0,align 4
%j1=call i8*@sml_alloc(i32 inreg 60)#0
%j2=getelementptr inbounds i8,i8*%j1,i64 -4
%j3=bitcast i8*%j2 to i32*
store i32 1342177336,i32*%j3,align 4
%j4=getelementptr inbounds i8,i8*%j1,i64 56
%j5=bitcast i8*%j4 to i32*
store i32 1,i32*%j5,align 4
%j6=load i8*,i8**%c,align 8
%j7=bitcast i8*%j1 to i8**
store i8*%j6,i8**%j7,align 8
call void@sml_raise(i8*inreg%j1)#1
unreachable
j8:
%j9=getelementptr inbounds i8,i8*%jN,i64 8
%ka=bitcast i8*%j9 to i8**
%kb=load i8*,i8**%ka,align 8
store i8*%kb,i8**%b,align 8
br label%lm
kc:
store i8*null,i8**%c,align 8
%kd=getelementptr inbounds i8,i8*%jN,i64 8
%ke=bitcast i8*%kd to i32**
%kf=load i32*,i32**%ke,align 8
%kg=load i32,i32*%kf,align 4
%kh=call i8*@sml_alloc(i32 inreg 12)#0
%ki=bitcast i8*%kh to i32*
%kj=getelementptr inbounds i8,i8*%kh,i64 -4
%kk=bitcast i8*%kj to i32*
store i32 1342177288,i32*%kk,align 4
store i32%jB,i32*%ki,align 4
%kl=getelementptr inbounds i8,i8*%kh,i64 4
%km=bitcast i8*%kl to i32*
store i32%kg,i32*%km,align 4
%kn=getelementptr inbounds i8,i8*%kh,i64 8
%ko=bitcast i8*%kn to i32*
store i32 0,i32*%ko,align 4
%kp=tail call fastcc i32@_SMLFN13FreeTypeVarID7compareE(i8*inreg%kh)
ret i32%kp
kq:
%kr=load i8*,i8**%b,align 8
%ks=icmp eq i8*%kr,null
br i1%ks,label%kw,label%kt
kt:
%ku=bitcast i8*%kr to i32*
%kv=load i32,i32*%ku,align 4
switch i32%kv,label%kw[
i32 5,label%kK
i32 10,label%kx
]
kw:
store i8*null,i8**%c,align 8
br label%k2
kx:
store i8*null,i8**%b,align 8
%ky=getelementptr inbounds i8,i8*%kr,i64 8
%kz=bitcast i8*%ky to i8***
%kA=load i8**,i8***%kz,align 8
%kB=load i8*,i8**%kA,align 8
%kC=bitcast i8*%kB to i32*
%kD=load i32,i32*%kC,align 4
%kE=icmp eq i32%kD,0
br i1%kE,label%kG,label%kF
kF:
store i8*null,i8**%c,align 8
br label%k2
kG:
%kH=getelementptr inbounds i8,i8*%kB,i64 8
%kI=bitcast i8*%kH to i8**
%kJ=load i8*,i8**%kI,align 8
store i8*%kJ,i8**%b,align 8
br label%lm
kK:
%kL=getelementptr inbounds i8,i8*%bp,i64 8
%kM=bitcast i8*%kL to i32**
%kN=load i32*,i32**%kM,align 8
%kO=load i32,i32*%kN,align 4
store i8*null,i8**%c,align 8
store i8*null,i8**%b,align 8
%kP=getelementptr inbounds i8,i8*%kr,i64 8
%kQ=bitcast i8*%kP to i32**
%kR=load i32*,i32**%kQ,align 8
%kS=load i32,i32*%kR,align 4
%kT=call i8*@sml_alloc(i32 inreg 12)#0
%kU=bitcast i8*%kT to i32*
%kV=getelementptr inbounds i8,i8*%kT,i64 -4
%kW=bitcast i8*%kV to i32*
store i32 1342177288,i32*%kW,align 4
store i32%kO,i32*%kU,align 4
%kX=getelementptr inbounds i8,i8*%kT,i64 4
%kY=bitcast i8*%kX to i32*
store i32%kS,i32*%kY,align 4
%kZ=getelementptr inbounds i8,i8*%kT,i64 8
%k0=bitcast i8*%kZ to i32*
store i32 0,i32*%k0,align 4
%k1=tail call fastcc i32@_SMLFN9ExistTyID7compareE(i8*inreg%kT)
ret i32%k1
k2:
%k3=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%k3,i8**%b,align 8
%k4=call i8*@sml_alloc(i32 inreg 28)#0
%k5=getelementptr inbounds i8,i8*%k4,i64 -4
%k6=bitcast i8*%k5 to i32*
store i32 1342177304,i32*%k6,align 4
store i8*%k4,i8**%c,align 8
%k7=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%k8=bitcast i8*%k4 to i8**
store i8*%k7,i8**%k8,align 8
%k9=getelementptr inbounds i8,i8*%k4,i64 8
%la=bitcast i8*%k9 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[72x i8]}>,<{[4x i8],i32,[72x i8]}>*@b,i64 0,i32 2,i64 0),i8**%la,align 8
%lb=getelementptr inbounds i8,i8*%k4,i64 16
%lc=bitcast i8*%lb to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[11x i8]}>,<{[4x i8],i32,[11x i8]}>*@c,i64 0,i32 2,i64 0),i8**%lc,align 8
%ld=getelementptr inbounds i8,i8*%k4,i64 24
%le=bitcast i8*%ld to i32*
store i32 7,i32*%le,align 4
%lf=call i8*@sml_alloc(i32 inreg 60)#0
%lg=getelementptr inbounds i8,i8*%lf,i64 -4
%lh=bitcast i8*%lg to i32*
store i32 1342177336,i32*%lh,align 4
%li=getelementptr inbounds i8,i8*%lf,i64 56
%lj=bitcast i8*%li to i32*
store i32 1,i32*%lj,align 4
%lk=load i8*,i8**%c,align 8
%ll=bitcast i8*%lf to i8**
store i8*%lk,i8**%ll,align 8
call void@sml_raise(i8*inreg%lf)#1
unreachable
lm:
%ln=call i8*@sml_alloc(i32 inreg 20)#0
%lo=getelementptr inbounds i8,i8*%ln,i64 -4
%lp=bitcast i8*%lo to i32*
store i32 1342177296,i32*%lp,align 4
%lq=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%lr=bitcast i8*%ln to i8**
store i8*%lq,i8**%lr,align 8
br label%ls
ls:
%lt=phi i8*[%ln,%lm],[%js,%jo]
%lu=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%lv=getelementptr inbounds i8,i8*%lt,i64 8
%lw=bitcast i8*%lv to i8**
store i8*%lu,i8**%lw,align 8
%lx=getelementptr inbounds i8,i8*%lt,i64 16
%ly=bitcast i8*%lx to i32*
store i32 3,i32*%ly,align 4
br label%h
}
define internal fastcc i8*@_SMLLLN9CompareTy9compareTyE_100(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLFN9CompareTy9compareTyE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
