@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN6IntInf1_RE=external local_unnamed_addr global i8*
@_SMLZN6IntInf1_eE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"<eof>\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"[\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"]\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"{\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"}\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c",\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c":\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"null\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"true\00"}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"false\00"}>,align 8
@k=private unnamed_addr constant[2x i8]c"0\00"
@l=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"-\00"}>,align 8
@m=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLL1f_59 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL1f_68 to void(...)*),i32 -2147483647}>,align 8
@n=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"\22\00"}>,align 8
@o=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@n,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@p=private unnamed_addr constant<{[4x i8],i32,[8x i8]}><{[4x i8]zeroinitializer,i32 -2147483640,[8x i8]c"<error>\00"}>,align 8
@q=private unnamed_addr constant<{[4x i8],i32,[45x i8]}><{[4x i8]zeroinitializer,i32 -2147483603,[45x i8]c"src/smlnj-lib/JSON/json-tokens.sml:26.4(560)\00"}>,align 8
@r=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN10JSONTokens8toStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10JSONTokens8toStringE_69 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN10JSONTokens8toStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@r,i64 0,i32 2)to i8*)
@_SML_ftab1b21066d594226d8_json_tokens=external global i8
@s=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@sml_load_intinf(i8*inreg)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@sml_save()local_unnamed_addr#0
declare void@sml_unsave()local_unnamed_addr#0
declare i8*@_SMLFN10CharVector6concatE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List5foldrE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4UTF87explodeE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4UTF88toStringE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6IntInf8toStringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6Real648toStringE(i64 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String1_ZE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main9d24bdf03f9e5ec9_Real64()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main5d4c3ea7bd6f9540_IntInf()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadbb5309e852b68c_CharVector()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maindc75c24a45712161_utf8()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load9d24bdf03f9e5ec9_Real64(i8*)local_unnamed_addr
declare void@_SML_load5d4c3ea7bd6f9540_IntInf(i8*)local_unnamed_addr
declare void@_SML_loadadbb5309e852b68c_CharVector(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
declare void@_SML_loaddc75c24a45712161_utf8(i8*)local_unnamed_addr
define private void@_SML_tabb1b21066d594226d8_json_tokens()#3{
unreachable
}
define void@_SML_load1b21066d594226d8_json_tokens(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@s,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@s,align 1
tail call void@_SML_load9d24bdf03f9e5ec9_Real64(i8*%a)#0
tail call void@_SML_load5d4c3ea7bd6f9540_IntInf(i8*%a)#0
tail call void@_SML_loadadbb5309e852b68c_CharVector(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@_SML_loaddc75c24a45712161_utf8(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb1b21066d594226d8_json_tokens,i8*@_SML_ftab1b21066d594226d8_json_tokens,i8*null)#0
ret void
}
define void@_SML_main1b21066d594226d8_json_tokens()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@s,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@s,align 1
tail call void@_SML_main9d24bdf03f9e5ec9_Real64()#2
tail call void@_SML_main5d4c3ea7bd6f9540_IntInf()#2
tail call void@_SML_mainadbb5309e852b68c_CharVector()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main1ef93e13728790b1_String()#2
tail call void@_SML_maindc75c24a45712161_utf8()#2
br label%d
}
define internal fastcc i8*@_SMLLL1f_59(i8*inreg%a)#2 gc"smlsharp"{
j:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%h,label%f
f:
call void@sml_check(i32 inreg%d)
%g=load i8*,i8**%b,align 8
br label%h
h:
%i=phi i8*[%g,%f],[%a,%j]
%k=bitcast i8*%i to i32*
%l=load i32,i32*%k,align 4
%m=getelementptr inbounds i8,i8*%i,i64 8
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=call fastcc i8*@_SMLFN4UTF88toStringE(i32 inreg%l)
store i8*%p,i8**%c,align 8
%q=call i8*@sml_alloc(i32 inreg 20)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177296,i32*%s,align 4
%t=load i8*,i8**%c,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=load i8*,i8**%b,align 8
%w=getelementptr inbounds i8,i8*%q,i64 8
%x=bitcast i8*%w to i8**
store i8*%v,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%q,i64 16
%z=bitcast i8*%y to i32*
store i32 3,i32*%z,align 4
ret i8*%q
}
define fastcc i8*@_SMLFN10JSONTokens8toStringE(i8*inreg%a)#2 gc"smlsharp"{
k:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%b,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%b,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%a,%k]
store i8*null,i8**%b,align 8
%l=bitcast i8*%j to i32*
%m=load i32,i32*%l,align 4
switch i32%m,label%n[
i32 2,label%bK
i32 9,label%bJ
i32 11,label%bI
i32 10,label%bH
i32 12,label%bG
i32 1,label%bF
i32 0,label%bE
i32 7,label%bD
i32 8,label%bC
i32 6,label%bB
i32 5,label%aN
i32 4,label%ar
i32 13,label%H
i32 3,label%F
]
n:
call void@sml_matchcomp_bug()
%o=load i8*,i8**@_SMLZ5Match,align 8
store i8*%o,i8**%b,align 8
%p=call i8*@sml_alloc(i32 inreg 20)#0
%q=getelementptr inbounds i8,i8*%p,i64 -4
%r=bitcast i8*%q to i32*
store i32 1342177296,i32*%r,align 4
store i8*%p,i8**%c,align 8
%s=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%t=bitcast i8*%p to i8**
store i8*%s,i8**%t,align 8
%u=getelementptr inbounds i8,i8*%p,i64 8
%v=bitcast i8*%u to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[45x i8]}>,<{[4x i8],i32,[45x i8]}>*@q,i64 0,i32 2,i64 0),i8**%v,align 8
%w=getelementptr inbounds i8,i8*%p,i64 16
%x=bitcast i8*%w to i32*
store i32 3,i32*%x,align 4
%y=call i8*@sml_alloc(i32 inreg 60)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177336,i32*%A,align 4
%B=getelementptr inbounds i8,i8*%y,i64 56
%C=bitcast i8*%B to i32*
store i32 1,i32*%C,align 4
%D=load i8*,i8**%c,align 8
%E=bitcast i8*%y to i8**
store i8*%D,i8**%E,align 8
call void@sml_raise(i8*inreg%y)#1
unreachable
F:
%G=phi i8*[getelementptr inbounds(<{[4x i8],i32,[8x i8]}>,<{[4x i8],i32,[8x i8]}>*@p,i64 0,i32 2,i64 0),%i],[getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@j,i64 0,i32 2,i64 0),%bB],[getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@i,i64 0,i32 2,i64 0),%bC],[getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@h,i64 0,i32 2,i64 0),%bD],[getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@g,i64 0,i32 2,i64 0),%bE],[getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@f,i64 0,i32 2,i64 0),%bF],[getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@e,i64 0,i32 2,i64 0),%bG],[getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@d,i64 0,i32 2,i64 0),%bH],[getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@c,i64 0,i32 2,i64 0),%bI],[getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@b,i64 0,i32 2,i64 0),%bJ],[getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@a,i64 0,i32 2,i64 0),%bK]
ret i8*%G
H:
%I=getelementptr inbounds i8,i8*%j,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%b,align 8
%L=call fastcc i8*@_SMLFN4List5foldrE(i32 inreg 0,i32 inreg 4,i32 inreg 1,i32 inreg 8)
%M=getelementptr inbounds i8,i8*%L,i64 16
%N=bitcast i8*%M to i8*(i8*,i8*)**
%O=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%N,align 8
%P=bitcast i8*%L to i8**
%Q=load i8*,i8**%P,align 8
%R=call fastcc i8*%O(i8*inreg%Q,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@m,i64 0,i32 2)to i8*))
%S=getelementptr inbounds i8,i8*%R,i64 16
%T=bitcast i8*%S to i8*(i8*,i8*)**
%U=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%T,align 8
%V=bitcast i8*%R to i8**
%W=load i8*,i8**%V,align 8
%X=call fastcc i8*%U(i8*inreg%W,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@o,i64 0,i32 2)to i8*))
%Y=getelementptr inbounds i8,i8*%X,i64 16
%Z=bitcast i8*%Y to i8*(i8*,i8*)**
%aa=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Z,align 8
%ab=bitcast i8*%X to i8**
%ac=load i8*,i8**%ab,align 8
store i8*%ac,i8**%c,align 8
%ad=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ae=call fastcc i8*@_SMLFN4UTF87explodeE(i8*inreg%ad)
%af=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ag=call fastcc i8*%aa(i8*inreg%af,i8*inreg%ae)
store i8*%ag,i8**%b,align 8
%ah=call i8*@sml_alloc(i32 inreg 20)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177296,i32*%aj,align 4
%ak=bitcast i8*%ah to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@n,i64 0,i32 2,i64 0),i8**%ak,align 8
%al=load i8*,i8**%b,align 8
%am=getelementptr inbounds i8,i8*%ah,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ah,i64 16
%ap=bitcast i8*%ao to i32*
store i32 3,i32*%ap,align 4
%aq=tail call fastcc i8*@_SMLFN10CharVector6concatE(i8*inreg%ah)
ret i8*%aq
ar:
%as=getelementptr inbounds i8,i8*%j,i64 8
%at=bitcast i8*%as to double*
%au=load double,double*%at,align 8
%av=fcmp uge double%au,0.000000e+00
br i1%av,label%aK,label%aw
aw:
%ax=fsub double 0.000000e+00,%au
%ay=bitcast double%ax to i64
%az=call fastcc i8*@_SMLFN6Real648toStringE(i64 inreg%ay)
store i8*%az,i8**%b,align 8
%aA=call i8*@sml_alloc(i32 inreg 20)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 1342177296,i32*%aC,align 4
%aD=bitcast i8*%aA to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@l,i64 0,i32 2,i64 0),i8**%aD,align 8
%aE=load i8*,i8**%b,align 8
%aF=getelementptr inbounds i8,i8*%aA,i64 8
%aG=bitcast i8*%aF to i8**
store i8*%aE,i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aA,i64 16
%aI=bitcast i8*%aH to i32*
store i32 3,i32*%aI,align 4
%aJ=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%aA)
ret i8*%aJ
aK:
%aL=bitcast double%au to i64
%aM=tail call fastcc i8*@_SMLFN6Real648toStringE(i64 inreg%aL)
ret i8*%aM
aN:
%aO=getelementptr inbounds i8,i8*%j,i64 8
%aP=bitcast i8*%aO to i8**
%aQ=load i8*,i8**%aP,align 8
store i8*%aQ,i8**%b,align 8
%aR=load i8*,i8**@_SMLZN6IntInf1_RE,align 8
%aS=getelementptr inbounds i8,i8*%aR,i64 16
%aT=bitcast i8*%aS to i8*(i8*,i8*)**
%aU=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aT,align 8
%aV=bitcast i8*%aR to i8**
%aW=load i8*,i8**%aV,align 8
store i8*%aW,i8**%d,align 8
%aX=call i8*@sml_save()#0
%aY=call i8*@sml_load_intinf(i8*inreg getelementptr inbounds([2x i8],[2x i8]*@k,i64 0,i64 0))#0
call void@sml_unsave()#0
store i8*%aY,i8**%c,align 8
%aZ=call i8*@sml_alloc(i32 inreg 20)#0
%a0=getelementptr inbounds i8,i8*%aZ,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 1342177296,i32*%a1,align 4
%a2=load i8*,i8**%b,align 8
%a3=bitcast i8*%aZ to i8**
store i8*%a2,i8**%a3,align 8
%a4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a5=getelementptr inbounds i8,i8*%aZ,i64 8
%a6=bitcast i8*%a5 to i8**
store i8*%a4,i8**%a6,align 8
%a7=getelementptr inbounds i8,i8*%aZ,i64 16
%a8=bitcast i8*%a7 to i32*
store i32 3,i32*%a8,align 4
%a9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ba=call fastcc i8*%aU(i8*inreg%a9,i8*inreg%aZ)
%bb=bitcast i8*%ba to i32*
%bc=load i32,i32*%bb,align 4
%bd=icmp eq i32%bc,0
br i1%bd,label%by,label%be
be:
%bf=load i8*,i8**@_SMLZN6IntInf1_eE,align 8
%bg=getelementptr inbounds i8,i8*%bf,i64 16
%bh=bitcast i8*%bg to i8*(i8*,i8*)**
%bi=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bh,align 8
%bj=bitcast i8*%bf to i8**
%bk=load i8*,i8**%bj,align 8
%bl=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bm=call fastcc i8*%bi(i8*inreg%bk,i8*inreg%bl)
%bn=call fastcc i8*@_SMLFN6IntInf8toStringE(i8*inreg%bm)
store i8*%bn,i8**%b,align 8
%bo=call i8*@sml_alloc(i32 inreg 20)#0
%bp=getelementptr inbounds i8,i8*%bo,i64 -4
%bq=bitcast i8*%bp to i32*
store i32 1342177296,i32*%bq,align 4
%br=bitcast i8*%bo to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@l,i64 0,i32 2,i64 0),i8**%br,align 8
%bs=load i8*,i8**%b,align 8
%bt=getelementptr inbounds i8,i8*%bo,i64 8
%bu=bitcast i8*%bt to i8**
store i8*%bs,i8**%bu,align 8
%bv=getelementptr inbounds i8,i8*%bo,i64 16
%bw=bitcast i8*%bv to i32*
store i32 3,i32*%bw,align 4
%bx=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%bo)
ret i8*%bx
by:
%bz=load i8*,i8**%b,align 8
%bA=tail call fastcc i8*@_SMLFN6IntInf8toStringE(i8*inreg%bz)
ret i8*%bA
bB:
br label%F
bC:
br label%F
bD:
br label%F
bE:
br label%F
bF:
br label%F
bG:
br label%F
bH:
br label%F
bI:
br label%F
bJ:
br label%F
bK:
br label%F
}
define internal fastcc i8*@_SMLLL1f_68(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLL1f_59(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN10JSONTokens8toStringE_69(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN10JSONTokens8toStringE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
