@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[37x i8]}><{[4x i8]zeroinitializer,i32 -2147483611,[37x i8]c"src/ml-yacc/lib/stream.sml:13.3(371)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLL9streamify_33 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLL9streamify_38 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN1__9StreamFunE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN1__9StreamFunE_39 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN1__9StreamFunE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SML_ftab250aeb242f7ed3cb_stream=external global i8
@d=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
define private void@_SML_tabb250aeb242f7ed3cb_stream()#2{
unreachable
}
define void@_SML_load250aeb242f7ed3cb_stream(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@d,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@d,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb250aeb242f7ed3cb_stream,i8*@_SML_ftab250aeb242f7ed3cb_stream,i8*null)#0
ret void
}
define void@_SML_main250aeb242f7ed3cb_stream()local_unnamed_addr#3 gc"smlsharp"{
ret void
}
define internal fastcc i8*@_SMLL3get_31(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
o:
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
store i8*%a,i8**%f,align 8
store i8*%b,i8**%c,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%m,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%c,align 8
%l=load i8*,i8**%f,align 8
br label%m
m:
%n=phi i8*[%l,%j],[%a,%o]
%p=phi i8*[%k,%j],[%b,%o]
store i8*%p,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%n,i64 4
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=add i32%s,-1
%u=sub i32 0,%s
%v=and i32%t,%u
%w=add i32%s,7
%x=add i32%w,%v
%y=and i32%x,-8
%z=add i32%y,15
%A=and i32%z,-8
%B=lshr i32%x,3
%C=lshr i32%v,3
%D=sub nsw i32%B,%C
%E=shl i32 1,%D
%F=bitcast i8*%n to i32*
%G=load i32,i32*%F,align 4
%H=or i32%E,%G
%I=or i32%A,4
%J=bitcast i8*%p to i8**
%K=load i8*,i8**%J,align 8
%L=bitcast i8*%K to i32*
%M=load i32,i32*%L,align 4
switch i32%M,label%N[
i32 0,label%bm
i32 1,label%af
]
N:
store i8*null,i8**%d,align 8
store i8*null,i8**%f,align 8
call void@sml_matchcomp_bug()
%O=load i8*,i8**@_SMLZ5Match,align 8
store i8*%O,i8**%c,align 8
%P=call i8*@sml_alloc(i32 inreg 20)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177296,i32*%R,align 4
store i8*%P,i8**%d,align 8
%S=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=getelementptr inbounds i8,i8*%P,i64 8
%V=bitcast i8*%U to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[37x i8]}>,<{[4x i8],i32,[37x i8]}>*@a,i64 0,i32 2,i64 0),i8**%V,align 8
%W=getelementptr inbounds i8,i8*%P,i64 16
%X=bitcast i8*%W to i32*
store i32 3,i32*%X,align 4
%Y=call i8*@sml_alloc(i32 inreg 60)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177336,i32*%aa,align 4
%ab=getelementptr inbounds i8,i8*%Y,i64 56
%ac=bitcast i8*%ab to i32*
store i32 1,i32*%ac,align 4
%ad=load i8*,i8**%d,align 8
%ae=bitcast i8*%Y to i8**
store i8*%ad,i8**%ae,align 8
call void@sml_raise(i8*inreg%Y)#1
unreachable
af:
%ag=getelementptr inbounds i8,i8*%K,i64 8
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
store i8*%ai,i8**%c,align 8
%aj=getelementptr inbounds i8,i8*%ai,i64 16
%ak=bitcast i8*%aj to i8*(i8*,i8*)**
%al=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ak,align 8
%am=bitcast i8*%ai to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=call i8*@sml_alloc(i32 inreg 4)#0
%ap=bitcast i8*%ao to i32*
%aq=getelementptr inbounds i8,i8*%ao,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 4,i32*%ar,align 4
store i32 0,i32*%ap,align 4
%as=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%at=call fastcc i8*%al(i8*inreg%as,i8*inreg%ao)
store i8*%at,i8**%e,align 8
%au=call i8*@sml_alloc(i32 inreg 8)#0
%av=getelementptr inbounds i8,i8*%au,i64 -4
%aw=bitcast i8*%av to i32*
store i32 805306376,i32*%aw,align 4
store i8*%au,i8**%g,align 8
%ax=bitcast i8*%au to i64*
store i64 0,i64*%ax,align 1
%ay=call i8*@sml_alloc(i32 inreg 20)#0
%az=bitcast i8*%ay to i32*
%aA=getelementptr inbounds i8,i8*%ay,i64 -4
%aB=bitcast i8*%aA to i32*
store i32 1342177296,i32*%aB,align 4
%aC=getelementptr inbounds i8,i8*%ay,i64 4
%aD=bitcast i8*%aC to i32*
store i32 0,i32*%aD,align 1
store i32 1,i32*%az,align 4
%aE=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aF=getelementptr inbounds i8,i8*%ay,i64 8
%aG=bitcast i8*%aF to i8**
store i8*%aE,i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%ay,i64 16
%aI=bitcast i8*%aH to i32*
store i32 2,i32*%aI,align 4
%aJ=load i8*,i8**%g,align 8
%aK=bitcast i8*%aJ to i8**
call void@sml_write(i8*inreg%aJ,i8**inreg%aK,i8*inreg%ay)#0
%aL=load i8*,i8**%f,align 8
%aM=getelementptr inbounds i8,i8*%aL,i64 4
%aN=bitcast i8*%aM to i32*
%aO=load i32,i32*%aN,align 4
store i8*null,i8**%f,align 8
%aP=bitcast i8*%aL to i32*
%aQ=load i32,i32*%aP,align 4
%aR=call i8*@sml_alloc(i32 inreg%I)#0
%aS=or i32%A,1342177280
%aT=getelementptr inbounds i8,i8*%aR,i64 -4
%aU=bitcast i8*%aT to i32*
store i32%aS,i32*%aU,align 4
store i8*%aR,i8**%c,align 8
call void@llvm.memset.p0i8.i32(i8*%aR,i8 0,i32%I,i1 false)
%aV=icmp eq i32%aQ,0
%aW=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aX=sext i32%v to i64
%aY=getelementptr inbounds i8,i8*%aR,i64%aX
br i1%aV,label%a1,label%aZ
aZ:
%a0=bitcast i8*%aY to i8**
store i8*%aW,i8**%a0,align 8
br label%a2
a1:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aY,i8*%aW,i32%aO,i1 false)
br label%a2
a2:
%a3=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%a4=sext i32%y to i64
%a5=getelementptr inbounds i8,i8*%aR,i64%a4
%a6=bitcast i8*%a5 to i8**
store i8*%a3,i8**%a6,align 8
%a7=sext i32%A to i64
%a8=getelementptr inbounds i8,i8*%aR,i64%a7
%a9=bitcast i8*%a8 to i32*
store i32%H,i32*%a9,align 4
%ba=call i8*@sml_alloc(i32 inreg 20)#0
%bb=getelementptr inbounds i8,i8*%ba,i64 -4
%bc=bitcast i8*%bb to i32*
store i32 1342177296,i32*%bc,align 4
%bd=bitcast i8*%ba to i64*
store i64 0,i64*%bd,align 4
%be=load i8*,i8**%c,align 8
%bf=getelementptr inbounds i8,i8*%ba,i64 8
%bg=bitcast i8*%bf to i8**
store i8*%be,i8**%bg,align 8
%bh=getelementptr inbounds i8,i8*%ba,i64 16
%bi=bitcast i8*%bh to i32*
store i32 2,i32*%bi,align 4
%bj=load i8*,i8**%d,align 8
%bk=bitcast i8*%bj to i8**
call void@sml_write(i8*inreg%bj,i8**inreg%bk,i8*inreg%ba)#0
%bl=load i8*,i8**%c,align 8
ret i8*%bl
bm:
%bn=getelementptr inbounds i8,i8*%K,i64 8
%bo=bitcast i8*%bn to i8**
%bp=load i8*,i8**%bo,align 8
ret i8*%bp
}
define internal fastcc i8*@_SMLL4cons_32(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%e,align 8
store i8*%b,i8**%c,align 8
%g=getelementptr inbounds i8,i8*%a,i64 4
%h=bitcast i8*%g to i32*
%i=load i32,i32*%h,align 4
%j=add i32%i,-1
%k=sub i32 0,%i
%l=and i32%j,%k
%m=add i32%i,7
%n=add i32%m,%l
%o=and i32%n,-8
%p=add i32%o,15
%q=and i32%p,-8
%r=lshr i32%n,3
%s=lshr i32%l,3
%t=sub nsw i32%r,%s
%u=shl i32 1,%t
%v=bitcast i8*%a to i32*
%w=load i32,i32*%v,align 4
%x=or i32%u,%w
%y=or i32%q,4
%z=icmp eq i32%w,0
br i1%z,label%F,label%A
A:
%B=sext i32%l to i64
%C=getelementptr inbounds i8,i8*%b,i64%B
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
br label%M
F:
%G=call i8*@sml_alloc(i32 inreg%i)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32%i,i32*%I,align 4
%J=load i8*,i8**%c,align 8
%K=sext i32%l to i64
%L=getelementptr inbounds i8,i8*%J,i64%K
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%G,i8*%L,i32%i,i1 false)
br label%M
M:
%N=phi i64[%K,%F],[%B,%A]
%O=phi i8*[%J,%F],[%b,%A]
%P=phi i8*[%G,%F],[%E,%A]
store i8*%P,i8**%d,align 8
%Q=sext i32%o to i64
%R=getelementptr inbounds i8,i8*%O,i64%Q
%S=bitcast i8*%R to i8**
%T=load i8*,i8**%S,align 8
store i8*%T,i8**%c,align 8
%U=call i8*@sml_alloc(i32 inreg 8)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 805306376,i32*%W,align 4
store i8*%U,i8**%f,align 8
%X=bitcast i8*%U to i64*
store i64 0,i64*%X,align 1
%Y=load i8*,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%Y,i64 4
%aa=bitcast i8*%Z to i32*
%ab=load i32,i32*%aa,align 4
store i8*null,i8**%e,align 8
%ac=bitcast i8*%Y to i32*
%ad=load i32,i32*%ac,align 4
%ae=call i8*@sml_alloc(i32 inreg%y)#0
%af=or i32%q,1342177280
%ag=getelementptr inbounds i8,i8*%ae,i64 -4
%ah=bitcast i8*%ag to i32*
store i32%af,i32*%ah,align 4
store i8*%ae,i8**%e,align 8
call void@llvm.memset.p0i8.i32(i8*%ae,i8 0,i32%y,i1 false)
%ai=icmp eq i32%ad,0
%aj=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ak=getelementptr inbounds i8,i8*%ae,i64%N
br i1%ai,label%an,label%al
al:
%am=bitcast i8*%ak to i8**
store i8*%aj,i8**%am,align 8
br label%ao
an:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ak,i8*%aj,i32%ab,i1 false)
br label%ao
ao:
%ap=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aq=getelementptr inbounds i8,i8*%ae,i64%Q
%ar=bitcast i8*%aq to i8**
store i8*%ap,i8**%ar,align 8
%as=sext i32%q to i64
%at=getelementptr inbounds i8,i8*%ae,i64%as
%au=bitcast i8*%at to i32*
store i32%x,i32*%au,align 4
%av=call i8*@sml_alloc(i32 inreg 20)#0
%aw=getelementptr inbounds i8,i8*%av,i64 -4
%ax=bitcast i8*%aw to i32*
store i32 1342177296,i32*%ax,align 4
%ay=bitcast i8*%av to i64*
store i64 0,i64*%ay,align 4
%az=load i8*,i8**%e,align 8
%aA=getelementptr inbounds i8,i8*%av,i64 8
%aB=bitcast i8*%aA to i8**
store i8*%az,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%av,i64 16
%aD=bitcast i8*%aC to i32*
store i32 2,i32*%aD,align 4
%aE=load i8*,i8**%f,align 8
%aF=bitcast i8*%aE to i8**
call void@sml_write(i8*inreg%aE,i8**inreg%aF,i8*inreg%av)#0
%aG=load i8*,i8**%f,align 8
ret i8*%aG
}
define internal fastcc i8*@_SMLL9streamify_33(i8*inreg%a)#3 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 805306376,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=bitcast i8*%d to i64*
store i64 0,i64*%g,align 1
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=bitcast i8*%h to i32*
%j=getelementptr inbounds i8,i8*%h,i64 -4
%k=bitcast i8*%j to i32*
store i32 1342177296,i32*%k,align 4
%l=getelementptr inbounds i8,i8*%h,i64 4
%m=bitcast i8*%l to i32*
store i32 0,i32*%m,align 1
store i32 1,i32*%i,align 4
%n=load i8*,i8**%b,align 8
%o=getelementptr inbounds i8,i8*%h,i64 8
%p=bitcast i8*%o to i8**
store i8*%n,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 2,i32*%r,align 4
%s=load i8*,i8**%c,align 8
%t=bitcast i8*%s to i8**
call void@sml_write(i8*inreg%s,i8**inreg%t,i8*inreg%h)#0
%u=load i8*,i8**%c,align 8
ret i8*%u
}
define internal fastcc i8*@_SMLLN1__9StreamFunE_35(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%c,align 8
%f=bitcast i8*%a to i32*
%g=load i32,i32*%f,align 4
%h=getelementptr inbounds i8,i8*%a,i64 4
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=call i8*@sml_alloc(i32 inreg 12)#0
%l=bitcast i8*%k to i32*
%m=getelementptr inbounds i8,i8*%k,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177288,i32*%n,align 4
store i8*%k,i8**%d,align 8
store i32%g,i32*%l,align 4
%o=getelementptr inbounds i8,i8*%k,i64 4
%p=bitcast i8*%o to i32*
store i32%j,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i32*
store i32 0,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
store i8*%s,i8**%e,align 8
%v=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3get_31 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3get_31 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
%D=load i8*,i8**%c,align 8
%E=bitcast i8*%D to i32*
%F=load i32,i32*%E,align 4
store i8*null,i8**%c,align 8
%G=getelementptr inbounds i8,i8*%D,i64 4
%H=bitcast i8*%G to i32*
%I=load i32,i32*%H,align 4
%J=call i8*@sml_alloc(i32 inreg 12)#0
%K=bitcast i8*%J to i32*
%L=getelementptr inbounds i8,i8*%J,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177288,i32*%M,align 4
store i8*%J,i8**%c,align 8
store i32%F,i32*%K,align 4
%N=getelementptr inbounds i8,i8*%J,i64 4
%O=bitcast i8*%N to i32*
store i32%I,i32*%O,align 4
%P=getelementptr inbounds i8,i8*%J,i64 8
%Q=bitcast i8*%P to i32*
store i32 0,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 28)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177304,i32*%T,align 4
store i8*%R,i8**%d,align 8
%U=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%R,i64 8
%X=bitcast i8*%W to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4cons_32 to void(...)*),void(...)**%X,align 8
%Y=getelementptr inbounds i8,i8*%R,i64 16
%Z=bitcast i8*%Y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4cons_32 to void(...)*),void(...)**%Z,align 8
%aa=getelementptr inbounds i8,i8*%R,i64 24
%ab=bitcast i8*%aa to i32*
store i32 -2147483647,i32*%ab,align 4
%ac=call i8*@sml_alloc(i32 inreg 28)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177304,i32*%ae,align 4
%af=load i8*,i8**%d,align 8
%ag=bitcast i8*%ac to i8**
store i8*%af,i8**%ag,align 8
%ah=load i8*,i8**%e,align 8
%ai=getelementptr inbounds i8,i8*%ac,i64 8
%aj=bitcast i8*%ai to i8**
store i8*%ah,i8**%aj,align 8
%ak=getelementptr inbounds i8,i8*%ac,i64 16
%al=bitcast i8*%ak to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*),i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ac,i64 24
%an=bitcast i8*%am to i32*
store i32 7,i32*%an,align 4
ret i8*%ac
}
define fastcc i8*@_SMLFN1__9StreamFunE(i32 inreg%a,i32 inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN1__9StreamFunE_35 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN1__9StreamFunE_35 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLL9streamify_38(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLL9streamify_33(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN1__9StreamFunE_39(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN1__9StreamFunE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
attributes#4={uwtable}
