@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN13AnalyzeTopEnv13analyzeTopEnvE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_50 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN13AnalyzeTopEnv13analyzeTopEnvE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SML_ftabba1b6429ec2c88fd_AnalyzeTopEnv=external global i8
@b=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@_SMLFN9SymbolEnv4appiE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main89b8631430c545af_Symbol()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load89b8631430c545af_Symbol(i8*)local_unnamed_addr
define private void@_SML_tabbba1b6429ec2c88fd_AnalyzeTopEnv()#2{
unreachable
}
define void@_SML_loadba1b6429ec2c88fd_AnalyzeTopEnv(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@b,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@b,align 1
tail call void@_SML_load89b8631430c545af_Symbol(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbba1b6429ec2c88fd_AnalyzeTopEnv,i8*@_SML_ftabba1b6429ec2c88fd_AnalyzeTopEnv,i8*null)#0
ret void
}
define void@_SML_mainba1b6429ec2c88fd_AnalyzeTopEnv()local_unnamed_addr#1 gc"smlsharp"{
tail call void@_SML_main89b8631430c545af_Symbol()#1
ret void
}
define internal fastcc void@_SMLLL10analyzeEnv_37(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%q
l:
call void@sml_check(i32 inreg%h)
%m=load i8*,i8**%c,align 8
%n=bitcast i8**%f to i8***
%o=load i8**,i8***%n,align 8
%p=bitcast i8**%o to i8*
br label%q
q:
%r=phi i8*[%p,%l],[%a,%j]
%s=phi i8**[%o,%l],[%k,%j]
%t=phi i8*[%m,%l],[%b,%j]
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%c,align 8
%w=getelementptr inbounds i8,i8*%t,i64 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%y,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
store i8*%B,i8**%e,align 8
%C=load i8*,i8**%s,align 8
%D=getelementptr inbounds i8,i8*%C,i64 24
%E=bitcast i8*%D to i8**
%F=load i8*,i8**%E,align 8
%G=getelementptr inbounds i8,i8*%F,i64 16
%H=bitcast i8*%G to i8*(i8*,i8*)**
%I=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%H,align 8
%J=bitcast i8*%F to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%g,align 8
%L=getelementptr inbounds i8,i8*%r,i64 16
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
%O=call i8*@sml_alloc(i32 inreg 4)#0
%P=bitcast i8*%O to i32*
%Q=getelementptr inbounds i8,i8*%O,i64 -4
%R=bitcast i8*%Q to i32*
store i32 4,i32*%R,align 4
store i32%N,i32*%P,align 4
%S=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%T=call fastcc i8*%I(i8*inreg%S,i8*inreg%O)
%U=getelementptr inbounds i8,i8*%T,i64 16
%V=bitcast i8*%U to i8*(i8*,i8*)**
%W=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%V,align 8
%X=bitcast i8*%T to i8**
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%g,align 8
%Z=call i8*@sml_alloc(i32 inreg 20)#0
%aa=getelementptr inbounds i8,i8*%Z,i64 -4
%ab=bitcast i8*%aa to i32*
store i32 1342177296,i32*%ab,align 4
%ac=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ad=bitcast i8*%Z to i8**
store i8*%ac,i8**%ad,align 8
%ae=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%af=getelementptr inbounds i8,i8*%Z,i64 8
%ag=bitcast i8*%af to i8**
store i8*%ae,i8**%ag,align 8
%ah=getelementptr inbounds i8,i8*%Z,i64 16
%ai=bitcast i8*%ah to i32*
store i32 3,i32*%ai,align 4
%aj=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ak=call fastcc i8*%W(i8*inreg%aj,i8*inreg%Z)
%al=load i8*,i8**%f,align 8
%am=getelementptr inbounds i8,i8*%al,i64 8
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
%ap=load i8*,i8**%e,align 8
tail call fastcc void@_SMLLL10analyzeEnv_36(i8*inreg%ao,i8*inreg%ap)
ret void
}
define internal fastcc void@_SMLLL10analyzeEnv_36(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%m,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%c,align 8
br label%m
m:
%n=phi i8*[%l,%k],[%b,%o]
%p=bitcast i8*%n to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%c,align 8
%r=getelementptr inbounds i8,i8*%n,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%d,align 8
%u=getelementptr inbounds i8,i8*%n,i64 16
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%e,align 8
%x=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%h,align 8
%D=bitcast i8**%f to i8***
%E=load i8**,i8***%D,align 8
%F=load i8*,i8**%E,align 8
%G=getelementptr inbounds i8,i8*%F,i64 8
%H=bitcast i8*%G to i8**
%I=load i8*,i8**%H,align 8
%J=getelementptr inbounds i8,i8*%I,i64 16
%K=bitcast i8*%J to i8*(i8*,i8*)**
%L=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%K,align 8
%M=bitcast i8*%I to i8**
%N=load i8*,i8**%M,align 8
store i8*%N,i8**%g,align 8
%O=getelementptr inbounds i8*,i8**%E,i64 1
%P=bitcast i8**%O to i32*
%Q=load i32,i32*%P,align 4
%R=call i8*@sml_alloc(i32 inreg 4)#0
%S=bitcast i8*%R to i32*
%T=getelementptr inbounds i8,i8*%R,i64 -4
%U=bitcast i8*%T to i32*
store i32 4,i32*%U,align 4
store i32%Q,i32*%S,align 4
%V=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%W=call fastcc i8*%L(i8*inreg%V,i8*inreg%R)
%X=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%Y=call fastcc i8*%A(i8*inreg%X,i8*inreg%W)
%Z=getelementptr inbounds i8,i8*%Y,i64 16
%aa=bitcast i8*%Z to i8*(i8*,i8*)**
%ab=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aa,align 8
%ac=bitcast i8*%Y to i8**
%ad=load i8*,i8**%ac,align 8
%ae=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%af=call fastcc i8*%ab(i8*inreg%ad,i8*inreg%ae)
%ag=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%ah=getelementptr inbounds i8,i8*%ag,i64 16
%ai=bitcast i8*%ah to i8*(i8*,i8*)**
%aj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ai,align 8
%ak=bitcast i8*%ag to i8**
%al=load i8*,i8**%ak,align 8
store i8*%al,i8**%g,align 8
%am=load i8**,i8***%D,align 8
%an=load i8*,i8**%am,align 8
%ao=getelementptr inbounds i8,i8*%an,i64 32
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8*(i8*,i8*)**
%at=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%as,align 8
%au=bitcast i8*%aq to i8**
%av=load i8*,i8**%au,align 8
store i8*%av,i8**%e,align 8
%aw=getelementptr inbounds i8*,i8**%am,i64 1
%ax=bitcast i8**%aw to i32*
%ay=load i32,i32*%ax,align 4
%az=call i8*@sml_alloc(i32 inreg 4)#0
%aA=bitcast i8*%az to i32*
%aB=getelementptr inbounds i8,i8*%az,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 4,i32*%aC,align 4
store i32%ay,i32*%aA,align 4
%aD=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aE=call fastcc i8*%at(i8*inreg%aD,i8*inreg%az)
%aF=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aG=call fastcc i8*%aj(i8*inreg%aF,i8*inreg%aE)
%aH=getelementptr inbounds i8,i8*%aG,i64 16
%aI=bitcast i8*%aH to i8*(i8*,i8*)**
%aJ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aI,align 8
%aK=bitcast i8*%aG to i8**
%aL=load i8*,i8**%aK,align 8
%aM=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aN=call fastcc i8*%aJ(i8*inreg%aL,i8*inreg%aM)
%aO=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%aP=getelementptr inbounds i8,i8*%aO,i64 16
%aQ=bitcast i8*%aP to i8*(i8*,i8*)**
%aR=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aQ,align 8
%aS=bitcast i8*%aO to i8**
%aT=load i8*,i8**%aS,align 8
store i8*%aT,i8**%e,align 8
%aU=load i8**,i8***%D,align 8
%aV=load i8*,i8**%aU,align 8
store i8*%aV,i8**%d,align 8
%aW=getelementptr inbounds i8*,i8**%aU,i64 1
%aX=bitcast i8**%aW to i32*
%aY=load i32,i32*%aX,align 4
%aZ=call i8*@sml_alloc(i32 inreg 28)#0
%a0=getelementptr inbounds i8,i8*%aZ,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 1342177304,i32*%a1,align 4
store i8*%aZ,i8**%g,align 8
%a2=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a3=bitcast i8*%aZ to i8**
store i8*%a2,i8**%a3,align 8
%a4=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a5=getelementptr inbounds i8,i8*%aZ,i64 8
%a6=bitcast i8*%a5 to i8**
store i8*%a4,i8**%a6,align 8
%a7=getelementptr inbounds i8,i8*%aZ,i64 16
%a8=bitcast i8*%a7 to i32*
store i32%aY,i32*%a8,align 4
%a9=getelementptr inbounds i8,i8*%aZ,i64 24
%ba=bitcast i8*%a9 to i32*
store i32 3,i32*%ba,align 4
%bb=call i8*@sml_alloc(i32 inreg 28)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177304,i32*%bd,align 4
%be=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bf=bitcast i8*%bb to i8**
store i8*%be,i8**%bf,align 8
%bg=getelementptr inbounds i8,i8*%bb,i64 8
%bh=bitcast i8*%bg to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLL10analyzeEnv_37 to void(...)*),void(...)**%bh,align 8
%bi=getelementptr inbounds i8,i8*%bb,i64 16
%bj=bitcast i8*%bi to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL10analyzeEnv_45 to void(...)*),void(...)**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bb,i64 24
%bl=bitcast i8*%bk to i32*
store i32 -2147483647,i32*%bl,align 4
%bm=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bn=call fastcc i8*%aR(i8*inreg%bm,i8*inreg%bb)
%bo=getelementptr inbounds i8,i8*%bn,i64 16
%bp=bitcast i8*%bo to i8*(i8*,i8*)**
%bq=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bp,align 8
%br=bitcast i8*%bn to i8**
%bs=load i8*,i8**%br,align 8
%bt=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bu=call fastcc i8*%bq(i8*inreg%bs,i8*inreg%bt)
ret void
}
define internal fastcc void@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_38(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8***
br label%q
l:
call void@sml_check(i32 inreg%h)
%m=load i8*,i8**%c,align 8
%n=bitcast i8**%f to i8****
%o=load i8***,i8****%n,align 8
%p=bitcast i8***%o to i8*
br label%q
q:
%r=phi i8*[%p,%l],[%a,%j]
%s=phi i8***[%o,%l],[%k,%j]
%t=phi i8*[%m,%l],[%b,%j]
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%c,align 8
%w=getelementptr inbounds i8,i8*%t,i64 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%y,i64 24
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
store i8*%B,i8**%e,align 8
%C=load i8**,i8***%s,align 8
%D=load i8*,i8**%C,align 8
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
store i8*%I,i8**%g,align 8
%J=getelementptr inbounds i8,i8*%r,i64 16
%K=bitcast i8*%J to i32*
%L=load i32,i32*%K,align 4
%M=call i8*@sml_alloc(i32 inreg 4)#0
%N=bitcast i8*%M to i32*
%O=getelementptr inbounds i8,i8*%M,i64 -4
%P=bitcast i8*%O to i32*
store i32 4,i32*%P,align 4
store i32%L,i32*%N,align 4
%Q=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%R=call fastcc i8*%G(i8*inreg%Q,i8*inreg%M)
%S=getelementptr inbounds i8,i8*%R,i64 16
%T=bitcast i8*%S to i8*(i8*,i8*)**
%U=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%T,align 8
%V=bitcast i8*%R to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%g,align 8
%X=call i8*@sml_alloc(i32 inreg 20)#0
%Y=getelementptr inbounds i8,i8*%X,i64 -4
%Z=bitcast i8*%Y to i32*
store i32 1342177296,i32*%Z,align 4
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=bitcast i8*%X to i8**
store i8*%aa,i8**%ab,align 8
%ac=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ad=getelementptr inbounds i8,i8*%X,i64 8
%ae=bitcast i8*%ad to i8**
store i8*%ac,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%X,i64 16
%ag=bitcast i8*%af to i32*
store i32 3,i32*%ag,align 4
%ah=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ai=call fastcc i8*%U(i8*inreg%ah,i8*inreg%X)
%aj=load i8*,i8**%f,align 8
%ak=getelementptr inbounds i8,i8*%aj,i64 8
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
%an=load i8*,i8**%e,align 8
tail call fastcc void@_SMLLL10analyzeEnv_36(i8*inreg%am,i8*inreg%an)
ret void
}
define internal fastcc void@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_39(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%q
l:
call void@sml_check(i32 inreg%h)
%m=load i8*,i8**%c,align 8
%n=bitcast i8**%f to i8***
%o=load i8**,i8***%n,align 8
%p=bitcast i8**%o to i8*
br label%q
q:
%r=phi i8*[%p,%l],[%a,%j]
%s=phi i8**[%o,%l],[%k,%j]
%t=phi i8*[%m,%l],[%b,%j]
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%c,align 8
%w=getelementptr inbounds i8,i8*%t,i64 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%d,align 8
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
store i8*%A,i8**%e,align 8
%B=load i8*,i8**%s,align 8
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
%F=getelementptr inbounds i8,i8*%E,i64 16
%G=bitcast i8*%F to i8*(i8*,i8*)**
%H=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%G,align 8
%I=bitcast i8*%E to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%g,align 8
%K=getelementptr inbounds i8,i8*%r,i64 16
%L=bitcast i8*%K to i32*
%M=load i32,i32*%L,align 4
%N=call i8*@sml_alloc(i32 inreg 4)#0
%O=bitcast i8*%N to i32*
%P=getelementptr inbounds i8,i8*%N,i64 -4
%Q=bitcast i8*%P to i32*
store i32 4,i32*%Q,align 4
store i32%M,i32*%O,align 4
%R=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%S=call fastcc i8*%H(i8*inreg%R,i8*inreg%N)
%T=getelementptr inbounds i8,i8*%S,i64 16
%U=bitcast i8*%T to i8*(i8*,i8*)**
%V=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%U,align 8
%W=bitcast i8*%S to i8**
%X=load i8*,i8**%W,align 8
store i8*%X,i8**%g,align 8
%Y=call i8*@sml_alloc(i32 inreg 20)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177296,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ac=bitcast i8*%Y to i8**
store i8*%ab,i8**%ac,align 8
%ad=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ae=getelementptr inbounds i8,i8*%Y,i64 8
%af=bitcast i8*%ae to i8**
store i8*%ad,i8**%af,align 8
%ag=getelementptr inbounds i8,i8*%Y,i64 16
%ah=bitcast i8*%ag to i32*
store i32 3,i32*%ah,align 4
%ai=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aj=call fastcc i8*%V(i8*inreg%ai,i8*inreg%Y)
%ak=load i8*,i8**%f,align 8
%al=getelementptr inbounds i8,i8*%ak,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
%ao=load i8*,i8**%e,align 8
tail call fastcc void@_SMLLL10analyzeEnv_36(i8*inreg%an,i8*inreg%ao)
ret void
}
define internal fastcc void@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_40(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%a,i8**%f,align 8
store i8*%b,i8**%c,align 8
%j=load atomic i32,i32*@sml_check_flag unordered,align 4
%k=icmp eq i32%j,0
br i1%k,label%l,label%o
l:
%m=bitcast i8*%a to i8**
%n=bitcast i8**%f to i8***
br label%s
o:
call void@sml_check(i32 inreg%j)
%p=load i8*,i8**%c,align 8
%q=bitcast i8**%f to i8***
%r=load i8**,i8***%q,align 8
br label%s
s:
%t=phi i8***[%n,%l],[%q,%o]
%u=phi i8**[%m,%l],[%r,%o]
%v=phi i8*[%b,%l],[%p,%o]
%w=bitcast i8*%v to i32**
%x=load i32*,i32**%w,align 8
%y=load i32,i32*%x,align 4
%z=getelementptr inbounds i8,i8*%v,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
store i8*%D,i8**%c,align 8
%E=getelementptr inbounds i8,i8*%B,i64 8
%F=bitcast i8*%E to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%d,align 8
%H=getelementptr inbounds i8,i8*%B,i64 16
%I=bitcast i8*%H to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%e,align 8
%K=load i8*,i8**%u,align 8
store i8*%K,i8**%g,align 8
%L=call i8*@sml_alloc(i32 inreg 20)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
store i8*%L,i8**%h,align 8
%O=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to i32*
store i32%y,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%L,i64 16
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=call i8*@sml_alloc(i32 inreg 28)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177304,i32*%W,align 4
%X=load i8*,i8**%h,align 8
%Y=bitcast i8*%U to i8**
store i8*%X,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%U,i64 8
%aa=bitcast i8*%Z to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLL10analyzeEnv_36 to void(...)*),void(...)**%aa,align 8
%ab=getelementptr inbounds i8,i8*%U,i64 16
%ac=bitcast i8*%ab to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL10analyzeEnv_46 to void(...)*),void(...)**%ac,align 8
%ad=getelementptr inbounds i8,i8*%U,i64 24
%ae=bitcast i8*%ad to i32*
store i32 -2147483647,i32*%ae,align 4
%af=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call fastcc void@_SMLLL10analyzeEnv_36(i8*inreg%X,i8*inreg%af)
%ag=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%ah=getelementptr inbounds i8,i8*%ag,i64 16
%ai=bitcast i8*%ah to i8*(i8*,i8*)**
%aj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ai,align 8
%ak=bitcast i8*%ag to i8**
%al=load i8*,i8**%ak,align 8
store i8*%al,i8**%g,align 8
%am=load i8**,i8***%t,align 8
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%c,align 8
%ao=call i8*@sml_alloc(i32 inreg 28)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177304,i32*%aq,align 4
store i8*%ao,i8**%i,align 8
%ar=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=load i8*,i8**%h,align 8
%au=getelementptr inbounds i8,i8*%ao,i64 8
%av=bitcast i8*%au to i8**
store i8*%at,i8**%av,align 8
%aw=getelementptr inbounds i8,i8*%ao,i64 16
%ax=bitcast i8*%aw to i32*
store i32%y,i32*%ax,align 4
%ay=getelementptr inbounds i8,i8*%ao,i64 24
%az=bitcast i8*%ay to i32*
store i32 3,i32*%az,align 4
%aA=call i8*@sml_alloc(i32 inreg 28)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 1342177304,i32*%aC,align 4
%aD=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aE=bitcast i8*%aA to i8**
store i8*%aD,i8**%aE,align 8
%aF=getelementptr inbounds i8,i8*%aA,i64 8
%aG=bitcast i8*%aF to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_38 to void(...)*),void(...)**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aA,i64 16
%aI=bitcast i8*%aH to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_47 to void(...)*),void(...)**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%aA,i64 24
%aK=bitcast i8*%aJ to i32*
store i32 -2147483647,i32*%aK,align 4
%aL=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aM=call fastcc i8*%aj(i8*inreg%aL,i8*inreg%aA)
%aN=getelementptr inbounds i8,i8*%aM,i64 16
%aO=bitcast i8*%aN to i8*(i8*,i8*)**
%aP=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aO,align 8
%aQ=bitcast i8*%aM to i8**
%aR=load i8*,i8**%aQ,align 8
%aS=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aT=call fastcc i8*%aP(i8*inreg%aR,i8*inreg%aS)
%aU=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%aV=getelementptr inbounds i8,i8*%aU,i64 16
%aW=bitcast i8*%aV to i8*(i8*,i8*)**
%aX=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aW,align 8
%aY=bitcast i8*%aU to i8**
%aZ=load i8*,i8**%aY,align 8
store i8*%aZ,i8**%d,align 8
%a0=load i8**,i8***%t,align 8
store i8*null,i8**%f,align 8
%a1=load i8*,i8**%a0,align 8
store i8*%a1,i8**%c,align 8
%a2=call i8*@sml_alloc(i32 inreg 28)#0
%a3=getelementptr inbounds i8,i8*%a2,i64 -4
%a4=bitcast i8*%a3 to i32*
store i32 1342177304,i32*%a4,align 4
store i8*%a2,i8**%f,align 8
%a5=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a6=bitcast i8*%a2 to i8**
store i8*%a5,i8**%a6,align 8
%a7=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%a8=getelementptr inbounds i8,i8*%a2,i64 8
%a9=bitcast i8*%a8 to i8**
store i8*%a7,i8**%a9,align 8
%ba=getelementptr inbounds i8,i8*%a2,i64 16
%bb=bitcast i8*%ba to i32*
store i32%y,i32*%bb,align 4
%bc=getelementptr inbounds i8,i8*%a2,i64 24
%bd=bitcast i8*%bc to i32*
store i32 3,i32*%bd,align 4
%be=call i8*@sml_alloc(i32 inreg 28)#0
%bf=getelementptr inbounds i8,i8*%be,i64 -4
%bg=bitcast i8*%bf to i32*
store i32 1342177304,i32*%bg,align 4
%bh=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bi=bitcast i8*%be to i8**
store i8*%bh,i8**%bi,align 8
%bj=getelementptr inbounds i8,i8*%be,i64 8
%bk=bitcast i8*%bj to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_39 to void(...)*),void(...)**%bk,align 8
%bl=getelementptr inbounds i8,i8*%be,i64 16
%bm=bitcast i8*%bl to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_48 to void(...)*),void(...)**%bm,align 8
%bn=getelementptr inbounds i8,i8*%be,i64 24
%bo=bitcast i8*%bn to i32*
store i32 -2147483647,i32*%bo,align 4
%bp=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bq=call fastcc i8*%aX(i8*inreg%bp,i8*inreg%be)
%br=getelementptr inbounds i8,i8*%bq,i64 16
%bs=bitcast i8*%br to i8*(i8*,i8*)**
%bt=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bs,align 8
%bu=bitcast i8*%bq to i8**
%bv=load i8*,i8**%bu,align 8
%bw=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bx=call fastcc i8*%bt(i8*inreg%bv,i8*inreg%bw)
ret void
}
define internal fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_41(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
store i8*%f,i8**%c,align 8
%g=call i8*@sml_alloc(i32 inreg 12)#0
%h=getelementptr inbounds i8,i8*%g,i64 -4
%i=bitcast i8*%h to i32*
store i32 1342177288,i32*%i,align 4
store i8*%g,i8**%d,align 8
%j=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%k=bitcast i8*%g to i8**
store i8*%j,i8**%k,align 8
%l=getelementptr inbounds i8,i8*%g,i64 8
%m=bitcast i8*%l to i32*
store i32 1,i32*%m,align 4
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
%q=load i8*,i8**%d,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%n,i64 8
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_40 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%n,i64 16
%v=bitcast i8*%u to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_49 to void(...)*),void(...)**%v,align 8
%w=getelementptr inbounds i8,i8*%n,i64 24
%x=bitcast i8*%w to i32*
store i32 -2147483647,i32*%x,align 4
ret i8*%n
}
define internal fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_42(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%i
g:
%h=bitcast i8*%a to i8**
br label%m
i:
call void@sml_check(i32 inreg%e)
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=load i8*,i8**%n,align 8
%q=tail call fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_41(i8*inreg%p,i8*inreg%o)
ret i8*%q
}
define fastcc i8*@_SMLFN13AnalyzeTopEnv13analyzeTopEnvE(i8*inreg%a)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_41 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_41 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
%v=call i8*@sml_alloc(i32 inreg 12)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177288,i32*%x,align 4
store i8*%v,i8**%b,align 8
%y=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=getelementptr inbounds i8,i8*%v,i64 8
%B=bitcast i8*%A to i32*
store i32 1,i32*%B,align 4
%C=call i8*@sml_alloc(i32 inreg 28)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177304,i32*%E,align 4
%F=load i8*,i8**%b,align 8
%G=bitcast i8*%C to i8**
store i8*%F,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%C,i64 8
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_42 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_42 to void(...)*),void(...)**%K,align 8
%L=getelementptr inbounds i8,i8*%C,i64 24
%M=bitcast i8*%L to i32*
store i32 -2147483647,i32*%M,align 4
ret i8*%C
}
define internal fastcc i8*@_SMLLL10analyzeEnv_45(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLL10analyzeEnv_37(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLL10analyzeEnv_46(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLL10analyzeEnv_36(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_47(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_38(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_48(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_39(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_49(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_40(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN13AnalyzeTopEnv13analyzeTopEnvE_50(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN13AnalyzeTopEnv13analyzeTopEnvE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
