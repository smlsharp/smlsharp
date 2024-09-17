@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 5,i32 1,i32 0}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 0,[4x i8]zeroinitializer,i32 0}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 1,i32 1,i32 -1,[4x i8]zeroinitializer,i32 0}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN13AssocResolver7resolveE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AssocResolver7resolveE_94 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN13AssocResolver7resolveE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SML_ftab9f229ed282d01639_AssocResolver=external global i8
@f=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
define private void@_SML_tabb9f229ed282d01639_AssocResolver()#1{
unreachable
}
define void@_SML_load9f229ed282d01639_AssocResolver(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@f,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@f,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb9f229ed282d01639_AssocResolver,i8*@_SML_ftab9f229ed282d01639_AssocResolver,i8*null)#0
ret void
}
define void@_SML_main9f229ed282d01639_AssocResolver()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
define internal fastcc i8*@_SMLL14encloseSymbols_76(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%g=bitcast i8*%a to i8**
%h=load i8*,i8**%g,align 8
%i=getelementptr inbounds i8,i8*%h,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%e,align 8
%l=call i8*@sml_alloc(i32 inreg 20)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177296,i32*%n,align 4
store i8*%l,i8**%f,align 8
%o=getelementptr inbounds i8,i8*%l,i64 4
%p=bitcast i8*%o to i32*
store i32 0,i32*%p,align 1
%q=bitcast i8*%l to i32*
store i32 1,i32*%q,align 4
%r=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%s=getelementptr inbounds i8,i8*%l,i64 8
%t=bitcast i8*%s to i8**
store i8*%r,i8**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 16
%v=bitcast i8*%u to i32*
store i32 2,i32*%v,align 4
%w=call i8*@sml_alloc(i32 inreg 20)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177296,i32*%y,align 4
store i8*%w,i8**%e,align 8
%z=getelementptr inbounds i8,i8*%w,i64 4
%A=bitcast i8*%z to i32*
store i32 0,i32*%A,align 1
%B=bitcast i8*%w to i32*
store i32 6,i32*%B,align 4
%C=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%D=getelementptr inbounds i8,i8*%w,i64 8
%E=bitcast i8*%D to i8**
store i8*%C,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%w,i64 16
%G=bitcast i8*%F to i32*
store i32 2,i32*%G,align 4
%H=call i8*@sml_alloc(i32 inreg 20)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177296,i32*%J,align 4
store i8*%H,i8**%f,align 8
%K=getelementptr inbounds i8,i8*%H,i64 4
%L=bitcast i8*%K to i32*
store i32 0,i32*%L,align 1
%M=bitcast i8*%H to i32*
store i32 4,i32*%M,align 4
%N=load i8*,i8**%c,align 8
%O=getelementptr inbounds i8,i8*%H,i64 8
%P=bitcast i8*%O to i8**
store i8*%N,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%H,i64 16
%R=bitcast i8*%Q to i32*
store i32 2,i32*%R,align 4
%S=bitcast i8**%d to i8***
%T=load i8**,i8***%S,align 8
store i8*null,i8**%d,align 8
%U=load i8*,i8**%T,align 8
%V=getelementptr inbounds i8,i8*%U,i64 16
%W=bitcast i8*%V to i8**
%X=load i8*,i8**%W,align 8
store i8*%X,i8**%c,align 8
%Y=call i8*@sml_alloc(i32 inreg 20)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177296,i32*%aa,align 4
store i8*%Y,i8**%d,align 8
%ab=getelementptr inbounds i8,i8*%Y,i64 4
%ac=bitcast i8*%ab to i32*
store i32 0,i32*%ac,align 1
%ad=bitcast i8*%Y to i32*
store i32 1,i32*%ad,align 4
%ae=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%af=getelementptr inbounds i8,i8*%Y,i64 8
%ag=bitcast i8*%af to i8**
store i8*%ae,i8**%ag,align 8
%ah=getelementptr inbounds i8,i8*%Y,i64 16
%ai=bitcast i8*%ah to i32*
store i32 2,i32*%ai,align 4
%aj=call i8*@sml_alloc(i32 inreg 20)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32 1342177296,i32*%al,align 4
store i8*%aj,i8**%c,align 8
%am=getelementptr inbounds i8,i8*%aj,i64 4
%an=bitcast i8*%am to i32*
store i32 0,i32*%an,align 1
%ao=bitcast i8*%aj to i32*
store i32 6,i32*%ao,align 4
%ap=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aq=getelementptr inbounds i8,i8*%aj,i64 8
%ar=bitcast i8*%aq to i8**
store i8*%ap,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%aj,i64 16
%at=bitcast i8*%as to i32*
store i32 2,i32*%at,align 4
%au=call i8*@sml_alloc(i32 inreg 20)#0
%av=getelementptr inbounds i8,i8*%au,i64 -4
%aw=bitcast i8*%av to i32*
store i32 1342177296,i32*%aw,align 4
store i8*%au,i8**%d,align 8
%ax=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ay=bitcast i8*%au to i8**
store i8*%ax,i8**%ay,align 8
%az=getelementptr inbounds i8,i8*%au,i64 8
%aA=bitcast i8*%az to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@c,i64 0,i32 2)to i8*),i8**%aA,align 8
%aB=getelementptr inbounds i8,i8*%au,i64 16
%aC=bitcast i8*%aB to i32*
store i32 3,i32*%aC,align 4
%aD=call i8*@sml_alloc(i32 inreg 20)#0
%aE=getelementptr inbounds i8,i8*%aD,i64 -4
%aF=bitcast i8*%aE to i32*
store i32 1342177296,i32*%aF,align 4
store i8*%aD,i8**%c,align 8
%aG=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aH=bitcast i8*%aD to i8**
store i8*%aG,i8**%aH,align 8
%aI=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aJ=getelementptr inbounds i8,i8*%aD,i64 8
%aK=bitcast i8*%aJ to i8**
store i8*%aI,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aD,i64 16
%aM=bitcast i8*%aL to i32*
store i32 3,i32*%aM,align 4
%aN=call i8*@sml_alloc(i32 inreg 20)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177296,i32*%aP,align 4
store i8*%aN,i8**%d,align 8
%aQ=bitcast i8*%aN to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@a,i64 0,i32 2)to i8*),i8**%aQ,align 8
%aR=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aS=getelementptr inbounds i8,i8*%aN,i64 8
%aT=bitcast i8*%aS to i8**
store i8*%aR,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aN,i64 16
%aV=bitcast i8*%aU to i32*
store i32 3,i32*%aV,align 4
%aW=call i8*@sml_alloc(i32 inreg 20)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177296,i32*%aY,align 4
%aZ=load i8*,i8**%e,align 8
%a0=bitcast i8*%aW to i8**
store i8*%aZ,i8**%a0,align 8
%a1=load i8*,i8**%d,align 8
%a2=getelementptr inbounds i8,i8*%aW,i64 8
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aW,i64 16
%a5=bitcast i8*%a4 to i32*
store i32 3,i32*%a5,align 4
ret i8*%aW
}
define internal fastcc i8*@_SMLL5revFE_78(i8*inreg%a,i8*inreg%b,i8*inreg%c)unnamed_addr#3 gc"smlsharp"{
j:
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%f,align 8
store i8*%b,i8**%e,align 8
store i8*%c,i8**%d,align 8
br label%h
h:
%i=phi i8*[%b,%j],[%F,%E]
%k=phi i8*[%c,%j],[%G,%E]
%l=load atomic i32,i32*@sml_check_flag unordered,align 4
%m=icmp eq i32%l,0
br i1%m,label%q,label%n
n:
call void@sml_check(i32 inreg%l)
%o=load i8*,i8**%d,align 8
%p=load i8*,i8**%e,align 8
br label%q
q:
%r=phi i8*[%p,%n],[%i,%h]
%s=phi i8*[%o,%n],[%k,%h]
%t=load i8*,i8**%f,align 8
%u=icmp eq i8*%t,null
br i1%u,label%v,label%H
v:
%w=icmp eq i8*%r,null
br i1%w,label%x,label%y
x:
ret i8*%s
y:
%z=bitcast i8*%r to i8**
%A=load i8*,i8**%z,align 8
%B=getelementptr inbounds i8,i8*%r,i64 8
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
store i8*%A,i8**%f,align 8
store i8*%D,i8**%e,align 8
store i8*%s,i8**%d,align 8
br label%E
E:
%F=phi i8*[%D,%y],[%ab,%N],[%ak,%ad]
%G=phi i8*[%s,%y],[%R,%N],[%au,%ad]
br label%h
H:
%I=bitcast i8*%t to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%f,align 8
%K=bitcast i8*%J to i32*
%L=load i32,i32*%K,align 4
%M=icmp eq i32%L,4
br i1%M,label%ad,label%N
N:
%O=getelementptr inbounds i8,i8*%t,i64 8
%P=bitcast i8*%O to i8**
%Q=load i8*,i8**%P,align 8
store i8*%Q,i8**%g,align 8
%R=call i8*@sml_alloc(i32 inreg 20)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177296,i32*%T,align 4
%U=load i8*,i8**%f,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=load i8*,i8**%d,align 8
%X=getelementptr inbounds i8,i8*%R,i64 8
%Y=bitcast i8*%X to i8**
store i8*%W,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%R,i64 16
%aa=bitcast i8*%Z to i32*
store i32 3,i32*%aa,align 4
%ab=load i8*,i8**%e,align 8
%ac=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
store i8*%ac,i8**%f,align 8
store i8*%ab,i8**%e,align 8
store i8*%R,i8**%d,align 8
br label%E
ad:
%ae=getelementptr inbounds i8,i8*%J,i64 8
%af=bitcast i8*%ae to i8**
%ag=load i8*,i8**%af,align 8
store i8*%ag,i8**%f,align 8
%ah=getelementptr inbounds i8,i8*%t,i64 8
%ai=bitcast i8*%ah to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%g,align 8
%ak=call i8*@sml_alloc(i32 inreg 20)#0
%al=getelementptr inbounds i8,i8*%ak,i64 -4
%am=bitcast i8*%al to i32*
store i32 1342177296,i32*%am,align 4
%an=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ao=bitcast i8*%ak to i8**
store i8*%an,i8**%ao,align 8
%ap=load i8*,i8**%e,align 8
%aq=getelementptr inbounds i8,i8*%ak,i64 8
%ar=bitcast i8*%aq to i8**
store i8*%ap,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%ak,i64 16
%at=bitcast i8*%as to i32*
store i32 3,i32*%at,align 4
%au=load i8*,i8**%d,align 8
store i8*%ak,i8**%e,align 8
store i8*%au,i8**%d,align 8
br label%E
}
define internal fastcc i8*@_SMLL4scan_82(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d,i8*inreg%e)#3 gc"smlsharp"{
o:
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
store i8*%a,i8**%k,align 8
store i8*%b,i8**%f,align 8
store i8*%c,i8**%i,align 8
store i8*%d,i8**%h,align 8
store i8*%e,i8**%g,align 8
%l=bitcast i8**%k to i8***
br label%m
m:
%n=phi i8*[%c,%o],[%M,%L]
%p=phi i8*[%b,%o],[%N,%L]
%q=load atomic i32,i32*@sml_check_flag unordered,align 4
%r=icmp eq i32%q,0
br i1%r,label%v,label%s
s:
call void@sml_check(i32 inreg%q)
%t=load i8*,i8**%f,align 8
%u=load i8*,i8**%i,align 8
br label%v
v:
%w=phi i8*[%u,%s],[%n,%m]
%x=phi i8*[%t,%s],[%p,%m]
store i8*%x,i8**%j,align 8
%y=icmp eq i8*%w,null
br i1%y,label%z,label%O
z:
%A=load i8*,i8**%h,align 8
%B=icmp eq i8*%A,null
br i1%B,label%C,label%E
C:
%D=load i8*,i8**%g,align 8
ret i8*%D
E:
%F=bitcast i8*%A to i8**
%G=load i8*,i8**%F,align 8
%H=getelementptr inbounds i8,i8*%A,i64 8
%I=bitcast i8*%H to i8**
%J=load i8*,i8**%I,align 8
%K=load i8*,i8**%g,align 8
store i8*null,i8**%j,align 8
store i8*%G,i8**%i,align 8
store i8*%J,i8**%h,align 8
store i8*%K,i8**%g,align 8
br label%L
L:
%M=phi i8*[%G,%E],[%ar,%ao],[%aC,%au],[%aM,%aE],[%a7,%aO]
%N=phi i8*[%x,%E],[%at,%ao],[%az,%au],[%aJ,%aE],[%a6,%aO]
br label%m
O:
%P=bitcast i8*%w to i8**
%Q=load i8*,i8**%P,align 8
%R=bitcast i8*%Q to i32*
%S=load i32,i32*%R,align 4
%T=icmp eq i32%S,4
br i1%T,label%aO,label%U
U:
%V=load i8*,i8**%k,align 8
%W=getelementptr inbounds i8,i8*%V,i64 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
%Z=call fastcc i8*@_SMLL5visit_77(i8*inreg%Y,i8*inreg%x,i8*inreg%Q)
store i8*%Z,i8**%f,align 8
%aa=call i8*@sml_alloc(i32 inreg 20)#0
%ab=getelementptr inbounds i8,i8*%aa,i64 -4
%ac=bitcast i8*%ab to i32*
store i32 1342177296,i32*%ac,align 4
%ad=load i8*,i8**%f,align 8
%ae=bitcast i8*%aa to i8**
store i8*%ad,i8**%ae,align 8
%af=load i8*,i8**%g,align 8
%ag=getelementptr inbounds i8,i8*%aa,i64 8
%ah=bitcast i8*%ag to i8**
store i8*%af,i8**%ah,align 8
%ai=getelementptr inbounds i8,i8*%aa,i64 16
%aj=bitcast i8*%ai to i32*
store i32 3,i32*%aj,align 4
%ak=load i8*,i8**%i,align 8
%al=bitcast i8*%ak to i32**
%am=load i32*,i32**%al,align 8
%an=load i32,i32*%am,align 4
switch i32%an,label%ao[
i32 6,label%aE
i32 1,label%au
]
ao:
%ap=getelementptr inbounds i8,i8*%ak,i64 8
%aq=bitcast i8*%ap to i8**
%ar=load i8*,i8**%aq,align 8
%as=load i8*,i8**%h,align 8
%at=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
store i8*%at,i8**%f,align 8
store i8*%ar,i8**%i,align 8
store i8*%as,i8**%h,align 8
store i8*%aa,i8**%g,align 8
br label%L
au:
store i8*null,i8**%j,align 8
%av=load i8**,i8***%l,align 8
%aw=load i8*,i8**%av,align 8
%ax=getelementptr inbounds i8,i8*%aw,i64 8
%ay=bitcast i8*%ax to i8**
%az=load i8*,i8**%ay,align 8
%aA=getelementptr inbounds i8,i8*%ak,i64 8
%aB=bitcast i8*%aA to i8**
%aC=load i8*,i8**%aB,align 8
%aD=load i8*,i8**%h,align 8
store i8*%az,i8**%f,align 8
store i8*%aC,i8**%i,align 8
store i8*%aD,i8**%h,align 8
store i8*%aa,i8**%g,align 8
br label%L
aE:
store i8*null,i8**%j,align 8
%aF=load i8**,i8***%l,align 8
%aG=load i8*,i8**%aF,align 8
%aH=getelementptr inbounds i8,i8*%aG,i64 8
%aI=bitcast i8*%aH to i8**
%aJ=load i8*,i8**%aI,align 8
%aK=getelementptr inbounds i8,i8*%ak,i64 8
%aL=bitcast i8*%aK to i8**
%aM=load i8*,i8**%aL,align 8
%aN=load i8*,i8**%h,align 8
store i8*%aJ,i8**%f,align 8
store i8*%aM,i8**%i,align 8
store i8*%aN,i8**%h,align 8
store i8*%aa,i8**%g,align 8
br label%L
aO:
%aP=getelementptr inbounds i8,i8*%Q,i64 8
%aQ=bitcast i8*%aP to i8**
%aR=load i8*,i8**%aQ,align 8
store i8*%aR,i8**%f,align 8
%aS=getelementptr inbounds i8,i8*%w,i64 8
%aT=bitcast i8*%aS to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%i,align 8
%aV=call i8*@sml_alloc(i32 inreg 20)#0
%aW=getelementptr inbounds i8,i8*%aV,i64 -4
%aX=bitcast i8*%aW to i32*
store i32 1342177296,i32*%aX,align 4
%aY=load i8*,i8**%i,align 8
%aZ=bitcast i8*%aV to i8**
store i8*%aY,i8**%aZ,align 8
%a0=load i8*,i8**%h,align 8
%a1=getelementptr inbounds i8,i8*%aV,i64 8
%a2=bitcast i8*%a1 to i8**
store i8*%a0,i8**%a2,align 8
%a3=getelementptr inbounds i8,i8*%aV,i64 16
%a4=bitcast i8*%a3 to i32*
store i32 3,i32*%a4,align 4
%a5=load i8*,i8**%g,align 8
%a6=load i8*,i8**%j,align 8
%a7=load i8*,i8**%f,align 8
store i8*null,i8**%j,align 8
store i8*%a6,i8**%f,align 8
store i8*%a7,i8**%i,align 8
store i8*%aV,i8**%h,align 8
store i8*%a5,i8**%g,align 8
br label%L
}
define internal fastcc i8*@_SMLL9visitList_83(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%o
l:
call void@sml_check(i32 inreg%h)
%m=bitcast i8**%d to i8***
%n=load i8**,i8***%m,align 8
br label%o
o:
%p=phi i8**[%n,%l],[%k,%j]
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%e,align 8
%r=getelementptr inbounds i8*,i8**%p,i64 1
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%f,align 8
%t=call i8*@sml_alloc(i32 inreg 20)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177296,i32*%v,align 4
store i8*%t,i8**%g,align 8
%w=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%x=bitcast i8*%t to i8**
store i8*%w,i8**%x,align 8
%y=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%z=getelementptr inbounds i8,i8*%t,i64 8
%A=bitcast i8*%z to i8**
store i8*%y,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%t,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
%D=call i8*@sml_alloc(i32 inreg 28)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177304,i32*%F,align 4
%G=load i8*,i8**%g,align 8
%H=bitcast i8*%D to i8**
store i8*%G,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%D,i64 8
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*,i8*)*@_SMLL4scan_82 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%D,i64 16
%L=bitcast i8*%K to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*,i8*)*@_SMLL4scan_82 to void(...)*),void(...)**%L,align 8
%M=getelementptr inbounds i8,i8*%D,i64 24
%N=bitcast i8*%M to i32*
store i32 -2147483647,i32*%N,align 4
%O=bitcast i8**%d to i8****
%P=load i8***,i8****%O,align 8
%Q=load i8**,i8***%P,align 8
%R=load i8*,i8**%Q,align 8
%S=load i8*,i8**%c,align 8
%T=call fastcc i8*@_SMLL4scan_82(i8*inreg%G,i8*inreg%R,i8*inreg%S,i8*inreg null,i8*inreg null)
ret i8*%T
}
define internal fastcc i8*@_SMLL9visitList_84(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%b,i8**%c,align 8
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%n=getelementptr inbounds i8,i8*%h,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%h,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 28)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177304,i32*%t,align 4
%u=load i8*,i8**%e,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL9visitList_83 to void(...)*),void(...)**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL9visitList_83 to void(...)*),void(...)**%z,align 8
%A=getelementptr inbounds i8,i8*%r,i64 24
%B=bitcast i8*%A to i32*
store i32 -2147483647,i32*%B,align 4
ret i8*%r
}
define internal fastcc i8*@_SMLL1l_85(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
%n=getelementptr inbounds i8,i8*%k,i64 8
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
%q=bitcast i8*%k to i8**
%r=load i8*,i8**%q,align 8
%s=tail call fastcc i8*@_SMLL5visit_77(i8*inreg%p,i8*inreg%r,i8*inreg%m)
ret i8*%s
}
define internal fastcc i8*@_SMLL5visit_77(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
v:
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
%m=alloca i8*,align 8
%n=alloca i8*,align 8
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
call void@llvm.gcroot(i8**%m,i8*null)#0
call void@llvm.gcroot(i8**%n,i8*null)#0
store i8*%a,i8**%m,align 8
store i8*%b,i8**%i,align 8
store i8*%c,i8**%j,align 8
%o=load atomic i32,i32*@sml_check_flag unordered,align 4
%p=icmp eq i32%o,0
br i1%p,label%t,label%q
q:
call void@sml_check(i32 inreg%o)
%r=load i8*,i8**%j,align 8
%s=load i8*,i8**%i,align 8
br label%t
t:
%u=phi i8*[%s,%q],[%b,%v]
%w=phi i8*[%r,%q],[%c,%v]
store i8*null,i8**%i,align 8
store i8*%u,i8**%k,align 8
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=icmp eq i32%y,1
br i1%z,label%B,label%A
A:
ret i8*%w
B:
%C=getelementptr inbounds i8,i8*%w,i64 8
%D=bitcast i8*%C to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%l,align 8
%F=bitcast i8*%E to i8**
%G=load i8*,i8**%F,align 8
%H=icmp eq i8*%G,null
%I=bitcast i8*%G to i8**
%J=select i1%H,i8**%k,i8**%I
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%j,align 8
%L=bitcast i8*%K to i32*
%M=load i32,i32*%L,align 4
%N=getelementptr inbounds i8,i8*%K,i64 8
%O=bitcast i8*%N to i32*
%P=load i32,i32*%O,align 4
%Q=call i8*@sml_alloc(i32 inreg 20)#0
%R=getelementptr inbounds i8,i8*%Q,i64 -4
%S=bitcast i8*%R to i32*
store i32 1342177296,i32*%S,align 4
store i8*%Q,i8**%i,align 8
%T=getelementptr inbounds i8,i8*%Q,i64 12
%U=bitcast i8*%T to i32*
store i32 0,i32*%U,align 1
%V=bitcast i8*%Q to i32*
store i32%M,i32*%V,align 4
%W=getelementptr inbounds i8,i8*%Q,i64 4
%X=bitcast i8*%W to i32*
store i32 1,i32*%X,align 4
%Y=getelementptr inbounds i8,i8*%Q,i64 8
%Z=bitcast i8*%Y to i32*
store i32%P,i32*%Z,align 4
%aa=getelementptr inbounds i8,i8*%Q,i64 16
%ab=bitcast i8*%aa to i32*
store i32 0,i32*%ab,align 4
%ac=call i8*@sml_alloc(i32 inreg 12)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177288,i32*%ae,align 4
store i8*%ac,i8**%n,align 8
%af=load i8*,i8**%m,align 8
%ag=bitcast i8*%ac to i8**
store i8*%af,i8**%ag,align 8
%ah=getelementptr inbounds i8,i8*%ac,i64 8
%ai=bitcast i8*%ah to i32*
store i32 1,i32*%ai,align 4
%aj=call i8*@sml_alloc(i32 inreg 28)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32 1342177304,i32*%al,align 4
%am=load i8*,i8**%n,align 8
%an=bitcast i8*%aj to i8**
store i8*%am,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%aj,i64 8
%ap=bitcast i8*%ao to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL9visitList_84 to void(...)*),void(...)**%ap,align 8
%aq=getelementptr inbounds i8,i8*%aj,i64 16
%ar=bitcast i8*%aq to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL9visitList_84 to void(...)*),void(...)**%ar,align 8
%as=getelementptr inbounds i8,i8*%aj,i64 24
%at=bitcast i8*%as to i32*
store i32 -2147483647,i32*%at,align 4
%au=load i8*,i8**%j,align 8
%av=getelementptr inbounds i8,i8*%au,i64 4
%aw=bitcast i8*%av to i32*
%ax=load i32,i32*%aw,align 4
switch i32%ax,label%ay[
i32 0,label%cF
i32 2,label%cg
]
ay:
store i8*null,i8**%i,align 8
store i8*null,i8**%n,align 8
%az=call i8*@sml_alloc(i32 inreg 20)#0
%aA=getelementptr inbounds i8,i8*%az,i64 -4
%aB=bitcast i8*%aA to i32*
store i32 1342177296,i32*%aB,align 4
store i8*%az,i8**%i,align 8
%aC=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%aD=bitcast i8*%az to i8**
store i8*%aC,i8**%aD,align 8
%aE=load i8*,i8**%m,align 8
%aF=getelementptr inbounds i8,i8*%az,i64 8
%aG=bitcast i8*%aF to i8**
store i8*%aE,i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%az,i64 16
%aI=bitcast i8*%aH to i32*
store i32 3,i32*%aI,align 4
%aJ=call i8*@sml_alloc(i32 inreg 28)#0
%aK=getelementptr inbounds i8,i8*%aJ,i64 -4
%aL=bitcast i8*%aK to i32*
store i32 1342177304,i32*%aL,align 4
%aM=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aN=bitcast i8*%aJ to i8**
store i8*%aM,i8**%aN,align 8
%aO=getelementptr inbounds i8,i8*%aJ,i64 8
%aP=bitcast i8*%aO to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL1l_85 to void(...)*),void(...)**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aJ,i64 16
%aR=bitcast i8*%aQ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL1l_85 to void(...)*),void(...)**%aR,align 8
%aS=getelementptr inbounds i8,i8*%aJ,i64 24
%aT=bitcast i8*%aS to i32*
store i32 -2147483647,i32*%aT,align 4
%aU=load i8*,i8**%l,align 8
%aV=getelementptr inbounds i8,i8*%aU,i64 8
%aW=bitcast i8*%aV to i8**
%aX=load i8*,i8**%aW,align 8
%aY=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%aY)
%aZ=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%aZ)
%a0=bitcast i8**%f to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%a0)
%a1=bitcast i8**%g to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%a1)
%a2=bitcast i8**%h to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%a2)
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
store i8*%aJ,i8**%d,align 8
store i8*%aX,i8**%g,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%e,align 8
br label%a3
a3:
%a4=phi i8*[%aJ,%ay],[%cb,%ca]
%a5=phi i8*[%aX,%ay],[%cc,%ca]
%a6=load atomic i32,i32*@sml_check_flag unordered,align 4
%a7=icmp eq i32%a6,0
br i1%a7,label%bb,label%a8
a8:
call void@sml_check(i32 inreg%a6)
%a9=load i8*,i8**%g,align 8
%ba=load i8*,i8**%d,align 8
br label%bb
bb:
%bc=phi i8*[%ba,%a8],[%a4,%a3]
%bd=phi i8*[%a9,%a8],[%a5,%a3]
store i8*%bc,i8**%g,align 8
%be=icmp eq i8*%bd,null
br i1%be,label%bf,label%bo
bf:
%bg=load i8*,i8**%f,align 8
%bh=icmp eq i8*%bg,null
br i1%bh,label%cd,label%bi
bi:
%bj=bitcast i8*%bg to i8**
%bk=load i8*,i8**%bj,align 8
%bl=getelementptr inbounds i8,i8*%bg,i64 8
%bm=bitcast i8*%bl to i8**
%bn=load i8*,i8**%bm,align 8
store i8*%bk,i8**%g,align 8
store i8*%bn,i8**%f,align 8
br label%ca
bo:
%bp=bitcast i8*%bd to i8**
%bq=load i8*,i8**%bp,align 8
%br=bitcast i8*%bq to i32*
%bs=load i32,i32*%br,align 4
%bt=icmp eq i32%bs,4
br i1%bt,label%bR,label%bu
bu:
%bv=getelementptr inbounds i8,i8*%bd,i64 8
%bw=bitcast i8*%bv to i8**
%bx=load i8*,i8**%bw,align 8
store i8*%bx,i8**%h,align 8
%by=getelementptr inbounds i8,i8*%bc,i64 16
%bz=bitcast i8*%by to i8*(i8*,i8*)**
%bA=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bz,align 8
%bB=bitcast i8*%bc to i8**
%bC=load i8*,i8**%bB,align 8
%bD=load i8*,i8**%bp,align 8
%bE=call fastcc i8*%bA(i8*inreg%bC,i8*inreg%bD)
store i8*%bE,i8**%d,align 8
%bF=call i8*@sml_alloc(i32 inreg 20)#0
%bG=getelementptr inbounds i8,i8*%bF,i64 -4
%bH=bitcast i8*%bG to i32*
store i32 1342177296,i32*%bH,align 4
%bI=load i8*,i8**%d,align 8
%bJ=bitcast i8*%bF to i8**
store i8*%bI,i8**%bJ,align 8
%bK=load i8*,i8**%e,align 8
%bL=getelementptr inbounds i8,i8*%bF,i64 8
%bM=bitcast i8*%bL to i8**
store i8*%bK,i8**%bM,align 8
%bN=getelementptr inbounds i8,i8*%bF,i64 16
%bO=bitcast i8*%bN to i32*
store i32 3,i32*%bO,align 4
%bP=load i8*,i8**%g,align 8
%bQ=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
store i8*%bP,i8**%d,align 8
store i8*%bQ,i8**%g,align 8
store i8*%bF,i8**%e,align 8
br label%ca
bR:
%bS=getelementptr inbounds i8,i8*%bq,i64 8
%bT=bitcast i8*%bS to i8**
%bU=load i8*,i8**%bT,align 8
store i8*%bU,i8**%d,align 8
%bV=getelementptr inbounds i8,i8*%bd,i64 8
%bW=bitcast i8*%bV to i8**
%bX=load i8*,i8**%bW,align 8
store i8*%bX,i8**%h,align 8
%bY=call i8*@sml_alloc(i32 inreg 20)#0
%bZ=getelementptr inbounds i8,i8*%bY,i64 -4
%b0=bitcast i8*%bZ to i32*
store i32 1342177296,i32*%b0,align 4
%b1=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b2=bitcast i8*%bY to i8**
store i8*%b1,i8**%b2,align 8
%b3=load i8*,i8**%f,align 8
%b4=getelementptr inbounds i8,i8*%bY,i64 8
%b5=bitcast i8*%b4 to i8**
store i8*%b3,i8**%b5,align 8
%b6=getelementptr inbounds i8,i8*%bY,i64 16
%b7=bitcast i8*%b6 to i32*
store i32 3,i32*%b7,align 4
%b8=load i8*,i8**%g,align 8
%b9=load i8*,i8**%d,align 8
store i8*%b8,i8**%d,align 8
store i8*%b9,i8**%g,align 8
store i8*%bY,i8**%f,align 8
br label%ca
ca:
%cb=phi i8*[%bc,%bi],[%bP,%bu],[%b8,%bR]
%cc=phi i8*[%bk,%bi],[%bQ,%bu],[%b9,%bR]
br label%a3
cd:
%ce=load i8*,i8**%e,align 8
call void@llvm.lifetime.end.p0i8(i64 8,i8*%aY)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%aZ)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%a0)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%a1)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%a2)
%cf=call fastcc i8*@_SMLL5revFE_78(i8*inreg%ce,i8*inreg null,i8*inreg null)
store i8*%cf,i8**%i,align 8
br label%c3
cg:
%ch=call i8*@sml_alloc(i32 inreg 20)#0
%ci=getelementptr inbounds i8,i8*%ch,i64 -4
%cj=bitcast i8*%ci to i32*
store i32 1342177296,i32*%cj,align 4
%ck=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cl=bitcast i8*%ch to i8**
store i8*%ck,i8**%cl,align 8
%cm=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cn=getelementptr inbounds i8,i8*%ch,i64 8
%co=bitcast i8*%cn to i8**
store i8*%cm,i8**%co,align 8
%cp=getelementptr inbounds i8,i8*%ch,i64 16
%cq=bitcast i8*%cp to i32*
store i32 3,i32*%cq,align 4
%cr=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%cs=call fastcc i8*@_SMLL9visitList_84(i8*inreg%cr,i8*inreg%ch)
%ct=getelementptr inbounds i8,i8*%cs,i64 16
%cu=bitcast i8*%ct to i8*(i8*,i8*)**
%cv=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cu,align 8
%cw=bitcast i8*%cs to i8**
%cx=load i8*,i8**%cw,align 8
store i8*%cx,i8**%i,align 8
%cy=load i8*,i8**%l,align 8
%cz=getelementptr inbounds i8,i8*%cy,i64 8
%cA=bitcast i8*%cz to i8**
%cB=load i8*,i8**%cA,align 8
%cC=call fastcc i8*@_SMLL5revFE_78(i8*inreg%cB,i8*inreg null,i8*inreg null)
%cD=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cE=call fastcc i8*%cv(i8*inreg%cD,i8*inreg%cC)
store i8*%cE,i8**%i,align 8
br label%c3
cF:
%cG=call i8*@sml_alloc(i32 inreg 20)#0
%cH=getelementptr inbounds i8,i8*%cG,i64 -4
%cI=bitcast i8*%cH to i32*
store i32 1342177296,i32*%cI,align 4
%cJ=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cK=bitcast i8*%cG to i8**
store i8*%cJ,i8**%cK,align 8
%cL=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cM=getelementptr inbounds i8,i8*%cG,i64 8
%cN=bitcast i8*%cM to i8**
store i8*%cL,i8**%cN,align 8
%cO=getelementptr inbounds i8,i8*%cG,i64 16
%cP=bitcast i8*%cO to i32*
store i32 3,i32*%cP,align 4
%cQ=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%cR=call fastcc i8*@_SMLL9visitList_84(i8*inreg%cQ,i8*inreg%cG)
%cS=getelementptr inbounds i8,i8*%cR,i64 16
%cT=bitcast i8*%cS to i8*(i8*,i8*)**
%cU=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cT,align 8
%cV=bitcast i8*%cR to i8**
%cW=load i8*,i8**%cV,align 8
%cX=load i8*,i8**%l,align 8
%cY=getelementptr inbounds i8,i8*%cX,i64 8
%cZ=bitcast i8*%cY to i8**
%c0=load i8*,i8**%cZ,align 8
%c1=call fastcc i8*%cU(i8*inreg%cW,i8*inreg%c0)
%c2=call fastcc i8*@_SMLL5revFE_78(i8*inreg%c1,i8*inreg null,i8*inreg null)
store i8*%c2,i8**%i,align 8
br label%c3
c3:
%c4=bitcast i8**%l to i8***
%c5=load i8**,i8***%c4,align 8
%c6=load i8*,i8**%c5,align 8
%c7=icmp eq i8*%c6,null
br i1%c7,label%c8,label%dt
c8:
store i8*null,i8**%k,align 8
store i8*null,i8**%l,align 8
store i8*null,i8**%m,align 8
%c9=call i8*@sml_alloc(i32 inreg 20)#0
%da=getelementptr inbounds i8,i8*%c9,i64 -4
%db=bitcast i8*%da to i32*
store i32 1342177296,i32*%db,align 4
store i8*%c9,i8**%j,align 8
%dc=bitcast i8*%c9 to i8**
store i8*null,i8**%dc,align 8
%dd=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%de=getelementptr inbounds i8,i8*%c9,i64 8
%df=bitcast i8*%de to i8**
store i8*%dd,i8**%df,align 8
%dg=getelementptr inbounds i8,i8*%c9,i64 16
%dh=bitcast i8*%dg to i32*
store i32 3,i32*%dh,align 4
%di=call i8*@sml_alloc(i32 inreg 20)#0
%dj=bitcast i8*%di to i32*
%dk=getelementptr inbounds i8,i8*%di,i64 -4
%dl=bitcast i8*%dk to i32*
store i32 1342177296,i32*%dl,align 4
%dm=getelementptr inbounds i8,i8*%di,i64 4
%dn=bitcast i8*%dm to i32*
store i32 0,i32*%dn,align 1
store i32 1,i32*%dj,align 4
%do=load i8*,i8**%j,align 8
%dp=getelementptr inbounds i8,i8*%di,i64 8
%dq=bitcast i8*%dp to i8**
store i8*%do,i8**%dq,align 8
%dr=getelementptr inbounds i8,i8*%di,i64 16
%ds=bitcast i8*%dr to i32*
store i32 2,i32*%ds,align 4
ret i8*%di
dt:
store i8*null,i8**%l,align 8
%du=bitcast i8**%c5 to i8***
%dv=load i8**,i8***%du,align 8
%dw=load i8*,i8**%dv,align 8
store i8*%dw,i8**%j,align 8
%dx=bitcast i8*%dw to i32*
%dy=load i32,i32*%dx,align 4
%dz=icmp eq i32%dy,0
br i1%dz,label%dV,label%dA
dA:
store i8*null,i8**%k,align 8
store i8*null,i8**%j,align 8
store i8*null,i8**%m,align 8
%dB=call i8*@sml_alloc(i32 inreg 20)#0
%dC=getelementptr inbounds i8,i8*%dB,i64 -4
%dD=bitcast i8*%dC to i32*
store i32 1342177296,i32*%dD,align 4
store i8*%dB,i8**%j,align 8
%dE=bitcast i8*%dB to i8**
store i8*null,i8**%dE,align 8
%dF=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%dG=getelementptr inbounds i8,i8*%dB,i64 8
%dH=bitcast i8*%dG to i8**
store i8*%dF,i8**%dH,align 8
%dI=getelementptr inbounds i8,i8*%dB,i64 16
%dJ=bitcast i8*%dI to i32*
store i32 3,i32*%dJ,align 4
%dK=call i8*@sml_alloc(i32 inreg 20)#0
%dL=bitcast i8*%dK to i32*
%dM=getelementptr inbounds i8,i8*%dK,i64 -4
%dN=bitcast i8*%dM to i32*
store i32 1342177296,i32*%dN,align 4
%dO=getelementptr inbounds i8,i8*%dK,i64 4
%dP=bitcast i8*%dO to i32*
store i32 0,i32*%dP,align 1
store i32 1,i32*%dL,align 4
%dQ=load i8*,i8**%j,align 8
%dR=getelementptr inbounds i8,i8*%dK,i64 8
%dS=bitcast i8*%dR to i8**
store i8*%dQ,i8**%dS,align 8
%dT=getelementptr inbounds i8,i8*%dK,i64 16
%dU=bitcast i8*%dT to i32*
store i32 2,i32*%dU,align 4
ret i8*%dK
dV:
%dW=call i8*@sml_alloc(i32 inreg 20)#0
%dX=getelementptr inbounds i8,i8*%dW,i64 -4
%dY=bitcast i8*%dX to i32*
store i32 1342177296,i32*%dY,align 4
%dZ=load i8*,i8**%k,align 8
%d0=bitcast i8*%dW to i8**
store i8*%dZ,i8**%d0,align 8
%d1=load i8*,i8**%j,align 8
%d2=getelementptr inbounds i8,i8*%dW,i64 8
%d3=bitcast i8*%d2 to i8**
store i8*%d1,i8**%d3,align 8
%d4=getelementptr inbounds i8,i8*%dW,i64 16
%d5=bitcast i8*%d4 to i32*
store i32 3,i32*%d5,align 4
%d6=getelementptr inbounds i8,i8*%dZ,i64 8
%d7=bitcast i8*%d6 to i32*
%d8=load i32,i32*%d7,align 4
%d9=getelementptr inbounds i8,i8*%d1,i64 8
%ea=bitcast i8*%d9 to i32*
%eb=load i32,i32*%ea,align 4
%ec=icmp slt i32%d8,%eb
br i1%ec,label%et,label%ed
ed:
%ee=icmp eq i32%d8,%eb
br i1%ee,label%ef,label%eu
ef:
%eg=getelementptr inbounds i8,i8*%dZ,i64 4
%eh=bitcast i8*%eg to i32*
%ei=load i32,i32*%eh,align 4
switch i32%ei,label%eu[
i32 0,label%eo
i32 2,label%ej
]
ej:
%ek=getelementptr inbounds i8,i8*%d1,i64 4
%el=bitcast i8*%ek to i32*
%em=load i32,i32*%el,align 4
%en=icmp eq i32%em,1
br i1%en,label%et,label%eu
eo:
%ep=getelementptr inbounds i8,i8*%d1,i64 4
%eq=bitcast i8*%ep to i32*
%er=load i32,i32*%eq,align 4
%es=icmp eq i32%er,1
br i1%es,label%et,label%eu
et:
store i8*null,i8**%k,align 8
store i8*null,i8**%j,align 8
br label%eU
eu:
%ev=call i8*@sml_alloc(i32 inreg 20)#0
%ew=getelementptr inbounds i8,i8*%ev,i64 -4
%ex=bitcast i8*%ew to i32*
store i32 1342177296,i32*%ex,align 4
%ey=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%ez=bitcast i8*%ev to i8**
store i8*%ey,i8**%ez,align 8
%eA=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%eB=getelementptr inbounds i8,i8*%ev,i64 8
%eC=bitcast i8*%eB to i8**
store i8*%eA,i8**%eC,align 8
%eD=getelementptr inbounds i8,i8*%ev,i64 16
%eE=bitcast i8*%eD to i32*
store i32 3,i32*%eE,align 4
%eF=getelementptr inbounds i8,i8*%ey,i64 8
%eG=bitcast i8*%eF to i32*
%eH=load i32,i32*%eG,align 4
%eI=getelementptr inbounds i8,i8*%eA,i64 8
%eJ=bitcast i8*%eI to i32*
%eK=load i32,i32*%eJ,align 4
%eL=icmp eq i32%eH,%eK
br i1%eL,label%eM,label%ff
eM:
%eN=getelementptr inbounds i8,i8*%ey,i64 4
%eO=bitcast i8*%eN to i32*
%eP=load i32,i32*%eO,align 4
%eQ=getelementptr inbounds i8,i8*%eA,i64 4
%eR=bitcast i8*%eQ to i32*
%eS=load i32,i32*%eR,align 4
%eT=icmp eq i32%eP,%eS
br i1%eT,label%eU,label%ff
eU:
store i8*null,i8**%m,align 8
%eV=call i8*@sml_alloc(i32 inreg 20)#0
%eW=getelementptr inbounds i8,i8*%eV,i64 -4
%eX=bitcast i8*%eW to i32*
store i32 1342177296,i32*%eX,align 4
store i8*%eV,i8**%j,align 8
%eY=bitcast i8*%eV to i8**
store i8*null,i8**%eY,align 8
%eZ=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%e0=getelementptr inbounds i8,i8*%eV,i64 8
%e1=bitcast i8*%e0 to i8**
store i8*%eZ,i8**%e1,align 8
%e2=getelementptr inbounds i8,i8*%eV,i64 16
%e3=bitcast i8*%e2 to i32*
store i32 3,i32*%e3,align 4
%e4=call i8*@sml_alloc(i32 inreg 20)#0
%e5=bitcast i8*%e4 to i32*
%e6=getelementptr inbounds i8,i8*%e4,i64 -4
%e7=bitcast i8*%e6 to i32*
store i32 1342177296,i32*%e7,align 4
%e8=getelementptr inbounds i8,i8*%e4,i64 4
%e9=bitcast i8*%e8 to i32*
store i32 0,i32*%e9,align 1
store i32 1,i32*%e5,align 4
%fa=load i8*,i8**%j,align 8
%fb=getelementptr inbounds i8,i8*%e4,i64 8
%fc=bitcast i8*%fb to i8**
store i8*%fa,i8**%fc,align 8
%fd=getelementptr inbounds i8,i8*%e4,i64 16
%fe=bitcast i8*%fd to i32*
store i32 2,i32*%fe,align 4
ret i8*%e4
ff:
%fg=bitcast i8**%m to i8***
%fh=load i8**,i8***%fg,align 8
store i8*null,i8**%m,align 8
%fi=load i8*,i8**%fh,align 8
%fj=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%fk=call fastcc i8*@_SMLL14encloseSymbols_76(i8*inreg%fi,i8*inreg%fj)
store i8*%fk,i8**%i,align 8
%fl=call i8*@sml_alloc(i32 inreg 20)#0
%fm=getelementptr inbounds i8,i8*%fl,i64 -4
%fn=bitcast i8*%fm to i32*
store i32 1342177296,i32*%fn,align 4
%fo=bitcast i8*%fl to i8**
store i8*null,i8**%fo,align 8
%fp=load i8*,i8**%i,align 8
%fq=getelementptr inbounds i8,i8*%fl,i64 8
%fr=bitcast i8*%fq to i8**
store i8*%fp,i8**%fr,align 8
%fs=getelementptr inbounds i8,i8*%fl,i64 16
%ft=bitcast i8*%fs to i32*
store i32 3,i32*%ft,align 4
store i8*null,i8**%i,align 8
store i8*%fp,i8**%j,align 8
%fu=call i8*@sml_alloc(i32 inreg 20)#0
%fv=getelementptr inbounds i8,i8*%fu,i64 -4
%fw=bitcast i8*%fv to i32*
store i32 1342177296,i32*%fw,align 4
store i8*%fu,i8**%k,align 8
%fx=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%fy=bitcast i8*%fu to i8**
store i8*%fx,i8**%fy,align 8
%fz=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%fA=getelementptr inbounds i8,i8*%fu,i64 8
%fB=bitcast i8*%fA to i8**
store i8*%fz,i8**%fB,align 8
%fC=getelementptr inbounds i8,i8*%fu,i64 16
%fD=bitcast i8*%fC to i32*
store i32 3,i32*%fD,align 4
%fE=call i8*@sml_alloc(i32 inreg 20)#0
%fF=bitcast i8*%fE to i32*
%fG=getelementptr inbounds i8,i8*%fE,i64 -4
%fH=bitcast i8*%fG to i32*
store i32 1342177296,i32*%fH,align 4
%fI=getelementptr inbounds i8,i8*%fE,i64 4
%fJ=bitcast i8*%fI to i32*
store i32 0,i32*%fJ,align 1
store i32 1,i32*%fF,align 4
%fK=load i8*,i8**%k,align 8
%fL=getelementptr inbounds i8,i8*%fE,i64 8
%fM=bitcast i8*%fL to i8**
store i8*%fK,i8**%fM,align 8
%fN=getelementptr inbounds i8,i8*%fE,i64 16
%fO=bitcast i8*%fN to i32*
store i32 2,i32*%fO,align 4
ret i8*%fE
}
define internal fastcc i8*@_SMLLN13AssocResolver7resolveE_87(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
br i1%g,label%h,label%j
h:
%i=bitcast i8*%a to i8**
br label%m
j:
call void@sml_check(i32 inreg%f)
%k=bitcast i8**%d to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%j],[%i,%h]
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%d,align 8
%p=call i8*@sml_alloc(i32 inreg 12)#0
%q=getelementptr inbounds i8,i8*%p,i64 -4
%r=bitcast i8*%q to i32*
store i32 1342177288,i32*%r,align 4
store i8*%p,i8**%e,align 8
%s=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%t=bitcast i8*%p to i8**
store i8*%s,i8**%t,align 8
%u=getelementptr inbounds i8,i8*%p,i64 8
%v=bitcast i8*%u to i32*
store i32 1,i32*%v,align 4
%w=call i8*@sml_alloc(i32 inreg 28)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177304,i32*%y,align 4
%z=load i8*,i8**%e,align 8
%A=bitcast i8*%w to i8**
store i8*%z,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%w,i64 8
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL14encloseSymbols_76 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%w,i64 16
%E=bitcast i8*%D to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL14encloseSymbols_76 to void(...)*),void(...)**%E,align 8
%F=getelementptr inbounds i8,i8*%w,i64 24
%G=bitcast i8*%F to i32*
store i32 -2147483647,i32*%G,align 4
%H=call i8*@sml_alloc(i32 inreg 12)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177288,i32*%J,align 4
store i8*%H,i8**%d,align 8
%K=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%L=bitcast i8*%H to i8**
store i8*%K,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%H,i64 8
%N=bitcast i8*%M to i32*
store i32 1,i32*%N,align 4
%O=call i8*@sml_alloc(i32 inreg 28)#0
%P=getelementptr inbounds i8,i8*%O,i64 -4
%Q=bitcast i8*%P to i32*
store i32 1342177304,i32*%Q,align 4
%R=load i8*,i8**%d,align 8
%S=bitcast i8*%O to i8**
store i8*%R,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%O,i64 8
%U=bitcast i8*%T to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLL5visit_77 to void(...)*),void(...)**%U,align 8
%V=getelementptr inbounds i8,i8*%O,i64 16
%W=bitcast i8*%V to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLL5visit_77 to void(...)*),void(...)**%W,align 8
%X=getelementptr inbounds i8,i8*%O,i64 24
%Y=bitcast i8*%X to i32*
store i32 -2147483647,i32*%Y,align 4
%Z=load i8*,i8**%c,align 8
%aa=tail call fastcc i8*@_SMLL5visit_77(i8*inreg%R,i8*inreg bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,i32,i32,[4x i8],i32}>*@d,i64 0,i32 2)to i8*),i8*inreg%Z)
ret i8*%aa
}
define fastcc i8*@_SMLFN13AssocResolver7resolveE(i8*inreg%a)#2 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AssocResolver7resolveE_87 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13AssocResolver7resolveE_87 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN13AssocResolver7resolveE_94(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN13AssocResolver7resolveE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
attributes#3={uwtable}
