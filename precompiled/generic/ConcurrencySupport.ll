@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[81x i8]}><{[4x i8]zeroinitializer,i32 -2147483567,[81x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:21.6(482)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:60.25(2188)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[16x i8]}><{[4x i8]zeroinitializer,i32 -2147483632,[16x i8]c"reachableToLoop\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[82x i8]}><{[4x i8]zeroinitializer,i32 -2147483566,[82x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:54.6(1934)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[82x i8]}><{[4x i8]zeroinitializer,i32 -2147483566,[82x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:75.6(2830)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:100.6(3610)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/extensions/concurrencysupport/main/ConcurrencySupport.sml:126.6(4456)\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLN18ConcurrencySupport13compileTopdecE_123 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN18ConcurrencySupport13compileTopdecE_135 to void(...)*),i32 -2147483647}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN18ConcurrencySupport13insertCheckGCE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN18ConcurrencySupport13insertCheckGCE_137 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN18ConcurrencySupport13insertCheckGCE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@i,i64 0,i32 2)to i8*)
@_SML_ftaba0689ce3f71c9ef3_ConcurrencySupport=external global i8
@j=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN13FunLocalLabel3Map4findE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map6insertE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainc261d7f8774fa92d_CodeLabel()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_loadc261d7f8774fa92d_CodeLabel(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
define private void@_SML_tabba0689ce3f71c9ef3_ConcurrencySupport()#3{
unreachable
}
define void@_SML_loada0689ce3f71c9ef3_ConcurrencySupport(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@j,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@j,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_loadc261d7f8774fa92d_CodeLabel(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabba0689ce3f71c9ef3_ConcurrencySupport,i8*@_SML_ftaba0689ce3f71c9ef3_ConcurrencySupport,i8*null)#0
ret void
}
define void@_SML_maina0689ce3f71c9ef3_ConcurrencySupport()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@j,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@j,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_mainc261d7f8774fa92d_CodeLabel()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
br label%d
}
define internal fastcc i8*@_SMLLN18ConcurrencySupport17insertCheckAtLoopE_98(i8*inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"{
t:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%r,label%o
o:
call void@sml_check(i32 inreg%m)
%p=load i8*,i8**%d,align 8
%q=load i8*,i8**%c,align 8
br label%r
r:
%s=phi i8*[%q,%o],[%a,%t]
%u=phi i8*[%p,%o],[%b,%t]
store i8*%s,i8**%d,align 8
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%e,align 8
%x=getelementptr inbounds i8,i8*%u,i64 8
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
%A=icmp eq i8*%z,null
br i1%A,label%W,label%B
B:
%C=bitcast i8*%z to i32*
%D=load i32,i32*%C,align 4
switch i32%D,label%E[
i32 4,label%W
i32 3,label%W
i32 1,label%b5
i32 5,label%W
i32 2,label%X
i32 0,label%W
i32 6,label%W
]
E:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
call void@sml_matchcomp_bug()
%F=load i8*,i8**@_SMLZ5Match,align 8
store i8*%F,i8**%c,align 8
%G=call i8*@sml_alloc(i32 inreg 20)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177296,i32*%I,align 4
store i8*%G,i8**%d,align 8
%J=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[81x i8]}>,<{[4x i8],i32,[81x i8]}>*@a,i64 0,i32 2,i64 0),i8**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to i32*
store i32 3,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 60)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177336,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%P,i64 56
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=load i8*,i8**%d,align 8
%V=bitcast i8*%P to i8**
store i8*%U,i8**%V,align 8
call void@sml_raise(i8*inreg%P)#1
unreachable
W:
ret i8*%u
X:
%Y=getelementptr inbounds i8,i8*%z,i64 8
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
store i8*%aa,i8**%f,align 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
store i8*%ac,i8**%g,align 8
%ad=getelementptr inbounds i8,i8*%aa,i64 16
%ae=bitcast i8*%ad to i8**
%af=load i8*,i8**%ae,align 8
store i8*%af,i8**%h,align 8
%ag=getelementptr inbounds i8,i8*%aa,i64 24
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
store i8*%ai,i8**%i,align 8
%aj=getelementptr inbounds i8,i8*%aa,i64 40
%ak=bitcast i8*%aj to i32*
%al=load i32,i32*%ak,align 4
%am=getelementptr inbounds i8,i8*%aa,i64 8
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
%ap=call fastcc i8*@_SMLLN18ConcurrencySupport17insertCheckAtLoopE_98(i8*inreg%s,i8*inreg%ao)
%aq=bitcast i8*%ap to i8**
%ar=load i8*,i8**%aq,align 8
store i8*%ar,i8**%c,align 8
%as=getelementptr inbounds i8,i8*%ap,i64 8
%at=bitcast i8*%as to i8**
%au=load i8*,i8**%at,align 8
store i8*%au,i8**%j,align 8
%av=icmp eq i32%al,0
br i1%av,label%a4,label%aw
aw:
%ax=call i8*@sml_alloc(i32 inreg 12)#0
%ay=getelementptr inbounds i8,i8*%ax,i64 -4
%az=bitcast i8*%ay to i32*
store i32 1342177288,i32*%az,align 4
store i8*%ax,i8**%k,align 8
%aA=load i8*,i8**%d,align 8
%aB=bitcast i8*%ax to i8**
store i8*%aA,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%ax,i64 8
%aD=bitcast i8*%aC to i32*
store i32 1,i32*%aD,align 4
%aE=call i8*@sml_alloc(i32 inreg 20)#0
%aF=getelementptr inbounds i8,i8*%aE,i64 -4
%aG=bitcast i8*%aF to i32*
store i32 1342177296,i32*%aG,align 4
store i8*%aE,i8**%l,align 8
%aH=getelementptr inbounds i8,i8*%aE,i64 4
%aI=bitcast i8*%aH to i32*
store i32 0,i32*%aI,align 1
%aJ=bitcast i8*%aE to i32*
store i32 5,i32*%aJ,align 4
%aK=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%aL=getelementptr inbounds i8,i8*%aE,i64 8
%aM=bitcast i8*%aL to i8**
store i8*%aK,i8**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aE,i64 16
%aO=bitcast i8*%aN to i32*
store i32 2,i32*%aO,align 4
%aP=call i8*@sml_alloc(i32 inreg 20)#0
%aQ=getelementptr inbounds i8,i8*%aP,i64 -4
%aR=bitcast i8*%aQ to i32*
store i32 1342177296,i32*%aR,align 4
store i8*%aP,i8**%k,align 8
%aS=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%aT=bitcast i8*%aP to i8**
store i8*%aS,i8**%aT,align 8
%aU=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aV=getelementptr inbounds i8,i8*%aP,i64 8
%aW=bitcast i8*%aV to i8**
store i8*%aU,i8**%aW,align 8
%aX=getelementptr inbounds i8,i8*%aP,i64 16
%aY=bitcast i8*%aX to i32*
store i32 3,i32*%aY,align 4
%aZ=call i8*@sml_alloc(i32 inreg 20)#0
%a0=getelementptr inbounds i8,i8*%aZ,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 1342177296,i32*%a1,align 4
%a2=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%a3=bitcast i8*%aZ to i8**
store i8*%a2,i8**%a3,align 8
br label%ba
a4:
%a5=call i8*@sml_alloc(i32 inreg 20)#0
%a6=getelementptr inbounds i8,i8*%a5,i64 -4
%a7=bitcast i8*%a6 to i32*
store i32 1342177296,i32*%a7,align 4
%a8=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a9=bitcast i8*%a5 to i8**
store i8*%a8,i8**%a9,align 8
br label%ba
ba:
%bb=phi i8*[%a5,%a4],[%aZ,%aw]
%bc=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bd=getelementptr inbounds i8,i8*%bb,i64 8
%be=bitcast i8*%bd to i8**
store i8*%bc,i8**%be,align 8
%bf=getelementptr inbounds i8,i8*%bb,i64 16
%bg=bitcast i8*%bf to i32*
store i32 3,i32*%bg,align 4
store i8*%bb,i8**%c,align 8
%bh=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bi=getelementptr inbounds i8,i8*%bh,i64 32
%bj=bitcast i8*%bi to i8**
%bk=load i8*,i8**%bj,align 8
%bl=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bm=call fastcc i8*@_SMLLN18ConcurrencySupport17insertCheckAtLoopE_98(i8*inreg%bl,i8*inreg%bk)
store i8*%bm,i8**%d,align 8
%bn=call i8*@sml_alloc(i32 inreg 52)#0
%bo=getelementptr inbounds i8,i8*%bn,i64 -4
%bp=bitcast i8*%bo to i32*
store i32 1342177328,i32*%bp,align 4
store i8*%bn,i8**%f,align 8
%bq=getelementptr inbounds i8,i8*%bn,i64 44
%br=bitcast i8*%bq to i32*
store i32 0,i32*%br,align 1
%bs=load i8*,i8**%g,align 8
%bt=bitcast i8*%bn to i8**
store i8*null,i8**%g,align 8
store i8*%bs,i8**%bt,align 8
%bu=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bv=getelementptr inbounds i8,i8*%bn,i64 8
%bw=bitcast i8*%bv to i8**
store i8*%bu,i8**%bw,align 8
%bx=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%by=getelementptr inbounds i8,i8*%bn,i64 16
%bz=bitcast i8*%by to i8**
store i8*%bx,i8**%bz,align 8
%bA=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bB=getelementptr inbounds i8,i8*%bn,i64 24
%bC=bitcast i8*%bB to i8**
store i8*%bA,i8**%bC,align 8
%bD=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bE=getelementptr inbounds i8,i8*%bn,i64 32
%bF=bitcast i8*%bE to i8**
store i8*%bD,i8**%bF,align 8
%bG=getelementptr inbounds i8,i8*%bn,i64 40
%bH=bitcast i8*%bG to i32*
store i32%al,i32*%bH,align 4
%bI=getelementptr inbounds i8,i8*%bn,i64 48
%bJ=bitcast i8*%bI to i32*
store i32 31,i32*%bJ,align 4
%bK=call i8*@sml_alloc(i32 inreg 20)#0
%bL=getelementptr inbounds i8,i8*%bK,i64 -4
%bM=bitcast i8*%bL to i32*
store i32 1342177296,i32*%bM,align 4
store i8*%bK,i8**%c,align 8
%bN=getelementptr inbounds i8,i8*%bK,i64 4
%bO=bitcast i8*%bN to i32*
store i32 0,i32*%bO,align 1
%bP=bitcast i8*%bK to i32*
store i32 2,i32*%bP,align 4
%bQ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bR=getelementptr inbounds i8,i8*%bK,i64 8
%bS=bitcast i8*%bR to i8**
store i8*%bQ,i8**%bS,align 8
%bT=getelementptr inbounds i8,i8*%bK,i64 16
%bU=bitcast i8*%bT to i32*
store i32 2,i32*%bU,align 4
%bV=call i8*@sml_alloc(i32 inreg 20)#0
%bW=getelementptr inbounds i8,i8*%bV,i64 -4
%bX=bitcast i8*%bW to i32*
store i32 1342177296,i32*%bX,align 4
%bY=load i8*,i8**%e,align 8
%bZ=bitcast i8*%bV to i8**
store i8*%bY,i8**%bZ,align 8
%b0=load i8*,i8**%c,align 8
%b1=getelementptr inbounds i8,i8*%bV,i64 8
%b2=bitcast i8*%b1 to i8**
store i8*%b0,i8**%b2,align 8
%b3=getelementptr inbounds i8,i8*%bV,i64 16
%b4=bitcast i8*%b3 to i32*
store i32 3,i32*%b4,align 4
ret i8*%bV
b5:
%b6=getelementptr inbounds i8,i8*%z,i64 8
%b7=bitcast i8*%b6 to i8**
%b8=load i8*,i8**%b7,align 8
store i8*%b8,i8**%f,align 8
%b9=bitcast i8*%b8 to i8**
%ca=load i8*,i8**%b9,align 8
store i8*%ca,i8**%g,align 8
%cb=getelementptr inbounds i8,i8*%b8,i64 8
%cc=bitcast i8*%cb to i8**
%cd=load i8*,i8**%cc,align 8
store i8*%cd,i8**%h,align 8
%ce=getelementptr inbounds i8,i8*%b8,i64 24
%cf=bitcast i8*%ce to i8**
%cg=load i8*,i8**%cf,align 8
store i8*%cg,i8**%i,align 8
%ch=getelementptr inbounds i8,i8*%b8,i64 32
%ci=bitcast i8*%ch to i8**
%cj=load i8*,i8**%ci,align 8
store i8*%cj,i8**%j,align 8
%ck=getelementptr inbounds i8,i8*%b8,i64 40
%cl=bitcast i8*%ck to i8**
%cm=load i8*,i8**%cl,align 8
%cn=call fastcc i8*@_SMLLN18ConcurrencySupport17insertCheckAtLoopE_98(i8*inreg%s,i8*inreg%cm)
store i8*%cn,i8**%c,align 8
%co=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cp=getelementptr inbounds i8,i8*%co,i64 16
%cq=bitcast i8*%cp to i8**
%cr=load i8*,i8**%cq,align 8
%cs=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ct=call fastcc i8*@_SMLLN18ConcurrencySupport17insertCheckAtLoopE_98(i8*inreg%cs,i8*inreg%cr)
store i8*%ct,i8**%d,align 8
%cu=call i8*@sml_alloc(i32 inreg 52)#0
%cv=getelementptr inbounds i8,i8*%cu,i64 -4
%cw=bitcast i8*%cv to i32*
store i32 1342177328,i32*%cw,align 4
store i8*%cu,i8**%f,align 8
%cx=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cy=bitcast i8*%cu to i8**
store i8*%cx,i8**%cy,align 8
%cz=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cA=getelementptr inbounds i8,i8*%cu,i64 8
%cB=bitcast i8*%cA to i8**
store i8*%cz,i8**%cB,align 8
%cC=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cD=getelementptr inbounds i8,i8*%cu,i64 16
%cE=bitcast i8*%cD to i8**
store i8*%cC,i8**%cE,align 8
%cF=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cG=getelementptr inbounds i8,i8*%cu,i64 24
%cH=bitcast i8*%cG to i8**
store i8*%cF,i8**%cH,align 8
%cI=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cJ=getelementptr inbounds i8,i8*%cu,i64 32
%cK=bitcast i8*%cJ to i8**
store i8*%cI,i8**%cK,align 8
%cL=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cM=getelementptr inbounds i8,i8*%cu,i64 40
%cN=bitcast i8*%cM to i8**
store i8*%cL,i8**%cN,align 8
%cO=getelementptr inbounds i8,i8*%cu,i64 48
%cP=bitcast i8*%cO to i32*
store i32 63,i32*%cP,align 4
%cQ=call i8*@sml_alloc(i32 inreg 20)#0
%cR=getelementptr inbounds i8,i8*%cQ,i64 -4
%cS=bitcast i8*%cR to i32*
store i32 1342177296,i32*%cS,align 4
store i8*%cQ,i8**%c,align 8
%cT=getelementptr inbounds i8,i8*%cQ,i64 4
%cU=bitcast i8*%cT to i32*
store i32 0,i32*%cU,align 1
%cV=bitcast i8*%cQ to i32*
store i32 1,i32*%cV,align 4
%cW=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cX=getelementptr inbounds i8,i8*%cQ,i64 8
%cY=bitcast i8*%cX to i8**
store i8*%cW,i8**%cY,align 8
%cZ=getelementptr inbounds i8,i8*%cQ,i64 16
%c0=bitcast i8*%cZ to i32*
store i32 2,i32*%c0,align 4
%c1=call i8*@sml_alloc(i32 inreg 20)#0
%c2=getelementptr inbounds i8,i8*%c1,i64 -4
%c3=bitcast i8*%c2 to i32*
store i32 1342177296,i32*%c3,align 4
%c4=load i8*,i8**%e,align 8
%c5=bitcast i8*%c1 to i8**
store i8*%c4,i8**%c5,align 8
%c6=load i8*,i8**%c,align 8
%c7=getelementptr inbounds i8,i8*%c1,i64 8
%c8=bitcast i8*%c7 to i8**
store i8*%c6,i8**%c8,align 8
%c9=getelementptr inbounds i8,i8*%c1,i64 16
%da=bitcast i8*%c9 to i32*
store i32 3,i32*%da,align 4
ret i8*%c1
}
define internal fastcc i32@_SMLLN18ConcurrencySupport7hasCallE_114(i8*inreg%a)unnamed_addr#2 gc"smlsharp"{
l:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
%h=bitcast i8**%d to i8*
%i=bitcast i8**%e to i8*
br label%j
j:
%k=phi i8*[%bo,%bn],[%a,%l]
store i8*%k,i8**%f,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%q,label%o
o:
call void@sml_check(i32 inreg%m)
%p=load i8*,i8**%f,align 8
br label%q
q:
%r=phi i8*[%p,%o],[%k,%j]
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=icmp eq i8*%t,null
br i1%u,label%v,label%aL
v:
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
%z=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%z)
%A=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%A)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%y,i8**%b,align 8
%B=load atomic i32,i32*@sml_check_flag unordered,align 4
%C=icmp eq i32%B,0
br i1%C,label%F,label%D
D:
call void@sml_check(i32 inreg%B)
%E=load i8*,i8**%b,align 8
br label%F
F:
%G=phi i8*[%E,%D],[%y,%v]
%H=icmp eq i8*%G,null
br i1%H,label%ad,label%I
I:
%J=bitcast i8*%G to i32*
%K=load i32,i32*%J,align 4
switch i32%K,label%L[
i32 4,label%ad
i32 3,label%ad
i32 1,label%au
i32 5,label%ad
i32 2,label%af
i32 0,label%ad
i32 6,label%ad
]
L:
call void@sml_matchcomp_bug()
%M=load i8*,i8**@_SMLZ5Match,align 8
store i8*%M,i8**%b,align 8
%N=call i8*@sml_alloc(i32 inreg 20)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177296,i32*%P,align 4
store i8*%N,i8**%c,align 8
%Q=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%N,i64 8
%T=bitcast i8*%S to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@f,i64 0,i32 2,i64 0),i8**%T,align 8
%U=getelementptr inbounds i8,i8*%N,i64 16
%V=bitcast i8*%U to i32*
store i32 3,i32*%V,align 4
%W=call i8*@sml_alloc(i32 inreg 60)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177336,i32*%Y,align 4
%Z=getelementptr inbounds i8,i8*%W,i64 56
%aa=bitcast i8*%Z to i32*
store i32 1,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
%ac=bitcast i8*%W to i8**
store i8*%ab,i8**%ac,align 8
call void@sml_raise(i8*inreg%W)#1
unreachable
ad:
%ae=phi i32[0,%I],[1,%af],[1,%au],[0,%I],[0,%I],[0,%I],[0,%I],[0,%F]
call void@llvm.lifetime.end.p0i8(i64 8,i8*%z)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%A)
br label%aJ
af:
%ag=getelementptr inbounds i8,i8*%G,i64 8
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
store i8*%ai,i8**%b,align 8
%aj=getelementptr inbounds i8,i8*%ai,i64 32
%ak=bitcast i8*%aj to i8**
%al=load i8*,i8**%ak,align 8
%am=call fastcc i32@_SMLLN18ConcurrencySupport7hasCallE_114(i8*inreg%al)
%an=icmp eq i32%am,0
br i1%an,label%ao,label%ad
ao:
%ap=load i8*,i8**%b,align 8
%aq=getelementptr inbounds i8,i8*%ap,i64 8
%ar=bitcast i8*%aq to i8**
%as=load i8*,i8**%ar,align 8
%at=tail call fastcc i32@_SMLLN18ConcurrencySupport7hasCallE_114(i8*inreg%as)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%z)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%A)
br label%aJ
au:
%av=getelementptr inbounds i8,i8*%G,i64 8
%aw=bitcast i8*%av to i8**
%ax=load i8*,i8**%aw,align 8
store i8*%ax,i8**%b,align 8
%ay=getelementptr inbounds i8,i8*%ax,i64 40
%az=bitcast i8*%ay to i8**
%aA=load i8*,i8**%az,align 8
%aB=call fastcc i32@_SMLLN18ConcurrencySupport7hasCallE_114(i8*inreg%aA)
%aC=icmp eq i32%aB,0
br i1%aC,label%aD,label%ad
aD:
%aE=load i8*,i8**%b,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 16
%aG=bitcast i8*%aF to i8**
%aH=load i8*,i8**%aG,align 8
%aI=tail call fastcc i32@_SMLLN18ConcurrencySupport7hasCallE_114(i8*inreg%aH)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%z)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%A)
br label%aJ
aJ:
%aK=phi i32[%ae,%ad],[%at,%ao],[%aI,%aD]
ret i32%aK
aL:
%aM=getelementptr inbounds i8,i8*%t,i64 8
%aN=bitcast i8*%aM to i8**
%aO=load i8*,i8**%aN,align 8
store i8*%aO,i8**%f,align 8
%aP=getelementptr inbounds i8,i8*%r,i64 8
%aQ=bitcast i8*%aP to i8**
%aR=load i8*,i8**%aQ,align 8
store i8*%aR,i8**%g,align 8
%aS=bitcast i8*%t to i8**
%aT=load i8*,i8**%aS,align 8
call void@llvm.lifetime.start.p0i8(i64 8,i8*%h)
call void@llvm.lifetime.start.p0i8(i64 8,i8*%i)
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%aT,i8**%d,align 8
%aU=load atomic i32,i32*@sml_check_flag unordered,align 4
%aV=icmp eq i32%aU,0
br i1%aV,label%aY,label%aW
aW:
call void@sml_check(i32 inreg%aU)
%aX=load i8*,i8**%d,align 8
br label%aY
aY:
%aZ=phi i8*[%aX,%aW],[%aT,%aL]
%a0=icmp eq i8*%aZ,null
br i1%a0,label%bn,label%a1
a1:
%a2=bitcast i8*%aZ to i32*
%a3=load i32,i32*%a2,align 4
switch i32%a3,label%a4[
i32 10,label%bn
i32 9,label%bm
i32 6,label%bn
i32 8,label%bn
i32 14,label%bn
i32 16,label%bn
i32 15,label%bn
i32 0,label%bn
i32 1,label%bn
i32 5,label%bn
i32 18,label%bn
i32 19,label%bn
i32 3,label%bn
i32 20,label%bn
i32 13,label%bn
i32 12,label%bn
i32 17,label%bn
i32 2,label%bn
i32 4,label%bm
i32 21,label%bn
i32 7,label%bn
i32 11,label%bn
]
a4:
call void@sml_matchcomp_bug()
%a5=load i8*,i8**@_SMLZ5Match,align 8
store i8*%a5,i8**%d,align 8
%a6=call i8*@sml_alloc(i32 inreg 20)#0
%a7=getelementptr inbounds i8,i8*%a6,i64 -4
%a8=bitcast i8*%a7 to i32*
store i32 1342177296,i32*%a8,align 4
store i8*%a6,i8**%e,align 8
%a9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ba=bitcast i8*%a6 to i8**
store i8*%a9,i8**%ba,align 8
%bb=getelementptr inbounds i8,i8*%a6,i64 8
%bc=bitcast i8*%bb to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[82x i8]}>,<{[4x i8],i32,[82x i8]}>*@e,i64 0,i32 2,i64 0),i8**%bc,align 8
%bd=getelementptr inbounds i8,i8*%a6,i64 16
%be=bitcast i8*%bd to i32*
store i32 3,i32*%be,align 4
%bf=call i8*@sml_alloc(i32 inreg 60)#0
%bg=getelementptr inbounds i8,i8*%bf,i64 -4
%bh=bitcast i8*%bg to i32*
store i32 1342177336,i32*%bh,align 4
%bi=getelementptr inbounds i8,i8*%bf,i64 56
%bj=bitcast i8*%bi to i32*
store i32 1,i32*%bj,align 4
%bk=load i8*,i8**%e,align 8
%bl=bitcast i8*%bf to i8**
store i8*%bk,i8**%bl,align 8
call void@sml_raise(i8*inreg%bf)#1
unreachable
bm:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%h)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%i)
ret i32 1
bn:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%h)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%i)
%bo=call i8*@sml_alloc(i32 inreg 20)#0
%bp=getelementptr inbounds i8,i8*%bo,i64 -4
%bq=bitcast i8*%bp to i32*
store i32 1342177296,i32*%bq,align 4
%br=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bs=bitcast i8*%bo to i8**
store i8*%br,i8**%bs,align 8
%bt=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bu=getelementptr inbounds i8,i8*%bo,i64 8
%bv=bitcast i8*%bu to i8**
store i8*%bt,i8**%bv,align 8
%bw=getelementptr inbounds i8,i8*%bo,i64 16
%bx=bitcast i8*%bw to i32*
store i32 3,i32*%bx,align 4
br label%j
}
define internal fastcc i8*@_SMLLN18ConcurrencySupport11compileBodyE_119(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
store i8*%a,i8**%l,align 8
store i8*%b,i8**%i,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%o,label%r
o:
%p=bitcast i8*%a to i8**
%q=bitcast i8**%l to i8***
br label%v
r:
call void@sml_check(i32 inreg%m)
%s=load i8*,i8**%i,align 8
%t=bitcast i8**%l to i8***
%u=load i8**,i8***%t,align 8
br label%v
v:
%w=phi i8***[%q,%o],[%t,%r]
%x=phi i8**[%p,%o],[%u,%r]
%y=phi i8*[%b,%o],[%s,%r]
store i8*null,i8**%i,align 8
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
store i8*%A,i8**%j,align 8
%B=getelementptr inbounds i8,i8*%y,i64 8
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
store i8*%D,i8**%k,align 8
%E=load i8*,i8**%x,align 8
%F=call fastcc i8*@_SMLLN18ConcurrencySupport17insertCheckAtLoopE_98(i8*inreg%E,i8*inreg%y)
store i8*%F,i8**%i,align 8
%G=call fastcc i8*@_SMLFN13FunLocalLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
%H=load i8*,i8**%i,align 8
%I=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%I)
%J=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%J)
%K=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%K)
%L=bitcast i8**%f to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%L)
%M=bitcast i8**%g to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%M)
%N=bitcast i8**%h to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%N)
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
store i8*%G,i8**%h,align 8
store i8*%H,i8**%c,align 8
br label%O
O:
%P=phi i8*[%H,%v],[%cq,%cp]
%Q=load atomic i32,i32*@sml_check_flag unordered,align 4
%R=icmp eq i32%Q,0
br i1%R,label%U,label%S
S:
call void@sml_check(i32 inreg%Q)
%T=load i8*,i8**%c,align 8
br label%U
U:
%V=phi i8*[%T,%S],[%P,%O]
%W=getelementptr inbounds i8,i8*%V,i64 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
%Z=icmp eq i8*%Y,null
br i1%Z,label%cr,label%aa
aa:
%ab=bitcast i8*%Y to i32*
%ac=load i32,i32*%ab,align 4
switch i32%ac,label%ad[
i32 4,label%cr
i32 3,label%cr
i32 1,label%ci
i32 5,label%cr
i32 2,label%bs
i32 0,label%av
i32 6,label%cr
]
ad:
store i8*null,i8**%h,align 8
call void@sml_matchcomp_bug()
%ae=load i8*,i8**@_SMLZ5Match,align 8
store i8*%ae,i8**%c,align 8
%af=call i8*@sml_alloc(i32 inreg 20)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32 1342177296,i32*%ah,align 4
store i8*%af,i8**%d,align 8
%ai=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aj=bitcast i8*%af to i8**
store i8*%ai,i8**%aj,align 8
%ak=getelementptr inbounds i8,i8*%af,i64 8
%al=bitcast i8*%ak to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[82x i8]}>,<{[4x i8],i32,[82x i8]}>*@d,i64 0,i32 2,i64 0),i8**%al,align 8
%am=getelementptr inbounds i8,i8*%af,i64 16
%an=bitcast i8*%am to i32*
store i32 3,i32*%an,align 4
%ao=call i8*@sml_alloc(i32 inreg 60)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177336,i32*%aq,align 4
%ar=getelementptr inbounds i8,i8*%ao,i64 56
%as=bitcast i8*%ar to i32*
store i32 1,i32*%as,align 4
%at=load i8*,i8**%d,align 8
%au=bitcast i8*%ao to i8**
store i8*%at,i8**%au,align 8
call void@sml_raise(i8*inreg%ao)#1
unreachable
av:
%aw=getelementptr inbounds i8,i8*%Y,i64 8
%ax=bitcast i8*%aw to i8**
%ay=load i8*,i8**%ax,align 8
%az=getelementptr inbounds i8,i8*%ay,i64 8
%aA=bitcast i8*%az to i8**
%aB=load i8*,i8**%aA,align 8
store i8*%aB,i8**%c,align 8
%aC=call fastcc i8*@_SMLFN13FunLocalLabel3Map4findE(i32 inreg 1,i32 inreg 8)
%aD=getelementptr inbounds i8,i8*%aC,i64 16
%aE=bitcast i8*%aD to i8*(i8*,i8*)**
%aF=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aE,align 8
%aG=bitcast i8*%aC to i8**
%aH=load i8*,i8**%aG,align 8
store i8*%aH,i8**%d,align 8
%aI=call i8*@sml_alloc(i32 inreg 20)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32 1342177296,i32*%aK,align 4
%aL=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aM=bitcast i8*%aI to i8**
store i8*%aL,i8**%aM,align 8
%aN=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aO=getelementptr inbounds i8,i8*%aI,i64 8
%aP=bitcast i8*%aO to i8**
store i8*%aN,i8**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aI,i64 16
%aR=bitcast i8*%aQ to i32*
store i32 3,i32*%aR,align 4
%aS=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aT=call fastcc i8*%aF(i8*inreg%aS,i8*inreg%aI)
%aU=icmp eq i8*%aT,null
br i1%aU,label%aV,label%bf
aV:
%aW=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%aW,i8**%c,align 8
%aX=call i8*@sml_alloc(i32 inreg 28)#0
%aY=getelementptr inbounds i8,i8*%aX,i64 -4
%aZ=bitcast i8*%aY to i32*
store i32 1342177304,i32*%aZ,align 4
store i8*%aX,i8**%d,align 8
%a0=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a1=bitcast i8*%aX to i8**
store i8*%a0,i8**%a1,align 8
%a2=getelementptr inbounds i8,i8*%aX,i64 8
%a3=bitcast i8*%a2 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@b,i64 0,i32 2,i64 0),i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aX,i64 16
%a5=bitcast i8*%a4 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[16x i8]}>,<{[4x i8],i32,[16x i8]}>*@c,i64 0,i32 2,i64 0),i8**%a5,align 8
%a6=getelementptr inbounds i8,i8*%aX,i64 24
%a7=bitcast i8*%a6 to i32*
store i32 7,i32*%a7,align 4
%a8=call i8*@sml_alloc(i32 inreg 60)#0
%a9=getelementptr inbounds i8,i8*%a8,i64 -4
%ba=bitcast i8*%a9 to i32*
store i32 1342177336,i32*%ba,align 4
%bb=getelementptr inbounds i8,i8*%a8,i64 56
%bc=bitcast i8*%bb to i32*
store i32 1,i32*%bc,align 4
%bd=load i8*,i8**%d,align 8
%be=bitcast i8*%a8 to i8**
store i8*%bd,i8**%be,align 8
call void@sml_raise(i8*inreg%a8)#1
unreachable
bf:
%bg=bitcast i8*%aT to i8**
%bh=load i8*,i8**%bg,align 8
%bi=bitcast i8*%bh to i32*
%bj=load i32,i32*%bi,align 4
%bk=icmp eq i32%bj,0
br i1%bk,label%bl,label%cr
bl:
%bm=getelementptr inbounds i8,i8*%bh,i64 8
%bn=bitcast i8*%bm to i8**
%bo=load i8*,i8**%bn,align 8
%bp=getelementptr inbounds i8,i8*%bh,i64 16
%bq=bitcast i8*%bp to i8**
%br=load i8*,i8**%bq,align 8
store i8*%bo,i8**%h,align 8
store i8*%br,i8**%c,align 8
br label%cp
bs:
%bt=getelementptr inbounds i8,i8*%Y,i64 8
%bu=bitcast i8*%bt to i8**
%bv=load i8*,i8**%bu,align 8
store i8*%bv,i8**%c,align 8
%bw=getelementptr inbounds i8,i8*%bv,i64 8
%bx=bitcast i8*%bw to i8**
%by=load i8*,i8**%bx,align 8
store i8*%by,i8**%d,align 8
%bz=getelementptr inbounds i8,i8*%bv,i64 16
%bA=bitcast i8*%bz to i8**
%bB=load i8*,i8**%bA,align 8
store i8*%bB,i8**%e,align 8
%bC=getelementptr inbounds i8,i8*%bv,i64 40
%bD=bitcast i8*%bC to i32*
%bE=load i32,i32*%bD,align 4
%bF=call fastcc i8*@_SMLFN13FunLocalLabel3Map6insertE(i32 inreg 1,i32 inreg 8)
%bG=getelementptr inbounds i8,i8*%bF,i64 16
%bH=bitcast i8*%bG to i8*(i8*,i8*)**
%bI=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bH,align 8
%bJ=bitcast i8*%bF to i8**
%bK=load i8*,i8**%bJ,align 8
store i8*%bK,i8**%g,align 8
%bL=call i8*@sml_alloc(i32 inreg 28)#0
%bM=getelementptr inbounds i8,i8*%bL,i64 -4
%bN=bitcast i8*%bM to i32*
store i32 1342177304,i32*%bN,align 4
store i8*%bL,i8**%f,align 8
%bO=getelementptr inbounds i8,i8*%bL,i64 4
%bP=bitcast i8*%bO to i32*
store i32 0,i32*%bP,align 1
%bQ=bitcast i8*%bL to i32*
store i32%bE,i32*%bQ,align 4
%bR=load i8*,i8**%h,align 8
%bS=getelementptr inbounds i8,i8*%bL,i64 8
%bT=bitcast i8*%bS to i8**
store i8*%bR,i8**%bT,align 8
%bU=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bV=getelementptr inbounds i8,i8*%bL,i64 16
%bW=bitcast i8*%bV to i8**
store i8*%bU,i8**%bW,align 8
%bX=getelementptr inbounds i8,i8*%bL,i64 24
%bY=bitcast i8*%bX to i32*
store i32 6,i32*%bY,align 4
%bZ=call i8*@sml_alloc(i32 inreg 28)#0
%b0=getelementptr inbounds i8,i8*%bZ,i64 -4
%b1=bitcast i8*%b0 to i32*
store i32 1342177304,i32*%b1,align 4
%b2=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b3=bitcast i8*%bZ to i8**
store i8*%b2,i8**%b3,align 8
%b4=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%b5=getelementptr inbounds i8,i8*%bZ,i64 8
%b6=bitcast i8*%b5 to i8**
store i8*%b4,i8**%b6,align 8
%b7=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%b8=getelementptr inbounds i8,i8*%bZ,i64 16
%b9=bitcast i8*%b8 to i8**
store i8*%b7,i8**%b9,align 8
%ca=getelementptr inbounds i8,i8*%bZ,i64 24
%cb=bitcast i8*%ca to i32*
store i32 7,i32*%cb,align 4
%cc=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cd=call fastcc i8*%bI(i8*inreg%cc,i8*inreg%bZ)
%ce=load i8*,i8**%c,align 8
%cf=getelementptr inbounds i8,i8*%ce,i64 32
%cg=bitcast i8*%cf to i8**
%ch=load i8*,i8**%cg,align 8
store i8*%cd,i8**%h,align 8
store i8*%ch,i8**%c,align 8
br label%cp
ci:
%cj=getelementptr inbounds i8,i8*%Y,i64 8
%ck=bitcast i8*%cj to i8**
%cl=load i8*,i8**%ck,align 8
%cm=getelementptr inbounds i8,i8*%cl,i64 40
%cn=bitcast i8*%cm to i8**
%co=load i8*,i8**%cn,align 8
store i8*%co,i8**%c,align 8
br label%cp
cp:
%cq=phi i8*[%br,%bl],[%ch,%bs],[%co,%ci]
br label%O
cr:
%cs=phi i1[true,%aa],[false,%bf],[true,%aa],[true,%aa],[true,%aa],[true,%U]
call void@llvm.lifetime.end.p0i8(i64 8,i8*%I)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%J)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%K)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%L)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%M)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%N)
%ct=load i8*,i8**%i,align 8
br i1%cs,label%cv,label%cu
cu:
ret i8*%ct
cv:
%cw=call fastcc i32@_SMLLN18ConcurrencySupport7hasCallE_114(i8*inreg%ct)
%cx=icmp eq i32%cw,0
br i1%cx,label%dd,label%cy
cy:
%cz=load i8**,i8***%w,align 8
store i8*null,i8**%l,align 8
%cA=load i8*,i8**%cz,align 8
store i8*%cA,i8**%i,align 8
%cB=call i8*@sml_alloc(i32 inreg 12)#0
%cC=getelementptr inbounds i8,i8*%cB,i64 -4
%cD=bitcast i8*%cC to i32*
store i32 1342177288,i32*%cD,align 4
store i8*%cB,i8**%l,align 8
%cE=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cF=bitcast i8*%cB to i8**
store i8*%cE,i8**%cF,align 8
%cG=getelementptr inbounds i8,i8*%cB,i64 8
%cH=bitcast i8*%cG to i32*
store i32 1,i32*%cH,align 4
%cI=call i8*@sml_alloc(i32 inreg 20)#0
%cJ=getelementptr inbounds i8,i8*%cI,i64 -4
%cK=bitcast i8*%cJ to i32*
store i32 1342177296,i32*%cK,align 4
store i8*%cI,i8**%i,align 8
%cL=getelementptr inbounds i8,i8*%cI,i64 4
%cM=bitcast i8*%cL to i32*
store i32 0,i32*%cM,align 1
%cN=bitcast i8*%cI to i32*
store i32 5,i32*%cN,align 4
%cO=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%cP=getelementptr inbounds i8,i8*%cI,i64 8
%cQ=bitcast i8*%cP to i8**
store i8*%cO,i8**%cQ,align 8
%cR=getelementptr inbounds i8,i8*%cI,i64 16
%cS=bitcast i8*%cR to i32*
store i32 2,i32*%cS,align 4
%cT=call i8*@sml_alloc(i32 inreg 20)#0
%cU=getelementptr inbounds i8,i8*%cT,i64 -4
%cV=bitcast i8*%cU to i32*
store i32 1342177296,i32*%cV,align 4
store i8*%cT,i8**%l,align 8
%cW=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cX=bitcast i8*%cT to i8**
store i8*%cW,i8**%cX,align 8
%cY=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cZ=getelementptr inbounds i8,i8*%cT,i64 8
%c0=bitcast i8*%cZ to i8**
store i8*%cY,i8**%c0,align 8
%c1=getelementptr inbounds i8,i8*%cT,i64 16
%c2=bitcast i8*%c1 to i32*
store i32 3,i32*%c2,align 4
%c3=call i8*@sml_alloc(i32 inreg 20)#0
%c4=getelementptr inbounds i8,i8*%c3,i64 -4
%c5=bitcast i8*%c4 to i32*
store i32 1342177296,i32*%c5,align 4
%c6=load i8*,i8**%l,align 8
%c7=bitcast i8*%c3 to i8**
store i8*%c6,i8**%c7,align 8
%c8=load i8*,i8**%k,align 8
%c9=getelementptr inbounds i8,i8*%c3,i64 8
%da=bitcast i8*%c9 to i8**
store i8*%c8,i8**%da,align 8
%db=getelementptr inbounds i8,i8*%c3,i64 16
%dc=bitcast i8*%db to i32*
store i32 3,i32*%dc,align 4
ret i8*%c3
dd:
%de=load i8*,i8**%i,align 8
ret i8*%de
}
define internal fastcc i8*@_SMLLN18ConcurrencySupport11compileBodyE_120(i8*inreg%a)unnamed_addr#4 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN18ConcurrencySupport11compileBodyE_119 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN18ConcurrencySupport11compileBodyE_119 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN18ConcurrencySupport13compileTopdecE_123(i8*inreg%a)#2 gc"smlsharp"{
s:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
store i8*%a,i8**%b,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%q,label%o
o:
call void@sml_check(i32 inreg%m)
%p=load i8*,i8**%b,align 8
br label%q
q:
%r=phi i8*[%p,%o],[%a,%s]
%t=bitcast i8*%r to i32*
%u=load i32,i32*%t,align 4
switch i32%u,label%v[
i32 1,label%bj
i32 0,label%N
]
v:
call void@sml_matchcomp_bug()
%w=load i8*,i8**@_SMLZ5Match,align 8
store i8*%w,i8**%b,align 8
%x=call i8*@sml_alloc(i32 inreg 20)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177296,i32*%z,align 4
store i8*%x,i8**%c,align 8
%A=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@g,i64 0,i32 2,i64 0),i8**%D,align 8
%E=getelementptr inbounds i8,i8*%x,i64 16
%F=bitcast i8*%E to i32*
store i32 3,i32*%F,align 4
%G=call i8*@sml_alloc(i32 inreg 60)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177336,i32*%I,align 4
%J=getelementptr inbounds i8,i8*%G,i64 56
%K=bitcast i8*%J to i32*
store i32 1,i32*%K,align 4
%L=load i8*,i8**%c,align 8
%M=bitcast i8*%G to i8**
store i8*%L,i8**%M,align 8
call void@sml_raise(i8*inreg%G)#1
unreachable
N:
%O=getelementptr inbounds i8,i8*%r,i64 8
%P=bitcast i8*%O to i8**
%Q=load i8*,i8**%P,align 8
store i8*%Q,i8**%b,align 8
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%c,align 8
%T=getelementptr inbounds i8,i8*%Q,i64 8
%U=bitcast i8*%T to i8**
%V=load i8*,i8**%U,align 8
store i8*%V,i8**%d,align 8
%W=getelementptr inbounds i8,i8*%Q,i64 24
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%Q,i64 32
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
store i8*%ab,i8**%f,align 8
%ac=getelementptr inbounds i8,i8*%Q,i64 40
%ad=bitcast i8*%ac to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%g,align 8
%af=getelementptr inbounds i8,i8*%Q,i64 48
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%h,align 8
%ai=getelementptr inbounds i8,i8*%Q,i64 56
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
store i8*%ak,i8**%i,align 8
%al=getelementptr inbounds i8,i8*%Q,i64 64
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%j,align 8
%ao=getelementptr inbounds i8,i8*%Q,i64 72
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
store i8*%aq,i8**%k,align 8
%ar=call fastcc i8*@_SMLLN18ConcurrencySupport11compileBodyE_120(i8*inreg%Y)
%as=getelementptr inbounds i8,i8*%ar,i64 16
%at=bitcast i8*%as to i8*(i8*,i8*)**
%au=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%at,align 8
%av=bitcast i8*%ar to i8**
%aw=load i8*,i8**%av,align 8
%ax=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ay=getelementptr inbounds i8,i8*%ax,i64 16
%az=bitcast i8*%ay to i8**
%aA=load i8*,i8**%az,align 8
%aB=call fastcc i8*%au(i8*inreg%aw,i8*inreg%aA)
store i8*%aB,i8**%b,align 8
%aC=call i8*@sml_alloc(i32 inreg 84)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177360,i32*%aE,align 4
store i8*%aC,i8**%l,align 8
%aF=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aG=bitcast i8*%aC to i8**
store i8*%aF,i8**%aG,align 8
%aH=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aI=getelementptr inbounds i8,i8*%aC,i64 8
%aJ=bitcast i8*%aI to i8**
store i8*%aH,i8**%aJ,align 8
%aK=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aL=getelementptr inbounds i8,i8*%aC,i64 16
%aM=bitcast i8*%aL to i8**
store i8*%aK,i8**%aM,align 8
%aN=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aO=getelementptr inbounds i8,i8*%aC,i64 24
%aP=bitcast i8*%aO to i8**
store i8*%aN,i8**%aP,align 8
%aQ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aR=getelementptr inbounds i8,i8*%aC,i64 32
%aS=bitcast i8*%aR to i8**
store i8*%aQ,i8**%aS,align 8
%aT=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aU=getelementptr inbounds i8,i8*%aC,i64 40
%aV=bitcast i8*%aU to i8**
store i8*%aT,i8**%aV,align 8
%aW=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aX=getelementptr inbounds i8,i8*%aC,i64 48
%aY=bitcast i8*%aX to i8**
store i8*%aW,i8**%aY,align 8
%aZ=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%a0=getelementptr inbounds i8,i8*%aC,i64 56
%a1=bitcast i8*%a0 to i8**
store i8*%aZ,i8**%a1,align 8
%a2=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%a3=getelementptr inbounds i8,i8*%aC,i64 64
%a4=bitcast i8*%a3 to i8**
store i8*%a2,i8**%a4,align 8
%a5=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%a6=getelementptr inbounds i8,i8*%aC,i64 72
%a7=bitcast i8*%a6 to i8**
store i8*%a5,i8**%a7,align 8
%a8=getelementptr inbounds i8,i8*%aC,i64 80
%a9=bitcast i8*%a8 to i32*
store i32 1023,i32*%a9,align 4
%ba=call i8*@sml_alloc(i32 inreg 20)#0
%bb=getelementptr inbounds i8,i8*%ba,i64 -4
%bc=bitcast i8*%bb to i32*
store i32 1342177296,i32*%bc,align 4
%bd=bitcast i8*%ba to i64*
store i64 0,i64*%bd,align 4
%be=load i8*,i8**%l,align 8
%bf=getelementptr inbounds i8,i8*%ba,i64 8
%bg=bitcast i8*%bf to i8**
store i8*%be,i8**%bg,align 8
%bh=getelementptr inbounds i8,i8*%ba,i64 16
%bi=bitcast i8*%bh to i32*
store i32 2,i32*%bi,align 4
ret i8*%ba
bj:
%bk=getelementptr inbounds i8,i8*%r,i64 8
%bl=bitcast i8*%bk to i8**
%bm=load i8*,i8**%bl,align 8
store i8*%bm,i8**%b,align 8
%bn=bitcast i8*%bm to i8**
%bo=load i8*,i8**%bn,align 8
store i8*%bo,i8**%c,align 8
%bp=getelementptr inbounds i8,i8*%bm,i64 16
%bq=bitcast i8*%bp to i8**
%br=load i8*,i8**%bq,align 8
store i8*%br,i8**%d,align 8
%bs=getelementptr inbounds i8,i8*%bm,i64 24
%bt=bitcast i8*%bs to i8**
%bu=load i8*,i8**%bt,align 8
store i8*%bu,i8**%e,align 8
%bv=getelementptr inbounds i8,i8*%bm,i64 40
%bw=bitcast i8*%bv to i8**
%bx=load i8*,i8**%bw,align 8
store i8*%bx,i8**%f,align 8
%by=getelementptr inbounds i8,i8*%bm,i64 48
%bz=bitcast i8*%by to i8**
%bA=load i8*,i8**%bz,align 8
store i8*%bA,i8**%g,align 8
%bB=getelementptr inbounds i8,i8*%bm,i64 56
%bC=bitcast i8*%bB to i8**
%bD=load i8*,i8**%bC,align 8
store i8*%bD,i8**%h,align 8
%bE=getelementptr inbounds i8,i8*%bm,i64 64
%bF=bitcast i8*%bE to i8**
%bG=load i8*,i8**%bF,align 8
store i8*%bG,i8**%i,align 8
%bH=getelementptr inbounds i8,i8*%bm,i64 32
%bI=bitcast i8*%bH to i32*
%bJ=load i32,i32*%bI,align 4
%bK=icmp eq i32%bJ,0
br i1%bK,label%bX,label%bL
bL:
%bM=call fastcc i8*@_SMLLN18ConcurrencySupport11compileBodyE_120(i8*inreg null)
%bN=getelementptr inbounds i8,i8*%bM,i64 16
%bO=bitcast i8*%bN to i8*(i8*,i8*)**
%bP=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bO,align 8
%bQ=bitcast i8*%bM to i8**
%bR=load i8*,i8**%bQ,align 8
%bS=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bT=getelementptr inbounds i8,i8*%bS,i64 8
%bU=bitcast i8*%bT to i8**
%bV=load i8*,i8**%bU,align 8
%bW=call fastcc i8*%bP(i8*inreg%bR,i8*inreg%bV)
br label%b1
bX:
store i8*null,i8**%b,align 8
%bY=getelementptr inbounds i8,i8*%bm,i64 8
%bZ=bitcast i8*%bY to i8**
%b0=load i8*,i8**%bZ,align 8
br label%b1
b1:
%b2=phi i8*[%b0,%bX],[%bW,%bL]
store i8*%b2,i8**%b,align 8
%b3=call i8*@sml_alloc(i32 inreg 76)#0
%b4=getelementptr inbounds i8,i8*%b3,i64 -4
%b5=bitcast i8*%b4 to i32*
store i32 1342177352,i32*%b5,align 4
store i8*%b3,i8**%j,align 8
%b6=getelementptr inbounds i8,i8*%b3,i64 36
%b7=bitcast i8*%b6 to i32*
store i32 0,i32*%b7,align 1
%b8=load i8*,i8**%c,align 8
%b9=bitcast i8*%b3 to i8**
store i8*null,i8**%c,align 8
store i8*%b8,i8**%b9,align 8
%ca=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cb=getelementptr inbounds i8,i8*%b3,i64 8
%cc=bitcast i8*%cb to i8**
store i8*%ca,i8**%cc,align 8
%cd=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ce=getelementptr inbounds i8,i8*%b3,i64 16
%cf=bitcast i8*%ce to i8**
store i8*%cd,i8**%cf,align 8
%cg=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ch=getelementptr inbounds i8,i8*%b3,i64 24
%ci=bitcast i8*%ch to i8**
store i8*%cg,i8**%ci,align 8
%cj=getelementptr inbounds i8,i8*%b3,i64 32
%ck=bitcast i8*%cj to i32*
store i32 0,i32*%ck,align 4
%cl=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cm=getelementptr inbounds i8,i8*%b3,i64 40
%cn=bitcast i8*%cm to i8**
store i8*%cl,i8**%cn,align 8
%co=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cp=getelementptr inbounds i8,i8*%b3,i64 48
%cq=bitcast i8*%cp to i8**
store i8*%co,i8**%cq,align 8
%cr=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cs=getelementptr inbounds i8,i8*%b3,i64 56
%ct=bitcast i8*%cs to i8**
store i8*%cr,i8**%ct,align 8
%cu=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cv=getelementptr inbounds i8,i8*%b3,i64 64
%cw=bitcast i8*%cv to i8**
store i8*%cu,i8**%cw,align 8
%cx=getelementptr inbounds i8,i8*%b3,i64 72
%cy=bitcast i8*%cx to i32*
store i32 495,i32*%cy,align 4
%cz=call i8*@sml_alloc(i32 inreg 20)#0
%cA=bitcast i8*%cz to i32*
%cB=getelementptr inbounds i8,i8*%cz,i64 -4
%cC=bitcast i8*%cB to i32*
store i32 1342177296,i32*%cC,align 4
%cD=getelementptr inbounds i8,i8*%cz,i64 4
%cE=bitcast i8*%cD to i32*
store i32 0,i32*%cE,align 1
store i32 1,i32*%cA,align 4
%cF=load i8*,i8**%j,align 8
%cG=getelementptr inbounds i8,i8*%cz,i64 8
%cH=bitcast i8*%cG to i8**
store i8*%cF,i8**%cH,align 8
%cI=getelementptr inbounds i8,i8*%cz,i64 16
%cJ=bitcast i8*%cI to i32*
store i32 2,i32*%cJ,align 4
ret i8*%cz
}
define fastcc i8*@_SMLFN18ConcurrencySupport13insertCheckGCE(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%e,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%o
l:
call void@sml_check(i32 inreg%h)
%m=bitcast i8**%e to i8***
%n=load i8**,i8***%m,align 8
br label%o
o:
%p=phi i8**[%n,%l],[%k,%j]
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%g,align 8
%r=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%s=getelementptr inbounds i8,i8*%r,i64 16
%t=bitcast i8*%s to i8*(i8*,i8*)**
%u=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%t,align 8
%v=bitcast i8*%r to i8**
%w=load i8*,i8**%v,align 8
%x=call fastcc i8*%u(i8*inreg%w,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@h,i64 0,i32 2)to i8*))
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
%D=load i8*,i8**%e,align 8
%E=getelementptr inbounds i8,i8*%D,i64 8
%F=bitcast i8*%E to i8**
%G=load i8*,i8**%F,align 8
%H=call fastcc i8*%A(i8*inreg%C,i8*inreg%G)
store i8*%H,i8**%f,align 8
%I=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%J=getelementptr inbounds i8,i8*%I,i64 16
%K=bitcast i8*%J to i8**
%L=load i8*,i8**%K,align 8
%M=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%M)
%N=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%N)
%O=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%O)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%L,i8**%b,align 8
%P=load atomic i32,i32*@sml_check_flag unordered,align 4
%Q=icmp eq i32%P,0
br i1%Q,label%T,label%R
R:
call void@sml_check(i32 inreg%P)
%S=load i8*,i8**%b,align 8
br label%T
T:
%U=phi i8*[%S,%R],[%L,%o]
%V=getelementptr inbounds i8,i8*%U,i64 8
%W=bitcast i8*%V to i8**
%X=load i8*,i8**%W,align 8
store i8*%X,i8**%c,align 8
%Y=getelementptr inbounds i8,i8*%U,i64 16
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
store i8*%aa,i8**%d,align 8
%ab=call fastcc i8*@_SMLLN18ConcurrencySupport11compileBodyE_120(i8*inreg%X)
%ac=getelementptr inbounds i8,i8*%ab,i64 16
%ad=bitcast i8*%ac to i8*(i8*,i8*)**
%ae=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ad,align 8
%af=bitcast i8*%ab to i8**
%ag=load i8*,i8**%af,align 8
%ah=bitcast i8**%b to i8***
%ai=load i8**,i8***%ah,align 8
store i8*null,i8**%b,align 8
%aj=load i8*,i8**%ai,align 8
%ak=call fastcc i8*%ae(i8*inreg%ag,i8*inreg%aj)
store i8*%ak,i8**%b,align 8
%al=call i8*@sml_alloc(i32 inreg 28)#0
%am=getelementptr inbounds i8,i8*%al,i64 -4
%an=bitcast i8*%am to i32*
store i32 1342177304,i32*%an,align 4
%ao=load i8*,i8**%b,align 8
%ap=bitcast i8*%al to i8**
store i8*%ao,i8**%ap,align 8
%aq=load i8*,i8**%c,align 8
%ar=getelementptr inbounds i8,i8*%al,i64 8
%as=bitcast i8*%ar to i8**
store i8*%aq,i8**%as,align 8
%at=load i8*,i8**%d,align 8
%au=getelementptr inbounds i8,i8*%al,i64 16
%av=bitcast i8*%au to i8**
store i8*%at,i8**%av,align 8
%aw=getelementptr inbounds i8,i8*%al,i64 24
%ax=bitcast i8*%aw to i32*
store i32 7,i32*%ax,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%M)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%N)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%O)
store i8*%al,i8**%e,align 8
%ay=call i8*@sml_alloc(i32 inreg 28)#0
%az=getelementptr inbounds i8,i8*%ay,i64 -4
%aA=bitcast i8*%az to i32*
store i32 1342177304,i32*%aA,align 4
%aB=load i8*,i8**%g,align 8
%aC=bitcast i8*%ay to i8**
store i8*%aB,i8**%aC,align 8
%aD=load i8*,i8**%f,align 8
%aE=getelementptr inbounds i8,i8*%ay,i64 8
%aF=bitcast i8*%aE to i8**
store i8*%aD,i8**%aF,align 8
%aG=load i8*,i8**%e,align 8
%aH=getelementptr inbounds i8,i8*%ay,i64 16
%aI=bitcast i8*%aH to i8**
store i8*%aG,i8**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%ay,i64 24
%aK=bitcast i8*%aJ to i32*
store i32 7,i32*%aK,align 4
ret i8*%ay
}
define internal fastcc i8*@_SMLLN18ConcurrencySupport13compileTopdecE_135(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLN18ConcurrencySupport13compileTopdecE_123(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN18ConcurrencySupport13insertCheckGCE_137(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN18ConcurrencySupport13insertCheckGCE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
