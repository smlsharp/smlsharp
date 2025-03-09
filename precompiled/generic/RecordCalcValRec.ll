@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZN5VarID3Set5emptyE=external local_unnamed_addr global i8*
@_SMLZN7LibBase8NotFoundE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLLLN16RecordCalcValRec3dfsE_57 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16RecordCalcValRec3dfsE_79 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[81x i8]}><{[4x i8]zeroinitializer,i32 -2147483567,[81x i8]c"src/compiler/compilePhases/partialevaluation/main/RecordCalcValRec.sml:26.2(644)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLL5binds_62 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5binds_81 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLLLN16RecordCalcValRec9decomposeE_66 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16RecordCalcValRec9decomposeE_82 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLL3inv_69 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3inv_83 to void(...)*),i32 -2147483647}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[83x i8]}><{[4x i8]zeroinitializer,i32 -2147483565,[83x i8]c"src/compiler/compilePhases/partialevaluation/main/RecordCalcValRec.sml:81.45(2729)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[10x i8]}><{[4x i8]zeroinitializer,i32 -2147483638,[10x i8]c"decompose\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN16RecordCalcValRec9decomposeE_74 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16RecordCalcValRec9decomposeE_85 to void(...)*),i32 -2147483647}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN16RecordCalcValRec9decomposeE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16RecordCalcValRec9decomposeE_86 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN16RecordCalcValRec9decomposeE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@i,i64 0,i32 2)to i8*)
@_SML_ftabc3f71c830930a29d_RecordCalcValRec=external global i8
@j=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN12RecordCalcFv5fvExpE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List1_VE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List5foldlE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map4findE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map6foldliE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map6insertE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map6lookupE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map8inDomainE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Map8listKeysE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5VarID3Set3addE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN5VarID3Set6memberE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main34dcc998b8dca612_lib_base()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main22c101bff228a4a9_LocalID()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main22bee215d45a17a3_RecordCalcFv()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load34dcc998b8dca612_lib_base(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_load22c101bff228a4a9_LocalID(i8*)local_unnamed_addr
declare void@_SML_load22bee215d45a17a3_RecordCalcFv(i8*)local_unnamed_addr
define private void@_SML_tabbc3f71c830930a29d_RecordCalcValRec()#3{
unreachable
}
define void@_SML_loadc3f71c830930a29d_RecordCalcValRec(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@j,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@j,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load34dcc998b8dca612_lib_base(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_load22c101bff228a4a9_LocalID(i8*%a)#0
tail call void@_SML_load22bee215d45a17a3_RecordCalcFv(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbc3f71c830930a29d_RecordCalcValRec,i8*@_SML_ftabc3f71c830930a29d_RecordCalcValRec,i8*null)#0
ret void
}
define void@_SML_mainc3f71c830930a29d_RecordCalcValRec()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@j,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@j,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main34dcc998b8dca612_lib_base()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_main22c101bff228a4a9_LocalID()#2
tail call void@_SML_main22bee215d45a17a3_RecordCalcFv()#2
br label%d
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec3dfsE_57(i32 inreg%a)#4 gc"smlsharp"{
%b=tail call i8*@sml_alloc(i32 inreg 12)#0
%c=bitcast i8*%b to i32*
%d=getelementptr inbounds i8,i8*%b,i64 -4
%e=bitcast i8*%d to i32*
store i32 1342177288,i32*%e,align 4
store i32 1,i32*%c,align 4
%f=getelementptr inbounds i8,i8*%b,i64 4
%g=bitcast i8*%f to i32*
store i32%a,i32*%g,align 4
%h=getelementptr inbounds i8,i8*%b,i64 8
%i=bitcast i8*%h to i32*
store i32 0,i32*%i,align 4
ret i8*%b
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec3dfsE_60(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d)unnamed_addr#2 gc"smlsharp"{
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
store i8*%a,i8**%i,align 8
store i8*%b,i8**%e,align 8
store i8*%c,i8**%f,align 8
store i8*%d,i8**%g,align 8
br label%m
m:
%n=load atomic i32,i32*@sml_check_flag unordered,align 4
%o=icmp eq i32%n,0
br i1%o,label%q,label%p
p:
call void@sml_check(i32 inreg%n)
br label%q
q:
%r=load i8*,i8**%g,align 8
%s=icmp eq i8*%r,null
br i1%s,label%t,label%E
t:
store i8*null,i8**%g,align 8
store i8*null,i8**%i,align 8
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=load i8*,i8**%f,align 8
%A=getelementptr inbounds i8,i8*%u,i64 8
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%u,i64 16
%D=bitcast i8*%C to i32*
store i32 3,i32*%D,align 4
ret i8*%u
E:
%F=bitcast i8*%r to i8**
%G=load i8*,i8**%F,align 8
%H=bitcast i8*%G to i32*
%I=load i32,i32*%H,align 4
switch i32%I,label%J[
i32 1,label%av
i32 0,label%ab
]
J:
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%i,align 8
call void@sml_matchcomp_bug()
%K=load i8*,i8**@_SMLZ5Match,align 8
store i8*%K,i8**%e,align 8
%L=call i8*@sml_alloc(i32 inreg 20)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
store i8*%L,i8**%f,align 8
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[81x i8]}>,<{[4x i8],i32,[81x i8]}>*@b,i64 0,i32 2,i64 0),i8**%R,align 8
%S=getelementptr inbounds i8,i8*%L,i64 16
%T=bitcast i8*%S to i32*
store i32 3,i32*%T,align 4
%U=call i8*@sml_alloc(i32 inreg 60)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177336,i32*%W,align 4
%X=getelementptr inbounds i8,i8*%U,i64 56
%Y=bitcast i8*%X to i32*
store i32 1,i32*%Y,align 4
%Z=load i8*,i8**%f,align 8
%aa=bitcast i8*%U to i8**
store i8*%Z,i8**%aa,align 8
call void@sml_raise(i8*inreg%U)#1
unreachable
ab:
%ac=getelementptr inbounds i8,i8*%G,i64 4
%ad=bitcast i8*%ac to i32*
%ae=load i32,i32*%ad,align 4
%af=getelementptr inbounds i8,i8*%r,i64 8
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%g,align 8
%ai=call i8*@sml_alloc(i32 inreg 20)#0
%aj=bitcast i8*%ai to i32*
%ak=getelementptr inbounds i8,i8*%ai,i64 -4
%al=bitcast i8*%ak to i32*
store i32 1342177296,i32*%al,align 4
%am=getelementptr inbounds i8,i8*%ai,i64 4
%an=bitcast i8*%am to i32*
store i32 0,i32*%an,align 1
store i32%ae,i32*%aj,align 4
%ao=load i8*,i8**%f,align 8
%ap=getelementptr inbounds i8,i8*%ai,i64 8
%aq=bitcast i8*%ap to i8**
store i8*%ao,i8**%aq,align 8
%ar=getelementptr inbounds i8,i8*%ai,i64 16
%as=bitcast i8*%ar to i32*
store i32 2,i32*%as,align 4
%at=load i8*,i8**%g,align 8
store i8*%ai,i8**%f,align 8
store i8*%at,i8**%g,align 8
br label%au
au:
br label%m
av:
%aw=getelementptr inbounds i8,i8*%G,i64 4
%ax=bitcast i8*%aw to i32*
%ay=load i32,i32*%ax,align 4
%az=getelementptr inbounds i8,i8*%r,i64 8
%aA=bitcast i8*%az to i8**
%aB=load i8*,i8**%aA,align 8
store i8*%aB,i8**%g,align 8
%aC=call i8*@sml_alloc(i32 inreg 20)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177296,i32*%aE,align 4
%aF=getelementptr inbounds i8,i8*%aC,i64 12
%aG=bitcast i8*%aF to i32*
store i32 0,i32*%aG,align 1
%aH=load i8*,i8**%e,align 8
%aI=bitcast i8*%aC to i8**
store i8*%aH,i8**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%aC,i64 8
%aK=bitcast i8*%aJ to i32*
store i32%ay,i32*%aK,align 4
%aL=getelementptr inbounds i8,i8*%aC,i64 16
%aM=bitcast i8*%aL to i32*
store i32 1,i32*%aM,align 4
%aN=call fastcc i32@_SMLFN5VarID3Set6memberE(i8*inreg%aC)
%aO=icmp eq i32%aN,0
br i1%aO,label%aP,label%au
aP:
%aQ=call fastcc i8*@_SMLFN5VarID3Map4findE(i32 inreg 1,i32 inreg 8)
%aR=getelementptr inbounds i8,i8*%aQ,i64 16
%aS=bitcast i8*%aR to i8*(i8*,i8*)**
%aT=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aS,align 8
%aU=bitcast i8*%aQ to i8**
%aV=load i8*,i8**%aU,align 8
store i8*%aV,i8**%h,align 8
%aW=call i8*@sml_alloc(i32 inreg 20)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177296,i32*%aY,align 4
%aZ=getelementptr inbounds i8,i8*%aW,i64 12
%a0=bitcast i8*%aZ to i32*
store i32 0,i32*%a0,align 1
%a1=load i8*,i8**%i,align 8
%a2=bitcast i8*%aW to i8**
store i8*%a1,i8**%a2,align 8
%a3=getelementptr inbounds i8,i8*%aW,i64 8
%a4=bitcast i8*%a3 to i32*
store i32%ay,i32*%a4,align 4
%a5=getelementptr inbounds i8,i8*%aW,i64 16
%a6=bitcast i8*%a5 to i32*
store i32 1,i32*%a6,align 4
%a7=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%a8=call fastcc i8*%aT(i8*inreg%a7,i8*inreg%aW)
%a9=icmp eq i8*%a8,null
br i1%a9,label%ba,label%bz
ba:
%bb=call i8*@sml_alloc(i32 inreg 20)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177296,i32*%bd,align 4
%be=getelementptr inbounds i8,i8*%bb,i64 12
%bf=bitcast i8*%be to i32*
store i32 0,i32*%bf,align 1
%bg=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bh=bitcast i8*%bb to i8**
store i8*%bg,i8**%bh,align 8
%bi=getelementptr inbounds i8,i8*%bb,i64 8
%bj=bitcast i8*%bi to i32*
store i32%ay,i32*%bj,align 4
%bk=getelementptr inbounds i8,i8*%bb,i64 16
%bl=bitcast i8*%bk to i32*
store i32 1,i32*%bl,align 4
%bm=call fastcc i8*@_SMLFN5VarID3Set3addE(i8*inreg%bb)
store i8*%bm,i8**%e,align 8
%bn=call i8*@sml_alloc(i32 inreg 20)#0
%bo=bitcast i8*%bn to i32*
%bp=getelementptr inbounds i8,i8*%bn,i64 -4
%bq=bitcast i8*%bp to i32*
store i32 1342177296,i32*%bq,align 4
%br=getelementptr inbounds i8,i8*%bn,i64 4
%bs=bitcast i8*%br to i32*
store i32 0,i32*%bs,align 1
store i32%ay,i32*%bo,align 4
%bt=load i8*,i8**%f,align 8
%bu=getelementptr inbounds i8,i8*%bn,i64 8
%bv=bitcast i8*%bu to i8**
store i8*%bt,i8**%bv,align 8
%bw=getelementptr inbounds i8,i8*%bn,i64 16
%bx=bitcast i8*%bw to i32*
store i32 2,i32*%bx,align 4
%by=load i8*,i8**%g,align 8
store i8*%bn,i8**%f,align 8
store i8*%by,i8**%g,align 8
br label%au
bz:
%bA=bitcast i8*%a8 to i8**
%bB=load i8*,i8**%bA,align 8
store i8*%bB,i8**%h,align 8
%bC=call i8*@sml_alloc(i32 inreg 20)#0
%bD=getelementptr inbounds i8,i8*%bC,i64 -4
%bE=bitcast i8*%bD to i32*
store i32 1342177296,i32*%bE,align 4
%bF=getelementptr inbounds i8,i8*%bC,i64 12
%bG=bitcast i8*%bF to i32*
store i32 0,i32*%bG,align 1
%bH=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bI=bitcast i8*%bC to i8**
store i8*%bH,i8**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bC,i64 8
%bK=bitcast i8*%bJ to i32*
store i32%ay,i32*%bK,align 4
%bL=getelementptr inbounds i8,i8*%bC,i64 16
%bM=bitcast i8*%bL to i32*
store i32 1,i32*%bM,align 4
%bN=call fastcc i8*@_SMLFN5VarID3Set3addE(i8*inreg%bC)
store i8*%bN,i8**%k,align 8
%bO=call fastcc i8*@_SMLFN4List1_VE(i32 inreg 1,i32 inreg 8)
%bP=getelementptr inbounds i8,i8*%bO,i64 16
%bQ=bitcast i8*%bP to i8*(i8*,i8*)**
%bR=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bQ,align 8
%bS=bitcast i8*%bO to i8**
%bT=load i8*,i8**%bS,align 8
store i8*%bT,i8**%j,align 8
%bU=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 0,i32 inreg 4,i32 inreg 1,i32 inreg 8)
%bV=getelementptr inbounds i8,i8*%bU,i64 16
%bW=bitcast i8*%bV to i8*(i8*,i8*)**
%bX=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bW,align 8
%bY=bitcast i8*%bU to i8**
%bZ=load i8*,i8**%bY,align 8
%b0=call fastcc i8*%bX(i8*inreg%bZ,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%b1=getelementptr inbounds i8,i8*%b0,i64 16
%b2=bitcast i8*%b1 to i8*(i8*,i8*)**
%b3=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%b2,align 8
%b4=bitcast i8*%b0 to i8**
%b5=load i8*,i8**%b4,align 8
%b6=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b7=call fastcc i8*%b3(i8*inreg%b5,i8*inreg%b6)
store i8*%b7,i8**%e,align 8
%b8=call i8*@sml_alloc(i32 inreg 12)#0
%b9=bitcast i8*%b8 to i32*
%ca=getelementptr inbounds i8,i8*%b8,i64 -4
%cb=bitcast i8*%ca to i32*
store i32 1342177288,i32*%cb,align 4
store i8*%b8,i8**%h,align 8
store i32 0,i32*%b9,align 4
%cc=getelementptr inbounds i8,i8*%b8,i64 4
%cd=bitcast i8*%cc to i32*
store i32%ay,i32*%cd,align 4
%ce=getelementptr inbounds i8,i8*%b8,i64 8
%cf=bitcast i8*%ce to i32*
store i32 0,i32*%cf,align 4
%cg=call i8*@sml_alloc(i32 inreg 20)#0
%ch=getelementptr inbounds i8,i8*%cg,i64 -4
%ci=bitcast i8*%ch to i32*
store i32 1342177296,i32*%ci,align 4
store i8*%cg,i8**%l,align 8
%cj=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ck=bitcast i8*%cg to i8**
store i8*%cj,i8**%ck,align 8
%cl=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cm=getelementptr inbounds i8,i8*%cg,i64 8
%cn=bitcast i8*%cm to i8**
store i8*%cl,i8**%cn,align 8
%co=getelementptr inbounds i8,i8*%cg,i64 16
%cp=bitcast i8*%co to i32*
store i32 3,i32*%cp,align 4
%cq=call i8*@sml_alloc(i32 inreg 20)#0
%cr=getelementptr inbounds i8,i8*%cq,i64 -4
%cs=bitcast i8*%cr to i32*
store i32 1342177296,i32*%cs,align 4
%ct=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cu=bitcast i8*%cq to i8**
store i8*%ct,i8**%cu,align 8
%cv=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%cw=getelementptr inbounds i8,i8*%cq,i64 8
%cx=bitcast i8*%cw to i8**
store i8*%cv,i8**%cx,align 8
%cy=getelementptr inbounds i8,i8*%cq,i64 16
%cz=bitcast i8*%cy to i32*
store i32 3,i32*%cz,align 4
%cA=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cB=call fastcc i8*%bR(i8*inreg%cA,i8*inreg%cq)
%cC=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
store i8*%cC,i8**%e,align 8
store i8*%cB,i8**%g,align 8
br label%au
}
define internal fastcc i8*@_SMLLL5binds_62(i8*inreg%a)#2 gc"smlsharp"{
m:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%b,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%b,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%a,%m]
%n=bitcast i8*%l to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%c,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i32**
%t=load i32*,i32**%s,align 8
%u=load i32,i32*%t,align 4
%v=getelementptr inbounds i8,i8*%l,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%d,align 8
%y=call fastcc i8*@_SMLFN5VarID3Map6insertE(i32 inreg 1,i32 inreg 8)
%z=getelementptr inbounds i8,i8*%y,i64 16
%A=bitcast i8*%z to i8*(i8*,i8*)**
%B=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%A,align 8
%C=bitcast i8*%y to i8**
%D=load i8*,i8**%C,align 8
store i8*%D,i8**%f,align 8
%E=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%F=call fastcc i8*@_SMLFN12RecordCalcFv5fvExpE(i8*inreg%E)
store i8*%F,i8**%c,align 8
%G=call i8*@sml_alloc(i32 inreg 20)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177296,i32*%I,align 4
store i8*%G,i8**%e,align 8
%J=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%M=getelementptr inbounds i8,i8*%G,i64 8
%N=bitcast i8*%M to i8**
store i8*%L,i8**%N,align 8
%O=getelementptr inbounds i8,i8*%G,i64 16
%P=bitcast i8*%O to i32*
store i32 3,i32*%P,align 4
%Q=call i8*@sml_alloc(i32 inreg 28)#0
%R=getelementptr inbounds i8,i8*%Q,i64 -4
%S=bitcast i8*%R to i32*
store i32 1342177304,i32*%S,align 4
%T=getelementptr inbounds i8,i8*%Q,i64 12
%U=bitcast i8*%T to i32*
store i32 0,i32*%U,align 1
%V=load i8*,i8**%d,align 8
%W=bitcast i8*%Q to i8**
store i8*%V,i8**%W,align 8
%X=getelementptr inbounds i8,i8*%Q,i64 8
%Y=bitcast i8*%X to i32*
store i32%u,i32*%Y,align 4
%Z=load i8*,i8**%e,align 8
%aa=getelementptr inbounds i8,i8*%Q,i64 16
%ab=bitcast i8*%aa to i8**
store i8*%Z,i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%Q,i64 24
%ad=bitcast i8*%ac to i32*
store i32 5,i32*%ad,align 4
%ae=load i8*,i8**%f,align 8
%af=tail call fastcc i8*%B(i8*inreg%ae,i8*inreg%Q)
ret i8*%af
}
define internal fastcc i8*@_SMLLL5graph_64(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
m:
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
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%b,%m]
%n=bitcast i8*%l to i32*
%o=load i32,i32*%n,align 4
%p=getelementptr inbounds i8,i8*%l,i64 4
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=getelementptr inbounds i8,i8*%l,i64 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=icmp slt i32%r,1
br i1%v,label%bM,label%w
w:
%x=call fastcc i8*@_SMLFN5VarID3Map8inDomainE(i32 inreg 1,i32 inreg 8)
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%f,align 8
%D=bitcast i8**%e to i8***
%E=load i8**,i8***%D,align 8
%F=load i8*,i8**%E,align 8
store i8*%F,i8**%d,align 8
%G=call i8*@sml_alloc(i32 inreg 20)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177296,i32*%I,align 4
%J=getelementptr inbounds i8,i8*%G,i64 12
%K=bitcast i8*%J to i32*
store i32 0,i32*%K,align 1
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=bitcast i8*%G to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 8
%O=bitcast i8*%N to i32*
store i32%o,i32*%O,align 4
%P=getelementptr inbounds i8,i8*%G,i64 16
%Q=bitcast i8*%P to i32*
store i32 1,i32*%Q,align 4
%R=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%S=call fastcc i8*%A(i8*inreg%R,i8*inreg%G)
%T=bitcast i8*%S to i32*
%U=load i32,i32*%T,align 4
%V=icmp eq i32%U,0
br i1%V,label%W,label%Y
W:
%X=load i8*,i8**%c,align 8
br label%bM
Y:
%Z=call fastcc i8*@_SMLFN5VarID3Map4findE(i32 inreg 1,i32 inreg 8)
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8*(i8*,i8*)**
%ac=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ab,align 8
%ad=bitcast i8*%Z to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%d,align 8
%af=load i8*,i8**%e,align 8
%ag=getelementptr inbounds i8,i8*%af,i64 8
%ah=bitcast i8*%ag to i32*
%ai=load i32,i32*%ah,align 4
%aj=call i8*@sml_alloc(i32 inreg 20)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32 1342177296,i32*%al,align 4
%am=getelementptr inbounds i8,i8*%aj,i64 12
%an=bitcast i8*%am to i32*
store i32 0,i32*%an,align 1
%ao=load i8*,i8**%c,align 8
%ap=bitcast i8*%aj to i8**
store i8*%ao,i8**%ap,align 8
%aq=getelementptr inbounds i8,i8*%aj,i64 8
%ar=bitcast i8*%aq to i32*
store i32%ai,i32*%ar,align 4
%as=getelementptr inbounds i8,i8*%aj,i64 16
%at=bitcast i8*%as to i32*
store i32 1,i32*%at,align 4
%au=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%av=call fastcc i8*%ac(i8*inreg%au,i8*inreg%aj)
%aw=icmp eq i8*%av,null
br i1%aw,label%ax,label%a8
ax:
%ay=call fastcc i8*@_SMLFN5VarID3Map6insertE(i32 inreg 1,i32 inreg 8)
%az=getelementptr inbounds i8,i8*%ay,i64 16
%aA=bitcast i8*%az to i8*(i8*,i8*)**
%aB=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aA,align 8
%aC=bitcast i8*%ay to i8**
%aD=load i8*,i8**%aC,align 8
store i8*%aD,i8**%d,align 8
%aE=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 8
%aG=bitcast i8*%aF to i32*
%aH=load i32,i32*%aG,align 4
%aI=call i8*@sml_alloc(i32 inreg 20)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32 1342177296,i32*%aK,align 4
store i8*%aI,i8**%e,align 8
%aL=getelementptr inbounds i8,i8*%aI,i64 4
%aM=bitcast i8*%aL to i32*
store i32 0,i32*%aM,align 1
%aN=bitcast i8*%aI to i32*
store i32%o,i32*%aN,align 4
%aO=getelementptr inbounds i8,i8*%aI,i64 8
%aP=bitcast i8*%aO to i8**
store i8*null,i8**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aI,i64 16
%aR=bitcast i8*%aQ to i32*
store i32 2,i32*%aR,align 4
%aS=call i8*@sml_alloc(i32 inreg 28)#0
%aT=getelementptr inbounds i8,i8*%aS,i64 -4
%aU=bitcast i8*%aT to i32*
store i32 1342177304,i32*%aU,align 4
%aV=getelementptr inbounds i8,i8*%aS,i64 12
%aW=bitcast i8*%aV to i32*
store i32 0,i32*%aW,align 1
%aX=load i8*,i8**%c,align 8
%aY=bitcast i8*%aS to i8**
store i8*%aX,i8**%aY,align 8
%aZ=getelementptr inbounds i8,i8*%aS,i64 8
%a0=bitcast i8*%aZ to i32*
store i32%aH,i32*%a0,align 4
%a1=load i8*,i8**%e,align 8
%a2=getelementptr inbounds i8,i8*%aS,i64 16
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aS,i64 24
%a5=bitcast i8*%a4 to i32*
store i32 5,i32*%a5,align 4
%a6=load i8*,i8**%d,align 8
%a7=tail call fastcc i8*%aB(i8*inreg%a6,i8*inreg%aS)
ret i8*%a7
a8:
%a9=bitcast i8*%av to i8**
%ba=load i8*,i8**%a9,align 8
store i8*%ba,i8**%d,align 8
%bb=call fastcc i8*@_SMLFN5VarID3Map6insertE(i32 inreg 1,i32 inreg 8)
%bc=getelementptr inbounds i8,i8*%bb,i64 16
%bd=bitcast i8*%bc to i8*(i8*,i8*)**
%be=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bd,align 8
%bf=bitcast i8*%bb to i8**
%bg=load i8*,i8**%bf,align 8
store i8*%bg,i8**%f,align 8
%bh=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bi=getelementptr inbounds i8,i8*%bh,i64 8
%bj=bitcast i8*%bi to i32*
%bk=load i32,i32*%bj,align 4
%bl=call i8*@sml_alloc(i32 inreg 20)#0
%bm=getelementptr inbounds i8,i8*%bl,i64 -4
%bn=bitcast i8*%bm to i32*
store i32 1342177296,i32*%bn,align 4
store i8*%bl,i8**%e,align 8
%bo=getelementptr inbounds i8,i8*%bl,i64 4
%bp=bitcast i8*%bo to i32*
store i32 0,i32*%bp,align 1
%bq=bitcast i8*%bl to i32*
store i32%o,i32*%bq,align 4
%br=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bs=getelementptr inbounds i8,i8*%bl,i64 8
%bt=bitcast i8*%bs to i8**
store i8*%br,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bl,i64 16
%bv=bitcast i8*%bu to i32*
store i32 2,i32*%bv,align 4
%bw=call i8*@sml_alloc(i32 inreg 28)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177304,i32*%by,align 4
%bz=getelementptr inbounds i8,i8*%bw,i64 12
%bA=bitcast i8*%bz to i32*
store i32 0,i32*%bA,align 1
%bB=load i8*,i8**%c,align 8
%bC=bitcast i8*%bw to i8**
store i8*%bB,i8**%bC,align 8
%bD=getelementptr inbounds i8,i8*%bw,i64 8
%bE=bitcast i8*%bD to i32*
store i32%bk,i32*%bE,align 4
%bF=load i8*,i8**%e,align 8
%bG=getelementptr inbounds i8,i8*%bw,i64 16
%bH=bitcast i8*%bG to i8**
store i8*%bF,i8**%bH,align 8
%bI=getelementptr inbounds i8,i8*%bw,i64 24
%bJ=bitcast i8*%bI to i32*
store i32 5,i32*%bJ,align 4
%bK=load i8*,i8**%f,align 8
%bL=tail call fastcc i8*%be(i8*inreg%bK,i8*inreg%bw)
ret i8*%bL
bM:
%bN=phi i8*[%X,%W],[%u,%k]
ret i8*%bN
}
define internal fastcc i8*@_SMLLL5graph_65(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%k=load i8*,i8**%c,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%b,%n]
%o=bitcast i8*%m to i32*
%p=load i32,i32*%o,align 4
%q=getelementptr inbounds i8,i8*%m,i64 8
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
%t=getelementptr inbounds i8,i8*%s,i64 8
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%c,align 8
%w=getelementptr inbounds i8,i8*%m,i64 16
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%d,align 8
%z=call fastcc i8*@_SMLFN5VarID3Map6foldliE(i32 inreg 0,i32 inreg 4,i32 inreg 1,i32 inreg 8)
%A=getelementptr inbounds i8,i8*%z,i64 16
%B=bitcast i8*%A to i8*(i8*,i8*)**
%C=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%B,align 8
%D=bitcast i8*%z to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%f,align 8
%F=bitcast i8**%e to i8***
%G=load i8**,i8***%F,align 8
%H=load i8*,i8**%G,align 8
store i8*%H,i8**%e,align 8
%I=call i8*@sml_alloc(i32 inreg 20)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177296,i32*%K,align 4
store i8*%I,i8**%g,align 8
%L=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to i32*
store i32%p,i32*%O,align 4
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to i32*
store i32 1,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 28)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177304,i32*%T,align 4
%U=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%R,i64 8
%X=bitcast i8*%W to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5graph_64 to void(...)*),void(...)**%X,align 8
%Y=getelementptr inbounds i8,i8*%R,i64 16
%Z=bitcast i8*%Y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5graph_64 to void(...)*),void(...)**%Z,align 8
%aa=getelementptr inbounds i8,i8*%R,i64 24
%ab=bitcast i8*%aa to i32*
store i32 -2147483647,i32*%ab,align 4
%ac=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ad=call fastcc i8*%C(i8*inreg%ac,i8*inreg%R)
%ae=getelementptr inbounds i8,i8*%ad,i64 16
%af=bitcast i8*%ae to i8*(i8*,i8*)**
%ag=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%af,align 8
%ah=bitcast i8*%ad to i8**
%ai=load i8*,i8**%ah,align 8
%aj=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ak=call fastcc i8*%ag(i8*inreg%ai,i8*inreg%aj)
%al=getelementptr inbounds i8,i8*%ak,i64 16
%am=bitcast i8*%al to i8*(i8*,i8*)**
%an=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%am,align 8
%ao=bitcast i8*%ak to i8**
%ap=load i8*,i8**%ao,align 8
%aq=load i8*,i8**%c,align 8
%ar=tail call fastcc i8*%an(i8*inreg%ap,i8*inreg%aq)
ret i8*%ar
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_66(i32 inreg%a)#4 gc"smlsharp"{
%b=tail call i8*@sml_alloc(i32 inreg 12)#0
%c=bitcast i8*%b to i32*
%d=getelementptr inbounds i8,i8*%b,i64 -4
%e=bitcast i8*%d to i32*
store i32 1342177288,i32*%e,align 4
store i32 1,i32*%c,align 4
%f=getelementptr inbounds i8,i8*%b,i64 4
%g=bitcast i8*%f to i32*
store i32%a,i32*%g,align 4
%h=getelementptr inbounds i8,i8*%b,i64 8
%i=bitcast i8*%h to i32*
store i32 0,i32*%i,align 4
ret i8*%b
}
define internal fastcc i8*@_SMLLL3inv_68(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
m:
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
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%c,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%b,%m]
%n=bitcast i8*%l to i32*
%o=load i32,i32*%n,align 4
%p=getelementptr inbounds i8,i8*%l,i64 8
%q=bitcast i8*%p to i8**
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%c,align 8
%s=call fastcc i8*@_SMLFN5VarID3Map4findE(i32 inreg 1,i32 inreg 8)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%d,align 8
%y=call i8*@sml_alloc(i32 inreg 20)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177296,i32*%A,align 4
%B=getelementptr inbounds i8,i8*%y,i64 12
%C=bitcast i8*%B to i32*
store i32 0,i32*%C,align 1
%D=load i8*,i8**%c,align 8
%E=bitcast i8*%y to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%y,i64 8
%G=bitcast i8*%F to i32*
store i32%o,i32*%G,align 4
%H=getelementptr inbounds i8,i8*%y,i64 16
%I=bitcast i8*%H to i32*
store i32 1,i32*%I,align 4
%J=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%K=call fastcc i8*%v(i8*inreg%J,i8*inreg%y)
%L=icmp eq i8*%K,null
br i1%L,label%M,label%aw
M:
%N=call fastcc i8*@_SMLFN5VarID3Map6insertE(i32 inreg 1,i32 inreg 8)
%O=getelementptr inbounds i8,i8*%N,i64 16
%P=bitcast i8*%O to i8*(i8*,i8*)**
%Q=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%P,align 8
%R=bitcast i8*%N to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%d,align 8
%T=bitcast i8**%e to i32**
%U=load i32*,i32**%T,align 8
store i8*null,i8**%e,align 8
%V=load i32,i32*%U,align 4
%W=call i8*@sml_alloc(i32 inreg 20)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177296,i32*%Y,align 4
store i8*%W,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%W,i64 4
%aa=bitcast i8*%Z to i32*
store i32 0,i32*%aa,align 1
%ab=bitcast i8*%W to i32*
store i32%V,i32*%ab,align 4
%ac=getelementptr inbounds i8,i8*%W,i64 8
%ad=bitcast i8*%ac to i8**
store i8*null,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%W,i64 16
%af=bitcast i8*%ae to i32*
store i32 2,i32*%af,align 4
%ag=call i8*@sml_alloc(i32 inreg 28)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177304,i32*%ai,align 4
%aj=getelementptr inbounds i8,i8*%ag,i64 12
%ak=bitcast i8*%aj to i32*
store i32 0,i32*%ak,align 1
%al=load i8*,i8**%c,align 8
%am=bitcast i8*%ag to i8**
store i8*%al,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%ag,i64 8
%ao=bitcast i8*%an to i32*
store i32%o,i32*%ao,align 4
%ap=load i8*,i8**%e,align 8
%aq=getelementptr inbounds i8,i8*%ag,i64 16
%ar=bitcast i8*%aq to i8**
store i8*%ap,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%ag,i64 24
%at=bitcast i8*%as to i32*
store i32 5,i32*%at,align 4
%au=load i8*,i8**%d,align 8
%av=tail call fastcc i8*%Q(i8*inreg%au,i8*inreg%ag)
ret i8*%av
aw:
%ax=bitcast i8*%K to i8**
%ay=load i8*,i8**%ax,align 8
store i8*%ay,i8**%d,align 8
%az=call fastcc i8*@_SMLFN5VarID3Map6insertE(i32 inreg 1,i32 inreg 8)
%aA=getelementptr inbounds i8,i8*%az,i64 16
%aB=bitcast i8*%aA to i8*(i8*,i8*)**
%aC=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aB,align 8
%aD=bitcast i8*%az to i8**
%aE=load i8*,i8**%aD,align 8
store i8*%aE,i8**%f,align 8
%aF=bitcast i8**%e to i32**
%aG=load i32*,i32**%aF,align 8
store i8*null,i8**%e,align 8
%aH=load i32,i32*%aG,align 4
%aI=call i8*@sml_alloc(i32 inreg 20)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32 1342177296,i32*%aK,align 4
store i8*%aI,i8**%e,align 8
%aL=getelementptr inbounds i8,i8*%aI,i64 4
%aM=bitcast i8*%aL to i32*
store i32 0,i32*%aM,align 1
%aN=bitcast i8*%aI to i32*
store i32%aH,i32*%aN,align 4
%aO=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aP=getelementptr inbounds i8,i8*%aI,i64 8
%aQ=bitcast i8*%aP to i8**
store i8*%aO,i8**%aQ,align 8
%aR=getelementptr inbounds i8,i8*%aI,i64 16
%aS=bitcast i8*%aR to i32*
store i32 2,i32*%aS,align 4
%aT=call i8*@sml_alloc(i32 inreg 28)#0
%aU=getelementptr inbounds i8,i8*%aT,i64 -4
%aV=bitcast i8*%aU to i32*
store i32 1342177304,i32*%aV,align 4
%aW=getelementptr inbounds i8,i8*%aT,i64 12
%aX=bitcast i8*%aW to i32*
store i32 0,i32*%aX,align 1
%aY=load i8*,i8**%c,align 8
%aZ=bitcast i8*%aT to i8**
store i8*%aY,i8**%aZ,align 8
%a0=getelementptr inbounds i8,i8*%aT,i64 8
%a1=bitcast i8*%a0 to i32*
store i32%o,i32*%a1,align 4
%a2=load i8*,i8**%e,align 8
%a3=getelementptr inbounds i8,i8*%aT,i64 16
%a4=bitcast i8*%a3 to i8**
store i8*%a2,i8**%a4,align 8
%a5=getelementptr inbounds i8,i8*%aT,i64 24
%a6=bitcast i8*%a5 to i32*
store i32 5,i32*%a6,align 4
%a7=load i8*,i8**%f,align 8
%a8=tail call fastcc i8*%aC(i8*inreg%a7,i8*inreg%aT)
ret i8*%a8
}
define internal fastcc i8*@_SMLLL3inv_69(i8*inreg%a)#2 gc"smlsharp"{
l:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%b,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%j,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%b,align 8
br label%j
j:
%k=phi i8*[%i,%h],[%a,%l]
%m=bitcast i8*%k to i32*
%n=load i32,i32*%m,align 4
%o=getelementptr inbounds i8,i8*%k,i64 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%b,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%c,align 8
%u=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg 0,i32 inreg 4,i32 inreg 1,i32 inreg 8)
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
store i8*%z,i8**%d,align 8
%A=call i8*@sml_alloc(i32 inreg 12)#0
%B=bitcast i8*%A to i32*
%C=getelementptr inbounds i8,i8*%A,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177288,i32*%D,align 4
store i8*%A,i8**%e,align 8
store i32%n,i32*%B,align 4
%E=getelementptr inbounds i8,i8*%A,i64 8
%F=bitcast i8*%E to i32*
store i32 0,i32*%F,align 4
%G=call i8*@sml_alloc(i32 inreg 28)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177304,i32*%I,align 4
%J=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3inv_68 to void(...)*),void(...)**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3inv_68 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%G,i64 24
%Q=bitcast i8*%P to i32*
store i32 -2147483647,i32*%Q,align 4
%R=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%S=call fastcc i8*%x(i8*inreg%R,i8*inreg%G)
%T=getelementptr inbounds i8,i8*%S,i64 16
%U=bitcast i8*%T to i8*(i8*,i8*)**
%V=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%U,align 8
%W=bitcast i8*%S to i8**
%X=load i8*,i8**%W,align 8
%Y=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%Z=call fastcc i8*%V(i8*inreg%X,i8*inreg%Y)
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8*(i8*,i8*)**
%ac=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ab,align 8
%ad=bitcast i8*%Z to i8**
%ae=load i8*,i8**%ad,align 8
%af=load i8*,i8**%b,align 8
%ag=tail call fastcc i8*%ac(i8*inreg%ae,i8*inreg%af)
ret i8*%ag
}
define internal fastcc i8*@_SMLLL6groups_71(i8*inreg%a,i32 inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i8*@_SMLFN5VarID3Map6lookupE(i32 inreg 1,i32 inreg 8)
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*)**
%l=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%d,align 8
%o=bitcast i8**%c to i8***
%p=load i8**,i8***%o,align 8
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%c,align 8
%r=call i8*@sml_alloc(i32 inreg 20)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177296,i32*%t,align 4
%u=getelementptr inbounds i8,i8*%r,i64 12
%v=bitcast i8*%u to i32*
store i32 0,i32*%v,align 1
%w=load i8*,i8**%c,align 8
%x=bitcast i8*%r to i8**
store i8*%w,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 8
%z=bitcast i8*%y to i32*
store i32%b,i32*%z,align 4
%A=getelementptr inbounds i8,i8*%r,i64 16
%B=bitcast i8*%A to i32*
store i32 1,i32*%B,align 4
%C=load i8*,i8**%d,align 8
%D=tail call fastcc i8*%l(i8*inreg%C,i8*inreg%r)
ret i8*%D
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_74(i8*inreg%a)#4 gc"smlsharp"{
%b=bitcast i8*%a to i8**
%c=load i8*,i8**%b,align 8
ret i8*%c
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_76(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
o:
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
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%m,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%c,align 8
br label%m
m:
%n=phi i8*[%l,%k],[%b,%o]
store i8*null,i8**%c,align 8
%p=icmp eq i8*%n,null
br i1%p,label%bi,label%q
q:
%r=bitcast i8*%n to i8**
%s=load i8*,i8**%r,align 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%c,align 8
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%d,align 8
%x=getelementptr inbounds i8,i8*%u,i64 8
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
store i8*%z,i8**%e,align 8
%A=getelementptr inbounds i8,i8*%s,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%f,align 8
%D=getelementptr inbounds i8,i8*%n,i64 8
%E=bitcast i8*%D to i8**
%F=load i8*,i8**%E,align 8
%G=icmp eq i8*%F,null
br i1%G,label%H,label%bh
H:
%I=call fastcc i8*@_SMLFN5VarID3Map8inDomainE(i32 inreg 0,i32 inreg 4)
%J=getelementptr inbounds i8,i8*%I,i64 16
%K=bitcast i8*%J to i8*(i8*,i8*)**
%L=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%K,align 8
%M=bitcast i8*%I to i8**
%N=load i8*,i8**%M,align 8
store i8*%N,i8**%h,align 8
%O=bitcast i8**%e to i32**
%P=load i32*,i32**%O,align 8
%Q=load i32,i32*%P,align 4
%R=call i8*@sml_alloc(i32 inreg 20)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177296,i32*%T,align 4
%U=getelementptr inbounds i8,i8*%R,i64 12
%V=bitcast i8*%U to i32*
store i32 0,i32*%V,align 1
%W=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%X=bitcast i8*%R to i8**
store i8*%W,i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%R,i64 8
%Z=bitcast i8*%Y to i32*
store i32%Q,i32*%Z,align 4
%aa=getelementptr inbounds i8,i8*%R,i64 16
%ab=bitcast i8*%aa to i32*
store i32 1,i32*%ab,align 4
%ac=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ad=call fastcc i8*%L(i8*inreg%ac,i8*inreg%R)
%ae=bitcast i8*%ad to i32*
%af=load i32,i32*%ae,align 4
%ag=icmp eq i32%af,0
br i1%ag,label%aP,label%ah
ah:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
%ai=call i8*@sml_alloc(i32 inreg 20)#0
%aj=getelementptr inbounds i8,i8*%ai,i64 -4
%ak=bitcast i8*%aj to i32*
store i32 1342177296,i32*%ak,align 4
store i8*%ai,i8**%e,align 8
%al=load i8*,i8**%c,align 8
%am=bitcast i8*%ai to i8**
store i8*%al,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%ai,i64 8
%ao=bitcast i8*%an to i8**
store i8*null,i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ai,i64 16
%aq=bitcast i8*%ap to i32*
store i32 3,i32*%aq,align 4
%ar=bitcast i8**%g to i8***
%as=load i8**,i8***%ar,align 8
store i8*null,i8**%g,align 8
%at=load i8*,i8**%as,align 8
store i8*%at,i8**%c,align 8
%au=call i8*@sml_alloc(i32 inreg 20)#0
%av=getelementptr inbounds i8,i8*%au,i64 -4
%aw=bitcast i8*%av to i32*
store i32 1342177296,i32*%aw,align 4
store i8*%au,i8**%d,align 8
%ax=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ay=bitcast i8*%au to i8**
store i8*%ax,i8**%ay,align 8
%az=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aA=getelementptr inbounds i8,i8*%au,i64 8
%aB=bitcast i8*%aA to i8**
store i8*%az,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%au,i64 16
%aD=bitcast i8*%aC to i32*
store i32 3,i32*%aD,align 4
%aE=call i8*@sml_alloc(i32 inreg 20)#0
%aF=bitcast i8*%aE to i32*
%aG=getelementptr inbounds i8,i8*%aE,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177296,i32*%aH,align 4
%aI=getelementptr inbounds i8,i8*%aE,i64 4
%aJ=bitcast i8*%aI to i32*
store i32 0,i32*%aJ,align 1
store i32 3,i32*%aF,align 4
%aK=load i8*,i8**%d,align 8
%aL=getelementptr inbounds i8,i8*%aE,i64 8
%aM=bitcast i8*%aL to i8**
store i8*%aK,i8**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aE,i64 16
%aO=bitcast i8*%aN to i32*
store i32 2,i32*%aO,align 4
ret i8*%aE
aP:
%aQ=bitcast i8**%g to i8***
%aR=load i8**,i8***%aQ,align 8
store i8*null,i8**%g,align 8
%aS=load i8*,i8**%aR,align 8
store i8*%aS,i8**%c,align 8
%aT=call i8*@sml_alloc(i32 inreg 28)#0
%aU=getelementptr inbounds i8,i8*%aT,i64 -4
%aV=bitcast i8*%aU to i32*
store i32 1342177304,i32*%aV,align 4
store i8*%aT,i8**%f,align 8
%aW=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aX=bitcast i8*%aT to i8**
store i8*%aW,i8**%aX,align 8
%aY=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aZ=getelementptr inbounds i8,i8*%aT,i64 8
%a0=bitcast i8*%aZ to i8**
store i8*%aY,i8**%a0,align 8
%a1=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%a2=getelementptr inbounds i8,i8*%aT,i64 16
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aT,i64 24
%a5=bitcast i8*%a4 to i32*
store i32 7,i32*%a5,align 4
%a6=call i8*@sml_alloc(i32 inreg 20)#0
%a7=bitcast i8*%a6 to i32*
%a8=getelementptr inbounds i8,i8*%a6,i64 -4
%a9=bitcast i8*%a8 to i32*
store i32 1342177296,i32*%a9,align 4
%ba=getelementptr inbounds i8,i8*%a6,i64 4
%bb=bitcast i8*%ba to i32*
store i32 0,i32*%bb,align 1
store i32 2,i32*%a7,align 4
%bc=load i8*,i8**%f,align 8
%bd=getelementptr inbounds i8,i8*%a6,i64 8
%be=bitcast i8*%bd to i8**
store i8*%bc,i8**%be,align 8
%bf=getelementptr inbounds i8,i8*%a6,i64 16
%bg=bitcast i8*%bf to i32*
store i32 2,i32*%bg,align 4
ret i8*%a6
bh:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
br label%bi
bi:
store i8*%n,i8**%c,align 8
%bj=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%bk=getelementptr inbounds i8,i8*%bj,i64 16
%bl=bitcast i8*%bk to i8*(i8*,i8*)**
%bm=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bl,align 8
%bn=bitcast i8*%bj to i8**
%bo=load i8*,i8**%bn,align 8
%bp=call fastcc i8*%bm(i8*inreg%bo,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@h,i64 0,i32 2)to i8*))
%bq=getelementptr inbounds i8,i8*%bp,i64 16
%br=bitcast i8*%bq to i8*(i8*,i8*)**
%bs=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%br,align 8
%bt=bitcast i8*%bp to i8**
%bu=load i8*,i8**%bt,align 8
%bv=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bw=call fastcc i8*%bs(i8*inreg%bu,i8*inreg%bv)
store i8*%bw,i8**%c,align 8
%bx=bitcast i8**%g to i8***
%by=load i8**,i8***%bx,align 8
store i8*null,i8**%g,align 8
%bz=load i8*,i8**%by,align 8
store i8*%bz,i8**%d,align 8
%bA=call i8*@sml_alloc(i32 inreg 20)#0
%bB=getelementptr inbounds i8,i8*%bA,i64 -4
%bC=bitcast i8*%bB to i32*
store i32 1342177296,i32*%bC,align 4
store i8*%bA,i8**%e,align 8
%bD=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bE=bitcast i8*%bA to i8**
store i8*%bD,i8**%bE,align 8
%bF=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bG=getelementptr inbounds i8,i8*%bA,i64 8
%bH=bitcast i8*%bG to i8**
store i8*%bF,i8**%bH,align 8
%bI=getelementptr inbounds i8,i8*%bA,i64 16
%bJ=bitcast i8*%bI to i32*
store i32 3,i32*%bJ,align 4
%bK=call i8*@sml_alloc(i32 inreg 20)#0
%bL=bitcast i8*%bK to i32*
%bM=getelementptr inbounds i8,i8*%bK,i64 -4
%bN=bitcast i8*%bM to i32*
store i32 1342177296,i32*%bN,align 4
%bO=getelementptr inbounds i8,i8*%bK,i64 4
%bP=bitcast i8*%bO to i32*
store i32 0,i32*%bP,align 1
store i32 3,i32*%bL,align 4
%bQ=load i8*,i8**%e,align 8
%bR=getelementptr inbounds i8,i8*%bK,i64 8
%bS=bitcast i8*%bR to i8**
store i8*%bQ,i8**%bS,align 8
%bT=getelementptr inbounds i8,i8*%bK,i64 16
%bU=bitcast i8*%bT to i32*
store i32 2,i32*%bU,align 4
ret i8*%bK
}
define fastcc i8*@_SMLFN16RecordCalcValRec9decomposeE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
%i=bitcast i8*%a to i8**
%j=load i8*,i8**%i,align 8
store i8*%j,i8**%b,align 8
%k=getelementptr inbounds i8,i8*%a,i64 8
%l=bitcast i8*%k to i8**
%m=load i8*,i8**%l,align 8
store i8*%m,i8**%c,align 8
%n=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%o=getelementptr inbounds i8,i8*%n,i64 16
%p=bitcast i8*%o to i8*(i8*,i8*)**
%q=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%p,align 8
%r=bitcast i8*%n to i8**
%s=load i8*,i8**%r,align 8
%t=call fastcc i8*%q(i8*inreg%s,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*))
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%d,align 8
%z=call fastcc i8*@_SMLFN5VarID3Map5emptyE(i32 inreg 1,i32 inreg 8)
%A=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%B=call fastcc i8*%w(i8*inreg%A,i8*inreg%z)
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
%F=bitcast i8*%B to i8**
%G=load i8*,i8**%F,align 8
%H=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%I=call fastcc i8*%E(i8*inreg%G,i8*inreg%H)
store i8*%I,i8**%b,align 8
%J=call fastcc i8*@_SMLFN5VarID3Map6foldliE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%K=getelementptr inbounds i8,i8*%J,i64 16
%L=bitcast i8*%K to i8*(i8*,i8*)**
%M=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%L,align 8
%N=bitcast i8*%J to i8**
%O=load i8*,i8**%N,align 8
store i8*%O,i8**%d,align 8
%P=call i8*@sml_alloc(i32 inreg 12)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177288,i32*%R,align 4
store i8*%P,i8**%e,align 8
%S=load i8*,i8**%b,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=getelementptr inbounds i8,i8*%P,i64 8
%V=bitcast i8*%U to i32*
store i32 1,i32*%V,align 4
%W=call i8*@sml_alloc(i32 inreg 28)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177304,i32*%Y,align 4
%Z=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aa=bitcast i8*%W to i8**
store i8*%Z,i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%W,i64 8
%ac=bitcast i8*%ab to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5graph_65 to void(...)*),void(...)**%ac,align 8
%ad=getelementptr inbounds i8,i8*%W,i64 16
%ae=bitcast i8*%ad to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5graph_65 to void(...)*),void(...)**%ae,align 8
%af=getelementptr inbounds i8,i8*%W,i64 24
%ag=bitcast i8*%af to i32*
store i32 -2147483647,i32*%ag,align 4
%ah=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ai=call fastcc i8*%M(i8*inreg%ah,i8*inreg%W)
%aj=getelementptr inbounds i8,i8*%ai,i64 16
%ak=bitcast i8*%aj to i8*(i8*,i8*)**
%al=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ak,align 8
%am=bitcast i8*%ai to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%d,align 8
%ao=call fastcc i8*@_SMLFN5VarID3Map5emptyE(i32 inreg 1,i32 inreg 8)
%ap=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aq=call fastcc i8*%al(i8*inreg%ap,i8*inreg%ao)
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8*(i8*,i8*)**
%at=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%as,align 8
%au=bitcast i8*%aq to i8**
%av=load i8*,i8**%au,align 8
%aw=load i8*,i8**%b,align 8
%ax=call fastcc i8*%at(i8*inreg%av,i8*inreg%aw)
store i8*%ax,i8**%d,align 8
%ay=call fastcc i8*@_SMLFN5VarID3Map8listKeysE(i32 inreg 1,i32 inreg 8)
%az=getelementptr inbounds i8,i8*%ay,i64 16
%aA=bitcast i8*%az to i8*(i8*,i8*)**
%aB=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aA,align 8
%aC=bitcast i8*%ay to i8**
%aD=load i8*,i8**%aC,align 8
%aE=load i8*,i8**%b,align 8
%aF=call fastcc i8*%aB(i8*inreg%aD,i8*inreg%aE)
store i8*%aF,i8**%e,align 8
%aG=load i8*,i8**@_SMLZN5VarID3Set5emptyE,align 8
store i8*%aG,i8**%f,align 8
%aH=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 0,i32 inreg 4,i32 inreg 1,i32 inreg 8)
%aI=getelementptr inbounds i8,i8*%aH,i64 16
%aJ=bitcast i8*%aI to i8*(i8*,i8*)**
%aK=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aJ,align 8
%aL=bitcast i8*%aH to i8**
%aM=load i8*,i8**%aL,align 8
%aN=call fastcc i8*%aK(i8*inreg%aM,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*))
%aO=getelementptr inbounds i8,i8*%aN,i64 16
%aP=bitcast i8*%aO to i8*(i8*,i8*)**
%aQ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aP,align 8
%aR=bitcast i8*%aN to i8**
%aS=load i8*,i8**%aR,align 8
%aT=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aU=call fastcc i8*%aQ(i8*inreg%aS,i8*inreg%aT)
%aV=load i8*,i8**%d,align 8
%aW=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aX=call fastcc i8*@_SMLLLN16RecordCalcValRec3dfsE_60(i8*inreg%aV,i8*inreg%aW,i8*inreg null,i8*inreg%aU)
%aY=getelementptr inbounds i8,i8*%aX,i64 8
%aZ=bitcast i8*%aY to i8**
%a0=load i8*,i8**%aZ,align 8
store i8*%a0,i8**%e,align 8
%a1=call fastcc i8*@_SMLFN5VarID3Map6foldliE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%a2=getelementptr inbounds i8,i8*%a1,i64 16
%a3=bitcast i8*%a2 to i8*(i8*,i8*)**
%a4=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a3,align 8
%a5=bitcast i8*%a1 to i8**
%a6=load i8*,i8**%a5,align 8
%a7=call fastcc i8*%a4(i8*inreg%a6,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*))
%a8=getelementptr inbounds i8,i8*%a7,i64 16
%a9=bitcast i8*%a8 to i8*(i8*,i8*)**
%ba=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a9,align 8
%bb=bitcast i8*%a7 to i8**
%bc=load i8*,i8**%bb,align 8
store i8*%bc,i8**%f,align 8
%bd=call fastcc i8*@_SMLFN5VarID3Map5emptyE(i32 inreg 1,i32 inreg 8)
%be=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bf=call fastcc i8*%ba(i8*inreg%be,i8*inreg%bd)
%bg=getelementptr inbounds i8,i8*%bf,i64 16
%bh=bitcast i8*%bg to i8*(i8*,i8*)**
%bi=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bh,align 8
%bj=bitcast i8*%bf to i8**
%bk=load i8*,i8**%bj,align 8
%bl=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bm=call fastcc i8*%bi(i8*inreg%bk,i8*inreg%bl)
store i8*%bm,i8**%d,align 8
%bn=load i8*,i8**@_SMLZN5VarID3Set5emptyE,align 8
%bo=load i8*,i8**%e,align 8
store i8*%bn,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*%bo,i8**%g,align 8
br label%bp
bp:
%bq=load atomic i32,i32*@sml_check_flag unordered,align 4
%br=icmp eq i32%bq,0
br i1%br,label%bt,label%bs
bs:
call void@sml_check(i32 inreg%bq)
br label%bt
bt:
%bu=load i8*,i8**%g,align 8
%bv=icmp eq i8*%bu,null
br i1%bv,label%bw,label%bz
bw:
store i8*null,i8**%e,align 8
store i8*null,i8**%g,align 8
%bx=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
store i8*%bx,i8**%d,align 8
%by=invoke fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
to label%cu unwind label%dK
bz:
%bA=bitcast i8*%bu to i32*
%bB=load i32,i32*%bA,align 4
%bC=getelementptr inbounds i8,i8*%bu,i64 8
%bD=bitcast i8*%bC to i8**
%bE=load i8*,i8**%bD,align 8
store i8*%bE,i8**%g,align 8
%bF=call i8*@sml_alloc(i32 inreg 20)#0
%bG=getelementptr inbounds i8,i8*%bF,i64 -4
%bH=bitcast i8*%bG to i32*
store i32 1342177296,i32*%bH,align 4
%bI=getelementptr inbounds i8,i8*%bF,i64 12
%bJ=bitcast i8*%bI to i32*
store i32 0,i32*%bJ,align 1
%bK=load i8*,i8**%e,align 8
%bL=bitcast i8*%bF to i8**
store i8*%bK,i8**%bL,align 8
%bM=getelementptr inbounds i8,i8*%bF,i64 8
%bN=bitcast i8*%bM to i32*
store i32%bB,i32*%bN,align 4
%bO=getelementptr inbounds i8,i8*%bF,i64 16
%bP=bitcast i8*%bO to i32*
store i32 1,i32*%bP,align 4
%bQ=call fastcc i32@_SMLFN5VarID3Set6memberE(i8*inreg%bF)
%bR=icmp eq i32%bQ,0
br i1%bR,label%bS,label%ct
bS:
%bT=call i8*@sml_alloc(i32 inreg 12)#0
%bU=bitcast i8*%bT to i32*
%bV=getelementptr inbounds i8,i8*%bT,i64 -4
%bW=bitcast i8*%bV to i32*
store i32 1342177288,i32*%bW,align 4
store i8*%bT,i8**%h,align 8
store i32 1,i32*%bU,align 4
%bX=getelementptr inbounds i8,i8*%bT,i64 4
%bY=bitcast i8*%bX to i32*
store i32%bB,i32*%bY,align 4
%bZ=getelementptr inbounds i8,i8*%bT,i64 8
%b0=bitcast i8*%bZ to i32*
store i32 0,i32*%b0,align 4
%b1=call i8*@sml_alloc(i32 inreg 20)#0
%b2=getelementptr inbounds i8,i8*%b1,i64 -4
%b3=bitcast i8*%b2 to i32*
store i32 1342177296,i32*%b3,align 4
%b4=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b5=bitcast i8*%b1 to i8**
store i8*%b4,i8**%b5,align 8
%b6=getelementptr inbounds i8,i8*%b1,i64 8
%b7=bitcast i8*%b6 to i8**
store i8*null,i8**%b7,align 8
%b8=getelementptr inbounds i8,i8*%b1,i64 16
%b9=bitcast i8*%b8 to i32*
store i32 3,i32*%b9,align 4
%ca=load i8*,i8**%d,align 8
%cb=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cc=call fastcc i8*@_SMLLLN16RecordCalcValRec3dfsE_60(i8*inreg%ca,i8*inreg%cb,i8*inreg null,i8*inreg%b1)
%cd=bitcast i8*%cc to i8**
%ce=load i8*,i8**%cd,align 8
store i8*%ce,i8**%e,align 8
%cf=getelementptr inbounds i8,i8*%cc,i64 8
%cg=bitcast i8*%cf to i8**
%ch=load i8*,i8**%cg,align 8
store i8*%ch,i8**%h,align 8
%ci=call i8*@sml_alloc(i32 inreg 20)#0
%cj=getelementptr inbounds i8,i8*%ci,i64 -4
%ck=bitcast i8*%cj to i32*
store i32 1342177296,i32*%ck,align 4
%cl=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cm=bitcast i8*%ci to i8**
store i8*%cl,i8**%cm,align 8
%cn=load i8*,i8**%f,align 8
%co=getelementptr inbounds i8,i8*%ci,i64 8
%cp=bitcast i8*%co to i8**
store i8*%cn,i8**%cp,align 8
%cq=getelementptr inbounds i8,i8*%ci,i64 16
%cr=bitcast i8*%cq to i32*
store i32 3,i32*%cr,align 4
%cs=load i8*,i8**%g,align 8
store i8*%ci,i8**%f,align 8
store i8*%cs,i8**%g,align 8
br label%ct
ct:
br label%bp
cu:
%cv=getelementptr inbounds i8,i8*%by,i64 16
%cw=bitcast i8*%cv to i8*(i8*,i8*)**
%cx=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cw,align 8
%cy=bitcast i8*%by to i8**
%cz=load i8*,i8**%cy,align 8
store i8*%cz,i8**%f,align 8
%cA=invoke fastcc i8*@_SMLFN4List3mapE(i32 inreg 0,i32 inreg 4,i32 inreg 1,i32 inreg 8)
to label%cB unwind label%dK
cB:
%cC=getelementptr inbounds i8,i8*%cA,i64 16
%cD=bitcast i8*%cC to i8*(i8*,i8*)**
%cE=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cD,align 8
%cF=bitcast i8*%cA to i8**
%cG=load i8*,i8**%cF,align 8
store i8*%cG,i8**%e,align 8
%cH=call i8*@sml_alloc(i32 inreg 12)#0
%cI=getelementptr inbounds i8,i8*%cH,i64 -4
%cJ=bitcast i8*%cI to i32*
store i32 1342177288,i32*%cJ,align 4
store i8*%cH,i8**%g,align 8
%cK=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cL=bitcast i8*%cH to i8**
store i8*%cK,i8**%cL,align 8
%cM=getelementptr inbounds i8,i8*%cH,i64 8
%cN=bitcast i8*%cM to i32*
store i32 1,i32*%cN,align 4
%cO=call i8*@sml_alloc(i32 inreg 28)#0
%cP=getelementptr inbounds i8,i8*%cO,i64 -4
%cQ=bitcast i8*%cP to i32*
store i32 1342177304,i32*%cQ,align 4
%cR=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cS=bitcast i8*%cO to i8**
store i8*%cR,i8**%cS,align 8
%cT=getelementptr inbounds i8,i8*%cO,i64 8
%cU=bitcast i8*%cT to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLL6groups_71 to void(...)*),void(...)**%cU,align 8
%cV=getelementptr inbounds i8,i8*%cO,i64 16
%cW=bitcast i8*%cV to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL6groups_84 to void(...)*),void(...)**%cW,align 8
%cX=getelementptr inbounds i8,i8*%cO,i64 24
%cY=bitcast i8*%cX to i32*
store i32 -2147483647,i32*%cY,align 4
%cZ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%c0=invoke fastcc i8*%cE(i8*inreg%cZ,i8*inreg%cO)
to label%c1 unwind label%dK
c1:
%c2=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%c3=invoke fastcc i8*%cx(i8*inreg%c2,i8*inreg%c0)
to label%c4 unwind label%dK
c4:
%c5=getelementptr inbounds i8,i8*%c3,i64 16
%c6=bitcast i8*%c5 to i8*(i8*,i8*)**
%c7=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%c6,align 8
%c8=bitcast i8*%c3 to i8**
%c9=load i8*,i8**%c8,align 8
%da=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%db=invoke fastcc i8*%c7(i8*inreg%c9,i8*inreg%da)
to label%dc unwind label%dK
dc:
store i8*%db,i8**%d,align 8
%dd=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%de=getelementptr inbounds i8,i8*%dd,i64 16
%df=bitcast i8*%de to i8*(i8*,i8*)**
%dg=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%df,align 8
%dh=bitcast i8*%dd to i8**
%di=load i8*,i8**%dh,align 8
store i8*%di,i8**%b,align 8
%dj=call i8*@sml_alloc(i32 inreg 12)#0
%dk=getelementptr inbounds i8,i8*%dj,i64 -4
%dl=bitcast i8*%dk to i32*
store i32 1342177288,i32*%dl,align 4
store i8*%dj,i8**%e,align 8
%dm=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dn=bitcast i8*%dj to i8**
store i8*%dm,i8**%dn,align 8
%do=getelementptr inbounds i8,i8*%dj,i64 8
%dp=bitcast i8*%do to i32*
store i32 1,i32*%dp,align 4
%dq=call i8*@sml_alloc(i32 inreg 28)#0
%dr=getelementptr inbounds i8,i8*%dq,i64 -4
%ds=bitcast i8*%dr to i32*
store i32 1342177304,i32*%ds,align 4
%dt=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%du=bitcast i8*%dq to i8**
store i8*%dt,i8**%du,align 8
%dv=getelementptr inbounds i8,i8*%dq,i64 8
%dw=bitcast i8*%dv to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16RecordCalcValRec9decomposeE_76 to void(...)*),void(...)**%dw,align 8
%dx=getelementptr inbounds i8,i8*%dq,i64 16
%dy=bitcast i8*%dx to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16RecordCalcValRec9decomposeE_76 to void(...)*),void(...)**%dy,align 8
%dz=getelementptr inbounds i8,i8*%dq,i64 24
%dA=bitcast i8*%dz to i32*
store i32 -2147483647,i32*%dA,align 4
%dB=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%dC=call fastcc i8*%dg(i8*inreg%dB,i8*inreg%dq)
%dD=getelementptr inbounds i8,i8*%dC,i64 16
%dE=bitcast i8*%dD to i8*(i8*,i8*)**
%dF=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dE,align 8
%dG=bitcast i8*%dC to i8**
%dH=load i8*,i8**%dG,align 8
%dI=load i8*,i8**%d,align 8
%dJ=tail call fastcc i8*%dF(i8*inreg%dH,i8*inreg%dI)
ret i8*%dJ
dK:
%dL=landingpad{i8*,i8*}
catch i8*null
%dM=extractvalue{i8*,i8*}%dL,1
%dN=bitcast i8*%dM to i8**
%dO=load i8*,i8**%dN,align 8
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
store i8*null,i8**%f,align 8
store i8*%dO,i8**%b,align 8
%dP=bitcast i8*%dO to i8**
%dQ=load i8*,i8**%dP,align 8
%dR=load i8*,i8**@_SMLZN7LibBase8NotFoundE,align 8
%dS=icmp eq i8*%dQ,%dR
br i1%dS,label%dT,label%ed
dT:
%dU=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%dU,i8**%b,align 8
%dV=call i8*@sml_alloc(i32 inreg 28)#0
%dW=getelementptr inbounds i8,i8*%dV,i64 -4
%dX=bitcast i8*%dW to i32*
store i32 1342177304,i32*%dX,align 4
store i8*%dV,i8**%c,align 8
%dY=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%dZ=bitcast i8*%dV to i8**
store i8*%dY,i8**%dZ,align 8
%d0=getelementptr inbounds i8,i8*%dV,i64 8
%d1=bitcast i8*%d0 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[83x i8]}>,<{[4x i8],i32,[83x i8]}>*@f,i64 0,i32 2,i64 0),i8**%d1,align 8
%d2=getelementptr inbounds i8,i8*%dV,i64 16
%d3=bitcast i8*%d2 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[10x i8]}>,<{[4x i8],i32,[10x i8]}>*@g,i64 0,i32 2,i64 0),i8**%d3,align 8
%d4=getelementptr inbounds i8,i8*%dV,i64 24
%d5=bitcast i8*%d4 to i32*
store i32 7,i32*%d5,align 4
%d6=call i8*@sml_alloc(i32 inreg 60)#0
%d7=getelementptr inbounds i8,i8*%d6,i64 -4
%d8=bitcast i8*%d7 to i32*
store i32 1342177336,i32*%d8,align 4
%d9=getelementptr inbounds i8,i8*%d6,i64 56
%ea=bitcast i8*%d9 to i32*
store i32 1,i32*%ea,align 4
%eb=load i8*,i8**%c,align 8
%ec=bitcast i8*%d6 to i8**
store i8*%eb,i8**%ec,align 8
call void@sml_raise(i8*inreg%d6)#1
unreachable
ed:
%ee=call i8*@sml_alloc(i32 inreg 60)#0
%ef=getelementptr inbounds i8,i8*%ee,i64 -4
%eg=bitcast i8*%ef to i32*
store i32 1342177336,i32*%eg,align 4
%eh=getelementptr inbounds i8,i8*%ee,i64 56
%ei=bitcast i8*%eh to i32*
store i32 1,i32*%ei,align 4
%ej=load i8*,i8**%b,align 8
%ek=bitcast i8*%ee to i8**
store i8*%ej,i8**%ek,align 8
call void@sml_raise(i8*inreg%ee)#1
unreachable
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec3dfsE_79(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLLN16RecordCalcValRec3dfsE_57(i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLL5binds_81(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLL5binds_62(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_82(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_66(i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLL3inv_83(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLL3inv_69(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLL6groups_84(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLL6groups_71(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_85(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%b to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN16RecordCalcValRec9decomposeE_86(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN16RecordCalcValRec9decomposeE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
