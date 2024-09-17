@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN13AnalyzeTopEnv13analyzeTopEnvE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_52 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN13AnalyzeTopEnv13analyzeTopEnvE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SML_ftab737b34eb3cf2dc08_AnalyzeTopEnv=external global i8
@b=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@_SMLFN9SymbolEnv4appiE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main44ca35c4c731682b_Symbol()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load44ca35c4c731682b_Symbol(i8*)local_unnamed_addr
define private void@_SML_tabb737b34eb3cf2dc08_AnalyzeTopEnv()#2{
unreachable
}
define void@_SML_load737b34eb3cf2dc08_AnalyzeTopEnv(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@b,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@b,align 1
tail call void@_SML_load44ca35c4c731682b_Symbol(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb737b34eb3cf2dc08_AnalyzeTopEnv,i8*@_SML_ftab737b34eb3cf2dc08_AnalyzeTopEnv,i8*null)#0
ret void
}
define void@_SML_main737b34eb3cf2dc08_AnalyzeTopEnv()local_unnamed_addr#1 gc"smlsharp"{
tail call void@_SML_main44ca35c4c731682b_Symbol()#1
ret void
}
define internal fastcc void@_SMLL10analyzeEnv_36(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%i,label%k
i:
%j=bitcast i8*%a to i8**
br label%p
k:
call void@sml_check(i32 inreg%g)
%l=load i8*,i8**%c,align 8
%m=bitcast i8**%e to i8***
%n=load i8**,i8***%m,align 8
%o=bitcast i8**%n to i8*
br label%p
p:
%q=phi i8*[%o,%k],[%a,%i]
%r=phi i8**[%n,%k],[%j,%i]
%s=phi i8*[%l,%k],[%b,%i]
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=getelementptr inbounds i8,i8*%s,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%d,align 8
%y=load i8*,i8**%r,align 8
%z=getelementptr inbounds i8,i8*%y,i64 24
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
%F=bitcast i8*%B to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%f,align 8
%H=getelementptr inbounds i8,i8*%q,i64 8
%I=bitcast i8*%H to i32***
%J=load i32**,i32***%I,align 8
%K=load i32*,i32**%J,align 8
%L=load i32,i32*%K,align 4
%M=call i8*@sml_alloc(i32 inreg 4)#0
%N=bitcast i8*%M to i32*
%O=getelementptr inbounds i8,i8*%M,i64 -4
%P=bitcast i8*%O to i32*
store i32 4,i32*%P,align 4
store i32%L,i32*%N,align 4
%Q=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%R=call fastcc i8*%E(i8*inreg%Q,i8*inreg%M)
%S=getelementptr inbounds i8,i8*%R,i64 16
%T=bitcast i8*%S to i8*(i8*,i8*)**
%U=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%T,align 8
%V=bitcast i8*%R to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%f,align 8
%X=call i8*@sml_alloc(i32 inreg 20)#0
%Y=getelementptr inbounds i8,i8*%X,i64 -4
%Z=bitcast i8*%Y to i32*
store i32 1342177296,i32*%Z,align 4
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=bitcast i8*%X to i8**
store i8*%aa,i8**%ab,align 8
%ac=load i8*,i8**%d,align 8
%ad=getelementptr inbounds i8,i8*%X,i64 8
%ae=bitcast i8*%ad to i8**
store i8*%ac,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%X,i64 16
%ag=bitcast i8*%af to i32*
store i32 3,i32*%ag,align 4
%ah=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ai=call fastcc i8*%U(i8*inreg%ah,i8*inreg%X)
%aj=load i8*,i8**%e,align 8
%ak=getelementptr inbounds i8,i8*%aj,i64 16
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
%an=load i8*,i8**%d,align 8
%ao=getelementptr inbounds i8,i8*%an,i64 8
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
tail call fastcc void@_SMLL10analyzeEnv_35(i8*inreg%am,i8*inreg%aq)
ret void
}
define internal fastcc void@_SMLL10analyzeEnv_35(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%j,label%k,label%m
k:
%l=bitcast i8*%b to i8**
br label%p
m:
call void@sml_check(i32 inreg%i)
%n=bitcast i8**%c to i8***
%o=load i8**,i8***%n,align 8
br label%p
p:
%q=phi i8**[%o,%m],[%l,%k]
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%g,align 8
%s=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%f,align 8
%y=bitcast i8**%d to i8***
%z=load i8**,i8***%y,align 8
%A=load i8*,i8**%z,align 8
%B=getelementptr inbounds i8,i8*%A,i64 8
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
store i8*%I,i8**%e,align 8
%J=getelementptr inbounds i8*,i8**%z,i64 1
%K=bitcast i8**%J to i32***
%L=load i32**,i32***%K,align 8
%M=load i32*,i32**%L,align 8
%N=load i32,i32*%M,align 4
%O=call i8*@sml_alloc(i32 inreg 4)#0
%P=bitcast i8*%O to i32*
%Q=getelementptr inbounds i8,i8*%O,i64 -4
%R=bitcast i8*%Q to i32*
store i32 4,i32*%R,align 4
store i32%N,i32*%P,align 4
%S=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%T=call fastcc i8*%G(i8*inreg%S,i8*inreg%O)
%U=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%V=call fastcc i8*%v(i8*inreg%U,i8*inreg%T)
%W=getelementptr inbounds i8,i8*%V,i64 16
%X=bitcast i8*%W to i8*(i8*,i8*)**
%Y=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%X,align 8
%Z=bitcast i8*%V to i8**
%aa=load i8*,i8**%Z,align 8
%ab=load i8*,i8**%c,align 8
%ac=getelementptr inbounds i8,i8*%ab,i64 16
%ad=bitcast i8*%ac to i8**
%ae=load i8*,i8**%ad,align 8
%af=call fastcc i8*%Y(i8*inreg%aa,i8*inreg%ae)
%ag=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%ah=getelementptr inbounds i8,i8*%ag,i64 16
%ai=bitcast i8*%ah to i8*(i8*,i8*)**
%aj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ai,align 8
%ak=bitcast i8*%ag to i8**
%al=load i8*,i8**%ak,align 8
store i8*%al,i8**%f,align 8
%am=load i8**,i8***%y,align 8
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
%ax=bitcast i8**%aw to i32***
%ay=load i32**,i32***%ax,align 8
%az=load i32*,i32**%ay,align 8
%aA=load i32,i32*%az,align 4
%aB=call i8*@sml_alloc(i32 inreg 4)#0
%aC=bitcast i8*%aB to i32*
%aD=getelementptr inbounds i8,i8*%aB,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 4,i32*%aE,align 4
store i32%aA,i32*%aC,align 4
%aF=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aG=call fastcc i8*%at(i8*inreg%aF,i8*inreg%aB)
%aH=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aI=call fastcc i8*%aj(i8*inreg%aH,i8*inreg%aG)
%aJ=getelementptr inbounds i8,i8*%aI,i64 16
%aK=bitcast i8*%aJ to i8*(i8*,i8*)**
%aL=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aK,align 8
%aM=bitcast i8*%aI to i8**
%aN=load i8*,i8**%aM,align 8
%aO=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aP=getelementptr inbounds i8,i8*%aO,i64 8
%aQ=bitcast i8*%aP to i8**
%aR=load i8*,i8**%aQ,align 8
%aS=call fastcc i8*%aL(i8*inreg%aN,i8*inreg%aR)
%aT=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%aU=getelementptr inbounds i8,i8*%aT,i64 16
%aV=bitcast i8*%aU to i8*(i8*,i8*)**
%aW=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aV,align 8
%aX=bitcast i8*%aT to i8**
%aY=load i8*,i8**%aX,align 8
store i8*%aY,i8**%f,align 8
%aZ=load i8**,i8***%y,align 8
%a0=load i8*,i8**%aZ,align 8
store i8*%a0,i8**%c,align 8
%a1=getelementptr inbounds i8*,i8**%aZ,i64 1
%a2=load i8*,i8**%a1,align 8
store i8*%a2,i8**%e,align 8
%a3=call i8*@sml_alloc(i32 inreg 28)#0
%a4=getelementptr inbounds i8,i8*%a3,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177304,i32*%a5,align 4
store i8*%a3,i8**%h,align 8
%a6=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a7=bitcast i8*%a3 to i8**
store i8*%a6,i8**%a7,align 8
%a8=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%a9=getelementptr inbounds i8,i8*%a3,i64 8
%ba=bitcast i8*%a9 to i8**
store i8*%a8,i8**%ba,align 8
%bb=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bc=getelementptr inbounds i8,i8*%a3,i64 16
%bd=bitcast i8*%bc to i8**
store i8*%bb,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%a3,i64 24
%bf=bitcast i8*%be to i32*
store i32 7,i32*%bf,align 4
%bg=call i8*@sml_alloc(i32 inreg 28)#0
%bh=getelementptr inbounds i8,i8*%bg,i64 -4
%bi=bitcast i8*%bh to i32*
store i32 1342177304,i32*%bi,align 4
%bj=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bk=bitcast i8*%bg to i8**
store i8*%bj,i8**%bk,align 8
%bl=getelementptr inbounds i8,i8*%bg,i64 8
%bm=bitcast i8*%bl to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLL10analyzeEnv_36 to void(...)*),void(...)**%bm,align 8
%bn=getelementptr inbounds i8,i8*%bg,i64 16
%bo=bitcast i8*%bn to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL10analyzeEnv_46 to void(...)*),void(...)**%bo,align 8
%bp=getelementptr inbounds i8,i8*%bg,i64 24
%bq=bitcast i8*%bp to i32*
store i32 -2147483647,i32*%bq,align 4
%br=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bs=call fastcc i8*%aW(i8*inreg%br,i8*inreg%bg)
%bt=getelementptr inbounds i8,i8*%bs,i64 16
%bu=bitcast i8*%bt to i8*(i8*,i8*)**
%bv=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bu,align 8
%bw=bitcast i8*%bs to i8**
%bx=load i8*,i8**%bw,align 8
%by=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bz=call fastcc i8*%bv(i8*inreg%bx,i8*inreg%by)
ret void
}
define internal fastcc void@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_37(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%i,label%k
i:
%j=bitcast i8*%a to i8***
br label%p
k:
call void@sml_check(i32 inreg%g)
%l=load i8*,i8**%c,align 8
%m=bitcast i8**%e to i8****
%n=load i8***,i8****%m,align 8
%o=bitcast i8***%n to i8*
br label%p
p:
%q=phi i8*[%o,%k],[%a,%i]
%r=phi i8***[%n,%k],[%j,%i]
%s=phi i8*[%l,%k],[%b,%i]
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=getelementptr inbounds i8,i8*%s,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%d,align 8
%y=load i8**,i8***%r,align 8
%z=load i8*,i8**%y,align 8
%A=getelementptr inbounds i8,i8*%z,i64 16
%B=bitcast i8*%A to i8*(i8*,i8*)**
%C=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%B,align 8
%D=bitcast i8*%z to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%f,align 8
%F=getelementptr inbounds i8,i8*%q,i64 8
%G=bitcast i8*%F to i32***
%H=load i32**,i32***%G,align 8
%I=load i32*,i32**%H,align 8
%J=load i32,i32*%I,align 4
%K=call i8*@sml_alloc(i32 inreg 4)#0
%L=bitcast i8*%K to i32*
%M=getelementptr inbounds i8,i8*%K,i64 -4
%N=bitcast i8*%M to i32*
store i32 4,i32*%N,align 4
store i32%J,i32*%L,align 4
%O=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%P=call fastcc i8*%C(i8*inreg%O,i8*inreg%K)
%Q=getelementptr inbounds i8,i8*%P,i64 16
%R=bitcast i8*%Q to i8*(i8*,i8*)**
%S=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%R,align 8
%T=bitcast i8*%P to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%f,align 8
%V=call i8*@sml_alloc(i32 inreg 20)#0
%W=getelementptr inbounds i8,i8*%V,i64 -4
%X=bitcast i8*%W to i32*
store i32 1342177296,i32*%X,align 4
%Y=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%Z=bitcast i8*%V to i8**
store i8*%Y,i8**%Z,align 8
%aa=load i8*,i8**%d,align 8
%ab=getelementptr inbounds i8,i8*%V,i64 8
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%V,i64 16
%ae=bitcast i8*%ad to i32*
store i32 3,i32*%ae,align 4
%af=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ag=call fastcc i8*%S(i8*inreg%af,i8*inreg%V)
%ah=load i8*,i8**%e,align 8
%ai=getelementptr inbounds i8,i8*%ah,i64 16
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
%al=load i8*,i8**%d,align 8
%am=getelementptr inbounds i8,i8*%al,i64 24
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
tail call fastcc void@_SMLL10analyzeEnv_35(i8*inreg%ak,i8*inreg%ao)
ret void
}
define internal fastcc void@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_38(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%i,label%k
i:
%j=bitcast i8*%a to i8**
br label%p
k:
call void@sml_check(i32 inreg%g)
%l=load i8*,i8**%c,align 8
%m=bitcast i8**%e to i8***
%n=load i8**,i8***%m,align 8
%o=bitcast i8**%n to i8*
br label%p
p:
%q=phi i8*[%o,%k],[%a,%i]
%r=phi i8**[%n,%k],[%j,%i]
%s=phi i8*[%l,%k],[%b,%i]
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=getelementptr inbounds i8,i8*%s,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%d,align 8
%y=load i8*,i8**%r,align 8
%z=getelementptr inbounds i8,i8*%y,i64 16
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
%F=bitcast i8*%B to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%f,align 8
%H=getelementptr inbounds i8,i8*%q,i64 8
%I=bitcast i8*%H to i32***
%J=load i32**,i32***%I,align 8
%K=load i32*,i32**%J,align 8
%L=load i32,i32*%K,align 4
%M=call i8*@sml_alloc(i32 inreg 4)#0
%N=bitcast i8*%M to i32*
%O=getelementptr inbounds i8,i8*%M,i64 -4
%P=bitcast i8*%O to i32*
store i32 4,i32*%P,align 4
store i32%L,i32*%N,align 4
%Q=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%R=call fastcc i8*%E(i8*inreg%Q,i8*inreg%M)
%S=getelementptr inbounds i8,i8*%R,i64 16
%T=bitcast i8*%S to i8*(i8*,i8*)**
%U=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%T,align 8
%V=bitcast i8*%R to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%f,align 8
%X=call i8*@sml_alloc(i32 inreg 20)#0
%Y=getelementptr inbounds i8,i8*%X,i64 -4
%Z=bitcast i8*%Y to i32*
store i32 1342177296,i32*%Z,align 4
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=bitcast i8*%X to i8**
store i8*%aa,i8**%ab,align 8
%ac=load i8*,i8**%d,align 8
%ad=getelementptr inbounds i8,i8*%X,i64 8
%ae=bitcast i8*%ad to i8**
store i8*%ac,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%X,i64 16
%ag=bitcast i8*%af to i32*
store i32 3,i32*%ag,align 4
%ah=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ai=call fastcc i8*%U(i8*inreg%ah,i8*inreg%X)
%aj=load i8*,i8**%e,align 8
%ak=getelementptr inbounds i8,i8*%aj,i64 16
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
%an=bitcast i8**%d to i8***
%ao=load i8**,i8***%an,align 8
%ap=load i8*,i8**%ao,align 8
tail call fastcc void@_SMLL10analyzeEnv_35(i8*inreg%am,i8*inreg%ap)
ret void
}
define internal fastcc void@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_39(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%j,label%k,label%n
k:
%l=bitcast i8*%a to i8**
%m=bitcast i8**%d to i8***
br label%q
n:
call void@sml_check(i32 inreg%i)
%o=bitcast i8**%d to i8***
%p=load i8**,i8***%o,align 8
br label%q
q:
%r=phi i8***[%m,%k],[%o,%n]
%s=phi i8**[%l,%k],[%p,%n]
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%e,align 8
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
store i8*%u,i8**%g,align 8
%x=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=load i8*,i8**%c,align 8
%A=getelementptr inbounds i8,i8*%u,i64 8
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%u,i64 16
%D=bitcast i8*%C to i32*
store i32 3,i32*%D,align 4
%E=call i8*@sml_alloc(i32 inreg 28)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32 1342177304,i32*%G,align 4
%H=load i8*,i8**%g,align 8
%I=bitcast i8*%E to i8**
store i8*%H,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%E,i64 8
%K=bitcast i8*%J to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLL10analyzeEnv_35 to void(...)*),void(...)**%K,align 8
%L=getelementptr inbounds i8,i8*%E,i64 16
%M=bitcast i8*%L to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL10analyzeEnv_47 to void(...)*),void(...)**%M,align 8
%N=getelementptr inbounds i8,i8*%E,i64 24
%O=bitcast i8*%N to i32*
store i32 -2147483647,i32*%O,align 4
%P=load i8*,i8**%c,align 8
%Q=getelementptr inbounds i8,i8*%P,i64 8
%R=bitcast i8*%Q to i8***
%S=load i8**,i8***%R,align 8
%T=load i8*,i8**%S,align 8
call fastcc void@_SMLL10analyzeEnv_35(i8*inreg%H,i8*inreg%T)
%U=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%V=getelementptr inbounds i8,i8*%U,i64 16
%W=bitcast i8*%V to i8*(i8*,i8*)**
%X=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%W,align 8
%Y=bitcast i8*%U to i8**
%Z=load i8*,i8**%Y,align 8
store i8*%Z,i8**%f,align 8
%aa=load i8**,i8***%r,align 8
%ab=load i8*,i8**%aa,align 8
store i8*%ab,i8**%e,align 8
%ac=call i8*@sml_alloc(i32 inreg 28)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177304,i32*%ae,align 4
store i8*%ac,i8**%h,align 8
%af=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ag=bitcast i8*%ac to i8**
store i8*%af,i8**%ag,align 8
%ah=load i8*,i8**%c,align 8
%ai=getelementptr inbounds i8,i8*%ac,i64 8
%aj=bitcast i8*%ai to i8**
store i8*%ah,i8**%aj,align 8
%ak=load i8*,i8**%g,align 8
%al=getelementptr inbounds i8,i8*%ac,i64 16
%am=bitcast i8*%al to i8**
store i8*%ak,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%ac,i64 24
%ao=bitcast i8*%an to i32*
store i32 7,i32*%ao,align 4
%ap=call i8*@sml_alloc(i32 inreg 28)#0
%aq=getelementptr inbounds i8,i8*%ap,i64 -4
%ar=bitcast i8*%aq to i32*
store i32 1342177304,i32*%ar,align 4
%as=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%at=bitcast i8*%ap to i8**
store i8*%as,i8**%at,align 8
%au=getelementptr inbounds i8,i8*%ap,i64 8
%av=bitcast i8*%au to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_37 to void(...)*),void(...)**%av,align 8
%aw=getelementptr inbounds i8,i8*%ap,i64 16
%ax=bitcast i8*%aw to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_48 to void(...)*),void(...)**%ax,align 8
%ay=getelementptr inbounds i8,i8*%ap,i64 24
%az=bitcast i8*%ay to i32*
store i32 -2147483647,i32*%az,align 4
%aA=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aB=call fastcc i8*%X(i8*inreg%aA,i8*inreg%ap)
%aC=getelementptr inbounds i8,i8*%aB,i64 16
%aD=bitcast i8*%aC to i8*(i8*,i8*)**
%aE=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aD,align 8
%aF=bitcast i8*%aB to i8**
%aG=load i8*,i8**%aF,align 8
%aH=load i8*,i8**%c,align 8
%aI=getelementptr inbounds i8,i8*%aH,i64 8
%aJ=bitcast i8*%aI to i8**
%aK=load i8*,i8**%aJ,align 8
%aL=getelementptr inbounds i8,i8*%aK,i64 8
%aM=bitcast i8*%aL to i8**
%aN=load i8*,i8**%aM,align 8
%aO=call fastcc i8*%aE(i8*inreg%aG,i8*inreg%aN)
%aP=call fastcc i8*@_SMLFN9SymbolEnv4appiE(i32 inreg 1,i32 inreg 8)
%aQ=getelementptr inbounds i8,i8*%aP,i64 16
%aR=bitcast i8*%aQ to i8*(i8*,i8*)**
%aS=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aR,align 8
%aT=bitcast i8*%aP to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%e,align 8
%aV=load i8**,i8***%r,align 8
%aW=load i8*,i8**%aV,align 8
store i8*%aW,i8**%d,align 8
%aX=call i8*@sml_alloc(i32 inreg 28)#0
%aY=getelementptr inbounds i8,i8*%aX,i64 -4
%aZ=bitcast i8*%aY to i32*
store i32 1342177304,i32*%aZ,align 4
store i8*%aX,i8**%f,align 8
%a0=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a1=bitcast i8*%aX to i8**
store i8*%a0,i8**%a1,align 8
%a2=load i8*,i8**%c,align 8
%a3=getelementptr inbounds i8,i8*%aX,i64 8
%a4=bitcast i8*%a3 to i8**
store i8*%a2,i8**%a4,align 8
%a5=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%a6=getelementptr inbounds i8,i8*%aX,i64 16
%a7=bitcast i8*%a6 to i8**
store i8*%a5,i8**%a7,align 8
%a8=getelementptr inbounds i8,i8*%aX,i64 24
%a9=bitcast i8*%a8 to i32*
store i32 7,i32*%a9,align 4
%ba=call i8*@sml_alloc(i32 inreg 28)#0
%bb=getelementptr inbounds i8,i8*%ba,i64 -4
%bc=bitcast i8*%bb to i32*
store i32 1342177304,i32*%bc,align 4
%bd=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%be=bitcast i8*%ba to i8**
store i8*%bd,i8**%be,align 8
%bf=getelementptr inbounds i8,i8*%ba,i64 8
%bg=bitcast i8*%bf to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_38 to void(...)*),void(...)**%bg,align 8
%bh=getelementptr inbounds i8,i8*%ba,i64 16
%bi=bitcast i8*%bh to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_49 to void(...)*),void(...)**%bi,align 8
%bj=getelementptr inbounds i8,i8*%ba,i64 24
%bk=bitcast i8*%bj to i32*
store i32 -2147483647,i32*%bk,align 4
%bl=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bm=call fastcc i8*%aS(i8*inreg%bl,i8*inreg%ba)
%bn=getelementptr inbounds i8,i8*%bm,i64 16
%bo=bitcast i8*%bn to i8*(i8*,i8*)**
%bp=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bo,align 8
%bq=bitcast i8*%bm to i8**
%br=load i8*,i8**%bq,align 8
%bs=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bt=getelementptr inbounds i8,i8*%bs,i64 8
%bu=bitcast i8*%bt to i8**
%bv=load i8*,i8**%bu,align 8
%bw=getelementptr inbounds i8,i8*%bv,i64 16
%bx=bitcast i8*%bw to i8**
%by=load i8*,i8**%bx,align 8
%bz=call fastcc i8*%bp(i8*inreg%br,i8*inreg%by)
ret void
}
define internal fastcc i8*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_40(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_39 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%n,i64 16
%v=bitcast i8*%u to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_50 to void(...)*),void(...)**%v,align 8
%w=getelementptr inbounds i8,i8*%n,i64 24
%x=bitcast i8*%w to i32*
store i32 -2147483647,i32*%x,align 4
ret i8*%n
}
define internal fastcc i8*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_43(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
%v=tail call fastcc i8*%s(i8*inreg%u,i8*inreg%o)
ret i8*%v
}
define fastcc i8*@_SMLFN13AnalyzeTopEnv13analyzeTopEnvE(i8*inreg%a)#1 gc"smlsharp"{
l:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%j,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%d,align 8
br label%j
j:
%k=phi i8*[%i,%h],[%a,%l]
store i8*null,i8**%d,align 8
%m=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%m)
%n=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%n)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%k,i8**%b,align 8
%o=call i8*@sml_alloc(i32 inreg 12)#0
%p=getelementptr inbounds i8,i8*%o,i64 -4
%q=bitcast i8*%p to i32*
store i32 1342177288,i32*%q,align 4
store i8*%o,i8**%c,align 8
%r=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%s=bitcast i8*%o to i8**
store i8*%r,i8**%s,align 8
%t=getelementptr inbounds i8,i8*%o,i64 8
%u=bitcast i8*%t to i32*
store i32 1,i32*%u,align 4
%v=call i8*@sml_alloc(i32 inreg 28)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177304,i32*%x,align 4
%y=load i8*,i8**%c,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=getelementptr inbounds i8,i8*%v,i64 8
%B=bitcast i8*%A to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_40 to void(...)*),void(...)**%B,align 8
%C=getelementptr inbounds i8,i8*%v,i64 16
%D=bitcast i8*%C to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_40 to void(...)*),void(...)**%D,align 8
%E=getelementptr inbounds i8,i8*%v,i64 24
%F=bitcast i8*%E to i32*
store i32 -2147483647,i32*%F,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%m)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%n)
store i8*%v,i8**%d,align 8
%G=call i8*@sml_alloc(i32 inreg 12)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177288,i32*%I,align 4
store i8*%G,i8**%e,align 8
%J=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i32*
store i32 1,i32*%M,align 4
%N=call i8*@sml_alloc(i32 inreg 28)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177304,i32*%P,align 4
%Q=load i8*,i8**%e,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%N,i64 8
%T=bitcast i8*%S to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_43 to void(...)*),void(...)**%T,align 8
%U=getelementptr inbounds i8,i8*%N,i64 16
%V=bitcast i8*%U to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_43 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%N,i64 24
%X=bitcast i8*%W to i32*
store i32 -2147483647,i32*%X,align 4
ret i8*%N
}
define internal fastcc i8*@_SMLL10analyzeEnv_46(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLL10analyzeEnv_36(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLL10analyzeEnv_47(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLL10analyzeEnv_35(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_48(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_37(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_49(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_38(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_50(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_39(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN13AnalyzeTopEnv13analyzeTopEnvE_52(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN13AnalyzeTopEnv13analyzeTopEnvE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
