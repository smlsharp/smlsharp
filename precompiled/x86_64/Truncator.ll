@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306360,i8*null,i32 1}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306360,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32}>,<{[4x i8],i32,i8*,i32}>*@a,i32 0,i32 0,i32 0),i32 8),i32 1}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32}>,<{[4x i8],i32,i8*,i32}>*@b,i32 0,i32 0,i32 0),i32 8),i32 1,[4x i8]zeroinitializer,i32 1}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 2,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@c,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[4x i8]}><{[4x i8]zeroinitializer,i32 -2147483644,[4x i8]c"...\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 3,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[4x i8]}>,<{[4x i8],i32,[4x i8]}>*@e,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 6,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@f,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@g,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@d,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@h,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*null,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@i,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 1,[4x i8]zeroinitializer,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@j,i32 0,i32 0,i32 0),i32 8),i32 2}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i32)*@_SMLL13isCutOffDepth_72 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLL13isCutOffDepth_84 to void(...)*),i32 -2147483647}>,align 8
@m=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLL8takeHead_76 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLL8takeHead_85 to void(...)*),i32 -2147483647}>,align 8
@n=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN9Truncator8truncateE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9Truncator8truncateE_88 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9Truncator8truncateE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@n,i64 0,i32 2)to i8*)
@_SML_ftab89187b999d299782_Truncator=external global i8
@o=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
define private void@_SML_tabb89187b999d299782_Truncator()#1{
unreachable
}
define void@_SML_load89187b999d299782_Truncator(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@o,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@o,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb89187b999d299782_Truncator,i8*@_SML_ftab89187b999d299782_Truncator,i8*null)#0
ret void
}
define void@_SML_main89187b999d299782_Truncator()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
define internal fastcc i8*@_SMLLN9Truncator4snocE_66(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%b,i8**%c,align 8
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
%h=icmp eq i8*%g,null
br i1%h,label%i,label%s
i:
%j=call i8*@sml_alloc(i32 inreg 20)#0
%k=getelementptr inbounds i8,i8*%j,i64 -4
%l=bitcast i8*%k to i32*
store i32 1342177296,i32*%l,align 4
%m=load i8*,i8**%c,align 8
%n=bitcast i8*%j to i8**
store i8*%m,i8**%n,align 8
%o=getelementptr inbounds i8,i8*%j,i64 8
%p=bitcast i8*%o to i8**
store i8*null,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%j,i64 16
%r=bitcast i8*%q to i32*
store i32 3,i32*%r,align 4
ret i8*%j
s:
store i8*%g,i8**%d,align 8
%t=call i8*@sml_alloc(i32 inreg 20)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177296,i32*%v,align 4
store i8*%t,i8**%e,align 8
%w=getelementptr inbounds i8,i8*%t,i64 4
%x=bitcast i8*%w to i32*
store i32 0,i32*%x,align 1
%y=bitcast i8*%t to i32*
store i32 4,i32*%y,align 4
%z=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%A=getelementptr inbounds i8,i8*%t,i64 8
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%t,i64 16
%D=bitcast i8*%C to i32*
store i32 2,i32*%D,align 4
%E=call i8*@sml_alloc(i32 inreg 20)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32 1342177296,i32*%G,align 4
store i8*%E,i8**%d,align 8
%H=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%I=bitcast i8*%E to i8**
store i8*%H,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%E,i64 8
%K=bitcast i8*%J to i8**
store i8*null,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%E,i64 16
%M=bitcast i8*%L to i32*
store i32 3,i32*%M,align 4
%N=call i8*@sml_alloc(i32 inreg 20)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177296,i32*%P,align 4
%Q=load i8*,i8**%e,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=load i8*,i8**%d,align 8
%T=getelementptr inbounds i8,i8*%N,i64 8
%U=bitcast i8*%T to i8**
store i8*%S,i8**%U,align 8
%V=getelementptr inbounds i8,i8*%N,i64 16
%W=bitcast i8*%V to i32*
store i32 3,i32*%W,align 4
ret i8*%N
}
define internal fastcc i32@_SMLL13isCutOffDepth_71(i8*inreg%a,i32 inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%a to i32*
%d=load i32,i32*%c,align 4
%e=icmp sle i32%d,%b
%f=zext i1%e to i32
ret i32%f
}
define internal fastcc i32@_SMLL13isCutOffDepth_72(i32 inreg%a)#2 gc"smlsharp"{
ret i32 0
}
define internal fastcc i32@_SMLL8takeHead_76(i8*inreg%a)#2 gc"smlsharp"{
f:
%b=bitcast i8*%a to i32*
%c=load i32,i32*%b,align 4
switch i32%c,label%d[
i32 5,label%h
i32 0,label%g
]
d:
%e=phi i32[0,%f],[1,%g],[1,%h]
ret i32%e
g:
br label%d
h:
br label%d
}
define internal fastcc i8*@_SMLL8takeHead_74(i8*inreg%a,i32 inreg%b,i32 inreg%c,i8*inreg%d,i8*inreg%e,i8*inreg%f)#3 gc"smlsharp"{
v:
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
%m=alloca i8*,align 8
%n=alloca i8*,align 8
%o=alloca i8*,align 8
%p=alloca i8*,align 8
%q=alloca i8*,align 8
%r=alloca i8*,align 8
call void@llvm.gcroot(i8**%n,i8*null)#0
call void@llvm.gcroot(i8**%o,i8*null)#0
call void@llvm.gcroot(i8**%p,i8*null)#0
call void@llvm.gcroot(i8**%q,i8*null)#0
call void@llvm.gcroot(i8**%r,i8*null)#0
store i8*%a,i8**%r,align 8
store i8*%d,i8**%n,align 8
store i8*%e,i8**%p,align 8
store i8*%f,i8**%o,align 8
%s=add nsw i32%b,1
br label%t
t:
%u=phi i8*[%d,%v],[%aT,%aS]
%w=phi i32[%c,%v],[%a4,%aS]
%x=icmp eq i32%w,0
br label%y
y:
%z=phi i8*[%u,%t],[%T,%S]
%A=load atomic i32,i32*@sml_check_flag unordered,align 4
%B=icmp eq i32%A,0
br i1%B,label%E,label%C
C:
call void@sml_check(i32 inreg%A)
%D=load i8*,i8**%n,align 8
br label%E
E:
%F=phi i8*[%D,%C],[%z,%y]
store i8*%F,i8**%q,align 8
br i1%x,label%bd,label%G
G:
%H=load i8*,i8**%p,align 8
%I=icmp eq i8*%H,null
br i1%I,label%J,label%U
J:
%K=load i8*,i8**%o,align 8
%L=icmp eq i8*%K,null
br i1%L,label%dH,label%M
M:
%N=bitcast i8*%K to i8**
%O=load i8*,i8**%N,align 8
%P=getelementptr inbounds i8,i8*%K,i64 8
%Q=bitcast i8*%P to i8**
%R=load i8*,i8**%Q,align 8
store i8*null,i8**%q,align 8
store i8*%O,i8**%p,align 8
store i8*%R,i8**%o,align 8
br label%S
S:
%T=phi i8*[%F,%M],[%ac,%Z],[%aI,%ar]
br label%y
U:
%V=bitcast i8*%H to i8**
%W=load i8*,i8**%V,align 8
%X=bitcast i8*%W to i32*
%Y=load i32,i32*%X,align 4
switch i32%Y,label%Z[
i32 6,label%a5
i32 1,label%aK
i32 4,label%ar
]
Z:
%aa=load i8*,i8**%r,align 8
%ab=call fastcc i8*@_SMLL5visit_75(i8*inreg%aa,i32 inreg%s,i8*inreg%W)
store i8*%ab,i8**%n,align 8
%ac=call i8*@sml_alloc(i32 inreg 20)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177296,i32*%ae,align 4
%af=load i8*,i8**%n,align 8
%ag=bitcast i8*%ac to i8**
store i8*%af,i8**%ag,align 8
%ah=load i8*,i8**%q,align 8
store i8*null,i8**%q,align 8
%ai=getelementptr inbounds i8,i8*%ac,i64 8
%aj=bitcast i8*%ai to i8**
store i8*%ah,i8**%aj,align 8
%ak=getelementptr inbounds i8,i8*%ac,i64 16
%al=bitcast i8*%ak to i32*
store i32 3,i32*%al,align 4
%am=load i8*,i8**%p,align 8
%an=getelementptr inbounds i8,i8*%am,i64 8
%ao=bitcast i8*%an to i8**
%ap=load i8*,i8**%ao,align 8
%aq=load i8*,i8**%o,align 8
store i8*%ac,i8**%n,align 8
store i8*%ap,i8**%p,align 8
store i8*%aq,i8**%o,align 8
br label%S
ar:
%as=getelementptr inbounds i8,i8*%W,i64 8
%at=bitcast i8*%as to i8**
%au=load i8*,i8**%at,align 8
store i8*%au,i8**%n,align 8
%av=getelementptr inbounds i8,i8*%H,i64 8
%aw=bitcast i8*%av to i8**
%ax=load i8*,i8**%aw,align 8
store i8*%ax,i8**%p,align 8
%ay=call i8*@sml_alloc(i32 inreg 20)#0
%az=getelementptr inbounds i8,i8*%ay,i64 -4
%aA=bitcast i8*%az to i32*
store i32 1342177296,i32*%aA,align 4
%aB=load i8*,i8**%p,align 8
%aC=bitcast i8*%ay to i8**
store i8*%aB,i8**%aC,align 8
%aD=load i8*,i8**%o,align 8
%aE=getelementptr inbounds i8,i8*%ay,i64 8
%aF=bitcast i8*%aE to i8**
store i8*%aD,i8**%aF,align 8
%aG=getelementptr inbounds i8,i8*%ay,i64 16
%aH=bitcast i8*%aG to i32*
store i32 3,i32*%aH,align 4
%aI=load i8*,i8**%q,align 8
%aJ=load i8*,i8**%n,align 8
store i8*null,i8**%q,align 8
store i8*%aI,i8**%n,align 8
store i8*%aJ,i8**%p,align 8
store i8*%ay,i8**%o,align 8
br label%S
aK:
%aL=load i8*,i8**%r,align 8
%aM=call fastcc i8*@_SMLL5visit_75(i8*inreg%aL,i32 inreg%s,i8*inreg%W)
store i8*%aM,i8**%n,align 8
%aN=call i8*@sml_alloc(i32 inreg 20)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177296,i32*%aP,align 4
%aQ=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%aR=bitcast i8*%aN to i8**
store i8*%aQ,i8**%aR,align 8
br label%aS
aS:
%aT=phi i8*[%aN,%aK],[%a8,%a5]
%aU=load i8*,i8**%q,align 8
store i8*null,i8**%q,align 8
%aV=getelementptr inbounds i8,i8*%aT,i64 8
%aW=bitcast i8*%aV to i8**
store i8*%aU,i8**%aW,align 8
%aX=getelementptr inbounds i8,i8*%aT,i64 16
%aY=bitcast i8*%aX to i32*
store i32 3,i32*%aY,align 4
%aZ=load i8*,i8**%p,align 8
%a0=getelementptr inbounds i8,i8*%aZ,i64 8
%a1=bitcast i8*%a0 to i8**
%a2=load i8*,i8**%o,align 8
%a3=load i8*,i8**%a1,align 8
store i8*%aT,i8**%n,align 8
store i8*%a3,i8**%p,align 8
%a4=add nsw i32%w,-1
store i8*%a2,i8**%o,align 8
br label%t
a5:
%a6=load i8*,i8**%r,align 8
%a7=call fastcc i8*@_SMLL5visit_75(i8*inreg%a6,i32 inreg%s,i8*inreg%W)
store i8*%a7,i8**%n,align 8
%a8=call i8*@sml_alloc(i32 inreg 20)#0
%a9=getelementptr inbounds i8,i8*%a8,i64 -4
%ba=bitcast i8*%a9 to i32*
store i32 1342177296,i32*%ba,align 4
%bb=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%bc=bitcast i8*%a8 to i8**
store i8*%bb,i8**%bc,align 8
br label%aS
bd:
store i8*null,i8**%r,align 8
%be=load i8*,i8**%p,align 8
%bf=icmp eq i8*%be,null
br i1%bf,label%bg,label%bk
bg:
%bh=load i8*,i8**%o,align 8
%bi=icmp eq i8*%bh,null
br i1%bi,label%dH,label%bj
bj:
store i8*null,i8**%o,align 8
store i8*null,i8**%p,align 8
store i8*null,i8**%q,align 8
br label%bw
bk:
%bl=bitcast i8*%be to i32**
%bm=load i32*,i32**%bl,align 8
%bn=load i32,i32*%bm,align 4
switch i32%bn,label%bo[
i32 6,label%bu
i32 1,label%bs
i32 4,label%bq
]
bo:
%bp=load i8*,i8**%o,align 8
store i8*null,i8**%o,align 8
store i8*null,i8**%p,align 8
store i8*null,i8**%q,align 8
br label%bw
bq:
%br=load i8*,i8**%o,align 8
store i8*null,i8**%o,align 8
store i8*null,i8**%p,align 8
store i8*null,i8**%q,align 8
br label%bw
bs:
%bt=load i8*,i8**%o,align 8
store i8*null,i8**%o,align 8
store i8*null,i8**%p,align 8
store i8*null,i8**%q,align 8
br label%bw
bu:
%bv=load i8*,i8**%o,align 8
store i8*null,i8**%o,align 8
store i8*null,i8**%p,align 8
store i8*null,i8**%q,align 8
br label%bw
bw:
%bx=phi i8*[%bh,%bj],[%bp,%bo],[%br,%bq],[%bt,%bs],[%bv,%bu]
%by=bitcast i8**%i to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%by)
%bz=bitcast i8**%j to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bz)
%bA=bitcast i8**%k to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bA)
%bB=bitcast i8**%l to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bB)
%bC=bitcast i8**%m to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bC)
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
call void@llvm.gcroot(i8**%m,i8*null)#0
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@m,i64 0,i32 2)to i8*),i8**%l,align 8
store i8*%be,i8**%k,align 8
store i8*%bx,i8**%j,align 8
store i8*null,i8**%i,align 8
%bD=bitcast i8**%k to i8***
%bE=bitcast i8**%g to i8*
%bF=bitcast i8**%h to i8*
br label%bG
bG:
%bH=phi i8*[%be,%bw],[%c9,%c8]
%bI=phi i8*[%bx,%bw],[%da,%c8]
%bJ=phi i8*[null,%bw],[%db,%c8]
%bK=load atomic i32,i32*@sml_check_flag unordered,align 4
%bL=icmp eq i32%bK,0
br i1%bL,label%bQ,label%bM
bM:
call void@sml_check(i32 inreg%bK)
%bN=load i8*,i8**%i,align 8
%bO=load i8*,i8**%j,align 8
%bP=load i8*,i8**%k,align 8
br label%bQ
bQ:
%bR=phi i8*[%bP,%bM],[%bH,%bG]
%bS=phi i8*[%bO,%bM],[%bI,%bG]
%bT=phi i8*[%bN,%bM],[%bJ,%bG]
%bU=bitcast i8*%bR to i8**
%bV=icmp eq i8*%bR,null
br i1%bV,label%bW,label%b4
bW:
%bX=icmp eq i8*%bS,null
br i1%bX,label%dc,label%bY
bY:
%bZ=bitcast i8*%bS to i8**
%b0=load i8*,i8**%bZ,align 8
%b1=getelementptr inbounds i8,i8*%bS,i64 8
%b2=bitcast i8*%b1 to i8**
%b3=load i8*,i8**%b2,align 8
store i8*%b0,i8**%k,align 8
store i8*%b3,i8**%j,align 8
store i8*%bT,i8**%i,align 8
br label%c8
b4:
%b5=load i8*,i8**%bU,align 8
%b6=bitcast i8*%b5 to i32*
%b7=load i32,i32*%b6,align 4
%b8=icmp eq i32%b7,4
br i1%b8,label%cP,label%b9
b9:
%ca=getelementptr inbounds i8,i8*%bR,i64 8
%cb=bitcast i8*%ca to i8**
%cc=load i8*,i8**%cb,align 8
store i8*%cc,i8**%m,align 8
%cd=load i8*,i8**%l,align 8
%ce=getelementptr inbounds i8,i8*%cd,i64 16
%cf=bitcast i8*%ce to i8*(i8*,i8*)**
%cg=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cf,align 8
%ch=bitcast i8*%cd to i8**
%ci=load i8*,i8**%ch,align 8
%cj=load i8*,i8**%bU,align 8
%ck=call fastcc i8*%cg(i8*inreg%ci,i8*inreg%cj)
%cl=bitcast i8*%ck to i32*
%cm=load i32,i32*%cl,align 4
%cn=icmp eq i32%cm,0
%co=load i8*,i8**%i,align 8
br i1%cn,label%cL,label%cp
cp:
store i8*null,i8**%i,align 8
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bE)
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bF)
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
store i8*%co,i8**%g,align 8
%cq=call i8*@sml_alloc(i32 inreg 12)#0
%cr=getelementptr inbounds i8,i8*%cq,i64 -4
%cs=bitcast i8*%cr to i32*
store i32 1342177288,i32*%cs,align 4
store i8*%cq,i8**%h,align 8
%ct=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cu=bitcast i8*%cq to i8**
store i8*%ct,i8**%cu,align 8
%cv=getelementptr inbounds i8,i8*%cq,i64 8
%cw=bitcast i8*%cv to i32*
store i32 1,i32*%cw,align 4
%cx=call i8*@sml_alloc(i32 inreg 28)#0
%cy=getelementptr inbounds i8,i8*%cx,i64 -4
%cz=bitcast i8*%cy to i32*
store i32 1342177304,i32*%cz,align 4
%cA=load i8*,i8**%h,align 8
%cB=bitcast i8*%cx to i8**
store i8*%cA,i8**%cB,align 8
%cC=getelementptr inbounds i8,i8*%cx,i64 8
%cD=bitcast i8*%cC to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9Truncator4snocE_66 to void(...)*),void(...)**%cD,align 8
%cE=getelementptr inbounds i8,i8*%cx,i64 16
%cF=bitcast i8*%cE to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9Truncator4snocE_66 to void(...)*),void(...)**%cF,align 8
%cG=getelementptr inbounds i8,i8*%cx,i64 24
%cH=bitcast i8*%cG to i32*
store i32 -2147483647,i32*%cH,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bE)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bF)
%cI=load i8**,i8***%bD,align 8
store i8*null,i8**%k,align 8
%cJ=load i8*,i8**%cI,align 8
%cK=call fastcc i8*@_SMLLN9Truncator4snocE_66(i8*inreg%cA,i8*inreg%cJ)
br label%cL
cL:
%cM=phi i8*[%cK,%cp],[%co,%b9]
%cN=load i8*,i8**%j,align 8
%cO=load i8*,i8**%m,align 8
store i8*null,i8**%m,align 8
store i8*%cO,i8**%k,align 8
store i8*%cM,i8**%i,align 8
br label%c8
cP:
%cQ=getelementptr inbounds i8,i8*%b5,i64 8
%cR=bitcast i8*%cQ to i8**
%cS=load i8*,i8**%cR,align 8
store i8*%cS,i8**%m,align 8
%cT=getelementptr inbounds i8,i8*%bR,i64 8
%cU=bitcast i8*%cT to i8**
%cV=load i8*,i8**%cU,align 8
store i8*%cV,i8**%k,align 8
%cW=call i8*@sml_alloc(i32 inreg 20)#0
%cX=getelementptr inbounds i8,i8*%cW,i64 -4
%cY=bitcast i8*%cX to i32*
store i32 1342177296,i32*%cY,align 4
%cZ=load i8*,i8**%k,align 8
%c0=bitcast i8*%cW to i8**
store i8*%cZ,i8**%c0,align 8
%c1=load i8*,i8**%j,align 8
%c2=getelementptr inbounds i8,i8*%cW,i64 8
%c3=bitcast i8*%c2 to i8**
store i8*%c1,i8**%c3,align 8
%c4=getelementptr inbounds i8,i8*%cW,i64 16
%c5=bitcast i8*%c4 to i32*
store i32 3,i32*%c5,align 4
%c6=load i8*,i8**%i,align 8
%c7=load i8*,i8**%m,align 8
store i8*null,i8**%m,align 8
store i8*%c7,i8**%k,align 8
store i8*%cW,i8**%j,align 8
br label%c8
c8:
%c9=phi i8*[%b0,%bY],[%cO,%cL],[%c7,%cP]
%da=phi i8*[%b3,%bY],[%cN,%cL],[%cW,%cP]
%db=phi i8*[%bT,%bY],[%cM,%cL],[%c6,%cP]
br label%bG
dc:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%by)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bz)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bA)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bB)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bC)
store i8*%bT,i8**%o,align 8
%dd=call i8*@sml_alloc(i32 inreg 20)#0
%de=getelementptr inbounds i8,i8*%dd,i64 -4
%df=bitcast i8*%de to i32*
store i32 1342177296,i32*%df,align 4
store i8*%dd,i8**%p,align 8
%dg=bitcast i8*%dd to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@k,i64 0,i32 2)to i8*),i8**%dg,align 8
%dh=load i8*,i8**%o,align 8
store i8*null,i8**%o,align 8
%di=getelementptr inbounds i8,i8*%dd,i64 8
%dj=bitcast i8*%di to i8**
store i8*%dh,i8**%dj,align 8
%dk=getelementptr inbounds i8,i8*%dd,i64 16
%dl=bitcast i8*%dk to i32*
store i32 3,i32*%dl,align 4
%dm=call i8*@sml_alloc(i32 inreg 20)#0
%dn=getelementptr inbounds i8,i8*%dm,i64 -4
%do=bitcast i8*%dn to i32*
store i32 1342177296,i32*%do,align 4
store i8*%dm,i8**%o,align 8
%dp=getelementptr inbounds i8,i8*%dm,i64 4
%dq=bitcast i8*%dp to i32*
store i32 0,i32*%dq,align 1
%dr=bitcast i8*%dm to i32*
store i32 4,i32*%dr,align 4
%ds=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%dt=getelementptr inbounds i8,i8*%dm,i64 8
%du=bitcast i8*%dt to i8**
store i8*%ds,i8**%du,align 8
%dv=getelementptr inbounds i8,i8*%dm,i64 16
%dw=bitcast i8*%dv to i32*
store i32 2,i32*%dw,align 4
%dx=call i8*@sml_alloc(i32 inreg 20)#0
%dy=getelementptr inbounds i8,i8*%dx,i64 -4
%dz=bitcast i8*%dy to i32*
store i32 1342177296,i32*%dz,align 4
%dA=load i8*,i8**%o,align 8
%dB=bitcast i8*%dx to i8**
store i8*%dA,i8**%dB,align 8
%dC=load i8*,i8**%p,align 8
%dD=getelementptr inbounds i8,i8*%dx,i64 8
%dE=bitcast i8*%dD to i8**
store i8*%dC,i8**%dE,align 8
%dF=getelementptr inbounds i8,i8*%dx,i64 16
%dG=bitcast i8*%dF to i32*
store i32 3,i32*%dG,align 4
ret i8*%dx
dH:
ret i8*%F
}
define internal fastcc i8*@_SMLL5visit_75(i8*inreg%a,i32 inreg%b,i8*inreg%c)#3 gc"smlsharp"{
n:
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%c,i8**%d,align 8
store i8*%a,i8**%g,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%d,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%c,%n]
%o=bitcast i8*%m to i32*
%p=load i32,i32*%o,align 4
%q=icmp eq i32%p,1
br i1%q,label%t,label%r
r:
%s=phi i8*[%m,%l],[bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i8*,i32}>,<{[4x i8],i32,i32,[4x i8],i8*,i32}>*@k,i64 0,i32 2)to i8*),%t]
ret i8*%s
t:
%u=getelementptr inbounds i8,i8*%m,i64 8
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%d,align 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%e,align 8
%z=load i8*,i8**%g,align 8
%A=getelementptr inbounds i8,i8*%z,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
%D=getelementptr inbounds i8,i8*%C,i64 16
%E=bitcast i8*%D to i8*(i8*,i8*)**
%F=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%E,align 8
%G=bitcast i8*%C to i8**
%H=load i8*,i8**%G,align 8
store i8*%H,i8**%f,align 8
%I=call i8*@sml_alloc(i32 inreg 4)#0
%J=bitcast i8*%I to i32*
%K=getelementptr inbounds i8,i8*%I,i64 -4
%L=bitcast i8*%K to i32*
store i32 4,i32*%L,align 4
store i32%b,i32*%J,align 4
%M=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%N=call fastcc i8*%F(i8*inreg%M,i8*inreg%I)
%O=bitcast i8*%N to i32*
%P=load i32,i32*%O,align 4
%Q=icmp eq i32%P,0
br i1%Q,label%R,label%r
R:
%S=bitcast i8**%g to i8***
%T=load i8**,i8***%S,align 8
%U=load i8*,i8**%T,align 8
%V=getelementptr inbounds i8,i8*%U,i64 32
%W=bitcast i8*%V to i8**
%X=load i8*,i8**%W,align 8
%Y=icmp eq i8*%X,null
br i1%Y,label%Z,label%ae
Z:
store i8*null,i8**%g,align 8
%aa=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ab=getelementptr inbounds i8,i8*%aa,i64 8
%ac=bitcast i8*%ab to i8**
%ad=load i8*,i8**%ac,align 8
br label%an
ae:
%af=bitcast i8**%T to i8*
%ag=bitcast i8*%X to i32*
%ah=load i32,i32*%ag,align 4
%ai=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aj=getelementptr inbounds i8,i8*%ai,i64 8
%ak=bitcast i8*%aj to i8**
%al=load i8*,i8**%ak,align 8
store i8*null,i8**%g,align 8
%am=call fastcc i8*@_SMLL8takeHead_74(i8*inreg%af,i32 inreg%b,i32 inreg%ah,i8*inreg null,i8*inreg%al,i8*inreg null)
br label%an
an:
%ao=phi i8*[%am,%ae],[%ad,%Z]
store i8*%ao,i8**%d,align 8
%ap=call i8*@sml_alloc(i32 inreg 20)#0
%aq=getelementptr inbounds i8,i8*%ap,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 1342177296,i32*%ar,align 4
store i8*%ap,i8**%f,align 8
%as=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%at=bitcast i8*%ap to i8**
store i8*%as,i8**%at,align 8
%au=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%av=getelementptr inbounds i8,i8*%ap,i64 8
%aw=bitcast i8*%av to i8**
store i8*%au,i8**%aw,align 8
%ax=getelementptr inbounds i8,i8*%ap,i64 16
%ay=bitcast i8*%ax to i32*
store i32 3,i32*%ay,align 4
%az=call i8*@sml_alloc(i32 inreg 20)#0
%aA=bitcast i8*%az to i32*
%aB=getelementptr inbounds i8,i8*%az,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 1342177296,i32*%aC,align 4
%aD=getelementptr inbounds i8,i8*%az,i64 4
%aE=bitcast i8*%aD to i32*
store i32 0,i32*%aE,align 1
store i32 1,i32*%aA,align 4
%aF=load i8*,i8**%f,align 8
%aG=getelementptr inbounds i8,i8*%az,i64 8
%aH=bitcast i8*%aG to i8**
store i8*%aF,i8**%aH,align 8
%aI=getelementptr inbounds i8,i8*%az,i64 16
%aJ=bitcast i8*%aI to i32*
store i32 2,i32*%aJ,align 4
ret i8*%az
}
define internal fastcc i8*@_SMLLN9Truncator8truncateE_78(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%i,label%k
i:
%j=bitcast i8*%a to i8**
br label%o
k:
call void@sml_check(i32 inreg%g)
%l=load i8*,i8**%d,align 8
%m=bitcast i8**%c to i8***
%n=load i8**,i8***%m,align 8
br label%o
o:
%p=phi i8**[%n,%k],[%j,%i]
%q=phi i8*[%l,%k],[%b,%i]
%r=load i8*,i8**%p,align 8
%s=getelementptr inbounds i8,i8*%r,i64 24
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
%v=icmp eq i8*%u,null
br i1%v,label%w,label%C
w:
%x=getelementptr inbounds i8,i8*%r,i64 32
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
%A=icmp eq i8*%z,null
br i1%A,label%B,label%C
B:
ret i8*%q
C:
store i8*null,i8**%c,align 8
%D=load i8*,i8**%p,align 8
store i8*%D,i8**%c,align 8
%E=getelementptr inbounds i8,i8*%D,i64 24
%F=bitcast i8*%E to i8**
%G=load i8*,i8**%F,align 8
%H=icmp eq i8*%G,null
br i1%H,label%ac,label%I
I:
%J=bitcast i8*%G to i32*
%K=load i32,i32*%J,align 4
%L=call i8*@sml_alloc(i32 inreg 12)#0
%M=bitcast i8*%L to i32*
%N=getelementptr inbounds i8,i8*%L,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177288,i32*%O,align 4
store i8*%L,i8**%e,align 8
store i32%K,i32*%M,align 4
%P=getelementptr inbounds i8,i8*%L,i64 8
%Q=bitcast i8*%P to i32*
store i32 0,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 28)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177304,i32*%T,align 4
%U=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%R,i64 8
%X=bitcast i8*%W to void(...)**
store void(...)*bitcast(i32(i8*,i32)*@_SMLL13isCutOffDepth_71 to void(...)*),void(...)**%X,align 8
%Y=getelementptr inbounds i8,i8*%R,i64 16
%Z=bitcast i8*%Y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL13isCutOffDepth_83 to void(...)*),void(...)**%Z,align 8
%aa=getelementptr inbounds i8,i8*%R,i64 24
%ab=bitcast i8*%aa to i32*
store i32 -2147483647,i32*%ab,align 4
br label%ac
ac:
%ad=phi i8*[%R,%I],[bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@l,i64 0,i32 2)to i8*),%C]
store i8*%ad,i8**%e,align 8
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
store i8*%ae,i8**%f,align 8
%ah=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ai=bitcast i8*%ae to i8**
store i8*%ah,i8**%ai,align 8
%aj=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ak=getelementptr inbounds i8,i8*%ae,i64 8
%al=bitcast i8*%ak to i8**
store i8*%aj,i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ae,i64 16
%an=bitcast i8*%am to i32*
store i32 3,i32*%an,align 4
%ao=call i8*@sml_alloc(i32 inreg 28)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177304,i32*%aq,align 4
%ar=load i8*,i8**%f,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ao,i64 8
%au=bitcast i8*%at to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32,i8*,i8*,i8*)*@_SMLL8takeHead_74 to void(...)*),void(...)**%au,align 8
%av=getelementptr inbounds i8,i8*%ao,i64 16
%aw=bitcast i8*%av to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*,i8*,i8*)*@_SMLL8takeHead_86 to void(...)*),void(...)**%aw,align 8
%ax=getelementptr inbounds i8,i8*%ao,i64 24
%ay=bitcast i8*%ax to i32*
store i32 -2147483647,i32*%ay,align 4
%az=call i8*@sml_alloc(i32 inreg 28)#0
%aA=getelementptr inbounds i8,i8*%az,i64 -4
%aB=bitcast i8*%aA to i32*
store i32 1342177304,i32*%aB,align 4
%aC=load i8*,i8**%f,align 8
%aD=bitcast i8*%az to i8**
store i8*%aC,i8**%aD,align 8
%aE=getelementptr inbounds i8,i8*%az,i64 8
%aF=bitcast i8*%aE to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i8*)*@_SMLL5visit_75 to void(...)*),void(...)**%aF,align 8
%aG=getelementptr inbounds i8,i8*%az,i64 16
%aH=bitcast i8*%aG to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLL5visit_87 to void(...)*),void(...)**%aH,align 8
%aI=getelementptr inbounds i8,i8*%az,i64 24
%aJ=bitcast i8*%aI to i32*
store i32 -2147483647,i32*%aJ,align 4
%aK=load i8*,i8**%d,align 8
%aL=tail call fastcc i8*@_SMLL5visit_75(i8*inreg%aC,i32 inreg 0,i8*inreg%aK)
ret i8*%aL
}
define fastcc i8*@_SMLFN9Truncator8truncateE(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9Truncator8truncateE_78 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9Truncator8truncateE_78 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLL13isCutOffDepth_83(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=bitcast i8*%a to i32*
%f=load i32,i32*%e,align 4
%g=icmp sle i32%f,%d
%h=zext i1%g to i32
%i=tail call i8*@sml_alloc(i32 inreg 4)#0
%j=bitcast i8*%i to i32*
%k=getelementptr inbounds i8,i8*%i,i64 -4
%l=bitcast i8*%k to i32*
store i32 4,i32*%l,align 4
store i32%h,i32*%j,align 4
ret i8*%i
}
define internal fastcc i8*@_SMLL13isCutOffDepth_84(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLL8takeHead_85(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
i:
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
switch i32%d,label%g[
i32 5,label%f
i32 0,label%e
]
e:
br label%g
f:
br label%g
g:
%h=phi i32[0,%i],[1,%e],[1,%f]
%j=tail call i8*@sml_alloc(i32 inreg 4)#0
%k=bitcast i8*%j to i32*
%l=getelementptr inbounds i8,i8*%j,i64 -4
%m=bitcast i8*%l to i32*
store i32 4,i32*%m,align 4
store i32%h,i32*%k,align 4
ret i8*%j
}
define internal fastcc i8*@_SMLL8takeHead_86(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d,i8*inreg%e,i8*inreg%f)#3 gc"smlsharp"{
%g=bitcast i8*%b to i32*
%h=load i32,i32*%g,align 4
%i=bitcast i8*%c to i32*
%j=load i32,i32*%i,align 4
%k=tail call fastcc i8*@_SMLL8takeHead_74(i8*inreg%a,i32 inreg%h,i32 inreg%j,i8*inreg%d,i8*inreg%e,i8*inreg%f)
ret i8*%k
}
define internal fastcc i8*@_SMLL5visit_87(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=tail call fastcc i8*@_SMLL5visit_75(i8*inreg%a,i32 inreg%e,i8*inreg%c)
ret i8*%f
}
define internal fastcc i8*@_SMLLN9Truncator8truncateE_88(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN9Truncator8truncateE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
attributes#3={uwtable}
