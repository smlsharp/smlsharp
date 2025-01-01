@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 5,i32 1,i32 0}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 0,[4x i8]zeroinitializer,i32 0}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i32 1,i32 1,i32 -1,[4x i8]zeroinitializer,i32 0}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN13AssocResolver7resolveE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AssocResolver7resolveE_79 to void(...)*),i32 -2147483647}>,align 8
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
define internal fastcc i8*@_SMLLL5visit_71(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
t:
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
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
call void@llvm.gcroot(i8**%m,i8*null)#0
store i8*%a,i8**%l,align 8
store i8*%b,i8**%d,align 8
store i8*%c,i8**%e,align 8
%n=load atomic i32,i32*@sml_check_flag unordered,align 4
%o=icmp eq i32%n,0
br i1%o,label%r,label%p
p:
call void@sml_check(i32 inreg%n)
%q=load i8*,i8**%e,align 8
br label%r
r:
%s=phi i8*[%q,%p],[%c,%t]
%u=bitcast i8*%s to i32*
%v=load i32,i32*%u,align 4
%w=icmp eq i32%v,1
br i1%w,label%y,label%x
x:
ret i8*%s
y:
%z=getelementptr inbounds i8,i8*%s,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
store i8*%D,i8**%e,align 8
%E=getelementptr inbounds i8,i8*%B,i64 8
%F=bitcast i8*%E to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%f,align 8
%H=icmp eq i8*%D,null
%I=bitcast i8*%D to i8**
%J=select i1%H,i8**%d,i8**%I
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%g,align 8
%L=bitcast i8*%K to i32*
%M=load i32,i32*%L,align 4
%N=getelementptr inbounds i8,i8*%K,i64 8
%O=bitcast i8*%N to i32*
%P=load i32,i32*%O,align 4
%Q=getelementptr inbounds i8,i8*%K,i64 4
%R=bitcast i8*%Q to i32*
%S=load i32,i32*%R,align 4
%T=call i8*@sml_alloc(i32 inreg 20)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177296,i32*%V,align 4
store i8*%T,i8**%h,align 8
%W=getelementptr inbounds i8,i8*%T,i64 12
%X=bitcast i8*%W to i32*
store i32 0,i32*%X,align 1
%Y=bitcast i8*%T to i32*
store i32%M,i32*%Y,align 4
%Z=getelementptr inbounds i8,i8*%T,i64 4
%aa=bitcast i8*%Z to i32*
store i32 1,i32*%aa,align 4
%ab=getelementptr inbounds i8,i8*%T,i64 8
%ac=bitcast i8*%ab to i32*
store i32%P,i32*%ac,align 4
%ad=getelementptr inbounds i8,i8*%T,i64 16
%ae=bitcast i8*%ad to i32*
store i32 0,i32*%ae,align 4
switch i32%S,label%af[
i32 0,label%d8
i32 2,label%b6
]
af:
%ag=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%h,align 8
br label%ah
ah:
%ai=phi i8*[%ag,%af],[%aw,%av]
%aj=icmp eq i8*%ai,null
br i1%aj,label%ak,label%ax
ak:
%al=load i8*,i8**%f,align 8
%am=icmp eq i8*%al,null
br i1%am,label%an,label%ap
an:
%ao=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
br label%bd
ap:
%aq=bitcast i8*%al to i8**
%ar=load i8*,i8**%aq,align 8
%as=getelementptr inbounds i8,i8*%al,i64 8
%at=bitcast i8*%as to i8**
%au=load i8*,i8**%at,align 8
store i8*%au,i8**%f,align 8
br label%av
av:
%aw=phi i8*[%ar,%ap],[%aU,%aD],[%bc,%aV]
br label%ah
ax:
%ay=bitcast i8*%ai to i8**
%az=load i8*,i8**%ay,align 8
%aA=bitcast i8*%az to i32*
%aB=load i32,i32*%aA,align 4
%aC=icmp eq i32%aB,4
br i1%aC,label%aV,label%aD
aD:
%aE=getelementptr inbounds i8,i8*%ai,i64 8
%aF=bitcast i8*%aE to i8**
%aG=load i8*,i8**%aF,align 8
store i8*%aG,i8**%j,align 8
%aH=load i8*,i8**%g,align 8
%aI=load i8*,i8**%l,align 8
%aJ=call fastcc i8*@_SMLLL5visit_71(i8*inreg%aI,i8*inreg%aH,i8*inreg%az)
store i8*%aJ,i8**%i,align 8
%aK=call i8*@sml_alloc(i32 inreg 20)#0
%aL=getelementptr inbounds i8,i8*%aK,i64 -4
%aM=bitcast i8*%aL to i32*
store i32 1342177296,i32*%aM,align 4
%aN=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aO=bitcast i8*%aK to i8**
store i8*%aN,i8**%aO,align 8
%aP=load i8*,i8**%h,align 8
%aQ=getelementptr inbounds i8,i8*%aK,i64 8
%aR=bitcast i8*%aQ to i8**
store i8*%aP,i8**%aR,align 8
%aS=getelementptr inbounds i8,i8*%aK,i64 16
%aT=bitcast i8*%aS to i32*
store i32 3,i32*%aT,align 4
%aU=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
store i8*%aK,i8**%h,align 8
br label%av
aV:
%aW=getelementptr inbounds i8,i8*%az,i64 8
%aX=bitcast i8*%aW to i8**
%aY=load i8*,i8**%aX,align 8
store i8*%aY,i8**%j,align 8
%aZ=getelementptr inbounds i8,i8*%ai,i64 8
%a0=bitcast i8*%aZ to i8**
%a1=load i8*,i8**%a0,align 8
store i8*%a1,i8**%i,align 8
%a2=call i8*@sml_alloc(i32 inreg 20)#0
%a3=getelementptr inbounds i8,i8*%a2,i64 -4
%a4=bitcast i8*%a3 to i32*
store i32 1342177296,i32*%a4,align 4
%a5=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%a6=bitcast i8*%a2 to i8**
store i8*%a5,i8**%a6,align 8
%a7=load i8*,i8**%f,align 8
%a8=getelementptr inbounds i8,i8*%a2,i64 8
%a9=bitcast i8*%a8 to i8**
store i8*%a7,i8**%a9,align 8
%ba=getelementptr inbounds i8,i8*%a2,i64 16
%bb=bitcast i8*%ba to i32*
store i32 3,i32*%bb,align 4
%bc=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
store i8*%a2,i8**%f,align 8
br label%av
bd:
%be=phi i8*[%ao,%an],[%bs,%br]
%bf=icmp eq i8*%be,null
br i1%bf,label%bg,label%bt
bg:
%bh=load i8*,i8**%f,align 8
%bi=icmp eq i8*%bh,null
br i1%bi,label%bj,label%bl
bj:
%bk=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
store i8*%bk,i8**%f,align 8
br label%ga
bl:
%bm=bitcast i8*%bh to i8**
%bn=load i8*,i8**%bm,align 8
%bo=getelementptr inbounds i8,i8*%bh,i64 8
%bp=bitcast i8*%bo to i8**
%bq=load i8*,i8**%bp,align 8
store i8*%bq,i8**%f,align 8
br label%br
br:
%bs=phi i8*[%bn,%bl],[%bN,%bz],[%b5,%bO]
br label%bd
bt:
%bu=bitcast i8*%be to i8**
%bv=load i8*,i8**%bu,align 8
store i8*%bv,i8**%h,align 8
%bw=bitcast i8*%bv to i32*
%bx=load i32,i32*%bw,align 4
%by=icmp eq i32%bx,4
br i1%by,label%bO,label%bz
bz:
%bA=getelementptr inbounds i8,i8*%be,i64 8
%bB=bitcast i8*%bA to i8**
%bC=load i8*,i8**%bB,align 8
store i8*%bC,i8**%i,align 8
%bD=call i8*@sml_alloc(i32 inreg 20)#0
%bE=getelementptr inbounds i8,i8*%bD,i64 -4
%bF=bitcast i8*%bE to i32*
store i32 1342177296,i32*%bF,align 4
%bG=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bH=bitcast i8*%bD to i8**
store i8*%bG,i8**%bH,align 8
%bI=load i8*,i8**%g,align 8
%bJ=getelementptr inbounds i8,i8*%bD,i64 8
%bK=bitcast i8*%bJ to i8**
store i8*%bI,i8**%bK,align 8
%bL=getelementptr inbounds i8,i8*%bD,i64 16
%bM=bitcast i8*%bL to i32*
store i32 3,i32*%bM,align 4
%bN=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*%bD,i8**%g,align 8
br label%br
bO:
%bP=getelementptr inbounds i8,i8*%bv,i64 8
%bQ=bitcast i8*%bP to i8**
%bR=load i8*,i8**%bQ,align 8
store i8*%bR,i8**%i,align 8
%bS=getelementptr inbounds i8,i8*%be,i64 8
%bT=bitcast i8*%bS to i8**
%bU=load i8*,i8**%bT,align 8
store i8*%bU,i8**%h,align 8
%bV=call i8*@sml_alloc(i32 inreg 20)#0
%bW=getelementptr inbounds i8,i8*%bV,i64 -4
%bX=bitcast i8*%bW to i32*
store i32 1342177296,i32*%bX,align 4
%bY=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bZ=bitcast i8*%bV to i8**
store i8*%bY,i8**%bZ,align 8
%b0=load i8*,i8**%f,align 8
%b1=getelementptr inbounds i8,i8*%bV,i64 8
%b2=bitcast i8*%b1 to i8**
store i8*%b0,i8**%b2,align 8
%b3=getelementptr inbounds i8,i8*%bV,i64 16
%b4=bitcast i8*%b3 to i32*
store i32 3,i32*%b4,align 4
%b5=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*%bV,i8**%f,align 8
br label%br
b6:
%b7=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%i,align 8
br label%b8
b8:
%b9=phi i8*[%b7,%b6],[%cp,%co]
%ca=icmp eq i8*%b9,null
br i1%ca,label%cb,label%cq
cb:
%cc=load i8*,i8**%f,align 8
%cd=icmp eq i8*%cc,null
br i1%cd,label%ce,label%ci
ce:
%cf=load i8*,i8**%i,align 8
%cg=load i8*,i8**%g,align 8
store i8*%cg,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%i,align 8
%ch=bitcast i8**%j to i32**
br label%c3
ci:
%cj=bitcast i8*%cc to i8**
%ck=load i8*,i8**%cj,align 8
%cl=getelementptr inbounds i8,i8*%cc,i64 8
%cm=bitcast i8*%cl to i8**
%cn=load i8*,i8**%cm,align 8
store i8*%cn,i8**%f,align 8
br label%co
co:
%cp=phi i8*[%ck,%ci],[%cK,%cw],[%c2,%cL]
br label%b8
cq:
%cr=bitcast i8*%b9 to i8**
%cs=load i8*,i8**%cr,align 8
store i8*%cs,i8**%j,align 8
%ct=bitcast i8*%cs to i32*
%cu=load i32,i32*%ct,align 4
%cv=icmp eq i32%cu,4
br i1%cv,label%cL,label%cw
cw:
%cx=getelementptr inbounds i8,i8*%b9,i64 8
%cy=bitcast i8*%cx to i8**
%cz=load i8*,i8**%cy,align 8
store i8*%cz,i8**%k,align 8
%cA=call i8*@sml_alloc(i32 inreg 20)#0
%cB=getelementptr inbounds i8,i8*%cA,i64 -4
%cC=bitcast i8*%cB to i32*
store i32 1342177296,i32*%cC,align 4
%cD=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cE=bitcast i8*%cA to i8**
store i8*%cD,i8**%cE,align 8
%cF=load i8*,i8**%i,align 8
%cG=getelementptr inbounds i8,i8*%cA,i64 8
%cH=bitcast i8*%cG to i8**
store i8*%cF,i8**%cH,align 8
%cI=getelementptr inbounds i8,i8*%cA,i64 16
%cJ=bitcast i8*%cI to i32*
store i32 3,i32*%cJ,align 4
%cK=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%cA,i8**%i,align 8
br label%co
cL:
%cM=getelementptr inbounds i8,i8*%cs,i64 8
%cN=bitcast i8*%cM to i8**
%cO=load i8*,i8**%cN,align 8
store i8*%cO,i8**%k,align 8
%cP=getelementptr inbounds i8,i8*%b9,i64 8
%cQ=bitcast i8*%cP to i8**
%cR=load i8*,i8**%cQ,align 8
store i8*%cR,i8**%j,align 8
%cS=call i8*@sml_alloc(i32 inreg 20)#0
%cT=getelementptr inbounds i8,i8*%cS,i64 -4
%cU=bitcast i8*%cT to i32*
store i32 1342177296,i32*%cU,align 4
%cV=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cW=bitcast i8*%cS to i8**
store i8*%cV,i8**%cW,align 8
%cX=load i8*,i8**%f,align 8
%cY=getelementptr inbounds i8,i8*%cS,i64 8
%cZ=bitcast i8*%cY to i8**
store i8*%cX,i8**%cZ,align 8
%c0=getelementptr inbounds i8,i8*%cS,i64 16
%c1=bitcast i8*%c0 to i32*
store i32 3,i32*%c1,align 4
%c2=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%cS,i8**%f,align 8
br label%co
c3:
%c4=phi i8*[%cf,%ce],[%di,%dh]
%c5=icmp eq i8*%c4,null
br i1%c5,label%c6,label%dj
c6:
%c7=load i8*,i8**%g,align 8
%c8=icmp eq i8*%c7,null
br i1%c8,label%c9,label%db
c9:
store i8*null,i8**%h,align 8
store i8*null,i8**%g,align 8
%da=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*%da,i8**%f,align 8
br label%ga
db:
%dc=bitcast i8*%c7 to i8**
%dd=load i8*,i8**%dc,align 8
%de=getelementptr inbounds i8,i8*%c7,i64 8
%df=bitcast i8*%de to i8**
%dg=load i8*,i8**%df,align 8
store i8*%dg,i8**%g,align 8
br label%dh
dh:
%di=phi i8*[%dd,%db],[%dJ,%dI],[%dM,%dK],[%dP,%dN],[%d7,%dQ]
br label%c3
dj:
%dk=bitcast i8*%c4 to i8**
%dl=load i8*,i8**%dk,align 8
store i8*%dl,i8**%j,align 8
%dm=bitcast i8*%dl to i32*
%dn=load i32,i32*%dm,align 4
%do=icmp eq i32%dn,4
br i1%do,label%dQ,label%dp
dp:
%dq=getelementptr inbounds i8,i8*%c4,i64 8
%dr=bitcast i8*%dq to i8**
%ds=load i8*,i8**%dr,align 8
store i8*%ds,i8**%k,align 8
%dt=load i8*,i8**%f,align 8
%du=load i8*,i8**%l,align 8
%dv=call fastcc i8*@_SMLLL5visit_71(i8*inreg%du,i8*inreg%dt,i8*inreg%dl)
store i8*%dv,i8**%m,align 8
%dw=call i8*@sml_alloc(i32 inreg 20)#0
%dx=getelementptr inbounds i8,i8*%dw,i64 -4
%dy=bitcast i8*%dx to i32*
store i32 1342177296,i32*%dy,align 4
%dz=load i8*,i8**%m,align 8
store i8*null,i8**%m,align 8
%dA=bitcast i8*%dw to i8**
store i8*%dz,i8**%dA,align 8
%dB=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%dC=getelementptr inbounds i8,i8*%dw,i64 8
%dD=bitcast i8*%dC to i8**
store i8*%dB,i8**%dD,align 8
%dE=getelementptr inbounds i8,i8*%dw,i64 16
%dF=bitcast i8*%dE to i32*
store i32 3,i32*%dF,align 4
%dG=load i32*,i32**%ch,align 8
store i8*null,i8**%j,align 8
%dH=load i32,i32*%dG,align 4
switch i32%dH,label%dI[
i32 6,label%dN
i32 1,label%dK
]
dI:
%dJ=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%dw,i8**%i,align 8
br label%dh
dK:
%dL=load i8*,i8**%h,align 8
%dM=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%dL,i8**%f,align 8
store i8*%dw,i8**%i,align 8
br label%dh
dN:
%dO=load i8*,i8**%h,align 8
%dP=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%dO,i8**%f,align 8
store i8*%dw,i8**%i,align 8
br label%dh
dQ:
%dR=getelementptr inbounds i8,i8*%dl,i64 8
%dS=bitcast i8*%dR to i8**
%dT=load i8*,i8**%dS,align 8
store i8*%dT,i8**%k,align 8
%dU=getelementptr inbounds i8,i8*%c4,i64 8
%dV=bitcast i8*%dU to i8**
%dW=load i8*,i8**%dV,align 8
store i8*%dW,i8**%j,align 8
%dX=call i8*@sml_alloc(i32 inreg 20)#0
%dY=getelementptr inbounds i8,i8*%dX,i64 -4
%dZ=bitcast i8*%dY to i32*
store i32 1342177296,i32*%dZ,align 4
%d0=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%d1=bitcast i8*%dX to i8**
store i8*%d0,i8**%d1,align 8
%d2=load i8*,i8**%g,align 8
%d3=getelementptr inbounds i8,i8*%dX,i64 8
%d4=bitcast i8*%d3 to i8**
store i8*%d2,i8**%d4,align 8
%d5=getelementptr inbounds i8,i8*%dX,i64 16
%d6=bitcast i8*%d5 to i32*
store i32 3,i32*%d6,align 4
%d7=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%dX,i8**%g,align 8
br label%dh
d8:
%d9=load i8*,i8**%f,align 8
%ea=load i8*,i8**%g,align 8
store i8*%ea,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%i,align 8
%eb=bitcast i8**%j to i32**
br label%ec
ec:
%ed=phi i8*[%d9,%d8],[%er,%eq]
%ee=icmp eq i8*%ed,null
br i1%ee,label%ef,label%es
ef:
%eg=load i8*,i8**%g,align 8
%eh=icmp eq i8*%eg,null
br i1%eh,label%ei,label%ek
ei:
store i8*null,i8**%h,align 8
%ej=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
br label%fh
ek:
%el=bitcast i8*%eg to i8**
%em=load i8*,i8**%el,align 8
%en=getelementptr inbounds i8,i8*%eg,i64 8
%eo=bitcast i8*%en to i8**
%ep=load i8*,i8**%eo,align 8
store i8*%ep,i8**%g,align 8
br label%eq
eq:
%er=phi i8*[%em,%ek],[%eS,%eR],[%eV,%eT],[%eY,%eW],[%fg,%eZ]
br label%ec
es:
%et=bitcast i8*%ed to i8**
%eu=load i8*,i8**%et,align 8
store i8*%eu,i8**%j,align 8
%ev=bitcast i8*%eu to i32*
%ew=load i32,i32*%ev,align 4
%ex=icmp eq i32%ew,4
br i1%ex,label%eZ,label%ey
ey:
%ez=getelementptr inbounds i8,i8*%ed,i64 8
%eA=bitcast i8*%ez to i8**
%eB=load i8*,i8**%eA,align 8
store i8*%eB,i8**%k,align 8
%eC=load i8*,i8**%f,align 8
%eD=load i8*,i8**%l,align 8
%eE=call fastcc i8*@_SMLLL5visit_71(i8*inreg%eD,i8*inreg%eC,i8*inreg%eu)
store i8*%eE,i8**%m,align 8
%eF=call i8*@sml_alloc(i32 inreg 20)#0
%eG=getelementptr inbounds i8,i8*%eF,i64 -4
%eH=bitcast i8*%eG to i32*
store i32 1342177296,i32*%eH,align 4
%eI=load i8*,i8**%m,align 8
store i8*null,i8**%m,align 8
%eJ=bitcast i8*%eF to i8**
store i8*%eI,i8**%eJ,align 8
%eK=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%eL=getelementptr inbounds i8,i8*%eF,i64 8
%eM=bitcast i8*%eL to i8**
store i8*%eK,i8**%eM,align 8
%eN=getelementptr inbounds i8,i8*%eF,i64 16
%eO=bitcast i8*%eN to i32*
store i32 3,i32*%eO,align 4
%eP=load i32*,i32**%eb,align 8
store i8*null,i8**%j,align 8
%eQ=load i32,i32*%eP,align 4
switch i32%eQ,label%eR[
i32 6,label%eW
i32 1,label%eT
]
eR:
%eS=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%eF,i8**%i,align 8
br label%eq
eT:
%eU=load i8*,i8**%h,align 8
%eV=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%eU,i8**%f,align 8
store i8*%eF,i8**%i,align 8
br label%eq
eW:
%eX=load i8*,i8**%h,align 8
%eY=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%eX,i8**%f,align 8
store i8*%eF,i8**%i,align 8
br label%eq
eZ:
%e0=getelementptr inbounds i8,i8*%eu,i64 8
%e1=bitcast i8*%e0 to i8**
%e2=load i8*,i8**%e1,align 8
store i8*%e2,i8**%k,align 8
%e3=getelementptr inbounds i8,i8*%ed,i64 8
%e4=bitcast i8*%e3 to i8**
%e5=load i8*,i8**%e4,align 8
store i8*%e5,i8**%j,align 8
%e6=call i8*@sml_alloc(i32 inreg 20)#0
%e7=getelementptr inbounds i8,i8*%e6,i64 -4
%e8=bitcast i8*%e7 to i32*
store i32 1342177296,i32*%e8,align 4
%e9=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%fa=bitcast i8*%e6 to i8**
store i8*%e9,i8**%fa,align 8
%fb=load i8*,i8**%g,align 8
%fc=getelementptr inbounds i8,i8*%e6,i64 8
%fd=bitcast i8*%fc to i8**
store i8*%fb,i8**%fd,align 8
%fe=getelementptr inbounds i8,i8*%e6,i64 16
%ff=bitcast i8*%fe to i32*
store i32 3,i32*%ff,align 4
%fg=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%e6,i8**%g,align 8
br label%eq
fh:
%fi=phi i8*[%ej,%ei],[%fw,%fv]
%fj=icmp eq i8*%fi,null
br i1%fj,label%fk,label%fx
fk:
%fl=load i8*,i8**%f,align 8
%fm=icmp eq i8*%fl,null
br i1%fm,label%fn,label%fp
fn:
%fo=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
store i8*%fo,i8**%f,align 8
br label%ga
fp:
%fq=bitcast i8*%fl to i8**
%fr=load i8*,i8**%fq,align 8
%fs=getelementptr inbounds i8,i8*%fl,i64 8
%ft=bitcast i8*%fs to i8**
%fu=load i8*,i8**%ft,align 8
store i8*%fu,i8**%f,align 8
br label%fv
fv:
%fw=phi i8*[%fr,%fp],[%fR,%fD],[%f9,%fS]
br label%fh
fx:
%fy=bitcast i8*%fi to i8**
%fz=load i8*,i8**%fy,align 8
store i8*%fz,i8**%h,align 8
%fA=bitcast i8*%fz to i32*
%fB=load i32,i32*%fA,align 4
%fC=icmp eq i32%fB,4
br i1%fC,label%fS,label%fD
fD:
%fE=getelementptr inbounds i8,i8*%fi,i64 8
%fF=bitcast i8*%fE to i8**
%fG=load i8*,i8**%fF,align 8
store i8*%fG,i8**%i,align 8
%fH=call i8*@sml_alloc(i32 inreg 20)#0
%fI=getelementptr inbounds i8,i8*%fH,i64 -4
%fJ=bitcast i8*%fI to i32*
store i32 1342177296,i32*%fJ,align 4
%fK=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%fL=bitcast i8*%fH to i8**
store i8*%fK,i8**%fL,align 8
%fM=load i8*,i8**%g,align 8
%fN=getelementptr inbounds i8,i8*%fH,i64 8
%fO=bitcast i8*%fN to i8**
store i8*%fM,i8**%fO,align 8
%fP=getelementptr inbounds i8,i8*%fH,i64 16
%fQ=bitcast i8*%fP to i32*
store i32 3,i32*%fQ,align 4
%fR=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*%fH,i8**%g,align 8
br label%fv
fS:
%fT=getelementptr inbounds i8,i8*%fz,i64 8
%fU=bitcast i8*%fT to i8**
%fV=load i8*,i8**%fU,align 8
store i8*%fV,i8**%i,align 8
%fW=getelementptr inbounds i8,i8*%fi,i64 8
%fX=bitcast i8*%fW to i8**
%fY=load i8*,i8**%fX,align 8
store i8*%fY,i8**%h,align 8
%fZ=call i8*@sml_alloc(i32 inreg 20)#0
%f0=getelementptr inbounds i8,i8*%fZ,i64 -4
%f1=bitcast i8*%f0 to i32*
store i32 1342177296,i32*%f1,align 4
%f2=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%f3=bitcast i8*%fZ to i8**
store i8*%f2,i8**%f3,align 8
%f4=load i8*,i8**%f,align 8
%f5=getelementptr inbounds i8,i8*%fZ,i64 8
%f6=bitcast i8*%f5 to i8**
store i8*%f4,i8**%f6,align 8
%f7=getelementptr inbounds i8,i8*%fZ,i64 16
%f8=bitcast i8*%f7 to i32*
store i32 3,i32*%f8,align 4
%f9=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
store i8*%fZ,i8**%f,align 8
br label%fv
ga:
%gb=load i8*,i8**%e,align 8
%gc=icmp eq i8*%gb,null
br i1%gc,label%gd,label%gy
gd:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%l,align 8
%ge=call i8*@sml_alloc(i32 inreg 20)#0
%gf=getelementptr inbounds i8,i8*%ge,i64 -4
%gg=bitcast i8*%gf to i32*
store i32 1342177296,i32*%gg,align 4
store i8*%ge,i8**%d,align 8
%gh=bitcast i8*%ge to i8**
store i8*null,i8**%gh,align 8
%gi=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%gj=getelementptr inbounds i8,i8*%ge,i64 8
%gk=bitcast i8*%gj to i8**
store i8*%gi,i8**%gk,align 8
%gl=getelementptr inbounds i8,i8*%ge,i64 16
%gm=bitcast i8*%gl to i32*
store i32 3,i32*%gm,align 4
%gn=call i8*@sml_alloc(i32 inreg 20)#0
%go=bitcast i8*%gn to i32*
%gp=getelementptr inbounds i8,i8*%gn,i64 -4
%gq=bitcast i8*%gp to i32*
store i32 1342177296,i32*%gq,align 4
%gr=getelementptr inbounds i8,i8*%gn,i64 4
%gs=bitcast i8*%gr to i32*
store i32 0,i32*%gs,align 1
store i32 1,i32*%go,align 4
%gt=load i8*,i8**%d,align 8
%gu=getelementptr inbounds i8,i8*%gn,i64 8
%gv=bitcast i8*%gu to i8**
store i8*%gt,i8**%gv,align 8
%gw=getelementptr inbounds i8,i8*%gn,i64 16
%gx=bitcast i8*%gw to i32*
store i32 2,i32*%gx,align 4
ret i8*%gn
gy:
store i8*null,i8**%e,align 8
%gz=bitcast i8*%gb to i8**
%gA=load i8*,i8**%gz,align 8
%gB=bitcast i8*%gA to i32*
%gC=load i32,i32*%gB,align 4
%gD=icmp eq i32%gC,0
br i1%gD,label%gZ,label%gE
gE:
store i8*null,i8**%d,align 8
store i8*null,i8**%l,align 8
%gF=call i8*@sml_alloc(i32 inreg 20)#0
%gG=getelementptr inbounds i8,i8*%gF,i64 -4
%gH=bitcast i8*%gG to i32*
store i32 1342177296,i32*%gH,align 4
store i8*%gF,i8**%d,align 8
%gI=bitcast i8*%gF to i8**
store i8*null,i8**%gI,align 8
%gJ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%gK=getelementptr inbounds i8,i8*%gF,i64 8
%gL=bitcast i8*%gK to i8**
store i8*%gJ,i8**%gL,align 8
%gM=getelementptr inbounds i8,i8*%gF,i64 16
%gN=bitcast i8*%gM to i32*
store i32 3,i32*%gN,align 4
%gO=call i8*@sml_alloc(i32 inreg 20)#0
%gP=bitcast i8*%gO to i32*
%gQ=getelementptr inbounds i8,i8*%gO,i64 -4
%gR=bitcast i8*%gQ to i32*
store i32 1342177296,i32*%gR,align 4
%gS=getelementptr inbounds i8,i8*%gO,i64 4
%gT=bitcast i8*%gS to i32*
store i32 0,i32*%gT,align 1
store i32 1,i32*%gP,align 4
%gU=load i8*,i8**%d,align 8
%gV=getelementptr inbounds i8,i8*%gO,i64 8
%gW=bitcast i8*%gV to i8**
store i8*%gU,i8**%gW,align 8
%gX=getelementptr inbounds i8,i8*%gO,i64 16
%gY=bitcast i8*%gX to i32*
store i32 2,i32*%gY,align 4
ret i8*%gO
gZ:
%g0=load i8*,i8**%d,align 8
%g1=getelementptr inbounds i8,i8*%g0,i64 8
%g2=bitcast i8*%g1 to i32*
%g3=load i32,i32*%g2,align 4
%g4=getelementptr inbounds i8,i8*%gA,i64 8
%g5=bitcast i8*%g4 to i32*
%g6=load i32,i32*%g5,align 4
%g7=icmp slt i32%g3,%g6
br i1%g7,label%hl,label%g8
g8:
%g9=icmp eq i32%g3,%g6
br i1%g9,label%ha,label%hm
ha:
%hb=getelementptr inbounds i8,i8*%g0,i64 4
%hc=bitcast i8*%hb to i32*
%hd=load i32,i32*%hc,align 4
%he=getelementptr inbounds i8,i8*%gA,i64 4
%hf=bitcast i8*%he to i32*
%hg=load i32,i32*%hf,align 4
switch i32%hd,label%hn[
i32 0,label%hj
i32 2,label%hh
]
hh:
%hi=icmp eq i32%hg,1
br i1%hi,label%hl,label%hn
hj:
%hk=icmp eq i32%hg,1
br i1%hk,label%hl,label%hn
hl:
store i8*null,i8**%d,align 8
br label%hr
hm:
store i8*null,i8**%d,align 8
br label%hM
hn:
store i8*null,i8**%d,align 8
%ho=load i32,i32*%hc,align 4
%hp=load i32,i32*%hf,align 4
%hq=icmp eq i32%ho,%hp
br i1%hq,label%hr,label%hM
hr:
store i8*null,i8**%l,align 8
%hs=call i8*@sml_alloc(i32 inreg 20)#0
%ht=getelementptr inbounds i8,i8*%hs,i64 -4
%hu=bitcast i8*%ht to i32*
store i32 1342177296,i32*%hu,align 4
store i8*%hs,i8**%d,align 8
%hv=bitcast i8*%hs to i8**
store i8*null,i8**%hv,align 8
%hw=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%hx=getelementptr inbounds i8,i8*%hs,i64 8
%hy=bitcast i8*%hx to i8**
store i8*%hw,i8**%hy,align 8
%hz=getelementptr inbounds i8,i8*%hs,i64 16
%hA=bitcast i8*%hz to i32*
store i32 3,i32*%hA,align 4
%hB=call i8*@sml_alloc(i32 inreg 20)#0
%hC=bitcast i8*%hB to i32*
%hD=getelementptr inbounds i8,i8*%hB,i64 -4
%hE=bitcast i8*%hD to i32*
store i32 1342177296,i32*%hE,align 4
%hF=getelementptr inbounds i8,i8*%hB,i64 4
%hG=bitcast i8*%hF to i32*
store i32 0,i32*%hG,align 1
store i32 1,i32*%hC,align 4
%hH=load i8*,i8**%d,align 8
%hI=getelementptr inbounds i8,i8*%hB,i64 8
%hJ=bitcast i8*%hI to i8**
store i8*%hH,i8**%hJ,align 8
%hK=getelementptr inbounds i8,i8*%hB,i64 16
%hL=bitcast i8*%hK to i32*
store i32 2,i32*%hL,align 4
ret i8*%hB
hM:
%hN=bitcast i8**%l to i8***
%hO=load i8**,i8***%hN,align 8
%hP=load i8*,i8**%hO,align 8
%hQ=getelementptr inbounds i8,i8*%hP,i64 8
%hR=bitcast i8*%hQ to i8**
%hS=load i8*,i8**%hR,align 8
store i8*%hS,i8**%d,align 8
%hT=call i8*@sml_alloc(i32 inreg 20)#0
%hU=getelementptr inbounds i8,i8*%hT,i64 -4
%hV=bitcast i8*%hU to i32*
store i32 1342177296,i32*%hV,align 4
store i8*%hT,i8**%e,align 8
%hW=getelementptr inbounds i8,i8*%hT,i64 4
%hX=bitcast i8*%hW to i32*
store i32 0,i32*%hX,align 1
%hY=bitcast i8*%hT to i32*
store i32 1,i32*%hY,align 4
%hZ=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%h0=getelementptr inbounds i8,i8*%hT,i64 8
%h1=bitcast i8*%h0 to i8**
store i8*%hZ,i8**%h1,align 8
%h2=getelementptr inbounds i8,i8*%hT,i64 16
%h3=bitcast i8*%h2 to i32*
store i32 2,i32*%h3,align 4
%h4=call i8*@sml_alloc(i32 inreg 20)#0
%h5=getelementptr inbounds i8,i8*%h4,i64 -4
%h6=bitcast i8*%h5 to i32*
store i32 1342177296,i32*%h6,align 4
store i8*%h4,i8**%g,align 8
%h7=getelementptr inbounds i8,i8*%h4,i64 4
%h8=bitcast i8*%h7 to i32*
store i32 0,i32*%h8,align 1
%h9=bitcast i8*%h4 to i32*
store i32 6,i32*%h9,align 4
%ia=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ib=getelementptr inbounds i8,i8*%h4,i64 8
%ic=bitcast i8*%ib to i8**
store i8*%ia,i8**%ic,align 8
%id=getelementptr inbounds i8,i8*%h4,i64 16
%ie=bitcast i8*%id to i32*
store i32 2,i32*%ie,align 4
%if=call i8*@sml_alloc(i32 inreg 20)#0
%ig=getelementptr inbounds i8,i8*%if,i64 -4
%ih=bitcast i8*%ig to i32*
store i32 1342177296,i32*%ih,align 4
store i8*%if,i8**%h,align 8
%ii=getelementptr inbounds i8,i8*%if,i64 4
%ij=bitcast i8*%ii to i32*
store i32 0,i32*%ij,align 1
%ik=bitcast i8*%if to i32*
store i32 4,i32*%ik,align 4
%il=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%im=getelementptr inbounds i8,i8*%if,i64 8
%in=bitcast i8*%im to i8**
store i8*%il,i8**%in,align 8
%io=getelementptr inbounds i8,i8*%if,i64 16
%ip=bitcast i8*%io to i32*
store i32 2,i32*%ip,align 4
%iq=load i8**,i8***%hN,align 8
store i8*null,i8**%l,align 8
%ir=load i8*,i8**%iq,align 8
%is=getelementptr inbounds i8,i8*%ir,i64 16
%it=bitcast i8*%is to i8**
%iu=load i8*,i8**%it,align 8
store i8*%iu,i8**%d,align 8
%iv=call i8*@sml_alloc(i32 inreg 20)#0
%iw=getelementptr inbounds i8,i8*%iv,i64 -4
%ix=bitcast i8*%iw to i32*
store i32 1342177296,i32*%ix,align 4
store i8*%iv,i8**%e,align 8
%iy=getelementptr inbounds i8,i8*%iv,i64 4
%iz=bitcast i8*%iy to i32*
store i32 0,i32*%iz,align 1
%iA=bitcast i8*%iv to i32*
store i32 1,i32*%iA,align 4
%iB=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%iC=getelementptr inbounds i8,i8*%iv,i64 8
%iD=bitcast i8*%iC to i8**
store i8*%iB,i8**%iD,align 8
%iE=getelementptr inbounds i8,i8*%iv,i64 16
%iF=bitcast i8*%iE to i32*
store i32 2,i32*%iF,align 4
%iG=call i8*@sml_alloc(i32 inreg 20)#0
%iH=getelementptr inbounds i8,i8*%iG,i64 -4
%iI=bitcast i8*%iH to i32*
store i32 1342177296,i32*%iI,align 4
store i8*%iG,i8**%d,align 8
%iJ=getelementptr inbounds i8,i8*%iG,i64 4
%iK=bitcast i8*%iJ to i32*
store i32 0,i32*%iK,align 1
%iL=bitcast i8*%iG to i32*
store i32 6,i32*%iL,align 4
%iM=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%iN=getelementptr inbounds i8,i8*%iG,i64 8
%iO=bitcast i8*%iN to i8**
store i8*%iM,i8**%iO,align 8
%iP=getelementptr inbounds i8,i8*%iG,i64 16
%iQ=bitcast i8*%iP to i32*
store i32 2,i32*%iQ,align 4
%iR=call i8*@sml_alloc(i32 inreg 20)#0
%iS=getelementptr inbounds i8,i8*%iR,i64 -4
%iT=bitcast i8*%iS to i32*
store i32 1342177296,i32*%iT,align 4
store i8*%iR,i8**%e,align 8
%iU=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%iV=bitcast i8*%iR to i8**
store i8*%iU,i8**%iV,align 8
%iW=getelementptr inbounds i8,i8*%iR,i64 8
%iX=bitcast i8*%iW to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@c,i64 0,i32 2)to i8*),i8**%iX,align 8
%iY=getelementptr inbounds i8,i8*%iR,i64 16
%iZ=bitcast i8*%iY to i32*
store i32 3,i32*%iZ,align 4
%i0=call i8*@sml_alloc(i32 inreg 20)#0
%i1=getelementptr inbounds i8,i8*%i0,i64 -4
%i2=bitcast i8*%i1 to i32*
store i32 1342177296,i32*%i2,align 4
store i8*%i0,i8**%d,align 8
%i3=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%i4=bitcast i8*%i0 to i8**
store i8*%i3,i8**%i4,align 8
%i5=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%i6=getelementptr inbounds i8,i8*%i0,i64 8
%i7=bitcast i8*%i6 to i8**
store i8*%i5,i8**%i7,align 8
%i8=getelementptr inbounds i8,i8*%i0,i64 16
%i9=bitcast i8*%i8 to i32*
store i32 3,i32*%i9,align 4
%ja=call i8*@sml_alloc(i32 inreg 20)#0
%jb=getelementptr inbounds i8,i8*%ja,i64 -4
%jc=bitcast i8*%jb to i32*
store i32 1342177296,i32*%jc,align 4
store i8*%ja,i8**%e,align 8
%jd=bitcast i8*%ja to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@a,i64 0,i32 2)to i8*),i8**%jd,align 8
%je=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%jf=getelementptr inbounds i8,i8*%ja,i64 8
%jg=bitcast i8*%jf to i8**
store i8*%je,i8**%jg,align 8
%jh=getelementptr inbounds i8,i8*%ja,i64 16
%ji=bitcast i8*%jh to i32*
store i32 3,i32*%ji,align 4
%jj=call i8*@sml_alloc(i32 inreg 20)#0
%jk=getelementptr inbounds i8,i8*%jj,i64 -4
%jl=bitcast i8*%jk to i32*
store i32 1342177296,i32*%jl,align 4
store i8*%jj,i8**%f,align 8
%jm=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%jn=bitcast i8*%jj to i8**
store i8*%jm,i8**%jn,align 8
%jo=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%jp=getelementptr inbounds i8,i8*%jj,i64 8
%jq=bitcast i8*%jp to i8**
store i8*%jo,i8**%jq,align 8
%jr=getelementptr inbounds i8,i8*%jj,i64 16
%js=bitcast i8*%jr to i32*
store i32 3,i32*%js,align 4
%jt=call i8*@sml_alloc(i32 inreg 20)#0
%ju=getelementptr inbounds i8,i8*%jt,i64 -4
%jv=bitcast i8*%ju to i32*
store i32 1342177296,i32*%jv,align 4
store i8*%jt,i8**%d,align 8
%jw=bitcast i8*%jt to i8**
store i8*null,i8**%jw,align 8
%jx=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%jy=getelementptr inbounds i8,i8*%jt,i64 8
%jz=bitcast i8*%jy to i8**
store i8*%jx,i8**%jz,align 8
%jA=getelementptr inbounds i8,i8*%jt,i64 16
%jB=bitcast i8*%jA to i32*
store i32 3,i32*%jB,align 4
%jC=call i8*@sml_alloc(i32 inreg 20)#0
%jD=bitcast i8*%jC to i32*
%jE=getelementptr inbounds i8,i8*%jC,i64 -4
%jF=bitcast i8*%jE to i32*
store i32 1342177296,i32*%jF,align 4
%jG=getelementptr inbounds i8,i8*%jC,i64 4
%jH=bitcast i8*%jG to i32*
store i32 0,i32*%jH,align 1
store i32 1,i32*%jD,align 4
%jI=load i8*,i8**%d,align 8
%jJ=getelementptr inbounds i8,i8*%jC,i64 8
%jK=bitcast i8*%jJ to i8**
store i8*%jI,i8**%jK,align 8
%jL=getelementptr inbounds i8,i8*%jC,i64 16
%jM=bitcast i8*%jL to i32*
store i32 2,i32*%jM,align 4
ret i8*%jC
}
define internal fastcc i8*@_SMLLLN13AssocResolver7resolveE_76(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLL5visit_71 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%w,i64 16
%E=bitcast i8*%D to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLL5visit_71 to void(...)*),void(...)**%E,align 8
%F=getelementptr inbounds i8,i8*%w,i64 24
%G=bitcast i8*%F to i32*
store i32 -2147483647,i32*%G,align 4
%H=load i8*,i8**%c,align 8
%I=tail call fastcc i8*@_SMLLL5visit_71(i8*inreg%z,i8*inreg bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,i32,i32,[4x i8],i32}>*@d,i64 0,i32 2)to i8*),i8*inreg%H)
ret i8*%I
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AssocResolver7resolveE_76 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN13AssocResolver7resolveE_76 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLLN13AssocResolver7resolveE_79(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN13AssocResolver7resolveE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
attributes#3={uwtable}
