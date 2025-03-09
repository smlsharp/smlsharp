@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZ4Fail=external unnamed_addr constant i8*
@_SMLZ3Chr=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[55x i8]}><{[4x i8]zeroinitializer,i32 -2147483593,[55x i8]c"src/compiler/data/name/main/NameMangle.sml:49.17(1729)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[22x i8]}><{[4x i8]zeroinitializer,i32 -2147483626,[22x i8]c"PathToSymbol.escape: \00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[3x i8]}><{[4x i8]zeroinitializer,i32 -2147483645,[3x i8]c"_x\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[3x i8]}><{[4x i8]zeroinitializer,i32 -2147483645,[3x i8]c"_a\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[3x i8]}><{[4x i8]zeroinitializer,i32 -2147483645,[3x i8]c"__\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[55x i8]}><{[4x i8]zeroinitializer,i32 -2147483593,[55x i8]c"src/compiler/data/name/main/NameMangle.sml:38.22(1305)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"_\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[55x i8]}><{[4x i8]zeroinitializer,i32 -2147483593,[55x i8]c"src/compiler/data/name/main/NameMangle.sml:36.22(1206)\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8)*@_SMLLLN10NameMangle10escapeCharE_70 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10NameMangle10escapeCharE_80 to void(...)*),i32 -2147483647}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLL4path_72 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL4path_81 to void(...)*),i32 -2147483647}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"N\00"}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"E\00"}>,align 8
@m=private unnamed_addr constant<{[4x i8],i32,[55x i8]}><{[4x i8]zeroinitializer,i32 -2147483593,[55x i8]c"src/compiler/data/name/main/NameMangle.sml:54.25(1848)\00"}>,align 8
@n=private unnamed_addr constant<{[4x i8],i32,[18x i8]}><{[4x i8]zeroinitializer,i32 -2147483630,[18x i8]c"NameMangle.mangle\00"}>,align 8
@o=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN10NameMangle6mangleE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN10NameMangle6mangleE_82 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN10NameMangle6mangleE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@o,i64 0,i32 2)to i8*)
@_SML_ftab5bd60e3f75c6afa4_NameMangle=external global i8
@p=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN10CharVector6concatE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN4Char10isAlphaNumE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List6lengthE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Int323fmtE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Int328toStringE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String1_ZE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String3strE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String9translateE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main5148a836b3728be9_Int32()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maince7036f3433e1102_Char()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadbb5309e852b68c_CharVector()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load5148a836b3728be9_Int32(i8*)local_unnamed_addr
declare void@_SML_loadce7036f3433e1102_Char(i8*)local_unnamed_addr
declare void@_SML_loadadbb5309e852b68c_CharVector(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
define private void@_SML_tabb5bd60e3f75c6afa4_NameMangle()#3{
unreachable
}
define void@_SML_load5bd60e3f75c6afa4_NameMangle(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@p,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@p,align 1
tail call void@_SML_load5148a836b3728be9_Int32(i8*%a)#0
tail call void@_SML_loadce7036f3433e1102_Char(i8*%a)#0
tail call void@_SML_loadadbb5309e852b68c_CharVector(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb5bd60e3f75c6afa4_NameMangle,i8*@_SML_ftab5bd60e3f75c6afa4_NameMangle,i8*null)#0
ret void
}
define void@_SML_main5bd60e3f75c6afa4_NameMangle()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@p,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@p,align 1
tail call void@_SML_main5148a836b3728be9_Int32()#2
tail call void@_SML_maince7036f3433e1102_Char()#2
tail call void@_SML_mainadbb5309e852b68c_CharVector()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main1ef93e13728790b1_String()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
br label%d
}
define internal fastcc i8*@_SMLLLN10NameMangle10escapeCharE_70(i8 inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i32@_SMLFN4Char10isAlphaNumE(i8 inreg%a)
%j=icmp eq i32%i,0
br i1%j,label%m,label%k
k:
%l=tail call fastcc i8*@_SMLFN6String3strE(i8 inreg%a)
ret i8*%l
m:
%n=add i8%a,-33
%o=icmp ugt i8%n,14
br i1%o,label%Y,label%p
p:
%q=zext i8%a to i32
%r=add nuw nsw i32%q,32
%s=icmp ugt i32%r,255
br i1%s,label%G,label%t
t:
%u=trunc i32%r to i8
%v=call fastcc i8*@_SMLFN6String3strE(i8 inreg%u)
store i8*%v,i8**%b,align 8
%w=call i8*@sml_alloc(i32 inreg 20)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177296,i32*%y,align 4
%z=bitcast i8*%w to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@g,i64 0,i32 2,i64 0),i8**%z,align 8
%A=load i8*,i8**%b,align 8
%B=getelementptr inbounds i8,i8*%w,i64 8
%C=bitcast i8*%B to i8**
store i8*%A,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%w,i64 16
%E=bitcast i8*%D to i32*
store i32 3,i32*%E,align 4
%F=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%w)
ret i8*%F
G:
%H=load i8*,i8**@_SMLZ3Chr,align 8
store i8*%H,i8**%b,align 8
%I=call i8*@sml_alloc(i32 inreg 20)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177296,i32*%K,align 4
store i8*%I,i8**%c,align 8
%L=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[55x i8]}>,<{[4x i8],i32,[55x i8]}>*@h,i64 0,i32 2,i64 0),i8**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to i32*
store i32 3,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 60)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177336,i32*%T,align 4
%U=getelementptr inbounds i8,i8*%R,i64 56
%V=bitcast i8*%U to i32*
store i32 1,i32*%V,align 4
%W=load i8*,i8**%c,align 8
%X=bitcast i8*%R to i8**
store i8*%W,i8**%X,align 8
call void@sml_raise(i8*inreg%R)#1
unreachable
Y:
%Z=add i8%a,-58
%aa=icmp ugt i8%Z,6
br i1%aa,label%aK,label%ab
ab:
%ac=zext i8%a to i32
%ad=add nuw nsw i32%ac,22
%ae=icmp ugt i32%ad,255
br i1%ae,label%as,label%af
af:
%ag=trunc i32%ad to i8
%ah=call fastcc i8*@_SMLFN6String3strE(i8 inreg%ag)
store i8*%ah,i8**%b,align 8
%ai=call i8*@sml_alloc(i32 inreg 20)#0
%aj=getelementptr inbounds i8,i8*%ai,i64 -4
%ak=bitcast i8*%aj to i32*
store i32 1342177296,i32*%ak,align 4
%al=bitcast i8*%ai to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@g,i64 0,i32 2,i64 0),i8**%al,align 8
%am=load i8*,i8**%b,align 8
%an=getelementptr inbounds i8,i8*%ai,i64 8
%ao=bitcast i8*%an to i8**
store i8*%am,i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ai,i64 16
%aq=bitcast i8*%ap to i32*
store i32 3,i32*%aq,align 4
%ar=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%ai)
ret i8*%ar
as:
%at=load i8*,i8**@_SMLZ3Chr,align 8
store i8*%at,i8**%b,align 8
%au=call i8*@sml_alloc(i32 inreg 20)#0
%av=getelementptr inbounds i8,i8*%au,i64 -4
%aw=bitcast i8*%av to i32*
store i32 1342177296,i32*%aw,align 4
store i8*%au,i8**%c,align 8
%ax=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ay=bitcast i8*%au to i8**
store i8*%ax,i8**%ay,align 8
%az=getelementptr inbounds i8,i8*%au,i64 8
%aA=bitcast i8*%az to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[55x i8]}>,<{[4x i8],i32,[55x i8]}>*@f,i64 0,i32 2,i64 0),i8**%aA,align 8
%aB=getelementptr inbounds i8,i8*%au,i64 16
%aC=bitcast i8*%aB to i32*
store i32 3,i32*%aC,align 4
%aD=call i8*@sml_alloc(i32 inreg 60)#0
%aE=getelementptr inbounds i8,i8*%aD,i64 -4
%aF=bitcast i8*%aE to i32*
store i32 1342177336,i32*%aF,align 4
%aG=getelementptr inbounds i8,i8*%aD,i64 56
%aH=bitcast i8*%aG to i32*
store i32 1,i32*%aH,align 4
%aI=load i8*,i8**%c,align 8
%aJ=bitcast i8*%aD to i8**
store i8*%aI,i8**%aJ,align 8
call void@sml_raise(i8*inreg%aD)#1
unreachable
aK:
%aL=add i8%a,-91
%aM=icmp ugt i8%aL,3
br i1%aM,label%a0,label%aN
aN:
%aO=add i8%a,-4
%aP=call fastcc i8*@_SMLFN6String3strE(i8 inreg%aO)
store i8*%aP,i8**%b,align 8
%aQ=call i8*@sml_alloc(i32 inreg 20)#0
%aR=getelementptr inbounds i8,i8*%aQ,i64 -4
%aS=bitcast i8*%aR to i32*
store i32 1342177296,i32*%aS,align 4
%aT=bitcast i8*%aQ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@g,i64 0,i32 2,i64 0),i8**%aT,align 8
%aU=load i8*,i8**%b,align 8
%aV=getelementptr inbounds i8,i8*%aQ,i64 8
%aW=bitcast i8*%aV to i8**
store i8*%aU,i8**%aW,align 8
%aX=getelementptr inbounds i8,i8*%aQ,i64 16
%aY=bitcast i8*%aX to i32*
store i32 3,i32*%aY,align 4
%aZ=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%aQ)
ret i8*%aZ
a0:
switch i8%a,label%a4[
i8 95,label%a2
i8 96,label%a1
]
a1:
br label%a2
a2:
%a3=phi i8*[getelementptr inbounds(<{[4x i8],i32,[3x i8]}>,<{[4x i8],i32,[3x i8]}>*@e,i64 0,i32 2,i64 0),%a0],[getelementptr inbounds(<{[4x i8],i32,[3x i8]}>,<{[4x i8],i32,[3x i8]}>*@d,i64 0,i32 2,i64 0),%a1]
ret i8*%a3
a4:
%a5=add i8%a,-123
%a6=icmp ugt i8%a5,3
%a7=zext i8%a to i32
br i1%a6,label%bl,label%a8
a8:
%a9=add i8%a,-25
%ba=call fastcc i8*@_SMLFN6String3strE(i8 inreg%a9)
store i8*%ba,i8**%b,align 8
%bb=call i8*@sml_alloc(i32 inreg 20)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177296,i32*%bd,align 4
%be=bitcast i8*%bb to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@g,i64 0,i32 2,i64 0),i8**%be,align 8
%bf=load i8*,i8**%b,align 8
%bg=getelementptr inbounds i8,i8*%bb,i64 8
%bh=bitcast i8*%bg to i8**
store i8*%bf,i8**%bh,align 8
%bi=getelementptr inbounds i8,i8*%bb,i64 16
%bj=bitcast i8*%bi to i32*
store i32 3,i32*%bj,align 4
%bk=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%bb)
ret i8*%bk
bl:
%bm=icmp sgt i8%a,-1
br i1%bm,label%bK,label%bn
bn:
%bo=call fastcc i8*@_SMLFN5Int323fmtE(i32 inreg 2)
%bp=getelementptr inbounds i8,i8*%bo,i64 16
%bq=bitcast i8*%bp to i8*(i8*,i8*)**
%br=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bq,align 8
%bs=bitcast i8*%bo to i8**
%bt=load i8*,i8**%bs,align 8
store i8*%bt,i8**%b,align 8
%bu=call i8*@sml_alloc(i32 inreg 4)#0
%bv=bitcast i8*%bu to i32*
%bw=getelementptr inbounds i8,i8*%bu,i64 -4
%bx=bitcast i8*%bw to i32*
store i32 4,i32*%bx,align 4
store i32%a7,i32*%bv,align 4
%by=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bz=call fastcc i8*%br(i8*inreg%by,i8*inreg%bu)
store i8*%bz,i8**%b,align 8
%bA=call i8*@sml_alloc(i32 inreg 20)#0
%bB=getelementptr inbounds i8,i8*%bA,i64 -4
%bC=bitcast i8*%bB to i32*
store i32 1342177296,i32*%bC,align 4
%bD=bitcast i8*%bA to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[3x i8]}>,<{[4x i8],i32,[3x i8]}>*@c,i64 0,i32 2,i64 0),i8**%bD,align 8
%bE=load i8*,i8**%b,align 8
%bF=getelementptr inbounds i8,i8*%bA,i64 8
%bG=bitcast i8*%bF to i8**
store i8*%bE,i8**%bG,align 8
%bH=getelementptr inbounds i8,i8*%bA,i64 16
%bI=bitcast i8*%bH to i32*
store i32 3,i32*%bI,align 4
%bJ=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%bA)
ret i8*%bJ
bK:
%bL=load i8*,i8**@_SMLZ4Fail,align 8
store i8*%bL,i8**%b,align 8
%bM=call fastcc i8*@_SMLFN6String3strE(i8 inreg%a)
store i8*%bM,i8**%c,align 8
%bN=call i8*@sml_alloc(i32 inreg 20)#0
%bO=getelementptr inbounds i8,i8*%bN,i64 -4
%bP=bitcast i8*%bO to i32*
store i32 1342177296,i32*%bP,align 4
%bQ=bitcast i8*%bN to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[22x i8]}>,<{[4x i8],i32,[22x i8]}>*@b,i64 0,i32 2,i64 0),i8**%bQ,align 8
%bR=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bS=getelementptr inbounds i8,i8*%bN,i64 8
%bT=bitcast i8*%bS to i8**
store i8*%bR,i8**%bT,align 8
%bU=getelementptr inbounds i8,i8*%bN,i64 16
%bV=bitcast i8*%bU to i32*
store i32 3,i32*%bV,align 4
%bW=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%bN)
store i8*%bW,i8**%c,align 8
%bX=call i8*@sml_alloc(i32 inreg 28)#0
%bY=getelementptr inbounds i8,i8*%bX,i64 -4
%bZ=bitcast i8*%bY to i32*
store i32 1342177304,i32*%bZ,align 4
store i8*%bX,i8**%d,align 8
%b0=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%b1=bitcast i8*%bX to i8**
store i8*%b0,i8**%b1,align 8
%b2=getelementptr inbounds i8,i8*%bX,i64 8
%b3=bitcast i8*%b2 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[55x i8]}>,<{[4x i8],i32,[55x i8]}>*@a,i64 0,i32 2,i64 0),i8**%b3,align 8
%b4=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%b5=getelementptr inbounds i8,i8*%bX,i64 16
%b6=bitcast i8*%b5 to i8**
store i8*%b4,i8**%b6,align 8
%b7=getelementptr inbounds i8,i8*%bX,i64 24
%b8=bitcast i8*%b7 to i32*
store i32 7,i32*%b8,align 4
%b9=call i8*@sml_alloc(i32 inreg 60)#0
%ca=getelementptr inbounds i8,i8*%b9,i64 -4
%cb=bitcast i8*%ca to i32*
store i32 1342177336,i32*%cb,align 4
%cc=getelementptr inbounds i8,i8*%b9,i64 56
%cd=bitcast i8*%cc to i32*
store i32 1,i32*%cd,align 4
%ce=load i8*,i8**%d,align 8
%cf=bitcast i8*%b9 to i8**
store i8*%ce,i8**%cf,align 8
call void@sml_raise(i8*inreg%b9)#1
unreachable
}
define internal fastcc i8*@_SMLLL4path_72(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%f,label%h
f:
%g=bitcast i8*%a to i32*
br label%k
h:
call void@sml_check(i32 inreg%d)
%i=bitcast i8**%b to i32**
%j=load i32*,i32**%i,align 8
br label%k
k:
%l=phi i32*[%j,%h],[%g,%f]
%m=getelementptr inbounds i32,i32*%l,i64 -1
%n=load i32,i32*%m,align 4
%o=and i32%n,268435455
%p=add nsw i32%o,-1
%q=call fastcc i8*@_SMLFN5Int328toStringE(i32 inreg%p)
store i8*%q,i8**%c,align 8
%r=call fastcc i8*@_SMLFN6String9translateE(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@i,i64 0,i32 2)to i8*))
%s=getelementptr inbounds i8,i8*%r,i64 16
%t=bitcast i8*%s to i8*(i8*,i8*)**
%u=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%t,align 8
%v=bitcast i8*%r to i8**
%w=load i8*,i8**%v,align 8
%x=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%y=call fastcc i8*%u(i8*inreg%w,i8*inreg%x)
store i8*%y,i8**%b,align 8
%z=call i8*@sml_alloc(i32 inreg 20)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177296,i32*%B,align 4
%C=load i8*,i8**%c,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=load i8*,i8**%b,align 8
%F=getelementptr inbounds i8,i8*%z,i64 8
%G=bitcast i8*%F to i8**
store i8*%E,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%z,i64 16
%I=bitcast i8*%H to i32*
store i32 3,i32*%I,align 4
%J=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%z)
ret i8*%J
}
define fastcc i8*@_SMLFN10NameMangle6mangleE(i8*inreg%a)#2 gc"smlsharp"{
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
%k=icmp eq i8*%i,null
br i1%k,label%l,label%F
l:
%m=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%m,i8**%b,align 8
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
store i8*%n,i8**%c,align 8
%q=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%n,i64 8
%t=bitcast i8*%s to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[55x i8]}>,<{[4x i8],i32,[55x i8]}>*@m,i64 0,i32 2,i64 0),i8**%t,align 8
%u=getelementptr inbounds i8,i8*%n,i64 16
%v=bitcast i8*%u to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[18x i8]}>,<{[4x i8],i32,[18x i8]}>*@n,i64 0,i32 2,i64 0),i8**%v,align 8
%w=getelementptr inbounds i8,i8*%n,i64 24
%x=bitcast i8*%w to i32*
store i32 7,i32*%x,align 4
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
%G=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%H=getelementptr inbounds i8,i8*%G,i64 16
%I=bitcast i8*%H to i8*(i8*,i8*)**
%J=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%I,align 8
%K=bitcast i8*%G to i8**
%L=load i8*,i8**%K,align 8
%M=call fastcc i8*%J(i8*inreg%L,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@j,i64 0,i32 2)to i8*))
%N=getelementptr inbounds i8,i8*%M,i64 16
%O=bitcast i8*%N to i8*(i8*,i8*)**
%P=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%O,align 8
%Q=bitcast i8*%M to i8**
%R=load i8*,i8**%Q,align 8
%S=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%T=call fastcc i8*%P(i8*inreg%R,i8*inreg%S)
store i8*%T,i8**%b,align 8
%U=call fastcc i8*@_SMLFN10CharVector6concatE(i8*inreg%T)
store i8*%U,i8**%c,align 8
%V=call fastcc i8*@_SMLFN4List6lengthE(i32 inreg 1,i32 inreg 8)
%W=getelementptr inbounds i8,i8*%V,i64 16
%X=bitcast i8*%W to i8*(i8*,i8*)**
%Y=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%X,align 8
%Z=bitcast i8*%V to i8**
%aa=load i8*,i8**%Z,align 8
%ab=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ac=call fastcc i8*%Y(i8*inreg%aa,i8*inreg%ab)
%ad=bitcast i8*%ac to i32*
%ae=load i32,i32*%ad,align 4
%af=icmp slt i32%ae,2
br i1%af,label%aB,label%ag
ag:
%ah=call i8*@sml_alloc(i32 inreg 20)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177296,i32*%aj,align 4
%ak=bitcast i8*%ah to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@k,i64 0,i32 2,i64 0),i8**%ak,align 8
%al=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%am=getelementptr inbounds i8,i8*%ah,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ah,i64 16
%ap=bitcast i8*%ao to i32*
store i32 3,i32*%ap,align 4
%aq=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%ah)
store i8*%aq,i8**%b,align 8
%ar=call i8*@sml_alloc(i32 inreg 20)#0
%as=getelementptr inbounds i8,i8*%ar,i64 -4
%at=bitcast i8*%as to i32*
store i32 1342177296,i32*%at,align 4
%au=load i8*,i8**%b,align 8
%av=bitcast i8*%ar to i8**
store i8*%au,i8**%av,align 8
%aw=getelementptr inbounds i8,i8*%ar,i64 8
%ax=bitcast i8*%aw to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@l,i64 0,i32 2,i64 0),i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%ar,i64 16
%az=bitcast i8*%ay to i32*
store i32 3,i32*%az,align 4
%aA=tail call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%ar)
ret i8*%aA
aB:
%aC=load i8*,i8**%c,align 8
ret i8*%aC
}
define internal fastcc i8*@_SMLLLN10NameMangle10escapeCharE_80(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=load i8,i8*%b,align 1
%d=tail call fastcc i8*@_SMLLLN10NameMangle10escapeCharE_70(i8 inreg%c)
ret i8*%d
}
define internal fastcc i8*@_SMLLL4path_81(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLL4path_72(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN10NameMangle6mangleE_82(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN10NameMangle6mangleE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
