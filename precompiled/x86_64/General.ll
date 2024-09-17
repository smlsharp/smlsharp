@_SMLZ4Size=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[13x i8]}><{[4x i8]zeroinitializer,i32 -2147483635,[13x i8]c"General.Span\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL38=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN7General7exnNameE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN7General7exnNameE_49 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[39x i8]}><{[4x i8]zeroinitializer,i32 -2147483609,[39x i8]c"src/basis/main/General.sml:71.18(2421)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN7General10exnMessageE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN7General10exnMessageE_50 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN7General4SpanE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL38,i64 0,i32 2)to i8*)
@_SMLZN7General7exnNameE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN7General10exnMessageE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SML_ftab901c59645de00b4c_General=external global i8
@g=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
define private void@_SML_tabb901c59645de00b4c_General()#2{
unreachable
}
define void@_SML_load901c59645de00b4c_General(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@g,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@g,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb901c59645de00b4c_General,i8*@_SML_ftab901c59645de00b4c_General,i8*null)#0
ret void
}
define void@_SML_main901c59645de00b4c_General()local_unnamed_addr#3 gc"smlsharp"{
ret void
}
define fastcc i8*@_SMLFN7General7exnNameE(i8*inreg%a)#3 gc"smlsharp"{
%b=bitcast i8*%a to i8****
%c=load i8***,i8****%b,align 8
%d=load i8**,i8***%c,align 8
%e=load i8*,i8**%d,align 8
ret i8*%e
}
define fastcc i8*@_SMLFN7General10exnMessageE(i8*inreg%a)#4 gc"smlsharp"personality i32(...)*@sml_personality{
J:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%b,align 8
%e=bitcast i8*%a to i8***
%f=load i8**,i8***%e,align 8
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=getelementptr inbounds i8,i8*%g,i64 8
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=icmp eq i32%j,0
%l=bitcast i8*%g to i32**
br i1%k,label%H,label%m
m:
%n=and i32%j,1
%o=icmp eq i32%n,0
br i1%o,label%A,label%p
p:
%q=getelementptr inbounds i8,i8*%a,i64 -4
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=and i32%s,268435455
%u=add nsw i32%t,-8
%v=sext i32%u to i64
%w=getelementptr inbounds i8,i8*%a,i64%v
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
%z=and i32%j,-2
br label%A
A:
%B=phi i32[%z,%p],[%j,%m]
%C=phi i8*[%y,%p],[%a,%m]
%D=sext i32%B to i64
%E=getelementptr inbounds i8,i8*%C,i64%D
%F=bitcast i8*%E to i32**
%G=load i32*,i32**%F,align 8
br label%H
H:
%I=phi i32*[%G,%A],[bitcast(i8*getelementptr inbounds(<{[4x i8],i32,[1x i8]}>,<{[4x i8],i32,[1x i8]}>*@d,i64 0,i32 2,i64 0)to i32*),%J]
%K=bitcast i8**%c to i32**
store i32*%I,i32**%K,align 8
%L=load i32*,i32**%l,align 8
%M=getelementptr inbounds i32,i32*%L,i64 -1
%N=load i32,i32*%M,align 4
%O=and i32%N,268435455
%P=add nsw i32%O,-1
%Q=getelementptr inbounds i32,i32*%I,i64 -1
%R=load i32,i32*%Q,align 4
%S=and i32%R,268435455
%T=add nsw i32%S,-1
%U=getelementptr inbounds i8,i8*%a,i64 8
%V=bitcast i8*%U to i32**
%W=load i32*,i32**%V,align 8
%X=getelementptr inbounds i32,i32*%W,i64 -1
%Y=load i32,i32*%X,align 4
%Z=and i32%Y,268435455
%aa=add nsw i32%Z,-1
%ab=icmp ne i32%T,0
%ac=select i1%ab,i32 6,i32 4
%ad=add nsw i32%T,%P
%ae=add nsw i32%ad,%aa
%af=add nsw i32%ae,%ac
%ag=icmp ugt i32%af,268435454
br i1%ag,label%ar,label%ah
ah:
%ai=add nsw i32%af,1
%aj=call i8*@sml_alloc(i32 inreg%ai)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32%ai,i32*%al,align 4
%am=sext i32%af to i64
%an=getelementptr inbounds i8,i8*%aj,i64%am
store i8 0,i8*%an,align 1
%ao=bitcast i8**%d to i8***
%ap=load i8**,i8***%ao,align 8
%aq=load i8*,i8**%ap,align 8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aj,i8*%aq,i32%P,i1 false)
br i1%ab,label%aJ,label%aT
ar:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
%as=load i8*,i8**@_SMLZ4Size,align 8
store i8*%as,i8**%b,align 8
%at=call i8*@sml_alloc(i32 inreg 20)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 1342177296,i32*%av,align 4
store i8*%at,i8**%c,align 8
%aw=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ax=bitcast i8*%at to i8**
store i8*%aw,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[39x i8]}>,<{[4x i8],i32,[39x i8]}>*@e,i64 0,i32 2,i64 0),i8**%az,align 8
%aA=getelementptr inbounds i8,i8*%at,i64 16
%aB=bitcast i8*%aA to i32*
store i32 3,i32*%aB,align 4
%aC=call i8*@sml_alloc(i32 inreg 60)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177336,i32*%aE,align 4
%aF=getelementptr inbounds i8,i8*%aC,i64 56
%aG=bitcast i8*%aF to i32*
store i32 1,i32*%aG,align 4
%aH=load i8*,i8**%c,align 8
%aI=bitcast i8*%aC to i8**
store i8*%aH,i8**%aI,align 8
call void@sml_raise(i8*inreg%aC)#1
unreachable
aJ:
%aK=sext i32%P to i64
%aL=getelementptr inbounds i8,i8*%aj,i64%aK
store i8 58,i8*%aL,align 1
%aM=zext i32%O to i64
%aN=getelementptr inbounds i8,i8*%aj,i64%aM
store i8 32,i8*%aN,align 1
%aO=add nuw nsw i32%O,1
%aP=load i8*,i8**%c,align 8
%aQ=zext i32%aO to i64
%aR=getelementptr inbounds i8,i8*%aj,i64%aQ
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aR,i8*%aP,i32%T,i1 false)
%aS=add nuw nsw i32%S,%O
br label%aT
aT:
%aU=phi i32[%aS,%aJ],[%P,%ah]
%aV=sext i32%aU to i64
%aW=getelementptr inbounds i8,i8*%aj,i64%aV
store i8 32,i8*%aW,align 1
%aX=add nsw i32%aU,1
%aY=sext i32%aX to i64
%aZ=getelementptr inbounds i8,i8*%aj,i64%aY
store i8 97,i8*%aZ,align 1
%a0=add nsw i32%aU,2
%a1=sext i32%a0 to i64
%a2=getelementptr inbounds i8,i8*%aj,i64%a1
store i8 116,i8*%a2,align 1
%a3=add nsw i32%aU,3
%a4=sext i32%a3 to i64
%a5=getelementptr inbounds i8,i8*%aj,i64%a4
store i8 32,i8*%a5,align 1
%a6=add nsw i32%aU,4
%a7=load i8*,i8**%b,align 8
%a8=getelementptr inbounds i8,i8*%a7,i64 8
%a9=bitcast i8*%a8 to i8**
%ba=load i8*,i8**%a9,align 8
%bb=sext i32%a6 to i64
%bc=getelementptr inbounds i8,i8*%aj,i64%bb
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%bc,i8*%ba,i32%aa,i1 false)
ret i8*%aj
}
define internal fastcc i8*@_SMLLN7General7exnNameE_49(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i8****
%d=load i8***,i8****%c,align 8
%e=load i8**,i8***%d,align 8
%f=load i8*,i8**%e,align 8
ret i8*%f
}
define internal fastcc i8*@_SMLLN7General10exnMessageE_50(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN7General10exnMessageE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
attributes#4={uwtable}
