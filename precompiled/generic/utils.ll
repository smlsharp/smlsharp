@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306360,i8*null,i32 1}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN9ListUtils5splitE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN9ListUtils5splitE_58 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN9ListUtils10prefixListE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_59 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN9ListUtils6listEqE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN9ListUtils6listEqE_61 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9ListUtils5splitE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN9ListUtils10prefixListE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
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
define internal fastcc i8*@_SMLLLN9ListUtils5splitE_44(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
X:
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
%h=getelementptr inbounds i8,i8*%a,i64 12
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=add i32%j,-1
%l=sub i32 0,%j
%m=and i32%k,%l
%n=add i32%j,7
%o=add i32%n,%m
%p=and i32%o,-8
%q=add i32%p,15
%r=and i32%q,-8
%s=lshr i32%o,3
%t=lshr i32%m,3
%u=sub nsw i32%s,%t
%v=shl i32 1,%u
%w=getelementptr inbounds i8,i8*%a,i64 8
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=or i32%v,%y
%A=or i32%r,4
%B=bitcast i8*%a to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%c,align 8
%D=call i8*@sml_alloc(i32 inreg 28)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177304,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%D,i64 20
%H=bitcast i8*%G to i32*
store i32 0,i32*%H,align 1
%I=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%J=bitcast i8*%D to i8**
store i8*%I,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%D,i64 8
%L=bitcast i8*%K to i8**
store i8*null,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%D,i64 16
%N=bitcast i8*%M to i32*
store i32%b,i32*%N,align 4
%O=getelementptr inbounds i8,i8*%D,i64 24
%P=bitcast i8*%O to i32*
store i32 3,i32*%P,align 4
%Q=bitcast i8**%c to i8***
%R=sext i32%m to i64
%S=sext i32%p to i64
%T=or i32%r,1342177280
%U=sext i32%r to i64
br label%V
V:
%W=phi i8*[%bS,%bH],[%I,%X]
%Y=phi i8*[%bN,%bH],[%D,%X]
store i8*%Y,i8**%c,align 8
%Z=load atomic i32,i32*@sml_check_flag unordered,align 4
%aa=icmp eq i32%Z,0
br i1%aa,label%af,label%ab
ab:
call void@sml_check(i32 inreg%Z)
%ac=load i8**,i8***%Q,align 8
%ad=load i8*,i8**%ac,align 8
%ae=bitcast i8**%ac to i8*
br label%af
af:
%ag=phi i8*[%ae,%ab],[%Y,%V]
%ah=phi i8*[%ad,%ab],[%W,%V]
store i8*%ah,i8**%d,align 8
%ai=icmp eq i8*%ah,null
br i1%ai,label%aj,label%aR
aj:
%ak=getelementptr inbounds i8,i8*%ag,i64 8
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
store i8*%am,i8**%d,align 8
store i8*null,i8**%c,align 8
%an=getelementptr inbounds i8,i8*%ag,i64 16
%ao=bitcast i8*%an to i32*
%ap=load i32,i32*%ao,align 4
%aq=load i8*,i8**%g,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 8
%as=bitcast i8*%ar to i32*
%at=load i32,i32*%as,align 4
store i8*null,i8**%g,align 8
%au=getelementptr inbounds i8,i8*%aq,i64 12
%av=bitcast i8*%au to i32*
%aw=load i32,i32*%av,align 4
%ax=call fastcc i8*@_SMLFN4List3revE(i32 inreg%at,i32 inreg%aw)
%ay=getelementptr inbounds i8,i8*%ax,i64 16
%az=bitcast i8*%ay to i8*(i8*,i8*)**
%aA=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%az,align 8
%aB=bitcast i8*%ax to i8**
%aC=load i8*,i8**%aB,align 8
%aD=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aE=call fastcc i8*%aA(i8*inreg%aC,i8*inreg%aD)
store i8*%aE,i8**%c,align 8
%aF=icmp slt i32%ap,1
%aG=select i1%aF,i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i32}>,<{[4x i8],i32,i8*,i32}>*@a,i64 0,i32 2)to i8*),i8*null
store i8*%aG,i8**%d,align 8
%aH=call i8*@sml_alloc(i32 inreg 20)#0
%aI=getelementptr inbounds i8,i8*%aH,i64 -4
%aJ=bitcast i8*%aI to i32*
store i32 1342177296,i32*%aJ,align 4
%aK=load i8*,i8**%c,align 8
%aL=bitcast i8*%aH to i8**
store i8*%aK,i8**%aL,align 8
%aM=load i8*,i8**%d,align 8
%aN=getelementptr inbounds i8,i8*%aH,i64 8
%aO=bitcast i8*%aN to i8**
store i8*%aM,i8**%aO,align 8
%aP=getelementptr inbounds i8,i8*%aH,i64 16
%aQ=bitcast i8*%aP to i32*
store i32 3,i32*%aQ,align 4
ret i8*%aH
aR:
%aS=load i8*,i8**%g,align 8
%aT=getelementptr inbounds i8,i8*%aS,i64 8
%aU=bitcast i8*%aT to i32*
%aV=load i32,i32*%aU,align 4
%aW=icmp eq i32%aV,0
br i1%aW,label%a1,label%aX
aX:
%aY=getelementptr inbounds i8,i8*%ah,i64%R
%aZ=bitcast i8*%aY to i8**
%a0=load i8*,i8**%aZ,align 8
br label%bb
a1:
%a2=getelementptr inbounds i8,i8*%aS,i64 12
%a3=bitcast i8*%a2 to i32*
%a4=load i32,i32*%a3,align 4
%a5=call i8*@sml_alloc(i32 inreg%a4)#0
%a6=getelementptr inbounds i8,i8*%a5,i64 -4
%a7=bitcast i8*%a6 to i32*
store i32%a4,i32*%a7,align 4
%a8=load i8*,i8**%d,align 8
%a9=getelementptr inbounds i8,i8*%a8,i64%R
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%a5,i8*%a9,i32%a4,i1 false)
%ba=load i8*,i8**%c,align 8
br label%bb
bb:
%bc=phi i8*[%ba,%a1],[%ag,%aX]
%bd=phi i8*[%a8,%a1],[%ah,%aX]
%be=phi i8*[%a5,%a1],[%a0,%aX]
store i8*%be,i8**%e,align 8
%bf=getelementptr inbounds i8,i8*%bd,i64%S
%bg=bitcast i8*%bf to i8**
%bh=load i8*,i8**%bg,align 8
store i8*%bh,i8**%d,align 8
%bi=getelementptr inbounds i8,i8*%bc,i64 8
%bj=bitcast i8*%bi to i8**
%bk=load i8*,i8**%bj,align 8
store i8*%bk,i8**%f,align 8
store i8*null,i8**%c,align 8
%bl=getelementptr inbounds i8,i8*%bc,i64 16
%bm=bitcast i8*%bl to i32*
%bn=load i32,i32*%bm,align 4
%bo=icmp slt i32%bn,1
br i1%bo,label%b1,label%bp
bp:
%bq=add nsw i32%bn,-1
%br=load i8*,i8**%g,align 8
%bs=getelementptr inbounds i8,i8*%br,i64 12
%bt=bitcast i8*%bs to i32*
%bu=load i32,i32*%bt,align 4
%bv=getelementptr inbounds i8,i8*%br,i64 8
%bw=bitcast i8*%bv to i32*
%bx=load i32,i32*%bw,align 4
%by=call i8*@sml_alloc(i32 inreg%A)#0
%bz=getelementptr inbounds i8,i8*%by,i64 -4
%bA=bitcast i8*%bz to i32*
store i32%T,i32*%bA,align 4
store i8*%by,i8**%c,align 8
call void@llvm.memset.p0i8.i32(i8*%by,i8 0,i32%A,i1 false)
%bB=icmp eq i32%bx,0
%bC=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bD=getelementptr inbounds i8,i8*%by,i64%R
br i1%bB,label%bE,label%bF
bE:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bD,i8*%bC,i32%bu,i1 false)
br label%bH
bF:
%bG=bitcast i8*%bD to i8**
store i8*%bC,i8**%bG,align 8
br label%bH
bH:
%bI=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bJ=getelementptr inbounds i8,i8*%by,i64%S
%bK=bitcast i8*%bJ to i8**
store i8*%bI,i8**%bK,align 8
%bL=getelementptr inbounds i8,i8*%by,i64%U
%bM=bitcast i8*%bL to i32*
store i32%z,i32*%bM,align 4
%bN=call i8*@sml_alloc(i32 inreg 28)#0
%bO=getelementptr inbounds i8,i8*%bN,i64 -4
%bP=bitcast i8*%bO to i32*
store i32 1342177304,i32*%bP,align 4
%bQ=getelementptr inbounds i8,i8*%bN,i64 20
%bR=bitcast i8*%bQ to i32*
store i32 0,i32*%bR,align 1
%bS=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bT=bitcast i8*%bN to i8**
store i8*%bS,i8**%bT,align 8
%bU=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bV=getelementptr inbounds i8,i8*%bN,i64 8
%bW=bitcast i8*%bV to i8**
store i8*%bU,i8**%bW,align 8
%bX=getelementptr inbounds i8,i8*%bN,i64 16
%bY=bitcast i8*%bX to i32*
store i32%bq,i32*%bY,align 4
%bZ=getelementptr inbounds i8,i8*%bN,i64 24
%b0=bitcast i8*%bZ to i32*
store i32 3,i32*%b0,align 4
br label%V
b1:
%b2=load i8*,i8**%g,align 8
%b3=getelementptr inbounds i8,i8*%b2,i64 8
%b4=bitcast i8*%b3 to i32*
%b5=load i32,i32*%b4,align 4
%b6=getelementptr inbounds i8,i8*%b2,i64 12
%b7=bitcast i8*%b6 to i32*
%b8=load i32,i32*%b7,align 4
%b9=call fastcc i8*@_SMLFN4List3revE(i32 inreg%b5,i32 inreg%b8)
%ca=getelementptr inbounds i8,i8*%b9,i64 16
%cb=bitcast i8*%ca to i8*(i8*,i8*)**
%cc=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cb,align 8
%cd=bitcast i8*%b9 to i8**
%ce=load i8*,i8**%cd,align 8
%cf=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cg=call fastcc i8*%cc(i8*inreg%ce,i8*inreg%cf)
store i8*%cg,i8**%c,align 8
%ch=load i8*,i8**%g,align 8
%ci=getelementptr inbounds i8,i8*%ch,i64 12
%cj=bitcast i8*%ci to i32*
%ck=load i32,i32*%cj,align 4
store i8*null,i8**%g,align 8
%cl=getelementptr inbounds i8,i8*%ch,i64 8
%cm=bitcast i8*%cl to i32*
%cn=load i32,i32*%cm,align 4
%co=call i8*@sml_alloc(i32 inreg%A)#0
%cp=getelementptr inbounds i8,i8*%co,i64 -4
%cq=bitcast i8*%cp to i32*
store i32%T,i32*%cq,align 4
store i8*%co,i8**%f,align 8
call void@llvm.memset.p0i8.i32(i8*%co,i8 0,i32%A,i1 false)
%cr=icmp eq i32%cn,0
%cs=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ct=getelementptr inbounds i8,i8*%co,i64%R
br i1%cr,label%cu,label%cv
cu:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ct,i8*%cs,i32%ck,i1 false)
br label%cx
cv:
%cw=bitcast i8*%ct to i8**
store i8*%cs,i8**%cw,align 8
br label%cx
cx:
%cy=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cz=getelementptr inbounds i8,i8*%co,i64%S
%cA=bitcast i8*%cz to i8**
store i8*%cy,i8**%cA,align 8
%cB=getelementptr inbounds i8,i8*%co,i64%U
%cC=bitcast i8*%cB to i32*
store i32%z,i32*%cC,align 4
%cD=call i8*@sml_alloc(i32 inreg 12)#0
%cE=getelementptr inbounds i8,i8*%cD,i64 -4
%cF=bitcast i8*%cE to i32*
store i32 1342177288,i32*%cF,align 4
store i8*%cD,i8**%d,align 8
%cG=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cH=bitcast i8*%cD to i8**
store i8*%cG,i8**%cH,align 8
%cI=getelementptr inbounds i8,i8*%cD,i64 8
%cJ=bitcast i8*%cI to i32*
store i32 1,i32*%cJ,align 4
%cK=call i8*@sml_alloc(i32 inreg 20)#0
%cL=getelementptr inbounds i8,i8*%cK,i64 -4
%cM=bitcast i8*%cL to i32*
store i32 1342177296,i32*%cM,align 4
%cN=load i8*,i8**%c,align 8
%cO=bitcast i8*%cK to i8**
store i8*%cN,i8**%cO,align 8
%cP=load i8*,i8**%d,align 8
%cQ=getelementptr inbounds i8,i8*%cK,i64 8
%cR=bitcast i8*%cQ to i8**
store i8*%cP,i8**%cR,align 8
%cS=getelementptr inbounds i8,i8*%cK,i64 16
%cT=bitcast i8*%cS to i32*
store i32 3,i32*%cT,align 4
ret i8*%cK
}
define internal fastcc i8*@_SMLLLN9ListUtils5splitE_45(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLLN9ListUtils5splitE_44 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils5splitE_57 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%u,i64 24
%E=bitcast i8*%D to i32*
store i32 -2147483647,i32*%E,align 4
ret i8*%u
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils5splitE_45 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils5splitE_45 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLLN9ListUtils10prefixListE_48(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
br i1%W,label%aa,label%ab
aa:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%Z,i8*%X,i32%Q,i1 false)
br label%ad
ab:
%ac=bitcast i8*%Z to i8**
store i8*%X,i8**%ac,align 8
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
define internal fastcc i8*@_SMLLLN9ListUtils10prefixListE_49(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
%W=phi i8*[%S,%O],[%J,%I]
%X=phi i8*[%P,%O],[%N,%I]
store i8*%X,i8**%d,align 8
%Y=sext i32%y to i64
%Z=getelementptr inbounds i8,i8*%W,i64%Y
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
store i8*%ab,i8**%c,align 8
%ac=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%ad=getelementptr inbounds i8,i8*%ac,i64 16
%ae=bitcast i8*%ad to i8*(i8*,i8*)**
%af=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ae,align 8
%ag=bitcast i8*%ac to i8**
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%f,align 8
%ai=load i8*,i8**%e,align 8
%aj=getelementptr inbounds i8,i8*%ai,i64 4
%ak=bitcast i8*%aj to i32*
%al=load i32,i32*%ak,align 4
%am=bitcast i8*%ai to i32*
%an=load i32,i32*%am,align 4
%ao=call i8*@sml_alloc(i32 inreg 20)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177296,i32*%aq,align 4
store i8*%ao,i8**%g,align 8
%ar=icmp eq i32%an,0
%as=load i8*,i8**%d,align 8
br i1%ar,label%at,label%au
at:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ao,i8*%as,i32%al,i1 false)
br label%aw
au:
%av=bitcast i8*%ao to i8**
store i8*%as,i8**%av,align 8
br label%aw
aw:
%ax=getelementptr inbounds i8,i8*%ao,i64 8
%ay=bitcast i8*%ax to i32*
store i32%an,i32*%ay,align 4
%az=getelementptr inbounds i8,i8*%ao,i64 12
%aA=bitcast i8*%az to i32*
store i32%al,i32*%aA,align 4
%aB=getelementptr inbounds i8,i8*%ao,i64 16
%aC=bitcast i8*%aB to i32*
store i32%p,i32*%aC,align 4
%aD=call i8*@sml_alloc(i32 inreg 28)#0
%aE=getelementptr inbounds i8,i8*%aD,i64 -4
%aF=bitcast i8*%aE to i32*
store i32 1342177304,i32*%aF,align 4
%aG=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aH=bitcast i8*%aD to i8**
store i8*%aG,i8**%aH,align 8
%aI=getelementptr inbounds i8,i8*%aD,i64 8
%aJ=bitcast i8*%aI to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_48 to void(...)*),void(...)**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aD,i64 16
%aL=bitcast i8*%aK to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_48 to void(...)*),void(...)**%aL,align 8
%aM=getelementptr inbounds i8,i8*%aD,i64 24
%aN=bitcast i8*%aM to i32*
store i32 -2147483647,i32*%aN,align 4
%aO=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aP=call fastcc i8*%af(i8*inreg%aO,i8*inreg%aD)
%aQ=getelementptr inbounds i8,i8*%aP,i64 16
%aR=bitcast i8*%aQ to i8*(i8*,i8*)**
%aS=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aR,align 8
%aT=bitcast i8*%aP to i8**
%aU=load i8*,i8**%aT,align 8
%aV=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aW=call fastcc i8*%aS(i8*inreg%aU,i8*inreg%aV)
store i8*%aW,i8**%c,align 8
%aX=load i8*,i8**%e,align 8
%aY=getelementptr inbounds i8,i8*%aX,i64 4
%aZ=bitcast i8*%aY to i32*
%a0=load i32,i32*%aZ,align 4
store i8*null,i8**%e,align 8
%a1=bitcast i8*%aX to i32*
%a2=load i32,i32*%a1,align 4
%a3=call i8*@sml_alloc(i32 inreg%G)#0
%a4=or i32%A,1342177280
%a5=getelementptr inbounds i8,i8*%a3,i64 -4
%a6=bitcast i8*%a5 to i32*
store i32%a4,i32*%a6,align 4
store i8*%a3,i8**%e,align 8
call void@llvm.memset.p0i8.i32(i8*%a3,i8 0,i32%G,i1 false)
%a7=icmp eq i32%a2,0
%a8=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a9=sext i32%v to i64
%ba=getelementptr inbounds i8,i8*%a3,i64%a9
br i1%a7,label%bb,label%bc
bb:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%ba,i8*%a8,i32%a0,i1 false)
br label%be
bc:
%bd=bitcast i8*%ba to i8**
store i8*%a8,i8**%bd,align 8
br label%be
be:
%bf=getelementptr inbounds i8,i8*%a3,i64%Y
%bg=bitcast i8*%bf to i8**
store i8*null,i8**%bg,align 8
%bh=sext i32%A to i64
%bi=getelementptr inbounds i8,i8*%a3,i64%bh
%bj=bitcast i8*%bi to i32*
store i32%F,i32*%bj,align 4
%bk=call i8*@sml_alloc(i32 inreg 20)#0
%bl=getelementptr inbounds i8,i8*%bk,i64 -4
%bm=bitcast i8*%bl to i32*
store i32 1342177296,i32*%bm,align 4
%bn=load i8*,i8**%e,align 8
%bo=bitcast i8*%bk to i8**
store i8*%bn,i8**%bo,align 8
%bp=load i8*,i8**%c,align 8
%bq=getelementptr inbounds i8,i8*%bk,i64 8
%br=bitcast i8*%bq to i8**
store i8*%bp,i8**%br,align 8
%bs=getelementptr inbounds i8,i8*%bk,i64 16
%bt=bitcast i8*%bs to i32*
store i32 3,i32*%bt,align 4
ret i8*%bk
}
define internal fastcc i8*@_SMLLLN9ListUtils10prefixListE_50(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_49 to void(...)*),void(...)**%S,align 8
%T=getelementptr inbounds i8,i8*%M,i64 16
%U=bitcast i8*%T to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_49 to void(...)*),void(...)**%U,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_50 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils10prefixListE_50 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i32@_SMLLLN9ListUtils6listEqE_53(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
ad:
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
%i=getelementptr inbounds i8,i8*%a,i64 12
%j=bitcast i8*%i to i32*
%k=load i32,i32*%j,align 4
%l=add i32%k,-1
%m=sub i32 0,%k
%n=and i32%l,%m
%o=add i32%n,%k
%p=add i32%o,7
%q=and i32%p,-8
%r=add i32%l,%o
%s=and i32%r,%m
%t=add i32%k,7
%u=add i32%t,%s
%v=and i32%u,-8
%w=lshr i32%s,3
%x=lshr i32%n,3
%y=sub nsw i32%w,%x
%z=getelementptr inbounds i8,i8*%a,i64 8
%A=bitcast i8*%z to i32*
%B=load i32,i32*%A,align 4
%C=shl i32%B,%y
%D=or i32%C,%B
%E=or i32%v,4
%F=bitcast i8*%b to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%b,i64 8
%I=bitcast i8*%H to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%d,align 8
%K=call i8*@sml_alloc(i32 inreg 20)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177296,i32*%M,align 4
%N=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%O=bitcast i8*%K to i8**
store i8*%N,i8**%O,align 8
%P=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%Q=getelementptr inbounds i8,i8*%K,i64 8
%R=bitcast i8*%Q to i8**
store i8*%P,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%K,i64 16
%T=bitcast i8*%S to i32*
store i32 3,i32*%T,align 4
%U=bitcast i8**%c to i8***
%V=sext i32%n to i64
%W=sext i32%q to i64
%X=bitcast i8**%g to i8***
%Y=or i32%v,1342177280
%Z=sext i32%s to i64
%aa=sext i32%v to i64
br label%ab
ab:
%ac=phi i8*[%b9,%b5],[%N,%ad]
%ae=phi i8*[%b6,%b5],[%K,%ad]
store i8*%ae,i8**%c,align 8
%af=load atomic i32,i32*@sml_check_flag unordered,align 4
%ag=icmp eq i32%af,0
br i1%ag,label%al,label%ah
ah:
call void@sml_check(i32 inreg%af)
%ai=load i8**,i8***%U,align 8
%aj=load i8*,i8**%ai,align 8
%ak=bitcast i8**%ai to i8*
br label%al
al:
%am=phi i8*[%ak,%ah],[%ae,%ab]
%an=phi i8*[%aj,%ah],[%ac,%ab]
store i8*%an,i8**%d,align 8
%ao=icmp eq i8*%an,null
br i1%ao,label%ap,label%ax
ap:
%aq=getelementptr inbounds i8,i8*%am,i64 8
%ar=bitcast i8*%aq to i8**
%as=load i8*,i8**%ar,align 8
%at=icmp eq i8*%as,null
%au=zext i1%at to i32
br label%av
av:
%aw=phi i32[%au,%ap],[0,%bX],[0,%aR]
ret i32%aw
ax:
%ay=load i8*,i8**%g,align 8
%az=getelementptr inbounds i8,i8*%ay,i64 8
%aA=bitcast i8*%az to i32*
%aB=load i32,i32*%aA,align 4
%aC=icmp eq i32%aB,0
br i1%aC,label%aH,label%aD
aD:
%aE=getelementptr inbounds i8,i8*%an,i64%V
%aF=bitcast i8*%aE to i8**
%aG=load i8*,i8**%aF,align 8
br label%aR
aH:
%aI=getelementptr inbounds i8,i8*%ay,i64 12
%aJ=bitcast i8*%aI to i32*
%aK=load i32,i32*%aJ,align 4
%aL=call i8*@sml_alloc(i32 inreg%aK)#0
%aM=getelementptr inbounds i8,i8*%aL,i64 -4
%aN=bitcast i8*%aM to i32*
store i32%aK,i32*%aN,align 4
%aO=load i8*,i8**%d,align 8
%aP=getelementptr inbounds i8,i8*%aO,i64%V
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aL,i8*%aP,i32%aK,i1 false)
%aQ=load i8*,i8**%c,align 8
br label%aR
aR:
%aS=phi i8*[%aQ,%aH],[%am,%aD]
%aT=phi i8*[%aO,%aH],[%an,%aD]
%aU=phi i8*[%aL,%aH],[%aG,%aD]
store i8*%aU,i8**%e,align 8
%aV=getelementptr inbounds i8,i8*%aT,i64%W
%aW=bitcast i8*%aV to i8**
%aX=load i8*,i8**%aW,align 8
store i8*%aX,i8**%d,align 8
%aY=getelementptr inbounds i8,i8*%aS,i64 8
%aZ=bitcast i8*%aY to i8**
%a0=load i8*,i8**%aZ,align 8
store i8*%a0,i8**%c,align 8
%a1=icmp eq i8*%a0,null
br i1%a1,label%av,label%a2
a2:
%a3=load i8*,i8**%g,align 8
%a4=getelementptr inbounds i8,i8*%a3,i64 8
%a5=bitcast i8*%a4 to i32*
%a6=load i32,i32*%a5,align 4
%a7=icmp eq i32%a6,0
br i1%a7,label%bd,label%a8
a8:
%a9=bitcast i8*%a3 to i8**
%ba=getelementptr inbounds i8,i8*%a0,i64%V
%bb=bitcast i8*%ba to i8**
%bc=load i8*,i8**%bb,align 8
br label%br
bd:
%be=getelementptr inbounds i8,i8*%a3,i64 12
%bf=bitcast i8*%be to i32*
%bg=load i32,i32*%bf,align 4
%bh=call i8*@sml_alloc(i32 inreg%bg)#0
%bi=getelementptr inbounds i8,i8*%bh,i64 -4
%bj=bitcast i8*%bi to i32*
store i32%bg,i32*%bj,align 4
%bk=load i8*,i8**%c,align 8
%bl=getelementptr inbounds i8,i8*%bk,i64%V
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bh,i8*%bl,i32%bg,i1 false)
%bm=load i8**,i8***%X,align 8
%bn=bitcast i8**%bm to i8*
%bo=getelementptr inbounds i8*,i8**%bm,i64 1
%bp=bitcast i8**%bo to i32*
%bq=load i32,i32*%bp,align 4
br label%br
br:
%bs=phi i32[%bq,%bd],[%a6,%a8]
%bt=phi i8*[%bn,%bd],[%a3,%a8]
%bu=phi i8**[%bm,%bd],[%a9,%a8]
%bv=phi i8*[%bk,%bd],[%a0,%a8]
%bw=phi i8*[%bh,%bd],[%bc,%a8]
store i8*%bw,i8**%f,align 8
%bx=getelementptr inbounds i8,i8*%bv,i64%W
%by=bitcast i8*%bx to i8**
%bz=load i8*,i8**%by,align 8
store i8*%bz,i8**%c,align 8
%bA=load i8*,i8**%bu,align 8
%bB=getelementptr inbounds i8,i8*%bA,i64 16
%bC=bitcast i8*%bB to i8*(i8*,i8*)**
%bD=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bC,align 8
%bE=bitcast i8*%bA to i8**
%bF=load i8*,i8**%bE,align 8
store i8*%bF,i8**%h,align 8
%bG=getelementptr inbounds i8,i8*%bt,i64 12
%bH=bitcast i8*%bG to i32*
%bI=load i32,i32*%bH,align 4
%bJ=call i8*@sml_alloc(i32 inreg%E)#0
%bK=getelementptr inbounds i8,i8*%bJ,i64 -4
%bL=bitcast i8*%bK to i32*
store i32%Y,i32*%bL,align 4
call void@llvm.memset.p0i8.i32(i8*%bJ,i8 0,i32%E,i1 false)
%bM=icmp eq i32%bs,0
%bN=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bO=getelementptr inbounds i8,i8*%bJ,i64%V
br i1%bM,label%bP,label%bS
bP:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bO,i8*%bN,i32%bI,i1 false)
%bQ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bR=getelementptr inbounds i8,i8*%bJ,i64%Z
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bR,i8*%bQ,i32%bI,i1 false)
br label%bX
bS:
%bT=bitcast i8*%bO to i8**
store i8*%bN,i8**%bT,align 8
%bU=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bV=getelementptr inbounds i8,i8*%bJ,i64%Z
%bW=bitcast i8*%bV to i8**
store i8*%bU,i8**%bW,align 8
br label%bX
bX:
%bY=getelementptr inbounds i8,i8*%bJ,i64%aa
%bZ=bitcast i8*%bY to i32*
store i32%D,i32*%bZ,align 4
%b0=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b1=call fastcc i8*%bD(i8*inreg%b0,i8*inreg%bJ)
%b2=bitcast i8*%b1 to i32*
%b3=load i32,i32*%b2,align 4
%b4=icmp eq i32%b3,0
br i1%b4,label%av,label%b5
b5:
%b6=call i8*@sml_alloc(i32 inreg 20)#0
%b7=getelementptr inbounds i8,i8*%b6,i64 -4
%b8=bitcast i8*%b7 to i32*
store i32 1342177296,i32*%b8,align 4
%b9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ca=bitcast i8*%b6 to i8**
store i8*%b9,i8**%ca,align 8
%cb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cc=getelementptr inbounds i8,i8*%b6,i64 8
%cd=bitcast i8*%cc to i8**
store i8*%cb,i8**%cd,align 8
%ce=getelementptr inbounds i8,i8*%b6,i64 16
%cf=bitcast i8*%ce to i32*
store i32 3,i32*%cf,align 4
br label%ab
}
define internal fastcc i8*@_SMLLLN9ListUtils6listEqE_54(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i32(i8*,i8*)*@_SMLLLN9ListUtils6listEqE_53 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils6listEqE_60 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%u,i64 24
%E=bitcast i8*%D to i32*
store i32 -2147483647,i32*%E,align 4
ret i8*%u
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils6listEqE_54 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9ListUtils6listEqE_54 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLLN9ListUtils5splitE_57(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLLN9ListUtils5splitE_44(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN9ListUtils5splitE_58(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN9ListUtils5splitE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLLN9ListUtils10prefixListE_59(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN9ListUtils10prefixListE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLLN9ListUtils6listEqE_60(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i32@_SMLLLN9ListUtils6listEqE_53(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLLN9ListUtils6listEqE_61(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLFN9ListUtils6listEqE(i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
