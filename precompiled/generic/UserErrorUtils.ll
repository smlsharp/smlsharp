@sml_check_flag=external local_unnamed_addr global i32
@_SML_gvar872d7bd4cbb24e12_UserErrorUtils=private global<{[4x i8],i32,[10x i8*]}><{[4x i8]zeroinitializer,i32 -1342177200,[10x i8*]zeroinitializer}>,align 8
@a=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@a to i64))]
@_SML_ftab872d7bd4cbb24e12_UserErrorUtils=external global i8
@b=private unnamed_addr global i8 0
@_SMLZN14UserErrorUtils20initializeErrorQueueE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 0)
@_SMLZN14UserErrorUtils20getErrorsAndWarningsE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 1)
@_SMLZN14UserErrorUtils9getErrorsE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 2)
@_SMLZN14UserErrorUtils10isAnyErrorE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 3)
@_SMLZN14UserErrorUtils11getWarningsE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 4)
@_SMLZN14UserErrorUtils12enqueueErrorE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 5)
@_SMLZN14UserErrorUtils14enqueueWarningE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 6)
@_SMLZN14UserErrorUtils23checkSymbolDuplication_GE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 7)
@_SMLZN14UserErrorUtils22checkSymbolDuplicationE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 8)
@_SMLZN14UserErrorUtils27checkRecordLabelDuplicationE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i32 0,i32 2,i32 9)
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_save_exn(i8*inreg)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN11RecordLabel3Map4findE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN11RecordLabel3Map6insertE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN11RecordLabel3Map9listItemsE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i32@_SMLFN4Bool3notE(i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN4List3appE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN6Symbol11symbolToLocE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9SymbolEnv4findE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9SymbolEnv5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9SymbolEnv6insertE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9SymbolEnv9listItemsE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SMLFN9UserError10clearQueueE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9UserError11createQueueE(i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9UserError11getWarningsE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9UserError12enqueueErrorE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9UserError14enqueueWarningE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9UserError20getErrorsAndWarningsE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9UserError9getErrorsE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maindaa180c1799f3810_Bool()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main44ca35c4c731682b_Symbol()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main60e750412e2bb4fe_RecordLabel()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_mainadeb402e3568875f_UserError_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_loaddaa180c1799f3810_Bool(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load44ca35c4c731682b_Symbol(i8*)local_unnamed_addr
declare void@_SML_load60e750412e2bb4fe_RecordLabel(i8*)local_unnamed_addr
declare void@_SML_loadadeb402e3568875f_UserError_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb872d7bd4cbb24e12_UserErrorUtils()#2{
unreachable
}
define void@_SML_load872d7bd4cbb24e12_UserErrorUtils(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@b,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@b,align 1
tail call void@_SML_loaddaa180c1799f3810_Bool(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load44ca35c4c731682b_Symbol(i8*%a)#0
tail call void@_SML_load60e750412e2bb4fe_RecordLabel(i8*%a)#0
tail call void@_SML_loadadeb402e3568875f_UserError_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb872d7bd4cbb24e12_UserErrorUtils,i8*@_SML_ftab872d7bd4cbb24e12_UserErrorUtils,i8*bitcast([2x i64]*@a to i8*))#0
ret void
}
define void@_SML_main872d7bd4cbb24e12_UserErrorUtils()local_unnamed_addr#1 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=load i8,i8*@b,align 1
%j=and i8%i,2
%k=icmp eq i8%j,0
br i1%k,label%m,label%l
l:
ret void
m:
store i8 3,i8*@b,align 1
tail call void@_SML_maindaa180c1799f3810_Bool()#1
tail call void@_SML_main03d87556ec7f64b2_List()#1
tail call void@_SML_main44ca35c4c731682b_Symbol()#1
tail call void@_SML_main60e750412e2bb4fe_RecordLabel()#1
tail call void@_SML_mainadeb402e3568875f_UserError_ppg()#1
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
%n=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%n)#0
%o=load atomic i32,i32*@sml_check_flag unordered,align 4
%p=icmp eq i32%o,0
br i1%p,label%r,label%q
q:
invoke void@sml_check(i32 inreg%o)
to label%r unwind label%df
r:
%s=invoke fastcc i8*@_SMLFN9UserError11createQueueE(i32 inreg 0)
to label%t unwind label%df
t:
store i8*%s,i8**%b,align 8
%u=invoke fastcc i8*@_SMLFN9UserError12enqueueErrorE(i8*inreg%s)
to label%v unwind label%df
v:
store i8*%u,i8**%c,align 8
%w=load i8*,i8**%b,align 8
%x=invoke fastcc i8*@_SMLFN9UserError14enqueueWarningE(i8*inreg%w)
to label%y unwind label%df
y:
store i8*%x,i8**%d,align 8
%z=call i8*@sml_alloc(i32 inreg 12)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177288,i32*%B,align 4
store i8*%z,i8**%e,align 8
%C=load i8*,i8**%c,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
%G=call i8*@sml_alloc(i32 inreg 28)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177304,i32*%I,align 4
%J=load i8*,i8**%e,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_53 to void(...)*),void(...)**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_99 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%G,i64 24
%Q=bitcast i8*%P to i32*
store i32 -2147483647,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 12)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177288,i32*%T,align 4
store i8*%R,i8**%f,align 8
%U=load i8*,i8**%e,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%R,i64 8
%X=bitcast i8*%W to i32*
store i32 1,i32*%X,align 4
%Y=call i8*@sml_alloc(i32 inreg 28)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177304,i32*%aa,align 4
%ab=load i8*,i8**%f,align 8
%ac=bitcast i8*%Y to i8**
store i8*%ab,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%Y,i64 8
%ae=bitcast i8*%ad to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_60 to void(...)*),void(...)**%ae,align 8
%af=getelementptr inbounds i8,i8*%Y,i64 16
%ag=bitcast i8*%af to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_102 to void(...)*),void(...)**%ag,align 8
%ah=getelementptr inbounds i8,i8*%Y,i64 24
%ai=bitcast i8*%ah to i32*
store i32 -2147483647,i32*%ai,align 4
%aj=call i8*@sml_alloc(i32 inreg 12)#0
%ak=getelementptr inbounds i8,i8*%aj,i64 -4
%al=bitcast i8*%ak to i32*
store i32 1342177288,i32*%al,align 4
store i8*%aj,i8**%g,align 8
%am=load i8*,i8**%c,align 8
%an=bitcast i8*%aj to i8**
store i8*%am,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%aj,i64 8
%ap=bitcast i8*%ao to i32*
store i32 1,i32*%ap,align 4
%aq=call i8*@sml_alloc(i32 inreg 28)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177304,i32*%as,align 4
%at=load i8*,i8**%g,align 8
%au=bitcast i8*%aq to i8**
store i8*%at,i8**%au,align 8
%av=getelementptr inbounds i8,i8*%aq,i64 8
%aw=bitcast i8*%av to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_67 to void(...)*),void(...)**%aw,align 8
%ax=getelementptr inbounds i8,i8*%aq,i64 16
%ay=bitcast i8*%ax to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_105 to void(...)*),void(...)**%ay,align 8
%az=getelementptr inbounds i8,i8*%aq,i64 24
%aA=bitcast i8*%az to i32*
store i32 -2147483647,i32*%aA,align 4
%aB=call i8*@sml_alloc(i32 inreg 12)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32 1342177288,i32*%aD,align 4
store i8*%aB,i8**%h,align 8
%aE=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aF=bitcast i8*%aB to i8**
store i8*%aE,i8**%aF,align 8
%aG=getelementptr inbounds i8,i8*%aB,i64 8
%aH=bitcast i8*%aG to i32*
store i32 1,i32*%aH,align 4
%aI=call i8*@sml_alloc(i32 inreg 28)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32 1342177304,i32*%aK,align 4
%aL=load i8*,i8**%h,align 8
%aM=bitcast i8*%aI to i8**
store i8*%aL,i8**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aI,i64 8
%aO=bitcast i8*%aN to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_75 to void(...)*),void(...)**%aO,align 8
%aP=getelementptr inbounds i8,i8*%aI,i64 16
%aQ=bitcast i8*%aP to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_108 to void(...)*),void(...)**%aQ,align 8
%aR=getelementptr inbounds i8,i8*%aI,i64 24
%aS=bitcast i8*%aR to i32*
store i32 -2147483647,i32*%aS,align 4
%aT=call i8*@sml_alloc(i32 inreg 12)#0
%aU=getelementptr inbounds i8,i8*%aT,i64 -4
%aV=bitcast i8*%aU to i32*
store i32 1342177288,i32*%aV,align 4
store i8*%aT,i8**%g,align 8
%aW=load i8*,i8**%b,align 8
%aX=bitcast i8*%aT to i8**
store i8*%aW,i8**%aX,align 8
%aY=getelementptr inbounds i8,i8*%aT,i64 8
%aZ=bitcast i8*%aY to i32*
store i32 1,i32*%aZ,align 4
%a0=call i8*@sml_alloc(i32 inreg 28)#0
%a1=getelementptr inbounds i8,i8*%a0,i64 -4
%a2=bitcast i8*%a1 to i32*
store i32 1342177304,i32*%a2,align 4
%a3=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%a4=bitcast i8*%a0 to i8**
store i8*%a3,i8**%a4,align 8
%a5=getelementptr inbounds i8,i8*%a0,i64 8
%a6=bitcast i8*%a5 to void(...)**
store void(...)*bitcast(void(i8*,i32)*@_SMLLN14UserErrorUtils20initializeErrorQueueE_76 to void(...)*),void(...)**%a6,align 8
%a7=getelementptr inbounds i8,i8*%a0,i64 16
%a8=bitcast i8*%a7 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils20initializeErrorQueueE_109 to void(...)*),void(...)**%a8,align 8
%a9=getelementptr inbounds i8,i8*%a0,i64 24
%ba=bitcast i8*%a9 to i32*
store i32 -2147483647,i32*%ba,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0),i8*inreg%a0)#0
%bb=call i8*@sml_alloc(i32 inreg 12)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177288,i32*%bd,align 4
store i8*%bb,i8**%g,align 8
%be=load i8*,i8**%b,align 8
%bf=bitcast i8*%bb to i8**
store i8*%be,i8**%bf,align 8
%bg=getelementptr inbounds i8,i8*%bb,i64 8
%bh=bitcast i8*%bg to i32*
store i32 1,i32*%bh,align 4
%bi=call i8*@sml_alloc(i32 inreg 28)#0
%bj=getelementptr inbounds i8,i8*%bi,i64 -4
%bk=bitcast i8*%bj to i32*
store i32 1342177304,i32*%bk,align 4
%bl=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bm=bitcast i8*%bi to i8**
store i8*%bl,i8**%bm,align 8
%bn=getelementptr inbounds i8,i8*%bi,i64 8
%bo=bitcast i8*%bn to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLN14UserErrorUtils20getErrorsAndWarningsE_78 to void(...)*),void(...)**%bo,align 8
%bp=getelementptr inbounds i8,i8*%bi,i64 16
%bq=bitcast i8*%bp to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils20getErrorsAndWarningsE_111 to void(...)*),void(...)**%bq,align 8
%br=getelementptr inbounds i8,i8*%bi,i64 24
%bs=bitcast i8*%br to i32*
store i32 -2147483647,i32*%bs,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 1),i8*inreg%bi)#0
%bt=call i8*@sml_alloc(i32 inreg 12)#0
%bu=getelementptr inbounds i8,i8*%bt,i64 -4
%bv=bitcast i8*%bu to i32*
store i32 1342177288,i32*%bv,align 4
store i8*%bt,i8**%g,align 8
%bw=load i8*,i8**%b,align 8
%bx=bitcast i8*%bt to i8**
store i8*%bw,i8**%bx,align 8
%by=getelementptr inbounds i8,i8*%bt,i64 8
%bz=bitcast i8*%by to i32*
store i32 1,i32*%bz,align 4
%bA=call i8*@sml_alloc(i32 inreg 28)#0
%bB=getelementptr inbounds i8,i8*%bA,i64 -4
%bC=bitcast i8*%bB to i32*
store i32 1342177304,i32*%bC,align 4
%bD=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bE=bitcast i8*%bA to i8**
store i8*%bD,i8**%bE,align 8
%bF=getelementptr inbounds i8,i8*%bA,i64 8
%bG=bitcast i8*%bF to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLN14UserErrorUtils9getErrorsE_80 to void(...)*),void(...)**%bG,align 8
%bH=getelementptr inbounds i8,i8*%bA,i64 16
%bI=bitcast i8*%bH to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils9getErrorsE_113 to void(...)*),void(...)**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bA,i64 24
%bK=bitcast i8*%bJ to i32*
store i32 -2147483647,i32*%bK,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 2),i8*inreg%bA)#0
%bL=call i8*@sml_alloc(i32 inreg 12)#0
%bM=getelementptr inbounds i8,i8*%bL,i64 -4
%bN=bitcast i8*%bM to i32*
store i32 1342177288,i32*%bN,align 4
store i8*%bL,i8**%g,align 8
%bO=load i8*,i8**%b,align 8
%bP=bitcast i8*%bL to i8**
store i8*%bO,i8**%bP,align 8
%bQ=getelementptr inbounds i8,i8*%bL,i64 8
%bR=bitcast i8*%bQ to i32*
store i32 1,i32*%bR,align 4
%bS=call i8*@sml_alloc(i32 inreg 28)#0
%bT=getelementptr inbounds i8,i8*%bS,i64 -4
%bU=bitcast i8*%bT to i32*
store i32 1342177304,i32*%bU,align 4
%bV=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bW=bitcast i8*%bS to i8**
store i8*%bV,i8**%bW,align 8
%bX=getelementptr inbounds i8,i8*%bS,i64 8
%bY=bitcast i8*%bX to void(...)**
store void(...)*bitcast(i32(i8*,i32)*@_SMLLN14UserErrorUtils10isAnyErrorE_82 to void(...)*),void(...)**%bY,align 8
%bZ=getelementptr inbounds i8,i8*%bS,i64 16
%b0=bitcast i8*%bZ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils10isAnyErrorE_115 to void(...)*),void(...)**%b0,align 8
%b1=getelementptr inbounds i8,i8*%bS,i64 24
%b2=bitcast i8*%b1 to i32*
store i32 -2147483647,i32*%b2,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 3),i8*inreg%bS)#0
%b3=call i8*@sml_alloc(i32 inreg 12)#0
%b4=getelementptr inbounds i8,i8*%b3,i64 -4
%b5=bitcast i8*%b4 to i32*
store i32 1342177288,i32*%b5,align 4
store i8*%b3,i8**%g,align 8
%b6=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%b7=bitcast i8*%b3 to i8**
store i8*%b6,i8**%b7,align 8
%b8=getelementptr inbounds i8,i8*%b3,i64 8
%b9=bitcast i8*%b8 to i32*
store i32 1,i32*%b9,align 4
%ca=call i8*@sml_alloc(i32 inreg 28)#0
%cb=getelementptr inbounds i8,i8*%ca,i64 -4
%cc=bitcast i8*%cb to i32*
store i32 1342177304,i32*%cc,align 4
%cd=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ce=bitcast i8*%ca to i8**
store i8*%cd,i8**%ce,align 8
%cf=getelementptr inbounds i8,i8*%ca,i64 8
%cg=bitcast i8*%cf to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLN14UserErrorUtils11getWarningsE_84 to void(...)*),void(...)**%cg,align 8
%ch=getelementptr inbounds i8,i8*%ca,i64 16
%ci=bitcast i8*%ch to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils11getWarningsE_117 to void(...)*),void(...)**%ci,align 8
%cj=getelementptr inbounds i8,i8*%ca,i64 24
%ck=bitcast i8*%cj to i32*
store i32 -2147483647,i32*%ck,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 4),i8*inreg%ca)#0
%cl=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 5),i8*inreg%cl)#0
%cm=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 6),i8*inreg%cm)#0
%cn=call i8*@sml_alloc(i32 inreg 12)#0
%co=getelementptr inbounds i8,i8*%cn,i64 -4
%cp=bitcast i8*%co to i32*
store i32 1342177288,i32*%cp,align 4
store i8*%cn,i8**%b,align 8
%cq=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cr=bitcast i8*%cn to i8**
store i8*%cq,i8**%cr,align 8
%cs=getelementptr inbounds i8,i8*%cn,i64 8
%ct=bitcast i8*%cs to i32*
store i32 1,i32*%ct,align 4
%cu=call i8*@sml_alloc(i32 inreg 28)#0
%cv=getelementptr inbounds i8,i8*%cu,i64 -4
%cw=bitcast i8*%cv to i32*
store i32 1342177304,i32*%cw,align 4
%cx=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cy=bitcast i8*%cu to i8**
store i8*%cx,i8**%cy,align 8
%cz=getelementptr inbounds i8,i8*%cu,i64 8
%cA=bitcast i8*%cz to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_89 to void(...)*),void(...)**%cA,align 8
%cB=getelementptr inbounds i8,i8*%cu,i64 16
%cC=bitcast i8*%cB to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_121 to void(...)*),void(...)**%cC,align 8
%cD=getelementptr inbounds i8,i8*%cu,i64 24
%cE=bitcast i8*%cD to i32*
store i32 -2147483647,i32*%cE,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 7),i8*inreg%cu)#0
%cF=call i8*@sml_alloc(i32 inreg 12)#0
%cG=getelementptr inbounds i8,i8*%cF,i64 -4
%cH=bitcast i8*%cG to i32*
store i32 1342177288,i32*%cH,align 4
store i8*%cF,i8**%b,align 8
%cI=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cJ=bitcast i8*%cF to i8**
store i8*%cI,i8**%cJ,align 8
%cK=getelementptr inbounds i8,i8*%cF,i64 8
%cL=bitcast i8*%cK to i32*
store i32 1,i32*%cL,align 4
%cM=call i8*@sml_alloc(i32 inreg 28)#0
%cN=getelementptr inbounds i8,i8*%cM,i64 -4
%cO=bitcast i8*%cN to i32*
store i32 1342177304,i32*%cO,align 4
%cP=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cQ=bitcast i8*%cM to i8**
store i8*%cP,i8**%cQ,align 8
%cR=getelementptr inbounds i8,i8*%cM,i64 8
%cS=bitcast i8*%cR to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_92 to void(...)*),void(...)**%cS,align 8
%cT=getelementptr inbounds i8,i8*%cM,i64 16
%cU=bitcast i8*%cT to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_123 to void(...)*),void(...)**%cU,align 8
%cV=getelementptr inbounds i8,i8*%cM,i64 24
%cW=bitcast i8*%cV to i32*
store i32 -2147483647,i32*%cW,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 8),i8*inreg%cM)#0
%cX=call i8*@sml_alloc(i32 inreg 12)#0
%cY=getelementptr inbounds i8,i8*%cX,i64 -4
%cZ=bitcast i8*%cY to i32*
store i32 1342177288,i32*%cZ,align 4
store i8*%cX,i8**%b,align 8
%c0=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%c1=bitcast i8*%cX to i8**
store i8*%c0,i8**%c1,align 8
%c2=getelementptr inbounds i8,i8*%cX,i64 8
%c3=bitcast i8*%c2 to i32*
store i32 1,i32*%c3,align 4
%c4=call i8*@sml_alloc(i32 inreg 28)#0
%c5=getelementptr inbounds i8,i8*%c4,i64 -4
%c6=bitcast i8*%c5 to i32*
store i32 1342177304,i32*%c6,align 4
%c7=load i8*,i8**%b,align 8
%c8=bitcast i8*%c4 to i8**
store i8*%c7,i8**%c8,align 8
%c9=getelementptr inbounds i8,i8*%c4,i64 8
%da=bitcast i8*%c9 to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_95 to void(...)*),void(...)**%da,align 8
%db=getelementptr inbounds i8,i8*%c4,i64 16
%dc=bitcast i8*%db to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_125 to void(...)*),void(...)**%dc,align 8
%dd=getelementptr inbounds i8,i8*%c4,i64 24
%de=bitcast i8*%dd to i32*
store i32 -2147483647,i32*%de,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 9),i8*inreg%c4)#0
call void@sml_end()#0
ret void
df:
%dg=landingpad{i8*,i8*}
cleanup
%dh=extractvalue{i8*,i8*}%dg,1
call void@sml_save_exn(i8*inreg%dh)#0
call void@sml_end()#0
resume{i8*,i8*}%dg
}
define internal fastcc i8*@_SMLL18collectDuplication_48(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d)#1 gc"smlsharp"{
m:
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
store i8*%a,i8**%h,align 8
store i8*%b,i8**%j,align 8
store i8*%c,i8**%i,align 8
br label%k
k:
%l=phi i8*[%d,%m],[%ay,%ax]
store i8*%l,i8**%e,align 8
%n=load atomic i32,i32*@sml_check_flag unordered,align 4
%o=icmp eq i32%n,0
br i1%o,label%r,label%p
p:
call void@sml_check(i32 inreg%n)
%q=load i8*,i8**%e,align 8
br label%r
r:
%s=phi i8*[%q,%p],[%l,%k]
store i8*%s,i8**%f,align 8
%t=load i8*,i8**%h,align 8
%u=getelementptr inbounds i8,i8*%t,i64 12
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=add i32%w,-1
%y=sub i32 0,%w
%z=and i32%x,%y
%A=add i32%w,7
%B=add i32%A,%z
%C=and i32%B,-8
%D=icmp eq i8*%s,null
br i1%D,label%E,label%N
E:
store i8*null,i8**%f,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%j,align 8
%F=call fastcc i8*@_SMLFN9SymbolEnv9listItemsE(i32 inreg 1,i32 inreg 8)
%G=getelementptr inbounds i8,i8*%F,i64 16
%H=bitcast i8*%G to i8*(i8*,i8*)**
%I=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%H,align 8
%J=bitcast i8*%F to i8**
%K=load i8*,i8**%J,align 8
%L=load i8*,i8**%i,align 8
%M=call fastcc i8*%I(i8*inreg%K,i8*inreg%L)
ret i8*%M
N:
%O=bitcast i8*%t to i8**
%P=load i8*,i8**%O,align 8
%Q=getelementptr inbounds i8,i8*%P,i64 16
%R=bitcast i8*%Q to i8*(i8*,i8*)**
%S=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%R,align 8
%T=bitcast i8*%P to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%e,align 8
%V=getelementptr inbounds i8,i8*%t,i64 8
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=icmp eq i32%X,0
br i1%Y,label%ae,label%Z
Z:
%aa=sext i32%z to i64
%ab=getelementptr inbounds i8,i8*%s,i64%aa
%ac=bitcast i8*%ab to i8**
%ad=load i8*,i8**%ac,align 8
br label%am
ae:
%af=call i8*@sml_alloc(i32 inreg%w)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32%w,i32*%ah,align 4
%ai=load i8*,i8**%f,align 8
%aj=sext i32%z to i64
%ak=getelementptr inbounds i8,i8*%ai,i64%aj
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%af,i8*%ak,i32%w,i1 false)
%al=load i8*,i8**%e,align 8
br label%am
am:
%an=phi i8*[%U,%Z],[%al,%ae]
%ao=phi i8*[%ad,%Z],[%af,%ae]
store i8*null,i8**%e,align 8
%ap=call fastcc i8*%S(i8*inreg%an,i8*inreg%ao)
%aq=icmp eq i8*%ap,null
br i1%aq,label%ar,label%az
ar:
%as=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%at=sext i32%C to i64
%au=getelementptr inbounds i8,i8*%as,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%ax
ax:
%ay=phi i8*[%bI,%bi],[%aw,%ar]
br label%k
az:
%aA=bitcast i8*%ap to i8**
%aB=load i8*,i8**%aA,align 8
store i8*%aB,i8**%g,align 8
%aC=call fastcc i8*@_SMLFN9SymbolEnv4findE(i32 inreg 1,i32 inreg 8)
%aD=getelementptr inbounds i8,i8*%aC,i64 16
%aE=bitcast i8*%aD to i8*(i8*,i8*)**
%aF=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aE,align 8
%aG=bitcast i8*%aC to i8**
%aH=load i8*,i8**%aG,align 8
store i8*%aH,i8**%e,align 8
%aI=call i8*@sml_alloc(i32 inreg 20)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32 1342177296,i32*%aK,align 4
%aL=load i8*,i8**%j,align 8
%aM=bitcast i8*%aI to i8**
store i8*%aL,i8**%aM,align 8
%aN=load i8*,i8**%g,align 8
%aO=getelementptr inbounds i8,i8*%aI,i64 8
%aP=bitcast i8*%aO to i8**
store i8*%aN,i8**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aI,i64 16
%aR=bitcast i8*%aQ to i32*
store i32 3,i32*%aR,align 4
%aS=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aT=call fastcc i8*%aF(i8*inreg%aS,i8*inreg%aI)
%aU=icmp eq i8*%aT,null
br i1%aU,label%aV,label%aX
aV:
%aW=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
br label%bi
aX:
%aY=call fastcc i8*@_SMLFN9SymbolEnv6insertE(i32 inreg 1,i32 inreg 8)
%aZ=getelementptr inbounds i8,i8*%aY,i64 16
%a0=bitcast i8*%aZ to i8*(i8*,i8*)**
%a1=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a0,align 8
%a2=bitcast i8*%aY to i8**
%a3=load i8*,i8**%a2,align 8
store i8*%a3,i8**%e,align 8
%a4=call i8*@sml_alloc(i32 inreg 28)#0
%a5=getelementptr inbounds i8,i8*%a4,i64 -4
%a6=bitcast i8*%a5 to i32*
store i32 1342177304,i32*%a6,align 4
%a7=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%a8=bitcast i8*%a4 to i8**
store i8*%a7,i8**%a8,align 8
%a9=load i8*,i8**%g,align 8
%ba=getelementptr inbounds i8,i8*%a4,i64 8
%bb=bitcast i8*%ba to i8**
store i8*%a9,i8**%bb,align 8
%bc=getelementptr inbounds i8,i8*%a4,i64 16
%bd=bitcast i8*%bc to i8**
store i8*%a9,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%a4,i64 24
%bf=bitcast i8*%be to i32*
store i32 7,i32*%bf,align 4
%bg=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bh=call fastcc i8*%a1(i8*inreg%bg,i8*inreg%a4)
br label%bi
bi:
%bj=phi i8*[%bh,%aX],[%aW,%aV]
store i8*%bj,i8**%e,align 8
%bk=call fastcc i8*@_SMLFN9SymbolEnv6insertE(i32 inreg 1,i32 inreg 8)
%bl=getelementptr inbounds i8,i8*%bk,i64 16
%bm=bitcast i8*%bl to i8*(i8*,i8*)**
%bn=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bm,align 8
%bo=bitcast i8*%bk to i8**
%bp=load i8*,i8**%bo,align 8
store i8*%bp,i8**%i,align 8
%bq=call i8*@sml_alloc(i32 inreg 28)#0
%br=getelementptr inbounds i8,i8*%bq,i64 -4
%bs=bitcast i8*%br to i32*
store i32 1342177304,i32*%bs,align 4
%bt=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bu=bitcast i8*%bq to i8**
store i8*%bt,i8**%bu,align 8
%bv=load i8*,i8**%g,align 8
%bw=getelementptr inbounds i8,i8*%bq,i64 8
%bx=bitcast i8*%bw to i8**
store i8*%bv,i8**%bx,align 8
store i8*null,i8**%g,align 8
%by=getelementptr inbounds i8,i8*%bq,i64 16
%bz=bitcast i8*%by to i8**
store i8*%bv,i8**%bz,align 8
%bA=getelementptr inbounds i8,i8*%bq,i64 24
%bB=bitcast i8*%bA to i32*
store i32 7,i32*%bB,align 4
%bC=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bD=call fastcc i8*%bn(i8*inreg%bC,i8*inreg%bq)
%bE=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bF=sext i32%C to i64
%bG=getelementptr inbounds i8,i8*%bE,i64%bF
%bH=bitcast i8*%bG to i8**
%bI=load i8*,i8**%bH,align 8
%bJ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
store i8*%bD,i8**%j,align 8
store i8*%bJ,i8**%i,align 8
br label%ax
}
define internal fastcc void@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_49(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br label%o
k:
call void@sml_check(i32 inreg%g)
%l=bitcast i8**%e to i8***
%m=load i8**,i8***%l,align 8
%n=load i8*,i8**%c,align 8
br label%o
o:
%p=phi i8*[%n,%k],[%b,%i]
%q=phi i8**[%m,%k],[%j,%i]
%r=load i8*,i8**%q,align 8
%s=getelementptr inbounds i8,i8*%r,i64 16
%t=bitcast i8*%s to i8*(i8*,i8*)**
%u=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%t,align 8
%v=bitcast i8*%r to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%f,align 8
%x=call fastcc i8*@_SMLFN6Symbol11symbolToLocE(i8*inreg%p)
store i8*%x,i8**%d,align 8
%y=load i8*,i8**%e,align 8
%z=getelementptr inbounds i8,i8*%y,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
store i8*null,i8**%e,align 8
%F=bitcast i8*%B to i8**
%G=load i8*,i8**%F,align 8
%H=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%I=call fastcc i8*%E(i8*inreg%G,i8*inreg%H)
store i8*%I,i8**%c,align 8
%J=call i8*@sml_alloc(i32 inreg 20)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177296,i32*%L,align 4
%M=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%N=bitcast i8*%J to i8**
store i8*%M,i8**%N,align 8
%O=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%P=getelementptr inbounds i8,i8*%J,i64 8
%Q=bitcast i8*%P to i8**
store i8*%O,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%J,i64 16
%S=bitcast i8*%R to i32*
store i32 3,i32*%S,align 4
%T=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%U=call fastcc i8*%u(i8*inreg%T,i8*inreg%J)
ret void
}
define internal fastcc void@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_50(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
o:
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
br i1%i,label%m,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%c,align 8
%l=load i8*,i8**%e,align 8
br label%m
m:
%n=phi i8*[%l,%j],[%a,%o]
%p=phi i8*[%k,%j],[%b,%o]
store i8*%p,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%n,i64 8
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%c,align 8
%t=getelementptr inbounds i8,i8*%n,i64 24
%u=bitcast i8*%t to i32*
%v=load i32,i32*%u,align 4
%w=getelementptr inbounds i8,i8*%n,i64 28
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
%z=call i8*@sml_alloc(i32 inreg 20)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177296,i32*%B,align 4
store i8*%z,i8**%f,align 8
%C=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i32*
store i32%v,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%z,i64 12
%H=bitcast i8*%G to i32*
store i32%y,i32*%H,align 4
%I=getelementptr inbounds i8,i8*%z,i64 16
%J=bitcast i8*%I to i32*
store i32 1,i32*%J,align 4
%K=call i8*@sml_alloc(i32 inreg 28)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177304,i32*%M,align 4
%N=load i8*,i8**%f,align 8
%O=bitcast i8*%K to i8**
store i8*%N,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%K,i64 8
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLL18collectDuplication_48 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%K,i64 16
%S=bitcast i8*%R to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLL18collectDuplication_48 to void(...)*),void(...)**%S,align 8
%T=getelementptr inbounds i8,i8*%K,i64 24
%U=bitcast i8*%T to i32*
store i32 -2147483647,i32*%U,align 4
%V=call fastcc i8*@_SMLFN9SymbolEnv5emptyE(i32 inreg 1,i32 inreg 8)
store i8*%V,i8**%c,align 8
%W=call fastcc i8*@_SMLFN9SymbolEnv5emptyE(i32 inreg 1,i32 inreg 8)
%X=load i8*,i8**%e,align 8
%Y=getelementptr inbounds i8,i8*%X,i64 16
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
%ab=load i8*,i8**%f,align 8
%ac=load i8*,i8**%c,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%c,align 8
%ad=call fastcc i8*@_SMLL18collectDuplication_48(i8*inreg%ab,i8*inreg%ac,i8*inreg%W,i8*inreg%aa)
store i8*%ad,i8**%c,align 8
%ae=call fastcc i8*@_SMLFN4List3appE(i32 inreg 1,i32 inreg 8)
%af=getelementptr inbounds i8,i8*%ae,i64 16
%ag=bitcast i8*%af to i8*(i8*,i8*)**
%ah=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ag,align 8
%ai=bitcast i8*%ae to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%f,align 8
%ak=bitcast i8**%e to i8***
%al=load i8**,i8***%ak,align 8
%am=load i8*,i8**%al,align 8
store i8*%am,i8**%e,align 8
%an=call i8*@sml_alloc(i32 inreg 20)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177296,i32*%ap,align 4
store i8*%an,i8**%g,align 8
%aq=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ar=bitcast i8*%an to i8**
store i8*%aq,i8**%ar,align 8
%as=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%at=getelementptr inbounds i8,i8*%an,i64 8
%au=bitcast i8*%at to i8**
store i8*%as,i8**%au,align 8
%av=getelementptr inbounds i8,i8*%an,i64 16
%aw=bitcast i8*%av to i32*
store i32 3,i32*%aw,align 4
%ax=call i8*@sml_alloc(i32 inreg 28)#0
%ay=getelementptr inbounds i8,i8*%ax,i64 -4
%az=bitcast i8*%ay to i32*
store i32 1342177304,i32*%az,align 4
%aA=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aB=bitcast i8*%ax to i8**
store i8*%aA,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%ax,i64 8
%aD=bitcast i8*%aC to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_49 to void(...)*),void(...)**%aD,align 8
%aE=getelementptr inbounds i8,i8*%ax,i64 16
%aF=bitcast i8*%aE to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_97 to void(...)*),void(...)**%aF,align 8
%aG=getelementptr inbounds i8,i8*%ax,i64 24
%aH=bitcast i8*%aG to i32*
store i32 -2147483647,i32*%aH,align 4
%aI=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aJ=call fastcc i8*%ah(i8*inreg%aI,i8*inreg%ax)
%aK=getelementptr inbounds i8,i8*%aJ,i64 16
%aL=bitcast i8*%aK to i8*(i8*,i8*)**
%aM=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aL,align 8
%aN=bitcast i8*%aJ to i8**
%aO=load i8*,i8**%aN,align 8
%aP=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aQ=call fastcc i8*%aM(i8*inreg%aO,i8*inreg%aP)
ret void
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_51(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%b,i8**%c,align 8
%g=bitcast i8*%a to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%d,align 8
%i=getelementptr inbounds i8,i8*%a,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%e,align 8
%l=getelementptr inbounds i8,i8*%a,i64 16
%m=bitcast i8*%l to i32*
%n=load i32,i32*%m,align 4
%o=getelementptr inbounds i8,i8*%a,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=call i8*@sml_alloc(i32 inreg 36)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177312,i32*%t,align 4
store i8*%r,i8**%f,align 8
%u=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%x=getelementptr inbounds i8,i8*%r,i64 8
%y=bitcast i8*%x to i8**
store i8*%w,i8**%y,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=getelementptr inbounds i8,i8*%r,i64 16
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%r,i64 24
%D=bitcast i8*%C to i32*
store i32%n,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%r,i64 28
%F=bitcast i8*%E to i32*
store i32%q,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%r,i64 32
%H=bitcast i8*%G to i32*
store i32 7,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 28)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177304,i32*%K,align 4
%L=load i8*,i8**%f,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_50 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_98 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_52(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
%h=getelementptr inbounds i8,i8*%a,i64 8
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=getelementptr inbounds i8,i8*%a,i64 12
%l=bitcast i8*%k to i32*
%m=load i32,i32*%l,align 4
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
store i8*%n,i8**%e,align 8
%q=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%t=getelementptr inbounds i8,i8*%n,i64 8
%u=bitcast i8*%t to i8**
store i8*%s,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%n,i64 16
%w=bitcast i8*%v to i32*
store i32%j,i32*%w,align 4
%x=getelementptr inbounds i8,i8*%n,i64 20
%y=bitcast i8*%x to i32*
store i32%m,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%n,i64 24
%A=bitcast i8*%z to i32*
store i32 3,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
%E=load i8*,i8**%e,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_51 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_51 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_53(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_52 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_52 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_56(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%e,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%h,label%j
h:
%i=bitcast i8*%a to i8**
br label%n
j:
call void@sml_check(i32 inreg%f)
%k=bitcast i8**%d to i8***
%l=load i8**,i8***%k,align 8
%m=load i8*,i8**%e,align 8
br label%n
n:
%o=phi i8*[%m,%j],[%b,%h]
%p=phi i8**[%l,%j],[%i,%h]
%q=load i8*,i8**%p,align 8
%r=getelementptr inbounds i8,i8*%q,i64 16
%s=bitcast i8*%r to i8*(i8*,i8*)**
%t=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%s,align 8
store i8*null,i8**%d,align 8
%u=bitcast i8**%p to i8***
%v=load i8**,i8***%u,align 8
%w=load i8*,i8**%v,align 8
store i8*null,i8**%e,align 8
%x=call fastcc i8*%t(i8*inreg%w,i8*inreg%o)
%y=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%y)
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%x,i8**%c,align 8
%z=call i8*@sml_alloc(i32 inreg 12)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177288,i32*%B,align 4
%C=load i8*,i8**%c,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%y)
ret i8*%z
}
define internal fastcc void@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_57(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%d,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
%o=getelementptr inbounds i8,i8*%m,i64 16
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
%r=getelementptr inbounds i8,i8*%m,i64 24
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=getelementptr inbounds i8,i8*%m,i64 28
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=call fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_53(i8*inreg%q,i32 inreg%t,i32 inreg%w)
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%f,align 8
%D=bitcast i8**%d to i8***
%E=load i8**,i8***%D,align 8
%F=load i8*,i8**%E,align 8
store i8*%F,i8**%e,align 8
%G=call i8*@sml_alloc(i32 inreg 12)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177288,i32*%I,align 4
store i8*%G,i8**%g,align 8
%J=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i32*
store i32 1,i32*%M,align 4
%N=call i8*@sml_alloc(i32 inreg 28)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177304,i32*%P,align 4
%Q=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%N,i64 8
%T=bitcast i8*%S to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_56 to void(...)*),void(...)**%T,align 8
%U=getelementptr inbounds i8,i8*%N,i64 16
%V=bitcast i8*%U to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_56 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%N,i64 24
%X=bitcast i8*%W to i32*
store i32 1,i32*%X,align 4
%Y=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%Z=call fastcc i8*%A(i8*inreg%Y,i8*inreg%N)
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8*(i8*,i8*)**
%ac=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ab,align 8
%ad=bitcast i8*%Z to i8**
%ae=load i8*,i8**%ad,align 8
%af=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ag=getelementptr inbounds i8,i8*%af,i64 8
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
%aj=call fastcc i8*%ac(i8*inreg%ae,i8*inreg%ai)
%ak=getelementptr inbounds i8,i8*%aj,i64 16
%al=bitcast i8*%ak to i8*(i8*,i8*)**
%am=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%al,align 8
%an=bitcast i8*%aj to i8**
%ao=load i8*,i8**%an,align 8
%ap=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aq=call fastcc i8*%am(i8*inreg%ao,i8*inreg%ap)
ret void
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_58(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%b,i8**%c,align 8
%g=bitcast i8*%a to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%d,align 8
%i=getelementptr inbounds i8,i8*%a,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%e,align 8
%l=getelementptr inbounds i8,i8*%a,i64 16
%m=bitcast i8*%l to i32*
%n=load i32,i32*%m,align 4
%o=getelementptr inbounds i8,i8*%a,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=call i8*@sml_alloc(i32 inreg 36)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177312,i32*%t,align 4
store i8*%r,i8**%f,align 8
%u=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%x=getelementptr inbounds i8,i8*%r,i64 8
%y=bitcast i8*%x to i8**
store i8*%w,i8**%y,align 8
%z=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%A=getelementptr inbounds i8,i8*%r,i64 16
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%r,i64 24
%D=bitcast i8*%C to i32*
store i32%n,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%r,i64 28
%F=bitcast i8*%E to i32*
store i32%q,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%r,i64 32
%H=bitcast i8*%G to i32*
store i32 7,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 28)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177304,i32*%K,align 4
%L=load i8*,i8**%f,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_57 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_101 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_59(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
%h=getelementptr inbounds i8,i8*%a,i64 8
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=getelementptr inbounds i8,i8*%a,i64 12
%l=bitcast i8*%k to i32*
%m=load i32,i32*%l,align 4
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
store i8*%n,i8**%e,align 8
%q=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%t=getelementptr inbounds i8,i8*%n,i64 8
%u=bitcast i8*%t to i8**
store i8*%s,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%n,i64 16
%w=bitcast i8*%v to i32*
store i32%j,i32*%w,align 4
%x=getelementptr inbounds i8,i8*%n,i64 20
%y=bitcast i8*%x to i32*
store i32%m,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%n,i64 24
%A=bitcast i8*%z to i32*
store i32 3,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
%E=load i8*,i8**%e,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_58 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_58 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_60(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_59 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_59 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define internal fastcc i8*@_SMLL18collectDuplication_61(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d)#1 gc"smlsharp"{
m:
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
store i8*%a,i8**%h,align 8
store i8*%b,i8**%j,align 8
store i8*%c,i8**%i,align 8
br label%k
k:
%l=phi i8*[%d,%m],[%ay,%ax]
store i8*%l,i8**%e,align 8
%n=load atomic i32,i32*@sml_check_flag unordered,align 4
%o=icmp eq i32%n,0
br i1%o,label%r,label%p
p:
call void@sml_check(i32 inreg%n)
%q=load i8*,i8**%e,align 8
br label%r
r:
%s=phi i8*[%q,%p],[%l,%k]
store i8*%s,i8**%f,align 8
%t=load i8*,i8**%h,align 8
%u=getelementptr inbounds i8,i8*%t,i64 12
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=add i32%w,-1
%y=sub i32 0,%w
%z=and i32%x,%y
%A=add i32%w,7
%B=add i32%A,%z
%C=and i32%B,-8
%D=icmp eq i8*%s,null
br i1%D,label%E,label%N
E:
store i8*null,i8**%f,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%j,align 8
%F=call fastcc i8*@_SMLFN11RecordLabel3Map9listItemsE(i32 inreg 1,i32 inreg 8)
%G=getelementptr inbounds i8,i8*%F,i64 16
%H=bitcast i8*%G to i8*(i8*,i8*)**
%I=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%H,align 8
%J=bitcast i8*%F to i8**
%K=load i8*,i8**%J,align 8
%L=load i8*,i8**%i,align 8
%M=call fastcc i8*%I(i8*inreg%K,i8*inreg%L)
ret i8*%M
N:
%O=bitcast i8*%t to i8**
%P=load i8*,i8**%O,align 8
%Q=getelementptr inbounds i8,i8*%P,i64 16
%R=bitcast i8*%Q to i8*(i8*,i8*)**
%S=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%R,align 8
%T=bitcast i8*%P to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%e,align 8
%V=getelementptr inbounds i8,i8*%t,i64 8
%W=bitcast i8*%V to i32*
%X=load i32,i32*%W,align 4
%Y=icmp eq i32%X,0
br i1%Y,label%ae,label%Z
Z:
%aa=sext i32%z to i64
%ab=getelementptr inbounds i8,i8*%s,i64%aa
%ac=bitcast i8*%ab to i8**
%ad=load i8*,i8**%ac,align 8
br label%am
ae:
%af=call i8*@sml_alloc(i32 inreg%w)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32%w,i32*%ah,align 4
%ai=load i8*,i8**%f,align 8
%aj=sext i32%z to i64
%ak=getelementptr inbounds i8,i8*%ai,i64%aj
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%af,i8*%ak,i32%w,i1 false)
%al=load i8*,i8**%e,align 8
br label%am
am:
%an=phi i8*[%U,%Z],[%al,%ae]
%ao=phi i8*[%ad,%Z],[%af,%ae]
store i8*null,i8**%e,align 8
%ap=call fastcc i8*%S(i8*inreg%an,i8*inreg%ao)
%aq=icmp eq i8*%ap,null
br i1%aq,label%ar,label%az
ar:
%as=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%at=sext i32%C to i64
%au=getelementptr inbounds i8,i8*%as,i64%at
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
br label%ax
ax:
%ay=phi i8*[%bI,%bi],[%aw,%ar]
br label%k
az:
%aA=bitcast i8*%ap to i8**
%aB=load i8*,i8**%aA,align 8
store i8*%aB,i8**%g,align 8
%aC=call fastcc i8*@_SMLFN11RecordLabel3Map4findE(i32 inreg 1,i32 inreg 8)
%aD=getelementptr inbounds i8,i8*%aC,i64 16
%aE=bitcast i8*%aD to i8*(i8*,i8*)**
%aF=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aE,align 8
%aG=bitcast i8*%aC to i8**
%aH=load i8*,i8**%aG,align 8
store i8*%aH,i8**%e,align 8
%aI=call i8*@sml_alloc(i32 inreg 20)#0
%aJ=getelementptr inbounds i8,i8*%aI,i64 -4
%aK=bitcast i8*%aJ to i32*
store i32 1342177296,i32*%aK,align 4
%aL=load i8*,i8**%j,align 8
%aM=bitcast i8*%aI to i8**
store i8*%aL,i8**%aM,align 8
%aN=load i8*,i8**%g,align 8
%aO=getelementptr inbounds i8,i8*%aI,i64 8
%aP=bitcast i8*%aO to i8**
store i8*%aN,i8**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aI,i64 16
%aR=bitcast i8*%aQ to i32*
store i32 3,i32*%aR,align 4
%aS=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aT=call fastcc i8*%aF(i8*inreg%aS,i8*inreg%aI)
%aU=icmp eq i8*%aT,null
br i1%aU,label%aV,label%aX
aV:
%aW=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
br label%bi
aX:
%aY=call fastcc i8*@_SMLFN11RecordLabel3Map6insertE(i32 inreg 1,i32 inreg 8)
%aZ=getelementptr inbounds i8,i8*%aY,i64 16
%a0=bitcast i8*%aZ to i8*(i8*,i8*)**
%a1=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a0,align 8
%a2=bitcast i8*%aY to i8**
%a3=load i8*,i8**%a2,align 8
store i8*%a3,i8**%e,align 8
%a4=call i8*@sml_alloc(i32 inreg 28)#0
%a5=getelementptr inbounds i8,i8*%a4,i64 -4
%a6=bitcast i8*%a5 to i32*
store i32 1342177304,i32*%a6,align 4
%a7=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%a8=bitcast i8*%a4 to i8**
store i8*%a7,i8**%a8,align 8
%a9=load i8*,i8**%g,align 8
%ba=getelementptr inbounds i8,i8*%a4,i64 8
%bb=bitcast i8*%ba to i8**
store i8*%a9,i8**%bb,align 8
%bc=getelementptr inbounds i8,i8*%a4,i64 16
%bd=bitcast i8*%bc to i8**
store i8*%a9,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%a4,i64 24
%bf=bitcast i8*%be to i32*
store i32 7,i32*%bf,align 4
%bg=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bh=call fastcc i8*%a1(i8*inreg%bg,i8*inreg%a4)
br label%bi
bi:
%bj=phi i8*[%bh,%aX],[%aW,%aV]
store i8*%bj,i8**%e,align 8
%bk=call fastcc i8*@_SMLFN11RecordLabel3Map6insertE(i32 inreg 1,i32 inreg 8)
%bl=getelementptr inbounds i8,i8*%bk,i64 16
%bm=bitcast i8*%bl to i8*(i8*,i8*)**
%bn=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bm,align 8
%bo=bitcast i8*%bk to i8**
%bp=load i8*,i8**%bo,align 8
store i8*%bp,i8**%i,align 8
%bq=call i8*@sml_alloc(i32 inreg 28)#0
%br=getelementptr inbounds i8,i8*%bq,i64 -4
%bs=bitcast i8*%br to i32*
store i32 1342177304,i32*%bs,align 4
%bt=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bu=bitcast i8*%bq to i8**
store i8*%bt,i8**%bu,align 8
%bv=load i8*,i8**%g,align 8
%bw=getelementptr inbounds i8,i8*%bq,i64 8
%bx=bitcast i8*%bw to i8**
store i8*%bv,i8**%bx,align 8
store i8*null,i8**%g,align 8
%by=getelementptr inbounds i8,i8*%bq,i64 16
%bz=bitcast i8*%by to i8**
store i8*%bv,i8**%bz,align 8
%bA=getelementptr inbounds i8,i8*%bq,i64 24
%bB=bitcast i8*%bA to i32*
store i32 7,i32*%bB,align 4
%bC=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bD=call fastcc i8*%bn(i8*inreg%bC,i8*inreg%bq)
%bE=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bF=sext i32%C to i64
%bG=getelementptr inbounds i8,i8*%bE,i64%bF
%bH=bitcast i8*%bG to i8**
%bI=load i8*,i8**%bH,align 8
%bJ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
store i8*%bD,i8**%j,align 8
store i8*%bJ,i8**%i,align 8
br label%ax
}
define internal fastcc void@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_62(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br label%o
j:
call void@sml_check(i32 inreg%f)
%k=load i8*,i8**%c,align 8
%l=bitcast i8**%d to i8***
%m=load i8**,i8***%l,align 8
%n=bitcast i8**%m to i8*
br label%o
o:
%p=phi i8*[%n,%j],[%a,%h]
%q=phi i8**[%m,%j],[%i,%h]
%r=phi i8*[%k,%j],[%b,%h]
store i8*null,i8**%c,align 8
%s=load i8*,i8**%q,align 8
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%e,align 8
%y=getelementptr inbounds i8,i8*%p,i64 16
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
%B=getelementptr inbounds i8,i8*%A,i64 16
%C=bitcast i8*%B to i8*(i8*,i8*)**
%D=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%C,align 8
%E=bitcast i8*%A to i8**
%F=load i8*,i8**%E,align 8
%G=call fastcc i8*%D(i8*inreg%F,i8*inreg%r)
store i8*%G,i8**%c,align 8
%H=load i8*,i8**%d,align 8
%I=getelementptr inbounds i8,i8*%H,i64 8
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
store i8*%K,i8**%d,align 8
%L=call i8*@sml_alloc(i32 inreg 20)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
%O=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%R=getelementptr inbounds i8,i8*%L,i64 8
%S=bitcast i8*%R to i8**
store i8*%Q,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%L,i64 16
%U=bitcast i8*%T to i32*
store i32 3,i32*%U,align 4
%V=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%W=call fastcc i8*%v(i8*inreg%V,i8*inreg%L)
ret void
}
define internal fastcc void@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_63(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
p:
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
store i8*%a,i8**%e,align 8
store i8*%b,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%n,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%c,align 8
%m=load i8*,i8**%e,align 8
br label%n
n:
%o=phi i8*[%m,%k],[%a,%p]
%q=phi i8*[%l,%k],[%b,%p]
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%c,align 8
%u=getelementptr inbounds i8,i8*%o,i64 32
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=getelementptr inbounds i8,i8*%o,i64 36
%y=bitcast i8*%x to i32*
%z=load i32,i32*%y,align 4
%A=call i8*@sml_alloc(i32 inreg 20)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177296,i32*%C,align 4
store i8*%A,i8**%f,align 8
%D=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to i32*
store i32%w,i32*%G,align 4
%H=getelementptr inbounds i8,i8*%A,i64 12
%I=bitcast i8*%H to i32*
store i32%z,i32*%I,align 4
%J=getelementptr inbounds i8,i8*%A,i64 16
%K=bitcast i8*%J to i32*
store i32 1,i32*%K,align 4
%L=call i8*@sml_alloc(i32 inreg 28)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177304,i32*%N,align 4
%O=load i8*,i8**%f,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLL18collectDuplication_61 to void(...)*),void(...)**%R,align 8
%S=getelementptr inbounds i8,i8*%L,i64 16
%T=bitcast i8*%S to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLL18collectDuplication_61 to void(...)*),void(...)**%T,align 8
%U=getelementptr inbounds i8,i8*%L,i64 24
%V=bitcast i8*%U to i32*
store i32 -2147483647,i32*%V,align 4
%W=call fastcc i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
store i8*%W,i8**%c,align 8
%X=call fastcc i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
%Y=load i8*,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%Y,i64 16
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
%ac=load i8*,i8**%f,align 8
%ad=load i8*,i8**%c,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%c,align 8
%ae=call fastcc i8*@_SMLL18collectDuplication_61(i8*inreg%ac,i8*inreg%ad,i8*inreg%X,i8*inreg%ab)
store i8*%ae,i8**%c,align 8
%af=call fastcc i8*@_SMLFN4List3appE(i32 inreg 1,i32 inreg 8)
%ag=getelementptr inbounds i8,i8*%af,i64 16
%ah=bitcast i8*%ag to i8*(i8*,i8*)**
%ai=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ah,align 8
%aj=bitcast i8*%af to i8**
%ak=load i8*,i8**%aj,align 8
store i8*%ak,i8**%g,align 8
%al=bitcast i8**%e to i8***
%am=load i8**,i8***%al,align 8
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%f,align 8
%ao=getelementptr inbounds i8*,i8**%am,i64 3
%ap=load i8*,i8**%ao,align 8
store i8*%ap,i8**%e,align 8
%aq=call i8*@sml_alloc(i32 inreg 28)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177304,i32*%as,align 4
store i8*%aq,i8**%h,align 8
%at=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%au=bitcast i8*%aq to i8**
store i8*%at,i8**%au,align 8
%av=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aw=getelementptr inbounds i8,i8*%aq,i64 8
%ax=bitcast i8*%aw to i8**
store i8*%av,i8**%ax,align 8
%ay=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%az=getelementptr inbounds i8,i8*%aq,i64 16
%aA=bitcast i8*%az to i8**
store i8*%ay,i8**%aA,align 8
%aB=getelementptr inbounds i8,i8*%aq,i64 24
%aC=bitcast i8*%aB to i32*
store i32 7,i32*%aC,align 4
%aD=call i8*@sml_alloc(i32 inreg 28)#0
%aE=getelementptr inbounds i8,i8*%aD,i64 -4
%aF=bitcast i8*%aE to i32*
store i32 1342177304,i32*%aF,align 4
%aG=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aH=bitcast i8*%aD to i8**
store i8*%aG,i8**%aH,align 8
%aI=getelementptr inbounds i8,i8*%aD,i64 8
%aJ=bitcast i8*%aI to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_62 to void(...)*),void(...)**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aD,i64 16
%aL=bitcast i8*%aK to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_103 to void(...)*),void(...)**%aL,align 8
%aM=getelementptr inbounds i8,i8*%aD,i64 24
%aN=bitcast i8*%aM to i32*
store i32 -2147483647,i32*%aN,align 4
%aO=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aP=call fastcc i8*%ai(i8*inreg%aO,i8*inreg%aD)
%aQ=getelementptr inbounds i8,i8*%aP,i64 16
%aR=bitcast i8*%aQ to i8*(i8*,i8*)**
%aS=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aR,align 8
%aT=bitcast i8*%aP to i8**
%aU=load i8*,i8**%aT,align 8
%aV=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aW=call fastcc i8*%aS(i8*inreg%aU,i8*inreg%aV)
ret void
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_64(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store i8*%b,i8**%c,align 8
%h=bitcast i8*%a to i8**
%i=load i8*,i8**%h,align 8
store i8*%i,i8**%d,align 8
%j=getelementptr inbounds i8,i8*%a,i64 8
%k=bitcast i8*%j to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%e,align 8
%m=getelementptr inbounds i8,i8*%a,i64 16
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%f,align 8
%p=getelementptr inbounds i8,i8*%a,i64 24
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=getelementptr inbounds i8,i8*%a,i64 28
%t=bitcast i8*%s to i32*
%u=load i32,i32*%t,align 4
%v=call i8*@sml_alloc(i32 inreg 44)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177320,i32*%x,align 4
store i8*%v,i8**%g,align 8
%y=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%B=getelementptr inbounds i8,i8*%v,i64 8
%C=bitcast i8*%B to i8**
store i8*%A,i8**%C,align 8
%D=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%E=getelementptr inbounds i8,i8*%v,i64 16
%F=bitcast i8*%E to i8**
store i8*%D,i8**%F,align 8
%G=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%v,i64 24
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%v,i64 32
%K=bitcast i8*%J to i32*
store i32%r,i32*%K,align 4
%L=getelementptr inbounds i8,i8*%v,i64 36
%M=bitcast i8*%L to i32*
store i32%u,i32*%M,align 4
%N=getelementptr inbounds i8,i8*%v,i64 40
%O=bitcast i8*%N to i32*
store i32 15,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 28)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177304,i32*%R,align 4
%S=load i8*,i8**%g,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=getelementptr inbounds i8,i8*%P,i64 8
%V=bitcast i8*%U to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_63 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%P,i64 16
%X=bitcast i8*%W to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_104 to void(...)*),void(...)**%X,align 8
%Y=getelementptr inbounds i8,i8*%P,i64 24
%Z=bitcast i8*%Y to i32*
store i32 -2147483647,i32*%Z,align 4
ret i8*%P
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_65(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%b,i8**%c,align 8
%g=bitcast i8*%a to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%d,align 8
%i=getelementptr inbounds i8,i8*%a,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%e,align 8
%l=getelementptr inbounds i8,i8*%a,i64 16
%m=bitcast i8*%l to i32*
%n=load i32,i32*%m,align 4
%o=getelementptr inbounds i8,i8*%a,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=call i8*@sml_alloc(i32 inreg 36)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177312,i32*%t,align 4
store i8*%r,i8**%f,align 8
%u=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%x=getelementptr inbounds i8,i8*%r,i64 8
%y=bitcast i8*%x to i8**
store i8*%w,i8**%y,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=getelementptr inbounds i8,i8*%r,i64 16
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%r,i64 24
%D=bitcast i8*%C to i32*
store i32%n,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%r,i64 28
%F=bitcast i8*%E to i32*
store i32%q,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%r,i64 32
%H=bitcast i8*%G to i32*
store i32 7,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 28)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177304,i32*%K,align 4
%L=load i8*,i8**%f,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_64 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_64 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_66(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
%h=getelementptr inbounds i8,i8*%a,i64 8
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=getelementptr inbounds i8,i8*%a,i64 12
%l=bitcast i8*%k to i32*
%m=load i32,i32*%l,align 4
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
store i8*%n,i8**%e,align 8
%q=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%t=getelementptr inbounds i8,i8*%n,i64 8
%u=bitcast i8*%t to i8**
store i8*%s,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%n,i64 16
%w=bitcast i8*%v to i32*
store i32%j,i32*%w,align 4
%x=getelementptr inbounds i8,i8*%n,i64 20
%y=bitcast i8*%x to i32*
store i32%m,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%n,i64 24
%A=bitcast i8*%z to i32*
store i32 3,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
%E=load i8*,i8**%e,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_65 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_65 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_67(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_66 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_66 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_70(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%e,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%h,label%j
h:
%i=bitcast i8*%a to i8**
br label%n
j:
call void@sml_check(i32 inreg%f)
%k=bitcast i8**%d to i8***
%l=load i8**,i8***%k,align 8
%m=load i8*,i8**%e,align 8
br label%n
n:
%o=phi i8*[%m,%j],[%b,%h]
%p=phi i8**[%l,%j],[%i,%h]
%q=load i8*,i8**%p,align 8
%r=getelementptr inbounds i8,i8*%q,i64 16
%s=bitcast i8*%r to i8*(i8*,i8*)**
%t=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%s,align 8
store i8*null,i8**%d,align 8
%u=bitcast i8**%p to i8***
%v=load i8**,i8***%u,align 8
%w=load i8*,i8**%v,align 8
store i8*null,i8**%e,align 8
%x=call fastcc i8*%t(i8*inreg%w,i8*inreg%o)
%y=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%y)
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%x,i8**%c,align 8
%z=call i8*@sml_alloc(i32 inreg 12)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177288,i32*%B,align 4
%C=load i8*,i8**%c,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%y)
ret i8*%z
}
define internal fastcc void@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_71(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%d,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
%o=getelementptr inbounds i8,i8*%m,i64 24
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
%r=getelementptr inbounds i8,i8*%m,i64 32
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=getelementptr inbounds i8,i8*%m,i64 36
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=call fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_67(i8*inreg%q,i32 inreg%t,i32 inreg%w)
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%f,align 8
%D=bitcast i8**%d to i8***
%E=load i8**,i8***%D,align 8
%F=load i8*,i8**%E,align 8
store i8*%F,i8**%e,align 8
%G=call i8*@sml_alloc(i32 inreg 12)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177288,i32*%I,align 4
store i8*%G,i8**%g,align 8
%J=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i32*
store i32 1,i32*%M,align 4
%N=call i8*@sml_alloc(i32 inreg 28)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177304,i32*%P,align 4
%Q=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%N,i64 8
%T=bitcast i8*%S to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_70 to void(...)*),void(...)**%T,align 8
%U=getelementptr inbounds i8,i8*%N,i64 16
%V=bitcast i8*%U to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_70 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%N,i64 24
%X=bitcast i8*%W to i32*
store i32 1,i32*%X,align 4
%Y=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%Z=call fastcc i8*%A(i8*inreg%Y,i8*inreg%N)
%aa=getelementptr inbounds i8,i8*%Z,i64 16
%ab=bitcast i8*%aa to i8*(i8*,i8*)**
%ac=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ab,align 8
%ad=bitcast i8*%Z to i8**
%ae=load i8*,i8**%ad,align 8
%af=load i8*,i8**%d,align 8
%ag=getelementptr inbounds i8,i8*%af,i64 8
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
%aj=call fastcc i8*%ac(i8*inreg%ae,i8*inreg%ai)
%ak=getelementptr inbounds i8,i8*%aj,i64 16
%al=bitcast i8*%ak to i8*(i8*,i8*)**
%am=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%al,align 8
%an=bitcast i8*%aj to i8**
%ao=load i8*,i8**%an,align 8
%ap=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aq=getelementptr inbounds i8,i8*%ap,i64 16
%ar=bitcast i8*%aq to i8**
%as=load i8*,i8**%ar,align 8
%at=call fastcc i8*%am(i8*inreg%ao,i8*inreg%as)
%au=getelementptr inbounds i8,i8*%at,i64 16
%av=bitcast i8*%au to i8*(i8*,i8*)**
%aw=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%av,align 8
%ax=bitcast i8*%at to i8**
%ay=load i8*,i8**%ax,align 8
%az=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aA=call fastcc i8*%aw(i8*inreg%ay,i8*inreg%az)
ret void
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_72(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store i8*%b,i8**%c,align 8
%h=bitcast i8*%a to i8**
%i=load i8*,i8**%h,align 8
store i8*%i,i8**%d,align 8
%j=getelementptr inbounds i8,i8*%a,i64 8
%k=bitcast i8*%j to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%e,align 8
%m=getelementptr inbounds i8,i8*%a,i64 16
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%f,align 8
%p=getelementptr inbounds i8,i8*%a,i64 24
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=getelementptr inbounds i8,i8*%a,i64 28
%t=bitcast i8*%s to i32*
%u=load i32,i32*%t,align 4
%v=call i8*@sml_alloc(i32 inreg 44)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177320,i32*%x,align 4
store i8*%v,i8**%g,align 8
%y=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%B=getelementptr inbounds i8,i8*%v,i64 8
%C=bitcast i8*%B to i8**
store i8*%A,i8**%C,align 8
%D=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%E=getelementptr inbounds i8,i8*%v,i64 16
%F=bitcast i8*%E to i8**
store i8*%D,i8**%F,align 8
%G=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%H=getelementptr inbounds i8,i8*%v,i64 24
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%v,i64 32
%K=bitcast i8*%J to i32*
store i32%r,i32*%K,align 4
%L=getelementptr inbounds i8,i8*%v,i64 36
%M=bitcast i8*%L to i32*
store i32%u,i32*%M,align 4
%N=getelementptr inbounds i8,i8*%v,i64 40
%O=bitcast i8*%N to i32*
store i32 15,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 28)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177304,i32*%R,align 4
%S=load i8*,i8**%g,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=getelementptr inbounds i8,i8*%P,i64 8
%V=bitcast i8*%U to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_71 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%P,i64 16
%X=bitcast i8*%W to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_107 to void(...)*),void(...)**%X,align 8
%Y=getelementptr inbounds i8,i8*%P,i64 24
%Z=bitcast i8*%Y to i32*
store i32 -2147483647,i32*%Z,align 4
ret i8*%P
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_73(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%b,i8**%c,align 8
%g=bitcast i8*%a to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%d,align 8
%i=getelementptr inbounds i8,i8*%a,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%e,align 8
%l=getelementptr inbounds i8,i8*%a,i64 16
%m=bitcast i8*%l to i32*
%n=load i32,i32*%m,align 4
%o=getelementptr inbounds i8,i8*%a,i64 20
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=call i8*@sml_alloc(i32 inreg 36)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177312,i32*%t,align 4
store i8*%r,i8**%f,align 8
%u=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%x=getelementptr inbounds i8,i8*%r,i64 8
%y=bitcast i8*%x to i8**
store i8*%w,i8**%y,align 8
%z=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%A=getelementptr inbounds i8,i8*%r,i64 16
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%r,i64 24
%D=bitcast i8*%C to i32*
store i32%n,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%r,i64 28
%F=bitcast i8*%E to i32*
store i32%q,i32*%F,align 4
%G=getelementptr inbounds i8,i8*%r,i64 32
%H=bitcast i8*%G to i32*
store i32 7,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 28)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177304,i32*%K,align 4
%L=load i8*,i8**%f,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_72 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_72 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_74(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
%h=getelementptr inbounds i8,i8*%a,i64 8
%i=bitcast i8*%h to i32*
%j=load i32,i32*%i,align 4
%k=getelementptr inbounds i8,i8*%a,i64 12
%l=bitcast i8*%k to i32*
%m=load i32,i32*%l,align 4
%n=call i8*@sml_alloc(i32 inreg 28)#0
%o=getelementptr inbounds i8,i8*%n,i64 -4
%p=bitcast i8*%o to i32*
store i32 1342177304,i32*%p,align 4
store i8*%n,i8**%e,align 8
%q=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%r=bitcast i8*%n to i8**
store i8*%q,i8**%r,align 8
%s=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%t=getelementptr inbounds i8,i8*%n,i64 8
%u=bitcast i8*%t to i8**
store i8*%s,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%n,i64 16
%w=bitcast i8*%v to i32*
store i32%j,i32*%w,align 4
%x=getelementptr inbounds i8,i8*%n,i64 20
%y=bitcast i8*%x to i32*
store i32%m,i32*%y,align 4
%z=getelementptr inbounds i8,i8*%n,i64 24
%A=bitcast i8*%z to i32*
store i32 3,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
%E=load i8*,i8**%e,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_73 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_73 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_75(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_74 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_74 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define internal fastcc void@_SMLLN14UserErrorUtils20initializeErrorQueueE_76(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%c,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%f,label%h
f:
%g=bitcast i8*%a to i8**
br label%k
h:
call void@sml_check(i32 inreg%d)
%i=bitcast i8**%c to i8***
%j=load i8**,i8***%i,align 8
br label%k
k:
%l=phi i8**[%j,%h],[%g,%f]
%m=load i8*,i8**%l,align 8
tail call fastcc void@_SMLFN9UserError10clearQueueE(i8*inreg%m)
ret void
}
define fastcc void@_SMLFN14UserErrorUtils20initializeErrorQueueE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 0),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%r=call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret void
}
define internal fastcc i8*@_SMLLN14UserErrorUtils20getErrorsAndWarningsE_78(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%c,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%f,label%h
f:
%g=bitcast i8*%a to i8**
br label%k
h:
call void@sml_check(i32 inreg%d)
%i=bitcast i8**%c to i8***
%j=load i8**,i8***%i,align 8
br label%k
k:
%l=phi i8**[%j,%h],[%g,%f]
%m=load i8*,i8**%l,align 8
%n=tail call fastcc i8*@_SMLFN9UserError20getErrorsAndWarningsE(i8*inreg%m)
ret i8*%n
}
define fastcc i8*@_SMLFN14UserErrorUtils20getErrorsAndWarningsE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 1),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define internal fastcc i8*@_SMLLN14UserErrorUtils9getErrorsE_80(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%c,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%f,label%h
f:
%g=bitcast i8*%a to i8**
br label%k
h:
call void@sml_check(i32 inreg%d)
%i=bitcast i8**%c to i8***
%j=load i8**,i8***%i,align 8
br label%k
k:
%l=phi i8**[%j,%h],[%g,%f]
%m=load i8*,i8**%l,align 8
%n=tail call fastcc i8*@_SMLFN9UserError9getErrorsE(i8*inreg%m)
ret i8*%n
}
define fastcc i8*@_SMLFN14UserErrorUtils9getErrorsE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 2),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define internal fastcc i32@_SMLLN14UserErrorUtils10isAnyErrorE_82(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%c,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%f,label%h
f:
%g=bitcast i8*%a to i8**
br label%k
h:
call void@sml_check(i32 inreg%d)
%i=bitcast i8**%c to i8***
%j=load i8**,i8***%i,align 8
br label%k
k:
%l=phi i8**[%j,%h],[%g,%f]
store i8*null,i8**%c,align 8
%m=load i8*,i8**%l,align 8
%n=call fastcc i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg%m)
%o=tail call fastcc i32@_SMLFN4Bool3notE(i32 inreg%n)
ret i32%o
}
define fastcc i32@_SMLFN14UserErrorUtils10isAnyErrorE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 3),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%r=call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
ret i32%t
}
define internal fastcc i8*@_SMLLN14UserErrorUtils11getWarningsE_84(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%c,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%f,label%h
f:
%g=bitcast i8*%a to i8**
br label%k
h:
call void@sml_check(i32 inreg%d)
%i=bitcast i8**%c to i8***
%j=load i8**,i8***%i,align 8
br label%k
k:
%l=phi i8**[%j,%h],[%g,%f]
%m=load i8*,i8**%l,align 8
%n=tail call fastcc i8*@_SMLFN9UserError11getWarningsE(i8*inreg%m)
ret i8*%n
}
define fastcc i8*@_SMLFN14UserErrorUtils11getWarningsE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 4),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define fastcc void@_SMLFN14UserErrorUtils12enqueueErrorE(i8*inreg%a)local_unnamed_addr#1 gc"smlsharp"{
i:
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%g,label%e
e:
call void@sml_check(i32 inreg%c)
%f=load i8*,i8**%b,align 8
br label%g
g:
%h=phi i8*[%f,%e],[%a,%i]
store i8*null,i8**%b,align 8
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 5),align 8
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=call fastcc i8*%m(i8*inreg%o,i8*inreg%h)
ret void
}
define fastcc void@_SMLFN14UserErrorUtils14enqueueWarningE(i8*inreg%a)local_unnamed_addr#1 gc"smlsharp"{
i:
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%g,label%e
e:
call void@sml_check(i32 inreg%c)
%f=load i8*,i8**%b,align 8
br label%g
g:
%h=phi i8*[%f,%e],[%a,%i]
store i8*null,i8**%b,align 8
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 6),align 8
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=call fastcc i8*%m(i8*inreg%o,i8*inreg%h)
ret void
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_88(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
k:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%a,%k]
%l=bitcast i8*%j to i8**
%m=load i8*,i8**%l,align 8
%n=getelementptr inbounds i8,i8*%j,i64 8
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%j,i64 12
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=call fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_53(i8*inreg%m,i32 inreg%p,i32 inreg%s)
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
ret i8*%A
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_89(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_88 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_88 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define fastcc i8*@_SMLFN14UserErrorUtils23checkSymbolDuplication_GE(i32 inreg%a,i32 inreg%b)local_unnamed_addr#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 7),align 8
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*,i8*)**
%l=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%c,align 8
%o=call i8*@sml_alloc(i32 inreg 4)#0
%p=bitcast i8*%o to i32*
%q=getelementptr inbounds i8,i8*%o,i64 -4
%r=bitcast i8*%q to i32*
store i32 4,i32*%r,align 4
store i8*%o,i8**%d,align 8
store i32%a,i32*%p,align 4
%s=call i8*@sml_alloc(i32 inreg 4)#0
%t=bitcast i8*%s to i32*
%u=getelementptr inbounds i8,i8*%s,i64 -4
%v=bitcast i8*%u to i32*
store i32 4,i32*%v,align 4
store i32%b,i32*%t,align 4
%w=load i8*,i8**%c,align 8
%x=load i8*,i8**%d,align 8
%y=tail call fastcc i8*%l(i8*inreg%w,i8*inreg%x,i8*inreg%s)
ret i8*%y
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_91(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
k:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%a,%k]
%l=bitcast i8*%j to i8**
%m=load i8*,i8**%l,align 8
%n=getelementptr inbounds i8,i8*%j,i64 8
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%j,i64 12
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=call fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_60(i8*inreg%m,i32 inreg%p,i32 inreg%s)
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
ret i8*%A
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_92(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_91 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_91 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define fastcc i8*@_SMLFN14UserErrorUtils22checkSymbolDuplicationE(i32 inreg%a,i32 inreg%b)local_unnamed_addr#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 8),align 8
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*,i8*)**
%l=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%c,align 8
%o=call i8*@sml_alloc(i32 inreg 4)#0
%p=bitcast i8*%o to i32*
%q=getelementptr inbounds i8,i8*%o,i64 -4
%r=bitcast i8*%q to i32*
store i32 4,i32*%r,align 4
store i8*%o,i8**%d,align 8
store i32%a,i32*%p,align 4
%s=call i8*@sml_alloc(i32 inreg 4)#0
%t=bitcast i8*%s to i32*
%u=getelementptr inbounds i8,i8*%s,i64 -4
%v=bitcast i8*%u to i32*
store i32 4,i32*%v,align 4
store i32%b,i32*%t,align 4
%w=load i8*,i8**%c,align 8
%x=load i8*,i8**%d,align 8
%y=tail call fastcc i8*%l(i8*inreg%w,i8*inreg%x,i8*inreg%s)
ret i8*%y
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_94(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
k:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%a,%k]
%l=bitcast i8*%j to i8**
%m=load i8*,i8**%l,align 8
%n=getelementptr inbounds i8,i8*%j,i64 8
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%j,i64 12
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=call fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_75(i8*inreg%m,i32 inreg%p,i32 inreg%s)
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
ret i8*%A
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_95(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%d,align 8
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=getelementptr inbounds i8,i8*%h,i64 8
%n=bitcast i8*%m to i32*
store i32%b,i32*%n,align 4
%o=getelementptr inbounds i8,i8*%h,i64 12
%p=bitcast i8*%o to i32*
store i32%c,i32*%p,align 4
%q=getelementptr inbounds i8,i8*%h,i64 16
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%e,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_94 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_94 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define fastcc i8*@_SMLFN14UserErrorUtils27checkRecordLabelDuplicationE(i32 inreg%a,i32 inreg%b)local_unnamed_addr#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvar872d7bd4cbb24e12_UserErrorUtils,i64 0,i32 2,i64 9),align 8
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*,i8*)**
%l=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%c,align 8
%o=call i8*@sml_alloc(i32 inreg 4)#0
%p=bitcast i8*%o to i32*
%q=getelementptr inbounds i8,i8*%o,i64 -4
%r=bitcast i8*%q to i32*
store i32 4,i32*%r,align 4
store i8*%o,i8**%d,align 8
store i32%a,i32*%p,align 4
%s=call i8*@sml_alloc(i32 inreg 4)#0
%t=bitcast i8*%s to i32*
%u=getelementptr inbounds i8,i8*%s,i64 -4
%v=bitcast i8*%u to i32*
store i32 4,i32*%v,align 4
store i32%b,i32*%t,align 4
%w=load i8*,i8**%c,align 8
%x=load i8*,i8**%d,align 8
%y=tail call fastcc i8*%l(i8*inreg%w,i8*inreg%x,i8*inreg%s)
ret i8*%y
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_97(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_49(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_98(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_50(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_99(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_53(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_101(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_57(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_102(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_60(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_103(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_62(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_104(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_63(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_105(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils28checkRecordLabelDuplication_GE_67(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_107(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_71(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_108(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_75(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN14UserErrorUtils20initializeErrorQueueE_109(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
tail call fastcc void@_SMLLN14UserErrorUtils20initializeErrorQueueE_76(i8*inreg%a,i32 inreg%d)
%e=tail call i8*@sml_alloc(i32 inreg 4)#0
%f=bitcast i8*%e to i32*
%g=getelementptr inbounds i8,i8*%e,i64 -4
%h=bitcast i8*%g to i32*
store i32 4,i32*%h,align 4
store i32 0,i32*%f,align 4
ret i8*%e
}
define internal fastcc i8*@_SMLLN14UserErrorUtils20getErrorsAndWarningsE_111(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLN14UserErrorUtils20getErrorsAndWarningsE_78(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLN14UserErrorUtils9getErrorsE_113(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLN14UserErrorUtils9getErrorsE_80(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLN14UserErrorUtils10isAnyErrorE_115(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i32@_SMLLN14UserErrorUtils10isAnyErrorE_82(i8*inreg%a,i32 inreg%d)
%f=tail call i8*@sml_alloc(i32 inreg 4)#0
%g=bitcast i8*%f to i32*
%h=getelementptr inbounds i8,i8*%f,i64 -4
%i=bitcast i8*%h to i32*
store i32 4,i32*%i,align 4
store i32%e,i32*%g,align 4
ret i8*%f
}
define internal fastcc i8*@_SMLLN14UserErrorUtils11getWarningsE_117(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLN14UserErrorUtils11getWarningsE_84(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_121(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils23checkSymbolDuplication_GE_89(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_123(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils22checkSymbolDuplicationE_92(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_125(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLN14UserErrorUtils27checkRecordLabelDuplicationE_95(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
