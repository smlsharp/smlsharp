@_SMLZ4Size=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[13x i8]}><{[4x i8]zeroinitializer,i32 -2147483635,[13x i8]c"General.Span\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL38=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN7General7exnNameE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7General7exnNameE_49 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[39x i8]}><{[4x i8]zeroinitializer,i32 -2147483609,[39x i8]c"src/basis/main/General.sml:71.18(2421)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN7General10exnMessageE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7General10exnMessageE_50 to void(...)*),i32 -2147483647}>,align 8
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
N:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8***
%f=load i8**,i8***%e,align 8
%g=getelementptr inbounds i8,i8*%a,i64 8
%h=bitcast i8*%g to i8**
%i=load i8*,i8**%h,align 8
store i8*%i,i8**%b,align 8
%j=load i8*,i8**%f,align 8
%k=bitcast i8*%j to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%c,align 8
%m=getelementptr inbounds i8,i8*%j,i64 8
%n=bitcast i8*%m to i32*
%o=load i32,i32*%n,align 4
%p=icmp eq i32%o,0
br i1%p,label%L,label%q
q:
%r=and i32%o,1
%s=icmp eq i32%r,0
br i1%s,label%E,label%t
t:
%u=getelementptr inbounds i8,i8*%a,i64 -4
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=and i32%w,268435455
%y=add nsw i32%x,-8
%z=sext i32%y to i64
%A=getelementptr inbounds i8,i8*%a,i64%z
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
%D=and i32%o,-2
br label%E
E:
%F=phi i32[%D,%t],[%o,%q]
%G=phi i8*[%C,%t],[%a,%q]
%H=sext i32%F to i64
%I=getelementptr inbounds i8,i8*%G,i64%H
%J=bitcast i8*%I to i32**
%K=load i32*,i32**%J,align 8
br label%L
L:
%M=phi i32*[%K,%E],[bitcast(i8*getelementptr inbounds(<{[4x i8],i32,[1x i8]}>,<{[4x i8],i32,[1x i8]}>*@d,i64 0,i32 2,i64 0)to i32*),%N]
%O=bitcast i8**%d to i32**
store i32*%M,i32**%O,align 8
%P=getelementptr inbounds i8,i8*%l,i64 -4
%Q=bitcast i8*%P to i32*
%R=load i32,i32*%Q,align 4
%S=and i32%R,268435455
%T=add nsw i32%S,-1
%U=getelementptr inbounds i32,i32*%M,i64 -1
%V=load i32,i32*%U,align 4
%W=and i32%V,268435455
%X=add nsw i32%W,-1
%Y=getelementptr inbounds i8,i8*%i,i64 -4
%Z=bitcast i8*%Y to i32*
%aa=load i32,i32*%Z,align 4
%ab=and i32%aa,268435455
%ac=add nsw i32%ab,-1
%ad=icmp ne i32%X,0
%ae=select i1%ad,i32 6,i32 4
%af=add nsw i32%X,%T
%ag=add nsw i32%af,%ac
%ah=add nsw i32%ag,%ae
%ai=icmp ugt i32%ah,268435454
br i1%ai,label%ar,label%aj
aj:
%ak=add nsw i32%ah,1
%al=call i8*@sml_alloc(i32 inreg%ak)#0
%am=getelementptr inbounds i8,i8*%al,i64 -4
%an=bitcast i8*%am to i32*
store i32%ak,i32*%an,align 4
%ao=sext i32%ah to i64
%ap=getelementptr inbounds i8,i8*%al,i64%ao
store i8 0,i8*%ap,align 1
%aq=load i8*,i8**%c,align 8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%al,i8*%aq,i32%T,i1 false)
br i1%ad,label%aJ,label%aT
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
%aK=sext i32%T to i64
%aL=getelementptr inbounds i8,i8*%al,i64%aK
store i8 58,i8*%aL,align 1
%aM=zext i32%S to i64
%aN=getelementptr inbounds i8,i8*%al,i64%aM
store i8 32,i8*%aN,align 1
%aO=add nuw nsw i32%S,1
%aP=load i8*,i8**%d,align 8
%aQ=zext i32%aO to i64
%aR=getelementptr inbounds i8,i8*%al,i64%aQ
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aR,i8*%aP,i32%X,i1 false)
%aS=add nuw nsw i32%W,%S
br label%aT
aT:
%aU=phi i32[%aS,%aJ],[%T,%aj]
%aV=sext i32%aU to i64
%aW=getelementptr inbounds i8,i8*%al,i64%aV
store i8 32,i8*%aW,align 1
%aX=add nsw i32%aU,1
%aY=sext i32%aX to i64
%aZ=getelementptr inbounds i8,i8*%al,i64%aY
store i8 97,i8*%aZ,align 1
%a0=add nsw i32%aU,2
%a1=sext i32%a0 to i64
%a2=getelementptr inbounds i8,i8*%al,i64%a1
store i8 116,i8*%a2,align 1
%a3=add nsw i32%aU,3
%a4=sext i32%a3 to i64
%a5=getelementptr inbounds i8,i8*%al,i64%a4
store i8 32,i8*%a5,align 1
%a6=add nsw i32%aU,4
%a7=load i8*,i8**%b,align 8
%a8=sext i32%a6 to i64
%a9=getelementptr inbounds i8,i8*%al,i64%a8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%a9,i8*%a7,i32%ac,i1 false)
ret i8*%al
}
define internal fastcc i8*@_SMLLLN7General7exnNameE_49(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i8****
%d=load i8***,i8****%c,align 8
%e=load i8**,i8***%d,align 8
%f=load i8*,i8**%e,align 8
ret i8*%f
}
define internal fastcc i8*@_SMLLLN7General10exnMessageE_50(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN7General10exnMessageE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
attributes#4={uwtable}
