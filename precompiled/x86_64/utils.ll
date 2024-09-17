@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306360,i8*null,i32 1}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN9ListUtils5splitE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN9ListUtils5splitE_76 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9ListUtils5splitE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN9ListUtils10prefixListE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN9ListUtils10prefixListE_77 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9ListUtils10prefixListE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN9ListUtils6listEqE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN9ListUtils6listEqE_78 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9ListUtils6listEqE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SML_ftaba87fdf662616c39b_utils=external global i8
@e=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN4List3revE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN4List5foldlE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
define private void@_SML_tabba87fdf662616c39b_utils()#2{
unreachable
}
define void@_SML_loada87fdf662616c39b_utils(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@e,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@e,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabba87fdf662616c39b_utils,i8*@_SML_ftaba87fdf662616c39b_utils,i8*null)#0
ret void
}
define void@_SML_maina87fdf662616c39b_utils()local_unnamed_addr#1 gc"smlsharp"{
tail call void@_SML_main03d87556ec7f64b2_List()#1
ret void
}
define internal fastcc i8*@_SMLL4loop_42(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
j:
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
store i8*%a,i8**%g,align 8
br label%h
h:
%i=phi i8*[%bm,%bf],[%b,%j]
store i8*%i,i8**%c,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%c,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%i,%h]
%q=load i8*,i8**%g,align 8
%r=getelementptr inbounds i8,i8*%q,i64 4
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=add i32%t,-1
%v=sub i32 0,%t
%w=and i32%u,%v
%x=add i32%t,7
%y=add i32%x,%w
%z=and i32%y,-8
%A=add i32%z,15
%B=and i32%A,-8
%C=lshr i32%y,3
%D=lshr i32%w,3
%E=sub nsw i32%C,%D
%F=shl i32 1,%E
%G=bitcast i8*%q to i32*
%H=load i32,i32*%G,align 4
%I=or i32%F,%H
%J=or i32%B,4
%K=bitcast i8*%p to i8**
%L=load i8*,i8**%K,align 8
%M=icmp eq i8*%L,null
br i1%M,label%N,label%aq
N:
%O=bitcast i8*%r to i32*
%P=getelementptr inbounds i8,i8*%p,i64 16
%Q=bitcast i8*%P to i32*
%R=load i32,i32*%Q,align 4
store i8*null,i8**%g,align 8
%S=load i32,i32*%O,align 4
%T=call fastcc i8*@_SMLFN4List3revE(i32 inreg%H,i32 inreg%S)
%U=getelementptr inbounds i8,i8*%T,i64 16
%V=bitcast i8*%U to i8*(i8*,i8*)**
%W=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%V,align 8
%X=bitcast i8*%T to i8**
%Y=load i8*,i8**%X,align 8
%Z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aa=getelementptr inbounds i8,i8*%Z,i64 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
%ad=call fastcc i8*%W(i8*inreg%Y,i8*inreg%ac)
store i8*%ad,i8**%c,align 8
%ae=icmp slt i32%R,1
%af=select i1%ae,i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i32}>,<{[4x i8],i32,i8*,i32}>*@a,i64 0,i32 2)to i8*),i8*null
store i8*%af,i8**%d,align 8
%ag=call i8*@sml_alloc(i32 inreg 20)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177296,i32*%ai,align 4
%aj=load i8*,i8**%c,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=load i8*,i8**%d,align 8
%am=getelementptr inbounds i8,i8*%ag,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ag,i64 16
%ap=bitcast i8*%ao to i32*
store i32 3,i32*%ap,align 4
ret i8*%ag
aq:
store i8*%L,i8**%e,align 8
%ar=load i32,i32*%G,align 4
%as=icmp eq i32%ar,0
br i1%as,label%ay,label%at
at:
%au=sext i32%w to i64
%av=getelementptr inbounds i8,i8*%L,i64%au
%aw=bitcast i8*%av to i8**
%ax=load i8*,i8**%aw,align 8
br label%aH
ay:
%az=load i32,i32*%s,align 4
%aA=call i8*@sml_alloc(i32 inreg%az)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32%az,i32*%aC,align 4
%aD=load i8*,i8**%e,align 8
%aE=sext i32%w to i64
%aF=getelementptr inbounds i8,i8*%aD,i64%aE
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aA,i8*%aF,i32%az,i1 false)
%aG=load i8*,i8**%c,align 8
br label%aH
aH:
%aI=phi i8*[%aG,%ay],[%p,%at]
%aJ=phi i8*[%aD,%ay],[%L,%at]
%aK=phi i8*[%aA,%ay],[%ax,%at]
store i8*%aK,i8**%d,align 8
%aL=sext i32%z to i64
%aM=getelementptr inbounds i8,i8*%aJ,i64%aL
%aN=bitcast i8*%aM to i8**
%aO=load i8*,i8**%aN,align 8
store i8*%aO,i8**%e,align 8
%aP=getelementptr inbounds i8,i8*%aI,i64 8
%aQ=bitcast i8*%aP to i8**
%aR=load i8*,i8**%aQ,align 8
store i8*%aR,i8**%f,align 8
store i8*null,i8**%c,align 8
%aS=getelementptr inbounds i8,i8*%aI,i64 16
%aT=bitcast i8*%aS to i32*
%aU=load i32,i32*%aT,align 4
%aV=icmp slt i32%aU,1
br i1%aV,label%bA,label%aW
aW:
%aX=add nsw i32%aU,-1
%aY=load i8*,i8**%g,align 8
%aZ=getelementptr inbounds i8,i8*%aY,i64 4
%a0=bitcast i8*%aZ to i32*
%a1=load i32,i32*%a0,align 4
%a2=bitcast i8*%aY to i32*
%a3=load i32,i32*%a2,align 4
%a4=call i8*@sml_alloc(i32 inreg%J)#0
%a5=or i32%B,1342177280
%a6=getelementptr inbounds i8,i8*%a4,i64 -4
%a7=bitcast i8*%a6 to i32*
store i32%a5,i32*%a7,align 4
store i8*%a4,i8**%c,align 8
call void@llvm.memset.p0i8.i32(i8*%a4,i8 0,i32%J,i1 false)
%a8=icmp eq i32%a3,0
%a9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ba=sext i32%w to i64
%bb=getelementptr inbounds i8,i8*%a4,i64%ba
br i1%a8,label%be,label%bc
bc:
%bd=bitcast i8*%bb to i8**
store i8*%a9,i8**%bd,align 8
br label%bf
be:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bb,i8*%a9,i32%a1,i1 false)
br label%bf
bf:
%bg=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bh=getelementptr inbounds i8,i8*%a4,i64%aL
%bi=bitcast i8*%bh to i8**
store i8*%bg,i8**%bi,align 8
%bj=sext i32%B to i64
%bk=getelementptr inbounds i8,i8*%a4,i64%bj
%bl=bitcast i8*%bk to i32*
store i32%I,i32*%bl,align 4
%bm=call i8*@sml_alloc(i32 inreg 28)#0
%bn=getelementptr inbounds i8,i8*%bm,i64 -4
%bo=bitcast i8*%bn to i32*
store i32 1342177304,i32*%bo,align 4
%bp=getelementptr inbounds i8,i8*%bm,i64 20
%bq=bitcast i8*%bp to i32*
store i32 0,i32*%bq,align 1
%br=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bs=bitcast i8*%bm to i8**
store i8*%br,i8**%bs,align 8
%bt=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bu=getelementptr inbounds i8,i8*%bm,i64 8
%bv=bitcast i8*%bu to i8**
store i8*%bt,i8**%bv,align 8
%bw=getelementptr inbounds i8,i8*%bm,i64 16
%bx=bitcast i8*%bw to i32*
store i32%aX,i32*%bx,align 4
%by=getelementptr inbounds i8,i8*%bm,i64 24
%bz=bitcast i8*%by to i32*
store i32 3,i32*%bz,align 4
br label%h
bA:
%bB=load i8*,i8**%g,align 8
%bC=bitcast i8*%bB to i32*
%bD=load i32,i32*%bC,align 4
%bE=getelementptr inbounds i8,i8*%bB,i64 4
%bF=bitcast i8*%bE to i32*
%bG=load i32,i32*%bF,align 4
%bH=call fastcc i8*@_SMLFN4List3revE(i32 inreg%bD,i32 inreg%bG)
%bI=getelementptr inbounds i8,i8*%bH,i64 16
%bJ=bitcast i8*%bI to i8*(i8*,i8*)**
%bK=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bJ,align 8
%bL=bitcast i8*%bH to i8**
%bM=load i8*,i8**%bL,align 8
%bN=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bO=call fastcc i8*%bK(i8*inreg%bM,i8*inreg%bN)
store i8*%bO,i8**%c,align 8
%bP=load i8*,i8**%g,align 8
%bQ=getelementptr inbounds i8,i8*%bP,i64 4
%bR=bitcast i8*%bQ to i32*
%bS=load i32,i32*%bR,align 4
store i8*null,i8**%g,align 8
%bT=bitcast i8*%bP to i32*
%bU=load i32,i32*%bT,align 4
%bV=call i8*@sml_alloc(i32 inreg%J)#0
%bW=or i32%B,1342177280
%bX=getelementptr inbounds i8,i8*%bV,i64 -4
%bY=bitcast i8*%bX to i32*
store i32%bW,i32*%bY,align 4
store i8*%bV,i8**%f,align 8
call void@llvm.memset.p0i8.i32(i8*%bV,i8 0,i32%J,i1 false)
%bZ=icmp eq i32%bU,0
%b0=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%b1=sext i32%w to i64
%b2=getelementptr inbounds i8,i8*%bV,i64%b1
br i1%bZ,label%b5,label%b3
b3:
%b4=bitcast i8*%b2 to i8**
store i8*%b0,i8**%b4,align 8
br label%b6
b5:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%b2,i8*%b0,i32%bS,i1 false)
br label%b6
b6:
%b7=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%b8=getelementptr inbounds i8,i8*%bV,i64%aL
%b9=bitcast i8*%b8 to i8**
store i8*%b7,i8**%b9,align 8
%ca=sext i32%B to i64
%cb=getelementptr inbounds i8,i8*%bV,i64%ca
%cc=bitcast i8*%cb to i32*
store i32%I,i32*%cc,align 4
%cd=call i8*@sml_alloc(i32 inreg 12)#0
%ce=getelementptr inbounds i8,i8*%cd,i64 -4
%cf=bitcast i8*%ce to i32*
store i32 1342177288,i32*%cf,align 4
store i8*%cd,i8**%d,align 8
%cg=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ch=bitcast i8*%cd to i8**
store i8*%cg,i8**%ch,align 8
%ci=getelementptr inbounds i8,i8*%cd,i64 8
%cj=bitcast i8*%ci to i32*
store i32 1,i32*%cj,align 4
%ck=call i8*@sml_alloc(i32 inreg 20)#0
%cl=getelementptr inbounds i8,i8*%ck,i64 -4
%cm=bitcast i8*%cl to i32*
store i32 1342177296,i32*%cm,align 4
%cn=load i8*,i8**%c,align 8
%co=bitcast i8*%ck to i8**
store i8*%cn,i8**%co,align 8
%cp=load i8*,i8**%d,align 8
%cq=getelementptr inbounds i8,i8*%ck,i64 8
%cr=bitcast i8*%cq to i8**
store i8*%cp,i8**%cr,align 8
%cs=getelementptr inbounds i8,i8*%ck,i64 16
%ct=bitcast i8*%cs to i32*
store i32 3,i32*%ct,align 4
ret i8*%ck
}
define internal fastcc i8*@_SMLLN9ListUtils5splitE_46(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
l:
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
%m=getelementptr inbounds i8,i8*%k,i64 8
%n=bitcast i8*%m to i32*
%o=load i32,i32*%n,align 4
%p=getelementptr inbounds i8,i8*%k,i64 12
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%s)
call void@llvm.gcroot(i8**%c,i8*null)#0
%t=call i8*@sml_alloc(i32 inreg 12)#0
%u=bitcast i8*%t to i32*
%v=getelementptr inbounds i8,i8*%t,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177288,i32*%w,align 4
store i8*%t,i8**%c,align 8
store i32%o,i32*%u,align 4
%x=getelementptr inbounds i8,i8*%t,i64 4
%y=bitcast i8*%x to i32*
store i32%r,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%t,i64 8
%A=bitcast i8*%z to i32*
store i32 0,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
%E=load i8*,i8**%c,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4loop_42 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4loop_42 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%s)
store i8*%E,i8**%e,align 8
%M=bitcast i8**%d to i8***
%N=load i8**,i8***%M,align 8
%O=load i8*,i8**%N,align 8
store i8*%O,i8**%d,align 8
%P=call i8*@sml_alloc(i32 inreg 28)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177304,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%P,i64 20
%T=bitcast i8*%S to i32*
store i32 0,i32*%T,align 1
%U=load i8*,i8**%d,align 8
%V=bitcast i8*%P to i8**
store i8*%U,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%P,i64 8
%X=bitcast i8*%W to i8**
store i8*null,i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%P,i64 16
%Z=bitcast i8*%Y to i32*
store i32%b,i32*%Z,align 4
%aa=getelementptr inbounds i8,i8*%P,i64 24
%ab=bitcast i8*%aa to i32*
store i32 3,i32*%ab,align 4
%ac=load i8*,i8**%e,align 8
%ad=tail call fastcc i8*@_SMLL4loop_42(i8*inreg%ac,i8*inreg%P)
ret i8*%ad
}
define internal fastcc i8*@_SMLLN9ListUtils5splitE_47(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLN9ListUtils5splitE_46 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils5splitE_70 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%u,i64 24
%E=bitcast i8*%D to i32*
store i32 -2147483647,i32*%E,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLN9ListUtils10prefixListE_50(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%f=getelementptr inbounds i8,i8*%a,i64 12
%g=bitcast i8*%f to i32*
%h=load i32,i32*%g,align 4
%i=add i32%h,-1
%j=sub i32 0,%h
%k=and i32%i,%j
%l=add i32%h,7
%m=add i32%l,%k
%n=and i32%m,-8
%o=add i32%n,15
%p=and i32%o,-8
%q=lshr i32%m,3
%r=lshr i32%k,3
%s=sub nsw i32%q,%r
%t=shl i32 1,%s
%u=getelementptr inbounds i8,i8*%a,i64 8
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=or i32%t,%w
%y=or i32%p,4
%z=icmp eq i32%w,0
br i1%z,label%D,label%A
A:
%B=bitcast i8*%a to i8**
%C=load i8*,i8**%B,align 8
br label%O
D:
%E=call i8*@sml_alloc(i32 inreg%h)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32%h,i32*%G,align 4
%H=load i8*,i8**%d,align 8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%E,i8*%H,i32%h,i1 false)
%I=getelementptr inbounds i8,i8*%H,i64 12
%J=bitcast i8*%I to i32*
%K=load i32,i32*%J,align 4
%L=getelementptr inbounds i8,i8*%H,i64 8
%M=bitcast i8*%L to i32*
%N=load i32,i32*%M,align 4
br label%O
O:
%P=phi i32[%N,%D],[%w,%A]
%Q=phi i32[%K,%D],[%h,%A]
%R=phi i8*[%E,%D],[%C,%A]
store i8*%R,i8**%e,align 8
store i8*null,i8**%d,align 8
%S=call i8*@sml_alloc(i32 inreg%y)#0
%T=or i32%p,1342177280
%U=getelementptr inbounds i8,i8*%S,i64 -4
%V=bitcast i8*%U to i32*
store i32%T,i32*%V,align 4
call void@llvm.memset.p0i8.i32(i8*%S,i8 0,i32%y,i1 false)
%W=icmp eq i32%P,0
%X=load i8*,i8**%e,align 8
%Y=sext i32%k to i64
%Z=getelementptr inbounds i8,i8*%S,i64%Y
br i1%W,label%ac,label%aa
aa:
%ab=bitcast i8*%Z to i8**
store i8*%X,i8**%ab,align 8
br label%ad
ac:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Z,i8*%X,i32%Q,i1 false)
br label%ad
ad:
%ae=load i8*,i8**%c,align 8
%af=sext i32%n to i64
%ag=getelementptr inbounds i8,i8*%S,i64%af
%ah=bitcast i8*%ag to i8**
store i8*%ae,i8**%ah,align 8
%ai=sext i32%p to i64
%aj=getelementptr inbounds i8,i8*%S,i64%ai
%ak=bitcast i8*%aj to i32*
store i32%x,i32*%ak,align 4
ret i8*%S
}
define internal fastcc i8*@_SMLLN9ListUtils10prefixListE_51(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
n:
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
store i8*%a,i8**%e,align 8
store i8*%b,i8**%c,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%e,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
%o=bitcast i8*%m to i32*
%p=load i32,i32*%o,align 4
%q=getelementptr inbounds i8,i8*%m,i64 4
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
%F=or i32%E,%p
%G=or i32%A,4
%H=icmp eq i32%p,0
br i1%H,label%O,label%I
I:
%J=load i8*,i8**%c,align 8
%K=sext i32%v to i64
%L=getelementptr inbounds i8,i8*%J,i64%K
%M=bitcast i8*%L to i8**
%N=load i8*,i8**%M,align 8
br label%V
O:
%P=call i8*@sml_alloc(i32 inreg%s)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32%s,i32*%R,align 4
%S=load i8*,i8**%c,align 8
%T=sext i32%v to i64
%U=getelementptr inbounds i8,i8*%S,i64%T
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%P,i8*%U,i32%s,i1 false)
br label%V
V:
%W=phi i8*[%P,%O],[%N,%I]
store i8*%W,i8**%d,align 8
%X=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%Y=getelementptr inbounds i8,i8*%X,i64 16
%Z=bitcast i8*%Y to i8*(i8*,i8*)**
%aa=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Z,align 8
%ab=bitcast i8*%X to i8**
%ac=load i8*,i8**%ab,align 8
store i8*%ac,i8**%f,align 8
%ad=load i8*,i8**%e,align 8
%ae=getelementptr inbounds i8,i8*%ad,i64 4
%af=bitcast i8*%ae to i32*
%ag=load i32,i32*%af,align 4
%ah=bitcast i8*%ad to i32*
%ai=load i32,i32*%ah,align 4
%aj=call i8*@sml_alloc(i32 inreg 20)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32 1342177296,i32*%al,align 4
store i8*%aj,i8**%g,align 8
%am=icmp eq i32%ai,0
%an=load i8*,i8**%d,align 8
br i1%am,label%aq,label%ao
ao:
%ap=bitcast i8*%aj to i8**
store i8*%an,i8**%ap,align 8
br label%ar
aq:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aj,i8*%an,i32%ag,i1 false)
br label%ar
ar:
%as=getelementptr inbounds i8,i8*%aj,i64 8
%at=bitcast i8*%as to i32*
store i32%ai,i32*%at,align 4
%au=getelementptr inbounds i8,i8*%aj,i64 12
%av=bitcast i8*%au to i32*
store i32%ag,i32*%av,align 4
%aw=getelementptr inbounds i8,i8*%aj,i64 16
%ax=bitcast i8*%aw to i32*
store i32%p,i32*%ax,align 4
%ay=call i8*@sml_alloc(i32 inreg 28)#0
%az=getelementptr inbounds i8,i8*%ay,i64 -4
%aA=bitcast i8*%az to i32*
store i32 1342177304,i32*%aA,align 4
%aB=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aC=bitcast i8*%ay to i8**
store i8*%aB,i8**%aC,align 8
%aD=getelementptr inbounds i8,i8*%ay,i64 8
%aE=bitcast i8*%aD to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_50 to void(...)*),void(...)**%aE,align 8
%aF=getelementptr inbounds i8,i8*%ay,i64 16
%aG=bitcast i8*%aF to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_50 to void(...)*),void(...)**%aG,align 8
%aH=getelementptr inbounds i8,i8*%ay,i64 24
%aI=bitcast i8*%aH to i32*
store i32 -2147483647,i32*%aI,align 4
%aJ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aK=call fastcc i8*%aa(i8*inreg%aJ,i8*inreg%ay)
%aL=getelementptr inbounds i8,i8*%aK,i64 16
%aM=bitcast i8*%aL to i8*(i8*,i8*)**
%aN=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aM,align 8
%aO=bitcast i8*%aK to i8**
%aP=load i8*,i8**%aO,align 8
%aQ=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aR=sext i32%y to i64
%aS=getelementptr inbounds i8,i8*%aQ,i64%aR
%aT=bitcast i8*%aS to i8**
%aU=load i8*,i8**%aT,align 8
%aV=call fastcc i8*%aN(i8*inreg%aP,i8*inreg%aU)
store i8*%aV,i8**%c,align 8
%aW=load i8*,i8**%e,align 8
%aX=getelementptr inbounds i8,i8*%aW,i64 4
%aY=bitcast i8*%aX to i32*
%aZ=load i32,i32*%aY,align 4
store i8*null,i8**%e,align 8
%a0=bitcast i8*%aW to i32*
%a1=load i32,i32*%a0,align 4
%a2=call i8*@sml_alloc(i32 inreg%G)#0
%a3=or i32%A,1342177280
%a4=getelementptr inbounds i8,i8*%a2,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32%a3,i32*%a5,align 4
store i8*%a2,i8**%e,align 8
call void@llvm.memset.p0i8.i32(i8*%a2,i8 0,i32%G,i1 false)
%a6=icmp eq i32%a1,0
%a7=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a8=sext i32%v to i64
%a9=getelementptr inbounds i8,i8*%a2,i64%a8
br i1%a6,label%bc,label%ba
ba:
%bb=bitcast i8*%a9 to i8**
store i8*%a7,i8**%bb,align 8
br label%bd
bc:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%a9,i8*%a7,i32%aZ,i1 false)
br label%bd
bd:
%be=getelementptr inbounds i8,i8*%a2,i64%aR
%bf=bitcast i8*%be to i8**
store i8*null,i8**%bf,align 8
%bg=sext i32%A to i64
%bh=getelementptr inbounds i8,i8*%a2,i64%bg
%bi=bitcast i8*%bh to i32*
store i32%F,i32*%bi,align 4
%bj=call i8*@sml_alloc(i32 inreg 20)#0
%bk=getelementptr inbounds i8,i8*%bj,i64 -4
%bl=bitcast i8*%bk to i32*
store i32 1342177296,i32*%bl,align 4
%bm=load i8*,i8**%e,align 8
%bn=bitcast i8*%bj to i8**
store i8*%bm,i8**%bn,align 8
%bo=load i8*,i8**%c,align 8
%bp=getelementptr inbounds i8,i8*%bj,i64 8
%bq=bitcast i8*%bp to i8**
store i8*%bo,i8**%bq,align 8
%br=getelementptr inbounds i8,i8*%bj,i64 16
%bs=bitcast i8*%br to i32*
store i32 3,i32*%bs,align 4
ret i8*%bj
}
define internal fastcc i8*@_SMLLN9ListUtils10prefixListE_52(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%s=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg%o,i32 inreg%r,i32 inreg 1,i32 inreg 8)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%e,align 8
%y=load i8*,i8**%d,align 8
%z=bitcast i8*%y to i32*
%A=load i32,i32*%z,align 4
%B=getelementptr inbounds i8,i8*%y,i64 4
%C=bitcast i8*%B to i32*
%D=load i32,i32*%C,align 4
%E=call i8*@sml_alloc(i32 inreg 12)#0
%F=bitcast i8*%E to i32*
%G=getelementptr inbounds i8,i8*%E,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177288,i32*%H,align 4
store i8*%E,i8**%f,align 8
store i32%A,i32*%F,align 4
%I=getelementptr inbounds i8,i8*%E,i64 4
%J=bitcast i8*%I to i32*
store i32%D,i32*%J,align 4
%K=getelementptr inbounds i8,i8*%E,i64 8
%L=bitcast i8*%K to i32*
store i32 0,i32*%L,align 4
%M=call i8*@sml_alloc(i32 inreg 28)#0
%N=getelementptr inbounds i8,i8*%M,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177304,i32*%O,align 4
%P=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%Q=bitcast i8*%M to i8**
store i8*%P,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%M,i64 8
%S=bitcast i8*%R to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_51 to void(...)*),void(...)**%S,align 8
%T=getelementptr inbounds i8,i8*%M,i64 16
%U=bitcast i8*%T to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_51 to void(...)*),void(...)**%U,align 8
%V=getelementptr inbounds i8,i8*%M,i64 24
%W=bitcast i8*%V to i32*
store i32 -2147483647,i32*%W,align 4
%X=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%Y=call fastcc i8*%v(i8*inreg%X,i8*inreg%M)
%Z=getelementptr inbounds i8,i8*%Y,i64 16
%aa=bitcast i8*%Z to i8*(i8*,i8*)**
%ab=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aa,align 8
%ac=bitcast i8*%Y to i8**
%ad=load i8*,i8**%ac,align 8
%ae=call fastcc i8*%ab(i8*inreg%ad,i8*inreg null)
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
%aq=call fastcc i8*@_SMLFN4List3revE(i32 inreg%am,i32 inreg%ap)
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8*(i8*,i8*)**
%at=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%as,align 8
%au=bitcast i8*%aq to i8**
%av=load i8*,i8**%au,align 8
%aw=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ax=call fastcc i8*%at(i8*inreg%av,i8*inreg%aw)
%ay=load i8*,i8**%e,align 8
%az=tail call fastcc i8*%ah(i8*inreg%ay,i8*inreg%ax)
ret i8*%az
}
define internal fastcc i32@_SMLL2eq_55(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
l:
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
store i8*%a,i8**%g,align 8
%i=bitcast i8**%g to i8***
br label%j
j:
%k=phi i8*[%bN,%bM],[%b,%l]
store i8*%k,i8**%c,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%q,label%o
o:
call void@sml_check(i32 inreg%m)
%p=load i8*,i8**%c,align 8
br label%q
q:
%r=phi i8*[%p,%o],[%k,%j]
%s=load i8*,i8**%g,align 8
%t=getelementptr inbounds i8,i8*%s,i64 12
%u=bitcast i8*%t to i32*
%v=load i32,i32*%u,align 4
%w=add i32%v,-1
%x=sub i32 0,%v
%y=and i32%w,%x
%z=add i32%y,%v
%A=add i32%z,7
%B=and i32%A,-8
%C=add i32%w,%z
%D=and i32%C,%x
%E=add i32%v,7
%F=add i32%E,%D
%G=and i32%F,-8
%H=lshr i32%D,3
%I=lshr i32%y,3
%J=sub nsw i32%H,%I
%K=getelementptr inbounds i8,i8*%s,i64 8
%L=bitcast i8*%K to i32*
%M=load i32,i32*%L,align 4
%N=shl i32%M,%J
%O=or i32%N,%M
%P=or i32%G,4
%Q=bitcast i8*%r to i8**
%R=load i8*,i8**%Q,align 8
%S=icmp eq i8*%R,null
br i1%S,label%T,label%ab
T:
%U=getelementptr inbounds i8,i8*%r,i64 8
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
%X=icmp eq i8*%W,null
%Y=zext i1%X to i32
br label%Z
Z:
%aa=phi i32[%Y,%T],[0,%bD],[0,%aq]
ret i32%aa
ab:
store i8*%R,i8**%e,align 8
%ac=icmp eq i32%M,0
br i1%ac,label%ai,label%ad
ad:
%ae=sext i32%y to i64
%af=getelementptr inbounds i8,i8*%R,i64%ae
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
br label%aq
ai:
%aj=call i8*@sml_alloc(i32 inreg%v)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32%v,i32*%al,align 4
%am=load i8*,i8**%e,align 8
%an=sext i32%y to i64
%ao=getelementptr inbounds i8,i8*%am,i64%an
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aj,i8*%ao,i32%v,i1 false)
%ap=load i8*,i8**%c,align 8
br label%aq
aq:
%ar=phi i8*[%ap,%ai],[%r,%ad]
%as=phi i8*[%am,%ai],[%R,%ad]
%at=phi i8*[%aj,%ai],[%ah,%ad]
store i8*%at,i8**%d,align 8
%au=sext i32%B to i64
%av=getelementptr inbounds i8,i8*%as,i64%au
%aw=bitcast i8*%av to i8**
%ax=load i8*,i8**%aw,align 8
store i8*%ax,i8**%e,align 8
%ay=getelementptr inbounds i8,i8*%ar,i64 8
%az=bitcast i8*%ay to i8**
%aA=load i8*,i8**%az,align 8
%aB=icmp eq i8*%aA,null
br i1%aB,label%Z,label%aC
aC:
store i8*%aA,i8**%f,align 8
%aD=load i8*,i8**%g,align 8
%aE=getelementptr inbounds i8,i8*%aD,i64 8
%aF=bitcast i8*%aE to i32*
%aG=load i32,i32*%aF,align 4
%aH=icmp eq i32%aG,0
br i1%aH,label%aO,label%aI
aI:
%aJ=bitcast i8*%aD to i8**
%aK=sext i32%y to i64
%aL=getelementptr inbounds i8,i8*%aA,i64%aK
%aM=bitcast i8*%aL to i8**
%aN=load i8*,i8**%aM,align 8
br label%a3
aO:
%aP=getelementptr inbounds i8,i8*%aD,i64 12
%aQ=bitcast i8*%aP to i32*
%aR=load i32,i32*%aQ,align 4
%aS=call i8*@sml_alloc(i32 inreg%aR)#0
%aT=getelementptr inbounds i8,i8*%aS,i64 -4
%aU=bitcast i8*%aT to i32*
store i32%aR,i32*%aU,align 4
%aV=load i8*,i8**%f,align 8
%aW=sext i32%y to i64
%aX=getelementptr inbounds i8,i8*%aV,i64%aW
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aS,i8*%aX,i32%aR,i1 false)
%aY=load i8**,i8***%i,align 8
%aZ=bitcast i8**%aY to i8*
%a0=getelementptr inbounds i8*,i8**%aY,i64 1
%a1=bitcast i8**%a0 to i32*
%a2=load i32,i32*%a1,align 4
br label%a3
a3:
%a4=phi i64[%aW,%aO],[%aK,%aI]
%a5=phi i32[%a2,%aO],[%aG,%aI]
%a6=phi i8*[%aZ,%aO],[%aD,%aI]
%a7=phi i8**[%aY,%aO],[%aJ,%aI]
%a8=phi i8*[%aV,%aO],[%aA,%aI]
%a9=phi i8*[%aS,%aO],[%aN,%aI]
store i8*%a9,i8**%c,align 8
%ba=getelementptr inbounds i8,i8*%a8,i64%au
%bb=bitcast i8*%ba to i8**
%bc=load i8*,i8**%bb,align 8
store i8*%bc,i8**%f,align 8
%bd=load i8*,i8**%a7,align 8
%be=getelementptr inbounds i8,i8*%bd,i64 16
%bf=bitcast i8*%be to i8*(i8*,i8*)**
%bg=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bf,align 8
%bh=bitcast i8*%bd to i8**
%bi=load i8*,i8**%bh,align 8
store i8*%bi,i8**%h,align 8
%bj=getelementptr inbounds i8,i8*%a6,i64 12
%bk=bitcast i8*%bj to i32*
%bl=load i32,i32*%bk,align 4
%bm=call i8*@sml_alloc(i32 inreg%P)#0
%bn=or i32%G,1342177280
%bo=getelementptr inbounds i8,i8*%bm,i64 -4
%bp=bitcast i8*%bo to i32*
store i32%bn,i32*%bp,align 4
call void@llvm.memset.p0i8.i32(i8*%bm,i8 0,i32%P,i1 false)
%bq=icmp eq i32%a5,0
%br=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bs=getelementptr inbounds i8,i8*%bm,i64%a4
br i1%bq,label%bz,label%bt
bt:
%bu=bitcast i8*%bs to i8**
store i8*%br,i8**%bu,align 8
%bv=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bw=sext i32%D to i64
%bx=getelementptr inbounds i8,i8*%bm,i64%bw
%by=bitcast i8*%bx to i8**
store i8*%bv,i8**%by,align 8
br label%bD
bz:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bs,i8*%br,i32%bl,i1 false)
%bA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bB=sext i32%D to i64
%bC=getelementptr inbounds i8,i8*%bm,i64%bB
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bC,i8*%bA,i32%bl,i1 false)
br label%bD
bD:
%bE=sext i32%G to i64
%bF=getelementptr inbounds i8,i8*%bm,i64%bE
%bG=bitcast i8*%bF to i32*
store i32%O,i32*%bG,align 4
%bH=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bI=call fastcc i8*%bg(i8*inreg%bH,i8*inreg%bm)
%bJ=bitcast i8*%bI to i32*
%bK=load i32,i32*%bJ,align 4
%bL=icmp eq i32%bK,0
br i1%bL,label%Z,label%bM
bM:
%bN=call i8*@sml_alloc(i32 inreg 20)#0
%bO=getelementptr inbounds i8,i8*%bN,i64 -4
%bP=bitcast i8*%bO to i32*
store i32 1342177296,i32*%bP,align 4
%bQ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bR=bitcast i8*%bN to i8**
store i8*%bQ,i8**%bR,align 8
%bS=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bT=getelementptr inbounds i8,i8*%bN,i64 8
%bU=bitcast i8*%bT to i8**
store i8*%bS,i8**%bU,align 8
%bV=getelementptr inbounds i8,i8*%bN,i64 16
%bW=bitcast i8*%bV to i32*
store i32 3,i32*%bW,align 4
br label%j
}
define internal fastcc i32@_SMLLN9ListUtils6listEqE_56(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%y,i8**%f,align 8
%z=getelementptr inbounds i8*,i8**%r,i64 1
%A=bitcast i8**%z to i32*
%B=load i32,i32*%A,align 4
store i8*null,i8**%e,align 8
%C=getelementptr inbounds i8,i8*%q,i64 12
%D=bitcast i8*%C to i32*
%E=load i32,i32*%D,align 4
%F=call i8*@sml_alloc(i32 inreg 20)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177296,i32*%H,align 4
store i8*%F,i8**%e,align 8
%I=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%F,i64 8
%L=bitcast i8*%K to i32*
store i32%B,i32*%L,align 4
%M=getelementptr inbounds i8,i8*%F,i64 12
%N=bitcast i8*%M to i32*
store i32%E,i32*%N,align 4
%O=getelementptr inbounds i8,i8*%F,i64 16
%P=bitcast i8*%O to i32*
store i32 1,i32*%P,align 4
%Q=call i8*@sml_alloc(i32 inreg 28)#0
%R=getelementptr inbounds i8,i8*%Q,i64 -4
%S=bitcast i8*%R to i32*
store i32 1342177304,i32*%S,align 4
%T=load i8*,i8**%e,align 8
%U=bitcast i8*%Q to i8**
store i8*%T,i8**%U,align 8
%V=getelementptr inbounds i8,i8*%Q,i64 8
%W=bitcast i8*%V to void(...)**
store void(...)*bitcast(i32(i8*,i8*)*@_SMLL2eq_55 to void(...)*),void(...)**%W,align 8
%X=getelementptr inbounds i8,i8*%Q,i64 16
%Y=bitcast i8*%X to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL2eq_73 to void(...)*),void(...)**%Y,align 8
%Z=getelementptr inbounds i8,i8*%Q,i64 24
%aa=bitcast i8*%Z to i32*
store i32 -2147483647,i32*%aa,align 4
%ab=call i8*@sml_alloc(i32 inreg 20)#0
%ac=getelementptr inbounds i8,i8*%ab,i64 -4
%ad=bitcast i8*%ac to i32*
store i32 1342177296,i32*%ad,align 4
%ae=load i8*,i8**%c,align 8
%af=bitcast i8*%ab to i8**
store i8*%ae,i8**%af,align 8
%ag=load i8*,i8**%d,align 8
%ah=getelementptr inbounds i8,i8*%ab,i64 8
%ai=bitcast i8*%ah to i8**
store i8*%ag,i8**%ai,align 8
%aj=getelementptr inbounds i8,i8*%ab,i64 16
%ak=bitcast i8*%aj to i32*
store i32 3,i32*%ak,align 4
%al=load i8*,i8**%e,align 8
%am=tail call fastcc i32@_SMLL2eq_55(i8*inreg%al,i8*inreg%ab)
ret i32%am
}
define internal fastcc i8*@_SMLLN9ListUtils6listEqE_57(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i32(i8*,i8*)*@_SMLLN9ListUtils6listEqE_56 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils6listEqE_74 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%u,i64 24
%E=bitcast i8*%D to i32*
store i32 -2147483647,i32*%E,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLN9ListUtils5splitE_60(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils5splitE_47 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils5splitE_47 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%r)
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=call fastcc i8*@_SMLLN9ListUtils5splitE_47(i8*inreg%D,i8*inreg%L)
ret i8*%M
}
define fastcc i8*@_SMLFN9ListUtils5splitE(i32 inreg%a,i32 inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils5splitE_60 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils5splitE_60 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLN9ListUtils10prefixListE_63(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_52 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_52 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%r)
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=call fastcc i8*@_SMLLN9ListUtils10prefixListE_52(i8*inreg%D,i8*inreg%L)
ret i8*%M
}
define fastcc i8*@_SMLFN9ListUtils10prefixListE(i32 inreg%a,i32 inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_63 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils10prefixListE_63 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLN9ListUtils6listEqE_66(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils6listEqE_57 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils6listEqE_57 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%r)
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=call fastcc i8*@_SMLLN9ListUtils6listEqE_57(i8*inreg%D,i8*inreg%L)
ret i8*%M
}
define fastcc i8*@_SMLFN9ListUtils6listEqE(i32 inreg%a,i32 inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils6listEqE_66 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN9ListUtils6listEqE_66 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLN9ListUtils5splitE_70(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLN9ListUtils5splitE_46(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLL2eq_73(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i32@_SMLL2eq_55(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLN9ListUtils6listEqE_74(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i32@_SMLLN9ListUtils6listEqE_56(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLN9ListUtils5splitE_76(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN9ListUtils5splitE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN9ListUtils10prefixListE_77(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN9ListUtils10prefixListE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN9ListUtils6listEqE_78(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN9ListUtils6listEqE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
